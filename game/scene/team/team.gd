# Team Screen — your club, and the first place the model becomes visible.
#
# `A.2` and `A.3` shipped ~700 lines of attributes, skills and actors and zero
# pixels. This is where that debt is paid: a roster you can read, and a full
# sheet one click away. Everything the creation screen taught you to read about
# yourself, now about twelve other people.
#
# Lives in `game/scene/` and not inside a module, like the start screen: every
# universe has clubs and rosters, so this is chrome. A module that ships its own
# league inherits the screen for free (PathManager rule R5 — active module
# first, then the game-level shell).
#
# Two tabs now, and the bar grows as Fase D lands the others.
extends Menu

# THE SCREEN WEARS THE CLUB. Background and lettering come from the club's own
# two colours, the way Elifoot did it — so when two managers share a screen,
# whose turn it is is a glance and not a label.
#
# TeamColors already guarantees the pair clears WCAG contrast, so plate/ink is
# readable by construction. The background is darkened from the plate because a
# full screen of a club's yellow is a different thing from a badge of it, and
# everything else (panels, rules, muted text) is derived from those two so the
# palette can never drift out of the club's identity.
# ⚠️ THE DEFAULTS COME FROM `Look` NOW. These were hand-written GREEN —
# Elifoot's green, kept alive here long after decision 62 took it off the
# palette. It never showed, because `_wear_club_colours()` overwrites every one
# of them a frame later, so the file sat asserting something false for months.
var CANVAS := Look.CANVAS
var PANEL := Look.PANEL
var ACCENT := Look.ACCENT
var MUTED := Look.MUTED
var INK := Look.INK
var LINE := Look.LINE
# The two the widgets used to hardcode: the ground inside a control, and the
# ink that goes ON the accent when a control is filled with it. Derived like
# everything else, so a yellow club gets a yellow-black and not a green one.
var WELL := Look.WELL
var ON_ACCENT := Look.ON_ACCENT

func _wear_club_colours() -> void:
	# ⚠️ THE CLUB COLOURS THE BADGE AND THE SELECTION, NOT THE MONITOR.
	#
	# This used to set the page to the club's own background and derive every
	# panel, well and rule from it, so there was no square of this screen that
	# was not the club — and the card you open on a player draws eight attributes
	# in eight CHAKRA hues with nothing to contrast against. A yellow club made
	# its own sheet unreadable, and it was nobody's bug: every single colour was
	# the one the player picked.
	#
	# The page is black now. The club arrives as the badge (which still carries
	# its real background, up in `_header()`), as the frame of every window, and
	# as the fill of whatever is SELECTED — which is more of the club than a wall
	# of it was, because now you can see where it is.
	var scheme: Dictionary = Look.club_scheme(_viewed_club())
	CANVAS = scheme["canvas"]
	PANEL = Look.PANEL
	WELL = Look.WELL
	ACCENT = scheme["signal"]
	INK = scheme["canvas_ink"]
	MUTED = scheme["canvas_muted"]
	LINE = ACCENT.lerp(CANVAS, 0.6)
	ON_ACCENT = CANVAS

const TAB_SQUAD := "squad"
const TAB_RIVALS := "rivals"

const SORT_NAME := "name"
const SORT_SHIRT := "shirt"
const SORT_PERK := "perk"
const SORT_STRENGTH := "strength"
const SORT_AGE := "age"

# Column widths live here and nowhere else: the group header above and the
# sortable header below are both derived from them, so they cannot drift apart.
# ⚠️ MEASURED AGAINST THEIR OWN HEADINGS, which three of them were not. The body
# face is monospaced at 12px a character, so "Talento" is 84px and "Idade" and
# "Geral" are 60 — plus a character for the sort arrow. Against COL_PERK 34,
# COL_AGE 48 and COL_STRENGTH 58, all three headings were cropped, and a cropped
# heading is the one cell in a table that cannot be read from context.
#
# It was invisible because the WIDEST thing in each of those columns is the
# heading, not the data: two digits of age need 24px, so the column looked
# comfortable from every row except the one that names it.
const HEAD_CHAR := 12
const COL_MARK := 18
const COL_NAME := 204
const COL_SHIRT := 156
# What is left of the shirt once " #99" has had its four characters.
const NICK_WIDTH := 108
const COL_PERK := 96
const COL_STRENGTH := 72
const COL_AGE := 72
const COL_ROLE := 36
const COL_GAP := 5
# The three-letter code column on the athlete card.
const CARD_CODE := 52
# ⚠️ MEASURED, NOT ESTIMATED. Four columns of a code and a ten-slot bar come to
# 806 on paper, and the card asks for 1064 — the difference is the header and
# the career log underneath, which are as much part of the card as the columns
# are. 880 was the arithmetic and it was wrong by a quarter.
const CARD_WIDTH := 1064
# Mark, name, shirt, talent, Geral, age.
const PROFILE_COLUMNS := 6
# Hairlines are counted by `_column_plan`, not declared — see the warning there.

# ⚠️ THE ROLE COLUMNS ARE THE BUDGET. There are EIGHTEEN of them — three
# administration chairs, five on the technical staff and ten in the formation —
# so every pixel added here is multiplied by eighteen and the table stops fitting
# beside the lineup panel. They were briefly squeezed to 22px with the codes at
# the 9px rung, back when the canvas was 1280 wide; at one-to-one on a 1440p
# monitor there is room for them to be clickable again.
#
# Everything is derived in one place: the group header above and the sortable
# header below both read these, so they cannot drift apart.

# Measured fits run from about 2% to 88%, so a fit IS the percentage — no
# scaling. A box filled a third of the way means a third of the way.
const SIDES_IN_LINEUP: Array[String] = ["offense", "defense"]

const _TIER_COLOR: Dictionary = {
	1: Color(0.95, 0.82, 0.35),
	2: Color(0.75, 0.78, 0.82),
	3: Color(0.72, 0.52, 0.36),
	4: Color(0.45, 0.47, 0.45),
}

var _tab: String = TAB_SQUAD
# Which club the Elenco tab is showing. Empty means your own — clicking a
# rival points it somewhere else, which is the cheapest possible scouting and
# the reason the tab is a view and not a fixed page.
var _viewing: String = ""
var _selected: Actor = null
# Which column the roster is ordered by, and which way. Sorting a roster is
# how a manager actually reads it: who is oldest, who is best, who can play
# corner.
# Green is a talent, red is a disadvantage, and both are FIXED — they read the
# same against every club's kit, so a liability never disguises itself as a
# strength because the shirt happened to be red.
const TALENT_GOOD := Color(0.42, 0.78, 0.45)
const TALENT_BAD := Color(0.85, 0.36, 0.36)

# The best fit at each position among the people currently shown, so every
# column is scaled to its own column.
var _fit_ceilings: Dictionary = {}
# The Geral span of whoever is on screen, so the colour ramp covers the numbers
# that exist instead of the numbers the scale allows.
var _worst_overall: int = 0
var _best_overall: int = 0

var _sort_key: String = SORT_STRENGTH
var _sort_desc: bool = true
var _root: VBoxContainer = null

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Look.fit_window()
	_wear_club_colours()
	var bg := ColorRect.new()
	bg.color = CANVAS
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	add_child(margin)

	_root = VBoxContainer.new()
	_root.add_theme_constant_override("separation", 10)
	# Tagged for tests/fit_check.tscn: THIS is the node that has to fit on the
	# screen. The check cannot guess it — a ScrollContainer reports a tiny
	# minimum by design, so measuring the outermost thing would hide exactly the
	# problem the check exists to catch.
	_root.set_meta("fit_root", true)
	margin.add_child(_root)
	_build_ui()

