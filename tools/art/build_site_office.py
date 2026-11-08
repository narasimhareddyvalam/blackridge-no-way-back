"""Build the lumber yard's timber site office (decision C36) as a glTF file for Godot.

The office is a small timber building on a concrete plinth: weathered plank siding, a
corrugated iron gable roof with gutters, a downpipe and a stovepipe, a plank door under a
bracketed hood with a timber landing, a sliding window with lit blinds, a side window, gable
vents, a meter box, an OFFICE board with the run sheet's clipboard under a gooseneck lamp, and
a yard floodlight on the corner, turned toward the van's place on the road.

Every face has real-world UVs (one UV unit is one metre), so Godot lays Poly Haven's CC0
textures over it at their real size. Each part's material is named after the Godot material
that replaces it ("siding", "roof", "door" and so on); no image is embedded in the file. The
Blender materials carry the same textures, only for previews.

Empties mark where Godot puts things: "RunSheet" (the clipboard's paper), "NoticeLamp" (in the
gooseneck's shade), "Floodlight" (the floodlight's lens) and "WindowLight" (in front of the
window). A light empty's local +Y is its beam, which Godot reads as the light's -Z. The boxes
"Building" and "Landing" carry Godot's "-convcolonly" suffix, so they import as collision only.

The front faces Blender's -Y, which becomes Godot's +Z. The origin is the middle of the
footprint at ground level.

Usage, from the repository root:
    /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup \\
        --python-exit-code 1 --python tools/art/build_site_office.py
"""

import math
import pathlib

import bmesh
import bpy
from mathutils import Matrix, Vector

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "game/features/environments/industrial_loop/art/office/site_office.glb"
TEXTURES = ROOT / "game/features/environments/industrial_loop/polyhaven/textures"

WIDTH = 6.0
DEPTH = 3.6
FLOOR = 0.35
EAVE = FLOOR + 2.6
PITCH = math.radians(22.0)
RIDGE = EAVE + DEPTH / 2 * math.tan(PITCH)
EAVE_OVERHANG = 0.35
GABLE_OVERHANG = 0.3
WALL = 0.14
ROOF = 0.05
FRONT = -DEPTH / 2
DOOR = (-1.6, 0.92, 2.05)
WINDOW = (1.4, 1.3, 1.0, 0.95)
SIDE_WINDOW = (0.35, 0.9, 0.9, 1.15)
HOOD = (1.5, 0.8, 2.3, 0.15)
LANDING = (1.4, 1.0)
STEP = 0.3
NOTICE = -0.4
BOARD = (0.78, 0.22, 2.05)
CLIPBOARD = 1.45
LAMP = 2.5
LAMP_AIM = Vector((0.0, 0.35, -1.0))
FLOOD = (2.82, 2.45, math.radians(26.0), math.radians(12.0))
STOVEPIPE = (1.6, 0.9, 0.075, 0.75)
VENT = (0.5, 0.28, 0.3)
QUADS = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]

SLOTS = ["siding", "trim", "roof", "door", "deck", "concrete", "metal", "glass", "blinds",
         "window_glow", "lamp_glow", "sign", "letters", "paper", "clipboard"]
PREVIEW = {
    "siding": ("weathered_plank_siding", "2k", 1.57),
    "roof": ("corrugated_iron", "1k", 1.12),
    "door": ("rough_pine_door", "1k", 2.0),
    "deck": ("stair_planks", "1k", 1.2),
    "concrete": ("brushed_concrete_03", "1k", 2.0),
}
COLOURS = {
    "trim": (0.5, 0.48, 0.43), "metal": (0.16, 0.17, 0.18), "glass": (0.6, 0.66, 0.7),
    "blinds": (0.75, 0.72, 0.64), "window_glow": (1.0, 0.85, 0.6),
    "lamp_glow": (1.0, 0.9, 0.7), "sign": (0.03, 0.12, 0.07), "letters": (0.85, 0.84, 0.78),
    "paper": (0.86, 0.84, 0.78), "clipboard": (0.3, 0.2, 0.12),
}


def slot(name):
    return SLOTS.index(name)


