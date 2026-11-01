extends SceneTree

const Check = preload("res://tests/normal_map_check.gd")
const FOG_SHADER := "res://shaders/foggy_windshield.gdshader"
const HINT_SHADER := "res://shaders/hint_experiment.gdshader"
const WINDSHIELD_SHADER := "res://features/vehicles/freight_van/windshield.gdshader"
const SIDE_RAIN_SHADER := "res://features/vehicles/freight_van/side_window_rain.gdshader"
const RAIN_INCLUDE := "#include \"rain_drops.gdshaderinc\""
const RAIN_UNIFORMS := {"rain": TYPE_FLOAT, "wetness": TYPE_FLOAT, "speed": TYPE_FLOAT,
	"drop_radii": TYPE_VECTOR4, "runner_speed": TYPE_FLOAT}
const HINT_PNG := "res://experiments/hint_experiment/greys_3x1.png"
const FOG_TEXTURES := {
	"fog_color": "res://assets/textures/windshield/fog_color.png",
	"fog_normal": "res://assets/textures/windshield/fog_normal.png",
	"fog_data": "res://assets/textures/windshield/fog_data.png",
}
const FOG_MATERIALS := {
	"res://materials/windshield/light_fog.tres": [0.25, 0.45, 0.65, 0.2, 0.5, 1.0],
	"res://materials/windshield/heavy_fog.tres": [0.75, 0.35, 0.35, 0.25, 0.5, 1.0],
}
const FOG_VALUE_NAMES: Array[String] = ["fog_amount", "fog_opacity", "clear_center",
	"edge_softness", "normal_strength", "texture_scale"]
const FOG_TINT := Color(0.82, 0.87, 0.9, 1.0)
const HINT_MATERIALS := {
	"res://experiments/hint_experiment/hint_as_color.tres": false,
	"res://experiments/hint_experiment/hint_as_data.tres": true,
}
const SAMPLER_HINTS := {
	FOG_SHADER: {
		"fog_color": "source_color, filter_linear, repeat_enable",
		"fog_normal": "hint_normal, filter_linear, repeat_enable",
		"fog_data": "filter_linear, repeat_enable",
	},
	HINT_SHADER: {
		"color_read": "source_color, filter_nearest",
		"data_read": "filter_nearest",
	},
}
const FOG_DECLARATIONS: Array[String] = [
	"uniform float fog_amount : hint_range(0.0, 1.0) = 0.25;",
	"uniform float fog_opacity : hint_range(0.0, 1.0) = 0.45;",
	"uniform vec4 fog_tint : source_color = vec4(0.82, 0.87, 0.90, 1.0);",
	"uniform float clear_center : hint_range(0.0, 0.9) = 0.65;",
	"uniform float edge_softness : hint_range(0.01, 0.5) = 0.20;",
	"uniform float normal_strength : hint_range(0.0, 2.0) = 0.5;",
	"uniform float texture_scale : hint_range(0.5, 4.0) = 1.0;",
]
const FOG_UNIFORMS := {
	"fog_amount": TYPE_FLOAT, "fog_opacity": TYPE_FLOAT, "fog_tint": TYPE_COLOR,
	"clear_center": TYPE_FLOAT, "edge_softness": TYPE_FLOAT, "normal_strength": TYPE_FLOAT,
	"texture_scale": TYPE_FLOAT, "fog_color": TYPE_OBJECT, "fog_normal": TYPE_OBJECT,
	"fog_data": TYPE_OBJECT,
}
const FOG_GROUPS: Array[String] = ["Fog", "Shape", "Detail"]
const HINT_UNIFORMS := {"color_read": TYPE_OBJECT, "data_read": TYPE_OBJECT, "show_data": TYPE_BOOL}
const IMPORTS := {
	"res://assets/textures/windshield/fog_color.png": [0, 2, true],
	"res://assets/textures/windshield/fog_normal.png": [0, 1, true],
	"res://assets/textures/windshield/fog_data.png": [0, 2, true],
	HINT_PNG: [0, 2, false],
}
const CALIBRATION_GL := "res://tests/calibration/box_profile_metal_sheet_nor_gl_1k.png"
const CALIBRATION_DX := "res://tests/calibration/box_profile_metal_sheet_nor_dx_1k.png"
const GL_THRESHOLD := 0.5792

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(120.0, true, false, true).timeout.connect(_timeout)
	_check_sampler_hints()
	_check_uniform_lists()
	_check_rain_shaders()
	_check_fog_materials()
	_check_hint_materials()
	_check_imports()
	_check_normal_maps()
	await _check_van_overlays()
	_check_hint_scene()
	print("MATERIALS RESULT: %d/%d passed; %d failed" % [
		_checks - _failures, _checks, _failures])
	quit(0 if _failures == 0 else 1)


