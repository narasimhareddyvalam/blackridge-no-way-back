extends RefCounted
## The missions' films' player (#362): it plays as a player would, through the real controls
## (analog accelerate, brake and steering pressed as Input actions, E, the mouse buttons), so every
## takeover the game makes (the locked brakes at the crossing, the hold after the hit, cutscenes)
## happens as written. It drives along a path (the loop road's centre line, or any points) by
## looking a few metres ahead and steering for that point, slowing for bends; walks Ethan along
## points; presses keys; and waits on the game's own states. Used by `film_missions.gd`.

var tree: SceneTree
var app: Node3D
var van: CharacterBody3D
var driver: CharacterBody3D
var hud: CanvasLayer
var road: PackedVector3Array
var _last_index := 0
const LANE := 1.5


func _init(scene_tree: SceneTree, game: Node3D) -> void:
	tree = scene_tree
	app = game
	van = app.get_node("FreightVan") as CharacterBody3D
	driver = app.get("driver") as CharacterBody3D
	hud = app.get("hud") as CanvasLayer
	road = app.get_node("IndustrialLoop").get("road_points")


func frames(count: int) -> void:
	for frame in range(count):
		await tree.physics_frame


func seconds(duration: float) -> void:
	await tree.create_timer(duration, true, false, true).timeout


## Waits until `condition` holds, or `limit` seconds pass; true if it held.
func until(condition: Callable, limit: float) -> bool:
	var waited := 0.0
	while not bool(condition.call()) and waited < limit:
		await tree.physics_frame
		waited += 1.0 / Engine.physics_ticks_per_second
	return bool(condition.call())


func press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await tree.process_frame
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	await tree.physics_frame


func key(code: Key) -> void:
	for down in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		Input.parse_input_event(event)
		await tree.process_frame


func objective() -> String:
	return (hud.get("_objective") as Label).text


func cutscene_playing() -> bool:
	var cutscene := app.get("cutscene") as Node
	return cutscene != null and bool(cutscene.get("playing"))


## Let go of every pedal and the wheel.
func release() -> void:
	for action in ["accelerate", "brake", "steer_left", "steer_right", "sprint"]:
		Input.action_release(action)


## Brakes to a stop.
func stop(limit: float = 6.0) -> void:
	release()
	Input.action_press("brake")
	await until(func() -> bool: return absf(float(van.get("speed"))) < 0.15, limit)
	release()


## One physics frame of driving toward `aim` at about `speed` m/s (negative to reverse).
func steer_for(aim: Vector3, speed: float) -> void:
	var local := van.global_basis.inverse() * (aim - van.global_position)
	var ahead := -local.z if speed >= 0.0 else local.z
	var angle := atan2(-local.x, maxf(ahead, 0.5))
	if speed < 0.0:
		angle = -angle
	var wheel := clampf(angle * 2.4, -1.0, 1.0)
	Input.action_release("steer_left")
	Input.action_release("steer_right")
	if wheel > 0.02:
		Input.action_press("steer_left", wheel)
	elif wheel < -0.02:
		Input.action_press("steer_right", -wheel)
	var now := float(van.get("speed"))
	var gap := absf(speed) - absf(now)
	Input.action_release("accelerate")
	Input.action_release("brake")
	if gap > 0.3:
		Input.action_press("accelerate", clampf(gap * 0.35, 0.25, 1.0))
	elif gap < -0.8:
		Input.action_press("brake", clampf(-gap * 0.25, 0.2, 1.0))


## Drives the loop road from where the van is, forward, until its nearest sample reaches `to`
## (or `limit` seconds pass, or the van is left); slows for bends from `cruise` to `slowest`.
func drive_road(to: int, cruise: float, slowest: float = 4.5, limit: float = 600.0) -> bool:
	_last_index = nearest_anywhere(van.global_position)
	var waited := 0.0
	var mark := van.global_position
	var since := 0.0
	while waited < limit and bool(van.get("occupied")):
		await tree.physics_frame
		var step := 1.0 / Engine.physics_ticks_per_second
		waited += step
		if bool(van.get("held")) or bool(van.get("scripted")) or bool(van.get("locked")):
			release()
			mark = van.global_position
			since = 0.0
			continue
		_last_index = nearest(van.global_position, _last_index, 12)
		if _last_index >= to:
			release()
			print("FILM kit: reached sample %d (wanted %d)" % [_last_index, to])
			return true
		var speed := float(van.get("speed"))
		var look := clampi(int(3 + absf(speed) * 0.55), 3, 10)
		var bend := _bend(_last_index, 18)
		var wanted := clampf(cruise / (1.0 + bend * 2.6), slowest, cruise)
		var ahead := mini(_last_index + look, road.size() - 2)
		var aim := lane_point(ahead, clampf(1.0 - bend * 0.9, 0.15, 1.0))
		since += step
		if since >= 1.5:
			if van.global_position.distance_to(mark) < 0.4:
				await _back_off(aim)
			mark = van.global_position
			since = 0.0
		steer_for(aim, wanted)
	release()
	print("FILM kit: stopped driving at sample %d (occupied %s, %.0f s)" % [_last_index,
		van.get("occupied"), waited])
	return false


