# Fleet Dynamic Routing — Decision Tree Implementation

> Implemented 2026-06-23 as Phase 6 of the fleet optimization initiative.
> Transforms the rigid 5-phase pipeline into a pattern-based dispatcher.

## The Problem

The old `process_request()` forced every request through all 5 phases:
Vesta-4 (security) → Astraea-5 (decomposition) → Worker → Nemesis-128 (QA) → Ceres-1 (review)

That's ~135s for every request — even "hello" and "what time is it?" Research confirmed sequential pipelines degrade performance 39-70% vs dynamic routing for most tasks.

## The Solution

Refactor `process_request()` into a **decision-tree dispatcher** that selects the optimal execution path per request.

### Architecture

```
process_request(user_input, pattern="auto")
  │
  ├─ Security: Vesta-4 screening (ALWAYS — non-negotiable)
  │
  ├─ pattern="pipeline" → _run_sequential_pipeline() (preserved legacy)
  │
  └─ pattern="auto" → _classify_task(user_input)
       │
       ├─ "direct"   → Hermes default profile. No worker dispatch.
       ├─ "wiki"     → Klio-84. Single worker, no gates.
       ├─ "search"   → Artemis-105. Single worker, no gates.
       ├─ "data"     → Fortuna-19. Single worker, no gates.
       ├─ "design"   → Harmonia-40. Single worker, no gates.
       ├─ "code"     → Metis-9 gen + optional QA gates.
       ├─ "complex"  → _run_sequential_pipeline() (full pipeline).
       └─ fallback   → _run_sequential_pipeline().
```

### Latency by Pattern

| Pattern | Hops | Est. Time | Use Case |
|---------|------|-----------|----------|
| direct | 0 | ~2s | Greetings, status, config |
| worker (wiki/search/data/design) | 1 | ~27s | "Search the wiki for X" |
| code | 1-2 | ~27-54s | "Write a script that..." |
| complex/pipeline | 5+ | ~135s | "Deploy CI pipeline" |

### _classify_task() Keyword Classifier

The classifier uses keyword matching ordered by specificity.

**⚠️ Crucial pitfall — short keywords need `text.split()`, not substring match.** A naive `kw in text` check for single-word keywords like `"hi"` matches as a substring of `"this"`. This caused `"analyze this data"` to be classified as `"direct"` (because `"hi" ∈ "this"`). Always use `text.split()` for short keywords (under 5 characters or single-word social tokens) to enforce word-boundary matching. Multi-word keywords like `"thank you"` are safe with substring match.

```python
def _classify_task(self, user_input: str) -> str:
    text = user_input.lower().strip()
    
    # 1. Direct — short social queries
    # SHORT keywords use text.split() to prevent substring false positives
    if len(text) < 60 and any(kw in text.split() for kw in [
        "hello", "hi", "hey", "thanks", "ok", "okay",
        "yes", "no", "goodbye", "bye",
    ]):
        return "direct"
    # LONGER/multi-word keywords still safe with substring match
    if any(kw in text for kw in [
        "thank you", "what time", "what date",
        "who are you", "what can you", "help", "status",
    ]) and len(text) < 60:
        return "direct"
    
    # 2. Wiki — dedicated worker (checked before search)
    if any(kw in text for kw in ["search the wiki", "wiki page", ...]):
        return "wiki"
    
    # 3. Design — dedicated worker
    if any(kw in text for kw in ["design", "color palette", ...]):
        return "design"
    
    # 4. Data — dedicated worker
    if any(kw in text for kw in ["analyze", "analysis", "trend", ...]):
        return "data"
    
    # 5. Code — worker with optional QA
    if any(kw in text for kw in ["write code", "implement", ...]):
        return "code"
    
    # 6. Search — generic information seeking
    if any(kw in text for kw in ["search for", "find", "look up", ...]):
        return "search"
    
    # 7. Complex — needs Astraea decomposition
    if any(kw in text for kw in ["set up", "deploy", ...]) or len(text) > 200:
        return "complex"
    
    # Default: web search (most common pattern)
    return "search"
```

