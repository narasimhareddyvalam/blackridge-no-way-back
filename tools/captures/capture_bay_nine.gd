extends SceneTree
## Bay 9's stills (step 2d), in a 1280x800 window on Mission 2's start save: the reverse camera as
## the van backs in, the open rear doors and the hold, the van docked, the chock under its wheel
## with the bay's lights turned, the lift in the floor from inside, and the bay from above in a
## debug light (ambient 6, no fog), which is not the game's look. It sets each state directly; the
## tests reach them by real keys. Real keys and clicks are swallowed. Usage, from the repository
## root:
##   HOME="$PWD/.scratch-home" Godot --path game --script ../tools/captures/capture_bay_nine.gd \
##     -- <absolute output folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const BACKING := Vector3(-47.75, 0.1, 27.5)
const DOCKED := Vector3(-47.75, 0.1, 23.16)
const BEHIND := [Vector3(-46.4, 1.6, 21.6), Vector3(-47.75, 1.2, 25.0), 60.0]
const COURT := [Vector3(-44.0, 1.7, 31.0), Vector3(-47.75, 1.6, 21.0), 50.0]
const WHEEL := [Vector3(-45.5, 0.9, 23.0), Vector3(-46.9, 0.25, 21.7), 50.0]
const LIGHTS := [Vector3(-43.5, 1.7, 29.0), Vector3(-46.2, 2.0, 20.1), 40.0]
const INSIDE := [Vector3(-46.6, 3.0, 15.5), Vector3(-47.75, 1.4, 21.0), 60.0]
const ABOVE := [Vector3(-47.75, 11.0, 27.5), Vector3(-47.75, 0.0, 22.0), 50.0]


class InputGate extends Node:
	func _input(event: InputEvent) -> void:
		if event is InputEventMouse or event is InputEventKey:
			get_viewport().set_input_as_handled()


var _app: Node3D
var _van: CharacterBody3D
var _camera: Camera3D
var _environment: Environment
var _folder: String
var _report := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var progress := OS.get_user_data_dir().path_join("capture_bay_nine_progress.cfg")
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
	_folder = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() \
		else ProjectSettings.globalize_path("res://").path_join("../captures/bay_nine/2d")
	DirAccess.make_dir_recursive_absolute(_folder)
	_van = _app.get_node("FreightVan")
	var world: Node3D = _app.get_node("IndustrialLoop")
	var shed: Node3D = world.get("transfer_shed")
	var holder := world.find_children("*", "WorldEnvironment", false, false)[0] as WorldEnvironment
	_environment = holder.environment
	_camera = Camera3D.new()
	_camera.far = 400.0
	root.add_child(_camera)
	await _seconds(1.0)
	_van.call("recover", Transform3D(Basis(Vector3.UP, PI), BACKING))
	_van.set("rear_doors_open", true)
	_van.set("gear", -1)
	await _seconds(3.0)
	var reverse := _van.get_node("VanPresentation").get("reverse_view") as SubViewport
	await RenderingServer.frame_post_draw
	reverse.get_texture().get_image().save_png(_folder.path_join("1_reverse_camera_backing_in.png"))
	_report.append("1_reverse_camera_backing_in: the van's own reverse view, its rear %.2f m from "
		% (_van.to_global(Vector3(0.0, 1.0, 3.01)).z - 20.13) + "the bumpers")
	await _view("2_open_doors_and_hold", BEHIND)
	_van.call("recover", Transform3D(Basis(Vector3.UP, PI), DOCKED))
	_van.set("rear_doors_open", true)
	await _seconds(3.0)
	var bay: Node = shed.get("bay_nine")
	_report.append("docked: verdict %s" % bay.get("verdict"))
	await _view("3_docked_from_the_court", COURT)
	bay.call("chock_wheel")
	await _seconds(0.5)
	await _view("4_chock_under_the_wheel", WHEEL)
	await _view("5_lights_turned_red_outside", LIGHTS)
	await _view("6_the_lift_and_the_hold_from_inside", INSIDE)
	_environment.ambient_light_energy = 6.0
	_environment.fog_enabled = false
	await _view("7_bay_from_above_debug_light_not_the_game", ABOVE)
	var text := "\n".join(_report)
	print(text)
	var notes := FileAccess.open(_folder.path_join("bay_nine_stills.txt"), FileAccess.WRITE)
	notes.store_string(text + "\n")
	notes.close()
	quit(0)


func _view(stem: String, view: Array) -> void:
	_camera.fov = view[2]
	_camera.look_at_from_position(view[0], view[1])
	_camera.make_current()
	await _seconds(1.5)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_folder.path_join(stem + ".png"))
	_report.append("%s: camera at %s looking at %s, fov %.0f" % [stem, str(view[0]),
		str(view[1]), view[2]])


func _seconds(duration: float) -> void:
	var end := Time.get_ticks_msec() + int(duration * 1000.0)
	while Time.get_ticks_msec() < end:
		await process_frame
