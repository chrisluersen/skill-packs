---
name: redirect
title: "Redirect — Back on the Rails"
description: "ADHD recovery skill. When a distraction steals your train of thought, minimize the re-entry tax. No long recaps. No 'where were we?' Three-second anchor back to exactly what you were doing, then the single next step."
category: productivity
created: 2026-06-20
version: 3
---

# Redirect — Back on the Rails

## When To Load

Load this skill when user signals he's been distracted or lost his thread:

- `"what was I doing?"`
- `"I got distracted"`
- `"where was I?"`
- `"redirect me"`
- `"anchor me"`
- `"I lost my train of thought"`
- `"what was I working on?"`
- `"pick up where I was"`
- `"where were we?"`
- `"what was the next step?"`
- Any signal of disorientation after a gap

This is the most frequently-needed ADHD skill. Use it fast — every second of "what was I doing?" recovery time is cognitive friction that makes the distraction worse.

## The Core Principle

**The best redirect is a single sentence: what you were doing + the next physical action.**

Not a recap. Not a summary. Not "we were discussing three options." One sentence. One next step. Then stop talking.

The brain doesn't need the whole context restored. It just needs the *current active thread* re-identified. The rest comes back naturally when you start moving.

## Signal Priority (Fastest → Most Complete)

Check these sources in order. Stop at the first one that gives a clear answer. Do not cascade through all of them unless the first 2 come up empty.

### Signal 1: This conversation (instant)

What was the last thing we were talking about before this redirect signal? Check your own context. The last user message before the redirect. The last tool call. The last file touched.

**This is sufficient 80% of the time.** The conversation is the context.

**Format:**

> **Redirect:** You were [working on X]. [Next physical step].

Examples:

> **Redirect:** You were fixing the router. `router.py` is still open. The next step was moving the fallback logic to its own module.

> **Redirect:** You were reviewing the Phase 11 diffs. You'd read through 3 of them. Number 4 starts at line 89.

> **Redirect:** You were writing the fleet dashboard. Last thing you did was add the header section. The test output was in the terminal.

### Signal 2: Tracking system (fast)

If the conversation doesn't have a clear recent thread (e.g., user just sat down and said "what was I doing?"), check tracking:

1. `read_file(tracking/latest-handoff.md)` — the handoff always has Active Context
2. `read_file(tracking/tasks.md)` — look for In Progress tasks

**Format:**

> **Redirect:** According to your last handoff, you were working on [Active Context task]. [Next step from the handoff or tasks.md].

### Signal 3: Session history (least fast, most complete)

If both sources above fail (no active conversation thread, no handoff), search the session DB:

1. `session_search()` — browse recent sessions by title
2. `session_search(query="<most likely keyword>")` — search for the last active task

**Format:**

> **Redirect:** Your last session was [session title]. You were [what you were doing based on session bookends]. Should I pull up the full handoff?

### Signal 4: Brain dumps (fallback)

If absolutely nothing in the tracking system or session history gives a thread, check open brain dump commitments:

- `mcp_wiki_search_wiki("tag:commitment AND tag:start-small")` — find open commitments
- Pick the most recent one as a candidate

**Format:**

> **Redirect:** You don't have an active task on record, but you did commit to [commitment from brain dump]. Want to pick that up?

## Workflow

### Step 1: Identify the redirect source

Instant check: "Was there a clear last task in this conversation?"
- Yes → Signal 1 (conversation context). Done.
- No, but there's a handoff → Signal 2 (tracking). Done.
- No, but there are recent sessions → Signal 3 (session history). Done.
- Nothing at all → Signal 4 (brain dump commitments).

### Step 2: Deliver the redirect in ONE sentence

> **Redirect:** You were X. Next step is Y.

**This is Rule 5 from the i-have-adhd commandments: *restate state every turn.*** The redirect IS the state restatement. One sentence. No hedging.

That's it. The entire output. No:

