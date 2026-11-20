extends Node3D
## Bay 9's dock worker (docs/PHASE_BRIEF.md, step 2e-3, rule H5; step 3 of #253; the author's L2 b,
## #230, and C58): Microsoft Rocketbox's Construction_Male_08, a stand-in. Between jobs he sits at
## his dock desk (dock_station.gd) by the door he works, in Rocketbox's seated idle at a table.
## Called once a loaded van's rear doors are shut, he stands up from the desk, takes the seal log
## from it in his hand, walks over the dock floor between the desk and bay 9's staged load to the
## stair's landing, down the dock stair and out by the shed's side door, round to the van's doors.
## There he seals them as C-TPAT's seal check asks, view, verify, tug, twist: the bolt through the
## hasp and its cap snapped on, tugged and twisted (Seal), the number checked against his log
## (Check) and noted (Note). Then he walks back the same way, puts the log down and sits at his
## desk again, the chair rolling back as he rises and in under him as he sits. He waits rather
## than walk into anyone: Ethan is the only one about. He reads the van and changes it only by
## sealing it. Since part G of step 5 he also scans each pallet Ethan sets down on bay 9's lift
## (`go_scan`, #302). Since the audit's fourth fix (#329) he gets up to pace and slows to his stops
## (Rocketbox's walk start and stop), turns on the spot to face what he works at (its turns),
## takes the dock stair a tread a step with his hand on the rail and the log in his other hand
## (`worker_stair.gd`), holds the seal until it is on the hasp and a pen as he notes, and his
## scanner lights only as he aims it at a load's shipping label, beeping with a green flash.

signal sealed
## A pallet's label read with his handheld scanner as Ethan set it down on bay 9's lift (#302).
signal scanned(load: Node3D)

const Model = preload("res://features/characters/dock_worker/dock_worker.glb")
const WorkerStair = preload("res://features/characters/dock_worker/worker_stair.gd")
const CLIPBOARD := "res://features/environments/industrial_loop/art/dock_station/models/" \
	+ "clipboard/clipboard.gltf"
## A steady adult walk, 1.4 m/s (the usual average walking pace).
const WALK := 1.4
const TURN_RATE := 8.0
const ARRIVE := 0.05
const KEEP_CLEAR := 0.75
const SEAL_AT := 3.1
const BLEND := 0.25
## Getting going and stopping (#329): up to his pace over half a second, down to a stop over his
## last metre (a steady 0.98 m/s each second); his walk start's and stop's clips play as he does.
const ACCEL := WALK / 0.5
const STOP_OVER := 1.0
const STOP_DECEL := WALK * WALK / (2.0 * STOP_OVER)
const STOPPING := 0.8
const RATE_LEAST := 0.4
## Turning on the spot: under 3 degrees at once in his stance, under 40 over a third of a second
## in his idle, more in Rocketbox's turn of 90 or 180 degrees, his body turned over the first
## two thirds of the clip; setting off, he turns first if his way lies more than 45 degrees off.
const TURN_AT_ONCE := deg_to_rad(3.0)
## Turning as he walks: no faster than 180 degrees a second as he gets going, up to 720 at pace.
const TURN_SLOW := deg_to_rad(180.0)
const TURN_FAST := deg_to_rad(720.0)
## He creeps the last of his way to stand just where he stops.
const CREEP := 0.15
const ROOM := 2.5
## Pushing his chair in under the desk, or drawing it out, takes him this long.
const TUCK_SECONDS := 0.8
const STEP_UP := 0.4
const DOOR_REACH := 0.5
const CORNER_LEAST := 0.2
const LOOK := 0.25
const ROUND_OFF := 0.15
const ARRIVE_LAST := 0.002
const TURN_SMALL := deg_to_rad(40.0)
const SMALL_SECONDS := 0.35
const TURN_SHARE := 0.66
const SET_OFF_TURN := deg_to_rad(45.0)
## The seal and the pen (#329): a bolt seal, its bolt and barrel cap, in his right hand from his
## first reach for the hasp until it is on it; a ballpoint in his right hand as he notes.
const SEAL_BOLT := Vector2(0.004, 0.085)
const SEAL_CAP := Vector2(0.009, 0.03)
const PEN := Vector2(0.004, 0.14)
## Where the seal and the pen sit in his fingers (#338): the bolt between the tips of his thumb
## and index finger, and the pen's tip 2 cm on from his index finger's last joint, its shaft back
## over the web of his thumb, as a pen is held.
const TIP_ON := 0.02
## His hands on the hasp as he seals (#336, #338). The hasp is 0.9 m over his feet, at his hips,
## so he works at it as a man does at that height: half crouched, his knees bent and his left foot
## a step ahead (the rise held at RISE_FROM, his hips 0.68 m up); not leaning back
## as the clip of a man trying a door did, which left his arms locked straight; his hands in from
## 0.6 s, held through pushing the bolt in at 3.1 s, his left off by 5.0 s and the check begun at
## 5.2 s, his right staying on the seal. His right hand's wrist 9 cm out from the doors and 5 cm
## right of the hasp, his fingers toward the doors and to the left, pinching the bolt; his left
## 8 cm out and 7 cm left of it, palm to the door and fingers up, steadying the hasp; both elbows
## bent.
const RISE_FROM := 1.6
const HANDS_ON := Vector2(0.6, 1.2)
const HANDS_OFF := Vector2(4.3, 5.0)
const SEAL_SECONDS := 5.2
const RIGHT_WRIST := Vector3(0.05, 0.0, 0.09)
const LEFT_WRIST := Vector3(-0.07, 0.02, 0.08)
## At the van, in its frame (x to its right, z out of its rear doors), all from one place, as a
## dock hand does it: where he stands, 0.78 m out from the doors, his shoulders over the step as
## he half crouches to seal and his head clear of the doors; and the log laid on the rear step
## before his right shoulder as he crouches, its middle 0.18 m right of the hasp, its underside
## on the step's top (0.538 m up, from under the doors to its rounded edge 0.25 m out), the
## whole log on it, its long side across it, its far edge under the doors' bottom edge (3 cm
## clear of it) and its near edge at the step's edge (#341: off it, it had seemed to lie on
## nothing), clear of his left foot as it steps ahead (#338).
const LOG_ON_STEP := Vector3(0.18, 0.538, 2.83)
const LOG_ON_STEP_TURN := Basis(Vector3(0, 0, 1), Vector3(0, 1, 0), Vector3(-1, 0, 0))
const AT_HASP := Vector3(0.0, 0.0, 3.66)
## Crouching (Rocketbox's crouch and rise, his left foot a step ahead): the parts of the clips he
## plays, each in seconds of its clip, his hips low from 1.7 s in. Down (CROUCH_IN) to lay the log
## on the step, lowered from his carrying hold over LOWER (in seconds from the start) and let go
## at LET_GO, his hand back off it by HAND_BACK; then half up (the rise from CROUCH_OUT.x to
## RISE_FROM), held there as he seals and checks; then back down (the rise run backwards) to take
## it up, his hand to it over REACH, taken at TAKE, held low TAKE_HOLD, and lifted to his carrying
## hold over LIFT as he rises the whole way (to CROUCH_OUT.y).
const CROUCH_IN := Vector2(0.8, 4.0)
const CROUCH_OUT := Vector2(0.5, 3.2)
const LOWER := Vector2(1.5, 2.6)
const LET_GO := 2.7
const HAND_BACK := 3.2
const REACH := Vector2(0.5, 1.3)
const TAKE := 1.4
const TAKE_HOLD := 0.4
const LIFT := Vector2(1.6, 3.6)
## Checking the seal as the log's header says, view, verify, tug, twist: his right hand on its
## middle, fingers toward the doors and palm to the left, moved there from pushing it home over
## REACH_SEAL, tugging it 12 mm
## out over TUG and twisting it 25 degrees each way over TWIST, then off by SEAL_LET_GO.
const REACH_SEAL := Vector2(0.0, 0.3)
const TUG := Vector2(1.0, 1.6)
const TUG_BY := 0.012
const TWIST := Vector2(1.8, 2.6)
const TWIST_BY := deg_to_rad(25.0)
const SEAL_LET_GO := Vector2(2.7, 3.0)
const ON_THE_SEAL := Vector3(0.025, 0.0, 0.09)
## Handing the log from his right hand to his left before he writes: his right brings it up before
## him by HANDS_TOGETHER, his left taking it over LEFT_ON, his right letting go over RIGHT_OFF.
## Walking, the log hangs at his side from his hand by its edge, as a clipboard is carried (#341);
## held up before him (at FRONT_AT, tilted FRONT_TILT toward him) only to hand it across and
## write.
const PASS_SECONDS := 1.0
const HANDS_TOGETHER := 0.4
const LEFT_ON := Vector2(0.05, 0.4)
const RIGHT_OFF := Vector2(0.45, 0.7)
const FRONT_AT := Vector3(0.0, 1.05, 0.28)
const FRONT_TILT := deg_to_rad(15.0)
## His hips over his feet standing, in the converted model.
const HIPS := 0.89
const ARM_BONES := ["Bip01 %s UpperArm", "Bip01 %s Forearm", "Bip01 %s Hand"]
## The seal log on his clipboard (#337): its printed page (`make_shed_signs.py`), 0.20 x 0.26 m on
## the board below its clip, the current row filled in with this van and its seal's number, and
## the tick he puts in its OK column with his pen as he notes: his right hand brought to the page
## by arm IK, the pen's tip drawing the tick's two strokes, the ink following it; the desk's log
## shows it too once he puts the log back. In the page's pixels (400 x 520).
const PAGE_IMAGE := "res://features/environments/industrial_loop/art/fitout/seal_log_page.png"
const PAGE := Vector2(0.20, 0.26)
const PAGE_AT := Vector3(0.0, 0.0055, 0.01)
const PAGE_PX := Vector2(400.0, 520.0)
const TICK_PX: Array[Vector2] = [Vector2(335.0, 375.0), Vector2(350.0, 390.0),
	Vector2(378.0, 358.0)]
