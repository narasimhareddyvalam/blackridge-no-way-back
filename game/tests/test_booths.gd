extends SceneTree
## Mission 2's guard booths as real gatehouses are (the audit, #348, after suppliers' photos): one
## booth shared by the transfer shed and the compound; a half-glazed steel door on the face away
## from the lane, its handle at hand height; every pane in an aluminium frame, the service window a
## framed pane that slides open in its track and back; inside an LED panel in its frame, a heater,
## a phone with its handset, a logbook with ruled pages, a radio; outside a wall air conditioner,
## a lamp over the door, a camera on the roof's corner watching the lane, a fascia and a downpipe.
## The sash moves only under the guard's hand (#348, the author's "the window is sliding without
## the guard reaching the window"): she leans in from her chair, takes its pull with her left hand
## and slides it, her hand on the pull all the way, her elbow bent and her wrist natural; she
## stays seated. Where he looks, as a guard does (#348, "why is he looking at the same location"):
## at his hand on the pull while he slides it, at the driver as the window opens and the sheet
## comes through, then where his gate has him look (the logbook as he checks); at the pull again
## shutting it, then a glance at the van leaving, then back.

const Booth = preload("res://features/environments/industrial_loop/guard_booth.gd")
const DOOR_WIDE := Vector2(0.8, 0.95)
const DOOR_TALL := Vector2(1.95, 2.1)
const HANDLE_AT := Vector2(0.9, 1.1)
const FRAME_FACE := Vector2(0.035, 0.075)
const SLIDES_LEAST := 0.4
const AC_OUT := Vector2(0.3, 0.55)
const ART := "res://features/environments/industrial_loop/art/booth/models/%s/%s.gltf"
const AIRCON := "exterior_aircon_unit"
const CAMERA := "security_camera_01"
## The kit, the real models (Poly Haven, CC0), each resting where it belongs: on the counter, on
## a wall, or as stated.
const KIT := {"WallClock": "wall_clock", "Notepads": "office_notepads",
	"Thermos": "modified_thermos", "FirstAid": "medical_box", "Monitor": "dell_monitor",
	"Keyboard": "keyboard", "Mouse": "mouse", "Phone": "desk_phone", "Radio": "walkie_talkie",
	"AcIndoor": "ac_indoor_unit"}
const ON_COUNTER: Array[String] = ["Notepads", "Thermos", "PencilCup", "Monitor", "Keyboard",
	"Mouse", "Phone"]
const ON_WALL: Array[String] = ["WallClock", "FirstAid", "AcIndoor"]
const REST_NEAR := 0.02
## The counter's top in the booth's frame (x, z): 0.55 deep against the window, 1.6 long; two
## items on it may touch (0.0004 m² shared at most), and only the monitor's screen may stand over
## another (its foot is all that meets the counter).
const COUNTER := Rect2(0.6, -0.8, 0.55, 1.6)
const OVERLAP_MOST := 0.0004
## The counter's back half, before the window, along the opening: where the sheet passes.
const HANDOVER_FROM := 0.9
const GRIP_NEAR := 0.03
const ELBOW := Vector2(70.0, 160.0)
const WRIST_MOST := 60.0
const ARM := ["Bip01 L UpperArm", "Bip01 L Forearm", "Bip01 L Hand", "Bip01 L Finger2",
	"Bip01 L Finger21"]
const LEAN_MOST := 25.0
const HAND_FASTEST := 2.0
## The run's fixed frame rate (`scripts/run-test.sh ... 60`): one pose a frame.
const FRAMES_PER_SECOND := 60.0
const TOE_CLEAR := 0.03
## The opening the sash leaves, 0.5 m wide, centred where the stop line puts the driver's eye.
const OPENING_WIDE := 0.45
const LOOK_NEAR := 0.05
## A person turning to someone beside him turns his shoulders part of the way; the neck turns some
## 70-80 degrees at most.
const TWIST := Vector2(12.0, 35.0)
const NECK_MOST := 75.0
const GREET_LEAST := 1.0
## Someone beside the guard, to his right through the side glass (a van drawing up behind the
## booth's line), whom he turns to.
const BESIDE_AT := Vector3(0.6, 1.6, 3.0)
const INSIDE: Array[String] = ["LedFrame", "Heater", "Phone", "Logbook", "Radio"]

