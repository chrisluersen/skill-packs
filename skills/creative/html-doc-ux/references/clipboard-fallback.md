# iOS-safe Clipboard Fallback

`navigator.clipboard.writeText()` only works in secure contexts (HTTPS or localhost). On HTTP pages (common for local file:// or intranet HTML docs), it throws. This pattern falls back silently to the legacy `document.execCommand('copy')` via a hidden textarea.

## Pattern: Universal copy function

```javascript
/* ---- Copy section link (with iOS fallback) ---- */
window.copySectionLink = function(id) {
    const url = window.location.href.split('#')[0] + '#' + id;
    if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(url).catch(() => fallbackCopy(url));
    } else {
        fallbackCopy(url);
    }
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

## Pattern: Code block copy button

```javascript
/* ---- Copy code block content ---- */
window.copyCodeBlock = function(btn) {
    const codeBlock = btn.closest('.code-block');
    const code = codeBlock.querySelector('code')?.textContent || '';
    doCopy(code, btn);
};
function doCopy(text, btn) {
    if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text)
            .then(() => flashCopied(btn))
            .catch(() => execCopy(text, btn));
    } else {
        execCopy(text, btn);
    }
}
function execCopy(text, btn) {
    const ta = document.createElement('textarea');
    ta.value = text;
    ta.style.position = 'fixed';
    ta.style.opacity = '0';
    document.body.appendChild(ta);
    ta.select();
    try { document.execCommand('copy'); flashCopied(btn); } catch(e) {}
    document.body.removeChild(ta);
}
function flashCopied(btn) {
    const orig = btn.textContent;
    btn.textContent = '✓';
    btn.style.color = 'var(--accent-primary)';
    setTimeout(() => {
        btn.textContent = orig;
        btn.style.color = '';
    }, 1200);
}
```

## Button HTML

```html
<button class="cb-copy" onclick="copyCodeBlock(this)" title="Copy code" aria-label="Copy code">📋</button>
```

Place this at the end of each `.cb-header` div in the code block.

## CSS for the button

```css
.cb-copy {
    margin-left: auto;
    background: none;
    border: none;
    color: var(--fg-tertiary);
    cursor: pointer;
    font-size: 13px;
    padding: 2px 6px;
    border-radius: 4px;
    transition: color 0.15s, background 0.15s;
    line-height: 1;
}
.cb-copy:hover {
    color: var(--fg-primary);
    background: rgba(128,128,128,0.1);
}
```

## Key constraints

- **Do NOT feature-detect `navigator.clipboard` with just a truthy check** — `navigator.clipboard` exists on iOS but `writeText` throws. Use `navigator.clipboard && navigator.clipboard.writeText` and always `.catch()`.
- The `textarea` approach requires the element to be in the DOM (`appendChild`) for `execCommand('copy')` to work
- `opacity: 0` + `position: fixed` keeps the textarea accessible but invisible — don't use `display: none` as `execCommand` won't work on hidden elements
