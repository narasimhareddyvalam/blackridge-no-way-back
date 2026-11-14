extends SceneTree
## #276: the long reflections of the street lamps on the wet road in the author's street photo,
## tried on the running game before any of it is written in, each step added on top of the ones
## before it, at R the town lamp at (-15, 63.8) and V the valley road's row of town lamps:
## LA lamps like real ones: a cobra-head street light throws its light out along the road,
##   peaking 70-75 degrees from straight down, so each lamp's cone opens from 55 to 75 degrees and
##   reaches 25 m, not 15, and its specular is the physical 1.0 (Godot's default 0.5);
## FR the road's film roughened by the rain's ripples, 0.12 to 0.25, which stretches a highlight;
## PR the puddles rippled, 0.02 to 0.08.
## Each step's GPU time is logged in alternating blocks for tools/tests/gpu_price.py
## (MTL_HUD_ENABLED=1 MTL_HUD_LOG_ENABLED=1); then a still after each step. It changes no game
## file. Run windowed:
##   MTL_HUD_ENABLED=1 MTL_HUD_LOG_ENABLED=1 HOME="$PWD/.scratch-home" Godot --path game \
##     --resolution 1280x800 --script ../tools/captures/trial_streaks.gd -- <stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const STREET_LIGHT := Color("ffa040")
const POST_ENERGY := 90.0
const SETTLE := 4.0
const CYCLES := 12
const BLOCK := 1.0
const SKIP := 0.3
const PLACES := {"R": [Vector3(-26.0, 1.6, 70.5), Vector3(-12.0, 0.0, 66.0), 55.0],
	"V": [Vector3(30.0, 1.7, 62.0), Vector3(5.0, 0.0, 64.0), 60.0]}
const STEPS: Array[String] = ["LA", "FR", "PR"]
const CONE := 75.0
const REACH := 25.0
const FILM := 0.25
const POOL := 0.08

var _app: Node3D
var _camera: Camera3D
var _lamps: Array[SpotLight3D] = []
var _road: ShaderMaterial
var _kept := {}
var _out := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("trial_streaks_progress.cfg")
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
	for found in world.find_children("*", "SpotLight3D", true, false):
		var lamp := found as SpotLight3D
		if lamp.light_color.is_equal_approx(STREET_LIGHT) and is_equal_approx(lamp.light_energy,
				POST_ENERGY):
			_lamps.append(lamp)
			_kept[lamp] = [lamp.spot_angle, lamp.spot_range, lamp.light_specular]
	for found in world.find_children("*", "MeshInstance3D", true, false):
		var paint := (found as MeshInstance3D).get_active_material(0) as ShaderMaterial
		if paint != null and paint.shader != null \
				and paint.shader.resource_path.ends_with("wet_ground.gdshader") \
				and (found as MeshInstance3D).get_aabb().size.y > 10.0:
			_road = paint
	_kept["film"] = _road.get_shader_parameter("film_roughness") if _road else null
	_kept["pool"] = _road.get_shader_parameter("puddle_roughness") if _road else null
	_camera = Camera3D.new()
	_camera.far = 400.0
	_camera.cull_mask = (_app.get("title_camera") as Camera3D).cull_mask
	root.add_child(_camera)
	await _wait(SETTLE)
	print("GPU PRICE: window %s, vsync %s, MetalFX scale %.2f, %d street lamps, road %s" % [
		root.get_visible_rect().size, DisplayServer.window_get_vsync_mode(),
		root.scaling_3d_scale, _lamps.size(), _road != null])
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
		"LA":
			for lamp in _lamps:
				var was: Array = _kept[lamp]
				lamp.spot_angle = CONE if on else float(was[0])
				lamp.spot_range = REACH if on else float(was[1])
				lamp.light_specular = 1.0 if on else float(was[2])
		"FR":
			_road.set_shader_parameter("film_roughness", FILM if on else 0.12)
		"PR":
			_road.set_shader_parameter("puddle_roughness", POOL if on else 0.02)


func _still(place: String, label: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join("%s_%s.png" % [place, label]))


func _wait(seconds: float) -> void:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < seconds * 1000.0:
		await process_frame
