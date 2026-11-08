"""Build the roadside streetlight (#154) as a glTF file for Godot.

A US roadside street lamp of the high-pressure sodium kind: a tapered round steel pole on a
concrete footing, with a bolted base plate and a hand-hole cover, that bends over in a davit
arm to a cobra-head luminaire with a drop refractor underneath and a photocell on top. The
arm reaches 1.9 m out from the pole's axis, and the refractor's middle hangs about 7 m up, as
the game's lamps did.

Every face has real-world UVs (one UV unit is one metre). Each part's material is named after
the Godot material that replaces it: "pole", "housing", "lens", "footing" and "steel". No image
is embedded. An empty, "Lens", marks where the light leaves the refractor.

The arm points along Blender's -X, which stays Godot's -X. The origin is the pole's axis at
ground level; the footing reaches 0.4 m below it.

Usage, from the repository root:
    /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup \\
        --python-exit-code 1 --python tools/art/build_streetlight.py
"""

import math
import pathlib

import bmesh
import bpy
from mathutils import Vector

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "game/features/environments/industrial_loop/art/streetlight/streetlight.glb"

SLOTS = ["pole", "housing", "lens", "footing", "steel"]
COLOURS = {
    "pole": (0.36, 0.38, 0.39),
    "housing": (0.5, 0.52, 0.53),
    "lens": (1.0, 0.62, 0.25),
    "footing": (0.55, 0.55, 0.53),
    "steel": (0.25, 0.26, 0.27),
}

FOOTING = (0.3, -0.4, 0.1)
PLATE = (0.34, 0.025)
BOLT_SPREAD = 0.12
POLE_FOOT = PLATE[1] + FOOTING[2]
POLE_RADII = (0.095, 0.068)
BEND_FROM = 5.75
BEND = 1.3
ARM_END = Vector((-1.58, 0.0, BEND_FROM + BEND + 0.02))
ARM_RADII = (0.052, 0.046)
HOUSING = [
    (-1.52, 0.07, 7.02, 7.12),
    (-1.62, 0.13, 6.995, 7.16),
    (-1.75, 0.165, 6.985, 7.19),
    (-1.95, 0.175, 6.985, 7.2),
    (-2.15, 0.16, 6.99, 7.18),
    (-2.27, 0.12, 7.0, 7.14),
    (-2.32, 0.05, 7.02, 7.09),
]
REFRACTOR = (Vector((-1.97, 0.0, 6.986)), 0.21, 0.13, 0.06)
PHOTOCELL = (Vector((-1.8, 0.0, 7.19)), 0.038, 0.06)
LENS_MARK = Vector((-1.97, 0.0, 6.92))


def slot(name):
    return SLOTS.index(name)


def frames(points):
    tangents = []
    for index, point in enumerate(points):
        ahead = points[min(index + 1, len(points) - 1)]
        behind = points[max(index - 1, 0)]
        tangents.append((ahead - behind).normalized())
    normal = Vector((0.0, 1.0, 0.0)).cross(tangents[0])
    if normal.length < 1e-6:
        normal = Vector((1.0, 0.0, 0.0))
    normal.normalize()
    result = []
    for tangent in tangents:
        normal = (normal - tangent * normal.dot(tangent)).normalized()
        result.append((tangent, normal, tangent.cross(normal).normalized()))
    return result


def tube(bm, uv, points, radii, name, sides=20, cap_start=True, cap_end=True):
    rings = []
    for point, radius, (_, normal, binormal) in zip(points, radii, frames(points)):
        ring = []
        for side in range(sides):
            turn = 2.0 * math.pi * side / sides
            ring.append(bm.verts.new(point + (normal * math.cos(turn)
                                              + binormal * math.sin(turn)) * radius))
        rings.append(ring)
    along = [0.0]
    for index in range(1, len(points)):
        along.append(along[-1] + (points[index] - points[index - 1]).length)
    for index in range(len(points) - 1):
        around = 2.0 * math.pi * (radii[index] + radii[index + 1]) * 0.5
        for side in range(sides):
            nxt = (side + 1) % sides
            face = bm.faces.new((rings[index][side], rings[index][nxt],
                                 rings[index + 1][nxt], rings[index + 1][side]))
            face.material_index = slot(name)
            face.smooth = True
            u0 = around * side / sides
            u1 = around * (side + 1) / sides
            for loop, (u, v) in zip(face.loops, ((u0, along[index]), (u1, along[index]),
                                                 (u1, along[index + 1]),
                                                 (u0, along[index + 1]))):
                loop[uv].uv = (u, v)
    for ring, wanted, flip in ((rings[0], cap_start, True), (rings[-1], cap_end, False)):
        if not wanted:
            continue
        cap = bm.faces.new(list(reversed(ring)) if flip else ring)
        cap.material_index = slot(name)
        planar(cap, uv)
        for edge in cap.edges:
            edge.smooth = False
    return rings


