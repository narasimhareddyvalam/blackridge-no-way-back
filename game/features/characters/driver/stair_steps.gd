extends RefCounted
## Ethan's feet on a stair (#245–#246, part A). Walking up or down one, his walk keeps its own
## rhythm, slowed going up to a stair's 76 steps a minute and kept near its own 116 going down
## (Di Giulio et al. 2019 measured about 76 up and 117 down), while his legs' IK sets each foot on
## a tread of its own, one tread a step, his feet taking turns: planted where it lands, swung up,
## or out and down, over the nosing between. His hips are lowered so his standing foot reaches its
## tread, his knees a little more bent on the flight, and each foot is lifted as his walk lifts it,
## heel first, so that his toes stay on the tread as his heel rises. Everything is in the world;
## the stair is described as `dock_access.gd`'s `stair()` gives it. Near a stair his body walks
## its hidden incline at the stair's pace (`kept_pace()`, `climb()`). Going up the flight he
## climbs in Mixamo's captured climb (#253-#254), `clip()`, at a stair's cadence walking and at
## its own captured cadence running, his feet set on the treads in its rhythm as in his walk's.

const FPS := 30.0
const CYCLE := 31.0
const STRIKES: Array[float] = [10.0, 25.5]
const LIFTS: Array[float] = [25.0, 10.5]
const SIDES: Array[float] = [0.103, -0.071]
const ANKLE_UP := 0.116
const TOE_REACH := 0.23
const HEEL_BACK := 0.07
const TOE_ROOM := 0.02
const ON_TREAD := 0.015
const BODY_RADIUS := 0.3
const EASE := 0.06
const AHEAD := 0.14
const CLIP_CADENCE := 2.0 * FPS * 60.0 / CYCLE
const CLIMB_CYCLE := 18.0
const WALK_GAIT := {"clip": "Walk", "cycle": CYCLE, "strikes": STRIKES, "lifts": LIFTS,
	"cadence": CLIP_CADENCE, "lifted": true}
const CLIMB_GAIT := {"clip": "StairsUp", "cycle": CLIMB_CYCLE, "strikes": [5.0, 14.0],
	"lifts": [12.0, 2.5], "cadence": 2.0 * FPS * 60.0 / CLIMB_CYCLE, "lifted": false}
const CLIMB_FROM := -0.35
const CLIMB_TO := 0.15
const UP_CADENCE := 76.0
const DOWN_CADENCE := 117.0
const APPROACH := 0.9
const LEAVE := 0.5
const BLEND_RATE := 1.0 / 0.3
const SYNC := 1.5
const SYNC_MOST := 0.2
const LIFT_UP := 0.04
const LIFT_DOWN := 0.03
const SETTLE_RATE := 1.0 / 0.3
const DROP_RATE := 7.0
const DROP_MOST := 0.35
const STAIR_BEND := 0.05
const REACH := 0.81
const SOLE_FALL := 0.543
const HEEL_UP_FALL := 1.3
const STANCE_SLACK := 0.008
const REACH_RATE := 0.6

var stair: Dictionary = {}
var hurry := false
var gait: Dictionary = WALK_GAIT
var entry := -1.0
var _pending: Dictionary = {}
var influence := 0.0
var sense := 1
var targets: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var falls: Array[float] = [SOLE_FALL, SOLE_FALL]
var _lift_falls: Array[float] = [SOLE_FALL, SOLE_FALL]
var drop := 0.0
var _holds: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _froms: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _steps: Array[int] = [0, 0]
var _swinging: Array[bool] = [false, false]
var _swing: Array[float] = [0.0, 0.0]
var _was_frame := -1.0
var _first := -1
var _settled := 0.0
var _drop_speed := 0.0
var _reach_drop := 0.0
var _was_yaw := NAN


func active() -> bool:
	return not stair.is_empty()


## Off any stair at once, as when he takes hold of something or a clip takes him over.
func reset() -> void:
	stair = {}
	influence = 0.0
	drop = 0.0
	_settled = 0.0
	_drop_speed = 0.0
	_reach_drop = 0.0
	_was_yaw = NAN


## Whether `at` is on `on`, or near enough its foot or top, for his feet to take its treads.
func near(on: Dictionary, at: Vector3) -> bool:
	if on.is_empty():
		return false
	var s := _along(on, at)
	var off := absf((at - (on["foot"] as Vector3)).dot(on["across"]))
	return s > -APPROACH and s < _flight(on) + LEAVE and off < float(on["width"]) / 2.0


