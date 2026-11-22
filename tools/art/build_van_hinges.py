"""Build the freight van's rear-door hinges (#258-#261) as a glTF file for Godot.

The Iveco Daily's twin rear doors open 270 degrees and lie flush against its sides, stopping at
90, 180 and 270 (Iveco's press kit), so each door turns about a pin out beyond its own edge, at
the body's rear corner. Each hinge here is the compact hinge a van's door hangs on, small and
in the finish of the door where it sits so that it blends into the body (the author's choice,
#261: "painted the van's white"): above the tail lamp the doors' white paint, and below it, where
the doors' foot is a black trim band beside the black bumper corner, that trim's black:

- the arm (`HingeArmL`, `HingeArmR`, and `HingeArmUpperL` and `R` for the upper hinges), on the
  door: a short pad bolted to the door's outer face at
  its edge, reaching only 0.03 m onto it, and a slim arm tapering from it over the corner pillar
  to the middle knuckle round the pin;
- the bracket (`HingeBracketL`, `HingeBracketR`, and `HingeBracketUpperL` and `R` for the upper
  hinges), on the body: a small plate bolted to the corner pillar's rear face, laid along that
  face's own slant, two lugs to the upper and lower knuckles, and the capped pin through all
  three.

Each object's origin is its pin's middle, so the game hangs the arm on the door (whose own origin
is the pin) and sets the bracket at the same point on the body. Sizes are in metres, measured
from the converted van (`convert_iveco.py`): the door's edge is 0.156 m in from the pin and its
outer face 0.01 m in front of it. The pillar's rear face was found by casting rays forward onto
the Iveco's body beside each pin: below the tail lamp (0.52 m) it runs from 0.059 m in front of
the pin, 0.085 m in, to 0.067 m in front, 0.045 m in, and nearer the corner it rounds away; above
the lamp (1.65 m) the body narrows toward the roof and its face starts only 0.08 m in, slanting
from 0.074 m in front, 0.125 m in, to 0.090 m in front, 0.09 m in. The finishes are the doors'
own, sampled from the Iveco's Back_door textures over their outer skin beside each hinge's pad:
the paint sRGB 0.91, roughness 0.482, metalness 0.439; the trim sRGB 0.18, roughness 0.49, not
metallic. Coordinates below are Godot's (x across, y up, z back); the left side is the
right mirrored.

Usage, from the repository root:
    /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup \\
        --python-exit-code 1 --python tools/art/build_van_hinges.py
"""

import math
import pathlib

import bmesh
import bpy
from mathutils import Matrix, Vector

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "game/features/vehicles/freight_van/art/van_hinges.glb"

DOOR_EDGE = 0.156
DOOR_FACE = 0.010
PAD = {"onto": 0.03, "height": 0.028, "thick": 0.009}
ARM = {"root": 0.026, "tip": 0.014}
KNUCKLE = {"radius": 0.010, "middle": 0.014, "outer": 0.0085, "gap": 0.0008}
PIN = {"radius": 0.004, "cap": 0.0055, "cap_thick": 0.002}
PLATE = {"height": 0.036, "thick": 0.006, "inset": 0.006}
## The pillar's rear face beside each pin, from its inner point to its outer: (x, z) pairs.
FACES = {"": ((-0.085, -0.059), (-0.045, -0.067)),
         "Upper": ((-0.125, -0.074), (-0.090, -0.090))}
LUG = {"width": 0.014}
BOLT = {"radius": 0.004, "height": 0.0025}
BEVEL = 0.0015
UV_METRES = 0.1
## Each level's finish: sRGB colour, roughness, metalness.
FINISHES = {"": ("hinge_trim", (0.18, 0.168, 0.195), 0.49, 0.0),
            "Upper": ("hinge_paint", (0.91, 0.91, 0.91), 0.482, 0.439)}


def g(x, y, z):
    """Godot's (x, y, z) as Blender's: x stays, Godot's up is Blender's z, Godot's +z Blender's -y."""
    return Vector((x, -z, y))


def linear(value):
    """An sRGB channel as linear, as Blender's base colour takes it."""
    return value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4


