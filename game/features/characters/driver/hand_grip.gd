extends SkeletonModifier3D
## Ethan's hands closed round the handle they hold (#250), as a hand grips a bar about 3 cm thick
## with its thumb on top: his fingers first set straight as in his rest pose, rid of the splay of
## his clip's open hands; each hand turned the shortest way until the bar runs through it from
## thumb to little finger (`bars`, the bar's way up at each hand, in the world), then each finger
## curled toward the palm at its three joints and the thumb round the other side; by `amount` (0
## as his clip has them, to 1 closed), which follows how fully his hands are on the handle. Runs
## after his hands' IK; `palms` tells which way each palm faces then, for his hands to be set
## with the bar just under the palm. Which way is a palm, and on which side its thumb, is the
## hand's own: Mixamo's rest pose has both palms facing down.

const FINGERS: Array[String] = ["Index", "Middle", "Ring", "Pinky"]
const CURL: Array[float] = [deg_to_rad(60.0), deg_to_rad(90.0), deg_to_rad(60.0)]
const THUMB: Array[float] = [deg_to_rad(25.0), deg_to_rad(30.0)]
const SIDES: Array[String] = ["Left", "Right"]

var amount := 0.0
var bars: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var palms: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _bones := {}
var _down := {}
var _thumb_side := {}


func _process_modification_with_delta(_delta: float) -> void:
	var skeleton := get_skeleton()
	if skeleton == null or amount <= 0.0:
		return
	if _bones.is_empty() and not _find(skeleton):
		return
	for index in range(2):
		var side := SIDES[index]
		_straighten(skeleton, side)
		_turn_hand(skeleton, index)
		var pose := skeleton.get_bone_global_pose(_bones[side + "Hand"])
		var palm: Vector3 = (pose.basis * (_down[side] as Vector3)).normalized()
		palms[index] = (skeleton.global_basis * palm).normalized()
		var middle := _at(skeleton, side + "HandMiddle1")
		for finger: String in FINGERS:
			var axis := _axis(skeleton, "%sHand%s1" % [side, finger],
				"%sHand%s2" % [side, finger], palm)
			for joint in range(3):
				_curl(skeleton, "%sHand%s%d" % [side, finger, joint + 1], axis,
					CURL[joint] * amount)
		var thumb := _at(skeleton, side + "HandThumb2")
		var round := _axis(skeleton, side + "HandThumb2", side + "HandThumb3",
			(palm + (middle - thumb).normalized()).normalized())
		for joint in range(2):
			_curl(skeleton, "%sHandThumb%d" % [side, joint + 2], round, THUMB[joint] * amount)


## The fingers and thumb of the hand `side` set, by `amount`, as they are in his rest pose.
func _straighten(skeleton: Skeleton3D, side: String) -> void:
	for finger: String in FINGERS + ["Thumb"]:
		for joint in range(1, 4):
			var bone: int = _bones["%sHand%s%d" % [side, finger, joint]]
			var pose := skeleton.get_bone_pose(bone)
			var rest := skeleton.get_bone_rest(bone)
			var turn := Quaternion(pose.basis.orthonormalized()).slerp(
				Quaternion(rest.basis.orthonormalized()), amount)
			skeleton.set_bone_pose(bone, Transform3D(Basis(turn).scaled(pose.basis.get_scale()),
				pose.origin))


## The hand `index` turned about its wrist, the shortest way, by `amount` of the way to having
## its bar run through it from its thumb to its little finger.
func _turn_hand(skeleton: Skeleton3D, index: int) -> void:
	if bars[index].length_squared() < 0.000001:
		return
	var side := SIDES[index]
	var bone: int = _bones[side + "Hand"]
	var pose := skeleton.get_bone_global_pose(bone)
	var fingers := (_at(skeleton, side + "HandMiddle1") - pose.origin).normalized()
	var palm := (pose.basis * (_down[side] as Vector3)).normalized()
	var thumb := fingers.cross(palm).normalized() * float(_thumb_side[side])
	var bar := (skeleton.global_basis.inverse() * bars[index]).normalized()
	var turn := Quaternion.IDENTITY.slerp(Quaternion(thumb, bar), amount)
	var basis := Basis(turn)
	skeleton.set_bone_global_pose(bone, Transform3D(basis, pose.origin - basis * pose.origin)
		* pose)


## The way a finger curls: about the axis that turns its first bone, `name` to `next`, toward
## `toward`; each of its joints curls about the same axis, so that it wraps on round the bar.
func _axis(skeleton: Skeleton3D, name: String, next: String, toward: Vector3) -> Vector3:
	var along := (_at(skeleton, next) - _at(skeleton, name)).normalized()
	var axis := along.cross(toward)
	return axis.normalized() if axis.length_squared() > 0.000001 else Vector3.ZERO


## The bone `name` turned by `angle` about `axis` at its joint, the bones beyond it going with it.
func _curl(skeleton: Skeleton3D, name: String, axis: Vector3, angle: float) -> void:
	if axis == Vector3.ZERO:
		return
	var bone: int = _bones[name]
	var pose := skeleton.get_bone_global_pose(bone)
	var turn := Basis(axis, angle)
	skeleton.set_bone_global_pose(bone, Transform3D(turn, pose.origin - turn * pose.origin) * pose)


func _at(skeleton: Skeleton3D, name: String) -> Vector3:
	return skeleton.get_bone_global_pose(_bones[name]).origin


func _rest(skeleton: Skeleton3D, name: String) -> Transform3D:
	return skeleton.get_bone_global_rest(_bones[name])


func _find(skeleton: Skeleton3D) -> bool:
	for side: String in SIDES:
		var names: Array[String] = [side + "Hand"]
		for finger: String in FINGERS + ["Thumb"]:
			for joint in range(1, 5):
				names.append("%sHand%s%d" % [side, finger, joint])
		for name in names:
			var bone := skeleton.find_bone("mixamorig_" + name)
			if bone < 0:
				_bones.clear()
				return false
			_bones[name] = bone
		var hand := _rest(skeleton, side + "Hand")
		var down := (skeleton.global_basis.inverse() * Vector3.DOWN).normalized()
		_down[side] = hand.basis.inverse() * down
		var fingers := (_rest(skeleton, side + "HandMiddle1").origin - hand.origin).normalized()
		var thumb := _rest(skeleton, side + "HandThumb1").origin - hand.origin
		_thumb_side[side] = signf(thumb.dot(fingers.cross(down)))
	return true
