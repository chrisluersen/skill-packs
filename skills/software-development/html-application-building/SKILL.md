---
name: html-application-building
title: HTML Application Building
description: Build polished, self-contained HTML single-page applications from research, data, or documentation. Uses a 4-pass iterative refinement model (content → interactivity → polish → quality) to produce production-quality single-file web apps.
triggers:
  - "Turn this into an HTML page/app"
  - "Build a web app from this data"
  - "Make this research into an interactive report"
  - "Iterate and improve this HTML file"
  - "Create a polished single-page app from this information"
---

# HTML Application Building

A disciplined 4-pass iteration model for building self-contained single-file HTML applications (no build tools, no dependencies). Each pass targets a specific dimension, ensuring the final artifact is comprehensive, interactive, polished, and accessible.

## Pass 1: Foundation (Content & Structure)

**Goal:** All content, all sections, responsive dark theme, working layout.

- Write a single `.html` file with inline `<style>` and `<script>`
- Use CSS custom properties (`:root`) for ALL colors — this is mandatory for theme support
- Default to dark theme (Hermes ecosystem default aesthetic), but ALWAYS include a light mode override
- Use system fonts via Google Fonts: `Inter` (sans) + `JetBrains Mono` (code)
- Organize content into clearly named `<section>` elements with `id` attributes
- Each section gets: label number, title, description, then content
- Add Open Graph, Twitter Card, and inline SVG favicon meta tags in `<head>` so the page looks good when shared (see `references/social-meta-tags.md`)
- Add `<link rel="preconnect">` for font performance
- Include `::selection`, `::-webkit-scrollbar` styling
- Add `scroll-behavior: smooth` and `scroll-padding-top` for anchor nav
- Add a `<footer>` with generation info
- Use `.container` class for max-width constrained layouts
- **Multi-column layouts** — two-col and three-col grids for comparison sections, feature tables, and side-by-side content:

```css
.tcol {
  display: grid; grid-template-columns: 1fr 1fr; gap: 12px; margin: 12px 0;
}
@media (max-width: 700px) { .tcol { grid-template-columns: 1fr; } }

.tcol-3 {
  display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 10px; margin: 12px 0;
}
@media (max-width: 700px) { .tcol-3 { grid-template-columns: 1fr; } }

.tcol > div, .tcol-3 > div {
  background: rgba(255,255,255,0.01);
  border: 1px solid var(--border-default);
  border-radius: var(--radius-md); padding: 16px;
}
.tcol > div h4 { font-size: 13px; font-weight: 600; color: var(--fg-primary); margin-bottom: 8px; }
.tcol > div ul { margin: 0 0 0 14px; }
.tcol > div li { font-size: 13px; margin-bottom: 3px; }
.tcol > div p { font-size: 13px; }
```

- **Feature list (arrow-prefixed)** — `→`-prefixed unstyled lists for quick-scan feature lists:

```css
.fl { list-style: none; margin: 0; }
.fl li { padding: 2px 0; font-size: 14px; }
.fl li::before { content: '→'; color: var(--accent-primary); font-weight: bold; margin-right: 8px; }
```

- **Card group titles** — subtitled dividers that group related cards with a visual connector line:

```css
.card-group { margin-bottom: 24px; }
.card-group-title {
  display: flex; align-items: center; gap: 8px;
  padding: 0 4px 12px; font-size: 12px; font-weight: 600;
  color: var(--fg-tertiary); text-transform: uppercase; letter-spacing: 0.6px;
}
.card-group-title::after {
  content: ''; flex: 1; height: 1px; background: var(--border-default);
}
```

## Pass 2: Interactivity (UX Layer)

**Goal:** Tabs, accordions, navigation, responsive breakpoints, animations.

### Components to add in this pass:

...

- **Enhanced code blocks** — macOS-style dot headers (red/yellow/green) with language label on the right, syntax-highlighted tokens (<span class="c-key">, <span class="c-str">, <span class="c-comment">)

### localStorage Safety Pattern

**Always wrap `localStorage` calls in `try/catch`** — they throw in private browsing mode (Safari, Firefox, Edge InPrivate) and break the app silently:

```js
// Read
var saved = null;
try { saved = localStorage.getItem('my-key'); } catch (_) {}

// Write
try { localStorage.setItem('my-key', value); } catch (_) {}
```

This pattern was validated in the AI Architecture.html Phase K refactor — both `getItem` and `setItem` wrapped.
  const SECTION_NUMS = { intro:'00', architecture:'01' };
  window.addEventListener('scroll', () => {
    const sects = document.querySelectorAll('section[id]:not(.filtered-out)');
    let cur = 'intro';
    sects.forEach(s => { if (document.documentElement.scrollTop >= s.offsetTop - 120) cur = s.id; });
    document.getElementById('sectionBadge').textContent = `§${SECTION_NUMS[cur]} · ${SECTION_NAMES[cur]}`;
    });
    ```
    **Performance tip:** wrap the scroll handler in `requestAnimationFrame` to throttle to ~60fps, or use a debounce utility:
    ```js
    function debounce(fn, ms) { let t; return (...a) => { clearTimeout(t); t = setTimeout(() => fn(...a), ms); }; }
    ```
  ```
  CSS: fixed bottom-right or top-right, small font, glass-effect background, appears after scrolling past hero.
- **Reading dock** — fixed bottom bar with three elements: current section label, progress bar, percentage. Alternative/complement to the top scroll bar:
  ```html
  <div id="readingDock" class="visible">
    <span id="rdLabel">§00 · Introduction</span>
    <div class="rd-bar"><div id="rdFill"></div></div>
    <span id="rdPct">0%</span>
  </div>
  ```
  JS updates on scroll alongside the progress bar. CSS: glass background, flex layout, hidden until scrolled past ~500px.
- **Sticky navbar** — blur backdrop, section link highlighting on scroll
- **Table of contents** — desktop sidebar + mobile slide-out panel
  - **Sidebar subsections** — collapsible sub-links under each main TOC entry showing topic keywords. Auto-open for the currently active section on scroll. Use `data-action="toggle-subsections"` instead of inline onclick:
    ```html
    <a href="#architecture" class="sb-link" data-section="architecture">01 Architecture</a>
    <button class="sb-expand" data-action="toggle-subsections" data-parent="architecture">▸</button>
    <div class="sb-sublinks" data-parent="architecture">
      <a href="#architecture" class="sb-sublink">Agent Loop · Profiles · CLI</a>
    </div>
    ```
    ```css
    .sb-sublinks { max-height:0; overflow:hidden; transition:max-height 0.3s ease; }
    .sb-sublinks.open { max-height:300px; }
    ```
    JS: on scroll, toggle `.open` on the `data-parent` matching the current section's id. Also hide sidebar links for filtered-out sections (see tag filter).