def roof_line(distance):
    return RIDGE - distance * math.tan(PITCH)


def cuboid(bm, centre, size, name, turn=None):
    turn = Matrix.Identity(3) if turn is None else turn
    half = Vector(size) / 2.0
    corners = [bm.verts.new(Vector(centre) + turn @ Vector((x * half.x, y * half.y, z * half.z)))
               for x in (-1, 1) for y in (-1, 1) for z in (-1, 1)]
    faces = [bm.faces.new([corners[index] for index in quad]) for quad in QUADS]
    for face in faces:
        face.material_index = slot(name)
    return faces


def beam(bm, start, end, width, height, name):
    start, end = Vector(start), Vector(end)
    turn = (end - start).to_track_quat("Y", "Z").to_matrix()
    return cuboid(bm, (start + end) / 2, (width, (end - start).length, height), name, turn)


def rounded(verts, name):
    faces = list(dict.fromkeys(face for vert in verts for face in vert.link_faces))
    for face in faces:
        face.material_index = slot(name)
        face.smooth = len(face.verts) == 4
    for face in faces:
        if not face.smooth:
            for edge in face.edges:
                edge.smooth = False
    return faces


def tube(bm, start, end, radius, name, sides=12, ends=True):
    start, end = Vector(start), Vector(end)
    direction = end - start
    up = "X" if abs(direction.normalized().y) > 0.9 else "Y"
    turn = direction.to_track_quat("Z", up).to_matrix().to_4x4()
    made = bmesh.ops.create_cone(bm, cap_ends=ends, segments=sides, radius1=radius,
                                 radius2=radius, depth=direction.length,
                                 matrix=Matrix.Translation((start + end) / 2) @ turn)
    return rounded(made["verts"], name)


def pipe(bm, points, radius, name, sides=12):
    points = [Vector(point) for point in points]
    for index, (start, end) in enumerate(zip(points, points[1:])):
        along = (end - start).normalized() * radius
        tube(bm, start - along * (index > 0), end + along * (index < len(points) - 2), radius,
             name, sides)


def wall(bm, origin, along, up, width, height, holes):
    origin, along, up = Vector(origin), Vector(along), Vector(up)
    cuts_u = sorted({0.0, width, *[edge for hole in holes for edge in (hole[0], hole[2])]})
    cuts_v = sorted({0.0, height, *[edge for hole in holes for edge in (hole[1], hole[3])]})
    grid = [[bm.verts.new(origin + along * u + up * v) for v in cuts_v] for u in cuts_u]
    faces = []
    for i in range(len(cuts_u) - 1):
        for j in range(len(cuts_v) - 1):
            middle = ((cuts_u[i] + cuts_u[i + 1]) / 2, (cuts_v[j] + cuts_v[j + 1]) / 2)
            if any(hole[0] < middle[0] < hole[2] and hole[1] < middle[1] < hole[3]
                   for hole in holes):
                continue
            face = bm.faces.new([grid[i][j], grid[i + 1][j], grid[i + 1][j + 1],
                                 grid[i][j + 1]])
            face.material_index = slot("siding")
            face.normal_update()
            faces.append(face)
    bmesh.ops.solidify(bm, geom=faces, thickness=WALL)


def gable(bm, x, facing):
    points = [Vector((x, FRONT, EAVE)), Vector((x, -FRONT, EAVE)), Vector((x, 0.0, RIDGE))]
    if facing < 0:
        points.reverse()
    face = bm.faces.new([bm.verts.new(point) for point in points])
    face.material_index = slot("siding")
    face.normal_update()
    bmesh.ops.solidify(bm, geom=[face], thickness=WALL)


