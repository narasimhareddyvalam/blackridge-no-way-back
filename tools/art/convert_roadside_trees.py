"""Makes the forest highway's roadside trees (#280, Pacific Northwest) from the models in
source_assets/sketchfab (CC BY 4.0), with tools/art/convert_depot_models.py's helpers.

mountain_hemlock: PlantCatalog's "Realistic HD Mountain hemlock (21/43)", the hemlock of the
    Cascades, 22 m tall as imported (second-growth hemlocks reach 20-35 m), its dead lower
    branches kept.
western_red_cedar: SirSonat's "Western Red Cedar *Inspired* Tree - WINTER Ver.", its mushrooms
    left out, its ground where they stood (1.0 m above the lowest root), 24 m tall above it and
    narrowed to 60% across: as modelled its trunk is 2.1 m thick at breast height, an old giant's
    on a second-growth height; narrowed it is 1.26 m and its crown 6 m wide.
young_firs: lolipop_1707's "Realistic fir trees pack" (Large tree 1-3 and Medium tree 1, their
    most detailed meshes, LOD0), young Douglas firs of the road's edge, 9.7, 9.6, 8.4 and 4.6 m
    tall as the pack has them, as the nodes YoungFir1 to YoungFir4 of one file, sharing its
    textures; matte (roughness 0.8), their metallic-roughness maps left out.
Each comes with a far version, `<name>Far`, for 20-50 m: a quarter of its foliage cards,
each grown 1.6 times about its middle to keep the crown's fill, and its wood decimated to 15%.
Each stands with its trunk's foot at the origin (its centre at breast height, 1.3 m up, on the
vertical axis). The foliage's alpha is cut (glTF MASK, by a ROUND node, so Godot draws it with
alpha scissor). Textures over 2048 pixels are halved until they fit, and saved as WebP.

Usage, from the repository root:
    /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python-exit-code 1 \\
        --python tools/art/convert_roadside_trees.py -- mountain_hemlock western_red_cedar \\
        young_firs
"""

import importlib.util
import pathlib
import random
import sys

import bmesh
import bpy
from mathutils import Vector

ROOT = pathlib.Path.cwd()
SOURCE = ROOT / "source_assets/sketchfab"
TARGET = ROOT / "game/features/environments/industrial_loop/art/trees"
LARGEST = 2048
BREAST = 1.3
CEDAR_GROUND = 1.0
CEDAR_TALL = 24.0
CEDAR_ACROSS = 0.6
FIRS = {"young_fir_1": "Christmas tree_LOD0", "young_fir_2": "Christmas tree_2_LOD0",
        "young_fir_3": "Christmas tree_3_LOD0", "young_fir_4": "Christmas tree_4_LOD0"}
FOLIAGE = ("Tsuga_fol", "Leaves", "Brunches")
FIR_ROUGHNESS = 0.8
FAR_KEEP = 0.25
FAR_GROW = 1.6
FAR_WOOD = 0.15
FAR_SEED = 280


