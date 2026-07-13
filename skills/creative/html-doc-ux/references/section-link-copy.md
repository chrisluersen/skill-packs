# Section Link Copy

Add a clickable link/copy button to each section heading that copies the direct URL (with `#section-id` hash) to the clipboard, with visual feedback.

## Pattern: Section heading link

### HTML

```html
<h2 id="section-$01">
    <span class="section-num">$01</span>
    Architecture &amp; Core Components
    <a class="section-link" href="#section-$01" onclick="copySectionLink('section-$01');return false;" title="Copy section link">#</a>
</h2>
```

The `#` anchor after the heading text serves as both a visual copy target and a working hash link (degrades gracefully on JS-disabled browsers — clicking scrolls to the section).

### CSS

```css
/* Section header copy link */
.section-link {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    text-decoration: none;
    color: var(--fg-tertiary);
    font-size: 16px;
    margin-left: 6px;
    opacity: 0;
    transition: opacity 0.15s, color 0.15s;
    width: 24px;
    height: 24px;
    border-radius: 4px;
}
/* Show on heading hover — common UX pattern */
h2:hover .section-link,
h3:hover .section-link {
    opacity: 0.5;
}
.section-link:hover {
    opacity: 1 !important;
    color: var(--accent-primary);
    background: rgba(128, 128, 128, 0.08);
}
/* Always-visible variant (good for reference docs) */
.section-link.always {
    opacity: 0.35;
}
.section-link.always:hover {
    opacity: 1;
}
```

### JavaScript

```javascript
/* ---- Copy section link (with iOS fallback + toast) ---- */
window.copySectionLink = function(id) {
    const url = window.location.href.split('#')[0] + '#' + id;
    if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(url).catch(() => fallbackCopy(url));
    } else {
        fallbackCopy(url);
    }
    showToast('✓ Link copied');
};
function fallbackCopy(text) {
    const ta = document.createElement('textarea');
    ta.value = text;
    ta.style.position = 'fixed';
    ta.style.opacity = '0';
    document.body.appendChild(ta);
    ta.select();
    try { document.execCommand('copy'); } catch(e) {}
    document.body.removeChild(ta);
}
```

### Copy Toast (visual feedback)

Clipboard writes are silent — the user gets no feedback without this toast pattern. Add it to every `copySectionLink` handler:

```css
/* --- Copy toast --- */
.toast {
    position: fixed;
    bottom: 24px;
    left: 50%;
    transform: translateX(-50%) translateY(80px);
    background: var(--bg-elevated);
    border: var(--border-strong);
    color: var(--fg-primary);
    padding: 8px 16px;
    border-radius: var(--radius-pill);
    font-size: 13px;
    font-weight: 500;
    box-shadow: var(--shadow-lg);
    opacity: 0;
    transition: all 0.25s cubic-bezier(0.22, 1, 0.36, 1);
    z-index: 300;
    pointer-events: none;
    white-space: nowrap;
}
.toast.show {
    opacity: 1;
    transform: translateX(-50%) translateY(0);
}
```

```javascript
/* ---- Copy toast (confirmation popup) ---- */
window.showToast = function(msg) {
    var t = document.getElementById('copyToast');
    if (!t) {
        t = document.createElement('div');
        t.id = 'copyToast';
        t.className = 'toast';
        t.innerHTML = '<span class="toast-icon">✓</span> <span class="toast-msg"></span>';
        document.body.appendChild(t);
    }
    t.querySelector('.toast-msg').textContent = msg.replace('✓ ','');
    t.classList.add('show');
    clearTimeout(t._hide);
    t._hide = setTimeout(function(){ t.classList.remove('show'); }, 2000);
};
```

## Key constraints

- See `references/clipboard-fallback.md` for full iOS clipboard details
- **Hover-only visibility** (`opacity: 0` → `opacity: 0.5` on `h2:hover`) keeps the UI clean for reading. Users discover the copy feature naturally when they hover over a heading.
- **Graceful degradation** — the `href="#section-id"` makes the link work as a standard anchor even without JS. JS just adds clipboard copy on top.
- **`return false`** in `onclick` prevents the anchor from also navigating (which would cause a page jump AND a clipboard write — disorienting)
- For reference docs where copy-links are primary UX (not decorative), use the `.always` variant for persistent low-opacity visibility
