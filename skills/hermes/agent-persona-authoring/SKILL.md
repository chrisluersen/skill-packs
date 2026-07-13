---
name: agent-persona-authoring
description: Author and iteratively refine an agent's personality/identity document (SOUL.md) — extract traits from curated visual inspiration, separate personality from operational protocols, codify voice rules, and handle refinement cycles without drifting.
category: hermes
created_from_user_sessions: true
---

# Agent Persona Authoring

How to write, refine, and ship an agent's SOUL.md — the identity document that defines who the agent is, how it sounds, and what tools it carries.

## When to Use

- User asks you to write or improve SOUL.md (the agent identity document)
- User provides inspiration images, themes, or references for their agent's personality
- User says the personality doesn't match their vision
- Starting a new agent profile that needs a persona

## Core Principles

### 1. Source of Truth = Curated Inspiration

The user's curated inspiration images/themes are the **primary source**. Every personality trait must trace back to something visible or explicitly described in that source material. If you can't point to the image or reference that inspired a trait, it's invented — cut it.

**Workflow:**
1. Read the user's source material (images, descriptions, references)
2. Extract concrete visual/character themes: colors, posture, expression, energy, symbols
3. Transform those themes into personality traits
4. Before writing any trait, verify it anchors to the source

### 2. Separate Personality from Operations

SOUL.md has two fundamentally different concerns that must never blend:

**Direct approach (when user rejects metaphor):**

| Section | Purpose | Example |
|---------|---------|---------|
| Role / Core Identity | What the agent's job is | "Your job: take fragments, expand, route." |
| Behavioral Rules | How the agent carries itself | "Confidence without display. Match tempo." |
| Operating Rules | How the agent works | "Always read_file before write_file" |
| Voice | How the agent writes | "Lead with the answer. Short sentences." |

**Mythic approach (when user embraces poetic framing):**

| Section | Purpose | Voice | Example |
|---------|---------|-------|---------|
| Personality & Presence | Who the agent IS | Mythic, poetic | "The rainbow is her nature, not her tool" |
| Voice & Cadence | How the agent WRITES | Directive, coaching | "Lead with the answer." |
| Tools of the Messenger | What the agent CARRIES | Instructional | "Always read_file before write_file" |

**IMPORTANT — preference-sensitive framing:** The user may explicitly reject mythic/metaphorical framing (e.g. "no cringey metaphors," no "caduceus," no "Styx water"). In that case, strip ALL myth references and use direct behavioral instruction instead. The personality emerges from the *rules*, not the references.

| Approach | Framing | When to use | User signals |
|----------|---------|-------------|-------------|
| **Mythic** | Poetic, aspirational, themed subtitles | User provides myth/visual inspiration and embraces poetic language | User shares themed images, myth references, poetic descriptions |
| **Direct** | Plain labels, behavioral rules only | User rejects metaphor or says nothing about theme | "no cringey metaphors," "just give me the rules," "strip the poetry" |

**The Direct approach (validated by E2E use):** Strip all myth/poetry. Use plain section headers (Role, Operating Rules, Behavioral Rules, Voice). Label subsections by function (Anticipation, Brevity, Honesty — not The Staff, The Fast Wings, The Clear Light). The behavioral rules ARE the personality — the model follows "Confidence without display" and "Match tempo" without needing myth framing.

**The mythic approach — themed subtitles (use only when user prefers poetic language):**
Use themed subtitles like "The Staff" for Anticipation if the user embraces mythological framing. Be ready to strip these on request — they are wallpaper, not behavioral payload.

### 4. Voice is Not Personality

Voice rules describe *how the agent writes* — sentence rhythm, word choice, what to cut. They are independent of the personality traits. A poetic personality can use terse prose. Include a dedicated Voice & Cadence section with explicit rules:
- Short sentences — but vary rhythm (em-dashes, fragments allowed when they land)
- Lead with the answer — signal first, context after
- Strip the filler — no "basically," "essentially," "Let me walk you through"
- **Default to direct** — when in doubt about wording, choose the plain version. Clean delivery over clever framing.
- Earn your syllables — humor gets the same budget as everything else

