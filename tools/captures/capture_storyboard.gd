extends SceneTree
## Raw frames for the cutscene designs (#357): the HUD hidden; a low wide shot of the van under the
## depot's lamps, Ethan close beside it after he steps out (lit as a cutscene would light him: a
## warm key light and a cool rim light), the compound's booth low across the
## lane in the rain, and a high shot over the valley road. Run windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1280x800 \
##     --script ../tools/captures/capture_storyboard.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"

var _out := ""
var _camera: Camera3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0]
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("capture_storyboard.cfg")
	var file := FileAccess.open(progress, FileAccess.WRITE)
	file.store_string(SAVE)
	file.close()
	var app := (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	app.get_node("DrivingTrial").checkpoint_path = progress
	root.add_child(app)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 800))
	await process_frame
	await process_frame
	for pressed in [true, false]:
		var key := InputEventKey.new()
		key.keycode = KEY_ENTER
		key.physical_keycode = KEY_ENTER
		key.pressed = pressed
		Input.parse_input_event(key)
		await process_frame
	await create_timer(1.5, true, false, true).timeout
	var van := app.get_node("FreightVan") as Node3D
	(app.get("hud") as CanvasLayer).visible = false
	van.call("recover", Transform3D(Basis.IDENTITY, Vector3(-28.0, 0.1, 93.0)))
	await create_timer(1.5, true, false, true).timeout
	_camera = Camera3D.new()
	root.add_child(_camera)
	_camera.make_current()
	await _shot("1_arrival", 32.0, van.to_global(Vector3(-3.2, 0.45, -6.5)), van.to_global(Vector3(0.0, 1.3, 0.5)))
	_camera.clear_current()
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = "interact"
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await create_timer(7.0, true, false, true).timeout
	var driver := app.get("driver") as Node3D
	var face := driver.global_position + Vector3.UP * 1.62
	var toward := (van.global_position - driver.global_position)
	toward.y = 0.0
	var side := toward.normalized().cross(Vector3.UP)
	_camera.make_current()
	var key_light := OmniLight3D.new()
	key_light.light_color = Color(1.0, 0.82, 0.6)
	key_light.light_energy = 1.6
	key_light.omni_range = 4.0
	root.add_child(key_light)
	key_light.global_position = face - toward.normalized() * 1.2 + side * 1.1 + Vector3.UP * 0.3
	var rim := OmniLight3D.new()
	rim.light_color = Color(0.55, 0.7, 1.0)
	rim.light_energy = 3.0
	rim.omni_range = 3.5
	root.add_child(rim)
	rim.global_position = face + toward.normalized() * 0.9 - side * 0.7 + Vector3.UP * 0.4
	await _shot("2_ethan", 28.0, face - toward.normalized() * 1.9 + side * 0.9 + Vector3.UP * 0.05, face + Vector3.UP * 0.02)
	key_light.queue_free()
	rim.queue_free()
	await _shot("3_booth", 30.0, Vector3(203.5, 0.55, 157.0), Vector3(196.8, 1.7, 150.3))
	van.call("recover", Transform3D(Basis(Vector3.UP, 0.5), Vector3(-30.0, 0.1, 100.0)))
	await create_timer(1.0, true, false, true).timeout
	await _shot("4_road", 40.0, van.to_global(Vector3(9.0, 11.0, 14.0)), van.to_global(Vector3(0.0, 0.5, -8.0)))
	quit(0)


func _shot(view: String, fov: float, eye: Vector3, at: Vector3) -> void:
	_camera.fov = fov
	_camera.global_position = eye
	await create_timer(0.8, true, false, true).timeout
	_camera.look_at_from_position(eye, at)
	for frame in range(3):
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join(view + ".png"))
