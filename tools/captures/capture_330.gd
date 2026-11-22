extends SceneTree
## #330 found in stills, at night: the van docked at bay 9, its cab under the dock front's rain,
## looking up and down inside the cab from the seats (six times toward the driver's seat), and at
## the moon roof from above, the rain landing on its glass (#330's fix); and the passenger
## wiper's water at its top turn, the wipers on fast, close up, from beside the van and from the
## driver's eye, slowed to a fifth. Run windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1280x800 \
##     --script ../tools/captures/capture_330.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const DOCKED := Transform3D(Basis(Vector3.UP, PI), Vector3(-47.75, 0.1, 23.0))
const PULLED_FORWARD := Transform3D(Basis(Vector3.UP, PI), Vector3(-47.75, 0.1, 26.14))
const EYE := Vector3(-0.45, 1.88, -0.72)
const CAB_VIEWS := {
	"up_back": [EYE, EYE + Vector3(0.0, 1.0, 0.8)],
	"straight_up": [EYE, EYE + Vector3(0.05, 1.0, 0.05)],
	"to_driver": [Vector3(0.45, 1.6, -0.75), Vector3(-0.45, 0.9, -0.55)],
	"down_from_roof": [Vector3(0.0, 2.1, -0.58), Vector3(0.0, 0.5, -0.7)],
}
const FAST := 2
const SLOWED := 0.2
const BURST_FRAMES := 28

var _out := ""
var _van: Node3D
var _camera: Camera3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("capture_330.cfg")
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
	_camera = Camera3D.new()
	_camera.fov = 70.0
	root.add_child(_camera)
	_camera.make_current()
	_van.call("recover", DOCKED)
	await create_timer(2.0, true, false, true).timeout
	await _cab_shots("now")
	for index in range(6):
		await _shot("9_cab_now_to_driver_%d" % index, CAB_VIEWS["to_driver"][0],
			CAB_VIEWS["to_driver"][1])
		await create_timer(0.3, true, false, true).timeout
	await _shot("9_roof_from_above", Vector3(0.6, 2.9, -1.6), Vector3(0.0, 2.23, -0.58))
	_van.call("recover", PULLED_FORWARD)
	await create_timer(1.5, true, false, true).timeout
	await _passenger_wiper()
	quit(0)


func _cab_shots(variant: String) -> void:
	for view in CAB_VIEWS:
		await _shot("9_cab_%s_%s" % [variant, view], CAB_VIEWS[view][0], CAB_VIEWS[view][1])


func _passenger_wiper() -> void:
	while int(_van.get("wiper_setting")) != FAST:
		await _action("wipers")
	var particles := _van.find_child("VanParticles", true, false)
	await _next_flick(particles)
	var water := particles.call("passenger_water_at") as Transform3D
	var outward := water.basis.y.normalized()
	var views := {
		"close": water.origin + outward * 0.45 + Vector3.UP * 0.12,
		"side": water.origin + _van.global_basis.x * 0.9 + Vector3.UP * 0.25
			- _van.global_basis.z * 0.4,
		"driver": _van.to_global(EYE),
	}
	for view in views:
		_camera.look_at_from_position(views[view], water.origin)
		await _next_flick(particles)
		Engine.time_scale = SLOWED
		for index in range(BURST_FRAMES):
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(_out.path_join(
				"8_passenger_%s_%02d.png" % [view, index]))
		Engine.time_scale = 1.0


func _next_flick(particles: Node) -> void:
	var seen := int(particles.get("passenger_flicks"))
	var waited := 0.0
	while int(particles.get("passenger_flicks")) == seen and waited < 5.0:
		await process_frame
		waited += 1.0 / 60.0


func _shot(label: String, eye: Vector3, at: Vector3) -> void:
	_camera.look_at_from_position(_van.to_global(eye), _van.to_global(at))
	for frame in range(3):
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join(label + ".png"))


func _action(action: String) -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = action
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
