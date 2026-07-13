# Stale-Task Watchdog Pattern

A concrete worked example of the **no_agent watchdog cron** for ADHD-friendly passive monitoring.

## Problem

Your tracking system has 140+ tasks. You forget about P1s after 3 days. You need a **passive nudge** — not an email, not an alert, just a quiet morning message when something's been sitting too long.

## Solution

A no_agent cron (zero tokens) that scans entity frontmatter daily, flags P1/P2 backlog tasks untouched >7 days, and stays **silent when clean**.

## Architecture

```
┌──────────────────┐    daily at 10am     ┌─────────────────────┐
│ stale-task-       │ ◄────────────────    │ Hermes cron         │
│ watchdog.py       │    (cron tick)       │ scheduler            │
│                   │                      │                      │
│ Reads entities/   │    ► stdout empty    │ Silent (no delivery) │
│ *.md frontmatter  │    = nothing stale   │                      │
│                   │    ► stdout non-     │ Verbatim delivery    │
│                   │    empty = stale     │ to user              │
│                   │    tasks found       │                      │
└──────────────────┘                      └──────────────────────┘
```

## Key Techniques

### 1. No YAML Library

```python
import re

def parse_frontmatter(path):
    with open(path, "r", errors="replace") as f:
        content = f.read()
    fm = {}
    m = re.match(r"^---\s*\n(.*?)\n---", content, re.DOTALL)
    if not m:
        return None
    for line in m.group(1).splitlines():
        if line.startswith("task_priority:"):
            fm["priority"] = line.split(":", 1)[1].strip().strip('"').lower().replace("p", "")
        elif line.startswith("task_status:"):
            fm["status"] = line.split(":", 1)[1].strip().strip('"').lower()
        elif line.startswith("title:"):
            fm["title"] = line.split(":", 1)[1].strip().strip('"')
    return fm
```

Why: no_agent scripts can't `pip install` anything. A single `re.match` on the YAML frontmatter delimiter avoids the dependency entirely. This is fast enough for 200+ entity files (completes in <100ms).

### 2. Silent-on-Clean Protocol

```python
if not stale:
    return  # exit 0, no stdout → no delivery
```

The critical design choice: **positive state produces no output**. The cron runner checks:
- stdout empty → user sees nothing (this is the happy path)
- stdout non-empty → delivered verbatim
- non-zero exit / timeout → error alert sent

### 3. Mtime-Based Staleness

```python
STALE_CUTOFF = time.time() - (7 * 86400)
mtime = os.path.getmtime(fpath)
if mtime >= STALE_CUTOFF:
    continue
```

Using file modification time is simpler than tracking `created` or `updated` in frontmatter. Any edit (including a status change) resets the clock. An entity that was `completed` and then reverted to `backlog` gets the full grace period again.

**Limitation:** mtime changes when *any* tool touches the file — even a read-only operation that happens to rewrite it (git checkout, sync script, editor autosave). For entities that change status programmatically via scripts, consider using frontmatter `updated` field instead:
```python
# Alternative: use frontmatter updated field
import datetime
updated_str = fm.get("updated", "")
updated = datetime.datetime.strptime(updated_str, "%Y-%m-%d").timestamp()
if updated >= STALE_CUTOFF:
    continue
```

## The ADHD Design Principle

This cron embodies a specific interaction pattern for ADHD users:

| Design Choice | Why It Works |
|---|---|
| **Daily, not hourly** | Weekly would be too late, hourly would be noise. Daily at 10am hits the morning planning window. |
| **Silent when good** | No notification = "everything's fine, keep going." Reduces anxiety about forgotten tasks when there are none. |
| **Verbose when bad** | When something IS stale, the message gives the exact wikilink + days stale + suggested action. Zero friction to act. |
| **7-day grace period** | A task added yesterday hasn't been "forgotten" — it's been "deferred." No guilt-tripping fresh tasks. |

## Registration

```python
cronjob(
    action='create',
    name='stale-task-watchdog',
    schedule='0 10 * * *',   # daily at 10am
    script='stale-task-watchdog.py',
    no_agent=True
)
```

## Verification

Test immediately with `cronjob(action='run', job_id='<id>')`. Silent stdout on a clean run confirms the pipeline works end-to-end.

## Sample Output

```
🧹 Stale Tasks — untouched for >7 days

  [🟡 P1] Get Fresh OpenRouter API Key — 11d stale
      wikilink: [[tracking/entities/fresh-openrouter-key|Get Fresh OpenRouter API Key]]
  [🟠 P2] Inventory Pending Pages — 9d stale
      wikilink: [[tracking/entities/inventory-pending-wiki-pages|Inventory Pending Pages]]

(2 tasks flagged)
⚡ Next action: open tracking/tasks.md and work through the 🎯 Focus section
```

## Extensions

- **Per-project sections** — group stale tasks by project (Fleet, Router, Wiki, etc.)
- **P0 escalation** — if a P0 is stale >3 days, use a shorter deadline and stronger language
- **Completion auto-ack** — cross-reference with a "just completed" list so a task completed at day 9 doesn't get flagged at day 10
