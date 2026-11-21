extends SceneTree
## Mission 2's last parts in play (#358): its opening (from the save Mission 1's end leaves) at
## each shot, the dispatcher's text after it; the inspection's bill of lading; a guard seeing
## Ethan, the mark over him filling; and PULL OVER where the hill road begins. Run windowed, from
## the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1280x800 \
##     --script ../tools/captures/capture_mission_two_end.gd -- <absolute stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=%d\n%s"
const OPENING_AT: Array[float] = [2.0, 6.5, 12.0, 16.5, 21.5]

var _out := ""
var _app: Node3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 800))
	await _open(0, "opening=true\n")
	var waited := 0.0
	for index in range(OPENING_AT.size()):
		await _wait(OPENING_AT[index] - waited)
		waited = OPENING_AT[index]
		await _save("1_opening_%d" % (index + 1))
	await _wait(3.5)
	await _save("2_dispatch_text")
	await _close()
	await _open(1, "")
	(_app.get("cargo") as Node).call("_check_seal")
	_app.call("_close_run_sheet")
	await _wait(1.0)
	await _save("3_read_the_bill_prompt")
	await _action("interact")
	await _wait(1.0)
	await _save("4_the_bill_of_lading")
	await _close()
	await _open(3, "")
	await _wait(1.5)
	await _action("interact")
	await _wait(3.0)
	var escape := (_app.get("cargo") as Node).get("escape") as Node
	var guard := (escape.get("guards") as Array)[0] as Node3D
	var driver := _app.get("driver") as CharacterBody3D
	guard.call("hold", Transform3D(Basis(Vector3.UP, -PI / 2.0), Vector3(218.0, 0.02, 124.0)))
	driver.global_position = Vector3(229.0, 0.02, 128.5)
	driver.call("look_toward", Vector3(-1.0, 0.0, -0.35))
	for frame in range(32):
		driver.global_position = Vector3(229.0, 0.02, 128.5)
		await physics_frame
	await _save("5_seen_by_a_guard")
	await _close()
	await _open(4, "")
	await _wait(1.5)
	var van := _app.get_node("FreightVan") as Node3D
	var points: PackedVector3Array = _app.get_node("IndustrialLoop").get("road_points")
	var along := (points[986] - points[994]).normalized()
	van.call("recover", Transform3D(Basis.looking_at(along, Vector3.UP), points[1003]
		+ Vector3.UP * 0.1))
	await _wait(2.0)
	await _save("6_pull_over")
	quit(0)


func _open(stage: int, extra: String) -> void:
	var progress := OS.get_user_data_dir().path_join("capture_mission_two_end.cfg")
	var file := FileAccess.open(progress, FileAccess.WRITE)
	file.store_string(SAVE % [stage, extra])
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	_app.get_node("DrivingTrial").checkpoint_path = progress
	root.add_child(_app)
	await process_frame
	await process_frame
	await _key(KEY_ENTER)
	await _wait(0.3)


func _close() -> void:
	_app.queue_free()
	await _wait(0.5)


func _key(code: Key) -> void:
	for pressed in [true, false]:
		var key := InputEventKey.new()
		key.keycode = code
		key.physical_keycode = code
		key.pressed = pressed
		Input.parse_input_event(key)
		await process_frame


func _action(action: String) -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame


func _wait(seconds: float) -> void:
	if seconds > 0.0:
		await create_timer(seconds, true, false, true).timeout


func _save(view: String) -> void:
	for frame in range(3):
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join(view + ".png"))