const ROW_PX: Array[Vector2] = [Vector2(60.0, 376.0), Vector2(180.0, 376.0),
	Vector2(285.0, 376.0)]
const ROW_LABELS: Array[String] = ["VanPlate", "SealNumber", "SealedBy"]
const VAN_PLATE := "BR 048"
## His initials, as in the BY column of the rows before; the page's hand at its type's size (19 px
## of its 520 px), shaded as its printed ink is.
const INITIALS := "R.M."
const ROW_PIXEL := 0.00024
const INK := Color(0.11, 0.16, 0.43)
const TICK_WIDE := 0.0016
const INK_ABOVE := 0.0004
const PEN_ON := Vector2(0.3, 0.75)
const STROKES := Vector3(0.85, 1.1, 1.55)
const PEN_OFF := Vector2(2.0, 2.4)
## The log held up to write on, as a man holds a clipboard in his hand: its middle this far
## across (to his right), up from his feet and before him, its page tilted this far from flat
## toward his eyes; raised as he starts noting, turned from the van's doors, and lowered with the
## pen (#337).
const BOARD_AT := Vector3(0.0, 1.1, 0.3)
const BOARD_TILT := deg_to_rad(40.0)
const BOARD_ON := Vector2(0.0, 0.5)
## Lowered once his pen is off it and he has looked over the row he ticked.
const BOARD_OFF := Vector2(2.9, 3.35)
const PEN_LIFT := 0.012
## The scan's look (#329): he aims 0.8 s in, the aiming line on 0.4 s, then the beep and the
## good-read light's green flash of 0.2 s.
const AIM_AT := 0.8
const AIM_SECONDS := 0.4
const FLASH_SECONDS := 0.2
const AIM_COLOUR := Color(1.0, 0.05, 0.03)
const GOOD_READ := Color(0.1, 1.0, 0.2)
const AIM_THICK := 0.002
const PEOPLE := 4
## A practised dock hand's look at the seal against his log and his note of it, in seconds.
const CHECK_SECONDS := 3.0
const NOTE_SECONDS := 3.5
## The desk clips' own root motion, as measured on the converted model (dock_worker.glb): seated,
## his hips 0.576 m up over the node; sitting down ends 0.126 m to his left and 0.672 m ahead of
## where it began; standing up ends 0.514 m to his right and 0.165 m ahead of the seat.
const SIT_FROM := Vector3(-0.126, 0.0, 0.672)
const STAND_TO := Vector3(-0.514, 0.0, 0.165)
## His hips sit 0.05 m behind the chair's column, over the cushion's middle.
const SEAT_BACK := 0.05
## How far the chair rolls back as he rises and is drawn in as he sits.
const CHAIR_ROLL := 0.3
## His hand's hold on the log: the clipboard in the left hand, held flat against the forearm.
const HAND := "Bip01 L Hand"
## The scan (part G of step 5 of #253, #302): from beside the lift's deck, off its north-east
## corner and clear of Ethan's way and of the pendant (at the deck's north-west corner), he reads
## the label of a pallet just set down on bay 9's lift with a handheld scanner in his right hand,
## its beep a second into the look, and goes back to his desk.
const SCAN_AT := Vector3(-46.6, 1.3, 17.05)
const SCAN_SECONDS := 3.0
const LIFT_DECK := Vector2(1.87, 2.46)
const BEEP_AT := AIM_AT + AIM_SECONDS
const SCANNER_HAND := "Bip01 R Hand"
const SCANNER_AT := Vector3(-0.06, 0.03, 0.02)
const SCANNER := Vector3(0.07, 0.17, 0.045)
const BEEP := preload("res://features/audio/shed/scanner_beep.wav")
## The log carried in either hand, in the hand's own frame (its x along his fingers, its y out
## of his palm, toward his thigh as his arm hangs): pinched by its top edge between his thumb and
## fingers, hanging along his leg clear of it, its page to his thigh; at its true size, the
## skeleton's 1/100 scale undone (#337).
const HOLD := Transform3D(Basis(Vector3(0, 0, -1), Vector3(0, 1, 0), Vector3(1, 0, 0)),
	Vector3(0.23, -0.015, 0.0))
## And carried before him or as he writes, his wrist in the board's frame: the board resting on
## his palm under its left edge (his left hand) or its right (his right), his fingers along under
## it; and setting it on the step or taking it up, his right palm down on its near edge, his
## fingers over its margin.
const BOARD_GRIP := Transform3D(Basis.IDENTITY, Vector3(-0.135, -0.045, 0.03))
const RIGHT_GRIP := Transform3D(Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, -1)),
	Vector3(0.135, -0.045, 0.03))
const EDGE_GRIP := Transform3D(Basis(Vector3(-1, 0, 0), Vector3(0, -1, 0), Vector3(0, 0, 1)),
	Vector3(0.174, 0.035, 0.0))
const POLES := {"L": Vector3(0.5, 0.6, -0.4), "R": Vector3(-0.5, 0.6, -0.4)}
const HAND_TURN := preload("res://features/characters/dock_worker/hand_turn.gd")

var home := true
## How far the van's rear is from the dock's bumpers (bay 9's `clearance()`): he goes out to seal
## it only with ROOM behind it to stand in, and waits by the side door, or where he is, until
## there is (#333).
var room_behind := Callable()
## The shed's side door (`dock_access.gd`): shut, he stops inside it and pushes it open, going on
## once it has swung open (#333).
var side_door: Node3D
## Bay 9's lift: he waits rather than step onto its deck while it is not up at the dock floor
## (his chair's sitting-down place is 5 cm onto its east rim).
var lift: Node3D
var state := "seated"