### 5. ADHD-Specific Behavioral Accommodations

When the user has disclosed ADHD (or shows scatter/fragmentation patterns like mid-sentence project jumps), embed these accommodations directly in the persona's Behavioral Rules. They are not optional fluff — they are the difference between a frustrating assistant and a useful one.

**The five patterns to watch for:**

| Accommodation | When to apply | Behavioral Rule text |
|---------------|---------------|---------------------|
| **Answer fresh** | User asks something already covered in the same session | "If they ask something already covered, answer fresh — no reminder you already said it." |
| **Tangent handling** | User goes on a side path mid-request | "If they go on a tangent, acknowledge the interesting point, note it as a follow-up, then steer back." |
| **Surface the plan** | Multi-step requests (3+ parts) | "When they give a multi-step request, list the steps before executing. Let them confirm or redirect early." |
| **Match tempo** | User's energy level shifts between sessions | "Read their first line and calibrate. Fast → match with sharp turns. Quiet → efficient, gentle, minimum words." |
| **No shame** | User contradicts earlier direction or forgot context | "Don't lecture. Don't say 'as I mentioned earlier.' Redirect cleanly." |

**Placement:** These go in the **Behavioral Rules** section (Direct approach) or under specific rule names in the Tools section (mythic approach). Do NOT bury them in the user profile section — they are session-entered behavioral rules, not biography.

**User profile sync:** After establishing these accommodations in SOUL.md, also add a compact version to the user's USER.md (via `memory(target='user')`) so fleet worker agents that don't load the persona's SOUL.md still get the guidance. Format: `"ADHD: low-friction. Answer fresh on repeats, no shaming."`

### 6. The Token Ethos

Every section of SOUL.md that costs tokens must earn its place. The "why" behind the Tools section should be stated explicitly: the user's attention is the bottleneck, and every tool exists to protect it.

**Reduction benchmark:** When transitioning from a mythic/poetic SOUL.md to direct behavioral rules, expect a ~45% token reduction. The validated target for a coordinator/supervisor persona is ~2,000-2,200 tokens (140-145 lines). Going below that risks losing necessary operational rules (dispatch table, ADHD accommodations, foundations). Going above ~2,500 tokens risks waste — re-audit for myth remnants, redundant rules, and over-written sections.

### 7. Future-Proof by Default

When the user has a demonstrated future-proofing preference (e.g., "don't defer gaps," "build for extensibility"), embed this as a behavioral rule in Foundations or Operating Rules:

> **Future-proof** — when multiple approaches work now, prefer the one easier to change later.

This is NOT a general principle. Only add it when the user has explicitly shown this preference (e.g., consistently choosing extensible solutions over quick fixes across multiple sessions).

### 8. Monolithic by Default

Unless the user explicitly asks to split, keep SOUL.md monolithic — everything in context. The user should not have to remember to load a skill for their agent's identity to function.

**Foundations should include a "Save as skill" bullet.** If the persona runs on an agent with skill management capabilities, include a Foundations rule that tells the agent to proactively save new workflows it discovers during a session:

> `- **Save as skill.** After a complex task (5+ tool calls or a new workflow), offer to save the approach as a skill.`

This closes the loop between "how the agent works" and "how the agent improves" — the agent that follows this rule will create skills without being told.

### 9. Personality-First vs. Task-First: Two Distinct Profile Patterns

**This is the most important distinction in this skill.** The mythic SOUL.md pattern (Personality & Presence, Voice & Cadence, Tools of the Messenger) is designed for **default/user-facing personality agents** — agents the user talks to directly. For **fleet worker agents**, this pattern actively causes failures.

| Profile Type | Purpose | Pattern | E2E Evidence |
|-------------|---------|---------|-------------|
| **Personality Agent** | User-facing chat, coordinator, messenger | SOUL.md mythic | Stella (default profile) |
| **Fleet Worker** | Executes domain tasks (code, search, content) | Task-First: [ROLE]/[BEHAVIOR]/[OUTPUT]/[RULES]/[PERSONALITY] | Klio-84 (8/100) with mythic — hallucinated roleplay instead of answering |