def helpers():
    spec = importlib.util.spec_from_file_location(
        "convert_depot_models", ROOT / "tools/art/convert_depot_models.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    module.TARGET = TARGET
    return module


DEPOT = helpers()


def cut_alpha(meshes: list) -> None:
    for obj in meshes:
        for slot in obj.material_slots:
            item = slot.material
            if item is None or not item.name.startswith(FOLIAGE):
                continue
            tree = item.node_tree
            shader = next(node for node in tree.nodes if node.type == "BSDF_PRINCIPLED")
            alpha = shader.inputs["Alpha"]
            source = alpha.links[0].from_socket if alpha.links else None
            if source is None:
                continue
            tree.links.remove(alpha.links[0])
            cut = tree.nodes.new("ShaderNodeMath")
            cut.operation = "ROUND"
            tree.links.new(source, cut.inputs[0])
            tree.links.new(cut.outputs[0], alpha)


def foot(meshes: list) -> tuple:
    trunk = [obj for obj in meshes if not DEPOT.material(obj).startswith(FOLIAGE)]
    low, _ = DEPOT.bounds(trunk)
    ring = [vertex.co for obj in trunk for vertex in obj.data.vertices
            if abs(vertex.co[2] - (low[2] + BREAST)) < 0.25]
    centre_x = sum(point[0] for point in ring) / max(len(ring), 1)
    centre_y = sum(point[1] for point in ring) / max(len(ring), 1)
    return centre_x, centre_y, low[2]


def join(objects: list, name: str):
    for obj in bpy.context.scene.objects:
        obj.select_set(obj in objects)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    joined = bpy.context.view_layer.objects.active
    joined.name = name
    return joined


def far_copy(model, name: str):
    far = model.copy()
    far.data = model.data.copy()
    far.name = name
    bpy.context.scene.collection.objects.link(far)
    mesh = bmesh.new()
    mesh.from_mesh(far.data)
    foliage = {index for index, slot in enumerate(far.material_slots)
               if slot.material is not None and slot.material.name.startswith(FOLIAGE)}
    rng = random.Random(FAR_SEED)
    seen = set()
    for face in mesh.faces:
        if face.index in seen or face.material_index not in foliage:
            continue
        island = []
        stack = [face]
        while stack:
            current = stack.pop()
            if current.index in seen:
                continue
            seen.add(current.index)
            island.append(current)
            stack.extend(other for edge in current.edges for other in edge.link_faces
                         if other.index not in seen)
        verts = {vert for item in island for vert in item.verts}
        if rng.random() < FAR_KEEP:
            middle = sum((vert.co for vert in verts), Vector()) / len(verts)
            for vert in verts:
                vert.co = middle + (vert.co - middle) * FAR_GROW
        else:
            for vert in verts:
                vert.tag = True
    bmesh.ops.delete(mesh, geom=[vert for vert in mesh.verts if vert.tag], context="VERTS")
    wood = [face for face in mesh.faces if face.material_index not in foliage]
    mesh.to_mesh(far.data)
    mesh.free()
    if wood:
        for obj in bpy.context.scene.objects:
            obj.select_set(obj == far)
        bpy.context.view_layer.objects.active = far
        for polygon in far.data.polygons:
            polygon.select = polygon.material_index not in foliage
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_mode(type="FACE")
        bpy.ops.mesh.decimate(ratio=FAR_WOOD)
        bpy.ops.object.mode_set(mode="OBJECT")
    return far


def write(models: list, file: str) -> None:
    made = []
    for name, model in models:
        made += [model, far_copy(model, name + "Far")]
    for obj in bpy.context.scene.objects:
        obj.select_set(obj in made)
    TARGET.mkdir(parents=True, exist_ok=True)
    path = TARGET / (file + ".glb")
    bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLB", use_selection=True,
                              use_active_scene=True, export_apply=True, export_yup=True,
                              export_cameras=False, export_lights=False,
                              export_image_format="WEBP", export_jpeg_quality=90)
    for obj in made:
        low, high = DEPOT.bounds([obj])
        print("CONVERTED %s: %d triangles, %.2f x %.2f x %.2f m" % (
            obj.name, DEPOT.triangles([obj]), high[0] - low[0], high[1] - low[1],
            high[2] - low[2]))
    print("CONVERTED %s.glb %.1f kB" % (file, path.stat().st_size / 1e3))


def mountain_hemlock() -> None:
    meshes = DEPOT.load("14_mountain_hemlock")
    cut_alpha(meshes)
    DEPOT.fit(meshes, foot(meshes), (1.0, 1.0, 1.0))
    DEPOT.shrink_images(LARGEST)
    write([("MountainHemlock", join(meshes, "MountainHemlock"))], "mountain_hemlock")


def western_red_cedar() -> None:
    meshes = DEPOT.load("16_western_red_cedar")
    DEPOT.drop(meshes, ("Mushrooms",))
    cut_alpha(meshes)
    low, high = DEPOT.bounds(meshes)
    ground = low[2] + CEDAR_GROUND
    tall = CEDAR_TALL / (high[2] - ground)
    centre = foot(meshes)
    DEPOT.fit(meshes, (centre[0], centre[1], ground), (CEDAR_ACROSS * tall, CEDAR_ACROSS * tall,
                                                         tall))
    DEPOT.shrink_images(LARGEST)
    write([("WesternRedCedar", join(meshes, "WesternRedCedar"))], "western_red_cedar")


def young_firs() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(SOURCE / "15_fir_pack/15_fir_pack.glb"))
    trees = []
    for index, node in enumerate(FIRS.values()):
        keep = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"
                and obj.parent is not None and obj.parent.name == node]
        trees.append(("YoungFir%d" % (index + 1), keep))
    kept = [obj for _, keep in trees for obj in keep]
    for obj in bpy.context.scene.objects:
        obj.select_set(obj in kept)
    bpy.context.view_layer.objects.active = kept[0]
    bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    for obj in [obj for obj in bpy.context.scene.objects if obj not in kept]:
        bpy.data.objects.remove(obj)
    for image in [image for image in bpy.data.images if image.users == 0]:
        bpy.data.images.remove(image)
    DEPOT.matte(kept, FIR_ROUGHNESS)
    cut_alpha(kept)
    DEPOT.shrink_images(LARGEST)
    models = []
    for name, keep in trees:
        DEPOT.fit(keep, foot(keep), (1.0, 1.0, 1.0))
        models.append((name, join(keep, name)))
    write(models, "young_firs")


JOBS = {"mountain_hemlock": mountain_hemlock, "western_red_cedar": western_red_cedar,
        "young_firs": young_firs}


if __name__ == "__main__":
    for job in sys.argv[sys.argv.index("--") + 1:]:
        JOBS[job]()
