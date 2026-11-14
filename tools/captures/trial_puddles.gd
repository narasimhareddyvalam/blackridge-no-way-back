extends SceneTree
## #277: the puddles of the wet ground (`wet_ground.gdshader`) as the author chose them, shown
## step by step on the running game at R the town lamp, A the dock apron and D the freight
## depot's yard, from the wet ground as first built (still puddles, 0.02 rough, no reflections of
## their own): PD the puddles rippled (0.08 rough, D on the streaks' sheet); PV their reflections
## from Rain Puddles V3's ray march, combined with the wet ground ("Combine them"); PF the same
## reflections across the whole wet film, blurred by its roughness. Each step's
## GPU time is logged for tools/tests/gpu_price.py (MTL_HUD_ENABLED=1 MTL_HUD_LOG_ENABLED=1), then
## a still after each. It changes no game file. Run windowed:
##   MTL_HUD_ENABLED=1 MTL_HUD_LOG_ENABLED=1 HOME="$PWD/.scratch-home" Godot --path game \
##     --resolution 1280x800 --script ../tools/captures/trial_puddles.gd -- <stills folder>

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const SETTLE := 4.0
const CYCLES := 12
const BLOCK := 1.0
const SKIP := 0.3
const PLACES := {"R": [Vector3(-26.0, 1.6, 70.5), Vector3(-12.0, 0.0, 66.0), 55.0],
	"A": [Vector3(-58.0, 1.7, 30.0), Vector3(-54.0, 0.2, 22.0), 55.0],
	"D": [Vector3(-24.0, 1.7, 92.0), Vector3(-30.0, 0.0, 104.0), 60.0]}
const STEPS: Array[String] = ["PD", "PV", "PF"]

var _app: Node3D
var _camera: Camera3D
var _grounds: Array[ShaderMaterial] = []
var _out := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var progress := OS.get_user_data_dir().path_join("trial_puddles_progress.cfg")
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
	for found in world.find_children("*", "MeshInstance3D", true, false):
		var paint := (found as MeshInstance3D).get_active_material(0) as ShaderMaterial
		if paint != null and paint.shader != null \
				and paint.shader.resource_path.ends_with("wet_ground.gdshader") \
				and not _grounds.has(paint):
			_grounds.append(paint)
	_camera = Camera3D.new()
	_camera.far = 400.0
	_camera.cull_mask = (_app.get("title_camera") as Camera3D).cull_mask
	root.add_child(_camera)
	await _wait(SETTLE)
	print("GPU PRICE: window %s, vsync %s, MetalFX scale %.2f, %d wet grounds" % [
		root.get_visible_rect().size, DisplayServer.window_get_vsync_mode(),
		root.scaling_3d_scale, _grounds.size()])
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
	for ground in _grounds:
		match step:
			"PD":
				ground.set_shader_parameter("puddle_roughness", 0.08 if on else 0.02)
			"PV":
				ground.set_shader_parameter("puddle_reflections", on)
			"PF":
				ground.set_shader_parameter("film_reflections", on)


func _still(place: String, label: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join("%s_%s.png" % [place, label]))


func _wait(seconds: float) -> void:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < seconds * 1000.0:
		await process_frame
