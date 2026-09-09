# Create Manager — you, at 18, about to be called by a sandlot club.
#
# Produces the `career` Record onto the Blackboard. The Flow gates every later
# step on its presence, so this screen is the only place a career begins.
#
# Two things it deliberately does NOT ask:
#   • your gender — it asks which CATEGORY you play, which is the thing the
#     game actually needs and the thing that is true of people (decision 17)
#   • which club you want — Pick Team is locked until a national round is won
#
# Name and seed are separate on purpose. The seed defines the whole universe of
# the run; the name is just what you are called. Rerolling one must never
# disturb the other.
extends Menu

# 18 and unproven. The manager's own strength grows with results (decision 12),
# so starting low is what gives that growth somewhere to go.
const START_AGE := 18
const START_QUALITY := 40

const BG := Color(0.055, 0.078, 0.063)
const PANEL := Color(0.086, 0.118, 0.094)
const ACCENT := Color(0.49, 0.78, 0.45)
const MUTED := Color(0.47, 0.52, 0.48)
const TEXT := Color(0.87, 0.90, 0.87)
const LINE := Color(0.16, 0.22, 0.17)

var _career_seed: int = 0
var _manager: Actor = null
var _plays: String = Actor.CATEGORY_MASC
var _drafted: Dictionary = {}
var _name_field: LineEdit = null
var _root: VBoxContainer = null

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reseed(_new_seed())

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
	panel.custom_minimum_size = Vector2(620, 0)
	center.add_child(panel)

	_root = VBoxContainer.new()
	_root.add_theme_constant_override("separation", 10)
	panel.add_child(_root)
	_build_ui()

func _build_ui() -> void:
	for child: Node in _root.get_children():
		_root.remove_child(child)
		child.queue_free()

	var title := Label.new()
	title.text = UiText.t("manager.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", TEXT)
	_root.add_child(title)
	_root.add_child(_rule())

	if _drafted.is_empty():
		_build_form()
	else:
		_build_result()

# --- Form ---

func _build_form() -> void:
	_root.add_child(_section(UiText.t("manager.identity")))
	_root.add_child(_name_row())
	_root.add_child(_seed_row())

	_root.add_child(_section(UiText.t("manager.body")))
	_root.add_child(_body_grid())

	_root.add_child(_section("%s   ·   %s %d" % [
		UiText.t("manager.sheet"), UiText.t("manager.overall"), _manager.overall()]))
	_root.add_child(_attributes())

	_root.add_child(_section(UiText.t("manager.modality")))
	_root.add_child(_plays_row())
	_root.add_child(_manages_row())

	_root.add_child(_section(UiText.t("manager.career_type")))
	_root.add_child(_career_type())

	_root.add_child(_spacer(6))
	_root.add_child(_flat_button(UiText.t("common.back"), func() -> void: go("back"), false))

func _name_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_field_label(UiText.t("manager.name")))

	_name_field = LineEdit.new()
	_name_field.text = _manager.full_name()
	_name_field.custom_minimum_size = Vector2(280, 34)
	_name_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_name_field)
	row.add_child(_flat_button("🎲 " + UiText.t("manager.reroll_name"), _on_reroll_name, false))
	return row

# The seed sits beside the name but is a different kind of thing, and the hint
# says so: rerolling it rebuilds the universe, not just the label.
func _seed_row() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_field_label("Seed"))

	var value := Label.new()
	value.text = str(_career_seed)
	value.custom_minimum_size = Vector2(280, 0)
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.add_theme_color_override("font_color", ACCENT)
	row.add_child(value)
	row.add_child(_flat_button("🎲 " + UiText.t("manager.reroll_seed"), _on_reroll_seed, false))
	box.add_child(row)
	box.add_child(_hint(UiText.t("manager.seed_hint")))
	return box

