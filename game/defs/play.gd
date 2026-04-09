# Play definition: routes, coverages, and rushes for the card minigame.
# Loaded from play.json, overridable by modules.
extends Def
class_name PlayDef

var plays: Array[Dictionary] = []
var categories: Array[Dictionary] = []
var _index: Dictionary = {}
var _cat_index: Dictionary = {}

func load_data(raw: Dictionary) -> void:
	plays.clear()
	categories.clear()
	_index.clear()
	_cat_index.clear()
	var raw_cats: Variant = raw.get("categories", [])
	if raw_cats is Array:
		for entry: Variant in (raw_cats as Array):
			if entry is Dictionary:
				categories.append(entry as Dictionary)
				var cat_id: String = String((entry as Dictionary).get("id", "")).strip_edges().to_lower()
				if cat_id != "":
					_cat_index[cat_id] = entry as Dictionary
	var raw_list: Variant = raw.get("plays", [])
	if not raw_list is Array:
		return
	for entry: Variant in (raw_list as Array):
		if not entry is Dictionary:
			continue
		var play: Dictionary = entry as Dictionary
		var play_id: String = String(play.get("id", "")).strip_edges().to_lower()
		if play_id == "":
			continue
		plays.append(play)
		_index[play_id] = play

func merge_data(raw: Dictionary) -> void:
	load_data(raw)

func list_all() -> Array[Dictionary]:
	return plays

func list_by_category(cat_id: String) -> Array[Dictionary]:
	var key: String = cat_id.strip_edges().to_lower()
	var result: Array[Dictionary] = []
	for play: Dictionary in plays:
		if String(play.get("category", "")).strip_edges().to_lower() == key:
			result.append(play)
	return result

func list_by_max_difficulty(max_diff: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for play: Dictionary in plays:
		if int(play.get("difficulty", 1)) <= max_diff:
			result.append(play)
	return result

func list_routes(max_diff: int = 99) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for play: Dictionary in plays:
		if String(play.get("category", "")) == "route" and int(play.get("difficulty", 1)) <= max_diff:
			result.append(play)
	return result

func get_play(play_id: String) -> Dictionary:
	return _index.get(play_id.strip_edges().to_lower(), {})

func get_random_distractors(correct: Dictionary, count: int, pool: Array[Dictionary]) -> Array[Dictionary]:
	var correct_id: String = String(correct.get("id", ""))
	var candidates: Array[Dictionary] = []
	for play: Dictionary in pool:
		if String(play.get("id", "")) != correct_id:
			candidates.append(play)
	candidates.shuffle()
	var result: Array[Dictionary] = []
	for i: int in mini(count, candidates.size()):
		result.append(candidates[i])
	return result

func list_by_drill_type(drill_type: String) -> Array[Dictionary]:
	var key: String = drill_type.strip_edges().to_lower()
	var result: Array[Dictionary] = []
	for play: Dictionary in plays:
		if String(play.get("drill_type", "")).strip_edges().to_lower() == key:
			result.append(play)
	return result

func get_drill_rounds(drill_type: String, count: int, max_diff: int = 99) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for play: Dictionary in list_by_drill_type(drill_type):
		if int(play.get("difficulty", 1)) <= max_diff:
			pool.append(play)
	pool.shuffle()
	var result: Array[Dictionary] = []
	for i: int in mini(count, pool.size()):
		result.append(pool[i])
	return result
