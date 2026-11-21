"""Convert the compound's patrol guard (Mission 2's step 6, #358): "Security Guard - Rigged 3D
Model" by qsardor57913 on Sketchfab (CC BY 4.0; source_assets/sketchfab/29_security_guard/),
a contract security officer in a grey long-sleeved uniform shirt with epaulettes and shoulder
patches, a tie, black trousers and a duty belt (handcuffs, radio, torch holder), on a Mixamo rig.

It gets Ethan's own Mixamo clips (source_assets/mixamo/: Breathing Idle, Walking, Running),
each baked onto the guard bone by bone as a turn from the rest pose: both rigs stand in the same
T-pose, so each bone takes the world turn the clip gives Ethan's bone from his rest, on the
guard's own bone lengths, and the hips take the clip's place scaled by the guard's hip height.
The walk and the run walk in place (the game moves him) and their ground speeds are printed.

What else it changes: the Sketchfab suffixes go from the bone names ("mixamorig:Hips_01" becomes
"mixamorig:Hips"); the model is scaled to its real height and stood with its shoes at the origin,
facing -Y (a glTF model's front); its textures are halved to 1024 pixels and written as WebP,
one roughness per part, nothing metallic. Clips are named as Godot imports them: Idle-loop,
Walk-loop and Run-loop loop.

Run from the repository root:
    /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python-exit-code 1 \\
        --python tools/art/convert_patrol_guard.py
"""

import math
import pathlib
import re

import bpy
from mathutils import Matrix, Vector

SOURCE = pathlib.Path("source_assets/sketchfab/29_security_guard/security_guard_raw.glb")
CLIPS = pathlib.Path("source_assets/mixamo")
TARGET = pathlib.Path("game/features/characters/patrol_guard/patrol_guard.glb")
HEIGHT = 1.80
MAX_TEXTURE = 1024
QUALITY = 90
FPS = 30.0
ROUGHNESS = 0.78
JOBS = [("Breathing Idle.fbx", "Idle-loop", False), ("Walking.fbx", "Walk-loop", True),
        ("Running.fbx", "Run-loop", True)]
SUFFIX = re.compile(r"_\d+$")


def rotation(matrix):
    return matrix.to_3x3().normalized()


def load_guard():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(SOURCE))
    armature = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    for item in [armature] + meshes:
        world = item.matrix_world.copy()
        item.parent = None
        item.matrix_world = world
    for item in [o for o in bpy.data.objects if o.type == "EMPTY"]:
        bpy.data.objects.remove(item, do_unlink=True)
    for item in meshes:
        world = item.matrix_world.copy()
        item.parent = armature
        item.matrix_parent_inverse = armature.matrix_world.inverted()
        item.matrix_world = world
        for modifier in item.modifiers:
            if modifier.type == "ARMATURE":
                modifier.object = armature
    for item in bpy.data.objects:
        item.animation_data_clear()
    for action in list(bpy.data.actions):
        bpy.data.actions.remove(action)
    for bone in armature.data.bones:
        bone.name = SUFFIX.sub("", bone.name)
    for item in meshes:
        for group in item.vertex_groups:
            group.name = SUFFIX.sub("", group.name)
    bpy.ops.object.select_all(action="DESELECT")
    for item in [armature] + meshes:
        item.select_set(True)
    bpy.context.view_layer.objects.active = armature
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    armature.data.pose_position = "POSE"
    return armature, meshes


def import_clip(name):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=str(CLIPS / name))
    new = [o for o in bpy.data.objects if o not in before]
    clip = next(o for o in new if o.type == "ARMATURE")
    for bone in clip.pose.bones:
        bone.name = re.sub(r"^mixamorig\d*:", "mixamorig:", bone.name)
    return clip, new


def hip_height(armature, name="mixamorig:Hips"):
    return (armature.matrix_world @ armature.data.bones[name].head_local).z


