# Fleet Audit Methodology

> Repeatable verification procedure for auditing the deployed fleet against design specs.

## When to Use

- After fleet changes (profile updates, cron migrations, model switches)
- When the fleet implementation plan needs updating
- When a previous audit's conclusions seem wrong
- Before declaring a fleet phase "complete"

## Audit Steps

### 1. Verify Profile Count and Names

```bash
hermes profile list
# Should show: default + 13 worker profiles (no thalia — merged into default)
ls ~/AppData/Local/hermes/profiles/
```

### 2. Verify Per-Profile Model and Context

```bash
cd ~/AppData/Local/hermes
for d in profiles/*/; do
  name=$(basename "$d")
  model=$(grep "^  default:" "$d/config.yaml" 2>/dev/null | head -1 | sed 's/.*: //')
  ctx=$(grep "context_length" "$d/config.yaml" 2>/dev/null | head -1 | sed 's/.*: //')
  echo "$name: model=$model ctx=$ctx"
done
```

Compare against V5 JSON tiers:
- Heavy/Reasoning/Analytical/Generative → `deepseek/deepseek-v4-flash`
- Fast/Execution/Routing/Design/Ops → `google/gemini-2.5-flash`
- Massive Context → `google/gemini-2.5-flash` with 128K-200K

### 3. Verify Per-Profile Crons (DO NOT skip the -p flag)

```bash
# ❌ WRONG — only shows default profile, will show "No scheduled jobs"
hermes cron list

# ✅ CORRECT — check each profile that should own crons
hermes -p klio cron list
hermes -p mnemosyne cron list
hermes -p atalanta cron list
```

Expected: Klio=7, Mnemosyne=1, Atalanta=3 (one paused), default=0.

### 4. Check Fleet Runtime State

```bash
python ~/AppData/Local/hermes/scripts/fleet-manager.py --status
cat ~/AppData/Local/hermes/scripts/fleet-state.json
```

Verify: request count, event count, quarantine count, per-agent success/fail tallies.

### 5. Check V5 JSON Source of Truth

```python
import json, os
p = os.path.expanduser('~/Vault/wiki/raw/hermes_agent_profiles_v5.json')
with open(p) as f:
    d = json.load(f)
agents = d if isinstance(d, list) else d.get('agents', d.get('profiles', []))
for a in agents:
    name = a.get('agent_name', a.get('profile_id', '?'))
    role = a.get('role', '?')
    gc = a.get('generation_config', {})
    tier = gc.get('tier', gc.get('model_tier', '?'))
    print(f"{name:25s} role={str(role):20s} tier={tier}")
```

### 6. Test the Pipeline End-to-End (Chat Path)

```bash
cd ~/AppData/Local/hermes
python scripts/fleet-manager.py "What is the capital of France?" 2>&1
# Expected: Vesta → Astraea → Hermes(default) → Ceres, ~90-100s, clean output
```

### 7. Test Specialist Routing (6 Paths)

The chat path only verifies Vesta → Astraea → Hermes → Ceres. Specialist routing tests verify that Astraea correctly classifies task types and dispatches to the right worker. **As of 2026-06-18, routing accuracy is 3/6** — see `references/fleet-routing-tests.md` for the full methodology, baseline results, and known routing gaps.

Quick routing check — verify the log shows the correct agent:
```bash
cd ~/AppData/Local/hermes

# Code → should route to Metis-9
python scripts/fleet-manager.py "Write a Python function to reverse a string" 2>&1 | grep "Routing to"

# Content → should route to Kalliope-22
python scripts/fleet-manager.py "Write a short blog intro about AI" 2>&1 | grep "Routing to"

# Data → should route to Fortuna-19
python scripts/fleet-manager.py "Analyze this data and give me statistics" 2>&1 | grep "Routing to"
```

**Known misrouting (must fix before production):**
- Web search ("find news") → routes to Metis (WRONG, should be Artemis) — Metis times out
- DevOps ("check service") → routes to Hermes/default (WRONG, should be Atalanta)
- Wiki search ("search the wiki") → routes to Artemis (WRONG, should be Klio)

Full test suite and fix priorities: `references/fleet-routing-tests.md`

### 8. Document Discrepancies

Any mismatch between V5 spec and deployed state should be:
1. Noted in the fleet implementation plan (`~/.hermes/plans/fleet-implementation-plan.md`)
2. Fixed if it's a bug, or documented if it's an intentional deviation
3. Reflected in the skill's deployed configs table

### 9. Cross-Section Consistency Audit (SOUL.md ↔ V5 JSON)

After any deployment or rename, verify that all agents have consistent representations:

```bash
# Check each profile's SOUL.md matches its V5 JSON system_prompt
for profile_dir in ~/AppData/Local/hermes/profiles/*/; do
  name=$(basename "$profile_dir")
  soul=$(grep "^\[ROLE\]" "$profile_dir/SOUL.md" 2>/dev/null)
  echo "$name SOUL.md: $soul"
done
```

Then check the V5 JSON for the same agents — their `system_prompt` should have matching [ROLE] lines.

**What to look for:**
- **Gates are the most common drift point** — they have dual representation (SOUL.md for standalone, V5 JSON system_prompt for fleet-manager). If you update one but not the other, the fleet-manager still uses the old prompt.
- **Renamed profiles** — the directory inherits ALL old files. The SOUL.md still says the old name/role. The launch script still says the old name.
- **Dead agent references** — surviving profiles may reference a removed profile_id in `synergistic_partner` or `fallback_target`. These point to nothing.

