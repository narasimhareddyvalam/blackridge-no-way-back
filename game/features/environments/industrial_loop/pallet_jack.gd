extends Node
## Bay 9's pallet jack in Ethan's hands (docs/PHASE_BRIEF.md, step 2e, rules H2 and H9; the
## author's L1 c, #230): E at its handle takes it, lifting the load its forks are under; W and S
## push and pull it, going where his feet take it (his push gait, #239-#240), and A and D steer
## it as it rolls, turning it about its middle; E sets the load down, and E again lets go. He
## takes it close to its handle, and as he gets going it runs out to his arm's length, both his
## hands on its handle's loop. Its handle tilts down to his hands as a real one does, and springs
## back upright when he lets go; its steering unit turns as he steers (step 2f, #244). It is
## taken only where Ethan has room to stand behind its handle.
## Each step is tried before it is
## taken, and one that would put the jack or its load into a wall, a rail, another load, the
## pit's sides or the van's sides is not taken. Lined up with a docked van whose floor the lift
## has reached, the load may go into the hold, Ethan walking in behind it, stooped under the low
## roof (the author's choice, #231), as far as the bulkhead; set down there it goes with the van,
## which settles under its weight, and E beside it straps it down. The jack's forks slide under a
## load, whose solid box starts above them.

signal changed

const HANDLE := Vector3(0.0, 1.05, 0.72)
const LIFT_DECK := Vector2(1.83, 2.44)
const PALMS: Array[Vector3] = [Vector3(-0.173, 0.79, 0.0), Vector3(0.173, 0.79, 0.0)]
const TILLER_FOOT := Vector2(0.30, 0.76)
const ROD := 0.017
const LOOP: Array[Vector3] = [Vector3(0.0, 0.05, 0.0), Vector3(0.0, 0.65, 0.0),
	Vector3(-0.13, 0.65, 0.0), Vector3(-0.19, 0.8, 0.0), Vector3(-0.08, 0.9, 0.0),
	Vector3(0.08, 0.9, 0.0), Vector3(0.19, 0.8, 0.0), Vector3(0.13, 0.65, 0.0),
	Vector3(0.0, 0.65, 0.0)]
const TILT_MOST := deg_to_rad(80.0)
const TILT_RATE := 1.5
const STEER_SWING := deg_to_rad(25.0)
const STEER_RATE := 2.0
const GRIP_BACK := 1.17
const PUSH_REACH := 1.45
const VAN_REACH := 1.65
const PULL_REACH := 1.25
const REACH_SPARE := 0.1
const LEAD_GAIN := 4.0
const LEAD_MOST := 2.0
const LAG_MOST := 0.5
const LOAD_AHEAD := 0.25
const FORKS_AHEAD := 0.2
const TURN_PER_METRE := 1.333
const LIFT := 0.04
const REACH := 0.9
const FORKS := [Vector3(0.7, 0.07, 1.2), Vector3(0.0, 0.045, -0.2)]
const BODY := [Vector3(0.62, 1.1, 0.42), Vector3(0.0, 0.6, 0.6)]
const SKIN := 0.1
const LEVEL := 0.03
const HOLD := Rect2(-0.867, -0.25, 1.734, 2.99)
const VAN_REAR := 3.012
const VAN_FLOOR := 0.614
const HOLD_ROOF := 1.536
const ALL_BUT_CAMERA := 0xFFFFFFFF & ~8
const REAR_DOOR := Vector2(0.66, 1.45)
const HEAD_ROOM := 0.01
const BY_THE_DOOR := 0.7
const VAN_SIDE := 1.1
const CLEAR := 0.35
const STOOP_FROM := 1.8
const STOOP_OUT := 0.5
const FORK_TIPS := 0.8
const AGAINST := 0.1
const STAND := 0.3
const DOOR_CLEAR := 0.05
const LOAD_HALF := Vector2(0.535, 0.61)
const LOAD_KG := 520.0
const STRAP_REACH := 1.35
const RADIUS := 0.3
const STRAP := Color(0.9, 0.48, 0.1)
const STRAP_AT: Array[float] = [-0.32, 0.32]

