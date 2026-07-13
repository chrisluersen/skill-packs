---
name: ai-platform-data-extraction
description: "Extract structured knowledge from external AI platform exports (Claude.ai, ChatGPT, Gemini, Pi, etc.) — read JSON exports, classify conversations, extract concepts/preferences/decisions, and stage for wiki ingestion. The structured-data counterpart to wiki-content-migration (which handles file-based migration)."
version: 1.2.0
author: Hermes Agent
platforms: [windows, linux, macos]
metadata:
  hermes:
    tags: [wiki, extraction, ai-platforms, data-pipeline, claude, chatgpt]
    related_skills: [wiki-content-migration, wiki-planning, knowledge-base-organization]
created_from_user_sessions: true
---

# AI Platform Data Extraction

Use this skill when the user says:
- "extract knowledge from my Claude/ChatGPT/Gemini exports"
- "build a pipeline to process {platform} conversation data"
- "find wiki-worthy knowledge in my chat history"
- "categorize these conversations and extract what I should remember"
- Any request involving processing structured exports from external AI platforms

This is the **structured data extraction** sibling of `wiki-content-migration` (which migrates physical files). This skill covers reading JSON exports, classifying conversations, distilling signal (concepts, preferences, decisions), and staging extractions for human review before wiki ingestion.

---

## The WORKFLOW: Inspect → Classify → Extract → Stage → Review

### Step 1 — Schema-Discovery Pre-Flight (CRITICAL)

**Do this as a single one-shot inspection before writing any extraction logic.** A bad schema assumption can cost 5+ wasted iterations.

On the first turn, run ONE Python command that inspects everything:

```bash
python3 -c "
import json
with open('conversations.json', 'r') as f:
    data = json.load(f)
print(f'Total conversations: {len(data)}')
# Top-level keys of first conversation
print(f'Conversation keys: {list(data[0].keys())}')
# Sample message field names
sample = data[0]['chat_messages'][0]
print(f'Message keys: {list(sample.keys())}')
print(f'sender field: {sample.get(\"sender\", \"MISSING\")}')
print(f'role field: {sample.get(\"role\", \"MISSING\")}')
print(f'text field length: {len(sample.get(\"text\", \"\") or \"\")}')
content = sample.get('content', [])
if isinstance(content, list) and content:
    print(f'Content[0] type: {content[0].get(\"type\", \"N/A\")}')
print(f'Total messages: {sum(len(c[\"chat_messages\"]) for c in data)}')
"
```

**This single command answers:**
- The `sender` vs `role` field question (Claude.ai uses `sender`, NOT `role` — see the reference file for the full gotcha)
- Message volume for iterating all messages vs targeted extraction
- Whether `text` field is reliable or has placeholders
- Whether `content` blocks contain tool_use data
- Account UUID uniformity

**Only after this pre-flight, proceed to detailed structure:**

1. **Identify key fields**:
   - Conversation ID / UUID
   - Name / title
   - Summary (Claude.ai includes auto-generated summaries — gold for extraction)
   - Message list: sender (human/assistant), text, content blocks, attachments, files
   - Timestamps, account UUIDs
2. **Check for companion files** (e.g. `memories.json` alongside conversations)
3. **Count conversations** and message distribution — many single-turn Q&A may be skippable
4. **Check account UUID consistency** — verify all belong to the same user

**Output:** A clear picture of available fields and data volume. Document the message structure (especially `content` vs `text` fields — Claude uses both).

### Step 1.5 — Screen for Signal-Rich Conversations (Before Classification)

**Do this BEFORE designing classification rules or skip logic.** When the export has 180 conversations but only a fraction contain genuine knowledge about the user, this step identifies which ones to invest processing time on.

#### Why This Matters

In a 180-conversation Claude export, ~86 are single-turn Q&A (2 messages each). Of those, maybe 10 contain a genuine user preference or decision. The other 76 are "what is X" generic questions. Processing all 180 with the full pipeline wastes compute and produces a noise-heavy extraction index.

