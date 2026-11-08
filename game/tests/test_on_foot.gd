extends SceneTree

const Driver = preload("res://features/characters/driver/driver.gd")
const DOOR_SWING := 0.541
const NEAR_DOOR := Vector3(-3.4, 0.0, 0.6)
const WALK_FACING := Vector3(1.0, 0.0, -0.37)
const RUN_SHEET := "BLACKRIDGE FREIGHT DEPOT\nRUN SHEET - NIGHT\n\n" \
	+ "Driver ......... E. COLE\nVan ............ BR 048\n" \
	+ "Pick-up ........ Lumber yard, Hill Road\nLoad ........... 14 pallets, sawn timber\n" \
	+ "Deliver to ..... Freight depot, bay 2\nRoute .......... Over the pass\n" \
	+ "                 (valley road closed)\n\nSigned ........."
const OFFICE_TEXTURES := {
	"siding": ["weathered_plank_siding", 1.57], "roof": ["corrugated_iron", 1.12],
	"door": ["rough_pine_door", 2.0], "deck": ["stair_planks", 1.2],
	"concrete": ["brushed_concrete_03", 2.0],
}
const OFFICE_FRONT := 1.8
const ROUND_THE_FRONT: Array[Vector3] = [Vector3(1.9, 0.0, -3.3), Vector3(-1.9, 0.0, -3.3),
	Vector3(-2.02, 0.0, -0.51)]

var _checks: int = 0
var _failures: int = 0
var _app: Node3D
var _van: CharacterBody3D
var _presentation: Node3D
var _driver: CharacterBody3D
var _hud: CanvasLayer
var _office := Vector3.ZERO
var _scratch: String


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(100.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-on-foot-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	_van = _app.get_node("FreightVan")
	_presentation = _van.get_node("VanPresentation")
	_driver = _app.get("driver")
	_hud = _app.get_node("DrivingHud")
	await process_frame
	_hud.resume_requested.emit()
	await _seconds(0.5)
	_check_start()
	_check_office()
	await _check_unsigned_van()
	await _check_run_sheet()
	await _check_walk_to_van()
	await _go_to_van()
	await _check_walking()
	await _check_boarding()
	await _check_ignition()
	await _check_cabin_light()
	await _check_driving()
	await _check_reentry()
	await _check_new_drive()
	_finish()


func _check_start() -> void:
	_check(not _van.occupied and not _van.engine_on and not _van.headlights_on
		and _van.wiper_setting == 0,
		"The drive begins on foot: the van is empty, its engine off, lights off, wipers parked")
	_office = _app.get_node("IndustrialLoop").get("run_sheet_spot")
	var gap := _flat(_driver.global_position - _office).length()
	_check(gap < 0.3, "Ethan starts at the site office door, by the clipboard (%.2f m from it)" % gap)
	_check(root.get_viewport().get_camera_3d() == _driver.call("get_camera"),
		"The player sees Ethan through his own camera")
	var player := _ethan_player()
	_check(player != null and player.current_animation == "Idle",
		"Ethan is the Mixamo character, standing in his Idle clip")
	_check(_objective().begins_with("SIGN THE RUN SHEET"), "The objective says to sign the run sheet")
	_check(_hint().begins_with("E  Sign the run sheet"), "At the clipboard the hint says E signs it")
	var screens: Array = _presentation.get("_powered_screens")
	var dark := screens.size() == 2
	for screen: MeshInstance3D in screens:
		dark = dark and not screen.visible
	_check(dark, "The cluster and map screens are off with the engine")
	_check(not _guide().shown(),
		"Before signing, no guide to the van shows: the run sheet comes first")


func _check_office() -> void:
	var world := _app.get_node("IndustrialLoop")
	var office := world.get_node("SiteOffice") as Node3D
	var shell := office.get_node("SiteOffice") as MeshInstance3D
	var dressed := shell.mesh.get_surface_count() == 15
	var textured := 0
	for surface in range(shell.mesh.get_surface_count()):
		var material := shell.get_surface_override_material(surface)
		dressed = dressed and material != null
		var part := shell.mesh.surface_get_material(surface).resource_name
		if material is ORMMaterial3D and OFFICE_TEXTURES.has(part):
			var source: Array = OFFICE_TEXTURES[part]
			var orm := material as ORMMaterial3D
			if orm.albedo_texture.resource_path.contains(source[0]) \
					and is_equal_approx(orm.uv1_scale.x, 1.0 / float(source[1])):
				textured += 1
	_check(dressed and textured == OFFICE_TEXTURES.size(),
		"The site office is the timber building from Blender, its siding, roof, door, landing "
		+ "and plinth in Poly Haven textures at real size (%d of 5)" % textured)
	var front := office.to_global(Vector3(0.0, 0.0, OFFICE_FRONT)).z
	var sheet: Vector3 = world.get("run_sheet_at")
	var height := sheet.y - office.global_position.y
	_check(sheet.z > front and sheet.z - front < 0.05 and height > 1.2 and height < 1.7,
		"The clipboard hangs on the office's front wall, %.2f m up, %.1f cm proud of it"
		% [height, (sheet.z - front) * 100.0])
	var lamp := office.get_node("NoticeLight") as SpotLight3D
	_check(lamp.shadow_enabled and _lit(lamp, sheet) and _lit(lamp, _office + Vector3.UP * 1.6),
		"The gooseneck lamp over the OFFICE board lights the clipboard and Ethan standing at it")
	var flood := office.get_node("FloodLight") as SpotLight3D
	var van := _van.global_position + Vector3.UP * 0.6
	var space := office.get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(flood.global_position, van))
	_check(flood.shadow_enabled and _lit(flood, van) and hit.get("collider") == _van,
		"A floodlight on the office's corner shines on the parked van, %.1f m away, with "
		% flood.global_position.distance_to(van) + "nothing in between")
	var capsule: CollisionShape3D = _driver.get("_collision")
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule.shape
	query.transform = capsule.global_transform.translated(Vector3.UP * 0.15)
	query.motion = Vector3(0.0, 0.0, front - capsule.global_position.z - 1.0)
	query.collision_mask = _driver.collision_mask
	query.exclude = [_driver.get_rid()]
	var stop := capsule.global_position.z + query.motion.z * space.cast_motion(query)[0]
	_check(stop > front + 0.2, "Walking at the wall, Ethan stops %.2f m short of it" % (
		stop - front))


