extends Node3D
## The warehouse compound (Mission 2's step 5, docs/PHASE_BRIEF.md; the author's choices,
## #314-#315), round the two warehouses at (150, 112) and (250, 120): its paving; a 2.4 m
## chain-link fence with barbed wire (`chain_link_fence.gd`) round x 128-274, z 92-146, stepped
## in to z 130 west of x 138 to keep 2 m clear of the container yard; a driveway from the valley
## road at x 200 to a cantilever gate in the north fence, shut at night; before it, on the
## driver's side on a kerbed island with bollards, the guard booth (`guard_booth.gd`) with its
## guard seated, a stand-in (D6), and the stop line. At the line E hands her the run sheet (his
## window down); she checks it for 3 s, says the door, and the gate slides open; it shuts once
## the van is 2 m inside, and his window goes up once it is open.

signal run_sheet_checked

const Build = preload("res://shared/components/mesh_builder.gd")
const Fence = preload("chain_link_fence.gd")
const SlidingGate = preload("sliding_gate.gd")
const LED_FLOOD := preload("res://features/environments/industrial_loop/art/gates/led_flood/led_flood.glb")
const Booth = preload("guard_booth.gd")
const Warehouse = preload("warehouse.gd")
const DockJudge = preload("dock_judge.gd")
const TRAILER := preload("res://features/environments/industrial_loop/art/depot/trailer_dryvan.glb")
const FORKLIFT := preload("res://features/environments/industrial_loop/art/depot/forklift.glb")
const DUMPSTERS := preload("res://features/environments/industrial_loop/art/depot/dumpsters.glb")
const PALLET := preload("res://features/environments/industrial_loop/art/depot/pallet.glb")
const Guard = preload("res://features/characters/compound_guard/compound_guard.glb")
const MOTOR := preload("res://features/audio/shed/forklift_pump.wav")
const GROUND := 0.0
const PAVING_TOP := 0.02
## The fence's outline on the ground (x, z), clockwise from the step's north-east corner.
const OUTLINE: Array[Vector2] = [Vector2(138.0, 146.0), Vector2(274.0, 146.0),
	Vector2(274.0, 92.0), Vector2(128.0, 92.0), Vector2(128.0, 130.0), Vector2(138.0, 130.0)]
const OUTWARD: Array[Vector3] = [Vector3.BACK, Vector3.RIGHT, Vector3.FORWARD, Vector3.LEFT,
	Vector3.BACK, Vector3.LEFT]
const PAVED: Array[Rect2] = [Rect2(138.0, 92.0, 136.0, 54.0), Rect2(128.0, 92.0, 10.0, 38.0)]
const GATE_X := 200.0
const GATE_WIDE := 6.0
const GATE_Z := 146.0
const TAIL := 3.0
const GATE_SPEED := 0.6
const CLEAR_BEHIND := 2.0
const DRIVEWAY := Rect2(194.5, 146.0, 8.5, 23.5)
const STOP_LINE_OUT := 2.5
const WINDOW_REACH := 0.4
const SWEEP_HALF_DEPTH := 0.3
const CHECK_SECONDS := 3.0
const STOPPED_SPEED := 0.5
const ISLAND := Rect2(195.05, 149.05, 3.4, 2.7)
const ISLAND_HEIGHT := 0.15
const BOLLARD_RADIUS := 0.075
const BOLLARD_HEIGHT := 1.07
## The booth's service window 2 m from the lane's middle, as the shed's.
const BOOTH_FACE_X := GATE_X - 2.0
const BOOTH_Z := GATE_Z + STOP_LINE_OUT + 1.9
## The door the guard sends the van to (a draft for the author, S1/S3).
const DOOR := 3
## The warehouses' docks and man doors (part B): six docks on the west one, seven on the east,
## 4 m apart; each man door near its west corner, its stair down toward the docks.
const WAREHOUSE_NAMES: Array[String] = ["WarehouseWest", "WarehouseEast"]
const DOCK_XS: Array[Array] = [[141.0, 145.0, 149.0, 153.0, 157.0, 161.0],
	[240.0, 244.0, 248.0, 252.0, 256.0, 260.0, 264.0]]
