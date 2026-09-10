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
		"test_no_randomness_in_creation",
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

# There is no seed here at all any more: two newborns are identical, and the
# career seed builds the world instead of the person.
func test_no_randomness_in_creation(t: TestHelper) -> void:
	t.equal(str(SheetBuilder.average_adult().stats), str(SheetBuilder.average_adult().stats), "atributos")
	t.equal(str(SheetBuilder.average_adult().skills), str(SheetBuilder.average_adult().skills), "habilidades")
	t.equal(SheetBuilder.average_adult().height, SheetBuilder.average_adult().height, "altura")

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
