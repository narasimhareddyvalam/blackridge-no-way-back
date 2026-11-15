extends SceneTree
## Ethan's legs after the fixes of #287 (steps 4-6 of #289), in a 1280x800 window on Mission 2's
## start save: up the dock stair, down it, across its flight and from its top along the landing,
## and running on the dock floor, each from beside him, in front of him and behind him, while he
## moves by the game's own walk and run keys. Real keys and clicks are swallowed. Usage, from the
## repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --script ../tools/captures/capture_legs.gd \
##     -- <absolute output folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const DOCKED := Vector3(-47.75, 0.1, 23.16)
const BELOW := Vector3(-44.2, 0.0, 17.4)
const ABOVE := Vector3(-44.2, 0.0, 13.45)
const MID_FLIGHT := Vector3(-44.2, 0.0, 14.75)
const ACROSS_TO := Vector3(-42.5, 0.0, 14.75)
const ALONG_LANDING := Vector3(-45.6, 0.0, 13.4)
const RUN_FROM := Vector3(-46.2, 1.3, 16.2)
const RUN_TO := Vector3(-46.2, 1.3, 8.0)
const ANGLES := {"beside": Vector3(2.2, 0.9, 0.0), "in_front": Vector3(0.0, 0.9, -2.4),
	"behind": Vector3(0.0, 1.0, 2.6)}


class InputGate extends Node:
	func _input(event: InputEvent) -> void:
		if event is InputEventMouse or event is InputEventKey:
			get_viewport().set_input_as_handled()


var _app: Node3D
var _driver: CharacterBody3D
var _camera: Camera3D
var _folder: String
var _number := 0
var _report := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var progress := OS.get_user_data_dir().path_join("capture_legs_progress.cfg")
	var file := FileAccess.open(progress, FileAccess.WRITE)
	file.store_string(SAVE)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = progress
	root.add_child(_app)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 800))
	var gate := InputGate.new()
	gate.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(gate)
	await process_frame
	await process_frame
	_app.call("_begin")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_folder = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(_folder)
	var van := _app.get_node("FreightVan") as CharacterBody3D
	_driver = _app.get("driver")
	_camera = Camera3D.new()
	_camera.far = 200.0
	_camera.fov = 50.0
	root.add_child(_camera)
	await _seconds(1.0)
	van.call("recover", Transform3D(Basis(Vector3.UP, PI), DOCKED))
	await _seconds(1.0)
	_tap_interact()
	await _seconds(6.0)
	await _place(BELOW, Vector3.FORWARD)
	await _walk(ABOVE, 14.0, "up_the_stair", [1.8, 3.4], false)
	_driver.call("look_toward", Vector3.BACK)
	await _seconds(0.6)
	await _walk(BELOW, 14.0, "down_the_stair", [0.9, 1.7], false)
	await _place(BELOW, Vector3.FORWARD)
	await _walk(MID_FLIGHT, 8.0, "", [], false)
	await _walk(ACROSS_TO, 1.6, "across_the_flight", [0.6], false)
	await _place(BELOW, Vector3.FORWARD)
	await _walk(ABOVE, 14.0, "", [], false)
	await _walk(ALONG_LANDING, 4.0, "along_the_landing", [0.5, 1.2], false)
	await _place(RUN_FROM, Vector3.FORWARD)
	await _walk(RUN_TO, 4.0, "running_on_the_dock", [0.8, 1.4], true)
	var notes := FileAccess.open(_folder.path_join("legs_stills.txt"), FileAccess.WRITE)
	notes.store_string("\n".join(_report) + "\n")
	notes.close()
	quit(0)


func _tap_interact() -> void:
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	Input.parse_input_event(event)
	var up := InputEventAction.new()
	up.action = "interact"
	up.pressed = false
	Input.parse_input_event(up)


func _place(at: Vector3, facing: Vector3) -> void:
	_driver.global_position = at
	_driver.velocity = Vector3.ZERO
	_driver.call("face", facing)
	_driver.call("look_toward", facing)
	await physics_frame
	await _seconds(0.5)


## Walks (or runs) toward `goal` by the game's keys, taking stills from each angle at `at` seconds.
func _walk(goal: Vector3, limit: float, stem: String, at: Array, running: bool) -> void:
	var time := 0.0
	var next := 0
	Input.action_press("accelerate")
	if running:
		Input.action_press("sprint")
	while Vector2(goal.x - _driver.global_position.x, goal.z - _driver.global_position.z) \
			.length() > 0.3 and time < limit:
		var to := goal - _driver.global_position
		_driver.call("look_toward", Vector3(to.x, 0.0, to.z).normalized())
		await physics_frame
		time += 1.0 / 60.0
		if next < at.size() and time >= float(at[next]):
			for angle: String in ANGLES:
				await _still("%s_%.1fs_%s" % [stem, time, angle], ANGLES[angle])
			next += 1
	Input.action_release("sprint")
	Input.action_release("accelerate")
	await _seconds(0.4)


func _still(stem: String, offset: Vector3) -> void:
	var facing := -_driver.global_basis.z
	var model := _driver.get_node_or_null("Ethan") as Node3D
	if model != null:
		facing = model.global_basis.z
	facing = Vector3(facing.x, 0.0, facing.z).normalized()
	var left := Vector3.UP.cross(facing)
	var hips := _driver.global_position + Vector3.UP * 0.8
	var eye := hips + left * offset.x + Vector3.UP * (offset.y - 0.8) - facing * offset.z
	var previous := root.get_viewport().get_camera_3d()
	_camera.look_at_from_position(eye, hips)
	_camera.make_current()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	_number += 1
	root.get_texture().get_image().save_png(_folder.path_join("%02d_%s.png" % [_number, stem]))
	_report.append("%02d_%s: from %s" % [_number, stem, eye.snapped(Vector3.ONE * 0.01)])
	if previous != null:
		previous.make_current()


func _seconds(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout
