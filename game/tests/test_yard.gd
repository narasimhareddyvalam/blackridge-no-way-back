extends SceneTree
## Part H of step 5 of #253 (docs/PHASE_BRIEF.md, "the yard at night"; the author's choices, #305):
## the transfer shed's yard as a shed's is overnight, read from the shed as the running game builds
## it on Mission 2's start save, through what its vehicles hand out (`placements()`): dropped dry
## vans backed square onto docks 1-3, their rears at the bumpers and their floors at the dock's
## height, their landing gear down on the paving, a rear wheel chocked, the dock doors shut behind
## them and the outside signals red; a dropped trailer in the west trailer bay and the 1980 tractor
## coupled to another in the middle one, its fifth wheel under the trailer's kingpin and the
## trailer's landing gear cranked up; the box truck nose out in the east bay; the sedan and the
## covered car in the staff bays; the dumpsters against the east wall; nothing in the van's way
## from the gate to bay 9, or by the west exit's stair; each solid. A headless run draws nothing.

const START_SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const DOCK_FLOOR := 1.3
const GROUND := 0.02
const TRAILER_DOCKS: Array[float] = [-80.0, -76.0, -72.0]
const BUMPER_FACE := 20.13
const AT_BUMPERS := 0.1
const SQUARE := deg_to_rad(1.0)
const LEVELLER := 0.1
const BAYS: Array[float] = [-37.4, -33.6, -29.8]
const BAY := Vector2(2.6, 14.0)
const BAY_BACK := 4.0
const STAFF_BAYS := Rect2(-88.4, 42.4, 5.0, 12.5)
const STAFF_BAY := 2.5
## A car parked nose in reaches over its bay's front line to the kerb.
const KERB_X := -89.0
const KINGPIN_WITHIN := 0.1
const FIFTH_WHEEL := 1.11
const GEAR_UP := 0.2
const EAST_WALL := -40.0
const WALL_WITHIN := 0.5
## The van's way: from the gate east along the fence's side of the yard (the arrows at z 53-55),
## then down to bay 9 and backing onto it.
const VAN_WAY: Array[Rect2] = [Rect2(-74.0, 36.0, 30.0, 19.0), Rect2(-50.5, 20.0, 5.5, 16.0)]
const EXIT_STAIR := Rect2(-91.25, 1.5, 1.25, 3.25)
const CHOCK_NEAR := 1.5

var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _app: Node3D
var _shed: Node3D
var _yard: Node3D


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(120.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-yard-%d-%d.cfg" % [OS.get_process_id(),
		Time.get_ticks_usec()])
	_store(START_SAVE)
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	await process_frame
	await physics_frame
	_shed = _app.get_node("IndustrialLoop").get("transfer_shed") as Node3D
	_yard = _shed.get_node_or_null("YardVehicles") as Node3D if _shed != null else null
	_check(_yard != null and _yard.has_method("placements"),
		"Y0: the yard has its vehicles (YardVehicles) handing out their placements")
	if _yard != null and _yard.has_method("placements"):
		_check_docked()
		_check_bays()
		_check_cars()
		_check_clear()
	_finish()


func _check_docked() -> void:
	var trailers := _placed("DockedTrailers")
	var half: float = _yard.get("TRAILER_HALF")
	var sill: float = _yard.get("TRAILER_SILL")
	var at_dock := trailers.size() == TRAILER_DOCKS.size()
	var level := at_dock
	var gear_down := at_dock
	for index in range(trailers.size()):
		var trailer: Transform3D = trailers[index]
		var rear := trailer.origin.z - half
		at_dock = at_dock and absf(trailer.origin.x - TRAILER_DOCKS[index]) < 0.05 \
			and rear >= BUMPER_FACE - 0.001 and rear - BUMPER_FACE <= AT_BUMPERS \
			and trailer.basis.z.normalized().angle_to(Vector3.BACK) <= SQUARE
		level = level and absf(trailer.origin.y + sill - DOCK_FLOOR) <= LEVELLER
		gear_down = gear_down and absf(trailer.origin.y - GROUND) < 0.005
	_check(at_dock, "Y1: dry vans backed square onto docks 1-3, rears within %.1f m of the "
		% AT_BUMPERS + "bumpers (%d)" % trailers.size())
	_check(level and gear_down, "Y1: their floors within the leveller's 0.1 m of the dock and "
		+ "their landing gear down on the paving")
	var chocks := _placed("Chocks")
	var chocked := chocks.size() >= trailers.size()
	for trailer: Transform3D in trailers:
		var axle := float(_yard.get("REAR_AXLE"))
		var near := false
		for chock: Transform3D in chocks:
			var local := trailer.affine_inverse() * chock.origin
			near = near or (absf(local.z - axle) <= CHOCK_NEAR and absf(local.x) <= 1.3
				and absf(chock.origin.y - GROUND) < 0.01)
		chocked = chocked and near
	_check(chocked, "Y1: a chock at each docked trailer's rear tandem")
	var building := _shed.get_node("Building")
	var red := true
	for index in range(3):
		var signal_node := building.get_node_or_null("DockSignal%d" % (index + 1))
		red = red and signal_node != null and (signal_node.get_node("Red") as MeshInstance3D) \
			.material_override == building.get("_red_on")
	_check(red, "Y2: the docks' outside signals red, a trailer at each shut door")


