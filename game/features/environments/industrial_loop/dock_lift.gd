extends AnimatableBody3D
## Bay 9's dock lift (docs/PHASE_BRIEF.md, steps 2d and 2e, rules G1 and H1): a scissor lift in a
## pit behind the van bay's door, as real sites fit for vans, whose floors stand below a truck
## dock. Its steel deck, 1.83 x 2.44 m (6 x 8 ft), rests flush with the dock floor, its edges
## painted in yellow and black stripes, and carries whoever stands on it. Worked from its pendant,
## it travels down to a van's floor and back up at about 0.14 m/s while its button is held, and
## stops where it is when let go (ANSI MH29.1's press-and-hold controls, as Pentalift's standard
## two-button pendant: UP and DOWN, with a red emergency stop), beeping while it moves (#286);
## its hinged bridge plate, 36 in
## (0.91 m) long as dock lifts offer for reaching into a vehicle, stored upright as a toe guard,
## comes down once the deck is there and rests on the van's rear sill, reaching over it onto the
## floor, and stands up again before it rises. The plate is solid on the van's layer, which the
## van's own movement never reads, so it never pushes the van: upright it stops a load at the
## deck's edge, down it is the way across. The node's origin is the deck's top centre. The lift
## is itself the moving body, so Godot carries whoever stands on it (a body set to follow
## physics follows only its own moves).

const Build = preload("res://shared/components/mesh_builder.gd")
const DECK := Vector3(1.83, 0.12, 2.44)
const EDGE := 0.08
const PAINT := 0.002
const LIP := Vector3(1.5, 0.025, 0.91)
const STRIPES := "res://features/environments/industrial_loop/art/depot/hazard_stripes.png"
const SPEED := 0.14
const LIP_SECONDS := 0.8
const STORED := -PI / 2.0
const PENDANT := Vector3(-0.865, 0.0, -1.02)
const POST := Vector2(0.02, 1.0)
const BEEP = preload("res://features/audio/loading/lift_beep.wav")
const BEEP_DB := -6.0

var top := 0.0
## Whether its button is being held: it moves only then.
var held := false

var _target := 0.0
var _lip := 0.0
var _lip_wanted := 0.0
var _deploy := false
var _rest := 0.0
var _van: Node3D
var _pivot: Node3D
var _guard: CollisionShape3D


func build() -> void:
	top = position.y
	_target = top
	var steel := Build.material(Color(0.3, 0.32, 0.34), 0.45)
	steel.metallic = 0.6
	var deck := Build.box(self, Vector3(0.0, -DECK.y / 2.0, 0.0), DECK, steel)
	deck.name = "Platform"
	var paint := StandardMaterial3D.new()
	paint.albedo_texture = load(STRIPES)
	paint.roughness = 0.7
	paint.uv1_triplanar = true
	paint.uv1_world_triplanar = true
	paint.uv1_scale = Vector3.ONE * 2.0
	for side: float in [-1.0, 1.0]:
		Build.box(self, Vector3(side * (DECK.x - EDGE) / 2.0, PAINT / 2.0, 0.0), Vector3(EDGE,
			PAINT, DECK.z), paint).name = "EdgeStripe"
		Build.box(self, Vector3(0.0, PAINT / 2.0, side * (DECK.z - EDGE) / 2.0), Vector3(
			DECK.x - EDGE * 2.0, PAINT, EDGE), paint).name = "EdgeStripe"
	var shape := BoxShape3D.new()
	shape.size = DECK
	var collision := CollisionShape3D.new()
	collision.name = "DeckShape"
	collision.shape = shape
	collision.position = Vector3(0.0, -DECK.y / 2.0, 0.0)
	add_child(collision)
	_pivot = Node3D.new()
	_pivot.name = "BridgeLip"
	_pivot.position = Vector3(0.0, 0.0, DECK.z / 2.0)
	_pivot.rotation.x = STORED
	add_child(_pivot)
	Build.box(_pivot, Vector3(0.0, -LIP.y / 2.0, LIP.z / 2.0), LIP, paint).name = "BridgeLipPlate"
	_guard = _solid(_pivot, "BridgeLipBody", Vector3(0.0, -LIP.y / 2.0, LIP.z / 2.0), LIP)
	var edge := Marker3D.new()
	edge.name = "BridgeLipEdge"
	edge.position = Vector3(0.0, 0.0, LIP.z)
	_pivot.add_child(edge)
	var casing := Build.material(Color(0.95, 0.75, 0.05), 0.5)
	Build.cylinder(self, PENDANT + Vector3.UP * POST.y / 2.0, POST.x, POST.y,
		steel).name = "LiftPendantPost"
	_solid(self, "LiftPendantPostBody", PENDANT + Vector3.UP * 0.6,
		Vector3(POST.x * 2.0, 1.2, POST.x * 2.0))
	var pendant := Build.box(self, PENDANT + Vector3.UP * 1.08, Vector3(0.1, 0.2, 0.07), casing)
	pendant.name = "LiftPendant"
	var black := Build.material(Color(0.06, 0.06, 0.06), 0.5)
	for button: Array in [["PendantUp", 0.035, "UP"], ["PendantDown", -0.035, "DOWN"]]:
		var knob := Build.box(pendant, Vector3(0.0, button[1], 0.04), Vector3(0.04, 0.04, 0.012),
			black)
		knob.name = button[0]
		var label := Label3D.new()
		label.text = button[2]
		label.font_size = 24
		label.pixel_size = 0.0008
		label.modulate = Color(0.08, 0.08, 0.08)
		label.outline_size = 0
		label.position = Vector3(0.0, float(button[1]) + 0.03, 0.0351)
		pendant.add_child(label)
	var stop := Build.cylinder(pendant, Vector3(0.0, 0.112, 0.0), 0.022, 0.024,
		Build.material(Color(0.75, 0.05, 0.04), 0.4))
	stop.name = "PendantStop"
	var beep := AudioStreamPlayer3D.new()
	beep.name = "LiftBeep"
	beep.stream = BEEP
	beep.volume_db = BEEP_DB
	beep.bus = &"Ambience"
	beep.unit_size = 4.0
	beep.position = Vector3(0.0, -0.3, 0.0)
	add_child(beep)


