---
name: hermes-mcp-debugging
description: "Debug MCP servers in Hermes — lifecycle, diagnostics, common failures, Windows fixes. Companion to native-mcp."
version: 1.11.0
author: Hermes Agent
license: MIT
platforms: [windows, linux, macos]
metadata:
  hermes:
    tags: [MCP, Debugging, Operations, Windows]
    related_skills: [native-mcp, fleet-health-watchdog]
created_from_user_sessions: true
---

# Hermes MCP Debugging & Operations

Hard-won knowledge from running MCP servers in Hermes on Windows — fleet-manager, wiki, and gbrain integrations. Covers what breaks, why, and how to fix it.

Companion to `native-mcp` (basic configuration and setup). This skill covers **debugging** — the failure modes you only discover after running MCP servers for a while.

## How MCP Works in Hermes

### Lifecycle

1. Hermes reads `mcp_servers` from `$HERMES_HOME/config.yaml` (`~/AppData/Local/hermes/AppData/Local/hermes/config.yaml`) at startup
2. Spawns each server as a long-lived subprocess (stdin/stdout for stdio transport)
3. Calls `list_tools()` to discover available tools
4. Registers them as `mcp_{server_name}_{tool_name}` (hyphens → underscores)
5. Connections persist for the lifetime of the agent process
6. Auto-reconnection with exponential backoff on drop (up to 5 retries)

### Critical: Sessions and Processes

- **`/new` does NOT kill MCP subprocesses.** They persist across sessions. New sessions spawn additional server instances, accumulating orphans.
- **`/reload-mcp`** is preferred for code changes — but old processes may survive if they weren't started by the current Hermes instance.
- **MCP server code loaded into memory at spawn time.** Patched code on disk =/= running code. Old `.pyc` bytecode in `__pycache__/` can also cause stale code execution.

### Cross-Profile MCP Configs

Every Hermes profile (`~/.hermes/profiles/<name>/config.yaml`) has its own `mcp_servers` section. When you switch profiles (e.g. `hermes -p klio`), the new profile spawns its own MCP servers — old ones from the previous profile persist.

**Symptoms of stale cross-profile configs:**
- MCP server count exceeds expected (2 per server × N profiles)
- Wiki MCP server referencing a vault path that no longer exists (vault renamed)
- Health checks passing but tool calls failing (server connects to a stale DB or path)

**Detection:**
```bash
# Check every profile's MCP config
for p in ~/AppData/Local/hermes/profiles/*/; do
  echo "=== $(basename $p) ==="
  grep -A 5 "mcp_servers:" "$p/config.yaml" 2>/dev/null
done
```

**Audit findings (2026-07-01):** 8 non-default profiles (artemis through vesta) all define a wiki MCP server pointing to `C:/agent-vault` — the old vault path before it was renamed to `~/agent-wiki`. These aren't active during default profile use, but would fail with "vault path does not exist" if profile-switched.

**Prevention:** After renaming or relocating any resource (vault, DB, API endpoint) referenced by MCP configs, audit ALL profiles — not just the active one. A `grep -r` across the profiles directory catches stale paths.

### Process Management

```bash
# Check active MCP servers via lock files
ls -la ~/AppData/Local/hermes/run/ 2>/dev/null || echo "No MCP lock files"

# Content of each lock file (shows PID of the lock holder)
cat ~/AppData/Local/hermes/run/*.lock 2>/dev/null

# Verify whose lock is alive — use Python os.kill(pid, 0)
# (git-bash `kill -0` does NOT reliably work on Windows processes)
python3 -c "
import os
from pathlib import Path
lock_dir = Path.home() / 'AppData/Local/hermes/run'
for f in sorted(lock_dir.glob('*.lock')):
    pid = int(f.read_text().strip())
    try:
        os.kill(pid, 0)
        print(f'  {f.stem}: PID {pid} RUNNING')
    except OSError:
        print(f'  {f.stem}: PID {pid} DEAD (stale lock)')
"

# List all MCP processes via wmic
# ⚠️ Pitfall: wmic can briefly show zombie/phantom entries for processes that
# have already exited (os.kill SIGTERM or taskkill succeeded). Always cross-check
# against lock file PIDs. A phantom wmic entry with no matching lock file PID
# is a ghost — safe to ignore.
wmic process where "CommandLine like '%%mcp%%'" get ProcessId,CommandLine /format:csv 2>/dev/null | grep -E "[0-9]{4,}"

> 🔍 See `references/wmic-phantom-entries.md` for the full diagnostic pattern — how to distinguish real processes from WMI cache ghosts.

### The Security Sandbox

MCP subprocesses inherit a **filtered** environment — only safe baseline vars (PATH, HOME, USER, etc.). API keys, tokens, and custom bin directories are excluded. This breaks subprocess-spawning MCP servers (see Failure Mode #6).

Always pass required variables via the config.yaml `env:` key, not shell env.

## Reference Files

- `references/mcp-audit-checklist.md` — Reusable audit framework for evaluating any MCP setup against all failure modes and best practices. Covers live-process inspection, config analysis, server code review, and issues triage. Use before commissioning a new server or investigating a persistent problem.
- `references/windows-process-killing-hierarchy.md` — Empirical hierarchy of Windows process killing methods for Hermes-spawned MCP servers (`kill` → `wmic` → `taskkill` → `os.kill()`). Full reproduction transcript from 2026-07-01 session where 6 stale processes resisted all conventional methods.
- `references/pid-file-sibling-killer.md` — Full reproduction transcript of the wmic-hang → silent-RC-1 failure cascade and the PID-file alternative adopted 2026-07-01. Includes exact code for both fleet and wiki servers.
- `references/combined-mcp-server-pattern.md` — Architecture for merging multiple MCP servers into a single process. Resolves cross-interpreter double-spawn and named-mutex persistence issues by eliminating the multi-server architecture entirely.
- `references/silent-startup-failures.md` — Diagnostic procedure for MCP servers that exit code 1 with no output (lock acquisition, orphan cleanup, missing imports, Windows named mutex pitfalls).
- `references/startup-retry-pattern-diagnosis.md` — Diagnostic workflow for MCP server startup retry failures. Covers log pattern analysis, test-spawn verification, orphan process detection by Python interpreter, and the 0ms WaitForSingleObject timeout fix.
- `references/shared-lock-module.md` — The `_mcp_lock.py` shared singleton lock module: how it works, usage, and why it replaces wmic-based orphan cleanup. Created 2026-07-03.

## Quick Diagnostic Commands

```bash
# 1. Check lock files for live MCP servers
ls -la "$LOCALAPPDATA/hermes/run/" 2>/dev/null || echo "No lock files (no MCP servers running)"

# 2. Test fleet-manager health (should be <1s)
cd "$LOCALAPPDATA/hermes/scripts" && python fleet-manager.py --cb-status

# 3. Test fleet-manager status
python fleet-manager.py --status

# 4. Check pycache age (stale bytecode indicator)
ls -la "$LOCALAPPDATA/hermes/scripts/__pycache__/" 2>/dev/null

# 5. Test from MCP server's perspective (simulate filtered env)
python -c "
import subprocess
result = subprocess.run(['python', 'fleet-manager.py', '--cb-status'],
    capture_output=True, text=True, timeout=30,
    env={'PATH': '/usr/local/bin:/usr/bin:/bin', 'HOME': '~/AppData/Local/hermes'})
print(result.stdout[:200] if result.stdout else result.stderr[:200])
"

# 6. Check config.yaml for MCP entries (live config, not backed-up copy)
grep -A 10 "^mcp_servers:" "$LOCALAPPDATA/hermes/config.yaml"
```

## MCP Server Unresponsive Diagnosis

**Symptom:** MCP wiki tools return `"Unknown tool: mcp_wiki_search_wiki"` repeatedly. Tools are not registered.

**Root cause candidates:** MCP server process died, config.yaml missing entries, network issues, server startup failure.

**Fallback workflow when MCP tools fail:**
1. **Don't retry the same MCP tool** — if `mcp_wiki_search_wiki` fails twice with "Unknown tool", the MCP server is down
2. **Fall back to filesystem tools immediately:** Use `search_files` and `read_file` instead of wiki MCP tools
3. **Verify server status after the session:** Check PID files, restart if needed, but complete current work via fallback

**Diagnostic sequence:**
```bash
# Check if MCP servers are running
ls "$LOCALAPPDATA/hermes/run/" 2>/dev/null

# If no PID files, MCP servers are not running
# Check config for MCP entries
grep -A 5 "mcp_servers:" "$LOCALAPPDATA/hermes/config.yaml"

