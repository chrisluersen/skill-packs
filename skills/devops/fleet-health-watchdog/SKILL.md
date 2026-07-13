---
name: fleet-health-watchdog
description: "Fleet health watchdog cron job — silent when healthy, alerts on circuit breaker trips, quarantines, or maintenance mode. Companion cron: fleet-regression-detector (nightly smoke test suite). Uses no_agent=True pattern for zero-token operation."
version: 1.2.0
author: 7-Iris
platforms: [windows]
---

# Fleet Health Watchdog

Automated fleet health monitoring via cron job. Runs `fleet-health-watchdog.py` every 30 minutes using the `no_agent=True` cron pattern — zero tokens when healthy, direct alerts when issues detected.

## Files

### Watchdog script: `~/AppData/Local/hermes/scripts/fleet-health-watchdog.py`

Also available in-skill at `scripts/fleet-health-watchdog.py`.

Lightweight Python script that:
1. Runs `fleet-manager.py --cb-status` — checks for OPEN/HALF_OPEN circuit breakers
2. Runs `fleet-manager.py --status` — checks for quarantines and maintenance mode
3. Scans process table for `fleet-mcp-server.py` — alerts if the MCP server process is missing (uses `psutil`; falls silent if not installed)
4. Returns empty stdout (silent) when healthy
5. Returns alert lines when issues found

The script hardcodes `FLEET_MANAGER = Path.home() / "AppData" / "Local" / "hermes" / "scripts" / "fleet-manager.py"` — this is correct for Windows where `HERMES_HOME` is `~/AppData/Local/hermes/` and `fleet-manager.py` may not be in PATH.

### Cron job

Created via `cronjob(action='create', name='fleet-health-watchdog', no_agent=True, schedule='every 30m', script='fleet-health-watchdog.py', deliver='origin')`

The `deliver='origin'` setting sends alerts to the current conversation. With `no_agent=True`:
- Empty stdout = no message sent (healthy)
- Non-empty stdout = alert delivered directly

## Commands

```bash
# Test the watchdog
timeout 30 python ~/AppData/Local/hermes/scripts/fleet-health-watchdog.py
echo "exit=$?"
# Silent exit (0) = fleet healthy, exit (1) = error

# View the cron job
hermes cron list | grep fleet-health

# Test the regression detector
timeout 120 python ~/AppData/Local/hermes/scripts/fleet-regression-detector.py
# Silent = all passing, alert = regression found

# Run manual
cronjob(action='run', job_id='<id>')
```

## Companion Cron: Fleet Regression Detector

In addition to the 30-min circuit-breaker watchdog, a nightly regression detector runs the full smoke test suite at 0500 daily.

### Script: `~/AppData/Local/hermes/scripts/fleet-regression-detector.py`

Runs `test-fleet-smoke.py --full` (all 6 patterns, ~600s timeout) and:
- **Empty stdout** (silent) when all patterns pass
- **Alert** listing which patterns failed, with timing
- **Alert** on suite crash or timeout

Uses `no_agent=True` pattern — zero tokens when healthy.

### Cron job (created 2026-07-07)

| Field | Value |
|---|---|
| Schedule | `0 5 * * *` (daily 0500) |
| Script | `fleet-regression-detector.py` |
| Delivery | Origin (this thread) — only when failure detected |
| Timeout | 700s (11:40 margin on ~12min suite) |

### Coverage

- Clears response cache before each run for clean results
- Parses `smoke-results.jsonl` per-test results
- Reports per-pattern pass/fail with durations
- No external dependencies beyond stdlib + test-fleet-smoke.py

## Pitfalls

- **Script location for cron:** Bare script names in cron jobs resolve relative to `HERMES_HOME/scripts/` (`~/AppData/Local/hermes/scripts/` on Windows). Do NOT put scripts in `~/.hermes/scripts/` — the cron system doesn't look there. The skill's own script is already at the right path.
- `fleet-manager.py` may not be in PATH in the TUI terminal — the script hardcodes its path, which is correct. If testing manually from a shell where fleet-manager is in PATH, the script still works.
- Must set `deliver='origin'` after creation — default is `local` which drops notifications
- Timeout handling: if `fleet-manager.py` hangs for >15s the watchdog reports timeout
- No_agent=True means the script IS the logic — no LLM involved
- **Transient errors on first run:** If the router-watchdog script errors with no obvious cause, it may be a stale state file or timing issue (the state file didn't exist yet when the cron first fired). Re-triggering with `cronjob(action='run', job_id='<id>')` often resolves it. If it errors consistently, check the script for file-existence guards and path assumptions.

### Fleet MCP Health Thread Timeout Pattern

The fleet MCP server (`fleet-mcp-server.py`) runs an internal background health thread that spawns `fleet-manager.py --cb-status` every 30s.

**Root cause (fixed 2026-07-06):** `fleet-manager.py main()` called `manager.start()` (launches Pub/Sub event loop) *before* checking if the command was display-only. Every display-only invocation spawned a dangling event loop task that `asyncio.run()` had to cancel on exit — causing the 45s STATUS_TIMEOUT. The actual `--cb-status` output returned in <1s; it was `asyncio.exit` cleanup that hung.

**Primary fix:** Move all sync display commands (`--cb-status`, `--status`, `--routing-status`, `--cost-report`, `--recent`, `--maintenance`, `--feedback-audit`) before `manager.start()` in `main()`. Eliminates root cause — no event loop for display-only commands.

**Secondary tuning (legacy, redundant after structural fix):**

| Constant | Default | Recommendation |
|---|---|---|
| `STATUS_TIMEOUT` | 20s | → **25s** — legacy margin for cold-start profile loading |
| `MAX_RETRIES` | 0 | → **1** — one retry for transient slow loading |

With the structural fix, cold-start `--cb-status` returns in ~16s (Python + profile loading) with no hanging event loop. Tuning knobs are now a safety margin.

**Diagnostic:** If watchdog reports CLOSED but MCP ping says UNHEALTHY, verify the fleet-manager has sync-before-start() fix. If it does, the health thread started before the patch — use `/reload-mcp` or new session.
