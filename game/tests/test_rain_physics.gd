extends SceneTree

const RainPhysics = preload("res://features/vehicles/freight_van/rain_physics.gd")
const WINDSHIELD_DOWN := Vector2(0.0, -0.949)
const SIDE_DOWN := Vector2(0.0, -1.0)
const UP := Vector2(0.0, 1.0)
const WINDSHIELD_AIR := 0.85
const SIDE_AIR := Vector2(-0.989, 0.148) * 0.9
const TOP_SPEED := 18.9

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run()


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	_check_windshield()
	_check_film()
	_check_side_window()
	_check_integration()
	print("RAIN PHYSICS RESULT: %d/%d passed; %d failed" % [
		_checks - _failures, _checks, _failures])
	quit(0 if _failures == 0 else 1)


func _climb(radius: float, speed: float) -> float:
	return RainPhysics.drop_velocity(radius, WINDSHIELD_DOWN, UP * WINDSHIELD_AIR * speed).dot(UP)


func _check_windshield() -> void:
	var runner := RainPhysics.RUNNER_RADIUS
	_check(_climb(0.0022, 0.0) == 0.0, "A 4.4 mm drop stays pinned on the parked windshield")
	_check(_climb(0.001, TOP_SPEED) == 0.0,
		"A 2 mm drop stays stuck even at 68 km/h (it sits in the slow air next to the glass)")
	var resting := _climb(runner, 0.0)
	_check(resting < -0.05, "An 11 mm runner slides down the parked windshield (%.3f m/s)" % resting)
	_check(_climb(runner, 13.5) == 0.0, "At 49 km/h gravity and air drag balance: the runner holds")
	var climbing := _climb(runner, TOP_SPEED)
	_check(climbing > 0.05, "At 68 km/h the runner climbs the windshield (%.3f m/s)" % climbing)
	_check(_climb(runner, 8.0) > resting and _climb(runner, 8.0) < 0.0,
		"At 29 km/h it still slides down, but slower than when parked")


func _check_film() -> void:
	var parked := RainPhysics.film_velocity(WINDSHIELD_DOWN, Vector2.ZERO).dot(UP)
	var fast := RainPhysics.film_velocity(WINDSHIELD_DOWN, UP * WINDSHIELD_AIR * TOP_SPEED).dot(UP)
	_check(parked < 0.0 and fast > 0.0,
		"The water film drains down when parked (%.4f m/s) and is dragged up at 68 km/h (%.4f m/s)"
		% [parked, fast])


func _check_side_window() -> void:
	var runner := RainPhysics.RUNNER_RADIUS
	var parked := RainPhysics.drop_velocity(runner, SIDE_DOWN, Vector2.ZERO)
	_check(parked.y < 0.0 and is_zero_approx(parked.x), "On a parked side window drops run down")
	var fast := RainPhysics.drop_velocity(runner, SIDE_DOWN, SIDE_AIR * TOP_SPEED)
	_check(fast.x < 0.0 and absf(fast.x) > absf(fast.y),
		"At 68 km/h side-window drops stream mostly backward (%.3f, %.3f m/s)" % [fast.x, fast.y])


func _check_integration() -> void:
	var water := RainPhysics.new()
	for tick in range(60):
		water.step(1.0 / 60.0, WINDSHIELD_DOWN, Vector2.ZERO, UP)
	var parked := water.runner_travel
	for tick in range(120):
		water.step(1.0 / 60.0, WINDSHIELD_DOWN, UP * WINDSHIELD_AIR * TOP_SPEED, UP)
	_check(parked < 0.0 and water.runner_travel > parked,
		"Integrated runner travel goes down when parked and turns up at speed")
	_check(is_zero_approx(water.travel.x),
		"The smallest drop size (%.1f mm across) never moved: it stayed pinned the whole time"
		% (RainPhysics.RADII.x * 2000.0))
	_check(parked < 0.0 and water.runner_down > 0.0 and water.runner_up > 0.0,
		"Separate down and up runner distances both advance, so runners never jump")
