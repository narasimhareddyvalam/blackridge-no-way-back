extends SceneTree
## The run sheet handed over at each gate's booth (#355; the author's choices: the guard reaches
## for it, from her chair, and hands it back): with the van tucked in by the booth, the sheet is
## held out at the driver's window; the guard leans over her counter and takes it, her hand on it
## before it moves; she reads it in front of her, watching it; she hands it back to the window
## and lets go, and it goes back in; only then does the gate open. Out of her reach (the van too
## far from the booth), E does nothing and the objective says to pull in closer.

## Mission 2 begun, so its gates watch the van as they do in play.
const SAVE := "[save]\nversion=2\nmission=\"the_wrong_cargo\"\n\n[cargo]\nstage=0\n"
const CLOSE_GAP := 0.4
const FAR_GAP := 1.3
const EYE := Vector3(-0.45, 1.8, -0.72)
const ON_SHEET := 0.05
const READ_LEAST := 2.5
const LOOK_NEAR := 0.25

var _checks := 0
var _failures := 0
var _app: Node3D
var _scratch: String
var _van: CharacterBody3D


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print(("PASS: " if condition else "FAIL: ") + description)


func _run() -> void:
	create_timer(240.0, true, false, true).timeout.connect(_timeout)
	_scratch = OS.get_temp_dir().path_join("blackridge-handover-%d-%d.cfg" % [
		OS.get_process_id(), Time.get_ticks_usec()])
	var file := FileAccess.open(_scratch, FileAccess.WRITE)
	file.store_string(SAVE)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate()
	_app.get_node("DrivingTrial").checkpoint_path = _scratch
	root.add_child(_app)
	await process_frame
	_app.call("_resume")
	await physics_frame
	_van = _app.get_node("FreightVan") as CharacterBody3D
	var world := _app.get_node("IndustrialLoop")
	var shed := world.get("transfer_shed") as Node3D
	var compound := world.get("compound") as Node3D
	await _gate("shed", shed, shed.get("_booth_node") as Node3D)
	await _gate("compound", compound, compound.get("booth") as Node3D)
	_finish()


## The van stopped with its driver's window level with the booth's opening, its side `gap` from
## the booth's service face.
func _park(booth: Node3D, gap: float) -> void:
	var out := booth.global_basis.x.normalized()
	out.y = 0.0
	out = out.normalized()
	var forward := -out.cross(Vector3.UP)
	var opening: Vector3 = booth.call("opening_centre")
	var basis := Basis(out, Vector3.UP, out.cross(Vector3.UP))
	var origin := opening + out * (gap + 1.0) + forward * EYE.z
	origin.y = booth.global_position.y - 0.25
	_van.call("recover", Transform3D(basis, origin))
	for frame in range(30):
		await physics_frame


func _gate(label: String, gate: Node3D, booth: Node3D) -> void:
	if booth == null or not booth.has_method("start_handover"):
		_check(false, "H1 (%s): the booth hands the run sheet over (no handover)" % label)
		return
	await _park(booth, FAR_GAP)
	var far_level := absf(float(gate.call("window_gap"))) <= 0.4
	var far_refused := not bool(gate.call("vehicle_at_window")) \
		and not bool(gate.call("window_in_reach"))
	await _park(booth, CLOSE_GAP)
	var close_ok := bool(gate.call("vehicle_at_window")) and bool(gate.call("window_in_reach"))
	_check(far_level and far_refused and close_ok, ("H1 (%s): out of her reach E does nothing; "
		+ "tucked in by the booth it hands the sheet over (far level %s refused %s, close %s)")
		% [label, far_level, far_refused, close_ok])
	gate.call("hand_run_sheet")
	var sheet := booth.get("sheet") as Node3D
	var held_out := false
	var took := false
	var nearest := INF
	var moved_early := false
	var read_for := 0.0
	var watched := true
	var given_back := false
	var went_in := false
	var opened_early := false
	var start := Vector3.ZERO
	var waited := 0.0
	while waited < 25.0:
		await physics_frame
		waited += 1.0 / 60.0
		var phase := String(booth.get("handover"))
		if sheet == null:
			break
		if phase == "offered" and sheet.visible:
			held_out = true
			start = sheet.global_position
		var grip: Vector3 = booth.call("grip_point")
		if phase == "taking" and start != Vector3.ZERO \
				and sheet.global_position.distance_to(start) > 0.02:
			moved_early = true
		if phase == "taking":
			nearest = minf(nearest, grip.distance_to(booth.call("sheet_grip")))
		if phase == "bringing" and not took:
			took = grip.distance_to(booth.call("sheet_grip")) < ON_SHEET
		if phase == "reading":
			read_for += 1.0 / 60.0
			var look := booth.get("_look") as Node3D
			watched = watched and look != null \
				and look.global_position.distance_to(sheet.global_position) < LOOK_NEAR
		if phase == "letting_go":
			given_back = sheet.global_position.distance_to(_van.call("window_hold") as Vector3) \
				< 0.3
		if bool(gate.call("checking")) == false and not bool(booth.call("sheet_back")):
			opened_early = true
		if bool(booth.call("sheet_back")):
			went_in = not sheet.visible
			break
	_check(held_out and took and not moved_early, ("H2 (%s): the sheet held out at the driver's "
		+ "window, her hand on it before it moves (held out %s, took %s, nearest %.2f m, moved "
		+ "early %s)") % [label, held_out, took, nearest, moved_early])
	_check(read_for >= READ_LEAST and watched, ("H3 (%s): she reads it in front of her for %.1f s, "
		+ "watching it (watched %s)") % [label, read_for, watched])
	_check(given_back and went_in, ("H4 (%s): she hands it back to the window and it goes back in "
		+ "(back at the window %s, in %s)") % [label, given_back, went_in])
	var opened := false
	for frame in range(120):
		await physics_frame
		if not bool(gate.call("checking")):
			opened = true
			break
	_check(opened and not opened_early, ("H5 (%s): the gate's check ends only once the sheet is "
		+ "back (ended %s, early %s)") % [label, opened, opened_early])


func _finish() -> void:
	print("HANDOVER RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks, _failures])
	_app.queue_free()
	if FileAccess.file_exists(_scratch):
		DirAccess.remove_absolute(_scratch)
	quit(0 if _failures == 0 else 1)


func _timeout() -> void:
	_check(false, "The handover's checks finish within 240 s")
	quit(1)
