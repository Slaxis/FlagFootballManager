# Tests for character creation priced in years of your life.
extends RefCounted
class_name TestSheetBuilder

const SEED := 424242

func tests() -> Array:
	return [
		"test_starts_as_an_average_adult",
		"test_age_climbs_as_you_spend",
		"test_age_goes_back_when_you_take_points_back",
		"test_full_budget_reaches_eighteen",
		"test_everything_can_be_given_back",
		"test_lowering_refunds_exactly_what_raising_cost",
		"test_start_is_blocked_until_the_budget_is_gone",
		"test_cannot_spend_more_than_you_have",
		"test_a_prodigy_must_sell_everything_else",
		"test_balanced_build_fits_the_budget",
		"test_step_costs_are_linear_and_stats_cost_more",
		"test_the_top_half_of_the_ladder_costs_far_more",
		"test_bakes_steps_into_stored_units",
		"test_an_extreme_body_costs_the_whole_spare_budget",
		"test_a_remainder_nothing_costs_still_finishes",
		"test_the_opening_rolls_a_twelve_year_old",
		"test_the_opening_rolls_a_whole_person",
		"test_each_origin_leans_its_own_way",
		"test_the_opening_leaves_nobody_hollow",
		"test_the_opening_can_always_afford_the_perk_it_picked",
		"test_the_opening_is_not_the_same_person_twice",
	]

func _builder() -> SheetBuilder:
	return SheetBuilder.average_adult()

# The screen opens on an average adult, already paid for. Same place you would
# reach by hand from zero — minus forty clicks.
func test_starts_as_an_average_adult(t: TestHelper) -> void:
	var def := Drive.def("stat") as StatDef
	var builder: SheetBuilder = _builder()
	for step: int in builder.stats.values():
		t.equal(step, SheetBuilder.START_STAT_STEP, "atributo deveria abrir no adulto mediano")
	for step: int in builder.skills.values():
		t.equal(step, 0, "habilidade deveria abrir em zero")
	t.equal(builder.age(), 15, "idade de abertura")
	t.equal(builder.remaining(), 54, "career points restantes")
	if def != null:
		t.equal(int(builder.stats.size()) * 45, builder.spent(), "custo pré-pago")

func test_age_climbs_as_you_spend(t: TestHelper) -> void:
	var builder: SheetBuilder = _builder()
	var id: String = String(builder.stats.keys()[0])
	var before: int = builder.age()
	for i: int in range(20):
		builder.raise_stat(id)
	t.check(builder.age() > before,
		"gastar não envelheceu (%d -> %d, gasto %d)" % [before, builder.age(), builder.spent()])

func test_age_goes_back_when_you_take_points_back(t: TestHelper) -> void:
	var builder: SheetBuilder = _builder()
	var opening: int = builder.age()
	var id: String = String(builder.stats.keys()[0])
	for i: int in range(3):
		builder.raise_stat(id)
	var older: int = builder.age()
	t.check(older > opening, "subir não envelheceu")
	for i: int in range(3):
		builder.lower_stat(id)
	t.equal(builder.age(), opening, "desfazer deveria voltar à idade de abertura")

func test_full_budget_reaches_eighteen(t: TestHelper) -> void:
	var builder: SheetBuilder = _builder()
	_spend_everything(builder)
	t.check(builder.remaining() < 1, "sobraram %d pontos" % builder.remaining())
	t.equal(builder.age(), SheetBuilder.END_AGE, "gastar tudo deveria dar 18")

# Refunds go back to the true origin, not to the sheet you were handed.
func test_everything_can_be_given_back(t: TestHelper) -> void:
	var builder: SheetBuilder = _builder()
	var id: String = String(builder.stats.keys()[0])
	for i: int in range(10):
		builder.lower_stat(id)
	t.equal(int(builder.stats[id]), SheetBuilder.MIN_STAT_STEP, "não voltou ao piso")
	t.equal(builder.remaining(), 54 + 45, "não devolveu os 45 daquele atributo")

