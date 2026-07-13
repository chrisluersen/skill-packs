# Hermes GitHub Ecosystem & Related Tools Reference

Source: GitHub, Hermes Atlas (https://hermesatlas.com), Vellum comparison, direct repo inspection
Compiled: June 2026

---

## 1. Agent Frameworks (Competitors & Alternatives)

| Framework | GitHub | Stars Est. | Language | Key Feature |
|-----------|--------|-----------|----------|-------------|
| **OpenClaw** | github.com/openclaw/openclaw | ~38K | Python | CLI-first, 20+ channels, any OS |
| **Hermes Agent** | NousResearch/hermes-agent | ~165K | Python | Learning loop, 6-backend, ACP |
| **AutoGPT** | Significant-Gravitas/AutoGPT | ~170K | Python | Pioneer autonomous agent |
| **CrewAI** | crewAIInc/crewAI | ~28K | Python | Role-based multi-agent teams |
| **AutoGen** | microsoft/autogen | ~38K | Python | Multi-agent conversations (MSR) |
| **LangGraph** | langchain-ai/langgraph | ~12K | Python | Graph-based agent orchestration |
| **PydanticAI** | pydantic/pydantic-ai | ~9K | Python | Type-safe agent framework |
| **MetaGPT** | geekan/MetaGPT | ~45K | Python | Software-company sim multi-agent |
| **OpenAI Agents SDK** | openai/openai-agents-python | ~5K | Python | Official OpenAI agent framework |
| **Semantic Kernel** | microsoft/semantic-kernel | ~23K | C#/Python | Microsoft enterprise agent SDK |
| **Dify** | langgenius/dify | ~60K | Python | LLM app builder platform |
| **Superagent** | superagent-ai/superagent | ~5K | Python | Custom agent builder framework |
| **Vellum** | vellum-ai/vellum | ~8K | Rust/Python | Desktop-native personal AI |
| **AGiXT** | Josh-XT/AGiXT | ~2K | Python | Modular agent framework |

### Key Differentiators vs Hermes

- **OpenClaw** — Closest direct competitor. Broader OS support (macOS/Linux/Win via WSL2). 20+ channels vs Hermes's ~8. CLI-first, no native desktop. Frequent breaking changes.
- **AutoGPT** — Pioneer, larger community, but less structured tool/system. More autonomous, less configurable.
- **CrewAI** — Role-based multi-agent focus (HR, engineer, etc.). Not a personal assistant — a team simulation.
- **LangGraph** — Complementary to Hermes (could be backend). Graph-based agent pipelines vs Hermes's monolithic agent.
- **MetaGPT** — Software-company role metaphor. Narrow use case (SDLC simulation). Not a personal AI.
- **Vellum** — Desktop-native, credential isolation by architecture, full identity layer. Newer/smaller community.

---

## 2. Agent CLI Tools (Coding Agents)

| Tool | GitHub | Stars | Language | Description |
|------|--------|-------|----------|-------------|
| **Claude Code** | anthropics/claude-code | ~20K | TypeScript | Anthropic's official coding agent CLI |
| **Codex CLI** | openai/codex | ~15K | TypeScript | OpenAI's coding agent CLI |
| **OpenCode** | sst/opencode | ~8K | Go | Fast, terminal-native coding agent |
| **Toad** | batrachianai/toad | ~2K | Rust | ACP-compatible terminal agent runner |
| **Aider** | Aider-AI/aider | ~25K | Python | Pair programming in terminal |
| **OpenHands** | All-Hands-AI/OpenHands | ~45K | Python | Generalist agent platform (fka OpenDevin) |

**ACP Compatibility** — Claude Code, OpenCode, Toad, and Codex CLI all support ACP (Agent Client Protocol) for spawning sub-agents. Hermes uses this for its delegation system.

---

## 3. Memory Systems

| System | GitHub | Stars | Language | Key Feature |
|--------|--------|-------|----------|-------------|
| **mem0** | mem0ai/mem0 | ~58K | Python | Universal memory layer for AI agents |
| **Hindsight** | vectorize-io/hindsight | ~10K | Rust | SOTA long-term memory with retain/recall |
| **Zep** | getzep/zep | ~4K | Go/TS | Long-term memory with graph relationships |
| **Graphiti** | getzep/graphiti | ~3K | Python | Temporal knowledge graphs for agents |
| **Supermemory** | Dhravya/supermemory | ~7K | TypeScript | Memory layer with web-first design |
| **Honcho** | (used by Hermes) | ~1K | Python | User modeling + memory management |
| **Chroma** | chroma-core/chroma | ~18K | Python | Embedding database, often used for agent memory |
| **Qdrant** | qdrant/qdrant | ~23K | Rust | Vector DB for agent memory backends |

### Hermes Memory Stack
- **Built-in**: FTS5 session search, KV memory store (MEMORY.md/USER.md), config-based
- **External**: Honcho (user modeling), any MCP memory server
- **Advantage**: Hermes has more flexible memory (env probe, session search, env snapshots) than most alternatives
- **Gap**: mem0/Hindsight's structured memory graph, dedup, staleness windows are more sophisticated

---

## 4. Agent-to-Agent Protocols

| Protocol | Creator | Description | Hermes Status |
|----------|---------|-------------|---------------|
| **ACP** (Agent Client Protocol) | Nous Research | Sub-agent spawning protocol (v0.9.0) | ✅ Built-in delegation |
| **MCP** (Model Context Protocol) | Anthropic | Tool/resource discovery protocol (v1.x) | ✅ Built-in MCP client |
| **A2A** (Agent-to-Agent) | Google | Inter-agent communication spec | ❌ Not supported yet |
| **ANP** | Anthropic | Stack-based agent protocol | ❌ Not supported yet |

### ACP Ecosystem
- **Clients**: Claude Code, Codex CLI, OpenCode, Toad, Hermes
- **Usage**: `delegate_task` in Hermes spawns ACP sub-agents
- **Relation to MCP**: MCP = tools/resources for agents, ACP = agent delegation; complementary

---

## 5. GUIs, Desktops, and Workspaces

| Tool | GitHub | Stars | Type | Description |
|------|--------|-------|------|-------------|
| **Hermes WebUI** | Built-in (`hermes webui`) | — | Web UI | Bundled chat UI for Hermes |
| **Hermes Desktop** | Built-in (`hermes desktop`) | — | Electron | Native desktop app |
| **Hermes Hub** | (Hermes component) | — | Service | Centralized session aggregation |
| **Mission Control** | builderz-labs/mission-control | ~800 | Web UI | Self-hosted multi-agent dashboard |
| **Open WebUI** | open-webui/open-webui | ~60K | Web UI | Popular LLM chat interface |
| **AnythingLLM** | Mintplex-Labs/anything-llm | ~30K | Desktop | Document-aware LLM app |

---

## 6. Multi-Agent Orchestration

| Framework | GitHub | Stars | Description |
|-----------|--------|-------|-------------|
| **CrewAI** | crewAIInc/crewAI | ~28K | Role-based agent teams with task delegation |
| **AutoGen** | microsoft/autogen | ~38K | Multi-agent conversation orchestration (MSR) |
| **LangGraph** | langchain-ai/langgraph | ~12K | Graph-defined agent workflows |
| **Temporal** | temporalio/temporal | ~12K | Workflow engine (agent durable execution) |
| **Prefect** | PrefectHQ/prefect | ~18K | Workflow orchestration (Python) |

### Hermes Multi-Agent Status
- `delegate_task` for spawning sub-agents (ACP)
- Cron jobs for scheduled multi-step workflows
- Kanban system for persistent task management
- **Gap**: No built-in multi-agent team orchestration (unlike CrewAI/AutoGen)

---

## 7. Deployment & Infrastructure

| Tool | Description | Relevance to Hermes |
|------|-------------|---------------------|
| **llm-agents.nix** | NixOS module for running Hermes/OpenClaw | Deploy Hermes on NixOS |
| **Hermes Gateway** | Multi-channel messaging bridge | Built-in (Telegram, Discord, Signal, etc.) |
| **Modal** | Serverless cloud for Hermes | Official supported backend |
| **WSL2** | Windows compatibility layer | Required for Hermes on Windows |

---

## 8. Key Observations

1. **Hermes is uniquely positioned** — The only CLI-first agent with a structured learning loop + ACP for delegation + MCP for tools. No other framework has all three.

2. **Memory gap** — mem0 (58K ⭐) and Hindsight (10K ⭐) are more sophisticated than Hermes's built-in memory. But Hermes's FTS5 session search + env probe + KV store is more flexible for agent workflows.

3. **Orchestration gap** — Hermes lacks a built-in multi-agent orchestration layer (like CrewAI/AutoGen). Delegate/kanban/cron cover some ground but aren't a team metaphor.

4. **Protocol leadership** — Hermes created ACP and is the reference implementation. MCP support is built-in. A2A integration would complete the protocol trifecta.

5. **Desktop gap** — Hermes desktop is an Electron wrapper around the web UI. Not a native OS citizen. Vellum leads on desktop-native experience.

6. **Windows gap** — Hermes requires WSL2 on Windows (no native Win32). OpenClaw and Vellum handle Windows better.

7. **Ecosystem scale** — Hermes core: 165K ⭐, ecosystem: 390K ⭐ across 123 projects. Largest in the open-source agent space.

8. **ACP is the differentiator** — No other framework has a standardized sub-agent delegation protocol. Hermes can delegate to Claude Code, Codex, OpenCode, and Toad.
