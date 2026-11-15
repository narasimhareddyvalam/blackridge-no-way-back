extends SceneTree
## Docking at bay 9 after the fixes of #287 (steps 1-3 of #289), in a 1280x800 window on Mission
## 2's start save: the game's own view in reverse, the rear camera with its parking guides and
## red stop line, at 3, 1 and 0.3 m from the bumpers, at the red line and touching them, and turned
## 1.5° at the line; the dash screen's picture; then from outside, the plate laid on the van's sill,
## along the lift's deck, from the dock floor and from the court, empty and loaded. It sets each state
## directly; the tests reach them by real keys. Real keys and clicks are swallowed. Usage, from the
## repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --script ../tools/captures/capture_docking.gd \
##     -- <absolute output folder>

const ParkingGuides = preload("res://features/vehicles/freight_van/parking_guides.gd")
const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const BAY := -47.75
const BUMPERS := 20.13
const REAR := 3.012
const ORIGIN_Y := 0.1
const SIDE_LOW := [Vector3(-46.95, 1.15, 18.9), Vector3(-47.75, 0.55, 20.7), 55.0]
const FROM_DOCK := [Vector3(-46.5, 2.7, 18.4), Vector3(-47.75, 0.85, 20.7), 55.0]
const FROM_COURT := [Vector3(-44.2, 2.2, 26.5), Vector3(-47.75, 1.0, 20.5), 50.0]


class InputGate extends Node:
	func _input(event: InputEvent) -> void:
		if event is InputEventMouse or event is InputEventKey:
			get_viewport().set_input_as_handled()


var _app: Node3D
var _van: CharacterBody3D
var _bay: Node
var _shed: Node3D
var _camera: Camera3D
var _folder: String
var _number := 0
var _report := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var progress := OS.get_user_data_dir().path_join("capture_docking_progress.cfg")
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
	_van = _app.get_node("FreightVan")
	_shed = _app.get_node("IndustrialLoop").get("transfer_shed")
	_bay = _shed.get("bay_nine")
	_camera = Camera3D.new()
	_camera.far = 400.0
	root.add_child(_camera)
	await _seconds(1.0)
	for gap: float in [3.0, 1.0, 0.3, ParkingGuides.STOP_LINE - 0.005, 0.0]:
		await _place(gap, 0.0)
		await _game_view("reverse_at_%.2f_m" % gap)
	await _place(ParkingGuides.STOP_LINE - 0.005, 1.5)
	await _game_view("reverse_at_the_line_turned_1.5_degrees")
	await _place(1.0, 0.0)
	var dash := (_van.get_node("VanPresentation").get("reverse_view") as SubViewport)
	dash.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	_keep(dash.get_texture().get_image(), "dash_screen_at_1.00_m", "the dash screen's picture")
	await _place(ParkingGuides.STOP_LINE / 2.0, 0.0)
	var lift := _shed.get_node("Building/DockLift9") as Node3D
	await _hold_lift(func() -> bool: return bool(lift.call("at_bottom")))
	await _seconds(1.5)
	await _outside("plate_on_the_sill_along_the_deck", SIDE_LOW)
	await _outside("plate_on_the_sill_from_the_dock", FROM_DOCK)
	await _outside("docked_from_the_court", FROM_COURT)
	(_shed.get("pallet_jack") as Node).call("stow", _shed.get_node("Building/Pallet6"))
	await _seconds(2.5)
	await _outside("loaded_plate_on_the_sill_along_the_deck", SIDE_LOW)
	await _outside("loaded_plate_on_the_sill_from_the_dock", FROM_DOCK)
	var notes := FileAccess.open(_folder.path_join("docking_stills.txt"), FileAccess.WRITE)
	notes.store_string("\n".join(_report) + "\n")
	notes.close()
	quit(0)


func _place(gap: float, turn: float) -> void:
	_van.call("recover", Transform3D(Basis(Vector3.UP, PI), Vector3(BAY, ORIGIN_Y, BUMPERS + 12.0)))
	await _seconds(0.3)
	var basis := Basis(Vector3.UP, PI + deg_to_rad(turn))
	var back := basis * Vector3(0.0, 0.0, REAR)
	_van.call("recover", Transform3D(basis, Vector3(BAY - back.x, ORIGIN_Y, BUMPERS + gap - back.z)))
	_van.set("rear_doors_open", true)
	_van.set("gear", -1)
	await _seconds(1.5)


func _game_view(stem: String) -> void:
	var rear: Camera3D = _van.get_node("VanPresentation").get("rear_camera")
	rear.make_current()
	await _seconds(0.3)
	await RenderingServer.frame_post_draw
	_keep(root.get_texture().get_image(), stem, "the game's view in reverse, %s, the bay's verdict %s"
		% [stem, _bay.get("verdict")])


func _outside(stem: String, view: Array) -> void:
	_camera.fov = view[2]
	_camera.look_at_from_position(view[0], view[1])
	_camera.make_current()
	await _seconds(0.3)
	await RenderingServer.frame_post_draw
	_keep(root.get_texture().get_image(), stem, "from %s looking at %s" % [view[0], view[1]])


func _hold_lift(done: Callable) -> void:
	Input.action_press("interact")
	_bay.call("operate_lift")
	var time := 0.0
	while not done.call() and time < 12.0:
		await physics_frame
		time += 1.0 / 60.0
	Input.action_release("interact")


func _keep(image: Image, stem: String, where: String) -> void:
	_number += 1
	image.save_png(_folder.path_join("%02d_%s.png" % [_number, stem]))
	_report.append("%02d_%s: %s" % [_number, stem, where])


func _seconds(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout
