# Fleet-Manager.py Refactor — Phases A-D (2026-07-03)

Full worked example of the `systematic-method-refactoring` methodology. Target: `fleet-manager.py` (3,457 lines, 69 methods).

## Baseline (before)

| Metric | Value |
|--------|-------|
| Total methods | 69 |
| Methods >100 lines | 10 |
| Average method size | 37 lines |
| Top 6 largest | process_request (171), _run_qa_gates (186), _route_to_worker (114), _clean_response (111), _ceres_retry_loop (107), _classify_task_keyword (69) |

## Phase A — Extract Pattern Handlers from `process_request`

**Target:** `process_request` (171 lines) — a routing switchboard with 5 inline pattern handlers.

**Approach:** Each `if pattern == "direct": ... elif pattern == "code": ...` block was cohesive (pattern-specific dispatch) and shared a return-type signature. Extracted each into its own method.

**Methods created:** `_handle_direct_pattern`, `_handle_code_pattern`, `_handle_single_worker_pattern`, `_handle_review_pr_pattern`, `_handle_complex_pattern`

**Result:** `process_request` 171→117 lines (−32%)

## Phase B — Extract Evaluation Stages from `_run_qa_gates`

**Target:** `_run_qa_gates` (186 lines) — QA pipeline with Ceres review, Eris second opinion, Kalliope doc gen.

**Approach:** The QA stages were already separated by comment blocks. Each used shared state (evaluations, current_output, worker_profile_id). Extracted as async methods that take the shared state as parameters.

**Methods created:** `_run_bug_fix_retry`, `_run_eris_second_opinion`, `_run_peer_review`

**Cleanup:** Removed 1 dead variable (`aggregate = aggregate_evaluations(evaluations)` — the result was never consumed). Consolidated OCR + sandbox context building into one block (was duplicated in two branches).

**Dead code removal:** Added `_prepare_qa_context` during extraction but it was NOT called in the replacement — the block it was extracted from was never reached. AST scan caught it. Removed.

**Result:** `_run_qa_gates` 186→97 lines (−48%)

## Phase C — Extract Keyword Constants

**Target:** 4 methods with duplicate inline keyword lists: `_classify_task_keyword`, `_route_to_worker`, `_predict_routing`, `_needs_qa`

**Approach:** Collected every inline keyword list across all 4 methods. Grouped by domain:
- `KW_CLASSIFY_*` — 8 lists for _classify_task_keyword (direct, wiki, code, code_review, search, complex, content, direct_phrases)
- `KW_ROUTE_*` — 5 lists for _route_to_worker and _predict_routing (wiki, search, code, content, plan_confirm_*)
- `KW_QA_*` — 3 lists for _needs_qa (code, wiki, content)

**Key insight:** `_route_to_worker` and `_predict_routing` used the EXACT same keyword lists — they had diverged from an earlier copy-paste. Using shared constants ensures they never diverge again.

**Result:** `_classify_task_keyword` 69→40 lines, `_route_to_worker` 114→100 lines (side benefit: removing inline list overhead)

## Phase D — Extract Ceres Retry Helpers

**Target:** `_ceres_retry_loop` (107 lines) — while loop with 3 distinct responsibilities: payload construction, approval handling, exhaustion handling, and worker retry.

**Approach:** Three extractions with different signatures:
- `_build_ceres_payload` — pure function, `@staticmethod`, 13 lines
- `_ceres_halt_fleet` — side-effectful (publishes event) + returns dict, async, 24 lines
- `_retry_worker_with_feedback` — returns `(updated_output, escalated_flag)` tuple, async, 27 lines

**Result:** `_ceres_retry_loop` 107→67 lines (−37%). The 3 helpers are individually testable — payload builder is pure, halt fleet is side-effect-only, retry worker returns a tuple for the caller to branch on.

## Final State

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Total methods | 69 | 80 | +11 focused helpers |
| Methods >100 lines | 10 | 5 | −50% |
| Average method size | 37 lines | 33 lines | −11% |
| _process_request | 171 | 117 | −32% |
| _run_qa_gates | 186 | 97 | −48% |
| _classify_task_keyword | 69 | 40 | −42% |
| _ceres_retry_loop | 107 | 67 | −37% |

## Key Techniques Found

1. **AST scan first** — lets you prioritize which methods to tackle and measure impact
2. **Insert helpers before the target method** — keeps discovery linear
3. **Compile verify after EVERY phase** — prevents cascading corruption from a bad patch
4. **Check for dead code after extraction** — extracted helpers may not be called by the replacement (a gap in the extraction logic)
5. **Keyword constants catch drift** — `_predict_routing` and `_route_to_worker` had diverged keyword lists from copy-paste; shared constants prevent future divergence
6. **Tuple return for branching** — `_retry_worker_with_feedback` returns `(value, bool)` so the loop body handles the control flow, not the helper. Cleaner than returning a pre-branched dict.
