# Ecosystem Reference Taxonomy

A reusable category template for auditing reference documents against community ecosystems. Extracted from the canonical community resource — **Hermes Atlas** (hermesatlas.com, maintained by ksimback).

## Hermes Atlas — Canonical Reference

**Source:** https://hermesatlas.com/ · GitHub: ksimback/hermes-ecosystem (1k+★)
**Scale:** 169 repos, 727.9K+ community stars, 12 categories
**Update cadence:** Daily (automated) — always the freshest data
**Snapshot tool:** `web_extract(urls=["https://hermesatlas.com/"])` — returns the full curated list data

### 12 Atlas Categories (in order)

```
01  Core/Official                → Nous Research repos, core agent
02  Workspaces & GUIs            → Web/desktop interfaces
03  Skills & Skill Registries    → agentskills.io skills, skill packs
04  Memory & Context             → Semantic memory, graph retrieval, persistence
05  Plugins & Extensions         → Runtime plugins, sidecars, event hooks
06  Multi-Agent & Orchestration  → Fleet managers, swarm coordinators, delegation
07  Deployment & Infra           → Docker, Nix, systemd, Kubernetes, Android
08  Integrations & Bridges       → Platform connectors, data bridges
09  Developer Tools              → Linters, migration helpers, token trackers
10  Domain Applications          → Robotics, gaming, legal, blockchain, infra
11  Guides & Docs                → Wikis, tutorials, optimization guides
12  Forks & Derivatives          → Notable forks, reimplementations
```

## Audit Workflow: Document vs Hermes Atlas

When auditing a Hermes ecosystem reference document against the live Atlas:

### Phase 1: Load Atlas data

```python
from hermes_tools import web_extract

result = web_extract(urls=["https://hermesatlas.com/"])
# Result contains every curated list — section content, star counts, descriptions
```

The Atlas main page returns the entire dataset including all 12 curated list sections. No need to visit individual list URLs.

### Phase 2: Map sections

Map each Atlas category to the corresponding section in the target doc:

| Atlas Category | Typical Doc Section | Audit Action |
|----------------|-------------------|--------------|
| Core/Official | "Official Nous Research" | Update star counts, add new repos |
| Workspaces & GUIs | "Workspaces & GUIs" | Update stars, add new GUI projects |
| Skills | "Top Community Skills" | Update stars, add notable new skills |
| Memory & Context | "Memory Providers" | Update stars, add new memory engines |
| **Plugins & Extensions** | Often MISSING | Insert new section |
| Multi-Agent | "Multi-Agent Frameworks" | Update stars, add frameworks |
| Deployment | "Deployment Options" | Update stars, add options |
| **Integrations & Bridges** | Often MISSING | Insert new section |
| Developer Tools | "Developer Tools" | Update stars, add tools |
| Domain Applications | "Domain Applications" | Update app list |
| Guides & Docs | "Guides" | Add new guides |
| Forks & Derivatives | "Forks & Derivatives" | Add new forks |

### Phase 3: Compare & patch at three levels

**Level 1 — Stale star counts** (safest, smallest change)
Target every `k`-suffixed number in existing tables against the Atlas value.

**Level 2 — Missing entries in existing tables**
The Atlas lists 10-20 repos per category. The doc may list only 6-10. Add the top 3-5 missing entries by star count, especially if they have >1K★.

**Level 3 — Entire missing sections**
The doc may be missing Plugins & Extensions and Integrations & Bridges entirely. These are the most common gaps. Insert them as complete `<h4>` + `<div class="tw"><table>` blocks.

### Phase 4: Patch order (parallelize within each layer)

```
Layer 1 — Safe parallel (no content overlap):
  1. Hero stats section count
  2. Atlas intro paragraph (stats, category names, report links)
  3. Sidebar / navigation / quick-jump data

Layer 2 — Content tables (each unique old_string):
  4. Official Nous table (star counts)
  5. Workspaces & GUIs (stars + new entries)
  6. Memory Providers (stars + new entries)
  7. Developer Tools (stars + new entries)
  8. Multi-Agent Frameworks (stars + new entries)
  9. Deployment Options (stars + new entries)
  10. Top Community Skills (stars + new entries)

Layer 3 — Structural inserts (depend on knowing exact insertion points):
  11. Insert Plugins & Extensions section
  12. Insert Integrations & Bridges section
  13. Update Forks, Domain Apps, Guides lists
  14. Update Key Integrations

Layer 4 — Cross-references:
  15. Section-nav prev/next chains (if sections were inserted before/after)
  16. Internal text references mentioning section numbers
```

## Current Notable Projects by Category (from Atlas, live)

Use this as a quick-reference when comparing — these are the top entries per category as of the most recent Atlas snapshot:

### Core/Official
hermes-agent (195.3K★), self-evolution (4.1K★), paperclip-adapter (1.6K★), function-calling (1.4K★), atropos (1.3K★), autonovel (1.1K★)

### Workspaces & GUIs
cc-switch (102.6K★), AionUi (28.4K★), hermes-webui/nesquena (14.6K★), hermes-desktop/fathah (12.3K★), hermes-web-ui (8.0K★), hermes-workspace (5.7K★)

### Skills & Skill Registries
open-design (66.0K★), Anthropic-Cybersecurity-Skills (16.0K★), drawio-skill (3.7K★), SkillClaw (1.9K★), avoid-ai-writing (1.9K★)

### Memory & Context
mem0 (58.7K★), supermemory (27.1K★), OpenViking (25.7K★), gbrain (23.0K★), Hindsight (16.5K★), Honcho (5.2K★), ByteRover (4.9K★)

### Plugins & Extensions
atomic-filesystem (4.9K★), hermes-agents (455★), hermes-agent-toolserver (62★), gladstone (29★), Hermes-Extender (16★)

### Multi-Agent & Orchestration
mission-control (5.3K★), agent-of-empires (2.6K★), hermes-agent-control-room/CryptoDmitry (858★), swarmclaw (583★), minions (578★)

### Deployment & Infra
llm-agents.nix (1.4K★), ClawPhone (536★), portable-hermes-agent (169★), hermes-agent-helm-chart (98★)

### Integrations & Bridges
lovable-dev-assistant (1.9K★), speech-mcp-server (459★), hermes-lcm-supabase (310★), hermes-signal-integration (130★)

### Forks & Derivatives
hermes-agent-camel, orahermes-agent (Oracle), hermes-alpha (cloud), valhalla, hermes-agent-ultra (190+ tools), go-hermes

### Notable New Guides
hermes-orange-book (4.4K★), hermes-optimization-guide (448★), jwangkun/hermes-agent-guide (370★), learn-hermes-agent

## Maturity Tags

| Tag | Meaning |
|-----|---------|
| production | Stable, documented, actively maintained — safe to build on |
| beta | Works but still evolving — expect some rough edges |
| experimental | Proof of concept or early-stage — learn from it, don't depend on it |

## Common "Your Setup" Audit Items

When auditing a user's own setup against the ecosystem, check for:
- Desktop app / Web UI — persistent window for chat and session browser
- Cron jobs — daily health checks, morning briefings, watchdogs
- Curator (`hermes curator status`) — auto-grades and prunes skills on schedule
- MCP servers — external tool servers extending capabilities
- Multi-model routing — cheap model for simple queries, expensive for deep work
- ACP delegation — hand off coding to Codex/Claude Code/Zed
- Windows-specific: WSL2 setup, Gateway as Windows service, git-bash quirks
