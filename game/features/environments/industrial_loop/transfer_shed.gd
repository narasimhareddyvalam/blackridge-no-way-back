extends Node3D
## The transfer shed's way in (docs/PHASE_BRIEF.md, Phase 2 step 2b and its r1): the spur north
## from the valley road, the security fence round the shed's yard, the guard booth on a kerbed
## island beside the driver's window at the stop line, and the boom barrier. The guard is a
## stand-in (decision D6): Rocketbox's seated security officer (C55) and a timed check of the run
## sheet, labelled so, until Assignment 9's technique replaces it. The barrier, like a real one on
## its safety loop, never comes down while a vehicle is under its arm.

signal run_sheet_checked
## The dock worker sent out to seal `van` (the app shows his round, #333).
signal dock_hand_called(van: Node3D)

const Build = preload("res://shared/components/mesh_builder.gd")
const ChainLink = preload("chain_link.gdshader")
const ThinWire = preload("thin_wire.gdshader")
const Retroreflector = preload("retroreflector.gdshader")
const Guard = preload("res://features/characters/guard/guard.glb")
const Booth = preload("guard_booth.gd")
const Yard = preload("transfer_yard.gd")
const Ground = preload("depot_ground.gd")
const Building = preload("transfer_building.gd")
const VanBay = preload("van_bay.gd")
const PalletJack = preload("pallet_jack.gd")
const YardVehicles = preload("yard_vehicles.gd")
const DockWorker = preload("res://features/characters/dock_worker/dock_worker.gd")
## Just inside the side door, where the dock worker stops to push it open (#333).
const WORKER_INSIDE := Vector3(-40.5, 0.0, 17.5)
## Round the shed's east end to bay 9's van along the walkway between the dock face and the wheel
## guides' ends (z 20.0 and 21.0, #342): his body clear of the dock seals' pads (0.46 m out from
## the dock face, from 1.15 m up) and 0.6 m clear of the bollards, past the chock, and in to the
## van west of the east guide's end, turning 1.4 m short of it and coming square into the
## walkway from the van, held to the walkway's line past the guide's end (he rounds corners on
## their inside); not through the 0.5 m that had been there, where his body
## went into bay 9's seal and bumpers (#338).
const WORKER_WAY: Array[Vector3] = [Vector3(-39.1, 0.0, 17.5), Vector3(-39.1, 0.0, 20.95),
	Vector3(-41.5, 0.0, 20.95), Vector3(-46.0, 0.0, 20.75), Vector3(-47.9, 0.0, 20.75),
	Vector3(-47.9, 0.0, 21.4)]
## From beside his chair round behind it, between bay 9's staged load and the edge rail, to the
## dock stair's landing (step 3 of #253); and from the landing down the stair to the side door.
## Past bay 9's staged load 0.47 m clear of it, wide of it as he rounds the corner (#333).
const WORKER_DESK_WAY: Array[Vector3] = [Vector3(-46.75, 1.3, 19.25), Vector3(-46.75, 1.3, 17.9),
	Vector3(-46.2, 1.3, 17.3), Vector3(-46.2, 1.3, 15.6), Vector3(-45.3, 1.3, 12.4)]
## Down the flight 0.35 m from its rail, within his reach of it (the audit's fourth fix, #329).
const WORKER_STAIR_WAY: Array[Vector3] = [Vector3(-44.0, 1.3, 12.4), Vector3(-44.0, 1.3, 12.92),
	Vector3(-44.0, 0.0, 15.4), Vector3(-44.0, 0.0, 16.4)]
