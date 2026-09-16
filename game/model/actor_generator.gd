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

# Reputation is the only dial. Quality (how good the weeks are) and career
# length (how many of them there were) are BOTH read off it, so they can never
# disagree — passing them separately let a caller ask for a great squad at a
# club nobody had heard of and get neither.
static func generate(
	seed_value: int,
	reputation: int,
	category: String = Actor.CATEGORY_MASC,
	club_level: float = 1.0,
	position: String = "",
) -> Actor:
	var spec: Dictionary = {"position": position} if position != "" else {}
	return _build(SeedRng.make_rng(seed_value), "actor_%d" % seed_value,
		quality_from_reputation(reputation), category, spec, reputation, club_level)

# Hydrates a CURATED actor: a sparse spec from ActorDef plus whatever the
# curator did not say. Everything pinned wins; everything absent is rolled.
#
# Seeded from the actor's ID, not from the career seed — a real athlete is the
# same person in every career, and only the squad-fillers around them move.
# Which also means a curator deepening a spec later changes only the numbers
# they touched: the rest was already a function of the id.
static func from_spec(spec: Dictionary, reputation: int,
		category: String = Actor.CATEGORY_MASC, club_level: float = 1.0) -> Actor:
	var id: String = String(spec.get("id", "")).strip_edges()
	return _build(SeedRng.make_rng(SeedRng.seed_from_string(id)), id,
		int(spec.get("quality", quality_from_reputation(reputation))),
		category, spec, reputation, club_level)

# How long somebody has been playing, by how established the club is. This is
# the whole of decision 26's first half: an entry club is full of kids because
# its players have one or two seasons behind them, not because anybody rolled
# a low age. Lognormal, so the tail is a veteran who stayed rather than a
# symmetric spread around a mean nobody occupies.
const YEARS_AT_ENTRY_CLUB := 1.6
const YEARS_AT_ELITE_CLUB := 9.0
const YEARS_SPREAD := 0.62

static func career_years(reputation: int, rng: RandomNumberGenerator) -> int:
	var maturity: float = clampf(float(reputation) / 100.0, 0.0, 1.0)
	var centre: float = lerpf(YEARS_AT_ENTRY_CLUB, YEARS_AT_ELITE_CLUB, maturity)
	return clampi(int(round(exp(rng.randfn(log(centre), YEARS_SPREAD)))), 0, 26)

# How good the weeks were. Club quality is not a target any more (decision 26):
# it lifts what a good week is worth and it cannot rescue a bad one.
static func _climate(quality: int, will_stored: int) -> Dictionary:
	var t: float = clampf(
		float(quality - QUALITY_FLOOR) / float(QUALITY_CEILING - QUALITY_FLOOR), 0.0, 1.0)
	# Dedication is the xp a person puts in on an ordinary day, before the die
	# says how the day went. Two is the good week (the gym most days at 75%);
	# `will` moves it either side, so the driven athlete lives at three and the
	# one who shows up when he feels like it lives at one.
	return {
		"training": lerpf(0.6, 1.35, t),
		# Floored at one: "corpo mole" is a bad WEEK, and the die already
		# delivers those. A permanent zero meant a whole decade of career
		# earning nothing, which is not a lazy athlete, it is a bug.
		"dedication": clampi(2 + int(floor(float(will_stored) / 10.0)) - 5, 1, 4),
	}

# --- Spawning ---
#
# THE ONLY WAY A PERSON ENTERS THE WORLD. Squads used to conjure their own
# members, which meant a club invented exactly the people it needed and there
# was no answer to "where did this man come from" other than "the club needed
# a center". Now everybody is born into the Praça with no club at all, and the
# clubs draft out of it — so the same event that fills a roster is the one that
# starts your career, and the market exists from minute one.
#
# A TRACK, NOT A POSITION. What varies between people is not which chair they
# were assigned but which KIND of life they lived: on the field, or beside it.
# Where on the field is then a question for the body, answered by the matcher.
const TRACK_PLAYER := "player"
const TRACK_STAFF := "staff"

