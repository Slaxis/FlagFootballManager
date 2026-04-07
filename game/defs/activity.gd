# Activity definition: daily activities the player can choose.
# Loaded from activity.json, overridable by modules.
extends Def
class_name ActivityDef

var activities: Array[Dictionary] = []
var _index: Dictionary = {}  # id -> Dictionary

func load_data(raw: Dictionary) -> void:
	activities.clear()
	_index.clear()
	var raw_list: Variant = raw.get("activities", [])
	if not raw_list is Array:
		return
	for entry: Variant in (raw_list as Array):
		if not entry is Dictionary:
			continue
		var act: Dictionary = entry as Dictionary
		var act_id: String = String(act.get("id", "")).strip_edges().to_lower()
		if act_id == "":
			continue
		activities.append(act)
		_index[act_id] = act

func merge_data(raw: Dictionary) -> void:
	load_data(raw)

func list_all() -> Array[Dictionary]:
	return activities

func list_for_slot(slot: String) -> Array[Dictionary]:
	var key: String = slot.strip_edges().to_lower()
	var result: Array[Dictionary] = []
	for act: Dictionary in activities:
		var slots: Variant = act.get("slots", [])
		if slots is Array and (slots as Array).has(key):
			result.append(act)
	return result

func get_activity(act_id: String) -> Dictionary:
	return _index.get(act_id.strip_edges().to_lower(), {})
