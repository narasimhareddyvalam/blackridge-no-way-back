extends SceneTree
## Step 3 of #253 (#263-#265, docs/PHASE_BRIEF.md): bay 9's dock worker at his station. In the
## running game on Mission 2's start save, read from the shed as it is built: his desk and chair
## on the dock floor in the corner east of bay 9's lift, along the edge rail, out of the way of
## the load's approach, the lift and the way to the dock stair; solid; the seal log and the pen
## cup on the desk; and the chair in sight through bay 9's doorway from where Ethan stands behind
## the van. Part 2: he sits at it (W7), and when bay 9's van's doors shut he stands, takes the
## seal log, walks down the dock stair and out by the side door to the doors, seals them with
## C-TPAT's view, verify, tug, twist (W8-W10) and comes back to sit (W11). The audit's fourth fix
## (#329, docs/PHASE_BRIEF.md): on the dock stair he takes a tread a step at the stair's cadence,
## his feet on the treads, his hand on the rail and the seal log in his other hand (W12, W13); he
## gets up to pace and slows to a stop, and turns on the spot rather than snapping round (W14,
## W15); the seal is in his hand until it is on the hasp and a pen is in his hand as he notes
## (W16); his scanner is dark until he aims it at the load's shipping label, a short red line,
## then a green flash with the beep (W17); and off the stair his feet stay on the floor (W18).
## His round is shown as a cutscene (W19, #333), and he goes out only with room behind the van
## (W20), opening the side door before he goes through it (W21) and never floating or dropping
## (W22); the van stands as play leaves it, pulled forward from the dock.
## His bones are read as they are posed, his legs' and arm's IK included. A headless run draws
## nothing, so the look is not checked here.

const START_SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const NOT_CAMERA_WALLS := 0xFFFFFFFF & ~8
const FLOOR := 1.3
const DESK_TOP := 0.788
const ON := 0.005
## Bay 9's lift's pit, the load's approach to it (test_loading.gd's H14), the edge rail's line and
## the way from the dock floor onto the dock stair's landing.
const PIT := Rect2(-48.665, 17.3, 1.83, 2.44)
const APPROACH := Rect2(-48.965, 14.3, 2.43, 3.0)
const RAIL_X := -44.76
const RAIL_CLEAR := 0.03
const WALL_Z := 19.75
const TO_THE_STAIR := 14.4
## Bay 9's load, staged on its jack (dock_staging.gd), and room to walk between it and the station.
const LOAD := Rect2(-47.708, 15.99, 1.016, 1.219)
const WALK_ROOM := 0.6
## Where Ethan's eyes and his camera are as he comes to the van's doors from behind it.
const SIGHTS: Array[Vector3] = [Vector3(-47.6, 1.7, 25.0), Vector3(-47.5, 1.75, 21.6),
	Vector3(-47.2, 2.3, 23.0)]

## Part 2: the worker at his desk and his round to seal bay 9's van (step 3 of #253).
const DOCKED := Vector3(-47.75, 0.1, 23.16)
## Where play leaves the van to be sealed (#333): pulled forward until the doors can shut, its
## rear 2.98 m from the bumpers (`the_wrong_cargo.gd`'s LOADED_AT); and too near for him, 1.0 m
## further on than docked.
const PULLED_FORWARD := Transform3D(Basis(Vector3.UP, PI), Vector3(-47.75, 0.1, 26.14))
const TOO_NEAR := Transform3D(Basis(Vector3.UP, PI), Vector3(-47.75, 0.1, 24.16))
const BUMPERS_Z := 20.0
const ROOM_SPARE := 0.5
const SHOTS: Array[String] = ["desk", "stair", "door", "apron", "doors", "paper", "doors", "seal"]
const HEIGHT_STEP := 0.05
## His hands on the hasp as the seal goes on (#336): from 0.5 s before it to 0.5 s after, his
## wrists within reach of it (a hand's length, 0.15 m), the seal in his hand at it.
const SEAL_AT := 3.1
const ON_HASP_FOR := 0.5
const ON_HASP := 0.15
const SEAL_IN_HAND := 0.15
## The pen's tip on the tick it draws, within a pen's width and its ink's (#337).
const PEN_ON_INK := 0.01
## Where a man writes on a clipboard held in his hand: before his lower chest, its page 1.0-1.25 m
## up and 0.2-0.4 m before him, his hand at the board's edge (his wrist within 0.18 m of its
## middle: half its 0.23 m width and a hand's breadth off its edge).
const BOARD_UP := Vector2(1.0, 1.25)
const BOARD_OUT := Vector2(0.2, 0.4)
const GRIP := 0.18
## Clear of the van, not through its doors: he turns from them to write (#337).
const CLEAR_OF_DOORS := 0.15
## His palm turned up under the board, within this of its face's turn.
const PALM_OFF := 15.0
## #338: his body's round on his walks, 0.25 m, from 5 cm over the floor to 1.55 m; what he may
## meet (floors, the stair and its rails, his desk and chair, which W23 watches) and the dock
## seal's pads, which nothing makes solid.
const BODY_ROUND := 0.25
const BODY_FROM := 0.4
const BODY_TO := 1.55
## And his legs below his knees, 0.12 m round from his ankles up (his body is not as wide at his
## shins as at his hips; his feet are W18's and W32's).
const LEGS_ROUND := 0.12
const LEGS_FROM := 0.08
const MAY_MEET: Array[String] = ["DockStair", "DockRails", "ChairBody", "DeskBody"]
const WALKS: Array[String] = ["out", "back"]
## The van's rear step, in its frame: its top and where it runs; the log may overhang its back by
## a hand's breadth (7 cm), and lies within 1 cm of its top and 3 degrees of level.
const STEP_TOP := 0.538
## The step's top runs from under the doors (z 2.72) to its rounded edge (2.97): the whole log on
## it, not over its edge (#341, the author saw it "on invisible block").
const STEP_FROM := Vector2(-0.9, 2.7)
const STEP_TO := Vector2(0.9, 2.97)
const LOG_HALF := Vector2(0.1143, 0.1683)
const ON_STEP := 0.01
const LEVEL := 3.0
const HANDS_OFF_LOG := 0.02
const CROUCHED := 0.3
## Checking, his right hand on the bolt seal most of the while (within 4 cm), tugging it out at
## least 5 mm and twisting it at least 20 degrees.
const ON_SEAL := 0.04
const ON_SEAL_MOST := 0.7
const TUG := 0.005
const TWIST := 20.0
## His tug and twist measured while his hand is settled on the seal (0.4-2.6 s into the check),
## not as it comes to it or as he lets it go.
const SETTLED := Vector2(0.4, 2.6)
## His wrists bent at most this far off his forearms; the pen's tip by his index fingertip, its
## shaft through the web of his thumb.
const WRIST_MOST := 60.0
## And his elbows at the hasp bent as a man's working at his chest are, never locked straight
## (180 degrees is straight).
const ELBOW_BENT := Vector2(70.0, 160.0)
const TIP_AT_FINGERS := 0.05
const SHAFT_IN_WEB := 0.035
## Walking, the log hung at his side from his hand by its edge, as a clipboard is carried (#341:
## the author found it held before him on his palm "weird and unrealistic"): its middle 0.45-0.9 m
## over his feet (his arm comes forward as he stops), and clear of his legs as they and his arm
## swing, his thigh and calf each 6 cm round; within 1.5 m of the stair's head or foot the
## stair's own checks hold.
const CARRY_UP := Vector2(0.45, 0.9)
const LEG_ROUND := 0.06
const NEAR_STAIR := 1.5
## No camera of the cutscene nearer him (or the seal) than this.
const NO_NEARER := 0.8
## Except over his shoulder on the paper, as near as this, clear of his head (0.1 m round).
const PAPER_NEAR := 0.25
const HEAD_RADIUS := 0.1
## Nor his body seen walking this near past the seal shot's lens.
const PAST_THE_LENS := 1.2
## His body's breadth about his middle, 0.2 m each way.
const BODY_WIDTH: Array[Vector3] = [Vector3.ZERO, Vector3(0.2, 0, 0), Vector3(-0.2, 0, 0),
	Vector3(0, 0, 0.2), Vector3(0, 0, -0.2)]
