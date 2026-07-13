---
name: knowledge-base-organization
description: >-
  Structure a flat set of markdown files into a categorized, cross-linked wiki/knowledge base
  following a spec document. The complement to knowledge-consolidation: instead of merging many
  files into one, take one source and expand into many organized pages.
category: productivity
created_from_user_sessions: true
---

# Knowledge Base Organization

Structure a flat collection of markdown files into a categorized, cross-linked wiki with entities,
concepts, comparisons, and query pages — all driven by a reference spec document.

## Trigger

User says any of:
- "Use this .md to refactor [directory] from the ground up"
- "Restructure my wiki using [spec file]"
- "Reorganize [dir] into entities/concepts/comparisons"
- "Build a knowledge base from these docs"
- Uploads a spec document and points to a wiki/knowledge directory

## Page Type Taxonomy

| Type | Directory | Frontmatter `type:` | Purpose |
|------|-----------|-------------------|---------|
| Entity | `entities/` | `type: entity` | A concrete thing (person, org, tool, product, project) with a stable definition |
| Concept | `concepts/` | `type: concept` | An abstract idea, design pattern, protocol, mechanism |
| Comparison | `comparisons/` | `type: comparison` | Side-by-side reference of two or more options |
| Query | `queries/` | `type: query` | A question with a definitive answer, maintained as living reference |

## Workflow

### Phase 1: Understand the Spec

1. **Identify the spec document** — the .md file the user provides. If the user says "download/review this .md" but the file isn't immediately locatable:
   - Search the wiki's `raw/` directory
   - Search the user's desktop, downloads, and project directories
   - If still not found: **clarify before proceeding** — ask "Which .md file do you mean? I searched [paths] and didn't find it." Do NOT assume or guess from context.

2. **Read the spec document** once found. Understand the target structure:
   - What page types are defined?
   - What naming conventions?
   - What frontmatter fields are required?
   - What directories need to be created?
   - What content sources are available?

2. **Survey what exists** — read the current wiki directory structure and key files (index, schema, log):
   ```
   search_files(path="<wiki-dir>", pattern="*", target="files")
   ```

3. **Read current index and log** — understand what's already there, what needs updating.

### Phase 2A: Roadmap Planning

Before building anything new, **review what's been done and what's next** (audit log, PLAN.md, index).

1. **Audit completed phases** — review the wiki's log (log.md) and any existing PLAN.md to understand the current state.

2. **Identify the highest-value next step** — determine who the wiki's primary users are:
   - **Humans as primary users** → content first, infra when pain arises (traditional priority)
   - **Agents/LLMs as primary users** → infra first, content second (agents need dedup, search, and verification *before* they can write safely at scale)
   - **Both (hybrid)** → sequenced phases where each phase is necessary, nothing deferred indefinitely

   When agents are first-class users (Hermes, autonomous writers, LLM queries), apply the **agent-first dependency chain**:

   ```
   Raw storage (dedup)  →  Query layer (search)  →  Verification (guardrails)  →  Content
   ```

   Each step is a prerequisite for the next. An agent cannot:
   - Search without a query index
   - Verify its own writing without a span verifier
   - Trust its own output without a pre-commit hook
   - Dedup sources without hash-addressed storage

3. **Create or update PLAN.md** — a living roadmap document in the wiki root with:
   - Completed phases summary
   - Upcoming phases in strict dependency order (nothing deferred indefinitely)
   - Rationale for each phase ordering (so future sessions understand the dependency chain)
   - Execution strategy: which phases benefit from parallel subagent dispatch vs sequential work
   - Success criteria table with concrete "when is it done" metrics per phase
   - Effort estimates and timeline per phase
   - Content audit tier table (🟢3K+ chars ✅ / 🟡1.5K-3K chars / 🔴<1.5K chars stub) to track real state

4. **Agent-first, human-always principle**: A wiki that agents cannot search, verify, or dedup produces content that agents cannot trust. Infrastructure is not overhead — it is the foundation that makes safe agent-authored content possible. Sequence everything, defer nothing. Each phase must enable the next; unblocked phases are the definition of done.

### Phase 2B: Content Mining (Monolithic Source Docs)

When the source material is a **single massive document** (2MB+ monolithic reference doc), NOT a set of small files:

