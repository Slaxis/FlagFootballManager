# NationDef — where a club sits on the WORLD ruler, not just its own league.
#
# The attribute ruler is absolute: 10 is the best there is, anywhere. So "good
# for a sandlot club in Rio" and "good" are different sentences, and the
# generator needs to know which one a club is speaking. Without this a
# twenty-six-year-old at a neighbourhood club in Piedade ended up with
# international-level coaching, which is the kind of nonsense that only shows
# up when you read a roster.
#
# Two weights, added, and the sum is the club's LEVEL on the quantile ladder:
#
#   nation    how the country stands internationally. Mexico and the USA are
#             a tier above; Brazil is mid; and that is a statement about flag
#             football, not about the countries.
#   division  how the club stands inside its own country.
#
# The consequence is the one that makes the model worth having: a CITY-level
# Mexican club can be stronger than a STATE-level Brazilian one. The MVP only
# ships Rio, but the rule is in place, so adding a continental round later is
# data and not a rewrite.
extends Def
class_name NationDef

const BASE_LEVEL := 1.0

var default_nation: String = "BR"

var _by_id: Dictionary = {}
var _order: Array[String] = []
var _division: Dictionary = {}

func load_data(raw: Dictionary) -> void:
	_by_id.clear()
	_order.clear()
	_division.clear()
	default_nation = _key(String(raw.get("default", "BR")))
	for entry: Variant in (raw.get("division_weight", []) as Array):
		var spec: Dictionary = entry as Dictionary
		_division[int(spec.get("tier", 4))] = float(spec.get("weight", 0.0))
	_ingest(raw.get("nations", []))

func add_thing(thing: Dictionary) -> void:
	_ingest([thing])

func _ingest(entries: Variant) -> void:
	if not entries is Array:
		return
	for entry: Variant in (entries as Array):
		if not entry is Dictionary:
			continue
		var spec: Dictionary = entry as Dictionary
		var id: String = _key(String(spec.get("id", "")))
		if id == "":
			Log.log(self, "error", "NationDef: nation without an id")
			continue
		if not _by_id.has(id):
			_order.append(id)
		_by_id[id] = spec

# --- Reading ---

func nation_ids() -> Array[String]:
	return _order.duplicate()

func has_nation(id: String) -> bool:
	return _by_id.has(_key(id))

func label(id: String) -> String:
	return I18n.text(_by_id.get(_key(id), {}).get("label", id), id)

func weight(id: String) -> float:
	return float(_by_id.get(_key(id), {}).get("weight", 0.0))

func division_weight(tier: int) -> float:
	return float(_division.get(tier, 0.0))

# Where this club sits on the quantile ladder, as a float between 1 and 5.
# Q1 is the floor: there is no level below "plays in the city".
func club_level(club: Dictionary) -> float:
	var nation: String = String(club.get("nation", default_nation))
	var tier: int = int(club.get("tier", 4))
	return clampf(BASE_LEVEL + weight(nation) + division_weight(tier), 1.0, 5.0)
