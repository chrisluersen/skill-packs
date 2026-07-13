---
name: multi-agent-orchestration-design
description: "Design optimal multi-agent fleet architectures — agent topology, orchestration layers, distributed systems patterns (circuit breakers, bulkheads, task contracts), and research-backed evaluation methodology. Ships with 64-test E2E test suite + silent health watchdog cron."
version: 2.8.1
author: 7-Iris
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [fleet, orchestration, architecture, multi-agent, distributed-systems, planning, design]
    related_skills: [hermes-fleet-profiles, fleet-pub-sub-event-bus, review-gate, plan]
---

# Multi-Agent Orchestration — Architecture Design

Use this skill when designing or auditing the architecture of a multi-agent system (fleet of LLM agents). Covers:

- Agent topology — which agents, why that many, what roles
- Orchestration layers — routing, state, recovery, governance
- Distributed systems patterns — circuit breakers, bulkheads, idempotency, event sourcing
- Task contracts — per-agent input/output schemas
- Research synthesis — consuming production research to validate architecture decisions

## Core Architecture Principles

### Agent Topology

Research (arXiv 2601.13671, Beam AI, Galileo) converges on:

| Property | Optimal Range | Source |
|----------|--------------|--------|
| Active agents | 5-10 total | arXiv scaling, Beam prod data |
| Workers | 5-7 domain specialists | Single responsibility per worker |
| Gates | 2-3 (security, QA, review) | Generator+Critic pattern |
| Coordinator | 1 (LLM-based router) | IBM, Anthropic, arXiv |

**Three agent categories** (arXiv taxonomy):

1. **Worker Agents** — Task execution (code, search, data, design, devops, content)
2. **Service Agents** — Shared operational capabilities (QA, compliance, diagnostics)
3. **Support Agents** — Supervisory/analytical (monitoring, cost tracking, drift detection)

Support agents are the most commonly omitted and most commonly needed category in production.

### Orchestration Layer Components

| Component | What It Does | Must Be |
|-----------|-------------|---------|
| **Planning Unit** | Goal decomposition, task routing | LLM-based (not keyword) |
| **Policy Unit** | Constraints, governance, permissions | Deterministic code |
| **State Management** | Cross-agent context, provenance | Typed schema, not raw strings |
| **Quality Operations** | Output validation, drift detection | Per-stage, not just final |

**Key insight from LinkedIn Playbook:** "LLMs decide what to do. The workflow engine guarantees it gets done reliably." Distinguish between LLM-driven decisions and deterministic workflow execution — don't let the LLM control retry logic, state persistence, or access control.

### Dispatch Patterns (Priority Order)

Based on production evidence (Beam AI, Digital Applied, MindStudio):

| Pattern | Wall-clock | Cost | When to Use |
|---------|-----------|------|------------|
| **Direct** (0 hops) | Fastest | Lowest | Greetings, status, simple Q&A |
| **Single Worker** (1 hop) | Fast | Low | Most domain tasks |
| **Fan-Out** (parallel N) | ~75% reduction vs sequential | N× per-call cost | Multi-angle research, comprehensive analysis |
| **Sequential Pipeline** (N hops) | Slowest | Highest | Complex multi-step (research→draft→review) |
| **Conditional Debate** (selective) | Medium | ~0.5× over single | Code when QA gate is uncertain (Eris-101) |

### Council vs Dispatch — Architectural Choice

The question of whether to use a **council pattern** (all agents see the same task, debate, produce consensus) or **dispatch pattern** (one worker per task, optional gates) comes up in every multi-agent design.

**Research summary:**

| Source | Finding |
|--------|---------|
| Digital Applied | Council = 2.5× quality on reasoning, also 2.5× cost |
| Digital Applied | Swarm frontier = 300 agents (for analysis, not daily ops) |
| arXiv 2601.13671v1 | Council for evaluation, dispatch for execution |
| Galileo | Coordination overhead O(n²): 200ms per pair, 4s+ for 7 |

**Decision framework — which to use when:**

| Pattern | Latency | Cost | Quality | Right for |
|---------|---------|------|---------|-----------|
| **Dispatch** (1 worker) | 20-60s | 1× | Good | 90% of tasks — search, code gen, read/write, status |
| **Sequential gates** (1 worker + 1-2 reviewers) | 60-120s | 1.5× | Better | Code review, content review |
| **Fan-out dispatch** (2-3 workers parallel) | ~60s | 2-3× | Better | Multi-angle research |
| **Conditional debate** (1 worker + 2nd evaluator on demand) | 60-120s | ~1.5× | Best | Code when first reviewer is uncertain |
| **Full council** (3-7 agents debate) | 3-10 min | 2.5× | Best | Architectural decisions, policy writing |

**Recommendation:** Hybrid progressive escalation is optimal for a single-user fleet. Full council for every request wastes 2.5× cost on tasks that already pass gates at 90/100. Build council only when existing gates can't catch a recurring error class.

**Implementation note:** Use the conditional second evaluator pattern (Eris-101, see below) as the "council lite" — it fires only when the first evaluator expresses uncertainty, keeping the 2.5× cost at ~0.5× of code costs.

### Progressive Escalation — The Decision Architecture

Every request enters at Level 0 and only climbs when necessary. This is the core efficiency principle: **don't review what's already correct, don't debate what's already decided.**

```
Level 0 — Direct (coordinator handles it)                    ← 60% of requests
   ↓  if it needs a specialist
Level 1 — Dispatch to 1 worker                               ← 30% of requests
   ↓  if the worker's domain is safety-critical (code, content)
Level 2 — Sequential gates (QA → review)                     ← 8% of requests
   ↓  if QA gate is uncertain (<50% confidence)
Level 3 — Conditional debate (second independent evaluator)  ← 1.5% of requests
   ↓  if destructive or irreversible
Level 4 — Human-in-Loop                                      ← 0.5% of requests
```

| Level | Agents at Runtime | Latency | Quality | Cost | When |
|-------|------------------|---------|---------|------|------|
| 0 | 0 (coordinator only) | Instant | Good enough | Zero | Status, config, chat |
| 1 | 1 specialist | 20-60s | Good | Low | Search, wiki, devops |
| 2 | 2-3 total | 60-120s | Better | Medium | Code or content review |
| 3 | 2 evaluators | 90-180s | Best | High | Code when QA uncertain |
| 4 | 1 (human) | Variable | Authoritative | N/A | Destructive ops |

**Design rationale:** The fleet does NOT have a council that reviews every output. It doesn't need one. Research confirms the 2.5× cost of full debate accomplishes nothing on tasks that already pass single-agent gates at 90/100.

### Dispatch Discipline — Coordinator's Hard Rules

The coordinator (Level 0) is not a general-purpose agent. It translates and routes — it does not execute specialist work. **These rules prevent scope creep into specialist domains.**

**The 1-turn rule:** The coordinator must dispatch any task matching a specialist's domain within 1 turn of identifying it. If it starts doing specialist work, it catches itself mid-turn and routes instead.

| Keep at Level 0 | Must dispatch to Level 1+ |
|----------------|--------------------------|
| Planning, analysis, architectural advice | Any code → coding specialist |
| Config changes, file reads, status checks | Any web search → search specialist |
| Coordinating the fleet, translating intent | Any wiki operation → librarian |
| Quick terminal checks (<10s) | Any data analysis → data specialist |
| | Any design/layout → design specialist |
| | Any devops/infrastructure → ops specialist |
| | Any content/drafting → content specialist |
| | Any security/QA/review → gate specialists |

**Exceptions:**
- **Planning-level decisions:** "Should I use Python or Rust for this project?" — that's architecture, not execution. Keep at Level 0.
- **Quick status checks:** "Is the router running?" — if it takes <10s via terminal, handle it. Faster than dispatching.
- **Fleet down:** When specialists are unreachable, do the work yourself but note the outage.

**Why this rule exists:** E2E tests consistently show that coordinators produce worse output than task-first specialists in domain-specific work. Dispatch is quality routing, not delegation.

**Self-correction protocol:** If the coordinator catches itself doing a specialist's work, it stops mid-turn, says "this should go to [specialist]," and dispatches. Do NOT finish half the work and hand it off.

**Critical constraints:**
- Sequential is the most expensive pattern (Beam: 950ms overhead per 4-agent chain)
- Context overflow with 4+ parallel workers (Beam). Cap at 3 with summary-based handoff
- Rate limits are #1 fan-out failure (Beam). Use per-class bulkheads

### Evaluator Pattern — Second Independent Opinion (Eris-101)

Galileo: "Multiple evaluator agents independently assess outputs — RLAIF principle — prevents single points of failure." A single QA gate misses errors that a second perspective would catch.

**Conditional second evaluator** — fire only when the first evaluator has low confidence. This keeps cost at ~0.5× (not 2.5× for full debate).

```python
needs_second_opinion = (
    worker_profile_id == "metis_9"   # Code only (safety critical)
    and (
        nemesis_score < 80            # Low score → second opinion
        or any(sig in str(issues).lower() for sig in [
            "uncertain", "might", "i'm not sure",
            "could not fully determine",
        ])                             # First evaluator expressed doubt
    )
)

if needs_second_opinion:
    second_response = await dispatch_to_agent(nemesis_profile, FleetEvent(
        type="compilation_success",
        payload={
            "code": worker_output,
            "task": user_input,
            "context": (
                "You are a second independent reviewer. The first review "
                "has been completed. Look for issues the first reviewer "
                "MISSED. Focus on: correctness, edge cases, security "
                "vulnerabilities, and any assumptions that aren't validated. "
                "Reply with your own FINAL_EVALUATION: block — do not "
                "reference the first review."
            ),
        },
        source="eris_101",
    ), pipeline=pipeline)

    second_eval = parse_evaluation(second_response or "")
    if second_eval:
        evaluations.append(second_eval)
        # aggregate_evaluations() merges all — confidence-weighted
        # average on scores, strictest on split verdicts
        aggregate = aggregate_evaluations(evaluations)
```

**Which patterns get second opinion:**
- **Code (Metis-9):** Always — safety critical, cost of error is high
- **Data/Content (Fortuna-19, Kalliope-22):** Only if first review expresses uncertainty
- **Search/Wiki/DevOps:** Never — factual lookup, single pass suffices

**Cost impact:** Full debate = 2.5× single model (Digital Applied). Conditional second opinion on ~20% of code dispatches = ~0.5× code costs, ~0.1× overall.

## Distributed Systems Patterns for Multi-Agent Fleets

**Core insight from Tianpan (2026):** Multi-agent systems ARE distributed systems. Apply microservices lessons before learning them the hard way.

### Circuit Breaker (3-State)

Every agent API call, tool invocation, or inter-agent communication is a service call that can fail (LLM APIs fail 1-5%).

```python
States: CLOSED → OPEN → HALF_OPEN → CLOSED
- CLOSED: calls pass through normally
- OPEN: all calls rejected immediately with fallback
- HALF_OPEN: limited traffic allowed to test recovery
- Threshold: ~50% failure rate over rolling 60s window
- Cooldown: ~120s before entering HALF_OPEN
```

**Apply at:** Every agent boundary. One breaker per worker agent.

