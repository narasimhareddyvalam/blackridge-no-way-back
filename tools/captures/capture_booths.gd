extends SceneTree
## Mission 2's guard booths at night (the audit, #348): the transfer shed's and the warehouse
## compound's, each from a driver pulling up at its service window (shut, then slid open), from
## the lane's approach, close at the window, from its far side, at its door, from its back corner
## and from above; inside at its counter, its north and south walls, and its counter close. Run
## windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1280x800 \
##     --script ../tools/captures/capture_booths.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
## In the booth's frame (its service window toward +x).
const VIEWS := {
	"driver_at_window": [Vector3(2.6, 1.9, 0.6), Vector3(0.0, 1.5, 0.0)],
	"approach": [Vector3(4.5, 1.8, -9.0), Vector3(0.0, 1.3, 0.0)],
	"window_close": [Vector3(1.6, 1.6, -0.9), Vector3(0.0, 1.4, 0.2)],
	"far_side": [Vector3(-4.0, 1.7, 4.5), Vector3(0.0, 1.3, 0.0)],
	"above": [Vector3(5.0, 7.0, 6.0), Vector3(0.0, 1.0, 0.0)],
	"door": [Vector3(-3.6, 1.7, -2.2), Vector3(-1.25, 1.3, -0.3)],
	"back_corner": [Vector3(-2.6, 1.9, -3.2), Vector3(-0.6, 1.2, -1.0)],
	"inside_counter": [Vector3(-0.6, 1.85, -0.2), Vector3(0.95, 1.05, 0.0)],
	"inside_north": [Vector3(0.6, 1.7, 0.7), Vector3(-0.6, 1.9, -0.95)],
	"inside_south": [Vector3(-0.5, 1.7, -0.6), Vector3(0.2, 2.2, 0.95)],
	"counter_close": [Vector3(0.4, 1.45, 0.05), Vector3(1.0, 1.0, -0.1)],
}

var _out := ""
var _camera: Camera3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("capture_booths.cfg")
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
	await _key_event(KEY_ENTER)
	await create_timer(1.5, true, false, true).timeout
	_camera = Camera3D.new()
	_camera.fov = 60.0
	root.add_child(_camera)
	_camera.make_current()
	var world := app.get_node("IndustrialLoop")
	var booths := world.find_children("GuardBooth", "Node3D", true, false)
	for index in range(booths.size()):
		var booth := booths[index] as Node3D
		var owner_name := String(booth.get_parent().name)
		for view in VIEWS:
			_camera.global_position = booth.to_global(VIEWS[view][0])
			await create_timer(0.6, true, false, true).timeout
			_camera.look_at_from_position(booth.to_global(VIEWS[view][0]),
				booth.to_global(VIEWS[view][1]))
			for frame in range(3):
				await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(_out.path_join("%d_%s_%s.png"
				% [index, owner_name, view]))
		if booth.has_method("open_window"):
			booth.call("open_window", true)
			_camera.look_at_from_position(booth.to_global(VIEWS["driver_at_window"][0]),
				booth.to_global(VIEWS["driver_at_window"][1]))
			await create_timer(2.0, true, false, true).timeout
			root.get_texture().get_image().save_png(_out.path_join("%d_%s_window_open.png"
				% [index, owner_name]))
	quit(0)


func _key_event(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await process_frame
