# Tests for the five bars, and mostly for the two things about them that are
# easy to get subtly wrong: that the weak are not made of paper, and that
# loyalty is about a RELATIONSHIP rather than about a person.
extends RefCounted
class_name TestPools

const SEED := 20260919

func tests() -> Array:
	return [
		"test_every_pool_opens_inside_its_own_ceiling",
		"test_the_weakest_body_is_not_made_of_paper",
		"test_a_stronger_body_holds_more",
		"test_loyalty_is_about_the_club_and_not_the_player",
		"test_a_founder_is_harder_to_lose",
		"test_a_fraction_is_safe_and_reads_zero_to_a_hundred",
		"test_the_bar_gets_longer_and_not_fuller",
	]

func _person(stats: Dictionary, level: float = 1.0, founder: bool = false) -> Actor:
	var actor := Actor.new()
	var payload: Dictionary = {"stats": stats, "level": level}
	if founder:
		payload["founder"] = true
	actor._apply_data("t", "actor", payload)
	return actor

# The ruler is stored over a hundred and read in steps of ten, so a step of two
# is the value twenty. Written out here rather than computed, because a test
# that derives its input the same way the code does proves nothing.
func _flat(step_value: int) -> Dictionary:
	var out: Dictionary = {}
	var def := Drive.def("stat") as StatDef
	if def == null:
		return out
	for id: String in def.base_ids():
		out[id] = step_value * 10
	return out

func test_every_pool_opens_inside_its_own_ceiling(t: TestHelper) -> void:
	var actor: Actor = _person(_flat(4))
	var def := Drive.def("pool") as PoolDef
	if def == null:
		t.fail("PoolDef ausente"); return
	var pools: Dictionary = Pools.of(actor, {})
	t.equal(pools.size(), Pools.ids().size(), "faltou pool")
	for id: String in Pools.ids():
		var pool: Dictionary = pools[id]
		t.check(int(pool["max"]) > 0, "%s abriu com teto zero" % id)
		t.check(int(pool["now"]) <= int(pool["max"]),
			"%s abriu com %d de %d" % [id, int(pool["now"]), int(pool["max"])])
		t.check(int(pool["now"]) >= 0, "%s abriu negativo" % id)

# ⚠️ DECISION 43, AND IT IS THE REASON THE FLOOR EXISTS. Step 0 is the twentieth
# percentile of PEOPLE, not the bottom of them — the adult who never trained
# still walks onto the pitch and still absorbs a shoulder. Without a floor the
# whole Q1 league would have two or three points of health, which reads as "the
# weak ones are made of paper" instead of "the strong ones last longer".
func test_the_weakest_body_is_not_made_of_paper(t: TestHelper) -> void:
	var def := Drive.def("pool") as PoolDef
	if def == null:
		t.fail("PoolDef ausente"); return
	var actor: Actor = _person(_flat(0))
	for id: String in Pools.ids():
		if def.sources(id).is_empty():
			continue
		t.equal(Pools.ceiling(actor, id), def.floor_value(),
			"%s de quem não treinou nada" % id)

func test_a_stronger_body_holds_more(t: TestHelper) -> void:
	var def := Drive.def("pool") as PoolDef
	if def == null:
		t.fail("PoolDef ausente"); return
	var weak: Actor = _person(_flat(2))
	var strong: Actor = _person(_flat(8))
	for id: String in Pools.ids():
		if def.sources(id).is_empty():
			continue
		t.check(Pools.ceiling(strong, id) > Pools.ceiling(weak, id),
			"%s não separou o Q1 do Q4 (%d vs %d)" % [id,
				Pools.ceiling(weak, id), Pools.ceiling(strong, id)])
	# And the ceiling is the one thing loyalty does NOT take from attributes:
	# nothing about a player says how much he can care about a club he has not
	# joined yet.
	t.equal(Pools.ceiling(strong, Pools.LOYALTY), Pools.ceiling(weak, Pools.LOYALTY),
		"a lealdade virou atributo")

