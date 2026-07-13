# Cost Tracking, Audit Trail & Provenance — Implementation Reference

Implemented June 2026 during Fleet V3.1 buildout. Covers three patterns deployed in
`fleet-manager.py` for observability and governance.

## Cost Estimation

### Constants & Helper

```python
TOKENS_PER_SECOND = {"fast": 800, "heavy": 250, "guardrail": 600}
COST_PER_1K_TOKENS = 0.0002  # ~$0.002 per 10K tokens (Nous directional)

def estimate_dispatch_cost(agent_pid: str, duration_ms: float) -> dict:
    if duration_ms <= 0:
        return {"tokens": 0, "cost_usd": 0.0, "level": "unknown"}
    tier = "fast"
    if agent_pid in TIER_8_AGENTS:
        tier = "heavy"
    elif agent_pid in TIER_0_AGENTS:
        tier = "guardrail"
    elif agent_pid in TIER_1_AGENTS:
        tier = "fast"
    tps = TOKENS_PER_SECOND.get(tier, 400)
    estimated_tokens = int(tps * (duration_ms / 1000))
    cost = round(estimated_tokens / 1000 * COST_PER_1K_TOKENS, 6)
    return {"tokens": estimated_tokens, "cost_usd": cost, "level": tier}
```

### Log Writing

```python
COST_LOG = FLEET_DIR / "cost_log.jsonl"

def write_cost_log(entry: dict):
    COST_LOG.parent.mkdir(parents=True, exist_ok=True)
    with open(COST_LOG, "a") as f:
        f.write(json.dumps({"ts": time.time(), **entry}) + "\n")

def write_audit_log(entry: dict):
    AUDIT_LOG.parent.mkdir(parents=True, exist_ok=True)
    with open(AUDIT_LOG, "a") as f:
        f.write(json.dumps({"ts": time.time(), **entry}) + "\n")
```

### Report Generation

```python
def generate_cost_report() -> str:
    if not COST_LOG.exists():
        return "📊 No cost data recorded yet."
    with open(COST_LOG) as f:
        entries = [json.loads(line) for line in f if line.strip()]
    total_cost = sum(e.get("cost_usd", 0) for e in entries)
    total_tokens = sum(e.get("tokens", 0) for e in entries)
    # Per-agent breakdown via agent_costs dict
    lines = ["📊 FLEET COST REPORT", ...,
             f"Total dispatches: {len(entries)}",
             f"Total estimated tokens: {total_tokens:,}",
             f"Total estimated cost: ${total_cost:.6f}"]
    for pid, stats in sorted(agent_costs.items(), key=lambda x: -x[1]["cost"]):
        lines.append(f"  {pid}: {stats['dispatches']} disp, ...")
    return "\n".join(lines)
```

### Wiring in _dispatch_with_fallback

Every return path calls `_log_dispatch_outcome()`:

```python
def _log_dispatch_outcome(self, agent_pid, event_type, response, start_time, pipeline):
    duration_ms = (time.time() - start_time) * 1000
    success = bool(response and len(response.strip()) > 10)
    cb_state = self._get_cb_state(agent_pid)
    cost = estimate_dispatch_cost(agent_pid, duration_ms)
    write_cost_log({"agent_pid": agent_pid, "tokens": cost["tokens"], ...})
    write_audit_log({"trace_id": pipeline.trace_id, "agent_pid": agent_pid, ...})
```

## Provenance Tagging

After a worker produces output, check for uncertainty signals. If found, append
`[PROVENANCE: uncertain]` so downstream agents can weight the output lower.

```python
def _tag_output_provenance(self, response: str, agent_pid: str) -> str:
    if not response:
        return response
    uncertainty_signals = ["I think", "probably", "might be", "I'm not sure",
                           "could be", "possibly", "I believe", "as far as I know",
                           "I'm not certain", "I assume"]
    text_lower = response.lower()
    has_uncertainty = any(sig.lower() in text_lower for sig in uncertainty_signals)
    if has_uncertainty:
        return response + "\n\n[PROVENANCE: uncertain — agent expressed doubt]"
    return response
```

**Critical detail:** Both text and signals are lowercased. Without `sig.lower()`,
`"I think"` never matches `"i think"` and the tag is silently omitted.

## CLI Entry

```bash
python fleet-manager.py --cost-report
```

Added to `main()` as a new `elif` branch between `--routing-status` and `--interactive`.
Usage string updated to include `--cost-report`.
