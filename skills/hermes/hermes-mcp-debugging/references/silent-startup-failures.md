# Silent MCP Server Startup Failures (Exit 1, No Output)

When a Python MCP server exits with code 1, empty stdout, and empty stderr:

## Root Cause Pattern

The MCP protocol uses **stdin for input, stdout for JSON-RPC output**. Stderr is the only usable channel for normal logging. But if the failure happens *before* the MCP framework starts (e.g., in lock acquisition, orphan cleanup, or early imports), **even stderr may be empty** — the process dies before any Python code runs to completion.

## Diagnostic Procedure

### 1. Isolate via importlib

Run the script's components directly, skipping the MCP runtime:

```python
import os, sys
import importlib.util

sys.path.insert(0, '/path/to/scripts')
spec = importlib.util.spec_from_file_location('_m', '/path/to/scripts/server.py')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

# Test lock acquisition
try:
    mod._acquire_lock()
    print('Lock OK')
    mod._release_lock()
except SystemExit as e:
    print(f'Lock FAILED: exit({e.code})')
except Exception as e:
    print(f'Lock ERROR: {e}')

# Test server creation (after lock)
mod._acquire_lock()
mcp = mod.create_wiki_server('/path/to/vault')  # or whatever factory
print(f'Server name: {mcp.name}')
mod._release_lock()
```

### 2. Add File-Based Debug Trace

Since stdout/stderr are unreliable (MCP owns them), write to a physical file:

```python
with open("C:/Users/<user>/mcp_debug.log", "w") as f:
    f.write("step1\n")
```

Place these progressively through `main()`. The last written line pinpoints where the failure occurs.

### 3. Check Each Failure Point

| Stage | What to check | Symptoms |
|-------|---------------|----------|
| **Orphan cleanup** | `wmic process where "name='python.exe' and commandline like '%IDENT%'"` | May match & kill current process if IDENT accidentally matches script path. Check `_LOCK_IDENT` vs script filename (underscores vs hyphens matter in WMIC `like`) |
| **Orphan cleanup** (wmic `_` wildcard) | WMIC's `LIKE` treats `_` as a single-char wildcard (same as SQL). `%wiki_mcp_server%` matches `wiki-mcp-server.py` because `_` matches `-` | **Root cause of 2026-07-03 debug session.** The wmic query `like '%wiki_mcp_server%'` matched ALL python.exe processes running `wiki-mcp-server.py` — including the orphan from the previous test. When taskkill killed it, the current process (spawned from a subprocess test) also died if it was a child of the orphan. |
| **Orphan cleanup** (wmic safety) | WMIC `LIKE` wildcards: `%` = any string, `_` = any single character. `_` is NOT a literal underscore. | **Fix:** Don't use wmic for orphan detection. Use lock-file PID check instead: `tasklist /FI "PID eq {pid}" /NH` — no wildcards, deterministic, ~50ms vs wmic's 2-5s |
| **Lock: CreateMutexW returns NULL** | `handle = _kernel32.CreateMutexW(None, True, name)` → `if not handle: sys.exit(1)` | Race condition, stale orphan from killed process, or mutex name collision. Check with `Process Explorer` > Find Handle |
| **Lock: WAIT_TIMEOUT after 3 retries** | Retry backoff (100/200/400ms) exhausted | Another MCP process with same lock ident is running. `tasklist /FI "IMAGENAME eq python.exe"` to find it |
| **Missing import** | Script uses `shutil.rmtree()` but `import shutil` is missing | ImportError is swallowed if it happens before any try/except. Only importlib test catches it |
| **argparse failure** | `--vault` path doesn't exist | Should produce stderr, but if stderr isn't flushed before exit, it may be lost |

### 4. Windows Named Mutex Pitfalls

```python
# Correct import pattern (cannot use __import__ trick):
import ctypes
_kernel32 = ctypes.windll.kernel32  # NOT from ctypes.windll import kernel32 as k32

# Mutex name namespace:
mutex_name = "Local\\HermesMCP_" + ident.replace("-", "_")
# Local\ prefix = session-local; Global\ = machine-wide
# Prefer Local\ to avoid cross-session conflicts

# CreateMutexW with bInitialOwner=True:
# - Creates AND acquires ownership atomically
# - If mutex already exists, returns handle + ERROR_ALREADY_EXISTS
# - Caller must then WaitForSingleObject to check ownership
```

### 5. Orphan Cleanup WMIC Query Safety

The orphan cleanup should never match the current process. Key guard:

```python
current_pid = str(os.getpid())
# ... wmic query ...
if pid != current_pid:
    orphan_pids.append(pid)
```

But if `_LOCK_IDENT` happens to be a substring of the script filename (unlikely with careful naming), the wmic `like '%ident%'` can match the script path. Test with:

```powershell
wmic process where "name='python.exe' and commandline like '%wiki_mcp_server%'" get processid /format:csv
```
