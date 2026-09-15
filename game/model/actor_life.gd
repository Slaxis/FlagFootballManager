# ActorLife — an actor is not rolled, an actor is LIVED.
#
# The old generator drew attributes, skills and age from three independent
# bells, which is exactly why a sixteen-year-old could come out better than a
# thirty-seven-year-old and why everybody knew all fifteen skills a little.
# Here a person is a birth sheet plus N years of showing up, and the numbers
# are whatever those years left behind.
#
# THE WEEK IS THE UNIT (decision 26). Every week an actor rolls `d5* - 2`
# career points: 71% of weeks land between -1 and +2, and 9% on each tail — the
# week nothing happened and the week everything clicked. Modifiers add to the
# die rather than replacing it, so a bad week at a great club is still a bad
# week.
#
# ONE OPERATION, TWO USES. Generating a 28-year-old is `advance_week` run
# 52x11 times over a birth sheet. Rolling the season over in C.4 is the SAME
# call, once a week, on everybody. A player you watched grow then ages by the
# rule that built his opponents, instead of by a second curve that quietly
# diverges from it.
class_name ActorLife

const WEEKS_PER_YEAR := 52
const DAYS_PER_WEEK := 5

# THE DAY IS THE UNIT, AND XP IS THE CURRENCY.
#
#   xp/day    = dedication + D5.successes()
#   10 xp     = 1 career point
#   1 cp/week = a good week: the gym most days, training at 75%
#   2 cp/week = an excellent one
#   3 cp/week = trained every day AND had the day where something clicked
#
# `D5.successes()` is the tally reading of the same die: 70% of days are a flat
# nothing, ~12% each way is one success or one failure, and the rest is the day
# you remember. So dedication sets where a person lives and the die says how
# today actually went.
const XP_PER_CP := 10.0

# TWO STREAMS, NOT ONE POCKET. An athlete who did the work earns a stat point
# AND a skill point — the gym and the field are different sessions, and one
# budget split between them made the untrained half of every sheet sit still.
const STREAM_STAT := "stat"
const STREAM_SKILL := "skill"

# Most of the gym is about the position, but not all of it. A safety still
# squats, and general conditioning lifts whatever it lifts — modelling the stat
# stream as position-only left five of the eight attributes frozen at whatever
# growing up handed out, which made club quality almost invisible in a player's
# overall.
const GENERAL_CONDITIONING := 0.32

# Career points buy STORED points, not steps: the sheet is stored 0..100 so
# training can move somebody three points and be felt before the bar lights up.
# Entering step N still costs N of its own kind, spread across that step's ten
# stored points — so 0 to 80 in a skill costs 72 cp either way you count it.
const STORED_PER_STEP := 10.0

# Age is not rolled. It falls out of debut plus years, which is what makes an
# entry club young and an established one full of veterans without either
# being stated anywhere.
const DEBUT_AGE_MIN := 15
const DEBUT_AGE_MAX := 21

# How fast somebody still learns. The tail is not zero: a 36-year-old still
# picks things up, just not the way he did at eighteen.
const LEARNING_BY_AGE: Array = [
	{"until": 21, "rate": 1.3},
	{"until": 26, "rate": 1.0},
	{"until": 31, "rate": 0.6},
	{"until": 35, "rate": 0.3},
	{"until": 99, "rate": 0.1},
]

# After the peak the body goes, and ONLY the body. Skills never decay: he still
# knows how to read a route, he just cannot get there any more — which is the
# whole reason a veteran should read differently from a kid.
const DECLINE_FROM_AGE := 30
const DECLINE_PER_YEAR := 1.4
const DECLINE_ACCELERATION := 0.35
const PHYSICAL: Array[String] = ["strength", "stamina", "agility", "dexterity"]

# Potential (decision 27), now drawn against the club's place in the WORLD
# (decision 33). The old version was a flat table that handed 7% of everybody a
# world-level ceiling, which is how a sandlot club in Piedade ended up fielding
# somebody with international-level coaching.
#
# A player is normally AT his club's level. The drift around it uses the same
# 4:1 odds the ladder is built on, so one band better is uncommon, two is rare,
# and nothing else happens. A great player at a poor club exists; a world star
# there does not.
const DRIFT_OFFSETS: Array[int] = [-1, 0, 1, 2]
const DRIFT_WEIGHTS: Array[float] = [0.25, 1.0, 0.25, 0.0625]

# And potential is a CEILING, not a toll. Charging four times the price above it
# was not a wall at all — a fifteen-year career at fifty-odd points a year
# walked straight through and came out nineteen points past, which is how a
# national-level ceiling produced world-level coaching.
#
# A hard cap is also what makes the quantile ladder mean anything: if a player
# can train past his band then the bands describe nothing. The small overshoot
# is the one honest exception — somebody who worked harder than anyone expected
# — and it is priced so only a long career reaches it.
const OVER_POTENTIAL_ALLOWED := 2
const OVER_POTENTIAL_COST := 9.0