## His feet start to be set on `on`'s treads, from where his ankles are (`feet`), walking along
## `heading`; the foot his walk has in the air at `frame` lifts at once.
func begin(on: Dictionary, feet: Array[Vector3], heading: Vector3, _facing: Vector3, at: Vector3,
		frame: float) -> void:
	stair = on
	sense = 1 if heading.dot(on["up"]) >= 0.0 else -1
	_choose_gait(at)
	for side in range(2):
		_holds[side] = feet[side]
		_froms[side] = feet[side]
		targets[side] = feet[side]
		_steps[side] = _index(_along(on, feet[side]))
		_swinging[side] = false
		_swing[side] = 1.0
	_was_frame = -1.0
	if frame >= 0.0:
		for side in range(2):
			if not _within(frame, _strikes()[side], _lifts()[side]):
				_lift(side, at, frame)
		_was_frame = frame


## The frame his walk should start from when he sets off standing on the stair along `heading`,
## so that the foot behind, on the lower tread going up or the higher going down, lifts first; -1
## when both stand on one step.
func start_frame(heading: Vector3) -> float:
	_first = -1
	if _steps[0] == _steps[1]:
		return -1.0
	var up := heading.dot(stair["up"]) >= 0.0
	_first = 0 if (_steps[0] < _steps[1]) == up else 1
	return float(_lifts()[_first]) + 0.01


## The clip his feet take the stair in now: his walk, or the climb up the flight.
func clip() -> String:
	return gait["clip"]


## The pace across the floor his feet walk `stair` at, up or down.
func pace() -> float:
	return float(stair["tread"]) * _cadence() / 60.0


## His clip's rate on `stair`, for its cadence.
func rate() -> float:
	return _cadence() / float(gait["cadence"])


## His steps a minute: a stair's, up or down, or running up the climb's own.
func _cadence() -> float:
	if sense < 0:
		return DOWN_CADENCE
	return float(CLIMB_GAIT["cadence"]) if hurry and gait == CLIMB_GAIT else UP_CADENCE


## His climb on the flight going up, from just before its first riser to its top; his walk
## elsewhere. Standing, the clip changes at once; walking, it changes as a foot lands, the new
## clip taken up at that foot's own landing (`entry`), so that both feet keep their step.
func _choose_gait(at: Vector3) -> void:
	var s := _along(stair, at)
	var wanted := CLIMB_GAIT if sense > 0 and s > CLIMB_FROM and s < _flight(stair) + CLIMB_TO \
		else WALK_GAIT
	if wanted == gait:
		_pending = {}
	elif _was_frame < 0.0:
		gait = wanted
		_pending = {}
		_first = -1
	else:
		_pending = wanted


## The foot `side` just landed: a clip waiting to take over does so from this landing, the
## other foot lifting at once if the new clip has it in the air by then.
func _take_up(side: int, at: Vector3) -> float:
	gait = _pending
	_pending = {}
	entry = float(_strikes()[side]) + 0.01
	var other := 1 - side
	if not _swinging[other] and not _within(entry, _strikes()[other], _lifts()[other]):
		_lift(other, at, entry)
	return entry


## The pace, kept in step with his feet: a little faster or slower so that his body passes over
## his standing foot halfway through its stance, at most a fifth either way; in the climb, whose
## footholds are chosen where his body will be as each foot lands, the stair's own pace.
func kept_pace(at: Vector3, frame: float) -> float:
	var base := pace()
	if not bool(gait["lifted"]):
		return base
	var standing := -1
	var through := -1.0
	for side in range(2):
		if not _swinging[side] and _within(frame, _strikes()[side], _lifts()[side]):
			var progress := _progress(frame, _strikes()[side], _lifts()[side])
			if progress > through:
				through = progress
				standing = side
	if standing < 0:
		return base
	var ideal := _along(stair, _holds[standing]) - sense * AHEAD + sense * 2.0 * AHEAD * through
	var error := (ideal - _along(stair, at)) * sense
	return base + clampf(error * SYNC, -SYNC_MOST * base, SYNC_MOST * base)


## How fully his pace is the stair's at `at`: as fully as his feet are on its steps, and on the
## way to its foot from APPROACH out to where his body meets the incline, so that a man running
## at it has slowed to his climbing pace by the first step.
func pace_weight(at: Vector3) -> float:
	var s := _along(stair, at)
	return maxf(influence, smoothstep(-APPROACH, _leaves_floor(), s) if sense > 0 else 0.0)


## Whether `at` is where his body rides the stair's hidden incline, its foot and its top
## included, so that `climb()` carries him.
func on_incline(at: Vector3) -> bool:
	var s := _along(stair, at)
	return s > _leaves_floor() - EASE and s < _flight(stair) + EASE