const LANE_X := -71.0
const LANE_WIDTH := 6.0
const GATE_Z := 55.0
const STOP_LINE_OUT := 2.5
const WINDOW_REACH := 0.4
const CORNER_RADIUS := 6.0
const COLUMN_STEP := 0.5
const SURFACE_HEIGHT := 0.02
const FENCE_HEIGHT := 2.4
const POST_SPACING := 3.0
const BARB_ARM := 0.45
const ARM_LENGTH := 6.4
const ARM_PIVOT_HEIGHT := 0.9
const RAISE_SECONDS := 4.0
const CHECK_SECONDS := 3.0
const BOOTH := Booth.SIZE
const BOOTH_FACE_X := LANE_X - 2.0
const BOOTH_Z := GATE_Z + STOP_LINE_OUT + 1.9
const WIRE_GLINT := 0.12
const ISLAND_HEIGHT := 0.15
const KERB_OUT := 0.25
const ISLAND_NOSE := 1.0
const BOLLARD_RADIUS := 0.075
const BOLLARD_HEIGHT := 1.07
const STOPPED_SPEED := 0.5
const CLEAR_BEHIND := 1.0
## The free-exit loop in the lane 1.5 m inside the barrier's line (the audit's first fix, #322):
## a vehicle over it (any part) facing out within 45 degrees raises the arm, which comes down once the whole
## vehicle is 1 m beyond the line.
const EXIT_LOOP := Rect2(LANE_X - LANE_WIDTH / 2.0, GATE_Z - 5.0, LANE_WIDTH, 3.5)
const FACING_OUT := 0.7071
const SWEEP_HALF_DEPTH := 0.3
const SPUR_PLOT := Rect2(LANE_X - LANE_WIDTH / 2.0 - CORNER_RADIUS - 1.0, GATE_Z,
	LANE_WIDTH + CORNER_RADIUS * 2.0 + 2.0, 20.0)

var lamp_at := Vector3(LANE_X + LANE_WIDTH / 2.0 + 1.6, 0.0, GATE_Z + 3.0)
var dock_rain_at := Vector3(-61.45, 4.6, 22.25)
var bay_nine: Node
var side_door: Node
var pallet_jack: Node
var forklift: Node3D
var _scanned: Array[Node3D] = []
var dock_worker: Node3D

var _jack_start := Transform3D()
var clearings: Array[Rect2] = [SPUR_PLOT, Ground.CLEARING]
var yard_lamps: Array[Vector3] = Yard.LAMPS
var yard_lamp_headings: Array[float] = Yard.LAMP_HEADINGS
var vehicle: Node3D
var driver_eye: Node3D

var _angle: float = 0.0
var _target: float = 0.0
var _check_left: float = -1.0
var _lowered_window := false
var _exiting := false
var _arm: AnimatableBody3D
var _vehicle_front := Vector3.ZERO
var _vehicle_rear := Vector3.ZERO
var _fence_body: StaticBody3D
var _booth_node: Node3D
var _window_open := false
var _screen: Node3D
var _logbook: Node3D
var _paint := Build.material(Color("d8d5cb"), 0.55)
var _galvanized := _galvanized_steel()
var _thin_wire := _wire_material()


static func road_opening() -> Vector3:
	return Vector3(LANE_X, GATE_Z + 16.0, LANE_WIDTH / 2.0 + CORNER_RADIUS + 1.5)


static func flat_plots() -> Array[Rect2]:
	return [Ground.FLAT, SPUR_PLOT]


static func _galvanized_steel() -> StandardMaterial3D:
	var steel := Build.material(Color(0.6, 0.62, 0.62), 0.5)
	steel.metallic = 0.5
	return steel


static func _wire_material() -> ShaderMaterial:
	var wire := ShaderMaterial.new()
	wire.shader = ThinWire
	return wire


