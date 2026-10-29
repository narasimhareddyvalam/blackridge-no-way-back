"""Create derived variants of downloaded CC0 textures for the depot yard.

The Poly Haven box-profile cladding is rust red; the approved depot reference
uses grey cladding. This keeps the original file and writes a grey version
that preserves its photographed light and dirt variation.

Usage, from the repository root (needs the already installed Pillow):
    python3 -I tools/assets/derive_textures.py
"""

import pathlib

from PIL import Image, ImageOps

ROOT = pathlib.Path("game/features/environments/depot_yard")
SOURCE = ROOT / "polyhaven/textures/box_profile_metal_sheet/box_profile_metal_sheet_diff_2k.jpg"
TARGET = ROOT / "derived/box_profile_metal_sheet_grey_diff_2k.jpg"
TARGET_MEAN = 118


def main() -> None:
    grey = ImageOps.grayscale(Image.open(SOURCE))
    mean = sum(index * count for index, count in enumerate(grey.histogram())) / (
        grey.width * grey.height)
    scaled = grey.point(lambda value: min(255, round(value * TARGET_MEAN / mean)))
    tinted = Image.merge("RGB", (
        scaled.point(lambda value: round(value * 0.96)),
        scaled.point(lambda value: round(value * 0.99)),
        scaled))
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    tinted.save(TARGET, quality=92)
    print(f"Wrote {TARGET} (source mean {mean:.1f}, target {TARGET_MEAN})")


if __name__ == "__main__":
    main()
