# Back-to-Top Floating Button

A floating ↑ button that appears after the user scrolls past the fold, with smooth scroll-to-top behavior. Standard on Vercel docs, Stripe docs, and Mintlify.

## Pattern

### HTML (header-right area)

```html
<button class="header-btn back-to-top-btn" onclick="scrollToTop()" title="Back to top" id="backToTopBtn"><span>↑</span></button>
```

Place in the header alongside the theme toggle and shortcuts buttons — user expects it in the top-right.

### CSS

```css
/* Hidden by default on all devices */
.back-to-top-btn {
    display: none !important;
}
/* Visible only on desktop after scrolling past the fold */
@media (min-width: 641px) {
    .back-to-top-btn.show {
        display: flex !important;
        opacity: 0.4;
        transition: opacity 0.2s;
    }
    .back-to-top-btn.show:hover {
        opacity: 1;
    }
}
```

### JavaScript

```javascript
/* ---- Back to top scroll visibility ---- */
const btt = document.getElementById('backToTopBtn');
function checkScroll() {
    btt.classList.toggle('show', window.scrollY > window.innerHeight);
}
window.addEventListener('scroll', checkScroll, { passive: true });
window.addEventListener('load', checkScroll);
window.scrollToTop = function() {
    window.scrollTo({ top: 0, behavior: 'smooth' });
};
```

## Variant: Always-visible bottom-right floating button

```css
#backToTopBtn {
    display: flex;
    position: fixed;
    bottom: 24px;
    right: 24px;
    z-index: 999;
    width: 40px;
    height: 40px;
    border-radius: 50%;
    background: var(--bg-elevated);
    border: var(--border-default);
    color: var(--fg-primary);
    cursor: pointer;
    align-items: center;
    justify-content: center;
    box-shadow: 0 2px 8px rgba(0,0,0,0.2);
    opacity: 0;
    transform: translateY(12px);
    transition: opacity 0.25s, transform 0.25s;
    pointer-events: none;
}
#backToTopBtn.show {
    opacity: 1;
    transform: translateY(0);
    pointer-events: auto;
}
#backToTopBtn:hover {
    background: var(--accent-primary);
    color: #fff;
}
```

## Key constraints

- **Mobile: hide the button entirely** — mobile users scroll by swiping and the header's logo/title area already acts as a tap-to-scroll-top on iOS. Adding another tap target is clutter.
- **`!important` on `display: none`** is needed to override any existing `.header-btn` flex styling
- **Use opacity fade, not animate display** — `display: none` to `flex` cannot be animated. The pattern layers `display` + `opacity` + `transition` to get both: element doesn't exist in layout when hidden, but fades smoothly when shown
- **Scroll past the viewport height** — `window.scrollY > window.innerHeight` means the button appears only after scrolling 100% past the initial viewport. Adjust threshold if needed (`> 500` for earlier appearance)
- **`passive: true`** on scroll handler — required for performance on scroll-heavy pages
