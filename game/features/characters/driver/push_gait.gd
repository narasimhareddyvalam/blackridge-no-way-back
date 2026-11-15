extends RefCounted
## Ethan's walk behind the depot's pallet jack (step 2e, the author's choices #239-#240; finished
## in step 2f, #243-#244), from Mixamo's Pushing and Push Stop and his own walk, walk back and
## idle, each played at the pace the load really goes, so that his feet keep their grip on the
## floor. The load gets going and slows at LOAD_ACCEL, as 520 kg on a hand jack does. He leans in
## with Pushing only while the load breaks away; once it rolls he walks nearly upright behind it
## at DOCK_PACE, and in the van's hold, under its low roof, he pushes stooped at Pushing's own
## pace. Let go of as he walks, he plants his feet on his walk's own frames, the load rolling on
## with his last step, and stands holding the handle; let go of while he still leans, the push
## ends in Push Stop and he stands and lets go. Against something, he finishes his step and steps
## up to the handle. He pulls by walking back upright, and in the hold by hauling it in Mixamo's
## Pull Heavy Object, low under the roof (#252-#257). `grip()` tells where his hands are in
## each, for the handle to tilt to. The frames are the clips' own, at 30 a second, first frame 1.

enum Gait { STAND, PUSH, STOP, SETTLE, STEP_IN, PULL }

const FPS := 30.0
const PUSH_SPEED := 0.377
const WALK_BACK_SPEED := 0.529
const HEAVE_SPEED := 0.243
const WALK_SPEED := 1.705
const DOCK_PACE := 0.9
const LEAN_UNTIL := 0.6
const LEAN_RATE_MOST := 1.5
const RUN_OUT_DONE := 0.2
const VAN_RATE := 1.0
const PULL_RATE := 1.0
const STEP_RATE := 0.5
const LOAD_ACCEL := 0.45
const ROLL_FROM := 0.2
const STOP_RATES := Vector2(0.75, 1.5)
const BLEND := 0.2
const WALK_BLEND := 0.5
const STAND_BLEND := 0.4
const STEP_CLOSE := 0.03
const CLOSE_IN_VAN := 0.2
const HANDS_CLOSE := 0.08
const REACH_FOR := 0.3
const EASE_FRAMES := 8.0
const EASE_LEAST := 0.4
const SETTLE_LEAST := 0.15
const STOP_EVERY := 6.0
const STOP_TRAVEL: Array[float] = [0.0, 0.076, 0.157, 0.253, 0.357, 0.458, 0.524, 0.622, 0.708,
	0.786, 0.815, 0.779, 0.754, 0.756]
const STOP_PLANTED := 61.0
const LET_GO := Vector2(56.0, 62.0)
const STOP_FROM: Array[Vector2] = [Vector2(1, 1), Vector2(12, 13), Vector2(20, 14),
	Vector2(27, 16), Vector2(33, 19), Vector2(36, 21), Vector2(40, 26), Vector2(44, 31),
	Vector2(48, 35), Vector2(52, 37), Vector2(55, 38), Vector2(56, 42), Vector2(61, 43),
	Vector2(66, 44), Vector2(76, 47), Vector2(76.01, 1), Vector2(81, 1)]
const PUSH_PLANTED: Array[Vector2] = [Vector2(11, 36), Vector2(55, 72)]
const WALK_PLANTED: Array[Vector2] = [Vector2(10, 11.5), Vector2(25.5, 27)]
const WALK_BACK_PLANTED: Array[Vector2] = [Vector2(13, 15), Vector2(35, 38)]
const HEAVE_PLANTED: Array[Vector2] = [Vector2(1, 6), Vector2(22, 24)]
const GRIP_LEANING := Vector2(0.7, 1.05)
const GRIP_STOOPED := Vector2(0.47, 0.96)
const GRIP_WALKING := Vector2(0.36, 1.02)
const GRIP_PULLING := Vector2(0.3, 1.07)
const GRIP_HEAVING := Vector2(0.51, 1.02)
const CAUGHT_UP := 0.2
const GRIP_STANDING := Vector2(0.36, 1.02)

var gait := Gait.STAND
var hands := 1.0
var _player: AnimationPlayer
var _clip := "Push"
var _pace := 0.0
var _way := 1.0
var _stop_time := 0.0
var _stop_rate := 1.0
var _against := false
var _closed := 0.0
var _stuck := 0.0
var _inside := false
var _slack := 0.0
var _rolling := false


