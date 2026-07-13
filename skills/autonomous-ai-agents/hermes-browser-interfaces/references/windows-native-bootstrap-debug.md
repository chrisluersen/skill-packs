# Native Windows Bootstrap: Debug Commands & Error Transcripts

Session findings from setting up nesquena/hermes-webui on Windows 10 (git-bash/MSYS2) without Docker or WSL2.

## Key Paths (this user — adapt to current context)

| Item | Path |
|------|------|
| Hermes agent dir | `C:\Users\<user>\AppData\Local\hermes\hermes-agent` |
| Agent venv Python | `C:\Users\<user>\AppData\Local\hermes\hermes-agent\venv\Scripts\python.exe` |
| Hermes home | `C:\Users\<user>\AppData\Local\hermes` |
| Hermes config | `C:\Users\<user>\AppData\Local\hermes\config.yaml` |
| WebUI repo | `C:\Users\<user>\hermes-webui` |
| WebUI state dir | `C:\Users\<user>\.hermes\webui` |
| WebUI log | `C:\Users\<user>\.hermes\webui\bootstrap-8787.log` |

## Diagnosing Python Resolution

The most common failure is the **Microsoft Store Python stub** — `python` resolves to a
stub that opens the Store app instead of running the real interpreter.

**Symptom (from webui.log):**
```
Python was not found; run without arguments to install from the Microsoft Store,
or disable this shortcut from Settings > Apps > Advanced app settings > App execution aliases.
```

**Diagnosis:**
```bash
# Check which python resolves to
which python
# Expected: /c/Users/<user>/AppData/Local/hermes/hermes-agent/venv/Scripts/python

# Check the agent dir has run_agent.py
ls /c/Users/<user>/AppData/Local/hermes/hermes-agent/run_agent.py

# Verify the venv Python exists and works
/c/Users/<user>/AppData/Local/hermes/hermes-agent/venv/Scripts/python.exe -c "import yaml; print('ok')"
```

**Fix:** Always set `HERMES_WEBUI_PYTHON` when using `ctl.sh`:
```bash
HERMES_WEBUI_PYTHON="/c/Users/<user>/AppData/Local/hermes/hermes-agent/venv/Scripts/python.exe" ./ctl.sh start
```

When using `bootstrap.py` directly, set `HERMES_WEBUI_AGENT_DIR` instead — it auto-discovers
the venv Python from the agent directory.

## `bootstrap.py` on Windows — How It Works

On native Windows, `bootstrap.py` takes this path through `main()`:

1. `ensure_supported_platform()` — prints a warning but does NOT block
2. `discover_agent_dir()` — checks `HERMES_WEBUI_AGENT_DIR` → `$HERMES_HOME/hermes-agent` → `~/.hermes/hermes-agent` → `~/hermes-agent` → the `hermes` CLI shebang. On Windows the CLI is a `.exe` stub, so the shebang fallback fails — `HERMES_WEBUI_AGENT_DIR` must be set.
3. `hermes_command_exists()` — checks `shutil.which("hermes")` — works on Windows if Hermes is on PATH
4. `discover_launcher_python()` — checks `HERMES_WEBUI_PYTHON` → agent venv `venv/Scripts/python.exe` → repo `.venv/Scripts/python.exe` → `shutil.which("python3") or sys.executable`
5. `ensure_python_has_webui_deps()` — creates repo `.venv` if needed, installs `pyyaml` and `cryptography`
6. Starts server as detached child via `subprocess.Popen` with `start_new_session=True` and `CREATE_NEW_PROCESS_GROUP`

## `ctl.sh` on Windows — PID Tracking Quirk

The `ctl.sh` script has Windows-awareness built in:
- `_is_windows_bash()` detects MSYS/MINGW/CYGWIN via `$OS` or `uname -s`
- `_stop_webui_pid()` uses `taskkill //F //T //PID` on Windows
- Path conversion via `_windows_bash_path()` and `cygpath`

**Why `ctl.sh status` fails on Windows:**

`ctl.sh start` launches `bootstrap.py --foreground`. On POSIX systems, `--foreground`
uses `os.execv()` to replace the bootstrap process with the server — the original PID
persists, so the PID file stays valid. On Windows, `os.execv()` spawns a new process
via `CreateProcess` instead of replacing the current one, so the bootstrap process
exits and the PID in the file points to a dead process. `status` checks `_is_alive`
on the PID, finds it dead, and reports "stopped" even though the child server is
running on a different PID.

**Workaround commands for status checking:**

```bash
# Check via health endpoint
curl -s http://localhost:8787/health

# Find the real PID
netstat -ano | findstr :8787

# Kill the real PID
taskkill //F //PID <pid>
```

## Requirements Check

WebUI only needs two Python packages beyond the agent venv:
```
pyyaml>=6.0
cryptography>=42.0
```

No heavy ML/agent deps — those live in the Hermes agent venv. Edge TTS
for server-side voice is optional (`pip install edge-tts`).
