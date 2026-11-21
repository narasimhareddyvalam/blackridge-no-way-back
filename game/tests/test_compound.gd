extends SceneTree
## Mission 2's step 5 (docs/PHASE_BRIEF.md, "the warehouse compound"; the author's choices,
## #314-#315), part A, on Mission 2's stage 2 save (in the dark van at the container yard), by
## real key presses where the player acts: the compound fenced round both warehouses but at its
## gate, in 2.4 m chain-link with barbed wire, clear of the container yard's fence; the guard
## booth before the gate with its guard seated, a stand-in, not the shed's guard and with no gun;
## the gate shut until E at the booth's line hands the run sheet over (his window down), open
## after her check, shut behind the van, the window up again; the fence, the gate and the booth
## solid; and the objective on the way.

const STAGE_TWO := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=2\n"
## The fence's outline, stepped in west of x 138 to keep clear of the container yard.
const OUTLINE: Array[Vector2] = [Vector2(138.0, 146.0), Vector2(274.0, 146.0),
	Vector2(274.0, 92.0), Vector2(128.0, 92.0), Vector2(128.0, 130.0), Vector2(138.0, 130.0)]
const GATE := Vector2(197.0, 203.0)
const FENCE_HEIGHT := 2.4
const YARD_CLEAR := 1.5
const WAREHOUSES: Array[Vector2] = [Vector2(150.0, 112.0), Vector2(250.0, 120.0)]
const SHED_GUARD := "res://features/characters/guard/guard.glb"
## At the line, tucked in toward the booth for the guard to reach his window (#355).
const AT_THE_LINE := Transform3D(Basis.IDENTITY, Vector3(199.4, 0.1, 151.3))
const ON_THE_DRIVE := Transform3D(Basis.IDENTITY, Vector3(200.0, 0.1, 166.0))
const INSIDE := Transform3D(Basis.IDENTITY, Vector3(200.0, 0.1, 138.0))
const FURTHER_IN := Transform3D(Basis.IDENTITY, Vector3(220.0, 0.1, 136.0))