func _init(player: AnimationPlayer) -> void:
	_player = player


## Taking the jack: he stands behind its handle with his hands on it.
func take() -> void:
	gait = Gait.STAND
	hands = 1.0
	_pace = 0.0
	_stuck = 0.0
	_against = false
	_play("Idle", BLEND, 1.0)


## One physics frame: `drive` is W less S; `lead`, how much faster than his feet the jack may go
## while it runs out to arm's length (0 to 1); `slack`, how much nearer its handle he may still
## step; `inside`, whether he is under the hold's low roof. Returns how far his feet carry him
## along his facing this frame and how far the jack goes with him, back being negative.
func step(drive: float, lead: float, slack: float, inside: bool, delta: float) -> Vector2:
	_inside = inside
	_slack = slack
	if signf(drive) != _stuck:
		_stuck = 0.0
	match gait:
		Gait.PUSH:
			return _push(drive, lead, delta)
		Gait.STOP:
			return _stop(delta)
		Gait.SETTLE:
			return _settle(drive, delta)
		Gait.STEP_IN:
			return _step_in(delta)
		Gait.PULL:
			return _pull(drive, delta, lead)
	return _stand(drive)


## The jack could not go where his feet were taking it: the load is against something, so it
## stops there and he finishes his steps up to the handle, his arms bending, close enough to stand
## on the lift's deck with it; in the hold, at most CLOSE_IN_VAN nearer it. Pushing the same way
## then does nothing until W or S is let go.
func blocked() -> void:
	_stuck = signf(_pace) if not is_zero_approx(_pace) else 1.0
	match gait:
		Gait.STEP_IN:
			return
		Gait.PUSH:
			_end_push(true)
		Gait.PULL:
			_way = -1.0
			gait = Gait.SETTLE
			_stop_against()
		Gait.STOP, Gait.SETTLE:
			_stop_against()


func _stop_against() -> void:
	if not _against:
		_against = true
		_closed = 0.0


func _stand(drive: float) -> Vector2:
	if drive > 0.0 and is_zero_approx(_stuck):
		gait = Gait.PUSH
		_clip = "Push"
		_pace = 0.0
		_rolling = false
		_against = false
		_play("Push", BLEND, 0.0)
		hands = 1.0
	elif drive < 0.0 and is_zero_approx(_stuck):
		_against = false
		_begin_pull()
	return Vector2.ZERO


## Leaning in while the load breaks away and the jack runs out ahead of his feet, by `lead`, to
## his arm's length, its handle tilting down; then walking behind it once it rolls; stooped in
## the hold.
func _push(drive: float, lead: float, delta: float) -> Vector2:
	if drive <= 0.0:
		_end_push(false)
		return Vector2.ZERO
	var target := drive * (VAN_RATE * PUSH_SPEED if _inside else DOCK_PACE)
	_pace = move_toward(_pace, target, LOAD_ACCEL * delta)
	var feet := _pace / (1.0 + lead)
	_rolling = not _inside and (_rolling or (_pace >= LEAN_UNTIL * DOCK_PACE
		and lead <= RUN_OUT_DONE))
	if not _rolling:
		feet = minf(feet, LEAN_RATE_MOST * PUSH_SPEED)
	_clip = "Walk" if _rolling else "Push"
	var blend := WALK_BLEND if str(_player.current_animation) != _clip else BLEND
	_play(_clip, blend, feet / (WALK_SPEED if _rolling else PUSH_SPEED))
	hands = 1.0
	return Vector2(feet, _pace) * delta


