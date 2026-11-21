extends Node3D
## A cantilever sliding gate, as real ones are (the audit, #349): its chain-link leaf framed by a
## deep bottom rail, a top rail, stiles and diagonal braces, with a counterweight tail behind the
## opening; it rides on two roller carriages on a concrete footing, placed so both stay under its
## bottom rail shut and open, and a guide post's rollers hold its top rail upright; a toothed rack
## along the rail's inner face meshes with the pinion of the motor (Maxwell autodoors' sliding gate
## motor, CC BY 4.0) on its plinth inside the fence; a receiver post catches it shut; photocells
## on short posts face each other across the opening; a warning lamp (x4vier28's, CC BY 4.0) on the
## inner guide post, clear of the leaf's path, flashes amber while it moves. Shared by the container yard and the compound.
## Its frame: x along the line, from the opening's middle; z inward (into the site) negative.

const Build = preload("res://shared/components/mesh_builder.gd")
const Fence = preload("chain_link_fence.gd")
const MOTOR = preload("res://features/environments/industrial_loop/art/gates/gate_motor/gate_motor.glb")
const LAMP = preload("res://features/environments/industrial_loop/art/gates/warning_light/warning_light.glb")
## The leaf's line, inside the closing line; the bottom rail and the rack on its inner face.
const LEAF_IN := 0.25
const RAIL := Vector2(0.12, 0.09)
const RAIL_LOW := 0.09
const RACK := Vector2(0.03, 0.022)
## The motor model's pinion: its top above the motor's base, its middle along the motor's turned
## x and its reach toward the leaf (`gate_motor.glb`, turned a quarter so its pinion faces the leaf).
const PINION_TOP := 0.0895
const PINION_ALONG := 0.0377
const PINION_OUT := 0.131
## Behind the opening's edge: the carriages, near and far (both within the tail), and the motor.
const CARRIAGES: Array[float] = [0.35, 2.55]
const MOTOR_BEHIND := 1.35
const CELL_UP := 0.5
const CELL_OUT := 0.3
const LAMP_UP := 1.05
const AMBER := Color(1.0, 0.55, 0.08)
const FLASH_HZ := 1.5

var leaf: AnimatableBody3D
var travel := 6.0
var _wide := 6.0
var _tail := 3.0
var _open := 0.0
var _moving := false
var _forced := false
var _clock := 0.0
var _lamp: OmniLight3D
var _glass: MeshInstance3D
var _lit: StandardMaterial3D
var _dark: StandardMaterial3D


## Builds it: `wide` the opening, `tail` the counterweight tail, its machinery's `concrete`.
func build(wide: float, tail: float, concrete: Material) -> void:
	_wide = wide
	_tail = tail
	travel = wide
	var fence := Fence.new()
	var steel := fence.galvanised
	_leaf(fence, steel)
	_carriages(concrete, steel)
	_drive(concrete)
	_posts(concrete, steel)
	_photocells(steel)
	set_open(0.0)


## Slides the leaf `open` metres back from shut.
func set_open(open: float) -> void:
	_open = clampf(open, 0.0, travel)
	if leaf != null:
		leaf.position = Vector3(-_wide / 2.0 - _open, 0.0, -LEAF_IN)


## Whether it is moving: the warning lamp flashes while it is.
func set_moving(moving: bool) -> void:
	_forced = moving


func moving_now(moving: bool) -> void:
	_moving = moving


func _process(delta: float) -> void:
	var on := _moving or _forced
	_clock = _clock + delta if on else 0.0
	var lit := on and fmod(_clock * FLASH_HZ, 1.0) < 0.5
	if _lamp != null:
		_lamp.visible = lit
		_glass.material_override = _lit if lit else _dark


