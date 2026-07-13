# Post-Patch Verification Checklist

After applying a batch of patches to a large HTML file (3+ patches in a multi-phase plan), do a **systematic verification pass** before declaring done. This catches the most common blind spots: missing theme variables, missing HTML attributes, and plan items that silently fell through the cracks.

## The 4-Step Verification Loop

```
For EACH affected area in the file:
  1. READ the patched lines back
  2. CROSS-REFERENCE against your plan/checklist
  3. SEARCH for missing companions (CSS vars in other themes, aria attrs, etc.)
  4. PATCH any gap found
```

## Verification Checklist

### 1. CSS Variable Completeness

- ✅ For every `--var` added to `:root` (dark mode): does `[data-theme="light"]` have it too?
- ✅ For every `--var` added to light mode: does `:root` already have it? (dark mode is usually the foundation)
- ✅ Do any hardcoded hex/rgba values remain that should be CSS variables? (Use `search_files` with a hex pattern like `#([0-9a-f]{3}|[0-9a-f]{6})\b`)

### 2. HTML Attribute Completeness

- ✅ Every modal `<div>` has `role="dialog" aria-modal="true" aria-labelledby="<id>"`
- ✅ Every `aria-labelledby` target element (`<h2 id="...">`) exists and is visible to screen readers OR uses a visually-hidden helper
- ✅ Every collapsible element has `aria-expanded="false"` on initial render
- ✅ Every navigation element has `aria-label`
- ✅ Every interactive container (filter bar, tablist) has `role="group"` or `role="tablist"`
- ✅ Toast/notification elements have `aria-live="polite"`
- ✅ Theme toggle button has dynamic `aria-label` updated on toggle
- ✅ Menu/sidebar toggle has `aria-label` on the button

### 3. Plan Coverage Gaps

- ✅ Re-read your plan/phases list against what was actually patched. Look for items that were accidentally skipped (e.g., `prefers-reduced-motion`, print styles, or accessibility items that got lost in the shuffle)
- ✅ Check item count: does the number of completed items match the original plan?

### 4. JS Function Completeness

- ✅ Every `data-action` value in the HTML has a matching `case` in the event delegation switch
- ✅ Theme toggle function updates the button's `aria-label` alongside its icon
- ✅ Sidebar toggle function updates `aria-expanded` alongside the `.open` class
- ✅ Toast creation sets `aria-live` attribute
- ✅ Keyboard listeners are bound, not inlined

## Real Session Example

This checklist emerged from a session where 7 phases (43 individual patches) were applied to a ~1,900-line HTML file. The verification pass found these gaps:

| Gap | Root Cause | Fix |
|-----|-----------|-----|
| Light mode missing `--border-hover` | Added `--border-hover` to `:root` but forgot `[data-theme="light"]` | Added `--border-hover: #ccc8be;` to light mode block |
| Mobile sidebar missing initial `aria-expanded="false"` | Only added aria-expanded update in toggleSidebar(), not on the HTML element | Added `aria-expanded="false"` to the `<nav>` in HTML |
| `prefers-reduced-motion` media query missing | Accessibility item was listed in the plan but never implemented | Added `@media (prefers-reduced-motion: reduce)` block |

Without the review pass, all three issues would have shipped — light-mode card hover borders invisible, mobile sidebar unannounced to screen readers, and motion-intolerant users getting full animations.
