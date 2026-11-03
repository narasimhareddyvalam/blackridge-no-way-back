extends Node

signal ringing(caller: String)
signal missed(caller: String)
signal connected
signal line_started(speaker: String, words: String)
signal ended

const RING_SECONDS := 2.2
const RINGS := 4
const AUTO_RINGS := 2
const ATTEMPTS := 3
const CALL_BACK := 2.0
const LINE_BASE := 1.0
const LINE_PER_LETTER := 0.06
const LINE_LONGEST := 3.6
const GAP := 0.35

var caller: String = ""
var active: bool = false
var talking: bool = false
var ringing_now: bool = false
var attempt: int = 0
var elapsed: float = 0.0
var _lines: Array = []
var _line: int = -1
var _line_ends: float = 0.0


func start(name: String, lines: Array) -> void:
	caller = name
	_lines = lines
	_line = -1
	attempt = 0
	active = true
	talking = false
	_ring()


func stop() -> void:
	if active:
		active = false
		talking = false
		ringing_now = false
		ended.emit()


func answer() -> bool:
	if not ringing_now:
		return false
	_connect()
	return true


func can_answer() -> bool:
	return active and ringing_now


func answers_itself() -> bool:
	return attempt >= ATTEMPTS


func line_seconds(words: String) -> float:
	return minf(LINE_BASE + words.length() * LINE_PER_LETTER, LINE_LONGEST)


func _process(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	if ringing_now:
		var rings := AUTO_RINGS if answers_itself() else RINGS
		if elapsed >= rings * RING_SECONDS:
			if answers_itself():
				_connect()
			else:
				ringing_now = false
				elapsed = 0.0
				missed.emit(caller)
		return
	if not talking:
		if elapsed >= CALL_BACK:
			_ring()
		return
	if elapsed >= _line_ends:
		_next_line()


func _ring() -> void:
	attempt += 1
	ringing_now = true
	elapsed = 0.0
	ringing.emit(caller)


func _connect() -> void:
	ringing_now = false
	talking = true
	elapsed = 0.0
	connected.emit()
	_next_line()


func _next_line() -> void:
	_line += 1
	if _line >= _lines.size():
		stop()
		return
	var line: Array = _lines[_line]
	_line_ends = elapsed + line_seconds(line[1]) + GAP
	line_started.emit(line[0], line[1])
