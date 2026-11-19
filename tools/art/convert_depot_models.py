"""Makes the bigger depot's game files from the models in source_assets/sketchfab (CC BY 4.0)
and one of Poly Haven's (CC0).

dock_door: Maxwell autodoors' Industrial Overhead Door, its panel alone (the red wall, the trim and
    the overhead tracks and springs above 2.35 m removed), scaled to the 2.74 x 3.05 m opening.
dock_seal: Maxwell autodoors' Foam Pad Dock Seal, its gap widened to 2.80 m and its side pads
    3.25 m tall, its back at the origin so it mounts on the wall's face.
dock_leveller: Maxwell autodoors' DLHH Electrohydraulic Dock Leveler, its deck 2.13 x 2.44 m
    (7 x 8 ft) with the top of the deck at the origin and its lip facing out.
forklift: Kamran Mughal's Warehouse Forklift, its forks toward +Z, its specular map left out, its
carriage (forks, plate and load backrest) cut from the truck to ride up its mast (#302); and
(the audit's second fix, #323) its steering wheel with its knob, its two drive wheels, its two
steer wheels and its mast cut free, each with its origin at its own pivot, the carriage riding
the mast.
pallet_jack: FFeller's Pallet Jack, its handle toward +Z and its forks toward -Z, cut as a real
    one moves (step 2f, #243): its frame (Chassis); its steering unit, the pump, turning on the
    pump's vertical axis 0.689 m behind the middle (Steering); and its handle, the shaft, loop
    and lever, hinged inside the steering unit at the shaft's foot, 0.30 m up, tilting toward
    whoever holds it (Tiller); and (the audit's third fix, #326) its twin steer wheels on their
    axle in the steering unit (SteerWheels), and in the frame each fork's two load rollers on
    their axles (RollerL1, RollerL2, RollerR1, RollerR2) and the bogie that holds them, turning
    about their middle (BogieL, BogieR).
pallet: widthRider's photoscanned Euro pallet sized as the American 48 x 40 in pallet (1.219 m
    along Z, 1.016 m across, 0.15 m tall), reduced to about 3,000 triangles, its dry wood matte
    (its roughness came from its specular map).
office_chair: Red Fox's (nokillnando) Office Chair, a fabric task chair on a five-star base with
    castors, for bay 9's dock worker at his desk (#265), its seat at 0.47 m (the middle of a task
    chair's 0.41-0.52 m), its front toward +Z, its origin on the floor under its gas lift, as its
    source was centred.
carton: Poly Haven's Cardboard Box 01 (CC0, the depot yard's copy) reduced to about 400
    triangles, its textures halved to 512 pixels, for the cartons on the staged pallets.
Each model stands with its base at the origin; the door, seal and leveller face +Z in Godot;
textures larger than 1024 pixels are halved until they fit, and the four props' are saved as JPEG.

Usage, from the repository root:
    /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python-exit-code 1 \\
        --python tools/art/convert_depot_models.py -- dock_door dock_seal dock_leveller forklift \\
        pallet_jack pallet carton office_chair
"""

import pathlib
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

ROOT = pathlib.Path.cwd()
SOURCE = ROOT / "source_assets/sketchfab"
TARGET = ROOT / "game/features/environments/industrial_loop/art/depot"
CARTON = ROOT / ("game/features/environments/depot_yard/polyhaven/models/cardboard_box_01/"
                 "cardboard_box_01.gltf")
