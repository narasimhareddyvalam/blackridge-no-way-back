extends SkeletonModifier3D
## Ethan's feet turned on a stair (#245–#246, part A): after his legs' IK has set his ankles on its
## treads, each foot is turned, as much as its weight in `weights` says, so that the line from his
## ankle to the ball of his foot points along `facing` and falls by its angle in `falls`: level as
## in his walk's flat stance while he stands on it, his heel up before it lifts, level again before
## it lands. Off a stair both weights are 0 and his walk's feet are left as they are.

const FEET: Array[String] = ["mixamorig_LeftFoot", "mixamorig_RightFoot"]
const BALLS: Array[String] = ["mixamorig_LeftToeBase", "mixamorig_RightToeBase"]

var weights: Array[float] = [0.0, 0.0]
var falls: Array[float] = [0.543, 0.543]
var facing := Vector3.BACK
var _feet: Array[int] = [-1, -1]
var _balls: Array[int] = [-1, -1]


func _process_modification_with_delta(_delta: float) -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	if _feet.has(-1):
		for side in range(2):
			_feet[side] = skeleton.find_bone(FEET[side])
			_balls[side] = skeleton.find_bone(BALLS[side])
		if _feet.has(-1) or _balls.has(-1):
			return
	var space := skeleton.global_transform
	var ahead := Vector3(facing.x, 0.0, facing.z)
	if ahead.length_squared() < 0.000001:
		return
	ahead = ahead.normalized()
	for side in range(2):
		if weights[side] <= 0.0:
			continue
		var foot := space * skeleton.get_bone_global_pose(_feet[side])
		var along := (space * skeleton.get_bone_global_pose(_balls[side])).origin - foot.origin
		if along.length_squared() < 0.000001:
			continue
		var wanted := ahead * cos(falls[side]) + Vector3.DOWN * sin(falls[side])
		var turn := Quaternion(along.normalized(), wanted)
		turn = Quaternion.IDENTITY.slerp(turn, clampf(weights[side], 0.0, 1.0))
		var turned := Transform3D(Basis(turn) * foot.basis, foot.origin)
		skeleton.set_bone_global_pose(_feet[side], space.affine_inverse() * turned)
