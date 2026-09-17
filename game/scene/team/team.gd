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
var BG := Color(0.055, 0.078, 0.063)
var PANEL := Color(0.086, 0.118, 0.094)
var ACCENT := Color(0.49, 0.78, 0.45)
var MUTED := Color(0.47, 0.52, 0.48)
var TEXT := Color(0.87, 0.90, 0.87)
var LINE := Color(0.16, 0.22, 0.17)
# The two the widgets used to hardcode: the ground inside a control, and the
# ink that goes ON the accent when a control is filled with it. Derived like
# everything else, so a yellow club gets a yellow-black and not a green one.
var WELL := Color(0.08, 0.11, 0.09)
var ON_ACCENT := Color(0.05, 0.09, 0.05)

func _wear_club_colours() -> void:
	var scheme: Dictionary = TeamColors.of(_viewed_club())
	var plate: Color = scheme["plate"]
	var ink: Color = scheme["ink"]
	# A dark ground under a light kit and a light ground under a dark one: the
	# club keeps its hue and the screen keeps its legibility.
	BG = plate.darkened(0.82) if plate.get_luminance() > 0.35 else plate.darkened(0.45)
	PANEL = BG.lightened(0.06)
	LINE = BG.lightened(0.16)
	ACCENT = ink if ink.get_luminance() > 0.3 else plate.lightened(0.45)
	TEXT = ACCENT.lightened(0.55)
	MUTED = TEXT.darkened(0.45)
	WELL = BG.darkened(0.18)
	ON_ACCENT = BG.darkened(0.35)

const TAB_SQUAD := "squad"
const TAB_RIVALS := "rivals"

const SORT_NAME := "name"
const SORT_SHIRT := "shirt"
const SORT_PERK := "perk"
const SORT_STRENGTH := "strength"
const SORT_AGE := "age"

# Column widths live here and nowhere else: the group header above and the
# sortable header below are both derived from them, so they cannot drift apart.
const COL_MARK := 18
const COL_NAME := 230
const COL_SHIRT := 190
const COL_PERK := 34
const COL_STRENGTH := 58
const COL_AGE := 48
const COL_ROLE := 36
const COL_GAP := 6
# The three-letter code column on the athlete card.
const CARD_CODE := 52

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

var _sort_key: String = SORT_STRENGTH
var _sort_desc: bool = true
var _root: VBoxContainer = null

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Look.fit_window()
	_wear_club_colours()
	var bg := ColorRect.new()
	bg.color = BG
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
			(child as ColorRect).color = BG
	for child: Node in _root.get_children():
		_root.remove_child(child)
		child.queue_free()
	# The card is a sibling of the layout and not a child of it, so clearing
	# `_root` does not clear the card. Without this every click stacked another
	# one on top of the last and the screen slowly filled with dead sheets.
	for child: Node in get_children():
		if child.has_meta("card_layer"):
			remove_child(child)
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

	# Fixed text until C.4 makes the calendar move. Showing it now is how the
	# screen says where the week is going to live.
	var week := Label.new()
	week.text = UiText.t("team.week") % [1, 2026]
	week.add_theme_color_override("font_color", MUTED)
	week.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(week)
	return row

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

	var career: Career = _career()
	var people: Array[Actor] = _sorted(_rosters().squad(_viewed_id(), _category()))
	_measure_fit_ceilings(people)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 2)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(_column_headings())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 1)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	left.add_child(scroll)
	var manager_id: String = career.manager.thing_id if career != null and career.manager != null else ""
	for person: Actor in people:
		list.add_child(_roster_row(person, person.thing_id == manager_id))
	# ESCALAÇÃO ON THE LEFT, table on the right. You read left to right, and the
	# question you arrive with is "who is on my team and what is still empty" —
	# the answer to that is the panel, so it goes first. The table is what you
	# reach for to change the answer, which is a second move.
	#
	# It lives beside the table and not behind a tab because the whole complaint
	# was that ticking boxes gave no sense of completeness, and an answer you
	# have to navigate to is not feedback.
	columns.add_child(_lineup_panel(people))
	columns.add_child(left)
	return columns

# --- The lineup ---

