extends SkeletonModifier3D
## Bends a seated body forward from its hips, `angle` shared over its spine bones, about `side` (its
## own left in the world): leaning in from a chair to reach the booth's window (#348).

var bones: PackedStringArray = ["Bip01 Spine", "Bip01 Spine1"]
var side := Vector3.LEFT
var angle := 0.35


func _process_modification_with_delta(_delta: float) -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	var share := angle / bones.size()
	var turn := Basis(side.normalized(), share)
	for name in bones:
		var bone := skeleton.find_bone(name)
		if bone < 0:
			continue
		var parent := skeleton.get_bone_parent(bone)
		var frame := skeleton.global_basis.orthonormalized()
		if parent >= 0:
			frame = frame * skeleton.get_bone_global_pose(parent).basis.orthonormalized()
		var local := (frame.inverse() * turn * frame).orthonormalized()
		skeleton.set_bone_pose_rotation(bone, Quaternion(local) * skeleton.get_bone_pose_rotation(
			bone))