## Half his body's width at the hips, clear of his chair's footprint (0.66 x 0.69 m): walking, he
## never steps nearer it than this; standing up, Rocketbox's clip leaves him 0.17 m beside it,
## where he turns on the spot and walks away.
const CHAIR_CLEAR := 0.2
## The seal shot's 3 s, once he has walked 1 m from the hasp, then his camera handed back.
## The seal shot waits for him to walk 1.8 m clear of its lens (#338), then holds 3 s.
const HANDED_BACK := 7.0
const SIDE_DOOR_X := -40.5
const WALL_X := -40.0
const IN_DOORWAY := 0.2
const SEAT_TOP := 0.47
const SEAT_ABOVE := Vector2(0.03, 0.2)
const ON_SEAT := 0.15
const LANDING := Vector3(-44.2, 1.3, 12.4)
const STAIR_FOOT := Vector3(-44.2, 0.0, 15.5)
const SIDE_DOOR := Vector3(-41.2, 0.0, 17.5)
const PASSES := 0.6
## His round's time from the call to his seat: 60 s until the audit's fourth fix (#329), 90 s since
## he gets going and stops, turns on the spot and takes the stair at a stair's pace.
const ROUND := 90.0
const NUMBER := "SL483201"
## The audit's fourth fix: the stair's cadence (Di Giulio et al. 2019: about 76 steps a minute up,
## 117 down) as a step's time, a planted foot's height over its tread, the rail's top (its line
## from `dock_access.gd`'s posts) and how near his hand holds it, his pace's rise and fall, the
## fastest he turns standing, the scanner's aim and its flash.
const STEP_TIME := Vector2(0.45, 0.85)
const ON_TREAD := 0.03
const PLANTED := 0.15
const STILL_FRAMES := 4
## Off the flight, as he walks, his toes never below the floor he walks on (W18). (His standing up
## from the chair is Rocketbox's clip, whose left toe dips 0.16 m under the floor as he rises: a
## defect found here and left for later, not this rule's.)
const OFF_FLIGHT := 0.3
const UNDER_FLOOR := 0.03
const STAIR_RAIL_X := -43.65
const RAIL_TOP := 1.07
const RAIL_FROM := Vector2(0.0, 15.07)
const RAIL_TO := Vector2(1.3, 13.92)
const GRIP_ABOVE := 0.04
## Where the rail runs on beyond his reach both ways (it ends 0.1 m up the flight from its foot
## and turns at its top): his hand lets go as he comes to either end.
const RAIL_FROM_ALONG := 0.3
const ON_RAIL := 0.05
const WALK := 1.4
const GETTING_GOING := 0.4
const TURN_MOST := 360.0
const AIM := Vector2(0.3, 0.5)
const FLASH := Vector2(0.15, 0.3)
const ON_LABEL := 0.05
const DECK_MIDDLE := Vector3(-47.75, 1.3, 18.52)

