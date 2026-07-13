# Design Audit & Improvement Workflow

Audit an existing HTML page's design and apply targeted improvements inspired by top design systems (from `popular-web-designs`).

## When to use this

- User says "make this look better / more polished / more professional"
- User asks "any improvements or inspo from top sites"
- User has an existing HTML file and wants to elevate its design
- The page already works but looks dated or generic

## Workflow

### 1. Read the existing CSS

Search for `:root` to get the color palette and CSS custom properties:

```python
from hermes_tools import search_files, read_file
# Find the root block
result = search_files(pattern=r":root\s*\{", path="path/to/file.html", target="content", output_mode="content")
# Read the CSS section (usually lines 10-340)
css_section = read_file(path, offset=1, limit=340)
```

Key things to extract:
- `--bg-*`, `--fg-*` colors (theme palette)
- `--accent-*` colors (brand accent)
- `--font`, `--mono` (typeface choices)
- `--radius-*` (border radius scale)
- `--border-*` (border colors)
- `--sidebar-w`, `--content-w` (layout dimensions)
- Responsive breakpoints
- Light mode override (`[data-theme="light"]` or `@media prefers-color-scheme`)

### 2. Read a few section cards to understand layout density

```python
# Read hero section
hero = read_file(path, offset=140, limit=50)
# Read a feature card section
section = read_file(path, offset=180, limit=60)
```

Note: spacing between sections, card padding, typography hierarchy (heading vs body sizes), and component styling (buttons, badges, code blocks, tables).

### 3. Select relevant design templates

Match the page type to 2-4 design systems from `popular-web-designs`:

| Page Type | Best Templates |
|-----------|---------------|
| Reference / docs | Mintlify, Notion, MongoDB |
| Developer tool landing | Linear, Vercel, Supabase |
| Dark terminal aesthetic | Ollama, x.ai, Supabase |
| Dashboard / data-dense | Sentry, ClickHouse, PostHog |
| Premium / marketing | Stripe, Apple, Linear |
| Playful / friendly | PostHog, Figma, Lovable |

Load each:
```
skill_view(name="popular-web-designs", file_path="templates/linear.app.md")
skill_view(name="popular-web-designs", file_path="templates/mintlify.md")
```

### 4. Compare and identify gaps

For each dimension, compare current vs. template values:

| Dimension | Current | Template | Gap |
|-----------|---------|----------|-----|
| Background | `#0f1117` | Linear `#08090a` | Slightly lighter; deeper = more premium |
| Font | system-ui | Inter + JetBrains Mono | Huge visual improvement |
| Border style | `#2a2d3a` solid | `rgba(255,255,255,0.08)` semi-transparent | Translucent borders add depth on dark |
| Heading tracking | normal | -0.72px display | Tight tracking = purposeful |
| Card hover | none | translateY(-1px) + border shift | Micro-interaction polish |
| Light mode | cool gray | warm neutrals (Notion) | Warmth = approachable |

### 5. Rank by impact

Score each improvement by visual impact:

- **🔥 Massive** — typography/fonts, background depth, hero treatment
- **🔥 High** — card hover effects, border system, spacing rhythm
- **✨ Medium** — light mode warmth, radius consistency, filter pills
- **💡 Low** — individual micro-interactions (skip if scope-limited)

### 6. Present with a comparison table

Use a markdown table format that maps: Feature → Current → Inspired By → Impact. Include exact CSS values so the user knows *what* will change.

### 7. Offer to apply

Ask if they want you to patch the file. If they say yes:

- **Small changes** (5-10 lines): use `patch()` with old_string/new_string
- **Batch changes** (CSS variables, font links, hero gradient): use `patch()` for each independent change
- **Large block changes**: use `execute_code()` with Python file I/O

### Example: Improvement table format

| Feature | Current | Inspired By | Impact |
|---|---|---|---|
| Font | system-ui | Inter (Mintlify/Linear) | 🔥 Massive |
| Background | `#0f1117` | `#0a0b10` w/ white borders (Linear) | 🔥 High |
| Hero glow | ❌ | Radial gradient (Mintlify) | 🔥 High |
| Card hover | ❌ | Multi-layer shadow (Notion) | 🔥 High |
| Light mode | cool gray | Warm neutrals (Notion) | ✨ Medium |

## Pitfalls

- **Don't apply every template's every value** — pick ONE source per design dimension (background from Linear, borders from Mintlify, accent from current brand). Mixing dimensions from different templates is fine; mixing colors within one dimension creates clash.
- **Don't change the brand accent** unless the user asks for it. The page already has a defined accent color (#6366f1, #6762ff, etc.) — preserve it.
- **Test light mode** after any background/border change — what works in dark may wash out in light.
- **Font changes require adding Google Fonts `<link>`** in `<head>` — also add a `<link rel="preconnect>` for font performance.
- **Don't break existing JS** during CSS changes — verify `data-action` attributes, event listeners, and scroll behaviors still work after structural CSS changes.
- **Offer, don't auto-execute** — the user may only want the analysis, not the implementation.

## Related

- `html-application-building/references/fusion-design-session.md` — full session transcript combining multiple design systems into one artifact
- `html-application-building/references/onclick-to-event-delegation.md` — migrating inline onclick to data-action (complementary migration when refactoring existing pages)
- `html-application-building/references/cross-dimension-quality-audit.md` — extends this workflow with 6 additional audit dimensions (accessibility, UX polish, performance, semantic HTML, JS behavior, content structure). Use when the user asks for comprehensive review beyond design/CSS.
- `popular-web-designs` — the design system template catalog (54 templates)
