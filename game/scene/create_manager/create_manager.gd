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
# for the player would empty the screen. 🎲 is the other verb, and it spends
# everything.
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

var _build: SheetBuilder = null
var _name: Dictionary = {}
var _plays: String = Actor.CATEGORY_MASC
var _drafted: Dictionary = {}
var _seed_label: Label = null
var _root: VBoxContainer = null

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var rng: RandomNumberGenerator = _free_rng()
	_build = SheetBuilder.rolled_opening(rng)
	_name = _roll_name(rng)

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
	panel.custom_minimum_size = Vector2(940, 0)
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

func _build_form() -> void:
	_root.add_child(_header())
	_root.add_child(_rule())
	_root.add_child(_identity_row())
	_root.add_child(_seed_row())
	_root.add_child(_section(UiText.t("manager.body"), UiText.t("manager.body_hint")))
	_root.add_child(_body_row())
	_root.add_child(_section(UiText.t("manager.perks"), UiText.t("manager.perks_hint")))
	_root.add_child(_perk_row())
	_root.add_child(_perk_detail())

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 40)
	_root.add_child(columns)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 4)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(_section(UiText.t("manager.attributes"), ""))
	columns.add_child(left)
	var stats := Drive.def("stat") as StatDef
	if stats != null:
		for id: String in stats.base_ids():
			left.add_child(_attribute_row(stats, id))

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 4)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(_section(UiText.t("manager.skills"), ""))
	columns.add_child(right)
	if stats != null:
		for group: String in stats.skill_groups():
			var caption := Label.new()
			caption.text = UiText.t("skillgroup." + group, group)
			caption.add_theme_font_size_override("font_size", 11)
			caption.add_theme_color_override("font_color", MUTED)
			right.add_child(caption)
			for id: String in stats.skills_in_group(group):
				right.add_child(_skill_row(stats, id))

	_root.add_child(_section(UiText.t("manager.modality"), ""))
	_root.add_child(_plays_row())
	_root.add_child(_manages_row())
	_root.add_child(_section(UiText.t("manager.career_type"), ""))
	_root.add_child(_career_type())
	_root.add_child(_spacer(4))
	_root.add_child(_flat_button(UiText.t("common.back"), func() -> void: go("back"), false))

# Age and remaining points side by side: the two halves of the same number.
func _header() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)

	var title := Label.new()
	title.text = UiText.t("manager.title")
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)

	var age := Label.new()
	age.text = UiText.t("manager.years") % _build.age()
	age.add_theme_font_size_override("font_size", 30)
	age.add_theme_color_override("font_color", ACCENT)
	age.tooltip_text = UiText.t("manager.invest_hint")
	age.mouse_filter = Control.MOUSE_FILTER_STOP
	row.add_child(age)

	var left := Label.new()
	left.text = (UiText.t("manager.overspent") % -_build.remaining()) if _build.remaining() < 0 		else (UiText.t("manager.points_left") % _build.remaining())
	left.add_theme_font_size_override("font_size", 18)
	left.add_theme_color_override("font_color", WARN if _build.remaining() != 0 else ACCENT)
	row.add_child(left)
	return row

# Three fields, not one. They are three different things — the surname the
# league table prints, the apelido everyone at the field actually uses — and
# the generator needs them apart to make the apelido cohere with the rest.
func _identity_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_name_field("first_name", UiText.t("manager.first_name"), 200))
	row.add_child(_name_field("last_name", UiText.t("manager.last_name"), 200))
	row.add_child(_name_field("nickname", UiText.t("manager.nickname"), 160))
	row.add_child(_flat_button("🎲 " + UiText.t("manager.reroll_all"), _on_reroll_all, false))
	return row

func _name_field(key: String, caption: String, width: int) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := Label.new()
	label.text = caption
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", MUTED)
	box.add_child(label)
	var field := LineEdit.new()
	field.text = String(_name.get(key, ""))
	field.custom_minimum_size = Vector2(width, 32)
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.text_changed.connect(_on_name_typed.bind(key))
	box.add_child(field)
	return box

# Read-only, because it is not an input: it is what the three fields above add
# up to. Typing updates it in place — rebuilding the form on every keystroke
# would yank the caret out of the field being used.
func _seed_row() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_field_label("Seed"))
	_seed_label = Label.new()
	_seed_label.text = str(_career_seed())
	_seed_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_seed_label.add_theme_color_override("font_color", ACCENT)
	row.add_child(_seed_label)
	box.add_child(row)
	box.add_child(_hint(UiText.t("manager.seed_hint")))
	return box