# Measures, not attributes: real units, no bars.
func _body_grid() -> Control:
	var stats := Drive.def("stat") as StatDef
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 34)

	grid.add_child(_measure_cell(UiText.t("manager.age_label"),
		UiText.t("manager.years") % _manager.age(), ""))
	if stats == null:
		return grid
	for id: String in stats.measure_ids():
		var spec: Dictionary = stats.measure(id)
		grid.add_child(_measure_cell(
			I18n.text(spec.get("label", id), id),
			stats.format_measure(id, _manager.measure(id)),
			I18n.text(spec.get("desc", ""), "")))
	return grid

func _measure_cell(label_text: String, value_text: String, tooltip: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	box.tooltip_text = tooltip
	box.mouse_filter = Control.MOUSE_FILTER_STOP

	var caption := Label.new()
	caption.text = label_text
	caption.add_theme_font_size_override("font_size", 11)
	caption.add_theme_color_override("font_color", MUTED)
	box.add_child(caption)

	var value := Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 17)
	value.add_theme_color_override("font_color", TEXT)
	box.add_child(value)
	return box

func _attributes() -> Control:
	var stats := Drive.def("stat") as StatDef
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	if stats == null:
		return box
	for id: String in stats.base_ids():
		var spec: Dictionary = stats.base_stat(id)
		box.add_child(StatBar.row(
			I18n.text(spec.get("label", id), id),
			_manager.stat(id),
			I18n.text(spec.get("desc", ""), "")))
	return box

# Free choice, independent of any club: you might play the men's side, the
# women's, the mixed, or not play at all.
func _plays_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.add_child(_field_label(UiText.t("manager.plays")))

	var categories := Drive.def("category") as CategoryDef
	for id: String in (categories.category_ids() if categories != null else []):
		row.add_child(_choice(categories.category_label(id), _plays == id, _on_plays.bind(id)))
	row.add_child(_choice(UiText.t("manager.plays_none"), _plays == "", _on_plays.bind("")))
	return row

# Not a choice yet: the draft lands you in a tier-4 club, and every one of them
# fields only a men's side. It becomes a real choice the day a club has two.
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

func _career_type() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)

	var pick: Button = _flat_button("🔒  " + UiText.t("manager.pick_team"), Callable(), false)
	pick.disabled = true
	box.add_child(pick)
	box.add_child(_hint(UiText.t("manager.pick_locked")))

	box.add_child(_spacer(4))
	box.add_child(_flat_button(UiText.t("manager.random"), _on_draw, true))
	box.add_child(_hint(UiText.t("manager.random_hint")))
	return box

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
	club.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	club.add_theme_color_override("font_color", scheme["ink"])
	club.add_theme_font_size_override("font_size", 32)
	plate.add_child(club)

	var where := Label.new()
	where.text = "%s/%s   ·   %s" % [
		_drafted.get("city", "?"), _drafted.get("state", "?"),
		UiText.t("tier.%d" % int(_drafted.get("tier", 4))),
	]
	where.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	where.add_theme_color_override("font_color", MUTED)
	_root.add_child(where)

	if not _club_fields_my_category():
		var warning := Label.new()
		warning.text = "⚠  " + UiText.t("manager.not_fielded")
		warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		warning.add_theme_font_size_override("font_size", 12)
		warning.add_theme_color_override("font_color", Color(0.85, 0.72, 0.45))
		_root.add_child(warning)

	_root.add_child(_spacer(18))
	_root.add_child(_flat_button(UiText.t("manager.start"), _on_start, true))

# You may play a category your club does not field — the author played men's
# and coached women's. The game says so instead of pretending it cannot happen.
func _club_fields_my_category() -> bool:
	if _plays == "":
		return true
	return bool((_drafted.get("squads", {}) as Dictionary).get(_plays, false))

# --- Actions ---

