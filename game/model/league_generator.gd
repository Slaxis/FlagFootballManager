# LeagueGenerator — how a world comes to exist.
#
# The whole of worldbuilding is one loop:
#
#     clubs = TeamGenerator.generate() × N        empty, just names and colours
#     while some club cannot field a side:
#         actor = ActorGenerator.spawn(...)        born into the Praça
#         draft(actor, clubs)                      somebody takes him, or nobody
#     ... and it keeps going a while after that, so the Praça has residue
#
# That is the entire architecture of decision 46, and it replaces the thing that
# was there before: each club inventing exactly the people it was short of, on
# first read, in isolation. Which produced squads that were individually fine
# and collectively impossible — nobody competed for anybody, every club got its
# ideal formation, and there was no such thing as a person without a club.
#
# The loop gets three things for free that the old version had to fake:
#
#   · stratification. Nobody assigns quality to a club. The draft matches level
#     to level, so the good ones accumulate at the good clubs because that is
#     who signs them, and the tier table falls out instead of being declared.
#   · a market. There is residue in the Praça at kickoff, so there is somebody
#     to sign in week one. A pool that starts empty is a transfer system that
#     starts dead.
#   · the player. You are a spawn like any other, and the scenario you picked is
#     a rule about how you get drafted. Nothing special happens for you, which
#     is exactly why the club that takes you is believable.
#
# ⚠️ `draft`, NOT `match`: `match` is GDScript's pattern-matching keyword, so
# `self.match(actor, teams)` is a parse error. It is also the better word —
# this is a club deciding to take somebody, not a similarity score.
class_name LeagueGenerator

# The world the module ships is Rio's sandlot, so the ambient level is the
# bottom of the ladder. The spread is what makes the pool worth drafting from:
# without it every club would fill with the same person and the tier table
# would be noise. Half a level of sigma puts the odd Q2 in a Q1 pool, which is
# the guy a good club fights for.
const LEVEL_SPREAD := 0.55
const LEVEL_FLOOR := 0.6
const LEVEL_CEILING := 5.0

# How many spawns the fill loop is allowed before it gives up. A cap and not a
# `while true`: if a formation hole can never be filled — a module that
# declares a position nothing matches into — this has to end in a log line and
# a short squad, not a hung boot.
const MAX_SPAWNS := 900
# And the same guard on the one-shot driver, counting phase steps rather than
# spawns: setup and settle are one step per club on top of the spawning.
const MAX_STEPS := 2000

# How many people are left standing in the Praça once every club is playable.
# Proportional to the field, because a sixteen-club league needs a bigger
# market than a four-club one. Roughly one spare per club plus a margin.
const RESIDUE_PER_CLUB := 1.4
const RESIDUE_MIN := 6

# --- Wanting ---
#
# One score per club per actor, and the biggest one signs him. Two forces, and
# they are deliberately different sizes:
#
#   NEED    a hole in the formation outweighs everything. This is what makes
#           the loop terminate, and what makes a sandlot club put whoever
#           turned up at center.
#   FIT     level to level. Not "the best club bids hardest" — that would send
#           every spawn to the same place — but "the club at this man's level
#           wants him most". A great club knows a sandlot player is a wasted
#           slot, and a sandlot club knows it cannot hold a star.
const NEED_FORMATION_HOLE := 3.0
const NEED_UNDER_MINIMUM := 1.8
const NEED_SHORT_AT_POSITION := 1.2
const NEED_DEPTH := 0.35
# How many past the formation a club will carry at one position. Two, because
# two quarterbacks is not a mistake — it is how a coach finds out which one is
# better, and most weeks the event IS the coletivo where both take snaps.
const MAX_SURPLUS := 2
# Heavy enough to sort the league, light enough that a hole in the formation
# still outranks a perfect match: a club that cannot snap the ball takes the
# center who turned up, and worries about his level afterwards.
const FIT_WEIGHT := 2.5
# The span of the world ladder, from a neighbourhood side to an IFAF club.
const LEVEL_SPAN := 4.0

# --- Building a world ---

# Fills every club that has none, and leaves a Praça behind. Idempotent: a club
# that already has a squad is skipped, so a caller may run this twice without
# rebuilding the world underneath the player.
#
# It does not reach for the Blackboard. Both Records are arguments because a
# model that fetches its own state is a model you cannot test twice in one
# process — and the Praça is a screen of its own, owned by whoever shows it.
#
# THE LOOP LIVES IN LeagueDraft. This is the one-shot door, which is what a
# test wants and what a nine-second frozen window looks like to a player; the
# draft screen drives the same object a step at a time and draws the bar.
static func fill(rosters: Rosters, praca: Praca, category: String) -> void:
	var run: LeagueDraft = LeagueDraft.make(rosters, praca, category)
	var guard: int = 0
	while not run.is_done() and guard < MAX_STEPS:
		run.step()
		guard += 1
	if guard >= MAX_STEPS:
		Log.log(null, "error", "LeagueGenerator: draft did not settle in %d steps" % MAX_STEPS)

# Every club that actually fields this category. A club with no women's side
# must not be handed women to draft.
static func clubs_fielding(teams: TeamDef, category: String) -> Array:
	var out: Array = []
	for club: Dictionary in teams.all():
		if bool(club.get("squads", {}).get(category, category == Actor.CATEGORY_MASC)):
			out.append(club)
	return out

# Where this field sits on the world ladder, averaged. A Rio sandlot league and
# a Monterrey one spawn different people, and neither had to say so.
static func ambient_level(clubs: Array) -> float:
	var nations := Drive.def("nation") as NationDef
	if nations == null or clubs.is_empty():
		return 1.0
	var total: float = 0.0
	for club: Dictionary in clubs:
		total += nations.club_level(club)
	return total / float(clubs.size())

