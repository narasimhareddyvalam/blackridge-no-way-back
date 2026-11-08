extends SceneTree

const ETHAN = preload("res://features/characters/ethan/ethan.glb")
const PEDESTRIAN = preload("res://features/characters/pedestrian/pedestrian.glb")
const CAB_FLOOR := 1.17
const DRIVER_EYE := Vector3(-0.52, 2.03, -0.32)
const DOOR := Vector3(-1.83, 0.0, -0.7)
const AHEAD := Vector3(0.6, 0.0, -14.0)
const LIT := Vector3(-0.8, 0.0, -6.0)
const CLOSE_UP := DOOR + Vector3(-3.0, 0.0, 3.0)


class InputGate extends Node:
	func _input(event: InputEvent) -> void:
		if event is InputEventMouse or event is InputEventKey:
			get_viewport().set_input_as_handled()


var _app: Node3D
var _van: CharacterBody3D
var _environment: Environment
var _camera: Camera3D
var _folder: String
var _report := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-character-capture-%d.cfg" % OS.get_process_id())
	root.add_child(_app)
	var gate := InputGate.new()
	gate.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(gate)
	await process_frame
	_app.call("_resume")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_folder = _output_folder("evidence/phase_1/characters/step1")
	DirAccess.make_dir_recursive_absolute(_folder)
	_van = _app.get_node("FreightVan")
	var world: Node3D = _app.get_node("IndustrialLoop")
	var holder := world.find_children("*", "WorldEnvironment", false, false)[0] as WorldEnvironment
	_environment = holder.environment
	_camera = Camera3D.new()
	_camera.fov = 50.0
	_camera.far = 400.0
	root.add_child(_camera)
	_hold("brake", true)
	await _seconds(2.0)
	var ethan := _character(ETHAN, "Idle")
	var pedestrian := _character(PEDESTRIAN, "Walk")
	_measure(ethan, pedestrian)
	await _night_shots(ethan, pedestrian)
	await _debug_shots(ethan, pedestrian)
	var text := "\n".join(_report)
	print(text)
	var file := FileAccess.open(_folder.path_join("character_captures.txt"), FileAccess.WRITE)
	file.store_string(text + "\n")
	file.close()
	quit(0)


func _night_shots(ethan: Node3D, pedestrian: Node3D) -> void:
	_stand(ethan, DOOR, Vector3.RIGHT)
	_stand(pedestrian, AHEAD, Vector3.LEFT)
	_look(DOOR + Vector3(-3.4, 1.9, 1.4), DOOR + Vector3(0.6, 1.3, -0.2))
	await _shot("ethan_by_van_night")
	_stand(ethan, LIT, Vector3.BACK)
	_look(Vector3(-2.6, 1.6, -2.8), LIT + Vector3(0.0, 1.2, 0.0))
	await _shot("ethan_in_headlights_night")
	_stand(ethan, DOOR, Vector3.RIGHT)
	(_van.get_node("VanPresentation").get("driving_camera") as Camera3D).make_current()
	await _shot("pedestrian_low_beam", pedestrian)
	await _tap("headlights")
	await _shot("pedestrian_high_beam", pedestrian)
	await _tap("headlights")
	await _shot("pedestrian_lights_off", pedestrian)
	await _tap("headlights")


func _debug_shots(ethan: Node3D, pedestrian: Node3D) -> void:
	_environment.ambient_light_energy = 6.0
	_environment.fog_enabled = false
	_look(DOOR + Vector3(-3.4, 1.9, 1.4), DOOR + Vector3(0.6, 1.3, -0.2))
	await _shot("ethan_by_van_debug_light")
	_stand(ethan, CLOSE_UP, Vector3.LEFT)
	_look(CLOSE_UP + Vector3(-2.2, 1.45, 0.5), CLOSE_UP + Vector3(0.0, 1.15, 0.0))
	await _shot("ethan_close_debug_light")
	_stand(ethan, DOOR, Vector3.RIGHT)
	_stand(pedestrian, CLOSE_UP, Vector3.LEFT)
	await _shot("pedestrian_close_debug_light")
	_stand(pedestrian, AHEAD, Vector3.LEFT)
	await _enter_van_shots(ethan)