func _build_ui() -> void:
	# Re-read every rebuild: looking at a rival puts you in THEIR colours, which
	# is the cheapest possible "you are away from home".
	_wear_club_colours()
	for child: Node in get_children():
		if child is ColorRect and not child.has_meta("card_layer"):
			(child as ColorRect).color = CANVAS
	Look.clear(_root)
	# The card is a sibling of the layout and not a child of it, so clearing
	# `_root` does not clear the card. Without this every click stacked another
	# one on top of the last and the screen slowly filled with dead sheets.
	for child: Node in get_children():
		if child.has_meta("card_layer"):
			remove_child(child)
			if child is CanvasItem:
				(child as CanvasItem).visible = false
			get_tree().root.add_child(child)
			child.queue_free()
	_root.add_child(_header())
	_root.add_child(_tab_bar())
	_root.add_child(_rule())
	if _tab == TAB_SQUAD:
		_root.add_child(_squad_tab())
	else:
		_root.add_child(_rivals_tab())
	# The card floats over everything rather than living in a column. A sheet is
	# twenty-three rows plus a career, and squeezed into a side panel it came
	# out as a long ribbon nobody could read at a glance.
	if _selected != null:
		_show_card()

# --- Chrome ---

func _career() -> Career:
	return read("career") as Career

func _rosters() -> Rosters:
	var existing := read("rosters") as Rosters
	if existing != null:
		return existing
	# THE DRAFT SCREEN BUILDS THE WORLD. It gets here already built, with a bar
	# and a log the player watched — two hundred lived careers is about nine
	# seconds, and doing that inside this `_ready` was nine seconds of a window
	# that looked hung.
	#
	# This branch is the fallback for arriving without passing through it: a
	# test mounting the scene on its own, or a save restored straight into the
	# squad. It costs the same nine seconds, silently, which is exactly why it
	# is not the normal path.
	var career: Career = _career()
	var seed_value: int = career.career_seed if career != null else 0
	var fresh: Rosters = Rosters.make(seed_value)
	var praca: Praca = Praca.make(seed_value)
	if career != null and career.manager != null:
		var mine: Array = career.manager.plays()
		if mine.is_empty():
			mine = [Actor.CATEGORY_MASC]
		for entry: Variant in mine:
			fresh.add(career.team_id, String(entry), career.manager)
	LeagueGenerator.fill(fresh, praca, Actor.CATEGORY_MASC)
	write("rosters", fresh)
	write("praca", praca)
	return fresh

# Which squad the Elenco tab is showing. Your own category when you play one,
# otherwise whatever the club actually fields.
func _viewed_id() -> String:
	if _viewing != "":
		return _viewing
	var career: Career = _career()
	return career.team_id if career != null else ""

func _viewed_club() -> Dictionary:
	var teams := Drive.def("team") as TeamDef
	return teams.get_team(_viewed_id()) if teams != null else {}

func _own_id() -> String:
	var career: Career = _career()
	return career.team_id if career != null else ""

func _category() -> String:
	var career: Career = _career()
	var club: Dictionary = _viewed_club()
	var squads: Dictionary = club.get("squads", {})
	if career != null and career.manager != null:
		for id: Variant in career.manager.plays():
			if bool(squads.get(String(id), false)):
				return String(id)
	for id: String in squads.keys():
		if bool(squads[id]):
			return id
	return Actor.CATEGORY_MASC

func _header() -> Control:
	var club: Dictionary = _viewed_club()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)

	var scheme: Dictionary = TeamColors.of(club)
	var style := StyleBoxFlat.new()
	style.bg_color = scheme["plate"]
	style.set_content_margin_all(10)
	for corner: String in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		style.set("corner_radius_" + corner, 4)
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", style)
	var name_label := Label.new()
	name_label.text = String(club.get("name", "?"))
	name_label.add_theme_color_override("font_color", scheme["ink"])
	Look.wear_display(name_label, Look.PLATE)
	plate.add_child(name_label)
	row.add_child(plate)

	var where := Label.new()
	var teams := Drive.def("team") as TeamDef
	where.text = "%s/%s   ·   %s" % [
		teams.where(club) if teams != null else club.get("city", "?"),
		club.get("state", "?"),
		UiText.t("tier.%d" % int(club.get("tier", 4)))]
	where.add_theme_color_override("font_color", MUTED)
	where.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	where.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(where)

	# YOUR THREE CURRENCIES, beside the week they are spent in. Nothing spends
	# them until `C.1`, and showing them now is not decoration: they come off the
	# sheet you filled in on the creation screen, and this is the first screen
	# that tells you what that sheet BOUGHT.
	var career: Career = _career()
	if career != null and career.manager != null:
		for id: String in Influence.ALL:
			row.add_child(_influence_chip(career.manager, id))

	# Fixed text until C.5 makes the calendar move. Showing it now is how the
	# screen says where the week is going to live.
	var week := Label.new()
	week.text = UiText.t("team.week") % [1, 2026]
	week.add_theme_color_override("font_color", MUTED)
	week.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(week)
	return row

func _influence_chip(manager: Actor, id: String) -> Control:
	var purse: Dictionary = Influence.of(manager).get(id, {})
	var held: int = int(purse.get("held", 0))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.tooltip_text = "%s\n\n%s\n\n%s" % [
		UiText.t("influence." + id + ".name"), UiText.t("influence." + id + ".desc"),
		UiText.t("influence.held") % [held, int(purse.get("cap", 0)),
			int(purse.get("income", 0))]]
	box.mouse_filter = Control.MOUSE_FILTER_STOP

	var caption := Label.new()
	caption.text = UiText.t("influence." + id)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_color_override("font_color", MUTED)
	Look.wear_body(caption, Look.TEXT)
	box.add_child(caption)

	var value := Label.new()
	value.text = str(held)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.add_theme_color_override("font_color", ACCENT if held > 0 else MUTED)
	Look.wear_display(value, Look.HEADING)
	box.add_child(value)
	return box

func _tab_bar() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	for pair: Array in [[TAB_SQUAD, "team.squad"], [TAB_RIVALS, "team.rivals"]]:
		row.add_child(_tab_button(UiText.t(String(pair[1])), String(pair[0])))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	if _viewing != "" and _viewing != _own_id():
		row.add_child(_flat_button(UiText.t("team.back_to_mine"), _on_view_mine))
	row.add_child(_flat_button(UiText.t("common.back"), func() -> void: go("back")))
	return row

# --- Elenco ---

func _squad_tab() -> Control:
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 18)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var people: Array[Actor] = _sorted(_rosters().squad(_viewed_id(), _category()))
	_measure_fit_ceilings(people)

	# ESCALAÇÃO ON THE LEFT, table on the right. You read left to right, and the
	# question you arrive with is "who is on my team and what is still empty" —
	# the answer to that is the panel, so it goes first. The table is what you
	# reach for to change the answer, which is a second move.
	columns.add_child(_lineup_panel(people))
	columns.add_child(_roster_table(people))
	return columns