# Name only. The universe stays exactly as it was.
func _on_reroll_name() -> void:
	var names := Drive.def("name_gen") as NameGenDef
	if names == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var pool: String = Actor.CATEGORY_FEM if rng.randf() < 0.5 else Actor.CATEGORY_MASC
	_manager.data["first_name"] = names.random_first_name(pool, rng)
	_manager.data["last_name"] = names.random_last_name(rng)
	_build_ui()

# Seed only. Rebuilds the manager, the sandlot clubs, everything.
func _on_reroll_seed() -> void:
	_reseed(_new_seed())
	_build_ui()

func _on_plays(category: String) -> void:
	_plays = category
	_build_ui()

func _on_draw() -> void:
	_commit_name()
	var def := Drive.def("team") as TeamDef
	if def == null:
		return
	var pool: Array = def.by_tier(TeamGenerator.TIER_UNAFFILIATED)
	if pool.is_empty():
		Log.log(self, "error", "CreateManager: no tier-4 club to draft into.")
		return
	var rng: RandomNumberGenerator = SeedRng.make_rng(SeedRng.derive(_career_seed, "draft"))
	_drafted = pool[rng.randi() % pool.size()]
	_build_ui()

func _on_start() -> void:
	_manager.set_plays([_plays] if _plays != "" else [])
	_manager.set_manages([Actor.CATEGORY_MASC])
	_manager.set_team(String(_drafted.get("id", "")))
	write("career", Career.make(_manager, String(_drafted.get("id", "")), _career_seed))
	go("created")

# --- Internals ---

func _reseed(value: int) -> void:
	_career_seed = value
	League.ensure_filled(_career_seed)
	_manager = _roll_manager()

func _commit_name() -> void:
	if _name_field == null:
		return
	var typed: String = _name_field.text.strip_edges()
	if typed == "":
		return
	var parts: PackedStringArray = typed.split(" ", false)
	_manager.data["first_name"] = parts[0]
	_manager.data["last_name"] = " ".join(parts.slice(1)) if parts.size() > 1 else ""

# The manager's name is drawn from BOTH pools, which is what asking about
# categories instead of identity buys us: no gender question, and the player
# still gets a name they like — or types their own.
func _roll_manager() -> Actor:
	var actor: Actor = ActorGenerator.generate(
		SeedRng.derive(_career_seed, "manager"), START_QUALITY, Actor.CATEGORY_MISTO,
		ActorGenerator.SPREAD, START_AGE, START_AGE)
	actor.set_plays([])
	actor.set_manages([Actor.CATEGORY_MASC])
	return actor

func _new_seed() -> int:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi_range(1, 99999999)

# --- Widgets ---

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.set_content_margin_all(30)
	style.border_color = LINE
	style.set_border_width_all(1)
	for corner: String in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		style.set("corner_radius_" + corner, 5)
	return style

func _section(text: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.add_child(_spacer(8))
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", ACCENT)
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
	label.custom_minimum_size = Vector2(130, 0)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", TEXT)
	return label

func _hint(text: String) -> Control:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", MUTED)
	return label

# A selected option must look CHOSEN, not switched off. Godot's `disabled`
# greys a button out, which reads as "you cannot press this" — the opposite of
# what a picked option means.
func _choice(text: String, selected: bool, on_press: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(112, 34)
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
	style.set_content_margin_all(6)
	for corner: String in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		style.set("corner_radius_" + corner, 3)
	return style

func _flat_button(text: String, on_press: Callable, primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 40 if primary else 32)
	button.add_theme_color_override("font_color", Color(0.05, 0.09, 0.05) if primary else TEXT)
	var style := StyleBoxFlat.new()
	style.bg_color = ACCENT if primary else Color(0.11, 0.15, 0.12)
	style.border_color = ACCENT if primary else Color(0.20, 0.27, 0.21)
	style.set_border_width_all(1)
	style.set_content_margin_all(8)
	for corner: String in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		style.set("corner_radius_" + corner, 3)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	if on_press.is_valid():
		button.pressed.connect(on_press)
	return button

func _spacer(height: int) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	return spacer