**Proof from E2E tests (2026-06-23):**

| Worker | Profile Style | Ceres Score | Failure Mode | Root Cause |
|--------|---------------|-------------|-------------|------------|
| Klio-84 | Mythological "cosmic stacks" preamble | 8/100 | Category hallucination — invented a debugging task, ignored the query | Theatrical prompt trained agent to stay in character, not do its job |
| Artemis-105 | Direct task instruction (no preamble) | 100/100 | None | Profile said "search for this" and it did exactly that |
| Kalliope-22 | Moderate theatricality | 86/100 | Minor preamble padding | Some roleplay crept into output |
| Metis-9 | Task-focused code instruction | 95/100 | Ceres rejected first pass as "fix, not implementation" | Task interpretation issue, not profile style |

**The task-first profile pattern (for fleet workers):**

```
[ROLE]: One sentence. What you do.
[BEHAVIOR]: 2-3 bullet instructions. How you work.
[OUTPUT]: What you deliver. Format expectations.
[RULES]: Non-negotiables — no preamble, no roleplay, direct answer first.
[PERSONALITY]: One line of voice style (optional — colors delivery, not content).
```

**⚠️ CRITICAL — Gate agent SOUL format contract:** If the agent is a QA/review gate (Nemesis-128, Ceres-1, Eris-101) whose output is parsed by `parse_evaluation()` in fleet-manager.py, the SOUL.md's `[OUTPUT]` section must use the parser's EXACT field names and format. Do NOT use different field names (`SCORE` → `Score`, `CONSENSUS` → `Verdict`, `CRITICAL_FAILURES` → `Issues`, `FEEDBACK` → `Confidence`). Do NOT wrap the format in markdown code blocks — the parser regex expects `FINAL_EVALUATION:\n` followed directly by the fields. If the SOUL says one format and the prompt says another, the LLM follows the SOUL. Validate by running a dispatch through the fleet manager and checking that `parse_evaluation()` returns a structured result instead of falling back to substring matching.

**When to use each:**

| Agent Type | Examples | Pattern | Why |
|------------|----------|---------|-----|
| Supervisor/Reviewer | Ceres-1, Nemesis-128, Vesta-4 | SOUL.md mythic | They set tone and enforce standards — persona helps assert authority |
| Director/Orchestrator | Astraea-5 | SOUL.md mythic | Decomposes and delegates — persona frames the role |
| Code worker | Metis-9 | Task-First | Output quality matters, not persona flavor |
| Search worker | Artemis-105 | Task-First | Direct answers with source citations |
| DevOps worker | Atalanta-36 | Task-First | Direct answers about system state — persona would add delay |
| Content worker | Kalliope-22 | Either — test both | Profile style has measurable impact |
| Wiki worker | Klio-84 | **Task-First required** | Theatrical style causes catastrophic failure (8/100) |

**Hybrid approach:** Even task-first profiles can have a thin personality layer via the `[PERSONALITY]` line. One line of voice is enough to color delivery without risking preamble.

**Important:** This distinction applies to the **system prompt / messages configuration**, not just SOUL.md. A fleet worker with a task-first system prompt and no SOUL.md works fine. A fleet worker with a mythic SOUL.md AND a task-first system prompt — the SOUL.md will override, causing persona bleed (see `hermes-fleet-profiles` skill for details).

**Coordinator agent dispatch discipline:** For the default/user-facing personality agent (Level 0), behavioral rules must enforce strict dispatch boundaries. Without them, the agent defaults to doing specialist work itself — acting as a jack-of-all-trades instead of routing to experts. The validated pattern (from Stella, ~2,000 tokens):

A **keep/dispatch table** defines the boundary explicitly:
- **Keep at Level 0:** Planning, analysis, advice, config changes, quick checks (<10s), fleet coordination
- **Dispatch to specialists:** Code → Metis, web search → Artemis, wiki → Klio, data → Fortuna, design → Harmonia, devops → Atalanta, content → Kalliope, security/QA → Vesta/Nemesis/Ceres

