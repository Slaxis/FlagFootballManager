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

const START_AGE := 12
const END_AGE := 18
const POINTS_PER_YEAR := 8

# A twelve-year-old: a bit under half an adult, and barely any practice.
const CHILD_ATTRIBUTE_STEP := 3
const CHILD_SKILL_STEP := 1

# Cost of ENTERING each step. Attributes climb steeply because the scale means
# something: ten steps is an Olympic medal contender, and nobody buys that at
# eighteen.
# Every step must have a price, including the low ones: a table starting at 4
# silently makes an attribute rolled at 2 impossible to ever raise, because
# there is no cost to look up and the button just never enables.
const ATTRIBUTE_COST: Dictionary = {1: 1, 2: 1, 3: 1, 4: 1, 5: 2, 6: 3, 7: 5, 8: 8, 9: 13, 10: 21}
# Skills are practice, so they are cheap — but they cap out at the same wall.
const SKILL_COST: Dictionary = {1: 1, 2: 1, 3: 2, 4: 2, 5: 3, 6: 3, 7: 4, 8: 4, 9: 5, 10: 5}

var stats: Dictionary = {}    # id -> step
var skills: Dictionary = {}   # id -> step
var height: float = 1.78
var weight: float = 78.0

var _base_stats: Dictionary = {}
var _base_skills: Dictionary = {}

static func total_points() -> int:
	return (END_AGE - START_AGE) * POINTS_PER_YEAR

# Rolls the twelve-year-old this build starts from. Deterministic per seed, so
# the same career always offers the same child.
static func child(seed_value: int) -> SheetBuilder:
	var builder := SheetBuilder.new()
	var def := Drive.def("stat") as StatDef
	if def == null:
		return builder
	var rng: RandomNumberGenerator = SeedRng.make_rng(seed_value)
	for id: String in def.base_ids():
		builder.stats[id] = clampi(CHILD_ATTRIBUTE_STEP + rng.randi_range(-1, 1), 1, StatDef.MAX_STEP)
	for id: String in def.skill_ids():
		builder.skills[id] = clampi(CHILD_SKILL_STEP + rng.randi_range(0, 1), 0, StatDef.MAX_STEP)
	builder.height = snappedf(rng.randfn(1.78, 0.075), 0.01)
	builder.weight = snappedf(rng.randfn(78.0, 9.0), 1.0)
	builder._base_stats = builder.stats.duplicate()
	builder._base_skills = builder.skills.duplicate()
	return builder

# --- Spending ---

func spent() -> int:
	var total: int = 0
	for id: String in stats.keys():
		total += _cost_between(ATTRIBUTE_COST, int(_base_stats.get(id, 0)), int(stats[id]))
	for id: String in skills.keys():
		total += _cost_between(SKILL_COST, int(_base_skills.get(id, 0)), int(skills[id]))
	return total

func remaining() -> int:
	return total_points() - spent()

# The whole point: your age IS how much you spent.
func age() -> int:
	return START_AGE + int(floor(float(spent()) / float(POINTS_PER_YEAR)))

func cost_to_raise_stat(id: String) -> int:
	return int(ATTRIBUTE_COST.get(int(stats.get(id, 0)) + 1, -1))

func cost_to_raise_skill(id: String) -> int:
	return int(SKILL_COST.get(int(skills.get(id, 0)) + 1, -1))

func can_raise_stat(id: String) -> bool:
	var cost: int = cost_to_raise_stat(id)
	return cost >= 0 and cost <= remaining()

func can_raise_skill(id: String) -> bool:
	var cost: int = cost_to_raise_skill(id)
	return cost >= 0 and cost <= remaining()

# You can never go below the child you were rolled as — those years were not
# yours to spend.
func can_lower_stat(id: String) -> bool:
	return int(stats.get(id, 0)) > int(_base_stats.get(id, 0))

func can_lower_skill(id: String) -> bool:
	return int(skills.get(id, 0)) > int(_base_skills.get(id, 0))

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

static func _cost_between(table: Dictionary, from_step: int, to_step: int) -> int:
	var total: int = 0
	for step: int in range(from_step + 1, to_step + 1):
		total += int(table.get(step, 0))
	return total
