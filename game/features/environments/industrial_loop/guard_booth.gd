extends Node3D
## A gatehouse booth with its guard, as real ones are (the audit, #348, after suppliers' photos),
## shared by the transfer shed's gate and the warehouse compound's: a steel booth 2.5 x 2.7 x 2.0 m
## on a concrete plinth, glazed above a 1.05 m sill, every pane in an aluminium frame; toward +x
## the service window, a fixed pane and a sash she slides open with her hand, leaning in from her
## chair, while she checks a run sheet (`open_window`), and shut after; on the face away from the lane a half-glazed steel door
## with its lever handle, hinges and a lamp over it; outside a wall air conditioner, a camera on
## the roof's corner watching the lane, a fascia with its drip edge and a gutter and downpipe;
## inside an LED panel in its frame, a heater, a counter with a monitor showing the cameras, a
## keyboard, a phone with its handset, a logbook open on ruled pages with a pen, and a radio on its
## charger; the guard seated on a swivel chair facing the window, a stand-in (D6), her head turning
## to what she looks at.

const Build = preload("res://shared/components/mesh_builder.gd")
const SIZE := Vector3(2.5, 2.7, 2.0)
const LIGHT := Color(1.0, 0.86, 0.68)
const PLINTH := 0.15
const SILL := 1.05
const HEAD := 2.25
const COUNTER_HEIGHT := 0.88
const SEAT_HEIGHT := 0.64
## Her chair in to the counter, her knees under it, facing the service opening, as a real gate
## guard sits (#348).
const SEAT := Vector3(0.55, 0.0, 0.0)
const MONITOR_ALONG := -0.58
const SCREEN_GLOW := Color(0.62, 0.72, 0.85)
const WALL := 0.1
const POST := 0.08
## An aluminium frame's face and depth; the door's leaf (UK 838 x 1981 mm, here 0.86 x 2.03 m) along
## the west face, its vision panel and handle; the sash's slide and speed.
const FRAME := Vector2(0.05, 0.07)
const DOOR := Vector2(0.86, 2.03)
const DOOR_ALONG := 0.4
const VISION := Vector2(0.5, 0.7)
const VISION_AT := 1.45
const HANDLE_UP := 1.0
## The service window as a three-pane slider (fixed, sliding, fixed): its sash, before the
## driver's window, slides behind the right-hand pane, leaving OPENING (less a frame) clear
## centred OPENING_AT along the booth, where the gates' stop line puts a van driver's eye (the
## booth 1.9 m behind the line, the driver's eye 1.8 m behind his front).
const OPENING := 0.52
const OPENING_AT := -0.1
const SASH_SLIDE := OPENING
const SASH_SPEED := 0.4
const SASH_OUT := 0.035
const DOOR_LAMP := Color(1.0, 0.9, 0.78)
## The sash's pull, low on its meeting stile where a seated hand reaches; her reach for it: she
## leans in from her hips and takes it with her left hand over REACH_SECONDS, slides it at
## SASH_SPEED with her hand on it, and lets go over RELEASE_SECONDS; her elbow down and out.
const PULL_UP := 0.3
const REACH_SECONDS := 0.8
const RELEASE_SECONDS := 0.8
## She leans only as far as she needs: until the pull, shut or open, is REACH_SHARE of her full
## reach from her shoulder (her lean bringing her shoulder forward, the pull partly to her side),
## between LEAN_LEAST and LEAN_MOST from her hips.
const REACH_SHARE := 0.85
const SHOULDER_IN := 0.65
const TOE_CLEAR := 0.08
const LEAN_LEAST := 0.05
const LEAN_MOST := 0.6
const ARM_POLE := Vector3(0.45, 0.9, 0.05)
const ARM_BONES: Array[String] = ["Bip01 L UpperArm", "Bip01 L Forearm", "Bip01 L Hand"]
const GRIP_BONES: Array[String] = ["Bip01 L Finger2", "Bip01 L Finger21"]
const THUMB_BONE := "Bip01 L Finger0"
## Where he looks while he works the window: his hand on the pull from a glance after he starts to
## reach until he lets go; then the driver for GREET_SECONDS as it opens and the sheet comes
## through, and the driver (the van leaving) for GREET_SECONDS once it is shut; else where his gate
## has him look (`look_at_point`).
const LOOK_AT_HAND := 0.15
## Turning to what he looks at, his shoulders take TORSO_SHARE of the turn (TORSO_MOST at most),
## easing over about a third of a second; his head the rest, NECK_LIMIT at most.
const TORSO_SHARE := 0.35
const TORSO_MOST := 0.55
const TURN_RATE := 3.0
const NECK_LIMIT := 70.0
const GREET_SECONDS := 1.5
const HandTurn = preload("res://shared/components/hand_turn.gd")
## The kit, real models (Poly Haven, CC0, `art/booth/POLYHAVEN.md`; the pencil cup the dock desk's).
const ART := "res://features/environments/industrial_loop/art/booth/models/"
const AIRCON = preload(ART + "exterior_aircon_unit/exterior_aircon_unit.gltf")
const CAMERA = preload(ART + "security_camera_01/security_camera_01.gltf")
const CLOCK = preload(ART + "wall_clock/wall_clock.gltf")
const NOTEPADS = preload(ART + "office_notepads/office_notepads.gltf")
const THERMOS = preload(ART + "modified_thermos/modified_thermos.gltf")
const FIRST_AID = preload(ART + "medical_box/medical_box.gltf")
const MONITOR = preload(ART + "dell_monitor/dell_monitor.glb")
const KEYBOARD = preload(ART + "keyboard/keyboard.glb")
const MOUSE = preload(ART + "mouse/mouse.glb")
const PHONE = preload(ART + "desk_phone/desk_phone.glb")
const RADIO = preload(ART + "walkie_talkie/walkie_talkie.glb")
const AC_INDOOR = preload(ART + "ac_indoor_unit/ac_indoor_unit.glb")
## Red Fox's task chair (the dock desk's, CC BY 4.0) on a draughtsman's tall gas lift and chrome
## foot ring, its cushion SEAT_HEIGHT up, for a counter COUNTER_HEIGHT high.
const CHAIR = preload(ART + "draughtsman_chair/draughtsman_chair.glb")
## Turned so a counter item's front (glTF's +Z) faces the guard (-X).
const TO_GUARD := Vector3(0, -PI / 2.0, 0)
const STATIONERY = preload("res://features/environments/industrial_loop/art/dock_station/models/"
	+ "stationery_supplies/stationery_supplies.gltf")
## The sticky notes lying on the yellow pad's corner (the pad 10 mm thick).
const STICKY_ON_PAD := Vector3(0.05, 0.01, 0.09)
const IN_CUP: Array[String] = ["stationery_supplies_pen_blue", "stationery_supplies_pen_red",
	"stationery_supplies_pencil_used"]
