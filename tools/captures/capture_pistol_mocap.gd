extends SceneTree
## A fixture for the author's look at the motion-captured pistol clips on Ethan (Assignment 7,
## #390), built as driver.gd builds them: his own player on Idle, a second player (UpperBody) with
## game/animations/ethan_pistol.tres over it, and the pistol on his right hand bone at the
## transform tools/art/measure_pistol_grip.gd measures. A plain lit room, not the game's world.
## Writes PNGs to captures/animation/pistol_mocap (or the folder after `--`).

const RIG := "res://features/characters/ethan/ethan.glb"
const POSE := "res://animations/ethan_pistol.tres"
const PISTOL := preload("res://features/weapons/pistol/pistol.glb")
const IN_HAND := Transform3D(Vector3(4.613871, -46.33203, 88.49892),
	Vector3(-8.440907, -88.45727, -45.87011), Vector3(99.53626, -5.35372, -7.992114),
	Vector3(7.058945, 95.86407, -26.21748))
const SHOTS := [["PistolAim", 0], ["PistolIdle", 0], ["PistolIdle", 120], ["PistolReload", 15],
	["PistolReload", 30], ["PistolReload", 40], ["PistolReload", 47], ["PistolReload", 56],
	["PistolReload", 62], ["PistolReload", 75], ["PistolReload", 99]]
const VIEWS := {"side": [Vector3(1.1, 1.45, 1.2), Vector3(0.0, 1.2, 0.3)],
	"front": [Vector3(-0.4, 1.4, 2.0), Vector3(0.0, 1.2, 0.3)],
	"shoulder": [Vector3(-0.45, 1.7, -0.9), Vector3(0.0, 1.25, 0.6)]}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var folder := ProjectSettings.globalize_path("res://").path_join(
		"../captures/animation/pistol_mocap")
	if OS.get_cmdline_user_args().size() > 0:
		folder = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(folder)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.32, 0.34, 0.37)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.6, 0.62, 0.65)
	environment.ambient_light_energy = 0.7
	var world := WorldEnvironment.new()
	world.environment = environment
	root.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40.0, 145.0, 0.0)
	sun.light_energy = 1.6
	root.add_child(sun)
	var model := (load(RIG) as PackedScene).instantiate() as Node3D
	root.add_child(model)
	var skeleton := model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var legs := model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	legs.play("Idle")
	var upper := AnimationPlayer.new()
	upper.name = "UpperBody"
	model.add_child(upper)
	upper.add_animation_library("", load(POSE))
	upper.process_priority = 1
	var hand := BoneAttachment3D.new()
	hand.bone_name = "mixamorig_RightHand"
	skeleton.add_child(hand)
	var pistol := PISTOL.instantiate() as Node3D
	hand.add_child(pistol)
	pistol.transform = IN_HAND
	var camera := Camera3D.new()
	camera.fov = 38.0
	root.add_child(camera)
	camera.make_current()
	for view in VIEWS:
		camera.global_position = VIEWS[view][0]
		camera.look_at(VIEWS[view][1])
		for shot in SHOTS:
			legs.seek(0.0, true)
			legs.pause()
			upper.play(shot[0])
			upper.seek(int(shot[1]) / 30.0, true)
			upper.pause()
			for wait in range(3):
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(folder.path_join("%s_%s_%03d.png" % [view,
				shot[0], shot[1]]))
	print("MOCAP: %d views x %d shots in %s" % [VIEWS.size(), SHOTS.size(), folder])
	quit(0)
