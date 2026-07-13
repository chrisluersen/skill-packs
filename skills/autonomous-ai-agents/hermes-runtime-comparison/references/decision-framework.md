# Decision Framework: Selecting Your Hermes Runtime Stack

Source: Synthesized from user workflows, community discussions, and official docs (June 2026).

## Primary Decision Tree

```
START: What is your PRIMARY daily interaction pattern?
│
├─► "I live in terminal / SSH / VS Code integrated terminal"
│   │
│   ├─► Need mobile Discord/Telegram + cron/kanban/webhooks?
│   │   │   YES → PRIMARY: TUI (`hermes --tui`) + Gateway (service)
│   │   │   NO  → PRIMARY: TUI only
│   │   │
│   │   └─► Want visual config/sessions sometimes?
│   │       YES → ADD: Dashboard (`hermes dashboard`) on demand
│   │       NO  → Stop
│   │
├─► "I want a polished native desktop app with voice, tabs, preview"
│   │
│   ├─► Team environment / WeChat/Feishu / RBAC / remote backends?
│   │   │   YES → PRIMARY: Hermes Studio (EKKO) Desktop + Gateway
│   │   │   NO  → PRIMARY: Official Desktop App (`hermes desktop`) + Gateway
│   │   │
│   │   └─► Still want terminal access for coding?
│   │       YES → ALSO: TUI in VS Code terminal
│   │       NO  → Stop
│   │
├─► "I self-host on a server, need browser access from phone/laptop"
│   │
│   ├─► Single user or small trusted team, no Electron, streaming SSE?
│   │   │   YES → PRIMARY: Hermes WebUI (nesquena) + Gateway
│   │   │   NO  → Continue
│   │   │
│   ├─► Multi-user, need RAG, pipelines, Open WebUI ecosystem?
│   │   │   YES → PRIMARY: Open WebUI + Hermes API Server (gateway)
│   │   │   NO  → Continue
│   │   │
│   └─► Team + WeChat/Feishu + RBAC + remote backends?
│       │   YES → PRIMARY: Hermes Studio (EKKO) + Gateway
│       │   NO  → Re-evaluate
│   │
├─► "I code in VS Code / Cursor / Zed and want Hermes inline"
│   │
│   └─► PRIMARY: ACP Server (`hermes acp`) + IDE extension
│       │
│       └─► Also need background automation?
│           YES → ALSO: Gateway
│           NO  → Stop
│   │
├─► "I want to give Hermes tools (terminal, skills, cron) to Claude Code / Codex"
│   │
│   └─► PRIMARY: MCP Server (`hermes mcp serve`)
│       │
│       └─► Also want to chat with Hermes directly?
│           YES → ALSO: TUI or Desktop App
│           NO  → Stop
│   │
└─► "I need production automation: cron, kanban, webhooks, Discord/Telegram bot 24/7"
    │
    └─► MANDATORY: Gateway (`hermes gateway install && hermes gateway start`)
        │
        └─► Add daily driver: TUI / Desktop / WebUI / ACP as above
```

## Secondary Decision Factors

### If You're on Windows 10/11

| Constraint | Recommendation |
|------------|----------------|
| VS Code integrated terminal (bash/git-bash) | TUI works natively — best coding experience |
| Want native Windows service for gateway | `hermes gateway install` → runs on boot, survives logout |
| Desktop App with voice mic input | Official `hermes desktop` — native Windows Electron |
| Dashboard Chat tab | Requires WSL2 (POSIX PTY); native Windows Python lacks PTY |
| Hermes WebUI | Run on WSL2 for best experience; see @markwang2658/hermes-windows-native-guide |
| Open WebUI | Run in Docker/WSL2, connect to Hermes API Server on gateway port |

### If You Need Multi-Profile Work

| Requirement | Best Choice |
|-------------|-------------|
| Run sessions in different profiles **simultaneously** | Desktop App (native multi-profile tabs) |
| Gateway serving multiple profiles | `hermes gateway` with profile-specific platform configs |
| Isolated configs/skills/sessions per project | `hermes profile create <name>` + `hermes -p <name>` |
| Team with role-based access | Hermes Studio (super-admin / regular admin RBAC) |

### If You Need Team Collaboration

| Team Size / Need | Best Stack |
|------------------|------------|
| 2-5 devs, shared bot, no RAG | Gateway (Discord/Telegram) + each runs TUI/Desktop |
| 5-20, need RAG + pipelines + multi-user UI | Open WebUI + Hermes API Server |
| Enterprise, WeChat/Feishu, RBAC, remote backends | Hermes Studio (EKKO) |
| Pair programming in IDE | ACP Server + VS Code Live Share / Cursor / Zed |

