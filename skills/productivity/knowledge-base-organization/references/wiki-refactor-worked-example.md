# Worked Example: Refactoring a Hermes Wiki from Ground Up

This reference documents the exact workflow from a 2026-06-16 session that refactored
`~/AppData/Local/hermes\wiki` from a flat collection into a structured knowledge base.

## Source Material

- **Spec doc**: `refactor-wiki.md` (in Obsidian vault) — defined page types, naming, frontmatter
- **Content source**: `raw/Hermes Agent — Full Documentation.md` — the canonical Hermes reference
- **Existing files**: index.md, log.md, SCHEMA.md, raw/ directory

## Target Structure Produced

```
wiki/
├── nav.md                  # Quick-jump navigation
├── index.md                # Full catalog
├── SCHEMA.md               # Schema (preexisting)
├── log.md                  # Activity log
├── entities/
│   ├── hermes-agent.md     # Core agent
│   └── nous-research.md    # The org
├── concepts/               # 17 concept pages
│   ├── acp.md, mcp.md, profiles.md, ...
│   ├── delegation.md, cron-jobs.md, tui.md, ...
│   ├── security.md, tool-gateway.md, skills-system.md, ...
│   └── context-compression.md, terminal-backends.md, ...
├── comparisons/            # 3 comparison pages
│   ├── cli-vs-tui.md
│   ├── native-vs-wsl2.md
│   └── terminal-backend-comparison.md
└── queries/                # 2 query pages
    ├── hermes-installation.md
    └── hermes-feature-index.md
```

## Workflow Steps (as executed)

### Step 1: Read the spec
Loaded `refactor-wiki.md` from the vault to understand page types (entities/concepts/comparisons/queries).

### Step 2: Survey existing wiki
- Read SCHEMA.md, index.md, log.md
- Listed existing files with `search_files`
- Identified source material in `raw/`

### Step 3: Plan
Planned the full page taxonomy before creating anything:
- 2 entity pages, 17 concept pages, 3 comparisons, 2 queries
- Each with specific source sections from the raw doc

### Step 4: Create directory structure
```bash
mkdir -p "~/AppData/Local/hermes/wiki/entities"
```

### Step 5: Create nav.md
Quick-jump reference at `~/AppData/Local/hermes\wiki\nav.md` with links to each section.

### Step 6: Create entity pages
Created `hermes-agent.md` first (most-referenced entity), then `nous-research.md`.

### Step 7: Create concept pages (17 pages, 3 batches)
Batch 1: Protocol + infrastructure (mcp, acp, tool-gateway, skills-system, profiles, profile-distributions)
Batch 2: Interface + optimization (tui, context-compression, delegation, cron-jobs, multi-profile-gateways)
Batch 3: Backend + safety (terminal-backends, checkpoints-rollback, git-worktrees, security, messaging-gateways, subscription-proxy)

Each page:
- YAML frontmatter with `type: concept`, `created`, `updated`, `tags`, `sources`, `confidence`
- Body: definition, how-it-works (tables), configuration (if applicable), `Related Pages`
- `[[wikilinks]]` to related pages (2+ per page)

### Step 8: Create comparison pages (3 pages)
Side-by-side at-a-glance tables with use-case guidance.

### Step 9: Create query pages (2 pages)
Direct answers at top with expanded context below.

### Step 10: Update index.md
Full catalog table with counts, update date, total pages.

### Step 11: Append to log.md
Dated entry with what was created and final page count.

## Key Decisions Made

- **Entities first** — Entity pages were created before concept pages so concept pages could link to them
- **Batched writes** — 17 concept pages created in 3 parallel batches to reduce round-trips
- **Nav as quick-jump** — nav.md in root serves as a reference, not a replacement for index.md
- **Log update last** — log entry written after everything was verified

## Source Extraction Pattern

For each concept page, extracted content from the raw doc using:
1. `grep -n "^## <Topic>"` to locate the section
2. `sed -n '<start>,<end>p'` to extract the exact range
3. Synthesized into the wiki page structure (not copied verbatim)
4. Linked to related concepts that had their own page

---

## Second Wave: Deep-Dive Expansion via delegate_task

**Date:** 2026-06-16 (continued after context compaction)

**Trigger:** Initial 25 pages covered the essentials; 11 more needed for deep-dive features.

**Key innovation:** Used `delegate_task` for parallel content mining instead of reading the 2.9MB doc directly.

### Workflow

1. **Survey remaining sections** — used `grep "^## "` to find un-extracted topics
2. **Spawn parallel extraction agent:**
   ```
   delegate_task(
     goal="Extract key content for 11 topics from Hermes Agent docs...",
     context="File path, tools: terminal+grep, each topic gets its own extraction",
     toolsets=["terminal", "file"]
   )
   ```
3. **Received 11.5K chars of structured summaries** — never loaded the 2.9MB doc into context
4. **Batch-created 10 concept pages + 1 query page** with `write_file` in parallel
5. **Updated index.md** (25→36 pages) and **log.md** in sequence

### Why delegate_task won here

| Approach | Cost |
|----------|------|
| Read 2.9MB doc directly | Swamps context, 100k+ char reads |
| Manual grep per page | 11 round-trips |
| **delegate_task extractor** | **1 call, returns 11.5K chars of usable content** |

### New pages added in this wave

| Page | Section extracted |
|------|-----------------|
| api-server | OpenAI-compatible HTTP server |
| approvals | Permission tiers (allow/ask/deny) |
| batch-processing | Running 100s of prompts |
| browser-automation | Camofox, Browserbase, CDP |
| context-files | SOUL.md, AGENTS.md, personality |
| hooks-events | 3 hook systems |
| plugins | 4 plugin types |
| provider-routing | Multi-provider + fallback chains |
| voice-mode | TTS/STT providers |
| webui-dashboard | React UI, Kanban board |
| hermes-configuration | Config.yaml + env vars ref |
