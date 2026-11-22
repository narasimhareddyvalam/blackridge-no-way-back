extends SkeletonModifier3D
## Each of Ethan's feet kept on its own side (#287): a man's heels pass about 0.08-0.12 m apart as
## he walks, never one across the other, but Mixamo's Pushing, Running and his walk back bring an
## ankle up to 0.03 m over his hips' middle line. Where a clip brings an ankle nearer that line than
## SIDE, his thigh is turned out at the hip, about his body's forward line, by just as much as puts
## the ankle SIDE out; a foot already that far out is left as the clip has it, and no bone changes
## its length. It runs before his legs' IK, which on a stair or under a low roof sets his feet as
## it does; getting in and out of the van, whose steps pivot one foot round the other, it is off.

const SIDE := 0.045
const CROSSING: Array[String] = ["EnterVan", "ExitVan"]
const BONES: Array[String] = ["mixamorig_LeftUpLeg", "mixamorig_RightUpLeg",
	"mixamorig_LeftFoot", "mixamorig_RightFoot"]

## His clips' player, to stand aside in the clips whose feet cross as they should.
var player: AnimationPlayer

var _bones: Array[int] = []


func _process_modification_with_delta(_delta: float) -> void:
	var skeleton := get_skeleton()
	if skeleton == null or (player != null and str(player.current_animation) in CROSSING):
		return
	if _bones.is_empty():
		for bone in BONES:
			_bones.append(skeleton.find_bone(bone))
	if _bones.has(-1):
		return
	var scale := skeleton.global_basis.get_scale().x
	var least := SIDE / maxf(scale, 0.0001)
	for side in range(2):
		var hips: Array[Vector3] = [skeleton.get_bone_global_pose(_bones[0]).origin,
			skeleton.get_bone_global_pose(_bones[1]).origin]
		var up := (skeleton.global_basis.inverse() * Vector3.UP).normalized()
		var across := hips[0] - hips[1]
		var left := (across - up * across.dot(up)).normalized()
		var outward := left if side == 0 else -left
		var middle := (hips[0] + hips[1]) / 2.0
		var ankle := skeleton.get_bone_global_pose(_bones[side + 2]).origin
		var short := least - (ankle - middle).dot(outward)
		if short <= 0.0:
			continue
		var forward := up.cross(left).normalized()
		var thigh := skeleton.get_bone_global_pose(_bones[side])
		var reach := ankle - thigh.origin
		var flat := reach - forward * reach.dot(forward)
		var turn := flat.signed_angle_to(flat + outward * short, forward)
		var basis := Basis(forward, turn)
		skeleton.set_bone_global_pose(_bones[side], Transform3D(basis * thigh.basis, thigh.origin))
