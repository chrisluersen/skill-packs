---
name: hermes-browser-interfaces
description: "Set up and use browser-based UIs for Hermes Agent — the built-in dashboard and third-party web UIs — especially on Windows."
version: 1.1.0
author: Hermes Agent (learned from session)
metadata:
  tags: [hermes, web-ui, dashboard, windows, docker, browser]
  related_skills: [hermes-agent, docker-setup]
created_from_user_sessions: true
---

# Hermes Browser Interfaces

Guide to running Hermes Agent from a browser — useful when you want a GUI instead of the CLI, need mobile access, or are on Windows where the CLI layout is less ideal.

## Two Options

| | `hermes dashboard` (built-in) | Third-party WebUI (e.g. nesquena/hermes-webui) |
|---|---|---|
| **Command** | `hermes dashboard` | `docker compose up -d` (Docker) or `python3 bootstrap.py` |
| **Port** | `127.0.0.1:9119` | `127.0.0.1:8787` |
| **Experience** | Admin panel (config, logs, analytics, sessions, cron, chat via xterm.js) | Full chat-first UI (streaming, workspace browser, file editing, themes, voice input) |
| **Requires** | `pip install 'hermes-agent[web,pty]'` | Python 3.10+ or Docker |
| **Windows notes** | Chat tab needs WSL2 for PTY; dashboard pages work fine natively | Native Windows not supported for bootstrap; use Docker or WSL2 |

---

## Built-in Dashboard (`hermes dashboard`)

```bash
# Install extras
pip install 'hermes-agent[web,pty]'

# Launch (binds to localhost:9119, auto-opens browser)
hermes dashboard

# Common flags
hermes dashboard --port 8080          # custom port
hermes dashboard --no-open            # don't auto-open browser
hermes dashboard --host 0.0.0.0       # ⚠️ expose to network (needs password auth setup)
```

**Pages:** Status, Chat (xterm.js TUI), Config editor, API Keys, Sessions browser, Logs viewer, Analytics, Cron manager, Skills manager, Profiles switcher.

**On Windows:** The dashboard pages (config, sessions, logs, analytics) work natively. The Chat tab (xterm.js PTY) requires WSL2.

---

### Third-Party WebUI (nesquena/hermes-webui)

A lightweight, dark-themed chat-first web interface with 1:1 CLI parity — streaming responses, workspace file browser, session management, themes, voice input, and more.

**Known fork: Valhalla** — A maintained fork at `~/AppData/Local/hermes\\valhalla` (renamed from `hermes-webui-fork`) that runs on port 8787 and replaces the original hermes-webui install. Valhalla uses a native PowerShell launcher (`start.ps1`) with a batch wrapper (`run-valhalla.bat`) for Windows, includes a custom multi-size `.ico` for Start Menu/taskbar, and has Makefile targets for shortcut creation. The original nesquena/hermes-webui was removed to avoid confusion.

### On Windows Native (Experimental — Works with Quirks)

Bootstrap can run on native Windows 10/11 with git-bash/MSYS2, but with caveats. Use this when you don't want the Docker/WSL2 memory overhead (~330 MB native vs ~1080 MB WSL2+Docker). For deeper debug commands and error transcripts, see `skill_view(name="hermes-browser-interfaces", file_path="references/windows-native-bootstrap-debug.md")`.

**Prerequisites:** Hermes Agent installed, git-bash, Python 3.10+

```bash
# 1. Clone
git clone https://github.com/nesquena/hermes-webui.git
cd hermes-webui

# 2. Find your agent Python (critical — avoid the Microsoft Store Python stub)
#    The agent venv Python is at:
#      /c/Users/<you>/AppData/Local/hermes/hermes-agent/venv/Scripts/python.exe
#    Verify with: which python

# 3. Start — simplest path (works reliably)
HERMES_WEBUI_AGENT_DIR="/c/Users/<you>/AppData/Local/hermes/hermes-agent" \
  python bootstrap.py --no-browser

# 4. Open in browser
start http://localhost:8787

# 5. To stop later: find the real process PID
netstat -ano | findstr :8787
taskkill //F //PID <pid>
```

**Using ctl.sh** (daemon-style start/stop/log management):

```bash
# Start — MUST set HERMES_WEBUI_PYTHON to agent venv python.exe,
# otherwise 'python' resolves to the Microsoft Store stub
HERMES_WEBUI_PYTHON="/c/Users/<you>/AppData/Local/hermes/hermes-agent/venv/Scripts/python.exe" \
  ./ctl.sh start

# View logs
./ctl.sh logs --lines 50

# Stop (checks PID file, then falls back to taskkill)
./ctl.sh stop

# ⚠️ ctl.sh status is BROKEN on Windows — PID tracking fails because
#    bootstrap.py --foreground can't use os.execv on Windows (POSIX-only),
#    so it spawns the server as a child and exits, leaving the PID file stale.
#    The server IS running; check with curl or netstat instead:
curl -s http://localhost:8787/health
netstat -ano | findstr :8787
```

**Key environment variables for native Windows:**

