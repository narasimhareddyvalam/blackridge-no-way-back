"""Draws the south valley road's gas station and shop signs (#267, part C) as one atlas,
`game/features/environments/industrial_loop/art/town/town_signs.png`: four columns by four rows of
512 x 256 cells. No sign carries a real brand; the words are what such signs say.

Cells, left to right, top to bottom:
0 GAS: the price sign's lit header, white on deep blue.
1-3 REGULAR, PLUS, DIESEL: its price panels, white grade names on charcoal and red seven-segment
  LED digits with the US pump's 9/10 cent, as small-town price signs read: 3.59, 3.89 and 4.19
  dollars a gallon (2026 US averages ran about 3.20-3.60 for regular, diesel about 0.60 more;
  a small station by a highway prices above them).
4 GROCERY: the store's lit fascia.
5 ICE: an outdoor ice merchandiser's front, blue on white with a snowflake.
6 PROPANE EXCHANGE: the cage's sign, red on white.
7 NEWSPAPERS: the vending box's label.
8-10 HARDWARE, LAUNDROMAT, BARBER: the three shops' fascia boards, faded paint.
11 AIR / WATER: the air machine's front.
12 OPEN 24 HOURS: the store's window sign, lit red.
13 STOP ENGINE / NO SMOKING: the pumps' warning label, as on every US island.
14 the price sign's back and sides, plain charcoal; 15 unused.
And `store_interior.png`: the store's lit inside as seen through its glass, a little blurred:
ceiling strip lights, a wall of cooler doors stocked with bottles, shelf aisles of goods, the
floor. And `cage_mesh.png`: one 50 mm cell of a propane exchange cage's galvanised welded wire, 4 mm wire,
open between (alpha 0), repeating over the cage's panels.

Usage, from the repository root (needs the already installed Pillow):
    python3 -I tools/art/make_town_signs.py
"""

import pathlib

from PIL import Image, ImageDraw, ImageFont

TARGET = pathlib.Path("game/features/environments/industrial_loop/art/town/town_signs.png")
INTERIOR = pathlib.Path("game/features/environments/industrial_loop/art/town/store_interior.png")
MESH = pathlib.Path("game/features/environments/industrial_loop/art/town/cage_mesh.png")
MESH_PIXELS = 64
MESH_CELL = 0.05
MESH_WIRE = 0.004
MESH_STEEL = (150, 156, 160)
CELL = (512, 256)
COLUMNS = 4
BLUE = (16, 52, 120)
CHARCOAL = (34, 36, 40)
LED = (255, 52, 28)
PRICES = [("REGULAR", "3.59"), ("PLUS", "3.89"), ("DIESEL", "4.19")]
FIT = 460
SEGMENTS = {"0": "abcdef", "1": "bc", "2": "abged", "3": "abgcd", "4": "fgbc", "5": "afgcd",
            "6": "afgedc", "7": "abc", "8": "abcdefg", "9": "abcfgd"}


def font(size: int, bold: bool = True) -> ImageFont.FreeTypeFont:
    names = ["/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else
             "/System/Library/Fonts/Supplemental/Arial.ttf", "/System/Library/Fonts/Helvetica.ttc"]
    for name in names:
        if pathlib.Path(name).exists():
            return ImageFont.truetype(name, size)
    return ImageFont.load_default()


