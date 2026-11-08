extends Node3D
## The van's particle effects (CHANGE-BRIEF.md §2, §3, §5): the wiper flick, the roof spill and
## the exhaust vapour. This node places, starts and stops them from what the van does and never
## writes the van's state. Each effect's look lives in its scene in game/effects/.
##
## The flick and the spill move with the van, both in the windshield's frame, so their water
## leaves at the van's speed. Each tick their gravity is the still air's, turned into each
## emitter's frame, plus the push the van's motion gives the water: as it drives, the air carries
## the flick's drops up the glass and its run-off back along the side window; as it slows, the
## spill's water surges forward. Colliders fitted to the curved windshield hold the water that
## lands on it, which then slides; none passes into the cab. Each van has its own copy of these
## process materials, since their gravity changes as it drives.

const WiperFlick = preload("res://effects/wiper_flick.tscn")
const RoofSpill = preload("res://effects/roof_spill.tscn")
const ExhaustVapour = preload("res://effects/exhaust_vapour.tscn")
const FLICK_POOL := 2
const FLICK_EMITTERS: Array[String] = ["WaterSheet", "BigDrops", "HeavyDrops", "FineSpray",
	"SpillWater", "PillarRunoff"]
const SPILL_EMITTERS: Array[String] = ["WaterWash", "RoofStreams", "RoofBeads", "Rivulets"]
## The air's push on the flick's water: g × (speed / its terminal speed)², up to a most, as drag
## on a drop grows with the square of the air's speed past it. It runs up the glass, except on the
## run-off, which the air carries back along the side window.
const AIR_TERMINAL := {"WaterSheet": 6.0, "BigDrops": 8.0, "HeavyDrops": 12.0, "FineSpray": 3.0,
	"SpillWater": 8.0, "PillarRunoff": 5.0}
const AIR_MOST := {"WaterSheet": 40.0, "BigDrops": 40.0, "HeavyDrops": 40.0, "FineSpray": 80.0,
	"SpillWater": 40.0, "PillarRunoff": 60.0}
const GRAVITY := 9.8
## The run-off is thrown back along the side window only above this forward speed.
const RUNOFF_SPEED := 5.0
## A spill's water stays on the glass this long, and the first top turn within it throws it off.
const SPILL_ON_GLASS := 3.0
## The surge of the spill's water follows the van's deceleration with this time constant.
const SURGE_FOLLOW := 0.05
## The windshield is curved, so thin colliders follow it, one per third of its width, each a plane
## fitted to that third of the glass model; their faces lie this far outside the glass.
const GLASS_PANELS := 3
const GLASS_SKIN := 0.003
const GLASS_DEPTH := 0.3
const SPILL_SPEED := 8.0
const SPILL_DECELERATION := 6.0
const SPILL_TICKS := 2
const ROOF_REFILL := 20.0
const ROOF_LIP := Vector3(0.0, 2.206, -1.038)
const PASSENGER_LAYER := 2
const PASSENGER_LEAD := 0.015
const PASSENGER_LIFT := 0.01
const WIPE_WIDTH := 0.1
const WIPE_DEPTH := 0.14
## No tailpipe is modelled; this place is an assumption (CHANGE-BRIEF.md revision 2).
const TAILPIPE := Vector3(-0.6, 0.46, 2.85)
const IDLE_RATIO := 0.15
const THROTTLE_RATIO := 0.65
const IGNITION_DELAY := 0.4
const IGNITION_RAMP := 0.6
const THROTTLE_FOLLOW := 0.6

var vehicle: CharacterBody3D
var flicks: Array[Node3D] = []
var flicks_fired: int = 0
var flicks_missed: int = 0
var runoffs_thrown: int = 0
var spill_water_thrown: int = 0
var last_flick: Node3D
var spill: Node3D
var spills_fired: int = 0
var spills_ignored: int = 0
var roof_refill: float = 0.0
var exhaust: GPUParticles3D
var glass_colliders: Array[GPUParticlesCollisionBox3D] = []
var wipe_collider: GPUParticlesCollisionBox3D
var passenger_flicks: int = 0

