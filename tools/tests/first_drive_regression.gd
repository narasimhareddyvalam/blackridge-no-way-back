extends SceneTree

const Trial = preload("res://features/missions/night_freight/first_drive.gd")

var _failures: int = 0
var _checks: int = 0
var _app: Node3D
var _van: CharacterBody3D
var _route: Node
var _scratch: String
var _saved: int = 0
var _failed: int = 0
var _last_save_error: int = OK


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(30.0).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-regression-%d-%d" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	var result := DirAccess.make_dir_recursive_absolute(_scratch)
	if result != OK:
		_check(false, "Create isolated test directory")
		quit(1)
		return
	var scene := load("res://app/first_drive.tscn") as PackedScene
	_app = scene.instantiate()
	_route = _app.get_node("DrivingTrial")
	_route.checkpoint_path = _scratch.path_join("checkpoint.cfg")
	root.add_child(_app)
	await process_frame
	_app.call("_resume")
	_route.set_process(false)
	_van = _app.get_node("FreightVan")
	_route.checkpoint_saved.connect(func() -> void: _saved += 1)
	_route.checkpoint_save_failed.connect(_save_failed)
	await create_timer(0.25).timeout
	await _test_steering()
	_test_audio_loops()
	_test_checkpoint_success()
	_test_checkpoint_failure()
	_test_checkpoint_reload()
	await _test_exit_and_collision()
	_app.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	_remove_fixture_tree(_scratch)
	print("REGRESSION RESULT: %d/%d passed; %d failed" % [
		_checks - _failures, _checks, _failures])
	quit(0 if _failures == 0 else 1)


func _test_steering() -> void:
	var collision: CollisionShape3D = _van.get_node("CollisionShape3D")
	_check(collision.shape.size == Vector3(2.4, 2.8, 5.3),
		"Physical vehicle collision dimensions are preserved")
	_check(not _van.call("_rotation_blocked", 0.16),
		"Ground contact permits a left turn")
	_check(not _van.call("_rotation_blocked", -0.16),
		"Ground contact permits a right turn")
	var wall := _obstruction(_van.to_global(Vector3(-1.42, 1.6, -2)),
		Vector3(0.1, 2.7, 0.3), _van.global_basis)
	await physics_frame
	await physics_frame
	_check(_van.call("_rotation_blocked", 0.16),
		"Turning into an adjacent obstacle is rejected")
	_check(not _van.call("_rotation_blocked", -0.16),
		"Turning away from the adjacent obstacle remains possible")
	wall.queue_free()
	await physics_frame
	await physics_frame
	var start := _van.global_position
	Input.action_press("accelerate")
	await create_timer(1.4).timeout
	_check(_van.speed > 3 and _van.global_position.distance_to(start) > 2,
		"Throttle produces forward travel")
	_check(_van.actual_speed > 3, "Measured speed reports forward motion")
	var heading := _van.rotation.y
	Input.action_press("steer_left")
	await create_timer(0.7).timeout
	Input.action_release("steer_left")
	Input.action_release("accelerate")
	_check(angle_difference(heading, _van.rotation.y) > 0.06,
		"Left steering changes heading during actual physics movement")
	Input.action_press("brake")
	await create_timer(1).timeout
	Input.action_release("brake")
	_check(absf(_van.speed) < 0.05, "Service brake stops the turning van")
	_app.call("_recover")
	_check(is_zero_approx(_van.actual_speed), "Recovery immediately resets measured speed")
	await physics_frame
	await physics_frame
	_van.gear = -1
	Input.action_press("accelerate")
	await create_timer(0.7).timeout
	Input.action_release("accelerate")
	_check(_van.actual_speed < -1, "Measured speed reports reverse motion")
	Input.action_press("brake")
	await create_timer(0.5).timeout
	Input.action_release("brake")
	_app.call("_recover")
	await physics_frame
	await physics_frame


