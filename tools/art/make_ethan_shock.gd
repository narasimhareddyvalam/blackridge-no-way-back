extends SceneTree
## Writes Ethan's shock after the hit (Assignment 7, the fourth clip; CHANGE-BRIEF.md #377-#383,
## #403; C67): game/animations/ethan_shock.tres, an AnimationLibrary holding "Shock", 90 frames at
## 30 fps, LOOP_NONE. Its base is Mixamo's captured "Male Sitting Pose" (ethan.glb's Sit), held;
## over it, small keyed turns of his chest, neck, head and shoulders, from the phase table:
##   grip   0-11   his hands close on the wheel (the IK in driver.gd); his head steadies
##   breath 12-35  a sharp breath: his chest and shoulders lift, his head pulls back a little
##   drop   36-59  his head falls toward the wheel, his chest and shoulders sag
##   stare  60-89  a slow breath; his head lifts and he stares ahead through the crack
## Each bone bends about his own left-right axis carried into the bone's parent's space (through the
## skeleton's own turn from the model: Mixamo's skeleton is Z-up), so a positive angle is forward and
## down whatever the bone's own axes; the shoulders lift about his forward axis. Built by this committed script, never at runtime. Run from the repository root:
##   HOME=.scratch-home /Applications/Godot.app/Contents/MacOS/Godot --headless --path game \
##       --script ../tools/art/make_ethan_shock.gd

const RIG := "res://features/characters/ethan/ethan.glb"
const TARGET := "res://animations/ethan_shock.tres"
const FPS := 30.0
const FRAMES := [0, 11, 24, 35, 47, 59, 74, 89]
## Degrees at each of FRAMES: forward bends, and the shoulders' lift.
const BEND := {
	"mixamorig_Spine2": [0, 0, -5, -6, 4, 8, 4, 3],
	"mixamorig_Neck": [0, 0, -3, -4, 8, 12, 2, 0],
	"mixamorig_Head": [0, 2, -4, -5, 14, 22, 2, -2],
}
const LIFT := [0, 2, 7, 8, 2, 0, 0, 0]

## The model's axes carried into the skeleton's space.
var _to_skeleton := Basis.IDENTITY


func _initialize() -> void:
	var model := (load(RIG) as PackedScene).instantiate() as Node3D
	var player := model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	var skeleton := model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var sit := player.get_animation("Sit")
	var turn := Basis.IDENTITY
	var node: Node = skeleton
	while node != model:
		turn = (node as Node3D).transform.basis.orthonormalized() * turn
		node = node.get_parent()
	_to_skeleton = turn.inverse()
	var clip := Animation.new()
	clip.length = FRAMES[-1] / FPS
	clip.step = 1.0 / FPS
	clip.loop_mode = Animation.LOOP_NONE
	var poses := {}
	for t in sit.get_track_count():
		var kind := sit.track_get_type(t)
		var path := sit.track_get_path(t)
		var bone := String(path.get_concatenated_subnames())
		var index := clip.add_track(kind)
		clip.track_set_path(index, path)
		var value: Variant = sit.track_get_key_value(t, 0)
		poses[bone + str(kind)] = value
		for frame in FRAMES:
			var keyed: Variant = value
			if kind == Animation.TYPE_ROTATION_3D:
				keyed = _turned(skeleton, sit, bone, value as Quaternion, FRAMES.find(frame))
			clip.track_insert_key(index, frame / FPS, keyed)
	var library := AnimationLibrary.new()
	library.add_animation("Shock", clip)
	var error := ResourceSaver.save(library, TARGET)
	print("SHOCK: %d tracks, %d frames, keys at %s; saved %s (%s)" % [clip.get_track_count(),
		roundf(clip.length * FPS) + 1, FRAMES, TARGET, error_string(error)])
	model.free()
	quit(0 if error == OK else 1)


## The bone's sitting rotation turned by this key's bend (or lift), in its parent's space.
func _turned(skeleton: Skeleton3D, sit: Animation, bone: String, rest: Quaternion,
		key: int) -> Quaternion:
	var degrees := 0.0
	var axis := Vector3.ZERO
	var parent_basis := _parent_basis(skeleton, sit, bone)
	if BEND.has(bone):
		degrees = float(BEND[bone][key])
		axis = parent_basis.inverse() * (_to_skeleton * Vector3.RIGHT)
	elif bone == "mixamorig_LeftShoulder" or bone == "mixamorig_RightShoulder":
		degrees = float(LIFT[key]) * (1.0 if bone == "mixamorig_LeftShoulder" else -1.0)
		axis = parent_basis.inverse() * (_to_skeleton * Vector3.BACK)
	if is_zero_approx(degrees):
		return rest
	return (Quaternion(axis.normalized(), deg_to_rad(degrees)) * rest).normalized()


## The global (skeleton-space) rotation of the bone's parent in the sitting pose.
func _parent_basis(skeleton: Skeleton3D, sit: Animation, bone: String) -> Basis:
	var parent := skeleton.get_bone_parent(skeleton.find_bone(bone))
	var basis := Basis.IDENTITY
	var chain: Array[int] = []
	while parent != -1:
		chain.push_front(parent)
		parent = skeleton.get_bone_parent(parent)
	for index in chain:
		var name := skeleton.get_bone_name(index)
		var track := sit.find_track(NodePath("Armature/Skeleton3D:" + name), Animation.TYPE_ROTATION_3D)
		var rotation := sit.track_get_key_value(track, 0) as Quaternion if track != -1 \
			else skeleton.get_bone_rest(index).basis.get_rotation_quaternion()
		basis = basis * Basis(rotation)
	return basis.orthonormalized()
