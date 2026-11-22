extends SceneTree
## Writes, for the rifle clips' key frames, Ethan's right hand bone's transform and the points the
## rifle must meet (Assignment 7, #397): the hole of his closed right hand (the pistol grip), of his left
## (the handguard, or the charging handle where he pulls it), and his right shoulder's pocket (the butt,
## when he aims). tools/art/solve_rifle_grip.py fits the one place of the rifle in his hand that
## best meets them all. The JSON goes to the path after `--`.

const RIG := "res://features/characters/ethan/ethan.glb"
const POSE := "res://animations/ethan_rifle.tres"
## [clip, frame, what the left hand holds ("guard", "charge" or ""), butt in the shoulder]
## The sets: "pack" (the Basic Shooter Pack's clips) and "own" (the author's own downloads), which
## hold the rifle at different angles in the hand, each solved on its own.
const FRAMES := [["pose/RifleAim", 0, "guard", true, "pack"], ["pose/RifleAim", 45, "guard", true, "pack"],
	["pose/RifleFire", 0, "guard", true, "pack"], ["pose/RifleFire", 4, "guard", true, "pack"],
	["pose/RifleHit", 7, "guard", true, "pack"], ["pose/RifleReload", 0, "guard", true, "pack"],
	["pose/RifleReload", 58, "charge", false, "pack"], ["pose/RifleReload", 99, "guard", true, "pack"],
	["RifleWalk", 10, "guard", true, "pack"], ["RifleRun", 8, "guard", true, "pack"],
	["RifleStrafeLeft", 12, "guard", true, "pack"], ["RifleWalkBack", 20, "guard", true, "pack"],
	["pose/RifleIdleA", 0, "guard", false, "own"], ["pose/RifleIdleA", 130, "guard", false, "own"],
	["pose/RifleIdleB", 0, "guard", false, "own"], ["pose/RifleIdleB", 60, "guard", false, "own"],
	["pose/RifleIdleB", 210, "guard", false, "own"], ["pose/RifleAimDown", 18, "guard", false, "own"],
	["pose/RifleAimDown", 24, "guard", false, "own"], ["pose/RifleGrab", 66, "guard", false, "own"],
	["pose/RifleGrab", 84, "guard", false, "own"], ["pose/RifleAway", 0, "guard", false, "own"],
	["pose/RifleAway", 36, "guard", false, "own"]]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var model := (load(RIG) as PackedScene).instantiate() as Node3D
	root.add_child(model)
	var skeleton := model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var player := model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	player.add_animation_library("pose", load(POSE))
	var out := []
	for entry in FRAMES:
		player.play("Idle")
		player.seek(0.0, true)
		player.play(entry[0])
		player.seek(int(entry[1]) / 30.0, true)
		await process_frame
		var bone := func(name: String) -> Transform3D:
			return skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(
				"mixamorig_" + name))
		var hand: Transform3D = bone.call("RightHand")
		var fist := func(side: String) -> Vector3:
			var sum := Vector3.ZERO
			for finger in ["Middle", "Ring", "Pinky"]:
				sum += bone.call(side + "Hand" + finger + "1").origin
				sum += bone.call(side + "Hand" + finger + "3").origin
			return sum / 6.0
		var right: Vector3 = fist.call("Right")
		var left: Vector3 = fist.call("Left")
		var chest: Transform3D = bone.call("Spine2")
		var pocket: Vector3 = bone.call("RightShoulder").origin.lerp(bone.call("RightArm").origin,
			0.7) + chest.basis.z.normalized() * 0.07
		out.append({"set": entry[4], "clip": entry[0], "frame": entry[1], "left_holds": entry[2],
			"butt": entry[3], "hand": [_v(hand.basis.x), _v(hand.basis.y), _v(hand.basis.z),
			_v(hand.origin)], "right_palm": _v(right), "left_palm": _v(left),
			"pocket": _v(pocket)})
	var file := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	file.store_string(JSON.stringify(out, "  "))
	file.close()
	print("TARGETS: %d frames" % out.size())
	quit()


func _v(v: Vector3) -> Array:
	return [v.x, v.y, v.z]
