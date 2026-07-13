---
name: windows-cleanup-optimization
description: "Windows cleanup & optimization — caches, startup, services, telemetry, disk health, and performance tuning for desktop PCs."
version: 1.0.0
platforms: [windows]
metadata:
  hermes:
    tags: [windows, cleanup, optimization, performance, privacy, telemetry, user-created]
---

# Windows Cleanup & Optimization

Class-level skill for cleaning, accelerating, and hardening a Windows 10/11 desktop. Use when the user asks to clean, speed up, or optimize their PC; remove unused files/folders; clear caches; trim startup; disable services/telemetry; or check disk health.

## Trigger

- "clean up my PC / user folder / disk space"
- "speed up Windows"
- "remove startup items / disable services"
- "clear cache / temp files"
- "chkdsk / optimize SSD"
- "disable telemetry / tips / ads"
- "reduce bloat / uninstall unused software"
- "computer health and security check"
- "run a security / antivirus / health checkup"
- "health check" when the user means overall system health/security posture review

## Scope

- User-profile directories: `C:\Users\<user>\`, Documents, Downloads, Desktop, AppData
- System-level changes require admin rights; delegate those to the user
- Do not touch Saved Games or OneDrive unless explicitly requested
- Leave `.runelite`/`jagexcache` alone unless explicitly requested; game caches are huge and often locked
- Health/security checks: system info, Defender status, recent updates, user accounts, startup programs, firewall, disk space, listening ports, high-memory processes

## Workflow

1. List current usage before editing anything
2. Identify candidates: temp files, caches, long-unused items (>180 days), stale IndexedDB, duplicate installers/screenshots, empty AI-tool scratch folders
3. Propose a "probably safe" batch for approval
4. Execute approved deletions
5. Verify post-cleanup results (free space, running processes, startup items)
6. Present updated quick-wins list with next items

## Caches & Temp

- `%TEMP%` — almost always safe to clear; stop locked processes first.
- Browser caches (Edge/Brave): remove `Cache`, `Code Cache`, `GPUCache`, `Service Worker`, `Storage\ext`.
- `~/.cache/` — small active runtime; safe to remove unless user depends on cached tool sessions.
- `.codex` — clear via manual delete after killing `extension-host.exe`; keep `.cache/codex-runtimes`.
- `.ollama/cache` — safe to remove; models live in `.ollama/models`.

## Startup Items

- Check both `HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run` and `Startup\\*.lnk`
- Disable one at a time; keep security, drivers, hardware, daily-boot tools
- Group "probably safe" first: launchers, auto-updaters, IDE helpers
- **Durable tracking:** For users who care about boot performance, create a wiki reference doc (`references/startup-apps.md`) with full inventory categorized by impact tier. See `references/startup-app-inventory-workflow.md` for the full audit workflow.

## Privacy Hardening

1. App capability permissions (webcam/mic/docs/pictures/notifications)
2. Telemetry services + scheduled tasks
3. Tips/ads/telemetry registry + policies
4. Windows Update P2P delivery
5. Wi-Fi Sense / auto-join / Hotspot 2.0
6. Browser hardening (Brave Shields strict + prefetch/preconnect off)
7. Search indexing disable if requested
8. Microsoft account disconnect for non-admin daily accounts

## Disk Health

- `chkdsk C: /scan` for bad sectors / file system errors
- SSD TRIM/optimize: `Optimize-Volume -DriveLetter C -ReTrim` (admin)
- Track free space before/after cleanup

## Power & Performance

- Preferred power plan: high-performance or custom
- Disable background timeout throttling if user needs responsiveness
- Visual effects: lean toward "Best performance" with cleartype enabled

## Quick Wins

- Tips/ads/telemetry (ContentDeliveryManager + AdvertisingInfo + DataCollection policy)
- Services (Xbox/Game Bar + telemetry services)
- Idle CPU/RAM probe before/after changes

## Pitfalls

- **Vault placement of startup inventory.** When creating `references/startup-apps.md`, write it to the wiki vault (`C:/Hermes-Vault/references/startup-apps.md`), not to the skill's own `references/` directory. The user expects this artifact in their vault, not buried in AppData. The skill's `references/startup-app-inventory-workflow.md` documents the audit workflow — the output goes in the vault.
- **PowerShell from bash/MSYS:** complex inline `-Command` with quoted strings fails. Write `.ps1` files and invoke with `powershell -NoProfile -ExecutionPolicy Bypass -File <path>`.
- **npm install encoding on Windows (TUI):** `UnicodeDecodeError` on npm output. Fix: `PYTHONIOENCODING=utf-8 npm install` in `ui-tui/`. See `references/windows-npm-encoding-fix.md`.
- **Hermes home cleanup:** Distinguish runtime folders from user artifacts. See `references/windows-hermes-home-cleanup.md`.
- For `taskkill`/`tasklist`/`where` from bash, use `cmd.exe /c` wrapper.
- `.runelite`/`jagexcache` — huge and locked by active game client; never treat as stale unless explicitly cleared.
- Brave IndexedDB domains 180+ days old are safe to clear.
- Registry privacy edits can conflict with enterprise policy.
- Always report: space reclaimed, preserved items and why, next recommended items.
