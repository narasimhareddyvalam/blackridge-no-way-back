"""Convert the Mixamo downloads into the two game characters (decision C27).

Each character is one .glb: its mesh, a skeleton whose bones are all named "mixamorig:...",
and one animation per NLA track. The raw downloads stay out of Git; these .glb files are
committed. The conversion:

- keeps the colour, normal and hair-alpha maps, and drops Mixamo's gloss and specular maps,
  which made the clothes look like plastic. Each part (skin, suit, shoes ...) gets its own
  copy of the shared material with its own roughness, and nothing is metallic;
- clips hair at half alpha (glTF MASK), so hair cards draw in depth order and cast shadows;
- tints the pedestrian's grey polo charcoal, so he is hard to see at night;
- halves textures larger than 2048 pixels and writes them as WebP;
- renames every bone prefix ("mixamorig7:", "mixamorig12:") to "mixamorig:", so the
  animations of one character play on the other;
- makes the walk, run and push cycles walk in place (the game moves the character) and
  prints their ground speed; the car and hit clips keep their own motion;
- makes the stair climb climb in place too: its forward travel and its rise both taken out, so
  that the game carries him up the stair's own incline, and prints both for a cycle (#253);
- takes Push Stop's travel out of it too, the hips' forward travel at knots every six frames
  with straight lines between, and prints those knots: the game moves Ethan by the same
  knots, so his planted feet stay put (step 2e, #239-#240);
- names the idle, walk, run and push tracks "<name>-loop", Godot's import hint for a looping
  clip; Godot removes the suffix on import;
- keeps only the upper body (spine, neck, head, shoulders, arms, hands, fingers) in the pistol
  clips, so a second player can lay them over his legs' Idle, Walk or Run (Assignment 7, #390);
  their loop modes are set in ethan.glb.import, not by a name suffix;
- exports the pedestrian at real size: Mixamo's 1/100 scale and 90-degree turn are baked
  into his skeleton and mesh, and the clips' movement is scaled to match, because the
  physics bones of his ragdoll cannot hang from a scaled skeleton.

Usage, from the repository root (add "-- ethan" to rebuild only him):
    /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup \\
        --python tools/art/convert_mixamo.py
"""

import pathlib
import sys

import bpy

SOURCE = pathlib.Path("source_assets/mixamo")
OUT = pathlib.Path("game/features/characters")
PREFIX = "mixamorig:"
MAX_TEXTURE = 2048
QUALITY = 90
ROUGHNESS = {"Body": 0.5, "Hair": 0.55, "Eyelashes": 0.6, "Suit": 0.82, "Shirt": 0.8,
             "Pants": 0.85, "Tie": 0.55, "Belt": 0.45, "Shoes": 0.4, "Sneakers": 0.75}
TINT = {("pedestrian", "Shirt"): (0.08, 0.087, 0.098)}
IN_PLACE = {"Walk", "WalkBack", "Run", "Push", "PullBack"}
CLIMBS = {"StairsUp"}
STOPS = {"PushStop"}
STOP_KNOTS = 6
REAL_SIZE = {"pedestrian"}
LOOPING = IN_PLACE | CLIMBS | {"Idle"}
UPPER_BODY = {"PistolIdle", "PistolReload"}
UPPER_BONES = ("Spine", "Neck", "Head", "Shoulder", "Arm", "Hand")
FPS = 30.0
CHARACTERS = {
    "ethan": ("Breathing Idle.fbx", "Idle", [
        ("Walking.fbx", "Walk"), ("Walking Backwards.fbx", "WalkBack"),
        ("Running.fbx", "Run"), ("Entering Car.fbx", "EnterVan"),
        ("Exiting Car.fbx", "ExitVan"), ("Pushing.fbx", "Push"),
        ("Push Stop.fbx", "PushStop"), ("Running Up Stairs.fbx", "StairsUp"),
        ("Pull Heavy Object.fbx", "PullBack"), ("Pistol Idle.fbx", "PistolIdle"),
        ("Reloading.fbx", "PistolReload")]),
    "pedestrian": ("Hit By Car.fbx", "HitByVan", [("Walking.fbx", "Walk"),
                                                    ("Breathing Idle.fbx", "Idle")]),
}


def import_fbx(name):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=str(SOURCE / name))
    new = [o for o in bpy.data.objects if o not in before]
    armature = next(o for o in new if o.type == "ARMATURE")
    return armature, new


def fcurves(action):
    for layer in action.layers:
        for strip in layer.strips:
            for bag in strip.channelbags:
                yield from bag.fcurves


def rename_prefix(armature):
    for bone in armature.data.bones:
        if ":" in bone.name:
            bone.name = PREFIX + bone.name.split(":", 1)[1]


def retarget(action):
    for curve in fcurves(action):
        path = curve.data_path
        if 'pose.bones["' in path:
            start = path.index('["') + 2
            end = path.index('"]')
            bone = path[start:end]
            if ":" in bone:
                curve.data_path = path[:start] + PREFIX + bone.split(":", 1)[1] + path[end:]