# Without a signed cost table the refunded points would silently vanish.
func test_lowering_refunds_exactly_what_raising_cost(t: TestHelper) -> void:
	var builder: SheetBuilder = _builder()
	var id: String = String(builder.stats.keys()[0])
	var before: int = builder.remaining()
	builder.raise_stat(id)
	builder.raise_stat(id)
	builder.lower_stat(id)
	builder.lower_stat(id)
	t.equal(builder.remaining(), before, "subir e descer não voltou ao mesmo lugar")

# You leave at eighteen or not at all.
func test_start_is_blocked_until_the_budget_is_gone(t: TestHelper) -> void:
	var builder: SheetBuilder = _builder()
	t.check(not builder.is_complete(), "recém-criado não deveria estar completo")
	_spend_everything(builder)
	t.check(builder.is_complete(), "gastou tudo e ainda não está completo")
	t.equal(builder.age(), SheetBuilder.END_AGE, "completo deveria significar 18 anos")

func test_cannot_spend_more_than_you_have(t: TestHelper) -> void:
	var builder: SheetBuilder = _builder()
	_spend_everything(builder)
	t.check(builder.spent() <= SheetBuilder.total_points(),
		"gastou %d de %d" % [builder.spent(), SheetBuilder.total_points()])

# Ten steps IS reachable at eighteen — a kid who did nothing but one thing can
# be exceptional at it. But not from the sheet as handed: the 54 spare points
# buy two steps. To reach the podium you have to SELL the rest of yourself,
# which is exactly the choice the mechanic is for.
func test_a_prodigy_must_sell_everything_else(t: TestHelper) -> void:
	var builder: SheetBuilder = _builder()
	var gift: String = String(builder.stats.keys()[0])

	for i: int in range(20):
		builder.raise_stat(gift)
	t.check(int(builder.stats[gift]) < StatDef.MAX_STEP,
		"chegou ao topo sem sacrificar nada — barato demais")

	for id: String in builder.stats.keys():
		if id == gift:
			continue
		while builder.can_lower_stat(id):
			builder.lower_stat(id)
	for i: int in range(20):
		builder.raise_stat(gift)

	t.equal(int(builder.stats[gift]), StatDef.MAX_STEP, "nem vendendo tudo chegou ao topo")
	for id: String in builder.stats.keys():
		if id != gift:
			t.equal(int(builder.stats[id]), 0, "o prodígio deveria ter zerado o resto")

# The budget should land a rounded adult: everything at the average, with some
# practice. Specialising then means trading that breadth away.
func test_balanced_build_fits_the_budget(t: TestHelper) -> void:
	var builder: SheetBuilder = _builder()
	for id: String in builder.stats.keys():
		while int(builder.stats[id]) < 5 and builder.can_raise_stat(id):
			builder.raise_stat(id)
	var reached: int = 0
	for id: String in builder.stats.keys():
		if int(builder.stats[id]) >= 5:
			reached += 1
	t.equal(reached, builder.stats.size(),
		"só %d de %d atributos chegaram ao adulto mediano" % [reached, builder.stats.size()])
	t.check(builder.remaining() > 0,
		"não sobrou nada para habilidade nenhuma")

# Entering step N costs N of its own kind, converted into career points at
# 3 for an attribute and 2 for a skill. Attributes are the hard half.
func test_step_costs_are_linear_and_stats_cost_more(t: TestHelper) -> void:
	var builder: SheetBuilder = _builder()
	var stat_id: String = String(builder.stats.keys()[0])
	var skill_id: String = String(builder.skills.keys()[0])
	var stat_step: int = int(builder.stats[stat_id])
	t.equal(builder.cost_to_raise_stat(stat_id), (stat_step + 1) * SheetBuilder.STAT_POINT_IN_CAREER,
		"custo do próximo passo de atributo")
	t.equal(builder.cost_to_raise_skill(skill_id), 1 * SheetBuilder.SKILL_POINT_IN_CAREER,
		"custo do primeiro passo de habilidade")
	t.check(SheetBuilder.STAT_POINT_IN_CAREER > SheetBuilder.SKILL_POINT_IN_CAREER,
		"atributo deveria ser mais caro que habilidade")

