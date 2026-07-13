# Fleet Overhaul Plan v3 — Complete Architecture Reference

> Generated June 24, 2026 from the optimal multi-agent orchestration design session.
> Full plan: 1,722 lines covering 14 phases from backup through closeout.

## Source (Live Plan)

The authoritative plan lives at:
`.hermes/plans/2026-06-24_optimal-multi-agent-orchestration.md`

## Quick Reference — 14 Phases

| Phase | Title | Est. Time |
|-------|-------|-----------|
| 0 | Pre-Flight + Task Contracts + OWASP AST10 | 45 min |
| 1 | LLM Routing + Spec Validation + Context Budget + Trace ID | 1h 30m |
| 2 | Kalliope-22 & Atalanta-36 SOUL.md Profiles | 45 min |
| 3 | Deep Observability — Support Agent | 45 min |
| 3.5 | Typed Shared State + Tracing + Event Sourcing | 45 min |
| 4 | Human-in-Loop Gate + Tool Gateway | 45 min |
| 5 | Bulkheaded Fan-Out + Rate-Limited Dispatch | 45 min |
| 5.5 | Circuit Breaker + Idempotency + Exponential Backoff | 45 min |
| 6 | Gate Optimization + Eris-101 Second Evaluator | 45 min |
| 6.5 | Cost Tracking + Governance + Event Sourcing | 30 min |
| 6.75 | max_turns Enforcement + Output Validation | 30 min |
| 7 | Profile Tuning — Task-First Personas | 30 min |
| 8 | E2E Test Suite — 15 Tests | 1h |
| 9 | Closeout — Wiki + Handoff | 15 min |

**Total:** ~8h 45m cumulative · ~5h 30m wall clock (parallelized)

## Fleet Composition

12 profiles (7 workers + 3 gates + 1 routing + 1 coordinator):

| Agent | Role | Cost Tier | max_turns |
|-------|------|-----------|-----------|
| Astraea-5 | LLM Router/Planner | guardrail | 3 |
| Vesta-4 | Security Gate | guardrail | 2 |
| Metis-9 | Code Generation | heavy | 8 |
| Artemis-105 | Web Search | fast | 6 |
| Klio-84 | Wiki Librarian | fast | 5 |
| Fortuna-19 | Data Analysis | heavy | 8 |
| Harmonia-40 | Design/Layout | fast | 6 |
| Atalanta-36 | DevOps/Infrastructure | fast | 5 |
| Kalliope-22 | Content/Copywriting | fast | 8 |
| Nemesis-128 | QA Evaluation Gate | heavy | 5 |
| Ceres-1 | Final Review Gate | heavy | 3 |
| Stella | Coordinator/Supervisor | — | — |

## Key Architecture Decisions

### Broadcast
- Orchestrator-Worker with LLM-based routing + keyword fallback
- Task-first profiles (not theatrical personas)
- Sequential pipeline only for complex pattern

### Safety
- Circuit breakers: 3-state per agent. 50% failure rate over 60s, 120s cooldown
- Bulkheads: Per-class semaphores (heavy=2, fast=5, guardrail=3)
- Human-in-Loop: --confirm gate for destructive operations
- Tool gateway: Per-agent tool allowlist from Task Contract
- OWASP AST10: Reviewed for every skill/plugin

### Observability
- fleet-observer cron: Every 4h — cost, latency, error rates, CB trips, spec rejections
- Trace ID: UUID on every request, linking cost/audit/events/logs
- Event sourcing: Immutable JSONL per trace_id, 7-day GC
- Cost tracking: Per-dispatch token estimate, --cost-report aggregate

### State
- PipelineState dataclass with provenance tagging (certain/sourced/uncertain)
- Per-stage output validation: non-empty, no errors, contract schema check

### Recovery
- GraSP: Substitute (1st) → Rebind (2nd) → Bypass (3rd) → Escalate (4th)
- Idempotency keys for dedup
- Exponential backoff with jitter

### Security (Deferred)
- Sandboxed execution, privilege rings, full OWASP AST10 compliance — all deferred. Acceptable for single-user fleet.

## Research Sources

16 sources consolidated: arXiv 2601.13671 / IBM Think / Augment Code / Beam AI / Confluent / TrueFoundry / MLflow / Galileo / Tianpan / LinkedIn Playbook / CrewAI / MindStudio / Digital Applied / Medium Best Practices / Anthropic Engineering / Prior E2E tests

## See Also

- references/research-synthesis.md — Full research notes from all 16 sources
- templates/task-contracts.json — Template for per-agent contract definitions
