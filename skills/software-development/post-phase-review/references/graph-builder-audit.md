# Graph Builder Audit — R3 / R5 Checklist

Graph data (`graph-data.json`) and the D3 explorer (`graph-explorer.html`) are **derived artifacts** — they regenerate from page frontmatter and must be re-verified after any content edit cycle. The build scripts themselves can have bugs that drift apart as the repo structure changes. Run these checks during R3 (backfill) or R5 (pre-commit).

## Common Drift Patterns (found across multiple review cycles)

### 1. SKIP_DIRS not in sync with repo structure

The `build_graph_data.py` script must exclude non-content directories (`raw/`, `_archive/`, `pending/`, `audit/`, `.git/`, `.llmwiki/`, `.obsidian/`, `.hermes/`). When a new directory is added to the repo (e.g. `pending/`), the builder's `SKIP_DIRS` set may not include it, causing:

- Inflated node counts (raw articles become graph nodes)
- Broken D3 tooltips (wiki pages pointing to `raw/` paths)
- Confusing graph / wrong edge density

**Fix:** Read `build_graph_data.py` and verify every non-content directory has an entry in `SKIP_DIRS`. Run the builder, then check output:
```
python build_graph_data.py
# Expected: node count matches content pages only
# If node count > content pages, check what leaked
```

### 2. SKIP_FILES case sensitivity on Windows

On Windows the filesystem is case-insensitive but Python string matching is not. A `SKIP` set containing `"TODO.md"` will NOT match a file named `todo.md`. This causes meta files (todo.md, log.md, README.md) to leak into the graph.

**Fix:** Use `path.name.lower() in SKIP_FILES` instead of `path.name in SKIP`. All entries in `SKIP_FILES` should be lowercase.

### 3. Nodes missing `edges` count

The D3 explorer uses `d.edges` for node radius sizing (`Math.max(6, Math.min(14, 8 + (d.edges || 0) * 1.5))`). If the builder script doesn't compute and inject edge counts, all nodes get the minimum radius and the graph loses visual hierarchy.

**Fix:** After building all edges, compute per-node edge counts and inject them:
```python
from collections import Counter
edge_counts = Counter()
for e in edges:
    edge_counts[e["source"]] += 1
    edge_counts[e["target"]] += 1
for i, n in enumerate(nodes):
    n["edges"] = edge_counts.get(i, 0)
```

### 4. Inject script / builder JSON key mismatch

`build_graph_data.py` writes `{"nodes": [...], "edges": [...]}`, but the D3 JS inside `inject_graph_data.py` may reference `GRAPH_DATA.links` instead of `GRAPH_DATA.edges`. These are separate files with no shared schema — the key contract can diverge.

**Fix:** In `inject_graph_data.py`, use a fallback:
```javascript
var links = (GRAPH_DATA.links || GRAPH_DATA.edges).map(function(d) { ... });
```

### 5. Broken `target_slug` in edge records

The builder constructs `edges` entries with `"target_slug": tgt_slug`. A past bug used `node_map[list(node_map.keys())[tgt_idx]]` which indexed into the dict keys by position — wrong slug assignment. Always store the actual matched slug, not an index-based deduction.

## Full Verification Script

Drop this into `.hermes/verify-graph.sh` or run it during R5 pre-commit:

```bash
#!/usr/bin/env bash
# Run from wiki root
set -euo pipefail

echo "=== Building graph data ==="
python ~/AppData/Local/hermes/scripts/build_graph_data.py

echo "=== Building graph explorer ==="
python ~/AppData/Local/hermes/scripts/inject_graph_data.py

echo "=== Verifying node fields ==="
python -c "
import json
with open('.hermes/graph-data.json') as f:
    d = json.load(f)
missing = [n['slug'] for n in d['nodes'] if 'edges' not in n]
if missing:
    print(f'WARN: {len(missing)} nodes missing edges field: {missing[:3]}...')
else:
    print(f'OK: All {len(d[\"nodes\"])} nodes have edges count')

# Check all nodes have expected fields
fields = {'id', 'slug', 'title', 'category', 'tags', 'path', 'color', 'edges'}
bad = [n['slug'] for n in d['nodes'] if not fields.issubset(n.keys())]
if bad:
    print(f'WARN: {len(bad)} nodes missing required fields: {bad[:3]}...')
else:
    print(f'OK: All nodes have required fields')

# Verify no raw/ or meta pages leaked
leaks = [n['slug'] for n in d['nodes'] if n['category'] not in ('concepts','entities','comparisons','queries','features','tutorials')]
if leaks:
    print(f'WARN: Unexpected categories: {leaks}')
else:
    print(f'OK: No unexpected categories')
"
```
