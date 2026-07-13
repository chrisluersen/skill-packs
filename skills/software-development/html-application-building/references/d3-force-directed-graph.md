# D3.js Force-Directed Graph in a Self-Contained HTML File

Build an interactive, self-contained force-directed graph as a single HTML file (no build tools, no npm). Data is inlined as a JS variable; D3.js is loaded from CDN.

## Architecture

```
HTML + CSS Layout          d3.js CDN (<script src>)
     │                           │
     └───────────┬───────────────┘
                 │
      Your IIFE JavaScript
      with inlined GRAPH_DATA
```

**Data generator pattern:** A separate Python script reads structured data (markdown frontmatter, JSON, etc.) and emits a `graph-data.json` file. Then an injector script replaces a placeholder `var GRAPH_DATA = null;` in the HTML template's `<script>` block with the real JSON.

## Data Structure

Nodes array — each node has:
```json
{
  "id": "acp",
  "title": "Agent Communication Protocol (ACP)",
  "category": "concepts",
  "tags": ["acp", "protocol", "agent"],
  "color": "#4a90d9"
}
```

Links array — each link has:
```json
{
  "source": "acp",
  "target": "delegation",
  "rel": "uses"
}
```

## Key D3.js Patterns

### 1. Force Simulation

```js
var simulation = d3.forceSimulation(nodes)
  .force('link', d3.forceLink(links).id(function(d) { return d.id; }).distance(120))
  .force('charge', d3.forceManyBody().strength(-350))
  .force('center', d3.forceCenter(width / 2, height / 2))
  .force('collision', d3.forceCollide(35));
```

Tune parameters:
- `distance` — prefered link length
- `strength` — negative = repulsion (more spread out), positive = attraction
- `collide` — radius to prevent node overlap

### 2. Zoom & Pan

```js
var zoom = d3.zoom()
  .scaleExtent([0.1, 6])
  .on('zoom', function(e) { g.attr('transform', e.transform); });
svg.call(zoom);
```

Wrap all rendered elements (links, nodes, labels) inside a single `<g>` group that gets transformed.

### 3. Drag Behavior

```js
node.call(d3.drag()
  .on('start', function(e, d) {
    if (!e.active) simulation.alphaTarget(0.3).restart();
    d.fx = d.x; d.fy = d.y;
  })
  .on('drag', function(e, d) { d.fx = e.x; d.fy = e.y; })
  .on('end', function(e, d) {
    if (!e.active) simulation.alphaTarget(0);
    d.fx = null; d.fy = null;
  })
);
```

### 4. Tooltip Positioning

Use `clientX/clientY` relative to the graph container, with edge overflow checks:

```js
node.on('mousemove', function(e) {
  var rect = document.getElementById('graph').getBoundingClientRect();
  var x = e.clientX - rect.left + 14;
  var y = e.clientY - rect.top - 10;
  if (x + 280 > rect.width) x = e.clientX - rect.left - 290;
  if (y + 120 > rect.height) y = rect.height - 130;
  tooltip.style.left = x + 'px';
  tooltip.style.top = y + 'px';
});
```

### 5. Search / Filter Integration

- **Search:** store a debounced (150ms) `input` listener. On each filter pass, iterate `node.each(function(d) { ... })` and set `this.style.display = 'none'` for non-matching nodes.
- **Category filter:** maintain an "active" filter button class. Combine category + search in one pass.
- **Link highlighting:** when search is active, add `.highlighted` class to links connecting matching nodes.

### 6. Resize Handling

```js
window.addEventListener('resize', function() {
  svg.attr('width', w).attr('height', h);
  simulation.force('center', d3.forceCenter(w / 2, h / 2));
  simulation.alpha(0.3).restart();
});
```

## HTML Structure Template

