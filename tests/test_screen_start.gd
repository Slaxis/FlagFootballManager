# Smoke test for the start screen, and for the chain behind its Quit button.
#
# Quit is four hops: the button asks the screen for a transition, the screen
# emits it, the Flow maps it to "$exit" and the boot layer turns that into
# leaving the application. It shipped broken because the LAST hop was never
# connected — the signal reached nobody — and nothing in the suite looked at
# any of it. This covers the three hops a test can see without killing the
# runner; the fourth is one line in `Game._on_flow_finished` and the boot smoke
# test is what proves it parses.
extends RefCounted
class_name TestScreenStart

const SCENE := "res://game/scene/start/start.tscn"
const FLOW_ID := "main_flow"

func tests() -> Array:
	return [
		"test_every_menu_button_asks_for_a_transition",
		"test_the_flow_answers_every_transition_the_screen_asks_for",
		"test_quit_means_leaving_the_application",
	]

func _open() -> Control:
	var packed: PackedScene = load(SCENE) as PackedScene
	var tree := Engine.get_main_loop() as SceneTree
	if packed == null or tree == null:
		return null
	var screen: Control = packed.instantiate() as Control
	tree.root.add_child(screen)
	return screen

func _close(screen: Control) -> void:
	if is_instance_valid(screen):
		screen.get_parent().remove_child(screen)
		screen.queue_free()

func _buttons(node: Node, into: Array) -> Array:
	if node is Button:
		into.append(node)
	for child: Node in node.get_children():
		_buttons(child, into)
	return into

func _start_step() -> Dictionary:
	var flows := Drive.def("flow") as FlowDef
	if flows == null:
		return {}
	for step: Variant in (flows.get_flow(FLOW_ID).get("steps", []) as Array):
		if String((step as Dictionary).get("id", "")) == "start":
			return step as Dictionary
	return {}

# A button that emits nothing is the failure mode the player reports as
# "o botão não faz nada", and it looks identical to a working one on screen.
func test_every_menu_button_asks_for_a_transition(t: TestHelper) -> void:
	var screen: Control = _open()
	if screen == null:
		t.fail("não consegui instanciar a tela"); return
	var asked: Array[String] = []
	(screen as Menu).transition_requested.connect(
		func(name: String) -> void: asked.append(name))
	var pressed: int = 0
	for node: Variant in _buttons(screen, []):
		var button := node as Button
		if button.disabled:
			continue
		pressed += 1
		button.pressed.emit()
	t.check(pressed >= 3, "só %d botões ativos na tela inicial" % pressed)
	t.equal(asked.size(), pressed, "algum botão foi apertado e não pediu nada")
	t.check(asked.has("quit"), "o botão Sair não pediu 'quit'")
	t.check(asked.has("new_game"), "Novo Jogo não pediu 'new_game'")
	_close(screen)

# The other half of the same bug: a screen can ask for a transition the Flow
# has never heard of, and the Flow answers with a warning nobody reads.
func test_the_flow_answers_every_transition_the_screen_asks_for(t: TestHelper) -> void:
	var screen: Control = _open()
	var step: Dictionary = _start_step()
	if screen == null or step.is_empty():
		t.fail("tela ou passo 'start' ausente"); return
	var transitions: Dictionary = step.get("transitions", {})
	t.check(not transitions.is_empty(), "o passo 'start' não declara transições")
	var asked: Array[String] = []
	(screen as Menu).transition_requested.connect(
		func(name: String) -> void: asked.append(name))
	for node: Variant in _buttons(screen, []):
		if not (node as Button).disabled:
			(node as Button).pressed.emit()
	for name: String in asked:
		t.check(transitions.has(name),
			"a tela pede '%s' e o fluxo não conhece essa transição" % name)
	_close(screen)

func test_quit_means_leaving_the_application(t: TestHelper) -> void:
	var step: Dictionary = _start_step()
	if step.is_empty():
		t.fail("passo 'start' ausente no fluxo"); return
	var transitions: Dictionary = step.get("transitions", {})
	t.equal(String(transitions.get("quit", "")), Flow.EXIT_TARGET,
		"'quit' deveria terminar o fluxo")
	# And the boot layer has to be listening, which is the hop that was missing:
	# the Flow emitted `flow_finished` into nothing for the whole of Fase B.
	var boot := load("res://addons/d5star/game/game.gd") as GDScript
	if boot == null:
		t.fail("game.gd da engine não carregou"); return
	var handlers: Array[String] = []
	for entry: Dictionary in boot.get_script_method_list():
		handlers.append(String(entry.get("name", "")))
	t.check(handlers.has("_on_flow_finished"),
		"o Game não trata mais o fim do fluxo — o botão Sair volta a não fazer nada")
