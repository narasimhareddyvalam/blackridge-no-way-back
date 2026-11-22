"""Build the transfer shed's safety and work kit for part F of step 5 of #253 (docs/PHASE_BRIEF.md)
for Godot, at its makers' sizes, as `shed_kit.glb`, with `build_shed_fitout.py`'s parts maker:

- `Extinguisher`: a 10 lb ABC extinguisher, its red cylinder 5 in (0.13 m) across and 0.5 m tall
  with its valve, handle and hose, on its wall hanger behind it (+z); origin its middle, its front
  toward -z.
- `ExitSign`: a lit exit sign's housing 0.33 x 0.2 x 0.06 m (its faces are drawn by the game);
  `EmergencyLight`: a battery emergency light, 0.3 m across with its two lamp heads; each origin
  its back, toward -z.
- `Mirror`: a convex safety mirror 24 in (0.61 m) across on its bracket, bulging toward +z, origin
  its middle.
- `FirstAidCabinet`: an ANSI Z308.1 class B cabinet 0.4 x 0.45 x 0.15 m; `Charger`: an industrial
  battery charger 0.6 x 0.9 x 0.4 m with its cable and plug; `Eyewash`: a plumbed eyewash, its
  bowl 0.3 m across on its bracket with its push flag; each origin its back, toward -z.
- `SpillKit`: a wheeled spill kit bin 0.6 x 0.9 x 0.6 m; `Baler`: a vertical cardboard baler 1.5 x
  1.85 x 0.9 m, its chamber door and its control box; `Bale`: a baled cube of cardboard 1.2 x 0.75
  x 0.75 m with its five straps; `Bin`: a 32 gal grey bin 0.56 m across; `HandTruck`: a two-wheel
  hand truck 1.2 m tall standing on its wheels and nose; `WrapStand`: a hand stretch-wrap stand,
  its roll of film on its post; each origin on the floor under its middle.
- `ExitDoor`: a steel exit door leaf 0.92 x 2.1 x 0.045 m with its push bar inside (-z), origin
  the middle of its bottom edge.

Usage, from the repository root:
    /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup \\
        --python-exit-code 1 --python tools/art/build_shed_kit.py
"""

import pathlib
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from build_shed_fitout import Part, g, material  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "game/features/environments/industrial_loop/art/fitout/shed_kit.glb"
PAINT = {"red": ((0.75, 0.06, 0.05), 0.2, 0.35), "black": ((0.06, 0.06, 0.06), 0.2, 0.6),
         "steel": ((0.62, 0.63, 0.64), 0.85, 0.35), "white": ((0.9, 0.9, 0.88), 0.0, 0.5),
         "grey": ((0.45, 0.46, 0.46), 0.3, 0.5), "mirror": ((0.95, 0.95, 0.95), 1.0, 0.04),
         "yellow": ((0.9, 0.72, 0.1), 0.1, 0.55), "green": ((0.12, 0.5, 0.25), 0.1, 0.5),
         "board": ((0.55, 0.42, 0.28), 0.0, 0.9), "strap": ((0.12, 0.12, 0.12), 0.0, 0.6),
         "film": ((0.82, 0.86, 0.88), 0.0, 0.25), "door": ((0.32, 0.36, 0.38), 0.4, 0.45),
         "rubber": ((0.04, 0.04, 0.04), 0.0, 0.85), "blue": ((0.2, 0.3, 0.55), 0.2, 0.5)}


def extinguisher(mats):
    part = Part("Extinguisher", mats, ["red", "black", "steel"])
    part.tube((0.0, -0.02, 0.0), 0.065, 0.46, "y", "red", 20)
    part.tube((0.0, 0.225, 0.0), 0.02, 0.05, "y", "steel")
    part.box((-0.015, 0.24, -0.08), (0.015, 0.26, 0.03), "black")
    part.box((-0.012, 0.215, -0.09), (0.012, 0.228, 0.02), "black")
    part.tube((0.03, 0.05, -0.07), 0.008, 0.36, "y", "black", 8)
    part.box((-0.05, -0.05, 0.065), (0.05, 0.2, 0.075), "steel")
    return part.finish()


def wall_boxes(mats):
    found = []
    sign = Part("ExitSign", mats, ["white", "grey"])
    sign.box((-0.165, -0.1, -0.06), (0.165, 0.1, 0.0), "white")
    sign.box((-0.02, 0.1, -0.04), (0.02, 0.18, 0.0), "grey")
    found.append(sign.finish())
    light = Part("EmergencyLight", mats, ["white", "black"])
    light.box((-0.15, -0.06, -0.08), (0.15, 0.06, 0.0), "white")
    for side in (-1.0, 1.0):
        light.tube((side * 0.1, 0.09, -0.07), 0.045, 0.06, "z", "white", 16)
        light.tube((side * 0.1, 0.09, -0.1), 0.035, 0.005, "z", "black", 16)
    found.append(light.finish())
    aid = Part("FirstAidCabinet", mats, ["white", "green"])
    aid.box((-0.2, -0.225, -0.15), (0.2, 0.225, 0.0), "white")
    aid.box((-0.19, 0.17, -0.152), (0.19, 0.2, -0.15), "green")
    found.append(aid.finish())
    charger = Part("Charger", mats, ["blue", "black", "grey"])
    charger.box((-0.3, -0.45, -0.4), (0.3, 0.45, 0.0), "blue")
    for row in range(6):
        y = -0.35 + row * 0.04
        charger.box((-0.22, y, -0.402), (0.22, y + 0.02, -0.4), "black")
    charger.box((-0.12, 0.2, -0.402), (0.12, 0.32, -0.4), "grey")
    charger.tube((0.22, -0.7, -0.3), 0.015, 0.5, "y", "black", 8)
    charger.box((0.17, -1.0, -0.36), (0.27, -0.92, -0.24), "grey")
    found.append(charger.finish())
    wash = Part("Eyewash", mats, ["yellow", "green", "steel"])
    wash.tube((0.0, 0.0, -0.2), 0.15, 0.08, "y", "yellow", 24)
    wash.tube((0.0, -0.35, -0.2), 0.02, 0.62, "y", "steel", 12)
    wash.box((-0.03, -0.1, -0.21), (0.03, 0.0, 0.0), "steel")
    wash.box((0.14, -0.05, -0.32), (0.2, 0.05, -0.3), "green")
    for side in (-1.0, 1.0):
        wash.tube((side * 0.05, 0.06, -0.2), 0.012, 0.05, "y", "green", 8)
    found.append(wash.finish())
    return found


