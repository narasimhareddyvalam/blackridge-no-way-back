extends SceneTree
## Mission 3's step 5, part B: the convoy (docs/PHASE_BRIEF.md, 2026-11-21, #359-#360; GAME_STORY's
## Act V: "Ethan follows a convoy toward the airfield ... Maya provides timing, a route change, and
## access information"), on Last Run's stage 2 save: INTERCEPT THE CONVOY to the coastal road; there
## two black SUVs are ahead heading north and Maya calls; TAIL THE CONVOY, 25-200 m behind: too
## close for 2 s and they see him (back to the junction, the convoy reset); kept back, the convoy
## keys through the airfield's gate, which shuts behind it; THE SERVICE GATE along the freight
## track; at it E keys Maya's code, the gate opens, stage 3 is saved, GET INTO THE HANGAR.

const STAGE_TWO := "[save]\nversion=2\nmission=\"last_run\"\n\n[run]\nstage=2\n"
const JUNCTION := Vector3(726.0, 0.0, 151.7)

var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _app: Node3D
var _van: CharacterBody3D
var _hud: CanvasLayer
var _run_mission: Node


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(400.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-convoy-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(STAGE_TWO)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	await process_frame
	_hud = _app.get("hud") as CanvasLayer
	_app.call("_begin")
	await _frames(10)
	_van = _app.get_node("FreightVan") as CharacterBody3D
	_run_mission = _app.get("run") as Node
	var first := _objective()
	_van.call("recover", Transform3D(Basis(Vector3.UP, -PI / 2.0), JUNCTION + Vector3(-20.0, 0.1,
		0.0)))
	await _frames(30)
	var convoy := _run_mission.get("convoy") as Node
	var call := (_app.get("route") as Node).get("phone_call") as Node
	var ahead := convoy != null and (convoy.get("suvs") as Array).size() == 2 and (convoy.get(
		"suvs") as Array).all(_ahead_on_the_road)
	_check(first == "INTERCEPT THE CONVOY" and ahead and bool(call.get("active"))
		and String(call.get("caller")) == "MAYA" and _objective() == "TAIL THE CONVOY",
		("C1: INTERCEPT THE CONVOY (%s); at the coastal road two black SUVs ahead heading north "
		+ "(%s), Maya calling (%s); TAIL THE CONVOY (%s)") % [first, ahead, call.get("active"),
		_objective()])
	if convoy == null:
		_finish()
		return
	await _check_spotted(convoy)
	await _check_tail(convoy)
	await _check_service_gate()
	_finish()


func _ahead_on_the_road(suv: Node3D) -> bool:
	return suv.is_visible_in_tree() and suv.global_position.z < JUNCTION.z \
		and absf(suv.global_position.x - JUNCTION.x) < 8.0 and _tail_lamps_lit(suv)


## Both red tail lamps lit on its rear corners, seen from behind as a tailing driver sees them.
func _tail_lamps_lit(suv: Node3D) -> bool:
	var lit := 0
	for lens: MeshInstance3D in suv.find_children("TailLens*", "MeshInstance3D", true, false):
		var glass := lens.material_override as StandardMaterial3D
		if glass != null and glass.emission_enabled and glass.emission.r > 0.8 \
				and glass.emission.g < 0.2 and lens.position.z > 2.6:
			lit += 1
	return lit == 2


## C2: closer than 25 m for 2 s and they see him; back at the junction, the convoy reset.
func _check_spotted(convoy: Node) -> void:
	var spotted_before: int = convoy.get("spotted_count")
	var waited := 0.0
	while int(convoy.get("spotted_count")) == spotted_before and waited < 8.0:
		var lead := (convoy.get("suvs") as Array)[1] as Node3D
		_van.call("recover", Transform3D(lead.global_basis, lead.global_position
			+ lead.global_basis.z * 12.0 + Vector3.UP * 0.1))
		await physics_frame
		waited += 1.0 / 60.0
	await _seconds(2.5)
	var back := Vector2(_van.global_position.x - JUNCTION.x, _van.global_position.z
		- JUNCTION.z).length() < 30.0
	_check(int(convoy.get("spotted_count")) == spotted_before + 1 and waited >= 1.9 and back
		and _objective() == "TAIL THE CONVOY", ("C2: too close (12 m) they see him after %.1f s; "
		+ "back at the junction (%s), tailing again (%s)") % [waited, back, _objective()])


## C3: kept 60 m back, the convoy keys through the airfield's gate, which shuts behind it.
func _check_tail(convoy: Node) -> void:
	var field := _app.get_node("IndustrialLoop").get("harbour_flats").get("airfield") as Node3D
	var opened := false
	var through_shut := 0
	var waited := 0.0
	while not bool(convoy.get("inside")) and waited < 90.0:
		var tail := (convoy.get("suvs") as Array)[1] as Node3D
		var back := -tail.global_basis.z
		_van.call("recover", Transform3D(tail.global_basis, tail.global_position - back * 60.0
			+ Vector3.UP * 0.1))
		await physics_frame
		waited += 1.0 / 60.0
		opened = opened or bool(field.call("gate_open"))
		for suv: Node3D in convoy.get("suvs"):
			if absf(suv.global_position.x - field.get("gate").x) < 1.5 \
					and not bool(field.call("gate_open")):
				through_shut += 1
	await _seconds(4.0)
	_check(bool(convoy.get("inside")) and opened and through_shut == 0
		and not bool(field.call("gate_open")) and _objective() == "THE SERVICE GATE",
		("C3: tailed 60 m back, the convoy keys through the gate (%s), only once it stands open "
		+ "(%d frames in it shut), and it shuts behind them (%s); THE SERVICE GATE (%s)") % [
		opened, through_shut, not bool(field.call("gate_open")), _objective()])


## C4: at the service gate E keys Maya's code: it opens, stage 3 saved, GET INTO THE HANGAR.
func _check_service_gate() -> void:
	var field := _app.get_node("IndustrialLoop").get("harbour_flats").get("airfield") as Node3D
	var gate: Vector3 = field.get("service_gate")
	_van.call("recover", Transform3D(Basis.IDENTITY, gate + Vector3(1.5, 0.1, 7.0)))
	await _frames(30)
	var shut_before := _blocked(gate)
	var offered := (_hud.get("_hint") as Label).text
	await _press("interact")
	var waited := 0.0
	while not bool(field.call("service_open")) and waited < 10.0:
		await physics_frame
		waited += 1.0 / 60.0
	await _frames(10)
	var clear_after := not _blocked(gate)
	var saved := ConfigFile.new()
	saved.load(_scratch)
	_check(offered == "E  Key in Maya's code" and bool(field.call("service_open")) and shut_before
		and clear_after and int(saved.get_value("run", "stage", -1)) == 3
		and _objective() == "GET INTO THE HANGAR", ("C4: at the service gate (%s), shut (%s), E "
		+ "keys the code, it slides open (%s) and the way is clear (%s), stage %s saved, %s") % [
		offered, shut_before, field.call("service_open"), clear_after,
		saved.get_value("run", "stage", -1), _objective()])


## Whether anything solid stands in the gate's opening, a van's width and height.
func _blocked(at: Vector3) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.2, 1.8, 0.6)
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, at + Vector3.UP * 1.2)
	query.collision_mask = 1
	return not _van.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


func _objective() -> String:
	return (_hud.get("_objective") as Label).text


func _press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	await physics_frame


func _frames(count: int) -> void:
	for frame in range(count):
		await physics_frame


func _seconds(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _timeout() -> void:
	print("FAIL: test timed out")
	_failures += 1
	_finish()


func _finish() -> void:
	print("CONVOY RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(1 if _failures > 0 else 0)
