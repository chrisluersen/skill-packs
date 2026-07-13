---
name: document-verification-update
title: 'Document Verification and Update'
description: 'Audit reference documents for factual accuracy or completeness. Three modes: (1) verify claims against live system state, (2) verify claims against source code implementation, (3) check coverage against external authoritative reference lists. Apply targeted patches to fix stale or missing content. For READMEs, setup guides, architecture docs, stack reports any document that describes current reality.'
category: productivity
triggers:
  - "verify this document against reality"
  - "verify against the source code"
  - "double check my setup doc is accurate"
  - "update the .html with verified info"
  - "audit what's stale in this reference"
  - "check if this doc still matches our config"
  - "check if the code still matches the docs"
  - "what is this doc missing"
  - "audit the coverage of this reference doc"
  - "check our doc against the ecosystem list"
  - "find gaps in this document compared to X"
  - "make sure the plan is consistent"
  - "double check your work one more time"
  - "double check your work"
---

# Document Verification & Update

Systematically verify every claim in a reference document against live state and update only the stale parts.

## 🔍 When to use

The user hands you a document (README, setup guide, architecture report, config reference) and asks you to check its accuracy against what's actually running. The doc may be a month old, migrated, or just untrusted.

Key signals: "verify", "double-check", "audit", "make sure this is still accurate", "update with verified info".

## 📋 Workflow

### Phase 1: Extract claims

Read the full document. Extract every verifiable claim into a mental checklist:

| Claim class | Example | How to verify |
|-------------|---------|---------------|
| **Version/version numbers** | "Hermes v1.7.0" | `hermes --version` or `<tool> --version` |
| **Model names** | "default model: qwen3:8B" | `hermes config show` → model key |
| **Tool/feature status** | "All 4 Nous tools active" | `hermes status --all` per toolset |
| **Service/runtime state** | "Gateway running (PID X)" | `hermes status` or `ps` / tasklist |
| **Counts** | "88 installed skills" | `hermes curator status` or skills_list |
| **Paths** | "Config at ~/.hermes/config.yaml" | `ls` the path |
| **Integrations mentioned** | "VS Code ACP wired up" | Check if the extension/Socket is live |
| **Screenshots/diagrams** | Architecture SVG labels | Check model names, versions, feature names in text |

**Important**: Don't just cursorily scan — read every line including code blocks, tooltips, footnotes, and image alt text. The most stale info hides in diagram labels and inline code examples.

### Phase 2: Run verification commands

Run the live commands in parallel where possible. The standard Hermes verification battery:

```bash
hermes status --all              # tool statuses, PIDs, subscriptions
hermes config show               # model, context length, compression settings
hermes curator status            # skill count, stale count, last run
hermes cron list                 # active cron jobs
```

For non-Hermes docs, adapt:
- `python3 --version`, `node --version`, `git --version`, `gh --version`
- `ls -la` to verify file paths exist
- `grep` the config for specific keys

### Phase 3: Compare & flag

Classify each original claim:

| Status | Label | Action |
|--------|-------|--------|
| ✅ Still accurate | **Holds up** | Leave as-is |
| ❌ Stale | **Stale** | Patch with correct value + note what changed |
| 👻 Unverifiable | **Unverifiable** | Either remove or label as "unverified claim" |
| 🚫 Never true | **Never was** | Remove or rewrite entirely |

### Phase 4: Patch targeted fixes

Use the `patch` tool for each stale claim. **NEVER rewrite the whole file** — targeted patches preserve:
- The document's original structure, tone, and design
- Other sections you didn't need to verify
- The user's formatting/design choices

```python
# Pattern — one patch per stale claim
patch(
    path="reference.html",
    old_string="Model: qwen3:8B",      # exactly as it appears
    new_string="Model: nvidia/nemotron-3-ultra:free (64K ctx)"  # verified value
)
```

