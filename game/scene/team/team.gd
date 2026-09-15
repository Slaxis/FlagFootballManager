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

const BG := Color(0.055, 0.078, 0.063)
const PANEL := Color(0.086, 0.118, 0.094)
const ACCENT := Color(0.49, 0.78, 0.45)
const MUTED := Color(0.47, 0.52, 0.48)
const TEXT := Color(0.87, 0.90, 0.87)
const LINE := Color(0.16, 0.22, 0.17)

const TAB_SQUAD := "squad"
const TAB_RIVALS := "rivals"

const _TIER_COLOR: Dictionary = {
	1: Color(0.95, 0.82, 0.35),
	2: Color(0.75, 0.78, 0.82),
	3: Color(0.72, 0.52, 0.36),
	4: Color(0.45, 0.47, 0.45),
}

var _tab: String = TAB_SQUAD
var _selected: Actor = null
var _root: VBoxContainer = null

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
	margin.add_child(_root)
	_build_ui()

func _build_ui() -> void:
	for child: Node in _root.get_children():
		_root.remove_child(child)
		child.queue_free()
	_root.add_child(_header())
	_root.add_child(_tab_bar())
	_root.add_child(_rule())
	if _tab == TAB_SQUAD:
		_root.add_child(_squad_tab())
	else:
		_root.add_child(_rivals_tab())

# --- Chrome ---

func _career() -> Career:
	return read("career") as Career

func _rosters() -> Rosters:
	var existing := read("rosters") as Rosters
	if existing != null:
		return existing
	# First arrival. The career seed is the world; the rosters are what that
	# world turned out to contain.
	var career: Career = _career()
	var fresh: Rosters = Rosters.make(career.career_seed if career != null else 0)
	if career != null and career.manager != null:
		# You are in your own squad. Standing outside the roster you manage was
		# the kind of detail that only shows up when you finally look.
		for category: String in career.manager.plays():
			fresh.add(career.team_id, String(category), career.manager)
	write("rosters", fresh)
	return fresh

# Which squad the Elenco tab is showing. Your own category when you play one,
# otherwise whatever the club actually fields.
func _category() -> String:
	var career: Career = _career()
	var club: Dictionary = career.team() if career != null else {}
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
	var career: Career = _career()
	var club: Dictionary = career.team() if career != null else {}
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
	name_label.add_theme_font_size_override("font_size", 26)
	plate.add_child(name_label)
	row.add_child(plate)

	var where := Label.new()
	where.text = "%s/%s   ·   %s" % [club.get("city", "?"), club.get("state", "?"),
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
	row.add_child(_flat_button(UiText.t("common.back"), func() -> void: go("back")))
	return row

# --- Elenco ---

func _squad_tab() -> Control:
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 22)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var career: Career = _career()
	var people: Array[Actor] = _rosters().squad(
		career.team_id if career != null else "", _category())

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
	columns.add_child(left)

	if _selected == null and not people.is_empty():
		_selected = people[0]
	columns.add_child(_sheet_panel())
	return columns

func _column_headings() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for pair: Array in [["", 22], [UiText.t("team.name"), 260],
			[UiText.t("team.age"), 54], [UiText.t("team.overall"), 44]]:
		var label := Label.new()
		label.text = String(pair[0])
		label.custom_minimum_size = Vector2(int(pair[1]), 0)
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", MUTED)
		row.add_child(label)
	return row

func _roster_row(person: Actor, is_manager: bool) -> Control:
	var button := Button.new()
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

	row.add_child(_cell("★" if is_manager else "", 22, ACCENT if is_manager else MUTED))
	row.add_child(_cell(person.display_name(), 260, TEXT))
	row.add_child(_cell(str(person.age()), 54, MUTED))
	row.add_child(_cell(str(person.overall()), 44, ACCENT))
	return button

func _cell(text: String, width: int, color: Color) -> Control:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(width, 0)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