def walls(bm):
    rise = EAVE - FLOOR
    door_left = DOOR[0] + WIDTH / 2 - DOOR[1] / 2
    window_left = WINDOW[0] + WIDTH / 2 - WINDOW[1] / 2
    side_left = SIDE_WINDOW[0] - FRONT - SIDE_WINDOW[1] / 2
    wall(bm, (-WIDTH / 2, FRONT, FLOOR), (1, 0, 0), (0, 0, 1), WIDTH, rise,
         [(door_left, 0.0, door_left + DOOR[1], DOOR[2]),
          (window_left, WINDOW[3], window_left + WINDOW[1], WINDOW[3] + WINDOW[2])])
    wall(bm, (WIDTH / 2, -FRONT, FLOOR), (-1, 0, 0), (0, 0, 1), WIDTH, rise, [])
    wall(bm, (WIDTH / 2, FRONT, FLOOR), (0, 1, 0), (0, 0, 1), DEPTH, rise,
         [(side_left, SIDE_WINDOW[3], side_left + SIDE_WINDOW[1],
           SIDE_WINDOW[3] + SIDE_WINDOW[2])])
    wall(bm, (-WIDTH / 2, -FRONT, FLOOR), (0, -1, 0), (0, 0, 1), DEPTH, rise, [])
    gable(bm, WIDTH / 2, 1)
    gable(bm, -WIDTH / 2, -1)
    for x in (-1, 1):
        for y in (-1, 1):
            cuboid(bm, (x * (WIDTH / 2 + 0.005), y * (DEPTH / 2 + 0.005), (FLOOR + EAVE) / 2),
                   (0.12, 0.12, rise), "trim")
    cuboid(bm, (0.0, 0.0, FLOOR / 2), (WIDTH - 0.06, DEPTH - 0.06, FLOOR), "concrete")


def roof(bm):
    run = DEPTH / 2 + EAVE_OVERHANG
    slope = run / math.cos(PITCH)
    length = WIDTH + 2 * GABLE_OVERHANG
    lift = ROOF / 2 / math.cos(PITCH)
    edge = run - 0.03
    for side in (-1, 1):
        turn = Matrix.Rotation(-side * PITCH, 3, "X")
        cuboid(bm, (0.0, side * run / 2, roof_line(run / 2) + lift), (length, slope, ROOF),
               "roof", turn)
        cap = 0.09 * math.cos(PITCH)
        cuboid(bm, (0.0, side * cap, roof_line(cap) + 2 * lift + 0.006 / math.cos(PITCH)),
               (length + 0.02, 0.2, 0.012), "metal", turn)
        cuboid(bm, (0.0, side * (edge - 0.015), roof_line(edge) - 0.09), (length, 0.03, 0.18),
               "trim")
        cuboid(bm, (0.0, side * (edge + 0.055), roof_line(edge) - 0.07),
               (length - 0.04, 0.11, 0.1), "metal")
        for end in (-1, 1):
            cuboid(bm, (end * (length / 2 - 0.045), side * run / 2, roof_line(run / 2) - 0.08),
                   (0.03, slope, 0.16), "trim", turn)
    gutter = roof_line(edge) - 0.12
    x = -WIDTH / 2 + 0.22
    pipe(bm, [(x, -(edge + 0.055), gutter), (x, FRONT - 0.06, gutter - 0.32),
              (x, FRONT - 0.06, 0.3), (x, FRONT - 0.22, 0.1)], 0.04, "metal")
    for z in (1.2, 2.1):
        cuboid(bm, (x, FRONT - 0.03, z), (0.1, 0.06, 0.025), "metal")
    cuboid(bm, (x, FRONT - 0.3, 0.025), (0.3, 0.45, 0.05), "concrete")


def stovepipe(bm):
    x, y, radius, height = STOVEPIPE
    surface = roof_line(y) + ROOF / math.cos(PITCH)
    top = surface + height
    tube(bm, (x, y, roof_line(y) - 0.05), (x, y, top), radius, "metal", 14)
    tube(bm, (x, y, surface - 0.02), (x, y, surface + 0.06), radius + 0.05, "metal", 14)
    tube(bm, (x, y, top), (x, y, top + 0.07), 0.02, "metal", 8)
    made = bmesh.ops.create_cone(bm, cap_ends=True, segments=14, radius1=radius + 0.08,
                                 radius2=0.012, depth=0.1,
                                 matrix=Matrix.Translation((x, y, top + 0.12)))
    rounded(made["verts"], "metal")


