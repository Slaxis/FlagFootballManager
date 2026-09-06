# Tests for the two-layer attribute model: 7 base attributes, 9 derived
# stats (each the floor of the average of exactly 3 base ones), and "Geral".
extends RefCounted
class_name TestStat

const BASE_IDS: Array[String] = [
	"strength", "stamina", "agility", "dexterity",
	"perception", "intelligence", "charisma",
]
const DERIVED_IDS: Array[String] = [
	"speed", "passing", "catching", "protection", "pressure",
	"coverage", "reading", "leadership", "trash_talk",
]

func tests() -> Array:
	return [
		"test_def_loads",
		"test_seven_base_attributes",
		"test_nine_derived_stats",
		"test_every_derived_reads_three_base",
		"test_derived_inputs_are_distinct_sets",
		"test_flat_sheet_derives_flat",
		"test_derive_floors_the_average",
		"test_overall_floors_the_average",
		"test_same_actor_differs_by_derived_stat",
		"test_unknown_ids_do_not_crash",
	]

func _def() -> StatDef:
	return Drive.def("stat") as StatDef

func test_def_loads(t: TestHelper) -> void:
	t.not_null(_def(), "StatDef")

func test_seven_base_attributes(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("StatDef ausente"); return
	t.equal(def.base_ids().size(), 7, "quantidade de stats base")
	for id: String in BASE_IDS:
		t.check(def.has_base(id), "stat base ausente: " + id)

func test_nine_derived_stats(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("StatDef ausente"); return
	t.equal(def.derived_ids().size(), 9, "quantidade de derivadas")
	for id: String in DERIVED_IDS:
		t.check(def.has_derived(id), "derivada ausente: " + id)

func test_every_derived_reads_three_base(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("StatDef ausente"); return
	for id: String in def.derived_ids():
		var inputs: Array = def.inputs_of(id)
		t.equal(inputs.size(), 3, "entradas de '%s'" % id)
		for input: Variant in inputs:
			t.check(def.has_base(String(input)),
				"derivada '%s' lê base inexistente '%s'" % [id, input])

# Two derived stats built from the same three attributes would be the same
# number under a different name — the model would be lying about depth.
func test_derived_inputs_are_distinct_sets(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("StatDef ausente"); return
	var seen: Dictionary = {}
	for id: String in def.derived_ids():
		var inputs: Array = def.inputs_of(id).duplicate()
		inputs.sort()
		var key: String = ",".join(PackedStringArray(inputs))
		t.check(not seen.has(key),
			"'%s' usa os mesmos 3 stats de '%s'" % [id, seen.get(key, "")])
		seen[key] = id

func test_flat_sheet_derives_flat(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("StatDef ausente"); return
	var sheet: Dictionary = def.blank_sheet(50)
	for id: String in def.derived_ids():
		t.equal(def.derive(sheet, id), 50, "derivada '%s' com tudo em 50" % id)
	t.equal(def.overall(sheet), 50, "Geral com tudo em 50")

func test_derive_floors_the_average(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("StatDef ausente"); return
	# speed = agility + strength + stamina -> (7 + 8 + 8) / 3 = 7.66 -> 7
	var sheet: Dictionary = def.blank_sheet(0)
	sheet["agility"] = 7
	sheet["strength"] = 8
	sheet["stamina"] = 8
	t.equal(def.derive(sheet, "speed"), 7, "arredondamento pra baixo em speed")

func test_overall_floors_the_average(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("StatDef ausente"); return
	# 6 atributos em 10 e um em 3 -> 63 / 7 = 9
	var sheet: Dictionary = def.blank_sheet(10)
	sheet["charisma"] = 3
	t.equal(def.overall(sheet), 9, "Geral arredondado pra baixo")

# The point of the model: one actor is not "good" or "bad", he is good at
# some things. This is what the coletivo is meant to reveal.
func test_same_actor_differs_by_derived_stat(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("StatDef ausente"); return
	var brute: Dictionary = def.blank_sheet(3)
	brute["strength"] = 10
	brute["stamina"] = 10
	brute["agility"] = 9
	t.check(def.derive(brute, "speed") > def.derive(brute, "passing"),
		"o brutamontes deveria correr melhor do que passar")
	t.check(def.derive(brute, "protection") > def.derive(brute, "leadership"),
		"o brutamontes deveria proteger melhor do que liderar")

func test_unknown_ids_do_not_crash(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("StatDef ausente"); return
	t.equal(def.derive(def.blank_sheet(50), "nao_existe"), 0, "derivada inexistente")
	t.equal(def.base_stat("nao_existe"), {}, "base inexistente")
	t.equal(def.derive({}, "speed"), 0, "ficha vazia")
