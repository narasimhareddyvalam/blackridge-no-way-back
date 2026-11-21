extends SceneTree
## Mission guidance as a professional game's (#356; the author's choice of a map with the route,
## step 1, the layout): a round map at the bottom left while playing, centred every frame exactly
## where the player is (the van while driving, Ethan on foot as he walks), turned with the van at
## the wheel (not the driver's head) and with the camera on foot, smoothly, Ethan's arrow the way
## he faces; its roads and buildings drawn;
## the objective beside it, not in the top-left corner; the control hints at the bottom right;
## nothing of it on the title screen, the pause menu or in a cinematic.

const GROUND_TEXTURE := "res://features/ui/driving_hud/art/mission_map_ground.png"
const GROUND_BOUNDS := "res://features/ui/driving_hud/art/mission_map_ground.json"
const FADE := "res://features/ui/driving_hud/map_fade.gdshader"
const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"

var _checks := 0
var _failures := 0
var _app: Node3D
var _scratch: String


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(120.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-guidance-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(SAVE)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	var hud := _app.get("hud") as CanvasLayer
	var map := hud.get("mission_map") as Control
	var on_title := map != null and not map.is_visible_in_tree()
	_app.call("_resume")
	for frame in range(10):
		await process_frame
	var screen := root.get_visible_rect().size
	_check(map != null and on_title and map.is_visible_in_tree(), "G1: a mission map while "
		+ "playing, none on the title screen")
	if map == null:
		_finish()
		return
	var circle: Rect2 = map.call("map_rect")
	_check(circle.end.x < screen.x * 0.35 and circle.position.y > screen.y * 0.5
		and circle.size.x > circle.size.y, ("G2: it sits at the bottom left, wider than tall "
		+ "(%s in %s)") % [circle, screen])
	_world_in_3d(map, _app.get_node("IndustrialLoop"))
	var van := _app.get_node("FreightVan") as Node3D
	await _drive(van, map)
	var roads: int = map.call("road_count")
	var places: int = map.call("place_count")
	_check(roads >= 1 and places >= 3, "G4: its roads and buildings drawn (%d roads, %d places)"
		% [roads, places])
	var title := hud.get("_objective") as Label
	var detail := hud.get("_detail") as Label
	var beside := title != null and title.get_global_rect().position.x > circle.end.x \
		and title.get_global_rect().position.y > screen.y * 0.6 \
		and detail.get_global_rect().position.x > circle.end.x
	_check(beside, ("G5: the objective beside the map, not in the top-left corner (title at %s)")
		% (title.get_global_rect().position if title != null else Vector2.ZERO))
	var hint := hud.get("_hint") as Label
	var hint_rect := hint.get_global_rect() if hint != null else Rect2()
	_check(hint != null and hint_rect.end.x > screen.x * 0.7 and hint_rect.position.y
		> screen.y * 0.8, "G6: the control hints at the bottom right (%s)" % hint_rect)
	hud.call("set_cinematic", true)
	await process_frame
	var cinematic_hidden := not map.is_visible_in_tree() and not title.is_visible_in_tree()
	hud.call("set_cinematic", false)
	await process_frame
	hud.call("set_menu", true)
	await process_frame
	var menu_hidden := not map.is_visible_in_tree()
	hud.call("set_menu", false)
	await process_frame
	_check(cinematic_hidden and menu_hidden and map.is_visible_in_tree(), ("G7: none of it in a "
		+ "cinematic or the pause menu (cinematic %s, menu %s)") % [cinematic_hidden, menu_hidden])
	await _walk(van, map)
	_finish()


## Driving: every frame the map is centred exactly where the van is and turned with the van, not
## with the driver's head, turning smoothly.
func _drive(van: Node3D, map: Control) -> void:
	var presentation := van.get_node("VanPresentation")
	presentation.set("_look_target", Vector2(0.0, 0.9))
	Input.action_press("accelerate")
	Input.action_press("steer_left")
	var worst := 0.0
	var turn_worst := 0.0
	var steepest := 0.0
	var last := INF
	for frame in range(150):
		await map.followed
		var focus: Vector3 = map.get("focus")
		worst = maxf(worst, Vector2(focus.x - van.global_position.x,
			focus.z - van.global_position.z).length())
		var forward := -van.global_basis.z
		var heading: float = map.get("heading")
		turn_worst = maxf(turn_worst, absf(angle_difference(heading, atan2(forward.x, forward.z))))
		if last != INF:
			steepest = maxf(steepest, absf(angle_difference(last, heading)))
		last = heading
	Input.action_release("accelerate")
	Input.action_release("steer_left")
	presentation.set("_look_target", Vector2.ZERO)
	_check(bool(van.get("occupied")) and worst < 0.05 and rad_to_deg(turn_worst) < 4.0
		and rad_to_deg(steepest) < 3.0, ("G3: driving and turning, it is centred on the van every "
		+ "frame (worst %.3f m) and turned with the van, not the driver looking 50 degrees aside "
		+ "(worst %.1f degrees off), smoothly (at most "
		+ "%.1f degrees a frame)") % [worst, rad_to_deg(turn_worst), rad_to_deg(steepest)])


## On foot: centred exactly where Ethan stands as he walks, his arrow pointing the way he faces.
func _walk(van: Node3D, map: Control) -> void:
	Input.action_press("brake")
	for frame in range(240):
		await physics_frame
		if absf(float(van.get("speed"))) < 0.05:
			break
	Input.action_release("brake")
	for frame in range(30):
		await physics_frame
	await _press("interact")
	var driver := _app.get("driver") as Node3D
	var out := false
	for frame in range(600):
		await physics_frame
		if not bool(van.get("occupied")) and bool(driver.get("active")) \
				and not bool(_app.get("_boarding")):
			out = true
			break
	Input.action_press("accelerate")
	var worst := 0.0
	var aim_worst := 0.0
	for frame in range(90):
		await map.followed
		var focus: Vector3 = map.get("focus")
		worst = maxf(worst, Vector2(focus.x - driver.global_position.x,
			focus.z - driver.global_position.z).length())
		var facing: float = driver.call("facing_yaw")
		aim_worst = maxf(aim_worst, absf(angle_difference(float(map.get("facing")), facing)))
	Input.action_release("accelerate")
	_check(out and not bool(map.get("driving")) and worst < 0.05 and rad_to_deg(aim_worst) < 4.0,
		("G8: on foot, it is centred on Ethan every frame as he walks (worst %.3f m), his arrow "
		+ "the way he faces (worst %.1f degrees off)") % [worst, rad_to_deg(aim_worst)])


## The map is the district in 3D (the author's "Frameless 3D"): its own world, the ground the
## baked top-down map laid at the world's real bounds, every building a block at its own height,
## seen by a camera tilted down 40-70 degrees, its edges faded into the screen by its shader.
func _world_in_3d(map: Control, world: Node) -> void:
	var view := map.get("viewport") as SubViewport
	var own := view != null and view.own_world_3d
	var ground := map.get("ground") as MeshInstance3D
	var laid := false
	if ground != null:
		var bounds: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GROUND_BOUNDS))
		var box := ground.global_transform * ground.get_aabb()
		var origin: Array = bounds["origin"]
		var size: Array = bounds["size"]
		laid = absf(box.position.x - float(origin[0])) < 0.5 \
			and absf(box.position.z - float(origin[1])) < 0.5 \
			and absf(box.size.x - float(size[0])) < 0.5 and absf(box.size.z - float(size[1])) < 0.5
		var material := ground.material_override as BaseMaterial3D
		laid = laid and material != null and material.albedo_texture != null \
			and material.albedo_texture.resource_path == GROUND_TEXTURE
	var blocks: Array = map.get("blocks")
	var wanted: Array = world.call("map_blocks")
	var tall := blocks.size() == wanted.size() and not blocks.is_empty()
	for index in range(mini(blocks.size(), wanted.size())):
		var block := blocks[index] as MeshInstance3D
		var height: float = (wanted[index] as Dictionary)["height"]
		tall = tall and absf((block.global_transform * block.get_aabb()).size.y - height) < 0.2
	var camera := map.get("camera") as Camera3D
	var down := rad_to_deg(-camera.global_rotation.x) if camera != null else 0.0
	var fade := map.get("screen") as TextureRect
	var faded := fade != null and fade.material is ShaderMaterial \
		and (fade.material as ShaderMaterial).shader.resource_path == FADE
	_check(own and laid and tall and down >= 40.0 and down <= 70.0 and faded, ("G9: the map is the "
		+ "district in 3D: its own world (%s), the baked ground at the world's bounds (%s), %d "
		+ "buildings at their heights (%s), a camera %.0f degrees down, edges faded (%s)") % [own,
		laid, blocks.size(), tall, down, faded])


func _press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	await physics_frame


func _finish() -> void:
	print("GUIDANCE RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	_app.queue_free()
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "The guidance checks finish within 120 s")
	quit(1)
