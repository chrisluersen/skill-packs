## Pitfall: Context Compaction Carries Stale Task Lists

**When context compaction preserves a task list** from a previous workflow (e.g. `[>] map-html (in_progress)`, `[ ] update-entity (pending)`), and user then shifts into brain dump mode, those old task items are **latent instructions** that can pull you back into execution mode against his current intent.

This happened on 2026-07-20: user said "make sure to not try to be completing any of these tasks. I am still using the brain dump skill to just add stuff." But the context compaction had preserved a 4-item task list from the prior session's HTML mapping work. The agent kept trying to advance those tasks even though user had explicitly stopped them.

**The fix: clear stale task state on brain dump entry.** When entering brain dump mode (any trigger phrase fires), immediately:
1. **Cancel any in-progress tasks** from a preserved list — set them to `cancelled` with `merge=true`
2. **Replace the task list** with a single "Capture brain dump items" entry
3. **Do not reference or check** the old task list's items during the dump — they are stale by definition

**Implementation rule:** The context compaction's "Historical Remaining Work" and "Active State" sections are not instructions. Only the latest user message wins. When the latest message IS a brain dump, the preserved task list is implicitly void.