**When to batch vs solo:** If 5+ claims are in the same paragraph/block, do one patch for the whole block. If they're scattered, do separate patches to keep old_string matches unique.

### Phase 5: Verify structure after each patch

After each patch batch, read the modified section to confirm:
- No duplicated lines (the tool merges adjacent patches poorly if context overlaps)
- No broken HTML tags if it's an HTML file
- The section still reads naturally
- **Markdown table formatting intact** — patches near table rows can introduce extra pipes (`|||` instead of `||`) or remove required separators. After patching a table row, check that all rows have the same number of columns.

## ⚠️ Pitfalls

- **Don't trust the document's own date stamps** — "Last updated: March 2024" may be wrong. Verify everything regardless.
- **Patch uniqueness is critical** — if `old_string` matches multiple places, use `replace_all=True` or add surrounding context lines up to 2-3 above/below.
- **Diagram labels are the easiest to miss** — SVG text elements, <image> alt text, and flowchart node labels are common stale-claim hiding spots. Read the entire SVG definition.
- **Don't rewrite sections that are correct** — if 8/10 claims hold up, patch the 2 stale ones; don't blast away the other 8.
- **Model names change fast** — a "free" model today may be paid next month. No need to capture the exact model in the skill (will be stale), just teach the verification pattern.
- **Don't fix what isn't asked** — the user's request is "verify and update claims", not "redesign the doc". Clean, targeted patches preserve the user's decisions about format and content.
- **First finding is never the full picture — sweep the whole category.** When you discover corruption in file A (escaped newlines, mangled content), don't fix A and call it done. The same process that corrupted A probably affected B, C, D, and E too — they just weren't in your sample. After the first fix, scan every sibling file in the same directory/category for the same corruption signature. In one session: initially reported 3 corrupted files from a spot-check, but a full-category sweep found 6 more with the same pattern.

## ✅ Verification checklist

Before finishing (verification mode):

- [ ] Every verifiable claim checked against live state
- [ ] Only stale/new content patched — correct content left untouched
- [ ] Document structure intact (no broken HTML, no duplicated lines)
- [ ] Footer/timestamp updated to reflect verification date
- [ ] No unverifiable claims left standing (either removed or flagged)

---

## 📖 Source-Code Verification Mode

Verify documentation claims against the actual implementation code, not just running system state. Useful when the doc describes algorithms, formulas, data structures, API shapes, or config schemas that are defined in source files.

### When to use

- Architecture docs referencing specific formulas, port numbers, env var names, or JSON shapes
- Config reference docs that match a YAML/JSON/TOML schema
- Behavior descriptions with pseudocode or algorithmic claims ("uses min(4096 + 2 * tokens, 8192)")
- API endpoint docs claiming specific response fields and JSON structure
- Log format claims (exact log line templates, prefixes, trace IDs)
- The doc describes code that may have changed since the doc was written

The trigger is usually the same as verification mode ("double check", "verify", "audit"), but a clue that you need source-code mode specifically is when the claimed content is too precise to be checked by running a command — it's about WHAT the code does internally.

### Workflow

#### Phase 1: Extract claims

Read the full document. Categorize each claim by verifiability:

| Claim class | How to verify | Example drift signal |
|-------------|---------------|---------------------|
| **Port/URL** | `grep` the source for that number/string | "port 8320" → code uses 8319 |
| **Env var name** | `grep -n 'ENV_VAR' source.py` | "`cache_ttl`" → code has `CACHE_TTL` |
| **Formula/algorithm** | Find and read the function | "min(4096 + 2*tokens, 8192)" → content-length tiers |
| **JSON response shape** | Find the return/flask.jsonify call | "estimated_cost_usd" → doesn't exist in code |
| **Log format** | Find the logging call | "↻ cache hit for <model>" → "[trace] ↩ cache hit" |
| **Config file schema** | Read the load/parse function | flat `{"groq": [...]}` → nested `{"providers": {...}}` |
| **Behavior claim** | Find the relevant conditional | "retries once then falls back" → check the actual retry logic |
| **Code references** | `grep` for the quoted function/class name | "`_compute_max_tokens`" → function doesn't exist |