## Stuck against something: backs up a car's length, wheel turned away from where it was going.
func _back_off(aim: Vector3) -> void:
	release()
	var local := van.global_basis.inverse() * (aim - van.global_position)
	Input.action_press("brake")
	await until(func() -> bool: return absf(float(van.get("speed"))) < 0.1, 3.0)
	release()
	if int(van.get("gear")) > 0:
		await press("change_gear")
	Input.action_press("steer_right" if local.x < 0.0 else "steer_left", 1.0)
	Input.action_press("accelerate", 0.6)
	await seconds(1.6)
	release()
	Input.action_press("brake")
	await until(func() -> bool: return absf(float(van.get("speed"))) < 0.1, 3.0)
	release()
	if int(van.get("gear")) < 0:
		await press("change_gear")


## Drives through `points` in order at `speed` (a polyline off the loop road); stops at the last
## if `stop_at_end`.
func drive_points(points: Array[Vector3], speed: float, stop_at_end := true,
		limit: float = 240.0) -> bool:
	var index := 0
	var waited := 0.0
	while index < points.size() and waited < limit and bool(van.get("occupied")):
		await tree.physics_frame
		waited += 1.0 / Engine.physics_ticks_per_second
		if bool(van.get("held")) or bool(van.get("scripted")):
			release()
			continue
		var target := points[index]
		var flat := Vector2(target.x - van.global_position.x, target.z - van.global_position.z)
		var last := index == points.size() - 1
		if flat.length() < (2.0 if last else 5.0):
			index += 1
			continue
		var pace := speed
		if last and stop_at_end:
			pace = clampf(flat.length() * 0.7, 1.5, absf(speed)) * signf(speed)
		steer_for(target, pace)
	if stop_at_end:
		await stop()
	else:
		release()
	return index >= points.size()


## The right-hand lane's middle at sample `index`: LANE right of the centre line, as an American
## driver keeps right (and the oncoming van passes on the left).
func lane_point(index: int, share: float = 1.0) -> Vector3:
	var ahead := road[index + 1] - road[index]
	var right := Vector3(-ahead.z, 0.0, ahead.x).normalized()
	return road[index] + right * LANE * share


func nearest(at: Vector3, around: int, span: int) -> int:
	var best := around
	var best_distance := INF
	for offset in range(-span, span + 1):
		var index := clampi(around + offset, 0, road.size() - 1)
		var distance := road[index].distance_squared_to(at)
		if distance < best_distance:
			best_distance = distance
			best = index
	return best


func nearest_anywhere(at: Vector3) -> int:
	var best := 0
	for index in range(road.size()):
		if road[index].distance_squared_to(at) < road[best].distance_squared_to(at):
			best = index
	return best


## How much the road turns over the next `span` samples (radians).
func _bend(index: int, span: int) -> float:
	var a := mini(index, road.size() - 3)
	var b := mini(index + span, road.size() - 2)
	var first := road[a + 1] - road[a]
	var last := road[b + 1] - road[b]
	return absf(Vector2(first.x, first.z).angle_to(Vector2(last.x, last.z)))


## Walks Ethan along `points` (his own walk), and waits until he is there.
func walk(points: Array[Vector3], limit: float = 60.0) -> void:
	driver.call("walk_to", points)
	var last := points[points.size() - 1]
	await until(func() -> bool: return Vector2(driver.global_position.x - last.x,
		driver.global_position.z - last.z).length() < 0.6, limit)
	await frames(10)


## Out of the van (E), waiting until he stands.
func get_out() -> void:
	await stop()
	await press("interact")
	await until(func() -> bool: return bool(driver.get("active")) and not bool(app.get(
		"_boarding")), 12.0)


## Into the van (E by it), waiting until he sits.
func get_in() -> void:
	await press("interact")
	await until(func() -> bool: return bool(van.get("occupied")) and not bool(app.get(
		"_boarding")), 15.0)


