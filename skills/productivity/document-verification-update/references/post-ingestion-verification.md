# Post-Ingestion Verification

Verify that a synthesized wiki page (created from structured data sources like JSON/CSV/YAML) accurately reflects the source data. Catches synthesis drift: lost fields, inaccurate values, misaligned counts, missing cross-links.

## When to Use

- User asks "double check your work" after you ingested data and wrote a wiki page
- You've synthesized a page from multiple source files (CSV + JSON + web extract)
- The source data has structured records with many fields per record (e.g., agent definitions, product specs, config manifests)
- Before promoting a page from `pending/` to its permanent directory

## Workflow

### Phase 1: Re-read Source Data

Read both the source files **and** the wiki page you wrote:

```python
# Load source data
json_data = json.loads(read_file(path="raw/assets/architecture.json")["content"])
csv_lines = read_file(path="raw/assets/manifest.csv")["content"].split("\n")
wiki_md = mcp_wiki_read_wiki_page(path="pending/my-page.md")["result"]
```

### Phase 2: Build a Verification Matrix

Create a field-by-field comparison. For each record (agent, product, etc.), extract key fields from both source and wiki:

| Field | Source Value | Wiki Value | Status |
|-------|-------------|------------|--------|
| Ceres-1 hex_color | `#FFFFFF` | `#FFFFFF` | ✅ |
| Ceres-1 lucide_icon | Anchor | Anchor | ✅ |
| Ceres-1 MBTI | INTJ | INTJ | ✅ |
| Ceres-1 model_tier | Heavy/Reasoning | Heavy/Reasoning (32K context, 1K output) | ✅ |

**What to verify (in priority order):**

| Priority | What | Why |
|----------|------|-----|
| 1 | **Counts** — number of records | Most basic error: missing a record entirely |
| 2 | **Identifiers** — names, IDs, designations | Wrong name means the whole entry is wrong |
| 3 | **Visual identifiers** — hex colors, icons, emoji | Easy to typo a hex code |
| 4 | **Structured fields** — MBTI, motivations, fears, quirks | Verbose fields invite paraphrase drift |
| 5 | **Quoted text** — welcome phrases, system prompts | Must be verbatim, not paraphrased |
| 6 | **Numerical data** — context limits, token counts, timestamps | Easy off-by-one or unit errors |
| 7 | **References** — fallback targets, synergistic partners | Check both direction (A→B) and direction (B→A) |
| 8 | **Cross-links** — wikilinks to related concept pages | Ensure bidirectional links where appropriate |

### Phase 3: Classify and Flag

| Status | Label | Meaning |
|--------|-------|---------|
| ✅ | Match | Source and wiki agree |
| ⚠️ | Acceptable enrichment | Wiki added context not in source (e.g., "32K" → "32K context, 1K output") — note it but pass |
| ❌ | Drift | Wiki value differs from source — must fix |
| 👻 | Missing from wiki | A source field was not carried into the wiki — add it |
| 🔗 | Missing link | A entity/concept page exists but no wikilink connects them — add bidirectional link |

### Phase 4: Apply Targeted Fixes

```python
# Fix a drifted value
patch(path="pending/my-page.md", 
      old_string="#EF4444",
      new_string="#FF4500")

# Fix a missing bidirectional link
patch(path="pending/my-page.md",
      old_string="See also section...",
      new_string="See also...\n- [[concepts/klio-the-librarian-agent.md|Klio-84 — The Archivist]]")

# Add a missing field
patch(path="pending/my-page.md",
      old_string="| **Welcome Phrase** | ... |",
      new_string="| **Welcome Phrase** | \"Alignment verified.\" |\n| **Protocol** | System Commands (Strict JSON) |")
```

### Phase 5: Present Audit Report

Deliver a structured summary so the user can trust the result at a glance:

```
## Audit Results

### ✅ Source Files Captured
| Source | Location | Size | Status |
|--------|----------|------|--------|
| Source A | `raw/assets/file.json` | 37KB | ✅ |
| Source B | `raw/assets/file.csv` | 3KB | ✅ |

### ✅ Wiki Page: `pending/my-page.md`
| Check | Result |
|-------|--------|
| All N records listed | ✅ |
| Hex colors match source | ✅ Spot-checked all N |
| Counts match source | ✅ |
| Fallback chains correct | ✅ |
| Cross-links to concept pages | ⚠️ Missing backlink to X — patched |

### ⚠️ Gaps Found & Fixed
- Missing backlink: page → concept/X — added
```

## Common Drift Patterns

| Drift type | Example | How to detect |
|------------|---------|---------------|
| **Paraphrase drift** | Source says "Espresso Romano (with a lemon peel)" → wiki says "Espresso with lemon" | Read exact quote fields from source, compare verbatim |
| **Hex rotation** | `#FF4500` → `#FF4400` (one digit off) | Compare hex strings character by character |
| **Missing records** | Source has 14 agents → wiki has 13 | Count source records first |
| **Field transposition** | Hex color assigned to wrong agent | Verify every color against every agent ID systematically |
| **Icon substitution** | "Anchor" → "AnchorIcon" or "Anchor2" | Compare icon names exactly |
| **Beverage loss** | Full beverage name truncated | Read beverage field as a multi-word string, not a single word |
| **Fallback direction error** | A falls back to B (correct) vs B falls back to A (swapped) | Check both directions for every fallback pair |

## Pitfalls

- **Don't spot-check 1-2 records and declare victory.** Verify every field for every record, or at minimum every relevant field category (all hex colors, all fallbacks, all icons). Errors cluster — if one hex is wrong, others likely are too.
- **Verify field-by-field, not page-by-page.** A page may look correct but have transposed values. Compare individual fields across the whole dataset.
- **Count records in source data programmatically.** `len(json_data["items"])` or `wc -l file.csv` — don't trust your mental count.
- **Cross-link verification is not optional.** A synthesized page that doesn't link back to its related concept pages creates orphans and broken navigation.
- **Don't fix formatting the user didn't complain about.** If the audit finds both data drift AND style choices you disagree with, only fix the data drift. Style is user territory.
