# Tests for character creation priced in years of your life.
extends RefCounted
class_name TestSheetBuilder

const SEED := 424242

func tests() -> Array:
	return [
		"test_starts_as_a_twelve_year_old",
		"test_age_climbs_as_you_spend",
		"test_age_goes_back_when_you_take_points_back",
		"test_full_budget_reaches_eighteen",
		"test_can_sell_the_child_back_down_to_one",
		"test_lowering_refunds_exactly_what_raising_cost",
		"test_start_is_blocked_until_the_budget_is_gone",
		"test_cannot_spend_more_than_you_have",
		"test_ten_steps_is_out_of_reach_at_eighteen",
		"test_balanced_build_fits_the_budget",
		"test_every_step_has_a_price",
		"test_bakes_steps_into_stored_units",
		"test_is_deterministic",
	]

func _builder() -> SheetBuilder:
	return SheetBuilder.child(SEED)

func test_starts_as_a_twelve_year_old(t: TestHelper) -> void:
	var builder: SheetBuilder = _builder()
	t.equal(builder.age(), SheetBuilder.START_AGE, "idade inicial")
	t.equal(builder.spent(), 0, "nada gasto")
	t.equal(builder.remaining(), SheetBuilder.total_points(), "bolso cheio")
	for step: int in builder.stats.values():
		t.check(step >= 2 and step <= 4, "atributo de criança fora de 2..4: %d" % step)
	for step: int in builder.skills.values():
		t.equal(step, 0, "criança de 12 não tem prática nenhuma")

# The mechanic in one assertion: points ARE years.
func test_age_climbs_as_you_spend(t: TestHelper) -> void:
	var builder: SheetBuilder = _builder()
	var id: String = String(builder.stats.keys()[0])
	var before: int = builder.age()
	for i: int in range(SheetBuilder.POINTS_PER_YEAR):
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

# You may sell your childhood back down to one step — a bad body that learned
# to read the game instead.
func test_can_sell_the_child_back_down_to_one(t: TestHelper) -> void:
	var builder: SheetBuilder = _builder()
	var id: String = String(builder.stats.keys()[0])
	for i: int in range(10):
		builder.lower_stat(id)
	t.equal(int(builder.stats[id]), SheetBuilder.MIN_STAT_STEP, "não chegou ao piso de 1")
	t.check(builder.remaining() > SheetBuilder.total_points(),
		"descer não devolveu pontos (sobraram %d de %d)" % [builder.remaining(), SheetBuilder.total_points()])

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

# Ten steps is an Olympic medal contender. Nobody buys that at eighteen, and
# the cost curve is what makes the anchor mean something.
func test_ten_steps_is_out_of_reach_at_eighteen(t: TestHelper) -> void:
	var builder: SheetBuilder = _builder()
	var id: String = String(builder.stats.keys()[0])
	for i: int in range(20):
		builder.raise_stat(id)
	t.check(int(builder.stats[id]) < 10,
		"chegou a %d passos com o orçamento inteiro num atributo só" % int(builder.stats[id]))

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

# A missing price is not a missing feature — it is a button that never
# enables, and an attribute the player can never fix.
func test_every_step_has_a_price(t: TestHelper) -> void:
	for step: int in range(1, StatDef.MAX_STEP + 1):
		t.check(SheetBuilder.ATTRIBUTE_COST.has(step), "atributo sem preço no passo %d" % step)
		t.check(SheetBuilder.SKILL_COST.has(step), "habilidade sem preço no passo %d" % step)

func test_bakes_steps_into_stored_units(t: TestHelper) -> void:
	var def := Drive.def("stat") as StatDef
	if def == null:
		t.fail("StatDef ausente"); return
	var builder: SheetBuilder = _builder()
	var actor: Actor = builder.to_actor(SEED, {"first_name": "João", "last_name": "das Couves"})
	t.equal(actor.age(), builder.age(), "idade")
	t.equal(actor.full_name(), "João das Couves", "nome")
	for id: String in builder.stats.keys():
		t.equal(actor.stat(id), def.stored_for(int(builder.stats[id])),
			"armazenado de '%s'" % id)
		t.equal(def.step(actor.stat(id)), int(builder.stats[id]),
			"ida e volta de passos em '%s'" % id)

func test_is_deterministic(t: TestHelper) -> void:
	t.equal(str(SheetBuilder.child(SEED).stats), str(SheetBuilder.child(SEED).stats),
		"mesma seed deveria dar a mesma criança")
	t.check(str(SheetBuilder.child(SEED).stats) != str(SheetBuilder.child(SEED + 1).stats),
		"seeds diferentes deveriam dar crianças diferentes")

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
