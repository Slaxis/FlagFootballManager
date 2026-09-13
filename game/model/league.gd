# League — the full field of clubs for a state: the ones the module authored
# plus the unaffiliated sides TeamGenerator invents to fill it out.
#
# Ten real Rio clubs make a thin championship and, worse, leave nowhere for the
# player to start — every one of them is affiliated, and the career begins in
# the sandlot. Six invented tier-4 clubs bring the field to sixteen, which is a
# round number for a table and gives the draft a pool to pick from.
#
# The seed is fixed for now so the league is stable across runs. When
# `B.4-create-manager` starts a real career it passes the career's own seed
# instead, and the only thing that changes is the argument.
class_name League

const FILL_COUNT := 6
const DEFAULT_SEED := 20260101
# "Nobody said" — not a seed anybody can ask for.
const NO_SEED := 0

# Which seed the current filler was built from. Zero means nothing is built
# yet — a career seed is never zero, so there is no ambiguous state.
static var _filled_seed: int = 0

# Idempotent PER SEED: calling it twice with the same seed does nothing, and
# calling it with a different one tears the invented clubs down and rebuilds
# them. Without the rebuild the promise on the creation screen — the seed says
# which sandlot clubs exist — would only hold for the first seed of a session.
static func ensure_filled(seed_value: int = NO_SEED) -> void:
	var def := Drive.def("team") as TeamDef
	if def == null:
		return
	var wanted: int = seed_value if seed_value != NO_SEED else current_seed()
	var built: bool = def.by_tier(TeamGenerator.TIER_UNAFFILIATED).size() >= FILL_COUNT
	if built and _filled_seed == wanted:
		return
	if _filled_seed != wanted:
		def.remove_generated()
	_filled_seed = wanted
	for team: Dictionary in TeamGenerator.batch(wanted, FILL_COUNT):
		# Never overwrite an authored club — the real ones are the truth.
		if def.get_team(String(team["id"])).is_empty():
			def.add_thing(team)

# WHICH world to build, when the caller does not say. A career on the
# Blackboard IS the answer: the sandlot clubs belong to that career's seed, and
# the club that drafted you is one of them.
#
# This exists because the default used to be a constant, and a screen that
# simply did not care about seeds — club_select calls `ensure_filled()` with no
# argument — silently tore the career's sandlot down and rebuilt somebody
# else's. The club you were drafted into stopped existing between one screen
# and the next. Asking is the only version of this that a future screen cannot
# get wrong by forgetting.
static func current_seed() -> int:
	var career := The.board.get("career", null) as Career
	if career != null and career.career_seed != NO_SEED:
		return career.career_seed
	return DEFAULT_SEED
