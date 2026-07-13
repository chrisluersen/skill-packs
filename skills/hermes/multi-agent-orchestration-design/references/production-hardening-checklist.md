# Production Hardening Checklist

Use this when reviewing a multi-agent orchestration plan before implementation. Each item represents a gap found during a real plan audit against 16 research sources (arXiv, IBM, Augment, LinkedIn, Galileo, Tianpan, Beam, MLflow, TrueFoundry, Confluent, etc.)

## Phase-by-Phase Checks

### Phase 0 — Pre-Flight
- [ ] **Section numbering consistent?** Re-number after inserting new sections to keep ordering correct (e.g., 3.6 before 3.5 is wrong)
- [ ] **Backup restorable?** Not just taken — verify the restore path works
- [ ] **Agent-factory documented?** Can a new agent be added by following a 10-step checklist?
- [ ] **OWASP AST10 audit?** Production baseline — explicit accept risk or mitigate each item

### Phase 1 — Routing & Validation
- [ ] **LLM routing timeout?** `asyncio.wait_for()` with 60s timeout on Astraea dispatch (30s was too short — first dispatch has ~15-45s spin-up cost)
- [ ] **Fallback path?** Keyword classifier catches LLM failures
- [ ] **Regex post-processing?** LLM output gets `.strip().lower()` + `in ALL_PATTERNS` guard
- [ ] **Route-destinations unambiguous?** Every category maps to exactly one worker
- [ ] **Dead code routing blocks?** Any routing block pointing to an agent that doesn't exist yet is a liability — either create the agent first, or add `if pid in self.profiles:` guard
- [ ] **Content routing correctly targets Kalliope-22?** Do NOT copy-paste from Fortuna-19 (data) to Kalliope-22 (content). The original code had Content routing to Fortuna with `data_analysis_requested=True`.
- [ ] **Keyword ordering correct?** DevOps and Content keyword blocks go BEFORE the "complex" catch-all. "deploy" is DevOps, not complex.
- [ ] **Spec validation heuristic?** Tasks <15 chars for `devops`/`direct` patterns should skip LLM validation (terse commands like "disk space" are valid).
- [ ] **Contract validation wired?** `dispatch_to_agent()` checks `max_turns` and logs tool allowlist from `task_contracts.json`.

### Phase 2 — Profile Creation
- [ ] **Every new profile has SOUL.md?** Task-first persona, not decorative
- [ ] **Profile wired into worker_map/PROFILE_MAP?** No orphan profiles

### Phase 3 — Observability
- [ ] **Health check timeout?** Per-agent `asyncio.wait_for(timeout=10.0)` prevents one slow profile from hanging the whole report
- [ ] **Data retention/Garbage Collection?** Event logs, audit trails, cost logs accumulate — add `RETENTION_DAYS = 30` with cleanup cron
- [ ] **Both trends AND current state?** Backward-looking cron + forward-looking `--health` command

### Phase 4 — Human-in-Loop & Security
- [ ] **Maintenance mode?** `--maintenance on/off` flag for graceful deployment pauses
- [ ] **Tool gateway?** Allowlist + denylist per agent from Task Contract

### Phase 5 — Resilience
- [ ] **Circuit breaker min_samples?** Don't trip on a single failure — `min_samples=5` prevents 1/1 = 100% false positive
- [ ] **Bulkheads?** Per-class semaphores to prevent noisy-neighbor problem
- [ ] **Idempotency?** Request deduplication cache for retry-safe operations

### Phase 6 — QA & Costs
- [ ] **Max turns enforced?** Per-agent cap from Task Contract
- [ ] **Context budget?** Max 3 workers, 8K per worker + summary handoff
- [ ] **Per-stage output validation?** Non-empty, no errors, contract schema check

### Phase 7 — Documentation
- [ ] **hermes_default defined?** When a fallback profile is referenced, document what it is and why
- [ ] **GraSP recovery documented?** All 4 strategies (Rebind, Substitute, Bypass, Escalate) tested, not just one

### Phase 8 — Testing
- [ ] **Header/table/signals in sync?** If you have 22 tests, EVERY reference says 22 — header, table, done signal, success criteria
- [ ] **Recovery chain tested for ALL strategies?** Not just substitute
- [ ] **Maintenance mode tested both on AND off?**
- [ ] **GC retention tested?** `--gc-only` + verify directory contents

## Common Failure Patterns Found During Production Audit

1. **Ordering drift**: Adding Phase N+1 section between existing sections without renumbering subsequent sections
2. **Count drift**: Updating E2E test table but forgetting header, done signal, or success criteria
3. **Timeout gaps**: All async dispatches that don't have explicit timeouts will hang indefinitely
4. **Undefined references**: Referencing a fallback profile (`hermes_default`) without documenting what it is
5. **No cleanup**: Event logs, audit trails, and cost reports accumulate with no retention policy
6. **Single-point coverage**: Testing one recovery strategy and assuming the rest work
