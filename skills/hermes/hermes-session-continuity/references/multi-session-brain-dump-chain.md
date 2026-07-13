# Multi-Session Brain Dump Chain Recovery

## The Pattern

When user brain dumps across multiple sessions, the chain commonly follows this sequence:

1. **Session A** (brain dump session) — user starts dumping content. The session auto-closes or user says "close out, brain dump next time." The brain dump content existed only in user messages that were **compacted before persisting to the wiki**.
2. **Session B** (other work) — user switches to a different project, does a deliberate closeout. May mention "brain dump next time" as a passing note.
3. **Session C** (recovery) — user returns and asks "find my zellij brain dump" or "review and continue where you left off."

## The Failure Mode

Context compaction eats the brain dump content. `session_search` returns zero matches because the user message that contained the dump existed only in a previous agent window's memory — it was never written to any DB-stored message. The wiki has no record. The content is **permanently lost** unless a raw save interleaved mid-session (see brain-dump skill's compaction pitfall).

## Recovery Workflow

When the user says "review and continue where you left off" or "find my brain dump about X":

### Step 1: Browse Recent Sessions

```python
session_search()  # browse shape — all recent sessions with timestamps
```

Note the pattern of session types:
- **Auto-closed** session (no explicit closeout, often ends mid-thought with a compaction boundary)
- **Deliberately closed** session titled "Next Step: X" with explicit closeout
- **Cut-off** session (ended at max tool calls — last assistant message is mid-query)

### Step 2: Read Each Session's Bookends

```python
session_search(session_id="<id>")  # read shape — shows first 20 + last 10 messages
```

For each recent session:
- **First 3 messages** — what was the goal/kickoff?
- **Last 3 messages** — was there a resolution, or was it cut off?
- **Check the closeout type:**
  - "do a close out" → deliberately closed, work was captured
  - "[CONTEXT COMPACTION]" → auto-closed, work may be lost
  - Last message is a mid-query tool call → cut off, work in flight

### Step 3: Identify the Chain

Label each session by content and closeout type:

| Session | Title/Topic | Closeout | Status |
|---------|-------------|----------|--------|
| A | Brain dump #54 | Auto-closed | ❌ Content may be compacted out |
| B | Fleet Router Docs #10 | Deliberate ("close out, brain dump next") | ✅ Closed with queue for brain dump |
| C | (recovery) | Cut off mid-turn | ❌ Never completed |

The "brain dump next session" queue from Session B + the auto-closed content from Session A = the thread.

### Step 4: Search for the Lost Content

If user mentioned a specific topic (e.g., "zellij"):

1. **Search the session chain's messages** for the topic:
   ```python
   session_search(query="zellij brain dump", limit=5, sort="newest")
   ```

2. **If FTS5 returns nothing**, the content was compacted out. Check:
   - Related setup sessions (zellij was installed in a June 18 session — the brain dump was about *config/keybinds/tasks*, not setup)
   - The content may exist in non-brain-dump sessions under different terminology

3. **If the content existed but was never persisted**, it's gone. Report this clearly to user:
   - Say what sessions were involved
   - Say what topic was referenced
   - Say the content didn't survive compaction
   - Offer to recapture it now

### Step 5: Report the Full Thread

Present the chain to user so they can decide what to do:

```
You had 3 sessions going back to [time]:
1. Brain dump #54 — auto-closed before the zellij stuff was captured
2. Fleet Router Docs #10 — you deliberately closed with "brain dump next time"
3. Last session — cut off while looking for the zellij content

The zellij brain dump was lost to compaction. Want to recapture it?
```

## Prevention

This pattern is why the `brain-dump` skill's compaction pitfall mandates **interleave raw saves** — after each user message in a brain dump session, write `braindumps/YYYY-MM-DD-HHMMSS-raw-<slug>.md` with the verbatim content. Without that, any brain dump that spans multiple context windows is at risk of permanent loss.

## Cross-References

- **`brain-dump` skill, "Pitfall: Context Compaction Eats Brain Dump Content"** — the interleave fix
- **`session-closeout` skill, Step 0c** — orphaned brain dump content check during closeout
- **`hermes-session-continuity` skill, Section 11a (Resume Interrupted Work)** — general pattern this is a specific instance of
- **Session chain example:** `20260620_141332_15ba84` (brain dump #54) → `20260620_193032_7376a7` (fleet router docs #10) → cut-off
