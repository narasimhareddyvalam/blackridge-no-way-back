extends SceneTree
## The mission guidance in play (#356): with `clean`, the HUD hidden (the mockups' bases); else the
## mission map and the objective as the player sees them, at the wheel on the valley road, at the
## compound's driveway, and on foot by the van. Run windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1280x800 \
##     --script ../tools/captures/capture_guidance.gd -- <absolute stills folder> [clean]

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"

var _out := ""
var _camera: Camera3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("capture_guidance.cfg")
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
	var clean := OS.get_cmdline_user_args().has("clean")
	var hud := app.get("hud") as CanvasLayer
	if clean and hud != null:
		hud.visible = false
	van.call("recover", Transform3D(Basis.IDENTITY, Vector3(199.6, 0.1, 172.0)))
	await create_timer(2.0, true, false, true).timeout
	await _save("1_seat_driveway")
	if OS.get_cmdline_user_args().has("raw_map"):
		var map := hud.get("mission_map") as Control
		(map.get("viewport") as SubViewport).get_texture().get_image().save_png(
			_out.path_join("1_raw_map.png"))
		print("CAM ", (map.get("camera") as Camera3D).global_transform, " focus ", map.get("focus"))
	van.call("recover", Transform3D(Basis(Vector3.UP, 0.5), Vector3(-30.0, 0.1, 100.0)))
	await create_timer(2.0, true, false, true).timeout
	await _save("2_seat_road")
	if clean:
		_camera = Camera3D.new()
		_camera.fov = 65.0
		root.add_child(_camera)
		_camera.make_current()
		_camera.look_at_from_position(van.to_global(Vector3(0.6, 3.2, 8.5)), van.to_global(
			Vector3(0.0, 1.2, -6.0)))
		await _save("3_chase_road")
	else:
		for pressed in [true, false]:
			var event := InputEventAction.new()
			event.action = "interact"
			event.pressed = pressed
			Input.parse_input_event(event)
			await process_frame
		await create_timer(6.0, true, false, true).timeout
		await _save("3_on_foot")
	quit(0)


func _save(view: String) -> void:
	for frame in range(3):
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join(view + ".png"))