var _model: Node3D
var _player: AnimationPlayer
var _inside := Vector3.ZERO
var _way: Array[Vector3] = []
var _desk_way: Array[Vector3] = []
var _stair_way: Array[Vector3] = []
var _route: Array[Vector3] = []
var _van: Node3D
var _number := ""
var _timer := 0.0
var _query := PhysicsShapeQueryParameters3D.new()
var _ray := PhysicsRayQueryParameters3D.new()
var _chair: Node3D
var _chair_home := Transform3D.IDENTITY
var _log: Node3D
var _clipboard: Node3D
var _seated := Vector3.ZERO
var _facing := Vector3.RIGHT
var _job := "seal"
var _scan_load: Node3D
var _scanner: Node3D
var _beep: AudioStreamPlayer3D
var _speed := 0.0
var _starting := false
var _stair_walk: RefCounted
var _turn_from := 0.0
var _turn_by := 0.0
var _turn_for := 0.0
var _then := Callable()
var _right_log: Node3D
var _seal_in_hand: Node3D
var _pen: Node3D
var _window: MeshInstance3D
var _window_lit: StandardMaterial3D
var _window_dark: StandardMaterial3D
var _aim_line: MeshInstance3D
var _good_read: Node3D
var _aim_label: Node3D
var _past_door := false
var _arms := {}
var _arm_targets := {}
var _hand_turns := {}
var _skeleton: Skeleton3D
var _held := HOLD
var _hand_scale := 1.0
var _board_floor := 0.0
var _on_step := false
var _step_board: Node3D
var _pen_on := 0.0
var _pen_reach := Transform3D.IDENTITY
var _tools: Node3D
var _pages: Array[Node3D] = []
var _tick := 0.0


## `inside` is the side door's inside, `way` the points from there to the van's back; `station`
## his dock desk (its chair and seal log), `desk_way` the points from beside his chair to the
## stair's landing and `stair_way` from the landing down the stair to `inside`.
func setup(inside: Vector3, way: Array[Vector3], station: Node3D,
		desk_way: Array[Vector3], stair_way: Array[Vector3]) -> void:
	_inside = inside
	_way = way
	_desk_way = desk_way
	_stair_way = stair_way
	_chair = station.get("chair") as Node3D
	_chair_home = _chair.global_transform
	_log = station.get_node("SealLog") as Node3D
	var desk: Vector3 = station.get_node("Desk").global_position
	_facing = Vector3(desk.x - _chair_home.origin.x, 0.0, desk.z - _chair_home.origin.z) \
		.normalized()
	_seated = _chair_home.origin - _facing * SEAT_BACK
	_model = Model.instantiate() as Node3D
	_model.name = "Model"
	add_child(_model)
	_player = _model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	_skeleton = _model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	_hold_clipboard()
	_hold_scanner()
	_hold_seal_and_pen()
	_make_arms()
	for board: Node3D in [_clipboard, _right_log, _log]:
		if board != null:
			_pages.append(_add_page(board))
	_board_floor = _lowest(_log)
	_skeleton.skeleton_updated.connect(_in_fingers)
	_draw_tick()
	var body := SphereShape3D.new()
	body.radius = KEEP_CLEAR
	_query.shape = body
	_query.collision_mask = PEOPLE
	_ray.collision_mask = 1
	reset()


func reset() -> void:
	state = "seated"
	home = true
	_van = null
	_route.clear()
	visible = true
	global_position = _seated
	_model.rotation.y = _heading(_facing)
	_chair.global_transform = _chair_home
	_carry(false)
	_carry_scanner(false)
	_scan_load = null
	_job = "seal"
	_speed = 0.0
	if _stair_walk != null:
		_stair_walk.call("reset")
	_show_seal(false)
	_show_pen(false)
	_aim(false)
	_off_step()
	for side: String in _arms:
		_reach(side, 0.0, Transform3D.IDENTITY)
	_player.play("SitIdle")


## The dock stair he takes, as `dock_access.gd`'s `stair()` and `rail_top()` give it.
func use_stair(stair: Dictionary, rail: Array[Vector3]) -> void:
	var skeleton := _model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	_stair_walk = WorkerStair.new()
	_stair_walk.call("setup", _model, skeleton, stair, rail[0], rail[1])


## Where his scanner's aiming line ends: the label he aims at.
func aim_end() -> Vector3:
	return _aim_label.global_position if _aim_label != null else global_position


## Over to bay 9's lift to scan `load`'s label, if he is at his desk.
func go_scan(load: Node3D) -> void:
	if state != "seated" or load == null:
		return
	_scan_load = load
	_job = "scan"
	state = "standing"
	home = false
	_timer = 0.0
	_player.play("StandUp", BLEND)


## Out to `van`'s rear doors to seal them with the seal numbered `number`.
func go_seal(van: Node3D, number: String) -> void:
	if state != "seated":
		return
	_van = van
	_number = number
	_past_door = false
	_tick = 0.0
	for page in _pages:
		_fill_row(page, [VAN_PLATE, number, INITIALS])
	_draw_tick()
	_job = "seal"
	state = "standing"
	home = false
	_timer = 0.0
	_player.play("StandUp", BLEND)


func _physics_process(delta: float) -> void:
	match state:
		"standing":
			_stand(delta)
		"turning":
			_turning(delta)
		"tucking":
			_tuck(delta)
		"untucking":
			_untuck(delta)
		"out", "back", "to_scan":
			_walk(delta)
		"sealing", "checking", "noting":
			_seal(delta)
		"setting_down", "taking_up":
			_crouch(delta)
		"passing":
			_pass(delta)
		"scanning":
			_scan(delta)
		"sitting":
			_sit(delta)
	_hands(delta)


func _stand(delta: float) -> void:
	_timer += delta
	var length := _player.get_animation("StandUp").length
	_roll(clampf(_timer / length, 0.0, 1.0))
	if _timer < length:
		return
	global_position = _seated + _local(STAND_TO)
	state = "tucking"
	_timer = 0.0
	_play("Idle")


## His chair pushed back in under the desk behind him before he sets off, as a tidy worker does,
## so his way round behind it is clear of it (#333).
func _tuck(delta: float) -> void:
	_timer += delta
	_roll(1.0 - smoothstep(0.0, 1.0, clampf(_timer / TUCK_SECONDS, 0.0, 1.0)))
	if _timer < TUCK_SECONDS:
		return
	if _job == "scan":
		_carry_scanner(true)
		_set_off("to_scan", [SCAN_AT] as Array[Vector3])
		return
	_carry(true, true)
	var route := _desk_way.duplicate()
	route.append_array(_stair_way)
	route.append(_inside)
	route.append_array(_way)
	route.append(_at_van(AT_HASP))
	_set_off("out", route)


## Off along `route` as `next`: turned on the spot first if his way lies well off where he faces,
## then getting going in his walk's start.
func _set_off(next: String, route: Array[Vector3]) -> void:
	_route = route
	var to := route[0] - global_position if not route.is_empty() else Vector3.ZERO
	to.y = 0.0
	var go := func() -> void:
		state = next
		_speed = 0.0
		_starting = true
		_player.play("WalkStart", BLEND)
	if to.length() > ARRIVE and absf(_off_by(to)) > SET_OFF_TURN:
		_turn_to(to, go)
	else:
		go.call()


## Turns him on the spot to face `direction`, then calls `then`.
func _turn_to(direction: Vector3, then: Callable) -> void:
	var by := _off_by(direction)
	if absf(by) <= TURN_AT_ONCE:
		_model.rotation.y += by
		then.call()
		return
	state = "turning"
	_then = then
	_timer = 0.0
	_turn_from = _model.rotation.y
	_turn_by = by
	if absf(by) <= TURN_SMALL:
		_turn_for = SMALL_SECONDS
		_play("Idle")
		return
	var clip := "Turn%s%d" % ["Left" if by > 0.0 else "Right", 90 if absf(by) <= deg_to_rad(135.0)
		else 180]
	_turn_for = _player.get_animation(clip).length * TURN_SHARE
	_player.play(clip, BLEND)