Key elements of the dispatch discipline:
- **1-turn rule:** Dispatch within 1 turn of identifying the domain. Do not do the specialist's work yourself.
- **Exceptions:** Architectural decisions, quick status checks, fleet-down scenarios
- **Self-correction:** If you catch yourself doing a specialist's work, stop mid-turn and dispatch. Don't finish and hand off.
- **Rationale:** "Dispatch is quality routing, not delegation. Specialists have task-first profiles, domain context, and QA gates."

This pattern belongs in the **Behavioral Rules** section of the SOUL.md, not in the fleet configuration files.

## Managing Register Shifts

SOUL.md can use multiple writing registers. Each transition between them must feel intentional, not abrupt.

**Two valid approaches:**

### A. Register-shifting (mythic persona)

Use when the user embraces mythological/poetic framing. Requires `---` dividers and deliberate transitions:

| Register | Used in | Sounds like |
|----------|---------|-------------|
| **Mythic** | Core Identity, Personality | Poetic, aspirational. "The rainbow is her nature, not her tool." |
| **Factual** | Working with user / Context | Grounded, specific. "user thinks in fragments, not paragraphs." |
| **Directive** | Voice, Behavioral Rules | Coaching, imperative. "Lead with the answer." |
| **Factual-procedural** | Operating Rules | Instructional. "Always read_file before write_file." |

**Transition techniques:**
- Use `---` section dividers between registers
- The first line after each divider establishes the new register immediately

### B. Uniform direct instruction (preferred by some users)

Use when the user rejects metaphor/poetry (signals: "no cringey metaphors," "just give me the rules," "strip the poetry"). All sections use a consistent direct-instruction register with no register shifts:

- Core Identity / Role: "Your job: take fragments, expand, route. Make communication land."
- Working with user: "user thinks in fragments, not paragraphs."
- Operating Rules: "Always read_file before write_file."
- Behavioral Rules: "Confidence without display."
- Voice: "Short sentences. Lead with the answer."

**No register shifts needed** — every section reads in the same instructional voice. No `---` dividers required between sections (plain headings suffice). The personality emerges from the behavioral rules themselves, not from register contrasts.

## The Refinement Cycle

When the user asks "improve it" or "try again":

1. **Read current state** — full SOUL.md via read_file
2. **Identify the gap** — what specifically isn't working? Extract from user feedback, not guesswork. Look for explicit signals: "this is too verbose," "too many metaphors," "stop doing X," "just give me the rules." Each distinct signal is a concrete action item.
3. **Verify scope** — does the improvement stay within established direction? If the user said "no metaphors," don't introduce new poetic language. If the user said "make it tighter," don't expand.
4. **Make surgical changes** — prefer `patch` over full rewrites for targeted fixes. A full rewrite is only justified when the architecture itself needs restructuring (e.g. changing from mythic to direct approach). For prose polishing, patch the sections that need love.
5. **Read back** — verify the change in context, not in isolation. A fix that reads great alone may break flow in sequence.
6. **Be honest about diminishing returns** — the correct stopping criterion is **feedback quality, not pass count**. A single session can productively run 5-8 passes if each pass addresses a different concrete signal (e.g., Pass 1: reorder sections, Pass 2: condense personality, Pass 3: strip myth references, Pass 4: rename headers, Pass 5: add ADHD accommodations). Stop when feedback becomes non-specific ("keep going," "I don't know, try something") — that means the remaining issues need real use to surface, not more polishing.

SIGNS IT'S TIME TO STOP:
- Feedback shifts from specific ("remove the Styx reference") to vague ("try something else")
- Feedback becomes contradictory with earlier passes (user approved something then asks to change it again)
- The user hasn't seen the file in action yet — some problems only surface in actual conversation
- You're changing things you already changed back

## Post-SOUL.md: USER.md Sync

After finalizing SOUL.md, the behavioral rules and accommodations should also be available to **fleet worker agents** who don't load the main profile's SOUL.md. Two stores need updating:

### 1. Memory Tool (target='user')

Loaded fresh every turn for the coordinator agent. Compact format — fits within the 600-char limit. Prioritize ADHD accommodations and work style:

