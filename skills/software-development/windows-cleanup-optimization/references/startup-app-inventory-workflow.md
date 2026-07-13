# Startup App Inventory & Boot Performance Tracking

Procedure for auditing all Windows startup programs, categorizing by performance impact, and creating a durable reference document (wiki entity or reference page) that persists across sessions.

## When to Use

- User asks "what starts on boot?"
- User wants to reduce boot time / startup load
- Adding a new app and want to track its boot impact
- Diagnosing slow boot / high idle resource usage

## Workflow

### 1. Enumerate All Startup Items

Three sources cover everything:

**Source A — Startup folder (shell:startup)**
```bash
ls -la "/c/Users/<user>/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/"
```

**Source B — Registry (HKCU + HKLM)**
```bash
powershell.exe -Command "Get-CimInstance Win32_StartupCommand | Select-Object Name,Command,Location,User | Format-Table -AutoSize"
```

**Source C — Task Scheduler startup triggers** (apps registered as tasks)
```bash
powershell.exe -Command "Get-ScheduledTask | Where-Object { $_.Settings.AllowStartIfOnBatteries -or $_.Triggers.Enabled -contains $true } | Select-Object TaskName,State,Triggers | Format-Table -AutoSize"
```

### 2. Classify Each Item

| Tier | Label | Definition |
|------|-------|------------|
| 🟢 Essential | Keep | Needed for core operation (VPN, sync, Hermes infrastructure) |
| 🟡 Optional | Keep but could disable | Secondary to primary workflow (e.g. Google Drive if OneDrive is primary) |
| 🔴 Performance Hitter | Review candidate | Heavy boot impact (Docker, Ollama, game launchers) |

Impact types:
- **Heavy:** VM-based (Docker), model-loader (Ollama), GPU constantly bound (WallpaperEngine)
- **Medium:** Electron apps (Discord), game launchers (Steam, Battle.net), driver suites (Razer)
- **Light:** Small tray icons, sync agents, security health

### 3. Create a Durable Reference Document

Write the inventory to the wiki so it survives across sessions:

```
C:/Hermes-Vault/references/startup-apps.md
```

Structure:
- **Table of all items** with name, launcher source, impact rating, notes
- **Grouped by tier** (Essential / Optional / Performance Hitters)
- **Management section** explaining how to disable each type (Task Manager Startup tab vs shell:startup vs registry)
- **Performance baseline** — notes on what was measured (Windows Startup Impact rating from Task Manager)

### 4. Wire to Entity Tracking

Update the relevant entity (`fix-self-startup-apps` or equivalent):
- Set `task_status: in_progress`
- Update `next_action` to reference the new doc
- After user decides what to disable, execute and mark `task_status: completed`

### 5. Disable Selected Items

**Easiest method — Task Manager Startup tab:**
Press Ctrl+Shift+Esc → Startup tab → right-click → Disable

**For Startup folder items (.vbs, .lnk, .cmd):**
Move the file out of the folder rather than deleting (can restore later).

**For registry items:**
```powershell
# HKCU (current user)
Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "AppName"
# HKLM (all users — requires admin)
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "AppName"
```

### 6. Verify & Update Reference

After disabling, check Task Manager Startup tab to confirm status changed to "Disabled". Update the reference doc with the new status and date.

## Pitfalls

- **Don't disable security software** (Defender, firewall, etc.)
- **VBS launchers** (Hermes Cron Ticker, Router, Brave) live in the Startup folder — if you disable them, Hermes crons and router won't auto-restart after reboot
- **Registry items may have duplicate entries** (Google Drive FS appeared 3× on this machine) — deduplicate in the reference doc but only disable once
- **Impact rating is heuristic** — Windows Task Manager's "Startup impact" column is the ground truth. Cross-reference your ratings with it.
- **Performance tracking is permanent** — once you create a startup-apps.md reference, maintain it as apps are added/removed. The user will expect it to reflect current state.
