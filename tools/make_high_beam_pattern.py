"""Generate the headlight high-beam pattern used as a SpotLight3D light projector (#282).

A high beam keeps the low beam lit and adds the high-beam lamp's long-reaching hot spot. The
high-beam lamp is UMTRI-2001-19's measured US high beam (Schoettle, Sivak and Flannagan,
"High-Beam and Low-Beam Headlighting Patterns in the U.S. and Europe at the Turn of the
Millennium", University of Michigan Transportation Research Institute, 2001): the median
luminous intensity, in candelas, of the high beams of the 20 best-selling US passenger vehicles
of model year 2000, its Table 6's middle rows, kept in
tools/data/umtri_2001_19_us_high_beam_medians.csv. Its brightest point is 39,590 cd at H 1R.
The low beam is tools/make_low_beam_pattern.py's measured one.

The spotlight is aimed level on high beams, as the high beams were measured (HIGH_TILT), and
the low beam's lamp is 1.25 degrees lower (LOW_TILT, its cutoff 1.75% down as UN Regulation 48
allows these lamps), so the low beam is drawn 1.25 degrees down from its own pattern. The two are added in candelas, interpolated as the low beam's
(tools/make_low_beam_pattern.py), and the sum normalised to its brightest point, at the measured points or between them; the game's
high-beam energy is the low beam's times that point over the low beam's brightest.

Usage, from the repository root:
    python3 -I tools/make_high_beam_pattern.py
"""

import importlib.util
import pathlib

import numpy as np

LOW_SCRIPT = pathlib.Path("tools/make_low_beam_pattern.py")
DATA = pathlib.Path("tools/data/umtri_2001_19_us_high_beam_medians.csv")
OUT = pathlib.Path("game/features/vehicles/freight_van/art/high_beam_pattern.png")
HIGH_TILT = 0.0
LOW_TILT = -1.25


def low_beam():
    spec = importlib.util.spec_from_file_location("make_low_beam_pattern", LOW_SCRIPT)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main() -> None:
    low = low_beam()
    side, up = low.grid()
    light = low.candelas(DATA, side, up) + low.candelas(low.DATA, side,
                                                         up + HIGH_TILT - LOW_TILT)
    sides, ups, _ = low.measured(DATA)
    at_points = low.candelas(DATA, sides, ups) + low.candelas(low.DATA, sides,
                                                              ups + HIGH_TILT - LOW_TILT)
    peak = max(light.max(), at_points.max())
    low_peak = 10 ** low.measured(low.DATA)[2].max()
    low.save(light / peak, OUT)
    print(f"wrote {OUT}, brightest {peak:.0f} cd, {peak / low_peak:.4f} times the low beam's")


if __name__ == "__main__":
    main()
