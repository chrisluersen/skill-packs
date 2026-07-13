# Task Routing Cost Analysis — Burn-Rate Methodology

A systematic procedure for evaluating a multi-phase plan's token cost profile and deciding which tasks to route to cheap agents vs strong models vs scripts.

## When to Use

- The user asks: "what's expensive in this plan?"
- The user asks: "should I make dedicated agents for these tasks?"
- You're planning a large batch of work and need to decide execution order by cost
- A new cheap agent (like Klio) becomes available and you need to know what to route to it

## The Methodology

### Step 1 — Enumerate all remaining tasks

List every phase/subtask that hasn't been done yet. For each, record:

| Field | Meaning |
|-------|---------|
| **Phase** | Plan phase identifier (e.g. "Phase 10a", "Phase 7d") |
| **Task** | One-line description |
| **Type** | Content / Coding / Research / Ops |
| **LLM turns** | Estimated conversation turns (1 turn ≈ 2 tool calls + 1 response) |
| **Data volume** | Chars read per run (sources, web pages, files) |
| **Reasoning depth** | Low / Medium / High |

**Example enumeration:**
```
Phase 10a — profiles.md expansion | Content | 5-8 turns | 50K chars | Low (copy+summarize)
Phase 8h — scaffold_page.py       | Coding  | 3-5 turns | 10K chars | High (write correct Python)
```

### Step 2 — Estimate token burn

Per task, compute:

```
Input tokens per turn  = system_prompt_overhead + data_volume_per_turn
Output tokens per turn = target_response_size

Total tokens           = ∑(input + output) × estimated_turns
```

**Fixed overhead per session (current profile):**
| Component | Tokens |
|-----------|:------:|
| System prompt + persona | ~3,000 |
| Memory + user profile | ~1,400 |
| Skills list (189 skills) | ~5,700 |
| Tool definitions (40+ tools) | ~6,000 |
| Context compaction | ~3,000 |
| **Per-session fixed** | **~19,000–22,000** |

**Lightweight profile overhead (31 skills, trimmed persona, 6 toolsets disabled):**
| Component | Tokens |
|-----------|:------:|
| System prompt + persona | ~520 (1.4KB SOUL.md) |
| Memory + user profile | ~240 |
| Skills list (31 skills) | ~930 |
| Tool definitions | ~4,000 |
| Context compaction | ~3,000 |
| **Per-session fixed** | **~11,000–13,000** |

**Savings:** ~40% reduction in fixed overhead (~9K tokens/session).

**Per-turn variable cost:**
| Action | Typical tokens |
|--------|:--------------:|
| web_extract a page (5K chars) | ~2,000 input |
| read_file of source doc (20K chars) | ~8,000 input |
| write_file of final page (6K chars) | ~2,400 output |
| synthesize_answer + read results | ~5,000 input |
| Terminal command + output | ~2,000 input |

**Model costs (standard rates, per 1M tokens):**
| Model Tier | Input/M | Output/M | Examples |
|------------|:-------:|:--------:|:---------|
| Free | $0 | $0 | Gemini Flash free tier, Nemotron free |
| Cheap | $0.30 | $2.50 | Gemini 2.5 Flash |
| Mid | $0.50 | $4.00 | DeepSeek V4 Flash |
| Premium | $3.00 | $15.00 | Claude Sonnet, DeepSeek V3 |
| Expensive | $15.00 | $75.00 | Claude Opus, o3 |

### Step 3 — Compute waste ratio

Waste ratio = cost_on_strong_model / cost_on_cheap_model

```
Waste ratio = 1.0  → Same cost (content irrelevant)
Waste ratio = 5×   → Strong model is 5× more expensive (mild waste)
Waste ratio = 10×+ → Strong model is 10×+ more expensive (clear waste)
Waste ratio = <2×  → Not worth routing — overhead of routing costs more than savings
```

**Rule of thumb from this session:** Any task with waste ratio ≥5× AND ≤Medium reasoning depth should be deferred to a cheap agent. Anything with High reasoning depth or waste ratio <2× should run on the main session.

### Step 4 — Classify tasks

| Class | Waste Ratio | Reasoning | Route To | Action |
|:-----:|:-----------:|:---------:|:---------|:-------|
| 🔴 **Defer** | ≥5× | Low-Medium | Cheap agent (Klio / Gemini 2.5 Flash) | Schedule as cron batch or one-shot cron with model override |
| 🟡 **Maybe** | 2-5× | Medium | Either | Depends on batch size — batch of 5+ → route for ~15× cumulative savings |
| 🟢 **Do now** | <2× | Medium-High | Main session | Needs strong reasoning; routing would cause rework cost |

**Example classification:**
```
🔴 Feed backlog (42 articles)   → 10-20× waste, low reasoning → DEFER to Klio
🔴 Phase 10 page expansions (11) → 5-7× waste, low reasoning → DEFER to Klio
🟢 Phase 8 tooling (scaffold script) → <2× waste, high reasoning → DO NOW
🟢 Phase 9 ops integrity         → <2× waste, any reasoning → DO NOW (trivial cost anyway)
```