## How fast his body rises, or falls, walking at `velocity` this frame (`delta`) on the stair's
## hidden incline: along the way his round-bottomed body really rides it, level until it meets
## the incline's foot, a little above the incline along it, and over its top edge in an arc onto
## the landing, so that neither edge jolts him or stops him.
func climb(at: Vector3, velocity: Vector3, delta: float) -> float:
	var next := _along(stair, at) + Vector3(velocity.x, 0.0, velocity.z).dot(stair["up"]) * delta
	return ((stair["foot"] as Vector3).y + _riding(next) - at.y) / maxf(delta, 0.0001)


## How high his body's foot rides over the stair's foot at `s` along it: on the floor, then a
## body of BODY_RADIUS on the incline stands a little above it, then over its top edge round
## onto the landing; the change from the floor eased over EASE.
func _riding(s: float) -> float:
	var angle := atan(float(stair["rise"]) / float(stair["tread"]))
	var above := BODY_RADIUS * (1.0 / cos(angle) - 1.0)
	var line := (s + float(stair["tread"])) * tan(angle) + above
	var top := _top(int(stair["risers"]))
	var edge := _flight(stair)
	var over := edge - BODY_RADIUS * sin(angle)
	if s >= edge:
		return top
	if s >= over:
		return top + sqrt(BODY_RADIUS * BODY_RADIUS - (s - edge) * (s - edge)) - BODY_RADIUS
	return (line + sqrt(line * line + EASE * EASE)) / 2.0


## How far his collision body rides above the line his feet stand on at `at` (the floor, the
## nosings, the landing), as a round-bottomed body does on an incline and over its edges; his
## model is drawn that much lower, from his feet's line, not from his body's.
func riding_above(at: Vector3) -> float:
	if stair.is_empty():
		return 0.0
	var s := _along(stair, at)
	var feet := clampf((s + float(stair["tread"])) * float(stair["rise"]) / float(stair["tread"]),
		0.0, _top(int(stair["risers"])))
	return maxf(at.y - (stair["foot"] as Vector3).y - feet, 0.0) * influence


## Where along the stair his body leaves the floor for the incline.
func _leaves_floor() -> float:
	var angle := atan(float(stair["rise"]) / float(stair["tread"]))
	return -float(stair["tread"]) - BODY_RADIUS * (1.0 / cos(angle) - 1.0) / tan(angle)


## One physics frame. `at` is his body's place and `facing` his model's; `frame` is his walk
## clip's frame (0–31) while `walking` along `heading`, otherwise he stands, a foot in the air
## coming down where it was going. `animated` and `hips` are where his walk puts his ankles and
## his hips' joints, before his legs' IK (`ankle_watch.gd`), over his model's `ground`.
func step(at: Vector3, facing: Vector3, frame: float, walking: bool, heading: Vector3,
		animated: Array[Vector3], hips: Array[Vector3], ground: float, delta: float) -> void:
	var inside := near(stair, at)
	influence = move_toward(influence, 1.0 if inside else 0.0, BLEND_RATE * delta)
	if walking and heading.length_squared() > 0.01:
		var along := heading.dot(stair["up"])
		if absf(along) > 0.3:
			sense = 1 if along > 0.0 else -1
	_choose_gait(at)
	_turn_with(at, facing)
	for side in range(2):
		if walking:
			if _was_frame < 0.0:
				if not _swinging[side] and not _within(frame, _strikes()[side], _lifts()[side]) \
						and (_first < 0 or side == _first):
					_lift(side, at, frame)
			else:
				if _crossed(_was_frame, frame, _lifts()[side]):
					_lift(side, at, frame)
				if _crossed(_was_frame, frame, _strikes()[side]) and _swinging[side]:
					_land(side)
					if not _pending.is_empty():
						frame = _take_up(side, at)
			if _swinging[side]:
				_swing[side] = _progress(frame, _lifts()[side], _strikes()[side])
		elif _swinging[side]:
			_swing[side] = minf(_swing[side] + SETTLE_RATE * delta, 1.0)
			if _swing[side] >= 1.0:
				_land(side)
		falls[side] = _fall(side, frame, walking)
		var lifted := maxf(animated[side].y - ground - ANKLE_UP - STANCE_SLACK, 0.0) \
			if bool(gait["lifted"]) else _heel_up(side)
		targets[side] = (_arc(side) if _swinging[side] else _holds[side]) + Vector3.UP * lifted
	if walking:
		_first = -1
	_was_frame = frame if walking else -1.0
	_lower_hips(at, hips, delta)
	if not inside and influence <= 0.0:
		reset()


