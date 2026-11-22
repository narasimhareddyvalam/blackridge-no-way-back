extends SkeletonModifier3D
## Where Ethan's walk puts his ankles and his hips' joints this frame, before his legs' IK moves
## them (#245–#246, part A), in the world, and the height of his model's ground as they were
## posed: on a stair his steps lift each foot as his walk lifts it, and lower his hips where his
## legs could not reach.

const BONES: Array[String] = ["mixamorig_LeftFoot", "mixamorig_RightFoot",
	"mixamorig_LeftUpLeg", "mixamorig_RightUpLeg"]

var ankles: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var hips: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var ground := 0.0
var seen := false
var _bones: Array[int] = []


func _process_modification_with_delta(_delta: float) -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	if _bones.is_empty():
		for bone in BONES:
			_bones.append(skeleton.find_bone(bone))
	if _bones.has(-1):
		return
	var space := skeleton.global_transform
	ground = space.origin.y
	for side in range(2):
		ankles[side] = (space * skeleton.get_bone_global_pose(_bones[side])).origin
		hips[side] = (space * skeleton.get_bone_global_pose(_bones[side + 2])).origin
	seen = true