func _check_bays() -> void:
	var dropped := _placed("BayTrailers")
	var half: float = _yard.get("TRAILER_HALF")
	var width: float = _yard.get("TRAILER_WIDTH")
	_check(dropped.size() == 2 and _in_bay(dropped[0], 0, width, half * 2.0)
		and _in_bay(dropped[1], 1, width, half * 2.0), "Y3: a dropped trailer in the west bay "
		+ "and a coupled one in the middle bay, each inside its lines")
	var tractor := _placed("Tractor")
	var kingpin: Vector3 = _yard.call("kingpin")
	var fifth: Vector3 = _yard.call("fifth_wheel")
	var gear := _yard.call("coupled_gear_lift") as float
	_check(tractor.size() == 1 and Vector2(kingpin.x - fifth.x, kingpin.z - fifth.z).length()
		<= KINGPIN_WITHIN and absf(kingpin.y - fifth.y) <= 0.02 and absf(fifth.y - GROUND
		- FIFTH_WHEEL) <= 0.02 and gear >= GEAR_UP, "Y4: the tractor coupled, its fifth wheel "
		+ "under the kingpin (%.2f m), the trailer's landing gear cranked up %.2f m"
		% [Vector2(kingpin.x - fifth.x, kingpin.z - fifth.z).length(), gear])
	var truck := _placed("BoxTruck")
	var length: float = _yard.get("TRUCK_LENGTH")
	_check(truck.size() == 1 and _in_bay(truck[0], 2, float(_yard.get("TRUCK_WIDTH")), length)
		and (truck[0] as Transform3D).basis.z.normalized().dot(Vector3.BACK) > 0.99,
		"Y5: the box truck inside the east bay's lines, nose out")


func _check_cars() -> void:
	var cars := _yard.call("car_boxes") as Array
	var inside := cars.size() == 2
	for box: Rect2 in cars:
		var bay := floori((box.get_center().y - STAFF_BAYS.position.y) / STAFF_BAY)
		var lines := Rect2(KERB_X + 0.1, STAFF_BAYS.position.y + bay * STAFF_BAY,
			STAFF_BAYS.end.x - KERB_X - 0.1, STAFF_BAY)
		inside = inside and lines.encloses(box)
	_check(inside, "Y6: the sedan and the covered car each inside a staff bay's lines, short of "
		+ "the kerb")
	var nose := _yard.call("sedan_front") as Vector3
	_check(nose.dot(Vector3.LEFT) > 0.99, "Y6: the sedan nose in, toward the kerb")


func _check_clear() -> void:
	var dumpsters := _placed("Dumpsters")
	var box := _yard.call("dumpster_box") as Rect2
	_check(dumpsters.size() == 1 and box.position.x - EAST_WALL >= 0.0
		and box.position.x - EAST_WALL <= WALL_WITHIN, "Y7: the dumpsters against the east wall "
		+ "outside, on the paving")
	var solids := _yard.call("footprints") as Array
	var blocked := []
	for rect: Rect2 in solids:
		for way in VAN_WAY:
			if rect.intersects(way):
				blocked.append(rect)
		if rect.intersects(EXIT_STAIR.grow(1.0)):
			blocked.append(rect)
	_check(blocked.is_empty() and solids.size() >= 9, "Y8: nothing in the van's way from the gate "
		+ "to bay 9 or by the west exit's stair (%d of %d in the way)" % [blocked.size(),
		solids.size()])
	var body := _yard.get_node_or_null("VehicleBodies") as StaticBody3D
	_check(body != null and body.get_child_count() >= solids.size(),
		"Y8: each parked vehicle solid (%d shapes)" % (body.get_child_count() if body else 0))


func _in_bay(placed: Transform3D, bay: int, width: float, length: float) -> bool:
	var lines := Rect2(BAYS[bay] - BAY.x / 2.0, BAY_BACK, BAY.x, BAY.y)
	var half := Vector2(width, length) / 2.0
	return lines.encloses(Rect2(Vector2(placed.origin.x, placed.origin.z) - half, half * 2.0))


func _placed(label: String) -> Array:
	return _yard.call("placements", label)


func _store(text: String) -> void:
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _remove() -> void:
	for suffix in ["", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(_scratch + suffix):
			DirAccess.remove_absolute(_scratch + suffix)


func _timeout() -> void:
	_check(false, "The yard's checks finish within 120 s")
	_finish()


func _finish() -> void:
	print("YARD RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	_remove()
	quit(1 if _failures > 0 else 0)