func _check_sampler_hints() -> void:
	for shader_path: String in SAMPLER_HINTS:
		var source := FileAccess.get_file_as_string(shader_path)
		var expected: Dictionary = SAMPLER_HINTS[shader_path]
		for sampler: String in expected:
			var pattern := RegEx.create_from_string(
				"uniform\\s+sampler2D\\s+%s\\s*:\\s*([^;]+);" % sampler)
			var found := pattern.search(source)
			var hints := found.get_string(1).strip_edges() if found else "<missing>"
			_check(hints == expected[sampler], "%s sampler %s hints are '%s' (found '%s')" % [
				shader_path.get_file(), sampler, expected[sampler], hints])
	var fog_source := FileAccess.get_file_as_string(FOG_SHADER)
	_check(fog_source.begins_with("shader_type spatial;"), "Fog shader line 1 is shader_type spatial")
	_check(fog_source.contains("render_mode blend_mix, depth_draw_never, cull_disabled;"),
		"Fog shader render_mode matches CHANGE-BRIEF 5.4")
	_check(not fog_source.contains("hint_screen_texture"), "Fog shader reads no screen texture")
	for declaration in FOG_DECLARATIONS:
		_check(fog_source.contains(declaration), "Fog source declares: " + declaration)


func _check_uniform_lists() -> void:
	_check_listed(FOG_SHADER, FOG_UNIFORMS)
	_check_listed(HINT_SHADER, HINT_UNIFORMS)
	var groups: Array[String] = []
	for item in (load(FOG_SHADER) as Shader).get_shader_uniform_list(true):
		if item.usage == PROPERTY_USAGE_GROUP and item.name != "":
			groups.append(item.name)
	_check(groups == FOG_GROUPS, "Fog uniform groups are %s (found %s)" % [FOG_GROUPS, groups])


func _check_rain_shaders() -> void:
	for shader_path: String in [WINDSHIELD_SHADER, SIDE_RAIN_SHADER]:
		_check_listed(shader_path, RAIN_UNIFORMS)
		_check(FileAccess.get_file_as_string(shader_path).contains(RAIN_INCLUDE),
			"%s uses the shared drop code: %s" % [shader_path.get_file(), RAIN_INCLUDE])


func _check_listed(shader_path: String, expected: Dictionary) -> void:
	var listed := {}
	for item in (load(shader_path) as Shader).get_shader_uniform_list():
		listed[item.name] = item.type
	_check(not listed.is_empty(), "%s parses: uniform list is not empty" % shader_path.get_file())
	for uniform_name: String in expected:
		_check(listed.get(uniform_name, -1) == expected[uniform_name],
			"%s lists %s as %s" % [shader_path.get_file(), uniform_name,
			type_string(expected[uniform_name])])


