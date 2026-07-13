# Cross-Dimension Quality Audit

Extends the **Design Audit** workflow with 6 additional quality dimensions beyond visual/CSS: **accessibility, UX polish, performance, semantic HTML, JS behavior, and content structure.** Use when the user asks for "even more changes" or wants a comprehensive review, not just visual polish.

## When to use this

- User says "look for even more changes to improve the file"
- You've already done a design audit and they want breadth, not depth
- The page is content-heavy (docs, reference, guide) and needs a full quality pass
- The user is a UX/UI designer or quality-conscious — they'll notice gaps

## Workflow

### Phase 1: Read and understand the full artifact

Read the file in segments to understand CSS, HTML structure, and JS:

```
read_file(path, offset=1, limit=350)       # CSS custom properties, responsive, animations
read_file(path, offset=350, limit=500)     # HTML sections (hero, stat rows, filter bar, cards)
read_file(path, offset=850, limit=500)     # Remaining sections + table/ecosystem content
read_file(path, offset=1350, limit=600)    # Trailing sections + JS
```

Key signals to extract:
- CSS custom properties (`:root` + theme override)
- Section structure and naming pattern
- JS event delegation pattern (IIFE? `data-action`? global functions?)
- Component classes (stat-card, card, code-block, hl-box, section-nav)
- Responsive breakpoints
- Mobile layout strategy (sidebar, hamburger)

### Phase 2: Audit across 7 dimensions

For each dimension, run through the checklist and compile findings into a table with Issue #, Issue description, and Fix description.

#### 1. Accessibility
| Checklist Item | How to Check |
|---|---|
| Focus-visible styles | Search CSS for `:focus-visible` |
| ARIA roles on modals | Look for `role="dialog"` on QJ/KS modals |
| ARIA-expanded on toggles | Check sidebar menu button |
| ARIA-current on active nav | Check sidebar link active state |
| Focus trapping in modals | Tab should cycle within modal |
| prefers-reduced-motion | Check for `@media (prefers-reduced-motion)` |
| aria-label on icon-only buttons | Check theme, menu, copy buttons |
| Skip-to-content link | Check if first focusable element is a skip link |
| Screen reader modals | Check `aria-labelledby` / `aria-describedby` on dialogs |
| Table semantics | Check for `<thead>` / `<tbody>` wrappers |

#### 2. UX Polish
| Checklist Item | How to Check |
|---|---|
| scroll-padding-top | Search CSS for `scroll-padding-top` — needed when header is fixed |
| Desktop sidebar active tracking | Does desktop have IntersectionObserver or only mobile? |
| Theme transition | Is theme switch instant or smooth? |
| QJ arrow-key navigation | Can user arrow through search results? |
| Filter empty state | When filter shows 0 items, is there a friendly message? |
| Stat card animations | Do numbers animate on scroll into view? |
| Reading position indicator | Is there a progress bar or reading dock? |
| Back-to-top button | Does it fade in after scrolling past hero? |
| Copy link feedback | Where's the toast positioned? Works on mobile? |

#### 3. Visual
| Checklist Item | How to Check |
|---|---|
| Unused CSS classes/IDs | Search HTML for classes declared in CSS but unused |
| Hero glow elements with no CSS | Look for `.glow`, `.hero-glow`, etc. in HTML but not styled |
| Card hover depth | Is there `box-shadow` + `translateY` on card hover? |
| Modal backdrop blur | Could overlay use `backdrop-filter: blur(2px)`? |
| Theme toggle icon swap | Does sun/moon icon match the current theme? |
| Code block polish | Header dots, language label, copy button, syntax tokens |

#### 4. Performance
| Checklist Item | How to Check |
|---|---|
| content-visibility: auto on off-screen sections | Search CSS for `content-visibility` |
| CSS containment | Check for `contain: layout style` on cards |
| Google Fonts preconnect | If using web fonts, check for `<link rel="preconnect">` |
| Passive scroll listeners | Check `{ passive: true }` on scroll/wheel handlers |
| Debounced input handlers | Check QJ input has setTimeout debounce |

#### 5. Semantic HTML
| Checklist Item | How to Check |
|---|---|
| `<header>` / `<nav>` / `<main>` / `<footer>` elements | Are semantic tags used or divs? |
| `aria-label` on navigation elements | `<nav aria-label="Table of contents">` |
| `role="group"` on filter bars | `<div role="group" aria-label="Filter sections">` |
| `<article>` for cards | Or are cards just `<div class="card">`? |
| Table structure | `<thead>`, `<tbody>`, `<th scope="col/row">` |

