extends SceneTree
## Part A of the author's #245 and #246 (docs/PHASE_BRIEF.md, revision "step 2f, part 1
## continued: smooth on foot"): Ethan on foot without a jolt. In the running game on Mission 2's
## start save, Ethan gets out of the van by E and is set at the foot of the dock stair (rule H8's,
## inside the shed's side door); from there he walks by the real key W, his camera turned by this
## script as the mouse turns it. Read from his skeleton as it is posed: up and down the stair at
## a stair's cadence (Di Giulio et al. 2019: about 76 steps a minute up, 117 down), one tread a
## step, each planted foot on its tread and no foot through a step, his body, hips and camera
## never jumping; stopping halfway up and going on, his feet still one tread a step; up a slope, a
## fixture, without a step taken; onto a kerb, a fixture, without his camera or hips jumping; his
## camera easing back out once a wall, a fixture, stops squeezing it. A headless run draws
## nothing, so the look is not checked here.

const START_SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const DOCKED := Vector3(-47.75, 0.1, 23.16)
const FOOT_Z := 15.17
const STAIR_X := Vector2(-44.7, -43.7)
const TREAD := 0.25
const RISERS := 6
const RISE := 1.3 / 6.0
const LANDING := 1.0
const BELOW := Vector3(-44.2, 0.0, 17.4)
const ABOVE := Vector3(-44.2, 0.0, 13.45)
const UP_PACE := TREAD * 76.0 / 60.0
const DOWN_PACE := TREAD * 117.0 / 60.0
const RUN_UP_CADENCE := 200.0
const CLIMBING := 0.9
const NEAR_STAIR := 0.9
## Running up, the captured climb's own hips rise 2.0 m/s at their quickest as he drives off
## each step at its full pace, 0.034 m a frame with the stair's own rise (#257).
const RUN_HIPS := 0.035
const PACE_SPREAD := 0.15
const UP_CADENCE := 76.0
const DOWN_CADENCE := 117.0
const CADENCE_SPREAD := 10.0
const JUMP := 0.02
const UNDER_HIP := 0.03
const FEET_APART := 0.15
const ANKLE_UP := 0.116
const ON_TREAD := 0.03
const CLEAR := 0.01
const ANKLE_CLEAR := 0.04
const STILL := 0.05
const STILL_TICKS := 4
const KERB := 0.15
const KERB_AT := Vector3(-41.8, KERB / 2.0, 10.0)
const KERB_SIZE := Vector3(2.0, KERB, 2.0)
const KERB_FROM := Vector3(-41.8, 0.0, 13.5)
const KERB_TO := Vector3(-41.8, 0.0, 9.6)
const KERB_RISE_TICK := 0.025
const PAUSE_AT := 0.6
const PAUSE := 1.0
const SLOPE_RISE := 0.6
const SLOPE_RUN := 1.65
const SLOPE_FOOT_Z := 4.0
const SLOPE_FROM := Vector3(-41.8, 0.0, 6.2)
const SLOPE_TO := Vector3(-41.8, 0.0, 1.0)
const CAMERA_AT := Vector3(-41.8, 0.0, 5.0)
const WALL_BEHIND := 1.0
const SQUEEZED := 1.0
const EASE_TICK := 0.12
const OUT_AGAIN := 3.2
const MID_FLIGHT := Vector3(-44.2, 0.0, 14.75)
const ACROSS_TO := Vector3(-42.5, 0.0, 14.75)
const ALONG_LANDING := Vector3(-45.6, 0.0, 13.4)
const SIDE_APART := 0.05
const SHINS_APART := 0.09
const UNDER_HIM := 0.5
const SETTLING := 0.3
## On an ordinary stair (risers 0.17-0.18 m) knees bend to about 80-90° (inside angle) as a foot
## swings; this dock stair's 0.217 m risers bend them further going down, the trailing foot clearing
## its own nosing before it drops (70° measured, #287); going up, the captured climb's own knee
## reaches 63°, which the stair must not bend further.
const KNEE_DOWN_LEAST := 68.0
const KNEE_UP_LEAST := 58.0
const BONES := ["mixamorig_Hips", "mixamorig_LeftFoot", "mixamorig_RightFoot",
	"mixamorig_LeftToeBase", "mixamorig_RightToeBase", "mixamorig_LeftToe_End",
	"mixamorig_RightToe_End", "mixamorig_LeftUpLeg", "mixamorig_RightUpLeg",
	"mixamorig_LeftLeg", "mixamorig_RightLeg"]

