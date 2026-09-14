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
		"test_the_dice_spend_the_whole_life",
		"test_the_dice_are_deterministic",
		"test_the_dice_make_specialists_not_clones",
		"test_the_dice_can_afford_the_perk_they_picked",
		"test_the_opening_is_somebody_with_points_left",
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
# The screen's 🎲. Whatever it rolls has to be a legal, finished build — if it
# can leave points on the table the start button stays dark and the button
# looks broken.
func test_the_dice_spend_the_whole_life(t: TestHelper) -> void:
	for seed_value: int in [1, 7, 4242, 99999]:
		var builder: SheetBuilder = _builder()
		builder.roll_random(SeedRng.make_rng(seed_value))
		t.check(builder.remaining() >= 0,
			"semente %d estourou o orçamento em %d" % [seed_value, -builder.remaining()])
		t.check(builder.is_complete(),
			"semente %d sobrou %d e nada para comprar" % [seed_value, builder.remaining()])
		# Not always exactly 18: the denominations are 2 and 3, so a roll can
		# strand one career point that nothing costs — the same remainder the
		# hand-built sheet is allowed to finish on.
		t.check(builder.age() >= SheetBuilder.END_AGE - 1,
			"semente %d parou aos %d anos" % [seed_value, builder.age()])
		t.check(builder.remaining() < builder.cheapest_purchase(),
			"semente %d deixou %d cp e o mais barato custa %d" % [
				seed_value, builder.remaining(), builder.cheapest_purchase()])

func test_the_dice_are_deterministic(t: TestHelper) -> void:
	var one: SheetBuilder = _builder()
	var two: SheetBuilder = _builder()
	one.roll_random(SeedRng.make_rng(SEED))
	two.roll_random(SeedRng.make_rng(SEED))
	t.equal(str(one.stats), str(two.stats), "atributos")
	t.equal(str(one.skills), str(two.skills), "habilidades")
	t.equal(one.perk, two.perk, "perk")
	t.equal(one.height, two.height, "altura")

# A uniform fill would put everybody at the same flat line. The appetite draw
# is what makes one roll a specialist and the next one a generalist, so this
# measures the spread rather than trusting it.
func test_the_dice_make_specialists_not_clones(t: TestHelper) -> void:
	var def := Drive.def("stat") as StatDef
	if def == null:
		t.fail("StatDef ausente"); return
	var rng: RandomNumberGenerator = SeedRng.make_rng(SEED)
	var with_a_peak: int = 0
	var sheets: Array[String] = []
	var runs: int = 40
	for i: int in range(runs):
		var builder: SheetBuilder = _builder()
		builder.roll_random(rng)
		var peak: int = 0
		for id: String in builder.stats.keys():
			peak = maxi(peak, int(builder.stats[id]))
		for id: String in builder.skills.keys():
			peak = maxi(peak, int(builder.skills[id]))
		if peak >= StatDef.NOTABLE_HIGH:
			with_a_peak += 1
		sheets.append(str(builder.stats) + str(builder.skills))
	t.check(with_a_peak >= runs / 2,
		"só %d de %d sorteios tiveram um pico — estão saindo todos medianos" % [with_a_peak, runs])
	var distinct: Dictionary = {}
	for sheet: String in sheets:
		distinct[sheet] = true
	t.equal(distinct.size(), runs, "sorteios repetidos: só %d fichas distintas" % distinct.size())

# The perk is picked BEFORE the sheet is bought, precisely so it is always
# payable. If that order ever flips this goes red.
func test_the_dice_can_afford_the_perk_they_picked(t: TestHelper) -> void:
	var perks := Drive.def("perk") as PerkDef
	if perks == null:
		t.fail("PerkDef ausente"); return
	var rng: RandomNumberGenerator = SeedRng.make_rng(SEED)
	var rolled: int = 0
	for i: int in range(60):
		var builder: SheetBuilder = _builder()
		builder.roll_random(rng)
		if builder.perk == "":
			continue
		rolled += 1
		t.check(perks.has_perk(builder.perk), "perk inventado: " + builder.perk)
		t.check(builder.remaining() >= 0, "o perk levou o orçamento a negativo")
	t.check(rolled > 0, "nenhum sorteio pegou perk em 60 tentativas")

# The screen used to open on five-in-everything: the same faceless adult every
# time, and a sheet of identical bars reads as empty. It now opens on a rolled
# person — but with the spare budget still in the pocket, because a sheet with
# nothing left to decide is not a creation screen.
func test_the_opening_is_somebody_with_points_left(t: TestHelper) -> void:
	var def := Drive.def("stat") as StatDef
	if def == null:
		t.fail("StatDef ausente"); return
	var reserve: int = SheetBuilder.opening_reserve()
	t.check(reserve > 0, "a abertura não deixou nada para gastar")
	for seed_value: int in [1, 99, SEED]:
		var builder: SheetBuilder = SheetBuilder.rolled_opening(SeedRng.make_rng(seed_value))
		t.check(builder.remaining() >= reserve,
			"semente %d abriu com %d cp, menos que a reserva de %d" % [
				seed_value, builder.remaining(), reserve])
		t.check(not builder.is_complete(),
			"semente %d abriu já pronta — não sobrou decisão nenhuma" % seed_value)
		# And it is a PERSON: not every attribute landed on the same number.
		var seen: Dictionary = {}
		for id: String in builder.stats.keys():
			seen[int(builder.stats[id])] = true
		t.check(seen.size() > 1, "semente %d abriu com tudo no mesmo valor" % seed_value)

func test_the_opening_is_not_the_same_person_twice(t: TestHelper) -> void:
	var rng: RandomNumberGenerator = SeedRng.make_rng(SEED)
	var sheets: Dictionary = {}
	for i: int in range(20):
		var builder: SheetBuilder = SheetBuilder.rolled_opening(rng)
		sheets[str(builder.stats) + str(builder.skills)] = true
	t.equal(sheets.size(), 20, "só %d aberturas distintas em 20" % sheets.size())
	# Same seed, same person — the screen still has to be reproducible.
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
