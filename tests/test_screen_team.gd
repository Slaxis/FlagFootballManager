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
		"test_clicking_a_rival_shows_their_squad",
		"test_the_roster_has_a_perk_column",
		"test_the_sheet_has_the_same_rows_for_everybody",
		"test_columns_sort_both_ways",
		"test_a_position_can_be_ticked_and_unticked",
		"test_every_position_has_a_button",
		"test_the_lineup_panel_shows_empty_slots",
		"test_an_extra_at_a_position_becomes_a_reserve",
		"test_the_card_shows_the_career",
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
	# He arrives ticked into his own chair in the real game — that claim lives
	# in test_sheet_builder, where it is the only thing being tested. Here it
	# would silently occupy a slot in every count on this screen.
	manager.data["lineup"] = []
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
	# Buttons count as text too: the headings became sortable, which made them
	# Buttons, and a check that only read Labels stopped seeing them.
	for node: Variant in _collect(screen, "Button", []):
		all.append((node as Button).text)
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
	t.equal(_tagged(screen, "roster_row").size(), people.size(), "linhas clicáveis")
	var row: Button = _row_named(screen, wanted.display_name())
	if row == null:
		t.fail("não achei a linha de " + wanted.display_name()); _close(screen); return
	row.pressed.emit()
	var shown: String = _texts(screen)
	t.check(shown.contains(wanted.display_name()), "a ficha não abriu para quem cliquei")
	# The sheet is the debt A.2/A.3 left: the eight attributes have to be there.
	#
	# BY CODE, not by name. Twenty-three named rows beside twenty-three bars was a
	# wall of words competing with the numbers they label, so the card shows INT,
	# PER, CAR — and the name moved to the tooltip, which is what the next
	# assertion checks, because a code nobody can expand is a code nobody can read.
	var stats := Drive.def("stat") as StatDef
	for id: String in stats.base_ids():
		t.check(shown.contains(stats.code(id)),
			"a ficha não mostra o código '%s'" % stats.code(id))
	t.check(_tooltips(screen).contains(
		I18n.text(stats.base_stat("intelligence").get("label", ""), "")),
		"o nome por extenso sumiu junto com o código — ele tem que estar no tooltip")
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
# The world is built ONCE, and the whole world at that. It used to be built a
# club at a time, on first look — which was cheap and meant nobody had come
# from anywhere: each club invented exactly the people it was short of and no
# two clubs ever wanted the same man. Now the draft is a single global event,
# so every club in the championship has a squad the moment you arrive, and the
# leftovers are standing in the Praça.
func test_the_roster_is_built_once_and_reused(t: TestHelper) -> void:
	var screen: Control = _open()
	if screen == null:
		t.fail("não consegui instanciar a tela"); return
	var rosters := The.board.get("rosters", null) as Rosters
	var praca := The.board.get("praca", null) as Praca
	t.check(rosters.has_squad("flag_kings", Actor.CATEGORY_MASC), "seu elenco não foi montado")
	var teams := Drive.def("team") as TeamDef
	var filled: int = 0
	for club: Dictionary in teams.by_reputation():
		if rosters.has_squad(String(club.get("id", "")), Actor.CATEGORY_MASC):
			filled += 1
	t.check(filled >= 10, "só %d clubes saíram do draft com elenco" % filled)
	t.check(praca != null and praca.size() > 0, "a praça ficou vazia — não há mercado")

	# And looking again does not rebuild it. A career that re-rolls its league
	# every time you open a screen has no state at all.
	var names: Array[String] = []
	for person: Actor in rosters.squad("flag_kings", Actor.CATEGORY_MASC):
		names.append(person.display_name())
	# Detached, NOT closed: _close wipes the Blackboard, and wiping it is the
	# one thing that would make this test pass for the wrong reason.
	_detach(screen)
	var again: Control = _reopen()
	if again == null:
		t.fail("não consegui reabrir a tela"); return
	var after: Array[String] = []
	for person: Actor in (The.board.get("rosters", null) as Rosters).squad(
			"flag_kings", Actor.CATEGORY_MASC):
		after.append(person.display_name())
	t.equal(str(after), str(names), "reabrir a tela remontou o elenco")
	_close(again)

