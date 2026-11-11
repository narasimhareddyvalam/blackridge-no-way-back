"""Convert Microsoft Rocketbox's Security_Male_01 and a seated idle into the gate guard (C55).

Run from the repository root:
    /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python-exit-code 1 \\
        --python tools/art/convert_rocketbox.py

It reads source_assets/rocketbox/ (its README.md lists the files) and writes
game/features/characters/guard/guard.glb. What it changes:
- the clip m_sit_chair_breathe_01 is baked onto the guard bone by bone. The clip's rest pose is
  its own first frame, so each bone takes the turn the clip gives it in the armature's space, on
  the guard's own bone lengths, and the pelvis also takes the clip's place;
- he is turned to face Blender's -Y, a glTF model's front, and moved so that his shoes stand at
  the origin, under his hips;
- one roughness per part replaces Rocketbox's specular maps, and the colour and normal maps are
  halved to 1024 pixels and stored as WebP;
- the one clip is named SitIdle-loop, which Godot imports as SitIdle, looping.
"""

import math
import pathlib

import bpy
from mathutils import Matrix, Vector

SOURCE = pathlib.Path("source_assets/rocketbox")
CHARACTER = SOURCE / "Security_Male_01"
CLIP = SOURCE / "Animations" / "m_sit_chair_breathe_01.max.fbx"
TARGET = pathlib.Path("game/features/characters/guard/guard.glb")
CLIP_NAME = "SitIdle-loop"
ROUGHNESS = {"head": 0.56, "body": 0.72, "equipment": 0.5}
MAX_TEXTURE = 1024
QUALITY = 90


def import_fbx(path):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=str(path))
    for item in [o for o in bpy.data.objects if o not in before and o.type == "EMPTY"]:
        bpy.data.objects.remove(item, do_unlink=True)
    new = [o for o in bpy.data.objects if o not in before]
    return next(o for o in new if o.type == "ARMATURE"), new


def bake(guard, clip):
    source_action = clip.animation_data.action
    start, end = (int(round(value)) for value in source_action.frame_range)
    if guard.animation_data is not None:
        guard.animation_data.action = None
    bones = sorted(guard.pose.bones, key=lambda bone: len(bone.parent_recursive))
    for bone in bones:
        bone.rotation_mode = "QUATERNION"
    previous = {}
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
            turn = source.matrix.to_3x3().normalized().to_4x4()
            at = source.matrix.translation if bone.parent is None else base.translation
            wanted = Matrix.Translation(at) @ turn
            posed[bone.name] = wanted
            location, rotation, _ = (base.inverted() @ wanted).decompose()
            last = previous.get(bone.name)
            if last is not None and last.dot(rotation) < 0.0:
                rotation.negate()
            previous[bone.name] = rotation.copy()
            bone.rotation_quaternion = rotation
            bone.keyframe_insert("rotation_quaternion", frame=frame, group=bone.name)
            if bone.parent is None:
                bone.location = location
                bone.keyframe_insert("location", frame=frame, group=bone.name)
    action = guard.animation_data.action
    action.name = CLIP_NAME
    action.use_fake_user = True
    action.use_frame_range = True
    action.frame_start, action.frame_end = start, end
    return action


def world_bone(armature, name):
    return armature.matrix_world @ armature.pose.bones[name].head


def lowest_point(meshes):
    depsgraph = bpy.context.evaluated_depsgraph_get()
    low = math.inf
    for item in meshes:
        evaluated = item.evaluated_get(depsgraph)
        mesh = evaluated.to_mesh()
        low = min(low, min((evaluated.matrix_world @ v.co).z for v in mesh.vertices))
        evaluated.to_mesh_clear()
    return low