var _body: Node3D
var _wiper: Node3D
var _tip_reach: float = 0.0
var _top_turn: float = 0.0
var _flick_alive: Array[bool] = []
var _spill_alive: bool = false
var _spill_water: float = 0.0
var _was_braking: bool = false
var _brake_pending: bool = false
var _hard_ticks: int = 0
var _last_speed: float = 0.0
var _last_forward: float = 0.0
var _surge: float = 0.0
var _engine_time: float = 0.0
var _ramp: float = 0.0
var _throttle: float = 0.0
var _still_air: Dictionary = {}
var _flick_process: Dictionary = {}
var _spill_process: Dictionary = {}
var _up_glass := Vector3.UP
var _passenger: Node3D
var _passenger_arm: float = 0.0


func setup(van: CharacterBody3D, wiper: Node3D, tip_reach: float, body: Node3D,
		glass: MeshInstance3D) -> void:
	vehicle = van
	_wiper = wiper
	_tip_reach = tip_reach
	_body = body
	var constants := (van.get_script() as GDScript).get_script_constant_map()
	_top_turn = float(constants["WIPER_PARK"]) + float(constants["WIPER_SWEEP"]) * 0.5
	van.wiper_swept.connect(_on_wiper_swept)
	var frame := body.global_transform.affine_inverse() * glass.global_transform
	_up_glass = frame.basis.y.normalized()
	for index in range(FLICK_POOL):
		var flick := WiperFlick.instantiate() as Node3D
		flick.name = "WiperFlick%d" % index
		flick.basis = frame.basis.orthonormalized()
		body.add_child(flick)
		flicks.append(flick)
		_flick_alive.append(false)
		var spray := flick.get_node("FineSpray") as GPUParticles3D
		spray.finished.connect(_flick_finished.bind(index))
	_own_processes(flicks, FLICK_EMITTERS, _flick_process)
	_fit_glass(glass.mesh, frame)
	spill = RoofSpill.instantiate() as Node3D
	spill.transform = Transform3D(frame.basis.orthonormalized(), ROOF_LIP)
	body.add_child(spill)
	_own_processes([spill], SPILL_EMITTERS, _spill_process)
	(spill.get_node("Rivulets") as GPUParticles3D).finished.connect(_spill_finished)
	var vapour := ExhaustVapour.instantiate() as Node3D
	vapour.position = TAILPIPE
	body.add_child(vapour)
	exhaust = vapour.get_node("ExhaustPlume") as GPUParticles3D
	_last_speed = absf(van.actual_speed)
	_last_forward = van.actual_speed


func tip() -> Vector3:
	return _wiper.global_transform * Vector3(0.0, _tip_reach, 0.0)


## The passenger blade leaves the water it pushed on the glass just ahead of it at its top turn,
## inside the driver's blade's sweep; the driver's blade carries a collider that wipes it off.
func wipe_with(passenger: Node3D, passenger_arm: float, driver_blade: Node3D,
		driver_length: float) -> void:
	_passenger = passenger
	_passenger_arm = passenger_arm
	wipe_collider = GPUParticlesCollisionBox3D.new()
	wipe_collider.name = "BladeWipe"
	wipe_collider.size = Vector3(WIPE_WIDTH, driver_length, WIPE_DEPTH)
	wipe_collider.cull_mask = PASSENGER_LAYER
	driver_blade.add_child(wipe_collider)


## Where the passenger blade's water starts: on the glass's outer face, just ahead of the blade's
## middle. The drops' frame leads the blade's travel along +x with +y leaving the glass; the line
## of water lies in the glass with its +y along the blade.
func passenger_water_at(line: bool = false) -> Transform3D:
	var frame := _passenger.global_transform
	var glass := glass_colliders[1]
	var outward := -glass.global_basis.z.normalized()
	var face := glass.global_position - glass.global_basis.z * glass.size.z * 0.5
	var lead := -frame.basis.x.normalized()
	var at := frame * Vector3(0.0, _passenger_arm, 0.0) + lead * PASSENGER_LEAD
	at += outward * (outward.dot(face - at) + PASSENGER_LIFT)
	var ahead := (lead - outward * outward.dot(lead)).normalized()
	if not line:
		return Transform3D(Basis(ahead, outward, ahead.cross(outward)), at)
	var along := outward.cross(ahead).normalized()
	if along.dot(frame.basis.y) < 0.0:
		along = -along
	return Transform3D(Basis(ahead, along, ahead.cross(along)), at)


func flicks_alive() -> int:
	return _flick_alive.count(true)


func spill_alive() -> bool:
	return _spill_alive


func spill_water_on_glass() -> bool:
	return _spill_water > 0.0


func roof_water_ready() -> bool:
	return roof_refill <= 0.0 and not _spill_alive


