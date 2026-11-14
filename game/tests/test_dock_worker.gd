extends SceneTree
## Step 3 of #253 (#263-#265, docs/PHASE_BRIEF.md): bay 9's dock worker at his station. In the
## running game on Mission 2's start save, read from the shed as it is built: his desk and chair
## on the dock floor in the corner east of bay 9's lift, along the edge rail, out of the way of
## the load's approach, the lift and the way to the dock stair; solid; the seal log and the pen
## cup on the desk; and the chair in sight through bay 9's doorway from where Ethan stands behind
## the van. A headless run draws nothing, so the look is not checked here.

const START_SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const NOT_CAMERA_WALLS := 0xFFFFFFFF & ~8
const FLOOR := 1.3
const DESK_TOP := 0.788
const ON := 0.005
## Bay 9's lift's pit, the load's approach to it (test_loading.gd's H14), the edge rail's line and
## the way from the dock floor onto the dock stair's landing.
const PIT := Rect2(-48.665, 17.3, 1.83, 2.44)
const APPROACH := Rect2(-48.965, 14.3, 2.43, 3.0)
const RAIL_X := -44.76
const RAIL_CLEAR := 0.03
const WALL_Z := 19.75
const TO_THE_STAIR := 14.4
## Bay 9's load, staged on its jack (dock_staging.gd), and room to walk between it and the station.
const LOAD := Rect2(-47.708, 15.99, 1.016, 1.219)
const WALK_ROOM := 0.6
## Where Ethan's eyes and his camera are as he comes to the van's doors from behind it.
const SIGHTS: Array[Vector3] = [Vector3(-47.6, 1.7, 25.0), Vector3(-47.5, 1.75, 21.6),
	Vector3(-47.2, 2.3, 23.0)]

