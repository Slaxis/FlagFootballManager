# Create Manager — you, growing up.
#
# The sheet is not filled with an abstract budget. The screen deals you a
# rolled adolescent and you spend the years left to adulthood, and the age at
# the top climbs as you allocate. Take points back and you get younger. The
# question the screen asks is "where did I invest my adolescence?".
#
# The screen deals you a rolled twelve-year-old — body, attributes, sometimes a
# perk — and never touches the skills: whether the six years left go into being
# faster or into knowing how to run a route is the question, and answering it
# for the player would empty the screen. 🎲 deals another child, identically:
# the dice pick who you were born as, never who you became.
#
# Attributes and skills share one pocket because a roll is
# `attribute + skill + 2d5*` — training dexterity and training throwing both
# make you throw better, and neither is the wrong answer.
#
# The seed is a HASH of the three name fields. Editing them is how you fix a
# world: the same nome + sobrenome + apelido always draws the same sandlot
# clubs and the same club calls you. Rerolling is therefore never separate from
# renaming — there is one 🎲 and it changes the person and the world together.
#
# Produces the `career` Record onto the Blackboard; the Flow gates every later
# step on it. Deliberately never asks your gender — it asks which CATEGORY you
# play (decision 17).
extends Menu

const BG := Color(0.055, 0.078, 0.063)
const PANEL := Color(0.086, 0.118, 0.094)
const ACCENT := Color(0.49, 0.78, 0.45)
const MUTED := Color(0.47, 0.52, 0.48)
const TEXT := Color(0.87, 0.90, 0.87)
const LINE := Color(0.16, 0.22, 0.17)
const WARN := Color(0.85, 0.72, 0.45)
const TALENT_GOOD := Color(0.42, 0.78, 0.45)
const TALENT_BAD := Color(0.85, 0.36, 0.36)

# ONE PAGE, THREE COLUMNS. The canvas is the monitor now (2560x1440, one logical
# pixel per screen pixel), so the whole sheet fits side by side again and the
# tabs it was split into are gone — a form you compare against itself should not
# make you click between the halves you are comparing.
# Pinned above the fullest scenario so the frame never moves: the three measure
# 783, 784 and 783, and one pixel of drift is still the screen jumping under you.
const PANEL_WIDTH := 1740
# The widths live here so the hints know what to wrap against: an autowrapping
# Label with no width reports its minimum as the whole unwrapped line and quietly
# blows the layout open.
#
# The height is pinned once the layout settles, so the Fundador's extra club
# block does not make the frame jump when you click between scenarios.
# Above the fullest scenario, so the frame never moves: the three measure 806,
# 807 and 806, and one pixel of drift is still the screen jumping under you.
const PANEL_HEIGHT := 790
const COL_LEFT := 620
const COL_MID := 360
const COL_RIGHT := 660
const SKILL_COLUMNS := 2
# The footer note gets whatever the three buttons leave. It was once 700px beside
# a 320px primary, which made that row alone wider than the screen.
# The three letters in every attribute and skill row.
const CODE_WIDTH := 52

const BOON_COLUMNS := 4
const FLAW_COLUMNS := 2
# How much of the row the qualities take. They outnumber the defects three to
# one, so they get five columns and the defects two.
const BOON_SHARE := 440
const PERK_GAP := 6
# The colours row, capped part by part so a typed club name cannot widen it.
const CREST_CAPTION := 90
const CREST_BUTTON := 130
const CREST_PLATE := 220

var _build: SheetBuilder = null
var _name: Dictionary = {}
var _plays: Array[String] = [Actor.CATEGORY_MASC]
var _origin: String = ""
var _drafted: Dictionary = {}
# The Fundador's club, while he is still deciding what it is called. Empty for
# the other two starts, who walk into something that already existed.
var _club: Dictionary = {}
var _seed_label: Label = null
var _root: VBoxContainer = null

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# The window may have changed since the last screen, and the canvas has to
	# follow it on a whole-pixel boundary or nothing drawn here lands on one.
	Look.fit_window()
	var rng: RandomNumberGenerator = _free_rng()
	var origins := Drive.def("origin") as OriginDef
	_origin = origins.origin_ids()[0] if origins != null else ""
	_build = SheetBuilder.rolled_opening(rng, _origin)
	_name = _roll_name(rng)
	# The screen opens on the Fundador, and the Fundador's form has a club in
	# it. Leaving it empty until he touched something meant the first thing he
	# saw was a nameless colour swatch.
	if _authors_club():
		_roll_club()

	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	# PINNED IN BOTH AXES. The Fundador's form carries a club block the other two
	# scenarios do not, so the panel grew and shrank as you clicked between them
	# and the whole screen jumped under the cursor — worst exactly when you are
	# comparing the three. A MINIMUM, so content that outgrows it still pushes
	# through and tests/fit_check.tscn still sees it.
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
	# Tagged for tests/fit_check.tscn: THIS is the node that has to fit on the
	# screen. The check cannot guess it — a ScrollContainer reports a tiny
	# minimum by design, so measuring the outermost thing would hide exactly the
	# problem the check exists to catch.
	panel.set_meta("fit_root", true)
	center.add_child(panel)

	_root = VBoxContainer.new()
	_root.add_theme_constant_override("separation", 8)
	panel.add_child(_root)
	_build_ui()

func _build_ui() -> void:
	for child: Node in _root.get_children():
		_root.remove_child(child)
		child.queue_free()
	if _drafted.is_empty():
		_build_form()
	else:
		_build_result()

# --- Form ---

