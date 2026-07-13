# MCP Server Startup Retry Pattern Diagnosis

**Session:** 2026-07-03, 16:00-16:20  
**Reported Issue:** "Every time I start a new session the MCP server starts failed"

## Symptom

On session start, the MCP server silently fails for the first 3-4 attempts. After ~2.5 minutes it connects and runs perfectly. No error messages are visible anywhere.

## Diagnostic Flow

### Step 1: Check mcp-stderr.log for the retry pattern

This is the #1 signal. A healthy server startup shows one header then initializes. A failing server shows 4+ headers in rapid succession:

```bash
grep -n "starting MCP server" ~/AppData/Local/hermes/logs/mcp-stderr.log | tail -10
```

**Retry pattern (failing):**
```
===== [08:44:47] starting MCP server 'hermes' =====
===== [08:44:49] starting MCP server 'hermes' =====   ← 2s later
===== [08:44:52] starting MCP server 'hermes' =====   ← 3s later
===== [08:44:57] starting MCP server 'hermes' =====   ← 5s later
[2.5 min gap — all retries exhausted]
[08:47:18] PingRequest                                 ← finally connected
```

**Healthy startup (single attempt):**
```
===== [14:01:26] starting MCP server 'hermes' =====
[14:01:28] ListToolsRequest
[14:04:28] PingRequest
```

The retry count matches `_MAX_INITIAL_CONNECT_RETRIES = 3` (1 initial + 3 retries = 4 total attempts). The gaps follow exponential backoff: immediate, 1s, 2s, 4s (from the Hermes manager code in `mcp_tool.py`).

### Step 2: Check the gap between retries and the first PingRequest

After 4 failures, the Hermes manager gives up (`_ready.set()` + `return`). The ~2.5 minute gap is the reconnect interval — a separate mechanism (not the initial retry loop). When you see this gap, the initial connection has permanently failed, and something else is driving the recovery.

### Step 3: Test-spawn the server directly

From `execute_code()` or terminal:
```python
import subprocess
import sys

cmd = [
    r"~/AppData/Local/hermes\AppData\Local\hermes\hermes-agent\venv\Scripts\python.EXE",
    r"~/AppData/Local/hermes\AppData\Local\hermes\scripts\hermes-mcp-server.py",
    "--vault", r"~/agent-wiki",
    "--accept-hooks"
]
proc = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    cwd=r"~/AppData/Local/hermes\AppData\Local\hermes\scripts", text=True, bufsize=0)
import time
time.sleep(1)
alive = proc.poll() is None
print(f"Alive: {alive}, RC: {proc.poll()}")
if not alive:
    stdout, stderr = proc.communicate(timeout=2)
    print(f"STDOUT: {stdout!r}")
    print(f"STDERR: {stderr!r}")
```

**Expected when lock is blocked:** Immediate exit with RC=0, empty stdout and stderr. This is the signature of `_sys.exit(0)` inside `_acquire_lock()` after `WaitForSingleObject(handle, 0)` returns `WAIT_TIMEOUT`.

### Step 4: Check for orphan MCP processes

Use `wmic` (Windows) to identify all MCP processes:

```bash
wmic process where "CommandLine like '%%mcp-server%%'" get ProcessId,CommandLine
```

**Critical nuance — check the Python interpreter path:**

| Path | Status | Notes |
|------|--------|-------|
| `hermes-agent/venv/Scripts/python.EXE` | ✅ **Legitimate** | Current session's MCP server |
| `AppData/Roaming/uv/python/cpython-3.11-.../python.exe` | ⚠️ **Orphan** | Spawned by a previous session using uv-managed Python |
| `AppData/Local/Microsoft/WindowsApps/python.exe` | ⚠️ **Orphan** | Store-installed Python, not in use |

The orphan detection trick: the legitimate MCP process runs from the Hermes venv (`$HERMES_HOME/hermes-agent/venv/Scripts/python.EXE`). Any other interpreter is either from a previous session (uv) or a system interpreter that was on PATH when Hermes resolved `command: python`.

### Step 5: Check mcp-stderr.log for error patterns

After the retry cluster, examine the log for errors:

