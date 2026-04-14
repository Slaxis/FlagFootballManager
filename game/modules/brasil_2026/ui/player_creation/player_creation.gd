extends Control

const T_TITLE: Dictionary = {"pt": "NOVA CARREIRA", "en": "NEW CAREER"}
const T_NAME: Dictionary = {"pt": "Nome:", "en": "Name:"}
const T_NAME_HINT: Dictionary = {"pt": "Seu nome de jogador", "en": "Your player name"}
const T_AGE: Dictionary = {"pt": "Idade: 15", "en": "Age: 15"}
const T_ORIGIN: Dictionary = {"pt": "ORIGEM", "en": "ORIGIN"}
const T_SCHOOL: Dictionary = {"pt": "COLEGIO", "en": "SCHOOL"}
const T_TURNO: Dictionary = {"pt": "TURNO", "en": "SHIFT"}
const T_BODY: Dictionary = {"pt": "CORPO", "en": "BODY"}
const T_HEIGHT: Dictionary = {"pt": "Altura: ", "en": "Height: "}
const T_WEIGHT: Dictionary = {"pt": "Peso: ", "en": "Weight: "}
const T_MODS: Dictionary = {"pt": "Modificadores: ", "en": "Modifiers: "}
const T_ATTRS: Dictionary = {"pt": "FICHA", "en": "SHEET"}
const T_HINT: Dictionary = {"pt": "· talento * | excepcional ** | fraqueza x", "en": "· talent * | exceptional ** | weakness x"}
const T_POINTS: Dictionary = {"pt": "Pontos: ", "en": "Points: "}
const T_TALENTS: Dictionary = {"pt": "Talentos: ", "en": "Talents: "}
const T_START: Dictionary = {"pt": "INICIAR", "en": "START"}
const T_BACK: Dictionary = {"pt": "VOLTAR", "en": "BACK"}

enum Mark { NONE, STAR, DOUBLE, DUMMY }
const MARK_LABELS: Dictionary = {Mark.NONE: "·", Mark.STAR: "*", Mark.DOUBLE: "**", Mark.DUMMY: "x"}
const MARK_CYCLE: Array[int] = [Mark.NONE, Mark.STAR, Mark.DOUBLE, Mark.DUMMY]

const COLOR_DEFAULT := Color.WHITE
const COLOR_STAR := Color(0.2, 0.85, 0.2)
const COLOR_DUMMY := Color(0.6, 0.15, 0.15)
const COLOR_GROUP := Color(0.5, 0.5, 0.5)
const COLOR_ACCENT := Color(0.3, 0.6, 1.0)

var _stat_def: Def
var _creation: Def
var _origin_def: Def
var _tech_def: Def

# Stat state
var stat_values: Dictionary = {}
var stat_marks: Dictionary = {}
var points_remaining: int = 0
var _gender: String = "male"
var _stat_value_labels: Dictionary = {}
var _stat_name_labels: Dictionary = {}
var _mark_buttons: Dictionary = {}

# Origin state
var _selected_origin: String = ""
var _selected_school: String = ""
var _selected_turno: int = 0
var _height: int = 170
var _weight: int = 65
var _current_mods: Dictionary = {}
var _selected_personality: String = ""
var _personality_buttons: Array[Button] = []
var _origin_buttons: Array[Button] = []
var _school_buttons: Array[Button] = []
var _turno_buttons: Array[Button] = []
var _height_label: Label
var _weight_label: Label
var _mods_label: Label
var _profile_label: RichTextLabel
var _turno_container: HBoxContainer

# Shared UI refs
var _name_input: LineEdit
var _btn_male: Button
var _btn_female: Button
var _btn_start: Button
var _points_label: Label
var _marks_label: Label

