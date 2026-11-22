extends SceneTree
## One stopping distance for backing onto bay 9 (#287, step 2 of #289): the reversing camera's red
## stop line, the bay's verdict and the lift's bridge plate agree. A van docks when the red line,
## drawn on the ground a fixed distance behind its bumper, reaches the dock's bumpers, and the
## plate rests on its sill at any gap the bay calls docked.
## K1 the red stop line runs across the van's width on the ground at the distance the bay docks
##    within.
## K2 backed in at a crawl by the game's keys and stopped as the red line reaches the bumpers, the
##    van docks: straight in, and again after pulling forward, turned 1.5° to the bay.
## K3 stopped with the red line 0.1 m short of the bumpers, it does not dock, and the objective
##    says it is short.
## K4 at every gap the bay docks within (touching, half way, at the line) the lift's bridge plate
##    rests on the van's sill (its underside within 1 cm of it) and reaches at least 0.10 m onto
##    its floor, as dock plates must (4 in).
## K5 loaded with the 520 kg pallet, the van settles, and its floor as Ethan and the pallet meet it
##    is the floor drawn (within 3 mm), the pallet stands on it, and the plate still rests on the
##    sill drawn.

const ParkingGuides = preload("res://features/vehicles/freight_van/parking_guides.gd")
const VanBay = preload("res://features/environments/industrial_loop/van_bay.gd")
const START_SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const BAY := -47.75
const BUMPERS := 20.13
const REAR := Vector3(0.0, 1.0, 3.012)
const ORIGIN_Y := 0.1
const START_GAP := 3.0
const CRAWL := 0.4
const SHORT := 0.1
const OVERLAP := 0.10
const RESTS := 0.01
const LIP_THICK := 0.025
const TURNED := 1.5
const VanHold = preload("res://features/vehicles/freight_van/van_hold.gd")
const FLOOR_MATCH := 0.003
const BRAKED := 0.06

