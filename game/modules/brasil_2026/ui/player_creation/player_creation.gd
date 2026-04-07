extends Control

enum Mark { NONE, STAR, DOUBLE, DUMMY }

const MARK_LABELS: Dictionary = {
	Mark.NONE: "·",
	Mark.STAR: "*",
	Mark.DOUBLE: "**",
	Mark.DUMMY: "x",
}
const MARK_CYCLE: Array[int] = [Mark.NONE, Mark.STAR, Mark.DOUBLE, Mark.DUMMY]

const COLOR_DEFAULT := Color.WHITE
const COLOR_STAR := Color(0.2, 0.85, 0.2)
const COLOR_DUMMY := Color(0.6, 0.15, 0.15)
const COLOR_GROUP := Color(0.5, 0.5, 0.5)
const COLOR_SKILL := Color(0.7, 0.7, 0.7)

# Loaded from engine Defs
var _stat_def: Def   # StatDef
var _skill_def: Def  # SkillDef
var _creation: Def   # CreationDef

# State — attributes only (skills are display-only at creation)
var stat_values: Dictionary = {}
var stat_marks: Dictionary = {}
var points_remaining: int = 0
var _stat_name_labels: Dictionary = {}
var _stat_value_labels: Dictionary = {}
var _mark_buttons: Dictionary = {}

@onready var name_input: LineEdit = $Margin/VBox/Header/NameInput
@onready var stats_columns: HBoxContainer = $Margin/VBox/StatsColumns
@onready var skills_columns: HBoxContainer = $Margin/VBox/SkillsColumns
@onready var points_label: Label = $Margin/VBox/InfoRow/PointsLabel
@onready var marks_label: Label = $Margin/VBox/InfoRow/MarksLabel
@onready var btn_start: Button = $Margin/VBox/Buttons/BtnStart
@onready var btn_back: Button = $Margin/VBox/Buttons/BtnBack

func _ready() -> void:
	_stat_def = Drive.def("stat")
	_skill_def = Drive.def("skill")
	_creation = Drive.def("creation")
	if _stat_def == null or _skill_def == null or _creation == null:
		Log.log(self, "error", "PlayerCreation: missing stat, skill, or creation Def.")
		return
	points_remaining = _creation.point_pool
	_init_stats()
	_build_attr_columns()
	_build_skill_columns()
	_update_labels()
	btn_back.pressed.connect(_on_back_pressed)
	btn_start.pressed.connect(_on_start_pressed)
	name_input.text_changed.connect(func(_t: String) -> void: _validate())
	btn_start.disabled = true

func _init_stats() -> void:
	for entry: Dictionary in _stat_def.list_stats():
		var stat_id: String = entry["id"]
		stat_values[stat_id] = _stat_def.base_for(stat_id)
		stat_marks[stat_id] = Mark.NONE

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
		var below: int = _stat_def.base_for(sid) - stat_values[sid]
		if below > 0:
			total += below
	return total

# --- Build attribute columns ---

func _build_attr_columns() -> void:
	for group: Dictionary in _stat_def.list_groups():
		var column: VBoxContainer = VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation", 6)

		var header: Label = Label.new()
		header.text = group["label"]
		header.add_theme_font_size_override("font_size", 14)
		header.add_theme_color_override("font_color", COLOR_GROUP)
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(header)

		column.add_child(HSeparator.new())

		for entry: Dictionary in group["stats"]:
			_build_attr_row(column, entry)

		stats_columns.add_child(column)

func _build_attr_row(parent: VBoxContainer, entry: Dictionary) -> void:
	var stat_id: String = entry["id"]
	var base: int = _stat_def.base_for(stat_id)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)

	var btn_mark: Button = Button.new()
	btn_mark.text = MARK_LABELS[Mark.NONE]
	btn_mark.custom_minimum_size = Vector2(32, 28)
	btn_mark.pressed.connect(_on_mark_pressed.bind(stat_id))
	btn_mark.tooltip_text = String(entry.get("desc", ""))
	row.add_child(btn_mark)
	_mark_buttons[stat_id] = btn_mark

	var label_name: Label = Label.new()
	label_name.text = String(entry.get("name", stat_id))
	label_name.custom_minimum_size = Vector2(100, 0)
	label_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label_name.tooltip_text = String(entry.get("desc", ""))
	row.add_child(label_name)
	_stat_name_labels[stat_id] = label_name

	var btn_minus: Button = Button.new()
	btn_minus.text = "-"
	btn_minus.custom_minimum_size = Vector2(28, 28)
	btn_minus.pressed.connect(_on_stat_change.bind(stat_id, -1))
	row.add_child(btn_minus)

	var label_value: Label = Label.new()
	label_value.text = str(base)
	label_value.custom_minimum_size = Vector2(24, 0)
	label_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(label_value)
	_stat_value_labels[stat_id] = label_value

	var btn_plus: Button = Button.new()
	btn_plus.text = "+"
	btn_plus.custom_minimum_size = Vector2(28, 28)
	btn_plus.pressed.connect(_on_stat_change.bind(stat_id, +1))
	row.add_child(btn_plus)

	parent.add_child(row)

