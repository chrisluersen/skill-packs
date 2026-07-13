# Light/Dark Theming: Real-World Example

**Source:** A 97KB Hermes ecosystem report (`hermes-agent-report.html`) was converted from dark-only to full light/dark mode support.

**File stats before:** 1876 lines, 99KB, 25 CSS custom properties, 7 hardcoded `rgba(6,6,15,…)` values, 1 hardcoded `rgba(0,0,0,0.6)`, 5 inline `rgba(99,102,241,…)` accent fills.

**After:** 1926 lines, 101KB, 32 CSS custom properties (including infra vars), `@media (prefers-color-scheme: light)` block, zero hardcoded theme-dependent rgba values.

## The Conversion Pattern

### Step 1: Audit hardcoded colors

Search for every hex and rgba that isn't a CSS variable reference:

```bash
grep -n 'rgba\|#[0-9a-f]\{6\}' file.html | grep -v 'var(--'
```

Pay special attention to:
- Navbar backgrounds — often `rgba(6,6,15,0.85)` in dark HTML reports
- Mobile menu backgrounds — `rgba(6,6,15,0.98)`
- Sidebar/slide-panel backgrounds — `rgba(6,6,15,0.6)`
- SVG background fills — `fill="rgba(6,6,15,0.3)"`
- Page overlays — `background: rgba(0,0,0,0.6)`
- Inline code backgrounds — `background: rgba(99,102,241,0.1)`

### Step 2: Create infra CSS variables in `:root`

```css
:root {
  /* ... existing theme vars ... */

  /* Infra (set explicitly per theme, not derived) */
  --navbar-bg: rgba(6,6,15,0.85);
  --navbar-bg-mobile: rgba(6,6,15,0.98);
  --sidebar-bg: rgba(6,6,15,0.6);
  --diagram-fill: rgba(6,6,15,0.3);
  --overlay-bg: rgba(0,0,0,0.6);
  --code-bg: rgba(99,102,241,0.1);
}
```

### Step 3: Add `@media (prefers-color-scheme: light)` block

```css
@media (prefers-color-scheme: light) {
:root {
  --bg-primary: #f5f6fa;
  --bg-secondary: #eef0f5;
  --bg-card: #ffffff;
  --bg-card-hover: #f0f1f5;
  --bg-elevated: #e2e4ec;
  --bg-input: #fafafa;
  --border: #d8dce6;
  --border-light: #c8cde0;
  --text-primary: #1a1a2e;
  --text-secondary: #4a4a6a;
  --text-muted: #8a8aaa;
  /* accent: #6366f1 — stays same, works in both modes */
  --accent-light: #4f46e5;  /* darker for contrast on white */
  --accent-glow: rgba(99,102,241,0.08);
  --accent-subtle: rgba(99,102,241,0.04);
  --shadow-card: 0 4px 24px rgba(0,0,0,0.06), inset 0 1px 0 rgba(255,255,255,0.8);
  --shadow-glow: 0 0 40px rgba(99,102,241,0.04);

  --navbar-bg: rgba(245,246,250,0.92);
  --navbar-bg-mobile: rgba(245,246,250,0.98);
  --sidebar-bg: rgba(255,255,255,0.7);
  --diagram-fill: rgba(0,0,0,0.05);
  --overlay-bg: rgba(0,0,0,0.3);
  --code-bg: rgba(99,102,241,0.06);
}
}
```

### Step 4: Replace all hardcoded references

Replace every `rgba(6,6,15,…)` / `rgba(0,0,0,0.6)` / `rgba(99,102,241,0.1)` with its corresponding `var(--…)`.

Example:
```css
/* BEFORE */
.navbar { background: rgba(6,6,15,0.85); }
.toc-overlay { background: rgba(0,0,0,0.6); }
code { background: rgba(99,102,241,0.1); }

/* AFTER */
.navbar { background: var(--navbar-bg); }
.toc-overlay { background: var(--overlay-bg); }
code { background: var(--code-bg); }
```

### Step 5: Verify

Open the file and toggle system dark/light. Key things to check:
1. Navbar is readable (not transparent-white on white)
2. Card shadows are visible (not overpowering in light mode)
3. SVG diagram backgrounds don't vanish
4. Code blocks have visible backgrounds in both modes
5. Accent colors on white don't create inaccessible contrast ratios
6. The hero gradient doesn't wash out

## Common Light Mode Colors (Guide)

| Token | Dark | Light |
|-------|------|-------|
| `--bg-primary` | `#06060f` | `#f5f6fa` |
| `--bg-secondary` | `#0a0a1a` | `#eef0f5` |
| `--bg-card` | `#0f0f24` | `#ffffff` |
| `--text-primary` | `#e8e8f0` | `#1a1a2e` |
| `--text-muted` | `#5e5e7e` | `#8a8aaa` |
| `--border` | `#1e1e4a` | `#d8dce6` |
| `--shadow-card` | `0 4px 24px rgba(0,0,0,0.4)` | `0 4px 24px rgba(0,0,0,0.06)` |
| `--accent-light` | `#818cf8` | `#4f46e5` |