func _check_fog_materials() -> void:
	for material_path: String in FOG_MATERIALS:
		var material := load(material_path) as ShaderMaterial
		var label := material_path.get_file()
		_check(material.shader.resource_path == FOG_SHADER, "%s uses %s" % [label, FOG_SHADER])
		var values: Array = FOG_MATERIALS[material_path]
		for index in range(FOG_VALUE_NAMES.size()):
			var uniform_name := FOG_VALUE_NAMES[index]
			var value: float = material.get_shader_parameter(uniform_name)
			_check(is_equal_approx(value, values[index]),
				"%s %s = %s" % [label, uniform_name, str(values[index])])
		var tint: Color = material.get_shader_parameter("fog_tint")
		_check(tint.is_equal_approx(FOG_TINT), "%s fog_tint = %s" % [label, str(FOG_TINT)])
		for sampler: String in FOG_TEXTURES:
			var texture: Texture2D = material.get_shader_parameter(sampler)
			_check(texture != null and texture.resource_path == FOG_TEXTURES[sampler],
				"%s binds %s to %s" % [label, FOG_TEXTURES[sampler].get_file(), sampler])


func _check_hint_materials() -> void:
	for material_path: String in HINT_MATERIALS:
		var material := load(material_path) as ShaderMaterial
		var label := material_path.get_file()
		_check(material.shader.resource_path == HINT_SHADER, "%s uses %s" % [label, HINT_SHADER])
		_check(material.get_shader_parameter("show_data") == HINT_MATERIALS[material_path],
			"%s show_data = %s" % [label, str(HINT_MATERIALS[material_path])])
		for sampler in ["color_read", "data_read"]:
			var texture: Texture2D = material.get_shader_parameter(sampler)
			_check(texture != null and texture.resource_path == HINT_PNG,
				"%s binds greys_3x1.png to %s" % [label, sampler])


func _check_imports() -> void:
	for texture_path: String in IMPORTS:
		var config := ConfigFile.new()
		var error := config.load(texture_path + ".import")
		var expected: Array = IMPORTS[texture_path]
		var mode: int = config.get_value("params", "compress/mode", -1)
		var normal_map: int = config.get_value("params", "compress/normal_map", -1)
		var mipmaps: bool = config.get_value("params", "mipmaps/generate", not expected[2])
		var detect: int = config.get_value("params", "detect_3d/compress_to", -1)
		_check(error == OK and mode == expected[0] and normal_map == expected[1]
			and mipmaps == expected[2] and detect == 0,
			"%s import: compress/mode=%d normal_map=%d mipmaps=%s detect_3d=%d" % [
			texture_path.get_file(), mode, normal_map, str(mipmaps), detect])


func _check_normal_maps() -> void:
	var gl := Image.load_from_file(CALIBRATION_GL)
	var dx := Image.load_from_file(CALIBRATION_DX)
	var gl_as_gl := Check.curl_ratio(gl, false)
	var gl_as_dx := Check.curl_ratio(gl, true)
	var dx_as_gl := Check.curl_ratio(dx, false)
	var dx_as_dx := Check.curl_ratio(dx, true)
	print("CURL calibration GL file: as GL %.4f, as DX %.4f" % [gl_as_gl, gl_as_dx])
	print("CURL calibration DX file: as GL %.4f, as DX %.4f" % [dx_as_gl, dx_as_dx])
	_check(gl_as_gl < gl_as_dx and dx_as_dx < dx_as_gl,
		"Calibration pair: each file is lower in its own convention (sign convention correct)")
	var fog := Image.load_from_file(FOG_TEXTURES["fog_normal"])
	var fog_as_gl := Check.curl_ratio(fog, false)
	var fog_as_dx := Check.curl_ratio(fog, true)
	print("CURL fog_normal.png: as GL %.4f, as DX %.4f" % [fog_as_gl, fog_as_dx])
	_check(fog_as_gl <= GL_THRESHOLD and fog_as_gl < fog_as_dx,
		"fog_normal.png is a real surface in the GL convention (<= %.4f)" % GL_THRESHOLD)


