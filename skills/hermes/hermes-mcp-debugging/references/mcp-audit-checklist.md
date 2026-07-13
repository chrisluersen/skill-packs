# MCP Server Audit Checklist

Reusable audit framework for evaluating any MCP setup against the failure modes and best practices in the `hermes-mcp-debugging` skill. Use before commissioning a new server, investigating persistent health issues, or during periodic maintenance.

## Phase 1: Process Inspection (2 min)

### 1.1 Check PID files for running MCP servers
```bash
ls ~/AppData/Local/hermes/run/ 2>/dev/null || echo "No MCP servers running"
```
**Check:** One `.pid` file per server entry. Zero files means no server is running (expected between sessions).

### 1.2 Count instances (fallback: wmic)
```bash
wmic process where "CommandLine like '%%mcp%%'" get ProcessId,CreationDate,CommandLine /format:csv 2>/dev/null
```
**Check:** Every MCP server entry in config.yaml should have exactly **1** PID file and **1** wmic match. If PID count doesn't match wmic count, the sibling killer is self-healing the mismatch.

### 1.3 Identify stale instances
Group results by creation time. Each `/new` should produce one batch. If you see 3+ batches for the same server, orphans are accumulating.

### 1.4 Check for double-spawn
Look for the same server started by different Python interpreters (e.g. `venv/Scripts/python.EXE` AND `uv/python/.../python.exe`). This confirms Failure Mode #4.

## Phase 2: Config Analysis (3 min)

### 2.1 Pin python paths
```yaml
# ❌ WRONG — resolves to every interpreter on PATH
mcp_servers:
  server:
    command: python

# ✅ RIGHT — single explicit path
mcp_servers:
  server:
    command: ~/AppData/Local/hermes/AppData/Local/hermes/hermes-agent/venv/Scripts/python.EXE
```

### 2.2 Path style consistency
```yaml
# ❌ SLOPPY — mixed forward/backslashes
  wiki:    command: ~/AppData/Local/hermes/...
  fleet:   command: ~/AppData/Local/hermes\...

# ✅ CONSISTENT
  wiki:    command: ~/AppData/Local/hermes/...
  fleet:   command: ~/AppData/Local/hermes/...
```

### 2.3 Explicit `enabled` flag
```yaml
# ✅ Both servers should have explicit enabled
mcp_servers:
  wiki:
    command: "..."
    enabled: true
  fleet:
    command: "..."
    args: ["...", "--accept-hooks"]
    enabled: true
```

### 2.4 Check `mcp_discovery_timeout`
```yaml
# In config.yaml (top-level, not under mcp_servers)
mcp_discovery_timeout: 5.0   # recommended minimum; 1.5 is tight
```
If either server has cold-start overhead (pycache purge, startup ping, 10s delay), the discovery timeout must be generous enough to cover it.

### 2.5 Env var passthrough
```yaml
# Check: are API keys/tokens that the server needs explicitly listed?
mcp_servers:
  server:
    command: "..."
    env:
      ZEROENTROPY_API_KEY: "ze_..."   # ✅ explicit
      # Don't rely on shell env — MCP sandbox filters it (FM #6)
### 2.5 Env var passthrough

## Phase 3: Server Code Review (5 min)

### 3.1 Stale pycache protection
```python
# ✅ AT MODULE LEVEL, before any imports from local modules:
import sys, shutil, pathlib
sys.dont_write_bytecode = True
_cache = pathlib.Path(__file__).parent / "__pycache__"
if _cache.exists():
    shutil.rmtree(_cache, ignore_errors=True)
```

### 3.2 Health check uses fast flag
```python
# ✅ Use --cb-status or equivalent (instant, no warmup)
# ❌ Avoid --status or similar that triggers full initialization
subprocess.run([sys.executable, SCRIPT, "--cb-status"],
    capture_output=True, text=True, timeout=20)
```
Check: Does the health check spawn a subprocess? If yes, does it pass `--cb-status` or similar fast flag?

### 3.3 Zero-cost `{server}_ping` liveness probe
```python
# ✅ Each server should have a tool like this (no I/O, no subprocess)
@mcp.tool()
def fleet_ping() -> str:
    \"\"\"Fast liveness check. Returns current health state.\"\"\"
    return "pong" if _is_healthy() else "unhealthy"
