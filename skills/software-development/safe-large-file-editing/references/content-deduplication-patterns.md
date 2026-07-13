# Content Deduplication & Information Flow Optimization

Post-refactor patterns for large documentation files (HTML, Markdown, etc.) to eliminate redundancy while preserving discoverability.

---

## The Problem

Large docs grow organically. Multiple authors (or one author over time) add similar content in different sections because:
- They forget what already exists
- Each section "needs" the same context
- Copy-paste is faster than cross-linking

Result: **bloated files, maintenance risk, reader confusion**.

---

## Detection Heuristics

Run these checks programmatically on any doc >50KB:

```python
import re
from collections import Counter
import hashlib

def audit_duplicates(content):
    issues = {}

    # 1. Duplicate H2/H3 headings (exact text match)
    h2s = re.findall(r'<h2[^>]*>([^<]+)</h2>', content)
    h3s = re.findall(r'<h3[^>]*>([^<]+)</h3>', content)
    for heading_list, label in [(h2s, 'H2'), (h3s, 'H3')]:
        dupes = {h: c for h, c in Counter(heading_list).items() if c > 1}
        if dupes:
            issues[f'duplicate_{label}_headings'] = dupes

    # 2. Repeated code snippets (install commands, config blocks)
    cb_blocks = re.findall(r'<div class="code-block">[\s\S]*?</div>', content)
    cb_hashes = [hashlib.md5(b.encode()).hexdigest()[:8] for b in cb_blocks]
    cb_dupes = {h: c for h, c in Counter(cb_hashes).items() if c > 1}
    if cb_dupes:
        issues['duplicate_code_blocks'] = list(cb_dupes.keys())

    # 3. Repeated inline command patterns
    for pattern, label in [
        (r'winget install [^\n]+', 'winget_commands'),
        (r'zellij --layout [^\n]+', 'zellij_launch'),
        (r'hermes config set [^\n]+', 'hermes_config'),
    ]:
        matches = re.findall(pattern, content)
        dupes = {m: c for m, c in Counter(matches).items() if c > 1}
        if dupes:
            issues[f'duplicate_{label}'] = dupes

    # 4. Table header overlap (>80% same columns)
    tables = re.findall(r'<table>[\s\S]*?</table>', content)
    headers = [re.search(r'<thead>[\s\S]*?</thead>', t).group(0) if re.search(r'<thead>[\s\S]*?</thead>', t) else '' for t in tables]
    if len(headers) > 1:
        from itertools import combinations
        similar_pairs = []
        for i, j in combinations(range(len(headers)), 2):
            h1, h2 = headers[i], headers[j]
            words1, words2 = set(re.findall(r'<th[^>]*>([^<]+)</th>', h1)), set(re.findall(r'<th[^>]*>([^<]+)</th>', h2))
            if words1 and words2:
                overlap = len(words1 & words2) / len(words1 | words2)
                if overlap > 0.8:
                    similar_pairs.append((i, j, overlap))
        if similar_pairs:
            issues['similar_tables'] = similar_pairs

    return issues
```

---

## Consolidation Patterns

### Pattern 1: Duplicate Heading → Canonical Heading + Cross-Links

**Before:**
```html
<!-- Section A -->
<h3>🧱 The Stack</h3>
<table>...</table>

<!-- Section B -->
<h3>🧱 The Stack</h3>
<table>...</table>
```

**After:**
```html
<!-- Section A -->
<h3>🧱 The Simple Stack</h3>
<table>...</table>

<!-- Section B -->
<h3>🧱 The End Game Stack</h3>
<table>...</table>
```

**Rule:** If two sections share a concept, **qualify the heading** with the section's context. Don't use identical headings.

### Pattern 2: Repeated Snippet → Single Canonical + Link

**Before:** `winget install Zellij.Zellij` appears 4× across file

**After:** Consolidate to one "🚀 Quick Start" subsection, replace others with:
```html
<p class="cross-link"><a href="#zellij-quick-start">See Zellij Quick Start →</a></p>
```