**Pitfall:** Starting threshold too sensitive. LLM API flakiness (1-5%) should not trip the breaker. Use 50% over 60s as baseline and adjust after observing real patterns.

**Tuning over time:**
| Scenario | Threshold | Window | Cooldown | Rationale |
|----------|-----------|--------|----------|-----------|
| Initial | 50% | 60s | 120s | Conservative — tolerates normal LLM flakiness |
| After 2 weeks stable | Lower to 40% | 60s | 120s | Tighten if system proves reliable |
| After observed retry storms | Raise to 60% | 30s | 180s | Loosen if false positives block real work |

### Bulkheads (Per-Class Resource Pools)

Prevent "noisy-neighbor problem" where one agent class monopolizes shared resources (e.g., research agent exhausting rate limits for user-facing agent).

```python
BULKHEAD_SEMAPHORES = {
    "heavy": asyncio.Semaphore(2),    # Code gen, QA, review, analytical
    "fast": asyncio.Semaphore(5),     # Search, wiki, devops, content, design
    "guardrail": asyncio.Semaphore(3),# Security, routing
}
```

**Apply at:** Fan-out dispatch and any parallel execution path.

**Common failure:** A single shared semaphore means Metis-9 (code, heavy, slow) blocks Atalanta-36 (devops, fast, quick). Fix with per-class pools.

### Idempotency Keys

"At-least-once delivery" means operations can execute multiple times due to retries. Non-idempotent operations produce incorrect results.

```python
id_key = hashlib.md5(f"{agent_pid}:{task_text}".encode()).hexdigest()
if id_key in cache:
    return cached_result  # Dedup
```

**Apply at:** Retry loops, circuit breaker half-open testing.

**Pitfall:** Unbounded cache growth. Add TTL (5 min) or LRU eviction.

### Exponential Backoff with Jitter

Prevent retry storms from overwhelming a recovering service.

```python
delay = base_delay * (2 ** attempt) + random.uniform(0, base_delay * (2 ** attempt) * 0.5)
```

**Apply at:** Any retry loop. Replace fixed delays.

### Distributed Tracing — Trace ID

LinkedIn Playbook: "Every run gets a trace ID linking: user request → retrieval → model calls → tool calls → final output → evaluation result." **Non-negotiable production artifact.**

```python
import uuid

# Seed at request entry
trace_id = uuid.uuid4().hex[:12]  # 12 hex chars = 2.8e14 unique IDs
log.info(f"🔍 [{trace_id}] New request: {task[:100]}")

# Thread through PipelineState
state = PipelineState(task=task, trace_id=trace_id, start_time=time.time())

# Include in every dispatch, cost record, audit entry, event sourcing file
```

**Where trace_id links:**
- **Cost tracking:** `trace_id` in every cost_log.jsonl entry
- **Audit trail:** `trace_id` in every audit.jsonl entry
- **Event sourcing:** `trace_id.jsonl` filename for the full event chain
- **Logs:** `[trace_id]` prefix in every pipeline log line

**Collision risk:** 12 hex chars = 16^12 ≈ 2.8 × 10^14 IDs. At 1,000/day, probability of collision in 100 years is negligible.

**Pitfall:** Forgetting to pass trace_id through async dispatch calls. Must be threaded through ALL pipeline stages, not just the entry point.

### Cost Tracking + Audit Trail

Every dispatch should record its estimated cost and an audit trail. This is separate from event sourcing (which records all pipeline events) — cost/audit logs are immutable append-only records designed for reporting and forensics.

**Cost estimation — directional, not billing:**
```python
TOKENS_PER_SECOND = {"fast": 800, "heavy": 250, "guardrail": 600}
COST_PER_1K_TOKENS = 0.0002  # ~$0.002/10K tokens (Nous directional)

def estimate_dispatch_cost(agent_pid: str, duration_ms: float) -> dict:
    """Map agent → tier → tokens/sec → estimated cost. Directional only."""
    tier = "heavy" if agent_pid in TIER_8_AGENTS else \
           "guardrail" if agent_pid in TIER_0_AGENTS else "fast"
    tps = TOKENS_PER_SECOND.get(tier, 400)
    estimated_tokens = int(tps * (duration_ms / 1000))
    return {"tokens": estimated_tokens, "cost_usd": round(estimated_tokens / 1000 * COST_PER_1K_TOKENS, 6), "level": tier}
```

**Log files:**
- `~/AppData/Local/hermes/fleet/cost_log.jsonl` — per-dispatch cost estimates (NOT `~/.hermes/fleet/` — the actual runtime path is under `~/AppData/Local/hermes/fleet/`)
- `~/AppData/Local/hermes/fleet/audit.jsonl` — per-dispatch decisions (agent_pid, cb_state, duration_ms, success)

**CLI report:** `fleet-manager.py --cost-report` reads cost_log.jsonl and prints per-agent breakdown.

**Wiring in _dispatch_with_fallback:**
Every return path logs via `_log_dispatch_outcome()`:
```python
def _log_dispatch_outcome(self, agent_pid, event_type, response, start_time, pipeline):
    duration_ms = (time.time() - start_time) * 1000
    cb_state = self._get_cb_state(agent_pid)
    cost = estimate_dispatch_cost(agent_pid, duration_ms)
    write_cost_log({"agent_pid": agent_pid, "tokens": cost["tokens"], ...})
    write_audit_log({"trace_id": pipeline.trace_id, "agent_pid": agent_pid, ...})
```

**Pattern:** Called at every `return` in `_dispatch_with_fallback` — primary success, GraSP recovery from CB open, GraSP recovery from primary failure.

**Pitfall — cost log file doesn't exist until first dispatch.** `--cost-report` gracefully says "No cost data recorded yet." Don't create empty files on manager startup.

### Event Sourcing

Immutable JSONL event log of all state transitions. Essential for debugging emergent agent behavior.

```python
# PipelineState stores events in _events buffer (flat dict format)
state.log_event("dispatch", {"from": "astraea_5", "to": "metis_9", "tier": "heavy"})
state.log_event("qa_complete", {"score": 85, "issues": ["missing error handling"]})
state.log_event("ceres_verdict", {"approved": True})
```

**Commit to disk at end of request — no-op if no events:**

```python
def _commit_state(self, pipeline: PipelineState):
    """Write pipeline events to disk as immutable JSONL event log.
    No-op if pipeline has no events.
    """
    if not pipeline or not pipeline.trace_id or not pipeline._events:
        return
    events_dir = FLEET_DIR / "events"  # ~/AppData/Local/hermes/fleet/events/
    events_dir.mkdir(parents=True, exist_ok=True)
    event_file = events_dir / f"{pipeline.trace_id}.jsonl"
    with open(event_file, "a") as f:
        for event in pipeline._events:
            f.write(json.dumps(event) + "\n")
    pipeline._events.clear()
```

The `_commit_state()` method is called alongside `_save_state()` at every return path of `process_request()`.

**Disk usage:** ~100KB/day at 1,000 dispatches. At 100K+/day, add a cron for GC:
```bash
cronjob name="events-gc" schedule="daily" no_agent=True \
  script="find ~/AppData/Local/hermes/fleet/events/ -mtime +7 -delete"
```

**Pitfall:** Events are append-only and immutable by design. Do NOT modify existing events — the value is in the audit trail. If a state transition was wrong, log a NEW event correcting it.

**Wiring — every return path gets _commit_state:**
- Vesta quarantine path in `process_request()`
- Direct pattern handler
- Code pattern handler
- Single worker pattern handler
- Both return paths in `_run_sequential_pipeline()`
- Complex and fallback patterns route through `_run_sequential_pipeline()` which commits

### Provenance Tagging

Galileo: "Hallucinated data in shared state poisons downstream agents." Provenance tagging lets downstream agents weight uncertain outputs lower.

**Pattern:** After a worker agent produces output, check for uncertainty signals in the text. If found, append a `[PROVENANCE: uncertain]` tag. Future agents in the pipeline can parse this tag and respond accordingly.

```python
def _tag_output_provenance(self, response: str, agent_pid: str) -> str:
    if not response:
        return response
    uncertainty_signals = [
        "I think", "probably", "might be", "I'm not sure",
        "could be", "possibly", "I believe", "as far as I know",
        "I'm not certain", "I assume",
    ]
    text_lower = response.lower()
    has_uncertainty = any(sig.lower() in text_lower
                         for sig in uncertainty_signals)
    if has_uncertainty:
        return (response + "\n\n[PROVENANCE: uncertain — "
                "agent expressed doubt]")
    return response
```

**Key implementation detail:** Both the text AND signals are lowercased before comparison. Without this, "I think" (capital I in signal) never matches "i think" (lowercased text), and the tag is silently omitted.

**Known uncertainty signals:**
| Signal | Example | Common agents |
|--------|---------|---------------|
| "I think" | "I think the file is at..." | Search, wiki |
| "probably" | "This probably works" | Code |
| "might be" | "The issue might be..." | Debug analysis |
| "I'm not sure" | "I'm not sure of the location" | DevOps |
| "could be" | "Could be a config issue" | Troubleshooting |
| "I believe" | "I believe it's port 8080" | Any |
| "as far as I know" | "As far as I know, it's safe" | Code review |
| "I assume" | "I assume Python 3.11+" | Code gen |

**Pitfall:** The provenance tag is appended to the agent's text output (the final response), not the internal processing. Downstream agents see it as plain text — they need to be instructed to parse and act on it. This is a soft signal, not a hard gate.

**Wiring — every return path gets _commit_state:**
- Vesta quarantine path in `process_request()`
- Direct pattern handler
- Code pattern handler
- Single worker pattern handler
- Both return paths in `_run_sequential_pipeline()`
- Complex and fallback patterns route through `_run_sequential_pipeline()` which commits

### Graceful Recovery (GraSP)

| Strategy | Action | When | Order |
|----------|--------|------|-------|
| **Rebind** | Same agent, different prompt/args | Agent had a bad first attempt | 2nd |
| **Substitute** | Different agent for same task | Agent has systemic error | 1st |
| **Bypass** | Skip this agent, return partial | Agent not critical to output | 3rd |
| **Escalate** | Full replan via coordinator | All local repairs exhausted | 4th |

**Ordering matters:** If the first dispatch failed with an error signal (Traceback, Exception, timeout), the agent likely has a SYSTEMIC error — retrying (Rebind) wastes time. Try Substitute first. If the first dispatch returned a plausible but wrong answer, Rebind with a different approach might fix it. Heuristic: if failure has error_signal, try Substitute. If failure has no error signal (empty output, wrong format), try Rebind.

**Pitfall:** Not tracking which repair strategy was used. Add a `state.log_event("repair_substitute", {"from": failed, "to": pid})` so you can tune which strategy fires most often in production.

### Task Contracts

Per-agent input/output schemas are the single highest-ROI reliability measure (LinkedIn Playbook, Galileo: **42% of failures = specification failures**).

### Required Fields per Agent

```json
{
  "agent_pid": {
    "display_name": "Agent-X",       # Human-readable name for logs
    "role": "One-line role description",
    "input_schema": {"type": "string", "description": "What this agent expects"},
    "output_schema": {"type": "string", "format": "expected output format"},
    "max_turns": 5-8,                # CrewAI: default 25 is a cost trap
    "allowed_tools": [],             # Tool gateway enforcement
    "quality_constraints": {},       # Non-empty, no error signals, no roleplay
    "cost_tier": "fast|heavy|guardrail",
    "privilege_level": 0-4           # Maps to L0-L4 governance ring
  }
}
```

