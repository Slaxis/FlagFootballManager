# Fit check — does every screen fit on the screen?
#
#   godot --headless --path . res://tests/fit_check.tscn
#
# The fourth harness, and it exists for the same reason quit_check does: the
# unit runner cannot see this. A screen's real size only settles after a LAYOUT
# PASS, and `get_combined_minimum_size()` read in the same frame a Control was
# added reports nonsense — an autowrapping Label does not know its own width
# yet, so it reports the height it would need at its minimum width. The creation
# form measured 7562px that way and 1051px one frame later.
#
# The runner calls each test synchronously inside one frame and cannot await, so
# this is a scene with its own `_ready` that can wait as long as it likes.
#
# WHY IT IS WORTH A HARNESS. The creation form shipped at 1743px against a 1080
# viewport, in a 940px column, with two thirds of the monitor empty beside it —
# and nothing about that looks wrong in a screenshot or in a passing test. It
# reads as "the screen is a bit long". Every row added from here on pushes at
# the same ceiling, silently.
extends Node

# The resolution the screens are laid out for. One source of truth with the
# runtime, so raising one cannot quietly leave the other behind.
var VIEWPORT := Vector2(Look.DESIGN_MIN)
# A screen that fits by using a third of the monitor is the old problem wearing
# different trousers, so there is a floor as well as a ceiling.
const MIN_WIDTH_USE := 0.6

var _failures: Array[String] = []

func _ready() -> void:
	var modules: Array[ModuleInfo] = Drive.list_modules()
	if modules.is_empty() or not Drive.set_module(modules[0].id):
		print("X nenhum módulo ativo")
		get_tree().quit(1)
		return
	await get_tree().process_frame
	_seed_board()

	await _check("create_manager", "res://game/scene/create_manager/create_manager.tscn")
	await _check("draft", "res://game/scene/draft/draft.tscn")
	await _check("team", "res://game/scene/team/team.tscn")
	await _check_steady()

	print("\n———————————————————————")
	if _failures.is_empty():
		print("todas as telas cabem em %.0fx%.0f" % [VIEWPORT.x, VIEWPORT.y])
		get_tree().quit(0)
		return
	print("%d tela(s) não cabem:" % _failures.size())
	for line: String in _failures:
		print("  - " + line)
	get_tree().quit(1)

# A career and a built world, so the team screen has something to draw and does
# not spend nine seconds building a league inside a layout check.
func _seed_board() -> void:
	var seed_value: int = 20260420
	League.ensure_filled(seed_value)
	var builder: SheetBuilder = SheetBuilder.rolled_opening(
		SeedRng.make_rng(seed_value), "player")
	var manager: Actor = builder.to_actor(seed_value, {
		"first_name": "Medida", "last_name": "Da Tela", "nickname": "Régua"})
	manager.set_plays([Actor.CATEGORY_MASC])
	manager.set_manages([Actor.CATEGORY_MASC])
	manager.set_team("flag_kings")
	The.board["career"] = Career.make(manager, "flag_kings", seed_value)
	var rosters: Rosters = Rosters.make(seed_value)
	var praca: Praca = Praca.make(seed_value)
	rosters.add("flag_kings", Actor.CATEGORY_MASC, manager)
	LeagueGenerator.fill(rosters, praca, Actor.CATEGORY_MASC)
	The.board["rosters"] = rosters
	The.board["praca"] = praca

# AND THE FRAME MUST NOT MOVE WHEN THE SCENARIO DOES. The Fundador carries a
# club block the other two do not, so the panel grew and shrank as you clicked
# between them and the whole screen jumped under the cursor — which is worst
# exactly when you are trying to compare the three.
func _check_steady() -> void:
	var packed: PackedScene = load(
		"res://game/scene/create_manager/create_manager.tscn") as PackedScene
	var screen: Control = packed.instantiate() as Control
	get_tree().root.add_child(screen)
	await get_tree().process_frame
	await get_tree().process_frame
	var origins := Drive.def("origin") as OriginDef
	var sizes: Dictionary = {}
	for id: String in (origins.origin_ids() if origins != null else []):
		screen.call("_on_origin", id)
		await get_tree().process_frame
		await get_tree().process_frame
		var panel: Control = _panel(screen)
		sizes[id] = panel.get_combined_minimum_size() if panel != null else Vector2.ZERO
	var first: Vector2 = Vector2.ZERO
	var moved: bool = false
	for id: String in sizes.keys():
		if first == Vector2.ZERO:
			first = sizes[id]
		elif sizes[id] != first:
			moved = true
	if moved:
		var report: Array[String] = []
		for id: String in sizes.keys():
			report.append("%s %.0fx%.0f" % [id, (sizes[id] as Vector2).x, (sizes[id] as Vector2).y])
		_failures.append("o painel muda de tamanho entre cenários: " + ", ".join(report))
	print("%-16s %5.0f x %5.0f   %s" % ["cenários", first.x, first.y,
		"MUDA" if moved else "estável"])
	screen.get_parent().remove_child(screen)
	screen.queue_free()

