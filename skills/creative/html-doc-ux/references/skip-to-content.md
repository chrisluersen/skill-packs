# Skip-to-Content Link

A visually-hidden "Skip to content" link that becomes visible on keyboard focus — the first focusable element after `<body>`. Lets keyboard and screen-reader users bypass the navigation chrome and jump directly to the main content.

## HTML

Place immediately after `<body>`, before any `<header>`, `<nav>`, or progress bars:

```html
<a href="#main" class="skip-link">Skip to content</a>
```

The `href` targets the `<main>` element's `id`. If the doc uses `<main id="main">`, use `href="#main"`.

## CSS

```css
.skip-link {
    position: absolute;
    top: -100%;
    left: 16px;
    background: var(--accent-primary);
    color: #fff;
    padding: 8px 16px;
    border-radius: var(--radius-sm, 6px);
    z-index: 9999;
    font-weight: 600;
    transition: top .15s;
}
.skip-link:focus {
    top: 8px;
}
```

**How it works:** `position: absolute` removes it from normal flow. `top: -100%` pushes it off-screen above the viewport. On `:focus` (triggered by Tab key), `top: 8px` pulls it into view below the sticky header.

## Variants

- **Double-colon border:** Add `outline: 2px solid var(--accent-primary)` and `outline-offset: 2px` for a more visible focus ring.
- **Dark overlay:** Some patterns add `background: var(--bg-primary)` behind the link so it's readable over any page content.

## Pitfalls

- **`position: absolute` vs `fixed`** — `absolute` is correct; it scrolls with the page. `fixed` would stay pinned relative to the viewport even as the user scrolls, which is wrong for a skip link.
- **First element after `<body>`** — the skip link must be the very first interactive element. If there's a `<noscript>` banner before it, keyboard users on JS-enabled browsers still tab to the skip link first (the noscript content is not in the tab order). If there's a progress bar div before it, move the progress bar after the skip link.
- **`z-index`** — must be higher than any sticky header or overlay. 9999 is safe.