var _anim: AnimationPlayer
var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _app: Node3D
var _hud: CanvasLayer
var _van: CharacterBody3D
var _driver: CharacterBody3D
var _skeleton: Skeleton3D
var _camera: Camera3D
var _bone_ids: Array[int] = []
var _pose: Array[Vector3] = []
var _samples: Array[Dictionary] = []
var _recording := false


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(240.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-stair-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_store(START_SAVE)
	await _build()
	await _key(KEY_ENTER)
	await _seconds(1.0)
	_van.call("recover", Transform3D(Basis(Vector3.UP, PI), DOCKED))
	await _seconds(1.0)
	await _key(KEY_E)
	await _until(_on_foot, 8.0)
	_skeleton = _driver.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	_camera = _driver.call("get_camera") as Camera3D
	_anim = _driver.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	for bone: String in BONES:
		_bone_ids.append(_skeleton.find_bone(bone))
	_pose.resize(BONES.size())
	_skeleton.skeleton_updated.connect(_on_pose)
	_check(_on_foot() and not _bone_ids.has(-1),
		"Setup: Ethan out of the van on foot, his hips', ankles' and toes' bones found")
	await _check_stair()
	await _check_across()
	await _check_run_up()
	await _check_pause()
	await _check_slope()
	await _check_kerb()
	await _check_camera()
	_finish()


func _check_stair() -> void:
	await _place(BELOW, Vector3.FORWARD)
	var up := await _walk_recorded(ABOVE, 14.0)
	await _seconds(0.6)
	_driver.call("look_toward", Vector3.BACK)
	await _seconds(0.3)
	var down := await _walk_recorded(BELOW, 14.0)
	for leg: Array in [["up", up, UP_PACE, UP_CADENCE, 1], ["down", down, DOWN_PACE,
			DOWN_CADENCE, -1]]:
		_judge_flight(leg[0], leg[1], leg[2], leg[3], leg[4])
	_judge_knees("up", up, KNEE_UP_LEAST)
	_judge_knees("down", down, KNEE_DOWN_LEAST)


## Walking across the flight, and from its top along the landing toward the dock (#287): his
## feet stay his own, the left on his left, never crossing, his shins apart and each foot under
## its own hip; walking across, he does not climb (S14, S15).
func _check_across() -> void:
	await _place(BELOW, Vector3.FORWARD)
	await _walk_recorded(MID_FLIGHT, 8.0)
	var across := await _walk_recorded(ACROSS_TO, 1.6)
	_judge_own_feet("S14 walking across the flight", across, true)
	await _place(BELOW, Vector3.FORWARD)
	await _walk_recorded(ABOVE, 14.0)
	var along := await _walk_recorded(ALONG_LANDING, 4.0)
	_judge_own_feet("S15 from the stair's top along the landing", along, false)


func _judge_own_feet(way: String, samples: Array[Dictionary], across: bool) -> void:
	var apart := INF
	var shins := INF
	var away := 0.0
	var climbing := 0
	for sample in samples:
		if float(sample["time"]) < SETTLING:
			continue
		var feet: Array = sample["feet"]
		var left: Vector3 = sample["left"]
		apart = minf(apart, ((feet[0][0] as Vector3) - (feet[1][0] as Vector3)).dot(left))
		var knees: Array = sample["knees"]
		var near := Geometry3D.get_closest_points_between_segments(knees[0], feet[0][0],
			knees[1], feet[1][0])
		shins = minf(shins, near[0].distance_to(near[1]))
		for side in range(2):
			away = maxf(away, _flat((feet[side][0] as Vector3) - (sample["joints"][side]
				as Vector3)).length())
		if across and str(sample["clip"]) == "StairsUp":
			climbing += 1
	_check(not samples.is_empty() and apart >= SIDE_APART and shins >= SHINS_APART
		and away <= UNDER_HIM and climbing == 0,
		("%s his feet stay his own: the left at least %.3f m to his left of the right (never "
		+ "crossing), his shins at least %.3f m apart, each ankle at most %.2f m from its own "
		+ "hip; %d frames in the climb walking across (%d frames)") % [way, apart, shins, away,
		climbing, samples.size()])


## His knees on the stair bend as a stair bends them, never folded deeper (S16): the inside angle
## at each knee, between its hip and its ankle, on the flight.
func _judge_knees(way: String, samples: Array[Dictionary], least: float) -> void:
	var sharpest := 180.0
	var counted := 0
	for sample in samples:
		var s := FOOT_Z - (sample["body"] as Vector3).z
		if s < 0.0 or s > RISERS * TREAD:
			continue
		counted += 1
		for side in range(2):
			var knee: Vector3 = sample["knees"][side]
			var hip: Vector3 = sample["joints"][side]
			var ankle: Vector3 = sample["feet"][side][0]
			sharpest = minf(sharpest, rad_to_deg((hip - knee).angle_to(ankle - knee)))
	_check(counted > 0 and sharpest >= least, ("S16 %s the flight his knees bend at most to %.0f° "
		+ "(at least %.0f°, %d frames)") % [way, sharpest, least, counted])


## Up the stair holding the run key: the climb at its own captured pace (#254).
func _check_run_up() -> void:
	await _place(BELOW, Vector3.FORWARD)
	Input.action_press("sprint")
	var up := await _walk_recorded(ABOVE, 14.0)
	Input.action_release("sprint")
	_judge_flight("running up", up, TREAD * RUN_UP_CADENCE / 60.0, RUN_UP_CADENCE, 1)
	_judge_knees("running up", up, KNEE_UP_LEAST)


func _judge_flight(way: String, samples: Array[Dictionary], pace: float, cadence: float,
		sense: int) -> void:
	if sense > 0:
		var on_flight := 0
		var climbing := 0
		for sample: Dictionary in samples:
			var s := FOOT_Z - (sample["body"] as Vector3).z
			if s > TREAD and s < TREAD * (RISERS - 2):
				on_flight += 1
				climbing += 1 if sample["clip"] == "StairsUp" else 0
		var share := float(climbing) / maxf(on_flight, 1.0)
		_check(on_flight > 0 and share >= CLIMBING,
			("S12 %s: on the flight he climbs as a man climbs a stair, in the captured climb "
			+ "(StairsUp in %.0f%% of its frames, at least %.0f%%)") % [way, share * 100.0,
			CLIMBING * 100.0])
	var top: float = samples[-1]["body"].y if not samples.is_empty() else -INF
	var reached := absf(top - (RISE * RISERS if sense > 0 else 0.0)) < 0.05
	var paces: Array[float] = []
	var jumps := {"body": 0.0, "camera": 0.0, "hips": 0.0}
	for index in range(1, samples.size()):
		var now: Dictionary = samples[index]
		var was: Dictionary = samples[index - 1]
		for part: String in jumps:
			jumps[part] = maxf(jumps[part], absf((now[part] as Vector3).y
				- (was[part] as Vector3).y))
		var s := FOOT_Z - (now["body"] as Vector3).z
		if s > 0.05 and s < TREAD * (RISERS - 1) - 0.05:
			paces.append(_flat(now["body"] - was["body"]).length() * 60.0)
	paces.sort()
	var slowest: float = paces[0] if not paces.is_empty() else 0.0
	var fastest: float = paces[-1] if not paces.is_empty() else INF
	var middle: float = paces[paces.size() / 2] if not paces.is_empty() else 0.0
	_check(reached and absf(middle - pace) <= pace * PACE_SPREAD and slowest >= pace * 0.5
		and fastest <= pace * 1.5,
		("S1 %s: Ethan walks the stair at a stair's pace, %.3f m/s across the floor (against "
		+ "%.3f), never stalling (%.3f m/s at the slowest, %.3f at the fastest), and gets to "
		+ "the %s (%s, %.2f m up)") % [way, middle, pace, slowest, fastest,
		"landing" if sense > 0 else "lane", reached, top])
	var hips_most := RUN_HIPS if cadence > UP_CADENCE * 2.0 else JUMP
	_check(jumps["body"] <= JUMP and jumps["camera"] <= JUMP and jumps["hips"] <= hips_most,
		("S2 %s: nothing jumps: in any one frame his body rises or drops at most %.3f m and his "
		+ "camera %.3f (at most %.2f), his hips %.3f (at most %.3f, %s)") % [way,
		jumps["body"], jumps["camera"], JUMP, jumps["hips"], hips_most,
		"the captured running climb's own" if hips_most > JUMP else "a walk's"])
	var plants := _plants(samples)
	var on_tread := 0.0
	var toes_in := -INF
	var steps: Array[int] = []
	var feet: Array[int] = []
	var stair_plants: Array[float] = []
	for plant: Dictionary in plants:
		var ankle: Vector3 = plant["ankle"]
		var under := _profile(ankle)
		on_tread = maxf(on_tread, absf(ankle.y - ANKLE_UP - under))
		for point: Vector3 in [plant["ball"], plant["tip"]]:
			toes_in = maxf(toes_in, _profile(point) - point.y)
		var index := _step_index(ankle)
		steps.append(index)
		feet.append(plant["foot"])
		if index > 0 and index < RISERS:
			stair_plants.append(plant["time"])
	_check(plants.size() >= RISERS and on_tread <= ON_TREAD and toes_in <= CLEAR,
		("S3 %s: each planted foot stands on its step: its sole at most %.3f m off the step "
		+ "under it (at most %.2f), its toes at most %.3f m into a step (at most %.2f), over %d "
		+ "plants") % [way, on_tread, ON_TREAD, toes_in, CLEAR, plants.size()])
	var regular := steps.size() >= RISERS
	var treads: Array[int] = []
	var treads_feet: Array[int] = []
	for index in range(steps.size()):
		if steps[index] > 0 and steps[index] < RISERS:
			treads.append(steps[index])
			treads_feet.append(feet[index])
	var wanted: Array[int] = []
	for tread in range(1, RISERS):
		wanted.append(tread if sense > 0 else RISERS - tread)
	regular = regular and treads == wanted
	for index in range(1, treads_feet.size()):
		regular = regular and treads_feet[index] != treads_feet[index - 1]
	_check(regular,
		("S4 %s: one tread a step, his feet taking turns: the steps he plants on %s (wanted "
		+ "%s, the floor 0 and the landing %d), by foot %s") % [way, str(steps), str(wanted),
		RISERS, str(feet)])
	var through := _through(samples)
	_check(through <= CLEAR,
		("S5 %s: no foot goes through a step as it swings: his ankles, the balls of his feet and "
		+ "his toes at most %.3f m into one (at most %.2f)") % [way, through, CLEAR])
	var per_minute := 0.0
	if stair_plants.size() >= 2:
		per_minute = 60.0 * (stair_plants.size() - 1) / (stair_plants[-1] - stair_plants[0])
	_check(absf(per_minute - cadence) <= CADENCE_SPREAD,
		("S6 %s: his cadence on the stair is a stair's, %.0f steps a minute (against %.0f ± "
		+ "%.0f)") % [way, per_minute, cadence, CADENCE_SPREAD])
	var off_hip := 0.0
	var narrowest := INF
	for plant: Dictionary in plants:
		if _step_index(plant["ankle"]) == 0 or _step_index(plant["ankle"]) == RISERS:
			continue
		var left: Vector3 = plant["left"]
		var ankle: Vector3 = plant["ankle"]
		off_hip = maxf(off_hip, absf((ankle - (plant["hip"] as Vector3)).dot(left)))
		var apart := (ankle - (plant["other"] as Vector3)).dot(left)
		narrowest = minf(narrowest, apart if int(plant["foot"]) == 0 else -apart)
	_check(off_hip <= UNDER_HIP and narrowest >= FEET_APART,
		("S11 %s: his legs never cross: each planted foot under its own hip, at most %.3f m to "
		+ "one side of it (at most %.2f), his left foot always to the left of his right, at "
		+ "least %.3f m apart (at least %.2f)") % [way, off_hip, UNDER_HIP, narrowest,
		FEET_APART])


func _check_pause() -> void:
	await _place(BELOW, Vector3.FORWARD)
	var samples: Array[Dictionary] = []
	var time := 0.0
	var paused := false
	var resumed := INF
	Input.action_press("accelerate")
	while _flat(ABOVE - _driver.global_position).length() > 0.3 and time < 18.0:
		var s := FOOT_Z - _driver.global_position.z
		if not paused and s >= PAUSE_AT:
			paused = true
			Input.action_release("accelerate")
			resumed = time + PAUSE
		if paused and time >= resumed and not Input.is_action_pressed("accelerate"):
			Input.action_press("accelerate")
		_driver.call("look_toward", Vector3.FORWARD)
		await physics_frame
		time += 1.0 / 60.0
		samples.append(_sample(time))
	Input.action_release("accelerate")
	await _seconds(0.4)
	var treads: Array[int] = []
	var feet: Array[int] = []
	for plant: Dictionary in _plants(samples):
		var index := _step_index(plant["ankle"])
		var stayed: bool = not treads.is_empty() and treads[-1] == index \
			and feet[-1] == plant["foot"]
		if index > 0 and index < RISERS and not stayed:
			treads.append(index)
			feet.append(plant["foot"])
	var turns := true
	for index in range(1, feet.size()):
		turns = turns and feet[index] != feet[index - 1]
	var through := _through(samples)
	var jumps := _jumps(samples)
	var top: float = samples[-1]["body"].y if not samples.is_empty() else -INF
	var every: Array[int] = []
	for tread in range(1, RISERS):
		every.append(tread)
	_check(paused and treads == every and turns and through <= CLEAR
		and jumps <= JUMP and absf(top - RISE * RISERS) < 0.05,
		("S10: W let go halfway up (%s) and pressed again a second on, his feet still take one "
		+ "tread a step, by turns (a foot settling where it stands is no step): %s by foot %s; "
		+ "no foot at most %.3f m into a step, nothing "
		+ "jumping more than %.3f m a frame, and he reaches the landing (%.2f m up)") % [paused,
		str(treads), str(feet), through, jumps, top])


func _check_slope() -> void:
	var length := Vector2(SLOPE_RUN, SLOPE_RISE).length()
	var angle := atan2(SLOPE_RISE, SLOPE_RUN)
	var middle := Vector3(-41.8, SLOPE_RISE / 2.0, SLOPE_FOOT_Z - SLOPE_RUN / 2.0)
	var ramp := _fixture(middle - Vector3(0.0, cos(angle), sin(angle)) * 0.1,
		Vector3(2.0, 0.2, length))
	ramp.rotation.x = angle
	var top := _fixture(Vector3(-41.8, SLOPE_RISE / 2.0, SLOPE_FOOT_Z - SLOPE_RUN - 1.0),
		Vector3(2.0, SLOPE_RISE, 2.0))
	await _place(SLOPE_FROM, Vector3.FORWARD)
	var samples := await _walk_recorded(SLOPE_TO, 6.0)
	ramp.queue_free()
	top.queue_free()
	var jumps := _jumps(samples)
	var up: float = samples[-1]["body"].y if not samples.is_empty() else -INF
	_check(jumps <= JUMP and absf(up - SLOPE_RISE) < 0.03,
		("S9: up a %.0f° slope he walks along it without stepping up: his body, hips and camera "
		+ "rise at most %.3f m a frame (at most %.2f), %.2f m up at its top") % [rad_to_deg(angle),
		jumps, JUMP, up])


func _jumps(samples: Array[Dictionary]) -> float:
	var most := 0.0
	for index in range(1, samples.size()):
		for part: String in ["body", "camera", "hips"]:
			most = maxf(most, absf((samples[index][part] as Vector3).y
				- (samples[index - 1][part] as Vector3).y))
	return most


func _through(samples: Array[Dictionary]) -> float:
	var through := -INF
	for sample: Dictionary in samples:
		if FOOT_Z - (sample["body"] as Vector3).z < -NEAR_STAIR:
			continue
		for side in range(2):
			var points: Array = sample["feet"][side]
			through = maxf(through, _profile(points[0]) + ANKLE_CLEAR - (points[0] as Vector3).y)
			for point: Vector3 in [points[1], points[2]]:
				through = maxf(through, _profile(point) - point.y)
	return through


func _sample(time: float) -> Dictionary:
	var model := _skeleton.get_parent() as Node3D
	while model != null and model.name != "Ethan":
		model = model.get_parent() as Node3D
	var turn := model.rotation.y if model != null else 0.0
	return {"time": time, "clip": str(_anim.current_animation),
		"body": _driver.global_position, "camera": _camera.global_position,
		"hips": _pose[0], "feet": [[_pose[1], _pose[3], _pose[5]], [_pose[2], _pose[4], _pose[6]]],
		"joints": [_pose[7], _pose[8]], "knees": [_pose[9], _pose[10]],
		"left": Vector3.UP.cross(Vector3(sin(turn), 0.0, cos(turn)))}


func _check_kerb() -> void:
	var clear := _clear_box(KERB_AT + Vector3.UP * 0.3, KERB_SIZE + Vector3(0.0, 0.4, 3.0))
	var kerb := _fixture(KERB_AT, KERB_SIZE)
	await _place(KERB_FROM, Vector3.FORWARD)
	await _seconds(0.5)
	var resting := _camera.global_position.y - _driver.global_position.y
	var samples := await _walk_recorded(KERB_TO, 6.0)
	await _seconds(0.5)
	var settled := absf(_camera.global_position.y - _driver.global_position.y - resting)
	var stepped := 0.0
	var camera_tick := 0.0
	var hips_tick := 0.0
	for index in range(1, samples.size()):
		var now: Dictionary = samples[index]
		var was: Dictionary = samples[index - 1]
		stepped = maxf(stepped, (now["body"] as Vector3).y - (was["body"] as Vector3).y)
		camera_tick = maxf(camera_tick, absf((now["camera"] as Vector3).y
			- (was["camera"] as Vector3).y))
		hips_tick = maxf(hips_tick, absf((now["hips"] as Vector3).y - (was["hips"] as Vector3).y))
	var on_top := absf(_driver.global_position.y - KERB) < 0.03
	kerb.queue_free()
	_check(clear and on_top and stepped >= KERB * 0.8 and camera_tick <= KERB_RISE_TICK
		and hips_tick <= KERB_RISE_TICK and settled <= 0.01,
		("S7: onto a %.2f m kerb his body steps up as before (%.3f m in one frame; on top %s), "
		+ "but his camera and hips glide up, at most %.3f and %.3f m a frame (at most %.3f), "
		+ "the camera settled %.3f m from its usual height 0.5 s on (the kerb's ground clear: "
		+ "%s)") % [KERB, stepped, on_top, camera_tick, hips_tick, KERB_RISE_TICK, settled,
		clear])


func _check_camera() -> void:
	await _place(CAMERA_AT, Vector3.FORWARD)
	await _seconds(0.8)
	var free_length := _camera_gap()
	var pivot := _camera.global_position
	var behind := (pivot - _driver.global_position - Vector3.UP * 1.55)
	behind = Vector3(behind.x, 0.0, behind.z).normalized()
	var wall := _fixture(_driver.global_position + behind * WALL_BEHIND + Vector3.UP * 1.5,
		Vector3(4.0, 3.0, 0.1))
	await physics_frame
	await physics_frame
	await physics_frame
	var squeezed := _camera_gap()
	wall.queue_free()
	var gaps: Array[float] = []
	for tick in range(90):
		await physics_frame
		gaps.append(_camera_gap())
	var widest_tick := 0.0
	var out_by := INF
	for index in range(1, gaps.size()):
		widest_tick = maxf(widest_tick, gaps[index] - gaps[index - 1])
		if out_by == INF and gaps[index] >= OUT_AGAIN:
			out_by = index / 60.0
	var again := _fixture(_driver.global_position + behind * WALL_BEHIND + Vector3.UP * 1.5,
		Vector3(4.0, 3.0, 0.1))
	await physics_frame
	await physics_frame
	await physics_frame
	var squeezed_again := _camera_gap()
	again.queue_free()
	_check(squeezed <= SQUEEZED and squeezed_again <= SQUEEZED and widest_tick <= EASE_TICK
		and out_by <= 1.2,
		("S8: a wall 1 m behind him pulls his camera in at once (%.2f m from his head, then "
		+ "%.2f, at most %.2f); once the wall is gone it eases back out, at most %.3f m a frame "
		+ "(at most %.2f), %.2f m out within %.2f s (free: %.2f m)") % [squeezed, squeezed_again,
		SQUEEZED, widest_tick, EASE_TICK, OUT_AGAIN, out_by, free_length])


func _camera_gap() -> float:
	return _camera.global_position.distance_to(_driver.global_position + Vector3.UP * 1.55)


func _plants(samples: Array[Dictionary]) -> Array[Dictionary]:
	var plants: Array[Dictionary] = []
	for side in range(2):
		var run: Array[int] = []
		for index in range(1, samples.size() + 1):
			var still := false
			if index < samples.size():
				var now: Vector3 = samples[index]["feet"][side][0]
				var was: Vector3 = samples[index - 1]["feet"][side][0]
				still = (now - was).length() * 60.0 < STILL
			if still:
				run.append(index)
			elif run.size() >= STILL_TICKS:
				var middle: Dictionary = samples[run[run.size() / 2]]
				plants.append({"foot": side, "time": middle["time"],
					"ankle": middle["feet"][side][0], "ball": middle["feet"][side][1],
					"tip": middle["feet"][side][2], "hip": middle["joints"][side],
					"other": middle["feet"][1 - side][0], "left": middle["left"]})
				run.clear()
			else:
				run.clear()
	plants.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["time"] < b["time"])
	return plants