const GuardLean = preload("guard_lean.gd")
## The run sheet handed over (#355; the author's choices: she reaches for it from her chair and
## hands it back): once her window is open the sheet is held out of the driver's window, its outer
## end SHEET_OUT past the glass (`start_handover`, from the van's `window_hold`); she leans over
## her counter (HAND_LEAN_MOST from her hips at most) and takes that end in her left hand, her hand
## on it before it moves; brings it in to READ_AT before her and reads it for READ_SECONDS,
## watching it; hands it back to the window and lets go; it goes back in (`sheet_back`). A van
## too far off for her reach (`can_reach`) is not handed to.
const SHEET := Vector2(0.21, 0.297)
const SHEET_OUT := 0.24
const HAND_LEAN_MOST := 1.0
const HAND_REACH_SHARE := 1.0
const LEAN_REACH_SHARE := 0.82
const OFFER_SECONDS := 0.6
const TAKE_SECONDS := 1.0
const BRING_SECONDS := 0.9
const READ_SECONDS := 3.0
const LET_GO_SECONDS := 0.8
const IN_SECONDS := 0.5
const READ_AT := Vector3(0.98, PLINTH + 1.04, -0.08)
const READ_TILT := 0.75

var guard: Node3D
## The run sheet as it passes through her window, and where its handover is ("" none, "waiting",
## "offered", "taking", "bringing", "reading", "returning", "letting_go", "in", "back").
var sheet: MeshInstance3D
var handover := ""
var _hand_t := 0.0
var _van: Node3D
var _hand_lean := 0.0
var _grip_world := Vector3.ZERO
var driver: Node3D
var screen: Node3D
var logbook: Node3D
var _look: Marker3D
var _sash: Array[Node3D] = []
var _sash_shut: Array[Vector3] = []
var _sash_way := Vector3.ZERO
var _open := 0.0
var _want_open := false
var _state := "shut"
var _t := 0.0
var _skeleton: Skeleton3D
var _arm: TwoBoneIK3D
var _arm_target: Marker3D
var _turn: SkeletonModifier3D
var _lean: SkeletonModifier3D
var _twist: SkeletonModifier3D
var _turned := 0.0
var _grip_local := Vector3.ZERO
var _hand_frame := Basis()
var _wanted_look := Vector3.ZERO
var _since := INF


## The booth, its room and `guard_scene`'s guard seated in it (her clip `seated`), with
## `sign_text` over the service window.
func build(concrete: Material, metal: Material, wall: Material, guard_scene: PackedScene,
		guard_name: String, sign_text: String) -> void:
	var body := StaticBody3D.new()
	body.name = "BoothBody"
	add_child(body)
	var shape := BoxShape3D.new()
	shape.size = SIZE + Vector3(0.3, 0.0, 0.3)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = Vector3.UP * SIZE.y / 2.0
	body.add_child(collision)
	Build.box(self, Vector3(0, PLINTH / 2.0, 0), Vector3(SIZE.x + 0.3, PLINTH, SIZE.z + 0.3),
		concrete)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.82, 0.88, 0.9, 0.12)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.04
	glass.metallic_specular = 0.5
	var aluminium := Build.material(Color("b9bcbd"), 0.35)
	aluminium.metallic = 0.6
	var lining := Build.material(Color(0.55, 0.56, 0.55), 0.6)
	var seam := Build.material(Color(0.32, 0.33, 0.33), 0.6)
	var names := {Vector3(0, 0, 1): "GlassSouth", Vector3(0, 0, -1): "GlassNorth",
		Vector3(1, 0, 0): "ServiceWindow", Vector3(-1, 0, 0): "GlassWest"}
	for normal: Vector3 in names:
		_face(normal, String(names[normal]), wall, lining, seam, glass, aluminium)
	_roof(metal, aluminium)
	_room(lining)
	var dark := Build.material(Color(0.03, 0.03, 0.035), 0.4)
	_seat(guard_scene, guard_name, dark)
	_outside(wall, aluminium, dark)
	_make_sheet()
	var sign := Build.text(self, sign_text, Vector3(SIZE.x / 2.0 + 0.06, SIZE.y - 0.22, 0), 28,
		Color("e3d5af"))
	sign.rotation.y = PI / 2.0
	sign.shaded = true
	sign.double_sided = false


## Has the guard slide the service window's sash open (or shut): she leans in, takes its pull with
## her left hand, slides it and lets go; the sash moves only under her hand.
func open_window(open: bool) -> void:
	_want_open = open


## Where his gate has him look (his head turning to it over 0.6 s), when he is not working the
## window.
func look_at_point(at: Vector3) -> void:
	_wanted_look = at


func _process(delta: float) -> void:
	if _sash.is_empty() or _arm == null:
		return
	_since += delta
	if (_state == "shut" or _state == "open") and _want_open != (_state == "open"):
		_state = "opening" if _want_open else "closing"
		_t = 0.0
		_grip_local = Vector3.ZERO
	if _state == "opening" or _state == "closing":
		_work_window(delta)
	elif handover != "" and handover != "back":
		_work_handover(delta)
	_aim_head(delta)


## Where his head turns: his hand on the pull, the driver, or where his gate has him look; his
## shoulders turning part of the way with him.
func _aim_head(delta: float) -> void:
	if _look == null:
		return
	var at := _wanted_look
	var sliding := _state == "opening" or _state == "closing"
	if sliding and _t >= LOOK_AT_HAND:
		at = _sash[2].global_position
	elif sheet != null and sheet.visible and handover != "" and handover != "in":
		at = sheet.global_position
	elif not sliding and _since < GREET_SECONDS and is_instance_valid(driver):
		at = driver.global_position
	if at == Vector3.ZERO:
		return
	_look.global_position = at
	if _twist == null or not is_instance_valid(guard):
		return
	var front := guard.global_basis.z
	front.y = 0.0
	var toward := at - guard.global_position
	toward.y = 0.0
	var wanted := 0.0
	if front.length() > 0.001 and toward.length() > 0.001:
		wanted = clampf(front.signed_angle_to(toward, Vector3.UP) * TORSO_SHARE, -TORSO_MOST,
			TORSO_MOST)
	_turned = lerpf(_turned, wanted, 1.0 - exp(-delta * TURN_RATE))
	_twist.set("angle", _turned)


## One tick of his working the sash: reaching, sliding it under his hand, letting go.
func _work_window(delta: float) -> void:
	_t += delta
	var slide := SASH_SLIDE / SASH_SPEED
	var moved := smoothstep(0.0, 1.0, clampf((_t - REACH_SECONDS) / slide, 0.0, 1.0))
	_open = moved if _state == "opening" else 1.0 - moved
	for index in range(_sash.size()):
		_sash[index].position = _sash_shut[index] + _sash_way * _open * SASH_SLIDE
	var on := smoothstep(0.0, REACH_SECONDS, _t) * (1.0 - smoothstep(REACH_SECONDS + slide,
		REACH_SECONDS + slide + RELEASE_SECONDS, _t))
	if _t >= REACH_SECONDS + slide + RELEASE_SECONDS:
		_state = "open" if _state == "opening" else "shut"
		_since = 0.0
		on = 0.0
	_hold_pull(on)


## Her left hand `on` of the way to the sash's pull: the wrist placed so her grip (between her
## middle finger's first two joints) is on it, her fingers on from her forearm (from her elbow to
## the pull) and her thumb up.
func _hold_pull(on: float) -> void:
	if _grip_local == Vector3.ZERO and on > 0.0:
		_grip_frame()
	_hand_on(_sash[2].global_position, on)


