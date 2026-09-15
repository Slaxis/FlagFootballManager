# ActorDef — the curated people. Real athletes at real clubs, authored as
# Things by whoever is curating a universe.
#
# There is no `actor.json` on purpose, exactly like `team.gd`: every actor in
# here comes from a module, which is what lets a player ship their own league
# without touching the game.
#
# SPARSE ON PURPOSE. A full sheet is 23 numbers, and twelve people at sixteen
# clubs is 4,400 fields nobody is ever going to fill correctly. So a spec says
# only what the curator actually knows:
#
#     {"id": "kings_07", "team": "flag_kings", "plays": ["masc"],
#      "first_name": "...", "last_name": "...", "nickname": "..."}
#
# and the generator fills the rest from the club's reputation. Pin a `quality`,
# a handful of `stats`, a `skills` entry or a perk and those win; leave them out
# and they are rolled. Six lines is a person; twenty-three is the same person
# with every judgement made explicit.
#
# The fill is seeded from the actor's ID, never from the career seed — the
# right winger at Flag Kings is the same man in every career you ever start.
# Only GENERATED squad-fillers move with the seed.
extends Def
class_name ActorDef

const NO_QUALITY := -1

var _by_id: Dictionary = {}       # id -> raw spec
var _order: Array[String] = []

func load_data(_raw: Dictionary) -> void:
	pass

# Later sources MERGE into earlier ones rather than replacing them, so a mod
# that only wants to say "this guy has 100 strength" writes exactly that and
# inherits the rest. `stats` and `skills` merge key by key for the same reason:
# pinning one number must not silently wipe the other twenty-two.
func add_thing(thing: Dictionary) -> void:
	var id: String = _key(String(thing.get("id", "")))
	if id == "":
		Log.log(self, "error", "ActorDef: actor without an id")
		return
	var spec: Dictionary = _by_id.get(id, {}).duplicate(true)
	if spec.is_empty():
		_order.append(id)
	for key: String in thing.keys():
		if (key == "stats" or key == "skills") and thing[key] is Dictionary:
			var merged: Dictionary = spec.get(key, {})
			merged.merge(thing[key] as Dictionary, true)
			spec[key] = merged
		else:
			spec[key] = thing[key]
	spec["id"] = id
	_by_id[id] = spec

# --- Reading ---

func actor_ids() -> Array[String]:
	return _order.duplicate()

func has_actor(id: String) -> bool:
	return _by_id.has(_key(id))

func spec(id: String) -> Dictionary:
	return _by_id.get(_key(id), {})

# Every curated actor at a club, in the category they play. This is what the
# roster is built on top of.
func ids_for(team_id: String, category: String) -> Array[String]:
	var wanted_team: String = _key(team_id)
	var wanted_category: String = _key(category)
	var out: Array[String] = []
	for id: String in _order:
		var entry: Dictionary = _by_id[id]
		if _key(String(entry.get("team", ""))) != wanted_team:
			continue
		if wanted_category != "" and not _plays_of(entry).has(wanted_category):
			continue
		out.append(id)
	return out

func _plays_of(entry: Dictionary) -> Array:
	var out: Array = []
	for value: Variant in (entry.get("plays", []) as Array):
		out.append(_key(String(value)))
	return out

# --- Validation ---
#
# This content is written by people who are not programmers, in a text editor,
# at volume. Every one of these mistakes WILL happen, and each one fails
# quietly if nobody looks: a typo in a club id just makes an athlete vanish
# from the roster with no error anywhere.
#
# Returns one human-readable line per problem, naming the actor. Empty means
# the catalogue is sound. `test_actor_def` runs it over the shipped module, so
# a curator who breaks the JSON turns the suite red before the game opens.
func problems() -> Array[String]:
	var out: Array[String] = []
	var teams := Drive.def("team") as TeamDef
	var stats := Drive.def("stat") as StatDef
	var perks := Drive.def("perk") as PerkDef
	for id: String in _order:
		var entry: Dictionary = _by_id[id]
		var team_id: String = String(entry.get("team", "")).strip_edges()
		if team_id == "":
			out.append("%s: sem clube" % id)
		elif teams != null and teams.get_team(team_id).is_empty():
			out.append("%s: clube '%s' não existe" % [id, team_id])
		var plays: Array = _plays_of(entry)
		if plays.is_empty() and (entry.get("manages", []) as Array).is_empty():
			out.append("%s: não joga nem treina — não faz nada no clube" % id)
		if not Actor.plays_is_valid(plays):
			out.append("%s: modalidades inválidas %s" % [id, str(plays)])
		if stats != null:
			out.append_array(_check_numbers(id, entry.get("stats", {}), stats, true))
			out.append_array(_check_numbers(id, entry.get("skills", {}), stats, false))
		var quality: int = int(entry.get("quality", NO_QUALITY))
		if quality != NO_QUALITY and (quality < 0 or quality > StatDef.STORED_MAX):
			out.append("%s: quality %d fora de 0..%d" % [id, quality, StatDef.STORED_MAX])
		if perks != null:
			for perk_id: Variant in (entry.get("perks", []) as Array):
				if not perks.has_perk(String(perk_id)):
					out.append("%s: perk '%s' não existe" % [id, perk_id])
	return out

func _check_numbers(id: String, values: Variant, stats: StatDef, is_base: bool) -> Array[String]:
	var out: Array[String] = []
	if not values is Dictionary:
		out.append("%s: %s deveria ser um objeto" % [id, "stats" if is_base else "skills"])
		return out
	for key: String in (values as Dictionary).keys():
		var known: bool = stats.has_base(key) if is_base else stats.has_skill(key)
		if not known:
			out.append("%s: '%s' não é %s" % [id, key, "atributo" if is_base else "habilidade"])
			continue
		var value: int = int((values as Dictionary)[key])
		if value < StatDef.STORED_MIN or value > StatDef.STORED_MAX:
			out.append("%s: '%s' = %d, fora de %d..%d" % [
				id, key, value, StatDef.STORED_MIN, StatDef.STORED_MAX])
	return out