# Who is where, with the empty slots drawn as empty. Everybody marked past a
# position's slots is a RESERVE there, not a mistake: two quarterbacks is how a
# coach finds out which one is better, and most weeks the event is the coletivo
# where both take snaps.
func _lineup_panel(people: Array[Actor]) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	panel.custom_minimum_size = Vector2(300, 0)
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

	box.add_child(_panel_title(UiText.t("team.admin"), UiText.t("team.admin_hint")))
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
	box.add_child(_panel_title(UiText.t("team.lineup"), _squad_note(people, positions)))
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
	if marked < positions.squad_minimum:
		return UiText.t("team.below_minimum") % [marked, positions.squad_minimum]
	return UiText.t("team.registered") % [marked, people.size()]

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
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", MUTED)
	row.add_child(label)
	var value := Label.new()
	value.text = str(overall) if overall > 0 else "—"
	value.add_theme_font_size_override("font_size", 12)
	value.add_theme_color_override("font_color",
		StatBar.tint(overall, ACCENT) if overall > 0 else MUTED)
	row.add_child(value)
	return row

func _measure_fit_ceilings(people: Array[Actor]) -> void:
	_fit_ceilings.clear()
	var positions := Drive.def("position") as PositionDef
	if positions == null:
		return
	for id: String in positions.position_ids():
		var best: float = 0.0
		for person: Actor in people:
			best = maxf(best, positions.fit(id, person.stats(), person.skills()))
		_fit_ceilings[id] = maxf(best, 0.01)

func _panel_title(text: String, note: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	var title := Label.new()
	title.text = text
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", ACCENT)
	Look.wear_display(title, Look.HEADING)
	box.add_child(title)
	var hint := Label.new()
	hint.text = note
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", MUTED)
	box.add_child(hint)
	box.add_child(_rule())
	return box

func _slot_row(code: String, who: Actor) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var tag := Label.new()
	tag.text = code
	tag.custom_minimum_size = Vector2(26, 0)
	tag.add_theme_font_size_override("font_size", 11)
	tag.add_theme_color_override("font_color", ACCENT if code != "" else MUTED)
	row.add_child(tag)

	var name_label := Label.new()
	name_label.custom_minimum_size = Vector2(190, 0)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 12)
	if who == null:
		name_label.text = "\u2b1a " + UiText.t("team.empty_slot")
		name_label.add_theme_color_override("font_color", MUTED.darkened(0.35))
		row.add_child(name_label)
		return row
	name_label.text = who.display_name()
	name_label.add_theme_color_override("font_color", TEXT)
	row.add_child(name_label)
	var strength := Label.new()
	strength.text = str(who.overall())
	strength.custom_minimum_size = Vector2(26, 0)
	strength.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	strength.add_theme_font_size_override("font_size", 12)
	strength.add_theme_color_override("font_color", StatBar.tint(who.overall(), ACCENT))
	row.add_child(strength)
	return row

# Two header rows. The top one says what the block of columns is FOR, which is
# what makes eleven little buttons legible instead of a wall: profile, who
# plays, who coaches.
func _column_headings() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.add_child(_group_headings())
	box.add_child(_sort_headings())
	return box

func _group_headings() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", COL_GAP)
	var positions := Drive.def("position") as PositionDef
	var lineup: int = 0
	var staff: int = 0
	if positions != null:
		for side: String in SIDES_IN_LINEUP:
			lineup += positions.ids_on_side(side).size()
		staff = positions.ids_on_side("staff").size()
	var admin: int = positions.ids_on_side("admin").size() if positions != null else 0
	row.add_child(_group_label(UiText.t("team.profile"),
		COL_MARK + COL_NAME + COL_SHIRT + COL_PERK + COL_STRENGTH + COL_AGE + COL_GAP * 5))
	row.add_child(_group_label(UiText.t("team.admin"), _block_width(admin)))
	row.add_child(_group_label(UiText.t("team.staff"), _block_width(staff)))
	row.add_child(_group_label(UiText.t("team.lineup"), _block_width(lineup)))
	return row

func _block_width(columns: int) -> int:
	return maxi(columns * COL_ROLE + maxi(columns - 1, 0) * COL_GAP, 0)

func _group_label(text: String, width: int) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	box.custom_minimum_size = Vector2(width, 0)
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.clip_text = true
	Look.wear_body(label, Look.TINY)
	label.add_theme_color_override("font_color", ACCENT)
	box.add_child(label)
	var rule := ColorRect.new()
	rule.color = LINE
	rule.custom_minimum_size = Vector2(0, 1)
	box.add_child(rule)
	return box