var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _app: Node3D
var _parts_now := {}
var _stair := {}
var _ankle := 0.0
var _plants: Array = []
var _was_planted := [true, true]
var _last_feet: Array[Vector3] = [Vector3.INF, Vector3.INF]
var _tread_off := 0.0
var _rail_off := {}
var _log_hand := {}
var _watch := false
var _off_floor := 0.0
var _hasp_off := 0.0
var _hasp_left_off := 0.0
var _seal_off := INF
var _pen_off := 0.0
var _board_low := INF
var _board_high := -INF
var _board_near := INF
var _board_far := -INF
var _board_grip := 0.0
var _board_clear := INF
var _palm_up := INF
var _van_now: Node3D
var _met := {}
var _seal_meshes: Array[MeshInstance3D] = []
var _log_off_step := 0.0
var _log_tilt := 0.0
var _log_on_step_frames := 0
var _log_where := ""
var _hands_on_log := INF
var _hips_low := {}
var _hips_from := INF
var _on_seal_frames := 0
var _checking_frames := 0
var _tug := Vector2(INF, -INF)
var _twist := Vector2(INF, -INF)
var _wrist_most := {}
var _elbows := {}
var _tip_off := 0.0
var _shaft_off := 0.0
var _carry_frames := 0
var _log_sizes := {}
var _carry_off := 0
var _carry_at := ""
var _tick_most := 0.0
var _last_drawn := -1.0
var _left_reach := ""
var _off_floor_at := ""
var _tread_at := ""
var _still := [0, 0]
var _steepest_at := ""
var _rail_at := {}


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(300.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-dock-worker-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_store(START_SAVE)
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	await process_frame
	await physics_frame
	await physics_frame
	_check_station()
	_app.call("_resume")
	for frame in range(30):
		await physics_frame
	_check_seated("W7 at the start")
	await _check_round()
	await _check_scan()
	await _check_no_room()
	_finish()


func _check_station() -> void:
	var shed := _app.get_node("IndustrialLoop").get("transfer_shed") as Node3D
	var station := shed.get_node_or_null("Building/DockStation") as Node3D if shed != null \
		else null
	var desk := station.get_node_or_null("Desk") as Node3D if station != null else null
	var chair := station.get_node_or_null("Chair") as Node3D if station != null else null
	var log := station.get_node_or_null("SealLog") as Node3D if station != null else null
	var pens := station.get_node_or_null("PenCup") as Node3D if station != null else null
	var made := desk != null and chair != null and log != null and pens != null \
		and desk.scene_file_path.ends_with("metal_office_desk.gltf") \
		and chair.scene_file_path.ends_with("office_chair.glb") \
		and log.scene_file_path.ends_with("clipboard.gltf") \
		and pens.scene_file_path.ends_with("stationery_supplies.gltf")
	_check(made, ("W1: bay 9's dock station is Poly Haven's Metal Office Desk and Red Fox's "
		+ "office chair, with Poly Haven's Clipboard as the seal log and its Stationery "
		+ "Supplies' pen cup (%s)") % ("so" if made else "missing or other models"))
	if not made:
		return
	var desk_box := _box(desk)
	var chair_box := _box(chair)
	var standing := absf(desk_box.position.y - FLOOR) <= ON \
		and absf(chair_box.position.y - FLOOR) <= ON \
		and absf(_box(log).position.y - (FLOOR + DESK_TOP)) <= ON \
		and absf(_box(pens).position.y - (FLOOR + DESK_TOP)) <= ON
	_check(standing, ("W2: the desk and the chair stand on the dock floor (their feet %.3f and "
		+ "%.3f m up) and the seal log and pen cup on the desk's top (%.3f and %.3f m)") % [
		desk_box.position.y, chair_box.position.y, _box(log).position.y, _box(pens).position.y])
	var both := desk_box.merge(chair_box)
	var flat := Rect2(both.position.x, both.position.z, both.size.x, both.size.z)
	var room := minf(_apart(_flat(desk_box), LOAD), _apart(_flat(chair_box), LOAD))
	var clear := not flat.intersects(APPROACH.grow(0.05)) and not flat.intersects(PIT) \
		and both.end.x <= RAIL_X - RAIL_CLEAR and both.end.z <= WALL_Z - 0.02 \
		and both.position.z >= TO_THE_STAIR and room >= WALK_ROOM
	_check(clear, ("W3: the station keeps to its corner, clear of the load's approach to the "
		+ "lift, the lift's pit, the edge rail by %.2f m, the dock wall and the way to the stair, "
		+ "with room to walk between it and bay 9's staged load (%.2f m; it spans x %.2f to "
		+ "%.2f, z %.2f to %.2f)") % [RAIL_CLEAR, room, both.position.x,
		both.end.x, both.position.z, both.end.z])
	var to_lift := desk.global_basis.z.normalized().dot(Vector3.LEFT)
	var to_desk := chair.global_basis.z.normalized().dot(Vector3.RIGHT)
	var front := desk_box.position.x
	var gap := front - chair.global_position.x
	var centred := absf(chair.global_position.z - desk.global_position.z)
	_check(to_lift > 0.99 and to_desk > 0.99 and gap >= 0.25 and gap <= 0.45 and centred <= 0.05,
		("W4: the desk's drawers face the lift and the chair stands in its kneehole facing it, "
		+ "its column %.2f m out from the desk's front and %.2f m off its middle") % [gap,
		centred])
	var space := _app.get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var ball := SphereShape3D.new()
	ball.radius = 0.05
	query.shape = ball
	query.collision_mask = 1
	var solid := true
	for point: Vector3 in [desk.global_position + Vector3.UP * (DESK_TOP - 0.06),
			chair.global_position + Vector3.UP * 0.4]:
		query.transform = Transform3D(Basis.IDENTITY, point)
		solid = solid and not space.intersect_shape(query, 1).is_empty()
	_check(solid, "W5: the desk and the chair are solid, so nobody walks or pushes a load "
		+ "through them")
	var ray := PhysicsRayQueryParameters3D.new()
	ray.collision_mask = NOT_CAMERA_WALLS
	var hidden: Array[String] = []
	for sight in SIGHTS:
		ray.from = sight
		ray.to = chair.global_position + Vector3.UP * 0.75
		var hit := space.intersect_ray(ray)
		var seen := not hit.is_empty() and (hit["position"] as Vector3).distance_to(ray.to) < 0.4
		if not seen:
			hidden.append("%s (%s)" % [sight, "nothing" if hit.is_empty()
				else String((hit["collider"] as Node).name)])
	_check(hidden.is_empty(), ("W6: from where Ethan stands behind the van and comes to its "
		+ "doors, the chair's back is in sight through bay 9's doorway (hidden from %s)") % [
		", ".join(hidden) if not hidden.is_empty() else "none"])


## `box`'s footprint on the floor.
func _parts() -> Dictionary:
	var shed := _app.find_child("TransferShed", true, false)
	var worker := shed.find_child("DockWorker", true, false) as Node3D
	var station := shed.find_child("DockStation", true, false) as Node3D
	var model := worker.get_node("Model") as Node3D
	return {"shed": shed, "worker": worker, "station": station, "model": model,
		"player": model.find_children("*", "AnimationPlayer", true, false)[0],
		"skeleton": model.find_children("*", "Skeleton3D", true, false)[0],
		"chair": station.get("chair"), "log": station.get_node("SealLog")}


func _pelvis(parts: Dictionary) -> Vector3:
	var skeleton := parts["skeleton"] as Skeleton3D
	return (skeleton.global_transform * skeleton.get_bone_global_pose(
		skeleton.find_bone("Bip01 Pelvis"))).origin


func _check_seated(when: String) -> void:
	var parts := _parts()
	var worker := parts["worker"] as Node3D
	var chair := parts["chair"] as Node3D
	var pelvis := _pelvis(parts)
	var seat := chair.global_position + Vector3.UP * SEAT_TOP
	var above := pelvis.y - seat.y
	var across := Vector2(pelvis.x - seat.x, pelvis.z - seat.z).length()
	var facing := (parts["model"] as Node3D).global_basis.z.normalized().dot(Vector3.RIGHT)
	var clip := String((parts["player"] as AnimationPlayer).current_animation)
	var log_back := (parts["log"] as Node3D).is_visible_in_tree()
	_check(worker.visible and bool(worker.get("home")) and clip == "SitIdle"
		and above >= SEAT_ABOVE.x and above <= SEAT_ABOVE.y and across <= ON_SEAT
		and facing > 0.9 and log_back, "%s he sits at his desk: %s, his hips %.2f m over the " % [
		when, clip, above] + "seat and %.2f m from its middle, facing the desk (%.2f), the log on "
		% [across, facing] + "it %s" % log_back)


func _check_round() -> void:
	var parts := _parts()
	var worker := parts["worker"] as Node3D
	var player := parts["player"] as AnimationPlayer
	var van := _app.get_node("FreightVan") as Node3D
	van.call("recover", PULLED_FORWARD)
	van.set("rear_doors_open", false)
	for frame in range(10):
		await physics_frame
	_watch_stair(parts)
	_van_now = van
	_seal_meshes.clear()
	for found in _app.find_children("DockSeal*", "MeshInstance3D", true, false):
		_seal_meshes.append(found as MeshInstance3D)
	(parts["shed"] as Node).call("call_dock_hand", van, NUMBER)
	var model := parts["model"] as Node3D
	var last_at := worker.global_position
	var last_yaw := model.global_rotation.y
	var speeds: Array[float] = []
	var whats: Array[String] = []
	var fastest_turn := 0.0
	var snaps := 0
	var steepest := 0.0
	var seal_held := 0
	var seal_late := 0
	var cutscene := _app.get("seal_cutscene") as Node
	var cut_camera := cutscene.get("camera") as Camera3D
	var shown := 0
	var unseen := 0
	var unseen_at := ""
	var unseen_by := {}
	## The dock's rails stop people stepping off with walls nobody sees (`dock_access.gd`'s
	## `_wall_stop()`), only their thin bars drawn; a camera sees past them.
	var see_through: Array[RID] = []
	for found in (parts["shed"] as Node3D).find_children("DockRails", "CollisionObject3D", true,
			false):
		see_through.append((found as CollisionObject3D).get_rid())
	var back_at := -1.0
	var ended_at := -1.0
	var room := INF
	var side_door := (parts["shed"] as Node).get("side_door") as Node3D
	var door_least := INF
	var last_y := worker.global_position.y
	var jump := 0.0
	var chair_near := INF
	var last_to_chair := INF
	var chair_at := ""
	var jump_at := ""
	var notes := 0
	var penned := 0
	var clips: Array[String] = []
	var carried := false
	var landing := INF
	var foot := INF
	var door := INF
	var sealed_during := ""
	var entered := false
	var time := 0.0
	var home_at := -1.0
	while time < ROUND + 5.0:
		await physics_frame
		time += 1.0 / Engine.physics_ticks_per_second
		var clip := String(player.current_animation)
		if clips.is_empty() or clips[-1] != clip:
			clips.append(clip)
		var hand := worker.find_child("Clipboard", true, false) as Node3D
		if hand != null and hand.is_visible_in_tree() \
				and not (parts["log"] as Node3D).is_visible_in_tree():
			carried = true
		var at := worker.global_position
		_watch_way(worker, cut_camera, bool(cutscene.get("playing")))
		landing = minf(landing, at.distance_to(LANDING))
		foot = minf(foot, at.distance_to(STAIR_FOOT))
		door = minf(door, at.distance_to(SIDE_DOOR))
		if sealed_during.is_empty() and bool(van.get("sealed")):
			sealed_during = clip
		if bool(cutscene.get("playing")):
			shown += 1
			var chest := worker.global_position + Vector3.UP * 1.25
			var seal_node := van.find_child("BoltSeal", true, false) as Node3D
			var his_way := false
			if String(cutscene.get("shot")) == "paper":
				chest = worker.call("paper_point")
				var head: Vector3 = worker.call("head_point")
				var run := chest - cut_camera.global_position
				var t := clampf((head - cut_camera.global_position).dot(run) / run.length_squared(),
					0.0, 1.0)
				his_way = (cut_camera.global_position + run * t).distance_to(head) < HEAD_RADIUS
			if String(cutscene.get("shot")) == "seal":
				chest = seal_node.global_position if seal_node != null else Vector3.INF
				his_way = _in_the_way(cut_camera.global_position, chest, worker.global_position)
				for up: float in [0.3, 0.9, 1.4]:
					for side: Vector3 in BODY_WIDTH:
						var body := worker.global_position + Vector3.UP * up + side
						if cut_camera.is_position_in_frustum(body) \
								and body.distance_to(cut_camera.global_position) < PAST_THE_LENS:
							his_way = true
			var ray := PhysicsRayQueryParameters3D.create(cut_camera.global_position, chest, 1)
			ray.exclude = see_through
			var hit := worker.get_world_3d().direct_space_state.intersect_ray(ray)
			var blocked := not hit.is_empty() and (hit["position"] as Vector3).distance_to(chest) \
				> 0.3
			var point := PhysicsPointQueryParameters3D.new()
			point.position = cut_camera.global_position
			point.collision_mask = 1
			var around := worker.get_world_3d().direct_space_state.intersect_point(point, 1)
			if not around.is_empty():
				blocked = true
				hit = around[0]
			var too_close := cut_camera.global_position.distance_to(chest) < (PAPER_NEAR
				if String(cutscene.get("shot")) == "paper" else NO_NEARER)
			if worker.get_viewport().get_camera_3d() != cut_camera \
					or not cut_camera.is_position_in_frustum(chest) or blocked or his_way \
					or too_close:
				unseen += 1
				var why := "behind %s" % (hit["collider"] as Node).name if blocked else (
					"behind him" if his_way else "too close" if too_close else
					"out of view" if worker.get_viewport().get_camera_3d() == cut_camera
					else "not current")
				var key := "%s %s" % [cutscene.get("shot"), why]
				if not unseen_by.has(key):
					unseen_by[key] = [0, str(worker.global_position)]
				unseen_by[key][0] += 1
				unseen_at = str(unseen_by)
		if back_at < 0.0 and String(worker.get("state")) == "back":
			back_at = time
		if back_at >= 0.0 and ended_at < 0.0 and not bool(cutscene.get("playing")):
			ended_at = time
		if String(worker.get("state")) == "sealing":
			room = minf(room, worker.global_position.z - BUMPERS_Z)
		var rise := absf(worker.global_position.y - last_y)
		if rise > jump and String(worker.get("state")) not in ["seated", "standing", "sitting"]:
			jump = rise
			jump_at = "%s at %s" % [worker.get("state"), str(worker.global_position)]
		last_y = worker.global_position.y
		var chair_box := _flat(_box(parts["chair"] as Node3D))
		var at_flat := Vector2(worker.global_position.x, worker.global_position.z)
		var to_chair := at_flat.distance_to(at_flat.clamp(chair_box.position, chair_box.end))
		var nearer := to_chair < last_to_chair - 0.001
		last_to_chair = to_chair
		if String(worker.get("state")) in ["out", "back"] and nearer and to_chair < chair_near:
			chair_near = to_chair
			chair_at = "%s in %s at %s" % [worker.get("state"), player.current_animation,
				str(worker.global_position)]
		if absf(worker.global_position.x - WALL_X) < IN_DOORWAY:
			door_least = minf(door_least, float(side_door.call("swung")))
		var held_seal := worker.find_child("SealInHand", true, false) as Node3D
		if held_seal != null and held_seal.is_visible_in_tree():
			seal_held += 1 if not bool(van.get("sealed")) else 0
			seal_late += 1 if bool(van.get("sealed")) else 0
		if clip == "Note" and player.current_animation_position > 0.3:
			notes += 1
			var pen := worker.find_child("Pen", true, false) as Node3D
			penned += 1 if pen != null and pen.is_visible_in_tree() else 0
		var moved := Vector2(worker.global_position.x - last_at.x,
			worker.global_position.z - last_at.z).length() * Engine.physics_ticks_per_second
		last_at = worker.global_position
		speeds.append(moved)
		whats.append("%s in %s at %s" % [String(worker.get("state")), clip,
			str(worker.global_position)])
		var yaw := absf(rad_to_deg(wrapf(model.global_rotation.y - last_yaw, -PI, PI))) \
			* Engine.physics_ticks_per_second
		last_yaw = model.global_rotation.y
		snaps += 1 if yaw > 3.0 * TURN_MOST else 0
		if moved < 0.05:
			fastest_turn = maxf(fastest_turn, yaw)
		var inside := van.to_local(at + Vector3.UP * 0.9)
		entered = entered or (absf(inside.x) < 0.9 and absf(inside.z) < 2.4)
		if bool(worker.get("home")) and time > 2.0:
			home_at = time
			break
	_watch = false
	for frame in range(30):
		await physics_frame
	for index in range(6, speeds.size()):
		var change := absf(speeds[index] - speeds[index - 6]) * Engine.physics_ticks_per_second / 6.0
		if speeds.slice(index - 6, index + 1).max() < 3.0 * WALK and change > steepest:
			steepest = change
			_steepest_at = "%s; %s" % [whats[index], str(speeds.slice(index - 8, index + 3).map(
				func(v: float) -> String: return "%.2f" % v))]
	var order := ["StandUp", "Walk", "CrouchIn", "CrouchOut", "Note", "Walk", "SitDown"]
	var seen := []
	var next := 0
	for clip in clips:
		if next < order.size() and clip == order[next]:
			seen.append(clip)
			next += 1
	_check(not clips.is_empty() and clips[0] == "StandUp" and carried, "W8 sent to seal, he stands "
		+ "up from his desk and takes the seal log in his hand (%s, carried %s)" % [clips.slice(0, 3),
		carried])
	_check(landing < PASSES and foot < PASSES and door < PASSES and not entered,
		"W9 his way: over the dock floor to the stair's landing (%.2f m), down the stair " % landing
		+ "(%.2f m from its foot), out of the side door (%.2f m), never into the van" % [foot, door])
	_check(next == order.size() and sealed_during == "CrouchOut", ("W10 at the doors, view, "
		+ "verify, tug, twist (C-TPAT's VVTT), all from one place: the log laid on the step "
		+ "crouching, the seal put on half risen at the hasp's height (%s), checked, the log taken "
		+ "up crouching again, then his note (%s)")
		% [sealed_during, clips])
	_check(home_at > 0.0 and home_at <= ROUND, "W11 back at his desk within the doors' %.0f s "
		% ROUND + "(%.1f s)" % home_at)
	_check_stair()
	_check(steepest <= WALK / GETTING_GOING * 1.1, ("W14: he gets up to pace and slows to a stop "
		+ "over a step or two, never changing pace faster than %.1f m/s a second (at most %.1f, "
		+ "%s)") % [WALK / GETTING_GOING, steepest, _steepest_at])
	_check(snaps == 0 and fastest_turn <= TURN_MOST, ("W15: he turns on the spot, never snapping "
		+ "round (%d frames), at most %.0f° a second standing (360)") % [snaps, fastest_turn])
	var seen_shots: Array = cutscene.get("shots")
	_check(shown > 0 and unseen == 0 and seen_shots == SHOTS and ended_at >= back_at
		and ended_at - back_at <= HANDED_BACK and room >= ROOM_SPARE, ("W19: his round shown as "
		+ "it happens, the cameras cutting as he reaches each part, the bolt seal last (%s), each "
		+ "seeing him or it all the while (%d of %d frames not: %s), ending %.1f s after he turns "
		+ "back, and room "
		+ "behind the van as he seals (%.2f m to the bumpers)") % [str(seen_shots), unseen, shown,
		unseen_at, ended_at - back_at, room])
	_check(_hasp_off <= ON_HASP and _hasp_left_off <= ON_HASP and _seal_off <= SEAL_IN_HAND,
		("W24: as the seal goes on his hands are on the hasp, his right wrist %.3f m from it and "
		+ "his left %.3f m (a hand's length, 0.15), the seal in his hand %.3f m from it; %s")
		% [_hasp_off, _hasp_left_off, _seal_off, _left_reach])
	_check(chair_near >= CHAIR_CLEAR, ("W23: walking he never goes into his chair, never stepping "
		+ "nearer it than half his body's width (he "
		+ "pushes it in under the desk before he sets off and draws it out to sit): stepping "
		+ "nearer, at least %.2f m from its footprint (%.2f m at the nearest, %s)")
		% [CHAIR_CLEAR, chair_near, chair_at])
	_check(jump <= HEIGHT_STEP, ("W22: he never floats up or drops: his height changes at most "
		+ "5 cm a frame as he walks (%.3f m at most%s)") % [jump, (", " + jump_at) if jump_at
		else ""])
	_check(door_least >= 1.0, ("W21: the side door shut, he stops inside it and pushes it open, "
		+ "going through only once it has swung open (%.2f of the way at the least)") % door_least)
	_check(_off_floor <= UNDER_FLOOR, ("W18: off the stair, walking, his feet stay on the floor "
		+ "he walks on, his toes never more than 3 cm below it (%.3f m at most: %s)") % [_off_floor,
		_off_floor_at])
	_check(seal_held > 0 and seal_late <= 2 and notes > 0 and penned == notes, ("W16: the seal "
		+ "is in his hand until it is on the hasp (%d frames before, %d after), and a pen is in "
		+ "his hand all the time he notes (%d of %d frames)") % [seal_held, seal_late, penned,
		notes])
	for frame in range(int(Engine.physics_ticks_per_second * 4.5)):
		await physics_frame
	_check_seated("W11 back,")
	var desk_log := parts["log"] as Node3D
	var desk_page := desk_log.find_child("SealLogPage", true, false) as Node3D
	var on_desk := desk_page != null and (desk_page.get_node("TickStroke2") as Node3D).visible \
		and (desk_page.get_node("SealNumber") as Label3D).text == NUMBER \
		and (desk_page.get_node("SealedBy") as Label3D).text != ""
	var desk_size := desk_log.global_basis.get_scale().x
	_check(_log_sizes.size() == 2 and _log_sizes.values().all(func(v: Vector2) -> bool:
		return absf(v.x / desk_size - 1.0) < 0.02 and absf(v.y / desk_size - 1.0) < 0.02),
		("W26: the seal log in either of his hands is the size of the one on his desk all the "
		+ "while he carries it, hung by its edge or held before him (%s of %.3f), not shrunk by "
		+ "the model's skeleton (#337)") % [str(_log_sizes), desk_size])
	var held_up := _board_low >= BOARD_UP.x and _board_high <= BOARD_UP.y \
		and _board_near >= BOARD_OUT.x and _board_far <= BOARD_OUT.y and _board_grip <= GRIP \
		and _board_clear >= CLEAR_OF_DOORS and _palm_up >= cos(deg_to_rad(PALM_OFF))
	_check(_tick_most >= 2.0 and _pen_off <= PEN_ON_INK and on_desk and held_up, ("W25: noting, "
		+ "he holds the seal log up before his chest in his left hand (its page %.2f-%.2f m up and "
		+ "%.2f-%.2f m before him, %.2f m clear of the van's doors, his wrist %.3f m from the "
		+ "board's middle, his palm under it, %.0f degrees off its face at the most) and ticks "
		+ "its row for this van with his pen, the tick drawn stroke by stroke under the pen's tip"
		+ " (%.3f m from it at the most; %.1f of 2 strokes), and the log he "
		+ "puts back on his desk shows the row and its tick (%s)") % [_board_low, _board_high,
		_board_near, _board_far, _board_clear, _board_grip,
		rad_to_deg(acos(clampf(_palm_up, -1.0, 1.0))), _pen_off, _tick_most, on_desk])
	_check(_met.is_empty(), ("W27: on his walks his body (0.25 m round, his legs below his knees "
		+ "0.12 m) meets nothing solid but floors and the stair, nor the dock seal's pads (%s)")
		% [str(_met)])
	var hips_ok := _hips_low.size() == 2 and _hips_low.values().all(
		func(v: float) -> bool: return v >= CROUCHED)
	_check(_log_on_step_frames > 0 and _log_off_step <= ON_STEP and _log_tilt <= LEVEL
		and _log_where.is_empty() and _hands_on_log >= HANDS_OFF_LOG and hips_ok, ("W28: he "
		+ "crouches to lay the log on the van's rear step and to take it up (his hips %s m "
		+ "lower), and while he seals and checks it lies on the step, within %.3f m of its top "
		+ "and %.1f degrees of level%s, no hand nearer it than %.3f m (%d frames)") % [
		str(_hips_low), _log_off_step, _log_tilt, (", " + _log_where) if _log_where else "",
		_hands_on_log, _log_on_step_frames])
	_check(_checking_frames > 0 and float(_on_seal_frames) / _checking_frames >= ON_SEAL_MOST
		and _tug.y - _tug.x >= TUG and _twist.y - _twist.x >= TWIST, ("W29: checking the seal "
		+ "(view, verify, tug, twist), his right hand on it %d of %d frames, tugging it %.3f m "
		+ "out and twisting it %.0f degrees") % [_on_seal_frames, _checking_frames,
		_tug.y - _tug.x if _checking_frames > 0 else 0.0, _twist.y - _twist.x
		if _checking_frames > 0 else 0.0])
	var elbows_ok := _elbows.size() == 2 and _elbows.values().all(
		func(v: Vector2) -> bool: return v.x >= ELBOW_BENT.x and v.y <= ELBOW_BENT.y)
	_check(_wrist_most.size() == 3 and _wrist_most.values().all(
		func(v: float) -> bool: return v <= WRIST_MOST) and elbows_ok
		and _tip_off <= TIP_AT_FINGERS and _shaft_off <= SHAFT_IN_WEB, ("W30: his arms as a "
		+ "man's are: at the hasp his elbows bent %s degrees (70-160, never locked straight), his "
		+ "wrists at most 60 degrees off his forearms (%s); the pen held in his fingers, its tip "
		+ "%.3f m from his index fingertip and its shaft %.3f m from the web of his thumb") % [
		str(_elbows), str(_wrist_most), _tip_off, _shaft_off])
	_check(_carry_frames > 0 and _carry_off == 0, ("W31: walking on the level he carries the "
		+ "log hung at his side from his hand by its edge, clear of his legs (%d of %d frames "
		+ "not%s)") % [
		_carry_off, _carry_frames, (", " + _carry_at) if _carry_at else ""])


## Watches his feet, hands and log as he is posed, his IK included: each foot planted on the dock
## stair's flight, the tread under it and when; the rail-side hand's reach to the rail; and which
## hand holds the log, going down and coming up.
func _watch_stair(parts: Dictionary) -> void:
	_parts_now = parts
	_stair = (parts["shed"] as Node).get("side_door").call("stair")
	var skeleton := parts["skeleton"] as Skeleton3D
	var rest := skeleton.global_transform * skeleton.get_bone_global_rest(
		skeleton.find_bone("Bip01 L Foot")).origin
	_ankle = rest.y - (parts["model"] as Node3D).global_position.y
	_watch = true
	skeleton.skeleton_updated.connect(_on_pose)


func _on_pose() -> void:
	if not _watch:
		return
	var worker := _parts_now["worker"] as Node3D
	var along := _along(worker.global_position)
	var flight := _flight_run()
	_watch_hands(worker)
	if String(worker.get("state")) == "noting":
		var drawn := float(worker.call("tick_drawn"))
		if drawn > 0.02 and drawn < 1.98 and drawn != _last_drawn:
			_pen_off = maxf(_pen_off, (worker.call("pen_tip") as Vector3).distance_to(
				worker.call("tick_point")))
			var page: Vector3 = worker.call("paper_point")
			var ahead := (_parts_now["model"] as Node3D).global_basis.z
			ahead = Vector3(ahead.x, 0.0, ahead.z).normalized()
			var board := worker.find_child("Clipboard", true, false) as Node3D
			var skeleton := worker.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
			var left_hand := skeleton.global_transform * skeleton.get_bone_global_pose(
				skeleton.find_bone("Bip01 L Hand"))
			var left := left_hand.origin
			_palm_up = minf(_palm_up, left_hand.basis.y.normalized().dot(
				board.global_basis.y.normalized()))
			var up := page.y - worker.global_position.y
			var out := (page - worker.global_position).dot(ahead)
			_board_low = minf(_board_low, up)
			_board_high = maxf(_board_high, up)
			_board_near = minf(_board_near, out)
			_board_far = maxf(_board_far, out)
			_board_grip = maxf(_board_grip, left.distance_to(board.global_position))
			var van := _van_now
			_board_clear = minf(_board_clear, (page - (van.call("seal_point") as Vector3)).dot(
				van.global_basis.z.normalized()))
		_last_drawn = drawn
		_tick_most = maxf(_tick_most, drawn)
	if String(worker.get("state")) == "sealing":
		var timer := float(worker.get("_timer"))
		var van := _app.get_node("FreightVan") as Node3D
		var hasp: Vector3 = van.call("seal_point")
		if absf(timer - SEAL_AT) <= ON_HASP_FOR:
			_hasp_off = maxf(_hasp_off, _bone("Bip01 R Hand").distance_to(hasp))
			_hasp_left_off = maxf(_hasp_left_off, _bone("Bip01 L Hand").distance_to(hasp))
			var aim := (_parts_now["model"] as Node3D).find_child("SealHandLTarget", true, false) \
				as Node3D
			if aim != null:
				_left_reach = "left shoulder %.3f m from its aim, the aim %.3f m from his left hand" \
					% [_bone("Bip01 L UpperArm").distance_to(aim.global_position),
					_bone("Bip01 L Hand").distance_to(aim.global_position)]
		if timer < SEAL_AT and timer > SEAL_AT - 0.1:
			var held := worker.find_child("SealInHand", true, false) as Node3D
			_seal_off = held.global_position.distance_to(hasp) if held != null else INF
	if _aside(worker.global_position) > float(_stair["width"]) / 2.0 + OFF_FLIGHT \
			and String(worker.get("state")) in ["out", "back", "to_scan"]:
		for toe: String in ["Bip01 L Toe0", "Bip01 R Toe0"]:
			var at := _bone(toe)
			if _floor_under(at) - at.y > _off_floor:
				_off_floor = _floor_under(at) - at.y
				var hit := _floor_hit(at)
				_off_floor_at = "%s toe at %s, %s, on %s" % [toe, str(at), String(worker.get(
					"state")), String(hit.get("collider").name) if not hit.is_empty() else "-"]
	if _aside(worker.global_position) > float(_stair["width"]) / 2.0:
		return
	var going := "down" if String(worker.get("state")) == "out" else "up"
	for side in range(2):
		var foot := _bone(["Bip01 L Foot", "Bip01 R Foot"][side])
		var at := _along(foot)
		var speed := foot.distance_to(_last_feet[side]) * Engine.physics_ticks_per_second \
			if _last_feet[side] != Vector3.INF else 0.0
		_last_feet[side] = foot
		_still[side] = _still[side] + 1 if speed < PLANTED else 0
		var planted: bool = _still[side] >= STILL_FRAMES
		if at > 0.02 and at < flight - 0.02 and along > -0.3 and along < flight + 0.3:
			var tread := ceili(at / float(_stair["tread"]))
			var top := tread * float(_stair["rise"])
			if planted and absf(foot.y - _ankle - top) > _tread_off:
				_tread_off = absf(foot.y - _ankle - top)
				var aim := (_parts_now["model"] as Node3D).find_child("StairFeet%sTarget" % [
					"L", "R"][side], true, false) as Node3D
				_tread_at = "%s foot %d at %.2f along, tread %d, body at %.2f, %.3f m off its IK's aim" \
					% [going, side, at, tread, along, foot.distance_to(aim.global_position) if aim
					else INF]
			if planted and not _was_planted[side]:
				_plants.append([Time.get_ticks_msec() / 1000.0, side, tread, going,
					Engine.get_physics_frames()])
		_was_planted[side] = planted
	if along > RAIL_FROM_ALONG and along < flight - RAIL_FROM_ALONG:
		var hand := _bone("Bip01 L Hand" if going == "down" else "Bip01 R Hand")
		var t := clampf((RAIL_FROM.y - hand.z) / (RAIL_FROM.y - RAIL_TO.y), 0.0, 1.0)
		var rail := Vector3(STAIR_RAIL_X, lerpf(RAIL_FROM.x, RAIL_TO.x, t) + RAIL_TOP + GRIP_ABOVE,
			hand.z)
		if hand.distance_to(rail) > _rail_off.get(going, 0.0):
			_rail_off[going] = hand.distance_to(rail)
			var aim := (_parts_now["model"] as Node3D).find_child("RailHand%s%sTarget" % [
				"L" if going == "down" else "R", "L" if going == "down" else "R"], true, false) \
				as Node3D
			_rail_at[going] = "%.2f along, %.3f m off its IK's aim at %s" % [along,
				hand.distance_to(aim.global_position) if aim else INF, str(aim.global_position
				if aim else Vector3.INF)]
		var right := worker.find_child("ClipboardRight", true, false) as Node3D
		var left := worker.find_child("Clipboard", true, false) as Node3D
		var in_right := right != null and right.is_visible_in_tree()
		var in_left := left != null and left.is_visible_in_tree()
		var wanted := in_right and not in_left if going == "down" else in_left and not in_right
		_log_hand[going] = _log_hand.get(going, true) and wanted


func _flight_run() -> float:
	return float(_stair["tread"]) * (int(_stair["risers"]) - 1)


## The floor's height under `at`, from just above it (so not a desk over his feet), solid things he
## walks on only (layer 1).
func _floor_under(at: Vector3) -> float:
	var hit := _floor_hit(at)
	return (hit["position"] as Vector3).y if not hit.is_empty() else at.y


func _floor_hit(at: Vector3) -> Dictionary:
	var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.2, at + Vector3.DOWN * 1.0, 1)
	return (_parts_now["worker"] as Node3D).get_world_3d().direct_space_state.intersect_ray(ray)


