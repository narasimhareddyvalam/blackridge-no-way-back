extends Node3D
## The way onto the transfer shed's dock floor on foot (docs/PHASE_BRIEF.md, step 2e, rule H8): a
## steel pedestrian door in the shed's east wall beside the drive-in lane, which E swings open,
## outward as an exit door does, with a wall light over it; inside, a concrete stair with yellow
## nosings from the lane up to the dock floor beside bay 9, its rail on the open side, and a
## guardrail along the dock's edge above the lane. A driver walks onto a dock; he never climbs its
## face. The building cuts the door's opening (DOOR) in its east wall. Underfoot the stair is one
## hidden incline along its nosings, as a studio builds a stair's collision, so that Ethan walks up
## it without a jolt; his feet take its treads by `stair()` (`stair_steps.gd`, #245–#246).

const Build = preload("res://shared/components/mesh_builder.gd")
const DOOR := Rect2(17.0, 0.0, 0.95, 2.13)
const WALL_X := -40.0
const OPEN_ANGLE := 95.0
const OPEN_SECONDS := 0.8
const STAIR := Rect2(-44.7, 12.92, 1.0, 2.25)
const RISERS := 6
const TREAD := 0.25
const LANDING := 1.0
const DOCK_FLOOR := 1.3
const EDGE_X := -44.76
const BACK_Z := -9.75
const FRONT_Z := 19.75
const RAIL := 1.07
const REACH := 1.3
const INCLINE_THICK := 0.3

var door_open := false

var _leaf: Node3D
var _swing := 0.0


func build(concrete: Material, steel: Material) -> void:
	var paint := Build.material(Color(0.86, 0.66, 0.08), 0.45)
	_door(steel)
	_stair(concrete, paint)
	_rails(paint)


func open_door() -> void:
	door_open = true


func reset() -> void:
	door_open = false
	_swing = 0.0
	if _leaf != null:
		_leaf.rotation.y = 0.0


## The stair, as Ethan's feet take it (`stair_steps.gd`), in the world: the middle of its first
## riser's foot, its way up and across, its rise, tread and risers (the last up onto the landing),
## its width and the landing's depth.
func stair() -> Dictionary:
	var up := (global_basis * Vector3.FORWARD).normalized()
	return {"foot": to_global(Vector3(STAIR.get_center().x, 0.0, STAIR.end.y)), "up": up,
		"across": Vector3.UP.cross(up).normalized(), "rise": DOCK_FLOOR / RISERS, "tread": TREAD,
		"risers": RISERS, "width": STAIR.size.x, "landing": LANDING}


## The top of the stair's rail on its open side, in the world: at the flight's foot and at its
## top, where it turns along the landing (`_rails()`).
func rail_top() -> Array[Vector3]:
	var side_x := STAIR.end.x + 0.05
	return [to_global(Vector3(side_x, RAIL, STAIR.end.y - 0.1)),
		to_global(Vector3(side_x, DOCK_FLOOR + RAIL, STAIR.position.y + LANDING))]


## How far the door has swung open, 0 shut to 1 open.
func swung() -> float:
	return _swing


func near_door(at: Vector3) -> bool:
	return Vector2(at.x - WALL_X, at.z - DOOR.get_center().x).length() < REACH


func _physics_process(delta: float) -> void:
	var wanted := 1.0 if door_open else 0.0
	if is_equal_approx(_swing, wanted) or _leaf == null:
		return
	_swing = move_toward(_swing, wanted, delta / OPEN_SECONDS)
	_leaf.rotation.y = deg_to_rad(OPEN_ANGLE) * smoothstep(0.0, 1.0, _swing)


func _door(steel: Material) -> void:
	var frame := Build.material(Color(0.22, 0.24, 0.26), 0.5)
	var z0 := DOOR.position.x
	var z1 := DOOR.end.x
	for z: float in [z0 + 0.025, z1 - 0.025]:
		Build.box(self, Vector3(WALL_X + 0.02, DOOR.size.y / 2.0, z), Vector3(0.06, DOOR.size.y,
			0.05), frame).name = "SideDoorFrame"
	Build.box(self, Vector3(WALL_X + 0.02, DOOR.size.y + 0.025, DOOR.get_center().x), Vector3(0.06,
		0.05, DOOR.size.x + 0.05), frame).name = "SideDoorFrame"
	_leaf = Node3D.new()
	_leaf.name = "SideDoorLeaf"
	_leaf.position = Vector3(WALL_X + 0.03, 0.0, z0 + 0.05)
	add_child(_leaf)
	var width := DOOR.size.x - 0.1
	var height := DOOR.size.y - 0.04
	Build.box(_leaf, Vector3(-0.0225, height / 2.0 + 0.01, width / 2.0), Vector3(0.045, height,
		width), steel).name = "SideDoorPanel"
	Build.box(_leaf, Vector3(0.02, 1.02, width - 0.08), Vector3(0.04, 0.03, 0.14),
		Build.material(Color(0.7, 0.72, 0.74), 0.3)).name = "SideDoorHandle"
	var body := StaticBody3D.new()
	body.name = "SideDoorBody"
	_leaf.add_child(body)
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.12, height, width)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = Vector3(-0.06, height / 2.0 + 0.01, width / 2.0)
	body.add_child(collision)
	Build.box(self, Vector3(WALL_X + 0.09, DOOR.size.y + 0.38, DOOR.get_center().x), Vector3(0.16,
		0.12, 0.24), frame).name = "SideDoorLamp"
	var lamp := OmniLight3D.new()
	lamp.name = "SideDoorLight"
	lamp.position = Vector3(WALL_X + 0.25, DOOR.size.y + 0.3, DOOR.get_center().x)
	lamp.light_color = Color(1.0, 0.95, 0.86)
	lamp.light_energy = 1.2
	lamp.omni_range = 6.0
	lamp.shadow_enabled = false
	add_child(lamp)