func _ready() -> void:
	_stat_def = Drive.def("stat")
	_creation = Drive.def("creation")
	_origin_def = Drive.def("origin")
	if _stat_def == null or _creation == null:
		Log.log(self, "error", "PlayerCreation: missing stat or creation Def.")
		return
	_tech_def = Drive.def("technique")
	points_remaining = _creation.point_pool
	_init_stats()
	_build_ui()
	# Select defaults
	if _origin_def != null and _origin_def.origins.size() > 1:
		_on_origin_selected(_origin_def.origins[1]["id"])
	_on_personality_selected("intenso")

func _init_stats() -> void:
	for entry: Dictionary in _stat_def.list_stats():
		var stat_id: String = entry["id"]
		stat_values[stat_id] = _stat_def.base_for(stat_id)
		stat_marks[stat_id] = Mark.NONE

# --- Build full UI ---

func _build_ui() -> void:
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_right", 80)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)

	var root_vbox: VBoxContainer = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	margin.add_child(root_vbox)

	# Title
	var title: Label = Label.new()
	title.text = I18n.text(T_TITLE)
	title.add_theme_font_size_override("font_size", 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(title)

	# Two columns
	var columns: HBoxContainer = HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 32)
	root_vbox.add_child(columns)

	# LEFT: inputs (name, gender, origin, school, turno, body)
	var left: VBoxContainer = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.2
	left.add_theme_constant_override("separation", 8)
	columns.add_child(left)
	_build_right_column(left)

	# Vertical separator
	columns.add_child(VSeparator.new())

	# RIGHT: character sheet (stats)
	var right: VBoxContainer = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 1.0
	right.add_theme_constant_override("separation", 6)
	columns.add_child(right)
	_build_left_column(right)

	# Bottom buttons
	var btn_row: HBoxContainer = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	root_vbox.add_child(btn_row)

	var btn_back: Button = Button.new()
	btn_back.text = I18n.text(T_BACK)
	btn_back.custom_minimum_size = Vector2(140, 40)
	btn_back.pressed.connect(_on_back_pressed)
	btn_row.add_child(btn_back)

	_btn_start = Button.new()
	_btn_start.text = I18n.text(T_START)
	_btn_start.custom_minimum_size = Vector2(140, 40)
	_btn_start.disabled = true
	_btn_start.pressed.connect(_on_start_pressed)
	btn_row.add_child(_btn_start)

# --- Left column: FICHA (stats) ---

func _build_left_column(parent: VBoxContainer) -> void:
	var header: Label = Label.new()
	header.text = I18n.text(T_ATTRS)
	header.add_theme_font_size_override("font_size", 18)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(header)

	var hint: Label = Label.new()
	hint.text = I18n.text(T_HINT)
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", COLOR_GROUP)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(hint)

	# Stats listed vertically by group — uses full column height
	var stats_vbox: VBoxContainer = VBoxContainer.new()
	stats_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stats_vbox.add_theme_constant_override("separation", 6)
	parent.add_child(stats_vbox)

	for group: Dictionary in _stat_def.list_groups():
		var gh: Label = Label.new()
		gh.text = I18n.text(group["label"])
		gh.add_theme_font_size_override("font_size", 13)
		gh.add_theme_color_override("font_color", COLOR_GROUP)
		stats_vbox.add_child(gh)
		for entry: Dictionary in group["stats"]:
			_build_stat_row(stats_vbox, entry)
		# Spacer between groups (except last)
		if group != _stat_def.list_groups().back():
			var spacer: Control = Control.new()
			spacer.custom_minimum_size = Vector2(0, 4)
			stats_vbox.add_child(spacer)

	# Points / Talents info
	var info_row: HBoxContainer = HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 24)
	parent.add_child(info_row)

	_points_label = Label.new()
	_points_label.add_theme_font_size_override("font_size", 13)
	info_row.add_child(_points_label)

	_marks_label = Label.new()
	_marks_label.add_theme_font_size_override("font_size", 13)
	info_row.add_child(_marks_label)

	_update_labels()

