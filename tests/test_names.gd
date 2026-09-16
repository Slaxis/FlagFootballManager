# Tests for the apelido generator: the morphology that bends a name, and the
# table that ties a nickname to what the person is actually notable for.
extends RefCounted
class_name TestNames

func tests() -> Array:
	return [
		"test_morphology_produces_sayable_names",
		"test_short_form_refuses_a_mid_word_cut",
		"test_feminine_forms_are_their_own",
		"test_nickname_coheres_with_a_notable_stat",
		"test_every_attribute_can_be_named_in_both_directions",
		"test_stat_nicknames_point_at_real_stats",
		"test_untrained_skills_are_never_flaws",
		"test_a_notable_stat_outranks_an_average_one",
		"test_nickname_is_deterministic_for_a_seed",
		"test_everybody_gets_an_apelido",
		"test_seed_from_identity_is_stable_and_sensitive",
	]

func _def() -> NameGenDef:
	return Drive.def("name_gen") as NameGenDef

func _stats() -> StatDef:
	return Drive.def("stat") as StatDef

# The anchors. Each of these is a form a Brazilian would actually say, and each
# one is a different branch: a dropped vowel, the c->qu repair, the g->gu one,
# the linking -z-, a nasal that refuses to be cut, and a -z name that already
# carries its own link.
func test_morphology_produces_sayable_names(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("NameGenDef ausente"); return
	var expected: Dictionary = {
		"Pedro": ["Pedrinho", "Pedrão"],
		"Lucas": ["Luquinho", "Lucão"],
		"Thiago": ["Thiaguinho", "Thiagão"],
		"Gabriel": ["Gabrielzinho", "Gabrielzão"],
		"João": ["Joãozinho", ""],
		"Beatriz": ["Beatrizinho", "Beatrizão"],
		"Matheus": ["Matheusinho", "Matheusão"],
		"Vinícius": ["Viniciusinho", "Viniciusão"],
		"Silva": ["Silvinho", "Silvão"],
		"Henrique": ["Henriquinho", "Henricão"],
		"Rocha": ["Rochinho", "Rochão"],
		"Nascimento": ["Nascimentinho", "Nascimentão"],
	}
	for name: String in expected.keys():
		var pair: Array = expected[name]
		t.equal(def.diminutive(name, "m"), String(pair[0]), "diminutivo de " + name)
		t.equal(def.augmentative(name, "m"), String(pair[1]), "aumentativo de " + name)

func test_short_form_refuses_a_mid_word_cut(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("NameGenDef ausente"); return
	for good: Array in [["Leonardo", "Leo"], ["Eduardo", "Edu"], ["Camila", "Cami"],
			["Vasconcelos", "Vasco"], ["Nascimento", "Nasci"], ["Vinícius", "Vini"]]:
		t.equal(def.short_form(String(good[0])), String(good[1]), "curto de " + String(good[0]))
	# Every one of these used to come out as a syllable nobody says.
	for bad: String in ["Guilherme", "Matheus", "Ferreira", "Thiago", "Caio", "Paulo", "Silva"]:
		t.equal(def.short_form(bad), "", "'%s' não deveria encurtar" % bad)

func test_feminine_forms_are_their_own(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("NameGenDef ausente"); return
	t.equal(def.diminutive("Camila", "f"), "Camilinha", "diminutivo feminino")
	t.equal(def.augmentative("Camila", "f"), "Camilona", "aumentativo feminino")
	t.equal(def.diminutive("Juliana", "f"), "Julianinha", "diminutivo feminino")

# The point of the whole system: the apelido has to be ABOUT the person. An
# actor with 9 agility and nothing else remarkable can only be named for it.
func test_nickname_coheres_with_a_notable_stat(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("NameGenDef ausente"); return
	var traits: Array = [{"stat": "agility", "dir": "high", "distance": 4}]
	var pool: Array[String] = def.nickname_options("", "", "m", traits)
	t.check(pool.size() >= 4, "pool de agilidade alta ficou pequeno: %d" % pool.size())
	var rng: RandomNumberGenerator = SeedRng.make_rng(99)
	for i: int in range(40):
		var nick: String = def.stat_nickname(traits, "m", rng)
		t.check(pool.has(nick), "'%s' não veio da agilidade alta" % nick)

func test_every_attribute_can_be_named_in_both_directions(t: TestHelper) -> void:
	var def := _def()
	var stats := _stats()
	if def == null or stats == null:
		t.fail("Defs ausentes"); return
	for id: String in stats.base_ids():
		for direction: String in [NameGenDef.DIR_HIGH, NameGenDef.DIR_LOW]:
			var traits: Array = [{"stat": id, "dir": direction, "distance": 4}]
			var pool: Array[String] = def.nickname_options("", "", "m", traits)
			t.check(not pool.is_empty(),
				"nenhum apelido para '%s' %s" % [id, direction])

# A pool keyed on a stat that does not exist would never fire and nobody would
# notice — it would just look like the generator preferring other sources.
func test_stat_nicknames_point_at_real_stats(t: TestHelper) -> void:
	var def := _def()
	var stats := _stats()
	if def == null or stats == null:
		t.fail("Defs ausentes"); return
	t.check(def.stat_nicknames.size() > 20, "tabela de apelidos por stat ficou curta")
	for entry: Variant in def.stat_nicknames:
		var spec: Dictionary = entry as Dictionary
		var id: String = String(spec.get("stat", ""))
		t.check(stats.has_base(id) or stats.has_skill(id),
			"'%s' não é atributo nem habilidade" % id)
		t.check(not (spec.get("pool", []) as Array).is_empty(),
			"entrada '%s' sem apelidos" % id)

# An amateur has a dozen skills at zero because he never trained them, not
# because he is bad at them. Reading those as flaws got every generated player
# mocked for something that was never a failing.
func test_untrained_skills_are_never_flaws(t: TestHelper) -> void:
	var stats := _stats()
	if stats == null:
		t.fail("StatDef ausente"); return
	var traits: Array = stats.notable_traits(
		stats.blank_sheet(5), stats.blank_skills(0))
	t.equal(traits.size(), 0, "uma habilidade zerada virou defeito")
	var trained: Array = stats.notable_traits(
		stats.blank_sheet(5), {"throwing": 8})
	t.equal(trained.size(), 1, "uma habilidade treinada deveria contar")
	t.equal(String((trained[0] as Dictionary)["dir"]), "high", "direção")
	# Attributes still count downward, but only at the floor: on the new ruler a
	# city-level player sits at one or two steps in everything, so calling that
	# a flaw would have every amateur in the game nicknamed after a weakness.
	t.equal(stats.notable_traits({"strength": 1}, {}).size(), 0,
		"um passo é nível várzea, não defeito")
	var weak: Array = stats.notable_traits({"strength": 0}, {})
	t.equal(weak.size(), 1, "um atributo baixo deveria contar")
	t.equal(String((weak[0] as Dictionary)["dir"]), "low", "direção")

func test_a_notable_stat_outranks_an_average_one(t: TestHelper) -> void:
	var stats := _stats()
	if stats == null:
		t.fail("StatDef ausente"); return
	var traits: Array = stats.notable_traits(
		{"agility": 10, "strength": 7, "will": 5, "charisma": 5}, {})
	t.equal(traits.size(), 2, "só os extremos deveriam entrar")
	t.equal(String((traits[0] as Dictionary)["stat"]), "agility", "o mais extremo primeiro")

func test_nickname_is_deterministic_for_a_seed(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("NameGenDef ausente"); return
	var traits: Array = [{"stat": "strength", "dir": "high", "distance": 3}]
	var first: String = def.nickname_for("Pedro", "Silva", "m", traits, SeedRng.make_rng(4242))
	var again: String = def.nickname_for("Pedro", "Silva", "m", traits, SeedRng.make_rng(4242))
	t.equal(first, again, "mesma semente, mesmo apelido")
	t.check(first != "", "apelido vazio com semente fixa")

# Any of the four sources may decline — the morphology refuses João, the stat
# table is empty for an average adult — so the generator has to fall through
# rather than hand back nothing.
func test_everybody_gets_an_apelido(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("NameGenDef ausente"); return
	var rng: RandomNumberGenerator = SeedRng.make_rng(7)
	var empties: int = 0
	for i: int in range(200):
		var first: String = def.random_first_name("m", rng)
		var last: String = def.random_last_name(rng)
		if def.nickname_for(first, last, "m", [], rng) == "":
			empties += 1
	t.equal(empties, 0, "%d pessoas ficaram sem apelido" % empties)

# The creation screen hashes the three name fields into the career seed, which
# is what lets a player write three words down and come back to the same world.
func test_seed_from_identity_is_stable_and_sensitive(t: TestHelper) -> void:
	var one: int = SeedRng.seed_from_string("Pedro|Silva|Pedrinho")
	var same: int = SeedRng.seed_from_string("Pedro|Silva|Pedrinho")
	var other: int = SeedRng.seed_from_string("Pedro|Silva|Pedrão")
	t.equal(one, same, "o mesmo nome deveria dar a mesma semente")
	t.check(one != other, "trocar o apelido deveria trocar o mundo")
