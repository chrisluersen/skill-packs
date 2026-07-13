# Full Runtime Mode Capability Matrix

Source: Consolidated from Hermes Agent docs, GitHub repos, and community comparisons (June 2026).

## Complete 10×25 Capability Matrix

| Capability | CLI/TUI | Gateway | Dashboard | Desktop App | Hermes WebUI (nesquena) | Hermes Studio (EKKO) | Open WebUI + API | ACP Server | MCP Server |
|------------|---------|---------|-----------|-------------|------------------------|----------------------|------------------|------------|------------|
| **Launch Command** | `hermes` / `hermes --tui` | `hermes gateway run` | `hermes dashboard` | `hermes desktop` | `python bootstrap.py` / `./start.sh` | Desktop / `npm i -g` / Docker | `hermes` + API platform | `hermes acp` | `hermes mcp serve` |
| **Interface Type** | Terminal (prompt_toolkit TUI) | Headless service | Browser (FastAPI + xterm.js) | Native Electron + React | Browser (vanilla JS + Python stdlib) | Electron + web console | Browser (React) | IDE protocol (ACP) | MCP protocol |
| **OS Support** | Linux/macOS/Win (WSL best) | Linux/macOS/Win (WSL2 systemd) | Linux/macOS/Win (Chat: POSIX/WSL2) | Linux/macOS/Win | Linux/macOS/WSL2 | Linux/macOS/Win | Any browser | Any IDE | Any MCP client |
| **Concurrent Sessions** | 1 per process | **Unlimited** (per thread/DM) | 1 embedded + view others | **Multi-profile simultaneous** | Multi-session tabs | Multi-profile simultaneous | Per browser tab | 1 per IDE conn | N/A (tool provider) |
| **Shared State** | `~/.hermes/state.db` | Same DB + gateway index | Same DB | Same `~/.hermes` | Local SQLite + reads `state.db` | Local SQLite + reads `state.db` | Reads via API | Same DB | Same DB |
| **delegate_task (subagents)** | ✅ Sync, same process | ✅ Sync, same process | Via embedded TUI | ✅ | ✅ (via bridge) | ✅ (via bridge) | ❌ | ✅ | ✅ |
| **Kanban Dispatcher+Workers** | ❌ | ✅ **Native** | Manage only | Manage only | ❌ | ✅ Full | ❌ | ❌ | ❌ |
| **Cron Execution** | Create/list only | ✅ **Scheduler runs here** | Manage + trigger | Manage only | Manage + trigger | Manage + trigger | ❌ | ❌ | ❌ |
| **Curator (skills lifecycle)** | Manual `/curator run` | ✅ **Auto on interval** | Manual trigger | Manual trigger | ❌ | Manual trigger | ❌ | ❌ | ❌ |
| **Webhooks Receive** | ❌ | ✅ **Adapter handles** | Manage only | Manage only | ❌ | Manage only | ❌ | ❌ | ❌ |
| **Voice STT (incoming)** | ❌ | ✅ Auto (platform msgs) | ❌ | ✅ Mic input | ❌ | ✅ Voice I/O | ❌ | ❌ | ❌ |
| **Voice TTS (outgoing)** | `/voice on` | ✅ Platform delivery | Via embedded TUI | ✅ Built-in | ✅ | ✅ | Via provider | Via provider | Via provider |
| **Platform Messaging** | N/A | ✅ 15+ platforms | Configure only | Configure + chat | 8 platforms unified | 8 platforms unified | Via Hermes API | N/A | N/A |
| **DM Approval (`/approve`)** | N/A | ✅ Pairing flow | ❌ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| **Toolset Per-Platform** | `cli` platform | Per platform (telegram, discord...) | View all | Configure all | Configure per platform | Configure per platform | Inherits `api` platform | Inherits `acp` | Inherits `mcp` |
| **File Browser** | `read_file`/`terminal` | N/A | ❌ | ✅ Native pane | ✅ Workspace tree | ✅ Remote backends | ❌ | Via tools | Via tools |
| **Model/Provider UI** | `hermes model` (interactive) | Config only | ✅ Form editor | ✅ Dedicated providers pane | ✅ Auto-discover + OAuth | ✅ Full management | ❌ (own models) | IDE picks | MCP client picks |
| **Skills UI** | `hermes skills` (curses) | Config only | ✅ Browse/install | ✅ Skills pane | ✅ | ✅ | ❌ | ❌ | ❌ |
| **Profiles** | `hermes -p name` | Multi-profile gateway | Switcher in sidebar | **Simultaneous multi-profile** | Switcher | Multi-profile + RBAC | Single | Single | Single |
| **Session Search** | `hermes sessions browse` | Same DB | ✅ Full FTS5 UI | ✅ Search by ID | ✅ Ctrl+K (local DB) | ✅ | Via Hermes API | Via tools | Via tools |
| **Analytics/Cost** | `hermes insights` | Same data | ✅ Charts + tables | Via insights | ✅ Charts + cost | ✅ Charts + cost | Own tracking | ❌ | ❌ |
| **Logs Viewer** | `hermes doctor` / files | `grep gateway.log` | ✅ Filtered + auto-refresh | Via logs pane | ❌ | ✅ | ❌ | ❌ | ❌ |
| **Offline/Air-gapped** | ✅ Fully | ✅ (no gateway features) | ❌ (web server) | ✅ Fully | ✅ Local only | ✅ Local only | ❌ Needs Hermes | ✅ Local | ✅ Local |
| **Mobile Access** | SSH + TUI | ✅ Native (Telegram/Discord) | ⚠️ Port forward + auth | ❌ | ✅ Phone browser | ✅ Phone browser | ✅ Phone browser | ❌ | ❌ |
| **Team/Multi-user** | ❌ | ✅ Per-user DMs | ⚠️ Auth if exposed | ❌ Single user | ❌ Single user | ✅ Multi-profile + super-admin | ✅ Multi-user | ❌ | ❌ |
| **Auto-Update** | `hermes update` | `hermes update` + restart | Manual | ✅ Background + one-click | Manual | Manual | Manual | Manual | Manual |
| **Resource Usage (Idle)** | ~50MB | ~150MB + platforms | +~80MB (FastAPI) | ~200MB (Electron) | ~100MB (Python + JS) | ~250MB (Electron + Python) | External | ~50MB | ~100MB |

