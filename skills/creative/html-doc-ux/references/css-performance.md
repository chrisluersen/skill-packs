# CSS Performance Optimizations for Static HTML Docs

## Transition Specificity — Banning `transition: all`

`transition: all` forces the browser to watch every animatable property on the element for changes. On large documents with many interactive elements, this adds unnecessary style-recalc work on every frame.

### Diagnosis

```bash
grep -n 'transition: all' doc.html
```

### Fix pattern

For each match, determine which properties actually change on `:hover`, `.active`, or `.open`, and list only those:

| Element | `:hover`/`.active` changes | Replacement |
|---------|---------------------------|-------------|
| `.header-btn` | `background`, `border-color`, `color` | `transition: background .15s, border-color .15s, color .15s` |
| `.sb-link` | `background`, `color` (hover); `border-left-color` (active) | `transition: background .12s, color .12s, border-left-color .12s` |
| `.ql a` | `border-color`, `color` | `transition: border-color .15s, color .15s` |
| `.filter-btn` | `border-color` (hover); `background`, `color` (active) | `transition: border-color .15s, color .15s, background .15s` |
| `.cb-copy` | `background`, `color` | `transition: background .12s, color .12s` |
| `.section-nav a` | `border-color` | `transition: border-color .15s` |
| `.qj-modal` | `opacity`, `transform` (.open) | `transition: opacity .15s, transform .15s` |
| `.toast` | `opacity`, `transform` (.show) | `transition: opacity .25s, transform .25s` |

**Workflow:** read each rule's context (hover/active/open states), extract the changing properties, then `patch()` each `transition: all` with the specific list.

**Do not replace `transition: all` with an even longer list of properties than actually change.** Only list properties that the element's hover/active/toggle states modify. Adding more creates the same perf issue with extra bytes.

---

## Content-Visibility: Auto on Sections

For long documents with many `<section>` elements, `content-visibility: auto` defers rendering of offscreen sections until they scroll near the viewport. This can cut initial paint cost by 60-80% on large docs.

```css
section {
    content-visibility: auto;
    contain-intrinsic-size: 500px;
}
```

`contain-intrinsic-size` reserves approximate vertical space so scrollbar height is correct while offscreen sections aren't rendered. Adjust the value to roughly match the average section height.

**Caveats:**
- Section contents (e.g. anchor links with `#section-id`) still work because the browser reserves space via `contain-intrinsic-size` and renders on demand as the user scrolls.
- Sections that are visibly adjacent to the viewport get rendered eagerly — `auto` means "render when near," not "never render."
- Sections using `IntersectionObserver` for active-link tracking still fire correctly because the browser renders the element before firing the observer.
- If sections use entrance animations (`opacity: 0; transform: translateY(...)`), the animation plays when the section first renders, not on page load. This is usually fine — the animation is what draws attention to newly-rendered content.

---

## Contain on Cards

`contain: content` (equivalent to `contain: layout paint style`) isolates each card's rendering from the rest of the page layout. The browser doesn't need to recalculate sibling positions when a card changes.

```css
.card {
    contain: content;
}
```

`contain: content` does NOT include `size` containment, so cards can still grow/shrink based on their content without requiring explicit dimensions.

**Apply to:** `.card`, `.stat-card`, `.hl-box`, and any other relatively-positioned block element that doesn't participate in layout calculations with siblings.

---

## Will-Change Hints

`will-change` tells the browser to promote an element to its own compositor layer before the animation starts, avoiding paint-on-animation-start jank.

```css
section {
    will-change: transform, opacity;
}
```

**Best for:** Elements that animate on page load (entrance animations, stagger fades). The `will-change` hint is set in the CSS and consumed on first paint — the browser prepares the layer before the first animation frame.

**Do NOT use on:** Hover-only effects (`.header-btn:hover`, `.sb-link:hover`). The hint would remain active for the element's entire lifetime, burning GPU memory for no benefit after the first interaction. For hover effects, `transition` with specific properties is sufficient.

**Do NOT use will-change with `content-visibility: auto`** unless you've verified both work together. In testing, the combination is safe: `content-visibility: auto` defers the element (and its `will-change` budget) until it scrolls near the viewport.

---

## Custom Scrollbar Styling

Custom scrollbars make a documentation site feel polished. Target WebKit-based browsers (Chrome, Edge, Brave, Opera, Safari):

```css
/* Dark theme (default) */
::-webkit-scrollbar { width: 8px; height: 8px; }
::-webkit-scrollbar-track { background: var(--bg-primary); }
::-webkit-scrollbar-thumb { background: var(--border-default); border-radius: 4px; }
::-webkit-scrollbar-thumb:hover { background: var(--fg-tertiary); }

/* Light theme override */
@media (prefers-color-scheme: light) {
    ::-webkit-scrollbar-track { background: #f5f5f5; }
    ::-webkit-scrollbar-thumb { background: #ccc; }
    ::-webkit-scrollbar-thumb:hover { background: #999; }
}
```

**Firefox/legacy fallback:** Firefox uses `scrollbar-width` and `scrollbar-color`:

```css
/* Optional Firefox fallback */
html { scrollbar-width: thin; scrollbar-color: var(--border-default) var(--bg-primary); }
```

**Theme variable approach versus hardcoded light values:** If the document already defines light-theme CSS variables in a `[data-theme="light"]` or `:root` override, reference those instead of hardcoding `#f5f5f5` / `#ccc`. Hardcode only when no light-theme CSS variables exist.

**Placement:** Insert just before `</style>`, after the last `@keyframes` or `@media` rule.

---

## Pairing with print styles

See `references/print-styles.md` for the print counterpart. Key overlap points when both scrollbar + print styles exist:
- Scrollbar styling doesn't affect print output (scrollbars don't render on paper) — no conflict.
- Print style's `@page { margin }` and scrollbar styling are orthogonal.
