"""Draws the dash's ringing-phone sheet (Assignment 7, CHANGE-BRIEF.md §2): six 64 x 64 cells in
one row (hframes 6, vframes 1), white on transparent, so the game tints it.

Frame order, left to right: 0 the handset alone; 1, 2, 3 one, two and three ring arcs spreading
from its earpiece; 4 the inner arc gone and the outer two fading; 5 only the outer arc, faint.
The handset stays at the same place in every cell (registration), so only the arcs change.

The sheet is drawn by this script, so it needs no licence; the script is its provenance.
Run from the repository root:
    python3 tools/art/make_phone_ring_sheet.py
It writes game/features/vehicles/freight_van/art/ring/phone_ring.png and prints its size.
"""

import math
import pathlib

from PIL import Image, ImageDraw

CELL = 64
FRAMES = 6
SCALE = 4
TARGET = pathlib.Path("game/features/vehicles/freight_van/art/ring/phone_ring.png")
## Each frame's ring arcs: (radius, opacity), around the handset's earpiece corner.
RADII = (7, 12, 17)
ARCS = [
    [],
    [(RADII[0], 1.0)],
    [(RADII[0], 1.0), (RADII[1], 1.0)],
    [(RADII[0], 1.0), (RADII[1], 1.0), (RADII[2], 1.0)],
    [(RADII[1], 0.75), (RADII[2], 0.75)],
    [(RADII[2], 0.4)],
]
## The handset: a curved grip, its arc's centre and radius, from the earpiece to the mouthpiece,
## with a rounded pad at each end; the ring arcs spread from the same centre into the top-right.
CENTRE = (41, 22)
GRIP = 25
ANGLES = (95, 175)
WHITE = (255, 255, 255, 255)


def handset(draw):
    s = SCALE
    cx, cy = CENTRE[0] * s, CENTRE[1] * s
    r = GRIP * s
    draw.arc([cx - r, cy - r, cx + r, cy + r], start=ANGLES[0], end=ANGLES[1], fill=WHITE,
             width=7 * s)
    for angle in ANGLES:
        a = math.radians(angle)
        x = cx + (r - 3.5 * s) * math.cos(a)
        y = cy + (r - 3.5 * s) * math.sin(a)
        draw.ellipse([x - 7 * s, y - 7 * s, x + 7 * s, y + 7 * s], fill=WHITE)


def frame(index):
    size = (CELL * SCALE, CELL * SCALE)
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    handset(draw)
    cx, cy = CENTRE[0] * SCALE, CENTRE[1] * SCALE
    for radius, opacity in ARCS[index]:
        r = radius * SCALE
        draw.arc([cx - r, cy - r, cx + r, cy + r], start=-80, end=-10,
                 fill=(255, 255, 255, int(255 * opacity)), width=3 * SCALE)
    return image.resize((CELL, CELL), Image.LANCZOS)


def main():
    sheet = Image.new("RGBA", (CELL * FRAMES, CELL), (0, 0, 0, 0))
    for index in range(FRAMES):
        sheet.alpha_composite(frame(index), (index * CELL, 0))
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(TARGET, optimize=True)
    print(f"{TARGET}: {sheet.size[0]} x {sheet.size[1]}, {FRAMES} cells of {CELL} x {CELL}")


if __name__ == "__main__":
    main()
