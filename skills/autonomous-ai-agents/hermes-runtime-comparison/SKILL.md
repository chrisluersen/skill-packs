---
name: hermes-runtime-comparison
description: "Compare Hermes Agent runtime modes (CLI/TUI, Gateway, Dashboard, Desktop App, WebUI, ACP, MCP) and select the right interface for a given use case."
version: 2.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [hermes, runtime, comparison, interface-selection, gateway, dashboard, desktop, webui, acp, mcp]
    homepage: https://github.com/NousResearch/hermes-agent
    related_skills: [hermes-agent, hermes-browser-interfaces, hermes-remote-access]
created_from_user_sessions: true
---

# Hermes Runtime Mode Comparison & Selection Guide

This skill provides a comprehensive comparison of all Hermes Agent runtime modes and a decision framework for selecting the right interface(s) for a given use case.

## Quick Reference: Runtime Modes

| Mode | Launch Command | Type | Best For |
|------|---------------|------|----------|
| **CLI/TUI** | `hermes` / `hermes --tui` | Terminal (prompt_toolkit) | Developers in terminal, SSH, VS Code, full tool access |
| **Gateway** | `hermes gateway run` | Headless service | 24/7 Discord/Telegram bot, cron, kanban, webhooks, STT |
| **Dashboard** | `hermes dashboard` | Browser (FastAPI + xterm.js) | Visual config, session archaeology, multi-profile management |
| **Desktop App** | `hermes desktop` | Native Electron (official) | Daily driver with voice, tabs, preview rail, multi-profile |
| **Hermes WebUI** | `python bootstrap.py` (nesquena) | Browser (vanilla JS) | Self-hosted web chat, phone access, no Electron |
| **Hermes Studio** | Desktop / `npm i -g` (EKKO) | Electron + web console | Teams, WeChat/Feishu, RBAC, remote backends |
| **Open WebUI** | `hermes` + API Server platform | Browser (React) | Multi-user, RAG, pipelines + Hermes agent autonomy |
| **ACP Server** | `hermes acp` | IDE protocol (VS Code/Cursor/Zed) | Coding in IDE with Hermes as agent |
| **MCP Server** | `hermes mcp serve` | MCP protocol | Exposing Hermes tools to other agents (Claude Code, Codex) |

## Capability Matrix (Condensed)

| Capability | CLI/TUI | Gateway | Dashboard | Desktop | WebUI | Studio | Open WebUI | ACP | MCP |
|------------|---------|---------|-----------|---------|-------|--------|------------|-----|-----|
| Concurrent sessions | 1 | **∞** | 1 + view | **Multi-profile** | Multi-tab | Multi-profile | Per user | 1/IDE | N/A |
| delegate_task | ✅ | ✅ | Via TUI | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ |
| Kanban dispatcher | ❌ | ✅ | Manage | Manage | ❌ | ✅ | ❌ | ❌ | ❌ |
| Cron execution | Create | ✅ **Runs** | Trigger | Manage | Trigger | Trigger | ❌ | ❌ | ❌ |
| Curator (auto) | Manual | ✅ Interval | Manual | Manual | ❌ | Manual | ❌ | ❌ | ❌ |
| Webhooks receive | ❌ | ✅ | Manage | Manage | ❌ | Manage | ❌ | ❌ | ❌ |
| Voice STT (incoming) | ❌ | ✅ | ❌ | ✅ Mic | ❌ | ✅ | ❌ | ❌ | ❌ |
| Platform messaging | N/A | ✅ 15+ | Config | Config | 8 unified | 8 unified | Via API | N/A | N/A |
| Mobile access | SSH+TUI | ✅ Native | Port fwd | ❌ | ✅ Browser | ✅ Browser | ✅ Browser | ❌ | ❌ |
| Team/multi-user | ❌ | ✅ DMs | Auth if exposed | ❌ | ❌ | ✅ RBAC | ✅ Multi-user | ❌ | ❌ |

## Decision Framework

### Solo Developer (Terminal/SSH/VS Code)
**Primary:** TUI (`hermes --tui`)  
**Add:** Gateway (for mobile Discord/Telegram + cron/kanban)  
**Optional:** Dashboard (visual config on demand)

### Daily Driver Desktop App (Windows/macOS/Linux)
**Primary:** Desktop App (`hermes desktop`)  
**Add:** Gateway (background automation)  
**Alternative:** Hermes Studio (if team/WeChat/Feishu/RBAC needed)

