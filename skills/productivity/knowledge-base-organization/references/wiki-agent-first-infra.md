# Agent-First Wiki Infrastructure

When the wiki's primary users include **LLMs, autonomous agents, and Hermes sessions** (not just humans browsing in Obsidian), the infrastructure stack must be built before content. This reference documents the agent-first dependency chain and why each layer matters.

## Core Insight

Humans can tolerate: duplicate pages, fuzzy search, unverified claims, stale data.
**Agents cannot.** An agent that finds two pages about the same topic writes a third. An agent that can't search writes blind. An agent with no verifier writes hallucinations into the canonical store.

Therefore, for agent-first wikis, the build order is:

```
Raw dedup  →  Search index  →  Verification pipeline  →  Content
```

Each step is a hard prerequisite for the next.

## The Dependency Chain

### Layer 1: Deterministic Source Dedup (hash-addressed raw storage)

**Problem:** An agent ingests "Hermes Agent Full Documentation.md" on Monday. On Wednesday, a slightly different filename arrives. Both save to `raw/articles/` as separate files. Now every source-based query returns two entries for the same document.

**Solution:** Dual-layout raw storage:
- `raw/<sha256>/source<ext>` — canonical, hash-addressed. Agents write here after computing sha256.
- `raw/articles/something.md` — symlink to the hash path. Humans browse by name.

**Agent workflow:** Save source → `sha256sum` → check if hash directory exists → skip if dup, write if new.

**Can't skip this because:** Without it, source dedup is impossible to automate. Human review can catch duplicate filenames, but agents ingest programmatically and cannot guess "this PDF might be the same as that one."

### Layer 2: Machine-Queryable Search Index (BM25 + entity graph)

**Problem:** An agent wants to check "does a page about Hermes TUI exist?" before writing one. `grep -r "TUI" entities/` is slow, breaks on synonyms, and can't rank results. The agent either writes a duplicate or gives up.

**Solution:** A lightweight BM25 index (SQLite FTS5 or inverted JSON) rebuilt on every commit:
- `scripts/rebuild-index.py` walks all content pages, tokenizes, builds BM25
- Same script builds `edges(from_id, rel, to_id)` table from `relates_to` frontmatter
- `scripts/wiki-search <query>` returns ranked results with page paths + snippets

**Agent workflow:** Before writing any page, `wiki-search "topic"` to check for existing pages. If a close match exists, update it instead of creating a duplicate.

**Can't skip this because:** Without search, every agent write is a gamble. The agent has no way to know whether the wiki already covers a topic. This directly causes page bloat and contradictions.

### Layer 3: Verification Pipeline (lint + span verification + pre-commit hook)

**Problem:** An agent writes "Hermes Agent uses MIT License" — wrong, it's Apache 2.0. This hallucination lands in `entities/hermes-agent.md` and propagates to every page that links to it.

**Solution:** A multi-stage verification pipeline that runs on every commit:

| Stage | What it checks | Blocks commit? |
|-------|---------------|----------------|
| Schema lint | `id:` matches filename, required frontmatter fields present, `sources[]` entries complete | Yes |
| Span verifier | Each `[^src:N]` citation → load raw source → fuzzy-match ≥85% | Yes |
| Edge validator | `relates_to` targets are valid page IDs that exist | Yes |
| Orphan detector | Pages with zero incoming wikilinks (excluding meta pages) | No (warns) |
| Deprecated field check | No `confidence:` fields present | Yes |

**Agent workflow:**
1. Write content to `pending/` (staging directory)
2. Run `lint.sh pending/` — fix any failures
3. Promote from `pending/` → `entities/concepts/comparisons/queries`
4. Commit — pre-commit hook runs full pipeline against staged files

**Can't skip this because:** Without verification, every agent-authored page carries a non-zero hallucination probability. As page count grows, hallucination count grows linearly. The verifier is the safety net that makes agent-authored content trustworthy.

## Content Audit Tiers

Not all pages are equal. Before an agent writes, audit the existing content into tiers:

| Tier | Character count | Cross-links | Sources | Action |
|------|----------------|-------------|---------|--------|
| 🟢 Well-populated | 3K-8K+ | 3+ inbound | 2+ with spans | Maintain, deepen on user request |
| 🟡 Filled | 1.5K-3K | 1-2 inbound | 1+ with spans | Add 1-2 more sources, cross-link more |
| 🔴 Thin/stub | <1.5K | 0 inbound | 0 or 1 | Fill to 1.5K+ with 2+ sources and 2+ `relates_to` edges |

## Hermes Ecosystem Tracking

When the wiki tracks a Hermes installation (instances, config, skills, sessions), the following entity/concept pattern applies:

| Page type | Examples | Content |
|-----------|----------|---------|
| Entity | `hermes-desktop.md`, `hermes-wsl.md` | Version, profile path, config key, active plugins, last commit, gateway channels |
| Concept | `hermes-config.md`, `hermes-sessions.md` | Provider chain, model routing, tool toggles, config change timeline, session→page link convention |
| Entity | `hermes-skills.md` | Skill registry: what exists, active/inactive, per-profile, authored vs community, versions |

This makes the wiki Hermes's own memory — any future session can answer "what's my current config?" from the wiki.

## Common Anti-Patterns

| Anti-pattern | Why it fails | Correct approach |
|-------------|-------------|------------------|
| "Content first, infra when pain arises" | Agents can't write safely without search/verify. Pain arrives on page 2, not page 200. | Build dedup → search → verify before bulk content. |
| "Defer indefinitely" | Deferred items never get done. The wiki stops evolving once the "fun" content work is done. | Sequence everything. Each phase is small (30 min - 2 hours). No deferred state. |
| "This is over-engineering for 50 pages" | 50 pages → 200 pages in 3 agent-assisted sessions. Infra designed for 50 breaks at 200. | Design for 1,000 pages from day 1. Single-file BM25 + SQLite handles that easily. |
| "Humans can grep for what they need" | Agents cannot grep effectively. The wiki has two user classes — optimize for the most constrained one. | Build `wiki-search` CLI. Humans benefit too. |
