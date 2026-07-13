# Phase 0 Pre-Flight Worked Example — 2026-06-24

> **Context:** This is the real execution of Phase 0 of the Fleet V3 architecture plan.
> The fleet had 9 active profiles, 17 cron jobs, and was running V2 operations on 10 agents.
> The goal was to prepare for a 14-phase architecture overhaul without disrupting production.

## Step-by-Step Execution

### 0a. Snapshot Existing State

**Commands:**
```bash
cp fleet-manager.py fleet-manager.py.bak
cp fleet-state.json fleet-state.json.bak
cp fleet-channels.json fleet-channels.json.bak
python fleet-manager.py --status   # capture baseline
```

**Result:** 3 backups created. Fleet healthy: 10 agents, 0 quarantines, 33 requests, 151 events.

### 0b. Inventory Current Profiles

**Commands:**
```bash
ls ~/AppData/Local/hermes/profiles/
ls ~/AppData/Local/hermes/profiles/*/SOUL.md
cronjob list
ls ~/AppData/Local/hermes/scripts/
```

**Result:** 9 profiles with SOUL.md (artemis, astraea, ceres, fortuna, harmonia, klio, metis, nemesis, vesta). No atalanta-36 or kalliope-22 profiles yet — those need Phase 2 creation. 17 cron jobs, 2 with errors. 57 scripts in scripts/ directory.

### 0c. Create Task Contract Registry

**File created:** `~/.hermes/fleet/task_contracts.json` (7,622 bytes)

**Structure per agent:**
```json
{
  "metis_9": {
    "display_name": "Metis-9",
    "role": "Code — Implementation & Debugging",
    "description": "Primary coding agent...",
    "input_schema": {"type": "string", "description": "Coding task"},
    "output_schema": {"type": "string", "format": "Code with imports ready to run"},
    "max_turns": 8,
    "allowed_tools": ["read_file", "write_file", "terminal", "search_files", "patch", "execute_code"],
    "quality_constraints": {"has_code_block": true, "no_roleplay_preamble": true},
    "cost_tier": "heavy",
    "privilege_level": 3
  }
}
```

**11 contracts total:** 9 active + 2 planned (atalanta_36, kalliope_22 with `"profile_needed": true`).

**Directory:** `~/.hermes/fleet/` had to be created first — it didn't exist.

### 0d. OWASP AST10 Security Audit

**File created:** `~/.hermes/fleet/owasp-ast10-audit.md` (3,691 bytes)

**Process:**
1. For each agent, read `allowed_tools` from the contract
2. Apply order-of-magnitude rule: does the agent use every tool 80%+ of the time?
3. Map each OWASP SK-01 through SK-10 risk to its mitigation
4. Document accepted risks with rationale

**Key findings:**
- 5 agents with 0 tools (gates + router) ✅ Minimal
- 6 agents with scoped tools ✅ No excess
- SK-03 (Runtime Isolation) deferred — single-process Hermes is an architectural constraint
- SK-09 (Privilege Escalation) deferred — Phase 4.5 maintenance mode

**Verdict:** PASS — all allowlists minimal and correct.

### 0e. Document Agent-Factory Workflow

**File created:** `~/.hermes/fleet/agent-factory-workflow.md` (4,310 bytes)

**10-step procedure:** Profile creation → Contract entry → PROFILE_MAP → Hermes registration → Tier assignment → Routing → Bulkheads → Circuit breakers → Test → E2E test.

**Design rule:** Adding an agent should never require editing routing logic. At 16+, even PROFILE_MAP should move to JSON.

## Artifacts Created

| Path | Size | Purpose |
|------|------|---------|
| `fleet-manager.py.bak` | 64,709 | Rollback of current fleet orchestrator |
| `fleet-state.json.bak` | 850 | State snapshot (33 requests, 151 events) |
| `fleet-channels.json.bak` | 7,944 | Channel subscription config |
| `~/.hermes/fleet/task_contracts.json` | 7,622 | 11 agent contracts with tool allowlists |
| `~/.hermes/fleet/owasp-ast10-audit.md` | 3,691 | Security audit pass + deferred risks |
| `~/.hermes/fleet/agent-factory-workflow.md` | 4,310 | 10-step add-agent procedure |

## Lessons Learned

1. **`~/.hermes/fleet/` may not exist yet** — check before referencing it in code or plans
2. **Cron errors are silent** — `onedrive-backup` and `session-closeout-audit` both had errors that were invisible from the task dashboard. Pre-flight surfaced them.
3. **Profile directory count ≠ agent count** — 9 profile dirs but 10 agents in `--status` output (hermes_default is synthetic)
4. **Backup is cheap, absence is expensive** — 3 `cp` commands took <1s. Without them, Phase 1 modifications would have no rollback path.
