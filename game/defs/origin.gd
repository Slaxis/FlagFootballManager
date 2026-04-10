# Origin definition: backgrounds, schools, turnos, and body config.
extends Def
class_name OriginDef

var origins: Array[Dictionary] = []
var schools: Array[Dictionary] = []
var turnos: Array[Dictionary] = []
var body: Dictionary = {}

var _origin_index: Dictionary = {}
var _school_index: Dictionary = {}
var _turno_index: Dictionary = {}

func load_data(raw: Dictionary) -> void:
	origins.clear()
	schools.clear()
	turnos.clear()
	_origin_index.clear()
	_school_index.clear()
	_turno_index.clear()
	for entry: Variant in raw.get("origins", []):
		if entry is Dictionary:
			origins.append(entry)
			_origin_index[_key(String(entry.get("id", "")))] = entry
	for entry: Variant in raw.get("schools", []):
		if entry is Dictionary:
			schools.append(entry)
			_school_index[_key(String(entry.get("id", "")))] = entry
	for entry: Variant in raw.get("turnos", []):
		if entry is Dictionary:
			turnos.append(entry)
			_turno_index[int(entry.get("id", 0))] = entry
	body = raw.get("body", {}) if raw.get("body", null) is Dictionary else {}

func merge_data(raw: Dictionary) -> void:
	load_data(raw)

func get_origin(origin_id: String) -> Dictionary:
	return _origin_index.get(_key(origin_id), {})

func get_school(school_id: String) -> Dictionary:
	return _school_index.get(_key(school_id), {})

func get_turno(turno_id: int) -> Dictionary:
	return _turno_index.get(turno_id, {})

func turnos_for_school(school_id: String) -> Array[Dictionary]:
	var school: Dictionary = get_school(school_id)
	var ids: Variant = school.get("turnos", [])
	var result: Array[Dictionary] = []
	if ids is Array:
		for tid: Variant in (ids as Array):
			var t: Dictionary = get_turno(int(tid))
			if not t.is_empty():
				result.append(t)
	return result

## Compute total stat modifiers from origin + school + body.
func compute_modifiers(origin_id: String, school_id: String, height: int, weight: int) -> Dictionary:
	var mods: Dictionary = {}
	# Origin
	var origin: Dictionary = get_origin(origin_id)
	for k: String in origin.get("stat_modifiers", {}).keys():
		mods[k] = int(mods.get(k, 0)) + int(origin["stat_modifiers"][k])
	# School
	var school: Dictionary = get_school(school_id)
	for k: String in school.get("stat_modifiers", {}).keys():
		mods[k] = int(mods.get(k, 0)) + int(school["stat_modifiers"][k])
	# Body — height
	var tall_t: int = int(body.get("tall_threshold", 185))
	var short_t: int = int(body.get("short_threshold", 160))
	if height >= tall_t:
		for k: String in body.get("tall_bonus", {}).keys():
			mods[k] = int(mods.get(k, 0)) + int(body["tall_bonus"][k])
	elif height <= short_t:
		for k: String in body.get("short_bonus", {}).keys():
			mods[k] = int(mods.get(k, 0)) + int(body["short_bonus"][k])
	# Body — weight
	var heavy_t: int = int(body.get("heavy_threshold", 85))
	var light_t: int = int(body.get("light_threshold", 55))
	if weight >= heavy_t:
		for k: String in body.get("heavy_bonus", {}).keys():
			mods[k] = int(mods.get(k, 0)) + int(body["heavy_bonus"][k])
	elif weight <= light_t:
		for k: String in body.get("light_bonus", {}).keys():
			mods[k] = int(mods.get(k, 0)) + int(body["light_bonus"][k])
	return mods
