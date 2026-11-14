"""Generate the headlight low-beam pattern used as a SpotLight3D light projector (#281).

The pattern is the measured US low beam of UMTRI-2004-23 (Schoettle, Sivak, Flannagan and
Kosmatka, "A Market-Weighted Description of Low-Beam Headlighting Patterns in the U.S.: 2004",
University of Michigan Transportation Research Institute): the median luminous intensity, in
candelas, of the low beams on the 20 best-selling US passenger vehicles of model year 2004,
photometered at 45L-45R and 7U-5D, its Table 4's middle rows, kept in
tools/data/umtri_2004_23_low_beam_medians.csv (first column degrees up, header degrees right).
Its brightest point is 22,740 cd at 1D 1R, just below the cutoff and toward the kerb.

The image covers the spotlight's whole cone, 35 degrees each way, the top row pointing up, in
the aimed lamp's own angles (H the horizon, V straight ahead), normalised to the brightest
point. Between the measured points the intensity is interpolated in log10 across, then up;
below 5D, where the table stops, it falls 0.06 decades a degree; above 7U the 7U row fades 0.05
decades a degree. Values are written sRGB-encoded because Godot samples light projectors as
sRGB.

Usage, from the repository root:
    python3 -I tools/make_low_beam_pattern.py
"""

import csv
import math
import pathlib

import numpy as np
from PIL import Image

DATA = pathlib.Path("tools/data/umtri_2004_23_low_beam_medians.csv")
OUT = pathlib.Path("game/features/vehicles/freight_van/art/low_beam_pattern.png")
SIZE = 256
HALF_ANGLE = 35.0
BELOW_FALL = 0.06
ABOVE_FALL = 0.05


def to_srgb(linear: np.ndarray) -> np.ndarray:
    return np.where(linear <= 0.0031308, 12.92 * linear,
                    1.055 * np.power(linear, 1.0 / 2.4) - 0.055)


def measured(data: pathlib.Path = DATA) -> tuple:
    with data.open(newline="") as handle:
        rows = list(csv.reader(handle))
    sides = np.array([float(value) for value in rows[0][1:]])
    ups = np.array([float(row[0]) for row in rows[1:]])
    logs = np.log10(np.array([[float(value) for value in row[1:]] for row in rows[1:]]))
    order = np.argsort(ups)
    return sides, ups[order], logs[order]


def grid() -> tuple:
    tan_half = math.tan(math.radians(HALF_ANGLE))
    centres = (np.arange(SIZE) + 0.5) / (SIZE / 2.0) - 1.0
    return np.degrees(np.arctan(centres * tan_half)), np.degrees(np.arctan(-centres * tan_half))


def candelas(data: pathlib.Path, side: np.ndarray, up: np.ndarray) -> np.ndarray:
    sides, ups, logs = measured(data)
    across = np.array([np.interp(side, sides, row) for row in logs])
    pattern = np.empty((up.size, side.size))
    for y in range(up.size):
        if up[y] < ups[0]:
            pattern[y] = across[0] - BELOW_FALL * (ups[0] - up[y])
        elif up[y] > ups[-1]:
            pattern[y] = across[-1] - ABOVE_FALL * (up[y] - ups[-1])
        else:
            pattern[y] = [np.interp(up[y], ups, across[:, x]) for x in range(side.size)]
    return np.power(10.0, pattern)


def save(linear: np.ndarray, out: pathlib.Path) -> None:
    grey = np.round(to_srgb(np.clip(linear, 0.0, 1.0)) * 255.0).astype(np.uint8)
    out.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(np.dstack([grey, grey, grey])).save(out)


def main() -> None:
    side, up = grid()
    light = candelas(DATA, side, up)
    peak = 10 ** measured(DATA)[2].max()
    save(light / peak, OUT)
    print(f"wrote {OUT} ({SIZE}x{SIZE}), brightest {peak:.0f} cd")


if __name__ == "__main__":
    main()