HARDWARE = 2.35
OPENING = (2.74, 3.05)
SEAL_GAP = 2.80
SEAL_SIDE = 3.25
LEVELLER = (2.13, 2.44)
SLIM_ABOVE = 5500
SLIM_TO = 5000
LARGEST = 1024
PALLET = (1.016, 1.219, 0.15)
PALLET_TO = 3000
CARTON_TO = 400
CARTON_LARGEST = 512
UNUSED = ("Specular IOR Level", "Specular Tint")
WOOD_ROUGHNESS = 0.85
STEER_AXIS = 0.689
STEER_HALF = 0.07
STEER_FROM = 0.52
TILLER_FOOT = (0.30, 0.76)
TILLER_FROM = 0.32
TILLER_BACK = 0.739
TILLER_HALF = 0.2
STEER_HUB = (0.1055, 0.6885)
ROLLER_HUBS = {"1": (0.073, -0.5715), "2": (0.073, -0.455)}
ROLLERS_MIDDLE = (0.073, -0.5135)
FORK_MIDDLE = 0.2575
ON_HUB = 0.006
BOGIE_ACROSS = (0.15, 0.37)
BOGIE_ALONG = (-0.63, -0.285)
BOGIE_TOP = 0.105


def load(name: str, path: pathlib.Path | None = None) -> list:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(path or SOURCE / name / (name + ".glb")))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    for obj in bpy.context.scene.objects:
        obj.select_set(obj in meshes)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.make_single_user(object=True, obdata=True)
    bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    for obj in list(bpy.context.scene.objects):
        if obj.type != "MESH":
            bpy.data.objects.remove(obj)
    return meshes


def material(obj) -> str:
    slot = obj.material_slots[0] if obj.material_slots else None
    return slot.material.name if slot and slot.material else ""


def drop(meshes: list, prefixes: tuple) -> None:
    for obj in [obj for obj in meshes if material(obj).startswith(prefixes)]:
        meshes.remove(obj)
        bpy.data.objects.remove(obj)


def bounds(objects: list) -> tuple:
    points = [vertex.co for obj in objects for vertex in obj.data.vertices]
    low = [min(point[axis] for point in points) for axis in range(3)]
    high = [max(point[axis] for point in points) for axis in range(3)]
    return low, high


def place(meshes: list, origin: tuple, scale: tuple) -> None:
    for obj in meshes:
        for vertex in obj.data.vertices:
            for axis in range(3):
                vertex.co[axis] = (vertex.co[axis] - origin[axis]) * scale[axis]


def fit(meshes: list, origin: tuple, scale: tuple) -> None:
    for obj in bpy.context.scene.objects:
        obj.select_set(obj in meshes)
    for obj in meshes:
        obj.scale = scale
        obj.location = tuple(-origin[axis] * scale[axis] for axis in range(3))
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.transform_apply(location=True, rotation=False, scale=True)


def standing(meshes: list, size: tuple | None = None) -> None:
    low, high = bounds(meshes)
    scale = (1.0, 1.0, 1.0) if size is None else tuple(size[axis] / (high[axis] - low[axis])
                                                        for axis in range(3))
    fit(meshes, ((low[0] + high[0]) / 2.0, (low[1] + high[1]) / 2.0, low[2]), scale)


def plain(meshes: list) -> None:
    for obj in meshes:
        for slot in obj.material_slots:
            tree = slot.material.node_tree if slot.material else None
            if tree is None:
                continue
            for link in [link for link in tree.links if link.to_socket.name in UNUSED]:
                tree.links.remove(link)
            loose = True
            while loose:
                loose = [node for node in tree.nodes if node.type in ("TEX_IMAGE", "MATH", "MIX")
                         and not any(output.is_linked for output in node.outputs)]
                for node in loose:
                    tree.nodes.remove(node)
    for image in [image for image in bpy.data.images if image.users == 0]:
        bpy.data.images.remove(image)


def matte(meshes: list, roughness: float) -> None:
    for obj in meshes:
        for slot in obj.material_slots:
            tree = slot.material.node_tree
            shader = next(node for node in tree.nodes if node.type == "BSDF_PRINCIPLED")
            for name, value in (("Metallic", 0.0), ("Roughness", roughness)):
                for link in list(shader.inputs[name].links):
                    tree.links.remove(link)
                shader.inputs[name].default_value = value
    plain(meshes)


