# onclick → data-action Event Delegation Refactoring

A practical workflow for migrating an existing HTML page from inline `onclick`/global functions to event delegation via `data-action` attributes. Based on a real 47-function, 290-line JS refactor of a 118KB doc.

## When to use this

- The page has 30+ `onclick="fn()"` attributes scattered across HTML
- Global `window.fn = function...` assignments pollute the namespace
- You want all interactions discoverable in one place
- The page has modals (QJ, shortcuts), copy buttons, filters, theme toggle, sidebar nav, and back-to-top

## Step 1: Audit all onclick

```bash
grep -n 'onclick=' your-file.html | wc -l
grep -n 'onclick=' your-file.html
```

This gives you every interaction to convert and the count. Note any that pass arguments (`onclick="applyFilter('stacks')"`) — those need `data-*` attributes.

## Step 2: Add data-action attributes to HTML

Replace each inline onclick with the equivalent data-action pattern:

| onclick | data-action |
|---------|-------------|
| `onclick="toggleSB()"` | `data-action="toggle-sidebar"` |
| `onclick="toggleTheme()"` | `data-action="toggle-theme"` |
| `onclick="openKS()"` | `data-action="open-shortcuts"` |
| `onclick="scrollToTop()"` | `data-action="scroll-top"` |
| `onclick="applyFilter('stacks')"` | `data-action="apply-filter" data-filter-val="stacks"` |
| `onclick="copySectionLink('my-section')"` | `data-action="copy-link" data-section="my-section"` |
| `onclick="closeQJ()"` | `data-action="close-qj"` |
| `onclick="switchQJTab('sections')"` | `data-action="switch-tab" data-qj="sections"` |

## Step 3: Write the event delegation handler

Replace all `window.*` function assignments with a single click handler:

```js
document.addEventListener('click', function(e) {
  var el = e.target.closest('[data-action]');
  if (!el) return;
  var action = el.getAttribute('data-action');

  switch (action) {
    case 'toggle-sidebar': toggleSidebar(); break;
    case 'toggle-theme': toggleTheme(); break;
    case 'open-shortcuts': openKS(); break;
    case 'scroll-top': window.scrollTo({ top: 0, behavior: 'smooth' }); break;
    case 'apply-filter':
      applyFilter(el.getAttribute('data-filter-val'));
      e.preventDefault();
      break;
    case 'copy-link':
      copySectionLink(el.getAttribute('data-section'));
      e.preventDefault();
      break;
    case 'close-qj': closeQJ(); e.preventDefault(); break;
    case 'close-ks': closeKS(); e.preventDefault(); break;
    case 'switch-tab':
      switchQJTab(el.getAttribute('data-qj'));
      e.preventDefault();
      break;
    case 'show-all':
      applyFilter('all');
      e.preventDefault();
      break;
  }
});
```

**Use `e.preventDefault()` when the element is an `<a href="#">`** — otherwise the page scrolls to top.

## Step 4: Convert JS-generated HTML

Search for `onclick=` in JS string concatenations (QJ results, filter summary links):

```js
// Before — inline onclick in generated HTML
h:'<a href="#" onclick="closeQJ();return false">' + name + '</a>'

// After — data-action on generated link
h:'<a href="#" data-action="close-qj">' + name + '</a>'
```

Also update `innerHTML`-based "Show all" / reset links:
```js
// Before
fs.innerHTML = 'Showing N sections. <a onclick="applyFilter(\'all\')">Show all</a>';

// After
fs.innerHTML = 'Showing N sections. <a data-action="show-all" href="#">Show all</a>';
```

## Step 5: Rewrite all `window.*` to local functions

| Before (global) | After (local to IIFE) |
|-----------------|----------------------|
| `window.toggleSB = function()` | `function toggleSidebar()` |
| `window.applyFilter = function(tag)` | `function applyFilter(tag)` |
| `window.openQJ = function()` | `function openQJ()` |
| `window.closeQJ = function()` | `function closeQJ()` |
| `window.switchQJTab = function(tab)` | `function switchQJTab(tab)` |
| `window.openKS = function()` | `function openKS()` |
| `window.closeKS = function()` | `function closeKS()` |
| `window.copySectionLink = function(id)` | `function copySectionLink(id)` |
| `window.showToast = function(msg)` | `function showToast(msg)` |
| `window.scrollToTop = function()` | Removed — handled by `data-action="scroll-top"` |

All go inside `;(function() { 'use strict'; ... })();`.

## Step 6: Debounce input handlers

Input handlers (QJ search, live filters) should be debounced — not just scroll:

```js
// Before — fires on every keystroke
input.addEventListener('input', function() { renderQJ(this.value); });

// After — 200ms debounce
var qjTimer = null;
input.addEventListener('input', function() {
  var val = this.value;
  clearTimeout(qjTimer);
  qjTimer = setTimeout(function() { renderQJ(val); }, 200);
});
```

## Verification

After conversion, verify:
1. `grep -c 'onclick='` returns 0 (ignoring commented code)
2. All `data-action` values are covered in the switch statement
3. No `window.fn = function` assignments remain
4. Modals still open/close, filters still work, copy buttons still copy
5. Enter key in QJ still clicks the first result (check the keydown handler calls `e.preventDefault()` to prevent double-firing)

## Pitfalls

- **Links in generated HTML with `href="#"`** need `e.preventDefault()` in the delegation handler, or the page scrolls to top on click
- **QJ Enter-key handler** needs `e.preventDefault()` — without it, the `data-action` handler fires AND the browser follows the `href="#"` link
- **Overlay clicks** for closing modals — use `data-action="close-qj"` on the overlay div, handled by delegation
- **Code block copy buttons** attach their own `addEventListener('click', ...)` to preserve `e.stopPropagation()` — keep these as direct listeners; they don't go through event delegation