Instead: **find the signal density first**, then decide the pipeline approach.

#### The Technique: Score by Human Message Length

```python
import json

with open('conversations.json') as f:
    data = json.load(f)

scored = []
for conv in data:
    msgs = conv.get('chat_messages', [])
    human_chars = 0
    human_count = 0
    total = len(msgs)
    for msg in msgs:
        if msg.get('sender') == 'human':
            text = msg.get('text', '') or ''
            human_chars += len(text)
            human_count += 1
    
    score = {
        'name': conv.get('name', ''),
        'human_chars': human_chars,
        'human_msgs': human_count,
        'total_msgs': total,
        'avg_human_len': human_chars // max(human_count, 1),
    }
    scored.append(score)

scored.sort(key=lambda s: s['human_chars'], reverse=True)

for s in scored[:30]:
    print(f"{s['human_chars']:>8} chars ({s['avg_human_len']:>4}/msg, {s['human_msgs']} human msgs of {s['total_msgs']}) — {s['name'][:60]}")
```

#### What The Output Tells You

| Metric | What It Signals |
|--------|----------------|
| **High `human_chars` + high `avg_human_len`** | The user provided significant context — rich conversations about preferences, decisions, architecture explanations |
| **High `human_chars` but low `avg_human_len`** | Many short human messages — iterative debugging or multi-step code review, still has signal but less preference density |
| **Low `human_chars` but high `total_msgs`** | Assistant-dominated conversation (e.g. assistant built a website while human gave one-word prompts) — low knowledge extraction value |
| **Low `human_chars` + low `total_msgs`** | Single-turn generic Q&A — skip unless name matches a specific target topic |

#### Heuristic Thresholds (for 180-conversation Claude-scale exports)

| Human Chars | Avg Human Len | Recommendation |
|-------------|---------------|---------------|
| >10,000 | — | **Highest priority** — read every message. Architecture decisions, tool preferences, deep technical context |
| 5,000–10,000 | >200 | **High priority** — likely contains 3-5 verifiable preferences or decisions |
| 1,000–5,000 | >200/msg | **Medium priority** — spot-check; likely has 1-2 useful preferences |
| <1,000 | — | **Low priority** — skip unless name matches a known target topic |

#### Detecting the "Assistant Did All The Work" Pattern

Some conversations have high total message count but low human character count — the assistant was generating code, writing plans, or building artifacts while the human gave brief prompts.

**Real example:** A conversation with 315K total chars, 15 messages, avg human length 128 chars. The assistant built an 8K+ line website from prompts like "make it responsive" (4 chars). **Zero user knowledge to extract.**

**Detection:** If `avg_human_len` < 150 and total message chars > 50,000 → assistant-generated artifact. Skip for knowledge extraction.

**Soft filter:** If `avg_human_len` < 200 and `human_msgs` ≤ 5, the conversation may have signal from the initial question but won't contain deep preference data. Treat as low priority.

#### What This Feeds Into

The signal screen tells you which *pipeline mode* to use:

| Finding | Recommended Pipeline |
|---------|---------------------|
| 15+ conversations with >10K human chars each | **Full batch pipeline** (Step 2-7) — enough signal density to justify processing everything |
| 2-5 target conversations dominate the signal | **Targeted extraction** (Sub-Pattern below) — skip batch, extract exactly those conversations |
| No conversation exceeds 5K human chars | **Skip the batch.** Single-turn Q&A exports with no depth. Ask the user if they have a different dataset |

### Step 2 — Design Classification Rules

Build a category system matching the user's interests:

| Category | What it covers |
|----------|---------------|
| `hermes` | Hermes Agent, fleet, router, wiki, MCP, tooling |
| `tech` | hardware, GPU, networking, Docker, dev setup, code |
| `wow` | World of Warcraft, raiding, characters, gear |
| `coffee_food` | coffee, brewing, cooking, grilling, beer, restaurants |
| `personal` | location, housing, health, hobbies, travel |
| `other` | misc |

