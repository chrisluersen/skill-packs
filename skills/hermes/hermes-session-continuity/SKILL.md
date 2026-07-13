---
name: hermes-session-continuity
description: Recover context across compacted, queued, or cross-platform Hermes sessions (CLI ↔ Discord ↔ TUI)
category: hermes
tags: [session, continuity, recovery, compaction, discord, cross-session, context, session_search, handoff, task-tracking]
---

# Hermes Session Continuity

Recover context after compaction boundaries, find queued messages from other platforms (Discord/CLI/TUI), and follow parent-child session chains.

## When to Use

- User says "load session <id>" and the context was compacted — don't rely on the summary alone
- User asks "what was I working on" or "you were previously looking at X" after compaction
- User sent messages via Discord/TUI while you were processing on another platform — those messages are in a sibling session
- Context summary says "Unknown from deterministic fallback" — summarizer failed, need raw session data
- User says "yes" to continue a task that was interrupted by compaction

## Key Concepts

| Concept | Meaning |
|---------|---------|
| **Compaction** | Long sessions get compressed — earlier turns replaced by a summary. May be incomplete if summarizer model fails (400 errors, model unavailability). |
| **Sibling sessions** | Messages from different sources (Discord vs CLI) at the same time create separate sessions. User Discord prompts while CLI is processing are in a Discord session. |
| **Parent-child chains** | `parent_session_id` links sessions across compaction boundaries. Follow the chain up. |
| **Queued prompts** | Messages sent via one platform while the agent is processing on another. The agent only sees them on its next turn; they accumulate in the platform session. |

## How to Recover Context

### 1. Scan the Compaction Summary

What the summary tells you:

| Phrase | Meaning |
|--------|---------|
| `"Historical Task Snapshot"` | The last active task before compaction |
| `"Historical Pending User Asks"` | Unanswered requests still pending |
| `"Last Dropped Turns"` | The agent's last action before compaction |
| `"Unknown from deterministic fallback"` | Summarizer failed — summary is mostly useless, go straight to session_search |
| `"Key Decisions"` / `"Resolved Questions"` | Decisions made before compaction |

### 2. Browse Recent Sessions

```python
session_search()  # browse shape: all recent sessions with timestamps + sources
```

Note the `source` field: `discord`, `cli`, `tui`, `cron`, `acp`. The user's active chat platform determines which sessions to inspect.

### 3. Discover by Topic

```python
session_search(query="<topic keywords>", limit=5, sort="newest")
```

The `sort` parameter shapes result ordering:
- `newest` — recency-biased (default for "where did we leave X")
- `oldest` — origin-biased ("how did X start")
- omit — relevance-only ("what do we know about X")

### 4. Read a Full Session

```python
session_search(session_id="<id>")  # read shape: all messages in the session
```

For large sessions (80K+ chars), the tool truncates. Use scroll shape to navigate.

### 5. Scroll Inside a Large Session

```python
# Start with a known message ID from a read/discover result
session_search(session_id="<id>", around_message_id=<id>, window=20)

# Scroll forward by passing the last message id
session_search(session_id="<id>", around_message_id=<last_id>, window=20)

# Scroll backward by passing the first message id
session_search(session_id="<id>", around_message_id=<first_id>, window=20)
```

### 6. Follow the Parent Chain

Each result may have `parent_session_id`. Follow it:

```python
result = session_search(session_id="<parent_id>")
```

Repeat until `parent_session_id` is absent — you've reached the root.

### 7. Find Discord Queued Prompts

Pattern: **User sent messages on Discord while you were processing in CLI**

```python
# Step 1: Find Discord sessions around the right time
result = session_search(query="discord", limit=5, sort="newest")

# Step 2: Look for sessions with source=discord and overlapping timestamps
# with the CLI session where the "deployment" or "processing" ran

# Step 3: Read the Discord session to see the queued messages
result = session_search(session_id="<discord-session-id>")

# Step 4: User messages on Discord appear with "[Username]" prefix
# e.g. "[user] create the window launcher..."
```

### 8. Find TUI/CLI Queued Prompts That Were Missed

**Pattern: User sends a prompt while you're still processing the previous one. The prompt goes to a queue but is never delivered — you see nothing on your next turn.**

The user will say: *"no i send a queued prompt but you missed it"* or *"why did you miss my queued prompt?"*

This is NOT the same as Discord queued prompts. In the TUI/CLI:
- When you're actively processing (tool calls running), a new user keystroke is queued
- **Cause:** The queue delivered but the agent's context was already full or the queue entry was consumed during a compaction boundary and didn't surface as a distinct user message
- **The fix is NOT to find a sibling session** (as with Discord) — the prompt was in the same session, just lost during a context transition

**Recovery steps:**

1. **Check for session forks** — the lost prompt may have created a new session:
   ```python
   session_search(query="<keyword from the conversation>", limit=5, sort="newest")
   ```
   Look for sessions starting around the same timestamp with similar content.

2. **Search the current session lineage** — if the user says they sent "X" but you don't see it, search past sessions for that phrase:
   ```python
   session_search(query="<exact phrase from queued prompt>", limit=3)
   ```

3. **If the prompt was a retry of an earlier request** (common pattern — user says "same thing again" but the original was lost), search for the topic of the original request to find what was dropped.