### Specification Validation

Before routing to an agent, validate that the task is specific enough. Galileo: **42% of failures happen because tasks are vague.**

```python
TASK_SPEC_PROMPT = """Rate the task specificity from 1-5:
1 = Completely vague ("help me", "do something")
2 = General topic but no action ("tell me about AI")
3 = Clear topic + action, missing details ("write code for a website")
4 = Specific action + subject ("write a Python script to rename .txt to .md")
5 = Fully specified with context ("write a Python script to rename all .txt files
    in Downloads/ to .md, handle errors, use pathlib")

If rating < 3, respond with: NEEDS_SPECIFICATION: <one sentence what's missing>
If rating >= 3, respond with: READY: <category from routing>

Task: {user_input}
Result:"""

def _validate_task_spec(user_input: str, pattern: str) -> tuple:
    """Validate task specificity. Returns (is_valid, message_or_category)."""
    if pattern == "direct":
        return (True, pattern)  # greetings don't need validation
    
    # Heuristic: short tasks for known patterns don't need LLM validation
    if len(user_input) < 15 and pattern in ("devops", "direct"):
        return (True, pattern)  # "check disk" = valid
    
    # LLM validation for ambiguous cases
    response = await llm_route(TASK_SPEC_PROMPT.format(user_input=user_input))
    if response and response.startswith("NEEDS_SPECIFICATION"):
        return (False, response)
    return (True, response.split(":")[1].strip().lower() if response else pattern)
```

**Timeout tuning pitfall — LLM routing and spec validation calls need 30s, not 15s:**
The first subprocess-based dispatch to any agent includes Hermes CLI startup time (5-15s). Using `asyncio.wait_for(dispatch_to_agent(...), timeout=15.0)` will time out on the first call because the agent hasn't started yet. Use 30s for the first dispatch to any agent, or warm agents up before the routing call.

**Pitfall:** Short single-word tasks ("disk space") are terse but perfectly valid for devops agents. The heuristic excludes tasks with length < 15 AND devops/direct patterns. Monitor for false positives — if the model rejects a valid task, add its pattern to the exclusion list.

### Phase Transition Discipline

**Hard rule: complete ALL items in a phase before advancing to the next.** Do not skip "low-ROI" or "polish" items — the user may value completeness differently than you estimate. This rule exists because the user corrected this behavior mid-session (June 2026): "just finish phase 3 first" was the response to suggesting Phase 3 items were too low-value to complete.

**Rationale:**
- Incomplete phases produce a fragmented codebase — half-migrated patterns, orphaned comments, dead code paths
- The user's mental model is phase-gated. Incomplete phases erode trust in the plan's fidelity
- "Low-ROI" items often block downstream work. Event GC was deferred because no event files existed yet — that's a valid deferral. But leaving `unused_import` warnings or half-documented methods is not a valid deferral
- The user prefers to finish what's started. Estimating correctly (vs. skipping) is the right fix

**When to skip:**
- The item is genuinely blocked by an external dependency (e.g., "waiting for provider docs")
- The deferred item won't compound — it's cleanly separable and won't be harder to add later
- The user explicitly agrees to defer. Never defer without a conversation

### Design Methodology

#### Phase Sequence for Fleet Architecture

| Step | Activity | Sources |
|------|----------|---------|
| 0 | Audit current state via capability coverage matrix | All sources |
| 1 | Research relevant sources for optimal topology | arXiv, production reports |
| 2 | Identify gaps: missing agents, patterns, subsystems | Cross-source comparison |
| 3 | Design target architecture with phase plan | This skill + `plan` skill |
| 4 | Add distributed systems safeguards | Circuit breakers, bulkheads, tracing |
| 5 | Iterate: research deeper, find more gaps, revise plan | Multi-pass methodology |
| 6 | E2E test all patterns against new architecture | verification commands |

### Phase 0 Pre-Flight Protocol — Before You Touch a Running System

Before executing ANY architecture plan against a live fleet, run this 5-step pre-flight. These are non-destructive and safe to run alongside production operations.

| # | Step | Action | Done Signal |
|---|------|--------|-------------|
1. **Snapshot existing state** — Backup every critical file (fleet-manager.py under `~/AppData/Local/hermes/scripts/`, fleet state/cost/audit files under `~/AppData/Local/hermes/fleet/`, profile configs under `~/AppData/Local/hermes/profiles/`). Run `--status` to capture baseline health. | All backups verified extant; fleet health baseline captured |
| 0b | **Inventory current profiles** | List profile directories (`ls profiles/`), check SOUL.md existence per profile, list cron jobs, list scripts. Note which planned agents already exist vs. need creation. | Complete profile manifest with readiness status per planned agent |
| 0c | **Create or audit Task Contract registry** | Ensure `task_contracts.json` exists at `~/.hermes/fleet/` with input/output schemas, allowed_tools, max_turns, quality_constraints, cost_tier, and privilege_level per agent. If it doesn't exist, create it from scratch using the template. | Validated JSON registry with all current + planned agents |
| 0d | **OWASP AST10 security audit** | For each agent, validate that its `allowed_tools` list is minimal (order-of-magnitude rule: no tool the agent doesn't use 80%+ of the time). Map each OWASP risk category (SK-01 through SK-10) to its mitigation. Document accepted risks. | Per-agent allowlist audit passed; deferred risks documented with rationale |
| 0e | **Document change procedures** | Write agent-factory workflow (how to add a new agent), rollback procedure (how to revert a phase), and any maintenance-mode protocol. Any dispatched agent should be able to follow these without asking. | Change procedure documents exist and are self-contained |

**Why this matters (proven in production):** This pattern caught that `~/AppData/Local/hermes/fleet/` didn't exist yet (it's where the contract registry goes), that cron jobs had undetected errors, that planned agents didn't have profiles yet, and that the existing fleet was healthy with 0 quarantines. Without the pre-flight, implementation starts against unknown state.

**When to skip:** Only skip steps 0a-0b when the fleet was JUST deployed (no state worth snapshotting). Never skip 0c-0e — the contract registry and agent-factory workflow are required even for a greenfield fleet.

## Phase 2 Implementation Patterns — Profile Creation

This section documents the exact profile creation workflow used to deploy Atalanta-36 (DevOps) and Kalliope-22 (Content) during Phase 2 (June 2026).

### The Profile Creation Workflow

**Note:** This section documents the *specific instance* of creating Atalanta-36 and Kalliope-22. For the *general method* of deploying profiles from wiki manifests, see the `hermes-fleet-profiles` skill and its `references/task-first-profile-template.md`.

```
Step 1: hermes profile create <name> --clone-from default
Step 2: Write task-first SOUL.md (overwrite default clone)
Step 3: Set model.default, model.provider, model.context_length, agent.max_turns
Step 4: Set terminal.cwd (per-role workspace)
Step 5: Add V5 JSON entry (fleet-manager loads profiles from V5 JSON)
Step 6: Remove "profile_needed: true" from task_contracts.json
Step 7: Verify: fleet-manager.py --status shows new agent
```

### Profile Creation Checklist

| # | Step | Command | Done Signal |
|---|------|---------|-------------|
| 1 | Create profile | `hermes profile create <name> --clone-from default` | "Profile '<name>' created" with .bat wrapper |
| 2 | Overwrite SOUL.md | `write_file('profiles/<name>/SOUL.md', ...)` with task-first format | Profile launch shows new welcome/behavior |
| 3 | Set model | `hermes --profile <name> config set model.default <model>` | `hermes profile show <name>` shows correct model |
| 4 | Set provider | `hermes --profile <name> config set model.provider nous` | Provider shows in profile show |
| 5 | Set context | `hermes --profile <name> config set model.context_length 64000` | Context shows 64K (floor, even if V5 spec is lower) |
| 6 | Set max_turns | `hermes --profile <name> config set agent.max_turns <N>` | Standalone max_turns (can be > dispatch max_turns) |
| 7 | Set cwd | `hermes --profile <name> config set terminal.cwd "C:\\path\\to\\workspace"` | `config show` shows correct cwd |
| 8 | Add V5 JSON entry | Patch `raw/hermes_agent_profiles_v5.json` with full profile block | Fleet-manager loads new profile |
| 9 | Remove profile_needed flag | Patch `task_contracts.json` — remove `"profile_needed": true` | No stale flags in registry |
| 10 | Verify | `python fleet-manager.py --status` | New agent shows in status table |

### Profile Configs Deployed (Phase 2)

| Field | Atalanta-36 (DevOps) | Kalliope-22 (Content) |
|-------|---------------------|----------------------|
| Model | google/gemini-2.5-flash | deepseek/deepseek-v4-flash |
| Provider | nous | nous |
| Context | 64K (floored from 4K V5 spec) | 64K (floored from 32K V5 spec) |
| Standalone max_turns | 20 | 25 |
| Dispatch tier | TIER_8 (max_turns=8) | TIER_1 (max_turns=1) |
| Dispatch timeout | 180s | 90s |
| terminal.cwd | ~/AppData/Local/hermes\AppData\Local\hermes | ~/AppData/Local/hermes |

**Design rationale for tier assignment:**
- **Atalanta TIER_8** (execution level): DevOps tasks require multi-step reasoning — check state, plan change, execute, verify. 8 turns gives room for tool calls.
- **Kalliope TIER_1** (light dispatch): Content tasks are generation-only — the model writes in one shot. If it needs reference material, it has 1 turn for read_file. Any revision comes from a separate dispatch.

### Task-First SOUL.md Templates for Phase 2

**DevOps (Atalanta-36):**
```
[ROLE]: DevOps specialist. Manage infrastructure, cron jobs, config, deployments, server health, backups, and system monitoring.

[BEHAVIOR]:
  - Read the full context before executing any infrastructure change
  - Check current state before making changes — verify, then act
  - Report status changes clearly: what changed, what stayed, any errors

[OUTPUT]: Bullet-point status report or change confirmation. Include error details if something failed.

[RULES]:
  - No preamble. No roleplay. No self-introduction.
  - Verify before destructive actions. Check process state before restarting.
  - If a command fails, report the error and suggest a fix — don't silently retry forever.

[SKILLS]: Load fleet-health-watchdog for fleet monitoring. Load hermes-cron-operations for cron job management. Load wiki-operations for backup verification.
[PERSONALITY]: Methodical, reliable, operations-first. Prefers verified state over assumptions.
```

**Content (Kalliope-22):**
```
[ROLE]: Content specialist. Write docs, blog posts, release notes, wiki pages, architecture decisions, and polished copy.

[BEHAVIOR]:
  - Read the full request and any reference material before writing
  - Match the requested tone (technical, casual, formal, persuasive)
  - Deliver well-structured markdown with clear headings, concise prose

[OUTPUT]: Clean markdown. Ready for review or publication.

[RULES]:
  - No preamble. No theatrical framing. No self-introduction.
  - Start writing. The output IS the content.
  - If a format is specified (RFC, ADR, blog, release notes), follow it exactly.

[SKILLS]: Load design-md for structured documentation format specs. Load document-verification-update for auditing reference docs.
[PERSONALITY]: Clear, articulate, adaptable. Professional prose without pretense.
```

