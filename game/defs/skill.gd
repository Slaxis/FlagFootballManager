# Skill definition: trainable flag football skills.
# Loaded from skill.json, overridable by modules.
extends Def
class_name SkillDef

var groups: Array[Dictionary] = []
var _skill_index: Dictionary = {}  # skill_id -> Dictionary

func load_data(raw: Dictionary) -> void:
	groups.clear()
	_skill_index.clear()
	var raw_groups: Variant = raw.get("groups", [])
	if not raw_groups is Array:
		return
	for entry: Variant in (raw_groups as Array):
		if not entry is Dictionary:
			continue
		var group: Dictionary = entry as Dictionary
		var stats_raw: Variant = group.get("stats", [])
		var skills: Array[Dictionary] = []
		if stats_raw is Array:
			for s_entry: Variant in (stats_raw as Array):
				if not s_entry is Dictionary:
					continue
				var s: Dictionary = s_entry as Dictionary
				var s_id: String = String(s.get("id", "")).strip_edges().to_lower()
				if s_id == "":
					continue
				skills.append(s)
				_skill_index[s_id] = s
		groups.append({
			"id": String(group.get("id", "")).strip_edges().to_lower(),
			"label": group.get("label", ""),
			"stats": skills,
		})

func merge_data(raw: Dictionary) -> void:
	load_data(raw)

func list_groups() -> Array[Dictionary]:
	return groups

func list_skills() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	for group: Dictionary in groups:
		for s: Dictionary in group["stats"]:
			all.append(s)
	return all

func skill(skill_id: String) -> Dictionary:
	var key: String = String(skill_id).strip_edges().to_lower()
	return _skill_index.get(key, {})

func has_skill(skill_id: String) -> bool:
	var key: String = String(skill_id).strip_edges().to_lower()
	return _skill_index.has(key)
