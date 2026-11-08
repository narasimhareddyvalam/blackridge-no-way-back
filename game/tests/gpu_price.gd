extends SceneTree
## The GPU price of Assignment 6's effects (CHANGE-BRIEF.md §8), for a windowed run on macOS with
## Apple's Metal Performance HUD logging each frame's GPU time to stderr (MTL_HUD_ENABLED=1 and
## MTL_HUD_LOG_ENABLED=1). Godot's own GPU timer reads 0 on Metal, so this script only sets each
## state and prints when it held; tools/tests/gpu_price.py pairs those times with the HUD's frames.
## Each effect runs at its heaviest, in a view where it is on screen, since Godot runs no GPU
## particles whose visibility box is off screen: A1 with two bursts alive, each with its passenger
## water, and one spill's water, and A2 with one burst, from the driver's seat; B1 with the eight
## lamp volumes nearest the B1 strip's view of the valley lamp; B2 at full throttle, from behind
## the van. The GPU's time for the same frame drifts by several milliseconds over a minute, so each
## effect is shown and hidden in alternating blocks while it keeps running, and its price is the
## difference between neighbouring blocks. Showing B2 restarts its 0.6 s ramp, so its blocks are
## longer. The window is brought to the front at every block, since the HUD logs only while it is
## in front. `-- --only=A1,A2 --cycles=40` measures some effects, with more cycles. It changes no
## effect or gameplay file: it shows, hides and starts nodes in the game.

const SETTLE := 2.0
const CYCLES := 24
const SKIP := 0.3
const BURST := ["WaterSheet", "BigDrops", "HeavyDrops", "FineSpray", "PillarRunoff"]
const FLICK_EVERY := 0.6
const SPILL_EVERY := 1.3
const MOST_VOLUMES := 8
const TAILPIPE := Vector3(-0.6, 0.46, 2.85)
const VALLEY_LAMP := Vector2(-15.0, 63.8)
const VALLEY_VIEW := [Vector3(15.0, -4.7, 3.6), Vector3(0.0, -3.6, 0.3), 40.0]
## Each effect's view, how long each shown or hidden block lasts, and how much of its start is left
## out, in seconds.
const EFFECTS := {
	"A1": ["the driver's seat", 1.0, SKIP],
	"A2": ["the driver's seat", 1.0, SKIP],
	"B1": ["the valley lamp", 1.0, SKIP],
	"B2": ["behind the van", 2.0, 0.8],
}

var _app: Node3D
var _van: CharacterBody3D
var _effects: Node3D
var _rain: Node3D
var _cab: Camera3D
var _rear: Camera3D
var _valley: Camera3D
var _step := Callable()
var _cycles := CYCLES
var _last_step := -1000000.0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	root.add_child(_app)
	await process_frame
	_app.call("_resume")
	_van = _app.get_node("FreightVan")
	_effects = _van.get_node("VanPresentation").get("particles")
	_rain = _app.get_node("IndustrialLoop").get("lamp_rain")
	_van.wiper_setting = 0
	Input.action_press("handbrake")
	_cab = root.get_camera_3d()
	_rear = Camera3D.new()
	_rear.name = "GpuPriceRear"
	root.add_child(_rear)
	_valley = Camera3D.new()
	_valley.name = "GpuPriceValley"
	_valley.fov = VALLEY_VIEW[2]
	_valley.cull_mask = (_app.get("title_camera") as Camera3D).cull_mask
	root.add_child(_valley)
	var lamp := _valley_volume().global_position
	_valley.look_at_from_position(lamp + VALLEY_VIEW[0], lamp + VALLEY_VIEW[1], Vector3.UP)
	_show_flicks(false)
	(_effects.spill as Node3D).visible = false
	_exhaust_node().visible = false
	_rain.visible = false
	await _wait(3.0)
	print("GPU PRICE: window %s, vsync %s, MetalFX scale %.2f" % [root.get_visible_rect().size,
		DisplayServer.window_get_vsync_mode(), root.scaling_3d_scale])
	var chosen: Array = EFFECTS.keys()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			chosen = arg.trim_prefix("--only=").split(",")
		elif arg.begins_with("--cycles="):
			_cycles = int(arg.trim_prefix("--cycles="))
	for effect: String in chosen:
		await _alternate(effect)
	Input.action_release("handbrake")
	print("GPU PRICE DONE")
	quit()


func _alternate(effect: String) -> void:
	var view: String = EFFECTS[effect][0]
	var block: float = EFFECTS[effect][1]
	var skip: float = EFFECTS[effect][2]
	_view(view)
	var particles := _start(effect)
	await _wait(SETTLE)
	for cycle in range(_cycles):
		for shown: bool in [true, false]:
			DisplayServer.window_move_to_foreground()
			_show(effect, shown)
			var began := Time.get_unix_time_from_system()
			await _wait(block)
			var ended := Time.get_unix_time_from_system()
			print("GPU PRICE BLOCK|%s|%s|cycle %d|time %.3f-%.3f|skip %.2f|particles %d|%s|%s"
				% [effect, "on" if shown else "off", cycle + 1, began, ended, skip, particles,
				view, _state(effect)])
	_stop(effect)
	await _wait(0.5)


## Starts the effect running, hidden, and returns the particles it then holds at most.
func _start(effect: String) -> int:
	match effect:
		"A1":
			_step = _keep_two_flicks
			return 2 * _amounts(_effects.flicks[0], BURST + ["PassengerWater", "PassengerLine"]) \
				+ _amounts(_effects.flicks[0], ["SpillWater"])
		"A2":
			_step = _keep_spill
			return _amounts(_effects.spill, ["WaterWash", "RoofStreams", "RoofBeads", "Rivulets"])
		"B1":
			var total := _volumes(true, _valley.global_position)
			_rain.visible = false
			return total
		"B2":
			Input.action_press("accelerate")
			return _effects.exhaust.amount
	return 0


