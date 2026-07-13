# Bulk HTML Regex Patterns

## Attribute Addition to External Links

### Pattern
```python
import re

def add_rel(m):
    tag = m.group(0)
    if 'rel=' in tag:
        return tag  # already has rel, skip
    if tag.endswith('/>'):
        return tag[:-2] + ' rel="noopener noreferrer" />'
    else:
        return tag[:-1] + ' rel="noopener noreferrer">'

ext_pat = re.compile(r'<a\s+[^>]*?href="https?://[^"]*"[^>]*?>')
content = ext_pat.sub(add_rel, content)
```

### Pitfalls
- **Double-write risk**: If the first script errors and doesn't write, the second script starts from unmodified source. Always verify counts after the write, not before.
- **Order matters**: Write the file ONCE at the end of the script. If the script errors before writing, no data loss — the file stays in its pre-script state.
- **`rel=` already present**: Some links (e.g. generated ones) may already have `rel`. Check before adding.

## JS IntersectionObserver Insertion

### Pattern
Insert new JS code before/after a known anchor string in the file:
```python
anchor = '\n})();\n</script>'  # end of IIFE
new_js = """
    /* Feature description */
    (function() { ... })();
"""
content = content.replace(anchor, new_js + anchor)
```

### Pitfalls
- Indentation must match exactly (Python cares about the str content, not whitespace-insensitive)
- Search for the anchor first: `anchor in content` — if False, find the actual line with `grep -n`
- The `})();` at end of IIFE may not be indented — check literal content

## Undo/Error Recovery Pattern

When a script errors mid-way:
1. **Do NOT write partial output** — the file on disk is still safe
2. Read the file fresh from disk for the retry
3. If retry still fails, check whether the first script's *regex* worked but the *insertion* failed (they're separate operations)
4. Split into two scripts: one for regex transforms, one for insertion transforms

## Verification Pattern

```python
# Post-verification for any bulk change
import re

with open('path/to/file.html', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Tag balance
assert content.count('<section ') == content.count('</section>')

# 2. JS structural integrity
js = content[content.index('<script>'):content.index('</script>')]
assert js.count('{') == js.count('}')
assert js.count('(') == js.count(')')
assert js.count('[') == js.count(']')

# 3. Find any remaining unmatched items
ext_links = re.findall(r'<a\s+[^>]*?href="https?://[^"]*"[^>]*?>', content)
missing = [l for l in ext_links if 'noopener' not in l]
assert len(missing) == 0, f"{len(missing)} links still missing attribute"
```
