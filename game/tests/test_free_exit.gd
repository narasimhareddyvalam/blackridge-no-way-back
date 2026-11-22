extends SceneTree
## The audit's first fix (docs/PHASE_BRIEF.md, "free exit from the shed and the container
## yard", #321-#322): a free-exit loop just inside each vehicle gate. By real key presses, the
## van driven out of the transfer shed's yard meets the barrier raised for it, never its arm, and
## the arm comes down behind it; driven out of the container yard, the gate slides open for it
## once it stands on the loop and shuts behind it once it is clear; a van on a loop facing in
## opens neither.

const STAGE_ONE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=1\n"
const STAGE_TWO := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=2\n"
const OUT := Basis(Vector3.UP, PI)
const SHED_INSIDE := Vector3(-71.0, 0.1, 45.0)
const SHED_GATE_Z := 55.0
const YARD_INSIDE := Vector3(100.0, 0.1, 147.0)
const YARD_GATE_Z := 157.75
## A van squarely over each exit loop (its middle over the loop's), facing in.
const SHED_OVER_LOOP := Vector3(-71.0, 0.1, 51.5)
const YARD_OVER_LOOP := Vector3(100.0, 0.1, 154.25)
const VAN_FRONT := Vector3(0.0, 1.0, -2.52)
const VAN_REAR := Vector3(0.0, 1.0, 3.01)
const CRUISE := 2.0

var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _app: Node3D
var _van: CharacterBody3D


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(300.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-free-exit-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	await _start(STAGE_ONE)
	await _check_shed()
	await _start(STAGE_TWO)
	await _check_yard()
	_finish()


func _start(save: String) -> void:
	if _app != null:
		_app.queue_free()
		await process_frame
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(save)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	await process_frame
	_app.call("_begin")
	await _frames(10)
	_van = _app.get_node("FreightVan") as CharacterBody3D


func _check_shed() -> void:
	var shed := _app.get_node("IndustrialLoop").get("transfer_shed") as Node3D
	_van.call("recover", Transform3D(Basis.IDENTITY, SHED_OVER_LOOP))
	await _frames(60)
	_check(not bool(shed.call("barrier_open")) and float(shed.call("barrier_angle")) < 1.0,
		"X1: a van over the shed's exit loop facing in leaves the barrier down")
	_van.call("recover", Transform3D(OUT, SHED_INSIDE))
	await _frames(20)
	var run := await _drive_out(SHED_GATE_Z, func() -> bool: return bool(shed.call("barrier_open")))
	_check(run["through"] and not run["blocked"], "X2: driven out of the shed's yard, the van "
		+ "finds the barrier up and passes under it (front %.2f m past its line)" % run["front"])
	var waited := 0.0
	while float(shed.call("barrier_angle")) >= 1.0 and waited < 12.0:
		await physics_frame
		waited += 1.0 / 60.0
	var rear := _van.to_global(VAN_REAR).z
	_check(float(shed.call("barrier_angle")) < 1.0 and rear > SHED_GATE_Z, "X3: and the barrier "
		+ "comes down behind it (the van's rear %.1f m past its line)" % (rear - SHED_GATE_Z))


func _check_yard() -> void:
	var yard := _app.get_node("IndustrialLoop").get("container_yard") as Node3D
	_van.call("recover", Transform3D(Basis.IDENTITY, YARD_OVER_LOOP))
	await _frames(60)
	_check(bool(yard.call("gate_shut")), "X4: a van over the yard's exit loop facing in leaves "
		+ "the gate shut")
	_van.call("recover", Transform3D(OUT, YARD_INSIDE))
	await _frames(20)
	var run := await _drive_out(YARD_GATE_Z, func() -> bool: return bool(yard.call("gate_open")))
	_check(run["through"] and not run["blocked"] and run["waited"]
		and run["said"] == "WAIT FOR THE GATE", "X5: driven out of the container yard, the van "
		+ "waits on the loop while the gate slides open (the objective: %s), then " % run["said"]
		+ "drives out (front %.2f m past its line)" % run["front"])
	var waited := 0.0
	while not bool(yard.call("gate_shut")) and waited < 20.0:
		await physics_frame
		waited += 1.0 / 60.0
	var rear := _van.to_global(VAN_REAR).z
	_check(bool(yard.call("gate_shut")) and rear > YARD_GATE_Z, "X6: and the gate shuts behind "
		+ "it (%.1f s; the van's rear %.1f m past its line)" % [waited, rear - YARD_GATE_Z])


## Drives the van forward toward the gate line `gate_z` (+z), as a driver does: at walking pace
## near the gate, stopping short of it until `is_open` says it is open, then on until the whole
## van is 4 m past it.
func _drive_out(gate_z: float, is_open: Callable) -> Dictionary:
	if int(_van.get("gear")) < 0:
		await _key(KEY_Q)
	var blocked := false
	var waited := false
	var said := ""
	var time := 0.0
	var stuck := 0.0
	while time < 60.0:
		var front := _van.to_global(VAN_FRONT).z
		var rear := _van.to_global(VAN_REAR).z
		if rear > gate_z + 4.0:
			break
		var speed := absf(float(_van.get("actual_speed")))
		var open := bool(is_open.call())
		var hold := not open and front > gate_z - 2.0 and front < gate_z
		if hold and speed < 0.05 and not waited:
			await _frames(5)
			var hud := _app.get("hud") as CanvasLayer
			said = (hud.get("_objective") as Label).text
		waited = waited or (hold and speed < 0.05)
		_press("accelerate", not hold and speed < CRUISE)
		_press("brake", hold or speed > CRUISE + 0.5)
		stuck = stuck + 1.0 / 60.0 if not hold and speed < 0.05 and time > 2.0 else 0.0
		blocked = blocked or stuck > 2.0
		await physics_frame
		time += 1.0 / 60.0
	for action: String in ["accelerate", "brake"]:
		Input.action_release(action)
	var past := _van.to_global(VAN_FRONT).z - gate_z
	return {"through": past > 5.0, "blocked": blocked, "waited": waited, "front": past,
		"said": said}


func _press(action: String, held: bool) -> void:
	if held:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _key(code: Key) -> void:
	var press := InputEventKey.new()
	press.keycode = code
	press.physical_keycode = code
	press.pressed = true
	Input.parse_input_event(press)
	await physics_frame
	var release := press.duplicate() as InputEventKey
	release.pressed = false
	Input.parse_input_event(release)
	await physics_frame


func _frames(count: int) -> void:
	for frame in range(count):
		await physics_frame


func _timeout() -> void:
	_check(false, "The free exits' checks finish within 300 s")
	_finish()


func _finish() -> void:
	print("FREE EXIT RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	for suffix in ["", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(_scratch + suffix):
			DirAccess.remove_absolute(_scratch + suffix)
	quit(1 if _failures > 0 else 0)
