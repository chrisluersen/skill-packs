# browser-cdp Setup on Windows (Session Reference)

Concrete recipe tested on Windows 10 with Brave browser.

## Prerequisites

- A Chromium-family browser installed (Brave, Chrome, or Edge)
- MSYS2/git-bash environment (for POSIX-style paths in terminal)

## Steps

### 1. Find the browser executable

| Browser | Common path |
|---------|-------------|
| Brave | `/c/Program Files/BraveSoftware/Brave-Browser/Application/brave.exe` |
| Chrome | `/c/Program Files/Google/Chrome/Application/chrome.exe` |
| Edge | `/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe` |

### 2. Set the CDP URL in config

```bash
hermes config set browser.cdp_url http://127.0.0.1:9222
```

This writes `browser.cdp_url: http://127.0.0.1:9222` into `config.yaml`.

### 3. Create a dedicated user-data directory

```bash
mkdir -p ~/AppData/Local/hermes/brave-debug
```

### 4. Launch browser with CDP enabled

```bash
"/c/Program Files/BraveSoftware/Brave-Browser/Application/brave.exe" \
  --remote-debugging-port=9222 \
  --user-data-dir="$HOME/AppData/Local/hermes/brave-debug" \
  --no-first-run --no-default-browser-check
```

Flags explained:
- `--remote-debugging-port=9222` — opens the CDP WebSocket on port 9222
- `--user-data-dir=...` — uses an isolated profile so your normal browsing is unaffected
- `--no-first-run` — suppresses the welcome/first-run dialog
- `--no-default-browser-check` — suppresses "make Brave your default browser?" prompts

### 5. Verify the CDP endpoint

```bash
curl -s http://127.0.0.1:9222/json/version
```

Expected response:
```json
{
   "Browser": "Chrome/149.0.7827.103",
   "Protocol-Version": "1.3",
   "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) ...",
   "V8-Version": "14.9.207.27",
   "WebKit-Version": "537.36 (@f4022dc...)",
   "webSocketDebuggerUrl": "ws://127.0.0.1:9222/devtools/browser/<uuid>"
}
```

If curl hangs or returns `curl: (7) Failed to connect`, the browser isn't running or the port is wrong.

### 6. Confirm in Hermes

```bash
hermes doctor
```

Before: `⚠ browser-cdp (system dependency not met)`
After: no warning shown (it either shows as available or disappears from the warning list)

## Important Notes

- **browser-cdp is not a separate toolset to enable.** It's an internal capability consumed by the `browser` toolset. Once CDP URL is configured, the existing browser toolset uses it transparently.
- **The browser must stay running.** Close the browser window and the CDP endpoint dies. Launch it via `terminal(background=true)` if setting up through Hermes, or start it manually and leave it open.
- **Relaunch command** (bookmark this):
  ```bash
  "/c/Program Files/BraveSoftware/Brave-Browser/Application/brave.exe" --remote-debugging-port=9222 --user-data-dir=%USERPROFILE%\.hermes\brave-debug --no-first-run --no-default-browser-check
  ```
- `computer_use` cannot be enabled on Windows (it requires macOS-only private Apple SPIs).