## How far `at` is to one side of the flight's middle.
func _aside(at: Vector3) -> float:
	var across := _stair["across"] as Vector3
	var from := _stair["foot"] as Vector3
	return absf(Vector2(at.x - from.x, at.z - from.z).dot(Vector2(across.x, across.z)))


func _along(at: Vector3) -> float:
	var up := _stair["up"] as Vector3
	var from := _stair["foot"] as Vector3
	return Vector2(at.x - from.x, at.z - from.z).dot(Vector2(up.x, up.z))


## W27, W31: each tick of his walks, what his body meets, and the log he carries on the level.
func _watch_way(worker: Node3D, camera: Camera3D, filming: bool) -> void:
	var state := String(worker.get("state"))
	for held: Node3D in [worker.find_child("Clipboard", true, false), worker.find_child(
			"ClipboardRight", true, false)]:
		if held != null and held.is_visible_in_tree():
			var size := held.global_basis.get_scale().x
			var was: Vector2 = _log_sizes.get(held.name, Vector2(INF, -INF))
			_log_sizes[held.name] = Vector2(minf(was.x, size), maxf(was.y, size))
	if not state in WALKS:
		return
	var at := worker.global_position
	var body := CylinderShape3D.new()
	body.radius = BODY_ROUND
	body.height = BODY_TO - BODY_FROM
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = body
	query.collision_mask = 0xFFFFFFFF
	query.transform = Transform3D(Basis.IDENTITY, at + Vector3.UP * (BODY_FROM + BODY_TO) / 2.0)
	var legs := CylinderShape3D.new()
	legs.radius = LEGS_ROUND
	legs.height = BODY_FROM - LEGS_FROM
	var low := PhysicsShapeQueryParameters3D.new()
	low.shape = legs
	low.collision_mask = 0xFFFFFFFF
	low.transform = Transform3D(Basis.IDENTITY, at + Vector3.UP * (LEGS_FROM + BODY_FROM) / 2.0)
	var space := worker.get_world_3d().direct_space_state
	for hit in space.intersect_shape(query, 16) + space.intersect_shape(low, 16):
		var thing := hit["collider"] as Node
		if thing == null or thing == worker or worker.is_ancestor_of(thing) \
				or thing.name in MAY_MEET:
			continue
		var key := "%s/%s" % [thing.get_parent().name, thing.name]
		if not _met.has(key):
			_met[key] = "%s at %s" % [state, str(at)]
	for pad in _seal_meshes:
		var local := pad.global_transform.affine_inverse()
		for up: float in [0.3, 0.9, 1.5]:
			for side: Vector3 in BODY_WIDTH:
				if pad.get_aabb().has_point(local * (at + Vector3.UP * up + side)):
					_met[String(pad.get_parent().name)] = "%s at %s" % [state, str(at)]
	var flat_at := Vector2(at.x, at.z)
	var on_stair := (_aside(at) <= float(_stair["width"]) / 2.0 + OFF_FLIGHT
		and _along(at) > -0.2 and _along(at) < _flight_run() + 0.2) \
		or flat_at.distance_to(Vector2(LANDING.x, LANDING.z)) <= NEAR_STAIR \
		or flat_at.distance_to(Vector2(STAIR_FOOT.x, STAIR_FOOT.z)) <= NEAR_STAIR
	var board := worker.call("log_node") as Node3D
	if on_stair or board == null \
			or not board.is_visible_in_tree() or float(worker.get("_speed")) < 0.5:
		return
	_carry_frames += 1
	var model := _parts_now["model"] as Node3D
	var ahead := Vector3(model.global_basis.z.x, 0.0, model.global_basis.z.z).normalized()
	var page := board.to_global(Vector3.ZERO)
	var up_from := page.y - at.y
	var leg := INF
	for limb: String in ["L", "R"]:
		var joints: Array[Vector3] = [_bone("Bip01 %s Thigh" % limb), _bone("Bip01 %s Calf" % limb),
			_bone("Bip01 %s Foot" % limb)]
		for index in range(2):
			for step in range(6):
				leg = minf(leg, _off_board(board, joints[index].lerp(joints[index + 1],
					step / 5.0)))
	if up_from < CARRY_UP.x or up_from > CARRY_UP.y or leg < LEG_ROUND:
		_carry_off += 1
		if _carry_at.is_empty():
			_carry_at = "%s: %.2f m up, %.3f m from his leg, at %s" % [state, up_from, leg,
				str(at)]


