"""Build the transfer shed's selective pallet racking parts (#267) as a glTF file for Godot.

Teardrop racking as the author's photo of a warehouse aisle shows it, at its makers' sizes
(Interlake Mecalux's selective rack guide; SJF's pallet rack guides):

- `RackFrame`: an upright frame 20 ft (6.096 m) tall and 42 in (1.067 m) deep for 48 in pallets,
  two 3 x 3 in (76.2 mm) posts in slate grey-green, their faces punched with teardrop slots on a
  2 in step (`upright_face.png`, each showing the channel's dark inside), a base plate and two anchors under each, and the
  bracing between them: horizontals at the foot and the top and diagonals zig-zagging between,
  1.5 x 1.25 in channel. The frame stands across local z, its posts at z = +-(0.5335 - 0.0381).
- `RackBeam`: a step beam 96 in (2.438 m) clear, 4 in (101.6 mm) tall and 1.62 in (41 mm) deep,
  in the photo's yellow-orange, with its 5/8 in step along the top of its inner face for the
  decks, and a connector plate at each end. Along local x, from 0 to its length; its outer face
  at local z = 0, the bay behind it at -z.
- `RackDeck`: a wire mesh deck 42 x 46 in (1.067 x 1.168 m), two to a bay, its mesh on three
  channel supports and its front and back flared down over the beams (waterfall).
- `PostGuard`: a safety-yellow post protector, a 0.45 m tall U of 6 mm plate round a post's
  foot, on its own base plate.
- `RowEndGuardSingle`, `RowEndGuardDouble`: the yellow guard across a row's end, a 0.3 m tall
  angle 0.15 m out from the frames, with 0.3 m returns, for a single row (1.067 m) and a
  back-to-back row (2.286 m: two frames and a 6 in flue).
- `RowSpacer`: the 6 in (152 mm) spacer bolted between back-to-back frames.
- `AisleSign01` to `AisleSign06`: navy aisle boards 0.25 x 0.36 m with white numerals, as the
  photo's "03", each mapped to its cell of `aisle_signs.png`.
- `BayLabelA` to `BayLabelD`: location labels 0.1 x 0.0375 m, each its cell of `bay_labels.png`.

And the stock that stands in it, light enough for 616 places:

- `RackPallet`: a GMA 48 x 40 in pallet (1.219 x 1.016 x 0.146 m), 48 in along local z: seven
  top boards and five bottom boards 5/8 in thick on three 1.5 x 3.5 in stringers, in the
  depot pallet's wood (`art/depot/pallet_palette_mat_diffuse.jpg`).
- `BoardBundle060`, `BoardBundle090`, `BoardBundle110`: bundles of flat corrugated board 0.60,
  0.90 and 1.10 m tall, 1.25 x 1.04 m, overhanging the pallet a little as the photo's do, their
  sheets' edges (`board_edge.png`) and top sheet (`board_top.png`), two white straps round them.
- `CartonStack3`, `CartonStack2`: cartons 0.5 x 0.4 x 0.34 m, two by three a layer, three or two
  layers high (1.02 or 0.68 m), each face showing one carton (`carton_face.png`), and their
  `Wrap3`, `Wrap2`: stretch film round the sides, translucent.

Each object's origin is where the game places it: a frame's at its foot's middle, a beam's at
its left end's lower outer edge, a deck's at its middle underside, guards at their foot. Coordinates
below are Godot's (x across, y up, z back); g() turns them into Blender's.

Usage, from the repository root:
    /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup \\
        --python-exit-code 1 --python tools/art/build_racking.py
"""

import math
import pathlib

import bmesh
import bpy
from mathutils import Matrix, Vector

ROOT = pathlib.Path(__file__).resolve().parents[2]
ART = ROOT / "game/features/environments/industrial_loop/art/racking"
OUT = ART / "racking.glb"

INCH = 0.0254
FRAME = {"height": 240 * INCH, "depth": 42 * INCH, "post": 3 * INCH}
BRACE = {"wide": 1.5 * INCH, "deep": 1.25 * INCH, "foot": 0.15, "panels": 5}
BASE = {"x": 4 * INCH, "z": 6 * INCH, "thick": 0.006}
BEAM = {"length": 96 * INCH, "tall": 4 * INCH, "deep": 0.041, "step": 0.016,
        "plate_tall": 0.165, "plate_wide": 0.065, "plate_thick": 0.004}
