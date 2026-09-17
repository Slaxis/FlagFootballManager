# Smoke test for the creation screen itself.
#
# The model tests prove the arithmetic; this one proves the screen that drives
# it survives being used. GDScript has no exceptions, so a screen that dies
# halfway through building its own form leaves a half-drawn panel and a green
# test run — which is exactly how the 1-career-point deadlock reached the
# player. Pressing the buttons here is the cheapest way to see it.
extends RefCounted
class_name TestScreenCreateManager

const SCENE := "res://game/scene/create_manager/create_manager.tscn"

func tests() -> Array:
	return [
		"test_the_form_builds",
		"test_the_seed_follows_the_name_fields",
		"test_the_dice_button_changes_the_person_and_the_world",
		"test_a_perk_chip_can_be_taken_and_dropped",
		"test_drafting_a_club_reaches_the_result",
	]

# --- Helpers ---

func _open() -> Control:
	var packed: PackedScene = load(SCENE) as PackedScene
	if packed == null:
		return null
	var screen: Control = packed.instantiate() as Control
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or screen == null:
		return null
	# _ready fires inside add_child, so the form exists when this returns.
	tree.root.add_child(screen)
	return screen

func _close(screen: Control) -> void:
	if is_instance_valid(screen):
		screen.get_parent().remove_child(screen)
		screen.queue_free()

func _collect(node: Node, type: String, into: Array) -> Array:
	if node.is_class(type):
		into.append(node)
	for child: Node in node.get_children():
		_collect(child, type, into)
	return into

func _button_starting_with(screen: Control, prefix: String) -> Button:
	for node: Variant in _collect(screen, "Button", []):
		var button := node as Button
		if button.text.begins_with(prefix):
			return button
	return null

func _seed_shown(screen: Control) -> String:
	# The seed is the only ACCENT-coloured label sitting next to the "SEED"
	# caption, so read it positionally rather than by text.
	var labels: Array = _collect(screen, "Label", [])
	for i: int in range(labels.size() - 1):
		if (labels[i] as Label).text == "SEED":
			return (labels[i + 1] as Label).text
	return ""

# --- Tests ---

func test_the_form_builds(t: TestHelper) -> void:
	var screen: Control = _open()
	if screen == null:
		t.fail("não consegui instanciar a tela"); return
	# Six, not three: the screen opens on the Fundador, and the Fundador names
	# his own club — nome, bairro e cidade on top of the three identity fields.
	# Every one of them arrives PRE-FILLED from the seed, because a blank name
	# box is a wall and a rolled one is a suggestion.
	var fields: Array = _collect(screen, "LineEdit", [])
	t.equal(fields.size(), 6, "3 de identidade + 3 do clube fundado")
	for field: Variant in fields:
		t.check((field as LineEdit).text.strip_edges() != "",
			"um dos campos abriu vazio")
	t.check(_collect(screen, "SpinBox", []).size() == 2, "altura e peso")
	t.check(_button_starting_with(screen, "🎲") != null, "botão de sortear tudo")
	t.check(_seed_shown(screen) != "", "semente não apareceu")
	_close(screen)

func test_the_seed_follows_the_name_fields(t: TestHelper) -> void:
	var screen: Control = _open()
	if screen == null:
		t.fail("não consegui instanciar a tela"); return
	var before: String = _seed_shown(screen)
	var first := _collect(screen, "LineEdit", [])[0] as LineEdit
	first.text = "Zoroastro"
	first.text_changed.emit("Zoroastro")
	var after: String = _seed_shown(screen)
	t.check(after != "", "a semente sumiu depois de digitar")
	t.check(after != before, "digitar o nome não mexeu na semente")
	# And typing the same thing again lands on the same world.
	first.text_changed.emit("Zoroastro")
	t.equal(_seed_shown(screen), after, "a mesma identidade deveria dar a mesma semente")
	_close(screen)

func test_the_dice_button_changes_the_person_and_the_world(t: TestHelper) -> void:
	var screen: Control = _open()
	if screen == null:
		t.fail("não consegui instanciar a tela"); return
	var before_seed: String = _seed_shown(screen)
	var before_name: String = (_collect(screen, "LineEdit", [])[0] as LineEdit).text
	var changed_name: int = 0
	var changed_seed: int = 0
	for i: int in range(8):
		_button_starting_with(screen, "🎲").pressed.emit()
		if (_collect(screen, "LineEdit", [])[0] as LineEdit).text != before_name:
			changed_name += 1
		if _seed_shown(screen) != before_seed:
			changed_seed += 1
	t.check(changed_name > 0, "o dado nunca trocou o nome")
	t.check(changed_seed > 0, "o dado nunca trocou o mundo")
	# And what it rolls is a CHILD: the six years that make an adult are still
	# the player's to spend, so the draft stays shut until they do.
	# The roll now finishes the sheet, so the draft opens immediately: what you
	# edit is a whole person, not a blank one.
	var draw: Button = _button_starting_with(screen, UiText.t("manager.random"))
	t.check(draw != null, "o botão de sortear clube sumiu depois do dado")
	t.check(not draw.disabled, "o dado deveria entregar uma ficha pronta para começar")
	_close(screen)

