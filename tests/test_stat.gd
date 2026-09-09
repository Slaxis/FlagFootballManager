# Tests for the sheet: 8 attributes, 15 skills, two measures, and the scale
# that ties them to the dice.
extends RefCounted
class_name TestStat

const BASE_IDS: Array[String] = [
	"strength", "stamina", "agility", "dexterity",
	"perception", "intelligence", "charisma", "will",
]

func tests() -> Array:
	return [
		"test_eight_attributes_including_will",
		"test_fifteen_skills_each_governed_by_a_real_attribute",
		"test_no_derived_layer_survives",
		"test_step_is_stored_over_ten",
		"test_modifier_is_zero_at_the_average_adult",
		"test_modifier_punishes_a_bad_leader",
		"test_taller_trades_agility_for_perception",
		"test_body_is_worth_at_most_three_steps",
		"test_measures_never_touch_the_same_attribute",
		"test_measures_move_in_real_units",
		"test_nearby_heights_read_the_same",
		"test_heavier_trades_stamina_for_strength",
		"test_median_body_changes_nothing",
		"test_body_trade_is_zero_sum",
		"test_roll_base_sums_aptitude_and_practice",
		"test_quality_stays_inside_the_adult_band",
	]

func _def() -> StatDef:
	return Drive.def("stat") as StatDef

