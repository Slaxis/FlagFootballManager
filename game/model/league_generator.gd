# LeagueGenerator — how a world comes to exist.
#
# The shape of it, and it is deliberately not a marketplace:
#
#     clubs = TeamGenerator × N                    empty, just names and colours
#     repeat, best club first, until everybody is full:
#         · each club holds a TRYOUT for what it lacks, and picks from it
#         · whoever was not picked walks to the Praça
#         · one INDIE turnout — the people nobody called — into the Praça
#         · each club, best first, picks what it still needs out of the Praça
#
# WHY TRYOUTS AND NOT A POOL. The first version spawned a stream of people with
# a fixed distribution over positions and let clubs refuse them. That is not
# where flag players come from, and it broke exactly where you would expect: a
# league short of centers sat there rolling receivers and turning them away,
# a hundred lines of "ninguém quis" while the loop waited for the dice. Supply
# is created BY the club, FOR the gap, because that is what actually happens —
# you do not wait for a center to wander past, you announce a tryout.
#
# The two real doors into the sport are both here: the gridiron player who also
# plays flag and simply turns up (the indie turnout), and the person a club went
# out and called (the tryout). Neither of them is a world pool being shopped.
#
# BEST CLUB FIRST, every phase. Flag Kings fills before Estácio Marrecos and
# what is left over is what Estácio gets, which is both how it works and why
# the tier table does not need anybody to declare it.
#
# ⚠️ `draft`, NOT `match`: `match` is GDScript's pattern-matching keyword, so
# `self.match(actor, teams)` is a parse error. The draft is the Praça phase —
# `pick()` is its unit operation, asking which person a club takes rather than
# which club takes a person. That inversion is the fix: a club shopping never
# has nothing to do, while a person being offered around can be refused by
# everybody, forever.
class_name LeagueGenerator

# How many rounds of tryouts before giving up. A cap and not a `while true`: a
# module declaring a position nothing can match into has to end in a log line
# and a short squad, not a hung boot. Each round gives every unfinished club a
# targeted tryout, so a club needing nine people is normally done in three.
const MAX_ROUNDS := 40
# And the same guard on the one-shot driver, counting phase steps.
const MAX_STEPS := 4000

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
# An empty chair on the sideline. Between a formation hole and being short at a
# position: a club without a head coach is in trouble, but not the kind of
# trouble that stops it taking the field.
const NEED_STAFF_CHAIR := 2.2
# How many positions a tryout calls for at once.
const ADVERTISED := 4
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

# --- The draft ---

# WHICH OF THESE PEOPLE THIS CLUB TAKES, or null when it wants none of them.
# The one line the whole architecture hangs off, and it points the way round it
# does on purpose: a club shopping a pool always has something to do, whereas a
# person offered around club by club can be refused by all of them and come
# back next turn to be refused again.
static func pick(club: Dictionary, pool: Array, rosters: Rosters,
		category: String, positions: PositionDef) -> Actor:
	var best: Actor = null
	var best_score: float = 0.0
	for person: Actor in pool:
		var score: float = wants(club, person, rosters, category, positions)
		if score > best_score:
			best_score = score
			best = person
	return best

# Clubs strongest first. Every phase runs in this order, which is the whole of
# the stratification: the best side picks from a full tryout and a full Praça,
# and what is left over is what the bottom of the table gets.
static func by_standing(clubs: Array) -> Array:
	var out: Array = clubs.duplicate()
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("reputation", 0)) > int(b.get("reputation", 0)))
	return out

