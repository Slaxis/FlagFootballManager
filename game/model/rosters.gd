# Rosters — who plays where, right now.
#
# Three layers meet here, and each has exactly one job:
#
#   ActorDef          the curated truth. Real athletes at real clubs. Immutable.
#   LeagueGenerator   spawns people into the Praça and drafts them into clubs.
#   Rosters           the live state. This is the one that CHANGES.
#
# IT NO LONGER GENERATES ANYBODY. It used to: a squad was built on first read,
# each club inventing exactly the people it was short of. Which quietly made
# every club a closed world — nobody came from anywhere, nobody was competed
# for, and the first time a player was signed the whole thing had to stop being
# a formula anyway. So the invention moved out to LeagueGenerator, and what is
# left here is the only thing that was ever really needed: a list per club that
# somebody else fills, and that changes for the rest of the career.
#
# It has to be state and not a formula. A roster derived from the career seed
# would be free and reproducible and completely wrong the moment anybody is
# signed, injured, trained or retired — which is the entire rest of the game.
class_name Rosters
extends Record

# How many people a club carries, by tier. A sandlot side scrapes a squad
# together; a tier-1 club has people who do not get on the field.
const SIZE_BY_TIER: Dictionary = {1: 15, 2: 13, 3: 11, 4: 9}
const DEFAULT_SIZE := 10
const SIZE_JITTER := 2

# Who founded the club. Somebody had to put five people on a field before there
# was a club at all, and those five are older, they are the reason the place
# exists, and they were never scouted — they just started it.
#
# Which is now settled AFTER the draft instead of before it: the founders are
# the oldest hands in the room, because an old man at a neighbourhood club is
# almost always one of the people who started it.
const FOUNDERS_MIN := 1
const FOUNDERS_MAX := 5

# How many people are there to COACH rather than play, by tier. A sandlot club
# has one person with a clipboard and he also plays; a tier-1 club can afford
# chairs. A SEPARATE budget from the squad, because a coach is not somebody you
# could have fielded — counting them together is what once produced a club with
# five fitness coaches and one center.
const STAFF_BY_TIER: Dictionary = {1: 4, 2: 3, 3: 2, 4: 1}
const DEFAULT_STAFF := 1

# team_id -> category -> Array[Actor]
var _squads: Dictionary = {}
# "team_id/category" -> true, for squads the draft has already been through.
#
# NOT the same question as "is this list non-empty". The player is seated at
# his own club before the draft runs — so the club counts him against its needs
# and does not go and sign a second head coach — and reading emptiness would
# have made that one seated person mean "already done", leaving the player's
# own club as the only one in the league with a squad of one.
var _filled: Dictionary = {}
var career_seed: int = 0

static func make(seed_value: int) -> Rosters:
	var rosters := Rosters.new()
	rosters.career_seed = seed_value
	return rosters

# The squad AS IT STANDS. An empty list is a real answer — it means nobody has
# been drafted here yet, which before the Praça existed was not a state a club
# could be in.
func squad(team_id: String, category: String) -> Array[Actor]:
	var key: String = _key(team_id)
	if not _squads.has(key):
		_squads[key] = {}
	var by_category: Dictionary = _squads[key]
	if not by_category.has(category):
		var empty: Array[Actor] = []
		by_category[category] = empty
	return by_category[category]

# Every club this roster knows about, in no particular order.
func team_ids() -> Array[String]:
	var out: Array[String] = []
	for id: String in _squads.keys():
		out.append(id)
	return out

func has_squad(team_id: String, category: String) -> bool:
	var people: Variant = _squads.get(_key(team_id), {}).get(category, null)
	return people != null and not (people as Array).is_empty()

func is_filled(team_id: String, category: String) -> bool:
	return bool(_filled.get("%s/%s" % [_key(team_id), category], false))

func mark_filled(team_id: String, category: String) -> void:
	_filled["%s/%s" % [_key(team_id), category]] = true

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

# --- Receiving ---

