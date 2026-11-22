extends SceneTree
## Measures where the pistol sits in Ethan's right hand (Assignment 7, #390), from his captured
## aim (PistolAim, the first frame of Mixamo's "Reloading"). His hand holds the grip as a shooter
## does: middle, ring and little fingers curled round it, the index finger straight along the frame
## above the trigger guard (trigger discipline), the thumb high. So the barrel runs along his index
## finger, the gun's top follows his knuckles from the little finger to the index (up the grip),
## and the index finger's middle joint lies against the frame's right side, just above the trigger
## guard (FINGER_ON_FRAME, in the pistol model: +x is the gun's left, -y its muzzle's way, +z its
## top). Prints the pistol's transform in his hand bone's space, the constant driver.gd uses.
## Run from the repository root:
##   HOME=.scratch-home /Applications/Godot.app/Contents/MacOS/Godot --headless --path game \
##       --script ../tools/art/measure_pistol_grip.gd

const RIG := "res://features/characters/ethan/ethan.glb"
const POSE := "res://animations/ethan_pistol.tres"
## The frame's right side (x 0.6227, less the finger's half thickness), above the trigger guard
## (z -0.008) and a little ahead of the trigger (y 0.60), from pistol.glb's measured parts.
const FINGER_ON_FRAME := Vector3(0.6147, 0.60, -0.008)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var model := (load(RIG) as PackedScene).instantiate() as Node3D
	root.add_child(model)
	var skeleton := model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var player := model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	player.add_animation_library("pose", load(POSE))
	player.play("pose/PistolAim")
	player.seek(0.0, true)
	await process_frame
	var at := func(bone: String) -> Vector3:
		return (skeleton.global_transform * skeleton.get_bone_global_pose(
			skeleton.find_bone("mixamorig_" + bone))).origin
	var hand := skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(
		"mixamorig_RightHand"))
	var bore: Vector3 = (at.call("RightHandIndex3") - at.call("RightHandIndex1")).normalized()
	var knuckles: Vector3 = at.call("RightHandIndex1") - at.call("RightHandPinky1")
	var up := (knuckles - bore * knuckles.dot(bore)).normalized()
	var across := up.cross(bore)
	var basis := Basis(across, -bore, up)
	var finger: Vector3 = at.call("RightHandIndex2")
	var pistol := Transform3D(basis, finger - basis * FINGER_ON_FRAME)
	print("GRIP: index finger %s along %s, the gun's top %s" % [finger, bore, up])
	assert(basis.determinant() > 0.0, "the pistol's basis must be a rotation, not a mirror")
	var local := hand.affine_inverse() * pistol
	print("GRIP: in the hand bone: %s" % [local])
	print("GRIP: const IN_HAND := Transform3D(Vector3%s, Vector3%s, Vector3%s, Vector3%s)" % [
		local.basis.x, local.basis.y, local.basis.z, local.origin])
	quit()