func _build_stat_row(parent: VBoxContainer, entry: Dictionary) -> void:
	var stat_id: String = entry["id"]
	var base: int = _stat_def.base_for(stat_id)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)

	var btn_mark: Button = Button.new()
	btn_mark.text = MARK_LABELS[Mark.NONE]
	btn_mark.custom_minimum_size = Vector2(28, 26)
	btn_mark.pressed.connect(_on_mark_pressed.bind(stat_id))
	row.add_child(btn_mark)
	_mark_buttons[stat_id] = btn_mark

	var lbl_name: Label = Label.new()
	lbl_name.text = I18n.text(entry.get("name", stat_id))
	lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_name.tooltip_text = I18n.text(entry.get("desc", ""))
	row.add_child(lbl_name)
	_stat_name_labels[stat_id] = lbl_name

	var btn_minus: Button = Button.new()
	btn_minus.text = "-"
	btn_minus.custom_minimum_size = Vector2(26, 26)
	btn_minus.pressed.connect(_on_stat_change.bind(stat_id, -1))
	row.add_child(btn_minus)

	var lbl_val: Label = Label.new()
	lbl_val.text = str(base)
	lbl_val.custom_minimum_size = Vector2(22, 0)
	lbl_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(lbl_val)
	_stat_value_labels[stat_id] = lbl_val

	var btn_plus: Button = Button.new()
	btn_plus.text = "+"
	btn_plus.custom_minimum_size = Vector2(26, 26)
	btn_plus.pressed.connect(_on_stat_change.bind(stat_id, +1))
	row.add_child(btn_plus)

	parent.add_child(row)

# --- Right column: inputs ---