**Rules for keyword matching:**
- Build a `CATEGORY_KEYWORDS` dict mapping category → list of trigger phrases
- Use word-boundary regex for short keywords (≤5 chars) to avoid false positives
- Add category-specific boost patterns (e.g. "world of warcraft" → wow +3)
- Score all categories, pick the highest — ties broken by priority order

### Step 3 — Design Skip Logic

Not every conversation is worth extracting. Skip rules:

1. **Empty conversations** — no messages, no name → skip
2. **Non-user accounts** — if account UUID doesn't match the known user → skip
3. **Generic question patterns** — single-turn Q&A with no personalization:
   - "identify this font/flower/breed"
   - "what is X", "explain Y"
   - "can dogs eat Z" (pet food queries)
   - Test conversations (name contains "test")
4. **No category keywords matched** — if the corpus has zero hits across all categories and ≤2 messages → skip

**Capture the reason** for every skip in the output so the user can audit easily.

### Step 4 — Design Signal Extraction

For each non-skipped conversation, extract four signal types:

#### Concepts
- Derive from conversation name via keyword→wiki_path mapping (e.g. `"docker" → "concepts/docker-container-management.md"`)
- Named recommendation terms → wiki paths (e.g. `"mac mini" → "concepts/mac-mini-ai-setup.md"`)
- Summary pattern matching for architectural/technical concepts
- **Key principle:** Good concept titles come from a controlled mapping, not regex-on-summary. Summary regex produces garbage titles from markdown artifacts.

#### Preferences
- Category-prefixed regex patterns matching specific user statements
- Examples: "Prefers Ducky/mechanical wired keyboard", "Lives in Richmond, VA", "Uses Mac mini M4 Pro/Max for AI development"
- Attach `source_conversation` so the preference is traceable

#### Recurring Topics
- Tracked keyword sets with priorities (P1-P3)
- Count matches per conversation for frequency signal
- Examples: `hermes-agent (P1)`, `multi-agent-orchestration (P1)`, `wow-tbc-anniversary (P2)`, `specialty-coffee (P2)`

#### Notable Decisions
- Pattern-matched from summary text: recommendations, migrations, tool choices
- Include: decision text, rationale, context (category), type

### Step 5 — Build the Script

**Script structure:**
- Python 3, stdlib only (json, sys, os, argparse, re, collections)
- Load both conversations.json and optional memories.json
- Per-conversation try/except with warning logging
- Validate output format with a dedicated function checking all required keys

**CLI flags:**
| Flag | Purpose |
|------|---------|
| `--dry-run` / `-n` | Stats only, no full dump — piping-friendly |
| `--test` / `-t` | Process first 5 conversations, validate schema |
| `--export-dir` / `-e` | Directory for per-conversation JSON files |
| `--conversations` / `-c` | Path to conversations.json override |
| `--memories` / `-m` | Path to memories.json override |

**Output format** (single JSON object to stdout):
```json
{
  "summary": {
    "total_conversations": 180,
    "processed": 64,
    "skipped": 116,
    "warnings": [],
    "categories": {"hermes": 12, "tech": 28, "wow": 11, "coffee_food": 7, "personal": 4, "other": 2},
    "signal_counts": {"concepts": 45, "preferences": 23, "recurring_topics": 89, "notable_decisions": 14},
    "memories_loaded": true,
    "exported_files": 64
  },
  "extractions": [...],
  "skipped": [...]
}
```

### Step 6 — Test and Validate

Before full run:
1. Run with `--test` (first 5 conversations)
2. Validate: every extraction has conversation_id, name, category, all four signal arrays
3. Validate: every concept has title, summary, key_points, proposed_wiki_path
4. Check for garbled concept titles (summary regex artifacts)
5. Verify skip reasons make sense

### Step 7 — Stage for Review

