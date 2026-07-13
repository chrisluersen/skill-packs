# Wiki Audit Recipes — R1 Measurement Commands

Concrete shell and Python one-liners for measuring wiki state during R1 audits. Use these rather than inventing ad-hoc commands each cycle.

## Page Counts & Tiers

```bash
# Per-category counts
for d in concepts entities comparisons queries; do
  count=$(find "$d" -name '*.md' 2>/dev/null | wc -l)
  echo "$d: $count pages"
done

# Total content pages (excludes raw/, pending/, _archive/, .git/, .llmwiki/, .hermes/, .obsidian/)
find . -name '*.md' \
  -not -path './.git/*' -not -path './raw/*' \
  -not -path './pending/*' -not -path './_archive/*' \
  -not -path './audit/*' -not -path './.hermes/*' \
  -not -path './.llmwiki/*' -not -path './.obsidian/*' \
  | wc -l

# Tier breakdown
well=0; adeq=0; thin=0
for f in concepts/*.md entities/*.md comparisons/*.md queries/*.md; do
  chars=$(wc -c < "$f" 2>/dev/null)
  if [ $chars -ge 3000 ]; then well=$((well+1))
  elif [ $chars -ge 2000 ]; then adeq=$((adeq+1))
  else thin=$((thin+1)); fi
done
echo "Well-populated (>=3K): $well"
echo "Adequate (2K-3K):   $adeq"
echo "Thin (<2K):         $thin"

# Bottom 5 by size (thin pages first)
for f in concepts/*.md entities/*.md comparisons/*.md queries/*.md; do
  chars=$(wc -c < "$f" 2>/dev/null)
  echo "$chars $f"
done | sort -n | head -5

# All pages sorted by size
for f in concepts/*.md entities/*.md comparisons/*.md queries/*.md; do
  chars=$(wc -c < "$f" 2>/dev/null); echo "$chars $f"
done | sort -n

# Total content KB
du -shc concepts/ entities/ comparisons/ queries/ | tail -1
```

## Git History

```bash
# Actual commit count
git rev-list --count HEAD

# Full log
git log --oneline --all

# Verify claimed commit hashes match reality
# (Look for the commit referenced in PLAN.md's timeline table)
```

## Edges & Relationships

### Graph data (if graph-data.json exists)
```bash
python -c "
import json
from collections import Counter
with open(r'~/AppData/Local/hermes\Vault\wiki\.hermes\graph-data.json') as f:
    d = json.load(f)
print(f'Nodes: {len(d[\"nodes\"])}')
print(f'Edges: {len(d[\"edges\"])}')
c = Counter(e.get('rel','unknown') for e in d['edges'])
for rel, cnt in sorted(c.items(), key=lambda x:-x[1]):
    print(f'  {rel}: {cnt}')
"
```

### Graph staleness check
```bash
# Compare latest frontmatter edit vs graph build time
python -c "
import os, glob
from datetime import datetime

graph_path = r'~/AppData/Local/hermes\Vault\wiki\.hermes\graph-data.json'
graph_mtime = os.path.getmtime(graph_path) if os.path.exists(graph_path) else 0

# Find all pages with relates_to edges that were edited after graph build
stale = []
for f in glob.glob('concepts/*.md') + glob.glob('entities/*.md') + glob.glob('comparisons/*.md') + glob.glob('queries/*.md'):
    page_mtime = os.path.getmtime(f)
    if page_mtime > graph_mtime:
        stale.append((os.path.getsize(f), f))

stale.sort(reverse=True)
print(f'Graph built: {datetime.fromtimestamp(graph_mtime)}')
print(f'Stale pages (edited after graph): {len(stale)}')
for size, path in stale[:10]:
    print(f'  {size:>6}B  {path}')
"
```