func _build_right_column(parent: VBoxContainer) -> void:
	# --- ROW 1: INPUTS ---
	# Name + Gender
	var name_row: HBoxContainer = HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	var name_lbl: Label = Label.new()
	name_lbl.text = I18n.text(T_NAME)
	name_row.add_child(name_lbl)
	_name_input = LineEdit.new()
	_name_input.placeholder_text = I18n.text(T_NAME_HINT)
	_name_input.max_length = 24
	_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_input.text_changed.connect(func(_t: String) -> void: _validate())
	name_row.add_child(_name_input)
	_btn_male = Button.new()
	_btn_male.text = "M"
	_btn_male.custom_minimum_size = Vector2(40, 0)
	_btn_male.toggle_mode = true
	_btn_male.button_pressed = true
	_btn_male.pressed.connect(_on_gender.bind("male"))
	name_row.add_child(_btn_male)
	_btn_female = Button.new()
	_btn_female.text = "F"
	_btn_female.custom_minimum_size = Vector2(40, 0)
	_btn_female.toggle_mode = true
	_btn_female.pressed.connect(_on_gender.bind("female"))
	name_row.add_child(_btn_female)
	var age_lbl: Label = Label.new()
	age_lbl.text = I18n.text(T_AGE)
	age_lbl.add_theme_color_override("font_color", COLOR_GROUP)
	name_row.add_child(age_lbl)
	parent.add_child(name_row)

	if _origin_def == null:
		return

	# Personality ("Who are you at school?")
	var pers_header: Dictionary = {"pt": "PERSONALIDADE", "en": "PERSONALITY"}
	_build_section_header(parent, pers_header)
	var pers_row: HBoxContainer = _make_button_row()
	var pers_options: Array[Dictionary] = [
		{"id": "intenso",     "label": {"pt": "Intenso",     "en": "Intense"},     "desc": {"pt": "Bully / Atleta — forca e velocidade",            "en": "Bully / Athlete — strength and speed"}},
		{"id": "tecnico",     "label": {"pt": "Tecnico",     "en": "Technical"},   "desc": {"pt": "Artista / Acrobata — agilidade e tecnica",       "en": "Artist / Acrobat — agility and technique"}},
		{"id": "estrategico", "label": {"pt": "Estrategico", "en": "Strategic"},   "desc": {"pt": "Nerd / Lider — percepcao e inteligencia",        "en": "Nerd / Leader — perception and intelligence"}},
	]
	for opt: Dictionary in pers_options:
		var btn: Button = Button.new()
		btn.text = I18n.text(opt.get("label", "?"))
		btn.tooltip_text = I18n.text(opt.get("desc", ""))
		btn.custom_minimum_size = Vector2(120, 36)
		btn.toggle_mode = true
		btn.pressed.connect(_on_personality_selected.bind(String(opt.get("id", ""))))
		pers_row.add_child(btn)
		_personality_buttons.append(btn)
	parent.add_child(pers_row)

	# Origin
	_build_section_header(parent, T_ORIGIN)
	var origin_row: HBoxContainer = _make_button_row()
	for origin: Dictionary in _origin_def.origins:
		var btn: Button = Button.new()
		btn.text = I18n.text(origin.get("name", "?"))
		btn.custom_minimum_size = Vector2(120, 36)
		btn.toggle_mode = true
		btn.pressed.connect(_on_origin_selected.bind(String(origin.get("id", ""))))
		origin_row.add_child(btn)
		_origin_buttons.append(btn)
	parent.add_child(origin_row)

	# School + Turno on same line
	var school_turno_row: HBoxContainer = HBoxContainer.new()
	school_turno_row.add_theme_constant_override("separation", 16)
	var school_box: VBoxContainer = VBoxContainer.new()
	school_box.add_theme_constant_override("separation", 4)
	_build_section_header(school_box, T_SCHOOL)
	var school_row: HBoxContainer = _make_button_row()
	for school: Dictionary in _origin_def.schools:
		var btn: Button = Button.new()
		btn.text = I18n.text(school.get("name", "?"))
		btn.custom_minimum_size = Vector2(130, 36)
		btn.toggle_mode = true
		btn.pressed.connect(_on_school_selected.bind(String(school.get("id", ""))))
		school_row.add_child(btn)
		_school_buttons.append(btn)
	school_box.add_child(school_row)
	school_turno_row.add_child(school_box)

	var turno_box: VBoxContainer = VBoxContainer.new()
	turno_box.add_theme_constant_override("separation", 4)
	_build_section_header(turno_box, T_TURNO)
	_turno_container = _make_button_row()
	turno_box.add_child(_turno_container)
	school_turno_row.add_child(turno_box)
	parent.add_child(school_turno_row)

	# Body sliders
	_build_section_header(parent, T_BODY)
	var body_cfg: Dictionary = _origin_def.body
	var body_row: HBoxContainer = HBoxContainer.new()
	body_row.add_theme_constant_override("separation", 24)

	var h_box: HBoxContainer = HBoxContainer.new()
	h_box.add_theme_constant_override("separation", 4)
	_height_label = Label.new()
	_height_label.text = I18n.text(T_HEIGHT) + str(_height) + "cm"
	_height_label.custom_minimum_size = Vector2(110, 0)
	h_box.add_child(_height_label)
	var h_slider: HSlider = HSlider.new()
	h_slider.min_value = float(body_cfg.get("height", {}).get("min", 150))
	h_slider.max_value = float(body_cfg.get("height", {}).get("max", 200))
	h_slider.value = float(body_cfg.get("height", {}).get("default", 170))
	h_slider.step = 1.0
	h_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_slider.value_changed.connect(_on_height_changed)
	h_box.add_child(h_slider)
	body_row.add_child(h_box)
	h_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var w_box: HBoxContainer = HBoxContainer.new()
	w_box.add_theme_constant_override("separation", 4)
	_weight_label = Label.new()
	_weight_label.text = I18n.text(T_WEIGHT) + str(_weight) + "kg"
	_weight_label.custom_minimum_size = Vector2(100, 0)
	w_box.add_child(_weight_label)
	var w_slider: HSlider = HSlider.new()
	w_slider.min_value = float(body_cfg.get("weight", {}).get("min", 45))
	w_slider.max_value = float(body_cfg.get("weight", {}).get("max", 110))
	w_slider.value = float(body_cfg.get("weight", {}).get("default", 65))
	w_slider.step = 1.0
	w_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	w_slider.value_changed.connect(_on_weight_changed)
	w_box.add_child(w_slider)
	body_row.add_child(w_box)
	w_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(body_row)

	# Modifiers summary (compact, under inputs)
	_mods_label = Label.new()
	_mods_label.add_theme_font_size_override("font_size", 12)
	_mods_label.add_theme_color_override("font_color", COLOR_STAR)
	_mods_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(_mods_label)

	parent.add_child(HSeparator.new())

	# --- ROW 2: PROFILE (narrative bio built from selections) ---
	_profile_label = RichTextLabel.new()
	_profile_label.bbcode_enabled = true
	_profile_label.fit_content = false
	_profile_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_profile_label.scroll_active = false
	_profile_label.add_theme_font_size_override("normal_font_size", 14)
	parent.add_child(_profile_label)
	_update_profile()

