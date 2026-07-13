# Tailscale Remote Access for zellij/neovim/herm Stack

Research conducted: 2026-06-18
## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        WSL UBUNTU                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐ │
│  │   zellij    │  │  herm TUI   │  │  Hermes Router/Gateway  │ │
│  │ (web:8082)  │  │             │  │  (port 8319)            │ │
│  │   + HTTPS   │  │             │  │                         │ │
│  └──────┬──────┘  └──────┬──────┘  └───────────┬─────────────┘ │
│         │                │                      │               │
│         └────────────────┼──────────────────────┘               │
│                          ▼                                      │
│              ┌─────────────────────┐                            │
│              │    Tailscale        │                            │
│              │  (serve / funnel)   │                            │
│              └──────────┬──────────┘                            │
└─────────────────────────┼──────────────────────────────────────┘
                          ▼
              ┌─────────────────────┐
              │   YOUR PHONE        │
              │  Browser / SSH App  │
              └─────────────────────┘
```

---

## Four Access Methods

| Method | What You Get | Client | Best For |
|--------|--------------|--------|----------|
| **1. Zellij Web Client** | Full zellij UI in browser (panes, tabs, sessions) | Any browser (phone Safari/Chrome) | Quick edits, review, herm chat |
| **2. SSH + Mosh** | Native terminal app, roaming, low latency | **Blink, Termius, Prompt (iOS) • Termux, Termius, JuiceSSH (Android)** | Serious coding, offline resilience |
| **3. Tailscale SSH** | Zero-config SSH, no keys, ACL-controlled | Any SSH client | Simplest setup, team access |
| **4. Hermes Gateway + Dashboard** | Web UI for Hermes Agent (chat, tools, sessions) | Browser | Hermes-specific work, not full dev env |

---

## Method 1: Zellij Web Client (Easiest)

### Server (WSL)
```bash
# Start zellij with web server enabled
zellij --session dev --web-server

# Or in config.kdl:
web-server {
  bind "0.0.0.0:3333"
  authenticated false  # or true with password
}
```

### Tailscale Setup
```bash
# On WSL: install tailscale
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --accept-dns --ssh

# Note your Tailscale IP
tailscale ip -4
# e.g., 100.x.y.z
```

### Phone Access
1. Install **Tailscale** app on phone, sign in same account
2. Open browser → `http://100.x.y.z:3333`
3. Full zellij UI: panes, tabs, sessions, herm, lazygit, everything

### Pros/Cons
| ✅ Pros | ❌ Cons |
|---------|---------|
| Zero client install (browser) | No true terminal (no tmux prefix, limited keys) |
| Works on iOS Safari / Android Chrome | Text selection/scroll can be finicky |
| Sees exact server state | Requires WebSocket support |
| No SSH keys needed | Latency over internet |

---

## Method 2: SSH + Mosh (Best Experience)

### Server (WSL)
```bash
sudo apt install mosh openssh-server
sudo systemctl enable ssh --now
# Or: sudo service ssh start (WSL)

# Tailscale SSH (recommended - no keys)
sudo tailscale up --ssh
```

### Phone Clients — Deep Comparison

| Feature | **Blink Shell (iOS)** | **Termius (iOS/Android)** | **Prompt 3 (iOS)** | **Termux (Android)** | **JuiceSSH (Android)** |
|---------|----------------------|---------------------------|-------------------|----------------------|------------------------|
| **Mosh** | ✅ Native, first-class | ✅ Native | ✅ Native | ✅ `pkg install mosh` | ✅ Plugin |
| **Background** | ✅ Always On mode | ⚠️ Limited (iOS) | ⚠️ Limited (iOS) | ✅ **Full background** | ⚠️ Limited |
| **Price** | $19.99 once | Free / $12/mo Pro | $9.99 once | **Free (F-Droid)** | Free / $9.99 Pro |
| **Sync** | iCloud (settings) | **Full cloud sync (Pro)** | iCloud | Manual (GitHub/dotfiles) | Google Drive (Pro) |
| **Scripting** | Lua (limited) | Snippets (Pro) | Limited | **Full shell (bash/zsh/fish)** | Limited |
| **Termux API** | ❌ | ❌ | ❌ | ✅ Notifications, GPS, sensors | ❌ |
| **Best For** | **iOS power users, Mosh + background** | Teams, cross-platform sync | iPad + hardware keyboard | **Android power users, full Linux** | Quick SSH, widgets |

