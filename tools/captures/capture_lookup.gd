extends SceneTree
## The rain seen looking up (the audit, #354): under a street lamp, under the compound gate's
## flood and at the shed's dock front, straight up and half up, each standing where a person
## would. Run windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1280x800 \
##     --script ../tools/captures/capture_lookup.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const STANDS := {
	"street": Vector3.ZERO,
	"gate": Vector3(199.5, 1.7, 148.0),
	"dock": Vector3(-47.75, 1.7, 24.5),
}
const LOOKS := {
	"straight_up": Vector3(0.03, 1.0, 0.02),
	"half_up": Vector3(0.0, 0.85, -0.55),
}

var _out := ""
var _camera: Camera3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("capture_lookup.cfg")
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
	_camera = Camera3D.new()
	_camera.fov = 60.0
	root.add_child(_camera)
	_camera.make_current()
	var rain := app.get_node("IndustrialLoop").get("lamp_rain") as Node3D
	var stands := STANDS.duplicate()
	for volume: Node3D in rain.get("volumes"):
		if String(volume.name).begins_with("LampRainStreet"):
			stands["street"] = Vector3(volume.global_position.x + 0.6, 1.7, volume.global_position.z)
			break
	for stand: String in stands:
		for look: String in LOOKS:
			var eye: Vector3 = stands[stand]
			_camera.global_position = eye
			await create_timer(1.2, true, false, true).timeout
			_camera.look_at_from_position(eye, eye + LOOKS[look], Vector3.FORWARD)
			for frame in range(3):
				await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(_out.path_join("%s_%s.png" % [stand, look]))
	quit(0)