func _turning(delta: float) -> void:
	_timer += delta
	var share := clampf(_timer / _turn_for, 0.0, 1.0)
	_model.rotation.y = _turn_from + _turn_by * smoothstep(0.0, 1.0, share)
	if share < 1.0:
		return
	var then := _then
	_then = Callable()
	then.call()


## How far, signed, he must turn to face `direction`.
func _off_by(direction: Vector3) -> float:
	return wrapf(atan2(direction.x, direction.z) - _model.rotation.y, -PI, PI)


func _walk(delta: float) -> void:
	if _route.is_empty():
		_arrived()
		return
	var down := state == "out"
	var left := _left()
	if left < ARRIVE_LAST:
		_route.clear()
		return
	var door_shut := side_door != null and float(side_door.call("swung")) < 1.0
	var waiting := state == "out" and (not _room() or door_shut) and (_past_door
		or _route[0].is_equal_approx(_inside))
	if waiting:
		var to_next := Vector3(_route[0].x - global_position.x, 0.0, _route[0].z - global_position.z)
		left = minf(left, to_next.length())
		if to_next.length() < ARRIVE_LAST or (_speed <= CREEP and _past_door):
			_speed = 0.0
			_play("Idle")
			if door_shut and not bool(side_door.get("door_open")) \
					and Vector2(global_position.x - _inside.x, global_position.z - _inside.z) \
					.length() < DOOR_REACH:
				side_door.call("open_door")
			return
	var on_stair := _stair_walk != null and bool(_stair_walk.call("near", global_position))
	var wanted := float(_stair_walk.call("pace", down)) if on_stair else WALK
	wanted = minf(wanted, _corner_pace())
	wanted = maxf(minf(wanted, sqrt(2.0 * STOP_DECEL * left)), CREEP)
	_speed = move_toward(_speed, wanted, ACCEL * delta)
	var step := _along_route(_speed * delta) if not waiting else Vector3(_route[0].x
		- global_position.x, 0.0, _route[0].z - global_position.z).limit_length(_speed * delta)
	_past_door = _past_door or (Vector2(global_position.x - _inside.x,
		global_position.z - _inside.z).length() < ROUND_OFF and state == "out")
	if _crowded(global_position + step) or _over_lowered_lift(global_position + step):
		_speed = 0.0
		_play("Idle")
		return
	var ahead := Vector3(_route[0].x - global_position.x, 0.0, _route[0].z - global_position.z) \
		if not _route.is_empty() else step
	_face(ahead if ahead.length() > ARRIVE else step, delta)
	global_position += step
	var ground := _ground(global_position)
	global_position.y = float(_stair_walk.call("step", global_position, down,
		_model.global_basis.z.normalized(), ground, delta)) if _stair_walk != null else ground
	_walk_clip(on_stair, down, left)


## His walk's clip and rate: its start as he gets going, its stop over his last steps, and the walk
## itself at his pace, or at a stair's cadence on the flight.
func _walk_clip(on_stair: bool, down: bool, left: float) -> void:
	if _starting and (_player.current_animation != "WalkStart" or _speed >= WALK * 0.95):
		_starting = false
	if _starting:
		return
	if left <= STOPPING and not on_stair:
		_play("WalkStop")
		_player.speed_scale = 1.0
		return
	_play("Walk")
	_player.speed_scale = float(_stair_walk.call("rate", down)) if on_stair \
		else maxf(_speed / WALK, RATE_LEAST)


## Whether there is room behind the van for him to stand in and seal it.
func _room() -> bool:
	return not room_behind.is_valid() or float(room_behind.call()) >= ROOM


## The fastest he may go now to round his route's next corner at a pace its turn allows: full pace
## on a straight, half at a right angle, a fifth doubling back, slowing to it as he comes.
func _corner_pace() -> float:
	if _route.size() < 2:
		return WALK
	var at := Vector3(global_position.x, 0.0, global_position.z)
	var corner := Vector3(_route[0].x, 0.0, _route[0].z)
	var into := corner - at
	var out := Vector3(_route[1].x, 0.0, _route[1].z) - corner
	if into.length() < 0.001 or out.length() < 0.001:
		return WALK
	var turn := into.normalized().dot(out.normalized())
	var pace := WALK * clampf((1.0 + turn) / 2.0, CORNER_LEAST, 1.0)
	return sqrt(pace * pace + 2.0 * STOP_DECEL * into.length())


## His step of `length` along his route, rounding its corners as a walker does: he heads for the
## point LOOK ahead along it, and a corner he has begun to round (within ROUND_OFF) is dropped.
func _along_route(length: float) -> Vector3:
	var at := Vector3(global_position.x, 0.0, global_position.z)
	var aim := _ahead_on_route(at, LOOK)
	var to := aim - at
	if to.length() < 0.0001:
		return Vector3.ZERO
	var step := to.normalized() * minf(length, to.length())
	while _route.size() > 1 and Vector2(_route[0].x - at.x - step.x,
			_route[0].z - at.z - step.z).length() < ROUND_OFF:
		_route.pop_front()
	return step


## The point `look` ahead of `at` along his route, or its end.
func _ahead_on_route(at: Vector3, look: float) -> Vector3:
	var from := at
	for point in _route:
		var flat := Vector3(point.x, 0.0, point.z)
		var run := flat - from
		if run.length() >= look:
			return from + run.normalized() * look
		look -= run.length()
		from = flat
	return from


## How far he has left to walk along his route.
func _left() -> float:
	var total := 0.0
	var from := global_position
	for point in _route:
		total += Vector2(point.x - from.x, point.z - from.z).length()
		from = point
	return total


func _arrived() -> void:
	_speed = 0.0
	_player.speed_scale = 1.0
	if state == "to_scan":
		_aim_label = _facing_label()
		var at := _aim_label.global_position if _aim_label != null else (
			_scan_load.global_position if is_instance_valid(_scan_load)
			else global_position + Vector3.LEFT)
		_turn_to(at - global_position, func() -> void:
			state = "scanning"
			_timer = 0.0
			_player.play("Check", BLEND))
		return
	if state == "out" and is_instance_valid(_van):
		_turn_to(-_van.global_basis.z, func() -> void:
			_timer = 0.0
			state = "setting_down"
			_player.play("CrouchIn", BLEND)
			_player.seek(CROUCH_IN.x, true))
		return
	_turn_to(_facing, func() -> void:
		state = "untucking"
		_timer = 0.0
		_play("Idle"))


## His chair drawn back out from under the desk before he sits, to roll in under him.
func _untuck(delta: float) -> void:
	_timer += delta
	_roll(smoothstep(0.0, 1.0, clampf(_timer / TUCK_SECONDS, 0.0, 1.0)))
	if _timer < TUCK_SECONDS:
		return
	state = "sitting"
	home = true
	_timer = 0.0
	_carry(false)
	_carry_scanner(false)
	_player.play("SitDown", BLEND)


func _seal(delta: float) -> void:
	var before := _timer
	_timer += delta
	_write()
	if state == "sealing":
		if before < SEAL_AT and _timer >= SEAL_AT and is_instance_valid(_van) \
				and not bool(_van.get("rear_doors_open")):
			_van.call("put_seal", _number)
			_show_seal(false)
			sealed.emit()
		if _timer >= SEAL_SECONDS:
			state = "checking"
			_timer = 0.0
	elif state == "checking" and _timer >= CHECK_SECONDS:
		state = "taking_up"
		_timer = 0.0
		_player.speed_scale = -1.0
	elif state == "noting" and _timer >= NOTE_SECONDS:
		_show_pen(false)
		_set_off("back", _route)


