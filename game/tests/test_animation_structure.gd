extends SceneTree
## Assignment 7's structure test (CHANGE-BRIEF.md §5, §1): the brief's state table asserted
## against the resources that hold the clips, every clip the code asks for present in them, and
## the one authority over each animated node, read from the sources that may write to it.
##   ring: `game/animations/phone_ring.tres`, played only by `navigation_display.gd` (play("ring")
##         and stop() on its RingPlayer), the drawn pulse gone.
##   Ethan: `ethan.glb`'s AnimationPlayer, played only by `driver.gd` and the push gait it builds
##         (`push_gait.gd`, given the player by `driver.gd` and called only through it); the app
##         asks `driver.gd` by name (`play_clip`).

const RING := "res://animations/phone_ring.tres"
const RIG := "res://features/characters/ethan/ethan.glb"
const NAVIGATION := "res://features/vehicles/freight_van/navigation_display.gd"
const ETHAN_WRITERS := ["res://features/characters/driver/driver.gd",
	"res://features/characters/driver/push_gait.gd"]
const ASKS_DRIVER := ["res://app/first_drive.gd"]
## The brief's state table (§5): each state's clip and the loop mode its resource must give it.
const RING_STATES := {"ringing": "ring", "auto": "ring", "talking": "", "missed": "", "": ""}
const ETHAN_STATES := {"on foot: idle": ["Idle", Animation.LOOP_LINEAR],
	"on foot: walking": ["Walk", Animation.LOOP_LINEAR],
	"on foot: running": ["Run", Animation.LOOP_LINEAR],
	"boarding": ["EnterVan", Animation.LOOP_NONE],
	"getting out": ["ExitVan", Animation.LOOP_NONE]}

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
	var ring := load(RING) as AnimationLibrary
	for state in RING_STATES:
		var clip: String = RING_STATES[state]
		if clip == "":
			continue
		check("S1 dash '%s' plays '%s': in %s, LOOP_LINEAR" % [state, clip, RING.get_file()],
			ring != null and ring.has_animation(clip)
			and ring.get_animation(clip).loop_mode == Animation.LOOP_LINEAR)
	var model := (load(RIG) as PackedScene).instantiate() as Node3D
	root.add_child(model)
	var player := model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	for state in ETHAN_STATES:
		var entry: Array = ETHAN_STATES[state]
		var present := player.has_animation(entry[0])
		check("S2 Ethan '%s' plays '%s' (loop mode %d)" % [state, entry[0],
			player.get_animation(entry[0]).loop_mode if present else -1], present
			and player.get_animation(entry[0]).loop_mode == entry[1])
	var navigation := _source(NAVIGATION)
	var asked := RegEx.create_from_string("ring_player\\.play\\(\"([a-z_]+)\"").search_all(
		navigation).map(func(found: RegExMatch) -> String: return found.get_string(1))
	check("S3 navigation_display.gd asks RingPlayer for exactly the clips the table names %s"
		% [asked], asked == ["ring"] and navigation.count("ring_player.stop(") == 1)
	check("S4 the drawn pulse is gone from the call card (no 'pulse', no sin(_clock))",
		not navigation.contains("pulse") and not navigation.contains("sin(_clock"))
	var missing: Array[String] = []
	var requested: Array[String] = []
	for path in ETHAN_WRITERS:
		for clip in _requests(_source(path), "play("):
			requested.append(clip)
			if not player.has_animation(clip):
				missing.append(clip)
	for path in ASKS_DRIVER:
		for clip in _requests(_source(path), "play_clip("):
			requested.append(clip)
			if not player.has_animation(clip):
				missing.append(clip)
	check("S5 every clip the code asks Ethan's player for exists in ethan.glb (asked %s; missing %s)"
		% [requested, missing], not requested.is_empty() and missing.is_empty()
		and requested.has("EnterVan"))
	var writers := _files_mentioning(["RingPlayer", "ring_player", "RingIcon", "ring_icon"])
	check("S6 one authority over the ring: only navigation_display.gd names its nodes %s" % [
		writers], writers == [NAVIGATION])
	var reached := _files_mentioning(["\"_player\"", "get(\"_player\")"])
	check("S7 nothing outside the driver reaches Ethan's AnimationPlayer by name %s" % [reached],
		reached.is_empty())
	var asks := _source(ASKS_DRIVER[0])
	check("S8 the app asks driver.gd for EnterVan and reads clip_time(), never the player",
		asks.contains("driver.play_clip(\"EnterVan\"") and asks.contains("driver.clip_time()")
		and not asks.contains("AnimationPlayer"))
	_finish()


func _source(path: String) -> String:
	return FileAccess.get_file_as_string(path)


## The clip names on the lines of `source` that call `call`: every capitalised string literal on
## such a line (a clip chosen by a condition names each choice on the line).
func _requests(source: String, call: String) -> Array[String]:
	var names: Array[String] = []
	var literal := RegEx.create_from_string("\"([A-Z][A-Za-z]+)\"")
	for line in source.split("\n"):
		if not line.contains(call) or line.strip_edges().begins_with("#"):
			continue
		for found in literal.search_all(line):
			if not names.has(found.get_string(1)):
				names.append(found.get_string(1))
	return names


## Game scripts (outside tests and tools) whose source contains any of `needles`.
func _files_mentioning(needles: Array) -> Array[String]:
	var hits: Array[String] = []
	var folders: Array[String] = ["res://"]
	while not folders.is_empty():
		var folder: String = folders.pop_back()
		var dir := DirAccess.open(folder)
		if dir == null:
			continue
		for sub in dir.get_directories():
			if not sub.begins_with(".") and sub != "tests" and sub != "addons":
				folders.append(folder.path_join(sub))
		for file in dir.get_files():
			if file.ends_with(".gd"):
				var path := folder.path_join(file)
				var text := _source(path)
				for needle in needles:
					if text.contains(needle):
						hits.append(path)
						break
	hits.sort()
	return hits


func _finish() -> void:
	print("ANIMATION STRUCTURE RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	quit(1 if _failures > 0 else 0)
