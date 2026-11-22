extends SceneTree
## The van's reversing camera and its parking guides (#287, step 1 of #289): a real van's
## camera, high on its back where the Daily's sits in the third brake light, looking down past
## its bumper, with guides that lie on the ground behind it.
## C1 the camera is on the body's rear, not in the air behind it.
## C2 the bumper's top edge is at the bottom of the picture, in the game's view and the dash
##    screen alike, as a real reversing camera shows it.
## C3 the guides lie on the ground (within 2 cm), the van's width apart (2.0 m) and parallel,
##    from the bumper back to 3 m, with marks at 0.5 m (red), 1 m (yellow), 2 and 3 m (green).
## C4 each line is drawn where the camera that shows it sees its ground point (within 1 px), in
##    the game's view and on the dash screen.
## C5 a board standing behind the van, between the points the guides are found at, hides the
##    guides behind it from the camera, and they never climb onto it.
## C6 on a slope the guides follow the ground.

const ParkingGuides = preload("res://features/vehicles/freight_van/parking_guides.gd")
const START_SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const COURT := Vector3(-47.75, 0.1, 31.0)
const BUMPER_TOP := Vector3(0.0, 0.55, 3.012)
const ON_GROUND := 0.02
const WIDTH := 2.0
const MARKS := {0.5: "e0483e", 1.0: "f2c230", 2.0: "4fd18b", 3.0: "4fd18b"}
const BLOCK := Vector3(3.0, 0.8, 0.05)
const BLOCK_AT := 1.625
const RAMP_TILT := 8.0

var _checks: int = 0
var _failures: int = 0
var _app: Node
var _van: Node3D
var _presentation: Node3D
var _scratch: String


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(200.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-rear-camera-%d.cfg" % OS.get_process_id())
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(START_SAVE)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	_van = _app.get_node("FreightVan")
	_presentation = _van.get_node("VanPresentation")
	await process_frame
	await process_frame
	await _key(KEY_ENTER)
	await _seconds(1.0)
	_van.call("recover", Transform3D(Basis(Vector3.UP, PI), COURT))
	await _seconds(1.0)
	await _shift()
	await _seconds(0.5)
	_check_camera()
	_check_bumper()
	_check_ground(_guides(false), "the game's view")
	_check_drawn(_guides(false), "the game's view")
	_check_drawn(_guides(true), "the dash screen")
	await _check_hidden()
	await _check_slope()
	_finish()


func _guides(dash: bool) -> Control:
	for found in _presentation.find_children("*", "Control", true, false):
		if found.get_script() == ParkingGuides and (found.get_parent() is SubViewport) == dash:
			return found as Control
	return null


func _rear_camera() -> Camera3D:
	return _presentation.get("rear_camera") as Camera3D


func _check_camera() -> void:
	var camera := _rear_camera()
	var at := _van.to_local(camera.global_position)
	var surface := -INF
	for node in _presentation.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.mesh == null or not mesh.visible:
			continue
		var into := _van.global_transform.affine_inverse() * mesh.global_transform
		for index in mesh.mesh.get_surface_count():
			var arrays := mesh.mesh.surface_get_arrays(index)
			if arrays.is_empty():
				continue
			for vertex: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
				var point := into * vertex
				if absf(point.x) < 0.3 and absf(point.y - at.y) < 0.08:
					surface = maxf(surface, point.z)
	var current := _app.get_viewport().get_camera_3d() == camera
	_check(current and at.z >= surface and at.z - surface <= 0.06 and at.y > 2.0,
		("C1 in reverse the game's view is the rear camera (%s), on the body's rear: %.3f m "
		+ "behind its surface at that height (%.3f), %.2f m up") % [current, at.z - surface,
		surface, at.y])


func _check_bumper() -> void:
	var shown: Array[String] = []
	var dash := (_presentation.get("reverse_view") as SubViewport).get_camera_3d()
	for camera: Camera3D in [_rear_camera(), dash]:
		var size := Vector2(camera.get_viewport().get_visible_rect().size)
		var edge := _van.to_global(BUMPER_TOP)
		var seen := camera.unproject_position(edge) / size
		var good := not camera.is_position_behind(edge) and seen.x > 0.0 and seen.x < 1.0 \
			and seen.y > 0.8 and seen.y < 1.0
		shown.append("%s at %s" % [good, seen.snapped(Vector2.ONE * 0.001)])
	_check(not shown[0].begins_with("false") and not shown[1].begins_with("false"),
		"C2 the bumper's top edge at the bottom of the picture (game view, dash screen: %s)"
		% ", ".join(shown))


func _segments(guides: Control) -> Array:
	return guides.call("segments") if guides != null and guides.has_method("segments") else []


func _ground_at(point: Vector3) -> float:
	var ray := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 1.5,
		point + Vector3.DOWN * 1.5, 1)
	ray.exclude = [(_van as CollisionObject3D).get_rid()]
	var hit := _van.get_world_3d().direct_space_state.intersect_ray(ray)
	return (hit["position"] as Vector3).y if not hit.is_empty() else INF


