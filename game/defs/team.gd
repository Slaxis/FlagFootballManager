# TeamDef — registry of the clubs a module declares. Each Thing under
# `<module>/things/team/<id>/<id>.json` becomes one entry.
#
# A club Thing carries `id`, `group: "team"`, `name`, `city`, `state` (UF),
# `tier`, `reputation`, `colors` and `squads`. Its region is NOT stored — it
# is derived from the UF through RegionDef, see `region_of()`.
#
# `squads` declares which categories the club fields:
#   "squads": { "masc": true, "fem": false }
# The MVP only plays the men's category, but clubs model both so adding the
# women's side later is a data change, not a refactor.
#
# Tiers: 1 = Serie A, 2 = Serie B, 3 = Serie C, 4 = not federated (plays only
# state and friendly games). The Campeonato Carioca decides which tier a club
# holds nationally.
extends Def
class_name TeamDef

const TIER_MIN := 1
const TIER_MAX := 4
const _REQUIRED: Array[String] = ["name", "city", "state"]

var _by_id: Dictionary = {}   # id -> raw team Dictionary

func load_data(_raw: Dictionary) -> void:
	pass

func add_thing(thing: Dictionary) -> void:
	var id: String = _key(String(thing.get("id", "")))
	if id == "":
		Log.log(self, "error", "TeamDef: team Thing without id")
		return
	for field: String in _REQUIRED:
		if String(thing.get(field, "")).strip_edges() == "":
			Log.log(self, "error", "TeamDef: team '%s' is missing '%s'" % [id, field])
			return
	var tier: int = int(thing.get("tier", TIER_MAX))
	if tier < TIER_MIN or tier > TIER_MAX:
		Log.log(self, "error", "TeamDef: team '%s' has tier %d outside %d..%d" % [id, tier, TIER_MIN, TIER_MAX])
		return
	_by_id[id] = thing

# --- Queries ---

func get_team(id: String) -> Dictionary:
	return _by_id.get(_key(id), {})

func all() -> Array:
	return _by_id.values()

func ids() -> Array:
	return _by_id.keys()

func by_state(uf: String) -> Array:
	var target: String = String(uf).strip_edges().to_upper()
	var out: Array = []
	for team: Dictionary in _by_id.values():
		if String(team.get("state", "")).to_upper() == target:
			out.append(team)
	return out

func by_tier(tier: int) -> Array:
	var out: Array = []
	for team: Dictionary in _by_id.values():
		if int(team.get("tier", TIER_MAX)) == tier:
			out.append(team)
	return out

# Clubs that field the given category ("masc" / "fem").
func by_squad(category: String) -> Array:
	var out: Array = []
	for team: Dictionary in _by_id.values():
		var squads: Dictionary = team.get("squads", {})
		if bool(squads.get(category, false)):
			out.append(team)
	return out

# Strongest first. Ties keep insertion order.
func by_reputation() -> Array:
	var out: Array = _by_id.values().duplicate()
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("reputation", 0)) > int(b.get("reputation", 0)))
	return out

# Region derived from the club's UF. Resolved lazily so RegionDef does not
# have to be loaded before TeamDef.
func region_of(team: Dictionary) -> String:
	var region_def := Drive.def("region") as RegionDef
	if region_def == null:
		return ""
	return region_def.region_of(String(team.get("state", "")))