### If You Have Specific Platform Requirements

| Platform | Gateway Support | Desktop App | WebUI (nesquena) | Studio (EKKO) | Open WebUI |
|----------|-----------------|-------------|------------------|---------------|------------|
| Discord | ✅ Full | Configure | ✅ | ✅ | Via API |
| Telegram | ✅ Full | Configure | ✅ | ✅ | Via API |
| Slack | ✅ Full | Configure | ❌ | ✅ | Via API |
| WhatsApp | ✅ Full | Configure | ❌ | ✅ | Via API |
| Matrix | ✅ Full | Configure | ❌ | ✅ | Via API |
| Signal | ✅ Full | Configure | ❌ | ❌ | Via API |
| Email/SMS | ✅ Full | Configure | ❌ | ❌ | Via API |
| Feishu (Lark) | ✅ Full | Configure | ✅ | ✅ | Via API |
| WeCom | ✅ Full | Configure | ❌ | ✅ | Via API |
| WeChat (QR) | ✅ Full | Configure | ❌ | ✅ | Via API |
| BlueBubbles (iMessage) | ✅ Full | Configure | ❌ | ❌ | Via API |

## Minimal Viable Stacks

### Solo Developer (Minimal)
```bash
# Daily driver
hermes --tui

# Background automation (optional but recommended)
hermes gateway install && hermes gateway start
```

### Solo Developer (Full)
```bash
# Daily driver with voice, tabs, preview
hermes desktop

# Background automation (mandatory for cron/kanban/bot)
hermes gateway install && hermes gateway start

# Visual config on demand
hermes dashboard
```

### Self-Hosted Server (Single User)
```bash
# On server (WSL2/Linux)
git clone https://github.com/nesquena/hermes-webui && cd hermes-webui
python3 bootstrap.py  # or ./ctl.sh start for daemon

# Background automation
hermes gateway install && hermes gateway start
```

### Team with RAG + Pipelines
```bash
# Server: Open WebUI (Docker) + Hermes Gateway with API platform enabled
docker run -d -p 3000:8080 ghcr.io/open-webui/open-webui:main

# Hermes: enable API platform in config.yaml
platforms:
  api:
    enabled: true
    extra:
      host: "0.0.0.0"
      port: 8644

hermes gateway install && hermes gateway start
```

### IDE-Native Coding
```bash
# Terminal 1: ACP server
hermes acp

# VS Code: Install ACP extension (or Copilot ACP), point to localhost:port
# Or: Use `hermes --tui` in VS Code terminal for full tool access
```

## Migration Paths

| From | To | Migration Steps |
|------|-----|-----------------|
| TUI only | + Gateway | `hermes gateway install && hermes gateway start` — zero config, shares `state.db` |
| TUI + Gateway | + Desktop | `hermes desktop` — picks up same profile, sessions resume |
| WebUI (nesquena) | Open WebUI | Install Open WebUI, point to `http://hermes-gateway:8644/v1` |
| Desktop | Studio (EKKO) | `npm install -g hermes-web-ui` — imports profiles, separate local DB |
| CLI only | ACP | `hermes acp` — add IDE extension, same `state.db` |

## Anti-Patterns to Avoid

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Running Gateway *without* systemd/service | Dies on logout, cron/kanban/webhooks stop | `hermes gateway install` (systemd/Windows service/WSL2) |
| Using Dashboard Chat tab on native Windows | PTY not supported, fails silently | Use WSL2 or TUI/Desktop instead |
| Running Hermes WebUI without Gateway | No cron/kanban/webhook execution | Always pair with Gateway |
| Multiple Gateway processes on same `~/.hermes` | Session DB corruption, port conflicts | One Gateway per profile; use `hermes -p` for isolation |
| Expecting Open WebUI to run Hermes tools | Open WebUI has no terminal/delegation/skills | Must run Hermes Gateway with API platform enabled |
| Using ACP for background tasks | ACP dies with IDE session | Use Gateway for durable work; ACP for interactive coding |

## Quick Health Checks

```bash
# Is Gateway running?
hermes gateway status
# or
systemctl --user status hermes-gateway
# or (Windows)
sc query hermes-gateway

# Are cron jobs firing?
hermes cron list
hermes cron run <job_id>  # test manually

# Is kanban dispatcher active?
hermes kanban stats

# Can Dashboard reach Gateway?
curl http://localhost:8644/health  # Gateway health
curl http://localhost:9119/api/status  # Dashboard API

# Shared session DB intact?
hermes sessions stats
sqlite3 ~/.hermes/state.db ".tables"
```