```
<div id="app">
  <header>
    <h1>Graph Title</h1>
    <div class="controls">
      <div class="search-wrap">🔍 <input id="search"></div>
      <div class="filter-group" id="filterGroup"></div>
      <div class="stats" id="stats">N visible</div>
    </div>
  </header>
  <div id="graph">
    <svg id="svg"></svg>
    <div id="tooltip"></div>          <!-- Floating tooltip -->
    <div id="legend"></div>           <!-- Category color legend -->
    <div id="edge-toggle-wrap">       <!-- Edge label toggle button -->
      <button id="edge-toggle">🏷️ Labels</button>
    </div>
  </div>
</div>
```

## CSS Must-Haves

- `#graph { flex: 1; position: relative; overflow: hidden; }` — fills remaining space
- `#graph svg { width: 100%; height: 100%; display: block; }` — responsive SVG
- `#tooltip` positioned absolute inside `#graph`, `opacity: 0` → `1` via `.visible` class
- `#legend` and `#edge-toggle-wrap` position absolute inside `#graph` (bottom-left, bottom-right)
- `.node circle { cursor: pointer; stroke: var(--bg); stroke-width: 2px; }` — visible against any background
- `.link { stroke: rgba(255,255,255,0.08); }` — subtle defaults, `.highlighted` when searching
- `.node-label { pointer-events: none; text-shadow: 0 1px 3px var(--bg); }` — legible over lines

## Data Generation Pattern (Python)

```python
import json, yaml, re
from pathlib import Path

CATEGORY_COLORS = {
    "concepts": "#4a90d9",
    "entities": "#3cb371",
    "comparisons": "#e74c3c",
    "queries": "#9370db",
    "howto": "#f0a030",
}

nodes = []
links = []

for file in sorted(VAULT.rglob("*.md")):
    rel = file.relative_to(VAULT)
    if rel.parts[0] in ("raw", ".hermes", "pending", "templates"):
        continue

    frontmatter = parse_frontmatter(file.read_text("utf-8"))
    page_id = frontmatter.get("id", file.stem)
    relates_to = frontmatter.get("relates_to", [])

    # Add node
    nodes.append({
        "id": page_id,
        "title": frontmatter.get("title", file.stem),
        "category": rel.parts[0],
        "color": CATEGORY_COLORS.get(rel.parts[0], "#888"),
    })

    # Add edges from relates_to
    if isinstance(relates_to, list):
        for edge in relates_to:
            if isinstance(edge, dict):
                links.append({"source": page_id, "target": edge["page"], "rel": edge.get("rel", "relates")})
            elif isinstance(edge, str):
                links.append({"source": page_id, "target": edge, "rel": "relates"})

# Add edge counts to nodes
link_count = {}
for l in links:
    link_count[l["source"]] = link_count.get(l["source"], 0) + 1
    link_count[l["target"]] = link_count.get(l["target"], 0) + 1
for n in nodes:
    n["edges"] = link_count.get(n["id"], 0)

json.dump({"nodes": nodes, "links": links}, open("graph-data.json", "w"), indent=2)
```

## Data Injection Pattern (Python)

```python
# Build HTML: replace placeholder with real JSON data
html = template_path.read_text("utf-8")
json_str = json.dumps(graph_data, separators=(",", ":"))
html = html.replace('var GRAPH_DATA = null;', f'var GRAPH_DATA = {json_str};')
template_path.write_text(html, "utf-8")
```

## Pitfalls

- **tooltip overflow:** Always check `x + tooltipWidth > containerWidth` and flip to the left side. Same for vertical overflow.
- **node boundary escape:** Use `simulation.on('tick', ...)` to clamp node positions within SVG bounds (`Math.max/min`).
- **resize breaks layout:** Without `simulation.alpha(0.3).restart()` on resize, nodes stay at old center coordinates.
- **mouse coords on zoom:** Tooltip uses `clientX/clientY` (viewport-relative), not D3 zoom-transformed coordinates. Always subtract the container's bounding rect.
- **D3 v7 breaking change:** `d3.event` is gone in v7 — event is the first argument to handlers, datum is the second: `function(e, d)`.
- **CDN failure:** If D3 doesn't load from CDN, the page is blank. Add a `<noscript>` fallback and consider a `<link rel="preconnect">` for the CDN domain.
