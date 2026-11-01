"""Draw the American mountain-road signs used on the ghat road into one texture atlas.

Each 256-pixel cell holds one sign face. Warning signs are black on yellow diamonds,
chevrons and advisory-speed plates are black on yellow rectangles, ROAD CLOSED is black
on white, and SCENIC VIEW is white on brown. Corners outside each sign are transparent.

Usage, from the repository root:
    python3 -I tools/make_road_signs.py
"""

import math
import pathlib

from PIL import Image, ImageDraw, ImageFont

OUT = pathlib.Path("game/features/environments/industrial_loop/art/road_signs.png")
CELL = 256
YELLOW = (250, 196, 18, 255)
BLACK = (18, 18, 18, 255)
WHITE = (238, 238, 232, 255)
BROWN = (92, 58, 38, 255)
CELLS = ["hairpin_left", "hairpin_right", "curve_left", "curve_right",
         "chevron_left", "chevron_right", "speed_15", "speed_20",
         "speed_25", "steep_grade", "grade_9", "road_closed",
         "landslide", "scenic_view", "low_gear", "blank"]


def font(size):
    for path in ("/System/Library/Fonts/Supplemental/Arial Bold.ttf",
                 "/Library/Fonts/Arial Bold.ttf",
                 "/System/Library/Fonts/Supplemental/Verdana Bold.ttf"):
        if pathlib.Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def diamond(draw):
    c, r = CELL / 2, CELL / 2 - 6
    outer = [(c, c - r), (c + r, c), (c, c + r), (c - r, c)]
    draw.polygon(outer, fill=BLACK)
    inner_r = r - 9
    draw.polygon([(c, c - inner_r), (c + inner_r, c), (c, c + inner_r), (c - inner_r, c)],
                 fill=YELLOW)
    border_r = r - 16
    draw.polygon([(c, c - border_r), (c + border_r, c), (c, c + border_r), (c - border_r, c)],
                 outline=BLACK, width=5)


def rectangle(draw, fill, border, inset=10):
    draw.rounded_rectangle([inset, inset + 30, CELL - inset, CELL - inset - 30], radius=14,
                           fill=border)
    draw.rounded_rectangle([inset + 7, inset + 37, CELL - inset - 7, CELL - inset - 37],
                           radius=10, fill=fill)


def arrow_head(draw, tip, direction, size=26):
    angle = math.atan2(direction[1], direction[0])
    left = (tip[0] - size * math.cos(angle - 0.55), tip[1] - size * math.sin(angle - 0.55))
    right = (tip[0] - size * math.cos(angle + 0.55), tip[1] - size * math.sin(angle + 0.55))
    draw.polygon([tip, left, right], fill=BLACK)


def hairpin(draw, flip):
    c = CELL / 2
    side = 1 if flip else -1
    stem_x = c + side * 26
    draw.line([(stem_x, c + 62), (stem_x, c - 14)], fill=BLACK, width=16)
    box = [c - 26 - 26, c - 66, c + 26 + 26, c + 38]
    draw.arc(box, 180, 360, fill=BLACK, width=16)
    end_x = c - side * 26
    draw.line([(end_x, c - 14), (end_x, c + 30)], fill=BLACK, width=16)
    arrow_head(draw, (end_x, c + 54), (0, 1))


def curve(draw, flip):
    c = CELL / 2
    side = 1 if flip else -1
    points = [(c + side * 6, c + 66), (c + side * 6, c + 10)]
    for step in range(1, 9):
        t = step / 8
        points.append((c + side * (6 - 44 * t * t), c + 10 - 46 * t))
    draw.line(points, fill=BLACK, width=16, joint="curve")
    arrow_head(draw, (c - side * 46, c - 50), (-side * 0.8, -0.6))


def chevron(draw, flip):
    rectangle(draw, YELLOW, BLACK)
    c = CELL / 2
    side = -1 if flip else 1
    for offset in (-34, 30):
        x = c + offset * side
        draw.polygon([(x - side * 24, c - 52), (x + side * 26, c), (x - side * 24, c + 52),
                      (x - side * 2, c + 52), (x + side * 48 - side * 22 * 0 - side * 2, c),
                      (x - side * 2, c - 52)], fill=BLACK)


def text_cell(draw, lines, fill, border, ink, sizes):
    rectangle(draw, fill, border)
    total = sum(sizes) + 10 * (len(lines) - 1)
    y = CELL / 2 - total / 2
    for line, size in zip(lines, sizes):
        face = font(size)
        width = draw.textlength(line, font=face)
        draw.text((CELL / 2 - width / 2, y), line, font=face, fill=ink)
        y += size + 10


def steep_grade(draw):
    diamond(draw)
    c = CELL / 2
    draw.polygon([(c - 70, c + 40), (c + 70, c + 40), (c + 70, c - 6)], fill=BLACK)
    draw.rectangle([c - 40, c - 34, c + 6, c - 2], fill=BLACK)
    draw.rectangle([c + 6, c - 24, c + 26, c - 2], fill=BLACK)
    draw.ellipse([c - 34, c - 6, c - 18, c + 10], fill=BLACK)
    draw.ellipse([c + 4, c - 6, c + 20, c + 10], fill=BLACK)


def landslide(draw):
    diamond(draw)
    c = CELL / 2
    draw.polygon([(c - 66, c + 50), (c + 30, c + 50), (c - 66, c - 40)], fill=BLACK)
    for x, y, r in ((c + 8, c - 30, 13), (c + 38, c - 2, 10), (c + 22, c + 26, 8)):
        draw.ellipse([x - r, y - r, x + r, y + r], fill=BLACK)


def main():
    atlas = Image.new("RGBA", (CELL * 4, CELL * 4), (0, 0, 0, 0))
    for index, name in enumerate(CELLS):
        cell = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
        draw = ImageDraw.Draw(cell)
        if name.startswith("hairpin"):
            diamond(draw)
            hairpin(draw, name.endswith("left"))
        elif name.startswith("curve"):
            diamond(draw)
            curve(draw, name.endswith("left"))
        elif name.startswith("chevron"):
            chevron(draw, name.endswith("left"))
        elif name.startswith("speed"):
            text_cell(draw, [name.split("_")[1], "MPH"], YELLOW, BLACK, BLACK, [92, 40])
        elif name == "steep_grade":
            steep_grade(draw)
        elif name == "grade_9":
            text_cell(draw, ["9%"], YELLOW, BLACK, BLACK, [104])
        elif name == "road_closed":
            text_cell(draw, ["ROAD", "CLOSED"], WHITE, BLACK, BLACK, [54, 54])
        elif name == "landslide":
            landslide(draw)
        elif name == "scenic_view":
            text_cell(draw, ["SCENIC", "VIEW"], BROWN, WHITE, WHITE, [52, 52])
        elif name == "low_gear":
            text_cell(draw, ["TRUCKS", "USE LOW", "GEAR"], WHITE, BLACK, BLACK, [44, 44, 44])
        atlas.paste(cell, ((index % 4) * CELL, (index // 4) * CELL))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(OUT)
    print(f"Wrote {OUT} with {len(CELLS)} cells: {', '.join(CELLS)}")


if __name__ == "__main__":
    main()
