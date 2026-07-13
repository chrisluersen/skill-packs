# Scroll Gradient Indicator

A subtle CSS-only gradient overlay on scrollable containers (tables, code blocks, panels) that hints at overflow content — common in Stripe, Linear, and Mintlify docs.

## Pattern: Table scroll indicator

### CSS

```css
.tw {
  overflow-x: auto;
  position: relative;
}
.tw::after {
  content: '';
  position: absolute;
  top: 0;
  right: 0;
  bottom: 0;
  width: 32px;
  background: linear-gradient(to right, transparent, var(--bg-surface));
  pointer-events: none;
  opacity: 0;
  transition: opacity 0.2s;
}
/* Show gradient when table CAN scroll (no sentinel at end) */
.tw:not(:has(.tw-end-marker))::after {
  opacity: 1;
  z-index: 2;
}
/* Hide on hover/focus (user is actively scrolling) */
@media (hover: hover) {
  .tw:hover::after,
  .tw:focus-within::after {
    opacity: 0;
  }
}
```

### How it works

1. `.tw` gets `position: relative` as anchor for the `::after`
2. `::after` renders a 32px gradient from transparent → `--bg-surface` (matches the page background in both themes)
3. The sentinel approach (`.tw-end-marker`) lets you suppress the gradient on tables too short to scroll — insert `<span class="tw-end-marker" hidden></span>` after the last row if needed
4. On hover/touch the gradient fades out so the user can see the full scrollbar

### Integration

Place the `::after` definition right after the `.tw` sizing rules in the existing `<style>` block. Use `patch` with the `.tw{...}` line as `old_string` context.

### Variant for code blocks

Same pattern, adapted for `.code-block`:

```css
.code-block {
  position: relative;
}
.code-block::after {
  content: '';
  position: absolute;
  top: 40px;  /* below the header */
  right: 0;
  bottom: 0;
  width: 24px;
  background: linear-gradient(to right, transparent, var(--bg-surface));
  pointer-events: none;
  opacity: 0;
  transition: opacity 0.2s;
}
.code-block:hover::after,
.code-block:focus-within::after {
  opacity: 1;
}
```

## Key constraints

- Uses `var(--bg-surface)` — requires the doc to have CSS custom properties for theme support. Never hardcode `#fff`/`#000`.
- `pointer-events: none` on `::after` prevents the gradient from blocking clicks on scrollbar or content underneath
- The hover-to-hide pattern assumes `hover: hover` (desktop). On mobile, users see the gradient and the scrollbar simultaneously, which is fine
