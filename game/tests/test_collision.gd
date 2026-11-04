extends SceneTree

const APPROACH := 672
const LANE := 1.0
const RUN_SPEED := 8.0
const LOCKED_LOSS := 8.0
const LANE_HOLD := 0.3
const LaneKeeper = preload("res://tests/lane_keeper.gd")
const OncomingVan = preload("res://features/vehicles/oncoming_van/oncoming_van.gd")
const Mission = preload("res://features/missions/night_freight/first_drive.gd")
const DEPOT := Vector3(-28.0, 0.1, 93.0)
const KNEE := Vector3(-1.0, 0.0, 0.0)
const LEFT_ELBOW := Vector3(0.33, 0.0, 0.94)
const RIGHT_ELBOW := Vector3(0.18, 0.0, -0.98)
const Presentation = preload("res://features/vehicles/freight_van/van_presentation.gd")
const SIGHT_LAYER := 1 << 19
const BUMPER := 2.45
const HOOD_MARGIN := 0.3
const SEE_THROUGH := [BaseMaterial3D.TRANSPARENCY_ALPHA,
	BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS]

var _checks: int = 0
var _failures: int = 0
var _app: Node3D
var _van: CharacterBody3D
var _route: Node
var _road: RefCounted
var _hud: CanvasLayer
var _presentation: Node3D
var _head_on_glass := Vector3.ZERO
var _crack: float = 0.0
var _scratch: String
var _after_hit := PackedByteArray()


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(150.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-collision-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	_van = _app.get_node("FreightVan")
	_route = _app.get_node("DrivingTrial")
	_road = _app.get_node("IndustrialLoop").get("road")
	_hud = _app.get_node("DrivingHud")
	_presentation = _van.get_node("VanPresentation")
	await process_frame
	_app.call("_resume")
	await physics_frame
	_route.set("stage", Mission.ENCOUNTER_STAGE)
	_place(APPROACH, LANE)
	_van.set("speed", RUN_SPEED)
	var keeper := LaneKeeper.new(_road, APPROACH)
	var waited := 0.0
	while not is_instance_valid(_route.get("oncoming")) and waited < 15.0:
		await physics_frame
		waited += 1.0 / 60.0
		keeper.steer(_van, LANE)
		_hold("accelerate", float(_van.get("speed")) < RUN_SPEED)
	var oncoming: Node3D = _route.get("oncoming")
	var pedestrian: Node3D = _route.get("pedestrian")
	var crossing: Node3D = _route.get("crossing")
	if not is_instance_valid(oncoming) or not is_instance_valid(pedestrian) or crossing == null:
		keeper.release()
		_hold("accelerate", false)
		_check(false, "Driving down into the second hairpin, the encounter begins")
		_finish()
		return
	_check(bool(pedestrian.get("waiting")) and pedestrian.call("animation") == "Idle"
		and pedestrian.global_position.distance_to(crossing.kerb) < 0.05,
		"He waits at the bus stop's crossing, breathing, as the oncoming van comes")
	await _check_approach(pedestrian, oncoming, crossing, keeper)
	keeper.release()
	_hold("accelerate", false)
	if not is_instance_valid(pedestrian) or bool(pedestrian.get("waiting")):
		_check(false, "He steps out onto the crossing as the van comes")
		_finish()
		return
	_hold("brake", true)
	_hold("steer_left", true)
	await _check_step_out(pedestrian, crossing)
	_hold("steer_left", false)
	await _check_aftermath(pedestrian, oncoming)
	_check_checkpoint(pedestrian)
	await _check_depot()
	_check(is_equal_approx(_amount(), _crack),
		"The crack stays for the rest of the drive (%.2f at the depot)" % _amount())
	var finished := ConfigFile.new()
	_check(finished.load(_scratch) == OK and finished.get_value("drive", "stage", -1) == 0
		and not finished.has_section_key("drive", "body"),
		"With the drive over, the save goes back to its start, so the next launch begins a new "
		+ "drive")
	await _check_continue()
	_hud.restart_requested.emit()
	await _seconds(0.3)
	_check(is_zero_approx(_amount()), "New drive brings back an unbroken windshield")
	_check(not is_instance_valid(_route.get("pedestrian")) and not bool(_route.get("fleeing"))
		and bool((_app.get("_audio").get("_music") as AudioStreamPlayer).playing),
		"New drive clears the pedestrian and brings the music back")
	_check(not paused and (_hud.get("_heading") as Control).visible
		and (_hud.get("_fade") as ColorRect).modulate.a < 0.01
		and (_hud.get("_resume") as Button).text == "Begin / continue drive",
		"New drive leaves the ending behind: the screen is clear and the objective is back")
	_finish()


func _check_approach(pedestrian: Node3D, oncoming: Node3D, crossing: Node3D,
		keeper: RefCounted) -> void:
	var always_high := true
	var gone_by := false
	var darkest := 1.0
	var yours := true
	var waited := 0.0
	while is_instance_valid(pedestrian) and bool(pedestrian.get("waiting")) and waited < 30.0:
		await physics_frame
		waited += 1.0 / 60.0
		keeper.steer(_van, LANE)
		_hold("accelerate", float(_van.get("speed")) < RUN_SPEED)
		if bool(pedestrian.get("waiting")):
			yours = yours and not bool(_van.get("scripted")) and not bool(_van.get("locked"))
		var here := int(_route.call("_nearest_index", _van.global_position))
		if is_instance_valid(oncoming):
			always_high = always_high and bool(oncoming.get("high_beams"))
			gone_by = float(oncoming.get("distance")) < here * OncomingVan.SPACING
		var camera: Camera3D = _presentation.get("driving_camera")
		var exposure := (camera.attributes as CameraAttributesPractical).exposure_multiplier
		darkest = minf(darkest, exposure)
	_check(always_high and darkest < 0.4,
		"The oncoming van keeps its high beams on and blinds the driver (the view darkens to "
		+ "%.2f)" % darkest)
	_check(gone_by or not is_instance_valid(oncoming),
		"No one is on the road while the oncoming van passes: he steps out only once it is past "
		+ "him")
	_check(yours, "You drive all the way: the wheel and the pedals are yours until he steps out "
		+ "(%.0f km/h)" % (float(_van.get("speed")) * 3.6))


func _check_step_out(pedestrian: Node3D, crossing: Node3D) -> void:
	var front := _van.global_position - _van.global_basis.z * BUMPER
	var gap: float = (crossing.centre - front).dot(crossing.forward)
	var heading: Vector3 = pedestrian.get("_heading")
	var speed := float(_van.get("speed"))
	_check(pedestrian.global_position.distance_to(crossing.kerb) < 0.1
		and heading.dot(-crossing.right) > 0.8 and gap > 0.0 and gap < 30.0,
		"He steps off the kerb onto the crossing, %.1f m before the van's bumper reaches it " % gap
		+ "(%.0f km/h)" % (speed * 3.6))
	var froze_first := false
	var locked := true
	var skid := false
	var slid := 0.0
	var lane_then := _lane()
	var waited := 0.0
	while not bool(pedestrian.get("hit")) and waited < 4.0:
		await physics_frame
		waited += 1.0 / 60.0
		froze_first = froze_first or bool(pedestrian.get("frozen"))
		if not bool(pedestrian.get("hit")):
			locked = locked and bool(_van.get("locked"))
			skid = skid or bool(_app.get("_audio").call("skidding"))
			slid = maxf(slid, absf(_lane() - lane_then))
	var hit_speed := float(_van.get("speed")) * 3.6
	_check(bool(pedestrian.get("hit")) and locked and skid and hit_speed > 25.0
		and speed * 3.6 - hit_speed < LOCKED_LOSS,
		"Braking hard, the wheels lock on the wet paint: the tyres skid, the van slows only from "
		+ "%.0f to %.0f km/h, and it hits him %.1f s after he steps out" % [speed * 3.6,
		hit_speed, waited])
	_check(slid < LANE_HOLD,
		"Turning the wheel does nothing in the skid: the van slides on in its lane "
		+ "(%.2f m across)" % slid)
	var struck_at: Vector3 = pedestrian.call("hips_position") - crossing.centre
	var along: float = struck_at.dot(crossing.forward)
	var across: float = struck_at.dot(crossing.right)
	_check(absf(along) < 2.1 and absf(across) < float(crossing.half_width) + 0.5,
		"He is struck on the crossing (%.2f m along, %.2f m across)" % [along, across])
	var head_at: Vector3 = pedestrian.call("head_position")
	var since := 0.0
	var coasting := 0.0
	while _glass("crack_amount") == null or float(_glass("crack_amount")) <= 0.0:
		head_at = pedestrian.call("head_position")
		await physics_frame
		since += 1.0 / 60.0
		if since > 1.0:
			break
	var head := _pane().global_transform.affine_inverse() * head_at
	_head_on_glass = head
	_check(since < 0.5 and -head.z < Presentation.HEAD_REACH,
		"His head strikes the base of the windshield %.2f s after the impact " % since
		+ "(%.2f m out from the glass)" % -head.z)
	while since < Mission.REACTION - 0.1:
		await physics_frame
		since += 1.0 / 60.0
	coasting = float(_van.get("speed")) * 3.6
	_check(coasting > hit_speed * 0.9 and not bool(_van.get("held")),
		"The van carries him on for half a second (%.0f km/h), before Ethan brakes" % coasting)
	_check(froze_first, "He freezes in the headlights just before the impact")
	_check(bool(pedestrian.call("simulating")) and pedestrian.call("animation") == "",
		"At the impact he goes limp: a physics ragdoll takes over from the animation")
	_check((_app.get("_audio").get("_body_impact") as AudioStreamPlayer).playing,
		"The body strikes the van with a heavy impact sound")
	_check(not bool((_app.get("_audio").get("_music") as AudioStreamPlayer).playing),
		"The music cuts out")


func _check_aftermath(pedestrian: Node3D, oncoming: Node3D) -> void:
	if is_instance_valid(oncoming):
		var from_him: Vector3 = oncoming.global_position - pedestrian.call("hips_position")
		var away := (-oncoming.global_basis.z).dot(from_him.normalized()) > 0.5
		_check(_van.to_local(oncoming.global_position).z > 0.0 and away
			and from_him.length() > 15.0,
			"The oncoming van is behind, %.0f m away and driving off: no witness"
			% from_him.length())
	else:
		_check(true, "The oncoming van is already gone: no witness")
	_hold("brake", false)
	_hold("accelerate", true)
	var bones: Dictionary = pedestrian.get("bones")
	var lowest := INF
	var knees := INF
	var elbows := INF
	var knees_most := -INF
	var elbows_most := -INF
	var rested_at := -1.0
	var hips := Vector3.ZERO
	var clear := -INF
	var held_for := 0.0
	var crept := 0.0
	var rock := 0.0
	var sample := {}
	var waited := 0.0
	while waited < 14.0 and (bool(_van.get("held")) or rested_at < 0.0):
		await physics_frame
		waited += 1.0 / 60.0
		if rested_at < 0.0 and bool(pedestrian.get("settled")):
			rested_at = waited
			hips = pedestrian.call("hips_position")
			clear = -_van.to_local(hips).z - BUMPER
		lowest = minf(lowest, _clearance(pedestrian.call("hips_position")))
		knees = minf(knees, minf(_bend(bones, "LeftUpLeg", "LeftLeg", KNEE),
			_bend(bones, "RightUpLeg", "RightLeg", KNEE)))
		elbows = minf(elbows, minf(_bend(bones, "LeftArm", "LeftForeArm", LEFT_ELBOW),
			_bend(bones, "RightArm", "RightForeArm", RIGHT_ELBOW)))
		knees_most = maxf(knees_most, maxf(_bend(bones, "LeftUpLeg", "LeftLeg", KNEE),
			_bend(bones, "RightUpLeg", "RightLeg", KNEE)))
		elbows_most = maxf(elbows_most, maxf(_bend(bones, "LeftArm", "LeftForeArm", LEFT_ELBOW),
			_bend(bones, "RightArm", "RightForeArm", RIGHT_ELBOW)))
		rock = maxf(rock, absf(float(_presentation.get("_rock"))))
		if bool(_van.get("held")):
			if absf(float(_van.get("speed"))) < 0.05:
				held_for += 1.0 / 60.0
			if held_for > 0.0:
				crept = maxf(crept, absf(float(_van.get("speed"))))
			if held_for >= 3.0 and sample.is_empty():
				sample = _sight_sample(bones)
				_hold("accelerate", false)
	_check(rested_at > 0.0 and rested_at < 10.0,
		"Thrown by the van, he tumbles and comes to rest (%.1f s)" % rested_at)
	_check(clear > 0.5, "He is thrown clear and lies %.1f m ahead of the bumper, in the beams"
		% clear)
	_check(_clearance(hips) < 0.4, "He lies on the road (hips %.2f m up)" % _clearance(hips))
	_check(lowest > 0.0, "His body never sinks into the road (lowest %.2f m)" % lowest)
	_check(knees > -30.0 and elbows > -30.0,
		"Knees and elbows bend no more than 30 degrees the wrong way as he tumbles " +
		"(worst %.0f and %.0f degrees)" % [knees, elbows])
	_check(knees_most < 155.0 and elbows_most < 155.0,
		"Knees and elbows never fold past their range (most %.0f and %.0f degrees)"
		% [knees_most, elbows_most])
	_check(held_for > 3.5 and crept < 0.1,
		"The van skids to a stop and holds there (%.1f s) despite the throttle" % held_for)
	_check(rock > 0.002 and rock < 0.02,
		"The cab rocks on its springs at the impact (%.2f degrees)" % rad_to_deg(rock))
	await _check_lean(sample)
	await _tap("interact")
	_check(bool(_van.get("occupied")), "E does nothing: Ethan does not get out")
	_check(bool(_route.get("fleeing")) and _objective() == "DRIVE.", "The objective reads DRIVE.")
	var stopped_at := _van.global_position
	await _seconds(3.0)
	var rolled := _van.global_position.distance_to(stopped_at)
	_check(rolled < 0.05 and bool(_van.get("braking")),
		"On the 9% grade Ethan keeps his foot on the brake until you drive, so the van never "
		+ "rolls onto him (%.2f m in 3 s)" % rolled)
	_hold("accelerate", true)
	await _seconds(1.5)
	_hold("accelerate", false)
	_check(float(_van.get("speed")) > 2.0, "Then the van drives again (%.1f m/s)"
		% float(_van.get("speed")))
	var eye := (_presentation.get("_look") as Node3D).position
	_check(eye.distance_to(Presentation.EYE) < 0.02,
		"Ethan sits back in his seat to drive (eye %.2f m from the seat position)"
		% eye.distance_to(Presentation.EYE))


func _sight_sample(bones: Dictionary) -> Dictionary:
	var camera: Camera3D = _presentation.get("driving_camera")
	var points: Array[Vector3] = []
	for bone: Node3D in bones.values():
		points.append(bone.global_position)
	return {"cab": _presentation.global_transform, "van": _van.global_transform,
		"eye": camera.global_position,
		"forward": -camera.global_basis.z, "hips": (bones["Hips"] as Node3D).global_position,
		"lean": (_presentation.get("_look") as Node3D).position - Presentation.EYE,
		"points": points}


func _check_lean(sample: Dictionary) -> void:
	if sample.is_empty():
		_check(false, "Leaning over the wheel, Ethan looks for him")
		return
	var cab: Transform3D = sample["cab"]
	var occluder := _cab_occluder(cab)
	root.add_child(occluder)
	await physics_frame
	await physics_frame
	var space := _van.get_world_3d().direct_space_state
	var van: Transform3D = sample["van"]
	var hips := van.affine_inverse() * (sample["hips"] as Vector3)
	var seated_reach := _first_in_view(space, cab * Presentation.EYE, van, hips)
	var leaning_reach := _first_in_view(space, sample["eye"], van, hips)
	var seated := 0
	var leaning := 0
	var near_seen := 0
	for point: Vector3 in sample["points"]:
		var seen_leaning := _clear_sight(space, sample["eye"], point)
		seated += 1 if _clear_sight(space, cab * Presentation.EYE, point) else 0
		leaning += 1 if seen_leaning else 0
		var past := -(van.affine_inverse() * point).z - BUMPER
		near_seen += 1 if seen_leaning and past < leaning_reach - HOOD_MARGIN else 0
	var crack: Vector2 = _glass("crack_point") if _glass("crack_point") != null else Vector2.INF
	var pane := _presentation.global_transform.affine_inverse() * _pane().global_transform
	var on_glass := pane * Vector3(crack.x, crack.y, 0.0)
	var in_view := _clear_sight(space, cab * Presentation.EYE, cab * on_glass) \
		and _in_seated_view(on_glass)
	occluder.queue_free()
	_crack = _amount()
	var area: Rect2 = Presentation.CRACK_AREA
	var struck := clampf(_head_on_glass.x, area.position.x, area.end.x)
	_check(_crack >= 0.3 and absf(crack.x - struck) < 0.01 and crack.y < -0.3 and in_view,
		"The windshield cracks low where his head struck it, in view from the seat "
		+ "(%.0f%% of full size, at x %.2f m; his head was at x %.2f m)"
		% [_crack * 100.0, crack.x, _head_on_glass.x])
	var parts: int = (sample["points"] as Array).size()
	var forward := maxf(-(sample["lean"] as Vector3).z, 0.0)
	var aim := rad_to_deg((sample["forward"] as Vector3).angle_to(
		(sample["hips"] as Vector3) - (sample["eye"] as Vector3)))
	_check(forward > 0.4 and aim < 20.0 and leaning > seated and near_seen == 0,
		"Leaning %.0f cm over the wheel, Ethan looks at him: %d of %d parts show, " % [
		forward * 100.0, leaning, parts] + "%d from the seat; the hood hides the road nearer " % (
		seated) + "than %.1f m past the bumper (his hips lie %.1f m out)" % [leaning_reach,
		-hips.z - BUMPER])
	_check(leaning_reach < 3.0 and seated_reach > leaning_reach + 1.0,
		"Leaning shows the road from %.1f m past the bumper, where a harder hit leaves him "
		% leaning_reach + "(%.1f m from the seat)" % seated_reach)


func _first_in_view(space: PhysicsDirectSpaceState3D, eye: Vector3, van: Transform3D,
		hips: Vector3) -> float:
	for step in range(5, 100):
		var past := step * 0.1
		if _clear_sight(space, eye, van * Vector3(hips.x, hips.y, -BUMPER - past)):
			return past
	return INF


func _cab_occluder(cab: Transform3D) -> StaticBody3D:
	var faces := PackedVector3Array()
	var to_cab := _presentation.global_transform.affine_inverse()
	for node in _presentation.find_children("*", "MeshInstance3D", true, false):
		var part := node as MeshInstance3D
		if not _see_through(part):
			faces.append_array(to_cab * part.global_transform * part.mesh.get_faces())
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	shape.backface_collision = true
	var collision := CollisionShape3D.new()
	collision.shape = shape
	var occluder := StaticBody3D.new()
	occluder.collision_layer = SIGHT_LAYER
	occluder.collision_mask = 0
	occluder.transform = cab
	occluder.add_child(collision)
	return occluder


func _see_through(part: MeshInstance3D) -> bool:
	var camera: Camera3D = _presentation.get("driving_camera")
	if part.mesh == null or not part.is_visible_in_tree() or (part.layers & camera.cull_mask) == 0 \
			or part == _presentation.get("_windshield") \
			or part.material_override is ShaderMaterial:
		return true
	for wiper: Node3D in _presentation.get("_wipers"):
		if wiper.is_ancestor_of(part):
			return true
	for surface in range(part.mesh.get_surface_count()):
		var material := part.get_active_material(surface) as BaseMaterial3D
		if material and material.transparency in SEE_THROUGH:
			return true
	return false


func _in_seated_view(point: Vector3) -> bool:
	var camera: Camera3D = _presentation.get("driving_camera")
	var aspect := float(ProjectSettings.get_setting("display/window/size/viewport_width")) \
		/ float(ProjectSettings.get_setting("display/window/size/viewport_height"))
	var half_width := atan(tan(deg_to_rad(camera.fov * 0.5)) * aspect)
	var look := Basis(Vector3.RIGHT, camera.rotation.x).inverse() * (point - Presentation.EYE)
	return absf(atan2(look.x, -look.z)) < half_width - deg_to_rad(3.0) \
		and absf(atan2(look.y, -look.z)) < deg_to_rad(camera.fov * 0.5 - 3.0)


func _pane() -> MeshInstance3D:
	return _presentation.get("_windshield")


func _glass(parameter: String) -> Variant:
	return (_presentation.get("_glass") as ShaderMaterial).get_shader_parameter(parameter)


func _amount() -> float:
	var amount: Variant = _glass("crack_amount")
	return 0.0 if amount == null else float(amount)


func _clear_sight(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> bool:
	return space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, SIGHT_LAYER)).is_empty()