DECK = {"depth": 42 * INCH, "width": 46 * INCH, "wire": 0.004, "channel": 0.038, "flare": 0.03}
GUARD = {"tall": 0.45, "plate": 0.006, "around": 0.012}
END_GUARD = {"tall": 0.3, "out": 0.15, "returns": 0.3, "plate": 0.008}
FLUE = 6 * INCH
SIGN = (0.25, 0.36, 0.006)
LABEL = (0.1, 0.0375)
PALLET = {"long": 48 * INCH, "wide": 40 * INCH, "board": 0.016, "stringer": (1.5 * INCH,
          3.5 * INCH), "top_boards": 7, "bottom_boards": 5, "board_wide": 5.5 * INCH}
BUNDLE = {"long": 1.25, "wide": 1.04, "tall": (0.60, 0.90, 1.10), "strap": 0.012}
CARTON = {"wide": 0.5, "deep": 0.4, "tall": 0.34, "across": 2, "along": 3}
WRAP_OUT = 0.006
UPRIGHT_TILE = (FRAME["post"], 2 * INCH)
DECK_TILE = (2.5 * INCH, 4 * INCH)
PAINT = {"upright": ((0.27, 0.31, 0.28), 0.3, 0.55), "beam": ((0.83, 0.66, 0.26), 0.2, 0.45),
         "zinc": ((0.62, 0.64, 0.63), 0.8, 0.42), "guard": ((0.95, 0.76, 0.06), 0.1, 0.5),
         "bolt": ((0.55, 0.56, 0.56), 0.9, 0.35)}


def g(x, y, z):
    return Vector((x, -z, y))


def linear(value):
    return value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4


def material(name, colour, metallic, roughness, image=None, alpha=False):
    """A painted or textured finish; with `alpha`, its texture's alpha cuts holes (glTF's MASK,
    which Blender's exporter writes for an alpha rounded to 0 or 1)."""
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
        if alpha:
            cut = tree.nodes.new("ShaderNodeMath")
            cut.operation = "ROUND"
            tree.links.new(texture.outputs["Alpha"], cut.inputs[0])
            tree.links.new(cut.outputs[0], shader.inputs["Alpha"])
    made.use_backface_culling = True
    return made


def box(bm, low, high, uv=None):
    """A box between two Godot corners; `uv` (u metres, v metres) tiles its faces by size."""
    low, high = Vector(low), Vector(high)
    made = bmesh.ops.create_cube(bm, size=1.0)
    verts = made["verts"]
    size = high - low
    bmesh.ops.scale(bm, vec=Vector((size.x, size.z, size.y)), verts=verts)
    bmesh.ops.translate(bm, vec=g(*((low + high) / 2.0)), verts=verts)
    faces = list({f for v in verts for f in v.link_faces})
    if uv is not None:
        tile_uvs(bm, faces, uv)
    return faces


def tile_uvs(bm, faces, tile):
    layer = bm.loops.layers.uv.verify()
    bm.normal_update()
    for face in faces:
        n = face.normal
        axis = max(range(3), key=lambda i: abs(n[i]))
        if axis == 2:
            u_axis, v_axis = 0, 1
        else:
            u_axis, v_axis = (1 if axis == 0 else 0), 2
        for loop in face.loops:
            co = loop.vert.co
            loop[layer].uv = (co[u_axis] / tile[0], co[v_axis] / tile[1])


def bar(bm, a, b, wide, deep):
    """A channel from `a` to `b` in Godot's yz plane (a brace), `wide` across x, `deep` across."""
    start, end = g(*a), g(*b)
    length = (end - start).length
    made = bmesh.ops.create_cube(bm, size=1.0)
    verts = made["verts"]
    bmesh.ops.scale(bm, vec=Vector((wide, deep, length)), verts=verts)
    direction = (end - start).normalized()
    rotation = Vector((0.0, 0.0, 1.0)).rotation_difference(direction).to_matrix()
    bmesh.ops.rotate(bm, cent=Vector(), matrix=rotation, verts=verts)
    bmesh.ops.translate(bm, vec=(start + end) / 2.0, verts=verts)


