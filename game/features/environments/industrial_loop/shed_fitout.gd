extends Node3D
## The transfer shed's fit-out overhead and on its walls (docs/PHASE_BRIEF.md, step 5 of #253,
## part E; the author's choices, #298), as a working dock's: six gas-fired unit heaters hung from
## struts across the joists, 8-14 ft up, their louvers turning the air down at the doors, each
## with its flue to the roof and its gas drop and shut-off from the gas main run through the
## joists; two 20 ft high-volume low-speed fans over the staging lanes, between the staging
## row's lights, each centred between four sprinkler heads and well below them (NFPA 13), turning
## slowly as in winter; three sprinkler mains over the staging lanes and the cross-aisle, heads
## every 8 ft 9 in, the lines 3.9 m apart, the last half a spacing from the dock wall; 12 in
## ladder tray on trapezes along the dock wall and the east wall, above the doors, with conduit
## to each door's operator and control station; at each dock its number on the pier beside it,
## its control station (`station_legend.png`) and its operator; by the side door the time clock,
## its card racks and the notice board with the six federal posters. Parts are drawn by
## `tools/art/build_shed_fitout.py`, their signs by `tools/art/make_shed_signs.py`; the sprinkler
## parts are part A's (`build_shed_services.py`). Nothing here is solid: it hangs overhead or
## lies flat on the walls. `placements()` hands out what was placed, since a headless run keeps
## no multi-mesh transforms.

const Racking := preload("racking.gd")
const Parts := preload("res://features/environments/industrial_loop/art/fitout/shed_fitout.glb")
const ART := "res://features/environments/industrial_loop/art/fitout/"
const FLOOR := 1.3
const LANE_FLOOR := 0.02
const FACE := 19.75
const EAST_WALL := -40.25
const OFFICE_EAST := -82.0
const WEST_WALL := -89.75
const DOCKS: Array[float] = [-80.0, -76.0, -72.0, -68.0, -64.0, -60.0, -56.0, -52.0, -47.75]
const OPENING := 2.74
## Each dock's kit on the pier east of its door, about 1.47-2.53 m from its middle.
const PIER := 2.0
const NUMBER_UP := 2.3
const NUMBER_SIZE := Vector2(0.32, 0.44)
const STATION_UP := 1.45
const STATION_SIZE := Vector3(0.25, 0.40, 0.14)
const CONDUIT_AT := 1.7
const OPERATOR_AT := -1.75
const OPERATOR_HEIGHT := 7.0
## Heaters: mounted with their bottoms 13 ft up (3.97 m), 2.75 m in from the dock wall so their
## flues clear the sprinkler main at z 17.5 and the raised doors, one more over the lane.
const HEATER_SIZE := Vector3(0.76, 0.66, 0.60)
const HEATER_BOTTOM := 3.97
const HEATER_XS: Array[float] = [-78.0, -70.0, -62.0, -54.0, -50.0]
const HEATER_Z := 17.0
const LANE_HEATER := Vector2(-43.4, 16.0)
const LOUVER_DOWN := deg_to_rad(30.0)
const ROD_APART := 0.3
const FLUE_BACK := 0.18
const GAS_INLET := Vector3(0.41, -0.1, -0.15)
const GAS_ABOVE_CHORD := 0.3
const COCK_ABOVE := 0.4
const JOIST_STEP := 2.0625
const JOIST_FIRST := -87.781
const JOIST_DEEP := 1.25
const STRUT_DEEP := 0.041
## Fans: 20 ft across, between the staging row's lights (every 8 m along z 15) so none turns
## under a lamp, centred between the sprinkler lines at z 13.6 and 17.5; blades 6 m above the
## dock floor; turning at 15 rpm, a winter's destratifying speed.
const FAN_DIAMETER := 240 * 0.0254
const FAN_CENTRES: Array[Vector2] = [Vector2(-74.0, 15.55), Vector2(-58.0, 15.55)]
const FAN_BLADES_UP := 6.0
const FAN_RPM := 15.0
const FAN_MOTOR_TALL := 0.42
const FAN_MOUNT_SPAN := 3.0
const FAN_MOUNT_DEEP := 0.1
## Sprinklers: three lines 3.9 m apart, heads 8 ft 9 in along them (112 ft² a head), phased so
## that each fan's centre falls between four heads.
const SPRINKLER_ZS: Array[float] = [9.7, 13.6, 17.5]
const HEAD_STEP := 16.0 / 6.0
const HEAD_PHASE := -72.6667
const OFFICE_FRONT := 12.0
## Tray: 0.8 m off the wall at 6 m above the dock floor, on trapezes every 3 m.
const TRAY_UP := 6.0
const TRAY_OFF := 0.8
const TRAY_SECTION := 3.0
const TRAY_DOCK := Vector2(-81.7, -41.05)
const TRAY_EAST := Vector2(18.95, -9.0)
const TRAPEZE := 0.5
## The side door's wall: the clock and its racks, the notice board and its posters.
const CLOCK := Vector3(EAST_WALL, LANE_FLOOR + 1.35, 16.2)
const RACK_APART := 0.4
const BOARD := Vector3(EAST_WALL, LANE_FLOOR + 1.47, 14.9)
const POSTER_SIZE := Vector2(0.28, 0.36)
const POSTER_GRID := Vector2(0.38, 0.42)

