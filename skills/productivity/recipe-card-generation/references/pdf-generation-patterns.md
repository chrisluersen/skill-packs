# fpdf2 Patterns for Recipe Cards

Reusable snippets for building recipe card PDFs.

---

## Basic Setup

```python
from fpdf import FPDF
import os

pdf = FPDF()
pdf.add_page()
pdf.set_auto_page_break(auto=True, margin=15)
```

---

## Fonts & Styles

```python
# Titles
pdf.set_font("Helvetica", "B", 16)   # Main title
pdf.set_font("Helvetica", "", 10)    # Subtitle

# Section headers
pdf.set_font("Helvetica", "B", 10)

# Body text
pdf.set_font("Helvetica", "", 9)

# Monospace (quick-look)
pdf.set_font("Courier", "", 9)

# Table headers
pdf.set_font("Helvetica", "B", 8)
pdf.set_fill_color(240, 240, 240)  # Light gray

# Bold inline
pdf.set_font("Helvetica", "B", 9)
```

---

## Specs Box (2-col key-value)

```python
specs = [("LABEL", "value"), ...]
pdf.set_fill_color(240, 240, 240)
for label, value in specs:
    pdf.set_font("Helvetica", "B", 9)
    pdf.cell(60, 6, label, border=1, fill=True)
    pdf.set_font("Helvetica", "", 9)
    pdf.cell(0, 6, value, border=1, new_x="LMARGIN", new_y="NEXT", fill=True)
pdf.ln(6)
```

---

## Multi-row Table with Auto Row Height

```python
col_w = [25, 25, 40, 110]  # Must sum to page width (~190)

def header_row(*cells):
    pdf.set_font("Helvetica", "B", 8)
    pdf.set_fill_color(240, 240, 240)
    for i, cell in enumerate(cells):
        pdf.cell(col_w[i], 6, cell, border=1, align="C", fill=True)
    pdf.ln()

def data_row(*cells):
    pdf.set_font("Helvetica", "", 8)
    # Calculate max height needed
    max_h = 6
    for i, cell in enumerate(cells):
        lines = pdf.multi_cell(col_w[i], 6, cell, border=0, split_only=True)
        h = len(lines) * 6
        if h > max_h:
            max_h = h
    x_start = pdf.get_x()
    y_start = pdf.get_y()
    for i, cell in enumerate(cells):
        pdf.set_xy(x_start + sum(col_w[:i]), y_start)
        pdf.multi_cell(col_w[i], 6, cell, border=1)
    pdf.set_y(y_start + max_h)

# Usage
header_row("Step", "Time", "Cumulative", "Action")
for row in steps:
    data_row(*row)
```

---

## Quick-Look Block (Monospace)

```python
pdf.set_font("Helvetica", "B", 10)
pdf.cell(0, 6, "QUICK-LOOK (tape to kettle)", new_x="LMARGIN", new_y="NEXT")
pdf.set_font("Courier", "", 9)
for line in quick_look_lines:
    pdf.cell(0, 5, line, new_x="LMARGIN", new_y="NEXT")
pdf.ln(4)
```

---

## Dial-In Table (2-col symptom→fix)

```python
pdf.set_font("Helvetica", "B", 10)
pdf.cell(0, 6, "DIAL-IN (one change at a time)", new_x="LMARGIN", new_y="NEXT")
pdf.set_font("Helvetica", "", 9)
for symptom, fix in dial_in:
    pdf.set_font("Helvetica", "B", 9)
    pdf.cell(90, 5, symptom)
    pdf.set_font("Helvetica", "", 9)
    pdf.cell(0, 5, fix, new_x="LMARGIN", new_y="NEXT")
pdf.ln(4)
```

---

## Notes Sections

```python
for section_title, lines in notes:
    pdf.set_font("Helvetica", "B", 10)
    pdf.cell(0, 6, section_title, new_x="LMARGIN", new_y="NEXT")
    pdf.set_font("Helvetica", "", 9)
    for line in lines:
        pdf.cell(0, 5, line, new_x="LMARGIN", new_y="NEXT")
    pdf.ln(4)
```

---

## Checklist

```python
pdf.set_font("Helvetica", "B", 10)
pdf.cell(0, 6, "PRE-FLIGHT CHECKLIST", new_x="LMARGIN", new_y="NEXT")
pdf.set_font("Helvetica", "", 9)
for item in checklist:
    pdf.cell(0, 5, item, new_x="LMARGIN", new_y="NEXT")
```

---

## Save

```python
output_path = os.path.expanduser("~/recipe_card.pdf")
pdf.output(output_path)
print(f"Saved to {output_path} ({os.path.getsize(output_path)} bytes)")
```

---

## Page Width Reference

- A4 page width: 210 mm
- Default margins: 10 mm each side → 190 mm usable
- `col_w` sums should equal ~190

---

## Common Pitfalls

| Issue | Fix |
|-------|-----|
| Table rows overlap | Use `multi_cell` with `split_only=True` to pre-calc height |
| Text cut off at bottom | `set_auto_page_break(auto=True, margin=15)` |
| Font not found | Use built-in: Helvetica, Courier, Times, Symbol, ZapfDingbats |
| Unicode chars (℃, →, etc.) | Use DejaVu font or replace with ASCII (C, ->) |
| Cell alignment off | `align="C"` for center, `align="L"` default, `align="R"` right |