# The authored athletes, seated at the club their curator wrote them into.
# They are not drafted: a real person at a real club is a fact about the world,
# and the draft only decides the invented ones. Returns how many sat down.
func seat_curated(team_id: String, category: String) -> int:
	var curated := Drive.def("actor") as ActorDef
	var teams := Drive.def("team") as TeamDef
	if curated == null or teams == null:
		return 0
	var club: Dictionary = teams.get_team(team_id)
	if club.is_empty():
		return 0
	var nations := Drive.def("nation") as NationDef
	var level: float = nations.club_level(club) if nations != null else 1.0
	var seated: int = 0
	for id: String in curated.ids_for(team_id, category):
		var person: Actor = ActorGenerator.from_spec(
			curated.spec(id), int(club.get("reputation", 30)), category, level)
		add(team_id, category, person)
		seated += 1
	return seated

# How many people this club is trying to carry. Jittered off the seed so two
# tier-4 clubs are not identically sized, which is what makes one of them the
# side that is always a man short.
func target_size(team_id: String, tier: int) -> int:
	var rng: RandomNumberGenerator = SeedRng.make_rng(
		SeedRng.derive(career_seed, "size_" + _key(team_id)))
	return maxi(size_for_tier(tier) + rng.randi_range(-SIZE_JITTER, SIZE_JITTER), 5)

# How many people at this club came up at this position. What the draft reads
# to know whether the club still has a hole there.
func depth_at(team_id: String, category: String, position_id: String) -> int:
	var count: int = 0
	for person: Actor in squad(team_id, category):
		if person.position() == position_id:
			count += 1
	return count

# The oldest hands in the room. Called once the club is full, because until
# then there is nobody to be oldest.
func mark_founders(team_id: String, category: String) -> void:
	var people: Array[Actor] = squad(team_id, category).duplicate()
	if people.is_empty():
		return
	var rng: RandomNumberGenerator = SeedRng.make_rng(
		SeedRng.derive(career_seed, "founders_" + _key(team_id)))
	var wanted: int = mini(rng.randi_range(FOUNDERS_MIN, FOUNDERS_MAX), people.size())
	people.sort_custom(func(a: Actor, b: Actor) -> bool: return a.age() > b.age())
	for i: int in range(wanted):
		people[i].data["founder"] = true

func size_for_tier(tier: int) -> int:
	return int(SIZE_BY_TIER.get(tier, DEFAULT_SIZE))

func staff_target(tier: int) -> int:
	return int(STAFF_BY_TIER.get(tier, DEFAULT_STAFF))

# How many of this club's people are on a given side of the operation. The
# squad target counts ATHLETES; a head coach must not eat a receiver's place.
func count_on_side(team_id: String, category: String, side: String) -> int:
	var positions := Drive.def("position") as PositionDef
	if positions == null:
		return 0
	var total: int = 0
	for person: Actor in squad(team_id, category):
		if positions.side(person.position()) == side:
			total += 1
	return total

func athlete_count(team_id: String, category: String) -> int:
	var positions := Drive.def("position") as PositionDef
	if positions == null:
		return squad(team_id, category).size()
	var total: int = 0
	for person: Actor in squad(team_id, category):
		if PositionDef.PLAYING_SIDES.has(positions.side(person.position())):
			total += 1
	return total

func staff_count(team_id: String, category: String) -> int:
	return count_on_side(team_id, category, PositionDef.SIDE_STAFF)

# Numbers, in squad order, skipping nobody. A shirt is how a crowd knows who
# just caught that, and the roster column is empty without one.
func hand_out_jerseys(team_id: String, category: String) -> void:
	var rng: RandomNumberGenerator = SeedRng.make_rng(
		SeedRng.derive(career_seed, "jersey_" + _key(team_id)))
	var pool: Array[int] = []
	for number: int in range(1, 100):
		pool.append(number)
	var positions := Drive.def("position") as PositionDef
	for person: Actor in squad(team_id, category):
		# A COACH DOES NOT WEAR A NUMBER. The shirt is how a crowd knows who
		# just caught that, and nobody is going to catch anything with a
		# clipboard in his hands.
		if positions != null and not PositionDef.PLAYING_SIDES.has(
				positions.side(person.position())):
			continue
		if person.jersey() != Actor.NO_JERSEY or pool.is_empty():
			continue
		var pick: int = rng.randi() % pool.size()
		person.set_jersey(pool[pick])
		pool.remove_at(pick)

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
	return {"seed": career_seed, "squads": squads, "filled": _filled.duplicate()}

func from_snapshot(state: Dictionary) -> void:
	career_seed = int(state.get("seed", 0))
	_squads.clear()
	_filled = (state.get("filled", {}) as Dictionary).duplicate()
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
