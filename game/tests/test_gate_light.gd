extends SceneTree
## The compound's gate lit at night as real gates are (the audit, #353, after Commons photos; the
## author's choices): a white LED flood pole by the gate, its heads the chosen ready-made LED
## floods (The Street Light Man's, CC BY), lighting the approach, the stop line, the booth's
## service window and the gate's leaf; solid and out of the van's way and the leaf's; rain showing
## in its light, raining when the camera is at the stop line; and rain in the light of each of the
## compound's yard floods.

const GATE := Vector3(200.0, 0.0, 146.0)
const LED_FLOOD := "res://features/environments/industrial_loop/art/gates/led_flood/led_flood.glb"
const NEAR_GATE := 9.0
const HEIGHT := Vector2(5.0, 10.0)
const APPROACH := Vector3(199.0, 0.02, 154.0)
const STOP_LINE := Vector3(200.0, 0.02, 148.5)
const LEAF := Vector3(200.0, 1.2, 145.75)
const DRIVEWAY := Rect2(194.5, 146.0, 8.5, 23.5)
const LEAF_RUN := Rect2(190.5, 145.4, 13.0, 1.6)

var _checks := 0
var _failures := 0
var _app: Node3D
var _scratch: String


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(120.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-gate-light-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	_app.call("_resume")
	await physics_frame
	var world := _app.get_node("IndustrialLoop")
	var compound := world.get("compound") as Node3D
	var rain := world.get("lamp_rain") as Node3D
	var lights := _gate_lights(compound)
	_lit(compound, lights)
	_heads(compound)
	_clear(compound)
	await _gate_rain(rain)
	_yard_rain(compound, rain)
	_finish()


func _box(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false) \
			+ ([node] if node is MeshInstance3D else []):
		var part := mesh.global_transform * mesh.get_aabb()
		box = part if first else box.merge(part)
		first = false
	return box


## The white spotlights within NEAR_GATE of the gate, HEIGHT up.
func _gate_lights(compound: Node3D) -> Array[SpotLight3D]:
	var found: Array[SpotLight3D] = []
	for light: SpotLight3D in compound.find_children("*", "SpotLight3D", true, false):
		var at := light.global_position
		var flat := Vector2(at.x - GATE.x, at.z - GATE.z).length()
		var white := light.light_color.r > 0.9 and light.light_color.b > 0.9
		if flat < NEAR_GATE and at.y >= HEIGHT.x and at.y <= HEIGHT.y and white:
			found.append(light)
	return found


func _reaches(light: SpotLight3D, point: Vector3) -> bool:
	var to := point - light.global_position
	return rad_to_deg((-light.global_basis.z).angle_to(to)) <= light.spot_angle \
		and to.length() <= light.spot_range


func _lit(compound: Node3D, lights: Array[SpotLight3D]) -> void:
	var booth := compound.get("booth") as Node3D
	var window := booth.find_child("ServiceWindow", true, false) as Node3D if booth else null
	var points := {"the approach": APPROACH, "the stop line": STOP_LINE, "the leaf": LEAF}
	if window != null:
		points["the service window"] = _box(window).get_center()
	var dark: Array[String] = []
	for label: String in points:
		if not lights.any(func(light: SpotLight3D) -> bool: return _reaches(light, points[label])):
			dark.append(label)
	_check(not lights.is_empty() and window != null and dark.is_empty(), ("G1: a white flood by "
		+ "the gate, %.0f-%.0f m up, lights the approach, the stop line, the booth's service window "
		+ "and the leaf (%d lights; dark: %s)") % [HEIGHT.x, HEIGHT.y, lights.size(), dark])


func _heads(compound: Node3D) -> void:
	var heads := compound.find_children("GateFloodHead*", "Node3D", true, false)
	var real := heads.size() >= 2
	for head: Node3D in heads:
		var model := head.find_children("*", "Node3D", true, false).any(
			func(node: Node) -> bool: return String(node.scene_file_path) == LED_FLOOD)
		var lit := false
		for mesh: MeshInstance3D in head.find_children("*", "MeshInstance3D", true, false):
			for surface in range(mesh.get_surface_override_material_count()):
				var made := mesh.get_surface_override_material(surface) as BaseMaterial3D
				if made != null and made.emission_enabled:
					lit = true
		real = real and model and lit and head.find_child("FloodLight", true, false) is SpotLight3D
	var pole := compound.find_child("GateFloodPole", true, false) as Node3D
	_check(real and pole != null, ("G2: the gate's pole carries the chosen LED floods (The Street "
		+ "Light Man's model), their LEDs lit, each with its light (%d heads, pole %s)")
		% [heads.size(), pole != null])


func _clear(compound: Node3D) -> void:
	var pole := compound.find_child("GateFloodPole", true, false) as Node3D
	var box := _box(pole) if pole else AABB()
	var foot := Rect2(box.position.x, box.position.z, box.size.x, box.size.z)
	var solid := false
	if pole != null:
		var body := compound.get_node_or_null("CompoundBody") as StaticBody3D
		for shape: CollisionShape3D in body.find_children("*", "CollisionShape3D", false, false):
			var at := shape.global_position
			if Vector2(at.x - box.get_center().x, at.z - box.get_center().z).length() < 0.4:
				solid = true
	var clear := pole != null and not foot.intersects(DRIVEWAY) and not foot.intersects(LEAF_RUN)
	_check(clear and solid, ("G3: the pole solid, off the driveway and clear of the leaf's run "
		+ "(clear %s, solid %s)") % [clear, solid])


func _covers(rain: Node3D, index: int, point: Vector3) -> bool:
	var volume := rain.get("volumes")[index] as Node3D
	var emitter := rain.call("rain", index) as GPUParticles3D
	var box := (emitter.process_material as ParticleProcessMaterial).emission_box_extents
	var local := volume.global_transform.affine_inverse() * point
	return absf(local.x) <= box.x and absf(local.z) <= box.z


func _gate_rain(rain: Node3D) -> void:
	var volumes: Array = rain.get("volumes")
	var found := -1
	for index in range(volumes.size()):
		if _covers(rain, index, STOP_LINE) and _covers(rain, index, GATE):
			found = index
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.global_position = STOP_LINE + Vector3(0.0, 2.2, 1.0)
	camera.make_current()
	for frame in range(4):
		await physics_frame
	var raining := found >= 0 and bool(rain.call("is_active", found))
	camera.queue_free()
	_check(raining, ("G4: rain in the gate's light, over the stop line and the opening, raining "
		+ "with the camera at the stop line (volume %d)") % found)


func _yard_rain(compound: Node3D, rain: Node3D) -> void:
	var volumes: Array = rain.get("volumes")
	var floods: Array[String] = []
	var dry: Array[String] = []
	for light: SpotLight3D in compound.find_children("Flood?", "SpotLight3D", false, false):
		floods.append(String(light.name))
		var wet := false
		for index in range(volumes.size()):
			var volume := volumes[index] as Node3D
			var at := volume.global_position
			if _reaches(light, Vector3(at.x, 0.0, at.z)) and Vector2(at.x - light.global_position.x,
					at.z - light.global_position.z).length() < light.spot_range:
				wet = true
		if not wet:
			dry.append(String(light.name))
	_check(floods.size() == 3 and dry.is_empty(), ("G5: rain in the light of each of the "
		+ "compound's yard floods (%s; dry: %s)") % [floods, dry])


func _finish() -> void:
	print("GATE LIGHT RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	_app.queue_free()
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "The gate light's checks finish within 120 s")
	quit(1)