func build(road: RefCounted, _building_width: float, surface: Material, concrete: Material,
		metal: Material, wall: Material, terrain: Node3D) -> void:
	_spur(road, surface)
	var ground := Ground.new()
	ground.name = "Ground"
	add_child(ground)
	ground.build(terrain, concrete)
	var building := Building.new()
	building.name = "Building"
	add_child(building)
	building.build(metal)
	var yard := Yard.new()
	yard.name = "Yard"
	add_child(yard)
	yard.build(surface)
	var vehicles := YardVehicles.new()
	vehicles.name = "YardVehicles"
	add_child(vehicles)
	vehicles.build()
	bay_nine = VanBay.new()
	bay_nine.name = "BayNine"
	add_child(bay_nine)
	bay_nine.call("setup", building, yard.get_node("WheelChock"), building.get_node("DockLift9"))
	side_door = building.get_node("DockAccess")
	forklift = building.get_node("Forklift") as Node3D
	pallet_jack = PalletJack.new()
	pallet_jack.name = "PalletJackRig"
	add_child(pallet_jack)
	var loads: Array[Node3D] = []
	for index in range(1, 7):
		loads.append(building.get_node("Pallet%d" % index) as Node3D)
	var jack := building.get_node("PalletJack") as Node3D
	_jack_start = jack.global_transform
	pallet_jack.call("setup", jack, loads, building, building.get_node("DockLift9"))
	dock_worker = DockWorker.new()
	dock_worker.name = "DockWorker"
	add_child(dock_worker)
	dock_worker.set("lift", building.get_node("DockLift9"))
	dock_worker.call("setup", WORKER_INSIDE, WORKER_WAY, building.get_node("DockStation"),
		WORKER_DESK_WAY, WORKER_STAIR_WAY)
	dock_worker.call("use_stair", side_door.call("stair"), side_door.call("rail_top"))
	dock_worker.set("room_behind", Callable(bay_nine, "clearance"))
	dock_worker.set("side_door", side_door)
	_markings()
	_fence_body = StaticBody3D.new()
	_fence_body.name = "Fence"
	add_child(_fence_body)
	var west := Ground.PLATFORM.position.x
	var east := Ground.PLATFORM.end.x
	var cabinet_west := LANE_X - LANE_WIDTH / 2.0 - 0.3 - 0.16
	var rest_x := LANE_X - LANE_WIDTH / 2.0 - 0.3 + ARM_LENGTH + 0.3
	_fence(Vector3(west, 0.0, GATE_Z), Vector3(cabinet_west, 0.0, GATE_Z), Vector3.BACK)
	_fence(Vector3(rest_x + 0.3, 0.0, GATE_Z), Vector3(east, 0.0, GATE_Z), Vector3.BACK)
	var reach := Vector2(Ground.PLATFORM.position.y, Ground.PLATFORM.position.y)
	for run in ground.top_runs():
		_fence(run["from"], run["to"], run["outward"])
		var outward: Vector3 = run["outward"]
		var end_z: float = (run["to"] as Vector3).z
		if outward.x < 0.0:
			reach.x = maxf(reach.x, end_z)
		elif outward.x > 0.0:
			reach.y = maxf(reach.y, end_z)
	_fence(Vector3(west, 0.0, GATE_Z), Vector3(west, 0.0, reach.x), Vector3.LEFT)
	_fence(Vector3(east, 0.0, GATE_Z), Vector3(east, 0.0, reach.y), Vector3.RIGHT)
	for at in Yard.LAMPS:
		var footing := CylinderShape3D.new()
		footing.radius = 0.25
		footing.height = 3.0
		var collision := CollisionShape3D.new()
		collision.shape = footing
		collision.position = at + Vector3.UP * 1.5
		_fence_body.add_child(collision)
	_island(concrete)
	_booth(concrete, metal, wall)
	_barrier(metal, rest_x)


func watch(body: Node3D) -> void:
	vehicle = body
	if bay_nine != null:
		bay_nine.set("vehicle", body)
	if pallet_jack != null:
		pallet_jack.call("watch", body)
	_vehicle_front = Vector3.ZERO
	_vehicle_rear = Vector3.ZERO
	for child in body.get_children():
		if child is CollisionShape3D and (child as CollisionShape3D).shape is BoxShape3D:
			var shape := child as CollisionShape3D
			var half := ((shape.shape as BoxShape3D).size * 0.5)
			_vehicle_front = shape.position + Vector3(0.0, 0.0, -half.z)
			_vehicle_rear = shape.position + Vector3(0.0, 0.0, half.z)
			return


## Bay 9's staged load, the one under the pallet jack, put in `van`'s hold strapped down.
func stow_load(van: Node3D) -> void:
	pallet_jack.call("stow", get_node("Building/Pallet6"))


## As a reload at Mission 2's stage 1 finds it: loaded, the doors shut and sealed (H6).
func restore_loaded(van: Node3D, seal_number: String) -> void:
	stow_load(van)
	van.set("rear_doors_open", false)
	van.call("put_seal", seal_number)


