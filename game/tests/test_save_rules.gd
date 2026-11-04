extends SceneTree

const Mission = preload("res://features/missions/night_freight/first_drive.gd")
const SAVE_FILE := "res://shared/save/save_file.gd"
const PROGRESS := "user://progress.cfg"
const SETTINGS := "user://settings.cfg"
const LEGACY := "user://driving_prototype.cfg"
const BUSES: Array[String] = ["Master", "Vehicle", "Ambience", "Music"]
const NEWER := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[drive]\nstage=9\n\n" \
	+ "[cargo]\nsealed=true\n"
const NEWER_SETTINGS := "[save]\nversion=2\n\n[audio]\nMusic=0.2\n\n[video]\ngamma=1.1\n"
const DAMAGED_SETTINGS := "[save]\nversion=1\n\n[audio]\nMaster=0.8\nMusic=\"loud\"\n"
const READ_ONLY := FileAccess.UNIX_READ_OWNER | FileAccess.UNIX_EXECUTE_OWNER \
	| FileAccess.UNIX_READ_GROUP | FileAccess.UNIX_EXECUTE_GROUP \
	| FileAccess.UNIX_READ_OTHER | FileAccess.UNIX_EXECUTE_OTHER
const WRITABLE := READ_ONLY | FileAccess.UNIX_WRITE_OWNER

