---
name: brain-dump
title: "Brain Dump — Get It Out of Your Head"
description: "ADHD-friendly brain dump: zero-friction capture of whatever's racing through your head. Auto-categorizes into tasks, ideas, worries, reminders, and random — saves to the wiki as searchable, datestamped pages, and promotes action items to tracking."
category: productivity
created: 2026-06-20
updated: 2026-07-22
version: 9
---

# Brain Dump — Get It Out of Your Head

## When To Load

Load this skill when user says any of these trigger phrases:

- `"brain dump: ..."` — the dump text follows the colon
- `"brain dump project: ..."` — variant specifying a project idea. Same flow as `"brain dump:"` but signals the item is a project concept. Categorize as **Task** (project ideas are actionable by definition).
- `"dump: ..."` — shorthand same meaning
- `"stash: ..."` — same meaning, preferred for single-item capture. Signals "save this, don't build it."
- `"add to the stash"` — variant without colon, same as stash:. Triggers when user appends a post-task stash request (e.g. "add to the stash i want to do X eventually").
- `"> ..."` — line-starting `> ` prefix, same meaning as stash:. Use when the thought starts mid-conversation without a keyword.
- `"get this out of my head: ..."` — same flow
- `"my head is full of: ..."` — same flow
- Just `"brain dump"` with nothing after — **prompt him** with "Fire away. What's in your head?"

**Continuation signals (no explicit "brain dump:" prefix, but same intent):**

- `"same with these"` — user is continuing the previous dump's theme with new items. Check the most recently created brain dump page, identify the domain (resume skills, system ideas, project concepts), and add to the same page.
- `"also add"` — same as above, continuation of current theme.
- `"back to regular brain dump tasks"` — user is switching back to the main system/tool dump domain after a side-tangent (resume skills, creative ideas). Append to the MOST ACTIVE non-side-tangent dump page.
- **Pasted text files** (via MCP paste tool) sent alongside a brain dump trigger phrase — treat the paste content as raw brain dump input. Read the paste file and process the lines as items. Each line in the paste is one item. Skip blank lines.

**`stash:` and `>` mean "capture and categorize, do NOT execute."** If user says these, treat the following text as a brain dump item even if it sounds like a task — it's a save-for-later signal, not a "do it now" signal.

**Do NOT load this skill** for normal conversation, research, or task delegation. This is a capture-only mode.

## The Golden Rule

**Friction is the enemy.** ADHD brains lose thoughts in seconds. The entire skill exists to move content from user's head into persistent storage with the fewest possible steps. Do not ask clarifying questions. Do not suggest rephrasing. Do not edit.

Capture everything. Sort it later.

## Auto-Promote Tasks to Entities

**Per user's directive (2026-06-23):** All Task-categorized items in a brain dump are automatically promoted to tracking entities immediately upon capture. No separate step needed. The brain dump page stays as a provenance record.

