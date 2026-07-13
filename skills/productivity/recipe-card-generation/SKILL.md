---
name: recipe-card-generation
description: Generate formatted recipe cards as PDFs for coffee/tea brewing, cooking, or any procedural recipe. Handles specs boxes, step tables, quick-look summaries, dial-in guides, and checklists. Outputs print-ready PDF via fpdf2.
category: productivity
tags: [pdf, recipe, brewing, coffee, template, fpdf2]
created_from_user_sessions: true
---

# Recipe Card Generation Skill

## When to Use
- User wants a printable/phone-friendly recipe card for a brew method, coffee, or food recipe
- Recurring need: structured specs, pour schedule, dial-in table, quick-look cheat sheet, pre-flight checklist
- Output must be PDF deliverable via Discord/Telegram/etc.

## Core Pattern (Recipe Card Structure)
Every recipe card follows this section order:
1. **Title block** — name, dose, gear, key params
2. **Specs box** — key-value pairs in bordered table (coffee, water, ice, ratio, grind, target time)
3. **Pour/Step Schedule** — table with Step | Time | Cumulative | Action
4. **Quick-Look** — monospace one-liner for taping to kettle/station
5. **Dial-In Guide** — symptom → fix table (one change at a time)
6. **Context Notes** — gear-specific, coffee-specific, temp-specific tips
7. **Pre-Flight Checklist** — tick boxes for setup verification

## PDF Generation (fpdf2)
```python
from fpdf import FPDF
pdf = FPDF()
pdf.add_page()
pdf.set_auto_page_break(auto=True, margin=15)
# ... build sections ...
pdf.output("~/recipe_card.pdf")
```

### Layout Conventions
- Title: Helvetica Bold 16, centered
- Subtitle: Helvetica 10, centered
- Section headers: Helvetica Bold 10
- Specs table: 2-col, 60/140 split, gray header fill
- Step table: 4-col, widths [25, 25, 40, 110], header fill
- Quick-look: Courier 9 (monospace alignment)
- Dial-in: 2-col, 90/110 split, bold symptom / regular fix
- Body text: Helvetica 9
- Checklist: `[ ]` prefix, Helvetica 9

## Gear-Specific Defaults (Coffee)
| Gear | Parameter | Default |
|------|-----------|---------|
| 1Zpresso K-Ultra | clicks | 23–25 (flat-bottom), 26–28 (V60) |
| Fellow Stagg EKG | temp | 205 °F (96 °C) for light-medium |
| Blue Bottle dripper | filter | thick, slower flow → don't over-grind |
| Hario V60 02 | filter | thin, fast flow → coarser grind |

## Dial-In Rows (Standard Set)
Always include these symptom→fix rows, adapt values per recipe:
- Finishes too fast, sour/salty → finer
- Finishes too slow, bitter/hollow → coarser
- Good time, flat flavor → +1g dose
- Too intense/drying → -1g dose
- Watery/weak → less ice (same water)
- **Muddy/heavy → coarser + verify temp** (honey process + thick filter)

## Template File
See `templates/recipe_card_template.py` for a reusable fpdf2 boilerplate.

## References
- `references/coffee-brew-params.md` — common ratios, temps, grind ranges by method
- `references/pdf-generation-patterns.md` — fpdf2 snippets for tables, checklists, quick-look blocks