var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _read: Dictionary = {}
var _app: Node3D
var _van: CharacterBody3D
var _route: Node
var _hud: CanvasLayer
var _world: Node3D
var _defaults: Dictionary = {}
var _failed: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(100.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-saves-%d-%d" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(_scratch)
	if ResourceLoader.exists(SAVE_FILE):
		_read = (load(SAVE_FILE) as Script).get_script_constant_map().get("Read", {})
	for bus in BUSES:
		_defaults[bus] = _volume(bus)
	_check(_in_scratch_home(), "Godot follows HOME: user:// is this run's scratch home (%s)"
		% OS.get_user_data_dir())
	var untouched := _user_files()
	await _build("", "")
	_check_no_crack()
	await _check_saving_off(untouched)
	var after_hit := _after_hit()
	_check_missing()
	_check_corrupt()
	_check_locked()
	_check_newer()
	_check_unwritable()
	_check_settings()
	await _free_app()
	await _check_round_trip(after_hit)
	await _check_launch()
	_finish()


func _check_no_crack() -> void:
	var state: Dictionary = _van.get_node("VanPresentation").call("crack_state")
	var point: Variant = state.get("point")
	var seed: Variant = state.get("seed")
	_check(point is Vector2 and (point as Vector2).is_finite()
		and (seed is float or seed is int) and is_finite(float(seed)),
		"With no crack on the glass, the crack it would save still has a finite point and seed")


func _check_saving_off(untouched: Array[String]) -> void:
	_check(_route.checkpoint_path == "" and _hud.get("settings_path") == "",
		"A game built by a test, given no paths, has saving off for progress and settings")
	_app.call("_resume")
	_route.set_process(false)
	await physics_frame
	_reach(_route, 0)
	_hud.call("_volume_changed", 40.0, "Music")
	_app.call("_set_paused", true)
	_app.call("_set_paused", false)
	_check(_in_scratch_home() and _route.stage == 1 and _user_files() == untouched
		and _hud.get("_notice").text != "Checkpoint saved",
		"Given no paths, it plays on and writes nothing: after a checkpoint and a volume change, "
		+ "user:// is unchanged and no save is claimed")


func _check_missing() -> void:
	var trial := _trial(_scratch.path_join("missing.cfg"))
	_check(_fresh(trial) and trial.get("progress_read") == _status("MISSING")
		and DirAccess.get_files_at(_scratch).is_empty(),
		"A missing save starts a new drive, with no warning, and creates no file")
	_done(trial)


func _check_corrupt() -> void:
	var path := _scratch.path_join("progress.cfg")
	print("EXPECTED: ConfigFile parse errors for the damaged files below")
	var damaged := PackedByteArray([0, 255, 19, 7]) + "[drive\nstage==\n".to_utf8_buffer()
	_check(_set_aside(path, damaged), "Text that is not a save file: nothing in it is used, it "
		+ "is kept as progress.cfg.corrupt with the same bytes, and the game warns")
	var versions := {
		"no version": "[drive]\nstage=2\n",
		"a version in quotes": "[save]\nversion=\"1\"\nmission=\"night_freight\"\n\n"
			+ "[drive]\nstage=2\n",
		"version 1.5": "[save]\nversion=1.5\nmission=\"night_freight\"\n\n[drive]\nstage=2\n",
		"version 0": "[save]\nversion=0\nmission=\"night_freight\"\n\n[drive]\nstage=2\n",
	}
	var missed: Array[String] = []
	for name: String in versions:
		if not _set_aside(path, (versions[name] as String).to_utf8_buffer()):
			missed.append(name)
	_check(missed.is_empty(), "No version, a version that is not a whole number, or one below 1 "
		+ "makes the file damaged: nothing in it is used, and it is kept aside (failed: %s)"
		% ", ".join(missed))
	missed.clear()
	var bad := _bad_values()
	for name: String in bad:
		if not _set_aside(path, (bad[name] as ConfigFile).encode_to_text().to_utf8_buffer()):
			missed.append(name)
	_check(missed.is_empty(), "One bad value among good ones (%s): nothing from the file is "
		% ", ".join(bad.keys()) + "used, and each is kept aside (failed: %s)" % ", ".join(missed))


func _check_locked() -> void:
	var folder := _scratch.path_join("locked")
	DirAccess.make_dir_absolute(folder)
	var path := folder.path_join("progress.cfg")
	var damaged := _store(path, "[drive]\nstage=2\n".to_utf8_buffer())
	FileAccess.set_unix_permissions(folder, READ_ONLY)
	var trial := _trial(path)
	var kept: bool = _fresh(trial) and trial.get("progress_read") == _status("CORRUPT") \
		and _bytes(path) == damaged and not FileAccess.file_exists(path + ".corrupt")
	FileAccess.set_unix_permissions(folder, WRITABLE)
	var failed := _failed
	_reach(trial, 0)
	_check(kept and trial.stage == 1 and _failed == failed + 1 and _bytes(path) == damaged,
		"A damaged file that cannot be moved aside stays where it is, and saving stays off for it "
		+ "even once its folder can be written again")
	_done(trial)


func _check_newer() -> void:
	var path := _scratch.path_join("newer.cfg")
	var newer := _store(path, NEWER.to_utf8_buffer())
	var trial := _trial(path)
	var loaded_nothing: bool = _fresh(trial) and trial.get("progress_read") == _status("NEWER")
	var failed := _failed
	_reach(trial, 0)
	_check(loaded_nothing and trial.stage == 1 and _failed == failed + 1 and _bytes(path) == newer
		and not FileAccess.file_exists(path + ".corrupt")
		and not FileAccess.file_exists(path + ".tmp"),
		"A save from a newer version is not loaded, moved or written: after a checkpoint it is "
		+ "byte-for-byte the same, and the game warns")
	_done(trial)
	var later := _scratch.path_join("later.cfg")
	_good(1).save(later)
	trial = _trial(later)
	var loaded: bool = trial.stage == 1 and trial.get("progress_read") == _status("LOADED")
	newer = _store(later, NEWER.to_utf8_buffer())
	_reach(trial, 1)
	_check(loaded and trial.stage == 2 and _bytes(later) == newer,
		"A newer save that appears after loading is still never written over")
	_done(trial)


func _check_unwritable() -> void:
	var folder := _scratch.path_join("read_only")
	DirAccess.make_dir_absolute(folder)
	var path := folder.path_join("progress.cfg")
	_good(1).save(path)
	var before := _bytes(path)
	FileAccess.set_unix_permissions(folder, READ_ONLY)
	var trial := _trial(path)
	var failed := _failed
	_reach(trial, 1)
	var kept: bool = trial.stage == 2 and _failed == failed + 1 and _bytes(path) == before \
		and not FileAccess.file_exists(path + ".tmp")
	trial.call("recover")
	var target: Vector3 = Mission.TARGETS[1]
	_check(kept and _van.global_position.distance_to(target + Vector3.UP * 0.1) < 0.05,
		"In a folder that cannot be written, a checkpoint warns, the last good save stays as it "
		+ "was with no .tmp left, and the game plays on with recovery working")
	FileAccess.set_unix_permissions(folder, WRITABLE)
	_done(trial)


func _check_settings() -> void:
	var path := _scratch.path_join("settings.cfg")
	_hud.set("settings_path", path)
	var read := _load_settings()
	_check(read == _status("MISSING") and _at_defaults() and _warning() == "",
		"Missing settings give the default volumes, with no warning")
	_set_slider("Music", 37.0)
	var unsaved := not FileAccess.file_exists(path)
	_hud.call("set_menu", false)
	var saved := ConfigFile.new()
	_check(unsaved and saved.load(path) == OK and saved.get_value("save", "version", 0) == 1
		and is_equal_approx(float(saved.get_value("audio", "Music", -1.0)), 0.37)
		and not FileAccess.file_exists(path + ".tmp"),
		"A volume change is saved when the menu is left, not before: version 1, Music 0.37, "
		+ "no .tmp left")
	_set_bus("Music", _defaults["Music"])
	read = _load_settings()
	_check(read == _status("LOADED") and is_equal_approx(snappedf(_volume("Music"), 0.001), 0.37)
		and is_equal_approx(_slider("Music"), 0.37),
		"Loaded again, the settings bring Music back at 37%")
	_set_slider("Music", 52.0)
	_hud.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	saved.load(path)
	_check(is_equal_approx(float(saved.get_value("audio", "Music", -1.0)), 0.52),
		"Quitting saves the volumes too")
	var damaged := _store(path, DAMAGED_SETTINGS.to_utf8_buffer())
	read = _load_settings()
	var first: bool = read == _status("CORRUPT") and _at_defaults() \
		and _bytes(path + ".corrupt") == damaged and "Settings could not be read" in _warning()
	_store(path, "[save]\nversion=1\n\n[audio]\nMusic=1.7\n".to_utf8_buffer())
	read = _load_settings()
	_check(first and read == _status("CORRUPT") and _at_defaults(),
		"Damaged settings (a volume in words, or above 1) give the default volumes for all four, "
		+ "are kept as settings.cfg.corrupt, and the menu warns")
	var newer_path := _scratch.path_join("newer_settings.cfg")
	var newer := _store(newer_path, NEWER_SETTINGS.to_utf8_buffer())
	_hud.set("settings_path", newer_path)
	read = _load_settings()
	var untouched: bool = read == _status("NEWER") and _at_defaults() \
		and "newer version" in _warning()
	_set_slider("Music", 64.0)
	_hud.call("set_menu", false)
	_check(untouched and _bytes(newer_path) == newer
		and not FileAccess.file_exists(newer_path + ".corrupt"),
		"Settings from a newer version give the default volumes and are never written, even "
		+ "after a change and leaving the menu")
	var folder := _scratch.path_join("read_only_settings")
	DirAccess.make_dir_absolute(folder)
	var locked := folder.path_join("settings.cfg")
	var kept := _store(locked, "[save]\nversion=1\n\n[audio]\nMusic=0.5\n".to_utf8_buffer())
	FileAccess.set_unix_permissions(folder, READ_ONLY)
	_hud.set("settings_path", locked)
	read = _load_settings()
	var loaded: bool = read == _status("LOADED") and is_equal_approx(_slider("Music"), 0.5)
	_set_slider("Music", 60.0)
	_hud.call("set_menu", false)
	_check(loaded and _bytes(locked) == kept and not FileAccess.file_exists(locked + ".tmp")
		and is_equal_approx(snappedf(_volume("Music"), 0.001), 0.6)
		and _hud.get("_notice").text.contains("could not be saved"),
		"Settings that cannot be written: a notice warns, the old file stays as it was, and the "
		+ "new volume holds for the session")
	FileAccess.set_unix_permissions(folder, WRITABLE)


func _check_round_trip(config: ConfigFile) -> void:
	var path := _scratch.path_join("round_trip.cfg")
	config.save(path)
	await _build(path, "")
	_app.call("_begin")
	await physics_frame
	_check(_matches(config), "Continuing from a save made after the hit restores the checkpoint, "
		+ "the van's place, where he lies and the crack")
	_route.call("_save_checkpoint", false)
	var written := ConfigFile.new()
	_check(written.load(path) == OK and written.get_value("save", "version", 0) == 1
		and written.get_value("save", "mission", "") == "night_freight"
		and not FileAccess.file_exists(path + ".tmp"),
		"The game saves it again as version 1 with the mission's name, leaving no .tmp")
	await _free_app()
	await _build(path, "")
	_app.call("_begin")
	await physics_frame
	_check(_matches(config), "Quit and load again: the same mission, checkpoint, van place, body "
		+ "and crack")
	await _free_app()


func _check_launch() -> void:
	if not _in_scratch_home():
		_check(false, "Launched as the game it uses user:// (skipped outside scripts/run-test.sh's "
			+ "scratch home, so the real save folder is never touched)")
		return
	_clear_user()
	print("EXPECTED: a ConfigFile parse error for the damaged user://progress.cfg")
	var damaged := _store(PROGRESS, PackedByteArray([0, 255]) + "[drive\n".to_utf8_buffer())
	var damaged_settings := _store(SETTINGS, DAMAGED_SETTINGS.to_utf8_buffer())
	var legacy := _store(LEGACY, "[drive]\nstage=3\n".to_utf8_buffer())
	await _launch()
	var home := OS.get_environment("HOME") + "/"
	_check(_route.checkpoint_path == PROGRESS and _hud.get("settings_path") == SETTINGS
		and ProjectSettings.globalize_path(PROGRESS).begins_with(home)
		and ProjectSettings.globalize_path(SETTINGS).begins_with(home),
		"Launched as the game, it uses user://progress.cfg and user://settings.cfg, here inside "
		+ "the scratch home")
	var warning := _warning()
	_check(_route.stage == 0 and _at_defaults() and _bytes(PROGRESS + ".corrupt") == damaged
		and _bytes(SETTINGS + ".corrupt") == damaged_settings and _bytes(LEGACY) == legacy
		and "Saved progress could not be read" in warning
		and "Settings could not be read" in warning,
		"With both files damaged, the menu warns about each, both are kept as .corrupt, a new "
		+ "drive starts at the default volumes, and the prototype's old save is neither read "
		+ "nor deleted")
	_route.call("_save_checkpoint")
	_set_slider("Music", 45.0)
	_app.call("_set_paused", false)
	var progress := ConfigFile.new()
	var settings := ConfigFile.new()
	_check(progress.load(PROGRESS) == OK and progress.get_value("save", "version", 0) == 1
		and settings.load(SETTINGS) == OK
		and is_equal_approx(float(settings.get_value("audio", "Music", -1.0)), 0.45)
		and not FileAccess.file_exists(PROGRESS + ".tmp")
		and not FileAccess.file_exists(SETTINGS + ".tmp"),
		"Its next checkpoint and leaving the menu write both files there, with no .tmp left")
	await _quit_launch()
	_clear_user()
	var newer := _store(PROGRESS, NEWER.to_utf8_buffer())
	var newer_settings := _store(SETTINGS, NEWER_SETTINGS.to_utf8_buffer())
	await _launch()
	warning = _warning()
	var fresh: bool = _route.stage == 0 and _at_defaults()
	_route.call("_save_checkpoint")
	_set_slider("Music", 45.0)
	_app.call("_set_paused", false)
	_check(fresh and _bytes(PROGRESS) == newer and _bytes(SETTINGS) == newer_settings
		and "newer version" in warning and not FileAccess.file_exists(PROGRESS + ".corrupt"),
		"With both files from a newer version, the menu warns, a new drive starts at the default "
		+ "volumes, and neither file is changed by a checkpoint or by leaving the menu")
	await _quit_launch()
	_clear_user()


func _bad_values() -> Dictionary:
	var cases := {}
	var at_nan := _after_hit()
	var body: Array = at_nan.get_value("drive", "body")
	body[4] = Transform3D(Basis(), Vector3(NAN, 33.0, -80.0))
	at_nan.set_value("drive", "body", body)
	cases["a body part at NaN"] = at_nan
	var short := _after_hit()
	short.set_value("drive", "body", (short.get_value("drive", "body") as Array).slice(0, 10))
	cases["10 body parts"] = short
	var squashed := _after_hit()
	var parts: Array = squashed.get_value("drive", "body")
	var flat_basis := Basis.from_scale(Vector3(1.0, 0.0, 1.0))
	parts[2] = Transform3D(flat_basis, (parts[2] as Transform3D).origin)
	squashed.set_value("drive", "body", parts)
	cases["a squashed body part"] = squashed
	var outside := _after_hit()
	outside.set_value("drive", "recovery", Transform3D(Basis(), Vector3(5000.0, 30.0, 0.0)))
	cases["the van outside the playable area"] = outside
	var cracked := _after_hit()
	cracked.set_value("drive", "crack", {"amount": 1.5, "point": Vector2(0.1, -0.3), "seed": 4.0})
	cases["a crack of 1.5"] = cracked
	var mission := _after_hit()
	mission.set_value("save", "mission", "harbour_run")
	cases["an unknown mission"] = mission
	cases["checkpoint 7"] = _good(7)
	cases["after-the-hit data at checkpoint 1"] = _after_hit(1)
	var half := _after_hit()
	half.erase_section_key("drive", "crack")
	cases["half of the after-the-hit data"] = half
	return cases


func _good(stage: int) -> ConfigFile:
	var config := ConfigFile.new()
	config.set_value("save", "version", 1)
	config.set_value("save", "mission", "night_freight")
	config.set_value("drive", "stage", stage)
	return config


func _after_hit(stage: int = 3) -> ConfigFile:
	var config := _good(stage)
	var crossing: Node3D = _world.get("crossing")
	var kerb: Vector3 = crossing.get("kerb")
	var across: Vector3 = crossing.get("right")
	config.set_value("drive", "recovery",
		Transform3D(Basis(Vector3.UP, 1.6), kerb - across * 7.0 + Vector3.UP * 0.1))
	var body: Array[Transform3D] = []
	for part in range(Mission.Pedestrian.BONES.size()):
		body.append(Transform3D(Basis(Vector3.RIGHT, PI / 2.0),
			kerb - across * (2.0 + 0.16 * part) + Vector3.UP * 0.15))
	config.set_value("drive", "body", body)
	config.set_value("drive", "crack", {"amount": 0.8, "point": Vector2(0.12, -0.31),
		"seed": 41.5})
	return config


func _matches(config: ConfigFile) -> bool:
	var pedestrian: Variant = _route.get("pedestrian")
	if _route.stage != config.get_value("drive", "stage", -1) or not _route.fleeing \
			or not is_instance_valid(pedestrian):
		return false
	var place: Transform3D = config.get_value("drive", "recovery")
	var flat := Vector2(_van.global_position.x, _van.global_position.z)
	if not _near(_route.recovery_pose, place) \
			or flat.distance_to(Vector2(place.origin.x, place.origin.z)) > 0.2:
		return false
	var pose: Array = (pedestrian as Node).call("lying_pose")
	var body: Array = config.get_value("drive", "body")
	for index in range(body.size()):
		if not _near(pose[index], body[index]):
			return false
	var crack: Dictionary = config.get_value("drive", "crack")
	var state: Dictionary = _van.get_node("VanPresentation").call("crack_state")
	return state.get("point") is Vector2 \
		and is_equal_approx(float(state.get("amount", -1.0)), float(crack["amount"])) \
		and (state["point"] as Vector2).is_equal_approx(crack["point"]) \
		and is_equal_approx(float(state.get("seed", -1.0)), float(crack["seed"]))


func _near(a: Transform3D, b: Transform3D) -> bool:
	return a.origin.distance_to(b.origin) < 0.001 and a.basis.x.distance_to(b.basis.x) < 0.001 \
		and a.basis.y.distance_to(b.basis.y) < 0.001 and a.basis.z.distance_to(b.basis.z) < 0.001


func _trial(path: String) -> Node:
	var trial: Node = Mission.new()
	trial.checkpoint_path = path
	trial.set("playable_area", _world.get("playable_area"))
	trial.crossing = _world.get("crossing")
	trial.checkpoint_save_failed.connect(func(_error: int) -> void: _failed += 1)
	root.add_child(trial)
	trial.set_process(false)
	trial.configure(_van)
	return trial


func _fresh(trial: Node) -> bool:
	var state: Dictionary = _van.get_node("VanPresentation").call("crack_state")
	return trial.stage == 0 and not trial.fleeing and not is_instance_valid(trial.pedestrian) \
		and is_zero_approx(float(state.get("amount", 0.0)))


func _done(trial: Node) -> void:
	trial.queue_free()
	_van.get_node("VanPresentation").call("clear_crack")


func _set_aside(path: String, bytes: PackedByteArray) -> bool:
	_store(path, bytes)
	var trial := _trial(path)
	var fine: bool = _fresh(trial) and trial.get("progress_read") == _status("CORRUPT") \
		and not FileAccess.file_exists(path) and _bytes(path + ".corrupt") == bytes \
		and not FileAccess.file_exists(path + ".tmp")
	_done(trial)
	return fine


func _reach(mission: Node, index: int) -> void:
	var target: Vector3 = Mission.TARGETS[index]
	_van.recover(Transform3D(Basis(Vector3.UP, Mission.HEADINGS[index]),
		target + Vector3.UP * 0.1))
	mission.call("_process", 0.2)


func _status(name: String) -> int:
	return int(_read.get(name, -100))


func _load_settings() -> int:
	return int(_hud.call("load_settings")) if _hud.has_method("load_settings") else -1


func _warning() -> String:
	return str(_hud.call("warning")) if _hud.has_method("warning") else "(no warning on the HUD)"


func _set_slider(bus: String, percent: float) -> void:
	var sliders: Variant = _hud.get("_sliders")
	if sliders is Dictionary and (sliders as Dictionary).has(bus):
		(sliders[bus] as HSlider).value = percent
	else:
		_hud.call("_volume_changed", percent, bus)


func _slider(bus: String) -> float:
	var sliders: Variant = _hud.get("_sliders")
	if not sliders is Dictionary or not (sliders as Dictionary).has(bus):
		return -1.0
	return float((sliders[bus] as HSlider).value) / 100.0


func _volume(bus: String) -> float:
	var index := AudioServer.get_bus_index(bus)
	if AudioServer.is_bus_mute(index):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(index))


