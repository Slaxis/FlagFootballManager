extends Def
class_name StateDef

var states: Array[Dictionary] = []
var _index: Dictionary = {}  # id (upper) -> state entry

func load_data(raw: Dictionary) -> void:
	states.clear()
	_index.clear()
	var raw_states: Variant = raw.get("states", [])
	if not raw_states is Array:
		return
	for entry: Variant in (raw_states as Array):
		if not entry is Dictionary:
			continue
		var s: Dictionary = (entry as Dictionary).duplicate(true)
		var id_key: String = String(s.get("id", "")).strip_edges().to_upper()
		if id_key == "":
			continue
		s["id"] = id_key
		states.append(s)
		_index[id_key] = s

func merge_data(raw: Dictionary) -> void:
	load_data(raw)

func list_states() -> Array[Dictionary]:
	return states

func list_states_sorted_by_name() -> Array[Dictionary]:
	var copy: Array[Dictionary] = states.duplicate()
	copy.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("name", "")) < String(b.get("name", ""))
	)
	return copy

func get_state(state_id: String) -> Dictionary:
	return _index.get(String(state_id).strip_edges().to_upper(), {})

func has_state(state_id: String) -> bool:
	return _index.has(String(state_id).strip_edges().to_upper())