def rename(old: str, new: str) -> None:
    for item in bpy.data.materials:
        item.name = item.name.replace(old, new)
    for image in bpy.data.images:
        if image.filepath_raw and not image.packed_file:
            image.pack()
        image.filepath_raw = image.filepath_raw.replace(old, new)
        image.name = image.name.replace(old, new)


def triangles(objects: list) -> int:
    total = 0
    for obj in objects:
        obj.data.calc_loop_triangles()
        total += len(obj.data.loop_triangles)
    return total


def slim(meshes: list, heavy: list, above: int = SLIM_ABOVE, target: int = SLIM_TO) -> None:
    for kind in ("DISSOLVE", "COLLAPSE"):
        count = triangles(meshes)
        if count <= above:
            return
        others = count - triangles(heavy)
        for obj in heavy:
            modifier = obj.modifiers.new("Slim", "DECIMATE")
            modifier.decimate_type = kind
            if kind == "DISSOLVE":
                modifier.angle_limit = 0.01
            else:
                modifier.ratio = max(0.01, (target - others) / triangles(heavy))
            bpy.context.view_layer.objects.active = obj
            bpy.ops.object.modifier_apply(modifier=modifier.name)


def shrink_images(largest: int = LARGEST) -> None:
    for image in bpy.data.images:
        width, height = image.size
        while max(width, height) > largest:
            width, height = max(1, width // 2), max(1, height // 2)
        if (width, height) != tuple(image.size):
            image.scale(width, height)


def finish(meshes: list, name: str, node: str, images: str = "AUTO",
           largest: int = LARGEST) -> None:
    shrink_images(largest)
    for obj in bpy.context.scene.objects:
        obj.select_set(obj in meshes)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.convert(target="MESH")
    bpy.ops.object.join()
    model = bpy.context.view_layer.objects.active
    model.name = node
    low, high = bounds([model])
    TARGET.mkdir(parents=True, exist_ok=True)
    path = TARGET / (name + ".glb")
    bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLB", use_selection=True,
                              use_active_scene=True, export_apply=True, export_yup=True,
                              export_cameras=False, export_lights=False,
                              export_image_format=images, export_jpeg_quality=90)
    sizes = sorted({tuple(image.size) for image in bpy.data.images if image.size[0] > 0})
    print("CONVERTED %s: %d triangles, %.2f x %.2f x %.2f m, %d materials, images %s, %.1f kB" % (
        name, triangles([model]), high[0] - low[0], high[1] - low[1], high[2] - low[2],
        len(model.material_slots), sizes, path.stat().st_size / 1e3))


def dock_door() -> None:
    meshes = load("01_door_maxwell")
    drop(meshes, ("lambert5", "lambert6", "lambert1"))
    panels = [obj for obj in meshes if material(obj).startswith("lambert2")]
    for obj in panels:
        mesh = bmesh.new()
        mesh.from_mesh(obj.data)
        bmesh.ops.delete(mesh, geom=[vertex for vertex in mesh.verts if vertex.co.z > HARDWARE],
                         context="VERTS")
        mesh.to_mesh(obj.data)
        mesh.free()
    low, high = bounds(panels)
    place(meshes, ((low[0] + high[0]) / 2.0, 0.0, low[2]),
          (OPENING[0] / (high[0] - low[0]), 1.0, OPENING[1] / (high[2] - low[2])))
    slim(meshes, panels)
    finish(meshes, "dock_door", "DockDoor")


def dock_seal() -> None:
    meshes = load("03_seal_maxwell")
    low, high = bounds(meshes)
    centre = (low[0] + high[0]) / 2.0
    right_pad = bounds([obj for obj in meshes if material(obj).startswith("lambert3")])
    side_top = max(vertex.co.z for obj in meshes if material(obj).startswith("lambert5")
                   for vertex in obj.data.vertices)
    half_gap = right_pad[0][0] - centre
    place(meshes, (centre, high[1], low[2]),
          (SEAL_GAP / 2.0 / half_gap, 1.0, SEAL_SIDE / (side_top - low[2])))
    finish(meshes, "dock_seal", "DockSeal")


