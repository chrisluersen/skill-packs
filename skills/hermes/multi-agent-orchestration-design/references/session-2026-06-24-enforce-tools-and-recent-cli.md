# Session: 2026-06-24 — Privilege Level Enforcement + `--recent` CLI

## Build Order

This session implemented the final Fleet V3 items in this order:
1. Router-watchdog fix (cron error)
2. Eris-101 (second independent evaluator, conditional on Nemesis score <80 or "uncertain" signals)
3. Event sourcing (`PipelineState._events` → `_commit_state()` → disk)
4. Cost tracking + audit trail (`estimate_dispatch_cost()`, `cost_log.jsonl`, `audit.jsonl`, `--cost-report`)
5. Privilege level enforcement (`_enforce_tool_level()` caps profile tools by max_turns)
6. `--recent` CLI (reads `audit.jsonl` and prints last N dispatches in a table)

Each step built on the last. Event sourcing enabled cost tracking (same FLEET_DIR/logging infrastructure). Cost+audit logs enabled `--recent`.

---

## Pattern: Privilege Level Enforcement via max_turns

### Design Decision

The skill documents PRIVILEGE_MAP (per-agent dict mapping pid → level) with LEVEL_TOOLS (per-level tool sets). The **actual implementation** simplifies this: `max_turns` doubles as the privilege level, using the existing TOOL_LEVELS constants directly.

### Rationale for Simplification

- **No separate PRIVILEGE_MAP to maintain.** Adding a new agent means setting `max_turns` in the JSON — that's already required. No second dict to edit.
- **Three levels cover the fleet.** 0 (gates/pure reasoners), 1 (workers with read/write/search), 8 (heavy executors with terminal). L2-L3 aren't needed at current scale.
- **TOOL_LEVELS already existed** for tier-based tool gating. Using max_turns as the level selector reuses existing infrastructure.

### Actual Code (fleet-manager.py)

```python
# TOOL_LEVELS — defined at module level, maps turn budget → tool capability
TOOL_LEVELS = {
    0: [],      # Pure reasoners — no tools (gates, evaluators)
    1: [         # Workers — read, write, search, web, vision
        "read_file", "write_file", "patch", "search_files",
        "web_search", "web_extract",
        "mcp_wiki_search_wiki", "mcp_wiki_read_wiki_page",
        "mcp_wiki_list_wiki_pages", "mcp_wiki_lint_wiki",
        "mcp_wiki_reindex_wiki", "mcp_wiki_wiki_stats",
        "mcp_wiki_synthesize_answer",
        "vision_analyze",
    ],
    8: [         # Heavy executors — full access incl. terminal
        *TOOL_LEVELS[1],
        "terminal", "cronjob", "execute_code",
        "process", "mcp_wiki_file_synthesis",
    ],
}

# In dispatch_to_agent(), after contract validation:
def _enforce_tool_level(self, profile: AgentProfile):
    """Cap profile tools to the agent's privilege level bound.

    Uses max_turns as proxy for privilege level:
      0 → TOOL_LEVEL 0 (no tools) — gates/evaluators
      1 → TOOL_LEVEL 1 (workers)  — content, data, design, wiki
      8 → TOOL_LEVEL 8 (executors) — code, devops, search

    This is a SECONDARY ring. The contract's allowed_tools is the
    primary gate. Both must agree for a tool to pass.
    """
    level = profile.max_turns if profile.max_turns in TOOL_LEVELS else 0
    allowed = set(TOOL_LEVELS.get(level, []))
    if profile.tools:
        stripped = [t for t in profile.tools if t not in allowed]
        profile.tools = [t for t in profile.tools if t in allowed]
        if stripped:
            log.warning(f"  ⚠️  Enforced TOOL_LEVEL {level}: stripped "
                        f"{', '.join(stripped)}")
```

### Key Insight: max_turns → Level Mapping

| max_turns | TOOL_LEVEL | Agents | Rationale |
|-----------|-----------|--------|-----------|
| 0 | 0 (empty) | Vesta-4, Astraea-5, Ceres-1, Nemesis-128 | Pure reasoners — no tools |
| 1 | 1 (worker) | Fortuna-19, Harmonia-40, Klio-84, Atalanta-36, Kalliope-22 | Single-shot generation + read |
| 8 | 8 (full) | Metis-9, Artemis-105, Mnemosyne-57 | Multi-step with terminal access |

### Pitfall

The `_enforce_tool_level()` call is placed **after** contract validation in `dispatch_to_agent()`. The contract's `allowed_tools` is the primary gate (strips tools first), then `TOOL_LEVELS` caps by tier. If the contract allows a tool but the tier doesn't, the tier wins. This is intentional — TOOL_LEVELS is a catch-all safety net.