## How far `point` is from the log `board`'s box, in metres.
func _off_board(board: Node3D, point: Vector3) -> float:
	var nearest := INF
	for found in board.find_children("*", "MeshInstance3D", true, false):
		var shape := found as MeshInstance3D
		if not shape.is_visible_in_tree():
			continue
		var local := shape.global_transform.affine_inverse() * point
		var box := shape.get_aabb()
		nearest = minf(nearest, (shape.global_transform * local.clamp(box.position, box.end))
			.distance_to(point))
	return nearest


## How large `board`'s face is in `camera`'s picture, in pixels of a 1280 by 800 frame.
func _on_screen(board: Node3D, camera: Camera3D) -> float:
	var half := Vector2(0.1143, 0.1683)
	var corners: Array[Vector2] = []
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var at := board.to_global(Vector3(corner.x * half.x, 0.0, corner.y * half.y))
		if camera.is_position_behind(at):
			return 0.0
		var seen := camera.unproject_position(at)
		var size := camera.get_viewport().get_visible_rect().size
		corners.append(Vector2(seen.x / size.x * 1280.0, seen.y / size.y * 800.0))
	var area := 0.0
	for index in range(4):
		var a := corners[index]
		var b := corners[(index + 1) % 4]
		area += a.x * b.y - b.x * a.y
	return absf(area) / 2.0


