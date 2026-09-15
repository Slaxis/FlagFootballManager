# Tests for the three layers that make a squad: the curated catalogue, the
# generator that fills around it, and the live roster that owns the result.
extends RefCounted
class_name TestRosters

const SEED := 20260915
const CLUB := "flag_kings"

func tests() -> Array:
	return [
		"test_the_shipped_module_validates",
		"test_a_sparse_spec_becomes_a_whole_person",
		"test_what_the_curator_pinned_wins",
		"test_a_curated_actor_is_the_same_in_every_career",
		"test_a_later_source_merges_instead_of_replacing",
		"test_curated_actors_all_make_the_squad",
		"test_the_generator_only_tops_up_what_is_missing",
		"test_a_squad_is_stable_once_built",
		"test_squad_size_follows_the_tier",
		"test_a_roster_survives_the_round_trip",
		"test_every_generated_actor_is_legal",
	]

func _actors() -> ActorDef:
	return Drive.def("actor") as ActorDef

func _stats() -> StatDef:
	return Drive.def("stat") as StatDef

func _spec(extra: Dictionary = {}) -> Dictionary:
	var base: Dictionary = {
		"id": "teste_qb", "team": CLUB, "plays": [Actor.CATEGORY_MASC],
		"first_name": "Teste", "last_name": "Da Silva",
	}
	base.merge(extra, true)
	return base

# The catalogue is written by people who are not programmers, in a text editor,
# at volume. This is the check that turns a curator's typo into a red run
# instead of an athlete who silently never appears.
func test_the_shipped_module_validates(t: TestHelper) -> void:
	var def := _actors()
	if def == null:
		t.fail("ActorDef ausente"); return
	var problems: Array[String] = def.problems()
	for line: String in problems:
		t.fail("elenco curado inválido — " + line)
	t.equal(problems.size(), 0, "problemas no elenco do módulo")

# Six lines of JSON have to come out a complete, plausible person, or nobody
# will ever curate four thousand fields.
func test_a_sparse_spec_becomes_a_whole_person(t: TestHelper) -> void:
	var stats := _stats()
	if stats == null:
		t.fail("StatDef ausente"); return
	var person: Actor = ActorGenerator.from_spec(_spec(), 60)
	t.equal(person.first_name(), "Teste", "nome fixado")
	for id: String in stats.base_ids():
		t.check(person.stat(id) > 0, "atributo '%s' ficou vazio" % id)
	t.check(person.height() > 1.0, "sem altura")
	t.check(person.weight() > 1.0, "sem peso")
	t.check(person.age() > 0, "sem idade")
	t.check(person.overall() > 0, "geral zerado")

func test_what_the_curator_pinned_wins(t: TestHelper) -> void:
	var person: Actor = ActorGenerator.from_spec(_spec({
		"stats": {"strength": 91}, "skills": {"throwing": 77},
		"age": 34, "perks": ["capitao"], "nickname": "Chefe",
	}), 60)
	t.equal(person.stat("strength"), 91, "atributo fixado")
	t.equal(person.skill("throwing"), 77, "habilidade fixada")
	t.equal(person.age(), 34, "idade fixada")
	t.equal(person.nickname(), "Chefe", "apelido fixado")
	t.check(person.has_perk("capitao"), "perk fixado")
	# And the body follows the pinned sheet, not a number that was thrown away.
	var weak: Actor = ActorGenerator.from_spec(_spec({"stats": {"strength": 5}}), 60)
	t.check(person.weight() > weak.weight(),
		"o corpo ignorou a força fixada: %d vs %d" % [person.weight(), weak.weight()])

# A real athlete is the same man in every career. Only the fillers move with
# the seed.
func test_a_curated_actor_is_the_same_in_every_career(t: TestHelper) -> void:
	var one: Actor = ActorGenerator.from_spec(_spec(), 60)
	var two: Actor = ActorGenerator.from_spec(_spec(), 60)
	t.equal(str(one.stats()), str(two.stats()), "atributos")
	t.equal(one.nickname(), two.nickname(), "apelido")
	t.equal(one.age(), two.age(), "idade")
	# A different id is a different person.
	var other: Actor = ActorGenerator.from_spec(_spec({"id": "outro_qb"}), 60)
	t.check(str(other.stats()) != str(one.stats()), "dois ids deram a mesma pessoa")

# A player's own mod says "this guy has 100 strength" and nothing else. That
# must not wipe the other twenty-two numbers.
func test_a_later_source_merges_instead_of_replacing(t: TestHelper) -> void:
	var def := ActorDef.new()
	def.add_thing({"id": "x", "team": CLUB, "plays": ["masc"],
		"first_name": "Base", "stats": {"agility": 40, "will": 30}})
	def.add_thing({"id": "x", "stats": {"strength": 100}})
	var spec: Dictionary = def.spec("x")
	t.equal(String(spec.get("first_name", "")), "Base", "o nome foi apagado pelo mod")
	t.equal(int((spec.get("stats", {}) as Dictionary).get("agility", 0)), 40,
		"um atributo não citado foi apagado")
	t.equal(int((spec.get("stats", {}) as Dictionary).get("strength", 0)), 100,
		"o override não pegou")
	t.equal(String(spec.get("team", "")), CLUB, "o clube foi apagado")