var _checks := 0
var _failures := 0
var _app: Node3D
var _scratch: String
var _samples: Array[Dictionary] = []
var _skeleton: Skeleton3D
var _pull: Node3D


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(120.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-booths-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	_app.call("_resume")
	await physics_frame
	var world := _app.get_node("IndustrialLoop")
	var booths := {"shed": world.get("transfer_shed").get_node_or_null("GuardBooth"),
		"compound": world.get("compound").get_node_or_null("GuardBooth")}
	var shared := booths.values().all(func(booth: Variant) -> bool:
		return booth != null and (booth as Node).get_script() == Booth)
	_check(shared, "B1: the shed's and the compound's booths are one booth (guard_booth.gd)")
	for label: String in booths:
		var booth := booths[label] as Node3D
		if booth == null or booth.get_script() != Booth:
			continue
		_door(label, booth)
		_frames(label, booth)
		await _sliding(label, booth)
		await _hand_on_sash(label, booth)
		await _gaze(label, booth)
		_inside(label, booth)
		_outside(label, booth)
		_kit(label, booth)
	_finish()


func _mesh_box(mesh: MeshInstance3D, frame: Node3D) -> AABB:
	return frame.global_transform.affine_inverse() * mesh.global_transform * mesh.get_aabb()


func _window_normal(booth: Node3D) -> Vector3:
	return booth.global_basis.x.normalized()


func _door(label: String, booth: Node3D) -> void:
	var door := booth.get_node_or_null("Door") as Node3D
	var leaves: Array[MeshInstance3D] = []
	if door != null:
		for child in door.get_children():
			if child is MeshInstance3D and String(child.name).begins_with("Leaf"):
				leaves.append(child)
	var vision := door.get_node_or_null("GlassDoor") as MeshInstance3D if door != null else null
	var handle := door.get_node_or_null("DoorHandle") as MeshInstance3D if door != null else null
	var size := Vector3.ZERO
	var away := 0.0
	var height := INF
	if not leaves.is_empty():
		var whole := _mesh_box(leaves[0], door)
		for leaf in leaves:
			whole = whole.merge(_mesh_box(leaf, door))
		size = whole.size
		away = door.global_basis.z.normalized().dot(_window_normal(booth))
	if handle != null:
		height = booth.to_local(handle.global_position).y - Booth.PLINTH
	var see_through := vision != null and vision.material_override is StandardMaterial3D \
		and (vision.material_override as StandardMaterial3D).transparency \
		!= BaseMaterial3D.TRANSPARENCY_DISABLED
	_check(size.x >= DOOR_WIDE.x and size.x <= DOOR_WIDE.y and size.y >= DOOR_TALL.x
		and size.y <= DOOR_TALL.y and away < -0.9 and see_through
		and height >= HANDLE_AT.x and height <= HANDLE_AT.y, ("B2 (%s): a half-glazed door "
		+ "%.2f x %.2f m on the face away from the lane (%.2f), its handle %.2f m up")
		% [label, size.x, size.y, away, height])


func _frames(label: String, booth: Node3D) -> void:
	var panes: Array[MeshInstance3D] = []
	for child in booth.find_children("*", "MeshInstance3D", true, false):
		var named := String(child.name)
		if named.begins_with("Glass") or named == "ServiceWindow":
			panes.append(child)
	var framed := 0
	for pane in panes:
		var frame := pane.get_parent().get_node_or_null(String(pane.name) + "Frame")
		if frame == null:
			continue
		var members := frame.find_children("*", "MeshInstance3D", true, false)
		var faces := members.all(func(member: MeshInstance3D) -> bool:
			var box := member.get_aabb().size
			var face := minf(box.x, box.y)
			return face >= FRAME_FACE.x and face <= FRAME_FACE.y)
		if members.size() >= 4 and faces:
			framed += 1
	_check(panes.size() >= 5 and framed == panes.size(), ("B3 (%s): every pane in an aluminium "
		+ "frame of head, sill and jambs %.0f-%.0f mm across (%d of %d)")
		% [label, FRAME_FACE.x * 1000.0, FRAME_FACE.y * 1000.0, framed, panes.size()])


func _sliding(label: String, booth: Node3D) -> void:
	var pane := booth.find_child("ServiceWindow", true, false) as Node3D
	if pane == null or not booth.has_method("open_window"):
		_check(false, "B4 (%s): the service window slides open in its track and back" % label)
		return
	var shut := booth.to_local(pane.global_position)
	booth.call("open_window", true)
	await create_timer(3.0, true, false, true).timeout
	var opened := booth.to_local(pane.global_position)
	booth.call("open_window", false)
	await create_timer(3.0, true, false, true).timeout
	var back := booth.to_local(pane.global_position)
	var span: Vector2 = booth.call("opening_span") if booth.has_method("opening_span") \
		else Vector2.ZERO
	var centre := (span.x + span.y) * 0.5 - booth.global_position.z
	var wanted: Variant = (Booth as GDScript).get_script_constant_map().get("OPENING_AT")
	_check(wanted != null and span.y - span.x >= OPENING_WIDE
		and absf(centre - float(wanted)) < 0.01, ("B14 (%s): open, the sash leaves %.2f m clear "
		+ "about where the stop line puts the driver's eye (%.2f m along the booth)")
		% [label, span.y - span.x, centre])
	var slid := absf(opened.z - shut.z)
	_check(slid >= SLIDES_LEAST and absf(opened.x - shut.x) < 0.001
		and absf(opened.y - shut.y) < 0.001 and back.distance_to(shut) < 0.001, ("B4 (%s): the "
		+ "service window slides %.2f m along its track, staying in it, and shuts again")
		% [label, slid])


func _hand_on_sash(label: String, booth: Node3D) -> void:
	var guard := booth.get("guard") as Node3D
	_pull = booth.find_child("SashPull", true, false) as Node3D
	var skeletons := guard.find_children("*", "Skeleton3D", true, false) if guard != null else []
	if _pull == null or skeletons.is_empty():
		_check(false, "B7 (%s): the sash moves only under her hand" % label)
		return
	_skeleton = skeletons[0] as Skeleton3D
	var seated_at := guard.global_position
	_samples.clear()
	_skeleton.skeleton_updated.connect(_sample)
	for open in [true, false]:
		booth.call("open_window", open)
		await create_timer(4.0, true, false, true).timeout
	_skeleton.skeleton_updated.disconnect(_sample)
	var moving := 0
	var far := 0.0
	var elbow := Vector2(INF, -INF)
	var wrist := 0.0
	var reached_first := false
	for index in range(1, _samples.size()):
		var now := _samples[index]
		if absf(float(now.sash) - float(_samples[index - 1].sash)) < 0.00001:
			continue
		moving += 1
		far = maxf(far, float(now.grip))
		elbow = Vector2(minf(elbow.x, float(now.elbow)), maxf(elbow.y, float(now.elbow)))
		wrist = maxf(wrist, float(now.wrist))
		if moving == 1:
			reached_first = float(_samples[index - 1].grip) <= GRIP_NEAR
	_check(moving > 20 and far <= GRIP_NEAR and reached_first, ("B7 (%s): the sash moves only "
		+ "under her left hand: over %d moving ticks her grip never %.0f cm from its pull (%.1f cm "
		+ "at most), her hand on it before it starts") % [label, moving, GRIP_NEAR * 100.0,
		far * 100.0])
	var fastest := 0.0
	var raised := -INF
	for index in range(1, _samples.size()):
		fastest = maxf(fastest, (_samples[index].hand as Vector3).distance_to(
			_samples[index - 1].hand) * FRAMES_PER_SECOND)
		raised = maxf(raised, float(_samples[index].elbow_up))
	_check(elbow.x >= ELBOW.x and elbow.y <= ELBOW.y and wrist <= WRIST_MOST and raised <= 0.02,
		("B8 (%s): sliding it her elbow bends %.0f-%.0f degrees, hangs below her reach (%.2f m at "
		+ "most above it) and her wrist turns %.0f degrees at most")
		% [label, elbow.x, elbow.y, raised, wrist])
	_check(fastest <= HAND_FASTEST, ("B11 (%s): her hand moves at a person's pace, %.1f m/s at "
		+ "most") % [label, fastest])
	var lean := booth.find_child("GuardLean", true, false)
	var leaned := rad_to_deg(float(lean.get("angle"))) if lean != null else INF
	var inner := Booth.SIZE.x / 2.0 - 0.05
	var toes := -INF
	for bone in ["Bip01 L Toe0", "Bip01 R Toe0"]:
		var at := _skeleton.global_transform * _skeleton.get_bone_global_pose(
			_skeleton.find_bone(bone)).origin
		toes = maxf(toes, booth.to_local(at).x)
	_check(leaned <= LEAN_MOST and toes <= inner - TOE_CLEAR, ("B10 (%s): her chair in as a "
		+ "person pulls hers in, so she leans only %.0f degrees to reach, her toes %.2f m clear of "
		+ "the front wall") % [label, leaned, inner - toes])
	var released := not _samples.is_empty() and float(_samples[-1].grip) > 0.1
	_check(guard.global_position.distance_to(seated_at) < 0.001 and released, ("B9 (%s): she "
		+ "stays seated and lets go after (her grip %.2f m from the pull at the end)")
		% [label, float(_samples[-1].grip) if not _samples.is_empty() else 0.0])


## His gaze over the window's opening and shutting, against what his gate hands his booth each
## tick: the driver it knows (Ethan's eye, or a marker when it knows none) and where it has him look.
func _gaze(label: String, booth: Node3D) -> void:
	var look := booth.find_child("GuardLook", true, false) as Node3D
	var pull := booth.find_child("SashPull", true, false) as Node3D
	var stand_in := Marker3D.new()
	booth.add_child(stand_in)
	if look == null or pull == null or not "driver" in booth:
		_check(false, "B12 (%s): his gaze follows what he does" % label)
		stand_in.queue_free()
		return
	var gate := booth.get_parent()
	var was: Variant = gate.get("driver_eye")
	stand_in.position = BESIDE_AT
	gate.set("driver_eye", stand_in)
	booth.set("driver", stand_in)
	var phases := {"slide": [0, 0], "greet": 0.0, "back": false, "glance": 0.0, "twist": 0.0}
	var twist := booth.find_child("GuardTwist", true, false)
	for open in [true, false]:
		booth.call("open_window", open)
		var last := pull.global_position
		var settled := 0.0
		var on_driver := 0.0
		for frame in range(int(6.0 * FRAMES_PER_SECOND)):
			await process_frame
			var moving := pull.global_position.distance_to(last) > 0.00001
			last = pull.global_position
			var target := look.global_position
			var driver := booth.get("driver") as Node3D
			var wanted: Vector3 = booth.get("_wanted_look")
			if moving:
				phases.slide[1] += 1
				if target.distance_to(pull.global_position) <= LOOK_NEAR:
					phases.slide[0] += 1
				settled = 0.0
				continue
			settled += 1.0 / FRAMES_PER_SECOND
			if settled > 0.1 and is_instance_valid(driver) \
					and target.distance_to(driver.global_position) <= LOOK_NEAR:
				on_driver += 1.0 / FRAMES_PER_SECOND
				if twist != null and on_driver > 0.8:
					phases.twist = maxf(phases.twist, absf(rad_to_deg(float(twist.get("angle")))))
			if settled > 2.6 and target.distance_to(wanted) <= LOOK_NEAR:
				phases.back = true
		phases["greet" if open else "glance"] = on_driver
	gate.set("driver_eye", was)
	stand_in.queue_free()
	var head := booth.find_child("GuardHead", true, false) as LookAtModifier3D
	var neck := head != null and head.use_angle_limitation \
		and rad_to_deg(head.primary_limit_angle) <= NECK_MOST
	_check(neck and phases.twist >= TWIST.x and phases.twist <= TWIST.y, ("B15 (%s): turning to "
		+ "the driver beside him his body turns too (%.0f degrees), his head no further than a "
		+ "neck turns (limited: %s)") % [label, phases.twist, neck])
	var watched: bool = phases.slide[1] > 20 and phases.slide[0] == phases.slide[1]
	_check(watched and phases.greet >= GREET_LEAST and phases.glance >= GREET_LEAST
		and phases.back, ("B12 (%s): he watches his hand on the pull while sliding (%d of %d "
		+ "ticks), looks at the driver as it opens (%.1f s) and at the van as it shuts (%.1f s), "
		+ "then back where his gate has him look (%s)") % [label, phases.slide[0],
		phases.slide[1], phases.greet, phases.glance, phases.back])


func _sample() -> void:
	var at: Array[Vector3] = []
	for bone in ARM:
		at.append(_skeleton.global_transform * _skeleton.get_bone_global_pose(
			_skeleton.find_bone(bone)).origin)
	var grip := (at[3] + at[4]) * 0.5
	var line := at[0].lerp(at[2], clampf((at[1] - at[0]).dot(at[2] - at[0])
		/ maxf((at[2] - at[0]).length_squared(), 0.0001), 0.0, 1.0))
	_samples.append({"sash": _pull.global_position.z, "grip": grip.distance_to(
		_pull.global_position), "elbow": rad_to_deg((at[0] - at[1]).angle_to(at[2] - at[1])),
		"wrist": rad_to_deg((at[2] - at[1]).angle_to(at[3] - at[2])), "hand": at[2],
		"elbow_up": at[1].y - line.y})


func _inside(label: String, booth: Node3D) -> void:
	var half := Booth.SIZE * 0.5
	var missing: Array[String] = []
	for name in INSIDE:
		var found := booth.find_child(name, true, false) as Node3D
		var at := booth.to_local(found.global_position) if found != null else Vector3.INF
		if found == null or absf(at.x) > half.x or absf(at.z) > half.z or at.y > Booth.SIZE.y:
			missing.append(name)
	var page := booth.find_child("LogPage", true, false) as MeshInstance3D
	var ruled := page != null and page.material_override is StandardMaterial3D \
		and (page.material_override as StandardMaterial3D).albedo_texture != null
	_check(missing.is_empty() and ruled, ("B5 (%s): inside, the LED panel's frame, a heater, a "
		+ "phone and its handset, a logbook with ruled pages and a radio (missing %s)")
		% [label, missing])


func _outside(label: String, booth: Node3D) -> void:
	var half := Booth.SIZE * 0.5
	var unit := booth.find_child("AirConditioner", true, false) as Node3D
	var out := 0.0
	if unit != null and _model(unit) == AIRCON:
		var box := _node_box(unit, booth)
		out = maxf(maxf(box.end.x - half.x, -half.x - box.position.x),
			maxf(box.end.z - half.z, -half.z - box.position.z))
	var lamp := booth.find_child("DoorLamp", true, false) as OmniLight3D
	var door := booth.get_node_or_null("Door") as Node3D
	var over_door := lamp != null and door != null and not lamp.shadow_enabled \
		and booth.to_local(lamp.global_position).y > Booth.SIZE.y - 0.5 \
		and Vector2(booth.to_local(lamp.global_position).x, booth.to_local(lamp.global_position).z) \
		.distance_to(Vector2(booth.to_local(door.global_position).x,
		booth.to_local(door.global_position).z)) < 0.6
	var camera := booth.find_child("Cctv", true, false) as Node3D
	var watching := camera != null and _model(camera) == CAMERA \
		and booth.to_local(camera.global_position).y >= Booth.SIZE.y \
		and (-camera.global_basis.z).normalized().dot(_window_normal(booth)) > 0.5
	var pipe := booth.find_child("Downpipe", true, false) as MeshInstance3D
	var drains := pipe != null and _mesh_box(pipe, booth).position.y <= Booth.PLINTH + 0.1 \
		and _mesh_box(pipe, booth).end.y >= Booth.SIZE.y - 0.1
	var fascia := booth.find_child("Fascia", true, false) != null
	_check(out >= AC_OUT.x and out <= AC_OUT.y and over_door and watching and drains and fascia,
		("B6 (%s): outside, an air conditioner %.2f m out of the wall, a lamp over the door "
		+ "(%s), a camera on the roof's corner watching the lane (%s), a downpipe from the roof "
		+ "(%s) and a fascia (%s)") % [label, out, over_door, watching, drains, fascia])


## The Poly Haven model a kit node holds (its scene's name), or "".
func _model(node: Node) -> String:
	for child in node.find_children("*", "Node3D", true, false) + [node]:
		var path := String((child as Node).scene_file_path)
		if path.begins_with("res://features/environments/industrial_loop/art/booth/models/"):
			return path.get_file().get_basename()
	return ""


func _node_box(node: Node3D, frame: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		if not mesh.is_visible_in_tree():
			continue
		var part := _mesh_box(mesh, frame)
		box = part if first else box.merge(part)
		first = false
	return box


func _kit(label: String, booth: Node3D) -> void:
	var wrong: Array[String] = []
	var half := Booth.SIZE * 0.5
	var top := Booth.PLINTH + Booth.COUNTER_HEIGHT
	var footprints := {}
	for name: String in KIT.keys() + ["PencilCup"]:
		var node := booth.find_child(name, true, false) as Node3D
		if node == null or (KIT.has(name) and _model(node) != KIT[name]):
			wrong.append(name + " (not the model)")
			continue
		var box := _node_box(node, booth)
		if ON_COUNTER.has(name) and absf(box.position.y - top) > REST_NEAR:
			wrong.append("%s %.3f m off the counter" % [name, box.position.y - top])
		if ON_WALL.has(name):
			var inner := half - Vector3(Booth.WALL * 0.55 + 0.01, 0, Booth.WALL * 0.55 + 0.01)
			var gap := minf(minf(absf(box.position.x + inner.x), absf(box.end.x - inner.x)),
				minf(absf(box.position.z + inner.z), absf(box.end.z - inner.z)))
			if gap > REST_NEAR:
				wrong.append("%s %.3f m off the wall" % [name, gap])
		if absf(box.get_center().x) > half.x or absf(box.get_center().z) > half.z:
			wrong.append(name + " outside")
		if ON_COUNTER.has(name):
			var on := Rect2(COUNTER.position - Vector2.ONE * REST_NEAR,
				COUNTER.size + Vector2.ONE * REST_NEAR * 2.0)
			if not on.encloses(Rect2(box.position.x, box.position.z, box.size.x, box.size.z)):
				wrong.append(name + " off the counter's edge")
			footprints[name] = Rect2(box.position.x, box.position.z, box.size.x, box.size.z)
	var names: Array = footprints.keys()
	for first in range(names.size()):
		for second in range(first + 1, names.size()):
			var shared: Rect2 = footprints[names[first]].intersection(footprints[names[second]])
			if shared.get_area() > OVERLAP_MOST and not _screen_over(names[first], names[second]):
				wrong.append("%s on %s" % [names[first], names[second]])
	var opening: Vector2 = booth.call("opening_span") if booth.has_method("opening_span") \
		else Vector2.ZERO
	var along := opening - Vector2.ONE * booth.global_position.z
	var handover := Rect2(HANDOVER_FROM, along.x, COUNTER.end.x - HANDOVER_FROM,
		along.y - along.x)
	var blocking: Array[String] = []
	for name: String in footprints:
		if (footprints[name] as Rect2).intersects(handover):
			blocking.append(name)
	_check(along.y > along.x and blocking.is_empty(), ("B16 (%s): the counter before the open "
		+ "window is kept clear, where the sheet passes (in the way: %s)") % [label, blocking])
	_check(wrong.is_empty(), ("B13 (%s): the kit is real models, each resting where it belongs "
		+ "(a clock, a first-aid case and the air conditioner's head on the walls; the monitor, "
		+ "keyboard, mouse, phone, notepads, a thermos and a pencil cup on the counter; a radio in "
		+ "its charger) (wrong: %s)") % [label, wrong])


func _screen_over(first: String, second: String) -> bool:
	return first == "Monitor" or second == "Monitor"


func _finish() -> void:
	print("BOOTHS RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	_app.queue_free()
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "The booth test finished within 120 s of game time")
	quit(1)
