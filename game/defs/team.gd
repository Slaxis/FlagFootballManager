# TeamDef — registry of the clubs available in a module. Each Thing under
# `<module>/things/team/<id>/<id>.json` becomes one entry.
#
# A team Thing carries `id`, `group: "team"`, `division`, `name`, `city`,
# `state`, `colors`, `budget`, `monthly_fee` and a `roster` of players whose
# attributes match the ids declared in stat.json and skill.json.
#
# Discovery: DefManager scans every active module for Things matching
# `things/team/<id>/<id>.json` and calls `add_thing()` once per entry.
extends Def
class_name TeamDef

var _by_id: Dictionary = {}    # id -> raw team Dictionary

func load_data(_raw: Dictionary) -> void:
	pass

func add_thing(thing: Dictionary) -> void:
	var id: String = String(thing.get("id", ""))
	if id == "":
		return
	_by_id[id] = thing

func get_team(id: String) -> Dictionary:
	return _by_id.get(id, {})

func all() -> Array:
	return _by_id.values()

func ids() -> Array:
	return _by_id.keys()

# Clubs of one division, in declaration order.
func by_division(division: String) -> Array:
	var out: Array = []
	for team: Dictionary in _by_id.values():
		if String(team.get("division", "")) == division:
			out.append(team)
	return out