func _sort_headings() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", COL_GAP)
	row.add_child(_spacer_cell(COL_MARK))
	row.add_child(_heading(UiText.t("team.name"), SORT_NAME, COL_NAME))
	row.add_child(_heading(UiText.t("team.shirt"), SORT_SHIRT, COL_SHIRT))
	row.add_child(_heading(UiText.t("team.talent"), SORT_PERK, COL_PERK))
	row.add_child(_heading(UiText.t("team.strength"), SORT_STRENGTH, COL_STRENGTH))
	row.add_child(_heading(UiText.t("team.age"), SORT_AGE, COL_AGE))
	var positions := Drive.def("position") as PositionDef
	if positions != null:
		for id: String in _role_order(positions):
			row.add_child(_heading(positions.code(id), "fit:" + id, COL_ROLE))
	return row

# Lineup first, then the staff chairs — the same order the rows use, because a
# header that does not line up with its column is worse than no header.
# Administration, then the coaching staff, then who takes the field — the order
# a club is actually built in. Somebody has to answer for the place before
# anybody picks a quarterback.
func _role_order(positions: PositionDef) -> Array[String]:
	var out: Array[String] = []
	out.append_array(positions.ids_on_side("admin"))
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
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", ACCENT if active else MUTED)
	button.add_theme_color_override("font_hover_color", TEXT)
	button.pressed.connect(_on_sort.bind(key))
	return button

func _roster_row(person: Actor, is_manager: bool) -> Control:
	var button := Button.new()
	# Tagged rather than named: Godot renames duplicate siblings, so a name is
	# not something a test can match on. The role buttons inside a row are
	# blank too — their code is a child Label over the fill bar — so text is
	# no help either.
	button.set_meta("roster_row", true)
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 26)
	var chosen: bool = _selected != null and _selected.thing_id == person.thing_id
	for state: String in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, _row_style(chosen, state == "hover"))
	button.pressed.connect(_on_pick.bind(person))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_child(row)

	row.add_child(_cell("\u2605" if is_manager else "", COL_MARK,
		ACCENT if is_manager else MUTED))
	# Full name and the name on the shirt are different things, and a manager
	# reads the second one far more often.
	row.add_child(_cell(person.full_name(), COL_NAME, TEXT))
	row.add_child(_shirt_cell(person))
	row.add_child(_talent_chip(person))
	# Elifoot calls this Forca and so does this column: one number for how good
	# somebody is, tinted so the roster reads before it is read.
	var strength: int = person.overall()
	row.add_child(_cell(str(strength), COL_STRENGTH, StatBar.tint(strength, ACCENT)))
	row.add_child(_cell(str(person.age()), COL_AGE, MUTED))
	var positions := Drive.def("position") as PositionDef
	if positions != null:
		for id: String in _role_order(positions):
			row.add_child(_position_button(person, positions, id,
				float(_fit_ceilings.get(id, 1.0))))
	return button

