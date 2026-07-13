# Common Stale Patterns Found During Review Cycles

Check these during R1 before trusting any plan claims. These are the numbers that drift most between cycles.

## Page Counts
- Plan says "44 pages" → reality: 45+, or 52 after MCP builds. Pages get added faster than plans are updated.
- Plan says "7 thin pages" → reality: 12+. Always re-measure with `list_wiki_pages()` (for wikis) or `ls` (for filesystem).

## Commit Counts
- Plan says "5 commits" → reality: 25-27 after extensive work. Commit numbers date fastest of any metric.
- Always use `git rev-list --count HEAD` — never trust the plan's number.

## Tool Counts
- Plan says "5 MCP tools" → reality: 8 after new tools are added. Each phase often adds 1-3 tools.
- Check with `hermes mcp test <server-name>` and count the output.

## Server / Script Line Counts
- Plan says "275 lines" → reality: 586+ after expansion. Track the delta — >2× growth is a refactoring signal.
- Use `wc -l` on the actual file.

## Architecture Layer Descriptions
- Plan lists tools in Layer 2 → reality has more tools that were added mid-phase.
- Update Layer 2 in both the architecture diagram AND the "Where We Are Today" section.

## Status Tables
- Timeline rows: phases marked "📋 Planned" turn to "✅ Done" mid-session. The table lags behind.
- Success criteria: phase columns stop at 🟡 "In progress" or are blank for the target phase.
- Dependency graphs have stale 🟡/🟣 status markers.

## Companion Document Misalignment
- A plan table row says "📋 Pending" or "⚠️ Not started" but the companion doc (AGENTS.md, SCHEMA.md, index.md) already has the content. This happens when work was done implicitly during a phase but the plan's task table wasn't updated.
- **Check pattern:** For every task row in the plan marked "Pending" or "📋", search the companion docs for relevant content before trusting the status. If the companion doc has it, the plan table is stale and needs a "✅ Done" update.
- **Common cause:** The work was split across sessions — companion doc got updated in session N but the plan table wasn't refreshed until session N+1's review cycle.
- **Detection:** During R1, after reading the plan, search AGENTS.md (or equivalent) for topics referenced in "Pending" plan rows. If they exist, the status is stale.

## Cross-Repo Changes
- Code modified outside the wiki repo (e.g. `AppData/Local/hermes/scripts/`) won't appear in `git status`.
- Check: what files were edited this session? Run `hermes mcp test` to verify server-side changes. Compare against what was committed.
- The MCP server under `AppData/` is a common blind spot — it's modified during Phase 4+ work but lives outside the wiki repo.

## Measured vs Claimed Attribute Counts
- SCHEMA.md audit: "18 pages under 3K chars" — re-measure with `wc -c` on each page file. Don't trust the stored count.
- Page tier ratios (well-populated / adequate / thin) drift as content expands.
- Total KB: plan says 221KB → actual index size may differ after reindex with different SKIP_DIRS.

## Graph Data Is a Derived Artifact
- `graph-data.json` is NOT auto-updated when frontmatter `relates_to` fields change.
- Plan says "50 nodes, 77 edges" → reality may differ if edges were edited but graph wasn't rebuilt.
- Always run `build_graph_data.py` after any edge edit and verify the D3 explorer still loads.
- `graph-explorer.html` version tracks the data it was built with — stale data means a stale viz.

## Frontmatter Staleness (Lint-Detected)
- **What drifts:** `sources[]` dates go stale (older than 90 days since the source was extracted), or pages have no sources at all. This is distinct from content staleness — the page body may be current but the provenance chain has decayed.
- **How far it drifts:** 10+ pages can go stale between review cycles. In a 56-page wiki with 49 content pages, roughly 20% of pages may have stale frontmatter by the next review.
- **Typical stale pages:** Meta pages (AGENTS.md, PLAN.md, SCHEMA.md, log.md, todo.md, README.md, index.md) always lack formal `sources[]` — they're the plan itself. Concept pages written early in Phase 1/1b may have dates from the original creation and no newer sources added since.
- **Detection:** Run the project's lint/health tool (e.g. `mcp_wiki_lint_wiki`, `pylint`, `eslint`). Frontmatter staleness shows up as a distinct check when the lint tool has a "stale sources" / "stale frontmatter" rule.
- **What to do about it:**
  - Meta pages (PLAN.md, AGENTS.md, etc.): Accept as expected — they don't need `sources[]`.
  - Content pages: Add fresh sources (e.g. a `session:session-id` reference from current work, or a new raw article reference with today's date). Don't just bump the timestamp — add real provenance.
  - **Track as a phase-quality metric:** The number of stale-frontmatter pages is a leading indicator that the provenance discipline is slipping. A rising trend between cycles means it's time to add a dedicated backfill step to the next phase.
  - **Recurrence pattern:** Stale frontmatter tends to accumulate in pages that were created in bulk (Phase 1 expansions, Phase 6 ecosystem pages) because the original sources are one-shot imports that don't get updated. Pages that are revisited and edited are naturally refreshed.

## Measured vs Claimed MCP Server Lines
- The MCP server line count grows predictably: 275 (Phase 3) → 586 (Phase 4) → 869 (Phase 5) → 913 (Phase 3.5 refactor).
- The plan's line count is always behind — review cycles are the only time it gets updated.
- Track both server.py AND utils.py (if refactored) — the total is what matters for the refactoring signal.