The script's output goes to stdout (pipe-friendly). Per-conversation extraction files go to `--export-dir` for individual review. The actual wiki page creation is **not** done by the script — that's a separate review phase.

---

### Pitfall 6: Not Deleting Temp Scripts After Targeted Extraction

After writing a one-off Python script to extract data from a specific conversation, delete it when done:

```bash
rm -f find_convs.py extract_human.py inspect_structure.py debug_*.py output_dump.txt all_human_messages.txt
```

Leaving these around confuses future sessions ("why are there 4 slightly different extraction scripts here?"). Exception: if the script is a reusable pipeline tool, move it to a `scripts/` directory under the skill.

---

## Sub-Pattern: Targeted Named-Conversation Extraction for Wiki Drafts

Use this sub-pattern when the user asks you to extract knowledge from **specific named conversations** (not a batch pipeline) and produce wiki-ready outputs.

### Trigger
- "Extract knowledge from the conversations about X, Y, Z"
- "Find the conversation named 'X' and read the human messages"
- "Turn this conversation into a wiki page"

### Workflow

1. **Schema pre-flight** (see Step 1 above) — one-shot to confirm field names. This is critical because the `sender` vs `role` gotcha (Claude.ai uses `sender`) will otherwise waste 5+ iterations.

2. **Find target conversations** — Write a minimal Python script that matches on `conv['name']` (exact or case-insensitive substring):

   ```python
   import json
   with open('conversations.json') as f:
       data = json.load(f)
   targets = ['exact name A', 'exact name B', 'exact name C']
   for conv in data:
       for t in targets:
           if t.lower() in conv.get('name', '').lower():
               print(f'{t} -> {conv[\"uuid\"]} ({conv[\"name\"]})')
   ```

3. **Extract human messages** — second script targeting the UUIDs found:

   ```python
   target_uuids = ['uuid-1', 'uuid-2', 'uuid-3']
   for conv in data:
       if conv['uuid'] in target_uuids:
           for msg in conv['chat_messages']:
               if msg.get('sender') == 'human':  # NOT msg.get('role')!
                   print(msg.get('text', ''))
   ```

4. **Read the assistant side too** — to understand decisions and rationale, you need the assistant's responses. Dump all messages to a temp file for reading:

   ```bash
   python3 extract_script.py > output.txt
   ```

5. **Produce dual deliverable** — write both:
   - **Wiki draft** — comprehensive markdown page with frontmatter and sections, staged to a drafts directory (e.g., `claude-extracted/wiki-drafts/`)
   - **Preferences/decisions file** — a companion `.txt` or `.md` with verifiable preference statements extracted from the conversations, staged alongside the draft (e.g., `claude-extracted/hermes-preferences.txt`)

6. **Clean up** — remove temp scripts and dump files:

   ```bash
   rm -f find_convs.py extract_script.py temp_output.txt debug_*.py
   ```

### Variation: Subagent-Assisted Drafting with Cache Recovery

When a topic cluster has 4+ target conversations with deep signal, you can delegate the actual wiki page drafting to subagents via `delegate_task`. This lets you process clusters in parallel while you work on other things.

**When to use this variation:**

- 3+ wiki pages to write from dense conversations
- Each page requires synthesizing multiple conversations into a coherent narrative
- You want to continue other extraction work while drafting runs in the background

**How it works:**

1. **Do the extraction yourself first** — read source conversations, extract human messages, identify signal. The subagent's job is *drafting*, not *discovery*. Give it the extracted content in the `context` field.
2. **Delegate one subagent per wiki page** (or per cluster) — pass the relevant conversation content with a clear spec for the wiki page structure.
3. **Wait for delegation completion** — subagents run in the background. Continue other extraction work while they draft.
4. **Check for silent failure** — after the subagent reports completion, **check that the files were actually written**:
   ```bash
   ls -la drafts-directory/*.md
   ```
   Subagents commonly exhaust their 20-call tool budget before reaching `write_file`. The content exists in their reasoning but never lands on disk.

