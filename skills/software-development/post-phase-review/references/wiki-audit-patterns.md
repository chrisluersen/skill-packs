# Wiki Audit Patterns (Post-Phase Review)

Use these when running a post-phase review on a wiki (Open Notebook / LLM wiki). These extend the generic R1-R5 methodology with wiki-specific checks.

## R1 — Audit: Lint First

1. Run `lint_wiki()` (MCP) as your first audit action
2. Categorize each finding:
   - **Lint → Orphan pages**: Pages with 0 inbound wikilinks. Common offenders: AGENTS.md, SCHEMA.md, log.md — these are meta files, NOT actual orphans. Only pages under `concepts/`, `entities/`, `comparisons/`, `queries/` that have no inbound links are true orphans.
   - **Lint → Stale frontmatter**: Pages whose `sources` are empty or whose `extracted_at` is >90 days old.
     - Meta files (AGENTS.md, PLAN.md, SCHEMA.md, README.md, index.md, log.md, todo.md) are EXPECTED to lack formal sources — they are the plan/codex itself, not content derived from an external source. Flag them as false positives.
     - Content pages under `concepts/`, `entities/`, `comparisons/`, `queries/` are REAL hits — their frontmatter needs fixing.
   - **Lint → Broken links**: Always a 0-tolerance finding. Fix immediately.

3. Check `pending/` directory
   - Empty: the automated ingest pipeline (Phase 7) isn't producing yet — expected pre-Phase 7.
   - Has files: pages awaiting human review. Verify and promote.

4. Check `todo.md` and `log.md` for completeness
   - Were all planned subtasks for the phase completed?
   - Does the log capture what was actually built, not just what was planned?

## R3 — Backfill: Frontmatter Hygiene

When a content page has stale frontmatter (no `sources` with `extracted_at`), fix it with this template:

```yaml
---
title: <Page Title>
created: YYYY-MM-DD
updated: YYYY-MM-DD
id: <kebab-case-id>
type: <concept|entity|comparison|query>
schema_version: v1
tags:
- <tag1>
- <tag2>
sources:
  - file: <url or path>
    extracted_at: YYYY-MM-DD
    extractor: <model/provider used>
relates_to:
- page: <related-page-id>
  rel: <similar|references|implements>
---
```

### Pitfalls

- **read_file pipe bleed**: When building `patch` strings from `read_file` output, the `LINE_NUM|CONTENT` separator `|` can be mistakenly included as literal content. Always verify `old_string`/`new_string` contain actual file content, not prefixed line numbers. If the frontmatter gets mangled with extra `|`, the fix is to match the corrupted content as `old_string` with clean content as `new_string`.
- **extracted_at date**: Use the actual date the source was consulted, not today's date. For Phase 6+ content where provenance wasn't recorded, use the page's `created` date as a best-effort backfill.
- **file field in sources**: Can be a URL (for live docs referenced) or a local path under `raw/` (for files extracted into the wiki). For Hermes docs URLs, use the full URL as `file:` value.

## R3 — Backfill: Graph Data

- After editing ANY content file, rebuild graph data (`build_graph_data.py`) or the graph will be stale.
- `find_related` and `suggest_edges` MCP tools are reliable regardless of the graph build state (they do live scans). The stale graph only affects visualizations and dashboard-embedded edge counts.

## R3 — Backfill: Plan Sync

Check for these silent drift signals between the plan and reality:

| Drift signal | Fix |
|---|---|
| Commit count diverges | Update count in plan or auto-derive from `git rev-list --count HEAD` |
| Repos/tools discovered mid-phase that affect upcoming phases | Add "dependency candidate" row to Post-Audit Lessons section |
| Companion systems explored but not part of direct wiki scope | Note as companion, don't add as a phase |