### iOS "Termux Equivalents" — Debunked

| App | What It Is | Mosh? | Verdict |
|-----|------------|-------|---------|
| **a-Shell** | Lua/Python/JS REPL | ❌ | Scripts only |
| **iSH** | Alpine via x86 emulation | ⚠️ Slow | Too slow for dev |
| **Secure ShellFish** | Files app SSH client | ❌ | File transfer only |

**Bottom line: No true Termux equivalent on iOS.** Blink Shell is the closest for terminal work.

### Termux Superpowers (Android Only)

- **Full package manager** — `pkg install neovim zellij rust go lazygit sqlite3 postgresql-client`
- **Termux:API** — Notifications, GPS, sensors, clipboard, TTS, vibration, contacts, battery
- **Termux:Widget** — One-tap launch scripts from home screen
- **Wake locks** — `termux-wake-lock` keeps CPU alive for long builds
- **SSH agent** — `eval $(ssh-agent)` + `ssh-add` works natively
- **F-Droid version** — No Google Play restrictions, auto-updates

### Connect
```bash
# From phone terminal app:
mosh user@100.x.y.z --ssh="ssh -p 22"
# Or with Tailscale SSH:
mosh user@hostname.tailnet.ts.net --ssh="ssh -p 22"

# Attach to existing zellij session:
mosh ... -- zellij attach dev

# Or start new:
mosh ... -- zellij --session dev
```

### Pros/Cons
| ✅ Pros | ❌ Cons |
|---------|---------|
| True terminal — all keys work | Requires client app install |
| **Mosh: roaming** (IP change = no disconnect) | iOS: background = disconnect (Blink handles best) |
| Low latency, predictive echo | WSL: mosh-server needs UDP ports open |
| Works offline briefly (Mosh) | Slightly more setup |

---

## Method 3: Tailscale SSH (Simplest)

### Server
```bash
# One command on WSL
sudo tailscale up --ssh --accept-dns

# ACL in admin console (tailnet):
# tag:dev-server -> autoconnected users
```

### Phone
```bash
# Any SSH client (Termius, Blink, Termux)
ssh user@hostname.tailnet.ts.net

# Or Tailscale CLI on phone (Termux):
tailscale ssh hostname
```

### Pros/Cons
| ✅ Pros | ❌ Cons |
|---------|---------|
| No key management | Requires Tailscale account on phone |
| ACL-based access control | No Mosh roaming (plain SSH) |
| Works with any SSH client | Slightly higher latency than Mosh |
| Audit logs in admin console | |

---

## Method 4: Hermes Gateway + Dashboard (Hermes-Only)

### Server
```yaml
# config.yaml
hermes:
  gateway:
    host: "0.0.0.0"
    port: 8319
    enabled: true
  dashboard:
    host: "0.0.0.0"
    port: 8080
    enabled: true
```

```bash
hermes gateway start
hermes dashboard start
```

### Phone Access
| Service | URL | What You Get |
|---------|-----|--------------|
| **Gateway API** | `http://100.x.y.z:8319` | REST API for Hermes |
| **Dashboard** | `http://100.x.y.z:8080` | Web UI: chat, tools, sessions, config |

### Pros/Cons
| ✅ Pros | ❌ Cons |
|---------|---------|
| Purpose-built for Hermes | Not a full dev environment |
| No terminal needed | Can't run neovim/lazygit/btop |
| Works in any browser | Separate from zellij sessions |

---

## Recommended Setup for You

