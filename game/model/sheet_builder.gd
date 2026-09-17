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

# The dice roll a CHILD, never an adult. Twelve years of childhood come out of
# `rolled_opening` — the body, a shape across the eight attributes, sometimes a
# perk — and the six years that turn that child into an adult are the ones you
# spend. That is true of the sheet the screen opens with and of every press of
# the 🎲: one verb, not two.
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

# Roughly how many rolled children come out with a perk, and how many of those
# are a boon rather than a flaw. Both are tones, not rewards: a flaw hands
# career points back.
const OPENING_PERK_CHANCE := 0.55
const OPENING_BOON_CHANCE := 0.70

var stats: Dictionary = {}    # id -> step
var skills: Dictionary = {}   # id -> step
var height: float = 1.78
var weight: float = 78.0

# Perks, plural, and paid for out of their OWN currency (decision 45). Career
# points are training; a perk is what a career did to you. Keeping them in one
# pocket meant a talent cost the same as two seasons in the gym, which is not
# the same kind of thing at all.
var perks: Array[String] = []
var perk_points: int = 0
# Which of the three scenarios this manager came from. It biases the sheet and
# it decides what kind of club is waiting.
var origin: String = ""
# The same ceiling every squad player has (decisions 27 and 34), drawn from the
# world this scenario drops you into. The manager used to be the only person on
# screen without one, which is why he came out heroic: a squad player is capped
# at city level and the manager could build ten steps of anything by hand.
var potential: int = StatDef.STORED_MAX
# What the rolled life actually cost. The budget is not a constant any more:
# 414 was calibrated against a ruler where an average adult sat at five steps,
# and on the new one a city-level person cannot absorb anywhere near that. So
# you are handed a person, and the points you may move around are HIS.
var budget: int = 0
var rolled_age: int = 0
# What the lived years were spent doing. Carried through to the Actor so the
# team screen can put him in the right box without re-deriving it.
var rolled_position: String = ""
var rolled_track: String = ""

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
	# The hand-built path keeps the classic allowance: a whole life to allocate.
	# Only the ROLLED path takes its budget from what the roll cost.
	builder.budget = total_points()
	builder.rolled_age = END_AGE
	return builder

# The age the opening roll leaves you at. Twelve years of childhood are rolled
# FOR you; the six that turn a kid into an adult are the ones you spend, and
# they are the whole point of the screen.
const OPENING_AGE := 12
# How tight the rolled body sits to the centre of its band.
const OPENING_BODY_TIGHTNESS := 0.55
# Narrower than the 🎲's appetite. With only eight tracks to spread across
# instead of twenty-three, the same spread concentrates hard enough to produce
# a child with 9 in one attribute and 0 in another — and on this ruler 9 is
# nearly a medal contender and 0 is less than a toddler.
const OPENING_APPETITE_SPREAD := 0.45
# Nobody alive is below a toddler. The floor is bought first so the spread has
# to work with what is left rather than being free to hollow somebody out.
# One step: enough that nobody is a literal zero across the board, which on
# this ruler would mean somebody who cannot take a field.
const OPENING_FLOOR_STEP := 1
# Q1 runs from ten to thirty. Twenty-five is two steps, which is the least that
# still fits what an origin promises — a student who cannot reach two steps of
# rules is not a student.
const MIN_MANAGER_POTENTIAL := 25
# The years everybody has just by having been around: playing on Sunday,
# helping out, watching. The origin's own years sit on top of these.
const BASE_YEARS := Vector2i(3, 6)
# And nobody is a prodigy yet. Two steps past the average ADULT is already a
# remarkable child; the ruler puts 10 at an Olympic medal contender, and the
# appetite will happily buy one at twelve if nothing stops it.
const OPENING_CEILING_STEP := 10

# Career points the opening roll spends: twelve years of them.
static func opening_budget() -> int:
	return OPENING_AGE * CAREER_POINTS_PER_YEAR