func _detach(screen: Control) -> void:
	if is_instance_valid(screen) and screen.get_parent() != null:
		screen.get_parent().remove_child(screen)
		screen.queue_free()

# Same as _open, minus the wipe: this is what the second visit looks like.
func _reopen() -> Control:
	var packed: PackedScene = load(SCENE) as PackedScene
	var tree := Engine.get_main_loop() as SceneTree
	if packed == null or tree == null:
		return null
	var screen: Control = packed.instantiate() as Control
	tree.root.add_child(screen)
	return screen

# Half the question is "who else is out there"; the other half is "and who
# plays for them". The rivals tab listed clubs and stopped there.
func test_clicking_a_rival_shows_their_squad(t: TestHelper) -> void:
	var screen: Control = _open()
	if screen == null:
		t.fail("não consegui instanciar a tela"); return
	_button_with(screen, UiText.t("team.rivals")).pressed.emit()
	var teams := Drive.def("team") as TeamDef
	var rival: Dictionary = {}
	for club: Dictionary in teams.by_reputation():
		if String(club.get("id", "")) != "flag_kings":
			rival = club
			break
	var row: Button = null
	for node: Variant in _collect(screen, "Button", []):
		var button := node as Button
		if button.tooltip_text.contains(String(rival.get("name", "?"))):
			row = button
	if row == null:
		t.fail("a linha do adversário não é clicável"); _close(screen); return
	row.pressed.emit()

	var shown: String = _texts(screen)
	t.check(shown.contains(String(rival.get("name", ""))), "o cabeçalho não virou o clube dele")
	var rosters := The.board.get("rosters", null) as Rosters
	var their_squad: Array[Actor] = rosters.squad(String(rival["id"]), Actor.CATEGORY_MASC)
	t.check(their_squad.size() >= 5, "elenco do adversário com %d" % their_squad.size())
	for person: Actor in their_squad:
		t.check(shown.contains(person.display_name()),
			"'%s' não apareceu no elenco do adversário" % person.display_name())

	# And a way home, or the player is stuck looking at somebody else's club.
	var home: Button = _button_with(screen, UiText.t("team.back_to_mine"))
	if home == null:
		t.fail("sem volta para o meu clube"); _close(screen); return
	home.pressed.emit()
	t.check(_texts(screen).contains("Chefinho"), "não voltei para o meu elenco")
	_close(screen)

func test_the_roster_has_a_perk_column(t: TestHelper) -> void:
	var screen: Control = _open()
	var perks := Drive.def("perk") as PerkDef
	if screen == null or perks == null:
		t.fail("não consegui instanciar a tela"); return
	t.check(_texts(screen).contains(UiText.t("team.talent")), "sem cabeçalho de talento")
	var rosters := The.board.get("rosters", null) as Rosters
	var shown: String = _texts(screen)
	var with_perk: int = 0
	for person: Actor in rosters.squad("flag_kings", Actor.CATEGORY_MASC):
		if person.perks().is_empty():
			continue
		with_perk += 1
		t.check(shown.contains(perks.icon(String(person.perks()[0]))),
			"o perk de %s não apareceu na lista" % person.display_name())
	t.check(with_perk > 0, "nenhum jogador do elenco tem perk — o teste não testou nada")
	_close(screen)

