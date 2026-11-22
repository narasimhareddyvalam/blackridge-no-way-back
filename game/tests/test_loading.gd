extends SceneTree
## Step 2e, the load and the seal (docs/PHASE_BRIEF.md, rules H1–H9, with the author's decisions
## L1 c and L2 b, #230), in the running game on Mission 2's start save. The van is set docked and
## chocked at bay 9 as setup (`test_bay_nine.gd` reaches that by real keys); from there Ethan's
## actions use the real keys. Ethan's push behind the jack (#239–#240) is read from his skeleton
## as it is posed: where his feet, hands and head are. A headless run draws nothing, so the look
## is not checked here.

const START_SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const DOCKED := Vector3(-47.75, 0.1, 23.16)
const DOCK_FLOOR := 1.3
const HOLD_FLOOR := Vector3(0.0, 0.614, 2.5)
const SILL := Vector3(0.0, 0.66, 2.74)
const LIP_THICK := 0.025
const BULKHEAD := -0.25
const LOAD_HALF := 0.61
const TO_THE_SIDE_DOOR: Array[Vector3] = [Vector3(-39.0, 0.0, 22.0), Vector3(-39.0, 0.0, 17.5)]
const INSIDE_THE_DOOR := Vector3(-41.2, 0.0, 17.5)
const STAIR_FOOT := Vector3(-44.2, 0.0, 16.0)
const ON_THE_STAIR := Vector3(-44.2, 0.0, 14.8)
const OFF_ITS_SIDE := Vector3(-42.5, 0.0, 14.8)
const STAIR_RAIL_X := -43.7
const TO_THE_DOCK: Array[Vector3] = [Vector3(-44.2, 0.0, 13.4), Vector3(-45.6, 0.0, 13.4)]
const TO_THE_LIFT: Array[Vector3] = [Vector3(-46.2, 0.0, 15.0), Vector3(-46.2, 0.0, 18.4),
	Vector3(-47.75, 0.0, 18.4)]
const TRAVEL := 8.0
const HOLD_TAP := 0.3
const STROKE := 0.6
## The game refreshes its hint every 0.2 s (`first_drive.gd`): read it once a refresh has passed.
const HINT_REFRESH := 0.25
const PUMPS := Vector2i(3, 7)
const PUMP_ARC := 15.0
const LOWERED := 1.6
## A foot within its leg's reach of its own hip (thigh 0.41 m and shin 0.42 m), as far back as the
## pushing clip's lunge takes it, leaning into the load.
const FOOT_UNDER_HIP := 0.75
const FOOT_JUMP := 0.08
## Walking, a man's heels pass about 0.08-0.12 m apart: each ankle on its own side of the middle.
const OWN_SIDE := 0.04
const RING_X := 0.8
const STRAP_STEP := 0.45
const STRAP_PRESSES_MOST := 20
const STRAP_ORDER: Array[String] = ["Hook the strap to the floor ring",
	"Throw the strap over the load", "Hook it to the far ring", "Ratchet the strap tight",
	"Ratchet the strap tight", "Ratchet the strap tight", "Ratchet the strap tight"]
const STEPPED_IN := 1.0
const STOOD_BACK := 1.3
const CLOSE_BEHIND := 1.22
const SINKING := 0.4
const OFF_THE_DECK: Array[Vector3] = [Vector3(-46.3, 0.0, 18.4)]
const DECK_HALF := 0.92
const ROUND_THE_LOAD: Array[Vector3] = [Vector3(-46.3, 0.0, 18.4), Vector3(-46.3, 0.0, 15.0),
	Vector3(-47.2, 0.0, 15.15)]
const BEHIND_THE_HANDLE := 0.3
const PAST_THE_GUARD := Vector2(-47.75, 20.6)
const WALL_JACK := Transform3D(Basis.IDENTITY, Vector3(-45.8, 1.3, 18.9))
const BY_THE_WALL: Array[Vector3] = [Vector3(-45.15, 0.0, 17.68), Vector3(-45.15, 0.0, 19.45)]
const TO_THE_BULKHEAD := Vector2(-47.75, 22.9)
const LOAD_KG := 520.0
const SINK_PER_KG := 0.00005
const FRONT_AXLE := Vector3(0.0, 0.5, -1.507)
const REAR_AXLE := Vector3(0.0, 0.5, 1.997)
const STANDING := 1.8
const STOOPED := 1.35
const ON_THE_DOCK := Vector2(-47.2, 18.0)
const STOP_WAIT := 3.5
const DOCK_PACE := 0.9
const VAN_PACE := 0.377
const PACE_TOLERANCE := 0.025
const START_SECONDS := 0.3
const ARM_LENGTH := Vector2(1.60, 1.70)
const VAN_REAR := 3.012
const DOOR_HEIGHT := 1.45
const ROOF_HEIGHT := 1.536
const HAIR := 0.06
const LOOP_X := 0.173
const LOOP_Y := Vector2(0.73, 0.85)
const LOOP_Z := 0.0
const WALK_TILT := Vector2(15.0, 40.0)
const VAN_TILT := Vector2(20.0, 45.0)
const BELOW_HEAD := 0.3
const UPRIGHT := 15.0
const BREAKAWAY := 0.8
const ON_LOOP := 0.04
const OFF_LOOP := 0.08
const TOE_DOWN := 0.05
const SLIP := 0.05
const SETTLED := 24
const SETTLED_CLIP := 0.3
const STEER_SETTLED := 12
const STEER_GAIN := 3.0
const STEER_EASE := 1.5
const STEER_MOST := deg_to_rad(35.0)
const STEER_HOLD := deg_to_rad(2.0)
const HANDS_LET_GO := 56.0
const STOP_PLANTED := 61.0
const ROD := 0.017
const TILLER: Array[Vector3] = [Vector3(0.0, 0.05, 0.0), Vector3(0.0, 0.65, 0.0),
	Vector3(-0.13, 0.65, 0.0), Vector3(-0.19, 0.8, 0.0), Vector3(-0.08, 0.9, 0.0),
	Vector3(0.08, 0.9, 0.0), Vector3(0.19, 0.8, 0.0), Vector3(0.13, 0.65, 0.0)]
const TILLER_PIECES: Array[Vector2i] = [Vector2i(0, 1), Vector2i(1, 2), Vector2i(2, 3),
	Vector2i(3, 4), Vector2i(4, 5), Vector2i(5, 6), Vector2i(6, 7), Vector2i(7, 1)]
const FINGERS: Array[String] = ["Index", "Middle", "Ring", "Pinky"]
const WRAPPED := 0.045
const UNDER_PALM := 0.03
const POST_RADIUS := 0.02
const LOAD_WIDE := 0.535
const ETHAN_RADIUS := 0.3
const FORKS_HALF := Vector2(0.35, 0.8)
const FORKS_BACK := 0.4
const AT_THE_POST := 0.2
const STRAIGHT_ON := 3.0
const PULL_LIMIT := 25.0
const PULL_OUT := 3.4
## The way onto bay 9's lift from the dock: as wide as its deck and a body either side, from 3 m
## out to the deck's edge.
const APPROACH := Rect2(-48.965, 14.3, 2.43, 3.0)
## Ethan's body about his bones, measured on his rest pose's mesh: how far his jacket, chin, face
## and trousers stand in front of each bone between two joints.
const BODY: Array = [["Hips", "Spine", 0.126], ["Spine", "Spine1", 0.129],
	["Spine1", "Spine2", 0.146], ["Spine2", "Neck", 0.143], ["Neck", "Head", 0.138],
	["Head", "HeadTop_End", 0.133], ["LeftUpLeg", "LeftLeg", 0.10],
	["RightUpLeg", "RightLeg", 0.10]]

