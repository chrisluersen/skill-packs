# Social Meta Tags & Favicon

Adding Open Graph, Twitter Card, and favicon support to a self-contained HTML file so it looks good when shared on social media, messaging apps, and in browser tabs.

## When to add these

Any HTML doc that might be shared as a URL (opened in a browser rather than a local file). These tags tell social platforms, search engines, and browsers what title, description, image, and icon to show.

## Open Graph (OG)

5 tags needed for good social previews on Facebook, LinkedIn, Discord, Slack, and most chat apps:

```html
<meta property="og:title" content="Page Title">
<meta property="og:description" content="Concise 1-2 sentence summary of the page.">
<meta property="og:type" content="website">
<meta property="og:url" content="https://example.com/page">
<meta property="og:image" content="https://example.com/og-image.png">
```

**Rules:**
- `og:title` should match the `<title>` element
- `og:description` should match the `<meta name="description">` content — keep them in sync
- `og:type` is almost always `website` for documentation/reference pages
- `og:url` is the canonical URL — use the real deployment URL, not `localhost` or a file path
- `og:image` should point to a deployed image (typically 1200×630px). For self-contained files without a deployed image, use the same placeholder URL pattern — the consuming platform will show a broken image if the URL doesn't resolve, but the tag structure is still correct for scraping

## Twitter Card

4 tags for nice previews on Twitter/X:

```html
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="Page Title">
<meta name="twitter:description" content="Concise 1-2 sentence summary of the page.">
<meta name="twitter:image" content="https://example.com/og-image.png">
```

**Rules:**
- `twitter:card` is `summary_large_image` for image-rich preview (recommended) or `summary` for text-only
- Keep `twitter:title` and `twitter:description` in sync with OG equivalents — duplicating values is correct here
- `twitter:image` can re-use the OG image URL; no separate image needed

## Inline SVG Favicon

For self-contained files with no external assets, use a `data:` URI to embed an SVG favicon directly in the HTML:

```html
<link rel="icon" type="image/svg+xml" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'%3E%3Crect width='100' height='100' rx='20' fill='%236762ff'/%3E%3Ctext x='50' y='68' font-size='56' font-family='monospace' font-weight='bold' fill='white' text-anchor='middle'%3EH%3C/text%3E%3C/svg%3E">
```

**Parameters to customize:**
- `fill='%236762ff'` — the background color (URL-encoded hex, e.g. `#6762ff` → `%236762ff`)
- `font-size='56'` — letter size relative to the 100×100 viewBox
- `font-family='monospace'` — typeface for the initial letter
- `fill='white'` — letter color
- Text content (`H`) — change to the first letter or logo character of your brand

**Design guide for the letter:**
- A single letter or symbol works best at this viewBox size
- `rx='20'` gives rounded corners (20px radius on a 100×100 box)
- Center the text with `x='50'` and `text-anchor='middle'`; `y` positions vertically (68 is roughly centered for 56px font)

### Multi-resolution favicon (optional)

If you want to serve different sizes, add additional `<link>` tags pointing to external PNGs. For self-contained files, the inline SVG covers all modern browsers.

## Insertion point

All tags go in `<head>`, after the `<meta name="description">` tag and before `<style>`:

```html
<head>
    <meta charset="UTF-8">
    <title>Page Title</title>
    <meta name="description" content="...">
    <!-- Open Graph -->
    <meta property="og:title" content="...">
    ...
    <!-- Twitter Card -->
    <meta name="twitter:card" content="summary_large_image">
    ...
    <!-- Favicon -->
    <link rel="icon" type="image/svg+xml" href="data:image/svg+xml,...">
    <style>/* ... */</style>
</head>
```

## Verification

```bash
grep -c 'og:title' doc.html          # should be 1
grep -c 'twitter:card' doc.html      # should be 1
grep -c 'rel="icon"' doc.html        # should be >= 1
grep -c 'image/svg+xml' doc.html     # should be 1 (for inline SVG)
```

## Code Block Line Numbers

Adding optional line numbers to code blocks without changing the underlying HTML structure. Line numbers are generated at runtime by JS and toggled on/off via a button in the code block header.

### How it works

