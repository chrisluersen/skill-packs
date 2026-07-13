---
name: quick-win
title: "Quick Win — Momentum Through Completion"
description: "ADHD dopamine hack. When nothing feels doable, find a single task that takes ≤5 minutes, produces visible output, and has an obvious 'done' state. One completion breaks the stall and builds momentum."
category: productivity
created: 2026-06-20
version: 3
---

# Quick Win — Momentum Through Completion

## When To Load

Load this skill when user signals he's spinning, stuck, or needs a dopamine hit:

- `"I need a win"`
- `"give me something quick"`
- `"I feel stuck"`
- `"nothing sounds doable"`
- `"I'm spinning"`
- `"quick win?"`
- `"something easy to knock out"`
- `"I need to start moving"`

Do NOT load this for normal task execution — this is specifically for *breaking a stall*. If user says "run task X" in a normal voice, that's not a quick win signal.

## The Core Principle

**The best quick win is something already 90% done.**

Chasing a shiny new 5-minute task is fine. But the *best* dopamine hit comes from finishing something that's been sitting there half-done. It closes a mental loop. That release is stronger than starting something new.

## Sources of Quick Wins (Check in Order)

Check these sources for candidate tasks. Stop as soon as you find one that fits. Don't over-research.

### 1. Current session context

What were you and user just talking about? Is there a dangling thread? A half-finished thought? A file that was opened but not edited?

### 2. Open brain dumps

`mcp_wiki_search_wiki("tag:braindump")` — look for items still marked `Open` in the dump table. Reminders and Random items are prime quick-win territory.

### 3. Tracking system — nearly-done tasks

Search `tracking/tasks.md` and `tracking/latest-handoff.md` for:
- Tasks marked In Progress with no blockers
- Tasks that say "nearly done" or "just needs X"
- Tasks that are just verifications ("check if X works", "confirm Y is deployed")

### 4. System health — low-effort maintenance

Quick wins that always work because they produce visible output:

| Win | Time | Dopamine source |
|-----|------|----------------|
| Run `mcp_wiki_reindex_wiki()` | 2s | Green checkmark output |
| Run `mcp_wiki_lint_wiki()` | 2s | "0 issues" or a concrete fix target |
| `watch -n 1 uptime` | free | Seeing the system run |
| Check cron health `cronjob(action='list')` | 5s | "All green" |
| `hermes status` | 3s | Clean status output |
| Check server uptime | 10s | "Everything's running" |

### 5. Config/file quick wins — visible, completable

| Win | Time | Why it works |
|-----|------|-------------|
| Fix one lint warning in a file | 2 min | Concrete before/after |
| Add a missing semicolon / bracket | 10s | ✓ save → ✓ green |
| Delete a stale comment or TODO | 30s | Cleanup feels good |
| Rename a poorly-named variable | 1 min | Order from chaos |
| Remove a debug print statement | 15s | "Ship cleanliness" |
| Bump a version number | 30s | Progress marker |
| Add one docstring to a function | 1 min | Completeness |
| Close a file that's been left open | 2s | Tidiness dopamine |
| Archive an old file | 30s | Decision made |

### 6. Life quick wins (if it's a life stall, not a work stall)

| Win | Time | Why it works |
|-----|------|-------------|
| Clear one notification | 5s | Visual reduction |
| Close one browser tab | 1s | Less clutter |
| Put one thing away | 10s | Physical order |
| Drink a glass of water | 30s | Self-care + "did a thing" |
| Stand up and stretch | 60s | Body win |

### 7. Environment reset — sound, sight, space

Sometimes the stall isn't about the task — it's about the *environment*. Fixing the environment IS the quick win:

| Win | Time | Why it works |
|-----|------|-------------|
| Put on brown noise / focus sounds | 15s | Immediate ambient shift — signals "work mode" to brain |
| Set a 25-min Pomodoro timer | 10s | Timebox shrinks the infinite horizon |
| Close 3 browser tabs | 5s | Visual clutter reduction |
| Mute notifications for 25 min | 10s | Removes the next distraction before it happens |
| Turn on a website blocker | 20s | Externalizes willpower — one less thing to resist |
| Open a single window / fullscreen the task | 5s | Eliminates visual competition |

**When to offer environment wins:** If the stall follows a distraction cycle (came back from YouTube, Twitter, news) or if user mentions noise/clutter.

## Workflow

### Step 1: Identify the stall type