# A rolled player has every skill above zero and a hand-built manager has one
# or two. Hiding the empty rows made those two sheets grow DIFFERENT rows, so
# you could not put them side by side — which is the only thing a sheet is
# for. An empty bar already says "never trained this".
func test_the_sheet_has_the_same_rows_for_everybody(t: TestHelper) -> void:
	var screen: Control = _open()
	var stats := Drive.def("stat") as StatDef
	if screen == null or stats == null:
		t.fail("não consegui instanciar a tela"); return
	var rosters := The.board.get("rosters", null) as Rosters
	var people: Array[Actor] = rosters.squad("flag_kings", Actor.CATEGORY_MASC)

	# The manager is the one with a nearly empty skill sheet; a filler is the
	# one with everything rolled. Both have to render the full set.
	var manager: Actor = null
	var filler: Actor = null
	for person: Actor in people:
		if person.display_name() == "Chefinho":
			manager = person
		elif filler == null:
			filler = person
	if manager == null or filler == null:
		t.fail("preciso do manager e de um gerado"); _close(screen); return

	# No premise about who is untrained: the manager now opens with a rolled
	# sheet like everybody else. The property is the one that matters — two
	# different people, the same rows — and it holds whoever they are.

	for person: Actor in [manager, filler]:
		var row: Button = _row_named(screen, person.display_name())
		if row == null:
			t.fail("não achei a linha de " + person.display_name()); continue
		row.pressed.emit()
		var shown: String = _texts(screen)
		for id: String in stats.skill_ids():
			t.check(shown.contains(stats.code(id)),
				"a ficha de %s não mostra '%s'" % [person.display_name(), stats.code(id)])
		for id: String in stats.base_ids():
			t.check(shown.contains(stats.code(id)),
				"a ficha de %s não mostra '%s'" % [person.display_name(), stats.code(id)])
	_close(screen)


# Every tooltip on the screen, joined. The card shows three-letter codes now, so
# the names and descriptions live here — and a code with no way to expand it is
# worse than the long name it replaced.
func _tooltips(screen: Control) -> String:
	var all: Array[String] = []
	for node: Variant in _collect(screen, "Control", []):
		var tip: String = (node as Control).tooltip_text
		if tip != "":
			all.append(tip)
	return "\n".join(all)

# Rows and role buttons are tagged with metadata, because their text is empty
# and Godot renames duplicate siblings.
func _tagged(screen: Control, key: String, value: Variant = null) -> Array:
	var out: Array = []
	for node: Variant in _collect(screen, "Button", []):
		var button := node as Button
		if not button.has_meta(key):
			continue
		if value == null or button.get_meta(key) == value:
			out.append(button)
	return out

# Reads the AGE CELL of each row in the order the rows are drawn. Looking the
# age up by display name was wrong: two players can share an apelido, and the
# dictionary silently kept one of them.
# Found by NAME, because the screen sorts the list and the roster does not — an
# index into one is somebody else in the other.
func _row_named(screen: Control, display_name: String) -> Button:
	for node: Variant in _tagged(screen, "roster_row"):
		for cell: Variant in _collect(node as Button, "Label", []):
			if (cell as Label).text == display_name:
				return node
	return null

func _ages_in_order(screen: Control) -> Array[int]:
	var out: Array[int] = []
	for node: Variant in _tagged(screen, "roster_row"):
		var cells: Array = _collect(node as Button, "Label", [])
		# mark, name, perk, strength, age
		if cells.size() >= 5:
			out.append(int(String((cells[4] as Label).text)))
	return out

# Sorting a roster is how a manager reads it. Clicking the column you are
# already on has to flip it, or you can see the best and never the worst.
func test_columns_sort_both_ways(t: TestHelper) -> void:
	var screen: Control = _open()
	if screen == null:
		t.fail("não consegui instanciar a tela"); return
	var header: Button = _button_with(screen, UiText.t("team.age"))
	if header == null:
		t.fail("cabeçalho de idade não é clicável"); _close(screen); return
	header.pressed.emit()

	var descending: Array[int] = _ages_in_order(screen)
	t.check(descending.size() >= 5, "só %d linhas lidas" % descending.size())
	for i: int in range(descending.size() - 1):
		t.check(descending[i] >= descending[i + 1],
			"fora de ordem decrescente: %d antes de %d" % [descending[i], descending[i + 1]])

	# Clicking the column you are already on flips it.
	_button_with(screen, UiText.t("team.age") + "  ▾").pressed.emit()
	var ascending: Array[int] = _ages_in_order(screen)
	t.equal(ascending.size(), descending.size(), "linhas depois de inverter")
	for i: int in range(ascending.size() - 1):
		t.check(ascending[i] <= ascending[i + 1],
			"fora de ordem crescente: %d antes de %d" % [ascending[i], ascending[i + 1]])
	t.check(ascending[0] == descending[descending.size() - 1], "a inversão não inverteu")
	_close(screen)