func _check_van_overlays() -> void:
	var app := (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	app.get_node("DrivingTrial").checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-materials-%d.cfg" % OS.get_process_id())
	root.add_child(app)
	await process_frame
	app.call("_resume")
	var presentation := app.get_node("FreightVan/VanPresentation")
	var overlays: Array = presentation.get("fog_overlays")
	var rain: Array = presentation.get("side_rain_overlays")
	var windows: Array = presentation.get("_windows")
	_check(overlays.size() == 1 and rain.size() == 2,
		"Van builds the windshield fog overlay and two side-window rain overlays")
	var windshield: MeshInstance3D = overlays[0]
	var side: MeshInstance3D = rain[0]
	_check(windshield.material_override.resource_path.ends_with("light_fog.tres"),
		"Windshield overlay uses light_fog.tres")
	_check((side.material_override as ShaderMaterial).shader.resource_path.ends_with(
		"side_window_rain.gdshader"),
		"Driver-window overlay uses side_window_rain.gdshader (fog removed by the author)")
	var pane := windshield.get_parent() as MeshInstance3D
	_check(pane.material_override is ShaderMaterial
		and (pane.material_override as ShaderMaterial).shader.resource_path.ends_with(
		"windshield.gdshader"), "Original windshield glass keeps windshield.gdshader")
	_check(side.get_parent() == windows[0] and windows[0].material_override
		is StandardMaterial3D,
		"Driver-window rain overlay is a child of the left window; its glass is unchanged")
	_check(side.position.x < 0.0 and side.sorting_offset < 0.0,
		"Driver-window rain sits on the outside of the glass and draws before it")
	_check(windshield.layers == 4 and side.layers == 4, "Both overlays are on the cabin layer")
	var van := app.get_node("FreightVan") as Node3D
	var glass := pane.material_override as ShaderMaterial
	van.set("actual_speed", 0.0)
	presentation.call("update_vehicle", 0.0)
	var up_before := float(glass.get_shader_parameter("runner_up"))
	var down_before := float(glass.get_shader_parameter("runner_down"))
	van.set("actual_speed", 18.0)
	presentation.call("update_vehicle", 0.5)
	var climbed := float(glass.get_shader_parameter("runner_up")) - up_before
	van.set("actual_speed", 0.0)
	presentation.call("update_vehicle", 0.5)
	var slid := float(glass.get_shader_parameter("runner_down")) - down_before
	_check(climbed > 0.0 and slid > 0.0,
		"Windshield runners climb at 65 km/h (%.3f m) and slide down when parked (%.3f m)" % [
		climbed, slid])
	var start_y: float = presentation.to_local(side.global_position).y
	var press := InputEventAction.new()
	press.action = "window_left"
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var release := InputEventAction.new()
	release.action = "window_left"
	Input.parse_input_event(release)
	for frame in range(180):
		await process_frame
	var moved: float = start_y - presentation.to_local(side.global_position).y
	_check(absf(moved - 0.88) < 0.02,
		"Real J press lowers the window and its fog overlay by %.3f m (expected 0.88)" % moved)
	app.queue_free()
	await process_frame


func _check_hint_scene() -> void:
	var scene := (load("res://experiments/hint_experiment/hint_experiment.tscn") as PackedScene
		).instantiate()
	var as_color: MeshInstance3D = scene.get_node("AsColor")
	var as_data: MeshInstance3D = scene.get_node("AsData")
	_check(as_color.get_surface_override_material(0).resource_path.ends_with("hint_as_color.tres")
		and as_data.get_surface_override_material(0).resource_path.ends_with("hint_as_data.tres"),
		"Hint quads use hint_as_color.tres and hint_as_data.tres")
	var environment: Environment = (scene.get_node("WorldEnvironment") as WorldEnvironment
		).environment
	_check(environment.tonemap_mode == Environment.TONE_MAPPER_LINEAR
		and is_equal_approx(environment.tonemap_exposure, 1.0) and not environment.glow_enabled
		and not environment.fog_enabled and not environment.adjustment_enabled,
		"Hint scene: Linear tonemap, exposure 1.0, glow/fog/adjustments off")
	scene.free()


func _timeout() -> void:
	_check(false, "Materials test finished within 120 s of game time")
	quit(1)
