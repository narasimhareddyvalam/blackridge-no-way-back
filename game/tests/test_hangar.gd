extends SceneTree
## Mission 3's step 6: the guard encounter at the hangar (docs/PHASE_BRIEF.md, 2026-11-22,
## #359-#360; GAME_DESIGN §8: "one handgun, hitscan ... ammunition, reload, health and one guard
## archetype with patrol/alert/chase/attack states"; GAME_STORY's Act V: "a compact guard
## encounter"). On Last Run's stage 3 save the van is back at the airfield's service gate, open, and
## Maya waits there by her car; on foot, E talks to her and she hands him his gun (since C68 a rifle,
## 30 in the magazine and a spare 30, #403; it was Adrian's pistol, 15 and 15; in the
## magazine, one spare magazine). Right mouse aims, left mouse fires along the crosshair, R reloads.
## Adrian's three men patrol the apron: a man who sees him or hears a shot chases, and in range
## stops and shoots; two body hits put a man down, as does one to the head, and he stays down.
## Ethan's health at nothing and all begins again at the service gate. Driving the van onto the
## airfield, they hear it. At the hangar office's door, no man on him, stage 4 is saved: FIND LILY.

## The rifle's magazine and its spare (C68, #403; the pistol's were 15).
const ROUNDS := 30
const STAGE_THREE := "[save]\nversion=2\nmission=\"last_run\"\n\n[run]\nstage=3\n"