func _set_bus(bus: String, volume: float) -> void:
	var index := AudioServer.get_bus_index(bus)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(index, volume <= 0.0)


func _at_defaults() -> bool:
	for bus in BUSES:
		if absf(_volume(bus) - float(_defaults[bus])) > 0.005 \
				or absf(_slider(bus) - float(_defaults[bus])) > 0.005:
			return false
	return true


func _build(progress: String, settings: String) -> void:
	for bus in BUSES:
		_set_bus(bus, _defaults[bus])
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_route = _app.get_node("DrivingTrial")
	_hud = _app.get_node("DrivingHud")
	if not progress.is_empty():
		_route.checkpoint_path = progress
	if not settings.is_empty():
		_hud.set("settings_path", settings)
	root.add_child(_app)
	_van = _app.get_node("FreightVan")
	_world = _app.get_node("IndustrialLoop")
	await process_frame


func _free_app() -> void:
	_app.queue_free()
	await process_frame
	await process_frame


func _launch() -> void:
	for bus in BUSES:
		_set_bus(bus, _defaults[bus])
	change_scene_to_packed(load("res://app/first_drive.tscn") as PackedScene)
	await process_frame
	await process_frame
	_app = current_scene
	_route = _app.get_node("DrivingTrial")
	_hud = _app.get_node("DrivingHud")
	_van = _app.get_node("FreightVan")
	_world = _app.get_node("IndustrialLoop")


