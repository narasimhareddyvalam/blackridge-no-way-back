"""Measures what each interface-sweep setting changes on screen.

For each light_fog uniform, compares the min and max captures with the default capture
(capture/sweep_<uniform>_<min|default|max>.png, 3840x2400, time frozen, wipers parked) and
reports the share of pixels whose largest RGB channel difference exceeds 6 levels.
Writes capture/sweep_diff.txt. Run with the toolkit venv (numpy, Pillow):
  ~/Desktop/brutalist.art/.venv/bin/python3 build/sweep_diff.py
"""
from pathlib import Path

import numpy as np
from PIL import Image

REEL = Path(__file__).resolve().parents[1]
NAMES = ["fog_amount", "fog_opacity", "clear_center", "edge_softness", "normal_strength", "texture_scale", "fog_tint"]
THRESHOLD = 6


def load(name):
    return np.asarray(Image.open(REEL / "capture" / f"sweep_{name}.png").convert("RGB")).astype(np.int16)


lines = [f"Interface sweep, light_fog on the windshield. Share of pixels changed by more than {THRESHOLD} levels "
         "(max over RGB) versus the default capture, whole 3840x2400 frame."]
result = {}
for n in NAMES:
    base = load(n + "_default")
    for end in ("min", "max"):
        diff = np.abs(load(f"{n}_{end}") - base).max(axis=2)
        share = float((diff > THRESHOLD).mean() * 100)
        result[(n, end)] = share
        lines.append(f"{n:16s} {end}: {share:5.2f}% changed · largest difference {int(diff.max())} levels")
(REEL / "capture" / "sweep_diff.txt").write_text("\n".join(lines) + "\n")
print("\n".join(lines))
