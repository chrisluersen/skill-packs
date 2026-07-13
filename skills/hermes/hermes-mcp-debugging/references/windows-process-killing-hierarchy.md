# Windows Process Killing Hierarchy for Hermes-Spawned MCP Servers

From 2026-07-01 session: 6 stale fleet-mcp-server.py processes, all conventional kill methods failed.

## Hierarchy (most → least reliable)

| Method | Success | Notes |
|--------|---------|-------|
| `os.kill(pid, signal.SIGTERM)` from Python | ✅ Always | Works for all Hermes-spawned MCP processes |
| `wmic call terminate` | ⚠️ Partial | Returns Invalid query for some process contexts |
| `taskkill /F` via cmd.exe /c | ⚠️ Fragile | MSYS path mangling breaks /F flag |
| `kill <PID>` from git-bash | ❌ Never | Permission denied |

## Session Reproduction

**Context:** 6 stale fleet-mcp-server.py instances accumulated from 3+/new spawn batches. Code patches confirmed correct (--cb-status 0.23s from terminal). Each instance's health check `--cb-status` subprocess competed for resources → 20s timeout → UNHEALTHY.

### Attempt 1: `kill <PID>` from git-bash
```
$ kill 9108
Failed PID 9108
$ kill 3456
Failed PID 3456
```
All 6 killed failed. Permission Denied — Hermes-spawned processes run in a different context than git-bash.

### Attempt 2: `taskkill /F` from git-bash
```
$ taskkill /F /FI "COMMANDLINE eq *fleet-mcp-server*"
ERROR: Invalid argument/option - 'F:/'
```
MSYS translates `/F` to Windows path `F:/`. Even `//F` (MSYS escape) doesn't reliably fix this with complex filter strings.

### Attempt 3: `wmic call terminate` per PID
```
$ wmic path Win32_Process where "Handle='9108'" call terminate
Method execution successful. (killed 2/6)
$ wmic path Win32_Process where "Handle='29132'" call terminate
ERROR: Invalid query (ReturnValue=2147749911)
```
Killed 2 of 6. The remaining 4 returned "Invalid query" — unknown root cause. Possibly related to process tree depth, parent process permission boundaries, or race condition with Hermes auto-restart.

### Attempt 4: `os.kill(pid, signal.SIGTERM)` from execute_code (Python)
```python
import subprocess, os, signal

# Get PIDs of all fleet-mcp-server processes
r = subprocess.run(['wmic', 'path', 'Win32_Process', 'where',
    "name='python.EXE' AND CommandLine like '%%fleet-mcp-server%%'",
    'get', 'ProcessId'], capture_output=True, text=True, timeout=10)

pids = [int(line.strip()) for line in r.stdout.split('\n')
        if line.strip().isdigit()]

# Kill each one
for pid in pids:
    os.kill(pid, signal.SIGTERM)
```
Result: All remaining processes killed cleanly. Verified with `wmic` — 0 remaining.

## Auto-Restart Trap

Hermes restarts MCP processes within seconds of death. During a multi-step kill attempt, new PIDs appear between steps. Strategy:

**Do NOT sequence kills.** Kill ALL PIDs in a single pass (the Python loop above collects them all before killing any), then immediately `/new`.

If you kill one-by-one and Hermes respawns between kills, you're fighting a losing battle — the respawned process starts a new health check timer, so the old process's health check timeout may not even matter anymore. A single clean sweep + `/new` is the only reliable path.

## What Doesn't Work

- `taskkill //F //IM python.EXE` — kills ALL Python (collateral damage), and the `//F` double-slash MSYS escape doesn't work from git-bash shell
- `powershell Stop-Process` — not tested, but same MSYS/PowerShell bridging issues likely apply