# ⚠️ ONE GRID, HEADER INCLUDED. The header and the rows used to be separate
# HBoxContainers that agreed about widths by being written from the same
# constants — and agreed about nothing else. The header separated its cells by
# COL_GAP and the rows by 8, so every column drifted two pixels and by the
# twenty-fourth the header was forty-eight pixels off the boxes it named. That
# had been "fixed" once already, by clipping a heading that was growing past its
# minimum; the widths were never the problem, the arrangement was.
#
# A GridContainer sizes each column to the widest cell IN THAT COLUMN, header
# and rows alike, because they are the same container. Alignment stops being
# something to get right and becomes something that cannot go wrong.
#
# It costs the row-as-a-Button: a grid has cells, not rows. So selection and the
# zebra stripe are painted per cell (`_shell`), and the name cell is the one you
# click — which is the ordinary table idiom anyway, and honest about the fact
# that the position boxes were never part of "click the row" either.
func _roster_table(people: Array[Actor]) -> Control:
	var positions := Drive.def("position") as PositionDef
	var career: Career = _career()
	var manager_id: String = career.manager.thing_id if career != null and career.manager != null else ""

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = _table_columns(positions)
	grid.add_theme_constant_override("h_separation", COL_GAP)
	grid.add_theme_constant_override("v_separation", 2)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)

	_fill_header(grid, positions)
	var index: int = 0
	for person: Actor in people:
		_fill_row(grid, person, positions, person.thing_id == manager_id, index)
		index += 1
	return box

# ⚠️ THE COLUMN PLAN IS ONE LIST, and the header and the rows both walk it.
#
# The first attempt counted the hairlines by hand — three, one per boundary —
# and emitted them from a loop that produced two, because offence and defence
# share a block. So the grid was told twenty-seven columns while each row filled
# twenty-six, and every row after the first slid one cell left: the table came
# out 5706px wide and nothing lined up with anything.
#
# That is the SAME class of bug the grid was brought in to kill, one level up.
# The fix is the same shape too: not "count more carefully" but "have one source
# and make both readers use it".
func _column_plan(positions: PositionDef) -> Array:
	var plan: Array = []
	if positions == null:
		return plan
	# A hairline between who you are and what you can do.
	plan.append({"rule": true})
	var side_of: String = ""
	for id: String in _role_order(positions):
		var side: String = positions.side(id)
		if side_of != "" and side != side_of and not _same_block(side_of, side):
			plan.append({"rule": true})
		side_of = side
		plan.append({"role": id})
	return plan

func _table_columns(positions: PositionDef) -> int:
	return PROFILE_COLUMNS + _column_plan(positions).size()

# ⚠️ ONE LIST, TWO READERS — the same lesson `_column_plan` learned for the
# eighteen role columns, applied to the six that come before them. The header
# spelled its cells out and `_fill_row` spelled the same six out again in the
# same order, which is an ordering maintained by hand in two places: reordering
# them meant editing both, and editing one is a table that slides by a column.
const PROFILE_PLAN: Array[Dictionary] = [
	{"kind": "mark", "sort": "", "width": COL_MARK},
	{"kind": "name", "sort": SORT_NAME, "head": "team.name", "width": COL_NAME},
	{"kind": "talent", "sort": SORT_PERK, "head": "team.talent", "width": COL_PERK},
	{"kind": "age", "sort": SORT_AGE, "head": "team.age", "width": COL_AGE},
	{"kind": "strength", "sort": SORT_STRENGTH, "head": "team.strength", "width": COL_STRENGTH},
	{"kind": "shirt", "sort": SORT_SHIRT, "head": "team.shirt", "width": COL_SHIRT},
]

func _fill_header(grid: GridContainer, positions: PositionDef) -> void:
	for step: Dictionary in PROFILE_PLAN:
		if not step.has("head"):
			grid.add_child(_spacer_cell(int(step["width"])))
			continue
		grid.add_child(_heading(UiText.t(String(step["head"])),
			String(step["sort"]), int(step["width"])))
	# The group NAMES are gone. Three words spanning eighteen columns cannot be
	# expressed in a grid without a span, and they were not earning the row: the
	# codes are unambiguous, the hairlines mark the boundaries, and the panel on
	# the left already says Administração / Comissão / Escalação over the actual
	# assignments. Each heading carries its group on the tooltip.
	for step: Dictionary in _column_plan(positions):
		if step.has("rule"):
			grid.add_child(_rule_cell())
			continue
		var id: String = String(step["role"])
		grid.add_child(_heading(positions.code(id), "fit:" + id, COL_ROLE))

func _profile_cell(person: Actor, kind: String, chosen: bool, is_manager: bool) -> Control:
	match kind:
		"mark":
			return _cell("\u2605" if is_manager else "", COL_MARK,
				ACCENT if is_manager else MUTED)
		"name":
			return _name_button(person, chosen)
		"talent":
			return _talent_mark(person)
		"age":
			# THE SAME RAMP AS GERAL, ASKING A DIFFERENT QUESTION. Geral runs
			# low-to-high because more is better; age does not — twenty is not
			# worse than thirty, it is earlier — so the heat peaks in the middle
			# and falls off both ways. The squad reads as a map of who is ready
			# NOW, which is the question a roster is for.
			return _cell(str(person.age()), COL_AGE,
				StatBar.tint(ActorLife.prime_heat(person.age()), ACCENT))
		"strength":
			# Elifoot calls this Geral and so does this column: one number for
			# how good somebody is, tinted so the roster reads before it is read.
			# ⚠️ TINTED AGAINST THE SQUAD, NOT AGAINST 0..100. Geral at this tier
			# runs from about 14 to 30, so a ramp calibrated on a hundred put
			# every number fourteen to thirty per cent of the way from grey to
			# the club's colour — which is to say grey.
			return _cell(str(person.overall()), COL_STRENGTH,
				StatBar.tint(_in_squad(person.overall()), ACCENT))
		"shirt":
			return _shirt_cell(person)
	return _spacer_cell(0)

# Offence and defence are one block on this screen: they are the side that takes
# the field, and a hairline between them would say they are different kinds of
# thing.
func _same_block(a: String, b: String) -> bool:
	return SIDES_IN_LINEUP.has(a) and SIDES_IN_LINEUP.has(b)

# ⚠️ EVERY CELL SAYS WHICH ROW AND WHICH COLUMN IT IS. A grid has neither — it
# has a flat list of children — so anything that wants to read "this person's
# age" has to be told, and the two metas are that telling. Without them the only
# way back to a row is counting children, which is the arithmetic this whole
# rewrite exists to stop doing.
func _fill_row(grid: GridContainer, person: Actor, positions: PositionDef,
		is_manager: bool, index: int) -> void:
	var chosen: bool = _selected != null and _selected.thing_id == person.thing_id
	for step: Dictionary in PROFILE_PLAN:
		var kind: String = String(step["kind"])
		_put(grid, person, kind, _profile_cell(person, kind, chosen, is_manager),
			chosen, index)
	for step: Dictionary in _column_plan(positions):
		if step.has("rule"):
			grid.add_child(_rule_cell())
			continue
		var id: String = String(step["role"])
		_put(grid, person, "fit:" + id, _position_button(person, positions, id,
			float(_fit_ceilings.get(id, 1.0))), chosen, index)