var _checks: int = 0
var _failures: int = 0
var _app: Node
var _van: Node3D
var _bay: Node
var _hud: Node
var _scratch: String


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(300.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-docking-%d.cfg" % OS.get_process_id())
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(START_SAVE)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	_van = _app.get_node("FreightVan")
	_hud = _app.get_node("DrivingHud")
	await process_frame
	await process_frame
	await _key(KEY_ENTER)
	await _seconds(1.0)
	_bay = _app.get_node("IndustrialLoop").get("transfer_shed").get("bay_nine")
	await _place(START_GAP, 0.0)
	await _key(KEY_Q)
	await _seconds(0.5)
	_check_stop_line()
	var straight := await _back_to_line(0.0)
	await _pull_forward()
	await _place(START_GAP, TURNED)
	await _key(KEY_Q)
	await _seconds(0.3)
	var turned := await _back_to_line(0.0)
	var by_line: float = VanBay.DOCKED_WITHIN - BRAKED
	_check(straight["verdict"] == "docked" and turned["verdict"] == "docked"
		and straight["gap"] >= by_line and turned["gap"] >= by_line,
		("K2 backed in at a crawl and stopped as the red line reaches the bumpers, the van docks: "
		+ "stopped by the brake, not the bumpers: straight in (%s, %.3f m from them) and turned %.1f° (%s, %.3f m, %.1f°)") % [
		straight["verdict"], straight["gap"], TURNED, turned["verdict"], turned["gap"],
		turned["angle"]])
	await _pull_forward()
	await _place(START_GAP, 0.0)
	await _key(KEY_Q)
	await _seconds(0.3)
	var short := await _back_to_line(SHORT)
	var said := _objective()
	_check(short["verdict"] == "far" and said.contains("short of the bumpers"),
		("K3 stopped with the red line %.1f m short of the bumpers (%.3f m from them) it does "
		+ "not dock (%s), and the objective says so (%s)") % [SHORT, short["gap"],
		short["verdict"], said])
	await _check_plate()
	await _check_loaded()
	_finish()


## The van lined up with bay 9, `gap` from its bumpers, turned `turn` degrees, its doors open.
func _place(gap: float, turn: float) -> void:
	_van.call("recover", Transform3D(Basis(Vector3.UP, PI), Vector3(BAY, ORIGIN_Y, BUMPERS + 12.0)))
	await _seconds(0.3)
	var basis := Basis(Vector3.UP, PI + deg_to_rad(turn))
	var back := basis * Vector3(0.0, 0.0, REAR.z)
	_van.call("recover", Transform3D(basis, Vector3(BAY - back.x, ORIGIN_Y,
		BUMPERS + gap - back.z)))
	_van.set("rear_doors_open", true)
	await _seconds(1.2)


func _guides() -> Control:
	for found in _van.find_children("*", "Control", true, false):
		if found.get_script() == ParkingGuides and not found.get_parent() is SubViewport:
			return found as Control
	return null


func _stop_points() -> Array[Vector3]:
	var points: Array[Vector3] = []
	var guides := _guides()
	if guides == null or not guides.has_method("segments"):
		return points
	for segment: Dictionary in guides.call("segments"):
		if String(segment["kind"]) == "stop":
			points.append(segment["from"])
			points.append(segment["to"])
	return points


func _check_stop_line() -> void:
	var points := _stop_points()
	var across := Vector2(INF, -INF)
	var behind := Vector2(INF, -INF)
	var red := true
	for segment: Dictionary in (_guides().call("segments") if _guides() != null
			and _guides().has_method("segments") else []):
		if String(segment["kind"]) == "stop":
			red = red and (segment["colour"] as Color).is_equal_approx(Color("e0483e"))
	for point in points:
		var local := _van.to_local(point)
		across = Vector2(minf(across.x, local.x), maxf(across.y, local.x))
		behind = Vector2(minf(behind.x, local.z - REAR.z), maxf(behind.y, local.z - REAR.z))
	var within: float = VanBay.DOCKED_WITHIN
	_check(not points.is_empty() and red and across.x <= -0.99 and across.y >= 0.99
		and absf(behind.x - within) < 0.01 and absf(behind.y - within) < 0.01,
		("K1 the red stop line runs across the van (%.2f to %.2f m) on the ground %.3f-%.3f m "
		+ "behind its bumper, where the bay docks within %.2f m") % [across.x, across.y,
		behind.x, behind.y, within])


## Backs in at a crawl by the keys, braking once the red line is `short` from the bumpers' face,
## as a driver watching it would; then the bay's verdict.
func _back_to_line(short: float) -> Dictionary:
	var time := 0.0
	var stopping := false
	var still := 0.0
	while time < 30.0 and still < 1.0:
		var points := _stop_points()
		var line := INF
		for point in points:
			line = minf(line, point.z)
		stopping = stopping or line <= BUMPERS + short
		var speed := absf(float(_van.get("actual_speed")))
		_press("accelerate", not stopping and speed < CRAWL - 0.1)
		_press("brake", stopping or speed > CRAWL + 0.1)
		await physics_frame
		time += 1.0 / 60.0
		still = still + 1.0 / 60.0 if stopping and speed < 0.03 else 0.0
	_press("accelerate", false)
	_press("brake", false)
	await _seconds(1.0)
	var rear := _van.to_global(REAR)
	return {"verdict": String(_bay.get("verdict")), "gap": rear.z - BUMPERS,
		"angle": rad_to_deg(acos(clampf(-_van.global_basis.z.normalized().z, -1.0, 1.0)))}


func _pull_forward() -> void:
	await _key(KEY_Q)
	_press("accelerate", true)
	await _seconds(2.0)
	_press("accelerate", false)
	_press("brake", true)
	await _seconds(1.0)
	_press("brake", false)


func _check_plate() -> void:
	var lift := _app.get_node("IndustrialLoop").get("transfer_shed").get_node(
		"Building/DockLift9") as Node3D
	var results: Array[String] = []
	var good := true
	for gap: float in [0.0, VanBay.DOCKED_WITHIN / 2.0, VanBay.DOCKED_WITHIN - 0.005]:
		await _place(gap, 0.0)
		var docked := String(_bay.get("verdict")) == "docked"
		await _hold_interact(func() -> bool: return bool(lift.call("at_bottom")), 12.0)
		await _seconds(1.2)
		var sill: Vector3 = _van.call("sill")
		var resting := _plate_underside_at(lift, sill.z) - sill.y
		var onto := _lip_tip(lift).z - sill.z
		var fine := docked and absf(resting) <= RESTS and onto >= OVERLAP
		good = good and fine
		results.append("gap %.3f: docked %s, %.3f m off the sill, %.3f m onto the floor" % [gap,
			docked, resting, onto])
		await _hold_interact(func() -> bool: return bool(lift.call("at_top")), 12.0)
	_check(good, "K4 at every gap the bay docks within the plate rests on the sill and reaches "
		+ "onto the floor (%s)" % "; ".join(results))


func _check_loaded() -> void:
	var shed: Node = _app.get_node("IndustrialLoop").get("transfer_shed")
	var lift := shed.get_node("Building/DockLift9") as Node3D
	var body := _van.get_node("VanPresentation") as Node3D
	await _place(VanBay.DOCKED_WITHIN / 2.0, 0.0)
	await _hold_interact(func() -> bool: return bool(lift.call("at_bottom")), 12.0)
	await _seconds(1.2)
	var stack := shed.get_node("Building/Pallet6") as Node3D
	(shed.get("pallet_jack") as Node).call("stow", stack)
	await _seconds(2.5)
	var drawn := body.to_global(Vector3(0.0, VanHold.FLOOR, 1.5))
	var ray := PhysicsRayQueryParameters3D.create(drawn + Vector3.UP * 0.5,
		drawn + Vector3.DOWN * 0.5, 2)
	ray.exclude = [(_van as CollisionObject3D).get_rid()]
	var hit := _van.get_world_3d().direct_space_state.intersect_ray(ray)
	var floor_off := (hit["position"] as Vector3).y - drawn.y if not hit.is_empty() else INF
	var under := body.to_global(Vector3(0.0, VanHold.FLOOR, body.to_local(
		stack.global_position).z))
	var stands := stack.global_position.y - under.y
	var sill := body.to_global(VanHold.SILL)
	var resting := _plate_underside_at(lift, sill.z) - sill.y
	var sank := float(_van.get("load_kg"))
	_check(sank > 0.0 and absf(floor_off) <= FLOOR_MATCH and absf(stands) <= FLOOR_MATCH
		and absf(resting) <= RESTS,
		("K5 loaded (%.0f kg), the van's floor as met is %.4f m off the floor drawn, the pallet "
		+ "stands %.4f m off it, and the plate rests %.4f m off the sill drawn") % [sank,
		floor_off, stands, resting])


func _hold_interact(done: Callable, limit: float) -> void:
	Input.action_press("interact")
	_bay.call("operate_lift")
	var time := 0.0
	while not done.call() and time < limit:
		await physics_frame
		time += 1.0 / 60.0
	Input.action_release("interact")
	await physics_frame


func _plate_underside_at(lift: Node3D, z: float) -> float:
	var plate := lift.find_child("BridgeLip", true, false) as Node3D
	var tip := _lip_tip(lift)
	var along := tip - plate.global_position
	if absf(along.z) < 0.001:
		return INF
	var t := (z - plate.global_position.z) / along.z
	return plate.global_position.y + along.y * t - LIP_THICK


func _lip_tip(lift: Node3D) -> Vector3:
	return (lift.find_child("BridgeLipEdge", true, false) as Node3D).global_position


func _objective() -> String:
	return "%s: %s" % [(_hud.get("_objective") as Label).text, (_hud.get("_detail") as Label).text]


func _press(action: String, on: bool) -> void:
	if on:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await process_frame


func _seconds(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _finish() -> void:
	print("DOCKING RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	_app.queue_free()
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "Docking test finished within 300 s")
	quit(1)