When user says he needs a quick win, pick up on any tone signal:

- **Low energy / brain fog** → choose a *passive* win (run a status check, read something)
- **Frustrated / stuck on something** → choose a *cleanup* win (fix a lint, delete a TODO)
- **Spinning / too many things** → choose a *finishing* win (complete a 90% task)
- **Just needs to start moving** → choose a *visible output* win (reindex, status check)

If no tone signal is obvious, default to: **system health check**. It's always available, always produces output, and often surfaces a real fix.

### Step 2: Find the best candidate

Scan the sources above (session → dumps → tracking → system → config → life) until you find ONE candidate. Not four. Not a list. One.

**If no candidate found after scanning:** the absolute fallback is a meta-win — clean up one thing in the wiki that's been bothering you both. Run `mcp_wiki_lint_wiki()`, pick the first actionable issue, and fix it. That's always available and always produces a win.

### Step 3: Propose it simply

Format:

> **Quick win:** [task name] — [time estimate]
> 
> [one-line description of the task]
> 
> Want to knock it out?

Examples:

> **Quick win:** Reindex the wiki — 2 seconds
> 
> Presses the green button. Clean output. Satisfying.
> 
> Want to?

> **Quick win:** Delete that `console.log` in dashboard.js — 15 seconds
> 
> You left it in there from debugging. Removing it = one less loose end.
> 
> Want to?

> **Quick win:** Close out that brain dump item "buy milk" — 10 seconds
> 
> It's been sitting in the dump since yesterday. Marking it done closes a loop.
> 
> Want to?

### Step 4: After the win

If user does the win (or says "do it for me"), acknowledge completion **concretely** — make the win visible, don't just say "done":

| Win type | Visible confirmation |
|----------|---------------------|
| File change | `✅ router.py: removed stale TODO comment` |
| System check | `✅ Wiki: 0 issues. Cron: 3 jobs, all green.` |
| Life task | `✅ One notification cleared. Feels lighter.` |
| Environment | `✅ Focus sounds on. Tabs closed. Ready.` |

Then confirm briefly:

> ✅ router.py — one less TODO. Loop closed.

That's it. No extrapolation, no "now you should do X." The win IS the point. Momentum is built, not demanded.

**Rule 7 explicit:** *Make completed work visible.* The concrete output IS the dopamine reward. Saying "I fixed something" doesn't release it. Seeing `✅ auth.py: removed dead import` does. Always name the specific file/state changed.

**Body-double extension:** If after the win user signals he's *ready* to work but can't *stay* working — "I don't trust myself not to tab away" — offer to body-double:

> *"Want me to stay here while you work? I won't talk unless you need me. I'm just a presence in the room."*

If yes: go quiet. If user speaks, answer minimally. Do NOT proactively check on progress.

If user wants to chain wins (he says "give me another"), offer one more at the same size level. After 2-3 wins in a row, gently suggest picking up the thing he was actually trying to do before the stall.

## What NOT to Do

- ❌ Do NOT offer more than one candidate at a time. Choice paralysis kills quick wins.
- ❌ Do NOT ask "what sounds good?" — that's the exact thing they can't answer right now
- ❌ Do NOT suggest a task that takes > 5 minutes. 5 is the hard cap. 2 is better.
- ❌ Do NOT follow a win with "now let's work on X" — let them sit in the win for a moment
- ❌ Do NOT evaluate their stall. "Why are you stuck?" is the opposite of helpful.
- ❌ Do NOT suggest starting the thing they're actually blocked on — that's the problem, not the solution

## Example Interactions

**user:** I need a win. Nothing sounds doable.
**You:** **Quick win:** Reindex the wiki — 2 seconds. Green checkmark. Clean output. Satisfying. Want to?

**user:** ugh gimme a quick win
**You:** **Quick win:** Delete `# TODO: fix this later` in router.py — 5 seconds. That comment has been there since last week. One less loose end. Want to?

**user:** I'm spinning on too many things
**You:** **Quick win:** Check cron health — 5 seconds. Everything running = one thing you don't have to worry about anymore. Want to?

## Verification

After each use:
- [ ] Identified the stall type (energy / frustrate / spin / start)
- [ ] Found exactly ONE candidate task
- [ ] Proposed it in 2 lines or less
- [ ] Time estimate is ≤ 5 minutes (ideally ≤ 2)
- [ ] Followed up with a brief acknowledgment, not a "now do X"