func _physics_process(delta: float) -> void:
	if vehicle == null:
		return
	_spill_water = maxf(_spill_water - delta, 0.0)
	_watch_brakes(delta)
	_drive_exhaust(delta)
	_blow_flicks()
	_pour_spill(delta)


## Each emitter named gets this van's own copy of its process material, shared by the van's
## bursts; the scene's gravity is kept as the still air's, in the world.
func _own_processes(roots: Array, names: Array[String], copies: Dictionary) -> void:
	for emitter_name in names:
		var first := (roots[0] as Node).get_node(emitter_name) as GPUParticles3D
		var original := first.process_material as ParticleProcessMaterial
		_still_air[emitter_name] = original.gravity
		var own := original.duplicate() as ParticleProcessMaterial
		copies[emitter_name] = own
		for root: Node in roots:
			(root.get_node(emitter_name) as GPUParticles3D).process_material = own


## One thin collider per third of the windshield's width: a plane fitted to that third of the
## glass model, in the glass's frame, with its face just outside the glass.
func _fit_glass(mesh: Mesh, frame: Transform3D) -> void:
	var faces := mesh.get_faces()
	var bounds := mesh.get_aabb()
	var width := bounds.size.x / GLASS_PANELS
	var middle := bounds.get_center().y
	for panel in range(GLASS_PANELS):
		var left := bounds.position.x + width * panel
		var fit := _fit_plane(faces, left, left + width)
		var centre_x := left + width * 0.5
		var surface := Vector3(centre_x, middle, fit.x + fit.y * centre_x + fit.z * middle)
		var inward := Vector3(-fit.y, -fit.z, 1.0).normalized()
		var across := (Vector3.RIGHT - inward * inward.dot(Vector3.RIGHT)).normalized()
		var panel_basis := Basis(across, inward.cross(across), inward)
		var collider := GPUParticlesCollisionBox3D.new()
		collider.name = "Glass%s" % ["Left", "Middle", "Right"][panel]
		collider.size = Vector3(width / across.x + 0.02, bounds.size.y + 0.04, GLASS_DEPTH)
		collider.cull_mask = 0xFFFFFFFF ^ PASSENGER_LAYER
		collider.transform = frame * Transform3D(panel_basis,
			surface + inward * (GLASS_DEPTH * 0.5 - GLASS_SKIN))
		_body.add_child(collider)
		glass_colliders.append(collider)


## The plane z = a + b·x + c·y, returned as (a, b, c), that best fits the points with x between
## left and right.
static func _fit_plane(points: PackedVector3Array, left: float, right: float) -> Vector3:
	var count := 0.0
	var sums := PackedFloat64Array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
	for point in points:
		if point.x < left or point.x > right:
			continue
		count += 1.0
		sums[0] += point.x
		sums[1] += point.y
		sums[2] += point.x * point.x
		sums[3] += point.x * point.y
		sums[4] += point.y * point.y
		sums[5] += point.z
		sums[6] += point.x * point.z
		sums[7] += point.y * point.z
	var normal := Basis(Vector3(count, sums[0], sums[1]), Vector3(sums[0], sums[2], sums[3]),
		Vector3(sums[1], sums[3], sums[4]))
	return normal.inverse() * Vector3(sums[5], sums[6], sums[7])


## Each tick the flick's gravity is the still air's plus the push of the air at the van's forward
## speed, up the glass or, for the run-off, back along the side; reversing, the cab shields it.
func _blow_flicks() -> void:
	if not flicks[0].is_inside_tree():
		return
	var speed := maxf(vehicle.actual_speed, 0.0)
	var up_glass := (_body.global_basis * _up_glass).normalized()
	var back := _body.global_basis.z.normalized()
	for emitter_name: String in AIR_TERMINAL:
		var emitter := flicks[0].get_node(emitter_name) as GPUParticles3D
		var push := minf(GRAVITY * pow(speed / float(AIR_TERMINAL[emitter_name]), 2.0),
			float(AIR_MOST[emitter_name]))
		var along := back if emitter_name == "PillarRunoff" else up_glass
		(_flick_process[emitter_name] as ParticleProcessMaterial).gravity = \
			emitter.global_basis.inverse() * (Vector3(_still_air[emitter_name]) + along * push)