# What this club would hold a tryout FOR, most urgent first. This is the line
# that conditions supply on demand — the club advertises its holes, and the
# bodies that turn up lean that way.
static func gaps(club: Dictionary, rosters: Rosters, category: String,
		positions: PositionDef) -> Array[String]:
	var id: String = String(club.get("id", ""))
	var tier: int = int(club.get("tier", 4))
	var scored: Array = []
	for pid: String in positions.playing_ids():
		var room: int = positions.slots(pid) + MAX_SURPLUS - rosters.depth_at(id, category, pid)
		if room <= 0:
			continue
		var short: int = positions.slots(pid) - rosters.depth_at(id, category, pid)
		scored.append({"id": pid, "want": maxi(short, 0) * 2 + 1})
	# A club also goes looking for a coach, and for the same reason: the chair
	# is empty and somebody has to call the plays.
	if rosters.staff_count(id, category) < rosters.staff_target(tier):
		for pid: String in positions.ids_on_side(PositionDef.SIDE_STAFF):
			if rosters.depth_at(id, category, pid) == 0:
				scored.append({"id": pid, "want": 2})
	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["want"]) > int(b["want"]))
	# ONLY THE FEW THAT MATTER. A tryout advertising all eleven positions steers
	# nothing — the candidates get spread one per position and the hole the club
	# actually has gets one body out of eleven. Four is a real call for help,
	# and it is also what the flyer would say.
	var out: Array[String] = []
	for entry: Variant in scored:
		if out.size() >= ADVERTISED:
			break
		out.append(String((entry as Dictionary)["id"]))
	return out

# Has this club finished building? Its squad AND its staff, because they are
# two budgets: a side with twelve athletes and nobody on the sideline is not
# done, and neither is one with a full technical staff and six players.
static func is_built(club: Dictionary, rosters: Rosters, category: String,
		positions: PositionDef) -> bool:
	var id: String = String(club.get("id", ""))
	var tier: int = int(club.get("tier", 4))
	if rosters.athlete_count(id, category) < rosters.target_size(id, tier):
		return false
	if rosters.staff_count(id, category) < rosters.staff_target(tier):
		return false
	return playable(rosters, id, category, positions)

# How badly this club wants this person. Zero means it does not.
static func wants(club: Dictionary, actor: Actor, rosters: Rosters,
		category: String, positions: PositionDef) -> float:
	var id: String = String(club.get("id", ""))
	var tier: int = int(club.get("tier", 4))
	var position: String = actor.position()

	# A CLIPBOARD IS NOT A ROSTER SPOT. Staff has its own small budget and one
	# person per chair — you do not carry a spare head coach — and it must not
	# come out of the squad's count, which is what once produced a club with
	# five fitness coaches and one center.
	if positions.side(position) == PositionDef.SIDE_STAFF:
		if rosters.staff_count(id, category) >= rosters.staff_target(tier):
			return 0.0
		if rosters.depth_at(id, category, position) > 0:
			return 0.0
		return NEED_STAFF_CHAIR + _fit(club, actor) * FIT_WEIGHT

	# A FORMATION HOLE BEATS THE SQUAD CAP. A club that has reached its target
	# size and still has nobody at center cannot take the field, and being one
	# over target is nothing next to that — so the cap stops applying to the
	# person who plugs the hole.
	#
	# Without this the two rules deadlocked: `is_built` demands playability, so
	# a full-but-unplayable club kept holding tryouts, and `wants` refused
	# everybody who turned up because the squad was full. The round signed
	# nobody, the stall guard fired, and the league shipped with five sides that
	# could not field five players.
	var depth: int = rosters.depth_at(id, category, position)
	var plugs_a_hole: bool = positions.has_position(position) and depth == 0
	if rosters.athlete_count(id, category) >= rosters.target_size(id, tier) 			and not plugs_a_hole:
		return 0.0

	# NOBODY CARRIES A FOURTH QUARTERBACK. Two deep past the formation is a
	# coach keeping his options open; six rushers at a one-rusher position is
	# the best club in the league hoovering up whatever the market spat out,
	# because it out-bid everybody on fit and no rule said no. A refusal and
	# not a weak preference: the draft asks which club wants THIS man most, so
	# a mild dislike still wins when the alternatives are milder.
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
	if rosters.athlete_count(String(club.get("id", "")), category) < positions.squad_minimum:
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
	# Athletes, not bodies. Seven REGISTERED is a rule about who can take the
	# field, and a head coach cannot.
	if rosters.athlete_count(team_id, category) < def.squad_minimum:
		return false
	for id: String in def.playing_ids():
		if rosters.depth_at(team_id, category, id) <= 0:
			return false
	return true