5. **Recover content from delegation cache** — if the files are missing, the subagent's output is saved in the delegation cache. Recovery procedure:

   ```python
   import re
   from hermes_tools import read_file, write_file

   # 1. Read the subagent summary file
   r = read_file(path="C:\\Users\\<user>\\AppData\\Local\\hermes\\cache\\delegation\\subagent-summary-N-<timestamp>.txt")
   content = r.get("content", "")

   # 2. Strip "N|" line-number prefixes read_file adds
   lines = content.split('\n')
   clean = []
   for line in lines:
       m = re.match(r'^(\d+)\|(.*)', line)
       clean.append(m.group(2) if m else line)

   # 3. Find section markers — subagent output uses ### FILE N: `filename.md`
   for i, line in enumerate(clean):
       m = re.search(r'### FILE (\d+): `([^`]+)`', line)
       if m:
           file_num = m.group(1)
           filename = m.group(2)
           # Extract content between this marker and the next
           # until closing ``` fence
           # [then write via write_file]
   ```

6. **Don't re-delegate** — the subagent already paid the token cost for extraction and drafting. Recovery from cache is a few `read_file` + `write_file` calls — cheaper than running the subagent again.

### Pitfall: Subagent Hits Tool Limit Before write_file

Subagents dispatched via `delegate_task` have a 20-call tool budget. Drafting a comprehensive wiki page from 500+ lines of conversation data easily consumes this in extraction/analysis calls before reaching `write_file`. **This is the expected failure mode, not an exception.**

**Detection:** After the subagent reports completion, `ls -la` the target directory. If files are absent, the subagent hit its limit.

**Recovery** (use instead of re-delegating):

1. Find the summary file: `C:\Users\<user>\AppData\Local\hermes\cache\delegation\subagent-summary-N-<timestamp>.txt` (the completion message includes the exact path)
2. Read the file with `read_file(path=..., limit=<total_lines>)` — get the complete content
3. Strip line-number prefixes: the `read_file` output adds `N|` before each line. Use `re.match(r'^(\d+)\|(.*)', line)` in Python
4. Extract embedded file content: the subagent's output includes the full content of each wiki page wrapped in:
   ```
   ### FILE N: `filename.md`
   
   ```markdown
   ...content...
   ```
   ```
   Find these section markers to locate each file
5. Strip markdown fences (` ```markdown ` / ` ``` `) and trailing cleanup notes
6. Write with direct `write_file` — the subagent did the synthesis work; you just land the artifact

**Don't re-run the subagent.** The content is already synthesized in the cache — the only gap is the final write. Recovery takes 2-3 tool calls vs. 20+ for a fresh delegation.

### Dual-Deliverable Format

**Wiki draft**: Comprehensive markdown with:
- YAML frontmatter (title, description, tags, created, sources)
- Overview section
- Thematic sections for each major topic addressed
- Decision tables with rationale
- Cross-links to related wiki pages
- Companion file pointer at the end

**Preferences file** (`*-preferences.txt`):
- One verifiable statement per line, prefixed with `PREF N:`
- Source conversation noted
- Clear enough to be consumed by a script or an agent in a future session
- Only concrete preferences/decisions, not context or narrative

### Pitfalls

- **Don't use `role` field** — Claude.ai messages have `role: 'unknown'` for ALL messages. Use `sender` instead. (This is the #1 wasted-iteration trap.)
- **Don't iterate** — Run the schema pre-flight ONCE before writing any script. If you write a script that uses `msg.get('role')`, you'll get back 0 human messages and waste the whole turn debugging.
- **Don't leave temp files** — The extraction scripts are single-use. Delete them when the deliverable is produced. Only keep the deliverable files.
- **Don't embed narrative in the preferences file** — It should be parseable by a future agent, not a human reader. One preference per line, atomic, verifiable.

---

## Execution Tips

### Handling Claude.ai's Dual Message Fields
Claude.ai messages have both `text` (string, sometimes truncated) and `content` (list of blocks with tool_use, text, etc.). For classification, concatenate both:
```python
text = msg.get("text", "") or ""
content = msg.get("content")
if isinstance(content, list):
    for block in content:
        if isinstance(block, dict) and block.get("type") == "text":
            text += " " + block.get("text", "")
```

### Summary Regex Pitfalls
Claude.ai summaries are markdown text with **bold**, code blocks, and structured lists. Feeding them directly into regex concept extraction produces garbage titles like `"With ram upgrade **conversation overview**...the person identified..."`. **Fix:** use controlled keyword→wiki_path dict mapping instead of open-ended regex on summaries.

### Memories.json Structure
Claude.ai's `memories.json` is often a single-element list containing a dict with:
- `conversations_memory` (long string — the user profile)
- `project_memories` (dict keyed by project UUID)
- `account_uuid` (matches conversations)
Use this for user context but don't mix it into conversation-level extraction.

### Windows Paths
Use MSYS-compatible paths: `~/agent-wiki/raw/imports/claude-data/conversations.json` (forward slashes, no escaping needed in Python).

---

## Common Pitfalls

### Pitfall 1: Regex-Generated Concept Titles
Regex on summary text produces markdown artifacts. **Always use controlled keyword→wiki_path mapping** for concept titles instead.

### Pitfall 2: Overly Broad Skip Patterns
The word `"test"` in a conversation name doesn't always mean it's a test — use `\btest\b` with word boundaries. Check: "AI testing framework" should NOT be skipped.

### Pitfall 3: Forgetting to Handle Both `text` and `content`
Only reading `msg["text"]` misses tool_use blocks, citations, and rich content. Always concatenate from both fields.

### Pitfall 4: Memory Field Shape Assumptions
`memories.json` may be a list or a dict. Always check `type(mem).__name__` before accessing keys.

### Pitfall 5: Output Format Drift
As the extraction grows, validate output shape with a dedicated function to catch missing or renamed keys early.

### Pitfall 6: Checking `role` Instead of `sender` on Claude Messages
Claude.ai export messages use `sender` (`"human"` / `"assistant"`) NOT `role` (`"human"` / `"assistant"` / `"tool"`). The `role` field exists but returns `"unknown"` for ALL messages — checking `msg.get('role')` will make every message look like the same sender. **Always use `msg.get('sender')`.** Verify with a sample message's keys if the export format version is uncertain.

### Pitfall 7: Assuming All Exports Need the Full Pipeline
Not every extraction task needs the full batch-pipeline script. When the user asks for a single specific conversation (by name), use targeted extraction instead:
1. Find `conv['name']` matching the title
2. Write a focused Python script for THAT conversation
3. Dump to a scratch file, read, process, clean up
This is faster, cleaner, and avoids polluting the batch pipeline with one-off logic.

---

## Verification Checklist

- [ ] Data structure inspected and understood before writing code
- [ ] Skip rules documented and tested against sample
- [ ] Concept titles use controlled mapping, not open-ended regex
- [ ] `--test` flag validates output schema
- [ ] All conversations inside try/except with warning logging
- [ ] Memory JSON shape-checked before key access
- [ ] Output goes to stdout (pipe-friendly), warnings to stderr
- [ ] Per-conversation export writes to configurable directory
- [ ] Dry-run mode produces stats-only JSON

---

## References

- `references/claude-conversation-extraction.md` — The specific Claude.ai export structure and extraction rules developed in session 2026-07-07, including data field maps, Claude-specific biases, and discovered gotchas
- `references/targeted-conversation-extraction-session.md` — Worked example of the targeted named-conversation extraction sub-pattern: find 3 specific conversations by name, extract human messages, produce wiki draft + preferences file. Covers schema confirmation, UUID discovery, dual-deliverable format, and temp file cleanup.