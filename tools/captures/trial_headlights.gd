extends SceneTree
## #281: realistic headlights, tried on the running game before any of it is written in. The
## options, set on the van's own two headlights:
## 1 now;
## A the measured beam: the low beam's pattern made from UMTRI-2004-23's measured medians (the
##   best-selling US cars' low beams, Schoettle, Sivak, Flannagan and Kosmatka, 2004), the lamp
##   aimed for the van's lamps, 1.15 m up where the study's were 0.66 m: 0.75 degrees down,
##   so the brightest light lands as far ahead as theirs (about 38 m);
## D the ECE beam: #280's trial pattern, the spread of ECE R112's class B low beam;
## B A with haze in the rain: the street lamps' own mist (lamp_mist.gdshader, single scattering
##   along each view ray) on each headlight, its cone replaced by the beam's pattern
##   (game/experiments/headlights/beam_mist_trial.gdshader). "Spatial Light Shaft"
##   (absentSpaghetti, CC0), tried first on a cone along each beam, did not show from the
##   driver's seat, behind the cone's tip, as it is drawn for a shaft seen from the side;
## C A with a lit headlamp lens (game/experiments/headlights/lens_trial.gdshader) on the van's
##   headlamps in place of their flat glow.
## Stills from three views each: T the weathered SPEED LIMIT 45 and the trunks behind it, D the
## driver's seat there, O the van's front from 7 m ahead and to the side, L one headlamp
## from 1.7 m. With "price", B's haze
## and C's lens are each shown and hidden in alternating blocks in the D view for
## tools/tests/gpu_price.py (MTL_HUD_ENABLED=1 MTL_HUD_LOG_ENABLED=1). It changes no game file.
## Run windowed, from the repository root:
##   HOME="$PWD/.scratch-home" Godot --path game --resolution 1280x800 \
##     --script ../tools/captures/trial_headlights.gd -- <stills folder> <measured.png> \
##     <ece.png> [price]

const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const MIST = preload("res://experiments/headlights/beam_mist_trial.gdshader")
const LENS = preload("res://experiments/headlights/lens_trial.gdshader")
const BACK := 10
const VIEW_BACK := 3
const LANE := 1.1
const EYE := 1.6
const MEASURED_TILT := -0.75
const LENS_FRONT := 0.12
const MIST_DEPTH := 40.0
const MIST_SCATTERING := 0.016
const CYCLES := 10
const BLOCK := 1.0
const SKIP := 0.3

var _out := ""
var _camera: Camera3D
var _van: Node3D
var _world: Node3D
var _lights: Array[SpotLight3D] = []
var _lenses: Array = []
var _haze: Array[MeshInstance3D] = []
var _lens_material: ShaderMaterial


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0]
	var measured := ImageTexture.create_from_image(Image.load_from_file(args[1]))
	var ece := ImageTexture.create_from_image(Image.load_from_file(args[2]))
	var price := args.size() > 3 and args[3] == "price"
	var progress := OS.get_user_data_dir().path_join("trial_headlights.cfg")
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
	_world = app.get_node("IndustrialLoop") as Node3D
	_van = app.get_node("FreightVan") as Node3D
	for node in _van.find_children("*", "SpotLight3D", true, false):
		var light := node as SpotLight3D
		if light.light_energy > 100.0:
			_lights.append(light)
	for node in _van.find_children("*", "Node3D", true, false):
		var script: Script = node.get_script()
		if script and script.resource_path.ends_with("van_presentation.gd"):
			_lenses = node.get("_front_lenses")
	_make_lens()
	_make_haze()
	var now := _lights[0].light_projector
	var now_tilt := _lights[0].rotation_degrees.x
	_camera = Camera3D.new()
	_camera.fov = 60.0
	root.add_child(_camera)
	print("TRIAL headlights %d, lenses %d, tilt %.1f" % [_lights.size(), _lenses.size(), now_tilt])
	await create_timer(2.0, true, false, true).timeout
	if price:
		await _price(measured)
		quit(0)
		return
	var options := [["1", now, now_tilt, false, false], ["A", measured, MEASURED_TILT, false, false],
		["D", ece, now_tilt, false, false], ["B", measured, MEASURED_TILT, true, false],
		["C", measured, MEASURED_TILT, false, true]]
	for option: Array in options:
		_apply(option[1], option[2], option[3], option[4])
		for view in ["T", "D", "O", "L"]:
			await _view(view, String(option[0]))
	quit(0)


func _apply(pattern: Texture2D, tilt: float, haze: bool, lens: bool) -> void:
	for light in _lights:
		light.light_projector = pattern
		light.rotation_degrees.x = tilt
	for mist in _haze:
		mist.visible = haze
		(mist.material_override as ShaderMaterial).set_shader_parameter("pattern", pattern)
	for mesh: MeshInstance3D in _lenses:
		mesh.material_overlay = _lens_material if lens else null