## Sends the dock worker out to seal `van`'s shut rear doors with the seal numbered `number`.
func call_dock_hand(van: Node3D, number: String) -> void:
	if String(dock_worker.get("state")) != "seated":
		return
	dock_worker.call("go_seal", van, number)
	dock_hand_called.emit(van)


func barrier_open() -> bool:
	return _angle >= 89.0


func barrier_angle() -> float:
	return _angle


func checking() -> bool:
	return _check_left >= 0.0


func at_stop(front: Vector3) -> bool:
	return front.z > GATE_Z - SWEEP_HALF_DEPTH and front.z < GATE_Z + STOP_LINE_OUT + 6.0 \
		and absf(front.x - LANE_X) < LANE_WIDTH / 2.0 + 1.0


func vehicle_at_stop() -> bool:
	return is_instance_valid(vehicle) and at_stop(vehicle.to_global(_vehicle_front))


## Whether the arm is on its way up after the guard's check (#348).
func barrier_rising() -> bool:
	return _target > 0.0 and _angle < 89.0


## Whether the van's driver is level with the booth's service opening, within WINDOW_REACH along
## the lane: only then can the guard take the run sheet from his hand (#348).
func vehicle_at_window() -> bool:
	return vehicle_at_stop() and absf(window_gap()) <= WINDOW_REACH


## How far the driver's eye is from the booth's opening along the lane (positive: he has yet to
## reach it, the van driving toward smaller z; negative: he is past it).
func window_gap() -> float:
	if not is_instance_valid(driver_eye) or _booth_node == null:
		return INF
	return driver_eye.global_position.z - (_booth_node.call("opening_centre") as Vector3).z


func vehicle_near() -> bool:
	if not is_instance_valid(vehicle):
		return false
	var front := vehicle.to_global(_vehicle_front)
	return front.z > GATE_Z - SWEEP_HALF_DEPTH and front.z < GATE_Z + 25.0 \
		and absf(front.x - LANE_X) < LANE_WIDTH / 2.0 + CORNER_RADIUS


func vehicle_through() -> bool:
	if not is_instance_valid(vehicle):
		return false
	return maxf(vehicle.to_global(_vehicle_front).z, vehicle.to_global(_vehicle_rear).z) \
		< GATE_Z - SWEEP_HALF_DEPTH and absf(vehicle.global_position.x - LANE_X) < 30.0


func hand_run_sheet() -> bool:
	if checking() or _target > 0.0:
		return false
	_check_left = CHECK_SECONDS
	if is_instance_valid(vehicle) and float(vehicle.get("left_window_target")) < 0.5:
		vehicle.set("left_window_target", 1.0)
		_lowered_window = true
	return true


## Bay 9's dock worker sent to scan each pallet as it is first set down on the lift (#302).
func _send_to_scan() -> void:
	if pallet_jack == null or dock_worker == null:
		return
	var load := pallet_jack.call("on_lift") as Node3D
	if load != null and not _scanned.has(load) and dock_worker.get("state") == "seated":
		_scanned.append(load)
		dock_worker.call("go_scan", load)


func reset() -> void:
	_scanned.clear()
	if bay_nine != null:
		bay_nine.call("reset")
	if side_door != null:
		side_door.call("reset")
	if pallet_jack != null:
		pallet_jack.call("reset", _jack_start)
	if dock_worker != null:
		dock_worker.call("reset")
		dock_worker.call("forget_log")
	_check_left = -1.0
	_target = 0.0
	_angle = 0.0
	_lowered_window = false
	_exiting = false
	if _arm != null:
		_arm.rotation.z = 0.0