# The sheet the screen opens with: a rolled twelve-year-old who already leans
# the way his ORIGIN leans.
#
# Four rules, and each one is there for a reason.
#
# ATTRIBUTES AND SKILLS BOTH. The first version left every skill at zero and
# made you fill fifteen bars from nothing, which is a chore and not a choice —
# and it got worse once origins existed, because an ex-player with no skills is
# not an ex-player. You get a whole person; editing one is the game.
#
# THE ORIGIN GOES IN FIRST, at full price, before anything is rolled. A founder
# opens with leadership and a rulebook, an ex-player with hands and routes, a
# student with the playbook. It is the difference between the three scenarios
# and it is not a rounding error.
#
# THE WHOLE LIFE, NOT A CHILDHOOD. The roll used to stop at twelve and leave a
# hundred and thirty points in your pocket — so the screen said "12 anos" while
# you pumped leadership to eight, and out came a child genius. An eighteen-
# year-old with everything spent has no such state to be in, and editing him is
# selling something to buy something, which is a decision and not a chore.
#
# NOBODY IS HOLLOW, AND NOBODY IS A PRODIGY. Every attribute is walked to the
# floor before the appetite plays favourites, and nothing passes POTENTIAL —
# the same ceiling a squad player has, drawn from the world the scenario drops
# you into. The manager was the only person on screen without one.
# `origin_id` and not `origin`: the class has a member of that name, and a
# parameter shadowing it in a STATIC function is the confusing kind — the member
# is not even reachable from here.
static func rolled_opening(rng: RandomNumberGenerator, origin_id: String = "") -> SheetBuilder:
	var builder: SheetBuilder = average_adult()
	var def := Drive.def("stat") as StatDef
	var origins := Drive.def("origin") as OriginDef
	if def == null:
		return builder
	builder.origin = origin_id

	# LIVED, NOT ALLOCATED. The manager used to come out of a second generator
	# with its own appetite, and two generators drift — which is exactly how he
	# ended up heroic next to the squad he manages. Now he is an Actor like any
	# other: a birth sheet, a position his scenario put him in, and the years
	# that scenario gives him.
	var level: float = origins.club_level(origin_id) if origins != null and origin_id != "" else 1.0
	var track: String = origins.career_track(origin_id) if origins != null 		else ActorGenerator.TRACK_PLAYER
	# TWO SPANS, ADDED. The scenario's own years are what makes the three
	# different from each other — the ex-jogador has one to three years AS a
	# club player, the founder has none because there was no club. But every
	# one of them has been around the sport for a few years before that, the
	# way any adult in the várzea has, and without those years the sheet came
	# out at nothing: a budget of three career points, an uneditable screen,
	# and a manager who had never done anything.
	var years: int = BASE_YEARS.x + rng.randi() % int(BASE_YEARS.y - BASE_YEARS.x + 1)
	years += origins.career_years(origin_id, rng) if origins != null else 0
	var person: Actor = ActorGenerator.lived(rng, level, track, years)

	# Where the career actually happened, which the BODY decided and not the
	# scenario. This is the line that stopped every ex-player being a
	# quarterback: the track says "on the field", the matcher says where.
	builder.rolled_position = person.position()
	builder.rolled_track = track
	builder.potential = maxi(int(person.data.get("potential", 25)), MIN_MANAGER_POTENTIAL)
	builder.rolled_age = person.age()
	builder.height = person.height()
	builder.weight = person.weight()
	for id: String in def.base_ids():
		builder.stats[id] = def.step(person.stat(id))
	for id: String in def.skill_ids():
		builder.skills[id] = def.step(person.skill(id))
	builder.perk_points = origins.perk_points(origin_id) if origins != null and origin_id != "" else 1
	for id: Variant in person.perks():
		if builder.can_take_perk(String(id)):
			builder.perks.append(String(id))
	builder._apply_origin(def)
	# The budget IS what this person cost. You cannot make him bigger, only
	# different — sell a step here to buy one there.
	builder.budget = builder.spent()
	return builder

# The origin's own allocation, on top of the lived sheet: the founder brought
# leadership, the ex-player brought hands, the student brought a rulebook. It
# is applied before the budget is measured, so it is part of who he is rather
# than something he has to pay for twice.
func _apply_origin(def: StatDef) -> void:
	var origins := Drive.def("origin") as OriginDef
	if origins == null or origin == "" or not origins.has_origin(origin):
		return
	for id: String in origins.stat_bias(origin).keys():
		if not def.has_base(id):
			continue
		var wanted: int = int(origins.stat_bias(origin)[id])
		while int(stats.get(id, 0)) < wanted \
				and int(stats.get(id, 0)) < potential_step() \
				and int(stats.get(id, 0)) < StatDef.MAX_STEP:
			stats[id] = int(stats[id]) + 1
	for id: String in origins.skill_bias(origin).keys():
		if not def.has_skill(id):
			continue
		var wanted: int = int(origins.skill_bias(origin)[id])
		while int(skills.get(id, 0)) < wanted \
				and int(skills.get(id, 0)) < potential_step() \
				and int(skills.get(id, 0)) < StatDef.MAX_STEP:
			skills[id] = int(skills[id]) + 1