# THREE COLUMNS AND A FOOTER, and where each thing goes is not arbitrary:
#
#   left    WHO YOU ARE — scenario, name, seed, your club if you are founding
#           one, and which category you turn out for. Everything that is a
#           sentence about the person rather than a number.
#   middle  the eight attributes and the body, because the body SHIFTS the
#           attributes and reading one while the other is off-screen was the
#           complaint that started all of this.
#   right   the fifteen skills in two lanes, and the twenty-seven talents under
#           them, split by sign.
#
# It was briefly three tabs, when the canvas was 1280x720 and none of this fit.
# At one-to-one on a 1440p monitor it all fits at once, which is better: this is
# a form you compare against itself, and clicking between the halves you are
# comparing is the same problem scrolling was.
func _build_form() -> void:
	_root.add_child(_header())
	_root.add_child(_rule())

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 28)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root.add_child(columns)
	columns.add_child(_left_column())
	columns.add_child(_middle_column())
	columns.add_child(_right_column())

	_root.add_child(_spacer(4))
	_root.add_child(_rule())
	_root.add_child(_footer())

func _column(width: int) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.custom_minimum_size = Vector2(width, 0)
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return box

func _left_column() -> Control:
	var box: VBoxContainer = _column(COL_LEFT)
	box.add_child(_section(UiText.t("manager.origin"), UiText.t("manager.origin_hint")))
	box.add_child(_origin_row())
	box.add_child(_section(UiText.t("manager.identity"), UiText.t("manager.identity_hint")))
	box.add_child(_identity_row())
	box.add_child(_seed_row())
	if _authors_club():
		box.add_child(_section(UiText.t("manager.club"), UiText.t("manager.club_hint")))
		box.add_child(_club_row())
	box.add_child(_section(UiText.t("manager.modality"), UiText.t("manager.plays_hint")))
	box.add_child(_plays_row())
	box.add_child(_manages_row())
	return box

func _middle_column() -> Control:
	var box: VBoxContainer = _column(COL_MID)
	var stats := Drive.def("stat") as StatDef
	box.add_child(_section(UiText.t("manager.attributes"), UiText.t("manager.attributes_hint")))
	if stats != null:
		for id: String in stats.base_ids():
			box.add_child(_attribute_row(stats, id))
	box.add_child(_section(UiText.t("manager.body"), UiText.t("manager.body_hint")))
	box.add_child(_body_row())
	return box

func _right_column() -> Control:
	var box: VBoxContainer = _column(COL_RIGHT)
	var stats := Drive.def("stat") as StatDef
	box.add_child(_section(UiText.t("manager.skills"), UiText.t("manager.skills_hint")))

	var spread := HBoxContainer.new()
	spread.add_theme_constant_override("separation", 20)
	box.add_child(spread)
	var lanes: Array[VBoxContainer] = []
	var lane_width: int = (COL_RIGHT - 20 * (SKILL_COLUMNS - 1)) / SKILL_COLUMNS
	for i: int in range(SKILL_COLUMNS):
		var lane: VBoxContainer = _column(lane_width)
		lanes.append(lane)
		spread.add_child(lane)
	if stats != null:
		# Filled by ROW COUNT and not by group, so the lanes come out even — the
		# four groups are 5/4/3/3 skills, and one lane per group would leave one
		# half empty and another over the column.
		var lane_index: int = 0
		var placed: int = 0
		var per_lane: int = int(ceil((float(stats.skill_ids().size())
			+ float(stats.skill_groups().size())) / float(SKILL_COLUMNS)))
		for group: String in stats.skill_groups():
			if placed >= per_lane and lane_index < SKILL_COLUMNS - 1:
				lane_index += 1
				placed = 0
			lanes[lane_index].add_child(_group_caption(group))
			placed += 1
			for id: String in stats.skills_in_group(group):
				lanes[lane_index].add_child(_skill_row(stats, id))
				placed += 1

	# Talents last, because they are the one thing on this sheet that is not
	# training: you finish the person, then you say what happened to him.
	box.add_child(_section(UiText.t("manager.perks"), UiText.t("manager.perks_hint") % _build.perk_points_left()))
	box.add_child(_perk_row())
	return box

func _group_caption(group: String) -> Control:
	var caption := Label.new()
	caption.text = UiText.t("skillgroup." + group, group)
	caption.add_theme_color_override("font_color", MUTED)
	Look.wear_body(caption, Look.TINY)
	return caption

# One bar across the bottom: what you cannot do yet on the left, and the button
# that leaves on the right. Pinned, so changing the scenario never moves it.
func _footer() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.add_child(_flat_button(UiText.t("common.back"),
		func() -> void: go("back"), false))

	# The literal glyph: GDScript's `\u` escape takes exactly four hex digits, so
	# `\u1F512` is U+1F51 followed by the character "2".
	var pick: Button = _flat_button("\uD83D\uDD12  " + UiText.t("manager.pick_team"), Callable(), false)
	pick.disabled = true
	pick.tooltip_text = UiText.t("manager.pick_locked")
	row.add_child(pick)

	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(gap)

	# The reason it is locked is on the button that is locked, which is where you
	# look when a button will not press. It used to be a sentence beside it.
	var draw_button: Button = _flat_button(UiText.t("manager.random"), _on_draw, true)
	draw_button.disabled = not _build.is_complete()
	draw_button.custom_minimum_size = Vector2(280, 40)
	draw_button.tooltip_text = _draw_hint()
	row.add_child(draw_button)
	return row

