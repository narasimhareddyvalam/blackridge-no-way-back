extends SkeletonModifier3D
## Turns one bone to `aim`, a turn in the world, after the modifiers before it: a hand set the way
## it holds something, which an arm's two-bone IK places but leaves turned as its clip has it.

var bone_name := ""
var aim := Basis()


func _process_modification_with_delta(_delta: float) -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	var bone := skeleton.find_bone(bone_name)
	if bone < 0:
		return
	var pose := skeleton.get_bone_global_pose(bone)
	var turn := skeleton.global_basis.orthonormalized().inverse() * aim.orthonormalized()
	pose.basis = turn * Basis.from_scale(pose.basis.get_scale())
	skeleton.set_bone_global_pose(bone, pose)
