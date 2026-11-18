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
const Booth = preload("guard_booth.gd")
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

var vehicle: CharacterBody3D
var driver_eye: Node3D
var booth: Node3D

var _fence_runs: Array = []
var _footprints: Array[Rect2] = []
var _body: StaticBody3D
var _gate: AnimatableBody3D
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


## The van Ethan drives: its front and rear, read from its collision shape.
func watch(van: CharacterBody3D) -> void:
	vehicle = van
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
	if moving and not _motor.playing:
		_motor.play()
	elif not moving and _motor.playing:
		_motor.stop()
	if _window_down and gate_open() and is_instance_valid(vehicle):
		_window_down = false
		vehicle.set("left_window_target", 0.0)
	if booth != null:
		booth.call("look_at_point", _gaze())


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


func _gate_leaf() -> void:
	var fence := Fence.new()
	_gate = AnimatableBody3D.new()
	_gate.name = "Gate"
	add_child(_gate)
	var leaf := GATE_WIDE + TAIL
	var middle := (GATE_WIDE - TAIL) / 2.0
	Build.box(_gate, Vector3(middle, 0.15, 0.0), Vector3(leaf, 0.12, 0.08),
		fence.galvanised).name = "GateBottom"
	Build.box(_gate, Vector3(middle, Fence.HEIGHT, 0.0), Vector3(leaf, 0.08, 0.08),
		fence.galvanised).name = "GateTop"
	for x: float in [-TAIL, 0.0, GATE_WIDE]:
		Build.box(_gate, Vector3(x, Fence.HEIGHT / 2.0, 0.0), Vector3(0.08, Fence.HEIGHT, 0.08),
			fence.galvanised).name = "GateStile"
	var quad := QuadMesh.new()
	quad.size = Vector2(leaf, Fence.HEIGHT - 0.2)
	Build.instance(_gate, Vector3(middle, Fence.HEIGHT / 2.0 + 0.1, 0.0), quad,
		fence.link).name = "GateMesh"
	var shape := BoxShape3D.new()
	shape.size = Vector3(GATE_WIDE, Fence.HEIGHT, 0.12)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = Vector3(GATE_WIDE / 2.0, Fence.HEIGHT / 2.0, 0.0)
	_gate.add_child(collision)
	_place_gate()
	for x: float in [GATE_X - GATE_WIDE / 2.0 - 2.0, GATE_X - GATE_WIDE / 2.0 - 7.0]:
		Build.box(self, Vector3(x, 0.4, GATE_Z - 0.2), Vector3(0.15, 0.8, 0.15),
			fence.galvanised).name = "GateRollerPost"
	_motor = AudioStreamPlayer3D.new()
	_motor.name = "GateMotor"
	_motor.stream = MOTOR
	_motor.pitch_scale = 0.55
	_motor.bus = "Ambience"
	_motor.volume_db = -14.0
	add_child(_motor)
	_motor.global_position = Vector3(GATE_X - GATE_WIDE / 2.0 - 1.0, 0.5, GATE_Z - 0.4)


func _place_gate() -> void:
	if _gate != null:
		_gate.global_position = Vector3(GATE_X - GATE_WIDE / 2.0 - _gate_open, GROUND,
			GATE_Z - 0.25)


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
