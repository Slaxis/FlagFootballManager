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

# Which seed the current filler was built from. Zero means nothing is built
# yet — a career seed is never zero, so there is no ambiguous state.
static var _filled_seed: int = 0

# Idempotent PER SEED: calling it twice with the same seed does nothing, and
# calling it with a different one tears the invented clubs down and rebuilds
# them. Without the rebuild the promise on the creation screen — the seed says
# which sandlot clubs exist — would only hold for the first seed of a session.
static func ensure_filled(seed_value: int = DEFAULT_SEED) -> void:
	var def := Drive.def("team") as TeamDef
	if def == null:
		return
	var built: bool = def.by_tier(TeamGenerator.TIER_UNAFFILIATED).size() >= FILL_COUNT
	if built and _filled_seed == seed_value:
		return
	if _filled_seed != seed_value:
		def.remove_generated()
	_filled_seed = seed_value
	for team: Dictionary in TeamGenerator.batch(seed_value, FILL_COUNT):
		# Never overwrite an authored club — the real ones are the truth.
		if def.get_team(String(team["id"])).is_empty():
			def.add_thing(team)