def vent(bm, facing):
    width, height, rise = VENT
    x = facing * (WIDTH / 2 + 0.02)
    centre = Vector((x, 0.0, EAVE + rise))
    cuboid(bm, centre - Vector((facing * 0.02, 0.0, 0.0)), (0.01, width, height), "metal")
    for z in (-1, 1):
        cuboid(bm, centre + Vector((0.0, 0.0, z * (height / 2 + 0.02))),
               (0.04, width + 0.08, 0.04), "trim")
    for y in (-1, 1):
        cuboid(bm, centre + Vector((0.0, y * (width / 2 + 0.02), 0.0)), (0.04, 0.04, height),
               "trim")
    turn = Matrix.Rotation(facing * math.radians(40.0), 3, "Y")
    for index in range(4):
        z = -height / 2 + (index + 0.5) * height / 4
        cuboid(bm, centre + Vector((0.0, 0.0, z)), (0.06, width, 0.012), "trim", turn)


def hood(bm):
    width, depth, height, fall = HOOD
    x = DOOR[0]
    top = FLOOR + height
    tilt = math.atan2(fall, depth)
    lift = ROOF / 2 / math.cos(tilt)
    cuboid(bm, (x, FRONT - depth / 2, top - fall / 2 + lift),
           (width, depth / math.cos(tilt), ROOF), "roof", Matrix.Rotation(tilt, 3, "X"))
    cuboid(bm, (x, FRONT - depth + 0.015, top - fall - 0.05), (width, 0.03, 0.1), "trim")
    cuboid(bm, (x, FRONT - 0.02, top + 0.03), (width + 0.06, 0.04, 0.08), "trim")
    for side in (-1, 1):
        across = x + side * (width / 2 - 0.12)
        beam(bm, (across, FRONT, top - 0.04), (across, FRONT - depth + 0.04, top - fall - 0.04),
             0.06, 0.08, "trim")
        beam(bm, (across, FRONT, top - 0.55),
             (across, FRONT - depth * 0.68, top - fall * 0.68 - 0.08), 0.05, 0.06, "trim")


def landing(bm):
    width, depth = LANDING
    x = DOOR[0]
    cuboid(bm, (x, FRONT - depth / 2, FLOOR - 0.025), (width, depth, 0.05), "deck")
    cuboid(bm, (x, FRONT - depth / 2 + 0.02, (FLOOR - 0.05) / 2),
           (width - 0.06, depth - 0.04, FLOOR - 0.05), "siding")
    cuboid(bm, (x, FRONT - depth - STEP / 2, FLOOR / 2 - 0.025), (1.0, STEP, 0.05), "deck")
    cuboid(bm, (x, FRONT - depth - STEP / 2 + 0.02, (FLOOR / 2 - 0.05) / 2),
           (0.96, STEP - 0.04, FLOOR / 2 - 0.05), "siding")


def door(bm):
    x, width, height = DOOR
    left, right = x - width / 2, x + width / 2
    face = FRONT + 0.0275
    cuboid(bm, (x, FRONT + 0.05, FLOOR + height / 2), (width - 0.02, 0.045, height - 0.02),
           "door")
    for edge in (left - 0.045, right + 0.045):
        cuboid(bm, (edge, FRONT - 0.02, FLOOR + height / 2 + 0.05), (0.09, 0.04, height + 0.1),
               "trim")
    cuboid(bm, (x, FRONT - 0.025, FLOOR + height + 0.06), (width + 0.26, 0.05, 0.12), "trim")
    cuboid(bm, (x, FRONT + 0.03, FLOOR + 0.01), (width, 0.12, 0.02), "metal")
    knob = Vector((right - 0.09, face, FLOOR + 1.0))
    cuboid(bm, knob + Vector((0.0, -0.005, 0.0)), (0.07, 0.01, 0.17), "metal")
    tube(bm, knob, knob + Vector((0.0, -0.065, 0.0)), 0.011, "metal", 8)
    tube(bm, knob + Vector((0.0, -0.055, 0.0)), knob + Vector((0.0, -0.085, 0.0)), 0.03, "metal")