def stand(guard, meshes, frame):
    bpy.context.scene.frame_set(frame)
    hips = world_bone(guard, "Bip01 Pelvis")
    knees = (world_bone(guard, "Bip01 L Calf") + world_bone(guard, "Bip01 R Calf")) / 2.0
    facing = Vector((knees.x - hips.x, knees.y - hips.y))
    turn = math.atan2(-1.0, 0.0) - math.atan2(facing.y, facing.x)
    guard.matrix_world = Matrix.Rotation(turn, 4, "Z") @ guard.matrix_world
    bpy.context.view_layer.update()
    hips = world_bone(guard, "Bip01 Pelvis")
    guard.matrix_world = Matrix.Translation((-hips.x, -hips.y, -lowest_point(meshes))) \
        @ guard.matrix_world
    bpy.context.view_layer.update()
    hips = world_bone(guard, "Bip01 Pelvis")
    print(f"  turned {math.degrees(turn):.1f} deg to face -Y; hips {hips.z:.3f} m above his shoes")


def clean_materials(meshes):
    for item in meshes:
        for slot in item.material_slots:
            material = slot.material
            part = material.name.split("_", 1)[1]
            tree = material.node_tree
            for node in [n for n in tree.nodes if n.type in {"TEX_IMAGE", "NORMAL_MAP"}]:
                tree.nodes.remove(node)
            shader = next(n for n in tree.nodes if n.type == "BSDF_PRINCIPLED")
            colour = tree.nodes.new("ShaderNodeTexImage")
            colour.image = bpy.data.images.load(
                str(CHARACTER / "Textures" / f"m171_{part}_color.tga"))
            tree.links.new(colour.outputs["Color"], shader.inputs["Base Color"])
            normal = tree.nodes.new("ShaderNodeTexImage")
            normal.image = bpy.data.images.load(
                str(CHARACTER / "Textures" / f"m171_{part}_normal.tga"))
            normal.image.colorspace_settings.name = "Non-Color"
            bend = tree.nodes.new("ShaderNodeNormalMap")
            tree.links.new(normal.outputs["Color"], bend.inputs["Color"])
            tree.links.new(bend.outputs["Normal"], shader.inputs["Normal"])
            shader.inputs["Roughness"].default_value = ROUGHNESS[part]
            shader.inputs["Metallic"].default_value = 0.0
            for image in (colour.image, normal.image):
                while image.size[0] > MAX_TEXTURE:
                    image.scale(image.size[0] // 2, image.size[1] // 2)


def push_track(guard, action):
    data = guard.animation_data
    data.action = None
    track = data.nla_tracks.new()
    track.name = CLIP_NAME
    strip = track.strips.new(CLIP_NAME, int(action.frame_start), action)
    if hasattr(strip, "action_slot") and action.slots and strip.action_slot is None:
        strip.action_slot = action.slots[0]


def export(guard, meshes):
    bpy.ops.object.select_all(action="DESELECT")
    for item in [guard] + meshes:
        item.select_set(True)
    bpy.context.view_layer.objects.active = guard
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(TARGET), export_format="GLB", use_selection=True,
                              export_animation_mode="NLA_TRACKS", export_force_sampling=True,
                              export_anim_slide_to_zero=True,
                              export_image_format="WEBP", export_image_quality=QUALITY,
                              export_apply=False, export_yup=True, export_cameras=False,
                              export_lights=False, export_extras=False)


bpy.ops.wm.read_factory_settings(use_empty=True)
guard, objects = import_fbx(CHARACTER / "Export" / "Security_Male_01.fbx")
meshes = [o for o in objects if o.type == "MESH"]
clip, clip_objects = import_fbx(CLIP)
source_action = clip.animation_data.action
for action in [a for a in bpy.data.actions if a is not source_action]:
    bpy.data.actions.remove(action)
baked = bake(guard, clip)
for item in clip_objects:
    bpy.data.objects.remove(item, do_unlink=True)
bpy.data.actions.remove(source_action)
stand(guard, meshes, int(baked.frame_start))
clean_materials(meshes)
push_track(guard, baked)
guard.name = "Guard"
for item in meshes:
    item.name = "GuardBody"
export(guard, meshes)
triangles = sum(sum(len(p.vertices) - 2 for p in m.data.polygons) for m in meshes)
print(f"{TARGET}: {triangles} triangles, {len(guard.data.bones)} bones, clip {CLIP_NAME} "
      f"frames {int(baked.frame_start)}-{int(baked.frame_end)}, "
      f"{TARGET.stat().st_size / 1e6:.1f} MB")