### Critical Learnings from Phase 2

1. **V5 JSON is required for fleet-manager loading.** The fleet-manager's `_load_profiles()` reads from `raw/hermes_agent_profiles_v5.json`. Adding entries to PROFILE_MAP and TIER sets is necessary but NOT sufficient — without V5 JSON entries, agents show in PROFILE_MAP but not in the runtime agent list. **Fix:** Add full V5 JSON entries (system_prompt, generation_config, fallback, pub/sub) before running fleet status.

2. **Profile creation is fast but SOUL.md overwrite is critical.** `hermes profile create --clone-from default` copies the default profile's SOUL.md verbatim. If you don't overwrite it, the new profile inherits the default persona. **Always overwrite SOUL.md immediately after creation.**

3. **Context length floor is 64K.** Hermes Agent refuses to initialize profiles with context below 64K. The V5 spec may say 4K (Atalanta) or 32K (Kalliope) — deploy at 64K regardless. The tier differentiation comes from model selection, not context window.

4. **Model tiering:** Gemini-2.5-flash for fast/ops agents (Atalanta, search, routing, design). DeepSeek V4 Flash for heavy/reasoning/generative agents (Kalliope, Ceres, Nemesis, Metis, Fortuna). This is consistent with the existing deployed fleet config.

5. **Entity pages should be created** to document new agents. The wiki entity pages serve as canonical documentation for system prompts, routing rules, contracts, and file locations.

6. **terminal.cwd matters for worker context.** DevOps agents should start in the Hermes infrastructure directory. Content agents start in home. Without explicit cwd, they start wherever the launcher ran from — unpredictable.

7. **[SKILLS] sections in SOUL.md wire role-specific procedural knowledge.** Agents don't automatically know which skills to load — they need explicit instruction. Add a `[SKILLS]` line between [RULES] and [PERSONALITY] listing the skills the agent should load and why. This tells the agent's persona to `skill_view()` the relevant skill at startup. Gate agents (pure reasoners with no tools) don't need skills. See `references/profile-skill-loading.md` for the full per-role mapping.

### Phase 2 Verification

```bash
# Check profiles exist and have correct model config
hermes profile show <name>  # Should show correct model/provider

# Smoke test
hermes -p <name> chat -q "Quick status check" -Q --max-turns 0
# Should respond without timeout. Ignore "Reached maximum iterations" CLI artifact.

# Fleet loading
cd ~/AppData/Local/hermes/scripts && python fleet-manager.py --status
# Should show new agent in table with correct tier and 0/0 S/F

# Verify contract
# Should be 0 — all profile_needed flags removed after creation

---

## Phase 3 Implementation Patterns

This section documents the observability layer deployed during Phase 3 (June 2026): typed pipeline state and on-demand fleet health checks.

### PipelineState — Typed Request State

**Problem:** The pipeline passed bare strings between stages (`process_request` → `_route_to_worker` → `dispatch_to_agent`). There was no typed object threading trace_id, timing, or stage-by-stage outcomes through the pipeline. Debugging multi-stage requests required reading log lines scattered across methods.

**Solution — PipelineState dataclass:**

```python
@dataclass
class PipelineState:
    """Typed state for a single request pipeline execution."""
    request_id: str = ""
    trace_id: str = ""
    user_input: str = ""
    vesta_response: str = ""
    vesta_passed: bool = False
    cleaned_input: str = ""
    pattern: str = ""
    astraea_plan: str = ""
    worker_pid: str = ""
    worker_response: str = ""
    evaluations: list = field(default_factory=list)
    ceres_response: str = ""
    ceres_approved: bool = False
    final_output: str = ""
    error: str = ""
    start_time: float = 0.0
    end_time: float = 0.0
    halted: bool = False
    _events: list = field(default_factory=list)

    def __post_init__(self):
        if not self.request_id:
            self.request_id = uuid.uuid4().hex[:12]
        if not self.trace_id:
            self.trace_id = self.request_id

    @property
    def duration_ms(self) -> float:
        if self.start_time and self.end_time:
            return (self.end_time - self.start_time) * 1000
        return 0.0

    def log_event(self, event_type: str, payload: dict = None):
        """Append an event to the in-memory buffer with flat dict format.

        Events use flat keys (type, ts, stage) merged with payload — no
        nested 'payload' layer. This is the format consumed by _commit_state()
        for disk persistence. Events are cleared from memory after commit.
        """
        self._events.append({
            "type": event_type,
            "trace_id": self.trace_id,
            "ts": time.time(),
            "stage": "pipeline",
            **(payload or {}),
        })
        log.debug(f"  📝 [{self.trace_id}] {event_type}: ...")
```

**Why not full migration?** PipelineState is introduced incrementally. Stage 1: the dataclass exists, `process_request` initializes it with trace_id, and `log_event()` is wired. Stage 2 (post-Phase 3): migrate `_route_to_worker`, `_dispatch_with_fallback`, and `_run_qa_gates` to accept and return PipelineState instead of bare strings.

**Key design decision:** `__post_init__` auto-generates trace_id if not provided. This means any code creating a PipelineState gets a trace_id for free — no forgetting to set it.

### On-Demand Fleet Health (`--health`)

**Problem:** The observability cron provides backward-looking trend data (was the fleet healthy 2 hours ago?). There was no way to answer "is the fleet healthy right now?" Acute problems (provider outage, profile silently crashed) went undetected until a dispatch failed.

**Solution — `fleet_health_snapshot()` method:**

```python
async def fleet_health_snapshot(self) -> dict:
    """On-demand fleet health snapshot — checks all agents are responsive."""
    checks = {
        "profiles_loaded": len(self.profiles),
        "state_file_ok": STATE_FILE.exists(),
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%S"),
        "circuit_breakers": {},
        "agents_responsive": {},
        "cost": {"avg_cost_per_dispatch": 0, "total_recent_100": 0},
    }

    for pid, profile in self.profiles.items():
        try:
            start = time.time()
            response = await asyncio.wait_for(
                self.dispatch_to_agent(profile, FleetEvent(
                    type="ping",
                    payload={"source": "health-check"},
                    source="fleet_health",
                )),
                timeout=15.0,
            )
            latency = int((time.time() - start) * 1000)
            is_pong = response and "PONG" in response.upper()
            checks["agents_responsive"][pid] = {
                "status": "ok" if is_pong else "unexpected_response",
                "latency_ms": latency,
            }
        except asyncio.TimeoutError:
            checks["agents_responsive"][pid] = {
                "status": "timeout", "latency_ms": 15000,
                "error": "No response within 15s",
            }
        except Exception as e:
            checks["agents_responsive"][pid] = {
                "status": "error", "error": str(e)[:80],
            }
    return checks
```

**CLI entry:**
```bash
python fleet-manager.py --health
# 🩺 Running fleet health check...
# {
#   "profiles_loaded": 12,
#   "state_file_ok": true,
#   "timestamp": "2026-06-24T05:35:00",
#   "agents_responsive": {
#     "metis_9": {"status": "ok", "latency_ms": 2341},
#     "vesta_4": {"status": "ok", "latency_ms": 512},
#     "atalanta_36": {"status": "timeout", "error": "..."}
#   }
# }
```

**Ping prompt template** (added to `_build_prompt`):
```python
"ping": f"A fleet health check has arrived.\n\nRespond with exactly: PONG. Your current status is OK.\nImmediately respond with PONG. No reasoning, no explanation, no tools needed.",
```

**Key design decisions:**
1. **15s timeout per agent** — long enough for Hermes CLI startup (~5-15s), short enough to not hang indefinitely
2. **PONG validation** — agents must respond with "PONG" to be considered healthy. Any other response is flagged as `unexpected_response`
3. **Sequential pings** — 12 agents × 15s = 30-60s total. Acceptable for on-demand (only run when you suspect a problem). Not suitable for cron intervals
4. **Cost tracking is a placeholder** — current fleet-state.json doesn't store per-dispatch costs. Phase 4 should add cost tracking to the state schema
5. **Circuit breaker state is a placeholder** — not yet stored in fleet-state.json

### Remaining Phase 3 Items (Deferred)

| Item | Reason Deferred | Future Phase |
|------|----------------|--------------|
| **Structured logging** (log levels per agent tier) | Requires logging middleware, not just format changes | 3b |
# Should be 0 — all profile_needed flags removed after creation

---

## Phase 3 Implementation Patterns

This section documents the exact implementation patterns deployed during the fleet overhaul (June 2026, Phases 0-1). Use these as templates when implementing or modifying `fleet-manager.py` patterns.

### The Implementation Order That Worked

| Step | What | Why in This Order |
|------|------|------------------|
| 1a | Add `import uuid` at top of fleet-manager.py | Needed for trace_ids before any dispatch code |
| 1b | Create `task_contracts.json` at `~/.hermes/fleet/` | Registry must exist before code reads it |
| 1c | Add contract registry loading (`CONTRACT_PATH`, `json.load`, fallback dict) | Replaces hardcoded config |
| 1d | Drive `PROFILE_MAP` from contracts + lookup dict | Keeps Python-to-Hermes-profile mapping but removes agent-per-agent typing |
| 1e | Update `TIER_*_AGENTS` sets | After contract loading exists, add new agents (atalanta, kalliope) |
| 1f | Rename `_classify_task()` → `_classify_task_keyword()` | Non-breaking rename — no callers update needed |
| 1g | Add `_llm_classify_task()` method | New LLM routing with keyword fallback |
| 1h | Wire LLM routing in `_route_to_worker()` | `await self._llm_classify_task(clean_input)` at the "auto" pattern branch |
| 1i | Add trace_id to `_orchestrate()` | UUID seeded at request entry, logged in header |
| 1j | Add "devops" + "content" to single-worker patterns | Without this, new routes would never match |
| 1k | Add keyword matching for devops and content in `_classify_task_keyword` | Keywords before the "complex" catch-all so they get routed correctly |
| 1l | Add `_validate_task_spec()`, `_check_context_budget()`, contract validation | Policy methods wired after routing is solid |
| 1m | Expand `PEER_REVIEW_MAP`, fix content routing bug | Final cleanup — this revealed a pre-existing bug |

**Key insight:** Add the data structures FIRST (contract file, imports, TIER sets), then the routing changes, then the policy methods. If you do policy before routing, smoke tests fail because routing isn't ready yet.

### Exact LLM Routing Prompt

This is the actual prompt sent to Astraea-5 for task classification. **Do not change the category names** — they match the routing blocks in `_route_to_worker()`:

```python
LLM_CLASSIFY_PROMPT = """
You are a task classifier for a fleet of specialized AI agents.
Classify the following user request into exactly ONE category.

Categories:
- direct: Greetings, simple questions, status checks, config changes, coordination. Handled by the coordinator directly.
- code: Writing, reviewing, debugging, or modifying code. Python, JavaScript, config files, SQL queries.
- wiki: Reading, writing, searching, or organizing wiki content. Knowledge base operations.
- search: Web research, finding information, looking up facts, current events.
- data: Data analysis, statistics, metrics, visualization, number crunching.
- design: UI design, visual mockups, image generation, layout.
- devops: Infrastructure, deployment, system administration, terminal operations, disk checks.
- content: Writing, copywriting, documentation, drafting, content strategy.
- complex: Multi-step tasks that need decomposition into sub-tasks. Set up, deploy, create project, build, migrate, plan, design a system, architect.

Respond with ONLY the category name. Example: search
If you are unsure, choose "complex".

Task: {task}
Category:
"""
```

**Timeout:** `asyncio.wait_for()` at **60s** (not 30s). The initial 30s timeout failed because subprocess dispatch to Astraea needs time to spin up the hermes profile. **Pitfall:** Every new async dispatch to a Hermes profile has a ~15-45s spin-up cost on first call. Account for this when setting timeouts in new methods.

**Post-processing:**
```python
response = response.strip().lower()
if response not in ALL_PATTERNS:
    log.warning(f"LLM returned unknown pattern '{response}', falling back to keyword")
    return self._classify_task_keyword(user_input)