## Her left hand `on` of the way to `pull` (its grip there), as for the sash's pull.
func _hand_on(pull: Vector3, on: float) -> void:
	for modifier: SkeletonModifier3D in [_arm, _turn, _lean]:
		modifier.influence = on
		modifier.active = on > 0.0
	if on <= 0.0:
		return
	var elbow := _skeleton.global_transform * _skeleton.get_bone_global_pose(
		_skeleton.find_bone(ARM_BONES[1])).origin
	var fingers := (pull - elbow).normalized()
	var thumb := (Vector3.UP - fingers * fingers.dot(Vector3.UP)).normalized()
	var aim := Basis(fingers, thumb, fingers.cross(thumb)) * _hand_frame.inverse()
	_turn.set("aim", aim)
	_arm_target.global_position = pull - aim * _grip_local


## Her grip and thumb in her hand's own frame (from her pose as she starts to reach), in metres,
## and how far she leans to bring the pull, at its farther end, within her comfortable reach.
func _grip_frame() -> void:
	var hand := _skeleton.get_bone_global_pose(_skeleton.find_bone(ARM_BONES[2]))
	var grip := Vector3.ZERO
	for bone in GRIP_BONES:
		grip += _skeleton.get_bone_global_pose(_skeleton.find_bone(bone)).origin / GRIP_BONES.size()
	var unit := _skeleton.global_basis.get_scale().x
	var frame := hand.basis.orthonormalized()
	_grip_local = frame.inverse() * (grip - hand.origin) * unit
	var thumb := frame.inverse() * (_skeleton.get_bone_global_pose(_skeleton.find_bone(
		THUMB_BONE)).origin - hand.origin)
	var along := _grip_local.normalized()
	var side := (thumb - along * along.dot(thumb)).normalized()
	_hand_frame = Basis(along, side, along.cross(side))
	var at := func(bone: String) -> Vector3:
		return _skeleton.global_transform * _skeleton.get_bone_global_pose(
			_skeleton.find_bone(bone)).origin
	var shoulder: Vector3 = at.call(ARM_BONES[0])
	var reach: float = shoulder.distance_to(at.call(ARM_BONES[1])) + (at.call(ARM_BONES[1]) as
		Vector3).distance_to(at.call(ARM_BONES[2])) + _grip_local.length()
	var shut_at := global_transform * _sash_shut[2]
	var open_at := global_transform * (_sash_shut[2] + _sash_way * SASH_SLIDE)
	var far_at := shut_at if shoulder.distance_to(shut_at) > shoulder.distance_to(open_at) \
		else open_at
	var farthest := shoulder.distance_to(far_at)
	var spine := (at.call("Bip01 Pelvis") as Vector3).distance_to(shoulder)
	var ahead := maxf((far_at - shoulder).normalized().dot(guard.global_basis.z.normalized()),
		0.3)
	var shift := clampf((farthest - REACH_SHARE * reach) / (spine * ahead), 0.0, 0.9)
	_lean.set("angle", clampf(asin(shift), LEAN_LEAST, LEAN_MOST))


## The van `van` holds the run sheet out at its driver's window; she takes it once her window is
## open (`handover` runs on from "waiting").
func start_handover(van: Node3D) -> void:
	_van = van
	handover = "waiting"
	_hand_t = 0.0


## Whether her run sheet has been handed back and gone in through the van's window.
func sheet_back() -> bool:
	return handover == "back"


## Whether she can reach `point` from her chair, leaning over her counter as far as she would.
func can_reach(point: Vector3) -> bool:
	if _skeleton == null:
		return false
	if _grip_local == Vector3.ZERO:
		_grip_frame()
	var bone := func(name: String) -> Vector3:
		return _skeleton.global_transform * _skeleton.get_bone_global_pose(
			_skeleton.find_bone(name)).origin
	var shoulder: Vector3 = bone.call(ARM_BONES[0])
	var elbow: Vector3 = bone.call(ARM_BONES[1])
	var reach := shoulder.distance_to(elbow) + elbow.distance_to(bone.call(ARM_BONES[2])) \
		+ _grip_local.length()
	var pelvis: Vector3 = bone.call("Bip01 Pelvis")
	var spine := pelvis.distance_to(shoulder)
	var front := guard.global_basis.z
	front.y = 0.0
	var leaned := pelvis + (shoulder - pelvis).normalized().rotated(front.normalized().cross(
		Vector3.UP).normalized(), -HAND_LEAN_MOST) * spine
	return leaned.distance_to(point) <= reach * HAND_REACH_SHARE


## Whether she can take the sheet held out of `van`'s driver's window (its end SHEET_OUT out).
func can_reach_van(van: Node3D) -> bool:
	var out := -van.global_basis.x
	out.y = 0.0
	return can_reach((van.call("window_hold") as Vector3) + out.normalized() * SHEET_OUT)


## Where her left hand's grip is, in the world, as her skeleton last drew it (her arm's IK in).
func grip_point() -> Vector3:
	return _grip_world


func _remember_grip() -> void:
	var hand := _skeleton.global_transform * _skeleton.get_bone_global_pose(
		_skeleton.find_bone(ARM_BONES[2]))
	_grip_world = hand.origin + hand.basis.orthonormalized() * _grip_local


## The sheet's end she takes (its outer end past the van's glass), in the world.
func sheet_grip() -> Vector3:
	if not is_instance_valid(_van):
		return Vector3.ZERO
	return (_van.call("window_hold") as Vector3) + _outward() * SHEET_OUT


## The van's outward way at its driver's window (its own -x, level).
func _outward() -> Vector3:
	var out := -_van.global_basis.x
	out.y = 0.0
	return out.normalized()


func _make_sheet() -> void:
	var paper := StandardMaterial3D.new()
	paper.albedo_texture = _ruled_pages()
	paper.albedo_color = Color(0.95, 0.95, 0.93)
	paper.roughness = 0.85
	paper.cull_mode = BaseMaterial3D.CULL_DISABLED
	var quad := QuadMesh.new()
	quad.size = SHEET
	sheet = MeshInstance3D.new()
	sheet.name = "RunSheet"
	sheet.mesh = quad
	sheet.material_override = paper
	sheet.top_level = true
	sheet.visible = false
	add_child(sheet)


## The sheet face up, its taken end at `end` and the rest of it along `along` (level); or, as she
## reads it, its far end turned up by `tilt` about its width, so its face turns toward her.
func _lay_sheet(end: Vector3, along: Vector3, tilt: float) -> void:
	var side := along.cross(Vector3.UP).normalized()
	var length := along.rotated(side, tilt).normalized()
	sheet.global_transform = Transform3D(Basis(side, length, side.cross(length).normalized()),
		end + length * SHEET.y * 0.5)