func pendant() -> Vector3:
	return to_global(PENDANT)


func at_top() -> bool:
	return is_equal_approx(position.y, top) and is_equal_approx(_target, top) and _lip == 0.0


func at_bottom() -> bool:
	return _target < top and is_equal_approx(position.y, _target) and is_equal_approx(_lip,
		_lip_wanted)


func moving() -> bool:
	return held and travelling()


## Whether its way is up: toward the dock floor.
func rising() -> bool:
	return is_equal_approx(_target, top)


## Whether it is away from its top and its bottom, moving or stopped between them.
func travelling() -> bool:
	return not at_top() and not at_bottom()


## Its button held (`on`) or let go: it moves only while held.
func hold(on: bool) -> void:
	held = on


## Its button pressed again where it stopped: on toward where it was going.
func resume() -> void:
	held = true


## Down to the height `level` (a van's floor), the bridge plate laid on it if `deploy`: on the
## edge `support` (the van's rear sill) if the plate reaches it, else flat.
## Down to `level`, its plate laid onto the sill of `van` (`sill()`) when `deploy`, kept resting
## on it as the van settles under its load (#287).
func lower(level: float, deploy: bool, van: Node3D = null) -> void:
	if at_top():
		_target = level
		_deploy = deploy
		_van = van
		_lip_wanted = 0.0
		_rest = _rest_on(level, _support())


## The plate's body, which a pallet jack rolls over once the plate is down.
func lip_body() -> RID:
	return (_guard.get_parent() as CollisionObject3D).get_rid()


func lip_down() -> bool:
	return _lip_wanted == 1.0 and is_equal_approx(_lip, 1.0)


func raise() -> void:
	if at_bottom():
		_lip_wanted = 0.0
		_target = top


func reset() -> void:
	held = false
	position.y = top
	_target = top
	_lip = 0.0
	_lip_wanted = 0.0
	_van = null
	_pivot.rotation.x = STORED


func _physics_process(delta: float) -> void:
	if _lip >= 1.0 and _lip_wanted >= 1.0 and is_instance_valid(_van):
		_rest = _rest_on(global_position.y, _support())
		_pivot.rotation.x = -_rest
	if not is_equal_approx(_lip, _lip_wanted):
		_lip = move_toward(_lip, _lip_wanted, delta / LIP_SECONDS)
		_pivot.rotation.x = lerpf(STORED, -_rest, smoothstep(0.0, 1.0, _lip))
		return
	var beeping := false
	if not is_equal_approx(position.y, _target):
		if held:
			position.y = move_toward(position.y, _target, SPEED * delta)
			beeping = true
	elif _target < top and _deploy and _lip_wanted == 0.0:
		_lip_wanted = 1.0
	var beep := get_node_or_null("LiftBeep") as AudioStreamPlayer3D
	if beep != null and beep.playing != beeping:
		if beeping:
			beep.play()
		else:
			beep.stop()


func _support() -> Vector3:
	return _van.call("sill") if is_instance_valid(_van) else Vector3.INF


## The angle, tip up, at which the plate laid from the deck at `level` comes to rest with its
## underside on the edge `support`, or 0 (flat) when it cannot reach it.
func _rest_on(level: float, support: Vector3) -> float:
	if not support.is_finite():
		return 0.0
	var reach := (support - to_global(Vector3(0.0, 0.0, DECK.z / 2.0))).dot(
		global_basis.z.normalized())
	if reach <= 0.0 or reach > LIP.z:
		return 0.0
	var rise := support.y - level
	return asin(clampf(rise / Vector2(reach, LIP.y).length(), -1.0, 1.0)) + atan2(LIP.y, reach)


func _solid(parent: Node3D, label: String, at: Vector3, size: Vector3) -> CollisionShape3D:
	var body := AnimatableBody3D.new()
	body.name = label
	body.sync_to_physics = false
	body.collision_layer = 2
	body.collision_mask = 0
	parent.add_child(body)
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = at
	body.add_child(collision)
	return collision
