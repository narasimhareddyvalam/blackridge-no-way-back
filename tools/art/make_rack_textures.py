"""Makes the transfer shed's pallet racking textures (#267), drawn here at real sizes.

upright_face.png: the face of a teardrop upright, 3 in (76.2 mm) wide, one 2 in (50.8 mm) step of
    its punching tall, so it repeats up the post: the slate grey-green paint sampled from the
    author's photo of a warehouse aisle (sRGB 0.27, 0.31, 0.28), two columns of teardrop slots,
    each about 3/4 in tall and 3/8 in wide, round end up, as teardrop racking is punched. A
    slot shows what a real one does: the open-backed channel's shadowed inside, so the post is
    drawn solid (cutting the slots through cost 0.27 ms of GPU time with the decks, #267).
wire_deck.png: one 2.5 x 4 in (63.5 x 101.6 mm) cell of a wire mesh deck, galvanised wire 4 mm
    thick round an open cell (alpha 0), repeating over the deck.
aisle_signs.png: six aisle boards, 01 to 06, white numerals on navy as the photo's "03", in a row.
bay_labels.png: four location labels, each a white label with a barcode and its text below.
board_edge.png: the edge of a stack of flat corrugated board, 0.1 m of it: kraft sheets about
    4 mm thick with darker flutes and glue lines between them.
carton_face.png: one face of a shipping carton, in the depot's carton's kraft (sampled from Poly
    Haven's Cardboard Box 01: sRGB 0.62, 0.55, 0.41): the flaps' seam across its top third, a
    strip of brown tape over it, a white shipping label and a printed this-way-up mark, for the
    stacks of cartons wrapped on the racks' pallets, tiled one face per carton.
duct_seam.png: one turn of a white spiral duct's lock seam, the seam a raised line wound once
    round the duct every 0.3 m of its length: a diagonal across the tile.
board_top.png: the top sheet of a bundle of flat board: plain kraft with a faint grain and
    scuffs.

Usage, from the repository root:
    python3 -I tools/art/make_rack_textures.py
"""

import math
import pathlib
import random

from PIL import Image, ImageDraw, ImageFont

TARGET = pathlib.Path("game/features/environments/industrial_loop/art/racking")
UPRIGHT = (0.27, 0.31, 0.28)
CHANNEL = (0.05, 0.06, 0.055)
PX_PER_MM = 2.0
DECK_WIRE = (168, 172, 170)
NAVY = (24, 38, 82)
KRAFT = (168, 128, 86)
CARTON = (158, 140, 105)
TAPE = (139, 104, 61)
SEED = 267


def srgb(colour: tuple) -> tuple:
    return tuple(round(channel * 255) for channel in colour)


def upright_face() -> None:
    width, height = round(76.2 * PX_PER_MM), round(50.8 * PX_PER_MM)
    image = Image.new("RGB", (width, height), srgb(UPRIGHT))
    draw = ImageDraw.Draw(image)
    slot_w, slot_h = 9.5 * PX_PER_MM, 19.0 * PX_PER_MM
    inside = srgb(CHANNEL)
    for column in (0.3, 0.7):
        cx, top = width * column, (height - slot_h) / 2.0
        draw.ellipse((cx - slot_w / 2, top, cx + slot_w / 2, top + slot_w), fill=inside)
        draw.polygon([(cx - slot_w / 2, top + slot_w / 2), (cx + slot_w / 2, top + slot_w / 2),
                      (cx, top + slot_h)], fill=inside)
    image.save(TARGET / "upright_face.png")


def wire_deck() -> None:
    width, height = round(63.5 * PX_PER_MM), round(101.6 * PX_PER_MM)
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    wire = round(4.0 * PX_PER_MM)
    draw.rectangle((0, 0, wire - 1, height), fill=DECK_WIRE + (255,))
    draw.rectangle((0, 0, width, wire - 1), fill=DECK_WIRE + (255,))
    image.save(TARGET / "wire_deck.png")


def font(size: int) -> ImageFont.FreeTypeFont:
    for name in ("/System/Library/Fonts/Supplemental/Arial Bold.ttf",
                 "/System/Library/Fonts/Helvetica.ttc"):
        if pathlib.Path(name).exists():
            return ImageFont.truetype(name, size)
    return ImageFont.load_default()


def aisle_signs() -> None:
    board_w, board_h = 128, 192
    image = Image.new("RGB", (board_w * 6, board_h), NAVY)
    draw = ImageDraw.Draw(image)
    numerals = font(96)
    for index in range(6):
        left = index * board_w
        draw.rectangle((left + 4, 4, left + board_w - 5, board_h - 5), outline=(235, 238, 242),
                       width=4)
        draw.text((left + board_w / 2, board_h / 2), "%02d" % (index + 1), fill=(240, 242, 245),
                  font=numerals, anchor="mm")
    image.save(TARGET / "aisle_signs.png")


