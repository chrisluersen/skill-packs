# Phase-Gated Progressive Refactoring for Large HTML Docs

This workflow emerged from the `AI Architecture.html` (178KB, 2600+ lines) 11-phase refactor (A→K). It prevents the common failure mode: jumping into patches without a full picture, then getting redirected when the user sees gaps.

## The Core Problem

Users with strong design/UX taste **will notice gaps you missed** and want to redirect you. Presenting the full plan first surfaces those gaps *before* you've burned time on patches that need undoing. It also gives the user agency — they're directing the work, not just watching it happen.

## Phase 0: Comprehensive Audit + User Alignment (MANDATORY)

**Do NOT start patching until this phase is complete.**

### Steps

1. **Read the entire file** in segments (CSS → HTML sections → JS) to understand every component
2. **Audit across ALL dimensions** — use the checklist below
3. **Compile a top-N ranked plan** organized by phase — include exact CSS/JS values and `old_string`/`new_string` anchors for each patch
4. **PRESENT the plan to the user for discussion before executing anything**
   - Use a table format showing each workstream, its scope, and effort level
   - Flag which changes are structural (affect content order) vs cosmetic (independent)
   - Ask "does this match what you're looking for? Any changes before I start?"
5. **Accept user input on priorities** — they may want to reorder, skip, or add workstreams

### Multi-Dimension Audit Checklist

| Dimension | What to Check |
|-----------|---------------|
| **Accessibility** | ARIA roles/labels, focus order, prefers-reduced-motion, semantic HTML, color contrast (WCAG AA), skip links, screen reader announcements |
| **UX Polish** | scroll-padding, modals (focus trap, escape close), keyboard nav, filter UX, toast notifications, scroll progress |
| **Visual** | Unused CSS, hover/focus effects, theme consistency, dark/light parity, border system, spacing scale |
| **Performance** | content-visibility, passive listeners, debounced handlers, will-change, contain, external resources, file size |
| **Semantic HTML** | `<header>`, `<nav>`, `<main>`, `<footer>`, `<section>` with ids, table semantics (`<thead>`, `<tbody>`), heading hierarchy |
| **JS Behavior** | IIFE pattern (zero globals), event delegation (data-action), focus trapping, localStorage safety, debounce, no inline onclick |
| **Content Structure** | Section numbering continuity, filter tags on every section, nav chain (prev/next), Quick Jump array sync |

### Phase Ordering Strategy

Apply phases in this order so anchors don't shift under later patches:

| Order | Layer | What | Why |
|-------|-------|------|-----|
| 1 | CSS vars | Typography, color tokens, border system | Foundation — everything CSS depends on these |
| 2 | Structural CSS | Background rgba, border, hero glow, z-index | Visual foundation |
| 3 | Layout CSS | Section spacing, card rules, grids, breakpoints | Building-block styles |
| 4 | Light/dark mode | Opposite theme palette, infra backgrounds | Needs all style vars defined |
| 5 | Visual quick wins | Progress bar height, stat hover, stagger timing, glow dot | Independent refinements |
| 6 | HTML changes | Modals, nav, buttons, aria attributes | Structural — do after CSS |
| 7 | JS changes | Theme toggle, sidebar aria-expanded, keyboard, toast | Last — operates on elements from step 6 |
| 8 | A11y + cleanup | focus-visible, prefers-reduced-motion, CSS var audit, print | Independent final pass |

**Golden rule:** Never patch content above a future anchor. CSS vars (top of file) are safe at any time. HTML in the middle moves anchors below it — batch those together.

## Workflow: search_files + read_file + patch

Do NOT read the whole file. Find anchors surgically:

1. `search_files(target="content", path="doc.html", pattern="--border-default:")` — find the line
2. `read_file(path="doc.html", offset=N, limit=3)` — confirm surrounding context
3. `patch(path="doc.html", old_string="...", new_string="...")` — replace with enough surrounding lines for uniqueness

## Phase Tracking

Use `todo` with status markers for multi-phase plans. The list survives context compaction so you resume cleanly after interruptions or tool-call limits.

## Mid-Batch Discovery Pitfall

If the user says "yes go ahead" but you notice additional improvement opportunities WHILE patching, do NOT stop mid-stream to flag them. Note them in your todo list, finish the current batch, then after the batch say "I noticed X more items while working — want me to add those?" Bringing up new items mid-batch derails focus and forces the user to context-switch.

## Pitfalls

- **Budget batching** — 8+ single-tool patches eat the turn limit fast. Batch many patches in a single `execute_code` call.
- **Anchor drift** — every `patch` shifts line numbers. Re-find with `search_files`, don't trust remembered offsets.
- **Stale reads** — re-read after nearby patches; offset/limit reads don't auto-update.
- **Parallel safety** — different file sections (CSS line 20 + CSS line 200) can patch in parallel. Same-section patches must be sequential.
- **CSS var audit last** — after all changes, search for hardcoded hex/rgba values that should be variables.
- **Scope creep** — if the user adds items mid-stream, explicitly confirm: "This adds N more patches to phase X. Continue?"

## Verification After Each Phase

Run the verification scripts from the main skill (CSS Responsive Audit, JS Structural Verification, Performance Audit, Lighthouse-Style Audit) after each major phase. Do NOT skip — the cost of finding a regression in phase K that was introduced in phase C is enormous.

## Backup Protocol

After each verified phase:
```bash
cp "doc.html" "backup/path/doc.html"
```

Use the cron job from `references/backup-cron-pattern.md` for automatic backups during long sessions.