# Tests for the invented clubs — the unaffiliated sandlot sides that fill out
# the state championship and give the career somewhere to start.
extends RefCounted
class_name TestTeamGenerator

const SEED := 20260101
const BATCH := 6
# Nova Friburgo Yetis, the weakest affiliated club. Everything invented must
# sit below it, or the sandlot step the player is supposed to feel is gone.
const WEAKEST_AFFILIATED := 36

func tests() -> Array:
	return [
		"test_deterministic_same_seed",
		"test_batch_is_all_unaffiliated",
		"test_reputation_sits_below_the_weakest_affiliated",
		"test_ids_are_unique_and_do_not_collide_with_real_clubs",
		"test_generated_colors_pass_without_repair",
		"test_batch_is_stable_per_index",
		"test_city_matches_the_neighbourhood_in_the_name",
		"test_vocabulary_comes_from_the_module",
		"test_league_fill_is_idempotent",
	]

func _names() -> NameGenDef:
	return Drive.def("name_gen") as NameGenDef

func test_deterministic_same_seed(t: TestHelper) -> void:
	t.equal(str(TeamGenerator.invent(SEED)), str(TeamGenerator.invent(SEED)),
		"mesma seed deveria dar o mesmo clube")

func test_batch_is_all_unaffiliated(t: TestHelper) -> void:
	var batch: Array[Dictionary] = TeamGenerator.batch(SEED, BATCH)
	t.equal(batch.size(), BATCH, "tamanho do lote")
	for team: Dictionary in batch:
		t.equal(int(team.get("tier", 0)), TeamGenerator.TIER_UNAFFILIATED,
			"'%s' deveria ser tier 4" % team.get("name", "?"))

func test_reputation_sits_below_the_weakest_affiliated(t: TestHelper) -> void:
	for team: Dictionary in TeamGenerator.batch(SEED, BATCH):
		var reputation: int = int(team.get("reputation", 999))
		t.check(reputation < WEAKEST_AFFILIATED,
			"'%s' com reputação %d não fica abaixo do pior federado (%d)" %
				[team.get("name", "?"), reputation, WEAKEST_AFFILIATED])

func test_ids_are_unique_and_do_not_collide_with_real_clubs(t: TestHelper) -> void:
	var def := Drive.def("team") as TeamDef
	if def == null:
		t.fail("TeamDef ausente"); return
	var seen: Dictionary = {}
	for team: Dictionary in TeamGenerator.batch(SEED, BATCH):
		var id: String = String(team.get("id", ""))
		t.check(id != "", "clube sem id")
		t.check(not seen.has(id), "id repetido no lote: " + id)
		seen[id] = true
		t.check(def.get_team(id).is_empty() or int(def.get_team(id).get("tier", 4)) == 4,
			"id '%s' colidiu com um clube autorado" % id)

# The readability repair exists for real clubs whose colours we do not choose.
# Anything we invent has no excuse for needing it.
func test_generated_colors_pass_without_repair(t: TestHelper) -> void:
	for team: Dictionary in TeamGenerator.batch(SEED, BATCH):
		var colors: Array = team.get("colors", [])
		t.equal(colors.size(), 2, "'%s' sem par de cores" % team.get("name", "?"))
		if colors.size() < 2:
			continue
		var ratio: float = TeamColors.contrast(Color(String(colors[0])), Color(String(colors[1])))
		t.check(ratio >= TeamColors.MIN_CONTRAST,
			"'%s' precisaria de reparo: contraste %.2f" % [team.get("name", "?"), ratio])

func test_batch_is_stable_per_index(t: TestHelper) -> void:
	var small: Array[Dictionary] = TeamGenerator.batch(SEED, 3)
	var large: Array[Dictionary] = TeamGenerator.batch(SEED, 8)
	for i: int in range(small.size()):
		t.equal(str(large[i]), str(small[i]), "clube %d mudou ao crescer o lote" % i)

# "Méier Sabiás" must actually be from Méier. A pattern free to roll its own
# neighbourhood happily places it in Deodoro.
func test_city_matches_the_neighbourhood_in_the_name(t: TestHelper) -> void:
	var names := _names()
	if names == null:
		t.fail("NameGenDef ausente"); return
	for team: Dictionary in TeamGenerator.batch(SEED, 24):
		var club_name: String = String(team.get("name", ""))
		# The BAIRRO, not the município. They became two fields the day the
		# Fundador was allowed to choose both.
		var bairro: String = String(team.get("neighborhood", ""))
		for neighbourhood: String in names.neighborhoods:
			if club_name.begins_with(neighbourhood):
				t.equal(bairro, neighbourhood,
					"'%s' diz ser de %s mas o bairro é %s" % [club_name, neighbourhood, bairro])
				break

func test_vocabulary_comes_from_the_module(t: TestHelper) -> void:
	var names := _names()
	if names == null:
		t.fail("NameGenDef ausente"); return
	t.check(names.neighborhoods.has("Jacarepaguá"),
		"o pool carioca do módulo não foi absorvido por add_thing()")
	for team: Dictionary in TeamGenerator.batch(SEED, BATCH):
		t.check(names.neighborhoods.has(String(team.get("neighborhood", ""))),
			"'%s' saiu de um bairro fora do pool do módulo: %s" %
				[team.get("name", "?"), team.get("neighborhood", "?")])
		t.equal(String(team.get("city", "")), TeamGenerator.DEFAULT_CITY,
			"'%s' deveria estar no município padrão" % team.get("name", "?"))

func test_league_fill_is_idempotent(t: TestHelper) -> void:
	var def := Drive.def("team") as TeamDef
	if def == null:
		t.fail("TeamDef ausente"); return
	League.ensure_filled()
	var after_first: int = def.all().size()
	League.ensure_filled()
	t.equal(def.all().size(), after_first, "chamar duas vezes duplicou clubes")
	t.equal(def.by_tier(TeamGenerator.TIER_UNAFFILIATED).size(), League.FILL_COUNT,
		"quantidade de não federados")
	t.equal(after_first, 16, "campeonato completo")