func _lit(light: SpotLight3D, point: Vector3) -> bool:
	var reach := point - light.global_position
	return reach.length() < light.spot_range \
		and rad_to_deg((-light.global_basis.z).angle_to(reach)) < light.spot_angle


func _check_unsigned_van() -> void:
	_driver.global_position = _van.to_global(NEAR_DOOR)
	await _seconds(0.3)
	await _tap("interact")
	await _seconds(0.2)
	_check(not bool(_app.get("_boarding")) and not _van.occupied
		and _notice().begins_with("Sign the run sheet"),
		"Before signing, E at the van only reminds him to sign the run sheet first")
	_driver.global_position = _office
	await _seconds(0.3)


func _check_run_sheet() -> void:
	await _tap("interact")
	await _seconds(0.3)
	_check(_sheet() == RUN_SHEET, "E at the clipboard shows the run sheet as approved, unsigned")
	await _seconds(1.2)
	_check(_sheet() == RUN_SHEET + " E. Cole" and _objective().begins_with("GET IN THE VAN"),
		"A moment later he signs it \"E. Cole\", and the objective becomes getting in the van")
	await _tap("interact")
	await _seconds(0.3)
	_check(not bool(_hud.call("document_visible")) and _hint().begins_with("WASD  Walk"),
		"E puts the sheet away, and the hint teaches walking (%s)" % _hint())
	var guide := _guide()
	_check(guide.shown() and guide.label().begins_with("VAN") and guide.distance() > 8.0
		and guide.distance() < 20.0,
		"After signing, a corner map and a marker over the van guide him to it (%s)"
		% guide.label())


