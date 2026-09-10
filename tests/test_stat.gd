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
		"test_measures_move_in_real_units",
		"test_body_is_purely_cosmetic",
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

func test_measures_move_in_real_units(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("StatDef ausente"); return
	t.equal(def.increment("height"), 0.01, "altura anda de centímetro em centímetro")
	t.equal(def.increment("weight"), 1.0, "peso anda de quilo em quilo")
	t.check(def.increment("height") < float(def.measure("height").get("step", 1.0)),
		"o passo do teclado deveria ser mais fino que a faixa do efeito")

# Height and weight are cosmetic. They used to trade attributes, and the trade
# was zero-sum in steps but net-positive in career points — an extreme body was
# a free upgrade worth the entire spare budget. This guards the removal.
func test_body_is_purely_cosmetic(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("StatDef ausente"); return
	var sheet: Dictionary = def.blank_sheet(50)
	var small := Actor.new()
	small._apply_data("s", "actor", {"stats": sheet.duplicate(), "skills": def.blank_skills(30),
		"height": 1.55, "weight": 50})
	var huge := Actor.new()
	huge._apply_data("h", "actor", {"stats": sheet.duplicate(), "skills": def.blank_skills(30),
		"height": 2.15, "weight": 140})
	for id: String in def.base_ids():
		t.equal(huge.step(id), small.step(id), "o corpo mexeu em '%s'" % id)
		t.equal(huge.team_bonus(id), small.team_bonus(id), "o corpo mexeu no bônus de '%s'" % id)
	for id: String in def.skill_ids():
		t.equal(huge.roll_base(id), small.roll_base(id), "o corpo mexeu no roll de '%s'" % id)
	t.check(not def.has_method("body_effect"), "body_effect voltou")

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
