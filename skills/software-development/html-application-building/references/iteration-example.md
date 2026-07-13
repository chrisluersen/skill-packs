# Iteration Example: Hermes Ecosystem Report

**Source:** Session where user asked for research on "top ways to use Hermes" turned into a polished HTML web app via 4 iterations.

**Input:** 11 Obsidian vault files + 20+ GitHub projects researched via web_search/web_extract

**Output:** `hermes-agent-report.html` (97KB, 1563 lines, single file, no dependencies)

## The 4-Pass Breakdown

### v1: Foundation
- 8 sections: Overview, Architecture, Runtimes, Editors, Hardware, Skills, Next Steps, Philosophy
- Dark theme with CSS custom properties
- Inter + JetBrains Mono fonts
- Responsive container layout
- Complete content from all vault files

### v2: Interactivity
- Reading progress bar (scroll tracker)
- Sticky navbar with section highlighting via IntersectionObserver
- Desktop ToC sidebar + mobile slide-out panel
- Tabs for editor integrations (ACP, VS Code, Zed, Neovim, JetBrains, Toad, Others)
- Accordions for hardware section (expand/collapse)
- Back-to-top button
- Code copy buttons on every `<div class="code-block">`
- Keyboard shortcuts (Ctrl+K, Escape, F)
- Mobile hamburger menu
- Print stylesheet

### v3: Visual Polish
- Animated scroll counters in hero stats
- Fade-in cards + quote blocks via IntersectionObserver
- `[data-tip]` hover tooltips on technical terms
- Full interactive SVG architecture diagram (1100×780 viewBox) with gradients, arrows, grid, tooltips
- Section index mini-map grid
- Focus mode (F key to dim other sections)
- Expand All / Collapse All for accordions
- Status bar with green/yellow dots
- Philosophy cards with decorative quote marks
- Table filter/search bars
- Tag/badge system

### v4: Code Quality & Accessibility
- Skip-to-content link
- `role="progressbar"` with `aria-valuenow`
- `aria-expanded` on accordion headers (synced on toggle)
- Debounced passive scroll handler (`debounce(fn, 16)`, `{passive: true}`)
- Descriptive `aria-label` on SVG diagram
- Version footer (v4 · Final · stats)
- Cleaned up JS, removed dead code

## Key Implementation Details

### Scroll progress bar
```html
<div class="progress-bar" role="progressbar" aria-valuenow="0" aria-valuemin="0" aria-valuemax="100">
  <div class="progress-fill" id="progressFill"></div>
</div>
```

### Tab system
```js
function switchTab(btn, contentId) {
  const parent = btn.closest('.tabs');
  parent.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
  parent.querySelectorAll('.tab-btn').forEach(b => {
    b.classList.remove('active');
    b.setAttribute('aria-selected', 'false');
  });
  document.getElementById(contentId).classList.add('active');
  btn.classList.add('active');
  btn.setAttribute('aria-selected', 'true');
}
```

### Debounced scroll handler
```js
function debounce(fn, ms) {
  let timer;
  return (...args) => { clearTimeout(timer); timer = setTimeout(() => fn(...args), ms); };
}
const scrollHandler = debounce(onScroll, 16);
window.addEventListener('scroll', scrollHandler, { passive: true });
```

### Accordion with accessibility
```js
function toggleAccordion(btn) {
  const item = btn.closest('.accordion-item');
  const wasOpen = item.classList.contains('open');
  item.closest('.accordion').querySelectorAll('.accordion-item.open').forEach(i => {
    i.classList.remove('open');
    i.querySelector('.accordion-header')?.setAttribute('aria-expanded', 'false');
  });
  if (!wasOpen) {
    item.classList.add('open');
    btn.setAttribute('aria-expanded', 'true');
  } else {
    btn.setAttribute('aria-expanded', 'false');
  }
}
```

### Counter animation
```js
let countersAnimated = false;
function animateCounters() {
  if (countersAnimated) return;
  countersAnimated = true;
  document.querySelectorAll('.counter').forEach(counter => {
    const target = parseInt(counter.dataset.target);
    const suffix = counter.dataset.suffix || '';
    const duration = 1500;
    const step = Math.max(1, Math.floor(target / 40));
    let current = 0;
    if (target === 0) { counter.textContent = '0' + suffix; return; }
    const interval = setInterval(() => {
      current = Math.min(current + step, target);
      counter.textContent = current + suffix;
      if (current >= target) clearInterval(interval);
    }, duration / (target / step));
  });
}
```

### Focus mode
```js
let focusMode = false;
function toggleFocus() {
  focusMode = !focusMode;
  document.body.classList.toggle('focus-mode', focusMode);
  updateFocus();
}
function updateFocus() {
  if (!focusMode) return;
  // Find most visible section and add .focus-active
}
```
