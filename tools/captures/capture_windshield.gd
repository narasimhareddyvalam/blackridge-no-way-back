extends SceneTree
## The windshield's water (#346), from the driver's eye at night, the van pulled forward of bay 9
## facing the yard's lamps: the wipers off after 30 s of rain (three looks), then on fast, twelve
## frames running through a sweep. Each step's stills sit beside these. Run windowed, from the
## repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1280x800 \
##     --script ../tools/captures/capture_windshield.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const PULLED_FORWARD := Transform3D(Basis(Vector3.UP, PI), Vector3(-47.75, 0.1, 26.14))
const EYE := Vector3(-0.45, 1.88, -0.72)
const LOOKS := {"ahead": Vector3(0.0, -0.12, -1.0), "left": Vector3(-0.35, -0.12, -1.0),
	"right": Vector3(0.45, -0.15, -1.0)}
const OFF := 0
const FAST := 2
const UNWIPED := 30.0
const SWEEP_FRAMES := 12

var _out := ""
var _van: Node3D
var _camera: Camera3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("capture_windshield.cfg")
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
	_van = app.get_node("FreightVan") as Node3D
	_van.call("recover", PULLED_FORWARD)
	_camera = Camera3D.new()
	_camera.fov = 70.0
	root.add_child(_camera)
	_camera.make_current()
	await _wipers(OFF)
	_place("ahead")
	await create_timer(UNWIPED, true, false, true).timeout
	for look in LOOKS:
		_place(look)
		await _save("1_unwiped_%s" % look)
	_place("ahead")
	await _wipers(FAST)
	await create_timer(3.0, true, false, true).timeout
	for index in range(SWEEP_FRAMES):
		await _save("2_sweep_%02d" % index)
	quit(0)


func _place(look: String) -> void:
	var eye := _van.to_global(EYE)
	_camera.look_at_from_position(eye, eye + _van.global_basis * LOOKS[look])


func _save(label: String) -> void:
	for frame in range(2):
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join(label + ".png"))


func _wipers(setting: int) -> void:
	while int(_van.get("wiper_setting")) != setting:
		for pressed in [true, false]:
			var event := InputEventAction.new()
			event.action = "wipers"
			event.pressed = pressed
			Input.parse_input_event(event)
			await process_frame


func _key_event(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await process_frame
