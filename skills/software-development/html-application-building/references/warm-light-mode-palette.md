# Warm Light Mode Palette (Notion-inspired)

A warm-neutral alternative to the default cool-blue light mode tokens. Use when the user's page has a dark default and needs a light mode that feels warm, earthy, and reading-optimized rather than technical.

## Palette

```css
[data-theme="light"] {
    /* Backgrounds — warm cream base */
    --bg-primary: #faf9f7;
    --bg-secondary: #f1f0ed;
    --bg-card: #ffffff;
    --bg-hover: #eae8e3;

    /* Borders — muted tan */
    --border-default: #e3dfd5;
    --border-accent: #6762ff22;

    /* Text — dark warm brown */
    --fg-primary: #1a1a18;
    --fg-secondary: #6b6760;
    --fg-tertiary: #9f9a91;
    --fg-muted: #b0aaa3;

    /* Code / surfaces */
    --code-bg: #f2f0eb;
    --sidebar-bg: #2c2b28;
    --sidebar-text: #e8e5de;
    --sidebar-hover: #3a3834;

    /* Navbar — glass over warm bg */
    --navbar-bg: rgba(250,249,247,0.88);
    --overlay-bg: rgba(0,0,0,0.3);
    --diagram-fill: rgba(0,0,0,0.04);
}
```

## When to use

Pair with a very dark default theme (`#0a0b10` page bg, `rgba(255,255,255,0.06)` borders). The light mode uses warm cream/beige instead of the common cool `#f8f9fc` to create a distinct reading experience.

## Best with

- Typography: Inter (500/600 weight, warm paper background)
- Accent: Indigo/purple (`#6c63ff`) — contrast against warm cream is beautiful
- Code blocks: `#f2f0eb` background with warm-tinted syntax tokens
- Ignore light mode: the dark theme must be the default — this palette is the surprise when toggling

## Compared to default cool theme

| Property | Cool default (`#f8f9fc`) | Warm Notion | Effect |
|----------|--------------------------|-------------|--------|
| Page bg | `#f8f9fc` | `#faf9f7` | Creamier, less sterile |
| Border | `#d0d5e0` | `#e3dfd5` | Softer, tan vs blue-grey |
| Text secondary | `#55648b` | `#6b6760` | Warm brown vs cool blue |
| Sidebar | `#1e293b` | `#2c2b28` | Warm charcoal vs slate |
| Hover bg | `#eef0f6` | `#eae8e3` | Tan vs blue-grey tint |