def cylinder(bm, centre, radius, length, segments=12):
    made = bmesh.ops.create_cone(bm, cap_ends=True, segments=segments, radius1=radius,
                                 radius2=radius, depth=length)
    bmesh.ops.translate(bm, vec=g(*centre), verts=made["verts"])


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


def frame(mats):
    """Two posts, their base plates and anchors, and the bracing between them."""
    bm = bmesh.new()
    half = FRAME["post"] / 2.0
    post_z = FRAME["depth"] / 2.0 - half
    post_faces = []
    for side in (-1.0, 1.0):
        z = side * post_z
        post_faces += box(bm, (-half, BASE["thick"], z - half), (half, FRAME["height"], z + half),
                          UPRIGHT_TILE)
    count_posts = len(bm.faces)
    for side in (-1.0, 1.0):
        z = side * post_z
        box(bm, (-BASE["x"] / 2.0, 0.0, z - BASE["z"] / 2.0),
            (BASE["x"] / 2.0, BASE["thick"], z + BASE["z"] / 2.0))
        for dz in (-1.0, 1.0):
            cylinder(bm, (0.0, BASE["thick"] + 0.006, z + dz * (BASE["z"] / 2.0 - 0.018)), 0.009,
                     0.012)
    inner = post_z - half
    heights = [BRACE["foot"]]
    top = FRAME["height"] - BRACE["foot"]
    for panel in range(1, BRACE["panels"] + 1):
        heights.append(BRACE["foot"] + (top - BRACE["foot"]) * panel / BRACE["panels"])
    for y in (heights[0], heights[-1]):
        bar(bm, (0.0, y, -inner), (0.0, y, inner), BRACE["wide"], BRACE["deep"])
    for index in range(BRACE["panels"]):
        a, b = heights[index], heights[index + 1]
        z0, z1 = (-inner, inner) if index % 2 == 0 else (inner, -inner)
        bar(bm, (0.0, a, z0), (0.0, b, z1), BRACE["wide"], BRACE["deep"])
    slots = [0] * count_posts + [1] * (len(bm.faces) - count_posts)
    return finish("RackFrame", bm, [mats["upright_face"], mats["upright"]], slots)


def beam(mats):
    bm = bmesh.new()
    length, tall, deep, step = BEAM["length"], BEAM["tall"], BEAM["deep"], BEAM["step"]
    box(bm, (0.0, 0.0, -deep), (length, tall - step, 0.0))
    box(bm, (0.0, tall - step, -deep + step), (length, tall, 0.0))
    count = len(bm.faces)
    for x0, x1 in ((-BEAM["plate_thick"], 0.0), (length, length + BEAM["plate_thick"])):
        box(bm, (x0, tall - BEAM["plate_tall"] + 0.03, -BEAM["plate_wide"]), (x1, tall + 0.03,
            0.0))
    slots = [0] * count + [1] * (len(bm.faces) - count)
    return finish("RackBeam", bm, [mats["beam"], mats["beam_plate"]], slots)


def deck(mats):
    bm = bmesh.new()
    depth, width, wire = DECK["depth"], DECK["width"], DECK["wire"]
    mesh_faces = box(bm, (-width / 2.0, 0.0, -depth / 2.0), (width / 2.0, wire, depth / 2.0),
                     DECK_TILE)
    count = len(bm.faces)
    for x in (-width / 2.0 + 0.05, 0.0, width / 2.0 - 0.05):
        box(bm, (x - 0.019, -DECK["channel"], -depth / 2.0), (x + 0.019, 0.0, depth / 2.0))
    for side in (-1.0, 1.0):
        z = side * (depth / 2.0)
        box(bm, (-width / 2.0, -DECK["flare"], min(z, z + side * wire)),
            (width / 2.0, 0.0, max(z, z + side * wire)))
    slots = [0] * count + [1] * (len(bm.faces) - count)
    return finish("RackDeck", bm, [mats["deck"], mats["zinc"]], slots)


def post_guard(mats):
    bm = bmesh.new()
    half = FRAME["post"] / 2.0 + GUARD["around"]
    plate, tall = GUARD["plate"], GUARD["tall"]
    box(bm, (-half - plate, 0.0, half), (half + plate, tall, half + plate))
    for side in (-1.0, 1.0):
        x = side * (half + plate / 2.0)
        box(bm, (x - plate / 2.0, 0.0, -half), (x + plate / 2.0, tall, half))
    box(bm, (-half - 0.03, 0.0, -half - 0.02), (half + 0.03, plate, half + 0.04))
    return finish("PostGuard", bm, [mats["guard"]])