**Real example (2026-06-23):**
| Audit Finding | Severity | Root Cause |
|---------------|----------|------------|
| Fortuna SOUL.md still said "Kalliope-22 — The Muse" | 🔴 High | Renamed directory inherited old SOUL.md |
| Gate V5 JSON prompts still theatrical | 🔴 High | Phase 3 only updated SOUL.md, not V5 JSON |
| launch-kalliope.bat in fortuna/ dir | 🟡 Low | Rename moved every file, not just the directory |

### 10. Pre-Declaration Multi-Dimension Audit (Before Marking Any Phase Complete)

Before declaring a phase "done," run a cross-section audit across 5 independent dimensions. Each dimension catches a different class of defect — the gaps between them are where real bugs live.

**Dimension 1 — Profile Config (SOUL.md ↔ V5 JSON)**
Check that every agent's SOUL.md in `profiles/<name>/SOUL.md` has a matching `system_prompt` in the V5 JSON. They describe the same role, same rules, same behavior. Common miss: gates updated in SOUL.md but not in V5 JSON (which is what fleet-manager uses at dispatch time).

**Dimension 2 — Code/Config Edge Cases (fleet-manager.py + V5 JSON)**
Check for:
- Stale field references (deleted profile_ids in tier sets, routing blocks, peer review maps)
- Keyword classifier false positives (e.g. `"hi" ∈ "this"` — short keywords need `text.split()`)
- Dead agent references in surviving profiles' `synergistic_partner`, `fallback_target`, `evolutionary_path`
- Missing `else` branch in routing (unclassified tasks must fall through to a real dispatch, not return a raw string)

**Dimension 3 — Filesystem Artifacts (profile directories)**
After any rename, check the renamed directory for:
- SOUL.md with old name/role
- Launch scripts with old name (`launch-<oldname>.bat`)
- Config.yaml comments referencing old name
- Any `.bat`, `.sh`, `.ps1`, or `.desktop` file with the old name

**Dimension 4 — Plan Document Consistency (fleet plan)**
Grep the entire plan document for the old agent name. Every section must be current:
- Architecture diagram labels
- Decision tree routes
- Harness tables
- Flow patterns
- Fleet manifest (active + removed tables, counts)
- Phase status tables and checkboxes
- Remaining phase specs (cross-section contradictions — Phase 2 fallback may say "keep as generator" while Phase 4 spec says "reviewer only")

**Dimension 5 — CLI Entry Point Backward Compatibility**
After refactoring `process_request()`, verify:
- `--status` flag still works (non-interactive mode)
- No new required positional arguments added to the CLI signature
- Default `pattern="auto"` preserves existing behavior for callers that don't pass a pattern
- Non-interactive mode (single request) still prints output

**Trigger:** Run all 5 dimensions when the user says "review what we've done" or before marking any multi-phase plan phase as "complete." If gaps are found, fix them before declaring victory.

**Verification macro:**
```bash
# Dimension 1: SOUL.md vs V5
for d in ~/AppData/Local/hermes/profiles/*/; do
  name=$(basename "$d"); role=$(grep "^\\[ROLE\\]" "$d/SOUL.md" 2>/dev/null)
  echo "$name SOUL: $role"
done

# Dimension 3: stale files after rename
find ~/AppData/Local/hermes/profiles/ -name "*kalliope*" -o -name "*thalia*" 2>/dev/null

# Dimension 4: plan cross-section
grep -n "kalliope\|thalia\|fortuna_19 (old)" ~/Vault/wiki/queries/fleet-optimization-v2-plan.md

# Dimension 5: CLI backward compat
cd ~/AppData/Local/hermes/scripts && timeout 10 python fleet-manager.py --status | head -3
```

## Common Audit Mistakes

1. **Checking only default profile crons** — `hermes cron list` without `-p` shows nothing. All crons are in per-profile namespaces.
2. **Assuming all profiles use the same model** — models are differentiated by V5 tier (DeepSeek for heavy, Gemini for fast).
3. **Trusting the plan doc over actual state** — the plan can be stale. Always verify against actual `config.yaml` files and `fleet-state.json`.
4. **Forgetting Thalia-23 merge** — 13 workers, not 14. Thalia is in the default profile's SOUL.md, not a separate profile.
5. **Only testing the chat path** — the chat path (Vesta → Astraea → Hermes → Ceres) always works, but specialist routing (→ Metis, → Klio, → Artemis, etc.) has known gaps. Always run at least the 3 quick routing checks in step 7.
2. **Assuming all profiles use the same model** — models are differentiated by V5 tier (DeepSeek for heavy, Gemini for fast).
3. **Trusting the plan doc over actual state** — the plan can be stale. Always verify against actual `config.yaml` files and `fleet-state.json`.
4. **Forgetting Thalia-23 merge** — 13 workers, not 14. Thalia is in the default profile's SOUL.md, not a separate profile.
5. **Only testing the chat path** — the chat path (Vesta → Astraea → Hermes → Ceres) always works, but specialist routing (→ Metis, → Klio, → Artemis, etc.) has known gaps. Always run at least the 3 quick routing checks in step 7.