#### Phase 2: Read the source

Read **the full file** or the relevant section end-to-end. Don't skim — line numbers matter for verification.

For Python projects, the key signals are:
- `@app.route(...)` / Flask routes — matches API endpoint docs
- `jsonify({...})` — matches JSON response shape docs
- `os.environ.get("...")` — matches config env var docs
- `log.warning(f"...")` / `log.info(f"...")` — matches log format docs
- `def _something(...)` — matches algorithm/function docs
- `{"key": [...],}` patterns — matches config file schema docs

#### Phase 3: Compare each claim

For each claim, find the exact line(s) in source that govern it. Classify:

| Status | Meaning |
|--------|---------|
| ✅ **Exact match** | Docs say what code does, down to casing and punctuation |
| ⚠️ **Approximate** | The concept is right but the specifics are wrong (port, formula, field name) |
| ❌ **Wrong** | Describes behavior or structure that doesn't exist at all |
| 👻 **Phantom** | Refers to a function, config, or endpoint that doesn't exist in source |

**Important: a single wrong claim often implies others.** When you find a port number that's wrong, check every other port reference in the doc. When a formula is wrong, check every behavioral description. Sweep the category after the first hit.

### Strategy: multiple audit passes (different lenses)

One pass is never enough. Different claim classes require different verification techniques — and reading **different parts of the source**. Plan **3+ passes**, each with a distinct lens:

| Pass | Lens | What you find | Source signal to read |
|------|------|---------------|-----------------------|
| **1** | **Factual claims** — ports, URLs, env var names, version numbers, counts | Stale port numbers, renamed env vars, wrong paths | `grep` the string, `os.environ.get(...)` calls |
| **2** | **Structural/API claims** — JSON response shapes, config file schemas, table columns | Wrong field names, missing/extra fields, wrong nesting | `jsonify({...})` returns, config load/parse functions, table rows |
| **3** | **Behavioral claims** — formulas, algorithms, pseudocode, conditional logic | Intent-based pseudocode that never matched implementation | `def _function(...)`, `if/else` chains, arithmetic expressions |
| **4** | **Code examples & log formats** — inline code blocks, example commands, log line templates | Outdated terminal output, changed log templates, wrong formatting tokens | Logging calls (`log.info(f"...")`), example command outputs |

**Why multiple passes?** On pass 1, your attention is on factual claims — you grep for port numbers and env var names. The JSON structure on line 250 isn't on your radar. On pass 2, you read the `jsonify()` block and see the response shape is completely different. Each lens reveals a class of issues the previous lens missed.

**Don't consolidate passes.** Even if you know pass 2 is coming, don't try to do factual claims AND structural claims in one read. The cognitive load of switching between "grep this port number" and "parse this 40-line JSON structure" means you'll miss things in both.

**After each pass, mark what you checked.** Before declaring done:
- [ ] Pass 1 done: all factual claims verified against code/source
- [ ] Pass 2 done: all response shapes, config schemas, and table structures verified
- [ ] Pass 3 done: all behavioral descriptions, formulas, and pseudocode verified
- [ ] Pass 4 done: all code examples and log format strings verified

**The user asking "double check your work" is the strongest signal you missed something.** It means a pass with a different lens would have caught more. Don't just re-check the same lens — switch lenses. If you did factual claims on pass 1, do structural claims on pass 2. Each "double check" should feel like a completely different reading of the document, not a re-read of the same claims.

#### Phase 4: Batch-fix with targeted patches

Fix each stale claim with a unique `patch()` call:

```python
# One per claim — old_string must be unique in the file
patch(path="architecture.md",
    old_string="curl http://127.0.0.1:8320/metrics",
    new_string="curl http://127.0.0.1:8319/metrics")
```

