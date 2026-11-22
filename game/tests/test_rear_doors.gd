extends SceneTree
## Part B of the author's #245–#247 (docs/PHASE_BRIEF.md, revision "step 2f, part 1 continued:
## the rear doors by hand"): Ethan opens and closes the van's rear doors himself. In the running
## game on Mission 2's start save the van is set stopped in the open court; Ethan gets out by E
## and walks round behind it by the real W key, his camera turned as the mouse turns it; then E.
## Read from his skeleton as it is posed and from the doors as they turn: his hand on each door's
## handle before it moves and while he pulls it, each door pushed on and caught at its stay,
## nothing passing through him, nothing jumping, his feet keeping his walk's pace; the right door
## first, as a Daily's opens, and the left first again closing; each door's latch and stay heard
## as they work. A headless run draws nothing, so the look is not checked here.

const START_SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const COURT_SPOT := Vector3(-47.75, 0.1, 31.0)
const TO_THE_REAR: Array[Vector3] = [Vector3(-1.7, 0.0, 1.5), Vector3(-1.5, 0.0, 4.3),
	Vector3(0.0, 0.0, 4.3)]
const HOME := 267.0
const SHUT := 1.0
const MOVED := 0.5
const ON_GRIP := 0.03
const DOOR_TICK := 4.0
const BODY_TICK := 0.05
const LIFT_TICK := 0.02
const CAMERA_TICK := 0.08
const CLEARANCE := 0.27
const WITHIN := 18.0
const WITHIN_CLOSING := 24.0
const BOUNCE := 6.0
const WALK_PACE := 1.705
const WALK_BACK_PACE := 0.529
const PACE_SPREAD := 0.25
const MOVING := 0.15
const AXIS: Array[float] = [0.35, 0.9, 1.45]
const HINGES_EACH := 2
const TOUCHING := 0.01
## The hinges as the author chose them (#261): compact, a real Daily's, reaching only a little onto
## the door, and in the finish of the door where each sits so that it blends into the body: its
## colour, roughness and metalness sampled from the Iveco's Back_door textures over the doors'
## outer skin by each hinge's pad: the white paint above the tail lamp (sRGB 0.91, 0.482, 0.439),
## the black trim band at the doors' foot below it (sRGB 0.18, 0.49, 0.0).
const ONTO_DOOR := 0.035
const HINGE_TALL := 0.04
const FINISHES := {"paint": [Color(0.91, 0.91, 0.91), 0.482, 0.439],
	"trim": [Color(0.18, 0.168, 0.195), 0.49, 0.0]}
const FINISH_NEAR := 0.03
const CAMERA_SKIN := 0.15
const HANDS: Array[String] = ["mixamorig_LeftHand", "mixamorig_RightHand",
	"mixamorig_LeftHandMiddle1", "mixamorig_RightHandMiddle1"]

