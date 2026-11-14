"""Build the transfer shed's roof structure, services and aisle lights (#267) for Godot, as the
author's photo of a warehouse shows them under its deck, at real sizes:

- `RoofJoist`: a long-span open-web steel joist across the shed's 29.5 m clear span between its
  side walls, white painted as the photo's, its top chord under the deck's liner along the
  roof's 5 degree pitch either side of the ridge, 1.2 m deep (about a twenty-fourth of its span,
  as long-span joists run), double-angle chords 5 x 2.5 in and web bars zig-zagging between them
  on 1.2 m panels, an end post and a bearing seat at each wall. Its origin: the ridge's line at
  the eaves' height (z = 0 is the ridge, y = 0 the eaves).
- `DuctRun`: 3.0 m of white spiral duct 0.6 m across, along local x, its lock seam wound round it
  (`duct_seam.png`), a joint band at its end; `DuctHanger`: a pair of 30 mm straps from its top,
  1 m tall, scaled to each hanger's length.
- `SprinklerMain`: 3.05 m (10 ft) of 4 in (114 mm) red steel pipe along local x with a grooved
  coupling at its end; `SprinklerHead`: a pendent head on its drop, brass body and deflector,
  origin at the deflector.
- `LinearHighBay`: a linear LED high-bay 1.22 x 0.30 m and 0.08 m deep, its length along local z,
  white housing and its lens (a separate material, made luminous in the game) underneath, origin
  at the lens; `FixtureChain`: a 1 m chain's stand-in, scaled to each fixture's hang.

Coordinates are Godot's (x across, y up, z back); g() turns them into Blender's.

Usage, from the repository root:
    /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup \\
        --python-exit-code 1 --python tools/art/build_shed_services.py
"""

import math
import pathlib

import bmesh
import bpy
from mathutils import Matrix, Vector

ROOT = pathlib.Path(__file__).resolve().parents[2]
ART = ROOT / "game/features/environments/industrial_loop/art/racking"
OUT = ART / "shed_services.glb"

INCH = 0.0254
HALF_SPAN = 14.75
PITCH = math.radians(5.0)
HALF_BUILDING = 15.0
LINER = 0.05
DEPTH = 1.2
CHORD = (5 * INCH, 2.5 * INCH)
WEB = 0.028
PANEL = 1.2
DUCT = {"length": 3.0, "radius": 0.3, "band": 0.05, "seam_pitch": 0.3}
MAIN = {"length": 120 * INCH, "radius": 4.5 * INCH / 2.0, "coupling": (0.075, 0.07)}
HEAD = {"drop": 0.22, "body": 0.012, "deflector": 0.036}
FIXTURE = (0.30, 0.08, 1.22)
PAINT = {"joist": ((0.86, 0.87, 0.87), 0.2, 0.5), "red": ((0.62, 0.07, 0.05), 0.2, 0.45),
         "brass": ((0.72, 0.56, 0.3), 0.9, 0.35), "housing": ((0.92, 0.93, 0.94), 0.1, 0.4),
         "lens": ((0.98, 0.98, 1.0), 0.0, 0.2), "strap": ((0.6, 0.61, 0.62), 0.8, 0.4)}


def g(x, y, z):
    return Vector((x, -z, y))


def linear(value):
    return value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4


def material(name, colour, metallic, roughness, image=None):
    made = bpy.data.materials.new(name)
    made.use_nodes = True
    tree = made.node_tree
    shader = next(n for n in tree.nodes if n.type == "BSDF_PRINCIPLED")
    shader.inputs["Base Color"].default_value = tuple(linear(c) for c in colour) + (1.0,)
    shader.inputs["Metallic"].default_value = metallic
    shader.inputs["Roughness"].default_value = roughness
    if image is not None:
        texture = tree.nodes.new("ShaderNodeTexImage")
        texture.image = bpy.data.images.load(str(ART / image))
        tree.links.new(texture.outputs["Color"], shader.inputs["Base Color"])
    made.use_backface_culling = True
    return made


def box(bm, low, high):
    low, high = Vector(low), Vector(high)
    made = bmesh.ops.create_cube(bm, size=1.0)
    size = high - low
    bmesh.ops.scale(bm, vec=Vector((size.x, size.z, size.y)), verts=made["verts"])
    bmesh.ops.translate(bm, vec=g(*((low + high) / 2.0)), verts=made["verts"])


def bar(bm, a, b, wide, deep):
    start, end = g(*a), g(*b)
    length = (end - start).length
    made = bmesh.ops.create_cube(bm, size=1.0)
    verts = made["verts"]
    bmesh.ops.scale(bm, vec=Vector((wide, deep, length)), verts=verts)
    rotation = Vector((0.0, 0.0, 1.0)).rotation_difference((end - start).normalized()).to_matrix()
    bmesh.ops.rotate(bm, cent=Vector(), matrix=rotation, verts=verts)
    bmesh.ops.translate(bm, vec=(start + end) / 2.0, verts=verts)


def tube(bm, start_x, length, radius, centre_y=0.0, centre_z=0.0, segments=24, uv_pitch=None):
    """A tube along Godot's x; with `uv_pitch`, UVs round it (u) and along it (v, per pitch)."""
    made = bmesh.ops.create_cone(bm, cap_ends=True, segments=segments, radius1=radius,
                                 radius2=radius, depth=length)
    verts = made["verts"]
    bmesh.ops.rotate(bm, cent=Vector(), matrix=Matrix.Rotation(math.pi / 2.0, 3, "Y"),
                     verts=verts)
    bmesh.ops.translate(bm, vec=g(start_x + length / 2.0, centre_y, centre_z), verts=verts)
    if uv_pitch is not None:
        layer = bm.loops.layers.uv.verify()
        faces = list({f for v in verts for f in v.link_faces})
        for face in faces:
            for loop in face.loops:
                co = loop.vert.co
                angle = math.atan2(co.z - centre_y, -co.y - centre_z) / math.tau + 0.5
                loop[layer].uv = (angle, co.x / uv_pitch)