# ⚠️ THE SAME PERSON, TWO CLUBS. This is the whole of what loyalty is: somebody
# who got into a side above his level is grateful, and somebody carrying a side
# below his is already being called by the neighbours. If this ever reads the
# other way round the fifth bar has quietly become a sixth attribute.
func test_loyalty_is_about_the_club_and_not_the_player(t: TestHelper) -> void:
	var nations := Drive.def("nation") as NationDef
	if nations == null:
		t.fail("NationDef ausente"); return
	var actor: Actor = _person(_flat(4), 3.0)
	var big: Dictionary = {"id": "a", "tier": 1, "reputation": 90}
	var small: Dictionary = {"id": "b", "tier": 4, "reputation": 12}
	var at_big: int = Pools.opening(actor, Pools.LOYALTY, big)
	var at_small: int = Pools.opening(actor, Pools.LOYALTY, small)
	t.check(at_big > at_small,
		"o mesmo atleta ficou mais leal ao clube pior (%d no grande, %d no pequeno)"
			% [at_big, at_small])
	t.check(at_small < Pools.ceiling(actor, Pools.LOYALTY),
		"craque em time de várzea abriu com a barra cheia")

func test_a_founder_is_harder_to_lose(t: TestHelper) -> void:
	var plain: Actor = _person(_flat(4))
	var founder: Actor = _person(_flat(4), 1.0, true)
	var def := Drive.def("pool") as PoolDef
	if def == null:
		t.fail("PoolDef ausente"); return
	t.equal(Pools.ceiling(founder, Pools.LOYALTY),
		Pools.ceiling(plain, Pools.LOYALTY) + def.founder_bonus(Pools.LOYALTY),
		"quem fundou o clube devia ser mais difícil de perder")

func test_a_fraction_is_safe_and_reads_zero_to_a_hundred(t: TestHelper) -> void:
	t.equal(Pools.fraction({"now": 5, "max": 10}), 50, "meia barra")
	t.equal(Pools.fraction({"now": 10, "max": 10}), 100, "barra cheia")
	t.equal(Pools.fraction({"now": 0, "max": 10}), 0, "barra vazia")
	# A ceiling of zero cannot happen today, but a module may ship its own
	# catalogue and a division by zero inside a draw call is a black screen.
	t.equal(Pools.fraction({"now": 3, "max": 0}), 0, "teto zero derrubou a conta")
	t.equal(Pools.fraction({}), 0, "pool vazio derrubou a conta")


# ⚠️ THE BAR THAT NEVER MOVED. The pools were drawn with `StatBar.row`, which
# shows a FRACTION — and since nothing drains them yet, `now == max` and every
# one of them came out at a hundred per cent on every roll. Five full bars,
# forever, while the ceiling underneath went from four to eleven.
#
# A pool has two numbers and a fraction throws one away. What a gauge does is
# what every HP bar does: the LENGTH is the ceiling and the FILL is the present.
# This pins the thing that was broken — reroll a body and the bar has to change
# SIZE — rather than the arithmetic, which was never wrong.
func test_the_bar_gets_longer_and_not_fuller(t: TestHelper) -> void:
	var def := Drive.def("pool") as PoolDef
	if def == null:
		t.fail("PoolDef ausente"); return
	t.check(def.scale_value() > 0, "a escala do medidor é zero")
	var weak: Actor = _person(_flat(0))
	var strong: Actor = _person(_flat(8))
	for id: String in Pools.ids():
		if def.sources(id).is_empty():
			continue
		var small: Dictionary = Pools.of(weak, {}).get(id, {})
		var big: Dictionary = Pools.of(strong, {}).get(id, {})
		# The fraction is identical — that IS the bug, written down.
		t.equal(Pools.fraction(small), Pools.fraction(big),
			"%s: as duas frações deveriam ser 100, e a fração é o que enganava" % id)
		t.check(int(big["max"]) > int(small["max"]),
			"%s: o teto não cresceu, então não há o que a barra possa mostrar" % id)
		# And the gauge has to turn that into a visibly different number of slots.
		t.check(_slots(int(big["max"]), def.scale_value())
				> _slots(int(small["max"]), def.scale_value()),
			"%s: teto %d e teto %d desenham o mesmo número de casas" % [
				id, int(small["max"]), int(big["max"])])

func _slots(top: int, scale: int) -> int:
	return clampi(int(round(float(top) * float(StatBar.SLOTS) / float(scale))),
		1, StatBar.SLOTS)