var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _app: Node3D
var _van: CharacterBody3D
var _driver: CharacterBody3D
var _hud: CanvasLayer
var _run_mission: Node
var _field: Node3D


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(500.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-hangar-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(STAGE_THREE)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	await process_frame
	_hud = _app.get("hud") as CanvasLayer
	_app.call("_begin")
	await _frames(20)
	_van = _app.get_node("FreightVan") as CharacterBody3D
	_driver = _app.get("driver") as CharacterBody3D
	_run_mission = _app.get("run") as Node
	_field = _app.get_node("IndustrialLoop").get("harbour_flats").get("airfield") as Node3D
	_check_controls()
	await _check_reload()
	var encounter := _run_mission.get("encounter") as Node
	if encounter == null:
		_check(false, "H2: the encounter is set up at stage 3 (none)")
		_finish()
		return
	await _check_maya(encounter)
	await _check_shots(encounter)
	await _check_reload_gun(encounter)
	await _check_guards(encounter)
	await _check_retry(encounter)
	await _check_van(encounter)
	await _check_office(encounter)
	_finish()


## H1: the three controls, as named actions on the mouse and R.
func _check_controls() -> void:
	var fire := _on_mouse("fire", MOUSE_BUTTON_LEFT)
	var aim := _on_mouse("aim", MOUSE_BUTTON_RIGHT)
	var reload := false
	if InputMap.has_action("reload"):
		for event in InputMap.action_get_events("reload"):
			reload = reload or (event is InputEventKey
				and (event as InputEventKey).physical_keycode == KEY_R)
	_check(fire and aim and reload, ("H1: left mouse fires (%s), right mouse aims (%s), R "
		+ "reloads (%s)") % [fire, aim, reload])


func _on_mouse(action: String, button: MouseButton) -> bool:
	if not InputMap.has_action(action):
		return false
	for event in InputMap.action_get_events(action):
		var click := event as InputEventMouseButton
		if click != null and click.button_index == button:
			return true
	return false


## H2 (reload at stage 3): the van at the service gate, open; Maya by her car there; MAYA.
func _check_reload() -> void:
	var gate: Vector3 = _field.get("service_gate")
	await _frames(30)
	var maya := _run_mission.get("maya") as Node3D
	var van_near := _flat(_van.global_position, gate) < 16.0
	var maya_near := maya != null and maya.visible and _flat(maya.global_position, gate) < 9.0
	_check(van_near and bool(_field.call("service_open")) and maya_near and _objective() == "MAYA",
		("H2: reloaded at stage 3, the van at the service gate (%.1f m), open (%s), Maya by her "
		+ "car there (%s), MAYA (%s)") % [_flat(_van.global_position, gate),
		_field.call("service_open"), maya_near, _objective()])


## H3: on foot by Maya, E talks to her; she hands him the rifle (C68): 30 and a spare 30; the HUD shows
## it; GET INTO THE HANGAR.
func _check_maya(encounter: Node) -> void:
	await _press("interact")
	var waited := 0.0
	while (not bool(_driver.get("active")) or bool(_app.get("_boarding"))) and waited < 10.0:
		await physics_frame
		waited += 1.0 / 60.0
	await _seconds(0.5)
	var maya := _run_mission.get("maya") as Node3D
	_place_ethan(maya.global_position + maya.global_basis.z * 1.4, maya.global_position)
	await _frames(20)
	var offered := (_hud.get("_hint") as Label).text
	await _press("interact")
	var gun := encounter.get("handgun") as Node
	waited = 0.0
	while not bool(gun.get("armed")) and waited < 30.0:
		await physics_frame
		waited += 1.0 / 60.0
	await _frames(10)
	var ammo := _hud.call("ammo_text") as String
	_check(offered == "E  Talk to Maya" and bool(gun.get("armed")) and int(gun.get("magazine"))
		== ROUNDS and int(gun.get("reserve")) == ROUNDS and ammo == "%d / %d" % [ROUNDS, ROUNDS]
		and _objective() == "GET INTO THE HANGAR", ("H3: by Maya (%s) E talks; she hands him the "
		+ "rifle (%s), %d and %d spare, the HUD %s; %s") % [offered, gun.get("armed"),
		gun.get("magazine"), gun.get("reserve"), ammo, _objective()])


## H4: aimed at a man's chest 8 m off, two shots: the first hits and he comes for him, the second
## puts him down; down, he stays down and no shot hits him again. (C68: the rifle is drawn and
## raised before he is placed, as it fires only from aim.)
func _check_shots(encounter: Node) -> void:
	var gun := encounter.get("handgun") as Node
	var guard := (encounter.get("guards") as Array)[0] as Node3D
	Input.action_press("aim")
	await _ready_to_fire()
	var chest := guard.global_position + Vector3.UP * 1.3
	var toward := Vector3(guard.global_basis.z.x, 0.0, guard.global_basis.z.z).normalized()
	_place_ethan(guard.global_position + toward * 8.0, chest)
	await _frames(3)
	_driver.call("aim_toward", chest)
	await _frames(5)
	await _press("fire")
	await _frames(5)
	var first: float = guard.get("health")
	var state_after_first := String(guard.get("state"))
	await _seconds(0.5)
	_driver.call("aim_toward", guard.global_position + Vector3.UP * 1.3)
	await _frames(3)
	await _press("fire")
	await _frames(20)
	var down := String(guard.get("state")) == "down"
	var left: int = gun.get("magazine")
	await _press("fire")
	await _frames(5)
	Input.action_release("aim")
	_check(first > 0.0 and first < 100.0 and state_after_first in ["chase", "attack"] and down
		and float(guard.get("health")) <= 0.0 and left == ROUNDS - 2 \
		and int(gun.get("magazine")) == ROUNDS - 3
		and String(guard.get("state")) == "down", ("H4: a hit (%.0f left, he %s), a second puts "
		+ "him down (%s), %d left; down he stays down (%s)") % [first, state_after_first, down,
		ROUNDS - 2,
		guard.get("state")])


## H5: R reloads in the time it takes: the magazine full again from the spare; empty with nothing
## spare, the trigger clicks and nothing fires. (C68: the rifle is brought out first; slung, R does
## nothing.)
func _check_reload_gun(encounter: Node) -> void:
	encounter.call("reset")
	var gun := encounter.get("handgun") as Node
	Input.action_press("aim")
	await _ready_to_fire()
	Input.action_release("aim")
	await _frames(40)
	gun.set("magazine", 12)
	var spare_before: int = gun.get("reserve")
	var missing := ROUNDS - int(gun.get("magazine"))
	await _press("reload")
	var reloading := bool(gun.get("reloading"))
	await _seconds(float(gun.get("RELOAD_SECONDS")) + 0.3)
	var full := int(gun.get("magazine")) == ROUNDS \
		and int(gun.get("reserve")) == spare_before - missing
	gun.set("magazine", 0)
	gun.set("reserve", 0)
	var shots_before: int = gun.get("shots")
	Input.action_press("aim")
	await _ready_to_fire()
	await _press("fire")
	await _frames(5)
	Input.action_release("aim")
	_check(reloading and full and int(gun.get("shots")) == shots_before and int(gun.get("dry"))
		>= 1, ("H5: R reloads (%s) to a full magazine from the spare (%s); empty, the trigger "
		+ "clicks (%d) and nothing fires") % [reloading, full, gun.get("dry")])
	gun.set("magazine", ROUNDS)
	gun.set("reserve", ROUNDS)


## H6: a man who sees him in the open comes and shoots: his health falls; a man too far to see him
## hears a shot and comes.
func _check_guards(encounter: Node) -> void:
	encounter.call("reset")
	await _frames(5)
	var guards: Array = encounter.get("guards")
	var seer := guards[1] as Node3D
	var hearer := guards[2] as Node3D
	var toward := Vector3(seer.global_basis.z.x, 0.0, seer.global_basis.z.z).normalized()
	var health_before: float = encounter.get("health")
	_place_ethan(seer.global_position - toward * 9.0, seer.global_position + Vector3.UP * 1.3)
	var waited := 0.0
	while float(encounter.get("health")) >= health_before and waited < 10.0:
		await physics_frame
		waited += 1.0 / 60.0
	var attacked := String(seer.get("state")) == "attack"
	var hurt := float(encounter.get("health")) < health_before
	encounter.call("reset")
	await _frames(5)
	var behind := Vector3(hearer.global_basis.z.x, 0.0, hearer.global_basis.z.z).normalized()
	_place_ethan(hearer.global_position + behind * 30.0, hearer.global_position + behind * 40.0)
	await _frames(5)
	var far := _flat(hearer.global_position, _driver.global_position)
	var unseen := not bool(hearer.call("sees", _driver.global_position + Vector3.UP * 1.2))
	Input.action_press("aim")
	await _ready_to_fire()
	_driver.call("aim_toward", _driver.global_position + Vector3(0.0, 30.0, -10.0))
	await _press("fire")
	await _frames(10)
	Input.action_release("aim")
	var came := String(hearer.get("state")) in ["chase", "attack"]
	_check(attacked and hurt and unseen and came, ("H6: seen in the open a man shoots (%s), his "
		+ "health falls (%s, %.0f); %.0f m off and unseen (%s), another hears a shot and comes "
		+ "(%s)") % [attacked, hurt, encounter.get("health"), far, unseen, came])


## H7: his health at nothing, all begins again at the service gate: on foot inside it, full health,
## the magazine and spare full, every man back at his post and standing.
func _check_retry(encounter: Node) -> void:
	var gun := encounter.get("handgun") as Node
	gun.set("magazine", 3)
	var retries: int = encounter.get("retries")
	encounter.call("hurt", 1000.0)
	var waited := 0.0
	while int(encounter.get("retries")) == retries and waited < 8.0:
		await physics_frame
		waited += 1.0 / 60.0
	await _seconds(2.0)
	var gate: Vector3 = _field.get("service_gate")
	var standing := true
	for guard: Node3D in encounter.get("guards"):
		standing = standing and String(guard.get("state")) == "patrol" \
			and is_equal_approx(float(guard.get("health")), 100.0) \
			and _flat(guard.global_position, (guard.get("start") as Transform3D).origin) < 2.0
	_check(int(encounter.get("retries")) == retries + 1 and bool(_driver.get("active"))
		and _flat(_driver.global_position, gate) < 8.0 and is_equal_approx(float(encounter.get(
		"health")), 100.0) and int(gun.get("magazine")) == ROUNDS \
		and int(gun.get("reserve")) == ROUNDS
		and standing, ("H7: down, all begins again at the service gate (%.1f m), health %.0f, %d "
		+ "and %d, every man at his post (%s)") % [_flat(_driver.global_position, gate),
		encounter.get("health"), gun.get("magazine"), gun.get("reserve"), standing])


## H8: driven onto the airfield, they hear the van: all begins again at the gate.
func _check_van(encounter: Node) -> void:
	var retries: int = encounter.get("retries")
	_driver.call("set_active", false)
	_van.set("occupied", true)
	var apron: Rect2 = _field.get("apron")
	_van.call("recover", Transform3D(Basis.IDENTITY, Vector3(apron.get_center().x, 0.1,
		apron.end.y + 20.0)))
	var waited := 0.0
	while int(encounter.get("retries")) == retries and waited < 8.0:
		await physics_frame
		waited += 1.0 / 60.0
	await _seconds(2.0)
	var gate: Vector3 = _field.get("service_gate")
	_check(int(encounter.get("retries")) == retries + 1 and bool(_driver.get("active"))
		and _flat(_driver.global_position, gate) < 8.0 and _flat(_van.global_position, gate) < 16.0
		and _van.global_position.z > gate.z, ("H8: the van driven onto the airfield, they hear it "
		+ "(%s); back at the gate on foot (%.1f m), the van outside it (%.1f m)") % [
		int(encounter.get("retries")) == retries + 1, _flat(_driver.global_position, gate),
		_flat(_van.global_position, gate)])


## H9: at the office door, no man on him, stage 4 saved, FIND LILY; the door a real one, 1 m wide.
func _check_office(encounter: Node) -> void:
	var door: Vector3 = _field.get("office_door")
	var wide: float = _field.get("office_door_width")
	_place_ethan(door + Vector3(0.0, 0.0, -1.0), door)
	var waited := 0.0
	while _objective() != "FIND LILY" and waited < 5.0:
		await physics_frame
		waited += 1.0 / 60.0
	await _frames(10)
	var saved := ConfigFile.new()
	saved.load(_scratch)
	_check(int(saved.get_value("run", "stage", -1)) == 4 and _objective() == "FIND LILY"
		and wide > 0.85 and wide < 1.1, ("H9: at the office door (%.2f m wide), stage %s saved, "
		+ "%s") % [wide, saved.get_value("run", "stage", -1), _objective()])


func _place_ethan(at: Vector3, look: Vector3) -> void:
	var space := _driver.get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(at + Vector3.UP * 3.0,
		at + Vector3.DOWN * 5.0, 1))
	_driver.global_position = (hit["position"] as Vector3) if not hit.is_empty() else at
	_driver.velocity = Vector3.ZERO
	var facing := Vector3(look.x - at.x, 0.0, look.z - at.z).normalized()
	_driver.call("face", facing)
	_driver.call("look_toward", facing)


## The rifle drawn and raised to aim (C68: it fires only from aim), or 8 s.
func _ready_to_fire() -> void:
	var waited := 0.0
	while not bool(_driver.call("can_fire")) and waited < 8.0:
		await physics_frame
		waited += 1.0 / 60.0
	await _frames(5)


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _objective() -> String:
	return (_hud.get("_objective") as Label).text


func _press(action: String) -> void:
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


func _frames(count: int) -> void:
	for frame in range(count):
		await physics_frame


func _seconds(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _timeout() -> void:
	print("FAIL: test timed out")
	_failures += 1
	_finish()


func _finish() -> void:
	print("HANGAR RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(1 if _failures > 0 else 0)
