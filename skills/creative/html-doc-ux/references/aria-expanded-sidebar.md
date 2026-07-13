# aria-expanded for Sidebar Navigation

Pattern for adding `aria-expanded` state to both desktop (persistent) and mobile (toggleable) sidebars. `aria-expanded` communicates to assistive technology whether a collapsible region is open or closed.

## Desktop sidebar

A desktop sidebar that is always visible on wide screens gets `aria-expanded="true"` — it's always expanded, never collapsed on desktop:

```html
<nav class="sidebar" id="sidebarDesktop" aria-expanded="true">
    ...
</nav>
```

The desktop sidebar does not toggle at desktop widths — it's a persistent landmark. The `aria-expanded="true"` simply confirms to screen readers that the navigation region is fully available.

## Mobile sidebar toggle

The toggle button (typically a hamburger ☰ menu icon) gets `aria-expanded="false"` initially (mobile sidebar starts hidden):

```html
<button class="menu-btn" data-action="toggle-sidebar"
        aria-label="Toggle sidebar"
        aria-expanded="false">☰</button>
```

## JS: toggle aria-expanded with sidebar state

Update the button's `aria-expanded` whenever the sidebar opens or closes:

```javascript
function toggleSidebar() {
    var sb = document.getElementById('sidebarMobile');
    var ov = document.getElementById('sbOverlay');
    var btn = document.querySelector('.menu-btn');
    if (sb) {
        sb.classList.toggle('open');
        if (btn) btn.setAttribute('aria-expanded', sb.classList.contains('open'));
    }
    if (ov) ov.classList.toggle('open');
}
```

This pattern:
- Reads the sidebar's actual state via `classList.contains('open')` — no need for a redundant state variable
- Sets `aria-expanded` to `"true"` when the sidebar is open, `"false"` when closed
- Works regardless of how many times `toggleSidebar` is called (idempotent)

## Why on the button, not the nav

`aria-expanded` belongs on the **control element** (the button that toggles the panel), not the panel itself. The button tells the screen reader: "this button controls an expandable region, and that region is currently open/closed." The sidebar nav itself should be a `<nav>` landmark — its expanded/collapsed state is communicated by the button.

## Pitfalls

- **`aria-expanded` on button, not nav** — put `aria-expanded` on the toggle button, not the sidebar `<nav>`. The desktop sidebar can carry `aria-expanded="true"` as a static attribute to indicate it's always open, but the dynamic state lives on the button.
- **Coercing to string** — `setAttribute` expects a string value. `"true"` and `"false"` are strings, not booleans. Do NOT use `.setAttribute('aria-expanded', true)` — that produces the string `"true"` in practice but explicit strings are clearer.
- **Initial state mismatch** — if the mobile sidebar starts hidden (no `.open` class), the button must start with `aria-expanded="false"`. If the JS on load re-checks and synchronizes, make sure the initial HTML attribute is correct for the no-JS case.
- **No-JS fallback** — when JS is disabled, the button's `aria-expanded="false"` tells screen readers the sidebar is collapsed, but there's no JS to open it. Add `.no-js [data-action="toggle-sidebar"] { display: none !important }` to hide the toggle button entirely when JS is off.
