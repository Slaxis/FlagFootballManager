# Rosters — who plays where, right now.
#
# Three layers meet here, and each has exactly one job:
#
#   ActorDef         the curated truth. Real athletes at real clubs. Immutable.
#   ActorGenerator   fills the gaps, and feeds the market from here on.
#   Rosters          the live state. This is the one that CHANGES.
#
# It has to be state and not a formula. A roster derived from the career seed
# would be free and reproducible and completely wrong the moment anybody is
# signed, injured, trained or retired — which is the entire rest of the game.
# So it is generated once, on first read, and owned from then on.
#
# Filled per club and per category, lazily: sixteen clubs would be roughly two
# hundred people invented at career start so the player could look at twelve of
# them. Every club still derives from the career seed, so the same seed builds
# the same league — what changes is that afterwards it is a thing that happened
# rather than a thing that is recomputed.
class_name Rosters
extends Record

# How many people a club carries, by tier. A sandlot side scrapes a squad
# together; a tier-1 club has people who do not get on the field.
const SIZE_BY_TIER: Dictionary = {1: 15, 2: 13, 3: 11, 4: 9}
const DEFAULT_SIZE := 10
const SIZE_JITTER := 2

# team_id -> category -> Array[Actor]
var _squads: Dictionary = {}
var career_seed: int = 0

static func make(seed_value: int) -> Rosters:
	var rosters := Rosters.new()
	rosters.career_seed = seed_value
	return rosters

# The squad, built on first ask. Curated actors always ALL make it in — a
# curator who wrote eighteen people meant eighteen — and the generator only
# tops up when the club is short.
func squad(team_id: String, category: String) -> Array[Actor]:
	var key: String = _key(team_id)
	if not _squads.has(key):
		_squads[key] = {}
	var by_category: Dictionary = _squads[key]
	if not by_category.has(category):
		by_category[category] = _build(key, category)
	return by_category[category]

func has_squad(team_id: String, category: String) -> bool:
	return _squads.get(_key(team_id), {}).has(category)

# Someone joining a club mid-career: a signing, or the manager walking in on
# day one.
func add(team_id: String, category: String, actor: Actor) -> void:
	var people: Array[Actor] = squad(team_id, category)
	for existing: Actor in people:
		if existing.thing_id == actor.thing_id:
			return
	actor.set_team(_key(team_id))
	people.append(actor)

func remove(team_id: String, category: String, thing_id: String) -> bool:
	var people: Array[Actor] = squad(team_id, category)
	for i: int in range(people.size()):
		if people[i].thing_id == thing_id:
			people.remove_at(i)
			return true
	return false

func size_for_tier(tier: int) -> int:
	return int(SIZE_BY_TIER.get(tier, DEFAULT_SIZE))

# --- Building ---

func _build(team_id: String, category: String) -> Array[Actor]:
	var teams := Drive.def("team") as TeamDef
	var people: Array[Actor] = []
	if teams == null:
		return people
	var club: Dictionary = teams.get_team(team_id)
	if club.is_empty():
		Log.log(self, "error", "Rosters: no club '%s'" % team_id)
		return people
	var reputation: int = int(club.get("reputation", 30))
	# Where this club stands in the WORLD, not just in its own league. A city
	# club in Piedade and a city club in Monterrey are not the same sentence.
	var nations := Drive.def("nation") as NationDef
	var club_level: float = nations.club_level(club) if nations != null else 1.0

	# Curated first, and all of them.
	var curated := Drive.def("actor") as ActorDef
	if curated != null:
		for id: String in curated.ids_for(team_id, category):
			var person: Actor = ActorGenerator.from_spec(
				curated.spec(id), reputation, category, club_level)
			person.set_team(team_id)
			people.append(person)

	# Then invented, only as many as the club is short. Salted per club and per
	# index so adding a curated athlete tomorrow does not reshuffle the people
	# already around them — the same discipline ActorGenerator.squad uses.
	var target: int = _target_size(team_id, int(club.get("tier", 4)))
	var index: int = 0
	while people.size() < target:
		var sub_seed: int = SeedRng.derive(
			career_seed, "roster_%s_%s_%d" % [team_id, category, index])
		var filler: Actor = ActorGenerator.generate(sub_seed, reputation, category, club_level)
		filler.set_team(team_id)
		people.append(filler)
		index += 1
	return people

func _target_size(team_id: String, tier: int) -> int:
	var rng: RandomNumberGenerator = SeedRng.make_rng(
		SeedRng.derive(career_seed, "size_" + team_id))
	return maxi(size_for_tier(tier) + rng.randi_range(-SIZE_JITTER, SIZE_JITTER), 5)

func _key(team_id: String) -> String:
	return String(team_id).strip_edges().to_lower()

# --- Memento ---
#
# An Actor is a Thing, so its whole state is already a plain Dictionary. What
# gets written is the roster AS IT STANDS, curated and generated alike — by the
# time this is saved, people have moved, and where they came from stopped being
# the interesting question.

func to_snapshot() -> Dictionary:
	var squads: Dictionary = {}
	for team_id: String in _squads.keys():
		var by_category: Dictionary = {}
		for category: String in (_squads[team_id] as Dictionary).keys():
			var people: Array = []
			for person: Actor in (_squads[team_id][category] as Array[Actor]):
				people.append({
					"thing_id": person.thing_id,
					"ancestor": person.ancestor,
					"data": person.data.duplicate(true),
				})
			by_category[category] = people
		squads[team_id] = by_category
	return {"seed": career_seed, "squads": squads}

func from_snapshot(state: Dictionary) -> void:
	career_seed = int(state.get("seed", 0))
	_squads.clear()
	var squads: Dictionary = state.get("squads", {})
	for team_id: String in squads.keys():
		var by_category: Dictionary = {}
		for category: String in (squads[team_id] as Dictionary).keys():
			var people: Array[Actor] = []
			for raw: Variant in (squads[team_id][category] as Array):
				var entry: Dictionary = raw as Dictionary
				var person := Actor.new()
				person._apply_data(
					String(entry.get("thing_id", "")),
					String(entry.get("ancestor", "actor")),
					entry.get("data", {}))
				people.append(person)
			by_category[category] = people
		_squads[team_id] = by_category
