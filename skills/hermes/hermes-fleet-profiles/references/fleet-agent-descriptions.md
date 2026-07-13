# Hermes Fleet — Current Agent Roster (2026-07-01)

Source of truth: `~/AppData/Local/hermes\AppData\Local\hermes\AGENT.md`

---

## Default Profile

| Agent | Designation | Role | Profile Dir | Model | Tools |
|-------|-------------|------|-------------|-------|-------|
| **Stella** | Default | Coordinator, UI, Dispatcher | (root) | direct Sonnet 4 (openrouter) | All (coordinator) |

---

## Fleet Roster (11 Asteroid Profiles)

| Agent | Designation | Role | Profile Dir | Model | Tools |
|-------|-------------|------|-------------|-------|-------|
| **Artemis-105** | Search & Recon | Web search, research, recon | profiles/artemis | deepseek/deepseek-v4-flash | web, terminal, file |
| **Astraea-7** | Task Decomposition | Complex multi-part planning, task classification | profiles/astraea | deepseek/deepseek-v4-flash | web, terminal, file, delegation |
| **Ceres-1** | Review Gate | Final QA, fail-closed review, pipeline approval | profiles/ceres | deepseek/deepseek-v4-flash | terminal, file, code |
| **Kalliope-22** | Content Specialist | Drafting, documentation, content writing | profiles/kalliope | deepseek/deepseek-v4-flash | terminal, file, web, delegation |
| **Klio-84** | Wiki Librarian | Lint, reindex, promote, gbrain | profiles/klio | deepseek/deepseek-v4-flash | terminal, file, wiki MCP |
| **Metis-9** | Code & Engineering | Implementation, refactor, debug | profiles/metis | deepseek/deepseek-v4-flash | terminal, file, code |
| **Nemesis-128** | QA Gate | Structured evaluation, scoring, rejection feedback | profiles/nemesis | deepseek/deepseek-v4-flash | terminal, file, web |
| **Vesta-4** | Security Gate | Input sanitization, security screening | profiles/vesta | deepseek/deepseek-v4-flash | terminal, file, code |
| **Fortuna-19** | Data & Analysis | Metrics, eval, cost optimization | profiles/fortuna | deepseek/deepseek-v4-flash | terminal, file, web |
| **Harmonia-40** | Design & Layout | UI, HTML, diagrams, Excalidraw | profiles/harmonia | deepseek/deepseek-v4-flash | terminal, file, creative |
| **Atalanta-36** | DevOps & Infra | Deploy, cron, Docker, CI/CD | profiles/atalanta | deepseek/deepseek-v4-flash | terminal, file, web |

> **Thalia-23** merged into Stella on 2026-06-18. No separate profile.

---

## Infrastructure Reference

| Component | Location / Endpoint |
|-----------|---------------------|
| **fleet-manager.py** | `~/AppData/Local/hermes\AppData\Local\hermes\fleet\fleet-manager.py` (v3.14) |
| **Pub/Sub Event Bus** | MCP server `fleet` (stdio) |
| **Router (hermes-router)** | `http://localhost:8319/v1` — 25 providers, OpenRouter funded |
| **Wiki (agent-wiki)** | `~/agent-wiki` — 450+ pages, Karpathy pattern, Klio maintains |
| **Config** | `~/AppData/Local/hermes\AppData\Local\hermes\config.yaml` — `custom:hermes-router` |

---

## Dispatch Table

| user says… | Route to |
|-------------|----------|
| "fix the router" | Atalanta-36 (infra) / Metis-9 (code) |
| "update the wiki" | Klio-84 |
| "fleet status" | All profiles, fleet-manager.py, cron health, router health |
| "make X better" | Kalliope-22 |
| Any code | Metis-9 |
| Any web search | Artemis-105 |
| Any wiki op | Klio-84 |
| Any data analysis | Fortuna-19 |
| Any design/layout | Harmonia-40 |
| Any devops/infra | Atalanta-36 |
| Any content/drafting | Kalliope-22 |
| Any security/QA/review | Vesta-4 / Nemesis-128 / Ceres-1 |

---

## Key Cron Jobs

| Job | Schedule | Purpose |
|-----|----------|---------|
| `session-registry-sync` | */5 * * * * | Sync state.db → session_registry.db |
| `klio-weekly` | 0 9 * * 1 | Full wiki maintenance |
| `klio-backlog` | 0 9 * * 3 | Wiki backlog process |
| `klio-expansions` | 0 9 * * 6 | Content expansion |
| `task-curator` | every 120m | Task landscape review |
| `router-watchdog` | every 5m | Provider status changes |
| `fleet-health-watchdog` | every 30m | Fleet liveness, circuit breakers |

---

## Update Protocol

When fleet changes (add/remove agent, change model, change infra):
1. Update `~/AppData/Local/hermes\AppData\Local\hermes\AGENT.md`
2. Update this reference file (`references/fleet-agent-descriptions.md`)
3. Update wiki entity `entities/hermes-identity-files.md` if identity file table changes
4. Commit both

---

*Generated 2026-07-01. Keep in sync with AGENT.md.*