def bake(guard, clip, name):
    source_action = clip.animation_data.action
    start, end = (int(round(v)) for v in source_action.frame_range)
    ratio = hip_height(guard) / hip_height(clip)
    guard_world = guard.matrix_world
    guard_turn = rotation(guard_world)
    if guard.animation_data is not None:
        guard.animation_data.action = None
    bones = sorted(guard.pose.bones, key=lambda b: len(b.parent_recursive))
    for bone in bones:
        bone.rotation_mode = "QUATERNION"
    previous = {}
    clip_hips_rest = clip.matrix_world @ clip.data.bones["mixamorig:Hips"].head_local
    for frame in range(start, end + 1):
        bpy.context.scene.frame_set(frame)
        posed = {}
        for bone in bones:
            rest = bone.bone.matrix_local
            if bone.parent is None:
                base = rest
            else:
                base = posed[bone.parent.name] @ bone.parent.bone.matrix_local.inverted() @ rest
            source = clip.pose.bones.get(bone.name)
            if source is None:
                posed[bone.name] = base
                continue
            turn_now = rotation(clip.matrix_world @ source.matrix)
            turn_rest = rotation(clip.matrix_world @ source.bone.matrix_local)
            world_rest = guard_turn @ rotation(rest)
            wanted_world = turn_now @ turn_rest.inverted() @ world_rest
            turn = (guard_turn.inverted() @ wanted_world).to_4x4()
            if bone.name == "mixamorig:Hips":
                moved = (clip.matrix_world @ source.head) - clip_hips_rest
                at = guard_world.inverted() @ (guard_world @ rest.translation + moved * ratio)
            else:
                at = base.translation
            wanted = Matrix.Translation(at) @ turn
            posed[bone.name] = wanted
            location, quaternion, _ = (base.inverted() @ wanted).decompose()
            last = previous.get(bone.name)
            if last is not None and last.dot(quaternion) < 0.0:
                quaternion.negate()
            previous[bone.name] = quaternion.copy()
            bone.rotation_quaternion = quaternion
            bone.keyframe_insert("rotation_quaternion", frame=frame, group=bone.name)
            if bone.name == "mixamorig:Hips":
                bone.location = location
                bone.keyframe_insert("location", frame=frame, group=bone.name)
    action = guard.animation_data.action
    action.name = name
    action.use_fake_user = True
    action.use_frame_range = True
    action.frame_start, action.frame_end = start, end
    return action


def in_place(guard, action, frames):
    """Takes the hips' even travel over the ground out of the clip; returns its speed (m/s)."""
    bpy.context.scene.frame_set(frames[0])
    guard.animation_data.action = action
    hips = guard.pose.bones["mixamorig:Hips"]
    bpy.context.scene.frame_set(frames[0])
    first = guard.matrix_world @ hips.head
    bpy.context.scene.frame_set(frames[1])
    last = guard.matrix_world @ hips.head
    travel = Vector((last.x - first.x, last.y - first.y, 0.0))
    seconds = (frames[1] - frames[0]) / FPS
    per_frame = travel / (frames[1] - frames[0])
    curves = {}
    for curve in fcurves(action):
        if curve.data_path == 'pose.bones["mixamorig:Hips"].location':
            curves[curve.array_index] = curve
    parent_inverse = (guard.matrix_world @ hips.bone.matrix_local).inverted().to_3x3()
    for frame in range(frames[0], frames[1] + 1):
        shift = parent_inverse @ (per_frame * (frame - frames[0]))
        for index, curve in curves.items():
            for key in curve.keyframe_points:
                if int(round(key.co[0])) == frame:
                    for point in (key.co, key.handle_left, key.handle_right):
                        point[1] -= shift[index]
    for curve in curves.values():
        curve.update()
    return travel.length / seconds


def fcurves(action):
    if hasattr(action, "fcurves") and len(action.fcurves):
        return list(action.fcurves)
    found = []
    for layer in getattr(action, "layers", []):
        for strip in layer.strips:
            for bag in strip.channelbags:
                found.extend(bag.fcurves)
    return found