## Crouching at the van's rear step (#338): down (CROUCH_IN of Rocketbox's crouch), the log laid
## on the step, and half up again (the rise to RISE_FROM), held there to seal; or, the check done,
## back down (the rise run backwards), the log taken up, and up the whole way, to hand it to his
## left.
func _crouch(delta: float) -> void:
	var before := _timer
	_timer += delta
	var down := CROUCH_IN.y - CROUCH_IN.x
	var half := RISE_FROM - CROUCH_OUT.x
	if state == "setting_down":
		if before < down and _timer >= down:
			_player.play("CrouchOut", BLEND)
			_player.seek(CROUCH_OUT.x, true)
		if before < LET_GO and _timer >= LET_GO:
			_onto_step()
		if _timer >= down + half:
			_player.speed_scale = 0.0
			state = "sealing"
			_timer = 0.0
			_show_seal(true)
		return
	if before < half and _timer >= half:
		_player.speed_scale = 0.0
	if before < half + TAKE_HOLD and _timer >= half + TAKE_HOLD:
		_player.speed_scale = 1.0
	if before < TAKE and _timer >= TAKE:
		_off_step()
	if _timer < half + TAKE_HOLD + CROUCH_OUT.y - CROUCH_OUT.x:
		return
	_timer = 0.0
	state = "passing"
	_play("Idle")


## The log handed from his right hand to his left before him, then he notes where he stands, the
## log well clear of the doors (he stands 0.78 m out), and turns to his way back after.
func _pass(delta: float) -> void:
	var before := _timer
	_timer += delta
	if before < RIGHT_OFF.x and _timer >= RIGHT_OFF.x:
		_carry(true)
	if _timer < PASS_SECONDS:
		return
	_route = _way_back()
	_show_pen(true)
	_next("noting", "Note")


## `local` in the van's frame, in the world, on the yard's ground he stands on there.
func _at_van(local: Vector3) -> Vector3:
	var at := _van.to_global(local)
	return Vector3(at.x, _inside.y, at.z)


## His way back from the van to his chair: out of the yard, in by the side door, up the stair and
## across the dock floor.
func _way_back() -> Array[Vector3]:
	var route := _way.duplicate()
	route.reverse()
	route.append(_inside)
	var down := _stair_way.duplicate()
	down.reverse()
	route.append_array(down)
	var over := _desk_way.duplicate()
	over.reverse()
	route.append_array(over)
	route.append(_seated - _local(SIT_FROM))
	return route


func _scan(delta: float) -> void:
	var before := _timer
	_timer += delta
	_aim(_timer >= AIM_AT and _timer < BEEP_AT)
	if before < BEEP_AT and _timer >= BEEP_AT:
		_beep.play()
		scanned.emit(_scan_load)
	_good_read.visible = _timer >= BEEP_AT and _timer < BEEP_AT + FLASH_SECONDS
	if _timer >= SCAN_SECONDS:
		_good_read.visible = false
		_set_off("back", [_seated - _local(SIT_FROM)] as Array[Vector3])


func _next(next: String, clip: String) -> void:
	state = next
	_timer = 0.0
	_player.play(clip, BLEND)


func _sit(delta: float) -> void:
	_timer += delta
	var length := _player.get_animation("SitDown").length
	_roll(1.0 - clampf(_timer / length, 0.0, 1.0))
	if _timer < length:
		return
	reset()


## The chair `share` of its roll back from the desk.
func _roll(share: float) -> void:
	_chair.global_transform = Transform3D(_chair_home.basis,
		_chair_home.origin - _facing * CHAIR_ROLL * share)


## `offset` in his own frame (facing the desk), in the world.
func _local(offset: Vector3) -> Vector3:
	return Basis(Vector3.UP, _heading(_facing)) * offset


func _heading(direction: Vector3) -> float:
	return atan2(direction.x, direction.z)


## The log in his hand (in his right with `right`, so his left is free for the stair's rail going
## down) or back on his desk.
func _carry(carrying: bool, right := false) -> void:
	if _clipboard != null:
		_clipboard.visible = carrying and not right
	if _right_log != null:
		_right_log.visible = carrying and right
	if _log != null:
		_log.visible = not carrying


func _hold_clipboard() -> void:
	var skeleton := _model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	if skeleton.find_bone(HAND) < 0:
		return
	var hand := BoneAttachment3D.new()
	hand.name = "LeftHand"
	hand.bone_name = HAND
	skeleton.add_child(hand)
	_clipboard = (load(CLIPBOARD) as PackedScene).instantiate() as Node3D
	_clipboard.name = "Clipboard"
	hand.add_child(_clipboard)
	var scale := 1.0 / maxf(skeleton.global_basis.get_scale().x, 0.0001)
	_hand_scale = scale
	_held = Transform3D(HOLD.basis.scaled(Vector3.ONE * scale), HOLD.origin * scale)
	_clipboard.transform = _held
	var right := BoneAttachment3D.new()
	right.name = "RightHandLog"
	right.bone_name = SCANNER_HAND
	skeleton.add_child(right)
	_right_log = (load(CLIPBOARD) as PackedScene).instantiate() as Node3D
	_right_log.name = "ClipboardRight"
	right.add_child(_right_log)
	_right_log.transform = _held
	_right_log.visible = false


## A handheld barcode scanner, its body and grip, in his right hand while he scans.
func _hold_scanner() -> void:
	var skeleton := _model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	if skeleton.find_bone(SCANNER_HAND) < 0:
		return
	var hand := BoneAttachment3D.new()
	hand.name = "RightHand"
	hand.bone_name = SCANNER_HAND
	skeleton.add_child(hand)
	_scanner = Node3D.new()
	_scanner.name = "Scanner"
	hand.add_child(_scanner)
	var scale := 1.0 / maxf(skeleton.global_basis.get_scale().x, 0.0001)
	_scanner.scale = Vector3.ONE * scale
	_scanner.position = SCANNER_AT * scale
	var casing := StandardMaterial3D.new()
	casing.albedo_color = Color(0.12, 0.13, 0.14)
	casing.roughness = 0.5
	_window_dark = StandardMaterial3D.new()
	_window_dark.albedo_color = Color(0.08, 0.04, 0.04)
	_window_dark.roughness = 0.2
	_window_lit = StandardMaterial3D.new()
	_window_lit.albedo_color = Color(0.6, 0.05, 0.05)
	_window_lit.emission_enabled = true
	_window_lit.emission = Color(0.8, 0.05, 0.05)
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = SCANNER
	body.mesh = box
	body.material_override = casing
	_scanner.add_child(body)
	_window = MeshInstance3D.new()
	_window.name = "ScannerWindow"
	var glass := BoxMesh.new()
	glass.size = Vector3(SCANNER.x - 0.01, 0.02, 0.005)
	_window.mesh = glass
	_window.material_override = _window_dark
	_window.position = Vector3(0.0, SCANNER.y / 2.0 - 0.012, SCANNER.z / 2.0)
	_scanner.add_child(_window)
	var green := StandardMaterial3D.new()
	green.albedo_color = GOOD_READ
	green.emission_enabled = true
	green.emission = GOOD_READ
	var led := MeshInstance3D.new()
	led.name = "GoodRead"
	var dot := BoxMesh.new()
	dot.size = Vector3(0.012, 0.006, 0.012)
	led.mesh = dot
	led.material_override = green
	led.position = Vector3(0.0, SCANNER.y / 2.0 - 0.03, -SCANNER.z / 2.0)
	led.visible = false
	_scanner.add_child(led)
	_good_read = led
	var beam := StandardMaterial3D.new()
	beam.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam.albedo_color = AIM_COLOUR
	_aim_line = MeshInstance3D.new()
	_aim_line.name = "AimLine"
	var line := BoxMesh.new()
	line.size = Vector3(AIM_THICK, AIM_THICK, 1.0)
	_aim_line.mesh = line
	_aim_line.material_override = beam
	_aim_line.top_level = true
	_aim_line.visible = false
	add_child(_aim_line)
	_scanner.visible = false
	_beep = AudioStreamPlayer3D.new()
	_beep.name = "ScannerBeep"
	_beep.stream = BEEP
	_beep.bus = "Ambience"
	_beep.volume_db = -8.0
	_beep.unit_size = 3.0
	add_child(_beep)