var _meshes := {}
var _placed := {}
var _blades: Array[MeshInstance3D] = []
var _mounts: Array[Vector3] = []
var _aims: Array[Vector3] = []


func build() -> void:
	var parts := Parts.instantiate() as Node3D
	for found in parts.find_children("*", "MeshInstance3D", true, false):
		_meshes[String(found.name)] = (found as MeshInstance3D).mesh
	parts.free()
	_heaters()
	_fans()
	_sprinklers()
	_trays()
	_docks()
	_side_door()


func _process(delta: float) -> void:
	for blades in _blades:
		blades.rotation.y = wrapf(blades.rotation.y + FAN_RPM / 60.0 * TAU * delta, -PI, PI)


## What was placed under `label`, as world transforms.
func placements(label: String) -> Array:
	return (_placed.get(label, []) as Array).duplicate()


## Which way heater `index` sends its air: out of its front, turned down by its louvers.
func heater_aim(index: int) -> Vector3:
	return _aims[index]


func fan_angle(index: int) -> float:
	return _blades[index].rotation.y


## The top of fan `index`'s mount, where it meets the joists' bottom chords.
func fan_mount(index: int) -> Vector3:
	return _mounts[index]


## Each dock's number and the middle of its plate.
func dock_numbers() -> Array:
	var found := []
	for index in range(DOCKS.size()):
		found.append({"number": index + 1, "centre": Vector3(DOCKS[index] + PIER,
			FLOOR + NUMBER_UP, FACE - 0.004)})
	return found


static func chord(z: float) -> float:
	return Racking.underside(z) - JOIST_DEEP