| Variable | Purpose | Windows tip |
|----------|---------|-------------|
| `HERMES_WEBUI_AGENT_DIR` | Path to Hermes agent source (run_agent.py parent) | `/c/Users/<you>/AppData/Local/hermes/hermes-agent` |
| `HERMES_WEBUI_PYTHON` | Python interpreter to use | Agent venv: `/c/Users/<you>/AppData/Local/hermes/hermes-agent/venv/Scripts/python.exe` |
| `HERMES_WEBUI_HOST` | Bind address (default: `127.0.0.1`) | Leave as localhost for local use |
| `HERMES_WEBUI_PORT` | Bind port (default: `8787`) | Change if port is in use |
| `HERMES_WEBUI_PASSWORD` | Password protect the UI | Set if exposing beyond localhost |

**Known Windows quirks:**
- **Microsoft Store Python stub:** `python` in cmd/git-bash may resolve to a stub that opens the Store. Always set `HERMES_WEBUI_PYTHON` explicitly to the agent venv path.
- **`ctl.sh status` broken:** PID file tracking doesn't work on Windows (see above). Use `curl`/`netstat` to verify.
- **Embedded terminal:** Not supported on native Windows — only the WebUI's chat panel, file browser, and session management work.
- **Auto-install:** Bootstrap's `install_hermes_agent()` raises RuntimeError on native Windows. Pre-install Hermes manually.
- **Passwordless access:** No password is set by default. Any process on the machine can read sessions via the local API.

### On Windows via Docker (RECOMMENDED for lighter-weight setup)

**Prerequisites:** Docker Desktop with WSL2 backend (Docker 24+)

```bash
# 1. Clone
git clone https://github.com/nesquena/hermes-webui.git
cd hermes-webui

# 2. Create .env from template
cp .env.docker.example .env

# 3. Edit .env — critical settings for Windows:
#    HERMES_HOME=/c/Users/<you>/AppData/Local/hermes
#    HERMES_WORKSPACE=/c/Users/<you>/workspace
#    HERMES_SKIP_CHMOD=1   (prevents permission clashes on Windows)

# 4. Launch
docker compose up -d

# 5. Open in browser
start http://localhost:8787

# To stop
docker compose down
```

**Key environment variables for `.env`:**

| Variable | Purpose | Windows tip |
|----------|---------|-------------|
| `HERMES_HOME` | Path to Hermes config/skills/sessions | Use `/c/Users/<you>/AppData/Local/hermes` |
| `HERMES_WORKSPACE` | Default filesystem workspace | Where your projects live |
| `HERMES_SKIP_CHMOD` | Skip permission fixer | Set `1` on Windows to avoid file mode clashes |
| `HERMES_WEBUI_PASSWORD` | Password protect the UI | Set this if exposing beyond localhost |
| `WANTED_UID` / `WANTED_GID` | Container user ID | Default 1000 works for most Windows setups |

### On Linux / macOS (Native)

```bash
git clone https://github.com/nesquena/hermes-webui.git
cd hermes-webui
python3 bootstrap.py
# Or: ./start.sh
```

### On WSL2 (Native, lighter than Docker)

```bash
# Inside WSL2
git clone https://github.com/nesquena/hermes-webui.git
cd hermes-webui
python3 bootstrap.py
# Access from Windows browser at http://localhost:8787
```

---

## Authentication & Remote Access

- Both UIs bind to `127.0.0.1` (localhost only) by default — safe without auth.
- **Remote access via SSH tunnel:** `ssh -N -L 8787:127.0.0.1:8787 user@host`
- **Tailscale:** Set `HERMES_WEBUI_HOST=0.0.0.0` + set a password for zero-config VPN access from phone.
- **Built-in dashboard:** Uses `--host 0.0.0.0` + `HERMES_WEBUI_PASSWORD` for remote.

---

## Pitfalls

- **Windows + bootstrap (native):** Bootstrap *can* run on native Windows — set `HERMES_WEBUI_AGENT_DIR` to the agent install path and the agent venv Python is auto-detected. Known quirks: `ctl.sh status` is broken (PID file goes stale), the Microsoft Store Python stub blocks auto-detection of the right interpreter, and embedded terminal isn't available.
- **Windows + bootstrap (via Docker or WSL2):** Recommended when you need the embedded terminal feature. For a lighter memory footprint (~330 MB vs ~1080 MB), native bootstrap is viable for chat+file-browser use only.
- **Docker permission clashes:** If the WebUI container can't read `~/.hermes`, set `HERMES_SKIP_CHMOD=1`.
- **Dashboard Chat tab on Windows:** The xterm.js PTY needs WSL2 — dashboard pages (config, sessions, analytics) work fine without it.
- **Port conflicts:** If port 8787 is in use, edit `docker-compose.yml` or set `HERMES_WEBUI_PORT` in `.env`.
- **Hermes home on Windows:** Your Hermes home is at `~/AppData/Local/hermes/` (not `~/.hermes`). If Docker can't find it, set `HERMES_HOME` explicitly in `.env` with an MSYS-style path.