var held := false
var jack: Node3D
var carried: Node3D
var driver: CharacterBody3D
var van: CharacterBody3D

var _loads: Array[Node3D] = []
var _homes := {}
var _building: Node3D
var _lift: Node3D
var _reach := GRIP_BACK
var _steering: Node3D
var _tiller: Node3D
var _query := PhysicsShapeQueryParameters3D.new()
var _box := BoxShape3D.new()
var _stand := PhysicsShapeQueryParameters3D.new()
var _capsule := CapsuleShape3D.new()


func setup(jack_node: Node3D, loads: Array[Node3D], building: Node3D, lift: Node3D) -> void:
	jack = jack_node
	_steering = jack.get_node_or_null("Steering") as Node3D
	_tiller = jack.get_node_or_null("Steering/Tiller") as Node3D
	_loads = loads
	_building = building
	_lift = lift
	for stack in loads:
		_homes[stack] = stack.transform
	_query.shape = _box
	_query.collision_mask = ALL_BUT_CAMERA
	_capsule.radius = RADIUS
	_stand.shape = _capsule
	_stand.collision_mask = ALL_BUT_CAMERA


## The van it may load: neither the jack nor any load ever pushes it, and a load in its hold has
## no collision of its own, so the van drives and turns as before.
func watch(body: CharacterBody3D) -> void:
	van = body
	for holder: Node3D in [jack] + _loads:
		for found in holder.find_children("*", "CollisionObject3D", true, false):
			van.add_collision_exception_with(found as CollisionObject3D)


## The jack back at `start` and every load back where it was staged, unstrapped, as the mission
## starts again.
func reset(start: Transform3D) -> void:
	if held:
		let_go()
	carried = null
	_reparent(jack, _building)
	jack.global_transform = start
	_rest_handle()
	for stack in _loads:
		_reparent(stack, _building)
		stack.transform = _homes[stack]
		_solid(stack, true)
		for strap_node in stack.find_children("LoadStrap*", "Node3D", false, false):
			strap_node.free()
		stack.remove_meta("strapped")


## `stack` loaded as the jack would leave it: in the van's hold forward against the bulkhead,
## on its floor, strapped down, its weight on the van (a reload at Mission 2's stage 1, H6).
func stow(stack: Node3D) -> void:
	if not is_instance_valid(van):
		return
	var depth := HOLD.position.y + LOAD_HALF.y + 0.002
	_reparent(stack, van)
	stack.transform = Transform3D(Basis.IDENTITY, Vector3(0.0, VAN_FLOOR, depth))
	_solid(stack, false)
	van.call("add_load", LOAD_KG, depth)
	_strap(stack)


func heading() -> Vector2:
	var ahead := _ahead(jack.global_transform)
	return Vector2(ahead.x, ahead.z)


func load_centre() -> Vector2:
	var at := jack.global_position + _ahead(jack.global_transform) * (LOAD_AHEAD if carried
		!= null else FORKS_AHEAD)
	return Vector2(at.x, at.z)


func handle() -> Vector3:
	return jack.to_global(HANDLE)


## How far Ethan at `at` is from the handle, across the floor, or INF on another level.
func reach(at: Vector3) -> float:
	var grip := handle()
	if absf(at.y - jack.global_position.y) > 0.4:
		return INF
	return Vector2(at.x - grip.x, at.z - grip.z).length()


func action(at: Vector3) -> String:
	if held:
		if carried != null:
			return _set_down_text()
		if can_strap(at):
			return "Strap the load"
		return "Pull the jack out first" if _in_van() else "Let go of the jack"
	if reach(at) >= REACH:
		return ""
	return "Take the pallet jack" if _room_behind() else ""


## A load set down in the van's hold, not yet strapped, with Ethan in the hold beside it.
func can_strap(at: Vector3) -> bool:
	var stack := _unstrapped()
	if stack == null or carried != null or not _inside_van(at):
		return false
	var back := van.to_local(stack.global_position).z + LOAD_HALF.y
	return van.to_local(at).z - back < STRAP_REACH


## Two ratchet straps over the load in the hold, each from a floor ring across its top to the
## floor ring opposite.
func strap() -> void:
	var stack := _unstrapped()
	if stack != null:
		_strap(stack)


