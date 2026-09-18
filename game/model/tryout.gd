# Tryout — a club putting out the word and seeing who turns up.
#
# WHERE FLAG PLAYERS ACTUALLY COME FROM. Two doors, and neither of them is a
# world pool that clubs shop from:
#
#   · gridiron players who also play flag — they exist already, they find the
#     sport on their own, and nobody recruited them. That is the indie turnout.
#   · people a club went out and CALLED. A tryout. Which is the ordinary way a
#     Brazilian amateur side fills a hole, and it is why the hole gets filled at
#     all: the club advertises for a center, and centers turn up.
#
# That second door is the whole reason this file exists. The draft used to
# spawn a stream of people with a fixed distribution over positions and let
# clubs refuse them, which meant a league short of centers sat there rolling
# receivers and turning them away — a hundred lines of "ninguém quis" while the
# loop waited for the dice to cough up the one position it needed. Supply is
# now CREATED FOR THE GAP, because that is what actually happens: you do not
# wait for a center to wander past, you announce a tryout.
#
# ⚠️ It steers the BODY, never the position. A tryout advertising for centers
# rolls bodies that lean that way and lets the matcher do what it always did —
# so decision 47 survives intact: nobody is assigned a chair, and a tryout for
# centers can still turn up somebody who is obviously a safety. He just came
# because he saw the flyer.
class_name Tryout

# 2d5*, so a turnout of five on average with the exploding tail doing the work:
# most weeks a handful show up and once in a while the whole gym does.
const TURNOUT_DICE := 2
# And reach on top. A club's pull is its fame: Flag Kings puts out a call and
# forty people see it, Bangu Castores tells eleven friends. This is the dial
# that makes a tier-1 tryout a different event from a sandlot one.
const REACH_PER_CANDIDATE := 25
const MIN_TURNOUT := 2

# How far a candidate can sit from the club's own level. Narrow on purpose: a
# tryout at an unaffiliated club in Bangu draws Bangu, and the Q4 who wanders
# in is the story, not the baseline.
const LEVEL_SPREAD := 0.5
const LEVEL_FLOOR := 0.6
const LEVEL_CEILING := 5.0

# The people nobody called. Gridiron players who also play flag, somebody's
# cousin, the guy who saw a game on a Sunday — they arrive at the scene rather
# than at a club, so they land in the Praça and get picked from there.
const INDIE_DICE := 2
const INDIE_SPREAD := 0.7

# Who turns up when this club puts out a call.
static func turnout(club: Dictionary, rng: RandomNumberGenerator) -> int:
	var reach: int = int(club.get("reputation", 20)) / REACH_PER_CANDIDATE
	return maxi(D5.roll_many(rng, TURNOUT_DICE) + reach, MIN_TURNOUT)

# One tryout. `wanted` is what the club is advertising for — the positions it is
# short of — and it may perfectly well include a staff chair, because a club
# looking for a defensive coordinator holds a tryout for one the same way.
#
# Returns everybody who showed up. The club picks first; whoever is left walks
# to the Praça, which is how somebody good ends up available to a worse club.
static func hold(club: Dictionary, wanted: Array[String], world_seed: int,
		first_index: int, category: String, years_cap: int = -1) -> Array[Actor]:
	var positions := Drive.def("position") as PositionDef
	var nations := Drive.def("nation") as NationDef
	var out: Array[Actor] = []
	if positions == null:
		return out
	var id: String = String(club.get("id", ""))
	var rng: RandomNumberGenerator = SeedRng.make_rng(
		SeedRng.derive(world_seed, "tryout_%s_%d" % [id, first_index]))
	var level: float = nations.club_level(club) if nations != null else 1.0
	var count: int = turnout(club, rng)
	for i: int in range(count):
		var toward: String = "" if wanted.is_empty() else wanted[i % wanted.size()]
		# -1 is "roll a career like anybody else". A cap is a club with no
		# history of its own: what turns up to its trials is people who have
		# never done this either.
		var years: int = -1 if years_cap < 0 else rng.randi_range(0, years_cap)
		out.append(_candidate(positions, world_seed, first_index + i,
			clampf(rng.randfn(level, LEVEL_SPREAD), LEVEL_FLOOR, LEVEL_CEILING),
			category, toward, years))
	return out

# The turnout nobody organised. No club, no advertised position — just the body
# somebody happens to have, which is the distribution the draft used to run on
# for everything.
static func indie(level: float, world_seed: int, first_index: int,
		category: String) -> Array[Actor]:
	var positions := Drive.def("position") as PositionDef
	var out: Array[Actor] = []
	if positions == null:
		return out
	var rng: RandomNumberGenerator = SeedRng.make_rng(
		SeedRng.derive(world_seed, "indie_%d" % first_index))
	var count: int = maxi(D5.roll_many(rng, INDIE_DICE), 1)
	for i: int in range(count):
		out.append(_candidate(positions, world_seed, first_index + i,
			clampf(rng.randfn(level, INDIE_SPREAD), LEVEL_FLOOR, LEVEL_CEILING),
			category, ""))
	return out

static func _candidate(positions: PositionDef, world_seed: int, index: int,
		level: float, category: String, toward: String, years: int = -1) -> Actor:
	var track: String = ActorGenerator.TRACK_PLAYER
	if toward != "" and positions.side(toward) == PositionDef.SIDE_STAFF:
		track = ActorGenerator.TRACK_STAFF
	return ActorGenerator.spawn(world_seed, index, level, category, track, years, toward)
