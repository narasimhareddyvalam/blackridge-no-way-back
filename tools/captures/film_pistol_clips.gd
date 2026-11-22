extends SceneTree
## A film of the motion-captured pistol clips on Ethan for the author (Assignment 7, #392), built as
## tools/captures/capture_pistol_mocap.gd builds them (his own player on Idle, UpperBody with
## ethan_pistol.tres over it, the pistol in his right hand), played at full speed with the blends
## driver.gd will use: the low ready, up to the aim, the complete reload, back on aim, the low
## ready; twice, from his front-left and over his right shoulder. A Movie Maker run
## (`--write-movie`, `--fixed-fps 30`); a plain lit room, not the game's world.

const RIG := "res://features/characters/ethan/ethan.glb"
const POSE := "res://animations/ethan_pistol.tres"
const PISTOL := preload("res://features/weapons/pistol/pistol.glb")
const IN_HAND := Transform3D(Vector3(-0.566986, -10.01996, 99.49512),
	Vector3(32.87387, -93.98531, -9.277737), Vector3(94.44041, 32.65531, 3.826859),
	Vector3(-15.74269, 77.44193, -55.1404))
const BLEND := 0.25
const VIEWS := [[Vector3(1.3, 1.55, 1.9), Vector3(0.0, 1.2, 0.2)],
	[Vector3(-0.55, 1.75, -1.1), Vector3(0.15, 1.3, 0.8)]]
const PLAN := [["PistolIdle", 3.0], ["PistolAim", 2.0], ["PistolReload", 3.3], ["PistolAim", 1.5],
	["PistolIdle", 2.0]]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
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
	sun.shadow_enabled = true
	root.add_child(sun)
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(8.0, 8.0)
	floor.mesh = plane
	root.add_child(floor)
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
	var pistol := PISTOL.instantiate() as Node3D
	hand.add_child(pistol)
	pistol.transform = IN_HAND
	var camera := Camera3D.new()
	camera.fov = 40.0
	root.add_child(camera)
	camera.make_current()
	for view in VIEWS:
		camera.global_position = view[0]
		camera.look_at(view[1])
		for step in PLAN:
			upper.play(step[0], BLEND)
			print("FILM: %s for %.1f s" % [step[0], step[1]])
			await create_timer(step[1]).timeout
	quit(0)