# --- Spending ---# --- Spending ---# --- Spending ---

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
	return budget - spent()

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
	# Only what the sheet would actually ALLOW. Reading the raw price meant a
	# manager whose every track sat at his ceiling still had a "cheapest
	# purchase" he could never make, so `is_complete()` never came true and the
	# start button never opened — the one-career-point deadlock again, wearing
	# a different hat.
	for id: String in stats.keys():
		if int(stats[id]) >= potential_step():
			continue
		var cost: int = cost_to_raise_stat(id)
		if cost >= 0 and (best < 0 or cost < best):
			best = cost
	for id: String in skills.keys():
		if int(skills[id]) >= potential_step():
			continue
		var cost: int = cost_to_raise_skill(id)
		if cost >= 0 and (best < 0 or cost < best):
			best = cost
	return best

# The age the life produced, not a function of the budget. Deriving it from
# spending was what let the header say "12 anos" while the sheet said eight
# steps of leadership — and with the manager now lived like everybody else,
# there is a real number to show instead of an inference.
func age() -> int:
	return rolled_age

# In career points, which is the only number the player ever spends.
func cost_to_raise_stat(id: String) -> int:
	var next_step: int = int(stats.get(id, 0)) + 1
	return -1 if next_step > StatDef.MAX_STEP else next_step * STAT_POINT_IN_CAREER

func cost_to_raise_skill(id: String) -> int:
	var next_step: int = int(skills.get(id, 0)) + 1
	return -1 if next_step > StatDef.MAX_STEP else next_step * SKILL_POINT_IN_CAREER

# Potential binds the PLAYER's own spending too, not just the roll. Capping
# only the dice would have left the superhero one click away.
func potential_step() -> int:
	return clampi(int(floor(float(potential) / 10.0)), 1, StatDef.MAX_STEP)

func can_raise_stat(id: String) -> bool:
	if int(stats.get(id, 0)) >= potential_step():
		return false
	var cost: int = cost_to_raise_stat(id)
	return cost >= 0 and cost <= remaining()

func can_raise_skill(id: String) -> bool:
	if int(skills.get(id, 0)) >= potential_step():
		return false
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
# Their own budget, spent freely. A flaw PAYS, so Vidraça buys Capitão — take
# as many as the balance allows and the balance is the only rule. The old cap
# of one existed because flaws refunded career points and the optimal build was
# the entire flaw list; on a separate ruler the budget does that job by itself.

func perk_points_spent() -> int:
	var def := Drive.def("perk") as PerkDef
	if def == null:
		return 0
	var total: int = 0
	for id: String in perks:
		total += def.cost(id)
	return total

func perk_points_left() -> int:
	return perk_points - perk_points_spent()

func has_perk(id: String) -> bool:
	return perks.has(id)

func can_take_perk(id: String) -> bool:
	var def := Drive.def("perk") as PerkDef
	if def == null or not def.has_perk(id):
		return false
	if perks.has(id):
		# Dropping a flaw costs back what it paid you, so it can be refused.
		return -def.cost(id) <= perk_points_left()
	return def.cost(id) <= perk_points_left()

func toggle_perk(id: String) -> void:
	if not can_take_perk(id):
		return
	if perks.has(id):
		perks.erase(id)
	else:
		perks.append(id)

# --- The dice ---

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
	if def == null or rng.randf() >= OPENING_PERK_CHANCE:
		return
	var pool: Array[String] = def.boons() if rng.randf() < OPENING_BOON_CHANCE else def.flaws()
	if pool.is_empty():
		return
	toggle_perk(pool[rng.randi() % pool.size()])

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
		"perks": perks.duplicate(),
		"origin": origin,
		"position": rolled_position,
		"lineup": _opening_lineup(),
		"potential": potential,
		"plays": [],
		"manages": [],
		"team": Actor.NO_TEAM,
		"jersey": Actor.NO_JERSEY,
	}
	payload.merge(name_parts)
	actor._apply_data("manager_%d" % seed_value, "actor", payload)
	return actor

# Which boxes you are ticked into on day one. The CHAIR always — the club gave
# you that the moment it took you on — and, if your years were spent playing,
# your own position too. The ex-jogador's own description promises he will have
# to carry the side himself early on; standing in the Comissão with nobody able
# to field him would have made that a lie.
func _opening_lineup() -> Array[String]:
	var origins := Drive.def("origin") as OriginDef
	var out: Array[String] = []
	if rolled_track == ActorGenerator.TRACK_PLAYER and rolled_position != "":
		out.append(rolled_position)
	var chair: String = origins.chair(origin) if origins != null and origin != "" else ""
	if chair != "" and not out.has(chair):
		out.append(chair)
	return out

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