## How far she leans to bring `point` within her reach: the least lean from her hips, in steps,
## that puts her shoulder within LEAN_REACH_SHARE of her arm's reach of it (as `can_reach` leans).
func _lean_for(point: Vector3) -> float:
	var bone := func(name: String) -> Vector3:
		return _skeleton.global_transform * _skeleton.get_bone_global_pose(
			_skeleton.find_bone(name)).origin
	var shoulder: Vector3 = bone.call(ARM_BONES[0])
	var elbow: Vector3 = bone.call(ARM_BONES[1])
	var reach := shoulder.distance_to(elbow) + elbow.distance_to(bone.call(ARM_BONES[2])) \
		+ _grip_local.length()
	var pelvis: Vector3 = bone.call("Bip01 Pelvis")
	var spine := pelvis.distance_to(shoulder)
	var front := guard.global_basis.z
	front.y = 0.0
	var side := front.normalized().cross(Vector3.UP).normalized()
	var lean := LEAN_LEAST
	while lean < HAND_LEAN_MOST:
		var leaned := pelvis + (shoulder - pelvis).normalized().rotated(side, -lean) * spine
		if leaned.distance_to(point) <= reach * LEAN_REACH_SHARE:
			break
		lean += 0.05
	return minf(lean, HAND_LEAN_MOST)


## One tick of the handover.
func _work_handover(delta: float) -> void:
	if not is_instance_valid(_van) or sheet == null:
		handover = ""
		return
	if handover == "waiting":
		if _state != "open":
			return
		handover = "offered"
		_hand_t = 0.0
		if _grip_local == Vector3.ZERO:
			_grip_frame()
	_hand_t += delta
	var out := _outward()
	var at_van := sheet_grip()
	var toward_van := -out
	var read := global_transform * READ_AT
	match handover:
		"offered":
			var held := smoothstep(0.0, OFFER_SECONDS, _hand_t)
			sheet.visible = true
			_lay_sheet((_van.call("window_hold") as Vector3) + out * SHEET_OUT * held, toward_van,
				0.0)
			if _hand_t >= OFFER_SECONDS:
				_next("taking")
				_hand_lean = _lean_for(at_van)
		"taking":
			_lean.set("angle", _hand_lean)
			_hand_on(at_van, smoothstep(0.0, TAKE_SECONDS, _hand_t))
			_lay_sheet(at_van, toward_van, 0.0)
			if _hand_t >= TAKE_SECONDS:
				_next("bringing")
		"bringing", "returning":
			var share := smoothstep(0.0, BRING_SECONDS, _hand_t)
			if handover == "returning":
				share = 1.0 - share
			_lean.set("angle", lerpf(_hand_lean, LEAN_LEAST, share))
			_hand_on(at_van.lerp(read, share), 1.0)
			_lay_sheet(grip_point(), toward_van, READ_TILT * share)
			if _hand_t >= BRING_SECONDS:
				_next("reading" if handover == "bringing" else "letting_go")
		"reading":
			_lean.set("angle", LEAN_LEAST)
			_hand_on(read, 1.0)
			_lay_sheet(grip_point(), toward_van, READ_TILT)
			if _hand_t >= READ_SECONDS:
				_next("returning")
		"letting_go":
			_lay_sheet(at_van, toward_van, 0.0)
			_hand_on(at_van, 1.0 - smoothstep(0.0, LET_GO_SECONDS, _hand_t))
			if _hand_t >= LET_GO_SECONDS:
				_hand_on(at_van, 0.0)
				_next("in")
		"in":
			var gone := smoothstep(0.0, IN_SECONDS, _hand_t)
			_lay_sheet((_van.call("window_hold") as Vector3) + out * SHEET_OUT * (1.0 - gone)
				- out * SHEET.y * gone, toward_van, 0.0)
			if _hand_t >= IN_SECONDS:
				sheet.visible = false
				_next("back")


func _next(phase: String) -> void:
	handover = phase
	_hand_t = 0.0


## One wall: its solid panels below the sill and above the head, the lining inside with its panel
## seam, the corner posts, and its glazing in frames; the service face's fixed pane and sliding
## sash; the west face's door beside its pane.
func _face(normal: Vector3, pane_name: String, wall: Material, lining: Material, seam: Material,
		glass: Material, aluminium: Material) -> void:
	var width := SIZE.x if normal.z != 0.0 else SIZE.z
	var across := normal.cross(Vector3.UP)
	var face := normal * ((SIZE.z if normal.z != 0.0 else SIZE.x) / 2.0)
	var basis := Basis(across, Vector3.UP, normal)
	var half := width / 2.0
	var open_from := -half + POST
	var open_to := half - POST
	var door_from := DOOR_ALONG - DOOR.x / 2.0 - FRAME.x
	var door_to := DOOR_ALONG + DOOR.x / 2.0 + FRAME.x
	var west := normal.x < 0.0
	var lower_to := door_from if west else half
	_panel(face, basis, -half, lower_to, PLINTH, SILL, wall, 0.0, WALL)
	_panel(face, basis, -half, half, HEAD, SIZE.y, wall, 0.0, WALL)
	for band: Vector2 in [Vector2(PLINTH, SILL), Vector2(HEAD, SIZE.y)]:
		var to := (door_from if west and band.x < SILL else half) - 0.11
		_panel(face, basis, -half + 0.11, to, band.x, band.y, lining, -WALL * 0.55, 0.01)
		if width > 2.2:
			_panel(face, basis, -0.003, 0.003, band.x, band.y, seam, -WALL * 0.55 - 0.006,
				0.002)
	for end in [-1.0, 1.0]:
		var post := Build.box(self, face + across * end * (half - POST / 2.0)
			+ Vector3.UP * (SILL + HEAD) / 2.0, Vector3(POST, HEAD - SILL, 0.12), aluminium)
		post.basis = basis
	if normal.x > 0.0:
		_service_window(face, basis, across, open_from, open_to, pane_name, glass, aluminium)
	elif west:
		_framed(self, pane_name, face + across * (open_from + door_from) / 2.0
			+ Vector3.UP * (SILL + HEAD) / 2.0, basis, Vector2(door_from - open_from,
			HEAD - SILL), glass, aluminium)
		_door(face, basis, across, wall, glass, aluminium)
	else:
		_framed(self, pane_name, face + Vector3.UP * (SILL + HEAD) / 2.0, basis,
			Vector2(open_to - open_from, HEAD - SILL), glass, aluminium)


func _panel(face: Vector3, basis: Basis, from: float, to: float, low: float, high: float,
		surface: Material, out: float, thick: float) -> MeshInstance3D:
	var panel := Build.box(self, face + basis.x * (from + to) / 2.0 + basis.z * out
		+ Vector3.UP * (low + high) / 2.0, Vector3(to - from, high - low, thick), surface)
	panel.basis = basis
	return panel


## A pane named `pane_name` in an aluminium frame (head, sill and two jambs) as its sibling
## `<pane_name>Frame`, `size` across the frame's outside.
func _framed(parent: Node3D, pane_name: String, at: Vector3, basis: Basis, size: Vector2,
		glass: Material, aluminium: Material) -> Array[Node3D]:
	var pane := Build.box(parent, at, Vector3(size.x - FRAME.x * 2.0 + 0.01,
		size.y - FRAME.x * 2.0 + 0.01, 0.012), glass)
	pane.basis = basis
	pane.name = pane_name
	pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var frame := Node3D.new()
	frame.name = pane_name + "Frame"
	frame.position = at
	frame.basis = basis
	parent.add_child(frame)
	for side in [-1.0, 1.0]:
		Build.box(frame, Vector3(0, side * (size.y - FRAME.x) / 2.0, 0),
			Vector3(size.x, FRAME.x, FRAME.y), aluminium).name = "Head" if side > 0.0 else "Sill"
		Build.box(frame, Vector3(side * (size.x - FRAME.x) / 2.0, 0, 0),
			Vector3(FRAME.x, size.y - FRAME.x * 2.0, FRAME.y), aluminium).name = "Jamb"
	return [pane, frame]


