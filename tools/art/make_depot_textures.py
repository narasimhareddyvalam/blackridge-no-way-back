"""Makes the bigger depot's grey cladding from Poly Haven's Box Profile Metal Sheet (CC0).

The red sheet's colour map becomes a light warm grey, keeping its fasteners, streaks and the
shading of its ribs; the shed uses the sheet's own normal and ARM maps from the depot yard's copy.

Usage, from the repository root:
    python3 -I tools/art/make_depot_textures.py
"""

import pathlib

from PIL import Image, ImageStat

SOURCE = pathlib.Path("game/features/environments/depot_yard/polyhaven/textures/"
                      "box_profile_metal_sheet/box_profile_metal_sheet_diff_2k.jpg")
TARGET = pathlib.Path("game/features/environments/industrial_loop/art/depot/"
                      "cladding_grey_diff_2k.jpg")
MEAN = 168.0
CONTRAST = 1.6
TINT = (1.0, 0.99, 0.965)


def main() -> None:
    grey = Image.open(SOURCE).convert("L")
    mean = ImageStat.Stat(grey).mean[0]
    level = grey.point(lambda value: max(0, min(255, round(MEAN + (value - mean) * CONTRAST))))
    channels = [level.point(lambda value, tint=tint: min(255, round(value * tint))) for tint in TINT]
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    Image.merge("RGB", channels).save(TARGET, quality=92)
    result = ImageStat.Stat(Image.open(TARGET)).mean
    print(f"{TARGET}: mean {result[0]:.0f}, {result[1]:.0f}, {result[2]:.0f} (from {mean:.0f})")


if __name__ == "__main__":
    main()
