"""Fits the one place of the M16 in Ethan's right hand (Assignment 7, #397) that best meets, over
the rifle clips' key frames (tools/art/dump_rifle_targets.gd), the points a right-handed rifle hold
puts on the rifle: its pistol grip in his right palm, its handguard in his left palm (or its
charging handle, at frame 58 of the reload, where he pulls it), and its butt in his right shoulder's
pocket when he aims. Least squares over the six numbers of a rigid placement (scipy). Prints each
frame's misses in centimetres and IN_HANDS, the rifle's transform in his hand bone's space.
Usage: python3 tools/art/solve_rifle_grip.py targets.json
"""

import json
import sys

import numpy as np
from scipy.optimize import least_squares
from scipy.spatial.transform import Rotation

## Points on the rifle, in m16.glb's own space (Godot: the muzzle -z, its top +y), from its parts:
## the pistol grip's upper middle where the palm closes, the handguard's underside a hand ahead of
## the magazine well, the charging handle's T at the receiver's rear top, and the butt plate.
GRIP = np.array([0.0, -0.095, 0.085])
GUARD = np.array([0.0, -0.06, -0.24])
CHARGE = np.array([0.0, 0.03, 0.09])
BUTT = np.array([0.0, -0.04, 0.44])
WEIGHT = {"grip": 3.0, "guard": 1.0, "charge": 1.5, "butt": 1.5}


def load(path):
    frames = json.load(open(path))
    for f in frames:
        basis = np.array(f["hand"][:3]).T
        scale = np.linalg.norm(basis[:, 0])
        f["R"] = basis / scale
        f["o"] = np.array(f["hand"][3])
        f["scale"] = scale
        for key in ("right_palm", "left_palm", "pocket"):
            f[key] = np.array(f[key])
    return frames


def placed(params, f, point):
    rotation = Rotation.from_rotvec(params[:3]).as_matrix()
    return f["R"] @ (rotation @ point + params[3:]) + f["o"]


def residuals(params, frames):
    out = []
    for f in frames:
        out.extend(WEIGHT["grip"] * (placed(params, f, GRIP) - f["right_palm"]))
        if f["left_holds"] == "guard":
            out.extend(WEIGHT["guard"] * (placed(params, f, GUARD) - f["left_palm"]))
        elif f["left_holds"] == "charge":
            out.extend(WEIGHT["charge"] * (placed(params, f, CHARGE) - f["left_palm"]))
        if f["butt"]:
            out.extend(WEIGHT["butt"] * (placed(params, f, BUTT) - f["pocket"]))
    return np.array(out)


def main():
    frames = load(sys.argv[1])
    best = None
    for seed in range(24):
        start = np.concatenate([Rotation.random(random_state=seed).as_rotvec(), np.zeros(3)])
        fit = least_squares(residuals, start, args=(frames,))
        if best is None or fit.cost < best.cost:
            best = fit
    p = best.x
    print(f"SOLVE: cost {best.cost:.5f}")
    for f in frames:
        grip = np.linalg.norm(placed(p, f, GRIP) - f["right_palm"]) * 100
        left = {"guard": GUARD, "charge": CHARGE}.get(f["left_holds"])
        lmiss = np.linalg.norm(placed(p, f, left) - f["left_palm"]) * 100 if left is not None else 0
        butt = np.linalg.norm(placed(p, f, BUTT) - f["pocket"]) * 100 if f["butt"] else 0
        print(f"SOLVE: {f['clip']:>18} {f['frame']:>3}: grip {grip:4.1f} cm, left hand on the "
              f"{f['left_holds'] or '-':6} {lmiss:4.1f} cm, butt {butt:4.1f} cm")
    rotation = Rotation.from_rotvec(p[:3]).as_matrix()
    scale = frames[0]["scale"]
    local = rotation / scale
    origin = p[3:] / scale
    cols = [local[:, i] for i in range(3)]
    fmt = lambda v: "Vector3(%.6g, %.6g, %.6g)" % tuple(v)
    print(f"SOLVE: const IN_HANDS := Transform3D({fmt(cols[0])}, {fmt(cols[1])}, "
          f"{fmt(cols[2])}, {fmt(origin)})")


if __name__ == "__main__":
    main()
