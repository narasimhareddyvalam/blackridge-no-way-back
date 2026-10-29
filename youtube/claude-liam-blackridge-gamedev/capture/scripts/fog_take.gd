extends "res://capture_drivers/game_take.gd"

## Common setup for the fog takes (C and D): park the wipers with two real "wipers" (V)
## action presses (wiper_setting starts at 1: low -> high -> off), wait until
## wiper_angle reaches its parked value -0.9, then pause the tree and set
## Engine.time_scale to 0. SceneTree.paused alone does not stop shader TIME
## (windshield.gdshader drop wobble and wet_asphalt.gdshader ripples keep moving);
## time_scale 0 stops it, so only the value being changed differs between frames.
## Also projects both fog overlays to screen polygons so the analysis can mask them.

const WIPER_PRESS_FRAMES: Array[int] = [150, 160]
const PARKED_ANGLE := -0.9

var light: ShaderMaterial
var heavy: ShaderMaterial
var shader: Shader
var world: WorldEnvironment
var camera: Camera3D
var freeze_frame: int = -1
var _parked_frames: int = 0
var heavy_snapshot: Dictionary = {}
var light_snapshot: Dictionary = {}

const FOG_PARAMS: Array[String] = ["fog_amount", "fog_opacity", "clear_center",
	"edge_softness", "normal_strength", "texture_scale", "fog_tint", "fog_color",
	"fog_normal", "fog_data"]


func _setup() -> void:
	var overlays: Array = presentation.get("fog_overlays")
	light = overlays[0].material_override
	heavy = overlays[1].material_override
	shader = light.shader
	world = app.find_children("*", "WorldEnvironment", true, false)[0]
	camera = van.call("get_camera")
	light_snapshot = params(light)
	heavy_snapshot = params(heavy)
	rig.log_event({"kind": "objects",
		"light_fog": {"resource_path": light.resource_path, "instance_id": light.get_instance_id(),
			"shader_instance_id": light.shader.get_instance_id(),
			"used_by": str(overlays[0].get_path())},
		"heavy_fog": {"resource_path": heavy.resource_path, "instance_id": heavy.get_instance_id(),
			"shader_instance_id": heavy.shader.get_instance_id(),
			"used_by": str(overlays[1].get_path())},
		"shader": {"resource_path": shader.resource_path, "instance_id": shader.get_instance_id()},
		"world_environment": str(world.get_path())})
	rig.check(light != heavy and light.get_instance_id() != heavy.get_instance_id(),
		"light_fog and heavy_fog are different ShaderMaterial objects (ids %d / %d)" % [
		light.get_instance_id(), heavy.get_instance_id()])
	rig.check(light.resource_path == "res://materials/windshield/light_fog.tres"
		and heavy.resource_path == "res://materials/windshield/heavy_fog.tres",
		"Windshield overlay uses light_fog.tres; driver-window overlay uses heavy_fog.tres")
	rig.check(light.shader == heavy.shader
		and shader.resource_path == "res://shaders/foggy_windshield.gdshader",
		"Both materials share one Shader object: %s (id %d)" % [shader.resource_path,
		shader.get_instance_id()])


func params(material: ShaderMaterial) -> Dictionary:
	var out := {}
	for key in FOG_PARAMS:
		var value: Variant = material.get_shader_parameter(key)
		out[key] = value.resource_path if value is Resource else value
	return out


func park_and_freeze(frame: int) -> bool:
	if freeze_frame >= 0:
		return true
	for at in WIPER_PRESS_FRAMES:
		if frame == at:
			rig.inject("wipers", true, "V: cycle wiper setting (starts at 1 = low)")
		elif frame == at + 1:
			rig.inject("wipers", false, "V release")
	if frame <= WIPER_PRESS_FRAMES[1] + 1:
		return false
	if van.get("wiper_setting") == 0 and van.get("wiper_angle") == PARKED_ANGLE:
		_parked_frames += 1
	if _parked_frames < 10 or not settled():
		return false
	rig.check(switch_frames.size() == 2 and van.get("wiper_setting") == 0,
		"Two real V presses (handled on frames %s) switched the wipers off" % str(switch_frames))
	rig.check(van.get("wiper_angle") == PARKED_ANGLE,
		"Wipers parked at angle %.2f (stationary for %d frames)" % [PARKED_ANGLE,
		_parked_frames])
	rig.log_event(settle_report())
	anchor_stationary()
	paused = true
	Engine.time_scale = 0.0
	freeze_frame = frame
	rig.log_event({"kind": "scripted", "what": "SceneTree.paused = true; Engine.time_scale = 0.0",
		"why": "freeze physics/process and shader TIME so only the edited value changes",
		"windshield_wetness": presentation.get("_water"),
		"wiper_angle": van.get("wiper_angle")})
	_log_masks()
	return false


func _log_masks() -> void:
	var overlays: Array = presentation.get("fog_overlays")
	var sizes: Array[Vector2] = [Vector2(2.12, 1.08), Vector2(1.48, 0.9)]
	var names: Array[String] = ["light_fog_windshield", "heavy_fog_driver_window"]
	var scale := Vector2(SIZE) / Vector2(rig.viewport.get_visible_rect().size)
	var polygons := {}
	for index in range(2):
		var node: Node3D = overlays[index]
		var half: Vector2 = sizes[index] * 0.5
		var corners: Array[Vector3] = [Vector3(-half.x, -half.y, 0), Vector3(half.x, -half.y, 0),
			Vector3(half.x, half.y, 0), Vector3(-half.x, half.y, 0)]
		var view_space: Array[Vector3] = []
		for corner in corners:
			view_space.append(camera.global_transform.affine_inverse() * node.to_global(corner))
		var clipped := _clip_near(view_space, -camera.near - 0.001)
		var points := []
		for point in clipped:
			var screen := camera.unproject_position(camera.global_transform * point) * scale
			points.append([snappedf(screen.x, 0.01), snappedf(screen.y, 0.01)])
		polygons[names[index]] = points
	rig.log_event({"kind": "overlay_screen_polygons", "pixel_space": [SIZE.x, SIZE.y],
		"polygons": polygons, "note": "overlay quads projected with the cockpit camera; "
		+ "clipped at the near plane; occluders not removed (masks are supersets)"})
	var file := FileAccess.open(capture_dir.path_join("logs/%s-overlay-masks.json" % _take_name()),
		FileAccess.WRITE)
	file.store_string(JSON.stringify({"pixel_space": [SIZE.x, SIZE.y], "polygons": polygons},
		"  ", true) + "\n")
	file.close()


func _clip_near(points: Array[Vector3], plane_z: float) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for index in range(points.size()):
		var a := points[index]
		var b := points[(index + 1) % points.size()]
		var a_in := a.z <= plane_z
		var b_in := b.z <= plane_z
		if a_in:
			out.append(a)
		if a_in != b_in:
			out.append(a.lerp(b, (plane_z - a.z) / (b.z - a.z)))
	return out


func check_heavy_unchanged(label: String) -> void:
	rig.check(params(heavy) == heavy_snapshot,
		"heavy_fog values unchanged %s: %s" % [label, str(params(heavy))])
