extends SceneTree
## The east road onto the harbour flats (Mission 3): a van driven east off the rim's cut, and back
## west, crosses the seam where the hill's ground meets the flats' embankment at x 659.5-660 without
## stopping, in every lane and at walking to cruising pace. Found filming Mission 3 (#448): the
## embankment's columns either side of the road reached up the cut's banks, and the slope between
## them stood up to 13 cm above the road at its edge; a van driven east stopped dead at x 657. Driven
## through the real controls (accelerate pressed as an Input action), each run from x 630 to 680
## (or back), at most 20 s.

const EAST := -PI / 2.0
const WEST := PI / 2.0
const RUNS := [[EAST, 150.05, 6.0], [EAST, 153.35, 6.0], [EAST, 153.35, 12.0], [EAST, 151.7, 3.0],
	[EAST, 149.0, 6.0], [EAST, 154.5, 8.0], [WEST, 150.05, 6.0], [WEST, 153.35, 12.0],
	[WEST, 149.5, 6.0]]

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
		"blackridge-flats-seam-%d.cfg" % OS.get_process_id())
	root.add_child(app)
	await process_frame
	app.call("_resume")
	await process_frame
	var van := app.get_node("FreightVan") as CharacterBody3D
	for run: Array in RUNS:
		var heading: float = run[0]
		var z: float = run[1]
		var pace: float = run[2]
		var east := heading == EAST
		van.call("recover", Transform3D(Basis(Vector3.UP, heading),
			Vector3(630.0 if east else 690.0, 0.1, z)))
		for wait in range(30):
			await physics_frame
		var ticks := 0
		var stopped_at := INF
		while ticks < 60 * 20 and (van.global_position.x < 680.0 if east
				else van.global_position.x > 630.0):
			ticks += 1
			Input.action_release("accelerate")
			if float(van.get("speed")) < pace:
				Input.action_press("accelerate", 0.6)
			await physics_frame
			if ticks > 120 and absf(float(van.get("speed"))) < 0.05 and stopped_at == INF:
				stopped_at = van.global_position.x
		Input.action_release("accelerate")
		var through := van.global_position.x >= 680.0 if east else van.global_position.x <= 630.0
		check("S1 %s at z %.2f, %.0f m/s: across the seam to x %.1f%s" % ["east" if east else
			"west", z, pace, van.global_position.x, "" if stopped_at == INF
			else " (stopped at x %.1f)" % stopped_at], through and stopped_at == INF)
	print("FLATS SEAM RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	quit(1 if _failures > 0 else 0)
