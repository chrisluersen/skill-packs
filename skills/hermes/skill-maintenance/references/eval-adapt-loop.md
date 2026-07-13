# Eval-Adapt Loop for Skill Description Optimization

A systematic pipeline for optimizing skill trigger descriptions, adapted from the 17-file quality pipeline at `~/agent-wiki/Claude Skills/`.

## When to use

- A skill's description causes false positives or false negatives (skill triggers when it shouldn't, or doesn't trigger when it should)
- You're iterating a skill's description and need objective measurement
- You want to measure whether a description change actually improved trigger rates

## The Pipeline (3 Phases)

### Phase 1: Author

- Write the skill's SKILL.md with **progressive disclosure** — the description is the hook, the body is the detail
- Keep descriptions under 1024 characters (Claude Code limit)
- Descriptions should be **pushy, not neutral** — Claude undertriggers by default. Explain what the skill DOES, not what it's about. Use verbs, not nouns.

### Phase 2: Evaluate

**Core mechanism:** Create a `.claude/commands/<name>.md` file with the description, then test whether `claude -p` with a query triggers the `Skill` tool with that command name.

**Key implementation patterns:**
- Strip `CLAUDECODE` from env before subprocess calls (Claude Code guards against nesting; programmatic subprocess usage is safe)
- Use `stream-json` output format with `--include-partial-messages` for early trigger detection via `content_block_start` + `content_block_delta` events — catches triggering before the full message resolves
- Run queries in parallel via `ProcessPoolExecutor`

**Eval set format:**
```json
[
  {"query": "how do I install Hermes on Windows", "should_trigger": true},
  {"query": "what's the weather today", "should_trigger": false}
]
```

**Train/test split:** Stratified by `should_trigger` to prevent class imbalance. Holdout 30-40% for testing. Blind test scores from the improvement model to prevent overfitting.

### Phase 3: Iterate

Feed failures to an LLM (via `claude -p` subprocess) to generate a new description. The improvement model receives:
- Current description
- Eval results (pass/fail per query, with what went wrong)
- Past iteration history (with test scores blinded — strip `test_*` keys before passing)

Iterate until all train queries pass or max iterations reached.

## Metrics

- **Precision:** `TP / (TP + FP)` — how many triggers are correct
- **Recall:** `TP / (TP + FN)` — how many should-trigger queries actually trigger
- **Accuracy:** `(TP + TN) / total` — overall correctness

## Files in the Pipeline

| File | Purpose |
|------|---------|
| `run_eval.py` | Run trigger evaluation — parallel `claude -p` subprocesses with stream-json parsing |
| `improve_description.py` | Generate improved description based on failed queries |
| `run_loop.py` | Eval → improve → eval → improve loop with train/test split |
| `generate_report.py` | HTML report with train/test columns, per-query pass/fail |
| `aggregate_benchmark.py` | Aggregate multiple runs → benchmark.json with stats (mean/stddev/delta) |
| `package_skill.py` | Zip skill folder into distributable `.skill` file |
| `eval-viewer/` | SPA for human review of eval outputs (keyboard nav, auto-save feedback) |
| `agents/analyzer.md` | Post-hoc analysis agent |
| `agents/comparator.md` | Blind A/B evaluator |
| `agents/grader.md.md` | Grading agent against expectations |

## Pitfalls

- **Don't overfit to the training set.** Without a holdout set, the description will memorize train queries and fail on novel input. Always stratify by `should_trigger`.
- **Don't let the improvement model see test scores.** Strip `test_*` keys from history before passing to `improve_description`.
- **Descriptions get stale.** A description optimized for one model version may behave differently on another. Re-evaluate after model updates.
- **1024-char hard limit.** Descriptions over 1024 chars are silently truncated by Claude Code's command-file loader. Verify length before finalizing.