extends SceneTree
## #275: fixes 2 to 5 toward the author's photos of a rainy night, tried on the running game
## before any is written into it, each added on top of the ones before it, at three places
## (R the valley road under the town lamp, A the dock apron, D the freight depot's yard):
## RF reflections: every lamp's specular at the physical 1.0 (Godot's default is 0.5) and a
##   reflection probe over each place, so lights reflect even when they are off screen;
## GL glow: Godot's glow over an HDR threshold of 1.0, so only light sources bloom;
## DK darker: the fog's light colour and the ambient light turned down, so the dark is dark;
## HZ haze: each lamp cone's scattering raised four times, toward heavy rain's.
## Each step's GPU time is logged in alternating blocks for tools/tests/gpu_price.py
## (MTL_HUD_ENABLED=1 MTL_HUD_LOG_ENABLED=1); then a still of each place after each step. It
## changes no game file. Run windowed:
##   MTL_HUD_ENABLED=1 MTL_HUD_LOG_ENABLED=1 HOME="$PWD/.scratch-home" Godot --path game \
##     --resolution 1280x800 --script ../tools/captures/trial_night_look.gd -- <stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const SETTLE := 4.0
const CYCLES := 12
const BLOCK := 1.0
const SKIP := 0.3
const PLACES := {"R": [Vector3(-26.0, 1.6, 70.5), Vector3(-12.0, 0.0, 66.0), 55.0,
		AABB(Vector3(-60.0, -1.0, 52.0), Vector3(80.0, 14.0, 26.0))],
	"A": [Vector3(-58.0, 1.7, 30.0), Vector3(-54.0, 0.2, 22.0), 55.0,
		AABB(Vector3(-90.0, -1.0, 19.0), Vector3(52.0, 12.0, 18.0))],
	"D": [Vector3(-24.0, 1.7, 92.0), Vector3(-30.0, 0.0, 104.0), 60.0,
		AABB(Vector3(-62.0, -1.0, 72.0), Vector3(68.0, 14.0, 58.0))]}
const STEPS: Array[String] = ["RF", "GL", "DK", "HZ"]
const DARK_FOG := Color("0a0e12")
const DARK_AMBIENT := 0.03
const HAZE := 4.0
## `lamp_mist.gdshader`'s own scattering, for a lamp that leaves it as it is.
const MIST_SCATTERING := 0.004

var _app: Node3D
var _environment: Environment
var _camera: Camera3D
var _lights: Array[Light3D] = []
var _probes: Array[ReflectionProbe] = []
var _mists: Array[ShaderMaterial] = []
var _kept := {}
var _out := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("trial_night_look_progress.cfg")
	var file := FileAccess.open(progress, FileAccess.WRITE)
	file.store_string(SAVE)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = progress
	root.add_child(_app)
	await process_frame
	await process_frame
	_app.call("_begin")
	var world: Node3D = _app.get_node("IndustrialLoop")
	_environment = (world.find_children("*", "WorldEnvironment", true, false)[0]
		as WorldEnvironment).environment
	_kept["fog"] = _environment.fog_light_color
	_kept["ambient"] = _environment.ambient_light_energy
	for found in world.find_children("*", "Light3D", true, false):
		if not found is DirectionalLight3D:
			_lights.append(found as Light3D)
			_kept[found] = (found as Light3D).light_specular
	for found in world.find_children("Mist", "MeshInstance3D", true, false):
		var air := (found as MeshInstance3D).material_override as ShaderMaterial
		if air == null:
			air = (found as MeshInstance3D).get_active_material(0) as ShaderMaterial
		if air != null and not _mists.has(air):
			_mists.append(air)
			var scattering: Variant = air.get_shader_parameter("scattering")
			_kept[air] = float(scattering) if scattering != null else MIST_SCATTERING
	for place: String in PLACES:
		var box: AABB = PLACES[place][3]
		var probe := ReflectionProbe.new()
		probe.name = "TrialProbe" + place
		probe.size = box.size
		probe.box_projection = true
		probe.update_mode = ReflectionProbe.UPDATE_ONCE
		probe.visible = false
		world.add_child(probe)
		probe.global_position = box.get_center()
		_probes.append(probe)
	_camera = Camera3D.new()
	_camera.far = 400.0
	_camera.cull_mask = (_app.get("title_camera") as Camera3D).cull_mask
	root.add_child(_camera)
	await _wait(SETTLE)
	print("GPU PRICE: window %s, vsync %s, MetalFX scale %.2f, %d lights, %d mists" % [
		root.get_visible_rect().size, DisplayServer.window_get_vsync_mode(),
		root.scaling_3d_scale, _lights.size(), _mists.size()])
	for place: String in PLACES:
		var view: Array = PLACES[place]
		_camera.fov = view[2]
		_camera.look_at_from_position(view[0], view[1], Vector3.UP)
		_camera.make_current()
		for step in STEPS:
			_apply(step, false)
		await _wait(1.5)
		await _still(place, "0_now")
		for index in STEPS.size():
			var step := STEPS[index]
			for cycle in range(CYCLES):
				for shown: bool in [true, false]:
					DisplayServer.window_move_to_foreground()
					_apply(step, shown)
					var began := Time.get_unix_time_from_system()
					await _wait(BLOCK)
					var ended := Time.get_unix_time_from_system()
					print("GPU PRICE BLOCK|%s|%s|cycle %d|time %.3f-%.3f|skip %.2f|particles 0|%s|-"
						% [place + step, "on" if shown else "off", cycle + 1, began, ended, SKIP,
						place])
			_apply(step, true)
			await _wait(1.0)
			await _still(place, "%d_%s" % [index + 1, step])
	print("GPU PRICE DONE")
	quit()


func _apply(step: String, on: bool) -> void:
	match step:
		"RF":
			for light in _lights:
				light.light_specular = 1.0 if on else float(_kept[light])
			for probe in _probes:
				probe.visible = on
		"GL":
			_environment.glow_enabled = on
			_environment.glow_hdr_threshold = 1.0
			_environment.glow_intensity = 0.9
			_environment.glow_bloom = 0.0
			_environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
		"DK":
			_environment.fog_light_color = DARK_FOG if on else _kept["fog"]
			_environment.ambient_light_energy = DARK_AMBIENT if on else float(_kept["ambient"])
		"HZ":
			for air in _mists:
				air.set_shader_parameter("scattering", float(_kept[air]) * (HAZE if on else 1.0))


func _still(place: String, label: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join("%s_%s.png" % [place, label]))


func _wait(seconds: float) -> void:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < seconds * 1000.0:
		await process_frame