def mirror(mats):
    part = Part("Mirror", mats, ["mirror", "black", "steel"])
    made = bmesh.ops.create_uvsphere(part.bm, u_segments=24, v_segments=12, radius=0.305)
    verts = made["verts"]
    bmesh.ops.scale(part.bm, vec=Vector((1.0, 0.28, 1.0)), verts=verts)
    part._mark(verts, "mirror")
    part.tube((0.0, 0.0, -0.02), 0.31, 0.03, "z", "black", 24)
    part.box((-0.02, -0.02, -0.3), (0.02, 0.02, -0.03), "steel")
    part.box((-0.08, -0.08, -0.32), (0.08, 0.08, -0.3), "steel")
    return part.finish()


def floor_kit(mats):
    found = []
    spill = Part("SpillKit", mats, ["yellow", "black"])
    spill.box((-0.3, 0.06, -0.3), (0.3, 0.9, 0.3), "yellow")
    spill.box((-0.31, 0.88, -0.31), (0.31, 0.93, 0.31), "black")
    for side in (-1.0, 1.0):
        spill.tube((side * 0.22, 0.06, 0.25), 0.06, 0.04, "x", "black", 12)
    found.append(spill.finish())
    baler = Part("Baler", mats, ["grey", "black", "yellow", "red"])
    baler.box((-0.45, 0.0, -0.75), (0.45, 1.85, 0.75), "grey")
    baler.box((-0.46, 0.15, -0.6), (-0.45, 1.1, 0.6), "black")
    baler.box((-0.47, 1.2, -0.6), (-0.45, 1.7, 0.6), "yellow")
    baler.box((-0.5, 1.3, 0.62), (-0.45, 1.6, 0.74), "grey")
    baler.tube((-0.51, 1.5, 0.68), 0.015, 0.01, "x", "red", 10)
    found.append(baler.finish())
    bale = Part("Bale", mats, ["board", "strap"])
    bale.box((-0.6, 0.0, -0.375), (0.6, 0.75, 0.375), "board")
    for index in range(5):
        x = -0.48 + index * 0.24
        bale.box((x - 0.012, -0.003, -0.378), (x + 0.012, 0.753, 0.378), "strap")
    found.append(bale.finish())
    bin_part = Part("Bin", mats, ["grey", "black"])
    bin_part.tube((0.0, 0.4, 0.0), 0.28, 0.8, "y", "grey", 24)
    bin_part.tube((0.0, 0.81, 0.0), 0.295, 0.03, "y", "black", 24)
    found.append(bin_part.finish())
    truck = Part("HandTruck", mats, ["red", "rubber", "steel"])
    for side in (-1.0, 1.0):
        truck.box((side * 0.2 - 0.015, 0.1, -0.02), (side * 0.2 + 0.015, 1.2, 0.02), "red")
        truck.tube((side * 0.24, 0.125, 0.12), 0.125, 0.07, "x", "rubber", 16)
    truck.box((-0.22, 1.15, -0.02), (0.22, 1.18, 0.02), "red")
    truck.box((-0.2, 0.0, -0.22), (0.2, 0.012, 0.02), "steel")
    found.append(truck.finish())
    stand = Part("WrapStand", mats, ["steel", "film", "black"])
    stand.box((-0.25, 0.0, -0.25), (0.25, 0.04, 0.25), "black")
    stand.tube((0.0, 0.6, 0.0), 0.02, 1.1, "y", "steel", 10)
    stand.tube((0.0, 0.95, 0.12), 0.055, 0.5, "y", "film", 20)
    found.append(stand.finish())
    door = Part("ExitDoor", mats, ["door", "steel"])
    door.box((-0.46, 0.0, -0.0225), (0.46, 2.1, 0.0225), "door")
    door.box((-0.4, 0.98, -0.09), (0.4, 1.04, -0.05), "steel")
    for side in (-1.0, 1.0):
        door.box((side * 0.4 - 0.02, 0.97, -0.06), (side * 0.4 + 0.02, 1.05, -0.0225), "steel")
    found.append(door.finish())
    return found


def main():
    for obj in list(bpy.context.scene.objects):
        bpy.data.objects.remove(obj)
    mats = {key: material(key, *PAINT[key]) for key in PAINT}
    parts = [extinguisher(mats)] + wall_boxes(mats) + [mirror(mats)] + floor_kit(mats)
    for obj in list(bpy.context.scene.objects):
        obj.select_set(obj in parts)
    bpy.ops.export_scene.gltf(filepath=str(OUT), export_format="GLB", use_selection=True,
                              use_active_scene=True, export_apply=True, export_yup=True)
    for obj in parts:
        print(f"  {obj.name}: {len(obj.data.polygons)} faces")
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
