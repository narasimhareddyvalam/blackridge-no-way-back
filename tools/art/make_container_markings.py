"""Draw the container yard's box markings (the audit, #351) as ISO 6346 has them, for
`container_paint.gdshader`, in white on transparent (the shader inks them light or dark on each
box's paint):

- `container_codes.png`: 128 strips, 8 across and 16 down, each 512 x 64 pixels standing for
  1.05 x 0.13 m: an owner code (its fourth letter U, a freight container), a six-digit serial and
  its check digit in a box, worked out as ISO 6346 does; each a box's own.
- `container_panels.png`: three panels of 1024 x 1024 for a right-hand door's 1.05 x 1.05 m, one
  a size-type (22G1 for 20 ft, 42G1 for 40 ft, 45G1 for 40 ft high cube) with its MAX GROSS,
  TARE, NET (payload) and CU.CAP. in kilograms and pounds, cubic metres and cubic feet.
- `container_lines.png`: eight lines' names, 2048 x 256 each, fictional (no real line's name or
  any name from the story), for the boxes' sides.
- `container_marks.json`: each strip's code and line, each line's livery, and each size-type's
  words, which `container_yard.gd` reads.

The type is Barlow Condensed SemiBold (SIL Open Font License, `source_assets/fonts/`).

Usage, from the repository root:
    python3 -I tools/art/make_container_markings.py
"""

import json
import pathlib
import random

from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "game/features/environments/industrial_loop/art/container_yard"
FONT = ROOT / "source_assets/fonts/barlow_condensed/BarlowCondensed-SemiBold.ttf"
SEED = 351
STRIPS = 128
STRIP = (512, 64)
PANEL = 1024
LINE = (2048, 256)
## The lines: their names on the boxes' sides, owner codes and livery colours (fictional).
LINES = [
    ("NORDLINE", "NDL", (0.16, 0.30, 0.48)),
    ("KESTREL", "KST", (0.50, 0.17, 0.12)),
    ("MERIDIAN LINES", "MRD", (0.20, 0.36, 0.25)),
    ("TRANSARC", "TSA", (0.48, 0.48, 0.46)),
    ("GREYPORT", "GYP", (0.15, 0.37, 0.38)),
    ("HALVARD", "HLV", (0.40, 0.13, 0.16)),
    ("PACIFIC CARGO", "PCG", (0.56, 0.33, 0.14)),
    ("TRILEASE", "TLS", (0.78, 0.78, 0.74)),
]
## Each size-type's ratings (ISO 1496-1 boxes as built today, 30,480 kg rated).
TYPES = {
    "22G1": {"tare": 2230, "cube": 33.2},
    "42G1": {"tare": 3750, "cube": 67.7},
    "45G1": {"tare": 3900, "cube": 76.4},
}
GROSS = 30480
LB = 2.20462
FT3 = 35.3147


def check_digit(code: str) -> int:
    values = {}
    value = 10
    for letter in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
        if value % 11 == 0:
            value += 1
        values[letter] = value
        value += 1
    total = sum((values[c] if c.isalpha() else int(c)) * 2 ** i for i, c in enumerate(code[:10]))
    return total % 11 % 10


def font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT), size)


def codes(draw: random.Random) -> list:
    made = []
    seen = set()
    while len(made) < STRIPS:
        line = draw.randrange(len(LINES))
        stem = LINES[line][1] + "U" + "%06d" % draw.randrange(100000, 999999)
        if stem in seen:
            continue
        seen.add(stem)
        made.append({"code": stem + str(check_digit(stem)), "line": line})
    return made


def draw_strips(made: list) -> None:
    sheet = Image.new("RGBA", (STRIP[0] * 8, STRIP[1] * (STRIPS // 8)), (0, 0, 0, 0))
    pen = ImageDraw.Draw(sheet)
    letters = font(52)
    for index, entry in enumerate(made):
        x, y = (index % 8) * STRIP[0], (index // 8) * STRIP[1]
        code = entry["code"]
        words = "%s %s" % (code[:4], code[4:10])
        pen.text((x + 14, y + 4), words, font=letters, fill=(255, 255, 255, 255))
        width = pen.textlength(words + " ", font=letters)
        box = (x + 14 + width, y + 8, x + 14 + width + 34, y + 58)
        pen.rectangle(box, outline=(255, 255, 255, 255), width=4)
        pen.text((box[0] + 6, y + 4), code[10], font=letters, fill=(255, 255, 255, 255))
    sheet.save(OUT / "container_codes.png")


def draw_panels() -> dict:
    sheet = Image.new("RGBA", (PANEL * 3, PANEL), (0, 0, 0, 0))
    pen = ImageDraw.Draw(sheet)
    big, small = font(150), font(66)
    words = {}
    for index, (kind, rating) in enumerate(TYPES.items()):
        x = index * PANEL
        tare = rating["tare"]
        net = GROSS - tare
        rows = [
            ("MAX GROSS", "{:,} KG".format(GROSS), "{:,} LB".format(round(GROSS * LB / 10) * 10)),
            ("TARE", "{:,} KG".format(tare), "{:,} LB".format(round(tare * LB / 10) * 10)),
            ("NET", "{:,} KG".format(net), "{:,} LB".format(round(net * LB / 10) * 10)),
            ("CU.CAP.", "%.1f CU.M" % rating["cube"],
             "{:,} CU.FT".format(round(rating["cube"] * FT3))),
        ]
        pen.text((x + 60, 150), kind, font=big, fill=(255, 255, 255, 255))
        for row, (label, metric, imperial) in enumerate(rows):
            y = 420 + row * 140
            pen.text((x + 60, y), label, font=small, fill=(255, 255, 255, 255))
            pen.text((x + 400, y), metric, font=small, fill=(255, 255, 255, 255))
            pen.text((x + 400, y + 62), imperial, font=small, fill=(255, 255, 255, 255))
        words[kind] = [" ".join(r) for r in rows]
    sheet.save(OUT / "container_panels.png")
    return words


def draw_lines() -> None:
    sheet = Image.new("RGBA", (LINE[0], LINE[1] * len(LINES)), (0, 0, 0, 0))
    pen = ImageDraw.Draw(sheet)
    for index, (name, _owner, _colour) in enumerate(LINES):
        size = 120 if name == "TRILEASE" else 210
        letters = font(size)
        width = pen.textlength(name, font=letters)
        y = index * LINE[1] + (LINE[1] - size) // 2 - 16
        pen.text(((LINE[0] - width) / 2, y), name, font=letters, fill=(255, 255, 255, 255))
    sheet.save(OUT / "container_lines.png")


def main() -> None:
    draw = random.Random(SEED)
    made = codes(draw)
    draw_strips(made)
    words = draw_panels()
    draw_lines()
    marks = {
        "strips": made,
        "strip_grid": [8, STRIPS // 8],
        "lines": [{"name": n, "owner": o + "U", "livery": list(c)} for n, o, c in LINES],
        "types": words,
    }
    (OUT / "container_marks.json").write_text(json.dumps(marks, indent=1) + "\n")
    print("strips", len(made), "lines", len(LINES))


if __name__ == "__main__":
    main()
