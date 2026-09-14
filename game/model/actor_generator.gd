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
# And how many carry one sentence about themselves. Kept below half so the
# perk stays a thing you notice on a roster rather than a column.
const PERK_CHANCE := 0.25
# A good club's players skew to boons and a sandlot side to flaws — the same
# reputation dial that sets quality, read a second time.
const BOON_AT_FLOOR := 0.25
const BOON_AT_CEILING := 0.85

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
	# A mixed squad genuinely holds both, so the coin decides which slot this
	# actor fills — and `plays` records it, because "mixed" on its own would
	# leave the women's quota uncountable.
	var pool: String = category
	if category == Actor.CATEGORY_MISTO:
		pool = Actor.CATEGORY_FEM if rng.randf() < 0.5 else Actor.CATEGORY_MASC
		payload["plays"] = [pool, Actor.CATEGORY_MISTO]
	payload.merge(_roll_name(rng, pool, stats, skills))
	payload["perks"] = _roll_perks(rng, quality)
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

# The name pool follows the slot the actor fills, which is a good enough proxy
# for an ISS-of-flag: a men's side draws from the men's pool.
static func _roll_name(rng: RandomNumberGenerator, pool: String,
		stats: Dictionary, skills: Dictionary) -> Dictionary:
	var names := Drive.def("name_gen") as NameGenDef
	if names == null:
		return {"first_name": "", "last_name": "", "nickname": ""}
	var first: String = names.random_first_name(pool, rng)
	var last: String = names.random_last_name(rng)
	var nickname: String = ""
	if rng.randf() < NICKNAME_CHANCE:
		# The apelido is drawn AFTER the sheet so it can be about the sheet:
		# the 9-agility receiver gets called Foguete, and the one who drops
		# everything gets called Manteiga.
		nickname = names.nickname_for(first, last, pool, _traits(stats, skills), rng)
	return {"first_name": first, "last_name": last, "nickname": nickname}

# Stored values into the steps the nickname table is keyed on.
static func _traits(stats: Dictionary, skills: Dictionary) -> Array:
	var def := Drive.def("stat") as StatDef
	if def == null:
		return []
	var stat_steps: Dictionary = {}
	var skill_steps: Dictionary = {}
	for id: String in stats.keys():
		stat_steps[id] = def.step(int(stats[id]))
	for id: String in skills.keys():
		skill_steps[id] = def.step(int(skills[id]))
	return def.notable_traits(stat_steps, skill_steps)

# One perk at most, same rule the creation screen plays by — an NPC roster and
# the manager are built out of the same catalogue, so a scouted player reads
# exactly like a created one.
static func _roll_perks(rng: RandomNumberGenerator, quality: int) -> Array:
	var def := Drive.def("perk") as PerkDef
	if def == null or def.max_per_actor <= 0 or rng.randf() >= PERK_CHANCE:
		return []
	var t: float = clampf(
		float(quality - QUALITY_FLOOR) / float(QUALITY_CEILING - QUALITY_FLOOR), 0.0, 1.0)
	var boon: bool = rng.randf() < lerpf(BOON_AT_FLOOR, BOON_AT_CEILING, t)
	var pool: Array[String] = def.boons() if boon else def.flaws()
	if pool.is_empty():
		pool = def.perk_ids()
	if pool.is_empty():
		return []
	return [pool[rng.randi() % pool.size()]]
