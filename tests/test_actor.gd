# Tests for the Actor entity and its generator.
extends RefCounted
class_name TestActor

const SEED := 20260906
const COHORT := 40

func tests() -> Array:
	return [
		"test_deterministic_same_seed",
		"test_different_seeds_differ",
		"test_stats_within_range",
		"test_age_within_range",
		"test_name_is_filled_and_keeps_its_case",
		"test_category_changes_the_name_pool",
		"test_club_level_moves_the_ceiling",
		"test_reputation_moves_the_years",
		"test_actors_are_specialists",
		"test_defaults_put_actor_in_praca",
		"test_squad_is_stable_per_index",
		"test_body_measures_are_plausible",
		"test_weight_follows_strength",
		"test_measures_format_with_locale_separator",
	]

func _sheet(a: Actor) -> String:
	return "%s|%d|%s" % [a.full_name(), a.age(), str(a.stats())]

func test_deterministic_same_seed(t: TestHelper) -> void:
	var a := ActorGenerator.generate(SEED, 50)
	var b := ActorGenerator.generate(SEED, 50)
	t.equal(_sheet(b), _sheet(a), "mesma seed deveria dar o mesmo actor")

func test_different_seeds_differ(t: TestHelper) -> void:
	var a := ActorGenerator.generate(SEED, 50)
	var b := ActorGenerator.generate(SEED + 1, 50)
	t.check(_sheet(a) != _sheet(b), "seeds diferentes deveriam dar actors diferentes")

func test_stats_within_range(t: TestHelper) -> void:
	var def := Drive.def("stat") as StatDef
	if def == null:
		t.fail("StatDef ausente"); return
	for actor: Actor in ActorGenerator.squad(SEED, COHORT, 50):
		for id: String in def.base_ids():
			var value: int = actor.stat(id)
			# The bound is the RULER's, not the generator's: training buys stored
			# points one at a time and a ten-year veteran legitimately tops out
			# at 100, which the old flat roll could never reach.
			t.check(value >= StatDef.STORED_MIN and value <= StatDef.STORED_MAX,
				"stat '%s' fora de %d..%d: %d" % [
					id, StatDef.STORED_MIN, StatDef.STORED_MAX, value])

func test_age_within_range(t: TestHelper) -> void:
	for actor: Actor in ActorGenerator.squad(SEED, COHORT, 50):
		t.check(actor.age() >= ActorGenerator.AGE_MIN and actor.age() <= ActorGenerator.AGE_MAX,
			"idade fora da faixa: %d" % actor.age())

# Guards the ThingData trap: `attr()` lowercases strings, `text()` does not.
# Reading a name through the wrong accessor turns "Lucas" into "lucas".
func test_name_is_filled_and_keeps_its_case(t: TestHelper) -> void:
	var actor := ActorGenerator.generate(SEED, 50)
	t.check(actor.first_name() != "", "primeiro nome vazio")
	t.check(actor.last_name() != "", "sobrenome vazio")
	t.check(actor.first_name() != actor.first_name().to_lower(),
		"nome veio minúsculo — leitura passou por attr() em vez de text(): '%s'" % actor.first_name())
	t.check(actor.display_name() != "", "display_name vazio")

# The generator takes a CATEGORY, not a gender (decision 17). The category picks
# which name pool a generated athlete is drawn from.
func test_category_changes_the_name_pool(t: TestHelper) -> void:
	var masc := ActorGenerator.generate(SEED, 50, Actor.CATEGORY_MASC)
	var fem := ActorGenerator.generate(SEED, 50, Actor.CATEGORY_FEM)
	t.check(masc.first_name() != fem.first_name(),
		"mesma seed em modalidades diferentes deveria puxar de pools diferentes")
	t.equal(str(fem.plays()), str([Actor.CATEGORY_FEM]), "modalidade gravada em plays")

# Reputation and CLUB LEVEL are two different axes now, and conflating them is
# what this test used to do.
#
#   reputation   how long these people have been playing and how good the
#                weeks were. Moves accumulation.
#   club level   where the club sits on the WORLD ladder (country + division).
#                Moves the CEILING, via potential.
#
# With a hard ceiling, reputation alone cannot lift a squad past its band — a
# sandlot club with great training still fields city-level players, which is
# the entire point of decision 33. So level is what has to move the squad, and
# reputation is what has to move the age.
func test_club_level_moves_the_ceiling(t: TestHelper) -> void:
	var city: int = _mean_overall(ActorGenerator.squad(SEED, COHORT, 60, Actor.CATEGORY_MASC, 1.0))
	var world: int = _mean_overall(ActorGenerator.squad(SEED, COHORT, 60, Actor.CATEGORY_MASC, 4.0))
	# +15 and not more, and the reason is `overall()` itself: it averages all
	# eight attributes, and a specialist only ever trains about three of them.
	# A world-level ceiling of 85 shows up as an overall in the sixties because
	# five untrained attributes sit at whatever growing up left them. The gap is
	# real; the measure dilutes it.
	# Narrower again after maturation stopped delivering people almost to their
	# ceiling: more of an attribute is now EARNED, and a city-level club earns
	# less of it — but `overall()` still averages five attributes nobody trains,
	# which is what keeps diluting a gap that is real.
	t.check(world > city + 12,
		"clube de nível mundial deveria bater o de bairro com folga (%d vs %d)" % [world, city])
	var national: int = _mean_overall(
		ActorGenerator.squad(SEED, COHORT, 60, Actor.CATEGORY_MASC, 3.0))
	t.check(national > city and world > national,
		"a escada deveria ser monotônica (%d < %d < %d)" % [city, national, world])

