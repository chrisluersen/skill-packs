---
name: hermes-remote-access
description: "Configure remote and mobile access to Hermes Agent via Gateway API Server, Tailscale, SSH, and messaging platforms."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [hermes, gateway, remote-access, mobile, tailscale, ssh, termux, api-server]
    homepage: https://github.com/NousResearch/hermes-agent
    related_skills: [hermes-agent, hermes-browser-interfaces]
created_from_user_sessions: true
---

# Hermes Remote & Mobile Access

This skill covers connecting to a Hermes Agent instance from remote devices — phones (Termux), tablets, other computers — using the Gateway API Server, Tailscale, SSH, or messaging platforms.

## Platform note: Hermes Home Path

On **Linux/macOS**, Hermes stores config at `~/.hermes/` by default.
On **Windows**, the canonical path is `$HOME/AppData/Local/hermes/` (settable via `HERMES_HOME` env var).

**Always verify the real path before editing:**
```bash
hermes config path      # config.yaml location
hermes config env-path  # .env location
```

All examples in this skill use `~/.hermes/` — substitute with your platform's path.

## ⚠️ Remote Access Strategy: API Server + Tailscale (not SSH tunnel)

**Tailscale already provides encrypted mesh networking** — don't add an SSH tunnel over it. The API Server pattern (`tailscale status` → Hermes API Server on port 8642) is simpler and more capable:

- No SSH key management on mobile devices
- OpenAI-compatible API endpoint (works with any HTTP client)
- Session continuity across connections
- Callable from scripts, Shortcuts, Termux, cron jobs

Use SSH **only** when you need the full interactive Hermes TUI on mobile (requires SSH server on host + SSH client on mobile). For most remote access, API Server + Tailscale is the right approach.

## Quick Reference

| Method | Best For | Setup Complexity |
|--------|----------|------------------|
| **API Server + Tailscale** | Termux, scripts, any HTTP client | Medium (one-time) |
| **SSH + hermes CLI** | Full interactive TUI on mobile | Medium (SSH server) |
| **Telegram/Discord Gateway** | Native mobile apps, notifications, voice | Low (account setup) |
| **Local LAN (no Tailscale)** | Home network only | Low |

---

## API Server + Tailscale (Recommended for Termux)

### On Host Machine (Windows/Linux/macOS)

1. **Install Tailscale**
   ```bash
   # Windows
   winget install --id Tailscale.Tailscale --silent
   
   # Linux
   curl -fsSL https://tailscale.com/install.sh | bash
   
   # macOS
   brew install --cask tailscale
   ```

2. **Authenticate Tailscale**
   ```bash
   tailscale up
   # Visit the printed URL in browser to authenticate
   # If URL expires (404 "This authentication link could not be located"), re-run `tailscale up` for fresh URL
   ```

3. **Get your Tailscale IP & MagicDNS name**
   ```bash
   tailscale ip -4
   # Returns stable 100.x.y.z address (e.g., 100.93.200.100)
   
   tailscale status --json | jq -r '.Self.DNSName'
   # Returns MagicDNS name (e.g., user.tail722363.ts.net) — stable across networks
   ```

4. **Enable Hermes Gateway API Server (via .env, NOT config.yaml)**
   
   **Critical**: The API Server platform reads configuration from `.env` environment variables, not from `config.yaml`'s `gateway.api_server.*` section.
   
   ```bash
   # Add to ~/.hermes/.env
   cat >> ~/.hermes/.env << 'EOF'

# =============================================================================
# API SERVER (OpenAI-compatible HTTP API for Hermes)
# =============================================================================
API_SERVER_ENABLED=true
API_SERVER_KEY=hermes-$(openssl rand -hex 16 2>/dev/null || echo 'localdevkey')  # Generate secure key
API_SERVER_HOST=0.0.0.0             # REQUIRED: binds to all interfaces (Tailscale + LAN)
API_SERVER_PORT=8642                # Default port (not 8080)
EOF
   
   # Allow unauthenticated gateway access (needed for API Server clients)
   echo "GATEWAY_ALLOW_ALL_USERS=true" >> ~/.hermes/.env
   ```

5. **Restart Gateway**
   ```bash
   hermes gateway restart
   # Or: hermes gateway stop && hermes gateway start
   ```

6. **Verify**
   ```bash
   # From host (no auth needed for health)
   curl http://localhost:8642/health
   # {"status":"ok"}
   
   # From Tailscale network (requires auth header)
   curl -H "Authorization: Bearer <YOUR_...Y>" http://user.tailXXXXX.ts.net:8642/health
   ```

### On Android (Termux)