func _check_checkpoint(pedestrian: Node3D) -> void:
	var saved := ConfigFile.new()
	var loaded := saved.load(_scratch)
	var pose: Variant = saved.get_value("drive", "recovery", null)
	var body: Variant = saved.get_value("drive", "body", [])
	var crack: Dictionary = saved.get_value("drive", "crack", {})
	var lying: Array = pedestrian.call("lying_pose")
	var apart := INF
	if body is Array and (body as Array).size() == lying.size():
		apart = 0.0
		for index in range(lying.size()):
			apart = maxf(apart, ((body as Array)[index] as Transform3D).origin.distance_to(
				(lying[index] as Transform3D).origin))
	_check(loaded == OK and pose is Transform3D and (pose as Transform3D).origin.distance_to(
		_van.global_position) < 5.0 and apart < 0.05
		and is_equal_approx(float(crack.get("amount", 0.0)), _crack),
		"When he can drive on, a checkpoint keeps the van's place, where the man lies and the "
		+ "crack (body within %.2f m)" % apart)
	_after_hit = FileAccess.get_file_as_bytes(_scratch)


func _check_continue() -> void:
	var quit_after_hit := FileAccess.open(_scratch, FileAccess.WRITE)
	quit_after_hit.store_buffer(_after_hit)
	quit_after_hit.close()
	var saved := ConfigFile.new()
	saved.load(_scratch)
	if not saved.has_section_key("drive", "recovery") \
			or not saved.has_section_key("drive", "body"):
		_check(false, "Continuing the drive after the hit starts in the van at that checkpoint")
		return
	var pose: Transform3D = saved.get_value("drive", "recovery")
	var body: Array = saved.get_value("drive", "body")
	_app.queue_free()
	await process_frame
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	_van = _app.get_node("FreightVan")
	_route = _app.get_node("DrivingTrial")
	_hud = _app.get_node("DrivingHud")
	_presentation = _van.get_node("VanPresentation")
	await process_frame
	_hud.resume_requested.emit()
	await _seconds(1.0)
	var driver: CharacterBody3D = _app.get("driver")
	var music := (_app.get("_audio").get("_music") as AudioStreamPlayer).playing
	var off := Vector2(_van.global_position.x - pose.origin.x,
		_van.global_position.z - pose.origin.z).length()
	_check(bool(_van.get("occupied")) and not driver.visible and _objective() == "DRIVE."
		and not music and off < 0.05,
		"Continuing the drive after the hit starts in the van at that checkpoint, held on the "
		+ "brake (%.2f m from it after 1 s): DRIVE., and no music" % off)
	var pedestrian: Node3D = _route.get("pedestrian")
	var apart := INF
	if is_instance_valid(pedestrian):
		var lying: Array = pedestrian.call("lying_pose")
		apart = 0.0
		for index in range(lying.size()):
			apart = maxf(apart, (body[index] as Transform3D).origin.distance_to(
				(lying[index] as Transform3D).origin))
	_check(apart < 0.05 and is_equal_approx(_amount(), _crack)
		and not is_instance_valid(_route.get("oncoming")),
		"He still lies where he fell (within %.2f m), the crack is on the glass, " % apart
		+ "and nothing replays")


