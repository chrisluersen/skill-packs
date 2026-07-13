# Cross-Interpreter MCP Orphan — Stale Process from Different Python Interpreter Holds Lock

**Session:** 2026-07-07 — fleet health exit=1 investigation

**Discovered:** A second MCP server process from a DIFFERENT Python interpreter (uv-managed Python) was running alongside the intended process (Hermes venv Python). The uv-server held the file lock and served health checks using OLD code — making it appear that the patch hadn't taken effect.

## The Pattern

1. You apply code fixes to `fleet-mcp-server.py` and `fleet-manager.py`
2. Kill the running MCP server, clear lock, restart
3. Health checks still return exit=1
4. You verify the code is correct by running the subprocess directly from terminal — exit=0
5. Patched code is on disk — why isn't it working?

**The hidden actor:** A SECOND fleet-mcp-server process running under a different Python interpreter (uv Python at `~/AppData/Roaming/uv/python/.../python.exe`) holds the lock and serves health checks using **old code loaded into memory**. Your patched venv-based process can't acquire the lock and doesn't serve any requests.

## Root Cause

The Gateway (or a previous manual session) spawned the MCP server under uv Python. When that session ended (`/new`) or was killed:

- The Hermes venv MCP process died (since it was a child of the Hermes process)
- But the uv Python MCP process survived as an **orphan** — it was a child of a different process tree

When you started a new venv-based MCP server:
- The uv orphan still held the file lock (`run/fleet_mcp_server.lock` with the uv process PID)
- The venv server couldn't acquire the lock — it exited or ran as a ghost without serving
- Health checks went to the uv orphan, which ran the OLD code (pre-patch) and returned exit=1

## Why Different Interpreters?

Hermes Gateway connects its MCP subprocesses differently than a direct `terminal()` session:

| Spawn method | Python interpreter used |
|---|---|
| `config.yaml` `command:` (pinned venv) | `~/.../hermes-agent/venv/Scripts/python.EXE` |
| Gateway via git-bash (indirect spawn) | Can resolve to uv Python on PATH |
| Direct `terminal()` command | Current shell's Python (git-bash `python` → uv) |
| Earlier session / manual launch | Whatever was on PATH at the time |

## Diagnostic Steps

```bash
# Step 1: Check whose lock it is
cat ~/AppData/Local/hermes/run/fleet_mcp_server.lock
# Returns: 34576 (example PID)

# Step 2: What process is this PID?
wmic PROCESS WHERE "ProcessId=34576" GET CommandLine /FORMAT:LIST 2>/dev/null
# Returns: CommandLine="~/AppData/Local/hermes\AppData\Roaming\uv\python\...\python.exe" fleet-mcp-server.py --accept-hooks
#                                                  ^^^^^^— DIFFERENT interpreter!

# Step 3: Compare with config.yaml's command:
#    mcp_servers.fleet.command: ~/AppData/Local/hermes/.../hermes-agent/venv/Scripts/python.EXE
#                              ^^^^^^— EXPECTED venv interpreter
# If they differ — you have a cross-interpreter orphan holding the lock
```

## Fix

**Kill ALL MCP processes across ALL interpreters in one pass, clear lock, let Gateway respawn clean:**

```bash
# Find ALL fleet-mcp processes (any interpreter)
wmic PROCESS WHERE "CommandLine like '%%fleet-mcp-server%%'" DELETE

# Clear stale lock and health log
rm -f ~/AppData/Local/hermes/run/fleet_mcp_server.lock
rm -f ~/AppData/Local/hermes/run/fleet_mcp_health_log.json

# Verify zero remain
wmic PROCESS WHERE "CommandLine like '%%fleet-mcp-server%%'" GET ProcessId,CommandLine /FORMAT:LIST
# Expected: (no output)

# Verify lock cleared
ls ~/AppData/Local/hermes/run/fleet_mcp_* 2>/dev/null || echo "clean"

# Let Gateway respawn during next session, or start manually:
cd ~/AppData/Local/hermes/scripts
"~/AppData/Local/hermes/AppData/Local/hermes/hermes-agent/venv/Scripts/python.exe" fleet-mcp-server.py --accept-hooks &
```

**After cleanup: verify both processes use the SAME interpreter:**
```bash
cat ~/AppData/Local/hermes/run/fleet_mcp_server.lock  # get PID
wmic PROCESS WHERE "ProcessId=<pid>" GET CommandLine /FORMAT:LIST  # check interpreter
# Should show: venv/Scripts/python.EXE — matching config.yaml command
```

## How to Distinguish from Other Failure Modes

| Failure Mode | Key Distinction |
|---|---|
| **FM#4 (Double-spawn from `command: python`)** | Both servers spawn at the SAME time from the SAME config, with different interpreters. Lock file is clean (only 1 PID). |
| **FM#14a (Session transition retry)** | Rapid startup retries (3-4 in 60s), server eventually connects after ~2.5min. Lock contests during kernel cleanup window. |
| **This pattern (Cross-interpreter orphan)** | Lock file has a PID from a DIFFERENT interpreter. Only ONE check per 30s (no rapid retries). Patching code on disk has NO effect on health results because the orphan runs old code from memory. |

## Prevention

The `_mcp_lock.py` shared singleton lock module (see `references/shared-lock-module.md`) incorporates a **startup orphan cleanup preflight** that scans for MCP processes from any interpreter and kills all except the current one before attempting the lock. If implementing a new MCP server, use `_mcp_lock.py` rather than raw file-lock or named-mutex code.
