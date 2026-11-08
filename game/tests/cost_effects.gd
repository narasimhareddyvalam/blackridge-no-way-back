extends SceneTree
## The headless CPU price of Assignment 6's effects (CHANGE-BRIEF.md §8). The chapter's Example 09
## script is not in this repository, so this one follows the assignment's description of it. At a
## fixed rate it times the same number of frames for each case: an empty scene, the control,
## first and last; the game with every effect off; A1 at its most bursts (two); A2 at its one
## burst; B1 at its heaviest (eight lamp volumes); and B2 at full throttle. The game's cases run in
## three alternating rounds, so a slow spell on the machine shows as a spread between rounds
## instead of passing for an effect's price. Each case reports the wall time between frames; Godot's
## process and physics time monitors read the same value in every case under a script main loop,
## so they are not used. The wipers are off, so only this script fires the flicks. A headless run
## draws nothing and runs no GPU particle process, so every number is the CPU's share only. It
## changes no effect or gameplay file: it shows, hides and starts nodes in the running game.

const WARM_UP := 60
const MEASURED := 240
const ROUNDS := 3
const MOST_VOLUMES := 8
const FLICK_EVERY := 30
const SPILL_EVERY := 70
const OFF := "game, every effect off"
const CASES := [OFF, "A1, two bursts alive", "A2, one burst alive", "B1, eight lamp volumes",
	"B2, full throttle"]

var _results: Dictionary = {}
var _states: Dictionary = {}
var _app: Node3D
var _van: CharacterBody3D
var _effects: Node3D
var _rain: Node3D
var _restarted: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _control("empty scene, first (control)")
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	root.add_child(_app)
	await process_frame
	_app.call("_resume")
	_van = _app.get_node("FreightVan")
	_effects = _van.get_node("VanPresentation").get("particles")
	_rain = _app.get_node("IndustrialLoop").get("lamp_rain")
	_van.wiper_setting = 0
	Input.action_press("handbrake")
	_all_off()
	for round in range(ROUNDS):
		for label: String in CASES:
			await _case(label)
	Input.action_release("handbrake")
	_app.queue_free()
	await process_frame
	await _control("empty scene, last (control)")
	_report()


func _control(label: String) -> void:
	var empty := Node3D.new()
	root.add_child(empty)
	_record(label, await _measure(Callable()))
	empty.queue_free()


func _case(label: String) -> void:
	match label:
		OFF:
			_record(label, await _measure(Callable()))
			_states[label] = "GPU emitters emitting: %d" % _emitting()
		"A1, two bursts alive":
			_show_flicks(true)
			_record(label, await _measure(_keep_two_flicks))
			_states[label] = "bursts alive at the end: %d" % _alive(_effects.flicks, "FineSpray")
			_show_flicks(false)
		"A2, one burst alive":
			(_effects.spill as Node3D).visible = true
			_record(label, await _measure(_keep_spill))
			_states[label] = "bursts alive at the end: %d" % _alive([_effects.spill], "RoofBeads")
			(_effects.spill as Node3D).visible = false
		"B1, eight lamp volumes":
			_volumes(true)
			_record(label, await _measure(Callable()))
			_states[label] = "lamp volumes shown and raining: %d" % _raining()
			_volumes(false)
		"B2, full throttle":
			_exhaust_node().visible = true
			Input.action_press("accelerate")
			_record(label, await _measure(Callable()))
			_states[label] = "exhaust amount_ratio %.2f, emitting %s, amount %d" % [
				_effects.exhaust.amount_ratio, _effects.exhaust.emitting, _effects.exhaust.amount]
			Input.action_release("accelerate")
			_exhaust_node().visible = false


func _record(label: String, stats: Dictionary) -> void:
	if not _results.has(label):
		_results[label] = []
	_results[label].append(stats)


## Bursts restarted within their longest emitter's lifetime, counted in frames: a one-shot
## emitter turns `emitting` off once its burst is out, while its particles still live.
func _alive(bursts: Array, longest: String) -> int:
	var count := 0
	for burst: Node3D in bursts:
		var life := (burst.get_node(longest) as GPUParticles3D).lifetime
		var age: int = WARM_UP + MEASURED - 1 - int(_restarted.get(burst, -100000))
		if age < life * Engine.physics_ticks_per_second:
			count += 1
	return count


func _emitting() -> int:
	var count := 0
	for node in _app.find_children("*", "GPUParticles3D", true, false):
		if (node as GPUParticles3D).emitting and (node as GPUParticles3D).is_visible_in_tree():
			count += 1
	return count


func _raining() -> int:
	var count := 0
	for index in range(_rain.volumes.size()):
		if _rain.volumes[index].is_visible_in_tree() and _rain.rain(index).emitting:
			count += 1
	return count