## Each tick the spill's gravity is the still air's plus the surge of its water as the van's speed
## changes: forward as it slows, back as it speeds up.
func _pour_spill(delta: float) -> void:
	var change: float = (vehicle.actual_speed - _last_forward) / delta
	_last_forward = vehicle.actual_speed
	_surge = lerpf(_surge, -change, 1.0 - exp(-delta / SURGE_FOLLOW))
	if not spill.is_inside_tree():
		return
	var ahead := -_body.global_basis.z.normalized()
	var into_spill := spill.global_basis.inverse()
	for emitter_name: String in SPILL_EMITTERS:
		(_spill_process[emitter_name] as ParticleProcessMaterial).gravity = \
			into_spill * (Vector3(_still_air[emitter_name]) + ahead * _surge)


func _on_wiper_swept() -> void:
	if not is_instance_valid(_wiper) or vehicle.wiper_setting == 0 \
			or vehicle.wiper_angle < _top_turn:
		return
	var index := _flick_alive.find(false)
	if index < 0:
		flicks_missed += 1
		push_warning("Wiper flick missed: both bursts are still alive")
		return
	var flick := flicks[index]
	if not flick.is_inside_tree():
		return
	flick.global_position = tip()
	_lay_along_blade(flick.get_node("WaterSheet") as Node3D)
	var throws: Array[GPUParticles3D] = []
	for emitter_name in ["WaterSheet", "BigDrops", "HeavyDrops", "FineSpray"]:
		throws.append(flick.get_node(emitter_name))
	if vehicle.actual_speed >= RUNOFF_SPEED:
		throws.append(flick.get_node("PillarRunoff"))
		runoffs_thrown += 1
	if _spill_water > 0.0:
		throws.append(flick.get_node("SpillWater"))
		_spill_water = 0.0
		spill_water_thrown += 1
	for emitter in throws:
		emitter.restart()
	if is_instance_valid(_passenger):
		var water := flick.get_node("PassengerWater") as GPUParticles3D
		var line := flick.get_node("PassengerLine") as GPUParticles3D
		water.global_transform = passenger_water_at()
		line.global_transform = passenger_water_at(true)
		water.restart()
		line.restart()
		passenger_flicks += 1
	_flick_alive[index] = true
	last_flick = flick
	flicks_fired += 1


## The water the blade pushed ahead of it leaves as a sheet along the blade: the sheet is turned
## in the glass about its normal, so that its +y runs out along the blade as it turns.
func _lay_along_blade(sheet: Node3D) -> void:
	var along := (sheet.get_parent() as Node3D).global_basis.inverse() * _wiper.global_basis.y
	sheet.basis = Basis(Vector3.BACK, atan2(-along.x, along.y))


func _flick_finished(index: int) -> void:
	_flick_alive[index] = false


func _spill_finished() -> void:
	_spill_alive = false


func _watch_brakes(delta: float) -> void:
	roof_refill = maxf(roof_refill - delta, 0.0)
	var speed := absf(vehicle.actual_speed)
	var slowing := (_last_speed - speed) / delta
	var braking: bool = vehicle.braking
	if braking and not _was_braking:
		_brake_pending = _last_speed >= SPILL_SPEED
		_hard_ticks = 0
	if _brake_pending and braking:
		_hard_ticks = _hard_ticks + 1 if slowing >= SPILL_DECELERATION else 0
		_brake_pending = _hard_ticks > 0
		if _hard_ticks >= SPILL_TICKS:
			_brake_pending = false
			_hard_brake()
	_was_braking = braking
	_last_speed = speed


func _hard_brake() -> void:
	if not roof_water_ready():
		spills_ignored += 1
		return
	for emitter_name: String in SPILL_EMITTERS:
		(spill.get_node(emitter_name) as GPUParticles3D).restart()
	_spill_alive = true
	_spill_water = SPILL_ON_GLASS
	roof_refill = ROOF_REFILL
	spills_fired += 1


func _drive_exhaust(delta: float) -> void:
	if not vehicle.engine_on or not exhaust.is_visible_in_tree():
		exhaust.emitting = false
		exhaust.amount_ratio = 0.0
		_ramp = 0.0
		_engine_time = IGNITION_DELAY if vehicle.engine_on else 0.0
		return
	_engine_time += delta
	if _engine_time < IGNITION_DELAY:
		return
	_ramp = move_toward(_ramp, 1.0, delta / IGNITION_RAMP)
	_throttle = move_toward(_throttle, clampf(vehicle.throttle, 0.0, 1.0), delta / THROTTLE_FOLLOW)
	exhaust.amount_ratio = (IDLE_RATIO + THROTTLE_RATIO * _throttle) * _ramp
	exhaust.emitting = true
