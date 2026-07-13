# Fleet Optimization Planning Methodology

> How to systematically analyze an existing multi-agent fleet against research-backed best practices and produce an actionable, dependency-ordered optimization plan.

## When to Use

- User asks "what gaps does the fleet have?" or "how can we make the fleet better?"
- User asks for a plan to add/remove agents, change routing, or restructure the fleet
- After major milestones (fleet E2E pass, new model release, provider change)
- Before significant profile changes (add/remove/rename agents)

## Workflow

### Phase A — Audit Current State

Read every live data source before drawing conclusions. Batch independent reads in parallel.

**Sources to read in parallel:**
```
batch:
  - read_file: ~/AppData/Local/hermes/scripts/fleet-manager.py
    sections: _classify_task(), _route_to_worker(), process_request(), profile map, tier sets
  - mcp_wiki_read_wiki_page: concepts/asteroid-fleet-manifest.md
  - skill_view: hermes-fleet-profiles references/multi-agent-orchestration-research-synthesis.md
  - session_search: "fleet E2E test results Phase 7" (limit=3, sort=newest)
  - session_search: "fleet gap missing role" (limit=3, sort=newest)
  - terminal: python fleet-manager.py --status
```

**Extract from each source:**

| Source | Extract |
|--------|---------|
| fleet-manager.py | Active workers (PROFILE_MAP), routing categories, dispatch patterns, tier sets, gate chain |
| fleet manifest | Agent roles, system groups, fallback chains, deploy status (🟢/🟡/⚪) |
| Research synthesis | Optimal agent count (5-8), 8 design patterns, missing canonical roles, profile format evidence |
| Session search | E2E test results, known bugs, stuck agents, latency numbers |
| --status output | Current agent count, load, quarantines |

### Phase B — Compare Against Research

For each of these dimensions, map current state → research optimal → gap:

| Dimension | Research Says | Current Fleet | Gap |
|-----------|--------------|---------------|-----|
| **Agent count** | 5-8 active agents optimal (diminishing returns beyond 8) | Count current active workers + gates | Over/under? |
| **Routing** | LLM-based orchestrator, not keyword | Current: keyword `_classify_task()` | Upgrade or keep? |
| **Pipeline** | Sequential most expensive pattern; dynamic patterns preferred | Current flow patterns | How many are dynamic vs sequential? |
| **Gates** | Dual gate (generator+critic) best QA pattern | Nemesis (QA) + Ceres (review) = dual gate | Working? |
| **Missing roles** | Memory, observability, human-in-loop, fallback handler | Which are present? Which are missing? | List each |
| **Profile format** | Task-first [ROLE]/[BEHAVIOR]/[OUTPUT]/[RULES] beats theatrical | Check current SOUL.md files | Audit per profile |

### Phase C — Classify Gaps

| Severity | Definition | Example |
|----------|-----------|---------|
| **P0 — Broken** | Active bug that degrades functionality | Agent timeout, routing crash, gate rejects good output |
| **P1 — Incomplete** | Working but suboptimal | Keyword routing when LLM would be better, no QA for some workers |
| **P2 — Missing** | Feature that should exist but doesn't | No observability cron, no human-in-loop gate |

**Priority rule:** P0 first (stops things from working), then P2 (new capability), then P1 (optimization). Rationale: P1 improvements on a broken foundation are wasted effort.

### Phase D — Order by Dependency

Draw a dependency graph. A phase cannot start until all its dependencies are complete.

**Common dependency patterns:**
```
Backup (Phase 0) → No dependencies
  │
  ▼
Core routing changes (Phase 1) → [needs forked: Profile creation (Phase 2), Observability (Phase 3), Gate additions (Phase 4)]
  │                              ↗           ↗               ↗
  ▼                            /           /               /
Parallel dispatch (Phase 5) ←─/──────┐    /              /
  │                                    │   /             /
  ▼                                    │  /             /
Gate optimization (Phase 6) ───────────┘ /             /
  │                                      /            /
  ▼                                     /            /
Profile tuning (Phase 7) ←─────────────┘←───────────/
  │
  ▼
E2E tests (Phase 8) ← All prior phases complete
  │
  ▼
Closeout (Phase 9)
```

**Identify parallelizable work:** Phases that share no file dependencies can run simultaneously (e.g., creating new SOUL.md files and adding a health-check cron touch different files).

### Phase E — Add Fallback & Rollback Per Phase

Every phase needs:
- **Rollback:** How to undo if it breaks. Common: `cp <file>.bak <file>`, `git checkout`, restore from OneDrive backup.
- **Fallback:** What happens if this phase's approach fails entirely. E.g., "If LLM routing is too slow, restore keyword routing and add LLM as opt-in flag."

### Phase F — Define Success Criteria

A table of before/after metrics. Every metric needs a specific, measurable target.

| Metric | Before | Target | How to Measure |
|--------|--------|--------|----------------|
| Routing patterns | N (keyword) | M (LLM-based) | `grep "pattern" fleet-manager.py`, E2E test passes |
| Active workers | N | M | `python fleet-manager.py --status` shows count |
| Pipeline latency | ~N seconds | ~M seconds | Average of 5 E2E runs |
| E2E pass rate | N/M tests pass | All M tests pass | Run E2E suite, check exit codes |

