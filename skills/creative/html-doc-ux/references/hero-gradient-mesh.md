# Hero Section Gradient Mesh

A subtle multi-gradient overlay behind the hero title text using a `::before` pseudo-element — adds visual depth without adding extra DOM elements. Used by Linear, Vercel, and Stripe docs to give hero sections a polished, dimensional feel.

## Pattern

### CSS

```css
/* Hero container: clip overflow, establish positioning context */
.hero {
    position: relative;
    overflow: hidden;
}

/* Gradient mesh via pseudo-element */
.hero::before {
    content: '';
    position: absolute;
    inset: 0;
    background:
        radial-gradient(ellipse 600px 400px at 20% 30%, rgba(103,98,255,0.06), transparent),
        radial-gradient(ellipse 500px 500px at 80% 70%, rgba(52,211,153,0.04), transparent);
    pointer-events: none;
    z-index: 0;
}

/* Push content above the pseudo overlay */
.hero > * {
    position: relative;
    z-index: 1;
}
```

### Variant: Single accent glow

```css
.hero::before {
    content: '';
    position: absolute;
    top: -20%;
    left: 50%;
    transform: translateX(-50%);
    width: 600px;
    height: 400px;
    background: radial-gradient(ellipse, var(--accent-primary) 0%, transparent 70%);
    opacity: 0.08;
    pointer-events: none;
    z-index: 0;
}
```

### Variant: Three-point mesh (wider coverage)

```css
.hero::before {
    content: '';
    position: absolute;
    inset: 0;
    background:
        radial-gradient(ellipse 500px 500px at 15% 20%, rgba(103,98,255,0.06), transparent),
        radial-gradient(ellipse 500px 500px at 85% 30%, rgba(52,211,153,0.04), transparent),
        radial-gradient(ellipse 300px 300px at 50% 80%, rgba(245,166,35,0.03), transparent);
    pointer-events: none;
    z-index: 0;
}
```

## Adding to an existing document

### Patch strategy

If the hero section already has a `.hero` class, the patch is small — just insert the CSS before `</style>`:

```css
/* Hero gradient mesh */
.hero { position: relative; overflow: hidden; }
.hero::before {
    content: ''; position: absolute; inset: 0;
    background:
        radial-gradient(ellipse 600px 400px at 20% 30%, rgba(103,98,255,0.06), transparent),
        radial-gradient(ellipse 500px 500px at 80% 70%, rgba(52,211,153,0.04), transparent);
    pointer-events: none; z-index: 0;
}
.hero > * { position: relative; z-index: 1; }
```

**Safe with existing CSS** — if `.hero` already has `position: relative`, the second declaration is harmless (same value, no specificity conflict). The patch will match `.hero { position: relative; ... }` or any existing block.

**Do NOT add `position: relative` twice** — if `.hero` already has it, only add the `overflow: hidden` alongside the `::before` rule.

### When to use

- The page has a hero or intro section with a title, subtitle, and quick-link row
- The hero feels flat — a subtle glow behind the title creates depth
- The doc has dark/light theme variables; use `rgba()` with low opacity (0.02–0.08) so the glow works in both themes naturally
- The hero has a `.grad` (gradient text) class — radial mesh behind gradient text creates a polished layered effect

### When NOT to use

- The hero has an explicit background image or pattern that would conflict with the pseudo-element
- The document has very few sections (3-4) and doesn't need the hero to feel weighted
- The user specifically asked for minimal styling

## Key constraints

- **`z-index` layering is critical** — `::before` gets `z-index: 0`, all direct children of `.hero` get `z-index: 1`. Without this, the pseudo element sits on top of the text, blocking hover/click events (or worse, making text invisible).
- **`pointer-events: none`** — prevents the gradient from intercepting clicks on hero links/buttons.
- **Low opacity values** — 0.02–0.08 for dark themes, 0.04–0.12 for light themes. The mesh should be *felt*, not seen. If the user can describe it, it's too dark.
- **CSS variables for accent colors** — prefer `var(--accent-primary)` on the radial gradient color for automatic theme adaptation. Fall back to `rgba(r, g, b, 0.06)` if the doc doesn't have accent variables.
- **`overflow: hidden`** — clips the blur edges of radial gradients so they don't bleed past the hero container. Only add if `::before` content would otherwise overflow.
- **Compatible with stagger entrance animations** — the `::before` is part of `.hero` and animates with it. No extra timing needed.
- **Light theme adjustment** — if the doc has `[data-theme="light"]`, the mesh may need different opacity or position. Either reference the same low values (they work because light backgrounds have enough contrast) or add a light-theme override.
