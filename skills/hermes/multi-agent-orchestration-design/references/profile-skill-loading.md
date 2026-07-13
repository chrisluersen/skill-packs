# Profile Skill Loading — Per-Role [SKILLS] Mapping

## Purpose

Each fleet agent profile's SOUL.md carries a `[SKILLS]` section that tells the agent which procedural skills to load at startup. This is not about tool access (that's handled by `task_contracts.json` allowed_tools + tool tiers) — it's about **procedural knowledge**: the agent should know the established workflow for its domain before starting work.

## Convention

```
[RULES]: ...
[SKILLS]: Load <skill-a> for <reason>. Load <skill-b> for <reason>.
[PERSONALITY]: ...
```

The [SKILLS] line goes between [RULES] and [PERSONALITY]. Skills are loaded via `skill_view()` by the agent when it reads its SOUL.md. Gate agents (pure reasoners with no tools) don't need [SKILLS] sections.

## Per-Role Mapping

### Workers (all have [SKILLS] sections)

| Profile | Role | Skills |
|---------|------|--------|
| **Klio-84** | Wiki librarian | `wiki-operations` — wiki maintenance workflows, lint/audit procedures. `klio` — weekly wiki health procedures. |
| **Metis-9** | Code/debug | `test-driven-development` — TDD workflows (RED-GREEN-REFACTOR). `systematic-debugging` — 4-phase root cause debugging. `codebase-inspection` — repository structure analysis via pygount. |
| **Artemis-105** | Web research | `web-research-synthesis` — structured research reports with multi-source synthesis. |
| **Atalanta-36** | DevOps | `fleet-health-watchdog` — fleet monitoring. `hermes-cron-operations` — cron job management. `wiki-operations` — backup verification. |
| **Kalliope-22** | Content/writing | `design-md` — structured documentation format specs. `document-verification-update` — auditing and updating reference docs. |
| **Fortuna-19** | Data analysis | `jupyter-live-kernel` — interactive data exploration and visualization. |
| **Harmonia-40** | Design | `architecture-diagram` — dark-themed SVG architecture diagrams. `excalidraw` — hand-drawn style diagrams. |

### Gates (no [SKILLS] sections — pure reasoners)

| Profile | Role | Rationale |
|---------|------|-----------|
| **Vesta-4** | Security gate | No tools, no domain-specific procedures |
| **Astraea-5** | Router/classifier | No tools — pure LLM routing |
| **Nemesis-128** | QA evaluator | No tools — pure evaluation |
| **Ceres-1** | Final review gate | No tools — pure verdict |

## Adding [SKILLS] to a New Profile

1. Identify the agent's domain (code, wiki, search, data, design, devops, content)
2. Check which skills exist in the Hermes skills library (`skills_list()`)
3. Map 1-3 skills that cover the agent's core workflows
4. Add `[SKILLS]: Load <skill-a> for <reason>. Load <skill-b> for <reason>.` between [RULES] and [PERSONALITY]
5. Update this reference file with the new mapping

## Pitfalls

- **Don't add skills to gate agents.** They have no tools and no domain-specific workflows — skills waste context.
- **Don't overload.** 1-3 skills per agent is the sweet spot. More than 3 and the agent won't actually load them all.
- **State the reason.** "Load X for Y" tells the agent *when* to use the skill, not just *that* it exists.
- **Skills are not tools.** A skill is procedural knowledge (how to do something). A tool is a capability (what you can do). Both are needed. The [SKILLS] section complements the `allowed_tools` in task_contracts.json — it doesn't replace it.