return response
```

**Fallback chain:** LLM → keyword → "complex" (default). The LLM can return any string; the `ALL_PATTERNS` guard catches garbage.

### Exact Spec Validation Prompt

```python
TASK_SPEC_PROMPT = """Rate the task specificity from 1-5:
1 = Completely vague ("help me", "do something")
2 = General topic but no action ("tell me about AI")
3 = Clear topic + action, missing details ("write code for a website")
4 = Specific action + subject ("write a Python script to rename .txt to .md")
5 = Fully specified with context ("write a Python script to rename all .txt files \
    in Downloads/ to .md, handle errors, use pathlib")

If rating < 3, respond with: NEEDS_SPECIFICATION: <one sentence what's missing>
If rating >= 3, respond with the task category name.

Task: {user_input}
Result:"""
```

**Heuristic skip:** Tasks shorter than 15 characters for `devops` and `direct` patterns skip LLM validation entirely. `_validate_task_spec("disk space", "devops")` → `(True, "devops")` without an API call. Rationale: short DevOps commands ("df -h", "disk space", "check memory") are terse but perfectly valid. Running LLM validation on them wastes tokens and time.

### Trace ID Implementation

```python
import uuid

# In _orchestrate(), before any dispatch:
trace_id = uuid.uuid4().hex[:12]  # 12 hex chars = 2.8e14 unique IDs
log.info(f"\n{'='*60}")
log.info(f"FLEET REQUEST #{self.state.total_requests}: {user_input[:100]}")
log.info(f"🔍 [{trace_id}] Trace ID")
log.info(f"{'='*60}")

# Thread through PipelineState — add to FleetEvent payload:
class FleetEvent:
    def __init__(self, type, payload, source="unknown"):
        self.type = type
        self.payload = payload
        self.source = source
        # trace_id is set by the dispatcher, not the event creator
```

**Where trace_id does NOT go:** It's NOT in the FleetEvent constructor — it's set by the dispatcher after creating the event. This keeps event creation stateless (called by routing methods) but dispatch contextual.

### Context Budget (Max Concurrent Workers)

```python
_context_semaphore = asyncio.Semaphore(3)  # Max 3 concurrent workers
_worker_contexts: Dict[str, int] = {}      # Active worker counts per agent_id

async def _check_context_budget(self, worker_profile_id: str) -> bool:
    """Check if we can dispatch another worker within budget. Returns False if over limit."""
    current = self._worker_contexts.get(worker_profile_id, 0)
    log.debug(f"  Context budget: {worker_profile_id} has {current} active calls")
    return current < 5  # Per-agent burst of 5, with total cap via semaphore
```

**Two-layer enforcement:**
- **Global semaphore** (Semaphore(3)) — prevents >3 workers running simultaneously
- **Per-agent counter** (5 max) — prevents one agent type from queuing up
- Both must pass before dispatch proceeds

### Contract Validation in dispatch_to_agent

```python
# In dispatch_to_agent(), after profile lookup and before subprocess call:

# Contract validation: enforce max_turns and tool allowlist from registry
contract = TASK_CONTRACTS.get(profile.pid)
if contract:
    if contract.get("max_turns", 5) < event.payload.get("expected_turns", 1):
        log.warning(f"  ⚠️  [{trace_id}] Task expected {event.payload.get('expected_turns')} "
                    f"turns but {profile.pid} max_turns={contract.get('max_turns')}")
    
    # Log tool allowlist for audit
    allowed = contract.get("allowed_tools", [])
    if allowed:
        log.info(f"  🛠️  [{trace_id}] {profile.pid} tools allowed: {', '.join(allowed[:4])}" 
                 f"{'...' if len(allowed) > 4 else ''}")
    else:
        log.warning(f"  ⚠️  [{trace_id}] {profile.pid} has 0 allowed tools — "
                    f"effective deny-all. Check task_contracts.json")
```

**Pitfall:** 5 of 11 agents have 0 allowed tools in the initial contract registry. This means their dispatch succeeds but the agent can't use any tools — it's a deny-all configuration. This is acceptable for gate agents (Nemesis, Ceres, Vesta are pure reasoners) but suspect for workers. Triple-check the allowed_tools field for every agent during contract creation.

### Content Routing Bug — Valuable Pitfall

**The bug:** The original `_route_to_worker()` had this:

```python
# 8. Content → Kalliope-22
if is_content or plan_says_content:
    log.info("  → Routing to Fortuna-19 (data)")  # ← WRONG agent name in log
    return await self._dispatch_with_fallback(
        "fortuna_19", user_input, trace_id,
        data_analysis_requested=True,  # ← WRONG: content is not data analysis
    )
```

**What was wrong:**
1. The comment said "Content" but routed to Fortuna-19 (data analysis agent)
2. The worker destination was Fortuna-19, not Kalliope-22
3. The parameter `data_analysis_requested=True` was a data-analysis parameter, not a content parameter
4. This was a dead code path — no Kalliope-22 profile existed yet, but if one existed, content tasks would still be routed incorrectly to data analysis

**Fix:**
```python
# 8. Content → Kalliope-22
if is_content or plan_says_content:
    log.info("  → Routing to Kalliope-22 (content)")
    return await self._dispatch_with_fallback(
        "kalliope_22", user_input, trace_id,
    )
```

**Root cause:** Someone (likely the original plan author) wrote a content routing block but hadn't created Kalliope-22 yet, so used Fortuna-19 as a placeholder and never corrected it. The code was never testable because the profile didn't exist. **Lesson:** Any routing block for an agent that doesn't exist yet is a liability. Either create the profile first, or add a `if pid in self.profiles:` guard so the block is inert until the profile exists.

**Lesson for multi-agent architecture:** Dead code paths like this are invisible until you run E2E tests against the actual profiles. Smoke-test every routing branch with a real agent, even if the agent is a minimal stub.

### DevOps and Content Keyword Patterns

Added to `_classify_task_keyword()` — must be placed BEFORE the "complex" catch-all keywords to intercept correctly:

```python
# DevOps — needs Atalanta-36 (fast, system-level)
if any(kw in text for kw in [
    "disk", "memory", "cpu", "process", "service", "install",
    "deploy", "server", "terminal", "run", "command",
    "config", "backup", "cron", "check",
]):
    return "devops"

# Content — needs Kalliope-22 (writing, documentation)
if any(kw in text for kw in [
    "write", "draft", "document", "content", "copy",
    "readme", "description", "announcement", "post",
]):
    return "content"
```

**Ordering is critical** — these go BEFORE the "complex" keyword block. If they're after, "deploy" gets classified as complex (needing Astraea decomposition) when it's actually a straightforward DevOps task.

### Peer Review Map Expansion

```python
PEER_REVIEW_MAP = {
    "metis_9": "nemesis_128",    # Code → QA evaluation
    "artemis_105": "klio_84",    # Search → wiki fact-check
    "klio_84": "fortuna_19",     # Wiki → data cross-check
    "fortuna_19": "nemesis_128", # Data → QA evaluation
    "harmonia_40": "nemesis_128",# Design → QA evaluation
    "atalanta_36": "nemesis_128",# DevOps → QA evaluation
    "kalliope_22": "nemesis_128",# Content → QA evaluation
    "ceres_1": None,             # Final gate — no further review
    "nemesis_128": None,         # QA evaluator — not reviewed
    "vesta_4": None,             # Security gate — not reviewed
    "astraea_5": None,           # Router — not reviewed
}
```

**Pattern:** Three agents review through Klio/Fortuna (domain-specific cross-check). All others review through Nemesis (generic QA). The `None` entries explicitly prevent gate-on-gate recursion.

### _needs_qa() Expansion

```python
def _needs_qa(self, worker_pid: str, request_pattern: str) -> Optional[str]:
    """Check if a worker's output needs structured QA.

    Returns the peer reviewer's profile_id, or None if no gate needed.
    """
    # Always gate code, data, design — safety critical
    if worker_pid in ("metis_9", "fortuna_19", "harmonia_40"):
        return "nemesis_128"

    # Gate content and devops only on 'complex' pattern
    if worker_pid in ("atalanta_36", "kalliope_22"):
        if request_pattern == "complex":
            return "nemesis_128"
        return None

    # Gate search through wiki fact-check (cheaper than Nemesis)
    if worker_pid == "artemis_105":
        return "klio_84"

    # Gate wiki through data cross-check
    if worker_pid == "klio_84":
        return "fortuna_19"

    return None
```

**Design rationale:** Content and DevOps are "fast" tier agents — gating every dispatch adds 60-120s for no benefit on trivial tasks. Only gate when the request was tagged as "complex" (multi-step, high impact).

### Architecture Audit — Capability Coverage Matrix

**Method:**

1. **List every source's requirements** — extract all specific capability claims from research (e.g., "must have circuit breakers," "should have 2-3 evaluators")
2. **Map each to current agents/patterns** — which agent or subsystem satisfies each requirement?
3. **Classify each** as: ✅ covered, 🟡 in-progress (Phase N), ❌ missing
4. **Count the gaps** — how many missing vs total? If >10% of research-backed capabilities are missing, the architecture is incomplete.
5. **Group gaps by priority:**
   - **P0 — Must add:** required by multiple sources, or single source with high impact (circuit breakers, spec validation, observability)
   - **P1 — Should add:** required by one source with moderate impact (consensus debate, privilege rings)
   - **P2 — Deferred:** acknowledged but deferred (MCP/A2A, sandboxing, full OWASP compliance). Sandbox trigger: Hermes Agent adds `HERMES_SANDBOX_DIR` env var support to write_file/patch tools.

**Example output:**
```
Capabilities audited: 59 (from 16 sources)
  ✅ Covered: 23
  🟡 In progress: 29
  ❌ Missing: 7
     → P0: multiple_evaluators (Galileo), owasp_ast10 (MLflow)
     → P2: mcp_a2a, privilege_rings, sandboxing (all deferred)
