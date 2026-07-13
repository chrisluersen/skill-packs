# Four Primitives — Patterns for Multi-Agent Orchestration

**Source session:** 2026-06-24 (fleet optimization plan v2)
**Derived from:** Augment Code (four primitives), arXiv 2601.13671v1 (Worker/Service/Support taxonomy), Beam AI (production failure modes), IBM Think (orchestration steps)

## Overview

Every multi-agent orchestration system depends on four primitives: Task Decomposition, Routing, State, and Recovery. A gap in any one creates systemic failure. These patterns capture the techniques that emerged from synthesizing 12 research sources into a production-grade fleet architecture.

---

## 1. Typed PipelineState — The State Primitive

**Problem:** Unstructured strings passed between pipeline stages (raw `worker_output` → raw `nemesis_eval` → raw `ceres_verdict`). No schema enforcement. No audit trail. Debugging requires grep over unstructured log lines.

**Pattern:** A typed dataclass that threads through the entire dispatch pipeline, carrying structured context between agents.

```python
@dataclass
class PipelineState:
    task: str = ""
    plan: str = ""              # Astraea-5 decomposition
    worker: str = ""            # selected worker profile_id
    worker_output: str = ""
    nemesis_eval: Optional[dict] = None
    ceres_verdict: Optional[str] = None
    evaluations: list[dict] = field(default_factory=list)
    latency_ms: int = 0
    dispatch_tier: int = 0
    pattern: str = "auto"
    error: Optional[str] = None
    start_time: float = field(default_factory=time.time)
```

**Key design decisions:**
- `Optional[dict]` for evaluation fields — agents return structured JSON, not free text
- `latency_ms` calculated at end of pipeline — enables observability without extra instrumentation
- `error` field tracks which recovery strategy was used — distinguishing Rebind vs Substitute vs Bypass vs Escalate failures

**Integration points:**
- Every pipeline stage (`_run_sequential_pipeline`, `_run_qa_gates`, `_dispatch_with_fallback`) accepts and returns `PipelineState`
- On completion, logged as structured JSON for observability: `log.info(f"📊 State: {json.dumps(entry)}")`
- Future: could be appended to `audit.jsonl` for persistence

**When to use:** Any multi-stage pipeline where agents pass context to downstream agents. Avoid if you have a single-agent architecture (no state to share).

---

## 2. GraSP Recovery — The Recovery Primitive

**Problem:** Current fallback is "retry once, then default agent." A single failure cascades through the entire pipeline — no local repair attempted before escalation.

**Pattern:** Four ordered recovery strategies (from GraSP graph repair primitives), tried in increasing cost:

```python
async def _recover_with_repair(self, user_input, failed_worker, error, state):
    # Strategy 1: Rebind — retry with restructured prompt
    retry_result = await self.dispatch_to_agent(
        self.profiles[failed_worker],
        FleetEvent(type="chat_query", payload={
            "query": f"The previous attempt had an error. Try again with a different approach.\n\nTask: {user_input}"
        }))
    if retry_result and len(retry_result) > 50:
        return retry_result
    
    # Strategy 2: Substitute — use a different worker
    substitute_map = {
        "artemis_105": ("klio_84", "wiki_query", ...),
        "metis_9": ("hermes_default", "chat_query", ...),
        ...
    }
    if failed_worker in substitute_map:
        return await self.dispatch_to_agent(...)
    
    # Strategy 3: Bypass — return partial output
    if state.worker_output:
        return state.worker_output[:500] + "\n\n[partial — worker error]"
    
    # Strategy 4: Escalate — full replan
    return await self._run_sequential_pipeline(user_input)
```

**Ordering rationale:** Rebind is cheapest (same agent, same API call pattern). Substitute adds a different agent (different profile, same cost). Bypass sacrifices completeness for availability. Escalate is the full pipeline cost — only when all cheaper strategies fail.

**Substitute map — which agent substitutes for which:**

| Primary | Substitute | Rationale |
|---------|-----------|-----------|
| Artemis-105 (web search) | Klio-84 (wiki) | Both information retrieval |
| Metis-9 (code) | Hermes default (general) | Default can write simple code |
| Klio-84 (wiki) | Fortuna-19 (data) | Both structured retrieval |
| Fortuna-19 (data) | Klio-84 (wiki) | Mutual backup pair |
| Atalanta-36 (devops) | Hermes default | Status checks are general |

**When to use:** Any multi-agent system with more than 2 agents. The cost of repair is negligible compared to the cost of a full pipeline re-run.

---

## 3. Context Budget — Orchestrator Overflow Prevention

**Problem (Beam AI):** The orchestrator accumulates context from every worker it dispatches. With 4+ workers, context exceeds window limits. Beam reports this as the #2 orchestrator failure mode (after misclassification).

**Pattern:** A configuration block that caps parallel workers and enforces per-worker context limits:

```python
CONTEXT_BUDGET = {
    "max_active_workers": 3,       # cap parallel workers
    "max_context_chars": 8000,     # per-worker context before summarize
    "summary_after_n_workers": 2,  # summarize handoffs after 2+
}
```

**Enforcement points:**
1. `_check_context_budget()` — caps fan-out to `max_active_workers` before dispatch
2. Per-worker truncation — each fan-out worker result truncated at `max_context_chars`
3. Summary threshold — after `summary_after_n_workers` workers reply, subsequent handoffs are summarized (concatenated summaries instead of full output)

**Tuning:** Start conservative (3 workers, 8K). If fan-out tasks routinely produce high-quality results at 4+ workers, increase `max_active_workers`. If API limits are hit, decrease.