func test_a_position_can_be_ticked_and_unticked(t: TestHelper) -> void:
	var screen: Control = _open()
	var positions := Drive.def("position") as PositionDef
	if screen == null or positions == null:
		t.fail("não consegui instanciar a tela"); return
	var rosters := The.board.get("rosters", null) as Rosters
	var people: Array[Actor] = rosters.squad("flag_kings", Actor.CATEGORY_MASC)
	for person: Actor in people:
		t.check(person.lineup().is_empty(), "alguém já nasceu escalado")
		break

	var buttons: Array = _tagged(screen, "role", "qb")
	t.equal(buttons.size(), people.size(), "botões de QB na tela, um por atleta")
	(buttons[0] as Button).pressed.emit()
	var ticked: int = 0
	for person: Actor in people:
		if person.plays_position("qb"):
			ticked += 1
	t.equal(ticked, 1, "exatamente um atleta deveria ficar escalado de QB")

	# And ticking again releases him.
	(_tagged(screen, "role", "qb")[0] as Button).pressed.emit()
	for person: Actor in people:
		t.check(not person.plays_position("qb"), "clicar de novo não desescalou")
	_close(screen)

# Six buttons, one per position, and the codes are the ones a flag manager
# would recognise. Linebacker is 7v7 and must not be here.
func test_every_position_has_a_button(t: TestHelper) -> void:
	var screen: Control = _open()
	var positions := Drive.def("position") as PositionDef
	if screen == null or positions == null:
		t.fail("não consegui instanciar a tela"); return
	t.equal(positions.position_ids().size(), 14, "posições + cargos + administração")
	var shown: String = _texts(screen)
	for id: String in positions.position_ids():
		t.check(shown.contains(positions.code(id)),
			"posição '%s' não tem botão" % positions.code(id))
	t.equal(positions.ids_on_side("offense").size(), 3, "posições de ataque")
	t.equal(positions.ids_on_side("defense").size(), 3, "posições de defesa")
	t.equal(positions.ids_on_side("staff").size(), 5, "cargos de comissão")
	# Somebody answers for the club, somebody pays and somebody talks — three
	# chairs that exist even at the smallest club in the city.
	t.equal(positions.ids_on_side("admin").size(), 3, "cargos de administração")
	# The three group headers are what make eleven little buttons legible.
	for key: String in ["team.profile", "team.admin", "team.staff", "team.lineup"]:
		t.check(shown.contains(UiText.t(key)), "sem cabeçalho de grupo '%s'" % key)
	_close(screen)


