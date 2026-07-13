# PipelineState — Typed State Threading Through Agent Pipelines

## Context

Introduced during Phase 3 of the fleet architecture implementation (2026-06-24) to replace raw `uuid.hex()` calls and string/dict passing between pipeline stages.

## Problem

A multi-agent pipeline passes state through multiple stages: security screening → routing → dispatch → QA → review. Without typed state:

- `trace_id` gets regenerated or forgotten across async calls
- Timing information (start/end times per stage) requires separate tracking
- Debugging requires reconstructing what happened from scattered log lines
- Error propagation is ad-hoc ("return None and hope the caller handles it")

## The Pattern: Optional PipelineState Threading

### Core Principle

**Don't change return types. Add state as an optional parameter.**

Every pipeline method retains its original return signature. `PipelineState` is threaded as:

```python
async def some_method(self, ..., pipeline: PipelineState = None) -> OriginalReturnType:
```

This means:
- Existing callers continue working with zero changes
- Tests don't need updating
- The state is opt-in — methods only use it when the caller provides it
- Gradual adoption is possible (thread through one method at a time)

### PipelineState Dataclass

```python
@dataclass
class PipelineState:
    """Typed state for a single request pipeline execution.

    Replaces raw dict/string passing between pipeline stages.
    Every stage CAN receive and update pipeline state without
    changing its return type.
    """
    request_id: str = field(default_factory=lambda: uuid.uuid4().hex[:12])
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
```

### Threading Flow

```
process_request(user_input)
  │
  ├── creates PipelineState(user_input=user_input, start_time=time.time())
  ├── trace_id = pipeline.trace_id
  ├── passes pipeline=pipeline to every dispatch
  │
  ├── direct pattern → dispatch_to_agent(..., pipeline=pipeline)
  ├── code pattern   → _dispatch_with_fallback(..., pipeline=pipeline)
  │   └── _run_qa_gates(..., pipeline=pipeline)
  │       └── _ceres_review_gate(..., pipeline=pipeline)
  ├── single worker  → _dispatch_with_fallback(..., pipeline=pipeline)
  └── complex        → _run_sequential_pipeline(..., pipeline=pipeline)
      ├── dispatch_to_agent(astraea, ..., pipeline=pipeline)
      ├── _route_to_worker(..., pipeline=pipeline)
      │   └── _dispatch_with_fallback(..., pipeline=pipeline)
      └── _run_qa_gates(..., pipeline=pipeline)
          └── _ceres_review_gate(..., pipeline=pipeline)
```

### What Each Stage Updates

| Stage | PipelineState Fields Updated |
|-------|------------------------------|
| `process_request()` | `trace_id`, `start_time` |
| Vesta-4 dispatch | `vesta_response`, `vesta_passed`, `cleaned_input` |
| Pattern dispatch | `pattern` |
| Astraea-5 plan | `astraea_plan` |
| `_dispatch_with_fallback` | `worker_pid`, pattern |
| `_route_to_worker` | pattern (through dispatch) |
| `_run_qa_gates` | `evaluations`, `qa_passed`, `ceres_response`, `ceres_approved` |
| Ceres gate | `ceres_response`, `ceres_approved`, `halted`, `final_output` |

### Event Logging

Each method that accepts pipeline calls `pipeline.log_event()` at key transitions:

```python
pipeline.log_event("dispatch_start", {
    "agent": profile.pid,
    "profile": profile.hermes_profile,
    "event_type": event.type,
})

pipeline.log_event("fallback", {
    "from": primary_pid,
    "to": "hermes_default",
    "reason": "primary_failed",
})
```

This provides an in-memory audit trail for the request. When `_commit_state()` is called (at every return path of `process_request()`), the events are flushed to `~/.hermes/fleet/events/{trace_id}.jsonl` and cleared from memory.

### Key Design Decisions

1. **`= None` on every method** — not `pipeline: PipelineState` (required). This is deliberate: it means existing callers (tests, one-off dispatches, the `--health` command) don't need to construct a PipelineState. Only the main `process_request` path creates one.

2. **No return type changes** — Methods that return `Optional[str]` continue to return `Optional[str]`. Methods that return `dict` continue to return `dict`. The pipeline state is a side channel, not the primary return value.

3. **`log_event` buffers in memory, `_commit_state` persists to disk** — The event buffer stays in-memory during the request. `_commit_state()` flushes to `~/.hermes/fleet/events/{trace_id}.jsonl` at the end of every request path. This separation keeps PipelineState lightweight (no file I/O during dispatch) while ensuring the audit trail survives crashes.

4. **`request_id` vs `trace_id`** — `request_id` is auto-generated by the dataclass. `trace_id` is the propagated identifier that links across dispatch boundaries. They could be the same value, but keeping them separate means you can seed the trace_id from an upstream system without overriding the local request identity.

## Trace ID Seeding

The trace_id links every stage of a single request pipeline. It's seeded at the entry point and threaded automatically through PipelineState:

```python
process_request(self, user_input, pattern="auto"):
    pipeline = PipelineState(user_input=user_input, start_time=time.time())
    trace_id = pipeline.trace_id  # 12 hex chars

    log.info(f"FLEET REQUEST #{n} [{trace_id}]: {user_input[:100]}")
```

The trace_id appears in:
- Log prefix: `[trace_id]` on every pipeline log line
- Event log: each `log_event` call carries the pipeline's trace_id
- Future event sourcing: filename = `{trace_id}.jsonl`

## Comparison with Other Approaches

| Approach | Change Surface | Safety | Gradual Adoption |
|----------|---------------|--------|-----------------|
| **Optional PipelineState** (this pattern) | Add param, never change return type | High — existing callers unchanged | ✅ Yes |
| **Global context** (thread-local) | Zero method signature changes | Low — implicit dependency, test brittleness | ❌ No |
| **Return PipelineState from everything** | Every caller must unwrap | Medium — compiler checks it | ❌ No |
| **Mutable class attribute** on manager | Zero signature changes | Low — implicit state, concurrency issues | ❌ No |