def window(bm, centre, width, height, sill, face, side=False):
    def at(u, v, w):
        return Vector((face + w, u, v)) if side else Vector((u, face + w, v))

    def size(u, v, w):
        return (w, u, v) if side else (u, w, v)

    out = 1.0 if side else -1.0
    bottom, top = FLOOR + sill, FLOOR + sill + height
    middle = (bottom + top) / 2
    for u in (centre - width / 2 - 0.045, centre + width / 2 + 0.045):
        cuboid(bm, at(u, middle + 0.02, out * 0.02), size(0.09, height + 0.13, 0.04), "trim")
    cuboid(bm, at(centre, top + 0.06, out * 0.02), size(width + 0.26, 0.12, 0.04), "trim")
    cuboid(bm, at(centre, bottom - 0.025, out * 0.04), size(width + 0.26, 0.05, 0.1), "trim")
    for v in (bottom + 0.025, top - 0.025):
        cuboid(bm, at(centre, v, -out * 0.035), size(width, 0.05, 0.05), "trim")
    for u in (centre - width / 2 + 0.025, centre, centre + width / 2 - 0.025):
        cuboid(bm, at(u, middle, -out * 0.035), size(0.05, height, 0.05), "trim")
    cuboid(bm, at(centre, middle, -out * 0.065), size(width, height, 0.008), "glass")
    turn = Matrix.Rotation(math.radians(30.0), 3, "Y" if side else "X")
    for index in range(int((height - 0.08) / 0.05)):
        cuboid(bm, at(centre, bottom + 0.04 + index * 0.05, -out * 0.1),
               size(width - 0.05, 0.006, 0.045), "blinds", turn)
    cuboid(bm, at(centre, top - 0.03, -out * 0.1), size(width - 0.02, 0.04, 0.05), "blinds")
    cuboid(bm, at(centre, middle, -out * 0.3), size(width + 0.3, height + 0.3, 0.01),
           "window_glow")


def lettering(bm, words, size, centre):
    curve = bpy.data.curves.new("Lettering", "FONT")
    curve.body = words
    curve.size = size
    curve.extrude = 0.003
    curve.align_x = "CENTER"
    curve.align_y = "CENTER"
    holder = bpy.data.objects.new("Lettering", curve)
    mesh = bpy.data.meshes.new_from_object(holder)
    before = len(bm.faces)
    bm.from_mesh(mesh)
    bm.faces.ensure_lookup_table()
    added = [bm.faces[index] for index in range(before, len(bm.faces))]
    place = Matrix.Translation(centre) @ Matrix.Rotation(math.radians(90.0), 4, "X")
    bmesh.ops.transform(bm, matrix=place, verts=list(dict.fromkeys(
        vert for face in added for vert in face.verts)))
    for face in added:
        face.material_index = slot("letters")
        face.smooth = False
    bpy.data.meshes.remove(mesh)
    bpy.data.objects.remove(holder)
    bpy.data.curves.remove(curve)


def notice(bm):
    width, height, centre = BOARD
    cuboid(bm, (NOTICE, FRONT - 0.015, centre), (width, 0.03, height), "sign")
    lettering(bm, "OFFICE", 0.13, Vector((NOTICE, FRONT - 0.033, centre)))
    board = Vector((NOTICE, FRONT - 0.01, CLIPBOARD))
    cuboid(bm, board, (0.23, 0.012, 0.32), "clipboard")
    cuboid(bm, board + Vector((0.0, -0.007, -0.015)), (0.21, 0.002, 0.28), "paper")
    cuboid(bm, board + Vector((0.0, -0.012, 0.14)), (0.11, 0.012, 0.035), "metal")
    return board + Vector((0.0, -0.008, -0.015))