var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _app: Node3D
var _van: CharacterBody3D
var _compound: Node3D
var _cargo: Node
var _hud: CanvasLayer


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(300.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-compound-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	await _start()
	_check(_compound != null and _compound.has_method("fence_runs"),
		"K0: the world has its warehouse compound (IndustrialLoop/WarehouseCompound)")
	if _compound == null or not _compound.has_method("fence_runs"):
		_finish()
		return
	_check(_objective().begins_with("DRIVE TO THE WAREHOUSE COMPOUND"),
		"K5: at the container yard the objective names the compound (%s)" % _objective())
	_check_fence()
	_check_booth()
	await _check_solid()
	await _check_gate()
	_finish()


func _start() -> void:
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(STAGE_TWO)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	await process_frame
	_cargo = _app.get("cargo") as Node
	_hud = _app.get("hud") as CanvasLayer
	_app.call("_begin")
	await _frames(10)
	_van = _app.get_node("FreightVan") as CharacterBody3D
	_compound = _app.get_node("IndustrialLoop").get("compound") as Node3D


func _check_fence() -> void:
	var runs: Array = _compound.call("fence_runs")
	var length := 0.0
	for run: Dictionary in runs:
		length += (run["from"] as Vector2).distance_to(run["to"])
	var perimeter := 0.0
	for index in range(OUTLINE.size()):
		perimeter += OUTLINE[index].distance_to(OUTLINE[(index + 1) % OUTLINE.size()])
	var posts := _compound.find_children("FencePost*", "MeshInstance3D", true, false)
	var tall := not posts.is_empty()
	for post in posts:
		tall = tall and absf((post as MeshInstance3D).get_aabb().size.y - (FENCE_HEIGHT + 0.05)) \
			< 0.02
	var barbs := _compound.find_children("BarbStrand*", "MeshInstance3D", true, false).size()
	var on_outline := not runs.is_empty()
	for run: Dictionary in runs:
		on_outline = on_outline and _on_outline(run["from"]) and _on_outline(run["to"])
	_check(absf(length + (GATE.y - GATE.x) - perimeter) < 0.01 and tall and on_outline
		and barbs == runs.size() * 3, "K1: the compound fenced round in 2.4 m chain-link with "
		+ "barbed wire but for its 6 m gate (%.1f m of %.1f m, %d strands)" % [length, perimeter,
		barbs])
	var inside := true
	for at in WAREHOUSES:
		inside = inside and Geometry2D.is_point_in_polygon(at, PackedVector2Array(OUTLINE))
	var nearest := INF
	var yard := _app.get_node("IndustrialLoop").get("container_yard") as Node3D
	for run: Dictionary in runs:
		for other: Dictionary in yard.call("fence_runs"):
			nearest = minf(nearest, _apart(run["from"], run["to"], other["from"], other["to"]))
	_check(inside and nearest >= YARD_CLEAR, "K1: both warehouses inside it, and its fence "
		+ "%.1f m from the container yard's at the nearest" % nearest)


func _check_booth() -> void:
	var booth := _compound.get_node_or_null("GuardBooth") as Node3D
	var guard := booth.find_child("CompoundGuardStandIn", true, false) as Node3D \
		if booth != null else null
	var gun := false
	var seated := false
	if guard != null:
		for mesh in guard.find_children("*", "MeshInstance3D", true, false):
			var visual := mesh as MeshInstance3D
			for surface in range(visual.mesh.get_surface_count()):
				var material := visual.get_active_material(surface)
				gun = gun or (material != null and material.resource_name.contains("pistol"))
		var player := guard.find_children("*", "AnimationPlayer", true, false)
		seated = not player.is_empty() and (player[0] as AnimationPlayer).is_playing() \
			and (player[0] as AnimationPlayer).current_animation == "SitIdle"
	var driver_side := booth != null and booth.global_position.x < GATE.x \
		and booth.global_position.z > OUTLINE[0].y
	_check(guard != null and bool(guard.get_meta("stand_in", false)) and seated
		and guard.scene_file_path != SHED_GUARD and not gun and driver_side, "K2: the booth "
		+ "before the gate on the driver's side, its guard seated, a stand-in, not the shed's "
		+ "guard, with no gun")


func _check_solid() -> void:
	await physics_frame
	var space := _app.get_world_3d().direct_space_state
	var missed: Array[String] = []
	var walls := {"west": [Vector3(129.0, 1.0, 110.0), Vector3(127.0, 1.0, 110.0)],
		"south": [Vector3(200.0, 1.0, 93.0), Vector3(200.0, 1.0, 91.0)],
		"east": [Vector3(273.0, 1.0, 100.0), Vector3(275.0, 1.0, 100.0)],
		"north": [Vector3(240.0, 1.0, 145.0), Vector3(240.0, 1.0, 147.0)],
		"the step's side": [Vector3(139.0, 1.0, 138.0), Vector3(137.0, 1.0, 138.0)],
		"the step's front": [Vector3(133.0, 1.0, 129.0), Vector3(133.0, 1.0, 131.0)],
		"the gate": [Vector3(200.0, 1.0, 145.0), Vector3(200.0, 1.0, 147.0)]}
	for wall: String in walls:
		var ray := PhysicsRayQueryParameters3D.create(walls[wall][0], walls[wall][1])
		if space.intersect_ray(ray).is_empty():
			missed.append(wall)
	var booth := _compound.get_node_or_null("GuardBooth") as Node3D
	if booth != null:
		var probe := PhysicsPointQueryParameters3D.new()
		probe.position = booth.global_position + Vector3.UP * 0.5
		if space.intersect_point(probe, 1).is_empty():
			missed.append("the booth")
	_check(missed.is_empty(), "K4: the fence round, the shut gate and the booth solid (not: %s)"
		% ", ".join(missed))


func _check_gate() -> void:
	_van.call("recover", ON_THE_DRIVE)
	await _frames(20)
	_check(not bool(_cargo.call("wants_interact"))
		and _objective().begins_with("STOP AT THE BOOTH"),
		"K3: on the drive, E at the booth not yet offered; the objective: stop at the booth (%s)"
		% _objective())
	_van.call("recover", AT_THE_LINE)
	await _frames(20)
	_check(bool(_compound.call("gate_shut")) and bool(_cargo.call("wants_interact")),
		"K3: the gate shut, and E offered at the booth's line")
	_tap("interact")
	await _frames(5)
	var window_down := float(_van.get("left_window_target")) > 0.5
	var waiting := _objective()
	var waited := 0.0
	while not bool(_compound.call("gate_open")) and waited < 35.0:
		await physics_frame
		waited += 1.0 / 60.0
	_check(window_down and waiting.begins_with("WAIT AT THE GATE")
		and bool(_compound.call("gate_open")) and _objective().begins_with("DRIVE IN"),
		"K3: E hands the run sheet over, his window down; after her check the gate slides open "
		+ "(%.1f s), and the objective names the door (%s)" % [waited, _objective()])
	_van.call("recover", INSIDE)
	await _frames(10)
	_van.call("recover", FURTHER_IN)
	waited = 0.0
	while not bool(_compound.call("gate_shut")) and waited < 20.0:
		await physics_frame
		waited += 1.0 / 60.0
	_check(bool(_compound.call("gate_shut")) and float(_van.get("left_window_target")) < 0.5,
		"K3: and shuts behind the van, the window up again (%.1f s)" % waited)


func _objective() -> String:
	return (_hud.get("_objective") as Label).text + " / " + (_hud.get("_detail") as Label).text


func _on_outline(point: Vector2) -> bool:
	for index in range(OUTLINE.size()):
		var from := OUTLINE[index]
		var to := OUTLINE[(index + 1) % OUTLINE.size()]
		if Geometry2D.get_closest_point_to_segment(point, from, to).distance_to(point) < 0.01:
			return true
	return false


func _apart(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> float:
	var points := Geometry2D.get_closest_points_between_segments(a, b, c, d)
	return (points[0] as Vector2).distance_to(points[1])


func _tap(action: String) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)


func _frames(count: int) -> void:
	for frame in range(count):
		await physics_frame


func _timeout() -> void:
	_check(false, "The compound's checks finish within 300 s")
	_finish()


func _finish() -> void:
	print("COMPOUND RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	for suffix in ["", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(_scratch + suffix):
			DirAccess.remove_absolute(_scratch + suffix)
	quit(1 if _failures > 0 else 0)
