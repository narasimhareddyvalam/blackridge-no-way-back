extends SceneTree
## A capture of Ethan's shock shot (Assignment 7's fourth clip, C67) in the running game, for the
## author's look: the van stopped on the hill road at night where the hit happens, the app's own
## _shock() played (the shot through the windshield, Shock, his hands closing on the wheel), and a
## moment after; the van held on its brakes, as the hold after the hit holds it. The struck man and the crack are not set up here (a fixture: the framing and the
## motion). A Movie Maker run (`--write-movie`, `--fixed-fps 30`).

const LaneKeeper = preload("res://tests/lane_keeper.gd")
const APPROACH := 780


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var app := (load("res://app/first_drive.tscn") as PackedScene).instantiate() as Node3D
	app.get_node("DrivingTrial").checkpoint_path = OS.get_temp_dir().path_join(
		"blackridge-a7-shock-%d.cfg" % OS.get_process_id())
	root.add_child(app)
	await process_frame
	app.call("_resume")
	var van := app.get_node("FreightVan") as CharacterBody3D
	var road: RefCounted = app.get_node("IndustrialLoop").get("road")
	var points: PackedVector3Array = road.points
	var basis := Basis(Vector3.UP, road.call("heading_at", APPROACH))
	van.call("recover", Transform3D(basis, points[APPROACH] + basis.x * 1.0 + Vector3.UP * 0.1))
	van.set("held", true)
	van.set("foot_on_brake", true)
	for wait in range(40):
		await physics_frame
	app.call("_shock")
	await create_timer(4.2).timeout
	quit(0)