def dock_leveller() -> None:
    meshes = load("02_leveller_maxwell")
    deck = bounds([obj for obj in meshes if material(obj).startswith("lambert1")])
    place(meshes, ((deck[0][0] + deck[1][0]) / 2.0, (deck[0][1] + deck[1][1]) / 2.0,
                   deck[1][2]),
          (LEVELLER[0] / (deck[1][0] - deck[0][0]), LEVELLER[1] / (deck[1][1] - deck[0][1]),
           1.0))
    finish(meshes, "dock_leveller", "DockLeveller")


## The forklift's carriage (part G of step 5 of #253, #302): its forks, fork plate and load
## backrest, every loose part in front of the mast's channels (Godot z 0.55 m on) and no higher
## than the backrest's top (1.47 m), cut free to ride up the mast.
CARRIAGE_FRONT = 0.55
CARRIAGE_TOP = 1.47


## Its wheels (#323), as Godot boxes (x, y, z ranges) round each: every loose part wholly inside
## one is that wheel's (its tyre, rim, hub and nuts).
WHEELS = {"DriveWheelL": ((0.28, 0.56), (0.0, 0.65), (-0.13, 0.52)),
          "DriveWheelR": ((-0.56, -0.28), (0.0, 0.65), (-0.13, 0.52)),
          "SteerWheelL": ((0.28, 0.56), (0.0, 0.56), (-1.55, -0.98)),
          "SteerWheelR": ((-0.56, -0.28), (0.0, 0.56), (-1.55, -0.98))}
## Its steering wheel about where its rim's ring of parts stands, the centre and axis found from
## the rim itself; every loose part within RIM_REACH of the axis and RIM_DEPTH along it is the
## wheel's (rim, spokes, hub and knob).
WHEEL_NEAR = (0.0, 1.415, -0.405)
RIM_REACH = 0.16
RIM_DEPTH = 0.07
## The mast: every loose part from its tilt cylinders' line forward (z 0.30) within its channels'
## width, not the carriage nor a wheel; it tilts about its foot on the drive axle.
MAST_FROM = 0.30
MAST_HALF = 0.30
MAST_FOOT = (0.0, 0.32, 0.45)


def godot(point) -> Vector:
    return Vector((point[0], point[2], -point[1]))


def blender(point) -> Vector:
    return Vector((point[0], -point[2], point[1]))


def _ring(objects: list) -> tuple:
    points = [godot(vertex.co) for obj in objects for vertex in obj.data.vertices]
    centre = sum(points, Vector()) / len(points)
    low = Vector(tuple(min(point[axis] for point in points) for axis in range(3)))
    high = Vector(tuple(max(point[axis] for point in points) for axis in range(3)))
    spread = Matrix(((0.0,) * 3,) * 3)
    for point in points:
        d = point - centre
        for row in range(3):
            for column in range(3):
                spread[row][column] += d[row] * d[column]
    axis = Vector((0.0, -0.7071, 0.7071))
    for _ in range(40):
        inverse = spread.inverted_safe()
        axis = (inverse @ axis).normalized()
    if axis.y > 0.0:
        axis = -axis
    return (low + high) / 2.0, axis


def _inside(obj, box) -> bool:
    low, high = bounds([obj])
    g_low, g_high = godot(low), godot(high)
    xs = sorted((g_low.x, g_high.x))
    ys = sorted((g_low.y, g_high.y))
    zs = sorted((g_low.z, g_high.z))
    return all(box[axis][0] <= span[0] and span[1] <= box[axis][1]
               for axis, span in enumerate((xs, ys, zs)))


def _origin_at(part, point) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    part.select_set(True)
    bpy.context.view_layer.objects.active = part
    bpy.context.scene.cursor.location = blender(point)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")


