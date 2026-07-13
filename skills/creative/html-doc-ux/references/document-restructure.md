# Document Restructure: Stack-Guide Reframing

A documented approach to pivoting a flat feature-list reference document into a tiered/stack-based structure — like reframing "15 sections about a tool" into "Simple Stack vs End Game Stack with supporting reference sections."

## When to use this pattern

This pattern applies when a reference document has grown organically (section after section, flat hierarchy) and needs to be reorganized around **user tiers**, **deployment complexity**, or **experience levels**.

**Good candidates:**
- Tool documentation organized by feature category → reorganize by user tier (beginner / power user)
- Setup guides organized by component → reorganize by stack (minimal / full)
- Product pages with a list of features → reorganize by plan level (free / pro / enterprise)

## The pattern

### 1. Design the decision matrix

Create a side-by-side comparison table that becomes the new hero/intro pivot:

| Dimension | Stack A (Simple) | Stack B (End Game) |
|-----------|------------------|---------------------|
| For who? | Beginners, quick experiments | Power users, teams, production |
| Models | Single model (local or API) | Multi-model, dynamic switching |
| Platforms | CLI + TUI only | Discord, Telegram, Slack, Web UI |
| Tools | Built-in defaults | MCP servers, plugins, sub-agents |
| Cost | $0–5/month | $10–150+/month |
| Setup time | 10 minutes | 1–2 hours + tuning |

### 2. Map every piece of content

Assign each original section to one of three buckets:

| Bucket | Example content | Goes where |
|--------|----------------|------------|
| **Stack A** | Installation, basic config, simple workflows | New §01 Simple Stack section |
| **Stack B** | Multi-model routing, gateway setup, advanced profiles | New §02 End Game Stack section |
| **Common** | Security, ecosystem, reference info | Renumbered standalone sections |

### 3. Write new stack sections

Each stack section should synthesize content from across the original document:
- **Goal** — one line: what this stack achieves
- **Stack table** — layer × choice × why
- **Quick setup** — the essential commands
- **Daily workflows** — 5-6 concrete examples
- **Cost breakdown** — specific, not abstract
- **Limitations / trade-offs** — honest about what you lose

Don't copy-paste original text — synthesize it. A stack section is a *curation* of the original content, organized for a specific audience.

### 4. Rewire navigation — in lockstep

Every navigation surface must be updated simultaneously.

**Use `execute_code` (Python) for the rewrite** — when the restructure touches 50+ locations, hand-editing is error-prone. Build the new document programmatically:

1. Read the original via `read_file`
2. Define the new structure as a Python data model (sections array with id/num/title/tag)
3. Generate sidebars, section-nav, quick-jump JS, and filter tags from the data model
4. Extract valuable content from absorbed sections, synthesize or redistribute per the folding map
5. Write the new document via `write_file`

This ensures all 50+ navigation references stay in lockstep from a single source of truth.

**Content folding pattern** — when absorbing a section into another, don't just delete it. Use a folding map to track what went where:

| Old section | Folded into | Strategy |
|-------------|-------------|----------|
| Architecture | Intro | `synthesize_paragraph` — extract key insight as single paragraph |
| Features | Simple + End Game | `split_by_tier` — partition by complexity/cost |
| Installation | Simple Stack | `copy_commands` — essential commands in quick-setup |
| Tools | Simple + End Game | `split_into_tables` — built-in vs MCP/plugins |

Strategies:
- `synthesize_paragraph`: 3-5 sentences distilling the old section's key point
- `split_by_tier`: read each feature/tool, assign it to the appropriate stack
- `copy_commands`: extract the 2-4 most essential command examples
- `split_into_tables`: partition a feature table into two columns or two tables
- `synthesize_table`: restructure content as a run-comparison table

1. **Desktop sidebar** — group links under headings (Stacks, Operational, Reference)
2. **Mobile sidebar** — same structure, add `onclick="toggleSB()"`
3. **Section-nav (prev/next)** — every section needs updated prev/next links
4. **Quick-jump JS array** — update section IDs, titles, tags, numbers
5. **Filter `<section data-filter-tag>`** — each section gets a filter tag
6. **Stat cards + meta row** — reflect new section count, stack count

**Checklist after rewiring:**
- [ ] Desktop sidebar has N links matching N sections
- [ ] Mobile sidebar has same N links
- [ ] Every section bottom has prev + next (or only-child fallback going up)
- [ ] Quick-jump `sections` array length == N
- [ ] Filter bar buttons toggle correct sections
- [ ] No `href="#old-section-id"` remains in the document

### 5. Verify structural integrity

```bash
# Count sections
grep -c '<section id="' output.html

# Check all sidebar hrefs exist as section ids
grep -o 'href="#\([^"]*\)"' output.html | sed 's/href="#//;s/"//' | sort -u | \
  while read id; do grep -q "id=\"$id\"" output.html || echo "MISSING: $id"; done
```

### 6. Update surrounding infrastructure

- **Meta description** — `AI stack decision guide for Hermes Agent — Simple Stack to End Game Stack`
- **Title** — should mention both tiers
- **Stats** — "2 stacks" instead of "15 sections"
- **Quick links** — point to the two stack sections first

## Patch vs full rewrite

| Factor | Patches win | Full rewrite wins |
|--------|-------------|-------------------|
| Change count | 2-10 patches | 30+ patches |
| Interconnection | Independent edits | Every change touches navigation |
| Risk of missed link | Low — fixable on next patch | High — verify carefully |
| Speed | Faster for small changes | Faster for massive restructures |
| History preservation | Yes — git-friendly | No — entire file changed |

**Decision rule:** If the restructure would require touching 80%+ of the document lines (sidebars, section-nav, every section's heading/badge/number), a full rewrite is cleaner than 50 incremental patches. A full rewrite with `write_file` is fine when you're generating a complete, self-consistent new document from your understanding of the original content — not from scratch.

## Concrete example: Hermes Agent Stack Guide

The Hermes Agent report was restructured from 15 sections to 11:

| Removed sections (content folded) | New sections created |
|-----------------------------------|---------------------|
| Architecture (→ intro) | §01 🟢 Simple Stack |
| Features (→ §01 + §02) | §02 🔴 End Game Stack |
| Running Strategies (→ §02) | |
| Installation (→ §01) | |
| Tools (→ §01 + §02 as MCP) | |

**Hero transformation:**
```
Before: "An in-depth reference guide covering every aspect of Hermes Agent"
After:  "An AI stack decision guide: from a single local model to multi-model enterprise — all powered by Hermes Agent"
```

**Key insight:** The same architecture, CLI, and security docs serve both stacks unchanged — only the intro, stack sections, and navigation change. The rest is renumbered, not rewritten.