- **Section meta bar** — per-section header showing section number, category tag, estimated reading time, and a copy-link button. Placed right inside each `<section>` before the `.card`:
  ```html
  <div class="section-meta">
    <span class="sm-badge">§03</span>
    <span class="sm-tag">Overview</span>
    <span class="sm-reading">⏱ ~2 min</span>
    <a href="#runtimes" class="sm-link" data-action="copy-link" data-section="runtimes" title="Copy link">🔗</a>
  </div>
  ```
  Style as small flex row (`gap:8px`, `font-size:11px`, `color:var(--fg-tertiary)`) with subtle background.
  See the **Event Delegation pattern** below for the click handler that dispatches on `data-action`.
- **Prev/Next section nav** — at the bottom of each section (inside it but after `.card`), provide sequential browsing:
  ```html
  <div class="section-nav">
    <a href="#previous"><span class="sn-label">← Previous</span><span class="sn-title">02 · Features</span></a>
    <a href="#next"><span class="sn-label">Next →</span><span class="sn-title">04 · Modes & Profiles</span></a>
  </div>
  ```
  Style as a two-column flex or grid with thin border on top, subtle hover effect, label in small caps and title in normal weight.
- **Tabs** — horizontal tab bar + tab content panels with fade-in
- **Accordions** — expand/collapse with arrow rotation, close others on open
- **Back-to-top button** — appears after scrolling past hero
- **Code copy buttons** — on hover, copies text content. Show `✓ Copied!` with inline-flex styling and a checkmark character during the feedback period (2s). Use `btn.innerHTML` for the styled feedback so you can include the checkmark glyph inline.
- **Enhanced code blocks** — macOS-style dot headers (red/yellow/green) with language label on the right, syntax-highlighted tokens (<span class="c-key">, <span class="c-str">, <span class="c-comment">)
- **Code block line numbers** — optional `#` toggle button in each code block header. At load time, `injectLineNumbers()` splits each `.cb-body` into `<span class="cb-line" data-line="N">` elements and adds a per-block toggle via `.show-lines` CSS class. See `references/social-meta-tags.md` for the full JS/CSS/HTML pattern and pitfalls.
- **Tag filter system** — JavaScript-powered category filter bar at the top of the page. Each section gets a `data-filter-tag` attribute; clicking a filter button shows/hides matching sections. The filter ALSO hides sidebar links for filtered-out sections. Use `data-action` + event delegation (see pattern below) — NOT global `window` functions:

```html
<button class="filter-btn active" data-action="apply-filter" data-filter-val="all">All</button>
<button class="filter-btn" data-action="apply-filter" data-filter-val="stacks">Stacks</button>
<button class="filter-btn" data-action="apply-filter" data-filter-val="reference">Reference</button>
```

```js
// Inside the IIFE — never window.* globals
function applyFilter(tag) {
  document.querySelectorAll('.filter-btn').forEach(function(b) {
    b.classList.toggle('active', b.dataset.filter === tag);
  });
  document.querySelectorAll('section[data-filter-tag]').forEach(function(s) {
    var match = tag === 'all' || s.dataset.filterTag === tag;
    s.style.display = match ? '' : 'none';
  });
  // Also hide sidebar links for filtered sections
  document.querySelectorAll('.sb-link').forEach(function(l) {
    var targetId = l.getAttribute('href')?.replace('#','');
    if (!targetId) return;
    var target = document.getElementById(targetId);
    l.style.display = (tag !== 'all' && target?.style.display === 'none') ? 'none' : '';
  });
}
```

- **Dynamic filter count badges** — on each filter button, show the count of matching sections. Populate on page load:
  ```js
  window.addEventListener('load', () => {
    document.querySelectorAll('.filter-btn').forEach(b => {
      const tag = b.dataset.filter;
      if (tag === 'all') return;
      const span = b.querySelector('.f-count');
      if (span) span.textContent = document.querySelectorAll(`section[data-filter-tag="${tag}"]`).length;
    });
  });
  ```
  Include a `<span class="f-count">` inside each filter button, styled as a small pill counter. Optionally show a summary text like `Showing ${visible} of ${total} sections`. When showing a subset, include an inline **reset link** next to the count (`(reset)`) that calls `setFilter('all')` so users don't have to hunt for the 'All' button.

- **Quick-jump modal (⌘K)** — keyboard-activated modal with search input. Pre-populated list of all sections. Filter as user types. Arrow-key navigation through results, Enter to jump. Escape to dismiss. Use `data-action` instead of inline `onclick` in generated HTML:

```js
const QJ_SECTIONS = [
  { id: 'intro', label: 'Introduction', cat: 'Overview', num: '00' },
  // ... all sections
];
document.addEventListener('keydown', e => {
  if ((e.metaKey||e.ctrlKey) && e.key === 'k') {
    e.preventDefault(); openQJ();
  }
});

// In renderQJ: generate links with data-action, not onclick
function renderQJ(q) {
  var results = [];
  // Section results — plain href, browser handles nav
  results.push('<a href="#' + s.id + '">§' + s.num + ' ' + highlight(s.title, q) + '</a>');
  // Command/topic results — data-action closes modal
  results.push('<a href="#" data-action="close-qj">' + highlight(c.cmd, q) + '</a>');
  document.getElementById('qjResults').innerHTML = results.join('');
}
```

- **Full-text search tab** — extend the Quick Jump modal with a second tab for full-page content search. Uses `document.createTreeWalker` to build an index of all text nodes, then searches with highlighted matches. **Debounce the search handler (200ms)** to avoid rebuilding the index on every keystroke. Cache the index on first build and clear it when the modal closes (to reflect DOM changes). Limit results to 20.:
  ```js
  function buildFulltextIndex() {
    const walker = document.createTreeWalker(main, NodeFilter.SHOW_TEXT, null, false);
    let node;
    while (node = walker.nextNode()) {
      const text = node.textContent.trim();
      if (text.length > 20) {
        let el = node.parentElement;
        while (el && el !== main && !el.id) el = el.parentElement;
        qjFulltextCache.push({ text, sectionId: el?.id || '' });
      }
    }
  }
  ```
  Two tabs in the modal: "Sections" (filter by name/number) and "Search" (full-text with snippet previews and highlighted matches). Tab buttons in the modal header. Results show a text snippet with the match highlighted, plus a link to the section. Limit to 20 results.
- **Responsive breakpoints** — 768px (tablet), 600px (mobile), 1200px (desktop sidebar)
- **Mobile hamburger menu** — for navbar links. Consider generating the mobile sidebar from JS data instead of hardcoding HTML. Pattern:
  ```js
  function buildMobileSidebar() {
    var nav = document.getElementById('sidebarMobile');
    if (!nav) return;
    var groups = []; /* build from sectionData array, group by category */
    nav.innerHTML = groups.map(...).join('');
    rebuildActiveObserver(); /* re-wire IntersectionObserver for new links */
  }
  ```
  This keeps desktop and mobile nav in sync automatically — adding a section to the data array updates both.