### Primary: **SSH + Mosh + zellij attach**
```bash
# WSL: one-time setup
sudo apt install mosh openssh-server
sudo tailscale up --ssh --accept-dns

# Phone: Blink Shell (iOS) or Termux (Android)
# Connection: mosh user@100.x.y.z -- zellij attach dev
```

### Fallback: **Zellij Web Client**
```bash
# WSL: add to zellij config.kdl
web-server {
  bind "0.0.0.0:3333"
  authenticated true
  password "your-secure-password"
}

# Phone: browser → http://100.x.y.z:3333
```

### Bonus: **Hermes Gateway** for Hermes-only tasks
```bash
# Quick Hermes chat without full terminal
# Browser → http://100.x.y.z:8080
```

---

## Security Checklist

- [ ] **Tailscale ACLs**: Restrict who can SSH to dev machine
- [ ] **Zellij web password**: Enable auth if exposing web client
- [ ] **SSH keys**: Use Tailscale SSH (no keys) or ed25519 keys
- [ ] **Mosh UDP**: Open UDP 60000-61000 in Windows Firewall for WSL
- [ ] **Hermes gateway**: Bind to Tailscale IP only, not 0.0.0.0

```powershell
# Windows Firewall for Mosh (run as Admin)
New-NetFirewallRule -DisplayName "Mosh UDP" -Direction Inbound -Protocol UDP -LocalPort 60000-61000 -Action Allow
```

---

## Phone-Specific Tips (Enhanced)

### iOS (Blink Shell — Recommended)
- **Always On** background mode (Settings → Always On) — keeps connection alive
- **Mosh** built-in — just add `mosh` command in host config
- **Hardware keyboard** support (iPad + Magic Keyboard = great)
- **Touch gestures**: two-finger scroll, pinch zoom
- **Cost**: $19.99 one-time — best investment for iOS terminal work

### Android (Termux — Recommended)
```bash
pkg install mosh openssh neovim zellij rust go lazygit sqlite3 postgresql-client
mosh user@100.x.y.z -- zellij attach dev
```
- **Termux:API** for notifications, sensors, GPS, clipboard, TTS
- **Termux:Widget** for one-tap launch from home screen
- **Wake locks** — `termux-wake-lock` keeps CPU alive for builds
- **F-Droid version** preferred (no Google Play restrictions, auto-updates)
- **Cost**: Free (open source)

---

## Quick Decision Matrix (5-Second Choice)

| Your Phone | Want Native Terminal + Mosh | Pick |
|------------|----------------------------|------|
| **iOS** | Yes | **Blink Shell** ($19.99) |
| **iOS** | No (browser OK) | Zellij Web Client |
| **Android** | Yes | **Termux** (Free, F-Droid) |
| **Android** | No (browser OK) | Zellij Web Client |
| **Both** | Cross-device sync | Termius Pro ($12/mo) |

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Zellij web client: "certificate not trusted" | Use mkcert, or `enforce_https_on_localhost false` (dev only) |
| Tailscale serve: 502 Bad Gateway | Check service is running on localhost port, check Tailscale logs |
| Mosh: connection timeout | UDP ports 60000-61000 must be open; Tailscale handles NAT traversal |
| SSH: permission denied | Ensure `~/.ssh/authorized_keys` has correct perms (600), check SSH config |
| Phone: can't resolve `<machine>.tailnet.ts.net` | Ensure Tailscale is running on both devices, check MagicDNS enabled |

---

## Recommendation for This Stack

| Goal | Primary Method | Fallback |
|------|----------------|----------|
| **Code on phone** | SSH + Mosh (Blink/Termux) | Zellij Web Client |
| **Quick terminal check** | Zellij Web Client | SSH |
| **Monitor Hermes** | Hermes Dashboard (web) | Zellij Web Client (herm pane) |
| **Run AI apps on phone** | Hermes Gateway API | — |

**Start with:** SSH + Mosh via Tailscale SSH (zero config) + Blink Shell (iOS) / Termux (Android).
Add Zellij Web Client for browser access when you don't have your phone.