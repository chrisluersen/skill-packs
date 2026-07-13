---
name: session-wiki-pipeline
description: >-
  Two complementary Python scripts convert Hermes Agent sessions into wiki
  insight pages. session-to-page.py extracts session insights via heuristic or
  LLM; compiled-truth.py scans wiki pages for factual claims and cross-references
  them. Both write to pending/ for human review.
tags:
  - wiki
  - session
  - pipeline
  - insight-extraction
  - tracking
---

# Session → Wiki Pipeline

Two scripts in `~/.hermes/scripts/` bridge Hermes sessions and the wiki:

| Script | Purpose | Output |
|--------|---------|--------|
| `session-to-page.py` | Extract session conversations → insight pages | `pending/` |
| `compiled-truth.py` | Scan wiki pages → claim cross-references | `pending/` |

Both use a tracking DB to avoid reprocessing and skip cron sessions by default.

## Quick Usage

```bash
# session-to-page (heuristic default, no LLM cost)
python ~/.hermes/scripts/session-to-page.py

# compiled-truth (heuristic only)
python ~/.hermes/scripts/compiled-truth.py

# Both in LLM mode (requires OPENROUTER_API_KEY)
python ~/.hermes/scripts/session-to-page.py --mode llm
python ~/.hermes/scripts/compiled-truth.py --mode llm

# Dry runs
python ~/.hermes/scripts/session-to-page.py --dry-run
python ~/.hermes/scripts/compiled-truth.py --report
```

## Options

### session-to-page.py

| Flag | Default | Description |
|------|---------|-------------|
| `--mode` | `heuristic` | `heuristic`, `llm`, or `hybrid` |
| `--hours` | `48` | Session age window (hours) |
| `--limit` | `5` | Max sessions to process |
| `--include-cron` | False | Include `cron_` prefixed sessions |
| `--dry-run` | False | Print what would be done |
| `--db` | auto | Override state.db path |

### compiled-truth.py

| Flag | Default | Description |
|------|---------|-------------|
| `--mode` | `heuristic` | `heuristic`, `llm`, or `hybrid` |
| `--source` | all | Specific wiki page(s) to scan |
| `--report` | False | Generate report only (no writes) |

## Common Tasks

### Run both scripts daily (cron)

```bash
python ~/.hermes/scripts/session-to-page.py --hours 24 --limit 10
python ~/.hermes/scripts/compiled-truth.py
```

### Check tracking status

```bash
# Count processed sessions
python3 -c "
import sqlite3
c = sqlite3.connect(r'~/AppData/Local/hermes\AppData\Local\hermes\data\tracking\tracking.db')
print('Processed:', c.execute('SELECT COUNT(*) FROM processed').fetchone()[0])
print('Recent:', c.execute('SELECT processed_at, session_id, title FROM processed ORDER BY processed_at DESC LIMIT 5').fetchall())
"
```

## Architecture Notes

- Both scripts write to `pending/` — no pages are promoted without human review
- Cron sessions (`cron_*`) are filtered by default — they're auto-generated and contain no useful insights
- Tool messages are excluded from conversation reconstruction
- Minimum message content threshold: 10 characters
- Tracking DB lives at `$HERMES_HOME/data/tracking/tracking.db`

## Testing

```bash
cd ~/agent-wiki
python3 -m pytest tests/test_session_to_page.py tests/test_compiled_truth.py -v
```

## Pitfalls

- **OPENROUTER_API_KEY must be set** for LLM mode. Without it, LLM mode falls back to heuristic silently.
- **Tracking DB must exist** — `init_tracking_db()` creates it automatically on first run.
- **Path resolution** — scripts use `HERMES_HOME` env var or default to `~/AppData/Local/hermes\AppData\Local\hermes`. Override via `--db` flag.
- **state.db locking** — don't run while Hermes is writing a session; use cron scheduling during idle hours.
- **Double processing** — the tracking DB prevents reprocessing, but if you delete tracking.db, everything re-processes. Delete individual tracking entries sparingly.
