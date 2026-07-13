# Print Styles for Static HTML Docs

## Minimal Template

Minimal `@media print` block that covers the essentials. Add just before `</style>`:

```css
@media print {
    /* Hide chrome */
    header, .sidebar, .sidebar-overlay, #progressBar,
    .btt, #ksOverlay, #ksModal, #qjOverlay, #qjModal,
    .filter-bar, .foot { display: none !important; }

    /* Full-width content */
    main { max-width: 100%; padding: 0.5in; margin: 0; }

    /* Card/box integrity */
    .card { break-inside: avoid; box-shadow: none; border: 1px solid #ccc; background: #fff; }
    .code-block { break-inside: avoid; border: 1px solid #ddd; }
    .hl-box { border: 1px solid #999; background: #fafafa; }

    /* Force light theme */
    body { background: #fff !important; color: #000; font-size: 11pt; }
    .card-header h2 { color: #000 !important; }
    .hero { background: none !important; border-bottom: 2px solid #000; }
    .hero h1 { color: #000 !important; }
    a { color: #000; text-decoration: underline; }

    /* Kill animations */
    section { animation: none !important; opacity: 1 !important; transform: none !important; }

    /* Badge cleanup */
    .badge, .sm-badge { border: 1px solid #000; color: #000; background: transparent !important; }

    /* Spacers */
    .section-spacer { display: none; }
    img { max-width: 100% !important; }
}

@media print and (prefers-color-scheme: dark) {
    /* Force light print even when system is in dark mode */
}
```

## What to hide in print

| Element | Why hide |
|---------|----------|
| `header` | Fixed header overlaps content on paper |
| `.sidebar` | Navigation sidebar is useless on paper |
| `.sidebar-overlay` | Mobile overlay background |
| `#progressBar` | Reading progress is scroll-only |
| `.btt` | Back-to-top button is scroll-only |
| `#qjOverlay, #qjModal` | Quick Jump modal |
| `#ksOverlay, #ksModal` | Keyboard shortcuts modal |
| `.filter-bar` | Section filter buttons are interactive |
| `.foot` | Footer with interactive links (fine to show if text-only) |

## What to force-light

Dark-theme HTML docs print as dark-background blocks on white paper — ink-heavy and unreadable. Force all backgrounds to white and text to black:

```css
body { background: #fff !important; color: #000; }
.card { background: #fff !important; }
.hero { background: none !important; border-bottom: 2px solid #000; }
```

## What to break-inside-avoid

Elements that should NOT split across pages:

- `.card` — individual content cards
- `.code-block` — code examples
- `.hl-box` — highlighted callout boxes
- The **last card** before `.section-nav` — so nav doesn't orphan
- `.section-nav` — prev/next links should stay together

## What to kill

- **All animations** — `animation: none !important; opacity: 1 !important; transform: none !important;`
- **Sticky positioning** — Reset to `position: static` if sticky elements exist
- **Box shadows** — Replace with `border: 1px solid #ccc` to save ink
- **CSS gradients** — Replace with solid colors