func _check(label: String, path: String) -> void:
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		_failures.append("%s: não carregou" % label)
		return
	var screen: Control = packed.instantiate() as Control
	get_tree().root.add_child(screen)
	# No `screen.size =` here: these screens anchor to the full rect, so the
	# viewport already sizes them and assigning it fights the anchors.
	# Two frames: one for the tree to settle, one for the containers to size
	# their children now that the widths are known.
	await get_tree().process_frame
	await get_tree().process_frame

	var panel: Control = _panel(screen)
	if panel == null:
		_failures.append("%s: nenhum nó marcado com set_meta(\"fit_root\")" % label)
		screen.get_parent().remove_child(screen)
		screen.queue_free()
		return
	var need: Vector2 = panel.get_combined_minimum_size()
	var verdict: String = "ok"
	if need.y > VIEWPORT.y:
		verdict = "ALTA"
		_failures.append("%s pede %.0fpx de altura (tela tem %.0f)" % [label, need.y, VIEWPORT.y])
	elif need.x > VIEWPORT.x:
		verdict = "LARGA"
		_failures.append("%s pede %.0fpx de largura (tela tem %.0f)" % [label, need.x, VIEWPORT.x])
	elif need.x < VIEWPORT.x * MIN_WIDTH_USE:
		verdict = "ESTREITA"
		_failures.append("%s usa só %.0f de %.0f de largura" % [label, need.x, VIEWPORT.x])
	var burst: Array[String] = []
	_overflows(screen, burst, "")
	if not burst.is_empty():
		verdict = "ESTOURA"
		for line: String in burst:
			_failures.append("%s: %s" % [label, line])
	print("%-16s %5.0f x %5.0f   %s" % [label, need.x, need.y, verdict])
	for line: String in burst:
		print("                 %s" % line)

	screen.get_parent().remove_child(screen)
	screen.queue_free()

# THE SCREEN SAYS WHICH NODE HAS TO FIT, via a `fit_root` meta. Guessing was
# wrong twice: the first version fell back to `node as Control` at every level
# and handed back the background ColorRect (0x0, "too narrow"); the second took
# the first PanelContainer and found the team screen's club-colour plate, which
# is 148px of badge. And there is no generic answer — a ScrollContainer reports
# a tiny minimum BY DESIGN, so measuring the outermost container would hide the
# exact problem this file exists to catch.
#
# ⚠️ Returns NULL when nothing is tagged, which fails the screen loudly. A new
# screen opts in, and one that forgot is told so rather than silently passing.
func _panel(node: Node) -> Control:
	if node.has_meta("fit_root"):
		return node as Control
	for child: Node in node.get_children():
		var found: Control = _panel(child)
		if found != null:
			return found
	return null


# ⚠️ NOTHING INSIDE A CELL MAY BE WIDER THAN THE CELL, and this is that rule as a
# measurement rather than as a note in a comment.
#
# It has now caused the same bug twice in the same file. The creation form was
# rebuilt as a 2x2 to be MORE compact and came out 500px wider, because three of
# its children were still sized against the whole column; and the pass after that
# was held 66px wide by one row of three scenario chips. In both cases the screen
# still "fitted", the totals still passed, and the only visible symptom was that
# the panel was bigger than it had any reason to be.
#
# A Control that DECLARES a minimum is making a promise about how much room it
# needs. When its combined minimum exceeds its own declaration, something inside
# it broke that promise, and the container above obligingly grew to cover for it
# — which is why this is invisible from the outside and obvious from here.
#
# It names the offender's ancestry rather than its node name, because these
# screens build their controls in code and the names are all `@VBoxContainer@41`.
const OVERFLOW_SLACK := 0.5

func _overflows(node: Node, into: Array[String], path: String) -> void:
	if node is Control:
		var control := node as Control
		var wants: float = control.get_combined_minimum_size().x
		var said: float = control.custom_minimum_size.x
		if said > 0.0 and wants > said + OVERFLOW_SLACK:
			into.append("%s pede %.0fpx e declarou %.0f   %s" % [
				node.get_class(), wants, said, path])
	for child: Node in node.get_children():
		_overflows(child, into, path + "/" + child.get_class())