### Self-Hosted Server + Phone Access
**Primary:** Hermes WebUI (nesquena) + Gateway  
**Alternative:** Open WebUI + Hermes API Server (if multi-user/RAG needed)

### IDE Integration
**Primary:** ACP Server (`hermes acp`) + VS Code/Cursor/Zed extension

### Tool Provider for Other Agents
**Primary:** MCP Server (`hermes mcp serve`)

### Production Automation (Cron/Kanban/Webhooks/Bot)
**Mandatory:** Gateway (`hermes gateway install && hermes gateway start`)

## Recommended Stack for Most Power Users

```
┌─────────────────────────────────────────────────────────────┐
│  ALWAYS RUNNING (systemd/service/WSL2):                     │
│  🔧 hermes gateway  →  Cron, Kanban, Webhooks,              │
│                      Discord/Telegram bot, STT, Curator     │
└─────────────────────────────────────────────────────────────┘
                           ▲ Shared ~/.hermes/state.db
        ┌──────────────────┼──────────────────┐
        ▼                  ▼                  ▼
┌───────────────┐  ┌───────────────┐  ┌───────────────┐
│  DESKTOP      │  │  TERMINAL     │  │  BROWSER      │
│  hermes       │  │  hermes --tui │  │  hermes       │
│  desktop      │  │  (SSH, coding)│  │  dashboard    │
└───────────────┘  └───────────────┘  └───────────────┘
                           │
         ┌─────────────────┴─────────────────┐
         │  OPTIONAL: WebUI, Open WebUI,     │
         │  ACP, MCP Server                  │
         └───────────────────────────────────┘
```

## Windows-Specific Notes

- **TUI in VS Code terminal**: Works natively (bash/git-bash), best coding experience
- **Gateway as Windows service**: `hermes gateway install` → runs on boot, survives logout
- **Desktop App**: Native Windows Electron build, supports voice mic input
- **Dashboard Chat tab**: Requires WSL2 (POSIX PTY); native Windows Python lacks PTY support
- **Hermes WebUI**: Run on WSL2 for best experience; native Windows guide available
- **Open WebUI**: Run in Docker/WSL2, connect to Hermes API Server on gateway

## Beyond Runtime Surfaces: Orchestration & Ecosystem Layers

The above covers *surfaces* you talk to Hermes through. Hermes also participates in broader multi-agent stacks — from internal sub-agent orchestration all the way up to external swarm controllers. These are **not** alternative runtimes; they are layers that coordinate, aggregate, or sit above Hermes instances.

### Layer 5: Built-in Sub-Agent Orchestration (`delegate_task`)

Hermes spawns sub-agents directly from any surface (CLI, TUI, Gateway, WebUI):

| Pattern | Call | Use Case |
|---------|------|----------|
| **Single child** | `delegate_task(goal, context)` | One focused worker, returns summary |
| **Parallel batch** | `delegate_task(tasks=[...])` | Up to N concurrent independent workstreams |
| **Background** (async) | `delegate_task(goal, background=True)` | Fire-and-forget; result re-enters conversation |

Each sub-agent gets an isolated terminal session, conversation, and toolset. No context bleed. Available from **every** runtime surface — CLI/TUI, Gateway, Dashboard, WebUI, Desktop — identically.

### Layer 6: Kanban Multi-Profile Orchestration

Work queue + dispatcher that routes tasks across multiple Hermes profiles (each with its own model, skills, memory):

```
Planner Profile ──▶ Researcher Profile ──▶ Reviewer Profile
                          │
                          ▼
                    Engineer Profile
```

- `kanban_create(title, assignee, parents, priority)` — create dependency-gated tasks
- **Dispatcher** (`hermes gateway`) — watches `ready` cards, spawns the right profile
- **Goal-mode** — persistent worker loops until a judge accepts the result
- **Block/Unblock** — human-in-the-loop mid-task

**Only the Gateway** runs the dispatcher. Other surfaces (TUI, Dashboard) can create/manage cards but the Gateway must be running for cards to be picked up.

### Layer 7: Hub Service — Multi-Instance Session Aggregation

The Hub Service (`hub_service.py`, port `:8788`) aggregates sessions from **multiple Hermes instances** into one REST + WebSocket API:

```
Hub Service (:8788) ──┬── Laptop (default profile)
                      ├── GPU Server (server profile)
                      └── Cloud VM (worker profile)
```

