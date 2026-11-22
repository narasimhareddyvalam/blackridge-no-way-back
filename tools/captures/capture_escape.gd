extends SceneTree
## Mission 2's escape in play (#358, step 6): the turn from the cab, the guards on their rounds
## with their torches, a guard close, the text naming the cut, the cut from inside and from the
## alley, the yard's keypad on foot and his van taken back. Run windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1280x800 \
##     --script ../tools/captures/capture_escape.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=3\n"

var _out := ""
var _app: Node3D
var _camera: Camera3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 800))
	var progress := OS.get_user_data_dir().path_join("capture_escape.cfg")
	var file := FileAccess.open(progress, FileAccess.WRITE)
	file.store_string(SAVE)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	_app.get_node("DrivingTrial").checkpoint_path = progress
	root.add_child(_app)
	await process_frame
	await process_frame
	await _key(KEY_ENTER)
	await _wait(3.5)
	await _save("1_the_turn_from_the_cab")
	await _action("interact")
	await _wait(3.0)
	await _save("2_out_of_the_van")
	var cargo := _app.get("cargo") as Node
	var escape := cargo.get("escape") as Node
	var guards: Array = escape.get("guards")
	var driver := _app.get("driver") as CharacterBody3D
	driver.global_position = Vector3(251.6, 0.02, 135.0)
	driver.call("look_toward", Vector3(-1.0, 0.0, 0.3))
	await _wait(4.5)
	await _save("3_the_text_hidden_by_the_van")
	escape.set_physics_process(false)
	_camera = Camera3D.new()
	_camera.fov = 40.0
	root.add_child(_camera)
	var guard := guards[2] as Node3D
	_camera.look_at_from_position(guard.global_position + Vector3(2.2, 1.7, -3.4),
		guard.global_position + Vector3(0.0, 1.3, 0.0))
	_camera.make_current()
	await _save("4_gate_guard_close")
	var walker := guards[1] as Node3D
	_camera.look_at_from_position(walker.global_position + walker.call("facing") * 6.0
		+ Vector3(1.5, 1.6, 0.0), walker.global_position + Vector3(0.0, 1.2, 0.0))
	await _save("5_patrol_walking_toward")
	var lamp := OmniLight3D.new()
	lamp.name = "InspectionLamp"
	lamp.omni_range = 9.0
	lamp.light_energy = 2.0
	root.add_child(lamp)
	lamp.global_position = Vector3(140.5, 2.5, 141.5)
	_camera.fov = 55.0
	_camera.look_at_from_position(Vector3(142.5, 1.7, 142.5), Vector3(138.0, 1.0, 140.0))
	await _save("6_cut_from_inside_inspection_lamp")
	lamp.global_position = Vector3(136.6, 2.5, 142.5)
	_camera.look_at_from_position(Vector3(136.8, 1.6, 144.5), Vector3(138.0, 1.0, 139.8))
	await _save("7_cut_from_the_alley_inspection_lamp")
	lamp.queue_free()
	driver.global_position = Vector3(98.4, 0.02, 164.0)
	driver.call("look_toward", Vector3(0.0, 0.0, -1.0))
	(driver.call("get_camera") as Camera3D).make_current()
	escape.set("outside", true)
	escape.set_physics_process(true)
	await _wait(1.5)
	await _save("8_keypad_on_foot")
	quit(0)


func _key(code: Key) -> void:
	for pressed in [true, false]:
		var key := InputEventKey.new()
		key.keycode = code
		key.physical_keycode = code
		key.pressed = pressed
		Input.parse_input_event(key)
		await process_frame


func _action(action: String) -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _save(view: String) -> void:
	for frame in range(3):
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join(view + ".png"))