func _physics_process(delta: float) -> void:
	_send_to_scan()
	if _check_left >= 0.0:
		_check_left -= delta
		if _check_left < 0.0:
			_check_left = -1.0
			_target = 90.0
			run_sheet_checked.emit()
	if is_instance_valid(vehicle):
		var front := vehicle.to_global(_vehicle_front)
		var rear := vehicle.to_global(_vehicle_rear)
		var in_lane := absf(vehicle.global_position.x - LANE_X) < ARM_LENGTH
		var under := in_lane and minf(front.z, rear.z) < GATE_Z + SWEEP_HALF_DEPTH \
			and maxf(front.z, rear.z) > GATE_Z - SWEEP_HALF_DEPTH
		if _target == 0.0 and _on_exit_loop(front):
			_target = 90.0
			_exiting = true
		if under and _target == 0.0 and _angle > 0.0:
			_target = 90.0
		elif _exiting and _target == 90.0 and _angle >= 90.0 and not under \
				and (minf(front.z, rear.z) > GATE_Z + CLEAR_BEHIND
				or maxf(front.z, rear.z) < EXIT_LOOP.position.y - 2.0):
			_target = 0.0
			_exiting = false
		elif not _exiting and _target == 90.0 and _angle >= 90.0 and not under \
				and maxf(front.z, rear.z) < GATE_Z - CLEAR_BEHIND:
			_target = 0.0
	_angle = move_toward(_angle, _target, 90.0 / RAISE_SECONDS * delta)
	if _arm != null:
		_arm.rotation.z = deg_to_rad(_angle)
	if _lowered_window and _angle >= 89.0:
		_lowered_window = false
		if is_instance_valid(vehicle):
			vehicle.set("left_window_target", 0.0)
	if _booth_node != null:
		_booth_node.set("driver", driver_eye)
		_booth_node.call("look_at_point", _gaze())
		if checking() != _window_open:
			_window_open = checking()
			_booth_node.call("open_window", _window_open)


## Whether any of the van stands over the free-exit loop (a loop senses the metal over it, along
## the van from its front to its rear), facing out of the yard.
func _on_exit_loop(front: Vector3) -> bool:
	var rear := vehicle.to_global(_vehicle_rear)
	var over := false
	for step in range(9):
		var at := front.lerp(rear, step / 8.0)
		over = over or EXIT_LOOP.has_point(Vector2(at.x, at.z))
	return over and (-vehicle.global_basis.z.normalized()).z > FACING_OUT


func _gaze() -> Vector3:
	if checking():
		return _logbook.global_position
	if _target == 0.0 and is_instance_valid(driver_eye) and vehicle_at_stop() \
			and absf(float(vehicle.get("actual_speed"))) < STOPPED_SPEED:
		return driver_eye.global_position
	return _screen.global_position


func _road_edge_z(road: RefCounted, x: float) -> float:
	var points: PackedVector3Array = road.points
	var count := points.size()
	var best := INF
	var edge := PackedVector3Array()
	for index in range(count):
		var at := points[index]
		if absf(at.x - x) > 30.0 or absf(at.z - GATE_Z) > 40.0:
			edge.append(Vector3.INF)
			continue
		var along := points[(index + 1) % count] - points[(index - 1 + count) % count]
		var side := Vector3(along.x, 0.0, along.z).normalized().cross(Vector3.UP)
		var reach: Vector3 = side * float(road.half_widths[index])
		edge.append(at - reach if (at - reach).z < (at + reach).z else at + reach)
	for index in range(edge.size() - 1):
		var a := edge[index]
		var b := edge[index + 1]
		if not a.is_finite() or not b.is_finite() or is_equal_approx(a.x, b.x):
			continue
		if (a.x - x) * (b.x - x) > 0.0:
			continue
		var z := lerpf(a.z, b.z, (x - a.x) / (b.x - a.x))
		if z > GATE_Z and z < best:
			best = z
	return best


