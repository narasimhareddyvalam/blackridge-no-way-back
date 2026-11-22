extends SceneTree
## Measures where the M16 sits in Ethan's hands (Assignment 7, #396), from his captured aim
## (RifleAim, Mixamo's "rifle aiming idle"): his right palm on the rifle's pistol grip (GRIP) and his
## left palm under its handguard (HANDGUARD), so the rifle lies along the line from his right palm
## to his left, its top up. Points are in m16.glb's own space (Godot: the muzzle -z, the top +y),
## measured from its parts. Prints the rifle's transform in his right hand bone's space, the
## constant driver.gd uses. Run from the repository root:
##   HOME=.scratch-home /Applications/Godot.app/Contents/MacOS/Godot --headless --path game \
##       --script ../tools/art/measure_rifle_grip.gd

const RIG := "res://features/characters/ethan/ethan.glb"
const POSE := "res://animations/ethan_rifle.tres"
## The pistol grip's upper middle, where the palm closes (the grip spans z 0.039-0.143 behind
## and y -0.055 to -0.17 below the bore line), and the handguard's underside a hand's width ahead
## of the magazine well (the rail spans z -0.132 to -0.349).
const GRIP := Vector3(0.0, -0.085, 0.075)
const HANDGUARD := Vector3(0.0, -0.05, -0.24)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var model := (load(RIG) as PackedScene).instantiate() as Node3D
	root.add_child(model)
	var skeleton := model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var player := model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	player.add_animation_library("pose", load(POSE))
	player.play("Idle")
	player.seek(0.0, true)
	player.play("pose/RifleAim")
	player.seek(0.0, true)
	await process_frame
	var at := func(bone: String) -> Vector3:
		return (skeleton.global_transform * skeleton.get_bone_global_pose(
			skeleton.find_bone("mixamorig_" + bone))).origin
	var right: Vector3 = (at.call("RightHand") + at.call("RightHandMiddle1")) / 2.0
	var left: Vector3 = (at.call("LeftHand") + at.call("LeftHandMiddle1")) / 2.0
	var along := (left - right).normalized()
	var gun_along := (HANDGUARD - GRIP).normalized()
	var world := _frame(along, Vector3.UP)
	var gun := _frame(gun_along, Vector3.UP)
	var basis := world * gun.inverse()
	assert(basis.determinant() > 0.0, "the rifle's basis must be a rotation, not a mirror")
	var rifle := Transform3D(basis, right - basis * GRIP)
	var muzzle := rifle * Vector3(0.0, 0.0, -0.56)
	var hand := skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(
		"mixamorig_RightHand"))
	var local := hand.affine_inverse() * rifle
	print("RIFLE: right palm %s left palm %s (%.2f m apart), muzzle %s, %.1f degrees left of his "
		% [right, left, right.distance_to(left), muzzle, rad_to_deg(atan2(-basis.z.x, -basis.z.z))]
		+ "feet")
	print("RIFLE: const IN_HANDS := Transform3D(Vector3%s, Vector3%s, Vector3%s, Vector3%s)" % [
		local.basis.x, local.basis.y, local.basis.z, local.origin])
	quit()


## An orthonormal frame whose -z is `forward` and whose y is `up` made square to it.
func _frame(forward: Vector3, up: Vector3) -> Basis:
	var back := -forward.normalized()
	var y := (up - back * up.dot(back)).normalized()
	return Basis(y.cross(back), y, back)