**Batching strategy:** Patches for different parts of the doc can be made in parallel (same turn) if they use different `old_string` targets. Patches for the same paragraph/section should be done sequentially to avoid overlapping context.

For **structural accuracy** (JSON examples, code blocks, tables), replace the entire block — don't try to patch individual lines inside it, because partial matches are fragile.

#### Phase 5: Verify zero remaining

After all patches, search the document for the WRONG values you removed:

```bash
grep -c 'old_wrong_value' doc.md
# → should output 0 (exited 1 on no matches)
```

For source-code verification specifically, this step catches:
- Multiple places you missed (same wrong port referenced in 5 places)
- Injected duplicates from imprecise patches
- Remaining stale cross-references

### Common drift patterns

These classes of claim are the most prone to code-doc drift:

| Pattern | Why it drifts | Fix |
|---------|---------------|-----|
| **Port numbers** | Changed during dev, doc often updated for 1 of N references | Grep every occurrence after fix |
| **Env var names** | Case changes (`cache_ttl` → `CACHE_TTL`) during cleanup | Check the actual `os.environ.get()` call |
| **Pseudocode in docs** | Developer wrote intent-based pseudocode, then implemented differently | Update to match actual implementation |
| **JSON response examples** | Written from a curl output at one point, then the endpoint changed | Return the actual `status()` function output |
| **Log format strings** | Changed during logging refactors | Find the logging call, copy the format verbatim |
| **Config file schema** | Flat → nested during multi-provider refactor | Read the load/parse function |
| **"N features" / counts** | Added or removed features without updating the doc heading/summary | Count manually or grep for feature markers |
| **Diagram/flowchart labels** | Easiest to miss — often in SVG or ASCII art separate from text | Read every node label in diagrams |

### Pitfalls

- **Don't assume the first claim you verify is representative.** One accurate port doesn't mean all ports are accurate. Check every reference.
- **Don't trust the doc's timestamp.** It may say "updated today" but still reference removed functions.
- **Inline code examples > prose.** Code blocks and JSON examples are the most likely to be wrong because they're copied from an old terminal session.
- **Aspirational pseudocode.** Docs often contain intent-based pseudocode (`def f(x): return 2*x`) that never matched the actual implementation (`def f(x): return 3*x`). Treat every code block in the doc as potentially aspirational until verified.
- **Phantom references.** When a doc references a function name or class that doesn't exist in source (`_compute_max_tokens`, `BoundedSemaphore`), that's evidence the doc was written from intent, not from reading the code. Flag this to the user — it suggests the entire behavioral section may be aspirational.
- **Table formatting after patches.** When you patch a markdown table row, verify the surrounding rows still have the correct number of columns. A misplaced pipe can silently create an extra column, making the row unaligned with the header.

### Pitfall: One bad claim hides a whole category of bad claims

When you discover the **first** incorrect claim, do a full-category sweep before patching. If the env var table is wrong, check the port table and the config reference table too. If one port is wrong, grep the entire doc for that port. A single "I found one" opens the door to finding all of them in the same pass.

---

## 📖 Completeness Audit Mode

### 🗺️ Hermes Atlas Audit (most common ecosystem audit)

When auditing a Hermes ecosystem reference doc, use **Hermes Atlas** as the authoritative reference:

1. **Load Atlas data** — `web_extract(urls=["https://hermesatlas.com/"])` returns all 12 curated lists with star counts & descriptions
2. **Map sections** — Atlas has 12 categories; map each to the doc's corresponding section (or note it's missing entirely)
3. **Patch at three levels** (in order):
   - Level 1: Stale star counts (e.g. hermes-agent 134K→195.3K)
   - Level 2: Missing entries in existing tables (Atlas has 15-20 repos per category, doc often lists 6-10)
   - Level 3: Entire missing sections (Plugins & Extensions and Integrations & Bridges are the most common gaps)
