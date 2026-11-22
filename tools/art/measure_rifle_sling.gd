extends SceneTree
## Places the M16 slung on Ethan (Assignment 7, #400) where his own clips put it: "Rifle Put Away"
## ends with his right hand letting go of it at his right hip (LET_GO), and "Grab Rifle From Back"
## starts by taking it from there (TAKE): the two agree within 0.15 m and 20 degrees, and neither
## reaches over his shoulder. So the slung rifle hangs at his right hip, muzzle down, exactly as
## his hand leaves it at LET_GO (rifle_hold.gd's one-hand placement for his own downloads),
## in his upper back's (Spine2) space. Prints SLUNG, the constant the game uses. Run from the
## repository root:
##   HOME=.scratch-home /Applications/Godot.app/Contents/MacOS/Godot --headless --path game \
##       --script ../tools/art/measure_rifle_sling.gd

const RifleHold = preload("res://features/weapons/rifle/rifle_hold.gd")
const RIG := "res://features/characters/ethan/ethan.glb"
const POSE := "res://animations/ethan_rifle.tres"
const LET_GO := 62
const TAKE := 15


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var model := (load(RIG) as PackedScene).instantiate() as Node3D
	root.add_child(model)
	var skeleton := model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var player := model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	player.add_animation_library("pose", load(POSE))
	var hold := RifleHold.new(skeleton)
	var at_let_go := await _rifle(player, skeleton, hold, "pose/RifleAway", LET_GO)
	var at_take := await _rifle(player, skeleton, hold, "pose/RifleGrab", TAKE)
	var apart := (at_let_go * RifleHold.GRIP).distance_to(at_take * RifleHold.GRIP)
	var angle := rad_to_deg(at_let_go.basis.get_rotation_quaternion().angle_to(
		at_take.basis.get_rotation_quaternion()))
	print("SLING: let go at frame %d of the put-away, taken at frame %d of the draw: %.2f m and "
		% [LET_GO, TAKE, apart] + "%.0f degrees apart" % angle)
	print("SLING: const SLUNG := Transform3D(Vector3%s, Vector3%s, Vector3%s, Vector3%s)" % [
		at_let_go.basis.x, at_let_go.basis.y, at_let_go.basis.z, at_let_go.origin])
	quit()


## The rifle in his hand at `frame` of `clip`, in Spine2's space (scaled as the bone is).
func _rifle(player: AnimationPlayer, skeleton: Skeleton3D, hold: RefCounted, clip: String,
		frame: int) -> Transform3D:
	player.play("Idle")
	player.seek(0.0, true)
	player.play(clip)
	player.seek(frame / 30.0, true)
	await process_frame
	var rifle: Transform3D = hold.call("place", 1.0, clip.trim_prefix("pose/"), frame)
	for settle in range(10):
		rifle = hold.call("place", 1.0, clip.trim_prefix("pose/"), frame)
	var spine := skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(
		"mixamorig_Spine2"))
	return spine.affine_inverse() * rifle