func _add_expand_spacer(parent: VBoxContainer) -> void:
	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(spacer)

func _build_section_header(parent: VBoxContainer, text: Dictionary) -> void:
	var lbl: Label = Label.new()
	lbl.text = I18n.text(text)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", COLOR_ACCENT)
	parent.add_child(lbl)

func _make_button_row() -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	return row


# --- Mark helpers ---

func _count_marks(mark: Mark) -> int:
	var count: int = 0
	for val: int in stat_marks.values():
		if val == mark:
			count += 1
	return count

func _star_points_available() -> int:
	return _creation.base_star_points + _count_marks(Mark.DUMMY)

func _star_points_spent() -> int:
	return _count_marks(Mark.STAR) * _creation.star_cost + _count_marks(Mark.DOUBLE) * _creation.double_cost

func _star_points_free() -> int:
	return _star_points_available() - _star_points_spent()

func _can_set_mark(stat_id: String, mark: Mark) -> bool:
	var old_mark: int = stat_marks[stat_id]
	if mark == old_mark:
		return true
	stat_marks[stat_id] = mark
	var dummies: int = _count_marks(Mark.DUMMY)
	var free: int = _star_points_free()
	stat_marks[stat_id] = old_mark
	if dummies > _creation.max_dummies:
		return false
	if free < 0:
		return false
	return true

func _next_valid_mark(stat_id: String, current: Mark) -> Mark:
	var idx: int = MARK_CYCLE.find(current)
	for i: int in MARK_CYCLE.size():
		var next_idx: int = (idx + 1 + i) % MARK_CYCLE.size()
		var candidate: Mark = MARK_CYCLE[next_idx] as Mark
		if _can_set_mark(stat_id, candidate):
			return candidate
	return Mark.NONE

func _color_for_mark(mark: Mark) -> Color:
	match mark:
		Mark.STAR, Mark.DOUBLE:
			return COLOR_STAR
		Mark.DUMMY:
			return COLOR_DUMMY
	return COLOR_DEFAULT

func _total_dumped() -> int:
	var total: int = 0
	for sid: String in stat_values:
		var below: int = _stat_def.base_for(sid) - stat_values[sid] + int(_current_mods.get(sid, 0))
		if below > 0:
			total += below
	return total

# --- Origin callbacks ---

func _on_personality_selected(pers_id: String) -> void:
	_selected_personality = pers_id
	for i: int in _personality_buttons.size():
		var ids: Array[String] = ["intenso", "tecnico", "estrategico"]
		_personality_buttons[i].button_pressed = ids[i] == pers_id if i < ids.size() else false
	_update_profile()
	_validate()