```
Check: If server has only one ping-style tool, it's adequate. If it has none, add one.

### 3.4 Subprocess env augmentation
```python
# ✅ AT MODULE LEVEL, before any subprocess.run() calls:
_CUSTOM_BIN = str(Path.home() / "AppData/Local/hermes/hermes-agent/venv/Scripts")
_ENV = {**os.environ, "PYTHONUNBUFFERED": "1"}
if _CUSTOM_BIN not in _ENV.get("PATH", ""):
    _ENV["PATH"] = f"{_CUSTOM_BIN};{_ENV.get('PATH', '')}"

# Then pass env=_ENV to every subprocess.run() (FM #6)
```
Check: Does the server spawn subprocesses? If yes, is `env=_ENV` passed to every `subprocess.run()` call?

### 3.5 Graceful shutdown
```python
# ✅ atexit.register cleans up resources
@atexit.register
def _shutdown():
    # close DB connections, kill child procs, flush state, etc.
```
Check: If the server has persistent resources (DB connections, subprocesses, file handles), is there an `atexit` handler?

### 3.6 STATUS_TIMEOUT consistency
```python
# ✅ Value matches config expectations
STATUS_TIMEOUT = 20   # seconds
MAX_RETRIES = 0       # health checks: no retry
```
Check: Is the timeout long enough for the real workload? Has it drifted across debugging iterations (15→5→20)?

### 3.7 Singleton lock pattern (Failure Mode #14)
```python
# ✅ CORRECT — uses WaitForSingleObject
if sys.platform == "win32":
    handle = ctypes.windll.kernel32.CreateMutexW(None, False, name)
    result = ctypes.windll.kernel32.WaitForSingleObject(handle, 0)
    if result == 0x00000102:  # WAIT_TIMEOUT
        sys.exit(0)

# ❌ WRONG — fails on abandoned mutexes (see FM #14)
handle = ctypes.windll.kernel32.CreateMutexW(None, True, name)
if ctypes.GetLastError() == 183:  # ERROR_ALREADY_EXISTS
    sys.exit(0)
```
Check: If using Windows named mutex, does it use `WaitForSingleObject` (correct) or `GetLastError() == ERROR_ALREADY_EXISTS` (broken)?

## Phase 4: Triage & Prioritization

| Priority | Signal | Action |
|----------|--------|--------|
| 🔴 Critical | MCP reports UNHEALTHY, tools unavailable | Kill stale processes, fix health check flag, `/new` |
| 🔴 Critical | 4+ stale instances accumulating | Kill all, pin python paths, `/new` |
| 🟡 High | Double-spawn from `command: python` | Pin to explicit path, kill stale, `/new` |
| 🟡 High | Named mutex uses `ERROR_ALREADY_EXISTS` instead of `WaitForSingleObject` | Patch to use WaitForSingleObject (FM #14), kill stale mutex, restart |
| 🟡 High | No `{server}_ping` liveness probe | Add one (2 lines of code) |
| 🟡 High | `mcp_discovery_timeout` < 3s | Bump to 5s |
| ⚪ Medium | Path style inconsistency | Normalize (both → forward slashes) |
| ⚪ Medium | Missing `enabled: true` flag | Add it for consistency |
| ⚪ Low | No atexit shutdown handler | Add one if server has persistent resources |
| ⚪ Low | Subprocess env not augmented | Add augmentation if server spawns subprocesses |

## Phase 5: Verify

```bash
# After fixes, verify clean MCP state
# Primary: check PID files
ls ~/AppData/Local/hermes/run/ 2>/dev/null
# Expected: one .pid file per server (fleet-mcp-server.pid, wiki-mcp-server.pid)

# Secondary: wmic process count (should match PID file count)
wmic process where "CommandLine like '%%fleet-mcp%%'" get ProcessId /format:csv 2>/dev/null | grep -cE "^[0-9]"
# Expected: 1 (one fleet server)

wmic process where "CommandLine like '%%wiki-mcp%%'" get ProcessId /format:csv 2>/dev/null | grep -cE "^[0-9]"
# Expected: 1 (one wiki server)

# Test fast health probe
cd "$LOCALAPPDATA/hermes/scripts"
python fleet-manager.py --cb-status
# Expected: All breakers CLOSED, returns in <3s
```

---

*Created from sessions of 2026-07-01 (fleet and wiki MCP audit) and 2026-07-02 (Windows named mutex WAIT_ABANDONED fix — FM #14).*
