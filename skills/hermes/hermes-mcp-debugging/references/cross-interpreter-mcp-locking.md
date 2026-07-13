# Cross-Interpreter MCP Locking on Windows

## Problem

Hermes may spawn duplicate stdio MCP server instances through different Python interpreters even when `config.yaml` pins an explicit command. In observed failures, one process ran from the Hermes venv Python while another ran from uv-managed Python. Both executed the same MCP server script.

A singleton implemented with `msvcrt.locking()` can fail in this shape because the lock may not be visible across different C runtime/interpreter combinations. Result: both MCP servers believe they own the lock, both survive, and health checks/tool calls contend.

## Symptom Pattern

- `mcp_wiki_wiki_ping` responds, but duplicate wiki server processes exist.
- `mcp_fleet_fleet_ping` responds but reports unhealthy.
- Fleet health log shows repeated `fleet-manager.py --cb-status` timeouts.
- Direct terminal run of the same `fleet-manager.py --cb-status` command returns quickly.
- Process scan shows both venv Python and uv Python variants of `fleet-mcp-server.py` / `wiki-mcp-server.py`.
- Lock files contain stale/dead PIDs or one of several live instances.

## Correct Lock Pattern

Use an OS-level lock implementation that works across interpreters, such as `portalocker` (`LockFileEx` on Windows, `flock` on POSIX), and keep the locked file handle alive for the full server lifetime.

```python
_LOCK_DIR = Path.home() / "AppData/Local/hermes/run"
_LOCK_IDENT = Path(__file__).stem
_LOCK_FILE = None  # keep handle alive; path alone is not enough


def _acquire_lock() -> None:
    global _LOCK_FILE
    _LOCK_DIR.mkdir(parents=True, exist_ok=True)
    lock_path = _LOCK_DIR / f"{_LOCK_IDENT}.lock"

    import portalocker

    try:
        fp = open(str(lock_path), "w")
        portalocker.lock(fp, portalocker.LOCK_EX | portalocker.LOCK_NB)
        fp.write(str(os.getpid()))
        fp.flush()
        _LOCK_FILE = fp
    except (portalocker.LockException, OSError, IOError, BlockingIOError):
        try:
            fp.close()
        except Exception:
            pass
        sys.exit(0)


def _release_lock() -> None:
    global _LOCK_FILE
    if _LOCK_FILE is not None:
        try:
            import portalocker
            portalocker.unlock(_LOCK_FILE)
            _LOCK_FILE.close()
        except Exception:
            pass
        _LOCK_FILE = None
```

## Critical Pitfall

Do **not** store only the lock path. If the file object is not retained, it may be closed or garbage-collected after `_acquire_lock()` returns, releasing the OS lock. The duplicate-prevention code will look correct but provide no long-lived protection.

Bad:

```python
_LOCK_FILEPATH = lock_path
# fp goes out of scope here; lock can be released
```

Good:

```python
_LOCK_FILE = fp
# fp remains open for the server lifetime
```

## Two-Server Triage Rule

For user's setup, the cross-interpreter double-spawn issue was tracked through three escalation levels:

**Level 1 — PID-file singleton:** Adopted 2026-07-01. Replaced wmic-based sibling killer with PID file read-then-write. Had TOCTOU race when processes spawned simultaneously.

**Level 2 — Named kernel mutex:** Adopted 2026-07-01 v2. Replaced PID files with `CreateMutexW` + `WaitForSingleObject`. Fixed the race but revealed a residual issue: the mutex can persist WAIT_TIMEOUT state across restarts even when all MCP processes are dead, blocking new servers.

**Level 3 — Combined MCP server (adopted 2026-07-02):** Merged fleet and wiki MCP servers into a single `hermes-mcp-server.py` with one lock identity. No cross-server contention, no race, no persistent stale state. See `references/combined-mcp-server-pattern.md`.

**Threshold crossed:** When the named kernel mutex returned WAIT_TIMEOUT with zero live MCP processes (confirmed via os.kill(pid, 0) on all PIDs), the single-server approach was no longer chasing symptoms. The merge was the right call.