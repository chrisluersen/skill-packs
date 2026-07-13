# Multi-Agent Orchestration — Condensed Findings

**Source session:** 2026-06-23, fleet E2E testing + architecture v2 redesign
**Sources:** 25+ sources across 3 research passes (academic papers, protocol docs, industry blogs, Hermes source code)

## Core Scaling Truths

| Finding | Source | Signal |
|---------|--------|--------|
| Multi-agent degrades performance 39-70% on **sequential reasoning** tasks | arXiv:2512.08296 | Sequential pipeline is wrong default |
| Multi-agent boosts research by +90.2% with **orchestrator-worker + parallel** | Anthropic Engineering | Right pattern for right task |
| 40% of multi-agent pilots fail in production (cost, latency, errors) | Beam AI | Production readiness requires gates |
| Independent agents amplify errors **17.2×**, centralized contains to **4.4×** | arXiv scaling | Gates must be centralized, not decentralized |
| Token usage explains 80% of performance variance | Anthropic Engineering | Budget estimation is not optional |
| Capability ceiling: single-agent >45% → coordination becomes net negative | arXiv scaling | Don't over-engineer simple tasks |
| Tool-heavy tasks suffer disproportionately from multi-agent overhead | arXiv scaling | Code tasks should minimize hop count |
| Harness depth > model quality for coding agents in 2026 | Firecrawl 2026 comparison | OpenCode and Claude Code have "deep" harnesses |

## The Protocol Stack (Second Pass Discovery)

```
Commerce      — ACP / UCP (payments, fulfillment, transactions)
Agent Layer   — A2A / ACP (discovery, tasks, delegation, lifecycle)
                ACP merged into A2A under Linux Foundation (2025)
Tool Layer    — MCP (APIs, databases, files, shell) — 97M downloads
Model Layer   — Claude, GPT, Gemini, Hermes, OpenCode, etc.
```

**Hermes status:**
- MCP: ✅ Built-in (`tools/mcp_tool.py`)
- A2A/ACP client: 🔄 Proposed (#5257 feat/acpx-plugin branch exists, generalized ACP client for 14 agent types)
- A2A remote: 🔄 Proposed (#514, Agent Cards, JSON-RPC, task lifecycle)
- A2A server: ✅ Already runs as ACP server for IDE integration (`hermes acp`)

## 8 Design Patterns — When Each Fires

| Pattern | Best For | Fire Only When |
|---------|---------|----------------|
| Sequential Pipeline | Deterministic multi-stage (contract gen, batch) | Task requires rigid step order |
| Orchestrator-Worker | Research, cross-functional workflows | Task decomposition adds value |
| Router | Distinct verticals at input | Simple classification suffices |
| Fan-Out / Fan-In | Parallel independent analysis | Workers don't share state |
| Generator+Critic | Quality-gated content | Output quality matters > latency |
| Multi-Agent Debate | Compliance, hallucination reduction | ⚠️ Limit to 3 agents, sycophancy risk |
| Dynamic Handoff | Emergent needs mid-conversation | ⚠️ Infinite loop risk without criteria |
| Hierarchical Decomposition | Multi-level planning | Goal decomposes into sub-goals |

## Agent Role Taxonomy (Canonical)

| Role | Example in Fleet | Research Consensus |
|------|-----------------|-------------------|
| Worker (narrow domain) | Artemis (search), Klio (wiki), Kalliope (content) | Required — core execution |
| Orchestrator | Stella (dynamic pattern choice) | Required — always needed |
| Task Decomposer | Astraea-5 (plan-only) | Required for complex tasks |
| Gate / Guardrail | Vesta-4 (security) | Required for production |
| Validator / Critic | Nemesis-128 (QA), Ceres-1 (review) | Required for quality |
| Memory Agent | *(missing — deferred to post-v2)* | Industry standard but deferrable |
| Observability | *(missing — deferred to post-v2)* | Industry standard but deferrable |
| Human-in-Loop Gate | *(handled by `clarify` tool)* | Deferrable for current scale |

## Fleet Architecture Best Practices

### Profile Design (from E2E test proof)
- **Artemis 100/100** = task-first profile ✓ → Keep
- **Klio 8/100** = mythological preamble → "I consulted the cosmic stacks" → REBUILD
- **Template:** `[ROLE]: one sentence. [BEHAVIOR]: 2-3 bullets. [OUTPUT]: format. [RULES]: no preamble. [PERSONALITY]: optional one line.`

### Agent Count Guidance
- Total fleet: 10 (9 Hermes + 1 OpenCode) — down from 14
- Per simple task: 0-1 agents
- Per complex task: 2-5 agents
- Workers only: 5 (OpenCode, Artemis, Klio, Kalliope, Metis)
- Coordination: 5 (Stella, Astraea, Vesta, Nemesis, Ceres)

### a2a-opencode Integration
```bash
npm install -g a2a-opencode
opencode serve                                     # :4096
a2a-opencode --config my-agent/config.json          # :3001
# Route: Stella → HTTP POST /a2a/jsonrpc → OpenCode
```

### Missing Roles (Acknowledged — All Post-v2)
1. Memory agent (cross-session state)
2. Observability / monitoring (cost, latency, error tracking)
3. Human-in-loop gate (irreversible action approvals)
4. Agent Card capability routing (replace keyword matching)
5. Context engineering (compaction, system reminders, memory pipeline)

## Source URLs (Key)

- arXiv:2512.08296 — Science of Scaling Agent Systems
- arXiv:2603.05344 — OpenDev: Building Terminal Coding Agents
- arXiv:2602.15055 — ACP: Unified Agent Communication Protocol
- Microsoft Agent Framework — BUILD 2026 announcements
- Microsoft Azure — AI Agent Design Patterns
- Google ADK — Multi-Agent Patterns
- Anthropic Engineering — Multi-Agent Research System
- IBM — What is ACP
- agentcommunicationprotocol.dev — ACP official docs
- digitalapplied.com — Protocol ecosystem map 2026
- firecrawl.dev — Best AI Coding Agents 2026
- dev.to/shashikanthgs — a2a-opencode setup guide
- github.com/NousResearch/hermes-agent/ issues/5257 + issues/514