4. **As a last resort, ask the user** — "I see you sent something that didn't reach me. Can you resend it?" The `/q` prefix queues, but queue delivery can fail across compaction boundaries.

**Pitfall:** Don't confuse "queued prompt was missed" with "user sent prompts on another platform." If they were in the TUI the whole time, there's no sibling Discord session. The prompt was simply lost in the same session — check for session forks.

### 9. Handle "There Were More Messages Before This"

**Pattern: User says "there's a bunch of prompts before those" or "that's not what I asked earlier" — meaning the current context window doesn't show the full session.**

This happens when:
- Context was compacted and the compaction summary was truncated
- The session fork lost the earliest messages
- You started a new session but the user expects continuity from a previous one

**Recovery steps:**

1. **Browse recent sessions** — the session you're in may have a parent or precursor:
   ```python
   session_search()
   ```
   Look for sessions immediately before the current one with related titles.

2. **Check the DB for sessions in the same time window** — if the current session started at 20:02, check 19:45–20:02 for related sessions.

3. **Search by topic rather than session ID** — query for keywords from the work:
   ```python
   session_search(query="<topic>", limit=5, sort="oldest")
   ```
   The `sort="oldest"` parameter finds the origin, not just the latest iteration.

4. **If the user says "you already looked at X"** and you don't remember it, search session history for X rather than assuming they're mistaken.

**Pitfall:** The user's "this session" means "this work thread" — not necessarily the current DB session ID. A single work thread (e.g., "wiki refactoring") may span 5+ DB sessions as it hits compaction boundaries and session forks.

### 10. Cross-Reference Timestamps

When a user asks about "6 queued prompts from discord while waiting for a deployment":

1. Find the CLI session (source=cli) where the deployment/processing happened
2. Note its timestamp range
3. Search for Discord sessions (source=discord) in the same time window
4. Read the Discord session — user messages are the "queued prompts"
5. Each user message in the Discord session represents one prompt

## Pitfalls

| Issue | Fix |
|-------|-----|
| Compaction summary says deterministic fallback but is incomplete | Do NOT trust the summary — use session_search to read raw session data |
| User asks about "queued prompts" from the other platform | They mean messages sent on Discord/other platform while CLI was processing — find the sibling session |
| Session data truncated (34 of 84+ messages shown) | Use scroll shape: pass last message id as `around_message_id` to go forward |
| User prefix differs per Discord server | Messages appear as `[Username]` — search for the username in Discord sessions |
| Multiple sessions match, which is the right one? | Match by timestamp window AND source — Discord messages are in source=discord sessions |
| Memory says vault path X but file at path Y | User moved the vault — update memory and check the user profile too |
| Session found but messages are compaction summaries themselves | Those are older compactions preserved in the DB — scroll past them to find actual conversation |
| Role filter obscures tool output | Default `role_filter` excludes tool output. For debugging tool behavior, pass `role_filter="user,assistant,tool"` |

## 10b. Advanced Session Archaeology — Finding Sessions That Don't Surface

When a `session_search(query=...)` call returns empty or misses a session you know exists, the session is still in the DB but the FTS5 index doesn't match your query terms. This is common when sessions describe work in different terminology than the query.

**Systematic multi-angle search workflow:**

1. **Query by the session's metadata first** — search the `title` and `source` fields visible in browse mode:
   ```python
   session_search()  # browse: see recent session titles and timestamps
   ```

2. **Try read-by-ID even when discover fails** — the `session_id` lookup does NOT go through FTS5, it reads by primary key:
   ```python
   session_search(session_id="20260617_193622_961f6a")
   ```
   A session can be findable by ID even when every query variation returns nothing.

3. **Try multiple query angles** — the same session may surface under different terminology:

   | Query angle | Example terms |
   |-------------|--------------|
   | Tool name | `agent_create klio`, `hermes profiles list`, `final_response_markdown` |
   | File path | `config.yaml`, `fleet-profile-deployment-status.md`, `PLAN.md` |
   | Config value | `render`, `strip`, `deepseek-v4-flash`, `claude-3-5-sonnet` |
   | Commit SHA | `8af8497`, `c02518d`, `git log --oneline` |
   | Page title | `Asteroid Fleet Manifest`, `fleet naming etymology` |
   | Feature name | `gap_detect.py`, `watch_feeds.py`, `wiki-dashboard.html` |

4. **Scroll past truncation** — when a session read shows "34 of 84+ messages", scroll forward to find the resolution:
   ```python
   session_search(session_id="<id>", around_message_id=<last_visible_id>, window=20)
   ```

5. **Follow the parent chain backwards** — repeat `session_search(session_id=parent_session_id)` until `parent_session_id` is absent. This reveals the full work thread, not just the most recent compaction fork.

6. **Cross-reference with `git log --oneline`** — search `session_search(query="<sha>")` to find the session that produced a specific commit. Commit SHAs are unique and memorable across sessions.

