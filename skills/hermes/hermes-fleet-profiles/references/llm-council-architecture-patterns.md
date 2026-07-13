# LLM Council Architecture Patterns for Fleet Pub/Sub

**Source:** Karpathy's `llm-council` repo (https://github.com/karpathy/llm-council, 21K stars)
**Extracted:** 2026-06-19
**Relevance:** The 3-stage council pattern is a concrete design for the fleet pub/sub event bus — moving from linear dispatch (Astraea→Worker→Nemesis→Ceres) to distributed peer review.

---

## The 3-Stage Pattern

| Stage | Council | Fleet Equivalent |
|-------|---------|-----------------|
| **1. Parallel Collection** | All models answer simultaneously via `asyncio.gather()` | Publish task to all relevant workers via pub/sub. Workers respond independently. |
| **2. Anonymous Peer Review** | Each model evaluates all OTHER responses with model names hidden (Response A/B/C labels). Models don't know who they're ranking. | Distributed QA: every worker that produced output also reviews 2-3 other workers' outputs before Nemesis/Ceres touch it. Single-gate bias eliminated. |
| **3. Chairman Synthesis** | A designated chairman model receives ALL responses + ALL peer rankings + agreement/disagreement patterns → produces a single synthesized final answer | Ceres upgrades from pass/fail to synthesis: "Here's what the fleet agreed on, here's where they diverged, here's my recommendation." |

## Implementation Tricks Worth Stealing

### 1. Anonymization Map

```python
# Create labels to hide model identity during peer review
labels = [f"Response {chr(65+i)}" for i in range(len(responses))]
label_to_model = {f"Response {chr(65+i)}": model for i, model in enumerate(models)}

# Shuffle labels so position doesn't leak identity
import random
shuffled_labels = list(label_to_model.keys())
random.shuffle(shuffled_labels)

# Models only see labels, never model names
# De-anonymization happens client-side or in the final synthesis stage
```

The `label_to_model` map is critical — it lets the chairman de-anonymize for the final synthesis without leaking identities during peer review.

**Key nuance:** Shuffle labels BEFORE presenting them to reviewers. If Response A is always the first model in the config list, models can infer "Response A is Gemini because it always goes first." Shuffle breaks this.

### 2. Structured Evaluation Format

The most brittle part of the pipeline is parsing free-form evaluation output. Karpathy solved it with a strict format:

```
FINAL RANKING:
1. Response C
2. Response A
3. Response B
```

The `parse_ranking_from_text()` function:
1. First searches for `FINAL RANKING:` header
2. Parses `\d+\.\s*Response [A-Z]` under it
3. Falls back to finding any "Response X" patterns in order if the header is missing

**For the fleet:** Nemesis and Ceres should output evaluations in this exact format so downstream tooling can parse rankings and aggregate scores. Standardizing the format across all gate agents is the goal — parser-friendly output.

### 3. Aggregate Ranking (Crowd Consensus)

```python
def calculate_aggregate_rankings(stage2_results, label_to_model):
    """Average rank position across all peer evaluations."""
    rank_sums = defaultdict(int)
    rank_counts = defaultdict(int)
    
    for ranking in stage2_results:
        for i, label in enumerate(ranking["parsed_ranking"]):
            # i is the rank position (0 = best), lower is better
            rank_sums[label] += i
            rank_counts[label] += 1
    
    aggregate = {}
    for label, total in rank_sums.items():
        model = label_to_model[label]
        aggregate[model] = {
            "avg_position": total / rank_counts[label],
            "n_evaluations": rank_counts[label]
        }
    return aggregate
```

This gives Ceres a **confidence signal**: if all 4 workers agree that Response A is best (avg_position ≈ 0), consensus is strong. If scores are spread across responses, the chairman should note the disagreement.

**Fleet equivalent:** Ceres receives not just "this output passed" but a ranked consensus from the distributed review. A "pass with strong consensus" vs "pass with split opinions" distinction.

### 4. Graceful Degradation

```python
async def query_models_parallel(models, messages):
    """Query all models. Individual failures return None — don't block the pipeline."""
    tasks = [query_model(model, messages) for model in models]
    responses = await asyncio.gather(*tasks)
    return {model: response for model, response in zip(models, responses)}
```

If 2 of 4 models fail, the pipeline proceeds with the 2 that succeeded. No retries, no cascading failures.

**Fleet equivalent:** If Fortuna-19 is down when a data-analysis task is published, the workers that DID respond still get reviewed and synthesized. The chairman notes the absence.

### 5. SSE Streaming for Multi-Stage Work

```python
# Server-Sent Events for real-time stage visibility
events:
  stage1_start → stage1_complete
  stage2_start → stage2_complete
  stage3_start → stage3_complete
  complete
  error
```

Each event carries typed data: `{"type": "stage1_complete", "data": [...]}`. The frontend can update progress without polling.

**Fleet equivalent:** The pub/sub bus already has channels. Each fleet stage (Vesta check → Astraea routing → Worker execution → Nemesis QA → Ceres review) should emit a status event on a `fleet/status` channel that a dashboard or log aggregator can subscribe to.

---

## What NOT to Borrow from This Repo

| Thing | Why Skip |
|-------|----------|
| React frontend | Fleet pub/sub doesn't need a web UI for internal coordination |
| JSON file storage (`data/conversations/`) | Wiki + SQLite already exist for persistence |
| OpenRouter-specific client | The fleet already uses Nous Portal; the parallel-query pattern is the only transferable part |
| The "vibe code" quality | This was Karpathy's Saturday hack — take the architecture idea, not the code quality |

---

## How to Integrate Into Fleet

### Phase 1: Add Anonymous Peer Review Stage

Currently: Worker → Nemesis (single gate QA) → Ceres (single gate review).

Change to: Worker → 2-3 peer workers review anonymized output → Nemesis weighs peer reviews → Ceres synthesizes.

### Phase 2: Standardize Evaluation Format

Add the `FINAL RANKING:` format to all Nemesis and Ceres prompts. Add `parse_ranking_from_text()` and `calculate_aggregate_rankings()` to `fleet-manager.py`.

### Phase 3: Add Chairman Synthesis Mode

Instead of Ceres just returning pass/fail, add a mode where Ceres synthesizes:
- What all workers agreed on
- Where they diverged
- How the peer rankings leaned
- A recommended course of action

### Phase 4: Pub/Sub Status Events

Emit typed events on each stage transition for observability:
```python
await self.publish("fleet/status", {
    "stage": "worker_complete",
    "agent": "metis_9",
    "status": "success",
    "duration_s": 45.2
})
```
