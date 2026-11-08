extends "res://previews/preview_fixture.gd"
## B2's frame strip (CHANGE-BRIEF.md §5): the exhaust vapour at the van's rear, parked at the site
## office under its floodlight, seen from behind the van or through the van's own reverse camera.
## The engine is switched off at the start and started with the real ignition on frame 10; the
## real accelerate action is held from frame 40 to frame 80, so the van pulls a few metres forward
## and the plume trails into its wake; then the brake is pressed, as a driver stopping would, and
## the engine is switched off on frame 100 with the van standing. The van's own controller turns
## all of this into the plume. Fixed seed on this van's plume only. Capture with --quit-after 190.

const ENGINE_ON_FRAME := 10
const THROTTLE_FRAME := 40
const THROTTLE_OFF_FRAME := 80
const ENGINE_OFF_FRAME := 100
## The rear view, in the van's frame where it starts: a standing eye behind the van on the driver's
## side, looking just behind the tailpipe.
const REAR_EYE := Vector3(-1.8, 1.6, 7.5)
const REAR_LOOK := Vector3(-0.6, 0.6, 3.6)
const REAR_FOV := 50.0
## The frames the brief reads.
const STRIP := [10, 20, 30, 40, 55, 80, 100, 130, 180]

@export_enum("rear", "reverse_camera") var view: String = "rear"

var _camera: Camera3D
var _reverse: Camera3D
var _start := Vector3.ZERO


func set_up() -> void:
	van.call("switch_off")
	_start = van.global_position
	fix_seeds([effects.exhaust], 6)
	match view:
		"rear":
			_camera = look(van.global_transform * REAR_EYE, van.global_transform * REAR_LOOK,
				REAR_FOV)
		"reverse_camera":
			_reverse = (presentation.get("reverse_view") as SubViewport).get_camera_3d()
			_camera = look(_reverse.global_position, _reverse.global_position - Vector3.FORWARD,
				_reverse.fov)
			_camera.cull_mask = _reverse.cull_mask
			_camera.attributes = _reverse.attributes
			_camera.environment = _reverse.environment
			_camera.near = _reverse.near
			_camera.far = _reverse.far
		_:
			push_error("Unknown view %s: use rear or reverse_camera" % view)


## The van acts on its next physics tick, so each change is made on the frame before the one
## the brief names, and is in force while that frame runs.
func on_frame(number: int) -> void:
	if _reverse != null:
		_camera.global_transform = _reverse.global_transform
	if number == 0:
		report("B2 at the site office, %s view, engine off" % view)
	match number + 1:
		ENGINE_ON_FRAME:
			van.call("start_engine")
			report("ignition, in force from frame %d" % ENGINE_ON_FRAME)
		THROTTLE_FRAME:
			hold(&"accelerate")
			report("accelerate held from frame %d" % THROTTLE_FRAME)
		THROTTLE_OFF_FRAME:
			let_go(&"accelerate")
			hold(&"brake")
			report("accelerate let off and brake pressed from frame %d, at %.1f km/h, %.1f m on"
				% [THROTTLE_OFF_FRAME, absf(van.actual_speed) * 3.6,
				van.global_position.distance_to(_start)])
		ENGINE_OFF_FRAME:
			van.call("switch_off")
			report("engine off from frame %d, at %.1f km/h, %.1f m on" % [ENGINE_OFF_FRAME,
				absf(van.actual_speed) * 3.6, van.global_position.distance_to(_start)])
	if number in STRIP:
		report("amount_ratio %.2f, emitting %s" % [effects.exhaust.amount_ratio,
			effects.exhaust.emitting])