func _check_depot() -> void:
	_route.set("stage", 4)
	_van.call("recover", Transform3D(Basis(Vector3.UP, PI), DEPOT))
	_hold("brake", true)
	await _until(func() -> bool: return bool(_route.get("complete")), 3.0)
	_hold("brake", false)
	await _seconds(2.0)
	_check(bool(_route.get("complete")) and not bool(_van.get("engine_on"))
		and not bool(_van.get("headlights_on")) and int(_van.get("wiper_setting")) == 0,
		"Parked at the depot, the engine goes off, the lights go out and the wipers stop")
	_hold("accelerate", true)
	await _seconds(1.0)
	_hold("accelerate", false)
	var driver: CharacterBody3D = _app.get("driver")
	_check(bool(_van.get("occupied")) and not driver.visible
		and absf(float(_van.get("speed"))) < 0.05,
		"Ethan stays in his seat, and the van no longer drives")
	var audio: Node = _app.get("_audio")
	_check(bool(audio.call("breathing"))
		and not (audio.get("_music") as AudioStreamPlayer).playing,
		"In the silence there is only the rain on the roof and his breathing")
	_check(not (_hud.get("_heading") as Control).visible and _objective() == "",
		"No objective and no \"DRIVE COMPLETE\" on screen")
	var waited := 3.0
	while not paused and waited < 25.0:
		await physics_frame
		waited += 1.0 / 60.0
	_check(paused and bool(_hud.get("menu_visible"))
		and (_hud.get("_fade") as ColorRect).modulate.a > 0.99
		and (_hud.get("_resume") as Button).text == "Drive again",
		"After %.0f s the screen fades to black and the menu offers to drive again" % waited)