- **Keyboard shortcuts** — Ctrl+K (focus nav), Escape (close panels), F (focus mode)

### JS patterns:

- ALWAYS wrap all JS in an IIFE (`;(function() { 'use strict'; ... })();`) — **zero global functions** on `window.*`
- **Event delegation** — single `document.addEventListener('click', handler)` that dispatches on `data-action` attributes via a switch statement. Never use inline `onclick` attributes:
  ```js
  document.addEventListener('click', function(e) {
    var el = e.target.closest('[data-action]');
    if (!el) return;
    switch (el.getAttribute('data-action')) {
      case 'toggle-sidebar': toggleSidebar(); break;
      case 'toggle-theme': toggleTheme(); break;
      case 'apply-filter': applyFilter(el.getAttribute('data-filter-val')); e.preventDefault(); break;
      case 'close-qj': closeQJ(); e.preventDefault(); break;
      case 'close-ks': closeKS(); e.preventDefault(); break;
      case 'toggle-subsections': toggleSubsections(el.getAttribute('data-parent')); break;
      case 'switch-tab': switchQJTab(el.getAttribute('data-qj')); e.preventDefault(); break;
    }
  });
  ```
  Benefits: one listener for all interactions, no global pollution, trivial to add new handlers at a glance.
- `switchTab(btn, contentId)` for tab handling
- `toggleAccordion(btn)` for accordion (close others, toggle open)
- `copyCode(btn)` with clipboard API + fallback
- `filterTable(input, tableId)` for live table search
- Debounced scroll handler (`debounce(fn, 16)`) or `requestAnimationFrame` throttling
- `debounce(fn, ms)` utility: `function debounce(fn, ms) { let t; return (...a) => { clearTimeout(t); t = setTimeout(() => fn(...a), ms); }; }`
- Clear full-text search caches on modal close to reflect DOM changes between opens

## Pass 3: Polish (Visual Refinement)

**Goal:** Animations, data visualization, tooltips, micro-interactions, information design.

### Enhancements:
- **Scroll-triggered animated counters** — count up from 0 to target on scroll into view
- **Fade-in cards** — IntersectionObserver triggers opacity + translateY transition. Add per-section **stagger delays** so sections animate in sequence as the user scrolls:
  ```js
  // In the IntersectionObserver callback or scroll handler:
  document.querySelectorAll('section[id]:not(.visible)').forEach((s, i) => {
    s.style.setProperty('--stagger-delay', (i * 0.05) + 's');
    s.classList.add('visible');
  });
  ```
  ```css
  /* Fallback for environments without CSS var support */
  section[id] { transition-delay: var(--stagger-delay, 0s); }
  section[id]:nth-child(1) { --stagger-delay: 0s; }
  section[id]:nth-child(2) { --stagger-delay: 0.03s; }
  /* etc. — precalculate for all expected sections */
  ```
  This gives a cascading reveal effect: sections enter one after another rather than all at once.
- **Hover tooltips** — `[data-tip]` attribute that reveals on hover via CSS ::after
- **Interactive SVG diagram** — `viewBox`, `<title>` tooltips on rects, gradient defs, glow filters, arrow markers
- **D3.js force-directed graph** — self-contained interactive graph (search, filter, zoom, drag, tooltips, legend). See `references/d3-force-directed-graph.md` for the full pattern: data generation, inline injection, force simulation tuning, search/filter integration, and pitfall handling.
- **Section index / mini-map** — grid of numbered section links at top. Each link shows a section number (01, 02…) and the section title. 2-4 column grid, responsive:

```css
.section-index {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 8px;
  margin-bottom: 40px;
}
.section-index a {
  display: flex; align-items: center; gap: 10px;
  padding: 12px 14px;
  background: var(--bg-surface);
  border: 1px solid var(--border-default);
  border-radius: var(--radius-md);
  text-decoration: none;
  font-size: 13px; font-weight: 500;
  color: var(--fg-secondary);
  transition: all 0.15s;
}
.section-index a:hover {
  background: var(--bg-hover);
  border-color: var(--border-strong);
  color: var(--fg-primary);
  transform: translateY(-1px);
}
```

- **Stat row / stat cards** — horizontal row of metric cards showing key numbers. Each card has a large value (24px bold) and small label. Use for quick-read analytics at the top of the page:

```html
<div class="stat-row">
  <div class="stat-card"><div class="stat-val">12</div><div class="stat-label">Sections</div></div>
  <div class="stat-card"><div class="stat-val">50+</div><div class="stat-label">Skills</div></div>
</div>
```
```css
.stat-row { display: flex; gap: 12px; flex-wrap: wrap; margin-bottom: 24px; }
.stat-card { flex: 1; min-width: 110px; padding: 14px 18px;
  background: var(--bg-surface); border: 1px solid var(--border-default);
  border-radius: var(--radius-md); text-align: center;
  transition: border-color 0.15s, transform 0.15s; }
.stat-card:hover { border-color: var(--border-strong); transform: translateY(-1px); }
.stat-card .stat-val { font-size: 24px; font-weight: 700; color: var(--fg-primary);
  letter-spacing: -0.5px; }
.stat-card .stat-label { font-size: 11px; color: var(--fg-tertiary); margin-top: 2px; font-weight: 500; }
```

- **Highlight boxes** — accent-left-border styled callouts in four colors: purple (default), green (success), amber (warning), rose (error). Use for pro tips, warnings, and key insights:

```html
<div class="hl-box"><p>Default purple highlight for key info</p></div>
<div class="hl-box green"><p>Green for positive results / tips</p></div>
<div class="hl-box amber"><p>Amber for warnings / caveats</p></div>
<div class="hl-box rose"><p>Rose for errors / breaking changes</p></div>
```
```css
.hl-box {
  background: rgba(108,99,255,0.04);
  border: 1px solid rgba(108,99,255,0.12);
  border-radius: var(--radius-md);
  padding: 16px 20px; margin: 12px 0;
}
.hl-box p { margin-bottom: 0; font-size: 14px; }
.hl-box.green { background: rgba(62,207,142,0.04); border-color: rgba(62,207,142,0.12); }
.hl-box.amber { background: rgba(245,166,35,0.04); border-color: rgba(245,166,35,0.12); }
.hl-box.rose { background: rgba(251,113,133,0.04); border-color: rgba(251,113,133,0.12); }
```
- **Focus mode** — dims all sections except the one being read (keyboard: F)
- **Status bars** — green/yellow dot indicators for system status
- **Philosophy cards** — quote blocks with decorative opening mark
- **Step lists** — numbered vertical timeline with circles
- **Quote blocks** — accent-left-border styled callouts
- **Badge/tag system** — `.tag-green`, `.tag-yellow`, `.tag-red`, `.tag-blue`, `.tag-cyan`
- **Expand/collapse all** buttons for accordion groups
- **Copy section link** — attaches to per-section link buttons (🔗). Use `data-action="copy-link"` + `data-section="id"` on the HTML, then handle via event delegation (no global function needed):