# Age and remaining points side by side: the two halves of the same number.
func _header() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)

	var title := Label.new()
	title.text = UiText.t("manager.title")
	title.add_theme_color_override("font_color", TEXT)
	Look.wear_display(title, Look.TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)

	var age := Label.new()
	age.text = UiText.t("manager.years") % _build.age()
	age.add_theme_color_override("font_color", ACCENT)
	Look.wear_display(age, Look.TITLE)
	age.tooltip_text = UiText.t("manager.invest_hint")
	age.mouse_filter = Control.MOUSE_FILTER_STOP
	row.add_child(age)

	var left := Label.new()
	left.text = (UiText.t("manager.overspent") % -_build.remaining()) if _build.remaining() < 0 		else (UiText.t("manager.points_left") % _build.remaining())
	left.add_theme_color_override("font_color", WARN if _build.remaining() != 0 else ACCENT)
	left.tooltip_text = UiText.t("manager.points_hint")
	left.mouse_filter = Control.MOUSE_FILTER_STOP
	Look.wear_display(left, Look.BIG)
	row.add_child(left)
	return row

# Three fields, not one. They are three different things — the surname the
# league table prints, the apelido everyone at the field actually uses — and
# the generator needs them apart to make the apelido cohere with the rest.
# Three scenarios, picked before anything else, because the answer to "why is
# this kid running the club" has to come from the player and not from a shrug.
func _origin_row() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var origins := Drive.def("origin") as OriginDef
	for id: String in (origins.origin_ids() if origins != null else []):
		var chip: Button = _choice(origins.label(id), _origin == id, _on_origin.bind(id))
		chip.custom_minimum_size = Vector2(196, 34)
		chip.tooltip_text = "%s\n%s\n\n%s" % [
			origins.label(id), origins.line(id), origins.desc(id)]
		row.add_child(chip)
	box.add_child(row)
	return box

# TWO ROWS. Three fields plus a labelled dice button measured 769px against a
# 520px column — and the label on the dice was 185px of it, which is a lot of
# width to spend saying what a die already says.
func _identity_row() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	top.add_child(_name_field("first_name", UiText.t("manager.first_name"), 240))
	top.add_child(_name_field("last_name", UiText.t("manager.last_name"), 240))
	box.add_child(top)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 8)
	bottom.add_child(_name_field("nickname", UiText.t("manager.nickname"), 240))
	bottom.add_child(_dice("manager.reroll_all", _on_reroll_all))
	box.add_child(bottom)
	return box

# A die, and the sentence goes on the tooltip. It is the one control on this
# screen that needs no label at all.
func _dice(tip_key: String, on_press: Callable) -> Button:
	var button: Button = _flat_button("🎲", on_press, false)
	button.custom_minimum_size = Vector2(46, 32)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.tooltip_text = UiText.t(tip_key)
	Look.wear_body(button, Look.TEXT)
	return button

# THE CAPTION IS THE PLACEHOLDER. A label above every field was 22px each, and
# with five text fields on this form that is 110px of a 520px column spent
# repeating what the box obviously is. The name survives as the tooltip, so the
# label is still there for anybody who wants it.
func _name_field(key: String, caption: String, width: int) -> Control:
	return _text_field(caption, width, String(_name.get(key, "")),
		_on_name_typed.bind(key))

func _text_field(caption: String, width: int, value: String,
		on_typed: Callable) -> Control:
	var field := LineEdit.new()
	field.text = value
	field.placeholder_text = caption
	field.tooltip_text = caption
	field.custom_minimum_size = Vector2(width, 32)
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.text_changed.connect(on_typed)
	return field

# Read-only, because it is not an input: it is what the three fields above add
# up to. Typing updates it in place — rebuilding the form on every keystroke
# would yank the caret out of the field being used.
# ONE LINE, and no hint under it. What the seed is for is on its tooltip: it is
# read far more often than it is explained, and the explanation was three lines
# of a column that did not have three lines to give.
func _seed_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.tooltip_text = UiText.t("manager.seed_hint")
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	var caption := Label.new()
	caption.text = "SEED"
	caption.add_theme_color_override("font_color", MUTED)
	Look.wear_body(caption, Look.TEXT)
	row.add_child(caption)
	_seed_label = Label.new()
	_seed_label.text = str(_career_seed())
	_seed_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_seed_label.add_theme_color_override("font_color", ACCENT)
	Look.wear_body(_seed_label, Look.TEXT)
	row.add_child(_seed_label)
	return row

# --- The club you are founding ---
#
# Only the Fundador sees this. The other two are drafted into somebody else's
# club and do not get to name it — which is the point of them: picking a
# scenario picks how much of the world is yours.
#
# The fields open PRE-FILLED from the seed rather than blank. A blank name box
# is a wall; a rolled one is a suggestion you can accept in one click or type
# over, and either way the club exists.

func _authors_club() -> bool:
	var origins := Drive.def("origin") as OriginDef
	return origins != null and _origin != "" and origins.authors_club(_origin)

func _club_row() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	top.add_child(_club_field("name", UiText.t("manager.club_name"), 420))
	top.add_child(_dice("manager.club_reroll", _on_reroll_club))
	box.add_child(top)
	var where := HBoxContainer.new()
	where.add_theme_constant_override("separation", 8)
	where.add_child(_club_field("neighborhood", UiText.t("manager.club_neighborhood"), 240))
	where.add_child(_club_field("city", UiText.t("manager.club_city"), 240))
	box.add_child(where)

	# Every width here is CAPPED, because the club name is player-typed and a
	# long one pushed this row two pixels past the column — which is all it took
	# for the panel to measure differently for the Fundador than for the other
	# two scenarios and jump as you clicked between them.
	var colours := HBoxContainer.new()
	colours.add_theme_constant_override("separation", 8)
	var caption: Control = _field_label(UiText.t("manager.club_colors"))
	caption.custom_minimum_size = Vector2(CREST_CAPTION, 0)
	colours.add_child(caption)
	colours.add_child(_palette_button())
	colours.add_child(_crest_preview())
	box.add_child(colours)
	return box

