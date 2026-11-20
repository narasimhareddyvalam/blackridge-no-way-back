extends SceneTree
## Step 2e-3, the doors and the seal (docs/PHASE_BRIEF.md, rules H3–H6, with the author's
## decisions L2 b, #230, and C58, #235), in the running game on Mission 2's start save. The van
## is set docked and chocked at bay 9 with the pallet strapped in its hold as setup
## (`test_bay_nine.gd` and `test_loading.gd` reach that by real keys); from there everything
## Ethan does uses the real keys. A headless run draws nothing, so the look is not checked here.

## He seals the doors half crouched from 0.78 m out, his hands on the hasp (#338).
const AT_THE_DOORS := 0.9
const START_SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const DOCKED := Vector3(-47.75, 0.1, 23.16)
const BAY := -47.75
const BUMPERS := 20.13
const VAN_REAR := 3.012
const CLEAR_OF_DOCK := 2.5
const BULKHEAD := -0.25
const LOAD_HALF := 0.61
const BY_THE_WHEEL := Vector3(-1.5, 0.0, 1.5)
const AT_THE_DOOR := Vector3(-2.0, 0.0, -0.5)
const TO_THE_REAR: Array[Vector3] = [Vector3(-1.7, 0.0, 1.5), Vector3(-1.5, 0.0, 4.3),
	Vector3(0.0, 0.0, 4.2)]
const TO_THE_REAR_NEAR: Array[Vector3] = [Vector3(-1.7, 0.0, 1.5), Vector3(-1.5, 0.0, 3.9),
	Vector3(0.0, 0.0, 4.0)]
## Where the seal's cutscene steps Ethan clear, in the van's frame (`seal_cutscene.gd`, #333).
const CLEAR_SPOT := Vector3(1.5, 0.0, 2.4)
const BACK_TO_THE_DOORS: Array[Vector3] = [Vector3(-1.6, 0.0, 4.4), Vector3(0.0, 0.0, 4.2)]
const SHORT_PULL := 1.9
const FULL_PULL := 3.0
const VAN_BOX := AABB(Vector3(-1.0, 0.15, -2.52), Vector3(2.0, 2.1, 5.53))
const RAIL := Vector3(-46.125, 0.0, 24.95)
const WALL := Vector3(-44.0, 0.0, 19.9)
const DOORS_BY_HAND := 26.0
const CAMERA_SKIN := 0.15
const DOCK_FACE_Z := 20.0
## How long the dock worker's round may take, out to the doors and back in: 60 s until the audit's
## fourth fix (#329), 90 s since he gets going and stops, turns on the spot and takes the stair
## at a stair's pace (`test_dock_worker.gd`'s ROUND).
const SEAL_ROUND := 90.0

