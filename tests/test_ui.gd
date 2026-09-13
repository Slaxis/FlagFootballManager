# Tests for the UI string catalogue.
extends RefCounted
class_name TestUi

func tests() -> Array:
	return [
		"test_def_loads",
		"test_every_key_has_both_languages",
		"test_resolves_in_pt",
		"test_resolves_in_en",
		"test_missing_key_shows_the_key",
		"test_ui_text_wrapper_matches_def",
		"test_format_placeholders_survive_translation",
	]

func _def() -> UiDef:
	return Drive.def("ui") as UiDef

func test_def_loads(t: TestHelper) -> void:
	var def := _def()
	t.not_null(def, "UiDef")
	if def != null:
		t.check(def.keys().size() > 0, "catálogo vazio")

# A string translated in one language only would silently fall back and the
# other language would look finished when it is not.
func test_every_key_has_both_languages(t: TestHelper) -> void:
	var file := FileAccess.open("res://game/defs/ui.json", FileAccess.READ)
	if file == null:
		t.fail("não consegui abrir ui.json"); return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		t.fail("ui.json não é um objeto"); return
	var raw: Dictionary = parsed as Dictionary
	var strings: Dictionary = raw.get("strings", {})
	t.check(strings.size() > 0, "ui.json sem strings")
	for key: String in strings.keys():
		var entry: Variant = strings[key]
		if not entry is Dictionary:
			t.fail("'%s' não é um dict {pt, en}" % key)
			continue
		var dict: Dictionary = entry as Dictionary
		t.check(String(dict.get("pt", "")).strip_edges() != "", "'%s' sem tradução pt" % key)
		t.check(String(dict.get("en", "")).strip_edges() != "", "'%s' sem tradução en" % key)

func test_resolves_in_pt(t: TestHelper) -> void:
	var previous: String = I18n.get_lang()
	I18n.set_lang("pt")
	t.equal(UiText.t("start.new_game"), "Novo Jogo", "start.new_game em pt")
	I18n.set_lang(previous)

func test_resolves_in_en(t: TestHelper) -> void:
	var previous: String = I18n.get_lang()
	I18n.set_lang("en")
	t.equal(UiText.t("start.new_game"), "New Game", "start.new_game em en")
	t.equal(UiText.t("common.back"), "Back", "common.back em en")
	I18n.set_lang(previous)

# A blank label is a bug that hides itself. Showing the raw key does not.
func test_missing_key_shows_the_key(t: TestHelper) -> void:
	t.equal(UiText.t("nao.existe"), "nao.existe", "chave inexistente")
	t.equal(UiText.t("nao.existe", "fallback"), "fallback", "chave inexistente com fallback")

func test_ui_text_wrapper_matches_def(t: TestHelper) -> void:
	var def := _def()
	if def == null:
		t.fail("UiDef ausente"); return
	for key: String in def.keys():
		t.equal(UiText.t(key), def.t(key), "UiText divergiu do UiDef em '%s'" % key)

# `%s` / `%d` must survive into every language, or the screen crashes on the
# format call in the language nobody tested.
func test_format_placeholders_survive_translation(t: TestHelper) -> void:
	var previous: String = I18n.get_lang()
	for lang: String in ["pt", "en"]:
		I18n.set_lang(lang)
		t.check(UiText.t("clubs.count").contains("%s") and UiText.t("clubs.count").contains("%d"),
			"clubs.count perdeu os placeholders em %s: '%s'" % [lang, UiText.t("clubs.count")])
		t.check(UiText.t("module.subtitle").contains("%d"),
			"module.subtitle perdeu o %%d em %s" % lang)
	I18n.set_lang(previous)
