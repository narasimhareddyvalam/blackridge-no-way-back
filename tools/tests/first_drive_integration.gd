extends SceneTree

var failures: int = 0
var app: Node
var van: Node3D
var presentation: Node3D
var checkpoint_path: String


func _initialize() -> void:
	call_deferred("_run")


func check(condition: bool, label: String) -> void:
	print(("PASS: " if condition else "FAIL: ") + label)
	if not condition:
		failures += 1


func tap(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	await physics_frame
	await process_frame


func _run() -> void:
	create_timer(35.0).timeout.connect(_timeout)
	checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-integration-%d-%d.cfg" % [OS.get_process_id(), Time.get_ticks_usec()])
	app = load("res://app/first_drive.tscn").instantiate()
	app.get_node("DrivingTrial").checkpoint_path = checkpoint_path
	root.add_child(app)
	await process_frame
	app.call("_resume")
	van = app.get_node("FreightVan")
	presentation = van.get_node("VanPresentation")
	await create_timer(0.25).timeout
	check(not van.call("_rotation_blocked", 0.04), "Steering clearance accepts open level ground")
	check(presentation.get("mirrors").size() == 3, "Three live mirror viewports exist")
	for camera in presentation.get("mirror_cameras"):
		check(camera.get_world_3d() == van.get_world_3d(), "Mirror/rear camera shares live world")
	await tap("indicator_left")
	check(van.get("indicator") == -1 and van.get("indicator_lit"), "Left indicator activates")
	await create_timer(0.48).timeout
	check(not van.get("indicator_lit"), "Indicator blinks off")
	await tap("hazards")
	check(van.get("hazards_on") and van.get("indicator_lit"), "Hazards activate")
	await tap("hazards")
	await tap("headlights")
	check(van.get("headlights_on") and van.get("high_beams"), "Headlight switch selects high beams")
	await tap("headlights")
	check(not van.get("headlights_on"), "Headlight switch turns lamps off")
	await tap("headlights")
	check(van.get("headlights_on") and not van.get("high_beams"),
		"Headlight switch returns to low beams")
	await tap("wipers")
	check(van.get("wiper_setting") == 2, "Wipers select high speed")
	await tap("wipers")
	await create_timer(0.85).timeout
	var park: float = van.get_script().get_script_constant_map()["WIPER_PARK"]
	check(van.get("wiper_setting") == 0 and absf(van.get("wiper_angle") - park) < 0.02,
		"Wipers switch off and park")
	await tap("window_left")
	await create_timer(2.1).timeout
	check(van.get("left_window") > 0.99, "Driver window fully lowers")
	var audio: Node = app.get("_audio")
	check(audio.get("_rain").volume_db > -9, "Open window increases exterior rain audio")
	await tap("window_left")
	await create_timer(2.1).timeout
	check(van.get("left_window") < 0.01, "Driver window fully closes")
	check(audio.get("_rain").volume_db < -22, "Closed window muffles exterior rain audio")
	await tap("change_gear")
	check(van.get("gear") == -1 and presentation.get("reverse_screen").visible,
		"Reverse selects live reversing display")
	Input.action_press("accelerate")
	await create_timer(0.7).timeout
	Input.action_release("accelerate")
	check(van.get("speed") < -1, "Reverse throttle drives backward")
	await tap("change_gear")
	check(van.get("gear") == -1, "Gear change blocked while moving")
	Input.action_press("brake")
	await create_timer(0.5).timeout
	Input.action_release("brake")
	check(absf(van.get("speed")) < 0.05, "Service brake stops reverse motion")
	await tap("change_gear")
	check(van.get("gear") == 1 and not presentation.get("reverse_screen").visible,
		"Forward restores navigation display")
	var start := van.global_position
	Input.action_press("accelerate")
	await create_timer(1.8).timeout
	check(van.get("speed") > 4 and van.global_position.distance_to(start) > 3,
		"Throttle accelerates and moves van")
	await tap("interact")
	check(van.get("occupied"), "Exit rejected while moving")
	var heading := van.rotation.y
	Input.action_press("steer_left")
	await create_timer(0.7).timeout
	Input.action_release("steer_left")
	Input.action_release("accelerate")
	check(absf(angle_difference(heading, van.rotation.y)) > 0.06, "Steering changes van heading")
	Input.action_press("brake")
	await create_timer(1).timeout
	Input.action_release("brake")
	await tap("interact")
	check(not van.get("occupied") and app.get("driver").get("active"),
		"Stopped van allows safe exit")
	await tap("interact")
	var boarding := 0.0
	while not van.get("occupied") and boarding < 8.0:
		await create_timer(0.1).timeout
		boarding += 0.1
	check(van.get("occupied") and not app.get("driver").get("active"),
		"Nearby driver can reenter")
	await tap("pause")
	check(paused, "Escape action pauses scene")
	await tap("pause")
	check(not paused, "Escape action resumes scene")
	app.call("_recover")
	await process_frame
	check(absf(van.get("speed")) < 0.05 and van.get("occupied"),
		"Recovery returns stopped occupied van")
	print("BEHAVIOR RESULT: ", failures, " failures")
	app.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	if FileAccess.file_exists(checkpoint_path):
		DirAccess.remove_absolute(checkpoint_path)
	quit(1 if failures > 0 else 0)


func _timeout() -> void:
	check(false, "Integration suite completed within thirty-five seconds")
	quit(1)