const MAN_DOOR_XS: Array[float] = [135.6, 234.6]
## Part C: the east warehouse's door 3 open; the yard dressed, all of it clear of the van's way
## from the gate to door 3.
const OPEN_DOCK := DOOR - 1
const TRAILER_HALF := 6.875
const TRAILER_WIDTH := 2.41
const DOCK_GAP := 0.02
const TRAILER_DOCKS: Array[int] = [1, 3]
const REAR_AXLE := -4.9
const CHOCK := Vector3(0.25, 0.2, 0.3)
const CHOCK_OUT := 1.0
const CHOCK_AHEAD := 1.25
const POLES: Array[Vector3] = [Vector3(172.0, 0.0, 145.4), Vector3(222.0, 0.0, 145.4),
	Vector3(268.0, 0.0, 145.4)]
const POLE_TALL := 9.0
const FLOOD := Color(0.96, 0.97, 1.0)
## The gate's flood pole (the audit, #353, after Commons photos of gates at night; the author's
## choice of The Street Light Man's LED flood, `art/gates/led_flood/`): on the verge east of the
## driveway, outside the fence, a crossarm on its top and two floods standing on it on their
## yokes, one on the approach, the stop line and the booth's window, one on the gate's leaf;
## white as the yard's. The model's yoke base is YOKE_DROP below its pivot, its head turning
## there, its lens facing -z, its LEDs' middle LENS_AT from the pivot.
const GATE_POLE := Vector3(204.6, 0.0, 147.4)
const GATE_POLE_TALL := 7.0
const CROSSARM := Vector3(0.08, 0.08, 1.1)
const FLOOD_APART := 0.38
const YOKE_DROP := 0.291
const LENS_AT := Vector3(0.0, 0.13, -0.06)
const GATE_AIMS: Array[Vector3] = [Vector3(199.0, 0.0, 151.5), Vector3(200.0, 0.0, 144.5)]
const GATE_FLOOD_ENERGY := 4.0
const GATE_FLOOD_ANGLE := 50.0
const GATE_FLOOD_RANGE := 20.0
## Where rain shows in the compound's lights, on the ground (the world raises each to its
## floodlight rain's height): over the gate's stop line and opening, and 7.4 m out in front of each
## yard flood, between the fence and the warehouses.
const GATE_RAIN := Vector3(200.0, 0.0, 148.0)
const YARD_RAIN_OUT := 7.4
const PALLET_STACKS: Array[Vector3] = [Vector3(168.2, 0.0, 110.0), Vector3(168.2, 0.0, 113.0)]
const PALLET_HIGH := 14
const PALLET_SIZE := Vector3(1.0, 0.144, 1.2)
const FORKLIFT_AT := Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(229.0, 0.0, 124.0))
const FORKLIFT_BOX := Vector3(1.1, 2.2, 3.0)
const DUMPSTERS_AT := Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(150.0, 0.0, 97.0))
const DUMPSTER_BOX := Vector3(1.75, 1.54, 4.36)

var vehicle: CharacterBody3D
var driver_eye: Node3D
var booth: Node3D
var _window_open := false
var judge: Node

var _fence_runs: Array = []
## Each place rain shows in the compound's lights (see GATE_RAIN), for the world's lamp rain.
var rain_places: Array[Transform3D] = []
var _flood_glass: StandardMaterial3D
var _flood_board: StandardMaterial3D
var _footprints: Array[Rect2] = []
var _body: StaticBody3D
var _gate: AnimatableBody3D
var _sliding: Node3D
var _motor: AudioStreamPlayer3D
var _gate_open := 0.0
var _gate_target := 0.0
var _check_left := -1.0
var _window_down := false
var _front := Vector3(0.0, 0.0, -2.5)
var _rear := Vector3(0.0, 0.0, 3.0)