# A run of weeks that goes badly enough eats condition instead of building it.
const DEFICIT_BEFORE_DECAY := -8.0
const DECAY_REFUND := 4.0

# GROWING UP IS NOT TRAINING. A fifteen-year-old becomes an adult whether or
# not anybody coaches him: he gets taller, stronger, steadier, and he learns
# what a room is. Modelling only practice left every generated actor stuck at
# the body of a child, with the untrained half of the sheet never moving at
# all — which dragged every overall into the twenties.
#
# So up to MATURITY_AGE every attribute drifts toward an adult baseline, bent
# by potential: the talented kid matures past average, the ordinary one lands
# on it. This is free and it happens to everybody.
const MATURITY_AGE := 23
const ADULT_BASELINE := 42.0
const MATURITY_STEP_MIN := 1
const MATURITY_STEP_MAX := 4

# --- Birth ---

# A thirteen-year-old: a body with some shape to it and no idea how to play.
static func birth_sheet(rng: RandomNumberGenerator) -> Dictionary:
	var def := Drive.def("stat") as StatDef
	var stats: Dictionary = {}
	if def == null:
		return stats
	for id: String in def.base_ids():
		stats[id] = clampi(int(round(rng.randfn(34.0, 9.0))), 8, 62)
	return stats

# `club_level` is a float from NationDef: 1.0 is a city club in a mid country,
# and it climbs with both the country and the division.
static func roll_potential(club_level: float, rng: RandomNumberGenerator) -> int:
	var def := Drive.def("stat") as StatDef
	if def == null:
		return 55
	var total: float = 0.0
	for weight: float in DRIFT_WEIGHTS:
		total += weight
	var roll: float = rng.randf() * total
	var drift: int = 0
	for i: int in range(DRIFT_OFFSETS.size()):
		roll -= DRIFT_WEIGHTS[i]
		if roll <= 0.0:
			drift = DRIFT_OFFSETS[i]
			break
	# The fractional part is a CHANCE of the band above, not a rounding. Level
	# 2.5 rounded up made Flag Kings a national-level club outright, and the
	# drift on top of that handed a Brazilian side six world-level stars.
	var base: int = int(floor(club_level))
	if rng.randf() < club_level - float(base):
		base += 1
	var quantile: int = clampi(base + drift, 1, def.quantile_count())
	return def.quantile_value(quantile, rng)

static func roll_debut_age(rng: RandomNumberGenerator) -> int:
	return rng.randi_range(DEBUT_AGE_MIN, DEBUT_AGE_MAX)

# --- The week ---

# Rolls one week, day by day, into two banks and spends what they can afford.
# Returns the xp the week produced, which is what a training screen shows.
static func advance_week(actor: Actor, position: String,
		climate: Dictionary, rng: RandomNumberGenerator) -> int:
	var dedication: int = int(climate.get("dedication", 2))
	var training: float = float(climate.get("training", 1.0))
	var rate: float = _learning_rate(actor.age())
	var xp: int = 0
	for _day: int in range(DAYS_PER_WEEK):
		xp += dedication + D5.successes(rng)
	# Club and age lift a productive week and cannot rescue a lost one: a great
	# facility does not make a missed session count.
	var earned: float = float(xp)
	if earned > 0.0:
		earned *= training * rate
	var gained: float = earned / XP_PER_CP
	_bank(actor, STREAM_STAT, gained)
	_bank(actor, STREAM_SKILL, gained)
	_spend(actor, position, rng)
	return xp

static func advance_year(actor: Actor, position: String,
		climate: Dictionary, rng: RandomNumberGenerator) -> void:
	for _week: int in range(WEEKS_PER_YEAR):
		advance_week(actor, position, climate, rng)
	actor.set_age(actor.age() + 1)
	_mature(actor, rng)
	_decline(actor, rng)

static func bank_of(actor: Actor, stream: String) -> float:
	return float(actor.data.get("bank_" + stream, 0.0))

static func _bank(actor: Actor, stream: String, delta: float) -> void:
	actor.data["bank_" + stream] = bank_of(actor, stream) + delta

# --- Internals ---

static func _learning_rate(age: int) -> float:
	for band: Dictionary in LEARNING_BY_AGE:
		if age <= int(band["until"]):
			return float(band["rate"])
	return 0.1