func _club_field(key: String, caption: String, width: int) -> Control:
	return _text_field(caption, width, String(_club.get(key, "")),
		_on_club_typed.bind(key))

# A cycle and not a colour picker. Every pair in the palette is authored to
# clear the contrast floor on its own, so no combination the player can reach
# produces a roster screen nobody can read.
func _palette_button() -> Button:
	var button: Button = _flat_button(UiText.t("manager.club_next_colors"), _on_cycle_colors, false)
	button.custom_minimum_size = Vector2(CREST_BUTTON, 30)
	button.clip_text = true
	button.tooltip_text = UiText.t("manager.club_colors_hint")
	return button

func _crest_preview() -> Control:
	var scheme: Dictionary = TeamColors.of(_club)
	var style := StyleBoxFlat.new()
	style.bg_color = scheme["plate"]
	style.set_content_margin_all(6)
	for corner: String in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		style.set("corner_radius_" + corner, 3)
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", style)
	plate.tooltip_text = UiText.t("manager.club_crest_hint")
	plate.mouse_filter = Control.MOUSE_FILTER_STOP
	var crest := Label.new()
	crest.text = String(_club.get("name", "?"))
	crest.add_theme_color_override("font_color", scheme["ink"])
	# Clipped and capped: the name is typed by the player, and "Associação
	# Atlética Padre Miguel Piranhas" must not be allowed to set a column width.
	crest.clip_text = true
	crest.custom_minimum_size = Vector2(CREST_PLATE, 0)
	Look.wear_body(crest, Look.TINY)
	plate.add_child(crest)
	return plate

func _roll_club() -> void:
	_club = TeamGenerator.found(
		SeedRng.derive(_career_seed(), "founded"), "", "", "", [])

func _on_club_typed(text: String, key: String) -> void:
	_club[key] = text

func _on_reroll_club() -> void:
	_roll_club()
	_build_ui()

func _on_cycle_colors() -> void:
	var current: Array = _club.get("colors", [])
	var head: String = String(current[0]) if not current.is_empty() else ""
	var index: int = 0
	for i: int in range(TeamGenerator.PALETTES.size()):
		if String((TeamGenerator.PALETTES[i] as Array)[0]) == head:
			index = i + 1
			break
	var picked: Array = TeamGenerator.PALETTES[index % TeamGenerator.PALETTES.size()]
	_club["colors"] = picked.duplicate()
	_build_ui()

# --- Perks ---

# One sentence about you, and you may take none. A defect is a perk with a
# negative price: it hands career points back, which is the only reason anybody
# would ever choose to drop passes on purpose.
# TWO BLOCKS, AND THE SIGN IS THE SPLIT: what you buy on the left, what pays you
# on the right. They are different decisions — one spends your balance and one
# funds it — and mixed into one grid in catalogue order you had to read the price
# on every chip to tell which was which.
#
# Grids and not flows. HFlowContainer reports a minimum width that depends on the
# width it was given, so with twenty-seven chips it came back 81px over the
# column's budget and pushed the whole panel past the screen. A grid's minimum is
# the sum of its columns, which is a number that does not argue.
func _perk_row() -> Control:
	var perks := Drive.def("perk") as PerkDef
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", PERK_GAP * 3)
	if perks == null:
		return row
	row.add_child(_perk_block(perks, perks.boons(), UiText.t("manager.perk_boons"),
		BOON_COLUMNS, TALENT_GOOD))
	row.add_child(_perk_block(perks, perks.flaws(), UiText.t("manager.perk_flaws"),
		FLAW_COLUMNS, TALENT_BAD))
	return row

func _perk_block(perks: PerkDef, ids: Array[String], caption: String,
		columns: int, hue: Color) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var label := Label.new()
	label.text = caption
	label.add_theme_color_override("font_color", hue)
	Look.wear_body(label, Look.TINY)
	box.add_child(label)
	var grid := GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", PERK_GAP)
	grid.add_theme_constant_override("v_separation", 2)
	for id: String in ids:
		grid.add_child(_perk_chip(perks, id, columns))
	box.add_child(grid)
	return box

# The two blocks share the right column, split by how many chips each carries.
func _perk_chip_width(columns: int) -> int:
	var share: int = BOON_SHARE if columns == BOON_COLUMNS else COL_RIGHT - BOON_SHARE
	return (share - PERK_GAP * (columns + 1)) / columns

func _perk_chip(perks: PerkDef, id: String, columns: int) -> Control:
	var cost: int = perks.cost(id)
	var price: String = (UiText.t("manager.perk_refund") % -cost) if cost < 0 		else (UiText.t("manager.perk_price") % cost)
	var chip: Button = _choice("%s %s  %s" % [perks.icon(id), perks.label(id), price],
		_build.has_perk(id), _on_perk.bind(id))
	# Green buys you something, red pays you to accept something. The sign is
	# the whole decision, so it should not need reading.
	var hue: Color = TALENT_BAD if cost < 0 else TALENT_GOOD
	chip.add_theme_color_override("font_color", hue)
	chip.add_theme_color_override("font_hover_color", hue.lightened(0.3))
	chip.custom_minimum_size = Vector2(_perk_chip_width(columns), 32)
	# Clipped, because a long name must not be allowed to set the column width —
	# the whole label is on the tooltip that already carries the description.
	chip.clip_text = true
	Look.wear_body(chip, Look.TINY)
	chip.tooltip_text = "%s — %s" % [perks.label(id), perks.desc(id)]
	# Unaffordable is not the same as unchosen: grey it so the player can see
	# the perk exists and costs more than they have left.
	if not _build.has_perk(id) and not _build.can_take_perk(id):
		chip.disabled = true
		chip.add_theme_color_override("font_disabled_color", Color(0.30, 0.34, 0.31))
	return chip



