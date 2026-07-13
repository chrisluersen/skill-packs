# SOUL.md Evolution — 7-Iris Case Study (2026-06-24)

This reference captures the transformation of 7-Iris's SOUL.md over a single session as a concrete example of the **Direct approach** (no metaphors, behavioral rules only).

## Starting Point

- **~3,800 tokens, 237 lines**
- Mythic: "not a messenger who carries the rainbow, but the rainbow itself made messenger"
- 7 poetic subsections (Rainbow Bridge, Prism, Smirk, Energy Mirror, Fixed Point, Main Character, Styx Water)
- Themed tool headers (Staff, Wings, Light, Caduceus, Golden Thread, Styx Water)
- Operational rules at bottom of file (recency position — bad for execution)
- Register shifts: mythic → factual → poetic → directive → procedural

## Transformation Sequence

### Pass 1: Reorder and Condense

**Trigger:** User asked to own and restructure the SOUL.md.

**Changes:**
- Promoted Dispatch Discipline from bottom to section #3
- Front-loaded operational rules (Working with user, Dispatch, Tools)
- Moved personality to bottom (Behavioral Rules + Voice)
- Condensed 7 personality subsections → 4 paragraphs (Personality Gestalt)

**Result:** ~2,384 tokens (-37%)

### Pass 2: Strip Poetry

**Trigger:** user pointed out that poetry doesn't cause behavior — rules do.

**Changes:**
- Core Identity: Stripped the 3 myth paragraphs → kept one myth sentence as anchor
- Personality Gestalt → Behavioral Rules (4 direct instructions)
- Removed themed tool headers (Staff, Wings, Light, Caduceus, Thread, Styx)
- Tools → Operating Rules
- Removed closing poetic line

**Result:** ~2,145 tokens (-44%)

### Pass 3: Remove All Myth References

**Trigger:** "ya i dont want any cringey metaphors in the soul.md"

**Changes:**
- Removed "In myth, Iris was the messenger..." sentence from Core Identity
- Role section: plain job description, no myth
- "The Fixed Point" → "Thread pulling" → "Coherence" (removed prism metaphor, then renamed again)
- "Catch the spark and fan it into full flame" → "Expand his shorthand into complete action"
- "Energy mirror" → "Match tempo"
- "Entry point, not star" → "Entry point"
- "Stop the bleeding" → removed (redundant with Failure Mode)
- "The faster the storm passes" → removed
- "hand-wringing" → "over-explaining"
- Removed closing line entirely

**Validated heuristic:** Strip in this order: myth references → poetic headings → redundant metaphor sections → framing language. Do NOT strip common English idioms (wade through, path forward, wall of text) — those are normal language, not cringey metaphors.

**Result:** ~1,937 tokens (-51% from original)

### Pass 4: ADHD Behavioral Accommodations + USER.md Sync

**Trigger:** user provided a Claude memory export and asked to audit my rules against his actual profile. Four gaps found: forgetfulness handling, tangent handling, multi-step request planning, future-proofing default.

**Changes to SOUL.md:**
- Coherence rule expanded: "If he asks something already covered, answer fresh — no reminder. If he goes on a tangent, acknowledge, note as follow-up, steer back."
- New Behavioral Rule: "Surface the plan — when given a multi-step request (3+ parts), list steps before executing."
- New Operating Rule: "Future-proof by default — when approaches work now, prefer the one easier to change later."

**Changes to USER.md:**
- Expanded from 16 terse lines → 16 denser lines with employer ([employer]), location (Richmond, VA), ADHD accommodation rules, hardware specs, CLI stack, hobbies (coffee, grilling, WoW), subscriptions (Nous)
- Synced `memory(target='user')` profile to match — 563/600 chars with compact ADHD-first format
- Source: imported from Claude's memory export (`user-context-handoff.md`), validated for accuracy (skipped stale entries: old terminal stack, Mac mini unconfirmed purchase)

**Validated heuristic for profile imports:** When importing user data from another AI system's memory export, cross-reference against observed preferences from YOUR session history with the user. The export will contain stale or inaccurate entries. Strip: old tech stacks that the user migrated away from, speculative purchases that never happened, terminal setups that changed. Keep: biographical constants (employer, location, hobbies), hardware specs, and inferred preferences (ADHD, research style, aesthetic taste).

**Result:** ~2,060 tokens (-46% from original). Slightly larger than Pass 3 because added 3 new behavioral rules.

### Pass 5: Comprehensive Final Audit (All Three Files)

**Trigger:** user asked for a review of SOUL.md, USER.md, and memory against everything learned across the session. Four improvements found.

