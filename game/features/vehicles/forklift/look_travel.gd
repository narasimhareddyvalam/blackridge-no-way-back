extends SkeletonModifier3D
## The forklift driver's head and neck turned the way he travels (part G of step 5 of #253): OSHA
## 1910.178(n)(6) has a driver look in his direction of travel, so backing he looks over his right
## shoulder. `wanted` is the turn asked for (0 ahead, LOOK_BACK backing); the turn eases toward it
## at TURN_RATE: his neck takes part of it and his head, set after it, the whole, about his
## body's up (a turn to his right is about up by minus the angle, as he faces +z).

const LOOK_BACK := deg_to_rad(75.0)
const TURN_RATE := 2.5
const SHARES := {"Bip01 Neck": 0.4, "Bip01 Head": 1.0}

var wanted := 0.0
var turned := 0.0

var _bones := {}


func _process_modification_with_delta(delta: float) -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	turned = move_toward(turned, wanted, TURN_RATE * delta)
	if absf(turned) < 0.0001:
		return
	if _bones.is_empty():
		for bone: String in SHARES:
			_bones[bone] = skeleton.find_bone(bone)
	var up := (skeleton.global_basis.inverse() * Vector3.UP).normalized()
	for bone: String in SHARES:
		var index: int = _bones[bone]
		if index < 0:
			continue
		var pose := skeleton.get_bone_global_pose(index)
		var turn := Basis(up, -turned * float(SHARES[bone]))
		skeleton.set_bone_global_pose(index, Transform3D(turn * pose.basis, pose.origin))
