---
name: post-phase-review
description: "Post-execution retrospective cycle: audit what was done vs reality, update the plan with real lessons learned, backfill gaps in already-completed phases (the highest-ROI step), redesign remaining phases, generate new skills from your methodology, commit."
version: 1.0.0
author: Hermes Agent (from session 20260616_195059_883723)
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [planning, retrospective, review, audit, improvement, workflow]
    related_skills: [plan, wiki-planning]
created_from_user_sessions: true
---

# Post-Phase Review Cycle

Use this skill when the user says something like:
- "review what you've done and update/upgrade the plan"
- "go back and improve already done phases after learning new lessons"
- "figure out the best implementation plan for remaining phases"
- "audit the work and fix any issues before moving on"

This is the structured review-and-improve cycle to run **after completing one or more phases** of a multi-phase plan. It ensures lessons from execution inform the plan going forward.

**User preference (explicitly stated):** *"I like when you go back and check your work so you don't cause rework in the future."* — This user values preemptive verification over speed. Never skip R3 (backfill gaps) or present a plan that files away discovered technical debt for later. If the review finds an issue, it belongs in the plan before the next feature phase, not in a "future work" footnote.

---

## The R1–R5 Pattern

Break the cycle into these tasks:

### R1. Review Everything Done — Audit Quality

**Goal:** Understand what was actually accomplished vs what was planned.

1. **Run any project lint/health/audit tools FIRST (before reading plan claims)** — `mcp_wiki_lint_wiki` for wikis, `pytest --tb=short` for testable code, linters for code quality. These surface freshness metrics (stale frontmatter, broken links, test regressions) that plan tables never track.
2. **If lint reports "stale frontmatter" or "stale sources," run reindex first** — the MCP server's SQLite DB can be out of sync with the files on disk, especially if pages were edited while the server was running with a stale index. Call `mcp_wiki_reindex_wiki()` and re-run lint before trusting any stale-frontmatter counts. Many "stale" reports are false positives caused by a stale DB, not stale content.
3. **Read the plan file** — load and review the existing PLAN.md (or equivalent), now equipped with accurate lint data from steps 1–2.
4. **Measure actual deliverables with real data** — don't trust plan estimates, use terminal:
   - `git log --oneline --all` for actual commit hashes
   - `wc -c` on files for actual sizes — sort by size to spot thin pages quickly
   - `grep -c` / `find` counts for verifying page counts vs plan claims
   - For wikis: page counts, sizes by category, schema compliance; for code: feature completion, test coverage, open issues
   - **Run any project lint/health/audit tools** — `mcp_wiki_lint_wiki` for wikis, `pytest --tb=short` for testable code, linters for code quality. These surface freshness metrics (stale frontmatter, broken links, test regressions) that plan tables never track. Add findings to the "List what's wrong" step.
3. **Compare plan claims to reality** — identify discrepancies: wrong commit hashes, theoretical page counts ≠ actual, stale status tables, claims of work not actually done. **Watch for numbers that drift between cycles** — page counts, commit totals, file sizes, and tool counts all go stale. Use `git rev-list --count HEAD` for actual commits, MCP stats for page counts, `wc -c` for file sizes — never trust what the plan claims without re-measuring.
4. **Inspect reference/companion docs** — SCHEMA.md, AGENTS.md, index.md, log.md, todo.md for currency. **Cross-check companion docs against plan status rows:** for every task in the plan marked "📋 Pending" or "⚠️ Not started", search the companion docs for relevant content. If AGENTS.md already documents the workflow or index.md already lists the page, the plan table is stale — the work was done but the status wasn't updated.
5. **List what's wrong** — stale audit tables, broken table rows, wrong page counts, missing frontmatter, companion-misaligned statuses

### R2. Update the Plan With Lessons Learned

**Goal:** Rewrite the plan to reflect actual execution realities.

1. **Correct factual errors** — commit hashes (use `git log --oneline --all`), page counts, dates
2. **Add Lessons Learned section** — real bugs encountered (YAML orphan, tool unavailability), what would be done differently
3. **Add Key Design Decisions** — explain why certain approaches were chosen (field ordering, content-first, no confidence field)
4. **Refine phase breakdown** — if Phase 1 turned out to be 2 sub-phases (1a + 1b), split it; if phases need reordering, reorder
5. **Add Risk Register** — document real issues that occurred so they're not rediscovered
6. **Update todo.md** — set the new task breakdown

### R3. Go Back and Improve Already-Done Phases

