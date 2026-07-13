# Stagger Entrance Animations

Sections fade and slide up on page load with staggered delays — creates a polished cascading reveal effect. Used by Stripe, Linear, and Vercel marketing pages.

## Pattern

### CSS (recommended — uses `--stagger-delay` var)

```css
/* Base state: invisible, slightly shifted down.
   --stagger-delay is set per-section by JS; fallback 0s if JS fails */
section:not(#intro) {
    opacity: 0;
    transform: translateY(8px);
    transition: opacity 0.4s cubic-bezier(0.22, 1, 0.36, 1) var(--stagger-delay, 0s),
                transform 0.4s cubic-bezier(0.22, 1, 0.36, 1) var(--stagger-delay, 0s);
}
```

### JavaScript (double rAF — no layout thrash)

```javascript
/* ---- Stagger entrance animations ---- */
window.addEventListener('load', function() {
    var secs = document.querySelectorAll('section:not(#intro)');
    var intro = document.getElementById('intro');
    if (intro) { intro.style.opacity = '1'; intro.style.transform = 'translateY(0)'; }
    secs.forEach(function(s, i) {
        s.style.setProperty('--stagger-delay', (i * 0.07) + 's');
    });
    /* Double rAF — all style changes batch into one paint cycle.
       CSS transitions handle the per-element timing via --stagger-delay. */
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

## How it works

1. All `<section>` elements (except `#intro`) start with `opacity: 0; transform: translateY(8px)` from CSS
2. JS sets a `--stagger-delay` CSS variable on each section (0s, 0.07s, 0.14s, …) in one loop
3. A double `requestAnimationFrame` batch-applies `opacity: 1; transform: translateY(0)` to all sections at once
4. The CSS `transition-delay: var(--stagger-delay)` causes each section to animate at its own staggered time — the browser handles the timing entirely via native composited CSS transitions, no N+1 timers needed
5. `#intro` is excluded from the stagger and appears immediately on page paint

## Why double rAF over nested setTimeout

| Approach | Timer count | Layout thrash | Timing precision |
|----------|------------|---------------|------------------|
| **Nested setTimeout** (old) | N+1 timers | Each call triggers style recalc | ~60ms intervals, drifting |
| **Double rAF + CSS transition** | 0 JS timers | Batch in one paint cycle | Vsync-aligned, GPU-composited |

Double rAF ensures the browser has painted the initial `opacity: 0` state before the transition to opacity: 1 is enqueued. The `var(--stagger-delay)` in the CSS `transition-delay` handles the per-element stagger — the JS only needs to set the CSS variable and toggle once.

## nth-child fallback — when NOT to use it

The `section:nth-child(N)` approach is only reliable when `<section>` elements are the first N children of their parent. If the container has non-section siblings before them (`.hero`, `.stat-row`, `.quick-start`), the nth-child indices will be wrong — `section:nth-child(1)` will match `.hero`, not the first section.

**Safer alternatives:**
- Use `section:nth-of-type(N)` which only counts `<section>` elements (but still breaks if you reorder)
- Use the `--stagger-delay` CSS var approach (recommended — reliable regardless of sibling order)
- Wrap all sections in a sub-container so nth-child starts at 1

## Hero section exclusion

When the document has a hero `<section id="intro">` (with background glow, stat row, quick-start grid), **exclude it from the stagger** so it appears immediately on page paint:

```javascript
const secs = document.querySelectorAll('section:not(#intro)');
const intro = document.getElementById('intro');
if (intro) { intro.style.opacity = '1'; intro.style.transform = 'translateY(0)'; }
```

Without this, the hero's visual first impression (title gradient, pulse dot, stat cards, quick-link pills) jumbles in alongside the content cards — makes the page feel sluggish.

## FOUC prevention

The stagger animation relies on sections starting at `opacity: 0`. In the gap between CSS loading and JS firing, the page renders with invisible sections — no visible content — which can look like a broken page.

### 🔴 CRITICAL: `js-ready` must be the first line of your script

The FOUC prevention pattern hides `<html>` itself until JS confirms it's ready. If you forget to add the class, the page stays invisible **forever** with no console error:

```css
/* html starts invisible — prevents FOUC of initial opacity:0 sections */
html { opacity: 0; }
html.js-ready { opacity: 1; }
```

```javascript
;(function() {
    'use strict';
    document.documentElement.classList.add('js-ready');  // ← MUST BE FIRST
    // ... everything else (theme, stagger, etc.) ...
})();
```

Without that `classList.add('js-ready')` call, `html{opacity:0}` is never overridden and the entire page is blank. No error, no warning — just invisible.

## Key constraints

- **`load` event, not `DOMContentLoaded`** — wait for fonts/images to load so the animation doesn't fight with layout shifts
- **`section:not(#intro)`** — always exclude the hero/intro section from staggering so the page's first impression appears instantly
- **Delay range:** 0.07s per section × 15 sections ≈ 1.05s total. The cascade finishes quickly enough not to feel slow, staggered enough to create depth
- **Don't animate the mobile TOC or sidebar** — only `<section>` elements get stagger animations
- **`cubic-bezier(0.22, 1, 0.36, 1)`** is an ease-out curve — starts fast, decelerates. Feels smooth for entrance animations
- **8px translateY** is subtle — enough to create depth without feeling like content is sliding in from far away
- **Works alongside other CSS transitions** — if a section already has hover transitions, the entrance transition doesn't interfere because it fires once on mount and then the property stabilizes
- **No FOUC white flash** — `html{opacity:0}` + `html.js-ready{opacity:1}` ensures the first paint is the finished product (but see 🔴 above — `js-ready` must be added immediately)
- **`--stagger-delay` fallback value** — always include `var(--stagger-delay, 0s)` with a fallback of `0s` so the page degrades gracefully if JS fails to set the variable
- **nth-child fallback is unreliable with non-section siblings** — prefer `--stagger-delay` var or `nth-of-type`