func _check_walk_to_van() -> void:
	var widest_step := 0.0
	var time := 0.0
	var last := _driver.global_position
	for waypoint in ROUND_THE_FRONT:
		var target := _van.to_global(waypoint)
		var still := 0.0
		Input.action_press("accelerate")
		while _flat(target - _driver.global_position).length() > 0.3 and still < 1.0 \
				and time < 30.0:
			_driver.call("look_toward", _flat(target - _driver.global_position).normalized())
			await physics_frame
			time += 1.0 / 60.0
			var moved := _flat(_driver.global_position - last).length()
			widest_step = maxf(widest_step, moved)
			still = still + 1.0 / 60.0 if moved < 0.004 else 0.0
			last = _driver.global_position
		Input.action_release("accelerate")
	var gap := _flat(_van.to_global(ROUND_THE_FRONT[-1]) - _driver.global_position).length()
	_check(gap < 0.5 and widest_step < 0.1,
		"From the office door, W and the mouse take Ethan round the van's front to the driver's "
		+ "door (%.2f m from it after %.1f s)" % [gap, time])
	await _check_kerb()
	var side := _van.to_global(Vector3(-1.6, 0.0, 1.2))
	_driver.global_position = side
	_driver.velocity = Vector3.ZERO
	for frame in range(15):
		await physics_frame
	var feet := _driver.global_position.y
	Input.action_press("accelerate")
	for frame in range(60):
		_driver.call("look_toward", _flat(_van.global_position - _driver.global_position)
			.normalized())
		await physics_frame
	Input.action_release("accelerate")
	var inside := _van.to_local(_driver.global_position)
	_check(absf(_driver.global_position.y - feet) < 0.05 and absf(inside.x) > 1.2,
		"Walking into the van's side, he stops against it and cannot climb it (%.2f m from its "
		% (absf(inside.x) - 1.0) + "side, feet %.2f m up)" % (_driver.global_position.y - feet))


func _check_kerb() -> void:
	var base := _ground_point(Vector3(585.0, 0.0, 100.0))
	var kerb := _block(base + Vector3(0.0, 0.1, -2.0), Vector3(1.6, 0.2, 2.0))
	var ledge := _block(base + Vector3(4.0, 0.25, -1.5), Vector3(1.6, 0.5, 0.4))
	var over := await _walk_into(base)
	var stopped := await _walk_into(base + Vector3(4.0, 0.0, 0.0))
	kerb.queue_free()
	ledge.queue_free()
	_check(over.x > 0.18 and over.y > 2.0 and stopped.x < 0.05 and stopped.y < 1.2,
		"Ethan steps up a 20 cm kerb onto the pavement behind it (%.2f m) and walks on, but a 50 "
		% over.x + "cm ledge stops him (%.2f m on)" % stopped.y)


func _walk_into(start: Vector3) -> Vector2:
	_driver.global_position = start
	_driver.velocity = Vector3.ZERO
	_driver.call("face", Vector3.FORWARD)
	_driver.call("look_toward", Vector3.FORWARD)
	for frame in range(10):
		await physics_frame
	var feet := _driver.global_position.y
	var rise := 0.0
	Input.action_press("accelerate")
	for frame in range(120):
		await physics_frame
		rise = maxf(rise, _driver.global_position.y - feet)
	Input.action_release("accelerate")
	return Vector2(rise, start.z - _driver.global_position.z)


func _block(at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	root.add_child(body)
	body.global_position = at
	return body


func _ground_point(at: Vector3) -> Vector3:
	var query := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 20.0,
		at + Vector3.DOWN * 20.0, 1)
	var hit := _van.get_world_3d().direct_space_state.intersect_ray(query)
	return (hit["position"] as Vector3) + Vector3.UP * 0.02 if not hit.is_empty() else at


func _go_to_van() -> void:
	_driver.global_position = _van.to_global(NEAR_DOOR)
	var along := _van.global_basis * WALK_FACING
	_driver.call("face", along)
	_driver.call("look_toward", along)
	await _seconds(0.4)
	_check(_hint().begins_with("E  Get in the van"), "Near the van the hint says E gets him in")