def finish(name, bm, materials, slots=None):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    for made in materials:
        obj.data.materials.append(made)
    if slots is not None:
        for polygon, slot in zip(mesh.polygons, slots):
            polygon.material_index = slot
    return obj


def top_chord(z):
    return (HALF_BUILDING - abs(z)) * math.tan(PITCH) - LINER


def joist(mats):
    bm = bmesh.new()
    wide, tall = CHORD
    for side in (-1.0, 1.0):
        end = side * HALF_SPAN
        for drop in (tall / 2.0, DEPTH - tall / 2.0):
            bar(bm, (0.0, top_chord(0.0) - drop, 0.0), (0.0, top_chord(end) - drop, end), wide,
                tall)
        panels = int(HALF_SPAN // PANEL)
        for index in range(panels):
            z0, z1 = side * index * PANEL, side * min((index + 1) * PANEL, HALF_SPAN - 0.1)
            low = (z0, top_chord(z0) - DEPTH + tall) if index % 2 == 0 else (z0, top_chord(z0) -
                                                                             tall)
            high = (z1, top_chord(z1) - tall) if index % 2 == 0 else (z1, top_chord(z1) - DEPTH +
                                                                      tall)
            bar(bm, (0.0, low[1], low[0]), (0.0, high[1], high[0]), WEB, WEB)
        bar(bm, (0.0, top_chord(end) - DEPTH, end - side * 0.05), (0.0, top_chord(end),
            end - side * 0.05), CHORD[1], CHORD[1])
        box(bm, (-0.1, top_chord(end) - 0.13, min(end, end - side * 0.15)),
            (0.1, top_chord(end) - 0.05, max(end, end - side * 0.15)))
    return finish("RoofJoist", bm, [mats["joist"]])


def duct(mats):
    bm = bmesh.new()
    tube(bm, 0.0, DUCT["length"], DUCT["radius"], segments=32, uv_pitch=DUCT["seam_pitch"])
    count = len(bm.faces)
    tube(bm, DUCT["length"] - DUCT["band"], DUCT["band"], DUCT["radius"] + 0.006, segments=32)
    slots = [0] * count + [1] * (len(bm.faces) - count)
    run = finish("DuctRun", bm, [mats["duct"], mats["joist"]], slots)
    straps = bmesh.new()
    for x in (-0.03, 0.03):
        box(straps, (x - 0.015, 0.0, -0.0015), (x + 0.015, 1.0, 0.0015))
    return [run, finish("DuctHanger", straps, [mats["strap"]])]


def main_pipe(mats):
    bm = bmesh.new()
    tube(bm, 0.0, MAIN["length"], MAIN["radius"], segments=16)
    radius, length = MAIN["coupling"]
    tube(bm, MAIN["length"] - length / 2.0, length, radius, segments=16)
    pipe = finish("SprinklerMain", bm, [mats["red"]])
    head = bmesh.new()
    bar(head, (0.0, 0.0, 0.0), (0.0, HEAD["drop"], 0.0), 0.027, 0.027)
    bar(head, (0.0, 0.012, 0.0), (0.0, 0.05, 0.0), HEAD["body"] * 2.0, HEAD["body"] * 2.0)
    made = bmesh.ops.create_cone(head, cap_ends=True, segments=16, radius1=HEAD["deflector"],
                                 radius2=HEAD["deflector"], depth=0.003)
    bmesh.ops.translate(head, vec=g(0.0, 0.0, 0.0), verts=made["verts"])
    slots = [0] * 6 + [1] * (len(head.faces) - 6)
    return [pipe, finish("SprinklerHead", head, [mats["red"], mats["brass"]], slots)]


def fixture(mats):
    bm = bmesh.new()
    wide, tall, long = FIXTURE
    box(bm, (-wide / 2.0, 0.004, -long / 2.0), (wide / 2.0, tall, long / 2.0))
    count = len(bm.faces)
    box(bm, (-wide / 2.0 + 0.02, 0.0, -long / 2.0 + 0.03), (wide / 2.0 - 0.02, 0.004,
        long / 2.0 - 0.03))
    slots = [0] * count + [1] * (len(bm.faces) - count)
    light = finish("LinearHighBay", bm, [mats["housing"], mats["lens"]], slots)
    chain = bmesh.new()
    box(chain, (-0.006, 0.0, -0.006), (0.006, 1.0, 0.006))
    return [light, finish("FixtureChain", chain, [mats["strap"]])]


def main():
    for obj in list(bpy.context.scene.objects):
        bpy.data.objects.remove(obj)
    mats = {key: material(key, *PAINT[key]) for key in PAINT}
    mats["duct"] = material("duct", (1, 1, 1), 0.3, 0.45, "duct_seam.png")
    parts = [joist(mats)] + duct(mats) + main_pipe(mats) + fixture(mats)
    for obj in list(bpy.context.scene.objects):
        obj.select_set(obj in parts)
    bpy.ops.export_scene.gltf(filepath=str(OUT), export_format="GLB", use_selection=True,
                              use_active_scene=True, export_apply=True, export_yup=True,
                              export_image_format="AUTO")
    for obj in parts:
        print(f"  {obj.name}: {len(obj.data.polygons)} faces")
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