func _all_off() -> void:
	_show_flicks(false)
	(_effects.spill as Node3D).visible = false
	_exhaust_node().visible = false
	_rain.visible = false


func _exhaust_node() -> Node3D:
	return _effects.exhaust.get_parent() as Node3D


func _show_flicks(shown: bool) -> void:
	for flick: Node3D in _effects.flicks:
		flick.visible = shown


func _keep_two_flicks(frame: int) -> void:
	if frame % FLICK_EVERY == 0:
		var flick: Node3D = _effects.flicks[(frame / FLICK_EVERY) % _effects.flicks.size()]
		for emitter: GPUParticles3D in [flick.get_node("BigDrops"), flick.get_node("FineSpray")]:
			emitter.restart()
		_restarted[flick] = frame


func _keep_spill(frame: int) -> void:
	if frame % SPILL_EVERY == 0:
		for name in ["RoofStreams", "RoofBeads"]:
			(_effects.spill.get_node(name) as GPUParticles3D).restart()
		_restarted[_effects.spill] = frame


func _volumes(shown: bool) -> void:
	_rain.visible = shown
	_rain.set_physics_process(not shown)
	for index in range(mini(MOST_VOLUMES, _rain.volumes.size())):
		_rain.volumes[index].visible = shown
		if shown:
			_rain.rain(index).restart()
		else:
			_rain.rain(index).emitting = false


func _measure(step: Callable) -> Dictionary:
	var walls: Array[float] = []
	var last := Time.get_ticks_usec()
	for frame in range(WARM_UP + MEASURED):
		if step.is_valid():
			step.call(frame)
		await process_frame
		var now := Time.get_ticks_usec()
		if frame >= WARM_UP:
			walls.append((now - last) / 1000.0)
		last = now
	return _stats(walls)


func _stats(values: Array[float]) -> Dictionary:
	var sorted := values.duplicate()
	sorted.sort()
	var mean := 0.0
	for value in values:
		mean += value
	mean /= values.size()
	var spread := 0.0
	for value in values:
		spread += (value - mean) * (value - mean)
	return {"mean": mean, "sd": sqrt(spread / values.size()), "max": sorted[-1],
		"p95": sorted[int(sorted.size() * 0.95)]}


func _summary(label: String) -> Dictionary:
	var means: Array[float] = []
	var sds: Array[float] = []
	var p95 := 0.0
	var worst := 0.0
	for stats: Dictionary in _results[label]:
		means.append(stats["mean"])
		sds.append(stats["sd"])
		p95 = maxf(p95, stats["p95"])
		worst = maxf(worst, stats["max"])
	var mean := 0.0
	for value in means:
		mean += value
	mean /= means.size()
	var sd := 0.0
	for value in sds:
		sd += value
	return {"mean": mean, "low": means.min(), "high": means.max(), "sd": sd / sds.size(),
		"p95": p95, "max": worst, "rounds": means.size()}


func _report() -> void:
	print("Headless CPU price: wall time between frames, %d measured after %d to warm up, at a "
		% [MEASURED, WARM_UP] + "fixed %d fps; the game's cases in %d alternating rounds"
		% [Engine.physics_ticks_per_second, ROUNDS])
	print("%-30s %8s %17s %8s %8s %8s" % ["case", "mean ms", "rounds' means", "sd", "p95",
		"max"])
	var labels := ["empty scene, first (control)"] + CASES + ["empty scene, last (control)"]
	for label: String in labels:
		var row := _summary(label)
		print("%-30s %8.3f %8.3f-%-8.3f %8.3f %8.3f %8.3f   %s" % [label, row["mean"], row["low"],
			row["high"], row["sd"], row["p95"], row["max"], _states.get(label, "")])
	var off := _summary(OFF)
	for label: String in CASES.slice(1):
		var row := _summary(label)
		var difference: float = row["mean"] - off["mean"]
		var noise := maxf(off["high"] - off["low"], row["high"] - row["low"])
		var verdict := "reads the same as every effect off"
		if difference < -noise:
			verdict = "below every effect off by more than the rounds vary: an effect cannot " \
				+ "make a frame cheaper, so this is noise between cases, not a price"
		elif difference > noise:
			verdict = "above every effect off by more than the rounds vary"
		print("%s against every effect off: %+.3f ms; the rounds vary by up to %.3f ms (%s)" % [
			label, difference, noise, verdict])
	print("The controls read %.3f and %.3f ms; the game with every effect off reads %.3f ms." % [
		_summary("empty scene, first (control)")["mean"],
		_summary("empty scene, last (control)")["mean"], off["mean"]])
	print("COST RESULT: %d cases measured" % labels.size())
	quit(0)
