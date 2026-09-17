# Tests for talents: the catalogue, and the currency that is NOT career points.
#
# Career points are training — weeks in the gym, seasons on the field. A talent
# is not something you train into; it is what a career did to you. Keeping both
# in one pocket meant Craque cost the same as two seasons of work, which is
# comparing two different kinds of thing.
extends RefCounted
class_name TestPerk

func tests() -> Array:
	return [
		"test_catalogue_loads_and_prices_in_perk_points",
		"test_every_perk_is_translated_and_declares_an_effect",
		"test_every_talent_has_its_own_icon",
		"test_skill_effects_point_at_real_skills",
		"test_boons_charge_and_flaws_pay",
		"test_a_talent_costs_nothing_in_career_points",
		"test_as_many_as_the_balance_allows",
		"test_a_flaw_pays_for_a_talent",
		"test_an_unaffordable_boon_is_refused",
		"test_the_perks_reach_the_actor",
		"test_generated_actors_only_take_what_exists",
	]

func _def() -> PerkDef:
	return Drive.def("perk") as PerkDef

func _build(points: int) -> SheetBuilder:
	var builder: SheetBuilder = SheetBuilder.average_adult()
	builder.perk_points = points
	return builder

func test_catalogue_loads_and_prices_in_perk_points(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("PerkDef ausente"); return
	t.check(def.perk_ids().size() >= 10, "catálogo pequeno demais")
	t.check(not def.boons().is_empty(), "nenhuma qualidade")
	t.check(not def.flaws().is_empty(), "nenhum defeito")
	# Small integers, because this is not the career-point ruler.
	for id: String in def.perk_ids():
		t.check(absi(def.cost(id)) <= 3 and def.cost(id) != 0,
			"'%s' custa %d pp" % [id, def.cost(id)])

func test_every_perk_is_translated_and_declares_an_effect(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("PerkDef ausente"); return
	var previous: String = I18n.get_lang()
	for id: String in def.perk_ids():
		for lang: String in ["pt", "en"]:
			I18n.set_lang(lang)
			t.check(def.label(id).strip_edges() != "", "'%s' sem label em %s" % [id, lang])
			t.check(def.desc(id).strip_edges() != "", "'%s' sem descrição em %s" % [id, lang])
		t.check(def.icon(id) != "", "'%s' sem ícone" % id)
		t.check(String(def.effect(id).get("kind", "")) != "", "'%s' sem efeito" % id)
	I18n.set_lang(previous)

# The effect block is a contract with C.1: a perk pointing at a skill that does
# not exist would fail silently inside the match engine, months from now.
func test_skill_effects_point_at_real_skills(t: TestHelper) -> void:
	var def := _def()
	var stats := Drive.def("stat") as StatDef
	if def == null or stats == null:
		t.fail("Defs ausentes"); return
	var checked: int = 0
	for id: String in def.perk_ids():
		var effect: Dictionary = def.effect(id)
		if String(effect.get("scope", "")) != "skill":
			continue
		checked += 1
		t.check(stats.has_skill(String(effect.get("target", ""))),
			"'%s' aponta para a habilidade inexistente '%s'" % [id, effect.get("target", "")])
	t.check(checked > 0, "nenhum talento mexe em habilidade — o teste não testou nada")

func test_boons_charge_and_flaws_pay(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("PerkDef ausente"); return
	for id: String in def.boons():
		t.check(def.cost(id) > 0, "qualidade '%s' não custa nada" % id)
	for id: String in def.flaws():
		t.check(def.cost(id) < 0, "defeito '%s' não devolve nada" % id)
		t.check(def.is_flaw(id), "'%s' classificado como qualidade" % id)

# The two rulers are separate, and this is the assertion that says so.
func test_a_talent_costs_nothing_in_career_points(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("PerkDef ausente"); return
	var build: SheetBuilder = _build(3)
	var before: int = build.remaining()
	var boon: String = def.boons()[0]
	build.toggle_perk(boon)
	t.check(build.has_perk(boon), "o talento não entrou")
	t.equal(build.remaining(), before, "o talento mexeu no orçamento de treino")
	t.equal(build.perk_points_left(), 3 - def.cost(boon), "saldo de talento")

# Zomboid logic: as many as the balance allows. The old cap of one existed only
# because flaws refunded CAREER points and the optimal build was the entire
# flaw list — on a separate ruler the budget does that job by itself.
func test_as_many_as_the_balance_allows(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("PerkDef ausente"); return
	var build: SheetBuilder = _build(6)
	var taken: int = 0
	for id: String in def.boons():
		build.toggle_perk(id)
		if build.has_perk(id):
			taken += 1
	t.check(taken >= 2, "só %d talentos com seis pontos de saldo" % taken)
	t.equal(build.perks.size(), taken, "a lista não bate com o que entrou")
	t.check(build.perk_points_left() >= 0, "o saldo ficou negativo")

func test_a_flaw_pays_for_a_talent(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("PerkDef ausente"); return
	var dear: String = ""
	for id: String in def.boons():
		if dear == "" or def.cost(id) > def.cost(dear):
			dear = id
	# The flaw that PAYS most, so the trade is actually possible: the cheapest
	# one does not cover the dearest talent, which is the point of having a
	# spread of prices.
	var flaw: String = ""
	for id: String in def.flaws():
		if flaw == "" or def.cost(id) < def.cost(flaw):
			flaw = id
	var build: SheetBuilder = _build(1)

	t.check(def.cost(dear) > build.perk_points_left(), "o talento caro já cabia no saldo")
	build.toggle_perk(dear)
	t.check(not build.has_perk(dear), "peguei um talento que não cabia")

	build.toggle_perk(flaw)
	t.check(build.has_perk(flaw), "o defeito não entrou")
	t.equal(build.perk_points_left(), 1 - def.cost(flaw), "o defeito não pagou")
	build.toggle_perk(dear)
	t.check(build.has_perk(dear), "o defeito deveria ter bancado o talento")
	t.equal(build.perks.size(), 2, "os dois deveriam coexistir")

	# And handing the flaw back costs what it paid, so with the money already
	# spent it is refused — you do not get the talent for free.
	build.toggle_perk(flaw)
	t.check(build.has_perk(flaw), "devolver o defeito já gasto deveria ser negado")

func test_an_unaffordable_boon_is_refused(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("PerkDef ausente"); return
	var build: SheetBuilder = _build(0)
	for id: String in def.boons():
		build.toggle_perk(id)
		t.check(not build.has_perk(id), "'%s' entrou sem saldo" % id)
	t.equal(build.perks.size(), 0, "entrou alguém sem saldo")

func test_the_perks_reach_the_actor(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("PerkDef ausente"); return
	var build: SheetBuilder = _build(6)
	var wanted: Array[String] = []
	for id: String in def.boons():
		build.toggle_perk(id)
		if build.has_perk(id):
			wanted.append(id)
	var actor: Actor = build.to_actor(1, {"first_name": "Teste", "last_name": "Um"})
	t.equal(actor.perks().size(), wanted.size(), "quantidade de talentos no actor")
	for id: String in wanted:
		t.check(actor.has_perk(id), "o actor perdeu '%s'" % id)
	var bare: Actor = SheetBuilder.average_adult().to_actor(1, {})
	t.equal(bare.perks().size(), 0, "sem talento deveria sair vazio, não nulo")

func test_generated_actors_only_take_what_exists(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("PerkDef ausente"); return
	var with_perk: int = 0
	for actor: Actor in ActorGenerator.squad(31337, 40, 60):
		for id: Variant in actor.perks():
			t.check(def.has_perk(String(id)), "talento inventado: %s" % id)
		if not actor.perks().is_empty():
			with_perk += 1
	t.check(with_perk > 0, "ninguém em 40 jogadores tirou um talento")
	t.check(with_perk < 40, "todo mundo tirou um talento")

# THE ICON IS AN IDENTITY, not decoration. It is the whole of the Talento column
# on the roster — a 26px box with one glyph in it — so two talents sharing one
# means the column lies, and anything that looks a talent up by its glyph finds
# the wrong one. Which is exactly what happened: two of the thirteen talents
# added at once reused glyphs already in the catalogue, and the screen test that
# gives a talent back started giving back somebody else's.
func test_every_talent_has_its_own_icon(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("PerkDef ausente"); return
	var owner_of: Dictionary = {}
	for id: String in def.perk_ids():
		var icon: String = def.icon(id)
		t.check(icon.strip_edges() != "", "'%s' sem ícone" % id)
		if owner_of.has(icon):
			t.fail("ícone '%s' repetido entre '%s' e '%s'" % [icon, owner_of[icon], id])
		owner_of[icon] = id
	t.equal(owner_of.size(), def.perk_ids().size(), "ícones distintos")