var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _app: Node3D
var _hud: CanvasLayer
var _van: CharacterBody3D
var _driver: CharacterBody3D
var _shed: Node3D
var _bay: Node
var _watching := false
var _lowest := INF
var _shortest := INF
var _clips_outside: Array[String] = []
var _clips_inside: Array[String] = []
var _deepest := INF
var _skeleton: Skeleton3D
var _player: AnimationPlayer
var _jack: Node3D
var _tiller: Node3D
var _lean := {}
var _tilt := {}
var _head_clear := {}
var _pull_outside: Array[String] = []
var _bones := {}
var _segment := ""
var _last_clip := ""
var _clip_segment := ""
var _since_clip: int = 0
var _clip_since := 0.0
var _since_steer: int = STEER_SETTLED + 1
var _toes_before: Array[Vector3] = [Vector3.INF, Vector3.INF]
var _trail: Array[Vector2] = []
var _slips := {}
var _hand_gap := {}
var _clips := {}
var _paces := {}
var _reach := Vector2(INF, -INF)
var _head_door := -INF
var _head_roof := -INF
var _hauled := false
var _pushed_back := false
var _starts: Array[float] = []
var _released_at := Vector2.INF
var _pose := {}
var _said: Array[String] = []
var _saying := false
var _down_said := ""
var _body_clear := {}
var _feet_off := 0.0
var _own_side := {}
var _feet_jump := 0.0
var _last_feet: Array[Vector3] = []
var _tips_off := {}
var _post_clear := Vector3(INF, INF, INF)


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(420.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-loading-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_store(START_SAVE)
	await _build()
	physics_frame.connect(_say)
	await _key(KEY_ENTER)
	await _seconds(1.0)
	_shed = _app.get_node("IndustrialLoop").get("transfer_shed")
	_bay = _shed.get("bay_nine")
	_van.call("recover", Transform3D(Basis(Vector3.UP, PI), DOCKED))
	_van.set("rear_doors_open", true)
	await _seconds(1.5)
	var docked: bool = _bay.get("verdict") == "docked"
	if docked:
		_bay.call("chock_wheel")
	_check(docked and bool(_bay.get("chocked")), "Setup: the van docked at bay 9 and chocked")
	await _key(KEY_E)
	await _until(_on_foot, 8.0)
	await _check_way_onto_the_dock()
	await _check_lift()
	await _check_loading()
	_finish()


func _check_way_onto_the_dock() -> void:
	await _walk(TO_THE_SIDE_DOOR)
	var offered := _hint()
	var outside := _driver.global_position
	await _walk([INSIDE_THE_DOOR], 1.5)
	var held := _driver.global_position.x > -40.0
	await _walk([outside])
	await _key(KEY_E)
	await _seconds(1.5)
	var door := _shed.find_child("SideDoorLeaf", true, false) as Node3D
	var swung := absf(rad_to_deg(door.rotation.y)) if door != null else -1.0
	_check(offered == "E  Open the door" and held and swung >= 80.0,
		("H8: the shed's side door, beside the drive-in lane, keeps Ethan out while shut (%s); "
		+ "the hint offers it (%s) and E swings it open (%.0f°)") % [held, offered, swung])
	await _walk([INSIDE_THE_DOOR, STAIR_FOOT, ON_THE_STAIR])
	await _walk([OFF_ITS_SIDE], 1.2)
	var kept := _driver.global_position.x < STAIR_RAIL_X
	await _walk(TO_THE_DOCK)
	var feet := _driver.global_position.y
	_check(kept and absf(feet - DOCK_FLOOR) < 0.08,
		("H8: inside, the stair climbs from the drive-in lane to the dock floor, Ethan's feet %.2f "
		+ "m up at its top, and its rail keeps him from stepping off its open side (%s)")
		% [feet, kept])


func _check_lift() -> void:
	await _walk(TO_THE_LIFT)
	var offered := _hint()
	await _check_hold_to_run()
	await _hold_key(KEY_E, TRAVEL)
	var lift := _shed.get_node_or_null("Building/DockLift9") as Node3D
	var floor_y := _van.to_global(HOLD_FLOOR).y
	var deck := lift.global_position.y if lift != null else INF
	var tip := _lip_tip(lift)
	var feet := _driver.global_position.y
	var raise := _hint()
	var sill := _van.to_global(SILL)
	var resting := _plate_underside_at(lift, sill.z) - sill.y
	_check(offered == "E  Hold to lower the lift" and absf(deck - floor_y) <= 0.02
		and absf(resting) <= 0.012 and tip.z > sill.z + 0.05 and tip.y - floor_y < 0.12
		and absf(feet - deck) < 0.06,
		("H1: on the deck the hint offers the lift (%s); E lowers it to the van's floor (%.3f m "
		+ "against %.3f); its bridge plate rests on the van's rear sill (%.3f m off it) and "
		+ "reaches %.2f m past it over the floor, its edge %.3f m above the floor; Ethan rides "
		+ "it (his feet %.2f m)") % [offered, deck, floor_y, resting, tip.z - sill.z,
		tip.y - floor_y, feet])
	await _hold_key(KEY_E, TRAVEL)
	deck = lift.global_position.y if lift != null else INF
	tip = _lip_tip(lift)
	feet = _driver.global_position.y
	_check(raise == "E  Hold to raise the lift" and absf(deck - DOCK_FLOOR) <= 0.01
		and tip.y > deck + 0.4 and absf(feet - DOCK_FLOOR) < 0.06,
		("H1: E again raises it flush with the dock floor (%.3f m), its plate stored upright (its "
		+ "edge %.2f m up), Ethan with it (%.2f m)") % [deck, tip.y, feet])


func _check_loading() -> void:
	var load := _shed.get_node_or_null("Building/Pallet6") as Node3D
	var lift := _shed.get_node_or_null("Building/DockLift9") as Node3D
	var in_the_way: Array[String] = []
	for found in _shed.find_children("Pallet*", "Node3D", true, false):
		var stack := found as Node3D
		var spot := Rect2(stack.global_position.x - LOAD_WIDE, stack.global_position.z - LOAD_HALF,
			LOAD_WIDE * 2.0, LOAD_HALF * 2.0)
		if stack != load and str(stack.name).trim_prefix("Pallet").is_valid_int() \
				and spot.intersects(APPROACH):
			in_the_way.append(str(stack.name))
	_check(in_the_way.is_empty(),
		("H14: the way onto bay 9's lift is clear, its own pallet the only load staged there (in "
		+ "the way: %s)") % (", ".join(in_the_way) if not in_the_way.is_empty() else "none"))
	if load == null or lift == null:
		_check(false, "H9: bay 9's staged load Pallet6 and its lift are there")
		return
	var floor_y := load.global_position.y
	var jack_start := (_shed.find_child("PalletJack", true, false) as Node3D).global_transform
	await _walk(ROUND_THE_LOAD)
	var offered := _hint()
	await _key(KEY_E)
	_saying = true
	await _seconds(0.5)
	await _check_pumping(load, floor_y)
	var lifted := load.global_position.y - floor_y
	_check(offered == "E  Take the pallet jack" and lifted > 0.015 and lifted < 0.12,
		("H9: behind its handle the hint offers the jack (%s); E takes it, and pumped, its forks "
		+ "raise the pallet above them %.3f m off the floor") % [offered, lifted])
	_track()
	_segment = "dock"
	await _push_to(PAST_THE_GUARD, 25.0, 2.0)
	_segment = ""
	var plate := lift.find_child("BridgeLip", true, false) as Node3D
	var guard := plate.global_position.z if plate != null else -INF
	var front := _front_of(load)
	_check(_jack_held() and front <= guard + 0.005 and front >= guard - 0.08,
		("H9: pushed on to the lift's deck, the pallet stops at the deck's front against the "
		+ "bridge plate standing up as a toe guard, never over the edge (its front at z %.3f, the "
		+ "plate at %.3f)") % [front, guard])
	var dock_pace: float = _paces.get("dock", 0.0)
	var start: float = _starts.max() if not _starts.is_empty() else INF
	var dock_clips: Array = _clips.get("dock", [])
	var walk_tilt: Vector2 = _tilt.get("dock", Vector2(INF, -INF))
	_check(absf(dock_pace - DOCK_PACE) <= PACE_TOLERANCE and start < 0.5 * DOCK_PACE * START_SECONDS
		and _slip("dock") <= SLIP and _hand_gap.get("dock", INF) <= ON_LOOP
		and dock_clips.find("Push") >= 0 and dock_clips.find("Walk") > dock_clips.find("Push")
		and _lean.get("dock", INF) <= UPRIGHT and walk_tilt.x >= WALK_TILT.x
		and walk_tilt.y <= WALK_TILT.y,
		("H2: on the dock Ethan leans in to get the load going (%s), then walks nearly upright "
		+ "behind it (leaning %.0f° at most), the jack at the pace of his feet, %.3f m/s, his "
		+ "planted feet slipping at most %.3f m/s, the load getting going slowly (%.3f m in its "
		+ "first %.1f s), the handle tilted down to his hands (%.0f° to %.0f°), his palms at most "
		+ "%.3f m off its loop") % [str(dock_clips), _lean.get("dock", INF), dock_pace,
		_slip("dock"), start, START_SECONDS, walk_tilt.x, walk_tilt.y,
		_hand_gap.get("dock", INF)])
	await _check_lowering(load, lift)
	await _key(KEY_E)
	await _seconds(0.5)
	var resting := absf(load.global_position.y - lift.global_position.y)
	_check(not bool(_jack_held()) and resting < 0.01
		and absf(load.global_position.x - lift.global_position.x) < 0.3,
		("H9: E sets the pallet down on the lift's deck (%.3f m above it, %.3f m off its middle) and "
		+ "E again lets go of the jack") % [resting, load.global_position.x - lift.global_position.x])
	await _to_the_pendant()
	var pendant := _hint()
	await _hold_key(KEY_E, TRAVEL)
	var floor_now := _van.to_global(HOLD_FLOOR).y
	var riding := _driver.global_position.y - lift.global_position.y
	_check(pendant == "E  Hold to lower the lift"
		and absf(load.global_position.y - floor_now) < 0.02 and absf(riding) < 0.06,
		("H1: by the pendant on the deck E lowers the lift (%s), the pallet riding it down to the "
		+ "van's floor (%.3f m against %.3f), and Ethan with it (%.3f m off the deck)")
		% [pendant, load.global_position.y, floor_now, riding])
	var body := _van.get_node("VanPresentation") as Node3D
	var rear_before := body.to_global(REAR_AXLE).y
	var front_before := body.to_global(FRONT_AXLE).y
	var deck := lift.global_position.y
	_down_said = (_hud.get("_objective") as Label).text
	await _walk([_behind_the_handle()])
	var take := _hint()
	await _key(KEY_E)
	await _seconds(0.5)
	await _pump()
	_watching = true
	_segment = "van"
	await _push_to(TO_THE_BULKHEAD, 25.0, 0.8)
	_watching = false
	_check(take == "E  Take the pallet jack" and _jack_held() and _lowest >= deck - 0.03
		and _deepest < SILL.z,
		("H2: behind the handle again E takes the jack (%s) and pushes the pallet into the van, "
		+ "walking in behind it over the bridge plate (his feet never below %.3f m, the deck at "
		+ "%.3f; %.2f m into the hold)") % [take, _lowest, deck, SILL.z - _deepest])
	var van_pace: float = _paces.get("in the van", 0.0)
	_check(_shortest <= STOOPED and "Push" in _clips_outside and _clips_inside.size() == 1
		and _clips_inside[0] == "Push"
		and _head_roof + HAIR < ROOF_HEIGHT and _head_door + HAIR < DOOR_HEIGHT
		and absf(van_pace - VAN_PACE) <= PACE_TOLERANCE and _slip("van") <= SLIP
		and _hand_gap.get("van", INF) <= ON_LOOP and _reach.y >= ARM_LENGTH.x
		and _reach.y <= ARM_LENGTH.y and _head_clear.get("van", -INF) >= BELOW_HEAD
		and (_tilt.get("van", Vector2(INF, -INF)) as Vector2).x >= VAN_TILT.x
		and (_tilt.get("van", Vector2(INF, -INF)) as Vector2).y <= VAN_TILT.y,
		("H2: under the van's low roof Ethan stoops (%.2f m tall, against %.2f standing) in "
		+ "Pushing's own lean, his clips outside %s and inside %s, his head at most %.3f m above "
		+ "the hold's floor under its %.3f m roof and %.3f m above the sill under its %.2f m rear "
		+ "door; in the hold the jack goes at Pushing's own pace, %.3f m/s, his planted feet "
		+ "slipping at most %.3f m/s, his hands at most %.3f m off the handle, at arm's length "
		+ "(%.2f m behind the jack), the handle tilted down (%s°) so his palms stay at least %.2f m "
		+ "below the top of his head") % [_shortest, STANDING, str(_clips_outside),
		str(_clips_inside), _head_roof + HAIR, ROOF_HEIGHT, _head_door + HAIR, DOOR_HEIGHT,
		van_pace, _slip("van"), _hand_gap.get("van", INF), _reach.y, str(_tilt.get("van")),
		_head_clear.get("van", -INF)])
	await _seconds(1.0)
	var holding := str(_player.current_animation) == "Push" and is_zero_approx(_player.speed_scale)
	var toes: float = _pose.get("toes_up", INF)
	var gap: float = _pose.get("loop_gap", INF)
	var head: float = _pose.get("head_up", INF)
	var clear: float = _pose.get("head_clear", -INF)
	_check(holding and toes < TOE_DOWN and gap <= ON_LOOP and head + HAIR < ROOF_HEIGHT
		and clear >= BELOW_HEAD,
		("H2: against the bulkhead the load stops and Ethan stays stooped on planted feet (%s "
		+ "held, %s; his toes at most %.3f m up), his hands on the handle (%.3f m off it, %.2f m "
		+ "below the top of his head), his head %.3f m up under the roof")
		% [_player.current_animation, holding, toes, gap, clear, head + HAIR])
	_segment = ""
	await _key(KEY_E)
	await _seconds(LOWERED)
	var inside := _van.to_local(load.global_position)
	var against := inside.z - LOAD_HALF - BULKHEAD
	_check(_van.is_ancestor_of(load) and absf(inside.x) < 0.1 and against >= -0.01
		and against <= 0.06 and absf(inside.y - HOLD_FLOOR.y) < 0.03,
		("H2: E sets the pallet down in the hold on its floor, forward against the bulkhead "
		+ "(%.3f m from it), between the wheel arches (%.3f m off the middle), and it goes with "
		+ "the van") % [against, inside.x])
	await _check_strapping(load)
	_saying = false
	var lowering := _said.find("LOWER THE LIFT")
	_check(not _said.has("LOAD THE PALLET") and lowering >= 0
		and _said.slice(lowering).has("ROLL THE PALLET IN")
		and _down_said == "ROLL THE PALLET IN",
		("H10: from the take to the strap the objective only goes on, never back to LOAD THE "
		+ "PALLET: lowering the lift while the pallet waits on its deck, then, the lift down, "
		+ "rolling it in (%s; with the lift down: %s)") % [str(_said), _down_said])
	_segment = "pull"
	await _pull_back(PULL_OUT)
	_segment = ""
	_check(_hauled and not _pushed_back and "WalkBack" in _pull_outside and _slip("pull") <= SLIP
		and _hand_gap.get("pull", INF) <= ON_LOOP and _head_roof + HAIR < ROOF_HEIGHT
		and _head_door + HAIR < DOOR_HEIGHT,
		("H2: pulling the jack back out, Ethan hauls it in the captured heavy pull in the hold "
		+ "(%s), never Pushing played backward (%s), and walks backward upright once out (%s), "
		+ "his planted feet slipping at most %.3f m/s, his hands on the handle (at most %.3f m "
		+ "off it), his head under the roof and the door (%.3f and %.3f m)") % [_hauled,
		_pushed_back, str(_pull_outside), _slip("pull"),
		_hand_gap.get("pull", INF), _head_roof + HAIR, _head_door + HAIR])
	var leave := _hint()
	await _key(KEY_E)
	await _seconds(2.0)
	var jack := _shed.find_child("PalletJack", true, false) as Node3D
	var jack_out := jack != null and not _van.is_ancestor_of(jack) \
		and _van.to_local(jack.global_position).z > 3.8
	var height := _height()
	_check(jack_out and leave == "E  Let go of the jack" and not _jack_held()
		and absf(height - STANDING) < 0.01,
		("H2: pulled back out, the jack leaves the van (%s), Ethan stands up again on the deck "
		+ "(%.2f m) and E lets go of it (%s)") % [jack_out, height, leave])
	var share := (inside.z - FRONT_AXLE.z) / (REAR_AXLE.z - FRONT_AXLE.z)
	var rear_sink := rear_before - body.to_global(REAR_AXLE).y
	var front_sink := front_before - body.to_global(FRONT_AXLE).y
	var total := LOAD_KG * SINK_PER_KG
	_check(absf(rear_sink - total * share) < 0.003
		and absf(front_sink - total * (1.0 - share)) < 0.003,
		("H2: the van settles under the %.0f kg by the estimate, shared between its axles by "
		+ "where the load stands: %.4f m at the rear (against %.4f) and %.4f m at the front "
		+ "(against %.4f)") % [LOAD_KG, rear_sink, total * share, front_sink,
		total * (1.0 - share)])
	await _to_the_pendant()
	await _hold_key(KEY_E, TRAVEL)
	_check(absf(lift.global_position.y - DOCK_FLOOR) < 0.01 and jack != null
		and absf(jack.global_position.y - DOCK_FLOOR) < 0.02 and _van.is_ancestor_of(load),
		("H1: E at the pendant raises the lift again with the jack on it (%.2f m), the load left "
		+ "in the van") % (jack.global_position.y if jack != null else INF))
	var rig: Node = _shed.get("pallet_jack")
	rig.call("reset", jack_start)
	await _walk(ROUND_THE_LOAD)
	await _key(KEY_E)
	await _seconds(0.5)
	await _pump()
	_segment = "stop"
	await _push_to(ON_THE_DOCK, 10.0, 2.0)
	await _seconds(STOP_WAIT)
	_check_stop(load)
	_clips.erase("breakaway")
	_segment = "breakaway"
	var before := Vector2(load.global_position.x, load.global_position.z)
	Input.action_press("accelerate")
	await _seconds(BREAKAWAY)
	Input.action_release("accelerate")
	_released_at = Vector2(load.global_position.x, load.global_position.z)
	await _seconds(STOP_WAIT)
	_check_breakaway(load, before)
	_segment = ""
	await _key(KEY_E)
	await _seconds(LOWERED)
	await _key(KEY_E)
	await _seconds(0.5)
	rig.call("reset", WALL_JACK)
	await _walk(BY_THE_WALL)
	var walled := _hint()
	await _key(KEY_E)
	await _seconds(0.5)
	_check(not walled.contains("pallet jack") and not _jack_held(),
		("H9: with the jack's back to the dock's front wall there is no room to stand behind its "
		+ "handle, so the hint does not offer it (%s) and E leaves it (held: %s)")
		% [walled, _jack_held()])
	var post := _shed.find_child("LiftPendantPost", true, false) as Node3D
	var aimed := jack_start.basis
	var across := aimed.x.normalized()
	var toward := post.global_position - across * (FORKS_HALF.x - AT_THE_POST) \
		* signf((post.global_position - jack_start.origin).dot(across))
	rig.call("reset", Transform3D(aimed, Vector3(toward.x, jack_start.origin.y,
		jack_start.origin.z)))
	await _walk([ROUND_THE_LOAD[0], ROUND_THE_LOAD[1], _behind_the_handle()])
	await _key(KEY_E)
	await _seconds(0.5)
	var took := _jack_held()
	Input.action_press("accelerate")
	await _seconds(STRAIGHT_ON)
	Input.action_release("accelerate")
	await _seconds(1.0)
	await _key(KEY_E)
	await _seconds(0.5)
	_check(took and _post_clear.z >= 0.0,
		("H13: the empty jack pushed straight at the pendant post, its forks lined up %.2f m "
		+ "across it, stops against it and does not pass through (taken: %s; its forks at the "
		+ "nearest %.3f m from it)") % [AT_THE_POST, took, _post_clear.z])
	var inside_him := []
	var closest := INF
	for where: String in _body_clear:
		var here: Vector2 = _body_clear[where]
		closest = minf(closest, here.x)
		var part: Array = BODY[int(here.y)]
		inside_him.append("%s %.3f m (%s-%s)" % [where, here.x, part[0], part[1]])
	_check(_body_clear.size() >= 5 and closest >= 0.0,
		("H11: the jack's handle never goes into Ethan: its rod and loop stay outside his "
		+ "jacket, chin, face and legs all the time he holds it, taking it, pushing, stooped in "
		+ "the van, pulling out, stopping and getting it going (at the nearest %s)")
		% ", ".join(inside_him))
	_check(_post_clear.x >= 0.0 and _post_clear.y >= -0.01,
		("H13: nothing goes through the lift's pendant post: the load stays outside it (at the "
		+ "nearest %.3f m) and so does Ethan (%.3f m)") % [_post_clear.x, _post_clear.y])
	_check(_own_side.size() == 3 and _own_side.values().min() >= OWN_SIDE,
		("H22: pushing on the dock, stooped in the hold and pulling out, each foot stays on its "
		+ "own side, its ankle at least %.2f m from his hips' middle line (%s)") % [OWN_SIDE,
		str(_own_side)])
	_check(_feet_off <= FOOT_UNDER_HIP and _feet_jump <= FOOT_JUMP,
		("H21: all the time he holds the jack, on the dock and stooped in the hold, each foot "
		+ "stays under him, at most %.2f m from its own hip, and never snaps, at most %.3f m in "
		+ "a frame") % [_feet_off, _feet_jump])
	_check(_tips_off.has("dock") and _tips_off.has("van")
		and maxf(_tips_off["dock"], _tips_off["van"]) <= WRAPPED,
		("H12: his hands hold the handle, not rest on it: pushing on the dock and in the van "
		+ "every fingertip is wrapped round the loop, at most %.3f m from its tube's middle, a "
		+ "finger's thickness and the tube's (open, they stood 0.11 m off it; on the dock "
		+ "%.3f, in the van %.3f)") % [WRAPPED, _tips_off.get("dock", INF),
		_tips_off.get("van", INF)])


## W let go on the dock as Ethan walks behind the jack, taken again where it was staged and
## pushed straight on: he plants his feet, the load rolling on with his last step, and stands
## there, his hands still on the handle.
func _check_stop(stack: Node3D) -> void:
	var rolled := Vector2(stack.global_position.x, stack.global_position.z).distance_to(
		_released_at)
	var clips: Array = _clips.get("stop", [])
	var gap: float = _pose.get("loop_gap", INF)
	_check("Walk" in clips and rolled > 0.02 and rolled < 0.8 and _slip("stop") <= SLIP
		and gap <= ON_LOOP and absf(_height() - STANDING) < 0.01
		and str(_player.current_animation) == "Idle",
		("H2: W let go on the dock as he walks behind it (%s), the load rolls on %.2f m with his "
		+ "last step, his planted feet slipping at most %.3f m/s; then he stands (%s), his hands "
		+ "on the handle (%.3f m off it)") % [str(clips), rolled, _slip("stop"),
		_player.current_animation, gap])


## W let go while Ethan still leans in to get the load going: the push ends in Push Stop from
## the step he is on, the load rolling on with his last steps, and then he stands and lets go of
## the handle.
func _check_breakaway(stack: Node3D, before: Vector2) -> void:
	var now := Vector2(stack.global_position.x, stack.global_position.z)
	var clips: Array = _clips.get("breakaway", [])
	var off: float = _pose.get("off_loop", -INF)
	_check("PushStop" in clips and not "Walk" in clips and now.distance_to(_released_at) > 0.02
		and now.distance_to(before) < 1.2 and _slip("breakaway") <= SLIP and off >= OFF_LOOP
		and str(_player.current_animation) == "Idle",
		("H2: W let go while he leans in to get it going (%s), the push ends in Push Stop from "
		+ "the step he is on, the load rolling on %.2f m, his planted feet slipping at most %.3f "
		+ "m/s; then he stands (%s) and lets go of the handle (his hands %.2f m off it)")
		% [str(clips), now.distance_to(_released_at), _slip("breakaway"),
		_player.current_animation, off])


## Ethan's skeleton and clips, and the jack, watched from here on as his skeleton is posed.
func _track() -> void:
	_skeleton = _driver.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	_player = _driver.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	_jack = _shed.find_child("PalletJack", true, false) as Node3D
	_tiller = _jack.get_node_or_null("Steering/Tiller") as Node3D
	for name: String in ["mixamorig_LeftToeBase", "mixamorig_RightToeBase",
			"mixamorig_LeftHand", "mixamorig_RightHand", "mixamorig_LeftHandMiddle1",
			"mixamorig_RightHandMiddle1", "mixamorig_LeftArm", "mixamorig_RightArm",
			"mixamorig_HeadTop_End", "mixamorig_Neck", "mixamorig_Hips", "mixamorig_LeftFoot",
			"mixamorig_RightFoot", "mixamorig_LeftUpLeg", "mixamorig_RightUpLeg"]:
		_bones[name] = _skeleton.find_bone(name)
	for part: Array in BODY:
		for joint: String in [part[0], part[1]]:
			_bones["mixamorig_" + joint] = _skeleton.find_bone("mixamorig_" + joint)
	for side: String in ["Left", "Right"]:
		for finger: String in FINGERS:
			var tip := "mixamorig_%sHand%s4" % [side, finger]
			_bones[tip] = _skeleton.find_bone(tip)
	_skeleton.skeleton_updated.connect(_on_pose)


## Ethan just posed, his hands' reach to the handle included: how fast his toes slip across the
## floor while down and his feet carry him, how far his palms are from the handle's loop, and how
## high his head is in the van, outside the first frames of each clip and its blend, which runs
## at the clip's own pace, so slowly as a push gets going, and while steering.
func _on_pose() -> void:
	_watch_post()
	if _jack == null or not _jack_held():
		_last_feet.clear()
	if _jack != null and _jack_held():
		var where := _segment if _segment != "" else "taking it"
		var nearest := _tiller_clear()
		if nearest.x < (_body_clear.get(where, Vector2(INF, 0.0)) as Vector2).x:
			_body_clear[where] = nearest
		_watch_feet()
		if _segment in ["dock", "van"] and _since_clip > SETTLED and _segment == _clip_segment:
			_tips_off[_segment] = maxf(_tips_off.get(_segment, 0.0), _tips_from_loop())
	if _segment == "" or _jack == null:
		return
	var clip := str(_player.current_animation)
	if clip != _last_clip or _segment != _clip_segment:
		_last_clip = clip
		_clip_segment = _segment
		_since_clip = 0
		_clip_since = 0.0
	_since_clip += 1
	_clip_since += absf(_player.speed_scale) / 60.0
	var seen: Array = _clips.get(_segment, [])
	if not clip in seen:
		seen.append(clip)
	_clips[_segment] = seen
	var settled := _since_clip > SETTLED and _clip_since > SETTLED_CLIP \
		and _since_steer > STEER_SETTLED
	var floor_y := _driver.global_position.y
	var toes_up := -INF
	var frame := 1.0 + _player.current_animation_position * 30.0
	var walking := (clip == "Push" and not is_zero_approx(_player.speed_scale)) \
		or (clip == "PushStop" and frame < STOP_PLANTED) or clip == "WalkBack" or clip == "Walk"
	for index in range(2):
		var toe := _bone_at(["mixamorig_LeftToeBase", "mixamorig_RightToeBase"][index])
		toes_up = maxf(toes_up, toe.y - floor_y)
		if settled and walking and toe.y - floor_y < TOE_DOWN \
				and _toes_before[index] != Vector3.INF:
			var slips: Array = _slips.get(_segment, [])
			slips.append(_flat(toe - _toes_before[index]).length() * 60.0)
			_slips[_segment] = slips
		_toes_before[index] = toe
	var gap := _loop_gap()
	_pose["loop_gap"] = gap
	_pose["off_loop"] = _loop_nearest()
	_pose["toes_up"] = toes_up
	if settled and (clip == "Push" or clip == "Walk" or clip == "WalkBack"
			or (clip == "PushStop" and frame < HANDS_LET_GO)):
		_hand_gap[_segment] = maxf(_hand_gap.get(_segment, 0.0), gap)
	var palms := maxf(_bone_at("mixamorig_LeftHandMiddle1").y,
		_bone_at("mixamorig_RightHandMiddle1").y)
	_pose["head_clear"] = _bone_at("mixamorig_HeadTop_End").y - palms
	var moving := not is_zero_approx(_player.speed_scale)
	var tilt := rad_to_deg(_tiller.rotation.x) if _tiller != null else 0.0
	if settled and moving and clip == "Push" and _driver.get("stooping"):
		_head_clear["van"] = minf(_head_clear.get("van", INF), _pose["head_clear"])
		_tilt["van"] = _widen(_tilt.get("van", Vector2(INF, -INF)), tilt)
	if settled and moving and clip == "Walk" and _paces.get("now", 0.0) > 0.5:
		_tilt[_segment] = _widen(_tilt.get(_segment, Vector2(INF, -INF)), tilt)
		var forward := -_jack.global_basis.z
		forward = Vector3(forward.x, 0.0, forward.z).normalized()
		var spine := _bone_at("mixamorig_Neck") - _bone_at("mixamorig_Hips")
		_lean[_segment] = maxf(_lean.get(_segment, -INF), rad_to_deg(atan2(spine.dot(forward),
			spine.y)))
	if _segment == "pull" and _van.to_local(_driver.global_position).z > VAN_REAR + 0.5 \
			and not clip in _pull_outside:
		_pull_outside.append(clip)
	var head := _van.to_local(_bone_at("mixamorig_HeadTop_End"))
	_pose["head_up"] = head.y - HOLD_FLOOR.y
	if absf(head.x) < 0.9 and head.z < VAN_REAR - 0.1:
		_head_roof = maxf(_head_roof, head.y - HOLD_FLOOR.y)
	elif absf(head.x) < 0.9 and absf(head.z - VAN_REAR) <= 0.1:
		_head_door = maxf(_head_door, head.y - SILL.y)


## How far the handle's rod and loop are outside Ethan's body at the nearest, and which of
## `BODY`'s parts that is (its index): below 0, the handle is inside him.
## Each ankle's distance across the floor from its own hip, and how far it moved since his last
## pose, while he holds the jack (H21), in the world, where a step's glide keeps his feet still as
## his body steps up; counted afresh from each take, which sets him behind its handle.
func _watch_feet() -> void:
	var feet: Array[Vector3] = []
	for side: String in ["Left", "Right"]:
		var ankle := _bone_at("mixamorig_%sFoot" % side)
		var hip := _bone_at("mixamorig_%sUpLeg" % side)
		_feet_off = maxf(_feet_off, _flat(ankle - hip).length())
		feet.append(ankle)
	var mid := (_bone_at("mixamorig_LeftUpLeg") + _bone_at("mixamorig_RightUpLeg")) / 2.0
	var left := _flat(_bone_at("mixamorig_LeftUpLeg") - _bone_at("mixamorig_RightUpLeg")) \
		.normalized()
	if _segment in ["dock", "van", "pull"]:
		var least := minf((feet[0] - mid).dot(left), -(feet[1] - mid).dot(left))
		_own_side[_segment] = minf(_own_side.get(_segment, INF), least)
	if _last_feet.size() == 2:
		for side in range(2):
			_feet_jump = maxf(_feet_jump, feet[side].distance_to(_last_feet[side]))
	_last_feet = feet


func _tiller_clear() -> Vector2:
	var hand: Node3D = _tiller if _tiller != null else _jack
	var nearest := Vector2(INF, -1.0)
	for index in range(BODY.size()):
		var part: Array = BODY[index]
		var a := _bone_at("mixamorig_" + part[0])
		var b := _bone_at("mixamorig_" + part[1])
		for piece in TILLER_PIECES:
			var points := Geometry3D.get_closest_points_between_segments(
				hand.to_global(TILLER[piece.x]), hand.to_global(TILLER[piece.y]), a, b)
			var gap: float = points[0].distance_to(points[1]) - ROD - float(part[2])
			if gap < nearest.x:
				nearest = Vector2(gap, index)
	return nearest


## How far the load on the jack and Ethan stay outside the lift's pendant post, at the nearest.
func _watch_post() -> void:
	var post := _shed.find_child("LiftPendantPost", true, false) as Node3D
	var load := _shed.get_node_or_null("Building/Pallet6") as Node3D
	if post == null or load == null:
		return
	var axis := Vector2(post.global_position.x, post.global_position.z)
	var local := load.to_local(post.global_position)
	var inside := Vector2(clampf(local.x, -LOAD_WIDE, LOAD_WIDE),
		clampf(local.z, -LOAD_HALF, LOAD_HALF))
	var level := absf(load.global_position.y - post.global_position.y) < 1.2
	if level:
		_post_clear.x = minf(_post_clear.x, Vector2(local.x, local.z).distance_to(inside)
			- POST_RADIUS)
	if _jack != null and absf(_jack.global_position.y - post.global_position.y) < 1.2:
		var on := _jack.to_local(post.global_position)
		var forks := Vector2(clampf(on.x, -FORKS_HALF.x, FORKS_HALF.x),
			clampf(on.z, -FORKS_HALF.y, FORKS_BACK))
		_post_clear.z = minf(_post_clear.z, Vector2(on.x, on.z).distance_to(forks) - POST_RADIUS)
	if absf(_driver.global_position.y - post.global_position.y) < 1.2:
		_post_clear.y = minf(_post_clear.y, axis.distance_to(Vector2(_driver.global_position.x,
			_driver.global_position.z)) - POST_RADIUS - ETHAN_RADIUS)


## How far the farthest of his fingertips is from the handle's loop: wrapped round it, each is
## on the loop's tube; open, they stand out beyond it.
func _tips_from_loop() -> float:
	var hand: Node3D = _tiller if _tiller != null else _jack
	var farthest := 0.0
	for side: String in ["Left", "Right"]:
		for finger: String in FINGERS:
			var tip := _bone_at("mixamorig_%sHand%s4" % [side, finger])
			var nearest := INF
			for piece in TILLER_PIECES.slice(1):
				nearest = minf(nearest, tip.distance_to(Geometry3D.get_closest_point_to_segment(
					tip, hand.to_global(TILLER[piece.x]), hand.to_global(TILLER[piece.y]))))
			farthest = maxf(farthest, nearest)
	return farthest


func _widen(span: Vector2, value: float) -> Vector2:
	return Vector2(minf(span.x, value), maxf(span.y, value))


func _bone_at(name: String) -> Vector3:
	return _skeleton.global_transform * _skeleton.get_bone_global_pose(_bones[name]).origin


## How far each palm, between its wrist and its knuckles, is from its own side of the handle's
## loop, in the handle's own frame as it tilts and turns, his left hand being the one on his left
## shoulder's side.
func _hand_gaps() -> Array[float]:
	var into := (_tiller if _tiller != null else _jack).global_transform.affine_inverse()
	var across := into.basis * (_bone_at("mixamorig_LeftArm") - _bone_at("mixamorig_RightArm"))
	var gaps: Array[float] = []
	for index in range(2):
		var hand: String = ["Left", "Right"][index]
		var at := into * ((_bone_at("mixamorig_%sHand" % hand)
			+ _bone_at("mixamorig_%sHandMiddle1" % hand)) / 2.0)
		var side := signf(across.x) * (1.0 if index == 0 else -1.0)
		var bar := Vector3(side * LOOP_X, clampf(at.y, LOOP_Y.x, LOOP_Y.y), LOOP_Z)
		gaps.append(at.distance_to(bar))
	return gaps


## How far his hands are from holding the loop: each palm's centre is 3 cm off its bar, the bar
## lying just under the palm as his fingers close round it, not through his hand.
func _loop_gap() -> float:
	var gaps := _hand_gaps()
	return maxf(absf(gaps[0] - UNDER_PALM), absf(gaps[1] - UNDER_PALM))


func _loop_nearest() -> float:
	var gaps := _hand_gaps()
	return minf(gaps[0], gaps[1])


## How fast Ethan's toes slipped across the floor while down in a segment, his feet carrying
## him: the slowest quarter's, so his steps' own toe-offs, landings and shuffles do not count,
## where at a wrong pace every planted foot would slide.
func _slip(segment: String) -> float:
	var slips: Array = _slips.get(segment, [])
	if slips.is_empty():
		return INF
	var sorted := slips.duplicate()
	sorted.sort()
	return sorted[sorted.size() / 4]


## How far forward (world z) the load's leading corner reaches.
func _front_of(stack: Node3D) -> float:
	var front := -INF
	for x: float in [-0.535, 0.535]:
		for z: float in [-LOAD_HALF, LOAD_HALF]:
			front = maxf(front, stack.to_global(Vector3(x, 0.0, z)).z)
	return front


func _jack_held() -> bool:
	var rig: Node = _shed.get("pallet_jack")
	return rig != null and bool(rig.get("held"))


## Pushes the held jack with W, steering it with A and D as it rolls, until its load's centre is
## at `goal` or past it along z, heading for a point `lead` metres ahead on the line to it, as a
## driver lines a pallet up with a doorway. Since the audit's third fix (#326) A and D swing the
## jack's steering unit up to 105 degrees and let go it eases back straight, so, as a driver
## does, it swings the handle a little toward the heading it wants, in proportion to how far
## off it is (STEER_GAIN, at most STEER_MOST) and easing off as that closes (STEER_EASE, for the
## handle's way back), tapping A or D to hold it there; before, any error held a key, which
## turned the old jack only as it rolled.
func _push_to(goal: Vector2, limit: float, lead := INF) -> void:
	var rig: Node = _shed.get("pallet_jack")
	var time := 0.0
	var still := 0.0
	var last := Vector2.INF
	var from := _jack.global_position if _jack != null else Vector3.ZERO
	var frames := 0
	var last_turn := INF
	_trail.clear()
	while time < limit and still < 1.0 and rig != null:
		var centre: Vector2 = rig.call("load_centre")
		var ahead: Vector2 = rig.call("heading")
		if (goal - centre).length() < 0.05 or centre.y >= goal.y:
			break
		var to := Vector2(goal.x, minf(centre.y + lead, goal.y)) - centre
		var turn := ahead.angle_to(to)
		var closing := (turn - last_turn) * 60.0 if last_turn != INF else 0.0
		last_turn = turn
		var want := clampf(turn * STEER_GAIN + closing * STEER_EASE, -STEER_MOST, STEER_MOST) \
			if absf(turn) > 0.03 else 0.0
		var swung := (_jack.get_node("Steering") as Node3D).rotation.y if _jack != null else 0.0
		_press("steer_left", swung > want + STEER_HOLD)
		_press("steer_right", want != 0.0 and swung < want - STEER_HOLD)
		_since_steer = 0 if absf(turn) > 0.03 else _since_steer + 1
		Input.action_press("accelerate")
		await physics_frame
		_observe()
		frames += 1
		if frames == roundi(START_SECONDS * 60.0) and _jack != null:
			_starts.append(_flat(_jack.global_position - from).length())
		time += 1.0 / 60.0
		still = still + 1.0 / 60.0 if centre.distance_to(last) < 0.001 else 0.0
		last = centre
	for action: String in ["steer_left", "steer_right", "accelerate"]:
		Input.action_release(action)
	_since_steer = STEER_SETTLED + 1
	if rig != null:
		_released_at = rig.call("load_centre")
	await _seconds(0.3)


## While watching, what Ethan's feet, capsule and clip do as he follows the jack into the van;
## in each segment, the jack's pace, his clips and his reach behind it.
func _observe() -> void:
	if _segment != "" and _jack != null:
		_trail.append(Vector2(_jack.global_position.x, _jack.global_position.z))
		if _trail.size() > 15:
			_trail.pop_front()
			var pace := (_trail[-1] - _trail[0]).length() / (14.0 / 60.0)
			_paces["now"] = pace
			var where := _segment
			if _segment == "van" and _van.to_local(_driver.global_position).z < VAN_REAR:
				where = "in the van"
			if _since_steer > STEER_SETTLED:
				_paces[where] = maxf(_paces.get(where, 0.0), pace)
		var clip := str(_player.current_animation)
		var ahead := -_jack.global_basis.z
		var behind := Vector2(ahead.x, ahead.z).normalized().dot(Vector2(
			_jack.global_position.x - _driver.global_position.x,
			_jack.global_position.z - _driver.global_position.z))
		if _segment == "van" and clip == "Push" and _player.speed_scale > 0.0 \
				and _since_clip > SETTLED:
			_reach = Vector2(minf(_reach.x, behind), maxf(_reach.y, behind))
		if _segment == "pull" and _van.to_local(_driver.global_position).z < VAN_REAR:
			_hauled = _hauled or (clip == "PullBack" and _player.speed_scale > 0.0)
			_pushed_back = _pushed_back or (clip == "Push" and _player.speed_scale < 0.0)
	if not _watching:
		return
	_lowest = minf(_lowest, _driver.global_position.y)
	_shortest = minf(_shortest, _height())
	var depth := _van.to_local(_driver.global_position).z
	_deepest = minf(_deepest, depth)
	var clip := str((_driver.find_children("*", "AnimationPlayer", true, false)[0]
		as AnimationPlayer).current_animation)
	var seen := _clips_inside if depth < SILL.z else _clips_outside
	if not clip in seen:
		seen.append(clip)


func _height() -> float:
	for found in _driver.get_children():
		if found is CollisionShape3D and (found as CollisionShape3D).shape is CapsuleShape3D:
			return ((found as CollisionShape3D).shape as CapsuleShape3D).height
	return INF


## Where the bridge plate's underside is at the world depth `z`, along its slope.
func _plate_underside_at(lift: Node3D, z: float) -> float:
	var plate := lift.find_child("BridgeLip", true, false) as Node3D if lift != null else null
	if plate == null:
		return INF
	var tip := _lip_tip(lift)
	var along := tip - plate.global_position
	if absf(along.z) < 0.001:
		return INF
	var t := (z - plate.global_position.z) / along.z
	return plate.global_position.y + along.y * t - LIP_THICK


## Pulls the held jack back with S for `metres` of Ethan's walk. Since the audit's third fix
## (#326) a jack set down a little askew in the narrow hold cannot straighten there, so, as a
## driver does, he steers it straight back along the van as he pulls: the same steering as
## `_push_to`, turned the other way, since backing turns the jack the other way.
func _pull_back(metres: float) -> void:
	var start := _driver.global_position
	var time := 0.0
	var last_turn := INF
	_trail.clear()
	Input.action_press("brake")
	while _flat(_driver.global_position - start).length() < metres and time < PULL_LIMIT:
		var rig: Node = _shed.get("pallet_jack")
		var ahead: Vector2 = rig.call("heading")
		var axis := _van.global_basis * Vector3.FORWARD
		var turn := ahead.angle_to(Vector2(axis.x, axis.z))
		var closing := (turn - last_turn) * 60.0 if last_turn != INF else 0.0
		last_turn = turn
		var want := -clampf(turn * STEER_GAIN + closing * STEER_EASE, -STEER_MOST, STEER_MOST) \
			if absf(turn) > 0.03 else 0.0
		var swung := (_jack.get_node("Steering") as Node3D).rotation.y if _jack != null else 0.0
		_press("steer_left", swung > want + STEER_HOLD)
		_press("steer_right", want != 0.0 and swung < want - STEER_HOLD)
		_since_steer = 0 if absf(turn) > 0.03 else _since_steer + 1
		await physics_frame
		_observe()
		time += 1.0 / 60.0
	for action: String in ["brake", "steer_left", "steer_right"]:
		Input.action_release(action)
	_since_steer = STEER_SETTLED + 1
	await _seconds(0.3)


func _press(action: String, held: bool) -> void:
	if held:
		Input.action_press(action)
	else:
		Input.action_release(action)


## The objective's title as it changes, while `_saying`.
func _say() -> void:
	if not _saying or _hud == null:
		return
	var now := (_hud.get("_objective") as Label).text
	if _said.is_empty() or _said[-1] != now:
		_said.append(now)


func _lip_tip(lift: Node3D) -> Vector3:
	var lip := lift.find_child("BridgeLipEdge", true, false) as Node3D if lift != null else null
	return lip.global_position if lip != null else Vector3(INF, INF, -INF)


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


## Up to the lift's pendant, as near as a man stands to work it, from the side he comes from.
func _to_the_pendant() -> void:
	var pendant: Vector3 = _shed.get_node("Building/DockLift9").call("pendant")
	var from := _flat(_driver.global_position - pendant)
	var spot := pendant + (from.normalized() if from.length() > 0.01 else Vector3.LEFT) * 0.35
	var time := 0.0
	Input.action_press("accelerate")
	while _flat(spot - _driver.global_position).length() > 0.08 and time < 4.0:
		_driver.call("look_toward", _flat(spot - _driver.global_position).normalized())
		await physics_frame
		time += 1.0 / 60.0
	Input.action_release("accelerate")
	await _seconds(0.4)


## Where Ethan stands to take the jack again: just behind its handle, wherever it was left.
func _behind_the_handle() -> Vector3:
	var rig: Node = _shed.get("pallet_jack")
	var grip: Vector3 = rig.call("handle")
	var ahead: Vector2 = rig.call("heading")
	return Vector3(grip.x - ahead.x * BEHIND_THE_HANDLE, 0.0, grip.z - ahead.y * BEHIND_THE_HANDLE)


func _flat(value: Vector3) -> Vector3:
	return Vector3(value.x, 0.0, value.z)


## E held for `seconds` and let go, as a hand on a hold-to-run button.
func _hold_key(code: Key, seconds: float) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	await _seconds(seconds)
	var up := InputEventKey.new()
	up.keycode = code
	up.physical_keycode = code
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame
	await process_frame


## A dock lift moves only while its button is held (ANSI MH29.1's press-and-hold controls, as
## Pentalift's two-button pendant): a short press moves it a little and it stops when let go,
## the hint then offering to carry on; its pendant has UP, DOWN and a red emergency stop, and it
## beeps while it moves and only then (H15, H16); it stops when he walks away (H17).
func _check_hold_to_run() -> void:
	var lift := _shed.get_node_or_null("Building/DockLift9") as Node3D
	await _check_walk_away(lift)
	var top := lift.global_position.y
	await _hold_key(KEY_E, HOLD_TAP)
	var after := lift.global_position.y
	await _seconds(1.0)
	var still := lift.global_position.y
	var offer := _hint()
	var beep := lift.find_child("LiftBeep", true, false) as AudioStreamPlayer3D
	var quiet := beep != null and not beep.playing
	var event := InputEventKey.new()
	event.keycode = KEY_E
	event.physical_keycode = KEY_E
	event.pressed = true
	Input.parse_input_event(event)
	await _seconds(1.5)
	var beeping := beep != null and beep.playing and beep.stream is AudioStreamWAV \
		and (beep.stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD
	var up := InputEventKey.new()
	up.keycode = KEY_E
	up.physical_keycode = KEY_E
	up.pressed = false
	Input.parse_input_event(up)
	await _seconds(0.3)
	var moved := top - after
	_check(moved > 0.01 and moved < 0.15 and absf(still - after) < 0.002
		and offer == "E  Hold to lower the lift", ("H15: held a moment, the lift moves %.3f m and "
		+ "stops when let go (%.4f m in the next second); the hint offers to carry on (%s)")
		% [moved, still - after, offer])
	var buttons := ["PendantUp", "PendantDown", "PendantStop"].filter(func(label: String) -> bool:
		return lift.find_child(label, true, false) != null)
	var box := lift.find_child("LiftPendant", true, false) as Node3D
	var face := 0.0
	if box != null and buttons.has("PendantUp"):
		var out := _flat((lift.find_child("PendantUp", true, false) as Node3D).global_position
			- box.global_position).normalized()
		face = out.dot(_flat(lift.global_position - box.global_position).normalized())
	_check(buttons.size() == 3 and face > 0.5 and beeping and quiet, ("H16: its pendant has UP, "
		+ "DOWN and a red emergency stop (%s), its buttons facing the deck he works it from (%.2f), "
		+ "and its beep loops on while it moves (%s), silent when still (%s)")
		% [buttons, face, beeping, quiet])


## A hand pallet jack lifts only as its handle is pumped (Dayton's, Strongway's and U-Line's
## pallet truck manuals: the lever at raise, the handle pumped up and down): taken, the pallet
## stays on the floor and W cannot roll it; each E is one stroke, the handle rocked down and back
## and the forks raised a step with the pump's knock; 3 to 7 strokes lift it clear (H18). Since
## the audit's third fix (#326) the forks rise 36 mm before they meet the pallet's deck, so the
## steps are the forks' and the pallet only rises with them once they meet it.
func _check_pumping(load: Node3D, floor_y: float) -> void:
	var tiller := _shed.find_child("Tiller", true, false) as Node3D
	var taken := load.global_position.y - floor_y
	var offer := _hint()
	var jack := _shed.find_child("PalletJack", true, false) as Node3D
	var stood := _flat(jack.global_position - _driver.global_position).length()
	var start := _flat(load.global_position)
	Input.action_press("accelerate")
	await _seconds(0.8)
	Input.action_release("accelerate")
	await _seconds(0.4)
	var dragged := _flat(load.global_position).distance_to(start)
	var steps: Array[float] = []
	var forks: Array[float] = []
	var arc := 0.0
	var knocked := 0
	var strokes := 0
	var pump := _shed.find_child("JackPump", true, false) as AudioStreamPlayer3D
	while _hint() == "E  Pump the handle" and strokes < 10:
		var rest := tiller.rotation.x if tiller != null else 0.0
		await _key(KEY_E)
		strokes += 1
		var played := false
		var time := 0.0
		while time < STROKE:
			if tiller != null:
				arc = maxf(arc, rad_to_deg(absf(tiller.rotation.x - rest)))
			played = played or (pump != null and pump.playing)
			await physics_frame
			time += 1.0 / 60.0
		knocked += 1 if played else 0
		steps.append(load.global_position.y - floor_y)
		var chassis := jack.get_node_or_null("Chassis") as Node3D
		forks.append(chassis.position.y if chassis != null else 0.0)
		await _seconds(HINT_REFRESH)
	var rising := true
	for index in range(1, steps.size()):
		rising = rising and forks[index] > forks[index - 1] + 0.002 \
			and steps[index] >= steps[index - 1] - 0.001
	await _seconds(STEPPED_IN)
	var after := _hint()
	var close := _flat(jack.global_position - _driver.global_position).length()
	_check(taken < 0.003 and offer == "E  Pump the handle" and dragged < 0.01
		and strokes >= PUMPS.x and strokes <= PUMPS.y and rising and arc >= PUMP_ARC
		and knocked == strokes and after == "E  Set the pallet down" and stood >= STOOD_BACK
		and close <= CLOSE_BEHIND,
		("H18: taken, the jack leaves the pallet on the floor (%.3f m) and the hint offers to "
		+ "pump it (%s), W not rolling it (%.3f m); standing back at arm's length (%.2f m behind "
		+ "its middle), %d strokes of E (3 to 7), each rocking the handle %.0f° and knocking "
		+ "(%d), raise its forks step by step, the pallet with them once they meet it %s;"
		+ " then, the lever back at neutral, the hint offers to set "
		+ "it down (%s) and he steps in to the handle (%.2f m)") % [taken, offer, dragged, stood,
		strokes, arc, knocked, str(steps), after, close])


## Pumped up again: E until the hint stops offering to pump.
func _pump() -> void:
	var strokes := 0
	while _hint() == "E  Pump the handle" and strokes < 10:
		await _key(KEY_E)
		await _seconds(STROKE + HINT_REFRESH)
		strokes += 1
	await _seconds(STEPPED_IN)


## E opens the jack's lowering valve: the pallet sinks slowly onto what is under it, the oil
## hissing back, not dropped at once; until it rests the hint offers nothing (H19).
func _check_lowering(load: Node3D, under: Node3D) -> void:
	var start := load.global_position.y - under.global_position.y
	await _key(KEY_E)
	await _seconds(SINKING)
	var midway := load.global_position.y - under.global_position.y
	var hiss := _shed.find_child("JackLower", true, false) as AudioStreamPlayer3D
	var hissing := hiss != null and hiss.playing
	var during := _hint()
	await _seconds(LOWERED - SINKING)
	var rested := load.global_position.y - under.global_position.y
	var after := _hint()
	_check(midway > 0.005 and midway < start - 0.003 and hissing and during.is_empty()
		and absf(rested) < 0.01 and after == "E  Let go of the jack",
		("H19: E opens the lowering valve: the pallet sinks slowly (%.3f m up, %.3f m after %.1f "
		+ "s), the oil hissing back (%s), no other offer meanwhile (%s), and rests (%.3f m) "
		+ "within %.1f s, then the hint offers to let go (%s)") % [start, midway, SINKING,
		hissing, during, rested, LOWERED, after])


## Strapping by hand (cargo securement guides: a ratchet strap hooked to a floor ring, thrown over
## the load, hooked to the ring opposite and ratcheted tight): the hold has lashing rings in its
## floor by each wall; for each of two straps the hint offers each step in turn, the hooks clack
## into their rings and each pull of the ratchet clicks; the load counts as strapped only after
## the last click, and then both straps run from a floor ring over its top to the ring opposite,
## drawn tight, each with its ratchet (H20).
func _check_strapping(load: Node3D) -> void:
	var rings := _van.find_children("FloorRing*", "Node3D", true, false)
	var by_walls := 0
	for node in rings:
		var at := _van.to_local((node as Node3D).global_position)
		if absf(absf(at.x) - RING_X) < 0.06 and absf(at.y - HOLD_FLOOR.y) < 0.02:
			by_walls += 1
	var offers: Array[String] = []
	var hooked := 0
	var clicked := 0
	var early := false
	var hook := _shed.find_child("StrapHook", true, false) as AudioStreamPlayer3D
	var click := _shed.find_child("RatchetClick", true, false) as AudioStreamPlayer3D
	var presses := 0
	while _hint().begins_with("E  ") and _hint() != "E  Let go of the jack" \
			and _hint() != "E  Pull the jack out first" and presses < STRAP_PRESSES_MOST:
		var offer := _hint().trim_prefix("E  ")
		offers.append(offer)
		await _key(KEY_E)
		presses += 1
		await process_frame
		hooked += 1 if offer.begins_with("Hook") and hook != null and hook.playing else 0
		clicked += 1 if offer.begins_with("Ratchet") and click != null and click.playing else 0
		await _seconds(STRAP_STEP)
		early = early or (load.has_meta("strapped") and presses < STRAP_ORDER.size() * 2)
	var straps := load.find_children("LoadStrap*", "Node3D", false, false)
	var anchored := 0
	var tight := 0
	var ratchets := 0
	var top := _load_top(load)
	for node in straps:
		var strap_node := node as Node3D
		for end: String in ["HookNear", "HookFar"]:
			var tip := strap_node.get_node_or_null(end) as Node3D
			for ring in rings:
				if tip != null and tip.global_position.distance_to(
						(ring as Node3D).global_position) < 0.05:
					anchored += 1
					break
		var over := strap_node.get_node_or_null("OverTop") as Node3D
		if over != null and absf(over.global_position.y - top) < 0.012 \
				and float(strap_node.get_meta("slack", 1.0)) < 0.001:
			tight += 1
		ratchets += 1 if strap_node.get_node_or_null("Ratchet") != null else 0
	var expected: Array[String] = []
	for index in range(2):
		expected.append_array(STRAP_ORDER)
	_check(by_walls >= 4 and offers == expected and hooked == 4 and clicked == 8 and not early
		and load.has_meta("strapped") and straps.size() == 2 and anchored == 4 and tight == 2
		and ratchets == 2,
		("H20: the hold has %d lashing rings in its floor by its walls; strapping by hand, the "
		+ "hint offers %s; the hooks clack into the rings (%d of 4) and each pull of the ratchet "
		+ "clicks (%d of 8); strapped only after the last click (%s early); then %d straps, "
		+ "their hooks in floor rings (%d of 4), drawn tight over the top (%d), each with its "
		+ "ratchet (%d)") % [by_walls, str(offers), hooked, clicked, early, straps.size(),
		anchored, tight, ratchets])


func _load_top(load: Node3D) -> float:
	var body := load.get_node("LoadBody/Shape") as CollisionShape3D
	return load.global_position.y + (body.shape as BoxShape3D).size.y + 0.1


## With E held, Ethan walks off the deck onto the dock floor: his hand leaves the pendant, so the
## lift stops where it is and falls silent, though the key is still down (H17). He walks back.
func _check_walk_away(lift: Node3D) -> void:
	var top := lift.global_position.y
	var event := InputEventKey.new()
	event.keycode = KEY_E
	event.physical_keycode = KEY_E
	event.pressed = true
	Input.parse_input_event(event)
	await _seconds(0.2)
	var started := top - lift.global_position.y
	await _walk(OFF_THE_DECK, 3.0)
	var left := lift.global_position.y
	await _seconds(1.0)
	var still := lift.global_position.y
	var beep := lift.find_child("LiftBeep", true, false) as AudioStreamPlayer3D
	var quiet := beep != null and not beep.playing
	var up := InputEventKey.new()
	up.keycode = KEY_E
	up.physical_keycode = KEY_E
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame
	var off := _driver.global_position.x - lift.global_position.x
	_check(started > 0.005 and absf(still - left) < 0.002 and top - still < 0.25 and quiet
		and off > DECK_HALF, ("H17: with E held Ethan starts the lift (%.3f m), then walks off its "
		+ "deck (%.2f m from its middle): it stops (%.4f m in the next second, %.3f m down) and "
		+ "falls silent (%s), E still held") % [started, off, still - left, top - still, quiet])
	await _walk([TO_THE_LIFT[TO_THE_LIFT.size() - 1]])


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
	_check(false, "The loading checks finish within 280 s")
	_finish()


func _finish() -> void:
	print("LOADING RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	_remove()
	quit(1 if _failures > 0 else 0)
