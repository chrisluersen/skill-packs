# Session Closeout Self-Review

> **Class level:** Quality verification / closeout hygiene
> **Added from:** 2026-06-19 fleet routing & persona fix session
> **Applies to:** Any session where files were modified, not just plan-phase work

## Why This Exists

After completing work, the natural instinct is to declare "done" and move on.
But files accumulate contradictory context across a session: you fix one thing but
forget to update three other places that reference the old behavior. The self-review
catches these before the next session inherits stale state.

This is **not** a plan-vs-reality audit (that's the main `post-phase-review` workflow).
This is a **read-back-everything-you-touched** verification step. Different class of bug.

## The Pattern

### Step 1 — Inventory Everything You Changed

List every file you wrote, patched, or created this session:

```bash
# Files in hermes config
~/AppData/Local/hermes/scripts/fleet-manager.py
~/AppData/Local/hermes/profiles/<agent>/SOUL.md
~/AppData/Local/hermes/scripts/fleet-state.json

# Plan docs
~/.hermes/plans/<plan>.md
~/.hermes/plans/session-closeout-*.md
```

For each file, ask: **did I touch it?** Even a one-line patch counts.

### Step 2 — Read Each One Back for Stale Content

For each file, check for **four categories** of defects:

#### Category A: Stale Claims

The file says something that was true *before* your fix but is now wrong.

**Signals:**
- "Needs re-testing after fix" — was the fix AND retest completed in this session? If yes, mark resolved.
- "Known issue: X does Y wrong" — did you fix X? If yes, update.
- Any paragraph that ends with "not yet implemented" — was it implemented? If yes, update.

**Real example from 2026-06-19:** The plan doc's `Remaining Quality Issues` section said
Artemis and Atalanta output "needs re-testing after persona fix" — but both were
tested and Ceres-approved in the same session. The section was stale.

#### Category B: Leftover Cruft

Intermediate fix artifacts that shouldn't exist in the final state.

**Signals:**
- A variable/field in the payload that was the *old* approach before you refactored
- A parameter passed to a function that the function no longer uses
- A comment documenting behavior that was changed
- A dead code path that was the *old* fix that got superseded

**Real example from 2026-06-19:** The `astraea_plan` field was removed from the
`publish()` call to Ceres but was STILL being passed in the `dispatch_to_agent()`
payload. The old approach was "remove from publish, keep in dispatch" and the
new approach should have been "remove from both." The dispatch payload was left
untouched — a classic intermediate-fix artifact.

#### Category C: Cross-File Contradictions

Two files say different things about the same fact.

**Signals:**
- Plan doc says `[ ] Task X not done` but the actual artifact has X working
- Plan doc says `[x] Fix applied` but the artifact doesn't have the fix
- Verification checklist says something is pending but the tests were run
- fleet-state.json counters don't add up

**Real example from 2026-06-19:** The verification checklist in the plan doc had
`[ ] Artemis search quality verified` — but the fleet-manager.log shows Ceres
approved Test 3 re-run. Checklist and reality disagreed.

#### Category D: Missing Propagation

You fixed X in one place but the same pattern exists in a second place.

**Signals:**
- You updated a prompt in one event type — is there a similar event type that needs the same update?
- You added a `_clean_response` filter for one pattern — does the same artifact appear elsewhere?
- You updated one agent's SOUL.md — do other agents have similar issues?
- You changed a parameter name — did you update all callers?

**Real example from 2026-06-19:** After fixing the `workflow_staged` prompt to remove
`astraea_plan`, the patch was applied to `publish()` but not `dispatch_to_agent()`
— the same leak existed in two pathways but only one was fixed.

### Step 3 — Verify fleet-state.json and Memory

**fleet-state.json checks:**
- Do `approved + rejected == requests_processed`? If not, the pipeline counters drifted across code revisions. Note this as approximate.
- Do per-agent stats make sense (each pipeline request involves ~4-5 agent invocations)?
- Are there agents with 0 invocations that should have been tested? (e.g. Iris-7, Harmonia-40, Klio-84)

**Memory checks:**
- Does memory still reference stale facts from before this session's fixes?
- Did the session discover new durable facts that should be saved?
- Are any memory entries contradictory with the new state?

### Step 4 — Update the Closeout Document

The closeout document should capture:

1. **What was accomplished** (bullet points, not narrative)
2. **Files modified** (full paths)
3. **Three categories of fixes:** bugs fixed, improvements made, design decisions
4. **Verification status** — which tests passed with Ceres approval
5. **Known limitations** — what's acknowledged but not changed

**Audit findings section** (new addition from this session's learnings):
Add a subsection that explicitly calls out what the self-review found:
- What was caught and fixed during review
- What was acknowledged as approximate/untested
- This is *meta* documentation — the review of the review

### Step 5 — Update the Plan Doc's Checklist

If the plan doc has a verification checklist, walk through EVERY item:
- Is an `[ ]` item actually done now? Mark `[x]` and add a note.
- Is an `[x]` item now wrong because the fix changed the approach? Consider what to do.
- Are there new items that should be added?

**Pitfall:** Don't just mark the items you remember. Re-read the entire checklist
section and verify each one, even the ones you think are done. The stale items
are the ones you *think* are correct.

## Common Patterns This Misses

| Defect | Why self-review misses it | Mitigation |
|--------|--------------------------|------------|
| Missing feature entirely | You forgot to build it — the file doesn't mention it because it doesn't exist | Cross-reference the plan's spec against actual files |
| Wrong test input | Test passed but with wrong inputs (Artemis used "egress" as search query — it returned "results" but they were wrong) | Read the test output in detail, not just Ceres's verdict |
| Wrong model/config | fleet-manager.py dispatches to right agent but agent uses wrong model | Check each profile's config.yaml independently |
| Persona bleed that looks clean | SOUL.md says "no roleplay" but persona still has strong voice (e.g. "Target acquired." as a delivery intro) | After verifying the *content* is correct, check the *tone* of delivery for subtle bleed |

## When to Run This

Every time before closing out a session, regardless of:
- How confident you feel ("I fixed everything")
- How simple the change was ("just a one-line patch")
- Whether the user asked for it

The user's signal for this: *"double check and make sure you did the best job possible"*
— but don't wait for that. Proactive self-review is the goal.

## Relationship to post-phase-review R3

| Dimension | post-phase-review R3 | Session Closeout Self-Review |
|-----------|---------------------|------------------------------|
| When | After completing a plan phase | After any work session |
| Scope | Phase deliverables vs plan spec | All files touched during session |
| Focus | Backfill gaps in deliverables | Catch stale/contradictory metadata |
| Output | Updated plan, patched gaps | Updated closeout doc, corrected files |
| Scale | Larger (hours/days of work) | Smaller (minutes of verification) |