func _strap(stack: Node3D) -> void:
	var size := _load_size(stack)
	var webbing := StandardMaterial3D.new()
	webbing.albedo_color = STRAP
	webbing.roughness = 0.8
	for index in range(STRAP_AT.size()):
		var strap_node := Node3D.new()
		strap_node.name = "LoadStrap%d" % (index + 1)
		stack.add_child(strap_node)
		var z := STRAP_AT[index]
		for side: float in [-1.0, 1.0]:
			_strip(strap_node, Vector3(side * (size.x / 2.0 + 0.005), size.y / 2.0, z),
				Vector3(0.004, size.y, 0.05), webbing)
		_strip(strap_node, Vector3(0.0, size.y + 0.004, z), Vector3(size.x + 0.01, 0.004, 0.05),
			webbing)
	stack.set_meta("strapped", true)
	changed.emit()


## The load in the van's hold, if there is one.
func in_van() -> Node3D:
	for stack in _loads:
		if is_instance_valid(van) and van.is_ancestor_of(stack):
			return stack
	return null


## The load set down on the lift's deck, waiting to ride it down or to be rolled into the van; else
## null.
func on_lift() -> Node3D:
	if not is_instance_valid(_lift):
		return null
	for stack in _loads:
		if stack == carried or (is_instance_valid(van) and van.is_ancestor_of(stack)):
			continue
		var at := _lift.to_local(stack.global_position)
		if absf(at.x) <= LIFT_DECK.x / 2.0 and absf(at.z) <= LIFT_DECK.y / 2.0 \
				and at.y > -0.05 and at.y < 0.4:
			return stack
	return null


func _unstrapped() -> Node3D:
	var stack := in_van()
	return stack if stack != null and not stack.has_meta("strapped") else null