**Pitfalls:**
- A session that returns results may describe planned work, not executed work. Cross-reference against live state before updating plans.
- Multiple sessions share the same title (common for "Karpathy Pattern" or "Fleet Manifest" threads). Use `sort="newest"` for recency or browse shape for timestamps.
- The read shape shows a compaction summary as the anchor message (80K+ chars). Scroll past it to find actual user+assistant messages.
- **Session ID alias trap:** `$HERMES_SESSION_ID` may report a DIFFERENT value than the session's stored DB ID. This happens when a session is continued/handoff across instances — the environment variable changes but the data stays under the original DB key. If a user references a session ID that doesn't exist in the DB:
  1. Search message content for the user's quoted session ID string via SQLite: `SELECT session_id, content FROM messages WHERE content LIKE '%<user-id>%'`
  2. This will find where the session ID was mentioned (usually in a tool call result showing `$HERMES_SESSION_ID`)
  3. That message's `session_id` is the DB-stored ID where the actual data lives
  4. Cross-reference by timestamp to confirm it's the same session

## 11. Validate Session Findings Against Live State

After reading session data to extract past decisions, validate each decision/claim against current live state. Sessions can record plans and intentions that were never executed, or describe infrastructure that has since changed.

**The one-pass validation workflow:**

1. **Extract verifiable claims** from the session. Common patterns:
   - "Created a profile for X" → check `ls ~/.hermes/profiles/` for that directory
   - "Set up a cron job for Y" → `cronjob(action='list')` and search for the exact schedule/prompt
   - "Created file at path Z" → check `ls -la <path>` exists and has expected content
   - "Patched file Z" → `read_file(Z, limit=5)` to verify the edit was applied
   - "Deployed agent X" → check multiple signals: profile exists? cron/automation exists? config registered?
   - "Fixed bug in tool MCP" → verify the fix is actually present in the source file

2. **Duplicate detection:** Check for multiple session claims about the same action. A cron job called "klio-weekly" and "klio-weekly-dual" with the same schedule means a duplicate was accidentally created.

3. **Stale claim detection:** A session might say "audit/log.jsonl has real entries" — check reality. If it only has the init entry, the claim was aspirational, not executed.

4. **Fiction detection — auto-generated pages may describe fictional reality:** Cron jobs and autonmous sessions can produce wiki pages in `pending/` that describe a desired future state as if it were already real. The most dangerous variant: a page titled "Deployment Status" or "Profile List" that lists N items as "deployed" when they have never been created. This happens because the agent was asked to create a plan or document the architecture and auto-generated a status page based on the *design spec*, not the *filesystem state*.

   **How to detect fiction in auto-generated pages:**
   - Cross-reference every concrete deployment/configuration claim in `pending/` against filesystem state
   - "All profiles created with `.bat` launchers" → `ls ~/*.bat` or `ls ~/.local/bin/` — do the launchers exist?
   - "SOUL.md personas deployed" → `ls ~/.hermes/profiles/*/SOUL.md 2>/dev/null | wc -l` — count vs claim
   - "Skills cloned from default at creation time" → check if `profiles/` directory even has subdirectories
   - "15 profiles active" → `hermes profiles list` or `ls ~/.hermes/profiles/` — are there 15 directories?

5. **Delta report:** Present findings as:
   - ✅ Confirmed — session claim matches live state
   - ❌ Not executed — session recorded the *intention* but it was never actioned
   - ⚠️ Drifted — was executed but live state no longer matches (paused cron, deleted file, etc.)
   - **❌⚠️ Fictional** — auto-generated page describes a state that never existed (pending/ fiction marker)

**Common patterns that look done but aren't:**
| Session says | What to actually check |
|--------------|-----------------------|
| "Created profile for Klio-84" | Does `profiles/klio-84/` directory exist with `persona.md`? Or is Klio just running as a cron job? |
| "Deployed weekly audit pipeline" | Does the cron exist? Is it enabled (`state: scheduled`, not `paused`)? Does it actually fire? |
| "Fixed the orphan bug" | Does the `wiki_utils.py` patch exist in the file? Has the MCP server been restarted since? |
| "Added sources[] to all pages" | Run a spot-check — are there still pages without `sources` frontmatter? |
| "[All 14 profiles deployed]" | Check `ls ~/.hermes/profiles/` — auto-generated page may describe the design spec, not reality |

**Pitfall:** Don't trust a session's self-report at face value. A session that says "created all 14 entity pages" may have only created 8 and failed silently on the remaining 6. Always verify the count.

**Pitfall:** Auto-generated pages in `pending/` are especially dangerous because they haven't been human-reviewed. A page that claims "15 profiles created" can sit in `pending/` for weeks, and every future agent who reads it takes it as fact. Always validate `pending/` content against live state before promoting.

## 11a. Resume Interrupted Work — Finding the Stopping Point and Next Action

When the user says "what have we done so far and what's next?" or "what are we going to do first?" about a topic from a prior session, the goal is not just to *recover* context but to **resume** — find the exact stopping point and the next concrete action.

**The title trap:** The session you need may be titled after its *primary* task while the user is asking about a *secondary* sub-topic that came up mid-session. Example: a session titled "Fixing OpenRouter Auxiliary Services" also contained a proposal for "missing concept pages" — the user asks about the concept pages, not OpenRouter. Searching by session title or the session's main theme misses it. **Search by the specific sub-topic keyword the user used**, not the presumed session theme.

**Resume workflow:**

