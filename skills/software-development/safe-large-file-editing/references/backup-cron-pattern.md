# Auto-Backup Cron Pattern for Active Editing

When editing large files (>100KB) across multiple turns/phases, use a `no_agent` cron job to auto-backup to a safe location (OneDrive, network drive, etc.) on a schedule.

## The Script

A simple shell script that checks if the file changed (via md5sum) and only copies when different — silent when unchanged, brief notification on backup:

```bash
#!/usr/bin/env bash
SRC="~/AppData/Local/hermes/AI Architecture.html"
DST="~/AppData/Local/hermes/OneDrive/AI Architecture.html"

if [ ! -f "$SRC" ]; then exit 0; fi

SRC_HASH=$(md5sum "$SRC" 2>/dev/null | cut -d' ' -f1)
DST_HASH=$(md5sum "$DST" 2>/dev/null | cut -d' ' -f1)

if [ "$SRC_HASH" != "$DST_HASH" ]; then
  cp "$SRC" "$DST"
  SRC_SIZE=$(wc -c < "$SRC")
  echo "📁 Backed up ($SRC_SIZE bytes)"
fi
```

Save as `~/AppData/Local/hermes/scripts/backup-<name>.sh`.

## Create the Cron Job

```
cronjob action=create
  name="<description>"
  schedule="every 30m"
  script=<scriptname>.sh
  no_agent=true
  enabled_toolsets=["terminal"]
```

## How It Works

- **`no_agent=true`** — no LLM call per tick. The scheduler just runs the script.
- **Silent when unchanged** — empty stdout means no notification.
- **Verbose when backed up** — non-empty stdout is delivered as a message.
- **`enabled_toolsets=["terminal"]`** — only loads the terminal tool, not the full agent toolkit. Saves token overhead.
