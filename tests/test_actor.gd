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
		"test_quality_target_moves_overall",
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
			t.check(value >= ActorGenerator.STAT_MIN and value <= ActorGenerator.STAT_MAX,
				"stat '%s' fora de 1..99: %d" % [id, value])

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

func test_quality_target_moves_overall(t: TestHelper) -> void:
	var weak: int = _mean_overall(ActorGenerator.squad(SEED, COHORT, 25))
	var strong: int = _mean_overall(ActorGenerator.squad(SEED, COHORT, 70))
	t.check(strong > weak + 20,
		"elenco de qualidade 70 deveria ser bem melhor que o de 25 (veio %d vs %d)" % [strong, weak])

# The whole point of the two-layer model: an actor is not "good" or "bad", he
# is good at some things. If this spread collapses, every actor plays the same
# and the coletivo has nothing to reveal — so it is asserted, not assumed.
func test_actors_are_specialists(t: TestHelper) -> void:
	var total: int = 0
	var squad: Array[Actor] = ActorGenerator.squad(SEED, COHORT, 50)
	for actor: Actor in squad:
		var values: Array = actor.derived_all().values()
		if values.is_empty():
			t.fail("actor sem derivadas"); return
		total += int(values.max()) - int(values.min())
	var average: int = int(float(total) / float(squad.size()))
	t.check(average >= 10,
		"espalhamento médio entre derivadas ficou em %d — actors saíram genéricos demais" % average)

func test_defaults_put_actor_in_praca(t: TestHelper) -> void:
	var actor := ActorGenerator.generate(SEED, 50)
	t.check(actor.in_praca(), "actor recém-criado deveria estar na Praça")
	t.check(actor.is_athlete(), "actor gerado joga na modalidade que pediram")
	t.check(not actor.is_coach(), "actor gerado não nasce técnico")
	t.equal(actor.team(), Actor.NO_TEAM, "time")
	t.equal(actor.jersey(), Actor.NO_JERSEY, "camisa")
	t.equal(actor.perks().size(), 0, "perks")

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
func test_weight_follows_strength(t: TestHelper) -> void:
	var light: float = _mean_weight(ActorGenerator.squad(SEED, COHORT, 20))
	var heavy: float = _mean_weight(ActorGenerator.squad(SEED, COHORT, 85))
	t.check(heavy > light + 5.0,
		"elenco forte deveria ser mais pesado (veio %.1f vs %.1f kg)" % [heavy, light])

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
