"""Bake the mission map's ground (#356) from straight-down captures of the district.

Each capture is `tools/captures/capture_map_base.gd` drawn unshaded at 1000 x 625 pixels with an
orthographic camera 250 m tall, so 0.4 m a pixel and 400 m wide. The four tiles cover x -170..630
and z -262.5..237.5. This stitches them, tells apart the terrain, the asphalt roads, the paved
yards (wider than a 7 m disk, the roads being narrower) and the buildings by colour, and repaints them in the map's night palette: dark slate
ground, paved yards a step lighter, light roads with a darker casing, and the buildings' ground
left dark for the map's own 3D blocks to stand on. Writes the ground PNG and its bounds (JSON).

Usage, from the repository root:
    python3 -I tools/art/bake_mission_map.py <captures folder> <out folder>
"""

import json
import pathlib
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

PIXEL = 0.4
TILE = (1000, 625)
CENTRES = [(30.0, -137.5), (30.0, 112.5), (430.0, -137.5), (430.0, 112.5)]
ORIGIN = (-170.0, -262.5)
SIZE_M = (800.0, 500.0)
GROUND = (11, 14, 19)
PAVED = (30, 36, 43)
ROAD = (156, 166, 174)
CASING = (66, 74, 83)
BUILT = (22, 26, 32)


def stitch(folder: pathlib.Path) -> np.ndarray:
    width = int(SIZE_M[0] / PIXEL)
    height = int(SIZE_M[1] / PIXEL)
    canvas = np.zeros((height, width, 3), np.float32)
    for x, z in CENTRES:
        name = f"tile_{x:g}_{z:g}.png"
        tile = np.asarray(Image.open(folder / name).convert("RGB")).astype(np.float32)
        left = int(round((x - TILE[0] * PIXEL / 2 - ORIGIN[0]) / PIXEL))
        top = int(round((z - TILE[1] * PIXEL / 2 - ORIGIN[1]) / PIXEL))
        canvas[top:top + TILE[1], left:left + TILE[0]] = tile
    return canvas


def paint(source: np.ndarray) -> np.ndarray:
    red, green, blue = source[..., 0], source[..., 1], source[..., 2]
    high = source.max(-1)
    low = source.min(-1)
    saturation = (high - low) / (high + 1e-3)
    terrain = (red > green) & (green > blue) & (saturation > 0.25) & (high < 170)
    water = (blue > red + 8) & (high < 70) & (saturation > 0.15)
    dark = (high < 80) & (saturation < 0.25) & ~water
    glow = high > 200
    radius = 17
    yy, xx = np.mgrid[-radius:radius + 1, -radius:radius + 1]
    disk = xx * xx + yy * yy <= radius * radius
    paved = ndimage.binary_opening(ndimage.binary_closing(dark, iterations=3), structure=disk) & dark
    road = dark & ~paved
    road = ndimage.binary_opening(road, iterations=1)
    built = ndimage.binary_opening(~(terrain | water | dark | glow), iterations=1)
    out = np.zeros_like(source)
    out[:] = GROUND
    out[paved] = PAVED
    out[built] = BUILT
    casing = ndimage.binary_dilation(road, iterations=2) & ~road & ~built
    out[casing] = CASING
    out[road] = ROAD
    return np.clip(out, 0, 255).astype(np.uint8)


def main() -> None:
    folder = pathlib.Path(sys.argv[1])
    out = pathlib.Path(sys.argv[2])
    out.mkdir(parents=True, exist_ok=True)
    Image.fromarray(paint(stitch(folder))).save(out / "mission_map_ground.png", optimize=True)
    bounds = {"origin": list(ORIGIN), "size": list(SIZE_M), "metres_a_pixel": PIXEL}
    (out / "mission_map_ground.json").write_text(json.dumps(bounds, indent=2) + "\n")


if __name__ == "__main__":
    main()