**Goal:** Fix gaps found during R1 review. This is the crucial step that most plans miss.

1. **Before anything: load the relevant skill + source material** — e.g. load `wiki-planning` skill and read raw doc files before judging what pages need. Without source context, expansions will be generic.
2. **Fix stale audit tables FIRST** — update tier boundaries, page counts, thresholds (e.g. SCHEMA.md audit) to reflect current state. Do this *before* backfill so you know what needs fixing.
3. **Backfill thin content in batches** — expand pages that are under threshold (e.g. <2K, <3K):
   - Batch similar pages together (e.g. all Hermes concept pages at once)
   - Have source material ready (raw docs, transcripts, articles)
   - After expansion, re-measure sizes and update the audit table again
4. **Fix broken markup** — table rows, missing wikilinks, orphan YAML fields, broken counts in index/ToC
5. **Update index/table of contents** — add new pages, fix counts, fix any broken table rows
6. **Verify graph builder integrity (if project uses a relationship graph)** — check that `build_graph_data.py` and any inject/explorer scripts still match the current repo structure (see `references/graph-builder-audit.md` for the full checklist). Common drift: `SKIP_DIRS` missing new non-content directories, case-insensitive `SKIP_FILES` mismatches on Windows, nodes missing `edges` count field, inject script referencing wrong JSON key (`links` vs `edges`). Fix bugs at the source (the builder script) — not by patching the output.
7. **Patch any skills that reference old numbers/methods** — the skill describing your methodology likely needs updating RIGHT AFTER your work changes the numbers it references
8. **Save new state facts to memory** — compact enough to fit (e.g. ~600 chars for memory, ~300 chars for user profile)

### R4. Design Refined Implementation Plan for Remaining Phases

**Goal:** With hard-won knowledge from executed phases, design better execution for remaining phases.

1. **Read raw/pending source material** — identify what content exists to power future phases. Check `raw/` directories specifically: large untapped docs (e.g. 2.8MB Hermes Agent docs, transcripts, source articles) are often sitting unprocessed and can directly feed Phase 6-style ecosystem page creation. Don't design remaining phases until you know what material exists.
2. **Consider tool availability** — check what's actually installed (`which bun`, `which uv`, `pip list`, `npm list`)
3. **Design with current constraints** — don't plan for tools that aren't installed
4. **Phase ordering** — what should come next given current state. Sub-phases may be needed (e.g. Phase 1 → Phase 1a + Phase 1b)
5. **Effort estimates** — rough sizing per phase based on prior execution speed
6. **Generate skills from your methodology** — the R1-R5 cycle itself, if proven useful, should be saved as a skill before the next user asks their next question. Don't wait to be told.
7. **Insert cleanup phases when technical debt is discovered** — If R4 finds a blocking issue (e.g. 869-line server hitting the refactoring threshold), amend the plan with a **new intermediary phase** (e.g. Phase 3.5-style) before the next feature phase. Update the dependency graph, timeline, and risk register to reflect the insertion. Do not leave it as a "note for later" — if it blocks forward progress, it needs its own plan entry.

### R5. Commit Everything

**Goal:** Save all improvements to version control.

1. **Update log.md** — append the backfill entry. **Read the full file first** (not paginated) if you're going to rewrite, or use surgical append if the log uses an append-only format
2. **Run quality checks before staging** — if the project has lint/audit/test tools (e.g. `lint_wiki` for wikis, `pytest` for code), run them and fix any new failures before committing. This prevents stale numbers from persisting into the next review cycle.
3. **Stage all changed files** — `git add -A`
4. **Verify what's changed** — `git status --short` before committing to catch unintended changes
5. **Commit with descriptive message** — use a `type: summary` format (e.g. `meta: Phase 1b complete — backfilled N pages, upgraded PLAN.md`). List the count of changed files in the body
6. **Update todo.md** — mark R1-R5 as complete, set next phase as pending

---

## Interaction Style