**Implementation:**
```python
def consolidate_snippet(content, pattern, anchor_id, link_text):
    matches = list(re.finditer(pattern, content, re.MULTILINE))
    if len(matches) <= 1:
        return content
    for m in reversed(matches[1:]):
        content = content[:m.start()] + f'<p class="cross-link"><a href="#{anchor_id}">{link_text}</a></p>' + content[m.end():]
    return content
```

### Pattern 3: Duplicate Table → Summary + Deep-Dive

**Before:** "Running Strategies" table in §02 lists `zellij`/`tmux`; full Zellij section in §03 repeats 2 rows

**After:** Keep summary in §02, add cross-link:
```html
<td data-label="Recommendation"><code>zellij</code> / <code>tmux</code> — <a href="#runtimes-zellij">See §03 for details</a></td>
```

### Pattern 4: Install/Setup Consolidation

**Before:** Separate "Quick Install" subsection + scattered commands in other code blocks

**After:** Merge into single "Quick Start" with:
1. Install command
2. Verification command
3. Launch command (using the canonical layout)

---

## Cross-Reference Discipline

### Anchor ID Conventions

| Content Type | Anchor ID Pattern | Example |
|--------------|-------------------|---------|
| Section | `#section-slug` | `#simple-stack` |
| Subsection (H3/H4) | `#section-h3-slug` | `#runtimes-zellij` |
| Code snippet | `#section-snippet-slug` | `#zellij-quick-start` |
| Table | `#section-table-slug` | `#runtimes-running-strategies` |

### Link Text Conventions

- **Back to overview:** `↩ Back to Simple Stack` (left arrow = back)
- **Forward to detail:** `See §03 for details →` (right arrow = forward)
- **Related concept:** `Related: Zellij Quick Start`

### `data-action` Integration

For SPAs or JS-enhanced static docs, use the existing `data-action` system:
```html
<a href="#zellij-quick-start" data-action="scroll-to" data-target="zellij-quick-start">Quick Start →</a>
```
JS handler:
```js
case 'scroll-to':
  document.getElementById(e.getAttribute('data-target')).scrollIntoView({ behavior: 'smooth' });
  break;
```

---

## Verification Checklist (Add to Phase K / Final Audit)

```bash
# 1. Duplicate headings
grep -oP '<h[23][^>]*>\K[^<]+' file.html | sort | uniq -d

# 2. Duplicate code block hashes
python3 -c "
import re, hashlib
c = open('file.html').read()
blocks = re.findall(r'<div class=\"code-block\">[\s\S]*?</div>', c)
hashes = [hashlib.md5(b.encode()).hexdigest()[:8] for b in blocks]
from collections import Counter
for h, cnt in Counter(hashes).items():
    if cnt > 1: print(f'DUPLICATE block hash: {h} (x{cnt})')
"

# 3. Repeated command patterns
grep -o 'winget install [^<]*' file.html | sort | uniq -d
grep -o 'zellij --layout [^<]*' file.html | sort | uniq -d
grep -o 'hermes config set [^<]*' file.html | sort | uniq -d

# 4. Concept keyword cross-check
for kw in zellij hermes tmux ollama; do
    echo "=== \$kw ==="
    grep -n "\$kw" file.html | head -20
done
```

---

## Metrics to Track

| Metric | Target |
|--------|--------|
| Duplicate H2/H3 | 0 |
| Duplicate code block (exact) | 0 |
| Repeated install commands | ≤ 1 per tool |
| Cross-links added per consolidation | ≥ 1 |
| File size reduction | 2–5% typical |

---

## Workflow: Deduplication Pass

1. **Run detection** on full file
2. **Group findings** by concept (Zellij, Hermes, tmux, etc.)
3. **For each concept:**
   - Identify canonical location (usually the deep-dive section)
   - Qualify heading in overview sections
   - Replace duplicates with cross-links
   - Verify all links resolve
4. **Run verification checklist** again
5. **Update master plan** with actual metrics (as done in Phase L)

---

## Anti-Patterns to Avoid

