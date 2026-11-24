extends SceneTree
## Maya's lines at the service gate (#469, #470): the author found her handing Ethan the rifle
## not believable. The scene keeps the handover and says why.
## G1 she gives the reason she does not go in herself: Adrian's men know her face.
## G2 she says where the rifle came from: Adrian's, from his car.
## G3 the count she gives is the rifle's real magazine (`handgun.gd` MAGAZINE, 30) with one
##    spare, not "Fifteen".
## G4 the lines run in order, none starting before the one before it has ended.

const LastRun = preload("res://features/missions/last_run/last_run.gd")
const Handgun = preload("res://features/weapons/pistol/handgun.gd")
const WORDS := {30: "Thirty"}

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	var lines: Array = LastRun.MAYA_GUN
	var text := " ".join(lines.map(func(line: Array) -> String: return String(line[2])))
	_check(text.contains("know my face"), "G1 Maya says why she does not go in herself")
	_check(text.contains("Adrian's") and text.contains("his car"),
		"G2 Maya says the rifle is Adrian's, from his car")
	var count: String = WORDS.get(Handgun.MAGAZINE, "?")
	_check(text.contains("%s in it, and one spare" % count) and not text.contains("Fifteen"),
		"G3 Maya's count is the magazine's: %s (%d)" % [count, Handgun.MAGAZINE])
	var ordered := true
	for index in range(1, lines.size()):
		var before: Array = lines[index - 1]
		if float(lines[index][0]) < float(before[0]) + float(before[3]):
			ordered = false
	_check(ordered, "G4 the %d lines run in order without overlapping" % lines.size())
	print("MAYA GUN LINES RESULT: %d/%d passed; %d failed" % [_checks - _failures, _checks,
		_failures])
	quit(1 if _failures > 0 else 0)


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: %s" % description)
	else:
		_failures += 1
		print("FAIL: %s" % description)
