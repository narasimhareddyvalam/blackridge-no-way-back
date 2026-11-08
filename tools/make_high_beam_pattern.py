"""Generate the headlight high-beam pattern used as a SpotLight3D light projector.

A high beam keeps the low beam lit and adds a long-reaching hot spot on the horizon, with
no cutoff. The image covers the spotlight's whole cone with the top row pointing up, like
the low-beam pattern, and the lamp is aimed 2 degrees down, so the horizon sits 2 degrees
above the image's centre. Values are written sRGB-encoded because Godot samples light
projectors as sRGB.

Usage, from the repository root:
    python3 -I tools/make_high_beam_pattern.py
"""

import math
import pathlib

import numpy as np
from PIL import Image

LOW = pathlib.Path("game/features/vehicles/freight_van/art/low_beam_pattern.png")
OUT = pathlib.Path("game/features/vehicles/freight_van/art/high_beam_pattern.png")
SIZE = 256
HALF_ANGLE = 35.0
HORIZON = 2.0
CORE = (7.5, 3.2)
SPREAD = (21.0, 7.0, 0.32)


def to_linear(srgb: np.ndarray) -> np.ndarray:
    return np.where(srgb <= 0.04045, srgb / 12.92, np.power((srgb + 0.055) / 1.055, 2.4))


def to_srgb(linear: np.ndarray) -> np.ndarray:
    return np.where(linear <= 0.0031308, 12.92 * linear,
                    1.055 * np.power(linear, 1.0 / 2.4) - 0.055)


def main() -> None:
    tan_half = math.tan(math.radians(HALF_ANGLE))
    centres = (np.arange(SIZE) + 0.5) / (SIZE / 2.0) - 1.0
    side = np.degrees(np.arctan(centres[None, :] * tan_half))
    up = np.degrees(np.arctan(-centres[:, None] * tan_half)) - HORIZON
    low = to_linear(np.asarray(Image.open(LOW).convert("L"), dtype=np.float64) / 255.0)
    core = np.exp(-(side / CORE[0]) ** 2 - (up / CORE[1]) ** 2)
    spread = SPREAD[2] * np.exp(-(side / SPREAD[0]) ** 2 - ((up + 1.0) / SPREAD[1]) ** 2)
    linear = np.clip(low + core + spread, 0.0, 1.0)
    grey = np.round(to_srgb(linear) * 255.0).astype(np.uint8)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(np.dstack([grey, grey, grey])).save(OUT)
    above = linear[: SIZE // 2 - 8, :].mean()
    print(f"wrote {OUT} ({SIZE}x{SIZE}); mean light above the low-beam cutoff {above:.3f}")


if __name__ == "__main__":
    main()