var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _app: Node3D
var _hud: CanvasLayer
var _van: CharacterBody3D
var _driver: CharacterBody3D
var _shed: Node3D
var _bay: Node
var _load: Node3D


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(360.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-sealing-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_store(START_SAVE)
	await _build()
	await _key(KEY_ENTER)
	await _seconds(1.0)
	_van.call("recover", Transform3D(Basis(Vector3.UP, PI), DOCKED))
	_van.set("rear_doors_open", true)
	await _seconds(1.5)
	var docked: bool = _bay.get("verdict") == "docked"
	if docked:
		_bay.call("chock_wheel")
	_load = _shed.get_node_or_null("Building/Pallet6") as Node3D
	_shed.call("stow_load", _van)
	await _seconds(0.5)
	var stowed := _load != null and _van.is_ancestor_of(_load) and _load.has_meta("strapped")
	_check(docked and bool(_bay.get("chocked")) and stowed,
		"Setup: the van docked at bay 9 and chocked, the pallet strapped in its hold")
	await _key(KEY_E)
	await _until(_on_foot, 8.0)
	_check_step_out()
	await _check_chock_out()
	await _check_doors()
	await _check_seal()
	await _check_reload()
	await _check_fresh_start()
	_finish()


## Getting out of the van, Ethan steps over a dock's 20 cm wheel guide as over a kerb; a wall
## still keeps him in (step 2e-3).
func _check_step_out() -> void:
	var over_rail: bool = _app.call("_clear", RAIL + Vector3.UP * 0.2)
	var at_wall: bool = _app.call("_clear", WALL + Vector3.UP * 0.2)
	_check(over_rail and not at_wall,
		("H4: the way out of the van is clear over bay 9's wheel guide (%s) but not against the "
		+ "dock's wall (%s)") % [over_rail, at_wall])


func _check_chock_out() -> void:
	await _seconds(0.5)
	var asked := _objective()
	var red := not _bay_green()
	await _walk_by_van([BY_THE_WHEEL])
	var offered := _hint()
	await _key(KEY_E)
	await _seconds(0.5)
	_check(asked == "TAKE THE CHOCK OUT" and red and offered == "E  Take the chock out"
		and not bool(_bay.get("chocked")) and _bay_green(),
		("H3: loaded, bay 9 still red outside (%s), the objective asks for the chock to come out "
		+ "(%s); E at the wheel (%s) takes it out and bay 9 turns green outside (%s)")
		% [red, asked, offered, _bay_green()])


func _check_doors() -> void:
	var asked := _objective()
	await _board()
	await _pull_to(SHORT_PULL)
	await _key(KEY_E)
	await _until(_on_foot, 8.0)
	await _walk_by_van(TO_THE_REAR_NEAR)
	var near := _gap()
	var offered := _hint()
	await _key(KEY_E)
	await _seconds(2.5)
	var kept_open := bool(_van.get("rear_doors_open"))
	var told := _objective()
	_check(asked == "PULL FORWARD" and offered == "E  Close the rear doors" and kept_open
		and told == "PULL FORWARD" and near < CLEAR_OF_DOCK,
		("H4: the chock out, the objective asks to pull forward (%s); with the van's rear %.2f m "
		+ "from the bumpers E at the doors (%s) leaves them open (%s) and the objective still "
		+ "says to pull forward first (%s)") % [asked, near, offered, kept_open, told])
	await _walk_by_van([AT_THE_DOOR])
	await _board()
	await _pull_to(FULL_PULL)
	await _key(KEY_E)
	await _until(_on_foot, 8.0)
	await _walk_by_van(TO_THE_REAR)
	var far := _gap()
	offered = _hint()
	_driver.call("look_toward", -_van.global_basis.z)
	await _seconds(0.4)
	await _key(KEY_E)
	var against := 0
	var behind_face := 0
	var deepest := -INF
	var frames := 0
	var time := 0.0
	var vis := _van.get_node("VanPresentation")
	var camera := _driver.call("get_camera") as Camera3D
	while not _doors_done() and time < DOORS_BY_HAND:
		await physics_frame
		time += 1.0 / 60.0
		frames += 1
		if _driver.global_position.z > DOCK_FACE_Z and camera.global_position.z < DOCK_FACE_Z:
			behind_face += 1
			deepest = maxf(deepest, DOCK_FACE_Z - camera.global_position.z)
		for index in range(2):
			var door := vis.call("rear_door", index) as Node3D
			var extent: AABB = vis.call("rear_door_extent", index)
			if extent.grow(CAMERA_SKIN).has_point(door.to_local(camera.global_position)):
				against += 1
				break
	await _seconds(0.3)
	_check(far >= CLEAR_OF_DOCK and offered == "E  Close the rear doors"
		and not bool(_van.get("rear_doors_open")) and _door_angles().x < 2.0
		and _door_angles().y < 2.0,
		("H4: pulled forward until its rear is %.2f m from the bumpers, E at the doors (%s) "
		+ "closes them (%s)") % [far, offered, str(_door_angles())])
	_check(frames > 0 and against == 0,
		("H4: closing them by the dock, his camera looking along the van, his camera is never "
		+ "in or against a door, within %.2f m, so the view never goes black (in %d of %d "
		+ "frames)") % [CAMERA_SKIN, against, frames])
	_check(frames > 0 and behind_face == 0,
		("H4: closing them in the court, his camera never backs through bay 9's open door into "
		+ "the dark behind the dock's face, where the view goes black (behind it in %d of %d "
		+ "frames, at most %.2f m)") % [behind_face, frames, maxf(deepest, 0.0)])


func _check_seal() -> void:
	var asked := _objective()
	await _check_cutscene_starts()
	var worker := _shed.find_child("DockWorker", true, false) as Node3D
	var hasp: Vector3 = _van.call("seal_point")
	var closest := INF
	var entered := false
	var time := 0.0
	var sealed_at := -1.0
	while time < SEAL_ROUND and worker != null:
		if worker.visible:
			closest = minf(closest, _flat(worker.global_position - hasp).length())
			var inside := _van.to_local(worker.global_position + Vector3.UP * 0.9)
			entered = entered or VAN_BOX.has_point(inside)
		if sealed_at < 0.0 and bool(_van.get("sealed")):
			sealed_at = time
		if sealed_at >= 0.0 and bool(worker.get("home")):
			break
		await physics_frame
		time += 1.0 / 60.0
	var seal := _van.find_child("BoltSeal", true, false) as Node3D
	var home := worker != null and bool(worker.get("home"))
	_check(asked == "WAIT FOR THE SEAL" and worker != null and closest < AT_THE_DOORS \
		and not entered
		and sealed_at > 0.0 and seal != null and seal.is_visible_in_tree() and home,
		("H5: the doors shut, the objective says to wait for the seal (%s); the dock worker walks "
		+ "out to the doors (%.2f m from the hasp at the closest, never through the van: %s), "
		+ "puts the bolt seal on (after %.1f s; seal shown: %s) and walks back in (%s)")
		% [asked, closest, not entered, sealed_at, seal != null and seal.is_visible_in_tree(),
		home])
	var cutscene := _app.get("seal_cutscene") as Node
	var given_back: bool = cutscene != null and not bool(cutscene.get("playing")) \
		and _driver.get_viewport().get_camera_3d() == _driver.call("get_camera") \
		and not bool(_driver.get("held"))
	_check(given_back, ("H5b: with the dock hand on his way back the cutscene ends: Ethan's own "
		+ "camera and his control back (%s)") % given_back)
	await _walk_by_van(BACK_TO_THE_DOORS)
	var offered := _hint()
	await _key(KEY_E)
	await _seconds(0.5)
	var number := str(_van.get("seal_number"))
	var words := _document()
	var shown := bool(_hud.call("document_visible"))
	_check(offered == "E  Check the seal" and shown and not number.is_empty()
		and words.count(number) == 3 and words.contains("Bolt") and words.contains("Cap")
		and words.contains("Run sheet"),
		("H5: at the sealed doors E (%s) shows the check: the number %s on the bolt, on the cap "
		+ "and on the run sheet's seal line, side by side (%d times in it)")
		% [offered, number, words.count(number)])
	await _key(KEY_E)
	await _seconds(0.5)
	var after := _hint()
	await _key(KEY_E)
	await _seconds(2.5)
	_check(not after.contains("Open the rear doors") and not bool(_van.get("rear_doors_open")),
		("H5: sealed, the doors no longer open: the hint at them is \"%s\" and E leaves them shut")
		% after)
	await _seconds(0.5)
	var saved := ConfigFile.new()
	var read := saved.load(_scratch)
	_check(read == OK and saved.get_value("cargo", "stage", -1) == 1
		and saved.get_value("save", "mission", "") == "the_wrong_cargo"
		and _objective() == "DRIVE TO THE CONTAINER YARD",
		("H6: checked, \"loaded\" saves Mission 2's stage 1 (stage %s in the file) and the "
		+ "objective moves on (%s)") % [saved.get_value("cargo", "stage", -1), _objective()])


func _check_reload() -> void:
	_app.queue_free()
	await process_frame
	await process_frame
	await _build()
	await _key(KEY_ENTER)
	await _seconds(1.5)
	_shed = _app.get_node("IndustrialLoop").get("transfer_shed")
	_load = _van.find_child("Pallet6", true, false) as Node3D
	var gap := _gap()
	var across := absf(_van.global_position.x - BAY)
	var facing := absf(angle_difference(_van.global_rotation.y, PI))
	var inside := _van.to_local(_load.global_position) if _load != null else Vector3.INF
	var against := inside.z - LOAD_HALF - BULKHEAD
	var loaded := _load != null and _van.is_ancestor_of(_load) and _load.has_meta("strapped") \
		and absf(against) < 0.06 and absf(float(_van.get("load_kg")) - 520.0) < 0.1
	_check(gap >= CLEAR_OF_DOCK and gap < 4.5 and across < 0.2 and facing < 0.05 and loaded
		and not bool(_van.get("rear_doors_open")) and bool(_van.get("sealed"))
		and bool(_van.get("occupied")),
		("H6: reloaded, the van stands in front of bay 9 (its rear %.2f m from the bumpers, %.2f m "
		+ "off the bay's middle) with the pallet strapped against the bulkhead in its hold (%s), "
		+ "its doors shut and sealed, and Ethan in it (%s)") % [gap, across, loaded,
		_van.get("occupied")])


## Mission 2 started again from its beginning, as the title's "new game" or a stage 0 save does:
## the pallet is back where it was staged, unstrapped and solid, and the van empty and unsealed.
func _check_fresh_start() -> void:
	var cargo: Node = _app.get_node("TheWrongCargo")
	cargo.call("configure", _van, cargo.call("start_progress"))
	await physics_frame
	await physics_frame
	var staged := _shed.get_node_or_null("Building/Pallet6") as Node3D
	var home := Vector3(-47.2, 1.3, 16.6)
	var solid := staged != null and staged.find_children("*", "CollisionShape3D", true, false) \
		.all(func(shape: Node) -> bool: return not (shape as CollisionShape3D).disabled)
	_check(staged != null and Vector2(staged.global_position.x - home.x,
		staged.global_position.z - home.z).length() < 0.05 and not staged.has_meta("strapped")
		and staged.find_children("LoadStrap*", "Node3D", true, false).is_empty()
		and solid and float(_van.get("load_kg")) == 0.0 and not bool(_van.get("sealed")),
		("H6: started again from Mission 2's beginning, the pallet stands back on bay 9's staging "
		+ "spot, unstrapped (%s), and the van is empty and unsealed (%.0f kg, sealed %s)")
		% [solid, float(_van.get("load_kg")), _van.get("sealed")])


## Drives the van forward with W until its rear is `gap` metres from the bumpers, then brakes.
func _pull_to(gap: float) -> void:
	var time := 0.0
	Input.action_press("accelerate", 0.5)
	while _gap() < gap - 0.45 and time < 8.0:
		await physics_frame
		time += 1.0 / 60.0
	Input.action_release("accelerate")
	Input.action_press("brake")
	time = 0.0
	while absf(float(_van.get("speed"))) > 0.02 and time < 4.0:
		await physics_frame
		time += 1.0 / 60.0
	Input.action_release("brake")
	await _seconds(0.5)


func _board() -> void:
	await _walk_by_van([AT_THE_DOOR])
	await _key(KEY_E)
	await _until(_in_the_van, 8.0)
	await _seconds(0.5)


func _gap() -> float:
	return _van.to_global(Vector3(0.0, 1.0, VAN_REAR)).z - BUMPERS


func _bay_green() -> bool:
	var outside := _shed.get_node("Building/DockSignal9") as Node3D
	return _lit(outside, "Green") and not _lit(outside, "Red")


func _lit(signal_node: Node3D, lens: String) -> bool:
	var mesh := signal_node.get_node_or_null(lens) as MeshInstance3D
	var surface := mesh.get_active_material(0) as StandardMaterial3D if mesh != null else null
	return surface != null and surface.emission_enabled


func _door_angles() -> Vector2:
	var left := _van.find_child("RearDoorLeft", true, false) as Node3D
	var right := _van.find_child("RearDoorRight", true, false) as Node3D
	if left == null or right == null:
		return Vector2(-1.0, -1.0)
	return Vector2(absf(rad_to_deg(left.rotation.y)), absf(rad_to_deg(right.rotation.y)))


## H5b (#333): the doors shut and the dock hand sent out, his round is shown: the cutscene's
## camera current, Ethan stepping clear to the van's far side, the keys not moving him.
func _check_cutscene_starts() -> void:
	var cutscene := _app.get("seal_cutscene") as Node
	await _seconds(3.0)
	var playing := cutscene != null and bool(cutscene.get("playing"))
	var current: bool = playing and _driver.get_viewport().get_camera_3d() == cutscene.get("camera")
	var spot := _van.to_global(CLEAR_SPOT)
	var stood := _flat(_driver.global_position - spot).length()
	var from := _driver.global_position
	Input.action_press("accelerate")
	await _seconds(1.0)
	Input.action_release("accelerate")
	var drifted := _flat(_driver.global_position - from).length()
	var hasp: Vector3 = _van.call("seal_point")
	var clear := _flat(_driver.global_position - hasp).length()
	_check(playing and current and stood < 0.4 and drifted < 0.05 and clear > 1.2,
		("H5b: the doors shut and the dock hand sent out, his round is shown (%s, its camera "
		+ "current: %s); Ethan steps clear to the van's far side (%.2f m from his spot, %.2f m "
		+ "from the hasp) and W does not move him (%.3f m)") % [playing, current, stood, clear,
		drifted])


func _walk_by_van(points: Array[Vector3]) -> void:
	for point in points:
		var target := _van.to_global(point)
		var time := 0.0
		Input.action_press("accelerate")
		while _flat(target - _driver.global_position).length() > 0.3 and time < 12.0:
			_driver.call("look_toward", _flat(target - _driver.global_position).normalized())
			await physics_frame
			time += 1.0 / 60.0
		Input.action_release("accelerate")
	await _seconds(0.4)


func _on_foot() -> bool:
	return not bool(_van.get("occupied")) and not bool(_app.get("_boarding"))


func _in_the_van() -> bool:
	return bool(_van.get("occupied")) and not bool(_app.get("_boarding"))


## Ethan done at the rear doors by hand (part B): they take him as long as a driver.
func _doors_done() -> bool:
	return not bool(_van.call("rear_doors_busy"))


func _until(done: Callable, limit: float) -> void:
	var time := 0.0
	while not done.call() and time < limit:
		await physics_frame
		time += 1.0 / 60.0


func _objective() -> String:
	return (_hud.get("_objective") as Label).text


func _hint() -> String:
	return (_hud.get("_hint") as Label).text


func _document() -> String:
	var sheet := _hud.get("_sheet") as RichTextLabel
	return sheet.get_parsed_text() if sheet != null and sheet.is_visible_in_tree() else ""


func _flat(value: Vector3) -> Vector3:
	return Vector3(value.x, 0.0, value.z)


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
	_shed = _app.get_node("IndustrialLoop").get("transfer_shed")
	_bay = _shed.get("bay_nine")


func _store(text: String) -> void:
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _remove() -> void:
	for suffix in ["", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(_scratch + suffix):
			DirAccess.remove_absolute(_scratch + suffix)


func _timeout() -> void:
	_check(false, "The sealing checks finish within 360 s")
	_finish()


func _finish() -> void:
	print("SEALING RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	_remove()
	quit(1 if _failures > 0 else 0)