func _bend(bones: Dictionary, upper: String, lower: String, axis: Vector3) -> float:
	var a := (bones[upper] as Node3D).global_basis
	var u := a.y.normalized()
	var v := (bones[lower] as Node3D).global_basis.y.normalized()
	var hinge := (a * axis.normalized()).normalized()
	return rad_to_deg(atan2(u.cross(v).dot(hinge), u.dot(v)))


func _clearance(point: Vector3) -> float:
	var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 2.0,
		point + Vector3.DOWN * 3.0, 1, [_van.get_rid()])
	var hit := _van.get_world_3d().direct_space_state.intersect_ray(query)
	return point.y - (hit.position as Vector3).y if not hit.is_empty() else INF


func _lane() -> float:
	var here := int(_route.call("_nearest_index", _van.global_position))
	var points: PackedVector3Array = _road.points
	var lane := Basis(Vector3.UP, _road.call("heading_at", here))
	return (_van.global_position - points[here]).dot(lane.x)


func _place(index: int, right: float) -> void:
	var points: PackedVector3Array = _road.points
	var basis := Basis(Vector3.UP, _road.call("heading_at", index))
	_van.call("recover", Transform3D(basis, points[index] + basis.x * right + Vector3.UP * 0.1))


func _objective() -> String:
	return (_hud.get("_objective") as Label).text


func _until(condition: Callable, limit: float) -> void:
	var waited := 0.0
	while not condition.call() and waited < limit:
		await physics_frame
		waited += 1.0 / 60.0


func _hold(action: String, pressed: bool) -> void:
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _tap(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	await physics_frame


func _seconds(duration: float) -> void:
	for frame in range(int(duration * 60.0)):
		await physics_frame


func _finish() -> void:
	print("COLLISION RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	_app.queue_free()
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "Collision test finished within 150 s of game time")
	quit(1)
