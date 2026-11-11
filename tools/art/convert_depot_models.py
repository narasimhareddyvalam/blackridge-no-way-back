"""Makes the bigger depot's game files from the models in source_assets/sketchfab (CC BY 4.0).

dock_door: Maxwell autodoors' Industrial Overhead Door, without its red wall and without the
overhead tracks and springs above 2.35 m (inside the shed while the door is shut), scaled so its
panel is 2.74 m wide and its trim 3.05 m tall: the 9 x 10 ft opening of a truck dock. Its front
faces +Z in Godot, the bottom of its panel at the origin.

Usage, from the repository root:
    /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python-exit-code 1 \\
        --python tools/art/convert_depot_models.py -- dock_door
"""

import pathlib
import sys

import bmesh
import bpy

ROOT = pathlib.Path.cwd()
SOURCE = ROOT / "source_assets/sketchfab"
TARGET = ROOT / "game/features/environments/industrial_loop/art/depot"
HARDWARE = 2.35
OPENING = (2.74, 3.05)
SLIM_ABOVE = 5500
SLIM_TO = 5000


def load(name: str) -> list:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(SOURCE / name / (name + ".glb")))
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


def bounds(objects: list) -> tuple:
    points = [vertex.co for obj in objects for vertex in obj.data.vertices]
    low = [min(point[axis] for point in points) for axis in range(3)]
    high = [max(point[axis] for point in points) for axis in range(3)]
    return low, high


def triangles(objects: list) -> int:
    total = 0
    for obj in objects:
        obj.data.calc_loop_triangles()
        total += len(obj.data.loop_triangles)
    return total


def dock_door() -> None:
    meshes = load("01_door_maxwell")
    for obj in [obj for obj in meshes if material(obj).startswith("lambert5")]:
        meshes.remove(obj)
        bpy.data.objects.remove(obj)
    panels = [obj for obj in meshes if material(obj).startswith("lambert2")]
    for obj in panels:
        mesh = bmesh.new()
        mesh.from_mesh(obj.data)
        bmesh.ops.delete(mesh, geom=[vertex for vertex in mesh.verts if vertex.co.z > HARDWARE],
                         context="VERTS")
        mesh.to_mesh(obj.data)
        mesh.free()
    low, high = bounds(panels)
    trim = [obj for obj in meshes if material(obj).startswith("lambert6")]
    trim_top = bounds(trim)[1][2]
    scale = (OPENING[0] / (high[0] - low[0]), 1.0, OPENING[1] / trim_top)
    middle = (low[0] + high[0]) / 2.0
    for obj in meshes:
        for vertex in obj.data.vertices:
            vertex.co.x = (vertex.co.x - middle) * scale[0]
            vertex.co.z *= scale[2]
    for kind in ("DISSOLVE", "COLLAPSE"):
        count = triangles(meshes)
        if count <= SLIM_ABOVE:
            break
        others = count - triangles(panels)
        for obj in panels:
            slim = obj.modifiers.new("Slim", "DECIMATE")
            slim.decimate_type = kind
            if kind == "DISSOLVE":
                slim.angle_limit = 0.01
            else:
                slim.ratio = max(0.05, (SLIM_TO - others) / triangles(panels))
            bpy.context.view_layer.objects.active = obj
            bpy.ops.object.modifier_apply(modifier=slim.name)
    for obj in bpy.context.scene.objects:
        obj.select_set(obj in meshes)
    bpy.context.view_layer.objects.active = panels[0]
    bpy.ops.object.convert(target="MESH")
    bpy.ops.object.join()
    door = bpy.context.view_layer.objects.active
    door.name = "DockDoor"
    low, high = bounds([door])
    TARGET.mkdir(parents=True, exist_ok=True)
    path = TARGET / "dock_door.glb"
    bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLB", use_selection=True,
                              use_active_scene=True, export_apply=True, export_yup=True,
                              export_cameras=False, export_lights=False)
    print("CONVERTED dock_door: %d triangles, %.2f x %.2f x %.2f m, %d materials, %.1f kB" % (
        triangles([door]), high[0] - low[0], high[1] - low[1], high[2] - low[2],
        len(door.material_slots), path.stat().st_size / 1e3))


JOBS = {"dock_door": dock_door}

if __name__ == "__main__":
    for job in sys.argv[sys.argv.index("--") + 1:]:
        JOBS[job]()