func _spur(road: RefCounted, surface: Material) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := LANE_WIDTH / 2.0
	var groups: Array[Array] = [
		[LANE_X - half - CORNER_RADIUS, LANE_X - half, -1.0],
		[LANE_X - half, LANE_X + half, 0.0],
		[LANE_X + half, LANE_X + half + CORNER_RADIUS, 1.0],
	]
	var first := 0
	for group in groups:
		var columns := int(round((float(group[1]) - float(group[0])) / COLUMN_STEP))
		for step in range(columns + 1):
			var x := float(group[0]) + step * COLUMN_STEP
			var edge := _road_edge_z(road, x)
			var north := GATE_Z
			if float(group[2]) != 0.0:
				var out := absf(x - LANE_X) - half
				var inner := CORNER_RADIUS - out
				north = edge - (CORNER_RADIUS - sqrt(maxf(CORNER_RADIUS * CORNER_RADIUS
					- inner * inner, 0.0)))
			for corner: Vector3 in [Vector3(x, 0.002, edge), Vector3(x, SURFACE_HEIGHT,
					minf(edge - 0.6, maxf(north, edge - 0.6))), Vector3(x, SURFACE_HEIGHT, north)]:
				tool.set_normal(Vector3.UP)
				tool.set_uv(Vector2(corner.x, corner.z))
				tool.add_vertex(corner)
		for step in range(columns):
			for row in range(2):
				var top := first + step * 3 + row
				var next := top + 3
				for index: int in [top, top + 1, next, top + 1, next + 1, next]:
					tool.add_index(index)
		first += (columns + 1) * 3
	tool.generate_tangents()
	var ground := Build.instance(self, Vector3.ZERO, tool.commit(), surface)
	ground.name = "Spur"
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _markings() -> void:
	var line_z := GATE_Z + STOP_LINE_OUT
	Build.box(self, Vector3(LANE_X, SURFACE_HEIGHT + 0.004, line_z),
		Vector3(LANE_WIDTH - 0.4, 0.008, 0.3), _paint).name = "StopLine"
	var word := Build.text(self, "STOP", Vector3(LANE_X, SURFACE_HEIGHT + 0.006, line_z + 2.2),
		400, Color("d8d5cb"))
	word.name = "StopWord"
	word.rotation.x = -PI / 2.0
	word.shaded = true
	word.double_sided = false
	word.pixel_size = 0.004


func _fence(from: Vector3, to: Vector3, outward: Vector3) -> void:
	var length := from.distance_to(to)
	if length < 0.3:
		return
	var along := (to - from) / length
	var bays := maxi(ceili(length / POST_SPACING), 1)
	var link := ShaderMaterial.new()
	link.shader = ChainLink
	link.set_shader_parameter("zinc_reflectance", WIRE_GLINT)
	var lean := (outward + Vector3.UP).normalized()
	var lean_basis := Basis(along, lean, along.cross(lean))
	for bay in range(bays + 1):
		var at := from + along * (length * bay / bays)
		Build.cylinder(self, at + Vector3.UP * (FENCE_HEIGHT + 0.05) / 2.0, 0.03,
			FENCE_HEIGHT + 0.05, _galvanized)
		var arm := Build.box(self, at + Vector3.UP * FENCE_HEIGHT + lean * BARB_ARM / 2.0,
			Vector3(0.03, BARB_ARM, 0.03), _galvanized)
		arm.basis = lean_basis
	var middle := (from + to) / 2.0
	var basis := Basis(along, Vector3.UP, along.cross(Vector3.UP))
	var rail := Build.box(self, middle + Vector3.UP * FENCE_HEIGHT, Vector3(length, 0.042, 0.042),
		_galvanized)
	rail.basis = basis
	var bottom := Build.box(self, middle + Vector3.UP * 0.08, Vector3(length, 0.006, 0.006),
		_thin_wire)
	bottom.basis = basis
	bottom.name = "BottomWire"
	bottom.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var quad := QuadMesh.new()
	quad.size = Vector2(length, FENCE_HEIGHT - 0.08)
	var panel := Build.instance(self, middle + Vector3.UP * (FENCE_HEIGHT / 2.0 + 0.02), quad,
		link)
	panel.basis = basis
	panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for strand in range(1, 4):
		var lift := BARB_ARM * strand / 3.0 * 0.7071
		var strand_at := middle + Vector3.UP * (FENCE_HEIGHT + lift) + outward * lift
		var wire := Build.box(self, strand_at, Vector3(length, 0.006, 0.006), _thin_wire)
		wire.basis = basis
		wire.name = "BarbStrand"
		wire.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shape := BoxShape3D.new()
	shape.size = Vector3(length, FENCE_HEIGHT + 0.4, 0.12)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.transform = Transform3D(basis, middle + Vector3.UP * (FENCE_HEIGHT + 0.4) / 2.0)
	_fence_body.add_child(collision)


