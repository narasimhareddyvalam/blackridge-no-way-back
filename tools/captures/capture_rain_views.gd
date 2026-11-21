extends SceneTree
## The rain at night from where the player sees it (the audit, #354), each view beside a real
## photo of the same: the van's own headlights from the driver's seat; a street lamp from the road
## and from under it looking up at it; the compound gate's flood from the driveway; a yard flood
## across the compound; the shed's dock front; the van's headlights from in front; the
## lit ground at the dock and under a street lamp, close. Run windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1280x800 \
##     --script ../tools/captures/capture_rain_views.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const FIXED := {
	"3_gate_drive": [Vector3(199.3, 2.0, 163.0), Vector3(201.0, 4.0, 146.0)],
	"4_yard_flood": [Vector3(205.0, 1.7, 124.0), Vector3(222.0, 6.0, 140.0)],
	"5_dock_front": [Vector3(-44.0, 1.7, 33.0), Vector3(-47.75, 3.5, 20.0)],
	"6_headlights_outside": [Vector3(-25.5, 1.6, 76.0), Vector3(-28.0, 1.0, 90.0)],
	"7_dock_ground": [Vector3(-46.0, 1.2, 30.0), Vector3(-47.75, 0.0, 24.0)],
}

var _out := ""
var _camera: Camera3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("capture_rain_views.cfg")
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
	(app.get_node("FreightVan") as Node3D).call("recover", Transform3D(Basis.IDENTITY,
		Vector3(-28.0, 0.1, 93.0)))
	await create_timer(2.0, true, false, true).timeout
	for frame in range(3):
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join("0_headlights_seat.png"))
	_camera = Camera3D.new()
	_camera.fov = 60.0
	root.add_child(_camera)
	_camera.make_current()
	var rain := app.get_node("IndustrialLoop").get("lamp_rain") as Node3D
	var head := Vector3.ZERO
	for volume: Node3D in rain.get("volumes"):
		if String(volume.name).begins_with("LampRainStreet"):
			head = volume.global_position
			break
	var views := FIXED.duplicate()
	views["1_street_lamp_road"] = [Vector3(head.x + 16.0, 1.9, head.z + 3.0), head + Vector3(0, -2.5, 0)]
	views["2_street_lamp_up"] = [Vector3(head.x + 2.5, 1.7, head.z + 0.5), head + Vector3(0, 0.2, 0)]
	views["8_street_ground"] = [Vector3(head.x + 5.0, 1.2, head.z + 4.0), Vector3(head.x, 0.0,
		head.z)]
	var names := views.keys()
	names.sort()
	for view: String in names:
		var eye: Vector3 = views[view][0]
		_camera.global_position = eye
		await create_timer(1.2, true, false, true).timeout
		_camera.look_at_from_position(eye, views[view][1], Vector3.UP)
		for frame in range(3):
			await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(_out.path_join(view + ".png"))
	quit(0)