# Level is the world ladder NationDef hands out — 1 is a neighbourhood side, 5
# is an IFAF star's club. It is the only dial: how good the weeks were and how
# many of them there have been both come off it, so they can never disagree.
static func spawn(world_seed: int, actor_seed: int, level: float,
		category: String = Actor.CATEGORY_MASC,
		track: String = TRACK_PLAYER, years: int = -1) -> Actor:
	return _lived(
		SeedRng.make_rng(SeedRng.derive(world_seed, "praca_%d" % actor_seed)),
		"actor_%d_%d" % [world_seed, actor_seed], level, category, track, years)

# YOU ARE NOT CREATING A FIFTEEN-YEAR-OLD. Everybody else spawns as a kid and
# grows up, because that is how a squad gets its age spread — but the person on
# the creation screen is a grown adult by definition, and rolling him a child's
# debut produced managers of fifteen with an empty sheet and nothing to edit.
const MANAGER_DEBUT_MIN := 18
const MANAGER_DEBUT_MAX := 22

# The creation screen's door into the same production line. It takes an rng
# rather than a seed because 🎲 has to deal a different person every press —
# the world seed is what the NAME spells, and the dice are not the world.
static func lived(rng: RandomNumberGenerator, level: float,
		track: String, years: int) -> Actor:
	return _lived(rng, "manager", level, Actor.CATEGORY_MASC, track, years,
		rng.randi_range(MANAGER_DEBUT_MIN, MANAGER_DEBUT_MAX))

static func _lived(rng: RandomNumberGenerator, thing_id: String, level: float,
		category: String, track: String, years: int, debut: int = -1) -> Actor:
	var reputation: int = level_to_reputation(level)
	var spec: Dictionary = {"track": track}
	if years >= 0:
		spec["career_years"] = years
	if debut >= 0:
		spec["debut_age"] = debut
	return _build(rng, thing_id, quality_from_reputation(reputation),
		category, spec, reputation, level)

# A club at the bottom of the ladder is a reputation-20 club, and one at the
# top is a hundred. Both dials already existed; this is the sentence that says
# they are the same dial read twice.
static func level_to_reputation(level: float) -> int:
	return clampi(int(round(clampf(level, 0.0, 5.0) * 20.0)), 0, 100)

