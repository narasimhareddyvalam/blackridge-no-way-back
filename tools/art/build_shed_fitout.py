"""Build the transfer shed's fit-out for part E of step 5 of #253 (docs/PHASE_BRIEF.md) for Godot,
at its makers' sizes, as `shed_fitout.glb`:

- `UnitHeater`: a gas-fired propeller unit heater about 30 x 26 x 24 in (0.76 x 0.66 x 0.60 m),
  enamelled casing, its discharge (-z) behind seven horizontal louvers turned 30 degrees down,
  its fan guard behind, its flue collar on top at the back and its gas inlet on its side toward
  the front, clear of the flue; origin
  its middle. `HeaterRod`: 3/8 in threaded rod, 1 m up (+y), scaled to its length. `Strut`: 1 5/8
  in strut channel, 1 m along x, origin its top middle, scaled to its length. `Flue`: a 4 in
  (0.1 m) galvanised vent pipe 1 m up. `GasPipe`: 2 in pipe 1 m along x and `GasDrop`: 1 in pipe
  1 m up, both painted safety yellow; `GasCock`: a shut-off valve with its red lever.
- `FanMotor`: a high-volume low-speed fan's gearbox and motor above its hub, origin the blades'
  plane; `FanBlades`: its hub and eight blades 20 ft (6.1 m) across, each pitched 8 degrees with
  its tip turned up, origin the hub's middle (it turns about y); `FanDownrod`: 1 m up; `FanMount`:
  a 3 m channel along x, origin its top middle.
- `TraySection`: 3 m of 12 in (0.305 m) steel ladder tray along x, 4 in side rails and rungs every
  9 in, origin the middle of its bottom.
- `Conduit`: 3/4 in EMT, 1 m up.
- `DoorOperator`: a door operator's motor and gear reducer on the wall, origin its back (the
  wall), the body toward -z.
- `ControlStation`: a NEMA 4X dock control station 0.25 x 0.40 x 0.14 m with its seven buttons
  where `station_legend.png` labels them, seen from the front (-z), whose right is -x (door open,
  close and a red stop; leveler raise and lip; restraint engage and release), origin its back.
- `TimeClock`: 0.19 x 0.24 x 0.11 m; `CardRack`: a 12-pocket rack 0.15 x 0.60 m; `NoticeBoard`: a
  1.2 x 0.9 m cork board in an aluminium frame; each origin its back, toward -z.

Coordinates are Godot's (x across, y up, z back); g() turns them into Blender's.

Usage, from the repository root:
    /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup \\
        --python-exit-code 1 --python tools/art/build_shed_fitout.py
"""

import math
import pathlib

import bmesh
import bpy
from mathutils import Matrix, Vector

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "game/features/environments/industrial_loop/art/fitout/shed_fitout.glb"

INCH = 0.0254
HEATER = (0.76, 0.66, 0.60)
LOUVERS = 7
LOUVER_DOWN = math.radians(30.0)
FAN_RADIUS = 120 * INCH
BLADES = 8
BLADE_PITCH = math.radians(8.0)
TRAY = {"length": 3.0, "wide": 12 * INCH, "rail": 4 * INCH, "rung_step": 9 * INCH}
STATION = (0.25, 0.40, 0.14)
PAINT = {"casing": ((0.55, 0.56, 0.55), 0.3, 0.45), "louver": ((0.33, 0.34, 0.34), 0.4, 0.4),
         "black": ((0.07, 0.07, 0.07), 0.2, 0.6), "steel": ((0.62, 0.63, 0.64), 0.8, 0.4),
         "galvanised": ((0.68, 0.69, 0.68), 0.85, 0.35), "yellow": ((0.86, 0.68, 0.08), 0.1, 0.5),
         "red": ((0.72, 0.08, 0.06), 0.1, 0.45), "green": ((0.1, 0.55, 0.2), 0.1, 0.45),
         "blade": ((0.78, 0.79, 0.8), 0.7, 0.35), "enclosure": ((0.73, 0.74, 0.72), 0.1, 0.5),
         "cork": ((0.62, 0.47, 0.31), 0.0, 0.85), "aluminium": ((0.75, 0.76, 0.77), 0.8, 0.3),
         "motor": ((0.18, 0.22, 0.3), 0.3, 0.5)}


