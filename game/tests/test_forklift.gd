extends SceneTree
## The audit's second fix (docs/PHASE_BRIEF.md, "the forklift", #321-#323): Kamran Mughal's
## four-wheel counterbalance truck made to move as a real one does. 2a, the model: its steering
## wheel, its two drive wheels, its two steer wheels and its mast cut free of its body, each with
## its origin at its own pivot, the carriage riding the mast. 2b-2c, over its two trips at work:
## no wheel scrubs sideways and its heading turns at v·tan(δ)/L; every wheel rolls its distance
## over its radius; its steering wheel at the steer's share of its turns to lock, never spun
## faster than a hand does; its mast tilted back with a load on the move and level to take or
## leave one; its lift's speeds; its blue spot lit whenever it moves; and it and its load never
## pass through anything solid. 2d, its driver: his left hand on the steering wheel's spinner
## knob as it turns, his right on the control lever beside the seat, or backing on the overhead
## guard's rear post with his chest turned, each hand within 8 cm of what it holds throughout.

const MODEL := "res://features/environments/industrial_loop/art/depot/forklift.glb"
## Each part's pivot in the model (Godot's axes, the forks toward +z), measured from the source:
## a wheel's on its axle in its tyre's middle plane (its hub stands inboard of it).
const PIVOTS := {"SteeringWheel": Vector3(0.0, 1.415, -0.405),
	"DriveWheelL": Vector3(0.515, 0.32, 0.195), "DriveWheelR": Vector3(-0.515, 0.32, 0.195),
	"SteerWheelL": Vector3(0.515, 0.275, -1.265), "SteerWheelR": Vector3(-0.515, 0.275, -1.265)}
const PIVOT_WITHIN := 0.02
const CENTRED_WITHIN := 0.015
const START_SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const NEAR := Vector3(-55.0, 4.0, 13.0)
const TRIP_LIMIT := 420.0
const FLOOR := 1.3
const WHEELBASE := 1.461
const FRONT_AXLE := -0.055
const LOCK_INNER := deg_to_rad(80.0)
const LOCK_TURNS := 2.25
const HANDS_RATE := 1.5
const RADII := {"DriveWheelL": 0.318, "DriveWheelR": 0.318, "SteerWheelL": 0.277,
	"SteerWheelR": 0.277}
const COLUMN := Vector3(0.0, -0.70711, 0.70711)
const SCRUB_WITHIN := deg_to_rad(1.5)
const YAW_WITHIN := 0.05
const ROLL_WITHIN := 0.03
const TILT_LOADED := Vector2(deg_to_rad(3.0), deg_to_rad(5.0))
const LEVEL_WITHIN := deg_to_rad(0.5)
const LIFT_UP := 0.35
const LOWER := 0.5
const BODY := Vector3(1.12, 2.21, 3.3)
const AXLE := 0.25
const HOLD_WITHIN := 0.08
## The control lever's knob beside the seat (measured from the model) and the overhead guard's
## right rear post, where his right hand goes.
const LEVER := Vector3(-0.387, 1.16, -0.546)
const GUARD_POST := Vector3(-0.475, 1.35, -1.11)

var _scratch: String
var _app: Node3D

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(900.0, true, false, true).timeout.connect(_timeout)
	var truck := (load(MODEL) as PackedScene).instantiate() as Node3D
	root.add_child(truck)
	await process_frame
	_check_parts(truck)
	truck.queue_free()
	await _check_work()
	_finish()


