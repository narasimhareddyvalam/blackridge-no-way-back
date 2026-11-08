extends "res://previews/preview_fixture.gd"
## A1's frame strip (CHANGE-BRIEF.md §2): the wiper flick from the driver's seat, on the dark valley
## road or in the depot bay under its lamps. The wipers really run on fast; this preview only sets
## their stroke's phase on frame 0, so that the game's own top turn, its wiper_swept signal and the
## van's flick controller fire the first flick on frame 10, and the next top turn comes on frame
## 37. With `retrigger` off, the brief's isolated preview, that second top turn passes without a
## flick. Each pooled burst has its own fixed seed. Capture with --quit-after 60 (the brief reads
## frames 10 to 50).

const WrongCargo = preload("res://features/missions/the_wrong_cargo/the_wrong_cargo.gd")
const FAST := 2
const DARK_VALLEY := 1200
const FIRST_TOP_FRAME := 10
## The top turn comes this many ticks before the end of frame 10, so rounding cannot move it into
## frame 11; the next one, a fast cycle (54.5 ticks) later, then ends frame 37.
const LEAD_TICKS := 0.8

@export_enum("valley", "depot") var place: String = "valley"
@export var retrigger: bool = false
@export var speed_kmh: float = 0.0

var _fired: int = 0
var _turns := PackedStringArray()
var _top_turn: float = 0.0
var _fast_rate: float = 0.0
var _quiet: bool = false


func set_up() -> void:
	match place:
		"valley":
			van.call("recover", on_road(DARK_VALLEY))
		"depot":
			van.call("recover", WrongCargo.START)
		_:
			push_error("Unknown place %s: use valley or depot" % place)
	van.speed = speed_kmh / 3.6
	van.wiper_setting = FAST
	var constants := (van.get_script() as GDScript).get_script_constant_map()
	_top_turn = float(constants["WIPER_PARK"]) + float(constants["WIPER_SWEEP"]) * 0.5
	_fast_rate = float(constants["WIPER_CYCLES"][FAST])
	van.wiper_swept.connect(_on_swept)
	for index in range(effects.flicks.size()):
		var flick: Node3D = effects.flicks[index]
		fix_seeds([flick.get_node("BigDrops"), flick.get_node("FineSpray")], 6 + index * 2)


func on_frame(number: int) -> void:
	if number == 0:
		_set_phase()
		report("A1 at %s, %.0f km/h, fast wipers, retrigger %s" % [place, speed_kmh,
			"on" if retrigger else "off"])
	for turn in _turns:
		report(turn)
	_turns.clear()
	if effects.flicks_fired != _fired:
		_fired = effects.flicks_fired
		report("flick %d fired at the blade tip (%d alive)" % [_fired, effects.flicks_alive()])
		if _quiet:
			report("retrigger off: later top turns fire no flick")


## Sets the fast stroke's phase so its top turn ends frame 10, counted from the ticks to come.
func _set_phase() -> void:
	var ticks := ticks_until_end_of(FIRST_TOP_FRAME) - LEAD_TICKS
	var cycle := 0.5 - ticks * _fast_rate / Engine.physics_ticks_per_second
	van.set("_wiper_time", cycle)
	if not is_equal_approx(float(van.call("wiper_cycles")), cycle):
		push_error("The van's wiper phase could not be set, so the flick will not end frame 10")


## Runs after the van's flick controller, which connected first. With retrigger off it then stops
## the controller hearing later top turns, so only the first burst is drawn.
func _on_swept() -> void:
	var top: bool = van.wiper_angle >= _top_turn
	_turns.append("wiper top turn" if top else "wiper park turn")
	if retrigger or not top or effects.flicks_fired == 0:
		return
	for connection: Dictionary in van.wiper_swept.get_connections():
		var callable: Callable = connection["callable"]
		if callable.get_object() == effects:
			van.wiper_swept.disconnect(callable)
			_quiet = true