func build(surface: Material, concrete: Material, metal: Material, wall: Material) -> void:
	_body = StaticBody3D.new()
	_body.name = "CompoundBody"
	add_child(_body)
	_paving(surface)
	_boundary()
	_gate_leaf()
	_island(concrete)
	booth = Booth.new()
	booth.name = "GuardBooth"
	add_child(booth)
	booth.position = Vector3(BOOTH_FACE_X - Booth.SIZE.x / 2.0, GROUND + PAVING_TOP
		+ ISLAND_HEIGHT, BOOTH_Z)
	booth.call("build", concrete, metal, wall, Guard, "CompoundGuardStandIn",
		"ALL VEHICLES STOP")
	var white := Build.material(Color(0.92, 0.92, 0.9), 0.6)
	Build.box(self, Vector3(GATE_X, PAVING_TOP + 0.003, GATE_Z + STOP_LINE_OUT),
		Vector3(GATE_WIDE - 0.4, 0.004, 0.3), white).name = "StopLine"
	_gate_flood(metal)


## The gate's flood pole: a galvanised pole on its footing and its cap, the crossarm on top and
## the two floods on it; solid; its rain over the stop line and the opening.
func _gate_flood(metal: Material) -> void:
	var steel := metal.duplicate() as Material
	var at := GATE_POLE
	var pole := Build.cylinder(self, at + Vector3.UP * GATE_POLE_TALL / 2.0, 0.085, GATE_POLE_TALL,
		steel, 0.06)
	pole.name = "GateFloodPole"
	Build.cylinder(pole, Vector3.DOWN * (GATE_POLE_TALL / 2.0 - 0.1), 0.2, 0.2,
		Build.material(Color(0.5, 0.5, 0.48), 0.9)).name = "Footing"
	Build.box(pole, Vector3(0.0, GATE_POLE_TALL / 2.0 + CROSSARM.y / 2.0, 0.0), CROSSARM, steel) \
		.name = "Crossarm"
	_solid_box(at + Vector3.UP * 1.0, Vector3(0.3, 2.0, 0.3))
	_footprints.append(Rect2(at.x - 0.2, at.z - 0.2, 0.4, 0.4))
	for index in range(GATE_AIMS.size()):
		var pivot := at + Vector3(0.0, GATE_POLE_TALL + CROSSARM.y + YOKE_DROP, (index - 0.5) * 2.0
			* FLOOD_APART)
		_led_flood("GateFloodHead%d" % (index + 1), pivot, GATE_AIMS[index])
	rain_places.append(Transform3D(Basis.IDENTITY, GATE_RAIN))


## One LED flood, `label`, its pivot at `pivot`: its yoke turned toward `target` and its head
## tilted on the yoke to aim at it; its LEDs lit and its light at them.
func _led_flood(label: String, pivot: Vector3, target: Vector3) -> void:
	if _flood_glass == null:
		_flood_glass = StandardMaterial3D.new()
		_flood_glass.albedo_color = Color(0.9, 0.95, 1.0, 0.12)
		_flood_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_flood_glass.roughness = 0.05
		_flood_board = Build.material(Color(0.8, 0.8, 0.8), 0.5)
		_flood_board.emission_enabled = true
		_flood_board.emission = FLOOD
		_flood_board.emission_energy_multiplier = 0.15
	var holder := Node3D.new()
	holder.name = label
	add_child(holder)
	holder.global_position = pivot
	holder.look_at(Vector3(target.x, pivot.y, target.z), Vector3.UP)
	var model := LED_FLOOD.instantiate() as Node3D
	model.name = "LedFlood"
	holder.add_child(model)
	var head := model.find_child("Head", true, false) as Node3D
	head.look_at(target, Vector3.UP)
	var face := head as MeshInstance3D if head is MeshInstance3D else head.find_child("*", true,
		false) as MeshInstance3D
	for surface in range(face.mesh.get_surface_count()):
		var named := face.mesh.surface_get_material(surface).resource_name
		if named.begins_with("phosphorus"):
			face.set_surface_override_material(surface, Build.luminous(FLOOD, 6.0))
		elif named == "tempered_glass":
			face.set_surface_override_material(surface, _flood_glass)
		elif named == "led_base":
			face.set_surface_override_material(surface, _flood_board)
	var light := SpotLight3D.new()
	light.name = "FloodLight"
	head.add_child(light)
	light.position = LENS_AT
	light.light_color = FLOOD
	light.light_energy = GATE_FLOOD_ENERGY
	light.spot_angle = GATE_FLOOD_ANGLE
	light.spot_range = GATE_FLOOD_RANGE
	light.spot_attenuation = 0.8