def hip_curves(action):
    return [c for c in fcurves(action)
            if c.data_path.endswith('Hips"].location')]


def walk_in_place(action):
    curves = hip_curves(action)
    forward = max(curves, key=lambda c: abs(c.keyframe_points[-1].co[1]
                                            - c.keyframe_points[0].co[1]))
    first, last = forward.keyframe_points[0].co, forward.keyframe_points[-1].co
    slope = (last[1] - first[1]) / (last[0] - first[0])
    for key in forward.keyframe_points:
        for point in (key.co, key.handle_left, key.handle_right):
            point[1] -= slope * (point[0] - first[0])
    forward.update()
    return slope * FPS * 0.01


def climb_in_place(action):
    """Takes the even forward travel and the even rise out of the hips; returns both, in metres
    a second."""
    moved = {}
    for curve in hip_curves(action):
        first, last = curve.keyframe_points[0].co, curve.keyframe_points[-1].co
        if abs(last[1] - first[1]) < 1.0:
            continue
        slope = (last[1] - first[1]) / (last[0] - first[0])
        for key in curve.keyframe_points:
            for point in (key.co, key.handle_left, key.handle_right):
                point[1] -= slope * (point[0] - first[0])
        curve.update()
        moved[curve.array_index] = slope * FPS * 0.01
    return moved


def stop_in_place(action):
    curves = hip_curves(action)
    forward = max(curves, key=lambda c: abs(c.keyframe_points[-1].co[1]
                                            - c.keyframe_points[0].co[1]))
    first = forward.keyframe_points[0].co[0]
    last = forward.keyframe_points[-1].co[0]
    knots = [first + step for step in range(0, int(round(last - first)) + 1, STOP_KNOTS)]
    if knots[-1] < last:
        knots.append(last)
    start = forward.evaluate(first)
    travel = [forward.evaluate(frame) - start for frame in knots]

    def along(frame):
        if frame <= knots[0]:
            return travel[0]
        for a, b, va, vb in zip(knots, knots[1:], travel, travel[1:]):
            if frame <= b:
                return va + (vb - va) * (frame - a) / (b - a)
        return travel[-1]

    for key in forward.keyframe_points:
        for point in (key.co, key.handle_left, key.handle_right):
            point[1] -= along(point[0])
    forward.update()
    sign = 1.0 if travel[-1] >= 0.0 else -1.0
    return [sign * value * 0.01 for value in travel]


def upper_body_only(action):
    """Removes every curve of a bone below the waist (the hips, legs and feet); returns how many
    curves are kept."""
    kept = 0
    for bag_curves in [list(fcurves(action))]:
        for curve in bag_curves:
            path = curve.data_path
            if 'pose.bones["' not in path:
                continue
            bone = path[path.index('["') + 2:path.index('"]')]
            if any(part in bone for part in UPPER_BONES):
                kept += 1
                continue
            for layer in action.layers:
                for strip in layer.strips:
                    for bag in strip.channelbags:
                        if curve in list(bag.fcurves):
                            bag.fcurves.remove(curve)
    return kept


def fit_range(action):
    keys = [k.co[0] for c in fcurves(action) for k in c.keyframe_points]
    action.use_frame_range = True
    action.frame_start, action.frame_end = min(keys), max(keys)


def prepare(action, label):
    action.name = label
    action.use_fake_user = True
    retarget(action)
    fit_range(action)
    if label in IN_PLACE:
        print(f"  {label}: ground speed {abs(walk_in_place(action)):.3f} m/s, "
              f"cycle {(action.frame_end - action.frame_start) / FPS:.3f} s")
    if label in CLIMBS:
        moved = climb_in_place(action)
        cycle = (action.frame_end - action.frame_start) / FPS
        print(f"  {label}: cycle {cycle:.3f} s, travel and rise a cycle "
              + ", ".join(f"axis {axis} {speed * cycle:.3f} m" for axis, speed in
                          sorted(moved.items())))
    if label in UPPER_BODY:
        print(f"  {label}: upper body only, {upper_body_only(action)} curves kept, "
              f"{(action.frame_end - action.frame_start + 1):.0f} frames")
    if label in STOPS:
        knots = stop_in_place(action)
        print(f"  {label}: travel at every {STOP_KNOTS}th frame from the first, "
              f"{(action.frame_end - action.frame_start) / FPS:.3f} s: "
              f"[{', '.join(f'{knot:.3f}' for knot in knots)}] m")


def take_action(name, label):
    armature, objects = import_fbx(name)
    action = armature.animation_data.action
    prepare(action, label)
    for item in objects:
        data = item.data
        bpy.data.objects.remove(item, do_unlink=True)
        if data is not None and data.users == 0:
            if isinstance(data, bpy.types.Mesh):
                bpy.data.meshes.remove(data)
            elif isinstance(data, bpy.types.Armature):
                bpy.data.armatures.remove(data)
    return action