## The push let go of, or its load against something. In the hold he plants his feet in
## Pushing's own stride. Outside, Push Stop picks up from the step he is on, at the pace his
## feet had; if the load cannot go on, or barely moved, it picks up late enough that his last
## steps take him no nearer the handle than he can go, or only as far as the load would roll.
func _end_push(against: bool) -> void:
	_against = false
	if against:
		_stop_against()
	if _inside or _clip == "Walk":
		_way = 1.0
		gait = Gait.SETTLE
		return
	var feet := _player.speed_scale * PUSH_SPEED
	var frame := _stop_from(_frame())
	if against:
		frame = maxf(frame, _frame_for(_travel((STOP_PLANTED - 1.0) / FPS) - _slack))
	elif _pace < ROLL_FROM:
		var rolls := _pace * _pace / (2.0 * LOAD_ACCEL)
		frame = maxf(frame, _frame_for(_travel((STOP_PLANTED - 1.0) / FPS) - rolls))
	_stop_time = (frame - 1.0) / FPS
	_stop_rate = clampf(feet / maxf(_stop_pace(frame), 0.05), STOP_RATES.x, STOP_RATES.y)
	gait = Gait.STOP
	_player.play("PushStop", BLEND)
	_player.seek(_stop_time, true)
	_player.speed_scale = _stop_rate


func _stop(delta: float) -> Vector2:
	var length := _player.get_animation("PushStop").length
	var before := _travel(_stop_time)
	_stop_time = minf(_stop_time + _stop_rate * delta, length)
	var feet := _travel(_stop_time) - before
	var frame := 1.0 + _stop_time * FPS
	hands = 1.0 - clampf((frame - LET_GO.x) / (LET_GO.y - LET_GO.x), 0.0, 1.0)
	var carry := feet if hands > 0.5 and not _against else 0.0
	if _stop_time >= length:
		gait = Gait.STAND
		hands = 0.0
		_pace = 0.0
		_play("Idle", STAND_BLEND, 1.0)
	return Vector2(feet, carry)


## Pushing, his walk or his walk back played on the way it went, easing, to the next frame on
## which both his feet are down; there it is held in the hold, or outside he stands holding the
## handle, first stepping up to it if the load stopped against something.
func _settle(drive: float, delta: float) -> Vector2:
	if drive * _way > 0.0 and is_zero_approx(_stuck):
		_against = false
		if _way > 0.0:
			gait = Gait.PUSH
			return _push(drive, 0.0, delta)
		gait = Gait.PULL
		return _pull(drive, delta)
	var planted: Array[Vector2] = {"Push": PUSH_PLANTED, "Walk": WALK_PLANTED,
		"PullBack": HEAVE_PLANTED}.get(_clip, WALK_BACK_PLANTED)
	var frames := _frames_to(planted, _frame(), _way if _clip == "Push" else 1.0)
	if is_zero_approx(frames):
		_hold()
		return Vector2.ZERO
	var clip_speed: float = {"Push": PUSH_SPEED, "Walk": WALK_SPEED,
		"PullBack": HEAVE_SPEED}.get(_clip, WALK_BACK_SPEED)
	var speed := maxf(absf(_pace), SETTLE_LEAST) * clampf(frames / EASE_FRAMES, EASE_LEAST, 1.0)
	var feet := speed * _way * delta
	if _against:
		if _closed + absf(feet) > minf(_slack + absf(feet), CLOSE_IN_VAN):
			_hold()
			return Vector2.ZERO
		_closed += absf(feet)
	var rate := speed / clip_speed
	_player.speed_scale = rate * _way if _clip == "Push" else rate
	return Vector2(feet, 0.0 if _against else feet)


func _hold() -> void:
	gait = Gait.STAND
	_pace = 0.0
	hands = 1.0
	if _inside and (_clip == "Push" or _clip == "PullBack"):
		_player.speed_scale = 0.0
		return
	if _against and _slack > STEP_CLOSE:
		gait = Gait.STEP_IN
		_play("Walk", STAND_BLEND, STEP_RATE)
		return
	_play("Idle", STAND_BLEND, 1.0)


## Up to the handle from where he stood back to pump the jack up (#286), as after the load
## stopped against something.
func step_in() -> void:
	if gait == Gait.STAND and _slack > STEP_CLOSE:
		gait = Gait.STEP_IN
		_play("Walk", STAND_BLEND, STEP_RATE)


## Up to the handle after the load stopped against something, his walk at half its pace, so he
## stands close to it, as on the lift's deck with it.
func _step_in(delta: float) -> Vector2:
	if _slack <= STEP_CLOSE:
		gait = Gait.STAND
		_play("Idle", STAND_BLEND, 1.0)
		return Vector2.ZERO
	return Vector2(minf(STEP_RATE * WALK_SPEED * delta, _slack), 0.0)