## The two warehouses on `footprints` (x, z), `heights` high (part B), west then east.
func build_warehouses(footprints_xz: Array[Rect2], heights: Array[float], metal: Material) -> void:
	for index in range(footprints_xz.size()):
		var house := Warehouse.new()
		house.name = WAREHOUSE_NAMES[index]
		add_child(house)
		var docks: Array[float] = []
		docks.assign(DOCK_XS[index])
		var open := OPEN_DOCK if index == 1 else -1
		house.build(footprints_xz[index], heights[index], docks, MAN_DOOR_XS[index], 1.0, metal,
			open)
		_footprints.append(footprints_xz[index])
	var east := get_node(WAREHOUSE_NAMES[1]) as Node3D
	var bumpers: Vector2 = east.call("open_bumpers")
	judge = DockJudge.new()
	judge.name = "DoorThreeJudge"
	judge.set("centre_x", bumpers.x)
	judge.set("bumpers_z", bumpers.y)
	add_child(judge)
	judge.connect("changed", func() -> void:
		east.call("set_docked", judge.get("verdict") == "docked"))
	_dress(footprints_xz[0])


## The east warehouse's door 3, where the van docks.
func door_house() -> Node3D:
	return get_node(WAREHOUSE_NAMES[1]) as Node3D


## The van Ethan drives: its front and rear, read from its collision shape.
func watch(van: CharacterBody3D) -> void:
	vehicle = van
	if judge != null:
		judge.set("vehicle", van)
	for child in van.get_children():
		if child is CollisionShape3D and (child as CollisionShape3D).shape is BoxShape3D:
			var shape := child as CollisionShape3D
			var half := (shape.shape as BoxShape3D).size / 2.0
			_front = shape.position + Vector3(0.0, 0.0, -half.z)
			_rear = shape.position + Vector3(0.0, 0.0, half.z)
			return


## As a night begins: the gate shut, no check under way.
func reset() -> void:
	_gate_open = 0.0
	_gate_target = 0.0
	_check_left = -1.0
	_window_down = false
	_place_gate()
	if judge != null:
		judge.call("reset")
		door_house().call("set_docked", false)


func fence_runs() -> Array:
	return _fence_runs.duplicate()


func footprints() -> Array[Rect2]:
	return _footprints.duplicate()


func gate_open() -> bool:
	return _gate_open >= GATE_WIDE - 0.01


func gate_shut() -> bool:
	return _gate_open <= 0.01


func checking() -> bool:
	return _check_left >= 0.0


func vehicle_near() -> bool:
	if not is_instance_valid(vehicle):
		return false
	var front := vehicle.to_global(_front)
	return front.z > GATE_Z - SWEEP_HALF_DEPTH and front.z < DRIVEWAY.end.y + 20.0 \
		and absf(front.x - GATE_X) < 25.0


## Whether the van's front is at the booth's line, in the lane.
## Whether the van's driver is level with the booth's service opening, within WINDOW_REACH along
## the lane (#348).
func vehicle_at_window() -> bool:
	return vehicle_at_booth() and absf(window_gap()) <= WINDOW_REACH


## How far the driver's eye is from the booth's opening along the lane (positive: he has yet to
## reach it; negative: he is past it).
func window_gap() -> float:
	if not is_instance_valid(driver_eye) or booth == null:
		return INF
	return driver_eye.global_position.z - (booth.call("opening_centre") as Vector3).z


func vehicle_at_booth() -> bool:
	if not is_instance_valid(vehicle):
		return false
	var front := vehicle.to_global(_front)
	return front.z > GATE_Z - SWEEP_HALF_DEPTH and front.z < GATE_Z + STOP_LINE_OUT + 6.0 \
		and absf(front.x - GATE_X) < GATE_WIDE / 2.0


## Whether the whole van is inside the fence, past the gate.
func vehicle_through() -> bool:
	if not is_instance_valid(vehicle):
		return false
	var at := Vector2(vehicle.global_position.x, vehicle.global_position.z)
	return maxf(vehicle.to_global(_front).z, vehicle.to_global(_rear).z) < GATE_Z \
		and Geometry2D.is_point_in_polygon(at, PackedVector2Array(OUTLINE))