func _show(effect: String, shown: bool) -> void:
	match effect:
		"A1":
			_show_flicks(shown)
		"A2":
			(_effects.spill as Node3D).visible = shown
		"B1":
			_rain.visible = shown
		"B2":
			_exhaust_node().visible = shown


func _stop(effect: String) -> void:
	_step = Callable()
	_show(effect, false)
	if effect == "B1":
		_volumes(false)
	if effect == "B2":
		Input.action_release("accelerate")


func _wait(seconds: float) -> void:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < seconds * 1000.0:
		if _step.is_valid():
			_last_step = _step.call(Time.get_ticks_msec(), _last_step)
		if _rear.current:
			_rear.global_transform = _behind()
		await process_frame


func _view(view: String) -> void:
	match view:
		"behind the van":
			_rear.global_transform = _behind()
			_rear.make_current()
		"the valley lamp":
			_valley.make_current()
		_:
			_cab.make_current()


func _behind() -> Transform3D:
	var from: Vector3 = _van.global_transform * Vector3(-0.6, 1.6, 7.5)
	var at: Vector3 = _van.global_transform * (TAILPIPE + Vector3(0.0, 0.1, 0.0))
	return Transform3D(Basis(), from).looking_at(at, Vector3.UP)


func _state(effect: String) -> String:
	match effect:
		"A1":
			return "flicks visible %d" % _effects.flicks.filter(func(f): return f.visible).size()
		"B1":
			return "volumes raining %d, in view %d" % [_raining(), _in_view()]
		"B2":
			return "exhaust amount_ratio %.2f" % _effects.exhaust.amount_ratio
	return ""


func _amounts(burst: Node3D, names: Array) -> int:
	var total := 0
	for name: String in names:
		total += (burst.get_node(name) as GPUParticles3D).amount
	return total


func _exhaust_node() -> Node3D:
	return _effects.exhaust.get_parent() as Node3D


func _show_flicks(shown: bool) -> void:
	for flick: Node3D in _effects.flicks:
		flick.visible = shown


## Both bursts kept alive at the blade tip, as the wipers' top turns place them, one every 0.6 s,
## so each is restarted within its 1.2 s life; the first also throws one spill's water.
func _keep_two_flicks(now: int, last: float) -> float:
	if now - last < FLICK_EVERY * 1000.0:
		return last
	var index: int = int(now / (FLICK_EVERY * 1000.0)) % _effects.flicks.size()
	var flick: Node3D = _effects.flicks[index]
	flick.global_position = _effects.tip()
	var names: Array = BURST + (["SpillWater"] if index == 0 else [])
	for name: String in names:
		(flick.get_node(name) as GPUParticles3D).restart()
	var water := flick.get_node("PassengerWater") as GPUParticles3D
	var line := flick.get_node("PassengerLine") as GPUParticles3D
	water.global_transform = _effects.passenger_water_at()
	line.global_transform = _effects.passenger_water_at(true)
	water.restart()
	line.restart()
	return float(now)


func _keep_spill(now: int, last: float) -> float:
	if now - last < SPILL_EVERY * 1000.0:
		return last
	for name in ["WaterWash", "RoofStreams", "RoofBeads", "Rivulets"]:
		(_effects.spill.get_node(name) as GPUParticles3D).restart()
	return float(now)


## Shows, restarts and counts the eight volumes nearest `near`, the controller paused; or stops
## every volume and gives the controller back.
func _volumes(shown: bool, near := Vector3.INF) -> int:
	var total := 0
	_rain.visible = shown
	_rain.set_physics_process(not shown)
	var order: Array = range(_rain.volumes.size())
	if near != Vector3.INF:
		var distance := {}
		for index: int in order:
			distance[index] = _rain.volumes[index].global_position.distance_to(near)
		order.sort_custom(func(a: int, b: int) -> bool: return distance[a] < distance[b])
	for index: int in (order.slice(0, MOST_VOLUMES) if shown else order):
		_rain.volumes[index].visible = shown
		if shown:
			_rain.rain(index).restart()
			total += _rain.rain(index).amount
			var splash: Node = _rain.rain(index).get_node_or_null(_rain.rain(index).sub_emitter)
			if splash is GPUParticles3D:
				total += (splash as GPUParticles3D).amount
		else:
			_rain.rain(index).emitting = false
	return total


func _raining() -> int:
	var count := 0
	for index in range(_rain.volumes.size()):
		if _rain.volumes[index].is_visible_in_tree() and _rain.rain(index).emitting:
			count += 1
	return count


func _in_view() -> int:
	var count := 0
	var camera := root.get_camera_3d()
	for index in range(_rain.volumes.size()):
		var at: Vector3 = _rain.volumes[index].global_position
		if _rain.volumes[index].visible and (camera.is_position_in_frustum(at)
				or camera.is_position_in_frustum(at + Vector3(0.0, -4.0, 0.0))):
			count += 1
	return count


func _valley_volume() -> Node3D:
	var best: Node3D = null
	var best_distance := INF
	for volume: Node3D in _rain.volumes:
		var flat := Vector2(volume.global_position.x, volume.global_position.z)
		if flat.distance_to(VALLEY_LAMP) < best_distance:
			best_distance = flat.distance_to(VALLEY_LAMP)
			best = volume
	return best