## Platform Toolset Inheritance

Each runtime mode maps to a platform identifier that determines available toolsets:

| Runtime | Platform ID | Default Toolsets |
|---------|-------------|------------------|
| CLI/TUI | `cli` | web, terminal, file, code_execution, vision, image_gen, video, tts, skills, memory, session_search, delegation, cronjob, clarify, todo, debugging, safe, spotify, homeassistant, discord, discord_admin, feishu_doc, feishu_drive, yuanbao, rl, moa |
| Gateway (Discord) | `discord` | web, file, browser, skills, memory, session_search, delegation, cronjob, clarify, todo, kanban, discord, discord_admin |
| Gateway (Telegram) | `telegram` | web, file, browser, skills, memory, session_search, delegation, cronjob, clarify, todo, kanban |
| Dashboard | `dashboard` | web, terminal (via PTY), file, skills, memory, session_search, cronjob, todo |
| Desktop App | `desktop` | web, terminal, file, code_execution, vision, image_gen, video, tts, skills, memory, session_search, delegation, cronjob, clarify, todo, debugging, spotify, homeassistant, yuanbao |
| Hermes WebUI | `webui` | web, file, skills, memory, session_search, delegation, cronjob, clarify, todo, browser |
| Hermes Studio | `studio` | web, terminal, file, skills, memory, session_search, delegation, cronjob, kanban, browser, yuanbao |
| Open WebUI + API | `api` | web, file, terminal, skills, memory, session_search, delegation, cronjob, clarify, browser |
| ACP Server | `acp` | web, terminal, file, code_execution, skills, memory, session_search, delegation, cronjob, clarify, todo |
| MCP Server | `mcp` | All tools exposed as MCP tools with `mcp_hermes_` prefix |

## Session Persistence Details

| Runtime | Session Store | Resume Mechanism | Cross-Runtime Resume |
|---------|---------------|------------------|---------------------|
| CLI/TUI | `~/.hermes/state.db` (SQLite + FTS5) | `hermes --resume <id>` / `/resume` | ✅ Full (same DB) |
| Gateway | Same DB + `~/.hermes/gateway_sessions.json` routing index | Auto per thread/DM | ✅ Full |
| Dashboard | Same DB | Click ▶ in Sessions tab → `/chat?resume=<id>` | ✅ Full |
| Desktop App | Same DB | Session list with resume button | ✅ Full |
| Hermes WebUI | Local SQLite (`~/.hermes/webui/sessions.db`) + imports from `state.db` | Session tabs persist | ⚠️ One-way import (CLI → WebUI) |
| Hermes Studio | Local SQLite + reads `state.db` (read-only) | Session tabs persist | ⚠️ One-way import |
| Open WebUI | Own DB + Hermes API | Own session management | Via Hermes API |
| ACP Server | Same DB | IDE-specific | ✅ Full |
| MCP Server | N/A (stateless tool calls) | N/A | N/A |