## As he turns, a foot standing on the level (the floor or the landing) turns with him round his
## body, as his walk's own feet do, so that turning round at the top leaves his left foot on his
## left; a foot on a tread stays where it stands.
func _turn_with(at: Vector3, facing: Vector3) -> void:
	var yaw := atan2(facing.x, facing.z)
	if not is_nan(_was_yaw):
		var turn := angle_difference(_was_yaw, yaw)
		for side in range(2):
			if not _swinging[side] and (_steps[side] == 0 or _steps[side] >= int(stair["risers"])):
				var off := _holds[side] - Vector3(at.x, _holds[side].y, at.z)
				_holds[side] = Vector3(at.x, _holds[side].y, at.z) + off.rotated(Vector3.UP, turn)
	_was_yaw = yaw


## The foot `side` lifts: where it will land, on the step nearest where his body will be by then
## and a little ahead of it, under its own hip, square across the flight however far round he has
## turned.
func _lift(side: int, at: Vector3, frame: float) -> void:
	var to_strike := _frames_until(frame, _strikes()[side]) / (FPS * rate())
	var wanted := _along(stair, at) + sense * (pace() * to_strike + AHEAD)
	var chosen := _foothold(wanted)
	var other := _steps[1 - side]
	if int(chosen.x) == other and other > 0 and other < int(stair["risers"]):
		chosen = Vector2(other + sense, _place(other + sense, wanted))
	_froms[side] = targets[side]
	_lift_falls[side] = falls[side]
	_steps[side] = int(chosen.x)
	var point := Vector3(at.x, 0.0, at.z) + _left((stair["up"] as Vector3) * sense) * SIDES[side]
	point += (stair["up"] as Vector3) * (chosen.y - _along(stair, point))
	point.y = (stair["foot"] as Vector3).y + _top(int(chosen.x)) + ANKLE_UP
	_holds[side] = point
	_swinging[side] = true
	_swing[side] = 0.0


func _land(side: int) -> void:
	_swinging[side] = false
	_swing[side] = 1.0


## The step a foot lands on nearest where it is `wanted` along the flight, and where on it.
func _foothold(wanted: float) -> Vector2:
	var chosen := 0
	var gap := INF
	for index in range(int(stair["risers"]) + 1):
		var off := absf(_place(index, wanted) - wanted)
		if off < gap:
			gap = off
			chosen = index
	return Vector2(chosen, _place(chosen, wanted))


## Where along the flight a foot stands on step `index` (0 the floor, the last the landing):
## going up with its toes clear of the riser ahead, its ankle at least a little onto the tread
## where a tread is shorter than his shoe, its heel then over the edge as a climber's is; going
## down with its heel clear of the riser behind; on the floor or the landing as near `wanted` as
## that allows.
func _place(index: int, wanted: float) -> float:
	var tread: float = stair["tread"]
	var flight := _flight(stair)
	if index == 0:
		return minf(wanted, -(TOE_REACH if sense > 0 else HEEL_BACK) - TOE_ROOM)
	if index >= int(stair["risers"]):
		return maxf(wanted, flight + (TOE_ROOM if sense > 0 else TOE_REACH - 2.0 * TOE_ROOM))
	if sense > 0:
		return maxf(index * tread - TOE_REACH - TOE_ROOM, (index - 1) * tread + ON_TREAD)
	return index * tread - HEEL_BACK - TOE_ROOM


## Where the foot `side` is on its swing: going up it rises first, its toes clear of the riser
## they stood against, and then goes on over the nosing; going down it goes out over the nosing first and then down; on the level it lifts a
## little as his walk's foot does.
func _arc(side: int) -> Vector3:
	var u := _swing[side]
	var from := _froms[side]
	var to := _holds[side]
	var rise := to.y - from.y
	var going: float
	var lifting: float
	var lift: float
	if rise > 0.02:
		going = smoothstep(0.3, 1.0, u)
		lifting = smoothstep(0.0, 0.55, u)
		lift = LIFT_UP
	elif rise < -0.02:
		going = smoothstep(0.0, 0.75, u)
		lifting = smoothstep(0.35, 1.0, u)
		lift = LIFT_DOWN
	else:
		going = smoothstep(0.0, 1.0, u)
		lifting = u
		lift = 0.0
	var point := Vector3(from.x, 0.0, from.z).lerp(Vector3(to.x, 0.0, to.z), going)
	point.y = lerpf(from.y, to.y, lifting) + lift * sin(PI * u)
	return point


## How far the ankle of the foot `side`, standing, rises as its heel comes up: as much as keeps
## the ball of the foot on its tread while the foot tips forward about the ankle.
func _heel_up(side: int) -> float:
	if _swinging[side] or falls[side] <= SOLE_FALL:
		return 0.0
	return ANKLE_UP / sin(SOLE_FALL) * (sin(falls[side]) - sin(SOLE_FALL))


