extends Node
## Shared set-up for Assignment 6's preview scenes (CHANGE-BRIEF.md §2–§5). A preview runs the real
## game at the place its part of the brief names, and puts its effect's event or condition on the
## brief's frames. The game starts in the van, as the tests start it, with the driving HUD hidden
## and the mouse free, so a stray mouse cannot turn the driver's view; it never saves, because only
## the main scene gets save paths. A capture window takes the keyboard when it opens, so the preview
## ignores real keys and clicks and keeps only the actions it holds itself. Frames count rendered
## frames from 0, the numbers Movie Maker writes into its file names, and every event is printed
## with its frame. The frames assume the brief's 30 fps with the project's 60 physics ticks a
## second. Each preview's exported settings can also be given after "--" as name=value.
## Capture a strip in a window, from the repository root:
##   HOME="$PWD/.scratch-home" /Applications/Godot.app/Contents/MacOS/Godot --path game \
##     --resolution 1280x800 res://previews/<effect>_preview.tscn \
##     --write-movie "$PWD/captures/<effect>/r0/frame.png" --fixed-fps 30 --quit-after <frames> \
##     -- <name>=<value>

const GAME = preload("res://app/first_drive.tscn")
const LANE := 1.25
const TICKS_PER_FRAME := 2

var app: Node3D
var van: CharacterBody3D
var presentation: Node3D
var effects: Node3D
var world: Node3D
var road: RefCounted
var frame: int = -1

var _ticks: int = 0
var _ticks_before: int = 0
var _held: Array[StringName] = []


func _ready() -> void:
	_apply_arguments()
	app = GAME.instantiate() as Node3D
	add_child(app)
	van = app.get_node("FreightVan")
	presentation = van.get_node("VanPresentation")
	effects = presentation.get("particles")
	world = app.get_node("IndustrialLoop")
	road = world.get("road")
	app.call("_resume")
	(app.get_node("DrivingHud") as CanvasLayer).visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_up()


func _physics_process(_delta: float) -> void:
	_ticks += 1


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		return
	get_viewport().set_input_as_handled()
	for action in InputMap.get_actions():
		if event.is_action(action):
			if _held.has(action):
				Input.action_press(action)
			else:
				Input.action_release(action)


func _exit_tree() -> void:
	for action in _held.duplicate():
		let_go(action)


func _process(_delta: float) -> void:
	frame += 1
	if frame == 2 and _ticks - _ticks_before != TICKS_PER_FRAME:
		push_warning("This preview's frames assume 30 fps with 60 physics ticks a second; " +
			"run it with --fixed-fps 30 (frame 2 ran %d ticks)." % (_ticks - _ticks_before))
	_ticks_before = _ticks
	on_frame(frame)


## Called once the game has started: a preview places the van and its camera here.
func set_up() -> void:
	pass


## Called on every rendered frame, counting from 0.
func on_frame(_number: int) -> void:
	pass


## Physics ticks from now to the last tick of a later frame. Godot runs one tick on frame 0 and
## two on every frame after it at 30 fps, so this is counted from the frame now running.
func ticks_until_end_of(target: int) -> int:
	return (target - frame) * TICKS_PER_FRAME


func on_road(sample: int) -> Transform3D:
	var points: PackedVector3Array = road.points
	var basis := Basis(Vector3.UP, road.call("heading_at", sample))
	return Transform3D(basis, points[sample] + basis.x * LANE + Vector3.UP * 0.1)


func look(eye: Vector3, target: Vector3, fov: float) -> Camera3D:
	var camera := Camera3D.new()
	camera.name = "PreviewCamera"
	camera.fov = fov
	camera.cull_mask = (app.get("title_camera") as Camera3D).cull_mask
	add_child(camera)
	camera.look_at_from_position(eye, target, Vector3.UP)
	camera.make_current()
	return camera


## A fixed seed on these instances only, so every capture of a strip draws the same particles.
func fix_seeds(emitters: Array, first: int) -> void:
	for index in range(emitters.size()):
		var emitter: GPUParticles3D = emitters[index]
		emitter.use_fixed_seed = true
		emitter.seed = first + index


## Presses an action as a player would, and keeps it pressed until let_go().
func hold(action: StringName) -> void:
	if not _held.has(action):
		_held.append(action)
	Input.action_press(action)


func let_go(action: StringName) -> void:
	_held.erase(action)
	Input.action_release(action)


func report(text: String) -> void:
	print("frame %d: %s" % [frame, text])


func _apply_arguments() -> void:
	var settings := {}
	for property in get_property_list():
		var usage: int = property["usage"]
		if usage & PROPERTY_USAGE_EDITOR and usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			settings[property["name"]] = true
	for argument in OS.get_cmdline_user_args():
		var parts := argument.split("=", true, 1)
		if parts.size() != 2 or not settings.has(parts[0]):
			push_warning("Ignored preview argument %s; settings: %s" % [argument, settings.keys()])
			continue
		match typeof(get(parts[0])):
			TYPE_BOOL:
				set(parts[0], parts[1] == "true")
			TYPE_FLOAT:
				set(parts[0], parts[1].to_float())
			TYPE_INT:
				set(parts[0], parts[1].to_int())
			_:
				set(parts[0], parts[1])