## Drives the loop road backwards (falling samples) from where the van is until its nearest sample
## reaches `to`, keeping right (the other side of the centre line from the forward direction).
func drive_road_back(to: int, cruise: float, slowest: float = 4.5, limit: float = 600.0) -> bool:
	_last_index = nearest_anywhere(van.global_position)
	var waited := 0.0
	var mark := van.global_position
	var since := 0.0
	while waited < limit and bool(van.get("occupied")):
		await tree.physics_frame
		var step := 1.0 / Engine.physics_ticks_per_second
		waited += step
		if bool(van.get("held")) or bool(van.get("scripted")) or bool(van.get("locked")):
			release()
			continue
		_last_index = nearest(van.global_position, _last_index, 12)
		if _last_index <= to:
			release()
			print("FILM kit: reached sample %d back (wanted %d)" % [_last_index, to])
			return true
		var speed := float(van.get("speed"))
		var look := clampi(int(3 + absf(speed) * 0.55), 3, 10)
		var bend := _bend(maxi(_last_index - 18, 0), 18)
		var wanted := clampf(cruise / (1.0 + bend * 2.6), slowest, cruise)
		var ahead := maxi(_last_index - look, 1)
		var aim := lane_point(ahead - 1, -clampf(1.0 - bend * 0.9, 0.15, 1.0))
		since += step
		if since >= 1.5:
			if van.global_position.distance_to(mark) < 0.4:
				await _back_off(aim)
			mark = van.global_position
			since = 0.0
		steer_for(aim, wanted)
	release()
	print("FILM kit: stopped driving back at sample %d" % _last_index)
	return false


## Turns his view smoothly toward `direction` (as a player's mouse does).
func turn_view(direction: Vector3, rate: float = 0.12) -> void:
	var pivot := driver.get("_pivot") as Node3D
	var wanted := atan2(-direction.x, -direction.z)
	pivot.rotation.y = lerp_angle(pivot.rotation.y, wanted, rate)


## Walks Ethan through `points` with the keys (W, his view turned toward each point; shift to run
## if `run`); `fight`, if given, is called each frame and may take over (returns true while it
## does). Waits until he is at the last point.
func walk_keys(points: Array[Vector3], run := false, fight := Callable(),
		limit: float = 180.0) -> bool:
	var index := 0
	var waited := 0.0
	var mark := driver.global_position
	var since := 0.0
	while index < points.size() and waited < limit:
		await tree.physics_frame
		var step := 1.0 / Engine.physics_ticks_per_second
		waited += step
		if not bool(driver.get("active")) or bool(driver.get("held")):
			Input.action_release("accelerate")
			continue
		if fight.is_valid() and bool(fight.call()):
			Input.action_release("accelerate")
			Input.action_release("sprint")
			continue
		var target := points[index]
		var to := Vector3(target.x - driver.global_position.x, 0.0,
			target.z - driver.global_position.z)
		if to.length() < (0.5 if index == points.size() - 1 else 1.2):
			index += 1
			continue
		turn_view(to.normalized())
		Input.action_press("accelerate")
		if run:
			Input.action_press("sprint")
		since += step
		if since >= 2.0:
			if driver.global_position.distance_to(mark) < 0.3:
				var side := Vector3.UP.cross(to.normalized())
				points.insert(index, driver.global_position + side * 1.5 - to.normalized() * 0.5)
			mark = driver.global_position
			since = 0.0
	Input.action_release("accelerate")
	Input.action_release("sprint")
	await frames(6)
	return index >= points.size()


## One frame of the fight: the nearest man still standing whose head he can see within `reach`
## gets the crosshair on his head and a round every `between` seconds; true while there is one.
var _next_shot := 0.0


func fight_men(men: Array, reach: float = 32.0, between: float = 0.45) -> bool:
	var camera := driver.call("get_camera") as Camera3D
	var space := driver.get_world_3d().direct_space_state
	var best: Node3D = null
	var best_distance := reach
	for man: Node3D in men:
		if not man.is_visible_in_tree() or String(man.get("state")) == "down":
			continue
		var head := man.global_position + Vector3.UP * 1.62
		var distance := driver.global_position.distance_to(man.global_position)
		if distance > best_distance:
			continue
		var query := PhysicsRayQueryParameters3D.create(driver.global_position + Vector3.UP * 1.5,
			head, 1 | 2, [driver.get_rid()])
		if not space.intersect_ray(query).is_empty():
			continue
		best = man
		best_distance = distance
	if best == null:
		Input.action_release("aim")
		return false
	Input.action_press("aim")
	var head_point := best.global_position + Vector3.UP * 1.62
	driver.call("aim_toward", head_point)
	_next_shot -= 1.0 / Engine.physics_ticks_per_second
	if _next_shot <= 0.0 and float((driver.get("_aim_arms") as Node).get("influence")
			if driver.get("_aim_arms") != null else 0.0) > 0.9:
		_next_shot = between
		var event := InputEventAction.new()
		event.action = "fire"
		event.pressed = true
		Input.parse_input_event(event)
		var up := InputEventAction.new()
		up.action = "fire"
		up.pressed = false
		Input.parse_input_event(up)
	return true
