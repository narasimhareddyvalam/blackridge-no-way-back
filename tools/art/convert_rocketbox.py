"""Convert Microsoft Rocketbox characters and their clips into the game: the gate guard (C55),
Security_Male_01 with a seated idle, and bay 9's dock worker (C58), Construction_Male_08 with a
standing idle, a walk, the reach to the van doors' hasp, and at his desk (step 3 of #253): sitting
down to it and standing up from it, a seated idle at it, checking a document and noting in it.

Run from the repository root (a job's name after "--" converts that one alone):
    /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python-exit-code 1 \\
        --python tools/art/convert_rocketbox.py [-- guard | dock_worker]

It reads source_assets/rocketbox/ (its README.md lists the files) and writes
game/features/characters/guard/guard.glb and game/features/characters/dock_worker/dock_worker.glb.
What it changes:
- each clip is baked onto the character bone by bone. A clip's rest pose is its own first
  frame, so each bone takes the turn the clip gives it in the armature's space, on the
  character's own bone lengths, and the pelvis also takes the clip's place; in SitDown,
  SitIdle-loop and StandUp it takes the clip's root motion too (its armature object's), so he
  sits into the chair, stays at the seat's height and rises from it;
- the seated guard is turned to face Blender's -Y, a glTF model's front (the dock worker
  already faces it), and each character is moved so that his shoes stand at the origin, under
  his hips;
- one roughness per part replaces Rocketbox's specular maps, and the colour and normal maps are
  halved to 1024 pixels and stored as WebP;
- the clips are named as Godot imports them: SitIdle-loop, Idle-loop and Walk-loop loop; Seal,
  SitDown, StandUp, Check and Note play once.
"""

import math
import pathlib
import sys

import bpy
from mathutils import Matrix, Vector

SOURCE = pathlib.Path("source_assets/rocketbox")
CLIPS = SOURCE / "Animations"
MAX_TEXTURE = 1024
## Clips whose root motion is kept: Rocketbox's "xyz" clips carry it on the armature object (its
## Bip01 node), not a bone, so it is taken from the object relative to the character's own.
MOVING = {"SitDown", "SitIdle-loop", "StandUp"}
QUALITY = 90
JOBS = {
    "guard": {
        "character": SOURCE / "Security_Male_01",
        "fbx": "Security_Male_01.fbx",
        "prefix": "m171",
        "clips": [("SitIdle-loop", CLIPS / "m_sit_chair_breathe_01.max.fbx")],
        "roughness": {"head": 0.56, "body": 0.72, "equipment": 0.5},
        "turn": True,
        "names": ("Guard", "GuardBody"),
        "target": pathlib.Path("game/features/characters/guard/guard.glb"),
    },
    "dock_worker": {
        "character": SOURCE / "Construction_Male_08",
        "fbx": "Construction_Male_08.fbx",
        "prefix": "m108",
        "clips": [("Idle-loop", CLIPS / "m_idle_neutral_01.max.fbx"),
                  ("Walk-loop", CLIPS / "m_walk_neutral_01.max.fbx"),
                  ("Seal", CLIPS / "m_try_door_outwards.max.fbx"),
                  ("SitDown", CLIPS / "m_sit_down_table_right.max.fbx"),
                  ("SitIdle-loop", CLIPS / "m_sit_table_idle_neutral_01.max.fbx"),
                  ("StandUp", CLIPS / "m_sit_stand_up_table_right.max.fbx"),
                  ("Check", CLIPS / "m_documents_check.max.fbx"),
                  ("Note", CLIPS / "m_documents_note.max.fbx")],
        "roughness": {"head": 0.56, "body": 0.72, "helmet": 0.35},
        "turn": False,
        "names": ("DockWorker", "DockWorkerBody"),
        "target": pathlib.Path("game/features/characters/dock_worker/dock_worker.glb"),
    },
}


def import_fbx(path):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=str(path))
    for item in [o for o in bpy.data.objects if o not in before and o.type == "EMPTY"]:
        bpy.data.objects.remove(item, do_unlink=True)
    new = [o for o in bpy.data.objects if o not in before]
    return next(o for o in new if o.type == "ARMATURE"), new


def bake(character, clip, name, moving=False):
    source_action = clip.animation_data.action
    start, end = (int(round(value)) for value in source_action.frame_range)
    if character.animation_data is not None:
        character.animation_data.action = None
    bones = sorted(character.pose.bones, key=lambda bone: len(bone.parent_recursive))
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
            posing = source.matrix
            if moving and bone.parent is None:
                posing = character.matrix_world.inverted() @ clip.matrix_world @ posing
            turn = posing.to_3x3().normalized().to_4x4()
            at = posing.translation if bone.parent is None else base.translation
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
    action = character.animation_data.action
    action.name = name
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


