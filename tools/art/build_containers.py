"""Build the container yard's ISO containers for Mission 2's step 4 (docs/PHASE_BRIEF.md) for
Godot, at ISO 668's sizes, as `containers.glb`, with `build_shed_fitout.py`'s parts maker:

- `Container20`, `Container40`, `Container40HC`: 20 ft (6.058 m), 40 ft (12.192 m) and 40 ft high
  cube boxes, 2.438 m wide, 2.591 m tall (2.896 m the high cube), their length along local x,
  their door end at +x, origin the middle of the bottom. Each has its corrugated sides (a
  trapezoidal profile, 0.278 m pitch, 0.036 m deep), its corrugated front end and roof, its door
  end with two doors and their four vertical locking bars, cams and handles, its bottom and top
  rails, its cast corner fittings at all eight corners and, on the 20 ft box, its forklift
  pockets. The paint is one material, `Paint`, white, so each box takes its colour from its
  instance; the corner fittings, rails' undersides and door gear are dark steel.

Usage, from the repository root:
    /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup \\
        --python-exit-code 1 --python tools/art/build_containers.py
"""

import pathlib
import sys

import bpy

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from build_shed_fitout import Part, material  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "game/features/environments/industrial_loop/art/container_yard/containers.glb"
WIDE = 2.438
TALL = 2.591
HIGH_CUBE = 2.896
LENGTHS = {"Container20": 6.058, "Container40": 12.192, "Container40HC": 12.192}
PITCH = 0.278
DEEP = 0.036
CORNER = (0.178, 0.118, 0.162)
RAIL = 0.15
PAINT = {"paint": ((1.0, 1.0, 1.0), 0.15, 0.62), "steel": ((0.12, 0.12, 0.12), 0.6, 0.55),
         "gear": ((0.35, 0.36, 0.36), 0.8, 0.45)}


def container(mats, name, length):
    tall = HIGH_CUBE if name.endswith("HC") else TALL
    part = Part(name, mats, ["paint", "steel", "gear"])
    half_l, half_w = length / 2.0, WIDE / 2.0
    part.box((-half_l + 0.02, RAIL, -half_w + DEEP), (half_l - 0.02, tall - RAIL, half_w - DEEP),
             "paint")
    ribs = int((length - 0.4) / PITCH)
    for index in range(ribs):
        x = -half_l + 0.2 + (index + 0.5) * PITCH
        for side in (-1.0, 1.0):
            low = side * half_w - (DEEP if side > 0 else 0.0)
            part.box((x - PITCH * 0.25, RAIL, min(low, low + DEEP)),
                     (x + PITCH * 0.25, tall - RAIL, max(low, low + DEEP)), "paint")
    for index in range(int((WIDE - 0.3) / PITCH)):
        z = -half_w + 0.15 + (index + 0.5) * PITCH
        part.box((-half_l, RAIL, z - PITCH * 0.25), (-half_l + 0.02 + DEEP, tall - RAIL,
                 z + PITCH * 0.25), "paint")
    for index in range(int((length - 0.4) / 0.5)):
        x = -half_l + 0.2 + (index + 0.5) * 0.5
        part.box((x - 0.1, tall - RAIL, -half_w + 0.05), (x + 0.1, tall - RAIL + 0.015,
                 half_w - 0.05), "paint")
    for y in (0.0, tall - RAIL):
        for side in (-1.0, 1.0):
            part.box((-half_l, y, side * half_w - 0.06), (half_l, y + RAIL, side * half_w + 0.0),
                     "paint")
    part.box((-half_l, 0.0, -half_w), (half_l, 0.04, half_w), "steel")
    door = half_l - 0.01
    part.box((door, RAIL, -half_w + 0.05), (door + 0.03, tall - RAIL, half_w - 0.05), "paint")
    part.box((door + 0.03, RAIL, -0.005), (door + 0.035, tall - RAIL, 0.005), "steel")
    for z in (-0.95, -0.35, 0.35, 0.95):
        part.box((door + 0.04, RAIL - 0.05, z - 0.015), (door + 0.07, tall - RAIL + 0.05,
                 z + 0.015), "gear")
        part.box((door + 0.035, tall * 0.42, z - 0.04), (door + 0.08, tall * 0.42 + 0.06,
                 z + 0.12), "gear")
        for y in (RAIL - 0.08, tall - RAIL + 0.02):
            part.box((door + 0.03, y, z - 0.05), (door + 0.09, y + 0.06, z + 0.05), "gear")
    for x in (-half_l, half_l - CORNER[0]):
        for y in (0.0, tall - CORNER[1]):
            for z in (-half_w, half_w - CORNER[2]):
                part.box((x, y, z), (x + CORNER[0], y + CORNER[1], z + CORNER[2]), "steel")
    if length < 7.0:
        for x in (-1.025, 1.025):
            for side in (-1.0, 1.0):
                part.box((x - 0.18, 0.02, side * half_w - 0.01), (x + 0.18, 0.13,
                         side * half_w + 0.005), "steel")
    return part.finish()


def main():
    for obj in list(bpy.context.scene.objects):
        bpy.data.objects.remove(obj)
    mats = {key: material(key, *PAINT[key]) for key in PAINT}
    parts = [container(mats, name, length) for name, length in LENGTHS.items()]
    for obj in list(bpy.context.scene.objects):
        obj.select_set(obj in parts)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(OUT), export_format="GLB", use_selection=True,
                              use_active_scene=True, export_apply=True, export_yup=True)
    for obj in parts:
        print(f"  {obj.name}: {len(obj.data.polygons)} faces")
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
