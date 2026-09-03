extends Def
class_name LocationTypeDef

var types: Array[Dictionary] = []
var _index: Dictionary = {}  # id -> entry

func load_data(raw: Dictionary) -> void:
	types.clear()
	_index.clear()
	var raw_types: Variant = raw.get("types", [])
	if not raw_types is Array:
		return
	for entry: Variant in (raw_types as Array):
		if not entry is Dictionary:
			continue
		var t: Dictionary = (entry as Dictionary).duplicate(true)
		var id_key: String = _key(String(t.get("id", "")))
		if id_key == "":
			continue
		t["id"] = id_key
		types.append(t)
		_index[id_key] = t

func merge_data(raw: Dictionary) -> void:
	load_data(raw)

func list_types() -> Array[Dictionary]:
	return types

func get_type(type_id: String) -> Dictionary:
	return _index.get(_key(type_id), {})

func has_type(type_id: String) -> bool:
	return _index.has(_key(type_id))

func color_for(type_id: String) -> Color:
	var entry: Dictionary = get_type(type_id)
	var hex: String = String(entry.get("color", ""))
	if hex.begins_with("#"):
		return Color(hex)
	return Color(0.5, 0.5, 0.5)