func test_eight_attributes_including_will(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("StatDef ausente"); return
	t.equal(def.base_ids().size(), 8, "quantidade de atributos")
	for id: String in BASE_IDS:
		t.check(def.has_base(id), "atributo ausente: " + id)

func test_fifteen_skills_each_governed_by_a_real_attribute(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("StatDef ausente"); return
	t.equal(def.skill_ids().size(), 15, "quantidade de habilidades")
	for id: String in def.skill_ids():
		var attribute: String = def.skill_attribute(id)
		t.check(def.has_base(attribute),
			"habilidade '%s' é regida por '%s', que não é atributo" % [id, attribute])
		t.check(def.skill_group(id) != "", "habilidade '%s' sem grupo" % id)

# The derived layer had nowhere to put training. If it comes back, the roll
# stops being aptitude + practice.
func test_no_derived_layer_survives(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("StatDef ausente"); return
	t.check(not def.has_method("derive"), "a camada 'derived' voltou")

func test_step_is_stored_over_ten(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("StatDef ausente"); return
	t.equal(def.step(0), 0, "0 armazenado")
	t.equal(def.step(49), 4, "49 armazenado")
	t.equal(def.step(50), 5, "50 armazenado")
	t.equal(def.step(100), 10, "100 armazenado")
	t.equal(def.step(180), 10, "acima do teto")
	t.equal(def.stored_for(5), 50, "5 passos de volta a armazenado")

# The anchor the author defined IS the zero of the modifier: an average adult
# leads nobody anywhere.
func test_modifier_is_zero_at_the_average_adult(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("StatDef ausente"); return
	t.equal(def.modifier(50), 0, "5 passos")
	t.equal(def.modifier(60), 1, "6 passos")
	t.equal(def.modifier(70), 2, "7 passos")
	t.equal(def.modifier(100), 5, "10 passos")

func test_modifier_punishes_a_bad_leader(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("StatDef ausente"); return
	t.equal(def.modifier(40), -1, "4 passos")
	t.equal(def.modifier(30), -2, "3 passos")
	t.check(def.modifier(10) < 0, "um líder de 1 passo deveria atrapalhar")

func test_taller_trades_agility_for_perception(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("StatDef ausente"); return
	var tall: Dictionary = def.body_effect({"height": 2.08, "weight": 78})
	t.check(int(tall.get("perception", 0)) > 0, "alto deveria enxergar mais")
	t.check(int(tall.get("agility", 0)) < 0, "alto deveria perder agilidade")

func test_heavier_trades_stamina_for_strength(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("StatDef ausente"); return
	var heavy: Dictionary = def.body_effect({"height": 1.78, "weight": 108})
	t.check(int(heavy.get("strength", 0)) > 0, "pesado deveria ganhar força")
	t.check(int(heavy.get("stamina", 0)) < 0, "pesado deveria perder vitalidade")

# An extreme body is worth THREE steps, no more. One was too timid to change a
# build; three is a real shape you feel on the field.
func test_body_is_worth_at_most_three_steps(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("StatDef ausente"); return
	var limit: int = def.stored_per_step * 3
	for body: Dictionary in [
		{"height": 2.15, "weight": 140}, {"height": 1.55, "weight": 50},
		{"height": 2.15, "weight": 50}, {"height": 1.55, "weight": 140},
	]:
		for id: String in def.body_effect(body).keys():
			var value: int = int(def.body_effect(body)[id])
			t.check(absi(value) <= limit,
				"corpo %s move '%s' em %d — mais de um passo" % [str(body), id, value])
	# And it has to actually reach three, or it is decoration.
	t.equal(int(def.body_effect({"height": 2.15, "weight": 78}).get("perception", 0)), limit,
		"o corpo extremo deveria valer três passos")

# The cheese that made this rule necessary: when height and weight both fed
# strength, a small light build dumped the stat it did not need and collected
# the credit in two it did.
func test_measures_never_touch_the_same_attribute(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("StatDef ausente"); return
	var seen: Dictionary = {}
	for id: String in def.measure_ids():
		for stat_id: String in (def.measure(id).get("affects", {}) as Dictionary).keys():
			t.check(not seen.has(stat_id),
				"'%s' é afetado por '%s' e por '%s' — as duas medidas empilham" %
					[stat_id, seen.get(stat_id, "?"), id])
			seen[stat_id] = id

# You enter your own body in centimetres and kilos, not in game units.
func test_measures_move_in_real_units(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("StatDef ausente"); return
	t.equal(def.increment("height"), 0.01, "altura anda de centímetro em centímetro")
	t.equal(def.increment("weight"), 1.0, "peso anda de quilo em quilo")
	t.check(def.increment("height") < float(def.measure("height").get("step", 1.0)),
		"o passo do teclado deveria ser mais fino que a faixa do efeito")

# Fine input, coarse effect: a couple of centimetres are the same person, and
# only crossing a threshold moves an attribute.
func test_nearby_heights_read_the_same(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("StatDef ausente"); return
	# The band is five centimetres wide and centred on the median, so its edges
	# fall on odd numbers — 1,79 and 1,81 really are different people.
	t.equal(def.bucket("height", 1.76), def.bucket("height", 1.80), "1,76 e 1,80")
	t.equal(def.bucket("height", 1.81), def.bucket("height", 1.84), "1,81 e 1,84")
	t.equal(def.bucket("height", 1.78), 0, "a mediana é a faixa zero")
	t.check(def.bucket("height", 1.80) != def.bucket("height", 1.81),
		"a fronteira da faixa deveria existir em algum lugar")
	t.check(def.bucket("height", 1.90) > def.bucket("height", 1.80),
		"10 cm deveriam mudar de faixa")
	t.equal(def.bucket("height", 2.15), 5, "o topo satura no cap")
	t.equal(def.bucket("weight", 140.0), 5, "o topo do peso satura no cap")
	t.equal(def.bucket("weight", 50.0), -5, "o piso do peso satura no cap")

func test_median_body_changes_nothing(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("StatDef ausente"); return
	for value: int in def.body_effect({"height": 1.78, "weight": 78}).values():
		t.equal(value, 0, "corpo mediano não deveria mexer em nada")

# Being 2.10 m is a SHAPE, not an upgrade. If the trade stopped being zero-sum
# the creation screen would have a dominant build.
func test_body_trade_is_zero_sum(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("StatDef ausente"); return
	for body: Dictionary in [
		{"height": 2.10, "weight": 78}, {"height": 1.60, "weight": 78},
		{"height": 1.78, "weight": 120}, {"height": 2.05, "weight": 115},
	]:
		var total: int = 0
		for value: int in def.body_effect(body).values():
			total += value
		t.equal(total, 0, "troca do corpo %s somou %d em vez de 0" % [str(body), total])

func test_roll_base_sums_aptitude_and_practice(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("StatDef ausente"); return
	var actor := Actor.new()
	actor._apply_data("t", "actor", {
		"stats": def.blank_sheet(70), "skills": def.blank_skills(30),
		"height": 1.78, "weight": 78,
	})
	# throwing is governed by dexterity: 7 steps of aptitude + 3 of practice.
	t.equal(actor.step("dexterity"), 7, "passos do atributo")
	t.equal(actor.skill_step("throwing"), 3, "passos da habilidade")
	t.equal(actor.roll_base("throwing"), 10, "base do roll")

# Reputation is not an attribute value: the worst club fields bad adults, not
# children, and the champion is not an Olympian.
func test_quality_stays_inside_the_adult_band(t: TestHelper) -> void:
	var worst: int = ActorGenerator.quality_from_reputation(12)
	var best: int = ActorGenerator.quality_from_reputation(90)
	t.check(worst >= 35 and worst <= 45, "várzea saiu com qualidade %d" % worst)
	t.check(best >= 70 and best <= 85, "campeão saiu com qualidade %d" % best)
	t.check(best > worst + 20, "a distância entre várzea e elite ficou pequena")