func _carry_scanner(carrying: bool) -> void:
	if _scanner != null:
		_scanner.visible = carrying


## The scanner's trigger held or let go: its window lit red and its aiming line from the window to
## the label while held; dark otherwise.
func _aim(on: bool) -> void:
	if _window == null:
		return
	_window.material_override = _window_lit if on else _window_dark
	_aim_line.visible = on and _aim_label != null
	if not _aim_line.visible:
		return
	var from := _window.global_position
	var to := aim_end()
	var basis := Basis.looking_at(to - from, Vector3.UP)
	basis.z = basis.z * from.distance_to(to)
	_aim_line.global_transform = Transform3D(basis, (from + to) / 2.0)


## Of the load's shipping labels, the one facing him most, on a face toward him.
func _facing_label() -> Node3D:
	if not is_instance_valid(_scan_load):
		return null
	var best: Node3D = null
	var most := 0.0
	for found in _scan_load.find_children("ShippingLabel*", "Node3D", true, false):
		var label := found as Node3D
		var out := label.global_basis.z.normalized()
		var to := (global_position - label.global_position)
		to.y = 0.0
		var facing := out.dot(to.normalized())
		if facing > most:
			most = facing
			best = label
	return best


## The seal log as it was before this mission: no row filled in for its van, no tick (the shed
## starting over, #337).
func forget_log() -> void:
	_tick = 0.0
	for page in _pages:
		_fill_row(page, ["", "", ""])
	_draw_tick()


## Where he is seen noting: the page's middle on the log in his left hand, and his head.
func paper_point() -> Vector3:
	return _clipboard.to_global(_page_point(PAGE_PX / 2.0)) if _clipboard != null \
		else global_position


func head_point() -> Vector3:
	var skeleton := _model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	return (skeleton.global_transform * skeleton.get_bone_global_pose(
		skeleton.find_bone("Bip01 Head"))).origin


## The seal log he is using: in his left hand or his right, or on his desk.
func log_node() -> Node3D:
	if _on_step:
		return _step_board
	for board: Node3D in [_clipboard, _right_log]:
		if board != null and board.visible:
			return board
	return _log


## Whether he is writing: noting, the log still up before him, the tick done or doing.
func writing() -> bool:
	return state == "noting" and _timer < BOARD_OFF.x


## How far his tick is drawn: 0 none, 1 its first stroke, 2 both.
func tick_drawn() -> float:
	return _tick


## The pen's tip, in the world.
func pen_tip() -> Vector3:
	return _pen.to_global(Vector3(0.0, -PEN.y / 2.0, 0.0)) if _pen != null else global_position


## Where the tick's pen stroke is now, on the page in his hand.
func tick_point() -> Vector3:
	var points := _tick_points()
	var at := points[0].lerp(points[1], clampf(_tick, 0.0, 1.0)) if _tick <= 1.0 \
		else points[1].lerp(points[2], clampf(_tick - 1.0, 0.0, 1.0))
	return _clipboard.to_global(at) if _clipboard != null else at


## A point on the page in the page's pixels, in the board's own frame.
func _page_point(px: Vector2) -> Vector3:
	return Vector3((px.x / PAGE_PX.x - 0.5) * PAGE.x, PAGE_AT.y + INK_ABOVE,
		PAGE_AT.z + (px.y / PAGE_PX.y - 0.5) * PAGE.y)


func _tick_points() -> Array[Vector3]:
	var points: Array[Vector3] = []
	for px in TICK_PX:
		points.append(_page_point(px))
	return points


## The seal log's page on `board`: the printed page, this round's row and the tick's two strokes.
func _add_page(board: Node3D) -> Node3D:
	var page := Node3D.new()
	page.name = "SealLogPage"
	board.add_child(page)
	var paper := StandardMaterial3D.new()
	paper.albedo_texture = load(PAGE_IMAGE) as Texture2D
	paper.roughness = 0.85
	var sheet := MeshInstance3D.new()
	sheet.name = "Sheet"
	var quad := QuadMesh.new()
	quad.size = PAGE
	sheet.mesh = quad
	sheet.material_override = paper
	sheet.position = PAGE_AT
	sheet.rotation.x = -PI / 2.0
	page.add_child(sheet)
	for index in range(ROW_LABELS.size()):
		var label := Label3D.new()
		label.name = ROW_LABELS[index]
		label.font_size = 40
		label.pixel_size = ROW_PIXEL
		label.modulate = INK
		label.shaded = true
		label.outline_size = 0
		label.double_sided = false
		label.position = _page_point(ROW_PX[index])
		label.rotation.x = -PI / 2.0
		page.add_child(label)
	_fill_row(page, [VAN_PLATE, _number, INITIALS] if not _number.is_empty() else ["", "", ""])
	var ink := StandardMaterial3D.new()
	ink.albedo_color = INK
	ink.roughness = 0.4
	for index in range(2):
		var stroke := MeshInstance3D.new()
		stroke.name = "TickStroke%d" % (index + 1)
		var line := BoxMesh.new()
		line.size = Vector3(1.0, 0.0003, TICK_WIDE)
		stroke.mesh = line
		stroke.material_override = ink
		page.add_child(stroke)
	return page


## This round's row on `page`: the van, its seal's number and his initials.
func _fill_row(page: Node3D, texts: Array) -> void:
	for index in range(ROW_LABELS.size()):
		(page.get_node(ROW_LABELS[index]) as Label3D).text = texts[index]


## The tick as far as it is drawn, on every page.
func _draw_tick() -> void:
	var points := _tick_points()
	for page in _pages:
		for index in range(2):
			var stroke := page.get_node("TickStroke%d" % (index + 1)) as MeshInstance3D
			var share := clampf(_tick - index, 0.0, 1.0)
			var run := (points[index + 1] - points[index]) * share
			stroke.visible = share > 0.0
			if not stroke.visible:
				continue
			var along := run.normalized()
			stroke.transform = Transform3D(Basis(run, Vector3.UP, along.cross(Vector3.UP)),
				points[index] + run / 2.0)


## His arms' IK, one an arm, each hand reaching for a target of its own in the world, his elbows
## down and out; and each hand then turned as it holds what it holds (`hand_turn.gd`).
func _make_arms() -> void:
	for side: String in ["L", "R"]:
		var target := Marker3D.new()
		_arms[side] = _arm_reaching("Arm" + side, side, target, POLES[side])
		_arm_targets[side] = target
		var turn := HAND_TURN.new()
		turn.name = "Hand%sTurn" % side
		turn.set("bone_name", String(ARM_BONES[2]) % side)
		_skeleton.add_child(turn)
		turn.active = false
		turn.influence = 0.0
		_hand_turns[side] = turn


func _arm_reaching(label: String, side: String, target: Marker3D, pole_at: Vector3) -> TwoBoneIK3D:
	return _limb(label, side, ARM_BONES, target, pole_at)


## A two-bone IK on his `side` limb (`bones`: its root, middle and end), reaching for `target`, its
## middle joint bent toward `pole_at` in his own frame.
func _limb(label: String, side: String, bones: Array, target: Marker3D,
		pole_at: Vector3) -> TwoBoneIK3D:
	var arm := TwoBoneIK3D.new()
	arm.name = label
	arm.set_setting_count(1)
	_skeleton.add_child(arm)
	arm.set_root_bone_name(0, String(bones[0]) % side)
	arm.set_middle_bone_name(0, String(bones[1]) % side)
	arm.set_end_bone_name(0, String(bones[2]) % side)
	target.name = label + "Target"
	target.top_level = true
	_model.add_child(target)
	var pole := Marker3D.new()
	pole.name = label + "Pole"
	pole.position = pole_at
	_model.add_child(pole)
	arm.set_target_node(0, arm.get_path_to(target))
	arm.set_pole_node(0, arm.get_path_to(pole))
	arm.active = false
	arm.influence = 0.0
	return arm


