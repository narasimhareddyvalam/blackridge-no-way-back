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
        --python tools/art/convert_patrol_guard.py [-- patrol_guard | syndicate_man]

Mission 3's syndicate men (#359) are converted the same way (the job "syndicate_man"): "guard"
by bumstrum on Sketchfab (CC BY 4.0; source_assets/sketchfab/32_syndicate_man/), a man in a black
jacket, gloves and boots, his own rig's bones mapped to Mixamo's names (`BUMSTRUM`), his cigarette
dropped and his pistol written apart as the game's pistol (`game/features/weapons/pistol/`).
"""

import math
import pathlib
import re
import sys

import bpy
from mathutils import Matrix, Vector

CLIPS = pathlib.Path("source_assets/mixamo")
BUMSTRUM = {"hips_01": "Hips", "spine_2_012": "Spine", "chest_2_013": "Spine2",
    "neck_2_063": "Neck", "head_2_064": "Head",
    "L_shoulder_2_014": "LeftShoulder", "L_arm_2_015": "LeftArm", "L_elbow_2_016": "LeftForeArm",
    "L_wrist_2_017": "LeftHand", "R_shoulder_2_039": "RightShoulder", "R_arm_2_040": "RightArm",
    "R_elbow_2_041": "RightForeArm", "R_wrist_2_042": "RightHand",
    "L_leg_2_02": "LeftUpLeg", "L_knee_2_03": "LeftLeg", "L_ankle_2_04": "LeftFoot",
    "L_foot_2_05": "LeftToeBase", "R_leg_2_07": "RightUpLeg", "R_knee_2_08": "RightLeg",
    "R_ankle_2_09": "RightFoot", "R_foot_2_010": "RightToeBase",
    "L_thumb1_2_018": "LeftHandThumb1", "L_thumb2_2_019": "LeftHandThumb2",
    "L_thumb3_2_020": "LeftHandThumb3", "L_point1_2_022": "LeftHandIndex1",
    "L_point2_2_023": "LeftHandIndex2", "L_point3_2_024": "LeftHandIndex3",
    "L_middle1_2_026": "LeftHandMiddle1", "L_middle2_2_027": "LeftHandMiddle2",
    "L_middle3_2_028": "LeftHandMiddle3", "L_ring1_2_031": "LeftHandRing1",
    "L_ring2_2_032": "LeftHandRing2", "L_ring3_2_033": "LeftHandRing3",
    "L_pink1_2_035": "LeftHandPinky1", "L_pink2_2_036": "LeftHandPinky2",
    "L_pink3_2_037": "LeftHandPinky3", "R_thumb1_2_043": "RightHandThumb1",
    "R_thumb2_2_044": "RightHandThumb2", "R_thumb3_2_045": "RightHandThumb3",
    "R_point1_2_00": "RightHandIndex1", "R_point2_2_047": "RightHandIndex2",
    "R_point3_2_048": "RightHandIndex3", "R_middle1_2_050": "RightHandMiddle1",
    "R_middle2_2_051": "RightHandMiddle2", "R_middle3_2_052": "RightHandMiddle3",
    "R_ring1_2_055": "RightHandRing1", "R_ring2_2_056": "RightHandRing2",
    "R_ring3_2_057": "RightHandRing3", "R_pink1_2_059": "RightHandPinky1",
    "R_pink2_2_060": "RightHandPinky2", "R_pink3_2_061": "RightHandPinky3"}
PISTOL_PARTS = ("pistol", "slide", "trigger", "clip", "bullet")
CHARACTERS = {
    "patrol_guard": {"source": "source_assets/sketchfab/29_security_guard/security_guard_raw.glb",
        "target": "game/features/characters/patrol_guard/patrol_guard.glb", "name": "PatrolGuard",
        "bones": None, "drop": (), "pistol": None},
    "syndicate_man": {"source": "source_assets/sketchfab/32_syndicate_man/syndicate_man_raw.glb",
        "target": "game/features/characters/syndicate_man/syndicate_man.glb",
        "name": "SyndicateMan", "bones": BUMSTRUM, "drop": ("cigarette",) + PISTOL_PARTS,
        "pistol": "game/features/weapons/pistol/pistol.glb"},
}
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


def load_guard(job):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=job["source"])
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
    mapping = job["bones"]
    for bone in armature.data.bones:
        bone.name = "mixamorig:" + mapping[bone.name] if mapping and bone.name in mapping \
            else SUFFIX.sub("", bone.name)
    for item in meshes:
        for group in item.vertex_groups:
            group.name = "mixamorig:" + mapping[group.name] if mapping and group.name in mapping \
                else SUFFIX.sub("", group.name)
    pistol = [m for m in meshes if job["pistol"]
        and any(part in m.name.lower() for part in PISTOL_PARTS)]
    for item in pistol:
        meshes.remove(item)
        world = item.matrix_world.copy()
        item.parent = None
        item.matrix_world = world
    for item in [m for m in meshes if any(part in m.name.lower() for part in job["drop"])]:
        meshes.remove(item)
        bpy.data.objects.remove(item, do_unlink=True)
    bpy.ops.object.select_all(action="DESELECT")
    for item in [armature] + meshes:
        item.select_set(True)
    bpy.context.view_layer.objects.active = armature
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    armature.data.pose_position = "POSE"
    return armature, meshes, pistol


def _write_pistol(job, parts, scale):
    """The pistol's parts written apart (`job["pistol"]`), scaled as the man was (`scale`), so at
    their real size."""
    if not parts:
        return
    for part in parts:
        for modifier in list(part.modifiers):
            part.modifiers.remove(modifier)
        part.matrix_world = Matrix.Diagonal((scale, scale, scale, 1.0)) @ part.matrix_world
    bpy.ops.object.select_all(action="DESELECT")
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    corners = [part.matrix_world @ Vector(c) for part in parts for c in part.bound_box]
    size = Vector((max(c.x for c in corners) - min(c.x for c in corners),
        max(c.y for c in corners) - min(c.y for c in corners),
        max(c.z for c in corners) - min(c.z for c in corners)))
    print(f"  pistol {size.x:.3f} x {size.y:.3f} x {size.z:.3f} m")
    target = pathlib.Path(job["pistol"])
    target.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(target), export_format="GLB", use_selection=True,
        export_image_format="WEBP", export_image_quality=QUALITY, export_animations=False)


def import_clip(name):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=str(CLIPS / name))
    new = [o for o in bpy.data.objects if o not in before]
    clip = next(o for o in new if o.type == "ARMATURE")
    for bone in clip.pose.bones:
        bone.name = re.sub(r"^mixamorig\d*:", "mixamorig:", bone.name)
    return clip, new


def mesh_height(objects):
    """How tall the meshes among `objects` stand, for scaling the hips' motion by body size: a rig's
    joints may not follow its body (bumstrum's hip bone rests at the waist), its mesh does."""
    depsgraph = bpy.context.evaluated_depsgraph_get()
    low, high = math.inf, -math.inf
    for item in [o for o in objects if o.type == "MESH"]:
        evaluated = item.evaluated_get(depsgraph)
        mesh = evaluated.to_mesh()
        for vertex in mesh.vertices:
            z = (evaluated.matrix_world @ vertex.co).z
            low, high = min(low, z), max(high, z)
        evaluated.to_mesh_clear()
    return high - low


ALIGNED = ("Shoulder", "Arm", "Hand", "UpLeg", "Leg", "Foot", "ToeBase")


def rest_alignment(guard, clip):
    """For each limb bone both rigs have, the turn that points the guard's rest bone (head to its
    first shared child's head) the way the clip's rest bone points: a rig resting in an A-pose
    (bumstrum's, arms 40 degrees down) is read as the clip's T-pose, so its arms are not posed 40
    degrees low."""
    align = {}
    guard_world, clip_world = guard.matrix_world, clip.matrix_world
    for bone in guard.data.bones:
        source = clip.data.bones.get(bone.name)
        if source is None or not any(part in bone.name for part in ALIGNED):
            continue
        child = next((c for c in bone.children if clip.data.bones.get(c.name) is not None), None)
        if child is None:
            continue
        mine = (guard_world @ child.head_local) - (guard_world @ bone.head_local)
        theirs = (clip_world @ clip.data.bones[child.name].head_local) \
            - (clip_world @ source.head_local)
        if mine.length < 1e-4 or theirs.length < 1e-4:
            continue
        align[bone.name] = mine.normalized().rotation_difference(theirs.normalized()).to_matrix()
    return align


def bake(guard, clip, name, ratio):
    source_action = clip.animation_data.action
    start, end = (int(round(v)) for v in source_action.frame_range)
    align = rest_alignment(guard, clip)
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
            world_rest = align.get(bone.name, Matrix.Identity(3)) @ guard_turn @ rotation(rest)
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
    return scale


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


def main(job):
    guard, meshes, pistol = load_guard(job)
    scale = stand(guard, meshes)
    _write_pistol(job, pistol, scale)
    baked = []
    for file, name, moving in JOBS:
        clip, objects = import_clip(file)
        source_action = clip.animation_data.action
        bpy.context.scene.frame_set(int(source_action.frame_range[0]))
        action = bake(guard, clip, name, HEIGHT / mesh_height(objects))
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
    guard.name = job["name"]
    target = pathlib.Path(job["target"])
    target.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for item in [guard] + meshes:
        item.select_set(True)
    bpy.context.view_layer.objects.active = guard
    bpy.ops.export_scene.gltf(filepath=str(target), export_format="GLB", use_selection=True,
                              export_animation_mode="NLA_TRACKS", export_force_sampling=True,
                              export_anim_slide_to_zero=True, export_image_format="WEBP",
                              export_image_quality=QUALITY, export_apply=False, export_yup=True,
                              export_cameras=False, export_lights=False, export_extras=False)
    triangles = sum(sum(len(p.vertices) - 2 for p in m.data.polygons) for m in meshes)
    clips = ", ".join(f"{a.name} {int(a.frame_start)}-{int(a.frame_end)}" for a in baked)
    print(f"{target}: {triangles} triangles, {len(guard.data.bones)} bones, clips {clips}, "
          f"{target.stat().st_size / 1e6:.1f} MB")


wanted = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else list(CHARACTERS)
for job_name in wanted:
    main(CHARACTERS[job_name])