## The service window: two fixed panes in the outer track and, between them before the driver's
## window, a sash in the inner track overlapping each by half a frame, its pull inside, low on its
## left stile, sliding behind the right-hand pane.
func _service_window(face: Vector3, basis: Basis, across: Vector3, from: float, to: float,
		pane_name: String, glass: Material, aluminium: Material) -> void:
	var height := Vector3.UP * (SILL + HEAD) / 2.0
	var tall := HEAD - SILL
	var low := OPENING_AT - OPENING / 2.0
	var high := OPENING_AT + OPENING / 2.0
	_framed(self, "GlassServiceLeft", face + across * (from + low + FRAME.x / 2.0) / 2.0 + height,
		basis, Vector2(low + FRAME.x / 2.0 - from, tall), glass, aluminium)
	_framed(self, "GlassServiceFixed", face + across * (high - FRAME.x / 2.0 + to) / 2.0 + height,
		basis, Vector2(to - high + FRAME.x / 2.0, tall), glass, aluminium)
	var sash := _framed(self, pane_name, face + across * OPENING_AT - basis.z * SASH_OUT + height,
		basis, Vector2(OPENING + FRAME.x, tall), glass, aluminium)
	var pull := Build.box(self, sash[1].position - across * (OPENING / 2.0 - FRAME.x)
		- basis.z * (FRAME.y / 2.0 + 0.012) + Vector3.UP * (SILL + PULL_UP - (SILL + HEAD) / 2.0),
		Vector3(0.022, 0.14, 0.024), aluminium)
	pull.basis = basis
	pull.name = "SashPull"
	_sash.assign(sash)
	_sash.append(pull)
	for part in _sash:
		_sash_shut.append(part.position)
	_sash_way = across


## The clear opening the sash leaves when open, along the lane (its two ends' world z).
func opening_span() -> Vector2:
	var face := Vector3(SIZE.x / 2.0, (SILL + HEAD) / 2.0, 0.0)
	var ends := [to_global(face + Vector3(0, 0, OPENING_AT - OPENING / 2.0 + FRAME.x / 2.0)).z,
		to_global(face + Vector3(0, 0, OPENING_AT + OPENING / 2.0 - FRAME.x / 2.0)).z]
	return Vector2(minf(ends[0], ends[1]), maxf(ends[0], ends[1]))


## The opening's middle, at the window's height, in the world.
func opening_centre() -> Vector3:
	return to_global(Vector3(SIZE.x / 2.0, (SILL + HEAD) / 2.0, OPENING_AT))


## The steel door on the west face: its leaf round a framed vision panel, its frame in the wall,
## three hinges on its hinge side, a lever handle outside and in, and a kick plate.
func _door(face: Vector3, basis: Basis, across: Vector3, wall: Material, glass: Material,
		aluminium: Material) -> void:
	var door := Node3D.new()
	door.name = "Door"
	door.position = face + across * DOOR_ALONG + Vector3.UP * PLINTH
	door.basis = basis
	add_child(door)
	var leaf_thick := 0.045
	var low := VISION_AT - VISION.y / 2.0
	var high := VISION_AT + VISION.y / 2.0
	var beside := (DOOR.x - VISION.x) / 2.0
	var parts := {"LeafLow": [Vector3(0, low / 2.0, 0), Vector3(DOOR.x, low, leaf_thick)],
		"LeafHigh": [Vector3(0, (high + DOOR.y) / 2.0, 0), Vector3(DOOR.x, DOOR.y - high,
		leaf_thick)], "LeafLeft": [Vector3(-(DOOR.x - beside) / 2.0, VISION_AT, 0),
		Vector3(beside, VISION.y, leaf_thick)], "LeafRight": [Vector3((DOOR.x - beside) / 2.0,
		VISION_AT, 0), Vector3(beside, VISION.y, leaf_thick)]}
	for part: String in parts:
		Build.box(door, parts[part][0], parts[part][1], wall).name = part
	_framed(door, "GlassDoor", Vector3(0, VISION_AT, 0), Basis.IDENTITY, VISION, glass,
		aluminium)
	for side in [-1.0, 1.0]:
		Build.box(door, Vector3(side * (DOOR.x + FRAME.x) / 2.0, (DOOR.y + 0.07) / 2.0, 0),
			Vector3(FRAME.x, DOOR.y + 0.07, WALL + 0.02), aluminium).name = "DoorFrame"
	Build.box(door, Vector3(0, DOOR.y + 0.035, 0), Vector3(DOOR.x + FRAME.x * 2.0, 0.07,
		WALL + 0.02), aluminium).name = "DoorFrame"
	for hinge in [0.25, 1.0, 1.8]:
		Build.cylinder(door, Vector3(-DOOR.x / 2.0, hinge, leaf_thick / 2.0 + 0.008), 0.011,
			0.1, aluminium).name = "Hinge"
	for side in [-1.0, 1.0]:
		var depth: float = side * (leaf_thick / 2.0 + 0.03)
		Build.box(door, Vector3(DOOR.x / 2.0 - 0.09, HANDLE_UP, side * (leaf_thick / 2.0 + 0.004)),
			Vector3(0.05, 0.16, 0.008), aluminium).name = "HandlePlate"
		var lever := Build.box(door, Vector3(DOOR.x / 2.0 - 0.15, HANDLE_UP, depth),
			Vector3(0.13, 0.02, 0.02), aluminium)
		lever.name = "DoorHandle" if side > 0.0 else "DoorHandleInside"
	Build.box(door, Vector3(0, 0.12, leaf_thick / 2.0 + 0.002), Vector3(DOOR.x - 0.06, 0.22,
		0.003), aluminium).name = "KickPlate"
	var lamp_at := Vector3(0, DOOR.y + 0.27, 0.07)
	var body := Build.box(door, lamp_at, Vector3(0.26, 0.14, 0.09),
		Build.material(Color(0.12, 0.12, 0.13), 0.5))
	body.name = "BulkheadBody"
	Build.box(door, lamp_at + Vector3(0, 0, 0.047), Vector3(0.2, 0.09, 0.006),
		Build.luminous(DOOR_LAMP, 1.6)).name = "BulkheadLens"
	var light := OmniLight3D.new()
	light.name = "DoorLamp"
	light.position = lamp_at + Vector3(0, -0.05, 0.15)
	light.light_color = DOOR_LAMP
	light.light_energy = 0.8
	light.omni_range = 4.5
	light.shadow_enabled = false
	door.add_child(light)


