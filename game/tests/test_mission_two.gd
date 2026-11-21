extends SceneTree

## The shed's camera walls (layer 8) in its open dock doors are solid to nothing but his camera.
const NOT_CAMERA_WALLS := 0xFFFFFFFF & ~8
const CARGO := "res://features/missions/the_wrong_cargo/the_wrong_cargo.gd"
const AT_THE_YARD := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=2\n"
const LOADED := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=1\n"
const START_SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const VAN_FRONT := Vector3(0.0, 1.0, -2.52)
const VAN_REAR := Vector3(0.0, 1.0, 3.01)
const YARD_SIGNS: Array[String] = ["5 MPH", "HI-VIS BEYOND THIS POINT", "STAFF PARKING ONLY",
	"NO PARKING"]
const GATE_LANE := Rect2(-74.0, 51.9, 6.0, 3.1)
const PLATFORM := Rect2(-92.0, -13.0, 66.0, 68.0)
const SHED := Rect2(-90.0, -10.0, 50.0, 30.0)
const OLD_SHED := Rect2(-89.0, 14.5, 36.0, 25.4)
const OFFICE := Rect2(-90.0, 12.0, 8.0, 8.0)
const DOCK_SIZE := Vector2(2.74, 3.05)
const DRIVE_IN_SIZE := Vector2(3.7, 2.9)
const DRIVE := Rect2(-74.0, 51.9, 21.0, 3.1)
const VAN_SILL := 0.4
const VAN_PASSAGE := AABB(Vector3(-48.6, 0.45, 19.8), Vector3(1.7, 0.8, 0.15))
## The drive-in lane inside the shed (#264): from the dock floor's edge to the east wall, and on
## under the drive-in door to the apron, whose top it is flush with.
const LANE := Rect2(-44.65, -9.7, 4.35, 29.7)
const APRON_TOP := 0.02