### Edge format validation (check for old string-format edges)
```bash
python -c "
import os, re, yaml
total = 0
string_edges = 0
bad_pattern = re.compile(r'^relates_to:\s*\[.*\]')
for root, dirs, files in os.walk('.'):
    dirs[:] = [d for d in dirs if not d.startswith('.') and d not in ('raw','pending','_archive')]
    for f in files:
        if not f.endswith('.md'): continue
        path = os.path.join(root, f)
        with open(path) as fh:
            content = fh.read()
        if 'relates_to:' not in content: continue
        total += 1
        # Check YAML frontmatter for string-format edges
        if re.search(r'^relates_to:\s*\[[^\]]*\]', content, re.MULTILINE):
            string_edges += 1
            print(f'STRING EDGES: {path}')
print(f'Pages with relates_to: {total}')
print(f'Still using old string format: {string_edges}')
"
```

### Pages with `relates_to` frontmatter
```bash
grep -rl 'relates_to:' concepts/ entities/ comparisons/ queries/ --include='*.md' | wc -l
```

## MCP Server Health

```bash
# Tool count
grep -c '@mcp.tool()' ~/AppData/Local/hermes/scripts/wiki-mcp-server.py

# Server line count (refactoring signal)
wc -l ~/AppData/Local/hermes/scripts/wiki-mcp-server.py

# Verify via MCP (fresh test)
hermes mcp test wiki
```

## Graph Explorer

```bash
# Size check
wc -c .hermes/graph-explorer.html
wc -l .hermes/graph-explorer.html
```

## Frontmatter Integrity

Audit every page's `sources:` field for completeness:
```bash
# Pages MISSING the sources field entirely
for d in concepts entities comparisons queries; do
  for f in $d/*.md; do
    if ! grep -q '^sources:' "$f" 2>/dev/null; then
      echo "MISSING: $f"
    fi
  done
done

# Pages with EMPTY sources (no actual URLs/references)
for d in concepts entities comparisons queries; do
  for f in $d/*.md; do
    if grep -q '^sources: \[\]$' "$f" 2>/dev/null; then
      echo "EMPTY: $f"
    fi
  done
done

# Pages with sources dates older than 90 days
cutoff=$(date -d '90 days ago' +%s 2>/dev/null)
for d in concepts entities comparisons queries; do
  for f in $d/*.md; do
    dates=$(grep -oE '202[0-9]-[0-9]{2}-[0-9]{2}' "$f" 2>/dev/null)
    for d_ in $dates; do
      ts=$(date -d "$d_" +%s 2>/dev/null)
      if [ -n "$ts" ] && [ -n "$cutoff" ] && [ "$ts" -lt "$cutoff" ] 2>/dev/null; then
        echo "OLD DATE: $f → $d_"
        break
      fi
    done
  done
done
```

## Plan Compliance Check

Compare plan claims against actuals for:
| Claim | Command |
|-------|---------|
| Page count | `find … -name '*.md' \| wc -l` |
| Commit count | `git rev-list --count HEAD` |
| MCP tools | `grep -c '@mcp.tool()'` on server file |
| Server lines | `wc -l` on server file |
| Total KB | `du -shc content-dirs/` |
| Pages under threshold | `wc -c` per-file + sort |
| Edges populated | `grep -rl 'relates_to:'` count + graph data |
| Graph freshness | Graph staleness check above |
| Edge format compliance | Edge format validation above |
| "Where We Are Today" checkboxes | Read PLAN.md section, compare each line |

## Common Stale Number Patterns

From experience across multiple review cycles:
- Plan says "44 pages" → reality: 45+
- Plan says "8 MCP tools" → reality: 10 (find_related + suggest_edges added)
- Plan says "221KB" → reality: 236KB (content grows as phases progress)
- Plan says "27 commits" → reality: 28+ (review commits aren't counted)
- Plan says "📋 Planned" for Phase 5 → reality: mostly complete (5a-5d done, 5e pending)
- Server line count in plan is always behind (275→586→869 from Phase 3→4→5)
- Graph nodes/edges in plan are always behind — graph-data.json is a derived artifact, not auto-updated