1. **Discover by sub-topic** — `session_search(query="<user's exact sub-topic phrase>", limit=5)`. The user's phrasing is the best query because they're referencing what they remember.
2. **Scroll to the session's END** — use `around_message_id` with the anchor from the discovery result, then scroll forward until `messages_after < window` (you've reached the end). The last assistant message is where work stopped — it usually contains the "I'll do X next" or "would you like me to proceed with Y?" proposal.
3. **Extract the proposed-but-not-done item** — the final message typically proposes a next step that was never executed (the session ended or compacted before the user responded). That proposed item is your resume point.
4. **Verify on-disk state** — this is the critical step. The session summary's "Completed Actions" list is *aspirational*. For each claim relevant to the resume point, check the filesystem:
   - "Created tracking pages with frontmatter" → `head -15 tracking/*.md` — do they actually have the frontmatter?
   - "Added relates_to edges" → are the edges present?
   - "Created concept pages" → do they exist in `pending/` or `concepts/`?
   - **Most importantly: check for gaps the summary didn't flag.** A summary may list "added frontmatter" as done but not mention that `sources[]` arrays are empty (a deeper compliance violation). Read the actual files and compare against the schema's non-negotiables, not against the summary's self-report.
5. **Report the verified state** — present three categories:
   - ✅ **Confirmed done** — summary claim matches on-disk reality
   - ⚠️ **Gap** — summary claimed done but verification reveals an incomplete aspect (e.g., frontmatter present but `sources[]` empty)
   - ❌ **Not done** — the proposed next-step item was never executed
6. **Act on verified state** — proceed with the resume-point item, informed by the gaps found. Don't redo confirmed-done work; do fix gaps before building on top of them.

**Pitfall — don't trust the summary's "Completed Actions" as ground truth.** A compaction summary aggregates what the agent *said* it did, not what actually landed on disk. The summary may also omit failures (e.g., a turn spent on failed `skill_manage` patches that produced no file changes). Only filesystem verification tells you the real state.

**Pitfall — don't redo work the summary lists as done without checking.** If you skip verification and start recreating pages that already exist, you create duplicates and waste a turn. Always `ls` / `head` / `read_file` the target location first.

**Pitfall — don't assume source files from the previous session still exist.** A task like "merge companion files into the report" assumes all referenced files are on disk — but they may have been deleted, moved, or renamed in a subsequent session. Before reading, editing, or merging files named in a prior session's task description, verify their existence with `search_files(target="files", pattern="<filename>")` or `ls`. If they're missing, report the gap to the user rather than proceeding with stale operations. This is the #1 source of "files not found" errors during resume workflows.

**Pitfall — check for moved file trees.** If `Vault/AI Stack/` was referenced in the prior session but the directory no longer exists, the entire file tree may have been restructured. Broaden the search: look for the specific filenames (not just the directory) across the user's home directory before concluding the data is lost entirely.

**Pitfall — check for existing equivalents before creating new pages.** When resuming a "create concept pages" task, search the target directory for pages that already cover the same ground (e.g., `concepts/cron-jobs.md` may already exist when you're about to create `cron-job-management.md`). If an equivalent exists, add a cross-link edge to it instead of duplicating. This is the #1 cause of wiki fragmentation during resume work.

## 11b. Recall Findings from Generated Artifacts

When a user asks "what were the findings of our X research?" or "what did we put in the Y guide?", the substantive findings often live in a **generated artifact file** (HTML report, markdown doc, generated guide), not in the session transcript itself. Session transcripts record the *process* (editing, polishing, refactoring) but the actual *content* is in the file.

**The artifact-first recall workflow:**

1. **`session_search(query=...)` to find related sessions** — but expect that the top hit may be a *polish/refactor* session, not the original research session. The session that *created* the artifact may be a parent or sibling. If the first result's snippet shows patch/regex/editing operations rather than research findings, do a second more targeted search (quoted phrases from the artifact's title/description).

2. **Identify the output artifact** from the session's file references, compaction summary, or tool calls. Common patterns:
   - HTML guides: `~/AI Architecture.html`, `~/OneDrive/Vault/AI Stack/hermes-agent-report.html`
   - Markdown reports: `~/Vault/wiki/`, `~/.hermes/plans/`
   - Generated configs: `~/.hermes/profiles/`, `scripts/`

3. **Extract content directly from the artifact file** — do NOT rely on session transcript snippets, which only show fragments of the file being edited. Use `execute_code` with Python's native `open()`:

   ```python
   with open(r"C:\path\to\file.html", "r", encoding="utf-8") as f:
       content = f.read()
   ```

   **Pitfall: `read_file` truncates at 500/2000 lines and adds `NNN|` line-number prefixes** that break regex/HTML parsing. For large HTML files, always use Python `open()` in `execute_code`. See `references/recall-from-html-artifacts.md` for the full extraction pattern (strip `<style>`/`<script>`, preserve section structure, strip tags, decode entities).

4. **Synthesize and present** — extract the key findings, structure them for the user, and cite the artifact location so they can open it.

**When this pattern applies:**
- "What were the findings of our X research?"
- "What did we put in the Y guide?"
- "What's in the Z report we created?"
- "Remind me what the stack guide says about X"

**Key insight:** Session search finds *where work happened*, but the *what* is in the files that work produced. Always check the artifact, not just the transcript.

## 12. Proactive Handoff — Saving Remaining Work Across Sessions

The counterpart to session recovery: **before the session ends (or when compaction is imminent), save remaining work for future agents.** This ensures nothing drops between compaction boundaries or across sessions.