func _on_origin_selected(origin_id: String) -> void:
	_selected_origin = origin_id
	for i: int in _origin_buttons.size():
		_origin_buttons[i].button_pressed = _origin_def.origins[i].get("id", "") == origin_id
	if _selected_school == "" and not _origin_def.schools.is_empty():
		_on_school_selected(_origin_def.schools[0]["id"])
	else:
		_update_origin_modifiers()
	_validate()

func _on_school_selected(school_id: String) -> void:
	_selected_school = school_id
	for i: int in _school_buttons.size():
		_school_buttons[i].button_pressed = _origin_def.schools[i].get("id", "") == school_id
	_rebuild_turno_buttons(school_id)
	_validate()

func _rebuild_turno_buttons(school_id: String) -> void:
	for child: Node in _turno_container.get_children():
		child.queue_free()
	_turno_buttons.clear()
	var available: Array[Dictionary] = _origin_def.turnos_for_school(school_id)
	for turno: Dictionary in available:
		var btn: Button = Button.new()
		btn.text = I18n.text(turno.get("name", "?"))
		btn.custom_minimum_size = Vector2(80, 28)
		btn.toggle_mode = true
		btn.pressed.connect(_on_turno_selected.bind(int(turno.get("id", 0))))
		_turno_container.add_child(btn)
		_turno_buttons.append(btn)
	if not available.is_empty():
		_on_turno_selected(int(available[0].get("id", 1)))

func _on_turno_selected(turno_id: int) -> void:
	_selected_turno = turno_id
	var available: Array[Dictionary] = _origin_def.turnos_for_school(_selected_school)
	for i: int in _turno_buttons.size():
		if i < available.size():
			_turno_buttons[i].button_pressed = int(available[i].get("id", 0)) == turno_id
	_update_origin_modifiers()
	_validate()

func _on_height_changed(value: float) -> void:
	_height = int(value)
	_height_label.text = I18n.text(T_HEIGHT) + str(_height) + "cm"
	_update_origin_modifiers()

func _on_weight_changed(value: float) -> void:
	_weight = int(value)
	_weight_label.text = I18n.text(T_WEIGHT) + str(_weight) + "kg"
	_update_origin_modifiers()

func _update_origin_modifiers() -> void:
	if _origin_def == null or _selected_origin == "":
		return
	# Remove old modifiers
	for stat_id: String in _current_mods:
		stat_values[stat_id] = stat_values[stat_id] - int(_current_mods[stat_id])
	# Compute and apply new
	var mods: Dictionary = _origin_def.compute_modifiers(_selected_origin, _selected_school, _height, _weight)
	_current_mods = mods
	for stat_id: String in stat_values:
		var mod: int = int(mods.get(stat_id, 0))
		stat_values[stat_id] = stat_values[stat_id] + mod
		_stat_value_labels[stat_id].text = str(stat_values[stat_id])
		if mod > 0:
			_stat_value_labels[stat_id].add_theme_color_override("font_color", COLOR_STAR)
		elif mod < 0:
			_stat_value_labels[stat_id].add_theme_color_override("font_color", COLOR_DUMMY)
		else:
			_stat_value_labels[stat_id].add_theme_color_override("font_color", _color_for_mark(stat_marks[stat_id] as Mark))
	# Summary text
	var parts: Array[String] = []
	for k: String in mods:
		var v: int = int(mods[k])
		if v != 0:
			var pfx: String = "+" if v > 0 else ""
			parts.append(k + " " + pfx + str(v))
	_mods_label.text = I18n.text(T_MODS) + (", ".join(parts) if not parts.is_empty() else "—")
	_update_profile()