```js
// In the event delegation switch:
document.addEventListener('click', function(e) {
  var el = e.target.closest('[data-action]');
  if (!el) return;
  switch (el.getAttribute('data-action')) {
    case 'copy-link':
      copySectionLink(el.getAttribute('data-section'));
      e.preventDefault();
      break;
  }
});

function copySectionLink(id) {
  var url = window.location.href.split('#')[0] + '#' + id;
  if (navigator.clipboard && navigator.clipboard.writeText) {
    navigator.clipboard.writeText(url).catch(function() { fallbackCopy(url); });
  } else { fallbackCopy(url); }
  showToast('✓ Link copied');
}
```

### SVG diagram best practices:
- `<defs>` for gradients, filters, markers, grid patterns
- Layer labels at section boundaries
- Arrow connectors between layers with `marker-end`
- `role="img"` + descriptive `aria-label` on the SVG
- `<title>` on clickable/hoverable elements for tooltips
- **Responsive sizing** — use `viewBox` (e.g. `viewBox="0 0 780 280"`) with `width:100%;height:auto` on the `<svg>` so it scales with the container. Wrap in a `div` with `overflow:hidden` and `border-radius` for contained layout.
- **Theme-aware fills** — use `fill="var(--bg-card, #111216)"` with CSS variable fallbacks so SVG elements adapt to light/dark mode instead of being hardcoded to one theme.

## Pass 4: Quality & Accessibility (Hardening)

**Goal:** ARIA attributes, performance, code cleanup, print styles, final polish.

### Accessibility:
- Skip-to-content link (visually hidden, shows on focus)
- `role="progressbar"` with `aria-valuenow/valuemin/valuemax` on progress bar
- **`aria-expanded`** on accordion buttons (updated on toggle)
- `aria-selected` on tab buttons (updated on switch)
- `aria-controls` linking accordion buttons to their panels
- `role="tablist"`, `role="tab"`, `role="tabpanel"` on tab system
- Descriptive `aria-label` on SVG diagrams
- `aria-label` on navigation elements
- **`role="progressbar"`** with `aria-valuenow/valuemin/valuemax` on the scroll progress bar, updated live on scroll

### Performance:
- Debounced scroll handler (16ms = ~60fps)
- `{ passive: true }` on scroll/wheel listeners
- `rootMargin` on IntersectionObservers to batch triggers
- Remove redundant DOM queries in hot paths
- **`content-visibility: auto` with adequate `contain-intrinsic-size`** — `contain-intrinsic-size: 500px` is too small for long reference sections; use ≥ 2000px or calculate based on typical section word count × ~1.5px/word. Too-small values cause the browser to truncate rendering and not expand when scrolled into view.

### Code quality:
- Group CSS into labeled sections with comments
- Group JS functions with comments
- Remove debug logging
- Consistent naming conventions
- Version indicator in footer

### Print:
- `@media print` styles — hide navbar, TOC, back-to-top, copy buttons, focus mode
- Force break-inside on cards, code blocks, tables, diagrams
- Reset colors for white background

## Multi-Phase Polish of an Existing HTML File

When the file already exists and you're improving it (not building from scratch), use this **progressive patch model** instead of the 4-pass build model. It avoids the file-truncation pitfall and lets you work safely on large docs.

### ⚠️ Phase 0: Comprehensive Audit + User Alignment (MANDATORY)

**Do NOT start patching until this phase is complete.** This is the most common workflow failure: jumping into improvements without a full picture, then getting redirected when the user sees gaps.

**Steps:**

1. **Read the entire file** in segments (CSS → HTML sections → JS) to understand every component
2. **Audit across ALL dimensions** — use the `references/cross-dimension-quality-audit.md` checklist:
   - Accessibility (ARIA, focus, prefers-reduced-motion, semantic HTML)
   - UX Polish (scroll-padding, modals, keyboard nav, filter UX)
   - Visual (unused CSS, hover effects, theme consistency)
   - Performance (content-visibility, passive listeners, debounced handlers)
   - Semantic HTML (<header>, <nav>, <main>, <footer>, table semantics)
   - JS Behavior (focus trapping, event delegation, IIFE pattern)
   - Content Structure (section numbering, filter tags, nav chains)
3. **Compile a top-N ranked plan** organized by phase — include exact CSS/JS values and `old_string`/`new_string` anchors for each patch
4. **PRESENT the plan to the user for discussion before executing anything**
   - Use a table format showing each workstream, its scope, and effort level
   - Flag which changes are structural (affect content order) vs cosmetic (independent)
   - Ask "does this match what you're looking for? Any changes before I start?"
5. **Accept user input on priorities** — they may want to reorder, skip, or add workstreams

**Why this matters:** Users with strong design taste (UI/UX professionals, quality-conscious developers) will notice gaps you missed and want to redirect you. Presenting the full plan first surfaces those gaps *before* you've burned time on patches that need undoing. It also gives the user agency — they're directing the work, not just watching it happen.

**Mid-batch discovery pitfall:** If the user says "yes go ahead" but you notice additional improvement opportunities WHILE patching, do NOT stop mid-stream to flag them. Note them in your todo list, finish the current batch, then after the batch say "I noticed X more items while working — want me to add those?" Bringing up new items mid-batch derails focus and forces the user to context-switch.

### Phase ordering strategy

Apply phases in this order so anchors don't shift under later patches:

| Order | Layer | What | Why |
|-------|-------|------|-----|
| 1 | CSS vars | Typography, color tokens, border system | Foundation — everything CSS depends on these |
| 2 | Structural CSS | Background `rgba`, border, hero glow, z-index | Visual foundation |
| 3 | Layout CSS | Section spacing, card rules, grids, breakpoints | Building-block styles |
| 4 | Light/dark mode | Opposite theme palette, infra backgrounds | Needs all style vars defined |
| 5 | Visual quick wins | Progress bar height, stat hover, stagger timing, glow dot | Independent refinements |
| 6 | HTML changes | Modals, nav, buttons, aria attributes | Structural — do after CSS |
| 7 | JS changes | Theme toggle, sidebar aria-expanded, keyboard, toast | Last — operates on elements from step 6 |
| 8 | A11y + cleanup | focus-visible, prefers-reduced-motion, CSS var audit, print | Independent final pass |

The golden rule: **never patch content above a future anchor**. CSS vars (top of file) are safe at any time. HTML in the middle moves anchors below it — batch those together.

### Workflow: search_files + read_file + patch

Do NOT read the whole file. Find anchors surgically:
1. `search_files(target="content", path="doc.html", pattern="--border-default:")` — find the line
2. `read_file(path="doc.html", offset=N, limit=3)` — confirm surrounding context
3. `patch(path="doc.html", old_string="...", new_string="...")` — replace with enough surrounding lines for uniqueness

### Phase tracking