```bash
# Install dependencies
pkg update && pkg install curl jq

# Install Tailscale (Play Store or F-Droid)
# Sign in with same account → your host appears in device list

# Create client script (uses OpenAI-compatible /v1/chat/completions endpoint)
cat > ~/hermes.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
HERMES_URL="http://user.tailXXXXX.ts.net:8642"  # Use MagicDNS name (stable)
HERMES_KEY="hermes-<your-key-from-.env>"           # Copy from host's .env
MSG="$*"

curl -s -X POST "$HERMES_URL/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer *** \
  -d "{\"model\": \"hermes-agent\", \"messages\": [{\"role\": \"user\", \"content\": \"$MSG\"}], \"stream\": false}" | jq -r '.choices[0].message.content // .error'
EOF
chmod +x ~/hermes.sh

# Test
~/hermes.sh "hello from termux via tailscale"
```

### API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check (no auth) |
| `/health/detailed` | GET | Rich status for dashboards (no auth) |
| `/v1/chat/completions` | POST | OpenAI-compatible chat (requires `Authorization: Bearer <API_SERVER_KEY>`) |
| `/v1/responses` | POST | OpenAI Responses API (stateful) |
| `/v1/models` | GET | List available models |
| `/v1/capabilities` | GET | Machine-readable capabilities |
| `/v1/runs` | POST | Start async agent run (returns run_id) |
| `/v1/runs/{run_id}` | GET | Get run status |
| `/v1/runs/{run_id}/events` | GET | SSE stream of run events |
| `/api/sessions` | GET/POST | List/create persistent sessions |
| `/api/sessions/{id}/chat` | POST | Chat with session continuity |

**Authentication**: All endpoints except `/health` and `/health/detailed` require:
```
Authorization: Bearer <API_SERVER_KEY>
```

---

## SSH + Interactive Hermes

### On Windows Host
1. Enable OpenSSH Server: Settings → Apps → Optional Features → Add "OpenSSH Server"
2. Start service: `Start-Service sshd` (Admin PowerShell)
3. Configure firewall: `New-NetFirewallRule -Name "OpenSSH" -DisplayName "OpenSSH" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22`

### On Termux
```bash
pkg install openssh
ssh user@<TAILSCALE_IP>
# Then run: hermes
```

---

## Messaging Platforms (Telegram/Discord/etc.)

```bash
hermes gateway setup
# Select: Telegram, Discord, Slack, etc.
# Follow platform-specific OAuth/bot setup

hermes gateway run
# Or as service: hermes gateway install && hermes gateway start
```

Platform docs: https://hermes-agent.nousresearch.com/docs/user-guide/messaging/

---

## Troubleshooting

### Tailscale not authenticated
```bash
tailscale status --json | jq -r '.BackendState'
# "NeedsLogin" → visit the AuthURL in browser
# If URL expired (404 "This authentication link could not be located"): re-run `tailscale up`
```
### Gateway not accessible

```bash
# Check gateway logs
cat ~/.hermes/logs/gateway.log

# Verify API Server binding (should show 0.0.0.0:8642, not 127.0.0.1:8642)
netstat -an | findstr 8642  # Windows
ss -tlnp | grep 8642        # Linux

# Common issue: API Server bound to 127.0.0.1 only
# Fix: Ensure API_SERVER_HOST=0.0.0.0 in .env, then `hermes gateway restart`

# BOTTOMLINE VERIFICATION: Always curl the health endpoint as the definitive check.
# `hermes gateway status` can return "running" while the HTTP server is dead.
curl http://localhost:8642/health
# Expect: {"status":"ok"}
```

### Gateway crashes silently (exit code -1073741510)

The gateway process can exit with code -1073741510 (STATUS_DLL_INIT_FAILED or orphaned process collision) without a visible error message.

**Fix:** Use `--replace` to force-terminate and respawn:
```bash
hermes gateway run --replace
```

This is more reliable than `hermes gateway restart` when the previous process left state behind. Always verify with the health endpoint after fixing:
```bash
curl http://localhost:8642/health
# {"status":"ok","platform":"hermes-agent","version":"0.18.0"}
```

### Termux connection refused / 401 Unauthorized
- Verify Tailscale connected on both devices: `tailscale status`
- Ping test: `ping user.tail722363.ts.net`
- Check API key matches: `API_SERVER_KEY` in host `.env` == `Authorization: Bearer` in client
- Ensure `GATEWAY_ALLOW_ALL_USERS=true` in host `.env` (or configure platform allowlists)
- Windows firewall: allow port 8642 on Tailscale interface
---

## Reference Files

- `references/tailscale-setup.md` — Detailed Tailscale installation and troubleshooting
- `references/api-server-endpoints.md` — Full API Server endpoint documentation
- `references/stt-setup-windows.md` — faster-whisper STT setup on Windows (venv path pitfall, verification)
- `templates/hermes-termux.sh` — Ready-to-use Termux client script with streaming support