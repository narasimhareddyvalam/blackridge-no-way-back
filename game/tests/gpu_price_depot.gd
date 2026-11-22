extends SceneTree
## The bigger depot's GPU price (docs/PHASE_BRIEF.md, Phase 2 step 2c, rule D9), measured as
## game/tests/gpu_price.gd measures Assignment 6's effects: a windowed run on macOS with Apple's
## Metal Performance HUD logging each frame's GPU time (MTL_HUD_ENABLED=1, MTL_HUD_LOG_ENABLED=1),
## read by tools/tests/gpu_price.py. From the court at eye height, looking at the docks, two cases
## are shown and hidden in alternating blocks. D9: the whole transfer shed (its ground and walls,
## the building, the yard and the fence), while the lamps' rain runs in both; hidden, the shed no
## longer hides the hill and forest behind it, so this case also prices what it covers. P2: only
## what part 2 added (the dock fittings, lights and signals, the arm and bay lights, the lanes, the
## open doors' tracks, the staged loads and the dock front's rain), the shell kept in both, so the
## view behind stays covered. RK (#267): the shed's racking and its fit-out (`racking.gd`: the
## racks and their stock, the aisles' lines and lights, the joists, liner, ducts and sprinkler
## mains), seen from the cross-aisle inside the shed; and its parts alone, to find what costs:
## RL its aisle lights and fixtures, RW its stretch film, RA its frames and decks (each deck's
## mesh cut out; the frames' slots cut out too until #267 drew them solid).
## FL and FB (step 5 of #253, part D): the shed's floor in its own material (`shed_floor.gd`)
## against the plain concrete it replaced, swapped on the dock floor's pieces and the lane, from
## the racking's view in the cross-aisle (FL) and looking into bay 9 (FB).
## FE (part E): the shed's fit-out overhead and on its walls (`shed_fitout.gd`: the heaters, fans,
## sprinklers over the staging, trays, the docks' kit and the side door's), shown and hidden, from
## the staging lanes looking along the dock wall.
## FK (part F): the safety and work kit (`shed_kit.gd`: the strip's lights, the west exit, signs,
## extinguishers, the charging bay, mirrors, the work kit), shown and hidden, from the staging
## lanes.
## YV (part H): the yard's parked vehicles (`yard_vehicles.gd`: the trailers at docks 1-3 and in
## the bays, the tractor, the box truck, the staff cars, the dumpsters), shown and hidden, from the
## court.
## CY (Mission 2's step 4): the container yard (`container_yard.gd`: the fence and gate, the
## stacks, the masts and their four lights, the dark van), shown and hidden, from the driveway.
## CP (Mission 2's step 5): the warehouse compound (`compound.gd`, `warehouse.gd`: the fence and
## gate, the booth and its guard, both warehouses with their dock lights, wall packs, the open bay,
## the floods, the trailers and the yard's kit), shown and hidden, from its court.
## `-- --only=P2 --cycles=40` measures one
## case, with more cycles. It changes no game file: it shows and hides nodes in the game.

const SETTLE := 3.0
const CYCLES := 24
const BLOCK := 1.0
const SKIP := 0.3
const VIEW := [Vector3(-58.0, 1.7, 36.0), Vector3(-62.0, 3.0, 20.0), 60.0]
const INSIDE := [Vector3(-50.0, 3.2, 12.0), Vector3(-68.0, 3.4, 1.0), 60.0]
const BAY_NINE := [Vector3(-48.6, 2.9, 12.8), Vector3(-47.8, 1.3, 18.6), 60.0]
const STAGING := [Vector3(-48.0, 2.9, 11.0), Vector3(-70.0, 7.6, 17.5), 65.0]
const DRIVEWAY := [Vector3(100.0, 1.7, 172.0), Vector3(100.0, 3.0, 140.0), 60.0]
const COURT := [Vector3(205.0, 1.7, 143.0), Vector3(240.0, 3.0, 128.0), 65.0]
const FLOOR_PIECES := ["DockFloor1", "DockFloor2", "DockFloor3", "DockFloor4", "LaneFloor"]
const RACK_PARTS := {"RL": ["BayLight", "AisleFixtures", "FixtureChains"], "RW": ["Wrap"],
	"RA": ["Frames", "Decks"]}
const PART_TWO := ["DockSeal", "DockBumper", "DockLeveller", "DockEdge", "DockLight", "DockSignal",
	"DockArm", "BayLight", "LaneLine", "DoorTrack", "DoorSpringShaft", "Pallet", "StretchWrap",
	"Cartons", "Forklift"]