func _test_audio_loops() -> void:
	var audio: Node = _app.get("_audio")
	for key in ["_engine", "_rain", "_cabin_rain", "_tires", "_wind", "_horn", "_music"]:
		var player: AudioStreamPlayer = audio.get(key)
		var stream := player.stream as AudioStreamWAV
		var file := String(key).trim_prefix("_")
		var original := load("res://features/audio/first_drive/" + file + ".wav")
		var frames := _source_wav_frames("res://features/audio/first_drive/" + file + ".wav")
		_check(frames > 0 and stream.loop_end == frames,
			key + " loop reaches the source WAV's complete frame count")
		_check(stream.loop_begin == 0 and stream.loop_mode == AudioStreamWAV.LOOP_FORWARD,
			key + " loops forward from the beginning")
		_check(original == null or original != stream,
			key + " playback owns a separate stream resource")
	for key in ["_click", "_wiper", "_window", "_collision"]:
		var player: AudioStreamPlayer = audio.get(key)
		_check(player.stream.loop_mode == AudioStreamWAV.LOOP_DISABLED,
			key + " remains a one-shot effect")


func _source_wav_frames(path: String) -> int:
	var source := FileAccess.open(path, FileAccess.READ)
	if source == null or source.get_buffer(4).get_string_from_ascii() != "RIFF":
		return -1
	source.get_32()
	if source.get_buffer(4).get_string_from_ascii() != "WAVE":
		return -1
	var alignment: int = 0
	var sample_bytes: int = 0
	while source.get_position() + 8 <= source.get_length():
		var chunk := source.get_buffer(4).get_string_from_ascii()
		var size := source.get_32()
		var start := source.get_position()
		if chunk == "fmt " and size >= 16:
			source.seek(start + 12)
			alignment = source.get_16()
		elif chunk == "data":
			sample_bytes = size
		source.seek(start + size + size % 2)
	return sample_bytes / alignment if alignment > 0 else -1


func _test_checkpoint_success() -> void:
	var target: Vector3 = Trial.TARGETS[0]
	_van.recover(Transform3D(Basis(Vector3.UP, Trial.HEADINGS[0]), target + Vector3.UP * 0.1))
	var previous_saved := _saved
	_route.call("_process", 0.2)
	_check(_route.stage == 1, "First landmark advances route state")
	_check(_saved == previous_saved + 1 and _failed == 0,
		"Successful checkpoint emits only a saved result")
	var config := ConfigFile.new()
	var result := config.load(_route.checkpoint_path)
	_check(result == OK and config.get_value("drive", "stage", -1) == 1,
		"Successful checkpoint is readable from disk")
	_check(not FileAccess.file_exists(_route.checkpoint_path + ".tmp"),
		"Successful replacement leaves no temporary save file")
	_check(_app.get("hud").get("_notice").text == "Checkpoint saved",
		"HUD reports successful disk write")


func _test_checkpoint_failure() -> void:
	var path: String = _route.checkpoint_path
	var temporary := path + ".tmp"
	DirAccess.make_dir_absolute(temporary)
	var previous_saved := _saved
	var previous_failed := _failed
	var target: Vector3 = Trial.TARGETS[1]
	_van.recover(Transform3D(Basis(Vector3.UP, Trial.HEADINGS[1]), target + Vector3.UP * 0.1))
	print("EXPECTED FAILURE: temporary save path is an existing test directory")
	_route.call("_process", 0.2)
	_check(_route.stage == 2, "Save failure keeps current route progress in memory")
	_check(_saved == previous_saved and _failed == previous_failed + 1,
		"Failed write emits failure and never emits saved")
	_check(_last_save_error != OK, "Save failure carries an error code")
	var original := ConfigFile.new()
	_check(original.load(path) == OK and original.get_value("drive", "stage", -1) == 1,
		"Failed write preserves the previous checkpoint")
	_check(_app.get("hud").get("_notice").text.contains("could not be saved"),
		"HUD reports failure rather than claiming a save")
	var expected: Transform3D = _route.recovery_pose
	_route.call("recover")
	_check(_van.global_transform.is_equal_approx(expected) and is_zero_approx(_van.speed),
		"In-session recovery still works after failed saving")
	DirAccess.remove_absolute(temporary)
	_check(_route.call("_save_checkpoint") == OK,
		"Checkpoint saving resumes after the obstruction is removed")
	_check(original.load(path) == OK and original.get_value("drive", "stage", -1) == 2,
		"A successful replacement updates an existing checkpoint")
	var blocked_path := _scratch.path_join("directory_target")
	DirAccess.make_dir_absolute(blocked_path)
	_route.checkpoint_path = blocked_path
	previous_saved = _saved
	previous_failed = _failed
	print("EXPECTED FAILURE: final save target is an existing test directory")
	var result: Error = _route.call("_save_checkpoint")
	_check(result != OK and _saved == previous_saved and _failed == previous_failed + 1,
		"Failed final replacement reports failure without saved success")
	_check(not FileAccess.file_exists(blocked_path + ".tmp"),
		"Failed replacement removes its incomplete temporary file")
	_check(DirAccess.dir_exists_absolute(blocked_path),
		"Failed replacement preserves the obstructing directory")
	_route.checkpoint_path = path


