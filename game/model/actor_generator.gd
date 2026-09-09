# ActorGenerator — invents people. Deterministic: the same seed always yields
# the same actor, which is what makes a career reproducible and lets the match
# simulation be replayed.
#
# No archetype system, on purpose. Attributes AND skills are rolled with
# variance, and a skill roll sums the two — so the actor who came out with high
# agility and a trained juke simply IS an evasive receiver, and nobody had to
# decide that. `test_actor.gd` measures the spread so SPREAD is tuned against
# numbers, not vibes.
class_name ActorGenerator

const AGE_MIN := 16
const AGE_MAX := 42
const STAT_MIN := 1
const STAT_MAX := 99
# Standard deviation of the bell curve around the quality target.
const SPREAD := 14.0
# Practice lags aptitude: an actor knows less than they could.
const SKILL_LAG := 12
# Nobody in the game is a toddler and nobody is an Olympic medallist. The
# worst sandlot player is still an adult (about 4 steps) and the champion is
# near the national side (about 8), so club reputation maps into that band
# rather than straight onto the attribute scale.
const QUALITY_FLOOR := 35
const QUALITY_CEILING := 80
# Roughly how many amateur athletes go by a nickname at the field.
const NICKNAME_CHANCE := 0.6

static func generate(
	seed_value: int,
	quality: int,
	category: String = Actor.CATEGORY_MASC,
	spread: float = SPREAD,
	age_min: int = AGE_MIN,
	age_max: int = AGE_MAX,
) -> Actor:
	var rng: RandomNumberGenerator = SeedRng.make_rng(seed_value)
	var actor := Actor.new()
	var stats: Dictionary = _roll_stats(rng, quality, spread)
	var skills: Dictionary = _roll_skills(rng, quality - SKILL_LAG, spread)
	var payload: Dictionary = {
		"plays": [category],
		"manages": [],
		"age": rng.randi_range(age_min, age_max),
		"stats": stats,
		"skills": skills,
		"perks": [],
		"team": Actor.NO_TEAM,
		"jersey": Actor.NO_JERSEY,
	}
	payload.merge(_roll_body(rng, stats))
	payload.merge(_roll_name(rng, category))
	actor._apply_data("actor_%d" % seed_value, "actor", payload)
	return actor

# A cohort sharing one base seed. Each actor gets a salted sub-seed so adding
# or removing one does not reshuffle the others.
static func squad(
	base_seed: int,
	count: int,
	quality: int,
	category: String = Actor.CATEGORY_MASC,
	spread: float = SPREAD,
) -> Array[Actor]:
	var out: Array[Actor] = []
	for i: int in range(count):
		var sub_seed: int = SeedRng.derive(base_seed, "actor_%d" % i)
		out.append(generate(sub_seed, quality, category, spread))
	return out

# --- Internals ---

# Club reputation is not an attribute value. A club at reputation 12 fields
# bad adults, not children.
static func quality_from_reputation(reputation: int) -> int:
	var t: float = clampf(float(reputation) / 100.0, 0.0, 1.0)
	return int(round(lerpf(float(QUALITY_FLOOR), float(QUALITY_CEILING), t)))

static func _roll_skills(rng: RandomNumberGenerator, quality: int, spread: float) -> Dictionary:
	var def := Drive.def("stat") as StatDef
	var out: Dictionary = {}
	if def == null:
		return out
	for id: String in def.skill_ids():
		out[id] = clampi(int(round(rng.randfn(float(quality), spread))), STAT_MIN, STAT_MAX)
	return out

static func _roll_stats(rng: RandomNumberGenerator, quality: int, spread: float) -> Dictionary:
	var def := Drive.def("stat") as StatDef
	var out: Dictionary = {}
	if def == null:
		return out
	for id: String in def.base_ids():
		out[id] = clampi(int(round(rng.randfn(float(quality), spread))), STAT_MIN, STAT_MAX)
	return out

# The name pool follows the squad's category, which is a good enough proxy for
# an ISS-of-flag: a men's side draws from the men's pool. A mixed side flips a
# coin, because a mixed squad genuinely holds both.
# Height is its own roll; weight follows from height AND strength, so the body
# agrees with the sheet — the 90-strength actor is visibly the heavy one, and
# nobody has to reconcile a wiry giant who bench-presses a car.
static func _roll_body(rng: RandomNumberGenerator, stats: Dictionary) -> Dictionary:
	var def := Drive.def("stat") as StatDef
	var height_spec: Dictionary = def.measure("height") if def != null else {}
	var weight_spec: Dictionary = def.measure("weight") if def != null else {}
	var height: float = clampf(
		rng.randfn(1.78, 0.075),
		float(height_spec.get("min", 1.55)), float(height_spec.get("max", 2.05)))
	# BMI climbs with strength: lean at 21, thick at 28.
	var strength: float = float(stats.get("strength", 50)) / float(STAT_MAX)
	var bmi: float = lerpf(21.0, 28.0, strength) + rng.randfn(0.0, 1.0)
	var weight: float = clampf(
		bmi * height * height,
		float(weight_spec.get("min", 50.0)), float(weight_spec.get("max", 130.0)))
	return {"height": snappedf(height, 0.01), "weight": snappedf(weight, 1.0)}

static func _roll_name(rng: RandomNumberGenerator, category: String) -> Dictionary:
	var names := Drive.def("name_gen") as NameGenDef
	if names == null:
		return {"first_name": "", "last_name": "", "nickname": ""}
	var pool: String = category
	if category == Actor.CATEGORY_MISTO:
		pool = Actor.CATEGORY_FEM if rng.randf() < 0.5 else Actor.CATEGORY_MASC
	return {
		"first_name": names.random_first_name(pool, rng),
		"last_name": names.random_last_name(rng),
		"nickname": names.random_nickname(pool, rng) if rng.randf() < NICKNAME_CHANCE else "",
	}
