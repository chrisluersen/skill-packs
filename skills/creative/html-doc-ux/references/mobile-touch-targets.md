# Mobile Touch Targets & Refinements

Minimum 44×44px touch targets for all interactive elements on narrow screens, plus tighter padding for cards and code blocks to maximize content area.

## Pattern: 640px breakpoint

```css
@media (max-width: 640px) {
    /* Interactive elements — min 44px touch target */
    .sb-link,
    .header-btn,
    .qj-tab,
    .filter-btn {
        padding-top: 10px;
        padding-bottom: 10px;
    }
    
    /* Tighter card padding */
    .hl-box { padding: 14px; }
    .card { padding: 18px; }
    .code-block { border-radius: var(--radius-sm); }
    
    /* Code block header — prevent wrapping on narrow screens */
    .cb-header { padding: 8px 10px; gap: 6px; }
    .cb-header .cb-dot { flex-shrink: 0; }
    .cb-header .cb-lang { white-space: nowrap; flex-shrink: 0; }
    .cb-body { padding: 10px; font-size: 11px; }
    
    /* Table cells — tighter horizontal padding */
    td, th { padding: 8px 10px; }
    
    /* Section nav links — larger tap target */
    .section-nav a { padding: 8px 12px; }
}
```

## Detailed rules

| Rule | What it fixes |
|------|---------------|
| `padding-top/bottom: 10px` on links/buttons | Ensures ≥44px tap target height (assuming ~24px text height + 20px padding total = 44px) |
| `.card { padding: 18px }` | Richer content areas on 375px screens — 24px is too much horizontal padding for card content |
| `.cb-body { font-size: 11px }` | Smaller code text to reduce horizontal scrolling on narrow viewports |
| `.cb-lang { flex-shrink: 0 }` | Prevents the language label from being collapsed by flex when the header is narrow |
| `td, th { padding: 8px 10px }` | More room for data cells on small screens |

## Additional mobile considerations

### Viewport meta (critical)

```html
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0">
```

Always present. `maximum-scale=5.0` lets users zoom but prevents accidental double-tap zoom on interactive elements.

### iOS tap highlight

```css
* {
    -webkit-tap-highlight-color: transparent;
}
```

Removes the gray flash on tap. Only apply if you have visible hover/focus states as alternatives.

### Safe area padding for notch devices

```css
@media (max-width: 640px) {
    .hero {
        padding-top: max(40px, env(safe-area-inset-top, 0px));
    }
    .foot {
        padding-bottom: max(24px, env(safe-area-inset-bottom, 0px));
    }
}
```

## Key constraints

- **640px breakpoint** — matches iPhone SE (375px) through iPad mini portrait (768px). At 641px+, the desktop layout is active.
- **Don't hide interactive elements on mobile** — the goal is to make them more tappable, not to remove them.
- **Test at 320px** (iPhone SE earliest) — some patterns may need further tweaking if the layout wraps awkwardly
- **`!important` sparingly** — only use it for truly critical overrides (like `back-to-top-btn` visibility). For padding/sizing changes, rely on specificity