# Height and weight step through the ranges the JSON declares. They cost no
# points: the trade they force IS the price.
func _body_row() -> Control:
	var stats := Drive.def("stat") as StatDef
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	if stats == null:
		return row
	for id: String in stats.measure_ids():
		var spec: Dictionary = stats.measure(id)
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 2)
		cell.tooltip_text = I18n.text(spec.get("desc", ""), "")
		cell.mouse_filter = Control.MOUSE_FILTER_STOP

		var caption := Label.new()
		caption.text = I18n.text(spec.get("label", id), id)
		caption.add_theme_color_override("font_color", MUTED)
		Look.wear_body(caption, Look.TINY)
		cell.add_child(caption)

		# A SpinBox, not steppers: someone entering their own 1,83 m should type
		# it, not click twenty-eight times.
		var field := SpinBox.new()
		field.min_value = float(spec.get("min", 0.0))
		field.max_value = float(spec.get("max", 999.0))
		field.step = stats.increment(id)
		field.value = _measure_value(id)
		field.suffix = String(spec.get("unit", ""))
		field.custom_minimum_size = Vector2(170, 32)
		field.value_changed.connect(_on_measure_value.bind(id))
		cell.add_child(field)
		row.add_child(cell)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	box.add_child(row)

	# UNDER the fields, and wrapping. As a fourth cell on the same line this was
	# a 432px unbroken sentence listing every shift the body performs, which on
	# its own made the attributes column more than twice its budget.
	var effect: Dictionary = stats.body_effect({"height": _build.height, "weight": _build.weight})
	var summary := Label.new()
	summary.text = _effect_text(stats, effect)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.custom_minimum_size = Vector2(COL_MID, 0)
	summary.add_theme_color_override("font_color", WARN)
	Look.wear_body(summary, Look.TINY)
	box.add_child(summary)

	var price := Label.new()
	price.text = UiText.t("manager.body_cost") % _build.body_cost()
	price.add_theme_color_override("font_color", MUTED if _build.body_cost() == 0 else ACCENT)
	Look.wear_body(price, Look.TINY)
	box.add_child(price)
	return box

# Reads the shift the body performs, so the player sees the trade before paying
# for it.
func _effect_text(stats: StatDef, effect: Dictionary) -> String:
	var parts: Array[String] = []
	for id: String in effect.keys():
		var value: int = int(effect[id])
		if value == 0:
			continue
		parts.append("%+d %s" % [value, I18n.text(stats.base_stat(id).get("label", id), id)])
	return "   ".join(parts)

# THREE LETTERS IN A FIXED COLUMN. "Chamada de jogada" is seventeen characters
# beside a ten-slot bar, and twenty-three rows of that read as a classified ad
# rather than a sheet. The name and the description are one hover away, where
# they stop competing with the numbers and start being a tutorial.
func _track_code(code: String) -> Control:
	var label := Label.new()
	label.text = code
	label.custom_minimum_size = Vector2(CODE_WIDTH, 0)
	label.add_theme_color_override("font_color", TEXT)
	Look.wear_body(label, Look.TEXT)
	return label

func _attribute_row(stats: StatDef, id: String) -> Control:
	var spec: Dictionary = stats.base_stat(id)
	var step_value: int = int(_build.stats.get(id, 0))
	var shift: int = int(stats.body_effect(
		{"height": _build.height, "weight": _build.weight}).get(id, 0))
	var effective: int = clampi(step_value + shift, 0, StatDef.MAX_STEP)
	var bonus: int = effective - stats.average_step

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	row.tooltip_text = "%s\n\n%d/10%s\n%s" % [
		stats.explain(id), effective,
		"   (%+d do corpo)" % shift if shift != 0 else "",
		UiText.t("manager.team_bonus") % bonus,
	]
	row.mouse_filter = Control.MOUSE_FILTER_STOP

	row.add_child(_step_button("−", _on_lower_stat.bind(id), _build.can_lower_stat(id),
		UiText.t("manager.step_down")))
	row.add_child(_step_button("+", _on_raise_stat.bind(id), _build.can_raise_stat(id),
		UiText.t("manager.step_up") % maxi(_build.cost_to_raise_stat(id), 0)))

	row.add_child(_track_code(stats.code(id)))
	# The RAW value, not the effective one. The bar used to include the body
	# shift while the minus button read the raw number, so an attribute at zero
	# with a tall body drew as "1" and refused to come down — you were stuck at
	# a step you never bought.
	row.add_child(StatBar.bar(step_value * 10, stats.chakra_color(id)))

	var mod := Label.new()
	mod.text = "%+d" % bonus if bonus != 0 else "·"
	mod.custom_minimum_size = Vector2(26, 0)
	mod.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mod.add_theme_font_size_override("font_size", 12)
	mod.add_theme_color_override("font_color",
		ACCENT if bonus > 0 else (WARN if bonus < 0 else MUTED))
	row.add_child(mod)

	var cost := Label.new()
	var next_cost: int = _build.cost_to_raise_stat(id)
	cost.text = str(next_cost) if next_cost >= 0 else "—"
	cost.custom_minimum_size = Vector2(22, 0)
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cost.add_theme_font_size_override("font_size", 11)
	cost.add_theme_color_override("font_color", MUTED)
	row.add_child(cost)
	return row

