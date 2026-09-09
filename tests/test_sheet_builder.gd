# Tests for character creation priced in years of your life.
extends RefCounted
class_name TestSheetBuilder

const SEED := 424242

func tests() -> Array:
	return [
		"test_starts_as_a_newborn_at_zero",
		"test_age_climbs_as_you_spend",
		"test_age_goes_back_when_you_take_points_back",
		"test_full_budget_reaches_eighteen",
		"test_everything_can_be_given_back",
		"test_lowering_refunds_exactly_what_raising_cost",
		"test_start_is_blocked_until_the_budget_is_gone",
		"test_cannot_spend_more_than_you_have",
		"test_a_prodigy_costs_a_third_of_a_life",
		"test_balanced_build_fits_the_budget",
		"test_step_costs_are_linear_and_stats_cost_more",
		"test_the_top_half_of_the_ladder_costs_far_more",
		"test_bakes_steps_into_stored_units",
		"test_no_randomness_in_creation",
	]

func _builder() -> SheetBuilder:
	return SheetBuilder.newborn()

# Nothing is rolled. An initial roll only teaches the player to mash reroll
# until the dice agree with the build they already wanted.
func test_starts_as_a_newborn_at_zero(t: TestHelper) -> void:
	var builder: SheetBuilder = _builder()
	t.equal(builder.age(), 0, "idade inicial")
	t.equal(builder.spent(), 0, "nada gasto")
	t.equal(builder.remaining(), SheetBuilder.total_points(), "bolso cheio")
	for step: int in builder.stats.values():
		t.equal(step, 0, "atributo deveria começar em zero")
	for step: int in builder.skills.values():
		t.equal(step, 0, "habilidade deveria começar em zero")

# The mechanic in one assertion: points ARE years.
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
	var id: String = String(builder.stats.keys()[0])
	for i: int in range(6):
		builder.raise_stat(id)
	var older: int = builder.age()
	for i: int in range(6):
		builder.lower_stat(id)
	t.equal(builder.age(), SheetBuilder.START_AGE, "voltar tudo deveria rejuvenescer")
	t.check(older >= SheetBuilder.START_AGE, "idade nunca deveria cair abaixo do início")

func test_full_budget_reaches_eighteen(t: TestHelper) -> void:
	var builder: SheetBuilder = _builder()
	_spend_everything(builder)
	t.check(builder.remaining() < 1, "sobraram %d pontos" % builder.remaining())
	t.equal(builder.age(), SheetBuilder.END_AGE, "gastar tudo deveria dar 18")

func test_everything_can_be_given_back(t: TestHelper) -> void:
	var builder: SheetBuilder = _builder()
	var id: String = String(builder.stats.keys()[0])
	for i: int in range(5):
		builder.raise_stat(id)
	builder.stats[id] = int(builder.stats[id])
	for i: int in range(10):
		builder.lower_stat(id)
	t.equal(int(builder.stats[id]), SheetBuilder.MIN_STAT_STEP, "não voltou ao piso")
	t.equal(builder.remaining(), SheetBuilder.total_points(), "não devolveu tudo")
	t.equal(builder.age(), 0, "devolver tudo deveria voltar a zero anos")

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
# be exceptional at it. What it must cost is a visible slice of the whole life,
# so nobody stumbles into being a medal contender.
func test_a_prodigy_costs_a_third_of_a_life(t: TestHelper) -> void:
	var builder: SheetBuilder = _builder()
	var id: String = String(builder.stats.keys()[0])
	for i: int in range(20):
		builder.raise_stat(id)
	t.equal(int(builder.stats[id]), StatDef.MAX_STEP, "não conseguiu chegar ao topo")
	t.check(builder.spent() > SheetBuilder.total_points() / 3,
		"o prodígio só gastou %d de %d — barato demais" %
			[builder.spent(), SheetBuilder.total_points()])

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
	t.equal(str(SheetBuilder.newborn().stats), str(SheetBuilder.newborn().stats), "atributos")
	t.equal(str(SheetBuilder.newborn().skills), str(SheetBuilder.newborn().skills), "habilidades")
	t.equal(SheetBuilder.newborn().height, SheetBuilder.newborn().height, "altura")

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