4. **Layer 1 first** (stats, intro paragraph, sidebar) — safe to parallelize
5. **Layer 2** (table content) — one patch per unique old_string
6. **Layer 3** (structural inserts) — use full HTML blocks as old_string with enough surrounding context

See `references/ecosystem-taxonomy.md` for the full category taxonomy, live project lists, and patch layer guidance.

When the user asks what's missing from a document, you're doing a **completeness audit** — checking coverage against an external authoritative reference list rather than verifying individual claims.

### When to use

The user says any of:
- "What's missing from this document?"
- "Audit the coverage against [awesome list / ecosystem / official docs]"
- "Check our doc against the community resources"
- "Find gaps in the [ecosystem/capabilities/setup] section"

### Workflow

#### Phase 1: Load the document and the reference

1. **Read the target document** fully (paginated if large).
2. **Identify the external reference** — typically:
   - An awesome-list README (`awesome-XYZ`)
   - The official docs TOC / sidebar structure
   - A competitor/comparison doc
   - A community wiki or curated resource page
3. **Scrape the reference** — use `web_extract` on the reference URL (GitHub README, docs page, etc.) or `web_search` if the URL isn't known.

#### Phase 2: Catalog the reference

Extract every distinct item from the reference, organized by category. For awesome lists, the natural categories are often already in the README H2 headings:

```
- Official Resources
- Skills & Plugins
  - Community Skills
  - Plugins
  - Skill Registries
- Tools & Utilities
  - Deployment
- Integrations & Bridges
- Web UIs
- Multi-Agent & Swarms
- Domain Applications
- Forks & Derivatives
- Guides & Documentation
- Operational Playbooks
```

Don't just mentally note these — type them out as a structured catalog so you can compare systematically.

#### Phase 3: Compare section by section

Walk through each category in the reference and ask:
- **Does the target doc have a section covering this category?** If yes, compare its content against the reference entries. Are there specific entries missing?
- **If no section exists at all**, that's a gap. Note the category and the top 3-5 items from the reference that should go there.
- **If a section exists but is thin** (e.g. the target lists 6 projects but the reference has 50+), that's an expansion opportunity. Flag it.

For each gap, record:
```
Gap: <category>
Missing items: <list of specific tools/projects/resources from reference>
Impact: <why this matters — are these popular, complementary, unique?>
```

#### Phase 4: Layer on setup audit

After the document-vs-reference comparison, check whether the **user's own setup** would benefit from anything in the reference:

1. Cross-reference the user's known tools (from memory, session history, or `terminal` probes) against the reference categories.
2. Identify **low-hanging fruit** — things they could set up in 30 minutes that would improve their workflow.
3. Identify **deeper patterns** — multi-step setups that would compound in value but take longer.

This turns an abstract "missing from the doc" audit into personalized action items.

#### Phase 5: Present the gap analysis

Structure the output as:

```
## 🕳 What the Report Is Missing

[For each gap category, a brief table or bullet list]
| Missing Category | Current State | What to Add |

## 🔧 What Your Setup Is Missing

[Organized by effort level]
### Low-hanging fruit (30 min each)
- Thing A
- Thing B

### Deeper patterns
- Pattern X
- Pattern Y
```

#### Phase 6: Execute — Multi-section structural injection

If the user says "add these" or "do all of those improvements," you're doing **multi-section structural injection** — inserting entire new sections, replacing existing ones, renumbering sections, and updating every cross-reference in the document. This is more complex than single targeted patches because the sections, nav links, sidebar, and JS data form an interdependent graph.

##### 6a. Map the full dependency graph

Before touching a single line, identify every place that references section structure:

