extends SceneTree
## Part E of step 5 of #253 (docs/PHASE_BRIEF.md, "overhead and on the walls"; the author's
## choices, #298): the transfer shed's fit-out above the floor and on its walls, read from the
## shed as the running game builds it on Mission 2's start save, through what the fit-out hands
## out (`placements()`, `fan_angle()`), since a headless run draws nothing: six gas unit heaters
## hung 8-14 ft up, aimed at the doors, their flues to the roof, clear of the raised doors; two
## high-volume low-speed fans turning slowly, centred between sprinklers and 3 ft below them,
## clear of the lights, the duct, the heaters and the racks; sprinkler mains over the staging
## lanes and the cross-aisle (NFPA 13: heads 15 ft apart at most, 130 ft² each, half a spacing
## from the wall); ladder trays on rods at most 12 ft apart; each dock's number, control station
## and inside lights on the pier beside it; the time clock and notice board by the side door.

const START_SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const INCH := 0.0254
const FOOT := 12 * INCH
const DOCK_FLOOR := 1.3
const LANE_FLOOR := 0.02
const FACE := 19.75
const EAST_WALL := -40.25
const DOCKS: Array[float] = [-80.0, -76.0, -72.0, -68.0, -64.0, -60.0, -56.0, -52.0, -47.75]
const OPENING := 2.74
const TRACK := 0.1
## The open docks' doors rise up the wall 0.34 m inside it, to about 7.7 m; keep 0.2 m more.
const RAISED_DOOR := 0.34 + 0.2
const RACK_END := 8.21
const SHED_X := Vector2(-89.75, -40.25)
const LANE_X := -44.7
## The office's two storeys fill the shed's corner west of x -82 from z 12 to the dock face.
const OFFICE_EAST := -82.0
const OFFICE_FRONT := 12.0
const EAVES := 9.0
const RIDGE_Z := 5.0
const HALF_BUILDING := 15.0
const PITCH := deg_to_rad(5.0)
const JOIST_DEEP := 1.25
const DUCT_Z := 11.5
const DUCT_RADIUS := 0.3
const HEATERS := 6
const HEATER_LOW := 8 * FOOT
const HEATER_HIGH := 14 * FOOT
const HEATER_DOWN := 0.3
const FANS := 2
const FAN_WIDEST := 24 * FOOT
const FAN_LOW := 10 * FOOT
const BELOW_HEADS := 3 * FOOT
const FAN_CLEAR := 0.2
const BETWEEN_HEADS := 0.25
const HEAD_APART := 15 * FOOT
const HEAD_AREA := 130 * FOOT * FOOT
const HEAD_FROM_WALL := 7.5 * FOOT
const STAGING := Vector2(10.0, 19.75)
const ROD_APART := 12 * FOOT
const TRAY_OFF_WALL := Vector2(0.5, 1.2)
const NUMBER_UP := Vector2(1.8, 3.0)
const STATION_UP := Vector2(1.2, 1.6)
const SIDE_DOOR := Vector2(-40.0, 17.475)
const SIDE_DOOR_WIDE := 0.95
const NEAR_DOOR := 3.0
const CLOCK_UP := Vector2(1.2, 1.5)
const POSTER_UP := Vector2(1.2, 1.7)
const ON_WALL := 0.2
const POSTERS := 6

