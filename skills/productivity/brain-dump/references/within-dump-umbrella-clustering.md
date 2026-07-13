# Within-Dump Umbrella Clustering — 2026-07-22 Session

## Context

user did 2 brain dumps in one session. The second dump was 4 resume/learning skills — all clearly part of one learning track (ML/GPU engineering), not 4 independent entities.

## The Pattern

**Problem:** The skill's Step 4 originally said "For each Task item, create a task entity page." A naive agent would create 4 separate entity pages for items that should be 1 umbrella.

**Fix applied:** Before creating entities, scan Task items within a single dump for thematic siblings. If 3+ items clearly belong to one learning track, project, or domain → one umbrella entity with sub-items in Notes.

## Concrete Example

**Dump input (2026-07-22-235600):**
```
• C++ / Python / CUDA
• Deep Learning & Neural Networks
• GPU Architecture
• Performance Modeling & MLPerf
```

**Decision:** All 4 are "build ML/GPU engineering skills for my resume." One umbrella entity `ml-gpu-engineering-skills.md` with:
- `task_priority: p2`
- `task_effort: ~ongoing`
- Notes section listing all 4 sub-items
- No separate entities created for each skill

**If they'd been independent** (e.g. "organize files on PC", "fix router config", "research RAG"):
→ separate entities, no umbrella needed. Threshold is 3+ clearly related items.

## Contrast with Cross-Dump Clustering

| Axis | Within-Dump (this session) | Cross-Dump (2026-06-23) |
|------|--------------------------|-------------------------|
| Trigger | 3+ related Task items in one dump | 3+ related items across multiple dumps |
| When to check | During Step 4, before creating entities | After each dump in a consecutive chain, before confirmation |
| What to create | One umbrella entity, sub-items in Notes | Umbrella entity + `has_part`/`part_of` edges to existing entities |
| Source linking | Single source in `sources[]` | Multiple sources appended to `sources[]` |

## Key Insight

The within-dump clustering pre-check prevents entity bloat. Without it, 4 learning skills → 4 entities. With it → 1 umbrella that's easier to track, prioritize, and close out.