- "Let me check..." (hesitation)
- "So from what I can gather..." (waffle)
- "There were a few things you were working on..." (choice paralysis)
- "Do you want to continue?" (they asked to be redirected, yes they want to continue)
- "Welcome back!" (no greeting needed — they didn't leave, their brain did)

### Step 3: If the next step is fuzzy (proactive start-small)

If you know what the task was but the next step isn't obvious, apply the **start-small** principle: identify the single smallest physical action.

> **Redirect:** You were refactoring auth. Next step: open `auth.py` and scroll to line 45 — that's where you left the TODO comment.

If that's also not obvious, offer to do a start-small breakdown:

> **Redirect:** You were working on the dashboard. The direction was clear but the next step wasn't. Want me to find the smallest thing you can do to pick it up?

### Step 4: If the task was blocked

If user was stuck when the distraction hit, name the blocker and offer to help:

> **Redirect:** You were working on X but got stuck on Y. That was probably what made you susceptible to the distraction. Want me to help you clear that blocker, or do you want to switch to something else?

Name it. Naming the blocker neutralizes its power. Not naming it means it's still there waiting.

## Mid-Task Distraction Recovery (Advanced)

If the distraction happened *while executing a tool chain* (e.g., I was running 3 back-to-back tool calls and user got distracted mid-output):

1. Look at the last completed tool call's output
2. Look at what the next tool call would have been
3. Offer to re-run the incomplete chain from the last good state

> **Redirect:** I was in the middle of setting up the fleet profiles. Artemis had just deployed successfully. I was about to deploy Iris next. Want me to continue from there?

## Environment Re-Anchor

If the distraction *came from the environment* (notification, open tab, noise), the redirect isn't complete until the environment is reset. Otherwise the next distraction is already queued.

**Check silently:** Did the distraction come from something environmental? A Slack ping? A browser tab? Noise?

If yes, add a one-line offer after the redirect:

> **Redirect:** You were reviewing the router diffs. Next step is diff 4 of 8. Also — want me to stay around as body double so you don't tab away again?

Or for noise-induced distraction:

> **Redirect:** You were refactoring auth. Next step: line 45. Sound like you want brown noise on while you work?

**Don't make this a separate step.** It's a single appended sentence. The redirect dominates.

## Focus-Sound Companion

After the redirect sentence, you may optionally append a focus-sound nudge if the pattern fits:

| Distraction type | Offer |
|-----------------|-------|
| Came back from doom-scrolling | "Want me to put on brown noise to kill the dopamine hangover?" |
| Came back from a rabbit-hole read | "Should I throw on some focus music to signal the brain it's work time?" |
| General re-entry | "Focus sounds?" — one word prompt |
| No obvious pattern | Skip it. Only offer when the pattern fits. |

Keep the offer to 4 words max: **"Focus sounds?"** or **"Brown noise?"** Yes/no. If no, drop it immediately. Never ask twice.

## What NOT to Do

- ❌ Do NOT ask "do you want to continue?" — the whole point of the redirect is you already know the answer
- ❌ Do NOT give a multi-paragraph recap — one sentence, one step
- ❌ Do NOT offer multiple options for where to pick up — choice re-triggers distraction
- ❌ Do NOT apologize for the distraction or make it a thing — "no problem" is fine, move on
- ❌ Do NOT meta-comment on the ADHD ("classic ADHD tax haha") — zero judgment, zero commentary
- ❌ Do NOT mention the distraction itself unless user does — redirect is forward-facing

## Example Interactions

**user:** I got distracted. What was I doing?
**You:** **Redirect:** You were reviewing the router.js diffs. You were on diff 4 of 8 — `handleConnection()`.

**user:** *comes back after 20 minutes* ugh where was I
**You:** **Redirect:** You were refactoring auth. `auth.py` is still open at line 45 where you left the TODO comment.

**user:** what was I even working on today
**You:** **Redirect:** According to your handoff, you were deploying fleet profiles — Artemis was done, Iris was next.

**user:** *comes back to the computer* what was I doing
**You:** **Redirect:** We were just writing the brain dump skill. You were about to decide where to save the dump pages. Options were `braindumps/` in the wiki. Your call — same decision still waiting.

## Verification

After each use:
- [ ] Checked sources in priority order (conversation → tracking → sessions → dumps)
- [ ] Delivered redirect in exactly 1 sentence + 1 next step
- [ ] No hedges, apologies, or meta-commentary
- [ ] If blocker identified, offered to help clear it
- [ ] If mid-toolchain, offered to resume from last good state
- [ ] If environment contributed to distraction, offered re-anchor (body double / focus sounds)
- [ ] If focus sounds offered, kept it to 4 words max and dropped on "no"
