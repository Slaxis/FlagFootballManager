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
	var pools: Dictionary = Pools.of(actor, {})
	t.equal(pools.size(), Pools.ALL.size(), "faltou pool")
	for id: String in Pools.ALL:
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
	var actor: Actor = _person(_flat(0))
	for id: String in [Pools.HEALTH, Pools.STAMINA, Pools.SANITY, Pools.EMOTIONAL]:
		t.equal(Pools.ceiling(actor, id), Pools.FLOOR,
			"%s de quem não treinou nada" % id)

func test_a_stronger_body_holds_more(t: TestHelper) -> void:
	var weak: Actor = _person(_flat(2))
	var strong: Actor = _person(_flat(8))
	for id: String in [Pools.HEALTH, Pools.STAMINA, Pools.SANITY, Pools.EMOTIONAL]:
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
	t.equal(Pools.ceiling(founder, Pools.LOYALTY),
		Pools.ceiling(plain, Pools.LOYALTY) + Pools.LOYALTY_FOUNDER,
		"quem fundou o clube devia ser mais difícil de perder")

func test_a_fraction_is_safe_and_reads_zero_to_a_hundred(t: TestHelper) -> void:
	t.equal(Pools.fraction({"now": 5, "max": 10}), 50, "meia barra")
	t.equal(Pools.fraction({"now": 10, "max": 10}), 100, "barra cheia")
	t.equal(Pools.fraction({"now": 0, "max": 10}), 0, "barra vazia")
	# A ceiling of zero cannot happen today, but a module may ship its own
	# catalogue and a division by zero inside a draw call is a black screen.
	t.equal(Pools.fraction({"now": 3, "max": 0}), 0, "teto zero derrubou a conta")
	t.equal(Pools.fraction({}), 0, "pool vazio derrubou a conta")