## His `side` hand `on` of the way to `wrist`: its place and its turn.
func _reach(side: String, on: float, wrist: Transform3D) -> void:
	var arm := _arms[side] as TwoBoneIK3D
	var turn := _hand_turns[side] as SkeletonModifier3D
	arm.influence = on
	arm.active = on > 0.0
	turn.influence = on
	turn.active = on > 0.0
	if on > 0.0:
		(_arm_targets[side] as Marker3D).global_position = wrist.origin
		turn.set("aim", wrist.basis)


## Each tick, what his hands hold and where they reach: the log hung at his side by its edge as he
## walks, laid on the van's step and taken up, brought up before him and handed from his right
## hand to his left, held up to write on; his hands on the hasp, on the seal, and on the page and
## the pen (#338, #341).
func _hands(_delta: float) -> void:
	if _arms.is_empty():
		return
	var carrying := _carried()
	var left := [0.0, Transform3D.IDENTITY]
	var right := [0.0, Transform3D.IDENTITY]
	var side := "R" if carrying == _right_log else "L"
	var grip := RIGHT_GRIP if side == "R" else BOARD_GRIP
	var share := 0.0
	var board := _carry_pose(FRONT_AT.x, FRONT_AT, FRONT_TILT)
	var t := _timer
	match state:
		"setting_down", "taking_up":
			board = _step_pose()
			grip = EDGE_GRIP
			if _on_step:
				var on := 1.0 - smoothstep(LET_GO, HAND_BACK, t) if state == "setting_down" \
					else smoothstep(REACH.x, REACH.y, t)
				right = [on, board * grip]
			else:
				share = smoothstep(LOWER.x, LOWER.y, t) if state == "setting_down" \
					else 1.0 - smoothstep(LIFT.x, LIFT.y, t)
		"passing":
			var up := smoothstep(0.0, HANDS_TOGETHER, t)
			right = [up * (1.0 - smoothstep(RIGHT_OFF.x, RIGHT_OFF.y, t)), board * RIGHT_GRIP]
			left = [smoothstep(LEFT_ON.x, LEFT_ON.y, t), board * BOARD_GRIP]
			_place(_right_log, RIGHT_GRIP, up)
			_place(_clipboard, BOARD_GRIP, 1.0)
			carrying = null
		"sealing":
			right = [smoothstep(HANDS_ON.x, HANDS_ON.y, t), _at_hasp(RIGHT_WRIST, _seal_turn())]
			left = [_on_hasp(), _at_hasp(LEFT_WRIST, _steady_turn())]
		"checking":
			right = [1.0 - smoothstep(SEAL_LET_GO.x, SEAL_LET_GO.y, t), _at_hasp(RIGHT_WRIST,
				_seal_turn()).interpolate_with(_on_seal(t), smoothstep(REACH_SEAL.x,
				REACH_SEAL.y, t))]
		"noting":
			board = board.interpolate_with(_carry_pose(BOARD_AT.x, BOARD_AT, BOARD_TILT),
				smoothstep(BOARD_ON.x, BOARD_ON.y, t))
			share = 1.0 - smoothstep(BOARD_OFF.x, BOARD_OFF.y, t)
			right = [_pen_on, _pen_reach]
	if carrying != null:
		_place(carrying, grip, share)
		var holding := [share, board * grip]
		if side == "R" and right[0] == 0.0:
			right = holding
		elif side == "L" and left[0] == 0.0:
			left = holding
	if _on_step and is_instance_valid(_van):
		_step_board.global_transform = _step_pose()
	_reach("L", left[0], left[1])
	_reach("R", right[0], right[1])


## The log `board` in its hand, `share` of the way from hanging by its edge to held in `grip`.
func _place(board: Node3D, grip: Transform3D, share: float) -> void:
	if board == null or board.top_level:
		return
	var held := grip.affine_inverse()
	board.transform = _held.interpolate_with(Transform3D(held.basis.scaled(Vector3.ONE
		* _hand_scale), held.origin * _hand_scale), share)


## The log in his hand: his right or his left, not on the step.
func _carried() -> Node3D:
	for board: Node3D in [_right_log, _clipboard]:
		if board != null and board.visible and not (_on_step and board == _step_board):
			return board
	return null


## The log held before him: its middle `across` (to his right), `at`'s height over his feet and
## reach before him, with his hips as they go down and up, its page tilted `tilt` toward him.
func _carry_pose(across: float, at: Vector3, tilt: float) -> Transform3D:
	var ahead := _model.global_basis.z
	ahead = Vector3(ahead.x, 0.0, ahead.z).normalized()
	var right := ahead.cross(Vector3.UP)
	var face := Vector3.UP * cos(tilt) - ahead * sin(tilt)
	var top := ahead * cos(tilt) + Vector3.UP * sin(tilt)
	var turn := Basis(right, face, -top)
	var hips := _bone_pose("Bip01 Pelvis").origin
	var under := Vector3(hips.x, global_position.y + hips.y - global_position.y - HIPS, hips.z)
	return Transform3D(turn, under + right * across + Vector3.UP * at.y + ahead * at.z
		- turn * PAGE_AT)


## The log as it lies on the van's rear step.
func _step_pose() -> Transform3D:
	return _van.global_transform * Transform3D(LOG_ON_STEP_TURN, LOG_ON_STEP
		- Vector3.UP * _board_floor) if is_instance_valid(_van) else global_transform


## The log let go of on the step: it lies there, going with the van, until he takes it up.
func _onto_step() -> void:
	var board := _carried()
	if board == null:
		return
	_step_board = board
	_on_step = true
	board.top_level = true
	board.global_transform = _step_pose()


## The log taken up off the step into his hand again.
func _off_step() -> void:
	if _step_board != null:
		_step_board.top_level = false
		_place(_step_board, EDGE_GRIP, 1.0)
	_on_step = false
	_step_board = null


## His hands on the hasp, eased on and off.
func _on_hasp() -> float:
	return smoothstep(HANDS_ON.x, HANDS_ON.y, _timer) * (1.0 - smoothstep(HANDS_OFF.x,
		HANDS_OFF.y, _timer))


## A wrist `offset` from the hasp (to the van's right, up, out of its doors), turned `turn`.
func _at_hasp(offset: Vector3, turn: Basis) -> Transform3D:
	var hasp: Vector3 = _van.call("seal_point") if is_instance_valid(_van) else global_position
	var van := _van.global_basis.orthonormalized() if is_instance_valid(_van) else Basis.IDENTITY
	return Transform3D(turn, hasp + van * offset)


## His right hand pushing the bolt in: fingers toward the doors and to the left, palm down.
func _seal_turn() -> Basis:
	var van := _van.global_basis.orthonormalized() if is_instance_valid(_van) else Basis.IDENTITY
	var fingers := (-van.x * 0.8 - van.z * 0.6).normalized()
	return Basis(fingers, -van.y, fingers.cross(-van.y))


## His left hand steadying the hasp: palm to the door, fingers up and toward it, on from his
## forearm as it comes up from his bent elbow.
func _steady_turn() -> Basis:
	var van := _van.global_basis.orthonormalized() if is_instance_valid(_van) else Basis.IDENTITY
	var fingers := (van.y * 0.6 - van.z * 0.8).normalized()
	var palm := -van.z - fingers * fingers.dot(-van.z)
	palm = palm.normalized()
	return Basis(fingers, palm, fingers.cross(palm))


