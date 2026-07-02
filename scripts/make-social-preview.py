#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["pillow", "matplotlib"]
# ///
"""Generate the repo's GitHub social-preview card.

Run:  uv run scripts/make-social-preview.py
Output: .github/social-preview.png (1280x640)

Visual system matches the bigelow.github.io blog card: paper background,
dark slate text, one accent rule. Fonts are DejaVu Sans from matplotlib's
bundled ttf set, so the render is reproducible without system fonts.
"""
import os
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import matplotlib

W, H = 1280, 640
BG = "#fdfdfc"
FG = "#1a1a1a"
ACCENT = "#0a5ad6"
MUTED = "#666666"

FONT_DIR = Path(matplotlib.get_data_path()) / "fonts" / "ttf"
bold = lambda s: ImageFont.truetype(str(FONT_DIR / "DejaVuSans-Bold.ttf"), s)
reg = lambda s: ImageFont.truetype(str(FONT_DIR / "DejaVuSans.ttf"), s)

img = Image.new("RGB", (W, H), BG)
d = ImageDraw.Draw(img)

MARGIN = 96
MAXW = W - 2 * MARGIN


def wrap(text, font, max_w):
    words, lines, cur = text.split(), [], ""
    for w in words:
        trial = f"{cur} {w}".strip()
        if d.textbbox((0, 0), trial, font=font)[2] <= max_w:
            cur = trial
        else:
            lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines


title_f = bold(88)
tag_f = reg(40)
url_f = reg(30)

title = "kubernetes-2026"
tag = "A Kubernetes reference architecture — every claim verified or honestly scoped."
tag_lines = wrap(tag, tag_f, MAXW)

title_h = d.textbbox((0, 0), title, font=title_f)[3]
line_h = int(tag_f.size * 1.35)
rule_gap = 28
block_h = title_h + rule_gap + 3 + rule_gap + line_h * len(tag_lines)
top = (H - block_h) // 2

d.text((MARGIN, top), title, font=title_f, fill=FG)
rule_y = top + title_h + rule_gap
d.rectangle([MARGIN, rule_y, MARGIN + 200, rule_y + 3], fill=ACCENT)
y = rule_y + 3 + rule_gap
for ln in tag_lines:
    d.text((MARGIN, y), ln, font=tag_f, fill=FG)
    y += line_h

url = "github.com/bigelow/kubernetes-2026"
url_h = d.textbbox((0, 0), url, font=url_f)[3]
d.text((MARGIN, H - MARGIN - url_h), url, font=url_f, fill=MUTED)

out = Path(__file__).resolve().parent.parent / ".github" / "social-preview.png"
out.parent.mkdir(parents=True, exist_ok=True)
img.save(out, "PNG")
print(f"wrote {out} ({img.size[0]}x{img.size[1]}, {os.path.getsize(out)} bytes)")