# --- Perks ---

# One sentence about you, and you may take none. A defect is a perk with a
# negative price: it hands career points back, which is the only reason anybody
# would ever choose to drop passes on purpose.
func _perk_row() -> Control:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	var perks := Drive.def("perk") as PerkDef
	if perks == null:
		return flow
	for id: String in perks.perk_ids():
		flow.add_child(_perk_chip(perks, id))
	return flow

func _perk_chip(perks: PerkDef, id: String) -> Control:
	var cost: int = perks.cost(id)
	var price: String = (UiText.t("manager.perk_refund") % -cost) if cost < 0 		else (UiText.t("manager.perk_price") % cost)
	var chip: Button = _choice("%s %s  %s" % [perks.icon(id), perks.label(id), price],
		_build.perk == id, _on_perk.bind(id))
	chip.custom_minimum_size = Vector2(0, 32)
	chip.tooltip_text = perks.desc(id)
	# Unaffordable is not the same as unchosen: grey it so the player can see
	# the perk exists and costs more than they have left.
	if _build.perk != id and not _build.can_take_perk(id):
		chip.disabled = true
		chip.add_theme_color_override("font_disabled_color", Color(0.30, 0.34, 0.31))
	return chip

func _perk_detail() -> Control:
	var perks := Drive.def("perk") as PerkDef
	if perks == null or not _build.has_perk():
		return _hint(UiText.t("manager.perk_none"))
	return _hint("%s %s — %s" % [
		perks.icon(_build.perk), perks.label(_build.perk), perks.desc(_build.perk)])

# Height and weight step through the ranges the JSON declares. They cost no
# points: the trade they force IS the price.
func _body_row() -> Control:
	var stats := Drive.def("stat") as StatDef
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 30)
	if stats == null:
		return row
	for id: String in stats.measure_ids():
		var spec: Dictionary = stats.measure(id)
		var cell := HBoxContainer.new()
		cell.add_theme_constant_override("separation", 6)
		cell.tooltip_text = I18n.text(spec.get("desc", ""), "")
		cell.mouse_filter = Control.MOUSE_FILTER_STOP

		var caption := Label.new()
		caption.text = I18n.text(spec.get("label", id), id)
		caption.add_theme_color_override("font_color", MUTED)
		cell.add_child(caption)

		# A SpinBox, not steppers: someone entering their own 1,83 m should type
		# it, not click twenty-eight times.
		var field := SpinBox.new()
		field.min_value = float(spec.get("min", 0.0))
		field.max_value = float(spec.get("max", 999.0))
		field.step = stats.increment(id)
		field.value = _measure_value(id)
		field.suffix = String(spec.get("unit", ""))
		field.custom_minimum_size = Vector2(104, 30)
		field.value_changed.connect(_on_measure_value.bind(id))
		cell.add_child(field)
		row.add_child(cell)

	var effect: Dictionary = stats.body_effect({"height": _build.height, "weight": _build.weight})
	var summary := Label.new()
	summary.text = _effect_text(stats, effect)
	summary.add_theme_font_size_override("font_size", 12)
	summary.add_theme_color_override("font_color", WARN)
	row.add_child(summary)

	var price := Label.new()
	price.text = UiText.t("manager.body_cost") % _build.body_cost()
	price.add_theme_font_size_override("font_size", 12)
	price.add_theme_color_override("font_color", MUTED if _build.body_cost() == 0 else ACCENT)
	row.add_child(price)
	return row

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

func _attribute_row(stats: StatDef, id: String) -> Control:
	var spec: Dictionary = stats.base_stat(id)
	var step_value: int = int(_build.stats.get(id, 0))
	var shift: int = int(stats.body_effect(
		{"height": _build.height, "weight": _build.weight}).get(id, 0))
	var effective: int = clampi(step_value + shift, 0, StatDef.MAX_STEP)
	var bonus: int = effective - stats.average_step

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	row.tooltip_text = "%s