def stand(guard, meshes):
    bpy.context.scene.frame_set(1)
    depsgraph = bpy.context.evaluated_depsgraph_get()
    low = math.inf
    top = -math.inf
    for item in meshes:
        evaluated = item.evaluated_get(depsgraph)
        mesh = evaluated.to_mesh()
        heights = [(evaluated.matrix_world @ v.co).z for v in mesh.vertices]
        low, top = min(low, min(heights)), max(top, max(heights))
        evaluated.to_mesh_clear()
    scale = HEIGHT / (top - low)
    hips = guard.matrix_world @ guard.data.bones["mixamorig:Hips"].head_local
    guard.matrix_world = Matrix.Diagonal((scale, scale, scale, 1.0)) \
        @ Matrix.Translation((-hips.x, -hips.y, -low)) @ guard.matrix_world
    bpy.context.view_layer.update()
    bpy.ops.object.select_all(action="DESELECT")
    for item in [guard] + meshes:
        item.select_set(True)
    bpy.context.view_layer.objects.active = guard
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    print(f"  scaled {scale:.4f} to {HEIGHT} m")


def clean_materials(meshes):
    for item in meshes:
        for slot in item.material_slots:
            tree = slot.material.node_tree
            shader = next(n for n in tree.nodes if n.type == "BSDF_PRINCIPLED")
            shader.inputs["Roughness"].default_value = ROUGHNESS
            shader.inputs["Metallic"].default_value = 0.0
            for link in list(tree.links):
                if link.to_node == shader and link.to_socket.name in {"Roughness", "Metallic",
                                                                     "Specular IOR Level"}:
                    tree.links.remove(link)
            for node in tree.nodes:
                if node.type == "TEX_IMAGE" and node.image is not None:
                    while node.image.size[0] > MAX_TEXTURE:
                        node.image.scale(node.image.size[0] // 2, node.image.size[1] // 2)


def push_track(guard, action):
    data = guard.animation_data
    data.action = None
    track = data.nla_tracks.new()
    track.name = action.name
    strip = track.strips.new(action.name, int(action.frame_start), action)
    if hasattr(strip, "action_slot") and action.slots and strip.action_slot is None:
        strip.action_slot = action.slots[0]


def main():
    guard, meshes = load_guard()
    stand(guard, meshes)
    baked = []
    for file, name, moving in JOBS:
        clip, objects = import_clip(file)
        source_action = clip.animation_data.action
        action = bake(guard, clip, name)
        if moving:
            speed = in_place(guard, action, (int(action.frame_start), int(action.frame_end)))
            print(f"  {name}: {speed:.3f} m/s over the ground")
        baked.append(action)
        for item in objects:
            bpy.data.objects.remove(item, do_unlink=True)
        bpy.data.actions.remove(source_action)
    clean_materials(meshes)
    for action in baked:
        push_track(guard, action)
    guard.name = "PatrolGuard"
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for item in [guard] + meshes:
        item.select_set(True)
    bpy.context.view_layer.objects.active = guard
    bpy.ops.export_scene.gltf(filepath=str(TARGET), export_format="GLB", use_selection=True,
                              export_animation_mode="NLA_TRACKS", export_force_sampling=True,
                              export_anim_slide_to_zero=True, export_image_format="WEBP",
                              export_image_quality=QUALITY, export_apply=False, export_yup=True,
                              export_cameras=False, export_lights=False, export_extras=False)
    triangles = sum(sum(len(p.vertices) - 2 for p in m.data.polygons) for m in meshes)
    clips = ", ".join(f"{a.name} {int(a.frame_start)}-{int(a.frame_end)}" for a in baked)
    print(f"{TARGET}: {triangles} triangles, {len(guard.data.bones)} bones, clips {clips}, "
          f"{TARGET.stat().st_size / 1e6:.1f} MB")


main()