func _enter_van_shots(ethan: Node3D) -> void:
	var player := _player(ethan)
	var end := player.get_animation("EnterVan").length
	var seated := _bone_at(ethan, "EnterVan", end, "mixamorig_Hips")
	var turn := _heading(ethan, end) - _heading(ethan, 0.0)
	var facing := Vector3.FORWARD.rotated(Vector3.UP, -turn)
	var seat := Vector3(DRIVER_EYE.x, 0.0, DRIVER_EYE.z)
	var offset := Basis.looking_at(facing, Vector3.UP, true) * Vector3(seated.x, 0.0, seated.z)
	_stand(ethan, seat - offset, facing)
	_report.append("EnterVan: the clip turns him %.0f degrees and moves his hips %.2f m; seated "
		% [rad_to_deg(turn), Vector2(seated.x, seated.z).length()]
		+ "hips are %.2f m above his feet. The cab floor is %.2f m above the van's base and the "
		% [seated.y, CAB_FLOOR] + "driver's eye %.2f m." % DRIVER_EYE.y)
	_look(DOOR + Vector3(-3.2, 1.6, 0.0), DOOR + Vector3(1.0, 1.1, -0.2))
	for moment in [2.5, player.get_animation("EnterVan").length]:
		player.play("EnterVan")
		player.seek(moment, true)
		player.pause()
		await _shot("enter_van_%.1fs_debug_light" % moment)


func _character(scene: PackedScene, clip: String) -> Node3D:
	var character := scene.instantiate() as Node3D
	_app.add_child(character)
	_player(character).play(clip)
	return character


func _player(character: Node3D) -> AnimationPlayer:
	return character.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer


func _skeleton(character: Node3D) -> Skeleton3D:
	return character.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D


func _bone_at(character: Node3D, clip: String, moment: float, bone: String) -> Vector3:
	var player := _player(character)
	player.play(clip)
	player.seek(moment, true)
	var skeleton := _skeleton(character)
	var pose := skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(bone))
	return character.global_transform.affine_inverse() * pose.origin


func _heading(character: Node3D, moment: float) -> float:
	var across := _bone_at(character, "EnterVan", moment, "mixamorig_RightUpLeg") - _bone_at(
		character, "EnterVan", moment, "mixamorig_LeftUpLeg")
	return atan2(across.x, across.z)


func _measure(ethan: Node3D, pedestrian: Node3D) -> void:
	for character: Node3D in [ethan, pedestrian]:
		var skeleton := _skeleton(character)
		var head := skeleton.global_transform * skeleton.get_bone_global_pose(
			skeleton.find_bone("mixamorig_HeadTop_End"))
		var height := head.origin.y - character.global_position.y
		_report.append("%s: top of head %.2f m above the feet" % [character.name, height])


func _stand(character: Node3D, local: Vector3, facing: Vector3) -> void:
	var at := _van.global_transform * local
	var space := _van.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 4.0, at + Vector3.DOWN * 6.0)
	query.exclude = [_van.get_rid()]
	var hit := space.intersect_ray(query)
	if not hit.is_empty():
		at.y = hit.position.y
	var forward := (_van.global_basis * facing) * Vector3(1, 0, 1)
	character.global_transform = Transform3D(Basis.looking_at(forward, Vector3.UP, true), at)


func _look(local_from: Vector3, local_to: Vector3) -> void:
	_camera.look_at_from_position(_van.global_transform * local_from,
		_van.global_transform * local_to)
	_camera.make_current()


func _shot(stem: String, measured: Node3D = null) -> void:
	await _seconds(1.5)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(_folder.path_join(stem + ".png"))
	var line := "saved %s.png" % stem
	if measured != null:
		line += ", pedestrian brightness %.1f against road %.1f (0-255)" % _brightness(image, measured)
	_report.append(line)


func _brightness(image: Image, character: Node3D) -> Array:
	var camera := root.get_viewport().get_camera_3d()
	var feet := camera.unproject_position(character.global_position)
	var head := camera.unproject_position(character.global_position + Vector3.UP * 1.75)
	var half := (feet.y - head.y) * 0.12
	var body := Rect2i(Vector2i(int(feet.x - half), int(head.y)), Vector2i(int(half * 2.0),
		int(feet.y - head.y)))
	var road := Rect2i(body.position + Vector2i(int(half * 5.0), 0), body.size)
	return [_luma(image, body), _luma(image, road)]


func _luma(image: Image, area: Rect2i) -> float:
	var clipped := area.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	var total := 0.0
	for y in range(clipped.position.y, clipped.end.y):
		for x in range(clipped.position.x, clipped.end.x):
			var colour := image.get_pixel(x, y)
			total += 0.2126 * colour.r + 0.7152 * colour.g + 0.0722 * colour.b
	return total * 255.0 / maxf(1.0, float(clipped.get_area()))


func _tap(action: String) -> void:
	_hold(action, true)
	await process_frame
	_hold(action, false)
	await process_frame


func _hold(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _seconds(duration: float) -> void:
	var end := Time.get_ticks_msec() + int(duration * 1000.0)
	while Time.get_ticks_msec() < end:
		await process_frame


func _output_folder(default_folder: String) -> String:
	var args := OS.get_cmdline_user_args()
	var folder: String = args[0] if args.size() > 0 else default_folder
	if folder.is_absolute_path():
		return folder
	return ProjectSettings.globalize_path("res://").path_join("..").path_join(folder)