# The whole point of the branch: 8 attributes, 15 skills, a body and a perk,
# for somebody who is not you.
func _sheet_panel() -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = LINE
	style.set_border_width_all(1)
	style.set_content_margin_all(16)
	for corner: String in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		style.set("corner_radius_" + corner, 4)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(430, 0)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	if _selected == null:
		box.add_child(_hint(UiText.t("team.pick_someone")))
		return panel

	var stats := Drive.def("stat") as StatDef
	var title := Label.new()
	title.text = _selected.display_name()
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", TEXT)
	box.add_child(title)

	var under := Label.new()
	under.text = "%s   ·   %s" % [_selected.full_name(), UiText.t("team.years") % _selected.age()]
	under.add_theme_font_size_override("font_size", 12)
	under.add_theme_color_override("font_color", MUTED)
	box.add_child(under)

	if stats != null:
		var body := Label.new()
		body.text = "%s   %s" % [
			stats.format_measure("height", _selected.height()),
			stats.format_measure("weight", _selected.weight())]
		body.add_theme_font_size_override("font_size", 12)
		body.add_theme_color_override("font_color", MUTED)
		box.add_child(body)

	var perks := Drive.def("perk") as PerkDef
	if perks != null:
		for perk_id: Variant in _selected.perks():
			var perk := Label.new()
			perk.text = "%s %s" % [perks.icon(String(perk_id)), perks.label(String(perk_id))]
			perk.tooltip_text = perks.desc(String(perk_id))
			perk.mouse_filter = Control.MOUSE_FILTER_STOP
			perk.add_theme_color_override("font_color", ACCENT)
			box.add_child(perk)

	if stats == null:
		return panel
	box.add_child(_section(UiText.t("manager.attributes")))
	for id: String in stats.base_ids():
		var spec: Dictionary = stats.base_stat(id)
		box.add_child(StatBar.row(
			I18n.text(spec.get("label", id), id),
			_selected.step(id) * 10,
			I18n.text(spec.get("desc", ""), ""), 118))
	box.add_child(_section(UiText.t("manager.skills")))
	for group: String in stats.skill_groups():
		for id: String in stats.skills_in_group(group):
			# Only what they actually know: fifteen bars, twelve of them dark,
			# says nothing that three lit ones do not say better.
			if _selected.skill_step(id) <= 0:
				continue
			var spec: Dictionary = stats.skill(id)
			box.add_child(StatBar.row(
				I18n.text(spec.get("label", id), id),
				_selected.skill_step(id) * 10,
				I18n.text(spec.get("desc", ""), ""), 118))
	return panel

# --- Adversários ---

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

func _rival_row(club: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var tier: int = int(club.get("tier", 4))

	var badge := Label.new()
	badge.text = UiText.t("tier.%d" % tier, "?")
	badge.custom_minimum_size = Vector2(96, 0)
	badge.add_theme_font_size_override("font_size", 12)
	badge.add_theme_color_override("font_color", _TIER_COLOR.get(tier, Color.WHITE))
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
	var name_label := Label.new()
	name_label.text = String(club.get("name", "?"))
	name_label.add_theme_color_override("font_color", scheme["ink"])
	plate.add_child(name_label)
	row.add_child(plate)

	row.add_child(_cell("%s/%s" % [club.get("city", "?"), club.get("state", "?")], 190, MUTED))
	var reputation: int = int(club.get("reputation", 0))
	row.add_child(_cell("%s %d" % ["█".repeat(int(reputation / 10.0)), reputation], 130, ACCENT))
	return row

# --- Actions ---

func _on_tab(id: String) -> void:
	_tab = id
	_build_ui()

func _on_pick(person: Actor) -> void:
	_selected = person
	_build_ui()

# --- Widgets ---

func _tab_button(text: String, id: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(140, 32)
	button.focus_mode = Control.FOCUS_NONE
	var chosen: bool = _tab == id
	var style := StyleBoxFlat.new()
	style.bg_color = ACCENT if chosen else Color(0.10, 0.14, 0.11)
	style.border_color = ACCENT if chosen else Color(0.20, 0.27, 0.21)
	style.set_border_width_all(1)
	style.set_content_margin_all(5)
	for corner: String in ["top_left", "top_right"]:
		style.set("corner_radius_" + corner, 3)
	for state: String in ["normal", "hover", "pressed"]:
		button.add_theme_stylebox_override(state, style)
	button.add_theme_color_override("font_color",
		Color(0.05, 0.09, 0.05) if chosen else MUTED)
	button.pressed.connect(_on_tab.bind(id))
	return button

func _row_style(chosen: bool, hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if chosen:
		style.bg_color = Color(0.14, 0.22, 0.16)
	else:
		style.bg_color = Color(0.10, 0.14, 0.11) if hovered else Color(0.07, 0.10, 0.08)
	style.border_color = ACCENT if chosen else Color(0.07, 0.10, 0.08)
	style.set_border_width_all(1)
	style.set_content_margin_all(3)
	return style

func _flat_button(text: String, on_press: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(110, 32)
	button.focus_mode = Control.FOCUS_NONE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.15, 0.12)
	style.border_color = Color(0.20, 0.27, 0.21)
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
