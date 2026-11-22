extends SceneTree
## Mission 2's docks as real ones are (the audit, #352, after Commons photos; the author's
## choices): at every dock door, the transfer shed's nine and the compound's two warehouses', its
## number on a plate above it and painted big on its door; a hi-vis band along its door's bottom;
## a hooded red-over-green traffic light beside it, at a driver's eye, with its caution sign
## ("BACK IN OR PULL OUT ON GREEN LIGHT ONLY"); and its seal's pads black rubber with yellow guide
## stripes. One dressing for both buildings (`dock_dressing.gd`).

const Dressing = preload("res://features/environments/industrial_loop/dock_dressing.gd")
const LENS_LEAST := 0.15
const LIGHT_HEIGHT := Vector2(1.8, 2.7)
const SIGN := "BACK IN OR PULL OUT ON GREEN LIGHT ONLY"

var _checks := 0
var _failures := 0
var _app: Node3D
var _scratch: String


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(120.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-docks-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	_app.call("_resume")
	await physics_frame
	var world := _app.get_node("IndustrialLoop")
	var houses := {"shed": world.get("transfer_shed").get_node("Building")}
	for house in world.get("compound").find_children("Warehouse*", "Node3D", false, false):
		houses[String(house.name)] = house
	for label: String in houses:
		_dock_house(label, houses[label] as Node3D)
	_finish()


func _doors(house: Node3D) -> Array[Node3D]:
	var found: Array[Node3D] = []
	var index := 1
	while house.get_node_or_null("DockDoor%d" % index) != null:
		found.append(house.get_node("DockDoor%d" % index) as Node3D)
		index += 1
	return found


func _box(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false) \
			+ ([node] if node is MeshInstance3D else []):
		var part := mesh.global_transform * mesh.get_aabb()
		box = part if first else box.merge(part)
		first = false
	return box


func _dock_house(label: String, house: Node3D) -> void:
	var doors := _doors(house)
	var numbers: Array[String] = []
	var bands: Array[String] = []
	var lights: Array[String] = []
	var signs: Array[String] = []
	for index in range(doors.size()):
		var door := doors[index]
		var number := str(index + 1)
		var plate := house.get_node_or_null("NumberPlate%d" % (index + 1)) as Node3D
		var plate_text := plate.find_child("Number", true, false) as Label3D if plate else null
		var painted := door.find_child("PaintedNumber", true, false) as Label3D
		var over := plate != null and absf(plate.global_position.x - door.global_position.x) \
			< 0.1 and plate.global_position.y > door.global_position.y + 3.05
		if plate_text == null or plate_text.text != number or painted == null \
				or painted.text != number or not over:
			numbers.append(number)
		var band := door.find_child("HiVisBand", true, false) as MeshInstance3D
		var shut := door.find_children("DoorBody", "StaticBody3D", true, false).size() > 0
		var band_ok := band != null and band.get_aabb().size.x >= 2.4
		if band_ok and shut:
			band_ok = _box(band).position.y - door.global_position.y < 0.5
		if not band_ok:
			bands.append(number)
		var lamp := house.get_node_or_null("DockSignal%d" % (index + 1)) as Node3D
		var red := lamp.get_node_or_null("Red") as MeshInstance3D if lamp else null
		var green := lamp.get_node_or_null("Green") as MeshInstance3D if lamp else null
		var hooded := lamp != null and lamp.find_children("Visor*", "MeshInstance3D", true,
			false).size() >= 2
		var ok := red != null and green != null and hooded \
			and red.global_position.y > green.global_position.y \
			and minf(_box(red).size.x, _box(red).size.y) >= LENS_LEAST
		ok = ok and lamp.global_position.y >= LIGHT_HEIGHT.x and lamp.global_position.y \
			<= LIGHT_HEIGHT.y
		if not ok:
			lights.append(number)
		var sign := house.get_node_or_null("CautionSign%d" % (index + 1)) as Node3D
		var words := sign.find_child("Words", true, false) as Label3D if sign else null
		if words == null or not words.text.replace("\n", " ").contains(SIGN) or lamp == null \
				or sign.global_position.distance_to(lamp.global_position) > 1.0:
			signs.append(number)
	_check(not doors.is_empty() and numbers.is_empty(), ("D1 (%s): each of %d doors numbered on a "
		+ "plate above it and painted on its door (wrong: %s)") % [label, doors.size(), numbers])
	_check(bands.is_empty(), "D2 (%s): a hi-vis band along each door's bottom (wrong: %s)"
		% [label, bands])
	_check(lights.is_empty(), ("D3 (%s): a hooded red-over-green traffic light beside each door, "
		+ "its lenses %.2f m at least, %.1f-%.1f m up (wrong: %s)") % [label, LENS_LEAST,
		LIGHT_HEIGHT.x, LIGHT_HEIGHT.y, lights])
	_check(signs.is_empty(), "D4 (%s): its caution sign by each light, \"%s\" (wrong: %s)"
		% [label, SIGN, signs])
	var seals := house.find_children("DockSeal*", "Node3D", false, false)
	var dressed := not seals.is_empty()
	for seal: Node3D in seals:
		var pads := false
		var stripes := false
		for mesh: MeshInstance3D in seal.find_children("*", "MeshInstance3D", true, false):
			for surface in range(mesh.mesh.get_surface_count()):
				var made := mesh.get_surface_override_material(surface) as BaseMaterial3D
				if made == null:
					continue
				var colour := made.albedo_color
				if colour.v < 0.08 and made.roughness >= 0.8:
					pads = true
				if colour.r > 0.7 and colour.g > 0.5 and colour.b < 0.25:
					stripes = true
		dressed = dressed and pads and stripes
	_check(dressed, "D5 (%s): its seals' pads black rubber with yellow guide stripes (%d seals)"
		% [label, seals.size()])


func _finish() -> void:
	print("DOCKS RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	_app.queue_free()
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "The docks' checks finish within 120 s")
	quit(1)