func _check_work() -> void:
	_scratch = OS.get_temp_dir().path_join("blackridge-forklift-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(START_SAVE)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	await process_frame
	_app.call("_resume")
	await physics_frame
	var shed := _app.get_node("IndustrialLoop").get("transfer_shed") as Node3D
	var forklift := shed.get_node("Building/Forklift") as Node3D
	var model := forklift.get_child(0) as Node3D
	var parts := {}
	for label: String in ["SteeringWheel", "Mast"] + RADII.keys():
		parts[label] = model.find_child(label, true, false)
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.global_position = NEAR
	camera.make_current()
	var space := _app.get_world_3d().direct_space_state
	var box := BoxShape3D.new()
	box.size = BODY - Vector3(0.1, 0.25, 0.1)
	var last := forklift.global_transform
	var hubs := {}
	var rolled := {}
	for label: String in RADII:
		hubs[label] = (parts[label] as Node3D).global_position
		rolled[label] = 0.0
	var worst := {"scrub": 0.0, "yaw": 0.0, "turns": 0.0, "rate": 0.0, "tilt_out": 0,
		"level": 0.0, "up": 0.0, "down": 0.0, "dark": 0, "clips": [], "inner": 0.0}
	var rolled_by := {}
	for label: String in RADII:
		rolled_by[label] = 0.0
	var was_carrying := false
	var last_lift := 0.0
	var last_turns := 0.0
	var wheel_then := (parts["SteeringWheel"] as Node3D).basis
	var still := 0
	var step_then := -1
	var spun_total := 0.0
	var moving := 0
	var time := 0.0
	var dt := 1.0 / 60.0
	while time < TRIP_LIMIT:
		await physics_frame
		time += dt
		var now := forklift.global_transform
		var speed := absf(float(forklift.call("speed")))
		var heading_rate := angle_difference(atan2(last.basis.z.x, last.basis.z.z),
			atan2(now.basis.z.x, now.basis.z.z)) / dt
		var front_now := now * Vector3(0.0, 0.0, FRONT_AXLE)
		var front_then := last * Vector3(0.0, 0.0, FRONT_AXLE)
		var front_move := front_now - front_then
		var steer := float(forklift.call("steer"))
		if front_move.length() > 0.002:
			moving += 1
			var along := front_move.dot(now.basis.z) / dt
			var expected := along * tan(steer) / WHEELBASE
			if absf(expected) > 0.05:
				worst["yaw"] = maxf(float(worst["yaw"]), maxf(absf(heading_rate - expected)
					- 0.01, 0.0) / absf(expected))
			for label: String in RADII:
				var hub := (parts[label] as Node3D).global_position
				var moved: Vector3 = hub - hubs[label]
				var flat := Vector3(moved.x, 0.0, moved.z)
				var ahead := _rolling_way(parts[label] as Node3D)
				if flat.length() > 0.003:
					var scrub := flat.normalized().angle_to(ahead * signf(flat.dot(ahead)))
					worst["scrub"] = maxf(float(worst["scrub"]), scrub)
				rolled_by[label] = float(rolled_by[label]) + moved.dot(ahead) / float(RADII[label])
			if String(forklift.call("phase")) != "parked" and not ((forklift.find_child(
					"BlueSpotFront", false, false) as Node3D).visible
					or (forklift.find_child("BlueSpotRear", false, false) as Node3D).visible):
				worst["dark"] = int(worst["dark"]) + 1
				worst["dark_at"] = "%s at %.2f m/s, moved %.4f m" % [String(forklift.call(
					"phase")), speed, front_move.length()]
			if moving % 6 == 0:
				var query := PhysicsShapeQueryParameters3D.new()
				query.shape = box
				query.transform = Transform3D(now.basis, now * Vector3(0.0, BODY.y / 2.0 + 0.15,
					-AXLE))
				var skip: Array[RID] = [(forklift as CollisionObject3D).get_rid()]
				var load := forklift.call("load_node") as Node3D
				for body in load.find_children("*", "CollisionObject3D", true, false):
					skip.append((body as CollisionObject3D).get_rid())
				if load is CollisionObject3D:
					skip.append((load as CollisionObject3D).get_rid())
				query.exclude = skip
				for hit in space.intersect_shape(query, 4):
					var other := hit.get("collider") as Node
					var what := String(other.name) if other != null else "?"
					var where := "%s at %s in %s" % [what, Vector2(now.origin.x, now.origin.z)
						.snapped(Vector2.ONE * 0.1), String(forklift.call("phase"))]
					if (worst["clips"] as Array).size() < 6:
						(worst["clips"] as Array).append(where)
		for label: String in RADII:
			hubs[label] = (parts[label] as Node3D).global_position
		var wheels: Dictionary = forklift.call("steer_wheels")
		for label: String in ["SteerWheelL", "SteerWheelR"]:
			worst["inner"] = maxf(float(worst["inner"]), absf(float(wheels[label])))
		var wheel := parts["SteeringWheel"] as Node3D
		var step_spun := _spun(wheel_then.inverse() * wheel.basis) / TAU
		spun_total += step_spun
		wheel_then = wheel.basis
		var turns := float(forklift.call("steering_turns"))
		worst["turns"] = maxf(float(worst["turns"]), absf(-spun_total - turns))
		var spin := absf(step_spun) / dt
		if spin > float(worst["rate"]):
			worst["rate"] = spin
			worst["rate_at"] = "%s at %.2f m/s" % [String(forklift.call("phase")), speed]
		last_turns = turns
		var tilt := float(forklift.call("tilt"))
		var mast_tilt := -(parts["Mast"] as Node3D).basis.get_euler().x
		worst["tilt_seen"] = maxf(float(worst.get("tilt_seen", 0.0)), absf(mast_tilt - tilt))
		var carrying := bool(forklift.call("carrying"))
		if carrying and speed > 0.2 and (tilt < TILT_LOADED.x or tilt > TILT_LOADED.y):
			worst["tilt_out"] = int(worst["tilt_out"]) + 1
		if carrying != was_carrying:
			worst["level"] = maxf(float(worst["level"]), absf(tilt))
			was_carrying = carrying
		var lift := float(forklift.call("lift"))
		var rate := (lift - last_lift) / dt
		worst["up"] = maxf(float(worst["up"]), rate)
		worst["down"] = maxf(float(worst["down"]), -rate)
		last_lift = lift
		var fit: Dictionary = forklift.call("driver_fit")
		if not fit.is_empty():
			worst["held"] = maxf(float(worst.get("held", 0.0)), float(fit["hands"]))
		var grips: Array = forklift.call("grips")
		var knob := forklift.call("knob_point") as Vector3
		var on_knob := (grips[0] as Vector3).distance_to(knob)
		worst["knob"] = maxf(float(worst.get("knob", 0.0)), on_knob)
		var right := model.to_local(grips[1] as Vector3)
		var at_rest := right.distance_to(GUARD_POST) if bool(forklift.call("reversing")) \
			else right.distance_to(LEVER)
		var step_now := int(forklift.get("_step"))
		still = still + 1 if speed < 0.01 and String(forklift.call("phase")) != "parked" \
			and step_now == step_then else 0
		step_then = step_now
		if String(forklift.call("phase")) != "parked" and still > 30 \
				or bool(forklift.call("reversing")) and speed > 0.5:
			if at_rest > float(worst.get("right", 0.0)):
				worst["right"] = at_rest
				worst["right_at"] = "%s, %s, %.2f m/s, still %d" % [String(forklift.call("phase")),
					"backing" if bool(forklift.call("reversing")) else "ahead", speed, still]
		var twist := float(forklift.call("chest_turned"))
		if bool(forklift.call("reversing")) and speed > 0.5:
			worst["twist_low"] = minf(float(worst.get("twist_low", PI)), twist)
		last = now
		if int(forklift.get("trips")) >= 2 and String(forklift.call("phase")) == "parked":
			break
	var off := 0.0
	var own: Dictionary = forklift.call("rolled")
	for label: String in RADII:
		var by := absf(float(rolled_by[label]))
		off = maxf(off, absf(absf(float(own[label])) - by) / maxf(by, 0.001))
	_check(int(forklift.get("trips")) >= 2 and moving > 0, "F2: it works its two trips (%.0f s)"
		% time)
	_check(float(worst["scrub"]) <= SCRUB_WITHIN and float(worst["yaw"]) <= YAW_WITHIN,
		"F2: no wheel scrubs sideways (the worst %.2f°) and its heading turns at v·tan(δ)/L "
		% rad_to_deg(float(worst["scrub"])) + "(within %.1f%%)" % (float(worst["yaw"]) * 100.0))
	_check(float(worst["inner"]) <= LOCK_INNER + 0.001, "F3: its inner steer wheel never past "
		+ "80° (%.1f°)" % rad_to_deg(float(worst["inner"])))
	_check(off <= ROLL_WITHIN, "F4: every wheel rolls its distance over its radius (within %.1f%%)"
		% (off * 100.0))
	_check(float(worst["turns"]) < 0.01 and float(worst["rate"]) <= HANDS_RATE + 0.01,
		"F5: its steering wheel at the steer's share of %.2f turns to lock (off %.3f turns), " % [
		LOCK_TURNS, float(worst["turns"])] + "never faster than %.1f turns a second (%.2f, " % [
		HANDS_RATE, float(worst["rate"])] + "in %s)" % String(worst.get("rate_at", "-")))
	_check(int(worst["tilt_out"]) == 0 and float(worst["level"]) <= LEVEL_WITHIN
		and float(worst.get("tilt_seen", 0.0)) < 0.001, "F6: its mast tilted back 3-5° with a "
		+ "load "
		+ "on the move (%d frames out), level at take and leave (%.2f°)" % [int(worst["tilt_out"]),
		rad_to_deg(float(worst["level"]))])
	_check(absf(float(worst["up"]) - LIFT_UP) < 0.02 and absf(float(worst["down"]) - LOWER) < 0.02,
		"F7: its forks rise at %.2f m/s and lower at %.2f m/s" % [float(worst["up"]),
		float(worst["down"])])
	_check(int(worst["dark"]) == 0, "F8: its blue spot lit whenever it moves (%d frames dark%s)"
		% [int(worst["dark"]), ", last in " + String(worst["dark_at"]) if worst.has("dark_at")
		else ""])
	_check(float(worst.get("held", INF)) <= HOLD_WITHIN and float(worst.get("knob", INF)) < 0.01,
		"F10: his left hand on the spinner knob, each hand within 8 cm of what it holds through "
		+ "both trips (the farthest %.3f m)" % float(worst.get("held", INF)))
	_check(float(worst.get("right", INF)) < 0.03 and float(worst.get("twist_low", 0.0))
		>= deg_to_rad(25.0), "F10: his right hand on the lever when he stands, on the guard's post "
		+ "as he backs (%.3f m, %s), his chest turned %.0f° backing" % [float(worst.get("right",
		INF)), String(worst.get("right_at", "-")), rad_to_deg(float(worst.get("twist_low", 0.0)))])
	_check((worst["clips"] as Array).is_empty(), "F9: it and its load never pass through anything "
		+ "solid (%s)" % ", ".join(worst["clips"] as Array))


## The way a wheel rolls: square to its axle (its own x, which its roll leaves where it is).
func _rolling_way(part: Node3D) -> Vector3:
	var axle := part.global_basis.x
	var way := axle.cross(Vector3.UP)
	return Vector3(way.x, 0.0, way.z).normalized()


## How far `basis` has turned about the steering column, signed.
func _spun(basis: Basis) -> float:
	var q := basis.get_rotation_quaternion()
	var angle := q.get_angle()
	var axis := q.get_axis()
	return angle * signf(axis.dot(COLUMN)) if angle > 0.0001 else 0.0


func _timeout() -> void:
	_check(false, "The forklift's checks finish within 900 s")
	_finish()


func _check_parts(truck: Node3D) -> void:
	var missing: Array[String] = []
	var off: Array[String] = []
	for label: String in PIVOTS:
		var part := truck.find_child(label, true, false) as Node3D
		if part == null:
			missing.append(label)
			continue
		var at := truck.to_local(part.global_position)
		var box := _box(part, truck)
		var middle := box.get_center()
		var across := middle.distance_to(at)
		if label != "SteeringWheel":
			across = Vector2(middle.y - at.y, middle.z - at.z).length()
		if at.distance_to(PIVOTS[label]) > PIVOT_WITHIN or across > CENTRED_WITHIN:
			off.append("%s at %s, its middle %s" % [label, at.snapped(Vector3.ONE * 0.001),
				box.get_center().snapped(Vector3.ONE * 0.001)])
	var mast := truck.find_child("Mast", true, false) as Node3D
	var carriage := truck.find_child("Carriage", true, false) as Node3D
	if mast == null:
		missing.append("Mast")
	else:
		var foot := truck.to_local(mast.global_position)
		var tall := _box(mast, truck)
		if foot.y > 0.5 or tall.size.y < 1.9 or tall.position.z < 0.25:
			off.append("Mast at %s, %.2f m tall" % [foot.snapped(Vector3.ONE * 0.001),
				tall.size.y])
	var rides := carriage != null and mast != null and mast.is_ancestor_of(carriage)
	_check(missing.is_empty() and off.is_empty(), "F1: its steering wheel, drive wheels, steer "
		+ "wheels and mast cut free, each about its own pivot (missing: %s; off: %s)" % [
		", ".join(missing), "; ".join(off)])
	var body := truck.find_child("Truck", true, false) as Node3D
	var wheel_in_body := false
	if body != null:
		var hull := _box(body, truck)
		wheel_in_body = hull.position.y < 0.05
	_check(rides and body != null and not wheel_in_body, "F1: the carriage rides the mast, and "
		+ "the body no longer holds the wheels (its lowest %.2f m)" % (_box(body, truck)
		.position.y if body != null else -1.0))


## The part's own meshes, as a box in the truck's frame.
func _box(part: Node3D, truck: Node3D) -> AABB:
	var merged := AABB()
	var meshes: Array = [part] if part is MeshInstance3D else []
	for found in part.find_children("*", "MeshInstance3D", true, false):
		if not meshes.has(found):
			meshes.append(found)
	for found in meshes:
		var mesh := found as MeshInstance3D
		if mesh.get_parent() != part and mesh != part and not _own(mesh, part):
			continue
		var box := truck.global_transform.affine_inverse() * mesh.global_transform \
			* mesh.get_aabb()
		merged = box if not merged.has_volume() else merged.merge(box)
	return merged


## Whether `mesh` belongs to `part` itself rather than to a part riding it (the mast's carriage).
func _own(mesh: Node, part: Node3D) -> bool:
	var at := mesh.get_parent()
	while at != null and at != part:
		if at is Node3D and String(at.name) == "Carriage":
			return false
		at = at.get_parent()
	return at == part


func _finish() -> void:
	print("FORKLIFT RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	if _scratch != "":
		for suffix in ["", ".tmp", ".corrupt"]:
			if FileAccess.file_exists(_scratch + suffix):
				DirAccess.remove_absolute(_scratch + suffix)
	quit(1 if _failures > 0 else 0)
