# Identity File Auto-Sync to Wiki

## Overview
Automatically keep `~/agent-wiki\entities\hermes-identity-files.md` in sync with the live identity files in Hermes home (`~/AppData/Local/hermes\AppData\Local\hermes\`).

## Files Watched
| Source File | Purpose |
|-------------|---------|
| `SOUL.md` | Default profile persona (Stella) |
| `memories/USER.md` | User preferences (memory tool managed) |
| `memories/MEMORY.md` | Agent durable notes (memory tool managed) |
| `AGENT.md` | Fleet manifest |
| `profile.yaml` | Default profile config |
| `config.yaml` | Main Hermes config |
| `profiles/<name>/SOUL.md` (8 profiles) | Per-agent personas |

## Implementation
- **Script:** `~/AppData/Local/hermes\AppData\Local\hermes\scripts\sync-identity-entities.py`
- **Cron Job:** `sync-identity-entities` — every 30m, no_agent, workdir=Hermes home
- **State:** `.identity-sync-state.json` (SHA256 hashes of watched files)

## How It Works
1. Cron runs script every 30 minutes
2. Script computes SHA256 of each watched file
3. Compares against stored state
4. If any changed → regenerates wiki entity from current source files
5. Updates state file with new hashes
6. Wiki entity footer shows: `*Auto-synced from Hermes home on YYYY-MM-DD HH:MM:SS*`

## Key Design Decisions
- **No reference stubs in Hermes root** — user prefers wiki entities as single source of truth for documentation
- **Memory-tool files** (`memories/USER.md`, `memories/MEMORY.md`) are documented in wiki but NOT synced content-wise (tool manages them)
- **Manual files** (SOUL.md, AGENT.md, profile.yaml, config.yaml) are the source of truth — wiki reflects them
- **Per-profile SOUL.md** included so fleet docs stay current when agent personas evolve

## Pitfalls
- Script must run from Hermes home workdir (paths are absolute but state file is relative)
- State file lives in `scripts/` — ensure write permission
- If wiki entity is manually edited, next sync will overwrite — document this in entity header
- Cron runs `no_agent=True` — no LLM tokens burned, pure script execution