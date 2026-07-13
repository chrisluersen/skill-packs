#!/usr/bin/env python3
"""
Recipe Card PDF Template — fpdf2 boilerplate.
Copy and modify for each recipe.
"""
from fpdf import FPDF
import os


class RecipeCard(FPDF):
    def __init__(self, title, subtitle, specs, steps, quick_look, dial_in, notes, checklist, output_path):
        super().__init__()
        self.title = title
        self.subtitle = subtitle
        self.specs = specs          # list of (label, value)
        self.steps = steps          # list of (step, time, cumulative, action)
        self.quick_look = quick_look # list of str
        self.dial_in = dial_in       # list of (symptom, fix)
        self.notes = notes           # list of str (each section gets a header)
        self.checklist = checklist   # list of str
        self.output_path = output_path
        self.setup()

    def setup(self):
        self.add_page()
        self.set_auto_page_break(auto=True, margin=15)
        self.build()

    def header_row(self, *cells, widths, bold=True, fill=True):
        self.set_font("Helvetica", "B" if bold else "", 8)
        if fill:
            self.set_fill_color(240, 240, 240)
        for i, cell in enumerate(cells):
            self.cell(widths[i], 6, cell, border=1, align="C", fill=fill)
        self.ln()

    def data_row(self, *cells, widths):
        self.set_font("Helvetica", "", 8)
        max_h = 6
        for i, cell in enumerate(cells):
            lines = self.multi_cell(widths[i], 6, cell, border=0, split_only=True)
            h = len(lines) * 6
            if h > max_h:
                max_h = h
        x_start = self.get_x()
        y_start = self.get_y()
        for i, cell in enumerate(cells):
            self.set_xy(x_start + sum(widths[:i]), y_start)
            self.multi_cell(widths[i], 6, cell, border=1)
        self.set_y(y_start + max_h)

    def build(self):
        # Title block
        self.set_font("Helvetica", "B", 16)
        self.cell(0, 10, self.title, align="C", new_x="LMARGIN", new_y="NEXT")
        self.set_font("Helvetica", "", 10)
        self.cell(0, 6, self.subtitle, align="C", new_x="LMARGIN", new_y="NEXT")
        self.ln(4)

        # Specs box
        self.set_font("Helvetica", "B", 10)
        self.set_fill_color(240, 240, 240)
        for label, value in self.specs:
            self.set_font("Helvetica", "B", 9)
            self.cell(60, 6, label, border=1, fill=True)
            self.set_font("Helvetica", "", 9)
            self.cell(0, 6, value, border=1, new_x="LMARGIN", new_y="NEXT", fill=True)
        self.ln(6)

        # Steps table
        self.set_font("Helvetica", "B", 10)
        self.cell(0, 6, "POUR SCHEDULE", new_x="LMARGIN", new_y="NEXT")
        col_w = [25, 25, 40, 110]
        self.header_row("Step", "Time", "Cumulative", "Action", widths=col_w)
        for row in self.steps:
            self.data_row(*row, widths=col_w)
        self.ln(6)

        # Quick-look
        self.set_font("Helvetica", "B", 10)
        self.cell(0, 6, "QUICK-LOOK (tape to kettle)", new_x="LMARGIN", new_y="NEXT")
        self.set_font("Courier", "", 9)
        for line in self.quick_look:
            self.cell(0, 5, line, new_x="LMARGIN", new_y="NEXT")
        self.ln(4)

        # Dial-in
        self.set_font("Helvetica", "B", 10)
        self.cell(0, 6, "DIAL-IN (one change at a time)", new_x="LMARGIN", new_y="NEXT")
        self.set_font("Helvetica", "", 9)
        for symptom, fix in self.dial_in:
            self.set_font("Helvetica", "B", 9)
            self.cell(90, 5, symptom)
            self.set_font("Helvetica", "", 9)
            self.cell(0, 5, fix, new_x="LMARGIN", new_y="NEXT")
        self.ln(4)

        # Notes sections
        for section_title, lines in self.notes:
            self.set_font("Helvetica", "B", 10)
            self.cell(0, 6, section_title, new_x="LMARGIN", new_y="NEXT")
            self.set_font("Helvetica", "", 9)
            for line in lines:
                self.cell(0, 5, line, new_x="LMARGIN", new_y="NEXT")
            self.ln(4)

        # Checklist
        self.set_font("Helvetica", "B", 10)
        self.cell(0, 6, "PRE-FLIGHT CHECKLIST", new_x="LMARGIN", new_y="NEXT")
        self.set_font("Helvetica", "", 9)
        for item in self.checklist:
            self.cell(0, 5, item, new_x="LMARGIN", new_y="NEXT")

        self.output(self.output_path)
        print(f"Saved to {self.output_path} ({os.path.getsize(self.output_path)} bytes)")


