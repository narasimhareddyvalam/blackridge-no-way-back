"""Pixel checks for takes C and D (lossless PNG stills, 3840x2400).

Usage: python3 -I analyze_fog.py <capture_dir> <c|d>

Masks come from logs/<take>-overlay-masks.json: each fog overlay quad projected with the
cockpit camera (supersets: occluders such as the A-pillar are not removed).
Take C asserts:
  - fog_baseline.png and world_fog_on.png are pixel-identical (nothing moved while paused);
  - material edit (light_fog fog_amount 0.25 -> 1.0): changed pixels lie inside the windshield
    mask, none inside the driver-window mask or outside both masks;
  - shader edit (shared Shader line replaced): pixels change inside both masks, none outside;
  - inside each clip, the JPEG frames before the edit are byte-identical, and so are the frames
    after it (static scene apart from the edit).
Take D asserts that every sweep still differs from the default only inside the windshield mask,
and that the seven "default" stills are identical to each other and to take C's fog_baseline.png.
Writes logs/analysis_<take>.json and difference maps logs/diff_*.png (1280 wide).
"""

import hashlib
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw


def load(path):
    return np.asarray(Image.open(path).convert("RGB")).astype(np.int16)


def masks(capture, take):
    with open(os.path.join(capture, "logs", "%s-overlay-masks.json" % take)) as handle:
        data = json.load(handle)
    width, height = data["pixel_space"]
    out = {}
    for name, points in data["polygons"].items():
        image = Image.new("L", (width, height), 0)
        ImageDraw.Draw(image).polygon([tuple(point) for point in points], fill=255)
        out[name] = np.asarray(image) > 0
    return out


def changed(a, b):
    return np.abs(a - b).max(axis=2) > 0


def regions(change, mask):
    light = mask["light_fog_windshield"]
    heavy = mask["heavy_fog_driver_window"]
    return {
        "changed_total": int(change.sum()),
        "inside_windshield_mask": int((change & light).sum()),
        "inside_driver_window_mask": int((change & heavy & ~light).sum()),
        "outside_both_masks": int((change & ~light & ~heavy).sum()),
    }


def save_map(change, path):
    image = Image.fromarray((change * 255).astype(np.uint8))
    image.resize((1280, round(1280 * change.shape[0] / change.shape[1]))).save(path)


def md5(path):
    with open(path, "rb") as handle:
        return hashlib.md5(handle.read()).hexdigest()


def clip_static(capture, clip, edit_at, count):
    folder = os.path.join(capture, "raw", "frames_" + clip)
    if not os.path.isdir(folder):
        return None
    hashes = [md5(os.path.join(folder, "%s_%05d.jpg" % (clip, index))) for index in range(count)]
    return {"frames": count, "distinct_before_edit": len(set(hashes[:edit_at])),
            "distinct_after_edit": len(set(hashes[edit_at:])),
            "before_equals_after": hashes[0] == hashes[-1]}


def take_c(capture, failures):
    take = "take_c_one_shader_two_materials"
    mask = masks(capture, take)
    report = {"masks_px": {name: int(value.sum()) for name, value in mask.items()}}
    baseline = load(os.path.join(capture, "fog_baseline.png"))
    fog_on = load(os.path.join(capture, "world_fog_on.png"))
    fog_off = load(os.path.join(capture, "world_fog_off.png"))
    report["baseline_vs_world_fog_on_changed_px"] = int(changed(baseline, fog_on).sum())
    report["baseline_vs_world_fog_off_changed_px"] = int(changed(baseline, fog_off).sum())
    if report["baseline_vs_world_fog_on_changed_px"] != 0:
        failures.append("fog_baseline.png and world_fog_on.png differ")
    if report["baseline_vs_world_fog_off_changed_px"] == 0:
        failures.append("world fog off made no difference")
    before = load(os.path.join(capture, "material_edit_before.png"))
    after = load(os.path.join(capture, "material_edit_after.png"))
    material = changed(before, after)
    report["material_edit"] = regions(material, mask)
    report["material_edit"]["before_equals_baseline_px"] = int(changed(before, baseline).sum())
    save_map(material, os.path.join(capture, "logs", "diff_material_edit.png"))
    m = report["material_edit"]
    if m["inside_windshield_mask"] == 0 or m["inside_driver_window_mask"] or m["outside_both_masks"]:
        failures.append("material edit changed pixels outside the windshield: %s" % m)
    before = load(os.path.join(capture, "shader_edit_before.png"))
    after = load(os.path.join(capture, "shader_edit_after.png"))
    shader = changed(before, after)
    report["shader_edit"] = regions(shader, mask)
    report["shader_edit"]["before_equals_baseline_px"] = int(changed(before, baseline).sum())
    save_map(shader, os.path.join(capture, "logs", "diff_shader_edit.png"))
    s = report["shader_edit"]
    if s["inside_windshield_mask"] == 0 or s["inside_driver_window_mask"] == 0 \
            or s["outside_both_masks"]:
        failures.append("shader edit did not change both overlays only: %s" % s)
    mean_after = after[shader].mean(axis=0) if shader.any() else None
    report["shader_edit"]["mean_rgb_of_changed_px_after"] = \
        [round(float(v), 1) for v in mean_after] if mean_after is not None else None
    for clip in ["material_edit", "shader_edit"]:
        static = clip_static(capture, clip, 120, 420)
        report[clip + "_jpeg_frames"] = static
        if static and (static["distinct_before_edit"] != 1 or static["distinct_after_edit"] != 1):
            failures.append("%s frames are not static apart from the edit: %s" % (clip, static))
    return report


def take_d(capture, failures):
    take = "take_d_interface_sweep"
    mask = masks(capture, take)
    names = ["fog_amount", "fog_opacity", "clear_center", "edge_softness", "normal_strength",
             "texture_scale", "fog_tint"]
    defaults = [load(os.path.join(capture, "sweep_%s_default.png" % name)) for name in names]
    report = {"defaults_identical": all(not changed(defaults[0], d).any() for d in defaults)}
    if not report["defaults_identical"]:
        failures.append("the seven default sweep stills differ")
    baseline_path = os.path.join(capture, "fog_baseline.png")
    if os.path.exists(baseline_path):
        report["default_vs_take_c_baseline_changed_px"] = int(
            changed(defaults[0], load(baseline_path)).sum())
    for name in names:
        for label in ["min", "max"]:
            still = load(os.path.join(capture, "sweep_%s_%s.png" % (name, label)))
            change = changed(defaults[0], still)
            entry = regions(change, mask)
            report["%s_%s" % (name, label)] = entry
            if entry["inside_driver_window_mask"] or entry["outside_both_masks"]:
                failures.append("%s %s changed pixels outside the windshield: %s" % (
                    name, label, entry))
            save_map(change, os.path.join(capture, "logs", "diff_sweep_%s_%s.png" % (name, label)))
    return report


def main():
    capture, which = sys.argv[1], sys.argv[2]
    failures = []
    report = take_c(capture, failures) if which == "c" else take_d(capture, failures)
    report["failures"] = failures
    name = "analysis_take_%s.json" % which
    with open(os.path.join(capture, "logs", name), "w") as handle:
        json.dump(report, handle, indent=2)
    print(json.dumps(report, indent=2))
    if failures:
        print("ANALYSIS FAIL")
        sys.exit(1)
    print("ANALYSIS PASS")


if __name__ == "__main__":
    main()
