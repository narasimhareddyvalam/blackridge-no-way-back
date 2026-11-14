"""Draws the ripple data texture Rain Puddles V3 asks for (#273), used by the game's
`wet_ground.gdshader` (#275) and the trial of V3 itself, from Sébastien Lagarde's
description ("Water drop 2b - Dynamic rain and its effects", 2013): 256 x 256 px, tiling,
non-overlapping rings 4 to 12 px in radius (2.8 to 8.4 cm where the shader tiles it every
1/0.7 m), each with red its radial gradient (1 at its centre to 0 at its edge), green and blue
its outward direction (0.5 + 0.5 * x and y) and alpha a random time offset; empty texels red 0,
green and blue 0.5, alpha 0. Saved lossless.

Usage, from the repository root:
    python3 -I tools/art/make_ripple_data.py
"""

import pathlib
import random

import numpy as np
from PIL import Image

TARGETS = [pathlib.Path("game/features/environments/industrial_loop/art/wet_ground/ripple_data.png"),
           pathlib.Path("game/experiments/rain_puddles_v3/ripple_data.png")]
SIZE = 256
RADII = (4, 12)
TRIES = 6000
SEED = 273


def main() -> None:
    random.seed(SEED)
    data = np.zeros((SIZE, SIZE, 4), dtype=np.float32)
    data[:, :, 1:3] = 0.5
    taken = np.zeros((SIZE, SIZE), dtype=bool)
    ys, xs = np.mgrid[0:SIZE, 0:SIZE]
    rings = 0
    for _ in range(TRIES):
        radius = random.uniform(*RADII)
        cx, cy = random.uniform(0, SIZE), random.uniform(0, SIZE)
        dx = (xs - cx + SIZE / 2) % SIZE - SIZE / 2
        dy = (ys - cy + SIZE / 2) % SIZE - SIZE / 2
        distance = np.sqrt(dx * dx + dy * dy)
        inside = distance < radius
        if (taken & (distance < radius + 1)).any():
            continue
        taken |= inside
        rings += 1
        offset = random.random()
        r = np.clip(1.0 - distance / radius, 0.0, 1.0)
        safe = np.maximum(distance, 1e-4)
        data[inside, 0] = r[inside]
        data[inside, 1] = 0.5 + 0.5 * (dx / safe)[inside]
        data[inside, 2] = 0.5 + 0.5 * (dy / safe)[inside]
        data[inside, 3] = offset
    for target in TARGETS:
        Image.fromarray((data * 255.0 + 0.5).astype(np.uint8), "RGBA").save(target)
        print(f"{target}: {SIZE} px, {rings} rings, {taken.mean() * 100:.0f}% covered")


if __name__ == "__main__":
    main()
