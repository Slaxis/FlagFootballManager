# Stat definition: groups and individual stat metadata.
# Loaded from stat.json, overridable by modules.
extends Def
class_name StatDef

var groups: Array[Dictionary] = []
var _stat_index: Dictionary = {}   # stat_id -> Dictionary (stat entry)
var _base_index: Dictionary = {}   # stat_id -> int (group base)

func load_data(raw: Dictionary) -> void:
	groups.clear()
	_stat_index.clear()
	_base_index.clear()
	var raw_groups: Variant = raw.get("groups", [])
	if not raw_groups is Array:
		return
	for entry: Variant in (raw_groups as Array):
		if not entry is Dictionary:
			continue
		var group: Dictionary = entry as Dictionary
		var base: int = int(group.get("base", 0))
		var stats_raw: Variant = group.get("stats", [])
		var stats: Array[Dictionary] = []
		if stats_raw is Array:
			for s_entry: Variant in (stats_raw as Array):
				if not s_entry is Dictionary:
					continue
				var s: Dictionary = s_entry as Dictionary
				var s_id: String = String(s.get("id", "")).strip_edges().to_lower()
				if s_id == "":
					continue
				stats.append(s)
				_stat_index[s_id] = s
				_base_index[s_id] = base
		groups.append({
			"id": String(group.get("id", "")).strip_edges().to_lower(),
			"label": String(group.get("label", "")),
			"base": base,
			"stats": stats,
		})

func merge_data(raw: Dictionary) -> void:
	load_data(raw)

func list_groups() -> Array[Dictionary]:
	return groups

func list_stats() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	for group: Dictionary in groups:
		for s: Dictionary in group["stats"]:
			all.append(s)
	return all

func base_for(stat_id: String) -> int:
	var key: String = String(stat_id).strip_edges().to_lower()
	return _base_index.get(key, 0)

func stat(stat_id: String) -> Dictionary:
	var key: String = String(stat_id).strip_edges().to_lower()
	return _stat_index.get(key, {})

func has_stat(stat_id: String) -> bool:
	var key: String = String(stat_id).strip_edges().to_lower()
	return _stat_index.has(key)
