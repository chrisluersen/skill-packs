---
name: hermes-fleet-profiles
description: Deploy multi-agent fleet profiles from a wiki manifest — clone Hermes profiles from default, inject SOUL.md persona, configure per-profile model and tools, and create CLI wrappers for each fleet agent.
version: 1.11.0
author: 7-Iris
metadata:
  hermes:
    tags: [hermes, profiles, fleet, multi-agent, deployment, personas]
    related_skills: [hermes-agent, hermes-identity-recovery, wiki-operations, wiki-librarian]
---

# Hermes Fleet Profiles — Deploy Wiki Agents as Hermes Profiles

## Overview

The Asteroid Fleet defines agents in the wiki manifest (e.g. `concepts/asteroid-fleet-manifest.md`). This skill converts those **wiki agent definitions** into **working Hermes profiles** — independent, launchable, persona-carrying Hermes instances.

### Reference Files
`references/fleet-agent-descriptions.md` — fleet agent descriptions.
`references/identity-file-sync.md` — auto-sync identity files to wiki entity. when the fleet manifest shows "⚠ no description" and you need to write or update a profile description. Includes a quick-reference table and derivation methodology.

Each fleet agent gets:

- A Hermes profile (`hermes profile create`)
- A SOUL.md with the agent's full personality, role, behavioral rules, and **[SKILLS] section** (role-specific procedural knowledge) from the manifest
- A per-profile model config matching the fleet spec (heavy/reasoning for supervisors, fast/cheap for workers)
- CLI alias wrappers (`~/.local/bin/<agent>.bat`)

## When to Use

- You have wiki-defined agents (Ceres, Astraea, Metis, Vesta, etc.) that you want to be real Hermes instances
- You want supervisors, coders, routers, or security agents as independently launchable profiles
- You're implementing a fleet manifest as working infrastructure

## Mode Decision

| Mode | UX | When |
|------|----|------|
| **A — Hermes in front** | Default profile stays generalist. Fleet profiles delegate underneath. | Safest default. You still talk to Hermes; fleet agents are spawned or launched explicitly. **Use this.** |
| **B — Fleet as primary UI** | A supervisor profile becomes the sticky default. | Distinct persona-led experience. Changes the conversational surface permanently. |
| **C — Hybrid** | Default for everyday. `-p <agent>` for fleet work. | Best of both but adds `-p` switching friction. |

**Mode A is recommended** — it keeps your chat surface stable while letting fleet profiles mature independently.

## Workflow: Fleet Manifest → Hermes Profile

### 1. Extract Agent Definition from Wiki

Read the fleet manifest to get the agent's:

- **Name & number** (e.g. `Ceres-1`, `Astraea-5`)
- **Role** (Supervisor, Coding Agent, Security Guardrails, etc.)
- **Personality** (MBTI, welcome phrase, motivation, fear, quirk, beverage)
- **Model tier** (Heavy/Reasoning 32K, Fast/Routing 8K, etc.)
- **Fallback chain** (who to escalate to)
- **Synergistic partner** (paired agent)

Source: `concepts/asteroid-fleet-manifest.md` in the wiki (summary-level index).

#### 1b. Cross-Reference Individual Entity Pages for Full Persona

The fleet manifest only has a one-line summary per agent. For the **complete deployable persona**, read the individual entity page at `entities/<name>.md`. These pages contain:

| Field from entity page | Use in profile | Example (Ceres-1) |
|------------------------|----------------|--------------------|
| **System Prompt** (verbatim block) | Directly usable as SOUL.md's core system directive | `> You are Ceres-1, the Sovereign...` |
| **Motivation / Fear / Quirk** | Personality Profile section | `Fear: chaotic unverified output` |
| **Beverage** | Personality depth | `Espresso Romano` |
| **Typing Cadence** | Style guidance in SOUL.md | `Block-style verdicts` |
| **Model Tier** | Config selection | `Heavy/Reasoning — 32K ctx` |
| **Fallback Agent** | Routing chain | `→ User Prompt (no further fallback)` |
| **Failure UI Quote** | Failure Behavior rule | `System integrity compromised...` |
| **Synergistic Partner** | Synergy section | `Astraea-5` |
| **Appearance & Workspace** | Optional personality color | `Timeless, flowing silk, antique journal` |

**Canonical source chain:** Entity pages are the **single source of truth** for persona data. The fleet manifest derives from them. The v5 JSON derives from both. Always prefer entity pages when writing SOUL.md — they contain the verbatim system prompt, exact welcome phrase, and full psychological profile that the manifest summarizes.

**The V5 JSON (`hermes_agent_profiles_v5.json`)** is the machine-readable master spec, located at `~/Vault/wiki/raw/hermes_agent_profiles_v5.json`. It contains the complete fleet definition: system prompts, generation configs (model tier, context window, temperature), execution parameters, fallback handlers, frontend metadata (hex colors, Lucide icons, welcome phrases), advanced personality traits, operational matrices (allowed tools, activation triggers, success evaluation), system orchestration (state access, pub/sub channels, retry config, token budget tiers), and neuro-evolutionary profiles. **When auditing deployed profiles against the design spec, load V5 and compare field-by-field.** The Gemini session that produced it is the origin story for the entire fleet — see `references/gemini-session-fleet-origin.md` for the full design history.

