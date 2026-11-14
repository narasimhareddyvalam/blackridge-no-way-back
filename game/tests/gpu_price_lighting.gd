extends SceneTree
## #270-#271: what real light would cost, before anything is built: each lighting option shown
## and hidden in alternating blocks at three places, its GPU time logged by Apple's Metal
## Performance HUD (MTL_HUD_ENABLED=1, MTL_HUD_LOG_ENABLED=1) and read by tools/tests/gpu_price.py,
## as Assignment 6's effects were priced; then a still of each option at each place. The places:
## S down aisle 03 in the transfer shed, A the dock apron by the court, R the valley road under
## the town lamp at (-15, 63.8). The options: SH shadows from every lamp and light within 30 m of
## the camera (they fade out beyond it); AO screen-space ambient occlusion; IL screen-space
## indirect (bounced) light; GI SDFGI, Godot's real-time global illumination; LT SH, AO and IL
## together. It changes no game file: it sets them on the running game. Run windowed:
##   MTL_HUD_ENABLED=1 MTL_HUD_LOG_ENABLED=1 HOME="$PWD/.scratch-home" Godot --path game \
##     --resolution 1280x800 --script res://tests/gpu_price_lighting.gd -- <stills folder>

const SETTLE := 3.0
const CYCLES := 14
const BLOCK := 1.0
const GI_BLOCK := 2.0
const SKIP := 0.3
const NEAR := 30.0
const PLACES := {"S": [Vector3(-66.3, 3.0, 12.6), Vector3(-66.3, 3.0, -8.0), 55.0],
	"A": [Vector3(-58.0, 1.7, 30.0), Vector3(-54.0, 0.2, 22.0), 55.0],
	"R": [Vector3(-26.0, 1.6, 70.5), Vector3(-12.0, 0.0, 66.0), 55.0]}
const OPTIONS: Array[String] = ["SH", "AO", "IL", "GI", "LT"]

var _app: Node3D
var _environment: Environment
var _camera: Camera3D
var _lights: Array[Light3D] = []
var _kept := {}
var _out := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	root.add_child(_app)
	await process_frame
	_app.call("_resume")
	var world: Node3D = _app.get_node("IndustrialLoop")
	_environment = (world.find_children("*", "WorldEnvironment", true, false)[0]
		as WorldEnvironment).environment
	for found in world.find_children("*", "Light3D", true, false):
		if not found is DirectionalLight3D:
			var light := found as Light3D
			_lights.append(light)
			_kept[light] = [light.shadow_enabled, light.distance_fade_enabled,
				light.distance_fade_begin, light.distance_fade_length, light.distance_fade_shadow]
	_camera = Camera3D.new()
	_camera.name = "GpuPriceLighting"
	_camera.far = 400.0
	_camera.cull_mask = (_app.get("title_camera") as Camera3D).cull_mask
	root.add_child(_camera)
	await _wait(SETTLE)
	print("GPU PRICE: window %s, vsync %s, MetalFX scale %.2f, %d lights" % [
		root.get_visible_rect().size, DisplayServer.window_get_vsync_mode(),
		root.scaling_3d_scale, _lights.size()])
	for place: String in PLACES:
		_look(place)
		await _wait(1.0)
		for option in OPTIONS:
			await _alternate(place, option)
		await _stills(place)
	print("GPU PRICE DONE")
	quit()


func _look(place: String) -> void:
	var view: Array = PLACES[place]
	_camera.fov = view[2]
	_camera.look_at_from_position(view[0], view[1], Vector3.UP)
	_camera.make_current()


func _alternate(place: String, option: String) -> void:
	var block := GI_BLOCK if option == "GI" else BLOCK
	for cycle in range(CYCLES):
		for shown: bool in [true, false]:
			DisplayServer.window_move_to_foreground()
			_apply(option, shown)
			var began := Time.get_unix_time_from_system()
			await _wait(block)
			var ended := Time.get_unix_time_from_system()
			print("GPU PRICE BLOCK|%s|%s|cycle %d|time %.3f-%.3f|skip %.2f|particles %d|%s|%s"
				% [place + option, "on" if shown else "off", cycle + 1, began, ended,
				SKIP if option != "GI" else 1.0, 0, place, "lights %d" % _lights.size()])
	_apply(option, false)


func _stills(place: String) -> void:
	for option: String in ["none"] + OPTIONS:
		if option != "none":
			_apply(option, true)
		await _wait(2.5 if option == "GI" else 0.6)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(_out.path_join("%s_%s.png" % [place, option]))
		if option != "none":
			_apply(option, false)


func _apply(option: String, on: bool) -> void:
	match option:
		"SH":
			_shadows(on)
		"AO":
			_environment.ssao_enabled = on
		"IL":
			_environment.ssil_enabled = on
		"GI":
			_environment.sdfgi_enabled = on
		"LT":
			_shadows(on)
			_environment.ssao_enabled = on
			_environment.ssil_enabled = on


## Shadows from every light, faded out beyond NEAR of the camera; the light itself fades as it did
## (the street lamps from 65 m), or never. Off, each light is as the game made it.
func _shadows(on: bool) -> void:
	for light in _lights:
		var was: Array = _kept[light]
		if on:
			light.shadow_enabled = true
			light.distance_fade_enabled = true
			light.distance_fade_begin = was[2] if was[1] else 1000.0
			light.distance_fade_length = was[3] if was[1] else 10.0
			light.distance_fade_shadow = NEAR
		else:
			light.shadow_enabled = was[0]
			light.distance_fade_enabled = was[1]
			light.distance_fade_begin = was[2]
			light.distance_fade_length = was[3]
			light.distance_fade_shadow = was[4]


func _wait(seconds: float) -> void:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < seconds * 1000.0:
		await process_frame
