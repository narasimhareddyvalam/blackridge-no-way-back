extends SceneTree
## Mission 3's convoy waits on the coastal road (x 726, z 95 and 117) from the mission's start,
## hidden until the convoy stage. Found filming Mission 3 (#448): escaping south from the waterfront
## during GET AWAY, the van stopped dead at z 122 against an SUV nobody could see. A hidden scripted
## SUV is not solid; shown, it stops the van as a real car would. Driven through the real controls
## (accelerate pressed as an Input action), north up the coastal road from z 150, at most 15 s.

const SUV = preload("res://features/vehicles/scripted_suv/scripted_suv.gd")
const PARKED := Vector3(726.0, 0.0, 117.0)
const FROM := Vector3(726.0, 0.1, 150.0)
const PAST_Z := 100.0

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func check(description: String, condition: bool) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	var app := (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	app.get_node("DrivingTrial").checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-hidden-suv-%d.cfg" % OS.get_process_id())
	root.add_child(app)
	await process_frame
	app.call("_resume")
	await process_frame
	var van := app.get_node("FreightVan") as CharacterBody3D
	var suv := SUV.new()
	app.add_child(suv)
	suv.call("place", Transform3D(Basis.IDENTITY, PARKED))
	for shown in [false, true]:
		suv.visible = shown
		var reached := await _drive_north(van)
		if shown:
			check("S2 shown, the SUV stops the van short of it (reached z %.1f)" % reached,
				reached > PARKED.z)
		else:
			check("S1 hidden, the van drives through where it waits (reached z %.1f)" % reached,
				reached <= PAST_Z)
	print("HIDDEN SUV RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	quit(1 if _failures > 0 else 0)


func _drive_north(van: CharacterBody3D) -> float:
	van.call("recover", Transform3D(Basis.IDENTITY, FROM))
	for wait in range(30):
		await physics_frame
	var ticks := 0
	while ticks < 60 * 15 and van.global_position.z > PAST_Z:
		ticks += 1
		Input.action_release("accelerate")
		if float(van.get("speed")) < 8.0:
			Input.action_press("accelerate", 0.6)
		await physics_frame
	Input.action_release("accelerate")
	return van.global_position.z
