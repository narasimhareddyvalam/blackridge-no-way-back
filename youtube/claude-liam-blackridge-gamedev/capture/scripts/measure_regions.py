"""Share of changed pixels in two fixed screen regions between before/after stills.

Usage: python3 -I measure_regions.py <capture_dir>

Regions (3840x2400 cockpit frames, numpy slices, half-open):
  windshield     x 1300-3840, y 0-1377  -> rows [0:1377],   columns [1300:3840]
  driver window  x 0-1250,    y 350-1500 -> rows [350:1500], columns [0:1250]
A pixel counts as changed when its largest per-channel absolute difference (0-255) exceeds
the threshold; both > 0 and > 6 levels are reported. Pairs: take C's shader edit, take C2's
shader edit (light_fog fog_amount 1.0 before recording), and take C's material edit.
Writes logs/region_change_shares.json.
"""

import json
import os
import sys

import numpy as np
from PIL import Image

REGIONS = {
    "windshield_x1300-3840_y0-1377": (slice(0, 1377), slice(1300, 3840)),
    "driver_window_x0-1250_y350-1500": (slice(350, 1500), slice(0, 1250)),
}
PAIRS = {
    "take_c_shader_edit (light_fog at .tres values)": ("shader_edit_before.png",
                                                       "shader_edit_after.png"),
    "take_c2_shader_edit_visible (light_fog fog_amount 1.0)": ("shader_edit_visible_before.png",
                                                               "shader_edit_visible_after.png"),
    "take_c_material_edit (light_fog fog_amount 0.25 -> 1.0)": ("material_edit_before.png",
                                                                "material_edit_after.png"),
}
THRESHOLDS = [0, 6]


def load(path):
    return np.asarray(Image.open(path).convert("RGB")).astype(np.int16)


def main():
    capture = sys.argv[1]
    report = {"regions": {name: {"rows": [r.start, r.stop], "columns": [c.start, c.stop]}
                          for name, (r, c) in REGIONS.items()}, "pairs": {}}
    for label, (before_name, after_name) in PAIRS.items():
        before = load(os.path.join(capture, before_name))
        after = load(os.path.join(capture, after_name))
        difference = np.abs(before - after).max(axis=2)
        entry = {"before": before_name, "after": after_name}
        for region, (rows, columns) in REGIONS.items():
            block = difference[rows, columns]
            mean_before = before[rows, columns].reshape(-1, 3).mean(axis=0)
            mean_after = after[rows, columns].reshape(-1, 3).mean(axis=0)
            entry[region] = {
                "pixels": int(block.size),
                **{"changed_gt_%d_pct" % t: round(100.0 * float((block > t).mean()), 2)
                   for t in THRESHOLDS},
                "max_level_change": int(block.max()),
                "mean_rgb_before": [round(float(v), 1) for v in mean_before],
                "mean_rgb_after": [round(float(v), 1) for v in mean_after],
            }
        report["pairs"][label] = entry
        print(label)
        for region in REGIONS:
            e = entry[region]
            print("  %-34s >0: %6.2f%%   >6: %6.2f%%   max %3d   mean RGB %s -> %s" % (
                region, e["changed_gt_0_pct"], e["changed_gt_6_pct"], e["max_level_change"],
                e["mean_rgb_before"], e["mean_rgb_after"]))
    with open(os.path.join(capture, "logs", "region_change_shares.json"), "w") as handle:
        json.dump(report, handle, indent=2)


if __name__ == "__main__":
    main()
