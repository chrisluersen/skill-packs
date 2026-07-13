# Tailscale Setup Details for Hermes Remote Access

## Installation by Platform

### Windows
```powershell
# Winget (recommended)
winget install --id Tailscale.Tailscale --silent --accept-source-agreements --accept-package-agreements

# Or download installer
# https://tailscale.com/download/windows
```

### Linux
```bash
# One-liner
curl -fsSL https://tailscale.com/install.sh | bash

# Or package manager
# Ubuntu/Debian: sudo apt install tailscale
# Arch: sudo pacman -S tailscale
# Fedora: sudo dnf install tailscale
```

### macOS
```bash
brew install --cask tailscale
# Or App Store
```

### Android (Termux)
- **Play Store**: Search "Tailscale"
- **F-Droid**: Add repo `https://f-droid.tailscale.com/` then install
- **APK**: https://pkgs.tailscale.com/stable/#android

---

## Authentication Flow

```bash
tailscale up
```

Output:
```
To authenticate, visit:

    https://login.tailscale.com/a/<unique-code>
```

1. Open URL in **any browser** (can be on phone)
2. Sign in or create free Tailscale account
3. Authorize the device
4. Command completes → device appears in admin console

### Verify Connection
```bash
tailscale status
# Or JSON for scripting
tailscale status --json | jq -r '.Self.TailscaleIPs[0]'
```

Returns stable `100.x.y.z` IP (CGNAT range, routes via Tailscale mesh).

---

## Useful Commands

| Command | Purpose |
|---------|---------|
| `tailscale status` | Show peer list, connection state |
| `tailscale ip -4` | Show your Tailscale IPv4 |
| `tailscale ip -6` | Show your Tailscale IPv6 |
| `tailscale ping <peer>` | Test connectivity to another node |
| `tailscale logout` | Disconnect from tailnet |
| `tailscale up --accept-routes` | Accept subnet routes from other nodes |
| `tailscale set --operator=$USER` | Allow non-root management (Linux) |

---

## Troubleshooting

### "BackendState": "NeedsLogin"
- Visit the printed AuthURL in browser
- Complete sign-in
- Run `tailscale status` again

### "BackendState": "Stopped"
```bash
tailscale up
```

### No connectivity to peer
```bash
# Check both nodes online
tailscale status

# Test direct connectivity
tailscale ping <peer-ip-or-name>

# Check firewall (Windows)
Get-NetFirewallProfile | Where-Object {$_.Enabled -eq $true}

# Linux: check tailscaled service
systemctl status tailscaled
```

### Windows: Tailscale service not starting
```powershell
# Restart service
Restart-Service "Tailscale IPN"
# Or reboot
```

### Android Termux: Cannot resolve Tailscale IPs
- Ensure Tailscale app is running and connected
- Termux uses Android's DNS; Tailscale MagicDNS may not propagate
- Use raw `100.x.y.z` IP instead of MagicDNS name

---

## Tailscale + Hermes Gateway Notes

- **Tailscale IP is stable** — survives reboots, network changes, roaming
- **No port forwarding needed** — Tailscale handles NAT traversal
- **Firewall**: Windows may prompt first time gateway binds to 0.0.0.0:8080 — allow on "Tailscale" network profile
- **Multiple devices**: Each gets unique 100.x.y.z; all can reach each other
- **Exit nodes**: Optional — route all traffic through a designated node

---

## Security Considerations

- Tailscale uses WireGuard® — encrypted, authenticated mesh
- Each device has unique key pair; keys rotate periodically
- Access controls (ACLs) in admin console: https://login.tailscale.com/admin/machines
- For Hermes: Consider binding API Server to `100.x.y.z` only (not `0.0.0.0`) if you want Tailscale-only access
  ```bash
  hermes config set gateway.api_server.host <TAILSCALE_IP>
  ```