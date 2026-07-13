---
name: html-doc-ux
description: Surgically add UX enhancements to existing static HTML reference documents — back-to-top, scroll indicators, clipboard fallback, mobile touch targets, stagger animations, theme toggle, reading progress. Not building from scratch (that's html-application-building), not merging content (that's knowledge-consolidation), not auditing claims (that's document-verification-update).
category: creative
triggers:
  - "enhance this HTML doc"
  - "add UX polish to this report"
  - "make this HTML page feel more polished"
  - "add mobile support to this HTML doc"
  - "improve the UX of this reference page"
  - "add theme support / dark mode to this HTML"
  - "add a back-to-top button"
  - "add reading progress bar"
  - "make code blocks copyable"
  - "add stagger entrance animations"
  - "fix the spacing / layout"
  - "do a spacing audit / layout pass"
  - "add a copy button to code blocks"
  - "clean up the vertical rhythm"
  - "make this HTML polish pass"
  - "refactor this HTML doc"
  - "clean up this HTML page"
  - "restructure this HTML doc"
  - "reframe this document"
  - "reorganize this HTML report"
  - "reorganize around stacks / tiers / user levels"
  - "turn this into a decision guide"
  - "pivot this doc to stack-based navigation"
  - "make this page more accessible"
  - "add skip to content link"
  - "add no-JS fallback"
  - "fix heading hierarchy"
  - "add aria-expanded"
  - "add scroll-padding"
  - "accessibility pass"
  - "a11y pass"
  - "add gradient mesh to hero"
  - "add visual depth to hero section"
  - "hero background glow"
  - "make tables responsive on mobile"
  - "table card stacking"
  - "add syntax highlighting to code blocks"
  - "inline styles should be classes"
  - "migrate inline styles to CSS"
---

# HTML Document UX Enhancement

Add polished UX patterns to an existing static HTML document using targeted patch edits — no rewrites, no full file overwrites.

## 🎯 When to use

This skill sits between three others:

| Skill | Handles |
|-------|---------|
| `knowledge-consolidation` | Merging multiple fragmented files into one comprehensive document |
| **`html-doc-ux`** ← YOU ARE HERE | Adding UX enhancements to the already-consolidated HTML document |
| `html-application-building` | Building polished HTML SPAs from scratch (4-pass iteration) |
| `document-verification-update` | Auditing claims against live system state |

Use this skill when the document already exists, the content is correct, and the user wants it to **look and feel better** — better mobile support, interactive patterns, theme support, navigation helpers.

## 🧰 Workflow

### Phase 1: Audit the document

**A. Feature audit** — what interactive patterns exist vs. what's missing:

1. **Read the full HTML** — use `read_file` with offset/limit pagination to read the entire file section by section
2. **Identify the existing patterns** — note what's already present:
   - Theme support (`data-theme`, `toggleTheme`, `localStorage`)
   - Navigation (sidebar, TOC, section navigation)
   - Responsive design (media queries, viewport meta)
   - Existing interactive elements (filters, accordions, copy buttons)
3. **Check for CSS custom properties** — a `:root` block with `--var` definitions means the doc has a theme system; use the existing vars rather than hardcoding colors
4. **Identify gaps** — what's missing that would improve UX:
   - Mobile touch targets (≥44px tap targets on small screens)
   - Reading progress bar (fixed top bar showing scroll %)
   - Back-to-top button (floating button after scrolling past the fold)
   - Code block copy buttons
   - Table scroll overflow indicators (gradient fade hinting at scrollable content)
   - iOS-safe clipboard fallback
   - Stagger entrance animations (sections fade in on load)
   - Keyboard shortcuts modal (`?` key handler)
   - **Hero visual depth** — gradient mesh or subtle background glow behind hero/title section
   - **Table responsive card-stacking** — wide tables that stack as labeled cards ≤640px
   - **Code block syntax highlighting** — lightweight token coloring (keywords, strings, comments)
   - **Copy button coverage** — every `<pre>`/`.code-block` has a functioning copy button

**B. Layout quality audit** — check the visual rhythm and spacing consistency:

1. **Section margins** — are all `<section>`s uniformly spaced? 
2. **Card/dark box padding** — consistent horizontal and vertical padding?
3. **Heading hierarchy** — are `h2` → `h3` → `p` gaps consistent? (Collapsing margins: the gap is `max(h3.margin-top, p.margin-bottom)`)
4. **Mobile breakpoint parity** — does each desktop feature have a responsive counterpart at 640px, 480px, 380px?
5. **Touch target minimums** — are buttons, links, tabs, and filter chips ≥44px on 640px-and-under?
6. **Footer breathing room** — does the footer have `padding` bottom so last section content doesn't touch the edge?
7. **Light/dark theme parity** — both themes should have the same layout; only colors change
8. **Table overflow** — are wide tables wrapped in a scroll container with `overflow-x: auto`? At ≤640px do they need card-stacking (see `references/responsive-tables.md`)?
9. **Spacer elements** — if the doc uses `<br>` for vertical gaps, replace with a `.section-spacer` CSS class for consistent rhythm

**C. Code block content integrity** — verify that code displayed inside the doc is actually copyable without introducing syntax errors:

1. **Trailing characters** — Scan code blocks for stray characters at line endings (`|`, `\`, `,`) that would create syntax errors if pasted into a real file. This is common where HTML rendering leaves visible artifacts from copy-paste or formatting.
2. **Escaped text** — Check for literal `\n`, `\t`, `\\` sequences that got rendered as visible text rather than actual line breaks. These appear when a patch or template used escaped newlines instead of real ones.
3. **Syntax validity** — For config file examples (YAML, TOML, JSON), mentally parse a few key lines to confirm they'd pass basic validation. A `{` without `}`, a trailing `|` in YAML, or an unclosed string means anyone copying the example gets a broken config.
4. **HTML entity bleed** — Look for `&lt;`, `&gt;`, `&amp;` appearing as visible text where they should have been rendered as `<`, `>`, `&`.
5. **Line-continuation escapes** — In shell/YAML code blocks, verify that `\` at line endings are intentional continuation markers, not rendering artifacts.

**D. Print readiness** — check if the HTML document would produce a clean printed page:

1. **`@media print` rule** — If absent, the document prints with navigation chrome, animations, dark backgrounds, and unreadable text on paper.
2. **UI chrome hidden** — Sidebar, sticky header, modals (QJ/KS overlays), progress bar, filter bar, and footer should all `display: none` in print.
3. **Card break avoidance** — Cards, code blocks, and highlight boxes should get `break-inside: avoid` so they don't split across pages.
4. **Light-mode forcing** — If the doc has a dark theme, the print style should force light colors (`background: #fff !important; color: #000`) regardless of user `prefers-color-scheme`.
5. **Animation suppression** — Stagger entrance animations, CSS transitions, and `@keyframes` must be disabled in print: `animation: none !important; opacity: 1 !important; transform: none !important;`.

After identifying issues, make a todo list and fix each with targeted patches. Address layout/rhythm issues BEFORE adding interactive features — the foundation determines how good the polish looks.

### 🧭 Phase 1.5: Adding Content Subsections

Before enhancing UX, you may need to **insert new content** into the document (a new subsection, comparison table, or block of text) that matches the document's existing design language.

This is a different motion from restructuring (Phase 5) or UX enhancement (Phases 2-4) — it's a content-editing pass that should respect the document's visual system.

#### Workflow

**1. Survey the document's design language**

Read the document and identify its reusable pattern classes — these are the building blocks for any new content:

| Pattern | HTML Class | Typical Usage |
|---------|-----------|---------------|
| Comparison tables | `.tw` → `<div class="tw"><table>...` | Feature matrices, decision matrices |
| Highlight/callout boxes | `.hl-box` | Key takeaways, tips, TL;DR summaries |
| Code blocks | `.code-block` → `.cb-header` + `.cb-body` | Commands, config examples, output |
| Badge labels | `.badge` (inline), `.badge-green`/`.badge-red` (colored variants) | Feature tags, status indicators |
| Card sections | `.card` → `.card-header` + `h2`/`h3` + `p`/`ul` | Main section bodies |
| Section metadata | `.section-meta` → `.sm-badge`, `.sm-tag`, `.sm-reading` | Section number, category, reading time |
| Lists | `<ul>` with default card styling | Feature lists, guide links |

**2. Find the right insertion point**

- Use `search_files` grep to find the anchor (e.g. `"<h3>Key Integrations</h3>"` or the section boundary)
- Use `read_file` with offset/limit around that line to see surrounding context
- Choose the `old_string` for `patch()`: include 1-3 lines of surrounding context for uniqueness

**3. Match existing patterns — DON'T invent new classes**

- Use the document's existing class names (`.tw`, `.hl-box`, `.badge`, `.badge-green`). Do not invent custom inline styles unless the document already uses them.
- For tables: wrap in `<div class="tw"><table>...</table></div>`
- For highlighted callouts: use `<div class="hl-box" style="margin-top:16px;">` (the margin-top matches the doc's standard vertical rhythm)
- For badges inside table cells: use `<span class="badge badge-green">` (green) or `<span class="badge">` (default purple-blue)
- Preserve existing spacing: paragraphs within cards use two-space indent in the HTML source to match surrounding content

**4. Update metadata in lockstep**

Any content addition changes document stats. Update these together:

| Location | What to change |
|----------|---------------|
| Hero meta row | Section count (e.g. `11` → `12` sections) |
| Stat cards | Corresponding stat card value |
| Quick-jump section array (JS) | Add entry if a new top-level section was created |
| Sidebar links | Add link if a new top-level section was created |
| Section-nav prev/next | Update adjacent sections' nav links if new section inserted |
| Reading time estimate (`⏱ ~N min`) | Increase if the content is substantial |

Use `patch()` for each change — they're independent, localized edits.

**5. Verify after insertion**

- Re-read the area around the insertion to confirm valid HTML (no unclosed tags, nested class mismatches)
- Confirm the new content renders correctly in both light/dark themes
- If you added a table, verify the `.tw` wrapper is present (without it, the table won't have overflow scrolling or proper responsive styling)
- Spot-check that stat counters in hero, stat cards, and any JS quick-jump arrays match

#### Example: Adding a code editor comparison table to the Ecosystem section

```html
<!-- New subsection heading -->
<h3>🧑‍💻 Code Editors &amp; IDE Integration</h3>
<p>How Hermes integrates with the code editor landscape.</p>

<!-- Comparison table matching document patterns -->
<div class="tw">
    <table>
        <tr><th>Editor</th><th>Hermes Integration</th><th>Best For</th><th>Trade-off</th></tr>
        <tr>
            <td><strong>🔹 Zed</strong></td>
            <td><span class="badge badge-green">Native ACP</span> — ...</td>
            <td>Speed-first devs ...</td>
            <td>Smaller extension ecosystem ...</td>
        </tr>
    </table>
</div>

<!-- TL;DR callout box -->
<div class="hl-box" style="margin-top:16px;">
    <p><strong>✅ The Combo (Recommended)</strong></p>
    <p>...</p>
</div>
```

#### Pitfalls

- **Don't invent new classes** — the document already has `.tw`, `.hl-box`, `.badge`, `.badge-green`. Using new class names means the new content won't match the document's visual system.
- **Inline styles for spacing, NOT for colors/fonts** — the document's theme system handles colors. Only use inline styles for margin/padding adjustments (`style="margin-top:16px;"`), and only when the document already uses this pattern.
- **HTML entity encoding** — use `&amp;` for `&`, `&lt;` for `<`, `&gt;` for `>` inside HTML content (not inside code blocks). Missing entity encoding breaks the HTML.
- **Stat counters cascade** — if you update the hero section count without also updating the stat card, the page shows conflicting numbers. Always update both.
- **Content insertion doesn't change navigation** — inserting a subsection (not a top-level section) means sidebar, section-nav, and quick-jump don't need updating. Only update them if you're adding a new `<section>` element.
- **Badge color semantics** — the doc uses `.badge-green` for positive/active states (e.g. "Native ACP"), `.badge` (default purple) for neutral info, `.badge-red` for warnings/limitations. Pick the right color for the semantic context.

### Phase 1.75: Framework Assessment — Vanilla vs Dependency

Before adding CSS/JS enhancements, decide whether the document should stay dependency-free or adopt a framework/build tool. The default for reference/README-style HTML docs should be **vanilla** — zero dependencies, zero build step, open-directly-in-browser.

| Approach | When it wins | Cost |
|----------|-------------|------|
| **Vanilla (default)** | Static reference docs, README-style guides, internal reports, one-off pages. All interactivity needed is search, filter, copy, theme toggle — all achievable in ~2.5KB of vanilla JS. | None |
| **HTMX** | Document needs server-driven partial updates, form submissions, or live data polling. Overkill for pure static content — you'd be adding a server just to use it. | +14KB htmx.min.js + server requirement |
| **Alpine.js** | Document has small reactive widgets (accordions, tabs, dynamic counts) but isn't an SPA. Overkill if you have 2-3 interactive elements that vanilla handles fine. | +15KB alpine.min.js |
| **Tailwind CSS** | Document has many custom components and you want consistent spacing/typography. Requires build step (PostCSS/CLI). Not worth it for a single-document reference page. | +build step, large generated CSS |
| **React / Vue / Svelte** | Document is becoming a full application with routing, state management, or multi-user interactivity. Never the right choice for a static README or reference doc. | +40KB+ runtime, build tooling, JSX compilation |

**Decision rules:**
- **Is the document mostly static content with lightweight interactivity?** → Vanilla. Always.
- **Is the user asking you to add React?** → Push back with this table. Explain the cost in bundle size, build complexity, and dependency maintenance.
- **Does the document need to be editable by non-developers in a CMS?** → Consider HTMX or Alpine.
- **Is the document evolving into a web application?** → Suggest Astro (static-first, embed frameworks later) or consider `html-application-building` skill instead.

The enhancements in Phases 2-4 are all designed for vanilla HTML/JS/CSS. No framework needed.

### Phase 2: Add CSS enhancements via targeted patches

Each enhancement needs specific CSS. Use the reference patterns in `references/` for exact code. Strategy:

1. **Patch the existing `</style>`** block — insert new CSS just before the closing `</style>` tag
2. **Use `old_string` with enough surrounding context** to guarantee uniqueness (include the preceding rule or comment)
3. **Use CSS custom properties** where the doc already defines them (`var(--bg-surface)`, `var(--fg-primary)`, etc.)
4. **Group related enhancements** by adding them as a single patch under a comment header:
   ```css
   /* --- Table scroll indicator --- */
   .tw::after{...}
   
   /* --- Back to top --- */
   .back-to-top-btn{...}
   ```

**Hero gradient mesh** — add subtle visual depth behind the hero section using a `::before` pseudo-element with radial gradients. See `references/hero-gradient-mesh.md` for full pattern and variants.

**Syntax highlighting classes** — for docs with inline code samples in the HTML (not rendered via a highlighter), add lightweight token coloring classes:
```css
.c-key { color: var(--accent-cyan); }
.c-str { color: var(--accent-amber); }
.c-op { color: var(--accent-primary); }
.c-com { color: var(--fg-muted); font-style: italic; }
```
Apply these to `<span>` elements inside `.cb-body` or `<pre>` blocks. These classes cover keywords, string literals, operators, and comments. They are NOT a full syntax highlighter — they provide just enough visual structure for readers to scan configuration examples.

**Inline style → CSS class migration** — if the audit finds hardcoded `style="background:rgba(...)"` or `style="margin-top:NNpx;"` attributes scattered in the HTML body, consolidate them into CSS utility classes:
1. Identify unique color/spacing values (e.g., `rgba(103,98,255,0.08)` appearing 6 times across different card icons)
2. Create utility classes: `.icon-primary { background: rgba(103,98,255,0.08); }`, `.mt-1 { margin-top: 6px; }`
3. Use `patch()` with `replace_all=true` to swap each inline `style="..."` for the class
4. Add a comment header grouping the utilities so future editors know the pattern

### Phase 3: Add JS enhancements via targeted patches

1. **Patch the existing `<script>` block** — find the Last Standing JS (the final `})();` or `</script>` tag) and insert before it
2. **Each JS pattern gets its own comment block** with a clear heading
3. **Always provide a fallback** for APIs that may not be available (especially on iOS/non-HTTPS):
   - `navigator.clipboard.writeText` → `document.execCommand('copy')` via hidden textarea
   - `scroll-behavior: smooth` CSS → `window.scrollTo({ behavior: 'smooth' }) ` JS fallback
   - Touch events → pointer events are preferred but fall back to touch
4. **Use `passive: true`** on scroll/touch event listeners for performance

**Copy toast pattern.** After any clipboard write that the user triggers intentionally (section link copy, code block copy), show a slide-up confirmation toast. This is critical because clipboard writes are silent — the user gets no feedback otherwise:

```javascript
/* ---- Copy toast (confirmation popup) ---- */
window.showToast = function(msg) {
    var t = document.getElementById('copyToast');
    if (!t) {
        t = document.createElement('div');
        t.id = 'copyToast';
        t.className = 'toast';
        t.innerHTML = '<span class="toast-icon">✓</span> <span class="toast-msg"></span>';
        document.body.appendChild(t);
    }
    t.querySelector('.toast-msg').textContent = msg.replace('✓ ','');
    t.classList.add('show');
    clearTimeout(t._hide);
    t._hide = setTimeout(function(){ t.classList.remove('show'); }, 2000);
};
```

```css
.toast {
    position: fixed;
    bottom: 24px;
    left: 50%;
    transform: translateX(-50%) translateY(80px);
    background: var(--bg-elevated);
    border: var(--border-strong);
    color: var(--fg-primary);
    padding: 8px 16px;
    border-radius: var(--radius-pill);
    font-size: 13px;
    font-weight: 500;
    box-shadow: var(--shadow-lg);
    opacity: 0;
    transition: all 0.25s cubic-bezier(0.22, 1, 0.36, 1);
    z-index: 300;
    pointer-events: none;
    white-space: nowrap;
}
.toast.show {
    opacity: 1;
    transform: translateX(-50%) translateY(0);
}
```

Wire `showToast('✓ Link copied')` into every `copySectionLink` handler after the clipboard write.

**Stagger: hero section exclusion.** When the first `<section>` is a hero with background glow, stat row, and quick-start grid (common in reference docs), exclude it from the stagger animation so it appears instantly. Without this, the page's most important visual first impression jumbles in alongside the content cards:

```javascript
const secs = document.querySelectorAll('section:not(#intro)');
const intro = document.getElementById('intro');
if (intro) { intro.style.opacity = '1'; intro.style.transform = 'translateY(0)'; }
```

**CSS `--stagger-delay` var (preferred over nth-child).** The cleanest approach: JS sets a CSS variable on each section with its staggered delay value, then CSS uses `transition-delay: var(--stagger-delay)` to let the browser handle timing natively via composited CSS transitions. This avoids N+1 timers and layout thrash:

```css
/* Per-section transition with --stagger-delay consumed from JS */
section:not(#intro) {
    opacity: 0;
    transform: translateY(8px);
    transition: opacity 0.4s cubic-bezier(0.22,1,0.36,1) var(--stagger-delay, 0s),
                transform 0.4s cubic-bezier(0.22,1,0.36,1) var(--stagger-delay, 0s);
}
```

```javascript
/* ---- Stagger entrance animations ---- */
window.addEventListener('load', function() {
    var secs = document.querySelectorAll('section:not(#intro)');
    var intro = document.getElementById('intro');
    if (intro) { intro.style.opacity = '1'; intro.style.transform = 'translateY(0)'; }
    secs.forEach(function(s, i) {
        s.style.setProperty('--stagger-delay', (i * 0.07) + 's');
    });
    /* Double rAF — browser handles all transitions in one paint */
    requestAnimationFrame(function() {
        requestAnimationFrame(function() {
            secs.forEach(function(s) {
                s.style.opacity = '1';
                s.style.transform = 'translateY(0)';
            });
        });
    });
});
```

**JS injection pattern (for repeated HTML structures).** When a UI element (like a code-block copy button) needs to appear in 50+ instances, don't edit each HTML block individually. Inject the element dynamically in JS:

```javascript
/* ---- Inject copy buttons into every code block ---- */
document.querySelectorAll('.cb-header').forEach(function(hdr) {
    if (hdr.querySelector('.cb-copy')) return; // guard: skip if already injected
    const btn = document.createElement('button');
    btn.className = 'cb-copy';
    btn.onclick = function(){ copyCodeBlock(this); };
    btn.title = 'Copy code';
    btn.setAttribute('aria-label', 'Copy code');
    btn.textContent = '�';
    hdr.appendChild(btn);
});
```

This avoids touching 50+ HTML templates. Guard with a presence-check (`if (el.querySelector)`) so re-injecting is idempotent. Wire the handler function globally (`window.fnName = function...`).

**Active link tracking with IntersectionObserver.** For docs with a sidebar that should highlight the current section, replace `scroll` event handlers with IntersectionObserver. This fires zero layout work on scroll — the observer only triggers when a section crosses the threshold:

```javascript
/* ---- Active link tracking (IntersectionObserver) ---- */
(function() {
    var links = document.querySelectorAll('.sb-link[data-section]');
    var sectMap = {};
    links.forEach(function(a) { sectMap[a.getAttribute('data-section')] = a; });
    var ids = Object.keys(sectMap);
    var visible = {};
    var obs = new IntersectionObserver(function(entries) {
        entries.forEach(function(e) { visible[e.target.id] = e.isIntersecting; });
        var best = null;
        ids.forEach(function(id) {
            if (!visible[id]) return;
            var el = document.getElementById(id);
            if (!el) return;
            var rect = el.getBoundingClientRect();
            if (!best || rect.top < document.getElementById(best).getBoundingClientRect().top) {
                best = id;
            }
        });
        links.forEach(function(a) {
            a.classList.toggle('active', a.getAttribute('data-section') === best);
        });
    }, { threshold: 0, rootMargin: '-48px 0px -60% 0px' });
    document.querySelectorAll('section[id]').forEach(function(s) { obs.observe(s); });
})();
```

**Key config:**
- `rootMargin: '-48px 0px -60% 0px'` — the top 48px accounts for the fixed header; the bottom -60% means a section is "active" when it occupies the top 40% of the viewport, making the transition feel natural as you scroll down
- `threshold: 0` — fires as soon as any pixel of the section enters the root margin zone
- `data-section` attribute — use `data-section="unique-id"` on sidebar links rather than parsing `href` values, so the tracking works even if URLs change

### Phase 4: Verify

1. **Check each patch succeeded** — `success: true` in the result
2. **Re-read the modified section** to confirm no broken HTML
3. **Toggle theme** (if applicable) to verify both light/dark modes
4. **Test on mobile viewport** — the patterns in `references/` are designed to work at widths down to 320px
5. **Copy button audit** — verify that every `.code-block` has a `.cb-copy` button. Count matches:
   ```bash
   grep -c 'class="code-block"' doc.html
   grep -c 'cb-copy' doc.html
   ```
   If copy buttons are injected by JS (`injectCopyButtons()`), verify the function exists in the script block and handles all `.cb-header` elements. Also verify a guard exists (`if (hdr.querySelector('.cb-copy')) return;`) so re-injection is idempotent.
6. **Responsive table check** — at ≤640px, tables should stack as cards with labels from `data-label`. Verify `<td>` elements have `data-label` attributes matching their `<th>` header. Count against total:
   ```bash
   grep -c 'data-label=' doc.html     # should equal <td> count
   grep -c 'data-label=' doc.html     # if it's 0, the responsive CSS won't show labels
   ```

### Phase 5: Content Restructuring & Reframing

Some tasks go beyond UX polish — the user wants the document **reorganized, reframed, or pivoted** to a new organizing principle. This is a different class of work from adding a back-to-top button.

#### Workflow assessment — patch vs full rewrite

Ask: *"Would I need 30+ individual patches, each touching a different line range, to complete this restructure?"*

| Scenario | Approach | Why |
|----------|----------|-----|
| Renumber 2-3 sections, adjust a few links | **Targeted patches** | Each change is localized and independent |
| Renumber 15→11 sections, rewrite sidebars, section-nav everywhere, quick-jump data, filter tags, hero, stat cards, meta row | **Full rewrite** | 50+ interconnected patches are slower, more fragile, and harder to verify correctness than one clean generation |
| Add a new section mid-doc | **Targeted patch** — insert before the next section boundary | Localized change |

When a full rewrite IS appropriate:
1. The restructuring affects every section (renumbering, retitling, new organizing principle)
2. Content is being consolidated/removed (sections folded into others)
3. Every navigation surface needs updating (sidebar, mobile sidebar, section-nav prev/next, quick-jump JS array)
4. The hero, meta row, stat cards, and filter bar all need new copy

**The `execute_code` rewrite technique** — don't hand-write the output. Use Python via `execute_code` to programmatically generate the restructured HTML from a data model:

```python
from hermes_tools import read_file, write_file

# 1. Read the original
original = read_file('report.html')['content']

# 2. Define the new structure as data
sections = [
    {'id': 'intro', 'num': '00', 'title': 'The Stack Guide', 'tag': 'stacks'},
    {'id': 'simple-stack', 'num': '01', 'title': 'Simple Stack', 'tag': 'stacks'},
    {'id': 'endgame-stack', 'num': '02', 'title': 'End Game Stack', 'tag': 'stacks'},
]

# 3. Generate nav for each section programmatically
def gen_nav(sections, idx):
    prev_link = '' if idx == 0 else f'<a href="#{sections[idx-1]["id"]}">...</a>'
    next_link = '' if idx == len(sections)-1 else f'<a href="#{sections[idx+1]["id"]}">...</a>'
    # handle only-child: if only one link, float it right with max-width 50%
    return f'<div class="section-nav">{prev_link}{next_link}</div>'

# 4. Build sidebar HTML from data
def gen_sidebar(sections, groups):
    links = ''
    for group_name, group_indices in groups:
        links += f'<div class="sb-group"><div class="sb-label">{group_name}</div>'
        for i in group_indices:
            s = sections[i]
            links += f'<a href="#{s["id"]}" class="sb-link" data-section="{s["id"]}">...</a>'
        links += '</div>'
    return links

# 5. Assemble
new_html = assemble(header, hero, sections_content, sidebar,
                    mobile_sidebar, quickjump_js, footer)
write_file('report.html', new_html)
```

**Key advantage:** When restructuring affects 50+ linked locations (every section-nav, both sidebars, quick-jump array, filter tags, stat cards, meta row), a single Python script keeps all references in lockstep. Use `execute_code` (not terminal + sed) so you can call read_file/write_file tools from within the script.

**Content folding pattern** — when consolidating sections (e.g. "Installation" folded into "Simple Stack"), extract valuable payloads and inject them as bullet points, code blocks, or sub-sections within the target. Track what went where:

```python
folding_map = {
    'architecture': {'into': 'intro', 'strategy': 'synthesize_paragraph'},
    'features': {'into': ('simple-stack', 'endgame-stack'), 'strategy': 'split_by_tier'},
    'installation': {'into': 'simple-stack', 'strategy': 'copy_commands'},
    'tools': {'into': ('simple-stack', 'endgame-stack'), 'strategy': 'split_into_tables'},
    'running-strategies': {'into': 'endgame-stack', 'strategy': 'synthesize_table'},
}
```

Strategies:
- `synthesize_paragraph` — extract the key insight, write a single paragraph for the target
- `split_by_tier` — partition content into two buckets based on complexity/cost
- `copy_commands` — the essential command examples belong in the quick-setup section
- `split_into_tables` — feature table gets split: built-in tools -> Simple, MCP/plugins -> End Game
- `synthesize_table` — re-present content as a run-comparison table in the target

#### The stack-guide reframing pattern

When pivoting a flat feature-list document to a **tiered/stack-based** structure (e.g. "Simple Stack vs End Game Stack"), use this pattern:

**Step 1 — Design the decision matrix.** Create a side-by-side comparison table as the new hero/intro pivot. Columns: feature dimension (models, platforms, tools, cost, setup time). Rows: each stack tier.

**Step 2 — Assign every piece of content to a stack.** 
- Installation guides → Simple Stack
- Multi-model routing, gateway, profiles → End Game Stack
- Content that applies to both (runtimes, security) → standalone operational/reference sections
- Architecture diagram → intro section

**Step 3 — Write new stack sections.** Each stack section aggregates content from across the original document. Don't copy-paste — synthesize:
- One-line "Goal" statement
- Stack table (layer × choice × why)
- Quick setup commands
- Costs (specific breakdown table)
- Limitations/trade-offs

**Step 4 — Rewire navigation.** Update in lockstep:
1. Sidebar (desktop) — new link structure with groups
2. Sidebar (mobile) — same structure, with `onclick="toggleSB()"`
3. Section-nav prev/next on every section
4. Quick-jump JS `sections` array
5. Filter tags on each `<section>` element

**Step 5 — Verify structural integrity.** Confirm:
- All section IDs referenced in navigation actually exist
- Every section-nav has both prev and next (or only-child fallback)
- Quick-jump `sections` array length matches visible `<section>` count
- Filter button active classes toggle correctly
- No broken `href="#..."` links

#### When NOT to restructure

Do NOT restructure if:
- The user asked for UX polish (use Phases 1-4)
- The user asked for fact-checking (use `document-verification-update`)
- The document is a 3rd-party file you shouldn't touch (PDF, vendor doc)
- The call is small enough for patches (fewer than ~15 patches to complete)

## 📐 UX patterns reference

Each pattern has a dedicated reference file with full code:

| Reference File | What It Adds |
|----------------|-------------|
| `references/back-to-top.md` | Floating ↑ button, scroll-aware visibility, smooth scroll |
| `references/document-restructure.md` | Stack-guide reframing pattern: decision matrix, dual-track content, full-rewrite criteria |
| `references/scroll-gradient-indicator.md` | CSS `::after` gradient on scroll containers hinting at overflow |
| `references/clipboard-fallback.md` | iOS-safe copy: `navigator.clipboard` → textarea + `execCommand` |
| `references/stagger-entrance.md` | Section fade-in animations on load with staggered delays |
| `references/mobile-touch-targets.md` | Min 44px tap targets at 640px breakpoint |
| `references/progress-bar.md` | Fixed reading progress bar at top of page |
| `references/section-link-copy.md` | Copy section URL to clipboard with visual feedback |
| `references/theme-toggle.md` | Dark/light theme toggle with `localStorage` persistence |
| `references/print-styles.md` | `@media print` styles: hide chrome, force light, avoid breaks |
| `references/css-performance.md` | CSS rendering performance: ban `transition:all`, `content-visibility`, `contain`, `will-change`, scrollbar styling |
| `references/skip-to-content.md` | Visually-hidden "Skip to content" link, visible on keyboard focus |
| `references/no-js-fallback.md` | `.no-js` class + `<noscript>` banner, hide JS-only elements |
| `references/scroll-padding.md` | `scroll-padding-top` offset so fixed headers don't cover anchored sections |
| `references/aria-expanded-sidebar.md` | `aria-expanded` on sidebar toggle button + nav |
| `references/hero-gradient-mesh.md` | Subtle `::before` gradient overlay behind hero section for visual depth |
| `references/responsive-tables.md` | Card-stacking table layout on narrow screens with `data-label` field names |

## ⚠️ Pitfalls

- **Prefer targeted `patch` calls over full file rewrites** — a full `write_file` discards the existing structure, theme system, and user's design decisions. **Exception:** full rewrites ARE appropriate when restructuring involves massive interconnected changes — e.g. renumbering 15→11 sections, rewriting sidebars, section-nav, quick-jump data, filter tags, and hero across 500+ lines, where 50+ individual patches would be slower and more error-prone than one clean document generation. Use the **workflow assessment** in Phase 5 to decide which approach fits.
**Pitfall: `patch` needs unique `old_string`** — always include 1-3 lines of surrounding context. If a patch fails with "Found N matches," add more context lines.

**Pitfall: `patch()` for large CSS blocks in large files can truncate** — when patching a file >100KB, inserting a large CSS block (100+ lines) via `patch()` with `old_string = '</style>'` can replace the entire file content after the match point, effectively truncating everything after `</style>`. Safer: use `execute_code` with a Python script that uses `from hermes_tools import read_file, write_file`:

```python
from hermes_tools import read_file, write_file

f = read_file(path='doc.html', limit=2000)
if f.get('truncated'):
    # File over 2000 lines — use terminal Python via a .py script file
    # (NOT a heredoc — see safe-large-file-editing skill)
    pass
content = f['content']
content = content.replace('</style>', css_block + '\n</style>')
write_file('doc.html', content)
```

**Why not terminal Python heredocs (`python3 -c "..." `)?** On Windows MSYS bash, multi-line heredocs can silently truncate when the Python code contains special characters (`'`, `\`, `$`, `"`), long string literals, or path separators. See `safe-large-file-editing` skill for the full root-cause analysis and Windows-safe workflow.
- **The `</style>` before-first-patch cache warning is harmless** — the tool warns "last read with offset/limit" when you read with pagination. The patch still succeeds. Re-read a section after patching to verify.
- **Don't double-patch** — if you already added a back-to-top button, don't accidentally add another. Check what's in the file first.
- **iOS Safari has quirks** — `navigator.clipboard` only works on HTTPS. `position: sticky` works on iOS 13+. `100vh` includes the address bar. Always include fallbacks for these.
- **Don't add features the user didn't ask for** — if the user says "add a back-to-top button," don't also rewrite their entire CSS system. Targeted scope per request.
- **Color values must work in both themes** — use `var(--bg-surface)` instead of hardcoded `#fff` / `#000`. The doc already has a theme system — extend it, don't duplicate it.
- **Watch for `border` vs `box-shadow` variable mismatch** — `--border-default: 0 0 0 1px rgba(...)` is valid `box-shadow` syntax but invalid as `border` because no `border-style` (e.g. `solid`) is set. Elements using `border: var(--border-default)` render invisibly. When you see a CSS variable named `--border-*` holding a `0 0 0 Npx` value, it was designed for `box-shadow`, not `border`. Either change usage to `box-shadow` or add `solid` to the variable value. Either way, the CSS is buggy and needs fixing — don't copy the pattern.
- **`--stagger-delay` set but never consumed** — if the JS sets `style.setProperty('--stagger-delay', ...)` but the CSS uses `transition: opacity 0.4s ease` (no delay), the var does nothing. The transition MUST include `var(--stagger-delay, 0s)` as its delay parameter for the stagger to work: `transition: opacity 0.4s ease var(--stagger-delay, 0s)`.
- **Code block examples that break when copied** — code blocks displayed as documentation examples (YAML configs, JSON, shell commands) can harbor invisible trailing characters (`|`, `\`, `,`), HTML entity bleed (`&lt;` shown instead of `<`), or escaped sequences (`\n` as literal text). Always spot-check a few lines by mentally tracing what a paste would produce. The user's config file is broken silently — no error message, just a non-functional copy. Add a line to the Phase 1 audit checklist for each code block example in the document.
- **`nth-child` indexes ALL siblings, not just `<section>`s** — if your main container has `.hero`, `.stat-row`, `.quick-start`, `.filter-bar` divs before the `<section>` elements, `section:nth-child(1)` will NOT match the first section. It matches the first child of the parent, which is likely `.hero`. Either (a) wrap sections in a sub-container, (b) use the JS `--stagger-delay` var approach instead, or (c) use `type:nth-of-type(N)` which only counts elements of that tag type.
- **`html{opacity:0}` without `js-ready` = blank page forever** — if the FOUC prevention pattern hides the `<html>` element and the JS never adds the `js-ready` class (e.g. it's inside an async callback that never fires, or the IIFE wraps it incorrectly), the page is invisible with no console error. Always add `document.documentElement.classList.add('js-ready')` as the very first line of your script, before any DOM queries, event listeners, or async work.

## 🔗 Related skills

- `knowledge-consolidation` — merge fragmented files into one comprehensive HTML doc (pre-requisite for this skill)
- `html-application-building` — build polished HTML SPAs from scratch (different workflow, same UX patterns)
- `document-verification-update` — audit doc claims against live system state (complementary to this skill)
- `popular-web-designs` — 54 real design systems for design inspiration
- **`safe-large-file-editing`** — root causes and Windows-safe alternative to patch/heredoc truncation when editing files >50KB. Load this alongside `html-doc-ux` when working with large files.
