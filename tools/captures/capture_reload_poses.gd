extends SceneTree
## A fixture for the author's look at the reload clip before it is wired (Assignment 7, #385):
## Ethan's rig (`ethan.glb`) with the arms `aim_arms.gd` builds, the clip seeked to the phase
## table's frames and rendered from his left front and over his right shoulder, in a plain lit
## room, not the game's world. Writes PNGs to the folder given after `--` (default
## captures/animation/reload_poses).

const AimArms = preload("res://features/weapons/pistol/aim_arms.gd")
const RIG := "res://features/characters/ethan/ethan.glb"
const FRAMES := [0, 6, 17, 30, 44, 47, 55, 65]
const VIEWS := {"side": [Vector3(0.75, 1.45, 1.05), Vector3(0.05, 1.2, 0.35)],
	"shoulder": [Vector3(-0.35, 1.75, -0.45), Vector3(0.0, 1.15, 0.55)]}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var folder := ProjectSettings.globalize_path("res://").path_join(
		"../captures/animation/reload_poses")
	if OS.get_cmdline_user_args().size() > 0:
		folder = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(folder)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.32, 0.34, 0.37)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.55, 0.57, 0.6)
	environment.ambient_light_energy = 0.6
	var world := WorldEnvironment.new()
	world.environment = environment
	root.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40.0, 35.0, 0.0)
	sun.light_energy = 1.6
	root.add_child(sun)
	var model := (load(RIG) as PackedScene).instantiate() as Node3D
	root.add_child(model)
	var player := model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	player.play("Idle")
	var skeleton := model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var arms := AimArms.new()
	model.add_child(arms)
	arms.call("setup", skeleton, 1.4)
	arms.set("wanted", 1.0)
	arms.set("influence", 1.0)
	var camera := Camera3D.new()
	camera.fov = 40.0
	root.add_child(camera)
	camera.make_current()
	var reload := arms.get("reload_player") as AnimationPlayer
	reload.play("reload")
	reload.pause()
	for view in VIEWS:
		camera.global_position = VIEWS[view][0]
		camera.look_at(VIEWS[view][1])
		for frame in FRAMES:
			reload.seek(frame / 30.0, true)
			for wait in range(4):
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(folder.path_join("%s_%02d.png" % [view,
				frame]))
	print("POSES: %d views x %d frames in %s" % [VIEWS.size(), FRAMES.size(), folder])
	quit(0)
