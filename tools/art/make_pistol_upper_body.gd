extends SceneTree
## Writes Ethan's upper-body pistol clips (Assignment 7, CHANGE-BRIEF.md's revision #386-#390):
## game/animations/ethan_pistol.tres, an AnimationLibrary built from the motion-captured clips that
## tools/art/convert_mixamo.py puts in ethan.glb. The glTF export samples every bone, so the
## imported PistolIdle and PistolReload also hold the hips and legs, frozen; played over his walk
## they would stop his legs. This keeps only the tracks of the bones above the waist (spine, neck,
## head, shoulders, arms, hands, fingers), every key as imported, so a second player can lay them
## over his own player's Idle, Walk or Run. The captured stances also turn at the hips (an aim
## stands side-on), and that turn would be lost with the hips' track, pointing his chest and gun
## where his feet point; so the hips' rotation away from their rest is carried onto the first spine
## bone at every key (spine' = rest_hips^-1 * hips * spine), the standard upper-body retarget: his
## shoulders, arms and the gun face as captured while his hips and legs keep his own walk.
##   PistolIdle    all 250 frames of Mixamo's "Pistol Idle", LOOP_LINEAR
##   PistolReload  all 100 frames of Mixamo's "Reloading", LOOP_NONE
##   PistolAim     all 41 frames of Mixamo's "Pistol Aim", both arms out, LOOP_LINEAR
## Built by this committed script, never at runtime. Run from the repository root:
##   HOME=.scratch-home /Applications/Godot.app/Contents/MacOS/Godot --headless --path game \
##       --script ../tools/art/make_pistol_upper_body.gd

const RIG := "res://features/characters/ethan/ethan.glb"
const TARGET := "res://animations/ethan_pistol.tres"
const UPPER := ["Spine", "Neck", "Head", "Shoulder", "Arm", "Hand"]
const FPS := 30.0
const HIPS := "mixamorig_Hips"
const SPINE := "mixamorig_Spine"

var _skeleton: Skeleton3D


func _initialize() -> void:
	var model := (load(RIG) as PackedScene).instantiate() as Node3D
	var player := model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	_skeleton = model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var library := AnimationLibrary.new()
	library.add_animation("PistolIdle", _upper(player.get_animation("PistolIdle"),
		Animation.LOOP_LINEAR))
	var reload := _upper(player.get_animation("PistolReload"), Animation.LOOP_NONE)
	library.add_animation("PistolReload", reload)
	library.add_animation("PistolAim", _upper(player.get_animation("PistolAim"),
		Animation.LOOP_LINEAR))
	var error := ResourceSaver.save(library, TARGET)
	for clip_name in library.get_animation_list():
		var clip := library.get_animation(clip_name)
		print("UPPER: %s %d tracks, %.0f frames, loop %d" % [clip_name, clip.get_track_count(),
			roundf(clip.length * FPS), clip.loop_mode])
	print("UPPER: saved %s (%s)" % [TARGET, error_string(error)])
	model.free()
	quit(0 if error == OK else 1)


func _upper(source: Animation, loop: Animation.LoopMode) -> Animation:
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
	clip.loop_mode = loop
	clip.step = 1.0 / FPS
	return clip


func _rotation_track(clip: Animation, bone: String) -> int:
	for t in clip.get_track_count():
		if clip.track_get_type(t) == Animation.TYPE_ROTATION_3D \
				and String(clip.track_get_path(t).get_concatenated_subnames()) == bone:
			return t
	push_error("no rotation track for " + bone)
	return -1