```bash
# Check if there are any errors NEAR the 08:44 cluster
sed -n '29190,29390p' ~/AppData/Local/hermes/logs/mcp-stderr.log | grep -iE 'error|traceback|exception|fail|crash|winerror'

# Check for kill/terminate errors (common when previous process was killed)
grep -c "WinError 87" ~/AppData/Local/hermes/logs/mcp-stderr.log
```

OSError [WinError 87] from `kill` is an old issue (pre-Jul-3 fix) and indicates the previous session was using `os.kill` on Windows which doesn't support signal semantics.

## What's Actually Happening

When the previous session ends, its MCP subprocess is killed (or exits). The Windows named kernel mutex `Local\HermesMCP_hermes_mcp_server` still exists in the kernel — it was created by `CreateMutexW(None, True, name)` with `bInitialOwner=True`. The owning thread is dead, so the mutex is abandoned.

The new session spawns a fresh MCP server. The new process calls `CreateMutexW(None, True, name)` which returns a handle to the existing mutex with `GetLastError() == ERROR_ALREADY_EXISTS`. Then `WaitForSingleObject(handle, 0)` with a **0ms timeout**:

- If the kernel has already marked the mutex as abandoned → `WAIT_ABANDONED` (0x80) → inherit ownership, proceed
- If the kernel is still finalizing the stale state → `WAIT_TIMEOUT` (0x102) → **exit silently**

The 0ms timeout creates a race condition with kernel cleanup. A short wait (100-400ms) closes this window.

## Fix

Apply both fixes to `hermes-mcp-server.py`:

**Fix A — Lock retry with backoff in `_acquire_lock()`.** Replace:

```python
result = _kernel32.WaitForSingleObject(handle, 0)
if result == WAIT_TIMEOUT:
    _kernel32.CloseHandle(handle)
    _sys.exit(0)
```

With:

```python
for attempt in range(3):
    result = _kernel32.WaitForSingleObject(
        handle, 100 << attempt  # 100ms, 200ms, 400ms
    )
    if result == WAIT_ABANDONED:
        break
    if result != WAIT_TIMEOUT:
        _kernel32.CloseHandle(handle)
        _sys.exit(0)
else:
    print(
        f"[{time.strftime('%H:%M:%S')}] "
        f"MCP lock held by another process after 3 retries, exiting",
        file=sys.stderr,
    )
    _kernel32.CloseHandle(handle)
    _sys.exit(0)
```

**Fix B — Orphan cleanup preflight in `main()`.** Insert before `_acquire_lock()`:

```python
def main() -> None:
    if os.name == "nt":
        try:
            current_pid = str(os.getpid())
            orphan_pids: list[str] = []
            result = subprocess.run(
                ["wmic", "process", "where",
                 f"name='python.exe' and commandline like '%{_LOCK_IDENT}%'",
                 "get", "processid", "/format:csv"],
                capture_output=True, text=True, timeout=5,
            )
            if result.returncode == 0:
                for line in result.stdout.strip().splitlines():
                    parts = line.strip().split(",")
                    if len(parts) >= 2 and parts[1].strip().isdigit():
                        pid = parts[1].strip()
                        if pid != current_pid:
                            orphan_pids.append(pid)
            if orphan_pids:
                subprocess.run(
                    ["taskkill", "/F"] +
                    [arg for p in orphan_pids for arg in ["/PID", p]],
                    capture_output=True, timeout=5,
                )
        except Exception:
            pass
    _acquire_lock()
```

## Related Failure Modes

- **FM#4 (double-spawn):** If both `command: python` resolve against multiple interpreters, the lock contention increases. Each pair of interpreters (venv + uv) spawns two MCP servers that race on the same mutex.
- **FM#11 (silent RC=1):** Different mechanism (wmic hang) but same symptom (silent exit, no log). Both fixed by replacing the blocking call with a deterministic alternative.
- **FM#14 (abandoned mutex):** The `bInitialOwner=True` fix for abandoned mutex detection is a prerequisite for this diagnosis — without it, the `WaitForSingleObject` path never runs.
- **FM#15 (ctypes import):** The `import ctypes.windll.kernel32 as k32` bug also causes silent exit but with a clear `ModuleNotFoundError` in stderr.