**Ordering rules:**
- **Specific before generic.** Wiki checked before search (prevents "search the wiki" → Artemis).
- **Short text with social keywords → direct.** Prevents "hello" from hitting a worker.
- **Design before search.** "Design a layout" should go to Harmonia, not Artemis.
- **Long text → complex.** Over 200 chars likely needs decomposition.
- **`text.split()` for short keywords, `in` for multi-word.** `"hi" ∈ "this"` is a real bug.
- **Test structurally before deploying.** Run 15-20 test cases through `_classify_task()` in isolation before running live dispatches. This catches false positives that dispatch tests never surface (because they time out on the first hop before reaching the worker). Structural testing found the "hi in this" bug — dispatch testing never would have.

### Testing the Decision Tree

The classifier should be verified structurally before any live dispatch tests. Dispatch-level tests take ~27s per hop and time out, making it hard to iterate on edge cases.

**Methodology:**
1. Extract `_classify_task()` logic into a standalone function
2. Write test cases for each expected pattern (direct, wiki, design, data, code, search, complex)
3. Include edge cases: "hi", "analyze this data", "status", literal wiki: syntax
4. Fix false positives until all cases pass
5. Only then run a live dispatch to confirm the log shows the correct pattern

Found bugs via structural testing (2026-06-23):
- `"analyze this data"` → direct (false positive: `"hi" ∈ "this"`) — fixed with `text.split()`
- Long ambiguous strings with no explicit keywords → complex (was defaulting to search)

### _run_qa_gates() — Extracted QA Pipeline

The Nemesis → Peer Review → Ceres review chain was extracted from the old monolithic process_request into a reusable method:

```python
async def _run_qa_gates(self, worker_response, user_input, worker_profile_id):
    # 1. Nemesis-128 evaluation with early abort
    # 2. Bug fix retry (one retry on score < 50)
    # 3. Peer review from synergistic partner (PEER_REVIEW_MAP)
    # 4. Aggregate evaluations
    # 5. Ceres-1 final review gate (fail-closed, retry loop, escalation)
    return result
```

This lets code, complex, and pipeline patterns all share the same QA chain without duplicating the logic.

### _run_sequential_pipeline() — Preserved Legacy

The old full pipeline is preserved for complex/deterministic tasks:

```
Vesta-4 → Astraea-5 → _route_to_worker() → _run_qa_gates()
```

Astraea-5 is only invoked when decomposition is genuinely needed (complex/pipeline patterns), not for every request.

## Key Design Decisions

1. **Vesta-4 always fires.** Security screening is non-negotiable even for "direct" patterns. The ~2s cost is acceptable safety overhead.

2. **Gates are optional.** Workers with task-first profiles (Klio, Artemis, Fortuna, Harmonia) dispatch without gates. Only code gen and complex tasks hit Nemesis → Ceres.

3. **Explicit "pipeline" override.** Pattern can be passed explicitly for deterministic multi-stage tasks (contract gen, batch processing) that genuinely need the full chain.

4. **Old pipeline preserved as `_run_sequential_pipeline()`.** Not deleted — just made opt-in. Easy to restore as default if needed.

5. **Keyword classifier is stateless.** No ML, no LLM call just to classify. Fast, predictable, debuggable.

## When to Apply This Pattern

Any multi-agent system with a rigid pipeline that processes ALL requests through ALL stages. Signs you need this:

- Every request takes the same latency regardless of complexity
- Simple queries ("what's the weather") go through 5 hops when 0 would do
- Agents that don't contribute to some request types still consume context budget
- Pipeline stages are mandatory, not conditional

## Relation to Other Patterns

| Pattern | Relationship |
|---------|-------------|
| Sequential pipeline (old) | Preserved as `_run_sequential_pipeline()` — available for tasks that genuinely need it |
| Orchestrator decision tree | This is the *implementation* layer. The orchestrator (Iris-7) makes the same routing decisions at a higher level — this is the fleet-manager.py instantiation |
| Worker dispatch with fallback | `_dispatch_with_fallback()` routes to Hermes default on timeout/error — stays unchanged |
| QA gates | `_run_qa_gates()` extracts the Nemesis → Peer Review → Ceres chain into a reusable callable |