%d/10%s
%s" % [
		I18n.text(spec.get("desc", ""), ""), effective,
		"   (%+d do corpo)" % shift if shift != 0 else "",
		UiText.t("manager.team_bonus") % bonus,
	]
	row.mouse_filter = Control.MOUSE_FILTER_STOP

	row.add_child(_step_button("−", _on_lower_stat.bind(id), _build.can_lower_stat(id)))
	row.add_child(_step_button("+", _on_raise_stat.bind(id), _build.can_raise_stat(id)))

	var label := Label.new()
	label.text = I18n.text(spec.get("label", id), id)
	label.custom_minimum_size = Vector2(104, 0)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", TEXT)
	row.add_child(label)
	row.add_child(StatBar.bar(effective * 10))

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
		I18n.text(spec.get("desc", ""), ""),
		I18n.text(stats.base_stat(attribute).get("label", attribute), attribute), attribute_step,
		I18n.text(spec.get("label", id), id), step_value,
		UiText.t("manager.roll_hint") % (attribute_step + step_value),
	]
	row.mouse_filter = Control.MOUSE_FILTER_STOP

	row.add_child(_step_button("−", _on_lower_skill.bind(id), _build.can_lower_skill(id)))
	row.add_child(_step_button("+", _on_raise_skill.bind(id), _build.can_raise_skill(id)))

	var label := Label.new()
	label.text = I18n.text(spec.get("label", id), id)
	label.custom_minimum_size = Vector2(128, 0)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", TEXT)
	row.add_child(label)
	row.add_child(StatBar.bar(step_value * 10))

	var cost := Label.new()
	var next_cost: int = _build.cost_to_raise_skill(id)
	cost.text = str(next_cost) if next_cost >= 0 else "—"
	cost.custom_minimum_size = Vector2(22, 0)
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cost.add_theme_font_size_override("font_size", 11)
	cost.add_theme_color_override("font_color", MUTED)
	row.add_child(cost)
	return row

func _plays_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.add_child(_field_label(UiText.t("manager.plays")))
	var categories := Drive.def("category") as CategoryDef
	for id: String in (categories.category_ids() if categories != null else []):
		row.add_child(_choice(categories.category_label(id), _plays == id, _on_plays.bind(id)))
	row.add_child(_choice(UiText.t("manager.plays_none"), _plays == "", _on_plays.bind("")))
	return row

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
	box.add_theme_constant_override("separation", 3)
	var pick: Button = _flat_button("🔒  " + UiText.t("manager.pick_team"), Callable(), false)
	pick.disabled = true
	box.add_child(pick)
	box.add_child(_hint(UiText.t("manager.pick_locked")))
	box.add_child(_spacer(4))
	var draw_button: Button = _flat_button(UiText.t("manager.random"), _on_draw, true)
	draw_button.disabled = not _build.is_complete()
	box.add_child(draw_button)
	box.add_child(_hint(_draw_hint()))
	return box

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
	where.text = "%s/%s   ·   %s" % [_drafted.get("city", "?"), _drafted.get("state", "?"),
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

func _club_fields_my_category() -> bool:
	if _plays == "":
		return true
	return bool((_drafted.get("squads", {}) as Dictionary).get(_plays, false))

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
# born into. Name, surname, apelido, the whole sheet, and a perk — or no perk,
# which is a legitimate roll.
func _on_reroll_all() -> void:
	var rng: RandomNumberGenerator = _free_rng()
	_build.roll_random(rng)
	_name = _roll_name(rng)
	_build_ui()

func _on_perk(id: String) -> void:
	_build.set_perk(id)
	_build_ui()

func _on_plays(category: String) -> void:
	_plays = category
	_build_ui()

func _on_draw() -> void:
	var def := Drive.def("team") as TeamDef
	if def == null:
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
	var manager: Actor = _build.to_actor(career_seed, _name)
	manager.set_plays([_plays] if _plays != "" else [])
	manager.set_manages([Actor.CATEGORY_MASC])
	manager.set_team(String(_drafted.get("id", "")))
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
	style.set_content_margin_all(26)
	style.border_color = LINE
	style.set_border_width_all(1)
	for corner: String in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		style.set("corner_radius_" + corner, 5)
	return style

func _section(text: String, hint: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	box.add_child(_spacer(6))
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", ACCENT)
	box.add_child(label)
	box.add_child(_rule())
	if hint != "":
		box.add_child(_hint(hint))
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

func _hint(text: String) -> Control:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", MUTED)
	return label

func _step_button(text: String, on_press: Callable, enabled: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(24, 24)
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