## The roof: a steel deck, its fascia all round with a drip edge, a gutter along the west eave
## and its downpipe down the north-west corner to the plinth.
func _roof(metal: Material, aluminium: Material) -> void:
	var over := 0.25
	Build.box(self, Vector3(0, SIZE.y + 0.08, 0), Vector3(SIZE.x + over * 2.0, 0.16,
		SIZE.z + over * 2.0), metal)
	var fascia := Node3D.new()
	fascia.name = "Fascia"
	add_child(fascia)
	for normal: Vector3 in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1),
			Vector3(0, 0, -1)]:
		var length := (SIZE.z if normal.x != 0.0 else SIZE.x) + over * 2.0 + 0.04
		var out := (SIZE.x if normal.x != 0.0 else SIZE.z) / 2.0 + over + 0.01
		var band := Build.box(fascia, normal * out + Vector3.UP * (SIZE.y + 0.07),
			Vector3(length, 0.22, 0.02), metal)
		band.basis = Basis(normal.cross(Vector3.UP), Vector3.UP, normal)
		var drip := Build.box(fascia, normal * (out + 0.015) + Vector3.UP * (SIZE.y - 0.045),
			Vector3(length, 0.012, 0.035), aluminium)
		drip.basis = band.basis
	var eave := -(SIZE.x / 2.0 + over + 0.07)
	Build.box(self, Vector3(eave, SIZE.y - 0.02, 0), Vector3(0.11, 0.08, SIZE.z + over * 2.0),
		aluminium).name = "Gutter"
	var corner := Vector3(-(SIZE.x / 2.0 + 0.05), 0.0, -(SIZE.z / 2.0 - 0.12))
	var reach := SIZE.y - 0.06 - PLINTH
	Build.cylinder(self, corner + Vector3.UP * (PLINTH + reach / 2.0), 0.034, reach, aluminium) \
		.name = "Downpipe"
	Build.box(self, Vector3((eave + corner.x) / 2.0, SIZE.y - 0.06, corner.z),
		Vector3(corner.x - eave, 0.06, 0.06), aluminium).name = "DownpipeOffset"
	Build.box(self, corner + Vector3(-0.04, PLINTH + 0.03, 0), Vector3(0.1, 0.05, 0.07),
		aluminium).name = "DownpipeShoe"


## Outside: a split air conditioner's outdoor unit on its wall brackets against the north wall, its
## drain to the ground; and a box camera on a mast at the roof's south-east corner, watching the
## lane's approach.
func _outside(wall: Material, aluminium: Material, dark: Material) -> void:
	var unit := _prop(AIRCON, "AirConditioner", Vector3(0, PI, 0))
	var rusted := unit.find_child("exterior_aircon_unit_rusted", true, false) as Node3D
	if rusted != null:
		rusted.visible = false
	_place(unit, Vector3(-0.55, 0.0, -SIZE.z / 2.0 - 0.005), "north_out")
	var camera := Node3D.new()
	camera.name = "Cctv"
	camera.position = Vector3(SIZE.x / 2.0 + 0.12, SIZE.y + 0.34, SIZE.z / 2.0 + 0.12)
	Build.box(self, Vector3(camera.position.x, SIZE.y + 0.24, camera.position.z),
		Vector3(0.04, 0.2, 0.04), aluminium).name = "CctvMast"
	add_child(camera)
	camera.basis = Basis.looking_at(Vector3(1.0, -0.35, 0.45).normalized(), Vector3.UP)
	var model := CAMERA.instantiate() as Node3D
	model.name = "CctvModel"
	camera.add_child(model)


## A kit model, `label`, turned by `turn`, in the booth.
func _prop(scene: PackedScene, label: String, turn: Vector3 = Vector3.ZERO) -> Node3D:
	var node := scene.instantiate() as Node3D
	node.name = label
	node.rotation = turn
	add_child(node)
	return node


## Sets `node` against what it rests on, by its own size: "counter" or "floor" (its bottom at
## at.y, centred on at's x and z), "north_in" and "south_in" (its back on that wall's lining at
## at.z),
## "north_out" (its back on the north wall's outside at at.z, its bottom at at.y), "west_in" (its
## back on the west wall's lining at at.x); centred on `at` along the other axes.
func _place(node: Node3D, at: Vector3, rest: String) -> void:
	var box := _box_of(node)
	var centre := box.get_center()
	var shift := at - centre
	match rest:
		"counter", "floor":
			shift.y = at.y - box.position.y
		"north_in":
			shift.z = at.z - box.position.z
		"south_in":
			shift.z = at.z - box.end.z
		"north_out":
			shift.z = at.z - box.end.z
			shift.y = at.y - box.position.y
		"west_in":
			shift.x = at.x - box.position.x
	node.position += shift


