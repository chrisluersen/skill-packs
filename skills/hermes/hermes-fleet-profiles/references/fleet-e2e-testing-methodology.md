# Fleet E2E Testing Methodology

**Session origin:** 2026-06-23
**Purpose:** Systematic validation of the multi-agent fleet pipeline — worker behavior, gate accuracy, latency, and error recovery.

## Test Design

### Worker Selection

Pick representative workers from each domain category. Test at least one per category:

| Category | Example Worker | Why This Category |
|----------|---------------|------------------|
| Code | Metis-9 (or OpenCode for v2) | Most complex output — hardest to get right |
| Search | Artemis-105 | Simple input, well-structured output — baseline for "good" |
| Content | Kalliope-22 | Free-form output — tests preamble and verbosity gates |
| Wiki | Klio-84 | Domain-specific retrieval — tests hallucination gates |
| Data | Fortuna-19 (if present) | Math/analytics — tests precision |

### Test Tasks

Design tasks that are:
1. **Unambiguous** — a clear right answer exists
2. **Domain-appropriate** — matches the worker's specialization
3. **Minimal** — short enough to complete in 1-2 turns

Examples from the 2026-06-23 E2E run:

| Category | Test Task | Why This Task |
|----------|-----------|---------------|
| Code | "Write a Python script that renames all .txt files in a directory to have a .md extension. Show the code." | Simple, production-relevant, unambiguous |
| Search | "Search the web for the latest news about Hermes Agent updates and releases" | Tests web tool access, source citation |
| Wiki | "Search the wiki for information about Hermes Agent skills and how they work" | Tests FTS5 wiki search, domain knowledge |
| Content | "Write a short blog post about the benefits of using AI agents for task automation" | Tests free-form output, preamble detection |

### Test Execution

**Method:**
1. Dispatch each test task via `fleet-manager.py`
2. Record: routing target, each phase's response time, Ceres score, final output
3. Collect ALL test results before analyzing — don't draw conclusions mid-run

**Metrics to capture per test:**

```
Task: "Write a Python script..."
Route: → Metis-9 (code)                        [routing accuracy]
Phase 2 (Astraea): 28.7s                       [decomposition latency]
Phase 3 (Worker): 37.2s                        [execution latency]
Phase 4 (Nemesis): 25.1s, score 97/100         [QA accuracy]
Phase 5 (Ceres): 24.8s, score 95/100           [final review accuracy]
Total: 135.6s                                   [end-to-end latency]
Retries: 1                                      [error recovery count]
```

### Scoring Criteria

| Score Range | Meaning | Action |
|-------------|---------|--------|
| 100-90 | Excellent. Direct answer, no preamble, correct. | Keep profile. |
| 89-70 | Good. Minor issues (slight preamble, formatting). | Minor polish. |
| 69-50 | Poor. Missing target, significant preamble, partial hallucination. | Rethink profile. |
| 49-0 | Failed. Hallucination, non-responsive, or false output. | Rebuild from scratch. |

### Diagnosis of Failures

When a worker scores < 70:

1. **Check output for preamble** — "I shall", "I have consulted", "As an AI" → profile is too theatrical. Strip mythological language. Move to [ROLE]/[BEHAVIOR]/[OUTPUT]/[RULES] pattern.
2. **Check for hallucination** — Output discusses a different topic entirely → rules are too weak. Add explicit "Do not fabricate" in [RULES]. Reduce temperature.
3. **Check for non-responsiveness** — Output is meta-commentary ("I need the code to proceed") → profile is confused about its role. Tighten [ROLE] to one sentence.
4. **Check routing** — Output is well-formed but on wrong topic → routing misclass. Fix keyword priority in `_route_to_worker()`.
5. **Check gates** — Good output but Ceres rejected it → gate criteria too strict or gate is judging plan adherence (historical bug). Ensure Ceres judges OUTPUT, not PROCESS.

### Scoring Consistency

Ceres-1 scores are THE canonical metric. If multiple test runs of the same query produce scores that differ by > 20 points, the profile is unstable — retest 3 times and take the median.

If Ceres-1 itself is unreliable (inconsistent scores for identical output), the gate profile needs fixing before worker profiles can be meaningfully tested.

## E2E Test Report Template

```
## E2E Test Results — YYYY-MM-DD

### Configuration
- Pipeline version: [v1 / v2]
- Workers tested: [list]
- Provider: [nous / openrouter]
- Model: [deepseek-v4-flash / gemini-2.5-flash]

### Results

| Worker | Task | Route | Ceres Score | Latency | Retries | Verdict |
|--------|------|-------|-------------|---------|---------|---------|
| [name] | [summary] | [target] | [0-100] | [sec] | [n] | ✅/❌ |

### Diagnostics

- Routing accuracy: [X/Y correct]
- Avg latency per phase: [sec]
- Top failures: [list with root causes]

### Action Items

1. [Urgent fix needed]
2. [Minor polish]
3. [Deferred]
```

## Reference

For full diagnostic data from the 2026-06-23 E2E run, see `~/Vault/wiki/pending/fleet-optimization-initiative.md` in the wiki.

For Phase 7 verification results (all 7 flow patterns, bug fix, latency data), see [`fleet-e2e-phase7-verification.md`](references/fleet-e2e-phase7-verification.md) in the hermes-fleet-profiles skill.