def end_guard(mats, name, row_depth):
    bm = bmesh.new()
    out, tall, plate, returns = END_GUARD["out"], END_GUARD["tall"], END_GUARD["plate"], \
        END_GUARD["returns"]
    half = row_depth / 2.0 + out
    box(bm, (-half, 0.0, out - plate), (half, tall, out))
    box(bm, (-half, 0.0, out - 0.08), (half, plate, out))
    for side in (-1.0, 1.0):
        x = side * half
        box(bm, (min(x, x - side * plate), 0.0, out - returns), (max(x, x - side * plate), tall,
            out))
    return finish(name, bm, [mats["guard"]])


def spacer(mats):
    bm = bmesh.new()
    box(bm, (-0.019, -0.019, -FLUE / 2.0), (0.019, 0.019, FLUE / 2.0))
    return finish("RowSpacer", bm, [mats["upright"]])


def plate_with_cell(mats, name, size, cells, index, material_key):
    """A thin board facing +z whose front shows cell `index` of `cells` across its texture."""
    bm = bmesh.new()
    w, h, t = size
    faces = box(bm, (-w / 2.0, -h / 2.0, -t), (w / 2.0, h / 2.0, 0.0))
    layer = bm.loops.layers.uv.verify()
    bm.normal_update()
    for face in faces:
        front = face.normal.y < -0.9
        for loop in face.loops:
            co = loop.vert.co
            u = (co.x + w / 2.0) / w
            v = (co.z + h / 2.0) / h
            loop[layer].uv = ((index + u) / cells, v) if front else (index / cells + 0.001, 0.5)
    return finish(name, bm, [mats[material_key]])


def pallet(mats):
    bm = bmesh.new()
    long, wide, board = PALLET["long"], PALLET["wide"], PALLET["board"]
    s_wide, s_tall = PALLET["stringer"]
    bottom = board
    for x in (-wide / 2.0 + s_wide / 2.0, 0.0, wide / 2.0 - s_wide / 2.0):
        box(bm, (x - s_wide / 2.0, bottom, -long / 2.0), (x + s_wide / 2.0, bottom + s_tall,
            long / 2.0), (0.3, 0.3))
    top = bottom + s_tall
    for count, y0 in ((PALLET["top_boards"], top), (PALLET["bottom_boards"], 0.0)):
        gap = (long - count * PALLET["board_wide"]) / (count - 1)
        for index in range(count):
            z0 = -long / 2.0 + index * (PALLET["board_wide"] + gap)
            box(bm, (-wide / 2.0, y0, z0), (wide / 2.0, y0 + board, z0 + PALLET["board_wide"]),
                (0.3, 0.3))
    return finish("RackPallet", bm, [mats["pallet"]])


def bundle(mats, tall):
    bm = bmesh.new()
    long, wide = BUNDLE["long"], BUNDLE["wide"]
    faces = box(bm, (-wide / 2.0, 0.0, -long / 2.0), (wide / 2.0, tall, long / 2.0))
    layer = bm.loops.layers.uv.verify()
    bm.normal_update()
    slots = []
    for face in faces:
        n = face.normal
        top = abs(n.z) > 0.9
        for loop in face.loops:
            co = loop.vert.co
            if top:
                loop[layer].uv = (co.x / 1.0, co.y / 1.0)
            else:
                along = co.x if abs(n.y) > 0.9 else co.y
                loop[layer].uv = (along / 0.4, co.z / 0.1)
        slots.append(1 if top else 0)
    count = len(bm.faces)
    for z in (-long * 0.3, long * 0.3):
        box(bm, (-wide / 2.0 - 0.002, -0.002, z - BUNDLE["strap"] / 2.0),
            (wide / 2.0 + 0.002, tall + 0.002, z + BUNDLE["strap"] / 2.0))
    slots += [2] * (len(bm.faces) - count)
    return finish("BoardBundle%03d" % round(tall * 100), bm, [mats["board_edge"],
                  mats["board_top"], mats["strap"]], slots)