# The property that makes the anchor mean something: the top half of the ladder
# is far dearer than the bottom. Reaching the average adult is a normal life;
# going from there to the podium is another life and a half.
func test_the_top_half_of_the_ladder_costs_far_more(t: TestHelper) -> void:
	var to_average: int = 0
	for step: int in range(1, 6):
		to_average += step * SheetBuilder.STAT_POINT_IN_CAREER
	var to_podium: int = 0
	for step: int in range(6, StatDef.MAX_STEP + 1):
		to_podium += step * SheetBuilder.STAT_POINT_IN_CAREER
	t.check(to_podium > to_average * 2,
		"do adulto mediano ao pódio custa %d contra %d até lá — degrau raso demais" %
			[to_podium, to_average])

func test_bakes_steps_into_stored_units(t: TestHelper) -> void:
	var def := Drive.def("stat") as StatDef
	if def == null:
		t.fail("StatDef ausente"); return
	var builder: SheetBuilder = _builder()
	builder.raise_stat(String(builder.stats.keys()[0]))
	var actor: Actor = builder.to_actor(SEED, {"first_name": "João", "last_name": "das Couves"})
	t.equal(actor.age(), builder.age(), "idade")
	t.equal(actor.full_name(), "João das Couves", "nome")
	for id: String in builder.stats.keys():
		t.equal(actor.stat(id), def.stored_for(int(builder.stats[id])),
			"armazenado de '%s'" % id)
		t.equal(def.step(actor.stat(id)), int(builder.stats[id]),
			"ida e volta de passos em '%s'" % id)

# Skill steps cost 2 and attribute steps cost 3, so a player can land on 1
# career point that nothing in the game costs. Demanding exactly zero
# deadlocked them: no purchase affordable, and the start button never opened.
func test_a_remainder_nothing_costs_still_finishes(t: TestHelper) -> void:
	var builder: SheetBuilder = _builder()
	# Every skill step costs an even number, so the parity has to come from an
	# attribute: entering step 7 costs 21. From 54 that leaves an odd purse
	# which even purchases can never empty.
	var id: String = String(builder.stats.keys()[0])
	builder.raise_stat(id)
	builder.raise_stat(id)
	t.check(builder.remaining() % 2 == 1, "o cenário precisava de uma sobra ímpar")

	var guard: int = 0
	while guard < 400:
		guard += 1
		var cheapest: int = builder.cheapest_purchase()
		if cheapest < 0 or cheapest > builder.remaining():
			break
		var bought: bool = false
		for skill_id: String in builder.skills.keys():
			if builder.cost_to_raise_skill(skill_id) == cheapest and builder.can_raise_skill(skill_id):
				builder.raise_skill(skill_id)
				bought = true
				break
		if not bought:
			for stat_id: String in builder.stats.keys():
				if builder.cost_to_raise_stat(stat_id) == cheapest and builder.can_raise_stat(stat_id):
					builder.raise_stat(stat_id)
					bought = true
					break
		if not bought:
			break

	t.check(builder.remaining() > 0, "o cenário não deixou sobra nenhuma")
	t.check(builder.cheapest_purchase() > builder.remaining(),
		"ainda havia algo comprável com %d pontos" % builder.remaining())
	t.check(builder.is_complete(),
		"com %d ponto(s) e nada comprável o jogador ficou preso na tela" % builder.remaining())

# The body is billed, and at the extreme of both measures the bill is exactly
# the spare budget — so a wildly shaped manager reaches eighteen with nothing
# left for skills. Shape or practice, not both.
func test_an_extreme_body_costs_the_whole_spare_budget(t: TestHelper) -> void:
	var builder: SheetBuilder = _builder()
	t.equal(builder.body_cost(), 0, "o corpo de abertura deveria ser grátis")
	var spare: int = builder.remaining()
	builder.height = 2.10
	builder.weight = 110.0
	t.equal(builder.body_cost(), spare, "o corpo extremo deveria custar toda a sobra")
	t.equal(builder.remaining(), 0, "não deveria sobrar nada")
	t.check(builder.is_complete(), "e ainda assim fecha os 18 anos")