def forklift() -> None:
    meshes = load("09_forklift")
    plain(meshes)
    standing(meshes)
    for obj in bpy.context.scene.objects:
        obj.select_set(obj in meshes)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.join()
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.separate(type="LOOSE")
    bpy.ops.object.mode_set(mode="OBJECT")
    loose = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    groups = {"Truck": [], "Carriage": [], "Mast": [], "SteeringWheel": []}
    groups.update({name: [] for name in WHEELS})
    near = Vector(WHEEL_NEAR)
    rim = [obj for obj in loose if all((godot(v.co) - near).length < 0.15
                                       for v in obj.data.vertices)
           and len(obj.data.polygons) >= 16]
    centre, axis = _ring(rim)
    for obj in loose:
        low, high = bounds([obj])
        front = -high[1]
        g_low, g_high = godot(low), godot(high)
        z_from = min(g_low.z, g_high.z)
        if front >= CARRIAGE_FRONT - 0.001 and high[2] <= CARRIAGE_TOP:
            groups["Carriage"].append(obj)
            continue
        wheel = next((name for name, box in WHEELS.items() if _inside(obj, box)), None)
        if wheel is not None:
            groups[wheel].append(obj)
            continue
        offsets = [godot(v.co) - centre for v in obj.data.vertices]
        if all(abs(d.dot(axis)) <= RIM_DEPTH and (d - axis * d.dot(axis)).length <= RIM_REACH
               for d in offsets):
            groups["SteeringWheel"].append(obj)
            continue
        if z_from >= MAST_FROM and max(abs(g_low.x), abs(g_high.x)) <= MAST_HALF:
            groups["Mast"].append(obj)
            continue
        groups["Truck"].append(obj)
    pivots = {"SteeringWheel": centre, "Mast": Vector(MAST_FOOT)}
    for name in WHEELS:
        low, high = bounds(groups[name])
        tyre = max(groups[name], key=lambda obj: len(obj.data.polygons))
        t_low, t_high = bounds([tyre])
        middle = (godot(low) + godot(high)) / 2.0
        middle.x = (godot(t_low).x + godot(t_high).x) / 2.0
        pivots[name] = middle
    print("FORKLIFT WHEEL: centre %s axis %s" % (tuple(round(c, 4) for c in centre),
                                                 tuple(round(c, 4) for c in axis)))
    parts = {}
    for name, objects in groups.items():
        bpy.ops.object.select_all(action="DESELECT")
        for obj in objects:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = objects[0]
        bpy.ops.object.join()
        part = bpy.context.view_layer.objects.active
        part.name = name
        part.data.name = name
        if name in pivots:
            _origin_at(part, pivots[name])
        parts[name] = part
    carriage = parts["Carriage"]
    keep = carriage.matrix_world.copy()
    carriage.parent = parts["Mast"]
    carriage.matrix_world = keep
    print("FORKLIFT PARTS: %s" % ", ".join("%s %d parts at %s" % (
        name, len(objects), tuple(round(c, 3) for c in pivots[name]) if name in pivots else "-")
        for name, objects in groups.items()))
    finish_parts(list(parts.values()), "forklift", "JPEG")


def pallet_jack() -> None:
    meshes = load("10_pallet_jack")
    plain(meshes)
    rename("Scene_-_Root", "PalletJack")
    standing(meshes)
    finish_parts(jack_parts(meshes), "pallet_jack", "JPEG")


