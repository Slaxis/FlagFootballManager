# SheetBuilder — character creation, priced in years of your life.
#
# You do not spend "20 points". You start as a twelve-year-old with a rolled
# sheet and spend the six years to eighteen, and the screen shows the age
# climbing as you allocate. Take points back and you get younger. The question
# stops being "how much budget do I have" and becomes the right one:
#
#     where did I invest my adolescence?
#
# Attributes and skills share the same pocket on purpose. A roll is
# `attribute + skill + 2d5*`, so training throwing and training dexterity both
# make you throw better — the player picks which, and neither is wrong.
class_name SheetBuilder

# The screen opens on somebody ROLLED, not on a blank line — but the roll stops
# while there is still an adolescence left to spend. You are handed a person
# with a shape and the same spare budget the flat average adult used to leave,
# and what you do with it is the question the screen asks.
#
# That is the difference between the two entry points:
#
#   rolled_opening()  a starting point — a person, plus points to make them yours
#   roll_random()     the 🎲 — a finished character you can walk out with
const START_AGE := 0
const END_AGE := 18
# Career points are the only currency. A year of life buys this many.
const CAREER_POINTS_PER_YEAR := 23

# Floors. The ORIGIN of every cost is zero — that is where refunds go back to —
# even though the screen hands you an average adult already paid for.
const MIN_STAT_STEP := 0
const MIN_SKILL_STEP := 0

# Where the screen starts you: an average adult with a median body, which costs
# 360 of the 414 career points and leaves 54 to spend. Identical to building it
# by hand from zero, minus forty clicks — and clicking is not a choice.
const START_STAT_STEP := 5
const START_HEIGHT := 1.80
const START_WEIGHT := 80.0

# Entering step N costs N points of its own kind: the first step is cheap and
# the tenth is brutal, which is what keeps "Olympic medal contender" out of
# reach at eighteen without needing a hand-tuned table.
#
# The two kinds then convert into career points at different rates, and THAT is
# where "attributes are hard, skills are easy" lives:
#
#     1 stat point   = 3 career points
#     1 skill point  = 2 career points
#
# So raising an attribute to step 5 costs 15 career points and raising a skill
# to the same step costs 10. Same shape, different weight.
const STAT_POINT_IN_CAREER := 3
const SKILL_POINT_IN_CAREER := 2

# How the 🎲 spends a whole life. Attributes get the larger appetite because a
# person is mostly what they are, and the appetite is then divided by the step
# already bought, so a track self-limits instead of eating the entire budget.
const RANDOM_STAT_APPETITE := 3.0
const RANDOM_SKILL_APPETITE := 1.0
# Lognormal sigma. At 0 everybody comes out identical and average; this is what
# makes one rolled actor a specialist and the next one a generalist.
const RANDOM_APPETITE_SPREAD := 0.85
const RANDOM_PERK_CHANCE := 0.55
const RANDOM_BOON_CHANCE := 0.70

var stats: Dictionary = {}    # id -> step
var skills: Dictionary = {}   # id -> step
var height: float = 1.78
var weight: float = 78.0

var perk: String = ""

var _base_stats: Dictionary = {}
var _base_skills: Dictionary = {}

static func total_points() -> int:
	return (END_AGE - START_AGE) * CAREER_POINTS_PER_YEAR

# The sheet the screen opens with: every attribute at the average adult, every
# skill at zero, and a body that sits squarely in the neutral band.
#
# Nothing here is random. An initial roll only teaches the player to mash
# reroll until the dice agree with the build they already wanted.
#
# The baselines stay at ZERO while the starting values do not: the cost of
# those five steps is already counted as spent, so the sheet opens at fifteen
# years old with 54 career points left, and selling an attribute back refunds
# all the way down to nothing.
static func average_adult() -> SheetBuilder:
	var builder := SheetBuilder.new()
	var def := Drive.def("stat") as StatDef
	if def == null:
		return builder
	for id: String in def.base_ids():
		builder._base_stats[id] = 0
		builder.stats[id] = START_STAT_STEP
	for id: String in def.skill_ids():
		builder._base_skills[id] = 0
		builder.skills[id] = 0
	builder.height = START_HEIGHT
	builder.weight = START_WEIGHT
	return builder

# What the flat average adult left in your pocket. Derived rather than written
# down, so it follows if the ladder or the budget is ever retuned.
static func opening_reserve() -> int:
	return total_points() - average_adult().spent()

