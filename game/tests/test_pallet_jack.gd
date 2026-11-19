extends SceneTree
## The audit's third fix (docs/PHASE_BRIEF.md, "the pallet jack", #321-#326): bay 9's pallet
## jack in Ethan's hands moves as a real one. Its forks rise with each stroke of the handle, the
## load only once they meet it, while its steer wheels and load rollers stay on the floor, each
## bogie turning about its rollers' middle as its pin rides up in the fork (planned about its
## pin; changed while built, see `_check_parts`); its steering unit swings up to 100-105 degrees
## (a 200-210 degree steering arc) at no more than 120 degrees a second, only as far as he can
## follow it with his walk (#327), and eases back straight when A or D is let go; it turns
## about its load rollers' line, its heading at v·sin(δ)/L,
## so swung right round it pivots about the rollers' middle; every wheel rolls with the floor it
## covers; his hands stay on the handle's loop as it swings. By real key presses from Mission
## 2's start; the van is set docked at bay 9 as setup, as in `test_loading.gd`.

const START_SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const DOCKED := Vector3(-47.75, 0.1, 23.16)
const TO_THE_SIDE_DOOR: Array[Vector3] = [Vector3(-39.0, 0.0, 22.0), Vector3(-39.0, 0.0, 17.5)]
const INTO_THE_SHED: Array[Vector3] = [Vector3(-41.2, 0.0, 17.5), Vector3(-44.2, 0.0, 16.0),
	Vector3(-44.2, 0.0, 14.8), Vector3(-44.2, 0.0, 13.4), Vector3(-45.6, 0.0, 13.4),
	Vector3(-47.2, 0.0, 15.15)]
## The parts a real jack moves, each in the part it rides on, and the point in its own frame
## it turns about (its origin): the twin steer wheels on their axle, each load roller on its
## axle, each bogie about its two rollers' middle (a rigid tandem bogie turned about its pin
## would lift one roller off the floor as the other dug in; turned about their middle, its pin
## rides up in the fork while both rollers stay down).
const PARTS: Array[String] = ["Chassis", "Steering", "Steering/SteerWheels", "Chassis/BogieL",
	"Chassis/BogieR", "Chassis/RollerL1", "Chassis/RollerL2", "Chassis/RollerR1",
	"Chassis/RollerR2"]
const WHEELS: Array[String] = ["Steering/SteerWheels", "Chassis/RollerL1", "Chassis/RollerL2",
	"Chassis/RollerR1", "Chassis/RollerR2"]
const STEER_RADIUS := 0.1055
const ROLLER_RADIUS := 0.049
const ON_FLOOR := 0.005
## The forks' tops lowered (the frame 24 mm under its drawn 115 mm), and how far they rise
## before they meet the load's deck (its underside 0.127 m up) and in all.
const FORK_TOP := 0.115
const LOWERED := 0.091
const MEETS := 0.036
const RAISED := 0.076
const LOAD_CLEAR := 0.04
const SWING := Vector2(100.0, 105.0)
const SWING_RATE := 120.0
const STAND_SWING := 10.0
const SIDE_SHARE := 0.5
const ROLLERS_LINE := -0.513
const ROLLERS_MIDDLE := -0.5135
## Each bogie's pin in its fork and the bogie's own origin there, as the model draws them.
const BOGIE_PIN := Vector3(0.0, 0.0525, -0.3255)
const BOGIE_ORIGIN := Vector3(0.0, 0.073, -0.5135)
const STEER_AXIS := 0.689
const WHEELBASE := 1.202
const LOOP_X := 0.173
const LOOP_Y := Vector2(0.73, 0.85)
const LOOP_Z := 0.0
const UNDER_PALM := 0.03
const ON_LOOP := 0.04
const SETTLED := 24
const HANDS_LET_GO := 56.0
const STROKE := 0.6
const HINT_REFRESH := 0.25

