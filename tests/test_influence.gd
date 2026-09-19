# Tests for the three currencies — and the one that matters most is the
# calibration, not the arithmetic.
#
# The formulas are three lines and they were never going to be wrong. What WAS
# wrong, and what only a measurement caught, is that the weekly income divided
# by three: every scenario opens around step 2, step 2 is the entire early game,
# and `1 + 2/3` is 1 for all three of them. A dial that does not move across the
# only range the player will ever see is not a dial.
extends RefCounted
class_name TestInfluence

func tests() -> Array:
	return [
		"test_the_three_stay_on_the_ruler",
		"test_each_scenario_owns_a_different_corner",
		"test_the_income_separates_the_scenarios",
		"test_a_long_career_does_not_buy_the_whole_ruler",
		"test_the_purse_holds_two_weeks",
	]

# ⚠️ THROUGH `to_actor`, NOT THROUGH A HAND-ROLLED COPY OF IT. A test that
# assembles its own Actor out of a builder is testing a person the game never
# makes — and `to_actor` is where steps become STORED values, which is exactly
# the conversion these formulas read through.
func _manager(origin: String, seed_value: int = 4242) -> Actor:
	var builder: SheetBuilder = SheetBuilder.rolled_opening(
		SeedRng.make_rng(seed_value), origin)
	return builder.to_actor(seed_value, {
		"first_name": "Teste", "last_name": origin.capitalize(), "nickname": ""})

func test_the_three_stay_on_the_ruler(t: TestHelper) -> void:
	for origin: String in ["founder", "player", "student"]:
		var manager: Actor = _manager(origin)
		for id: String in Influence.ALL:
			var value: int = Influence.step(manager, id)
			t.check(value >= 0 and value <= StatDef.MAX_STEP,
				"%s de %s saiu fora da régua: %d" % [id, origin, value])

# ⚠️ THREE SCENARIOS, THREE CORNERS, and it is not arranged — it falls out of
# the sheets each origin already carries. The Fundador's is will and leadership,
# the Estudado's is rules and play calling, and the Ex-jogador's is YEARS, which
# is the one thing the other two cannot buy.
#
# If this ever collapses, the creation screen has stopped mattering after you
# leave it, which is the whole reason these currencies exist.
func test_each_scenario_owns_a_different_corner(t: TestHelper) -> void:
	var founder: Actor = _manager("founder")
	var player: Actor = _manager("player")
	var student: Actor = _manager("student")
	t.check(Influence.step(student, Influence.LOGOS) > Influence.step(player, Influence.LOGOS),
		"o estudado devia convencer pela lógica melhor que o ex-jogador (%d vs %d)" % [
			Influence.step(student, Influence.LOGOS),
			Influence.step(player, Influence.LOGOS)])
	t.check(Influence.step(player, Influence.ETHOS) > Influence.step(student, Influence.ETHOS),
		"o ex-jogador devia ter mais estrada que o estudado (%d vs %d)" % [
			Influence.step(player, Influence.ETHOS),
			Influence.step(student, Influence.ETHOS)])
	t.check(Influence.step(founder, Influence.PATHOS) > Influence.step(student, Influence.PATHOS),
		"o fundador devia convencer pelo carisma melhor que o estudado (%d vs %d)" % [
			Influence.step(founder, Influence.PATHOS),
			Influence.step(student, Influence.PATHOS)])

# THE BUG THIS TEST EXISTS FOR. At `1 + step/3` all three scenarios came out at
# 1·1·1 a week, because they all open around step 2. The formulas were fine and
# the game was flat.
func test_the_income_separates_the_scenarios(t: TestHelper) -> void:
	var weeks: Dictionary = {}
	for origin: String in ["founder", "player", "student"]:
		var manager: Actor = _manager(origin)
		var total: int = 0
		for id: String in Influence.ALL:
			var week: int = Influence.income(manager, id)
			t.check(week >= 1, "%s não recebe nada de %s por semana" % [origin, id])
			total += week
		weeks[origin] = total
	var shapes: Dictionary = {}
	for origin: String in weeks.keys():
		shapes[_shape(_manager(origin))] = true
	t.check(shapes.size() >= 2,
		"os três cenários recebem a mesma coisa por semana — a renda não está separando nada")

func _shape(manager: Actor) -> String:
	var out: Array[String] = []
	for id: String in Influence.ALL:
		out.append(str(Influence.income(manager, id)))
	return "-".join(out)

# Twenty-six years divided by three is nine steps of ethos before the will is
# counted, which is the whole ruler for having lasted.
func test_a_long_career_does_not_buy_the_whole_ruler(t: TestHelper) -> void:
	var lifer := Actor.new()
	lifer._apply_data("t", "actor", {"stats": {"will": 0}, "age": 40, "debut_age": 14})
	t.check(lifer.career_years() > Influence.CAREER_CAP,
		"o teste não construiu uma carreira longa o bastante")
	var capped: int = Influence.CAREER_CAP / Influence.CAREER_PER_STEP
	t.equal(Influence.step(lifer, Influence.ETHOS), capped,
		"a carreira sozinha passou do teto")

func test_the_purse_holds_two_weeks(t: TestHelper) -> void:
	var manager: Actor = _manager("founder")
	for id: String in Influence.ALL:
		t.equal(Influence.stock_cap(manager, id),
			Influence.income(manager, id) * Influence.STOCK_WEEKS,
			"o estoque de %s não são duas semanas" % id)
	# And a fresh manager opens with something to spend: an empty purse and a
	# week to wait is a first turn with no decision in it.
	var purse: Dictionary = Influence.of(manager)
	for id: String in Influence.ALL:
		t.check(int((purse[id] as Dictionary)["held"]) > 0,
			"o manager abriu sem %s nenhum" % id)
