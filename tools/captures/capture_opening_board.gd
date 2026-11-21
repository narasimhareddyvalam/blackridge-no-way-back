extends SceneTree
## Raw frames for the opening cutscene's storyboard (#357; GAME_STORY's prologue: the long lonely
## drive in cold rain, Ethan finishing a late shift; C35), second pass, after "make it more
## interesting and cinematic": the HUD hidden, a new game begun; a street lamp reflected in the wet
## road from the asphalt's level, the hill road's sharpest hairpin from high above, the empty zebra crossing
## low at the kerb and from inside its empty shelter (foreshadowing, nobody there), Ethan seen
## from the dark cab through the wet windshield, a close-up of his face lit by the office lamp, and
## a high crane shot of him small beside the van. Run windowed, from the
## repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1280x800 \
##     --script ../tools/captures/capture_opening_board.gd -- <absolute stills folder>

var _out := ""
var _camera: Camera3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_out = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(_out)
	var app := (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	app.get_node("DrivingTrial").checkpoint_path = OS.get_user_data_dir().path_join(
		"capture_opening_board.cfg")
	root.add_child(app)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 800))
	await process_frame
	app.call("_new_drive")
	await create_timer(2.5, true, false, true).timeout
	(app.get("hud") as CanvasLayer).visible = false
	var world := app.get_node("IndustrialLoop")
	var van := app.get_node("FreightVan") as Node3D
	var driver := app.get("driver") as Node3D
	var road: RefCounted = world.get("road")
	var points: PackedVector3Array = world.get("road_points")
	var laybys: PackedFloat32Array = road.get("laybys")
	var best := 0
	for index in range(laybys.size()):
		if laybys[index] > laybys[best]:
			best = index
	var lookout := points[mini(best, points.size() - 1)]
	_camera = Camera3D.new()
	root.add_child(_camera)
	_camera.make_current()
	var rain := world.get("lamp_rain") as Node3D
	var lamp_head := Vector3.ZERO
	for volume: Node3D in rain.get("volumes"):
		if String(volume.name).begins_with("LampRainStreet"):
			lamp_head = volume.global_position
			break
	var lamp_foot := Vector3(lamp_head.x, 0.0, lamp_head.z)
	var near := 0
	for index in range(points.size()):
		if points[index].distance_to(lamp_foot) < points[near].distance_to(lamp_foot):
			near = index
	var along := (points[near + 4] - points[near]).normalized()
	var low := points[near] - along * 7.0 + Vector3.UP * 0.16
	await _shot("1_puddle", 30.0, low, points[near] - along * 2.5 + Vector3.UP * 0.25)
	var bend := points[points.size() / 3]
	var ahead := points[points.size() / 3 + 14]
	var sharpest := 10
	var turn := 0.0
	for index in range(10, points.size() - 10):
		var a := (points[index] - points[index - 8]).normalized()
		var b := (points[index + 8] - points[index]).normalized()
		var angle := a.angle_to(b)
		if angle > turn:
			turn = angle
			sharpest = index
	var hairpin := points[sharpest]
	await _shot("2_aerial", 50.0, hairpin + Vector3(6.0, 48.0, 10.0), hairpin)
	var stop := world.get("crossing") as Node3D
	var centre: Vector3 = stop.get("centre")
	var right: Vector3 = stop.get("right")
	var forward: Vector3 = stop.get("forward")
	var kerb: Vector3 = stop.get("kerb")
	await _shot("3_crossing", 24.0, centre - right * 4.6 + forward * 6.0 + Vector3.UP * 0.3,
		centre + right * 1.0 + Vector3.UP * 0.6)
	await _shot("4_shelter", 34.0, kerb + right * 2.2 + Vector3.UP * 1.2 - forward * 0.6,
		centre - right * 2.0 + Vector3.UP * 0.8)
	var eye := van.to_global(Vector3(-0.45, 1.8, -0.72))
	await _shot("5_windshield", 40.0, eye, driver.global_position + Vector3.UP * 1.3)
	var face := driver.global_position + Vector3.UP * 1.62
	var toward := (van.global_position - driver.global_position)
	toward.y = 0.0
	var side := toward.normalized().cross(Vector3.UP)
	var key_light := OmniLight3D.new()
	key_light.light_color = Color(1.0, 0.78, 0.55)
	key_light.light_energy = 1.2
	key_light.omni_range = 3.0
	root.add_child(key_light)
	key_light.global_position = face + toward.normalized() * 0.8 - side * 0.9 + Vector3.UP * 0.25
	var rim := OmniLight3D.new()
	rim.light_color = Color(0.55, 0.7, 1.0)
	rim.light_energy = 2.5
	rim.omni_range = 3.0
	root.add_child(rim)
	rim.global_position = face - toward.normalized() * 0.8 + side * 0.6 + Vector3.UP * 0.35
	await _shot("6_face", 22.0, face + toward.normalized() * 0.75 - side * 0.25 + Vector3.DOWN
		* 0.05, face + Vector3.UP * 0.04)
	key_light.queue_free()
	rim.queue_free()
	await _shot("7_crane", 40.0, driver.global_position + toward.normalized() * -6.0 + side * 3.0
		+ Vector3.UP * 13.0, driver.global_position.lerp(van.global_position, 0.45))
	quit(0)


func _shot(view: String, fov: float, eye: Vector3, at: Vector3) -> void:
	_camera.fov = fov
	_camera.global_position = eye
	await create_timer(0.8, true, false, true).timeout
	_camera.look_at_from_position(eye, at)
	for frame in range(3):
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join(view + ".png"))
