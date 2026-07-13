# Windows-Specific Setup & Quirks

Source: Hermes Agent docs (Windows-Specific Quirks section), community guides, and issue reports (June 2026).

## Installation on Windows

### Official Installer (Recommended)
```powershell
# PowerShell (Admin not required)
irm https://hermes-agent.nousresearch.com/install.ps1 | iex

# Or via pip (if Python 3.11+ installed)
pip install 'hermes-agent[all]'
```

### Windows Terminal Backend
- Hermes `terminal` tool runs commands through **bash (git-bash/MSYS)**, NOT PowerShell or cmd.exe
- Use POSIX shell syntax: `ls`, `$HOME`, `&&`, `|`, single-quoted strings
- MSYS-style paths like `/c/Users/<user>/...` work alongside native `C:\Users\<user>\...`
- PowerShell builtins (`Get-ChildItem`, `$env:FOO`, `Select-String`) will NOT work

### Python Toolchain
```bash
# Check what's available
python --version     # 3.11.15 (system)
python3 --version    # missing
pip --version        # missing
uv --version         # installed (fast Python package manager)
```
- Use `uv pip install` for packages
- `uv run hermes` works as alternative launcher

## Runtime Mode Specifics on Windows

### TUI (`hermes --tui`) in VS Code
- **Best experience**: VS Code integrated terminal with git-bash profile
- **Alt+Enter newline**: Doesn't work (Windows Terminal intercepts for fullscreen)
  - **Use Ctrl+Enter** instead (bound to newline on Windows only)
- **Keybinding diagnostic**: `python scripts/keystroke_diagnostic.py` from repo root

### Gateway as Windows Service
```powershell
# Install as background service (survives logout)
hermes gateway install

# Control
hermes gateway start
hermes gateway stop
hermes gateway restart
hermes gateway status

# Logs
Get-Content ~/.hermes/logs/gateway.log -Wait -Tail 50
# or
hermes gateway run  # foreground for debugging
```
- Creates `hermes-gateway` Windows service
- Runs under your user account (not SYSTEM)
- Shares `~/.hermes` with CLI/Desktop

### Dashboard (`hermes dashboard`)
| Component | Windows Support |
|-----------|-----------------|
| Config/API Keys/Sessions/Logs/Analytics/Cron/Skills UI | ✅ Full |
| **Chat tab (embedded TUI)** | ❌ **Requires WSL2** — native Windows Python lacks PTY support |
| Workaround | Run Dashboard in WSL2, or use TUI/Desktop for chat |

### Desktop App (`hermes desktop`)
- **Native Windows Electron build** — downloads `.exe` installer
- **Voice mic input**: Works (prompts for microphone permission)
- **Command palette**: Ctrl+K (not Cmd+K)
- **Auto-update**: Background checks + one-click update
- **Config location**: `%LOCALAPPDATA%\hermes` (same as `~/.hermes` via MSYS)

### Hermes WebUI (nesquena)
- **Native Windows**: Not officially supported for bootstrap
- **Community guide**: @markwang2658/hermes-windows-native-guide
- **Recommended**: Run in WSL2
  ```bash
  # In WSL2
  git clone https://github.com/nesquena/hermes-webui
  cd hermes-webui
  python3 bootstrap.py
  ```
- **Daemon control**: `./ctl.sh start|stop|status|logs|restart`

### Hermes Studio / EKKO (EKKOLearnAI/hermes-web-ui)
- **Desktop**: Windows `.exe` installer available
- **npm CLI**: `npm install -g hermes-web-ui` → runs on `http://localhost:8648`
- **Docker**: `docker run -p 6060:6060 ekkoye8888/hermes-web-ui`
- **WeChat/Feishu**: QR code login works in Windows browser

### Open WebUI + Hermes API Server
```bash
# Option 1: Docker (recommended on Windows)
docker run -d -p 3000:8080 ghcr.io/open-webui/open-webui:main

# Option 2: WSL2 native
# In WSL2: pip install open-webui && open-webui serve

# Hermes: Enable API platform in config.yaml
# ~/.hermes/config.yaml
platforms:
  api:
    enabled: true
    extra:
      host: "0.0.0.0"
      port: 8644

# Restart gateway
hermes gateway restart
```
- Open WebUI connects to `http://localhost:8644/v1` (or WSL2 IP)