# The one construction path. `spec` is empty for an invented actor and holds
# whatever a curator pinned for an authored one, so the two cannot drift apart.
static func _build(
	rng: RandomNumberGenerator,
	thing_id: String,
	quality: int,
	category: String,
	spec: Dictionary,
	reputation: int,
	club_level: float,
) -> Actor:
	var actor := Actor.new()
	var def := Drive.def("stat") as StatDef
	var positions := Drive.def("position") as PositionDef
	var birth: Dictionary = ActorLife.birth_sheet(rng)
	var debut: int = int(spec.get("debut_age", ActorLife.roll_debut_age(rng)))
	var years: int = int(spec.get("career_years", career_years(reputation, rng)))
	var payload: Dictionary = {
		"plays": [category],
		"manages": [],
		"age": debut,
		"debut_age": debut,
		"potential": ActorLife.roll_potential(club_level, rng),
		# WHERE ON THE LADDER THIS PERSON WAS DRAWN. Carried on the actor
		# because the draft needs to compare him to a club on the same ruler,
		# and Geral is not that ruler — it is a 0..100 average of attributes
		# that, at this tier, never leaves the twenties.
		"level": club_level,
		"stats": birth,
		"skills": def.blank_skills(0) if def != null else {},
		"perks": [],
		"team": Actor.NO_TEAM,
		"jersey": Actor.NO_JERSEY,
	}
	actor._apply_data(thing_id if thing_id != "" else "actor", "actor", payload)

	# Where this body ends up, then that many years of being there. The track
	# says which SIDE of the whitewash the career happened on; the body says
	# where exactly, because a fast kid with hands ends up catching whether or
	# not anybody planned it.
	var position: String = String(spec.get("position", ""))
	if position == "" and positions != null:
		var sides: Array[String] = PositionDef.PLAYING_SIDES
		if String(spec.get("track", TRACK_PLAYER)) == TRACK_STAFF:
			sides = [PositionDef.SIDE_STAFF]
		position = positions.match_on_sides(birth, {}, rng, sides)
	actor.data["position"] = position
	var declared: Array = spec.get("career", [])
	for year: int in range(years):
		# Recomputed every season. `will` grows as somebody grows up, and a
		# fifteen-year-old genuinely does not train like a man of twenty-two —
		# computing this once before the loop froze everybody at a child's
		# dedication and left half the squad with a blank sheet.
		var climate: Dictionary = _climate(quality, actor.stat("will"))
		var season: Dictionary = declared[year] if year < declared.size() else {}
		_live_one_year(actor, position, climate, season, rng)

	# Pinned numbers land BEFORE the body, so the body is built around the sheet
	# the curator actually meant.
	if spec.has("stats"):
		actor.data["stats"].merge(_numbers(spec["stats"]), true)
	if spec.has("skills"):
		actor.data["skills"].merge(_numbers(spec["skills"]), true)
	# And the body follows the sheet the career produced, not the one it started
	# with: a rusher who spent ten years in the gym is not built like the kid
	# who walked in.
	actor.data.merge(_roll_body(rng, actor.stats()), true)
	var pool: String = category
	if category == Actor.CATEGORY_MISTO:
		pool = Actor.CATEGORY_FEM if rng.randf() < 0.5 else Actor.CATEGORY_MASC
		actor.data["plays"] = [pool, Actor.CATEGORY_MISTO]
	actor.data.merge(_roll_name(rng, pool, actor.stats(), actor.skills()), true)
	actor.data["perks"] = _roll_perks(rng, quality)
	for key: String in ["first_name", "last_name", "nickname", "age", "height",
			"weight", "plays", "manages", "perks", "team", "jersey", "position"]:
		if spec.has(key):
			actor.data[key] = spec[key]
	return actor

# One season. A curator who knows what somebody did that year says so and it
# is applied verbatim; a year nobody wrote down is simulated. Same list, same
# code path — decision 28.
static func _live_one_year(actor: Actor, fallback_position: String,
		climate: Dictionary, season: Dictionary, rng: RandomNumberGenerator) -> void:
	var position: String = String(season.get("position", fallback_position))
	var gains: Dictionary = season.get("gains", {})
	if gains.is_empty():
		ActorLife.advance_year(actor, position, climate, rng)
		return
	for id: String in gains.keys():
		var key: String = String(id).strip_edges().to_lower()
		var amount: int = int(gains[id]) * int(ActorLife.STORED_PER_STEP)
		actor.set_skill(key, clampi(actor.skill(key) + amount,
			StatDef.STORED_MIN, StatDef.STORED_MAX))
	actor.set_age(actor.age() + 1)

static func _numbers(raw: Variant) -> Dictionary:
	var out: Dictionary = {}
	if not raw is Dictionary:
		return out
	for key: String in (raw as Dictionary).keys():
		out[String(key).strip_edges().to_lower()] = clampi(
			int((raw as Dictionary)[key]), StatDef.STORED_MIN, StatDef.STORED_MAX)
	return out

# A cohort sharing one base seed. Each actor gets a salted sub-seed so adding
# or removing one does not reshuffle the others.
static func squad(
	base_seed: int,
	count: int,
	reputation: int,
	category: String = Actor.CATEGORY_MASC,
	club_level: float = 1.0,
	position: String = "",
) -> Array[Actor]:
	var out: Array[Actor] = []
	for i: int in range(count):
		var sub_seed: int = SeedRng.derive(base_seed, "actor_%d" % i)
		out.append(generate(sub_seed, reputation, category, club_level, position))
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
	if def == null or rng.randf() >= PERK_CHANCE:
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