# THE ROW BACKGROUND, one cell at a time. A grid cannot paint a row, so the row
# paints itself — and since every cell is wrapped anyway, the odd ones get a
# shade for free. Zebra is not decoration in a table twenty-seven columns wide:
# it is the only thing keeping your eye on the line it started on.
func _put(grid: GridContainer, person: Actor, kind: String, inner: Control,
		chosen: bool, index: int) -> void:
	var shell: Control = _shell(inner, chosen, index)
	shell.set_meta("row_of", person.thing_id)
	shell.set_meta("cell", kind)
	grid.add_child(shell)

func _shell(inner: Control, chosen: bool, index: int) -> Control:
	var shell := PanelContainer.new()
	var style := StyleBoxFlat.new()
	if chosen:
		style.bg_color = LINE.lightened(0.05)
		style.border_color = ACCENT
		style.set_border_width_all(1)
	else:
		style.bg_color = WELL.lightened(0.05) if index % 2 == 1 else WELL
	style.set_content_margin_all(2)
	shell.add_theme_stylebox_override("panel", style)
	shell.add_child(inner)
	return shell

# The name is the click target. A grid has no row to press, and pressing a name
# to open a record is what a table does everywhere else anyway.
func _name_button(person: Actor, chosen: bool) -> Button:
	var button := Button.new()
	button.set_meta("roster_row", true)
	button.text = person.full_name()
	button.clip_text = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(COL_NAME, 22)
	button.focus_mode = Control.FOCUS_NONE
	Look.wear_body(button, Look.TEXT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.set_content_margin_all(0)
	for state: String in ["normal", "hover", "pressed"]:
		button.add_theme_stylebox_override(state, style)
	button.add_theme_color_override("font_color", ACCENT if chosen else INK)
	button.add_theme_color_override("font_hover_color", ACCENT)
	button.tooltip_text = UiText.t("team.open_sheet") % person.display_name()
	button.pressed.connect(_on_pick.bind(person))
	return button

# Lineup first, then the staff chairs — the same order the rows use, because a
# header that does not line up with its column is worse than no header.
# Administration, then the coaching staff, then who takes the field — the order
# a club is actually built in. Somebody has to answer for the place before
# anybody picks a quarterback.
# ⚠️ NO COLUMN FOR THE PRESIDENCY. Every cell in it said the same thing — you,
# and only you — because you do not appoint yourself, you already are it
# (decision 72). A column whose every value is known before you open the screen
# is 96px of table and forty cells of nothing, and it made the one genuinely
# fixed chair look like a choice you had already made.
#
# The star in the first column already says which row is yours.
func _role_order(positions: PositionDef) -> Array[String]:
	var out: Array[String] = []
	for id: String in positions.ids_on_side("admin"):
		if id != OriginDef.CHAIR_OF_THE_CLUB:
			out.append(id)
	out.append_array(positions.ids_on_side("staff"))
	for side: String in SIDES_IN_LINEUP:
		out.append_array(positions.ids_on_side(side))
	return out

func _spacer_cell(width: int) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(width, 0)
	return spacer

# A header is a button. The arrow says which way, and clicking the column you
# are already on flips it.
func _heading(text: String, key: String, width: int) -> Button:
	var button := Button.new()
	var active: bool = _sort_key == key
	button.text = text + ("  \u25be" if active and _sort_desc else ("  \u25b4" if active else ""))
	button.custom_minimum_size = Vector2(width, 20)
	# A Button grows past its minimum when the text does not fit, so "Talento"
	# at forty-five pixels was shoving a thirty-pixel column — and every column
	# to its right with it. The boxes were always right; the header was the one
	# sliding.
	button.clip_text = true
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = UiText.t("team.sort_by") % text
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.set_content_margin_all(0)
	for state: String in ["normal", "hover", "pressed"]:
		button.add_theme_stylebox_override(state, style)
	Look.wear_body(button, Look.TEXT)
	button.add_theme_color_override("font_color", ACCENT if active else MUTED)
	button.add_theme_color_override("font_hover_color", INK)
	button.pressed.connect(_on_sort.bind(key))
	return button

# A hairline between one side of the club and the next.
func _rule_cell() -> Control:
	var rule := ColorRect.new()
	rule.color = LINE
	rule.custom_minimum_size = Vector2(1, 0)
	rule.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rule

# --- The lineup ---

# Who is where, with the empty slots drawn as empty. Everybody marked past a
# position's slots is a RESERVE there, not a mistake: two quarterbacks is how a
# coach finds out which one is better, and most weeks the event is the coletivo
# where both take snaps.
func _lineup_panel(people: Array[Actor]) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	panel.custom_minimum_size = Vector2(310, 0)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)

	var positions := Drive.def("position") as PositionDef
	if positions == null:
		return panel
	var assigned: Dictionary = _assignment(people, positions)

	box.add_child(_panel_title(UiText.t("team.admin"), "", UiText.t("team.admin_hint")))
	for id: String in positions.ids_on_side("admin"):
		var chairs: Array = assigned.get(id, [])
		box.add_child(_slot_row(positions.code(id),
			chairs[0] if not chairs.is_empty() else null))
	box.add_child(_unit_caption(UiText.t("team.staff"),
		_unit_overall(assigned, positions, "staff")))
	for id: String in positions.ids_on_side("staff"):
		var chairs: Array = assigned.get(id, [])
		box.add_child(_slot_row(positions.code(id),
			chairs[0] if not chairs.is_empty() else null))
	var short: bool = _squad_is_short(people, positions)
	box.add_child(_panel_title(UiText.t("team.lineup"), _squad_note(people, positions),
		UiText.t("team.below_minimum") % positions.squad_minimum if short
			else UiText.t("team.lineup_hint"), short))
	var reserves: Array = []
	for side: String in SIDES_IN_LINEUP:
		box.add_child(_unit_caption(UiText.t("team.side_" + side),
			_unit_overall(assigned, positions, side)))
		for id: String in positions.ids_on_side(side):
			var picked: Array = assigned.get(id, [])
			for slot: int in range(positions.slots(id)):
				var who: Actor = picked[slot] if slot < picked.size() else null
				box.add_child(_slot_row(positions.code(id) if slot == 0 else "", who))
			for extra: int in range(positions.slots(id), picked.size()):
				reserves.append({"position": id, "actor": picked[extra]})

	if not reserves.is_empty():
		box.add_child(_group_caption(UiText.t("team.reserves") % reserves.size()))
		for entry: Dictionary in reserves:
			box.add_child(_slot_row(positions.code(String(entry["position"])),
				entry["actor"] as Actor))

	return panel

# Best Forca first, so the starter is the starter and the rest are depth.
func _assignment(people: Array[Actor], positions: PositionDef) -> Dictionary:
	var out: Dictionary = {}
	for id: String in positions.position_ids():
		var picked: Array[Actor] = []
		for person: Actor in people:
			if person.plays_position(id):
				picked.append(person)
		picked.sort_custom(func(a: Actor, b: Actor) -> bool:
			return a.overall() > b.overall())
		out[id] = picked
	return out

# The competition wants seven names on the sheet and twelve is the usual, so the
# header says where this squad stands against both.
func _squad_note(people: Array[Actor], positions: PositionDef) -> String:
	var marked: int = 0
	for person: Actor in people:
		if not person.lineup().is_empty():
			marked += 1
	# JUST THE NUMBERS. "abaixo do mínimo" is four more words of explanation in a
	# three-hundred-pixel column, and it was widening the whole panel to say what
	# the colour beside it already says — the sentence is on the tooltip.
	return UiText.t("team.registered") % [marked, positions.squad_minimum] \
		if marked < positions.squad_minimum \
		else UiText.t("team.registered") % [marked, people.size()]

