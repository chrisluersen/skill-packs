# Targeted Named-Conversation Extraction Session

*Session: 2026-07-07 — Extract 3 named Claude conversations → wiki draft + preferences file*

## Data Validation

This session processed 180 conversations from `~/agent-wiki/raw/imports/claude-data/conversations.json`.

### Schema Confirmation
- **Sender field:** `msg.get('sender')` → `'human'` / `'assistant'` ✅ (correct)
- **Role field:** `msg.get('role')` → `'unknown'` for ALL messages ❌ (trap)
- **Text field usable?** Yes, but some messages have `"This block is not supported on your current device yet"` placeholder — real content is in `msg.get('content')` array blocks
- **Message volume:** 20 ecosystem, 14 context-window, 10 memory-access messages

### Target Conversations Found

| Title | UUID | Human Msgs | Total Msgs | 
|---|---|---|---|
| Hermes ecosystem endpoint collection | `2a5a29cf-ae65-414c-a073-0922386e3383` | 10 | 20 |
| AI context window and compression settings | `352e33bf-633a-4e29-9447-989f16df0bc1` | 7 | 14 |
| Accessing user memory and conversation history | `ede5f4d9-91ae-4196-875e-42ef9231f78a` | 5 | 10 |

### Conversation Search Code (Python)

```python
import json
with open('conversations.json', 'r') as f:
    data = json.load(f)
    
target_names = [
    'Hermes ecosystem endpoint collection',
    'AI context window and compression settings', 
    'Accessing user memory and conversation history'
]

for conv in data:
    name = conv.get('name', '')
    for target in target_names:
        if target.lower() in name.lower():
            print(f'{target} -> {conv["uuid"]} ({name})')
```

This produces UUIDs. Then extract human messages:

```python
target_uuids = [
    '2a5a29cf-ae65-414c-a073-0922386e3383',
    '352e33bf-633a-4e29-9447-989f16df0bc1',
    'ede5f4d9-91ae-4196-875e-42ef9231f78a'
]

for conv in data:
    uuid = conv['uuid']
    if uuid in target_uuids:
        name = conv.get('name', '')
        print(f"\nCONVERSATION: {name}")
        human_count = 0
        for msg in conv['chat_messages']:
            sender = msg.get('sender', '')
            text = msg.get('text', '')
            if sender == 'human':
                human_count += 1
                print(f"\n--- HUMAN MESSAGE #{human_count} ---")
                print(text)
        print(f"\n--- Total human messages: {human_count} ---")
```

## Key Discovery: Need Assistant Messages Too

For understanding *decisions and rationale*, the assistant messages are essential — the human messages alone provide questions and preferences, but the assistant provides context, analysis, and tradeoff explanations that the human accepted. A full extraction should read both sides:

```python
for msg in conv['chat_messages']:
    sender = msg.get('sender', '')
    text = msg.get('text', '')
    print(f"\n--- {sender.upper()} ---")
    print(text)
```

## Dual Deliverable Produced

| Deliverable | Path | Contents |
|---|---|---|
| Wiki draft | `claude-extracted/wiki-drafts/hermes-tooling-ecosystem.md` | Comprehensive wiki page: frontmatter, overview, architecture, context/compression, memory, multi-agent, decisions, preferences |
| Preferences file | `claude-extracted/hermes-preferences.txt` | 15 verifiable preference statements with source conversation |

## Version Info

- Claude.ai export format: 180 conversations, all under one account
- Field map confirmed: `sender` (not `role`) is the correct field for human/assistant identification
- Summary field: high-signal markdown, usable for classification but NOT for regex title extraction

---

## Follow-Up: Subagent-Assisted Drafting (2026-07-07)

In a second pass, the extraction was followed by subagent-assisted wiki page drafting. Six wiki drafts were produced from the same export:

### Subagent Strategy

The extraction pipeline identified clusters (17 topic clusters from 145 conversations). For the deepest signal clusters, wiki page drafting was delegated to subagents:

| Delegated Task | Conversations Used | Subagent Outcome | Recovery Needed? |
|----------------|-------------------|-----------------|------------------|
| agent-store-architecture.md | "Defining agent-store's core purpose and roadmap" (58 msgs) | Completed — wrote 16K file ✅ | No |
| tech-stack-decisions.md | "Best terminal for your workflow", "Finding the right laptop for you", "Best open source AI models", "Cheapest AI provider comparison" | Hit tool limit before write_file ❌ | Yes — recovered from delegation cache |
| networking-docker-setup.md | 4 conversations from same cluster | Hit tool limit before write_file ❌ | Yes — recovered from delegation cache |

### Recovery Pattern Used

For the two failed subagents, recovery involved:

1. Located summary files at `~/AppData/Local/hermes\AppData\Local\hermes\cache\delegation\subagent-summary-N-<timestamp>.txt`
2. Read full content with `read_file` (386 lines, 18KB)
3. Used Python to strip `N|` line-number prefixes via regex
4. Found section markers like `### FILE 1: \`filename.md\`` and `### FILE 2: \`filename.md\``
5. Extracted content between markers, stripped fences and cleanup notes
6. Wrote files directly with `write_file`

### Lessons

- Subagents reliably hit tool limits (20 calls) before write_file — budget is consumed by extraction/analysis, not delivery
- Recovering from delegation cache is 2-3 tool calls vs. 20+ for re-delegation
- Manual extraction patterns were added to `ai-platform-data-extraction` SKILL.md v1.2.0