func _begin_pull() -> void:
	gait = Gait.PULL
	_clip = "PullBack" if _inside else "WalkBack"
	_pace = 0.0
	hands = 1.0


## Walking back upright, close to the handle, or in the hold hauling it in the captured heavy pull;
## out of the hold he stays stooped until the jack has closed in to him (`lead`, negative while
## it is farther than his arm's length), then walks back. The jack follows half `lead` slower
## or faster than his feet until it is at his arm's length.
func _pull(drive: float, delta: float, lead: float = 0.0) -> Vector2:
	if drive >= 0.0:
		_way = -1.0
		gait = Gait.SETTLE
		return _settle(drive, delta)
	var lag := lead * 0.5
	_clip = "PullBack" if _inside or (_clip == "PullBack" and lead < -CAUGHT_UP) else "WalkBack"
	var heaving := _clip == "PullBack"
	var clip_speed := HEAVE_SPEED if heaving else WALK_BACK_SPEED
	var rate := VAN_RATE if heaving else PULL_RATE
	_pace = move_toward(_pace, drive * rate * clip_speed, LOAD_ACCEL * delta)
	var blend := WALK_BLEND if str(_player.current_animation) != _clip else BLEND
	_play(_clip, blend, -_pace / clip_speed)
	hands = 1.0
	return Vector2(_pace, _pace * (1.0 - lag)) * delta


## Where his hands are for the clip he is in: how far ahead of his feet's middle and how high,
## for the handle to tilt to.
func grip() -> Vector2:
	match str(_player.current_animation):
		"Push", "PushStop":
			return GRIP_STOOPED if _inside else GRIP_LEANING
		"Walk":
			return GRIP_WALKING
		"WalkBack":
			return GRIP_PULLING
		"PullBack":
			return GRIP_HEAVING
	return GRIP_STANDING


func _play(clip: String, blend: float, speed: float) -> void:
	_player.speed_scale = speed
	if str(_player.current_animation) != clip:
		_player.play(clip, blend)


func _frame() -> float:
	return 1.0 + _player.current_animation_position * FPS


## Push Stop's frame that picks up from Pushing's frame `push`: the one whose feet match best.
func _stop_from(push: float) -> float:
	for index in range(1, STOP_FROM.size()):
		var a := STOP_FROM[index - 1]
		var b := STOP_FROM[index]
		if push <= b.x:
			return lerpf(a.y, b.y, clampf((push - a.x) / maxf(b.x - a.x, 0.0001), 0.0, 1.0))
	return STOP_FROM[-1].y


## How far Push Stop has carried him from its first frame at `time`, between its knots.
func _travel(time: float) -> float:
	var at := clampf(time * FPS / STOP_EVERY, 0.0, STOP_TRAVEL.size() - 1.0)
	var index := mini(int(at), STOP_TRAVEL.size() - 2)
	return lerpf(STOP_TRAVEL[index], STOP_TRAVEL[index + 1], at - index)


## The first frame of Push Stop at which it has carried him `travel`, up to where his last step
## is planted.
func _frame_for(travel: float) -> float:
	for index in range(1, STOP_TRAVEL.size()):
		if travel <= STOP_TRAVEL[index]:
			var a := STOP_TRAVEL[index - 1]
			var part := clampf((travel - a) / maxf(STOP_TRAVEL[index] - a, 0.0001), 0.0, 1.0)
			return minf(1.0 + (index - 1 + part) * STOP_EVERY, STOP_PLANTED)
	return STOP_PLANTED


## How fast Push Stop's feet carry him at `frame`, played at its own pace.
func _stop_pace(frame: float) -> float:
	var index := clampi(int((frame - 1.0) / STOP_EVERY), 0, STOP_TRAVEL.size() - 2)
	return (STOP_TRAVEL[index + 1] - STOP_TRAVEL[index]) / STOP_EVERY * FPS


## How many frames, played the way `way` goes, until `frame` is in one of the `planted` spans.
func _frames_to(planted: Array[Vector2], frame: float, way: float) -> float:
	var length := _player.get_animation(_clip).length * FPS
	var nearest := INF
	for span in planted:
		if frame >= span.x and frame <= span.y:
			return 0.0
		var gap := (span.x - frame) if way > 0.0 else (frame - span.y)
		nearest = minf(nearest, fposmod(gap, length))
	return nearest