Endpoints: `GET /sessions`, `GET /sessions/{id}`, `GET /search?q=...`, `WS /realtime`. The WebUI can display all instances as grouped sidebar sections. Useful for fleet management, centralized dashboards, cross-machine visibility.

### Layer 8: External Orchestrator — SwarmClaw

[SwarmClaw](https://github.com/swarmclawai/swarmclaw) is a self-hosted multi-agent runtime that lists **Hermes Agent as a managed provider** alongside Claude Code, Codex, OpenClaw, Gemini CLI, and 20+ others:

> *"Control plane for your OpenClaw and Hermes Agent swarms"* — swarmclaw.ai

- Spawns Hermes instances as swarm workers alongside heterogeneous agents
- Agent Builder with personality/MPC/skills
- Kanban-style task board, cron scheduling, delegation chains
- Connectors to Discord, Slack, Telegram, WhatsApp, SwarmDock marketplace
- Hermes is one node in a larger swarm — SwarmClaw is the meta-orchestrator

### Layer 9: External Substrate — OpenCoven / Coven

[OpenCoven](https://github.com/OpenCoven) takes a different architectural approach — a **persistent agent substrate** (not a harness) in Rust:

| Repo | Role |
|------|------|
| **coven** | Rust daemon — local socket API, SQLite session/event ledger |
| **coven-cave** | Native workspace UI — talk to familiars, inspect memory/tools |
| **cast-codes** | Spell grammar — intent commands to summon/command agents |

Coven is a **substrate** — the daemon owns memory, sessions, and tool policies, bridging to harnesses (Codex CLI, Claude Code, eventually Hermes). Familiars are persistent agents with identity that outlive any single conversation. Early-stage but architecturally distinct: Hermes could plug into it as a harness adapter.

### Full Spectrum Summary

| Level | Name | Relation to Hermes | Gateway Required? |
|-------|------|-------------------|-------------------|
| **1** | CLI flags (`hermes chat -q`) | Direct invocation | No |
| **2** | TUI (`hermes`, `herm`) | Interactive terminal session | No |
| **3** | Gateway (Telegram/Discord/Slack) | Same agent, remote surfaces | Yes (is the gateway) |
| **4** | WebUI / Dashboard / Desktop | Browser/native visual surfaces | No |
| **5** | `delegate_task` sub-agents | Internal orchestration | No |
| **6** | Kanban multi-profile orchestration | Native fleet orchestration | **Yes** (dispatcher runs here) |
| **7** | Hub Service | Multi-instance aggregation | No |
| **8** | SwarmClaw | Meta-orchestrator managing Hermes as a provider | No |
| **9** | OpenCoven/Coven | Substrate Hermes could plug into | No |

### When to Reach for Each Layer

- **One-shot task** → CLI (`hermes chat -q`)
- **Interactive session** → TUI or Desktop or WebUI
- **Always-on, mobile, team** → Gateway + Telegram/Discord
- **Need parallel sub-tasks** → `delegate_task` (any surface)
- **Complex multi-step project, multi-specialist** → Kanban (Gateway must run)
- **Multiple Hermes machines** → Hub Service
- **Heterogeneous swarm (Hermes + Codex + Claude + ...)** → SwarmClaw
- **Persistent agent identity across harnesses** → OpenCoven/Coven

## Key Commands

```bash
# Core runtimes
hermes                    # CLI chat
hermes --tui              # Explicit TUI
hermes gateway run        # Gateway foreground
hermes gateway install    # Gateway as service
hermes dashboard          # Web dashboard (localhost:9119)
hermes desktop            # Desktop app
hermes acp                # ACP server for IDE
hermes mcp serve          # MCP server for other agents

# Community UIs (separate installs)
git clone https://github.com/nesquena/hermes-webui && cd hermes-webui && python3 bootstrap.py
npm install -g hermes-web-ui  # EKKO Studio

# Herm TUI — OpenTUI dashboard for Hermes Agent
# Requires Bun runtime. See references/windows-setup.md for Windows install.
bunx herm-tui             # Run without installing
bun add -g herm-tui       # Install globally
herm                      # Start fresh session
herm -c                   # Resume last session
herm --help               # Full usage
```

## References

- `references/runtime-mode-matrix.md` — Full capability matrix with all 10 modes × 25 capabilities
- `references/decision-framework.md` — Detailed decision trees per use case
- `references/windows-setup.md` — Windows-specific installation and quirks