def cartons(mats, layers):
    bm = bmesh.new()
    wide = CARTON["wide"] * CARTON["across"]
    long = CARTON["deep"] * CARTON["along"]
    tall = CARTON["tall"] * layers
    faces = box(bm, (-wide / 2.0, 0.0, -long / 2.0), (wide / 2.0, tall, long / 2.0))
    layer = bm.loops.layers.uv.verify()
    bm.normal_update()
    slots = []
    for face in faces:
        n = face.normal
        top = abs(n.z) > 0.9
        for loop in face.loops:
            co = loop.vert.co
            if top:
                loop[layer].uv = (co.x / 1.0, co.y / 1.0)
            elif abs(n.x) > 0.9:
                loop[layer].uv = (co.y / CARTON["deep"], co.z / CARTON["tall"])
            else:
                loop[layer].uv = (co.x / CARTON["wide"], co.z / CARTON["tall"])
        slots.append(1 if top else 0)
    stack = finish("CartonStack%d" % layers, bm, [mats["carton"], mats["board_top"]], slots)
    film = bmesh.new()
    sides = box(film, (-wide / 2.0 - WRAP_OUT, 0.02, -long / 2.0 - WRAP_OUT),
                (wide / 2.0 + WRAP_OUT, tall - 0.03, long / 2.0 + WRAP_OUT))
    bmesh.ops.delete(film, geom=[f for f in sides if abs(f.normal.z) > 0.9], context="FACES")
    wrap = finish("Wrap%d" % layers, film, [mats["wrap"]])
    return [stack, wrap]


def export(objects):
    for obj in list(bpy.context.scene.objects):
        obj.select_set(obj in objects)
    bpy.ops.export_scene.gltf(filepath=str(OUT), export_format="GLB", use_selection=True,
                              use_active_scene=True, export_apply=True, export_yup=True,
                              export_image_format="AUTO")
    for obj in objects:
        print(f"  {obj.name}: {len(obj.data.polygons)} faces")
    print(f"Wrote {OUT}")


def main():
    for obj in list(bpy.context.scene.objects):
        bpy.data.objects.remove(obj)
    mats = {key: material(key, *PAINT[key]) for key in PAINT}
    mats["upright_face"] = material("upright_face", (1, 1, 1), 0.3, 0.55, "upright_face.png")
    mats["beam_plate"] = material("beam_plate", tuple(min(1.0, c * 1.08) for c in
                                  PAINT["beam"][0]), 0.2, 0.4)
    mats["deck"] = material("deck", (1, 1, 1), 0.8, 0.42, "wire_deck.png", True)
    mats["sign"] = material("sign", (1, 1, 1), 0.0, 0.6, "aisle_signs.png")
    mats["label"] = material("label", (1, 1, 1), 0.0, 0.7, "bay_labels.png")
    mats["pallet"] = material("pallet", (1, 1, 1), 0.0, 0.85,
                              "../depot/pallet_palette_mat_diffuse.jpg")
    mats["board_edge"] = material("board_edge", (1, 1, 1), 0.0, 0.9, "board_edge.png")
    mats["board_top"] = material("board_top", (1, 1, 1), 0.0, 0.9, "board_top.png")
    mats["carton"] = material("carton", (1, 1, 1), 0.0, 0.88, "carton_face.png")
    mats["strap"] = material("strap", (0.92, 0.92, 0.9), 0.0, 0.5)
    mats["wrap"] = material("wrap", (0.9, 0.93, 0.95), 0.0, 0.15)
    shader = next(n for n in mats["wrap"].node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    shader.inputs["Alpha"].default_value = 0.11
    mats["wrap"].use_backface_culling = False
    parts = [frame(mats), beam(mats), deck(mats), post_guard(mats), pallet(mats)]
    parts += [bundle(mats, tall) for tall in BUNDLE["tall"]]
    parts += cartons(mats, 3) + cartons(mats, 2)
    parts += [
             end_guard(mats, "RowEndGuardSingle", FRAME["depth"]),
             end_guard(mats, "RowEndGuardDouble", FRAME["depth"] * 2.0 + FLUE), spacer(mats)]
    for index in range(6):
        parts.append(plate_with_cell(mats, "AisleSign%02d" % (index + 1), SIGN, 6, index, "sign"))
    for index in range(4):
        parts.append(plate_with_cell(mats, "BayLabel" + "ABCD"[index], LABEL + (0.001,), 4, index,
                                     "label"))
    export(parts)


if __name__ == "__main__":
    main()
