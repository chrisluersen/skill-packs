# Large File Recovery & Append Techniques

## The Catastrophe Pattern: Paginated Read → Write

**Never feed a paginated `read_file` result into `write_file`.**

### How it happens

You're maintaining a large HTML document (~140KB, ~2900 lines). You want to read part of it for context:

```python
resp = read_file(path="report.html")  # returns offset=1, limit=500
# resp["content"] only has ~18KB / 500 lines
write_file(path="report.html", content=resp["content"])  # 💥 122KB GONE
```

`write_file` overwrites the entire file. The remaining ~2600 lines are lost. There is no undo.

### Root cause

`read_file` by default returns only the first 500 lines (~18KB). There is no visual distinction between "full file" and "paginated preview" in the returned dict — both look like `{"content": "...", "total_lines": N}`. The `total_lines` field is the only clue: if the content is significantly shorter than `total_lines` would suggest, you have a paginated view.

### Prevention

1. **Never use `write_file` with content from `read_file` unless you explicitly checked `total_lines` vs actual content length.** If `total_lines` is 2946 but your content is only a few hundred KB chunks, you have a paginated view.

2. **Use `execute_code` + `from hermes_tools import read_file` for programmatic full reads** — but even there, respect the 2000-line limit per call.

3. **For append operations** (adding content to an existing large file), use the terminal concatenation pattern instead (see below).

4. **If you MUST reconstruct a large file**, read it in sections, verify each section, then concatenate via terminal.

## The Append Pattern: cat >> via Terminal