def planar(face, uv):
    normal = face.normal
    axis = max(range(3), key=lambda index: abs(normal[index]))
    keep = [index for index in range(3) if index != axis]
    for loop in face.loops:
        loop[uv].uv = (loop.vert.co[keep[0]], loop.vert.co[keep[1]])


def cuboid(bm, uv, centre, size, name):
    half = Vector(size) * 0.5
    corners = [bm.verts.new(Vector(centre) + Vector((sx * half.x, sy * half.y, sz * half.z)))
               for sx in (-1, 1) for sy in (-1, 1) for sz in (-1, 1)]
    for indices in ((0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4),
                    (1, 5, 7, 3)):
        face = bm.faces.new([corners[index] for index in indices])
        face.material_index = slot(name)
        face.smooth = False
        planar(face, uv)


def prism(bm, uv, centre, radius, low, high, sides, name, smooth):
    bottom = [bm.verts.new(centre + Vector((radius * math.cos(2 * math.pi * k / sides),
                                            radius * math.sin(2 * math.pi * k / sides), low)))
              for k in range(sides)]
    top = [bm.verts.new(centre + Vector((radius * math.cos(2 * math.pi * k / sides),
                                         radius * math.sin(2 * math.pi * k / sides), high)))
           for k in range(sides)]
    around = 2.0 * math.pi * radius
    for k in range(sides):
        nxt = (k + 1) % sides
        face = bm.faces.new((bottom[k], bottom[nxt], top[nxt], top[k]))
        face.material_index = slot(name)
        face.smooth = smooth
        for loop, (u, v) in zip(face.loops, ((around * k / sides, low),
                                             (around * (k + 1) / sides, low),
                                             (around * (k + 1) / sides, high),
                                             (around * k / sides, high))):
            loop[uv].uv = (u, v)
    for ring, flip in ((bottom, True), (top, False)):
        cap = bm.faces.new(list(reversed(ring)) if flip else ring)
        cap.material_index = slot(name)
        cap.smooth = False
        planar(cap, uv)
        for edge in cap.edges:
            edge.smooth = False


def pole_path():
    points = []
    radii = []
    for height in (POLE_FOOT, 1.5, 3.0, 4.5, BEND_FROM):
        share = (height - POLE_FOOT) / (BEND_FROM - POLE_FOOT)
        points.append(Vector((0.0, 0.0, height)))
        radii.append(POLE_RADII[0] + (POLE_RADII[1] - POLE_RADII[0]) * share)
    for step in range(1, 13):
        turn = math.radians(90.0 * step / 12)
        points.append(Vector((-BEND + BEND * math.cos(turn), 0.0,
                              BEND_FROM + BEND * math.sin(turn))))
        radii.append(POLE_RADII[1] + (ARM_RADII[0] - POLE_RADII[1]) * step / 12)
    points.append(ARM_END)
    radii.append(ARM_RADII[1])
    return points, radii


def housing(bm, uv):
    arc = 14
    sections = []
    for x, half, bottom, top in HOUSING:
        ring = [bm.verts.new((x, -half, bottom)), bm.verts.new((x, half, bottom))]
        for step in range(1, arc):
            turn = math.pi * step / arc
            lift = math.sin(turn) ** 0.6
            ring.append(bm.verts.new((x, half * math.cos(turn), bottom + (top - bottom) * lift)))
        sections.append(ring)
    count = len(sections[0])
    for index in range(len(sections) - 1):
        for k in range(count):
            nxt = (k + 1) % count
            face = bm.faces.new((sections[index][k], sections[index + 1][k],
                                 sections[index + 1][nxt], sections[index][nxt]))
            face.material_index = slot("housing")
            face.smooth = k != 0
            planar(face, uv)
    for ring, flip in ((sections[0], False), (sections[-1], True)):
        cap = bm.faces.new(list(reversed(ring)) if flip else ring)
        cap.material_index = slot("housing")
        cap.smooth = False
        planar(cap, uv)


