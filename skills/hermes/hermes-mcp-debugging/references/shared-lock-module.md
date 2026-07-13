# Shared MCP Lock Module (`_mcp_lock.py`)

Created 2026-07-03 to replace ~100 lines of duplicate lock code per server with 3 lines. Solves the WMIC orphan cleanup bug and cross-interpreter singleton enforcement.

## Architecture

The module provides two functions used in every MCP server:

```
acquire_singleton_lock(ident: str)    # Exits with code 1 if another instance holds lock
release_lock()                         # Registered via atexit at import time
```

### Lock mechanisms by platform

| Platform | Mechanism | Notes |
|----------|-----------|-------|
| Windows | `CreateMutexW` + `GetLastError()` + `WaitForSingleObject` | Uses `bInitialOwner=True` to close the race window. Cross-interpreter safe (venv vs uv Python). Handles abandoned mutexes from crashed previous owners. |
| Linux/macOS | `fcntl.flock()` | Standard POSIX advisory lock on `~/run/{ident}.lock` |

### Stale lock cleanup

Before acquiring the lock, `_check_stale_lock()` reads the `.lock` file and checks if the stored PID is alive using `tasklist` on Windows (not `wmic` — avoids the `_` wildcard pitfall). Dead lock files are removed before the lock attempt.

```python
if os.name == "nt":
    result = subprocess.run(
        ["tasklist", "/FI", f"PID eq {pid}", "/NH"],
        capture_output=True, text=True, timeout=5,
    )
    if "No tasks" in result.stdout:
        lock_path.unlink(missing_ok=True)
```

`tasklist` is preferred over `wmic` because:
- No wildcard parsing issues (no `_` single-char wildcard)
- Returns in ~50ms vs wmic's 2-5s
- Deterministic output — no CSV parsing needed

### Retry in lock acquisition

When `CreateMutexW` returns `ERROR_ALREADY_EXISTS`, the module retries `WaitForSingleObject` up to 3 times with backoff (100ms, 200ms, 400ms). This covers the kernel cleanup window after a previous owner crashes or is killed.

## Usage

```python
# In your MCP server, at the top of main():
from _mcp_lock import acquire_singleton_lock, release_lock

def main() -> None:
    acquire_singleton_lock("my_server_ident")
    # ... parse args, create server, run ...
    asyncio.run(mcp.run_stdio_async())
# release_lock is registered via atexit at import time — no manual registration needed
```

**Important:** `release_lock` is registered via `atexit.register()` at the module level when `_mcp_lock.py` is imported. Do NOT register it again in your server — it would run twice (harmless, but wasteful).

## What it replaces

Before `_mcp_lock.py`, every MCP server had:
- ~40 lines of Windows lock code (CreateMutexW + GetLastError + WaitForSingleObject)
- ~20 lines of POSIX lock code (fcntl.flock)
- ~40 lines of WMIC-based orphan cleanup (the buggy version with `_` wildcard)
- Shared lock constants (_LOCK_IDENT, _LOCK_DIR, etc.)
- Two function definitions (_acquire_lock, _release_lock)
- atexit.register call

That's ~100 lines per server × 3 servers = 300 lines of identical, hard-to-test code. Now:
- 1 shared module (~150 lines total)
- 1 import line per server
- 1 call to `acquire_singleton_lock()` per server

## Pitfalls

- **`__file__` reference at module level:** The ident passed to `acquire_singleton_lock()` is a plain string, not derived from `__file__`. This avoids the `__file__` crash in atexit handlers.
- **Don't double-register:** `release_lock` is already registered via `atexit` in the module. Calling `atexit.register(release_lock)` in your server runs it twice — harmless on Windows (CloseHandle on released handle returns error) but wasteful.
- **Windows named mutex cleanup:** The module cleans up both the kernel handle AND the `.lock` file on exit. If the process crashes, the kernel auto-releases the mutex and `_check_stale_lock()` handles the stale `.lock` file on next startup.
