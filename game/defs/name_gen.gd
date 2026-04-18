extends Def
class_name NameGenDef

var first_male: Array[String] = []
var first_female: Array[String] = []
var last_names: Array[String] = []
var nicknames_male: Array[String] = []
var nicknames_female: Array[String] = []
var team_prefixes: Array[String] = []
var team_suffixes: Array[String] = []
var neighborhoods: Array[String] = []
var street_patterns: Array[String] = []
var place_patterns: Array[String] = []

func load_data(raw: Dictionary) -> void:
	first_male       = _load_strings(raw.get("first_male", []))
	first_female     = _load_strings(raw.get("first_female", []))
	last_names       = _load_strings(raw.get("last", []))
	nicknames_male   = _load_strings(raw.get("nicknames_male", []))
	nicknames_female = _load_strings(raw.get("nicknames_female", []))
	team_prefixes    = _load_strings(raw.get("team_prefixes", []))
	team_suffixes    = _load_strings(raw.get("team_suffixes", []))
	neighborhoods    = _load_strings(raw.get("neighborhoods", []))
	street_patterns  = _load_strings(raw.get("street_patterns", []))
	place_patterns   = _load_strings(raw.get("place_patterns", []))

func merge_data(raw: Dictionary) -> void:
	# Append rather than replace so user modules can extend the pools.
	first_male.append_array(_load_strings(raw.get("first_male", [])))
	first_female.append_array(_load_strings(raw.get("first_female", [])))
	last_names.append_array(_load_strings(raw.get("last", [])))
	nicknames_male.append_array(_load_strings(raw.get("nicknames_male", [])))
	nicknames_female.append_array(_load_strings(raw.get("nicknames_female", [])))
	team_prefixes.append_array(_load_strings(raw.get("team_prefixes", [])))
	team_suffixes.append_array(_load_strings(raw.get("team_suffixes", [])))
	neighborhoods.append_array(_load_strings(raw.get("neighborhoods", [])))
	street_patterns.append_array(_load_strings(raw.get("street_patterns", [])))
	place_patterns.append_array(_load_strings(raw.get("place_patterns", [])))

func _load_strings(raw: Variant) -> Array[String]:
	var out: Array[String] = []
	if not raw is Array:
		return out
	for v: Variant in (raw as Array):
		var s: String = String(v).strip_edges()
		if s != "":
			out.append(s)
	return out

# --- Public API. All methods accept a RandomNumberGenerator for determinism.

func random_first_name(gender: String, rng: RandomNumberGenerator) -> String:
	var pool: Array[String] = first_female if gender.to_lower().begins_with("f") else first_male
	return _pick(pool, rng)

func random_last_name(rng: RandomNumberGenerator) -> String:
	return _pick(last_names, rng)

func random_nickname(gender: String, rng: RandomNumberGenerator) -> String:
	var pool: Array[String] = nicknames_female if gender.to_lower().begins_with("f") else nicknames_male
	return _pick(pool, rng)

func random_full_name(gender: String, rng: RandomNumberGenerator) -> String:
	var first: String = random_first_name(gender, rng)
	var last: String = random_last_name(rng)
	if first == "" and last == "":
		return ""
	return (first + " " + last).strip_edges()

func random_team_name(rng: RandomNumberGenerator) -> String:
	var prefix: String = _pick(team_prefixes, rng)
	var suffix: String = _pick(team_suffixes, rng)
	if prefix == "" and suffix == "":
		return "Time"
	return (prefix + " " + suffix).strip_edges()

func random_neighborhood(rng: RandomNumberGenerator) -> String:
	return _pick(neighborhoods, rng)

func random_street_name(rng: RandomNumberGenerator) -> String:
	var pattern: String = _pick(street_patterns, rng)
	return _fill_pattern(pattern, rng)

func random_place_name(rng: RandomNumberGenerator) -> String:
	var pattern: String = _pick(place_patterns, rng)
	return _fill_pattern(pattern, rng)

func _fill_pattern(pattern: String, rng: RandomNumberGenerator) -> String:
	if pattern == "":
		return ""
	var result: String = pattern
	# Supported placeholders:
	#   {last} {first_male} {first_female} {neighborhood}
	if result.contains("{last}"):
		result = result.replace("{last}", random_last_name(rng))
	if result.contains("{first_male}"):
		result = result.replace("{first_male}", random_first_name("m", rng))
	if result.contains("{first_female}"):
		result = result.replace("{first_female}", random_first_name("f", rng))
	if result.contains("{neighborhood}"):
		result = result.replace("{neighborhood}", random_neighborhood(rng))
	return result

func _pick(pool: Array[String], rng: RandomNumberGenerator) -> String:
	if pool.is_empty():
		return ""
	var idx: int = rng.randi() % pool.size()
	return pool[idx]
