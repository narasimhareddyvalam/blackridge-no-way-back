extends SceneTree
## #267 part C: the south valley road's gas station and main street in stills at night. The van
## stands on the road west of the station, low beams on; views: the station from the road as
## the driver comes (A), the forecourt under the canopy (B), the store's front and its sidewalk
## (C), main street's shops and their parked cars (D), the price sign from along the road (E),
## and the forecourt from the store's door (F). With "price", the town is shown and hidden in
## alternating blocks from view A for tools/tests/gpu_price.py (MTL_HUD_ENABLED=1
## MTL_HUD_LOG_ENABLED=1). Run windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1280x800 \
##     --script ../tools/captures/capture_town.gd -- <absolute stills folder> [price]

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const VIEWS := {"A_from_road": [Vector3(-22.0, 1.6, 170.0), Vector3(14.0, 2.5, 182.0)],
	"B_forecourt": [Vector3(3.0, 1.7, 178.0), Vector3(16.0, 1.6, 182.0)],
	"C_store_front": [Vector3(8.0, 1.7, 182.5), Vector3(4.0, 1.4, 189.0)],
	"D_main_street": [Vector3(30.0, 1.7, 179.0), Vector3(44.0, 2.0, 190.0)],
	"E_price_sign": [Vector3(48.0, 1.6, 171.5), Vector3(29.0, 5.0, 175.5)],
	"F_from_door": [Vector3(6.0, 1.7, 187.8), Vector3(16.0, 2.0, 176.0)]}
const CYCLES := 10
const BLOCK := 1.0
const SKIP := 0.3

var _out := ""
var _camera: Camera3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	var price := args.size() > 1 and args[1] == "price"
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("capture_town.cfg")
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
	app.call("_begin")
	var world := app.get_node("IndustrialLoop") as Node3D
	var van := app.get_node("FreightVan") as Node3D
	var town := world.get_node("TownStation") as Node3D
	_camera = Camera3D.new()
	_camera.fov = 60.0
	root.add_child(_camera)
	await create_timer(2.0, true, false, true).timeout
	van.call("recover", Transform3D(Basis.looking_at(Vector3.RIGHT, Vector3.UP),
		Vector3(-30.0, 0.0, 170.2)))
	await create_timer(0.6, true, false, true).timeout
	if price:
		await _price(town)
		quit(0)
		return
	for label: String in VIEWS:
		var view: Array = VIEWS[label]
		_camera.look_at_from_position(view[0], view[1])
		_camera.make_current()
		for frame in range(3):
			await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(_out.path_join(label + ".png"))
	quit(0)


func _price(town: Node3D) -> void:
	print("GPU PRICE: window %s, vsync %s, MetalFX scale %.2f" % [root.get_visible_rect().size,
		DisplayServer.window_get_vsync_mode(), root.scaling_3d_scale])
	var view: Array = VIEWS["A_from_road"]
	_camera.look_at_from_position(view[0], view[1])
	_camera.make_current()
	for cycle in range(CYCLES):
		for shown in [true, false]:
			town.visible = shown
			var began := Time.get_unix_time_from_system()
			await create_timer(BLOCK, true, false, true).timeout
			var ended := Time.get_unix_time_from_system()
			print("GPU PRICE BLOCK|TWN|%s|cycle %d|time %.3f-%.3f|skip %.2f|particles 0|road|-"
				% ["on" if shown else "off", cycle + 1, began, ended, SKIP])
	print("GPU PRICE DONE")