def push_tracks(armature, actions):
    data = armature.animation_data or armature.animation_data_create()
    data.action = None
    for label, action in actions:
        track = data.nla_tracks.new()
        track.name = f"{label}-loop" if label in LOOPING else label
        strip = track.strips.new(track.name, int(action.frame_start), action)
        if hasattr(strip, "action_slot") and action.slots and strip.action_slot is None:
            strip.action_slot = action.slots[0]


def unlink(tree, socket):
    for link in list(socket.links):
        tree.links.remove(link)


def clip_alpha(tree, shader):
    source = shader.inputs["Alpha"].links[0].from_socket
    clip = tree.nodes.new("ShaderNodeMath")
    clip.operation = "ROUND"
    tree.links.new(source, clip.inputs[0])
    tree.links.new(clip.outputs[0], shader.inputs["Alpha"])


def socket(sockets, identifier):
    return next(s for s in sockets if s.identifier == identifier)


def tint(tree, shader, colour):
    source = shader.inputs["Base Color"].links[0].from_socket
    mix = tree.nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.blend_type = "MULTIPLY"
    socket(mix.inputs, "Factor_Float").default_value = 1.0
    tree.links.new(source, socket(mix.inputs, "A_Color"))
    socket(mix.inputs, "B_Color").default_value = (*colour, 1.0)
    tree.links.new(socket(mix.outputs, "Result_Color"), shader.inputs["Base Color"])


def clean_materials(name, meshes):
    for item in meshes:
        part = item.name.split("_", 1)[1]
        material = item.material_slots[0].material.copy()
        material.name = item.name
        item.material_slots[0].material = material
        tree = material.node_tree
        shader = next(n for n in tree.nodes if n.type == "BSDF_PRINCIPLED")
        for socket_name in ("Roughness", "Specular IOR Level", "Metallic"):
            unlink(tree, shader.inputs[socket_name])
        shader.inputs["Roughness"].default_value = ROUGHNESS[part]
        shader.inputs["Specular IOR Level"].default_value = 0.5
        shader.inputs["Metallic"].default_value = 0.0
        if part in ("Hair", "Eyelashes"):
            clip_alpha(tree, shader)
        else:
            unlink(tree, shader.inputs["Alpha"])
            shader.inputs["Alpha"].default_value = 1.0
        if (name, part) in TINT:
            tint(tree, shader, TINT[(name, part)])
    images = {n.image for item in meshes for n in item.material_slots[0].material.node_tree.nodes
              if n.type == "TEX_IMAGE" and n.image}
    for image in images:
        if image.size[0] > MAX_TEXTURE:
            image.scale(image.size[0] // 2, image.size[1] // 2)


def real_size(armature, meshes, actions):
    scale = armature.scale.x
    bpy.ops.object.select_all(action="DESELECT")
    for item in [armature] + meshes:
        item.select_set(True)
    bpy.context.view_layer.objects.active = armature
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    for action in actions:
        for curve in fcurves(action):
            if curve.data_path.endswith(".location"):
                for key in curve.keyframe_points:
                    for point in (key.co, key.handle_left, key.handle_right):
                        point[1] *= scale
                curve.update()


def export(name, armature, meshes):
    bpy.ops.object.select_all(action="DESELECT")
    for item in [armature] + meshes:
        item.select_set(True)
    bpy.context.view_layer.objects.active = armature
    target = OUT / name / f"{name}.glb"
    target.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(target), export_format="GLB", use_selection=True,
                              export_animation_mode="NLA_TRACKS", export_force_sampling=True,
                              export_anim_slide_to_zero=True,
                              export_image_format="WEBP", export_image_quality=QUALITY,
                              export_apply=False, export_yup=True, export_cameras=False,
                              export_lights=False, export_extras=False)
    return target


def build(name, base_file, base_label, extras):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    armature, objects = import_fbx(base_file)
    rename_prefix(armature)
    base_action = armature.animation_data.action
    prepare(base_action, base_label)
    actions = [(base_label, base_action)]
    for file_name, label in extras:
        actions.append((label, take_action(file_name, label)))
    push_tracks(armature, actions)
    meshes = [o for o in objects if o.type == "MESH"]
    clean_materials(name, meshes)
    if name in REAL_SIZE:
        real_size(armature, meshes, [action for _, action in actions])
    target = export(name, armature, meshes)
    triangles = sum(sum(len(p.vertices) - 2 for p in m.data.polygons) for m in meshes)
    print(f"{target}: {triangles} triangles, {len(armature.data.bones)} bones, "
          f"animations {[label for label, _ in actions]}, "
          f"{target.stat().st_size / 1e6:.1f} MB")


ONLY = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
for character, (base_file, base_label, extras) in CHARACTERS.items():
    if not ONLY or character in ONLY:
        build(character, base_file, base_label, extras)