var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _app: Node3D
var _hud: CanvasLayer
var _van: CharacterBody3D
var _driver: CharacterBody3D
var _skeleton: Skeleton3D
var _player: AnimationPlayer
var _camera: Camera3D
var _vis: Node
var _doors: Array[Node3D] = []
var _extents: Array[AABB] = []
var _hands: Array[int] = []
var _palms: Array[Vector3] = [Vector3.INF, Vector3.INF]
var _sounds: Array[String] = []
var _camera_in_door := 0
var _camera_frames := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(240.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-doors-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_store(START_SAVE)
	await _build()
	await _key(KEY_ENTER)
	await _seconds(1.0)
	_van.call("recover", Transform3D(Basis(Vector3.UP, PI), COURT_SPOT))
	await _seconds(0.5)
	await _key(KEY_E)
	await _until(_on_foot, 8.0)
	_skeleton = _driver.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	_player = _driver.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	_camera = _driver.call("get_camera") as Camera3D
	_vis = _van.get_node("VanPresentation")
	for door in ["RearDoorLeft", "RearDoorRight"]:
		var node := _van.find_child(door, true, false) as Node3D
		_doors.append(node)
		_extents.append(_vis.call("_door_extent", node) if node != null else AABB())
	for bone in HANDS:
		_hands.append(_skeleton.find_bone(bone))
	_skeleton.skeleton_updated.connect(_on_pose)
	if _van.has_signal("rear_door_sounded"):
		_van.connect("rear_door_sounded", func(kind: String) -> void: _sounds.append(kind))
	await _walk(TO_THE_REAR)
	var offered := _hint()
	_check(_on_foot() and not _doors.has(null) and not _hands.has(-1)
		and offered == "E  Open the rear doors",
		"Setup: Ethan on foot behind the stopped van in the open court, offered the doors (%s)"
		% offered)
	var shut_hung := _hinges_join()
	await _check_opening()
	await _seconds(1.0)
	var held_open := _angles()
	var open_hung := _hinges_join()
	_check(shut_hung == "" and open_hung == "",
		("R10: each rear door hangs on %d strap hinges, modelled as a Daily's are, shut and on its "
		+ "stay: each hinge's arm, on the door, runs from the door's edge to its pin, and its "
		+ "bracket from the pin to the body's corner, nothing open between them (shut: %s; open: "
		+ "%s)") % [HINGES_EACH,
		"joined" if shut_hung == "" else shut_hung, "joined" if open_hung == "" else open_hung])
	var made := _hinges_compact_and_painted()
	_check(made == "", ("R12: each hinge is compact, its arm reaching at most %.3f m onto its door "
		+ "and at most %.2f m tall, and in the finish of the door where it sits, the white paint or "
		+ "the black trim at the foot, so that it blends into the body "
		+ "(%s)") % [ONTO_DOOR, HINGE_TALL, "so" if made == "" else made])
	_check(held_open.x >= HOME and held_open.y >= HOME and _hint() == "E  Close the rear doors",
		("R4: a second on, both doors are still held back against the sides by their stays "
		+ "(%.1f° and %.1f°), and E now offers to close them (%s)") % [held_open.x, held_open.y,
		_hint()])
	await _check_closing()
	_check(_camera_frames > 0 and _camera_in_door == 0,
		("R11: all the time he works the doors, his camera looking along the van as a player "
		+ "leaves it, the camera is never inside either door or against it, within 0.15 m, so "
		+ "the view never goes black (in or against a door in %d of %d frames)") % [_camera_in_door,
		_camera_frames])
	_finish()


func _check_opening() -> void:
	_sounds.clear()
	_driver.call("look_toward", -_van.global_basis.z)
	await _seconds(0.4)
	await _key(KEY_E)
	var started := _doing()
	var samples := await _record(true)
	_judge_common("opening", samples)
	var right := _first_moving(samples, 1)
	var left := _first_moving(samples, 0)
	_check(started and right >= 0 and _held_on(samples, right, 1, 1)
		and _held_while(samples, 1, 1, MOVED, 90.0),
		("R1 opening: E sets Ethan to it (%s); the right door does not move until his right "
		+ "palm is on its handle, and stays there while he pulls it to 90° (%s)") % [started,
		_grip_gaps(samples, 1, 1, MOVED, 90.0)])
	_check(left > right and _angles_at(samples, left).y >= 90.0 and _held_on(samples, left, 0, 0)
		and _held_while(samples, 0, 0, MOVED, 90.0),
		("R1 opening: the left door goes only after the right, which is out of its way (%.0f° "
		+ "when the left moves), his left palm on its release first and while he pulls it (%s)")
		% [_angles_at(samples, left).y if left >= 0 else -1.0,
		_grip_gaps(samples, 0, 0, MOVED, 90.0)])
	var swing := _free_swing(samples, 1)
	_check(swing["on_its_own"] and swing["slowing"] and swing["bounce"] <= BOUNCE
		and swing["home"] >= HOME,
		("R5: let go, the right door swings on by itself, slowing (%.0f°/s at 150°, %.0f°/s at "
		+ "250°), and its stay catches it at %.1f° with a bounce of %.1f° (at most %.0f°)")
		% [swing["at_150"], swing["at_250"], swing["home"], swing["bounce"], BOUNCE])
	var flagged := -1
	for index in range(samples.size()):
		if samples[index]["open"]:
			flagged = index
			break
	var end := _angles_at(samples, samples.size() - 1)
	var flagged_angles := _angles_at(samples, flagged) if flagged >= 0 else Vector2(-1.0, -1.0)
	var took: float = samples[-1]["time"] if not samples.is_empty() else INF
	_check(_sounds.count("release") == 2 and _sounds.count("stay") == 2 and _sounds.size() == 4,
		("R9 opening: each door sounds as it is worked: its latch freed by his hand, then its "
		+ "stay's knock as it catches it (%s)") % str(_sounds))
	_check(end.x >= HOME and end.y >= HOME and flagged >= 0 and flagged_angles.x >= HOME
		and flagged_angles.y >= HOME and took <= WITHIN,
		("R4 opening: both doors end on their stays (%.1f° and %.1f°); the van counts them open "
		+ "only once both are home (%.1f° and %.1f° then); all in %.1f s (at most %.0f)")
		% [end.x, end.y, flagged_angles.x, flagged_angles.y, took, WITHIN])


func _check_closing() -> void:
	_sounds.clear()
	_driver.call("look_toward", -_van.global_basis.z)
	await _seconds(0.4)
	await _key(KEY_E)
	var started := _doing()
	var samples := await _record(false)
	_judge_common("closing", samples)
	var left := _first_moving(samples, 0, true)
	var right := _first_moving(samples, 1, true)
	var left_shut := -1
	for index in range(samples.size()):
		if _angles_at(samples, index).x < SHUT:
			left_shut = index
			break
	_check(started and left >= 0 and right > left and left_shut >= 0 and right >= left_shut
		and _held_on(samples, left, 0, -1) and _held_on(samples, right, 1, -1),
		("R8 closing: E sets Ethan to it (%s); he takes the left door off its stay first, his "
		+ "hand on it as it moves, and shuts it before the right door leaves its stay (left "
		+ "shut at %.1f s, right moving at %.1f s), his hand on the right as it moves")
		% [started, samples[left_shut]["time"] if left_shut >= 0 else -1.0,
		samples[right]["time"] if right >= 0 else -1.0])
	_check(_sounds.count("unhook") == 2 and _sounds.count("latch") == 2 and _sounds.size() == 4,
		("R9 closing: each door sounds as it is worked: tugged off its stay, then its latch's "
		+ "clunk as it shuts (%s)") % str(_sounds))
	var end := _angles_at(samples, samples.size() - 1)
	var flagged := -1
	for index in range(samples.size()):
		if not samples[index]["open"]:
			flagged = index
			break
	var flagged_angles := _angles_at(samples, flagged) if flagged >= 0 else Vector2(-1.0, -1.0)
	var took: float = samples[-1]["time"] if not samples.is_empty() else INF
	_check(end.x < SHUT and end.y < SHUT and flagged >= 0 and flagged_angles.x < SHUT
		and flagged_angles.y < SHUT and took <= WITHIN_CLOSING
		and _hint() == "E  Open the rear doors",
		("R8 closing: both doors end shut (%.1f° and %.1f°), counted shut only once both are "
		+ "(%.1f° and %.1f° then), in %.1f s (at most %.0f, walking round to each side for its "
		+ "stay); E offers to open them again (%s)") % [end.x, end.y, flagged_angles.x,
		flagged_angles.y, took, WITHIN_CLOSING, _hint()])


## Smooth and solid, opening and closing alike: nothing jumps and nothing passes through him; his
## feet keep the pace of the walk he plays; the keys do not take him off it.
func _judge_common(way: String, samples: Array[Dictionary]) -> void:
	var door_tick := 0.0
	var body_tick := 0.0
	var lift_tick := 0.0
	var camera_tick := 0.0
	var nearest := INF
	var paced := true
	var worst_pace := ""
	for index in range(samples.size()):
		var now: Dictionary = samples[index]
		for side in range(2):
			nearest = minf(nearest, _clearance(now, side))
		if index == 0:
			continue
		var was: Dictionary = samples[index - 1]
		var angles := _angles_at(samples, index) - _angles_at(samples, index - 1)
		door_tick = maxf(door_tick, maxf(absf(angles.x), absf(angles.y)))
		var moved: Vector3 = now["body"] - was["body"]
		body_tick = maxf(body_tick, Vector2(moved.x, moved.z).length())
		lift_tick = maxf(lift_tick, absf(moved.y))
		camera_tick = maxf(camera_tick, (now["camera"] - was["camera"]).length())
		var speed := Vector2(moved.x, moved.z).length() * 60.0
		if speed > MOVING:
			var clip: String = now["clip"]
			var pace := WALK_PACE if clip == "Walk" else (WALK_BACK_PACE if clip == "WalkBack"
				else 0.0)
			var played: float = pace * float(now["rate"])
			if pace == 0.0 or absf(played - speed) > speed * PACE_SPREAD:
				if paced:
					worst_pace = "%s at %.2f s: %.2f m/s on %s at %.2fx" % [way, now["time"],
						speed, clip, now["rate"]]
				paced = false
	_check(door_tick <= DOOR_TICK and body_tick <= BODY_TICK and lift_tick <= LIFT_TICK
		and camera_tick <= CAMERA_TICK,
		("R3 %s: nothing jumps: a door turns at most %.1f° a frame (at most %.0f), Ethan moves "
		+ "%.3f m across and %.3f m up a frame, his camera %.3f m") % [way, door_tick,
		DOOR_TICK, body_tick, lift_tick, camera_tick])
	_check(nearest >= CLEARANCE,
		("R2 %s: no door passes through him: his body is never nearer than %.3f m to either "
		+ "door's slab (at least %.2f)") % [way, nearest, CLEARANCE])
	_check(paced and not samples.is_empty(),
		("R6 %s: whenever he moves he plays his walk forward or back at its own pace, his feet "
		+ "not sliding (%s)") % [way, "kept" if paced else worst_pace])


## Whether each rear door is joined to the van by its hinges as it stands now: "" if so, or
## what is not.
func _hinges_join() -> String:
	var faults: Array[String] = []
	for index in range(_doors.size()):
		var door := _doors[index]
		var arms := door.find_children("HingeArm*", "MeshInstance3D", false, false)
		var brackets := door.get_parent().find_children("HingeBracket%d*" % index,
			"MeshInstance3D", false, false)
		if arms.size() != HINGES_EACH or brackets.size() != HINGES_EACH:
			faults.append("door %d: %d arms and %d brackets" % [index, arms.size(),
				brackets.size()])
			continue
		var edge := _extents[index].position.x + _extents[index].size.x \
			if index == 1 else _extents[index].position.x
		var outer := _extents[index].position.z + _extents[index].size.z
		for hinge in range(HINGES_EACH):
			var arm := arms[hinge] as MeshInstance3D
			var bracket := brackets[hinge] as MeshInstance3D
			if arm.mesh is BoxMesh or bracket.mesh is BoxMesh:
				faults.append("door %d hinge %d a plain box, not the modelled hinge" % [index,
					hinge])
			var height := door.to_local(arm.global_position).y
			var pin := door.to_global(Vector3(0.0, height, 0.0))
			var door_edge := door.to_global(Vector3(edge, height, outer))
			var corner := _body_corner(door.get_parent() as Node3D, bracket.global_position,
				index)
			for gap: Array in [["arm to the door's edge", _apart(arm, door_edge)],
					["arm to the pin", _apart(arm, pin)], ["bracket to the pin",
					_apart(bracket, pin)], ["bracket to the body", _apart(bracket, corner)]]:
				if float(gap[1]) > TOUCHING:
					faults.append("door %d hinge %d %s %.3f m" % [index, hinge, gap[0], gap[1]])
	return "; ".join(faults)


## Whether every hinge is compact and in the doors' paint: "" if so, or what is not.
func _hinges_compact_and_painted() -> String:
	var faults: Array[String] = []
	for index in range(_doors.size()):
		var door := _doors[index]
		var edge := _extents[index].position.x + _extents[index].size.x \
			if index == 1 else _extents[index].position.x
		var parts := door.find_children("HingeArm*", "MeshInstance3D", false, false) \
			+ door.get_parent().find_children("HingeBracket%d*" % index, "MeshInstance3D", false,
			false)
		for found in parts:
			var part := found as MeshInstance3D
			var box := part.get_aabb()
			if part.get_parent() == door:
				var onto := edge - (part.position.x + box.position.x) if index == 1 \
					else part.position.x + box.end.x - edge
				if onto > ONTO_DOOR:
					faults.append("%s on door %d reaches %.3f m onto it" % [part.name, index,
						onto])
			if box.size.y > HINGE_TALL:
				faults.append("%s of door %d %.3f m tall" % [part.name, index, box.size.y])
			var finish: String = "paint" if door.to_local(part.global_position).y > 0.0 \
				else "trim"
			var wanted: Array = FINISHES[finish]
			var colour: Color = wanted[0]
			var paint := part.mesh.surface_get_material(0) as BaseMaterial3D \
				if part.mesh != null and part.mesh.get_surface_count() > 0 else null
			if paint == null or absf(paint.albedo_color.r - colour.r) > FINISH_NEAR \
					or absf(paint.albedo_color.g - colour.g) > FINISH_NEAR \
					or absf(paint.albedo_color.b - colour.b) > FINISH_NEAR \
					or absf(paint.roughness - float(wanted[1])) > FINISH_NEAR \
					or absf(paint.metallic - float(wanted[2])) > FINISH_NEAR:
				faults.append("%s of door %d not in the door's %s (%s)" % [part.name, index,
					finish, "none" if paint == null else "%s, rough %.3f, metal %.3f" % [
					paint.albedo_color, paint.roughness, paint.metallic]])
	return "; ".join(faults)


## How far `point`, in the world, is outside the box `mesh` draws.
func _apart(mesh: MeshInstance3D, point: Vector3) -> float:
	var local := mesh.to_local(point)
	var box := mesh.get_aabb()
	return (local - local.clamp(box.position, box.end)).length()


## The point of the van's body's surface, on the side of door `index`, nearest `near`: its rear
## corner by a hinge.
func _body_corner(art: Node3D, near: Vector3, index: int) -> Vector3:
	var body := art.get_node("Body") as MeshInstance3D
	var local := body.to_local(near)
	var nearest := Vector3.INF
	for surface in body.mesh.get_surface_count():
		var arrays := body.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var faces: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		for corner in range(0, faces.size(), 3):
			var a := vertices[faces[corner]]
			if signf(a.x) != (-1.0 if index == 0 else 1.0) or a.distance_to(local) > 0.3:
				continue
			var on := _on_triangle(local, a, vertices[faces[corner + 1]],
				vertices[faces[corner + 2]])
			if on.distance_squared_to(local) < nearest.distance_squared_to(local):
				nearest = on
	return body.to_global(nearest)


## The point of the triangle `a`, `b`, `c` nearest `p` (Ericson, Real-Time Collision Detection,
## 5.1.5).
func _on_triangle(p: Vector3, a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	var ab := b - a
	var ac := c - a
	var ap := p - a
	var d1 := ab.dot(ap)
	var d2 := ac.dot(ap)
	if d1 <= 0.0 and d2 <= 0.0:
		return a
	var bp := p - b
	var d3 := ab.dot(bp)
	var d4 := ac.dot(bp)
	if d3 >= 0.0 and d4 <= d3:
		return b
	var vc := d1 * d4 - d3 * d2
	if vc <= 0.0 and d1 >= 0.0 and d3 <= 0.0:
		return a + ab * (d1 / (d1 - d3))
	var cp := p - c
	var d5 := ab.dot(cp)
	var d6 := ac.dot(cp)
	if d6 >= 0.0 and d5 <= d6:
		return c
	var vb := d5 * d2 - d1 * d6
	if vb <= 0.0 and d2 >= 0.0 and d6 <= 0.0:
		return a + ac * (d2 / (d2 - d6))
	var va := d3 * d6 - d5 * d4
	if va <= 0.0 and d4 - d3 >= 0.0 and d5 - d6 >= 0.0:
		return b + (c - b) * ((d4 - d3) / ((d4 - d3) + (d5 - d6)))
	var whole := 1.0 / (va + vb + vc)
	return a + ab * (vb * whole) + ac * (vc * whole)


## Records every physics frame from E until the job is done or the limit runs out; on the way it
## holds W down for a second and presses E again, as a player might, which must change nothing.
func _record(opening: bool) -> Array[Dictionary]:
	var samples: Array[Dictionary] = []
	var time := 0.0
	var pressed_again := false
	while time < (WITHIN if opening else WITHIN_CLOSING) + 2.0:
		if time >= 1.0 and time < 2.0:
			Input.action_press("accelerate")
		elif Input.is_action_pressed("accelerate"):
			Input.action_release("accelerate")
		if time >= 3.0 and not pressed_again:
			pressed_again = true
			_tap(KEY_E)
		await physics_frame
		time += 1.0 / 60.0
		var held: Dictionary = _van.call("rear_door_hold") if _van.has_method("rear_door_hold") \
			else {}
		samples.append({"time": time, "angles": _angles(), "body": _driver.global_position,
			"camera": _camera.global_position, "palms": _palms.duplicate(), "held": held,
			"clip": _player.current_animation, "rate": _player.speed_scale,
			"open": bool(_van.get("rear_doors_open")), "doing": _doing()})
		if time > 1.0 and not _doing():
			break
	Input.action_release("accelerate")
	await _seconds(0.3)
	return samples


func _doing() -> bool:
	return _van.has_method("rear_doors_busy") and bool(_van.call("rear_doors_busy"))


func _first_moving(samples: Array[Dictionary], door: int, from_home := false) -> int:
	var start := _angles_at(samples, 0)
	var at := start.x if door == 0 else start.y
	for index in range(samples.size()):
		var angles := _angles_at(samples, index)
		var now := angles.x if door == 0 else angles.y
		if absf(now - at) > MOVED:
			return index
	return -1


## Whether at `index`, and the three frames before it, Ethan's `hand` (-1: either) holds `door`,
## his palm on its grip.
func _held_on(samples: Array[Dictionary], index: int, door: int, hand: int) -> bool:
	if index < 0:
		return false
	for back in range(4):
		var at := index - back
		if at < 0:
			return false
		if _grip_gap(samples[at], door, hand) > ON_GRIP:
			return false
	return true


## Whether, while `door` turns under his pull (from its first move until it first stands still,
## within `from` to `to` degrees), his `hand` is on its grip.
func _held_while(samples: Array[Dictionary], door: int, hand: int, from: float,
		to: float) -> bool:
	var frames := _pulled(samples, door, from, to)
	for index in frames:
		if _grip_gap(samples[index], door, hand) > ON_GRIP:
			return false
	return not frames.is_empty()


func _grip_gaps(samples: Array[Dictionary], door: int, hand: int, from: float,
		to: float) -> String:
	var most := 0.0
	var frames := _pulled(samples, door, from, to)
	for index in frames:
		most = maxf(most, _grip_gap(samples[index], door, hand))
	return "palm at most %.3f m off it over %d frames of the pull (at most %.2f)" % [most,
		frames.size(), ON_GRIP]


func _pulled(samples: Array[Dictionary], door: int, from: float, to: float) -> Array[int]:
	var frames: Array[int] = []
	var started := false
	for index in range(1, samples.size()):
		var now_angles := _angles_at(samples, index)
		var was_angles := _angles_at(samples, index - 1)
		var now := now_angles.x if door == 0 else now_angles.y
		var was := was_angles.x if door == 0 else was_angles.y
		var moving := absf(now - was) > 0.02
		if not started and moving and now >= from:
			started = true
		if started:
			if not moving or now > to:
				break
			frames.append(index)
	return frames


func _grip_gap(sample: Dictionary, door: int, hand: int) -> float:
	var held: Dictionary = sample["held"]
	if held.is_empty() or int(held["door"]) != door or (hand >= 0 and int(held["hand"]) != hand):
		return INF
	return (sample["palms"][int(held["hand"])] as Vector3).distance_to(held["grip"])


## The right door's swing once his hand has left it: on by itself, slowing, caught at its stay.
func _free_swing(samples: Array[Dictionary], door: int) -> Dictionary:
	var released := -1
	for index in range(samples.size()):
		var held: Dictionary = samples[index]["held"]
		var angles := _angles_at(samples, index)
		var now := angles.x if door == 0 else angles.y
		if now > 90.0 and (held.is_empty() or int(held["door"]) != door):
			released = index
			break
	var result := {"on_its_own": false, "slowing": false, "bounce": INF, "home": -1.0,
		"at_150": 0.0, "at_250": 0.0}
	if released < 0:
		return result
	var peak := -INF
	var after_peak := INF
	var on := true
	var reached := false
	for index in range(released + 1, samples.size()):
		var angles := _angles_at(samples, index)
		var now := angles.x if door == 0 else angles.y
		var was_angles := _angles_at(samples, index - 1)
		var was := was_angles.x if door == 0 else was_angles.y
		var rate := (now - was) * 60.0
		if not reached and now < was - 0.01:
			on = false
		if result["at_150"] == 0.0 and now >= 150.0:
			result["at_150"] = rate
		if result["at_250"] == 0.0 and now >= 250.0:
			result["at_250"] = rate
		if now >= 268.0:
			reached = true
		if reached:
			peak = maxf(peak, now)
			after_peak = minf(after_peak, now)
	var end := _angles_at(samples, samples.size() - 1)
	result["home"] = end.x if door == 0 else end.y
	result["on_its_own"] = on and reached
	result["slowing"] = result["at_150"] > 0.0 and result["at_250"] > 0.0 \
		and result["at_250"] < result["at_150"]
	result["bounce"] = peak - after_peak if reached else INF
	return result


## How near Ethan's body comes to the slab of `door`, his capsule's axis against the door's box.
func _clearance(sample: Dictionary, door: int) -> float:
	var node := _doors[door]
	var box := _extents[door]
	var angle: float = (sample["angles"] as Vector2)[door]
	var hinge: Transform3D = node.get_parent().global_transform * Transform3D(Basis(Vector3.UP,
		deg_to_rad(angle) * (1.0 if door == 1 else -1.0)), node.position)
	var nearest := INF
	for height in AXIS:
		var point: Vector3 = hinge.affine_inverse() * ((sample["body"] as Vector3)
			+ Vector3.UP * height)
		var inside := point.clamp(box.position, box.end)
		nearest = minf(nearest, (point - inside).length())
	return nearest


func _angles_at(samples: Array[Dictionary], index: int) -> Vector2:
	if index < 0 or index >= samples.size():
		return Vector2(-1.0, -1.0)
	return samples[index]["angles"]


func _angles() -> Vector2:
	return Vector2(absf(rad_to_deg(_doors[0].rotation.y)), absf(rad_to_deg(_doors[1].rotation.y)))


func _on_pose() -> void:
	if _camera != null and bool(_van.call("rear_doors_busy")):
		_camera_frames += 1
		for index in range(_doors.size()):
			if _extents[index].grow(CAMERA_SKIN).has_point(_doors[index].to_local(
					_camera.global_position)):
				_camera_in_door += 1
				break
	for side in range(2):
		var wrist := (_skeleton.global_transform * _skeleton.get_bone_global_pose(
			_hands[side])).origin
		var knuckle := (_skeleton.global_transform * _skeleton.get_bone_global_pose(
			_hands[side + 2])).origin
		_palms[side] = (wrist + knuckle) / 2.0


func _walk(points: Array[Vector3]) -> void:
	for point in points:
		var target := _van.to_global(point)
		var time := 0.0
		Input.action_press("accelerate")
		while _flat(target - _driver.global_position).length() > 0.3 and time < 12.0:
			_driver.call("look_toward", _flat(target - _driver.global_position).normalized())
			await physics_frame
			time += 1.0 / 60.0
		Input.action_release("accelerate")
	_driver.call("look_toward", -_van.global_basis.z)
	await _seconds(0.4)


func _hint() -> String:
	return (_hud.get("_hint") as Label).text


func _on_foot() -> bool:
	return not bool(_van.get("occupied")) and not bool(_app.get("_boarding"))


func _until(done: Callable, limit: float) -> void:
	var time := 0.0
	while not done.call() and time < limit:
		await physics_frame
		time += 1.0 / 60.0


func _flat(value: Vector3) -> Vector3:
	return Vector3(value.x, 0.0, value.z)


func _tap(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)


func _key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await process_frame
	await process_frame


func _seconds(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _build() -> void:
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	_hud = _app.get_node("DrivingHud")
	_van = _app.get_node("FreightVan")
	_driver = _app.get("driver")
	await process_frame
	await process_frame


func _store(text: String) -> void:
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _remove() -> void:
	for suffix in ["", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(_scratch + suffix):
			DirAccess.remove_absolute(_scratch + suffix)


func _timeout() -> void:
	_check(false, "The rear doors' checks finish within 240 s")
	_finish()


func _finish() -> void:
	print("REAR DOORS RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	_remove()
	quit(1 if _failures > 0 else 0)