# There is no seed here at all any more: two newborns are identical, and the
# career seed builds the world instead of the person.
# The screen used to open on five-in-everything: the same faceless adult every
# time, and eight identical bars read as empty. It now opens on a rolled
# twelve-year-old — and what makes that a starting point rather than an answer
# is everything it deliberately does NOT decide.
func test_the_opening_rolls_a_twelve_year_old(t: TestHelper) -> void:
	var def := Drive.def("stat") as StatDef
	if def == null:
		t.fail("StatDef ausente"); return
	for seed_value: int in [1, 99, SEED, 20260914]:
		var builder: SheetBuilder = SheetBuilder.rolled_opening(SeedRng.make_rng(seed_value))
		t.equal(builder.age(), SheetBuilder.OPENING_AGE,
			"semente %d abriu com %d anos" % [seed_value, builder.age()])
		t.check(builder.spent() >= SheetBuilder.opening_budget(),
			"semente %d não viveu os doze anos inteiros" % seed_value)
		t.check(not builder.is_complete(),
			"semente %d abriu pronta — não sobrou decisão nenhuma" % seed_value)

# The opening now rolls SKILLS TOO, and that is the point: filling fifteen bars
# from zero is a chore, not a choice — and it got worse once origins existed,
# because an ex-player with no skills is not an ex-player. You get a whole
# person and editing him is the game.
func test_the_opening_rolls_a_whole_person(t: TestHelper) -> void:
	var def := Drive.def("stat") as StatDef
	if def == null:
		t.fail("StatDef ausente"); return
	for seed_value: int in [3, 77, SEED]:
		var builder: SheetBuilder = SheetBuilder.rolled_opening(SeedRng.make_rng(seed_value))
		var trained: int = 0
		for id: String in def.skill_ids():
			if int(builder.skills[id]) > 0:
				trained += 1
		t.check(trained >= 3,
			"semente %d abriu com só %d habilidades" % [seed_value, trained])
		# And the six spare years survive, or there is nothing left to decide.
		t.check(builder.remaining() > SheetBuilder.CAREER_POINTS_PER_YEAR * 4,
			"semente %d deixou só %d cp" % [seed_value, builder.remaining()])
		t.check(not builder.is_complete(), "semente %d abriu pronta" % seed_value)

# Each scenario leans its own way, and the lean is paid for at the normal
# price — it is the difference between the three and not a rounding error.
func test_each_origin_leans_its_own_way(t: TestHelper) -> void:
	var origins := Drive.def("origin") as OriginDef
	if origins == null:
		t.fail("OriginDef ausente"); return
	t.equal(origins.origin_ids().size(), 3, "quantidade de origens")
	for id: String in origins.origin_ids():
		var builder: SheetBuilder = SheetBuilder.rolled_opening(SeedRng.make_rng(11), id)
		t.equal(builder.origin, id, "a origem não ficou registrada")
		for skill_id: String in origins.skill_bias(id).keys():
			t.check(int(builder.skills.get(skill_id, 0)) >= int(origins.skill_bias(id)[skill_id]),
				"origem '%s': '%s' abaixo do que ela promete" % [id, skill_id])
		for stat_id: String in origins.stat_bias(id).keys():
			t.check(int(builder.stats.get(stat_id, 0)) >= int(origins.stat_bias(id)[stat_id]),
				"origem '%s': '%s' abaixo do que ela promete" % [id, stat_id])
	# The ex-player knows how to catch; the student knows the rulebook.
	var player: SheetBuilder = SheetBuilder.rolled_opening(SeedRng.make_rng(11), "player")
	var student: SheetBuilder = SheetBuilder.rolled_opening(SeedRng.make_rng(11), "student")
	t.check(int(player.skills["catching"]) > int(student.skills["catching"]),
		"o ex-jogador deveria pegar melhor que o estudado")
	t.check(int(student.skills["rules"]) > int(player.skills["rules"]),
		"o estudado deveria saber mais regra que o ex-jogador")

