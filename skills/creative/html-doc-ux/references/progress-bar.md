# Reading Progress Bar

A thin fixed bar at the very top of the page that fills as the user scrolls — indicates how much content remains. Used by Medium, Stripe docs, and most long-form reference pages.

## Pattern

### HTML (right after `<body>`)

```html
<div id="progressBar" style="position:fixed;top:0;left:0;width:0%;height:2px;background:var(--accent-primary);z-index:10001;transition:width 0.1s linear;pointer-events:none"></div>
```

Place it as the first element inside `<body>` so it sits above everything.

### CSS

```css
/* --- Fixed progress bar --- */
#progressBar {
    position: fixed;
    top: 0;
    left: 0;
    width: 0%;
    height: 2px;
    background: var(--accent-primary);
    z-index: 10001;
    transition: width 0.1s linear;
    pointer-events: none;
}
```

### JavaScript

```javascript
/* ---- Reading Progress Bar ---- */
function updateProgress() {
    const scrollTop = window.scrollY;
    const docHeight = document.documentElement.scrollHeight - window.innerHeight;
    const progress = docHeight > 0 ? Math.min((scrollTop / docHeight) * 100, 100) : 0;
    document.getElementById('progressBar').style.width = progress + '%';
}
window.addEventListener('scroll', updateProgress, { passive: true });
window.addEventListener('resize', updateProgress, { passive: true });
window.addEventListener('load', updateProgress);
```

## Key constraints

- **`z-index: 10001`** — ensure it's above the header (`z-index: 10000`). Adjust if your header has a different z-index layer.
- **`transition: width 0.1s linear`** — smooths the bar movement without lag. 0.1s is fast enough to feel responsive.
- **`pointer-events: none`** — prevents the bar from intercepting clicks (especially important if it's at the very top edge where users might click tabs/back button).
- **Edge case: zero-height document** — if `docHeight` is 0 (empty page, or single element filling viewport), the division would be `0/0 = NaN`. Guard with `docHeight > 0 ? ... : 0`.
- **Accent color** — use `var(--accent-primary)` so it matches the page's theme. If the doc doesn't have a `--accent-primary` var, use a hardcoded color that works in both themes, or add the CSS variable first.
- **Combined with stagger animations** — the progress bar should be visible before animations complete (it's outside `section` elements and shows 0% immediately on load).
