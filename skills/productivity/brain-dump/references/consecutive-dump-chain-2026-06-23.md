# Consecutive Dump Chain — 2026-06-23 Session

## Context

user fired off 3 brain dumps in rapid succession during a single session. Each was a pasted list of ~10 items. Full transcript in session `@session:default/<session-id>`.

## What Happened

| # | Time | Items | Raw Saved | Entities Created | Umbrellas |
|---|------|-------|-----------|------------------|-----------|
| 1 | 00:49 | 6 | `2026-06-23-004933-raw-dump.md` | 6 (all new) | — |
| 2 | 00:53 | 11 | `2026-06-23-005340-raw-dump.md` | 8 (3 notes) | `finish-building-wiki` (P1) |
| 3 | 00:56 | 10 | `2026-06-23-005636-raw-dump.md` | 7 (1 linked to existing, 2 merged) | `consolidate-everything` (P1) |

## Dedup Decisions

### Dump 3 → Dump 1 collision

**Item:** "Organize Files" (dump 3, item 2)
**Existing entity:** `organize-files-on-pc` (created from dump 1, item "organize files on pc")

**Action:** Patched existing entity — added dump 3 as second source in `sources[]` and `relates_to`. Created a `rel: part_of` edge to the new `consolidate-everything` umbrella. Did NOT create a duplicate entity.

**Patch applied:**
```yaml
relates_to:
  - target: braindump-20260623-004933    # original source
    rel: source
  - target: braindump-20260623-005636    # new source
    rel: source
  - target: set-up-protected-backup-folder
    rel: related
  - target: consolidate-everything       # new umbrella parent
    rel: part_of
sources:
  - file: braindumps/2026-06-23-004933-brain-dump.md
  - file: braindumps/2026-06-23-005636-brain-dump.md  # appended
```

### Dump 3 → Dump 2 collision

**Item:** "Clean default pc" (dump 3, item 9)
**Existing entities:** `organize-files-on-pc` (dump 1) + `debloat-pc` (dump 3, item 6)

**Action:** Marked as "merged into items 2+6" in the brain dump table. No entity created.

## Umbrella Creation

### `finish-building-wiki` (P1, ongoing)
Created from dump 2. Wraps:
- `build-out-wiki-sections`
- `ingest-pc-files-into-wiki`
- `clean-up-leftover-wiki-projects`
- `improve-wiki-task-manager`

Frontmatter: `rel: has_part` to each sub-entity. Each sub-entity has `rel: part_of` back.

### `consolidate-everything` (P1, ~3+ hrs)
Created from dump 3. Wraps 7+ sub-tasks including items from all 3 dumps:
- `organize-files-on-pc` (dump 1)
- `debloat-pc` (dump 3)
- `debloat-home-directory` (dump 3)
- `merge-apple-notes-into-wiki` (dump 3)
- `aggregate-project-files` (dump 3)
- `unify-plan-files` (dump 3)
- `remove-extra-hermes-installs` (dump 3)
- Also `rel: related` to `extract-bookmarks` (pre-existing entity)

## Raw Save Strategy

All 3 raw dumps were saved BEFORE parsing — interleaving raw saves:
1. Read the paste
2. `write_file` to `*-raw-dump.md` (verbatim, no parsing)
3. Then parse, categorize, create structured dump + entities
4. Then reindex + rebuild dashboard

This prevented compaction loss across ~30 tool calls across 3 dump iterations.

## Dashboard Impact

- Started at 41 active tasks (pre-session)
- After dump 1: 58 active tasks
- After dump 2: 66 active tasks
- After dump 3: 74 active tasks
- Final: 74 active + 2 blocked + 4 completed (+33 tasks total)