## Ethan hands the guard the run sheet through his window: she checks it, then opens the gate.
func hand_run_sheet() -> bool:
	if checking() or _gate_target > 0.0:
		return false
	_check_left = CHECK_SECONDS
	if is_instance_valid(vehicle) and float(vehicle.get("left_window_target")) < 0.5:
		vehicle.set("left_window_target", 1.0)
		_window_down = true
	return true


func _physics_process(delta: float) -> void:
	if _check_left >= 0.0:
		_check_left -= delta
		if _check_left < 0.0:
			_check_left = -1.0
			_gate_target = GATE_WIDE
			run_sheet_checked.emit()
	elif _gate_target > 0.0 and gate_open() and _behind_the_gate():
		_gate_target = 0.0
	var moving := not is_equal_approx(_gate_open, _gate_target)
	_gate_open = move_toward(_gate_open, _gate_target, GATE_SPEED * delta)
	_place_gate()
	if _sliding != null:
		_sliding.call("moving_now", moving)
	if moving and not _motor.playing:
		_motor.play()
	elif not moving and _motor.playing:
		_motor.stop()
	if _window_down and gate_open() and is_instance_valid(vehicle):
		_window_down = false
		vehicle.set("left_window_target", 0.0)
	if booth != null:
		booth.set("driver", driver_eye)
		booth.call("look_at_point", _gaze())
		if checking() != _window_open:
			_window_open = checking()
			booth.call("open_window", _window_open)


func _gaze() -> Vector3:
	var book := booth.get("logbook") as Node3D
	if checking():
		return book.global_position
	if _gate_target == 0.0 and is_instance_valid(vehicle) and vehicle_at_booth() \
			and absf(float(vehicle.get("actual_speed"))) < STOPPED_SPEED:
		if is_instance_valid(driver_eye):
			return driver_eye.global_position
		return vehicle.to_global(Vector3(-0.5, 1.6, -1.0))
	return (booth.get("screen") as Node3D).global_position


func _behind_the_gate() -> bool:
	if not is_instance_valid(vehicle):
		return true
	var nearest := maxf(vehicle.to_global(_front).z, vehicle.to_global(_rear).z)
	var outside := minf(vehicle.to_global(_front).z, vehicle.to_global(_rear).z)
	return nearest < GATE_Z - CLEAR_BEHIND or outside > GATE_Z + STOP_LINE_OUT + 8.0


func _paving(surface: Material) -> void:
	for rect: Rect2 in PAVED + [DRIVEWAY]:
		var slab := Build.box(self, Vector3(rect.get_center().x, PAVING_TOP / 2.0,
			rect.get_center().y), Vector3(rect.size.x, PAVING_TOP, rect.size.y), surface)
		slab.name = "CompoundPaving"


func _boundary() -> void:
	var fence := Fence.new()
	var west := GATE_X - GATE_WIDE / 2.0
	var east := GATE_X + GATE_WIDE / 2.0
	for index in range(OUTLINE.size()):
		var from := OUTLINE[index]
		var to := OUTLINE[(index + 1) % OUTLINE.size()]
		var pieces: Array[Array] = [[from, to]]
		if index == 0:
			pieces = [[from, Vector2(west, GATE_Z)], [Vector2(east, GATE_Z), to]]
		for piece in pieces:
			var a: Vector2 = piece[0]
			var b: Vector2 = piece[1]
			fence.run(self, _body, Vector3(a.x, GROUND, a.y), Vector3(b.x, GROUND, b.y),
				OUTWARD[index])
			_fence_runs.append({"from": a, "to": b})