def stand(character, meshes, frame, turn_to_front):
    bpy.context.scene.frame_set(frame)
    if turn_to_front:
        hips = world_bone(character, "Bip01 Pelvis")
        knees = (world_bone(character, "Bip01 L Calf")
                 + world_bone(character, "Bip01 R Calf")) / 2.0
        facing = Vector((knees.x - hips.x, knees.y - hips.y))
        turn = math.atan2(-1.0, 0.0) - math.atan2(facing.y, facing.x)
        character.matrix_world = Matrix.Rotation(turn, 4, "Z") @ character.matrix_world
        bpy.context.view_layer.update()
        print(f"  turned {math.degrees(turn):.1f} deg to face -Y")
    hips = world_bone(character, "Bip01 Pelvis")
    character.matrix_world = Matrix.Translation((-hips.x, -hips.y, -lowest_point(meshes))) \
        @ character.matrix_world
    bpy.context.view_layer.update()
    hips = world_bone(character, "Bip01 Pelvis")
    print(f"  hips {hips.z:.3f} m above his shoes")


def clean_materials(meshes, job):
    for item in meshes:
        for slot in item.material_slots:
            material = slot.material
            part = material.name.split("_", 1)[1]
            tree = material.node_tree
            for node in [n for n in tree.nodes if n.type in {"TEX_IMAGE", "NORMAL_MAP"}]:
                tree.nodes.remove(node)
            shader = next(n for n in tree.nodes if n.type == "BSDF_PRINCIPLED")
            textures = job["character"] / "Textures"
            colour = tree.nodes.new("ShaderNodeTexImage")
            colour.image = bpy.data.images.load(
                str(textures / f"{job['prefix']}_{part}_color.tga"))
            tree.links.new(colour.outputs["Color"], shader.inputs["Base Color"])
            normal = tree.nodes.new("ShaderNodeTexImage")
            normal.image = bpy.data.images.load(
                str(textures / f"{job['prefix']}_{part}_normal.tga"))
            normal.image.colorspace_settings.name = "Non-Color"
            bend = tree.nodes.new("ShaderNodeNormalMap")
            tree.links.new(normal.outputs["Color"], bend.inputs["Color"])
            tree.links.new(bend.outputs["Normal"], shader.inputs["Normal"])
            shader.inputs["Roughness"].default_value = job["roughness"][part]
            shader.inputs["Metallic"].default_value = 0.0
            for image in (colour.image, normal.image):
                while image.size[0] > MAX_TEXTURE:
                    image.scale(image.size[0] // 2, image.size[1] // 2)


def push_track(character, action):
    data = character.animation_data
    data.action = None
    track = data.nla_tracks.new()
    track.name = action.name
    strip = track.strips.new(action.name, int(action.frame_start), action)
    if hasattr(strip, "action_slot") and action.slots and strip.action_slot is None:
        strip.action_slot = action.slots[0]


def export(character, meshes, target):
    bpy.ops.object.select_all(action="DESELECT")
    for item in [character] + meshes:
        item.select_set(True)
    bpy.context.view_layer.objects.active = character
    target.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(target), export_format="GLB", use_selection=True,
                              export_animation_mode="NLA_TRACKS", export_force_sampling=True,
                              export_anim_slide_to_zero=True,
                              export_image_format="WEBP", export_image_quality=QUALITY,
                              export_apply=False, export_yup=True, export_cameras=False,
                              export_lights=False, export_extras=False)


def convert(job):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    character, objects = import_fbx(job["character"] / "Export" / job["fbx"])
    meshes = [o for o in objects if o.type == "MESH"]
    baked = []
    for name, path in job["clips"]:
        clip, clip_objects = import_fbx(path)
        moving = name in MOVING
        source_action = clip.animation_data.action
        for action in [a for a in bpy.data.actions if a is not source_action and a not in baked]:
            bpy.data.actions.remove(action)
        baked.append(bake(character, clip, name, moving))
        for item in clip_objects:
            bpy.data.objects.remove(item, do_unlink=True)
        bpy.data.actions.remove(source_action)
    character.animation_data.action = baked[0]
    stand(character, meshes, int(baked[0].frame_start), job["turn"])
    clean_materials(meshes, job)
    for action in baked:
        push_track(character, action)
    character.name, body = job["names"]
    for item in meshes:
        item.name = body
    export(character, meshes, job["target"])
    triangles = sum(sum(len(p.vertices) - 2 for p in m.data.polygons) for m in meshes)
    clips = ", ".join(f"{a.name} {int(a.frame_start)}-{int(a.frame_end)}" for a in baked)
    print(f"{job['target']}: {triangles} triangles, {len(character.data.bones)} bones, clips "
          f"{clips}, {job['target'].stat().st_size / 1e6:.1f} MB")


wanted = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else list(JOBS)
for job_name in wanted:
    convert(JOBS[job_name])