def cell(atlas: Image.Image, index: int, colour: tuple) -> tuple:
    left, top = (index % COLUMNS) * CELL[0], (index // COLUMNS) * CELL[1]
    ImageDraw.Draw(atlas).rectangle((left, top, left + CELL[0] - 1, top + CELL[1] - 1),
                                    fill=colour)
    return left, top


def words(draw: ImageDraw.ImageDraw, at: tuple, text: str, size: int, colour: tuple,
          bold: bool = True, room: int = FIT) -> None:
    while size > 12 and draw.textlength(text, font=font(size, bold)) > room:
        size -= 2
    draw.text(at, text, fill=colour, font=font(size, bold), anchor="mm")


def digit(draw: ImageDraw.ImageDraw, left: float, top: float, width: float, height: float,
          value: str) -> None:
    thick = width * 0.18
    half = height / 2.0
    bars = {"a": (left, top, left + width, top + thick),
            "g": (left, top + half - thick / 2, left + width, top + half + thick / 2),
            "d": (left, top + height - thick, left + width, top + height),
            "f": (left, top, left + thick, top + half), "b": (left + width - thick, top,
                                                             left + width, top + half),
            "e": (left, top + half, left + thick, top + height),
            "c": (left + width - thick, top + half, left + width, top + height)}
    for name, box in bars.items():
        lit = name in SEGMENTS[value]
        draw.rectangle(box, fill=LED if lit else (60, 14, 10))


def price(draw: ImageDraw.ImageDraw, left: int, top: int, grade: str, value: str) -> None:
    words(draw, (left + 105, top + 128), grade, 52, (236, 236, 232), room=190)
    x = left + 222
    for character in value:
        if character == ".":
            draw.rectangle((x - 6, top + 186, x + 6, top + 200), fill=LED)
            x += 16
            continue
        digit(draw, x, top + 56, 46, 144, character)
        x += 60
    digit(draw, x + 2, top + 56, 24, 62, "9")
    draw.line((x + 2, top + 140, x + 26, top + 128), fill=LED, width=4)
    digit(draw, x + 2, top + 146, 24, 54, "1")


def interior() -> None:
    import random
    from PIL import ImageFilter
    rng = random.Random(267)
    width, height = 1024, 256
    room = Image.new("RGB", (width, height), (196, 190, 176))
    draw = ImageDraw.Draw(room)
    draw.rectangle((0, 0, width, 38), fill=(232, 230, 222))
    for x in range(40, width, 170):
        draw.rectangle((x, 12, x + 110, 20), fill=(255, 255, 250))
    draw.rectangle((0, 38, width, 120), fill=(150, 156, 160))
    for door in range(0, width, 64):
        draw.rectangle((door + 3, 44, door + 60, 118), fill=(206, 226, 236))
        for shelf in range(4):
            y = 52 + shelf * 17
            for item in range(door + 6, door + 58, 7):
                draw.rectangle((item, y, item + 5, y + 10), fill=rng.choice(
                    [(190, 40, 30), (30, 90, 170), (240, 200, 40), (40, 140, 60), (240, 240, 240),
                     (120, 60, 30)]))
    for aisle in range(0, width, 128):
        draw.rectangle((aisle + 10, 130, aisle + 118, 232), fill=(210, 210, 206))
        for shelf in range(5):
            y = 138 + shelf * 19
            draw.rectangle((aisle + 10, y + 13, aisle + 118, y + 15), fill=(120, 120, 120))
            for item in range(aisle + 12, aisle + 116, 6):
                draw.rectangle((item, y, item + 4, y + 12), fill=rng.choice(
                    [(200, 50, 40), (40, 80, 160), (230, 190, 50), (60, 150, 70), (235, 235, 230),
                     (150, 90, 40), (90, 50, 120)]))
    draw.rectangle((0, 232, width, height), fill=(168, 166, 160))
    room = room.filter(ImageFilter.GaussianBlur(1.6))
    room.save(INTERIOR)
    print(f"wrote {INTERIOR}: the store's lit inside seen through its glass")


def main() -> None:
    atlas = Image.new("RGB", (CELL[0] * COLUMNS, CELL[1] * 4), CHARCOAL)
    draw = ImageDraw.Draw(atlas)
    left, top = cell(atlas, 0, BLUE)
    words(draw, (left + 256, top + 128), "GAS", 170, (250, 250, 248))
    for index, (grade, value) in enumerate(PRICES):
        left, top = cell(atlas, 1 + index, CHARCOAL)
        price(draw, left, top, grade, value)
    left, top = cell(atlas, 4, (238, 236, 228))
    words(draw, (left + 256, top + 128), "GROCERY", 110, (150, 28, 24))
    left, top = cell(atlas, 5, (246, 248, 250))
    words(draw, (left + 310, top + 128), "ICE", 170, (22, 86, 170), room=300)
    for spoke in range(6):
        centre = (left + 110, top + 128)
        import math
        angle = math.radians(60 * spoke)
        draw.line((centre[0], centre[1], centre[0] + 70 * math.cos(angle),
                   centre[1] + 70 * math.sin(angle)), fill=(22, 86, 170), width=10)
    left, top = cell(atlas, 6, (246, 244, 240))
    words(draw, (left + 256, top + 92), "PROPANE", 96, (186, 30, 26))
    words(draw, (left + 256, top + 180), "EXCHANGE", 64, (40, 40, 40))
    left, top = cell(atlas, 7, (230, 228, 220))
    words(draw, (left + 256, top + 128), "NEWSPAPERS", 76, (24, 24, 24))
    for index, name in enumerate(["HARDWARE", "LAUNDROMAT", "BARBER"]):
        left, top = cell(atlas, 8 + index, [(92, 52, 40), (40, 70, 92), (52, 52, 52)][index])
        words(draw, (left + 256, top + 128), name, 84, (226, 220, 204))
    left, top = cell(atlas, 11, (196, 30, 28))
    words(draw, (left + 256, top + 92), "AIR", 100, (250, 250, 248))
    words(draw, (left + 256, top + 186), "WATER", 64, (250, 250, 248))
    left, top = cell(atlas, 12, (12, 12, 14))
    words(draw, (left + 256, top + 128), "OPEN 24 HOURS", 66, (255, 40, 40))
    left, top = cell(atlas, 13, (250, 222, 40))
    words(draw, (left + 256, top + 92), "STOP ENGINE", 66, (20, 20, 20))
    words(draw, (left + 256, top + 178), "NO SMOKING", 58, (180, 20, 20))
    cell(atlas, 14, CHARCOAL)
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(TARGET)
    print(f"wrote {TARGET} ({atlas.width} x {atlas.height})")
    interior()
    mesh = Image.new("RGBA", (MESH_PIXELS, MESH_PIXELS), (0, 0, 0, 0))
    wires = ImageDraw.Draw(mesh)
    wire = max(2, round(MESH_PIXELS * MESH_WIRE / MESH_CELL))
    wires.rectangle((0, 0, wire - 1, MESH_PIXELS), fill=MESH_STEEL + (255,))
    wires.rectangle((0, 0, MESH_PIXELS, wire - 1), fill=MESH_STEEL + (255,))
    mesh.save(MESH)
    print(f"wrote {MESH}: one {MESH_CELL * 1000:.0f} mm cell of welded wire, {MESH_WIRE * 1000:.0f} mm wire")


if __name__ == "__main__":
    main()
