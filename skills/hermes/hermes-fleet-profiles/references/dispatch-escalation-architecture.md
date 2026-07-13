# Progressive Dispatch Escalation Architecture

**Context:** Formalizes the "council for evaluation, dispatch for execution" principle.
**Provenance:** Fleet optimization session 2026-06-24, derived from open question #9 analysis.
**Related:** `fleet-dynamic-routing-decision-tree.md` (the pattern-level view of the same system).

## The 5-Level Escalation Model

Every request enters at Level 0. Only climbs when the current level can't resolve it.

```
Level 0 — Direct (Stella handles it)              ← 60% of requests
   ↓  if it needs a specialist
Level 1 — Dispatch to 1 worker                    ← 30% of requests
   ↓  if the worker's domain is code or content
Level 2 — Sequential gates (Nemesis → Ceres)      ← 8% of requests
   ↓  if Nemesis is uncertain (<50% confidence)
Level 3 — Conditional debate (Eris-101)           ← 1.5% of requests
   ↓  if destructive or irreversible
Level 4 — Human-in-Loop (user decides)           ← 0.5% of requests
```

## When Each Level Fires

| Level | Agents at Runtime | Latency | Quality | Cost | Trigger |
|-------|-------------------|---------|---------|------|---------|
| 0 | 0 (me) | Instant | Good enough | Zero | Status, config, analysis, advice |
| 1 | 1 specialist | 20-60s | Good | Low | Code, search, wiki, DevOps, data, design, content |
| 2 | 2-3 total | 60-120s | Better | Medium | Code review, content review |
| 3 | 2 evaluators | 90-180s | Best | High | Nemesis confidence < 50% |
| 4 | 1 (human) | Variable | Authoritative | N/A | Destructive ops, irreversible actions |

## Research Backing

- **Digital Applied (Swarm frontier):** Council = 2.5× quality on *reasoning* tasks, 2.5× cost. Not worth it for execution.
- **arXiv 2601.13671v1:** Council is for *evaluation* (deciding what's right). Dispatch is for *execution* (doing the work).
- **Galileo:** Coordination overhead is O(n²) — 200ms per agent pair, 4s+ for 7 agents.
- **Our E2E tests (Phase 7):** Dispatch + sequential gates catches 90/100 quality on code. Council would add 2.5× cost for marginal improvement on tasks that already pass Ceres.

## Dispatch Discipline

Stella (the default profile) is the entry point at Level 0. She must not do a specialist's work:

| Keep at Level 0 | Must dispatch to Level 1+ |
|----------------|--------------------------|
| Planning, analysis, architectural advice | Any code → Metis |
| Config changes, file reads, status checks | Any web search → Artemis |
| Coordinating the fleet, translating intent | Any wiki operation → Klio |
| Quick terminal checks (<10s) | Any data analysis → Fortuna |
| | Any design/layout → Harmonia |
| | Any devops/infra → Atalanta |
| | Any content/drafting → Kalliope |
| | Any security/QA/review → Vesta/Nemesis/Ceres |

**Hard rule:** Dispatch within 1 turn of identifying a specialist's domain. If she starts doing a specialist's work, she catches herself mid-turn and routes instead. Dispatch is quality routing, not delegation.

**Exceptions:**
- Planning/analysis related to a domain is Level 0 (e.g. "should I use Python or Rust?")
- Quick status checks <10s (e.g. "is the router running?")
- When the fleet is down or unreachable

## Contrast with Full Council

| | Our progressive escalation | Full council (not built) |
|---|---|---|
| Every task debated? | No — only when gates are uncertain | Yes — every output |
| Cost | 1-1.5× base | 2.5× base |
| Latency | 20s-3min | 3-10min |
| When to build | Current state | Phase 10 — only if existing gates miss errors |
