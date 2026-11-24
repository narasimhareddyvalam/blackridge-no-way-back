extends SceneTree
## Two short Mission 3 shots for the pitch film (#469, #474), filmed alone because a 4K run of the
## whole mission from the gate ran the author's Mac out of memory with other apps open. Both start
## from Last Run's stage 4 save (the game's checkpoint at the hangar's office) and are set up as
## `capture_rescue.gd` and `capture_ending.gd` set them up; after the setup the game plays itself.
##   -- lily    Ethan by Lily in the office takes her hand (E, the real action) and walks her out
##              (the move key held), from the side door's corridor toward the hangar.
##   -- ending  Ethan, Maya and Lily at the service gate; the story set to "home": the reunion,
##              its cards ("HE TOLD THEM EVERYTHING", "SIX MONTHS LATER"), then the family home.
## Run windowed with Movie Maker, from the repository root:
##   HOME=<empty folder> Godot --path game --resolution 3840x2160 --fixed-fps 30 \
##     --write-movie <absolute .ogv> --quit-after <frames> \
##     --script ../tools/captures/film_pitch_shots.gd -- <lily|ending>

const SAVE := "[save]\nversion=2\nmission=\"last_run\"\n\n[run]\nstage=4\n"

var _app: Node3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var shot := args[0] if not args.is_empty() else "lily"
	var progress := OS.get_user_data_dir().path_join("film_pitch_shots.cfg")
	var file := FileAccess.open(progress, FileAccess.WRITE)
	file.store_string(SAVE)
	file.close()
	_app = (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	_app.get_node("DrivingTrial").checkpoint_path = progress
	root.add_child(_app)
	await process_frame
	await process_frame
	_app.call("_begin")
	await _wait(1.5)
	print("FILM shot %s" % shot)
	if shot == "ending":
		await _ending()
	else:
		await _lily()
	print("FILM done")


func _lily() -> void:
	var driver := _app.get("driver") as CharacterBody3D
	var run := _app.get("run") as Node
	var lily := run.get("lily") as Node3D
	var field := _app.get_node("IndustrialLoop").get("harbour_flats").get("airfield") as Node3D
	_app.call("_stand_ethan", lily.global_position + Vector3(0.0, 0.0, -1.3), lily.global_position)
	await _wait(1.0)
	driver.call("look_toward", Vector3.BACK)
	await _wait(1.5)
	run.call("do_foot_action", driver.global_position)
	print("FILM her hand: %s" % run.get("story"))
	await _wait(1.0)
	var door: Vector3 = field.get("office_door")
	_app.call("_stand_ethan", door + Vector3(0.0, 0.0, -4.0), door + Vector3(0.0, 0.0, -10.0))
	await _wait(0.2)
	lily.global_position = driver.global_position + Vector3(-0.45, 0.0, 0.3)
	lily.call("lead", driver)
	driver.call("look_toward", Vector3.FORWARD)
	Input.action_press("accelerate")
	print("FILM walking out")
	await _wait(14.0)
	Input.action_release("accelerate")


func _ending() -> void:
	var run := _app.get("run") as Node
	var maya := run.get("maya") as Node3D
	var lily := run.get("lily") as Node3D
	var field := _app.get_node("IndustrialLoop").get("harbour_flats").get("airfield") as Node3D
	var gate: Vector3 = field.get("service_gate")
	_app.call("_stand_ethan", gate + Vector3(0.5, 0.0, 1.5), maya.global_position)
	lily.call("go_to", maya.global_position + Vector3(0.6, 0.0, 0.4), maya.global_position)
	await _wait(1.0)
	run.set("story", "home")
	print("FILM the ending begins")
	var epilogue: Node = null
	while epilogue == null:
		await physics_frame
		epilogue = run.get("epilogue") as Node
	print("FILM the home")
	await _wait(25.0)


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout
