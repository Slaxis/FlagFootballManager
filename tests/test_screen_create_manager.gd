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
	# Whatever it rolled has to be startable, or the button looks broken.
	t.check(_button_starting_with(screen, UiText.t("manager.random")) != null,
		"o botão de sortear clube sumiu depois do dado")
	t.check(not (_button_starting_with(screen, UiText.t("manager.random")) as Button).disabled,
		"o dado deixou uma ficha que não pode começar")
	_close(screen)

func test_a_perk_chip_can_be_taken_and_dropped(t: TestHelper) -> void:
	var perks := Drive.def("perk") as PerkDef
	var screen: Control = _open()
	if screen == null or perks == null:
		t.fail("não consegui instanciar a tela"); return
	var chip: Button = _button_starting_with(screen, perks.icon(perks.boons()[0]))
	if chip == null:
		t.fail("chip do perk não foi desenhado"); _close(screen); return
	t.check(not chip.button_pressed, "a tela abriu com um perk já escolhido")
	chip.pressed.emit()
	var taken: Button = _button_starting_with(screen, perks.icon(perks.boons()[0]))
	t.check(taken.button_pressed, "o perk não ficou marcado")
	taken.pressed.emit()
	t.check(not _button_starting_with(screen, perks.icon(perks.boons()[0])).button_pressed,
		"clicar de novo não tirou o perk")
	_close(screen)

func test_drafting_a_club_reaches_the_result(t: TestHelper) -> void:
	var screen: Control = _open()
	if screen == null:
		t.fail("não consegui instanciar a tela"); return
	# The sheet opens with points left over, so spend them the way the dice do.
	_button_starting_with(screen, "🎲").pressed.emit()
	var draw: Button = _button_starting_with(screen, UiText.t("manager.random"))
	if draw == null:
		t.fail("botão de sortear clube não existe"); _close(screen); return
	draw.pressed.emit()
	t.check(_button_starting_with(screen, UiText.t("manager.start")) != null,
		"não cheguei na tela do clube sorteado")
	t.equal(_collect(screen, "LineEdit", []).size(), 0,
		"o formulário continuou desenhado por cima do resultado")
	_close(screen)