```

**Where to document:** Save the matrix as `references/capability-audit-YYYY-MM-DD.md` for future reference.

**Pitfall:** A "covered" capability may be covered by the plan but not yet implemented (in-progress). Note the phase number. A gap between planned and deployed is a risk, not a success.

### Governance & Security Patterns

#### OWASP AST10 Audit Methodology

MLflow (2026): OWASP Agentic Skills Top 10 (AST10) review is a baseline production requirement. Every agent with tool access introduces attack surface at the skill boundary.

**Audit process:**

1. **For each agent, catalog its `allowed_tools`** against the Tool Gateway allowlist.
2. **Map each risk category** to its mitigation:
   - SK-01 (Unrestricted Tool Access) → Tool Gateway per-agent allowlist
   - SK-02 (Tool Supply Chain) → Only built-in Hermes tools
   - SK-03 (Runtime Isolation) → Per-dispatch sandbox OR accept risk for single-user
   - SK-05 (Prompt Injection via Tools) → Security gate sanitizes input
   - SK-08 (Credential Leakage) → Tool gateway blocks unauthorized reads
   - SK-09 (Privilege Escalation) → Privilege levels + human-in-loop gate
3. **For each risk without mitigation:** document the accepted risk and why (e.g., "single-user fleet, blast radius small")
4. **Apply the order-of-magnitude rule:** if an agent has a tool it doesn't use 80% of the time, remove it.

**Pitfall:** Don't skip SK-03 (runtime isolation) for production fleets. If agents serve multiple users or access sensitive data, sandboxing is mandatory.

#### Privilege Levels (AGT-Light)

Microsoft Agent Governance Toolkit defines deterministic privilege rings. For small-to-medium fleets, a lighter equivalent using 5 levels (L0-L4) in Task Contracts, enforced by the Tool Gateway.

| Level | Name | Capabilities | Example Agents |
|-------|------|-------------|----------------|
| L0 | None | No tools (pure reasoner) | QA gates, evaluators |
| L1 | Read | Read files, search, web | Search, wiki agents |
| L2 | Standard | Read + write files, patch | Code, content, design agents |
| L3 | Power | Read/write + exec terminal, process | DevOps, data analysis |
| L4 | Admin | All tools incl. destructive ops | Routing, security, coordinator |

**Implementation:**

```python
PRIVILEGE_MAP = {
    "atalanta_36": 3, "metis_9": 2, "artemis_105": 1,
    "nemesis_128": 0, "ceres_1": 0, "vesta_4": 4,
}

LEVEL_TOOLS = {
    0: [],
    1: ["read_file", "search_files", "web_search", "web_extract"],
    2: [*LEVEL_TOOLS[1], "write_file", "patch"],
    3: [*LEVEL_TOOLS[2], "terminal", "execute_code", "process"],
    4: [*LEVEL_TOOLS[3], "write_file", "patch", "delete", "skill_*"],
}

# In Tool Gateway _validate_tool_call():
agent_level = PRIVILEGE_MAP.get(agent_pid, 0)
required_level = next(level for level, tools in sorted(LEVEL_TOOLS.items())
                      if tool_name in tools)
if agent_level < required_level:
    log.warning(f"🚫 [{trace_id}] Privilege violation: {agent_pid} L{agent_level}" 
                f" tried {tool_name} (requires L{required_level})")
    return False
```

**Why this matters:** RBAC-style privilege model scales with fleet size. Adding a new agent means assigning one level in one place — not editing per-tool configs. Kubernetes RBAC, AWS IAM, and AGT all use this model.

**Pitfall:** Don't mix privilege-level enforcement with tool-allowlist enforcement. The level is a BOUND on capability (an L2 agent cannot exec terminal, period). The allowlist is a PRECISE restriction (this L2 agent may use write_file but not patch). Both checks fire independently in the gateway.

#### Per-Dispatch Working Directory Sandbox

A tool gateway that restricts *which* tools an agent can use doesn't restrict *where* they write. The sandbox pattern redirects all write operations to a per-dispatch temp directory. Output only reaches the real filesystem after QA gate approval.

```python
import shutil
from pathlib import Path

def _create_sandbox(trace_id: str) -> Path:
    """Create a per-dispatch sandbox directory."""
    sandbox = Path.home() / "AppData/Local/hermes/sandbox" / trace_id
    sandbox.mkdir(parents=True, exist_ok=True)
    return sandbox

def _sandbox_path(real_path: str, sandbox: Path) -> str:
    """Rewrite write-target path to sandbox directory."""
    return str(sandbox / Path(real_path).name)

# In Tool Gateway — intercept write operations:
WRITE_TOOLS = ["write_file", "patch"]
if tool_name in WRITE_TOOLS and state.sandbox_path:
    params["path"] = _sandbox_path(params["path"], Path(state.sandbox_path))

# After gates approve — promote output from sandbox to real path:
if state.sandbox_path and state.approved_output_file:
    sandbox_file = Path(state.sandbox_path) / Path(state.approved_output_file).name
    real_file = Path(state.approved_output_file)
    if sandbox_file.exists():
        shutil.copy2(sandbox_file, real_file)

# Cleanup in finally block:
if state.sandbox_path:
    shutil.rmtree(Path(state.sandbox_path))
```

**Design rationale:**
- Only write operations are sandboxed. Read operations pass normally (agents need context).
- Output promotion happens only after gate approval. The sandbox acts as a staging area.
- Cleanup is automatic: after promotion (success) or without promotion (failure).
- Agents are unaware of sandboxing — no behavioral changes needed.

**Pitfall:** Forgetting to call `_create_sandbox()` before the first write. Always call it in `dispatch_to_agent()` before dispatching, not when the first tool call arrives.

#### A2A-Compatible Event Envelope

Google's Agent-to-Agent (A2A) protocol defines standard fields for inter-agent communication. Adding these fields to the event sourcing layer costs nothing now but prevents vendor lock-in later.

```python
event_envelope = {
    "protocol": "a2a/v1.0",                # A2A protocol marker
    "exchange_id": trace_id,                # Maps to A2A conversation_id
    "sender": source,                       # Who sent this message
    "target": selected_worker or "*",       # Intended recipient
    "thread_id": trace_id,                  # Multi-turn exchange thread
    "message_type": event_type,             # A2A: text, structured, tool_use
    "timestamp": datetime.now().isoformat(),
    # Existing payload fields:
    "trace_id": trace_id,
    **data,
}
```

**Why this matters:** If the fleet later adopts A2A natively, the event log already speaks the dialect. A future adapter just translates the envelope format — no log-format migration needed.

**Pitfall:** Don't add A2A fields to the PipelineState dataclass itself. Add them only to the `log_event()` method's output envelope. The internal state should stay clean — the envelope is a wire format.

### Evaluation Framework

| Metric | Target | Source |
|--------|--------|--------|
| Pattern coverage | All relevant patterns (9+) | Production need |
| Agent count | 5-10 active | arXiv, Beam |
| Routing | LLM-based with keyword fallback | IBM, Anthropic |
| Recovery | 4-stage GraSP | Augment |
| Safety | Circuit breakers + human-in-loop | Tianpan, TrueFoundry |
| Observability | Cost, latency, error rates, CB trips | arXiv Support Agents |
| State | Typed with provenance + trace_id | Augment, LinkedIn |
| Governance | Task contracts + audit trail + OWASP AST10 review | LinkedIn, TrueFoundry, MLflow |

### Future-Proofing Audit (Systemic Gaps)

After the research-backed architecture is designed (above) and before sign-off, run a **systemic audit** for gaps that won't show up in a research-driven capability coverage matrix. These are structural gaps — the architecture may have all the right patterns but be brittle under growth.

#### Five Dimensions of Future-Proofing

| # | Dimension | Question | Failure Mode |
|---|-----------|----------|-------------|
| 1 | **Agent Discovery/Registration** | Can you add a new agent without editing Python code? If it requires editing fleet-manager.py's PROFILE_MAP, TIER sets, and routing logic, it doesn't scale. | Adding an agent becomes a code change, not a config change. Breeds resistance to growing the fleet. |

**Agent Discovery implementation — file-backed registry:**

The registry file (`task_contracts.json`) is the single source of truth. `fleet-manager.py` loads from it at startup with a fallback dict for bootstrap:

```python
import json
from pathlib import Path

CONTRACT_PATH = Path.home() / "AppData/Local/hermes/fleet/task_contracts.json"
if CONTRACT_PATH.exists():
    with open(CONTRACT_PATH) as f:
        TASK_CONTRACTS = json.load(f)
else:
    TASK_CONTRACTS = {...}  # Bootstrap defaults

# Profile name mapping — last hardcoded dict
HERMES_PROFILE_NAMES = {
    "vesta_4": "vesta", "astraea_5": "astraea", ...
}

# _load_profiles() reads from registry, not hardcoded sets
for pid, contract in TASK_CONTRACTS.items():
    if pid in PROFILE_MAP:
        self.profiles[pid] = AgentProfile(
            pid=pid,
            name=contract.get("display_name", pid),
            role=contract.get("role", "worker"),
            hermes_profile=PROFILE_MAP[pid],
            max_turns=contract.get("max_turns", 5),
            allowed_tools=contract.get("allowed_tools", []),
        )
```

**Scale threshold:** At **16+ workers**, even `HERMES_PROFILE_NAMES` should go — embed `hermes_profile` as a field in the contract JSON so an agent is fully self-describing from one file entry. Anything below 16 is fine with the dict + file approach.
| 2 | **On-Demand Health Monitoring** | Can you ask "is the fleet healthy right now?" and get a snapshot — agents responsive, circuit breaker states, recent error rates, cost trends? | Observability cron looks backward (4h log window). Acute failures go unnoticed until the user hits a broken dispatch. |

**Health check implementation — `--health` command:**

The observer cron provides trend data (backward-looking). The `--health` command provides a snapshot (right now):

```python
async def fleet_health_snapshot(self):
    checks = {
        "profiles_loaded": len(self.profiles),
        "state_file_ok": Path(self.state_path).exists(),
        "circuit_breakers": {},
        "agents_responsive": {},
    }
    # Poll circuit breaker states
    for agent_id in self.fleet_state.get("circuit_breakers", {}):
        cb = self.fleet_state["circuit_breakers"][agent_id]
        checks["circuit_breakers"][agent_id] = cb.get("state", "unknown")
    # Ping each profile for responsiveness
    for pid, profile in self.profiles.items():
        try:
            start = time.time()
            await self.dispatch_to_agent(
                profile,
                FleetEvent(type="ping", payload={"query": "ping"}, source="health"),
            )
            checks["agents_responsive"][pid] = {
                "status": "ok",
                "latency_ms": int((time.time() - start) * 1000),
            }
        except Exception as e:
            checks["agents_responsive"][pid] = {"status": "error", "error": str(e)[:60]}
    # Cost snapshot
    recent = deque(self.fleet_state.get("dispatches", []), maxlen=100)
    costs = [d.get("cost_usd", 0) for d in recent if "cost_usd" in d]
    checks["cost"] = {
        "avg_cost_per_dispatch": sum(costs) / len(costs) if costs else 0,
        "total_recent_100": sum(costs),
    }
    return checks