# Test server health manually (if processes exist)
cd "$LOCALAPPDATA/hermes/scripts" && python wiki-mcp-server.py --health 2>/dev/null
```

**Immediate fallback pattern:**
- `mcp_wiki_search_wiki` → `search_files(pattern="...", path="~/agent-wiki")`
- `mcp_wiki_read_wiki_page` → `read_file(path="~/agent-wiki/...")`
- `mcp_wiki_list_wiki_pages` → `search_files(target="files", pattern="*.md", path="~/agent-wiki")`

## Failure Mode Index

| # | Failure Mode | Key Symptom | Quick Fix |
|---|-------------|-------------|-----------|
| 1 | Stale process accumulation | 4+ MCP instances, tools timeout | Kill all, purge pycache, /new |
| 2 | Health check timeout loop | Connected but UNHEALTHY, --cb-status works | Use --cb-status, not --status |
| 3 | Concurrent health check contention | --cb-status times out from MCP but not terminal | Kill stale instances, keep 1 server |
| 4 | `command: python` double-spawn | 2× expected server count | Pin to explicit python path |
| 5 | Stale `.pyc` bytecode | Patched code doesn't take effect | Purge __pycache__ |
| 6 | Filtered env breaks subprocesses | MCP tool spawns scripts that hang | Augment PATH in Python code |
| 7 | Native binary stdio failure | .exe works interactively, fails as MCP | Python FastMCP wrapper |
| 8 | Dual MCP for same data source | PGLite lock conflicts, hanging tools | Single MCP server per source |
| 9 | Stale PGLite postmaster.pid | gbrain query hangs | Remove lock files |
| 10 | `hermes config set` silent failure | Config changes don't stick | Verify by reading file |
| 11 | **wmic hang / `_` wildcard → RC=1 (FIXED)** | `_mcp_lock.py` deployed 2026-07-03 — no wmic at all | Lock-file PID check via `tasklist` + named mutex |
| 12 | **ClosedResourceError — MCP connection lost** | Both `fleet_ping` and `wiki_ping` return `ClosedResourceError` | Clean stale PID files, purge pycache, verify fix on disk → user must restart (this session can't reload its own MCP) |
| 13 | **Health check thread silent death** | Server responds to `fleet_ping` but never recovers from UNHEALTHY; health log timestamp never updates | Wrap tick in try/except; use always-transition (heartbeat) state machine |
| 14 | **Windows named mutex: race window with `bInitialOwner=False`** | Two MCP instances both survive startup; mutex was created unowned, racing on WaitForSingleObject | Use `bInitialOwner=True` + `GetLastError()` + `WaitForSingleObject` — closes the race |
| 15 | **`import ctypes.windll.kernel32 as k32` runtime crash** | `ModuleNotFoundError: No module named 'ctypes.windll.kernel32'; 'ctypes.windll' is not a package` at server startup | Use `import ctypes; k32 = ctypes.windll.kernel32` instead |
| 16 | **MCP tool reads files redundantly from disk** | Tool calls slow on large wikis; content already in FTS5 index | Use indexed FTS5 content column instead of rglob + read_text |
| 17 | **WMIC `_` wildcard — orphan cleanup kills wrong processes** | Exit code 1, empty output | **FIXED v7** — `_mcp_lock.py` replaces wmic; see FM#11 |
| 18 | **Shutdown Handler Failures — `atexit` + wrong function name — silently crash startup** | Server exits with zero stderr; Hermes shows retry loops | Add `import atexit` AND match `release_lock()` to `_mcp_lock.py` exports — audit ALL servers |
| 19 | **`args` as JSON string instead of YAML list - StdioServerParameters validation error** | `1 validation error for StdioServerParameters` at connect; 3 retry loops then abandoned | Convert `args` from JSON string to proper YAML list. Verify with `hermes mcp test <name>` |
| 20 | **Cross-interpreter MCP orphan holds lock, serves old code** | Health check returns exit=1 despite patched code. Terminal test of same subprocess returns exit=0. Lock file PID belongs to a DIFFERENT Python interpreter than config.yaml `command:`. | Kill ALL MCP processes across all interpreters, clear lock, restart. See `references/cross-interpreter-mcp-orphan.md`. |

---

## Failure Mode Details

### 1. Stale MCP Process Accumulation

**Symptom:** Multiple MCP server instances (4, 8, 12+). Tools time out or return errors. `wmic` shows server processes with different CreationDate timestamps.

**Root cause:** Every `/new` spawns fresh MCP subprocesses without killing the previous ones. Over hours of work, orphans accumulate. Each one runs health checks, subprocess calls, and resource contention against the same targets.

**Resolution — Windows process killing hierarchy (use in this order):**

Methods are listed from simplest to most reliable. Earlier methods may fail against Hermes-spawned MCP processes — the later method (`os.kill` from `execute_code`) is the **only reliably successful approach** confirmed across multiple sessions.

```bash
# Step 0: Identify stale MCP processes
wmic process where "CommandLine like '%%fleet-mcp%%'" get ProcessId /format:csv 2>/dev/null
```

**Method 1 — `taskkill /F` via cmd.exe (fragile):**
```bash
# MUST run via raw cmd.exe — MSYS/git-bash eats /F as F:/
cmd.exe /c "taskkill /F /FI \"COMMANDLINE eq *fleet-mcp*\" 2>nul"
```
Pitfall: MSYS translates `/F` to `F:/`. Even `//F` (MSYS escape) can fail for complex filter strings. Use `cmd.exe /c` with quotes to avoid MSYS path mangling entirely.

**Method 2 — `wmic terminate` per-PID (partial — sometimes fails):**
```bash
wmic path Win32_Process where "Handle='<PID>'" call terminate
```
Pitfall from 2026-07-01 session: Returns `ReturnValue = 2147749911 (Invalid query)` for some process contexts. Unknown root cause — possibly related to permissions or process tree depth on Hermes-spawned subprocesses. Successfully killed some but not all.

**Method 3 — `os.kill(pid, signal.SIGTERM)` from Python (MOST RELIABLE):**
```python
import os, signal, subprocess
# Get PIDs
r = subprocess.run(['wmic', 'path', 'Win32_Process', 'where',
    "name='python.EXE' AND CommandLine like '%%fleet-mcp%%'",
    'get', 'ProcessId'], capture_output=True, text=True, timeout=10)
pids = [int(line.strip()) for line in r.stdout.split('\n')
        if line.strip().isdigit()]
# Kill each one
for pid in pids:
    os.kill(pid, signal.SIGTERM)
    print(f"Killed PID {pid}")
```
Can be run via `execute_code()` or a standalone Python script. SIGTERM (15) is cleaner than SIGKILL. Works where both `taskkill` and `wmic` fail. Confirmed across 2026-07-01 sessions.

```bash
# Step 2: Purge stale bytecode
rm -rf "$LOCALAPPDATA/hermes/scripts/__pycache__"

# Step 3: Verify clean slate
wmic process where "CommandLine like '%%fleet-mcp%%'" get ProcessId /format:csv 2>/dev/null | grep -cE "^[0-9]"
# Expected: 0

# Step 4: Start fresh Hermes session (/new)
```

**Auto-restart trap:** Hermes auto-restarts MCP processes when they die. If you kill processes one-by-one, new ones spawn before you finish. Strategy:
- Kill ALL in a single pass (Python `os.kill` loop on all PIDs)
- Or kill all, then immediately `/new` to let Hermes manage clean spawns
- Don't try to sequence kills — Hermes restarts faster than you can iterate one-at-a-time

**Prevention — Singleton via Windows named mutex (the actual deployed approach):**

The PID-file approach (adopted 2026-07-01) had a TOCTOU race — both instances could read "no PID file", both write, both survive. The durable fix uses a **Windows named kernel mutex** via ctypes for truly atomic cross-interpreter singleton enforcement. Unlike file locks, a named mutex works across different Python interpreters (venv vs uv) without any filesystem race.

The code is in `_acquire_lock()` in `hermes-mcp-server.py`. It uses `CreateMutexW` with `bInitialOwner=True` + `GetLastError()` + `WaitForSingleObject`:

```python
if os.name == "nt":
    import ctypes
    WAIT_TIMEOUT = 0x00000102
    ERROR_ALREADY_EXISTS = 0xB7
    mutex_name = "Local\\HermesMCP_" + _LOCK_IDENT.replace("-", "_")

    # bInitialOwner=True closes the race window -- creating thread
    # immediately owns the mutex. Second process sees
    # ERROR_ALREADY_EXISTS and checks ownership via WaitForSingleObject.
    handle = ctypes.windll.kernel32.CreateMutexW(None, True, mutex_name)
    if not handle:
        sys.exit(1)
    err = ctypes.windll.kernel32.GetLastError()
    if err == ERROR_ALREADY_EXISTS:
        result = ctypes.windll.kernel32.WaitForSingleObject(handle, 0)
        if result == WAIT_TIMEOUT:
            ctypes.windll.kernel32.CloseHandle(handle)
            sys.exit(0)
        # WAIT_ABANDONED: inherit ownership -- proceed
    _LOCK_HANDLE = handle
```

**⚠️ This is the 3rd iteration across 3 days -- see Failure Mode #14 for the full evolution:**
1. `CreateMutexW(None, True, name)` + `ERROR_ALREADY_EXISTS` -- failed on abandoned mutexes (Jul 1)
2. `CreateMutexW(None, False, name)` + `WaitForSingleObject` -- race window between Create and Wait (Jul 2)
3. **This version** -- `bInitialOwner=True` + `GetLastError()` + `WaitForSingleObject` for abandoned detection (Jul 3)