# 0 on this ruler is below a toddler. A rolled child with a hollow attribute is
# not a starting point, it is a trap the player has to spend points undoing.
func test_the_opening_leaves_nobody_hollow(t: TestHelper) -> void:
	var def := Drive.def("stat") as StatDef
	if def == null:
		t.fail("StatDef ausente"); return
	var rng: RandomNumberGenerator = SeedRng.make_rng(SEED)
	var peak: int = 0
	for i: int in range(40):
		var builder: SheetBuilder = SheetBuilder.rolled_opening(rng)
		for id: String in def.base_ids():
			var value: int = int(builder.stats[id])
			t.check(value >= SheetBuilder.OPENING_FLOOR_STEP,
				"'%s' abriu em %d, abaixo do piso" % [id, value])
			peak = maxi(peak, value)
	# A twelve-year-old is not a medal contender either.
	t.check(peak <= SheetBuilder.OPENING_CEILING_STEP,
		"uma criança abriu com %d passos, acima do teto" % peak)
	t.check(peak > StatDef.DEFAULT_AVERAGE_STEP,
		"em 40 sorteios ninguém passou da média — o espalhamento morreu")

# The perk is picked BEFORE the attributes are bought, precisely so it is
# always payable. If that order ever flips, a 40-point boon on a sheet with
# nothing left goes silently unbought and the roll quietly stops giving tones.
func test_the_opening_can_always_afford_the_perk_it_picked(t: TestHelper) -> void:
	var perks := Drive.def("perk") as PerkDef
	if perks == null:
		t.fail("PerkDef ausente"); return
	var rng: RandomNumberGenerator = SeedRng.make_rng(SEED)
	var rolled: int = 0
	for i: int in range(60):
		var builder: SheetBuilder = SheetBuilder.rolled_opening(rng)
		t.check(builder.remaining() >= 0, "a abertura estourou o orçamento")
		if builder.perk == "":
			continue
		rolled += 1
		t.check(perks.has_perk(builder.perk), "perk inventado: " + builder.perk)
	t.check(rolled > 0, "nenhuma abertura pegou perk em 60 sorteios")

func test_the_opening_is_not_the_same_person_twice(t: TestHelper) -> void:
	var rng: RandomNumberGenerator = SeedRng.make_rng(SEED)
	var sheets: Dictionary = {}
	var with_a_perk: int = 0
	for i: int in range(20):
		var builder: SheetBuilder = SheetBuilder.rolled_opening(rng)
		sheets[str(builder.stats) + builder.perk] = true
		if builder.has_perk():
			with_a_perk += 1
	t.equal(sheets.size(), 20, "só %d aberturas distintas em 20" % sheets.size())
	# The perk is what gives a rolled character a tone, so some have one and
	# some do not — neither extreme is a roll.
	t.check(with_a_perk > 0, "ninguém abriu com perk em 20 sorteios")
	t.check(with_a_perk < 20, "todo mundo abriu com perk")
	# Same seed, same child — the screen still has to be reproducible.
	t.equal(str(SheetBuilder.rolled_opening(SeedRng.make_rng(7)).stats),
		str(SheetBuilder.rolled_opening(SeedRng.make_rng(7)).stats),
		"a mesma semente deveria abrir a mesma ficha")

func _spend_everything(builder: SheetBuilder) -> void:
	var guard: int = 0
	while builder.remaining() > 0 and guard < 500:
		guard += 1
		var moved: bool = false
		for id: String in builder.skills.keys():
			if builder.can_raise_skill(id):
				builder.raise_skill(id)
				moved = true
				break
		if not moved:
			for id: String in builder.stats.keys():
				if builder.can_raise_stat(id):
					builder.raise_stat(id)
					moved = true
					break
		if not moved:
			return