func _island(concrete: Material) -> void:
	var west := BOOTH_FACE_X - BOOTH.x - KERB_OUT
	var east := BOOTH_FACE_X + KERB_OUT
	var north := GATE_Z - 0.4
	var south := BOOTH_Z + BOOTH.z / 2.0 + ISLAND_NOSE
	var middle := Vector3((west + east) / 2.0, ISLAND_HEIGHT / 2.0, (north + south) / 2.0)
	Build.box(self, middle, Vector3(east - west, ISLAND_HEIGHT, south - north), concrete, true) \
		.name = "Island"
	var safety := Build.material(Color(0.86, 0.66, 0.08), 0.55)
	Build.box(self, Vector3(east + 0.006, ISLAND_HEIGHT / 2.0, middle.z),
		Vector3(0.012, ISLAND_HEIGHT, south - north), safety).name = "Kerb"
	Build.box(self, Vector3(middle.x, ISLAND_HEIGHT / 2.0, south + 0.006),
		Vector3(east - west, ISLAND_HEIGHT, 0.012), safety).name = "KerbNose"
	var band := ShaderMaterial.new()
	band.shader = Retroreflector
	band.set_shader_parameter("sheeting", Vector3(0.88, 0.88, 0.86))
	band.set_shader_parameter("stripe_colour", Vector3(0.88, 0.88, 0.86))
	for at_z: float in [BOOTH_Z - BOOTH.z / 2.0 - 0.12, BOOTH_Z + BOOTH.z / 2.0 + 0.12,
			south - 0.25]:
		var at := Vector3(east - 0.1, ISLAND_HEIGHT, at_z)
		var bollard := Build.cylinder(self, at + Vector3.UP * BOLLARD_HEIGHT / 2.0,
			BOLLARD_RADIUS, BOLLARD_HEIGHT, safety)
		bollard.name = "Bollard"
		bollard.create_trimesh_collision()
		Build.cylinder(self, at + Vector3.UP * (BOLLARD_HEIGHT - 0.18), BOLLARD_RADIUS + 0.002,
			0.08, band).name = "ReflectiveBand"


func _booth(concrete: Material, metal: Material, wall: Material) -> void:
	_booth_node = Booth.new()
	_booth_node.name = "GuardBooth"
	_booth_node.position = Vector3(BOOTH_FACE_X - BOOTH.x / 2.0, ISLAND_HEIGHT, BOOTH_Z)
	add_child(_booth_node)
	_booth_node.call("build", concrete, metal, wall, Guard, "GuardStandIn",
		"STOP  -  REPORT TO GATEHOUSE")
	_screen = _booth_node.get("screen") as Node3D
	_logbook = _booth_node.get("logbook") as Node3D


func _barrier(metal: Material, rest_x: float) -> void:
	var post_x := LANE_X - LANE_WIDTH / 2.0 - 0.3
	var cabinet := Build.material(Color("d6d3ca"), 0.45)
	Build.box(self, Vector3(post_x, 0.5, GATE_Z), Vector3(0.32, 1.0, 0.32), cabinet, true) \
		.name = "BarrierCabinet"
	Build.cylinder(self, Vector3(rest_x, 0.42, GATE_Z), 0.04, 0.84, metal).name = "ArmRest"
	_arm = AnimatableBody3D.new()
	_arm.name = "BarrierArm"
	_arm.sync_to_physics = true
	_arm.position = Vector3(post_x + 0.16, ARM_PIVOT_HEIGHT, GATE_Z)
	add_child(_arm)
	var bands := ShaderMaterial.new()
	bands.shader = Retroreflector
	bands.set_shader_parameter("sheeting", Vector3(0.88, 0.88, 0.86))
	bands.set_shader_parameter("stripe_colour", Vector3(0.62, 0.04, 0.03))
	bands.set_shader_parameter("stripe_slope", 100.0)
	bands.set_shader_parameter("stripe_width", 0.8 * 100.0 / (2.0 * sqrt(2.0)))
	var size := Vector3(ARM_LENGTH, 0.1, 0.06)
	Build.box(_arm, Vector3(ARM_LENGTH / 2.0, 0, 0), size, bands)
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = Vector3(ARM_LENGTH / 2.0, 0, 0)
	_arm.add_child(collision)
