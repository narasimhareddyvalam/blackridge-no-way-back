"""Generate the headlight low-beam pattern used as a SpotLight3D light projector.

The image covers the spotlight's whole cone, with the top row pointing up. Rows above the
cutoff stay almost dark. A bright band sits just under the cutoff and fades downwards and
towards the sides. The right half's cutoff rises in a 15-degree step, as on a low beam
for right-hand traffic. Values are written sRGB-encoded because Godot samples light
projectors as sRGB.

Usage, from the repository root:
    python3 -I tools/make_low_beam_pattern.py
"""

import math
import pathlib

import numpy as np
from PIL import Image

OUT = pathlib.Path("game/features/vehicles/freight_van/art/low_beam_pattern.png")
SIZE = 256
HALF_ANGLE = 35.0
CUTOFF_ABOVE_AXIS = 1.4
STEP_RISE = 1.0
STRAY = 0.05
EDGE_SOFTNESS = 1.2


def to_srgb(linear: np.ndarray) -> np.ndarray:
    return np.where(linear <= 0.0031308, 12.92 * linear,
                    1.055 * np.power(linear, 1.0 / 2.4) - 0.055)


def main() -> None:
    tan_half = math.tan(math.radians(HALF_ANGLE))
    centres = (np.arange(SIZE) + 0.5) / (SIZE / 2.0) - 1.0
    side = np.degrees(np.arctan(centres[None, :] * tan_half))
    up = np.degrees(np.arctan(-centres[:, None] * tan_half))
    cutoff = CUTOFF_ABOVE_AXIS + np.clip(side * math.tan(math.radians(15.0)), 0.0, STEP_RISE)
    below = cutoff - up
    vertical = np.interp(below, [0.0, 1.5, 4.0, 8.0, 27.0], [1.0, 1.0, 0.45, 0.2, 0.08])
    vertical = STRAY + (vertical - STRAY) * np.clip(below / EDGE_SOFTNESS, 0.0, 1.0)
    horizontal = np.interp(np.abs(side), [0.0, 9.0, 20.0, 35.0], [1.0, 1.0, 0.5, 0.22])
    linear = np.where(below >= 0.0, vertical, STRAY) * horizontal
    grey = np.round(to_srgb(np.clip(linear, 0.0, 1.0)) * 255.0).astype(np.uint8)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(np.dstack([grey, grey, grey])).save(OUT)
    print(f"wrote {OUT} ({SIZE}x{SIZE})")


if __name__ == "__main__":
    main()