func _shirt_cell(person: Actor) -> Control:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	box.custom_minimum_size = Vector2(COL_SHIRT, 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var nick := Label.new()
	nick.text = person.nickname() if person.nickname() != "" else person.first_name()
	nick.clip_text = true
	nick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nick.add_theme_font_size_override("font_size", 13)
	nick.add_theme_color_override("font_color", TEXT)
	nick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(nick)
	var number := Label.new()
	number.text = "#%d" % person.jersey() if person.jersey() != Actor.NO_JERSEY else ""
	number.add_theme_font_size_override("font_size", 11)
	number.add_theme_color_override("font_color", MUTED)
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(number)
	return box

# A chip, and the colour carries the sign: green is a talent, red is a
# disadvantage. Fixed hues on purpose — they read the same on every club's
# palette, so "that one is a liability" never depends on whose kit you are
# wearing.
func _talent_chip(person: Actor) -> Control:
	var perks := Drive.def("perk") as PerkDef
	var ids: Array = person.perks()
	if perks == null or ids.is_empty():
		return _cell("\u00b7", COL_PERK, MUTED.darkened(0.45))
	var id: String = String(ids[0])
	var flaw: bool = perks.is_flaw(id)
	var hue: Color = TALENT_BAD if flaw else TALENT_GOOD
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(COL_PERK, 0)
	chip.tooltip_text = "%s \u2014 %s" % [perks.label(id), perks.desc(id)]
	chip.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = hue.darkened(0.55)
	style.border_color = hue
	style.set_border_width_all(1)
	style.set_content_margin_all(1)
	for corner: String in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		style.set("corner_radius_" + corner, 3)
	chip.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = perks.icon(id)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", hue.lightened(0.3))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(label)
	return chip

func _cell(text: String, width: int, color: Color) -> Control:
	var label := Label.new()
	label.name = "Cell"
	label.text = text
	label.custom_minimum_size = Vector2(width, 0)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", color)
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

# --- The card ---
#
# SQUARE, not a ribbon. Attributes on the left, the fifteen skills in two
# columns on the right, the body and the perk in the header, and the CAREER at
# the bottom — which was the thing missing entirely: a rolled thirty-year-old
# had nine seasons of history and the sheet showed none of it, so there was no
# way to tell a veteran QB from a kid who happens to throw.
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
	panel.custom_minimum_size = Vector2(700, 0)
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
	columns.add_theme_constant_override("separation", 22)
	box.add_child(columns)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 2)
	left.add_child(_group_caption(UiText.t("manager.attributes")))
	# Declared head to foot in the JSON, so this loop reads top-down like a
	# person standing up: mind, eyes, voice, heart, core, hands, hips, feet.
	# THE THREE-LETTER CODE, same as the creation sheet. Twenty-three named rows
	# beside twenty-three bars is a wall of words competing with the numbers they
	# label; the name and the description are one hover away instead.
	for id: String in stats.base_ids():
		left.add_child(StatBar.row(stats.code(id), _selected.step(id) * 10,
			"%s\n%s" % [stats.chakra_label(id), stats.explain(id)],
			CARD_CODE, stats.chakra_color(id)))
	columns.add_child(left)

	# Two columns with a MEANING, not just a fold. Left is attack and defence —
	# what makes an athlete. Right is general and staff — what makes a coach. So
	# the card answers "player or clipboard" before you read a single number.
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 2)
	var pair := HBoxContainer.new()
	pair.add_theme_constant_override("separation", 18)
	right.add_child(pair)
	for half: Array in [["offense", "defense"], ["general", "staff"]]:
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 2)
		column.add_child(_group_caption(UiText.t(
			"team.as_athlete" if half[0] == "offense" else "team.as_staff")))
		pair.add_child(column)
		for group: Variant in half:
			var ids: Array = stats.skills_in_group(String(group))
			if ids.is_empty():
				continue
			column.add_child(_group_caption(UiText.t("skillgroup." + String(group), String(group))))
			for id: String in ids:
				column.add_child(StatBar.row(stats.code(id),
					_selected.skill_step(id) * 10,
					stats.explain(id), CARD_CODE, stats.skill_color(id)))
	columns.add_child(right)

	box.add_child(_career_log())
	box.add_child(_flat_button(UiText.t("common.close"), _on_close_card))

func _card_header() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var positions := Drive.def("position") as PositionDef
	var stats := Drive.def("stat") as StatDef

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	var name_label := Label.new()
	name_label.text = _selected.display_name()
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_label)
	var strength := Label.new()
	strength.text = "%s %d" % [UiText.t("team.strength"), _selected.overall()]
	strength.add_theme_font_size_override("font_size", 18)
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
	under.add_theme_font_size_override("font_size", 12)
	under.add_theme_color_override("font_color", MUTED)
	box.add_child(under)

	var perks := Drive.def("perk") as PerkDef
	if perks != null:
		for perk_id: Variant in _selected.perks():
			var perk := Label.new()
			perk.text = "%s %s — %s" % [perks.icon(String(perk_id)),
				perks.label(String(perk_id)), perks.desc(String(perk_id))]
			perk.add_theme_font_size_override("font_size", 11)
			perk.add_theme_color_override("font_color", ACCENT)
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
			else UiText.t("team.quiet_season"), 460, TEXT if not gains.is_empty() else MUTED))
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
	badge.add_theme_font_size_override("font_size", 12)
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

	var button := Button.new()
	button.set_meta("role", id)
	button.text = ""
	button.custom_minimum_size = Vector2(COL_ROLE, 22)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.clip_contents = true
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

	var label := Label.new()
	label.text = positions.code(id)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Look.wear_body(label, Look.TINY)
	label.add_theme_color_override("font_color",
		ON_ACCENT if chosen else TEXT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(label)

	button.tooltip_text = "%s — %s\n%s: %d%%" % [
		positions.label(id), positions.desc(id),
		UiText.t("team.fit"), int(round(raw * 100.0))]
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
	button.custom_minimum_size = Vector2(140, 32)
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
	button.add_theme_color_override("font_color", TEXT)
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
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", ACCENT)
	box.add_child(label)
	box.add_child(_rule())
	return box

func _group_caption(text: String) -> Control:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", MUTED)
	return label

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = LINE
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
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", MUTED)
	return label
