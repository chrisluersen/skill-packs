# Second Brain Setup — Current State & Checklist

> Assessed 2026-06-20 session. Foundation exists; "second brain" layer not configured.

## Existing State

| Layer | Status | Detail |
|-------|--------|--------|
| Obsidian installation | ✅ | Installed, `AppData/Roaming/Obsidian/` config present |
| Vault registration | ✅ | `~/AppData/Local/hermes\Vault` registered in `obsidian.json`, currently open (`"open": true`) |
| Wiki inside vault | ✅ | `Vault/wiki/` — 206 pages containing LLM wiki |
| Core plugins | ✅ | Graph, backlinks, templates, daily-notes, properties, file-recovery, sync, bases all enabled |
| `.obsidian/` config | ✅ | `core-plugins.json`, `graph.json`, `workspace.json` populated |
| Wiki knowledge | ✅ | `concepts/obsidian.md` page exists; Phase 11 documented PARA + Intermediate Packets |

## Missing — Second Brain Layer

### 1. Community plugins (install via Obsidian Settings → Community plugins → Browse)

| Plugin | Purpose | Priority |
|--------|---------|----------|
| **Dataview** | SQL-like queries over YAML frontmatter (wiki dashboards, stats, page lists) | P0 — wiki depends on this for auto-generated listings |
| **Templater** | Template system with frontmatter variables, date insertion, file naming | P1 — consistent page creation |
| **Kanban** | Render markdown checklists as kanban boards | P2 — task management UI |
| **Git plugin** | Stage/commit from within Obsidian | P2 — optional, LLM handles git |

### 2. Directory structure (create at vault root `~/AppData/Local/hermes\Vault\`)

| Directory | Purpose | Signal |
|-----------|---------|--------|
| `_templates/` | Note templates for consistent frontmatter | Mentioned in `concepts/obsidian.md` Quick Start section |
| `inbox/` | Rough human-generated captures awaiting LLM triage | Described in wiki as "Inbox Pattern" |
| `Artifacts/` | Target for proactive artifact-saving from the `obsidian` Hermes skill | SKILL.md references this path |

### 3. Environment variable

| Variable | Value | Why |
|----------|-------|-----|
| `OBSIDIAN_VAULT_PATH` | `~/AppData/Local/hermes\Vault` | The `obsidian` skill checks this first — without it, every tool call falls back to memory guessing |

### 4. Theme

| Item | Status |
|------|--------|
| Community theme | ❌ Not installed — `appearance.json` is empty `{}` |
| Recommended: Minimal, Blue Topaz, or Things | Any dark theme with good Dataview support works |

### 5. Cleanup

| Item | Detail |
|------|--------|
| `Captures/` | 135+ screenshot PNGs dating Jun 10–20 — clutter in vault root. Needs organization or archival |

## Estimated Setup Effort

~30 minutes total:
- 5 min: Install 4 community plugins (restart Obsidian once)
- 5 min: Create 3 directories
- 2 min: Set env var (add to `~/.hermes/.env` or wherever Hermes loads it)
- 5 min: Install and apply theme
- 10 min: Create `_templates/note.md` starter template
- Optional: Archive `Captures/` screenshots
