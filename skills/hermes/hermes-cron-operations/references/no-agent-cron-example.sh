#!/bin/bash
# Example no_agent cron: one-time backup to OneDrive
# Registered as:
#   cronjob(action='create', name='my-config-backup', schedule='every 6h',
#           script='no-agent-cron-example.sh', no_agent=True)
#
# Pattern: script lives under ~/.hermes/scripts/, referenced by basename only.
# Empty stdout = silent run (nothing to report = good).
# Non-zero exit = error alert sent to user.
set -e

HERMES="$HOME/AppData/Local/hermes"
DEST="$HOME/OneDrive/Vault/backups"
LOG="$DEST/.cron_log"

mkdir -p "$DEST"
date +"[%Y-%m-%d %H:%M:%S] Starting sync..." >> "$LOG"

# Config
if [ -f "$HERMES/config.yaml" ]; then
    cp "$HERMES/config.yaml" "$DEST/config.yaml"
    echo "  config.yaml ✓" >> "$LOG"
fi

# Memories
for f in USER.md MEMORY.md; do
    if [ -f "$HERMES/memories/$f" ]; then
        cp "$HERMES/memories/$f" "$DEST/$f"
        echo "  $f ✓" >> "$LOG"
    fi
done

# .env (secrets)
if [ -f "$HERMES/.env" ]; then
    cp "$HERMES/.env" "$DEST/.env"
    echo "  .env ✓" >> "$LOG"
fi

# Skills — only new/changed subdirs
if [ -d "$HERMES/skills" ]; then
    mkdir -p "$DEST/skills"
    for d in "$HERMES/skills"/*/; do
        skill=$(basename "$d")
        if [ ! -d "$DEST/skills/$skill" ]; then
            cp -r "$d" "$DEST/skills/$skill"
            echo "  skills/$skill (new) ✓" >> "$LOG"
        fi
    done
fi

echo "  Done." >> "$LOG"
