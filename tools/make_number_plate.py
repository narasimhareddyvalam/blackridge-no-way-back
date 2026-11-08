"""Draw the van's Blackridge number plate, "BR 048", for the Iveco van (decision C31).

The plate is cream with a thin dark border, the jurisdiction "BLACKRIDGE" along the top in
blue and the registration in black, raised like stamped metal. Its shape matches the plate on
the Iveco model, which `tools/art/convert_iveco.py` paints it onto, front and rear.

The oncoming van's plate ("BR 731") is drawn the same way, at half size, straight into its
feature folder:
    python3 -I tools/make_number_plate.py --registration "BR 731" --width 768 \
        --out game/features/vehicles/oncoming_van/art/number_plate.png

Usage, from the repository root:
    python3 -I tools/make_number_plate.py
"""

import argparse
import pathlib

from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT = pathlib.Path("source_assets/artwork/number_plate.png")
SIZE = (1536, 320)
CREAM = (236, 232, 219)
EDGE = (205, 200, 186)
INK = (24, 26, 31)
BLUE = (30, 52, 104)
REGISTRATION = "BR 048"
JURISDICTION = "BLACKRIDGE"


def font(size):
    for path in ("/System/Library/Fonts/Supplemental/DIN Condensed Bold.ttf",
                 "/System/Library/Fonts/Supplemental/Arial Narrow Bold.ttf",
                 "/System/Library/Fonts/Supplemental/Arial Bold.ttf"):
        if pathlib.Path(path).is_file():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def centred(draw, text, face, top, colour, spacing=0):
    widths = [draw.textlength(letter, font=face) for letter in text]
    width = sum(widths) + spacing * (len(text) - 1)
    x = (SIZE[0] - width) / 2
    for letter, advance in zip(text, widths):
        draw.text((x, top), letter, font=face, fill=colour)
        x += advance + spacing


def raised(text, face, top, colour, spacing=0):
    layer = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    centred(draw, text, face, top, colour + (255,), spacing)
    alpha = layer.getchannel("A")
    shadow = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    shadow.putalpha(alpha.point(lambda value: value * 0.45).filter(ImageFilter.GaussianBlur(3)))
    light = Image.new("RGBA", SIZE, (255, 255, 255, 0))
    light.putalpha(alpha.point(lambda value: value * 0.5))
    return shadow, light, layer


def main():
    options = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    options.add_argument("--registration", default=REGISTRATION)
    options.add_argument("--out", type=pathlib.Path, default=OUT)
    options.add_argument("--width", type=int, default=SIZE[0])
    arguments = options.parse_args()
    plate = Image.new("RGBA", SIZE, CREAM + (255,))
    draw = ImageDraw.Draw(plate)
    for step in range(SIZE[1]):
        shade = 1.0 - 0.06 * abs(step / SIZE[1] - 0.45)
        draw.line([(0, step), (SIZE[0], step)], fill=tuple(int(c * shade) for c in CREAM))
    draw.rounded_rectangle([6, 6, SIZE[0] - 7, SIZE[1] - 7], radius=26, outline=EDGE, width=10)
    draw.rounded_rectangle([18, 18, SIZE[0] - 19, SIZE[1] - 19], radius=18, outline=INK, width=5)
    for text, size, top, colour, spacing in ((JURISDICTION, 58, 26, BLUE, 14),
                                             (arguments.registration, 222, 100, INK, 34)):
        shadow, light, layer = raised(text, font(size), top, colour, spacing)
        plate.alpha_composite(shadow, (5, 6))
        plate.alpha_composite(light, (-2, -2))
        plate.alpha_composite(layer)
    size = (arguments.width, round(SIZE[1] * arguments.width / SIZE[0]))
    if size != SIZE:
        plate = plate.resize(size, Image.LANCZOS)
    arguments.out.parent.mkdir(parents=True, exist_ok=True)
    plate.convert("RGB").save(arguments.out)
    print(f"Wrote {arguments.out} ({size[0]}x{size[1]})")


if __name__ == "__main__":
    main()