**Process:**
1. After writing the brain dump page, cluster related Task items (see Step 4's pre-check), then create entity pages in `tracking/entities/` for each distinct Task or umbrella
2. Add `relates_to: [{target: braindumps/<id>.md, rel: source}]` and `sources` frontmatter pointing to the brain dump
3. Run `mcp_wiki_reindex_wiki()` so entities appear in FTS5
4. Confirm in the one-line summary: `**Dump captured.** [N] items ([M] tasks → tracking)`

**Exception:** Items tagged `stash:` or `> ` (single-throwaway captures) are NOT promoted — they're "save for later" signals, not actionable tasks.

## Response Style

This skill follows **i-have-adhd** principles. The confirmation is the only output:

| Before (fluff) | After (good) |
|----------------|--------------|
| "Great, I've captured everything you said! Let me organize it into categories..." | **Dump captured.** 5 items (1 task → tracking, 1 reminder → tracking, 2 ideas, 1 random) |
| "No problem at all! Here's what I found..." | **Dump captured.** 3 items. All random. |
| "Hope this helps! Let me know if you want to..." | (nothing — skill is done) |

No "Great!", "No problem!", "Let me know if you need...", "Is there anything else?". The confirmation IS the response.

## Workflow

### Workflow 0: Task Verification Mode

**Trigger:** user names a task with any short fragment — `"working check"`, `"maybe?"`, `"research about"`, `"explore"` — OR explicit verification words like `"just check"`, `"verify if done"`, `"don't complete it yet"`, `"is this done"`, `"categorize and prioritize"`. Anything that signals STATUS CHECK ≠ EXECUTION. If user drops a 2-5 word fragment on a new topic, treat it as a verification-mode task: research context, categorize, create entity — don't execute.

**Process-as-you-go principle:** When user drops brain dump items one at a time (the "next task?" pattern), process EACH item immediately — research context, categorize, create entity page, present summary with the running aggregated list. Do not batch. Do not defer. Each item gets its own complete cycle before waiting for the next one. user said "do this as we go so you don't lose context" — this is the rule. The running list at the end of each cycle gives user a full view of what's been captured.

**Key difference from Pure Capture:** In Pure Capture (Workflow 1), you save everything and promote tasks automatically. In Verification Mode, you ONLY check status, categorize, and prioritize. You do NOT execute. The task stays in the user's court until they say "do it now."

**Steps:**

1. **Parse the task name** — user says `"Run Hermes obsidian skill for second brain setup"`. Understand what the task IS.

2. **Audit REALITY** — Check filesystem, installed tools, env vars, existing configs, wiki content. Don't assume anything. Go verify:
   - Is the software installed?
   - Are the plugins loaded?
   - Are the config files in place?
   - Is the env var set?
   - Does the wiki already document this?

3. **Classify as:**
   - **✅ Done** — everything that would constitute "finishing" this task is in place
   - **🟡 Partially done** — foundation exists but the core work isn't finished (say what's done AND what's missing)
   - **❌ Not done / Not started** — nothing or almost nothing exists

4. **Categorize** — Assign a category like Setup/Configuration, Feature, Bugfix, Research, Maintenance, Content, Personal

5. **Prioritize** — Quick (~5-15 min), Balanced (~30-60 min), Deep (~1hr+). Be honest about scope based on what you found.

6. **Report** — Concise table or structured list covering: status, what's done, what's missing, category, priority, estimated effort. No "should I proceed?" — that's a different mode.

7. **Create a task entity page in `tracking/entities/`.** user wants this done as part of verification — do NOT wait for permission. The entity captures the status check permanently so nothing gets lost. See the `task-entity-management` skill for full schema, but minimally include:
   - Frontmatter: `task_status: backlog`, `task_priority: p0-p3`, `task_effort: "~N min/hrs"`, `project`
   - Body: Context (why this exists), Success Criteria (checklist), Notes (what you found during verification)
   - Tag the source: `sources: [{file: "tracking/braindumps/YYYY-MM-DD-HHMMSS-brain-dump.md"}]`
   - Cross-reference the brain dump page in `relates_to` if one was created

8. **Reindex the wiki** — call `mcp_wiki_reindex_wiki` so the entity appears in full-text search.

9. **Report to user** in a concise table: status (done/partial/not-done), what's done, what's missing, category, priority, effort. End with a running aggregated table of ALL items captured this session so far — each row showing name, priority, effort. This gives user a full picture of what's been categorized at a glance. No "should I proceed?" — user decides what to do next.

**What NOT to do in Verification Mode:**
- ❌ Do not install anything
- ❌ Do not change configs, set env vars, or create non-wiki files
- ❌ Do not suggest "I can go ahead and do this now" — user will tell you when
- ❌ Do not skip entity creation — user wants every task captured as a wiki entity, even (especially) during verification

### Pre-Flight Check (Before Step 1)

Before any brain dump, audit what's already tracked and confirm the system:

1. **Audit existing state** — read `~/Vault/wiki/tracking/tasks.md` (dashboard) and `~/Vault/wiki/tracking/projects.md` to understand what's already in the system. Don't duplicate.

2. **For consecutive dumps:** also audit entities created in earlier dumps THIS session (read the dump files you just wrote). Use `session_search` or check your own tool output to build a mental map of what already has an entity.

3. **Format is settled: task entity pages** — the task tracking system uses individual wiki pages in `~/Vault/wiki/tracking/entities/` with frontmatter, typed edges (`depends_on`, `blocks`, `part_of`), and full context. The dashboard at `tracking/tasks.md` aggregates them. This was settled on 2026-06-20 — do NOT ask to re-negotiate the format.

4. **Consistency rule enforced** — ALL tasks must follow the same format. No mixing entity pages with inline table rows. user corrected this explicitly: split formats lose the single-pane view and make prioritization harder.

5. **If tasks exist in old format** — offer to migrate them all to entity pages before adding new stuff. Consistency > incremental migration.

### Step 1: Receive the dump

user says something like:

> brain dump: I need to fix the router config before tomorrow. Also, I've been thinking about a new dashboard layout with a dark theme. Oh, and I keep forgetting to back up my vault. And what if the fleet profiles could auto-detect model availability? Random: buy milk.

### Step 2: Parse into items

Split the text on natural pauses (commas, periods, "also", "oh and", "random:", "reminder:", "and another thing", line breaks). For each item, auto-assign a category:

**URL detection:** If an item is a URL (starts with http:// or https://), it's a research-audit item. Do NOT categorize text-only. Instead, research the URL first (web_extract or browser_navigate) to understand what it is, then categorize based on the content. The resulting entity page should capture the research summary alongside the task.

**Research-audit workflow for URL items:**
1. Extract the page content (`web_extract` or `browser_navigate`)
2. Summarize what the URL is about and its relevance to user's system
3. Categorize based on the summary (not the bare URL)
4. Create the entity page with research findings in the Notes section
5. Report: `**Dump captured.** [N] items ([N] research-audit tasks → tracking)`

**Example:** `"go through these githubs: https://github.com/mem0ai/mem0"` → research first, then capture as Task with the repo summary in the entity body.

| Signal | Category |
|--------|----------|
| "need to", "must", "should", "fix", "set up", "configure", "deploy", actionable now | **Task** |
| "what if", "I've been thinking", "imagine", "maybe we could", "idea:" | **Idea** |
| "worried", "scared", "nervous about", "concerned", "afraid", "what if X goes wrong" | **Worry** |
| "reminder:", "don't forget", "remember to", "keep meaning to" | **Reminder** |
| "decided", "let's go with", "going to do X instead" | **Decision** |
| Everything else | **Random** |

**Long-term project tagging:** When user explicitly says these are long-term/someday items (e.g. \"long term project ideas that i want to get to eventually\"), append `(long-term)` to the item name in the table. Use `task_priority: p3` and `task_effort: ~X hrs` for the created entities. This distinguishes active back-burner projects from genuine near-term tasks.

**Category defaults from context:**
- A mention of a concrete file, config, or system = **Task** ("the router config", "the wiki lint")
- A future-facing speculation = **Idea** ("what if we used X")
- A shopping/life errand = **Reminder** ("buy milk", "call dentist")
- If you can't decide, pick **Random** — better to under-classify than to force it

### Step 3: Save to wiki

Create a new page at `braindumps/YYYY-MM-DD-HHMMSS-brain-dump.md` with frontmatter:

```markdown
---
title: "Brain Dump — 2026-06-20"
id: braindump-YYYYMMDD-HHMMSS
type: braindump
created: 2026-06-20THH:MM:SSZ
tags: [braindump, capture]
---
```

Followed by a table of captured items with status (Open/Resolved for tasks):

```markdown
## Captured Items

| # | Category | Item | Status |
|---|----------|------|--------|
| 1 | Task | Fix router config before tomorrow | → [[tracking/tasks]] |
| 2 | Idea | New dashboard layout with dark theme | Open |
| 3 | Reminder | Back up the vault | → [[tracking/tasks]] |
| 4 | Idea | Fleet profiles auto-detect model availability | Open |
| 5 | Random | Buy milk | Open |

## Action Items Created

- [[tracking/tasks#fix-router-config|Fix router config before tomorrow]]
- [[tracking/tasks#back-up-vault|Back up the vault]]
```

**Important:** Write directly to `braindumps/` — these are personal captures, not wiki ingests. No `pending/` staging needed.

### Expand Existing Items with New Context

When later input from user **enriches or elaborates** an existing brain dump item (not a new item — additional detail on something already captured):

1. **Identify the matching item** by scanning the current brain dump table. Match on semantic intent, not wording.
2. **Update the existing row** in the table — expand the "Item" column to include the new context. Do NOT create a new row.
3. **If the item was an Idea and the new context makes it a Task**, re-categorize it and create the entity.
4. **Use `write_file` to rewrite** the entire brain dump page with the updated row. The `patch` tool is fragile on tables (see "Patch Fragility" pitfall).

**Example:** Item 6 started as `\"theme/vibes folder for photos and videos and GitHub read.me and tweets\"`. user later added 9 sub-themes (vintage anime, RuneScape, ASCII art, etc.). The correct response is to update the single row, not add 9 new rows.

**When NOT to expand:** If the new input is a genuinely new idea (different domain, different category, not related to any existing item), add a new row instead.

### Cross-Domain Dump Routing

user may fire off dumps across completely unrelated domains in rapid succession (system architecture → resume skills → creative video) within the same conversation. When domains diverge:

- **Same domain** (system/tool ideas, then more system/tool ideas) → append to the existing brain dump page. Keeps related capture in one place.
- **Different domain** (system ideas → resume skills → creative content) → create a NEW brain dump page per domain. Use descriptive titles: `Brain Dump — Skills to Learn for Resume`, `Brain Dump — Video Ideas`, etc.
- **Return to a previous domain** (resume skills → system ideas → back to resume skills) → append to the NEWEST page in the target domain. Don't scatter the same domain across multiple pages.
- **Single one-off items** ("brain dump: buy milk") → add to the most recent active brain dump page regardless of domain. Don't create a new page for one item.

**Rationale:** Each page represents a thematic bucket. Multiple buckets is fine. One bucket mixing system architecture and raccoon videos is not.

### Step 4: Create task entity pages (auto-discovered by dashboard)

**Pre-check: cluster related items first.** Before creating entities 1:1 for every Task item, scan the Task items for thematic siblings. If 3+ items share a clear learning track, project, or domain (e.g. 4 resume skills all about ML/GPU engineering → one umbrella entity), group them into a single umbrella entity rather than creating 4 separate ones. Set `task_effort: ~ongoing` on the umbrella and capture sub-items as a list in the Notes section. Only create individual entities when items are genuinely independent of each other.

Then, for each **Task** item (or umbrella), create a task entity page in `tracking/entities/`:

1. Create `tracking/entities/<descriptive-slug>.md` with full frontmatter:
   - `type: task` — `task_status: backlog`, `task_priority: p2/p3`, `task_effort`, `project`
   - `relates_to` edges to dependencies, blockers, related brain dump
   - `sources` array linking to the brain dump page
2. Add a `[[wikilink]]` in the body back to the brain dump page for provenance
3. **No manual dashboard wiring needed** — the `tasks-dashboard-rebuild` cron auto-generates `tracking/tasks.md` from entity frontmatter every 60 min. For immediate display: `cd ~/Vault/wiki && python ~/AppData/Local/hermes/scripts/build-tasks-dashboard.py`

**Life/personal items** (chores, errands, appointments) use `project: Personal` in entity frontmatter — the auto-generator groups them under a "Personal" project row in the dashboard. No special section needed.

**Batch entity creation from backlog:** When processing a comprehensive backlog audit (like "check all pending/missing entities"), follow the batch workflow from `task-entity-management` skill §H. This ensures all backlog items get proper entity pages with full frontmatter, relations, and sources — not just table rows.

**Template reference:** `tracking/entities/_template.md` has the full frontmatter schema and structure.

4. **Reindex the wiki** — call `mcp_wiki_reindex_wiki` so entity pages appear in FTS5 search. FTS5 does NOT auto-update on write; reindex is required after every entity creation.

### Auto-Promotion of Task Items

**User preference (2026-06-22):** user confirmed that Task items from brain dumps should be automatically promoted to tracking entities. This is now the default behavior for all brain dump sessions.

**Implementation:**
- When processing a brain dump, automatically create entity pages in `tracking/entities/` for all Task items
- Use reasonable default priorities (P2 for most tasks, P1 for urgent/blocking items, P3 for nice-to-haves)
- Set effort estimates based on task description complexity
- Link back to the source brain dump page via `relates_to` and `[[wikilink]]`
- Reindex the wiki after creating entities

**Rationale:** This ensures brain dump tasks appear in the task board alongside other work, prevents tasks from getting lost in brain dump pages, and matches user's existing workflow.

**For full entity lifecycle management**, see the `task-entity-management` skill (entity creation schema, migration workflows, dependency wiring, dashboard aggregation).

Respond with a single-line summary. No more than 2 lines:

### 7. Random → unclassified pile

If it doesn't fit the above, tag as `#random` and park it. Revisit semiannually.

## Cognitive Frame Reframing (Advanced)

For complex dumps where user says `"help me make sense of this"` or `"I don't know what to do with this"`, apply cognitive frames from the wiki ([[adhd-cognitive-frames-brain-dump]]):

1. **Generator pass** — All thoughts down, no judgment
2. **Pick 1-3 frames** from: Speedrunner (fastest path), Minimalist (what to drop), Journalist (who/what/when/where/why), Regulator (shoulds vs. wants)
3. **Critic pass** — Score each framed idea, pick best 1-2
4. **Action** — One next step

**When NOT to frame:** Pure emotional venting, single clear thoughts, crisis mode.

## High-Speed Capture (One-Liner Dump)

If user's brain is *moving too fast* for the full dump flow — e.g. `"brain dump: thing1 thing2 thing3"` in a single breath with no pause — skip the full parse/save/promote workflow. Do the minimum:

1. **Write the raw text** to `braindumps/YYYY-MM-DD-HHMMSS-raw-dump.md` verbatim. No parsing. No table. No categories.
2. **Skip tracking promotion.** Raw dumps get promoted later.
3. **Confirm in 4 words:** `**Dump captured.** [N] items.`

The categories and tracking can come later when user says "process my dumps". Raw capture > perfect capture.

## Rapid-Fire Single-Item Cadence

When user says "brain dump project: X" or "brain dump: X" as a **single item per message**, repeated across multiple messages (not a batch, not verification mode):

1. **Check if this enriches an existing item** on the current brain dump page (same domain). If so, update the existing row — see "Expand Existing Items" above.
2. **Otherwise, add a new row** to the current brain dump page. Read the file first to get the true current item count.
3. **USE write_file, NOT patch, for any table with ≥5 existing items.** Once a brain dump page has 5+ rows, `patch` is unreliable on markdown tables — it can consume section headers, blank lines, or adjacent bullets after the table. Read the full file, rebuild the table in memory, and write the whole page back. (See "Patch Fragility on Brain Dump Tables" pitfall.)
4. **If it's a Task**, create the entity immediately (same-session dedup rules apply).
5. **If it's an Idea**, leave it Open in the table. Do NOT create an entity — ideas are reference material, not tracking items.
6. **Cross-link new entities** to related entities from earlier items in this session via `rel: part_of` or `rel: related` edges.
7. **Confirm in one line:** `**Dump captured.** 1 item -> tracking.` (or `Open.` for ideas.)

## After the Dump

Once the dump is captured, you're back to default Stella Polaris mode. The brain dump is done. user may immediately follow up with an action on one of the captured items — treat that normally.

## Periodic Review / Process Raw Dumps

If user asks `"what's in my brain dumps?"`, `"review my dumps"`, or `"process my raw dumps"`:

### Review mode
1. `mcp_wiki_search_wiki("tag:braindump")` — find all brain dump pages
2. Summarize patterns: most common categories, tasks that are still open, ideas that could become projects
3. Offer to consolidate: "I notice 3 brain dumps mention server config issues — want me to bundle those into a tracking item?"

### Process raw dumps mode
If user says `"process my raw dumps"`, there are raw (unparsed) dump files. Run the normal Step 2-4 workflow on them:

1. Read each `*-raw-dump.md` file
2. Parse into categories, build the table
3. Promote Tasks to tracking
4. Rename the file from `*-raw-dump.md` to the normal `*-brain-dump.md` format
5. Confirm: **`Processed [N] raw dumps.`** [count of tasks promoted, ideas found, etc.]

## References

- `references/adhd-research-from-repos.md` — Condensed knowledge from 4 ADHD repo links (communication style, expert framing, tool categories, body doubling, environment tools). Read this for the source material behind the v2 improvements.

## Cross-References

- **`task-entity-management` skill** — Full entity lifecycle: schema, creation, migration, dependency wiring, dashboard aggregation, **and §I: Full Portfolio Categorization & Priority Queue** for when user says "organize everything." Load this alongside `brain-dump` when verification or pure capture produces task entities, or when doing a cross-brain-dump reconciliation sweep.
- **`references/consecutive-dump-chain-2026-06-23.md`** — Full trace of a 3-dump rapid-fire chain: raw saves, dedup decisions, umbrella creation, and source appending. Read this for a worked example of the consecutive dump pattern.
- **`references/within-dump-umbrella-clustering.md`** — Worked example of grouping related Task items into one umbrella entity within a single dump (4 resume skills → 1 entity). Read this alongside the Step 4 pre-check for concrete implementation guidance.
- **`wiki-operations` skill §11** — The broader "everything goes in wiki" principle. Brain dumps are one capture technique within it. When this session also produces other durable knowledge (decisions, bugs discovered, tool quirks), that goes to wiki concept pages — not mixed into braindumps.
- **`adhd-cognitive-frames-brain-dump` wiki page** — For complex dumps requiring frame-based processing.
- **`references/session-retrospective-scan.md`** — Structured pattern for scanning a session for missed items after the initial dump. Loaded when user says "go through the session and add anything you missed."

## Pitfall: Context Compaction Eats Brain Dump Content

**The most dangerous failure mode for brain dumps:** if user brain dumps across multiple session continuations, the user message containing the dump content may be **permanently lost** — compacted into a summary that references the dump without preserving its content. `session_search` cannot recover it. The wiki never received it.

This happened on June 20, 2026 across the brain dump chain #45–#54: user brain dumped about zellij, the session ran through 10 continuations, and by closeout the zellij content existed only in a previous agent window's memory. Gone from every user message in every session. A raw dump page was never written.

**The fix: interleave raw saves.** Any brain dump that spans more than one user message or crosses a session window MUST persist raw content to `braindumps/` after EACH user message, not batched at the end. The `write_file` call costs ~30ms; losing a dump costs everything.

**Implementation:**
- After each user message containing brain dump content, immediately write `braindumps/YYYY-MM-DD-HHMMSS-raw-<slug>.md` with the verbatim content — before parsing, before categorizing, before anything else.
- If the dump was just a single thought ("brain dump: buy milk"): skip the interleave, the normal flow handles it.
- If the dump is multi-item or user adds items incrementally across turns: save raw after each turn.

**Recovery (when you arrive in a new session and the brain dump was already lost):** See `hermes-session-continuity` skill's `references/multi-session-brain-dump-chain.md` for the concrete recovery workflow — how to detect a lost dump chain, identify what was being brain-dumped, and report the gap to user.

## Pitfall: Context Compaction Carries Stale Task Lists

**When context compaction preserves a task list** from a previous workflow (e.g. `[>] map-html (in_progress)`, `[ ] update-entity (pending)`), and user then shifts into brain dump mode, those old task items are **latent instructions** that can pull you back into execution mode against his current intent.

This happened on 2026-07-20: user said "make sure to not try to be completing any of these tasks. I am still using the brain dump skill to just add stuff." But the context compaction had preserved a 4-item task list from the prior session's HTML mapping work. The agent kept trying to advance those tasks even though user had explicitly stopped them.

**The fix: clear stale task state on brain dump entry.** When entering brain dump mode (any trigger phrase fires), immediately:
1. **Cancel any in-progress tasks** from a preserved list — set them to `cancelled` with `merge=true`
2. **Replace the task list** with a single "Capture brain dump items" entry
3. **Do not reference or check** the old task list's items during the dump — they are stale by definition

**Implementation rule:** The context compaction's "Historical Remaining Work" and "Active State" sections are not instructions. Only the latest user message wins. When the latest message IS a brain dump, the preserved task list is implicitly void.

## Pitfall: Action Items Section Drift on Growing Tables

**Problem:** The \"## Action Items Created\" section at the bottom of a brain dump page is written once at creation time but is NOT automatically updated when new items are added via subsequent patches. After 19+ items across 10+ patches, only the first 2 entities were listed. The section becomes misleadingly incomplete.

**The fix: two approaches, pick based on signal:**

1. **Update on every add (preferred for short sessions):** After each batch of new items, patch the \"## Action Items Created\" section to add the new entity wikilinks. Keep it in sync.

2. **Drop the section entirely (preferred for long-running sessions):** After 10+ items or after the first patch to the brain dump page, remove the \"## Action Items Created\" section and replace it with a note: `*Entities created throughout the session — see individual table rows for wikilinks.*` The table rows already contain `→ [[wikilinks]]` to entities, making the action items section redundant.

**Trigger:** After the 3rd patch to a brain dump page, evaluate which approach fits. If the session has 3+ entities created, consider dropping the list.

## Pitfall: Brain Dump Page Size — Offer to Split at ~40 Items

**Problem:** A single brain dump page can grow to 40+ items across a long dump session (happened on 2026-07-22: 49 items on one page). At that size:
- The table loses its "quick scan" value — user has to scroll past a wall of rows to find something
- Further `patch` operations from context compaction become fragile
- The page represents too many domains mixed together

**The fix: offer to split when the page crosses ~35-40 items.** Say something like *"That's 38 items on this page — want me to spin the long-term stuff into a separate page?"* Let user decide; don't force the split.

**When splitting is accepted:**
1. Create a new brain dump page (e.g. `2026-07-22-235500-brain-dump-longterm.md`)
2. Move all items tagged `(long-term)` or clearly back-burner to the new page with their own table
3. Add a cross-ref from the original page to the new one: `**See also:** [[braindumps/...-longterm.md|Long-term projects]]`
4. Keep the main page focused on active/near-term items

## Pitfall: Patch Fragility on Brain Dump Tables

**Problem:** Adding a new row to a brain dump's markdown table via the `patch` tool is fragile. The fuzzy matcher can match too broadly — eating adjacent section headers, bullets, or the table's closing row. This happened on 2026-07-22 when adding item 16: the patch consumed the \"## Action Items Created\" header and the second bullet.

**The fix: prefer full rewrite over patching tables.** Once a brain dump page has more than ~10 items, or when adding the last row before a non-table section:

1. **Read the full file** with `read_file` to get the current table
2. **Use `write_file` to rewrite the entire brain dump page** with the new row appended, rather than `patch` on a single row insert
3. **Verify the rewrite** — immediately read back the file to confirm the table still terminates cleanly and no sections were lost

**Exceptions:** Use `patch` only when:
- The table is short (≤5 rows) AND the table is the LAST thing before the file ends (no sections after it)
- You're adding a row to the very end of an already-clean table where the old_string includes the exact last row + blank line boundary

**After any table operation, always verify** that the section immediately after the table (\"## Action Items Created\", \"---\", etc.) still exists. If it was consumed, roll back with a second patch or rewrite.

## Pitfall: Consecutive Dump Chains — Dedup and Cluster

**Problem:** user may fire off 2-3 brain dumps in rapid succession in the same session (e.g., items 1-6, then 7-11, then 12-20). The skill handles single dumps well, but rapid-fire chains create risks:

- **Duplicate entities** — item 2 in dump #3 ("Organize Files") already has an entity from dump #1.
- **Missed clustering** — 7 items across 3 dumps are all "PC cleanup" work but get scattered across unrelated entities with no umbrella.
- **Stale entity state** — existing entities don't get updated with new source references from later dumps.

**The fix: interleave dedup and clustering after each dump in the chain.**

After each dump's standard processing (raw save → parse → structured page → entities), but before returning the one-line confirmation:

1. **Dedup against session entities.** For each new Task item, check: "Could this already be covered by an entity I created in a previous dump THIS session?" Match on semantic intent, not exact wording. "Organize Files" == "organize files on pc".

2. **Handle matches:**
   - If exact match -> add this brain dump to the existing entity's `sources[]` and `relates_to` instead of creating a duplicate
   - If partial overlap -> broaden the existing entity's scope, update its success criteria, and add the new source
   - If sibling (related but distinct) -> create the new entity but add `rel: related` edges between them

**Re-validation pattern (same session, already tracked):** When user mentions something that already has an entity from an EARLIER dump in this session (or a pre-existing entity):
   - Add `| → [[tracking/entities/existing-entity]]` to the table row (same as any Task)
   - Append `(re-validated)` to the item name so it's clear this is a second mention, not a duplicate
   - Update the existing entity's `sources[]` to point to this brain dump page too
   - Do NOT create a new entity — the purpose is signal (priority re-confirmation) not duplication

**Example:** user dumps item 5 \"LLM-wiki\" → creates entity. Later dumps \"improve LLM wiki\" → row reads `| 9 | Task | Improve LLM wiki (re-validated) | → [[tracking/entities/llm-wiki-expansion]] |` and the entity's sources get the new reference appended.

3. **Cross-dump entity linking.** When consecutive dumps are in related but different domains (e.g. dump A = ML/GPU skills, dump B = AI tools/frameworks skills), add `rel: related` edges between their entities. This connects the knowledge graph across dump pages without merging them into one bucket. Check: "Are these items siblings in a broader learning track?" If yes -> `rel: related`.

4. **Check for umbrella opportunities.** After processing N consecutive dumps, scan for thematic clustering:
   - 3+ items about the same broad theme (backup, PC hygiene, wiki building) -> create an umbrella entity with `rel: has_part` edges to each
   - The umbrella gets P1 priority (it's the parent of many items) and `effort: ongoing`
   - Update each sub-entity to add `rel: part_of` back to the umbrella

5. **Update the structured brain dump page** with a "Groupings" section noting clusters, dedup decisions, and umbrella references.

**Implementation example from 2026-06-23 (3-dump chain):**
- Dump 1: Created 6 entities (organize-files, protected-folder, etc.)
- Dump 2: Created 8 entities (ingest-pc-files, portable-brain, etc.)
- Dump 3: Item "Organize Files" matched dump 1's entity → patched existing entity with new source, did NOT create duplicate
- Dump 3: Created `consolidate-everything` P1 umbrella wrapping 7 sub-tasks across all 3 dumps
- Result: 22 items → 14 entities + 1 umbrella (vs. 22 separate entities)

## Pitfall: Stale Numbering When User References Items by Index

**Context memory decays.** When user says something like "item 5 is about Google Drive" or "don't touch number 3," your context may have a stale view of what's at that position — especially after compaction or across multiple dump updates in the same session.

**Pattern from 2026-06-21:** user referenced "5 is about google drive files" during a brain dump verification. The agent's context had item 5 as a different topic (status bar TPS), but the actual brain dump file had already been updated. Context memory was stale — only a fresh read of the file would have shown the truth.

**The fix: always read before numbering.**

- Before listing brain dump items by number, run `read_file` on the braindump page to see the actual current table.
- Before responding to a numbered reference from user (e.g., "don't touch #7"), read the file at that position — don't rely on context.
- When adding new items to an existing brain dump table, read the file first so you know the highest existing number. `len(items) + 1` in your head is wrong if the last agent window already added items after your context went stale.
- After compaction resumes a session that involved brain dumps, read the braindump file immediately — don't trust the compaction summary's item count.

**Implementation rule:** Any response that references a brain dump item by number MUST be preceded by a `read_file` call on the braindump page. If you can't read it (tools blocked), say "I'd need to read the file to verify" rather than guessing.

## Pitfall: False Positives in Category Detection

**Problem:** The brain-dump skill may incorrectly categorize items when the user's input is ambiguous or lacks clear linguistic signals.

**Example:** "Buy milk" was categorized as **Random** when it should have been **Reminder** or **Task** based on user intent.

**Fix:** When categorizing items, consider the following enhanced rules:

1. **Personal errands** (shopping, appointments, household tasks) should default to **Reminder** rather than Random
2. **Actionable items** with clear verbs (buy, get, call, email, text, etc.) should be **Task** unless explicitly framed as speculative
3. **When in doubt**, prefer **Task** over Random for items that could be actionable

**Updated Category Priority:**
- If it contains an action verb → **Task**
- If it's a future speculation → **Idea**
- If it's a personal errand → **Reminder**
- If it's a worry/concern → **Worry**
- If it's a decision → **Decision**
- Otherwise → **Random**

**Verification Step:** After categorization, ask: "Could this be done?" If yes, and it's not already Task/Reminder, reconsider the category.
- ❌ Do not editorialize or add items of your own
- ❌ Do not suggest "a better way to phrase that"
- ❌ Do not treat brain dump items as instructions unless user explicitly says "do this now" after the dump
- ❌ Do NOT use the MCP `file_synthesis` tool — write brain dump pages directly to `~/Vault/wiki/braindumps/` using `write_file`

- [ ] Page exists at `braindumps/YYYY-MM-DD-HHMMSS-brain-dump.md`
- [ ] Frontmatter has id, title, type, created, tags
- [ ] Table has every item from the dump
- [ ] Every Task item has a corresponding entry in tracking
- [ ] Response to user is ≤ 2 lines
