# Drill definitions: sequences of situations for physical/position drills.
extends Def
class_name DrillDef

var drills: Array[Dictionary] = []
var _index: Dictionary = {}
var _by_category: Dictionary = {}

func load_data(raw: Dictionary) -> void:
	drills.clear()
	_index.clear()
	_by_category.clear()
	for entry: Variant in raw.get("drills", []):
		if entry is Dictionary:
			var drill: Dictionary = entry as Dictionary
			drills.append(drill)
			_index[_key(String(drill.get("id", "")))] = drill
			var cat: String = _key(String(drill.get("category", "")))
			if not _by_category.has(cat):
				_by_category[cat] = []
			_by_category[cat].append(drill)

func merge_data(raw: Dictionary) -> void:
	load_data(raw)

func get_drill(drill_id: String) -> Dictionary:
	return _index.get(_key(drill_id), {})

func list_all() -> Array[Dictionary]:
	return drills

func list_by_category(cat: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for d: Dictionary in _by_category.get(_key(cat), []):
		result.append(d)
	return result

func get_situations(drill_id: String) -> Array[Dictionary]:
	var drill: Dictionary = get_drill(drill_id)
	var raw: Variant = drill.get("situations", [])
	var result: Array[Dictionary] = []
	if raw is Array:
		for s: Variant in (raw as Array):
			if s is Dictionary:
				result.append(s as Dictionary)
	return result