func _update_profile() -> void:
	if _profile_label == null:
		return
	var lines: Array[String] = []
	# Origin story
	if _selected_origin != "":
		var origin: Dictionary = _origin_def.get_origin(_selected_origin)
		lines.append(I18n.text(origin.get("desc", "")))
	# School story
	if _selected_school != "":
		var school: Dictionary = _origin_def.get_school(_selected_school)
		var turno: Dictionary = _origin_def.get_turno(_selected_turno)
		var turno_name: String = I18n.text(turno.get("name", "")) if not turno.is_empty() else ""
		lines.append(I18n.text(school.get("desc", "")) + " " + I18n.text({"pt": "Turno: ", "en": "Shift: "}) + turno_name + ".")
	# Body
	var body_desc: Array[String] = []
	body_desc.append(str(_height) + "cm, " + str(_weight) + "kg.")
	var body_cfg: Dictionary = _origin_def.body
	if _height >= int(body_cfg.get("tall_threshold", 185)):
		body_desc.append(I18n.text({"pt": "Alto pra idade — bom alcance, menos agilidade.", "en": "Tall for his age — good reach, less agility."}))
	elif _height <= int(body_cfg.get("short_threshold", 160)):
		body_desc.append(I18n.text({"pt": "Baixo e rapido — escapa facil, menos forca.", "en": "Short and quick — slips through, less power."}))
	if _weight >= int(body_cfg.get("heavy_threshold", 85)):
		body_desc.append(I18n.text({"pt": "Pesado — forte no contato, mais lento.", "en": "Heavy — strong in contact, slower."}))
	elif _weight <= int(body_cfg.get("light_threshold", 55)):
		body_desc.append(I18n.text({"pt": "Magro — leve e agil, menos resistente.", "en": "Lean — light and agile, less sturdy."}))
	lines.append(" ".join(body_desc))
	# Money
	if _selected_origin != "":
		var origin: Dictionary = _origin_def.get_origin(_selected_origin)
		var money: int = int(origin.get("money_start", 500))
		lines.append(I18n.text({"pt": "Comeca com R$" + str(money) + ".", "en": "Starts with R$" + str(money) + "."}))
	_profile_label.text = "\n\n".join(lines)

# --- Stat callbacks ---

func _on_mark_pressed(stat_id: String) -> void:
	var current: Mark = stat_marks[stat_id] as Mark
	var next: Mark = _next_valid_mark(stat_id, current)
	stat_marks[stat_id] = next
	_mark_buttons[stat_id].text = MARK_LABELS[next]
	var color: Color = _color_for_mark(next)
	_stat_name_labels[stat_id].add_theme_color_override("font_color", color)
	_stat_value_labels[stat_id].add_theme_color_override("font_color", color)
	_update_labels()
	_validate()

func _on_stat_change(stat_id: String, delta: int) -> void:
	var current: int = stat_values[stat_id]
	var mod: int = int(_current_mods.get(stat_id, 0))
	var base_val: int = current - mod
	var new_base: int = base_val + delta
	if new_base > _creation.max_stat or new_base < _creation.min_stat:
		return
	if delta > 0 and points_remaining <= 0:
		return
	if delta < 0 and _total_dumped() >= _creation.max_dump:
		return
	stat_values[stat_id] = new_base + mod
	points_remaining -= delta
	_stat_value_labels[stat_id].text = str(stat_values[stat_id])
	_update_labels()
	_validate()

func _update_labels() -> void:
	_points_label.text = I18n.text(T_POINTS) + str(points_remaining)
	var available: int = _star_points_available()
	var spent: int = _star_points_spent()
	_marks_label.text = I18n.text(T_TALENTS) + str(spent) + "/" + str(available)

func _validate() -> void:
	var has_name: bool = _name_input.text.strip_edges().length() >= 2
	var has_stars: bool = _star_points_spent() > 0
	var balanced: bool = _star_points_free() == 0
	var points_ok: bool = points_remaining >= 0
	var has_origin: bool = _selected_origin != ""
	var has_pers: bool = _selected_personality != ""
	_btn_start.disabled = not (has_name and has_stars and balanced and points_ok and has_origin and has_pers)