def material(level):
    name, colour, roughness, metalness = FINISHES[level]
    finish = bpy.data.materials.new(name)
    finish.use_nodes = True
    shader = next(n for n in finish.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    shader.inputs["Base Color"].default_value = tuple(linear(c) for c in colour) + (1.0,)
    shader.inputs["Metallic"].default_value = metalness
    shader.inputs["Roughness"].default_value = roughness
    return finish


def slab(bm, centre, length, height, thick, angle=0.0, taper=1.0):
    """A box `length` along its own x, `height` up and `thick` deep, turned `angle` about Godot's
    y and centred at `centre`; `taper` scales its height at its +x end."""
    made = bmesh.ops.create_cube(bm, size=1.0)
    verts = made["verts"]
    bmesh.ops.scale(bm, vec=Vector((length, thick, height)), verts=verts)
    for vert in verts:
        if vert.co.x > 0.0:
            vert.co.z *= taper
    bmesh.ops.rotate(bm, cent=Vector(), matrix=Matrix.Rotation(angle, 3, "Z"), verts=verts)
    bmesh.ops.translate(bm, vec=g(*centre), verts=verts)


def cylinder(bm, centre, radius, length, segments=24):
    """A cylinder along Godot's y: a pin, knuckle or cap."""
    made = bmesh.ops.create_cone(bm, cap_ends=True, segments=segments, radius1=radius,
                                 radius2=radius, depth=length)
    bmesh.ops.translate(bm, vec=g(*centre), verts=made["verts"])


def bar(bm, a, b, thick, width):
    """A flat bar from `a` to `b` in Godot's xz plane, `thick` along Godot's y, `width` across."""
    start, end = g(*a), g(*b)
    length = (end - start).length
    made = bmesh.ops.create_cube(bm, size=1.0)
    verts = made["verts"]
    bmesh.ops.scale(bm, vec=Vector((length, width, thick)), verts=verts)
    angle = math.atan2(end.y - start.y, end.x - start.x)
    bmesh.ops.rotate(bm, cent=Vector(), matrix=Matrix.Rotation(angle, 3, "Z"), verts=verts)
    bmesh.ops.translate(bm, vec=(start + end) / 2.0, verts=verts)


def dome(bm, centre, angle=0.0):
    """A bolt's round head on a face looking toward Godot's +z, turned `angle` about Godot's y."""
    made = bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=8, radius=BOLT["radius"])
    verts = list(made["verts"])
    for vert in verts:
        vert.co.y *= BOLT["height"] / BOLT["radius"]
    behind = [v for v in verts if v.co.y > 0.0]
    bmesh.ops.delete(bm, geom=behind, context="VERTS")
    kept = set(verts)
    verts = [v for v in bm.verts if v.is_valid and v in kept]
    bmesh.ops.rotate(bm, cent=Vector(), matrix=Matrix.Rotation(angle, 3, "Z"), verts=verts)
    bmesh.ops.translate(bm, vec=g(*centre), verts=verts)


def box_uvs(bm):
    """UVs projected from each face's own axis, 1 UV unit to UV_METRES of steel."""
    bm.normal_update()
    layer = bm.loops.layers.uv.new("UVMap")
    for face in bm.faces:
        axis = max(range(3), key=lambda i: abs(face.normal[i]))
        u, v = [i for i in range(3) if i != axis]
        for loop in face.loops:
            loop[layer].uv = (loop.vert.co[u] / UV_METRES, loop.vert.co[v] / UV_METRES)


def finish(name, bm, paint, mirror):
    if mirror:
        bmesh.ops.scale(bm, vec=Vector((-1.0, 1.0, 1.0)), verts=bm.verts[:])
        bmesh.ops.reverse_faces(bm, faces=bm.faces[:])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    box_uvs(bm)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(paint)
    bevel = obj.modifiers.new("Bevel", "BEVEL")
    bevel.width = BEVEL
    bevel.segments = 2
    bevel.limit_method = "ANGLE"
    for polygon in mesh.polygons:
        polygon.use_smooth = True
    return obj