---

## Pattern: `--recent` CLI

### Problem

Cost+audit logs are written to disk as JSONL (`~/.hermes/fleet/audit.jsonl`) but there was no way to query them. Debugging what the fleet has been doing required `cat audit.jsonl` and grepping.

### Implementation

```python
def _print_recent_dispatches(self, limit: int = 20):
    """Read audit log and print recent dispatches in a table."""
    audit_path = FLEET_DIR / "audit.jsonl"
    if not audit_path.exists():
        print("📭 No audit log found — no dispatches recorded yet.")
        return

    records = []
    with open(audit_path) as f:
        for line in f:
            line = line.strip()
            if line:
                try:
                    records.append(json.loads(line))
                except json.JSONDecodeError:
                    continue

    if not records:
        print("📭 Audit log is empty — no dispatches recorded yet.")
        return

    records.reverse()
    entries = records[:limit]

    print(f"\n{'='*70}")
    print(f"  RECENT DISPATCHES  (last {len(entries)} of {len(records)} total)")
    print(f"{'='*70}")
    print(f"  {'AGENT':<20} {'STATUS':<10} {'CB':<12} {'DURATION':<10} {'TRACE':<14}")
    print(f"  {'─'*20} {'─'*10} {'─'*12} {'─'*10} {'─'*14}")
    for e in entries:
        pid = e.get("agent_pid", "?")[:18]
        status = "✅" if e.get("success") else "❌"
        cb = e.get("cb_state", "?")[:10]
        dur = f"{e.get('duration_ms', 0):.0f}ms"[:8]
        tid = e.get("trace_id", "?")[:12]
        print(f"  {pid:<20} {status:<10} {cb:<12} {dur:<10} {tid:<14}")
    print(f"{'='*70}\n")
```

### CLI wiring

```python
elif sys.argv[1] == "--recent":
    limit = int(sys.argv[2]) if len(sys.argv) > 2 else 20
    manager._print_recent_dispatches(limit)
```

### Usage

```bash
python fleet-manager.py --recent        # Last 20 dispatches
python fleet-manager.py --recent 5      # Last 5
```

### Data Source

The `--recent` command reads `~/.hermes/fleet/audit.jsonl`, which is written by `_log_dispatch_outcome()` at every return path in `_dispatch_with_fallback()`. Each line is a JSON dict:

```json
{
  "trace_id": "a1b2c3d4e5f6",
  "agent_pid": "metis_9",
  "duration_ms": 45123,
  "success": true,
  "cb_state": "CLOSED",
  "event_type": "compilation_success",
  "timestamp": "2026-06-24T10:00:00"
}
```

### Design Notes

- **Most-recent-first order.** Read all lines, reverse in Python. Simpler than `tail -r` and works cross-platform.
- **Empty state is explicit.** "No audit log found" vs "Audit log is empty" — distinguishes "never dispatched" from "dispatched but nothing recorded."
- **Column alignment is human-readable, not machine-parseable.** For programmatic queries, read the JSONL directly.
- **No output count.** The table header shows how many entries are displayed vs total, so `--recent 5` shows "5 of 234" to communicate there's more data available.

### Pitfall

The audit log doesn't exist until the first successful dispatch. Running `--recent` on a fresh fleet returns "No audit log found." This is correct behavior but can be surprising on first use.

---

## Pattern: FLEET_DIR Centralization

### What Changed

Event sourcing, cost logging, audit logging, and the privilege enforcement all read/write from `~/.hermes/fleet/`. A `FLEET_DIR` constant was needed:

```python
FLEET_DIR = Path.home() / ".hermes" / "fleet"
```

### Files Under FLEET_DIR

| Path | Purpose | Created By |
|------|---------|------------|
| `events/{trace_id}.jsonl` | Full event log per dispatch | `_commit_state()` |
| `cost_log.jsonl` | Per-dispatch cost estimates | `write_cost_log()` |
| `audit.jsonl` | Per-dispatch outcomes | `write_audit_log()` |
| `fleet-state.json` | Persistent state (counters, CB states) | `_save_state()` |
| `task_contracts.json` | Agent registry | Manual (wiki template) |

### Pattern: No-op Guards

Every log writer checks for real data before writing:

```python
def _commit_state(self, pipeline: PipelineState):
    """No-op if pipeline has no events."""
    if not pipeline or not pipeline.trace_id or not pipeline._events:
        return
    # ... write events ...

def _print_recent_dispatches(self, limit: int = 20):
    """N ...[truncated]