## His right hand on the bolt seal as he checks it, `t` into the check: on its middle, fingers to
## the doors, palm to the left, thumb up; tugging it out, then twisting it each way.
func _on_seal(t: float) -> Transform3D:
	var van := _van.global_basis.orthonormalized() if is_instance_valid(_van) else Basis.IDENTITY
	var seal := _van.find_child("BoltSeal", true, false) as Node3D if is_instance_valid(_van) \
		else null
	var at: Vector3 = seal.global_position if seal != null else _at_hasp(Vector3.ZERO,
		Basis.IDENTITY).origin
	var tug := sin(PI * clampf((t - TUG.x) / (TUG.y - TUG.x), 0.0, 1.0)) * TUG_BY
	var twist := sin(TAU * clampf((t - TWIST.x) / (TWIST.y - TWIST.x), 0.0, 1.0)) * TWIST_BY
	var turn := Basis(-van.z, -van.x, (-van.z).cross(-van.x))
	return Transform3D(Basis(-van.z, twist) * turn, at + van * ON_THE_SEAL + van.z * tug)


## As he notes: the tick drawn under the pen's tip as his right hand brings it down onto the page,
## its first stroke down to the right, its second up to the right, then the pen lifted off; his
## hand turned to write, palm to the page, fingers up the page and in toward it.
func _write() -> void:
	_pen_on = 0.0
	if state != "noting" or _clipboard == null:
		return
	_pen_on = smoothstep(PEN_ON.x, PEN_ON.y, _timer) * (1.0 - smoothstep(PEN_OFF.x, PEN_OFF.y,
		_timer))
	var drawn := 0.0
	if _timer >= STROKES.x:
		drawn = clampf((_timer - STROKES.x) / (STROKES.y - STROKES.x), 0.0, 1.0) \
			+ clampf((_timer - STROKES.y) / (STROKES.z - STROKES.y), 0.0, 1.0)
	if drawn > _tick:
		_tick = drawn
		_draw_tick()
	var page := _clipboard.global_basis.orthonormalized()
	var lift := 0.0 if _timer >= STROKES.x and _timer <= STROKES.z else PEN_LIFT
	var tip := tick_point() + page.y * lift
	var fingers := (-page.z * 0.75 - page.x * 0.35 - page.y * 0.55).normalized()
	var thumb := page.y * 0.6 - page.x * 0.4
	thumb = (thumb - fingers * fingers.dot(thumb)).normalized()
	var turn := Basis(fingers, thumb.cross(fingers), thumb)
	var hand := _tools.global_position if _tools != null else tip
	_pen_reach = Transform3D(turn, tip - (pen_tip() - hand))


## The pen and the bolt seal in his fingers as he is posed: the pen's tip on from his index
## finger's last joint and its shaft over the web of his thumb; the bolt between the tips of his
## thumb and index finger, pointing to the hasp.
func _in_fingers() -> void:
	if _pen != null and _pen.visible:
		var last := _bone_pose("Bip01 R Finger12").origin
		var tip := last + (last - _bone_pose("Bip01 R Finger11").origin).normalized() * TIP_ON
		var web := (_bone_pose("Bip01 R Finger0").origin + _bone_pose("Bip01 R Finger1").origin) \
			/ 2.0
		var shaft := (web - tip).normalized()
		_pen.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, shaft)), tip
			+ shaft * PEN.y / 2.0)
	if _seal_in_hand != null and _seal_in_hand.visible:
		var pinch := (_bone_pose("Bip01 R Finger02").origin
			+ _bone_pose("Bip01 R Finger12").origin) / 2.0
		var into := -_van.global_basis.x.normalized() if is_instance_valid(_van) \
			else -_model.global_basis.x
		_seal_in_hand.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, into)), pinch)


## A bone of his as last posed, in the world.
func _bone_pose(bone: String) -> Transform3D:
	return _skeleton.global_transform * _skeleton.get_bone_global_pose(_skeleton.find_bone(bone))


## The lowest point of `board` (a clipboard), in its own frame.
func _lowest(board: Node3D) -> float:
	var lowest := 0.0
	var inverse := board.global_transform.affine_inverse()
	for found in board.find_children("*", "MeshInstance3D", true, false):
		var mesh := found as MeshInstance3D
		var box := inverse * mesh.global_transform * mesh.get_aabb()
		lowest = minf(lowest, box.position.y)
	return lowest


## The bolt seal and the pen, each in his right hand while he uses it.
func _hold_seal_and_pen() -> void:
	var skeleton := _model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	if skeleton.find_bone(SCANNER_HAND) < 0:
		return
	var hand := BoneAttachment3D.new()
	hand.name = "RightHandTools"
	hand.bone_name = SCANNER_HAND
	skeleton.add_child(hand)
	_tools = hand
	_seal_in_hand = Node3D.new()
	_seal_in_hand.name = "SealInHand"
	_seal_in_hand.top_level = true
	hand.add_child(_seal_in_hand)
	_rod(_seal_in_hand, SEAL_BOLT, Color(0.75, 0.75, 0.72), 0.0)
	_rod(_seal_in_hand, SEAL_CAP, Color(0.95, 0.75, 0.1), -SEAL_BOLT.y / 2.0)
	_pen = Node3D.new()
	_pen.name = "Pen"
	_pen.top_level = true
	hand.add_child(_pen)
	_rod(_pen, PEN, Color(0.1, 0.15, 0.45), 0.0)
	_show_seal(false)
	_show_pen(false)


func _rod(parent: Node3D, size: Vector2, colour: Color, along: float) -> void:
	var paint := StandardMaterial3D.new()
	paint.albedo_color = colour
	paint.roughness = 0.4
	var shape := CylinderMesh.new()
	shape.top_radius = size.x
	shape.bottom_radius = size.x
	shape.height = size.y
	var rod := MeshInstance3D.new()
	rod.mesh = shape
	rod.material_override = paint
	rod.position = Vector3(0.0, along, 0.0)
	parent.add_child(rod)


func _show_seal(on: bool) -> void:
	if _seal_in_hand != null:
		_seal_in_hand.visible = on


func _show_pen(on: bool) -> void:
	if _pen != null:
		_pen.visible = on


func _face(direction: Vector3, delta: float) -> void:
	var wanted := lerp_angle(_model.rotation.y, atan2(direction.x, direction.z),
		1.0 - exp(-delta * TURN_RATE))
	var most := lerpf(TURN_SLOW, TURN_FAST, clampf(_speed / WALK, 0.0, 1.0)) * delta
	_model.rotation.y += clampf(wrapf(wanted - _model.rotation.y, -PI, PI), -most, most)


## Whether `at` lies over bay 9's lift deck while the deck is not up at the dock floor.
func _over_lowered_lift(at: Vector3) -> bool:
	if lift == null or not is_instance_valid(lift) or bool(lift.call("at_top")):
		return false
	var local := lift.to_local(at)
	return absf(local.x) <= LIFT_DECK.x / 2.0 and absf(local.z) <= LIFT_DECK.y / 2.0


## Whether someone stands where he would step: he waits for them instead of walking through.
func _crowded(at: Vector3) -> bool:
	_query.transform = Transform3D(Basis.IDENTITY, at + Vector3.UP * 0.9)
	return not get_world_3d().direct_space_state.intersect_shape(_query, 1).is_empty()


## The floor under `at`, from no higher than a step above his feet, so that nothing he passes
## beside, such as a load's top, is ever taken for it (#333: his corner past bay 9's load).
func _ground(at: Vector3) -> float:
	_ray.from = at + Vector3.UP * STEP_UP
	_ray.to = at + Vector3.DOWN * 1.0
	var hit := get_world_3d().direct_space_state.intersect_ray(_ray)
	return (hit["position"] as Vector3).y if not hit.is_empty() else at.y


func _play(clip: String) -> void:
	if _player.current_animation != clip:
		_player.play(clip, BLEND)
