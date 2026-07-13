---
title: Hermes Gateway Setup
name: hermes-gateway-setup
description: Configure, operate, and troubleshoot the Hermes messaging gateway — set up Telegram, Discord, and other platforms. Covers config vars, gateway lifecycle, and the interactive wizard's PTY limitations.
type: workflow
tags: [gateway, telegram, messaging, setup, configuration, windows]
---

# Hermes Gateway Setup

## Overview

The Hermes Gateway is a single background process that connects to messaging platforms (Telegram, Discord, WhatsApp, Signal, etc.), runs cron jobs, and manages per-chat sessions. On Windows it runs as a Scheduled Task.

## Gateway Lifecycle Commands

```bash
hermes gateway status        # Check if installed + running
hermes gateway run           # Run in foreground (foreground process)
hermes gateway start         # Start the installed background service
hermes gateway stop          # Stop the background service
hermes gateway restart       # Restart the service
hermes gateway install       # Install as Windows Scheduled Task / systemd service
hermes gateway uninstall     # Remove the service
hermes gateway setup         # Interactive config wizard
hermes gateway list          # List all profiles and their gateway status
```

## Gateway Status Interpretation

```
✓ Scheduled Task registered: Hermes_Gateway    ← installed
  Status: Ready                                 ← task is configured
  Last Run Time: ...                            ← last attempted start
  Last Run Result: -1073741510                  ← STATUS_CONTROL_C_EXIT (killed)
✗ No gateway process detected                   ← not currently running
```

Common exit codes:
| Code | Meaning |
|------|---------|
| 0 | Clean exit |
| -1073741510 (0xC000013A) | `STATUS_CONTROL_C_EXIT` — process was killed/stopped **or crashed** | If intentional: not an error. If unexpected: gateway is dead and `hermes gateway run --replace` is needed to respawn cleanly. |
| -1073741502 (0xC0000132) | `STATUS_DLL_INIT_FAILED` — startup failure |
| 1+ | Generic error — check gateway logs |

## Configuration — Environment Variables

Use `hermes config check` to list all platform env vars. Key ones for messaging:

### Telegram
| Env Var | Required | Purpose |
|---------|----------|---------|
| `TELEGRAM_BOT_TOKEN` | ✅ Yes | Bot token from @BotFather on Telegram |
| `TELEGRAM_ALLOWED_USERS` | 🔲 Optional | Comma-separated Telegram user IDs or usernames |
| `TELEGRAM_PROXY` | 🔲 Optional | SOCKS5 proxy URL for Telegram connection |

Set via:
```bash
hermes config set TELEGRAM_BOT_TOKEN "123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"
```

### Discord
| Env Var | Required | Purpose |
|---------|----------|---------|
| `DISCORD_BOT_TOKEN` | ✅ Yes | Bot token from Discord Developer Portal |
| `DISCORD_ALLOWED_USERS` | 🔲 Optional | Comma-separated Discord user IDs |
| `DISCORD_HOME_CHANNEL` | 🔲 Optional | Default channel ID |

### config.yaml Platform Settings

Each platform has a `config.yaml` section under the top-level key:
```yaml
telegram:
  reactions: false
  channel_prompts: {}
  allowed_chats: ''
  extra:
    rich_messages: false

discord:
  require_mention: true
  free_response_channels: ''
  reactions: true
  # ... full config in config.yaml at line ~406
```

The env vars (set via `hermes config set`) are read at runtime into `.env` and override the config.yaml defaults.

## Interactive Wizard Limitations

The `hermes gateway setup` wizard uses Python's `input()` + readline for interactive prompts. When invoked via `terminal(pty=true, background=true)`, the wizard:

1. Shows its first prompt ("Start it now? [Y/n]:") correctly
2. Accepts input via `process(action='submit', data='Y')`
3. Does NOT progress to the next prompt (the PTY output buffer doesn't flush between reads)

**Recommended approach:** Skip the wizard. Configure platforms directly:
1. Create a bot on the messaging platform (e.g. @BotFather on Telegram)
2. Set tokens via `hermes config set <VAR> <value>`
3. Configure `allowed_chats` / `allowed_users` in config.yaml if needed
4. Start the gateway: `hermes gateway start` or `hermes gateway run`

## Getting a Telegram Bot Token

1. Open Telegram, search for **@BotFather**
2. Send `/newbot` and follow prompts (choose a name and username)
3. @BotFather replies with your token: `123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11`
4. Set it: `hermes config set TELEGRAM_BOT_TOKEN "123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"`

Optionally restrict who can message the bot:
```bash
hermes config set TELEGRAM_ALLOWED_USERS "your_telegram_user_id"
```

## Starting the Gateway

```bash
# Option A: Foreground (good for testing)
hermes gateway run

# Option B: Background service (Windows Scheduled Task)
hermes gateway start

# Option C: Install then start (first-time setup)
hermes gateway install
hermes gateway start
```

## Verification

After starting the gateway, verify:
1. `hermes gateway status` shows "✓ Gateway process detected"
2. **Definitive check**: `curl http://localhost:8642/health` returns `{"status":"ok"}` — status alone can lie when the HTTP server is dead but the process metadata is stale
3. Send a message to your bot on Telegram — you should get a reply
4. `hermes gateway list` shows the gateway as running

## Troubleshooting

| Problem | Likely Cause | Fix |
|---------|-------------|-----|
| Gateway installed but no process | Service exited or crashed | Check exit code via status, then --replace (below) |
| Bot not responding | Token wrong or gateway not running | Verify token, check status, curl health endpoint |
| "Connection refused" | Network/proxy issue | Check TELEGRAM_PROXY, try without |
| Gateway starts then immediately exits | Config error or missing dependency | Run `hermes gateway run` in foreground to see stderr |
| Exit code -1073741510 | Normal shutdown (Ctrl+C or stop) **or crash** | If intentional: not an error. If unexpected: see --replace below |
| `hermes gateway status` says "Ready" but bot doesn't respond | HTTP server is dead (orphaned process metadata) | Always use `curl :8642/health` as the definitive check, not just status |

### Gateway crash recovery (--replace)

When the gateway exits unexpectedly and `hermes gateway restart` won't bring it up:

```bash
# Force-terminate any stale process and respawn cleanly
hermes gateway run --replace

# Verify
curl http://localhost:8642/health
```

`--replace` is more reliable than `restart` because it SIGTERMs the old process first before spawning, avoiding orphan collisions. Use it anytime the gateway shows exit code -1073741510 mid-session.

### Plugin changes require gateway restart

Hermes plugins are loaded at **session start**, not on file write. An on-disk plugin fix is NOT a live fix until a new session loads it. For gateway sessions (Telegram, Discord), the gateway holds the persistent session — `hermes gateway run --replace` kills the running session and spawns a new one, forcing all plugins to re-load.

See `references/plugin-lifecycle-session-reload.md` for the full verification workflow, detection table, and the "fixed the file, why is it still broken" trap.

## Reference Files

- `references/plugin-lifecycle-session-reload.md` — plugin load timing, verification workflow, Gateway restart dependency
