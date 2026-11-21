extends SceneTree
## Mission 2's gates as real ones are (the audit, #349, after photos of real gates): the yard's and
## the compound's sliding gates one cantilever gate (`sliding_gate.gd`): its leaf framed with
## diagonal braces and a counterweight tail, riding on two roller carriages on a footing that stay
## under its bottom rail shut and open; a toothed rack along that rail over the motor's pinion (the
## motor a real model on a plinth, inside the fence); a receiver post catching it shut; photocells
## on posts facing across the opening; a warning lamp flashing only while it moves. The shed's
## barrier: a real cabinet model whose hub carries the arm, a fork post the shut arm rests in, red
## lamps along the arm (steady down, flashing moving, out up) and an amber lamp flashing moving.

const SlidingGate = preload("res://features/environments/industrial_loop/sliding_gate.gd")
const ART := "res://features/environments/industrial_loop/art/gates/"
const PINION_NEAR := 0.02
const RACK_LEAST := 6.0
const CELL_HEIGHT := Vector2(0.4, 0.7)
const FLASH := Vector2(0.8, 2.5)
const HUB_NEAR := 0.04
const ARM_LAMPS_LEAST := 3

var _checks := 0
var _failures := 0
var _app: Node3D
var _scratch: String


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(180.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-gates-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	_app.call("_resume")
	await physics_frame
	var world := _app.get_node("IndustrialLoop")
	var owners := {"yard": world.get("container_yard"), "compound": world.get("compound")}
	for label: String in owners:
		var owner := owners[label] as Node3D
		var gate := owner.get_node_or_null("SlidingGate") as Node3D
		_check(gate != null and gate.get_script() == SlidingGate,
			"G1 (%s): the gate is the one cantilever sliding gate (sliding_gate.gd)" % label)
		if gate == null or gate.get_script() != SlidingGate:
			continue
		await _sliding(label, owner, gate)
	await _barrier(world.get("transfer_shed") as Node3D)
	_finish()


func _box(node: Node3D, frame: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false) \
			+ ([node] if node is MeshInstance3D else []):
		if not mesh.is_visible_in_tree():
			continue
		var part := frame.global_transform.affine_inverse() * mesh.global_transform \
			* mesh.get_aabb()
		box = part if first else box.merge(part)
		first = false
	return box


func _model(node: Node) -> String:
	for child in node.find_children("*", "Node3D", true, false) + [node]:
		var path := String((child as Node).scene_file_path)
		if path.begins_with(ART):
			return path.get_file().get_basename()
	return ""


func _sliding(label: String, owner: Node3D, gate: Node3D) -> void:
	var leaf := gate.get("leaf") as Node3D
	var rack := gate.find_child("Rack", true, false) as Node3D
	var motor := gate.find_child("Motor", true, false) as Node3D
	var pinion := gate.find_child("pGear1_blinn1_0", true, false) as Node3D
	var carriages := gate.find_children("RollerCarriage*", "Node3D", true, false)
	var shut_ok := []
	var gaps := []
	for open in [0.0, float(gate.get("travel"))]:
		gate.call("set_open", open)
		await physics_frame
		var rail := _box(gate.find_child("BottomRail", true, false) as Node3D, gate)
		var under := carriages.size() == 2
		for carriage: Node3D in carriages:
			var at := gate.to_local(carriage.global_position)
			under = under and at.x > rail.position.x + 0.1 and at.x < rail.end.x - 0.1
		shut_ok.append(under)
		if rack != null and pinion != null:
			var teeth := _box(rack, gate)
			var gear := _box(pinion, gate)
			gaps.append(absf(teeth.position.y - gear.end.y))
			under = gear.get_center().x > teeth.position.x and gear.get_center().x < teeth.end.x
			gaps[-1] = gaps[-1] if under else INF
	gate.call("set_open", 0.0)
	_check(shut_ok == [true, true], ("G2 (%s): two roller carriages on a footing stay under the "
		+ "leaf's bottom rail both shut and open") % label)
	var long_enough := rack != null and _box(rack, gate).size.x >= RACK_LEAST
	_check(motor != null and _model(motor) == "gate_motor" and long_enough and gaps.size() == 2
		and gaps.max() <= PINION_NEAR, ("G3 (%s): the motor (a real model) drives a toothed rack "
		+ "along the bottom rail, its pinion meeting the rack shut and open (gaps %s)")
		% [label, gaps])
	var plinth := gate.find_child("MotorPlinth", true, false) as Node3D
	var inside := motor != null and plinth != null \
		and absf(_box(motor, gate).position.y - _box(plinth, gate).end.y) < 0.01
	var braces := leaf.find_children("Brace*", "MeshInstance3D", true, false).size() \
		if leaf != null else 0
	var receiver := gate.find_child("ReceiverPost", true, false) != null
	var light := gate.find_child("WarningLight", true, false) as Node3D
	var clear := light != null and leaf != null
	if clear:
		var path := _box(leaf, gate)
		path.position.x -= float(gate.get("travel"))
		path.size.x += float(gate.get("travel"))
		clear = not path.intersects(_box(light, gate))
	_check(clear, "G7 (%s): the warning lamp stands clear of the leaf's path, shut to open" % label)
	_check(inside and braces >= 2 and receiver, ("G4 (%s): the motor on its plinth, the leaf "
		+ "framed with diagonal braces (%d), a receiver post catching it shut") % [label, braces])
	var cells := gate.find_children("Photocell*", "Node3D", true, false)
	var facing := cells.size() == 2
	if facing:
		var a := cells[0] as Node3D
		var b := cells[1] as Node3D
		var across := (b.global_position - a.global_position).normalized()
		facing = (-a.global_basis.z).dot(across) > 0.9 and (-b.global_basis.z).dot(-across) > 0.9
		for cell: Node3D in cells:
			var up := cell.global_position.y - owner.global_position.y \
				- float(owner.get("GROUND") if "GROUND" in owner else 0.0)
			facing = facing and up >= CELL_HEIGHT.x - 0.3 and up <= CELL_HEIGHT.y + 0.3
	_check(facing, "G5 (%s): a pair of photocells on posts face each other across the opening"
		% label)
	await _flashing("G6 (%s)" % label, gate, func(on: bool) -> void: gate.call("set_moving", on))


## The lamp flashes while moving (its light switching on and off FLASH times a second) and is out
## when still.
func _flashing(tag: String, owner: Node, moving: Callable) -> void:
	var lamp := owner.find_child("WarningLamp", true, false) as OmniLight3D
	if lamp == null:
		_check(false, "%s: a warning lamp flashes while it moves" % tag)
		return
	moving.call(false)
	await create_timer(0.3, true, false, true).timeout
	var still_lit := lamp.visible and lamp.light_energy > 0.01
	moving.call(true)
	var changes := 0
	var last := lamp.visible and lamp.light_energy > 0.01
	var time := 0.0
	while time < 3.0:
		await process_frame
		time += 1.0 / 60.0
		var now := lamp.visible and lamp.light_energy > 0.01
		if now != last:
			changes += 1
		last = now
	moving.call(false)
	await create_timer(0.3, true, false, true).timeout
	var after := lamp.visible and lamp.light_energy > 0.01
	var rate := changes / 2.0 / 3.0
	_check(not still_lit and not after and rate >= FLASH.x and rate <= FLASH.y, ("%s: a warning "
		+ "lamp flashes %.1f times a second while it moves, and is out when still") % [tag, rate])


func _barrier(shed: Node3D) -> void:
	var cabinet := shed.get_node_or_null("BarrierCabinet") as Node3D
	var arm := shed.get_node_or_null("BarrierArm") as Node3D
	var hub := cabinet.find_child("pCylinder1_lambert4_0", true, false) as Node3D \
		if cabinet != null else null
	var near := INF
	if hub != null and arm != null:
		var centre := hub.global_transform * (hub as MeshInstance3D).get_aabb().get_center()
		near = Vector2(centre.x - arm.global_position.x, centre.y - arm.global_position.y).length()
	_check(cabinet != null and _model(cabinet) == "barrier_cabinet" and near <= HUB_NEAR,
		("B1: the barrier's cabinet is a real model, its hub carrying the arm (%.3f m from the "
		+ "arm's pivot)") % near)
	var fork := shed.get_node_or_null("ArmRest") as Node3D
	var resting := false
	if fork != null and arm != null:
		var length := float(shed.get("ARM_LENGTH"))
		var tip := arm.global_transform * Vector3(length - 0.15, 0.0, 0.0)
		var cup := _box(fork, shed)
		var local := shed.to_local(tip)
		resting = local.x > cup.position.x - 0.05 and local.x < cup.end.x + 0.05 \
			and absf(local.y - cup.end.y) < 0.12 and fork.find_child("Fork*", true, false) != null
	var far_edge := float(shed.get("LANE_X")) + float(shed.get("LANE_WIDTH")) / 2.0
	var beyond := fork != null and fork.global_position.x - 0.1 > far_edge
	_check(resting and beyond, ("B2: shut, the arm spans the lane, its tip lying in the fork of its "
		+ "rest post past the lane's far edge (%s)") % beyond)
	var lamps := arm.find_children("ArmLamp*", "MeshInstance3D", true, false) if arm != null \
		else []
	_check(lamps.size() >= ARM_LAMPS_LEAST, "B3: red lamps along the arm (%d)" % lamps.size())
	await _flashing("B4", shed, func(on: bool) -> void: shed.call("set_barrier_moving", on))


func _finish() -> void:
	print("GATES RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	_app.queue_free()
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "The gate test finished within 180 s of game time")
	quit(1)