| Dependency | Example | Type |
|-----------|---------|------|
| **Sidebar (desktop)** | `<a href="#ecosystem">§12 Ecosystem</a>` | Must update for insert/reorder |
| **Sidebar (mobile)** | Same links with `onclick="toggleSB()"` | Must update for insert/reorder |
| **Hero quick links** | Quick-start grid with section links | Must insert new entry |
| **Stat counter** | `15 Sections` in hero stats | Must increment |
| **Quick-jump JS data** | `{ id: 'security', title: 'Security', tag: 'reference', num: '13' }` | Must add new entries, renumber existing |
| **Section IDs** | `<section id="next-steps">` | Must be unique, descriptive |
| **Section-nav prev/next** | `<a href="#ecosystem">→</a>` on each section | Must form a correct chain |
| **Badge numbers** | `§13`, `§14` in section-meta and card | Must renumber for shifted sections |
| **Section meta links** | `<a href="#next-steps">` in copySectionLink | Must match new IDs |
| **Internal text refs** | "run through the checklist in §13" | Must update if sections shifted |
| **Keyboard shortcut references** | Any shortcut pointing to a section ID | Rare but check |

##### 6b. Dependency ordering — patch in the right sequence

```
Layer 1 — No dependencies (safe to parallelize):
   1. Sidebar desktop links (new sections, renumbered links)
   2. Sidebar mobile links (same changes)
   3. Hero quick links (insert new entry)
   4. Stat counter (increment number)
   5. Quick-jump JS data (add new section objects, renumber shifted ones)

Layer 2 — Content patches (need unique old_string from the HTML):
   6. Add/expand subsections in existing sections (e.g. Curator in §08, ACP in §11)
   7. Replace existing section content (e.g. §12 Ecosystem expansion)
   8. Insert new sections (§13 Security)
   9. Renumber shifted sections (§13 → §14 Next Steps)

Layer 3 — Cross-reference updates (depend on layer 2's new IDs):
  10. Section-nav prev/next chains for affected sections
  11. Any internal text references mentioning section numbers
```

**Rule**: if two patches are in different layers, do layer 1 first. If they're in the same layer and don't overlap text, they can be done in parallel.

##### 6c. Build the old_string with enough context

For section-level replacements, include the **entire section** from `<!-- ===== N — TITLE ===== -->` through `</section>` plus the section-spacer. This guarantees uniqueness and avoids partial-match failures.

For section-nav updates, include both the prev AND next link in the old_string even if only one changes — this guarantees the match is unique across all sections' nav bars.

```python
# Pattern — replacing an entire section (from comment tag to closing tag)
patch(
    path="doc.html",
    old_string="""<!-- ===== 12 — ECOSYSTEM ===== -->
<section id=\"ecosystem\" ...>
    ...
    <a href=\"#workflows\">← Previous</a>
    <a href=\"#next\">Next →</a>
</section>""",
    new_string="""<!-- ===== 12 — ECOSYSTEM ===== -->
<section id=\"ecosystem\" ...>
    ...(expanded content)...
    <a href=\"#workflows\">← Previous</a>
    <a href=\"#security\">Next →</a>  <!-- updated ref -->
</section>"""
)
```

##### 6d. Post-Edit Cross-Document Consistency Audit (Mode 3)

After bulk renames, section insertions, or structural changes (e.g., `replace_all=true`, adding/removing agent entries, updating agent counts), use `references/consistency-audit-bulk-edit.md` for a third audit mode: **cross-document consistency checking**.

Unlike Mode 1 (claims vs reality) and Mode 2 (coverage vs reference), Mode 3 checks that every section of a single document is internally consistent after edits:

- Section header counts match table row counts
- Renamed entities are consistent across all references (architecture, decision trees, flow patterns, manifests, success criteria)
- No truncated content from sequential patches
- Checkbox/marker states reflect actual completion
- Ambiguity scan after name repurposing

**Trigger phrases:** "make sure the plan is the best it can be", "review and make sure this is consistent", "check all the references still make sense"

---

## ✅ Verification checklist

Before finishing (verification mode):

- [ ] Every verifiable claim checked against live state
- [ ] Only stale/new content patched — correct content left untouched
- [ ] Document structure intact (no broken HTML, no duplicated lines)
- [ ] Footer/timestamp updated to reflect verification date
- [ ] No unverifiable claims left standing (either removed or flagged)

