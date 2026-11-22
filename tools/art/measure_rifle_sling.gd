extends SceneTree
## Places the M16 slung across Ethan's back (Assignment 7, #397: the author chose "Across his
## back"), where the draw's motion reaches for it: in RifleGrab ("Grab Rifle From Back") his right
## hand goes behind his right hip and lower back, deepest at frame 25 (GRAB_FRAME), so the rifle lies
## diagonally across his back with its pistol grip there, its muzzle up toward his left shoulder,
## flat against him with its sights out. Prints SLUNG, its transform in his upper back's (Spine2)
## space, the constant driver.gd uses. Run from the repository root:
##   HOME=.scratch-home /Applications/Godot.app/Contents/MacOS/Godot --headless --path game \
##       --script ../tools/art/measure_rifle_sling.gd

const RIG := "res://features/characters/ethan/ethan.glb"
const POSE := "res://animations/ethan_rifle.tres"
const GRAB_FRAME := 25
## The pistol grip's upper middle (as tools/art/solve_rifle_grip.py), in m16.glb's space.
const GRIP := Vector3(0.0, -0.095, 0.085)
## In Spine2's space, in metres (x his left, y up, z forward): the grip just behind where his hand
## reaches at GRAB_FRAME (-0.14, -0.35, -0.14), on his back; the rifle's line up toward his left
## shoulder; its top facing out behind him.
const GRIP_ON_BACK := Vector3(-0.13, -0.33, -0.2)
const ALONG := Vector3(0.55, 0.83, -0.04)
const TOP := Vector3(0.0, 0.0, -1.0)


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
	player.play("pose/RifleGrab")
	player.seek(GRAB_FRAME / 30.0, true)
	await process_frame
	var spine := skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(
		"mixamorig_Spine2"))
	var scale := spine.basis.get_scale()
	var unscaled := Transform3D(spine.basis.orthonormalized(), spine.origin)
	var muzzle_way := ALONG.normalized()
	var top := (TOP - muzzle_way * TOP.dot(muzzle_way)).normalized()
	var basis := Basis(top.cross(-muzzle_way), top, -muzzle_way)
	assert(basis.determinant() > 0.0, "the sling's basis must be a rotation, not a mirror")
	var on_back := Transform3D(basis, GRIP_ON_BACK - basis * GRIP)
	var slung := spine.affine_inverse() * (unscaled * on_back)
	print("SLING: Spine2 scale %s; grip on his back at %s" % [scale, unscaled * GRIP_ON_BACK])
	print("SLING: const SLUNG := Transform3D(Vector3%s, Vector3%s, Vector3%s, Vector3%s)" % [
		slung.basis.x, slung.basis.y, slung.basis.z, slung.origin])
	quit()
