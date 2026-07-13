# Windows + Hermes Home Cleanup Notes

## Hermes folder layout on Windows
- Canonical Hermes home: `C:\Users\<user>\AppData\Local\hermes\`
- Runtime files: `config.yaml`, `state.db`, `auth.json`, `logs/`, `sessions/`, `cron/`, `skills/`, `webui/`, `cache/`
- `C:\Users\<user>\.hermes\` is scratch/runtime overlap only; not the main home unless explicitly configured that way
- Safe cleanup outcome: one canonical runtime folder under `AppData\Local\hermes\`, with `Downloads/` for user-facing artifacts

## Hermes Default/Runtime Folders (created by Hermes on first use)
| Folder | Purpose | Created When |
|--------|---------|--------------|
| `audio_cache/` / `cache/audio/` | TTS audio cache | First TTS use |
| `cache/documents/` | Document cache | First doc processing |
| `cache/images/` / `image_cache/` | Image generation cache | First image generation |
| `cache/screenshots/` | Browser screenshots | First browser use |
| `interrupt_debug.log` | Runtime crash/debug log | On error/crash |
| `kanban/` + `kanban.db*` | Kanban board DB & workspaces | Kanban enabled |
| `memories/` + `MEMORY.md`/`USER.md` | Agent memory system | First memory write / `hermes doctor --fix` |
| `pastes/` | Paste buffer (large pastes → files) | First 5+ line paste |
| `sandboxes/` | Terminal execution sandboxes | First code execution |
| `skills/` | Built-in skills directory | Hermes install/update |
| `logs/` | Session logs | First session |
| `sessions/` | SQLite session store | First session |
| `state.db` | Agent state SQLite | First session |
| `auth.json` | Auth tokens | First auth |
| `config.yaml` | User config | First run / `hermes config` |
| `cron/` | Scheduled jobs | First cron job |
| `webui/` | WebUI assets/sessions | WebUI install |

## Migration pattern: compress before delete
- When consolidating Hermes vaults/system folders into `AppData\Local\hermes\`:
  1. Move/copy stateful folders first: `config.yaml`, `cron/`, `skills/`, `webui-docs/`, `wiki/`, `legacy-wiki/`
  2. Keep a backup of old `config.yaml` separately if needed
  3. Do not run destructive deletes until the destination files are verified present
- PowerShell `Copy-Item` from inside `ObsidianHermesVault` to `AppData\Local\hermes\` is fine, but prefer `Move-Item`/`robocopy` follow-up to avoid duplicate source files remaining

## PowerShell quoting pitfall on Windows
- Inline `powershell -Command '...'` from MSYS/bash often strips quotes/variables. Examples that fail:
  - `$src=...; $dest=...` becomes `=...`
  - Quoted paths with backslashes get mangled
- Fix: write a `.ps1` to `Desktop/` and run:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\<user>\Desktop\script.ps1`
- For extremely simple moves, `cmd /c 'move ...'` or direct bash `mv` with `$HOME` translation works

## MSYS/bash path behavior
- `/c/Users/<user>/AppData/Local/hermes/` and `C:\Users\<user>\AppData\Local\hermes\` both work, but never mix the two styles in one command
- MSYS `mv -f` is fine for simple moves; `cp`/`robocopy` often needs absolute Windows paths
- `find ... -maxdepth N -mindepth 1` is reliable for inventory before acting

## What should stay local vs Downloads
- Keep in `AppData\Local\hermes\`: runtime state, config, skills, cron, webui sessions
- Move to `Downloads/`: repos, artwork, wireframes, installers, generated image/video exports, `egg-info/` build artifacts
- Keep in `~/`: game caches (`.runelite` unless requested), `Captures/`, OneDrive, iCloudDrive

## Safe cleanup checklist
1. Inventory with `find`/`dir`
2. Propose move batches explicitly
3. Verify destination contains expected files
4. Remove sources only after verification
5. Retain betas via `.bak` rename before deleting folders the tooling might still reference
