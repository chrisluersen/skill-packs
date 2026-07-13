# wmic Phantom Process Entries

**Session:** 2026-07-01 — post-/new MCP verification

**Discovered:** wmic can report zombie/phantom process entries for processes that have already exited. These are not real processes — they are transient records from a prior wmic query or stale WMI cache.

## The Pattern

1. You kill all MCP processes (e.g. via `taskkill //F //PID` or `os.kill(SIGTERM)`)
2. `wmic` still shows entries with the same PIDs
3. But `taskkill //F //PID` returns "The process with PID X has been terminated" and then "The process Y not found" — partial failure
4. Lock files show "Device or resource busy" confirming the surviving instance holds the lock
5. A second `wmic` query returns empty — phantom entries disappear

## Root Cause

WMI maintains a cached process list. When a process exits between your `wmic` query's enumeration and result delivery, the PID can still appear in the CSV output even though the process is already dead. This is **not** a race condition in your code — it's a WMI artifact.

## How to Avoid False Positives

```bash
# Don't trust one wmic call alone. Cross-check against lock files.
python3 -c "
import os
from pathlib import Path

# 1. Check lock file PIDs
lock_dir = Path.home() / 'AppData/Local/hermes/run'
for f in sorted(lock_dir.glob('*.lock')):
    pid = int(f.read_text().strip())
    try:
        os.kill(pid, 0)
        print(f'{f.stem}: PID {pid} RUNNING')
    except OSError:
        print(f'{f.stem}: PID {pid} DEAD')

# 2. After killing, run a confirmatory wmic query
import subprocess
r = subprocess.run(['wmic', 'process', 'where',
    \"CommandLine like '%fleet-mcp%'\",
    'get', 'ProcessId', '/format:csv'],
    capture_output=True, text=True, timeout=10)
pids = [int(l.strip()) for l in r.stdout.split() if l.strip().isdigit()]
print(f'Remaining wmic entries: {pids}')
"
```

## Key Takeaway

If lock files are present and `cat` returns "Device or resource busy" (or the PID in the lock is alive via `os.kill(pid, 0)`), **trust the lock, not wmic**. The lock is kernel-guaranteed; wmic is cached.

---

## Common MCP Server Startup Crash: Missing `import atexit` (2026-07-03)

A new failure mode discovered during the 2026-07-03 session: both `wiki-mcp-server.py` and `fleet-mcp-server.py` use `@atexit.register` for cleanup but never imported `atexit`. The decorator raises `NameError: name 'atexit' is not defined` at module execution time, before any MCP tool registration or stdio connection.

**Detection:** Rapid retry loop in `mcp-stderr.log` (3+ start headers within 60s, zero error output). Test-spawn the server directly from terminal to see the actual traceback.

**Fix:** Add `import atexit` at module level. Both files patched.

**Pitfall — `atexit` + `__file__`:** If the handler references `__file__` (e.g. `Path(__file__).stem`), the handler crashes silently at program exit because `atexit` silently drops handler exceptions. Store at module level: `_SCRIPT_IDENT = Path(__file__).stem` and use `_SCRIPT_IDENT` in the handler.