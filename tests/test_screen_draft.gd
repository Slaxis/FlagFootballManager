# Smoke test for the draft screen.
#
# It is the one screen whose whole job is to not look broken: a progress bar
# over nine seconds of arithmetic. If it stops advancing, or finishes without
# enabling the button, the player is stuck on a panel with no way forward and
# nothing in the log says so — GDScript has no exceptions, so a run that dies
# halfway leaves a half-filled bar and a green suite.
extends RefCounted
class_name TestScreenDraft

const SCENE := "res://game/scene/draft/draft.tscn"
const SEED := 20260420

func tests() -> Array:
	return [
		"test_it_builds_and_waits_for_you",
		"test_it_finishes_and_hands_over_a_built_world",
	]

func _career() -> Career:
	League.ensure_filled(SEED)
	var builder: SheetBuilder = SheetBuilder.rolled_opening(SeedRng.make_rng(SEED), "player")
	var manager: Actor = builder.to_actor(SEED, {
		"first_name": "Chefe", "last_name": "Da Casa", "nickname": "Chefinho"})
	manager.set_plays([Actor.CATEGORY_MASC])
	manager.set_manages([Actor.CATEGORY_MASC])
	manager.set_team("flag_kings")
	return Career.make(manager, "flag_kings", SEED)

func _open() -> Control:
	The.board["career"] = _career()
	The.board.erase("rosters")
	The.board.erase("praca")
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
	The.board.erase("career")
	The.board.erase("rosters")
	The.board.erase("praca")

func _collect(node: Node, type: String, into: Array) -> Array:
	if node.is_class(type):
		into.append(node)
	for child: Node in node.get_children():
		_collect(child, type, into)
	return into

func _ok_button(screen: Control) -> Button:
	for node: Variant in _collect(screen, "Button", []):
		if (node as Button).has_meta("draft_ok"):
			return node as Button
	return null

# The button is the whole point of the screen existing rather than a spinner:
# you get to read what happened before you move on.
func test_it_builds_and_waits_for_you(t: TestHelper) -> void:
	var screen: Control = _open()
	if screen == null:
		t.fail("não consegui instanciar a tela"); return
	t.check(_collect(screen, "ProgressBar", []).size() == 1, "sem barra de progresso")
	t.check(_collect(screen, "RichTextLabel", []).size() == 1, "sem log")
	var ok: Button = _ok_button(screen)
	if ok == null:
		t.fail("o botão de OK não foi desenhado"); _close(screen); return
	t.check(ok.disabled, "o OK abriu liberado — a liga nem começou a ser montada")
	_close(screen)

# Driven to completion by hand, because the runner does not give the engine
# frames between tests. One `_process` is one budget of work.
func test_it_finishes_and_hands_over_a_built_world(t: TestHelper) -> void:
	var screen: Control = _open()
	var positions := Drive.def("position") as PositionDef
	if screen == null or positions == null:
		t.fail("não consegui instanciar a tela"); return
	var bar := _collect(screen, "ProgressBar", [])[0] as ProgressBar
	var ok: Button = _ok_button(screen)
	var guard: int = 0
	while ok.disabled and guard < 4000:
		screen._process(0.0)
		guard += 1
	t.check(not ok.disabled, "a montagem não terminou em %d quadros" % guard)
	t.check(guard > 1, "terminou em um quadro só — não montou nada")
	t.equal(int(round(bar.value)), 100, "a barra não fechou em 100%")

	var written := _collect(screen, "RichTextLabel", [])[0] as RichTextLabel
	t.check(written.get_parsed_text().strip_edges() != "", "o log saiu vazio")

	# And what it hands over is a world, not a promise of one.
	var rosters := The.board.get("rosters", null) as Rosters
	var praca := The.board.get("praca", null) as Praca
	if rosters == null or praca == null:
		t.fail("a tela não entregou rosters/praça"); _close(screen); return
	t.check(praca.size() > 0, "a praça ficou vazia")
	var teams := Drive.def("team") as TeamDef
	var checked: int = 0
	for club: Dictionary in teams.by_reputation():
		var id: String = String(club.get("id", ""))
		if not rosters.has_squad(id, Actor.CATEGORY_MASC):
			continue
		checked += 1
		t.check(LeagueGenerator.playable(rosters, id, Actor.CATEGORY_MASC, positions),
			"'%s' saiu do draft sem conseguir entrar em quadra" % club.get("name", id))
	t.check(checked >= 10, "só %d clubes montados" % checked)

	# You are in your own squad, seated before the draft ran.
	var found: bool = false
	for person: Actor in rosters.squad("flag_kings", Actor.CATEGORY_MASC):
		if person.display_name() == "Chefinho":
			found = true
	t.check(found, "o manager não está no próprio elenco")
	_close(screen)