```

**Why separate from the observer cron:** The cron detects trends (growing error rates). The health command detects acute problems (an agent that stopped responding 30s ago). Both are needed — they answer different questions.
| 3 | **Profile Stack Optimization** | Is every agent necessary? Are there overlaps? Is the hierarchy depth correct (flat > deep)? Do the model tiers match each agent's workload (cheap for search, expensive for reasoning)? | Redundant agents increase coordination overhead. Wrong model = wasted cost or insufficient quality. |
| 4 | **Budget Enforcement** | What happens when total cost exceeds a threshold? Is there a stop-loss mechanism? | Unbounded costs from retry storms, runaway agents, or excessive iteration. The cost tracking cron logs the damage but doesn't stop it. |
| 5 | **Tool/Model Supply Chain** | Are all agents using the same set of tools and models? Is there a single point of failure at the provider level? | A provider outage or API key exhaustion blocks ALL agents. Cross-provider model selection per tier mitigates this. |

#### Audit Workflow

```
1. Registry check → Is there a file-backed agent registry (task_contracts.json)?
   YES → Verify fleet-manager.py reads from it, not from hardcoded dicts
   NO  → Add registry creation to Phase 0. Add file-loading to Phase 1

2. Health check → Is there an on-demand health command?
   YES → Verify it checks: CB states, agent responsiveness, cost snapshot
   NO  → Add as Phase N+1: `--health` flag on fleet-manager.py

3. Profile stack → Are any agents redundant or missing optimal format?
   For each agent, ask:
   - Does it have a unique domain not covered by any other agent?
   - Is its model tier appropriate (reasoning vs fast vs cheap)?
   - Could two workers be merged into one with no loss?
   - Is the hierarchy flat (workers under router) and not deep (worker under supervisor under gate)?
   
4. Budget → Is there any cost enforcement?
   NO  → Defer but document as accepted risk. Add to Open Questions.
   YES → Verify: daily cap? per-request cap? what happens when exceeded?

5. Supply chain → Are all agents on one provider?
   YES → What's the fallback? Can reasoning agents fall back to a different provider?
   NO  → Document the cross-provider topology
```

#### Example: This Session's Audit (Fleet v3 → v3.1)

| Dimension | Finding | Fix |
|-----------|---------|-----|
| Agent Discovery | Task contract registry exists as JSON but fleet-manager.py has hardcoded dict. Adding an agent = code change. | Phase 1.8.1: `TASK_CONTRACTS = json.load(open(path))` with inline fallback. |
| Health Monitoring | Only observer cron (4h window, looks backward). No way to ask "are agents responsive right now?" | Phase 3.6: `fleet-manager.py --health` returns CB states, per-agent responsiveness, costs. |
| Profile Stack | 7 workers × 3 gates × 1 router × 1 coordinator. Flat hierarchy. No redundancies found. Model tiers checked: appropriate. | No changes needed. ✅ |
| Budget Enforcement | Cost tracking exists (Phase 6.5) but no stop-loss. | Deferred to Open Questions — acceptable at current scale. |
| Supply Chain | All agents on Nous Portal. No cross-provider fallback in the design (Hermes-router handles it at the provider level, not the agent level). | Noted as architecture-level risk. Router fallback chain covers provider-level failover. |

**When to run this audit:**
- Before deploying any architecture change
- When the user asks "make it future proof"
- At each major inflection point (doubling agent count, adding multi-tenancy, cross-platform expansion)

**Pitfall:** Don't confuse "covers all research sources" with "is future-proof." The research-backed Capability Coverage Matrix and the Future-Proofing Audit check different things — one looks at WHAT the architecture does, the other at HOW it handles growth. Both are required before sign-off.

### Phase 3 Verification

```bash
# Check PipelineState is wired through pipeline methods
python -c "import ast; tree = ast.parse(open('fleet-manager.py').read()); refs = [n for n in ast.walk(tree) if isinstance(n, ast.Name) and n.id == 'PipelineState']; print(f'PipelineState references: {len(refs)}')"

# Test --health CLI
python fleet-manager.py --health

# Verify tier-aware logging in dispatch log
python fleet-manager.py --status | grep "Dispatcher health"
```

### Critical Learnings from Phase 3

1. **Tier detection via max_turns.** The `log_for_tier` helper uses `profile.max_turns` as a proxy for agent tier: 0 → WARNING level (gates), 1 → INFO (workers), 8 → DEBUG (execution). This avoids adding a separate tier field to AgentProfile.

2. **PipelineState is opt-in, not refactoring.** The dataclass is threaded as `pipeline: PipelineState = None` on every method, not `pipeline: PipelineState` (required). This lets the method receive state without changing its return type — critical for keeping the refactor bounded.

3. **Event GC is premature without event files.** `--health` verified no events directory exists on disk. The conditional second evaluator and event-sourcing patterns are documented but not implemented (Phase 8). Don't create GC infrastructure before the data exists.

4. **Allowlist enforcement = real safety.**

## Phase 4 Implementation Patterns

In `dispatch_to_agent()`, after loading the contract for a profile:

1. **Read** `contract.allowed_tools` from the task contract registry
2. **Compare** against `profile.tools` (loaded from V5 JSON)
3. **Strip** any tool not in the allowlist: `profile.tools = [t for t in profile.tools if t in contract_tools]`
4. **Log** which tools were stripped and the resulting allowlist
5. **Result:** The Hermes subprocess never receives tools the contract forbids

This is a **fail-open at the manager level, fail-close at the subprocess level** — the manager strips tools before they reach the agent. If a tool is accidentally omitted from the contract, the manager can't know, but the agent has fewer tools than expected (safe side).

### Tool Levels — Secondary Safety Ring

`TOOL_LEVELS` constants define the maximum tool set per dispatch tier:

| Tier | Tools | Agents |
|------|-------|--------|
| 0 | None (empty list) | Vesta-4, Astraea-5, Ceres-1, Nemesis-128 |
| 1 | Read, write, search, web, vision | Fortuna-19, Harmonia-40, Klio-84, Atalanta-36, Kalliope-22 |
| 8 | Full: terminal, cron, execute_code | Metis-9, Artemis-105 |

The tier level is a **secondary ring** — the contract's `allowed_tools` is the primary gate. Both must agree for a tool to pass.

### Destructive Operations

`DESTRUCTIVE_TOOLS = ["cronjob", "terminal", "process"]` — flagged but not currently gated. Future work: intercept these at the Hermes CLI level with a confirmation prompt.

### Maintenance Mode

`fleet-manager.py --maintenance on|off` toggles a flag that rejects all dispatches with a maintenance message. No state is lost — agents remain in `self.profiles`, state counters persist. Use before hot-updating profiles or deploying contract changes.

### Phase 4 Verification

```bash
# Verify tool gateway — check profile tools are being stripped
python fleet-manager.py --status
# Look for "Stripping disallowed tools" in the log

# Toggle maintenance mode
python fleet-manager.py --maintenance on
python fleet-manager.py --status | grep Maintenance
python fleet-manager.py --maintenance off

# Verify dispatch still works after toggling
python fleet-manager.py --maintenance off
```

### Critical Learnings from Phase 4

**⚠️ FIXED June 2026 — Tool loading now sources from task_contracts.json, giving workers real tool access.**

Before the fix, `profile.tools` was loaded from the V5 JSON which uses abstract/conceptual tool names (`wiki_search`, `headless_browser`, `ast_parser`). The contract's `allowed_tools` uses real Hermes tool names (`mcp_wiki_search_wiki`, `web_search`, `execute_code`). These never matched → every worker had `profile.tools = []`.

**The root cause:** `fleet-manager.py` line 616 loaded tools from the V5 JSON design artifact, not from the runtime `task_contracts.json`:

```python
# Before (V5 JSON — abstract names like 'wiki_search'):
tools=entry.get("operational_matrix", {}).get("allowed_tools", []),
```

**The fix (one line):**
```python
# After (task_contracts.json — real Hermes tool names like 'mcp_wiki_search_wiki'):
tools=TASK_CONTRACTS.get(pid, {}).get("allowed_tools", []),
```

This changes the source of truth for `profile.tools` from the V5 design JSON to the `task_contracts.json` registry. Since the contract's `allowed_tools` are what the tool gateway compares against, sourcing tools from the contract means they always match — no stripping from mismatch.

**Impact verified in E2E tests:**
- Pre-fix: Klio responded from training data only (couldn't search wiki, `profile.tools = []`)
- Post-fix: Klio has `mcp_wiki_search_wiki`, `mcp_wiki_read_wiki_page`, `mcp_wiki_list_wiki_pages`, `mcp_wiki_lint_wiki`, `mcp_wiki_reindex_wiki`, `mcp_wiki_wiki_stats`, `mcp_wiki_synthesize_answer`, `read_file`, `write_file`. Searched "hermes router" and returned 2369 chars with live wiki page IDs and content.
- All 11 workers now load their correct contract tools at runtime

**Verification after fix:**
```bash
cd ~/AppData/Local/hermes/scripts
python fleet-manager.py "search the wiki for hermes router"
# Expect: Decision tree → pattern: wiki
#         Pattern: SINGLE WORKER → klio_84
#         ✅ Klio-84 responded (N chars)
#         Content includes real wiki page IDs
# Log NO LONGER shows: Stripping disallowed tools
# Log SHOWS: L1 — stripped 1 tools: ['terminal']  (tier level, not mismatch)
```

**Tier-based enforcement still applies** (`_enforce_tool_level`). The `L1 — stripped N tools: [...]` log message is from tier level, not name mismatch — expected behavior.

**Two-ring tool safety.** Contract allowlists + tier-based tool levels = defense in depth. The tier level acts as a catch-all for tools not yet in any contract, while the contract provides per-agent precision. Both must be maintained.

3. **Maintenance mode is not persistence.** The flag resets on restart. Use `--maintenance on` before a deployment sequence, not as a persistent config.

### Fleet-Manager Fixes (June 2026)

**V5_JSON path fix — `wiki` → `llm-wiki`:**

During a wiki path migration (`Hermes-Vault/wiki` → `Hermes-Vault/llm-wiki`), `fleet-manager.py`'s `V5_JSON` variable still pointed at the old path, silently failing to find the profile JSON:

**Fix:** Updated the path assignment to resolve under the correct `llm-wiki` path.

**`asyncio.run()` inside running event loop:**

The `__main__` block used `asyncio.run(manager.fleet_health_snapshot())`. When called from an already-running event loop, this raises `RuntimeError: asyncio.run() cannot be called from a running event loop`.

**Fix:** Wrapped the entry point in `async def main():` — sync callers use `asyncio.run(main())`, async callers `await main()` directly. Preserves CLI compatibility while allowing programmatic invocation.

**Verification:** `python fleet-manager.py --health` returns agent responsiveness snapshot with no `RuntimeError`.

## Phase 5 Implementation Patterns — Bulkheads + Circuit Breakers + GraSP Recovery

### Core Data Structures

```python
# Bulkhead semaphores — per-class, prevents noisy-neighbor
BULKHEAD_SEMAPHORES = {"fast": 5, "heavy": 2, "guardrail": 3}