func _heaters() -> void:
	var heaters: Array[Transform3D] = []
	for x in HEATER_XS:
		heaters.append(Transform3D(Basis(Vector3.UP, PI), Vector3(x, FLOOR + HEATER_BOTTOM
			+ HEATER_SIZE.y / 2.0, HEATER_Z)))
	heaters.append(Transform3D(Basis(Vector3.UP, -PI / 2.0), Vector3(LANE_HEATER.x, LANE_FLOOR
		+ HEATER_BOTTOM + HEATER_SIZE.y / 2.0, LANE_HEATER.y)))
	var rods: Array[Transform3D] = []
	var struts: Array[Transform3D] = []
	var flues: Array[Transform3D] = []
	var drops: Array[Transform3D] = []
	var cocks: Array[Transform3D] = []
	var gas_main: Array[Transform3D] = []
	for heater in heaters:
		_aims.append(heater.basis * Vector3(0.0, -sin(LOUVER_DOWN), -cos(LOUVER_DOWN)))
		var top := heater.origin.y + HEATER_SIZE.y / 2.0
		var hang := chord(heater.origin.z) - STRUT_DEEP
		var west := floorf((heater.origin.x - JOIST_FIRST) / JOIST_STEP) * JOIST_STEP + JOIST_FIRST
		var along := heater.basis.x.normalized()
		struts.append(Transform3D(Basis.IDENTITY.scaled(Vector3(JOIST_STEP + 0.2, 1.0, 1.0)),
			Vector3(west - 0.1, chord(heater.origin.z), heater.origin.z)))
		for side: float in [-1.0, 1.0]:
			var at := heater.origin + along * side * ROD_APART
			rods.append(_upright(Vector3(at.x, top, at.z), hang - top))
		var flue := heater.origin + heater.basis * Vector3(0.0, 0.0, FLUE_BACK)
		flues.append(_upright(Vector3(flue.x, top, flue.z), Racking.underside(flue.z) - top))
		var inlet := heater * GAS_INLET
		var gas := chord(inlet.z) + GAS_ABOVE_CHORD
		drops.append(_upright(inlet, gas - inlet.y))
		cocks.append(Transform3D(heater.basis, inlet + Vector3.UP * COCK_ABOVE))
	var main_z := (heaters[0] * GAS_INLET).z
	var main_y := chord(main_z) + GAS_ABOVE_CHORD
	var main_from := HEATER_XS[0] - 2.0
	gas_main.append(Transform3D(Basis.IDENTITY.scaled(Vector3(HEATER_XS[HEATER_XS.size() - 1]
		+ 2.0 - main_from, 1.0, 1.0)), Vector3(main_from, main_y, main_z)))
	_many("Heaters", "UnitHeater", heaters)
	_many("HeaterRods", "HeaterRod", rods)
	_many("HeaterStruts", "Strut", struts)
	_many("Flues", "Flue", flues)
	_many("GasDrops", "GasDrop", drops)
	_many("GasCocks", "GasCock", cocks)
	_many("GasMain", "GasPipe", gas_main)


func _fans() -> void:
	var motors: Array[Transform3D] = []
	var rods: Array[Transform3D] = []
	var mounts: Array[Transform3D] = []
	var centres: Array[Transform3D] = []
	for index in range(FAN_CENTRES.size()):
		var at := Vector3(FAN_CENTRES[index].x, FLOOR + FAN_BLADES_UP, FAN_CENTRES[index].y)
		centres.append(Transform3D(Basis.IDENTITY, at))
		motors.append(Transform3D(Basis.IDENTITY, at))
		var top := chord(at.z)
		_mounts.append(Vector3(at.x, top, at.z))
		mounts.append(Transform3D(Basis.IDENTITY, Vector3(at.x, top, at.z)))
		var from := at.y + FAN_MOTOR_TALL
		rods.append(_upright(Vector3(at.x, from, at.z), top - FAN_MOUNT_DEEP - from))
		var blades := MeshInstance3D.new()
		blades.name = "FanBlades%d" % (index + 1)
		blades.mesh = _meshes["FanBlades"]
		add_child(blades)
		blades.global_position = at
		_blades.append(blades)
	_placed["Fans"] = centres
	_many("FanMotors", "FanMotor", motors)
	_many("FanDownrods", "FanDownrod", rods)
	_many("FanMounts", "FanMount", mounts)


func _sprinklers() -> void:
	var mains: Array[Transform3D] = []
	var heads: Array[Transform3D] = []
	var length := Racking.MAIN.z
	for z in SPRINKLER_ZS:
		var west := OFFICE_EAST if z > OFFICE_FRONT else WEST_WALL
		var centre := Racking.underside(z) - Racking.MAIN_DOWN
		var count := ceili((EAST_WALL - west) / length)
		var scale := (EAST_WALL - west) / (count * length)
		for index in range(count):
			mains.append(Transform3D(Basis.IDENTITY.scaled(Vector3(scale, 1.0, 1.0)),
				Vector3(west + index * length * scale, centre, z)))
		var x := HEAD_PHASE - floorf((HEAD_PHASE - west - 0.3) / HEAD_STEP) * HEAD_STEP
		while x < EAST_WALL - 0.3:
			heads.append(Transform3D(Basis.IDENTITY, Vector3(x, centre - Racking.MAIN.y
				- Racking.HEAD_DROP, z)))
			x += HEAD_STEP
	var services := Racking.Services.instantiate() as Node3D
	for found in services.find_children("*", "MeshInstance3D", true, false):
		_meshes[String(found.name)] = (found as MeshInstance3D).mesh
	services.free()
	_many("SprinklerMains", "SprinklerMain", mains)
	_many("SprinklerHeads", "SprinklerHead", heads)


