# Agent Removal Workflow — Fleet Lifecycle Management

> Reverse of deployment. Removing a fleet agent requires updates in every location that references it.

## When to Remove a Fleet Agent

| Signal | Example | Action |
|--------|---------|--------|
| Domain covered by Stella | Fortuna-19 (data), Iris-7 (API), Atalanta-36 (DevOps) | Remove entirely |
| Never fired in E2E tests | Harmonia-40 (design) | Remove — no usage justifies the overhead |
| Redundant with built-in | Mnemosyne-57 (memory → Hermes session_search + memory tools) | Remove |
| Merged into default profile | Thalia-23 → Stella | Remove profile, keep in V5 JSON as reference |
| Replaced by external harness | Metis-9 (code gen → OpenCode) | Keep in fleet, change role (generator → reviewer) |

## Removal Procedure (5 Touchpoints)

### 1. V5 JSON — Remove Profile Entry

The source of truth at `~/Vault/wiki/raw/hermes_agent_profiles_v5.json`.

**Method:** Use `patch` tool with the full profile object as `old_string` and empty `new_string`.

**⚠️ Pitfall — Stray `{` after removal:** The `patch` tool may leave a trailing `{` from the removed entry's opening brace if whitespace doesn't match exactly. After each removal:
1. **Verify lint passes** — if JSON lint fails, `read_file` around the removal site to check for stray characters
2. **Fix any strays** with a second `patch` — e.g. `old_string: "        {\n        {", new_string: "        {"`
3. **Don't batch removals** in one patch — remove one entry at a time and verify after each

**Agents to keep (9 Hermes fleet agents):**

| # | Agent | Role | Profile ID |
|---|-------|------|-----------|
| 1 | Stella | Orchestrator (default) | `hermes_default` (built-in, not in V5 list) |
| 2 | Astraea-5 | Task decomposer | `astraea_5` |
| 3 | Metis-9 | Code reviewer | `metis_9` |
| 4 | Artemis-105 | Web search | `artemis_105` |
| 5 | Fortuna-19 | Data analysis | `fortuna_19` |
| 6 | Klio-84 | Wiki librarian | `klio_84` |
| 7 | Vesta-4 | Security gate | `vesta_4` |
| 8 | Nemesis-128 | QA gate | `nemesis_128` |
| 9 | Ceres-1 | Final reviewer | `ceres_1` |

### 2. fleet-manager.py — Remove from 5 Structures

The dispatch orchestrator at `~/AppData/Local/hermes/scripts/fleet-manager.py`.

| Structure | What to Remove | Example |
|-----------|---------------|---------|
| `PROFILE_MAP` | The entry mapping `profile_id` to profile name | `"fortuna_19": "fortuna",` |
| `PEER_REVIEW_MAP` | Any entry referencing the dead agent as reviewer OR reviewee | `"metis_9": "iris_7"` → replace with new partner |
| `TIER_0_AGENTS`, `TIER_1_AGENTS`, `TIER_8_AGENTS` | The agent's profile_id from its tier set | `"mnemosyne_57"` from `TIER_1_AGENTS` |
| `_route_to_worker()` | The routing block that dispatches to this agent | Entire `if` block from `# 2. Memory → Mnemosyne-57` through the `_dispatch_with_fallback()` call |
| `_route_to_worker()` comments and tiebreakers | Update numbering, comments, and exclusion patterns | Remove `is_devops` detection, `devops_has_search` tiebreaker, `plan_says_devops` |

**Rewiring peer review:** When removing an agent that was a partner in `PEER_REVIEW_MAP`, assign its reviewers to remaining agents:

| Original Pair | New Pair |
|--------------|---------|
| `metis_9: iris_7` | `metis_9: nemesis_128` (code → QA) |
| `artemis_105: fortuna_19` | `artemis_105: klio_84` (search → wiki fact-check) |
| `fortuna_19: mnemosyne_57` | Remove entirely (both removed) |
| `harmonia_40: atalanta_36` | Remove entirely (both removed) |
| `atalanta_36: iris_7` | Remove entirely (both removed) |

**Verification after edits:**
```bash
cd ~/AppData/Local/hermes/scripts
search_files(pattern="fortuna_19|iris_7|atalanta_36|harmonia_40|mnemosyne_57", path="fleet-manager.py", output_mode="count")
# Result must be: total_count: 0
```

### 3. Profile Directories — Delete

The physical Hermes profile at `~/AppData/Local/hermes/profiles/<name>/`.

```bash
rm -rf ~/AppData/Local/hermes/profiles/<name>/
```

**Verify:**
```bash
ls ~/AppData/Local/hermes/profiles/
# Should show only remaining profiles
```

### 4. Wiki — Archive Identity (User Preference)

**Before deleting any data source, preserve the identity.** user's explicit preference: "backup iris_7's personality to an .md before getting to her."

Create an entity page at `~/Vault/wiki/entities/<name>.md` with:

```
---
title: <Name> — <Nickname> (Archived Profile)
id: <name>
type: entity
schema_version: v1
created: <original creation date>
updated: <archive date>
status: archived
tags: [fleet, archived, identity-reference]
superseded_by: <replacement or 7-iris>
sources:
  - file: raw/hermes_agent_profiles_v5.json.bak
    span: {start: <line>, end: <line>}
    extracted_at: <date>
    extractor: 7-iris
---

# <Name> — <Nickname> (Archived)

> Archived during Fleet v2 Phase 1 (<date>). Reason for removal.

## Identity

One-sentence description of the agent's role.

## System Prompt

> Verbatim system prompt from V5 JSON

## Personality

| Trait | Value |
|-------|-------|
| Core motivation | ... |
| Quirk | ... |
| Pet peeve | ... |
| Dialogue example | ... |

## Why Removed

Clear reason — domain covered by Stella, false-positive routing, redundant with built-in, etc.

## Evolution

What carried forward from this agent into its replacement.
```

### 5. Verify

```bash
cd ~/AppData/Local/hermes/scripts && python fleet-manager.py --status
```

Expected: `Loaded 9 agent profiles` (14 - 5 removed = 9). The status table should show exactly the 9 surviving agents. No dead agents should appear.

## Agents Removed in Phase 1 (2026-06-23)

| Agent | Profile ID | Why | Touchpoints |
|-------|-----------|-----|-------------|
| Fortuna-19 | `fortuna_19` | Data analysis covered by Stella | V5, fleet-manager.py ×5, profile dir, wiki entity |
| Iris-7 | `iris_7` | Web/API domain absorbed by Stella | V5, fleet-manager.py ×5, profile dir, wiki entity |
| Harmonia-40 | `harmonia_40` | Design — never fired in E2E tests | V5, fleet-manager.py ×5, profile dir |
| Atalanta-36 | `atalanta_36` | DevOps covered by Stella + terminal tools | V5, fleet-manager.py ×5, profile dir |
| Mnemosyne-57 | `mnemosyne_57` | Memory redundant (Hermes built-in session_search + memory tools) | V5, fleet-manager.py ×5, profile dir |

## Rollback

If a removal causes issues, restore from the V5 JSON backup:

```bash
cp ~/Vault/wiki/raw/hermes_agent_profiles_v5.json.bak ~/Vault/wiki/raw/hermes_agent_profiles_v5.json
```

Then re-add the agent to fleet-manager.py and recreate its profile directory. The wiki entity page preserves the full personality for SOUL.md reconstruction.
