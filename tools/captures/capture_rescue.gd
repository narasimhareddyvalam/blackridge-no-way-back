extends SceneTree
## Lily and Adrian in play (#359, Mission 3's step 7): Lily in the office; walking out with her
## hand in his, from the side and behind; then the scene at the service gate, a still from each of
## its shots. Run windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1280x800 \
##     --script ../tools/captures/capture_rescue.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"last_run\"\n\n[run]\nstage=4\n"
const SCENE_STILLS: Array = [[3.0, "4_he_comes"], [9.5, "5_adrian"], [15.5, "6_ethan"],
	[21.0, "7_maya_and_lily"], [24.1, "8_he_draws"], [29.0, "9_after"]]

var _out := ""
var _app: Node3D
var _driver: CharacterBody3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 800))
	var progress := OS.get_user_data_dir().path_join("capture_rescue.cfg")
	var file := FileAccess.open(progress, FileAccess.WRITE)
	file.store_string(SAVE)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	_app.get_node("DrivingTrial").checkpoint_path = progress
	root.add_child(_app)
	await process_frame
	await process_frame
	_app.call("_begin")
	await _wait(1.5)
	_driver = _app.get("driver") as CharacterBody3D
	var run := _app.get("run") as Node
	var lily := run.get("lily") as Node3D
	var field := _app.get_node("IndustrialLoop").get("harbour_flats").get("airfield") as Node3D
	_app.call("_stand_ethan", lily.global_position + Vector3(0.0, 0.0, -1.3), lily.global_position)
	await _wait(1.0)
	_driver.call("look_toward", Vector3.BACK)
	await _wait(0.3)
	await _save("1_lily_in_the_office")
	run.call("do_foot_action", _driver.global_position)
	var door: Vector3 = field.get("office_door")
	_app.call("_stand_ethan", door + Vector3(0.0, 0.0, -4.0), door + Vector3(0.0, 0.0, -10.0))
	await _wait(0.2)
	lily.global_position = _driver.global_position + Vector3(-0.45, 0.0, 0.3)
	lily.call("lead", _driver)
	_driver.call("look_toward", Vector3.FORWARD)
	Input.action_press("accelerate")
	await _wait(2.5)
	var camera := Camera3D.new()
	camera.fov = 40.0
	root.add_child(camera)
	camera.look_at_from_position(_driver.global_position + Vector3(-3.2, 1.2, -1.0),
		_driver.global_position + Vector3(-0.2, 0.8, 0.0))
	camera.make_current()
	await _wait(0.2)
	await _save("2_her_hand_in_his_side")
	camera.look_at_from_position(_driver.global_position + Vector3(-0.6, 1.4, 2.6),
		_driver.global_position + Vector3(-0.3, 0.8, 0.0))
	await _wait(0.2)
	await _save("3_her_hand_in_his_behind")
	Input.action_release("accelerate")
	(_driver.call("get_camera") as Camera3D).make_current()
	var maya := run.get("maya") as Node3D
	_app.call("_stand_ethan", maya.global_position + Vector3(1.0, 0.0, -3.5), maya.global_position)
	await _wait(0.1)
	lily.global_position = _driver.global_position + Vector3(-0.45, 0.0, 0.3)
	var clock := 0.0
	var cutscene := _app.get("cutscene") as Node
	while not bool(cutscene.get("playing")) and clock < 5.0:
		await physics_frame
		clock += 1.0 / 60.0
	for still: Array in SCENE_STILLS:
		while float(run.get("_scene_clock")) < float(still[0]):
			await physics_frame
		await _save(String(still[1]))
		if String(still[1]) == "8_he_draws":
			var adrian := run.get("adrian") as Node3D
			var close := Camera3D.new()
			close.fov = 35.0
			root.add_child(close)
			close.look_at_from_position(adrian.global_position + adrian.global_basis.z * 2.5
				+ adrian.global_basis.x * 1.8 + Vector3.UP * 1.6, adrian.global_position
				+ Vector3.UP * 1.3)
			close.make_current()
			var film := cutscene.get("film") as CanvasLayer
			film.visible = false
			await _save("8b_adrian_draws_close")
			film.visible = true
			(cutscene.get("camera") as Camera3D).make_current()
			close.queue_free()
	quit(0)


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _save(view: String) -> void:
	for frame in range(3):
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join(view + ".png"))
