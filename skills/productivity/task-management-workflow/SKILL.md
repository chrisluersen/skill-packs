---
title: Task Management Workflow (CLI + Dashboard)
name: task-management-workflow
description: Full-stack task management — create, track, update, and complete tasks via CLI with auto-generated dashboards
type: workflow
tags: [tracking, tasks, cli, automation, workflow]
---

# Task Management Workflow

## Architecture

Three layers:
1. **Entity files** (`tracking/entities/*.md`) — YAML frontmatter is the source of truth
2. **CLI** (`hermes task ...`) — fast one-shot operations on entities
3. **Dashboards** — auto-generated every 60 min by cron

## CLI Commands

```bash
# Interactive creation
hermes task create

# Fast non-interactive
hermes task create "Install Neovim" --priority p1 --project personal --plan tools-setup --effort "~30 min"

# Status transitions — updates entity + regenerates dashboards + logs
hermes task done install-neovim     # fuzzy match: "neovim" works
hermes task start neovim
hermes task block neovim --blocked-by openrouter-key
hermes task unblock neovim
hermes task backlog neovim

# Attributes
hermes task priority neovim p1
hermes task effort neovim "~15 min"
hermes task plan neovim tools-setup
hermes task note neovim "Checked 2026-06-23"

# Dependencies
hermes task depends fleet-pub-sub on fleet-router-config
hermes task depends fleet-e2e on fleet-pub-sub

# Status overview
hermes task status
hermes task status --project router

# Quick aliases
task-done neovim
task-start neovim
task-block neovim --blocked-by openrouter-key
task-status
task-create "Install Neovim" --priority p1
task-note neovim "Checked 2026-06-23"
```\n\n## What Each Command Does

- `done` — sets `task_status: completed`, `updated: today`, logs it, rebuilds dashboards
- `start` — sets `task_status: in_progress`
- `block` — sets `task_status: blocked`, optionally adds `relates_to: [{target, depends_on}]`
- `depends` — adds edge to `relates_to` array
- `note` — appends timestamped line to Notes section
- `priority` / `effort` / `plan` — set single fields

## Entity Lookup

Fuzzy matching: `task-done router-config` matches `router-config-401-fix` if unique. Multiple matches show a list.

## Dashboard Views

| View | File | Content |
|------|------|---------|
| Priority | `tracking/tasks.md` | Phase 1 bar + Focus + ⚡Dopamine Menu + P0-P3 + Someday bucket |
| By Project | `tracking/tasks-by-project.md` | Project with Plan + Ready now sections |
| By Theme | `tracking/themes.md` | Cross-project theme clusters (Wiki, Creative, Infra, etc.) |
| Execution Plan | `tracking/execution-plan.md` | 3-phase critical path |
| Dashboard | `tracking/index.md` | Nav hub with project snapshot + Future Ideas table |

## Session Startup

- `focus` — prints the **Your Next Moves** section from `tasks.md` to the terminal. Run when you sit down to see what's ready.

## Automation

## Automation

- **Phase 1 progress bar** — auto-updates when entities complete
- **Stale task watchdog** — daily 10 AM, flags P1/P2s untouched >7d
- **Auto-priority** — daily 11 AM, no_agent, adjusts P1/P2/P3 based on handoff mentions and staleness
- **Weekly completion report** — Saturdays 10 AM
- **Someday bucket** — P3s untouched >30d auto-collapsed
- **Dashboard rebuild** — every 60 min, regenerates all 3 views
- **Log** — all CLI operations append to `tracking/log.md`

## Session Hooks

- **`focus`** — prints Focus section from dashboard when you sit down. Add to bashrc:
  ```bash
  focus() {
    python3 -c "
  with open('~/AppData/Local/hermes/Vault/wiki/tracking/tasks.md', 'r', encoding='utf-8') as f:
      lines = f.readlines()
  capture = False
  for line in lines:
      if '\U0001f3af Your Next Moves' in line:
          capture = True
      if capture:
          print(line, end='')
      if capture and ('## \U0001f7e1' in line or 'Dopamine' in line):
          break
  "
  }
  ```
- Session tracking via PROMPT_COMMAND (restored from `concepts/session-registry.md`):
  ```bash
  export HERMES_ACTIVE_FILE="$HOME/.hermes/active_session"
  __hermes_track_session() {
    echo "$HERMES_SESSION_ID" > "$HERMES_ACTIVE_FILE" 2>/dev/null || true
  }
  PROMPT_COMMAND="__hermes_track_session${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
  alias herms='python3 "$HOME/AppData/Local/hermes/scripts/herms.py"'
  ```

## Dashboard Views

| View | File | Content |
|------|------|---------|
| Priority + Focus | `tracking/tasks.md` | Phase 1 bar + Focus (top 5 P1s) + Dopamine Menu (<15m tasks) + P0-P3 + Someday bucket |
| By Project | `tracking/tasks-by-project.md` | Project with Plan + Ready now sections |
| By Theme | `tracking/themes.md` | Cross-project theme clusters (Wiki, Creative, Infra, etc.) |
| Execution Plan | `tracking/execution-plan.md` | 3-phase critical path |
| Dashboard | `tracking/index.md` | Nav hub with project snapshot + Future Ideas table |

## Scripts

| Script | Purpose |
|--------|---------|
| `task-manager.py` | CLI for all task operations (the `hermes task` command) |
| `task-create.py` | Task creation (called by task-manager) |
| `build-tasks-dashboard.py` | Regenerates tasks.md + calls by-project + themes + dopamine menu |
| `build-tasks-by-project.py` | Regenerates tasks-by-project.md |
| `build-themes.py` | Regenerates themes.md from tags |
| `auto-priority.py` | No_agent cron, daily priority rebalance from activity signals |
| `stale-task-watchdog.py` | Flags stale P1/P2s |
| `weekly-completion-report.py` | Saturday completion summary |
| `weekly-completion-report.py` | Saturday completion summary |