### Trigger

After every task completion where there's still outstanding work:
- Remaining API keys to add
- Verification steps not yet done
- TODO list items that weren't completed
- Fixes, patches, or expansions deferred

### Target

User's wiki tracking system at `~/AppData/Local/hermes/Vault/wiki/`:
- **`tracking/tasks.md`** — Cross-cutting tasks, sorted by priority (🔴 Urgent → 🟡 High → 🟠 Medium → 🔵 Low)
- **`tracking/index.md`** — Dashboard overview showing all active items
- Both use markdown table format with `| # | Task | Context | Depends On |` columns

### Workflow

1. **Compile remaining work** — scan for every uncompleted item: un-added API keys, un-verified features, deferred fixes, un-tested fallbacks
2. **Format as tasks** — one row per item with clear context (exact commands, file paths, provider names) and dependency notes
3. **Update `tracking/tasks.md`** — add new entries in the correct priority section. Preserve existing entries — only add, don't overwrite existing tasks.
4. **Update `tracking/index.md`** — add new items to the Cross-Cutting Tasks table if they're visible there
5. **Reindex** — always call `mcp_wiki_reindex_wiki()` afterward so the new tasks are FTS5-searchable
6. **Commit** the changes so they survive git operations

### Format

Each task entry must include:
- **Task** — one-line action item
- **Context** — what commands, paths, or providers are involved, why it matters (free model? cost savings? unblocks what?)
- **Depends On** — what must be done first (use `#<task-number>` references when the dependency is in the same table)

### What NOT to save

- **Completed items** — those go in the past session, not in the future task list
- **Environment-specific transient errors** — missing binary, fresh install failure. These are fixable, not durable constraints.
- **Session narratives** — don't record "we tried X and then Y happened". Only record what still needs doing.
- **Wiki build phases** — those go in `todo.md`, not `tracking/tasks.md`. The tasks file is for cross-cutting operational work.

### Verification

After updating:
- `mcp_wiki_search_wiki(query=<task keyword>)` — new tasks should be discoverable
- Read back the updated `tasks.md` — entries should be formatted correctly (no mangled table pipes)

### Pitfalls

