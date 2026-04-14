# Technique card definitions: collectible cards used in drills, training, matches.
extends Def
class_name TechniqueDef

var techniques: Array[Dictionary] = []
var starter_personalities: Dictionary = {}
var origin_bonuses: Dictionary = {}

var _index: Dictionary = {}
var _by_personality: Dictionary = {}
var _by_tag: Dictionary = {}

func load_data(raw: Dictionary) -> void:
	techniques.clear()
	_index.clear()
	_by_personality.clear()
	_by_tag.clear()
	starter_personalities = raw.get("starter_personalities", {}) if raw.get("starter_personalities", null) is Dictionary else {}
	origin_bonuses = raw.get("origin_bonuses", {}) if raw.get("origin_bonuses", null) is Dictionary else {}
	for entry: Variant in raw.get("techniques", []):
		if entry is Dictionary:
			var tech: Dictionary = entry as Dictionary
			techniques.append(tech)
			var tid: String = _key(String(tech.get("id", "")))
			_index[tid] = tech
			var pers: String = _key(String(tech.get("personality", "")))
			if not _by_personality.has(pers):
				_by_personality[pers] = []
			_by_personality[pers].append(tech)
			var tags: Variant = tech.get("situation_tags", [])
			if tags is Array:
				for tag: Variant in (tags as Array):
					var t: String = _key(String(tag))
					if not _by_tag.has(t):
						_by_tag[t] = []
					_by_tag[t].append(tech)

func merge_data(raw: Dictionary) -> void:
	load_data(raw)

func get_technique(tech_id: String) -> Dictionary:
	return _index.get(_key(tech_id), {})

func list_all() -> Array[Dictionary]:
	return techniques

func list_by_personality(pers: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for t: Dictionary in _by_personality.get(_key(pers), []):
		result.append(t)
	return result

func list_by_tag(tag: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for t: Dictionary in _by_tag.get(_key(tag), []):
		result.append(t)
	return result

func list_for_context(context: String) -> Array[Dictionary]:
	var ctx: String = _key(context)
	var result: Array[Dictionary] = []
	for t: Dictionary in techniques:
		var contexts: Variant = t.get("valid_contexts", [])
		if contexts is Array and (contexts as Array).has(ctx):
			result.append(t)
	return result

func resolve_cards(card_ids: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for cid: Variant in card_ids:
		var tech: Dictionary = get_technique(String(cid))
		if not tech.is_empty():
			result.append(tech)
	return result

func get_starter_card(personality: String) -> String:
	return String(starter_personalities.get(_key(personality), ""))

func get_origin_bonus(origin_id: String, school_id: String) -> Dictionary:
	var key: String = origin_id + "_" + school_id
	return origin_bonuses.get(key, {}) if origin_bonuses.has(key) else {}

func list_advanced() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for t: Dictionary in techniques:
		if int(t.get("tier", 1)) >= 2 and String(t.get("card_type", "")) == "":
			result.append(t)
	return result