func test_reputation_moves_the_years(t: TestHelper) -> void:
	var young: Array[Actor] = ActorGenerator.squad(SEED, COHORT, 20)
	var seasoned: Array[Actor] = ActorGenerator.squad(SEED, COHORT, 85)
	var young_age: float = 0.0
	var seasoned_age: float = 0.0
	for i: int in range(COHORT):
		young_age += float(young[i].age())
		seasoned_age += float(seasoned[i].age())
	t.check(seasoned_age > young_age + float(COHORT) * 2.0,
		"clube estabelecido deveria ter gente mais velha (%d vs %d anos de média)" % [
			int(seasoned_age / COHORT), int(young_age / COHORT)])

# The whole point of the two-layer model: an actor is not "good" or "bad", he
# is good at some things. If this spread collapses, every actor plays the same
# and the coletivo has nothing to reveal — so it is asserted, not assumed.
func test_actors_are_specialists(t: TestHelper) -> void:
	var total: int = 0
	var squad: Array[Actor] = ActorGenerator.squad(SEED, COHORT, 50)
	for actor: Actor in squad:
		var values: Array = actor.skills().values()
		if values.is_empty():
			t.fail("actor sem habilidades"); return
		total += int(values.max()) - int(values.min())
	var average: int = int(float(total) / float(squad.size()))
	t.check(average >= 10,
		"espalhamento médio entre habilidades ficou em %d — actors saíram genéricos demais" % average)

func test_defaults_put_actor_in_praca(t: TestHelper) -> void:
	var actor := ActorGenerator.generate(SEED, 50)
	t.check(actor.in_praca(), "actor recém-criado deveria estar na Praça")
	t.check(actor.is_athlete(), "actor gerado joga na modalidade que pediram")
	t.check(not actor.is_coach(), "actor gerado não nasce técnico")
	t.equal(actor.team(), Actor.NO_TEAM, "time")
	t.equal(actor.jersey(), Actor.NO_JERSEY, "camisa")
	# Not zero: a perk is rolled at a quarter chance, so asserting none was
	# always a bet on this particular seed. What matters is the cap.
	t.check(actor.perks().size() <= 1, "no máximo um perk")

# Salted sub-seeds: growing the cohort must not reshuffle the actors already
# in it, or every roster would churn whenever one player is added.
func test_squad_is_stable_per_index(t: TestHelper) -> void:
	var small: Array[Actor] = ActorGenerator.squad(SEED, 5, 50)
	var large: Array[Actor] = ActorGenerator.squad(SEED, 12, 50)
	for i: int in range(small.size()):
		t.equal(_sheet(large[i]), _sheet(small[i]), "actor %d mudou ao crescer o elenco" % i)

# Height and weight are MEASURES, not attributes: real units, own ranges.
func test_body_measures_are_plausible(t: TestHelper) -> void:
	var def := Drive.def("stat") as StatDef
	if def == null:
		t.fail("StatDef ausente"); return
	for actor: Actor in ActorGenerator.squad(SEED, COHORT, 50):
		for id: String in def.measure_ids():
			var spec: Dictionary = def.measure(id)
			var value: float = actor.measure(id)
			t.check(value >= float(spec.get("min", 0.0)) and value <= float(spec.get("max", 999.0)),
				"%s fora da faixa: %.2f" % [id, value])
		t.check(not def.has_base("height"), "altura não deveria ser atributo")
		t.check(not def.has_base("weight"), "peso não deveria ser atributo")

# The body must agree with the sheet: the strong cohort is visibly the heavy
# one, so nobody has to reconcile a wiry giant who bench-presses a car.
# BMI, not weight. Weight is bmi times height squared, and height varies enough
# on its own that sorting a squad by the scale sorts it mostly by how tall
# people are — the heavy half came out WEAKER than the light half, which looked
# like a bug in the body roll and was really a bug in the question. What the
# generator actually promises is that build follows strength at a given height.
func test_weight_follows_strength(t: TestHelper) -> void:
	var squad: Array[Actor] = ActorGenerator.squad(SEED, 24, 60)
	var by_build: Array[Actor] = squad.duplicate()
	by_build.sort_custom(func(a: Actor, b: Actor) -> bool:
		return _bmi(a) > _bmi(b))
	var half: int = by_build.size() / 2
	var thick: float = 0.0
	var lean: float = 0.0
	for i: int in range(half):
		thick += float(by_build[i].stat("strength"))
		lean += float(by_build[by_build.size() - 1 - i].stat("strength"))
	t.check(thick > lean,
		"a metade mais encorpada deveria ser a mais forte (%d vs %d de força)" % [
			int(thick / half), int(lean / half)])

func _bmi(actor: Actor) -> float:
	var height: float = actor.height()
	return actor.weight() / (height * height) if height > 0.0 else 0.0

func test_measures_format_with_locale_separator(t: TestHelper) -> void:
	var def := Drive.def("stat") as StatDef
	if def == null:
		t.fail("StatDef ausente"); return
	var previous: String = I18n.get_lang()
	I18n.set_lang("pt")
	t.equal(def.format_measure("height", 1.78), "1,78 m", "altura em pt")
	I18n.set_lang("en")
	t.equal(def.format_measure("height", 1.78), "1.78 m", "altura em en")
	t.equal(def.format_measure("weight", 74.0), "74 kg", "peso")
	I18n.set_lang(previous)

func _mean_weight(squad: Array[Actor]) -> float:
	var total: float = 0.0
	for actor: Actor in squad:
		total += actor.weight()
	return total / float(squad.size())

func _mean_overall(squad: Array[Actor]) -> int:
	var total: int = 0
	for actor: Actor in squad:
		total += actor.overall()
	return int(float(total) / float(squad.size()))
