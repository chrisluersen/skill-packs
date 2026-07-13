# Cron Output Directory Maintenance

## Overview

Hermes cron jobs write their stdout to `~/.hermes/cron/output/<job_id>/<timestamp>.md` files. Each run creates a new timestamped file. For recurring jobs (e.g. every 5 minutes), this accumulates quickly — 12 jobs × 12 runs/hour × 24 hours = 3,456 files/day.

## Directory Structure

```
~/.hermes/cron/output/
├── 169a69e2d9ae/           # Job ID directory
│   ├── 2026-06-27_19-41-48.md
│   ├── 2026-06-27_19-36-47.md
│   └── ...
├── 9141c4f062de/
│   ├── 2026-06-27_19-40-45.md
│   └── ...
└── a9f6a2af338b/           # Oldest — Jun 17
    └── 2026-06-17_23-44-00.md
```

## Purging Old Output

### Manual purge by age

```bash
# Find directories older than N days
find ~/.hermes/cron/output -type d -mtime +7 -print

# Remove them (dry-run first)
find ~/.hermes/cron/output -type d -mtime +7 -exec rm -rf {} +
```

### Selective purge by job ID

```bash
# Remove a specific job's output directory
rm -rf ~/.hermes/cron/output/a9f6a2af338b/
```

### Windows (PowerShell)

```powershell
# Remove directories older than 7 days
Get-ChildItem "$env:LOCALAPPDATA\hermes\cron\output" | 
  Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } | 
  Remove-Item -Recurse -Force
```

### Git-bash on Windows

```bash
find ~/AppData/Local/hermes/AppData/Local/hermes/cron/output -type d -mtime +7 -exec rm -rf {} +
```

## Automation

### no_agent cron job for auto-purge

Create a script at `~/.hermes/scripts/cron-output-purge.py`:

```python
#!/usr/bin/env python3
"""Purge old cron output directories (>7 days)."""
import os
import shutil
import time
from pathlib import Path

OUTPUT_DIR = Path.home() / "AppData" / "Local" / "hermes" / "cron" / "output"
AGE_DAYS = 7

cutoff = time.time() - (AGE_DAYS * 86400)

for job_dir in OUTPUT_DIR.iterdir():
    if not job_dir.is_dir():
        continue
    try:
        mtime = job_dir.stat().st_mtime
    except OSError:
        continue
    if mtime < cutoff:
        shutil.rmtree(job_dir)
        print(f"Purged: {job_dir.name}")
```

Register as a no_agent cron:

```python
cronjob(
    action='create',
    name='cron-output-purge',
    schedule='every 1d',
    script='cron-output-purge.py',
    no_agent=True
)
```

### Pitfalls

- **File handles on Windows** — A stale file handle can prevent directory deletion. If `rm -rf` fails with "Permission denied" or "Directory not empty", reboot and try again. The cron scheduler holds file handles open during execution; a reboot clears them.
- **Active job output** — Don't purge a job's directory while it's actively writing. The purge script above checks modification time, not active processes. For safety, run the purge when cron activity is low (e.g. not during a job's scheduled window).
- **Symlinks** — The output directory may contain symlinks if jobs use `workdir`. The purge script above handles them via `shutil.rmtree` which resolves symlinks.

## Retention Policy

| Age | Action | Rationale |
|-----|--------|-----------|
| < 1 day | Keep | Active debugging |
| 1-7 days | Keep | Recent history, may need rollback |
| 7-30 days | Purge | Stale, low value |
| > 30 days | Purge | Archive-only value |

For jobs that produce high-value output (e.g. daily synthesis, watchdog alerts), consider archiving to a dated tarball instead of deleting:

```bash
# Archive and purge
cd ~/.hermes/cron/output
tar -czf ../../cron-output-archive-$(date +%Y-%m-%d).tar.gz *
rm -rf *
```

## Verification

After purging, verify the cron system still works:

```bash
# Trigger a test job
cronjob(action='run', job_id='<any-active-job>')

# Check new output appears
ls ~/.hermes/cron/output/<job_id>/
```
