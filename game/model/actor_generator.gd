# ActorGenerator — invents people. Deterministic: the same seed always yields
# the same actor, which is what makes a career reproducible and lets the match
# simulation be replayed.
#
# No archetype system, on purpose. Each derived stat reads a DIFFERENT trio of
# base attributes, so plain variance across the 7 already produces specialists
# — the actor who rolled high agility and low dexterity simply IS a safety,
# and nobody had to decide that. `test_actor.gd` measures how much spread this
# actually creates so `SPREAD` is tuned against numbers, not vibes.
class_name ActorGenerator

const AGE_MIN := 16
const AGE_MAX := 42
const STAT_MIN := 1
const STAT_MAX := 99
# Standard deviation of the bell curve around the quality target.
const SPREAD := 14.0
# Roughly how many amateur athletes go by a nickname at the field.
const NICKNAME_CHANCE := 0.6

static func generate(
	seed_value: int,
	quality: int,
	gender: String = Actor.GENDER_MASC,
	spread: float = SPREAD,
	age_min: int = AGE_MIN,
	age_max: int = AGE_MAX,
) -> Actor:
	var rng: RandomNumberGenerator = SeedRng.make_rng(seed_value)
	var actor := Actor.new()
	var payload: Dictionary = {
		"gender": gender,
		"age": rng.randi_range(age_min, age_max),
		"stats": _roll_stats(rng, quality, spread),
		"perks": [],
		"team": Actor.NO_TEAM,
		"jersey": Actor.NO_JERSEY,
	}
	payload.merge(_roll_name(rng, gender))
	actor._apply_data("actor_%d" % seed_value, "actor", payload)
	return actor

# A cohort sharing one base seed. Each actor gets a salted sub-seed so adding
# or removing one does not reshuffle the others.
static func squad(
	base_seed: int,
	count: int,
	quality: int,
	gender: String = Actor.GENDER_MASC,
	spread: float = SPREAD,
) -> Array[Actor]:
	var out: Array[Actor] = []
	for i: int in range(count):
		var sub_seed: int = SeedRng.derive(base_seed, "actor_%d" % i)
		out.append(generate(sub_seed, quality, gender, spread))
	return out

# --- Internals ---

static func _roll_stats(rng: RandomNumberGenerator, quality: int, spread: float) -> Dictionary:
	var def := Drive.def("stat") as StatDef
	var out: Dictionary = {}
	if def == null:
		return out
	for id: String in def.base_ids():
		out[id] = clampi(int(round(rng.randfn(float(quality), spread))), STAT_MIN, STAT_MAX)
	return out

static func _roll_name(rng: RandomNumberGenerator, gender: String) -> Dictionary:
	var names := Drive.def("name_gen") as NameGenDef
	if names == null:
		return {"first_name": "", "last_name": "", "nickname": ""}
	return {
		"first_name": names.random_first_name(gender, rng),
		"last_name": names.random_last_name(rng),
		"nickname": names.random_nickname(gender, rng) if rng.randf() < NICKNAME_CHANCE else "",
	}
