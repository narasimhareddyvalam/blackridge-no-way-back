extends SceneTree
## Mission 3's step 5, part A: the airfield (docs/PHASE_BRIEF.md, 2026-11-21, #359-#360), after
## Commons photos of William R. Fairchild airport at Port Angeles (chain-link with barbed wire, flat
## tarmac, an evergreen treeline): a runway 500 m or more long and 18 m wide with white edge lights
## at most 60 m apart and green thresholds, its numbers painted; a windsock; an apron joined to the
## runway by a taxiway; a steel hangar whose door opens wider than a PC-12's 16.28 m span and higher
## than its 4.26 m tail, high-bay lights inside, an office in its corner with a lit window; the
## PC-12 on the apron at its real size; the airfield fenced in chain-link with a keypad gate off the
## coastal road and a service gate on its south side; an access road to the gate.

const PC12 := Vector3(16.28, 4.26, 14.40)

var _checks: int = 0
var _failures: int = 0
var _app: Node3D
var _space: PhysicsDirectSpaceState3D


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(200.0, true, false, true).timeout.connect(_timeout)
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(_app)
	await process_frame
	await physics_frame
	_space = _app.get_world_3d().direct_space_state
	var flats := _app.get_node("IndustrialLoop").get("harbour_flats") as Node3D
	var field := flats.get("airfield") as Node3D if flats != null else null
	if field == null:
		_check(false, "F1: the flats have their airfield (none)")
		_finish()
		return
	_check_runway(field)
	_check_apron(field)
	_check_hangar(field)
	_check_plane(field)
	_check_fence(field)
	_finish()


func _check_runway(field: Node3D) -> void:
	var from: Vector3 = field.get("runway_from")
	var to: Vector3 = field.get("runway_to")
	var width: float = field.get("runway_width")
	var edges: Array = field.get("edge_lights")
	var greens: Array = field.get("threshold_lights")
	var widest := 0.0
	for side in [-1.0, 1.0]:
		var along: Array[float] = []
		for light: Node3D in edges:
			var off := (light.global_position - from).dot((to - from).normalized().cross(
				Vector3.UP))
			if signf(off) == side:
				along.append((light.global_position - from).dot((to - from).normalized()))
		along.sort()
		for index in range(along.size() - 1):
			widest = maxf(widest, along[index + 1] - along[index])
	var solid := 0
	for step in range(0, 11):
		if not _down(from.lerp(to, step / 10.0)).is_empty():
			solid += 1
	var numbers: Array = field.get("runway_numbers")
	_check(from.distance_to(to) >= 500.0 and is_equal_approx(width, 18.0) and edges.size() >= 16
		and widest <= 60.5 and greens.size() >= 4 and solid == 11 and numbers.size() == 2,
		("F1: the runway %.0f m by %.0f m, solid, %d white edge lights at most %.0f m apart, %d "
		+ "green threshold lights, its numbers painted (%s)") % [from.distance_to(to), width,
		edges.size(), widest, greens.size(), numbers])


func _check_apron(field: Node3D) -> void:
	var sock := field.get("windsock") as Node3D
	var apron: Rect2 = field.get("apron")
	var taxi: Array = field.get("taxiway")
	var clear := 0
	var a: Vector3 = taxi[0]
	var b: Vector3 = taxi[1]
	for step in range(0, 11):
		var at := a.lerp(b, step / 10.0)
		if not _down(at).is_empty() and not _blocked(at, Vector3(6.0, 3.0, 2.0)):
			clear += 1
	_check(sock != null and apron.size.x >= 60.0 and clear == 11, ("F2: a windsock (%s), the apron "
		+ "%s, a clear taxiway to the runway (%d of 11)") % [sock != null, apron, clear])


func _check_hangar(field: Node3D) -> void:
	var door: Vector2 = field.get("door_opening")
	var lights: Array = field.get("hangar_lights")
	var office := field.get("office") as Node3D
	var lit := office != null and office.find_children("*", "Light3D", true, false).size() > 0
	var centre: Vector3 = field.get("hangar_at")
	var size: Vector3 = field.get("hangar_size")
	var back_solid := _blocked(centre + Vector3(0.0, 0.0, size.z / 2.0 - 0.1), Vector3(2.0, 2.0,
		0.5))
	_check(door.x > PC12.x + 3.0 and door.y > PC12.y + 1.0 and lights.size() >= 4 and lit
		and back_solid, ("F3: the hangar's door %.1f m wide and %.1f m high (a PC-12 is %.2f by "
		+ "%.2f), %d high-bay lights, an office with a lit window (%s), solid walls (%s)") % [
		door.x, door.y, PC12.x, PC12.y, lights.size(), lit, back_solid])


func _check_plane(field: Node3D) -> void:
	var plane := field.get("plane") as Node3D
	var span := 0.0
	var length := 0.0
	if plane != null:
		var box := AABB()
		var first := true
		for mesh: MeshInstance3D in plane.find_children("*", "MeshInstance3D", true, false):
			var each := mesh.global_transform * mesh.get_aabb()
			box = each if first else box.merge(each)
			first = false
		span = maxf(box.size.x, box.size.z)
		length = minf(box.size.x, box.size.z)
	var apron: Rect2 = field.get("apron")
	_check(plane != null and absf(span - PC12.x) < 0.3 and absf(length - PC12.z) < 0.4
		and apron.has_point(Vector2(plane.global_position.x, plane.global_position.z)),
		("F4: the PC-12 on the apron, %.2f m span and %.2f m long (%.2f, %.2f)") % [span, length,
		PC12.x, PC12.z])


func _check_fence(field: Node3D) -> void:
	var runs: Array = field.get("fence_runs")
	var gate: Vector3 = field.get("gate")
	var service: Vector3 = field.get("service_gate")
	var keypad := field.find_child("Keypad", true, false) as Node3D
	var shut := _blocked(gate + Vector3.UP * 0.0, Vector3(4.0, 2.0, 0.6))
	var road := 0
	for step in range(0, 9):
		var at := Vector3(726.0, 0.0, gate.z).lerp(gate - Vector3(3.0, 0.0, 0.0), step / 8.0)
		if not _down(at).is_empty():
			road += 1
	_check(runs.size() >= 4 and keypad != null and shut and service.z > gate.z and road == 9,
		("F5: fenced (%d runs), a keypad (%s) by the gate, shut (%s), a service gate on the south "
		+ "side (%s), an access road from the coastal road (%d of 9)") % [runs.size(),
		keypad != null, shut, service, road])


func _down(at: Vector3) -> Dictionary:
	return _space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(at.x, 60.0, at.z),
		Vector3(at.x, -10.0, at.z), 1))


func _blocked(at: Vector3, size: Vector3) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, Vector3(at.x, size.y / 2.0 + 0.3, at.z))
	query.collision_mask = 1
	return not _space.intersect_shape(query, 1).is_empty()


func _timeout() -> void:
	print("FAIL: test timed out")
	_failures += 1
	_finish()


func _finish() -> void:
	print("AIRFIELD RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	quit(1 if _failures > 0 else 0)