- **Don't duplicate existing tasks** — always read the current `tracking/tasks.md` before adding. If the task already exists (same exact wording), skip it.
- **Don't remove existing tasks** — only add. Deferral decisions belong in memory or the decision log, not in the task list.
- **Reindex is not optional** — without it, the new tasks are invisible to `mcp_wiki_search_wiki`. Always call it after every update.
- **Priority decay** — tasks saved today may be less urgent next week. The stale-task handling is a separate workflow (Klio's domain).

## 11c. Session Knowledge Mining — Extract Cross-Project Context

When a user says "review session X and see what's relevant to my projects/tasks," the goal is **structured knowledge extraction**, not just session recovery. The session may be a meta-review (a session that itself reviewed other sessions), and the relevant signal is scattered across bookends, tool calls, and compaction summaries — not in one clean message.

### The Multi-Pass Extraction Workflow

**Pass 1 — Browse & Bookends (30 seconds)**
```python
# Step 1: Get the session's scope
session_search(session_id="<id>")
```
Read the session title, source, model, and message count. Then read the first few messages (the kickoff/goal) and last few (the resolution/decisions). This tells you:
- What the session was *trying* to do (kickoff)
- What it *decided* or *produced* (resolution)

**Pass 2 — Anchor Scroll (1-2 minutes)**
```python
# Step 2: Find the anchor (discovery-by-topic or scroll to the end)
session_search(query="<relevant keyword>", limit=3, sort="newest")
# OR scroll to the end by finding the last anchor message
```
Scroll through 1-2 windows of key sections. Don't read every message — look for:
- **Decisions** — "going with X over Y", "approved", "confirmed"
- **Status updates** — "X is done", "Y is blocked because..."
- **Proposed work** — "next I'll do Z", "add task for W"
- **Subagent summaries** — these are the most information-dense messages in a session

**Pass 3 — Structured Extraction for Large Sessions (when scroll view is fragmented)**

When the session is 80K+ chars and the scroll view shows fragmented snippets, use `execute_code` to extract structured data from the `session_search` result (available as a Python dict in `execute_code`):

```python
import json

# session_search result is returned as a Python dict
# You can access message data from the search result
messages = result["messages"]

# Find the last major assistant message (the resolution/synthesis)
for m in reversed(messages):
    if m["role"] == "assistant" and len(m.get("content","")) > 200:
        print(f"=== End-of-session summary (id={m['id']}) ===")
        print(m["content"])
        break
```

**Pass 4 — Synthesize by Category (1-2 minutes)**

Group findings by the user's project domains. For user, these are:
1. **Agent Fleet** — profile status, fleet pipeline, tier splits
2. **Router** — provider config, bug fixes, routing verification
3. **Wiki** — tracking pages, pending items, provenance, lint issues
4. **Hermes Growth** — terminal stack, memory backup, project directories

For each category, extract:
- ✅ **Confirmed done** — verified against session evidence
- ⚠️ **Gap identified** — problem found but not fixed
- ❌ **Blocked/not done** — intended but unexecuted
- **Key decisions** — rationale that future work must respect

**Pass 5 — Report (30 seconds)**

Present a structured summary: 1-2 sentences per category, bullet points, bottom line. Don't dump raw session output — the user wants the synthesized signal.

### When This Applies

- User asks "review session X and see if any info provides context for my tasks"
- User asks "what did session X say about Y project?"
- Session is a meta-review (was itself mining other sessions)
- You need to extract actionable intel from a session you weren't present for

### Pitfalls

| Issue | Fix |
|-------|------|
| Session is 129K chars with 110+ messages | Don't try to read every message. Use the multi-pass approach — bookends → scroll → execute_code extraction |
| The session is a meta-review (reviewing other sessions) | The useful content is in the **subagent summaries** and **synthesis messages**, not in the raw session reads. Focus on what the meta-reviewer *concluded*, not what it *read*. |
| Compaction summaries within the session are truncated | Scroll past them — the actual work happened in the turns between compactions |
| Session claims "X is done" but it was aspirational | Cross-reference against live state for critical dependencies. Meta-reviews can repeat claims from prior sessions that were never executed. |
| The session's title doesn't match the topic you're mining | Search by sub-topic keyword that the user used, not by session title. A session titled about one thing often contains significant work on another. |

### Worked Example

See `references/session-knowledge-mining-example.md` for the full worked example with session `20260618_153136_3bc2e9` — a meta-review session that mined 12 sessions and produced project-spanning context.

### Deleted Source Files on Resume

See `references/deleted-source-files-on-resume.md` for the pattern of files referenced in a prior session being gone on resume — the workflow for finding them (or confirming they're lost) and reporting the gap to the user.

## 12. Finding the Current Session ID

When beginning **any** session recovery or archaeology work, first check the current session environment to establish the context baseline. The canonical source is `$HERMES_SESSION_ID`:

```bash
echo "$HERMES_SESSION_ID"
```

This is the canonical way to find the current session's DB key. The session ID is set at session creation and persists for the session's lifetime.

### Why This Matters

- Cross-referencing: the user may want to bookmark, share, or reference this session later
- Session linking: when saving artifacts or tasks, citing the session ID in `sources[]` frontmatter enables provenance tracing
- Debugging: if you notice odd behavior, the session ID helps trace it back

### Pitfall: Session ID Alias

The `$HERMES_SESSION_ID` value may differ from the session's stored DB ID when a session is continued across instances (handoff/restore). See **Section 10b — Advanced Session Archaeology** for the recovery technique. But in normal operation (no handoff), `$HERMES_SESSION_ID` is the correct identifier.

## 13. Session List Display Limits in `herm`

`herm` (the bun TUI, installed via `herm-tui` bun/npm package) uses the **same session IDs** as the Hermes session DB — there is no separate ID format. However, two limitations affect session discoverability:

### 13.1 The `roots()` Limit of 30

From the `db.worker.js` code: `roots()` queries the sessions table with a **default LIMIT 30**. This means the `herm` session list only shows the 30 most recent **root** sessions (non-compressed, non-child sessions). Older sessions **still exist in the DB** but don't appear in the default session list.

**Recovery:** Use `session_search(query=...)` to find older sessions by topic, or read by full session ID.

### 13.2 The `trunc5(sid, 24)` Display Truncation

From the `index.js` source: the switch-session confirmation dialog uses `trunc5(sid, 24)` to display the session ID. This is a soft truncation:
- Standard-format session IDs (`YYYYMMDD_HHMMSS_XXXXXX` = 23 chars) pass through unchanged
- Older 8-char-suffix IDs (`YYYYMMDD_HHMMSS_XXXXXXXX` = 25 chars) lose their last character **in the dialog only**
- The session ID stored in the DB and used in all other UI rendering is always the full ID

**This is NOT the cause of "can't find session" issues.** The real cause is:
- The `roots()` LIMIT 30 (session not in the recent list)
- Multi-format session ID ecosystem (see Section 14)

### Key Distinction

`herm` does NOT generate a separate "short ID" (like `da3c457d`). The session ID you see in the session list **is** the Hermes session ID. The only truncation is the 24-char dialog display, which is essentially a no-op for modern sessions.

### Session ID Sources — Canonical Hierarchy

| Source | Correct? | Notes |
|--------|----------|-------|
| `$HERMES_SESSION_ID` | ✅ Always canonical | Set at session creation, valid until session end |
| `HERMES_TUI_ACTIVE_SESSION_FILE` | ✅ Canonical | Temp file at `%TEMP%/hermes-tui-active-session-*.json`, contains `{"session_id":"..."}` |
| `herm` session list | ✅ Canonical | Shows the full DB session ID (same as env var) |
| `herm` switch dialog | ⚠️ May be truncated | `trunc5(sid, 24)` — only affects 25+ char IDs |
| `state.db` sessions table | ✅ Canonical | Primary key is the full session ID |

### Cue-Based Identification

When the user reports a session ID that doesn't match the DB:

1. Check `echo "$HERMES_SESSION_ID"` — this always gives the correct ID
2. Check `cat "$HERMES_TUI_ACTIVE_SESSION_FILE"` — same ID, alternate source
3. If the user's ID is 23+ chars and follows `YYYYMMDD_HHMMSS_XXXXXX`, it IS the DB ID
4. If the user's string is shorter (e.g. `8af8497` or `db332727`), it's likely a **partial suffix** — search the DB by hex fragment (see Section 14)

### Why This Matters

The `roots()` LIMIT 30 means sessions from earlier in the same day may not appear in the `herm` session list, even though they're still in the DB. Always use `session_search(query=...)` to find sessions by topic rather than relying on the session list.

## 14. Multi-Format Session ID Ecosystem

The Hermes `state.db` contains session IDs in **multiple historical formats**, not just the current standard. When a user references a session ID that doesn't match the current format, it may still exist in the DB under an older format.

### Known Session ID Formats (from `state.db` audit)

| Format | Example | Length | Count (approx) | Period |
|--------|---------|--------|----------------|--------|
| **Current standard** (6 hex suffix) | `20260619_102733_1edadf` | 23 chars | ~900 | Current |
| **8-hex suffix** (older) | `20260601_174914_db332727` | 25 chars | ~50 | Early June |
| **Cron** | `cron_1543384cb1da_20260614_084509` | ~35 chars | ~40 | June 13-18 |
| **Background task** | `bg_120426_cc4ee3` | ~16 chars | 1+ | Occasional |
| **Short hex** (primordial) | `00767e933d69` | 12 chars | 12 | Early sessions |
| **UUID** | `1e8eb132-dd36-4357-b8f2-afc40dcf1d81` | 36 chars | 11 | Migration artifacts |

### The Format Transition (8-hex → 6-hex suffix)

Older sessions (approximately before June 15) used `YYYYMMDD_HHMMSS_XXXXXXXX` (8 hex chars in the suffix). Newer sessions use `YYYYMMDD_HHMMSS_XXXXXX` (6 hex chars). Both formats coexist in the DB.

**Impact on `trunc5(sid, 24)`:** The 25-char 8-suffix IDs DO get their last character clipped by `trunc5(sid, 24)` in the `herm` switch dialog. The 23-char 6-suffix IDs pass through unchanged.

### How to Resolve Partial Session IDs

When a user gives you a short hex string (e.g. `db332727` or `1edadf`) that they see as a "session ID":

1. **It's likely the hex suffix of a full session ID.** The suffix is unique because the timestamp prefix makes collisions extremely unlikely.
2. **Search the state.db by suffix:**
   ```sql
   SELECT id FROM sessions WHERE id LIKE '%<suffix>' LIMIT 5;
   ```
   Example: `SELECT id FROM sessions WHERE id LIKE '%1edadf' LIMIT 5;`
3. **If the suffix is 8 hex chars**, try matching against 8-suffix IDs OR try the first/last 6 chars of that 8-char suffix.
4. **If the suffix is 4-6 hex chars**, try `LIKE '%<suffix>'` — it will match against both 6-suffix and 8-suffix IDs (8-suffix IDs contain the shorter suffix as a substring).
5. **If no match found**, the session may be a cron ID: format `cron_<12hex>_<timestamp>`. Search by the hex portion.

### `HERMES_TUI_ACTIVE_SESSION_FILE` — The TUI-to-DB Bridge

When `herm` is running, it writes the full session ID to a temp file at:
```
%TEMP%/hermes-tui-active-session-<random>.json
```
Contents: `{"session_id":"20260619_102205_97fdf0"}`

This is the **definitive bridge** between the TUI session and the Hermes DB — it always contains the canonical full session ID. Use it when:
- `$HERMES_SESSION_ID` is empty or stale
- The TUI shows a session but you can't find it in the DB
- The user is in `herm` but you're in a Hermes CLI session

### Compression Chain Tracking

Compressed sessions have `parent_session_id` pointing to their predecessor. Follow the chain up to find the original session root:
```sql
SELECT id, parent_session_id, end_reason FROM sessions WHERE parent_session_id IS NOT NULL;
```
The `roots()` function in `db.worker.js` walks these chains automatically for the session list display.

### Cross-Format Session Search Strategy

When searching for a session by ID fragment:

1. **Is it a timestamp prefix?** `20260614` → `SELECT id FROM sessions WHERE id LIKE '20260614%'`
2. **Is it a hex suffix?** `db332727` → `SELECT id FROM sessions WHERE id LIKE '%db332727'` (may match 6 or 8 char suffixes)
3. **Is it a UUID?** Contains hyphens → direct match
4. **Is it a cron ID?** Starts with `cron_` → direct match
5. **Is it a short hex?** 12 chars with no timestamp → `SELECT id FROM sessions WHERE id = '<hex>'`

**Better approach:** Use the `herms` CLI tool instead of writing raw SQL. See Section 15 below.

See `references/session-id-formats.md` for the full format archaeology with counts and queries.

## 15. Session Registry Tool (`herms`)

**RECOMMENDED for session lookups** — wraps the raw SQL from Section 14 into one command. Handles all 7 known ID formats, alias generation, title search, timeline filtering, and format-epoch tracking. Append-only design survives state.db pruning.

### Setup (already in place)

- **DB:** `~/.hermes/session_registry.db`
- **Scripts:** `~/AppData/Local/hermes/scripts/herms.py` (CLI), `session_registry_sync.py` (sync)
- **Alias:** `herms` in `.bashrc`
- **Cron:** `*/5 * * * *` with `no_agent=true` — silent unless new sessions detected. Syncs state.db AND checks active-session watchdog file for in-flight tracking.

### Commands

| Command | Use case |
|---------|----------|
| `herms lookup <partial-id>` | Search by hex suffix, title, or alias across all formats |
| `herms search <query>` | Full-text search over titles + descriptions via FTS5 |
| `herms resolve <partial-id>` | Get full session ID for piping to `herm --resume` |
| `herms list --since YYYY-MM-DD --source tui` | Filtered session listing |
| `herms stats` | Registry health, format epochs, sync status |
| `herms sync` | Force an immediate pull from state.db |

### FTS5 Full-Text Search

The registry has a `description` column (backfilled from the first user message in `state.db`) and an FTS5 virtual table `sessions_fts` over `id`, `title`, and `description`. The sync script rebuilds the FTS5 index on every run.

```bash
herms search "fleet"                    # single word (AND by default)
herms search "discord screen"           # AND: matches both terms
herms search "router OR tailscale"      # boolean OR
herms search '"session registry"'       # exact phrase
herms search "disc*"                    # prefix wildcard
herms search "screen" --verbose         # show description snippet + BM25 rank
herms search "screen" -n 3             # limit results
```

If FTS5 syntax errors (malformed query), falls back to `LIKE '%query%'` on title + description.

### Description Backfill

Sessions with empty titles get their `description` field populated from the first user message in `state.db`. This enables natural-language search for sessions that only show as `(no title)` in listings.

- Backfill runs as a one-time sweep after each sync, then only for new/changed sessions
- Session titles from `state.db` are preferred when available
- 504 descriptions backfilled on initial run (all sessions without titles that had messages)

### Key Workflow — Resume by Partial ID

```bash
herm --resume $(herms resolve 1edadf --pick-first)
```

### What It Handles vs. What It Doesn't

| Handles | Doesn't handle |
|---------|----------------|
| All 7 ID formats (6/8-suffix, UUID, 12-hex, cron, bg, label) | Sessions that crash before the first `$HERMES_SESSION_ID` write (~1s window) |
| 4/6/8-hex suffix matching, title + FTS5 description search | Does NOT need manual sync — the watchdog catches in-flight IDs within 5 min |
| Timestamp filtering, source filtering | Empty sessions (opened and closed without typing) — excluded by design |
| In-flight active sessions via watchdog | — |

### ✅ Crash Survival — Proactive Watchdog (Implemented)

The registry now captures active sessions BEFORE they reach state.db via a three-layer chain:

```
Your terminal (bash PROMPT_COMMAND)
    │  writes $HERMES_SESSION_ID to ~/.hermes/active_session every prompt
    ▼
~/.hermes/active_session ──────────────────┐
                                            │
TUI session file                            │
(%TEMP%/hermes-tui-active-session-*.json)  ├──→ cron */5 * * * *
                                            │    session_registry_sync.py
                                            │    track_active_sessions()
                                            ▼
session_registry.db ←── inserted as "(in-flight)" with ended_at=NULL

Later, when the session closes:
state.db gets the record ──→ next cron tick updates ended_at + title
```

**What survives a crash:**

| Scenario | Outcome |
|----------|---------|
| Session runs 1+ min, then crashes | ✅ Captured. PROMPT_COMMAND wrote the ID before the crash. Next cron tick (≤5 min) registered it as in-flight. |
| Session crashes immediately, no chat | ✗ Not captured — but you don't want those (zero-content sessions ignored by design) |
| Terminal closes without `exit` | ✅ `~/.hermes/active_session` is a file, persists until next shell writes to it. The last ID remains. |
| `herm` TUI session crashes | ✅ TUI written session file (temp, survives process crash). Also captured via PROMPT_COMMAND if in same terminal. |

**How it works:**

1. **`.bashrc` PROMPT_COMMAND** — fires on every prompt, writes `$HERMES_SESSION_ID` to `~/.hermes/active_session`
2. **Cron cron every 5 min** — `session_registry_sync.py` runs, calls `track_active_sessions()`, which reads both the `active_session` file and the TUI temp file
3. **Unknown IDs get inserted** — any session ID not yet in the registry gets a row with `ended_at=NULL` and `source='active_watchdog'` or `'tui_watchdog'`
4. **Later sync fills the gap** — when the session closes and state.db gets the record, the same script's main sync updates the in-flight row with real `ended_at`, `title`, and `message_count`

**Implementation details:**

- `track_active_sessions()` in `session_registry_sync.py`
- Falls back to scanning `%TEMP%/hermes-tui-active-session-*.json` if `$HERMES_TUI_ACTIVE_SESSION_FILE` env var isn't available (cron context)
- Silent until something changes: `no_agent=true` means only non-empty script stdout is delivered

### What to Tell the User

If someone asks "will the registry track my session if it crashes?":

> Yes — as long as the session had at least one prompt fired (so PROMPT_COMMAND wrote the ID before the crash). The active-session watchdog catches it within 5 minutes and registers it as in-flight. When the session later closes, state.db fills in the proper end time. Empty sessions (opened and closed without typing) are not tracked by design.

See `references/session-registry-tool.md` for full documentation, alias generation rules, and schema.

## Related Skills

- `hermes-agent` — General Hermes configuration and CLI usage (bundled, read-only)
- `session_search` tool — built into the agent toolkit, always available