func _strip(parent: Node3D, at: Vector3, size: Vector3, surface: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var piece := MeshInstance3D.new()
	piece.mesh = mesh
	piece.material_override = surface
	piece.position = at
	parent.add_child(piece)


func take() -> void:
	if not _room_behind():
		return
	held = true
	_reach = GRIP_BACK
	driver.set("pushing", true)
	var at := _grip_spot(jack.global_transform)
	driver.global_position = Vector3(at.x, driver.global_position.y, at.z)
	carried = _load_on_forks()
	if carried != null:
		if _inside_van(carried.global_position) and is_instance_valid(van):
			van.call("remove_load", LOAD_KG, van.to_local(carried.global_position).z)
		_solid(carried, true)
		_reparent(carried, _building)
		_reparent(jack, _building)
		carried.global_transform = _load_pose(jack.global_transform)
	else:
		_reparent(jack, _building)
	changed.emit()


func set_down() -> void:
	if carried == null:
		return
	var pose := carried.global_transform
	pose.origin.y -= LIFT
	carried.global_transform = pose
	if _inside_van(pose.origin):
		_reparent(carried, van)
		_solid(carried, false)
		van.call("add_load", LOAD_KG, van.to_local(pose.origin).z)
	else:
		_reparent(carried, _on_what(pose.origin))
	carried = null
	changed.emit()


func let_go() -> void:
	held = false
	if is_instance_valid(driver):
		driver.set("pushing", false)
		driver.set("stooping", false)
		driver.call("keep_clear_of", PackedVector3Array(), 0.0)
		if is_instance_valid(van):
			driver.call("pass_through", van, false)
	_reparent(jack, _on_what(jack.global_position))
	_rest_handle()
	changed.emit()


## Each physics frame his push gait says how far his feet carry him and how far the jack goes with
## him; the jack goes there if it can, turned about its middle by A and D as it rolls, he keeping
## behind its handle, or else stays against what stopped it while he finishes his steps.
func _physics_process(delta: float) -> void:
	if not held or not is_instance_valid(driver):
		return
	var steer := Input.get_axis("steer_right", "steer_left")
	var drive := Input.get_action_strength("accelerate") - Input.get_action_strength("brake")
	var pose := jack.global_transform
	var ahead := _ahead(pose)
	var arms := VAN_REACH if bool(driver.get("stooping")) else (PULL_REACH if drive < 0.0
		else PUSH_REACH)
	var lead := clampf((arms - _reach) * LEAD_GAIN, -LAG_MOST, LEAD_MOST)
	var slack := maxf(_reach - GRIP_BACK, 0.0)
	var moved: Vector2 = driver.call("push_gait", drive, lead, slack, delta)
	var feet := moved.x
	var carry := moved.y
	var chosen := pose
	if not is_zero_approx(carry):
		var free := false
		for turn: float in [steer * TURN_PER_METRE * absf(carry), 0.0]:
			var candidate := Transform3D(Basis(Vector3.UP, turn) * pose.basis,
				pose.origin + ahead * carry)
			if not _blocked(candidate):
				chosen = candidate
				free = true
				break
		if not free:
			carry = 0.0
			driver.call("push_blocked")
	var after := clampf(_reach + carry - feet, GRIP_BACK - REACH_SPARE / 5.0,
		VAN_REACH + REACH_SPARE)
	var heading := _ahead(chosen)
	var spot := chosen.origin - heading * after
	_enter(chosen, drive)
	driver.call("push_step", spot - driver.global_position, heading, delta)
	if not is_zero_approx(carry):
		var follows := driver.global_position + heading * after
		follows.y = pose.origin.y
		jack.global_transform = Transform3D(chosen.basis, follows)
	var apart := jack.global_position - driver.global_position
	_reach = Vector2(apart.x, apart.z).dot(Vector2(heading.x, heading.z))
	if carried != null:
		carried.global_transform = _load_pose(jack.global_transform)
	_turn_handle(steer, delta)
	var hand: Node3D = _tiller if _tiller != null else jack
	var bars: Array[Vector3] = [hand.global_basis * (LOOP[3] - LOOP[2]),
		hand.global_basis * (LOOP[6] - LOOP[7])]
	driver.call("hold_handle", hand.to_global(PALMS[0]), hand.to_global(PALMS[1]), bars)
	var roof := {}
	if is_instance_valid(van):
		roof = {"space": van.global_transform, "roof": VAN_FLOOR + HOLD_ROOF - HEAD_ROOM,
			"door": REAR_DOOR.x + REAR_DOOR.y - HEAD_ROOM, "rear": VAN_REAR, "side": VAN_SIDE,
			"by_door": BY_THE_DOOR}
	driver.call("keep_clear_of", _handle_pieces(hand), ROD, roof)


## The handle's rod and loop as straight pieces in the world, in pairs of ends: its rod from
## the steering unit up, and round its loop, as the model's handle is drawn.
func _handle_pieces(hand: Node3D) -> PackedVector3Array:
	var pieces := PackedVector3Array()
	pieces.append_array([hand.to_global(LOOP[0]), hand.to_global(LOOP[1])])
	for index in range(2, LOOP.size() - 1):
		pieces.append_array([hand.to_global(LOOP[index]), hand.to_global(LOOP[index + 1])])
	return pieces


## The handle tilted down toward where Ethan's hands are in the clip he plays, about its foot, as
## far as a real one goes, or upright when his hands are off it; the steering unit under it
## turned with A and D.
func _turn_handle(steer: float, delta: float) -> void:
	if _tiller == null or _steering == null:
		return
	var tilt := 0.0
	if float(driver.call("hands_on_handle")) > 0.5:
		var grip: Vector2 = driver.call("push_grip")
		tilt = clampf(atan2(_reach - grip.x - TILLER_FOOT.y, grip.y - TILLER_FOOT.x), 0.0,
			TILT_MOST)
	_tiller.rotation.x = move_toward(_tiller.rotation.x, tilt, TILT_RATE * delta)
	_steering.rotation.y = move_toward(_steering.rotation.y, -steer * STEER_SWING,
		STEER_RATE * delta)


## Let go of, the handle springs back upright and the steering unit straightens.
func _rest_handle() -> void:
	if _tiller == null or _steering == null:
		return
	var spring := _tiller.create_tween().set_parallel()
	spring.tween_property(_tiller, "rotation:x", 0.0, 0.35)
	spring.tween_property(_steering, "rotation:y", 0.0, 0.35)


func _blocked(pose: Transform3D) -> bool:
	var exclude: Array[RID] = [driver.get_rid()]
	for body in jack.find_children("*", "CollisionObject3D", true, false):
		exclude.append((body as CollisionObject3D).get_rid())
	if carried != null:
		for body in carried.find_children("*", "CollisionObject3D", true, false):
			exclude.append((body as CollisionObject3D).get_rid())
	if _lined_up(pose):
		exclude.append(van.get_rid())
	if _lift != null and bool(_lift.call("lip_down")):
		exclude.append(_lift.call("lip_body"))
	_query.exclude = exclude
	var space := jack.get_world_3d().direct_space_state
	for part: Array in [FORKS, BODY]:
		_box.size = part[0]
		_query.transform = pose * Transform3D(Basis.IDENTITY, part[1])
		if not space.intersect_shape(_query, 1).is_empty():
			return true
	if carried != null:
		var size := _load_size(carried)
		_box.size = Vector3(size.x, size.y - SKIN, size.z)
		_query.transform = _load_pose(pose) * Transform3D(Basis.IDENTITY,
			Vector3.UP * (SKIN + (size.y - SKIN) / 2.0))
		if not space.intersect_shape(_query, 1).is_empty():
			return true
	return false


## At a docked van's open rear, on its floor's level, with the jack and its load inside the
## hold's width, so they can only be behind the van or in its hold, whose own walls, arches and
## bulkhead then guide them.
func _lined_up(pose: Transform3D) -> bool:
	if not is_instance_valid(van) or not bool(van.get("rear_doors_open")):
		return false
	var floor_y := van.to_global(Vector3(0.0, VAN_FLOOR, 0.0)).y
	if absf(pose.origin.y - floor_y) > LEVEL:
		return false
	for corner in _footprint(pose):
		if absf(van.to_local(corner).x) > HOLD.end.x:
			return false
	return true


## The corners of the jack's forks and body and of the load on them, at `pose`.
func _footprint(pose: Transform3D) -> Array[Vector3]:
	var corners: Array[Vector3] = []
	for part: Array in [FORKS, BODY]:
		var half: Vector3 = part[0] / 2.0
		for x: float in [-half.x, half.x]:
			for z: float in [-half.z, half.z]:
				corners.append(pose * (part[1] + Vector3(x, 0.0, z)))
	if carried != null:
		var load_pose := _load_pose(pose)
		for x: float in [-LOAD_HALF.x, LOAD_HALF.x]:
			for z: float in [-LOAD_HALF.y, LOAD_HALF.y]:
				corners.append(load_pose * Vector3(x, 0.0, z))
	return corners


## What E does with the load on the forks: in the hold it goes down only forward against the
## bulkhead, as loads in vans go; outside, only clear of the van.
func _set_down_text() -> String:
	if not is_instance_valid(van):
		return "Set the pallet down"
	var centre := carried.global_position
	var local := van.to_local(centre)
	var depth := LOAD_HALF.y
	if _inside_van(centre) and local.z < HOLD.end.y - depth - DOOR_CLEAR:
		return "Set the pallet down" if local.z - depth - HOLD.position.y < AGAINST \
			else "Push it in against the bulkhead first"
	if local.z > VAN_REAR + depth or absf(local.x) > HOLD.end.x + LOAD_HALF.x:
		return "Set the pallet down"
	return "Push it fully in or out first"


## Lets Ethan into the van's hold behind the jack, lined up with its open rear, and stoops him
## before its low roof: 1.8 m before it as he pushes in, slowing to its pace by the doors, and
## until his head is clear of them as he pulls out; the hold's own walls, floor and roof then
## hold him.
func _enter(pose: Transform3D, drive: float = 0.0) -> void:
	if not is_instance_valid(van):
		return
	var standing := van.to_local(driver.global_position)
	var near := absf(standing.x) < VAN_SIDE and standing.z < VAN_REAR + CLEAR
	var entering := _lined_up(pose) or near
	driver.call("pass_through", van, entering)
	driver.set("stooping", entering and absf(standing.x) < VAN_SIDE
		and standing.z < VAN_REAR + (STOOP_OUT if drive < 0.0 else STOOP_FROM))


## Whether the jack's forks or Ethan are still in the van, so neither may be left there.
func _in_van() -> bool:
	if not is_instance_valid(van):
		return false
	var tips := van.to_local(jack.global_position + _ahead(jack.global_transform) * FORK_TIPS)
	var standing := van.to_local(driver.global_position)
	return (absf(tips.x) < VAN_SIDE and tips.z < VAN_REAR) \
		or (absf(standing.x) < VAN_SIDE and standing.z < VAN_REAR + CLEAR)


func _grip_spot(pose: Transform3D) -> Vector3:
	return pose.origin - _ahead(pose) * GRIP_BACK


## Whether Ethan can stand behind the handle where taking the jack puts him: a floor under that
## spot at his level, and room there for him.
func _room_behind() -> bool:
	if not is_instance_valid(driver):
		return false
	var spot := _grip_spot(jack.global_transform)
	spot.y = driver.global_position.y
	var exclude: Array[RID] = [driver.get_rid()]
	for holder: Node3D in [jack] + _loads:
		for body in holder.find_children("*", "CollisionObject3D", true, false):
			exclude.append((body as CollisionObject3D).get_rid())
	var space := jack.get_world_3d().direct_space_state
	var ray := PhysicsRayQueryParameters3D.create(spot + Vector3.UP * STAND,
		spot + Vector3.DOWN * STAND)
	ray.collision_mask = ALL_BUT_CAMERA
	ray.exclude = exclude
	var hit := space.intersect_ray(ray)
	if hit.is_empty():
		return false
	var height := _driver_height()
	_capsule.height = height
	_stand.transform = Transform3D(Basis.IDENTITY, Vector3(spot.x, (hit["position"] as Vector3).y
		+ height / 2.0 + 0.02, spot.z))
	_stand.exclude = exclude
	return space.intersect_shape(_stand, 1).is_empty()


func _driver_height() -> float:
	for found in driver.get_children():
		if found is CollisionShape3D and (found as CollisionShape3D).shape is CapsuleShape3D:
			return ((found as CollisionShape3D).shape as CapsuleShape3D).height
	return 1.8


func _inside_van(point: Vector3) -> bool:
	if not is_instance_valid(van):
		return false
	var local := van.to_local(point)
	return HOLD.has_point(Vector2(local.x, local.z)) and local.y > 0.0 and local.y < 2.2


func _on_what(point: Vector3) -> Node3D:
	var on_deck := _lift.to_local(point)
	if absf(on_deck.x) < 0.95 and absf(on_deck.z) < 1.25 and absf(on_deck.y) < 0.15:
		return _lift
	return _building


func _load_on_forks() -> Node3D:
	var forks := jack.global_position + _ahead(jack.global_transform) * FORKS_AHEAD
	for stack in _loads:
		var local := stack.to_local(forks)
		if absf(local.x) < 0.5 and absf(local.z) < 0.6 and absf(local.y) < 0.12:
			return stack
	return null


func _load_pose(pose: Transform3D) -> Transform3D:
	var ahead := _ahead(pose)
	return Transform3D(Basis(Vector3.UP, atan2(ahead.x, ahead.z)),
		pose.origin + ahead * LOAD_AHEAD + Vector3.UP * LIFT)


func _load_size(stack: Node3D) -> Vector3:
	var body := stack.get_node("LoadBody/Shape") as CollisionShape3D
	var size := (body.shape as BoxShape3D).size
	return Vector3(size.x, size.y + SKIN, size.z)


func _ahead(pose: Transform3D) -> Vector3:
	var back := pose.basis.z
	return Vector3(-back.x, 0.0, -back.z).normalized()


func _solid(stack: Node3D, on: bool) -> void:
	for shape in stack.find_children("*", "CollisionShape3D", true, false):
		(shape as CollisionShape3D).set_deferred("disabled", not on)


func _reparent(node: Node3D, parent: Node3D) -> void:
	if node.get_parent() != parent:
		node.reparent(parent, true)
