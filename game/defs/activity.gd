# Activity definition: daily activities the player can choose.
# Loaded from activity.json, overridable by modules.
extends Def
class_name ActivityDef

var activities: Array[Dictionary] = []
var categories: Array[Dictionary] = []
var _index: Dictionary = {}       # id -> Dictionary
var _cat_index: Dictionary = {}   # cat_id -> Dictionary

func load_data(raw: Dictionary) -> void:
	activities.clear()
	categories.clear()
	_index.clear()
	_cat_index.clear()
	var raw_cats: Variant = raw.get("categories", [])
	if raw_cats is Array:
		for entry: Variant in (raw_cats as Array):
			if entry is Dictionary:
				var cat: Dictionary = entry as Dictionary
				categories.append(cat)
				var cat_id: String = String(cat.get("id", "")).strip_edges().to_lower()
				if cat_id != "":
					_cat_index[cat_id] = cat
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

func list_categories() -> Array[Dictionary]:
	return categories

func list_for_slot(slot: String) -> Array[Dictionary]:
	var key: String = slot.strip_edges().to_lower()
	var result: Array[Dictionary] = []
	for act: Dictionary in activities:
		var slots: Variant = act.get("slots", [])
		if slots is Array and (slots as Array).has(key):
			result.append(act)
	return result

func list_for_slot_grouped(slot: String) -> Array[Dictionary]:
	var available: Array[Dictionary] = list_for_slot(slot)
	var by_cat: Dictionary = {}
	for act: Dictionary in available:
		var cat_id: String = String(act.get("category", "other")).strip_edges().to_lower()
		if not by_cat.has(cat_id):
			by_cat[cat_id] = []
		by_cat[cat_id].append(act)
	var result: Array[Dictionary] = []
	for cat: Dictionary in categories:
		var cat_id: String = String(cat.get("id", ""))
		if by_cat.has(cat_id):
			result.append({"type": "header", "category": cat})
			for act: Dictionary in by_cat[cat_id]:
				result.append({"type": "activity", "activity": act})
	# Any uncategorized
	if by_cat.has("other"):
		for act: Dictionary in by_cat["other"]:
			result.append({"type": "activity", "activity": act})
	return result

func get_activity(act_id: String) -> Dictionary:
	return _index.get(act_id.strip_edges().to_lower(), {})

func get_recovery_for(vital_id: String) -> Dictionary:
	var key: String = vital_id.strip_edges().to_lower()
	for act: Dictionary in activities:
		if String(act.get("recovery_for", "")).strip_edges().to_lower() == key:
			return act
	return {}

func get_category(cat_id: String) -> Dictionary:
	return _cat_index.get(cat_id.strip_edges().to_lower(), {})