# Example usage:
if __name__ == "__main__":
    RecipeCard(
        title="BLUE BOTTLE FLASH BREW - RECIPE CARD",
        subtitle="35 g dose | Flat-bottom dripper | 1Zpresso K-Ultra | Fellow Stagg EKG",
        specs=[
            ("COFFEE", "35 g"),
            ("HOT WATER", "235 g @ 205 F"),
            ("ICE", "235 g (in server FIRST)"),
            ("RATIO", "1 : 13.4 (total liquid)"),
            ("GRIND (K-Ultra)", "23-25 clicks"),
            ("TARGET TIME", "2:15 - 2:45"),
        ],
        steps=[
            ("Bloom", "0:00-0:50", "105 g (3x)", "Spiral out-in, saturate fully. Swirl at 0:35"),
            ("Pour 1", "0:50-1:25", "155 g (+50)", "Center spiral, steady ~3 g/s. Water 1cm above bed"),
            ("Pour 2", "1:25-1:55", "200 g (+45)", "Same spiral"),
            ("Pour 3", "1:55-2:20", "235 g (+35)", "Finish pouring by 2:20"),
            ("Drawdown", "2:20-2:45", "--", "Gentle swirl at ~2:30. Flat bed = good"),
        ],
        quick_look=[
            "35 g | 235 g ice | 235 g water @ 205 F",
            "Bloom 105 g -> 0:50",
            "-> 155 g -> 1:25",
            "-> 200 g -> 1:55",
            "-> 235 g -> 2:20",
            "Done ~2:35",
            "K-Ultra: 24 clicks",
        ],
        dial_in=[
            ("Finishes < 2:10, sour/salty", "1 click finer (23)"),
            ("Finishes > 2:50, bitter/hollow", "1 click coarser (25)"),
            ("Good time, flat florals", "36 g coffee, same grind"),
            ("Too intense / drying", "34 g coffee, same grind"),
            ("Watery / weak", "Reduce ice to 220 g (keep water 235 g)"),
            ("Muddy / heavy", "1 click coarser (25) + verify 205 F"),
        ],
        notes=[
            ("TEMP NOTES FOR FELLOW STAGG EKG", [
                "- Set kettle to 205 F (hold mode keeps it there)",
                "- 205 F = 96 C -- preserves floral jasmine, avoids scorching honey sweetness",
                "- If roof of mouth feels 'sharp' -> drop to 203 F",
                "- If florals still muted at 24 clicks -> try 207 F + 25 clicks",
            ]),
            ("NOTES FOR THIS COFFEE", [
                "Weird Brothers - Ethiopia Sidama Honey - Light-Medium",
                "- Floral jasmine + toffee/caramel = delicate top notes, sticky sweetness",
                "- Honey process = more body than washed -> if muddy, 1 click coarser",
                "- Blue Bottle filter = thicker than V60 -> naturally slower, don't over-grind",
            ]),
        ],
        checklist=[
            "[ ] 235 g ice weighed into server",
            "[ ] Filter rinsed thoroughly, rinse water dumped",
            "[ ] 35 g coffee dosed, bed leveled",
            "[ ] Kettle set to 205 F (hold mode ON)",
            "[ ] Scale tared, timer ready",
        ],
        output_path=os.path.expanduser("~/blue_bottle_flash_brew_recipe.pdf")
    )