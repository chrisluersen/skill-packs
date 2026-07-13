# AGENT.md Fleet Manifest Reference

**Location:** `~/AppData/Local/hermes\AppData\Local\hermes\AGENT.md`

**Purpose:** Single source of truth for the Hermes Agent Fleet — roster, infrastructure, dispatch table, identity file locations, cron jobs, and project map. Created 2026-07-01 by Stella.

---

## Contents Summary

| Section | Description |
|---------|-------------|
| Fleet Roster | 13 asteroid profiles + default (Stella) with designation, role, profile dir, model, tools |
| Infrastructure | fleet-manager.py, Pub/Sub Event Bus, Router endpoint, Wiki path, Config location |
| Dispatch Table | user shorthand → specialist routing (code→Metis-9, web→Artemis-105, wiki→Klio-84, etc.) |
| Identity Files | SOUL.md, USER.md, MEMORY.md, AGENT.md locations and ownership (tool vs manual) |
| Profile Directories | Tree view of `~/AppData/Local/hermes\AppData\Local\hermes\` with all profile dirs |
| Cron Jobs | Key scheduled jobs: session-registry-sync, klio-weekly, klio-backlog, klio-expansions, task-curator, router-watchdog, fleet-health-watchdog |
| Projects Map | Four projects (Agent Fleet, Dynamic Model Switching, LLM Wiki, Hermes Growth) with lead agents |

---

## Key Conventions Documented

1. **AGENT.md** (singular) — matches SOUL.md, USER.md, MEMORY.md, profile.yaml naming
2. **Location** — `~/AppData/Local/hermes\AppData\Local\hermes\AGENT.md` (Hermes home, not wiki)
3. **Ownership** — Manual file, not managed by memory tool
4. **Separation** — Wiki's `AGENTS.md` is ingest instructions; Hermes' `AGENT.md` is fleet manifest
5. **USER.md / MEMORY.md** — Managed by `memory` tool in `memories/` subdir; do not edit manually

---

## When to Update

- Fleet roster changes (add/remove/rename profiles)
- Infrastructure changes (router port, fleet-manager version, wiki path)
- Dispatch table changes (new specialist, changed routing)
- Identity file location changes
- Cron job schedule changes
- Project map changes

---

## Related Skills

- `hermes-fleet-profiles` — deploys profiles from wiki manifest
- `agent-fleet-management` — fleet operations, pub/sub, MCP servers
- `klio` — wiki librarian (maintains wiki that feeds fleet manifest)
- `hermes-identity-recovery` — tracks agent-created artifacts in wiki