# --- Navigation ---

func _on_gender(gender: String) -> void:
	_gender = gender
	_btn_male.button_pressed = gender == "male"
	_btn_female.button_pressed = gender == "female"

func _on_back_pressed() -> void:
	var scene: PackedScene = The.ui("module_select")
	if scene:
		The.next_scene(scene)

func _on_start_pressed() -> void:
	var player_name: String = _name_input.text.strip_edges()

	var stars: Array[String] = []
	var doubles: Array[String] = []
	var dummies: Array[String] = []
	for stat_id: String in stat_marks:
		match stat_marks[stat_id]:
			Mark.STAR: stars.append(stat_id)
			Mark.DOUBLE: doubles.append(stat_id)
			Mark.DUMMY: dummies.append(stat_id)

	var spec: Dictionary = {
		"id": player_name.to_lower().replace(" ", "_"),
		"ancestor": "base_player",
		"group": "player",
		"name": player_name,
		"stars": stars,
		"doubles": doubles,
		"dummies": dummies,
	}
	for stat_id: String in stat_values:
		spec[stat_id] = stat_values[stat_id]

	var player_type: ThingType = God.register_type(spec)
	if player_type == null:
		Log.log(self, "error", "PlayerCreation: failed to register player Thing.")
		return

	The.session["player_id"] = spec["id"]
	The.session["player_name"] = player_name
	The.session["player_age"] = 15
	The.session["player_gender"] = _gender
	The.session["mode"] = "player"
	The.session["week"] = 1
	The.session["day"] = 1

	# Origin-based starting conditions
	var origin_data: Dictionary = {}
	if _origin_def != null and _selected_origin != "":
		origin_data = _origin_def.get_origin(_selected_origin)
	The.session["money"] = int(origin_data.get("money_start", 500))
	The.session["vitals"] = origin_data.get("vitals_start", {"hp": 100, "energy": 100, "hunger": 80, "social": 50, "leisure": 50, "room": 80}).duplicate()
	The.session["fridge_meals"] = int(origin_data.get("fridge_start", 5))
	The.session["origin"] = _selected_origin
	The.session["school"] = _selected_school
	The.session["turno"] = _selected_turno
	The.session["height"] = _height
	The.session["weight"] = _weight
	The.session["personality"] = _selected_personality

	# Build starter deck: 1 personality base card + 1 origin bonus
	var starter_deck: Array[String] = []
	if _tech_def != null:
		var base_card: String = _tech_def.get_starter_card(_selected_personality)
		if base_card != "":
			starter_deck.append(base_card)
		var origin_bonus: Dictionary = _tech_def.get_origin_bonus(_selected_origin, _selected_school)
		var bonus_type: String = String(origin_bonus.get("type", ""))
		if bonus_type == "card":
			var bonus_card: String = String(origin_bonus.get("card_id", ""))
			if bonus_card != "":
				starter_deck.append(bonus_card)
		elif bonus_type == "money":
			The.session["money"] = int(The.session.get("money", 0)) + int(origin_bonus.get("amount", 0))
		elif bonus_type == "fridge":
			The.session["fridge_meals"] = int(The.session.get("fridge_meals", 0)) + int(origin_bonus.get("amount", 0))
		elif bonus_type == "random_advanced":
			var advanced: Array[Dictionary] = _tech_def.list_advanced()
			if not advanced.is_empty():
				advanced.shuffle()
				starter_deck.append(String(advanced[0].get("id", "")))
	The.session["technique_deck"] = starter_deck
	The.session["technique_collection"] = starter_deck.duplicate()

	Log.log(self, "info", "Career: " + player_name + " [" + _selected_personality + "/" + _selected_origin + "/" + _selected_school + "/T" + str(_selected_turno) + "] deck=" + str(starter_deck))
	var scene: PackedScene = The.ui("cutscene")
	if scene:
		The.next_scene(scene)