- Load the plan skill first (`skill_view(name='plan')`) to use its Plan Audit & Redesign section
- Create the todo list as `R1` through `R5` immediately
- Each R task should be bite-sized with clear completion criteria
- Always commit at the end — a review cycle that doesn't commit hasn't finished
- **Reference:** `references/common-stale-patterns.md` — specific stale-number patterns found across review cycles (page counts, commit counts, tool tables, index sizes). Check this during R1 before trusting plan claims.
- **Reference:** `references/wiki-audit-recipes.md` — concrete shell/Python one-liners for measuring page tiers, edge counts, MCP tools, server growth, and graph explorer stats during R1. Use these instead of inventing ad-hoc commands each cycle.
- **Reference:** `references/graph-builder-audit.md` — concrete checks for graph builder integrity during R3 backfill and R5 pre-commit. Covers: SKIP_DIRS drift, case-insensitive SKIP_FILES, missing edges counts, inject script JSON key mismatches, broken target_slug assignments.
- **Reference:** `references/session-closeout-self-review.md` — read-back-everything-you-touched verification between R3 (backfill) and R5 (commit). Catches stale claims, leftover cruft, cross-file contradictions, and missing propagation. Run before every session closeout, not just plan-phase work. (Added 2026-06-19.)
- **Reference:** `references/memory-claim-verification.md` — cross-reference agent claims in memory against actual source files to catch hallucinated function names, mischaracterized behaviors, and miscounts. Use after any multi-file reading session where synthesis was stored to memory. (Added 2026-07-07.)

## Common Pitfalls

- **Skipping R3** — fixing already-done phases is the highest-ROI step in the cycle. Don't skip it just because the phase is "done."
- **Forgetting log.md** — the log is append-only; add a new entry rather than editing old ones. If you need to rewrite it entirely (major milestone), read the FULL file first with `offset=1, limit=2000` — not paginated — to avoid missing content
- **Not updating skills** — if you discovered pitfalls during execution, patch the relevant skill immediately. The skill describing your methodology is stale the moment your work changes its numbers.
- **Writing a future plan that ignores tool constraints** — always check `which`/`where` before assuming tools exist
- **Overwriting files without reading fully** — always read the full file before writing a replacement. Paginated reads risk missing content at page boundaries
- **SCHEMA.md audit: update BEFORE and AFTER backfill** — if you only update the audit after expanding pages, you lose the baseline comparison. Take a snapshot first, then update again
- **Context compaction kills long turn sequences** — each context compaction loses your ability to scroll back in detail. Batch operations aggressively (expand 12 pages at once, do all patches in one write call). Testing complex patches one by one will exhaust the turn budget and force compaction mid-workflow
- **Plan staleness causes duplicate work** — When a plan marks a phase as "NEXT" but the work was already done in a prior session (common after context compaction loses track of completed work), jumping straight to implementation without verifying the target file produces duplicate code. Before starting any phase, search the target artifact for the feature/pattern you're about to implement (function names, CSS classes, DOM elements). If it already exists, mark the phase complete and move on. This is a pre-execution check, not just a post-hoc R1 review step — R1 catches it after the fact, but a 5-second search before writing prevents the duplicate from being created in the first place.
- **Mechanically executing cosmetic phases when substance is needed** — During R4 (designing remaining phases), assess whether the remaining phases actually serve the user's goal or are diminishing returns. If the remaining work is polish/cosmetic (CSS transitions, animation tweaks, visual refinement) and the user's real goal is decisions or functional outcomes, **proactively recommend pivoting to substance over polish** rather than mechanically executing the plan. This is especially critical for users with ADHD who tend toward perfectionism on cosmetic details — they need the agent to be the one who says "this is good enough, let's move to the real work." Only polish for public sharing when the user explicitly asks. Signal: if you've completed 3+ phases and the user asks "what should we do next?" or "do I need to improve anything else?" — that's a pivot prompt, not a request to continue the plan.
- **Memory has a strict size limit** — don't dump full state facts. Memory limit is ~1,000 chars total; user profile limit is ~600 chars. Pack only what prevents repeated steering
- **PLAN.md numbers drift between cycles** — page counts, commit totals, and file sizes in the plan are always stale by the next review round. Always re-measure with terminal commands before trusting what the plan claims. A plan that says "5 commits" and "54 pages" when reality has 25 commits and 52 pages is the norm, not the exception.
- **Phase nesting is common** — if a phase turns out to need sub-phases (e.g. Phase 1 → Phase 1a + Phase 1b), split the plan mid-stream and update the frontmatter. Don't pretend the original phase structure was correct
- **Markdown pipe-table patching with `patch` tool is fragile** — when patching PLAN.md tables that use GFM pipe syntax (`| col1 | col2 |`), the leading `| ` pipe characters in `old_string` must precisely match the file. Any mismatch causes the tool to add extra `||` triples, breaking the table. After each table patch, re-read the affected lines to verify row alignment. If a table is heavily stale, replace the entire section with `new_string` (including full table header + separator + data rows) rather than patching individual rows one at a time
- **Unicode box-drawing chars (`│`, `├`, `└`, `─`) in ASCII art / dependency graphs are vulnerable to `patch` tool replacement** — the tool's fuzzy matching can silently substitute a box-drawing `│` (U+2502) with a regular pipe `|` (U+007C) when the surrounding context is similar. This visually breaks dependency graph diagrams and tree layouts. After patching any section containing box-drawing characters, re-read the affected lines and visually verify the Unicode chars survived. If they were replaced, run a second patch: `old_string="| chars..."` → `new_string="│ chars..."` using the correct U+2502 character. To be safe, replace whole ASCII-art blocks rather than patching individual lines inside them.
- **Graph builder and inject script share an implicit JSON schema with no validator** — `build_graph_data.py` writes `{"nodes": [...], "edges": [...]}` while `inject_graph_data.py` embeds JS that reads `GRAPH_DATA.links`. When these scripts are edited independently (different phases, different authors), the key contract silently diverges. Always use a fallback in the inject script (`GRAPH_DATA.links || GRAPH_DATA.edges`) and verify the key match during R3.
- **`SKIP_DIRS` in graph builder must be verified against current repo directories** — as the project grows, new directories like `pending/`, `_archive/`, or `audit/` may be added. The builder's `SKIP_DIRS` set won't include them unless explicitly updated. Check by listing all top-level dirs and comparing against SKIP_DIRS during R3.
- **Case-insensitive SKIP_FILES on Windows** — using `path.name in SKIP` in a set where half the entries are uppercase (`"TODO.md"`, `"README.md"`) won't match lowercase files on Windows. Always normalize with `.lower()` and store SKIP_FILES entries in lowercase.