func _leaf(fence: Fence, steel: Material) -> void:
	leaf = AnimatableBody3D.new()
	leaf.name = "Leaf"
	leaf.sync_to_physics = true
	add_child(leaf)
	var length := _wide + _tail
	var middle := (_wide - _tail) / 2.0
	Build.box(leaf, Vector3(middle, RAIL_LOW + RAIL.x / 2.0, 0.0), Vector3(length, RAIL.x, RAIL.y),
		steel).name = "BottomRail"
	Build.box(leaf, Vector3(middle, Fence.HEIGHT, 0.0), Vector3(length, 0.06, 0.06), steel) \
		.name = "TopRail"
	for x: float in [-_tail, 0.0, _wide / 2.0, _wide]:
		Build.box(leaf, Vector3(x, Fence.HEIGHT / 2.0 + RAIL_LOW / 2.0, 0.0),
			Vector3(0.06, Fence.HEIGHT - RAIL_LOW, 0.06), steel).name = "Stile"
	var bays: Array[Vector2] = [Vector2(-_tail, 0.0), Vector2(0.0, _wide / 2.0),
		Vector2(_wide / 2.0, _wide)]
	for index in range(bays.size()):
		var bay := bays[index]
		var low := Vector3(bay.x, RAIL_LOW + RAIL.x, 0.0)
		var high := Vector3(bay.y, Fence.HEIGHT - 0.03, 0.0)
		if index % 2 == 1:
			low.x = bay.y
			high.x = bay.x
		var brace := Build.box(leaf, (low + high) / 2.0, Vector3(low.distance_to(high), 0.04,
			0.04), steel)
		brace.rotation.z = atan2(high.y - low.y, high.x - low.x)
		brace.name = "Brace%d" % index
	var quad := QuadMesh.new()
	quad.size = Vector2(length, Fence.HEIGHT - RAIL_LOW - RAIL.x)
	Build.instance(leaf, Vector3(middle, (Fence.HEIGHT + RAIL_LOW + RAIL.x) / 2.0, 0.0), quad,
		fence.link).name = "Mesh"
	var pinion := -MOTOR_BEHIND + PINION_ALONG
	var rack := Build.box(leaf, Vector3(pinion + _wide / 2.0 - 0.0, RAIL_LOW + RAIL.x + RACK.y
		/ 2.0, -RAIL.y / 2.0 - RACK.x / 2.0), Vector3(_wide + 0.5, RACK.y, RACK.x),
		Build.material(Color(0.2, 0.2, 0.21), 0.45))
	rack.name = "Rack"
	var shape := BoxShape3D.new()
	shape.size = Vector3(length, Fence.HEIGHT, 0.12)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = Vector3(middle, Fence.HEIGHT / 2.0, 0.0)
	leaf.add_child(collision)


## The two roller carriages on their footing behind the opening, under the bottom rail.
func _carriages(concrete: Material, steel: Material) -> void:
	var from := -_wide / 2.0 - CARRIAGES[1] - 0.4
	var to := -_wide / 2.0 - CARRIAGES[0] + 0.4
	Build.box(self, Vector3((from + to) / 2.0, 0.025, -LEAF_IN), Vector3(to - from, 0.05, 0.5),
		concrete).name = "CarriageFooting"
	for index in range(CARRIAGES.size()):
		var carriage := Node3D.new()
		carriage.name = "RollerCarriage%d" % index
		carriage.position = Vector3(-_wide / 2.0 - CARRIAGES[index], 0.05, -LEAF_IN)
		add_child(carriage)
		Build.box(carriage, Vector3(0, 0.005, 0), Vector3(0.32, 0.01, 0.22), steel)
		for side in [-1.0, 1.0]:
			Build.box(carriage, Vector3(0, 0.025, side * 0.075), Vector3(0.28, 0.035, 0.012), steel)
		for along in [-0.08, 0.08]:
			var wheel := Build.cylinder(carriage, Vector3(along, RAIL_LOW - 0.05 - 0.02, 0), 0.02,
				0.06, Build.material(Color(0.15, 0.15, 0.16), 0.5))
			wheel.rotation.x = PI / 2.0
			wheel.name = "Roller"