## The yard at night (part C): floodlights on poles along the north fence; trailers dropped
## square at two of the west warehouse's docks (`west`), on their landing gear, a tandem
## chocked; empty pallets stacked by its east wall; the forklift parked by the east warehouse;
## the dumpsters behind the west one. Each solid.
func _dress(west: Rect2) -> void:
	var steel := Build.material(Color(0.5, 0.52, 0.52), 0.5)
	steel.metallic = 0.6
	for index in range(POLES.size()):
		var at := POLES[index]
		Build.cylinder(self, at + Vector3.UP * POLE_TALL / 2.0, 0.1, POLE_TALL, steel).name = \
			"FloodPole"
		_solid_box(at + Vector3.UP * 1.0, Vector3(0.3, 2.0, 0.3))
		_footprints.append(Rect2(at.x - 0.15, at.z - 0.15, 0.3, 0.3))
		var head := at + Vector3(0.0, POLE_TALL, -0.35)
		Build.box(self, head, Vector3(0.6, 0.12, 0.45), steel).name = "FloodHead"
		var light := SpotLight3D.new()
		light.name = "Flood%d" % (index + 1)
		add_child(light)
		light.position = head - Vector3(0.0, 0.1, 0.0)
		light.look_at(at + Vector3(0.0, 0.0, -20.0), Vector3.UP)
		light.light_color = FLOOD
		light.light_energy = 40.0
		light.spot_angle = 60.0
		light.spot_range = 45.0
		light.shadow_enabled = index == 1
		rain_places.append(Transform3D(Basis.IDENTITY, Vector3(at.x, GROUND, at.z
			- YARD_RAIN_OUT)))
	var bumper_face := west.end.y + 0.13
	var docks: Array = DOCK_XS[0]
	for slot in range(TRAILER_DOCKS.size()):
		var x: float = docks[TRAILER_DOCKS[slot]]
		var at := Transform3D(Basis.IDENTITY, Vector3(x, GROUND + PAVING_TOP, bumper_face
			+ DOCK_GAP + TRAILER_HALF))
		var trailer := TRAILER.instantiate() as Node3D
		trailer.name = "DroppedTrailer%d" % (slot + 1)
		add_child(trailer)
		trailer.global_transform = at
		trailer.set_meta("rear_z", at.origin.z - TRAILER_HALF)
		var gear := trailer.find_child("LandingGear", true, false) as Node3D
		trailer.set_meta("gear_down", _lowest(gear) - GROUND - PAVING_TOP if gear != null else 1.0)
		_solid_box(at.origin + Vector3.UP * 2.175, Vector3(TRAILER_WIDTH, 4.35, TRAILER_HALF
			* 2.0))
		_footprints.append(Rect2(x - TRAILER_WIDTH / 2.0, at.origin.z - TRAILER_HALF,
			TRAILER_WIDTH, TRAILER_HALF * 2.0))
		_chock(at * Vector3(CHOCK_OUT, 0.0, REAR_AXLE + CHOCK_AHEAD))
	for index in range(PALLET_STACKS.size()):
		var holder := Node3D.new()
		holder.name = "PalletStack%d" % (index + 1)
		add_child(holder)
		holder.position = PALLET_STACKS[index] + Vector3.UP * PAVING_TOP
		for level in range(PALLET_HIGH - index * 3):
			var deck := PALLET.instantiate() as Node3D
			holder.add_child(deck)
			deck.position = Vector3(0.0, level * PALLET_SIZE.y, 0.0)
			deck.rotation.y = PI / 2.0 if level % 2 == 1 and index == 0 else 0.0
		var tall := (PALLET_HIGH - index * 3) * PALLET_SIZE.y
		_solid_box(holder.position + Vector3.UP * tall / 2.0, Vector3(1.2, tall, 1.2))
		_footprints.append(Rect2(holder.position.x - 0.6, holder.position.z - 0.6, 1.2, 1.2))
	var forklift := FORKLIFT.instantiate() as Node3D
	forklift.name = "ParkedForklift"
	add_child(forklift)
	forklift.global_transform = FORKLIFT_AT.translated(Vector3.UP * PAVING_TOP)
	_solid_box(FORKLIFT_AT.origin + Vector3.UP * FORKLIFT_BOX.y / 2.0, Vector3(FORKLIFT_BOX.z,
		FORKLIFT_BOX.y, FORKLIFT_BOX.x))
	_footprints.append(Rect2(FORKLIFT_AT.origin.x - FORKLIFT_BOX.z / 2.0, FORKLIFT_AT.origin.z
		- FORKLIFT_BOX.x / 2.0, FORKLIFT_BOX.z, FORKLIFT_BOX.x))
	var bins := DUMPSTERS.instantiate() as Node3D
	bins.name = "Dumpsters"
	add_child(bins)
	bins.global_transform = DUMPSTERS_AT.translated(Vector3.UP * PAVING_TOP)
	_solid_box(DUMPSTERS_AT.origin + Vector3.UP * DUMPSTER_BOX.y / 2.0, Vector3(
		DUMPSTER_BOX.z, DUMPSTER_BOX.y, DUMPSTER_BOX.x))
	_footprints.append(Rect2(DUMPSTERS_AT.origin.x - DUMPSTER_BOX.z / 2.0, DUMPSTERS_AT.origin.z
		- DUMPSTER_BOX.x / 2.0, DUMPSTER_BOX.z, DUMPSTER_BOX.x))