#### 6. JS Behavior
| Checklist Item | How to Check |
|---|---|
| Focus restoration on modal close | Does focus return to trigger element? |
| prefers-color-scheme auto-detect | Check if localStorage check also reads OS preference |
| Body scroll lock | Does mobile sidebar toggle add `overflow: hidden` to body? |
| aria-live on dynamic content | Toast, filter summary should use `aria-live="polite"` |
| Event delegation pattern | Single listener or scattered listeners? |
| IIFE wrapping | All code in `;(function() { 'use strict'; ... })();`? |

#### 7. Content Structure
| Checklist Item | How to Check |
|---|---|
| Section numbering consistency | Do sidebar numbers match section badges match section-nav? |
| Filter tag coverage | Every section has `data-filter-tag` matching the filter bar? |
| Section-nav prev/next chains | Each section's prev/next correctly chains through all sections? |
| Quick-jump data array | Does the JS array include ALL sections? |
| Stat counters accuracy | Do section counts / stat values match actual content? |

### Phase 3: Prioritize

Rank all findings into a top-N list. Use this weighting:

| Score | Criteria | Example |
|---|---|---|
| Critical | Bug-level: broken UX, inaccessible, wrong data | scroll-padding missing, no focus-visible, stat count wrong |
| High | Visible quality gap that a designer/power user will notice | No theme transition, desktop sidebar not tracking |
| Medium | Nice-to-have with clear benefit | QJ arrow keys, stat card animation, backdrop blur |
| Low | Polishing that only matters for QA | Unused CSS class, minor semantic improvement |

### Phase 4: Present findings — DO NOT start patching yet

Use this format — one table per dimension, then a final top-N ranking table:

```
## Accessibility (N items)
| # | Issue | Fix |
|---|-------|-----|
| 1 | Issue description | One-line fix description |

## UX Polish (N items)
...
## Top 10 Most Valuable to Add

Ranked by value/effort ratio. Include exact CSS/JS values.
```

### Phase 5: Get user sign-off before any execution

**CRITICAL: Present the complete findings for discussion before applying a single patch.** Do not ask "shall I apply these" while already writing code.

The user may want to:
- Reorder priorities (e.g. content audit before visual polish)
- Skip certain items (e.g. they don't care about print styles)
- Add entirely new workstreams they thought of while reading your audit
- Give feedback on your proposed fix approach (different CSS values, different technique)

**Presentation format:** Organize into workstreams/phases with clear cost/benefit, then ask "does this match what you're looking for? Any changes before I start?"

Only begin patching after the user explicitly confirms.
Ask if the user wants these applied immediately or saved as a plan. If they're mid-session and already have a plan document, offer to append as additional phases.

## Pitfalls

- **Don't re-audit what the design audit already covered** — the existing `design-audit-improvement.md` handles CSS variables, typography, backgrounds, borders, light mode, and card hover. This reference is additive to that one.
- **Don't report the same issue twice** — some issues span dimensions (e.g. missing aria-label is both accessibility and UX). Pick the primary dimension and note the cross-reference.
- **Don't skip the top-N ranking** — a flat list of 30 items overwhelms the user. The top-10 frame makes the audit actionable.
- **Don't write fix descriptions that say "fix it" without specifics** — every fix should include exact CSS/JS (e.g. `html { scroll-padding-top: calc(var(--header-h) + 16px); }`).
- **Test in both themes** — issues often only appear in one mode (light-mode invisible backgrounds, dark-mode invisible borders).
- **Read the full file before auditing** — partial reads miss issues in the last third (often where JS or mobile sidebar generation lives).
- **Check existing patterns first** — if the file already follows `html-application-building` patterns (IIFE, data-action, CSS vars), some dimensions may already be clean. Don't audit for the sake of it.

## Related

- `design-audit-improvement.md` — the companion design/CSS-only audit (this file extends it)
- `onclick-to-event-delegation.md` — migrating inline onclick to data-action (frequently needed if JS audit finds global functions)
- `theming-light-dark.md` — light/dark theme conversion guide (needed if visual audit finds hardcoded colors)
