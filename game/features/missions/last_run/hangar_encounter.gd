extends Node
## Mission 3's step 6: the guard encounter at the hangar (docs/PHASE_BRIEF.md, 2026-11-22,
## #359-#360; GAME_DESIGN §8; GAME_STORY's Act V, "a compact guard encounter"). Three of Adrian's
## men (`armed_guard.gd`) on the airfield: one at the hangar's door, one walking the apron round
## the plane, one along the hangar's east wall, the way in from the service gate. Ethan's handgun
## (`handgun.gd`), once Maya hands it over (`arm`): right mouse raises it (his arms, the camera over
## his shoulder), left mouse fires along the crosshair, R reloads. Every man hears a shot. A man's
## round that hits takes DAMAGE of Ethan's HEALTH; at nothing he is down (`down_and_out`), and the
## app begins it again at the service gate (`reset`). The van driven onto the airfield past the
## gate, they hear it (`heard_van`). Words and choices are Claude Code's (#359), drafts.

signal down_and_out
signal heard_van
signal hurt_now(health: float)

const Guard = preload("res://features/characters/syndicate_man/armed_guard.gd")
const Handgun = preload("res://features/weapons/pistol/handgun.gd")
const HEALTH := 100.0
const DAMAGE := 20.0
## How far inside the service gate the van may come before they hear it.
const VAN_HEARD := 15.0

var guards: Array[Node3D] = []
var handgun: Node3D
var health := HEALTH
var retries := 0
var running := false
var airfield: Node3D
var driver: CharacterBody3D
var vehicle: CharacterBody3D
var _out := false


## Its men at their posts and the handgun, on `airfield`.
func build(field: Node3D, ethan: CharacterBody3D, van: CharacterBody3D) -> void:
	airfield = field
	driver = ethan
	vehicle = van
	handgun = Handgun.new()
	handgun.name = "Handgun"
	add_child(handgun)
	handgun.fired.connect(_shot_fired)
	var hangar: Vector3 = field.get("hangar_at")
	var size: Vector3 = field.get("hangar_size")
	var apron: Rect2 = field.get("apron")
	var front := hangar.z - size.z / 2.0
	var east := hangar.x + size.x / 2.0
	var posts := [
		[Vector3(hangar.x + 8.0, 0.0, front - 4.0), [Vector3(hangar.x - 8.0, 0.0, front - 4.0),
			Vector3(hangar.x + 14.0, 0.0, front - 4.0)]],
		[Vector3(apron.position.x + 20.0, 0.0, apron.end.y - 8.0), [Vector3(apron.position.x
			+ 20.0, 0.0, apron.end.y - 8.0), Vector3(apron.end.x - 20.0, 0.0, apron.end.y - 8.0),
			Vector3(apron.end.x - 20.0, 0.0, apron.position.y + 10.0)]],
		[Vector3(east + 5.0, 0.0, front + 8.0), [Vector3(east + 5.0, 0.0, front + 6.0),
			Vector3(east + 5.0, 0.0, hangar.z + size.z / 2.0 - 3.0)]],
	]
	for index in range(posts.size()):
		var guard := Guard.new()
		guard.name = "AdriansMan%d" % (index + 1)
		add_child(guard)
		var at: Vector3 = posts[index][0]
		var points: Array[Vector3] = []
		for point: Vector3 in posts[index][1]:
			points.append(point)
		var ahead := (points[1] - points[0]).normalized() if points[0].distance_to(at) < 0.5 \
			else (points[0] - at).normalized()
		var turn := Basis.looking_at(ahead, Vector3.UP)
		guard.target = driver
		guard.target_active = _ethan_out
		guard.connect("fired_at", _fired_at)
		guard.call("setup", Transform3D(turn, _on_ground(at)), _grounded(points))
		guards.append(guard)
	set_running(false)


func _grounded(points: Array[Vector3]) -> Array[Vector3]:
	var placed: Array[Vector3] = []
	for point in points:
		placed.append(_on_ground(point))
	return placed


func _on_ground(at: Vector3) -> Vector3:
	var space := airfield.get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(at + Vector3.UP * 20.0,
		at + Vector3.DOWN * 20.0, 1))
	return (hit["position"] as Vector3) if not hit.is_empty() else at


## Out on the airfield (true), or not there at all (false).
func set_running(on: bool) -> void:
	running = on
	for guard in guards:
		guard.visible = on
		guard.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	if not on:
		_aim(false)


## Past the office's door (stage 4): the men still on their feet gone from the airfield, the men
## put down left lying where they fell; the gun still his.
func stand_down() -> void:
	running = false
	_aim(false)
	for guard in guards:
		guard.process_mode = Node.PROCESS_MODE_DISABLED
		guard.visible = String(guard.get("state")) == "down"


## Maya's pistol in his hands.
func arm() -> void:
	handgun.armed = true
	handgun.call("refill")


## All as at the service gate: every man at his post, Ethan whole, the gun full.
func reset() -> void:
	health = HEALTH
	_out = false
	handgun.call("refill")
	for guard in guards:
		guard.call("reset")


## A hit on Ethan (or the test's).
func hurt(amount: float) -> void:
	if _out:
		return
	health = maxf(0.0, health - amount)
	hurt_now.emit(health)
	if health <= 0.0:
		_out = true
		retries += 1
		down_and_out.emit()


## Whether any man is after him.
func on_them() -> bool:
	for guard in guards:
		if String(guard.get("state")) in ["alert", "chase", "attack"]:
			return true
	return false


func armed_on_foot() -> bool:
	return running and bool(handgun.armed) and _ethan_out()


func _ethan_out() -> bool:
	return driver != null and bool(driver.get("active"))


func _fired_at(hit: bool, _from: Vector3) -> void:
	if hit and _ethan_out():
		hurt(DAMAGE)


func _shot_fired(at: Vector3) -> void:
	for guard in guards:
		guard.call("heard", at)


func _aim(on: bool) -> void:
	if driver != null and driver.has_method("set_aiming"):
		driver.call("set_aiming", on, handgun)


func _physics_process(_delta: float) -> void:
	if not running:
		return
	_aim(armed_on_foot() and Input.is_action_pressed("aim"))
	if vehicle != null and bool(vehicle.get("occupied")) and not _out:
		var gate: Vector3 = airfield.get("service_gate")
		if bool(airfield.call("inside", vehicle.global_position)) \
				and vehicle.global_position.distance_to(gate) > VAN_HEARD:
			_out = true
			retries += 1
			heard_van.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not armed_on_foot() or event.is_echo():
		return
	if event.is_action_pressed("reload"):
		handgun.call("reload")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("fire") and Input.is_action_pressed("aim"):
		_fire()
		get_viewport().set_input_as_handled()


## One round along the crosshair: from the camera through the screen's middle to the first thing
## there, then from the muzzle to that point.
func _fire() -> void:
	var camera := driver.call("get_camera") as Camera3D
	var from := camera.global_position
	var ahead := -camera.global_basis.z
	var exclude: Array[RID] = [driver.get_rid()]
	var query := PhysicsRayQueryParameters3D.create(from, from + ahead * Handgun.REACH,
		Handgun.STOPS, exclude)
	var hit := driver.get_world_3d().direct_space_state.intersect_ray(query)
	var point: Vector3 = hit["position"] if not hit.is_empty() else from + ahead * Handgun.REACH
	var muzzle: Vector3 = driver.call("muzzle")
	handgun.call("pull", muzzle, point + (point - muzzle).normalized() * 0.2, exclude)