func _quit_launch() -> void:
	unload_current_scene()
	await process_frame
	await process_frame


func _in_scratch_home() -> bool:
	var home := OS.get_environment("HOME")
	return home.ends_with("/.scratch-home") and OS.get_user_data_dir().begins_with(home + "/")


func _user_files() -> Array[String]:
	var found: Array[String] = []
	if _in_scratch_home():
		_list("user://", found)
	found.sort()
	return found


func _list(folder: String, found: Array[String]) -> void:
	for file in DirAccess.get_files_at(folder):
		var path := folder.path_join(file)
		found.append("%s %s %d" % [path, FileAccess.get_md5(path),
			FileAccess.get_modified_time(path)])
	for directory in DirAccess.get_directories_at(folder):
		if folder != "user://" or directory != "logs":
			_list(folder.path_join(directory), found)


func _clear_user() -> void:
	for path in [PROGRESS, SETTINGS, LEGACY]:
		for suffix in ["", ".corrupt", ".tmp"]:
			if FileAccess.file_exists(path + suffix):
				DirAccess.remove_absolute(path + suffix)


func _store(path: String, bytes: PackedByteArray) -> PackedByteArray:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(bytes)
	file.close()
	return bytes


func _bytes(path: String) -> PackedByteArray:
	if not FileAccess.file_exists(path):
		return PackedByteArray()
	return FileAccess.get_file_as_bytes(path)


func _remove(path: String) -> void:
	FileAccess.set_unix_permissions(path, WRITABLE)
	for file in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file))
	for directory in DirAccess.get_directories_at(path):
		_remove(path.path_join(directory))
	DirAccess.remove_absolute(path)


func _finish() -> void:
	_remove(_scratch)
	print("SAVE RULES RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "Save rules test finished within 100 s")
	quit(1)