func _skill_row(stats: StatDef, id: String) -> Control:
	var spec: Dictionary = stats.skill(id)
	var step_value: int = int(_build.skills.get(id, 0))
	var attribute: String = stats.skill_attribute(id)
	var attribute_step: int = int(_build.stats.get(attribute, 0))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	row.tooltip_text = "%s\n\n%s %d + %s %d\n%s" % [
		stats.explain(id),
		stats.code(attribute), attribute_step, stats.code(id), step_value,
		UiText.t("manager.roll_hint") % (attribute_step + step_value),
	]
	row.mouse_filter = Control.MOUSE_FILTER_STOP

	row.add_child(_step_button("−", _on_lower_skill.bind(id), _build.can_lower_skill(id),
		UiText.t("manager.step_down")))
	row.add_child(_step_button("+", _on_raise_skill.bind(id), _build.can_raise_skill(id),
		UiText.t("manager.step_up") % maxi(_build.cost_to_raise_skill(id), 0)))

	row.add_child(_track_code(stats.code(id)))
	row.add_child(StatBar.bar(step_value * 10, stats.skill_color(id)))

	var cost := Label.new()
	var next_cost: int = _build.cost_to_raise_skill(id)
	cost.text = str(next_cost) if next_cost >= 0 else "—"
	cost.custom_minimum_size = Vector2(22, 0)
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cost.add_theme_font_size_override("font_size", 11)
	cost.add_theme_color_override("font_color", MUTED)
	row.add_child(cost)
	return row

# Not a single choice. You can play the men's side and the mixed side, or the
# women's and the mixed, or one, or none — and the chips have to say so, which
# they did not: forcing one selection made "mixed" read as though it implied a
# men's slot when it implies nothing at all.
func _plays_row() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	# Wraps. Four chips behind a 120px label came to 576px in a 520px column, and
	# a chip that fits on the next line is not a problem — it is a chip.
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 6)
	row.add_theme_constant_override("v_separation", 4)
	row.add_child(_field_label(UiText.t("manager.plays")))
	var categories := Drive.def("category") as CategoryDef
	for id: String in (categories.category_ids() if categories != null else []):
		var chip: Button = _choice(
			categories.category_label(id), _plays.has(id), _on_plays.bind(id))
		# Mixed needs a base under it: the quota has to know which slot you
		# fill. Greyed rather than hidden, so the rule is visible.
		if id == Actor.CATEGORY_MISTO and not _plays_has_base():
			chip.disabled = true
			chip.tooltip_text = UiText.t("manager.plays_hint")
		row.add_child(chip)
	row.add_child(_choice(UiText.t("manager.plays_none"), _plays.is_empty(), _on_plays_none))
	box.add_child(row)
	return box

func _plays_has_base() -> bool:
	return _plays.has(Actor.CATEGORY_MASC) or _plays.has(Actor.CATEGORY_FEM)

func _manages_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.add_child(_field_label(UiText.t("manager.manages")))
	var categories := Drive.def("category") as CategoryDef
	var value := Label.new()
	value.text = categories.category_label(Actor.CATEGORY_MASC) if categories != null else Actor.CATEGORY_MASC
	value.add_theme_color_override("font_color", MUTED)
	row.add_child(value)
	return row

# Three states, not two: ready, still holding points, or holding a remainder
# too small to spend. The third used to read as the second and locked the
# player in place.
func _draw_hint() -> String:
	if not _build.is_complete():
		return UiText.t("manager.must_spend") % _build.remaining()
	if _build.remaining() == 1:
		return UiText.t("manager.leftover_one")
	if _build.remaining() > 0:
		return UiText.t("manager.leftover_many") % _build.remaining()
	return UiText.t("manager.random_hint")

# --- Result ---

func _build_result() -> void:
	_root.add_child(_spacer(16))
	var lead := Label.new()
	lead.text = UiText.t("manager.drafted")
	lead.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lead.add_theme_color_override("font_color", MUTED)
	_root.add_child(lead)

	var scheme: Dictionary = TeamColors.of(_drafted)
	var style := StyleBoxFlat.new()
	style.bg_color = scheme["plate"]
	style.set_content_margin_all(16)
	for corner: String in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		style.set("corner_radius_" + corner, 4)
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", style)
	plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_root.add_child(plate)

	var club := Label.new()
	club.text = String(_drafted.get("name", "?"))
	club.add_theme_color_override("font_color", scheme["ink"])
	club.add_theme_font_size_override("font_size", 32)
	plate.add_child(club)

	var where := Label.new()
	var teams := Drive.def("team") as TeamDef
	where.text = "%s/%s   ·   %s" % [
		teams.where(_drafted) if teams != null else _drafted.get("city", "?"),
		_drafted.get("state", "?"),
		UiText.t("tier.%d" % int(_drafted.get("tier", 4)))]
	where.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	where.add_theme_color_override("font_color", MUTED)
	_root.add_child(where)

	if not _club_fields_my_category():
		var warning := Label.new()
		warning.text = "⚠  " + UiText.t("manager.not_fielded")
		warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		warning.add_theme_font_size_override("font_size", 12)
		warning.add_theme_color_override("font_color", WARN)
		_root.add_child(warning)

	_root.add_child(_spacer(18))
	_root.add_child(_flat_button(UiText.t("manager.start"), _on_start, true))