func test_curated_actors_all_make_the_squad(t: TestHelper) -> void:
	var def := ActorDef.new()
	var wanted: Array[String] = []
	for i: int in range(20):
		var id: String = "curado_%d" % i
		wanted.append(id)
		def.add_thing({"id": id, "team": CLUB, "plays": ["masc"]})
	var ids: Array[String] = def.ids_for(CLUB, Actor.CATEGORY_MASC)
	# Twenty curated people means twenty, even past the tier's target size: a
	# curator who wrote twenty meant twenty.
	t.equal(ids.size(), 20, "o catálogo perdeu gente")
	t.equal(def.ids_for("outro_clube", Actor.CATEGORY_MASC).size(), 0, "vazou de clube")
	t.equal(def.ids_for(CLUB, Actor.CATEGORY_FEM).size(), 0, "vazou de modalidade")

func test_the_generator_only_tops_up_what_is_missing(t: TestHelper) -> void:
	var rosters: Rosters = Rosters.make(SEED)
	var people: Array[Actor] = rosters.squad(CLUB, Actor.CATEGORY_MASC)
	t.check(people.size() >= 5, "elenco pequeno demais para jogar: %d" % people.size())
	for person: Actor in people:
		t.equal(person.team(), CLUB, "%s não ficou no clube" % person.full_name())
		t.check(person.display_name().strip_edges() != "", "alguém sem nome")

# Built once and owned from then on — a derived roster could not hold a
# signing, and signing people is the rest of the game.
func test_a_squad_is_stable_once_built(t: TestHelper) -> void:
	var rosters: Rosters = Rosters.make(SEED)
	var first: Array[Actor] = rosters.squad(CLUB, Actor.CATEGORY_MASC)
	var size: int = first.size()
	var newcomer := Actor.new()
	newcomer._apply_data("contratado", "actor", {"first_name": "Novo", "last_name": "Reforço"})
	rosters.add(CLUB, Actor.CATEGORY_MASC, newcomer)
	t.equal(rosters.squad(CLUB, Actor.CATEGORY_MASC).size(), size + 1, "a contratação sumiu")
	rosters.add(CLUB, Actor.CATEGORY_MASC, newcomer)
	t.equal(rosters.squad(CLUB, Actor.CATEGORY_MASC).size(), size + 1, "entrou duas vezes")
	t.check(rosters.remove(CLUB, Actor.CATEGORY_MASC, "contratado"), "não consegui dispensar")
	t.equal(rosters.squad(CLUB, Actor.CATEGORY_MASC).size(), size, "a dispensa não pegou")
	# Same seed, same league.
	t.equal(str(Rosters.make(SEED).squad(CLUB, Actor.CATEGORY_MASC).size()), str(size),
		"a mesma semente montou um elenco de outro tamanho")

func test_squad_size_follows_the_tier(t: TestHelper) -> void:
	var rosters: Rosters = Rosters.make(SEED)
	t.check(rosters.size_for_tier(1) > rosters.size_for_tier(4),
		"a várzea deveria ter elenco menor que a elite")
	var teams := Drive.def("team") as TeamDef
	if teams == null:
		t.fail("TeamDef ausente"); return
	League.ensure_filled(SEED)
	var sandlot: Array = teams.by_tier(TeamGenerator.TIER_UNAFFILIATED)
	if sandlot.is_empty():
		t.fail("sem clube de várzea"); return
	var small: int = rosters.squad(String(sandlot[0]["id"]), Actor.CATEGORY_MASC).size()
	var big: int = rosters.squad(CLUB, Actor.CATEGORY_MASC).size()
	t.check(big > small, "tier 1 (%d) não tem mais gente que tier 4 (%d)" % [big, small])

# E.1 is a persistence rewrite and this is the first real state to survive it.
func test_a_roster_survives_the_round_trip(t: TestHelper) -> void:
	var rosters: Rosters = Rosters.make(SEED)
	var before: Array[Actor] = rosters.squad(CLUB, Actor.CATEGORY_MASC)
	var restored := Rosters.new()
	restored.from_snapshot(rosters.to_snapshot())
	var after: Array[Actor] = restored.squad(CLUB, Actor.CATEGORY_MASC)
	t.equal(after.size(), before.size(), "tamanho do elenco")
	t.equal(restored.career_seed, rosters.career_seed, "semente")
	for i: int in range(before.size()):
		t.equal(after[i].display_name(), before[i].display_name(), "nome na posição %d" % i)
		t.equal(after[i].overall(), before[i].overall(), "geral na posição %d" % i)

func test_every_generated_actor_is_legal(t: TestHelper) -> void:
	var stats := _stats()
	if stats == null:
		t.fail("StatDef ausente"); return
	var rosters: Rosters = Rosters.make(SEED)
	for person: Actor in rosters.squad(CLUB, Actor.CATEGORY_MASC):
		t.check(Actor.plays_is_valid(person.plays()),
			"%s: modalidades %s" % [person.full_name(), str(person.plays())])
		for id: String in stats.base_ids():
			var value: int = person.stat(id)
			t.check(value >= StatDef.STORED_MIN and value <= StatDef.STORED_MAX,
				"%s: '%s' = %d" % [person.full_name(), id, value])
		t.check(person.perks().size() <= 1, "%s: mais de um perk" % person.full_name())