func _squad_is_short(people: Array[Actor], positions: PositionDef) -> bool:
	var marked: int = 0
	for person: Actor in people:
		if not person.lineup().is_empty():
			marked += 1
	return marked < positions.squad_minimum

# The number that moves as you shuffle the pieces. Only the STARTERS count —
# depth on the bench does not take the field — so swapping a reserve in changes
# it and that is the whole feedback loop of building a side.
func _unit_overall(assigned: Dictionary, positions: PositionDef, side: String) -> int:
	var total: int = 0
	var counted: int = 0
	for id: String in positions.ids_on_side(side):
		var picked: Array = assigned.get(id, [])
		for slot: int in range(mini(positions.slots(id), picked.size())):
			total += (picked[slot] as Actor).overall()
			counted += 1
	return int(round(float(total) / float(counted))) if counted > 0 else 0

func _unit_caption(text: String, overall: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Look.wear_body(label, Look.TEXT)
	label.add_theme_color_override("font_color", MUTED)
	row.add_child(label)
	var value := Label.new()
	value.text = str(overall) if overall > 0 else "—"
	Look.wear_body(value, Look.TEXT)
	value.add_theme_color_override("font_color",
		StatBar.tint(overall, ACCENT) if overall > 0 else MUTED)
	row.add_child(value)
	return row

# Where a Geral sits between the worst and the best in this squad, as 0..100.
# A flat squad still spreads across the ramp, which is right: the question the
# column answers is "who here is good", and "here" is the squad.
func _in_squad(value: int) -> int:
	var span: int = _best_overall - _worst_overall
	if span <= 0:
		return 50
	return clampi(int(round(float(value - _worst_overall) * 100.0 / float(span))), 0, 100)

func _measure_fit_ceilings(people: Array[Actor]) -> void:
	_fit_ceilings.clear()
	_worst_overall = 0
	_best_overall = 0
	for person: Actor in people:
		var mark: int = person.overall()
		if _best_overall == 0 or mark > _best_overall:
			_best_overall = mark
		if _worst_overall == 0 or mark < _worst_overall:
			_worst_overall = mark
	var positions := Drive.def("position") as PositionDef
	if positions == null:
		return
	for id: String in positions.position_ids():
		var best: float = 0.0
		for person: Actor in people:
			best = maxf(best, positions.fit(id, person.stats(), person.skills()))
		_fit_ceilings[id] = maxf(best, 0.01)

# A heading, and whatever STATE goes with it. The sentence explaining what the
# block is for moved to the tooltip — "existe até no menor clube: alguém
# responde, alguém paga e alguém fala" is a nice line and it was sixty-nine
# characters of a three-hundred-pixel column, permanently, saying something you
# need told once.
#
# `note` is the difference: it is state, not explanation ("9/12 inscritos"), so
# it stays on screen and stays short.
func _panel_title(text: String, note: String, tip: String = "",
		alarm: bool = false) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var title := Label.new()
	title.text = text
	title.add_theme_color_override("font_color", ACCENT)
	Look.wear_display(title, Look.HEADING)
	row.add_child(title)
	if note != "":
		var state := Label.new()
		state.text = note
		state.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		state.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		state.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		state.clip_text = true
		Look.wear_body(state, Look.TEXT)
		# The colour is the alarm, so the words do not have to be.
		state.add_theme_color_override("font_color", Look.WARN if alarm else MUTED)
		row.add_child(state)
	if tip != "":
		row.tooltip_text = tip
		row.mouse_filter = Control.MOUSE_FILTER_STOP
	box.add_child(row)
	box.add_child(_rule())
	return box

func _slot_row(code: String, who: Actor) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var tag := Label.new()
	tag.text = code
	tag.custom_minimum_size = Vector2(36, 0)
	Look.wear_body(tag, Look.TEXT)
	tag.add_theme_color_override("font_color", ACCENT if code != "" else MUTED)
	row.add_child(tag)

	var name_label := Label.new()
	name_label.custom_minimum_size = Vector2(190, 0)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	Look.wear_body(name_label, Look.TEXT)
	if who == null:
		name_label.text = "\u2b1a " + UiText.t("team.empty_slot")
		name_label.add_theme_color_override("font_color", MUTED.darkened(0.35))
		row.add_child(name_label)
		return row
	name_label.text = who.display_name()
	name_label.add_theme_color_override("font_color", INK)
	row.add_child(name_label)
	var strength := Label.new()
	strength.text = str(who.overall())
	strength.custom_minimum_size = Vector2(36, 0)
	strength.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	Look.wear_body(strength, Look.TEXT)
	strength.add_theme_color_override("font_color", StatBar.tint(who.overall(), ACCENT))
	row.add_child(strength)
	return row

# Two header rows. The top one says what the block of columns is FOR, which is
# what makes eleven little buttons legible instead of a wall: profile, who
# plays, who coaches.
func _shirt_cell(person: Actor) -> Control:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	box.custom_minimum_size = Vector2(COL_SHIRT, 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# ⚠️ ONE SPACE, NOT A LEADER. The nickname used to EXPAND_FILL, which pushed
	# the number to the right edge of a 190px column and left a run of empty
	# table between them — the dotted line of a menu, on something that should
	# read the way it reads on the back of the shirt.
	# ⚠️ THE APELIDO, AND NOTHING STANDING IN FOR IT. It fell back to the first
	# name when there was none, which put "João" in the shirt column beside "João
	# das Couves" in the name column — the same word twice, reading as though the
	# nickname were missing from a player who simply has not got one. Forty per
	# cent of a squad goes by no nickname, and a shirt with just a number on it
	# is what that actually looks like.
	# ⚠️ CLIPPED **AND** GIVEN A WIDTH, and it needs both. `clip_text` alone makes
	# a Label report a minimum of ZERO, so inside an HBox it is the first thing
	# squeezed — the apelido was crushed to nothing against the number beside it,
	# which reads exactly like the apelido not being there. It used to survive
	# because it also had EXPAND_FILL to claim the slack, and taking that away to
	# close the gap took the width with it.
	#
	# Dropping the clip instead is the other trap: the column then grows to
	# whatever the longest nickname in THIS squad happens to be, and a module
	# with longer ones silently widens the table. A floor plus a clip is bounded
	# in both directions.
	var nick := Label.new()
	nick.text = person.nickname()
	nick.clip_text = true
	nick.custom_minimum_size = Vector2(NICK_WIDTH, 0)
	Look.wear_body(nick, Look.TEXT)
	nick.add_theme_color_override("font_color", INK)
	nick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(nick)
	var number := Label.new()
	number.text = "#%d" % person.jersey() if person.jersey() != Actor.NO_JERSEY else ""
	Look.wear_body(number, Look.TEXT)
	number.add_theme_color_override("font_color", MUTED)
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(number)
	return box

# ⚠️ THE MARK, IN ITS COLOUR. NO BOX. It was a PanelContainer with a filled
# background and a border, which on a table of forty rows is forty little red
# and green rectangles fighting the roster for attention — a chip is a thing you
# click, and this one does nothing.
#
# The glyph is the same one the creation screen puts in brackets beside the
# name, which is the point: you learn `[>] FOGUETE` while building your manager
# and then recognise `[>]` here without being told. The colour still carries the
# sign, because green-is-a-talent and red-is-a-liability is the one comparison a
# player makes constantly — and it is a FIXED green and red so that a liability
# never disguises itself as a strength because the shirt happened to be red.
func _talent_mark(person: Actor) -> Control:
	var perks := Drive.def("perk") as PerkDef
	var ids: Array = person.perks()
	if perks == null or ids.is_empty():
		return _cell("\u00b7", COL_PERK, MUTED.darkened(0.45))
	var id: String = String(ids[0])
	var mark: Control = _cell("[%s]" % perks.glyph(id), COL_PERK,
		TALENT_BAD if perks.is_flaw(id) else TALENT_GOOD)
	mark.tooltip_text = perks.explain(id)
	mark.mouse_filter = Control.MOUSE_FILTER_STOP
	return mark

func _cell(text: String, width: int, color: Color) -> Control:
	var label := Label.new()
	label.name = "Cell"
	label.text = text
	label.custom_minimum_size = Vector2(width, 0)
	Look.wear_body(label, Look.TEXT)
	label.add_theme_color_override("font_color", color)
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

# --- The card ---
#
# ⚠️ FOUR COLUMNS THAT SHARE THE WIDTH, and the nesting is why they did not.
# The card used to be a two-column split — attributes on the left, skills on the
# right — and then the pools were added UNDER the attributes, so one side grew
# to thirteen rows while the other kept eight and the whole sheet piled up in
# the left half with air beside it.
#
# Nesting a column inside a column is what does that: an inner VBox hugs its own
# content, the outer HBox hands out no slack, and every group ends up as narrow
# as its narrowest row no matter how much room the panel has. Four siblings on
# one row, each set to EXPAND_FILL, and the width is divided instead of clumped.
#
# The order is a reading order, not a packing order: who he IS (attributes),
# what he HAS LEFT (pools), what he does with the ball, what he does with a
# clipboard. The body and the talent are in the header and the CAREER is at the
# bottom — which was the thing missing entirely at first: a rolled thirty-year-
# old had nine seasons of history and the sheet showed none of it.
func _show_card() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.gui_input.connect(_on_card_background)
	shade.set_meta("card_layer", true)
	add_child(shade)

	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.set_meta("card_layer", true)
	add_child(centre)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	# Four columns of a code and a ten-slot bar, measured: 40 + 118 plus the
	# separations. At 700 the fourth one had nowhere to go.
	panel.custom_minimum_size = Vector2(CARD_WIDTH, 0)
	panel.set_meta("athlete_card", true)
	centre.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	box.add_child(_card_header())
	box.add_child(_rule())

	var stats := Drive.def("stat") as StatDef
	if stats == null:
		return
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 18)
	box.add_child(columns)

	# WHO HE IS. Declared head to foot in the JSON, so this loop reads top-down
	# like a person standing up: mind, eyes, voice, heart, core, hands, hips,
	# feet. THE THREE-LETTER CODE, same as the creation sheet — twenty-three
	# named rows beside twenty-three bars is a wall of words competing with the
	# numbers they label, and the name is one hover away.
	var attributes: VBoxContainer = _card_column(UiText.t("manager.attributes"))
	for id: String in stats.base_ids():
		attributes.add_child(StatBar.row(stats.code(id), _selected.step(id) * 10,
			"%s\n%s" % [stats.chakra_label(id), stats.explain(id)],
			CARD_CODE, stats.chakra_color(id)))
	columns.add_child(attributes)

	# WHAT HE HAS LEFT.
	var pools: VBoxContainer = _card_column(UiText.t("team.pools"))
	for id: String in Pools.ids():
		pools.add_child(_pool_row(id))
	columns.add_child(pools)

	# WHAT HE DOES WITH THE BALL, and then with a clipboard. Two columns with a
	# MEANING rather than a fold: the card answers "player or clipboard" before
	# you have read a single number.
	for half: Array in [["offense", "defense"], ["general", "staff"]]:
		var column: VBoxContainer = _card_column(UiText.t(
			"team.as_athlete" if half[0] == "offense" else "team.as_staff"))
		for group: Variant in half:
			var ids: Array = stats.skills_in_group(String(group))
			if ids.is_empty():
				continue
			column.add_child(_group_caption(UiText.t(
				"skillgroup." + String(group), String(group))))
			for id: String in ids:
				column.add_child(StatBar.row(stats.code(id),
					_selected.skill_step(id) * 10,
					stats.explain(id), CARD_CODE, stats.skill_color(id)))
		columns.add_child(column)

	box.add_child(_career_log())
	box.add_child(_flat_button(UiText.t("common.close"), _on_close_card))

# ⚠️ THE COLOUR IS HOW FULL IT IS, NOT WHICH POOL IT IS. Five hues for five bars
# would put five new colours on a screen whose whole point is that colour means
# something (decision 71) — and it would say the wrong thing anyway, because
# what you need from this block at a glance is not "this is the sanity one", it
# is "something here is nearly empty". The code beside the bar says which.
const POOL_CRITICAL := 25
const POOL_LOW := 50

# ⚠️ `EXPAND_FILL` IS THE WHOLE FIX. Without it a VBox is exactly as wide as its
# widest child, four of them add up to less than the panel, and an HBox leaves
# the remainder on the right — which reads as "everything is stuck to the left"
# and is really "nobody asked for the space".
func _card_column(caption: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_group_caption(caption))
	return box

# ⚠️ THE HUE IS WHICH POOL IT IS, AND THAT BEATS WHAT I HAD. I made it the FILL
# LEVEL first — neutral when healthy, amber below half, red below a quarter — on
# the grounds that five hues would spend the colour budget decision 71 reserves
# for meaning, and that "something here is nearly empty" is what you need from
# this block at a glance.
#
# It is the wrong trade. Red health, green stamina and blue for the mental bar
# are forty years of convention: the player reads them without being taught,
# which is a stronger kind of meaning than any rule about a budget. And the fill
# level was never lost — a bar shows it by construction, with the unlit slots
# dimmed in the same hue. It says how much AND which, the way an HP bar always
# has.
func _pool_row(id: String) -> Control:
	var pools := Drive.def("pool") as PoolDef
	if pools == null:
		return _spacer_cell(0)
	var pool: Dictionary = Pools.of(_selected, _viewed_club()).get(id, {})
	return StatBar.gauge_row(pools.code(id),
		int(pool.get("now", 0)), int(pool.get("max", 0)), pools.scale_value(),
		"%s  %d/%d\n\n%s" % [pools.label(id),
			int(pool.get("now", 0)), int(pool.get("max", 0)), pools.desc(id)],
		CARD_CODE, pools.color(id))

func _card_header() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var positions := Drive.def("position") as PositionDef
	var stats := Drive.def("stat") as StatDef

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	var name_label := Label.new()
	name_label.text = _selected.display_name()
	Look.wear_display(name_label, Look.PLATE)
	name_label.add_theme_color_override("font_color", INK)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_label)
	var strength := Label.new()
	strength.text = "%s %d" % [UiText.t("team.strength"), _selected.overall()]
	Look.wear_body(strength, Look.LEAD)
	strength.add_theme_color_override("font_color", StatBar.tint(_selected.overall(), ACCENT))
	strength.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(strength)
	box.add_child(top)

	var lived: String = ""
	if positions != null and _selected.position() != "":
		lived = positions.label(_selected.position())
	var parts: Array[String] = [_selected.full_name(),
		UiText.t("team.years") % _selected.age()]
	if lived != "":
		parts.append(lived)
	if _selected.career_years() > 0:
		parts.append(UiText.t("team.career_years") % _selected.career_years())
	if stats != null:
		parts.append("%s  %s" % [stats.format_measure("height", _selected.height()),
			stats.format_measure("weight", _selected.weight())])
	var under := Label.new()
	under.text = "   \u00b7   ".join(parts)
	Look.wear_body(under, Look.TEXT)
	under.add_theme_color_override("font_color", MUTED)
	box.add_child(under)

	var perks := Drive.def("perk") as PerkDef
	if perks != null:
		# ⚠️ CODE AND NAME, DESCRIPTION ON THE TOOLTIP. This line used to print the
		# whole sentence inline — the last place in the game still reading like a
		# classified ad after `B.6i` cleared every other screen. It survived
		# because it is behind a click, so nobody looking at the main screens
		# ever saw it.
		for perk_id: Variant in _selected.perks():
			var id: String = String(perk_id)
			var perk := Label.new()
			perk.text = "%s · %s" % [perks.icon(id), perks.label(id)]
			perk.tooltip_text = perks.explain(id)
			perk.mouse_filter = Control.MOUSE_FILTER_STOP
			Look.wear_body(perk, Look.TEXT)
			perk.add_theme_color_override("font_color",
				TALENT_BAD if perks.is_flaw(id) else TALENT_GOOD)
			box.add_child(perk)
	return box

