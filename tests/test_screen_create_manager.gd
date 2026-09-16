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
	# The seed is the only ACCENT-coloured label sitting next to the "Seed"
	# caption, so read it positionally rather than by text.
	var labels: Array = _collect(screen, "Label", [])
	for i: int in range(labels.size() - 1):
		if (labels[i] as Label).text == "Seed":
			return (labels[i + 1] as Label).text
	return ""

# --- Tests ---

func test_the_form_builds(t: TestHelper) -> void:
	var screen: Control = _open()
	if screen == null:
		t.fail("não consegui instanciar a tela"); return
	var fields: Array = _collect(screen, "LineEdit", [])
	t.equal(fields.size(), 3, "nome, sobrenome e apelido")
	for field: Variant in fields:
		t.check((field as LineEdit).text.strip_edges() != "",
			"um dos campos de identidade abriu vazio")
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
	# On the ex-player scenario, because a FOUNDER has almost nothing on his
	# sheet — stats of zero and one — and you cannot trade what is not there.
	# That is worth knowing about the scenario, but it makes a poor fixture.
	_button_starting_with(screen, origins.label("player")).pressed.emit()

	# Sell first. The sheet opens with everything spent, and the talent the dice
	# handed you may be a DISADVANTAGE — giving one of those back costs the
	# points it paid you, so there has to be slack before anything moves. That
	# is the trade, not a bug.
	# The CHEAPEST talent, not the first. The screen rolls with a randomised
	# seed, and a founder's whole sheet can cost about what Craque does — so
	# asking for the dearest one made this a coin flip instead of a test.
	var wanted: String = ""
	for id: String in perks.boons():
		if wanted == "" or perks.cost(id) < perks.cost(wanted):
			wanted = id
	var guard: int = 0
	while guard < 80:
		var chip: Button = _button_starting_with(screen, perks.icon(wanted))
		var current: Button = _pressed_chip(screen, perks)
		if not chip.disabled and (current == null or current.text == chip.text):
			break
		var sold: Button = _first_enabled(screen, "−")
		if sold == null:
			break
		sold.pressed.emit()
		guard += 1
	t.check(guard > 0, "o talento estava de graça — a ficha não gastou tudo")

	var taken: Button = _pressed_chip(screen, perks)
	if taken != null and taken.text != _button_starting_with(screen, perks.icon(wanted)).text:
		taken.pressed.emit()
	t.equal(_pressed_chip(screen, perks), null, "não consegui largar o talento sorteado")
	t.check(not _button_starting_with(screen, perks.icon(wanted)).disabled,
		"vender passos não liberou o talento")

	_button_starting_with(screen, perks.icon(wanted)).pressed.emit()
	t.check(_button_starting_with(screen, perks.icon(wanted)).button_pressed,
		"o talento não ficou marcado")
	t.equal(_pressed_chip(screen, perks).text,
		_button_starting_with(screen, perks.icon(wanted)).text,
		"mais de um talento marcado ao mesmo tempo")

	_button_starting_with(screen, perks.icon(wanted)).pressed.emit()
	t.equal(_pressed_chip(screen, perks), null, "clicar de novo não tirou o talento")
	_close(screen)

func _first_enabled(screen: Control, text: String) -> Button:
	for node: Variant in _collect(screen, "Button", []):
		var button := node as Button
		if button.text == text and not button.disabled:
			return button
	return null

# The chip currently ON, or null. Doubles as the cap check: a second pressed
# chip would mean two perks at once.
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