func _trays() -> void:
	var runs: Array[Transform3D] = []
	var rods: Array[Transform3D] = []
	var trapezes: Array[Transform3D] = []
	var height := FLOOR + TRAY_UP
	var dock_z := FACE - TRAY_OFF
	var east_x := EAST_WALL - TRAY_OFF
	_run(runs, rods, trapezes, Vector3(TRAY_DOCK.x, height, dock_z), Vector3(TRAY_DOCK.y,
		height, dock_z))
	_run(runs, rods, trapezes, Vector3(east_x, height, TRAY_EAST.x), Vector3(east_x, height,
		TRAY_EAST.y))
	_many("TrayRuns", "TraySection", runs)
	_many("TrayRods", "HeaterRod", rods)
	_many("TrayTrapezes", "Strut", trapezes)


## A tray from `from` to `to` in equal sections of about TRAY_SECTION, a trapeze and its two
## rods at each end of each section.
func _run(runs: Array[Transform3D], rods: Array[Transform3D], trapezes: Array[Transform3D],
		from: Vector3, to: Vector3) -> void:
	var count := ceili(from.distance_to(to) / TRAY_SECTION)
	var step := from.distance_to(to) / count
	var along := (to - from).normalized()
	var turn := Basis(Vector3.UP, atan2(-along.z, along.x))
	var across := turn * Vector3(0.0, 0.0, 1.0)
	for index in range(count):
		var middle := from + along * step * (index + 0.5)
		runs.append(Transform3D(turn * Basis.from_scale(Vector3(step / TRAY_SECTION, 1.0, 1.0)),
			middle))
	for index in range(count + 1):
		var at := from + along * step * index
		var bottom := at.y - STRUT_DEEP
		trapezes.append(Transform3D(Basis(Vector3.UP, atan2(-across.z, across.x))
			* Basis.from_scale(Vector3(TRAPEZE, 1.0, 1.0)), at - across * TRAPEZE / 2.0))
		for side: float in [-1.0, 1.0]:
			var rod := at + across * side * (TRAPEZE / 2.0 - 0.03)
			rods.append(_upright(Vector3(rod.x, bottom, rod.z), chord(rod.z) - bottom))


func _docks() -> void:
	var stations: Array[Transform3D] = []
	var operators: Array[Transform3D] = []
	var conduits: Array[Transform3D] = []
	var plates := load(ART + "dock_numbers.png") as Texture2D
	var legend := _sign(load(ART + "station_legend.png") as Texture2D, Vector2.ONE, Vector2.ZERO)
	for index in range(DOCKS.size()):
		var x := DOCKS[index]
		var number := MeshInstance3D.new()
		number.name = "DockNumber%d" % (index + 1)
		number.mesh = _quad(NUMBER_SIZE)
		number.material_override = _sign(plates, Vector2.ONE / 3.0, Vector2(index % 3,
			index / 3) / 3.0)
		add_child(number)
		number.global_transform = Transform3D(Basis(Vector3.UP, PI), dock_numbers()[index]["centre"])
		var station := Transform3D(Basis.IDENTITY, Vector3(x + PIER, FLOOR + STATION_UP, FACE))
		stations.append(station)
		var face := MeshInstance3D.new()
		face.name = "StationLegend%d" % (index + 1)
		face.mesh = _quad(Vector2(STATION_SIZE.x, STATION_SIZE.y))
		face.material_override = legend
		add_child(face)
		face.global_transform = Transform3D(Basis(Vector3.UP, PI), station.origin
			- Vector3(0.0, 0.0, STATION_SIZE.z + 0.001))
		operators.append(Transform3D(Basis.IDENTITY, Vector3(x + OPERATOR_AT, OPERATOR_HEIGHT,
			FACE)))
		var low := FLOOR + STATION_UP + STATION_SIZE.y / 2.0
		var high := FLOOR + TRAY_UP
		conduits.append(_upright(Vector3(x + CONDUIT_AT, low, FACE - 0.03), high - low))
		conduits.append(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0) * Basis.from_scale(
			Vector3(1.0, TRAY_OFF - 0.03, 1.0)), Vector3(x + CONDUIT_AT, high + 0.05, FACE - 0.03)))
	_many("Stations", "ControlStation", stations)
	_many("Operators", "DoorOperator", operators)
	_many("Conduits", "Conduit", conduits)