**Relationship to rate limits:** The context budget caps parallel workers. Rate limit enforcement (asyncio.Semaphore) caps concurrent API calls. Both are needed — context budget prevents orchestrator overflow, semaphore prevents provider 429s.

---

## 4. Deep Observability — The Support Agent Primitive

**Problem (arXiv 2601.13671v1):** Support agents (monitoring, health, transparency, drift detection) are a core agent category, but our fleet has none. No agent watches token costs, latency trends, or error rates.

**Pattern:** A no_agent cron that reads fleet logs and produces structured observations:

```
fleet-observer.py (every 4h)
  ├── Parses fleet.log for: dispatches, successes, failures, timeouts, quarantines
  ├── Computes: success rate, avg latency, P95 latency, errors by agent
  ├── Appends structured JSON to ~/.hermes/fleet/observations/YYYY-MM-DD.jsonl
  └── Silent when healthy. Verbose on anomalies (failure > success, timeouts > 3)
```

**What to track per dispatch:**

| Metric | Source | Why |
|--------|--------|-----|
| Agent profile_id | Log line | Which agent is failing most |
| Pattern | log context | Which pattern is slowest |
| Latency_ms | Timing | P95 drift detection |
| Token estimate | Model tier × latency | Cost attribution |
| Success/failure | Exit code | Error rate by agent/pattern |
| Quarantine | Vesta-4 flag | Security incident frequency |

**Trend analysis:** Observations accumulate in daily JSONL files. Over 7-30 days, you can detect:
- Which agents degrade over time (latency creep)
- Which patterns cost the most (token count per dispatch)
- Error rate changes after config changes

**Integration with cost tracking:** Each dispatch also writes to `~/.hermes/fleet/cost_log.jsonl`:

```json
{"ts": ..., "agent": "metis_9", "tier": "Massive/Coding", "latency_ms": 4500, "tokens_est": 1800}
```

**When to add:** Before scaling beyond 5 agents. Silent failures compound faster than human monitoring can catch them.

---

## 5. Rate-Limited Fan-Out — Safe Parallel Dispatch

**Problem (Beam AI):** API rate limits are the #1 failure mode under fan-out. 3 parallel dispatches to the same provider can exceed per-second or per-minute limits, causing cascading failures.

**Pattern:** asyncio.Semaphore wraps each parallel dispatch, preventing more than N concurrent API calls:

```python
semaphore = asyncio.Semaphore(3)  # max 3 concurrent API calls

async def _dispatch_with_rate_limit(pid, event_type, payload):
    async with semaphore:
        result = await self._dispatch_with_fallback(...)
        # Truncate if over context budget
        if result and len(result) > CONTEXT_BUDGET["max_context_chars"]:
            result = result[:CONTEXT_BUDGET["max_context_chars"]] + "\n\n[truncated]"
        return pid, result
```

**Tuning:** Start at 3 (matches context budget cap). If you hit 429s:
- Lower to 2
- Add retry with exponential backoff
- Stagger dispatch starts by 500ms

**Safety layer:** The fan-out method should never block. If the semaphore wait exceeds 5s, return partial results from completed workers rather than blocking the whole response.

---

## 6. Light Governance — Cost + Audit Trail

**Problem (TrueFoundry):** Multi-agent workflows can involve 15+ inference calls per task. Without tracking, you can't attribute costs, reconstruct decisions, or audit failures.

**Pattern:** Two JSONL logs — one for cost, one for audit:

```python
# Cost log — per-dispatch token estimates
def record_cost(self, agent_pid, tier, latency_ms):
    entry = {"ts": time.time(), "agent": agent_pid, "tier": tier,
             "latency_ms": latency_ms, "tokens_est": estimate_from_tier(tier, latency_ms)}
    with open("~/.hermes/fleet/cost_log.jsonl", "a") as f:
        f.write(json.dumps(entry) + "\n")

# Audit log — per-request provenance
def log_audit(self, user_input, pattern, worker, result):
    entry = {"ts": time.time(), "task": user_input[:100], "pattern": pattern,
             "worker": worker, "response_length": len(result) if result else 0, "success": result is not None}
    with open("~/.hermes/fleet/audit.jsonl", "a") as f:
        f.write(json.dumps(entry) + "\n")
```

**Query patterns:**
- `grep metis cost_log.jsonl | python -c "sum(json loads)"` — total Metis cost
- `grep '"success": false' audit.jsonl | wc -l` — failure rate
- `python fleet-manager.py --cost-report` — per-agent dispatch summary

**When to add:** Before production use. After the fact, you can't reconstruct costs.

---

## Relationship Between Patterns

```
User Request
    │
    ▼
PipelineState.created()          ← Primitive: State
    │
    ▼
Context Budget check             ← Pattern 3: Cap parallel workers
    │
    ▼
Fan-out (with Semaphore)         ← Pattern 5: Rate-limited parallel
    │
    ├── Worker A succeeds ──► PipelineState.worker_output
    ├── Worker B fails ────► GraSP Recovery (Pattern 2)
    │                          ├── Rebind (retry)
    │                          ├── Substitute (different worker)
    │                          ├── Bypass (partial output)
    │                          └── Escalate (full replan)
    │
    ▼
PipelineState.nemesis_eval ← QA Gate
    │
    ▼
PipelineState.latency_ms = now - start_time
    │
    ▼
Deep Observability (Pattern 4) ← writes to cost_log.jsonl
Light Governance (Pattern 6)   ← writes to audit.jsonl
    │
    ▼
User receives result + structured state log
```
