extends SceneTree
## The audit's third fix (#326-#327): bay 9's pallet jack in stills as Ethan works it by keys,
## each taken when the moment comes: lowered under the load, its rollers on the floor; pumped,
## its forks and the load raised while its rollers and steer wheels stay down, seen low from the
## side; its handle swung as he walks it round; swung right round, pivoting about its rollers.
## Run windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game \
##     --script ../tools/captures/capture_pallet_jack.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const DOCKED := Vector3(-47.75, 0.1, 23.16)
const TO_THE_SIDE_DOOR: Array[Vector3] = [Vector3(-39.0, 0.0, 22.0), Vector3(-39.0, 0.0, 17.5)]
const INTO_THE_SHED: Array[Vector3] = [Vector3(-41.2, 0.0, 17.5), Vector3(-44.2, 0.0, 16.0),
	Vector3(-44.2, 0.0, 14.8), Vector3(-44.2, 0.0, 13.4), Vector3(-45.6, 0.0, 13.4),
	Vector3(-47.2, 0.0, 15.15)]
## Shots in the jack's own frame (its forks toward -z): the camera's place, where it looks, and
## the field of view.
const LOWERED := ["lowered_rollers_on_floor", Vector3(-1.1, 0.25, -0.6), Vector3(0.0, 0.06,
	-0.5), 40.0]
const RAISED := ["pumped_forks_up_rollers_down", Vector3(-1.1, 0.25, -0.6), Vector3(0.0, 0.06,
	-0.5), 40.0]
const SWUNG := ["handle_swung_as_he_walks", Vector3(-2.2, 2.4, 2.6), Vector3(0.0, 0.5, 0.4),
	50.0]
const PIVOT := ["swung_round_pivoting", Vector3(0.0, 4.2, 0.6), Vector3(0.0, 0.0, -0.2), 55.0]

var _out := ""
var _app: Node3D
var _van: CharacterBody3D
var _driver: CharacterBody3D
var _jack: Node3D
var _camera: Camera3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("capture_pallet_jack_progress.cfg")
	var file := FileAccess.open(progress, FileAccess.WRITE)
	file.store_string(SAVE)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	_app.get_node("DrivingTrial").checkpoint_path = progress
	root.add_child(_app)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 800))
	_van = _app.get_node("FreightVan")
	_driver = _app.get("driver")
	await process_frame
	await process_frame
	await _key(KEY_ENTER)
	await _seconds(1.0)
	var shed := _app.get_node("IndustrialLoop").get("transfer_shed") as Node3D
	_jack = shed.find_child("PalletJack", true, false) as Node3D
	_van.call("recover", Transform3D(Basis(Vector3.UP, PI), DOCKED))
	await _seconds(1.5)
	await _key(KEY_E)
	await _seconds(3.0)
	await _walk(TO_THE_SIDE_DOOR)
	await _key(KEY_E)
	await _seconds(1.5)
	await _walk(INTO_THE_SHED)
	_camera = Camera3D.new()
	root.add_child(_camera)
	await _shot(LOWERED)
	await _key(KEY_E)
	await _seconds(0.5)
	for stroke in range(6):
		await _key(KEY_E)
		await _seconds(0.85)
	await _shot(RAISED)
	await _hold(["brake"], 1.6)
	await _hold(["accelerate", "steer_left"], 1.6)
	await _shot(SWUNG)
	await _hold(["accelerate", "steer_left"], 3.0)
	await _shot(PIVOT)
	for action: String in ["accelerate", "steer_left"]:
		Input.action_release(action)
	quit(0)


func _shot(shot: Array) -> void:
	_camera.fov = shot[3]
	_camera.look_at_from_position(_jack.to_global(shot[1]), _jack.to_global(shot[2]))
	_camera.make_current()
	await process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join("%s.png" % shot[0]))
	_camera.clear_current()


func _hold(actions: Array, seconds: float) -> void:
	for action: String in actions:
		Input.action_press(action)
	await _seconds(seconds)


func _walk(points: Array[Vector3], limit: float = 12.0) -> void:
	for point in points:
		var time := 0.0
		Input.action_press("accelerate")
		while _flat(point - _driver.global_position).length() > 0.3 and time < limit:
			_driver.call("look_toward", _flat(point - _driver.global_position).normalized())
			await physics_frame
			time += 1.0 / 60.0
		Input.action_release("accelerate")
	await _seconds(0.4)


func _flat(value: Vector3) -> Vector3:
	return Vector3(value.x, 0.0, value.z)


func _key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await process_frame
	await process_frame


func _seconds(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout
