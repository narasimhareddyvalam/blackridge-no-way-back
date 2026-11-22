extends SceneTree
## Writes Ethan's shock after the hit (Assignment 7, the fourth clip; CHANGE-BRIEF.md #377-#383,
## #403, #404; C67): game/animations/ethan_shock.tres, an AnimationLibrary holding "Shock", 105
## frames at 30 fps (3.5 s), LOOP_NONE. Its base is the last frame of Mixamo's captured "Entering
## Car" (ethan.glb's EnterVan, beyond the game's cut): Ethan seated in a vehicle, his feet at the
## pedals and his hands forward at the wheel's height. Over it, a hunch over the wheel held
## throughout (HUNCH: a frightened driver clamps the wheel and leans into it) and keyed turns of his chest, neck, head
## and shoulders, from the phase table, as a frightened driver moves (#404):
##   startle   0-8    his head jerks back, his shoulders snap up
##   panic     8-30   quick heaving breaths, his grip clamped (the IK); a glance out at the road
##   disbelief 30-47  his head shakes "no", a little bowed
##   drop      47-63  his head falls toward the wheel, his shoulders sag
##   checks    63-83  he looks to his left mirror, then to his right: did anyone see?
##   stare     83-104 a fixed stare ahead through the crack, two more heavy breaths
## His own left-right axis (from hip to hip), forward axis (hips to knees) and up axis are read
## from that pose: the bends turn about the left-right axis (forward and down positive), the head
## turns about the up axis (to his left positive) and the shoulders lift about the forward one, each
## carried into the bone's parent's space. Built by this committed script, never at runtime. Run
## from the repository root:
##   HOME=.scratch-home /Applications/Godot.app/Contents/MacOS/Godot --headless --path game \
##       --script ../tools/art/make_ethan_shock.gd

const RIG := "res://features/characters/ethan/ethan.glb"
const TARGET := "res://animations/ethan_shock.tres"
const BASE := "EnterVan"
const FPS := 30.0
const FRAMES := [0, 4, 8, 14, 20, 26, 31, 35, 39, 43, 47, 55, 63, 68, 73, 78, 83, 88, 94, 104]
## Degrees at each of FRAMES: forward bends, turns to his left, and the shoulders' lift.
const BEND := {
	"mixamorig_Spine2": [0, -6, -8, -3, -7, -2, 2, 2, 2, 2, 4, 10, 10, 6, 2, 2, -5, -1, -4, 0],
	"mixamorig_Neck": [0, -6, -4, -2, -1, 0, 3, 3, 3, 3, 6, 12, 13, 8, 3, 2, 1, 0, 0, 0],
	"mixamorig_Head": [0, -12, -8, -4, -2, 0, 6, 6, 6, 6, 10, 24, 26, 16, 6, 4, 2, 0, 1, 0],
}
## Degrees held through the whole clip: he hunches forward over the wheel, his arms bent to it
## (his lower and middle back bent forward), his neck and head bent back up so he still looks out.
const HUNCH := {"mixamorig_Spine": 9.0, "mixamorig_Spine1": 9.0, "mixamorig_Neck": -8.0,
	"mixamorig_Head": -10.0}
const TURN := {
	"mixamorig_Neck": [0, 0, 0, 0, 2, 6, -6, 6, -5, 4, 0, 0, 0, 12, 12, -9, -9, 0, 0, 0],
	"mixamorig_Head": [0, 0, 0, 0, 4, 12, -12, 12, -10, 8, 0, 0, 0, 25, 25, -18, -18, 0, 0, 0],
}
const LIFT := [0, 6, 8, 3, 7, 2, 1, 1, 1, 1, 0, -2, -2, 0, 2, 2, 6, 1, 5, 0]

var _skeleton: Skeleton3D
var _lateral := Vector3.ZERO
var _forward := Vector3.ZERO
var _up := Vector3.ZERO


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var model := (load(RIG) as PackedScene).instantiate() as Node3D
	root.add_child(model)
	var player := model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	_skeleton = model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var base := player.get_animation(BASE)
	var at := base.length
	player.play(BASE)
	player.seek(at, true)
	player.pause()
	await process_frame
	var hips := _pose("Hips").origin
	_lateral = (_pose("LeftUpLeg").origin - _pose("RightUpLeg").origin).normalized()
	var knees := (_pose("LeftLeg").origin + _pose("RightLeg").origin) / 2.0
	_forward = knees - hips
	_forward = (_forward - _lateral * _forward.dot(_lateral)).normalized()
	_up = _forward.cross(_lateral).normalized()
	var clip := Animation.new()
	clip.length = FRAMES[-1] / FPS
	clip.step = 1.0 / FPS
	clip.loop_mode = Animation.LOOP_NONE
	for t in base.get_track_count():
		var kind := base.track_get_type(t)
		var path := base.track_get_path(t)
		var bone := String(path.get_concatenated_subnames())
		var value: Variant
		match kind:
			Animation.TYPE_POSITION_3D:
				value = base.position_track_interpolate(t, at)
			Animation.TYPE_ROTATION_3D:
				value = base.rotation_track_interpolate(t, at)
			Animation.TYPE_SCALE_3D:
				value = base.scale_track_interpolate(t, at)
			_:
				continue
		var index := clip.add_track(kind)
		clip.track_set_path(index, path)
		for key in FRAMES.size():
			var keyed: Variant = value
			if kind == Animation.TYPE_ROTATION_3D:
				keyed = _turned(bone, value as Quaternion, key)
			clip.track_insert_key(index, FRAMES[key] / FPS, keyed)
	var library := AnimationLibrary.new()
	library.add_animation("Shock", clip)
	var error := ResourceSaver.save(library, TARGET)
	print("SHOCK: base %s at its last frame; %d tracks, %d frames, keys at %s; saved %s (%s)" % [
		BASE, clip.get_track_count(), roundf(clip.length * FPS) + 1, FRAMES, TARGET,
		error_string(error)])
	model.free()
	quit(0 if error == OK else 1)


## The bone's seated rotation turned by this key's bend and turn (or lift), in its parent's space.
func _turned(bone: String, rest: Quaternion, key: int) -> Quaternion:
	var index := _skeleton.find_bone(bone)
	if index == -1:
		return rest
	var parent := _skeleton.get_bone_parent(index)
	var parent_basis := _skeleton.get_bone_global_pose(parent).basis.orthonormalized() \
		if parent != -1 else Basis.IDENTITY
	var turn := Quaternion.IDENTITY
	var bend := float(HUNCH.get(bone, 0.0))
	if BEND.has(bone):
		bend += float(BEND[bone][key])
	if not is_zero_approx(bend):
		turn = Quaternion((parent_basis.inverse() * _lateral).normalized(),
			deg_to_rad(bend)) * turn
	if TURN.has(bone) and not is_zero_approx(float(TURN[bone][key])):
		turn = Quaternion((parent_basis.inverse() * _up).normalized(),
			deg_to_rad(float(TURN[bone][key]))) * turn
	if bone == "mixamorig_LeftShoulder" or bone == "mixamorig_RightShoulder":
		var degrees := float(LIFT[key]) * (1.0 if bone == "mixamorig_LeftShoulder" else -1.0)
		if not is_zero_approx(degrees):
			turn = Quaternion((parent_basis.inverse() * _forward).normalized(),
				deg_to_rad(degrees)) * turn
	return (turn * rest).normalized()


func _pose(bone: String) -> Transform3D:
	return _skeleton.get_bone_global_pose(_skeleton.find_bone("mixamorig_" + bone))