1. **Survey the doc structure** — extract top-level section headings to identify candidates:
   ```bash
   grep "^## " "<doc>" | sort -u | head -80
   grep "^### " "<doc>" | grep -i "<keyword>" | sort -u
   ```

2. **Extract via delegate_task** — spawn a parallel extraction agent for each content section:
   ```
   delegate_task(
     goal="Extract [Topic X] from the Hermes docs...",
     context="File path, what to grep for, what sections to capture",
     toolsets=["terminal", "file"]
   )
   ```
   The subagent uses `grep -n` + `sed` to extract sections and returns a concise summary ready for page creation.

3. **Batch-create pages** — take all extracted summaries and write_file them in parallel. The delegate_task approach avoids loading the entire 2MB+ doc into your context window.

> **Why delegate_task for content mining?** Your context window would be swamped by a 2.9MB doc. The subagent reads the file on disk via terminal, extracts only the relevant sections with `grep`/`sed`, and returns only the summaries. You get structured, page-ready content without ever pulling the full doc into your turn.

### Phase 2C: Plan

4. **Identify entities** — things/concepts that deserve their own page. These are the "nouns" of the domain:
   - Core tools, products, platforms
   - Organizations, people
   - Each needs: overview, key facts, relationships, source references

5. **Identify concepts** — abstract ideas, protocols, mechanisms, design patterns:
   - Each needs: definition, explanation, related concepts, source references

6. **Identify comparisons** — topics where the user makes trade-off decisions:
   - Each needs: side-by-side table, use-case guidance, related pages

7. **Identify queries** — questions with definitive answers the user will come back to:
   - Each needs: direct answer, expanded context, commands/configs as needed

8. **Write a structured plan** listing:
   - Directory structure to create
   - Each page to create (entity/concept/comparison/query)
   - Source material for each page
   - Cross-links between pages
   - Navigation and index updates

### Phase 3: Execute

9. **Create directory structure**:
   ```
   mkdir -p "<wiki-dir>/entities" "<wiki-dir>/concepts" "<wiki-dir>/comparisons" "<wiki-dir>/queries" "<wiki-dir>/pending"
   ```

10. **Write new pages to `pending/` first** — all autonomous (LLM-generated) writes land in `pending/` for human review before promotion to the knowledge directories. This prevents unchecked content from polluting the canonical wiki.

11. Once reviewed, **promote pages** from `pending/` to their proper directory (`entities/`, `concepts/`, etc.):
    ```bash
    mv pending/new-page.md entities/new-page.md
    ```

12. **Create nav.md** — a quick-jump reference in the wiki root:
    - Links to each section
    - Key pages under each section
    - Format: markdown lists with `[[wikilinks]]`

### Phase 4: Structural Verify

13. **Run the verification script** — `scripts/verify-wiki-structure.sh` checks every page for frontmatter, required fields, orphans, index count consistency, and git status:
    ```bash
    bash scripts/verify-wiki-structure.sh "<wiki-dir>"
    ```
    This catches: missing frontmatter, missing `created:/updated:/type:/tags:` fields, file count vs index mismatch, orphan pages (0 inbound wikilinks), missing `id:`, and dirty git state.

14. **Verify the index** — re-read index.md to confirm every page is listed and the table formatting is correct (no broken pipes, aligned columns)

15. **Verify cross-links** — spot-check a few pages that their `Related Pages` links are valid — every page must have 2+ outbound `[[wikilinks]]`.

16. **Git init** (if not already a repo) — the wiki should be version-controlled for rollback and history:
    ```bash
    cd "<wiki-dir>"
    git init
    git config user.name "Hermes Agent"
    git config user.email "hermes@nousresearch.com"
    git add -A
    git commit -m "feat(wiki): init structured knowledge base"
    ```

### Phase 5: Content Accuracy Verify (CRITICAL)

After structural verification, **always perform a content accuracy audit** against the source material. A beautiful structure with wrong facts is worse than no wiki at all. The user will catch these — proactively.

Do this ONLY after structural verify passes. Fixing wrong claims first, then re-structuring, wastes effort.

#### 5a. Identify source material