1. An `injectLineNumbers()` JS function splits each `.cb-body` div's innerHTML on newlines and wraps each line in a `<span class="cb-line" data-line="N">` element
2. CSS with `.show-lines` class on the parent `.code-block` shows line numbers via `::before` pseudo-elements
3. A `#` toggle button is injected into each `.cb-header` alongside the copy button

### JS function

```js
function injectLineNumbers() {
    document.querySelectorAll('.cb-body').forEach(function(body) {
        if (body.querySelector('.cb-line')) return;  // already processed
        var lines = body.innerHTML.split('\n');
        body.innerHTML = lines.map(function(line, i) {
            return '<span class="cb-line" data-line="' + (i + 1) + '">' + (line || ' ') + '</span>';
        }).join('\n');
    });
    document.querySelectorAll('.cb-header').forEach(function(header) {
        if (header.querySelector('.cb-ln-toggle')) return;  // already has toggle
        var btn = document.createElement('button');
        btn.className = 'cb-ln-toggle';
        btn.innerHTML = '#';
        btn.setAttribute('aria-label', 'Toggle line numbers');
        btn.setAttribute('title', 'Toggle line numbers');
        btn.addEventListener('click', function(e) {
            e.stopPropagation();
            var block = header.closest('.code-block');
            if (block) { block.classList.toggle('show-lines'); btn.classList.toggle('active'); }
        });
        var right = header.querySelector('.cb-header-right');
        if (right) {
            right.insertBefore(btn, right.firstChild);  // before lang + copy
        } else {
            header.appendChild(btn);
        }
    });
}
```

### CSS

```css
.code-block.show-lines .cb-body span.cb-line {
    display: block; padding-left: 3.5em; position: relative; min-height: 1.4em;
}
.code-block.show-lines .cb-body span.cb-line::before {
    content: attr(data-line);
    position: absolute; left: 0; width: 2.8em;
    text-align: right; padding-right: 0.6em;
    color: var(--fg-muted); font-size: 0.85em;
    opacity: 0.6; user-select: none;
}
.cb-ln-toggle {
    background: none;
    border: 1px solid var(--border-default);
    color: var(--fg-muted); cursor: pointer;
    font-size: 0.75em; padding: 0.1em 0.4em;
    border-radius: 3px; margin-left: 0.3em;
    line-height: 1.4; opacity: 0.6;
    transition: opacity 0.15s;
}
.cb-ln-toggle:hover { opacity: 1; }
.cb-ln-toggle.active { border-color: var(--accent-primary); color: var(--accent-primary); opacity: 1; }
```

### Wiring into load handler

Call after `injectCopyButtons()`:

```js
window.addEventListener('load', function() {
    injectCopyButtons();
    injectLineNumbers();
    buildMobileSidebar();
    // ... rest of init
});
```

### DOM structure expected

Line numbers work with this code block HTML structure:

```html
<div class="code-block">
    <div class="cb-header">
        <span class="cb-dot green"></span> Language
        <span class="cb-lang">bash</span>
    </div>
    <div class="cb-body">code line 1
code line 2    <span class="c-com"># comment</span>
code line 3</div>
</div>
```

### How users interact

- Click the `#` button in any code block header to toggle line numbers on/off
- Active state shows a highlighted `#` button (accent-color border)
- Line numbers are `:before` pseudo-elements — not selectable, no copy-paste contamination
- State is per-block (not global), so each code block can be toggled independently

### Pitfalls

- **Runtime generation** — `data-line` attributes don't exist in the static HTML. They're created by `injectLineNumbers()` when the page loads. `grep` for them in the HTML file will only find the JS template string
- **Call order** — `injectLineNumbers()` must run after the DOM is ready and after `injectCopyButtons()` (since the toggle button slots into `.cb-header-right` which is created by `injectCopyButtons`). Always call it after the copy-button injection
- **Multi-line `<span>` content** — the `\n` split preserves existing syntax highlighting spans (e.g. `<span class="c-key">hermes</span>`) as long as they don't span lines. If a span does span a line break, it will be broken by the split
- **Empty lines** — `(line || ' ')` ensures empty lines still get a span (with a space) so line counting remains accurate