## How far the line from his ankle to the ball of the foot `side` falls: level, as in his walk's
## flat stance, while he stands on it; his heel rising in the last part of its stance as his walk's
## does, the ball kept on the tread; from as it lifted to level again by the middle of its swing,
## so that it lands flat.
func _fall(side: int, frame: float, walking: bool) -> float:
	if _swinging[side]:
		return lerpf(_lift_falls[side], SOLE_FALL, smoothstep(0.0, 0.5, _swing[side]))
	if not walking or not _within(frame, _strikes()[side], _lifts()[side]):
		return SOLE_FALL
	return lerpf(SOLE_FALL, HEEL_UP_FALL, smoothstep(0.7, 1.0, _progress(frame,
		_strikes()[side], _lifts()[side])))


## His hips lowered, smoothly, to his standing foot's tread, or, as a foot goes down to a lower
## tread, down with it ahead of its landing, his knees a little more bent on the flight; and,
## quickly but never at a jump, by as much more as a standing leg could not reach its foot.
func _lower_hips(at: Vector3, hips: Array[Vector3], delta: float) -> void:
	var lowest := INF
	for side in range(2):
		var under := _holds[side].y
		if _swinging[side]:
			under = lerpf(_froms[side].y, _holds[side].y, smoothstep(0.0, 0.8, _swing[side]))
			under = maxf(under, minf(_froms[side].y, _holds[side].y))
		lowest = minf(lowest, under - ANKLE_UP)
	var tread: float = stair["tread"]
	var s := _along(stair, at)
	var on_flight := clampf((s + tread) / tread, 0.0, 1.0) \
		* clampf((_flight(stair) + tread - s) / tread, 0.0, 1.0)
	var wanted := (clampf(at.y - riding_above(at) - lowest, 0.0, DROP_MOST)
		+ STAIR_BEND * on_flight) * influence
	_drop_speed += (DROP_RATE * DROP_RATE * (wanted - _settled) - 2.0 * DROP_RATE
		* _drop_speed) * delta
	_settled += _drop_speed * delta
	var short := -INF
	for side in range(2):
		if _swinging[side]:
			continue
		var across := Vector2(hips[side].x - targets[side].x, hips[side].z - targets[side].z)
		var most := sqrt(maxf(REACH * REACH - across.length_squared(), 0.0))
		short = maxf(short, hips[side].y - targets[side].y - most)
	if short == -INF:
		short = -_reach_drop
	_reach_drop = maxf(_reach_drop + clampf(short, -REACH_RATE * delta, REACH_RATE * delta), 0.0)
	drop = _settled + _reach_drop * influence


func _left(facing: Vector3) -> Vector3:
	var flat := Vector3(facing.x, 0.0, facing.z)
	return Vector3.UP.cross(flat.normalized()) if flat.length_squared() > 0.0001 else Vector3.LEFT


func _along(on: Dictionary, at: Vector3) -> float:
	var from := at - (on["foot"] as Vector3)
	return Vector3(from.x, 0.0, from.z).dot(on["up"])


func _flight(on: Dictionary) -> float:
	return float(on["tread"]) * (int(on["risers"]) - 1)


func _index(s: float) -> int:
	if s < 0.0:
		return 0
	if s < _flight(stair):
		return int(floorf(s / float(stair["tread"]))) + 1
	return int(stair["risers"])


func _top(index: int) -> float:
	return float(stair["rise"]) * index


func _strikes() -> Array:
	return gait["strikes"]


func _lifts() -> Array:
	return gait["lifts"]


## Whether `frame` is between `from` and `to` on the clip's loop.
func _within(frame: float, from: float, to: float) -> bool:
	return _frames_until(from, frame) <= _frames_until(from, to)


## How far `frame` is from `from` toward `to` on the clip's loop, 0 to 1.
func _progress(frame: float, from: float, to: float) -> float:
	var span := _frames_until(from, to)
	return clampf(_frames_until(from, frame) / span, 0.0, 1.0) if span > 0.0 else 1.0


func _frames_until(from: float, to: float) -> float:
	return fposmod(to - from, float(gait["cycle"]))


## Whether the clip passed `mark` between `was` and `now`.
func _crossed(was: float, now: float, mark: float) -> bool:
	var moved := _frames_until(was, now)
	return moved > 0.0 and moved < float(gait["cycle"]) / 2.0 \
		and _frames_until(was, mark) <= moved \
		and _frames_until(was, mark) > 0.0