# The log. One line per season: how old he was, where he played it, and the two
# or three things that actually moved.
func _career_log() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	var seasons: Array = _selected.career()
	box.add_child(_group_caption(UiText.t("team.career") % _selected.career_years()))
	if seasons.is_empty():
		box.add_child(_hint(UiText.t("team.no_career")))
		return box
	var positions := Drive.def("position") as PositionDef
	var stats := Drive.def("stat") as StatDef
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 108)
	box.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	for entry: Variant in seasons:
		var season: Dictionary = entry as Dictionary
		var gains: Array[String] = []
		for id: String in (season.get("gains", {}) as Dictionary).keys():
			var delta: int = int((season["gains"] as Dictionary)[id])
			var label: String = id
			if stats != null:
				label = I18n.text(stats.skill(id).get("label",
					stats.base_stat(id).get("label", id)), id)
			gains.append("%s %+d" % [label, delta])
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 10)
		line.add_child(_cell(str(int(season.get("age", 0))), 26, MUTED))
		var code: String = String(season.get("position", ""))
		if positions != null and positions.has_position(code):
			code = positions.code(code)
		line.add_child(_cell(code, 30, ACCENT))
		line.add_child(_cell("   ".join(gains) if not gains.is_empty()
			else UiText.t("team.quiet_season"), 460, INK if not gains.is_empty() else MUTED))
		rows.add_child(line)
	return box

