extends SceneTree
## Part G of step 5 of #253 (docs/PHASE_BRIEF.md, "the shed at work"; the author's choices,
## #302-#303): the transfer shed's forklift at work, read from the shed as the running game
## builds it on Mission 2's start save. Parked while no one is near; once the camera comes within
## reach, its driver takes a pallet of its own from dock 6's staging lane to an empty floor place
## in aisle 03 and comes back, as OSHA 1910.178(n) has it: the load carried low, never over 5 mph
## (2.2 m/s) and slower in the aisle, its blue spot ahead of it in its direction of travel, its
## alarm only while it backs, its horn at the aisle's mouth, stopping short of Ethan and going on
## when he has left its way. Its driver sits at the wheel, his hands on it, his feet on the plate,
## his head turned the way he backs. A headless run draws nothing, so the look is not checked.

const START_SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const FLOOR := 1.3
const NEAR := Vector3(-55.0, 4.0, 13.0)
const TRIP_LIMIT := 400.0
const STAGE := Vector2(-60.0, 16.3)
const SLOT := Vector2(-63.79, 7.56)
const SLOT_WITHIN := 0.05
const HOME_WITHIN := 0.05
const TOP_SPEED := 2.2
const AISLE_SPEED := 1.0
const SPEED_SLACK := 0.03
const AISLE := Rect2(-68.21, -9.4, 3.81, 17.64)
const TRAVEL_LIFT := Vector2(0.10, 0.15)
const SPOT_AHEAD := Vector2(3.0, 5.0)
const MOUTH := Vector2(-66.3, 8.24)
## Where the second trip's loaded run along the cross-aisle ends, before dock 6's lane.
const RUN_END := Vector2(-60.0, 12.0)
const ETHAN_AHEAD := 3.2
const ETHAN_HOLD := 4.0
const HORN_NEAR := 4.5
const KEEP_CLEAR := 2.0
const RESUME_WITHIN := 2.0
const GRIP_WITHIN := 0.08
const LOOK_BACK := deg_to_rad(45.0)
## The scan (#302): bay 9's lift deck, the worker's place beside it and his times.
const DECK := Rect2(-48.685, 17.29, 1.87, 2.46)
const SCAN_AT := Vector2(-46.6, 17.05)
const REACH_WITHIN := 15.0
const BACK_WITHIN := 30.0
const FACING := deg_to_rad(15.0)
## The shed's sounds (#302): under its roof, and outside it in the yard.
const UNDER_ROOF := Vector3(-62.0, 3.0, 5.0)
const IN_THE_YARD := Vector3(-60.0, 3.0, 40.0)
const SHELTERED_BY := 10.0
const ROOF_TOP := 9.0
const DUTY := Vector2(0.5, 0.7)
const DESK := Rect2(-45.784, 17.55, 0.947, 2.0)
const DESK_TOP := 1.3 + 0.788