def g(x, y, z):
    return Vector((x, -z, y))


def linear(value):
    return value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4


def material(name, colour, metallic, roughness):
    made = bpy.data.materials.new(name)
    made.use_nodes = True
    shader = next(n for n in made.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    shader.inputs["Base Color"].default_value = tuple(linear(c) for c in colour) + (1.0,)
    shader.inputs["Metallic"].default_value = metallic
    shader.inputs["Roughness"].default_value = roughness
    made.use_backface_culling = True
    return made


class Part:
    """One mesh built from boxes and tubes, each face given its material's slot."""

    def __init__(self, name, mats, keys):
        self.name = name
        self.bm = bmesh.new()
        self.mats = [mats[key] for key in keys]
        self.keys = keys

    def _mark(self, verts, key):
        """Gives every face of these new vertices `key`'s slot, on the face itself."""
        slot = self.keys.index(key)
        for face in {face for vert in verts for face in vert.link_faces}:
            face.material_index = slot

    def box(self, low, high, key, turn=None):
        low, high = Vector(low), Vector(high)
        made = bmesh.ops.create_cube(self.bm, size=1.0)
        size = high - low
        bmesh.ops.scale(self.bm, vec=Vector((size.x, size.z, size.y)), verts=made["verts"])
        if turn is not None:
            bmesh.ops.rotate(self.bm, cent=Vector(), matrix=turn, verts=made["verts"])
        bmesh.ops.translate(self.bm, vec=g(*((low + high) / 2.0)), verts=made["verts"])
        self._mark(made["verts"], key)

    def tube(self, centre, radius, length, axis, key, segments=16):
        made = bmesh.ops.create_cone(self.bm, cap_ends=True, segments=segments, radius1=radius,
                                     radius2=radius, depth=length)
        if axis == "x":
            bmesh.ops.rotate(self.bm, cent=Vector(), matrix=Matrix.Rotation(math.pi / 2, 3, "Y"),
                             verts=made["verts"])
        elif axis == "z":
            bmesh.ops.rotate(self.bm, cent=Vector(), matrix=Matrix.Rotation(math.pi / 2, 3, "X"),
                             verts=made["verts"])
        bmesh.ops.translate(self.bm, vec=g(*centre), verts=made["verts"])
        self._mark(made["verts"], key)

    def finish(self):
        bmesh.ops.recalc_face_normals(self.bm, faces=self.bm.faces[:])
        mesh = bpy.data.meshes.new(self.name)
        self.bm.to_mesh(mesh)
        self.bm.free()
        obj = bpy.data.objects.new(self.name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        for made in self.mats:
            obj.data.materials.append(made)
        return obj


def heater(mats):
    part = Part("UnitHeater", mats, ["casing", "louver", "black", "galvanised", "yellow"])
    w, h, d = HEATER
    part.box((-w / 2, -h / 2, -d / 2 + 0.03), (w / 2, h / 2, d / 2), "casing")
    part.box((-w / 2 + 0.03, -h / 2 + 0.03, -d / 2), (w / 2 - 0.03, h / 2 - 0.03, -d / 2 + 0.03),
             "black")
    step = (h - 0.08) / LOUVERS
    for index in range(LOUVERS):
        y = -h / 2 + 0.04 + step * (index + 0.5)
        turn = Matrix.Rotation(-LOUVER_DOWN, 3, "X")
        part.box((-w / 2 + 0.03, y - 0.004, -0.04), (w / 2 - 0.03, y + 0.004, 0.04), "louver",
                 None)
        verts = list(part.bm.verts)[-8:]
        bmesh.ops.translate(part.bm, vec=-g(0.0, y, 0.0), verts=verts)
        bmesh.ops.rotate(part.bm, cent=Vector(), matrix=turn, verts=verts)
        bmesh.ops.translate(part.bm, vec=g(0.0, y, -d / 2 - 0.01), verts=verts)
    part.tube((0.0, 0.0, d / 2 + 0.01), 0.26, 0.02, "z", "black", 24)
    for angle in (0.0, math.pi / 2):
        spoke = Matrix.Rotation(angle, 3, "Y")
        part.box((-0.26, -0.008, d / 2 + 0.005), (0.26, 0.008, d / 2 + 0.02), "black", spoke)
    part.tube((0.0, h / 2 + 0.04, d / 2 - 0.12), 0.05, 0.08, "y", "galvanised")
    part.tube((w / 2 + 0.03, -0.1, -0.15), 0.017, 0.06, "x", "yellow")
    return part.finish()


def unit_parts(mats):
    found = []
    for name, radius, axis, key in [("HeaterRod", 0.005, "y", "steel"),
                                    ("Flue", 0.05, "y", "galvanised"),
                                    ("GasPipe", 0.03, "x", "yellow"),
                                    ("GasDrop", 0.017, "y", "yellow"),
                                    ("FanDownrod", 0.04, "y", "motor"),
                                    ("Conduit", 0.0115, "y", "galvanised")]:
        part = Part(name, mats, [key])
        centre = (0.5, 0.0, 0.0) if axis == "x" else (0.0, 0.5, 0.0)
        part.tube(centre, radius, 1.0, axis, key, 12 if radius < 0.02 else 16)
        found.append(part.finish())
    strut = Part("Strut", mats, ["galvanised"])
    strut.box((0.0, -0.041, -0.0205), (1.0, 0.0, 0.0205), "galvanised")
    found.append(strut.finish())
    valve = Part("GasCock", mats, ["yellow", "red"])
    valve.box((-0.03, -0.03, -0.025), (0.03, 0.03, 0.025), "yellow")
    valve.box((-0.01, 0.03, -0.01), (0.12, 0.045, 0.01), "red")
    found.append(valve.finish())
    return found


def fan(mats):
    motor = Part("FanMotor", mats, ["motor", "black"])
    motor.tube((0.0, 0.26, 0.0), 0.2, 0.32, "y", "motor", 24)
    motor.box((0.18, 0.16, -0.14), (0.46, 0.4, 0.14), "motor")
    motor.tube((0.0, 0.09, 0.0), 0.08, 0.04, "y", "black")
    blades = Part("FanBlades", mats, ["black", "blade"])
    blades.tube((0.0, 0.04, 0.0), 0.3, 0.08, "y", "black", 32)
    for index in range(BLADES):
        angle = math.tau * index / BLADES
        spin = Matrix.Rotation(angle, 3, "Z")
        pitch = Matrix.Rotation(BLADE_PITCH, 3, "X")
        start = len(blades.bm.verts)
        blades.box((0.28, 0.025, -0.11), (FAN_RADIUS - 0.04, 0.05, 0.11), "blade")
        blades.box((FAN_RADIUS - 0.04, 0.025, -0.11), (FAN_RADIUS, 0.16, 0.11), "blade")
        verts = list(blades.bm.verts)[start:]
        bmesh.ops.rotate(blades.bm, cent=Vector(), matrix=pitch, verts=verts)
        bmesh.ops.rotate(blades.bm, cent=Vector(), matrix=spin, verts=verts)
    mount = Part("FanMount", mats, ["galvanised"])
    mount.box((-1.5, -0.1, -0.1), (1.5, 0.0, -0.09), "galvanised")
    mount.box((-1.5, -0.1, 0.09), (1.5, 0.0, 0.1), "galvanised")
    mount.box((-1.5, -0.1, -0.1), (1.5, -0.09, 0.1), "galvanised")
    return [motor.finish(), blades.finish(), mount.finish()]


def tray(mats):
    part = Part("TraySection", mats, ["galvanised"])
    length, wide, rail = TRAY["length"], TRAY["wide"], TRAY["rail"]
    for side in (-1.0, 1.0):
        z = side * wide / 2
        part.box((0.0 - length / 2, 0.0, z - 0.002), (length / 2, rail, z + 0.002), "galvanised")
        part.box((-length / 2, rail - 0.003, z - side * 0.02 - 0.0), (length / 2, rail,
                 z), "galvanised")
        part.box((-length / 2, 0.0, z - side * 0.02), (length / 2, 0.003, z), "galvanised")
    count = int(length / TRAY["rung_step"])
    for index in range(count):
        x = -length / 2 + TRAY["rung_step"] * (index + 0.5)
        part.box((x - 0.0125, 0.0, -wide / 2), (x + 0.0125, 0.02, wide / 2), "galvanised")
    return part.finish()


def wall_parts(mats):
    found = []
    operator = Part("DoorOperator", mats, ["motor", "black", "steel"])
    operator.box((-0.15, -0.14, -0.22), (0.15, 0.14, 0.0), "motor")
    operator.tube((0.0, -0.2, -0.11), 0.07, 0.16, "x", "black")
    operator.tube((0.12, -0.2, -0.11), 0.06, 0.03, "x", "steel")
    found.append(operator.finish())
    w, h, d = STATION
    station = Part("ControlStation", mats, ["enclosure", "black", "red", "steel"])
    station.box((-w / 2, -h / 2, -d), (w / 2, h / 2, 0.0), "enclosure")
    rows = [(76, [48, 124]), (196, [67, 182]), (316, [67, 182])]
    for py, xs in rows:
        for px in xs:
            station.tube((w / 2 - px / 1000, h / 2 - py / 1000, -d - 0.008), 0.016, 0.016, "z",
                         "black")
    station.tube((w / 2 - 200 / 1000, h / 2 - 76 / 1000, -d - 0.012), 0.022, 0.024, "z", "red")
    station.box((-w / 2 + 0.01, -h / 2 - 0.03, -0.03), (w / 2 - 0.01, -h / 2, 0.0), "steel")
    found.append(station.finish())
    clock = Part("TimeClock", mats, ["black", "steel"])
    clock.box((-0.095, -0.12, -0.11), (0.095, 0.12, 0.0), "black")
    clock.box((-0.06, 0.04, -0.112), (0.06, 0.05, -0.11), "steel")
    found.append(clock.finish())
    rack = Part("CardRack", mats, ["steel"])
    rack.box((-0.075, -0.3, -0.004), (0.075, 0.3, 0.0), "steel")
    for slot in range(12):
        y = 0.3 - 0.008 - slot * 0.049 - 0.032 - 0.012
        rack.box((-0.07, y, -0.03), (0.07, y + 0.012, -0.004), "steel")
    found.append(rack.finish())
    board = Part("NoticeBoard", mats, ["cork", "aluminium"])
    board.box((-0.6, -0.45, -0.012), (0.6, 0.45, 0.0), "cork")
    for low, high in [((-0.625, 0.45, -0.025), (0.625, 0.475, 0.0)),
                      ((-0.625, -0.475, -0.025), (0.625, -0.45, 0.0)),
                      ((-0.625, -0.45, -0.025), (-0.6, 0.45, 0.0)),
                      ((0.6, -0.45, -0.025), (0.625, 0.45, 0.0))]:
        board.box(low, high, "aluminium")
    found.append(board.finish())
    return found


def main():
    for obj in list(bpy.context.scene.objects):
        bpy.data.objects.remove(obj)
    mats = {key: material(key, *PAINT[key]) for key in PAINT}
    parts = [heater(mats)] + unit_parts(mats) + fan(mats) + [tray(mats)] + wall_parts(mats)
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
