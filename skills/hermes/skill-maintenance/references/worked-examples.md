# Worked Examples: Skill Consolidation

Three consolidation passes across the wiki skill ecosystem. These examples show the full lifecycle: audit, absorb, cross-reference sweep, verify.

## Example 3: Wiki Skill Consolidation (2026-07-20)

**Context:** 12 wiki-related skills with heavy overlap. `wiki-planning` and `llm-wiki` shared ~60% content (Karpathy pattern, three-layer architecture, cross-linking discipline). `wiki-health-doctor` and `wiki-operations` shared ~70% (lint/fix/extract pipeline). `add-next-actions` and `bulk-entity-enrichment` were sub-workflows of `wiki-entity-management`.

**Outcome:** 12 skills → 7. ~50K redundant content eliminated. Coordinator skill (Klio) updated with companion skills reference table.

### Skills Consolidated

| Retired | Absorbed Into | What Moved |
|---------|---------------|------------|
| `wiki-health-doctor` | `wiki-operations` | Health pipeline (Diagnose→Fix→Extract→Verify), gbrain upgrade cycle, Quick Reference Card |
| `llm-wiki` | `wiki-planning` | Schema migration, code architecture ingest, content accuracy verification, external evaluation, vision audit, scope widening, archiving |
| `add-next-actions` | `wiki-entity-management` | YAML pollution workflow + recovery script — Phase 4g |
| `bulk-entity-enrichment` | `wiki-entity-management` | Full 11-phase enrichment pipeline — Phases 4a-4k |

### Cross-Reference Sweep (What Got Missed Initially)

After retiring the 4 skills, a grep across all SKILL.md files found:

1. **`gbrain-integration`** — `related_skills` still listed `wiki-health-doctor`. **Fix:** removed it.
2. **`knowledge-base-organization`** — body referenced "companion `llm-wiki` skill". **Fix:** redirected to `wiki-planning`.
3. **`wiki-planning`** — newly absorbed section said "See the full `llm-wiki` skill reference". **Fix:** removed stale pointer (content now inline).
4. **`wiki-entity-management`** — `Related Skills` section referenced `bulk-entity-enrichment`. **Fix:** replaced with proper pointers to the wiki skill ecosystem.

**Lesson:** Always run `grep -r "retired-skill-name" ~/hermes/skills/*/SKILL.md` after any retirement. The absorbed content is safe, but the cross-references from other skills are not.

### Coordinator Update (Klio v2.0.0)

The Klio skill was the wiki auditor. After consolidation, it needed:
1. **`related_skills`** — expanded from 4 → 10 skills (was missing wiki-planning, wiki-entity-management, wiki-cross-linking, wiki-content-migration, wiki-reference-document, tracking-system-operations)
2. **Companion Skills table** — new section mapping task types to the right companion skill
3. **Workflow numbering fix** — step numbers had duplicates (two "2." and "8." entries)
4. **Version bump** — 1.9.1 → 2.0.0

### Retention Sizes

| Skill | Before | After | Net |
|-------|--------|-------|-----|
| `wiki-operations` | ~102K | ~108K | +6K (absorbed health pipeline) |
| `wiki-planning` | ~50K | ~55K | +5K (absorbed Karpathy ops) |
| `wiki-entity-management` | ~25K | ~36K | +11K (absorbed enrichment pipeline) |
| 4 retired skills | ~65K combined | 0 | -65K |
| **Total** | **~242K** | **~199K** | **-43K** |

### Key Observations

- **The cleanup happened because the 4 source skills were noticeably overlapping** with their targets when loaded side-by-side. Bloat was visible before any audit.
- **Cross-references from UNRELATED skills** (gbrain-integration, knowledge-base-organization) were the hardest to catch — they reference the retired skill by name in places you wouldn't think to look.
- **Coordinator skills (Klio) always need updating** after a landscape change — they're the main entry point for the user.
- **`absorbed_into` parameter** on skill_manage(action='delete') tracks the trail for future curators.

## Example 4: Companion Skills Reference Table (2026-07-20)

**Context:** After consolidating the wiki skill stack, Klio needed a map so future sessions know which companion to load for each task type.

**Before:** No guidance — just `related_skills: [wiki-operations, ...]` in frontmatter. Future agents had to guess.

**After:** A `## Companion Skills` section with a 8-row table mapping task → companion skill, plus a cron note explaining why routine crons only load the minimum pair.

```markdown
## Companion Skills

Klio is the coordinator for wiki work. Load the appropriate companion alongside Klio based on the task:

| Task | Load With Klio |
|------|---------------|
| General health check, lint, backup, content audit | `wiki-operations` |
| Planning wiki structure, methodology, graph topology | `wiki-planning` |
| Entity lifecycle (create, bulk edit, enrich, normalize) | `wiki-entity-management` |
| Add `relates_to` edges and `[[wikilinks]]` | `wiki-cross-linking` |
| Move external content into the wiki | `wiki-content-migration` |
| Create structured reference docs from visuals | `wiki-reference-document` |
| Session handoff hygiene, dashboard views, watchdogs | `tracking-system-operations` |
| Full enrichment pipeline (phases 4a-4k) | Now lives inside `wiki-entity-management` Phase 4 |

> **Cron note:** Routine weekly crons load only `['klio', 'wiki-operations']` to minimize token cost.
```

**When to use this pattern:** Any coordinator agent that routes work across specialist skills. The table serves as the map for future sessions — without it, they'll load the wrong companion or miss one entirely.