# One squad you can turn out for is enough; the warning is for the club that
# fields none of them.
func _club_fields_my_category() -> bool:
	if _plays.is_empty():
		return true
	var squads: Dictionary = _drafted.get("squads", {})
	for id: String in _plays:
		if bool(squads.get(id, false)):
			return true
	return false

# --- Actions ---

func _on_raise_stat(id: String) -> void:
	_build.raise_stat(id)
	_build_ui()

func _on_lower_stat(id: String) -> void:
	_build.lower_stat(id)
	_build_ui()

func _on_raise_skill(id: String) -> void:
	_build.raise_skill(id)
	_build_ui()

func _on_lower_skill(id: String) -> void:
	_build.lower_skill(id)
	_build_ui()

# Redraws only when the value crosses a band. Typing 1,81 then 1,82 changes
# nothing on the sheet, so rebuilding would just yank the caret out of the
# field the player is still using.
func _on_measure_value(value: float, id: String) -> void:
	var stats := Drive.def("stat") as StatDef
	if stats == null:
		return
	var before: int = stats.band(id, _measure_value(id))
	if id == "height":
		_build.height = snappedf(value, 0.01)
	else:
		_build.weight = snappedf(value, 1.0)
	if stats.band(id, value) != before:
		_build_ui()

# Never rebuilds the form: the seed label is the only thing a keystroke can
# change, and redrawing would take the caret with it.
func _on_name_typed(text: String, key: String) -> void:
	_name[key] = text.strip_edges()
	if is_instance_valid(_seed_label):
		_seed_label.text = str(_career_seed())

# One button, everything at once: a new person AND the world that person was
# born into. Name, surname, apelido, a fresh twelve-year-old and maybe a perk.
#
# Exactly the roll the screen opened with, on purpose. A second kind of roll
# that spent the whole 414 would hand back a finished adult, and then the six
# years the screen exists to ask about would already be gone.
func _on_reroll_all() -> void:
	var rng: RandomNumberGenerator = _free_rng()
	_build = SheetBuilder.rolled_opening(rng, _origin)
	_name = _roll_name(rng)
	if _authors_club():
		_roll_club()
	_build_ui()

# Changing the scenario rerolls, because a sheet built as an ex-player is not
# the sheet a student would have. The six spare years survive either way.
func _on_origin(id: String) -> void:
	_origin = id
	_build = SheetBuilder.rolled_opening(_free_rng(), _origin)
	if _authors_club() and _club.is_empty():
		_roll_club()
	_build_ui()

func _on_perk(id: String) -> void:
	_build.toggle_perk(id)
	_build_ui()

func _on_plays(category: String) -> void:
	if _plays.has(category):
		_plays.erase(category)
		# Dropping the base drops the mixed side with it — nobody plays mixed
		# without a slot to fill.
		if not _plays_has_base():
			_plays.erase(Actor.CATEGORY_MISTO)
	else:
		if category == Actor.CATEGORY_MASC:
			_plays.erase(Actor.CATEGORY_FEM)
		elif category == Actor.CATEGORY_FEM:
			_plays.erase(Actor.CATEGORY_MASC)
		_plays.append(category)
	_build_ui()

func _on_plays_none() -> void:
	_plays.clear()
	_build_ui()

func _on_draw() -> void:
	var def := Drive.def("team") as TeamDef
	if def == null:
		return
	# A FOUNDER IS NOT DRAFTED. There is no club to be drafted into — that is
	# the whole scenario — so the club he has been editing IS the answer, and
	# the sandlot around him is still built, because he needs somebody to play.
	if _authors_club():
		League.ensure_filled(_career_seed())
		if _club.is_empty():
			_roll_club()
		_drafted = _club.duplicate(true)
		_build_ui()
		return
	# Built here and not while typing: the sandlot clubs come from the seed the
	# three fields ended up spelling, and nobody needs six clubs invented per
	# keystroke.
	var career_seed: int = _career_seed()
	League.ensure_filled(career_seed)
	var pool: Array = def.by_tier(TeamGenerator.TIER_UNAFFILIATED)
	if pool.is_empty():
		Log.log(self, "error", "CreateManager: no tier-4 club to draft into.")
		return
	var rng: RandomNumberGenerator = SeedRng.make_rng(SeedRng.derive(career_seed, "draft"))
	_drafted = pool[rng.randi() % pool.size()]
	_build_ui()

func _on_start() -> void:
	var career_seed: int = _career_seed()
	# The founded club has to EXIST before the career points at it. Every screen
	# after this one reads clubs out of TeamDef, and a career whose team_id
	# resolves to nothing is the same bug that made "Onças da Pista" vanish.
	var teams := Drive.def("team") as TeamDef
	if _authors_club() and teams != null \
			and teams.get_team(String(_drafted.get("id", ""))).is_empty():
		teams.add_thing(_drafted)
	var manager: Actor = _build.to_actor(career_seed, _name)
	manager.set_plays(_plays)
	manager.set_manages([Actor.CATEGORY_MASC])
	manager.set_team(String(_drafted.get("id", "")))
	manager.data["origin"] = _origin
	write("career", Career.make(manager, String(_drafted.get("id", "")), career_seed))
	go("created")

# --- Internals ---

