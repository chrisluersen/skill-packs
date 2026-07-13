# Theme Toggle (Dark/Light)

A full dark/light theme system with CSS custom properties, a toggle button, `localStorage` persistence, and system preference detection.

## Pattern

### CSS Variables

```css
:root {
    /* Dark theme (default) */
    --bg-primary: #07080a;
    --bg-surface: #0d0f13;
    --bg-elevated: #14171c;
    --bg-hover: rgba(255,255,255,0.04);
    --fg-primary: #e4e5e7;
    --fg-secondary: #9ba1a7;
    --fg-tertiary: #5f656b;
    --fg-muted: #3b4046;
    --accent-primary: #4f8cff;
    --accent-secondary: #6b5bff;
    --border-default: 1px solid rgba(255,255,255,0.06);
    --border-strong: 1px solid rgba(255,255,255,0.1);
}

[data-theme="light"] {
    --bg-primary: #f5f5f7;
    --bg-surface: #ffffff;
    --bg-elevated: #f0f0f2;
    --bg-hover: rgba(0,0,0,0.03);
    --fg-primary: #1d1d1f;
    --fg-secondary: #6e6e73;
    --fg-tertiary: #9d9d9f;
    --fg-muted: #c4c4c6;
    --accent-primary: #2563eb;
    --accent-secondary: #7c3aed;
    --border-default: 1px solid rgba(0,0,0,0.06);
    --border-strong: 1px solid rgba(0,0,0,0.12);
}
```

### HTML

```html
<button class="header-btn" onclick="toggleTheme()" title="Toggle theme" id="themeBtn">
    <span>☀</span>
</button>
```

### JavaScript

```javascript
/* ---- Theme Toggle ---- */
function toggleTheme() {
    const current = document.documentElement.getAttribute('data-theme') || 'dark';
    const next = current === 'dark' ? 'light' : 'dark';
    document.documentElement.setAttribute('data-theme', next);
    localStorage.setItem('hermes-theme', next);
    document.getElementById('themeBtn').innerHTML = next === 'dark' ? '☀' : '☾';
}

(function() {
    const saved = localStorage.getItem('hermes-theme');
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    const theme = saved || (prefersDark ? 'dark' : 'light');
    document.documentElement.setAttribute('data-theme', theme);
    if (theme === 'light') {
        document.getElementById('themeBtn').innerHTML = '☾';
    }
})();
```

## Key constraints

- **`localStorage` overrides system preference** — if the user manually toggles, that choice persists across sessions. System preference only applies on first visit (no saved theme).
- **`☀`/`☾` emoji as icon** — no external icon dependencies. The sun icon is visible when in dark mode (click to switch to light), moon when in light mode.
- **Inline IIFE for initial theme** — runs before `load`/`DOMContentLoaded` so there's no flash of wrong-theme content. Place this script in `<head>` or immediately after `<body>`.
- **Accent colors** — the light theme should have slightly muted, accessible accent colors (WCAG 4.5:1 contrast against white). `#2563eb` (blue-600) passes against white.
- **Print** — add a `@media print { [data-theme="light"] }` override or always force light mode: `@media print { html:not([data-theme]){--bg-surface:#fff;--fg-primary:#000} }`