var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _cargo: Dictionary = {}
var _app: Node3D
var _hud: CanvasLayer
var _route: Node
var _van: CharacterBody3D
var _menu: Control
var _gate_shed: Node3D
var _gate_frames: int = 0
var _gate_hits: int = 0
var _gate_contacts: int = 0
var _head_pose := Transform3D()


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(170.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-mission-two-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	if not ResourceLoader.exists(CARGO):
		_check(false, "Mission 2, The Wrong Cargo, has its own mission script (%s)" % CARGO)
		_finish()
		return
	_cargo = (load(CARGO) as Script).get_script_constant_map()
	await _check_mission_one_hands_on()
	await _check_title()
	await _check_continue()
	await _check_new_game()
	await _check_gate()
	_remove()
	_finish()


func _check_mission_one_hands_on() -> void:
	await _build()
	_route.call("_save_finished")
	var saved := ConfigFile.new()
	_check(saved.load(_scratch) == OK and saved.get_value("save", "version", 0) == 2
		and saved.get_value("save", "mission", "") == "the_wrong_cargo"
		and saved.get_value("cargo", "stage", -1) == 0 and not saved.has_section("drive"),
		"Finishing Mission 1 saves Mission 2's start: version 2, the_wrong_cargo, checkpoint 0, "
		+ "and no Mission 1 section")
	await _free_app()


func _check_title() -> void:
	await _build()
	var start: Transform3D = _cargo.get("START", Transform3D())
	var eye: Vector3 = start * (_cargo.get("TITLE_EYE", Vector3.INF) as Vector3)
	var camera: Camera3D = _app.get("title_camera")
	var at := _van.global_position.distance_to(start.origin)
	_check(paused and _screen() == "title" and camera != null and root.get_camera_3d() == camera
		and camera.global_position.distance_to(eye) < 0.01 and at < 0.05,
		("Launched with that save, the title shows Mission 2's own scene: the van parked in the "
		+ "depot bay where Mission 1 ended, through the title camera (%.2f m from its spot)") % at)
	var named := _text_of("ContinuePlace")
	_check(_focus() == "Continue" and named == "The Wrong Cargo · The freight depot",
		"Continue comes first and names it (%s)" % named)
	_check(bool(_route.get("complete")) and _route.get("handed_on") != null
		and int(_route.get("stage")) == 0,
		"Mission 1 stays finished while the save is on Mission 2: no call, no encounter, no "
		+ "checkpoint of its own")
	await _free_app()


func _check_continue() -> void:
	_store(AT_THE_YARD)
	await _build()
	var named := _text_of("ContinuePlace")
	await _key(KEY_ENTER)
	await _seconds(1.5)
	var dark: Transform3D = _cargo.get("DARK_VAN", Transform3D())
	var off := Vector2(_van.global_position.x - dark.origin.x,
		_van.global_position.z - dark.origin.z).length()
	_check(named == "The Wrong Cargo · The container yard" and not paused
		and bool(_van.get("occupied")) and off < 0.5 and _eyebrow() == "THE WRONG CARGO",
		("Continue from Mission 2's third checkpoint names it (%s) and starts Mission 2 there: "
		+ "Ethan in the dark van at the container yard (%.2f m off, step 4), the screen headed "
		+ "The Wrong Cargo") % [named, off])
	await _key(KEY_ESCAPE)
	_check(paused and _screen() == "pause" and _text_of("Mission") == "THE WRONG CARGO"
		and _text_of("NextCheckpoint") == "The warehouse compound"
		and _text_of("LastSaved") == "The container yard",
		"Paused, Mission 2 names itself, its next checkpoint and its last save (%s; %s)"
		% [_text_of("NextCheckpoint"), _text_of("LastSaved")])
	await _key(KEY_ESCAPE)
	await _free_app()


func _check_new_game() -> void:
	_store(LOADED)
	await _build()
	await _key(KEY_DOWN)
	await _key(KEY_ENTER)
	var asked := _screen() == "confirm" and _focus() == "ConfirmNo"
	await _key(KEY_LEFT)
	await _key(KEY_ENTER)
	await _seconds(1.5)
	var saved := ConfigFile.new()
	_check(asked and saved.load(_scratch) == OK and saved.get_value("save", "version", 0) == 2
		and saved.get_value("save", "mission", "") == "night_freight"
		and saved.get_value("drive", "stage", -1) == 0 and not saved.has_section("cargo")
		and _objective() == "SIGN THE RUN SHEET" and _eyebrow() == "NIGHT FREIGHT",
		"New game, asked first, goes back to Mission 1's start at the office, saved as version 2")
	await _free_app()


func _check_gate() -> void:
	_remove()
	_store(START_SAVE)
	await _build()
	await _key(KEY_ENTER)
	await _seconds(1.0)
	var shed: Node3D = _app.get_node("IndustrialLoop").get("transfer_shed")
	if shed == null:
		_check(false, "The world has a transfer shed with a gate (IndustrialLoop.transfer_shed)")
		await _free_app()
		return
	var gate_z: float = shed.get("GATE_Z")
	var lane_x: float = shed.get("LANE_X")
	_check(not bool(shed.call("barrier_open")) and _objective() == "DRIVE TO THE TRANSFER SHED",
		"At Mission 2's start the gate's barrier is down, and the objective is the transfer shed "
		+ "(%s)" % _objective())
	_van.call("recover", Transform3D(Basis.IDENTITY, Vector3(lane_x, 0.1, gate_z + 18.0)))
	await _seconds(0.5)
	var booth := _check_booth(shed)
	_check_ground(shed, _app.get_node("IndustrialLoop"))
	_check_building(shed, _app.get_node("IndustrialLoop"))
	_check_lane_floor(shed)
	_check_docks(shed)
	_check_dock_lights(shed)
	_check_inside(shed)
	_check_yard(shed, _app.get_node("IndustrialLoop"))
	var eye := _van.get_node("VanPresentation").get("driving_camera") as Camera3D
	_watch_gate(shed)
	await _hold(KEY_W, 5.0)
	await _hold(KEY_S, 1.5)
	var front := _van.to_global(VAN_FRONT).z
	_check(front > gate_z - 0.05 and not bool(shed.call("barrier_open")),
		"Driving at the closed barrier, the van stops against its arm: its front %.2f m short of "
		% (front - gate_z) + "the arm's line, and the barrier stays down")
	_check(_objective() == "STOP AT THE GATE" and _detail().contains("E"),
		"At the gate the objective asks for a stop and names E (%s: %s)" % [_objective(),
		_detail()])
	var line_z: float = gate_z + float(shed.get("STOP_LINE_OUT"))
	_check(_detail().to_lower().contains("back up") and _detail().to_lower().contains("window"),
		("Against the arm, Ethan's window is past the booth's, and the objective says to back up "
		+ "level with it (%s)") % _detail())
	var mission: Node = null
	for node in _app.find_children("*", "Node", true, false):
		var script := node.get_script() as Script
		if script != null and script.resource_path == CARGO:
			mission = node
	_check(mission != null and not bool(mission.call("wants_interact")),
		"There, E offers the guard nothing: she cannot reach a window 2.6 m past hers")
	_van.call("recover", Transform3D(Basis.IDENTITY, Vector3(lane_x, 0.1, line_z - VAN_FRONT.z)))
	await _seconds(0.5)
	var window := shed.get_node_or_null("GuardBooth/ServiceWindow") as Node3D
	var along := INF
	var gap := INF
	if window != null and eye != null:
		var behind_front := eye.global_position.z - _van.to_global(VAN_FRONT).z
		along = absf(window.global_position.z - (line_z + behind_front))
		gap = _van.to_global(Vector3(-1.0, 1.0, 0.0)).x - window.global_position.x
	_check(along <= 0.5 and gap > 0.0 and gap <= 1.2,
		("With its front at the stop line, the van's driver sits beside the guard's window: "
		+ "Ethan's eye %.2f m from it along the lane, the booth %.2f m from the van's side")
		% [along, gap])
	var seated := booth.get("guard") as Node3D
	var side := INF
	if eye != null and is_instance_valid(seated):
		var bones := seated.find_children("*", "Skeleton3D", true, false)
		var head := _bone_at(bones[0] as Skeleton3D, "Bip01 Head")
		var at_line := eye.global_position + Vector3(0.0, 0.0,
			line_z - _van.to_global(VAN_FRONT).z)
		var ahead := -_van.global_basis.z
		side = absf(rad_to_deg(Vector2(ahead.x, ahead.z).angle_to(
			Vector2(head.x - at_line.x, head.z - at_line.z))))
	_check(side >= 85.0 and side <= 120.0,
		("Looking left from the seat at the stop line, Ethan sees the guard in his side window, "
		+ "clear of the windscreen pillar: his head %.0f° left of straight ahead") % side)
	await _seconds(1.0)
	var axis: int = booth.get("axis", -1)
	var look := INF
	if axis >= 0 and eye != null:
		var forward: Vector3 = _head_pose.basis[axis].normalized() * float(booth.get("sign", 1.0))
		look = rad_to_deg(forward.angle_to(eye.global_position - _head_pose.origin))
	_check(look < 25.0, "Within a second of the stop the guard looks at Ethan (%.0f° off his eye)"
		% look)
	var shut_z := window.position.z if window != null else 0.0
	await _key(KEY_E)
	await _seconds(1.0)
	_check(bool(_van.get("occupied")) and not bool(shed.call("barrier_open")),
		"E at the gate hands the guard the run sheet instead of leaving the van; the barrier "
		+ "waits for the guard's check")
	await _seconds(1.5)
	var lowered := float(_van.get("left_window"))
	_check(lowered > 0.9, "E lowers the driver's window, because the sheet goes through it "
		+ "(%.2f open)" % lowered)
	var slid := absf(window.position.z - shut_z) if window != null else 0.0
	_check(slid >= 0.4, ("While she checks the sheet the guard has slid her window open (%.2f m), "
		+ "as a gatehouse's sash is") % slid)
	var booth_node := shed.get_node_or_null("GuardBooth")
	var opening: Vector2 = booth_node.call("opening_span") if booth_node != null \
		and booth_node.has_method("opening_span") else Vector2.ZERO
	var glass := _van.find_child("DriverWindow", true, false) as MeshInstance3D
	var pane := glass.global_transform * glass.get_aabb() if glass != null else AABB()
	var overlap := minf(opening.y, pane.end.z) - maxf(opening.x, pane.position.z)
	var eye_z := eye.global_position.z if eye != null else INF
	_check(overlap >= 0.4 and eye_z >= opening.x and eye_z <= opening.y, ("Stopped at the line, "
		+ "the booth's open window is level with Ethan's: %.2f m of the opening beside his "
		+ "window's glass, his eye within it (%.2f to %.2f, his eye %.2f)") % [overlap, opening.x,
		opening.y, eye_z])
	var rising_said := ""
	for frame in range(int(6.5 * 60.0)):
		await process_frame
		if shed.has_method("barrier_rising") and bool(shed.call("barrier_rising")):
			rising_said = _objective()
	_check(rising_said == "WAIT FOR THE BARRIER", ("While the arm rises after her check the "
		+ "objective says to wait for it, not to stop and press E again (%s)") % rising_said)
	_check(bool(shed.call("barrier_open")),
		"After the check the barrier is up within 8 s")
	var closed := absf(window.position.z - shut_z) if window != null else INF
	_check(closed < 0.01, "Her check done, the window slides shut again (%.3f m open)" % closed)
	await _hold(KEY_W, 4.0)
	var rear := _van.to_global(VAN_REAR).z
	_check(rear < gate_z - 1.0, "The van drives through the gate: its rear %.2f m past the arm"
		% (gate_z - rear))
	var raised := float(_van.get("left_window"))
	_check(lowered > 0.9 and raised < 0.1,
		"Once the barrier is up, the window that went down goes back up (%.2f open)" % raised)
	await _seconds(6.0)
	_check(not bool(shed.call("barrier_open")),
		"Once the van is clear, the barrier comes back down behind it")
	_check(_gate_hits == 0 and _gate_frames > 0,
		"Over %d physics frames the arm was never across the van while it was lower than fully up "
		% _gate_frames + "(%d frames it was)" % _gate_hits)
	var bollards := shed.find_children("Bollard*", "MeshInstance3D", true, false).size()
	_check(shed.get_node_or_null("Island") != null and bollards == 3 and _gate_contacts == 0,
		("A kerbed island with %d bollards guards the booth, and the van driven up the middle of "
		+ "the lane touched neither (%d contacts)") % [bollards, _gate_contacts])
	var guard := booth.get("guard") as Node3D
	var moved := INF
	if is_instance_valid(guard):
		var start: Vector3 = booth.get("start", Vector3.INF)
		moved = guard.global_position.distance_to(start)
	_check(moved < 0.01, "The guard stays where he sits from the start of the gate to its end "
		+ "(%.3f m)" % moved)
	_gate_shed = null
	await _free_app()


func _check_booth(shed: Node3D) -> Dictionary:
	var gate_z: float = shed.get("GATE_Z")
	var size: Vector3 = shed.get("BOOTH")
	var booth := shed.get_node_or_null("GuardBooth") as Node3D
	var panes: Array[MeshInstance3D] = []
	if booth != null:
		for child in booth.get_children():
			var named := String(child.name)
			if child is MeshInstance3D and (named.begins_with("Glass") or named == "ServiceWindow"):
				panes.append(child as MeshInstance3D)
	var clear := panes.size() >= 4
	for pane in panes:
		var surface := pane.material_override as StandardMaterial3D
		clear = clear and surface != null \
			and surface.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED \
			and surface.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED \
			and not surface.emission_enabled
	_check(clear, ("The booth's windows are glass you see through: %d panes, each transparent, "
		+ "lit by the scene and not glowing") % panes.size())
	var counter := _in_booth(booth, size, "Counter")
	var chair := _in_booth(booth, size, "Chair")
	var screen := _in_booth(booth, size, "Monitor/Screen") as MeshInstance3D
	var light: OmniLight3D = null
	if booth != null:
		light = booth.get_node_or_null("BoothLight") as OmniLight3D
	var glowing := screen != null and screen.material_override is StandardMaterial3D \
		and (screen.material_override as StandardMaterial3D).emission_enabled
	_check(counter != null and chair != null and glowing and light != null and light.shadow_enabled,
		"Inside the booth stand a counter, a chair and a lit monitor, and its light casts "
		+ "shadows, so it leaves the booth only through the glass")
	var guard := _in_booth(booth, size, "GuardStandIn")
	var skeleton: Skeleton3D = null
	var skinned := false
	var solid := 0
	var looping := false
	if guard != null:
		var skeletons := guard.find_children("*", "Skeleton3D", true, false)
		if not skeletons.is_empty():
			skeleton = skeletons[0] as Skeleton3D
		for mesh in guard.find_children("*", "MeshInstance3D", true, false):
			skinned = skinned or (mesh as MeshInstance3D).skin != null
		solid = guard.find_children("*", "CollisionObject3D", true, false).size()
		var players := guard.find_children("*", "AnimationPlayer", true, false)
		if not players.is_empty() and (players[0] as AnimationPlayer).is_playing():
			var player := players[0] as AnimationPlayer
			var clip := player.get_animation(player.current_animation)
			looping = clip != null and clip.loop_mode != Animation.LOOP_NONE
	var marked := guard != null and bool(guard.get_meta("stand_in", false))
	_check(skeleton != null and skinned and marked and solid == 0 and looping,
		"The guard sits in the booth: a skinned character playing a looping idle, marked a "
		+ "stand-in (D6), with nothing in him to collide with")
	var above := INF
	var turn := INF
	var axis := -1
	var sign := 1.0
	if skeleton != null and chair != null:
		var hips := _bone_at(skeleton, "Bip01 Pelvis")
		var seat_top := chair.get_node_or_null("SeatTop") as Node3D
		if seat_top != null:
			above = hips.y - seat_top.global_position.y
		var knees := (_bone_at(skeleton, "Bip01 L Calf") + _bone_at(skeleton, "Bip01 R Calf")) / 2.0
		var facing := Vector3(knees.x - hips.x, 0.0, knees.z - hips.z)
		if facing.length() > 0.01:
			turn = rad_to_deg(facing.normalized().angle_to(Vector3.RIGHT))
		var head := skeleton.find_bone("Bip01 Head")
		if head >= 0:
			var rest := (skeleton.global_transform.basis
				* skeleton.get_bone_global_rest(head).basis).orthonormalized()
			var best := 0.0
			for index in range(3):
				var along := rest[index].dot(Vector3.RIGHT)
				if absf(along) > best:
					best = absf(along)
					axis = index
					sign = signf(along)
			skeleton.skeleton_updated.connect(_on_guard_pose.bind(skeleton, head))
	_check(above > 0.0 and above < 0.25, "He sits on the chair: his hips %.2f m above its seat"
		% above)
	var lit_face := false
	if skeleton != null:
		var face := _bone_at(skeleton, "Bip01 Head")
		for found in booth.find_children("*", "OmniLight3D", true, false):
			var lamp := found as OmniLight3D
			var offset := lamp.global_position - face
			lit_face = lit_face or (lamp.name != "BoothLight" and offset.length() <= 1.2
				and offset.dot(Vector3.RIGHT) > 0.0 and not lamp.shadow_enabled
				and lamp.light_energy > 0.0)
	_check(lit_face, "A light in front of the guard, within 1.2 m of his head and casting no "
		+ "shadow, lights his face")
	_check(turn < 20.0, "He faces the lane-side window: his knees point %.0f° from it" % turn)
	var cabinet := shed.get_node_or_null("BarrierCabinet") as Node3D
	var fence := shed.get_node_or_null("Fence")
	var to_cabinet := INF
	if cabinet != null and fence != null:
		var cabinet_west := INF
		for mesh: MeshInstance3D in cabinet.find_children("*", "MeshInstance3D", true, false):
			cabinet_west = minf(cabinet_west, (mesh.global_transform * mesh.get_aabb()).position.x)
		for child in fence.get_children():
			var shape := child as CollisionShape3D
			if shape == null or not shape.shape is BoxShape3D:
				continue
			if absf(shape.global_position.z - gate_z) > 0.2 \
					or absf(shape.global_transform.basis.x.normalized().x) < 0.99:
				continue
			var east_end := shape.global_position.x + (shape.shape as BoxShape3D).size.x / 2.0
			to_cabinet = minf(to_cabinet, absf(cabinet_west - east_end))
	var outside := booth != null and booth.global_position.z - size.z / 2.0 > gate_z
	_check(to_cabinet <= 0.1 and outside,
		("The fence along the gate line runs to the barrier cabinet (%.2f m short) and the booth "
		+ "stands outside it, on the road side") % to_cabinet)
	var wires := shed.find_children("BarbStrand*", "MeshInstance3D", true, false) \
		+ shed.find_children("BottomWire*", "MeshInstance3D", true, false)
	var thin := not wires.is_empty()
	for wire in wires:
		var surface := (wire as MeshInstance3D).material_override as ShaderMaterial
		thin = thin and surface != null and surface.shader != null \
			and surface.shader.resource_path.ends_with("thin_wire.gdshader")
	_check(thin, "The barbed strands and the bottom wire are drawn as thin wire, at least a "
		+ "pixel wide (%d wires)" % wires.size())
	var panels := 0
	var veiled := true
	for found in shed.find_children("*", "MeshInstance3D", true, false):
		var surface := (found as MeshInstance3D).material_override as ShaderMaterial
		if surface == null or surface.shader == null \
				or not surface.shader.resource_path.ends_with("chain_link.gdshader"):
			continue
		panels += 1
		var glint: Variant = surface.get_shader_parameter("zinc_reflectance")
		veiled = veiled and not surface.shader.code.contains("ALPHA_HASH_SCALE") \
			and glint != null and float(glint) <= 0.15
	_check(panels > 0 and veiled, "The chain-link is a blended veil, not hashed, and glints at no "
		+ "more than 0.15 of a wire's light (%d panels)" % panels)
	return {"guard": guard, "start": guard.global_position if guard != null else Vector3.INF,
		"axis": axis, "sign": sign}


func _check_ground(shed: Node3D, world: Node3D) -> void:
	var terrain: Node3D = world.get("terrain")
	var forest: Node3D = world.get("forest")
	var worst := 0.0
	var open := 0
	for z in range(int(PLATFORM.position.y), int(PLATFORM.end.y)):
		for x in range(int(PLATFORM.position.x), int(PLATFORM.end.x)):
			worst = maxf(worst, absf(float(terrain.call("height_at", x + 0.5, z + 0.5))))
			if forest != null and not bool(forest.call("_is_blocked", x + 0.5, z + 0.5)):
				open += 1
	_check(worst <= 0.02 and open == 0, ("E1: the platform is level (%.2f m at worst) and no "
		+ "tree may stand on it (%d open spots)") % [worst, open])
	var walls: Array[AABB] = []
	for found in shed.find_children("CutWall*", "MeshInstance3D", true, false):
		walls.append((found as MeshInstance3D).global_transform * (found as MeshInstance3D).get_aabb())
	var edges: Array[Array] = [[Vector2(PLATFORM.position.x, PLATFORM.position.y),
		Vector2(PLATFORM.end.x, PLATFORM.position.y), Vector2(0.0, -1.0)],
		[Vector2(PLATFORM.position.x, PLATFORM.position.y), Vector2(PLATFORM.position.x,
		PLATFORM.end.y), Vector2(-1.0, 0.0)], [Vector2(PLATFORM.end.x, PLATFORM.position.y),
		Vector2(PLATFORM.end.x, PLATFORM.end.y), Vector2(1.0, 0.0)]]
	var sloping := 0
	var unheld := 0
	var samples := 0
	for edge in edges:
		var from: Vector2 = edge[0]
		var to: Vector2 = edge[1]
		var out: Vector2 = edge[2]
		var steps := int(from.distance_to(to) / 0.5)
		for step in range(1, steps):
			var at := from.lerp(to, float(step) / steps)
			samples += 1
			var inside := at - out * 0.5
			var behind := at + out * 3.0
			if absf(float(terrain.call("height_at", inside.x, inside.y))) > 0.02:
				sloping += 1
			var ground := float(terrain.call("height_at", behind.x, behind.y))
			if ground > 0.3 and not walls.any(func(box: AABB) -> bool:
					return Rect2(box.position.x, box.position.z, box.size.x, box.size.z).grow(0.3) \
						.has_point(at) and box.end.y >= ground):
				unheld += 1
	_check(not walls.is_empty() and samples > 0 and sloping == 0 and unheld == 0,
		("E2: every cut is held: %d walls; of %d points along the edges, %d slope in front "
		+ "and %d have higher ground 3 m behind than any wall there") % [walls.size(), samples,
		sloping, unheld])


## Whether a slab is drawn in a textured concrete: a material with its albedo texture, or the
## shed's floor (`shed_floor.gd`, step 5 of #253, part D), a shader over its concrete texture.
func _textured(paint: Material) -> bool:
	if paint is BaseMaterial3D:
		return (paint as BaseMaterial3D).albedo_texture != null
	return paint is ShaderMaterial \
		and (paint as ShaderMaterial).get_shader_parameter("floor_color") is Texture2D


## E11: the drive-in lane is floored, as a shed's is, with a concrete slab, never the hill's dirt:
## at every point of a 0.5 m grid over it a ray down from just above the apron's height (below
## anything standing on the floor, such as the dock stair) meets the shed's own body at that
## height, where the shed draws a slab in a textured concrete.
func _check_lane_floor(shed: Node3D) -> void:
	var body := shed.get_node_or_null("Building/ShedBody")
	var slabs: Array[MeshInstance3D] = []
	for found in shed.find_children("LaneFloor*", "MeshInstance3D", true, false):
		slabs.append(found as MeshInstance3D)
	var ray := PhysicsRayQueryParameters3D.new()
	ray.collision_mask = NOT_CAMERA_WALLS
	var space := _app.get_world_3d().direct_space_state
	var points := 0
	var bare := 0
	var undrawn := 0
	var worst := ""
	var x := LANE.position.x + 0.05
	while x < LANE.end.x:
		var z := LANE.position.y + 0.05
		while z < LANE.end.y:
			points += 1
			ray.from = Vector3(x, APRON_TOP + 0.04, z)
			ray.to = Vector3(x, -0.5, z)
			var hit := space.intersect_ray(ray)
			var top := (hit.get("position", Vector3.INF) as Vector3).y
			if hit.is_empty() or hit["collider"] != body or absf(top - APRON_TOP) > 0.005:
				bare += 1
				if worst == "":
					worst = "(%.2f, %.2f): %s at %.3f m" % [x, z, "nothing" if hit.is_empty()
						else String((hit["collider"] as Node).name), top]
			var drawn := false
			for slab in slabs:
				var box := slab.global_transform * slab.get_aabb()
				if Rect2(box.position.x, box.position.z, box.size.x, box.size.z).has_point(
						Vector2(x, z)) and absf(box.end.y - APRON_TOP) < 0.005 \
						and _textured(slab.get_active_material(0)):
					drawn = true
			if not drawn:
				undrawn += 1
			z += 0.5
		x += 0.5
	_check(points > 0 and bare == 0 and undrawn == 0, ("E11: the drive-in lane inside the shed "
		+ "is a concrete slab flush with the apron, %.2f m up, never the hill's dirt: of %d points, "
		+ "%d not on the shed's slab (first %s), %d not drawn in its textured concrete") % [
		APRON_TOP, points, bare, worst, undrawn])


func _check_building(shed: Node3D, world: Node3D) -> void:
	var body := shed.get_node_or_null("Building/ShedBody") as StaticBody3D
	var boxes: Array[AABB] = []
	if body != null:
		for found in body.find_children("*", "CollisionShape3D", true, false):
			var shape := found as CollisionShape3D
			if shape.shape is BoxShape3D:
				var size: Vector3 = (shape.shape as BoxShape3D).size
				boxes.append(shape.global_transform * AABB(-size / 2.0, size))
	var union := boxes[0] if not boxes.is_empty() else AABB()
	for box in boxes:
		union = union.merge(box)
	var old := 0
	for found in world.get_children():
		if found is MeshInstance3D:
			var at := (found as MeshInstance3D).global_position
			old += 1 if OLD_SHED.has_point(Vector2(at.x, at.z)) else 0
	_check(not boxes.is_empty() and absf(union.position.x - SHED.position.x) < 0.05
		and absf(union.end.x - SHED.end.x) < 0.05 and absf(union.position.z - SHED.position.y) < 0.05
		and absf(union.end.z - SHED.end.y) < 0.05 and absf(union.end.y - 9.0) < 0.1 and old == 0,
		("E3: the shed's walls span x %.2f..%.2f, z %.2f..%.2f, eaves %.2f m; %d pieces of the old "
		+ "warehouse remain") % [union.position.x, union.end.x, union.position.z, union.end.z,
		union.end.y, old])
	var openings: Array[Array] = []
	for index in range(8):
		openings.append(["DockOpening%d" % (index + 1), Vector3(-80.0 + 4.0 * index, 1.3, 20.0),
			DOCK_SIZE])
	openings.append(["DockOpening9", Vector3(-47.75, 1.3, 20.0), DOCK_SIZE])
	openings.append(["DriveInOpening", Vector3(-42.75, 0.0, 20.0), DRIVE_IN_SIZE])
	var wrong: Array[String] = []
	for entry in openings:
		var marker := shed.get_node_or_null("Building/" + entry[0]) as Node3D
		var sill: Vector3 = entry[1]
		var size: Vector2 = entry[2]
		if marker == null or marker.global_position.distance_to(sill) > 0.02:
			wrong.append(entry[0])
			continue
		var floor := APRON_TOP if entry[0] == "DriveInOpening" else sill.y
		var hole := AABB(Vector3(sill.x - size.x / 2.0, floor, 19.0), Vector3(size.x,
			size.y - (floor - sill.y), 2.0))
		var edges: Array[Vector3] = [Vector3(hole.position.x - 0.05, sill.y + size.y / 2.0, 19.9),
			Vector3(hole.end.x + 0.05, sill.y + size.y / 2.0, 19.9),
			Vector3(sill.x, hole.end.y + 0.05, 19.9)]
		if entry[0] == "DockOpening9":
			edges.append_array([Vector3(sill.x - 1.15, sill.y - 0.05, 19.9),
				Vector3(sill.x + 1.15, sill.y - 0.05, 19.9)])
		elif sill.y > 0.0:
			edges.append(Vector3(sill.x, sill.y - 0.05, 19.9))
		var overlaps := boxes.any(func(box: AABB) -> bool: return box.intersects(hole.grow(-0.02)))
		var framed := edges.all(func(point: Vector3) -> bool:
			return boxes.any(func(box: AABB) -> bool: return box.grow(0.001).has_point(point)))
		if overlaps or not framed:
			wrong.append(entry[0])
	var undoored: Array[String] = []
	for entry in openings:
		var door_name: String = (entry[0] as String).replace("Opening", "Door")
		var door_node := shed.get_node_or_null("Building/" + door_name) as Node3D
		var sill: Vector3 = entry[1]
		var size: Vector2 = entry[2]
		var opening := AABB(Vector3(sill.x - size.x / 2.0 + 0.03, sill.y + 0.03, 19.95),
			Vector3(size.x - 0.06, size.y - 0.06, 0.1))
		var seen := AABB()
		var solid := false
		var parts: Array[AABB] = []
		if door_node != null:
			for found in door_node.find_children("*", "MeshInstance3D", true, false):
				var part := found as MeshInstance3D
				var box: AABB = part.global_transform * part.get_aabb()
				parts.append(box)
				seen = box if not seen.has_volume() else seen.merge(box)
			for found in door_node.find_children("*", "CollisionShape3D", true, false):
				var shape := found as CollisionShape3D
				if shape.shape is BoxShape3D:
					var extent: Vector3 = (shape.shape as BoxShape3D).size
					var blocker: AABB = shape.global_transform * AABB(-extent / 2.0, extent)
					solid = solid or blocker.grow(0.0).encloses(AABB(opening.position, Vector3(
						opening.size.x, opening.size.y, 0.0)))
		var face := AABB(opening.position, Vector3(opening.size.x, opening.size.y, 0.0))
		var doorway := AABB(face.position + Vector3(0.1, 0.1, -0.2), Vector3(face.size.x - 0.2,
			face.size.y - 0.2, 0.4))
		if door_name in ["DockDoor5", "DockDoor9"]:
			if door_node == null or (seen.has_volume() and seen.intersects(doorway)) or solid:
				undoored.append(door_name + " not open")
		elif door_node == null or not seen.has_volume() or not seen.grow(0.001).encloses(face) \
				or not solid or not _filled(parts, face):
			undoored.append(door_name)
	_check(undoored.is_empty(), ("E4: a closed, solid door fills each opening but docks 5 "
		+ "and 9, which stand open, every point of it, no gap to see through (wrong: %s)")
		% ", ".join(undoored))
	_check(wrong.is_empty(), ("E4: nine dock openings 2.74 x 3.05 m from 1.3 m up at x -80 + 4n "
		+ "and -47.75, framed by the wall (bay 9's below only beside its passage), and the drive-in "
		+ "door's 3.7 x 2.9 m at the yard's level at x -42.75 (wrong: %s)") % ", ".join(wrong))
	var through := boxes.filter(func(box: AABB) -> bool: return box.intersects(VAN_PASSAGE))
	var kerb := boxes.any(func(box: AABB) -> bool:
		return box.has_point(Vector3(-47.75, VAN_SILL - 0.1, 19.9)))
	_check(through.is_empty() and kerb,
		("E4: under bay 9's door a passage as wide as its lift's pit reaches down to a 0.4 m sill, "
		+ "a kerb below it (%d walls in it; kerb %s), so the lowered lift meets a van's floor "
		+ "(step 2e)") % [through.size(), kerb])
	var light := shed.get_node_or_null("Building/OfficeLight") as OmniLight3D
	var door := shed.get_node_or_null("Building/OfficeDoor") as MeshInstance3D
	var door_box: AABB = door.global_transform * door.get_aabb() if door != null else AABB()
	_check(light != null and light.light_energy > 0.0 and OFFICE.has_point(Vector2(
		light.global_position.x, light.global_position.z)) and door != null
		and door_box.position.y < 0.05 and absf(door_box.get_center().z - 20.0) < 0.3
		and door_box.position.x > OFFICE.position.x and door_box.end.x < OFFICE.end.x,
		"E5: the office is lit inside, and its door stands at the yard's level in the front wall")


const DOCK_XS: Array[float] = [-80.0, -76.0, -72.0, -68.0, -64.0, -60.0, -56.0, -52.0, -47.75]


func _seen(node: Node) -> AABB:
	var seen := AABB()
	if node == null:
		return seen
	for found in node.find_children("*", "MeshInstance3D", true, false):
		var part := found as MeshInstance3D
		var box: AABB = part.global_transform * part.get_aabb()
		seen = box if not seen.has_volume() else seen.merge(box)
	return seen


func _check_docks(shed: Node3D) -> void:
	var unsealed: Array[String] = []
	for index in range(DOCK_XS.size()):
		var x := DOCK_XS[index]
		var seal := _seen(shed.get_node_or_null("Building/DockSeal%d" % (index + 1)))
		if not seal.has_volume() or seal.position.x > x - 1.47 or seal.end.x < x + 1.47 \
				or seal.position.y > 1.35 or seal.end.y < 4.4 or seal.position.z < 19.95 \
				or seal.end.z > 20.7:
			unsealed.append(str(index + 1))
	_check(unsealed.is_empty(), "F1: each dock has a seal framing its door on the wall's face "
		+ "(wrong: %s)" % ", ".join(unsealed))
	var bumpers := shed.find_children("DockBumper*", "MeshInstance3D", true, false)
	var bumped: Array[String] = []
	for index in range(DOCK_XS.size()):
		var x := DOCK_XS[index]
		var van_bay := index == DOCK_XS.size() - 1
		var span := Vector2(0.6, 1.0) if van_bay else Vector2(0.8, 1.5)
		var top := VAN_SILL if van_bay else 1.3
		var near := bumpers.filter(func(found: Node) -> bool:
			var box: AABB = (found as MeshInstance3D).global_transform \
				* (found as MeshInstance3D).get_aabb()
			var off := absf(box.get_center().x - x)
			return off >= span.x and off <= span.y and absf(box.end.y - top) <= 0.05 \
				and box.end.z - 20.0 >= 0.1 and box.end.z - 20.0 <= 0.2 \
				and found.find_children("*", "CollisionShape3D", true, false).size() > 0)
		if near.size() != 2:
			bumped.append(str(index + 1))
	_check(bumpers.size() == 18 and bumped.is_empty(), ("F2: two solid bumpers under each "
		+ "door, tops at 1.3 m (bay 9's at its 0.4 m sill, where a van's rear meets them) and "
		+ "0.10-0.20 m proud (%d bumpers; wrong: %s)") % [bumpers.size(), ", ".join(bumped)])
	var unlevelled: Array[String] = []
	for index in range(DOCK_XS.size()):
		var x := DOCK_XS[index]
		var leveller := _seen(shed.get_node_or_null("Building/DockLeveller%d" % (index + 1)))
		if index == DOCK_XS.size() - 1:
			if leveller.has_volume():
				unlevelled.append("9 has one")
		elif not leveller.has_volume() or absf(leveller.end.y - 1.3) > 0.05 \
				or leveller.position.z < 17.0 or leveller.end.z > 19.8 \
				or absf(leveller.get_center().x - x) > 0.2:
			unlevelled.append(str(index + 1))
	_check(unlevelled.is_empty(), "F3: docks 1-8 each have a leveller inside, its deck at 1.3 m, "
		+ "and bay 9 none (wrong: %s)" % ", ".join(unlevelled))


func _lit(lens: MeshInstance3D) -> bool:
	var surface := lens.get_active_material(0) as StandardMaterial3D
	return surface != null and surface.emission_enabled


func _check_dock_lights(shed: Node3D) -> void:
	var tops: Array[Vector2] = []
	for x in DOCK_XS:
		tops.append(Vector2(x, 4.35))
	tops.append(Vector2(-42.75, 2.9))
	var lights := shed.find_children("DockLight*", "SpotLight3D", true, false)
	var dark: Array[String] = []
	for top in tops:
		var over := lights.filter(func(node: Node) -> bool:
			var light := node as SpotLight3D
			var at := light.global_position
			var aim := -light.global_basis.z.normalized()
			return absf(at.x - top.x) < 0.3 and at.y - top.y > 0.3 and at.y - top.y < 1.2 \
				and at.z >= 20.0 and at.z <= 20.6 and aim.dot(Vector3.DOWN) > 0.5 \
				and light.light_energy > 0.0 and light.visible)
		if over.size() != 1:
			dark.append("%.2f" % top.x)
	_check(lights.size() == 10 and dark.is_empty(), ("F4: a lit light over each of the ten "
		+ "doors, aimed down (%d lights; wrong at x %s)") % [lights.size(), ", ".join(dark)])
	var wrong: Array[String] = []
	for index in range(DOCK_XS.size()):
		var housing := shed.get_node_or_null("Building/DockSignal%d" % (index + 1)) as Node3D
		var red := housing.get_node_or_null("Red") as MeshInstance3D if housing != null else null
		var green := housing.get_node_or_null("Green") as MeshInstance3D \
			if housing != null else null
		var want_green := index == 4 or index == 8
		if red == null or green == null or _lit(green) != want_green or _lit(red) == want_green \
				or absf(housing.global_position.x - DOCK_XS[index]) > 2.2 \
				or housing.global_position.y < 1.8 or housing.global_position.y > 3.0:
			wrong.append(str(index + 1))
	_check(wrong.is_empty(), ("F5: a red/green signal beside each dock door, green at docks 5 "
		+ "and 9 and red at the others (wrong: %s)") % ", ".join(wrong))


## Whether `parts` between them cover every point of `face`, on a 5 cm grid: no gap between a
## door's panels to see out through (#258).
func _filled(parts: Array[AABB], face: AABB) -> bool:
	var steps := Vector2i(ceili(face.size.x / 0.05), ceili(face.size.y / 0.05))
	for i in range(steps.x + 1):
		for j in range(steps.y + 1):
			var point := face.position + Vector3(face.size.x * i / steps.x,
				face.size.y * j / steps.y, 0.0)
			var behind := false
			for box in parts:
				if box.position.x - 0.001 <= point.x and point.x <= box.end.x + 0.001 \
						and box.position.y - 0.001 <= point.y and point.y <= box.end.y + 0.001:
					behind = true
					break
			if not behind:
				return false
	return true


func _check_inside(shed: Node3D) -> void:
	var space := shed.get_world_3d().direct_space_state
	var clear: Array[String] = []
	for index: int in [4, 8]:
		var x := DOCK_XS[index]
		var box := BoxShape3D.new()
		box.size = Vector3(2.4, 2.6, 0.2)
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = box
		query.transform = Transform3D(Basis.IDENTITY, Vector3(x, 2.8, 19.88))
		query.collision_mask = NOT_CAMERA_WALLS
		var arm := shed.get_node_or_null("Building/DockArmLight%d" % (index + 1)) as SpotLight3D
		var aim := -arm.global_basis.z.normalized() if arm != null else Vector3.ZERO
		if not space.intersect_shape(query, 1).is_empty() or arm == null \
				or arm.light_energy <= 0.0 or aim.dot(Vector3.BACK) < 0.5 \
				or arm.global_position.z > 20.0 or absf(arm.global_position.x - x) > 2.0:
			clear.append(str(index + 1))
	_check(clear.is_empty(), "F6: docks 5 and 9 stand open, a lit arm light inside each aimed out "
		+ "into its bay (wrong: %s)" % ", ".join(clear))
	var lights := shed.find_children("BayLight*", "Light3D", true, false)
	var lit := lights.filter(func(node: Node) -> bool:
		var light := node as Light3D
		var at := light.global_position
		return SHED.has_point(Vector2(at.x, at.z)) and at.y > 7.0 and at.y < 9.0 \
			and light.light_energy > 0.0)
	var props: Array[String] = []
	for entry: Array in [["Building/Forklift", Vector2(-64.0, 15.0), 8.0],
			["Building/PalletJack", Vector2(-47.75, 16.0), 6.0]]:
		var node := shed.get_node_or_null(entry[0]) as Node3D
		var centre: Vector2 = entry[1]
		if node == null or Vector2(node.global_position.x, node.global_position.z) \
				.distance_to(centre) > float(entry[2]) or node.global_position.y < 1.25:
			props.append(String(entry[0]).get_file())
	var building := shed.get_node_or_null("Building")
	var pallets := 0 if building == null else building.get_children().filter(
		func(node: Node) -> bool: return String(node.name).begins_with("Pallet") \
			and not String(node.name).begins_with("PalletJack")).size()
	_check(lit.size() >= 8 and props.is_empty() and pallets >= 4, ("F6: the inside by the docks is "
		+ "lit (%d lights under the roof) with the forklift, the pallet jack and %d pallets "
		+ "(missing: %s)") % [lit.size(), pallets, ", ".join(props)])


func _check_yard(shed: Node3D, world: Node3D) -> void:
	var pieces: Array[Rect2] = []
	for found in shed.find_children("*", "MeshInstance3D", true, false):
		var named := String(found.name)
		if named.begins_with("YardAsphalt") or named.begins_with("DockApron"):
			var box: AABB = (found as MeshInstance3D).global_transform \
				* (found as MeshInstance3D).get_aabb()
			pieces.append(Rect2(box.position.x, box.position.z, box.size.x, box.size.z)
				.grow(0.01))
	var bare := 0
	var sampled := 0
	for spot in _yard_spots():
		sampled += 1
		if not pieces.any(func(piece: Rect2) -> bool: return piece.has_point(spot)):
			bare += 1
	_check(sampled > 0 and bare == 0, ("E6: the yard is paved everywhere inside the fence: "
		+ "%d of %d points between the fence and the shed unpaved") % [bare, sampled])
	var shapes: Array[CollisionShape3D] = []
	for holder: String in ["Fence", "Ground"]:
		var node := shed.get_node_or_null(holder)
		if node != null:
			for found in node.find_children("*", "CollisionShape3D", true, false):
				if (found as CollisionShape3D).shape is BoxShape3D:
					shapes.append(found as CollisionShape3D)
	var corners: Array[Vector2] = [Vector2(PLATFORM.position.x, PLATFORM.position.y),
		Vector2(PLATFORM.end.x, PLATFORM.position.y), Vector2(PLATFORM.end.x, PLATFORM.end.y),
		Vector2(PLATFORM.position.x, PLATFORM.end.y)]
	var gaps := 0
	var edge_points := 0
	for side in range(4):
		var from := corners[side]
		var to := corners[(side + 1) % 4]
		var steps := int(from.distance_to(to) / 0.5)
		for step in range(steps + 1):
			var at := from.lerp(to, float(step) / steps)
			if absf(at.y - PLATFORM.end.y) < 0.01 and at.x > -74.4 and at.x < -67.4:
				continue
			edge_points += 1
			if not shapes.any(func(shape: CollisionShape3D) -> bool:
					var local := shape.global_transform.affine_inverse() * Vector3(at.x, 1.0, at.y)
					var half := (shape.shape as BoxShape3D).size / 2.0
					return absf(local.x) <= half.x + 0.35 and absf(local.z) <= half.z + 0.35):
				gaps += 1
	var body := shed.get_node_or_null("Building/ShedBody")
	var front := -INF
	if body != null:
		for found in body.find_children("*", "CollisionShape3D", true, false):
			var shape := found as CollisionShape3D
			if shape.shape is BoxShape3D:
				front = maxf(front, shape.global_position.z + (shape.shape as BoxShape3D).size.z / 2.0)
	_check(edge_points > 0 and gaps == 0 and PLATFORM.end.y - front >= 34.95,
		("E6: the fence and the walls close the yard but for the gate (%d of %d points along "
		+ "its edge open), and the court is %.1f m deep") % [gaps, edge_points,
		PLATFORM.end.y - front])
	var rails := shed.find_children("WalkwayRail*", "MeshInstance3D", true, false)
	var railed := not rails.is_empty()
	for found in rails:
		var part := found as MeshInstance3D
		var box: AABB = part.global_transform * part.get_aabb()
		railed = railed and box.position.x > -90.5 and box.end.x < -89.9 \
			and box.position.z < 22.0 and box.end.z > 41.5 \
			and found.find_children("*", "CollisionShape3D", true, false).size() > 0
	_check(railed, "E6: a solid rail runs between the walkway and the court, from the office")
	var words: Array[String] = []
	for found in shed.find_children("*", "Label3D", true, false):
		words.append((found as Label3D).text)
	var missing := YARD_SIGNS.filter(func(sign: String) -> bool: return not words.has(sign))
	for number in range(1, 10):
		if not words.has(str(number)):
			missing.append("bay %d" % number)
	var lines := shed.find_children("BayLine*", "MeshInstance3D", true, false).size()
	_check(missing.is_empty() and lines >= 10,
		"E7: the yard carries its bay lines (%d of 10), numbers and signs (missing: %s)" % [lines,
		", ".join(missing)])
	var placed := {"TrailerBay": Rect2(-38.8, 3.9, 10.4, 14.2),
		"CarBay": Rect2(-88.5, 42.3, 5.2, 12.7)}
	var astray: Array[String] = []
	for prefix: String in placed:
		var found_lines := shed.find_children(prefix + "*", "MeshInstance3D", true, false)
		if found_lines.is_empty():
			astray.append(prefix)
		for found in found_lines:
			var box: AABB = (found as MeshInstance3D).global_transform \
				* (found as MeshInstance3D).get_aabb()
			if not (placed[prefix] as Rect2).grow(0.1).encloses(Rect2(box.position.x,
					box.position.z, box.size.x, box.size.z)):
				astray.append(String(found.name))
	_check(astray.is_empty(), "E7: the trailer bays stand beside the shed's east wall and the "
		+ "car bays beside the walkway (astray: %s)" % ", ".join(astray))
	_check_arrows(shed)
	var yard := shed.get_node_or_null("Yard")
	var signs: Array[Node] = yard.find_children("Sign*", "Node3D", false, false) \
		if yard != null else []
	var solid := signs.filter(func(sign: Node) -> bool:
		return sign.find_children("*", "CollisionShape3D", true, false).size() > 0)
	_check(not signs.is_empty() and solid.size() == signs.size(),
		"Every yard sign stands on a solid post (%d of %d)" % [solid.size(), signs.size()])
	var in_drive := signs.filter(func(sign: Node) -> bool:
		var at := (sign as Node3D).global_position
		return DRIVE.has_point(Vector2(at.x, at.z)))
	_check(not signs.is_empty() and in_drive.is_empty(),
		"No sign stands in the drive from the gate to the side yard (%d do)" % in_drive.size())
	_check_way_in(shed)


func _check_way_in(shed: Node3D) -> void:
	var space := shed.get_world_3d().direct_space_state
	var way: Array[Vector3] = [Vector3(-70.0, 1.2, 53.5), Vector3(-70.0, 1.2, 46.0),
		Vector3(-62.0, 1.2, 40.0), Vector3(-41.0, 1.2, 37.5), Vector3(-47.75, 1.2, 22.5)]
	var box := BoxShape3D.new()
	box.size = Vector3(2.4, 1.6, 2.4)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = box
	if _van != null:
		query.exclude = [_van.get_rid()]
	var blocked: Array[String] = []
	for index in range(way.size() - 1):
		var steps := int(way[index].distance_to(way[index + 1]) / 0.5)
		for step in range(steps + 1):
			query.transform = Transform3D(Basis.IDENTITY, way[index].lerp(way[index + 1],
				float(step) / steps))
			for hit in space.intersect_shape(query, 4):
				var collider := hit["collider"] as Node
				var named := String(collider.name) if collider != null else "?"
				if not blocked.has(named):
					blocked.append(named)
	_check(blocked.is_empty(), "The van's way in, right, then back onto bay 9 is clear of "
		+ "anything solid (blocked by: %s)" % ", ".join(blocked))


func _check_arrows(shed: Node3D) -> void:
	var north := false
	var east := Rect2()
	var west := Rect2()
	for found in shed.find_children("Arrow*", "MeshInstance3D", true, false):
		var arrow := found as MeshInstance3D
		var box: AABB = arrow.global_transform * arrow.get_aabb()
		var area := Rect2(box.position.x, box.position.z, box.size.x, box.size.z)
		var points := arrow.global_basis.x.normalized()
		if points.dot(Vector3.FORWARD) > 0.99 and GATE_LANE.encloses(area):
			north = true
		elif points.dot(Vector3.RIGHT) > 0.99 and DRIVE.encloses(area):
			east = area
		elif points.dot(Vector3.LEFT) > 0.99 and DRIVE.encloses(area):
			west = area
	var kept_right := east.has_area() and west.has_area() and west.end.y <= east.position.y
	_check(north and kept_right, ("The arrows lead in north from the gate, then east, and out "
		+ "west to the gate, each on its own right-hand side (north %s, east %s, west %s)")
		% [north, east.has_area(), west.has_area()])


func _yard_spots() -> Array[Vector2]:
	var spots: Array[Vector2] = []
	for z in range(int(PLATFORM.position.y), int(PLATFORM.end.y)):
		for x in range(int(PLATFORM.position.x), int(PLATFORM.end.x)):
			var spot := Vector2(x + 0.5, z + 0.5)
			if not SHED.has_point(spot):
				spots.append(spot)
	return spots


func _in_booth(booth: Node3D, size: Vector3, path: String) -> Node3D:
	if booth == null:
		return null
	var node := booth.get_node_or_null(path) as Node3D
	if node == null:
		return null
	var local := booth.to_local(node.global_position)
	return node if absf(local.x) < size.x / 2.0 and absf(local.z) < size.z / 2.0 else null


func _bone_at(skeleton: Skeleton3D, bone: String) -> Vector3:
	var index := skeleton.find_bone(bone)
	if index < 0:
		return Vector3.INF
	return skeleton.global_transform * skeleton.get_bone_global_pose(index).origin


func _on_guard_pose(skeleton: Skeleton3D, head: int) -> void:
	_head_pose = skeleton.global_transform * skeleton.get_bone_global_pose(head)


func _island_part(node: Node) -> bool:
	var at := node
	for _step in range(3):
		if at == null:
			return false
		var named := String(at.name)
		if named.begins_with("Island") or named.begins_with("Kerb") or named.begins_with("Bollard"):
			return true
		at = at.get_parent()
	return false


func _watch_gate(shed: Node3D) -> void:
	_gate_shed = shed
	_gate_frames = 0
	_gate_hits = 0
	_gate_contacts = 0
	while _gate_shed == shed and is_instance_valid(shed):
		await physics_frame
		if not is_instance_valid(_van):
			return
		_gate_frames += 1
		for index in range(_van.get_slide_collision_count()):
			var contact := _van.get_slide_collision(index)
			if contact != null and _island_part(contact.get_collider() as Node):
				_gate_contacts += 1
		var gate_z: float = shed.get("GATE_Z")
		var front := _van.to_global(VAN_FRONT).z
		var rear := _van.to_global(VAN_REAR).z
		if front < gate_z - 0.05 and rear > gate_z + 0.05 and float(shed.call("barrier_angle")) < 80.0:
			_gate_hits += 1


func _hold(code: Key, seconds: float) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await _seconds(seconds)
	var release := event.duplicate() as InputEventKey
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame


func _detail() -> String:
	var label: Variant = _hud.get("_detail")
	return (label as Label).text if label is Label else ""


func _screen() -> String:
	return String(_menu.call("screen"))


func _focus() -> String:
	var owner := root.gui_get_focus_owner()
	return String(owner.name) if owner != null else "(nothing)"


func _text_of(name: String) -> String:
	var node := _menu.find_child(name, true, false)
	return (node as Label).text if node is Label else ""


func _eyebrow() -> String:
	var label: Variant = _hud.get("_eyebrow")
	return (label as Label).text if label is Label else "(no mission name on the screen)"


func _objective() -> String:
	return (_hud.get("_objective") as Label).text


func _key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await process_frame
	await process_frame


func _seconds(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _build() -> void:
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	_hud = _app.get_node("DrivingHud")
	_route = _app.get_node("DrivingTrial")
	_van = _app.get_node("FreightVan")
	_menu = _hud.get("menu")
	await process_frame
	await process_frame


func _free_app() -> void:
	_app.queue_free()
	paused = false
	await process_frame
	await process_frame


func _store(text: String) -> void:
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _remove() -> void:
	for suffix in ["", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(_scratch + suffix):
			DirAccess.remove_absolute(_scratch + suffix)


func _timeout() -> void:
	_check(false, "The Mission 2 checks finish within 170 s")
	_finish()


func _finish() -> void:
	print("MISSION TWO RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	quit(1 if _failures > 0 else 0)