## Its visible meshes' bounds in the booth's frame, from the transforms between each mesh and the
## booth (a model just instanced has not yet given its pieces their place in the world).
func _box_of(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		if not mesh.visible:
			continue
		var to_booth := Transform3D.IDENTITY
		var step: Node = mesh
		while step != self and step is Node3D:
			to_booth = (step as Node3D).transform * to_booth
			step = step.get_parent()
		var part := to_booth * mesh.get_aabb()
		box = part if first else box.merge(part)
		first = false
	return box


## Inside, the guard's kit: the air conditioner's head high on the north wall, over its outdoor
## unit, a wall clock high on the south wall, a first-aid case on the west wall's lower panel,
## notepads (the yellow pad, sticky notes on its corner), a thermos and a pencil cup with pens on
## the counter, the counter before the open window kept clear for the sheet.
func _kit(top: float) -> void:
	var lining := SIZE * 0.5 - Vector3(WALL * 0.55 + 0.005, 0, WALL * 0.55 + 0.005)
	_place(_prop(AC_INDOOR, "AcIndoor"), Vector3(-0.55, 2.47, -lining.z), "north_in")
	_place(_prop(CLOCK, "WallClock", Vector3(0, PI, 0)), Vector3(0.15, 2.47, lining.z),
		"south_in")
	_place(_prop(FIRST_AID, "FirstAid", Vector3(0, 0, -PI / 2.0)), Vector3(-lining.x, 0.62, 0.5),
		"west_in")
	var pads := _prop(NOTEPADS, "Notepads")
	for mesh: MeshInstance3D in pads.find_children("*", "MeshInstance3D", true, false):
		var named := String(mesh.name)
		mesh.visible = named.contains("yellow") or named.contains("sticky")
		if named.contains("yellow"):
			mesh.position = Vector3.ZERO
		elif named.contains("sticky"):
			mesh.position = STICKY_ON_PAD
	_place(pads, Vector3(0.72, top, -0.64), "counter")
	_place(_prop(THERMOS, "Thermos"), Vector3(1.08, top, 0.3), "counter")
	var cup := _prop(STATIONERY, "PencilCup")
	for mesh: MeshInstance3D in cup.find_children("*", "MeshInstance3D", true, false):
		mesh.visible = String(mesh.name) == "stationery_supplies_pencilcup"
	_place(cup, Vector3(1.1, top, 0.45), "counter")
	var holder := cup.find_child("stationery_supplies_pencilcup", true, false) as Node3D
	for index in range(IN_CUP.size()):
		var pen := cup.find_child(IN_CUP[index], true, false) as Node3D
		if pen == null or holder == null:
			continue
		pen.visible = true
		var lean := Vector3(0.12 * (index - 1), 0, 0.1 * (1 - index % 2))
		pen.global_transform = Transform3D(Basis.from_euler(Vector3(lean.z, 0, PI / 2.0 + lean.x)),
			holder.global_position + Vector3(0.012 * (index - 1), 0.05, 0.008 * (index % 2)))


func _room(lining: Material) -> void:
	var inner := Vector2(SIZE.x - 0.2, SIZE.z - 0.2)
	Build.box(self, Vector3(0, PLINTH + 0.005, 0), Vector3(inner.x, 0.01, inner.y),
		Build.material(Color(0.08, 0.08, 0.085), 0.55)).name = "Floor"
	Build.box(self, Vector3(0, SIZE.y - 0.005, 0), Vector3(inner.x, 0.01, inner.y), lining) \
		.name = "Ceiling"
	var panel_at := Vector3(0.2, SIZE.y - 0.016, SEAT.z * 0.5)
	Build.box(self, panel_at, Vector3(0.6, 0.012, 0.6), Build.luminous(LIGHT * 0.9)).name = \
		"LedPanel"
	var trim := Build.material(Color(0.85, 0.85, 0.83), 0.4)
	var led_frame := Node3D.new()
	led_frame.name = "LedFrame"
	led_frame.position = panel_at + Vector3(0, -0.008, 0)
	add_child(led_frame)
	for side in [-1.0, 1.0]:
		Build.box(led_frame, Vector3(side * 0.31, 0, 0), Vector3(0.025, 0.02, 0.645), trim)
		Build.box(led_frame, Vector3(0, 0, side * 0.31), Vector3(0.6, 0.02, 0.025), trim)
	var light := OmniLight3D.new()
	light.name = "BoothLight"
	light.position = panel_at - Vector3(0, 0.08, 0)
	light.light_color = LIGHT
	light.light_energy = 1.5
	light.omni_range = 4.0
	light.shadow_enabled = true
	add_child(light)
	var laminate := Build.material(Color(0.58, 0.56, 0.52), 0.45)
	var dark := Build.material(Color(0.03, 0.03, 0.035), 0.4)
	var depth := 0.55
	var counter_x := SIZE.x / 2.0 - 0.1 - depth / 2.0
	var top := PLINTH + COUNTER_HEIGHT
	Build.box(self, Vector3(counter_x, top - 0.015, 0), Vector3(depth, 0.03, 1.6), laminate) \
		.name = "Counter"
	for end in [-1.0, 1.0]:
		Build.box(self, Vector3(counter_x, PLINTH + (COUNTER_HEIGHT - 0.03) / 2.0, end * 0.785),
			Vector3(depth, COUNTER_HEIGHT - 0.03, 0.03), laminate).name = "CounterSide"
	_monitor(counter_x, top, dark)
	_place(_prop(KEYBOARD, "Keyboard", TO_GUARD), Vector3(counter_x - 0.08, top, -0.1), "counter")
	_place(_prop(MOUSE, "Mouse", TO_GUARD + Vector3(0, 0.15, 0)), Vector3(counter_x - 0.085, top,
		0.19), "counter")
	_place(_prop(PHONE, "Phone", TO_GUARD + Vector3(0, 0.25, 0)), Vector3(counter_x + 0.185, top,
		0.66), "counter")
	_logbook(Vector3(counter_x - 0.045, top, 0.48), dark)
	_radio(Vector3(counter_x - 0.225, top, 0.75), dark)
	_kit(top)
	var heater := Build.box(self, Vector3(0.2, PLINTH + 0.4, -SIZE.z / 2.0 + WALL / 2.0 + 0.06),
		Vector3(0.8, 0.45, 0.08), Build.material(Color(0.9, 0.9, 0.88), 0.5))
	heater.name = "Heater"
	Build.box(self, heater.position + Vector3(0, 0.19, 0.041), Vector3(0.7, 0.04, 0.004),
		dark).name = "HeaterGrille"


func _monitor(counter_x: float, top: float, dark: Material) -> void:
	var monitor := Node3D.new()
	monitor.name = "Monitor"
	monitor.position = Vector3(counter_x + 0.02, top, MONITOR_ALONG)
	add_child(monitor)
	var towards := Vector3(SEAT.x - monitor.position.x, 0.0, SEAT.z - monitor.position.z)
	towards = towards.normalized()
	monitor.basis = Basis(Vector3.UP.cross(towards).normalized(), Vector3.UP, towards)
	var model := MONITOR.instantiate() as Node3D
	model.name = "DellMonitor"
	monitor.add_child(model)
	screen = model.find_child("Screen", true, false) as MeshInstance3D
	screen.reparent(monitor, true)
	(screen as MeshInstance3D).material_override = _cctv()
	var glow := OmniLight3D.new()
	glow.name = "MonitorGlow"
	glow.position = monitor.to_local(screen.global_transform * (screen as MeshInstance3D)
		.get_aabb().get_center()) + Vector3(0, 0, 0.15)
	glow.light_color = SCREEN_GLOW
	glow.light_energy = 0.35
	glow.omni_range = 1.2
	glow.shadow_enabled = false
	monitor.add_child(glow)


## The gate's logbook open on the counter: a hardback cover, two ruled pages, a pen across them.
func _logbook(at: Vector3, dark: Material) -> void:
	logbook = Build.box(self, at + Vector3(0, 0.006, 0), Vector3(0.32, 0.012, 0.44),
		Build.material(Color(0.1, 0.14, 0.26), 0.6))
	logbook.name = "Logbook"
	var page := MeshInstance3D.new()
	page.name = "LogPage"
	var quad := QuadMesh.new()
	quad.size = Vector2(0.3, 0.42)
	page.mesh = quad
	var paper := Build.material(Color.WHITE, 0.85)
	paper.albedo_texture = _ruled_pages()
	page.material_override = paper
	page.position = at + Vector3(0, 0.0135, 0)
	page.rotation = Vector3(-PI / 2.0, -PI / 2.0, 0)
	add_child(page)
	var pen := Build.cylinder(self, at + Vector3(-0.05, 0.02, -0.06), 0.0045, 0.14, dark)
	pen.name = "LogPen"
	pen.rotation = Vector3(PI / 2.0, 0.6, 0)


## A handheld radio standing in its charger, the charger's lamp green.
func _radio(at: Vector3, dark: Material) -> void:
	Build.box(self, at + Vector3(0, 0.02, 0), Vector3(0.08, 0.04, 0.1), dark).name = \
		"RadioCharger"
	Build.box(self, at + Vector3(-0.041, 0.03, 0.03), Vector3(0.004, 0.006, 0.006),
		Build.luminous(Color(0.2, 1.0, 0.3), 1.5)).name = "ChargerLamp"
	_place(_prop(RADIO, "Radio", TO_GUARD), at + Vector3(0, 0.025, 0), "counter")


## Two facing pages ruled in blue, a red margin each, the first rows filled in a hand's pencil.
func _ruled_pages() -> ImageTexture:
	var image := Image.create(240, 168, true, Image.FORMAT_RGB8)
	image.fill(Color(0.93, 0.92, 0.87))
	for x in range(image.get_width()):
		for row in range(8, image.get_height(), 7):
			image.set_pixel(x, row, Color(0.62, 0.72, 0.86))
	for page in range(2):
		var margin := page * 120 + 14
		for y in range(image.get_height()):
			image.set_pixel(margin, y, Color(0.85, 0.4, 0.4))
		var draw := RandomNumberGenerator.new()
		draw.seed = 48 + page
		for row in range(1, 14 if page == 0 else 6):
			var x := margin + 3
			while x < page * 120 + 112:
				var word := draw.randi_range(4, 14)
				for step in range(word):
					var y := 8 + row * 7 - 2 - draw.randi_range(0, 2)
					image.set_pixel(mini(x + step, 239), y, Color(0.28, 0.28, 0.32))
				x += word + 3
	for y in range(image.get_height()):
		image.set_pixel(119, y, Color(0.7, 0.68, 0.62))
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


func _seat(guard_scene: PackedScene, guard_name: String, dark: Material) -> void:
	var chair := Node3D.new()
	chair.name = "Chair"
	chair.position = Vector3(SEAT.x - 0.06, PLINTH, SEAT.z)
	add_child(chair)
	var model := CHAIR.instantiate() as Node3D
	model.name = "DraughtsmanChair"
	model.rotation.y = PI / 2.0
	chair.add_child(model)
	var seat_top := Marker3D.new()
	seat_top.name = "SeatTop"
	seat_top.position = Vector3.UP * SEAT_HEIGHT
	chair.add_child(seat_top)
	guard = guard_scene.instantiate() as Node3D
	guard.name = guard_name
	guard.set_meta("stand_in", true)
	guard.position = Vector3(SEAT.x, PLINTH, SEAT.z)
	guard.rotation.y = PI / 2.0
	add_child(guard)
	var player := guard.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	player.play("SitIdle")
	player.advance(0.0)
	var skeleton := guard.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	_pull_chair_in(chair, skeleton)
	var head := skeleton.find_bone("Bip01 Head")
	var rest := (skeleton.global_basis * skeleton.get_bone_global_rest(head).basis) \
		.orthonormalized()
	var front := guard.global_basis.z.normalized()
	var best := 0.0
	var axis := 0
	var upward := 0.0
	var turn_axis := 0
	for index in range(3):
		var along := rest[index].dot(front)
		if absf(along) > best:
			best = absf(along)
			axis = index * 2 + (0 if along > 0.0 else 1)
		if absf(rest[index].dot(Vector3.UP)) > upward:
			upward = absf(rest[index].dot(Vector3.UP))
			turn_axis = index
	_look = Marker3D.new()
	_look.name = "GuardLook"
	add_child(_look)
	_look.global_position = screen.global_position
	_wanted_look = screen.global_position
	var look := LookAtModifier3D.new()
	look.name = "GuardHead"
	look.bone_name = "Bip01 Head"
	look.forward_axis = axis as SkeletonModifier3D.BoneAxis
	look.primary_rotation_axis = turn_axis as Vector3.Axis
	look.duration = 0.6
	look.use_angle_limitation = true
	look.symmetry_limitation = true
	look.primary_limit_angle = deg_to_rad(NECK_LIMIT)
	look.primary_damp_threshold = 0.8
	look.secondary_limit_angle = deg_to_rad(40.0)
	look.secondary_damp_threshold = 0.8
	look.transition_type = Tween.TRANS_SINE
	look.ease_type = Tween.EASE_IN_OUT
	skeleton.add_child(look)
	look.target_node = look.get_path_to(_look)
	_make_reach(skeleton)


## Seats her as a person pulls her chair in to the counter: her shoulder SHOULDER_IN from the
## booth's middle toward the window, whatever her build and sitting clip, her toes TOE_CLEAR from
## the front wall.
func _pull_chair_in(chair: Node3D, skeleton: Skeleton3D) -> void:
	var at := func(bone: String) -> Vector3:
		return to_local(skeleton.global_transform * skeleton.get_bone_global_pose(
			skeleton.find_bone(bone)).origin)
	var shoulder: Vector3 = at.call(ARM_BONES[0])
	var toes := maxf((at.call("Bip01 L Toe0") as Vector3).x, (at.call("Bip01 R Toe0") as Vector3).x)
	var room := SIZE.x / 2.0 - WALL / 2.0 - TOE_CLEAR - toes
	var shift := clampf(SHOULDER_IN - shoulder.x, -0.2, room)
	chair.position.x += shift
	guard.position.x += shift


## Her lean and her left arm's reach for the sash's pull: a lean from her hips (first, so the
## head's look and the arm follow it), a two-bone IK placing her wrist, her elbow toward ARM_POLE,
## and her hand turned as it holds the pull.
func _make_reach(skeleton: Skeleton3D) -> void:
	_skeleton = skeleton
	_lean = GuardLean.new()
	_lean.name = "GuardLean"
	_lean.set("side", guard.global_basis.x.normalized())
	_lean.set("angle", LEAN_LEAST)
	skeleton.add_child(_lean)
	skeleton.move_child(_lean, 0)
	_twist = GuardLean.new()
	_twist.name = "GuardTwist"
	_twist.set("bones", PackedStringArray(["Bip01 Spine1", "Bip01 Spine2"]))
	_twist.set("side", Vector3.UP)
	_twist.set("angle", 0.0)
	skeleton.add_child(_twist)
	skeleton.move_child(_twist, 1)
	_arm = TwoBoneIK3D.new()
	_arm.name = "GuardArmL"
	_arm.set_setting_count(1)
	skeleton.add_child(_arm)
	_arm.set_root_bone_name(0, ARM_BONES[0])
	_arm.set_middle_bone_name(0, ARM_BONES[1])
	_arm.set_end_bone_name(0, ARM_BONES[2])
	_arm_target = Marker3D.new()
	_arm_target.name = "GuardArmLTarget"
	_arm_target.top_level = true
	guard.add_child(_arm_target)
	var pole := Marker3D.new()
	pole.name = "GuardArmLPole"
	pole.position = ARM_POLE
	guard.add_child(pole)
	_arm.set_target_node(0, _arm.get_path_to(_arm_target))
	_arm.set_pole_node(0, _arm.get_path_to(pole))
	skeleton.skeleton_updated.connect(_remember_grip)
	_turn = HandTurn.new()
	_turn.name = "GuardHandLTurn"
	_turn.set("bone_name", ARM_BONES[2])
	skeleton.add_child(_turn)
	_hold_pull(0.0)


func _cctv() -> StandardMaterial3D:
	var image := Image.create(64, 36, false, Image.FORMAT_RGB8)
	image.fill(Color(0.02, 0.02, 0.025))
	var tones: Array[Color] = [Color(0.22, 0.26, 0.3), Color(0.16, 0.19, 0.21),
		Color(0.25, 0.25, 0.27), Color(0.12, 0.15, 0.18)]
	for pane in range(4):
		var left := 1 + (pane % 2) * 32
		var high := 1 + floori(pane / 2.0) * 18
		for y in range(16):
			for x in range(30):
				image.set_pixel(left + x, high + y, tones[pane] * (0.75 + 0.25 * y / 16.0))
	var glow := Build.luminous(Color(1.4, 1.5, 1.6))
	glow.albedo_texture = ImageTexture.create_from_image(image)
	return glow