### ACP Server (`hermes acp`)
- Works natively on Windows
- VS Code: Install "ACP" extension or use Copilot ACP (`copilot --acp --stdio`)
- Cursor/Zed: Native ACP support

### MCP Server (`hermes mcp serve`)
- Works natively on Windows
- Other agents (Claude Code, Codex) connect via MCP stdio/HTTP
- Tools exposed as `mcp_hermes_*`

## Common Windows Issues & Fixes

### Config UTF-8 BOM Error
**Error**: `HTTP 400 "No models provided"` on first run
**Cause**: `config.yaml` saved with UTF-8 BOM (Notepad default)
**Fix**:
```bash
hermes config edit  # Opens in $EDITOR (saves without BOM)
# Or manually: open in VS Code → Save with encoding "UTF-8 (without BOM)"
```

### execute_code Sandbox WinError 10106
**Error**: `WinError 10106 "The requested service provider could not be loaded"`
**Cause**: Child process can't create AF_INET socket; env scrubber drops `SYSTEMROOT`/`WINDIR`/`COMSPEC`
**Fix**: Fixed in `tools/code_execution_tool.py` via `_WINDOWS_ESSENTIAL_ENV_VARS` allowlist
**Verify**:
```python
# In execute_code or hermes session
import os
print("SYSTEMROOT" in os.environ)  # Should be True
```

### Line Endings (Git)
**Warning**: `LF will be replaced by CRLF`
**Fix**: Repo has `.gitattributes` normalizing to LF. Don't let editors auto-convert.
```bash
# Check
git config core.autocrlf  # Should be 'input' or 'false'
```

### Path Separators
- **Use forward slashes** in code/logs: `C:/Users/...` works everywhere
- Avoid backslash escaping in bash: `C:\\Users\\...` → use `C:/Users/...` or `/c/Users/...`

### Symlinks / File Modes
- Symlinks require elevated privileges on Windows
- POSIX mode bits (0o600) not enforced on NTFS by default
- Tests using these are skipped on Windows via `@pytest.mark.skipif(sys.platform == "win32", ...)`

## WSL2 Integration (Best of Both Worlds)

### Recommended Setup
```bash
# In WSL2 (Ubuntu/Debian)
sudo apt update && sudo apt install -y python3.11 python3.11-venv nodejs npm

# Install Hermes in WSL2
pip3 install 'hermes-agent[all]'

# Gateway runs as systemd service (requires systemd=true in /etc/wsl.conf)
sudo systemctl enable --user hermes-gateway
sudo loginctl enable-linger $USER

# Windows VS Code → Connect to WSL2 → Use TUI natively
# Windows browser → http://localhost:9119 (Dashboard) / :3000 (Open WebUI)
```

### File Sharing
- `~/.hermes` in WSL2 = `/home/user/.hermes`
- Windows sees it at `\\wsl$\Ubuntu\home\user\.hermes`
- **Same state.db** — sessions resume across Windows TUI ↔ WSL2 TUI ↔ Dashboard

## Testing/Development on Windows

### Running Tests
```bash
# Hermes-installed venv lacks pip/pytest — use system Python
"C:/Program Files/Python311/python" -m pip install --user pytest pytest-xdist pyyaml

export PYTHONPATH="$(pwd)"
"C:/Program Files/Python311/python" -m pytest tests/tools/test_foo.py -v --tb=short -n 0
```
- Use `-n 0` (not `-n 4`) — `pyproject.toml` default `addopts` includes `-n`
- POSIX-only tests need skip guards: `sys.platform == "win32"`

### Monkeypatching Platform in Tests
```python
# Not enough: monkeypatch.setattr(sys, "platform", "linux")
# Must also patch platform module:
monkeypatch.setattr(sys, "platform", "linux")
monkeypatch.setattr(platform, "system", lambda: "Linux")
monkeypatch.setattr(platform, "release", lambda: "6.8.0-generic")
```

