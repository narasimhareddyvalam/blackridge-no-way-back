"""Makes red alder's bark for the forest highway's bare alders (#280) from Poly Haven's Chinese
Hackberry Bark (CC0): a smooth, thin bark with lichen patches, brown-green as photographed.
Red alder's is the same smooth, thin bark, but light grey, often whitened by lichen: the texture
is turned grey, keeping its photographed light, cracks and lichen, its mean set to sRGB 128 and
tinted a little green-grey (1.0, 1.0, 0.95). The game darkens it for the rain as it does the
conifers' bark.

Usage, from the repository root (needs the already installed Pillow):
    python3 -I tools/art/make_alder_bark.py
"""

import pathlib

from PIL import Image, ImageOps

SOURCE = pathlib.Path("game/features/environments/industrial_loop/polyhaven/textures/"
                      "chinese_hackberry_bark/chinese_hackberry_bark_diff_2k.jpg")
TARGET = pathlib.Path("game/features/environments/industrial_loop/art/trees/"
                      "red_alder_bark_diff.jpg")
TARGET_MEAN = 128
TINT = (1.0, 1.0, 0.95)


def main() -> None:
    grey = ImageOps.grayscale(Image.open(SOURCE))
    mean = sum(index * count for index, count in enumerate(grey.histogram())) / (
        grey.width * grey.height)
    scaled = grey.point(lambda value: min(255, round(value * TARGET_MEAN / mean)))
    channels = [scaled.point(lambda value, tint=tint: min(255, round(value * tint)))
                for tint in TINT]
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    Image.merge("RGB", channels).save(TARGET, quality=90)
    print(f"wrote {TARGET} ({scaled.width} x {scaled.height}), mean {TARGET_MEAN}")


if __name__ == "__main__":
    main()
