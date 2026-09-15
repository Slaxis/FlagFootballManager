# Smoke test for the team screen — the one that finally shows the model.
#
# Mounts the scene over a real career on the Blackboard, reads the roster the
# screen built for itself, clicks somebody and switches tabs. A screen that
# dies halfway through building its own list leaves a half-drawn panel and a
# green run, which is exactly what this exists to stop.
extends RefCounted
class_name TestScreenTeam

const SCENE := "res://game/scene/team/team.tscn"
const SEED := 20260915

func tests() -> Array:
	return [
		"test_the_squad_is_listed",
		"test_you_are_in_your_own_squad",
		"test_clicking_somebody_opens_their_sheet",
		"test_the_rivals_tab_leaves_your_own_club_out",
		"test_the_roster_is_built_once_and_reused",
	]

# --- Harness ---

func _career() -> Career:
	League.ensure_filled(SEED)
	var builder: SheetBuilder = SheetBuilder.rolled_opening(SeedRng.make_rng(SEED))
	var manager: Actor = builder.to_actor(SEED, {
		"first_name": "Chefe", "last_name": "Da Casa", "nickname": "Chefinho"})
	manager.set_plays([Actor.CATEGORY_MASC])
	manager.set_manages([Actor.CATEGORY_MASC])
	manager.set_team("flag_kings")
	return Career.make(manager, "flag_kings", SEED)

func _open() -> Control:
	The.board["career"] = _career()
	The.board.erase("rosters")
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

func _collect(node: Node, type: String, into: Array) -> Array:
	if node.is_class(type):
		into.append(node)
	for child: Node in node.get_children():
		_collect(child, type, into)
	return into

func _texts(screen: Control) -> String:
	var all: Array[String] = []
	for node: Variant in _collect(screen, "Label", []):
		all.append((node as Label).text)
	return "\n".join(all)

func _button_with(screen: Control, text: String) -> Button:
	for node: Variant in _collect(screen, "Button", []):
		if (node as Button).text == text:
			return node
	return null

# --- Tests ---

func test_the_squad_is_listed(t: TestHelper) -> void:
	var screen: Control = _open()
	if screen == null:
		t.fail("não consegui instanciar a tela"); return
	var rosters := The.board.get("rosters", null) as Rosters
	t.not_null(rosters, "a tela não montou o elenco")
	if rosters == null:
		_close(screen); return
	var people: Array[Actor] = rosters.squad("flag_kings", Actor.CATEGORY_MASC)
	t.check(people.size() >= 5, "elenco com %d pessoas" % people.size())
	var shown: String = _texts(screen)
	for person: Actor in people:
		t.check(shown.contains(person.display_name()),
			"'%s' não apareceu na lista" % person.display_name())
	_close(screen)

# Standing outside the roster you manage is the kind of thing that only shows
# up when you finally look at the list.
func test_you_are_in_your_own_squad(t: TestHelper) -> void:
	var screen: Control = _open()
	if screen == null:
		t.fail("não consegui instanciar a tela"); return
	var rosters := The.board.get("rosters", null) as Rosters
	var found: bool = false
	for person: Actor in rosters.squad("flag_kings", Actor.CATEGORY_MASC):
		if person.display_name() == "Chefinho":
			found = true
	t.check(found, "o manager não está no próprio elenco")
	t.check(_texts(screen).contains("★"), "o manager não está marcado na lista")
	_close(screen)

func test_clicking_somebody_opens_their_sheet(t: TestHelper) -> void:
	var screen: Control = _open()
	if screen == null:
		t.fail("não consegui instanciar a tela"); return
	var rosters := The.board.get("rosters", null) as Rosters
	var people: Array[Actor] = rosters.squad("flag_kings", Actor.CATEGORY_MASC)
	if people.size() < 2:
		t.fail("preciso de duas pessoas para testar a troca"); _close(screen); return
	# The second one, so it is not whatever the screen picked by default.
	var wanted: Actor = people[1]
	var rows: Array = []
	for node: Variant in _collect(screen, "Button", []):
		if (node as Button).text == "":
			rows.append(node)
	t.check(rows.size() >= people.size(), "linhas clicáveis: %d" % rows.size())
	(rows[1] as Button).pressed.emit()
	var shown: String = _texts(screen)
	t.check(shown.contains(wanted.display_name()), "a ficha não abriu para quem cliquei")
	# The sheet is the debt A.2/A.3 left: the eight attributes have to be there.
	var stats := Drive.def("stat") as StatDef
	for id: String in stats.base_ids():
		var label: String = I18n.text(stats.base_stat(id).get("label", id), id)
		t.check(shown.contains(label), "a ficha não mostra '%s'" % label)
	_close(screen)

func test_the_rivals_tab_leaves_your_own_club_out(t: TestHelper) -> void:
	var screen: Control = _open()
	if screen == null:
		t.fail("não consegui instanciar a tela"); return
	var tab: Button = _button_with(screen, UiText.t("team.rivals"))
	if tab == null:
		t.fail("aba Adversários não existe"); _close(screen); return
	tab.pressed.emit()
	var shown: String = _texts(screen)
	var teams := Drive.def("team") as TeamDef
	var mine: String = String(teams.get_team("flag_kings").get("name", "Flag Kings"))
	var others: int = 0
	for club: Dictionary in teams.by_reputation():
		if String(club.get("id", "")) == "flag_kings":
			continue
		if shown.contains(String(club.get("name", ""))):
			others += 1
	t.check(others >= 10, "só %d adversários listados" % others)
	# The header still shows your club, so count the LIST, not the screen.
	t.equal(shown.count(mine), 1, "seu próprio clube apareceu na lista de adversários")
	_close(screen)

# Two hundred people invented at career start so the player can look at twelve
# is the thing the lazy fill exists to avoid.
func test_the_roster_is_built_once_and_reused(t: TestHelper) -> void:
	var screen: Control = _open()
	if screen == null:
		t.fail("não consegui instanciar a tela"); return
	var rosters := The.board.get("rosters", null) as Rosters
	t.check(rosters.has_squad("flag_kings", Actor.CATEGORY_MASC), "seu elenco não foi montado")
	var teams := Drive.def("team") as TeamDef
	var untouched: int = 0
	for club: Dictionary in teams.by_reputation():
		if not rosters.has_squad(String(club.get("id", "")), Actor.CATEGORY_MASC):
			untouched += 1
	t.check(untouched > 5, "a tela montou elenco de clube que ninguém abriu")
	_close(screen)
