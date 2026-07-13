# Content Triage Framework

A reusable framework for evaluating discovered files against an existing wiki and prioritizing migration. Designed for use with `wiki-content-migration` skill's Step 2b — Content Gap Cross-Reference.

## Triaging Rules

### Tier 1 — High Priority (should migrate)

File represents genuinely **new content** not in the wiki. Apply when:

- **New topic** — no wiki page covers this subject at all. The wiki has no entity/concept page with overlapping title, definition, or key claims.
- **Deep architecture design** — wiki has a high-level description but the file contains implementation-level detail (architecture documents, RFC summaries, design decision records with trade-off analysis).
- **Reference data** — stats, benchmarks, comparison tables that other wiki pages could cite. Check `references/` dir first; if an equivalent doesn't exist, it's Tier 1.
- **External reference implementations** — forks or derivative projects of your own system with different design choices, documented in a way that adds a perspective not captured in the wiki. (e.g. `LLM-Wiki-v3-external/` vs the resident `llm-wiki-pattern.md` concept page.)

### Tier 2 — Medium Priority (partial overlap / expansion)

Wiki **already covers the topic** but the file adds valuable detail. Apply when:

- **Missing section** — wiki page exists but the file covers a subtopic the wiki doesn't (e.g. wiki has "architecture" concept but file adds Glossary or Migration Path sections).
- **Alternative perspective** — the file presents the same subject from a different angle (e.g. wiki covers Hermes features from user perspective, file covers the developer architecture).
- **Outdated wiki entry** — the file is more recent/accurate than the wiki page. Note what changed and flag as update candidate.
- **Companion to a plan** — the file is referenced by an active `.hermes/plans/` document. Check if the plan says "→ moved to wiki" — if so, the companion was already extracted and the plan is authoritative.

### Skip — Not Wiki Material

File should **not** enter the wiki. Apply when:

- **Personal data** — memory backups (MEMORY.md, USER.md), SOUL persona files, skill backups. These belong to the agent's persistent memory or skill library, not the wiki's general knowledge.
- **Transient state** — session working files, TODO lists, terminal history, temp scripts.
- **VS Code / IDE configs** — `.code-workspace`, `.vscode/`, `.cursor/`, `.claude/` project configs.
- **Already covered** — content exists 1:1 in an existing wiki page.
- **Intentionally de-wiki'd** — file has a note saying "moved from wiki to `.hermes/plans/`" or similar. Respect that decision — it was placed outside the wiki for a reason.
- **Cross-profile artifacts** — skills/plugins/cron from another Hermes profile. These belong to that profile's environment, not the wiki.

## Triage Output Template

```
## Content Triage

### 🔴 Tier 1 — Should Migrate
| Source | Destination | Rationale |
|--------|-------------|-----------|
| path/to/file | entities/concepts/... | One-liner on gap |

### 🟡 Tier 2 — Partial Overlap / Expand
| Source | Expand Page | Gap |
|--------|-------------|-----|
| path/to/file | existing-page.md | What it adds |

### ⚪ Skip
| Source | Reason |
|--------|--------|
| path/to/file | Personal / covered / etc. |
```

## Common Skip Candidates (Quick Reference)

| File | Always Skip? | Notes |
|------|-------------|-------|
| `.claude/` AGENTS.md | Yes | Project-specific agent context |
| `.hermes/plans/*.md` | Usually | Plans stay in plans dir |
| `Desktop/backups/MEMORY.md` | Yes | Personal memory |
| `Desktop/backups/USER.md` | Yes | User profile |
| `Desktop/hermes-backup-*/SOUL.md` | Yes | Persona definition |
| `OneDrive/hermes.code-workspace` | Yes | VS Code workspace config |
| `OneDrive/*.png` | Usually | Visual layouts — wiki has textual structure |
| `*.html` standalone | Maybe | If it's a self-contained reference doc (like AI Architecture.html), add as a `sources/` entry and extract key sections. Skip if it's a generated artifact/backup copy. |
| `raw/*` in wiki dir | Yes | Already in the wiki |
