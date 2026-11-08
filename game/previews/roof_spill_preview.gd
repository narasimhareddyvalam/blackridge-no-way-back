extends "res://previews/preview_fixture.gd"
## A2's frame strip (CHANGE-BRIEF.md §3): the roof spill from the driver's seat as the van brakes
## hard, approaching the site office's parking area under its floodlight, or on the dark valley
## road. The van arrives coasting at 43 km/h and the real brake action is pressed on frame 9, so the
## van's own spill controller sees two ticks of hard braking and spills on frame 10. With
## `retrigger` on, the brake is let off on frame 20 and pressed again on frame 24: a second hard
## brake on frame 25, inside the first spill's life, which the controller must ignore. Fixed seeds
## on this van's spill only. Capture with --quit-after 60 (the brief reads frames 10 to 50).

const OFFICE_APPROACH := 1492
const DARK_VALLEY := 1200
const ARRIVAL_SPEED := 12.0
const BRAKE_FRAME := 9
const RELEASE_FRAME := 20
const AGAIN_FRAME := 24

@export_enum("office", "valley") var place: String = "office"
@export var retrigger: bool = false

var _fired: int = 0
var _ignored: int = 0


func set_up() -> void:
	match place:
		"office":
			van.call("recover", on_road(OFFICE_APPROACH))
		"valley":
			van.call("recover", on_road(DARK_VALLEY))
		_:
			push_error("Unknown place %s: use office or valley" % place)
	van.speed = ARRIVAL_SPEED
	var spill: Node3D = effects.spill
	fix_seeds([spill.get_node("RoofStreams"), spill.get_node("RoofBeads"),
		spill.get_node("Rivulets"), spill.get_node("WaterWash")], 6)


func on_frame(number: int) -> void:
	if number == 0:
		report("A2 at %s, arriving at %.0f km/h, retrigger %s" % [place, ARRIVAL_SPEED * 3.6,
			"on" if retrigger else "off"])
	if number == BRAKE_FRAME or retrigger and number == AGAIN_FRAME:
		hold(&"brake")
		report("brake pressed at %.1f km/h" % (absf(van.actual_speed) * 3.6))
	elif retrigger and number == RELEASE_FRAME:
		let_go(&"brake")
		report("brake let off at %.1f km/h" % (absf(van.actual_speed) * 3.6))
	if effects.spills_fired != _fired:
		_fired = effects.spills_fired
		report("hard brake: the roof spills (roof refills for %.0f s)" % effects.roof_refill)
	if effects.spills_ignored != _ignored:
		_ignored = effects.spills_ignored
		report("hard brake ignored: the first spill is still alive (%s)" % effects.spill_alive())
