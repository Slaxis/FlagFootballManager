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

var perk: String = ""
# Which of the three scenarios this manager came from. It biases the sheet and
# it decides what kind of club is waiting.
var origin: String = ""
# The same ceiling every squad player has (decisions 27 and 34), drawn from the
# world this scenario drops you into. The manager used to be the only person on
# screen without one, which is why he came out heroic: a squad player is capped
# at city level and the manager could build ten steps of anything by hand.
var potential: int = StatDef.STORED_MAX

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
const OPENING_FLOOR_STEP := 2
# Below this the eighteen years do not fit under the ceiling.
const MIN_MANAGER_POTENTIAL := 45
# And nobody is a prodigy yet. Two steps past the average ADULT is already a
# remarkable child; the ruler puts 10 at an Olympic medal contender, and the
# appetite will happily buy one at twelve if nothing stops it.
const OPENING_CEILING_STEP := 7

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
static func rolled_opening(rng: RandomNumberGenerator, origin: String = "") -> SheetBuilder:
	var builder: SheetBuilder = average_adult()
	var def := Drive.def("stat") as StatDef
	if def == null:
		return builder
	for id: String in def.base_ids():
		builder.stats[id] = MIN_STAT_STEP
	for id: String in def.skill_ids():
		builder.skills[id] = MIN_SKILL_STEP
	builder.perk = ""
	builder.origin = origin
	var origins := Drive.def("origin") as OriginDef
	var level: float = origins.club_level(origin) if origins != null and origin != "" else 1.0
	# Floored so the whole life is spendable: at three steps the eight
	# attributes and fifteen skills together hold only 324 career points, and a
	# manager would finish the screen with a hundred he could never spend.
	# Four steps is an ordinary adult, not a hero.
	builder.potential = maxi(ActorLife.roll_potential(level, rng), MIN_MANAGER_POTENTIAL)
	builder._roll_body(def, rng, OPENING_BODY_TIGHTNESS)
	builder._roll_perk(rng)
	builder._apply_origin(def)

	for id: String in def.base_ids():
		while int(builder.stats[id]) < OPENING_FLOOR_STEP and builder.can_raise_stat(id):
			builder.raise_stat(id)

	# Two appetites, so a rolled sheet has practice on it as well as aptitude.
	var appetite: Dictionary = {}
	for id: String in def.base_ids() + def.skill_ids():
		appetite[id] = exp(rng.randfn(0.0, OPENING_APPETITE_SPREAD))
	var guard: int = 0
	while guard < 900:
		guard += 1
		var ids: Array[String] = []
		var weights: Array[float] = []
		for id: String in def.base_ids():
			if builder.can_raise_stat(id):
				ids.append(id)
				weights.append(float(appetite[id]) / float(int(builder.stats[id]) + 1))
		for id: String in def.skill_ids():
			if builder.can_raise_skill(id):
				ids.append("skill:" + id)
				weights.append(float(appetite[id]) / float(int(builder.skills[id]) + 2))
		if ids.is_empty():
			break
		var chosen: String = ids[builder._weighted_index(weights, rng)]
		if chosen.begins_with("skill:"):
			builder.raise_skill(chosen.substr(6))
		else:
			builder.raise_stat(chosen)
	return builder

# The origin's own allocation, bought at the normal price so it costs the same
# years it would have cost by hand.
func _apply_origin(def: StatDef) -> void:
	var origins := Drive.def("origin") as OriginDef
	if origins == null or origin == "" or not origins.has_origin(origin):
		return
	for id: String in origins.stat_bias(origin).keys():
		if not def.has_base(id):
			continue
		var wanted: int = int(origins.stat_bias(origin)[id])
		while int(stats.get(id, 0)) < wanted and can_raise_stat(id):
			raise_stat(id)
	for id: String in origins.skill_bias(origin).keys():
		if not def.has_skill(id):
			continue
		var wanted: int = int(origins.skill_bias(origin)[id])
		while int(skills.get(id, 0)) < wanted and can_raise_skill(id):
			raise_skill(id)

# --- Spending ---# --- Spending ---# --- Spending ---

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
		"origin": origin,
		"potential": potential,
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