# The complaint that started this: ticking boxes gave no sense of completeness.
# The panel answers it by drawing the holes, so "am I done" is a look and not a
# count.
func test_the_lineup_panel_shows_empty_slots(t: TestHelper) -> void:
	var screen: Control = _open()
	var positions := Drive.def("position") as PositionDef
	if screen == null or positions == null:
		t.fail("não consegui instanciar a tela"); return
	var shown: String = _texts(screen)
	t.check(shown.contains(UiText.t("team.side_offense")), "sem bloco de ataque")
	t.check(shown.contains(UiText.t("team.side_defense")), "sem bloco de defesa")
	# THE ESCALAÇÃO IS ALL HOLES AND THE COMISSÃO IS NOT, and that difference is
	# the design: picking the starting five is your job, so nobody arrives ticked
	# — but a club that went out and held a tryout for a defensive coordinator
	# HAS one, and drawing "Vazio" beside him would be a lie.
	#
	# Administração stays empty too: those three chairs are yours to hand out.
	var rosters := The.board.get("rosters", null) as Rosters
	var hired: int = rosters.staff_count("flag_kings", Actor.CATEGORY_MASC)
	var open_chairs: int = maxi(positions.slots_on_side("staff") - hired, 0)
	var total: int = positions.slots_on_side("admin") + open_chairs 		+ positions.slots_on_side("offense") + positions.slots_on_side("defense")
	t.check(hired > 0, "o clube não contratou comissão nenhuma")
	t.equal(shown.count(UiText.t("team.empty_slot")), total,
		"vagas vazias desenhadas (esperava %d, com %d da comissão já ocupadas)"
			% [total, hired])
	t.equal(positions.slots_on_side("admin") + positions.slots_on_side("staff")
		+ positions.slots_on_side("offense") + positions.slots_on_side("defense"), 18,
		"3 de administração + 5 de comissão + 5 de ataque + 5 de defesa")
	_close(screen)

# Two quarterbacks is not an error, it is how a coach finds out which one is
# better — and most weeks the event is the coletivo where both take snaps. The
# extra is depth, listed under RESERVAS with the position he would cover.
func test_an_extra_at_a_position_becomes_a_reserve(t: TestHelper) -> void:
	var screen: Control = _open()
	var positions := Drive.def("position") as PositionDef
	if screen == null or positions == null:
		t.fail("não consegui instanciar a tela"); return
	t.equal(positions.slots("qb"), 1, "o QB é uma vaga")
	t.check(not _texts(screen).contains(UiText.t("team.reserves") % 1), "reserva antes da hora")

	var qbs: Array = _tagged(screen, "role", "qb")
	t.check(qbs.size() >= 2, "preciso de dois atletas para testar")
	(qbs[0] as Button).pressed.emit()
	t.check(not _texts(screen).contains(UiText.t("team.reserves") % 1),
		"o primeiro QB deveria ser titular, não reserva")
	(_tagged(screen, "role", "qb")[1] as Button).pressed.emit()
	t.check(_texts(screen).contains(UiText.t("team.reserves") % 1),
		"o segundo QB deveria virar reserva")
	_close(screen)

# A rolled thirty-year-old has a decade of seasons behind him and the sheet used
# to show none of it — no way to tell a veteran QB from a kid who throws.
func test_the_card_shows_the_career(t: TestHelper) -> void:
	var screen: Control = _open()
	if screen == null:
		t.fail("não consegui instanciar a tela"); return
	var rosters := The.board.get("rosters", null) as Rosters
	var veteran: Actor = null
	for person: Actor in rosters.squad("flag_kings", Actor.CATEGORY_MASC):
		if person.career_years() >= 4 and (veteran == null
				or person.career_years() > veteran.career_years()):
			veteran = person
	if veteran == null:
		t.fail("ninguém no elenco tem carreira registrada"); _close(screen); return
	t.check(veteran.career().size() == veteran.career_years(),
		"o log tem %d temporadas para %d anos de carreira" % [
			veteran.career().size(), veteran.career_years()])

	var row: Button = _row_named(screen, veteran.display_name())
	if row == null:
		t.fail("não achei a linha do veterano"); _close(screen); return
	row.pressed.emit()
	var shown: String = _texts(screen)
	t.check(shown.contains(UiText.t("team.career") % veteran.career_years()),
		"o card não mostra os anos de carreira")
	# Every season is a line, and the age it happened at is on it.
	for entry: Variant in veteran.career():
		t.check(shown.contains(str(int((entry as Dictionary).get("age", 0)))),
			"temporada dos %d anos não aparece" % int((entry as Dictionary).get("age", 0)))
	_close(screen)
