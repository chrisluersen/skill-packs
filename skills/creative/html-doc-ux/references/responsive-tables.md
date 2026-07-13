# Responsive Table Card-Stacking

Convert wide tables into stacked card rows on small viewports — each row becomes a bordered card with labeled fields. Essential for reference docs where tables contain configuration parameters, feature comparisons, or CLI flags.

## How it works

On screens ≤640px, the pattern:
1. **Hides `<thead>`** — column headers become per-cell labels via `data-label` attributes
2. **Makes each `<tr>` a card** — border, border-radius, padding, margin-bottom
3. **Shows each `<td>` as a labeled row** — `::before` pseudo-content reads `attr(data-label)`
4. **Hides empty cells** — `td:empty { display: none }` removes blank trailing cells

## Pattern

### CSS

```css
/* Table responsive: stacked cards on small screens */
@media (max-width: 640px) {
    table { display: block; }
    thead { display: none; }
    tbody, tr, td { display: block; }
    tr {
        border: 1px solid var(--border-default);
        border-radius: var(--radius-md);
        padding: 12px;
        margin-bottom: 12px;
    }
    td { padding: 4px 0; border: none; }
    td::before {
        content: attr(data-label);
        display: block;
        font-size: 11px;
        color: var(--fg-muted);
        text-transform: uppercase;
        letter-spacing: .05em;
        margin-bottom: 2px;
    }
    td:empty { display: none; }
    td code { font-size: 12px; }
}
```

### HTML: Add `data-label` to every `<td>`

Every table in the document needs `data-label` attributes added to each `<td>`:

```html
<div class="tw">
    <table>
        <tr>
            <th>Feature</th>
            <th>Description</th>
        </tr>
        <tr>
            <td data-label="Feature">Auto Scaling</td>
            <td data-label="Description">Adjusts capacity based on load</td>
        </tr>
    </table>
</div>
```

### Batch adding `data-label` attributes

For documents with many tables, use a Python script via `terminal` to batch-process:

```python
import re, sys

with open('doc.html', 'r', encoding='utf-8') as f:
    content = f.read()

# Process each table independently
def add_data_labels(html):
    tables = re.finditer(r'(<table[^>]*>)(.*?)(</table>)', html, re.DOTALL)
    for table in tables:
        table_html = table.group(0)
        # Parse header row from <th> elements
        header_match = re.search(r'<tr>(.*?)</tr>', table_html[:table_html.index('</tr>')+6], re.DOTALL)
        if not header_match:
            continue
        headers = re.findall(r'<th[^>]*>(.*?)</th>', header_match.group(1))
        if not headers:
            continue
        headers = [re.sub(r'<[^>]+>', '', h).strip() for h in headers]

        # Add data-label to every <td> that doesn't have one
        rows = re.split(r'(<tr>.*?</tr>)', table_html, flags=re.DOTALL)
        new_rows = []
        for row_html in rows:
            if not row_html.startswith('<tr>'):
                new_rows.append(row_html)
                continue
            tds = re.findall(r'<td[^>]*>', row_html)
            if not tds:
                new_rows.append(row_html)
                continue
            for i, td_open in enumerate(tds):
                if 'data-label' not in td_open and i < len(headers):
                    td_label = f' data-label="{headers[i].strip()}"'
                    row_html = row_html.replace(td_open, td_open.replace('<td', f'<td{td_label}'), 1)
            new_rows.append(row_html)
        html = html.replace(table_html, ''.join(new_rows), 1)
    return html

content = add_data_labels(content)

with open('doc.html', 'w', encoding='utf-8') as f:
    f.write(content)

print('data-label attributes added')
```

**Pitfall:** The script above assumes the first `<tr>` in each table is the header row (containing `<th>` elements). If any table has `<th>` in a different position (e.g., row headers in the first column of every row), it will produce incorrect labels. Verify a sample of tables afterward.

### Manual add for one-off tables

For one or two tables, use `patch()` with enough context:

```bash
grep -n '<td>' doc.html | head -20
```

Then patch each:
```python
# Example: adding data-label to a comparison table's feature column
patch(
    path='doc.html',
    old_string='<td>Auto Scaling</td>',
    new_string='<td data-label="Feature">Auto Scaling</td>'
)
```

## Integration with existing patterns

- **`.tw` wrapper** — works with the existing `.tw` table container (overflow-x: auto on desktop, card-stacking on mobile). The `@media` query changes table display from `table` to `block`, which only takes effect on small screens.
- **Inline code in cells** — `td code { font-size: 12px }` prevents code samples from being too large on mobile.
- **Badges in cells** — badges like `<span class="badge badge-green">` inside `<td>` elements render as inline elements within the card, maintaining color semantics.

## When NOT to use

- Tables with only 2-3 rows and 2 columns — they're already readable on mobile without stacking
- Tables where every cell is empty or nearly empty (sparse data)
- Tables where the column relationship is visually obvious (e.g., a single-column table)

## Key constraints

- **Every `<td>` needs `data-label`** — the `::before` pseudo-content reads this attribute. If any `<td>` lacks it, its mobile card row shows an empty label (no uppercase heading).
- **`<th>` elements are hidden** — the `thead { display: none }` rule hides ALL `<th>` content on mobile. Don't put critical data solely in `<th>` tags.
- **Empty cells** — `td:empty { display: none }` removes cells without content. If a cell has a space or `&nbsp;`, it's NOT empty and shows a blank labeled row. Strip whitespace or use actual empty `<td></td>`.
- **Nested tables** — a table inside a `<td>` breaks the block layout. Avoid nested tables, or exclude them from the media query with a wrapper class.
- **Code font size** — code inside cells shrinks to 12px on mobile. If your code examples are long, they may need word-break handling.
