extends RefCounted

enum Read { OFF, MISSING, LOADED, CORRUPT, NEWER }

const SECTION := "save"
const KEY := "version"

var path: String
var version: int
var status: Read = Read.OFF
var _locked: bool = false


func _init(file_path: String, file_version: int) -> void:
	path = file_path
	version = file_version


func read(valid: Callable) -> ConfigFile:
	if path.is_empty():
		status = Read.OFF
		return null
	if not FileAccess.file_exists(path):
		status = Read.MISSING
		return null
	var config := ConfigFile.new()
	var found: Variant = _version_in(config)
	if found is int and found > version:
		status = Read.NEWER
		_locked = true
		push_warning("%s is from a newer version (%d); it is left as it is, and not saved this "
			% [path, found] + "session.")
		return null
	if found is int and found == version and valid.call(config):
		status = Read.LOADED
		return config
	status = Read.CORRUPT
	_set_aside()
	return null


func write(config: ConfigFile) -> Error:
	if path.is_empty():
		return ERR_UNAVAILABLE
	if _locked or _newer_on_disk():
		_locked = true
		push_warning("%s was not saved: the file there must not be replaced." % path)
		return ERR_UNAVAILABLE
	var out := ConfigFile.new()
	out.set_value(SECTION, KEY, version)
	for section in config.get_sections():
		for key in config.get_section_keys(section):
			out.set_value(section, key, config.get_value(section, key))
	var temporary := path + ".tmp"
	var result := out.save(temporary)
	if result == OK:
		result = DirAccess.rename_absolute(temporary, path)
	if result != OK:
		if FileAccess.file_exists(temporary):
			DirAccess.remove_absolute(temporary)
		push_warning("Could not save %s: %s" % [path, error_string(result)])
	return result


func _version_in(config: ConfigFile) -> Variant:
	if config.load(path) != OK or not config.has_section_key(SECTION, KEY):
		return null
	return config.get_value(SECTION, KEY)


func _newer_on_disk() -> bool:
	if not FileAccess.file_exists(path):
		return false
	var found: Variant = _version_in(ConfigFile.new())
	return found is int and found > version


func _set_aside() -> void:
	if DirAccess.rename_absolute(path, path + ".corrupt") == OK:
		push_warning("Could not read %s; it was kept as %s.corrupt." % [path, path])
	else:
		_locked = true
		push_warning("Could not read %s, nor move it aside; it is left as it is, and not saved "
			% path + "this session.")
