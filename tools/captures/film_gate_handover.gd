extends SceneTree
## The run sheet handed over at the transfer shed's gate, as played (#348): the van stopped with
## its front on the stop line, Ethan's window level with the booth's; E pressed; the guard leans in,
## slides his window open with his hand, turns to Ethan, checks the sheet, slides it shut and the
## barrier rises. Filmed from Ethan's seat turned to the booth, as a player turns his view with the
## mouse ("driver"), or from beside the
## van ("side"). Run windowed with Movie Maker, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1280x800 --fixed-fps 30 \
##     --write-movie <absolute .avi> --script ../tools/captures/film_gate_handover.gd -- <view>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const VAN_FRONT := Vector3(0.0, 1.0, -2.52)
const SIDE := [Vector3(-1.5, 1.9, 3.2), Vector3(-1.55, 1.45, -1.0)]
const FILM := 16.0

var _camera: Camera3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var view := args[0] if not args.is_empty() else "driver"
	var progress := OS.get_user_data_dir().path_join("film_gate_handover.cfg")
	var file := FileAccess.open(progress, FileAccess.WRITE)
	file.store_string(SAVE)
	file.close()
	var app := (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	app.get_node("DrivingTrial").checkpoint_path = progress
	root.add_child(app)
	await process_frame
	await process_frame
	await _key(KEY_ENTER)
	await create_timer(1.0).timeout
	var shed := app.get_node("IndustrialLoop").get("transfer_shed") as Node3D
	var van := app.get_node("FreightVan") as Node3D
	var line_z: float = float(shed.get("GATE_Z")) + float(shed.get("STOP_LINE_OUT"))
	van.call("recover", Transform3D(Basis.IDENTITY, Vector3(float(shed.get("LANE_X")), 0.1,
		line_z - VAN_FRONT.z)))
	var booth := shed.get_node("GuardBooth") as Node3D
	if view == "side":
		_camera = Camera3D.new()
		_camera.fov = 55.0
		root.add_child(_camera)
		_camera.make_current()
		_camera.look_at_from_position(van.to_global(SIDE[0]), van.to_global(SIDE[1]))
	else:
		var presentation := van.get_node("VanPresentation") as Node3D
		await create_timer(0.5).timeout
		var eye := (presentation.get("_look") as Node3D).position
		var to := presentation.to_local(booth.call("opening_centre")) - eye
		presentation.set("_look_target", Vector2(atan2(to.y, Vector2(to.x, to.z).length())
			+ float(presentation.get("CAMERA_TILT")), atan2(-to.x, -to.z)))
	await create_timer(1.5).timeout
	await _key(KEY_E)
	await create_timer(FILM).timeout
	quit(0)


func _key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await process_frame
