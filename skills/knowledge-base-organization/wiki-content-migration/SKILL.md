---
name: wiki-content-migration
description: "Audit user workspace locations — .hermes/plans/, home directory, Hermes_Artifacts, Documents — and migrate wiki-worthy files into the LLM wiki with proper frontmatter. Covers the full pipeline: survey, classify, frontmatter, copy, update references, clean up originals."
version: 1.0.0
author: Hermes Agent (from session 2026-06-17)
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [wiki, migration, organization, audit, filesystem]
    related_skills: [plan-directory-maintenance, wiki-planning, knowledge-base-organization]
created_from_user_sessions: true
---

# Wiki Content Migration

Use this skill when the user says:
- "check my {folder} for files to move to the wiki"
- "organize these files into the wiki"
- "migrate {X,Y,Z} into the wiki"
- "what should go in the wiki from my {folder}?"
- Any request that involves finding files outside the wiki that belong inside it

This is the **import** sibling of `wiki-planning` (which plans the wiki's growth strategy) and `plan-directory-maintenance` (which keeps `.hermes/plans/` healthy). This skill executes the physical migration of files from scattered locations into the wiki.

---

## The WORKFLOW: Survey → Classify → Move → Update References

### Step 1 — Survey Candidate Origins

Check these locations systematically. Do them in parallel on the first turn:

**Primary (always check):**
- `.hermes/plans/` — companion reference files (non-plan, e.g. stats pages, ecosystem comparisons)
- User home directory (`~/`) — standing files (.json, .csv, .html, .md) on the desktop
- Project checkouts in home dir — e.g. `hermes-webui-fork/docs/architecture/`, `docs/rfcs/` — architecture docs and RFCs that expand wiki concepts. Check with `ls ~/hermes-webui-fork/docs/architecture/*.md ~/hermes-webui-fork/docs/rfcs/*.md 2>/dev/null`.

**Secondary (when user says "rest of my folders"):**
- `~/Hermes_Artifacts/` — Notes/, References/, Scripts/ subdirectories may contain wiki-worthy content
- `~/Documents/` — user-accessible docs, but usually game folders and shortcuts. Still scan.
- `~/Vault/` or other knowledge folders — check for:
  - Orphaned/inline files that should have proper frontmatter
  - External reference implementations (e.g. `Vault/LLM-Wiki-v3-external/`) — external forks of the wiki pattern itself, containing reference AGENTS.md protocols, schema designs, and architecture not captured in the wiki's own `concepts/llm-wiki-pattern.md`
- `~/Desktop/backups/` — backup skills may contain documentation that drifted from live versions. Check `skills/hermes/` and `skills/research/` for stale-but-comprehensive docs that could supplement wiki pages.

Use `ls -la ~/*.md ~/*.json ~/*.csv ~/*.html ~/*.txt 2>/dev/null` for the standing file list, then `find ~/Hermes_Artifacts -type f | sort` for the artifact tree. For project checkouts, check `docs/` and `docs/architecture/` subdirectories specifically.

### Step 2 — Classify Each File

For each candidate, assign one of these types:

| Class | Wiki Destination | Example | Rule |
|-------|-----------------|---------|------|
| **Reference** | `references/<slug>.md` | Ecosystem comparison, stats pages | Durable data that other pages should `[[wikilink]]` to. Static, citation-grade. |
| **Concept** | `concepts/<slug>.md` | Architecture design docs, manifest pages | A wiki concept that overlaps with the fleet's conceptual model. |
| **Entity** | `entities/<slug>.md` | Individual agent definitions | A distinct named entity with its own page. |
| **Raw Source** | `raw/<slug>.json` / `.csv` | Agent profile JSONs, fleet CSVs, architecture JSONs | Provenance data. COPY ONLY — never move (originals may be working files). |
| **Comparison** | `comparisons/<slug>.md` | Tool vs Tool comparison tables | Cross-referencing data that feeds comparison pages. |
| **Plan** | **STAYS in `.hermes/plans/`** | Any file with task/phases/checkboxes | Plans live in `.hermes/plans/` — NOT the wiki. |
| **Working File** | **SKIP** | TODO lists, task artifacts, transient data | Not durable reference content. |
| **Artifact** | Maybe `raw/` | Generated HTML dashboards, backup copies | Usually stays where it is unless important provenance. Judgement call. |

### Step 2b — Content Gap Cross-Reference (before proposing a move)

After classifying, cross-reference each candidate against existing wiki pages BEFORE deciding to migrate. This prevents duplicate or redundant content.

**How to check:**
1. Read the wiki's `index.md` — it lists all indexed pages with descriptions
2. For candidates in broad topic areas (Hermes architecture, fleet agents, LLM wiki patterns), also search the entities/ and concepts/ directories with `ls -1`
3. For each candidate, ask:
   - **New topic** — no existing page covers this → high priority (Tier 1)
   - **Partial overlap** — wiki has a page but it skips this content → expansion candidate (Tier 2). Note what's missing vs what's already covered.
   - **Already covered** — wiki page already has equivalent content → skip. Note the overlap.
   - **Personal/transient** — memory backups, SOUL files, shell history, VS Code configs → skip
   - **Cross-profile** — profile-specific skills/plugins/cron from another Hermes profile → skip (these belong to that profile, not the wiki)

### Step 2c — Choose Entry Path

Two paths for getting content into the wiki:

**Path A — Direct Migration (default):** Move files directly into the wiki with frontmatter. Used when the user says "put this in the wiki" or when content is clearly structured reference material.

**Path B — Staging Path (alternative):** Move files to `~/Downloads/wiki-save/` for the user to review before wiki integration. Used when:
- The user says "move it to my downloads folder" or "downloads for later"
- Content is discovered during a broader cleanup sweep
- The user has not explicitly asked for wiki migration yet
- Files lack clear classification (let the user decide)

In Path B, skip frontmatter creation entirely. Just move/copy to staging and report what's there.

### Step 2c — Triage Output

Present findings as a tiered recommendation table to the user before executing moves:

```markdown
## Content Triage

### 🔴 Tier 1 — Should Migrate (new content, not covered)
| Source | Destination Type | Why |
|--------|-----------------|-----|
| `path/to/file` | concept / entity / references | Brief rationale |

### 🟡 Tier 2 — Partial Overlap / Expand (covered but has gaps)
| Source | Expand Page | Gap |
|--------|-------------|-----|
| `path/to/file` | concepts/existing-page.md | What the file adds |

### ⚪ Skip
| Source | Reason |
|--------|--------|
| `path/to/personal-file.md` | Personal/transient/covered |
```

**Do NOT assume the user wants to proceed** — present the triage and let them confirm. The migration execution (Step 3+) only fires after the user says "go ahead."

> **Reference:** `references/content-triage-framework.md` — full triage rules, skip candidates, common patterns. Use this when you need a more detailed assessment framework than the quick summary above.

**Key rule:** Reference and comparison files move to the wiki. Raw source files are COPIED to `raw/` (originals stay as working copies). Plans stay in `.hermes/plans/`.

### Step 3 — Craft Frontmatter

Every wiki page needs proper YAML frontmatter matching the AGENTS.md schema:

```yaml
---
id: <unique-kebab-slug>
title: Human Title
type: comparison | concept | entity | reference
schema_version: v1
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [tag1, tag2]
sources:
  - url: https://primary-source.com
    rel: primary
  - url: https://secondary.org
    rel: reference
relates_to:
  - page: "existing-wiki-page-name"
    rel: extends | supports | compares | similar | topic
---
```

**Minimum 2 outbound `relates_to` entries** — every page must link to at least 2 other wiki pages.

**No stale companion notes** — remove any old "> **Note:** This is a companion reference..." blockquote that referenced the old location. The frontmatter replaces that.

**Sources** — for web-scraped reference data, list the URLs. For raw JSON data, the `raw/` copy is itself the provenance.

**Tags** — use SCHEMA.md controlled vocabulary. Common patterns: `[hermes, ecosystem, comparison]`, `[reference, atlas, benchmarks]`, `[concept, architecture]`.

### Step 4 — Write or Copy

**For reference/comparison files (from plans):**
- Read the full original file
- Strip old companion notes or stale header comments
- Add proper YAML frontmatter
- Format body for wiki consumption (tables, wikilinks)
- Write to target wiki directory

**For raw data files (from home directory):**
- Simple `cp` to `raw/` — no frontmatter
- Do NOT `mv` (delete original) unless user explicitly confirms
- Exception: CSV/JSON created specifically as wiki input data

### Step 5 — Update Plan References

After migration, fix any plans that referenced the old location:
- Remove moved file from plan's file listing
- Or add note: "→ migrated to wiki `references/<slug>.md`"

### Step 6 — Verify

- `ls -la` target wiki directories to confirm files landed
- Confirm originals removed from plans dir (for reference/comparison moves)
- Present clean summary table to the user

---

## Execution Tips

### Parallelism
- Survey all origins in a single `terminal()` call
- Write all moved wiki pages in parallel `write_file()` calls
- Raw data copies via single `cp` with `&&`

### File Paths (Windows git-bash)
- Use MSYS paths: `/c/Users/<user>/...` or native `C:/Users/<user>/...`
- Escape spaces: `"~/AppData/Local/hermes/AI Architecture.html"`

### Reference vs Comparison Destination
- `comparisons/` — tool-vs-tool tables, framework comparisons
- `references/` — stats data, glossary terms, metrics
- If unsure, `references/` is safer

---

## Common Pitfalls

### Pitfall 1: Moving Raw Data Originals
**Don't** — `mv` agent profile JSON from `~/`. Copy to `raw/` instead.

### Pitfall 2: Missing reles_to
Every page needs 2+ relates_to. Include `hermes-agent` entity + one more content page.

### Pitfall 3: Leaving Stale Companion Notes
The old note says "companion reference for ai-architecture-design-touchup" — strip that in the wiki version. Frontmatter replaces it.

### Pitfall 4: Forgetting to Remove Originals
After moving reference/comparison files from plans to wiki, `rm` the original from plans.

---

## Verification Checklist

- [ ] All origins surveyed (plans, home dir, Hermes_Artifacts, Documents)
- [ ] Every candidate classified
- [ ] Reference/comparison files: frontmatter with 2+ relates_to
- [ ] Stale companion notes removed
- [ ] Raw data: copied (not moved) to `raw/`
- [ ] Originals removed for moved files
- [ ] Plans updated to reference new wiki path
- [ ] Files landed in target directories
