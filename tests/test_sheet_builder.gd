# Tests for character creation priced in years of your life.
extends RefCounted
class_name TestSheetBuilder

const SEED := 424242

func tests() -> Array:
	return [
		"test_starts_as_an_average_adult",
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
		"test_an_extreme_body_is_a_small_price",
		"test_a_remainder_nothing_costs_still_finishes",
		"test_the_opening_rolls_a_lived_person",
		"test_the_manager_is_capped_like_a_squad_player",
		"test_the_opening_rolls_a_whole_person",
		"test_each_origin_leans_its_own_way",
		"test_the_scenario_is_a_trajectory_not_a_chair",
		"test_you_arrive_sitting_in_your_chair",
		"test_the_rolled_manager_is_an_adult_worth_editing",
		"test_only_the_ex_player_has_a_career",
		"test_the_roll_only_takes_talents_it_can_pay_for",
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
	# The hand-built sheet is a finished adult by definition: it is the whole
	# allowance already laid out.
	t.equal(builder.age(), SheetBuilder.END_AGE, "idade de abertura")
	t.equal(builder.remaining(), 54, "career points restantes")
	if def != null:
		t.equal(int(builder.stats.size()) * 45, builder.spent(), "custo pré-pago")

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

# The body is a SMALL price now, and it has to be. It used to be worth three
# steps in each direction and cost the entire spare budget — which was fine
# when a good player sat at five steps and absurd once a city-level player
# lives between one and three. A body that outweighs everything a person ever
# trained is not a body, it is a cheat code.
func test_an_extreme_body_is_a_small_price(t: TestHelper) -> void:
	var def := Drive.def("stat") as StatDef
	var builder: SheetBuilder = _builder()
	if def == null:
		t.fail("StatDef ausente"); return
	builder.height = 2.10
	builder.weight = 110.0
	t.check(builder.body_cost() > 0, "o corpo extremo saiu de graça")
	t.check(builder.body_cost() <= SheetBuilder.CAREER_POINTS_PER_YEAR,
		"o corpo custou %d cp, mais de um ano de vida" % builder.body_cost())
	# And it still shifts something, or it would be decoration.
	var effect: Dictionary = def.body_effect({"height": 2.10, "weight": 110})
	var moved: int = 0
	for value: int in effect.values():
		if value != 0:
			moved += 1
	t.check(moved >= 2, "o corpo extremo não mexeu em nada")

# There is no seed here at all any more: two newborns are identical, and the
# career seed builds the world instead of the person.
# The roll hands you a FINISHED ADULT, and that is the fix for the child
# genius. It used to stop at twelve and leave a hundred and thirty points in
# your pocket, so the header said "12 anos" while you pumped leadership to
# eight. An eighteen-year-old with everything spent has no such state to be in.
func test_the_opening_rolls_a_lived_person(t: TestHelper) -> void:
	var origins := Drive.def("origin") as OriginDef
	if origins == null:
		t.fail("OriginDef ausente"); return
	for id: String in origins.origin_ids():
		for seed_value: int in [1, SEED, 20260916]:
			var builder: SheetBuilder = SheetBuilder.rolled_opening(
				SeedRng.make_rng(seed_value), id)
			# The age is the LIFE's, not a function of the budget. Deriving it
			# from spending is what let the header say "12 anos" beside eight
			# steps of leadership.
			# ⚠️ SIXTEEN NOW, AND THE REASON IT MOVED IS THE POINT. The floor
			# was eighteen because a child's debut produced a sheet worth three
			# career points and a screen with nothing to edit — a BUDGET
			# problem wearing an age problem's clothes. The scenarios carry
			# their own allocation since, so the two came apart and the age is
			# free to be what the scene looks like: a founder who put a club
			# together at seventeen is the most ordinary story in amateur flag.
			# The budget itself is asserted separately, where it belongs.
			t.check(builder.age() >= MANAGER_ADULT_AGE and builder.age() <= 34,
				"origem %s, semente %d: %d anos" % [id, seed_value, builder.age()])
			# And the roll leaves nothing over: what you may move is HIS points.
			t.equal(builder.remaining(), 0,
				"origem %s abriu com %d cp livres" % [id, builder.remaining()])
			t.check(builder.is_complete(), "origem %s abriu incompleta" % id)

# THE SAME RULER AS EVERYBODY ELSE. The manager was the only person on screen
# without a ceiling, which is why he came out heroic — a squad player is capped
# at city level and the manager could build ten steps of anything by hand.
func test_the_manager_is_capped_like_a_squad_player(t: TestHelper) -> void:
	var def := Drive.def("stat") as StatDef
	if def == null:
		t.fail("StatDef ausente"); return
	for seed_value: int in [1, 99, SEED, 20260916]:
		var builder: SheetBuilder = SheetBuilder.rolled_opening(SeedRng.make_rng(seed_value))
		var cap: int = builder.potential_step()
		t.check(builder.potential >= SheetBuilder.MIN_MANAGER_POTENTIAL,
			"potencial %d abaixo do piso" % builder.potential)
		for id: String in def.base_ids():
			t.check(int(builder.stats[id]) <= cap, "'%s' passou do teto" % id)
		for id: String in def.skill_ids():
			t.check(int(builder.skills[id]) <= cap, "'%s' passou do teto" % id)
		# And the ceiling binds the PLAYER too, or the superhero is one click
		# away.
		for id: String in def.base_ids():
			if int(builder.stats[id]) >= cap:
				t.check(not builder.can_raise_stat(id),
					"dava para subir '%s' acima do teto na mão" % id)

func test_the_opening_rolls_a_whole_person(t: TestHelper) -> void:
	var def := Drive.def("stat") as StatDef
	if def == null:
		t.fail("StatDef ausente"); return
	for seed_value: int in [3, 77, SEED]:
		var builder: SheetBuilder = SheetBuilder.rolled_opening(
			SeedRng.make_rng(seed_value), "player")
		var trained: int = 0
		for id: String in def.skill_ids():
			if int(builder.skills[id]) > 0:
				trained += 1
		t.check(trained >= 3,
			"semente %d abriu com só %d habilidades" % [seed_value, trained])

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
			t.check(int(builder.skills.get(skill_id, 0)) >= OriginDef.promises(origins.skill_bias(id)[skill_id]),
				"origem '%s': '%s' abaixo do que ela promete" % [id, skill_id])
		for stat_id: String in origins.stat_bias(id).keys():
			t.check(int(builder.stats.get(stat_id, 0)) >= OriginDef.promises(origins.stat_bias(id)[stat_id]),
				"origem '%s': '%s' abaixo do que ela promete" % [id, stat_id])
	# The ex-player knows how to catch; the student knows the rulebook.
	#
	# MEASURED OVER TWENTY SEEDS, not one. A single roll used to be enough back
	# when the origin was a fixed chair and the sheet was a constant — but the
	# scenario is a TRAJECTORY now, so an ex-player who happened to live three
	# years at rusher legitimately catches no better than anybody, and a
	# one-seed comparison was testing the dice.
	var catch_gap: float = _origin_mean("player", "catching") - _origin_mean("student", "catching")
	var rules_gap: float = _origin_mean("student", "rules") - _origin_mean("player", "rules")
	t.check(catch_gap > 0.0, "o ex-jogador deveria pegar melhor que o estudado (%.2f)" % catch_gap)
	t.check(rules_gap > 0.0, "o estudado deveria saber mais regra que o ex-jogador (%.2f)" % rules_gap)

func _origin_mean(origin: String, skill_id: String) -> float:
	var total: float = 0.0
	for seed_value: int in range(11, 31):
		var build: SheetBuilder = SheetBuilder.rolled_opening(
			SeedRng.make_rng(seed_value), origin)
		total += float(int(build.skills.get(skill_id, 0)))
	return total / 20.0

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

# Talents ride a separate budget now, so the roll can only hand you what the
# scenario's balance covers. A founder with one point cannot come out wearing
# Craque.
func test_the_roll_only_takes_talents_it_can_pay_for(t: TestHelper) -> void:
	var perks := Drive.def("perk") as PerkDef
	var origins := Drive.def("origin") as OriginDef
	if perks == null or origins == null:
		t.fail("Defs ausentes"); return
	var rng: RandomNumberGenerator = SeedRng.make_rng(SEED)
	var rolled: int = 0
	for i: int in range(40):
		for id: String in origins.origin_ids():
			var builder: SheetBuilder = SheetBuilder.rolled_opening(rng, id)
			t.check(builder.perk_points_left() >= 0,
				"origem %s abriu com saldo de talento negativo" % id)
			for perk_id: String in builder.perks:
				t.check(perks.has_perk(perk_id), "talento inventado: " + perk_id)
			rolled += builder.perks.size()
	t.check(rolled > 0, "nenhuma abertura pegou talento em 120 sorteios")

func test_the_opening_is_not_the_same_person_twice(t: TestHelper) -> void:
	var rng: RandomNumberGenerator = SeedRng.make_rng(SEED)
	var sheets: Dictionary = {}
	var with_a_perk: int = 0
	for i: int in range(20):
		# WITH an origin. Rolled without one, everybody is a thirteen-year-old
		# with zero seasons behind him and of course they come out alike — the
		# scenario is most of what makes two managers different.
		var builder: SheetBuilder = SheetBuilder.rolled_opening(rng, "player")
		sheets[str(builder.stats) + str(builder.skills) + str(builder.perks)] = true
		if not builder.perks.is_empty():
			with_a_perk += 1
	# Not twenty of twenty: a city-level sheet lives in three steps across
	# twenty-three tracks, so two sandlot managers genuinely do look alike.
	t.check(sheets.size() >= 14, "só %d aberturas distintas em 20" % sheets.size())
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

# THE SYMPTOM THAT STARTED ALL OF THIS. The origin used to name the exact
# position the career was spent in — the ex-player was a `receiver`, full stop —
# so every ex-player came out a receiver, the founder came out with nothing but
# management skills, and the student was the same two skills every roll.
#
# It names a TRACK now: which side of the whitewash the years happened on. The
# body decides the rest, so rolling twenty ex-players gives you twenty people.
func test_the_scenario_is_a_trajectory_not_a_chair(t: TestHelper) -> void:
	var origins := Drive.def("origin") as OriginDef
	var positions := Drive.def("position") as PositionDef
	if origins == null or positions == null:
		t.fail("Defs ausentes"); return
	var seen: Dictionary = {}
	for seed_value: int in range(50, 80):
		var build: SheetBuilder = SheetBuilder.rolled_opening(
			SeedRng.make_rng(seed_value), "player")
		seen[build.rolled_position] = true
		t.check(positions.playing_ids().has(build.rolled_position),
			"o ex-jogador passou a carreira em '%s', que não é posição de quadra"
				% build.rolled_position)
	t.check(seen.size() >= 3,
		"trinta ex-jogadores e só %d posições distintas — ainda é um cargo fixo" % seen.size())

	# The student went the other way, and never onto the field.
	var staff: Array[String] = positions.ids_on_side(PositionDef.SIDE_STAFF)
	for seed_value: int in range(50, 60):
		var build: SheetBuilder = SheetBuilder.rolled_opening(
			SeedRng.make_rng(seed_value), "student")
		t.check(staff.has(build.rolled_position),
			"o estudado foi parar em '%s'" % build.rolled_position)

# You do not walk into the club and stand in the corridor. The chair is the one
# thing about the manager that is ASSIGNED rather than lived — it is the club's
# decision — and if you played, your own position comes with you, because the
# ex-jogador's own pitch is that early on he has to carry the side himself.
func test_you_arrive_sitting_in_your_chair(t: TestHelper) -> void:
	var origins := Drive.def("origin") as OriginDef
	if origins == null:
		t.fail("OriginDef ausente"); return
	for id: String in origins.origin_ids():
		var build: SheetBuilder = SheetBuilder.rolled_opening(SeedRng.make_rng(7), id)
		var person: Actor = build.to_actor(7, {"first_name": "Teste", "last_name": "Um"})
		t.check(person.plays_position(origins.chair(id)),
			"origem '%s': ninguém sentou na cadeira '%s'" % [id, origins.chair(id)])
		t.equal(person.position(), build.rolled_position,
			"origem '%s': a carreira não chegou no actor" % id)
		if origins.career_track(id) == ActorGenerator.TRACK_PLAYER:
			t.check(person.plays_position(build.rolled_position),
				"origem '%s': quem jogou deveria poder ser escalado" % id)

# The screen's whole proposition is "here is a person, now move his points
# around". A roll that produces a fifteen-year-old with one step to his name
# has a budget of three career points and nothing to trade — the form is drawn,
# every button is dead, and nothing about that reads as a bug from the outside.
func test_the_rolled_manager_is_an_adult_worth_editing(t: TestHelper) -> void:
	var origins := Drive.def("origin") as OriginDef
	var def := Drive.def("stat") as StatDef
	if origins == null or def == null:
		t.fail("Defs ausentes"); return
	for id: String in origins.origin_ids():
		var youngest: int = 99
		var thinnest: int = 1 << 30
		for seed_value: int in range(200, 220):
			var build: SheetBuilder = SheetBuilder.rolled_opening(
				SeedRng.make_rng(seed_value), id)
			youngest = mini(youngest, build.age())
			thinnest = mini(thinnest, build.budget)
			t.equal(build.remaining(), 0, "origem '%s': a ficha não abriu quitada" % id)
		t.check(youngest >= MANAGER_ADULT_AGE,
			"origem '%s': saiu um manager de %d anos" % [id, youngest])
		t.check(thinnest >= MANAGER_MIN_BUDGET,
			"origem '%s': a ficha mais magra tem %d cp para mexer" % [id, thinnest])

# WHICH OF THE THREE ACTUALLY PLAYED, and only one of them did.
#
# There used to be a second, shared span of years on top of the origin's own —
# three to six that everybody got for having been around — and it was
# load-bearing for the wrong reason: without it the sheet came out at nothing,
# three career points and an uneditable screen. But it also made all three the
# same person underneath, which is false for two of them. The founder is a
# rookie; that is the premise, there was no club to have a career at. The
# student never played at all.
#
# So the sheet is carried by the origin's own allocation now, and this test
# guards both halves at once: the years are the scenario's, and the budget did
# not collapse back to three when they left.
func test_only_the_ex_player_has_a_career(t: TestHelper) -> void:
	var origins := Drive.def("origin") as OriginDef
	if origins == null:
		t.fail("OriginDef ausente"); return
	var oldest: Dictionary = {}
	for id: String in origins.origin_ids():
		var top: int = 0
		for seed_value: int in range(300, 340):
			var build: SheetBuilder = SheetBuilder.rolled_opening(
				SeedRng.make_rng(seed_value), id)
			top = maxi(top, build.age() - ActorGenerator.MANAGER_DEBUT_MIN)
		oldest[id] = top
	t.check(int(oldest.get("founder", 99)) <= 1 + MANAGER_DEBUT_SPAN,
		"o fundador saiu com %d anos de carreira — ele é novato" % int(oldest.get("founder", -1)))
	t.check(int(oldest.get("student", 99)) <= MANAGER_DEBUT_SPAN,
		"o estudado saiu com %d anos de carreira — ele nunca jogou" % int(oldest.get("student", -1)))
	t.check(int(oldest.get("player", 0)) >= 4,
		"o ex-jogador saiu com %d anos de carreira — ele é o único que tem uma"
			% int(oldest.get("player", -1)))

# The manager's own debut window is 16..18, so any age measured from its floor
# carries up to two years that are not career at all.
const MANAGER_DEBUT_SPAN := 2

# ⚠️ SIXTEEN, AND THE REASON THIS NUMBER MOVED MATTERS. It was eighteen, and the
# stated reason was that you should not be creating a child — but the real
# problem underneath was a BUDGET: a child's debut gave a sheet worth three
# career points and a screen with nothing to edit. That is asserted separately,
# by MANAGER_MIN_BUDGET, and it is the assertion that was doing the work.
#
# With the scenarios carrying their own allocation the two came apart, and the
# age is free to be what the scene actually looks like: a founder who put a club
# together at seventeen is the most ordinary story in amateur flag.
const MANAGER_ADULT_AGE := 16
# Eight attributes one step above the ordinary adult is 24 career points, and
# that is the thinnest sheet the roll actually produces. The number is here to
# catch the collapse — a budget of three, which is what a child's debut gave —
# and not to pin the balance.
const MANAGER_MIN_BUDGET := 24
