# Extracting Readable Text from Large HTML Artifacts

When recalling findings from a generated HTML documentation file, you need to extract readable text content (stripping CSS, JS, and HTML tags) while preserving structure (sections, headings, lists, tables).

## Why not `read_file`?

`read_file` has two problems for large HTML files:

1. **Truncation** — defaults to 500 lines, max 2000. A 2,900-line HTML file requires 6+ paginated reads.
2. **Line-number prefixes** — output is `NNN|<content>`, which breaks regex patterns that expect clean HTML.

Use Python's `open()` in `execute_code` instead — no truncation, no prefixes.

## The Extraction Pattern

```python
import re

with open(r"C:\path\to\file.html", "r", encoding="utf-8") as f:
    content = f.read()

# 1. Strip <style>, <script>, and <head> blocks
text = re.sub(r'<style[^>]*>.*?</style>', '', content, flags=re.DOTALL|re.IGNORECASE)
text = re.sub(r'<script[^>]*>.*?</script>', '', text, flags=re.DOTALL|re.IGNORECASE)
text = re.sub(r'<head>.*?</head>', '', text, flags=re.DOTALL|re.IGNORECASE)

# 2. Body only
bm = re.search(r'<body[^>]*>', text, re.IGNORECASE)
if bm:
    text = text[bm.start():]
text = re.sub(r'</body>.*$', '', text, flags=re.DOTALL|re.IGNORECASE)

# 3. Preserve structure as text markers
text = re.sub(r'<section[^>]*id="([^"]+)"[^>]*>',
              r'\n\n========== [\1] ==========\n', text, flags=re.IGNORECASE)
text = re.sub(r'<h([1-4])[^>]*>(.*?)</h\1>',
              lambda m: '\n' + '#'*int(m.group(1)) + ' ' +
              re.sub(r'<[^>]+>','',m.group(2)).strip() + '\n',
              text, flags=re.DOTALL|re.IGNORECASE)
text = re.sub(r'<li[^>]*>', '\n  - ', text, flags=re.IGNORECASE)
text = re.sub(r'</tr>', '\n', text, flags=re.IGNORECASE)
text = re.sub(r'<t[dh][^>]*>', ' | ', text, flags=re.IGNORECASE)
text = re.sub(r'<br\s*/?>', '\n', text, flags=re.IGNORECASE)
text = re.sub(r'</p>', '\n', text, flags=re.IGNORECASE)

# 4. Strip remaining tags
text = re.sub(r'<[^>]+>', '', text)

# 5. Decode HTML entities
entities = [
    ('&amp;', '&'), ('&lt;', '<'), ('&gt;', '>'), ('&quot;', '"'),
    ('&#39;', "'"), ('&nbsp;', ' '), ('&mdash;', '—'), ('&ndash;', '–'),
    ('&hellip;', '…'), ('&rarr;', '→'), ('&check;', '✓'), ('&times;', '×'),
]
for ent, ch in entities:
    text = text.replace(ent, ch)

# 6. Collapse whitespace
text = re.sub(r'[ \t]+\n', '\n', text)
text = re.sub(r'\n{3,}', '\n\n', text)
text = text.strip()

# Write to temp file for paging through large outputs
with open(r"~/AppData/Local/hermes\AppData\Local\Temp\extracted.txt", "w", encoding="utf-8") as f:
    f.write(text)

# List sections found
secs = re.findall(r'========== \[([^\]]+)\] ==========', text)
print(f"Sections: {secs}")
print(f"Extracted: {len(text)} chars")
```

## Paging Through Extracted Text

If the extracted text is large (>15K chars), write it to a temp file and page through it by section:

```python
with open(r"~/AppData/Local/hermes\AppData\Local\Temp\extracted.txt", "r") as f:
    text = f.read()

# Print a specific section by ID
idx = text.find('========== [section-id] ==========')
next_sec = text.find('==========', idx + 10)
print(text[idx:next_sec if next_sec > 0 else idx + 10000])

# Or print a range
print(text[12000:24000])
```

## When to Use This

- User asks "what were the findings of our X research?" and the research was compiled into an HTML guide
- User asks "what's in the Y report we created?" and the report is an HTML file
- Reviewing the content of any large HTML documentation artifact without opening a browser

## Related

- `safe-large-file-editing` skill — documents the `read_file` truncation and line-number prefix issues in the context of *editing* large HTML files
- `html-doc-restructure` skill — covers *editing/restructuring* HTML docs; this reference covers *reading/extracting* content from them