func _on_card_background(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_on_close_card()

func _on_close_card() -> void:
	_selected = null
	_build_ui()

# --- Adversários ---# --- Adversários ---

func _rivals_tab() -> Control:
	var career: Career = _career()
	var mine: String = career.team_id if career != null else ""
	var teams := Drive.def("team") as TeamDef
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)
	if teams == null:
		return scroll
	for club: Dictionary in teams.by_reputation():
		# Your own club is the other tab. Listing it here made the screen look
		# like two views of the same thing.
		if String(club.get("id", "")) == mine:
			continue
		list.add_child(_rival_row(club))
	return scroll

# Clickable, because "who else is out there" is only half the question and the
# other half is "and who plays for them".
func _rival_row(club: Dictionary) -> Control:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 34)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, _row_style(false, state == "hover"))
	button.pressed.connect(_on_view.bind(String(club.get("id", ""))))
	button.tooltip_text = UiText.t("team.see_squad") % club.get("name", "?")

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_child(row)
	var tier: int = int(club.get("tier", 4))

	var badge := Label.new()
	badge.text = UiText.t("tier.%d" % tier, "?")
	badge.custom_minimum_size = Vector2(96, 0)
	Look.wear_body(badge, Look.TEXT)
	badge.add_theme_color_override("font_color", _TIER_COLOR.get(tier, Color.WHITE))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(badge)

	var scheme: Dictionary = TeamColors.of(club)
	var style := StyleBoxFlat.new()
	style.bg_color = scheme["plate"]
	style.set_content_margin_all(5)
	for corner: String in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		style.set("corner_radius_" + corner, 3)
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", style)
	plate.custom_minimum_size = Vector2(230, 0)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_label := Label.new()
	name_label.text = String(club.get("name", "?"))
	name_label.add_theme_color_override("font_color", scheme["ink"])
	plate.add_child(name_label)
	row.add_child(plate)

	var teams := Drive.def("team") as TeamDef
	row.add_child(_cell("%s/%s" % [
		teams.where(club) if teams != null else club.get("city", "?"),
		club.get("state", "?")], 190, MUTED))
	var reputation: int = int(club.get("reputation", 0))
	row.add_child(_cell("%s %d" % ["█".repeat(int(reputation / 10.0)), reputation], 130, ACCENT))
	return button

# --- Actions ---

func _on_tab(id: String) -> void:
	_tab = id
	_build_ui()

# Looking at a rival is looking at a different squad, so the selected player
# has to let go — keeping it would show somebody from the previous club under
# this club's name.
func _on_view(team_id: String) -> void:
	_viewing = team_id
	_selected = null
	_tab = TAB_SQUAD
	_build_ui()

func _on_view_mine() -> void:
	_viewing = ""
	_selected = null
	_build_ui()

func _on_sort(key: String) -> void:
	if _sort_key == key:
		_sort_desc = not _sort_desc
	else:
		_sort_key = key
		# Names read A-Z; every other column reads best-first.
		_sort_desc = key != SORT_NAME
	_build_ui()

func _on_toggle_position(person: Actor, position_id: String) -> void:
	person.toggle_position(position_id)
	_build_ui()

func _on_pick(person: Actor) -> void:
	_selected = person
	_build_ui()