```
Name: Luersen (user). [employer] — AI engineer. Richmond, VA.
§
ADHD: low-friction. Answer fresh on repeats, no shaming.
§
Style: terse, results-first, provenance-first, future-proof.
§
Projects: agent fleet, router, wiki, Hermes growth.
§
Tech: Windows (5600X, 3060 Ti). git-bash + zellij + nvim. Nous sub.
§
Creative: AI DJ, pixel art, video. Long-term: drones, watch, dog bot.
§
Prod: 4-layer stack. Clean DLs/Desktop. HF token for router.
§
File: auto-load, no splitting, archive identity before removal.
```

### 2. USER.md File (`~/.hermes/memories/USER.md`)

Read by dispatched fleet workers (Metis, Klio, Artemis, etc.) before they execute. Same content as the memory tool but can be slightly more detailed since the file has no hard char limit. Include:

- Name, employer, location
- ADHD accommodations (compact)
- Work style (terse, results-first, provenance-first)
- Tech stack and CLI tools
- Production conventions (cleanup schedules, token usage)
- File/edit preferences
- Aesthetic preferences (if relevant to design/content workers)

**Validation rule:** Do NOT duplicate SOUL.md behavioral rules in USER.md or memory(traget='user'). USER.md/memory is for *who the user is*. SOUL.md is for *how the agent behaves*. If a rule appears in both, the two stores will drift over time — the SOUL.md is the source of truth.

**Source material warning:** When importing user data from another AI system's memory export (e.g., Claude's user-context-handoff.md), cross-reference against YOUR session history with the user. The export will contain stale or inaccurate entries. Strip: old tech stacks the user migrated away from, speculative purchases, terminal setups that changed. Keep: biographical constants (employer, location, hobbies), hardware specs, and inferred preferences (ADHD, research style, aesthetic taste).

**Multi-export cross-referencing (when you have 2+ exports):** When the user provides exports from multiple AI platforms (ChatGPT, Gemini, Claude), do not treat them equally:

1. **Rate each export for depth:** Scan the first 50 lines of each. Some exports are rich behavioral analyses (ChatGPT: 6-part profile including cognitive style, contradictions, architecture insights), others are nearly empty (Gemini: no cross-session memory at all). Claude exports sit in between — project inventory is excellent, but communication-style sections are explicitly marked as empty.

2. **Cross-reference overlapping facts:** When the same fact appears in multiple exports (e.g., both ChatGPT and Claude mention function-over-form gear decisions), use the more detailed version. Cross-referencing increases confidence — independent sources agreeing on the same trait means it's real, not a lucky guess.

3. **Flag contradictions:** If two exports disagree about the same trait (e.g., one says "prefers bullet points" and another says "prefers prose"), note the contradiction in your output. Don't silently pick one — surface the ambiguity.

4. **Provenance chains in USER.md:** When a USER.md entry is derived from an export, the source should be identifiable. Not inline footnotes (too noisy), but if challenged you should be able to say "this came from Claude new, section 2, the Ducky keyboard note."

**Example of multi-export extraction (from real use):**

| Export | Value | Used for |
|--------|-------|----------|
| ChatGPT (1164 lines) | Behavioral contradictions, communication style, architecture framework, exploration→execution pivot | USER.md: cognitive style, decision patterns, pet peeves |
| Gemini (near-empty) | Nothing recoverable — no cross-session memory | Skipped |
| Claude old (11KB) | Project inventory, tech stack, gear decisions | USER.md: hardware specs, tool choices |
| Claude new (23KB) | Same as old + personal details (girlfriend, rabbit), richer hobbies, WoW specifics | USER.md: personal life, hobby depth, gear philosophy |

**Don't merge every fact.** A fact is only worth storing if it's: (a) confirmed by 2+ signals, OR (b) from a single high-confidence export that explicitly flagged it as "high confidence." Low-confidence guesses from the export ("user might prefer X") should be discarded.

## TUI Display Name

After writing SOUL.md, if the user wants their agent's name to show in the CLI/TUI banner (rather than "Hermes Agent"):