def refractor(bm, uv):
    centre, along, across, depth = REFRACTOR
    segments, rings = 24, 7
    columns = []
    for ring in range(rings + 1):
        fall = (math.pi / 2) * ring / rings
        row = []
        for segment in range(segments):
            turn = 2 * math.pi * segment / segments
            row.append(bm.verts.new(centre + Vector((along * math.cos(fall) * math.cos(turn),
                                                     across * math.cos(fall) * math.sin(turn),
                                                     -depth * math.sin(fall)))))
        columns.append(row)
    for ring in range(rings):
        for segment in range(segments):
            nxt = (segment + 1) % segments
            face = bm.faces.new((columns[ring][segment], columns[ring][nxt],
                                 columns[ring + 1][nxt], columns[ring + 1][segment]))
            face.material_index = slot("lens")
            face.smooth = True
            planar(face, uv)


def photocell(bm, uv):
    centre, radius, height = PHOTOCELL
    prism(bm, uv, Vector((centre.x, centre.y, 0.0)), radius, centre.z, centre.z + height, 16,
          "housing", True)


def base(bm, uv):
    prism(bm, uv, Vector((0.0, 0.0, 0.0)), FOOTING[0], FOOTING[1], FOOTING[2], 24, "footing",
          True)
    cuboid(bm, uv, (0.0, 0.0, FOOTING[2] + PLATE[1] / 2), (PLATE[0], PLATE[0], PLATE[1]),
           "steel")
    for sx in (-1, 1):
        for sy in (-1, 1):
            at = Vector((sx * BOLT_SPREAD, sy * BOLT_SPREAD, 0.0))
            prism(bm, uv, at, 0.026, POLE_FOOT, POLE_FOOT + 0.028, 6, "steel", False)
            prism(bm, uv, at, 0.012, POLE_FOOT + 0.028, POLE_FOOT + 0.06, 8, "steel", True)
    radius = POLE_RADII[0] + (POLE_RADII[1] - POLE_RADII[0]) * (0.62 - POLE_FOOT) / (
        BEND_FROM - POLE_FOOT)
    cuboid(bm, uv, (radius + 0.004, 0.0, 0.62), (0.012, 0.085, 0.22), "steel")


def build(scene):
    mesh = bpy.data.meshes.new("Streetlight")
    for name in SLOTS:
        material = bpy.data.materials.new(name)
        material.use_nodes = True
        shader = next(node for node in material.node_tree.nodes
                      if node.type == "BSDF_PRINCIPLED")
        shader.inputs["Base Color"].default_value = (*COLOURS[name], 1.0)
        shader.inputs["Roughness"].default_value = 0.5
        mesh.materials.append(material)
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new("UVMap")
    points, radii = pole_path()
    tube(bm, uv, points, radii, "pole", cap_start=True, cap_end=True)
    housing(bm, uv)
    refractor(bm, uv)
    photocell(bm, uv)
    base(bm, uv)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.normal_update()
    bm.to_mesh(mesh)
    bm.free()
    light = bpy.data.objects.new("Streetlight", mesh)
    scene.collection.objects.link(light)
    mark = bpy.data.objects.new("Lens", None)
    mark.location = LENS_MARK
    scene.collection.objects.link(mark)
    return [light, mark]


def export(objects):
    for obj in list(bpy.context.scene.objects):
        obj.select_set(obj in objects)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(OUT), export_format="GLB", use_selection=True,
                              export_image_format="NONE", export_apply=True, export_yup=True)
    triangles = sum(len(polygon.vertices) - 2 for polygon in objects[0].data.polygons)
    print(f"Wrote {OUT} ({triangles} triangles)")


def main():
    scene = bpy.context.scene
    for obj in list(scene.objects):
        bpy.data.objects.remove(obj)
    export(build(scene))


if __name__ == "__main__":
    main()