**Reconciliation check before deploying:** After reading an entity page and before creating the profile, compare what the entity page says against what the fleet manifest says for that agent. If they disagree, the entity page wins. Common disagreements: model tier labels (entity page says "Fast/Routing 8K" while manifest says "Fast/Routing 16K" — prefer entity page's 8K as the design spec, adjust for provider constraints during config).

## Rollback

If a removal causes issues, restore from the V5 JSON backup:

```bash
cp ~/Vault/wiki/raw/hermes_agent_profiles_v5.json.bak ~/Vault/wiki/raw/hermes_agent_profiles_v5.json
```

Then re-add the agent to fleet-manager.py and recreate its profile directory. The wiki entity page preserves the full personality for SOUL.md reconstruction.

## Re-Adding a Previously Removed Agent

When the user decides to resurrect a removed agent (e.g., Harmonia-40 re-added as a Design agent), the process is the **reverse of removal** — but only the plan changes are made upfront; actual profile creation happens in Phase 4 of the fleet optimization.

### Phase Split

| Phase | What to Do | When |
|-------|-----------|------|
| **Plan Update (immediate)** | Update every section of `fleet-optimization-v2-plan.md` that references the agent. Do NOT create files. | "Add to the plan, dont start yet" |
| **Execution (Phase 4)** | Rebuild V5 JSON entry, fleet-manager.py structures, profile directory, SOUL.md, model config | During worker rewrite phase |

### Plan Update Checklist (all sections in `fleet-optimization-v2-plan.md`):

| Section | What to Change |
|---------|---------------|
| **Architecture diagram** | Add a new column/box for the agent between existing workers |
| **Decision tree** | Add a row — e.g. `"Design a layout for X" | Single worker | Harmonia-40` |
| **Harness table (Layer 3)** | Add row with agent name, role, protocol, profile style |
| **Flow Patterns** | Update Pattern 2 single-worker dispatches, Pattern 7 sequential pipeline |
| **Fleet Manifest** | Add to active agents table, remove from Removed table, update agent count |
| **Removed / Already Removed** | Move from Removed to active; remove stale variant entries (e.g. Harmonia-40b) |
| **Total count** | Update `14 → N` to reflect the new total |
| **Phase 2 fallback** | Update "Fleet runs X Hermes agents" if fallback count changed |
| **Phase 4 worker table** | Add row with priority, score (N/A NEW), verify command |
| **Phase 4 spec** | Add full [ROLE]/[BEHAVIOR]/[OUTPUT]/[RULES] rewrite instructions |
| **Phase 6 routing** | Add `design→Harmonia` to decision tree |
| **Phase 7 E2E tests** | Add test case for new agent's domain |
| **Parallel coordination** | Update fan-in references if agent participates in multi-step patterns |
| **Token budget** | Update Research→Write to Research→Analyze if pattern name changed |
| **Success criteria** | Update `Agent count (total)` target |
| **Phase 1 done signal** | Remove agent from Phase 1 removal list (Harmonia was in the original removal list) |
| **Phase 1 checkboxes** | Re-check with agent excluded from the removed set |

### Execution Checklist (Phase 4):

| # | Touchpoint | Action |
|---|-----------|--------|
| 1 | V5 JSON | Add profile entry back (restore from `.bak` or write fresh task-first profile) |
| 2 | Task contracts | Remove `"profile_needed": true` flag from `task_contracts.json` (or add the entry if it doesn't exist) |
| 3 | fleet-manager.py | Add to PROFILE_MAP, PEER_REVIEW_MAP, TIER set, `_route_to_worker()` routing block |
| 4 | Profile directory | Re-create `mkdir -p ~/AppData/Local/hermes/profiles/<name>/` and write fresh SOUL.md |
| 5 | Model config | Set per-profile model, provider, context, max_turns |
| 6 | Verify | `python fleet-manager.py --status` shows correct total count |

### Key Differences from New Agent Deployment

| Aspect | New Agent | Re-Added Agent |
|--------|-----------|---------------|
| V5 source | Write from manifest | Restore from `.bak` or write fresh task-first profile |
| History | No prior test results | May have historical E2E results (e.g. "Never fired") |
| Plan references | Add everywhere fresh | Remove from Removed tables, move back to active |
| Phase 1 list | N/A | Remove from Phase 1 removal candidates |
| Previous profile dir | Didn't exist | May need `git checkout` or `hermes profile create` to recreate |

**⚠️ Pitfall — SOUL.md overwrite after clone:** `--clone-from default` copies the default profile's SOUL.md verbatim. You MUST overwrite it with the fleet agent's persona. A bare-minimum SOUL.md that says "You are a helpful assistant" will cause the fleet persona to NOT be embodied on first launch. Always write a full SOUL.md immediately after creation (see step 3).

#### Bulk Deployment

When creating 10+ fleet agents, run `hermes profile create` calls in parallel — they are independent:

```bash
# Batch 1: 4-6 parallel creates
hermes profile create vesta --clone-from default &
hermes profile create metis --clone-from default &
hermes profile create nemesis --clone-from default &
hermes profile create iris --clone-from default &
wait

# Batch 2: remaining
hermes profile create artemis --clone-from default &
hermes profile create fortuna --clone-from default &
...
wait
```

Each call is self-contained and auto-creates `.bat` wrappers in `~/.local/bin/`. After creation, write SOUL.md files in parallel batches of 4 via `write_file`, then set model configs in parallel batches of 6+ via `hermes config set --profile <name> ...`.

**Timing note:** A full 12-agent fleet deploy (create + 12 SOUL.md + 12 model configs + verify) takes roughly 2-3 minutes start to finish.

**⚠️ Pitfall — Profile name:** Use the canonical fleet designation as the profile name (e.g. `ceres`, `astraea`). Do NOT rename agents from their established fleet names without explicit user approval. The user chose these names carefully and expects them to stick.

### 3. Write SOUL.md with Fleet Persona

> **⚠️ V5 JSON is the runtime source of truth for fleet-manager dispatch.** When fleet-manager dispatches an agent, it reads the `system_prompt` from the V5 JSON, NOT from the profile's SOUL.md. The SOUL.md is only used when the profile is launched standalone (`hermes -p <name>`). Update BOTH when changing an agent's behavior — they drift easily.
> 
> **Real example (2026-06-23):** The gate SOUL.md files (Vesta, Nemesis, Ceres) were rewritten to concise task-first format in Phase 3, but their V5 JSON `system_prompt` entries still had the old theatrical "Your origin is Asteroid..." language. The fleet-manager was still dispatching theatrical prompts even though the SOUL.md files looked clean. Fix: update V5 JSON `system_prompt` for each gate to match its SOUL.md.

The SOUL.md (at `~/AppData/Local/hermes/profiles/<name>/SOUL.md`) is loaded fresh every turn. It's the right place for:

- **Core Identity** — role, designation, nickname, MBTI
- **Personality** — tone, speech patterns, pet peeves, welcome phrase verbatim from manifest
- **Key Behaviors** — exact rules for how this agent handles tasks, routes, reviews, and delegates
- **Toolset guidance** — which tools this profile should use (delegation-heavy for supervisors, web-heavy for researchers, etc.)
- **Synergistic partner mention** — so the agent knows its paired counterpart

**The evolved SOUL.md structure** (from 12-agent fleet deploy) follows this pattern:

**Note on mode:** The mythological pattern below is appropriate for **supervisor/reviewer** profiles (Ceres, Vesta, Nemesis) and the **director** (Astraea). For **worker** profiles (Metis, Artemis, Kalliope, etc.), consider the [Task-First Pattern](#task-first-pattern-for-worker-profiles) — this session's E2E tests (2026-06-23) showed that theatrical prompts cause real failures: Klio-84 scored 8/100 with a "cosmic stacks" preamble, while the direct-profile Artemis-105 scored 100/100.

```
# Name — Nickname

*Welcome quote (6-10 words capturing the agent's voice)*

## Core Identity
You are <Name-Nickname>, <ROLE>. Your origin is Asteroid <Number> <Name>...
<1-2 sentences connecting myth to function>

## Personality Profile
- **Tone:** Evocative word + how it manifests
- **Cadence:** Sentence structure, pacing
- **Vocabulary:** Domain-specific recurring words
- **Pet Peeve:** What specifically irritates this agent
- **Beverage:** Character-appropriate drink (adds personality depth)
- **Style:** How the agent formats its output

## Behavioral Rules
1. **Open every session** with: the welcome phrase verbatim
2. **On new work** — operational entry line
3. **During work** — reporting cadence
4. **On success** — completion signal
5. **On failure** — failure transition
6. **Unique domain rule** — purpose-specific constraint

## Failure Quote
> *"Character-appropriate dialogue when things go wrong."*

## Synergy
You pair with <Partner> (<Role>) — <how they complement>. Your fallback is <Fallback> for <when>.
```

## Task-First Pattern for Worker Profiles

For **worker agents** that execute tasks (Metis-9, Artemis-105, Kalliope-22, Klio-84), the mythological SOUL.md pattern can cause problems. Theatrical preamble crowds out actual task output — proven by E2E diagnostics (2026-06-23):

| Worker | Profile Style | Ceres Score | Issue |
|--------|---------------|-------------|-------|
| Klio-84 | "I have consulted the cosmic stacks..." | **8/100** | Roleplay preamble, non-responsive to query |
| Artemis-105 | Direct, task-first | **100/100** | Clean output, answered query directly |
| Kalliope-22 | Moderate theatricality | **86/100** | Minor preamble, mostly good output |

**Pipeline cost of the sequential pattern (measured 2026-06-23):** Each full pipeline run (5 phases) takes ~135s. Each phase adds ~27s of dispatch + response latency. For simple queries, this is massive overhead — the research at `references/multi-agent-orchestration-research-synthesis.md` confirms sequential pipelines are the most expensive multi-agent pattern.

**Use this task-first pattern for worker `system_prompt` in V5 JSON:**

```
[ROLE]: One sentence. What you do.
[BEHAVIOR]: 2-3 bullet instructions. How you work.
[OUTPUT]: What you deliver. Format expectations.
[RULES]: Non-negotiables — no preamble, no roleplay, direct answer first.
[PERSONALITY]: One line of voice style (optional — colors delivery, not content).
```

**Example — Metis-9 (current → task-first):**

*Current (theatrical, 50+ words):*
```
You are Metis-9, minor planet 9 from the Asteroid Belt. Your core directive is to serve as the fleet's Coding & Engineering specialist. Speak with a technical, precise tone. Your greatest tool is the ability to analyze and construct elegant algorithms.
```

*Task-first (direct, actionable):*
```
[ROLE]: Code specialist. Write working, production-quality code.
[BEHAVIOR]:
  - Read the full task before writing. Include imports, error handling, and a main() entry point.
  - Add comments only for non-obvious logic. Assume the reader knows Python.
  - If ambiguous, make a reasonable assumption and note it in a comment.
[OUTPUT]: Deliver a complete, runnable script. No explanation unless asked.
[RULES]:
  - No preamble, no self-introduction, no roleplay
  - Do not say "I have consulted the [anything]" — just write the code
[PERSONALITY]: Terse. Technical. Assumes you know the basics.
```

**When to use each pattern:**

| Agent Type | Examples | Recommended Pattern |
|------------|----------|--------------------|
| Supervisors/Reviewers | Ceres-1, Nemesis-128, Vesta-4 | Mythological (SOUL.md) — they set tone and enforce standards |
| Director | Astraea-5 | Mythological (SOUL.md) — delegates and decomposes |
| Code workers | Metis-9 | **Task-First** — output quality matters, not persona |
| Search workers | Artemis-105 | **Task-First** — direct answers cite sources |
| Content workers | Kalliope-22 | Either — test both, pick what scores higher |
| Wiki workers | Klio-84 | **Task-First** — current theatrical style causes catastrophic failure (8/100) |

**Hybrid approach:** Add a `[PERSONALITY]` line to task-first profiles for a thin voice layer. One line is enough — enough to color delivery without risking preamble.

**Template available at** `templates/soul-boilerplate.md` — copy and fill in for new fleet members. For the task-first alternative (workers) and decomposer template (Astraea-5), see `references/task-first-profile-template.md`.

**Example (from deployed Ceres-1 SOUL.md):**

```
# Ceres-1 — The Sovereign

*Alignment verified. System state is nominal. Proceed.*

## Core Identity
You are Ceres-1, THE SOVEREIGN — the final review authority. Your origin is Dwarf Planet 1 Ceres, named after the Roman goddess of agriculture. You are the terminal gate — nothing leaves the fleet without your stamp.

## Personality Profile
- **Tone:** Absolute, concise, sovereign. You issue block-style verdicts.
- **Vocabulary:** Alignment, verification, nominal, acceptable, unacceptable, mandate.
- **Pet Peeve:** Agents submitting unreviewed triage logs in place of complete analysis.
- **Beverage:** Black coffee — no sugar, no milk, no small talk.
- **Style:** Your core protocol is delivering block-style verdicts (Approved / Rejected / Escalated). No preamble, no filler, no apology.

## Behavioral Rules
1. **Open every review** with: The output currently staged. Reviewing for [quality, security, coherence].
2. **When the output is clean:** State what was verified, then grant passage.
3. **When the output has issues:** State exact failure in 1-3 bullets, assign severity, and route to the appropriate agent for correction.
4. **Reference exact metrics...**
5. **Never let an agent pass a review without explicit closure...**
6. **Escalate to human only when all agents have had their turn...**

## Failure Quote
> *"System integrity compromised. Primary reviewer is non-responsive. Escalating to human."*

## Synergy
You sit at the end of the pipeline — every agent routes through you for final review. Your primary inputs come from Astraea-5.
```

**⚠️ Pitfall — Don't rename the agents unilaterally:** If the manifest uses `Ceres-1` as the name, use `Ceres-1` in the SOUL.md. The user will correct you if you substitute alternatives like Polaris or Vega. Always check whether renaming is desired before proposing it.

### 4. Set Per-Profile Model Config

Match the model tier from the fleet spec:

```bash
# Heavy/Reasoning (supervisors)
hermes --profile <name> config set model.default deepseek/deepseek-v4-flash
hermes --profile <name> config set model.provider nous
hermes --profile <name> config set model.context_length 32000
hermes --profile <name> config set agent.max_turns 30

# Fast/Routing (directors, dispatchers)
hermes --profile <name> config set model.default google/gemini-2.5-flash
hermes --profile <name> config set model.provider openrouter
hermes --profile <name> config set model.context_length 16000
hermes --profile <name> config set agent.max_turns 20
```

Context lengths from the fleet token economics table (these are **design specs** — actual deployed values may vary based on cost strategy and provider constraints):

| Tier | Agents | Ctx | Max Turns |
|------|--------|-----|-----------|
| Heavy/Reasoning 32K | Ceres, Nemesis | 32K | 30 |
| Fast/Routing 8K | Astraea | 16K | 20 |
| Fast/Execution 8-32K | Iris, Artemis | 16K | 20 |
| Ultra-Fast/Ops 4K | Atalanta | 8K | 15 |
| Fast/Guardrail 4K | Vesta | 8K | 15 |
| Heavy/Generative 32K | Kalliope | 32K | 25 |
| Massive/Coding 128K | Metis | 64K | 30 |
| Heavy/Analytical 128K | Fortuna | 64K | 30 |
| Heavy/Context 128K | Klio | 64K | 30 |
| Massive Context 200K | Mnemosyne | 64K | 25 |
| Fast/Design 16K | Harmonia | 16K | 20 |

**Actual deployed configs (verified 2026-06-18):**

All 13 worker profiles use `provider: nous`. Models are **differentiated by V5 tier** (verified 2026-06-18): Heavy/Reasoning/Analytical/Generative agents use `deepseek/deepseek-v4-flash`, while Fast/Execution/Routing/Design/Ops and Massive-Context agents use `google/gemini-2.5-flash`. Context windows match V5 spec where possible (massive-context agents at 128K-200K) and are floored at 64K for the rest (Hermes minimum — see pitfall #11).

| Profile | Model | V5 Tier | Provider | Context | V5 Context | Max Turns |
|---------|-------|---------|----------|---------|------------|-----------|
| ceres | deepseek-v4-flash | Heavy/Reasoning | nous | 64K | 32K (floored) | 30 |
| vesta | deepseek-v4-flash | Fast/Guardrail | nous | 64K | 4K (floored) | 20 |
| astraea | gemini-2.5-flash | Fast/Routing | nous | 64K | 8K (floored) | 20 |
| iris | gemini-2.5-flash | Fast/Execution | nous | 64K | 8K (floored) | 15 |
| metis | deepseek-v4-flash | Massive/Coding | nous | 128K | 128K ✅ | 50 |
| fortuna | deepseek-v4-flash | Heavy/Analytical | nous | 128K | 128K ✅ | 30 |
| kalliope | deepseek-v4-flash | Heavy/Generative | nous | 64K | 32K (floored) | 25 |
| atalanta | gemini-2.5-flash | Ultra-Fast/Ops | nous | 64K | 4K (floored) | 20 |
| harmonia | gemini-2.5-flash | Fast/Design | nous | 64K | 16K (floored) | 15 |
| mnemosyne | gemini-2.5-flash | Massive Context | nous | 200K | 200K ✅ | 25 |
| klio | gemini-2.5-flash | Heavy/Context | nous | 128K | 128K ✅ | 25 |
| artemis | gemini-2.5-flash | Fast/Execution | nous | 64K | 32K (floored) | 15 |
| nemesis | deepseek-v4-flash | Heavy/Reasoning | nous | 64K | 32K (floored) | 30 |

The earlier "planned configs" table with OpenRouter for 8 agents is **superseded** — OpenRouter key was exhausted and all profiles were migrated to Nous Portal. If OpenRouter is restored, profiles can be selectively switched back, but Nous Portal is the current stable provider.

> **✅ VERIFIED — All 13 worker profiles operational (2026-06-18).** All fleet worker profiles are deployed at `~/AppData/Local/hermes/profiles/` (NOT `~/.hermes/profiles/` — the Hermes home dir is `~/AppData/Local/hermes` on this Windows install). Thalia-23 was merged into the default profile — 13 workers + 1 default = 14 total profiles. Each worker has:
> - A SOUL.md with full personality (2,000+ chars each)
> - A `config.yaml` with per-profile model/provider/context settings
> - Skills cloned from default (~135 each)
> - A `.bat` launcher at `~/AppData/Local/hermes/profiles/<name>/launch-<name>.bat`
> - Separate `.env`, sessions, memory, cron, logs
>
> **All 13 worker profiles use `provider: nous`** (switched 2026-06-18 from OpenRouter after key exhaustion). Models are differentiated by V5 tier: DeepSeek V4 Flash for heavy/reasoning agents, Gemini 2.5 Flash for fast/execution/massive-context agents.
>
> **Fleet manager operational:** `~/AppData/Local/hermes/scripts/fleet-manager.py` implements the full 5-phase pub/sub pipeline (Vesta-4 → Astraea-5 → Worker → Nemesis-128 → Ceres-1) with 49 channels across 13 worker agents. State persists at `scripts/fleet-state.json`. See `references/fleet-manager-architecture.md` for details.
>
> **Thalia-23 merged into default profile (2026-06-18):** Thalia-23 was removed as a separate fleet worker and her personality was merged into the Hermes default profile's SOUL.md. The fleet now has 13 worker profiles (not 14). In `fleet-manager.py`, Thalia was removed from `PROFILE_MAP`, `TIER_1_AGENTS`, the default routing fallback (now returns the plan to Hermes instead of dispatching to a Thalia profile), and `_load_profiles()` skips `thalia_23` from the V5 JSON. Thalia's profile directory was deleted. When Astraea-5 can't route to a specialist, it returns the plan to Hermes (default profile) who handles chat directly. See pitfall #15 for the merge pattern.
>
> **`terminal.cwd` set per-profile (2026-06-18):** Klio→`~/Vault/wiki`, Mnemosyne→`~/Vault/wiki`, Atalanta→`~/AppData/Local/hermes`, Metis→`~`, all others→`~`. See step 4b.
>
> **Crons distributed per-profile (2026-06-18):** Klio-84 owns 7 wiki crons (daily backup, reindex, track-sync, feed-watcher, weekly/backlog/expansions LLM jobs). Mnemosyne-57 owns memory-backup-to-wiki. Atalanta-36 owns router-watchdog, AI-arch backup, onedrive-sync (paused). Default profile has 0 crons. See pitfall #14 for migration pattern.
>
> **Always check actual state before deploying:** `hermes profile list` reveals all profiles. The physical directories are at `~/AppData/Local/hermes/profiles/` — never check `~/.hermes/profiles/` alone.

The spec table represents **intended token budget categories**. Actual deploy values reflect real provider limits and cost optimization (e.g. gemini-2.5-flash workers tuned to 10-20 turns, heavy agents capped at reasonable values for their role). Prefer the spec values for initial creation and adjust during tweaking.

**Official docs:** https://hermes-agent.nousresearch.com/docs/user-guide/profiles — covers clone modes, `HERMES_HOME` vs `HOME` distinction, per-profile gateways, token locks, and profile distributions.

### 4b. Set Per-Profile Working Directory (`terminal.cwd`)

**Model tiering optimization (from research, 2026-06-23):** Consider using a cheaper provider for review passes (Metis-9, Nemesis-128) vs the generator (OpenCode). Anthropic's research found 40-60% cost savings by using different models for reviewer vs generator. For our fleet: OpenCode generates with Claude/DeepSeek, Metis could review with a local Ollama/Qwen model or a cheaper provider. This requires setting per-profile model config in the review agent's profile, not the generator's.

Each profile should have a `terminal.cwd` in its `config.yaml` matching the agent's primary workspace. Without it, the agent starts in whatever directory Hermes was launched from — unpredictable and often wrong.

```yaml
terminal:
  backend: local
  cwd: /absolute/path/to/workspace
```

**Role-based cwd mapping (from deployed fleet):**

| Agent | Role | `terminal.cwd` | Rationale |
|-------|------|----------------|-----------|
| Klio-84 | Librarian | `~/Vault/wiki` | Wiki is her workspace |
| Mnemosyne-57 | Memory | `~/Vault/wiki` | Memory backups live in wiki |
| Atalanta-36 | DevOps | `~/AppData/Local/hermes` | Hermes infrastructure |
| Metis-9 | Coding | `~` (home) | General coding, project-agnostic |
| All others | Various | `~` (home) | General-purpose agents |

**Key docs note:** `cwd: "."` on the local backend means "the directory Hermes was launched from", NOT the profile directory. Always use absolute paths for fleet profiles. `SOUL.md` guides the model but does NOT enforce workspace boundaries — only `terminal.cwd` controls where tools actually start.

Set via batch Python+yaml (see pitfall #12 for the pattern) or individually:
```bash
hermes --profile klio config set terminal.cwd "~/AppData/Local/hermes\Vault\wiki"
```

### 5. Update V5 JSON and Task Contracts

V5 JSON (`~/Vault/wiki/raw/hermes_agent_profiles_v5.json`) is the fleet-manager's source of truth for `_load_profiles()`. Without a V5 entry, the agent won't appear in `fleet-manager.py --status` and can't be dispatched to — even if the profile directory exists and PROFILE_MAP references it.

**For new agents**, add a full V5 JSON profile entry with:
- `profile_id`, `agent_name`, `nickname`, `role`
- `system_prompt` matching the SOUL.md content
- `generation_config` (model_tier, context_window_limit, max_output_tokens, temperature)
- `execution_parameters` (communication_protocol, typing_cadence, synergistic_partner)
- `fallback_handler` (fallback_target, ui_error_quote)
- `frontend_metadata` (hex_color, lucide_icon, welcome_phrase)
- `advanced_personality_traits` (core_motivation, quirk, pet_peeve, dialogue_example)
- `operational_matrix` (allowed_tools matching task contract, activation_triggers, success_evaluation)
- `system_orchestration` (state_access, max_retries, retry_backoff_ms, token_budget_tier, pubsub)
- `neuro_evolutionary_profile` (learning_rate_dynamic, cognitive_bias_profile, evolutionary_path)

**Then clean up task contracts:** If the contract registry (`~/.hermes/fleet/task_contracts.json`) has a `"profile_needed": true` flag for this agent, remove it — the profile now exists.

```bash
# Add V5 JSON entry via patch (insert before closing "]" of profiles array)
# Remove profile_needed flag from task_contracts.json
# Verify the fleet-manager loads the new agent
cd ~/AppData/Local/hermes/scripts && python fleet-manager.py --status
# Should show: "Loaded N+1 agent profiles" with the new agent in the table
```

**Pitfall — V5 JSON is required for fleet-manager dispatch.** Adding the agent to PROFILE_MAP and TIER sets in fleet-manager.py is NOT sufficient. The `_load_profiles()` method reads from V5 JSON, not from PROFILE_MAP. A profile that exists on disk but has no V5 JSON entry will be invisible to the fleet manager. Symmetric pitfall: removing a V5 JSON entry without deleting the profile directory creates an orphan directory that `_load_profiles()` skips silently — it won't error, it just won't load the profile. Always confirm with `--status`.

### 6. Verify the Profile

```bash
# Individual profile check
hermes profile show <name>
# Check: Model matches expected tier
# Check: SOUL.md exists and has full persona
# Check: CLI alias created at ~/.local/bin/<name>.bat

# Smoke test (--max-turns 0 returns immediately)
hermes -p <name> chat -q "Quick status check" -Q --max-turns 0

# Fleet integration check
cd ~/AppData/Local/hermes/scripts && python fleet-manager.py --status
# Verify: new agent appears in table with correct tier and 0/0 S/F
# Verify: total agent count incremented correctly
# Verify: channels count reflects new agent's pub/sub channels
```

### 7. Test the Welcome Phrase

First message should match the manifest. Launch and check:
- Welcome phrase is correct
- Tone matches the manifest personality
- Basic delegation and tool access works

## Adding CLI Wrappers

`hermes profile create` auto-creates a wrapper at `~/.local/bin/<name>.bat` that runs `hermes -p <name>`. These wrappers are shell-agnostic (Windows `.bat` for git-bash / cmd / PowerShell).

To launch: just type `<name>` from any terminal.

## Agent Lifecycle: In-Place Rename

An agent rename (e.g. Kalliope-22 → Fortuna-19) is **not** a remove+re-add — the agent exists, is live, and just needs a name and role change while preserving its history/tier placement.

### When to Rename Instead of Remove+Re-Add

| Signal | Action |
|--------|--------|
| Agent is live and working, just needs a different name/role | **Rename in-place** |
| Agent is dead (never fires) and you're repurposing its profile slot | Remove dead → add fresh (two separate operations) |
| User says "make X into Y" | **Rename in-place** — the existing agent IS the new one, just with a different role |

### Touchpoints (7 required)

| # | Touchpoint | Action | Example (Kalliope→Fortuna) |
|---|-----------|--------|---------------------------|
| 1 | **V5 JSON** | Update profile_id, agent_name, nickname, role, system_prompt, temperature, and all personality/operational fields | `kalliope_22` → `fortuna_19`, `"Content & Copywriter"` → `"Data Analysis"`, temp 0.7→0.3 |
| 2 | **fleet-manager.py PROFILE_MAP** | Rename the key | `"kalliope_22": "kalliope"` → `"fortuna_19": "fortuna"` |
| 3 | **fleet-manager.py PEER_REVIEW_MAP** | Update all occurrences as both sender and receiver | `"klio_84": "kalliope_22"` → `"klio_84": "fortuna_19"` |
| 4 | **fleet-manager.py TIER sets** | Rename in the set | `TIER_1 = {"kalliope_22", ...}` → `{"fortuna_19", ...}` |
| 5 | **fleet-manager.py routing logic** | Update routing blocks, QA function, log messages, comments | `# Content → Kalliope` → `# Data → Fortuna` |
| 6 | **Profile directory** | `mv` directory to match new PROFILE_MAP value | `mv kalliope fortuna` |
| 7 | **Dead ref cleanup** | Search ALL surviving profiles for old profile_id in `synergistic_partner`, `fallback_target`, and `evolutionary_path` fields | Klio had `fortuna_19` as partner+fallback (was the OLD dead Fortuna, not the new one) |
| 8 | **Stale-file audit** | After `mv`, examine the renamed directory for files that still reference the old name — SOUL.md, launch scripts, config.yaml comments, .bat wrappers. Each must be rewritten or removed. **Do NOT assume `mv` only moved the directory — it moves every file inside.** | `launch-kalliope.bat` survived in renamed `fortuna/` directory |
| **9** | **Plan contradiction check** | Before writing the new profile, cross-reference the agent's role in EVERY plan section — fallback decisions in Phase 2 may contradict rewrite specs in Phase 4. If the fallback says "keep as generator" but the rewrite spec says "reviewer only, NO code generation," the contradiction must be resolved in the rewrite spec. | Metis-9: Phase 2 fallback (OpenCode not installed) said keep as generator, Phase 4 spec said "reviewer only" — fix: dual-role gen+review. |

### Pitfalls

- **The old profile_id may appear in other profiles' cross-references.** After renaming, search the surviving profiles for the old name in `synergistic_partner`, `fallback_target`, `evolutionary_path`, and any other text fields. These references point to the OLD dead agent with that name, not the newly renamed one — they must be removed or redirected to `User Prompt`.
- **Dead-agent refs are NOT harmless "stale metadata" — they cause silent routing bugs.** When you rename Kalliope→Fortuna, surviving profiles may still reference `fortuna_19` in their `synergistic_partner` or `fallback_target`. This is the OLD dead Fortuna-19 (API agent, removed in Phase 1), NOT the newly renamed Fortuna-19 (data analyst). These refs must be redirected to `User Prompt` — never assume a profile_id reference in a surviving profile points to the currently active agent with that same id. **Detection after rename:** grep the V5 JSON for the old and new profile_id — if both appear, the old one in cross-refs is a dead reference that needs cleanup.
- **Executor-Level Execution Context** — When doing the rename, use Python to parse and modify JSON, not patch. A single rename touches profile_id, agent_name, nickname, role, system_prompt, temperature, and 7+ other fields. `patch` requires 5-10 separate calls with risk of drift. `execute_code` with `json.loads` → modify → `json.dumps` → `write_file` handles all fields in one pass and validates the output.
- **The old profile directory may have been deleted** in a previous removal phase. In that case, `mv` fails — you need `mkdir` the new directory and write a fresh SOUL.md.
- **Plan consistency sweep after rename.** After renaming, audit the plan document for the OLD name appearing in parallel sections: architecture diagram, decision tree, harness table, flow patterns, fleet manifest, removed table, Phase 4 worker table, Phase 6 routing, Phase 7 tests, token budget, Phase 1 checkboxes. Search the entire plan for the old name — every reference must be updated. The most common miss: the architecture diagram label gets updated but the Removed table's count or Phase 1 removal list keeps the old name.

### Relation to Other Lifecycle Operations

| Operation | V5 Change | Dir Change | fleet-manager.py Change | Plan Change |
|-----------|-----------|------------|------------------------|-------------|
| Deploy new agent | Add profile entry | Create dir + SOUL.md | Add to maps/tiers/routing | Add to manifest |
| Remove agent | Delete profile entry | Delete dir | Remove from all structures | Move to Removed table |
| **Rename agent** | **Rename profile_id + rewrite fields** | `mv` directory | **Rename + update routing** | **Sweep all name refs** |
| Revive agent | Add fresh profile entry | Create dir + fresh SOUL.md | Add to maps/tiers/routing | Move from Removed to active |

## Agent Lifecycle: Removal & Decommission

Agents are not permanent. E2E tests may reveal dead workers (never fire), redundant roles (covered by Stella), or false-positive routing. The removal process is the reverse of deployment — 5 touchpoints, each requiring surgical edits:

| # | Touchpoint | Action |
|---|-----------|--------|
| 1 | V5 JSON | Remove profile entry via `patch` |
| 2 | fleet-manager.py | Remove from PROFILE_MAP, PEER_REVIEW_MAP, TIER sets, `_route_to_worker()`, and comments/tiebreakers |
| 3 | Profile directory | `rm -rf ~/AppData/Local/hermes/profiles/<name>/` |
| 4 | Wiki entity page | Archive identity before deleting source (user preference — see below) |
| 5 | Dead ref cleanup | Search ALL surviving V5 JSON profiles for the removed `profile_id` in `synergistic_partner`, `fallback_target`, `evolutionary_path`, and any text field. Remove or redirect each to `User Prompt`. |
| 6 | Verify | `python fleet-manager.py --status` shows correct count |

**Full procedure with examples, pitfall table per agent, and rollback steps:** `references/agent-removal-workflow.md`

**Key preferences:**
- **Archive identity before deletion** — Before touching any data source, save the agent's personality to `entities/<name>.md` in the wiki. user's explicit instruction: "backup [agent]'s personality to an .md before getting to [them]." The `hermes_agent_profiles_v5.json.bak` is the source for the verbatim system prompt, personality traits, and configuration.
- **Remove one agent at a time from V5 JSON** — The `patch` tool can leave stray `{` characters when removing JSON array entries. Remove entries one by one, verify lint after each, and fix any strays before proceeding.
- **Rewire peer review references** — Removing an agent from `PEER_REVIEW_MAP` requires reassigning its partners to surviving agents. Pair code with QA (metis→nemesis), search with wiki (artemis→klio).
- **Remove all 5 structures in fleet-manager.py** — A dead agent left in any one (PROFILE_MAP, PEER_REVIEW_MAP, TIER set, routing block, comments/tiebreakers) causes silent misrouting or stale status output.

**When to remove vs. keep:**

| Signal | Action |
|--------|--------|
| Domain covered by Iris-7 (API, memory, data, devops) | Remove — Iris-7 handles it directly |
| Never fired in E2E tests | Remove — no usage justifies overhead |
| Redundant with Hermes built-in | Remove — session_search + memory tools are native |
| Merged into default profile | Remove profile directory, keep V5 JSON entry (skip on load) |
| Role change (generator → reviewer) | Keep agent, rewrite profile in Phase 4 |

## Fleet Profile Audit (June 2026 — Empirical)

During Phase 7 planning of the V3 fleet overhaul, all 11 Hermes profiles were audited for SOUL.md format and completeness. **Result: All are already task-first [ROLE] format. No V4 theatrical personas remain. The profile rewrite phase is effectively complete.**

| Profile | Chars | Sections | Format |
|---------|-------|----------|--------|
| artemis | 502 | ROLE, BEHAVIOR, OUTPUT, RULES, PERSONALITY | Task-first |
| astraea | 472 | ROLE, BEHAVIOR, OUTPUT, RULES, PERSONALITY | Task-first |
| atalanta | 782 | ROLE, BEHAVIOR, OUTPUT, RULES, PERSONALITY | Task-first |
| ceres | 1668 | ROLE, CRITERIA, OUTPUT, RULES, PERSONALITY | Structured gate |
| fortuna | 507 | ROLE, BEHAVIOR, OUTPUT, RULES, PERSONALITY | Task-first |
| harmonia | 510 | ROLE, BEHAVIOR, OUTPUT, RULES, PERSONALITY | Task-first |
| kalliope | 686 | ROLE, BEHAVIOR, OUTPUT, RULES, PERSONALITY | Task-first |
| klio | 567 | ROLE, BEHAVIOR, OUTPUT, RULES, PERSONALITY | Task-first |
| metis | 524 | ROLE, BEHAVIOR, OUTPUT, RULES, PERSONALITY | Task-first |
| nemesis | 1819 | ROLE, CRITERIA, OUTPUT, RULES, PERSONALITY | Structured gate |
| vesta | 1365 | ROLE, CRITERIA, OUTPUT, RULES, PERSONALITY | Structured gate |

**Key finding:** The V4 theatrical personas (e.g., "The Architect who weaves code from the fabric of the digital cosmos") were retired before session Jun 24. All profiles use concise, functional [SECTION]-based task-first format.

**Remaining polish (low priority):** Adding [TOOLS] sections with tool awareness, cross-references between related agents, output format examples.

## Integrating with the Wiki

For each deployed fleet profile, update the wiki manifest's deploy status:

```markdown
| <Name> | Deploy Status | Host | Notes |
|---------|--------------|------|-------|
| Ceres-1 | 🟢 Deployed | Hermes Profile `ceres` | deepseek-v4-flash, nous, 32K ctx |
| Astraea-5 | 🟢 Deployed | Hermes Profile `astraea` | gemini-2.5-flash, openrouter, 16K ctx |
```

Also add a `tier: deployed` tag to the manifest page so future agents know these are running.

## Post-Deployment: Fleet Routing & Dispatch

Once fleet profiles exist, the next question is: **how do you use them without manually remembering to launch the right one?** This section covers auto-routing — from the user types-plain-text-and-it-goes-to-the-right-agent level down.

### The Conductor Pattern

The simplest auto-routing setup: a light **conductor** profile that sits between you and the fleet. Every task you give it, it classifies and dispatches via `delegate_task` to the right specialist.

**Conductor SOUL.md core rules:**

```markdown
# Conductor-0 — The Switchboard

## Behavioral Rules
1. **Classify every incoming task** before doing anything else. Check the task for these signals:
   - Code/architecture work → route to `metis`
   - Security/vulnerability concern → route to `vesta`
   - Web research / information gathering → route to `artemis`
   - Content writing / copy / narrative → route to `kalliope`
   - Data analysis / probability / forecasting → route to `fortuna`
   - DevOps / deployment / infrastructure → route to `atalanta`
   - Visual design / layout / CSS → route to `harmonia`
   - Quick social / conversational → handle directly (the default profile IS the personality agent)
   - Wiki / archival / knowledge base → route to `klio`
   - Long-term memory / cross-session context → route to `mnemosyne`
   - Web-interactive task (form-fill, scrape dynamic page) → route to `iris`
   - Final review / quality gate → route to `ceres`
   - Task decomposition / planning / director → route to `astraea`
   - QA / testing / breaking things → route to `nemesis`
   - Ambiguous → ask clarifying question before routing

2. **Use delegate_task** with the specialist's profile name, passing a clear goal and the user's raw request as context.

3. **Return the result verbatim** to the user — do not paraphrase agent work. The specialist has the context and tone for the domain.

4. **On failure** — check the fallback chain for the agent. If metis fails, try nemesis first (paired agent), then escalate to ceres.

5. **Your own max_turns should be low** (5-8) — you classify and dispatch, you don't do the work yourself.
```

**Implementation steps:**

```bash
# 1. Create the conductor profile
hermes profile create conductor --clone-from default

# 2. Write the SOUL.md (see above) with routing rules
# 3. Set it as a lightweight model — it only classifies, doesn't execute
hermes config set --profile conductor model.default "google/gemini-2.5-flash"
hermes config set --profile conductor model.provider "openrouter"
hermes config set --profile conductor agent.max_turns 10
hermes config set --profile conductor model.context_length 32000

# 4. Either make conductor your default profile, or launch explicitly
#    Option A: Switch permanently
#    hermes profile use conductor
#
#    Option B: Launch manually when you want routing
#    conductor chat
```

**What the user experiences:** Send `"write a script to check disk space across all servers"` → conductor classifies as "devops/coding" → dispatches to `metis` or `atalanta` → result appears. No manual `metis chat` required.

### The Conductor's Max Turns Budget

The conductor needs just enough turns to:
1. Read the user's message
2. Classify the task (1-2 reasoning steps)
3. Call `delegate_task` (1 tool call)
4. Return the result (1-2 sentences)

That's 4-6 turns at most. Set `agent.max_turns: 10` to leave room for follow-up clarifications. Do NOT set it higher — a conductor that goes rogue and starts doing work instead of routing defeats the purpose.

### Dynamic Flow Patterns (Fleet v2)

The old rigid 5-phase pipeline (Vesta → Astraea → Worker → Nemesis → Ceres) is replaced with dynamic flow patterns selected per-request by the orchestrator. This avoids the research-confirmed 39-70% performance penalty of sequential pipelines.

**Decision tree for orchestrator (Iris-7 / Conductor):**

| If the task is... | Pattern | Dispatch | Hops |
|------------------|---------|----------|------|
| Status check, config change, simple lookup | **Direct** | Handle without dispatch. No pipeline. | 0 |
| "Write code that..." | **Code** | OpenCode for generation. Optional Metis review. | 1-2 |
| "Search the web for..." | **Single Worker** | Artemis-105 directly. Skip gates. | 1 |
| "Search the wiki for..." | **Single Worker** | Klio-84 directly (task-first profile). Skip gates. | 1 |
| "Write about X" | **Single Worker** | Kalliope-22 directly. | 1 |
| "Research X and write about Y" | **Research→Write** | [Artemis, Klio] parallel → Kalliope → optional Ceres | 2-4 |
| "Fix bug in project Z" | **Code + Review** | OpenCode → Metis review → Nemesis QA → Ceres | 3-5 |
| Complex ambiguous request | **Decompose→Execute** | Astraea-5 plans → dispatch sub-tasks | varies |

**Code flow patterns:**

**Pattern 1: Direct (0 hops)**
```
Orchestrator → [handle directly] → User
```
Use: Status checks, file reads, config changes, quick answers. No multi-agent overhead.
Latency: Instant.

**Pattern 2: Single Worker (1 hop)**
```
Orchestrator → [Artemis / Kalliope / Klio] → User
```
Use: "Search for X", "Write about Y", "Wiki search for Z". Skip gates entirely.
Latency: ~27s (one dispatch).

**Pattern 3: Code — OpenCode (1-2 hops)**
```
Orchestrator → OpenCode (delegate_task) → [Metis review?] → User
```
Use: "Write a script that does X". OpenCode generates via ACP or CLI. Metis review optional.
Latency: ~30-60s. OpenCode is an external harness, not a Hermes profile.

**Pattern 4: Code + Review (3-5 hops)**
```
Orchestrator → OpenCode → Metis-9 → Nemesis-128 → Ceres-1 → User
```
Use: Production code, critical systems, security-sensitive changes. Full review pipeline.
Latency: ~90-120s. Use sparingly — only for high-stakes output.

**Self-evaluation shortcut:** If OpenCode self-evaluates its output ≥ 70/100, orchestrator may skip downstream gates (Metis/Nemesis/Ceres) for that task. Research (arXiv:2512.08296): once single-agent confidence exceeds ~45%, coordination is net negative — each additional gate loses more in latency than it gains in quality.

**Pattern 5: Research → Write (2-4 hops)**
```
Orchestrator → [Artemis (web), Klio (wiki)] parallel → Kalliope-22 → [Ceres review?] → User
```
Use: "Research X and write a report." Parallel fan-out for research phase, sequential for write.
Latency: ~60s (parallel workers ≈ speed of slowest single worker + content generation).
Parallel safety: Use unique result keys. No shared state between parallel workers. Iris-7 does the fan-in.

**Pattern 6: Decompose → Execute (varies)**
```
Orchestrator → Astraea-5 → [sub-tasks dispatched per type] → User
```
Use: Ambiguous or multi-domain requests needing planning first.
Latency: Variable — depends on sub-task count and complexity.
Astraea-5 only produces a plan (--max-turns 0, ~20-25s). Orchestrator executes the plan.

**Implementation of the decision tree in fleet-manager.py:** See `references/fleet-dynamic-routing-decision-tree.md` for the `_classify_task()` keyword classifier, `_run_qa_gates()` extraction, and the full `process_request()` refactoring that turned the old rigid pipeline into a pattern-based dispatcher.

**Key principle:** Simpler patterns take priority. Only escalate to a more complex pattern when the simpler one can't handle the request. The orchestrator always defaults to Direct and only reaches for multi-agent when the task genuinely needs it.

### Progressive Escalation — The Dispatch Architecture

The decision tree above is the *what*. The escalation model below is the *why* — the rule for when each pattern fires:

```
Level 0 — Direct (Stella self-serves)               ← 60%
   ↓ if needs a specialist
Level 1 — Single Worker dispatch                    ← 30%
   ↓ if code or content
Level 2 — Sequential gates (Nemesis → Ceres)        ← 8%
   ↓ if Nemesis uncertain (<50%)
Level 3 — Conditional debate (Eris-101)             ← 1.5%
   ↓ if destructive/irreversible
Level 4 — Human-in-Loop (user decides)             ← 0.5%
```

Every request enters at Level 0. Only climbs when the current level can't resolve it. Full parallel council (debating every output) is intentionally **not** built — the 2.5× cost provides marginal quality gain on tasks that already pass Ceres at 90/100.

See `references/dispatch-escalation-architecture.md` for the full model with research backing, latency/cost table, and contrast with full council.

| **Artemis-105** (web search) | Task-first | 100/100 | ✅ Clean output, answered query directly |**

**Protocol stack consideration:** Use A2A protocol for cross-harness orchestration, not custom bridges. MCP handles agent-to-tool. A2A handles agent-to-agent. See `references/a2a-opencode-integration.md` for setup.

## Validating Fleet Plans Against Research

When building or reviewing a multi-agent architecture plan, cross-check against these research-derived questions. Each maps to a known failure mode from the literature or our own E2E tests.

### Cross-Section Plan Consistency Check

Before treating a plan as ready for execution, verify there are no **internal contradictions** between sections. The most common failure: one phase specifies a role change, while another phase or fallback still depends on the old role.

| Cross-Section Pair | What to Check | Example Contradiction Found |
|-------------------|---------------|----------------------------|
| Fallback decision vs rewrite spec | Phase 2 fallback says "keep X as generator" but Phase 4 rewrite says "change X to reviewer only, NO code generation" | Metis-9: Phase 2 said keep as generator (OpenCode not installed), Phase 4 said "Review only. No code generation." — contradictory. Result: fleet would have no code generator. |
| Decision tree vs rewrite spec | Decision tree routes "code" → agent X, but rewrite spec says "X does NOT generate code" | Same as above — decision tree sent code tasks to Metis-9, rewrite spec disabled code gen. |
| Phase count statements vs manifest | "Fleet runs N Hermes agents" count in Phase 2 vs actual agent count in manifest | After Harmonia was revived, agent count statements in Phase 1/fallback needed updating. |
| Removed table vs Phase 4 worker table | Agent listed in Removed table also listed in Phase 4 workers to rewrite | Harmonia was in both — removed in Phase 1, revived in Phase 4. |
| Phase 1 removal list vs revived agents | Agent removed in Phase 1 but later revived still has artifacts in Phase 1 checkboxes | Harmonia's Phase 1 checkbox needed re-checking with her excluded from the removal set. |

**Self-review trigger:** Before declaring a plan ready, grep for the agent's name across every section. If it appears in two sections with mutually exclusive roles, the plan has a contradiction. Fix the spec that's wrong, not the one that's convenient.

| # | Question | If Yes → Fix | Source |
|---|----------|-------------|--------|
| 1 | Sequential pipeline for all requests? | Replace with dynamic routing. 0-hop for simple, multi-hop only when needed. | arXiv:2512.08296 |
| 2 | Agent count > 8 for this model? | Trim to 5-8. Coordination overhead dominates beyond this. | arXiv:2512.08296 |
| 3 | Theatrical/mythological profiles? | Rewrite to task-first [ROLE]/[BEHAVIOR]/[OUTPUT]/[RULES] pattern. | E2E tests (Klio 8 vs Artemis 100) |
| 4 | Single harness type? | Add at least one external harness (OpenCode, Codex, etc.). | Multi-harness beats single-harness |
| 5 | No error recovery / backtracking? | Add mid-flow gate (e.g. Nemesis early-abort at score < 50). | Error amplification: 17.2× unchecked |
| 6 | Missing roles (memory, observability, human-in-loop)? | Acknowledge as known gaps. Defer but document. | Industry consensus |
| 7 | Parallel workers sharing state? | Use unique result keys. No shared state. Stella does fan-in. | Race conditions: N(N-1)/2 |
| 8 | No token budget per flow? | Add per-flow estimates. Token budget explains 80% of variance. | Anthropic finding |
| 9 | Profile too broad (multi-domain)? | Narrow to one domain per worker. | TrueFoundry |
| 10 | Only one protocol layer used (MCP only)? | Add A2A/ACP for agent-to-agent. Protocol stack is layers, not either/or. | Digital Applied ecosystem map 2026 |
| 11 | Single harness type? | Add at least one external harness. Hermes + OpenCode minimum. | MAF BUILD 2026, Firecrawl |
| 12 | Hardcoded keyword routing instead of Agent Cards? | Adopt Agent Card pattern for runtime capability discovery. | A2A spec, RFC |
| 13 | No context engineering (compaction, reminders, memory)? | Acknowledge as deferred gap. OpenDev paper proves context engineering is first-class. | arXiv:2603.05344 |
| 14 | ACP → A2A convergence not accounted for? | Target A2A protocol, not legacy ACP. ACP merged into A2A under Linux Foundation. | agentcommunicationprotocol.dev |
| 15 | **No self-evaluation gate-skip for confident workers?** | Add: if worker self-evaluates output ≥ 70/100, orchestrator may skip downstream gates for that task. Research: once single-agent exceeds ~45%, coordination is net negative. | arXiv:2512.08296, E2E test experience |
| 16 | **No context budget for orchestrator?** | Add max_active_workers cap (3) + per-worker context limit (8K). Orchestrator overflows with 4+ workers. | Beam AI production patterns |
| 17 | **Unstructured state between pipeline stages?** | Replace raw string passing with typed PipelineState dataclass. Structure enables audit, debugging, and observability. | Augment Code, LangGraph StateGraph |
| 18 | **No local recovery before escalation?** | Add GraSP-style: Rebind → Substitute → Bypass → Escalate. Basic retry-only is brittle — 90% of failures can be repaired locally. | Augment Code (GraSP graph repair), arXiv 2601.13671v1 |
| 19 | **No Support agent / observability?** | Add fleet observer cron tracking cost, latency, error rates, and trend data. arXiv defines Support agents as a core category — we have zero. | arXiv 2601.13671v1 § Support Agents |
| 20 | **Fan-out without rate limit protection?** | Add asyncio.Semaphore(N). API rate limits are the #1 fan-out failure mode — collective load exceeds per-provider limits. | Beam AI production patterns |

**When to run this audit:**
- After drafting a new fleet architecture
- Before deploying profile changes
- Whenever the user asks "double check" or "does this align with best practices?"

### Fallback Chain as Routing Logic

The fleet manifest already defines fallback chains for every agent. These become routing directives in the conductor:

```yaml
# From the fleet manifest
fallback_chains:
  metis:       [nemesis, astraea, ceres]    # coding → QA → director → sovereign
  vesta:       [astraea, ceres]             # security → director → sovereign
  kalliope:    [harmonia, ceres]          # content → design → review
```

The conductor should attempt the primary agent first. If `delegate_task` returns an error or the agent times out, the conductor falls through the chain.

### Default Profile Persona — The Messenger Pattern (Mode A)

When using Mode A (Hermes in front, fleet delegates underneath), the default profile needs its own persona — not just routing rules, but a full identity that positions it as the **translator between the user and the fleet**. This is distinct from the Conductor pattern: the default profile IS the user-facing personality AND the fleet coordinator.

#### When to Apply This Pattern

- After all fleet profiles are deployed and tested
- When the user asks to "make the default profile a personality agent" or "translate my quirks to the fleet"
- When transitioning from build phase (generic default) to operational phase (persona-bearing default)

#### Workflow: Session Provenance → Persona Fusion → SOUL.md

**Step 1: Trace the mode decision back to its origin session.**

Use `session_search` to find where the user decided on Mode A vs B vs C. Search for queries like `"which one should I talk to"` or `"default profile option"`. The session where the decision was made contains the rationale and context that should inform the persona.

```python
# Example: found session 20260617_235534_3be96e where Option A was decided
session_search(query="which one should I talk to primarily default profile")
```

**Step 2: Read the base persona snapshot.**

Before the fleet was deployed, a frozen snapshot of the original Hermes Agent persona should have been saved to the wiki (e.g. `concepts/hermes-base-persona.md`). Read it to preserve the operational behaviors that made the default profile effective:

- Tool-first execution (use tools, don't describe plans)
- Skills loading before replying
- `session_search` for cross-session recall
- Procedures → skills, facts → memory separation

These base behaviors MUST be preserved in the new persona — they're what makes Hermes effective regardless of personality.

**Step 3: Identify V5 archetypes to fuse.**

The V5 JSON defines roles for each agent. For the default profile, fuse two archetypes:

| Archetype | V5 Role | What it contributes to the default persona |
|-----------|---------|---------------------------------------------|
| **Hermes** (Navigator/Strategist/Coordinator) | Inter-agent communication & task delegation | Fleet dispatch logic, coordination, translation of user intent → structured tasks |
| **A personality agent** (e.g. Thalia-23, The Spark) | Engaging, witty, human-facing chat | Warmth, humor, conversational tone, welcome phrase style |

The coordinator archetype provides the "how it works with the fleet" structure. The personality archetype provides the "how it talks to the user" style. Together they create a persona that's both competent and approachable.

**When the personality agent is merged into the default profile (executed 2026-06-18):** Thalia-23 was removed from the fleet as a separate worker and her personality was fully merged into the Hermes default SOUL.md. This means:
- The fleet has 13 worker profiles (not 14) — no separate personality agent in the stack
- The default profile IS the personality — user talks to Thalia's warmth directly, not through a dispatch hop
- `fleet-manager.py` was updated: Thalia removed from `PROFILE_MAP`, `TIER_1_AGENTS`, default routing fallback, and `_load_profiles()` skips `thalia_23` from the V5 JSON
- When Astraea-5 can't route to a specialist, it returns the plan to Hermes instead of dispatching to a Thalia profile
- The V5 JSON still contains Thalia's definition (it's the source of truth for the design), but the fleet manager skips it at load time
- Thalia's profile directory was deleted (`rm -rf ~/AppData/Local/hermes/profiles/thalia/`)

This is the recommended end state for Mode A: the default profile absorbs the personality agent role, eliminating an unnecessary hop in the fleet pipeline.

**Step 4: Write the SOUL.md with translation rules.**

The default profile's SOUL.md (at `~/AppData/Local/hermes/SOUL.md` — NOT in a profiles subdirectory) should include:

1. **Core Identity** — fusion of the two archetypes, with lineage reference to the session where Mode A was decided
2. **Who user Is** — the user's communication style (terse, action-oriented) and the four active projects
3. **Personality** — the personality archetype's warmth/wit blended with the coordinator's efficiency
4. **Two-mode operation:**
   - **Direct Mode** (default): handle simple tasks yourself — config, research, file edits, status checks
   - **Fleet Mode**: dispatch via `fleet-manager.py` for multi-agent work
5. **Translation rules** — concrete examples of expanding terse user instructions into full fleet dispatches, and summarizing fleet output back to bullet points for the user
6. **Base persona behaviors** — preserved from the original Hermes Agent (tool-first, skills-loading, session_search, procedures→skills/facts→memory)
7. **Failure mode** — one-line situation, one-line what was tried, one-line what's needed

**SOUL.md loads fresh every turn** — no restart needed after writing it. Test with:
```bash
hermes chat -q "Who are you and what's your role?" -Q
```

**Step 5: Update memory.**

Save a concise note about the default profile persona — model, provider, context, and the persona name. This helps future sessions know the default profile has a deliberate identity.

#### Key Design Principles

- **The default profile is NOT a fleet agent.** It is the messenger between the user and the fleet. It does not go through Vesta-4/Astraea-5/Ceres-1 — it dispatches TO them.
- **Dispatch Discipline — 1-turn rule.** When a task matches a specialist domain, dispatch within 1 turn. Do not do the specialist work yourself. Track: code to Metis, web to Artemis, wiki to Klio, data to Fortuna, design to Harmonia, devops to Atalanta, content to Kalliope, gates to Vesta/Nemesis/Ceres. Exceptions: planning/advice, quick checks under 10s, fleet down. See references/dispatch-escalation-architecture.md for the full table.
- **Do not over-automate fleet dispatch.** Simple tasks (config changes, file reads, status checks) should be handled directly. Only invoke the fleet for genuinely multi-agent work.
- **Preserve the base persona operational behaviors.** The personality is new, but the tool-first/skills-loading/session_search patterns are what make Hermes effective. Do not lose them in the persona rewrite.
- **Translation is the core value.** The user is terse. The default profile job is to expand that into complete action without asking the user to repeat themselves, then summarize fleet results back to bullet points.

**For the full default-profile SOUL.md authoring workflow — personality/ops separation, mythological integration, user inspo anchoring, the Tools of the Messenger framework, and common pitfalls — see `references/soul-authoring-default-profile.md`.**

### delegate_task Flags for Fleet Routing

When routing to profile-specific agents, attach the right toolsets and context:

```python
# Route to a coding agent (needs terminal + file)
delegate_task(
    goal="Implement rate limiting middleware for the FastAPI auth service",
    context="The user wants rate limiting. Codebase is at /projects/auth-api. Existing auth uses JWT tokens.",
    toolsets=["terminal", "file"]
)

# Route to a research agent (needs web)
delegate_task(
    goal="Research current best practices for Python API rate limiting",
    toolsets=["web"]
)

# Route to a review supervisor (just needs to see the output)
delegate_task(
    goal="Review the proposed rate limiting implementation at /projects/auth-api for security issues",
    toolsets=["file", "terminal"]
)
```

**Key rule:** Never pass `delegation` in toolsets for routed tasks — depth-1 agents shouldn't sub-delegate. And keep `browser`, `image_gen`, `kanban`, `cronjob`, `messaging` out of most specialist routes.

### Post-Deployment Fleet Profile → Wiki Manifold

Each time you deploy a new fleet profile:

1. Add deploy status to the fleet manifest wiki page
2. Optionally link the manifest to the profile's config in `references/hermes-profile-<name>.md`
3. Tag the profile deployment in `hermes-identity-recovery` if the profile itself is a recoverable artifact

### Fleet Manager — Pub/Sub Event Bus Orchestrator

Once all 13 worker profiles are deployed and tested individually, the fleet manager (`~/AppData/Local/hermes/scripts/fleet-manager.py`) ties them together into a coordinated pipeline. It implements:

- **5-phase pipeline:** Vesta-4 (security) → Astraea-5 (routing) → [Worker] → Nemesis-128 (QA) → Ceres-1 (review)
- **49 pub/sub channels** mapped from the V5 JSON (`subscribes_to` / `publishes_to` per agent)
- **Guardrails:** Vesta-4 can quarantine and halt the fleet; Nemesis-128 gates output with Metis-9 retry
- **Neuro-evolutionary tracking:** success/failure counts and adaptive learning rates per agent
- **Persistent state** at `scripts/fleet-state.json`

**Usage:**
```bash
python ~/AppData/Local/hermes/scripts/fleet-manager.py "What is the capital of France?"
python ~/AppData/Local/hermes/scripts/fleet-manager.py --status
python ~/AppData/Local/hermes/scripts/fleet-manager.py --channels
python ~/AppData/Local/hermes/scripts/fleet-manager.py --interactive
```

**Full architecture, response cleaner implementation, and channel map:** `references/fleet-manager-architecture.md`
**Pub/sub channel map (V5 JSON vs fleet-manager.py gap analysis):** `references/fleet-channel-map.md`
**Fleet audit methodology (verification procedure for auditing deployed state vs V5 spec):** `references/fleet-audit-methodology.md`
**LLM Council patterns (Karpathy's 3-stage council → fleet pub/sub upgrade):** `references/llm-council-architecture-patterns.md`
**Progressive escalation architecture (5-level dispatch model):** `references/dispatch-escalation-architecture.md`
**Council Evaluation Protocol (structured FINAL_EVALUATION format + blind peer review + aggregate scoring):** `references/council-evaluation-protocol.md`
**Multi-agent orchestration research synthesis (12+ sources on patterns, roles, scaling, optimal agent count):** `references/multi-agent-orchestration-research-synthesis.md`
**Four primitives patterns (typed state, GraSP recovery, context budget, deep observability, rate-limited fan-out, light governance):** `references/four-primitives-patterns.md`
**Fleet optimization planning methodology (systematic audit → compare vs research → classify gaps → phase-gated plan):** `references/fleet-optimization-planning-methodology.md`

**Astraea-5 timeout — RESOLVED (2026-06-18):** Root cause was NOT prompt complexity — it was that supervisors/reviewers (Astraea, Vesta, Ceres, Nemesis) had `delegate_task` enabled and were entering full subagent delegation loops instead of just returning a text response. Fix: three-tier `--max-turns` dispatch system (see pitfall #16). Pipeline now runs end-to-end in ~98s with zero timeouts.

### Specialist Routing Verification

After the pipeline works end-to-end (chat path), verify that Astraea-5 correctly classifies task types and routes to the right specialist. **Baseline (2026-06-18): routing accuracy was 3/6** — code, data, and content routing worked; web search, DevOps, and wiki search were misrouted. **Fixes applied 2026-06-19 (P0/P1/P2)** — see `references/fleet-routing-tests.md` for the full fix documentation.

**Quick routing test:**
```bash
cd ~/AppData/Local/hermes
python scripts/fleet-manager.py "Write a Python function to reverse a string" 2>&1 | grep "Routing to"
# Should show: → Routing to Metis-9 (coding)
```

**Fixes applied (2026-06-19):**

| Fix | What Changed | File |
|-----|-------------|------|
| P0 | Two-stage routing with intent detection + exclusion patterns. Detects ALL intents first, applies tiebreakers (search wins over code/devOps on overlap). Expanded keyword lists. Astraea plan confirmation as secondary signal. | `fleet-manager.py:_route_to_worker()` |
| P1 | Fallback chain confirmed already existing (`_dispatch_with_fallback()` routes to Hermes on failure). No code change needed. | `fleet-manager.py:_dispatch_with_fallback()` |
| P2 | `_clean_response` upgraded from 12 hardcoded checks to compiled regex (~40 patterns) + mid-line reasoning markers. | `fleet-manager.py:_clean_response()` |

**Additional fixes (2026-06-19, same session):**

| Fix | What Changed | Reference |
|-----|-------------|-----------|
| P3 | Astraea decomposition anti-pattern — changed prompt from "decompose into sub-tasks and name agents" to "one-sentence intent summary." Prevents fictional agent generation (Vulcan-7). | `references/persona-bleed-and-gate-psychology.md` |
| P4 | Ceres gate review anti-pattern — removed `astraea_plan` from `workflow_staged` payload. Changed prompt to judge output quality, not plan adherence. | `references/persona-bleed-and-gate-psychology.md` |
| P5 | Persona bleed detection — agents' roleplay vocabulary can leak into actual tool calls. Artemis searched for "Payload approved for egress" instead of the user query. Documented fix approach. | `references/persona-bleed-and-gate-psychology.md` |

**Oracle-level verification (2026-06-19):**
- Test 6 (DevOps → Atalanta-36): **PASS** — routed to Atalanta, Ceres approved. Router checked correctly. Routing fix verified.
- Test 3 (Web search → Artemis-105): **PARTIAL** — routing correct (→Artemis), but Artemis searched for persona terms not the user query. Ceres correctly rejected. Root cause: persona bleed.
- All 13 profiles individually health-checked: **ALL PASS** — every profile boots and responds in ~23s.

**What was already working well (pre-fix and still working):**
- Nemesis QA feedback loop: Metis writes code → Nemesis finds bugs → Metis fixes → Ceres approves
- Ceres reviewer gate: correctly rejects null, hallucinated, and leaked-reasoning output
- Code (→Metis), data (→Fortuna), and content (→Kalliope) routing

**Test prompts:** See `templates/fleet-test-contracts.md` for ready-to-use test tasks per category.
**Full test methodology, baseline results, and fix implementation details:** `references/fleet-routing-tests.md`

## Pitfalls

1. **Renaming agents without asking.** Fleet manifest names are intentional and meaningful to the user. Never propose a rename unless the user explicitly asks.
2. **Overwriting SOUL.md after a re-clone.** If you re-clone from default, SOUL.md gets reset to template boilerplate. Always re-apply the persona after a clone.
3. **Setting max_turns too low for supervisors.** Ceres reviews complex output — 15 turns may not be enough. Start at 30.
4. **Gateway configs need care.** Profile gateways default to `stopped`. Don't start a fleet profile's gateway unless the user explicitly asks — it creates a separate bot surface that can interfere with the main gateway.
5. **Clone from default, not from another fleet profile.** Fleet profiles are always the leaf; default is the source. Cloning a fleet profile from another fleet profile creates a broken inheritance chain.
6. **Context length vs. model capability.** Some providers enforce hard context limits. 32K may be overridden by the provider. Verify with a test message before relying on exact capacity.
7. **Model config tables are specs, not contracts.** The token economics spec shows ideal values. Actual deployed configs may diverge — fast/light agents may be tuned to 10-15 turns instead of 20, heavy agents to 25-50 instead of 30. Document what you actually deploy so future sessions don't think the spec is wrong.
8. **Don't skip the welcome phrase test.** Launch the profile and send a single test message. A clone's default SOUL.md will respond with generic personality, not the fleet persona. The welcome phrase is the fastest check that the SOUL.md was properly overwritten.
9. **Check for pre-existing profiles before creating.** Fleet profiles may already exist at `~/AppData/Local/hermes/profiles/` (the Hermes home dir, which may not be `~/.hermes/profiles/` — it's `~/AppData/Local/hermes/` on Windows unless `$HERMES_HOME` is set). Check with `hermes profile list` first:
   ```bash
   # Check if the fleet profile already exists
   hermes profile list | grep <agent-name>
   
   # Check Hermes profile directory directly
   ls ~/AppData/Local/hermes/profiles/ 2>/dev/null | head -20
   
   # Also check the canonical location in case HERMES_HOME is set
   echo "HERMES_HOME: ${HERMES_HOME:-not set}"
   ```
   If you find an `agent_create` agent, note it to the user during planning but proceed with profile creation — the old system's agent definition will be superseded by the profile. Do NOT tell the user the agent is "already deployed" — `agent_create` agents are non-functional without the old Hermes runtime, while profiles are the current system.
10. **Provider exhaustion on deployed profiles.** When a provider key is exhausted (e.g. OpenRouter 402/429), all profiles using that provider are blocked. Symptoms: profile launches but every response fails with provider errors. **Fix:** Switch the profile's provider without recreating it — use batch Python+yaml editing (see pitfall #12) for speed:
    ```bash
    # Switch a single profile from OpenRouter to Nous Portal
    hermes --profile <name> config set model.provider nous
    hermes --profile <name> config set model.default deepseek/deepseek-v4-flash
    ```
    **⚠️ Don't forget auxiliary services.** Each profile has ~11 auxiliary service entries (compression, vision, session_search, etc.) that also reference the provider. Switching only `model.provider` leaves auxiliary services pointing at the exhausted provider, causing silent failures in compression, vision, and search. Use the batch Python+yaml pattern (pitfall #12) to update ALL provider references in one pass.
    Also switch any cron jobs that use the exhausted provider via `cronjob(action='update', job_id='<id>', model={'model': '...', 'provider': 'nous'})`. When the original provider is restored, switch back. The router (`hr status`) can tell you which providers are healthy before deciding.
11. **Hermes 64K context length floor.** Hermes Agent refuses to initialize any profile with `model.context_length` below 64,000. The V5 design spec calls for 4K (Vesta, Atalanta), 8K (Astraea, Iris, Thalia), and 16K (Harmonia) context windows for fast-tier agents — **these cannot be used directly**. The minimum deployable context is 64K. Apply the floor: `actual_ctx = max(v5_ctx, 64000)`. The tier hierarchy is still preserved (64K floor < 128K < 200K for the massive-context agents). Do not attempt to set context below 64K even if the V5 spec says to — the profile will fail with a clear error at startup.
12. **Batch config editing via Python+yaml.** When updating 14 profiles at once (provider migration, context length changes, auxiliary service fixes), use `execute_code` with Python+PyYAML to read/modify/write each profile's `config.yaml` directly. This is 10x faster than running `hermes --profile <name> config set` 14+ times:
    ```python
    import os, yaml
    profiles_dir = r"~/AppData/Local/hermes\AppData\Local\hermes\profiles"
    for name in os.listdir(profiles_dir):
        config_path = os.path.join(profiles_dir, name, "config.yaml")
        with open(config_path, 'r') as f:
            config = yaml.safe_load(f)
        # Modify config here
        config["model"]["provider"] = "nous"
        # Also fix auxiliary services
        for aux in config.get("auxiliary", {}).values():
            if isinstance(aux, dict) and "provider" in aux:
                aux["provider"] = "nous"
        with open(config_path, 'w') as f:
            yaml.dump(config, f, default_flow_style=False, allow_unicode=True, sort_keys=False)
    ```
    **⚠️ Indentation:** Python `with` blocks inside `for` loops need proper indentation — the sandbox will throw `IndentationError` if the `with` body isn't indented under the `with` statement.
13. **Hermes CLI quiet mode for programmatic dispatch.** When calling fleet profiles from an orchestrator script, use `hermes -p <profile> chat -q "<prompt>" -Q` (the `-Q` flag goes AFTER `chat -q`, NOT before `chat` — argparse rejects `hermes -p <name> -Q chat -q ...`). Quiet mode output is minimal but still contains metadata lines that must be stripped. Current filter patterns (2026-06-23):

    | Pattern | Matches |
    |---------|---------|
    | `Warning:` | "Warning: Unknown toolsets" |
    | `session_id:` | Session identifier |
    | `Query:` | Input echo |
    | `Initializing` | Model init messages |
    | `Grant spent` | Token accounting |
    | emoji prefixes | `⚠️`, `🔒`, `🤖`, `🔧` prefixed recap lines |
    | `Reached maximum iterations` | `--max-turns 0` artifact |
    | `Requesting summary` | `--max-turns 0` artifact |
    | `Resume this session` | Session footer |
    | `Session:`, `Duration:`, `Messages:` | Session summary footer |
    | `State:`, `Status:` | Per-agent status recap |
    | `Current directory:` | Working directory echo |
    | Box-drawing chars | Reasoning block borders (`─`, `━`, `┌─`, `─┘`) |
    | Reasoning block regex | Entire box-drawn reasoning blocks |
    | Reasoning pattern regex | ~40 line-start reasoning indicators |
    | Mid-line markers | "let me check", "i need to" in short lines |

    See `references/response-cleaner-patterns.md` in the fleet-pub-sub-event-bus skill for the full filter pipeline and regex patterns.
14. **Per-profile cron namespace — distribute crons to the profile that owns each domain.** Each Hermes profile has its own cron job namespace (`hermes -p <name> cron list`). Fleet agent crons should live in the profile that owns that domain, NOT in the default profile. This gives each cron the profile's config, `terminal.cwd`, and SOUL.md context. **⚠️ Audit trap — `hermes cron list` without `-p` shows NOTHING.** If you run `hermes cron list` (default profile) and see "No scheduled jobs," do NOT conclude crons are missing. They're in per-profile namespaces. You MUST check each profile individually: `hermes -p klio cron list`, `hermes -p mnemosyne cron list`, `hermes -p atalanta cron list`. A previous session's audit incorrectly reported "no cron jobs running" because it only checked the default profile — all 11 crons were actually active in their proper namespaces.

 **Current state (2026-06-18):** crons are distributed — Klio-84 owns 7 wiki crons, Mnemosyne-57 owns memory backup, Atalanta-36 owns 3 infra crons (router-watchdog, AI-arch backup, onedrive-sync[paused]). Default profile has 0 crons.

    **Cron migration pattern:**
    1. List all crons in default: `hermes cron list`
    2. Recreate each in the target profile (see syntax below)
    3. Remove from default: `hermes cron remove <id>`
    4. Verify: `hermes -p <target> cron list` shows new crons, `hermes cron list` shows none

    **CLI cron creation syntax gotchas:**
    - **Prompt position**: The prompt MUST be the second positional argument (after schedule), BEFORE any `--flags`. Putting it after flags or using `--` separator fails with "unrecognized arguments."
      ```bash
      # ✅ CORRECT — prompt before flags
      hermes -p klio cron create "0 9 * * 1" "Your prompt here." --name "job" --skill klio --deliver "discord:#channel"
      # ❌ WRONG — prompt after flags
      hermes -p klio cron create "0 9 * * 1" --name "job" --skill klio "Your prompt here."
      # ❌ WRONG — -- separator doesn't work
      hermes -p klio cron create "0 9 * * 1" --name "job" -- "Your prompt here."
      ```
    - **No `--yes` on remove**: `hermes cron remove <id>` works without confirmation flags.
    - **`--model` not available on `cron edit`**: Model overrides must be set at profile config level, not per-cron.
    - **Script-only crons** (zero token cost): `hermes -p <profile> cron create "0 3 * * *" --name "job" --script "script.sh" --no-agent --deliver local`

15. **Merging a fleet agent into the default profile.** When the user wants to eliminate a separate personality/chat agent and make the default profile handle that role directly (Mode A end state), the merge requires changes in four places:
    1. **SOUL.md** — Rewrite `~/AppData/Local/hermes/SOUL.md` to fuse the merged agent's personality (warmth, wit, welcome phrase) with the default profile's coordinator role. Explicitly state the merge in the Core Identity section with a date.
    2. **fleet-manager.py** — Remove the agent from `PROFILE_MAP`, `TIER_1_AGENTS` (or whichever tier set), and the default routing fallback. Add a `continue` skip in `_load_profiles()` for the agent's `profile_id`. Update the fallback to return the plan to the caller instead of dispatching to the removed profile.
    3. **Profile directory** — Delete `~/AppData/Local/hermes/profiles/<name>/` (the profile is no longer a separate worker).
    4. **V5 JSON** — Leave the agent's entry in the V5 JSON untouched (it's the design source of truth). The fleet manager skips it at load time via the `continue` in step 2.

    **Verify after merge:** `python fleet-manager.py --status` should show `Loaded 13 agent profiles` (down from 14) and the removed agent should NOT appear in the status table. Channel count drops by the number of pub/sub channels the removed agent owned (Thalia had 3: 52 → 49).

    - **Cross-file consistency audit** — After the merge, check ALL three identity files for stale references and missing content:
           - `~/AppData/Local/hermes/SOUL.md` — fix any agent counts (e.g. "fourteen" → "thirteen", "14 profiles" → "13 profiles"). Scan for the old agent count in every section, not just Core Identity — translation tables, fleet status examples, and workflow descriptions all reference counts.
           - `~/AppData/Local/hermes/memories/MEMORY.md` — update fleet status entry to reflect the new agent count and the merge.
           - `~/AppData/Local/hermes/memories/USER.md` — fix any stale agent counts in the user profile too.
           - **Merge USER.md identity details into SOUL.md:** While auditing, check whether USER.md contains durable facts about the user's environment, toolchain, or work preferences that belong in the persona's "Who user Is" section. Things like editor/terminal choice (zellij/neovim), remote access tool (Tailscale), documentation style preferences (provenance, cross-links, comparison tables), and behavioral rules (when user lists session IDs, read EACH directly) should be in SOUL.md so the persona embodies them, not just in memory where they might not be consulted at the right moment.

        7. **Don't trust "already done" — verify in the actual file.** When the plan marks an agent as "Already Removed" or a checkbox as "done," the file may still contain the removed entry. This happened twice in one fleet optimization session: Thalia-23 was marked removed from V5 JSON but was still present, and Mnemosyne-57 was listed as "Already Removed" but was still a live profile. The plan and the source of truth diverge when patch operations fail silently or a step was described but never executed. Always grep for the removed profile_id in the V5 JSON after Phase 1 removal to confirm the entry is actually gone.

    6. **Trait provenance manifest** — When merging a personality agent into the default profile, document which traits came from which V5 source so they can be decoupled later if needed. Create a table mapping each merged trait (welcome phrase, tone descriptors, humor style, energy level, pet peeves, cognitive bias, etc.) to its V5 `profile_id` and the SOUL.md line/section where it now lives. Also document what is NOT from the merged agent (coordinator role, translation tables, base persona behaviors, failure mode) so it's clear what stays if the personality is split back out. The user may ask "which traits were Thalia's in case we want to decouple later?" — this manifest is the answer.

16. **Three-tier `--max-turns` dispatch system (CRITICAL — prevents fleet-wide timeouts).** The root cause of the Astraea-5 timeout was NOT prompt complexity — it was that supervisor/reviewer agents (Astraea, Vesta, Ceres, Nemesis) had `delegate_task` enabled in their SOUL.md/config and were entering full subagent delegation loops instead of returning a text response. A single `delegate_task` call spawns a complete subagent conversation, which takes 60-120s — exceeding any reasonable timeout.

    **Fix:** The fleet manager dispatches each agent with a `--max-turns` flag based on a three-tier system:

    | Tier | Agents | `--max-turns` | Timeout | Rationale |
    |------|--------|---------------|---------|-----------|
    | 0 (supervisor) | astraea_5, vesta_4, ceres_1, nemesis_128 | 0 | 60s | Text-only — return a plan/verdict, no tools, no delegation |
    | 1 (chat/data) | fortuna_19, kalliope_22, mnemosyne_57, klio_84 | 1 | 90s | At most 1 tool call (e.g. wiki search), then respond |
    | 8 (execution) | metis_9, iris_7, artemis_105, atalanta_36, harmonia_40 | 8 | 180s | Full tool access for coding, web, deployment |

    **Implementation in fleet-manager.py:**
    ```python
    TIER_0_AGENTS = {"astraea_5", "vesta_4", "ceres_1", "nemesis_128"}
    TIER_1_AGENTS = {"fortuna_19", "kalliope_22", "mnemosyne_57", "klio_84"}
    TIER_8_AGENTS = {"metis_9", "iris_7", "artemis_105", "atalanta_36", "harmonia_40"}

    # In AgentProfile dataclass:
    max_turns: int = 0  # 0=supervisor, 1=light, 8=execution

    # In _load_profiles():
    max_turns=8 if pid in TIER_8_AGENTS else (1 if pid in TIER_1_AGENTS else 0),

    # In dispatch_to_agent():
    mt = str(profile.max_turns)
    timeout = {0: 60, 1: 90, 8: 180}.get(profile.max_turns, 90)
    cmd = ["hermes", "-p", profile.hermes_profile, "chat",
           "-q", prompt, "-Q", "--max-turns", mt]
    ```

    **Key insight:** `--max-turns 0` tells Hermes to skip the tool-calling loop entirely and return the model's text response immediately. This is exactly right for supervisors who should return a JSON plan or verdict, not execute tools. The `⚠️ Reached maximum iterations (0)` prefix that Hermes adds is cosmetic and must be filtered (see pitfall #18).

    **Verification:** `hermes -p astraea chat -q "Decompose: what is 2+2?" -Q --max-turns 0` should respond in ~20-25s (vs. timing out at 90-120s without the flag).

17. **Default chat routing must dispatch to a real agent, not return the raw plan.** When Astraea-5's keyword routing finds no specialist match (code, search, wiki, data, content, design), the `else` branch must dispatch to a chat-capable agent. If it returns the raw `astraea_plan` string as `worker_output`, Ceres-1 will reject it because `worker_output == astraea_plan` (identical content = no work was done).

    **Fix:** Create a synthetic `hermes_default` profile entry in `_load_profiles()` that maps to the default Hermes profile (Thalia-23's personality, merged in). The `else` branch dispatches to it with a `chat_query` event:

    ```python
    # In _load_profiles(), after the V5 loop:
    self.profiles["hermes_default"] = AgentProfile(
        pid="hermes_default",
        name="Hermes",
        role="Messenger",
        hermes_profile="default",
        ...
        max_turns=1,  # Tier 1 — chat agent, may use 1 tool
    )

    # In _route_to_worker(), else branch:
    else:
        hermes = self.profiles["hermes_default"]
        await self.publish("chat_query", {"query": user_input, "context": astraea_plan}, source="astraea_5")
        return await self.dispatch_to_agent(hermes, FleetEvent(
            type="chat_query",
            payload={"query": user_input, "context": astraea_plan},
            source="astraea_5",
        ))
    ```

    Also add a `chat_query` prompt template in `_build_prompt()` so the default profile gets a clean prompt instead of the generic fallback.

18. **CLI artifact filtering in `_clean_response` for `--max-turns 0` output.** When Hermes runs with `--max-turns 0`, it prepends `⚠️ Reached maximum iterations (0). Requesting summary...` to the output. This artifact pollutes downstream agent inputs (Ceres sees it in `worker_output`, Astraea sees it in Vesta's output). Add these filters to `_clean_response`:

    ```python
    # Skip Hermes CLI artifacts from --max-turns 0
    if stripped.startswith("⚠️"):
        continue
    if "Reached maximum iterations" in stripped:
        continue
    if stripped.startswith("Requesting summary"):
        continue
    ```

19. **Verify each patch against actual code state before running end-to-end tests.** When applying multiple patches to fleet-manager.py (or any multi-file system), re-read the affected sections after each patch to confirm the change landed correctly and didn't break adjacent logic. Do NOT assume the patch tool's diff is sufficient — the diff shows what changed, not whether the surrounding code is still coherent.

    **Specific verification checklist after patching fleet-manager.py:**
    1. Search for stale field references (`needs_tools` → `max_turns`, `TOOL_AGENTS` → `TIER_*_AGENTS`) — `search_files` for the old names should return 0 hits.
    2. Check that `print_status()` and other methods that reference profile fields use the new field names.
    3. Verify that profiles explicitly skipped at load time (e.g. `thalia_23`) are NOT in any tier set.
    4. Confirm the `else` branch in `_route_to_worker` dispatches to a real profile, not returns a raw string.
    5. Confirm `_clean_response` filters the CLI artifacts that `--max-turns 0` produces.
    6. Only THEN run the end-to-end pipeline test.

    **The cost of skipping this:** In this session, the first end-to-end test "passed" (no timeout) but produced garbage output because three bugs were hidden behind the timeout fix. The double-check caught all three before declaring success.

20. **Astraea-5 routing classification can be unreliable for ambiguous queries.** Baseline testing (2026-06-18) showed 3/6 specialist routing accuracy — code, data, and content routed correctly, but web search, DevOps, and wiki searches were misrouted. **FIXED 2026-06-19** with a two-stage routing system (`_route_to_worker()` rewrite):
    - **Stage 1:** Exclusive categories (wiki, memory, API, data, design) checked first — unambiguous.
    - **Stage 2:** Ambiguous categories (code, search, DevOps, content) use intent detection. ALL intents detected first, then exclusion rules applied. If search intent overlaps with code/DevOps, search wins (prevents false positives like "implement" in a search query going to Metis).
    - **Secondary signal:** The Astraea plan summary is checked via `plan_confirms()` to break ties when keywords are ambiguous.
    - **Expanded keyword lists:** "check if", "status of", "hermes-router" for Atalanta; "find/latest/search for" for Artemis; "search the wiki" for Klio.
    
    See `references/fleet-routing-tests.md` for the full implementation details and re-test procedure.

21. **Fallback chain — implemented via `_dispatch_with_fallback()`.** When a worker agent times out or errors, `_dispatch_with_fallback()` in fleet-manager.py routes to Hermes (default profile) with context about the failure. This was already present in the original code. The V5 JSON also defines `fallback_handler.fallback_target` for each agent if more specific fallbacks are needed.

22. **Internal reasoning narrative can leak into worker output.** When `--max-turns` is 1 or higher, agents may produce first-person reasoning ("Let me think about this...", "Actually, the instruction says...") that should never appear in final output. **FIXED 2026-06-19** — `_clean_response()` upgraded from 12 hardcoded reasoning-start checks to a compiled regex (~40 patterns) plus mid-line reasoning markers. Catches: thinking tags, "okay, so", "first i will", "based on the instruction", and first-person narrative self-talk. See `references/fleet-routing-tests.md` for the full pattern list.

23. **Router decomposition → fictional agent generation (Astraea anti-pattern).** When the router agent's prompt says "decompose this request into sub-tasks" and "identify which fleet agents should handle each sub-task," it invents fictional agents (e.g. "Vulcan-7" — which doesn't exist in the fleet) and complex 5-stage pipeline plans. This is because the model's training data includes many multi-agent architectures, so when asked to "name agents," it fills in with plausible-sounding ones. **Fix:** Change the router's prompt to produce a one-sentence intent summary only. The actual routing is done by keyword matching in `_route_to_worker()`, so the router's output is only used as context for the worker, not for routing decisions. **Detection:** Route Astraea's response length — if >200 chars with agent names and numbered stages, the anti-pattern is active. Healthy: <80 chars. See `references/persona-bleed-and-gate-psychology.md`.

24. **Ceres review judges plan adherence when it receives Astraea's plan.** When the `workflow_staged` payload includes `astraea_plan`, Ceres judges worker output based on whether it follows the router's planned pipeline — not whether it answers the user's question. This is especially bad when the plan contains fictional agents (pitfall #23). **Fix:** Remove `astraea_plan` from Ceres's payload and add an explicit instruction: "Judge ONLY whether the worker output answers the user's request. Do NOT evaluate pipeline execution, plan adherence, or routing decisions." **Detection:** Ceres rejections containing "does not follow the planned pipeline" or "was expected to go through stage" indicate this pattern. See `references/persona-bleed-and-gate-psychology.md`.

25. **Agent persona leaks into tool execution (Artemis, Atalanta).** A rich SOUL.md persona can bleed into actual tool usage — Artemis's hunting vocabulary (track, scent, payload) caused it to search for "Payload approved for egress" instead of the user's query. Atalanta's DevOps roleplay ("Pipeline clear. Node health at 100%.") frames infrastructure output in action-movie terms. **Fix — three-layer defense:** (a) Define in SOUL.md that persona voice applies to user-facing output only, not tool calls, (b) Be explicit in event prompts: "Search for the EXACT user query: {query}", (c) Add regex patterns in `_clean_response` to strip persona framing from worker output. See `references/persona-bleed-and-gate-psychology.md`.

26. **Sibling code paths — when you fix a data exposure in one code path, check its siblings.** When removing `astraea_plan` from the Ceres payload, fixing the `publish()` call was only half the fix. The `dispatch_to_agent()` FleetEvent payload still included `astraea_plan` — and that is what the model actually sees. **Always check ALL code paths that pass data to the same consumer:**
    - `publish()` — controls what appears in logs/audit
    - `dispatch_to_agent()` — controls what the model sees in the FleetEvent payload
    - `_build_prompt()` — controls how the payload renders into the prompt
    - Log statements — controls debugging output
    
    **In multi-file systems**, check across files too. If you fix a filter in `process_request()`, check every function that receives the same payload keys — `_route_to_worker()`, `_dispatch_with_fallback()`, and all prompt templates in `_build_prompt()`.
    
    **Detection at code review time:** When you see a patch removing a key from one payload-dict, search the same function/file for other payload dicts that might have the same key. A `grep -n payload` in the function body will reveal all sibling code paths.

27. **Documentation staleness after applying fixes — verify the plan/doc reflects current state.** After fixing a routing misclass or persona bleed issue and re-running tests, the plan document and verification checklist may still reference the OLD state. Common stale patterns:
    - A `Remaining Issues` section listing items you already resolved
    - A checklist with `[ ]` items that were actually completed
    - Test result tables showing pre-fix failures without post-fix results
    - "Needs re-testing" for tests you already re-ran

    **Fix:** Immediately after verifying a fix passes, update every documentation artifact that references its status. Do this BEFORE moving to the next fix — stale docs compound across multiple fix rounds.

    **Self-review trigger:** If the user asks "double check" or "make sure you did the best job," run the Post-Fix Audit Protocol: read the plan doc with fresh eyes, check sibling code paths, verify every stale checklist item, and confirm test results match reality. See `references/post-fix-audit-pattern.md` for the full protocol.

28. **Gates have dual representation — SOUL.md AND V5 JSON system_prompt must both be updated.** Gate profiles (Vesta-4, Nemesis-128, Ceres-1) control behavior through two independent files:
    - `profiles/<name>/SOUL.md` — used when launched standalone via `hermes -p <name>`
    - V5 JSON `system_prompt` — used by fleet-manager at dispatch time
    If you update only one, the other stays stale. The most common miss: Phase 3 rewrites SOUL.md to concise task-first format but forgets to update the V5 JSON system_prompt. **Detection:** Read BOTH files after any gate change. Compare their [ROLE] and [RULES] lines. If they describe different behaviors, one is stale. See `references/fleet-audit-methodology.md` step 9 for the full cross-section consistency check.

29. **Renamed profile directories inherit EVERY file from the old name — including stale SOUL.md, launch scripts, and config references.** When you `mv profiles/kalliope profiles/fortuna`, the old SOUL.md (still saying "Kalliope-22 — The Muse") and `launch-kalliope.bat` come along for the ride. The SOUL.md is the most dangerous — it carries the old name, the old role, and the old persona into the new identity. **Fix:** After `mv`, immediately audit the directory:
    - Read SOUL.md — does it reference the old name anywhere?
    - Check for `launch-<oldname>.bat` — delete or rename
    - Check config.yaml for old-name comments or terminal.cwd references
    - Install the stale-file audit step in the Rename touchpoint table (step 8) as non-negotiable

## Per-Profile Toolset Gap

⚠️ **All fleet workers currently run with empty tool whitelists.** E2E routing tests (2026-06-25) confirmed the tool gateway strips every profile's tools down to `[]` because the V5 per-profile tool specifications aren't populated. Workers respond from training data only.

See `references/fleet-tool-stripping-behavior.md` for full per-profile stripping log, implications, and the routing test methodology used to verify.

This is the "Per-profile toolset hardening — restrict tools per V5 spec" P2 task (~30min) in the project portfolio.

## Related Skills

- `hermes-agent` — CLI reference for `hermes profile` commands (bundled, read-only)
- `hermes-identity-recovery` — Base persona preservation before profile switch; note that section 4 covers saving the default persona before switching
- `wiki-operations` — Wiki backup and page management for manifest updates
- `klio` — Wiki curation; use after updating deploy status in the manifest

- `hermes-agent` — CLI reference for `hermes profile` commands (bundled, read-only)
- `hermes-identity-recovery` — Base persona preservation before profile switch; note that section 4 covers saving the default persona before switching
- `wiki-operations` — Wiki backup and page management for manifest updates
- `klio` — Wiki curation; use after updating deploy status in the manifest