# One button per position, per player. Ticked means "cleared to play here" and
# fills in; untouched, the letters are tinted by how well he FITS the position,
# so the column reads as a heat map before anybody has decided anything.
# One button per role, per player, and the BOX IS A BAR. A 33% fit fills a
# third of the box from the left.
#
# The first version tinted the letters instead, and the difference between a
# 40% fit and a 55% one was invisible — a gradient across two characters of
# text has nowhere to be seen. Filled area reads at a glance down a whole
# column, which is the point: the roster becomes a heat map of who could play
# what before the manager has decided anything.
func _position_button(person: Actor, positions: PositionDef, id: String,
		ceiling: float) -> Button:
	var chosen: bool = person.plays_position(id)
	# NORMALISED to the best in this column, not to an absolute scale. You never
	# pick a quarterback against the world, you pick him against the eleven
	# other people in the room — so the fullest box in a column is the club's
	# best option there, and the rest read as fractions of him.
	var raw: float = maxf(positions.fit(id, person.stats(), person.skills()), 0.0)
	var fit: float = clampf(raw / ceiling, 0.0, 1.0) if ceiling > 0.0 else 0.0
	var shown: int = int(round(raw * 100.0))

	var button := Button.new()
	button.set_meta("role", id)
	button.text = ""
	button.custom_minimum_size = Vector2(COL_ROLE, 22)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.clip_contents = true
	# ONE CHAIR IS NOT YOURS TO HAND OUT. The president is the person the club
	# answers to, and that is what being the player means — you cannot resign it
	# and you cannot give it to a receiver. Every other chair on this row is a
	# job, and jobs are exactly what this screen is for.
	# ⚠️ LOCKED, NOT DISABLED. `disabled` greys a control out, and grey means "not
	# available" — which is the opposite of what this cell says. The presidency is
	# HELD: the box is filled, in the club's own lettering, exactly like every
	# other chair somebody holds. It simply does not answer the mouse.
	var locked: bool = id == OriginDef.CHAIR_OF_THE_CLUB
	var style := StyleBoxFlat.new()
	style.bg_color = ACCENT if chosen else WELL
	style.border_color = ACCENT if chosen else LINE
	style.set_border_width_all(1)
	style.set_content_margin_all(0)
	for state: String in ["normal", "hover", "pressed"]:
		button.add_theme_stylebox_override(state, style)

	# Fractional anchors, so the fill is a real proportion of the box at any
	# width rather than a pixel count that goes wrong when the column moves.
	if not chosen and fit > 0.0:
		var bar := ColorRect.new()
		# THE CLUB'S HUE, not the app's green. This box sits on a ground made
		# from the club's own kit, and a green fill on a yellow ground was two
		# teams' colours in one cell.
		bar.color = StatBar.tint(int(round(fit * 100.0)), ACCENT)
		bar.color.a = 0.42
		bar.anchor_left = 0.0
		bar.anchor_top = 0.0
		bar.anchor_right = fit
		bar.anchor_bottom = 1.0
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(bar)

	# ⚠️ THE AFFINITY, NOT THE CODE. Every cell in the president column used to
	# read "PRE", twelve times, under a heading that already said PRE — two
	# hundred and sixteen repetitions of eighteen words the column had already
	# named. It was not information, it was texture, and it made the table
	# unreadable by being loud about nothing.
	#
	# What a cell of (person, position) actually knows is how well this person
	# suits this job, and that was only ever encoded as the width of the fill
	# behind it. Now it is a number as well: the fill is RELATIVE (how he ranks
	# against the rest of this squad at this position) and the number is
	# ABSOLUTE, so the two answer different questions rather than repeat.
	#
	# Tinted by its own value, so a column of low fits fades out and the eye
	# lands on the two people who can actually do the job.
	var label := Label.new()
	label.text = str(shown)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Look.wear_body(label, Look.TEXT)
	label.add_theme_color_override("font_color",
		# The RELATIVE value colours it and the absolute one is written in it:
		# affinities run from about 2 to 88, so tinting by the raw number would
		# leave most of the table grey for the same reason Geral was.
		ON_ACCENT if chosen else StatBar.tint(int(round(fit * 100.0)), ACCENT))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(label)

	button.tooltip_text = "%s — %s\n%s: %d%%%s" % [
		positions.label(id), positions.desc(id),
		UiText.t("team.fit"), shown,
		"\n" + UiText.t("team.president_fixed") if locked else ""]
	if not locked:
		button.pressed.connect(_on_toggle_position.bind(person, id))
	return button

# Sorting is stable on the name, so two players with the same Forca keep a
# fixed order instead of shuffling every time the screen redraws.
func _sorted(people: Array[Actor]) -> Array[Actor]:
	var positions := Drive.def("position") as PositionDef
	var out: Array[Actor] = people.duplicate()
	var key: String = _sort_key
	out.sort_custom(func(a: Actor, b: Actor) -> bool:
		var left: float = _sort_value(a, key, positions)
		var right: float = _sort_value(b, key, positions)
		if is_equal_approx(left, right):
			return a.display_name().naturalnocasecmp_to(b.display_name()) < 0
		return left > right if _sort_desc else left < right)
	return out

func _sort_value(person: Actor, key: String, positions: PositionDef) -> float:
	if key.begins_with("fit:"):
		return positions.fit(key.substr(4), person.stats(), person.skills()) \
			if positions != null else 0.0
	match key:
		SORT_STRENGTH:
			return float(person.overall())
		SORT_AGE:
			return float(person.age())
		SORT_SHIRT:
			return float(person.jersey())
		SORT_PERK:
			var perks := Drive.def("perk") as PerkDef
			if person.perks().is_empty() or perks == null:
				return 0.0
			# Talents above, disadvantages below, nothing in between.
			return 1.0 if not perks.is_flaw(String(person.perks()[0])) else -1.0
	# By name the comparator falls through to the tie-break, which IS the name.
	return 0.0

# --- Widgets ---

func _tab_button(text: String, id: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(142, 32)
	button.focus_mode = Control.FOCUS_NONE
	var chosen: bool = _tab == id
	var style := StyleBoxFlat.new()
	style.bg_color = ACCENT if chosen else WELL.lightened(0.05)
	style.border_color = ACCENT if chosen else LINE
	style.set_border_width_all(1)
	style.set_content_margin_all(5)
	for corner: String in ["top_left", "top_right"]:
		style.set("corner_radius_" + corner, 3)
	for state: String in ["normal", "hover", "pressed"]:
		button.add_theme_stylebox_override(state, style)
	button.add_theme_color_override("font_color",
		ON_ACCENT if chosen else MUTED)
	button.pressed.connect(_on_tab.bind(id))
	return button

func _row_style(chosen: bool, hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if chosen:
		style.bg_color = LINE.lightened(0.05)
	else:
		style.bg_color = WELL.lightened(0.06) if hovered else WELL
	style.border_color = ACCENT if chosen else WELL
	style.set_border_width_all(1)
	style.set_content_margin_all(3)
	return style

func _flat_button(text: String, on_press: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(110, 32)
	button.focus_mode = Control.FOCUS_NONE
	var style := StyleBoxFlat.new()
	style.bg_color = WELL.lightened(0.08)
	style.border_color = LINE
	style.set_border_width_all(1)
	style.set_content_margin_all(5)
	for corner: String in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		style.set("corner_radius_" + corner, 3)
	for state: String in ["normal", "hover", "pressed"]:
		button.add_theme_stylebox_override(state, style)
	button.add_theme_color_override("font_color", INK)
	if on_press.is_valid():
		button.pressed.connect(on_press)
	return button

func _section(text: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	box.add_child(spacer)
	var label := Label.new()
	label.text = text
	Look.wear_body(label, Look.TEXT)
	label.add_theme_color_override("font_color", ACCENT)
	box.add_child(label)
	box.add_child(_rule())
	return box

func _group_caption(text: String) -> Control:
	var label := Label.new()
	label.text = text
	Look.wear_body(label, Look.TEXT)
	label.add_theme_color_override("font_color", MUTED)
	return label

# A WINDOW, and the border is the club. The fill is near-black on purpose: this
# same style carries the athlete card, and the card is where the chakras live.
func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = ACCENT.lerp(CANVAS, 0.35)
	style.set_border_width_all(1)
	style.set_content_margin_all(16)
	for corner: String in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		style.set("corner_radius_" + corner, 4)
	return style

func _rule() -> Control:
	var line := ColorRect.new()
	line.color = LINE
	line.custom_minimum_size = Vector2(0, 1)
	return line

func _hint(text: String) -> Control:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Look.wear_body(label, Look.TEXT)
	label.add_theme_color_override("font_color", MUTED)
	return label