When a file is too large for a single `write_file` call (or you're adding to an existing file), use a **two-file approach**:

### Workflow

1. **Write part 1** (everything up to the insertion point) with `write_file`:
   ```
   write_file(path="doc.html", content=part1_html)
   # verify: ~48KB
   ```

2. **Write part 2** (everything from the insertion point onward) as a separate file:
   ```
   write_file(path="doc_part2.html", content=part2_html)
   # verify: ~40KB
   ```

3. **Concatenate via terminal**:
   ```bash
   cat doc_part2.html >> doc.html
   ```

4. **Verify** the final size (should be ~ part1 + part2):
   ```bash
   wc -c doc.html
   ```

5. **Clean up** the temp file:
   ```bash
   rm doc_part2.html
   ```

### When to use this

- Appending sections to an existing large HTML document
- Any time total content exceeds ~50KB (write_file may have per-call limits depending on the backend)
- After recovering from a corruption — append the lost content back via cat

## Recovery Workflow (from corruption)

If you've already corrupted a large file:

1. **STOP** — don't write anything else to it. Every overwrite makes recovery harder.

2. **Check version history**: git, Windows Previous Versions, OneDrive version history via web UI.

3. **Check shadow copies**:
   ```bash
   vssadmin list shadows
   # or PowerShell: Get-WmiObject -Class Win32_ShadowCopy
   ```

4. **Search Hermes `state.db` (BEST recovery chance)** — the session database stores all tool call outputs. Earlier `read_file` calls may still have the original content cached as assistant or tool messages. Query for unique strings from the lost sections:

   ```python
   import sqlite3
   db = "~/AppData/Local/hermes/state.db"
   conn = sqlite3.connect(os.path.expanduser(db))
   cur = conn.cursor()
   # Find candidate messages with raw content from the lost sections
   cur.execute("""
       SELECT id, session_id, length(content) as clen
       FROM messages
       WHERE content LIKE ?
       ORDER BY clen DESC
       LIMIT 5
   """, ('%unique_section_string%',))
   # Extract full content from the largest/oldest candidate
   cur.execute("SELECT content FROM messages WHERE id = ?", (msg_id,))
   ```

   Look for large messages (50K-200K chars) containing unique strings from the file — section IDs, data attributes, table content. Prefer `role='tool'` messages (raw tool output) and pre-compaction assistant messages.

5. **Check session history** — earlier turns in this very session may have the original content in tool outputs (read_file results, patch diffs). Use `session_search` to find references.

6. **Salvage what's intact** — `read_file` the corrupted file. The first N lines are preserved (the paginated fragment you wrote). Everything after the write boundary is gone.

7. **Rebuild from knowledge** — if you know the document structure and content intimately (because you built it), reconstruct the missing sections from memory, using the preserved CSS/front-matter as-is.

8. **Use the append pattern** above to stitch partial rebuilds together.

### Real example 1: 140KB SQLite-DB recovery

A 2064-line, 149KB HTML doc was truncated to 500 lines (28KB) when `execute_code`'s `read_file` returned only the first 500 lines and the result was fed into `write_file`. Recovery:

- The `state.db` messages table had several large cached tool outputs (msg #19172 = 95K, msg #8577 = 92K) containing the original file content from earlier `read_file` calls
- Queried for unique strings from the lost sections (`'Kernel → Agent Loop'`, `'AIAgent core'`, `'data-filter-tag'`) to find the right messages
- Extracted the raw content from the oldest/largest candidate message
- Note: session compaction replaces tool output with compaction summaries in the `content` field, so target pre-compaction messages. Also check the WAL (`state.db-wal`) for uncheckpointed data if the DB is mid-write.

### Real example 2: 140KB memory reconstruction

A 2946-line, 140KB HTML report was corrupted when a 500-line paginated read was written back over it (18KB preserved, 122KB lost). Recovery steps:

- Preserved fragment had all CSS, sidebar, header, nav, first 5 sections
- Lost: sections 05-13 (installation, hardware, skills, CLI ref, tools, workflows, ecosystem, next steps), all modals, all JS, footer
- Reconstructed from memory of section content
- Part 1 written = preserved CSS + sections 00-04 (48KB)
- Part 2 written = sections 05-13 + modals + JS (40KB)
- Concatenated via `cat part2.html >> main.html`
- Final: 89KB (smaller than original because reconstructed sections were more concise)

## SQLite DB Forensics (when search isn't enough)

If `session_search` returns nothing or you need the raw bytes:

```python
import sqlite3, os

db = os.path.expanduser("~/AppData/Local/hermes/state.db")
conn = sqlite3.connect(db)
cur = conn.cursor()

# 1. Find candidate messages by unique content strings from the lost file
patterns = ['section id="ecosystem"', 'data-filter-tag', 'Kernel → Agent Loop']
for pat in patterns:
    cur.execute("""
        SELECT id, session_id, role, length(content) as clen
        FROM messages
        WHERE content LIKE ?
        LIMIT 3
    """, ('%' + pat + '%',))
    for row in cur.fetchall():
        print(f"  '{pat}' → msg #{row[0]} ({row[3]}c) role={row[2]} session={row[1][:20]}")

# 2. Extract full content from the best candidate
cur.execute("SELECT content FROM messages WHERE id = ?", (best_msg_id,))
content = cur.fetchone()[0]

# 3. The content may be JSON (tool call result) or raw text (assistant message).
#    Tool results look like: {"success": True, "content": "..."}
#    Assistant messages may have the read_file tool output embedded.
```

### Key considerations

- **Wal mode** — if `state.db-wal` exists and is large, checkpoint first: `cur.execute("PRAGMA wal_checkpoint(FULL)")` to merge pending transactions.
- **Session compaction** — recent sessions may have their content truncated to compaction summaries. Target older sessions or pre-compaction message IDs.
- **Message roles** — `role='tool'` messages contain raw tool output. `role='assistant'` messages have the agent's response, which may embed tool results inline. Search both.
- **Size heuristic** — `length(content) > 30000` is usually a full file read. Sort by `clen DESC` to find the largest candidates first.
- **Don't search for 'AI Architecture' or the filename** — the content field stores the *output*, not the *input parameters*. The filename is in the tool_calls JSON, not the content. Search for content strings that appear INSIDE the file.
