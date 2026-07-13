# Windows npm install Encoding Fix

## Problem
When running `hermes --tui` or `hermes setup` on Windows, the TUI dependency installation via `npm install` fails with:
```
UnicodeDecodeError: 'charmap' codec can't decode byte 0x8f in position 29: character maps to <undefined>
```
This occurs because npm output contains Unicode characters (emoji, box-drawing chars) that the default Windows code page (charmap/CP1252) cannot decode.

## Root Cause
Windows console uses legacy code pages by default. The Hermes Python process captures npm stdout/stderr with `text=True` (which uses locale.getpreferredencoding()), but npm emits UTF-8 output including emoji. The mismatch causes a decode error in the Python wrapper.

## Fix
Run npm install manually with explicit UTF-8 encoding:
```bash
cd "C:/Users/<user>/AppData/Local/hermes/hermes-agent/ui-tui"
PYTHONIOENCODING=utf-8 npm install
```
Or if already in a Python context:
```python
import os, subprocess
env = {**os.environ, "PYTHONIOENCODING": "utf-8", "CI": "1"}
subprocess.run(["npm", "install", "--silent", "--no-fund", "--no-audit", "--progress=false"], 
               cwd=tui_dir, env=env, capture_output=True, text=True)
```

## Prevention
- The `hermes_cli/main.py` TUI bootstrap code (around line 1622) should set `PYTHONIOENCODING=utf-8` in the subprocess env
- User can also set `chcp 65001` in cmd before running, but PYTHONIOENCODING works from bash/MSYS
- Setting `HERMES_QUIET=1` suppresses the print but doesn't fix the underlying decode

## Verified Working
- Hermes version: 2026-06-11
- Windows 10 (10.0.26200.8524)
- Node: v22.x (from Hermes bundle)
- npm: 10.x
