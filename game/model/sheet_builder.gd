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

# Nothing is rolled. You are born at zero in everything and allocate the whole
# eighteen years — which is also why the seed no longer touches the manager:
# rerolling it changes the world, never you.
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

var stats: Dictionary = {}    # id -> step
var skills: Dictionary = {}   # id -> step
var height: float = 1.78
var weight: float = 78.0

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

# --- Spending ---

func spent() -> int:
	var total: int = 0
	for id: String in stats.keys():
		total += _cost_between(int(_base_stats.get(id, 0)), int(stats[id])) * STAT_POINT_IN_CAREER
	for id: String in skills.keys():
		total += _cost_between(int(_base_skills.get(id, 0)), int(skills[id])) * SKILL_POINT_IN_CAREER
	return total + body_cost()

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

# You leave this screen at eighteen or not at all. Every unspent point is a
# year you did not live, and the game has no room for a manager who is still
# fifteen — so the button that starts the career stays shut until the budget is
# gone. Rearranging is free; leaving early is not.
func is_complete() -> bool:
	return remaining() == 0

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
		"perks": [],
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
