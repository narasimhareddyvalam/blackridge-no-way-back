"""Makes the bigger depot's own textures.

cladding_grey_diff_2k.jpg: from Poly Haven's Box Profile Metal Sheet (CC0). The red sheet's colour
    map becomes a light warm grey, keeping its fasteners, streaks and the shading of its ribs; the
    shed uses the sheet's own normal and ARM maps from the depot yard's copy.
hazard_stripes.png: drawn here, a tile of yellow and black stripes at 45 degrees, for the painted
    edges of bay 9's dock lift.

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
STRIPES = pathlib.Path("game/features/environments/industrial_loop/art/depot/hazard_stripes.png")
STRIPE_TILE = 128
STRIPE_PAIRS = 2
YELLOW = (242, 191, 13)
BLACK = (18, 18, 18)


def stripes() -> None:
    period = STRIPE_TILE // STRIPE_PAIRS
    tile = Image.new("RGB", (STRIPE_TILE, STRIPE_TILE))
    tile.putdata([YELLOW if (x + y) % period < period // 2 else BLACK
                  for y in range(STRIPE_TILE) for x in range(STRIPE_TILE)])
    tile.save(STRIPES)
    print(f"{STRIPES}: {STRIPE_TILE} px, {STRIPE_PAIRS} pairs of stripes")


def main() -> None:
    grey = Image.open(SOURCE).convert("L")
    mean = ImageStat.Stat(grey).mean[0]
    level = grey.point(lambda value: max(0, min(255, round(MEAN + (value - mean) * CONTRAST))))
    channels = [level.point(lambda value, tint=tint: min(255, round(value * tint))) for tint in TINT]
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    Image.merge("RGB", channels).save(TARGET, quality=92)
    result = ImageStat.Stat(Image.open(TARGET)).mean
    print(f"{TARGET}: mean {result[0]:.0f}, {result[1]:.0f}, {result[2]:.0f} (from {mean:.0f})")
    stripes()


if __name__ == "__main__":
    main()