**On POSIX (Linux/macOS):** Falls back to `fcntl.flock()`:

```python
else:
    try:
        import fcntl
        fp = open(str(lock_path), "w")
        fcntl.flock(fp, fcntl.LOCK_EX | fcntl.LOCK_NB)
        fp.write(str(os.getpid()))
        fp.flush()
        # ...
    except (OSError, IOError, BlockingIOError):
        sys.exit(0)
```

---

### 2. Health Check Timeout Loop

**Symptom:** MCP server connects successfully (no "Failed to connect"), tools register, but health checks consistently time out. From terminal, `fleet-manager.py --cb-status` returns in ~0.16s.

**Root cause chain:**
1. MCP server's health check calls `fleet-manager.py --status`
2. `--status` triggers worker warmup — pings all 9 profiles (15s+ per profile = 135s+ hang)
3. Health check timeout fires → server reports UNHEALTHY
4. MCP client circuit breaker opens → all tool calls fail
5. On retry, same timeout cycle repeats

**Fix (in fleet-manager.py):**
- Health checks should use `--cb-status` (instant, ~0.16s, no warmup) instead of `--status`
- fleet-manager.py uses boolean skip logic for display flags:
```python
display_only = len(sys.argv) >= 2 and sys.argv[1] in (
    "--status", "--channels", "--health", "--cb-status",
    "--routing-status", "--cost-report", "--recent", "--maintenance"
)
skip_warmup = dry_run or has_flags or display_only or (len(sys.argv) < 2)
```
- Set `STATUS_TIMEOUT=45` for real dispatch calls and health checks (was 5 → 20 → 25 → 45 across iterations — cold-start `--cb-status` takes 16-30s on Windows)
- Set `MAX_RETRIES=0` for health checks — one probe, no retry

**In fleet-mcp-server.py:**
```python
# Health check instant probe
STATUS_TIMEOUT = 45  # seconds (increased from 20 after iteration — cold start on Windows takes 16-30s)
MAX_RETRIES = 0      # no retry on health check

def _check_health(self) -> bool:
    try:
        result = subprocess.run(
            [sys.executable, SCRIPT, "--cb-status"],  # ← --cb-status, not --status
            capture_output=True, text=True,
            timeout=STATUS_TIMEOUT
        )
        return result.returncode == 0
    except subprocess.TimeoutExpired:
        return False
```

---

### 3. Concurrent Health Check Contention

**Symptom:** `--cb-status` works in 0.23s from terminal but times out at 20s from MCP server's background thread. Exception log shows `'--cb-status' timed out after 20 seconds`.

**Root cause:** 8+ stale MCP server instances all running health checks simultaneously. Each one calls `fleet-manager.py --cb-status` in its own subprocess, but the fleet-manager script itself has startup overhead and potential file-lock contention on `state.json` and `FEEDBACK_LOG`.