func _side_door() -> void:
	var wall := Basis(Vector3.UP, PI / 2.0)
	_many("TimeClock", "TimeClock", [Transform3D(wall, CLOCK)] as Array[Transform3D])
	var racks: Array[Transform3D] = []
	for side: float in [-1.0, 1.0]:
		racks.append(Transform3D(wall, CLOCK + Vector3(0.0, 0.0, side * RACK_APART)))
	_many("CardRacks", "CardRack", racks)
	_many("NoticeBoard", "NoticeBoard", [Transform3D(wall, BOARD)] as Array[Transform3D])
	var face_turn := Basis(Vector3.UP, -PI / 2.0)
	_flat("ClockFace", load(ART + "clock_face.png") as Texture2D, Vector2(0.19, 0.24),
		Transform3D(face_turn, CLOCK - Vector3(0.112, 0.0, 0.0)), Vector2.ONE, Vector2.ZERO)
	for index in range(racks.size()):
		_flat("TimeCards%d" % (index + 1), load(ART + "time_cards.png") as Texture2D,
			Vector2(0.15, 0.6), Transform3D(face_turn, racks[index].origin
			- Vector3(0.005, 0.0, 0.0)), Vector2.ONE, Vector2.ZERO)
	var posters: Array[Transform3D] = []
	var sheet := load(ART + "posters.png") as Texture2D
	for index in range(6):
		var column := index % 3
		var row := index / 3
		var at := BOARD + Vector3(-0.013, (0.5 - row) * POSTER_GRID.y, (column - 1)
			* POSTER_GRID.x)
		posters.append(Transform3D(face_turn, at))
		_flat("Poster%d" % (index + 1), sheet, POSTER_SIZE, Transform3D(face_turn, at),
			Vector2(1.0 / 3.0, 0.5), Vector2(column / 3.0, row * 0.5))
	_placed["Posters"] = posters


func _flat(label: String, texture: Texture2D, size: Vector2, at: Transform3D, scale: Vector2,
		offset: Vector2) -> void:
	var plate := MeshInstance3D.new()
	plate.name = label
	plate.mesh = _quad(size)
	plate.material_override = _sign(texture, scale, offset)
	add_child(plate)
	plate.global_transform = at


func _quad(size: Vector2) -> QuadMesh:
	var quad := QuadMesh.new()
	quad.size = size
	return quad


func _sign(texture: Texture2D, scale: Vector2, offset: Vector2) -> StandardMaterial3D:
	var paint := StandardMaterial3D.new()
	paint.albedo_texture = texture
	paint.roughness = 0.75
	paint.uv1_scale = Vector3(scale.x, scale.y, 1.0)
	paint.uv1_offset = Vector3(offset.x, offset.y, 0.0)
	return paint


## A part 1 m tall along +y set at `bottom`, stretched to `length`.
func _upright(bottom: Vector3, length: float) -> Transform3D:
	return Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, maxf(length, 0.01), 1.0)), bottom)


func _many(label: String, part: String, placed: Array[Transform3D]) -> void:
	_placed[label] = placed
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = _meshes[part]
	multi.instance_count = placed.size()
	for index in range(placed.size()):
		multi.set_instance_transform(index, global_transform.affine_inverse() * placed[index])
	var many := MultiMeshInstance3D.new()
	many.name = label
	many.multimesh = multi
	add_child(many)