# How far from the average adult an opening attribute strays, in steps.
const OPENING_SPREAD := 1.25
const OPENING_MIN_STEP := 2
const OPENING_MAX_STEP := 8
# A kid who has played before is not a blank slate, but they have not
# specialised either.
const OPENING_SKILLS_MIN := 1
const OPENING_SKILLS_MAX := 3
const OPENING_SKILL_STEP_MAX := 3

# The sheet the screen opens with: a rolled adolescent who still has the whole
# spare budget to spend.
#
# NOT the same roll as the 🎲. That one spends all 414 points, and a shape
# built to eat the entire budget puts a 10 in one skill and a 1 in half the
# attributes — fine as a finished character, wrong as a starting point. What
# the opening has to produce is somebody ORDINARY but not identical: the
# average adult, perturbed, with a couple of things they already know.
#
# The arithmetic says so too. Five steps in all eight attributes costs exactly
# the 360 the opening has, so every point of skill here is paid for out of an
# attribute. The roll walks each attribute to a target near the average,
# lowering before raising so the refunds are on the table first.
static func rolled_opening(rng: RandomNumberGenerator) -> SheetBuilder:
	var builder: SheetBuilder = average_adult()
	var def := Drive.def("stat") as StatDef
	if def == null:
		return builder
	var reserve: int = opening_reserve()
	builder._roll_body(def, rng, 0.55)

	var targets: Dictionary = {}
	for id: String in def.base_ids():
		targets[id] = clampi(
			int(round(rng.randfn(float(START_STAT_STEP), OPENING_SPREAD))),
			OPENING_MIN_STEP, OPENING_MAX_STEP)
	# Down first: selling is what pays for the raises.
	for id: String in def.base_ids():
		while int(builder.stats[id]) > int(targets[id]) and builder.can_lower_stat(id):
			builder.lower_stat(id)
	for id: String in def.base_ids():
		while int(builder.stats[id]) < int(targets[id]) \
				and builder.cost_to_raise_stat(id) <= builder.remaining() - reserve:
			builder.raise_stat(id)

	var ids: Array = def.skill_ids()
	for _i: int in range(rng.randi_range(OPENING_SKILLS_MIN, OPENING_SKILLS_MAX)):
		var id: String = String(ids[rng.randi() % ids.size()])
		var want: int = rng.randi_range(1, OPENING_SKILL_STEP_MAX)
		while int(builder.skills[id]) < want \
				and builder.cost_to_raise_skill(id) <= builder.remaining() - reserve:
			builder.raise_skill(id)

	# A run of low targets refunds more than the raises spend, and opening with
	# 130 points in hand is as much of a chore as opening with none is a blank.
	# The excess goes back into the shape that was just rolled.
	var guard: int = 0
	while builder.remaining() > reserve and guard < 200:
		guard += 1
		var affordable: Array[String] = []
		for id: String in def.base_ids():
			var cost: int = builder.cost_to_raise_stat(id)
			if cost >= 0 and cost <= builder.remaining() - reserve:
				affordable.append(id)
		if affordable.is_empty():
			break
		builder.raise_stat(affordable[rng.randi() % affordable.size()])
	return builder

# --- Spending ---# --- Spending ---

func spent() -> int:
	var total: int = 0
	for id: String in stats.keys():
		total += _cost_between(int(_base_stats.get(id, 0)), int(stats[id])) * STAT_POINT_IN_CAREER
	for id: String in skills.keys():
		total += _cost_between(int(_base_skills.get(id, 0)), int(skills[id])) * SKILL_POINT_IN_CAREER
	return total + body_cost() + perk_cost()

# The body is billed at exactly what the swap it performs is worth, so shape
# costs points and power does not come free. Moving away from the centre gives
# one attribute a step and takes a step from another — and because the ladder
# is triangular, the step you gain always costs more than the one you give up.
# That is true going up AND going down, which is why both directions are
# charged instead of only the tall one.
func body_cost() -> int:
	var def := Drive.def("stat") as StatDef
	if def == null:
		return 0
	return def.body_value({"height": height, "weight": weight}) * STAT_POINT_IN_CAREER

func can_move_body(id: String, value: float) -> bool:
	var def := Drive.def("stat") as StatDef
	if def == null:
		return true
	var values: Dictionary = {"height": height, "weight": weight}
	values[id] = value
	var after: int = def.body_value(values) * STAT_POINT_IN_CAREER
	return after - body_cost() <= remaining()

func remaining() -> int:
	return total_points() - spent()

