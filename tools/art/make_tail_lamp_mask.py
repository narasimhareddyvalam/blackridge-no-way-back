"""The van's tail lamps lit as a real van's (#343, #344): the masks of the Iveco lens texture
(`iveco_exterior_Window_baseColor.webp`, which the tail lamps share with the windows) that
`tail_lamp.gdshader` lights them by. Red: where the texture is the lamp's red lens, as bright as
its red (so the glow keeps the lens's prisms), at least FLOOR; the tail and stop glow there.
Green: where it is the clear section's solid chrome reflector (neutral grey, not see-through); the
indicator and the reversing lamp shine there. Black elsewhere: the clear cover (see-through), the
trim. Edges softened by a pixel.

Run from the repository root (an output path may follow; by default it writes beside the texture):
    python3 -I tools/art/make_tail_lamp_mask.py [out.png]
"""

import pathlib
import sys

from PIL import Image, ImageFilter

ART = pathlib.Path("game/features/vehicles/freight_van/art/iveco")
SOURCE = ART / "iveco_exterior_Window_baseColor.webp"
TARGET = ART / "tail_lamp_masks.png"
## Red: its red channel at least this bright and this many times its green and its blue.
RED_LEAST = 0.35
RED_OVER = 1.8
## Where red, the mask is the texture's red over this (its brightest red lens), at least FLOOR.
RED_FULL = 0.8
FLOOR = 0.45
## Chrome: solid (alpha over a half), its channels within this of each other, between these.
CHROME_SPREAD = 0.05
CHROME_SHADE = (0.27, 0.75)


def masks(pixel):
    r, g, b, a = (channel / 255.0 for channel in pixel)
    if r >= RED_LEAST and r >= RED_OVER * g and r >= RED_OVER * b:
        return (int(255 * max(FLOOR, min(1.0, r / RED_FULL))), 0, 0)
    if a > 0.5 and abs(r - g) < CHROME_SPREAD and abs(r - b) < CHROME_SPREAD \
            and CHROME_SHADE[0] < r < CHROME_SHADE[1]:
        return (0, 255, 0)
    return (0, 0, 0)


def main():
    out = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else TARGET
    lens = Image.open(SOURCE).convert("RGBA")
    mask = Image.new("RGB", lens.size, (0, 0, 0))
    mask.putdata([masks(pixel) for pixel in getattr(lens, "get_flattened_data", lens.getdata)()])
    mask = mask.filter(ImageFilter.GaussianBlur(1.0))
    mask.save(out, optimize=True)
    pixels = list(getattr(mask, "get_flattened_data", mask.getdata)())
    red = sum(1 for pixel in pixels if pixel[0] > 100)
    chrome = sum(1 for pixel in pixels if pixel[1] > 127)
    print(f"{out}: {mask.size[0]}x{mask.size[1]}, {red} red lens pixels, {chrome} chrome pixels")


if __name__ == "__main__":
    main()