**Changes to SOUL.md:**
- Moved "Future-proof by default" from standalone line between Token discipline and Anticipation → bullet in Foundations
- Added new Behavioral Rule: "Default to direct — when in doubt about wording, choose the plain version."
- Removed the myth-adjacent welcome line check (kept "Hey! Pull up a chair" — not a myth reference, just friendly)

**Changes to USER.md:**
- Added "Brave browser" to tech spec line

**Changes to memory:**
- Removed dispatch discipline entry (now fully covered in SOUL.md, which is loaded every turn — redundant)
- Added router/config fact: "Router on 0.0.0.0:8319 (PID 12240 via venv). Config base_url bypasses router — direct to Nous inference-api."
- Memory count: 698/1,000 chars, 6 entries

**Validated heuristic — what goes where:**
| Store | Purpose | Contents |
|-------|---------|----------|
| **SOUL.md** | Agent behavioral rules, operating procedures | How the agent acts, what it prioritizes, dispatch discipline, voice rules |
| **USER.md / memory(user)** | User facts for ALL agents | Who the user is: employer, location, ADHD, preferences, tech stack |
| **memory(self)** | Durable environment facts | File system quirks, port numbers, config state, fleet decisions |
| **Session logs** | Transient task state | What happened this session |

**Key rule:** Do NOT duplicate SOUL.md content in memory(user) or memory(self). SOUL.md is loaded fresh every turn. Memory is for facts SOUL.md doesn't cover. If a rule lives in both, they drift.

### Pass 6: Final Metaphor Strip and Foundations Polish

**Trigger:** user asked for a comprehensive review of all three files (SOUL.md, USER.md, memory) with "review and revise one more time."

**Changes to SOUL.md:**
- Double "land" fixed: "land them on the right agent. Make communication land" → "route them to the right specialist. Make communication land"
- "Dispatch Discipline — The Golden Rule" → "Dispatch Discipline" ("the Golden Rule" was a biblical reference — removed)
- "wade through" → "read through" (water metaphor, replaced with plain language)
- "bury the noise" → "cut the noise" (burial metaphor)
- "Write only when you mean it" → "Never write placeholder or speculative content" (vague → precise)
- Added "Save as skill" to Foundations: "After a complex task (5+ tool calls or a new workflow), offer to save the approach as a skill."

**Changes to USER.md:**
- Added "Tailscale for remote access" to tech line

**Changes to memory:**
- No changes needed (already at 698/1,000 with 6 efficient entries)

**Coherence check:** 28/28 checks passed — every expected rule present, no myth references, no stylistic drift.

**Validated heuristic — what to check in a final audit:**
1. Duplicate phrases (double "land", repeated instructions across sections)
2. Remaining myth/religion references ("The Golden Rule")
3. Overwriting vague instructions ("Write only when you mean it" → "Never write placeholder")
4. Normal English idioms vs. cringey metaphors — strip the latter, keep the former ("wade through" was borderline and was replaced; "path forward" and "bottom line" are standard and kept)
5. Cross-file sync — USER.md should match what SOUL.md says about the user's environment

**Final result:** 2,117 tokens, 140 lines, 45% reduction from original 3,800.

## Final Structure

```
Role                    — job description, lineage, coherence rule
Working with user      — preferences, projects, delivery style
Dispatch Discipline     — 1-turn routing rule, exceptions, self-correction
Operating Rules         — token discipline, future-proofing, anticipation, brevity, honesty,
                          foundations, translation, memory, failure mode (8 subsections)
Behavioral Rules        — confidence without display, match tempo, entry point,
                          surface the plan (4 rules)
Voice                   — short sentences, lead with answer, strip filler,
                          earn syllables
```

## Key Observations

1. **The myth was wallpaper, not behavior.** Stripping it changed nothing about how the agent responded — the behavioral rules were what actually controlled output quality.

2. **Front-loading operational rules improved execution.** With Dispatch Discipline and Operating Rules at the top of the file (against recency bias), the agent dispatches more consistently in the first turn rather than falling through to personal chat.

3. **The refinement cycle was productive through 7+ passes** because each pass had a specific signal from the user: "reorder it," "poetry doesn't cause behavior," "no cringey metaphors," "merge redundant rules." When feedback became non-specific, the file was done.

4. **"Confidence without display" produced the same behavior as "the smirk."** The behavioral rule (one line for the fix, no "told you") does the work. The poetic description was just packaging.

5. **The Voice section is the highest-ROI personality tool.** ~180 tokens for rules that define how every response reads (short sentences, lead with answer, strip filler). Without it, the model's natural voice is more verbose.
