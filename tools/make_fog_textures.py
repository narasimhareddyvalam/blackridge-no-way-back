"""Write the three foggy-windshield textures for Assignment 5.

Run from the repository root: python3 tools/make_fog_textures.py
Outputs 1024 x 1024 PNGs in game/assets/textures/windshield/:
fog_color.png (sRGB colour), fog_data.png (fog thickness in red)
and fog_normal.png (OpenGL convention, green up, from a droplet height field).
All three tile seamlessly, and the fixed seed makes the output repeatable.
"""

from pathlib import Path

import numpy as np
from PIL import Image

SIZE = 1024
SEED = 20261029
OUTPUT = Path("game/assets/textures/windshield")


def periodic_noise(rng: np.random.Generator, wavelength: float) -> np.ndarray:
    white = rng.standard_normal((SIZE, SIZE))
    frequency = np.fft.fftfreq(SIZE)
    radius = np.hypot(*np.meshgrid(frequency, frequency))
    falloff = np.exp(-(radius * wavelength) ** 2)
    smooth = np.real(np.fft.ifft2(np.fft.fft2(white) * falloff))
    return (smooth - smooth.min()) / (smooth.max() - smooth.min())


def fractal_noise(rng: np.random.Generator, wavelengths: list[float]) -> np.ndarray:
    total = np.zeros((SIZE, SIZE))
    weight = 1.0
    for wavelength in wavelengths:
        total += periodic_noise(rng, wavelength) * weight
        weight *= 0.5
    return (total - total.min()) / (total.max() - total.min())


def droplet_heights(rng: np.random.Generator, count: int) -> np.ndarray:
    heights = np.zeros((SIZE, SIZE))
    rows, columns = np.mgrid[-12:13, -12:13]
    for _ in range(count):
        radius = rng.uniform(2.0, 9.0)
        centre = rng.integers(0, SIZE, size=2)
        distance = np.hypot(rows, columns) / radius
        dome = radius * 0.5 * np.exp(-3.0 * distance**2)
        patch_rows = (rows + centre[0]) % SIZE
        patch_columns = (columns + centre[1]) % SIZE
        heights[patch_rows, patch_columns] = np.maximum(
            heights[patch_rows, patch_columns], dome)
    return heights


def normal_map(heights: np.ndarray, strength: float) -> np.ndarray:
    dh_du = (np.roll(heights, -1, axis=1) - np.roll(heights, 1, axis=1)) * 0.5
    dh_dv = (np.roll(heights, -1, axis=0) - np.roll(heights, 1, axis=0)) * 0.5
    normal = np.stack([-dh_du * strength, dh_dv * strength, np.ones_like(heights)], axis=-1)
    normal /= np.linalg.norm(normal, axis=-1, keepdims=True)
    return np.round((normal * 0.5 + 0.5) * 255.0).astype(np.uint8)


def save(pixels: np.ndarray, name: str) -> None:
    Image.fromarray(pixels).save(OUTPUT / name)
    print(f"wrote {OUTPUT / name} {pixels.shape[1]}x{pixels.shape[0]}")


def main() -> None:
    rng = np.random.default_rng(SEED)
    OUTPUT.mkdir(parents=True, exist_ok=True)
    patches = fractal_noise(rng, [160.0, 60.0, 18.0])
    streaks = periodic_noise(rng, 40.0)[:, :1].repeat(SIZE, axis=1).T
    thickness = np.clip((patches - 0.25) * 1.6, 0.0, 1.0) * (0.85 + 0.15 * streaks)
    grey = np.round(np.clip(thickness, 0.0, 1.0) * 255.0).astype(np.uint8)
    save(np.stack([grey, grey, grey], axis=-1), "fog_data.png")
    tint = fractal_noise(rng, [220.0, 70.0])
    base = np.array([222.0, 228.0, 233.0])
    shift = np.array([5.0, 3.0, -2.0])
    colour = base + (tint[..., None] - 0.5) * 2.0 * shift
    save(np.round(np.clip(colour, 0.0, 255.0)).astype(np.uint8), "fog_color.png")
    save(normal_map(droplet_heights(rng, 2600), 0.45), "fog_normal.png")


if __name__ == "__main__":
    main()
