# Smoke test for the start screen, and for the chain behind its Quit button.
#
# Quit is four hops: the button asks the screen for a transition, the screen
# emits it, the Flow maps it to "$exit" and the boot layer turns that into
# leaving the application. It shipped broken because the LAST hop was never
# connected — the signal reached nobody — and nothing in the suite looked at
# any of it. This covers the three hops a test can see without killing the
# runner; the fourth is Flow quitting when the boot layer armed it, which the
# runner cannot survive being shown.
extends RefCounted
class_name TestScreenStart

const SCENE := "res://game/scene/start/start.tscn"
const FLOW_ID := "main_flow"

func tests() -> Array:
	return [
		"test_every_menu_button_asks_for_a_transition",
		"test_the_flow_answers_every_transition_the_screen_asks_for",
		"test_quit_means_leaving_the_application",
		"test_the_exit_policy_lives_on_the_survivor",
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
	t.equal(String((step.get("transitions", {}) as Dictionary).get("quit", "")),
		Flow.EXIT_TARGET, "'quit' deveria terminar o fluxo")

	# And the Flow really ends on that target. Driven directly rather than
	# through a scene swap, with the quit disarmed — armed, it would take the
	# test runner down with it.
	var flow := Flow.new()
	flow.quit_on_finish = false
	var finished: Array[bool] = []
	flow.flow_finished.connect(func() -> void: finished.append(true))
	flow._current_step = {"id": "start", "transitions": {"quit": Flow.EXIT_TARGET}}
	flow._on_transition_requested("quit")
	t.equal(finished.size(), 1, "o fluxo não terminou em '$exit'")
	flow.free()

# The bug behind the bug, and the reason the first fix did nothing.
#
# Game IS the boot scene, and the first `change_scene_to_packed` the Flow
# issues frees it — that is exactly why Flow is parented to the tree root
# instead. So a `flow_finished` listener installed on Game is dead before the
# player ever sees the start screen, and the Quit button silently does nothing.
# The policy has to be DECLARED on the survivor, not listened for by the
# casualty.
func test_the_exit_policy_lives_on_the_survivor(t: TestHelper) -> void:
	var flow := Flow.new()
	t.check("quit_on_finish" in flow, "Flow perdeu a política de saída")
	flow.free()
	var source: String = FileAccess.get_file_as_string("res://addons/d5star/game/game.gd")
	t.check(source != "", "não consegui ler o game.gd da engine")
	t.check(source.contains("quit_on_finish"),
		"o boot não declara mais o que '$exit' significa — o botão Sair volta a não fazer nada")
	t.check(not source.contains("flow_finished.connect"),
		"o boot voltou a ESCUTAR o fim do fluxo: Game é liberado na primeira troca de cena, "
		+ "então esse connect nunca dispara")
