extends RefCounted

const TEXT := {
	"walk": "WASD  Walk     SHIFT  Run     MOUSE  Look",
	"drive": "W / S  Accelerate / brake     A / D  Steer",
	"pause": "ESC  Pause and all controls",
	"high_beams": "L  High beams     L again  Lights off     L again  Low beams",
	"wipers": "V  Wipers: fast, off, slow",
	"look": "MOUSE  Look around",
	"recover": "R  Recover the van to the last checkpoint",
}
const LONGEST := {"walk": 30.0, "drive": 15.0, "pause": 5.0, "high_beams": 8.0, "wipers": 6.0,
	"look": 8.0, "recover": 6.0}

var _done := {}
var _current: String = ""
var _left: float = 0.0


func reset() -> void:
	_done.clear()
	_current = ""
	_left = 0.0


func done(lesson: String) -> bool:
	return _done.has(lesson)


func showing() -> String:
	return _current


func learn(lesson: String) -> void:
	_done[lesson] = true
	if _current == lesson:
		_current = ""


func offer(lesson: String) -> void:
	if _current == "" and not _done.has(lesson):
		_current = lesson
		_left = LONGEST[lesson]


func again(lesson: String) -> void:
	_done.erase(lesson)


func tick(delta: float) -> String:
	if _current == "":
		return ""
	_left -= delta
	if _left <= 0.0:
		learn(_current)
		return ""
	return TEXT[_current]