def gooseneck(bm):
    base = Vector((NOTICE, FRONT, LAMP))
    cuboid(bm, base + Vector((0.0, -0.01, 0.0)), (0.13, 0.02, 0.13), "metal")
    bends = [(0.0, -0.02, 0.0), (0.0, -0.13, 0.07), (0.0, -0.27, 0.09), (0.0, -0.38, 0.05),
             (0.0, -0.41, -0.01)]
    pipe(bm, [base + Vector(offset) for offset in bends], 0.014, "metal", 8)
    top = base + Vector(bends[-1])
    made = bmesh.ops.create_cone(bm, cap_ends=False, segments=20, radius1=0.17, radius2=0.035,
                                 depth=0.1, matrix=Matrix.Translation(top + Vector((0, 0, -0.05))))
    shade = rounded(made["verts"], "metal")
    for face in shade:
        face.normal_update()
    bmesh.ops.solidify(bm, geom=shade, thickness=0.006)
    tube(bm, top + Vector((0.0, 0.0, -0.01)), top + Vector((0.0, 0.0, 0.025)), 0.04, "metal")
    tube(bm, top + Vector((0.0, 0.0, -0.085)), top + Vector((0.0, 0.0, -0.025)), 0.038,
         "lamp_glow")
    return top + Vector((0.0, 0.0, -0.09))


def floodlight(bm):
    x, z, turn, tilt = FLOOD
    mount = Vector((x, FRONT, z))
    cuboid(bm, mount + Vector((0.0, -0.01, 0.0)), (0.1, 0.02, 0.16), "metal")
    cuboid(bm, mount + Vector((0.0, -0.08, 0.0)), (0.04, 0.12, 0.04), "metal")
    aim = Matrix.Rotation(turn, 3, "Z") @ Matrix.Rotation(tilt, 3, "X")
    head = mount + Vector((0.0, -0.14, 0.0)) + aim @ Vector((0.0, -0.06, 0.0))
    cuboid(bm, head, (0.34, 0.1, 0.26), "metal", aim)
    for fin in range(5):
        cuboid(bm, head + aim @ Vector((-0.12 + fin * 0.06, 0.065, 0.0)), (0.012, 0.03, 0.22),
               "metal", aim)
    lens = head + aim @ Vector((0.0, -0.052, 0.0))
    cuboid(bm, lens, (0.29, 0.006, 0.21), "lamp_glow", aim)
    return lens + aim @ Vector((0.0, -0.01, 0.0)), aim


def meter(bm):
    box = Vector((WIDTH / 2 + 0.07, FRONT + 0.6, 1.55))
    cuboid(bm, box, (0.14, 0.32, 0.46), "metal")
    cuboid(bm, box + Vector((0.071, 0.0, 0.08)), (0.004, 0.16, 0.16), "glass")
    tube(bm, box + Vector((0.0, 0.0, 0.23)), Vector((box.x, box.y, EAVE - 0.02)), 0.016,
         "metal", 8)


def uvs(bm):
    layer = bm.loops.layers.uv.verify()
    door_left = DOOR[0] - DOOR[1] / 2
    for face in bm.faces:
        name = SLOTS[face.material_index]
        axis = max(range(3), key=lambda index: abs(face.normal[index]))
        for loop in face.loops:
            x, y, z = loop.vert.co
            if axis == 2:
                uv = (y, x) if name == "deck" else (x, y)
            elif axis == 1:
                uv = (x, z)
            else:
                uv = (y, z)
            if name == "door":
                uv = (uv[0] - door_left, uv[1] - FLOOR)
            loop[layer].uv = uv


def materials(mesh):
    for name in SLOTS:
        material = bpy.data.materials.new(name)
        material.use_nodes = True
        shader = next(node for node in material.node_tree.nodes
                      if node.type == "BSDF_PRINCIPLED")
        if name in PREVIEW:
            textured(material, shader, *PREVIEW[name])
        else:
            shader.inputs["Base Color"].default_value = (*COLOURS[name], 1.0)
            shader.inputs["Roughness"].default_value = 0.6
            if name in ("window_glow", "lamp_glow"):
                shader.inputs["Emission Color"].default_value = (*COLOURS[name], 1.0)
                shader.inputs["Emission Strength"].default_value = 3.0
        mesh.materials.append(material)