# You leave this screen when there is nothing left to buy — which is not the
# same as leaving with zero.
#
# The denominations are 2 for a skill step and 3 for an attribute one, so a
# player can easily land on 1 career point that nothing in the game costs. The
# old rule demanded exactly zero and deadlocked them there: no purchase was
# affordable and the start button never opened.
func is_complete() -> bool:
	if remaining() < 0:
		return false
	var cheapest: int = cheapest_purchase()
	return cheapest < 0 or remaining() < cheapest

# Price of the least expensive thing still on offer, or -1 when everything is
# maxed out.
func cheapest_purchase() -> int:
	var best: int = -1
	for id: String in stats.keys():
		var cost: int = cost_to_raise_stat(id)
		if cost >= 0 and (best < 0 or cost < best):
			best = cost
	for id: String in skills.keys():
		var cost: int = cost_to_raise_skill(id)
		if cost >= 0 and (best < 0 or cost < best):
			best = cost
	return best

# The whole point: your age IS how much you spent.
func age() -> int:
	return START_AGE + int(floor(float(spent()) / float(CAREER_POINTS_PER_YEAR)))

# In career points, which is the only number the player ever spends.
func cost_to_raise_stat(id: String) -> int:
	var next_step: int = int(stats.get(id, 0)) + 1
	return -1 if next_step > StatDef.MAX_STEP else next_step * STAT_POINT_IN_CAREER

func cost_to_raise_skill(id: String) -> int:
	var next_step: int = int(skills.get(id, 0)) + 1
	return -1 if next_step > StatDef.MAX_STEP else next_step * SKILL_POINT_IN_CAREER

func can_raise_stat(id: String) -> bool:
	var cost: int = cost_to_raise_stat(id)
	return cost >= 0 and cost <= remaining()

func can_raise_skill(id: String) -> bool:
	var cost: int = cost_to_raise_skill(id)
	return cost >= 0 and cost <= remaining()

# Everything can be given back, all the way to zero.
func can_lower_stat(id: String) -> bool:
	return int(stats.get(id, 0)) > MIN_STAT_STEP

func can_lower_skill(id: String) -> bool:
	return int(skills.get(id, 0)) > MIN_SKILL_STEP

func raise_stat(id: String) -> void:
	if can_raise_stat(id):
		stats[id] = int(stats[id]) + 1

func raise_skill(id: String) -> void:
	if can_raise_skill(id):
		skills[id] = int(skills[id]) + 1

func lower_stat(id: String) -> void:
	if can_lower_stat(id):
		stats[id] = int(stats[id]) - 1

func lower_skill(id: String) -> void:
	if can_lower_skill(id):
		skills[id] = int(skills[id]) - 1

# --- Perks ---
#
# One sentence about you, priced in career points, and the price can be
# negative. A flaw hands points back — which is the only reason anybody would
# ever pick "drops what he shouldn't" — and the cap of one is what keeps the
# optimal build from being the whole flaw list.
#
# Optional on purpose: passing on the perk and putting everything into the
# sheet is a real answer, not a wasted slot.

func perk_cost() -> int:
	var def := Drive.def("perk") as PerkDef
	return def.cost(perk) if def != null and perk != "" else 0

func has_perk() -> bool:
	return perk != ""

# Swapping counts the difference, so trading a 40-point boon for a 25-point one
# does not ask you to afford both.
func can_take_perk(id: String) -> bool:
	var def := Drive.def("perk") as PerkDef
	if def == null:
		return false
	if id != "" and not def.has_perk(id):
		return false
	# Dropping a flaw is a PURCHASE: it costs back the points it paid you, and
	# without this you could take Vidraça, spend the thirty points, untick it
	# and walk out thirty points over budget.
	var wanted: int = def.cost(id) if id != "" else 0
	return wanted - perk_cost() <= remaining()

# Clicking the perk you already have takes it off: there is no "none" button to
# hunt for.
func set_perk(id: String) -> void:
	var wanted: String = "" if id == perk else id
	if can_take_perk(wanted):
		perk = wanted

# --- The dice ---