def arm(paint, mirror, level):
    """On the door: the pad on its outer face at its edge, and the arm tapering to the knuckle."""
    bm = bmesh.new()
    face = -DOOR_FACE + PAD["thick"] / 2.0 - 0.001
    inner = -(DOOR_EDGE + PAD["onto"])
    slab(bm, ((inner - DOOR_EDGE) / 2.0, 0.0, face), PAD["onto"], PAD["height"], PAD["thick"])
    start, end = -DOOR_EDGE - 0.004, -0.004
    slab(bm, ((start + end) / 2.0, 0.0, face), end - start, ARM["root"], PAD["thick"],
         taper=ARM["tip"] / ARM["root"])
    cylinder(bm, (0.0, 0.0, 0.0), KNUCKLE["radius"], KNUCKLE["middle"])
    for y in (-0.007, 0.007):
        dome(bm, (inner + PAD["onto"] / 2.0, y, face + PAD["thick"] / 2.0))
    return finish("HingeArm" + level + ("L" if mirror else "R"), bm, paint, mirror)


def bracket(paint, mirror, level):
    """On the body: the plate along the pillar's face, two lugs and outer knuckles, the pin."""
    bm = bmesh.new()
    (x1, z1), (x2, z2) = FACES[level]
    length = math.hypot(x2 - x1, z2 - z1)
    ux, uz = (x2 - x1) / length, (z2 - z1) / length
    nx, nz = -uz, ux
    if nz < 0.0:
        nx, nz = -nx, -nz
    angle = math.atan2(-uz, ux)
    half = PLATE["thick"] / 2.0
    slab(bm, ((x1 + x2) / 2.0 + nx * half, 0.0, (z1 + z2) / 2.0 + nz * half), length,
         PLATE["height"], PLATE["thick"], angle)
    outer_x = x2 - ux * PLATE["inset"] + nx * PLATE["thick"]
    outer_z = z2 - uz * PLATE["inset"] + nz * PLATE["thick"]
    offset = KNUCKLE["middle"] / 2.0 + KNUCKLE["gap"] + KNUCKLE["outer"] / 2.0
    for side in (-1.0, 1.0):
        y = side * offset
        cylinder(bm, (0.0, y, 0.0), KNUCKLE["radius"], KNUCKLE["outer"])
        bar(bm, (0.0, y, 0.0), (outer_x, y, outer_z), KNUCKLE["outer"], LUG["width"])
    pin = 2.0 * (offset + KNUCKLE["outer"] / 2.0) + 0.002
    cylinder(bm, (0.0, 0.0, 0.0), PIN["radius"], pin)
    for side in (-1.0, 1.0):
        cylinder(bm, (0.0, side * (pin / 2.0 + PIN["cap_thick"] / 2.0), 0.0), PIN["cap"],
                 PIN["cap_thick"])
    for along in (0.3, 0.7):
        dome(bm, (x1 + (x2 - x1) * along + nx * PLATE["thick"], 0.0,
                  z1 + (z2 - z1) * along + nz * PLATE["thick"]), angle)
    return finish("HingeBracket" + level + ("L" if mirror else "R"), bm, paint, mirror)


def export(objects):
    for obj in list(bpy.context.scene.objects):
        obj.select_set(obj in objects)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(OUT), export_format="GLB", use_selection=True,
                              export_image_format="NONE", export_apply=True, export_yup=True)
    depsgraph = bpy.context.evaluated_depsgraph_get()
    for obj in objects:
        evaluated = obj.evaluated_get(depsgraph)
        corners = [evaluated.matrix_world @ Vector(c) for c in evaluated.bound_box]
        tall = max(c.z for c in corners) - min(c.z for c in corners)
        print(f"  {obj.name}: {len(evaluated.data.polygons)} faces, {tall:.4f} m tall")
    print(f"Wrote {OUT}")


def main():
    for obj in list(bpy.context.scene.objects):
        bpy.data.objects.remove(obj)
    parts = []
    for level in FACES:
        finish = material(level)
        for mirror in (False, True):
            parts += [arm(finish, mirror, level), bracket(finish, mirror, level)]
    export(parts)


if __name__ == "__main__":
    main()
