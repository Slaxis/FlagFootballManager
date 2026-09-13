# Tests for the category × format matrix.
extends RefCounted
class_name TestCategory

func tests() -> Array:
	return [
		"test_def_loads",
		"test_three_categories_two_formats",
		"test_labels_resolve_in_both_languages",
		"test_mens_side_needs_no_women",
		"test_mixed_side_needs_two_in_every_format",
		"test_womens_side_needs_the_whole_field",
		"test_unknown_ids_do_not_crash",
	]

func _def() -> CategoryDef:
	return Drive.def("category") as CategoryDef

func test_def_loads(t: TestHelper) -> void:
	t.not_null(_def(), "CategoryDef")

func test_three_categories_two_formats(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("CategoryDef ausente"); return
	for id: String in ["masc", "fem", "misto"]:
		t.check(def.has_category(id), "categoria ausente: " + id)
	for id: String in ["5x5", "4x4"]:
		t.check(def.has_format(id), "formato ausente: " + id)
	t.equal(def.on_field("5x5"), 5, "jogadores em campo no 5x5")
	t.equal(def.on_field("4x4"), 4, "jogadores em campo no 4x4")

func test_labels_resolve_in_both_languages(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("CategoryDef ausente"); return
	var previous: String = I18n.get_lang()
	I18n.set_lang("pt")
	t.equal(def.category_label("misto"), "Misto", "rótulo pt")
	I18n.set_lang("en")
	t.equal(def.category_label("misto"), "Mixed", "rótulo en")
	I18n.set_lang(previous)

func test_mens_side_needs_no_women(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("CategoryDef ausente"); return
	for format_id: String in ["5x5", "4x4"]:
		t.equal(def.min_women("masc", format_id), 0, "masc no " + format_id)

# The rule the author gave: two women, in both formats.
func test_mixed_side_needs_two_in_every_format(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("CategoryDef ausente"); return
	for format_id: String in ["5x5", "4x4"]:
		t.equal(def.min_women("misto", format_id), 2, "misto no " + format_id)

# "all" is the only rule whose number depends on the format.
func test_womens_side_needs_the_whole_field(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("CategoryDef ausente"); return
	t.equal(def.min_women("fem", "5x5"), 5, "fem no 5x5")
	t.equal(def.min_women("fem", "4x4"), 4, "fem no 4x4")

func test_unknown_ids_do_not_crash(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("CategoryDef ausente"); return
	t.equal(def.min_women("nao_existe", "5x5"), 0, "categoria inexistente")
	t.equal(def.min_women("misto", "nao_existe"), 2, "formato inexistente com regra fixa")
	t.equal(def.min_women("fem", "nao_existe"), 0, "formato inexistente com regra 'all'")
	t.equal(def.on_field("nao_existe"), 0, "formato inexistente")
	t.check(not def.has_category("nao_existe"), "categoria fantasma")
