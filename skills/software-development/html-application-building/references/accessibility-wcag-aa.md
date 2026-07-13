# WCAG AA Accessibility Audit & Remediation

Systematic methodology for auditing and fixing WCAG AA compliance on existing single-file HTML docs. Complements Pass 4 of `html-application-building`.

## Audit Sequence (in order)

These phases should run in this order — later phases depend on anchors from earlier ones.

| Phase | Focus | Why first |
|-------|-------|-----------|
| 1 | Color contrast (CSS variables) | Foundation — every other fix references these values |
| 2 | Focus order / tabindex | Structural — affects keyboard navigation globally |
| 3 | Screen reader announcements | Content — adds ARIA to existing elements without moving them |
| 4 | `color-scheme` meta tag | One-line, independent |
| 5 | `prefers-reduced-motion` | CSS-only, positioned at end of `<style>` block |

## Phase 1: Color Contrast (WCAG AA)

### Minimum ratios
- **Normal text** (`<14pt`): **4.5:1**
- **Large text** (`≥14pt bold` or `≥18pt`): **3:1**
- **UI components** (borders, icons): **3:1**

### Toolkit: Python contrast checker

```python
def linearize(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

def relative_luminance(hex_color):
    h = hex_color.lstrip('#')
    r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b)

def contrast_ratio(c1, c2):
    l1, l2 = relative_luminance(c1), relative_luminance(c2)
    lighter, darker = max(l1, l2), min(l1, l2)
    return (lighter + 0.05) / (darker + 0.05)

# Usage
r = contrast_ratio('#4b4f62', '#0f1117')
print(f"Ratio: {r:.2f}:1 — {'PASS' if r >= 4.5 else 'FAIL'} AA")
```

### Common failing patterns

| Variable | Dark bg (`#0f1117`) | Light bg (`#f8f9fc`) |
|----------|---------------------|---------------------|
| `--fg-muted` | Often fails — too close to bg | Often fails — too light on white |
| `--fg-tertiary` | Borderline — may need 3% brighter | Rarely fails on light |
| `--accent-primary` | Borderline if blue/purple at `#62xxff` | Usually passes on light |

### Fix strategy
1. Compute failing ratio programmatically
2. For dark bg: **lighten** the color (increase RGB values). Target `#7c7c7c` range for muted, `#7c7c83` for tertiary
3. For light bg: **darken** the color (decrease RGB values). Target `#737373` range for muted
4. For accent: adjust hue slightly toward lighter direction (e.g. `#6762ff` → `#6769ff` adds 7 points of green)
5. Update the value in ALL theme blocks (`:root` for dark, `[data-theme="light"]` for light)

### Verification
```bash
# Check specific variable in all theme blocks
grep -c -- '--fg-muted:' "doc.html"
grep -c '--fg-muted: #9ca3af' "doc.html"  # should be 0 if old value removed
```

## Phase 2: Focus Order

### Checklist
- [ ] No positive `tabindex` values (`tabindex="1"`, `tabindex="2"`, etc.) — these override natural DOM order
- [ ] `tabindex="-1"` only on elements that should be programmatically focusable but not in Tab sequence
- [ ] Add a global `:focus-visible` rule in CSS:
  ```css
  *:focus-visible { outline: 2px solid var(--accent-primary); outline-offset: 2px; }
  ```
- [ ] Tab order through page: skip link → header → main content → nav → footer
- [ ] Back-to-top, modals, sidebar panels: trap focus inside when open

### Pitfall
`outline: none` without a `:focus-visible` replacement is the #1 keyboard accessibility failure. Always pair outline removal with a `:focus-visible` alternative — never use bare `outline: none`.

## Phase 3: Screen Reader Announcements

### Three ARIA patterns used in this session

| Element | ARIA | Placement |
|---------|------|-----------|
| Filter/sort summary | `aria-live="polite"` | HTML attribute on container (`<div id="filterSummary" aria-live="polite">`) |
| Toast notification | `role="status"` | JS `setAttribute` when creating the toast `<div>` element |
| Theme toggle button | `aria-label` | HTML default + JS update on toggle |

### Implementation details

**Filter summary** — static HTML attribute:
```html
<div class="filter-summary" id="filterSummary" aria-live="polite"></div>
```

**Toast** — set programmatically in JS (toast is dynamically created):
```js
t = document.createElement('div');
t.className = 'toast';
t.setAttribute('role', 'status');
t.innerHTML = '...';
```

**Theme button** — dynamic aria-label in toggle function:
```js
btn.setAttribute('aria-label', next === 'dark'
    ? 'Switch to light theme'
    : 'Switch to dark theme');
```
Always keep the aria-label in sync with the icon — if the icon shows ☀ (sun for dark mode), the label says "Switch to light theme".

### Why not `aria-live="assertive"`?
Routine announcements (toast, filter count, theme switch) should use `polite` or `role="status"`. `assertive` interrupts the user's current interaction and should be reserved for errors, warnings, and critical alerts.

## Phase 4: `color-scheme` Meta Tag

One-line `<head>` addition. Tells the browser which color schemes the page supports, enabling native form controls, scrollbars, and `::selection` to adapt without explicit CSS:

```html
<meta name="color-scheme" content="light dark">
```

Verify presence:
```bash
grep -c 'color-scheme' doc.html  # should be >= 1
```

## Phase 5: `prefers-reduced-motion`

### CSS pattern — disable all animations for users who prefer reduced motion

Insert a block at the end of `<style>` (before `</style>`):

```css
@media (prefers-reduced-motion: reduce) {
    *, *::before, *::after {
        animation-duration: 0.01ms !important;
        animation-iteration-count: 1 !important;
        transition-duration: 0.01ms !important;
    }
    html { scroll-behavior: auto; }
    section { opacity: 1 !important; transform: none !important; }
    .toast { transition: none; }
}
```

Key details:
- `!important` is justified here — this is an accessibility override, not a design choice
- `0.01ms` is visually instantaneous but avoids the `0s` edge case where some browsers skip the animation entirely
- Section entrance must be force-visible (`opacity:1, transform:none`) so users see content without delay
- `scroll-behavior: auto` disables smooth anchor scrolling
- Test by enabling "Reduce motion" in OS accessibility settings

### Audit existing animations
Before adding the reduced-motion block, find all animation/transition sources:
```bash
grep -n 'transition:' doc.html | grep -v '//'  # all CSS transitions
grep -c '@keyframes' doc.html                    # all keyframe animations
grep -c '@media.*prefers-reduced-motion' doc.html # existing overrides (should be 0 or 1)
```

### Entrance animation cleanup
If the page has both a legacy immediate-reveal loop (sets `style.opacity='1'` on all sections in a `load` handler) AND an IntersectionObserver approach, remove the legacy loop. The IntersectionObserver version is superior: it progressively reveals sections as they scroll into view rather than all at once on load, and automatically honours stagger delays.

Search for stale immediate-reveal code:
```bash
grep -n 'var secs = document.querySelectorAll.*section' doc.html
```
If found, remove the `secs.forEach` + double-rAF block, keeping only `injectCopyButtons()`, `buildMobileSidebar()`, and the IntersectionObserver setup.