The source material is whatever the user provided (the spec doc, the massive reference doc in `raw/`, or the content sources listed in pages' `sources:` frontmatter). For a refactor from a single massive doc (2+ MB), that doc is the ground truth.

#### 5b. Read every wiki page

Read ALL pages in entities/, concepts/, comparisons/, and queries/. For each page, note:
- The `sources:` frontmatter — which raw file(s) it claims to derive from
- Specific factual claims (numbers, dates, names, licenses, relationships, definitions)
- Quantified claims ("~2s", "300+", "15+") — these are the most commonly inflated

#### 5c. Cross-reference against source material

For each key factual claim, search the source material:

```bash
# Search the raw source for key terms
grep -i "Apache License\|MIT\|license" "wiki/raw/Source Document.md" | head -5

# For version numbers and dates
grep -i "version\|v[0-9]\.[0-9]" "wiki/raw/Source Document.md" | head -5
```

Classification:
| Finding | Status | Action |
|---------|--------|--------|
| Exact match in source | ✅ Correct | Leave as-is |
| Reasonable paraphrase | 👍 Acceptable | Leave as-is |
| No match in source | ❌ Unverified | Remove, tag as `confidence: low`, or find actual source |
| Contradicts source | 🚨 Error | Must fix |

#### 5d. Cross-reference against project sources (not just the doc)

Some claims need verification against the **actual project**, not just the wiki's source doc. The source doc may itself be wrong or stale.

Use `web_extract` on the project's GitHub raw files for **high-impact claims**:
- **Licenses** — `web_extract("https://raw.githubusercontent.com/<org>/<repo>/main/LICENSE")` — catches MIT ≠ Apache 2.0 ≠ GPL errors
- **Version requirements** — `web_extract("https://raw.githubusercontent.com/<org>/<repo>/main/pyproject.toml")` — check `requires-python`, dependency versions
- **Build tools** — `web_extract("https://raw.githubusercontent.com/<org>/<repo>/main/package.json")` — check `dependencies`

Known high-error-claim patterns:
| Claim type | Example error | How to verify |
|------------|--------------|---------------|
| **License** | "MIT" when it's Apache 2.0 | Read the actual LICENSE file from GitHub |
| **Quantified claims** | "~2s startup" when source says "a few seconds" | Search source for the exact number |
| **Company names** | "Anthrophic" instead of "Anthropic" | Search project README for official branding |
| **Feature names** | "Hermes CLI" instead of "Hermes Agent" | Check project README for the proper product name |
| **Technical claims** | "Built with Textual" when it's built with Rich | Check pyproject.toml dependencies |

#### 5e. Fix inaccuracies

When a claim is wrong:
1. **Correct the wiki page text** — use `patch` for targeted edits, NOT file rewrites
2. **Bump `updated:` date** in frontmatter
3. **Check for systemic errors** — if one page has the wrong license, check ALL pages for the same error. One patch may fix 5+ pages
4. **Log the fix** in log.md with old→new values

#### 5f. Re-verify wikilinks after fixes

Every edited page still needs 2+ outbound `[[wikilinks]]`. Fixes to content may have accidentally broken links or made references stale. Run a focused wikilink check on only the modified pages.

#### 5g. Commit and log

```bash
git commit -am "fix(wiki): content accuracy audit — N pages checked, M fixes applied"
```

Append to `log.md`:
```
## [YYYY-MM-DD] lint | Content accuracy — N pages checked, M fixes applied
- Fixed wrong license (MIT → Apache 2.0) on hermes-agent, tui, mcp
- De-inflated startup time claim on tui.md (~2s → instant)
```

### Phase 6: Handoff

21. **Cross-reference the `wiki-planning` skill** — for ongoing maintenance (ingest/query/lint workflows, Obsidian integration, Dataview queries, scope widening, audit against vision docs), point the user (or future agent session) to the companion `wiki-planning` skill (Karpathy Advanced Operations section). This skill covers the initial refactor; the Karpathy Advanced Operations section in `wiki-planning` covers the daily lifecycle patterns.

## Phase 3.5: Enrich Existing Pages from a Source Document

When you already have a structured wiki and a source document (export, profile, research doc) with new content to merge in, use this enrichment workflow.

### Prerequisites

Before enriching from a raw JSON export (e.g., `conversations.json` from Claude or ChatGPT), you need to extract the relevant conversations into readable text first. The raw JSON is too large to read into context directly and its schema varies by platform.

See `references/json-conversation-extraction.md` for the progressive extraction pipeline: validate targets → inspect structure → targeted extraction → paginated review.

### Triggers

- User provides a reference doc with behavioral insights, architecture concepts, or project history
- User says "integrate this into the wiki" or "enrich existing pages from this"
- User provides an export/profile from another AI platform (ChatGPT, Claude, Gemini)

### Workflow

1. **Read the source document fully** — understand what sections exist and which existing wiki pages they map to.

2. **Identify enrichment targets** — for each section of the source, determine:
   - Does a wiki page already cover this topic? → **Enrich** the existing page
   - Is this entirely new territory? → **Create** a new page (see Phases 2-3 above)

3. **Map content to targets** — create a table mapping source sections → wiki pages:
   ```
   | Source Section | Target Page | Action |
   |----------------|-------------|--------|
   | "4-layer model" | concepts/ai-os-paradigm.md | New subsection |
   | "Memory scoring" | concepts/hermes-context-os.md | New subsection |
   | "Decision journal" | concepts/decision-journal.md | New page (create) |
   ```

4. **Read every target page fully** before editing — `read_file` with full path. This is mandatory: you need to know the existing structure to avoid duplicate content and lost links.

5. **Create new pages first** (via `mcp_wiki_file_synthesis`), then **enrich existing pages** (via `patch`). New pages may be referenced by the enriched content.

### Pitfalls — Auto-Generated Pages

The `mcp_wiki_file_synthesis` tool auto-stamps with these defaults that must be corrected:

| Auto-generated value | Must fix to | Reason |
|---------------------|-------------|--------|
| `type: query` | `type: concept` (or entity/comparison) | Query type is for answered questions, not concept docs |
| `tags: [query, auto-generated]` | Real tags (e.g. `[memory, constitution, policy]`) | Auto-generated tags aren't useful for navigation |
| No `relates_to` | Add `relates_to` edges to parent/sibling pages | Cross-linking is required for wiki health |
| `created:` is set correctly | Keep as-is | File creation date is correct |
| `source_query:` is set | Keep as provenance marker | Useful for traceability |

**Fix order:** All 4 corrections in one batch, immediately after creation, before any other edits.

### Pitfalls — Enriching Existing Pages via Patch

1. **`old_string` must be unique.** When adding a new section between existing sections, include enough surrounding context (the heading above AND below) to make the match unambiguous. If there are two `## See Also` headings, use 3+ lines of context around the unique section you're targeting.

2. **Don't lose existing links.** When replacing a `## See Also` section, include the old links in your `new_string` — you're adding to the list, not replacing it. Read the full file first so you know what links exist.

3. **Don't lose frontmatter fields.** When replacing a frontmatter line like `created: YYYY-MM-DD`, make sure the `old_string` includes enough of the adjacent lines to differentiate it from `updated:` (they share the same date format). Common mistake: patch replaces `created:` when you meant `updated:` because you didn't include surrounding lines.

4. **Don't accidentally remove subheadings.** When using surrounding context to disambiguate, the `old_string` must match the section it's in exactly — a `### Subheading` on the line above can get consumed. Verify by reading the file after every patch.

5. **Check for duplicate content.** If you add a new section that overlaps with an existing section (e.g., two "What Hermes Is Not" tables), the enrichment creates a confusing duplicate. Read the full file before patching to check for existing coverage.

6. **Bump `updated:` date.** Every enriched page's frontmatter needs its `updated:` field set to the current date. This is easy to forget when patching the body content only.

### Post-Enrichment Verification

After ALL enrichment work (new pages + patches), run this verification:

1. **Re-read every modified file** — catch structural issues: lost headings, duplicate sections, orphaned content
2. **Check `type:` consistency** — ensure pages in `concepts/` have `type: concept`, pages in `entities/` have `type: entity`, etc.
3. **Check cross-links** — every See Also section should have 3+ outgoing wikilinks
4. **Run wiki lint** — `mcp_wiki_lint_wiki` to check for orphans and broken links from the new pages
5. **Reindex** — `mcp_wiki_reindex_wiki` to register new pages in FTS5

### Support Files for This Phase

When the enrichment involves behavioral patterns, decision models, or memory architecture (common in cross-platform profile imports), create reference files under the relevant skill umbrella rather than as wiki pages. For example, a decision journal format specification belongs under a `decision-log` skill's `references/`, not in `concepts/`.

### Entity Page Structure
```
> One-line description of what this is.

## Overview
Brief intro paragraph.

## Key Facts
- List of notable facts

## Features (optional)
| Feature | Description |
|---------|-------------|

## Related Pages
- [[other-entity]] — relationship
```

### Concept Page Structure
```
> One-line elevator pitch.

## How It Works
Mechanism explanation.

## Key Concepts (if needed)
| Term | Description |
|------|-------------|

## Configuration (if applicable)
```yaml
example: config
```

## Related Pages
- [[entity]] — implements this concept
```

### Comparison Page Structure
```
# Title: Which to Choose

## At a Glance
| Aspect | Option A | Option B |
|--------|----------|----------|

## When to Use Each
**Choose A when:** ...
**Choose B when:** ...

## Related Pages
```

### Query Page Structure
```
# Question

## Answer
Direct answer.

## Details
Expanded context.

## Related Pages
```

## Standard Frontmatter Template

```yaml
---
title: Page Title
created: YYYY-MM-DD
updated: YYYY-MM-DD
id: page-slug
type: entity | concept | comparison | query | meta
tags: [tag1, tag2]
schema_version: v1
sources:
  - file: raw/source-file.md
    span: {start: 10, end: 150}
    extracted_at: YYYY-MM-DD
    extractor: <model-id>
relates_to:
  - page: "Another Page"
    rel: contradicts | supports | extends | supersedes | similar
contested: false
supersedes: []
superseded_by: null
---
```

## Cross-Linking Rules

- Every page MUST have at least 2 `[[wikilinks]]` to other pages
- Add a `## Related Pages` section at the bottom of every page
- Link to: entity pages from concept pages (and vice versa), comparison pages from concepts
- Link to the main entity page from every page that references it
- Cross-link complementary concepts (e.g., [[acp]] ↔ [[mcp]], [[profiles]] ↔ [[profile-distributions]])

## Pitfalls

- **Frontmatter is strict** — every page MUST have `title`, `created`, `updated`, `id`, `type`, `tags`, and `sources` with full provenance (file, span, extracted_at, extractor). Missing fields won't break rendering but Dataview queries will miss them, and `lint.sh` will block commits.
- **Batch creation order matters** — create entity pages first (they're referenced by other types), then concepts, then comparisons, then queries.
- **Don't forget nav.md** — it's the user's quick-jump reference. Update it after every batch.
- **Update the total page count** in index.md — stale counts erode confidence in the catalog.
- **Log every action** — the log is append-only and chronological. Every batch gets a dated entry.
- **Cross-references to not-yet-created pages** are fine in Obsidian (they render as "not created" links). If creating pages in batch, do entity pages first so concept pages can link to them.
- **Windows paths** — use `C:\\Users\\<user>\\...` or `/c/Users/<user>/...` consistently. `read_file`, `patch`, and `write_file` handle native `C:\\` paths fine; `terminal` works with both MSYS (`/c/`) and native paths.
- **Frontmatter date format** — use `YYYY-MM-DD` ISO format. Always set `created` to today for new pages, `updated` to today for modified pages.

## Reference Files

- `references/wiki-refactor-worked-example.md` — Full worked example from a real wiki refactor session (Hermes Agent docs → 25-page wiki). Concrete step-by-step with actual commands, batch patterns, and extraction techniques used.
- `references/json-conversation-extraction.md` — Progressive JSON extraction pipeline for pulling named conversations out of a large export file (e.g., `conversations.json` from Claude/ChatGPT). Use before Phase 3.5 to turn raw JSON into readable text for wiki enrichment. Covers: validate targets, inspect structure, phased extraction (human-only → full), and paginated review.
- `references/content-accuracy-audit.md` — Reusable content accuracy audit script (Python) and known error patterns. Use after any refactor to verify every page's claims against the source material and catch license errors, inflated claims, and wrong version numbers before the user does.
- `references/wiki-agent-first-infra.md` — Architecture reference for agent-first wiki planning: the unbreakable dependency chain (dedup → search → verify → content), why deferring infra is wrong for agent-first systems, Hermes ecosystem tracking pattern, content audit tiers, and common anti-patterns. Consult this before writing or revising any PLAN.md for an agent-served wiki.
- `references/wiki-anatomy-document-format.md` — Format spec for creating TUI-style anatomy/infographic reference documents. Covers when to use this format, tier system with section headers instead of per-line icons, priority ordering, description style, and anti-patterns. Consult when the user asks for a filesystem layout overview ("anatomy of X", "do the same thing for Y").