func _check_walking() -> void:
	var start := _driver.global_position
	Input.action_press("accelerate")
	await _seconds(0.5)
	var walk_pace := _flat(_driver.velocity).length()
	var walked := _flat(_driver.global_position - start).length()
	var walk_clip := _ethan_player().current_animation
	Input.action_press("sprint")
	await _seconds(0.1)
	var run_pace := _flat(_driver.velocity).length()
	var run_clip := _ethan_player().current_animation
	Input.action_release("sprint")
	Input.action_release("accelerate")
	await _seconds(0.4)
	_check(walk_clip == "Walk" and absf(walk_pace - Driver.WALK_SPEED) < 0.05,
		"W walks Ethan at the Walk clip's own pace (%s, %.2f m/s)" % [walk_clip, walk_pace])
	_check(walked > 0.6 and walked < 1.0, "He covers %.2f m in half a second" % walked)
	_check(run_clip == "Run" and absf(run_pace - Driver.RUN_SPEED) < 0.05,
		"SHIFT runs at the Run clip's pace (%s, %.2f m/s)" % [run_clip, run_pace])
	_check(_ethan_player().current_animation == "Idle", "Letting go returns him to Idle")


func _check_boarding() -> void:
	await _tap("interact")
	_check(bool(_app.get("_boarding")) and _hint() == "",
		"E near the van starts boarding and clears the hint")
	var saw_clip := false
	var widest := 0.0
	var glass_follows := true
	var door: Node3D = _presentation.get("_door")
	var glass: Node3D = _presentation.get("_door_glass")
	var waited := 0.0
	var off_handle := 0.0
	var lamp_lit := 0.0
	var guide_hidden := true
	while not _van.occupied and waited < 8.0:
		await physics_frame
		waited += 1.0 / 60.0
		saw_clip = saw_clip or _ethan_player().current_animation == "EnterVan"
		widest = minf(widest, door.rotation.y)
		glass_follows = glass_follows and is_equal_approx(glass.rotation.y, door.rotation.y)
		var time: float = _driver.call("clip_time")
		if saw_clip and time > 1.1 and time < 1.7:
			off_handle = maxf(off_handle, (_driver.call("grip_point") as Vector3).distance_to(
				_van.call("door_handle")))
		if float(_van.driver_door) > 0.5:
			lamp_lit = maxf(lamp_lit, _lamp().light_energy)
		guide_hidden = guide_hidden and not _guide().shown()
	_check(saw_clip, "Ethan walks to the door and plays Entering Car")
	_check(widest < -0.9 * DOOR_SWING,
		"The driver's door swings outward about 31 degrees as he pulls it (%.1f)" % rad_to_deg(
			widest))
	_check(glass_follows, "The door glass swings with the door")
	_check(saw_clip and off_handle < 0.12,
		"His left hand holds the door handle while the door swings open (at most %.1f cm off)"
		% (off_handle * 100.0))
	_check(lamp_lit > 0.5, "With the door open, the cabin lamp lights the cab (energy %.2f)"
		% lamp_lit)
	_check(guide_hidden, "The guide to the van hides while he gets in")
	await process_frame
	_check(_van.occupied and not _driver.visible
		and root.get_viewport().get_camera_3d() == _van.call("get_camera"),
		"After the cut the player sits in the driver's seat (%.1f s)" % waited)
	_check(is_zero_approx(float(_van.driver_door)) and is_zero_approx(door.rotation.y),
		"The door is shut behind him")
	_check(not _objective().begins_with("GET IN THE VAN"),
		"The route's objective returns (%s)" % _objective())


func _check_ignition() -> void:
	var swept := 0.0
	var waited := 0.0
	while not _van.headlights_on and waited < 4.0:
		await physics_frame
		waited += 1.0 / 60.0
		swept = maxf(swept, float(_van.call("ignition_sweep")))
	_check(_van.engine_on and swept > 0.95,
		"The engine starts and the gauge needles sweep to the top (%.2f)" % swept)
	_check(_van.headlights_on and not _van.high_beams and _van.wiper_setting == 1,
		"After the sweep the low beams and the wipers come on (%.1f s after the cut)" % waited)
	await physics_frame
	var screens: Array = _presentation.get("_powered_screens")
	var lit := true
	for screen: MeshInstance3D in screens:
		lit = lit and screen.visible
	_check(lit, "The dash screens come on with the engine")


func _check_driving() -> void:
	await _seconds(0.3)
	_check(_hint().begins_with("W / S  Accelerate / brake"),
		"In the seat, the hint teaches the pedals and the wheel (%s)" % _hint())
	Input.action_press("accelerate")
	await _seconds(1.5)
	Input.action_release("accelerate")
	_check(_van.speed > 3.0, "The van drives after Ethan gets in (%.1f m/s)" % _van.speed)
	Input.action_press("brake")
	await _seconds(1.5)
	Input.action_release("brake")


