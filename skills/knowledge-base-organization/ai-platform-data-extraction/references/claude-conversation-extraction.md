# Claude Conversation Extraction Reference

*Session: 2026-07-07 — First Claude.ai extraction pipeline build*

## Data Structure

### conversations.json
Format: JSON array of 180 conversation objects.

**Top-level keys per conversation:**
```
uuid          — e.g. "6d661e28-15fe-435c-bd37-7fc6a2beb544"
name          — human-readable title
summary       — Claude.ai auto-generated markdown summary (GOLD — rich signal for extraction)
created_at    — ISO 8601 timestamp
updated_at    — ISO 8601 timestamp
account       — {"uuid": "39cf07de-388f-4049-ae69-7b74956f4449"}  (all same for user)
chat_messages — array of message objects
```

**Message keys:**
```
uuid                — string
text                — string (may contain placeholder text like "This block is not supported on your current device yet")
content             — array of content blocks (RICH — contains tool_use, text blocks)
sender              — "human" | "assistant"
created_at          — ISO 8601
updated_at          — ISO 8601
attachments         — array of attachment objects (can contain extracted_content — important for full-text extraction)
files               — array of uploaded file references
parent_message_uuid — for threading
```

**Content block types:**
- `type: "text"` — has `text` field
- `type: "tool_use"` — has `name`, `input`, `id` fields — tool execution
- Citations array may also be present

**IMPORTANT:** Both `msg["text"]` and `msg["content"]` must be read. The `text` field may have placeholders like "This block is not supported on your current device yet" while the actual content is in the `content` array. Tool use blocks only appear in `content`, not `text`.

### memories.json
Format: Single-element list containing:
```json
[{
  "conversations_memory": "long markdown string...",
  "project_memories": {"<project-uuid>": "project-specific memory..."},
  "account_uuid": "39cf07de-..."
}]
```

## Key Session Work Patterns

### Finding a Specific Conversation by Name

When the user asks "find the conversation about X", match on `conv['name']`:

```python
for conv in data:
    if conv.get('name') == "Exact Conversation Title":
        # Process this conversation
```

The `name` field is the human-readable title the user set — it matches the visible title in Claude.ai's UI.

### Single-Conversation Extraction Workflow

For targeted extraction (not batch pipeline):

1. **Scan first** — Load the JSON, find the target conversation, print its UUID/name/message count
2. **Write a focused script** — Small Python script that extracts JUST what's needed from THAT conversation
3. **Dump to a temp file** — Write extracted content to a `.txt` scratch file for reading
4. **Process and clean up** — Read the temp file, produce the deliverable, delete temp files

This pattern avoids:
- Polluting the batch pipeline with one-off extraction logic
- Re-reading the entire 180-conversation JSON for every small extraction
- Leaving temp files behind

### Temp File Cleanup

After targeted extraction, always clean up:
- Python extraction scripts (unless they're reusable pipeline tools)
- Dump/scratch text files
- Intermediate data artifacts

Use `rm -f <paths>` at the end. This keeps the workspace clean and avoids confusing future sessions.

---

## Claude-Specific Biases & Gotchas

### 0. Role Field: `role` vs `sender` — CRITICAL GOTCHA

**Do NOT use `msg.get('role')` to identify human vs assistant messages.**

The `role` field on messages is `'unknown'` for ALL messages in the export — both human and assistant. This is NOT the field you want for sender identification.

**Instead, use the `sender` field:**
```python
sender = msg.get('sender', 'unknown')  # Returns 'human' or 'assistant'
```

This was discovered in session 2026-07-07 during agent-store extraction: all 58 messages returned `role: 'unknown'` when using `msg.get('role')`, making the output useless for distinguishing speakers. The correct field name is `sender`.

**When you need to extract just the human's messages (Q&A mode where Claude interviews the user):**
```python
human_msgs = [msg for msg in conv['chat_messages'] if msg.get('sender') == 'human']
assistant_msgs = [msg for msg in conv['chat_messages'] if msg.get('sender') == 'assistant']
```

If you must use `role` as the field name (e.g. from an older export version), verify the field actually exists first:
```python
sample = conv['chat_messages'][0]
print(f"Available keys: {list(sample.keys())}")
print(f"role={sample.get('role')} sender={sample.get('sender')}")
```

### 1. Summary Field Quality
Claude.ai's auto-generated summaries are excellent — they capture the essence, decisions, and context of the conversation. They are the single highest-signal field for extraction. However, they are written in markdown, so regex extraction from them produces garbage (bold markers, structured lists bleeding into match groups).

**Fix:** Never open-ended regex on summaries. Use controlled keyword-to-path mapping.

### 2. Dual Message Representation
The `text` and `content` fields can diverge. Some messages have useful `text` but empty `content` (or vice versa). Tool-heavy conversations have most signal in `content` blocks.

**Fix:** Concatenate `text` + all `content[type=text]` blocks + attachment `extracted_content` for classification.

### 3. Account UUID Uniformity
All 180 conversations had the same account UUID (`39cf07de-...`). The skip-logic for non-user accounts never triggered in this dataset but should exist for multi-user exports.

### 4. Conversation Length Distribution

| Messages | Count | Notes |
|----------|-------|-------|
| 0        | 4     | Empty — always skip |
| 1        | 1     | Single orphan message |
| 2        | 86    | Single Q&A — most skippable |
| 3        | 2     | Usually still shallow |
| 4-6      | 54    | Moderate depth — likely has signal |
| 7-18     | 21    | Rich conversations |
| 20+      | 12    | Deep multi-turn — highest signal density |

The 2-message conversations are the hardest filter. Many are genuinely useful single-turn questions (equipment recommendations, technique questions) but many are generic "what is X" queries. The skip rule needs to catch the latter without filtering the former.

### 5. Summary Regex Artifact Example
Input summary text:
```
**Conversation Overview**

The person identified themselves as an AI engineer seeking a Mac mini setup recommendation...
```

Open-ended regex capture: `"with ram upgrade **conversation overview**...the person identified themselves as an ai engineer..."` — completely unusable.

**Fix applied:** Use a `descriptive_name_concepts` dict mapping trigger words to wiki paths, not open-ended summary pattern matching.

## Extraction Results (First Run)

Processed: 4 of 5 test conversations (1 skipped as "generic question match")
Categories: all 4 were `tech` (biased by test sample)
Signal counts: 4 concepts, 2 preferences, 11 recurring topics, 2 notable decisions

## Script Architecture Notes

The script is designed for piping — stdout gets the full JSON report, warnings go to stderr. This means you can:
```bash
python extract-claude-knowledge.py | jq '.summary'
python extract-claude-knowledge.py --dry-run
python extract-claude-knowledge.py | python -c "import sys, json; d=json.load(sys.stdin); print(d['summary']['warnings'])"
```

Per-conversation exports land in `--export-dir` for individual review before wiki ingestion. The script does NOT write to the wiki — that's the human review phase.