extends SceneTree
## Mission 3's step 3, part A: the waterfront (docs/PHASE_BRIEF.md, 2026-11-21, #359-#360), after
## Commons photos of small container terminals at night (Dublin's South Quays, a Liebherr mobile
## harbour crane): an access road from the coastal road to the terminal's gate, open; the terminal
## fenced in chain-link but for its gate and its quay; blocks of containers at their real ISO sizes,
## two to four high, solid; a mobile harbour crane on the apron, its boom out over the water; high
## masts at least 25 m tall in warm floodlight, rain falling in it; mooring bollards along the quay
## edge and fenders on its wall; berth 2 marked at the quay's edge and reached from the gate by a
## clear lane; and on Last Run's start the objective sends the van to the gate, then to berth 2.

const STAGE_ZERO := "[save]\nversion=2\nmission=\"last_run\"\n\n[run]\nstage=0\n"
const ACCESS: Array[Vector3] = [Vector3(730.0, 0.0, 200.0), Vector3(845.0, 0.0, 200.0)]
const QUAY_X := 1000.0
const ISO := {"Container20": Vector3(6.058, 2.591, 2.438), "Container40": Vector3(12.192, 2.591,
	2.438), "Container40HC": Vector3(12.192, 2.896, 2.438)}

var _checks: int = 0
var _failures: int = 0
var _scratch: String
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
	create_timer(240.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-waterfront-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(STAGE_ZERO)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	await physics_frame
	_space = _app.get_world_3d().direct_space_state
	var flats := _app.get_node("IndustrialLoop").get("harbour_flats") as Node3D
	var front := flats.get("waterfront") as Node3D if flats != null else null
	if front == null:
		_check(false, "W1: the flats have their waterfront (none)")
		_finish()
		return
	_check_access(front)
	_check_fence(front)
	_check_containers(front)
	_check_crane(front)
	_check_masts(front)
	_check_quay(front)
	_check_berth(front)
	await _check_objective(front)
	_finish()


func _check_access(front: Node3D) -> void:
	var holes := 0
	var blocked := 0
	for step in range(0, 116, 4):
		var at := ACCESS[0].lerp(ACCESS[1], step / 115.0)
		if _down(at).is_empty():
			holes += 1
		if _blocked(at, ACCESS[1] - ACCESS[0], Vector3(5.0, 3.0, 3.0)):
			blocked += 1
	var gate: Vector3 = front.get("gate")
	_check(holes == 0 and blocked == 0 and gate.distance_to(Vector3(840.0, 0.0, 200.0)) < 6.0,
		("W1: the access road from the coastal road to the gate, solid (%d holes) and clear (%d "
		+ "blocked), the gate open at %s") % [holes, blocked, gate])


func _check_fence(front: Node3D) -> void:
	var runs: Array = front.get("fence_runs")
	var length := 0.0
	for run: Dictionary in runs:
		length += (run["from"] as Vector2).distance_to(run["to"])
	var closed := 0
	for z in [170.0, 230.0, 290.0]:
		if _blocked(Vector3(840.0, 0.0, z), Vector3.RIGHT, Vector3(0.5, 2.0, 0.5)):
			closed += 1
	var open := not _blocked(Vector3(840.0, 0.0, 200.0), Vector3.RIGHT, Vector3(0.5, 2.0, 3.0))
	_check(not runs.is_empty() and length > 400.0 and closed == 3 and open, ("W2: the terminal "
		+ "fenced in chain-link (%.0f m), shut along its west side (%d of 3 points) but open at "
		+ "the gate (%s)") % [length, closed, open])


func _check_containers(front: Node3D) -> void:
	var stacks: Array = front.get("stacks")
	var real := stacks.all(func(stack: Array) -> bool:
		return ISO.has(stack[0]) and int(stack[2]) >= 2 and int(stack[2]) <= 4)
	var solid := 0
	for stack: Array in stacks.slice(0, 6):
		var base: Transform3D = stack[1]
		if not _down(base.origin + Vector3.UP * 0.1).is_empty() \
				and (_down(base.origin + Vector3.UP * 0.1)["position"] as Vector3).y > 4.0:
			solid += 1
	_check(stacks.size() >= 24 and real and solid == mini(stacks.size(), 6), ("W3: %d stacks of "
		+ "containers at ISO sizes, two to four high (%s), solid (%d)") % [stacks.size(), real,
		solid])


func _check_crane(front: Node3D) -> void:
	var crane := front.get("crane") as Node3D
	var reach := -INF
	var top := -INF
	if crane != null:
		for mesh: MeshInstance3D in crane.find_children("*", "MeshInstance3D", true, false):
			var box := mesh.global_transform * mesh.get_aabb()
			reach = maxf(reach, box.end.x)
			top = maxf(top, box.end.y)
	var base: Vector3 = front.get("crane_base")
	var base_solid := crane != null and _blocked(base + Vector3.UP * 1.0, Vector3.RIGHT,
		Vector3(1.0, 1.0, 1.0))
	_check(crane != null and base.x > QUAY_X - 30.0 and base.x < QUAY_X - 4.0
		and reach > QUAY_X + 15.0 and top > 25.0 and base_solid, ("W4: the mobile harbour crane "
		+ "on the apron (x %.0f), its boom out over the water to x %.0f, %.0f m high, solid at "
		+ "its base (%s)") % [base.x, reach, top, base_solid])


func _check_masts(front: Node3D) -> void:
	var masts: Array = front.get("masts")
	var tall := masts.all(_tall_and_warm)
	var rain := _app.get_node("IndustrialLoop").get("lamp_rain") as Node
	var wet := 0
	for volume: Node3D in rain.get("volumes"):
		for mast: Node3D in masts:
			if Vector2(volume.global_position.x - mast.global_position.x,
					volume.global_position.z - mast.global_position.z).length() < 20.0:
				wet += 1
				break
	_check(masts.size() >= 4 and tall and wet >= masts.size(), ("W5: %d high masts, their warm "
		+ "floods 25 m up or more (%s), rain in each one's light (%d)") % [masts.size(), tall, wet])


func _tall_and_warm(mast: Node3D) -> bool:
	var found := mast.find_children("*", "SpotLight3D", true, false)
	if found.is_empty():
		return false
	var light := found[0] as SpotLight3D
	return light.global_position.y >= 25.0 and light.light_color.r > light.light_color.b


func _check_quay(front: Node3D) -> void:
	var bollards: Array = front.get("bollards")
	bollards.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return a.global_position.z < b.global_position.z)
	var widest := 0.0
	var on_edge := true
	for index in range(bollards.size()):
		var at := (bollards[index] as Node3D).global_position
		on_edge = on_edge and absf(at.x - QUAY_X) < 1.5
		if index > 0:
			widest = maxf(widest, at.z - (bollards[index - 1] as Node3D).global_position.z)
	var fenders: Array = front.get("fenders")
	_check(bollards.size() >= 6 and on_edge and widest <= 20.0 and fenders.size() >= 6,
		("W6: %d mooring bollards along the quay's edge (%s), at most %.0f m apart, %d fenders on "
		+ "its wall") % [bollards.size(), on_edge, widest, fenders.size()])