func _check_cabin_light() -> void:
	await _seconds(1.0)
	var faded := _lamp().light_energy
	var guide_hidden: bool = not _guide().shown()
	await _tap("cabin_light")
	await _seconds(0.3)
	var lit := _lamp().light_energy
	var switched := bool(_van.get("cabin_light"))
	await _tap("cabin_light")
	await _seconds(2.5)
	_check(is_zero_approx(faded) and guide_hidden,
		"In the van the guide hides, and with the door shut the cabin lamp has faded out")
	_check(switched and lit > 0.5 and is_zero_approx(_lamp().light_energy)
		and not bool(_van.get("cabin_light")),
		"I switches the cabin lamp on (energy %.2f) and off again, from the seat" % lit)


func _check_reentry() -> void:
	await _tap("interact")
	var door: Node3D = _presentation.get("_door")
	var saw_exit := false
	var widest := 0.0
	var lamp_lit := 0.0
	var off_door := 0.0
	var before := 0.0
	var leaving := 0.0
	while bool(_app.get("_boarding")) and leaving < 10.0:
		await physics_frame
		leaving += 1.0 / 60.0
		saw_exit = saw_exit or (_driver.visible and _ethan_player().current_animation == "ExitVan")
		var opening := float(_van.driver_door)
		widest = maxf(widest, opening)
		if opening > 0.5:
			lamp_lit = maxf(lamp_lit, _lamp().light_energy)
		if opening > 0.3 and opening < 1.9 and opening < before - 0.001:
			var touch := door.global_transform.affine_inverse() * (_driver.call("grip_point")
				as Vector3)
			off_door = maxf(off_door, absf(touch.x))
		before = opening
	_check(saw_exit and not _van.occupied and _driver.visible
		and is_zero_approx(float(_van.driver_door)),
		"E at a stop plays Exiting Car: the door opens, he steps out, and the door is shut "
		+ "behind him (%.1f s)" % leaving)
	_check(widest > 2.0, "The door opens wide for him to step out (%.0f degrees)"
		% rad_to_deg(widest * DOOR_SWING))
	_check(off_door > 0.0 and off_door < 0.06,
		"He pushes the door shut with his hand on it (at most %.1f cm off the door)"
		% (off_door * 100.0))
	_check(lamp_lit > 0.5, "The cabin lamp is on while the door is open (energy %.2f)" % lamp_lit)
	await _tap("interact")
	var waited := 0.0
	var restarted := false
	while not _van.occupied and waited < 8.0:
		await physics_frame
		waited += 1.0 / 60.0
		restarted = restarted or not _van.engine_on
	await _seconds(0.5)
	_check(_van.occupied and not restarted and is_zero_approx(float(_van.call("ignition_sweep"))),
		"Getting back into the running van needs no second ignition (%.1f s)" % waited)


func _check_new_drive() -> void:
	_hud.restart_requested.emit()
	await _seconds(0.3)
	_check(not _van.occupied and not _van.engine_on and _driver.visible
		and _objective().begins_with("SIGN THE RUN SHEET")
		and _flat(_driver.global_position - _office).length() < 0.3,
		"New drive starts at the site office again, with the run sheet to sign")


func _guide() -> Control:
	return _hud.get("van_guide")


func _lamp() -> OmniLight3D:
	return _presentation.get("cabin_lamp")


func _ethan_player() -> AnimationPlayer:
	var ethan := _driver.get_node_or_null("Ethan")
	if ethan == null:
		return null
	return ethan.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer


func _objective() -> String:
	return (_hud.get("_objective") as Label).text


func _hint() -> String:
	return (_hud.get("_hint") as Label).text


func _notice() -> String:
	return (_hud.get("_notice") as Label).text


func _sheet() -> String:
	return _hud.call("document_text")


func _flat(value: Vector3) -> Vector3:
	return Vector3(value.x, 0.0, value.z)


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
	var frames := int(duration * 60.0)
	for frame in range(frames):
		await physics_frame


func _finish() -> void:
	print("ON FOOT RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	_app.queue_free()
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "On-foot test finished within 100 s of game time")
	quit(1)
