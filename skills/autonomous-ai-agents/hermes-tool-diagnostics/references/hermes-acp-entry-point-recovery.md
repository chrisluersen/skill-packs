# ACP Entry Point Recovery (Windows)

When `pip install -e .` or `pip install -e '.[acp]'` fails on Windows because `hermes.exe` is locked (the running session), console_scripts entry points like `hermes-acp` can be deleted during the failed uninstall phase.

## Symptoms

```
$ hermes-acp --check
bash: hermes-acp: command not found

$ ls ~/AppData/Local/hermes/hermes-agent/venv/Scripts/hermes-acp*
ls: cannot access: No such file or directory
```

But the Python packages are intact:
```
$ python -m acp_adapter --check
Hermes ACP check OK
```

## Recovery: Create Entry Point Scripts Manually

### 1. Locate the venv scripts directory

```bash
cd "$LOCALAPPDATA/hermes/hermes-agent/venv/Scripts"
```

### 2. Create `hermes-acp` (bash — for git-bash/MSYS/WSL)

```bash
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${SCRIPT_DIR}/python.exe" -m acp_adapter "$@"
```

Make it executable: `chmod +x hermes-acp`

### 3. Create `hermes-acp.bat` (CMD — for Windows native)

```batch
@echo off
"%~dp0python.exe" -m acp_adapter %*
```

### 4. Verify

```bash
hermes-acp --check
# Expected output: "Hermes ACP check OK"
```

## How it works

The `pyproject.toml` maps `hermes-acp` → `acp_adapter.entry:main` as a console_scripts entry point. The adapter itself lives at `hermes-agent/acp_adapter/entry.py`. Since this is run via `-m acp_adapter`, no reinstallation of the hermes-agent package is needed — the scripts just need the correct `python.exe` path and module invocation.

## Prevention

To avoid this situation entirely, do NOT run `pip install -e .` (or with extras like `.[acp]`) while the current session is using `hermes.exe`. If you need to install or update an extra, use:

```bash
# Installing a new extra dependency (won't touch entry points):
"$LOCALAPPDATA/hermes/hermes-agent/venv/Scripts/python" -m pip install agent-client-protocol==0.9.0

# To regenerate entry points without the editable reinstall hazard, start a fresh venv
# or use a different Python environment.
```