# Buys what each bank can afford. The target is drawn against the position
# weights, so fifteen years of running routes produces a receiver rather than a
# generalist — and the attribute stream buys the attributes UNDER those same
# skills, so aptitude and practice grow together instead of apart.
static func _spend(actor: Actor, position: String, rng: RandomNumberGenerator) -> void:
	var positions := Drive.def("position") as PositionDef
	var def := Drive.def("stat") as StatDef
	if positions == null or def == null:
		return
	var weights: Dictionary = positions.trains(position)
	if weights.is_empty():
		return
	var potential: int = int(actor.data.get("potential", 70))
	for stream: String in [STREAM_STAT, STREAM_SKILL]:
		var bank: float = bank_of(actor, stream)
		if bank <= DEFICIT_BEFORE_DECAY:
			actor.data["bank_" + stream] = _decay_one(actor, bank, rng)
			continue
		var is_attribute: bool = stream == STREAM_STAT
		var guard: int = 0
		while bank >= 0.1 and guard < 40:
			guard += 1
			var target: String = _pick_weighted(weights, rng)
			if target == "":
				break
			var stat_id: String = target
			if is_attribute:
				stat_id = def.skill_attribute(target)
				if rng.randf() < GENERAL_CONDITIONING:
					var all_ids: Array = def.base_ids()
					stat_id = String(all_ids[rng.randi() % all_ids.size()])
			if stat_id == "":
				continue
			var current: int = actor.stat(stat_id) if is_attribute else actor.skill(stat_id)
			if current >= StatDef.STORED_MAX:
				continue
			var cost: float = _cost_of_next(current, is_attribute, potential)
			if is_inf(cost):
				continue
			if cost > bank:
				break
			bank -= cost
			if is_attribute:
				actor.set_stat(stat_id, current + 1)
			else:
				actor.set_skill(stat_id, current + 1)
		actor.data["bank_" + stream] = bank

# What one stored point costs right now: the step it sits in, times its kind's
# rate, spread over that step's ten points. Above potential it costs four times
# as much, which is the difference between hard work and talent.
static func _cost_of_next(current: int, is_attribute: bool, potential: int) -> float:
	var step: int = int(floor(float(current) / STORED_PER_STEP)) + 1
	var kind: int = SheetBuilder.STAT_POINT_IN_CAREER if is_attribute \
		else SheetBuilder.SKILL_POINT_IN_CAREER
	var cost: float = float(step * kind) / STORED_PER_STEP
	if current < potential:
		return cost
	if current >= potential + OVER_POTENTIAL_ALLOWED:
		return INF
	return cost * OVER_POTENTIAL_COST

static func _pick_weighted(weights: Dictionary, rng: RandomNumberGenerator) -> String:
	var total: float = 0.0
	for key: String in weights.keys():
		total += float(weights[key])
	if total <= 0.0:
		return ""
	var roll: float = rng.randf() * total
	for key: String in weights.keys():
		roll -= float(weights[key])
		if roll <= 0.0:
			return key
	return String(weights.keys()[weights.size() - 1])

static func _decay_one(actor: Actor, bank: float, rng: RandomNumberGenerator) -> float:
	var id: String = PHYSICAL[rng.randi() % PHYSICAL.size()]
	actor.set_stat(id, maxi(actor.stat(id) - 1, StatDef.STORED_MIN))
	return bank + DECAY_REFUND

# Adulthood arriving, free of charge. Stops at MATURITY_AGE, which is why the
# difference between two twenty-five-year-olds is what they DID and not how
# they were born.
static func _mature(actor: Actor, rng: RandomNumberGenerator) -> void:
	if actor.age() > MATURITY_AGE:
		return
	var def := Drive.def("stat") as StatDef
	if def == null:
		return
	# Growing up cannot take somebody past what they were ever going to be:
	# maturation aims BELOW potential, and training covers the rest.
	var potential: float = float(actor.data.get("potential", 55))
	var ceiling: int = int(round(minf(lerpf(ADULT_BASELINE, potential, 0.45), potential)))
	for id: String in def.base_ids():
		var current: int = actor.stat(id)
		if current >= ceiling:
			continue
		actor.set_stat(id, mini(
			current + rng.randi_range(MATURITY_STEP_MIN, MATURITY_STEP_MAX), ceiling))

# The body after thirty, accelerating. Nothing here touches a skill.
static func _decline(actor: Actor, rng: RandomNumberGenerator) -> void:
	var over: int = actor.age() - DECLINE_FROM_AGE
	if over <= 0:
		return
	var loss: float = DECLINE_PER_YEAR + float(over) * DECLINE_ACCELERATION
	for id: String in PHYSICAL:
		var drop: int = int(round(maxf(loss + rng.randfn(0.0, 0.6), 0.0)))
		actor.set_stat(id, maxi(actor.stat(id) - drop, 5))
