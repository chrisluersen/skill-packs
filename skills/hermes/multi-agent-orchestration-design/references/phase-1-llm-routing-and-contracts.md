# Phase 1 Implementation — LLM Routing, Contracts & Spec Validation

> Deployed June 24, 2026 as part of the fleet v3 overhaul.
> Executed by Stella, implemented in `fleet-manager.py`.

## What Was Built

| Feature | Code | Description |
|---------|------|-------------|
| LLM Routing | `_llm_classify_task()` | 9-category classification via Astraea-5 with keyword fallback |
| Spec Validation | `_validate_task_spec()` | 1-5 specificity rating, heuristic skip for short DevOps commands |
| Trace ID | `trace_id = uuid.uuid4().hex[:12]` | 12-char hex ID on every request, logged in dispatch header |
| Context Budget | `_check_context_budget()` | Max 3 concurrent workers (global semaphore), per-agent burst of 5 |
| Contract Dispatch | `dispatch_to_agent()` + `TASK_CONTRACTS` | 11 contracts loaded from JSON, max_turns/tool allowlist enforced |
| DevOps Routes | Added `atalanta_36` to routing | Keyword + LLM routing for infrastructure tasks |
| Content Routes | Added `kalliope_22` to routing | Keyword + LLM routing for writing/copy tasks |

## Files Modified

- `fleet-manager.py` — 13 targeted patches, ~400 lines added
- `task_contracts.json` — Created at `~/.hermes/fleet/` with 11 agent contracts
- `latest-handoff.md` — Updated with Phase 0 + 1 completion

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| LLM routing → keyword fallback | LLM is smarter but slower. Keyword catches common patterns instantly. |
| 60s timeout on `_llm_classify_task` | 30s failed because subprocess spin-up takes 15-45s on first call |
| Spec validation skips <15-char DevOps tasks | "disk space" is valid but too short for LLM to rate meaningfully |
| trace_id NOT in FleetEvent constructor | Keeps event creation stateless; trace_id set by dispatcher |
| Global Semaphore(3) + per-agent burst(5) | Two-layer context budget prevents single-agent queue buildup |
| Content routes BEFORE complex keyword | "write a doc" is content, not complex — ordering matters |

## Bug Fixed

**Content routing misdirection:** `is_content` was routing to `fortuna_19` (data analysis) with `data_analysis_requested=True`. The comment said "Content → Kalliope-22" but the code routed to the wrong agent. Fixed to correctly route to `kalliope_22` with no spurious parameters.

**Root cause:** Dead code — the routing block was written before Kalliope-22 existed. Since the profile didn't exist, the bug was invisible until the profile was created.

## Remaining Work (for next implementer)

- Phase 2: Create Atalanta-36 and Kalliope-22 SOUL.md profiles
- Phase 3: Deep observability (fleet-observer cron, `--health` command)
- Phase 3.5: Event sourcing (immutable JSONL per trace_id)
- Populate `allowed_tools` for all agents (5 of 11 currently have 0 tools — deny-all)