func _test_checkpoint_reload() -> void:
	var restored := Trial.new()
	restored.checkpoint_path = _route.checkpoint_path
	root.add_child(restored)
	restored.set_process(false)
	restored.configure(_van)
	_check(restored.stage == 2, "A fresh route instance reloads the saved stage")
	var expected := Transform3D(Basis(Vector3.UP, Trial.HEADINGS[1]),
		Trial.TARGETS[1] + Vector3.UP * 0.1)
	_check(_van.global_transform.is_equal_approx(expected),
		"Reload restores the authored safe recovery pose")
	restored.queue_free()
	for invalid: Variant in [-1, 99, "two", 2.5]:
		var bad := ConfigFile.new()
		bad.set_value("drive", "stage", invalid)
		var bad_path := _scratch.path_join("invalid.cfg")
		bad.save(bad_path)
		var trial := Trial.new()
		trial.checkpoint_path = bad_path
		root.add_child(trial)
		trial.set_process(false)
		trial.configure(_van)
		_check(trial.stage == 0, "Invalid checkpoint stage %s is ignored" % str(invalid))
		trial.queue_free()
	_app.call("_recover")


func _test_exit_and_collision() -> void:
	await physics_frame
	await physics_frame
	var blockers: Array[StaticBody3D] = []
	for side in [-1, 1]:
		blockers.append(_obstruction(_van.to_global(Vector3(side * 2.05, 1.1, -0.4)),
			Vector3(0.9, 2.8, 1.2)))
	await physics_frame
	await physics_frame
	_app.call("_exit_van")
	_check(_van.occupied, "Blocked doors prevent exiting into obstacles")
	for blocker in blockers:
		blocker.queue_free()
	await physics_frame
	await physics_frame
	_app.call("_exit_van")
	_check(not _van.occupied, "Clear doors allow exit")
	_app.call("_enter_van")
	_check(_van.occupied, "Driver can reenter the van")
	var wall := _obstruction(_van.to_global(Vector3(0, 1.5, -7)),
		Vector3(9, 3, 0.5), _van.global_basis)
	var start := _van.global_position
	await physics_frame
	await physics_frame
	Input.action_press("accelerate")
	await create_timer(3).timeout
	Input.action_release("accelerate")
	var motion := _van.get_real_velocity()
	_check(Vector2(motion.x, motion.z).length() < 0.2,
		"Physical wall collision stops actual motion")
	_check(absf(_van.actual_speed) < 0.2,
		"Measured speed stays zero while throttle is held against a wall")
	_check(_van.global_position.distance_to(start) < 5,
		"Van remains on the near side of the test wall")
	wall.queue_free()


func _obstruction(
	at: Vector3, dimensions: Vector3, orientation: Basis = Basis.IDENTITY
) -> StaticBody3D:
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	body.add_child(collision)
	body.transform = Transform3D(orientation, at)
	root.add_child(body)
	return body


func _save_failed(error: int) -> void:
	_failed += 1
	_last_save_error = error


func _timeout() -> void:
	_check(false, "Regression suite completed within thirty seconds")
	quit(1)


func _remove_fixture_tree(path: String) -> void:
	for file in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file))
	for directory in DirAccess.get_directories_at(path):
		_remove_fixture_tree(path.path_join(directory))
	DirAccess.remove_absolute(path)