def jack_parts(meshes: list) -> list:
    """The jack's loose parts sorted into its frame, its steering unit and its handle, each
    joined and its origin at the pivot it turns on (Blender's frame: Godot's +Z is -Y here)."""
    for obj in bpy.context.scene.objects:
        obj.select_set(obj in meshes)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.join()
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.separate(type="LOOSE")
    bpy.ops.object.mode_set(mode="OBJECT")
    groups = {"Chassis": [], "Steering": [], "Tiller": [], "SteerWheels": [], "BogieL": [],
              "BogieR": [], "RollerL1": [], "RollerL2": [], "RollerR1": [], "RollerR2": []}
    for obj in [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]:
        low, high = bounds([obj])
        back = -high[1]
        across = max(abs(low[0]), abs(high[0]))
        g_low, g_high = godot(low), godot(high)
        side = "L" if low[0] + high[0] < 0.0 else "R"
        if low[2] >= TILLER_FROM - 0.001 and back >= TILLER_BACK and across <= TILLER_HALF:
            groups["Tiller"].append(obj)
        elif back >= STEER_FROM and across <= STEER_HALF:
            groups["SteerWheels" if _round_on(obj, STEER_HUB) else "Steering"].append(obj)
        elif (hub := next((name for name, at in ROLLER_HUBS.items()
                           if _round_on(obj, at)), None)) is not None:
            groups["Roller" + side + hub].append(obj)
        elif (BOGIE_ACROSS[0] <= min(abs(low[0]), abs(high[0])) and across <= BOGIE_ACROSS[1]
              and BOGIE_ALONG[0] <= min(g_low.z, g_high.z)
              and max(g_low.z, g_high.z) <= BOGIE_ALONG[1] and high[2] <= BOGIE_TOP):
            groups["Bogie" + side].append(obj)
        else:
            groups["Chassis"].append(obj)
    pivots = {"Chassis": (0.0, 0.0, 0.0), "Steering": (0.0, -STEER_AXIS, 0.0),
              "Tiller": (0.0, -TILLER_FOOT[1], TILLER_FOOT[0]),
              "SteerWheels": blender((0.0, STEER_HUB[0], STEER_HUB[1]))}
    for side, sign in (("L", -1.0), ("R", 1.0)):
        pivots["Bogie" + side] = blender((sign * FORK_MIDDLE,) + ROLLERS_MIDDLE)
        for hub, at in ROLLER_HUBS.items():
            pivots["Roller" + side + hub] = blender((sign * FORK_MIDDLE,) + at)
    parts = {}
    for name, objects in groups.items():
        bpy.ops.object.select_all(action="DESELECT")
        for obj in objects:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = objects[0]
        bpy.ops.object.join()
        part = bpy.context.view_layer.objects.active
        part.name = name
        part.data.name = name
        bpy.context.scene.cursor.location = pivots[name]
        bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
        parts[name] = part
    riders = {"Tiller": "Steering", "SteerWheels": "Steering", "BogieL": "Chassis",
              "BogieR": "Chassis", "RollerL1": "Chassis", "RollerL2": "Chassis",
              "RollerR1": "Chassis", "RollerR2": "Chassis"}
    for name, carrier in riders.items():
        parts[name].parent = parts[carrier]
        parts[name].matrix_parent_inverse = parts[carrier].matrix_world.inverted()
    print("JACK PARTS: %s" % ", ".join("%s %d parts" % (name, len(objects))
                                       for name, objects in groups.items()))
    return list(parts.values())


def _round_on(obj, hub: tuple) -> bool:
    """Whether a loose part is round about an axle across the jack at `hub` (Godot's y, z): its
    middle on the axle and as tall as it is long, as a wheel, a roller, a hub or a cap is."""
    low, high = bounds([obj])
    g_low, g_high = godot(low), godot(high)
    middle = (g_low + g_high) / 2.0
    tall, long = abs(g_high.y - g_low.y), abs(g_high.z - g_low.z)
    return (abs(middle.y - hub[0]) <= ON_HUB and abs(middle.z - hub[1]) <= ON_HUB
            and abs(tall - long) <= ON_HUB and tall >= 0.03)


def finish_parts(parts: list, name: str, images: str = "AUTO") -> None:
    shrink_images(LARGEST)
    bpy.ops.object.select_all(action="DESELECT")
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    TARGET.mkdir(parents=True, exist_ok=True)
    path = TARGET / (name + ".glb")
    bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLB", use_selection=True,
                              use_active_scene=True, export_apply=True, export_yup=True,
                              export_cameras=False, export_lights=False,
                              export_image_format=images, export_jpeg_quality=90)
    low, high = bounds(parts)
    print("CONVERTED %s: %d triangles in %d parts, %.2f x %.2f x %.2f m, %.1f kB" % (
        name, triangles(parts), len(parts), high[0] - low[0], high[1] - low[1],
        high[2] - low[2], path.stat().st_size / 1e3))


