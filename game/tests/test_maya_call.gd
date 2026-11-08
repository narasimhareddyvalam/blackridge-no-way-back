extends SceneTree

const LaneKeeper = preload("res://tests/lane_keeper.gd")
const PhoneCall = preload("res://features/missions/night_freight/phone_call.gd")
const Mission = preload("res://features/missions/night_freight/first_drive.gd")
const BEFORE_CALL := 84
const PAST_CALL := 120
const LANE := 1.0
const SPEED := 8.0
const DUCK_WAIT := 0.8
const WAIT_AT := 712
const FAST := 16.0
const APPROVED: Array[String] = [
	"MAYA: Hey. Still working?",
	"ETHAN: Last run of the night. Almost done.",
	"MAYA: You always say that.",
	"ETHAN: You eating okay?",
	"MAYA: Ethan.",
	"ETHAN: That's not an answer.",
	"MAYA: I'm fine. Work's just busy.",
	"ETHAN: Come by Sunday. I'll cook.",
	"MAYA: Maybe. I'll let you know.",
	"ETHAN: Lock your door tonight.",
	"MAYA: I'm twenty-five.",
	"ETHAN: Lock it anyway.",
	"MAYA: Drive safe, okay?",
]

var _checks: int = 0
var _failures: int = 0
var _app: Node3D
var _van: CharacterBody3D
var _route: Node
var _road: RefCounted
var _hud: CanvasLayer
var _audio: Node
var _navigation: Control
var _scratch: String


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(180.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-call-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	_van = _app.get_node("FreightVan")
	_route = _app.get_node("DrivingTrial")
	_road = _app.get_node("IndustrialLoop").get("road")
	_hud = _app.get_node("DrivingHud")
	await process_frame
	_app.call("_resume")
	_audio = _app.get("_audio")
	_navigation = _van.get_node("VanPresentation").get("navigation")
	await physics_frame
	_check(_navigation.get("caller") == "" and not bool(_audio.call("calling")),
		"The drive starts quietly: no call, and the dash shows the map")
	await _drive_to_call()
	if not bool(_audio.call("calling")):
		_check(false, "Driving onto the climb, the phone rings")
		_finish()
		return
	_check(_navigation.get("caller") == "MAYA" and float(_navigation.get("call_seconds")) < 0.0,
		"Driving onto the climb, the phone rings through the van and the dash shows MAYA, "
		+ "incoming")
	_hold("brake", true)
	await _check_waits()
	await _tap("answer_call")
	await _check_call()
	_hold("brake", false)
	await _drive_to_call()
	_check(not bool(_audio.call("calling")) and _navigation.get("caller") == "",
		"Driving onto the climb again, she does not call twice")
	_route.call("restart")
	_app.call("_resume")
	await physics_frame
	await _drive_to_call()
	_check(bool(_audio.call("calling")), "A new drive brings the call back")
	_hold("brake", true)
	await _check_missed()
	_hold("brake", false)
	_check_fits()
	await _check_scene_waits()
	_finish()


func _check_waits() -> void:
	await _seconds(3.0)
	await _seconds(0.4)
	var call: Node = _route.get("phone_call")
	var hint := (_hud.get("_hint") as Label).text
	_check(bool(_audio.call("calling")) and not bool(call.get("talking"))
		and _navigation.get("call_state") == "ringing" and hint == "T  Answer the call",
		"It keeps ringing until answered: the dash asks for T, and the hint says \"%s\"" % hint)


func _check_missed() -> void:
	var call: Node = _route.get("phone_call")
	var rang := 0.0
	while bool(_audio.call("calling")) and rang < 20.0:
		await physics_frame
		rang += 1.0 / 60.0
	var missed_shown: bool = _navigation.get("call_state") == "missed"
	var waited := 0.0
	while not bool(_audio.call("calling")) and waited < 12.0:
		await physics_frame
		waited += 1.0 / 60.0
	var second := int(call.get("attempt"))
	while bool(_audio.call("calling")) and rang < 40.0:
		await physics_frame
		rang += 1.0 / 60.0
	while not bool(_audio.call("calling")) and waited < 24.0:
		await physics_frame
		waited += 1.0 / 60.0
	var third := int(call.get("attempt"))
	var auto: bool = _navigation.get("call_state") == "auto"
	var picked := 0.0
	while not bool(call.get("talking")) and picked < 8.0:
		await physics_frame
		picked += 1.0 / 60.0
	var expected := PhoneCall.AUTO_RINGS * PhoneCall.RING_SECONDS
	_check(missed_shown and second == 2 and third == 3 and auto and bool(call.get("talking"))
		and absf(picked - expected) < 0.2,
		"Unanswered, the call is missed and she calls back; after two missed calls the third "
		+ "picks up by itself after two rings (%.1f s)" % picked)
	_route.call("restart")
	await physics_frame


func _check_fits() -> void:
	var phone: Node = _route.get("phone_call")
	var talk := 0.0
	for line: Array in Mission.MAYA_CALL:
		talk += float(phone.call("line_seconds", line[1])) + PhoneCall.GAP
	var worst := (PhoneCall.ATTEMPTS - 1) * (PhoneCall.RINGS * PhoneCall.RING_SECONDS
		+ PhoneCall.CALL_BACK) + PhoneCall.AUTO_RINGS * PhoneCall.RING_SECONDS + talk
	var points: PackedVector3Array = _road.points
	var metres := 0.0
	for index in range(Mission.CALL_AT, Mission.ENCOUNTER_SPAN.x):
		metres += Vector2(points[index + 1].x - points[index].x,
			points[index + 1].z - points[index].z).length()
	var top := float(_van.get("maximum_speed"))
	_check(worst < metres / top, "Left to ring out twice, her call still ends before even a "
		+ "flat-out van could reach the pedestrian scene (%.1f s after the first ring; " % worst
		+ "%.0f m at %.0f km/h takes %.1f s)" % [metres, top * 3.6, metres / top])


func _check_scene_waits() -> void:
	_app.call("_resume")
	await physics_frame
	_route.set("stage", Mission.ENCOUNTER_STAGE)
	_route.get("phone_call").call("start", "MAYA", Mission.MAYA_CALL)
	_place(WAIT_AT)
	var keeper := LaneKeeper.new(_road, WAIT_AT)
	await _coast(0.6, keeper)
	var waited := not is_instance_valid(_route.get("oncoming"))
	_route.get("phone_call").call("stop")
	await _coast(0.4, keeper)
	keeper.release()
	_check(waited and is_instance_valid(_route.get("oncoming")),
		"While she is on the line, the pedestrian scene waits, and it begins once the call ends")
	_route.call("restart")
	await physics_frame


func _coast(duration: float, keeper: RefCounted) -> void:
	for frame in range(int(duration * 60.0)):
		_van.set("speed", FAST)
		keeper.call("steer", _van, LANE)
		await physics_frame


func _drive_to_call() -> void:
	_place(BEFORE_CALL)
	_van.set("speed", SPEED)
	var keeper := LaneKeeper.new(_road, BEFORE_CALL)
	var waited := 0.0
	while waited < 6.0 and not bool(_audio.call("calling")) and _index() < PAST_CALL:
		await physics_frame
		waited += 1.0 / 60.0
		keeper.steer(_van, LANE)
		_hold("accelerate", float(_van.get("speed")) < SPEED)
	keeper.release()
	_hold("accelerate", false)


func _check_call() -> void:
	var call: Node = _route.get("phone_call")
	var connected := bool(call.get("talking")) and not bool(_audio.call("calling"))
	await _seconds(PhoneCall.GAP + 0.6)
	var dipped := float(_audio.call("music_level"))
	_check(connected and dipped < -10.0 and float(_navigation.get("call_seconds")) >= 0.0
		and _navigation.get("call_state") == "talking",
		"Pressing T answers: it connects hands-free at once, the dash shows the call, and the "
		+ "music dips %.0f dB" % dipped)
	var heard: Array[String] = [_hud.call("subtitle")]
	var talked := PhoneCall.GAP + 0.6
	while bool(_route.get("phone_call").get("active")) and talked < 60.0:
		await physics_frame
		talked += 1.0 / 60.0
		var shown: String = _hud.call("subtitle")
		if shown != "" and shown != heard[-1]:
			heard.append(shown)
	_check(heard == APPROVED, "Her call plays the 13 approved lines in order, as subtitles "
		+ "(%d heard; first \"%s\", last \"%s\")" % [heard.size(), heard[0], heard[-1]])
	_check(talked > 20.0 and talked < 40.0, "The call is short: %.0f s once connected" % talked)
	await _seconds(DUCK_WAIT)
	_check(_hud.call("subtitle") == "" and absf(float(_audio.call("music_level"))) < 0.5
		and _navigation.get("caller") == "",
		"When she hangs up, the subtitles clear, the music comes back and the dash shows the map")
	await _seconds(0.4)
	var hint := (_hud.get("_hint") as Label).text
	_check(hint.begins_with("L  High beams"),
		"After the call, on the dark climb, the hint teaches the high beams (%s)" % hint)


func _index() -> int:
	var points: PackedVector3Array = _road.points
	var best := 0
	for index in range(0, 300):
		if _van.global_position.distance_squared_to(points[index]) \
				< _van.global_position.distance_squared_to(points[best]):
			best = index
	return best


func _place(index: int) -> void:
	var points: PackedVector3Array = _road.points
	var basis := Basis(Vector3.UP, _road.call("heading_at", index))
	_van.call("recover", Transform3D(basis, points[index] + basis.x * LANE + Vector3.UP * 0.1))


func _tap(action: String) -> void:
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


func _hold(action: String, pressed: bool) -> void:
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _seconds(duration: float) -> void:
	for frame in range(int(duration * 60.0)):
		await physics_frame


func _finish() -> void:
	print("CALL RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	_app.queue_free()
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "Call test finished within 180 s of game time")
	quit(1)