## The motor on its plinth inside the fence, its pinion under the rack.
func _drive(concrete: Material) -> void:
	var rack_low := RAIL_LOW + RAIL.x
	var plinth_top := rack_low - PINION_TOP
	var at := Vector3(-_wide / 2.0 - MOTOR_BEHIND, 0.0,
		-LEAF_IN - RAIL.y / 2.0 - RACK.x / 2.0 - PINION_OUT)
	Build.box(self, Vector3(at.x, plinth_top / 2.0, at.z), Vector3(0.4, plinth_top, 0.4),
		concrete).name = "MotorPlinth"
	var motor := MOTOR.instantiate() as Node3D
	motor.name = "Motor"
	motor.position = Vector3(at.x, plinth_top, at.z)
	motor.rotation.y = -PI / 2.0
	add_child(motor)


## The guide post (its rollers holding the top rail, the warning lamp on it) and the receiver post
## at the closing end.
func _posts(concrete: Material, steel: Material) -> void:
	var guide_x := -_wide / 2.0 - 0.15
	for side in [-1.0, 1.0]:
		Build.box(self, Vector3(guide_x, Fence.HEIGHT / 2.0, -LEAF_IN + side * 0.13),
			Vector3(0.08, Fence.HEIGHT + 0.1, 0.08), steel).name = "GuidePost"
		var roller := Build.cylinder(self, Vector3(guide_x, Fence.HEIGHT, -LEAF_IN + side * 0.052),
			0.022, 0.05, Build.material(Color(0.15, 0.15, 0.16), 0.5))
		roller.name = "GuideRoller"
	var receiver := Node3D.new()
	receiver.name = "ReceiverPost"
	receiver.position = Vector3(_wide / 2.0 + 0.12, 0.0, -LEAF_IN)
	add_child(receiver)
	Build.box(receiver, Vector3(0, Fence.HEIGHT / 2.0, 0), Vector3(0.1, Fence.HEIGHT, 0.1), steel)
	for side in [-1.0, 1.0]:
		Build.box(receiver, Vector3(-0.08, 0.3, side * 0.07), Vector3(0.1, 0.3, 0.012), steel) \
			.name = "Catcher"
	var lamp := LAMP.instantiate() as Node3D
	lamp.name = "WarningLight"
	lamp.position = Vector3(guide_x, LAMP_UP, -LEAF_IN - 0.13 - 0.04)
	lamp.rotation.y = PI / 2.0
	add_child(lamp)
	_glass = lamp.find_child("glasse_old_0", true, false) as MeshInstance3D
	_dark = Build.material(Color(0.75, 0.45, 0.15, 0.6), 0.2)
	_dark.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_lit = Build.luminous(AMBER, 3.0)
	_lamp = OmniLight3D.new()
	_lamp.name = "WarningLamp"
	_lamp.light_color = AMBER
	_lamp.light_energy = 1.2
	_lamp.omni_range = 6.0
	_lamp.shadow_enabled = false
	_lamp.visible = false
	add_child(_lamp)
	_lamp.global_position = _glass.global_transform * _glass.get_aabb().get_center()


## Photocells on short posts either side of the opening, outside the line, facing each other.
func _photocells(steel: Material) -> void:
	var housing := Build.material(Color(0.88, 0.88, 0.86), 0.45)
	for side in [-1.0, 1.0]:
		var x: float = side * (_wide / 2.0 + 0.2)
		Build.box(self, Vector3(x, CELL_UP / 2.0, CELL_OUT), Vector3(0.06, CELL_UP, 0.06), steel) \
			.name = "CellPost"
		var cell := Node3D.new()
		cell.name = "Photocell%d" % (0 if side < 0.0 else 1)
		cell.position = Vector3(x, CELL_UP + 0.05, CELL_OUT)
		add_child(cell)
		cell.basis = Basis.looking_at(Vector3(-side, 0, 0))
		Build.box(cell, Vector3.ZERO, Vector3(0.05, 0.1, 0.035), housing)
		Build.box(cell, Vector3(0, 0.01, -0.019), Vector3(0.03, 0.03, 0.002),
			Build.material(Color(0.6, 0.05, 0.04), 0.1)).name = "Lens"