## W28-W30: as he is posed, his IK included: the log on the step, his hips, his hand on the seal,
## his wrists and the pen in his fingers.
func _watch_hands(worker: Node3D) -> void:
	var state := String(worker.get("state"))
	var skeleton := _parts_now["skeleton"] as Skeleton3D
	var hips := _bone("Bip01 Pelvis").y - worker.global_position.y
	if state in ["out", "to_hasp", "to_log"]:
		_hips_from = hips
	if state in ["setting_down", "taking_up"] and _hips_from < INF:
		_hips_low[state] = maxf(float(_hips_low.get(state, 0.0)), _hips_from - hips)
	var van := _van_now
	if state in ["sealing", "checking"]:
		var board := worker.call("log_node") as Node3D
		_log_on_step_frames += 1
		var step := van.global_transform.affine_inverse()
		var lowest := INF
		for mesh in board.find_children("*", "MeshInstance3D", true, false):
			var shape := mesh as MeshInstance3D
			var box := shape.global_transform * shape.get_aabb()
			lowest = minf(lowest, box.position.y)
		var top := van.to_global(Vector3(0.0, STEP_TOP, 2.93)).y
		_log_off_step = maxf(_log_off_step, absf(lowest - top))
		_log_tilt = maxf(_log_tilt, rad_to_deg(board.global_basis.y.normalized().angle_to(
			van.global_basis.y.normalized())))
		for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			var at := step * board.to_global(Vector3(corner.x * LOG_HALF.x, 0.0,
				corner.y * LOG_HALF.y))
			if at.x < STEP_FROM.x or at.x > STEP_TO.x or at.z < STEP_FROM.y or at.z > STEP_TO.y:
				_log_where = "a corner off the step at %s in the van's frame" % str(at)
		var near := INF
		for side: String in ["L", "R"]:
			for part: String in ["Hand", "Finger0", "Finger02", "Finger1", "Finger12", "Finger2",
					"Finger22", "Finger4", "Finger42"]:
				var bone := _bone("Bip01 %s %s" % [side, part])
				near = minf(near, _off_board(board, bone))
		_hands_on_log = minf(_hands_on_log, near)
	if state == "checking":
		_checking_frames += 1
		var seal := van.find_child("BoltSeal", true, false) as Node3D
		var hand := skeleton.global_transform * skeleton.get_bone_global_pose(
			skeleton.find_bone("Bip01 R Hand"))
		var settled := float(worker.get("_timer")) >= SETTLED.x \
			and float(worker.get("_timer")) <= SETTLED.y
		if seal != null and _bone("Bip01 R Finger1").distance_to(seal.global_position) <= ON_SEAL:
			_on_seal_frames += 1
		if seal != null and settled and _bone("Bip01 R Finger1").distance_to(
				seal.global_position) <= ON_SEAL:
			var out := van.global_basis.z.normalized()
			var along := hand.origin.dot(out)
			_tug = Vector2(minf(_tug.x, along), maxf(_tug.y, along))
			var roll := rad_to_deg(atan2(hand.basis.z.normalized().dot(Vector3.UP),
				hand.basis.z.normalized().dot(van.global_basis.x.normalized())))
			_twist = Vector2(minf(_twist.x, roll), maxf(_twist.y, roll))
	var timer := float(worker.get("_timer"))
	var bends: Array = []
	if state == "sealing" and timer >= 1.2 and timer <= 4.3:
		bends = ["L", "R"]
	elif state == "noting" and timer >= 0.85 and timer <= 1.55:
		bends = ["R"]
	for side: String in bends:
		var hand := skeleton.global_transform * skeleton.get_bone_global_pose(
			skeleton.find_bone("Bip01 %s Hand" % side))
		var arm := hand.origin - _bone("Bip01 %s Forearm" % side)
		var bend := rad_to_deg(arm.angle_to(hand.basis.x))
		var key := "%s %s" % [state, side]
		_wrist_most[key] = maxf(float(_wrist_most.get(key, 0.0)), bend)
		if state == "sealing":
			var elbow := _bone("Bip01 %s Forearm" % side)
			var angle := rad_to_deg((_bone("Bip01 %s UpperArm" % side) - elbow).angle_to(
				hand.origin - elbow))
			var was: Vector2 = _elbows.get(side, Vector2(INF, -INF))
			_elbows[side] = Vector2(minf(was.x, angle), maxf(was.y, angle))
	if state == "noting" and timer >= 0.85 and timer <= 1.55:
		var tip: Vector3 = worker.call("pen_tip")
		var pen := worker.find_child("Pen", true, false) as Node3D
		_tip_off = maxf(_tip_off, tip.distance_to(_bone("Bip01 R Finger12")))
		var web := (_bone("Bip01 R Finger0") + _bone("Bip01 R Finger1")) / 2.0
		var shaft := pen.global_basis.y.normalized()
		var from_tip := web - tip
		_shaft_off = maxf(_shaft_off, (from_tip - shaft * from_tip.dot(shaft)).length())