var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _app: Node3D
var _hud: CanvasLayer
var _van: CharacterBody3D
var _driver: CharacterBody3D
var _shed: Node3D
var _rig: Node
var _jack: Node3D
var _skeleton: Skeleton3D
var _bones := {}
var _off_floor := 0.0
var _off_floor_at := ""
var _hand_gap := 0.0
var _hand_at := ""
var _last_clip := ""
var _since_clip: int = 0
var _watching_hands := false
var _last := {}
var _sums := {}
var _round_fastest := 0.0
var _last_swing := 0.0
var _last_driver := Vector3.INF
var _last_pivot := Vector3.ZERO
var _last_pace := 0.0
var _hand_over := 0
var _hand_frames := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(300.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-pallet-jack-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_store(START_SAVE)
	await _build()
	await _key(KEY_ENTER)
	await _seconds(1.0)
	_shed = _app.get_node("IndustrialLoop").get("transfer_shed")
	_rig = _shed.get("pallet_jack")
	_jack = _shed.find_child("PalletJack", true, false) as Node3D
	_van.call("recover", Transform3D(Basis(Vector3.UP, PI), DOCKED))
	await _seconds(1.5)
	await _key(KEY_E)
	await _until(_on_foot, 8.0)
	_check_parts()
	_check_lowered("standing")
	await _walk(TO_THE_SIDE_DOOR)
	await _key(KEY_E)
	await _seconds(1.5)
	await _walk(INTO_THE_SHED)
	_skeleton = _driver.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	for side: String in ["Left", "Right"]:
		for bone: String in ["Arm", "Hand", "HandMiddle1"]:
			var name := "mixamorig_%s%s" % [side, bone]
			_bones[name] = _skeleton.find_bone(name)
	_skeleton.skeleton_updated.connect(_on_pose)
	physics_frame.connect(_on_physics)
	await _key(KEY_E)
	await _seconds(0.5)
	await _check_pumping()
	await _drive("brake", 0.0, 1.6)
	await _check_swing()
	await _check_turns()
	await _check_pivot()
	await _check_lowering()
	_finish()


## P1: the jack cut into the parts a real one moves, each turning about its own pivot: a wheel or
## roller about its axle through its middle, a bogie about its pin.
func _check_parts() -> void:
	var missing: Array[String] = []
	var off: Array[String] = []
	for path in PARTS:
		var part := _jack.get_node_or_null(path) as Node3D
		if part == null:
			missing.append(path)
			continue
		if path in WHEELS:
			var middle := _middle(part)
			if Vector2(middle.y, middle.z).length() > 0.004:
				off.append("%s (%.3f, %.3f)" % [path, middle.y, middle.z])
	var bogie := _jack.get_node_or_null("Chassis/BogieL") as Node3D
	var turns := _jack.to_local(bogie.global_position) if bogie != null else Vector3.INF
	_check(missing.is_empty() and off.is_empty() and absf(turns.z - ROLLERS_MIDDLE) < 0.005,
		("P1: its steer wheels, both bogies and four load rollers cut free, each about its own "
		+ "axle, a bogie about its rollers' middle (missing: %s; off their axles: %s; the "
		+ "bogie's at z %.3f)") % [", ".join(missing), ", ".join(off), turns.z])


## The middle of a part's own mesh, in its own frame.
func _middle(part: Node3D) -> Vector3:
	var box := AABB()
	var first := true
	for found in [part] + part.find_children("*", "MeshInstance3D", true, false):
		var mesh := found as MeshInstance3D
		if mesh == null or mesh.mesh == null:
			continue
		var into := part.global_transform.affine_inverse() * mesh.global_transform
		var piece := into * mesh.mesh.get_aabb()
		box = piece if first else box.merge(piece)
		first = false
	return box.get_center()


## P2: lowered, every steer wheel and load roller on the floor and the forks' tops at 91 mm.
func _check_lowered(when: String) -> void:
	var worst := _wheels_off_floor()
	var top := _fork_rise() + FORK_TOP
	_check(worst <= ON_FLOOR and absf(top - LOWERED) <= 0.003,
		("P2: %s lowered, its steer wheels and load rollers on the floor (the farthest %.4f m "
		+ "off) and its forks' tops %.3f m up (91 mm)") % [when, worst, top])


func _fork_rise() -> float:
	var chassis := _jack.get_node_or_null("Chassis") as Node3D
	return _jack.to_local(chassis.global_position).y if chassis != null else INF


func _wheels_off_floor() -> float:
	var worst := 0.0
	for path in WHEELS:
		var part := _jack.get_node_or_null(path) as Node3D
		if part == null:
			return INF
		var radius := STEER_RADIUS if path.begins_with("Steering") else ROLLER_RADIUS
		worst = maxf(worst, absf(_jack.to_local(part.global_position).y - radius))
	return worst


## P3: each stroke of E raises the forks, the load only once they meet its deck, 40 mm clear at
## the last; the wheels and rollers on the floor throughout.
func _check_pumping() -> void:
	var load := _shed.get_node_or_null("Building/Pallet6") as Node3D
	var floor_y := load.global_position.y
	var forks: Array[float] = []
	var lifted: Array[float] = []
	var strokes := 0
	_off_floor = 0.0
	while _hint() == "E  Pump the handle" and strokes < 10:
		await _key(KEY_E)
		await _seconds(STROKE + HINT_REFRESH)
		strokes += 1
		forks.append(_fork_rise() + FORK_TOP - LOWERED)
		lifted.append(load.global_position.y - floor_y)
	var rising := forks.size() >= 2
	var waited := true
	for index in range(forks.size()):
		if index > 0:
			rising = rising and forks[index] > forks[index - 1] + 0.002
		if forks[index] < MEETS - 0.003:
			waited = waited and lifted[index] < 0.002
	var pinned := _pins_off()
	var met := forks.size() >= 1 and forks[0] < MEETS and not lifted.is_empty() \
		and absf(lifted[-1] - LOAD_CLEAR) <= 0.003 and absf(forks[-1] - RAISED) <= 0.003
	_check(rising and waited and met and _off_floor <= ON_FLOOR and pinned <= 0.01,
		("P3: each stroke raises the forks %s m, the load %s m only once they meet its deck "
		+ "(%.3f m up), %.3f m clear at the last; its wheels and rollers on the floor (%.4f m "
		+ "off, %s), each bogie turned so its pin rides in its fork (%.3f m off)") % [
		_list(forks), _list(lifted), MEETS, lifted[-1] if not lifted.is_empty() else -1.0,
		_off_floor, _off_floor_at, pinned])


## How far each bogie's pin, as the bogie is turned, is from the pin's place in its fork.
func _pins_off() -> float:
	var chassis := _jack.get_node_or_null("Chassis") as Node3D
	var worst := 0.0
	for path: String in ["Chassis/BogieL", "Chassis/BogieR"]:
		var bogie := _jack.get_node_or_null(path) as Node3D
		if bogie == null or chassis == null:
			return INF
		var pin := chassis.to_local(bogie.to_global(BOGIE_PIN - BOGIE_ORIGIN))
		worst = maxf(worst, Vector2(pin.y - BOGIE_PIN.y, pin.z - BOGIE_PIN.z).length())
	return worst


## P4: with no sidestep in his clips (#327), A held standing swings the steering unit only
## as far as he shuffles round, 10 degrees, never faster than 120 degrees a second; let go, it
## comes back straight. (As he walks it, P8 swings it on to 100-105 degrees.)
func _check_swing() -> void:
	var steering := _jack.get_node("Steering") as Node3D
	var standing := 0.0
	var fastest := 0.0
	var last := steering.rotation.y
	Input.action_press("steer_left")
	for frame in range(60):
		await physics_frame
		standing = maxf(standing, absf(rad_to_deg(steering.rotation.y)))
		fastest = maxf(fastest, absf(rad_to_deg(steering.rotation.y - last)) * 60.0)
		last = steering.rotation.y
	Input.action_release("steer_left")
	for frame in range(60):
		await physics_frame
		fastest = maxf(fastest, absf(rad_to_deg(steering.rotation.y - last)) * 60.0)
		last = steering.rotation.y
	var back := absf(rad_to_deg(steering.rotation.y))
	_check(standing > 3.0 and standing <= STAND_SWING + 0.01 and back < 0.5
		and fastest <= SWING_RATE + 0.5,
		("P4: standing, A swings the steering unit %.1f° (10), at most %.0f° a second (120), "
		+ "and let go it comes back straight (%.1f°)") % [standing, fastest, back])


## P5-P7: pushed through turns each way, its heading turns at v·sin(δ)/L about its rollers' line,
## which never slides sideways; every wheel rolls its distance over its radius; his hands stay on
## the loop.
func _check_turns() -> void:
	_sums = {"turned": 0.0, "predicted": 0.0, "off": 0.0, "slid": 0.0, "travel": 0.0}
	for path in WHEELS:
		_sums[path] = Vector2.ZERO
	_last = _pose()
	_hand_gap = 0.0
	_watching_hands = true
	await _drive("accelerate", 1.0, 1.4)
	await _drive("accelerate", -1.0, 1.4)
	await _drive("brake", 1.0, 1.4)
	_watching_hands = false
	var turned: float = _sums["turned"]
	var predicted: float = _sums["predicted"]
	var heading_off: float = _sums["off"] / maxf(predicted, 0.001)
	var slid: float = _sums["slid"] / maxf(_sums["travel"], 0.001)
	_check(rad_to_deg(predicted) > 10.0 and heading_off <= 0.05 and slid <= 0.03,
		("P5: its heading turns at v·sin(δ)/L about its rollers' line (%.1f° in all against "
		+ "%.1f°, within %.1f%%), the line sliding sideways %.1f%% of the pivot's travel; "
		+ "ending at %s") % [rad_to_deg(turned), rad_to_deg(predicted), heading_off * 100.0,
		slid * 100.0, _flat(_jack.global_position)])
	var worst := 0.0
	var parts: Array[String] = []
	for path in WHEELS:
		var roll: Vector2 = _sums[path]
		var off := roll.x / maxf(roll.y, 0.001)
		worst = maxf(worst, off if roll.y > 0.2 else INF)
		parts.append("%s %.3f m off in %.2f m" % [path.get_file(), roll.x, roll.y])
	_check(worst <= 0.03, ("P6: every wheel and roller rolls its distance over its radius "
		+ "(within %.1f%%: %s)") % [worst * 100.0, ", ".join(parts)])
	_check(_hand_gap <= ON_LOOP, ("P7: his hands on the handle's loop through the turns, as it "
		+ "swings (the farthest %.3f m off: %s; %d of %d over 0.04 m)") % [_hand_gap, _hand_at,
		_hand_over, _hand_frames])


## P8: A held as he walks it swings the steering unit on to 100-105 degrees and no further,
## never faster than 120 degrees a second nor than his walk carries him round behind it (0.5 of
## his pace, the jack's own `_pace` over its `_reach` from the unit's axis, as `pallet_jack.gd`
## reckons them); swung right round, it pivots about its rollers' middle: the heading turns
## while that middle barely moves.
func _check_pivot() -> void:
	var steering := _jack.get_node("Steering") as Node3D
	_round_fastest = 0.0
	var fastest := 0.0
	var most := 0.0
	var last := steering.rotation.y
	Input.action_press("steer_left")
	Input.action_press("accelerate")
	var waited := 0
	while absf(rad_to_deg(steering.rotation.y)) < SWING.x and waited < 480:
		await physics_frame
		fastest = maxf(fastest, absf(rad_to_deg(steering.rotation.y - last)) * 60.0)
		last = steering.rotation.y
		waited += 1
	var swung := absf(rad_to_deg(steering.rotation.y))
	var before := _pose()
	for frame in range(72):
		await physics_frame
		most = maxf(most, absf(rad_to_deg(steering.rotation.y)))
		fastest = maxf(fastest, absf(rad_to_deg(steering.rotation.y - last)) * 60.0)
		last = steering.rotation.y
	var after := _pose()
	Input.action_release("accelerate")
	Input.action_release("steer_left")
	var turned := absf(rad_to_deg(before["ahead"].signed_angle_to(after["ahead"], Vector3.UP)))
	var middle := _flat(after["rollers"] - before["rollers"]).length()
	var pivot := _flat(after["pivot"] - before["pivot"]).length()
	await _seconds(1.5)
	_check(swung >= SWING.x and most <= SWING.y + 0.01 and fastest <= SWING_RATE + 0.5
		and _round_fastest <= 1.05,
		("P8: A held as he walks it swings the steering unit to %.1f° (100-105°), at most %.1f°, "
		+ "at most %.0f° a second (120), his walk round it at most %.2f of 0.5 of his pace") % [
		swung, most, fastest, _round_fastest])
	_check(swung >= SWING.x and turned > 20.0 and middle <= 0.3 * pivot,
		("P8: swung right round, it pivots about its rollers' middle: turned %.0f°, the middle "
		+ "moving %.2f m while the handle's foot moved %.2f m; at %s") % [turned, middle, pivot,
		_flat(_jack.global_position)])


## P9: E lowers the load onto the floor and the forks back to their lowered height.
func _check_lowering() -> void:
	var load := _shed.get_node_or_null("Building/Pallet6") as Node3D
	_off_floor = 0.0
	await _key(KEY_E)
	await _seconds(1.6)
	var floor_y := _jack.global_position.y
	var rested := load.global_position.y - floor_y if load != null else INF
	_check(absf(rested) < 0.01 and _off_floor <= ON_FLOOR,
		("P9: set down, the load rests on the floor (%.3f m) and the wheels stayed on it (%.4f m "
		+ "off)") % [rested, _off_floor])
	_check_lowered("set down,")


## Held: A or D (`steer` -1 right, 1 left, 0 none) with W or S for `seconds`.
func _drive(action: String, steer: float, seconds: float, release := true) -> void:
	_press("steer_left", steer > 0.0)
	_press("steer_right", steer < 0.0)
	Input.action_press(action)
	await _seconds(seconds)
	Input.action_release(action)
	if release:
		_press("steer_left", false)
		_press("steer_right", false)
	await _seconds(0.3)


func _pose() -> Dictionary:
	var steering := _jack.get_node("Steering") as Node3D
	var chassis := _jack.get_node("Chassis") as Node3D
	var ahead := _flat(-_jack.global_basis.z).normalized()
	var wheels := {}
	for path in WHEELS:
		var part := _jack.get_node(path) as Node3D
		var carrier := part.get_parent_node_3d()
		wheels[path] = [part.global_position, part.rotation.x,
			-_flat(carrier.global_basis.z).normalized()]
	return {"ahead": ahead, "pivot": steering.global_position,
		"along": _flat(-steering.global_basis.z).normalized(),
		"rollers": chassis.global_transform * Vector3(0.0, 0.0, ROLLERS_LINE), "wheels": wheels}


## Each physics frame while held: the wheels on the floor, and while turning the kinematics.
func _on_physics() -> void:
	if _jack == null or not bool(_rig.get("held")):
		return
	var steering := _jack.get_node("Steering") as Node3D
	if _last_driver != Vector3.INF:
		var pace := _last_pace
		var rolled := _flat(steering.global_position - _last_pivot).length() * 60.0
		var arm := maxf(float(_rig.get("_reach")) - STEER_AXIS, 0.3)
		var round := absf(steering.rotation.y - _last_swing) * 60.0 * arm
		if rolled > 0.05 and absf(steering.rotation.y) > deg_to_rad(STAND_SWING):
			_round_fastest = maxf(_round_fastest, round / (SIDE_SHARE * pace + 0.01))
	_last_swing = steering.rotation.y
	_last_driver = _driver.global_position
	_last_pivot = steering.global_position
	_last_pace = float(_rig.get("_pace"))
	var off := _wheels_off_floor()
	if off > _off_floor:
		_off_floor = off
		_off_floor_at = "%s, swung %.0f°" % [_hint(), rad_to_deg((_jack.get_node("Steering")
			as Node3D).rotation.y)]
	if _sums.is_empty() or _last.is_empty():
		return
	var now := _pose()
	var moved := _flat(now["pivot"] - _last["pivot"])
	var delta: float = _last["ahead"].signed_angle_to(_last["along"], Vector3.UP)
	var turned: float = _last["ahead"].signed_angle_to(now["ahead"], Vector3.UP)
	var predicted := -moved.dot(_last["along"]) * sin(delta) / WHEELBASE
	_sums["turned"] += absf(turned)
	_sums["predicted"] += absf(predicted)
	_sums["off"] += absf(turned - predicted)
	var side := Vector3.UP.cross(_last["ahead"])
	_sums["slid"] += absf(_flat(now["rollers"] - _last["rollers"]).dot(side))
	_sums["travel"] += moved.length()
	for path in WHEELS:
		var was: Array = _last["wheels"][path]
		var is_now: Array = now["wheels"][path]
		var radius := STEER_RADIUS if path.begins_with("Steering") else ROLLER_RADIUS
		var rolled := wrapf(float(is_now[1]) - float(was[1]), -PI, PI) * radius
		var covered := -_flat(is_now[0] - was[0]).dot(was[2])
		_sums[path] += Vector2(absf(rolled - covered), absf(covered))
	_last = now


## His palms against the loop once each clip has settled, as `test_loading.gd` reads them: the
## first 24 frames of a clip and its blend are left out.
func _on_pose() -> void:
	var player := _driver.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	var clip := str(player.current_animation)
	_since_clip = _since_clip + 1 if clip == _last_clip else 0
	_last_clip = clip
	var frame := 1.0 + player.current_animation_position * 30.0
	var holding := clip in ["Push", "Walk", "WalkBack"] or (clip == "PushStop"
		and frame < HANDS_LET_GO)
	if not _watching_hands or float(_driver.call("hands_on_handle")) < 0.5 \
			or _since_clip <= SETTLED or not holding:
		return
	var tiller := _jack.get_node("Steering/Tiller") as Node3D
	var into := tiller.global_transform.affine_inverse()
	var across := into.basis * (_bone_at("mixamorig_LeftArm") - _bone_at("mixamorig_RightArm"))
	for index in range(2):
		var hand: String = ["Left", "Right"][index]
		var at := into * ((_bone_at("mixamorig_%sHand" % hand)
			+ _bone_at("mixamorig_%sHandMiddle1" % hand)) / 2.0)
		var side := signf(across.x) * (1.0 if index == 0 else -1.0)
		var bar := Vector3(side * LOOP_X, clampf(at.y, LOOP_Y.x, LOOP_Y.y), LOOP_Z)
		var gap := absf(at.distance_to(bar) - UNDER_PALM)
		_hand_frames += 1
		_hand_over += 1 if gap > ON_LOOP else 0
		if gap > _hand_gap:
			_hand_gap = gap
			var swung := (_jack.get_node("Steering") as Node3D).rotation.y
			_hand_at = "%s hand, %s at %.2f s, swung %.0f° at %.0f° a second, reach %.2f m" % [
				hand, player.current_animation, player.current_animation_position,
				rad_to_deg(swung), rad_to_deg(swung - _last_swing) * 60.0,
				float(_rig.get("_reach"))]


func _bone_at(name: String) -> Vector3:
	return _skeleton.global_transform * _skeleton.get_bone_global_pose(_bones[name]).origin


func _list(values: Array[float]) -> String:
	var parts: Array[String] = []
	for value in values:
		parts.append("%.3f" % value)
	return "[" + ", ".join(parts) + "]"


func _walk(points: Array[Vector3], limit: float = 12.0) -> void:
	for point in points:
		var time := 0.0
		Input.action_press("accelerate")
		while _flat(point - _driver.global_position).length() > 0.3 and time < limit:
			_driver.call("look_toward", _flat(point - _driver.global_position).normalized())
			await physics_frame
			time += 1.0 / 60.0
		Input.action_release("accelerate")
	await _seconds(0.4)


func _on_foot() -> bool:
	return not bool(_van.get("occupied")) and not bool(_app.get("_boarding"))


func _until(done: Callable, limit: float) -> void:
	var time := 0.0
	while not done.call() and time < limit:
		await physics_frame
		time += 1.0 / 60.0


func _hint() -> String:
	return (_hud.get("_hint") as Label).text


func _press(action: String, held: bool) -> void:
	if held:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _flat(value: Vector3) -> Vector3:
	return Vector3(value.x, 0.0, value.z)


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
	_van = _app.get_node("FreightVan")
	_driver = _app.get("driver")
	await process_frame
	await process_frame


func _store(text: String) -> void:
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _timeout() -> void:
	_check(false, "The pallet jack's checks finish within 300 s")
	_finish()


func _finish() -> void:
	print("PALLET JACK RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	for suffix in ["", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(_scratch + suffix):
			DirAccess.remove_absolute(_scratch + suffix)
	quit(1 if _failures > 0 else 0)
