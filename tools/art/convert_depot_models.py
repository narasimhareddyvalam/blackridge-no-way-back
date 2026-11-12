"""Makes the bigger depot's game files from the models in source_assets/sketchfab (CC BY 4.0)
and one of Poly Haven's (CC0).

dock_door: Maxwell autodoors' Industrial Overhead Door, its panel alone (the red wall, the trim and
    the overhead tracks and springs above 2.35 m removed), scaled to the 2.74 x 3.05 m opening.
dock_seal: Maxwell autodoors' Foam Pad Dock Seal, its gap widened to 2.80 m and its side pads
    3.25 m tall, its back at the origin so it mounts on the wall's face.
dock_leveller: Maxwell autodoors' DLHH Electrohydraulic Dock Leveler, its deck 2.13 x 2.44 m
    (7 x 8 ft) with the top of the deck at the origin and its lip facing out.
forklift: Kamran Mughal's Warehouse Forklift, its forks toward +Z, its specular map left out.
pallet_jack: FFeller's Pallet Jack, its handle toward +Z and its forks toward -Z.
pallet: widthRider's photoscanned Euro pallet sized as the American 48 x 40 in pallet (1.219 m
    along Z, 1.016 m across, 0.15 m tall), reduced to about 3,000 triangles, its dry wood matte
    (its roughness came from its specular map).
carton: Poly Haven's Cardboard Box 01 (CC0, the depot yard's copy) reduced to about 400
    triangles, its textures halved to 512 pixels, for the cartons on the staged pallets.
Each model stands with its base at the origin; the door, seal and leveller face +Z in Godot;
textures larger than 1024 pixels are halved until they fit, and the four props' are saved as JPEG.

Usage, from the repository root:
    /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python-exit-code 1 \\
        --python tools/art/convert_depot_models.py -- dock_door dock_seal dock_leveller forklift \\
        pallet_jack pallet carton
"""

import pathlib
import sys

import bmesh
import bpy

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


def forklift() -> None:
    meshes = load("09_forklift")
    plain(meshes)
    standing(meshes)
    finish(meshes, "forklift", "Forklift", "JPEG")


def pallet_jack() -> None:
    meshes = load("10_pallet_jack")
    plain(meshes)
    rename("Scene_-_Root", "PalletJack")
    standing(meshes)
    finish(meshes, "pallet_jack", "PalletJack", "JPEG")


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


JOBS = {"dock_door": dock_door, "dock_seal": dock_seal, "dock_leveller": dock_leveller,
        "forklift": forklift, "pallet_jack": pallet_jack, "pallet": pallet, "carton": carton}

if __name__ == "__main__":
    for job in sys.argv[sys.argv.index("--") + 1:]:
        JOBS[job]()
