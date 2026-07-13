# Scroll-Padding for Fixed Headers

When a page has a fixed/sticky header (`position: fixed; top: 0;`), anchor links (`<a href="#section-id">`) scroll the target element to the top of the viewport — where it's hidden behind the header. The `scroll-padding-top` CSS property offsets the scroll position so anchor targets land below the header.

## CSS

Add to `:root` or `html`:

```css
:root {
    scroll-padding-top: calc(var(--header-h) + 20px);
}
```

Or without CSS custom properties:

```css
html {
    scroll-padding-top: 72px; /* header height + breathing room */
}
```

## How it works

`scroll-padding-top` adds padding (offset) to the top of the scrollport when the browser performs a scroll operation triggered by:
- Anchor navigation (`<a href="#target">`)
- `window.scrollTo()` / `element.scrollIntoView()`
- Browser find-in-page
- Focus navigation to an off-screen element

It does NOT affect normal page scrolling — only programmatic/anchored scrolls.

## Setting the right value

The offset should be: `fixed_header_height + gap_glyph`. The gap accounts for the visual separation between the header and the section title so the section heading isn't pressed right up against the header bottom. A 16-20px gap is standard.

If the header height is a CSS custom property (`--header-h`), use `calc()` so the offset stays in sync if the header is resized.

## Pitfalls

- **Not supported in print or `@media print`** — irrelevant for print stylesheets since scroll is not a print concept.
- **Unit mismatch** — `scroll-padding-top` accepts lengths, not percentages of the scrollport. Use `px`, `em`, `rem`, or `calc()`. Do NOT use bare `%` values.
- **Conflicts with `scroll-margin-top`** — if individual elements also set `scroll-margin-top`, the effective offset is `max(scroll-padding-top, scroll-margin-top)` for that element. Prefer the single `scroll-padding-top` on `:root` unless a specific element needs a different offset.
- **Browser support** — supported in all modern browsers (Chrome 69+, Firefox 68+, Safari 14.1+, Edge 79+). For very old browsers the anchor will land behind the header — no breakage, just suboptimal UX.