def textured(material, shader, asset, resolution, tile):
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    coords = nodes.new("ShaderNodeTexCoord")
    mapping = nodes.new("ShaderNodeMapping")
    mapping.inputs["Scale"].default_value = (1.0 / tile, 1.0 / tile, 1.0)
    links.new(coords.outputs["UV"], mapping.inputs["Vector"])
    images = {}
    for kind in ("diff", "arm", "nor_gl"):
        node = nodes.new("ShaderNodeTexImage")
        path = TEXTURES / asset / f"{asset}_{kind}_{resolution}.jpg"
        node.image = bpy.data.images.load(str(path), check_existing=True)
        if kind != "diff":
            node.image.colorspace_settings.name = "Non-Color"
        links.new(mapping.outputs["Vector"], node.inputs["Vector"])
        images[kind] = node
    links.new(images["diff"].outputs["Color"], shader.inputs["Base Color"])
    split = nodes.new("ShaderNodeSeparateColor")
    links.new(images["arm"].outputs["Color"], split.inputs["Color"])
    links.new(split.outputs["Green"], shader.inputs["Roughness"])
    links.new(split.outputs["Blue"], shader.inputs["Metallic"])
    normal = nodes.new("ShaderNodeNormalMap")
    links.new(images["nor_gl"].outputs["Color"], normal.inputs["Color"])
    links.new(normal.outputs["Normal"], shader.inputs["Normal"])


def marker(scene, name, at, beam_direction=None):
    empty = bpy.data.objects.new(name, None)
    empty.empty_display_size = 0.15
    turn = Matrix.Identity(4)
    if beam_direction is not None:
        turn = Vector(beam_direction).to_track_quat("Y", "Z").to_matrix().to_4x4()
    empty.matrix_world = Matrix.Translation(at) @ turn
    scene.collection.objects.link(empty)
    return empty


def solid(scene, name, centre, size):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=size, verts=bm.verts)
    bmesh.ops.translate(bm, vec=centre, verts=bm.verts)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    box = bpy.data.objects.new(name + "-convcolonly", mesh)
    box.display_type = "WIRE"
    box.hide_render = True
    scene.collection.objects.link(box)
    return box


def build(scene):
    bm = bmesh.new()
    walls(bm)
    roof(bm)
    stovepipe(bm)
    for facing in (-1, 1):
        vent(bm, facing)
    hood(bm)
    landing(bm)
    door(bm)
    window(bm, WINDOW[0], WINDOW[1], WINDOW[2], WINDOW[3], FRONT)
    window(bm, SIDE_WINDOW[0], SIDE_WINDOW[1], SIDE_WINDOW[2], SIDE_WINDOW[3], WIDTH / 2,
           side=True)
    sheet = notice(bm)
    lamp = gooseneck(bm)
    lens, aim = floodlight(bm)
    meter(bm)
    bmesh.ops.delete(bm, geom=[vert for vert in bm.verts if not vert.link_faces],
                     context="VERTS")
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    ordered = sorted(bm.faces, key=lambda face: (
        face.material_index, sorted(tuple(round(value, 5) for value in vert.co)
                                    for vert in face.verts)))
    for rank, face in enumerate(ordered):
        face.index = rank
    bm.faces.sort()
    uvs(bm)
    mesh = bpy.data.meshes.new("SiteOffice")
    bm.to_mesh(mesh)
    bm.free()
    materials(mesh)
    office = bpy.data.objects.new("SiteOffice", mesh)
    scene.collection.objects.link(office)
    window_light = Vector((WINDOW[0], FRONT - 0.45, FLOOR + WINDOW[3] + WINDOW[2] / 2))
    landing_depth = LANDING[1] + STEP
    return [office,
            marker(scene, "RunSheet", sheet),
            marker(scene, "NoticeLamp", lamp, LAMP_AIM),
            marker(scene, "Floodlight", lens, aim @ Vector((0.0, -1.0, 0.0))),
            marker(scene, "WindowLight", window_light),
            solid(scene, "Building", (0.0, 0.0, EAVE / 2), (WIDTH, DEPTH, EAVE)),
            solid(scene, "Landing", (DOOR[0], FRONT - landing_depth / 2, FLOOR / 2),
                  (LANDING[0], landing_depth, FLOOR))]


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