## Quick Reference: Windows Command Equivalents

| Task | Windows (PowerShell) | HermES (bash/MSYS) |
|------|----------------------|-------------------|
| List files | `Get-ChildItem` / `ls` | `ls` |
| Read file | `Get-Content file.txt` | `cat file.txt` / `read_file` tool |
| Search content | `Select-String "pattern" *.py` | `grep "pattern" *.py` / `search_files` tool |
| Find files | `Get-ChildItem -Recurse -Filter "*.py"` | `find . -name "*.py"` / `search_files target=files` |
| Edit file | `notepad file.txt` / VS Code | `nano file.txt` / `patch` tool / `write_file` tool |
| Env var | `$env:FOO = "bar"` | `export FOO=bar` |
| Path join | `Join-Path $a $b` | `"$a/$b"` |
| Home dir | `$env:USERPROFILE` | `$HOME` / `~` |

## Bun & Herm TUI (Community TUI Dashboard)

[herm-tui](https://github.com/liftaris/herm) is a third-party TUI dashboard for Hermes Agent built with OpenTUI and Bun. It provides chat, session management, kanban, eikon marketplace, and profile switching — all in the terminal.

### Installing Bun on Windows

**Do NOT rely on `npm i -g bun` alone** — that installs a node.js wrapper script that `herm.exe` cannot use as its runtime.

**Install the full Bun runtime via PowerShell:**
```powershell
powershell -c "irm bun.sh/install.ps1 | iex"
```

This installs `bun.exe` to `~/.bun/bin/bun.exe`.

### Install herm-tui

```bash
# Add bun bin to PATH first (or use full path)
export PATH="$HOME/.bun/bin:$PATH"

# Install globally
bun add -g herm-tui

# Binary at ~/.bun/bin/herm
```

### PATH Setup (git-bash)

Add to `~/.bashrc` or `~/.bash_profile`:
```bash
export PATH="$HOME/.bun/bin:$PATH"
```

### Usage

```bash
herm            # Start fresh session
herm -c         # Resume last session
herm --help     # Full usage
```

> **Note:** herm is a full TUI (curses-style) — run it in a real interactive terminal (VS Code terminal, Windows Terminal, etc.), not through the Hermes Agent `terminal` tool.

### Start Menu Shortcut (Windows)

After installing, create a Start Menu icon so herm appears in Windows search and the Start Menu:

```powershell
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Hermes TUI (herm).lnk")
$Shortcut.TargetPath = "$env:USERPROFILE\.bun\bin\herm.exe"
$Shortcut.WorkingDirectory = "$env:USERPROFILE"
$Shortcut.Description = "Hermes Agent TUI Dashboard - herm"
$Shortcut.IconLocation = "$env:LOCALAPPDATA\hermes\hermes-agent\apps\desktop\assets\icon.ico, 0"
$Shortcut.Save()
```

Write to a `.ps1` temp file and execute with `powershell -ExecutionPolicy Bypass -File` — inline `-Command` breaks with COM objects from git-bash. See `windows-startup-autolaunch` skill for the full pattern.

### Pitfalls

- **"bun runtime not found"** — This means `bun.exe` is missing from `~/.bun/bin/`. The npm-installed bun wrapper (`AppData/Roaming/npm/bun`) is not sufficient. Run the PowerShell installer above.
- **`herm` not found after install** — Bun installs global binaries to `~/.bun/bin/`. Add it to PATH.
- **TUI quirks on Windows** — `Alt+Enter` may be intercepted by Windows Terminal. Use `Ctrl+Enter` for newlines in chat.

## Resources

- Official Docs: https://hermes-agent.nousresearch.com/docs/user-guide/windows
- Windows Native Guide: https://github.com/markwang2658/hermes-windows-native-guide
- WSL2 Setup: https://hermes-agent.nousresearch.com/docs/getting-started/wsl2
- GitHub Issues (Windows tag): https://github.com/NousResearch/hermes-agent/issues?q=label%3Awindows