var _checks: int = 0
var _failures: int = 0
var _scratch: String
var _app: Node3D
var _shed: Node3D
var _fitout: Node3D


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(120.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-shed-fitout-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_store(START_SAVE)
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	await process_frame
	_app.call("_resume")
	await physics_frame
	_shed = _app.get_node("IndustrialLoop").get("transfer_shed") as Node3D
	_fitout = _shed.get_node_or_null("Building/ShedFitout") as Node3D if _shed != null else null
	_check(_fitout != null and _fitout.has_method("placements"),
		"E0: the shed has its fit-out (Building/ShedFitout) handing out its placements")
	if _fitout != null and _fitout.has_method("placements"):
		_check_heaters()
		await _check_fans()
		_check_sprinklers()
		_check_trays()
		_check_docks()
		_check_side_door()
	_finish()


func _check_heaters() -> void:
	var heaters := _placed("Heaters")
	var size: Vector3 = _fitout.get("HEATER_SIZE")
	var flues := _placed("Flues")
	var high := heaters.size() == HEATERS
	var aimed := high
	var flued := high and flues.size() == HEATERS
	var clear := high
	for index in range(heaters.size()):
		var heater: Transform3D = heaters[index]
		var floor_y := LANE_FLOOR if heater.origin.x > LANE_X else DOCK_FLOOR
		var bottom := heater.origin.y - size.y / 2.0 - floor_y
		high = high and bottom >= HEATER_LOW and bottom <= HEATER_HIGH
		var blows := _fitout.call("heater_aim", index) as Vector3
		var door := Vector3(0.0, 0.0, 1.0) if heater.origin.x <= LANE_X else Vector3(1.0, 0.0, 0.0)
		aimed = aimed and heater.basis.y.normalized().dot(Vector3.UP) > 0.999 \
			and blows.normalized().y <= -HEATER_DOWN \
			and Vector3(blows.x, 0.0, blows.z).normalized().dot(door) > 0.9
		if index < flues.size():
			var flue: Transform3D = flues[index]
			var top := flue.origin.y + flue.basis.y.length()
			flued = flued and absf(flue.origin.x - heater.origin.x) < 0.3 \
				and absf(flue.origin.z - heater.origin.z) < 0.3 \
				and absf(flue.origin.y - (heater.origin.y + size.y / 2.0)) < 0.05 \
				and absf(top - _underside(flue.origin.z)) < 0.05
		var reach := maxf(size.x, size.z) / 2.0
		clear = clear and heater.origin.z + reach < FACE - RAISED_DOOR \
			and heater.origin.z - reach > RACK_END and _from_lights(heater.origin) > 0.5
	_check(high, "E1: %d gas unit heaters, each hung %.1f-%.1f m (8-14 ft) above its floor"
		% [heaters.size(), HEATER_LOW, HEATER_HIGH])
	_check(aimed, "E1: each heater hung level, its louvers turning the air down at least %.0f° "
		% rad_to_deg(asin(HEATER_DOWN)) + "and toward the doors it heats")
	_check(flued, "E1: each heater's flue rises from its top to the roof (%d flues)" % flues.size())
	_check(clear, "E1: every heater clear of the raised doors, the racks and the lights")


func _check_fans() -> void:
	var fans := _placed("Fans")
	var diameter: float = _fitout.get("FAN_DIAMETER")
	var radius := diameter / 2.0
	var heads := _placed("SprinklerHeads")
	heads.append_array(_racking_heads())
	var sized := fans.size() == FANS and diameter <= FAN_WIDEST
	var below := sized
	var between := sized
	var clear := sized
	var worst := INF
	for fan: Transform3D in fans:
		var blades := fan.origin.y
		sized = sized and blades - DOCK_FLOOR >= FAN_LOW
		var near: Array[float] = []
		for head: Transform3D in heads:
			var apart := _flat(head.origin).distance_to(_flat(fan.origin))
			near.append(apart)
			if apart < radius + 0.5:
				worst = minf(worst, head.origin.y - blades)
				below = below and head.origin.y - blades >= BELOW_HEADS
		near.sort()
		between = between and near.size() >= 4 and near[3] - near[0] <= BETWEEN_HEADS
		clear = clear and fan.origin.z - radius > RACK_END \
			and fan.origin.z - radius > DUCT_Z + DUCT_RADIUS + FAN_CLEAR \
			and fan.origin.z + radius < FACE - RAISED_DOOR \
			and _lights_over(fan.origin, radius + FAN_CLEAR) == 0
		for label: String in ["HeaterRods", "Flues"]:
			for part: Transform3D in _placed(label):
				clear = clear and _flat(part.origin).distance_to(_flat(fan.origin)) \
					> radius + FAN_CLEAR
	_check(sized, "E2: %d fans, %.2f m across (at most 24 ft), the blades at least 10 ft above "
		% [fans.size(), diameter] + "the dock floor")
	_check(below, "E2: the blades at least 3 ft below every sprinkler head over them (least %.2f m)"
		% worst)
	_check(between, "E2: each fan centred between four sprinkler heads")
	_check(clear, "E2: each fan clear of the racks, the duct, the raised doors, the lights over "
		+ "it and the heaters' rods and flues")
	var mounted := fans.size() == FANS
	for fan: Transform3D in fans:
		var mount := _fitout.call("fan_mount", fans.find(fan)) as Vector3
		mounted = mounted and absf(mount.y - (_underside(fan.origin.z) - JOIST_DEEP)) < 0.05 \
			and _joists_spanned(fan.origin.x) >= 2
	_check(mounted, "E2: each fan hung from a channel across two joists' bottom chords")
	var before: Array[float] = []
	for index in range(fans.size()):
		before.append(float(_fitout.call("fan_angle", index)))
	for frame in range(30):
		await process_frame
	var turning := fans.size() == FANS
	for index in range(fans.size()):
		var turned := absf(angle_difference(before[index], float(_fitout.call("fan_angle", index))))
		turning = turning and turned > 0.01 and turned < 1.0
	_check(turning, "E2: the fans turn slowly, as in winter (half a second turned them less "
		+ "than a radian)")


func _check_sprinklers() -> void:
	var heads := _placed("SprinklerHeads")
	var lines := {}
	for head: Transform3D in heads:
		var z := snappedf(head.origin.z, 0.01)
		if not lines.has(z):
			lines[z] = []
		(lines[z] as Array).append(head.origin.x)
	var zs: Array = lines.keys()
	zs.sort()
	var spaced := zs.size() >= 2
	var along_most := 0.0
	var across_most := 0.0
	for index in range(zs.size()):
		var xs: Array = lines[zs[index]]
		xs.sort()
		for each in range(xs.size() - 1):
			along_most = maxf(along_most, xs[each + 1] - xs[each])
		if index > 0:
			across_most = maxf(across_most, zs[index] - zs[index - 1])
		var west := OFFICE_EAST if float(zs[index]) > OFFICE_FRONT else SHED_X.x
		spaced = spaced and xs.size() > 1 and xs[0] - west <= HEAD_APART / 2.0 \
			and xs[0] > west and EAST_WALL - xs[xs.size() - 1] <= HEAD_APART / 2.0
	spaced = spaced and along_most <= HEAD_APART and across_most <= HEAD_APART
	var covered := spaced and FACE - float(zs[zs.size() - 1]) <= HEAD_FROM_WALL \
		and float(zs[0]) - STAGING.x <= HEAD_FROM_WALL and along_most * across_most <= HEAD_AREA
	_check(spaced, "E3: %d sprinkler lines over the staging lanes and the cross-aisle, heads at "
		% zs.size() + "most 15 ft apart (along %.2f m, across %.2f m)" % [along_most, across_most])
	_check(covered, "E3: each head covers at most 130 ft² (%.1f ft²), the last line within "
		% (along_most * across_most / FOOT / FOOT) + "half a spacing of the dock wall")


func _check_trays() -> void:
	var runs := _placed("TrayRuns")
	var rods := _placed("TrayRods")
	var walls := {"dock": [], "east": []}
	var along := runs.size() > 0
	for run: Transform3D in runs:
		var off_dock := FACE - run.origin.z
		var off_east := EAST_WALL - run.origin.x
		if off_dock >= TRAY_OFF_WALL.x and off_dock <= TRAY_OFF_WALL.y:
			(walls["dock"] as Array).append(run.origin.x)
		elif off_east >= TRAY_OFF_WALL.x and off_east <= TRAY_OFF_WALL.y:
			(walls["east"] as Array).append(run.origin.z)
		else:
			along = false
		along = along and run.origin.y > DOCK_FLOOR + 3.05 + 0.5
	_check(along and not (walls["dock"] as Array).is_empty() and not (walls["east"] as Array) \
		.is_empty(), "E4: ladder tray along the dock wall and the east wall, above the doors "
		+ "(%d dock, %d east)" % [(walls["dock"] as Array).size(), (walls["east"] as Array).size()])
	var dock_rods: Array[float] = []
	var east_rods: Array[float] = []
	for rod: Transform3D in rods:
		if FACE - rod.origin.z <= TRAY_OFF_WALL.y:
			dock_rods.append(rod.origin.x)
		else:
			east_rods.append(rod.origin.z)
	var widest := maxf(_widest(dock_rods), _widest(east_rods))
	_check(not dock_rods.is_empty() and not east_rods.is_empty() and widest <= ROD_APART,
		"E4: the trays on rods at most 12 ft apart (widest %.2f m)" % widest)
	var clear := true
	var fans := _placed("Fans")
	var radius: float = _fitout.get("FAN_DIAMETER") / 2.0
	var section: float = _fitout.get("TRAY_SECTION")
	for run: Transform3D in runs:
		var half := _flat(run.basis.x.normalized()) * section / 2.0
		for fan: Transform3D in fans:
			var centre := _flat(fan.origin)
			var nearest := Geometry2D.get_closest_point_to_segment(centre, _flat(run.origin) - half,
				_flat(run.origin) + half)
			clear = clear and nearest.distance_to(centre) > radius + FAN_CLEAR
		clear = clear and _from_lights(run.origin) > 0.4
	_check(clear, "E4: the trays clear of the fans and the lights")


func _check_docks() -> void:
	var numbers: Array = _fitout.call("dock_numbers")
	var stations := _placed("Stations")
	var ordered := numbers.size() == DOCKS.size()
	var placed := ordered
	for index in range(numbers.size()):
		var number: Dictionary = numbers[index]
		ordered = ordered and int(number["number"]) == index + 1
		var at: Vector3 = number["centre"]
		placed = placed and _on_pier(at, index) and at.y - DOCK_FLOOR >= NUMBER_UP.x \
			and at.y - DOCK_FLOOR <= NUMBER_UP.y and FACE - at.z <= 0.1
	_check(ordered, "E5: docks 1-9 numbered in order, west to east (%d numbers)" % numbers.size())
	_check(placed, "E5: each number on the pier beside its own door, %.1f-%.1f m up, never behind "
		% [NUMBER_UP.x, NUMBER_UP.y] + "its raised door")
	var stationed := stations.size() == DOCKS.size()
	for index in range(stations.size()):
		var at: Vector3 = stations[index].origin
		stationed = stationed and _on_pier(at, index) and at.y - DOCK_FLOOR >= STATION_UP.x \
			and at.y - DOCK_FLOOR <= STATION_UP.y and FACE - at.z <= 0.2
	_check(stationed, "E5: a control station by each door, centred %.1f-%.1f m above the dock "
		% [STATION_UP.x, STATION_UP.y] + "floor, out of its opening (%d)" % stations.size())
	var building := _shed.get_node("Building")
	var lit := true
	for index in range(DOCKS.size()):
		var signal_node := building.get_node_or_null("DockSignalInside%d" % (index + 1)) as Node3D
		lit = lit and signal_node != null and _on_pier(signal_node.global_position, index)
		if signal_node != null and index < DOCKS.size() - 1:
			var red := signal_node.get_node("Red") as MeshInstance3D
			lit = lit and red.material_override == building.get("_red_on")
	_check(lit, "E5: inside red and green lights by every door, red at the eight shut docks")


func _check_side_door() -> void:
	var near := true
	var heights := true
	var on_wall := true
	var labels := {"TimeClock": CLOCK_UP, "CardRacks": Vector2(0.9, 1.9), "NoticeBoard":
		Vector2(1.0, 1.9), "Posters": POSTER_UP}
	for label: String in labels:
		var found := _placed(label)
		near = near and not found.is_empty()
		for part: Transform3D in found:
			near = near and _flat(part.origin).distance_to(SIDE_DOOR) <= NEAR_DOOR \
				and absf(part.origin.z - SIDE_DOOR.y) > SIDE_DOOR_WIDE / 2.0 + 0.1
			var up := part.origin.y - LANE_FLOOR
			heights = heights and up >= (labels[label] as Vector2).x \
				and up <= (labels[label] as Vector2).y
			on_wall = on_wall and EAST_WALL - part.origin.x <= ON_WALL
	_check(near, "E6: the time clock, its card racks and the notice board within %.0f m of the "
		% NEAR_DOOR + "side door, beside it, not in it")
	_check(heights, "E6: the clock's face %.1f-%.1f m up and the posters' middles %.1f-%.1f m up"
		% [CLOCK_UP.x, CLOCK_UP.y, POSTER_UP.x, POSTER_UP.y])
	_check(on_wall and _placed("Posters").size() == POSTERS, "E6: all on the east wall, "
		+ "out of Ethan's way, the board holding the %d federal posters" % POSTERS)


func _placed(label: String) -> Array:
	return _fitout.call("placements", label)


func _racking_heads() -> Array:
	var racking := _shed.get_node_or_null("Building/Racking")
	return racking.call("placements", "SprinklerHeads") if racking != null else []


func _on_pier(at: Vector3, index: int) -> bool:
	var door := DOCKS[index]
	var next := DOCKS[index + 1] if index + 1 < DOCKS.size() else EAST_WALL + OPENING / 2.0
	return at.x > door + OPENING / 2.0 + TRACK and at.x < next - OPENING / 2.0 - TRACK


func _lights_over(centre: Vector3, reach: float) -> int:
	var count := 0
	for light in _shed.find_children("*", "SpotLight3D", true, false):
		var at := (light as Node3D).global_position
		if at.y > centre.y and _flat(at).distance_to(_flat(centre)) < reach:
			count += 1
	return count


func _from_lights(point: Vector3) -> float:
	var least := INF
	for light in _shed.find_children("*", "SpotLight3D", true, false):
		least = minf(least, (light as Node3D).global_position.distance_to(point))
	return least


func _joists_spanned(x: float) -> int:
	var spanned := 0
	var span: float = _fitout.get("FAN_MOUNT_SPAN")
	for index in range(24):
		var joist := -87.781 + index * 2.0625
		if absf(joist - x) <= span / 2.0:
			spanned += 1
	return spanned


func _widest(values: Array[float]) -> float:
	values.sort()
	var widest := 0.0
	for index in range(values.size() - 1):
		widest = maxf(widest, values[index + 1] - values[index])
	return widest


func _flat(point: Vector3) -> Vector2:
	return Vector2(point.x, point.z)


func _underside(z: float) -> float:
	return EAVES + (HALF_BUILDING - absf(z - RIDGE_Z)) * tan(PITCH)


func _store(text: String) -> void:
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _remove() -> void:
	for suffix in ["", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(_scratch + suffix):
			DirAccess.remove_absolute(_scratch + suffix)


func _timeout() -> void:
	_check(false, "The fit-out's checks finish within 120 s")
	_finish()


func _finish() -> void:
	print("SHED FITOUT RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	_remove()
	quit(1 if _failures > 0 else 0)
