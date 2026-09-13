# Tests for the Career Record and the plays/manages model.
extends RefCounted
class_name TestCareer

const SEED := 777001

func tests() -> Array:
	return [
		"test_plays_rejects_mens_and_womens_together",
		"test_plays_allows_mixed_with_either",
		"test_set_plays_sanitizes_instead_of_accepting",
		"test_manages_has_no_restriction",
		"test_actor_has_no_gender_field",
		"test_career_round_trips_through_the_snapshot",
		"test_career_resolves_its_club",
		"test_same_seed_drafts_the_same_club",
		"test_draft_pool_is_only_unaffiliated",
		"test_the_drafted_club_survives_the_next_screen",
	]

func _actor() -> Actor:
	return ActorGenerator.generate(SEED, 40)

# The one hard rule of decision 17.
func test_plays_rejects_mens_and_womens_together(t: TestHelper) -> void:
	t.check(not Actor.plays_is_valid([Actor.CATEGORY_MASC, Actor.CATEGORY_FEM]),
		"masc + fem deveria ser inválido")

func test_plays_allows_mixed_with_either(t: TestHelper) -> void:
	t.check(Actor.plays_is_valid([Actor.CATEGORY_MASC, Actor.CATEGORY_MISTO]),
		"masc + misto é caso real")
	t.check(Actor.plays_is_valid([Actor.CATEGORY_FEM, Actor.CATEGORY_MISTO]),
		"fem + misto é caso real")
	t.check(Actor.plays_is_valid([]), "não jogar é válido")

# Provokes the guard on purpose, so one [ERROR][Actor] line in the suite output
# is expected here — it is the sanitizer reporting the impossible combination.
func test_set_plays_sanitizes_instead_of_accepting(t: TestHelper) -> void:
	var actor: Actor = _actor()
	actor.set_plays([Actor.CATEGORY_MASC, Actor.CATEGORY_FEM])
	t.check(Actor.plays_is_valid(actor.plays()),
		"set_plays deveria ter recusado a combinação impossível, veio %s" % str(actor.plays()))

# A head coach running the men's, women's and mixed sides is a real case.
func test_manages_has_no_restriction(t: TestHelper) -> void:
	var actor: Actor = _actor()
	actor.set_manages([Actor.CATEGORY_MASC, Actor.CATEGORY_FEM, Actor.CATEGORY_MISTO])
	t.equal(actor.manages().size(), 3, "manages deveria aceitar as três")
	t.check(actor.is_coach(), "quem gerencia é técnico")

# The game asks what you play, never who you are. If a `gender` key comes back,
# something reintroduced the question.
func test_actor_has_no_gender_field(t: TestHelper) -> void:
	var actor: Actor = _actor()
	t.check(not actor.data.has("gender"),
		"o Actor voltou a carregar 'gender' — decisão 17 diz modalidade, não gênero")

func test_career_round_trips_through_the_snapshot(t: TestHelper) -> void:
	var actor: Actor = _actor()
	actor.set_plays([Actor.CATEGORY_FEM])
	actor.set_manages([Actor.CATEGORY_MASC])
	var original: Career = Career.make(actor, "sepetiba_coiotes", SEED)

	var restored := Career.new()
	restored.from_snapshot(original.to_snapshot())

	t.equal(restored.team_id, original.team_id, "team_id")
	t.equal(restored.career_seed, original.career_seed, "seed")
	t.equal(restored.manager.full_name(), actor.full_name(), "nome do manager")
	t.equal(restored.manager.overall(), actor.overall(), "Geral do manager")
	t.equal(str(restored.manager.plays()), str(actor.plays()), "plays")
	t.equal(str(restored.manager.manages()), str(actor.manages()), "manages")

func test_career_resolves_its_club(t: TestHelper) -> void:
	League.ensure_filled()
	var def := Drive.def("team") as TeamDef
	if def == null:
		t.fail("TeamDef ausente"); return
	var career: Career = Career.make(_actor(), "flag_kings", SEED)
	t.equal(String(career.team().get("name", "")), "Flag Kings", "clube resolvido")
	t.check(Career.make(_actor(), "nao_existe", SEED).team().is_empty(),
		"clube inexistente deveria dar vazio, não crashar")

# Determinism all the way to the draft: the same seed is the same universe,
# which is what makes a reported bug reproducible.
func test_same_seed_drafts_the_same_club(t: TestHelper) -> void:
	t.equal(_draft(SEED), _draft(SEED), "mesma seed deveria sortear o mesmo clube")
	t.check(_draft(SEED) != "" , "sorteio devolveu vazio")

func test_draft_pool_is_only_unaffiliated(t: TestHelper) -> void:
	League.ensure_filled()
	var def := Drive.def("team") as TeamDef
	if def == null:
		t.fail("TeamDef ausente"); return
	var pool: Array = def.by_tier(TeamGenerator.TIER_UNAFFILIATED)
	t.check(pool.size() > 0, "nenhum clube de várzea para sortear")
	for team: Dictionary in pool:
		t.equal(int(team.get("tier", 0)), TeamGenerator.TIER_UNAFFILIATED,
			"'%s' não é várzea" % team.get("name", "?"))

# "Fui sorteado pro time Onças da Pista, inexistente na lista de times."
#
# The sandlot belongs to the CAREER's seed. club_select calls
# `League.ensure_filled()` without one, and while the default was a constant
# that call rebuilt somebody else's world — the club that had just drafted you
# stopped existing between one screen and the next. The default now asks the
# Blackboard, so a screen that does not care about seeds cannot get it wrong.
func test_the_drafted_club_survives_the_next_screen(t: TestHelper) -> void:
	var def := Drive.def("team") as TeamDef
	if def == null:
		t.fail("TeamDef ausente"); return
	var career_seed: int = SeedRng.seed_from_string("Pedro|Vasconcelos|Pedrinho")
	var drafted_id: String = _draft(career_seed)
	t.check(drafted_id != "", "o sorteio não devolveu clube")
	var career: Career = Career.make(_actor(), drafted_id, career_seed)
	The.board["career"] = career

	# Exactly what club_select does when it opens.
	League.ensure_filled()

	t.check(not def.get_team(drafted_id).is_empty(),
		"o clube sorteado '%s' sumiu da lista" % drafted_id)
	t.check(not career.team().is_empty(),
		"a carreira ficou apontando para um clube que não existe")
	t.check(def.by_tier(TeamGenerator.TIER_UNAFFILIATED).size() >= League.FILL_COUNT,
		"a várzea encolheu")
	The.board.erase("career")

	# And with no career on the board it still falls back to the default world,
	# which is what the club list shows before anybody starts a run.
	League.ensure_filled()
	t.equal(League.current_seed(), League.DEFAULT_SEED, "sem carreira, mundo padrão")

# Mirrors what the screen does, so determinism is asserted on the real path.
func _draft(seed_value: int) -> String:
	League.ensure_filled(seed_value)
	var def := Drive.def("team") as TeamDef
	if def == null:
		return ""
	var pool: Array = def.by_tier(TeamGenerator.TIER_UNAFFILIATED)
	if pool.is_empty():
		return ""
	var rng: RandomNumberGenerator = SeedRng.make_rng(SeedRng.derive(seed_value, "draft"))
	return String((pool[rng.randi() % pool.size()] as Dictionary).get("id", ""))
