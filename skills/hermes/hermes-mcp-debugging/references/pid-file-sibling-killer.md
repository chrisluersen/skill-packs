# PID-File Sibling Killer — Reproduction & Rationale

> **⚠️ SUPERSEDED (2026-07-01 v2):** The PID-file approach described here had a TOCTOU race — both instances could read "no PID file", both write, both survive. See the main SKILL.md for the current `msvcrt.locking()` file-lock singleton which is truly atomic. This reference is preserved as historical context for the wmic→PID-file evolution.

Adopted 2026-07-01 after the wmic-based approach caused a silent RC=1 hang cascade.

## The Failure

### Symptom

MCP server script (`fleet-mcp-server.py`) exited with RC=1 immediately on startup. No stderr output. No traceback. Debug prints showed the script reached `_kill_sibling_instances()` but never passed it.

### Reproduction

```
$ python fleet-mcp-server.py --accept-hooks
$ echo $?  # → 1 (no output, no stderr)
```

Adding debug prints at every section of the script showed:
- Imports OK
- Pycache purge OK
- FastMCP import OK
- FastMCP instantiation OK
- Tool registration OK
- `if __name__ == "__main__":` entered OK
- `_kill_sibling_instances()` called... but never returned
- Script exited with RC=1

### Root Cause

The wmic-based sibling killer hung:

```python
subprocess.run(
    ["wmic", "process", "where",
     'name like "%python%"',
     "get", "commandline,processid", "/format:csv"],
    capture_output=True, text=True, timeout=10,
)
```

On this system (Windows 10, 5600X/16GB, with 190+ python processes from Hermes venv, uv Python, and various tools), `wmic` took 5-10+ seconds for this query. The 10-second timeout sometimes triggered, causing the `except` handler to silently return — but the damage was done: Hermes' MCP discovery timeout (1.5s) had already fired, and the MCP connection was never established.

### Why wmic Fails for This Use Case

1. **Subprocess fork** — every call spawns a full WMI process
2. **Fragile CSV parsing** — `line.split(",")` on CSV where paths may contain commas
3. **Self-kill risk** — if CSV parsing misidentifies which process is "self", the server kills itself
4. **Scales poorly** — more python processes on the system = slower wmic query
5. **Noisy** — returns ALL python processes, must filter by script name

## The Fix: PID File Approach

Replaced wmic scanning with a simple PID file:

```python
_PID_DIR = Path.home() / "AppData/Local/hermes/run"
_SCRIPT_IDENT = Path(__file__).stem


def _kill_sibling_instances() -> None:
    ident = _SCRIPT_IDENT
    current_pid = os.getpid()

    _PID_DIR.mkdir(parents=True, exist_ok=True)
    pid_file = _PID_DIR / f"{ident}.pid"

    if pid_file.exists():
        try:
            old_pid = int(pid_file.read_text().strip())
        except (ValueError, OSError):
            old_pid = None

        if old_pid and old_pid != current_pid:
            try:
                os.kill(old_pid, 0)  # instant liveness check
                os.kill(old_pid, signal.SIGTERM)
                time.sleep(0.5)
            except (OSError, ProcessLookupError):
                pass

    try:
        pid_file.write_text(str(current_pid))
    except OSError:
        pass
```

### Pitfall: `__file__` in atexit handlers

The first version of `_cleanup_pid()` used `Path(__file__).stem` directly:

```python
@atexit.register
def _cleanup_pid():
    ident = Path(__file__).stem  # ← crashes! __file__ undefined during atexit
```

Fix: store the ident at module level (`_SCRIPT_IDENT = Path(__file__).stem`) where `__file__` is still valid, and reference it from `_cleanup_pid`.

### Files Updated (2026-07-01)

| File | Change |
|------|--------|
| `fleet-mcp-server.py` | Replaced wmic `_kill_sibling_instances()` with PID-file version |
| `wiki-mcp-server.py` | Same replacement in `main()` entry point |
| `hermes-mcp-debugging` (skill) | Updated v1.1.0 → v1.2.0, all references to wmic approach replaced |

## Verification

Both servers tested post-fix:
```
$ python fleet-mcp-server.py --accept-hooks
→ RC=0, proper initialize response, no stderr

$ python wiki-mcp-server.py --vault ~/agent-wiki
→ RC=0, proper initialize response, no stderr
```
