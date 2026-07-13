# JSON Conversation Extraction Pipeline

Extract named conversations from a large JSON export file to prepare content for wiki enrichment. Prerequisite for Phase 3.5 (Enrich Existing Pages from a Source Document).

## When to Use

- You have a large JSON file (100+ entries) containing conversation objects
- You need to extract specific named conversations for wiki content
- You don't know the exact schema of the JSON entries upfront

## The Pipeline: Progressive Discovery

### Step 1 — Count & Validate Targets

Before any extraction, confirm your target entries exist. Write a minimal script:

```python
import json

with open('conversations.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

targets = [
    'Exact conversation name 1',
    'Exact conversation name 2',
]

found = 0
for conv in data:
    if conv.get('name') in targets:
        found += 1

print(f"Found {found} of {len(targets)}")
```

This catches misspelled names and structural surprises (e.g., the data is a dict, not a list) before you invest in a full extraction script.

### Step 2 — Inspect Structure

Don't assume you know the schema. Write a script to print the keys and one sample message structure:

```python
import json

with open('conversations.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

targets = ['First conversation name']

for conv in data:
    if conv.get('name') not in targets:
        continue
    
    print("Top-level keys:", list(conv.keys()))
    
    msgs = conv.get('chat_messages', [])
    print(f"Message count: {len(msgs)}")
    
    if msgs:
        first = msgs[0]
        print(f"Message keys: {list(first.keys())}")
        print(f"Sender field: {first.get('sender', 'MISSING')}")
        print(f"Text preview: {first.get('text', '')[:200]}")
        break
```

Common findings from real exports:
- `sender` values might be `'human'` / `'assistant'` — NOT `'user'` / `'ai'`
- Conversations may be nested under `chat_messages` key, not `messages`
- Entries might be sorted by creation date, not by appearance in the file

### Step 3 — Targeted Extraction (Phased)

Extract data progressively — don't dump everything at once:

**Phase A — Human messages only** (for wiki content about the user's preferences/interests):
```python
for conv in data:
    if conv.get('name') not in targets:
        continue
    
    msgs = conv.get('chat_messages', [])
    msgs.sort(key=lambda m: m.get('created_at', ''))
    
    for m in msgs:
        if m.get('sender') == 'human':
            print(m.get('text', ''))
```

**Phase B — Full conversation** (when both sides are needed for context):
```python
for conv in data:
    if conv.get('name') not in targets:
        continue
    
    name = conv['name']
    print(f"\n{'='*80}")
    print(f"CONVERSATION: {name}")
    
    msgs = conv.get('chat_messages', [])
    msgs.sort(key=lambda m: m.get('created_at', ''))
    
    for m in msgs:
        sender = m.get('sender', '')
        label = "HUMAN" if sender == 'human' else "CLAUDE"
        print(f"\n~~ {label} ~~")
        print(m.get('text', ''))
```

### Step 4 — Paginated Review via File

Pipe extraction output to a file, then read in chunks with `read_file`:

```bash
python3 extract_script.py > output.txt
```

Then:
- `read_file(path='output.txt', offset=1, limit=500)` — start reading
- `read_file(path='output.txt', offset=501, limit=500)` — continue
- Increase limit to 1000 if content is proving to be sparse or dense

### Step 5 — Reconcile Content to Wiki Pages

After reading all extracted content, create a mapping of conversation → wiki page before writing:

| Conversation | Wiki Page Type | Notes |
|-------------|---------------|-------|
| Coffee gear settings | Entity or Reference | User's specific tunings |
| Brewery recommendations | Reference | Place list with context |
| Tool purchases | Reference | Decision rationale |

Then write wiki pages following the `knowledge-base-organization` Phase 3 entity/concept/reference templates.

## Pitfalls

- **Inline Python in git-bash fails on syntax errors with `exit -1`** — Write `.py` files and run `python3 script.py` instead of pasting multi-line Python inline. Git-bash's handling of heredocs and inline Python is unreliable.
- **Key structure varies by export format** — Claude exports use `chat_messages`, `name`, `sender='human'`. ChatGPT exports have different keys. Always inspect first.
- **Output files can exceed 150K chars** — A dozen full conversations can easily generate 143KB+ of text. Use read_file offset/limit with 500-line chunks.
- **Line count ≠ char count** — read_file's limit is a LINE limit, not a char limit. If a conversation has very long messages, 500 lines might only cover 2-3 conversations. Adjust the limit up (to 1000-2000) for dense text.
- **Don't read the entire JSON into context** — The source JSON may be gigabytes. Python scripts stay on disk; only the extracted output enters your context window.

## File Organization

When working with extracted data, organize scripts and output in the working directory:

```
raw/imports/claude-data/
├── conversations.json           # Source (DO NOT edit)
├── find_convs.py                # Step 1: validate targets
├── inspect_structure.py         # Step 2: inspect schema
├── extract_human.py             # Step 3A: human messages only
├── extract_full.py              # Step 3B: full conversations
├── human_messages.txt           # Phase A output
└── full_convs.txt              # Phase B output
```

This layout keeps scripts reusable and output files available for paginated review without re-running extraction.
