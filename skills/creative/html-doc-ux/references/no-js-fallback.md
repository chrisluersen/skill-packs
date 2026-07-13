# No-JS Fallback

Pattern for gracefully degrading a static HTML page when JavaScript is disabled. Uses a `.no-js` class on `<html>` that JS removes at load time, plus a `<noscript>` banner to inform users.

## HTML

Add `.no-js` class to the `<html>` element:

```html
<html lang="en" data-theme="dark" class="no-js">
```

Add `<noscript>` banner right after `<body>` (after the skip-link, before everything else):

```html
<noscript><div class="noscript-banner">⚡ This page requires JavaScript for interactive features. Content is fully readable without JS.</div></noscript>
```

## CSS

Place before any `.sidebar`, `.filter-bar`, or interactive-element CSS:

```css
/* Hide JS-only elements when JS is off */
.no-js .filter-bar,
.no-js [data-action="toggle-sidebar"],
.no-js [data-action="toggle-theme"],
.no-js [data-action="open-shortcuts"] {
    display: none !important;
}

/* Noscript banner — visible only when JS is off */
.noscript-banner {
    background: var(--accent-amber);
    color: #000;
    text-align: center;
    padding: 10px 16px;
    font-size: 14px;
    position: sticky;
    top: 0;
    z-index: 9999;
}
```

## JS

Remove the `.no-js` class as the **very first statement** in the script, before any DOM queries or event listeners:

```javascript
document.documentElement.classList.remove('no-js');
```

**Critical:** This must be the first line of the script, not inside a `DOMContentLoaded` or `load` callback. The CSS hiding rules take effect immediately — if the class removal is async, there's a flash where JS-only elements are hidden while JS is loading. Adding the removal as the first synchronous statement prevents this.

## Why `.no-js` (not `:has` CSS)

The `.no-js` class technique is a well-established pattern from HTML5 Boilerplate. CSS `:has()` could theoretically achieve the same with `html:not(:has(script[src]))`, but:
- `:has()` does not detect inline `<script>` blocks
- `:has()` support is still not universal
- The JS-removal pattern is more explicit and works in every browser

## Which elements to hide

When JS is disabled, hide elements that are:
- Interactive and require JS to function (theme toggle, sidebar toggle)
- Filter/search bars that need JS event handlers
- Any button with `data-action` attributes that routes through JS event delegation

Never hide static content (section text, tables, code blocks) — the page should be fully readable without JS.

## Pitfalls

- **Do NOT wrap the `classList.remove` in `DOMContentLoaded`** — the CSS has already applied `.no-js .filter-bar { display: none }` by the time the parse reaches the `<script>` tag. If you defer the removal, you get a visible flash of hidden elements. Remove it synchronously.
- **`.noscript-banner` is outside the `<noscript>` tag visually** — the `<noscript>` only wraps the banner div; the CSS and HTML structure around it are standard. The `<noscript>` element itself has no visual appearance — only its contents render when JS is off.
- **`!important` on `.no-js` rules** — interactive elements may have competing CSS specificity (e.g. `.filter-bar` styled by multiple selectors). `!important` ensures the hiding rule wins regardless of source order.