func _bone(name: String) -> Vector3:
	var skeleton := _parts_now["skeleton"] as Skeleton3D
	return (skeleton.global_transform * skeleton.get_bone_global_pose(
		skeleton.find_bone(name))).origin


## W12, W13: on the flight, down and up, a tread a step at the stair's cadence, each planted foot
## on its tread; his rail-side hand on the rail, the log in his other hand.
func _check_stair() -> void:
	var times: Array[float] = []
	var treads_ok := true
	var steps := {"down": 0, "up": 0}
	for index in range(1, _plants.size()):
		var was: Array = _plants[index - 1]
		var now: Array = _plants[index]
		if was[3] != now[3] or now[4] - was[4] > 90:
			continue
		steps[now[3]] += 1
		times.append(float(now[4] - was[4]) / Engine.physics_ticks_per_second)
		treads_ok = treads_ok and absi(int(now[2]) - int(was[2])) == 1 and was[1] != now[1]
	var slowest: float = times.max() if not times.is_empty() else INF
	var fastest: float = times.min() if not times.is_empty() else 0.0
	_check(steps["down"] >= 3 and steps["up"] >= 3 and treads_ok and fastest >= STEP_TIME.x
		and slowest <= STEP_TIME.y and _tread_off <= ON_TREAD, ("W12: on the dock stair he takes "
		+ "a tread a step, his feet taking turns (%s; %d steps down, %d up), each step %.2f-%.2f "
		+ "s (0.45-0.85), each planted foot on its tread (%.3f m off: %s); plants %s") % [
		treads_ok, steps["down"], steps["up"], fastest, slowest, _tread_off, _tread_at,
		str(_plants.map(func(p: Array) -> String: return "%s%d@%d" % [p[3][0], p[2], p[4]]))])
	_check(_rail_off.get("down", INF) <= ON_RAIL and _rail_off.get("up", INF) <= ON_RAIL
		and _log_hand.get("down", false) and _log_hand.get("up", false), ("W13: his hand on the "
		+ "rail's side holds the rail all the way down and up (%.3f and %.3f m off it), the log "
		+ "in his other hand (%s, %s; the farthest at %s)") % [_rail_off.get("down", INF),
		_rail_off.get("up", INF), _log_hand.get("down", false), _log_hand.get("up", false),
		str(_rail_at)])