var _app: Node3D
var _shed: Node3D
var _yard: Node3D
var _compound: Node3D
var _rain: Node3D
var _camera: Camera3D
var _cycles := CYCLES
var _added: Array[Node3D] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	root.add_child(_app)
	await process_frame
	_app.call("_resume")
	var world: Node3D = _app.get_node("IndustrialLoop")
	_shed = world.get("transfer_shed")
	_yard = world.get("container_yard")
	_compound = world.get("compound")
	_rain = world.get("lamp_rain")
	_camera = Camera3D.new()
	_camera.name = "GpuPriceCourt"
	_camera.fov = VIEW[2]
	_camera.far = 400.0
	_camera.cull_mask = (_app.get("title_camera") as Camera3D).cull_mask
	root.add_child(_camera)
	_camera.look_at_from_position(VIEW[0], VIEW[1], Vector3.UP)
	_camera.make_current()
	var chosen: Array = ["D9", "P2"]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			chosen = arg.trim_prefix("--only=").split(",")
		elif arg.begins_with("--cycles="):
			_cycles = int(arg.trim_prefix("--cycles="))
	for found in _shed.get_node("Building").get_children():
		if PART_TWO.any(func(prefix: String) -> bool: return String(found.name).begins_with(prefix)):
			_added.append(found as Node3D)
	_added.append(_rain.volumes[_rain.volumes.size() - 1] as Node3D)
	await _wait(SETTLE)
	print("GPU PRICE: window %s, vsync %s, MetalFX scale %.2f" % [root.get_visible_rect().size,
		DisplayServer.window_get_vsync_mode(), root.scaling_3d_scale])
	for case: String in chosen:
		var view: Array = INSIDE if case.begins_with("R") or case == "FL" else VIEW
		if case == "FB":
			view = BAY_NINE
		elif case == "FE" or case == "FK":
			view = STAGING
		elif case == "CY":
			view = DRIVEWAY
		elif case == "CP":
			view = COURT
		_camera.fov = view[2]
		_camera.look_at_from_position(view[0], view[1], Vector3.UP)
		await _wait(1.0)
		await _alternate(case)
	print("GPU PRICE DONE")
	quit()


func _alternate(case: String) -> void:
	for cycle in range(_cycles):
		for shown: bool in [true, false]:
			DisplayServer.window_move_to_foreground()
			_show(case, shown)
			var began := Time.get_unix_time_from_system()
			await _wait(BLOCK)
			var ended := Time.get_unix_time_from_system()
			print("GPU PRICE BLOCK|%s|%s|cycle %d|time %.3f-%.3f|skip %.2f|particles %d|%s|%s"
				% [case, "on" if shown else "off", cycle + 1, began, ended, SKIP, 0,
				"the cross-aisle" if case.begins_with("R") or case == "FL" else ("bay 9"
				if case == "FB" else ("the staging lanes" if case == "FE" or case == "FK"
				else ("the driveway" if case == "CY" else ("the compound's court"
				if case == "CP" else "the court")))),
				"nodes toggled %d, rain volumes active %d" % [_added.size() if case == "P2" else 1,
				int(_rain.call("active_count"))]])
	_show(case, true)
	await _wait(0.5)


func _show(case: String, shown: bool) -> void:
	if case == "D9":
		_shed.visible = shown
		return
	if case == "RK":
		(_shed.get_node("Building/Racking") as Node3D).visible = shown
		return
	if case == "FE":
		(_shed.get_node("Building/ShedFitout") as Node3D).visible = shown
		return
	if case == "CY":
		_yard.visible = shown
		return
	if case == "CP":
		_compound.visible = shown
		return
	if case == "YV":
		(_shed.get_node("YardVehicles") as Node3D).visible = shown
		return
	if case == "FK":
		(_shed.get_node("Building/ShedKit") as Node3D).visible = shown
		return
	if case == "FL" or case == "FB":
		var building := _shed.get_node("Building")
		for piece: String in FLOOR_PIECES:
			(building.get_node(piece) as MeshInstance3D).material_override = \
				building.get("_floor") if shown else building.get("_concrete")
		return
	if RACK_PARTS.has(case):
		for found in _shed.get_node("Building/Racking").get_children():
			if (RACK_PARTS[case] as Array).any(func(prefix: String) -> bool:
					return String(found.name).begins_with(prefix)):
				(found as Node3D).visible = shown
		return
	for node in _added:
		node.visible = shown


func _wait(seconds: float) -> void:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < seconds * 1000.0:
		await process_frame