## Verification Checklist

- [ ] R1: Plan vs reality audit complete — measured with actual data (git log, wc, grep) not plan claims
- [ ] R2: Plan rewritten with lessons learned, frontmatter timestamps updated
- [ ] R3: All gaps backfilled in already-done phases, audit table updated before AND after
- [ ] R3d: Skills patched with new knowledge — both the skill for this workflow and any skills describing already-done phases
- [ ] R4: Remaining phases redesigned with real constraints, new skills generated from methodology
- [ ] R5: All changes committed with descriptive message after `git status --short` verification
- [ ] Quality check ran before commit — lint, audit, or test tool confirmed no new failures
- [ ] Graph data verified (if wiki has relationship graph): `build_graph_data.py` run, nodes have `edges` count, `graph-explorer.html` loads correctly after `inject_graph_data.py`, no content-page leakage from `raw/` or meta dirs, inject script references correct JSON keys (`GRAPH_DATA.links || GRAPH_DATA.edges` fallback in place)

---

## Post-Execution Addendum (from 20260617_195059_883723 follow-up)

The following lessons were added after a follow-up cycle that fixed code bugs (MCP server dir-skip logic, broken wikilinks, reindex safety), added a new MCP tool (`lint_wiki`), and verified everything worked:

| Lesson | Detail |
|--------|--------|
| **MCP servers are stale until restarted** | The Hermes session spawns MCP server subprocesses at startup. Editing the server's `.py` file mid-session does NOT affect the running process — the old code stays in memory until the session restarts (`/restart` or new `hermes` invocation). |
| **`hermes mcp test <name>` spawns a fresh copy** | Use `hermes mcp test wiki` to verify new server code works — it starts a brand-new subprocess from disk. The test confirms the code is correct even when the session's active server is stale. |
| **Standalone verification bypasses stale processes** | Write a standalone script (e.g. `wiki-reindex.py` that uses `importlib` to load the server module fresh) to test logic independently of the running MCP server. This catches discrepancies between "what the server will do after restart" and "what the old server is doing now." |
| **Reindex after indexer-logic changes** | Changing what gets indexed (e.g. adding `SKIP_DIRS`) requires a full FTS5 rebuild. The running MCP server's `reindex_wiki` tool uses old code — run reindex via the standalone script instead until the server restarts. |
| **Server line count signal confirmed at 3.2× growth** | Server went from 275 → 586 → 869 lines across Phases 3→4→5. The 500-line refactoring threshold was accurate but was missed — the 3.2× growth made the phase-timing problem worse. When a review cycle discovers past-threshold bloat, insert a cleanup phase before the next feature phase. |
| **Edge format standardization is a one-shot fix** | Converting string-format `relates_to` entries to dict format `[{rel: ..., target: ...}]` via `populate_edges.py` was a one-time operation. After script fixes and normalization, all 45 pages were consistent. The lesson: edge schemas evolve — build `populate_edges.py`-style migration scripts rather than manual edits. |
| **Graph data is a derived artifact, not source of truth** | `graph-data.json` and `graph-explorer.html` are generated from frontmatter `relates_to` fields. They're NOT auto-updated when frontmatter changes. After any edge edit, regenerate with `build_graph_data.py` and verify the graph explorer loads. Track this in the Verification Checklist. |
| **Verify all new MCP tools after phase execution** | Every phase that adds MCP tools (Phases 3, 4, 5) must also verify them via `hermes mcp test wiki` after restart. The tool count grows across phases — verify the full set, not just the new ones. |
| **FTS5 index size as a smell** | When the index size drops dramatically (e.g. 3 MB → 221 KB) after a reindex, check if large `raw/` files were previously bloating it. A healthy corpus index is dominated by actual content, not source articles. |