func _profile(point: Vector3) -> float:
	if point.x < STAIR_X.x or point.x > STAIR_X.y:
		return 0.0 if point.x > STAIR_X.y else RISE * RISERS
	var s := FOOT_Z - point.z
	if s < 0.0:
		return 0.0
	if s < TREAD * (RISERS - 1):
		return (floorf(s / TREAD) + 1.0) * RISE
	return RISE * RISERS


func _step_index(point: Vector3) -> int:
	var s := FOOT_Z - point.z
	if s < 0.0:
		return 0
	if s < TREAD * (RISERS - 1):
		return int(floorf(s / TREAD)) + 1
	return RISERS


func _on_pose() -> void:
	for index in range(_bone_ids.size()):
		_pose[index] = (_skeleton.global_transform * _skeleton.get_bone_global_pose(
			_bone_ids[index])).origin


func _walk_recorded(goal: Vector3, limit: float) -> Array[Dictionary]:
	var samples: Array[Dictionary] = []
	var time := 0.0
	Input.action_press("accelerate")
	while _flat(goal - _driver.global_position).length() > 0.3 and time < limit:
		_driver.call("look_toward", _flat(goal - _driver.global_position).normalized())
		await physics_frame
		time += 1.0 / 60.0
		samples.append(_sample(time))
	Input.action_release("accelerate")
	await _seconds(0.4)
	return samples


func _place(at: Vector3, facing: Vector3) -> void:
	_driver.global_position = at
	_driver.velocity = Vector3.ZERO
	_driver.call("face", facing)
	_driver.call("look_toward", facing)
	await physics_frame
	await _seconds(0.3)


func _fixture(at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	root.add_child(body)
	body.global_position = at
	return body


func _clear_box(at: Vector3, size: Vector3) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	box.size = size
	query.shape = box
	query.transform = Transform3D(Basis.IDENTITY, at)
	query.exclude = [_driver.get_rid()]
	return _van.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


func _on_foot() -> bool:
	return not bool(_van.get("occupied")) and not bool(_app.get("_boarding"))


func _until(done: Callable, limit: float) -> void:
	var time := 0.0
	while not done.call() and time < limit:
		await physics_frame
		time += 1.0 / 60.0


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


func _remove() -> void:
	for suffix in ["", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(_scratch + suffix):
			DirAccess.remove_absolute(_scratch + suffix)


func _timeout() -> void:
	_check(false, "The stair checks finish within 240 s")
	_finish()


func _finish() -> void:
	print("STAIR RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	_remove()
	quit(1 if _failures > 0 else 0)
