extends SceneTree
## A fixture for the author's look at the rifle clips on Ethan (Assignment 7, #396), built as
## driver.gd will build them: his own player on Idle, UpperBody with game/animations/ethan_rifle.tres
## over it, the M16 in his right hand at the transform tools/art/measure_rifle_grip.gd measures. A
## plain lit room, not the game's world. PNGs go to captures/animation/rifle_mocap.

const RIG := "res://features/characters/ethan/ethan.glb"
const POSE := "res://animations/ethan_rifle.tres"
const RIFLE := preload("res://features/weapons/rifle/m16.glb")
const IN_HANDS := Transform3D(Vector3(-1.352649, 26.61023, -96.38499),
	Vector3(96.53981, 25.4537, 5.672503), Vector3(26.04297, -92.97318, -26.03375),
	Vector3(6.777893, 14.75708, 2.339657))
const SHOTS := [["RifleAim", 0], ["RifleFire", 4], ["RifleIdleA", 0], ["RifleIdleB", 100],
	["RifleAimDown", 30], ["RifleReload", 30], ["RifleReload", 45], ["RifleReload", 58],
	["RifleGrab", 87], ["RifleHit", 7]]
const VIEWS := {"front_left": [Vector3(1.5, 1.6, 1.6), Vector3(0.15, 1.2, 0.35)],
	"right": [Vector3(-1.6, 1.5, 0.9), Vector3(0.15, 1.2, 0.35)]}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var folder := ProjectSettings.globalize_path("res://").path_join(
		"../captures/animation/rifle_mocap")
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
	upper.process_priority = 1
	model.add_child(upper)
	upper.add_animation_library("", load(POSE))
	var hand := BoneAttachment3D.new()
	hand.bone_name = "mixamorig_RightHand"
	skeleton.add_child(hand)
	var rifle := RIFLE.instantiate() as Node3D
	hand.add_child(rifle)
	rifle.transform = IN_HANDS
	var camera := Camera3D.new()
	camera.fov = 40.0
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
	print("RIFLE: %d views x %d shots in %s" % [VIEWS.size(), SHOTS.size(), folder])
	quit(0)