func _stair(concrete: Material, paint: Material) -> void:
	var body := StaticBody3D.new()
	body.name = "DockStair"
	add_child(body)
	var rise := DOCK_FLOOR / RISERS
	var x := STAIR.get_center().x
	var foot := STAIR.end.y
	for step in range(1, RISERS):
		var top := rise * step
		var z := foot - (step - 0.5) * TREAD
		Build.box(self, Vector3(x, top / 2.0, z), Vector3(STAIR.size.x, top, TREAD),
			concrete).name = "DockStairStep"
		Build.box(self, Vector3(x, top + 0.003, z + TREAD / 2.0 - 0.04), Vector3(STAIR.size.x,
			0.006, 0.06), paint).name = "DockStairNosing"
	_incline(body, x, foot)
	var landing_z := STAIR.position.y + LANDING / 2.0
	_solid(body, Vector3(x, DOCK_FLOOR / 2.0, landing_z), Vector3(STAIR.size.x, DOCK_FLOOR,
		LANDING), concrete, "DockStairLanding")


## The stair's one hidden collision: an incline along its nosings, from the floor a tread before
## the first riser up to the landing's edge.
func _incline(body: StaticBody3D, x: float, foot: float) -> void:
	var run := TREAD * RISERS
	var slope := atan2(DOCK_FLOOR, run)
	var shape := BoxShape3D.new()
	shape.size = Vector3(STAIR.size.x, INCLINE_THICK, Vector2(run, DOCK_FLOOR).length())
	var incline := CollisionShape3D.new()
	incline.name = "DockStairIncline"
	incline.shape = shape
	var surface := Vector3(x, DOCK_FLOOR / 2.0, foot + TREAD - run / 2.0)
	incline.position = surface - Vector3(0.0, cos(slope), sin(slope)) * INCLINE_THICK / 2.0
	incline.rotation.x = slope
	body.add_child(incline)


func _rails(paint: Material) -> void:
	var body := StaticBody3D.new()
	body.name = "DockRails"
	add_child(body)
	var side_x := STAIR.end.x + 0.05
	var top := DOCK_FLOOR + RAIL
	_post_and_rail(Vector3(side_x, 0.0, STAIR.end.y - 0.1), Vector3(side_x, DOCK_FLOOR,
		STAIR.position.y + LANDING), paint)
	_post_and_rail(Vector3(side_x, DOCK_FLOOR, STAIR.position.y + LANDING), Vector3(side_x,
		DOCK_FLOOR, STAIR.position.y + 0.05), paint)
	_post_and_rail(Vector3(STAIR.position.x, DOCK_FLOOR, STAIR.position.y + 0.03), Vector3(side_x,
		DOCK_FLOOR, STAIR.position.y + 0.03), paint)
	_wall_stop(body, Vector3(side_x, 1.3, STAIR.get_center().y), Vector3(0.06, 2.6, STAIR.size.y))
	_wall_stop(body, Vector3(STAIR.get_center().x, top - RAIL / 2.0, STAIR.position.y + 0.03),
		Vector3(STAIR.size.x + 0.1, RAIL, 0.06))
	for run: Vector2 in [Vector2(BACK_Z, STAIR.position.y),
			Vector2(STAIR.position.y + LANDING, FRONT_Z)]:
		_post_and_rail(Vector3(EDGE_X, DOCK_FLOOR, run.x), Vector3(EDGE_X, DOCK_FLOOR, run.y),
			paint)
		_wall_stop(body, Vector3(EDGE_X, top - RAIL / 2.0, (run.x + run.y) / 2.0),
			Vector3(0.06, RAIL, run.y - run.x))


func _post_and_rail(from: Vector3, to: Vector3, paint: Material) -> void:
	var length := Vector2(to.x - from.x, to.z - from.z).length()
	var posts := maxi(2, ceili(length / 2.0) + 1)
	for index in range(posts):
		var at := from.lerp(to, float(index) / float(posts - 1))
		Build.cylinder(self, at + Vector3.UP * RAIL / 2.0, 0.022, RAIL, paint).name = \
			"DockRailPost"
	for height: float in [RAIL, RAIL / 2.0]:
		var a := from + Vector3.UP * height
		var b := to + Vector3.UP * height
		var rail := Build.box(self, (a + b) / 2.0, Vector3(0.04, 0.04, a.distance_to(b)), paint)
		rail.look_at(b, Vector3.UP if absf((b - a).normalized().y) < 0.99 else Vector3.FORWARD)
		rail.name = "DockRail"


func _solid(body: StaticBody3D, at: Vector3, size: Vector3, surface: Material,
		label: String) -> void:
	Build.box(self, at, size, surface).name = label
	_wall_stop(body, at, size)


func _wall_stop(body: StaticBody3D, at: Vector3, size: Vector3) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = at
	body.add_child(collision)
