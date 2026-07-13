# Session Retrospective Scan

When the user says "go through the session and add anything you missed" or similar — a structured pattern for catching brain dump items that slipped through during a session.

## When to Run

- User explicitly asks: "did I miss anything?", "go through the session", "add anything you missed"
- After a long session where items were mentioned but may not have been captured to brain dump
- When switching out of brain dump mode to verify completeness

## Workflow

1. **Inventory what's already captured** — read the current brain dump file for the session
2. **Search session history** — use `session_search` with broad keywords (idea, task, should, need, fix, create, add, setup, configure, explore, maybe, could, would)
3. **Check for preserved task lists** — context compaction often preserves stale task lists from previous sessions. Cross-reference those items: if they're NOT in the brain dump and not already completed, capture them
4. **Check for implicit items** — things that were discussed but never formally dumped:
   - Tools or features that were worked on but not completed (patches, configs)
   - Wiki pages created but not yet promoted from `pending/`
   - Cron jobs mentioned but not set up
   - Items from project portfolio that were flagged as P1/P2
5. **Add to brain dump** — append any missed items to the session's brain dump file with appropriate categories (Task/Idea/Reminder)
6. **Report** — concise table of what was added, organized by category

## What NOT to Do

- ❌ Do not start executing missed items — capture only
- ❌ Do not batch-import entire task lists without filtering to genuinely new/unlogged items
- ❌ Do not re-capture items already in the brain dump

## Pitfalls

- **The compaction blind spot.** Context compaction summaries may have their own "Historical Remaining Work" section that contains items the user intended to capture but were never written to a brain dump file. The compaction summary is a processed artifact, not the original instruction — but it often preserves latent work items that the user never formalized. Always scan it.
- **State-worked-but-not-captured items.** If the agent patched a config file or created wiki pages during execution mode, but the user later switched to brain dump mode, those modifications are DONE (not brain dump items). The implicit items are the *unstarted ones* — tasks that were blocked or pending when the mode switched.