### Step 5 — Present a prioritized routing plan

Format: a single table prioritized by waste ratio (highest first):

| Priority | Task | Waste Ratio | Route | Est. Now | Est. With Klio | Savings |
|:--------:|:-----|:-----------:|:------|:--------:|:--------------:|:-------:|
| 🥇 | Feed backlog (42 articles) | 10-20× | Klio | $4-10 | $0.50 | $3.50-9.50 |
| 🥈 | Phase 7d bookmarks | 7-10× | Klio | $2-3 | $0.30 | $1.70-2.70 |
| 🥉 | Phase 10 page expansions | 5-7× | Klio | $1.65 | $0.25 | $1.40 |
| 4 | Phase 8 tooling | <2× | Main session | $1-3 | Can't (wrong model) | N/A |

### Step 6 — Decide on agent architecture

After the burn-rate analysis, the user will ask "should I create specialized agents for this?"

**Decision tree:**

```
Is waste ratio ≥5× on any task?
├── No → Keep current setup. No new agents needed.
├── Yes → Is batch size ≥5 items?
│   ├── No → Handle ad-hoc via one-shot cron with model override
│   └── Yes → Consider options:
│       ├── Hermes profile (lightest) — separate profile with cheap model + minimal tools
│       │   Pros: zero infra, built-in, transparent
│       │   Cons: manual switch, one at a time
│       │   When: single task type (e.g. "wiki-worker")
│       │
│       ├── Dedicated agent (like Klio) — cron-based, autonomous
│       │   Pros: fully automatic, scheduled, persistent
│       │   Cons: cron setup, failure handling, state management
│       │   When: recurring on schedule (e.g. weekly maintenance)
│       │
│       └── More profiles + restricted delegation (recommended default)
│           Pros: covers 80% of need, minimal management
│           Cons: doesn't replace recurring cron work
│           When: 2-3 task classes, nothing that needs its own schedule
```

## One-Time Optimization vs Recurring Operations

| Dimension | One-time (phase closure) | Recurring (maintenance) |
|-----------|:------------------------:|:-----------------------:|
| Example | Phase 10 page expansions | Weekly lint + edges |
| Pattern | One-shot cron with model override | Persistent cron with schedule |
| Cost per run | ~$0.09-0.15 | ~$0.01-0.02 |
| Automation | Manual trigger | Fully automatic |
| Failure handling | User notified if broken | Autonomous recovery (see Klio failure recovery) |

## Worked Example — This Session

The burn-rate analysis run on 2026-06-17 for PLAN.md phases 7-10:

**Inputs:**
- Main model: DeepSeek V4 Flash (~$0.50/M input, ~$4.00/M output)
- Cheap model: Gemini 2.5 Flash (~$0.30/M input, ~$2.50/M output)
- Per-session overhead: ~22K tokens (~$0.009-0.011 on main model)

**Enumeration results:**

| Task | Turns | Data/run | Reasoning | Main model cost | Cheap model cost | Waste ratio |
|:-----|:-----:|:--------:|:---------:|:---------------:|:----------------:|:-----------:|
| Feed backlog (42 articles) | 3-5/task | 5-20K | Low | ~$0.10-0.24/ea | ~$0.01-0.02/ea | **10-20×** |
| Bookmark ingest (30 URLs) | 3-5/task | 5-50K | Low | ~$0.07-0.10/ea | ~$0.01/ea | **7-10×** |
| Phase 10 page expansion (11) | 5-8/task | 10-30K | Low | ~$0.15/ea | ~$0.02/ea | **7×** |
| Phase 8 tooling | 3-5 total | 5-10K | High | ~$1-3 total | Wrong model | <2× |
| Phase 9 ops | 1-2/task | 2-5K | Low-Med | ~$0.02-0.05 | ~$0.01 | <2× |

**Routing decision:** Profiles + restricted delegation (more agents not needed — Klio + wiki-worker profile cover 90% of the waste). Tasks above 5× waste deferred, others executed now on main session.

## Quick Checklist

When the user asks "what should I defer / what should I route where":

- [ ] Enumerate all remaining tasks from the plan
- [ ] For each: estimate LLM turns, data volume, reasoning depth
- [ ] Compute per-task cost on current model vs cheap alternative
- [ ] Calculate waste ratio (strong ÷ cheap)
- [ ] Classify: 🔴 ≥5× waste → defer | 🟡 2-5× → consider batch | 🟢 <2× → do now
- [ ] Present as prioritized table sorted by waste ratio
- [ ] Determine architecture: profiles vs dedicated agent vs one-shot cron
- [ ] For 🔴 tasks: confirm with user, then create cron/schedule/note
- [ ] For 🟢 tasks: execute immediately or queue for next session
