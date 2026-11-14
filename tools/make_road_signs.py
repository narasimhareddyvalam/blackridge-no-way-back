"""Draw the American mountain-road signs used on the ghat road into one texture atlas.

Each 256-pixel cell holds one sign face, four to a row. Warning signs are black on yellow
diamonds, chevrons and advisory-speed plates are black on yellow rectangles, ROAD CLOSED is
black on white, SCENIC VIEW is white on brown, and the bus stop flag is white on blue. Added
for #267's roadside (MUTCD sizes): the SPEED LIMIT 45 regulatory sign (R2-1, 24 x 30 in, black
on white, drawn in a 30 in cell), also weathered (faded, grimed, rust from its bolt holes); the
deer crossing (W11-3, a leaping deer on a yellow diamond); mile markers 0 and 1 (D10-1, white on
green, 10 x 36 in, drawn in a 36 in cell).
Corners outside each sign are transparent.

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
BLUE = (18, 70, 140, 255)
COLUMNS = 4
CELLS = ["hairpin_left", "hairpin_right", "curve_left", "curve_right",
         "chevron_left", "chevron_right", "speed_15", "speed_20",
         "speed_25", "steep_grade", "grade_9", "road_closed",
         "landslide", "scenic_view", "low_gear", "pedestrian",
         "ahead", "arrow_down_left", "bus_stop", "blank",
         "limit_45", "limit_45_weathered", "deer_crossing", "mile_0", "mile_1"]


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


def pedestrian(draw):
    diamond(draw)
    c = CELL / 2
    draw.ellipse([c + 2, c - 72, c + 26, c - 48], fill=BLACK)
    limbs = [
        [(c + 8, c - 40), (c, c + 4)],
        [(c + 6, c - 34), (c + 22, c - 14), (c + 30, c + 2)],
        [(c + 6, c - 34), (c - 12, c - 18), (c - 22, c - 4)],
        [(c, c + 4), (c + 16, c + 28), (c + 22, c + 56), (c + 36, c + 56)],
        [(c, c + 4), (c - 14, c + 28), (c - 34, c + 50), (c - 42, c + 42)],
    ]
    for index, limb in enumerate(limbs):
        draw.line(limb, fill=BLACK, width=18 if index == 0 else 12, joint="curve")
        for x, y in limb:
            r = 9 if index == 0 else 6
            draw.ellipse([x - r, y - r, x + r, y + r], fill=BLACK)


def arrow_down_left(draw):
    rectangle(draw, YELLOW, BLACK)
    c = CELL / 2
    draw.line([(c + 54, c - 36), (c - 30, c + 26)], fill=BLACK, width=16)
    arrow_head(draw, (c - 58, c + 46), (-0.8, 0.6), size=40)


def bus(draw, left, top, width, height, fill, ink):
    draw.rounded_rectangle([left, top, left + width, top + height], radius=8, fill=fill)
    pane = (width - 20) / 3
    for step in range(3):
        x = left + 6 + step * (pane + 4)
        draw.rectangle([x, top + 7, x + pane, top + height * 0.45], fill=ink)
    for x in (left + width * 0.22, left + width * 0.78):
        draw.ellipse([x - 9, top + height - 9, x + 9, top + height + 9], fill=ink)
        draw.ellipse([x - 4, top + height - 4, x + 4, top + height + 4], fill=fill)


def bus_stop(draw):
    draw.rounded_rectangle([48, 8, 208, 248], radius=10, fill=WHITE)
    draw.rounded_rectangle([54, 14, 202, 242], radius=8, fill=BLUE)
    draw.ellipse([106, 22, 150, 66], fill=WHITE)
    face = font(34)
    width = draw.textlength("4", font=face)
    draw.text((128 - width / 2, 24), "4", font=face, fill=BLUE)
    bus(draw, 76, 78, 104, 48, WHITE, BLUE)
    for line, y, size in (("BUS", 142, 38), ("STOP", 182, 38), ("BLACKRIDGE TRANSIT", 226, 11)):
        face = font(size)
        width = draw.textlength(line, font=face)
        draw.text((128 - width / 2, y), line, font=face, fill=WHITE)


GREEN = (0, 104, 56, 255)
RUST = (122, 64, 30)


def regulatory(draw, lines, sizes):
    """A portrait 24 x 30 in sign in a 30 in cell: white, a black border, black words."""
    width = round(CELL * 24 / 30)
    left = (CELL - width) // 2
    draw.rounded_rectangle((left, 2, left + width - 1, CELL - 3), radius=10, fill=WHITE)
    draw.rounded_rectangle((left + 7, 9, left + width - 8, CELL - 10), radius=7, outline=BLACK,
                           width=5)
    tops = [44, 98, 168]
    for line, size, top in zip(lines, sizes, tops):
        draw.text((CELL / 2, top), line, fill=BLACK, font=font(size), anchor="mm")
    return left, width


def weather(cell, left, width):
    """Years of sun and road grime: faded toward grey, soft dark streaks run down from its top,
    rust from its two bolt holes; each blended over the sign, never cutting through it."""
    import random
    random.seed(45)
    pixels = cell.load()
    for y in range(CELL):
        for x in range(left, left + width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            fade = 0.8 + 0.06 * math.sin(x * 0.05 + y * 0.02)
            r, g, b = (round(c * fade + 205 * (1 - fade)) for c in (r, g, b))
            pixels[x, y] = (min(255, r + 6), min(255, g + 4), b, a)
    grime = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    draw = ImageDraw.Draw(grime)
    for _ in range(18):
        x = random.randint(left + 10, left + width - 10)
        length = random.randint(40, 150)
        for step in range(length):
            shade = round(46 * (1 - step / length))
            draw.point((x + round(math.sin(step * 0.08) * 1.5), 12 + step),
                       fill=(96, 90, 78, shade))
            draw.point((x + 1 + round(math.sin(step * 0.08) * 1.5), 12 + step),
                       fill=(96, 90, 78, shade // 2))
    for hole in (18, CELL - 18):
        cx = CELL // 2
        draw.ellipse((cx - 4, hole - 4, cx + 4, hole + 4), fill=(60, 60, 58, 255))
        for _ in range(4):
            dx = random.randint(-5, 5)
            run = random.randint(10, 30)
            for step in range(run):
                draw.point((cx + dx, hole + 4 + step), fill=RUST + (round(120 * (1 - step / run)),))
    mask = Image.new("L", (CELL, CELL), 0)
    mask.paste(cell.split()[3])
    grime.putalpha(Image.composite(grime.split()[3], Image.new("L", (CELL, CELL), 0), mask))
    cell.alpha_composite(grime)


def ellipse_points(cx, cy, rx, ry, turn, count=28):
    return [(cx + rx * math.cos(t) * math.cos(turn) - ry * math.sin(t) * math.sin(turn),
             cy + rx * math.cos(t) * math.sin(turn) + ry * math.sin(t) * math.cos(turn))
            for t in (2 * math.pi * k / count for k in range(count))]


def limb(draw, points, width):
    draw.line(points, fill=BLACK, width=width, joint="curve")
    for x, y in (points[0], points[-1]):
        draw.ellipse((x - width / 2, y - width / 2, x + width / 2, y + width / 2), fill=BLACK)


def deer(draw):
    """The W11-3 leaping deer, leaping to the left: its body tilted up into the leap, its neck
    rising to its head and antlers, its forelegs tucked forward, its hind legs stretched back."""
    draw.polygon(ellipse_points(132, 124, 46, 19, -0.28), fill=BLACK)
    draw.polygon([(96, 118), (84, 92), (78, 82), (90, 78), (104, 100), (112, 116)], fill=BLACK)
    draw.polygon(ellipse_points(78, 80, 13, 7, -0.5), fill=BLACK)
    draw.polygon([(66, 82), (60, 88), (66, 89)], fill=BLACK)
    limb(draw, [(84, 72), (80, 58), (72, 50)], 4)
    limb(draw, [(80, 60), (88, 52)], 3)
    limb(draw, [(88, 70), (92, 56), (100, 50)], 4)
    limb(draw, [(91, 58), (86, 50)], 3)
    limb(draw, [(104, 132), (86, 140), (74, 150)], 7)
    limb(draw, [(112, 134), (98, 148), (88, 162)], 7)
    limb(draw, [(168, 120), (190, 140), (212, 152)], 8)
    limb(draw, [(162, 128), (182, 150), (198, 168)], 8)
    draw.polygon([(176, 110), (190, 100), (188, 112)], fill=BLACK)


def milepost(draw, number):
    """A D10-1 reference post sign, 10 x 36 in, in a 36 in cell: white on green."""
    width = round(CELL * 10 / 36)
    left = (CELL - width) // 2
    draw.rounded_rectangle((left, 2, left + width - 1, CELL - 3), radius=6, fill=GREEN)
    draw.rounded_rectangle((left + 4, 6, left + width - 5, CELL - 7), radius=4, outline=WHITE,
                           width=3)
    draw.text((CELL / 2, 46), "MILE", fill=WHITE, font=font(16), anchor="mm")
    draw.text((CELL / 2, 140), str(number), fill=WHITE, font=font(62), anchor="mm")


def main():
    rows = (len(CELLS) + COLUMNS - 1) // COLUMNS
    atlas = Image.new("RGBA", (CELL * COLUMNS, CELL * rows), (0, 0, 0, 0))
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
        elif name == "pedestrian":
            pedestrian(draw)
        elif name == "ahead":
            text_cell(draw, ["AHEAD"], YELLOW, BLACK, BLACK, [58])
        elif name == "arrow_down_left":
            arrow_down_left(draw)
        elif name.startswith("limit_45"):
            left, width = regulatory(draw, ["SPEED", "LIMIT", "45"], [38, 38, 84])
            if name.endswith("weathered"):
                weather(cell, left, width)
        elif name == "deer_crossing":
            diamond(draw)
            deer(draw)
        elif name.startswith("mile_"):
            milepost(draw, int(name.split("_")[1]))
        elif name == "bus_stop":
            bus_stop(draw)
        atlas.paste(cell, ((index % COLUMNS) * CELL, (index // COLUMNS) * CELL))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(OUT)
    print(f"Wrote {OUT} with {len(CELLS)} cells: {', '.join(CELLS)}")


if __name__ == "__main__":
    main()