# The seed IS the name. Hashing nome + sobrenome + apelido means two players
# who type the same three words get the same world — and a player who liked a
# roll can write the three down and come back to it. Zero is reserved as
# "nothing built yet" by League, so it never leaves here.
func _career_seed() -> int:
	var spelled: String = "%s|%s|%s" % [
		_name.get("first_name", ""), _name.get("last_name", ""), _name.get("nickname", "")]
	return maxi(absi(SeedRng.seed_from_string(spelled)), 1)

# Drawn from BOTH pools, which is what asking about categories instead of
# identity buys us: no gender question, and the player still gets a name they
# like — or types their own.
#
# The apelido comes last on purpose: it is drawn from the sheet that was just
# rolled, so a manager with 9 agility can come out as Foguete.
func _roll_name(rng: RandomNumberGenerator) -> Dictionary:
	var names := Drive.def("name_gen") as NameGenDef
	if names == null:
		return {"first_name": "", "last_name": "", "nickname": ""}
	var pool: String = Actor.CATEGORY_FEM if rng.randf() < 0.5 else Actor.CATEGORY_MASC
	var first: String = names.random_first_name(pool, rng)
	var last: String = names.random_last_name(rng)
	return {
		"first_name": first,
		"last_name": last,
		"nickname": names.nickname_for(first, last, pool, _traits(), rng),
	}

# What the current build is notable for, in the steps the nickname table reads.
func _traits() -> Array:
	var stats := Drive.def("stat") as StatDef
	return stats.notable_traits(_build.stats, _build.skills) if stats != null else []

func _measure_value(id: String) -> float:
	return _build.height if id == "height" else _build.weight

# The one RNG on this screen that is NOT seeded: pressing 🎲 must give you
# something new, and seeding it from the thing it is about to overwrite would
# make the button a fixed point.
func _free_rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return rng

# --- Widgets ---

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	# 12, not 26. On a 720px canvas the panel's own padding was 52px of it — the
	# frame was eating a section.
	style.set_content_margin_all(20)
	style.border_color = LINE
	style.set_border_width_all(1)
	for corner: String in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		style.set("corner_radius_" + corner, 5)
	return style

# A HEADING AND A TOOLTIP. Every one of these used to carry two lines of prose
# explaining what the section was for, and six of them turned the form into a
# page of small print that you read once and then had to look past forever.
#
# The explanation did not get deleted — it moved to where an explanation belongs,
# which is one hover away and permanently available rather than permanently in
# the way.
func _section(text: String, tip: String = "") -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	box.add_child(_spacer(5))
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", ACCENT)
	Look.wear_display(label, Look.HEADING)
	if tip != "":
		label.tooltip_text = tip
		label.mouse_filter = Control.MOUSE_FILTER_STOP
	box.add_child(label)
	box.add_child(_rule())
	return box

func _rule() -> Control:
	var line := ColorRect.new()
	line.color = LINE
	line.custom_minimum_size = Vector2(0, 1)
	return line

func _field_label(text: String) -> Control:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(120, 0)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", TEXT)
	return label

func _step_button(text: String, on_press: Callable, enabled: bool,
		tip: String = "") -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(24, 24)
	if tip != "":
		button.tooltip_text = tip
	button.focus_mode = Control.FOCUS_NONE
	button.disabled = not enabled
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.16, 0.12)
	style.border_color = Color(0.20, 0.27, 0.21)
	style.set_border_width_all(1)
	for corner: String in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		style.set("corner_radius_" + corner, 2)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("disabled", style)
	button.add_theme_color_override("font_color", ACCENT)
	button.add_theme_color_override("font_disabled_color", Color(0.24, 0.28, 0.25))
	if on_press.is_valid():
		button.pressed.connect(on_press)
	return button

# A selected option must look CHOSEN, not switched off. Godot's `disabled`
# greys a button out, which reads as "you cannot press this".
func _choice(text: String, selected: bool, on_press: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(108, 32)
	button.toggle_mode = true
	button.button_pressed = selected
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", _chip_style(false))
	button.add_theme_stylebox_override("hover", _chip_style(false, true))
	button.add_theme_stylebox_override("pressed", _chip_style(true))
	button.add_theme_stylebox_override("hover_pressed", _chip_style(true))
	button.add_theme_color_override("font_color", MUTED)
	button.add_theme_color_override("font_pressed_color", Color(0.05, 0.09, 0.05))
	button.add_theme_color_override("font_hover_color", TEXT)
	if on_press.is_valid():
		button.pressed.connect(on_press)
	return button

func _chip_style(selected: bool, hovered: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if selected:
		style.bg_color = ACCENT
	else:
		style.bg_color = Color(0.13, 0.18, 0.14) if hovered else Color(0.10, 0.14, 0.11)
	style.border_color = ACCENT if selected else Color(0.20, 0.27, 0.21)
	style.set_border_width_all(1)
	style.set_content_margin_all(5)
	for corner: String in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		style.set("corner_radius_" + corner, 3)
	return style

func _flat_button(text: String, on_press: Callable, primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 38 if primary else 30)
	button.add_theme_color_override("font_color", Color(0.05, 0.09, 0.05) if primary else TEXT)
	var style := StyleBoxFlat.new()
	style.bg_color = ACCENT if primary else Color(0.11, 0.15, 0.12)
	style.border_color = ACCENT if primary else Color(0.20, 0.27, 0.21)
	style.set_border_width_all(1)
	style.set_content_margin_all(7)
	for corner: String in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		style.set("corner_radius_" + corner, 3)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("disabled", style)
	if on_press.is_valid():
		button.pressed.connect(on_press)
	return button

func _spacer(height: int) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	return spacer