def bay_labels() -> None:
    random.seed(SEED)
    label_w, label_h = 256, 96
    image = Image.new("RGB", (label_w * 4, label_h), (244, 244, 240))
    draw = ImageDraw.Draw(image)
    text = font(18)
    for index in range(4):
        left = index * label_w
        x = left + 16
        while x < left + label_w - 16:
            bar = random.choice((2, 2, 3, 4, 6))
            draw.rectangle((x, 12, x + bar - 1, 58), fill=(16, 16, 16))
            x += bar + random.choice((2, 3, 4))
        draw.text((left + label_w / 2, 76), "%02d-%02d-%s" % (random.randint(1, 6),
                  random.randint(1, 7), "ABCD"[index]), fill=(16, 16, 16), font=text,
                  anchor="mm")
        draw.rectangle((left, 0, left + label_w - 1, label_h - 1), outline=(190, 190, 186))
    image.save(TARGET / "bay_labels.png")


def board_edge() -> None:
    random.seed(SEED + 1)
    width, height = 256, 256
    image = Image.new("RGB", (width, height), KRAFT)
    pixels = image.load()
    sheet = 10.24
    for y in range(height):
        phase = (y % sheet) / sheet
        for x in range(width):
            flute = 0.5 + 0.5 * math.sin(x / width * math.tau * 64 + y * 0.7)
            shade = 0.86 + 0.1 * flute if 0.15 < phase < 0.85 else 0.62
            r, g, b = KRAFT
            pixels[x, y] = (round(r * shade), round(g * shade), round(b * shade))
    image.save(TARGET / "board_edge.png")


def carton_face() -> None:
    random.seed(SEED + 2)
    width, height = 256, 174
    image = Image.new("RGB", (width, height), CARTON)
    draw = ImageDraw.Draw(image)
    for y in range(height):
        for x in range(0, width, 2):
            if random.random() < 0.08:
                shade = random.randint(-10, 8)
                draw.point((x, y), fill=tuple(max(0, min(255, c + shade)) for c in CARTON))
    seam = round(height * 0.3)
    draw.line((0, seam, width, seam), fill=(118, 102, 74), width=2)
    draw.rectangle((width * 0.42, 0, width * 0.58, seam + 14), fill=TAPE)
    draw.rectangle((width * 0.08, height * 0.5, width * 0.36, height * 0.82),
                   fill=(236, 236, 230), outline=(200, 200, 194))
    for row in range(3):
        y = height * 0.56 + row * 9
        draw.line((width * 0.11, y, width * 0.32, y), fill=(60, 60, 60), width=2)
    for column in (0.72, 0.8):
        x = width * column
        draw.line((x, height * 0.78, x, height * 0.55), fill=(52, 44, 34), width=3)
        draw.polygon([(x - 6, height * 0.6), (x + 6, height * 0.6), (x, height * 0.5)],
                     fill=(52, 44, 34))
    draw.rectangle((0, 0, width - 1, height - 1), outline=(120, 104, 76))
    image.save(TARGET / "carton_face.png")


def board_top() -> None:
    random.seed(SEED + 3)
    size = 256
    image = Image.new("RGB", (size, size), KRAFT)
    draw = ImageDraw.Draw(image)
    for y in range(0, size, 1):
        shade = round(6 * math.sin(y * 0.9) + random.randint(-4, 4))
        draw.line((0, y, size, y), fill=tuple(max(0, min(255, c + shade)) for c in KRAFT))
    for _ in range(14):
        x, y = random.randint(0, size), random.randint(0, size)
        draw.line((x, y, x + random.randint(-40, 40), y + random.randint(-6, 6)),
                  fill=(140, 104, 68), width=1)
    image.save(TARGET / "board_top.png")


def duct_seam() -> None:
    size = 256
    image = Image.new("RGB", (size, size), (222, 224, 226))
    draw = ImageDraw.Draw(image)
    for offset in (-size, 0, size):
        draw.line((0, offset + size, size, offset), fill=(176, 178, 180), width=6)
        draw.line((0, offset + size + 4, size, offset + 4), fill=(238, 240, 242), width=2)
    image.save(TARGET / "duct_seam.png")


def main() -> None:
    TARGET.mkdir(parents=True, exist_ok=True)
    upright_face()
    wire_deck()
    aisle_signs()
    bay_labels()
    board_edge()
    carton_face()
    board_top()
    duct_seam()
    for path in sorted(TARGET.glob("*.png")):
        with Image.open(path) as image:
            print(f"{path}: {image.size[0]} x {image.size[1]} {image.mode}")


if __name__ == "__main__":
    main()