# Circuit breaker — 3-state, per-agent, rolling 60s window
CB_CONFIG = {
    "failure_threshold": 0.5,   # 50% failure rate trips
    "window_seconds": 60,
    "cooldown_seconds": 120,    # 2 min before HALF_OPEN
    "half_open_max": 2,         # Test calls before resetting
}
```

### Circuit Breaker State Machine

```
CLOSED → (failure rate > 50% over 60s) → OPEN
OPEN → (120s cooldown expires) → HALF_OPEN
HALF_OPEN → (2 consecutive successes) → CLOSED
HALF_OPEN → (any failure) → OPEN (full cooldown)
```

Implementation: `_get_cb_state()` initializes per-agent with rolling failure timestamps. `_record_cb_failure()` prunes expired entries and checks rate. `_record_cb_success()` resets HALF_OPEN → CLOSED. State persisted via `FleetState.cb_state` for crash recovery.

### Bulkhead Integration

- **fast** (max 5): Search, wiki, devops, content, design — high volume, low cost
- **heavy** (max 2): Code gen, data, QA, review — high cost, low volume
- **guardrail** (max 3): Security, routing — must always be available

Acquire in `_dispatch_with_fallback` via `_bulkhead_acquire()`, release in `finally` block. Non-blocking: if lock contended, dispatches proceed but skip bulkhead (best-effort).

### GraSP Recovery Chain

4-step recovery order (Tianpan 2026):

1. **Substitute** — different agent for same task (map-based)
2. **Rebind** — same agent with "previous attempt failed" context  
3. **Bypass** — Hermes default catch-all with failure context
4. **Escalate** — return None, caller sees the gap

Implementation: `_grasp_recover()` in fleet-manager. Called from `_dispatch_with_fallback()` when primary dispatch fails OR when circuit breaker is OPEN.

### Idempotency Cache

MD5-keyed cache (`pid:user_input`) with 300s TTL. Prevents the same task from hitting the same agent twice in quick succession. Prunes expired entries on each check.

### CLI Commands — Consolidated Reference

The fleet manager ships with these CLI flags. Run from `~AppData/Local/hermes/scripts/`:

| Flag | What It Does | Example |
|------|-------------|---------|
| `"user message"` | Single dispatch | `python fleet-manager.py "check disk space"` |
| `--status` | Fleet overview: profiles, tier, dispatch counts | `python fleet-manager.py --status` |
| `--health` | On-demand agent responsiveness snapshot | `python fleet-manager.py --health` |
| `--recent [N]` | Last N dispatches from audit log (default 20) | `python fleet-manager.py --recent 10` |
| `--cost-report` | Per-agent cost breakdown from cost_log.jsonl | `python fleet-manager.py --cost-report` |
| `--cb-status` | Per-agent circuit breaker states + failure rates | `python fleet-manager.py --cb-status` |
| `--routing-status` | Routing cache: valid/expired entry count | `python fleet-manager.py --routing-status` |
| `--maintenance on/off` | Toggle maintenance mode | `python fleet-manager.py --maintenance on` |
| `--channels` | Pub/sub channel map | `python fleet-manager.py --channels` |
| `--interactive` | REPL mode for sequential dispatches | `python fleet-manager.py --interactive` |

**Data files** (all under `~/AppData/Local/hermes/fleet/`):
- `~/AppData/Local/hermes/fleet/task_contracts.json` — per-agent input/output schemas
- `~/AppData/Local/hermes/fleet/audit.jsonl` — per-dispatch records (agent_pid, cb_state, duration_ms, success, trace_id)
- `~/AppData/Local/hermes/fleet/cost_log.jsonl` — per-dispatch cost estimates
- `~/AppData/Local/hermes/fleet/audit.jsonl` — per-dispatch decisions
- `task_contracts.json` — per-agent input/output schemas
- `fleet-state.json` — persistent state (counters, CB states, quarantines)

### Phase 5 Verification

```bash
# Check all breakers are CLOSED
python fleet-manager.py --cb-status

# Toggle maintenance to see breaker states persist
python fleet-manager.py --maintenance on
python fleet-manager.py --maintenance off
python fleet-manager.py --cb-status  # Should still show CLOSED for all

# Verify status page shows maintenance + bulkhead counts
python fleet-manager.py --status | grep -E "(Maintenance|breaker|Bulkhead)"
```

### Critical Learnings from Phase 5

1. **Circuit breakers need per-agent state, not global.** A failing Metis shouldn't block Artemis. The per-agent CB state persisted via FleetState means restarts don't reset health.

2. **Bulkhead semaphores must release in `finally`.** Without the `try/finally` in `_dispatch_with_fallback`, a timeout would leak the semaphore and eventually lock the entire class.

3. **GraSP is better than simple fallback.** The old code only had "try primary → Hermes default". GraSP's 4-step chain gives 3 more chances to recover gracefully before reaching the catch-all.

4. **Idempotency on the dispatching side is safer than on the agent side.** Agents can't coordinate. The dispatcher is the single point where dedup makes sense.

## Phase 6 Implementation Patterns — Gate Routing Cache

### Problem

`_llm_classify_task()` dispatches to Astraea-5 for every request, taking 30s+ per call. Most requests fit into the same routing patterns (search, code, wiki, etc.) — caching avoids redundant subprocess dispatches.

### Implementation

```python
# In __init__:
self._routing_cache: dict[str, tuple[str, float]] = {}

# In _llm_classify_task:
normalized = user_input.strip().lower()[:200]
now = time.time()
if normalized in self._routing_cache:
    pattern, cached_at = self._routing_cache[normalized]
    if now - cached_at < ROUTING_CACHE_TTL:  # 300s
        log.info(f"🧠 Routing cache hit: {pattern}")
        return pattern
    else:
        del self._routing_cache[normalized]
```

### TTL

300s (5 min) — long enough for repeated queries in a session, short enough that stale routing decays naturally.

### Cache Policy

- Key: `user_input.strip().lower()[:200]` — 200-char prefix of normalized input
- Value: `(pattern: str, timestamp: float)` — stores the LLM routing decision
- TTL: 300s, checked on every `get()`, expired entries auto-cleaned on access
- Miss penalty: zero — falls through to normal LLM routing with no cache overhead

### CLI

`python fleet-manager.py --routing-status` — prints valid/expired entry count.

### Pitfall

Cache is in-memory only. Each `fleeting-manager.py` subprocess invocation starts with an empty cache. For persistent caching (daemon mode), the cache would need to move to Redis or a file — overkill at current scale.

### Fleet Health Watchdog

**Problem:** The fleet has circuit breakers, bulkheads, and health checks — but no automated alerting. A CB trip or agent going down is only noticed when a dispatch fails.

**Solution — no_agent=True cron with silent-when-healthy pattern:**

The watchdog script (`fleet-health-watchdog.py`) runs every 30 min via cron. It checks:
- `--cb-status` for OPEN or HALF_OPEN breakers
- `--status` for quarantined agents or maintenance mode

```python
# In fleet-health-watchdog.py:
def check_cb_status():
    out = run_flag("--cb-status", timeout=15)
    issues = []
    for line in out.splitlines():
        if "OPEN" in line or "HALF_OPEN" in line:
            issues.append(f"⚠️  CB: {line}")
    return issues

def check_status():
    out = run_flag("--status", timeout=15)
    issues = []
    q_match = re.search(r"Quarantines:?\s*(\d+)", out)
    if q_match and int(q_match.group(1)) > 0:
        issues.append(f"⚠️  {q_match.group(0)}")
    if re.search(r"Maintenance.*ON", out):
        issues.append("⚠️  Fleet is in MAINTENANCE mode")
    return issues
```

**no_agent=True pattern (from cron spec):**
- Empty stdout = SILENT — nothing is sent, no notification
- Non-empty stdout = delivered as an alert
- Non-zero exit = error alert

This means the watchdog uses ZERO tokens when the fleet is healthy. It only costs tokens when something is wrong.

**Verification:**
```bash
# Test the watchdog (should be silent if fleet is healthy)
cd "~/AppData/Local/hermes/AppData/Local/hermes/scripts" && timeout 30 python fleet-health-watchdog.py
# No output = healthy
```

### Test Coverage

3 tests in `TestRoutingCache`: initialization, cache hit returns correct pattern, expired entries detected during lookup.

### Profile Survey Finding (June 2026)

During Phase 7 planning, all 11 profiles were audited. **Result: All are already task-first [ROLE] format with [ROLE], [BEHAVIOR], [OUTPUT], [RULES], [PERSONALITY] sections. No V4 theatrical personas remain. Phase 7 is effectively complete.**

| Profile | Chars | Sections | Status |
|---------|-------|----------|--------|
| Standard agents (8) | 470-782 | ROLE, BEHAVIOR, OUTPUT, RULES, SKILLS, PERSONALITY | ✅ Task-first with skills |
| Gate agents (3) | 1365-1819 | ROLE, CRITERIA, OUTPUT, RULES, PERSONALITY | ✅ Structured evaluators |

**Phase 7 expanded (June 2025):** [SKILLS] sections added to all worker profiles as a separate layer — agents now load role-specific procedural knowledge alongside their tool allowlists.

**Acknowledged polish (low priority):** [TOOLS] section awareness was assessed and closed as redundant — agents already know their tools from Hermes Agent profile config.

---

## Linked Files

This skill ships with supporting files in the `references/` directory:

- **production-hardening-checklist.md** — Phase-by-phase checklist of 22 checks
- **phase-0-pre-flight-worked-example.md** — Real execution trace of Phase 0
- **phase-1-llm-routing-and-contracts.md** — Phase 1 patterns
- **pipeline-state-pattern.md** — PipelineState dataclass reference
- **fleet-test-suite-pattern.md** — 41-test suite methodology
- **e2e-smoke-test.md** — Quick 6-test routing smoke test (sequential dispatch, ~30-60 min)
- **fleet-health-watchdog.md** — Silent watchdog cron pattern with no_agent=True
- **External artifacts:** `~/AppData/Local/hermes/fleet/task_contracts.json`, `owasp-ast10-audit.md`, `agent-factory-workflow.md`
- **cost-audit-provenance-patterns.md** — Implementation reference for cost estimation, audit log, provenance tagging, and `--cost-report` CLI flag
- **session-2026-06-24-enforce-tools-and-recent-cli.md** — Privilege level enforcement via max_turns, `--recent` CLI pattern, FLEET_DIR centralization
- **profile-skill-loading.md** — Full per-role [SKILLS] mapping for worker profile SOUL.md files

---

## Deferred Item Registry — Triggers for Revisit

| # | Item | Trigger | Notes |
|---|------|---------|-------|
| 1 | **Sandbox** (per-dispatch write redirection) | Hermes Agent adds `HERMES_SANDBOX_DIR` (or similar) env var to write_file/patch tools | Current privilege levels (L0-L4) provide operational sandbox |
| 2 | **Event GC cron** (30-day retention) | Daily event volume exceeds 10MB | At ~50KB/day, not worth automating yet |
| 3 | **Profile [TOOLS] sections** | No trigger — closed as redundant | Agents know tools from profile config, not SOUL.md. [SKILLS] (added June 2025) is a separate concept — procedural knowledge, not tool capability. Don't conflate. |
| 4 | **Profile cross-refs/output examples** | No trigger — purely cosmetic | Stretch goal, no blocking value |
| 5 | **Worker profile [SKILLS] expansion** | New worker profile created | Add [SKILLS] section to SOUL.md per profile-skill-loading.md mapping |

**When Hermes Agent ships a relevant feature, cross-reference this registry — the user wants to be notified when any of these items becomes unblocked.**