def pallet() -> None:
    meshes = load("11_pallet")
    matte(meshes, WOOD_ROUGHNESS)
    standing(meshes, PALLET)
    slim(meshes, meshes, PALLET_TO + 200, PALLET_TO)
    finish(meshes, "pallet", "Pallet", "JPEG")


def carton() -> None:
    meshes = load("carton", CARTON)
    plain(meshes)
    rename("_1k", "")
    standing(meshes)
    slim(meshes, meshes, CARTON_TO + 50, CARTON_TO)
    finish(meshes, "carton", "Carton", "JPEG", CARTON_LARGEST)


def office_chair() -> None:
    meshes = load("13_office_chair")
    finish(meshes, "office_chair", "OfficeChair", "JPEG")


## The yard at night (part H of step 5 of #253, #305): the dry van slimmed from 637k faces, then its
## landing gear (every face whose middle lies between Blender y -3.45 and -2.80, below 1.15 m) cut
## from its box so a coupled trailer's can be cranked up; the tractor slimmed from 202k.
GEAR_Y = (-3.45, -2.80)
GEAR_TOP = 1.15
TRAILER_TO = 20000
TRACTOR_TO = 25000


def trailer() -> None:
    meshes = load("05_trailer_dryvan")
    plain(meshes)
    standing(meshes)
    for obj in bpy.context.scene.objects:
        obj.select_set(obj in meshes)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.join()
    body = bpy.context.view_layer.objects.active
    slim([body], [body], TRAILER_TO + 500, TRAILER_TO)
    bpy.ops.object.mode_set(mode="EDIT")
    mesh = bmesh.from_edit_mesh(body.data)
    for face in mesh.faces:
        centre = face.calc_center_median()
        face.select = GEAR_Y[0] <= centre.y <= GEAR_Y[1] and centre.z <= GEAR_TOP
    bmesh.update_edit_mesh(body.data)
    bpy.ops.mesh.separate(type="SELECTED")
    bpy.ops.object.mode_set(mode="OBJECT")
    gear = next(obj for obj in bpy.context.scene.objects if obj.type == "MESH" and obj != body)
    body.name = body.data.name = "Trailer"
    gear.name = gear.data.name = "LandingGear"
    print("TRAILER PARTS: Trailer %d triangles, LandingGear %d" % (triangles([body]),
                                                                   triangles([gear])))
    finish_parts([body, gear], "trailer_dryvan", "JPEG")


def tractor() -> None:
    meshes = load("04_tractor_1980")
    plain(meshes)
    standing(meshes)
    slim(meshes, meshes, TRACTOR_TO + 500, TRACTOR_TO)
    finish(meshes, "tractor_1980", "Tractor", "JPEG")


def box_truck() -> None:
    meshes = load("06_box_truck_lct3000")
    plain(meshes)
    standing(meshes)
    finish(meshes, "box_truck", "BoxTruck", "JPEG")


def dumpsters() -> None:
    meshes = load("08_dumpsters")
    plain(meshes)
    standing(meshes)
    finish(meshes, "dumpsters", "Dumpsters", "JPEG")


JOBS = {"dock_door": dock_door, "dock_seal": dock_seal, "dock_leveller": dock_leveller,
        "forklift": forklift, "pallet_jack": pallet_jack, "pallet": pallet, "carton": carton,
        "office_chair": office_chair, "trailer": trailer, "tractor": tractor,
        "box_truck": box_truck, "dumpsters": dumpsters}

if __name__ == "__main__":
    for job in sys.argv[sys.argv.index("--") + 1:]:
        JOBS[job]()