Use `todo` with status markers for multi-phase plans. The list survives context compaction so you resume cleanly after interruptions or tool-call limits.

### Pitfalls

- **Budget batching** — 8+ single-tool patches eat the turn limit fast. Batch many patches in a single `execute_code` call.
- **Anchor drift** — every `patch` shifts line numbers. Re-find with `search_files`, don't trust remembered offsets.
- **Stale reads** — re-read after nearby patches; offset/limit reads don't auto-update.
- **Parallel safety** — different file sections (CSS line 20 + CSS line 200) can patch in parallel. Same-section patches must be sequential.
- **CSS var audit last** — after all changes, search for hardcoded hex/rgba values that should be variables.

## Theming: Light/Dark Mode

A dark-default HTML file must also work in light mode. CSS custom properties make this trivial — never hardcode theme-specific colors.

### Do this from Pass 1

Structure your `:root` as a dark theme, then add a `@media (prefers-color-scheme: light)` override block right below it:

```css
:root {
  --bg-primary: #06060f;
  --bg-card: #0f0f24;
  --text-primary: #e8e8f0;
  --accent: #6366f1;
  /* ... all other colors ... */

  /* Infra backgrounds — set EXPLICITLY per theme, don't derive from bg-primary */
  --navbar-bg: rgba(6,6,15,0.85);
  --overlay-bg: rgba(0,0,0,0.6);
  --diagram-fill: rgba(6,6,15,0.3);
}

@media (prefers-color-scheme: light) {
:root {
  --bg-primary: #f5f6fa;
  --bg-card: #ffffff;
  --text-primary: #1a1a2e;
  /* accent can stay the same — indigo/purple works in both modes */

  --navbar-bg: rgba(245,246,250,0.92);
  --overlay-bg: rgba(0,0,0,0.3);
  --diagram-fill: rgba(0,0,0,0.05);
}
}
```

### Rules

1. **Every color goes through a CSS variable** — never inline a hex or rgba. Every `background:`, `color:`, `border-color:`, `fill:`, `stroke:` must reference a `--var`.
2. **Separate infra backgrounds from theme backgrounds** — navbar, sidebar, overlay, diagram-fill need EXPLICIT values in both modes because they blend against different bases. Don't reference `--bg-primary` with an opacity — light mode bg-primary is nearly white, so `rgba(var(--bg-primary), 0.85)` would be invisible.
3. **Test both modes** — open the file in a browser, toggle system theme, confirm everything reads well.
4. **`::selection`** needs `color: #fff` in both modes (light text on accent bg reads fine).
5. **Shadows** need to be much softer in light mode (`rgba(0,0,0,0.06)` vs `rgba(0,0,0,0.4)`).
6. **Gradient hero** — light mode may need deeper cyan/blue ends for contrast against a white hero section.

### What NOT to do

❌ *Don't use `!important` hacks* — early versions of this pattern used them, but CSS variable overrides work cleanly.

❌ *Don't use only JavaScript theme detection* — `prefers-color-scheme` auto-detects the OS setting. Use a hybrid approach: start with the media query, then allow a JS toggle button to override it (see Pass 2 for implementation). See the "JS Toggle" section below for the pattern.

❌ *Don't leave hardcoded dark-mode rgba values* — every `rgba(6,6,15,…)` or `rgba(0,0,0,…)` that isn't a CSS variable becomes invisible in light mode.

## Fusion Design: Combining Multiple Design Systems

This pattern emerged from the need to build a single page whose visual identity draws from *multiple* design systems simultaneously — taking the best of each for different dimensions of the design.

### When to use this

The user says "make it look like these references" or has described a visual identity that doesn't match any single design system. You load 2-4 templates from `popular-web-designs` and synthesize them into one cohesive page.

### The Multi-Source Allocation Pattern

Pick **one source per dimension** — don't mix strokes from Linear with borders from Supabase within the same component:

| Dimension | Pick From |
|-----------|-----------|
| **Background & surface** (page bg, card bg, elevation) | One primary design system |
| **Border system** (colors, widths, radiuses) | Another system with distinctive border language |
| **Typography & spacing** (font, leading, letter-spacing) | The system best aligned with your content density |
| **Accent color** (brand color, call-to-action) | A third system whose accent defines the visual identity |
| **Layout pattern** (sidebar doc, centered reading, dashboard) | The system whose information architecture fits |

### Real Example: Hermes Agent Stack Reference

This session produced a 98KB, 2,068-line HTML document fusing four design systems:

```
┌──────────────────────────────────────────────────────────────┐
│ Dimension          │ Source           │ Contributed           │
│──────────────────────────────────────────────────────────────│
│ Background/theme   │ Supabase (dark)  │ #070708 page bg,      │
│                    │                  │ #0e0e10 card surfaces  │
│ Border precision   │ Linear           │ rgba(255,255,255,0.06)│
│                    │                  │ ultra-thin borders    │
│ Card/layout        │ Mintlify         │ Reading-optimized     │
│                    │                  │ card padding, groups  │
│ Accent             │ Stripe           │ #6c63ff purple glow   │
└──────────────────────────────────────────────────────────────┘
```

### Implementation in CSS

```css
/* ===== FUSION DESIGN TOKENS ===== */
:root {
  /* Primary: Supabase dark-native */
  --bg-page: #070708;
  --bg-surface: #0e0e10;
  --bg-elevated: #151517;

  /* Precision: Linear thin borders */
  --border-default: rgba(255,255,255,0.06);
  --border-strong: rgba(255,255,255,0.10);

  /* Layout: Mintlify reading-optimized */
  --sidebar-w: 270px;
  --max-content: 900px;

  /* Accent: Stripe purple */
  --accent-primary: #6c63ff;
  --accent-primary-hover: #7f77ff;
}
```

### Rules for Fusion