# Spends an entire life at random, legally: a body, maybe a perk, and every
# career point the two leave behind.
#
# Not a uniform fill. Each of the twenty-three tracks draws a lognormal
# APPETITE and the loop buys proportionally to it, divided by the step already
# paid for — so the cheap early steps go everywhere, the expensive late ones go
# only where the appetite was high, and what comes out is a person with a
# shape instead of a flat line at the average.
func roll_random(rng: RandomNumberGenerator) -> void:
	var def := Drive.def("stat") as StatDef
	if def == null:
		return
	for id: String in def.base_ids():
		stats[id] = MIN_STAT_STEP
	for id: String in def.skill_ids():
		skills[id] = MIN_SKILL_STEP
	perk = ""
	_roll_body(def, rng)
	_roll_perk(rng)

	var appetite: Dictionary = {}
	for id: String in def.base_ids():
		appetite[id] = RANDOM_STAT_APPETITE * exp(rng.randfn(0.0, RANDOM_APPETITE_SPREAD))
	for id: String in def.skill_ids():
		appetite[id] = RANDOM_SKILL_APPETITE * exp(rng.randfn(0.0, RANDOM_APPETITE_SPREAD))

	while true:
		var ids: Array[String] = []
		var weights: Array[float] = []
		for id: String in def.base_ids():
			if can_raise_stat(id):
				ids.append(id)
				weights.append(float(appetite[id]) / float(int(stats[id]) + 1))
		for id: String in def.skill_ids():
			if can_raise_skill(id):
				ids.append(id)
				weights.append(float(appetite[id]) / float(int(skills[id]) + 1))
		if ids.is_empty():
			return
		var chosen: String = ids[_weighted_index(weights, rng)]
		if stats.has(chosen):
			raise_stat(chosen)
		else:
			raise_skill(chosen)

# Height and weight land near the centre and rarely more than a band out — an
# extreme body costs most of the budget, and the roll should produce a person,
# not a stunt.
func _roll_body(def: StatDef, rng: RandomNumberGenerator, tightness: float = 0.85) -> void:
	for id: String in def.measure_ids():
		var spec: Dictionary = def.measure(id)
		var centre: float = float(spec.get("center", 0.0))
		var band_width: float = float(spec.get("band", 1.0))
		var value: float = clampf(
			rng.randfn(centre, band_width * tightness),
			float(spec.get("min", centre)), float(spec.get("max", centre)))
		if id == "height":
			height = snappedf(value, def.increment(id))
		else:
			weight = snappedf(value, def.increment(id))

func _roll_perk(rng: RandomNumberGenerator) -> void:
	var def := Drive.def("perk") as PerkDef
	if def == null or rng.randf() >= RANDOM_PERK_CHANCE:
		return
	var pool: Array[String] = def.boons() if rng.randf() < RANDOM_BOON_CHANCE else def.flaws()
	if pool.is_empty():
		return
	# Affordability is checked before the sheet is bought, so a 40-point boon is
	# always payable here and only the sheet gets thinner.
	set_perk(pool[rng.randi() % pool.size()])

func _weighted_index(weights: Array[float], rng: RandomNumberGenerator) -> int:
	var total: float = 0.0
	for w: float in weights:
		total += w
	if total <= 0.0:
		return rng.randi() % weights.size()
	var roll: float = rng.randf() * total
	for i: int in range(weights.size()):
		roll -= weights[i]
		if roll <= 0.0:
			return i
	return weights.size() - 1

# --- Result ---

# Bakes the build into an Actor, converting steps back into stored units so
# weekly training has somewhere finer to move.
func to_actor(seed_value: int, name_parts: Dictionary) -> Actor:
	var def := Drive.def("stat") as StatDef
	var actor := Actor.new()
	var stored_stats: Dictionary = {}
	var stored_skills: Dictionary = {}
	if def != null:
		for id: String in stats.keys():
			stored_stats[id] = def.stored_for(int(stats[id]))
		for id: String in skills.keys():
			stored_skills[id] = def.stored_for(int(skills[id]))
	var payload: Dictionary = {
		"age": age(),
		"height": height,
		"weight": weight,
		"stats": stored_stats,
		"skills": stored_skills,
		"perks": [perk] if perk != "" else [],
		"plays": [],
		"manages": [],
		"team": Actor.NO_TEAM,
		"jersey": Actor.NO_JERSEY,
	}
	payload.merge(name_parts)
	actor._apply_data("manager_%d" % seed_value, "actor", payload)
	return actor

# --- Internals ---

# Points of its own kind between two steps, signed. Walking DOWN returns what
# walking up would have cost — without the sign, selling your childhood back
# would burn the points instead of freeing them.
#
# Entering step N costs N, so the sum from a to b is the triangular difference.
static func _cost_between(from_step: int, to_step: int) -> int:
	if to_step == from_step:
		return 0
	var low: int = mini(from_step, to_step)
	var high: int = maxi(from_step, to_step)
	var total: int = 0
	for step: int in range(low + 1, high + 1):
		total += step
	return total if to_step > from_step else -total