func _check_ground(guides: Control, where: String) -> void:
	var segments := _segments(guides)
	var worst := 0.0
	var lefts: Array[float] = []
	var rights: Array[float] = []
	var farthest := 0.0
	var marks := {}
	for segment: Dictionary in segments:
		for end: String in ["from", "to"]:
			var point: Vector3 = segment[end]
			worst = maxf(worst, absf(point.y - _ground_at(point)))
			var local := _van.to_local(point)
			farthest = maxf(farthest, local.z - BUMPER_TOP.z)
			if String(segment["kind"]) == "side":
				(lefts if local.x < 0.0 else rights).append(local.x)
		if String(segment["kind"]) == "mark":
			marks[snappedf(float(segment["distance"]), 0.01)] = \
				(segment["colour"] as Color).to_html(false)
	var apart: float = (rights.max() - lefts.min()) if not lefts.is_empty() and not rights.is_empty() \
		else 0.0
	var spread: float = (lefts.max() - lefts.min()) + (rights.max() - rights.min()) \
		if not lefts.is_empty() and not rights.is_empty() else INF
	var right_marks := true
	for distance: float in MARKS:
		right_marks = right_marks and marks.get(snappedf(distance, 0.01), "") == MARKS[distance]
	_check(not segments.is_empty() and worst <= ON_GROUND and absf(apart - WIDTH) < 0.02
		and spread < 0.01 and farthest >= 2.95 and right_marks,
		("C3 in %s the guides lie on the ground (at most %.3f m off it), %.3f m apart and "
		+ "parallel (%.3f m of drift), back to %.2f m behind the bumper, marked %s") % [where,
		worst, apart, spread, farthest, marks])


func _check_drawn(guides: Control, where: String) -> void:
	var segments := _segments(guides)
	var camera := guides.get_viewport().get_camera_3d() if guides != null else null
	var worst := 0.0
	for segment: Dictionary in segments:
		for end: String in ["from", "to"]:
			var seen := camera.unproject_position(segment[end])
			worst = maxf(worst, seen.distance_to(segment[end + "_drawn"]))
	_check(not segments.is_empty() and camera != null and worst <= 1.0,
		("C4 on %s each line is drawn where its camera sees its ground point (at most %.2f px "
		+ "off, %d pieces)") % [where, worst, segments.size()])


func _check_hidden() -> void:
	var guides := _guides(false)
	var before := _segments(guides).size()
	var block := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = BLOCK
	shape.shape = box
	block.add_child(shape)
	root.add_child(block)
	var behind := _van.to_global(Vector3(0.0, 0.0, BUMPER_TOP.z + BLOCK_AT))
	block.global_transform = Transform3D(_van.global_basis, Vector3(behind.x,
		_ground_at(behind) + BLOCK.y / 2.0, behind.z))
	await physics_frame
	await _seconds(0.2)
	var camera := _rear_camera()
	var bounds := AABB(-BLOCK / 2.0, BLOCK)
	var through := 0
	var climbed := 0
	var segments := _segments(guides)
	for segment: Dictionary in segments:
		for end: String in ["from", "to"]:
			var point: Vector3 = segment[end]
			var from := block.global_transform.affine_inverse() * camera.global_position
			var to := block.global_transform.affine_inverse() * point
			if bounds.grow(-0.01).intersects_segment(from, to):
				through += 1
			if point.y > _ground_at(point) + ON_GROUND:
				climbed += 1
	block.free()
	await physics_frame
	_check(through == 0 and climbed == 0 and segments.size() < before,
		("C5 a %.1f m board %.3f m behind the van hides the guides behind it (%d pieces before, "
		+ "%d with it; %d seen through it, %d on top of it)") % [BLOCK.y, BLOCK_AT, before,
		segments.size(), through, climbed])


func _check_slope() -> void:
	var ramp := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4.0, 0.2, 5.0)
	shape.shape = box
	ramp.add_child(shape)
	root.add_child(ramp)
	var middle := _van.to_global(Vector3(0.0, 0.0, BUMPER_TOP.z + 2.5))
	var ground := _ground_at(middle)
	var tilt := Basis(_van.global_basis.x, deg_to_rad(-RAMP_TILT)) * _van.global_basis
	ramp.global_transform = Transform3D(tilt, Vector3(middle.x, ground + 0.05, middle.z))
	await physics_frame
	await _seconds(0.2)
	var worst := 0.0
	var rise := 0.0
	var segments := _segments(_guides(false))
	for segment: Dictionary in segments:
		for end: String in ["from", "to"]:
			var point: Vector3 = segment[end]
			worst = maxf(worst, absf(point.y - _ground_at(point)))
			rise = maxf(rise, point.y - ground)
	ramp.free()
	await physics_frame
	_check(not segments.is_empty() and worst <= ON_GROUND and rise > 0.1,
		("C6 on an %.0f° slope behind the van the guides follow the ground (at most %.3f m off "
		+ "it, rising %.2f m)") % [RAMP_TILT, worst, rise])


func _shift() -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = "change_gear"
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await process_frame


func _key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await process_frame


func _seconds(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _finish() -> void:
	print("REAR CAMERA RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	_app.queue_free()
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "Rear camera test finished within 200 s")
	quit(1)
