# Fusion Design Session: Hermes Agent Stack Reference

**Source:** Session where user asked to "improve the UX/UI to the best you can" on an existing HTML reference report, using "the best UI inspo you can find online."

**Approach:** Fusion of 4 design systems (Supabase + Linear + Mintlify + Stripe) across 3 iterations.

## Session Details

- **Total iterations:** 3 (not 4 — the HTML Application Building skill's standard 4-pass model was adapted to 3 cycles for this artifact)
- **Output:** 98KB, 2,068 lines, single self-contained HTML file
- **Iteration pattern:** Content & structure → Navigation & interactivity → UX polish & filtering

## Fusion Allocation

| Dimension | Source | CSS Values |
|-----------|--------|------------|
| Background & surfaces | Supabase (dark-native) | `--bg-page: #070708`, `--bg-surface: #0e0e10` |
| Border system | Linear (ultra-thin precision) | `--border-default: rgba(255,255,255,0.06)` |
| Layout & card patterns | Mintlify (reading-optimized) | `--sidebar-w: 270px`, `--max-content: 900px` |
| Accent color | Stripe (signature purple) | `--accent-primary: #6c63ff` |

## Components Built

### Pass 1 (Foundation)
- 12 content sections with numbered labels (§00-§12)
- Dark theme with CSS custom properties (28 vars)
- Stats row (4 metric cards at top)
- Interactive accordions for grouped content
- Two-col/three-col grid layouts for comparisons
- Feature lists (→ arrow-prefixed)
- Card groups with visual divider lines
- Tag badge system (.tag-arch, .tag-feat, .tag-config, etc.)

### Pass 2 (Interactivity)
- Fixed sidebar with scroll-spy active section highlighting
- Mobile slide-out sidebar with blur backdrop overlay
- Scroll progress bar (gradient: purple → cyan)
- Quick-jump modal with ⌘K keyboard shortcut
- Arrow-key navigation within quick-jump results
- Tag filter bar (All / Overview / Setup / Reference) that filters sections AND sidebar links
- Code copy buttons on hover (clipboard API + fallback)
- macOS-style dot headers on code blocks

### Pass 3 (UX Polish)
- Section reveal animations (IntersectionObserver, fade-in + translateY)
- Light/dark mode toggle button (JS CSS variable swap, not class-based)
- Filter-aware sidebar (hidden links for filtered-out sections)
- Filter-aware scroll-spy (only highlights visible sections)
- Back-to-top floating button
- Print stylesheet
- Card hover effects (border highlight + subtle shadow)
- Smooth transitions (0.25s card hovers, 0.3s sidebar slide, 0.15s filter buttons)

## Key UX Decisions

### Why a sidebar over horizontal tabs
For 12 sections, a horizontal tab bar would truncate at 5-6 and require sub-navigation. A numbered sidebar provides instant orientation ("section 05 of 12") and works at any depth.

### Why the tag filter also hides sidebar links
Without this, clicking "Setup" would filter to 4 sections but the sidebar would still show 12 links. Clicking a sidebar link for a filtered-out section would scroll to invisible content — actively confusing. Hiding the sidebar links for filtered sections completes the filter illusion.

### Why JS variable swap over class toggle for theme
Adding a `.light` class on `<body>` and relying on CSS overrides works but has a subtle failure mode: `prefers-color-scheme` in a media query can override the class in some CSS cascade scenarios. Inline `element.style.setProperty()` on `:root` always wins, zero ambiguity.

### Why 3 iterations instead of 4
The 4-pass model (content → interactivity → polish → quality/accessibility) is ideal for greenfield builds. This was a redesign of an existing HTML file, so the quality pass was distributed across the first three passes — each iteration incorporated ARIA attributes and print styles inline, not as a separate pass.

## Implementation Notes

```js
// Filter count badges — update when filter changes
function setFilter(tag) {
  currentFilter = tag;
  document.querySelectorAll('.filter-btn').forEach(b => {
    b.classList.toggle('active', b.dataset.filter === tag);
  });
  applyFilter();
}
```

```js
// Quick-jump keyboard handler — prevents default browser behavior
document.addEventListener('keydown', e => {
  if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
    e.preventDefault(); openQJ();
  }
  if (e.key === 'Escape' && qjOpen) closeQJ();
});
```

```css
/* Scroll-padding for fixed header */
html { scroll-padding-top: calc(56px + 32px); }
```

## Key Mistakes Caught by Iteration

1. **Tag filter was decorative in v2** — the filter buttons rendered but had no JavaScript wiring. The third iteration added `setFilter()` and `applyFilter()`.
2. **Section reveal fired on page sections behind the hero** — fixed by adding `rootMargin: -60px` to the IntersectionObserver.
3. **Mobile sidebar didn't sync desktop sidebar state** — each sidebar needs its own scroll-spy event handler using the same visible-section calculation.
4. **Theme toggle didn't reset on page load** — the saved `localStorage` preference wasn't checked. Added an init function that reads storage first, then falls back to `prefers-color-scheme`.