### Phase G — Write the Plan

Use the `plan` skill for structure. Each phase has:

```markdown
## Phase N: Name (estimated time)

### Files changed:
- Modify: `~/AppData/Local/hermes/scripts/fleet-manager.py"
- Create: `~/AppData/Local/hermes/profiles/<name>/SOUL.md"
- ...exact paths

### Step-by-step:
1. [Exact action with code or command]
2. [Exact action with code or command]
3. ...

### Verify:
[Exact command with expected output]

### Done signal:
[What tells you this phase is complete — specific output, test pass, file content check]

### Rollback:
[How to undo]

### Fallback:
[What to try if this phase fails]
```

Include at the end:
- **Dependency graph** (ASCII diagram or table)
- **Parallelism map** (which phases can run concurrently, estimated wall-clock time)
- **Effort summary** (table with estimated times, parallelization potential)
- **Open questions** (things that need user decision before execution)

## Example: Fleet Optimization Plan Structure

```
Phase 0: Pre-Flight Backup & Audit (30m)
  └── Backup fleet-manager.py, V5 JSON, profile dirs

Phase 1: Routing Upgrade — LLM-based Classification (1h)
  └── Replace _classify_task() keyword with LLM call to Astraea-5
  └── Add devops + content pattern branches
  └── Load Atalanta-36 and Kalliope-22 profiles from V5 JSON
  └── E2E test: all 9 patterns route correctly

Phase 2: Add Missing Agent Profiles — SOUL.md (45m)
  └── Create Kalliope-22 SOUL.md (task-first format)
  └── Create Atalanta-36 SOUL.md (task-first format)
  └── Register profiles with Hermes
  └── Verify standalone: hermes -p <name> chat -q "test"

Phase 3: Add Observability Cron (30m)
  └── Create fleet-health-check.sh (disk, memory, router, fleet-manager)
  └── Register as no_agent cron, every 6h, silent when healthy
  └── Verify: cronjob list shows fleet-health

Phase 4: Add Human-in-Loop Gate (30m)
  └── Add _needs_confirmation() to fleet-manager.py
  └── Check in process_request() after Vesta-4
  └── Handle --confirm prefix to bypass
  └── E2E test: destructive op → gate, --confirm → bypass

Phase 5: Add Parallel Fan-Out for Multi-Angle Research (45m)
  └── Add _fan_out_to_workers() async method
  └── Add _is_multi_angle() heuristic
  └── Dispatch in process_request(): fan-out for broad research, single worker for narrow
  └── E2E test: "comprehensive overview" → 3-section merged output

Phase 6: Smart Gate Selection — Skip Gates for Simple Tasks (30m)
  └── Update _needs_qa() with dual signal: task type + output length
  └── Skip Ceres gate for Tier 0/1 tasks
  └── E2E test: simple lookup → no QA, complex code → full gate chain

Phase 7: Task-First Profile Tuning (30m)
  └── Audit all SOUL.md files for theatrical preamble
  └── Rewrite to [ROLE]/[BEHAVIOR]/[OUTPUT]/[RULES] format
  └── Verify: test queries produce clean, non-theatrical output

Phase 8: E2E Test Suite (30m)
  └── Test all 9 patterns
  └── Test fan-out dispatch
  └── Test human-in-loop gate
  └── Test fallback chain (simulate missing profile)
  └── All pass: done

Phase 9: Closeout — Wiki & Handoff (15m)
  └── Update latest-handoff.md
  └── Update fleet manifest with new agent count
  └── Save any reusable patterns as skills
```

## Key Principles

1. **Read before write.** Never write to a file you haven't read in full. `write_file` overwrites completely.

2. **Patch surgically.** Use `patch(mode='replace', ...)` for targeted changes to existing files, not full rewrites. Only `write_file` for new files or complete replacements.

3. **Verify each phase before starting the next.** Create a phase done signal checklist. A done signal is a test result, not a feeling.

4. **Parallelize aggressively.** Backups, profile creation, cron setup, and simple gate logic can all run simultaneously. Only serialize when a phase genuinely depends on a prior phase's output.

5. **Backup between phases.** Snapshot changed files before each phase's first mutation. Restore is a `cp .bak` away.

6. **Account for known constraints.** Hermes enforces a 64K context floor — any profile with a lower V5 spec value must be floored up. Provider key exhaustion can block all profiles using that provider.

7. **Separate analysis from action.** Phase 0 is analysis-only (reads, audits, comparisons). No mutations until the user confirms the plan is correct. After confirmation, execute phases 1-9 with the user's approval at each phase boundary if they want staged execution.

## Provenance

Developed during the June 2026 fleet optimization session:
- **Research backed by:** 8-source multi-agent orchestration synthesis (arXiv, Azure, Anthropic, Google ADK, LangChain, Galileo, Beam, TrueFoundry)
- **Empirically validated by:** Phase 7 E2E test suite (7 patterns, 100% pass after bug fix)
- **Gaps discovered:** No DevOps agent, no Content agent, no observability, no human-in-loop, keyword routing brittle, theatrical profiles causing 8/100 scores
- **Plan produced:** `2026-06-24_optimal-multi-agent-orchestration.md` under `.hermes/plans/`
