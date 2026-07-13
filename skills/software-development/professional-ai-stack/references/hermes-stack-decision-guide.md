# Hermes Agent Stack Decision Guide

Condensed from the AI Architecture research (v1.2, June 2026).
Source artifact: `~/AppData/Local/hermes\AI Architecture.html`

## Two Stacks

| Dimension | 🟢 Simple Stack | 🔴 End Game Stack |
|-----------|----------------|-------------------|
| **For who** | Beginners, quick experiments, daily helpers | Power users, teams, production deployments |
| **Models** | Single model (Ollama local or OpenRouter API) | Multi-model gateway with dynamic switching |
| **Platforms** | CLI + TUI only | Discord · Telegram · Slack · Signal · Email · Web UI |
| **Tools** | Built-in defaults (search, file, terminal) | MCP servers, plugins, sub-agents, background tasks |
| **Automation** | Manual cron jobs | Auto-curated skills, scheduled workflows, ACP delegation |
| **Cost** | $0–$5/month | $10–$100+/month |
| **Setup time** | 10 minutes | 1–2 hours + ongoing tuning |

**Core philosophy (both stacks):** Local-first, model-agnostic, tool-augmented, always-on capable, extensible.

## 7-Step Incremental Upgrade Path

| Step | What You Add | Time |
|------|-------------|------|
| 1. Simple Stack | CLI + TUI, single model (Ollama or OpenRouter), built-in tools | 10 min |
| 2. + Profiles | Create fast and deep profile for dynamic model switching | +5 min |
| 3. + Gateway | Run `hermes gateway` for cron jobs and always-on availability | +10 min |
| 4. + One Platform | Connect Discord or Telegram for on-the-go access | +15 min |
| 5. + MCP Servers | Add specialized tools (MeiGen AI, Toucan, Mistral-MCP) | +10 min |
| 6. + Multi-Agent | Set up ACP for Claude Code / Codex delegation + Toad orchestration | +20 min |
| 7. Full End Game | All platforms, auto-curated skills, remote access, hub aggregator | +30 min |

## user's Current Stack Audit (June 2026)

| Step | Research Says | Reality | Status |
|------|--------------|---------|--------|
| 1. Simple Stack | CLI + TUI, single model | GLM-5.2 via zai, 128K context | ✅ Exceeded |
| 2. Profiles | fast/deep presets | 13 fleet profiles + custom router | ✅ Way exceeded |
| 3. Gateway | Always-on daemon | hermes-router running as process | ✅ Done (custom) |
| 4. Platform | Discord or Telegram | **None connected** | ❌ Missing |
| 5. MCP Servers | Specialized tools | **None configured** | ❌ Missing |
| 6. Multi-Agent | ACP + Toad | fleet-manager.py + 13 agents + pub/sub | ✅ Done (custom) |
| 7. Full End Game | All platforms, curator, hub | Curator running, 105 skills | ⚠️ Partial |

### What user built that replaces the research's recommendations
- **hermes-router** replaces profile-based model switching (free→Nous→Ollama fallback)
- **fleet-manager.py** replaces ACP/Toad delegation (13 asteroid agents + pub/sub bus)
- **LLM wiki** at ~/Vault/wiki/ replaces the Obsidian vault integration
- **Fleet crons** (Klio 7×wiki, Mnemosyne 1×memory, Atalanta 3×infra) replace generic cron

### Gaps that matter (priority order)
1. **Mobile/Platform Access** — Tailscale gives remote terminal, but no mobile interface. Telegram would enable phone access + cron notifications. ~15 min setup. **Highest ROI.**
2. **Curator Consolidation** — Curator running but in prune-only mode (LLM merge off). 105 skills would benefit from auto-consolidation. One config change.
3. **MCP Servers** — Already have web (Firecrawl), browser (Browser-use), image gen (FAL) via Nous. Skip unless a specific need surfaces.
4. **Hub Service** — Probably overkill; fleet-manager.py already coordinates 13 profiles.

## Key Architectural Concepts

### The Agent Loop
Prompt Assembly → Tool Injection → Provider Resolution → LLM Call → Tool Execution → Loop (until final answer or max iterations) → Context Compression (when budget exceeded)

### Three Memory Tiers
| Tier | Location | Contents | How It's Used |
|------|----------|----------|---------------|
| Active Memory | MEMORY.md | Agent-level durable facts | Injected into every turn |
| User Profile | USER.md | User identity, preferences | Injected into every turn |
| Session History | state.db (SQLite) | Full transcripts, FTS5-indexed | Queried on demand via session_search |

Skills = procedural memory (loaded on demand via skill_view). Curator = self-maintenance (weekly grading, consolidation, pruning).

### AI OS Paradigm
Hermes maps to OS concepts: Gateway=kernel, Cron=process scheduler, Context Budget=memory management, Tool Registry=device drivers, Memory Store=filesystem, ACP=IPC, Profile System=boot loader, Plugin System=package manager, Curator=self-maintenance.

### Provider Fallback Chain
Multi-provider resilience: primary model fails → automatic retry with next configured fallback. Config via `fallback_providers` in config.yaml. A single session can ride through gateway errors, rate limits, and model unavailability.