**Resolution:** Kill stale processes (Failure Mode #1). Only one MCP server instance should exist per service entry.

---

### 4. `command: python` Double-Spawn

**Symptom:** 2× or 4× expected server count. `wmic` shows multiple process trees for the same config entry.

**Root cause:** Multiple Python interpreters on PATH (system Python, venv, uv-managed, etc.). Hermes resolves `python` independently for each interpreter found, spawning one MCP server per interpreter.

**Fix:** Pin to an explicit Python path:

```yaml
mcp_servers:
  fleet:
    command: "~/AppData/Local/hermes/AppData/Local/hermes/hermes-agent/venv/Scripts/python.EXE"
    args: ["~/AppData/Local/hermes/AppData/Local/hermes/scripts/fleet-mcp-server.py", "--accept-hooks"]
    enabled: true
```

Verify after fixing:
```bash
# Check lock files — one .lock file per server expected
ls ~/AppData/Local/hermes/run/ 2>/dev/null
# Expected: fleet-mcp-server.lock (and/or wiki-mcp-server.lock)
```

---

### 5. Stale `.pyc` Bytecode

**Symptom:** Patched code (e.g., changed `STATUS_TIMEOUT` from 5→20) doesn't take effect. Old behavior (timeouts at 5s) persists after `/reload-mcp`.

**Root cause:** Python imports compiled bytecode from `__pycache__/` before running source. If the script was patched while running, the cached `.pyc` may predate the patch. Hermes' `/reload-mcp` doesn't purge bytecode caches.

**⚠️ Conditional purge is NOT enough.** The stale-pycache protection in many MCP servers only removes `.pyc` files older than the source (by mtime). This misses a critical scenario: if Hermes spawns 2 instances simultaneously, both run the same conditional-purge logic. Both see "no stale pycache" (because both just compiled fresh `.pyc` from the patched source). But consider: the OLD `.pyc` from a prior reload was deleted, then Python re-created it. The NEW `.pyc` has the same mtime as the source (or slightly newer). The conditional check `pyc.stat().st_mtime < source.stat().st_mtime` evaluates to False → the purge does nothing → the stale code was already gone. This is fine. HOWEVER: if between reloads the source was patched (changing mtime to NOW) but the `.pyc` was written AFTER the original install (mtime = last reload time), and the new source mtime is OLDER than the `.pyc` (because `patch` preserves mtime, or the file was written at install time), the conditional check ALSO misses. The `.pyc` is treated as "fresher" and loaded instead of the patched source.

**The only reliable fix:** unconditional purge + disable bytecode writing.

```python
# At module level, before any imports from local modules
import sys
sys.dont_write_bytecode = True  # Python won't write .pyc files at all
```

Then add this at startup (after imports, before any FastMCP setup):
```python
import shutil, pathlib
_pycache = pathlib.Path(__file__).parent / "__pycache__"
if _pycache.is_dir():
    shutil.rmtree(_pycache, ignore_errors=True)  # unconditional — not conditional on mtime
```

**Key insight:** `sys.dont_write_bytecode = True` prevents Python from re-creating the `.pyc` after the purge. Without it, the first successful startup creates a fresh `.pyc`, and a subsequent `/reload-mcp` loads that fresh bytecode (which IS correct if the source wasn't changed in between). But the cycle continues — every reload writes a new `.pyc`, and if the next reload happens AFTER another patch, the `.pyc` is stale again. **The only stable fix is disabling bytecode writing entirely.**

**Fix (from terminal — emergency):**
```bash
rm -rf "$LOCALAPPDATA/hermes/scripts/__pycache__"
```

**Verification after restart:**
```bash
# If sys.dont_write_bytecode is set, __pycache__ should NOT exist after startup
ls "$LOCALAPPDATA/hermes/scripts/__pycache__/" 2>/dev/null || echo "No pycache — bytecode writing disabled"
```

**MCP-server self-diagnostic for stale bytecode:**
When debugging why a patch didn't take effect, the fastest check is to compare what the RUNNING process does vs what the source says:
```bash
# Add a unique marker to the source, reload, and check behavior
# Or: compare process behavior with terminal test of the same logic
python fleet-mcp-server.py --help  # Should fail with argparse error (source version)
# vs
# Check if --accept-hooks is recognized (old code didn't parse it)
```
The health check timeout pattern is the strongest signal: if `--cb-status` works in 0.2s from terminal but consistently times out from the MCP server, the running code probably predates the `--cb-status` fix.

---

### 6. Filtered Environment Breaks Subprocess-Spawning MCP Servers

**Symptom:** MCP server connects and registers tools. But tool calls that spawn subprocesses (e.g., `fleet_dispatch` → `fleet-manager.py`) hang silently and time out. Direct `terminal()` calls to the same script work in seconds.

**Root cause:** The MCP security sandbox passes only a baseline PATH to subprocesses. Custom bin directories (e.g., `~/AppData/Local/hermes/hermes-agent/venv/Scripts/`) are excluded. When the MCP server Python code calls `subprocess.run(["hermes", ...])` or `subprocess.run(["python", "fleet-manager.py", ...])`, the child process can't find the binary because the venv bin directory isn't on the filtered PATH.

**Detection checklist:**
- [ ] MCP server connects and registers tools ✓
- [ ] Tool calls time out with no error detail
- [ ] MCP server code spawns subprocesses to do real work
- [ ] Direct terminal call to the same script works fine
- [ ] Running MCP server script directly (`python fleet-mcp-server.py`) works fine

**Fix (in Python code — preferred):**
```python
from pathlib import Path
import os, subprocess

# MCP filters the env, but this server spawns subprocesses that need tools
# in custom bin dirs. Augment PATH before any subprocess calls.
_CUSTOM_BIN = str(Path.home() / "AppData/Local/hermes/hermes-agent/venv/Scripts")
_ENV = {**os.environ, "PYTHONUNBUFFERED": "1"}
if _CUSTOM_BIN not in _ENV.get("PATH", ""):
    _ENV["PATH"] = f"{_CUSTOM_BIN};{_ENV.get('PATH', '')}"

# Then pass env=_ENV to EVERY subprocess call:
result = subprocess.run(
    ["python", "fleet-manager.py", "--cb-status"],
    capture_output=True, text=True, timeout=45,  # match fleet-mcp-server's STATUS_TIMEOUT
    env=_ENV  # ← critical
)
```

**Fix (in config.yaml — alternative):**
```yaml
mcp_servers:
  fleet:
    command: "C:/path/to/python.exe"
    args: ["server.py"]
    env:
      PATH: "~/AppData/Local/hermes/AppData/Local/hermes/hermes-agent/venv/Scripts;%PATH%"
```

Option A (Python code) is more robust — no `%PATH%` expansion issues, works across platforms, handles multiple subprocess levels.

---

### 7. Windows Native Binary Stdio Failure

**Symptom:** A native `.exe` binary (PE32+) works fine in a terminal but fails to connect as an MCP server with "Failed to connect" and no error detail.

**Root cause:** Git-bash/MSYS2 stdio pipes don't fully bridge JSON-RPC for Windows native PE binaries. The binary starts but stdin/stdout communication fails silently.

**Fix:** Wrap the native binary in a Python FastMCP server:

```python
#!/usr/bin/env python3
"""MCP wrapper for native-tool.exe."""
import subprocess, shutil
from pathlib import Path
from mcp.server.fastmcp import FastMCP

# Resolve binary and env
TOOL = shutil.which("native-tool") or str(Path.home() / ".bun/bin/native-tool.exe")
_ENV = {**__import__('os').environ}
_ENV["PATH"] = f"{Path.home() / '.bun/bin'};{_ENV.get('PATH', '')}"

mcp = FastMCP("wrapper", instructions="...")

@mcp.tool()
def my_tool(query: str) -> str:
    result = subprocess.run([TOOL, query],
        capture_output=True, text=True, timeout=30, env=_ENV)
    return result.stdout if result.returncode == 0 else f"Error: {result.stderr}"

mcp.run(transport="stdio")
```

Wire the Python script (not the EXE) in config.yaml:
```yaml
mcp_servers:
  my-tool:
    command: "python"
    args: ["C:/path/to/wrapper.py"]
```

See `native-mcp` skill's `references/windows-native-binary-mcp-wrapper.md` and the concrete `gbrain-mcp-server.py` example at `scripts/gbrain-mcp-server.py`.

---

### 8. Dual MCP Entries for Same Data Source

**Symptom:** Random tool hangs or stale data. gbrain and wiki tools interleaving incorrectly.

**Root cause:** Two MCP server entries in config.yaml both accessing the same PGLite or SQLite database. File-level locking contention on the database file.

**Fix:** Consolidate to a single MCP server that manages the data source, embedding all tools:

```yaml
# ❌ WRONG — two servers accessing same data
mcp_servers:
  wiki:
    command: "python"
    args: ["wiki-mcp-server.py"]
  gbrain:
    command: "python"
    args: ["gbrain-mcp-server.py"]

# ✅ RIGHT — one server, all tools
mcp_servers:
  wiki:
    command: "python"
    args: ["wiki-mcp-server.py"]  # has FTS5 + gbrain tools built in
```

The wiki-mcp-server.py pattern embeds gbrain tools (query, think, doctor, brain_stats) via `subprocess.run()` — keeping a single MCP connection to manage.

---

### 9. Stale PGLite `postmaster.pid`

**Symptom:** `gbrain_query` or `gbrain_think` hangs indefinitely. `gbrain_brain_stats` returns nothing.

**Root cause:** gbrain serve or its MCP wrapper was killed uncleanly. PGLite's `postmaster.pid` lock file remains, blocking new connections.

**Fix:**
```bash
rm -f ~/.gbrain/brain.pglite/postmaster.pid
rm -rf ~/.gbrain/brain.pglite/.gbrain-lock
```

Can also recur across reboots — the lock file is on disk and persists until manually cleaned.

---

### 10. `hermes config set` Silent Failure (Windows)

**Symptom:** Changes made with `hermes config set` don't persist. The old value remains when the file is read again.

**Root cause:** `os.replace()` in Python raises `PermissionError` on Windows when the target file is open/locked by another process. Hermes has the config file open, so the write fails silently — the CLI reports success but the file wasn't actually replaced.

**Fix:**
- Always verify by reading the config file after setting: `grep "key" ~/AppData/Local/hermes/config.yaml`
- For MCP args (arrays), use JSON syntax: `hermes config set mcp_servers.<name>.args '["path/to/server.py","--flag"]'` — works for setting nested YAML lists via CLI
- `hermes mcp add` may fail silently (exit 1, no output) when the command path or args have quoting issues. Prefer `hermes config set mcp_servers.<name>.*` for reliable setup.
- For edits, use `sed -i` via terminal (e.g. `sed -i 's|old|new|' ~/AppData/Local/hermes/AppData/Local/hermes/config.yaml`) — bypasses the Python `os.replace()` issue entirely
- When inserting new lines, use sed with line numbers: `sed -i '634a\    enabled: true' ~/AppData/Local/hermes/AppData/Local/hermes/config.yaml` (read the file first to find the target line number)
- The patch tool refuses to touch Hermes config files — that's expected, not a bug. Use terminal sed instead.
- Verify every edit with `grep -A` to confirm it landed correctly

---

### 11. wmic Hang / `_` Wildcard on Startup → RC-1 (FIXED)

**Status:** Replaced wmic entirely with `_mcp_lock.py` shared lock module (2026-07-03). This failure mode should not recur.

**Historical symptom:** MCP server script exited with RC=1 immediately on startup. No stderr, no traceback. Two root causes were identified and eliminated:

**Original cause (2026-07-01):** The wmic-based sibling killer hung because `wmic process where "name like '%python%'"` took 5-10s on a busy system, exceeding the 10s internal timeout. Replaced with PID-file approach.

**Deeper cause (2026-07-03):** WMIC's `LIKE` operator treats `_` as a single-character wildcard (identical to SQL). The WQL query `commandline like '%wiki_mcp_server%'` does NOT mean "contains the literal string `wiki_mcp_server`" — it means "contains `wiki` + any character + `mcp` + any character + `server`". This matched `wiki-mcp-server.py` (with hyphens), meaning the orphan cleanup was killing ALL python processes running wiki-mcp-server, including the current process's parent or sibling.

**Fix — `_mcp_lock.py` shared lock module (2026-07-03):**

```python
from _mcp_lock import acquire_singleton_lock, release_lock

def main() -> None:
    acquire_singleton_lock("wiki_mcp_server")
    # ... rest of server ...
```

The shared module uses:
- **Lock file** PID tracking (no wmic — uses `tasklist` for PID liveness check, ~50ms)
- **Windows named mutex** via ctypes for cross-interpreter singleton enforcement
- **Retry with backoff** (100ms, 200ms, 400ms) for mutex abandonment detection
- **Stale lock cleanup** — checks if the PID in the lock file is alive, removes stale locks

This replaces ~100 lines of per-server lock code (including the buggy wmic orphan cleanup) with 3 lines. All 3 MCP servers (wiki, fleet, gbrain) use it.

See `references/shared-lock-module.md` for the full module code and `references/startup-retry-pattern-diagnosis.md` for the diagnostic workflow that led to this fix.

**Debugging heuristic (for other silent RC=1 failures):** When a script exits RC=1 with no stderr, add `sys.stderr.write` before every blocking call. The print that never appears pinpoints the hang. The fix is to remove the blocking call, not increase its timeout.

**Pitfall: `__file__` is undefined during atexit.** If `_cleanup_pid()` uses `Path(__file__).stem` inside an `@atexit.register` handler, it crashes silently -- `NameError`. atexit swallows handler exceptions, so the error is invisible. Store the ident at module level:
```python
_SCRIPT_IDENT = Path(__file__).stem  # module level
@atexit.register
def _cleanup_pid():
    pid_file = _PID_DIR / f'{_SCRIPT_IDENT}.pid'  # use stored ident
```

---

### 12. ClosedResourceError -- MCP Connection Lost

**Symptom:** Both MCP pings -- `mcp_fleet_fleet_ping` and `mcp_wiki_wiki_ping` -- fail with `ClosedResourceError`. The agent knows the MCP servers exist (tools appear in the list) but cannot communicate with them.

**Root cause:** The MCP subprocess died or was killed mid-session (orphan PID file remains). The session's MCP client connection is severed and cannot be resurrected -- Hermes' auto-reconnection retries (up to 5 with exponential backoff) apply to network drops, not to process death.

**Common trigger scenarios:**
- Stale MCP servers were killed from another session/terminal
- A prior session killed all MCP processes (e.g., to apply the sibling-killer fix)
- PID files remain from the dead processes, tricking diagnostic checks into thinking they just need a re-connect

**Prep-and-handoff workflow (Discord/remote sessions):**

When you are in a session that cannot reload MCP (no TUI), the correct workflow is:

1. **Diagnose:** Check PID files (alive or stale?), check processes, verify patched code on disk
2. **Clean:** Remove stale PID files, purge `__pycache__`, verify files parse clean
3. **Handoff:** All pre-work is done -- the user just needs to restart Hermes
4. **Delivery:** Tell the user exactly one action to take (e.g. "Ctrl+C then hermes") and what to verify after

**Do not** keep debugging after you have confirmed the fix is on disk -- you cannot apply it from inside the broken session. The only action is the restart. The session you are in is a lost cause for MCP; use filesystem fallbacks (`search_files`, `read_file`) for all wiki operations until the user restarts.

**Verification after restart:**
```bash
# Both should return instantly
mcp_fleet_fleet_ping  # -> {"pong": true, "healthy": true}
mcp_wiki_wiki_ping    # -> {"pong": true}
```

---

### 13. Health Check Thread Silent Death

**Symptom:** MCP server responds to `fleet_ping` (returns JSON with health status) but health check never recovers from UNHEALTHY state. The `health_log` shows the same old timestamp indefinitely. `--cb-status` works fine from terminal.

**Root cause:** Two issues:
1. **State machine only transitions on state change** — old pattern: `if not ok and _is_healthy():` / `elif ok and not _is_healthy():`. If the thread dies while UNHEALTHY, no tick can ever recover it. If the thread recovers after an exception, `ok=True + healthy=False` fires `elif` and transitions, UNLESS `_is_healthy()` was somehow already set back — which can't happen because only this function sets it. However: if the background thread itself crashes (daemon thread = silent exit), no further ticks fire at all.
2. **No exception barrier in background loop** — An unhandled exception in `_health_check_tick()` kills the daemon thread silently. The thread exits, the `while True` loop stops, no more health checks ever run.

**Fix — always-transition state machine:**
```python
def _health_check_tick():
    try:
        result = subprocess.run(
            [sys.executable, FLEET_MANAGER, "--cb-status"],
            capture_output=True, text=True, timeout=STATUS_TIMEOUT, env=_ENV,
        )
        ok = result.returncode == 0
        # Always transition — heartbeat even when stable
        _health_transition(ok, f"status check {'ok' if ok else 'failed'} (exit={result.returncode})")
    except Exception as e:
        # Always log — even if already unhealthy
        _health_transition(False, f"health check exception: {e}")
```

**Fix — thread-safe loop with exception barriers:**
```python
def _background_health_check():
    time.sleep(STARTUP_DELAY)
    try:
        _health_check_tick()
    except Exception:
        pass
    while True:
        time.sleep(HEALTH_CHECK_INTERVAL)
        try:
            _health_check_tick()
        except Exception:
            pass
```

Key insights:
- Daemon threads exit silently on exception — no traceback, no log
- The `while True` loop is the only thing keeping the health check running; kill that, and the server is blind
- Always-transition state machine provides a heartbeat trail in the health log — you can tell when the last check ran
- `fleet_ping` returning `{"healthy": false}` with a stale timestamp tells you the thread is dead, not the backend

---

### 14. Windows Named Mutex WAIT_ABANDONED Bug

**Symptom:** MCP server exits immediately with RC=0 and no stderr output. Lock files are written to `~/AppData/Local/hermes/run/` but the process is dead. `hermes mcp test <name>` reports `✗ Connection failed: Connection closed`.

**Root cause:** `CreateMutexW(None, True, name)` with `GetLastError() == ERROR_ALREADY_EXISTS` does NOT handle **abandoned mutexes**. When the owning process is killed (taskkill, Hermes auto-restart, crash), the named mutex object persists in the Windows kernel. A new process calling `CreateMutexW` gets a handle to the existing object, `GetLastError()` returns `ERROR_ALREADY_EXISTS`, and the code incorrectly believes another instance holds the lock — so it calls `sys.exit(0)`.

This is the mechanism behind the "MCP servers restart but immediately die" cascade:
1. Hermes spawns MCP servers at startup
2. Previous session's MCP processes are killed (or they crashed)
3. Named mutex remains in kernel with abandoned state
4. New MCP instances see `ERROR_ALREADY_EXISTS` and exit
5. Hermes sees the server died, auto-restarts it
6. Same abandonment → same exit → infinite restart loop

**Detection:**
- `hermes mcp test <name>` reports "Connection closed" after 10+ seconds
- Lock files exist but `os.kill(pid, 0)` confirms the PID is dead
- Running the server script manually produces zero output and exit code 0
- `wmic` may show phantom entries for dead PIDs (see FM#11 pitfall)

**Fix — use `CreateMutexW` with `bInitialOwner=True` + `GetLastError()` + `WaitForSingleObject`:**

```python
if os.name == "nt":
    import ctypes
    WAIT_TIMEOUT = 0x00000102
    ERROR_ALREADY_EXISTS = 0xB7
    mutex_name = "Local\\HermesMCP_" + _LOCK_IDENT.replace("-", "_")

    # bInitialOwner=True closes the race window — the creating thread
    # immediately owns the mutex. No window where two processes can
    # both call CreateMutexW before either calls WaitForSingleObject.
    handle = ctypes.windll.kernel32.CreateMutexW(None, True, mutex_name)
    if not handle:
        sys.exit(1)
    err = ctypes.windll.kernel32.GetLastError()
    if err == ERROR_ALREADY_EXISTS:
        # Mutex exists -- owned by another process OR abandoned
        result = ctypes.windll.kernel32.WaitForSingleObject(handle, 0)
        if result == WAIT_TIMEOUT:
            ctypes.windll.kernel32.CloseHandle(handle)
            sys.exit(0)
        # WAIT_ABANDONED (0x80): previous owner died, inherit ownership
    _LOCK_HANDLE = handle
```

Key changes vs the two prior iterations (this is iteration #3 across 3 days):
1. **`bInitialOwner=True`** (`CreateMutexW(None, True, name)`) -- the creating thread immediately owns the mutex. No race: when two processes spawn near-simultaneously, the first to call `CreateMutexW` wins immediately.
2. **`GetLastError()`** checks for `ERROR_ALREADY_EXISTS` -- catches the second-instance case
3. **`WaitForSingleObject(handle, 0)`** on the `ERROR_ALREADY_EXISTS` path handles abandoned mutexes:
   - `WAIT_ABANDONED` (0x80): previous owner died, we inherit ownership -- **proceed**
   - `WAIT_TIMEOUT` (0x102): another process genuinely holds it -- **exit**

Why `bInitialOwner=False` (iteration #2) had a race: With `bInitialOwner=False`, the mutex was created unowned. `WaitForSingleObject` was needed to acquire ownership. Two processes spawning near-simultaneously could both call `CreateMutexW` before either called `WaitForSingleObject`, and on Windows with git-bash subprocess spawning, both could survive through the window. The `bInitialOwner=True` approach eliminates this window entirely.

**Verification:**
```bash
hermes mcp test wiki    # ✓ Connected (1640ms)
hermes mcp test fleet   # ✓ Connected (1234ms)
```

**Lock file hygiene in `_release_lock()`:** After releasing the mutex handle, always clean up the `.lock` file written during lock acquisition. The original `_release_lock()` released the handle but left `run/hermes-mcp-server.lock` behind, which confused diagnostics (looking like a live server when there was none). Fix:

```python
# In _release_lock(), after handle/file cleanup:
if _LOCK_FILEPATH is not None:
    try:
        _LOCK_FILEPATH.unlink(missing_ok=True)
    except Exception:
        pass
    _LOCK_FILEPATH = None
```

**Residual failure mode — race window with `bInitialOwner=False` (2026-07-03):** Even with the correct `WaitForSingleObject` handling above, the second iteration (`CreateMutexW(None, False, name)`) had a race: the mutex was created **unowned**, so two processes spawning near-simultaneously could both call `CreateMutexW` before either called `WaitForSingleObject`. Both would survive through the window. This was the root cause of the two-MCP-instance double-spawn observed after the combined-server merge.

**This is now fixed** — iteration #3 (deployed 2026-07-03) uses `CreateMutexW(None, True, name)` with `bInitialOwner=True`. The creating thread immediately owns the mutex. No race. See the Fix section above for the exact code.

**Ultimate fix — the correct `bInitialOwner=True` + `GetLastError()` + `WaitForSingleObject` pattern:** The third iteration (deployed 2026-07-03) closes the race. With `bInitialOwner=True`, the creating thread immediately owns the mutex — no window for two processes to both call `CreateMutexW` before either acquires. When the second instance calls `CreateMutexW`, it gets `ERROR_ALREADY_EXISTS` and uses `WaitForSingleObject` to distinguish genuinely-held (WAIT_TIMEOUT → exit) from abandoned (WAIT_ABANDONED → inherit). See the Fix section above for the exact code.

Three iterations across three days:
- **Jul 1:** `CreateMutexW(None, True)` + `ERROR_ALREADY_EXISTS → exit` — failed on abandoned mutexes
- **Jul 2:** `CreateMutexW(None, False)` + `WaitForSingleObject` — race window, both processes could survive
- **Jul 3:** `CreateMutexW(None, True)` + `GetLastError()` + `WaitForSingleObject` — correct
- **Jul 3 (later):** Retry fix — `WaitForSingleObject(handle, 0)` with 0ms timeout is too aggressive for session transitions

**Why `msvcrt.locking()` is not used:** The MCP servers use named kernel mutex via ctypes for cross-interpreter singleton enforcement (venv vs uv Python). `msvcrt.locking()` works within a single filesystem but can't prevent two different Python interpreters from each getting the lock on the same `.lock` file. The named mutex approach is correct — it just had a bug in the second iteration's ownership test (the race from `bInitialOwner=False`).

### 14a. `WaitForSingleObject(handle, 0)` — 0ms Timeout Causes Session-Transition Failures

**Symptom:** On every new session start, the MCP server fails the first 3-4 startup attempts (silent exit, code 0), then eventually connects after ~2.5min. The mcp-stderr.log shows:

```
===== [08:44:47] starting MCP server 'hermes' =====
===== [08:44:49] starting MCP server 'hermes' =====   ← 2s later
===== [08:44:52] starting MCP server 'hermes' =====   ← 3s later
===== [08:44:57] starting MCP server 'hermes' =====   ← 5s later
[2.5 min gap with no activity]
[08:47:18] PingRequest                                 ← finally connected
```

**Root cause:** `WaitForSingleObject(handle, 0)` with **0ms timeout** is a pure non-blocking check. During the kernel cleanup window after the previous session's MCP process terminates, the named mutex may briefly be in a state where `WaitForSingleObject` returns `WAIT_TIMEOUT` — even though the old process is genuinely dead. This causes the new server to exit silently. The Hermes manager retries 3× with exponential backoff (1s, 2s, 4s) then gives up, and a separate reconnect mechanism recovers after ~2.5min.

**Detection:**
1. Run `grep -n "starting MCP server" ~/AppData/Local/hermes/logs/mcp-stderr.log | tail -10` — look for 4+ start headers in rapid succession followed by a gap
2. Test-spawn the server directly (outside Hermes) — it exits with code 0, no stdout/stderr
3. Check for orphan processes running the same command with different Python interpreters:
   ```
   wmic process where "CommandLine like '%%mcp-server%%'" get ProcessId,CommandLine
   ```
   A legitimate MCP process runs from the Hermes venv (`hermes-agent/venv/Scripts/python.EXE`). A zombie/orphan runs from a different interpreter (`uv/python/.../python.exe`).

**Fix — retry loop with backoff + logging in `_acquire_lock()`:**

Replace the single-shot `WaitForSingleObject(handle, 0)` with a retry loop that distinguishes WAIT_ABANDONED, WAIT_TIMEOUT, and unexpected results:

```python
# BEFORE (fails on session transition — pure race):
result = _kernel32.WaitForSingleObject(handle, 0)
if result == WAIT_TIMEOUT:
    _kernel32.CloseHandle(handle)
    _sys.exit(0)

# AFTER (retries with backoff + diagnostic logging):
for attempt in range(3):
    result = _kernel32.WaitForSingleObject(
        handle, 100 << attempt  # 100ms, 200ms, 400ms
    )
    if result == WAIT_ABANDONED:
        break                      # inherited ownership, proceed
    if result != WAIT_TIMEOUT:
        # Unexpected result — safe exit
        _kernel32.CloseHandle(handle)
        _sys.exit(0)
else:
    # All retries exhausted — another process holds the lock
    print(
        f"[{time.strftime('%H:%M:%S')}] "
        f"MCP lock held by another process after 3 retries, exiting",
        file=sys.stderr,
    )
    _kernel32.CloseHandle(handle)
    _sys.exit(0)
# WAIT_ABANDONED: previous owner died, we inherit ownership
```

Key changes vs the simplified version:
- `WAIT_ABANDONED` is explicitly checked — the break is intentional, not coincidental
- Non-WAIT_TIMEOUT/WAIT_ABANDONED results exit safely (belt-and-suspenders)
- Timestamped stderr message makes the failure visible in `mcp-stderr.log`

**Companion — startup orphan cleanup preflight:**

Before `_acquire_lock()` in `main()`, scan for stale MCP processes from prior sessions and kill them. This prevents orphan processes (from different Python interpreters) from holding the lock indefinitely:

```python
def main() -> None:
    # ── Orphan cleanup: kill stale MCP processes from prior sessions ──
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
    # ...
```

This detects MCP processes running under ANY Python interpreter (venv, uv, system) and kills all except the current one. Combined with the lock retry above, it handles the full session-transition edge case.

**Why the orphan cleanup matters:** The lock retry handles the kernel cleanup window (100-400ms), but it doesn't handle the case where a genuinely LIVING orphan process from a previous session holds the lock indefinitely. This happens when a previous Hermes session spawned an MCP server using a different Python interpreter (e.g., uv-managed Python instead of the Hermes venv Python), and that orphan survives because:
1. The Hermes session ends (`/new`) which kills the venv-based MCP process
2. The uv-based MCP process was spawned as a child of the venv process, not as a child of Hermes
3. When the venv process is killed, the uv child is orphaned (not killed)
4. The uv process continues running, holding the named mutex
5. The next session spawns a new venv-based MCP server — it sees `ERROR_ALREADY_EXISTS` + `WaitForSingleObject` returns `WAIT_TIMEOUT` (genuinely held by the uv orphan)
6. Even with retries, the uv orphan never releases the lock
7. All startup attempts fail silently

The preflight cleanup prevents this by killing ALL MCP processes (except current) before attempting the lock.

**Why this works:** The lock retry gives the kernel a few hundred ms to finalize stale mutex state. The orphan cleanup removes zombies that would otherwise block the lock forever. Together they cover both transient and persistent lock contention on session transition.

**Detection — orphan processes:** Check for them by comparing Python interpreters:
- Legitimate: `hermes-agent/venv/Scripts/python.EXE`
- Orphan: `Roaming/uv/python/cpython-3.11-.../python.exe`
Both run the same command line with `--vault ~/agent-wiki --accept-hooks`.

**See also:** `references/startup-retry-pattern-diagnosis.md` for the full diagnostic workflow used in the 2026-07-03 session. The reference file should be updated to match the deployed fix (WAIT_ABANDONED check + orphan cleanup).
**See also:** `references/startup-retry-pattern-diagnosis.md` for the full diagnostic workflow used in the 2026-07-03 session.

---

### 15. `import ctypes.windll.kernel32` Runtime Crash

**Symptom:** MCP server exits with `ModuleNotFoundError` immediately on startup:
```
ModuleNotFoundError: No module named 'ctypes.windll.kernel32'; 'ctypes.windll' is not a package
```

**Root cause:** `ctypes.windll` is a dynamically-created module attribute of the `ctypes` module, not an importable subpackage. `import ctypes.windll.kernel32 as k32` fails because Python's import system tries to find a *file* at `ctypes/windll/`, which doesn't exist — `windll` is created in memory by `ctypes.__init__`.

**Fix — always use the two-step import:**
```python
# ❌ WRONG — crashes at runtime
import ctypes.windll.kernel32 as k32
k32.CreateMutexW(None, False, name)

# ✅ CORRECT — works at runtime
import ctypes
k32 = ctypes.windll.kernel32
k32.CreateMutexW(None, False, name)
```

**Scope:** Affects all Windows Python MCP servers that use named kernel mutexes for singleton enforcement — `hermes-mcp-server.py`, `fleet-mcp-server.py`, `wiki-mcp-server.py`, and any `gbrain-mcp-server.py`.

**Why this bites experienced Python developers:** The pattern `import module.submodule` usually works, so `import ctypes.windll.kernel32` *looks* valid. The error only surfaces at runtime when the import is executed (often inside a `if sys.platform == 'win32'` guard). Static analysis tools and linters don't catch it because `ctypes.windll` is dynamically typed.

**Memory aid:** `ctypes.windll` is a *property*, not a *path*. You access it via dot, not via import.

---

### 16. MCP Tool Reads Files Redundantly from Disk — FTS5 Content Is Already Indexed

**Symptom:** Wiki tools (`find_related`, `suggest_edges`) take seconds per call instead of milliseconds. Each call re-reads every `.md` file from disk via `vault.rglob("*.md")` + `read_text()`, even though the full content was already indexed into the `wiki_fts` FTS5 table during `scan_and_index()`.

**Root cause:** The FTS5 content table stores the **full original text** for every column. When a tool does:

```python
# Already has content from FTS5:
cur = conn.execute("SELECT path, tags, content FROM wiki_fts")
for p, tags, content in cur.fetchall():
    page_data[p] = {"content": content, ...}

# Then REDUNDANTLY reads the same data from disk:
for p, data in page_data.items():
    full_path = vault / p
    text = full_path.read_text(encoding="utf-8", errors="replace")
    fm = parse_frontmatter(text)  # ⬅ could use data["content"]
```

This is both slow and wasteful — 450+ file reads per call, each reading 2-50KB from disk.

**Fix:** Use the `content` field from the FTS5 index directly. The `scan_and_index()` function inserts the full markdown text into `wiki_fts.content`. Subsequent tool operations should parse frontmatter and extract wikilinks from this already-loaded string instead of re-reading the file:

```python
# ✅ RIGHT — use indexed content
cur = conn.execute("SELECT path, tags, content FROM wiki_fts")
for p, tags, content in cur.fetchall():
    page_data[p] = {"content": content, ...}

for p, data in page_data.items():
    fm = parse_frontmatter(data["content"])       # no file read
    for target in extract_wikilinks(data["content"]):  # no file read
        ...
```

**Related trap — cursor exhaustion:** When you fetch indexed data with `conn.execute()` and then need to iterate through it a second time, the cursor is already exhausted. The second `cur.fetchall()` returns an empty list:

```python
# ❌ BUG — second fetch returns nothing
cur = conn.execute("SELECT path, content FROM wiki_fts WHERE path != ?", (path,))
for other_path, other_content in cur.fetchall():
    ...  # first pass works

for other_path, other_content in cur.fetchall():
    ...  # SECOND PASS RETURNS NOTHING — cursor exhausted

# ✅ FIX — cache results in a list
cur = conn.execute("SELECT path, content FROM wiki_fts WHERE path != ?", (path,))
other_pages = cur.fetchall()
for other_path, other_content in other_pages:
    ...  # first pass

for other_path, other_content in other_pages:
    ...  # second pass works — iterating a list, not a cursor
```

**Related pattern — `async def` wrapping synchronous I/O:** If an MCP tool is declared `async def` but all its I/O uses synchronous `subprocess.run()` or synchronous file reads, you gain nothing from async and actually **block the event loop**:

```python
# ❌ WRONG — async def wrapping sync I/O
@mcp.tool()
async def my_tool(query: str) -> str:
    result = subprocess.run([...], ...)  # blocks event loop
    return result.stdout

# ✅ RIGHT — sync def for sync I/O
@mcp.tool()
def my_tool(query: str) -> str:
    result = subprocess.run([...], ...)  # runs in thread pool
    return result.stdout
```

FastMCP automatically runs sync tools in a thread pool when called from an async context. Explicit `async def` is only needed when the tool itself uses `await` for true async I/O (e.g. `asyncio.create_subprocess_exec()` or `aiohttp`).

**Diagnosis — find redundant reads in MCP tools:**
```bash
# Search for tools that query FTS5 but then also read files
grep -n "rglob\|read_text" ~/AppData/Local/hermes/scripts/hermes-mcp-server.py
# Look for: vault.rglob, full_path.read_text, etc.
# Cross-reference with: conn.execute.*wiki_fts earlier in the same function
```

Three signals that a tool has this bug:
1. Queries `wiki_fts` (FTS5 index)
2. Also calls `vault.rglob()` or `path.read_text()` in the same function
3. Parser functions (`parse_frontmatter`, `extract_wikilinks`) could have used the already-fetched content

**Scope:** Applies to any MCP tool that wraps a file-indexed data source. The pattern is generic — when you have an FTS5 or other index that stores full content, use it instead of re-reading files. The `suggest_edges` and `find_related` tools in `hermes-mcp-server.py` had this issue (fixed 2026-07-03).

---

### 17. WMIC `_` Wildcard — Orphan Cleanup Kills Wrong Processes

**Symptom:** MCP server exits with code 1 and no stdout/stderr output immediately on startup. Debug trace shows the orphan cleanup ran but the process died after `taskkill`. Lock file is never written. The server is unrecoverable without a terminal kill-and-restart cycle.

**Root cause:** WMIC's `LIKE` operator treats `_` as a single-character wildcard (identical to SQL). The WQL query `commandline like '%wiki_mcp_server%'` does NOT mean "contains the literal string `wiki_mcp_server`" — it means "contains `wiki` + any single character + `mcp` + any single character + `server`". This matches `wiki-mcp-server.py` because `-` is a valid single character match for `_`.

The result: the orphan cleanup finds ALL running `python.exe wiki-mcp-server.py ...` processes — including:
- The current process (excluded by `pid != current_pid` check)
- The orphan from the previous test run
- Any other process running a wiki-mcp-server

When `taskkill /F` kills the orphan, the current process may be killed too if it's a child of the orphan (common when the test script spawns the MCP server as a subprocess — killing the orphan also kills its children).

**Detection:**
```bash
# Simulate what the orphan cleanup does — see what matches:
wmic process where "name='python.exe' and commandline like '%wiki_mcp_server%'" get ProcessId,CommandLine /format:csv
# If results include processes running wiki-mcp-server.py (with hyphens), the _ wildcard is matching
```

**Fix — use `tasklist` PID check instead of `wmic`:**

```python
# Instead of:
# wmic process where "name='python.exe' and commandline like '%ident%'"

# Use:
import subprocess
result = subprocess.run(
    ["tasklist", "/FI", f"PID eq {pid}", "/NH"],
    capture_output=True, text=True, timeout=5,
)
if "No tasks" in result.stdout:
    # PID is dead — safe to remove lock file
    lock_path.unlink(missing_ok=True)
```

`tasklist` has no wildcards, no `_` surprise, returns in ~50ms (vs wmic's 2-5s), and output is deterministic.

**Ultimate fix — use the shared lock module:**

The `_mcp_lock.py` module (see `references/shared-lock-module.md`) encapsulates this pattern: lock-file based PID checking with `tasklist` on Windows, plus named mutex cross-interpreter singleton enforcement. All 3 MCP servers now use it:

```python
from _mcp_lock import acquire_singleton_lock, release_lock

def main() -> None:
    acquire_singleton_lock("wiki_mcp_server")
    # ... rest of server ...
```

This replaces ~100 lines of per-server lock code (including the buggy wmic orphan cleanup) with 3 lines.

**Why wmic was used before:** Earlier Windows process management relied on `wmic` because it could find processes by command line content — `tasklist /FI "IMAGENAME eq python.exe"` can only filter by image name, not command line. The key insight: **you don't need to find processes by command line if you track them by PID in lock files.** The lock file approach (`~AppData/Local/hermes/run/{ident}.lock`) has the PID already — you just need to check if that specific PID is alive. `tasklist /FI "PID eq N"` is the simplest way to check.

---

### 18. Shutdown Handler Failures — `atexit` + Wrong Function Name — Silently Crash Startup

**Two related bugs** in the shutdown handler that both produce the same symptom: server exits with RC=0/1 immediately on startup, no stderr visible from Hermes' perspective. The `mcp-stderr.log` shows rapid retries (3+ start headers within 60s) with no error lines between them.

**Bug A — Missing `import atexit`:**

Running the server directly from terminal reveals `NameError: name 'atexit' is not defined` — `atexit` was never imported. Every MCP server that uses `@atexit.register` must have `import atexit` at module level.

Detection: grep for mismatch between `@atexit.register` usage and `import atexit`:
```bash
grep -c "@atexit.register" wiki-mcp-server.py fleet-mcp-server.py gbrain-mcp-server.py
# vs
grep -c "import atexit" wiki-mcp-server.py fleet-mcp-server.py gbrain-mcp-server.py
```

**Bug B — Wrong function name in shutdown handler (`_release_lock()` → `release_lock()`):**

The `_mcp_lock.py` module exposes `release_lock()` (no underscore prefix), but the shutdown handler in the MCP server scripts calls `_release_lock()` (with underscore). This is a silent `NameError` inside the `@atexit.register` handler — Python's atexit module swallows handler exceptions, making the error invisible. The server exits cleanly with RC=0 and no traceback.

Detection: running the server directly from terminal and checking exit code:
```bash
cd "$LOCALAPPDATA/hermes/scripts"
python wiki-mcp-server.py --vault ~/agent-wiki
echo "Exit code: $?"  # Shows 0 (clean exit) even though shutdown handler failed silently
```

Fix: match the function name to what `_mcp_lock.py` actually exports:
```python
# ✅ CORRECT
from _mcp_lock import acquire_singleton_lock, release_lock
# ...
@atexit.register
def _shutdown():
    release_lock()  # not _release_lock()
```

Pitfall — `atexit` + `__file__`: handlers referencing `__file__` (e.g. `Path(__file__).stem`) crash silently because atexit drops handler exceptions. Store at module level: `_SCRIPT_IDENT = Path(__file__).stem` and reference the variable in the handler.

**Systematic pattern — audit ALL servers, not just the one that failed:**

When you find this bug in one server, it exists in ALL servers that share the same codebase pattern. On 2026-07-03, both Bug A and Bug B were present in all three MCP servers (wiki, fleet, gbrain). The shutdown handler code was copy-pasted from a single template. Fix procedure:
1. Grep all MCP server scripts for `@atexit.register` → list every server that needs it
2. Grep all for `import atexit` → identify which are missing it
3. Grep all for `release_lock` → ensure the function name matches what `_mcp_lock.py` exports
4. Grep all for `_release_lock` → identify wrong-name references
5. Fix all at once — don't fix one, test, then fix the next. The pattern is systematic, not per-server.

---

## Best Practices

1. **Pin Python paths** — Always use explicit paths in `command:` to avoid double-spawn
2. **Single server per data source** — Don't split one source across multiple MCP entries
3. **Separation by failure domain** — Keep fast/deterministic servers separate from slow/spawn-heavy ones. A hung tool call blocks ALL tools on that server.
4. **PyCache purge at startup** — Add `shutil.rmtree(__pycache__, ignore_errors=True)` in MCP server init
5. **`--cb-status` for health checks** — Not `--status` (triggers full warmup)
6. **Verify config changes by reading the file** — `hermes config set` may silently fail
7. **Pass env vars in config.yaml** — Don't rely on shell env being inherited through MCP
8. **After killing stale processes** — Verify with lock files: `ls ~/AppData/Local/hermes/run/` shows one `.lock` per server, and each lock holder is alive (`kill -0 <pid>` using the PID stored in the `.lock` file).
9. **Add `fleet_ping` liveness probe** — Zero-cost, <10ms, no subprocess fork. Lets the client circuit breaker probe instantly without expensive health checks.
10. **Document STATUS_TIMEOUT values** — Fleet MCP: 45s for health check (was 20→25→45 across iterations as cold-start overhead proved higher each time). These drift during debugging sessions. Bump by a comfortable margin above measured cold-start time — 25s was borderline at ~16s cold start, 45s gives healthy headroom. Update `agent-fleet-management`'s troubleshooting table when you bump the source constant.
11. **Add a `{server}_ping` zero-cost probe to every MCP server** — Each server should expose a lightweight tool that returns instantly with no I/O (no DB query, no subprocess spawn, no file read). Example: `fleet_ping` returns `"pong"` + current `_SERVER_HEALTHY` state in <10ms. `wiki_ping` returns `{"pong": true}` in <1ms. This lets Hermes' built-in circuit breaker probe liveness without blocking on the server's real tools. If a server has multiple failure domains (fast search + slow gbrain), the probe is the only reliable way to distinguish "server is dead" from "server is busy."
12. **Validate all user-facing string inputs for empty/blank** — Every MCP tool that accepts a string from the caller should check `if not param or not param.strip():` before proceeding. An empty string passed to a subprocess (gbrain, fleet-manager) or database query will either crash or produce bad errors. Pattern:
    ```python
    @mcp.tool()
    def my_tool(query: str) -> str:
        if not query or not query.strip():
            return "**Error:** Empty query. Provide a non-blank value."
        # ... proceed with real work
    ```
13. **Singleton enforcement on startup (know your limits)** — Every MCP server must ensure only one instance runs. The fleet and wiki servers use a **Windows named kernel mutex** via ctypes (cross-interpreter atomicity). If implementing a new server, use one of:

    **Option A — Windows named mutex (preferred for Hermes MCP servers):**
    ```python
    handle = ctypes.windll.kernel32.CreateMutexW(None, True, name)
    err = ctypes.windll.kernel32.GetLastError()
    if err == 0xB7:  # ERROR_ALREADY_EXISTS
        result = ctypes.windll.kernel32.WaitForSingleObject(handle, 0)
        if result == 0x00000102:  # WAIT_TIMEOUT
            sys.exit(0)
        # WAIT_ABANDONED: inherit ownership -- proceed
    ```
    ⚠️ **This is iteration #3 — see Failure Mode #14 for the full evolution.** The pattern must use `bInitialOwner=True` to close the race window. Do NOT use `bInitialOwner=False` (creates unowned mutex → race) and do NOT use `ERROR_ALREADY_EXISTS → exit` without `WaitForSingleObject` (fails on abandoned mutexes).

    **Option B — File lock (simpler, no ctypes):**
    ```python
    fd = os.open(str(lock_path), os.O_CREAT | os.O_RDWR)
    if sys.platform == "win32":
        import msvcrt
        msvcrt.locking(fd, msvcrt.LK_NBLCK, 1)
    else:
        import fcntl
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    ```
    File locks are simpler but don't protect against two different Python interpreters (venv vs uv) each getting their own lock on the same file. Named mutex handles this correctly.

    **Option C — Merge servers (nuclear option, 2026-07-02):** When singleton enforcement persistently fails due to cross-interpreter spawning + kernel mutex handle persistence, eliminate the multi-server architecture entirely. Combine all MCP tools into a single process with one lock identity. See `references/combined-mcp-server-pattern.md`.

    **Option D — `_mcp_lock.py` shared module (preferred, 2026-07-03):** Uses lock-file PID checking with `tasklist` (no wmic, no `_` wildcard) plus Windows named mutex for cross-interpreter singleton enforcement. One import line per server. See `references/shared-lock-module.md`. Replaces Options A (raw mutex code) and the wmic-based orphan cleanup with a tested, reusable module.
14. **Heartbeat state machine for health checks** — An MCP server's health check tick should **always transition** (set healthy=True or healthy=False on every call), not just when state changes. This provides a heartbeat trail in the health log — you can tell the thread is alive even when healthy. If the state machine only fires on state change, a stuck-in-UNHEALTHY condition with a stale timestamp is indistinguishable from a dead thread. Always-transition pattern: `_health_transition(ok, f"status check {'ok' if ok else 'failed'}")`.
15. **Audit end-to-end before patching** — When debugging a persistent MCP failure, do NOT start with code changes. Start with a full-system audit: count running processes, check lock files, test the backend directly from terminal, verify which code the running process actually loaded (compare behavior vs source), then form a hypothesis. Patching without auditing produces symptom-chasing iterations that waste reloads and frustrate the user. The correct sequence: **audit → hypothesize → verify hypothesis with one targeted test → fix → verify fix**.
16. **Refactor over trace — when the problem is the dependency, replace it** — If debugging shows the root cause is a slow or broken system-level call (wmic, slow CLI, hanging subprocess), do not spend cycles tracing why it fails. The call itself *is* the problem — replace it with a direct alternative (syscall, PID file, in-process API). This is faster and produces a more reliable result than adding timeouts and retries around a fundamentally broken dependency. The heuristic: if `sys.stderr.write` before the call prints but the one after doesn't, the call is the bottleneck — remove it, don't chase it.
17. **Prep-and-handoff pattern for remote sessions** — When MCP is down in a session with no TUI (Discord, remote CLI), apply the pre-work pipeline: stale PID cleanup -> pycache purge -> code verification on disk. Once confirmed the fix is ready, hand off to the user with exactly one action step. The session you are in cannot reload its own MCP — stop debugging and switch to filesystem fallbacks for all wiki operations.
18. **`mcp_discovery_timeout` must cover cold-start overhead** — MCP servers that rebuild indexes (`scan_and_index` on FTS5) or perform heavy imports at startup need a generous discovery timeout. A 728-page wiki's FTS5 index rebuild takes ~0.7-1.5s on its own, and the full startup pipeline (Python import, lock acquisition, DB connect, index rebuild, server loop start) can exceed 2-3s. The audit-recommended minimum is 5.0s; the default 1.5s is too tight for any server with startup work. Set via `hermes config set mcp_discovery_timeout 5.0`.

## LLM Wiki MCP GitHub References

From `~/agent-wiki/llm-wiki mcp githubs.md` — LLM Wiki MCP implementations to study for patterns:

| Repo | Stars | Description | Language |
|------|-------|-------------|----------|
| [nashsu/llm_wiki](https://github.com/nashsu/llm_wiki) | 13.4k | Cross-platform desktop app. Incremental wiki from documents. MCP server at `mcp-server/`. Latest: v0.5.4 (Jun 29). | TypeScript + Rust |
| [Electro-resonance/LLM-WIKI-MCP](https://github.com/Electro-resonance/LLM-WIKI-MCP) | 19 | Local-first Markdown KB with MCP+CLI. Ingests MD/PDF/DOCX. CLI + MCP server. | Python |
| [flsteven87/llm-wiki-mcp](https://github.com/flsteven87/llm-wiki-mcp) | 1 | Karpathy-style MCP server. 4 tools (read/write/log/inventory). Atomic writes, etag CAS, path containment. | Python |
| [geronimo-iia/llm-wiki](https://github.com/geronimo-iia/llm-wiki) | 9 | Rust git-backed wiki engine with MCP. 550+ commits, 6 releases (v0.4.1). | Rust + Python |
| [lucasastorian/llmwiki](https://github.com/lucasastorian/llmwiki) | — | LLM wiki implementation | — |
| [Pratiyush/llm-wiki](https://github.com/Pratiyush/llm-wiki) | — | LLM wiki implementation | — |

Key patterns from these repos:
- **flsteven87**: Separation of MCP transport from storage backend via `WikiStorage` Protocol. Atomic writes with etag-based optimistic concurrency. Path containment against symlink escapes.
- **Electro-resonance**: Single codebase serving both CLI and MCP. SQLite FTS5 index. Configurable context budgets for LLM prompts.
- **geronimo-iia**: Rust core for performance. Feature flags over MCP — the MCP server is one of several build targets, not the whole project.