---

For section-level replacements, include the **entire section** from `<!-- ===== N — TITLE ===== -->` through `</section>` plus the section-spacer. This guarantees uniqueness and avoids partial-match failures.

For section-nav updates, include both the prev AND next link in the old_string even if only one changes — this guarantees the match is unique across all sections' nav bars.

```python
# Pattern — replacing an entire section (from comment tag to closing tag)
patch(
    path="doc.html",
    old_string="""<!-- ===== 12 — ECOSYSTEM ===== -->
<section id=\"ecosystem\" ...>
    ...
    <a href=\"#workflows\">← Previous</a>
    <a href=\"#next\">Next →</a>
</section>""",
    new_string="""<!-- ===== 12 — ECOSYSTEM ===== -->
<section id=\"ecosystem\" ...>
    ...(expanded content)...
    <a href=\"#workflows\">← Previous</a>
    <a href=\"#security\">Next →</a>  <!-- updated ref -->
</section>"""
)
```

##### 6d. Verify the full chain after all patches

Run these checks after every batch:

```bash
# 1. All section IDs exist and are unique
grep -o 'id="[a-z-]*"' doc.html | sort | uniq -d
# → should output nothing (no duplicates)

# 2. Every #href points to a real id
# (spot-check: search for each section-nav target)

# 3. Old broken references are gone
grep -n 'href="#next"' doc.html
# → should output nothing (exited with 1)

# 4. Sidebar + nav chain forms a loopless path through all sections
grep -n '<a href="#(ecosystem|security|next-steps)"' doc.html | head -20
```

### Completeness-specific pitfalls

- **Don't confuse "document is wrong" with "document is incomplete."** Verification mode corrects stale content; completeness mode identifies missing content. These are different operations with different outputs and patch strategies. Verification patches replace text; completeness patches INSERT NEW SECTIONS.
- **Don't stop at the first gap you find.** The reference may have 10+ categories; keep comparing until you've exhausted the entire reference list.
- **Reference lists can themselves be stale.** An awesome list last updated 6 months ago may be missing new tools. Note "last reviewed" dates when you see them.
- **Awesome-list entries are not endorsements.** A project listed in the ecosystem may be experimental or abandoned. Flag maturity levels where the reference provides them.
- **Don't present missing-items-as-improvements without an organizing framework.** Raw lists of 50 tools are overwhelming. Group by category, tag by maturity (beta/production/experimental), and suggest where they'd fit in the existing document.

## ✅ Verification checklist

Before finishing (completeness mode):

- [ ] Full reference list scraped and cataloged by category
- [ ] Every reference category compared against the target document
- [ ] Gaps organized by impact level (missing vs thin vs absent section)
- [ ] User's setup audited for low-hanging fruit
- [ ] Patch plan written (if user requested execution)

## 📁 Support files

- `references/verification-commands.md` — Common verification commands per tool type
- `references/ecosystem-taxonomy.md` — Reusable ecosystem category taxonomy for completeness audits; includes the full awesome-hermes-agent resource catalog, maturity tagging conventions, and common "your setup" audit items
- `references/post-ingestion-verification.md` — Verify synthesized wiki pages against source structured data (JSON/CSV). Field-by-field cross-reference pattern to catch synthesis drift after data-to-wiki-page workflows. Six drift patterns with detection techniques, audit report template, and pitfalls for post-ingestion quality gates.
- `references/plan-audit-before-execution.md` — Pre-execution plan audit: cross-repo file comparison, PII counting, severity-classified findings against plan claims.
- `references/consistency-audit-bulk-edit.md` — Cross-document consistency audit after bulk renames/edits. Checks section headers vs content, cross-references after renames, truncation detection, checkbox/marker state, and ambiguity scan. Use after any `replace_all=true` or multi-section structural change.
