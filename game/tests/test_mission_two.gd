extends SceneTree

const CARGO := "res://features/missions/the_wrong_cargo/the_wrong_cargo.gd"
const AT_THE_YARD := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=2\n"
const LOADED := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=1\n"
const START_SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const VAN_FRONT := Vector3(0.0, 1.0, -2.52)
const VAN_REAR := Vector3(0.0, 1.0, 3.01)
const SIDE_YARD := Rect2(-53.0, 30.0, 26.0, 25.0)
const YARD_INSIDE: Array[Rect2] = [Rect2(-89.0, 37.5, 62.0, 17.5), Rect2(-53.0, 30.0, 26.0, 8.0)]
const FENCE_ENDS: Array[Vector2] = [Vector2(-89.0, 37.5), Vector2(-53.0, 30.0),
	Vector2(-74.46, 55.0), Vector2(-67.3, 55.0)]
const YARD_SIGNS: Array[String] = ["5 MPH", "HI-VIS BEYOND THIS POINT", "STAFF PARKING ONLY",
	"NO PARKING"]
const GATE_LANE := Rect2(-74.0, 51.9, 6.0, 3.1)
const DRIVE := Rect2(-74.0, 51.9, 21.0, 3.1)

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
	var start: Transform3D = _cargo.get("START", Transform3D())
	var off := Vector2(_van.global_position.x - start.origin.x,
		_van.global_position.z - start.origin.z).length()
	_check(named == "The Wrong Cargo · The container yard" and not paused
		and bool(_van.get("occupied")) and off < 0.5 and _eyebrow() == "THE WRONG CARGO",
		("Continue from Mission 2's third checkpoint names it (%s) and starts Mission 2 where its "
		+ "places stand today: Ethan in his van at the depot bay (%.2f m off), the screen headed "
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
	var window := shed.get_node_or_null("GuardBooth/ServiceWindow") as Node3D
	var line_z: float = gate_z + float(shed.get("STOP_LINE_OUT"))
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
	await _key(KEY_E)
	await _seconds(1.0)
	_check(bool(_van.get("occupied")) and not bool(shed.call("barrier_open")),
		"E at the gate hands the guard the run sheet instead of leaving the van; the barrier "
		+ "waits for the guard's check")
	await _seconds(1.5)
	var lowered := float(_van.get("left_window"))
	_check(lowered > 0.9, "E lowers the driver's window, because the sheet goes through it "
		+ "(%.2f open)" % lowered)
	await _seconds(6.5)
	_check(bool(shed.call("barrier_open")),
		"After the check the barrier is up within 8 s")
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
		var seat := chair.get_node_or_null("Seat") as MeshInstance3D
		if seat != null and seat.mesh is BoxMesh:
			above = hips.y - seat.global_position.y - (seat.mesh as BoxMesh).size.y / 2.0
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
		var cabinet_west := cabinet.global_position.x - 0.16
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
	_check(sampled > 0 and bare == 0, ("D1: the yard is paved everywhere inside the fence: "
		+ "%d of %d points between the fence and the shed unpaved") % [bare, sampled])
	var ends: Array[Vector2] = []
	var inside := 0
	var fence := shed.get_node_or_null("Fence")
	if fence != null:
		for child in fence.get_children():
			var shape := child as CollisionShape3D
			if shape == null or not shape.shape is BoxShape3D:
				continue
			var half := (shape.shape as BoxShape3D).size.x / 2.0
			var along := shape.global_basis.x.normalized() * half
			for end: Vector3 in [shape.global_position - along, shape.global_position + along]:
				ends.append(Vector2(end.x, end.z))
			var middle := Vector2(shape.global_position.x, shape.global_position.z)
			var within := func(rect: Rect2) -> bool: return rect.grow(-0.5).has_point(middle)
			if YARD_INSIDE.any(within):
				inside += 1
	var loose := 0
	for end in ends:
		var meets := ends.filter(func(other: Vector2) -> bool: return other.distance_to(end) < 0.1)
		var held := FENCE_ENDS.any(func(post: Vector2) -> bool: return post.distance_to(end) < 0.6)
		if meets.size() < 2 and not held:
			loose += 1
	_check(not ends.is_empty() and loose == 0 and inside == 0,
		("D2: the fence closes the yard: %d loose ends (gaps over 0.1 m), %d fence runs inside the "
		+ "yard") % [loose, inside])
	var terrain: Node3D = world.get("terrain")
	var forest: Node3D = world.get("forest")
	var worst := 0.0
	var wooded := 0
	for spot in _yard_spots():
		if SIDE_YARD.has_point(spot):
			worst = maxf(worst, absf(float(terrain.call("height_at", spot.x, spot.y))))
		if forest != null and not bool(forest.call("_is_blocked", spot.x, spot.y)):
			wooded += 1
	_check(worst <= 0.02 and wooded == 0, ("D3: the side yard is level (%.2f m at worst) and no "
		+ "tree may stand inside the fence (%d open spots)") % [worst, wooded])
	var rails := shed.find_children("WalkwayRail*", "MeshInstance3D", true, false)
	var railed := not rails.is_empty()
	for found in rails:
		var part := found as MeshInstance3D
		var box: AABB = part.global_transform * part.get_aabb()
		railed = railed and box.position.x > -87.0 and box.end.x < -86.0 \
			and box.position.z < 42.0 and box.end.z > 53.0 \
			and found.find_children("*", "CollisionShape3D", true, false).size() > 0
	_check(railed, "D6: a solid rail runs between the walkway and the lane, along the walkway")
	var words: Array[String] = []
	for found in shed.find_children("*", "Label3D", true, false):
		words.append((found as Label3D).text)
	var missing := YARD_SIGNS.filter(func(sign: String) -> bool: return not words.has(sign))
	var lines := shed.find_children("BayLine*", "MeshInstance3D", true, false).size()
	_check(missing.is_empty() and lines >= 4,
		"The yard carries its bay lines (%d) and its signs (missing: %s)" % [lines,
		", ".join(missing)])
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
	for z in range(41, 55):
		for x in range(-88, -53):
			spots.append(Vector2(x + 0.5, z + 0.5))
	for z in range(31, 55):
		for x in range(-52, -27):
			spots.append(Vector2(x + 0.5, z + 0.5))
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