The following lessons were extracted from the actual execution of this skill for a wiki Phase 1b backfill cycle:

| Lesson | Detail |
|--------|--------|
| **Measure don't assume** | The plan claimed "44 pages normalized and 7 thin pages expanded." Reality: 45 pages existed, and 12 more pages were under 2K. Always measure with real terminal commands. |
| **Batch expansion is reliable** | Expanding 12 pages at once with `write_file` works well. Each page gets a clean read-rewrite cycle. No need to do them one-by-one through patch. |
| **SCHEMA.md audit needs BEFORE snapshot** | When updating the audit table for page sizes, take a snapshot first, compare, then update again after backfill. Otherwise the delta is invisible. |
| **Skill patching is the bottleneck** | The `wiki-planning` skill had stale page counts. Remember to patch the skill that describes your methodology after you change the facts it captures. |
| **log.md rewriting risks data loss** | When writing a major milestone entry to log.md, read the FULL file with `offset=1, limit=2000` rather than paginated reads. A partial read leads to an incomplete rewrite. |
| **Memory compaction** | Pack only the essential state facts (~600 chars). Don't store counts you can re-measure with `ls`/`wc`. |
| **Skill creation is an R4 output** | The R1-R5 pattern itself was worth saving as a skill. Don't wait for the user to suggest it — if the methodology worked, save it. |

## Post-Execution Addendum (from Phase 4 of the wiki build)

The following lessons were extracted from Phase 4 execution (Content Synthesis Engine) and the subsequent review cycle:

| Lesson | Detail |
|--------|--------|
| **Cross-repo scope: measure what was committed vs what was changed** | Phase 4 edited the MCP server under `AppData/Local/hermes/scripts/` (outside the wiki repo) AND wiki docs. During R1, `git status --short` only shows repo files. Also check `git diff --stat` for staged files. The server change was never committed — detect this gap by listing ALL files modified during the phase, not just repo-tracked ones. |
| **Tool cache vs server registration: confirm it explicitly** | `hermes mcp test wiki` shows tools registered on the server (count) but those tools won't appear as `mcp_wiki_*` callable functions until the Hermes session restarts. R1 verification should call out this distinction: "tools discovered on server: N — tools available in session toolset: M." If N > M, note that a session restart is needed before new tools are usable. |
| **Hyphenated filenames block Python import** | MCP server files with hyphens (`wiki-mcp-server.py`) cannot be imported via `import` or `importlib.import_module`. Testing requires `importlib.util.spec_from_file_location()` or a subprocess JSON-RPC call. Document the test approach for each tool in its development cycle. |
| **New capabilities unlock downstream phase redesign** | When Phase 4 added `synthesize_answer` + `file_synthesis`, those tools changed the approach for Phases 6 (draft pages from source doc) and 7 (ingest pipeline write path). R4 must explicitly ask: "Did the completed phase produce new tools/endpoints/APIs that change how remaining phases work?" If yes, update those phase descriptions. |
| **Server/script line count as a quality signal** | The MCP server grew 275→586 lines (2.1×). This is a smell: a single file doubling suggests it's time to split into a utilities module. During R1, compare the current line count of any script that was modified against its pre-phase baseline. >500 lines or >2× growth means consider refactoring. |
| **Verification scripts should survive context compaction** | Long verification sequences (test tool A → test tool B → lint → reindex → commit) span many turns and context compactions. Write a standalone verification script at the start of the phase and reuse it throughout, rather than hand-typing each test command. The script survives compaction because it exists on disk. |
