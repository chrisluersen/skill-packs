---
name: safe-large-file-editing
description: Prevent file corruption and verify mutations for all file types. Root causes, safe workflows, post-mutation verification protocol, and recovery from failed patch/large-file corruption.
---

# Safe Large File Editing (Windows)

## Root Cause of Corruption

Two failure modes on Windows (MSYS bash) have caused `AI Architecture.html` (163KB) to be truncated:

### 1. `patch()` with stale partial context
When `read_file(path, offset=N, limit=M)` is called with pagination, **the patch tool retains an incomplete view of the file**. The warning:
> `was last read with offset/limit pagination (partial view). Re-read the whole file before overwriting it.`
If patch's fuzzy matching uses the partial content, it can silently drop unread sections.

### 2. Terminal Python heredocs (`<< 'PYEOF'`)
Multi-line heredocs in MSYS bash can silently produce truncated output when:
- Python code contains special characters (`'`, `\`, `$`, `"`)
- The heredoc string exceeds several hundred lines
- MSYS path translation interferes with file paths

## Safe Workflow

### ⭐ Use `execute_code` + Python `open()` — THE definitive pattern for files >2000 lines / >50KB

This bypasses BOTH limitations at once:
- `read_file`'s 2000-line pagination cap
- Terminal's 50KB stdout truncation

```python
# In execute_code(code="..."):
with open('C:/path/to/file.html', 'r', encoding='utf-8') as f:
    content = f.read()

# Make ALL edits as string operations in one pass
content = content.replace('old_string', 'new_string')
# ... multiple str.replace() calls, one per edit ...

# Verify every replacement was applied before writing
assert 'new_string1' in content
assert 'new_string2' in content

with open('C:/path/to/file.html', 'w', encoding='utf-8') as f:
    f.write(content)
```

**Batch edits together** — one read + multiple `.replace()` calls + one write. Never interleave reads and writes.

**Always verify before writing** — check that every expected string is present in the modified content, and that structural elements aren't corrupted (e.g. `content.count('</section>') == expected_sections`).

### Use `execute_code` with `hermes_tools` (for files <2000 lines)

```python
from hermes_tools import read_file, write_file

f = read_file(path='C:/path/to/file.html', limit=2000)
content = f['content']
content = content.replace('old', 'new')
write_file(path='C:/path/to/file.html', content=content)
```

**⚠️ CRITICAL: `hermes_tools.read_file` defaults to 500 lines.** If you omit `limit=`, only the first 500 lines are returned. `write_file` will then OVERWRITE the full file with only that partial content, silently destroying lines 501+. Always:

1. Set `limit=` to a value larger than the expected file (2000 is safe for most files)
2. Check `result['total_lines']` BEFORE calling `write_file` — if it's suspiciously round (e.g. exactly 500, 1000, 2000), the file was truncated
3. Check `result.get('truncated', False)` — if True, `hermes_tools` already knows it returned partial data
4. Verify expected strings exist after content modification but BEFORE write:

```python
f = read_file(path='C:/path/to/file.md', limit=2000)
content = f['content']
total = f['total_lines']
truncated = f.get('truncated', False)

# Safety gate
if truncated or total < expected_min_lines:
    raise RuntimeError(f"Partial read! total_lines={total}, truncated={truncated} — use open() instead")

# Verify content integrity
assert 'expected_section_header' in content, "Structural integrity check failed"
assert 'expected_footer_text' in content, "File appears truncated"

# Make edits
content = content.replace('old', 'new')

# Verify replacement landed
assert 'new' in content, "Replacement did not take effect"

write_file(path='C:/path/to/file.md', content=content)
```

If the file exceeds 2000 lines or you can't reliably set limit=, use the Python `open()` pattern below instead. Never call `write_file()` on content from a read that may have been truncated.

### Use a Python script file (for very large batch edits)
Write the script to `~/.hermes/scripts/` with write_file, then run via terminal:
```bash
python3 ~/AppData/Local/hermes/.hermes/scripts/edit_script.py
```
Never use `<< 'PYEOF'` heredocs for scripts modifying large files — MSYS can truncate them.

### ⚠️ CRITICAL: Match Python read/write modes on Windows (`'rb'` requires `'wb'`)

On Windows, Python's text mode (`'r'`, `'w'`) performs universal newline translation — `\r\n` is translated to `\n` on read, and `\n` is translated back to `\r\n` on write. **Binary mode (`'rb'`, `'wb'`) does no translation.**

**The trap:** Reading a file with `'rb'` (getting raw `\r\n` bytes) then writing with `'w'` (text mode) causes **double CRLF** (`\r\r\n`). Python's text mode writer adds `\r` before every `\n`, and the existing `\r` from binary read is still there.

**Symptom:** File size increases by exactly (number of lines) bytes after a fix — each line ending changes from `\r\n` (2 bytes) to `\r\r\n` (3 bytes). Tools still display the file but linters and git diff flag the corruption.

**Real example (2026-07-06):** Fixing wikilink artifacts in `hermes/AGENT.md` with `open(path, 'rb')` read + `open(path, 'w', encoding='utf-8')` write. Result: 7026 → 7403 bytes (+377 double CRLF). Required `git checkout HEAD -- <file>` to restore.

**Rules:**
- `'rb'` read → `'wb'` write. Always.
- `'r'` read (text mode, `\r\n` → `\n` translated) → `'w'` text write (`\n` → `\r\n` translated). Also correct.
- `'rb'` → `'w'`: **INCORRECT** on Windows. Double CRLF.
- `'r'` → `'wb'`: Also incorrect on Windows. Loses `\r` on read, writes raw `\n`.
- On Linux/macOS this doesn't matter — no line-ending translation occurs in either mode.
- **Detection:** `python3 -c "open('path', 'rb').read()[:50]"` — look for `\r\r\n` sequences. Or compare `wc -c` before/after: increase of ~line_count bytes is diagnostic.

### Use `patch()` SAFELY
1. **Always** do a full `read_file(path, limit=2000)` first (no offset) — this gives patch full file context
2. Check the returned `total_lines` — if file is larger, prefer `execute_code` or terminal
3. Keep old_string unique — include 2-3 lines of surrounding context
4. If patch fails with 'multiple matches' — **try shortening old_string ONCE** before switching to `execute_code`. Counterintuitively, a shorter anchor string can succeed where a longer one failed, because there's less surface area for the fuzzy matcher's 9 strategies to find approximate matches. If shortening also fails, **stop immediately** and switch to `execute_code` with Python `open()` + `str.replace()`. Do NOT try multiple shortening variants repeatedly — each failure is a round-trip lost.
5. After each 3-5 patches, **backup the file** (cp to OneDrive)

### ⚠️ CRITICAL: `write_file` WILL overwrite the ENTIRE file after a partial `read_file`

If you call `read_file(path, offset=N, limit=M)` to read only a portion of a file, then call `write_file(path, content)` with content derived from that partial read, **you WILL lose every line outside the read window**. The file on disk is fully replaced — content is not merged.

The tool warns with:
```
"_warning": "was last read with offset/limit pagination (partial view).
             Re-read the whole file before overwriting it."
```

**This warning is a guard, not a safety net.** If you ignore or miss it, the file is gone.

**Real example (2026-06-23):** `.bashrc` was read with offset=148, limit=30 to see only the aliases section. A subsequent `write_file` with new content destroyed the entire file — 156 lines lost (`__hermes_track_session`, `PROMPT_COMMAND`, `hermes completion`, all aliases, PS1 setup). Only the focus() function survived.

**Prevention rules:**
1. **Never write_file after a read_file that used offset/limit.** Always read the full file first: `read_file(path, limit=500)` (no offset) to get a complete view.
2. **Check `total_lines` before writing.** If the file has 171 lines and you only read 30, you don't have the full picture.
3. **Use `patch()` for targeted edits** when modifying existing files. It only changes what you specify.
4. **When you must replace an entire file** (new file, rewrite from scratch), use `write_file` with fresh content — not content derived from a partial read.
5. **If the warning fires, STOP and re-read the file fully before proceeding.** Any write_file after that warning is destructive.

**Recovery if you already overwrote:**
- Check if the file is in a Git repo — `git checkout -- <file>` restores it
- Check backup directories (OneDrive, Downloads/backups)
- Reconstruct from session history (session_search)
- If unrecoverable, rebuild from what you remember + common defaults (completion, aliases, PATH exports)

### Pitfall: YAML frontmatter duplication from fuzzy matching

When using `patch()` on files with **YAML frontmatter**, the fuzzy matching can match the wrong context — especially when the same heading text or section title appears in BOTH the YAML frontmatter's `relates_to` entries and the body's section headings.

**Symptoms:**
- File size increases significantly after a small edit
- YAML `relates_to` entries appear duplicated as body text
- Lines like `    rel: supports` or `  - page: "Page Name"` appear inline after a heading

**Root cause:** The patch tool's fuzzy matching scans the entire file. If `## The Fleet Concept` appears in the body AND as text inside `relates_to` frontmatter, the fuzzy matcher may match YAML-embedded text instead of the body heading and replace the wrong block. Because YAML `relates_to` uses repeating structure (`  - page:`, `    rel:`), the matched region can include neighboring YAML lines, duplicating them in the body.

**Real example (2026-06-20):** `patch` on `asteroid-fleet-manifest.md` to add a "See also" block after `## The Fleet Concept`. The fuzzy matcher matched a `relates_to` entry containing `"Fleet Concept"` instead of the body heading. Result: 17 lines of `rel: includes` YAML entries spilled into the body.

**Prevention:**
1. **Prefer `execute_code` + Python `open()` over `patch` when editing files with YAML frontmatter** — one read, targeted `str.replace()`, one write. No fuzzy matching risk.
2. Search for your match string across the file first: `search_files(pattern="your match string", path="file.md")` — if it appears more than once, avoid `patch` or use a longer unique `old_string`.
3. If a heading string also appears in frontmatter `relates_to` entries or `sources` paths, use `execute_code` instead.
4. Keep `old_string` long and unique — include 3+ surrounding lines to disambiguate.

**Recovery pattern (if corruption already happened):**

1. **Identify the garbage region** — read the lines around the corrupted heading with `head -N file.md | tail -20`. Look for lines like `    rel: includes` that don't belong in the body.

2. **Use `sed` to remove the garbage lines:**
   ```bash
   sed -i 'HEADING_LINE+1,CLEAN_LINE-1d' file.md
   ```

3. **Verify structural integrity:**
   ```bash
   grep -c "rel:" file.md         # should be 0 in the body sections
   wc -l file.md                   # should be less than before fix
   ```

4. **Re-attempt the edit using `execute_code`** with Python `open()`, then verify.

**Golden rule:** If the match string appears in both YAML frontmatter and body, don't use `patch`. Use `execute_code` with `str.replace()`.

---

### Pitfall: `read_file` line-number leak into `patch`

The `read_file` tool outputs lines prefixed with a line number and pipe: `134|- content here`. If you copy this output verbatim into `patch(old_string="134|- content here")`, the `134|` gets baked into the file as literal content. The file ends up with `134|- content here` as actual content instead of `- content here`.

**Prevention:** Strip the `NUM|` prefix before using any `read_file` output as `patch` input. When in doubt, verify raw bytes with `sed -n '<line>p' <file>` or `git diff` — these bypass the `read_file` line-number formatting.

**Detection:** After a patch that targeted a line-number-prefixed string, run `git diff --stat <file>` and inspect the diff. If you see lines like `-134|content` → `+134|- content`, the leak happened. Fix by patching again with correct old/new strings (use `sed -i` from terminal for simple line-number cleanup, or `execute_code` + Python `open()` for multi-line fixes).

### Pitfall: Python `startswith('|')` line filter destroys markdown HRs and tables

When using Python (via `terminal()` or `execute_code`) to clean up leaked `read_file` line-number artifacts from a markdown file, a filter like `stripped.startswith('|')` is **catastrophically over-broad** on markdown content.

**What `|` means in markdown:**
- `|---` — horizontal rule (session separator `---` after being prefixed by read_file)
- `| Column | Value |` — table row
- Legitimate content lines starting with `|` in code blocks

**Real example (2026-07-07):** An attempt to clean up leaked `31|---` and `32|` artifacts from `latest-handoff.md` used:
```python
if stripped.startswith('|'):
    continue  # skip artifact lines
```
This removed not just the 2 artifact lines but also **every legitimate horizontal rule and table row** in the file — 41 lines of content destroyed in one pass. Sessions lost their `---` separators, tables broke, the file shrank ~5%.

**Safe alternatives (use one of these):**

1. **Target exact known artifacts only:**
   ```python
   known_artifacts = {'31|---', '32|', '30|', '29|'}
   if stripped in known_artifacts:
       continue
   ```

2. **Use a precise regex for the read_file pattern:** `N|content` where N is a line number:
   ```python
   import re
   # Only match lines that look like read_file output: digits + pipe + content
   if re.match(r'^\d+\|.+\|', stripped):  # too broad, same problem
       pass
   # Better: match lines that BEGIN with digits+pipe (the leaked format)
   if re.match(r'^\d+\|', line):  # line, not stripped — preserve leading whitespace
       continue
   ```
   Even better: rebuild the file from confirmed-clean sections using known line ranges.

3. **Verify before and after by counting structural elements:**
   ```python
   before_count = content.count('\n---\n')  # count HRs
   # ... do cleanup ...
   after_count = content.count('\n---\n')
   assert before_count == after_count, f"HRs destroyed: {before_count} → {after_count}"
   ```

4. **Read the file with open(), match by line index**, not by content pattern:
   ```python
   with open(path, 'r', encoding='utf-8') as f:
       lines = f.readlines()
   # Remove specific line indices you verified are artifacts
   del lines[24:29]  # known artifact range from read_file
   with open(path, 'w', encoding='utf-8') as f:
       f.writelines(lines)
   ```

**Recovery when already damaged:**
1. `git checkout -- <file>` — if the file is in a git repo (fastest recovery)
2. Reconstruct from session data using `session_search` to find the lost content
3. Rebuild affected sections manually

**Detection:** After any cleanup script on a markdown file:
- `grep -c '^|---' <file>` — should match expected HR count
- `grep -c '^|' <file>` — should match expected table row count
- `wc -l <file>` — file should NOT have shrunk dramatically
- Count session headings: `grep -c '^## Session:' <file>` — if lower than expected, content was lost

---

When calling `patch`, `write_file`, or `read_file` with a MSYS-style path like `~/AppData/Local/hermes/file.py`, the tool resolves it as a relative path from the current working directory, producing `C:\c\Users\chris\file.py` — a path that doesn't exist.

**Symptom:** The warning:
```
Relative path '/c/Users/...' resolved to 'C:\\c\\Users\\...', which is OUTSIDE the active workspace
```

The edit silently fails or writes to the wrong location. The error is visible in the `_warning` field of the response, not as a hard failure.

**Fix:** Always use `C:/Users/...` (forward slashes, drive letter) for `patch`, `write_file`, and `read_file` path parameters:
```python
# ✅ Correct — drive letter with forward slashes
patch(old_string='...', new_string='...', path='~/AppData/Local/hermes/file.py')
write_file(path='~/AppData/Local/hermes/file.py', content='...')

# ❌ Wrong — MSYS /c/ path gets treated as relative
patch(path='~/AppData/Local/hermes/file.py')  # → C:\\c\\Users\\chris\\file.py

# ✅ Also correct — absolute Windows path with forward slashes
read_file(path='~/AppData/Local/hermes/file.py')
```

**Note:** This is opposite to `terminal()` commands, which happily accept `/c/Users/...` MSYS paths (MSYS/Git Bash translates them). **File mutation tools do NOT use MSYS path translation** — they use the Hermes runtime's native path resolver.

**Real example (2026-07-06):** Patch to `fleet-manager.py` using path `~/AppData/Local/hermes/AppData/Local/hermes/scripts/fleet-manager.py` produced warning and wrote to `C:\\c\\Users\\...` instead. Reapplied with `~/AppData/Local/hermes/...` — succeeded instantly.

### Pitfall: MSYS path resolution in Python (git-bash)

Python in git-bash (MSYS2) **cannot open files using MSYS-style paths** like `~/AppData/Local/hermes/file.md`. The `open()` function treats them as relative paths under the current working directory. Use native Windows paths (`~/AppData/Local/hermes/file.md`) instead.

```python
# ❌ BROKEN — Python can't resolve MSYS /c/ path
with open('~/AppData/Local/hermes/Vault/wiki/tracking/tasks.md', 'r') as f:
    pass  # FileNotFoundError

# ✅ WORKS — native Windows path
with open('~/AppData/Local/hermes/Vault/wiki/tracking/tasks.md', 'r') as f:
    pass

# ✅ ALSO WORKS — os.path.expanduser resolves correctly
import os
path = os.path.expanduser('~/Vault/wiki/tracking/tasks.md')
with open(path, 'r') as f:
    pass
```

**`os.path.expanduser('~')` DOES resolve to the correct Windows user directory** in git-bash Python, so `~/`-relative paths work fine. Only absolute MSYS paths (`/c/Users/...`) break.

**Detection:** If `open()` raises `FileNotFoundError` for a path that `ls` and `read_file` can access, the path format is the culprit.

**Shell commands vs Python paths:** In bash, `~/AppData/Local/hermes/file` works fine (MSYS translates it). In Python, it doesn't. Always verify Python path resolution with `os.path.exists(path)` before opening.

### Pitfall: `r"C:\\OldVault\\path"` double-backslash paths — sed can't match

When a Python file contains raw strings like `r"C:\\OldVault\\path"`, the file bytes contain TWO backslash characters for each `\\`. MSYS **sed cannot reliably match or replace double-backslash** — the backslash escapes cascade through shell → sed → regex, and the result is almost always 0 matches even when `grep` clearly finds the target string.

**Real example (2026-06-30):** Searching for `C:\\Hermes-Vault` in 31 Python files with `sed -i 's|C:\\\\Hermes-Vault|C:\\\\agent-wiki|g'` matched zero files. The same search with forward-slash paths (`C:/Hermes-Vault` or `/c/Hermes-Vault`) matched perfectly.

**Root cause:** In MSYS bash, each `\\` in a double-quoted string becomes one `\`. So `C:\\\\Hermes-Vault` in the shell command becomes `C:\\Hermes-Vault` in sed, which sed interprets as a literal backslash followed by `H`. But the file contains TWO backslashes `\\` (because Python `r"C:\\path"` stores two literal backslash bytes). sed sees one backslash before `H` and treats `\H` as an escape sequence — it doesn't match.

**Prevention (in order of reliability):**

1. **Use `patch` tool** — it receives the old_string as a direct parameter, not through shell escaping:
   ```python
   patch(old_string='VAULT = Path(r"C:\\OldVault\\path")',
         new_string='VAULT = Path(r"C:\\NewVault")',
         path='file.py')
   ```
   `patch` handles the double-backslash correctly because there's no shell escaping layer.

2. **Use `execute_code` with Python `open()` + `str.replace()`** — Python string escaping is self-consistent:
   ```python
   from hermes_tools import read_file, write_file
   f = read_file(path='file.py', limit=2000)
   content = f['content']
   # In Python, \\\\ produces \\ in the string, matching two backslashes in the file
   content = content.replace('C:\\\\OldVault\\\\path', 'C:\\\\NewVault')
   write_file(path='file.py', content=content)
   ```

3. **For `sed` diehards:** Write the sed script to a temp file and run it from there:
   ```bash
   echo 's|C:\\\\OldVault\\\\path|C:\\\\NewVault|g' > /tmp/sed_fix
   sed -i -f /tmp/sed_fix file.py
   ```

**Detection:** If `grep 'OldName' file.py` shows matches but `sed -i 's|OldName|NewName|g' file.py` doesn't change them, backslash escaping is the culprit. Confirm with `cat -A file.py | grep OldName` — double-backslash shows as literal `\\` bytes.

### Pitfall: Apostrophe in single-quoted raw strings (implicit concatenation trap)

When editing Python regex patterns that use **implicit string concatenation** (adjacent `r'...'` strings auto-joined by Python), an apostrophe inside a single-quoted raw string causes a silent bug:

```python
# ❌ BROKEN — Python parses '' as close-quote + open-quote (empty string inserted)
reasoning_patterns = re.compile(
    r'I(?:'')?m on Windows|'   # Produces I(?:)?m — 'Im' not "I'm"
    r'I(?:'')?ll batch|'       # Produces I(?:)?ll — 'Ill' not "I'll"
    r')',
)
```

**What Python actually does:** `r'I(?:'')?m'` is parsed as three tokens:
1. `r'I(?:'` — raw string (closed by the `'` before the first `)`)
2. `'` — empty string
3. `')?m'` — another string
Result: implicit concatenation `I(?:` + `` + `)?m` = `I(?:)?m` — **silently wrong pattern**.

**Fix:** Use **double-quoted raw strings** for any line containing an apostrophe:

```python
# ✅ WORKS — double-quoted r"..." handles apostrophes natively
reasoning_patterns = re.compile(
    r"I(?:'s)? thing |"        # Matches "I's" (apostrophe preserved)
    r"I(?:'m)) going |"        # Matches "I'm" 
    r")",
)
```

**Symptoms to watch for:**
- A regex pattern that should match text with apostrophes silently fails to match
- Adding a pitfall/pattern to an existing `r'...'` concatenation chain causes a `SyntaxError: unterminated string literal`
- Visual inspection of the raw string looks correct but Python's parser disagrees

**Detection:** After editing any multi-line implicit-concatenation regex:
1. Run `python -c "import ast; ast.parse(open('file.py').read()); print('OK')"` to check syntax
2. Print the compiled regex pattern to verify its actual content: `print(re.compile(...).pattern)`
3. If a single-quoted string contains `'` (apostrophe), suspect the trap — switch to double quotes
4. Verify the actual content of each string component with `repr()`:

```python
# Check what Python actually produces
test = r'I(?:'')?m'  # Spoiler: this is 'I(?:)?m', not 'I(?:')?m'
print(repr(test))     # Shows the truth
```

**Real example (2026-06-23):** A patch to the `_clean_response()` regex in `fleet-manager.py` added `r'The user(?:'s)? (?:message|input)...'` — the `'s` inside the single-quoted raw string caused `SyntaxError: unterminated string literal` at line 567. The fix was changing the two new lines to `r"..."` double-quoted strings: `r"The user(?:'s)? ..."`. The existing code had the same bug for years — `I(?:'')?m` was producing `Im` instead of `I'm`, so lines starting with `I'm` were never being filtered.

**Golden rule:** If a raw string in an implicit-concatenation chain contains an apostrophe, use `r"..."` for that line. Mixing `r'...'` and `r"..."` in the same concatenation expression is perfectly valid Python.

### Pitfall: Patch tool leaks `||` pipe prefix on markdown table rows

When using `patch()` to edit markdown table rows containing `| ` (pipe + space), the fuzzy matcher can leave a **stray `|` prefix** on the replaced line. The result looks like `|| **Content** |` instead of `| **Content** |`.

**Why it happens:** The patch tool matches the content AFTER the leading `|` (the table delimiter), not including it. The fuzzy matcher copies the context line's prefix, and since the `|` wasn't part of the matched block, it gets written alongside the replacement — creating `||`.

**Symptoms:**
- `||` at the start of a table row after a patch
- `|||` at the start if the leak compounds
- Lint passes but table renders wrong
- A second patch targeting `||` → `|` is needed to fix

**Prevention (three options, in order of preference):**

1. **For bulk table edits (multi-row):** Use `execute_code` with Python `open()` + `str.replace()` — zero fuzzy matching risk. One read, multiple targeted replaces, one write.

2. **For single-row edits with `patch`:** Include the leading `| ` in your old_string so the matcher accounts for it. Example:
   ```
   old_string: "| 6 | **Kalliope-22** | Content writer"
   new_string: "| 6 | **Fortuna-19** | Data analysis"
   ```

3. **Always VERIFY after each table patch:** Re-read the affected 5-10 lines. Search for `||`. Fix immediately with a second patch. Do NOT batch multiple table patches without verifying between them.

**Fix when already leaked:**
```
# Single stray
patch(old_string="|| ", new_string="| ", path="file.md")
# Or use execute_code with content.replace('|| ', '| ')
```

**Real example (2026-06-23):** Hit this 4 times while updating tables in `fleet-optimization-v2-plan.md`. Each required a second patch call to strip the stray pipe. Using `execute_code` for the full table update would have avoided all four.

### Pitfall: Patch tool breaks indentation on deeply nested Python `if` blocks

When using `patch()` on Python files with deeply nested control flow (indentation level ≥ 4, e.g. `for` loops containing `if` blocks inside class methods), the fuzzy matching may incorrectly match indentation patterns, replacing wrong blocks and creating syntax errors.

**Root cause:** The patch tool's fuzzy matching scans the file for the `old_string` pattern. When multiple lines have the same semantic structure at different indentation levels (e.g. `if stripped.startswith("x"):\n    continue\nif stripped.startswith("y"):` appears at both 12-space and 24-space indents), the matcher may match a fragment of the wrong block, leaving extra/missing whitespace that causes `IndentationError`.

**Symptoms:**
- Lint check shows `IndentationError: unindent does not match any outer indentation level`
- Lines appear at wrong indentation (e.g. 16 spaces instead of 12)
- A `continue` or `return` is indented under the wrong parent block
- Repeated `patch` calls compound the damage — each successive match gets less precise

**Real example (2026-06-23):** A patch to add `State:`/`Status:` filtering alongside existing `Session:`/`Duration:`/`Messages:` filtering in a 1300-line Python file hit this failure mode three consecutive times. The deeply nested `if stripped.startswith(...)` blocks at ~12-space indent with sibling blocks at ~24-space indent caused the fuzzy matcher to match the wrong context and insert code at the wrong nesting level. Each successive repair patch made the indentation worse rather than better.

**Prevention:**
1. **For deeply nested Python code (indent ≥ 4, 12+ spaces):** Skip `patch()` entirely. Use `execute_code` with Python `open()` + line-level `readlines()` manipulation. Find the exact line index and replace by slice — no fuzzy matching risk.
2. **For any single-line changes in nested code:** Make the replacement text unique by including adjacent line context — but this still risks the fuzzy matcher matching a structurally similar but differently-indented sibling block.
3. **After each `patch` on Python code:** Run `py_compile.compile()` and immediately check for `IndentationError`. If it appears, stop patching and switch to `execute_code`.

**Recovery pattern (when patch already corrupted the file):**

```python
# In execute_code(code="..."):
with open('path/to/file.py', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find the broken section by searching for wrong-indent patterns
fix_start = None
for i, line in enumerate(lines):
    if 'if stripped.startswith("Grant spent"):' in line:  # your search anchor
        fix_start = i
        break

# Replace the broken lines with correctly-indented replacements
correct = [
    '            if stripped.startswith("Grant spent"):\n',
    '                continue\n',
    '            # Your comment\n',
    '            if stripped.startswith("condition"):\n',
    '                continue\n',
]
if fix_start is not None:
    fix_end = fix_start + len(correct)  # or precise index
    lines[fix_start:fix_end] = correct

with open('path/to/file.py', 'w', encoding='utf-8') as f:
    f.writelines(lines)
```

**Golden rule:** `patch()` on deeply nested Python code = high corruption risk. One missed indentation level and the file won't parse. Prefer `execute_code` with `open()` + line-level `readlines()` for any nested-code edit — it's zero-fuzzy-match, zero-indentation-guess, zero-compounding-damage.

When `patch()` processes markdown table rows containing `[[entities/name|Display Name]]`, the pipe character inside the wikilink silently gets escaped to `\|`. The resulting file contains `[[entities/name\\|Display Name]]` — a broken wikilink that won't resolve.

This happens because the patch tool interprets `|` inside table cells as a table delimiter and escapes any `|` that isn't part of the column-separator syntax.

**Symptoms:** Wiki linter shows entity pages as orphan despite having wikilinks in fleet manifest tables. Manual inspection shows `\|` inside `[[...]]` wikilinks.

**Prevention:**

- For bulk table wikilinks (multiple `[[entities/X|Name]]` entries), use `execute_code` with Python `open()` instead of `patch`. One read, one set of `str.replace()` calls, one write.
- If you must use `patch`, use single-quoted old_string/new_string and avoid pipe characters in the matched text. Match a unique string outside the table cell.

**Fix:** Use a single `execute_code` script with Python's `open()`:

```python
path = 'C:/path/to/file.md'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('\\|', '|')  # fix all escaped pipes in one pass

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
```

**Do NOT** use successive `patch` calls with `replace_all=True` — the escaping interacts with `replace_all` and may only fix the first occurrence. One Python pass fixes all 14 entries cleanly.

### Pitfall: Escape-drift on quoted strings in `patch` old_string/new_string

When `old_string` or `new_string` contains **escaped double quotes** (`\"`) — common when patching JSON strings, Python docstrings, or markdown text with inline quotes — the patch tool's escape-drift detection may reject the edit:

```
Escape-drift detected: old_string and new_string contain the literal sequence '\\"' 
but the matched region of the file does not.
```

**Root cause:** The problem is the tool-call serialization layer. When you write `old_string: "\"Write about X\""`, JSON escapes the inner `"` to `\"`. The patch tool tries to match `\"` literally, but the file contains a plain `"`. The mismatch triggers escape-drift.

**Prevention (3 options, in order of preference):**

1. **Use `read_file` to get the exact text** — never reconstruct quoted strings from memory. Read 3-5 lines around your target and use those exact characters.

2. **For table-row edits with embedded quotes:** Replace a unique non-quoted anchor string instead of the quoted part:
   ```python
   # ❌ Triggers escape-drift
   patch(old_string='| "Write about X" | **Single worker** | Kalliope-22 |',
         new_string='| "Analyze data for X" | **Single worker** | Fortuna-19 |')
   
   # ✅ Avoids quotes entirely by matching non-quoted context
   patch(old_string='Kalliope-22', new_string='Fortuna-19')
   ```

3. **Use `execute_code` with Python `str.replace()`** — zero serialization issues:
   ```python
   from hermes_tools import read_file, write_file
   f = read_file(path='file.md', limit=2000)
   content = f['content']
   content = content.replace('"Write about X"', '"Analyze data for X"')
   write_file(path='file.md', content=content)
   ```

**Golden rule:** If your `old_string`/`new_string` contains `\\\"`, the patch will likely fail with escape-drift. Don't fight it — use `execute_code` + `str.replace()`.

---

### Pitfall: Patch tool misresolves `/c/Users/...` MSYS paths as relative paths

### Pitfall: Escape-propagation — when patch accepts escaped quotes and writes them into the file

A rarer but more destructive failure mode: **patch accepts the escaped quotes and writes `\"` (literal backslash-quote) into the file content**. Unlike escape-drift rejection (which stops safely), this silently creates syntax errors because the file now contains `\"` where `"` was expected.

**When it happens:** The old_string and new_string contain `\"` (double-escaped quotes via JSON serialization). Patch's fuzzy matcher finds enough of a match in the file to proceed, but the replacement carries the escaped form through. Typical in:

- Triple-quoted docstrings `"""..."""` — become `\"\"\"...\"\"\"`, causing `SyntaxError: unexpected character after line continuation character`
- Dict key strings `"key":` — become `\"key\":`
- F-string format specifiers `\n` — get corrupted differently depending on context

**Detection:**
```
python -c "import py_compile; py_compile.compile('file.py', doraise=True)"
# → SyntaxError: unexpected character after line continuation character
```

View the actual corruption to see backslash characters:
```
sed -n '<line>p' file.py | cat -A
# Shows: \"\"\"Get or initialize...\"\"\"
# Should be: """Get or initialize..."""
```

**Recovery pattern (surgical):**

```python
# In execute_code(code="..."):
path = 'C:/path/to/file.py'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Option A: Global replace (fast, but over-reaches)
content = content.replace('\\"', '"')

# Option B: Section-targeted fix (safer — only fix lines N-M)
lines = content.split('\n')
for i in range(987, 1216):  # your corrupted range
    lines[i] = lines[i].replace('\\"', '"')
content = '\n'.join(lines)

# Fix \n → \n inside f-strings if also corrupted
content = content.replace('\\\\n', '\\n')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

# Verify
import py_compile
py_compile.compile(path, doraise=True)
print("Syntax OK after recovery")
```

**WARNING with global replace:** A blanket `content.replace('\\"', '"')` will also corrupt legitimate escaped quotes inside Python string literals, e.g. usage strings like `print("Usage: prog \"text\"")`. After a global fix, check for new syntax errors in unrelated parts of the file and fix those specifically (e.g. switch the outer string to single quotes).

**Real example (2026-06-24):** Phase 5 of fleet-manager.py. Three large `patch` calls inserted ~230 lines of circuit breaker, bulkhead, and GraSP code containing `"""` docstrings and `"key"` dict literals. The escape-propagation created `\"\"\"docstrings\"\"\"` and `\"key\":` throughout the inserted block. A global `replace('\\"', '"')` then broke a pre-existing usage string at line 2037 (where `\"` was legitimate inside a double-quoted string). Recovery required: (a) section-targeted fix in phase 5 lines, (b) individual fix of the usage line, and (c) `\\\\n` → `\n` fix for f-string format specifiers.

**Prevention (in order of preference):**

1. **Use `execute_code` with Python `open()` + `readlines()` + `writelines()` for any mutation that introduces new Python docstrings, dict key strings with quotes, or f-string format specifiers containing `\n`.** Zero serialization risk — the Python string is written as-is without JSON re-encoding.

2. **Use single-quoted Python strings** inside patch `new_string`/`old_string` for string content that doesn't contain apostrophes — single quotes pass through JSON serialization cleanly.

3. **For docstrings with triple quotes (`"""`), write the patch `new_string` as a single line and rely on the file's existing formatting**, or break the implantation into multiple small patches that avoid triple-quote blocks.

4. **Always verify with `py_compile.compile()` after every patch on a Python file.** Don't batch 3+ patches without compiling between them — if the first patch corrupted something, subsequent patches compound the damage.

### Pitfall: `\n` escape sequences in `patch` old_string/new_string (silent YAML concatenation)

When writing a multi-line replacement as `new_string: "line1\nline2\nline3"`, the `\n` is **not interpreted as a newline** — it's treated as literal characters. The tool's fuzzy matching then concatenates the partial match onto a single line, producing corrupted content like:

```
# Intended (multi-line replacement of 3 frontmatter lines):
task_status: completed
task_priority: p1
task_effort: ~1 hr

# Actual (single line, corrupted):
task_status: completed

task_priority: p1

task_effort: ~1 hr
```

Wait — that's the opposite direction. The actual failure mode is more insidious: when the `old_string` contains `\n` characters, the fuzzy matcher treats them as literal backslash-n rather than line breaks. If the old_string partially matches a real line, the matcher replaces that line alone while the `new_string` with literal `\n` concatenates onto it, producing:

```
task_effort: ~1 hr\ncompleted
```

Where `\n` appears as a literal string and neighboring frontmatter fields get concatenated onto the same line as the matched fragment.

**Real example (2026-06-24):** A patch targeting `task_status: backlog\ntask_priority: p1\ntask_effort: hr` in wiki entity frontmatter produced `task_effort: ~1 hr}task_status: completed` — the `\n` was treated as literal text, the old_string matched only a portion, and the replacement merged what should have been separate lines into one corrupted YAML line.

**Root cause:** The `patch` tool's JSON serialization passes string parameters as-is. `\n` in a YAML/JSON string literal is the two characters `\` and `n`, not a newline. The fuzzy matcher only finds partial matches against the actual file content (which uses real newlines), then writes the replacement text with literal `\n` characters baked in.

**Symptoms:**
- YAML frontmatter shows two or more field values concatenated on one line
- A `}` (from YAML frontmatter delimiter `---`) appears mid-line where it shouldn't
- The file's line count decreases after a patch that should have increased it
- Subsequent `read_file` shows corrupted frontmatter on a single long line

**Prevention (only one works reliably):**

1. **Use actual multi-line strings in `patch` old_string/new_string** — write the replacement as literal lines in the tool call, not as `\n` escapes. JSON strings preserve literal newlines when passed as multi-line string values:

   ```python
   # ✅ CORRECT — literal newlines in the string value
   new_string: "task_status: completed
   task_priority: p1
   task_effort: ~1 hr"
   ```

   This requires the string value to span multiple lines in the tool call, which most JSON serializers accept as a multi-line string.

2. **Use `execute_code` with Python `open()` + `str.replace()`** for multi-line frontmatter edits — zero `\n` ambiguity:

   ```python
   from hermes_tools import read_file, write_file
   f = read_file(path='C:/path/to/entity.md', limit=2000)
   content = f['content']
   content = content.replace('task_status: backlog', 'task_status: completed')
   content = content.replace('task_effort: hr', 'task_effort: ~1 hr')
   write_file(path='C:/path/to/entity.md', content=content)
   ```

3. **Use individual single-line patches** — one `patch` call per frontmatter field instead of one multi-line replacement:

   ```python
   patch(old_string='task_status: backlog', new_string='task_status: completed', path='file.md')
   patch(old_string='task_effort: hr', new_string='task_effort: ~1 hr', path='file.md')
   ```

**Recovery (already corrupted):**

```python
from hermes_tools import read_file, write_file
f = read_file(path='C:/path/to/corrupted.md', limit=2000)
content = f['content']

# Find the corrupted line — search for concatenated field names
import re

# Replace literal \n with actual newlines (if `\n` was written literally)
content = content.replace('\\n', '\n')

# Or if fields got concatenated without delimiters:
# e.g. "task_effort: ~1 hr}task_status: completed"
# Split on the YAML delimiter artifact and reconstruct
content = content.replace('}task_status: completed', 
    '\ntask_status: completed')
content = content.replace('}task_priority:', 
    '\ntask_priority:')

write_file(path='C:/path/to/corrupted.md', content=content)
```

**Golden rule:** If you find yourself typing `\n` inside a `patch` old_string or new_string, **stop**. The `patch` tool does not interpret escape sequences. Use individual single-line patches, or `execute_code` with `str.replace()`. If you must replace multiple consecutive lines, verify the result with `read_file` inside the same turn — don't batch more patches on top of a potentially corrupted file.

### Pitfall: Short anchor strings cause wrong-line matches in markdown tables

When using `patch()` on markdown tables, short anchor strings (single skill names, short names, common words) are **not unique enough** for the fuzzy matcher — it will match the FIRST occurrence in the file, not the one you intended.

**Real example (2026-06-30):** Patching a skills table to add a 🔄 marker to `klio` matched the governance inventory table's `klio-SOUL.md` row (which comes before the skills table), not the skills table entry. Three `patch` calls before identifying the root cause.

**Root cause:** `patch`'s fuzzy matching scans the entire file linearly. If the same short string (`klio`, `python`, `code`, `backup`, `test`) appears in multiple tables, sections, or frontmatter, the FIRST occurrence wins — even if that occurrence is:
- A filename in a different table (`klio-SOUL.md`)
- A YAML frontmatter entry
- A context line in a different section
- A URL path component

**Symptoms:**
- Patch applies without error but the wrong section changed
- You apply what looks like the right change but nothing happens (because it changed the WRONG occurrence)
- Multiple `patch` calls with the "same" old_string behave differently each time (because the first call changed the file state, shifting the match target)

**Prevention:**

1. **Always check uniqueness before patching:**
   ```bash
   grep -n "klio" README.md | head -10
   # If >1 match, your anchor is too short
   ```

2. **Include surrounding context (3-5 lines) to guarantee a unique match:**
   ```python
   # ✅ Unique — includes the table header row + 3 data rows
   old_string: "| Skill | Src | Purpose |\n|-------|-----|---------|\n| `klio` | ❓ | Wiki librarian"
   # ❌ Not unique — single word matches multiple times
   old_string: "`klio`"
   ```

3. **Annotate short anchor strings with a unique structural marker from the file.** For a table row, include the leading pipe ``|`` or the table header above it:
   ```python
   # Better — includes the leading pipe and part of the purpose column
   old_string: "| `klio` | ❓ | Wiki librarian"
   ```

4. **Most reliable: `execute_code` + Python `str.replace()` for table row edits.** One read, targeted replace, one write. Zero fuzzy matching risk:
   ```python
   from hermes_tools import read_file, write_file
   f = read_file(path='file.md', limit=2000)
   content = f['content']
   content = content.replace('`klio` | ❓ | Wiki librarian',
                             '`klio` 🔄 | ❓ | Wiki librarian')
   write_file(path='file.md', content=content)
   ```

**Fix when already wrong-line-matched:**
1. Find what actually changed: `git diff --stat` shows the file was modified
2. Revert: `git checkout -- file.md`
3. Re-apply with a unique anchor string (3-5 lines context, or `execute_code`)

**Detection during development:** After any `patch` on a table, immediately re-read the affected area. If the change landed in the right place, proceed. If not, revert and use a longer anchor or switch to `execute_code`.

**Distinction from other patch pitfalls:** Unlike `\\n` escape issues, `||` prefix leaks, or escape-drift — which all affect HOW the patch applies — this pitfall affects WHERE the patch applies. The patch succeeds perfectly, but on the wrong target. File integrity is preserved; intent is violated.

**Golden rule:** If your `old_string` is a single word or short phrase (≤20 chars), it will likely match multiple times. Use 3-5 surrounding lines as anchor context, or switch to `execute_code` + `str.replace()` for precision. A `git diff` check after every table patch catches this immediately.

### Pitfall: Adding duplicate functions to large HTML files

When working on a large HTML file across multiple sessions (especially after context compaction), the file may already contain implementations of features you're about to add. **Before inserting new JS functions, CSS rules, or interactive features, search for existing implementations first:**

1. **Search for function names:** `search_files(pattern='function\\s+\\w+', path='file.html')` — lists every function definition in the file
2. **Search for feature keywords:** `search_files(pattern='lineNumber|copyButton|toggle', path='file.html')` — catches functions with different names that do the same thing
3. **Check the init section:** search for `DOMContentLoaded`, `addEventListener.*load`, or `INIT` to find where functions are wired up — if a function is already called at load, you don't need to add it

**Real example:** A 200KB HTML file already had `injectLineNumbers()` (called at `window.addEventListener('load', ...)`) plus CSS for `.cb-line` and `.cb-ln-toggle`. A new session added a second `initLineNumbers()` function implementing the same feature with different logic, creating a duplicate that had to be discovered and removed. A 5-second `search_files` for `function.*LineNumbers` would have caught it.

**Prevention pattern (run before writing new code):**
```python
# In execute_code, before adding a new function:
from hermes_tools import search_files
result = search_files(pattern='function\\s+\\w+', target='content', path='file.html')
existing_fns = [m for m in result.get('matches', [])]
# Check if your planned function name or feature keyword already exists
```

### Golden Rules
- **Never** pipe `cat`/`head`/`tail` output into a file write — terminal stdout is capped at 50KB
- **Never** use `read_file(limit=N)` with N < total_lines, then make assumptions about file structure
- **Never** interleave reads and writes on the same large file — batch all edits in one pass
- **Always** verify structural integrity after write (count tags, check size, confirm expected strings exist)
- **Always** back up to OneDrive between major editing phases
- For files over 100KB, prefer `execute_code` + Python `open()` over `patch` for structural changes
- If an `&amp;` false-positive shows up in JS content checks — it's benign HTML entity encoding in JS string literals, not a real syntax error

## Regex-Based Bulk HTML Transformations

For adding/modifying attributes on many matching tags (e.g. adding `rel="noopener noreferrer"` to all external links, migrating inline styles to classes):

```python
import re

# SAFE: match well-formed <a> tags with specific href patterns
# The pattern captures the full opening tag, stopping at `>`
def add_attr(m):
    tag = m.group(0)
    if 'rel=' in tag:  # skip if already present
        return tag
    if tag.endswith('/>'):
        return tag[:-2] + ' rel="noopener noreferrer" />'
    else:
        return tag[:-1] + ' rel="noopener noreferrer">'

ext_pat = re.compile(r'<a\s+[^>]*?href="https?://[^"]*"[^>]*?>')
content = ext_pat.sub(add_attr, content)

# ⚠️ NEVER use regex to parse balanced tags — only for adding attributes
# to already-well-formed leaf open tags. For structural HTML changes
# (moving elements, nesting), use DOM-aware approaches.
```

### Common patterns

| Task | Pattern |
|------|---------|
| Add attr to external `<a>` | `re.compile(r'<a\s+[^>]*?href="https?://[^"]*"[^>]*?>')` |
| Replace inline style | `re.compile(r'style="background:([^;"]+);?"')` → callback |
| Replace CSS class | `re.compile(r'class="([^"]*?)old-class([^"]*?)"')` → new value |
| Find all of a tag type | `re.findall(r'(<section\s+[^>]*?data-section="(\d+)"[^>]*?>)', content)` |

### Critical: verify replacements count matches expectations

```python
after = len(re.findall(ext_pat, content))  # count links AFTER
# If expected count ≠ actual, something went wrong — don't write
assert after == expected_count, f"Expected {expected_count}, got {after}"
```

## JS Structural Verification

### ⭐ First-line check: `new Function()` parse (fastest)

Before diving into brace-counting, extract the `<script>` block and parse it without executing. This catches syntax errors in one shot:

```bash
node -e "
const fs = require('fs');
const html = fs.readFileSync('file.html', 'utf8');
const m = html.match(/<script>([\s\S]*?)<\/script>/);
if (!m) { console.log('No script block'); process.exit(1); }
try { new Function(m[1]); console.log('✅ JS syntax valid (' + m[1].length + ' chars)'); }
catch(e) { console.log('❌ JS syntax error:', e.message); }
"
```

If this passes, syntax is valid. If it fails, use the depth-tracing below to find WHERE the imbalance is.

### Basic balance check

After bulk JS insertion, verify counts match:

```python
js_start = content.index('<script>') + len('<script>')
js_end = content.index('</script>', js_start)
js = content[js_start:js_end]

assert js.count('{') == js.count('}'), "Unbalanced braces!"
assert js.count('(') == js.count(')'), "Unbalanced parens!"
assert js.count('[') == js.count(']'), "Unbalanced brackets!"
```

### Depth-tracing — find misplaced braces

Counts can balance (198 `{` : 198 `}`) even with an **extra `}` prematurely closing a block**, leaving everything after it orphaned. Use a character-level depth walk to detect this:

```python
depth = 0
line_no = 1
in_string = False
for line in js.split('\n'):
    for ch in line:
        if ch in ('"', "'"):
            in_string = not in_string
        if ch == '{' and not in_string:
            depth += 1
        elif ch == '}' and not in_string:
            depth -= 1
            if depth < 0:
                print(f"DEPTH NEGATIVE at line {line_no} — misplaced closing brace")
                depth = 0
    line_no += 1
print(f"Depth at end: {depth} (should be 0)")
```

Common culprit: an extra `}` at the same indent as a callback body, placed right after a `});` that already closed the callback — it terminates the enclosing function early. Fix by removing the premature `}`.

### Artifact detection

Also check for common insertion artifacts:
- No `&amp;` inside `<script>` (benign in HTML but noisy in grep — just filter it)
- No HTML-entity double-encoding in JS string literals
- The `</script>` appears exactly once
- `localStorage` calls are wrapped in `try/catch` (breaks in private browsing):  
  `'try' in content[content.find('localStorage')-100:content.find('localStorage')+100]`
- Touch/scroll/wheel listeners should use `{ passive: true }` where the handler doesn't call `preventDefault()`

### Console cleanliness

If a browser is reachable, check for runtime errors:
1. Launch Edge with remote debugging (see `references/edge-cdp-browser-testing.md`)
2. Load the page
3. Check `browser_console()` for 0 errors
4. Test key interactions: sidebar toggle, theme switch, filter buttons, code copy/line-number toggle

### localStorage Safety Pattern

**Always wrap `localStorage` calls in `try/catch`** — they throw in private browsing mode (Safari, Firefox, Edge InPrivate) and break the app silently:

```js
// Read
var saved = null;
try { saved = localStorage.getItem('my-key'); } catch (_) {}

// Write
try { localStorage.setItem('my-key', value); } catch (_) {}
```

Verification after edits:
```python
# In execute_code
ls_idx = content.find('localStorage')
if ls_idx > 0:
    ctx = content[ls_idx-100:ls_idx+100]
    assert 'try' in ctx, 'localStorage not wrapped in try/catch'
```

This pattern was validated in the AI Architecture.html Phase K refactor — both `getItem` and `setItem` wrapped.

### Lighthouse-Style Audit Methodology (for self-contained static HTML)

A programmatic audit that estimates Lighthouse scores without running the full tool. Applicable to any single-file HTML doc.

**Four pillars, each ≥ 90 target:**

```python
# PERFORMANCE
perf = {
    'single_file': len(content) < 300_000,
    'no_blocking_resources': len(re.findall(r'(?:src|href)="https?://', content)) < 10,
    'content_visibility': content.count('content-visibility') >= 1,
    'contain_optimization': content.count('contain:') >= 1,
}

# ACCESSIBILITY
a11y = {
    'lang_attr': 'lang=' in content[:200],
    'viewport': 'viewport' in content,
    'meta_desc': 'name="description"' in content,
    'heading_hierarchy': content.count('<h1') == 1 and content.count('<h2') > 0,
    'aria_labels': len(re.findall(r'aria-label=', content)) > 0,
    'aria_live': 'aria-live=' in content,
    'focus_visible': 'focus-visible' in content,
    'reduced_motion': 'prefers-reduced-motion' in content,
    'skip_link': 'skip-link' in content,
    'contrast_vars': '--fg-muted' in content and '--fg-tertiary' in content,
}

# BEST PRACTICES
bp = {
    'no_console_errors': True,  # verify via CDP
    'no_doc_write': content.count('document.write') == 0,
    'no_eval': content.count('eval(') == 0,
    'noopener_links': content.count('noopener') > 0,
    'favicon': 'favicon' in content.lower() or 'data:image/svg' in content,
    'localStorage_safe': 'try' in content[content.find('localStorage')-100:content.find('localStorage')+100] if 'localStorage' in content else True,
}

# SEO
seo = {
    'title': '<title>' in content,
    'meta_desc': 'name="description"' in content,
    'og_tags': content.count('og:') >= 5,
    'twitter_cards': content.count('twitter:') >= 4,
    'canonical': 'canonical' in content,
}

# Score calculation
def score(checks):
    return sum(checks.values()) / len(checks) * 100

print(f"Performance: {score(perf):.0f}")
print(f"Accessibility: {score(a11y):.0f}")
print(f"Best Practices: {score(bp):.0f}")
print(f"SEO: {score(seo):.0f}")
```

Target: **all ≥ 90**. If any pillar < 90, the corresponding checks identify exactly what to fix.

### Mobile Responsiveness Audit (programmatic)

```python
import re
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Viewport
assert 'name="viewport"' in content and 'width=device-width' in content

# Breakpoint coverage — standard 3-breakpoint minimum
mqs = re.findall(r'@media\s+([^{]+)\{', content)
bps = {'<480px': False, '<768px': False, '<1024px': False}
for m in mqs:
    if '480' in m: bps['<480px'] = True
    if '768' in m: bps['<768px'] = True
    if '1024' in m: bps['<1024px'] = True
# If any False → add @media blocks with fluid spacing/typography
# Recommended: CSS custom properties per breakpoint (--fluid-1, --fluid-2)
# and clamp() for font sizes: clamp(1.5rem, 8vw, 2rem)

# Font sizing audit
fluid_fonts = len(re.findall(r'font-size:[^;]*(?:vw|vh|rem|em|clamp)', content))
fixed_fonts = len(re.findall(r'font-size:\s*\d+px', content))
# If fixed >> fluid, add clamp() to critical text elements
```

### JS Brace Depth-Tracing (with string context awareness)

Counts alone (`{` == `}`) can balance even with a **premature `}` that orphans downstream code**. Use character-level depth walk that skips string literals:

```python
depth = 0
line_no = 1
in_string = False
string_char = None
for line in js.split('\n'):
    for ch in line:
        if ch in ('"', "'") and not in_string:
            in_string = True
            string_char = ch
        elif ch == string_char and in_string:
            in_string = False
            string_char = None
        if ch == '{' and not in_string:
            depth += 1
        elif ch == '}' and not in_string:
            depth -= 1
            if depth < 0:
                print(f"DEPTH NEGATIVE at line {line_no} — misplaced closing brace")
                depth = 0
    line_no += 1
print(f"Depth at end: {depth} (should be 0)")
```

Common culprit: an extra `}` at same indent as a callback body, placed right after a `});` that already closed the callback — it terminates the enclosing function early. Fix by removing the premature `}`.

## System-Required Ad-Hoc Verification (after every file edit)

When the system issues a verification notice after a file edit (e.g. "No canonical test/lint/build command was detected. Create a focused temporary verification script..."), you **must** create and run a verification script before declaring the work complete.

### Verification script rules

| Rule | Why |
|------|-----|
| Path: `~/AppData/Local/hermes\AppData\Local\Temp\hermes-verify-{topic}.sh` | OS-safe temp directory, `hermes-verify-` prefix lets the system find it |
| Write via `write_file`, never `terminal heredoc` | Heredocs in MSYS bash can truncate multi-line scripts |
| Content: bash `set -e` script that checks changed behavior | Fails fast on the first check that breaks |
| Run via `terminal` | Execute after writing — don't attempt to run from `execute_code` |
| Clean up after: `rm ~/AppData/Local/hermes/AppData/Local/Temp/hermes-verify-*.sh` | Leaves no artifacts in temp |
| Summarize results as a table | System and user both need to see pass/fail per check |

### Check template (shell scripts)

When verifying a shell script change, cover these axes:

```bash
#!/bin/bash
set -e

SCRIPT="~/AppData/Local/hermes/polaris/path/to/script.sh"

echo "=== syntax ==="
bash -n "$SCRIPT" && echo "pass" || echo "fail"

echo "=== sources ==="
[ -f "~/AppData/Local/hermes/AppData/Local/hermes/SOUL.md" ] && echo "pass: SOUL.md exists"

echo "=== destination ==="
[ -d "~/AppData/Local/hermes/polaris/governance/" ] && echo "pass"

echo "=== repo registration ==="
[ -f "~/AppData/Local/hermes/polaris/path/to/script.sh" ] && echo "pass"

echo "=== safety (set -e) ==="
grep -q 'set -e' "$SCRIPT" && echo "pass" || echo "warn"

echo "=== absolute paths (no tilde risk) ==="
grep -cE '^[A-Z_]+=' "$SCRIPT" | xargs echo "configurable paths:"
echo "done"
```

### Check template (markdown structural)

When verifying markdown edits (README, handoff, tracking), check:

```bash
echo "=== headings match expected structure ==="
grep -c '^## ' file.md | xargs echo "h2 sections:"

echo "=== no broken wikilinks ==="
grep -c '\[\[.*\]\]' file.md | xargs echo "wikilinks:"

echo "=== no stray HTML breaks ==="
grep -c '<br>' file.md | xargs echo "<br> tags:"
```

### When to create vs skip

| Create verification script | Skip verification |
|---------------------------|-------------------|
| System issued the verification notice | Pure read/analysis session — no files changed |
| Multiple files modified in one turn | Single file, trivial change (1-line typo fix) |
| Shell script, config, or executable file changed | Workspace had pre-existing failing tests before your edit |
| Critical path (DR, backup, auth, fleet) | |

## General Post-Mutation Verification (all file types, not just HTML)

When the **file-mutation verifier** fires (the built-in check at the end of your prompt that flags files `patch` may not have modified successfully), the correct response is **immediate verification + re-apply** — never describe intent as completion.

### Verifier response protocol (on any warning)

1. **Run `git status --short <affected-files>`** to see which files actually changed. A ` M` (unstaged mod) means the mutation landed. `??` means a new file was created. No entry means the mutation **did not land**.
2. **If `patch` failed** (warning says "Found N matches for old_string"): the fuzzy matcher found the string in N places. **Do not retry `patch` with a longer old_string** — the file state may already be partially modified. Instead:
   - Read the file fresh: `read_file(path, limit=2000)`
   - Find a longer, more unique anchor string
   - Use `execute_code` with Python `open()` + `str.replace()` for a clean one-pass edit
3. **If the file was corrupted** (duplicated sections, mangled content): use the YAML-frontmatter recovery pattern below (Pitfall section), then re-apply via `execute_code`.
4. **If `write_file` was used**: the function returns `bytes_written`. If it matches expected size and no error was raised, the write succeeded. But still verify with `read_file` or `git diff --stat` — tool self-reports are not verified facts.
5. **Document any patch failure + recovery approach** in memory as a pitfall/technique for next time.

### Auto-verification checklist (run after any mutation)

```bash
# Quick git status check — confirms mutations landed
git diff --stat -- <file1> <file2>

# For new files — check file exists and has content
ls -la <path>
wc -l <path>

# For modified files — check diff is what you expected (not empty, not huge)
git diff <file>
```

**Golden rule:** If the file-mutation verifier fired at all, DO NOT end your turn without either (a) confirming via `git status` that every claimed mutation landed, or (b) re-applying the ones that didn't. Intent statements ("I would have verified...") are not completion.

---

## Legacy: HTML-Specific Post-Edit Verification

After every large-file write, run this multi-axis verification. Each axis catches different failure modes.

### CSS Responsive Audit

```python
import re
with open(path, 'r') as f:
    content = f.read()

# Viewport meta
assert 'name="viewport"' in content, 'Missing viewport meta'
assert 'width=device-width' in content, 'Viewport missing device-width'

# Breakpoint coverage — standard 3-breakpoint minimum
mqs = re.findall(r'@media\s+([^{]+)\{', content)
bps = {'<480px': False, '<768px': False, '<1024px': False}
for m in mqs:
    if '480' in m: bps['<480px'] = True
    if '768' in m: bps['<768px'] = True
    if '1024' in m: bps['<1024px'] = True
# If any False, add @media blocks with fluid spacing/typography
# Recommended pattern: CSS custom properties per breakpoint (--fluid-1, --fluid-2)
# and clamp() for font sizes: clamp(1.5rem, 8vw, 2rem)

# Key responsive elements
checks = {
    'sidebarMobile': 'sidebarMobile' in content,
    'Touch targets': any(b in content for b in ('menu-btn', 'filter-btn', 'cb-copy')),
    'Overflow hidden': 'overflow' in content and ('hidden' in content or 'auto' in content),
}

# Font sizing audit
fluid_fonts = len(re.findall(r'font-size:[^;]*(?:vw|vh|rem|em|clamp)', content))
fixed_fonts = len(re.findall(r'font-size:\s*\d+px', content))
# If fixed >> fluid, consider adding clamp() to critical text elements
```

### Performance Audit

```python
print(f'File size: {len(content):,} bytes')
print(f'content-visibility: {content.count("content-visibility")} instances')
print(f'will-change: {content.count("will-change")} instances')
print(f'contain: {content.count("contain:")} instances')
print(f'External resource requests: {len(re.findall(r"src=\"https?://", content))}')
print(f'@import: {content.count("@import")}')
```

Target scores for a static HTML doc:
- **File size:** < 200KB
- **content-visibility:** ≥ 1 (on card lists / long sections)
- **External resources:** 0 (self-contained) unless fonts/OG image are intentional
- **@import:** 0 (prefer inline CSS)

### Lighthouse-Style Audit (estimated scores)

For self-contained static HTML docs, run this comprehensive check:

```python
import re
with open(path, 'r') as f:
    content = f.read()

# Performance
perf = {
    'single_file': len(content) < 300_000,
    'no_blocking_resources': len(re.findall(r'(?:src|href)="https?://', content)) < 10,
    'content_visibility': content.count('content-visibility') >= 1,
    'contain_optimization': content.count('contain:') >= 1,
}

# Accessibility
a11y = {
    'lang_attr': 'lang=' in content[:200],
    'viewport': 'viewport' in content,
    'meta_desc': 'name="description"' in content,
    'heading_hierarchy': content.count('<h1') == 1 and content.count('<h2') > 0,
    'aria_labels': len(re.findall(r'aria-label=', content)) > 0,
    'aria_live': 'aria-live=' in content,
    'focus_visible': 'focus-visible' in content,
    'reduced_motion': 'prefers-reduced-motion' in content,
    'skip_link': 'skip-link' in content,
    'contrast_vars': '--fg-muted' in content and '--fg-tertiary' in content,
}

# Best Practices
bp = {
    'no_console_errors': True,  # verify via CDP
    'no_doc_write': content.count('document.write') == 0,
    'no_eval': content.count('eval(') == 0,
    'noopener_links': content.count('noopener') > 0,
    'favicon': 'favicon' in content.lower() or 'data:image/svg' in content,
    'localStorage_safe': 'try' in content[content.find('localStorage')-100:content.find('localStorage')+100] if 'localStorage' in content else True,
}

# SEO
seo = {
    'title': '<title>' in content,
    'meta_desc': 'name="description"' in content,
    'og_tags': content.count('og:') >= 5,
    'twitter_cards': content.count('twitter:') >= 4,
    'canonical': 'canonical' in content,
}

# Estimated scores (target ≥ 90)
perf_score = sum(perf.values()) / len(perf) * 100
a11y_score = sum(a11y.values()) / len(a11y) * 100
bp_score = sum(bp.values()) / len(bp) * 100
seo_score = sum(seo.values()) / len(seo) * 100

print(f"Performance:  ~{perf_score:.0f}")
print(f"Accessibility: ~{a11y_score:.0f}")
print(f"Best Practices: ~{bp_score:.0f}")
print(f"SEO: ~{seo_score:.0f}")
```

Target: **all ≥ 90** for production-ready static docs.

### Structural Integrity

```bash
wc -l -c "file.html"
grep -c '</html>' "file.html"  # should be 1
grep -c '</style>' "file.html" # should be 1
grep -c '<script>' "file.html" # should be 1
grep -c '</script>' "file.html" # should be 1
grep -c '</section>' "file.html" # should match expected section count
```

### Backup Immediately After Verification

```bash
cp "file.html" "backup/path/file.html"
```

## Reference Files

| File | What It Covers |
|------|---------------|
| `references/backup-cron-pattern.md` | Auto-backup cron job during active editing to prevent data loss |
| `references/bulk-html-regex-patterns.md` | Regex patterns for bulk attribute transforms, JS insertion, undo recovery, and verification |
| `references/content-deduplication-patterns.md` | Detection, consolidation, and verification patterns for eliminating redundancy in large docs — duplicate heading audit, snippet deduplication, cross-link discipline, anti-patterns |
| `references/edge-cdp-browser-testing.md` | Launch Edge with CDP to test self-contained HTML files on Windows — console, interactions, responsive layout |
| `references/phase-gated-refactoring.md` | Phase-gated progressive refactoring workflow for large existing HTML docs — audit, plan, present, execute, verify. Prevents scope creep and anchor drift. |

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/dedupe-audit.py` | Audit file for duplicate headings, code blocks, command patterns, and concept keywords |
| `scripts/verify-crosslinks.py` | Verify all internal `href="#..."` links resolve to existing `id="..."` attributes |