1. **One dimension, one source** — the background system doesn't also define the accent.
2. **Load all source templates** — `skill_view("popular-web-designs", "templates/<site>.md")` for each, extract the CSS values you need.
3. **Accent color is the one that defines the page's identity** — everything else is infrastructure.
4. **Test the fusion visually** — open in a browser and verify the mix doesn't clash.
5. **Document which source contributed what** in the CSS header, so the user can swap any dimension later.
6. **When one dimension has no strong source** (e.g. you didn't pick a spacing system), fall back to the primary background source's values. Don't introduce a 5th source for a minor dimension.

### Related: Why NOT to use a single template

A single design system template (`linear.app.md`, `stripe.md`) gives you a coherent visual identity but usually targets one page type (marketing, docs, dashboard). When your page needs to be a reference document *and* look like a developer tool *and* feel premium, no single template covers all three. Fusion is the right tool for compound-use artifacts.

## Hybrid Theme Toggle: prefers-color-scheme + JS Override

The skill's default approach uses `@media (prefers-color-scheme: light)` which auto-detects the OS setting. For user-facing pages where someone might want to toggle without changing their OS setting, add a **JavaScript-controlled toggle button** that overrides the media query.

### Pattern: CSS variable swap on button click

```js
let darkMode = true;
function toggleTheme() {
  darkMode = !darkMode;
  const r = document.documentElement.style;
  if (darkMode) {
    r.setProperty('--bg-page', '#070708');
    r.setProperty('--bg-surface', '#0e0e10');
    r.setProperty('--fg-primary', '#ededef');
    r.setProperty('--fg-secondary', '#a1a1ab');
    r.setProperty('--navbar-bg', 'rgba(14,14,16,0.85)');
    r.setProperty('--overlay-bg', 'rgba(0,0,0,0.6)');
    document.getElementById('themeToggle').textContent = '☀️';
  } else {
    r.setProperty('--bg-page', '#f9f9fb');
    r.setProperty('--bg-surface', '#ffffff');
    r.setProperty('--fg-primary', '#111113');
    r.setProperty('--fg-secondary', '#52525b');
    r.setProperty('--navbar-bg', 'rgba(255,255,255,0.9)');
    r.setProperty('--overlay-bg', 'rgba(0,0,0,0.3)');
    document.getElementById('themeToggle').textContent = '🌙';
  }
}
```

### Key rules for JS-toggle:

1. **Start with `prefers-color-scheme` as the initial state** — the page matches the OS on load
2. **The JS toggle then overrides via `element.style.setProperty()`** — this has higher priority than media queries
3. **Store the preference in `localStorage`** so it survives page reloads:
   ```js
   localStorage.setItem('theme', darkMode ? 'dark' : 'light');
   ```
4. **On page load, check localStorage first**, then fall back to prefers-color-scheme:
   ```js
   const saved = localStorage.getItem('theme');
   if (saved === 'light') { applyLight(); }
   ```
5. **Include ALL infra CSS variables in the toggle** — navbar bg, overlay bg, diagram fills, code bg. Missing one creates a "blind spot" that breaks in the toggled mode.
6. **The toggle button itself** should show the *opposite* icon: ☀️ when in dark mode (click to get sun/light), 🌙 when in light mode.

### What NOT to do with JS-toggle:

- ❌ Don't add/remove a class on `<body>` and rely on CSS overrides — class+media-query interaction is fragile. Inline style on `:root` always wins and is simpler.
- ❌ Don't use a `<link rel="stylesheet">` swap — loading a second stylesheet creates a flash of wrong-themed content.
- ❌ Don't forget that `prefers-color-scheme` in a media query still applies — the JS inline style overrides individual properties but the media query block for other properties still runs. This is correct behavior but can surprise you if you're not expecting it.

## Hierarchical Tree + Card Layouts from JSON Data

When given JSON data representing a multi-level hierarchy (groups → subgroups → agents), build a **collapsible tree of cards** rather than a flat table. The user will correct you if you start flat — start deep.

### The pattern in one sentence

```
Root Canopy (Level 1, collapsible, prominent)
  ├─ Root-level agents as cards
  ├─ Child Branch (Level 2, collapsible, indented)
  │   ├─ Agent Card
  │   ├─ Agent Card
  │   └─ Agent Card
  ├─ Child Branch
  │   ├─ Agent Card
  │   └─ Agent Card
  └─ ...
```

### Key design rules

1. **Never assume all groups are siblings.** When the data has multiple groups, always ask or infer which group is the root/parent. Groups like "Leadership & Routing", "Supervision", "Management" are usually canopy-level. Everything else nests under them. If you build a flat tree of peers, the user will say "they're all the same level still."

2. **Three visual depths minimum.** A tree with only 2 levels (group → cards) reads as flat. Add Level 3 via nested subgroups or clear depth cues (branch lines, indentation, junction dots, per-level color accents).

3. **Tree connectors are mandatory visual language.** Each card must have:
   - A vertical spine line behind the list (gradient or solid)
   - A horizontal branch line from spine to each card (`::before`)
   - A junction dot at the intersection (`::after`)
   - The dot should glow on hover (transition to accent color)

4. **Independent collapsibility at every depth.** The root canopy, each branch, and each card's detail panel should be independently collapsible. Root collapsing hides ALL children. Branch collapsing hides just that branch's agents. Card expanding shows the agent detail.

5. **Staggered entrance animations.** Animate nodes in with `nth-child` or JS delay keys — root first, branches second, cards last. ~40-60ms stagger per sibling level.

### CSS structure for depth cues

```css
/* Branch container — vertical spine */
.branch-container { position: relative; margin-left: 32px; }
.branch-container::before {
  content: ''; position: absolute; left: 0; top: 0; bottom: 0;
  width: 2px; background: linear-gradient(180deg, var(--border) 0%, transparent 100%);
}

/* Agent card — horizontal branch line */
.agent-card::before {
  content: ''; position: absolute; left: -28px; top: 18px;
  width: 24px; height: 2px; background: var(--border);
}
.agent-card::after {
  content: ''; position: absolute; left: -30px; top: 16px;
  width: 6px; height: 6px; border-radius: 50%; background: var(--border);
  border: 2px solid var(--bg-card); z-index: 1;
  transition: all 0.2s ease;
}
.agent-card:hover::after { background: var(--accent); border-color: var(--accent); }
```

### Animation pattern for staggered tree entry

```js
// Stagger delays for each level
.root-node  { animation-delay: 0s; }
.branch-node { animation-delay: (idx * 0.06) + 's'; }
.agent-card  { animation-delay: (idx * 0.04) + 's'; }
.agent-card.hidden { display: none; } // for search/filter
```

### Detail expansion: grow parent containers

When a card's detail panel opens, the parent `.agent-list` and `.branch-list` max-height values need to stretch:

```js
function toggleDetail(icon) {
  const d = icon.closest('.agent-card').querySelector('.card-detail');
  const open = d.classList.toggle('open');
  icon.textContent = open ? '▾' : '▸';
  [d.closest('.agent-list'), d.closest('.branch-list')].forEach(el => {
    if (el && el.style.maxHeight && el.style.maxHeight !== '0px') {
      el.style.maxHeight = (el.scrollHeight + 280) + 'px';
    }
  });
}
```

### For the root/canopy node

The root node should be visually distinct from branch nodes — use gradient backgrounds, colored tint, or elevated shadow to signal it governs everything below:

```css
.root-header {
  background: linear-gradient(135deg, #1c1440 0%, var(--bg-card) 100%);
  border-color: #2a1f5c;
  box-shadow: 0 0 30px rgba(124,92,252,.12), 0 2px 16px rgba(0,0,0,.25);
}
```

### See also

- `references/tree-layout-from-json.md` — full worked example with the asteroid fleet JSON-to-HTML iteration, including the table→tree→nested correction sequence

## Pitfalls

- **When starting a tree from JSON, ask about hierarchy depth.** Groups at the same level are a red flag — ask "is any of these a parent of the others?" before building. Building flat peer groups and getting corrected wastes a round-trip.
- **"Don't make it so flat"** = user wants 3+ visual depth levels. Add branch lines, junction dots, color accents, and distinct visual treatment per depth level (root ≠ branch ≠ card).
- **NEVER feed a paginated `read_file` result into `write_file`** — `read_file` returns only the first 500 lines by default (offset=1, limit=500). **This applies to BOTH the direct `read_file` tool AND `from hermes_tools import read_file` inside `execute_code`** — both default to the same limit. Calling `write_file` with that truncated content OVERWRITES the entire file, silently dropping the remaining ~80% of your document. Always check `total_lines` vs actual content length before overwriting.
  - **Safe pattern in `execute_code`:** `read_file(path, offset=1, limit=0)` — passing `limit=0` returns the full file without pagination, as does omitting offset/limit entirely when combined with an explicit `limit=0`.
  - **Safest pattern for large files:** use surgical `patch()` calls instead of read-rewrite cycles. Patch operations never truncate.
  - **If you MUST rewrite the full file**, read it in segments and concatenate via terminal (see `references/large-file-recovery.md`).
- **`write_file` in `execute_code` is a single-shot overwrite** — unlike the direct `write_file` tool, there is no safety check. The content you pass IS the new file. Verify your content is complete before writing.
- **Section renumbering is a multi-target operation** — inserting a section between existing ones means updating: (a) the new section's badge/number, (b) every subsequent section's badge/number, (c) every subsequent section's `data-section` attribute if present, (d) sidebar links (desktop + mobile) with their numbers, (e) sidebar link `data-section` attributes, (f) all section-nav prev/next link titles and numbers for affected sections, and (g) the Quick Jump JS section array. Make a checklist or use a script — missing any one creates a broken link or duplicate number.
- **For large-file appends, use `cat >>` via terminal, not `write_file`** — writing a multi-part file and concatenating with `cat part2.html >> main.html` avoids `write_file`'s single-shot limit and won't accidentally truncate preserved content. Documented in `references/large-file-recovery.md`.
- **Don't use external dependencies** — no React, no Bootstrap, no npm. Everything must be self-contained in the single HTML file.
- **Don't skip the print stylesheet** — users will try to print to PDF.
- **Don't hardcode data that came from research** — if data came from web extracts or vault files, tag it as sourced.
- **Don't leave passive listener off scroll handlers** — this causes jank on long pages.
- **Don't forget `aria-expanded` sync** — when toggling accordion with JS, always update the attribute alongside the class.
- **CSS var naming convention for color tokens** — use a tiered naming system that conveys hierarchy, not visual appearance:
  - `--fg-primary` / `--fg-secondary` / `--fg-tertiary` / `--fg-muted` (text colors, descending importance)
  - `--bg-primary` / `--bg-secondary` / `--bg-surface` / `--bg-elevated` (backgrounds, descending depth)
  - `--border-default` / `--border-strong` (border weight, not color name)
  - `--accent-primary` (brand color)
  - `[data-theme="light"]` always mirrors `:root`'s structure exactly — same variable names, different hex values. A missing variable in one theme block creates invisible UI in toggled mode. Verify with grep after any addition.
- **Screen reader announcements** — dynamic content changes (toast, filter results, theme switches) need explicit ARIA to be announced:
  - Toast: give the element `role="status"` (appended via `setAttribute`) — this triggers an implicit live region announcement
  - Filter/sort summary: `aria-live="polite"` on the container so count changes are read after the user finishes typing/clicking
  - Theme toggle button: `aria-label` that updates dynamically in JS alongside the icon — "Switch to light theme" / "Switch to dark theme"
  - Do NOT use `aria-live="assertive"` for routine updates — it interrupts the user mid-task. Reserve for errors and critical warnings.
- **SVG overflow** — wrap SVG in a container with `overflow-x: auto` to prevent breaking on small screens.
- **Table overflow** — wrap `<table>` in `.table-wrap` with `overflow-x: auto`.
- **Tab content wrapping** — each tab content div needs unique `id` matching the tab button.
- **Don't put text in the hero as an H1 sibling** — wrap in a `<span>` or `<p>`.
- **Counter animation edge cases** — if target is 0, skip the interval entirely.
- **Copy button visibility** — only show on hover within `.code-block`; always appear on focus for keyboard users.
- **Sticky table headers** — wrap `<table>` in a `<div class="table-wrap" style="overflow-x:auto;">` and make `<th>` sticky: `th { position: sticky; top: 0; z-index: 1; }`. This keeps column headers visible while scrolling through long tables.
- **SVG responsiveness** — a bare `<svg>` without `viewBox` won't scale. Always include `viewBox="x y w h"` and set `width:100%;height:auto` via CSS. Wrap in a container with `overflow:hidden` to prevent layout overflow on narrow viewports.
- **Copy code feedback** — after a successful copy, show `✓ Copied!` briefly (2s), not plain "Copied!" Use `btn.innerHTML` with a styled `<span>` so the checkmark renders as a glyph rather than text that might overlap other inline elements. Revert to "Copy" after the timeout.
- **Staggered entrance animation lag** — on long pages with many sections, setting stagger delays on page load via nth-child creates a visible cascading effect, but if the page loads with all content above the fold, the delays cause unnecessary waiting. Use IntersectionObserver to add `visible` class dynamically and set `--stagger-delay` via JS per-entry, so delays only apply when sections scroll into view (not on initial render). Provide nth-child fallbacks for no-JS environments.
- **CSS+JS entrance animation out of sync (blank page symptom)** — the most dangerous pitfall in entrance animations: adding `section { opacity: 0; }` to the CSS without ALSO adding the JS that makes sections visible (`.section-visible { opacity: 1; }` + IntersectionObserver) causes ALL sections to render invisible on page load. This must be caught at the code-review stage, not in testing. **The CSS and JS for entrance animations MUST be shipped in the same phase** — never add the opacity:0 CSS in one batch and the JS activation in a later batch. During a multi-phase polish, if you add section entrance CSS but the corresponding JS is scheduled for a later phase, the page is broken between deployments. Correct pattern for the JS (using a monotonic counter for true stagger ordering and unobserve to prevent re-triggers):
  ```js
  var _sectionObserved = 0;
  var _sectionObs = new IntersectionObserver(function(entries) {
      entries.forEach(function(entry) {
          if (entry.isIntersecting) {
              var sec = entry.target;
              if (sec.classList.contains('section-visible')) return;
              sec.style.setProperty('--stagger-delay', (_sectionObserved * 0.06) + 's');
              sec.classList.add('section-visible');
              _sectionObserved++;
              _sectionObs.unobserve(sec);
          }
      });
  }, { rootMargin: '0px 0px -60px 0px' });
  document.querySelectorAll('section').forEach(function(sec) {
      _sectionObs.observe(sec);
  });
  ```
- **First-N-immediate pattern** — when using IntersectionObserver for section entrance, reveal the first 1-2 sections immediately on page load so the user never sees a blank or blankish above-the-fold area. Run this right after setting up the observer:
  ```js
  var _firstSections = document.querySelectorAll('section');
  for (var si = 0; si < 2 && si < _firstSections.length; si++) {
      _firstSections[si].style.setProperty('--stagger-delay', (si * 0.06) + 's');
      _firstSections[si].classList.add('section-visible');
      _sectionObs.unobserve(_firstSections[si]);
      _sectionObserved++;
  }
  ```
  Adjust the count (2) based on how many sections are visible above the fold on a typical screen.
- **Don't hardcode theme-dependent rgba values** — every `rgba(6,6,15,…)`, `rgba(0,0,0,…)`, or opaque hex that represents a background/infra layer MUST be a CSS variable with both dark and light values. Hardcoded values become invisible in the wrong mode.
- **Don't forget to light-mode test inline SVG fills/strokes** — diagrams often have hardcoded `fill="rgba(6,6,15,0.3)"` or `stroke="#5e5e7e"` that render fine in dark mode but wash out or vanish on a light background. Add a `--diagram-fill` / `--diagram-stroke` variable.
- **Don't use `gradient-section` computed from `--bg-secondary` → `--bg-primary` without testing** — it auto-adapts via var() references, but may look too subtle in light mode. Add an explicit light-mode override if it fades to nothing.
- **Don't build a tag filter without wiring the JavaScript** — filter buttons that look clickable but don't filter anything is a broken UX. The filter must ALSO update sidebar links for filtered-out sections, or you get a sidebar with dead links pointing to invisible content.
- **Don't forget scroll-padding for the header** — if the page has a fixed header/navbar, anchor links (`#section`) scroll content behind it. Add `scroll-padding-top: calc(var(--header-h, 56px) + 20px)` on `html` to offset automatically.
- **Cross-theme CSS variable sync** — when you add a new CSS variable to the `:root` (dark) block, you MUST add it to EVERY `[data-theme="..."]` block immediately — before writing any consuming CSS rules. Variables missing from the opposite theme evaluate to `undefined`, causing invisible hover states, transparent borders, and broken backgrounds. Verification command after adding any variable: `grep -c "--my-var"` across each theme block or visually inspect both modes in a browser. This is the #1 source of light-mode regressions from dark-first patches.
- **Debounce input handlers, not just scroll** — Quick Jump search input, full-text search, and live filter fields should have a 150-300ms debounce on their `input` event. Without it, every keystroke triggers a re-render on large result sets. Pattern:
  ```js
  var searchTimer = null;
  input.addEventListener('input', function() {
    var val = this.value;
    clearTimeout(searchTimer);
    searchTimer = setTimeout(function() { renderResults(val); }, 200);
  });
  ```
- **Don't use a single design system template when the artifact has multiple personality types** — a reference document that's also a landing page *and* a developer tool needs fusion, not a single template.
- **Don't hardcode filter categories in JS without adding data attributes to HTML** — the `data-filter-tag` attribute on each `<section>` is what makes JS-driven filtering possible. If sections don't have it, the filter function finds nothing to hide.
- **Don't leave code blocks unstyled** — plain `<pre>` tags render as monospaced blocks with no visual container. Wrap them in a bordered, background-colored `.code-block` with a header bar for visual hierarchy.
- **Don't use inline `onclick` in HTML** — every `onclick="..."` creates a global function requirement (`window.fn = ...`) and bypasses event delegation. Use `data-action` attributes instead. From the event delegation handler, dispatch to local functions inside the IIFE. This keeps the namespace clean and makes all interactions discoverable in one place.
- **Don't expose functions on `window.*`** — all functions should be local to the IIFE. If you need event delegation to call them, the switch statement handles that. If you're tempted to assign `window.myHandler = function...`, you've missed the delegation pattern.
- **Don't use inline `onclick` in HTML** — every `onclick="..."` creates a global function requirement (`window.fn = ...`) and bypasses event delegation. Use `data-action` attributes instead. From the event delegation handler, dispatch to local functions inside the IIFE. This keeps the namespace clean and makes all interactions discoverable in one place.
- **Don't put the quick-jump keyboard shortcut on a scarce key** — Ctrl+K works because it's unbound in browsers. Don't use single-key shortcuts (K, S, /) that conflict with browser default behavior or text input.

## References

- `references/social-meta-tags.md` — Open Graph, Twitter Card, inline SVG favicon, and code block line numbers: adding social preview support and optional line numbering to self-contained HTML docs
- `references/large-file-recovery.md` — catastrophic file corruption and recovery pattern: what happens when a paginated read_file gets fed into write_file, and how to recover using terminal concatenation
- `references/iteration-example.md` — real session transcript showing the 4-pass model applied to a Hermes ecosystem report (11 vault files, 20+ GitHub projects → 97KB polished HTML)
- `references/accessibility-wcag-aa.md` — systematic WCAG AA audit and remediation for existing HTML docs: color contrast (Python toolkit, common failing patterns, fix strategy), focus order, screen reader announcements, color-scheme meta tag, prefers-reduced-motion block with entrance animation cleanup
- `references/theming-light-dark.md` — step-by-step conversion guide from dark-only to full light/dark theme support, with real-world color table and audit commands
- `references/warm-light-mode-palette.md` — Notion-inspired warm neutral light mode palette (cream backgrounds, tan borders, warm brown text). Alternative to the cool blue `#f8f9fc` default.
- `references/fusion-design-session.md` — session transcript showing multi-source fusion of 4 design systems (Supabase + Linear + Mintlify + Stripe) into a 98KB reference doc, plus key UX decisions and iteration corrections
- `references/onclick-to-event-delegation.md` — migrating an existing HTML page from inline `onclick`/global functions to event delegation via `data-action`. Step-by-step replacement table, generated-HTML conversion, debounce patterns, and verification checklist. Companion to the **JS Patterns** section.
- `references/cross-dimension-quality-audit.md` — extends the design audit with 6 additional quality dimensions (accessibility, UX polish, performance, semantic HTML, JS behavior, content structure). Use after the design audit when the user asks for comprehensive review: 7-dimension checklist, prioritization framework, and top-N ranking format from real sessions.
- `references/patch-verification-checklist.md` — systematic 4-step verification loop (read → cross-reference → search → patch) to catch missing theme variables, HTML accessibility attributes, skipped plan items, and JS gaps after a batch of patches is applied. Essential companion to the Multi-Phase Polish workflow.
- `references/phase-gated-refactoring.md` — phase-gated progressive refactoring workflow for large existing HTML docs — audit, plan, present, execute, verify. Prevents scope creep and anchor drift.
- `references/decision-framework-tables.md` — documentation pattern for technology choice tables with decision frameworks: use/don't-use scenarios, upgrade triggers, cost control, and decision guide tables. Emerged from AI Architecture.html Phase L stack documentation.