func _chock(at: Vector3) -> void:
	var wedge := MeshInstance3D.new()
	wedge.name = "WheelChock"
	var prism := PrismMesh.new()
	prism.size = Vector3(CHOCK.z, CHOCK.y, CHOCK.x)
	prism.left_to_right = 0.0
	wedge.mesh = prism
	wedge.material_override = Build.material(Color(0.85, 0.65, 0.08), 0.8)
	add_child(wedge)
	wedge.global_transform = Transform3D(Basis(Vector3.UP, PI / 2.0), at + Vector3.UP
		* (PAVING_TOP + CHOCK.y / 2.0))


func _lowest(node: Node3D) -> float:
	var lowest := INF
	for found in node.find_children("*", "MeshInstance3D", true, false):
		var mesh := found as MeshInstance3D
		lowest = minf(lowest, (mesh.global_transform * mesh.get_aabb()).position.y)
	if node is MeshInstance3D:
		var own := node as MeshInstance3D
		lowest = minf(lowest, (own.global_transform * own.get_aabb()).position.y)
	return lowest


func _gate_leaf() -> void:
	_sliding = SlidingGate.new()
	_sliding.name = "SlidingGate"
	add_child(_sliding)
	_sliding.global_position = Vector3(GATE_X, GROUND, GATE_Z)
	_sliding.call("build", GATE_WIDE, TAIL, Build.material(Color(0.6, 0.6, 0.58), 0.85))
	_gate = _sliding.get("leaf") as AnimatableBody3D
	_gate.name = "Gate"
	_place_gate()
	_motor = AudioStreamPlayer3D.new()
	_motor.name = "GateMotor"
	_motor.stream = MOTOR
	_motor.pitch_scale = 0.55
	_motor.bus = "Ambience"
	_motor.volume_db = -14.0
	add_child(_motor)
	_motor.global_position = (_sliding.find_child("Motor", true, false) as Node3D).global_position \
		+ Vector3.UP * 0.25


func _place_gate() -> void:
	if _sliding != null:
		_sliding.call("set_open", _gate_open)


## The booth's kerbed island, with a bollard at each of its corners on the lane.
func _island(concrete: Material) -> void:
	var top := GROUND + PAVING_TOP + ISLAND_HEIGHT
	Build.box(self, Vector3(ISLAND.get_center().x, GROUND + PAVING_TOP + ISLAND_HEIGHT / 2.0,
		ISLAND.get_center().y), Vector3(ISLAND.size.x, ISLAND_HEIGHT, ISLAND.size.y), concrete) \
		.name = "BoothIsland"
	_footprints.append(ISLAND)
	var yellow := Build.material(Color(0.86, 0.68, 0.08), 0.5)
	for z: float in [ISLAND.position.y + 0.2, ISLAND.end.y - 0.2]:
		var at := Vector3(ISLAND.end.x - 0.2, top, z)
		Build.cylinder(self, at + Vector3.UP * BOLLARD_HEIGHT / 2.0, BOLLARD_RADIUS,
			BOLLARD_HEIGHT, yellow).name = "Bollard"
		_solid_box(at + Vector3.UP * BOLLARD_HEIGHT / 2.0, Vector3(0.15, BOLLARD_HEIGHT, 0.15))


func _solid_box(centre: Vector3, size: Vector3) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = centre
	_body.add_child(collision)
