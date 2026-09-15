# Tests for perks: the catalogue, the price, and the one rule that makes the
# cap matter — a flaw pays you.
extends RefCounted
class_name TestPerk

func tests() -> Array:
	return [
		"test_catalogue_loads_with_a_cap_of_one",
		"test_every_perk_is_translated_and_declares_an_effect",
		"test_skill_effects_point_at_real_skills",
		"test_boons_charge_and_flaws_pay",
		"test_taking_a_perk_spends_career_points",
		"test_only_one_perk_at_a_time",
		"test_a_flaw_buys_more_sheet",
		"test_dropping_a_flaw_you_already_spent_is_refused",
		"test_an_unaffordable_boon_is_refused",
		"test_the_perk_reaches_the_actor",
		"test_generated_actors_respect_the_cap",
	]

func _def() -> PerkDef:
	return Drive.def("perk") as PerkDef

func test_catalogue_loads_with_a_cap_of_one(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("PerkDef ausente"); return
	t.check(def.perk_ids().size() >= 10, "catálogo de perks pequeno demais")
	t.equal(def.max_per_actor, 1, "no máximo um perk")
	t.check(not def.boons().is_empty(), "nenhuma qualidade")
	t.check(not def.flaws().is_empty(), "nenhum defeito")

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
		t.check(def.cost(id) != 0, "'%s' custa zero — perk de graça" % id)
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
			"perk '%s' aponta para a habilidade inexistente '%s'" % [id, effect.get("target", "")])
	t.check(checked > 0, "nenhum perk mexe em habilidade — o teste não testou nada")

func test_boons_charge_and_flaws_pay(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("PerkDef ausente"); return
	for id: String in def.boons():
		t.check(def.cost(id) > 0, "qualidade '%s' não custa nada" % id)
		t.check(not def.is_flaw(id), "'%s' classificada como defeito" % id)
	for id: String in def.flaws():
		t.check(def.cost(id) < 0, "defeito '%s' não devolve nada" % id)
		t.check(def.is_flaw(id), "'%s' classificado como qualidade" % id)

func test_taking_a_perk_spends_career_points(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("PerkDef ausente"); return
	var build: SheetBuilder = SheetBuilder.average_adult()
	var before: int = build.remaining()
	var boon: String = def.boons()[0]
	build.set_perk(boon)
	t.equal(build.perk, boon, "o perk deveria ter sido pego")
	t.equal(build.remaining(), before - def.cost(boon), "pontos após pegar o perk")
	t.check(build.has_perk(), "has_perk")

func test_only_one_perk_at_a_time(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("PerkDef ausente"); return
	var boons: Array[String] = def.boons()
	if boons.size() < 2:
		t.fail("preciso de duas qualidades para testar a troca"); return
	var build: SheetBuilder = SheetBuilder.average_adult()
	build.set_perk(boons[0])
	build.set_perk(boons[1])
	t.equal(build.perk, boons[1], "o segundo perk deveria substituir o primeiro")
	t.equal(build.perk_cost(), def.cost(boons[1]), "só o custo do perk atual")
	# Clicking the one you already have takes it off.
	build.set_perk(boons[1])
	t.equal(build.perk, "", "clicar de novo deveria remover")
	t.check(not build.has_perk(), "ficou com perk depois de remover")

# The whole reason flaws exist: they buy sheet. Without this a defect is pure
# downside and nobody would ever take one.
func test_a_flaw_buys_more_sheet(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("PerkDef ausente"); return
	var build: SheetBuilder = SheetBuilder.average_adult()
	var before: int = build.remaining()
	var flaw: String = def.flaws()[0]
	build.set_perk(flaw)
	t.equal(build.remaining(), before - def.cost(flaw), "o defeito deveria devolver pontos")
	t.check(build.remaining() > before, "o defeito não devolveu nada")
	t.check(not build.is_complete(), "com pontos sobrando não dá para começar")

func test_dropping_a_flaw_you_already_spent_is_refused(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("PerkDef ausente"); return
	var build: SheetBuilder = SheetBuilder.average_adult()
	var flaw: String = def.flaws()[0]
	build.set_perk(flaw)
	# Spend the refund down to nothing, then try to hand the flaw back.
	var guard: int = 0
	while build.cheapest_purchase() >= 0 and build.remaining() >= build.cheapest_purchase() and guard < 400:
		guard += 1
		build.raise_skill(Drive.def("stat").skill_ids()[0])
	t.check(build.remaining() < -def.cost(flaw), "não gastei o suficiente para o teste valer")
	t.check(not build.can_take_perk(""), "devolver o defeito gasto deveria ser negado")
	build.set_perk(flaw)
	t.equal(build.perk, flaw, "o defeito saiu mesmo sem poder pagar")
	t.check(build.remaining() >= 0, "o jogador ficou com pontos negativos")

func test_an_unaffordable_boon_is_refused(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("PerkDef ausente"); return
	var build: SheetBuilder = SheetBuilder.average_adult()
	var priciest: String = ""
	for id: String in def.boons():
		if priciest == "" or def.cost(id) > def.cost(priciest):
			priciest = id
	var guard: int = 0
	while build.remaining() > def.cost(priciest) - 1 and guard < 400:
		guard += 1
		build.raise_skill(Drive.def("stat").skill_ids()[0])
	t.check(build.remaining() < def.cost(priciest), "ainda sobra para o perk mais caro")
	t.check(not build.can_take_perk(priciest), "um perk caro demais deveria ser negado")
	build.set_perk(priciest)
	t.equal(build.perk, "", "pegou um perk que não podia pagar")

func test_the_perk_reaches_the_actor(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("PerkDef ausente"); return
	var build: SheetBuilder = SheetBuilder.average_adult()
	var boon: String = def.boons()[0]
	build.set_perk(boon)
	var actor: Actor = build.to_actor(1, {"first_name": "Teste", "last_name": "Um"})
	t.equal(actor.perks().size(), 1, "quantidade de perks no actor")
	t.check(actor.has_perk(boon), "o actor não ficou com o perk escolhido")
	var bare: Actor = SheetBuilder.average_adult().to_actor(1, {})
	t.equal(bare.perks().size(), 0, "sem perk deveria sair vazio, não nulo")

# The manager and a scouted player are built from the same catalogue, so the
# cap has to hold on both sides.
func test_generated_actors_respect_the_cap(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("PerkDef ausente"); return
	var with_perk: int = 0
	for actor: Actor in ActorGenerator.squad(31337, 60, 60):
		t.check(actor.perks().size() <= def.max_per_actor,
			"%s saiu com %d perks" % [actor.full_name(), actor.perks().size()])
		for id: Variant in actor.perks():
			t.check(def.has_perk(String(id)), "perk inventado: %s" % id)
		if not actor.perks().is_empty():
			with_perk += 1
	t.check(with_perk > 0, "ninguém em 60 jogadores tirou um perk")
	t.check(with_perk < 60, "todo mundo tirou um perk")