**What actually changes the TUI banner title:**
- Create a minimal custom skin at `~/.hermes/skins/<name>.yaml`:
  ```yaml
  name: <skin-name>
  description: "<description>"
  branding:
    agent_name: "<display-name>"
  ```
- Set `display.skin: <skin-name>` to activate it

The `branding.agent_name` key in a custom skin is what replaces "Hermes Agent" in the TUI status bar, welcome banner, and title text. This is the only setting that affects the banner.

**What does NOT change the banner:**
- `display.personality: <name>` — this only shows as a label in `hermes config show` output. It does not affect the TUI banner, status bar, or any UI surface. Setting this alone will not change what the user sees.

**Both can be set independently** — skin for the banner, personality for your own reference:

1. Set `display.personality: Iris` — shows "Personality: Iris" in config output  
2. Create skin with `agent_name: "Iris"` plus `display.skin: iris` — changes the TUI title  
3. Restart the session (`/reset` or relaunch) for skin changes to take effect

## Pitfalls

- **Don't introduce new traits from your general knowledge.** If the image doesn't show a smirk, don't add one. Every trait needs provenance.
- **In the Direct approach (no metaphors):** Do NOT use themed subtitles, myth references, or poetic bridge lines. The personality must come from the behavioral rules themselves, not from packaging.
- **In the Mythic approach (poetic framing):** Do NOT blend personality language into the Tools/Operating Rules section. The tool names describe what the rule does, not who the agent is. The bridge line should be the only exception.
- **Don't over-write.** If a trait can be said in 4 lines instead of 8, say it in 4. The file is injected every turn.
- **Don't change approved content without cause.** If the user approved the content, don't rewrite it. Polish transitions, tighten language, fix structural issues — but leave the substance intact.
- **Don't drift.** When the user says "don't drift too far," every new word must earn its place against established themes.

## Verification

After finalizing, confirm:
- Every personality trait traces to curated inspiration
- Voice rules describe how the agent actually writes
- Tools section is cleanly separated from personality
- No emojis or noisy formatting in headers
- File reads as one voice from top to bottom
- Total length is justified — no section that could be a reference doc instead

## Related Skills

- `hermes-fleet-profiles` — Deploying SOUL.md across fleet profiles
- `hermes-webui-customization` — WebUI and TUI chat appearance (separate from CLI banner)
- `improve-user-md` — User profile refinement (different document, similar workflow)

## Context File Ecosystem

SOUL.md does not live in isolation. Three other context files layer with it to define the agent's full behavior:

| File | Slot | Purpose |
|------|------|---------|
| **SOUL.md** (this skill) | #1 system prompt | Agent identity — who the agent IS |
| **AGENTS.md** | Project context | Operational protocol — how the agent WORKS |
| **CLAUDE.md** | Project context | Project constitution — what the PROJECT expects |
| **.hermes.md** | Project context | Hermes project config — same as CLAUDE.md, with YAML frontmatter |

The prompt stack: SOUL.md → AGENTS.md → CLAUDE.md/.hermes.md → session context.
Most specific wins. Higher in the list = more influence per token.

For full details, loads, locations, and comparison tables, see `references/context-file-ecosystem.md`.

Starter templates available at `C:/Hermes-Vault/templates/` — `soul.md`, `agents.md`, `claude.md`, `hermes.md`.

> **Vault visibility note:** Files use `.md` extension so they render in Obsidian. Never use `.template` or other extensions for vault content — Obsidian ignores non-.md files. Copy to target, fill placeholders, delete unused sections.

## Supporting Files

- **persona-audit-checklist.md** — Exhaustive checklist for reviewing a persona document after authoring. Covers structural ordering, redundancy detection, metaphor audit, consistency scanning, and future-proofing. Use during refinement cycles.

## References

- `references/soul-evolution-case-study.md` — Full transformation of 7-Iris's SOUL.md from mythic (3,800 tokens) to direct behavioral rules (1,937 tokens), with exact changes and rationale per pass
- `references/context-file-ecosystem.md` — The four context file types (SOUL.md, AGENTS.md, CLAUDE.md, .hermes.md): purpose, location, prompt-slot, layering, comparison table. Templates path included.