var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _app: Node3D
var _shed: Node3D
var _truck: Node3D
var _camera: Camera3D
var _horns: Array[Vector3] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(600.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-shed-work-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_store(START_SAVE)
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	await process_frame
	_app.call("_resume")
	await physics_frame
	_shed = _app.get_node("IndustrialLoop").get("transfer_shed") as Node3D
	_truck = _shed.get_node_or_null("Building/Forklift") as Node3D if _shed != null else null
	_check(_truck != null and _truck.has_method("phase"),
		"W0: the shed's forklift is a working truck (Building/Forklift)")
	if _truck == null or not _truck.has_method("phase"):
		_finish()
		return
	_truck.connect("horned", func(at: Vector3) -> void: _horns.append(at))
	var home: Transform3D = _truck.global_transform
	await _seconds(5.0)
	var moved := _truck.global_transform.origin.distance_to(home.origin)
	var turned := _truck.global_basis.z.angle_to(home.basis.z)
	_check(moved < 0.001 and turned < 0.001, "W1: parked while no one is near (moved %.3f m, "
		% moved + "turned %.3f rad)" % turned)
	_check(not String(_truck.call("load_node").name).begins_with("Pallet"),
		"W1: its load is its own, not one of the mission's Pallet<n>")
	_camera = Camera3D.new()
	root.add_child(_camera)
	_camera.global_position = NEAR
	_camera.make_current()
	await _check_trip(home)
	await _check_driver()
	await _check_scan()
	await _check_sounds()
	_finish()


func _check_trip(home: Transform3D) -> void:
	var time := 0.0
	var started := false
	var fastest := 0.0
	var fastest_aisle := 0.0
	var lift_bad := 0
	var spot_bad := 0
	var alarm_bad := 0
	var moving_frames := 0
	var looked_back := true
	var reversed_frames := 0
	var since_reverse := 0
	var ethan := _app.get("driver") as Node3D
	var ethan_state := 0
	var ethan_at := Vector3.ZERO
	var ethan_time := 0.0
	var least_gap := INF
	var gave_way := false
	var resumed := INF
	var travel_then := Vector3.ZERO
	var first_at := Vector3.INF
	var first_back := false
	var first_time := 0.0
	while time < TRIP_LIMIT:
		await physics_frame
		time += 1.0 / 60.0
		var phase := String(_truck.call("phase"))
		if phase != "parked":
			started = true
		var speed := absf(float(_truck.call("speed")))
		var at := _truck.global_position
		fastest = maxf(fastest, speed)
		if AISLE.has_point(Vector2(at.x, at.z)):
			fastest_aisle = maxf(fastest_aisle, speed)
		var reversing := bool(_truck.call("reversing"))
		if speed > 0.2:
			moving_frames += 1
			if bool(_truck.call("carrying")):
				var lift := float(_truck.call("lift"))
				if lift < TRAVEL_LIFT.x or lift > TRAVEL_LIFT.y:
					lift_bad += 1
			var travel := _truck.global_basis.z * (-1.0 if reversing else 1.0)
			var spot: Vector3 = _truck.call("spot_point")
			var reach := Vector2(spot.x - at.x, spot.z - at.z)
			var ahead := reach.dot(Vector2(travel.x, travel.z).normalized())
			if absf(spot.y - FLOOR) > 0.05 or ahead < SPOT_AHEAD.x or ahead > SPOT_AHEAD.y \
					or reach.length() > ahead + 0.5:
				spot_bad += 1
			if bool(_truck.call("alarm_playing")) != reversing:
				alarm_bad += 1
			if reversing:
				reversed_frames += 1
				since_reverse += 1
				if since_reverse > 40:
					looked_back = looked_back and float(_truck.call("head_turned")) >= LOOK_BACK
			else:
				since_reverse = 0
		var run_left := Vector2(at.x, at.z).distance_to(RUN_END)
		if ethan != null and ethan_state == 0 and phase == "to_lane" and speed > 1.0 \
				and run_left > 4.5 and bool(_truck.call("carrying")):
			travel_then = _truck.global_basis.z
			ethan_at = at + travel_then * (float(_truck.call("reach_ahead")) + ETHAN_AHEAD)
			ethan_state = 1
		if ethan_state == 1:
			ethan.global_position = ethan_at + Vector3.UP * 0.05
			ethan.set("velocity", Vector3.ZERO)
			ethan_time += 1.0 / 60.0
			var gap := Vector2(ethan_at.x - at.x, ethan_at.z - at.z).dot(Vector2(travel_then.x,
				travel_then.z).normalized()) - float(_truck.call("reach_ahead"))
			least_gap = minf(least_gap, gap)
			gave_way = gave_way or (speed < 0.01 and phase == "to_lane" and run_left > 0.5)
			if ethan_time >= ETHAN_HOLD:
				ethan.global_position = Vector3(-46.0, FLOOR + 0.05, 18.0)
				ethan_state = 2
				ethan_time = 0.0
		elif ethan_state == 2:
			ethan_time += 1.0 / 60.0
			if speed > 0.05 and phase == "to_lane":
				resumed = ethan_time
				ethan_state = 3
		if phase == "parked" and int(_truck.get("trips")) == 1 and first_at == Vector3.INF:
			var put := _truck.call("load_node") as Node3D
			first_at = put.global_position
			first_back = _truck.global_position.distance_to(home.origin) <= HOME_WITHIN \
				and _truck.global_basis.z.angle_to(home.basis.z) < deg_to_rad(2.0)
			first_time = time
		if started and phase == "parked" and int(_truck.get("trips")) >= 2:
			break
	var load := _truck.call("load_node") as Node3D
	var placed := first_at != Vector3.INF and Vector2(first_at.x, first_at.z).distance_to(SLOT) \
		<= SLOT_WITHIN and absf(first_at.y - FLOOR) < 0.01
	var back := first_back
	var returned := load != null and Vector2(load.global_position.x, load.global_position.z) \
		.distance_to(STAGE) <= SLOT_WITHIN and absf(load.global_position.y - FLOOR) < 0.01 \
		and _truck.global_position.distance_to(home.origin) <= HOME_WITHIN
	_check(started and placed and back, "W2: the putaway: the load on aisle 03's floor place "
		+ "within 5 cm (%s), the truck parked again (%.1f s)"
		% [str(first_at.snapped(Vector3.ONE * 0.01)), first_time])
	_check(returned, "W2: and the pick: the load back in dock 6's lane within 5 cm, the truck "
		+ "parked again (%.1f s)" % time)
	_check(lift_bad == 0 and moving_frames > 0, "W3: the load carried 0.10-0.15 m up whenever it "
		+ "moves loaded (%d frames out)" % lift_bad)
	_check(fastest <= TOP_SPEED + SPEED_SLACK and fastest > 1.0 and fastest_aisle <= AISLE_SPEED
		+ SPEED_SLACK, "W4: never over 5 mph (fastest %.2f m/s), slower in the aisle (%.2f m/s)"
		% [fastest, fastest_aisle])
	_check(spot_bad == 0, "W5: its blue spot 3-5 m ahead in its direction of travel (%d frames "
		% spot_bad + "out of %d)" % moving_frames)
	_check(alarm_bad == 0 and reversed_frames > 0, "W6: its alarm only while it backs (%d frames "
		% alarm_bad + "wrong, %d backing)" % reversed_frames)
	var at_mouth := _horns.filter(func(point: Vector3) -> bool:
		return Vector2(point.x, point.z).distance_to(MOUTH) <= HORN_NEAR)
	_check(at_mouth.size() >= 2, "W7: its horn at aisle 03's mouth going in and coming out (%d "
		% at_mouth.size() + "of %d horns)" % _horns.size())
	_check(looked_back, "W8: the driver looks the way he backs (his head turned at least 45°)")
	_check(gave_way and least_gap >= KEEP_CLEAR, "W10: with Ethan in its way on the cross-aisle "
		+ "it stops, at least 2 m short of him (%.2f m)" % least_gap)
	_check(resumed <= RESUME_WITHIN, "W10: and goes on when he has left its way (%.1f s)"
		% resumed)


func _check_driver() -> void:
	var seated: Dictionary = _truck.call("driver_fit")
	_check(float(seated.get("hands", INF)) <= GRIP_WITHIN and float(seated.get("feet", INF))
		<= GRIP_WITHIN and bool(seated.get("on_seat", false)), "W9: the driver seated, his hands "
		+ "on the wheel (%.3f m) and his feet on the plate (%.3f m)"
		% [float(seated.get("hands", INF)), float(seated.get("feet", INF))])


func _check_scan() -> void:
	var worker := _shed.get("dock_worker") as Node3D
	var load := _shed.get_node_or_null("Building/Pallet6") as Node3D
	var lift := _shed.get_node_or_null("Building/DockLift9") as Node3D
	if worker == null or load == null or lift == null:
		_check(false, "S0: bay 9's dock worker, its load and its lift are there")
		return
	var reads: Array[Node3D] = []
	worker.connect("scanned", func(read: Node3D) -> void: reads.append(read))
	load.global_position = Vector3(lift.global_position.x, lift.global_position.y,
		lift.global_position.z)
	var time := 0.0
	var reached := INF
	var on_deck := false
	var faced := false
	var held := false
	var beeped := false
	var back := INF
	while time < BACK_WITHIN + REACH_WITHIN:
		await physics_frame
		time += 1.0 / 60.0
		var at := Vector2(worker.global_position.x, worker.global_position.z)
		on_deck = on_deck or (DECK.has_point(at) and not bool(lift.call("at_top")))
		var state := String(worker.get("state"))
		if state == "scanning":
			if reached == INF:
				reached = time
			var model := worker.get_node("Model") as Node3D
			var toward := atan2(load.global_position.x - worker.global_position.x,
				load.global_position.z - worker.global_position.z)
			faced = faced or absf(angle_difference(model.rotation.y, toward)) <= FACING
			var scanner := worker.find_child("Scanner", true, false) as Node3D
			held = held or (scanner != null and scanner.is_visible_in_tree())
			beeped = beeped or (worker.get_node("ScannerBeep") as AudioStreamPlayer3D).playing
		if reached != INF and state == "seated":
			back = time
			break
	var spot := Vector2(worker.global_position.x, worker.global_position.z)
	_check(reached <= REACH_WITHIN and not on_deck, "S1: bay 9's dock worker goes to scan the "
		+ "pallet set down on the lift, at his place beside its deck within %.0f s (%.1f s), "
		% [REACH_WITHIN, reached] + "never stepping on the deck while it is down")
	_check(faced and held and beeped and reads == [load], "S2: he faces the pallet, the scanner in "
		+ "his hand, and reads it once with its beep (%d reads)" % reads.size())
	var scanner := worker.find_child("Scanner", true, false) as Node3D
	_check(back <= BACK_WITHIN + REACH_WITHIN and scanner != null and not scanner.visible,
		"S3: then he is back at his desk, seated, the scanner put away (%.1f s)" % back)
	load.global_position += Vector3(0.0, 0.0, -2.0)
	await physics_frame
	load.global_position += Vector3(0.0, 0.0, 2.0)
	for frame in range(60):
		await physics_frame
	_check(String(worker.get("state")) == "seated" and reads.size() == 1,
		"S4: the same pallet set down again does not send him a second time")
	var other := _shed.get_node_or_null("Building/Pallet5") as Node3D
	lift.call("lower", 0.7, false)
	lift.call("hold", true)
	var down := 0.0
	while not bool(lift.call("at_bottom")) and down < 20.0:
		await physics_frame
		down += 1.0 / 60.0
	other.global_position = lift.global_position
	var waited := 0.0
	var stepped := false
	var sat_early := false
	var scanned_again := false
	while waited < 25.0:
		await physics_frame
		waited += 1.0 / 60.0
		var at := Vector2(worker.global_position.x, worker.global_position.z)
		stepped = stepped or (DECK.has_point(at) and not bool(lift.call("at_top")))
		scanned_again = scanned_again or reads.size() == 2
		if scanned_again and String(worker.get("state")) == "sitting":
			sat_early = true
	_check(scanned_again and not stepped and not sat_early, "S5: with the lift down, he scans "
		+ "from beside it and waits off its deck rather than step to his chair over the pit")
	lift.call("raise")
	var risen := 0.0
	while String(worker.get("state")) != "seated" and risen < 30.0:
		await physics_frame
		risen += 1.0 / 60.0
	_check(bool(lift.call("at_top")) and String(worker.get("state")) == "seated",
		"S5: and sits down once it is up again (%.1f s)" % risen)
	lift.call("hold", false)


func _check_sounds() -> void:
	var sounds := _shed.get_node_or_null("Building/ShedSounds")
	if sounds == null:
		_check(false, "R0: the shed has its sounds (Building/ShedSounds)")
		return
	var roofs := sounds.find_children("RoofRain*", "AudioStreamPlayer3D", false, false)
	var under := not roofs.is_empty()
	for found in roofs:
		var player := found as AudioStreamPlayer3D
		under = under and player.playing and player.bus == "Ambience" \
			and player.global_position.y < ROOF_TOP and sounds.call("shelter",
			player.global_position) == 1.0
	_check(under and roofs.size() >= 4, "R1: rain drumming on the roof from %d places under it, "
		% roofs.size() + "on the Ambience bus")
	var audio := _app.get("_audio") as Node
	var rain := audio.get("_rain") as AudioStreamPlayer
	_camera.global_position = IN_THE_YARD
	for frame in range(10):
		await process_frame
	var outside := rain.volume_db
	_camera.global_position = UNDER_ROOF
	for frame in range(10):
		await process_frame
	var inside := rain.volume_db
	_check(outside - inside >= SHELTERED_BY, "R2: under the roof the yard's rain falls away "
		+ "(%.1f dB outside, %.1f dB inside)" % [outside, inside])
	var heaters := _shed.get_node("Building/ShedFitout").call("placements", "Heaters") as Array
	var running: Array = sounds.call("heaters_running")
	var clock := float(sounds.get("_clock"))
	var matches := running.size() == heaters.size() and heaters.size() > 0
	var duty_ok := matches
	for index in range(running.size()):
		matches = matches and bool(running[index]) == bool(sounds.call("heater_running", index,
			clock))
		var on := 0
		for step in range(3600):
			if bool(sounds.call("heater_running", index, step * 2.0)):
				on += 1
		duty_ok = duty_ok and on / 3600.0 >= DUTY.x and on / 3600.0 <= DUTY.y
	var placed := true
	for index in range(heaters.size()):
		var player := sounds.get_node_or_null("Heater%d" % (index + 1)) as AudioStreamPlayer3D
		placed = placed and player != null and player.global_position.distance_to(
			(heaters[index] as Transform3D).origin) < 0.01
	_check(matches and duty_ok and placed, "R3: each heater heard where it hangs, running on its "
		+ "thermostat, %d-%d%% of the time over two hours" % [roundi(DUTY.x * 100),
		roundi(DUTY.y * 100)])
	var fans := _shed.get_node("Building/ShedFitout").call("placements", "Fans") as Array
	var whooshes := 0
	for found in sounds.find_children("Fan*", "AudioStreamPlayer3D", false, false):
		var player := found as AudioStreamPlayer3D
		for fan: Transform3D in fans:
			if player.playing and player.global_position.distance_to(fan.origin) < 0.01:
				whooshes += 1
	_check(whooshes == fans.size() and fans.size() == 2, "R4: each fan's slow swish heard where it "
		+ "turns (%d)" % whooshes)
	var radio := sounds.get_node_or_null("DeskRadio") as Node3D
	var tune := sounds.get_node_or_null("Radio") as AudioStreamPlayer3D
	var on_desk := radio != null and DESK.has_point(Vector2(radio.global_position.x,
		radio.global_position.z)) and absf(radio.global_position.y - 0.075 - DESK_TOP) < 0.01
	_check(on_desk and tune != null and tune.playing and tune.volume_db <= -12.0
		and tune.global_position.distance_to(radio.global_position) < 0.01,
		"R5: a radio on the dock desk playing low")


func _seconds(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _store(text: String) -> void:
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _remove() -> void:
	for suffix in ["", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(_scratch + suffix):
			DirAccess.remove_absolute(_scratch + suffix)


func _timeout() -> void:
	_check(false, "The shed's work finishes within 600 s")
	_finish()


func _finish() -> void:
	print("SHED WORK RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	_remove()
	quit(1 if _failures > 0 else 0)
