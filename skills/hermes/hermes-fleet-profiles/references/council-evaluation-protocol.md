# Council Evaluation Protocol

> Structured evaluation format with blind peer review, borrowed from Karpathy's LLM Council.
> Implemented 2026-06-19 in `fleet-manager.py` — Phase 4 of the fleet pipeline.

## Overview

Replaces the simple Nemesis-128 "does it contain BUG?" substring check with a structured, multi-evaluator evaluation system. Every quality-sensitive task (code, wiki, content, deployment) now passes through:

1. **Nemesis-128** — primary QA evaluation (structured `FINAL_EVALUATION:` format)
2. **Peer reviewer** — blind second opinion from the worker's synergistic partner
3. **Aggregate scoring** — confidence-weighted consensus from both evaluators
4. **Ceres-1** — final review with full evaluation context

## `FINAL_EVALUATION:` Format

Every gate agent (Nemesis, Ceres) outputs evaluations in this parseable structured format:

```
FINAL_EVALUATION:
Score: 85/100
Verdict: PASS
Issues: minor edge case in boundary check
Confidence: 0.92
```

Fields:
- **Score** — 0-100 integer (may include /100 suffix)
- **Verdict** — PASS / BUG (Nemesis) or APPROVED / REJECTED (Ceres)
- **Issues** — free-text description of problems (or "None")
- **Confidence** — 0.0-1.0 float, evaluator's self-reported certainty

### Fallback Parsing

`parse_evaluation()` in fleet-manager.py is intentionally **lenient** — if no structured `FINAL_EVALUATION:` block is found, it falls back to substring matching:

| Pattern | Result |
|---------|--------|
| "PASS" or "APPROVED" (alone) | score=80, verdict=PASS |
| "BUG" or "REJECTED" (alone) | score=30, verdict=BUG |
| Both present | whichever appears LAST in text |

This ensures backward compatibility with agents that haven't been updated to output structured format.

## Peer Review Map

After a worker produces output and Nemesis has evaluated it, the pipeline dispatches a **second** evaluation from the worker's synergistic partner:

| Worker | Peer Reviewer | Why |
|--------|--------------|-----|
| Metis-9 (code) | Iris-7 (API/network) | Infrastructure perspective on code quality |
| Iris-7 (API request) | Artemis-105 (web search) | Consumer's viewpoint on API design |
| Artemis-105 (web search) | Fortuna-19 (data analysis) | Fact-check the results |
| Klio-84 (wiki/lit) | Kalliope-22 (content creation) | Content quality and coherence |
| Kalliope-22 (content) | Klio-84 (wiki/lit) | Wiki consistency and provenance |
| Fortuna-19 (data) | Mnemosyne-57 (memory/context) | Cross-reference against stored knowledge |
| Harmonia-40 (design) | Atalanta-36 (DevOps) | Deployment feasibility check |
| Atalanta-36 (DevOps) | Iris-7 (API/network) | Service-level perspective on infra changes |

The peer receives the same structured format instruction as Nemesis. Its output is parsed identically.

## Aggregate Scoring

After both evaluations are collected, `aggregate_evaluations()` computes:

- **Score** — confidence-weighted average (each evaluator's score × confidence / total confidence)
- **Consensus** — majority vote on verdict (PASS / BUG / SPLIT)
- **Confidence** — mean of evaluator confidence scores
- **n_evaluations** — how many evaluators participated

```python
def aggregate_evaluations(evaluations: list[dict]) -> dict:
    """Returns {avg_score, consensus, confidence, n_evaluations, evaluation_details}"""
```

## Updated 6-Phase Pipeline

```
User Input
    │
    ▼
Phase 1: Vesta-4 (Security) ──── quarantines malicious input, can halt fleet
    │
    ▼
Phase 2: Astraea-5 (Routing) ── one-sentence intent summary
    │
    ▼
Phase 3: Worker Dispatch ─────── routes to specialist (Metis/Iris/Klio/etc.)
    │                               OR → Hermes default (chat queries)
    ▼
Phase 4a: Nemesis-128 (QA) ───── structured FINAL_EVALUATION: format
    │                               (only for quality-sensitive tasks)
    │                               May trigger Metis-9 retry on BUG
    ▼
Phase 4b: Peer Review ────────── blind second opinion from synergistic partner
    │                               (same structured format)
    ▼
Phase 4c: Aggregate ──────────── confidence-weighted consensus
    │
    ▼
Phase 5: Ceres-1 (Review) ────── gets {worker_output + aggregate evaluations}
    │                               Judge output quality, NOT plan adherence
    │                               Outputs structured FINAL_EVALUATION:
    │
    ▼
Phase 6: Output ──────────────── structured score display with fallback
```

## What Changed in fleet-manager.py

| Component | Before | After |
|-----------|--------|-------|
| `parse_evaluation()` | Did not exist | Lenient parser + substring fallback |
| `aggregate_evaluations()` | Did not exist | Confidence-weighted consensus |
| `PEER_REVIEW_MAP` | Did not exist | 8 worker→partner mappings |
| Nemesis-128 prompt | Ad-hoc "PASS" or "BUG" | Structured `FINAL_EVALUATION:` format |
| `_check_nemesis_gate` | Returns `bool` | Returns `Tuple[bool, dict\|None]` |
| `_is_code_task` | Bool, code-only | `_needs_qa()` → str\|None, covers code+wiki+content+deploy |
| Ceres-1 prompt | Receives worker_output only | Receives worker_output + aggregate evaluations |
| Ceres output handling | Substring APPROVED/REJECTED | Structured + substring fallback |
| `_format_eval_for_prompt()` | Did not exist | Formats aggregate for Ceres prompt context |

## Quality-Sensitive Task Detection

`_needs_qa()` replaces `_is_code_task()` with broader coverage:

| Category | Keywords | Example |
|----------|----------|---------|
| Code | code, implement, function, build, deploy | "write a Python script" |
| Wiki | write, wiki, article, blog | "add a page about MCP" |
| Content | draft, content, narrative | "draft a blog post" |
| Deployment | deploy, ship, release | "deploy the auth service" |

Simple queries (chat, memory recall, status checks) skip QA entirely and go straight to Ceres (or directly to user).

## Ceres Gate Psychology

The `workflow_staged` prompt for Ceres-1 now explicitly instructs:

> "Judge ONLY whether the worker output answers the user's request. Do NOT evaluate pipeline execution, plan adherence, or routing decisions. Consider the evaluation scores and consensus."

This prevents the old anti-pattern where Ceres rejected output for "not following the planned pipeline" when the pipeline plan was irrelevant to output quality.

## Design Rationale

- **Blind peer review prevents groupthink:** Nemesis and the peer worker evaluate independently — they don't see each other's responses. This matches the LLM Council's anonymization pattern.
- **Confidence weighting prevents overconfident bad evaluators:** If one evaluator scores confidently but wrong, the weighted average dilutes their impact.
- **Fallback ensures zero breakage:** If any agent outputs old-style text, the parser degrades gracefully. The pipeline never hangs on a parse failure.