# --- Build skill columns (read-only) ---

func _build_skill_columns() -> void:
	for group: Dictionary in _skill_def.list_groups():
		var column: VBoxContainer = VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation", 6)

		var header: Label = Label.new()
		header.text = group["label"]
		header.add_theme_font_size_override("font_size", 14)
		header.add_theme_color_override("font_color", COLOR_GROUP)
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(header)

		column.add_child(HSeparator.new())

		for entry: Dictionary in group["stats"]:
			_build_skill_row(column, entry)

		skills_columns.add_child(column)

func _build_skill_row(parent: VBoxContainer, entry: Dictionary) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)

	var label_name: Label = Label.new()
	label_name.text = String(entry.get("name", entry.get("id", "")))
	label_name.custom_minimum_size = Vector2(110, 0)
	label_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label_name.tooltip_text = String(entry.get("desc", ""))
	label_name.add_theme_color_override("font_color", COLOR_SKILL)
	row.add_child(label_name)

	var label_value: Label = Label.new()
	label_value.text = "0"
	label_value.custom_minimum_size = Vector2(24, 0)
	label_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_value.add_theme_color_override("font_color", COLOR_SKILL)
	row.add_child(label_value)

	parent.add_child(row)

# --- Callbacks ---

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
	var new_val: int = current + delta
	if new_val > _creation.max_stat or new_val < _creation.min_stat:
		return
	if delta > 0 and points_remaining <= 0:
		return
	if delta < 0 and _total_dumped() >= _creation.max_dump:
		return
	stat_values[stat_id] = new_val
	points_remaining -= delta
	_stat_value_labels[stat_id].text = str(new_val)
	_update_labels()
	_validate()

func _update_labels() -> void:
	points_label.text = "Points remaining: " + str(points_remaining)
	var available: int = _star_points_available()
	var spent: int = _star_points_spent()
	marks_label.text = "Talents: " + str(spent) + "/" + str(available)

func _validate() -> void:
	var has_name: bool = name_input.text.strip_edges().length() >= 2
	var has_stars: bool = _star_points_spent() > 0
	var balanced: bool = _star_points_free() == 0
	var points_ok: bool = points_remaining >= 0
	btn_start.disabled = not (has_name and has_stars and balanced and points_ok)

# --- Navigation ---

func _on_back_pressed() -> void:
	var scene: PackedScene = The.ui("module_select")
	if scene:
		The.next_scene(scene)

func _on_start_pressed() -> void:
	var player_name: String = name_input.text.strip_edges()

	var stars: Array[String] = []
	var doubles: Array[String] = []
	var dummies: Array[String] = []
	for stat_id: String in stat_marks:
		match stat_marks[stat_id]:
			Mark.STAR:
				stars.append(stat_id)
			Mark.DOUBLE:
				doubles.append(stat_id)
			Mark.DUMMY:
				dummies.append(stat_id)

	# Register player as a runtime Thing via engine
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
	# Skills start at 0 — inherited from base_player ancestor

	var player_type: ThingType = God.register_type(spec)
	if player_type == null:
		Log.log(self, "error", "PlayerCreation: failed to register player Thing.")
		return

	The.session["player_id"] = spec["id"]
	The.session["player_name"] = player_name
	The.session["player_age"] = 15
	The.session["mode"] = "player"
	The.session["week"] = 1
	The.session["day"] = 1
	The.session["money"] = 500
	The.session["vitals"] = {"energy": 100, "hunger": 80, "social": 50, "leisure": 50}
	Log.log(self, "info", "Career: " + player_name + " registered as Thing '" + spec["id"] + "'")
	var scene: PackedScene = The.ui("cutscene")
	if scene:
		The.next_scene(scene)
