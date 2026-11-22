extends SceneTree
## Writes Ethan's upper-body rifle clips (Assignment 7, CHANGE-BRIEF.md's revision #393-#396):
## game/animations/ethan_rifle.tres, an AnimationLibrary built from the motion-captured clips
## tools/art/convert_mixamo.py puts in ethan.glb. Its glTF export samples every bone, so these
## clips also hold the hips and legs, frozen; this keeps only the bones above the waist (spine,
## neck, head, shoulders, arms, hands, fingers), every key as imported, carrying any hips turn onto
## the first spine bone (spine' = rest_hips^-1 * hips * spine), so a second player (UpperBody) lays
## them over his own player's Idle, Walk, Run or the rifle's gaits. Loop modes as ethan.glb.import
## sets them. Built by this committed script, never at runtime. Run from the repository root:
##   HOME=.scratch-home /Applications/Godot.app/Contents/MacOS/Godot --headless --path game \
##       --script ../tools/art/make_rifle_upper_body.gd

const RIG := "res://features/characters/ethan/ethan.glb"
const TARGET := "res://animations/ethan_rifle.tres"
const UPPER := ["Spine", "Neck", "Head", "Shoulder", "Arm", "Hand"]
const CLIPS := ["RifleIdleA", "RifleIdleB", "RifleAim", "RifleFire", "RifleAimDown", "RifleReload",
	"RifleHit", "RifleGrab", "RifleAway"]
const FPS := 30.0
const HIPS := "mixamorig_Hips"
const SPINE := "mixamorig_Spine"

var _skeleton: Skeleton3D


func _initialize() -> void:
	var model := (load(RIG) as PackedScene).instantiate() as Node3D
	var player := model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	_skeleton = model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var library := AnimationLibrary.new()
	for clip_name in CLIPS:
		library.add_animation(clip_name, _upper(player.get_animation(clip_name)))
	var error := ResourceSaver.save(library, TARGET)
	for clip_name in library.get_animation_list():
		var clip := library.get_animation(clip_name)
		print("UPPER: %s %d tracks, %.0f frames, loop %d" % [clip_name, clip.get_track_count(),
			roundf(clip.length * FPS) + 1, clip.loop_mode])
	print("UPPER: saved %s (%s)" % [TARGET, error_string(error)])
	model.free()
	quit(0 if error == OK else 1)


func _upper(source: Animation) -> Animation:
	var clip := source.duplicate(true) as Animation
	var hips := _rotation_track(clip, HIPS)
	var spine := _rotation_track(clip, SPINE)
	var rest := _skeleton.get_bone_rest(_skeleton.find_bone(HIPS)).basis.get_rotation_quaternion()
	for k in clip.track_get_key_count(spine):
		var time := clip.track_get_key_time(spine, k)
		var turned: Quaternion = rest.inverse() * clip.rotation_track_interpolate(hips, time) \
			* (clip.track_get_key_value(spine, k) as Quaternion)
		clip.track_set_key_value(spine, k, turned.normalized())
	for t in range(clip.get_track_count() - 1, -1, -1):
		var path := clip.track_get_path(t)
		var bone := String(path.get_concatenated_subnames()) if path.get_subname_count() else ""
		var keep := false
		for part in UPPER:
			keep = keep or bone.contains(part)
		if not keep:
			clip.remove_track(t)
	clip.step = 1.0 / FPS
	return clip


func _rotation_track(clip: Animation, bone: String) -> int:
	for t in clip.get_track_count():
		if clip.track_get_type(t) == Animation.TYPE_ROTATION_3D \
				and String(clip.track_get_path(t).get_concatenated_subnames()) == bone:
			return t
	push_error("no rotation track for " + bone)
	return -1