func _make_lens() -> void:
	_lens_material = ShaderMaterial.new()
	_lens_material.shader = LENS
	if _lenses.is_empty():
		return
	var mesh: MeshInstance3D = _lenses[0]
	var sums := [Vector3.ZERO, Vector3.ZERO]
	var counts := [0, 0]
	var front := INF
	var points: PackedVector3Array = mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	for point in points:
		front = minf(front, point.z)
	for point in points:
		if point.z < front + LENS_FRONT:
			var side := 0 if point.x > 0.0 else 1
			sums[side] += point
			counts[side] += 1
	var a: Vector3 = sums[0] / float(maxi(counts[0], 1))
	var b: Vector3 = sums[1] / float(maxi(counts[1], 1))
	_lens_material.set_shader_parameter("lamp_a", a)
	_lens_material.set_shader_parameter("lamp_b", b)
	print("TRIAL lens mesh %s aabb %s, lamps in its space %s %s" % [mesh.name,
		mesh.get_aabb(), a, b])


func _make_haze() -> void:
	for light in _lights:
		var colour := light.light_color.srgb_to_linear() * light.light_energy
		var radius := MIST_DEPTH * tan(deg_to_rad(light.spot_angle))
		var air := ShaderMaterial.new()
		air.shader = MIST
		air.set_shader_parameter("light_colour", Vector3(colour.r, colour.g, colour.b))
		air.set_shader_parameter("half_size", Vector3(radius, radius, MIST_DEPTH * 0.5))
		air.set_shader_parameter("tan_half", tan(deg_to_rad(light.spot_angle)))
		air.set_shader_parameter("light_range", light.spot_range)
		air.set_shader_parameter("light_decay", light.spot_attenuation)
		air.set_shader_parameter("scattering", MIST_SCATTERING)
		air.set_shader_parameter("fade_begin", 1.0e6)
		var box := BoxMesh.new()
		box.size = Vector3(radius * 2.0, radius * 2.0, MIST_DEPTH)
		var mist := MeshInstance3D.new()
		mist.mesh = box
		mist.material_override = air
		mist.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mist.position = Vector3(0.0, 0.0, -MIST_DEPTH * 0.5)
		mist.visible = false
		light.add_child(mist)
		_haze.append(mist)


func _place(view: String) -> Vector3:
	var dressing: Node3D = _world.get("dressing")
	var road: RefCounted = _world.get("road")
	var index := 0
	var at := Vector3.ZERO
	for sign: Dictionary in dressing.get("signs"):
		if String(sign["kind"]) == "limit_45_weathered":
			index = int(sign["index"])
			at = sign["at"]
	var points: PackedVector3Array = road.points
	var from := posmod(index - BACK, points.size())
	var ahead := points[(from + 1) % points.size()] - points[from]
	var forward := Vector3(ahead.x, 0.0, ahead.z).normalized()
	var right := forward.cross(Vector3.UP)
	_van.call("recover", Transform3D(Basis.looking_at(forward, Vector3.UP),
		points[from] + right * LANE))
	await create_timer(0.6, true, false, true).timeout
	if view == "D":
		var eye := _van.global_transform * Vector3(-0.45, 2.05, -0.9)
		_camera.look_at_from_position(eye, eye + forward * 20.0 + Vector3.DOWN * 1.6)
	elif view == "L":
		var lamp := _lights[0].global_position
		var outward := signf((lamp - _van.global_position).dot(right))
		var eye := lamp + forward * 1.6 + right * outward * 0.7 + Vector3.UP * 0.2
		_camera.fov = 40.0
		_camera.look_at_from_position(eye, lamp)
	elif view == "O":
		var front := _van.global_position + forward * 7.0 + right * 2.5 + Vector3.UP * 1.3
		_camera.look_at_from_position(front, _van.global_position + Vector3.UP * 1.1
			+ forward * 1.5)
	else:
		var near := posmod(index - VIEW_BACK, points.size())
		var toward := signf((at - points[near]).dot(right))
		_camera.look_at_from_position(points[near] + right * toward * LANE + Vector3.UP * EYE,
			at + Vector3.UP * 0.8)
	_camera.make_current()
	return forward


func _view(view: String, option: String) -> void:
	_camera.fov = 60.0
	await _place(view)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join("%s_%s.png" % [option, view]))
	print("TRIAL saved %s_%s" % [option, view])


func _price(measured: Texture2D) -> void:
	print("GPU PRICE: window %s, vsync %s, MetalFX scale %.2f, headlights %d" % [
		root.get_visible_rect().size, DisplayServer.window_get_vsync_mode(),
		root.scaling_3d_scale, _lights.size()])
	await _place("D")
	for step in ["HHZ", "HLN"]:
		for cycle in range(CYCLES):
			for shown in [true, false]:
				_apply(measured, MEASURED_TILT, shown and step == "HHZ", shown and step == "HLN")
				var began := Time.get_unix_time_from_system()
				await create_timer(BLOCK, true, false, true).timeout
				var ended := Time.get_unix_time_from_system()
				print("GPU PRICE BLOCK|%s|%s|cycle %d|time %.3f-%.3f|skip %.2f|particles 0|%s|-"
					% [step, "on" if shown else "off", cycle + 1, began, ended, SKIP, "driver"])
	print("GPU PRICE DONE")