| Anti-Pattern | Why It Fails | Fix |
|--------------|--------------|-----|
| "I'll just copy this table to both sections" | Diverges on updates; reader sees same data twice | Summary in section A, link to section B |
| "Each section should be self-contained" | Leads to massive repetition in 16-section docs | Self-contained = "has what you need" NOT "has everything" |
| Identical `<h3>` in multiple sections | Screen readers announce same heading; no context | Qualify with section context: "The Simple Stack" / "The End Game Stack" |
| Separate "Install" and "Quick Start" subsections | Fragmented UX; user checks both | One "Quick Start" = install + verify + launch |

---

## Tools & Scripts

### `scripts/dedupe-audit.py`

```python
#!/usr/bin/env python3
"""
Run: python3 dedupe-audit.py AI\ Architecture.html
Outputs: Duplicates summary + suggested consolidations
"""
import sys, re, hashlib
from collections import Counter

path = sys.argv[1]
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

print(f"Auditing {path} ({len(content):,} bytes)\n")

# 1. Headings
h2s = re.findall(r'<h2[^>]*>([^<]+)</h2>', content)
h3s = re.findall(r'<h3[^>]*>([^<]+)</h3>', content)
for label, heads in [('H2', h2s), ('H3', h3s)]:
    dupes = {h: c for h, c in Counter(heads).items() if c > 1}
    if dupes:
        print(f"Duplicate {label}s:")
        for h, c in dupes.items():
            print(f"  {c}x: {h}")
        print()

# 2. Code blocks
blocks = re.findall(r'<div class="code-block">[\s\S]*?</div>', content)
hashes = [hashlib.md5(b.encode()).hexdigest()[:8] for b in blocks]
dupes = {h: c for h, c in Counter(hashes).items() if c > 1}
if dupes:
    print(f"Duplicate code blocks: {len(dupes)}")
    for h, c in dupes.items():
        print(f"  {c}x: {h}")
    print()

# 3. Common command patterns
patterns = [
    ('winget install', r'winget install [^\n<]+'),
    ('zellij --layout', r'zellij --layout [^\n<]+'),
    ('hermes config set', r'hermes config set [^\n<]+'),
]
for label, pat in patterns:
    matches = re.findall(pat, content)
    dupes = {m: c for m, c in Counter(matches).items() if c > 1}
    if dupes:
        print(f"Duplicate {label}:")
        for m, c in dupes.items():
            print(f"  {c}x: {m}")
        print()

print("Done.")
```

### `scripts/verify-crosslinks.py`

```python
#!/usr/bin/env python3
"""
Verify all internal anchor links resolve.
Run: python3 verify-crosslinks.py AI\ Architecture.html
"""
import sys, re

path = sys.argv[1]
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Collect all IDs
ids = set(re.findall(r'id="([^"]+)"', content))

# Check all href="#..."
links = re.findall(r'href="#([^"]+)"', content)
broken = [l for l in links if l not in ids]

if broken:
    print(f"BROKEN LINKS ({len(broken)}):")
    for l in broken:
        print(f"  #{l}")
    sys.exit(1)
else:
    print(f"All {len(links)} internal links resolve ✅")
```

---

## Session Notes: AI Architecture.html Phase L

**File:** `~/AppData/Local/hermes\AI Architecture.html` (173 KB, 16 sections)

| Consolidation | Before | After |
|---------------|--------|-------|
| "🧱 The Stack" H3 | 2× (identical) | 0× (qualified) |
| `winget install Zellij.Zellij` | 4× | 1× (in Quick Start) |
| `zellij --layout` launch | 3× | 2× (Layout Ex + Quick Start) |
| Quick Script H4 | 2× | 1× (removed orphan) |
| Quick Install subsection | Standalone | Merged into Quick Start |
| Cross-links added | 0 | 2 (Back to Simple/End Game) |

**File size:** 178 KB → 173 KB (-2.8%)

**Key learning:** The "self-contained section" instinct causes bloat. Cross-links with clear direction (↩ back / → forward) preserve discoverability without duplication.