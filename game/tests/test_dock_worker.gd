extends SceneTree
## Step 3 of #253 (#263-#265, docs/PHASE_BRIEF.md): bay 9's dock worker at his station. In the
## running game on Mission 2's start save, read from the shed as it is built: his desk and chair
## on the dock floor in the corner east of bay 9's lift, along the edge rail, out of the way of
## the load's approach, the lift and the way to the dock stair; solid; the seal log and the pen
## cup on the desk; and the chair in sight through bay 9's doorway from where Ethan stands behind
## the van. Part 2: he sits at it (W7), and when bay 9's van's doors shut he stands, takes the
## seal log, walks down the dock stair and out by the side door to the doors, seals them with
## C-TPAT's view, verify, tug, twist (W8-W10) and comes back to sit (W11). A headless run draws
## nothing, so the look is not checked here.

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

## Part 2: the worker at his desk and his round to seal bay 9's van (step 3 of #253).
const DOCKED := Vector3(-47.75, 0.1, 23.16)
const SEAT_TOP := 0.47
const SEAT_ABOVE := Vector2(0.03, 0.2)
const ON_SEAT := 0.15
const LANDING := Vector3(-44.2, 1.3, 12.4)
const STAIR_FOOT := Vector3(-44.2, 0.0, 15.5)
const SIDE_DOOR := Vector3(-41.2, 0.0, 17.5)
const PASSES := 0.6
const ROUND := 60.0
const NUMBER := "SL483201"

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
	create_timer(240.0, true, false, true).timeout.connect(_timeout)
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
	_app.call("_resume")
	for frame in range(30):
		await physics_frame
	_check_seated("W7 at the start")
	await _check_round()
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
func _parts() -> Dictionary:
	var shed := _app.find_child("TransferShed", true, false)
	var worker := shed.find_child("DockWorker", true, false) as Node3D
	var station := shed.find_child("DockStation", true, false) as Node3D
	var model := worker.get_node("Model") as Node3D
	return {"shed": shed, "worker": worker, "station": station, "model": model,
		"player": model.find_children("*", "AnimationPlayer", true, false)[0],
		"skeleton": model.find_children("*", "Skeleton3D", true, false)[0],
		"chair": station.get("chair"), "log": station.get_node("SealLog")}


func _pelvis(parts: Dictionary) -> Vector3:
	var skeleton := parts["skeleton"] as Skeleton3D
	return (skeleton.global_transform * skeleton.get_bone_global_pose(
		skeleton.find_bone("Bip01 Pelvis"))).origin


func _check_seated(when: String) -> void:
	var parts := _parts()
	var worker := parts["worker"] as Node3D
	var chair := parts["chair"] as Node3D
	var pelvis := _pelvis(parts)
	var seat := chair.global_position + Vector3.UP * SEAT_TOP
	var above := pelvis.y - seat.y
	var across := Vector2(pelvis.x - seat.x, pelvis.z - seat.z).length()
	var facing := (parts["model"] as Node3D).global_basis.z.normalized().dot(Vector3.RIGHT)
	var clip := String((parts["player"] as AnimationPlayer).current_animation)
	var log_back := (parts["log"] as Node3D).is_visible_in_tree()
	_check(worker.visible and bool(worker.get("home")) and clip == "SitIdle"
		and above >= SEAT_ABOVE.x and above <= SEAT_ABOVE.y and across <= ON_SEAT
		and facing > 0.9 and log_back, "%s he sits at his desk: %s, his hips %.2f m over the " % [
		when, clip, above] + "seat and %.2f m from its middle, facing the desk (%.2f), the log on "
		% [across, facing] + "it %s" % log_back)


func _check_round() -> void:
	var parts := _parts()
	var worker := parts["worker"] as Node3D
	var player := parts["player"] as AnimationPlayer
	var van := _app.get_node("FreightVan") as Node3D
	van.call("recover", Transform3D(Basis(Vector3.UP, PI), DOCKED))
	van.set("rear_doors_open", false)
	for frame in range(10):
		await physics_frame
	(parts["shed"] as Node).call("call_dock_hand", van, NUMBER)
	var clips: Array[String] = []
	var carried := false
	var landing := INF
	var foot := INF
	var door := INF
	var sealed_during := ""
	var entered := false
	var time := 0.0
	var home_at := -1.0
	while time < ROUND + 5.0:
		await physics_frame
		time += 1.0 / Engine.physics_ticks_per_second
		var clip := String(player.current_animation)
		if clips.is_empty() or clips[-1] != clip:
			clips.append(clip)
		var hand := worker.find_child("Clipboard", true, false) as Node3D
		if hand != null and hand.is_visible_in_tree() \
				and not (parts["log"] as Node3D).is_visible_in_tree():
			carried = true
		var at := worker.global_position
		landing = minf(landing, at.distance_to(LANDING))
		foot = minf(foot, at.distance_to(STAIR_FOOT))
		door = minf(door, at.distance_to(SIDE_DOOR))
		if sealed_during.is_empty() and bool(van.get("sealed")):
			sealed_during = clip
		var inside := van.to_local(at + Vector3.UP * 0.9)
		entered = entered or (absf(inside.x) < 0.9 and absf(inside.z) < 2.4)
		if bool(worker.get("home")) and time > 2.0:
			home_at = time
			break
	for frame in range(30):
		await physics_frame
	var order := ["StandUp", "Walk", "Seal", "Check", "Note", "Walk", "SitDown"]
	var seen := []
	var next := 0
	for clip in clips:
		if next < order.size() and clip == order[next]:
			seen.append(clip)
			next += 1
	_check(not clips.is_empty() and clips[0] == "StandUp" and carried, "W8 sent to seal, he stands "
		+ "up from his desk and takes the seal log in his hand (%s, carried %s)" % [clips.slice(0, 3),
		carried])
	_check(landing < PASSES and foot < PASSES and door < PASSES and not entered,
		"W9 his way: over the dock floor to the stair's landing (%.2f m), down the stair " % landing
		+ "(%.2f m from its foot), out of the side door (%.2f m), never into the van" % [foot, door])
	_check(next == order.size() and sealed_during == "Seal", "W10 at the doors, view, verify, "
		+ "tug, twist (C-TPAT's VVTT): the seal put on in Seal (%s), then Check against " % sealed_during
		+ "his log and Note (%s)" % [clips])
	_check(home_at > 0.0 and home_at <= ROUND, "W11 back at his desk within the doors' %.0f s "
		% ROUND + "(%.1f s)" % home_at)
	for frame in range(int(Engine.physics_ticks_per_second * 4.5)):
		await physics_frame
	_check_seated("W11 back,")


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
	_check(false, "The dock worker's checks finish within 240 s")
	_finish()


func _finish() -> void:
	print("DOCK WORKER RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	_remove()
	quit(1 if _failures > 0 else 0)