# One person into the world, at a level drawn around the league's own.
static func spawn_one(world_seed: int, index: int, level: float, category: String) -> Actor:
	var rng: RandomNumberGenerator = SeedRng.make_rng(
		SeedRng.derive(world_seed, "level_%d" % index))
	return ActorGenerator.spawn(world_seed, index,
		clampf(rng.randfn(level, LEVEL_SPREAD), LEVEL_FLOOR, LEVEL_CEILING), category)

# --- The draft ---

# Which club takes this person, or "" when nobody does and he stays in the
# Praça. The one line the whole architecture hangs off.
static func draft(actor: Actor, clubs: Array, rosters: Rosters,
		category: String, positions: PositionDef) -> String:
	var best: String = ""
	var best_score: float = 0.0
	for club: Dictionary in clubs:
		var score: float = wants(club, actor, rosters, category, positions)
		if score > best_score:
			best_score = score
			best = String(club.get("id", ""))
	return best

# How badly this club wants this person. Zero or less means it does not.
static func wants(club: Dictionary, actor: Actor, rosters: Rosters,
		category: String, positions: PositionDef) -> float:
	var id: String = String(club.get("id", ""))
	var people: Array[Actor] = rosters.squad(id, category)
	var tier: int = int(club.get("tier", 4))
	if people.size() >= rosters.target_size(id, tier):
		return 0.0

	var position: String = actor.position()
	# NOBODY CARRIES A FOURTH QUARTERBACK. Two deep past the formation is a
	# coach keeping his options open; six rushers at a one-rusher position is
	# the best club in the league hoovering up whatever the market spat out,
	# because it out-bid everybody on fit and no rule said no. A refusal and
	# not a weak preference: the draft asks which club wants THIS man most, so
	# a mild dislike still wins when the alternatives are milder.
	var depth: int = rosters.depth_at(id, category, position)
	if positions.has_position(position) and depth >= positions.slots(position) + MAX_SURPLUS:
		return 0.0

	return _need(club, actor, rosters, category, positions, depth)["value"] \
		+ _fit(club, actor) * FIT_WEIGHT

# WHY it wants him, alongside how much. The reason is not decoration: this
# system fails quietly — the club that ended up with six rushers, the fit term
# that compared two different rulers — and one word per signing is what turns
# that into something a person can scroll and catch.
static func reason_for(club: Dictionary, actor: Actor, rosters: Rosters,
		category: String, positions: PositionDef) -> String:
	return UiText.t(String(_need(club, actor, rosters, category, positions,
		rosters.depth_at(String(club.get("id", "")), category, actor.position()))["reason"]))

static func _need(club: Dictionary, actor: Actor, rosters: Rosters,
		category: String, positions: PositionDef, depth: int) -> Dictionary:
	var position: String = actor.position()
	if positions.has_position(position) and depth == 0:
		# Nobody here plays his position at all. This is the term that ends the
		# fill loop, and it is the biggest one on purpose.
		return {"value": NEED_FORMATION_HOLE, "reason": "draft.why_hole"}
	if rosters.squad(String(club.get("id", "")), category).size() < positions.squad_minimum:
		# Below the competition's own floor, a body is a body.
		return {"value": NEED_UNDER_MINIMUM, "reason": "draft.why_minimum"}
	if positions.has_position(position) and depth < positions.slots(position):
		# SCALED BY HOW SHORT. Flat, this put six rushers and one receiver at
		# the same club: the rusher slot was full at one, the receiver slot
		# wanted three, and both read as "a bit short" — so the fit term won
		# every time and the squad drifted into whatever the market happened to
		# be spawning. Three slots with one man in them is twice the hole that
		# two slots with one man in them is, and now it says so.
		return {
			"value": NEED_SHORT_AT_POSITION * float(positions.slots(position) - depth),
			"reason": "draft.why_short",
		}
	return {"value": NEED_DEPTH, "reason": "draft.why_depth"}

# Level against level, as a closeness rather than a bid.
#
# ⚠️ REPUTATION AND GERAL ARE NOT THE SAME RULER, and reading them as if they
# were inverted the whole league. Reputation runs 14 to 90; Geral, at this tier,
# runs about 14 to 30 — so EVERY player looked like a sandlot player to the
# subtraction, the weak clubs won every fit term, and the strong ones signed
# only what nobody else had taken. Flag Kings came out with a worse squad than
# Madureira, which is exactly backwards and is the kind of bug that looks like
# a balance problem for a month.
#
# The world ladder is the ruler both sides already share: NationDef gives a
# club its level, and a spawn carries the level it was drawn at. Same dial,
# same units, one subtraction — and now a 2.5 belongs at a 2.2 club and is
# wasted at a 1.0 one.
static func _fit(club: Dictionary, actor: Actor) -> float:
	var nations := Drive.def("nation") as NationDef
	var here: float = nations.club_level(club) if nations != null else 1.0
	var theirs: float = float(actor.data.get("level", 1.0))
	return clampf(1.0 - absf(here - theirs) / LEVEL_SPAN, 0.0, 1.0)

# --- Playability ---

# Can this club take the field? Seven registered AND somebody at every playing
# position. Both halves are needed: seven receivers is seven people and still
# nobody to snap the ball.
static func playable(rosters: Rosters, team_id: String, category: String,
		positions: PositionDef = null) -> bool:
	var def: PositionDef = positions if positions != null else Drive.def("position") as PositionDef
	if def == null:
		return false
	var people: Array[Actor] = rosters.squad(team_id, category)
	if people.size() < def.squad_minimum:
		return false
	for id: String in def.playing_ids():
		if rosters.depth_at(team_id, category, id) <= 0:
			return false
	return true