var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _app: Node3D


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(120.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-dock-worker-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_store(START_SAVE)
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	await process_frame
	await physics_frame
	await physics_frame
	_check_station()
	_finish()


func _check_station() -> void:
	var shed := _app.get_node("IndustrialLoop").get("transfer_shed") as Node3D
	var station := shed.get_node_or_null("Building/DockStation") as Node3D if shed != null \
		else null
	var desk := station.get_node_or_null("Desk") as Node3D if station != null else null
	var chair := station.get_node_or_null("Chair") as Node3D if station != null else null
	var log := station.get_node_or_null("SealLog") as Node3D if station != null else null
	var pens := station.get_node_or_null("PenCup") as Node3D if station != null else null
	var made := desk != null and chair != null and log != null and pens != null \
		and desk.scene_file_path.ends_with("metal_office_desk.gltf") \
		and chair.scene_file_path.ends_with("office_chair.glb") \
		and log.scene_file_path.ends_with("clipboard.gltf") \
		and pens.scene_file_path.ends_with("stationery_supplies.gltf")
	_check(made, ("W1: bay 9's dock station is Poly Haven's Metal Office Desk and Red Fox's "
		+ "office chair, with Poly Haven's Clipboard as the seal log and its Stationery "
		+ "Supplies' pen cup (%s)") % ("so" if made else "missing or other models"))
	if not made:
		return
	var desk_box := _box(desk)
	var chair_box := _box(chair)
	var standing := absf(desk_box.position.y - FLOOR) <= ON \
		and absf(chair_box.position.y - FLOOR) <= ON \
		and absf(_box(log).position.y - (FLOOR + DESK_TOP)) <= ON \
		and absf(_box(pens).position.y - (FLOOR + DESK_TOP)) <= ON
	_check(standing, ("W2: the desk and the chair stand on the dock floor (their feet %.3f and "
		+ "%.3f m up) and the seal log and pen cup on the desk's top (%.3f and %.3f m)") % [
		desk_box.position.y, chair_box.position.y, _box(log).position.y, _box(pens).position.y])
	var both := desk_box.merge(chair_box)
	var flat := Rect2(both.position.x, both.position.z, both.size.x, both.size.z)
	var room := minf(_apart(_flat(desk_box), LOAD), _apart(_flat(chair_box), LOAD))
	var clear := not flat.intersects(APPROACH.grow(0.05)) and not flat.intersects(PIT) \
		and both.end.x <= RAIL_X - RAIL_CLEAR and both.end.z <= WALL_Z - 0.02 \
		and both.position.z >= TO_THE_STAIR and room >= WALK_ROOM
	_check(clear, ("W3: the station keeps to its corner, clear of the load's approach to the "
		+ "lift, the lift's pit, the edge rail by %.2f m, the dock wall and the way to the stair, "
		+ "with room to walk between it and bay 9's staged load (%.2f m; it spans x %.2f to "
		+ "%.2f, z %.2f to %.2f)") % [RAIL_CLEAR, room, both.position.x,
		both.end.x, both.position.z, both.end.z])
	var to_lift := desk.global_basis.z.normalized().dot(Vector3.LEFT)
	var to_desk := chair.global_basis.z.normalized().dot(Vector3.RIGHT)
	var front := desk_box.position.x
	var gap := front - chair.global_position.x
	var centred := absf(chair.global_position.z - desk.global_position.z)
	_check(to_lift > 0.99 and to_desk > 0.99 and gap >= 0.25 and gap <= 0.45 and centred <= 0.05,
		("W4: the desk's drawers face the lift and the chair stands in its kneehole facing it, "
		+ "its column %.2f m out from the desk's front and %.2f m off its middle") % [gap,
		centred])
	var space := _app.get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var ball := SphereShape3D.new()
	ball.radius = 0.05
	query.shape = ball
	query.collision_mask = 1
	var solid := true
	for point: Vector3 in [desk.global_position + Vector3.UP * (DESK_TOP - 0.06),
			chair.global_position + Vector3.UP * 0.4]:
		query.transform = Transform3D(Basis.IDENTITY, point)
		solid = solid and not space.intersect_shape(query, 1).is_empty()
	_check(solid, "W5: the desk and the chair are solid, so nobody walks or pushes a load "
		+ "through them")
	var ray := PhysicsRayQueryParameters3D.new()
	ray.collision_mask = NOT_CAMERA_WALLS
	var hidden: Array[String] = []
	for sight in SIGHTS:
		ray.from = sight
		ray.to = chair.global_position + Vector3.UP * 0.75
		var hit := space.intersect_ray(ray)
		var seen := not hit.is_empty() and (hit["position"] as Vector3).distance_to(ray.to) < 0.4
		if not seen:
			hidden.append("%s (%s)" % [sight, "nothing" if hit.is_empty()
				else String((hit["collider"] as Node).name)])
	_check(hidden.is_empty(), ("W6: from where Ethan stands behind the van and comes to its "
		+ "doors, the chair's back is in sight through bay 9's doorway (hidden from %s)") % [
		", ".join(hidden) if not hidden.is_empty() else "none"])


## `box`'s footprint on the floor.
func _flat(box: AABB) -> Rect2:
	return Rect2(box.position.x, box.position.z, box.size.x, box.size.z)


## How far apart two rectangles on the floor are: 0 if they touch or overlap.
func _apart(a: Rect2, b: Rect2) -> float:
	var dx := maxf(0.0, maxf(b.position.x - a.end.x, a.position.x - b.end.x))
	var dz := maxf(0.0, maxf(b.position.y - a.end.y, a.position.y - b.end.y))
	return Vector2(dx, dz).length()


## The box, in the world, round everything `node` draws.
func _box(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for found in node.find_children("*", "MeshInstance3D", true, false):
		var mesh := found as MeshInstance3D
		var part := mesh.global_transform * mesh.get_aabb()
		box = part if first else box.merge(part)
		first = false
	return box


func _store(text: String) -> void:
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _remove() -> void:
	for suffix in ["", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(_scratch + suffix):
			DirAccess.remove_absolute(_scratch + suffix)


func _timeout() -> void:
	_check(false, "The dock worker's checks finish within 120 s")
	_finish()


func _finish() -> void:
	print("DOCK WORKER RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	_remove()
	quit(1 if _failures > 0 else 0)