# The screen opens on a FINISHED adult, talent included. Swapping to a dearer
# one is a real trade now: you give back the one the dice handed you and, if
# that is not enough, you sell a step to cover the difference. That IS the edit
# loop, so the test walks it instead of pretending the points are free.
func test_a_perk_chip_can_be_taken_and_dropped(t: TestHelper) -> void:
	var perks := Drive.def("perk") as PerkDef
	var screen: Control = _open()
	var origins := Drive.def("origin") as OriginDef
	if screen == null or perks == null or origins == null:
		t.fail("não consegui instanciar a tela"); return
	# The ex-player arrives with two perk points, which is enough to take
	# something without trading first.
	_button_starting_with(screen, origins.label("player")).pressed.emit()
	# And the talents live on their own tab now: twenty-seven of them plus the
	# fifteen skills came to nine pixels over a 720px canvas, and splitting the
	# screen beat shaving nine pixels off it.
	_tab(screen, "manager.tab_talents_name")

	# The roll may already have spent the balance on a talent of its own — the
	# ex-player lives one to three years now, and a career hands out talents.
	# Give back whatever it took before asking whether a chip can be taken, or
	# this test is measuring the dice.
	for id: String in perks.boons():
		var owned: Button = _button_starting_with(screen, perks.icon(id))
		if owned != null and owned.button_pressed:
			owned.pressed.emit()

	var cheap: String = ""
	for id: String in perks.boons():
		if cheap == "" or perks.cost(id) < perks.cost(cheap):
			cheap = id
	var chip: Button = _button_starting_with(screen, perks.icon(cheap))
	if chip == null:
		t.fail("chip do talento não foi desenhado"); _close(screen); return

	var was_on: bool = chip.button_pressed
	chip.pressed.emit()
	t.check(_button_starting_with(screen, perks.icon(cheap)).button_pressed != was_on,
		"o talento não mudou de estado")
	_button_starting_with(screen, perks.icon(cheap)).pressed.emit()
	t.equal(_button_starting_with(screen, perks.icon(cheap)).button_pressed, was_on,
		"clicar de novo não voltou ao estado anterior")

	# A flaw pays, so it is always takeable whatever the balance.
	var flaw: String = perks.flaws()[0]
	_button_starting_with(screen, perks.icon(flaw)).pressed.emit()
	t.check(_button_starting_with(screen, perks.icon(flaw)).button_pressed,
		"o defeito deveria entrar sempre — ele paga")
	_close(screen)

# The form is three tabs — FICHA, HABILIDADES, TALENTOS — so a test that wants
# something has to be on the tab that draws it.
func _tab(screen: Control, key: String) -> void:
	var button: Button = _button_starting_with(screen, UiText.t(key))
	if button != null:
		button.pressed.emit()

func _pressed_chip(screen: Control, perks: PerkDef) -> Button:
	var found: Button = null
	for id: String in perks.perk_ids():
		var chip: Button = _button_starting_with(screen, perks.icon(id))
		if chip != null and chip.button_pressed:
			found = chip
	return found

func test_drafting_a_club_reaches_the_result(t: TestHelper) -> void:
	var screen: Control = _open()
	if screen == null:
		t.fail("não consegui instanciar a tela"); return
	var draw: Button = _button_starting_with(screen, UiText.t("manager.random"))
	if draw == null or draw.disabled:
		t.fail("a ficha sorteada deveria abrir o sorteio de clube na hora"); _close(screen); return
	draw.pressed.emit()
	t.check(_button_starting_with(screen, UiText.t("manager.start")) != null,
		"não cheguei na tela do clube sorteado")
	t.equal(_collect(screen, "LineEdit", []).size(), 0,
		"o formulário continuou desenhado por cima do resultado")
	_close(screen)

# Clicks "+" until the draft opens, which is the only path a player has. It
# doubles as proof that the sheet the dice deal CAN be spent to completion by
# hand — a roll that left an unspendable remainder would hang here.
func _spend_the_six_years(screen: Control) -> int:
	var clicks: int = 0
	while clicks < 400:
		var draw: Button = _button_starting_with(screen, UiText.t("manager.random"))
		if draw != null and not draw.disabled:
			return clicks
		var plus: Array = []
		for node: Variant in _collect(screen, "Button", []):
			var button := node as Button
			if button.text == "+" and not button.disabled:
				plus.append(button)
		if plus.is_empty():
			return clicks
		(plus[clicks % plus.size()] as Button).pressed.emit()
		clicks += 1
	return clicks
