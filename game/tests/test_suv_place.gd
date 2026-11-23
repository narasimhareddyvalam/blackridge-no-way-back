extends SceneTree
## A scripted SUV stood somewhere (`place`) stands there, whatever it was driving before (found
## recording Mission 3, #451: `drive` keeps the route it is given, and the ambush and the convoy
## give it their constant routes, which are read-only; `place` then failed to clear the route
## ("Array is in read-only state", ambush.gd's retry and escape) and, its leg set back to 0, the
## SUV drove the old route again from its start).
## P1: given a constant route and placed, it has no route left and has not moved 2 s later.

const SUV = preload("res://features/vehicles/scripted_suv/scripted_suv.gd")
const ROUTE: Array[Vector3] = [Vector3(40.0, 0.0, 0.0), Vector3(80.0, 0.0, 0.0)]
const STAND := Vector3(0.0, 0.0, 20.0)

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
	var holder := Node3D.new()
	root.add_child(holder)
	var suv := SUV.new()
	holder.add_child(suv)
	await physics_frame
	suv.call("place", Transform3D.IDENTITY)
	suv.call("drive", ROUTE, 9.0)
	for frame in range(30):
		await physics_frame
	suv.call("place", Transform3D(Basis.IDENTITY, STAND))
	for frame in range(120):
		await physics_frame
	var moved := suv.global_position.distance_to(STAND)
	_check(bool(suv.call("arrived")) and moved < 0.01 and ROUTE.size() == 2,
		"P1 placed, it stands (route left %d, moved %.2f m, the constant route still %d points)"
		% [(suv.get("route") as Array).size(), moved, ROUTE.size()])
	print("SUV PLACE RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	quit(1 if _failures > 0 else 0)
