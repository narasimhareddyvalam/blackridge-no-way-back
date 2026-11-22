extends SceneTree
## The hangar's guard encounter in play (#359, Mission 3's step 6): Maya at the service gate; Ethan
## aiming over his shoulder and seen from the side; one of Adrian's men shooting; a man down; the
## office door. Run windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1280x800 \
##     --script ../tools/captures/capture_hangar.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"last_run\"\n\n[run]\nstage=3\n"

var _out := ""
var _app: Node3D
var _driver: CharacterBody3D
var _camera: Camera3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 800))
	var progress := OS.get_user_data_dir().path_join("capture_hangar.cfg")
	var file := FileAccess.open(progress, FileAccess.WRITE)
	file.store_string(SAVE)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	_app.get_node("DrivingTrial").checkpoint_path = progress
	root.add_child(_app)
	await process_frame
	await process_frame
	_app.call("_begin")
	await _wait(1.5)
	_driver = _app.get("driver") as CharacterBody3D
	var run := _app.get("run") as Node
	var maya := run.get("maya") as Node3D
	var encounter := run.get("encounter") as Node
	var field := _app.get_node("IndustrialLoop").get("harbour_flats").get("airfield") as Node3D
	_app.call("_stand_ethan", maya.global_position + maya.global_basis.z * 2.2,
		maya.global_position)
	await _wait(1.0)
	_driver.call("look_toward", (maya.global_position - _driver.global_position).normalized())
	await _wait(0.5)
	await _save("1_maya_at_the_gate")
	run.call("do_foot_action", _driver.global_position)
	await _wait(8.0)
	await _save("2_her_pistol")
	await _wait(12.0)
	var guards: Array = encounter.get("guards")
	var door_man := guards[0] as Node3D
	var behind := Vector3(door_man.global_basis.z.x, 0.0, door_man.global_basis.z.z).normalized()
	_place(door_man.global_position + behind * 9.0, door_man.global_position)
	Input.action_press("aim")
	await _wait(0.8)
	_driver.call("aim_toward", door_man.global_position + Vector3.UP * 1.3)
	await _wait(0.6)
	await _save("3_aiming_over_the_shoulder")
	_camera = Camera3D.new()
	_camera.fov = 40.0
	root.add_child(_camera)
	var side := Vector3.UP.cross(-behind).normalized()
	_camera.look_at_from_position(_driver.global_position + side * 3.0 + Vector3.UP * 1.5
		- behind * 0.6, _driver.global_position + Vector3.UP * 1.25)
	_camera.make_current()
	await _wait(0.3)
	await _save("4_aiming_from_the_side")
	(_driver.call("get_camera") as Camera3D).make_current()
	Input.action_release("aim")
	encounter.call("reset")
	await _wait(0.3)
	var walker := guards[1] as Node3D
	var ahead := -Vector3(walker.global_basis.z.x, 0.0, walker.global_basis.z.z).normalized()
	Input.action_release("aim")
	_place(walker.global_position + ahead * 10.0, walker.global_position)
	var waited := 0.0
	while String(walker.get("state")) != "attack" and waited < 6.0:
		await physics_frame
		waited += 1.0 / 60.0
	await _wait(0.8)
	var across := Vector3.UP.cross(ahead).normalized()
	var middle := walker.global_position.lerp(_driver.global_position, 0.5)
	_camera.look_at_from_position(middle + across * 9.0 + Vector3.UP * 1.8, middle
		+ Vector3.UP * 1.1)
	_camera.make_current()
	await _wait(0.2)
	await _save("5_he_shoots")
	(_driver.call("get_camera") as Camera3D).make_current()
	Input.action_press("aim")
	await _wait(0.6)
	for shot in range(2):
		_driver.call("aim_toward", walker.global_position + Vector3.UP * 1.3)
		await _wait(0.1)
		_tap("fire")
		await _wait(0.4)
	Input.action_release("aim")
	await _wait(3.5)
	var lying := walker.global_position
	_camera.look_at_from_position(lying + across * 2.6 + ahead * 1.5 + Vector3.UP * 1.3,
		lying + Vector3.UP * 0.25)
	_camera.make_current()
	await _wait(0.2)
	await _save("6_a_man_down")
	encounter.call("reset")
	var door: Vector3 = field.get("office_door")
	_camera.fov = 55.0
	_camera.look_at_from_position(door + Vector3(-6.0, 1.7, -7.0), door + Vector3(0.0, 1.2, 0.0))
	await _wait(0.3)
	await _save("7_the_office_door")
	var apron: Rect2 = field.get("apron")
	_camera.fov = 60.0
	_camera.look_at_from_position(Vector3(apron.get_center().x - 10.0, 28.0, apron.end.y + 30.0),
		Vector3(apron.get_center().x, 0.0, apron.get_center().y))
	await _wait(0.3)
	await _save("8_the_apron_lit")
	quit(0)


func _place(at: Vector3, look: Vector3) -> void:
	_driver.global_position = at
	_driver.velocity = Vector3.ZERO
	var facing := Vector3(look.x - at.x, 0.0, look.z - at.z).normalized()
	_driver.call("face", facing)
	_driver.call("look_toward", facing)


func _tap(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _save(view: String) -> void:
	for frame in range(3):
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join(view + ".png"))