## W17: sent to scan bay 9's load, set on the lift's deck as Ethan sets it down (as setup), his
## scanner stays dark until he aims it at a shipping label facing him: a red line from its window
## to the label for 0.3-0.5 s, then a green flash with the beep.
func _check_scan() -> void:
	var parts := _parts()
	var worker := parts["worker"] as Node3D
	var load := (parts["shed"] as Node3D).get_node_or_null("Building/Pallet6") as Node3D
	var labels := load.find_children("ShippingLabel*", "Node3D", true, false) if load != null \
		else []
	var label: Node3D = labels[0] if not labels.is_empty() else null
	var staged := load.global_position
	load.global_position = DECK_MIDDLE
	worker.call("go_scan", load)
	var lit_before := 0
	var aimed := 0
	var flashed := 0
	var beeped_flash := true
	var off_label := INF
	var time := 0.0
	var reads: Array[Node3D] = []
	worker.connect("scanned", func(what: Node3D) -> void: reads.append(what))
	while time < 20.0 and not (not reads.is_empty() and String(worker.get("state")) == "sitting"):
		await physics_frame
		time += 1.0 / Engine.physics_ticks_per_second
		var aim := worker.find_child("AimLine", true, false) as Node3D
		var green := worker.find_child("GoodRead", true, false) as Node3D
		var window := worker.find_child("ScannerWindow", true, false) as MeshInstance3D
		var lit := window != null and (window.material_override as StandardMaterial3D) \
			.emission_enabled
		var aiming := aim != null and aim.is_visible_in_tree()
		if aiming:
			aimed += 1
			for each: Node3D in labels:
				off_label = minf(off_label, (worker.call("aim_end") as Vector3).distance_to(
					each.global_position))
		elif lit and aimed == 0:
			lit_before += 1
		if green != null and green.is_visible_in_tree():
			flashed += 1
			beeped_flash = beeped_flash and (worker.get_node("ScannerBeep")
				as AudioStreamPlayer3D).playing
	load.global_position = staged
	var rate := float(Engine.physics_ticks_per_second)
	_check(label != null and lit_before == 0 and aimed / rate >= AIM.x and aimed / rate <= AIM.y
		and off_label <= ON_LABEL and flashed / rate >= FLASH.x and flashed / rate <= FLASH.y
		and beeped_flash and not reads.is_empty(), ("W17: his scanner dark until he aims (%d "
		+ "frames lit before), "
		+ "a red line to the load's shipping label for %.2f s (0.3-0.5), ending %.3f m from it, "
		+ "then a green flash of %.2f s with the beep (%s), the label read (%s)") % [lit_before,
		aimed / rate, off_label, flashed / rate, beeped_flash, not reads.is_empty()])


## Whether his body (a 0.25 m column up to 1.85 m) stands between `from` and `to`.
func _in_the_way(from: Vector3, to: Vector3, body: Vector3) -> bool:
	var a := Vector2(from.x, from.z)
	var b := Vector2(to.x, to.z)
	var c := Vector2(body.x, body.z)
	var t := clampf((c - a).dot(b - a) / maxf((b - a).length_squared(), 0.0001), 0.0, 1.0)
	var height := lerpf(from.y, to.y, t) - body.y
	return (a + (b - a) * t).distance_to(c) < 0.25 and height < 1.85 and t > 0.02 and t < 0.98


## W20 (#333): with the van backed up to 1.0 m nearer the dock than play leaves it, too near
## to stand behind, he waits inside the side door; Enter skips his cutscene at once; pulled
## forward again, out he goes.
func _check_no_room() -> void:
	var parts := _parts()
	var worker := parts["worker"] as Node3D
	var van := _app.get_node("FreightVan") as Node3D
	var cutscene := _app.get("seal_cutscene") as Node
	var settling := 0.0
	while String(worker.get("state")) != "seated" and settling < 15.0:
		await physics_frame
		settling += 1.0 / Engine.physics_ticks_per_second
	van.call("recover", TOO_NEAR)
	van.set("rear_doors_open", false)
	for frame in range(10):
		await physics_frame
	_van_now = van
	(parts["shed"] as Node).call("call_dock_hand", van, NUMBER)
	var furthest := -INF
	var time := 0.0
	while time < 40.0:
		await physics_frame
		time += 1.0 / Engine.physics_ticks_per_second
		furthest = maxf(furthest, worker.global_position.x)
	var waiting := String(worker.get("state")) == "out" and furthest < SIDE_DOOR_X
	var where := "%s at %s" % [worker.get("state"), str(worker.global_position)]
	var was_playing := bool(cutscene.get("playing"))
	await _key(KEY_ENTER)
	var skipped: bool = not bool(cutscene.get("playing")) \
		and worker.get_viewport().get_camera_3d() != cutscene.get("camera")
	van.call("recover", PULLED_FORWARD)
	van.set("rear_doors_open", false)
	var out := false
	time = 0.0
	while time < 15.0 and not out:
		await physics_frame
		time += 1.0 / Engine.physics_ticks_per_second
		out = worker.global_position.x > SIDE_DOOR_X + 0.5
	_check(waiting and was_playing and skipped and out, ("W20: with the van too near the dock to "
		+ "stand behind, he waits inside the side door (%s, never past x %.2f), Enter skips his "
		+ "cutscene at once (%s), and pulled forward again, out he goes (%s; he was %s)") % [
		waiting, furthest, was_playing and skipped, out, where])


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


func _flat(box: AABB) -> Rect2:
	return Rect2(box.position.x, box.position.z, box.size.x, box.size.z)


## How far apart two rectangles on the floor are: 0 if they touch or overlap.
func _apart(a: Rect2, b: Rect2) -> float:
	var dx := maxf(0.0, maxf(b.position.x - a.end.x, a.position.x - b.end.x))
	var dz := maxf(0.0, maxf(b.position.y - a.end.y, a.position.y - b.end.y))
	return Vector2(dx, dz).length()


## The box, in the world, round everything `node` draws.
func _box(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for found in node.find_children("*", "MeshInstance3D", true, false):
		var mesh := found as MeshInstance3D
		var part := mesh.global_transform * mesh.get_aabb()
		box = part if first else box.merge(part)
		first = false
	return box


func _store(text: String) -> void:
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _remove() -> void:
	for suffix in ["", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(_scratch + suffix):
			DirAccess.remove_absolute(_scratch + suffix)


func _timeout() -> void:
	_check(false, "The dock worker's checks finish within 300 s")
	_finish()


func _finish() -> void:
	print("DOCK WORKER RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	_remove()
	quit(1 if _failures > 0 else 0)