func _check_berth(front: Node3D) -> void:
	var berth: Vector3 = front.get("berth")
	var clear := 0
	var gate: Vector3 = front.get("gate")
	var steps := 40
	for step in range(steps + 1):
		var at := gate.lerp(berth, float(step) / steps)
		if not _blocked(at, berth - gate, Vector3(3.0, 2.5, 3.0)):
			clear += 1
	_check(absf(berth.x - (QUAY_X - 8.0)) < 6.0 and clear == steps + 1, ("W7: berth 2 marked at "
		+ "the quay's edge (%s), a clear lane from the gate to it (%d of %d)") % [berth, clear,
		steps + 1])


func _check_objective(front: Node3D) -> void:
	_app.call("_begin")
	for frame in range(20):
		await physics_frame
	var hud := _app.get("hud") as CanvasLayer
	var title := (hud.get("_objective") as Label).text
	var target: Vector3 = hud.get("target")
	var gate: Vector3 = front.get("gate")
	var first := title == "DRIVE TO THE WATERFRONT" and Vector2(target.x - gate.x,
		target.z - gate.z).length() < 4.0
	var van := _app.get_node("FreightVan") as CharacterBody3D
	van.call("recover", Transform3D(Basis(Vector3.UP, -PI / 2.0), gate + Vector3(12.0, 0.1, 0.0)))
	for frame in range(20):
		await physics_frame
	title = (hud.get("_objective") as Label).text
	target = hud.get("target")
	var berth: Vector3 = front.get("berth")
	var second := title == "PARK AT BERTH 2" and Vector2(target.x - berth.x,
		target.z - berth.z).length() < 2.0
	_check(first and second, ("W8: the objective sends the van to the gate (%s), then inside to "
		+ "berth 2 (%s)") % [first, title])


func _down(at: Vector3) -> Dictionary:
	return _space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(at.x, 60.0, at.z),
		Vector3(at.x, -10.0, at.z), 1))


func _blocked(at: Vector3, along: Vector3, size: Vector3) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	query.shape = shape
	query.transform = Transform3D(Basis.looking_at(along.normalized(), Vector3.UP),
		Vector3(at.x, size.y / 2.0 + 0.3, at.z))
	query.collision_mask = 1
	return not _space.intersect_shape(query, 1).is_empty()


func _timeout() -> void:
	print("FAIL: test timed out")
	_failures += 1
	_finish()


func _finish() -> void:
	print("WATERFRONT RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(1 if _failures > 0 else 0)
