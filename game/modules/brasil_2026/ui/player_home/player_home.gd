extends Control

const DAYS: Array[String] = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]
const SLOTS: Array[String] = ["morning", "afternoon", "night", "late_night"]

const DAY_LABELS: Dictionary = {
	"mon": {"pt": "SEG", "en": "MON"},
	"tue": {"pt": "TER", "en": "TUE"},
	"wed": {"pt": "QUA", "en": "WED"},
	"thu": {"pt": "QUI", "en": "THU"},
	"fri": {"pt": "SEX", "en": "FRI"},
	"sat": {"pt": "SAB", "en": "SAT"},
	"sun": {"pt": "DOM", "en": "SUN"},
}
const SLOT_LABELS: Dictionary = {
	"morning":    {"pt": "MANHA",      "en": "MORN"},
	"afternoon":  {"pt": "TARDE",      "en": "AFT"},
	"night":      {"pt": "NOITE",      "en": "NITE"},
	"late_night": {"pt": "MADRUGA",    "en": "LATE"},
}
const SLOT_ICONS: Dictionary = {
	"morning":    "[*]",
	"afternoon":  "[o]",
	"night":      "[.]",
	"late_night": "[~]",
}
const T_WEEK: Dictionary = {"pt": "Semana", "en": "Week"}
const T_DAY: Dictionary = {"pt": "Dia", "en": "Day"}
const T_PLAN: Dictionary = {"pt": "PLANEJE SUA SEMANA", "en": "PLAN YOUR WEEK"}
const T_NEXT_WEEK: Dictionary = {"pt": ">> SEMANA", "en": ">> WEEK"}
const T_TIP_SLOT: Dictionary = {"pt": "Resolver proximo horario", "en": "Resolve next time slot"}
const T_TIP_DAY: Dictionary = {"pt": "Resolver dia inteiro", "en": "Resolve full day"}
const T_TIP_WEEK: Dictionary = {"pt": "Resolver semana inteira", "en": "Resolve full week"}
const T_TIP_CLEAR: Dictionary = {"pt": "Limpar planejamento", "en": "Clear all planned activities"}
const T_COLUMN_EMPTY: Dictionary = {"pt": "---", "en": "---"}
const T_CLEAR: Dictionary = {"pt": "LIMPAR", "en": "CLEAR"}
const T_ROOM: Dictionary = {"pt": "SEU QUARTO", "en": "YOUR ROOM"}
const T_VITALS: Dictionary = {"pt": "SINAIS VITAIS", "en": "VITALS"}
const T_WELCOME: Dictionary = {"pt": "Bem-vindo! Planeje sua semana.", "en": "Welcome home. Plan your week."}
const T_PHONE: Dictionary = {"pt": "Celular", "en": "Phone"}
const T_COMPUTER: Dictionary = {"pt": "Computador", "en": "Computer"}
const T_FRIDGE: Dictionary = {"pt": "Geladeira", "en": "Fridge"}
const T_WARDROBE: Dictionary = {"pt": "Armario", "en": "Wardrobe"}
const T_NOT_IMPL: Dictionary = {"pt": " -- nao implementado", "en": " -- not yet implemented"}
const T_SUMMARY: Dictionary = {"pt": "RESUMO DA SEMANA", "en": "WEEK SUMMARY"}
const T_CLOSE: Dictionary = {"pt": "FECHAR", "en": "CLOSE"}
const T_COLLAPSES: Dictionary = {"pt": "Colapsos", "en": "Collapses"}
const T_SYNERGIES: Dictionary = {"pt": "Sinergias", "en": "Synergies"}
const T_MONEY_CHANGE: Dictionary = {"pt": "Saldo", "en": "Balance"}
const T_ACTIVITIES: Dictionary = {"pt": "Atividades", "en": "Activities"}
const T_QUESTS: Dictionary = {"pt": "TAREFAS", "en": "QUESTS"}
const COLOR_QUEST_DONE := Color(0.2, 0.75, 0.2)
const COLOR_QUEST_PENDING := Color(0.6, 0.6, 0.6)

const VITAL_NAMES: Dictionary = {
	"hp":      {"pt": "HP",       "en": "HP"},
	"energy":  {"pt": "Energia",  "en": "Energy"},
	"hunger":  {"pt": "Fome",     "en": "Hunger"},
	"social":  {"pt": "Social",   "en": "Social"},
	"leisure": {"pt": "Lazer",    "en": "Leisure"},
	"room":    {"pt": "Quarto",   "en": "Room"},
}

const T_FRIDGE_TITLE: Dictionary = {"pt": "Geladeira", "en": "Fridge"}
const T_FRIDGE_MEALS: Dictionary = {"pt": "Refeicoes: ", "en": "Meals: "}
const T_MIRROR: Dictionary = {"pt": "Espelho", "en": "Mirror"}
const T_MIRROR_TITLE: Dictionary = {"pt": "Ficha do Jogador", "en": "Player Sheet"}
const T_PAUSED: Dictionary = {"pt": "|| PAUSADO", "en": "|| PAUSED"}
const T_EFFECTS: Dictionary = {"pt": "EFEITOS", "en": "EFFECTS"}

const COLOR_SYNERGY := Color(0.2, 0.75, 0.2)
const COLOR_NORMAL := Color(0.85, 0.75, 0.2)
const COLOR_COLLAPSE := Color(0.8, 0.2, 0.2)
const COLOR_RUNNING := Color(0.3, 0.5, 0.9)
const COLOR_DEBUFF := Color(0.8, 0.3, 0.3)
const COLOR_BUFF := Color(0.3, 0.7, 0.9)
const COLOR_DEFAULT := Color(1, 1, 1)
const SLOT_DELAY: float = 0.5

var _activity_def: Def
var _grid_selects: Dictionary = {}      # "day_slot" -> OptionButton
var _grid_activities: Dictionary = {}   # "day_slot" -> Array[Dictionary]
var _column_selects: Dictionary = {}    # slot_id -> OptionButton (column header)
var _column_activities: Dictionary = {} # slot_id -> Array[Dictionary]
var _day_play_buttons: Dictionary = {}  # "day" -> Button (single slot >)
var _day_fast_buttons: Dictionary = {}  # "day" -> Button (full day >>)
var _day_resolved: Dictionary = {}      # "day" -> bool
var _day_slot_index: Dictionary = {}    # "day" -> int (next slot to resolve)
var _updating_column: bool = false
var _vital_bars: Dictionary = {}
var _fridge_window: Window = null
var _fridge_label: Label = null
var _mirror_window: Window = null
var _paused: bool = false
var _last_week_selections: Dictionary = {}  # key -> activity_id
# Active effects: Array of {name, desc, duration, category_bonus, icon, color_rank}
var _active_effects: Array[Dictionary] = []
# Quests
var _current_quests: Array[Dictionary] = []
var _quest_labels: Array[Label] = []
var _quest_activity_counts: Dictionary = {}  # activity_id -> int
# Week tracking
var _week_collapses: int = 0
var _week_synergies: int = 0
var _week_money_start: int = 0
var _week_vitals_start: Dictionary = {}
var _week_activities: Dictionary = {}  # activity_id -> {count, color}
var _vital_labels: Dictionary = {}
var _vital_value_labels: Dictionary = {}
var _effects: Array[Dictionary] = []
var _resolving: bool = false

@onready var money_label: Label = $Margin/VBox/TopBar/MoneyLabel
@onready var day_label: Label = $Margin/VBox/TopBar/DayLabel
@onready var week_label: Label = $Margin/VBox/TopBar/WeekLabel
@onready var player_label: Label = $Margin/VBox/TopBar/PlayerLabel

@onready var plan_header: Label = $Margin/VBox/Content/LeftPanel/ToolRow/PlanHeader
@onready var grid_container: GridContainer = $Margin/VBox/Content/LeftPanel/GridScroll/WeekGrid
@onready var btn_next_week: Button = $Margin/VBox/Content/LeftPanel/ToolRow/BtnNextWeek
@onready var btn_clear: Button = $Margin/VBox/Content/LeftPanel/ToolRow/BtnClear

@onready var quest_header: Label = $Margin/VBox/Content/RightPanel/QuestHeader
@onready var quest_list: VBoxContainer = $Margin/VBox/Content/RightPanel/QuestList
@onready var room_header: Label = $Margin/VBox/Content/RightPanel/RoomHeader
@onready var room_panel: VBoxContainer = $Margin/VBox/Content/RightPanel/Room
@onready var vitals_header: Label = $Margin/VBox/Content/RightPanel/VitalsHeader
@onready var vitals_panel: VBoxContainer = $Margin/VBox/Content/RightPanel/Vitals
@onready var log_text: RichTextLabel = $Margin/VBox/Content/RightPanel/LogText
@onready var effects_bar: HBoxContainer = $Margin/VBox/EffectsBar

func _ready() -> void:
	_activity_def = Drive.def("activity")
	if _activity_def == null:
		Log.log(self, "error", "PlayerHome: missing activity Def.")
		return
	_build_grid()
	_build_room()
	_build_vitals()
	_update_text()
	_update_header()
	_update_vitals()
	btn_next_week.pressed.connect(_on_next_week)
	btn_clear.pressed.connect(_on_clear)
	_reset_week_tracking()
	_load_quests()
	_apply_default_week()
	set_process_unhandled_key_input(true)
	_log(I18n.text(T_WELCOME), COLOR_DEFAULT)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not (event as InputEventKey).pressed:
		return
	var key: InputEventKey = event as InputEventKey
	match key.keycode:
		KEY_SPACE:
			get_viewport().set_input_as_handled()
			_paused = not _paused
			_update_pause_indicator()
		KEY_1:
			_on_play_next_slot()
		KEY_2:
			_on_play_next_day()
		KEY_3:
			_on_next_week()
		KEY_F:
			_toggle_fridge_window()
		KEY_M:
			_toggle_mirror_window()

func _update_pause_indicator() -> void:
	if _paused:
		plan_header.text = I18n.text(T_PLAN) + "  " + I18n.text(T_PAUSED)
		plan_header.add_theme_color_override("font_color", COLOR_RUNNING)
	else:
		plan_header.text = I18n.text(T_PLAN)
		plan_header.remove_theme_color_override("font_color")

func _on_play_next_slot() -> void:
	var day_id: String = _next_unresolved_day()
	if day_id != "":
		_on_play_slot(day_id)

func _on_play_next_day() -> void:
	var day_id: String = _next_unresolved_day()
	if day_id != "":
		_on_play_day(day_id)

# --- Text ---

func _update_text() -> void:
	plan_header.text = I18n.text(T_PLAN)
	btn_next_week.text = ">>"
	btn_next_week.tooltip_text = I18n.text(T_TIP_WEEK)
	btn_clear.text = "X"
	btn_clear.tooltip_text = I18n.text(T_TIP_CLEAR)
	quest_header.text = I18n.text(T_QUESTS)
	room_header.text = I18n.text(T_ROOM)
	vitals_header.text = I18n.text(T_VITALS)
	for vid: String in _vital_labels:
		_vital_labels[vid].text = I18n.text(VITAL_NAMES.get(vid, vid))
	_rebuild_room()

# --- Header ---

func _update_header() -> void:
	var money: int = int(The.session.get("money", 0))
	var week: int = int(The.session.get("week", 1))
	var day: int = int(The.session.get("day", 1))
	player_label.text = String(The.session.get("player_name", ""))
	money_label.text = "R$ " + str(money)
	day_label.text = I18n.text(T_DAY) + " " + str(day)
	week_label.text = I18n.text(T_WEEK) + " " + str(week)

# --- Week Grid ---

func _build_grid() -> void:
	grid_container.columns = SLOTS.size() + 3  # day label + 4 slots + > + >>

	# Corner cell
	var corner: Label = Label.new()
	corner.text = ""
	corner.custom_minimum_size = Vector2(36, 0)
	grid_container.add_child(corner)

	# Column headers: Label on top, OptionButton below for "fill all"
	for slot_id: String in SLOTS:
		var col_box: VBoxContainer = VBoxContainer.new()
		col_box.add_theme_constant_override("separation", 1)

		var label: Label = Label.new()
		label.text = I18n.text(SLOT_LABELS[slot_id])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 11)
		col_box.add_child(label)

		var available: Array[Dictionary] = _activity_def.list_for_slot(slot_id)
		_column_activities[slot_id] = available
		var col_select: OptionButton = OptionButton.new()
		col_select.add_theme_font_size_override("font_size", 9)
		col_select.custom_minimum_size = Vector2(0, 22)
		col_select.add_item("---")
		_populate_grouped_select(col_select, slot_id)
		col_select.selected = 0
		col_select.item_selected.connect(_on_column_changed.bind(slot_id))
		_column_selects[slot_id] = col_select
		col_box.add_child(col_select)

		grid_container.add_child(col_box)

	# Play columns header (empty spacers)
	var ph: Label = Label.new()
	ph.text = ""
	ph.custom_minimum_size = Vector2(28, 0)
	grid_container.add_child(ph)
	var fh: Label = Label.new()
	fh.text = ""
	fh.custom_minimum_size = Vector2(28, 0)
	grid_container.add_child(fh)

	# Day rows
	for day_id: String in DAYS:
		_day_resolved[day_id] = false
		_day_slot_index[day_id] = 0

		var row_label: Label = Label.new()
		row_label.text = I18n.text(DAY_LABELS[day_id])
		row_label.add_theme_font_size_override("font_size", 12)
		row_label.custom_minimum_size = Vector2(36, 0)
		grid_container.add_child(row_label)

		for slot_id: String in SLOTS:
			var avail: Array[Dictionary] = _activity_def.list_for_slot(slot_id)
			var key: String = day_id + "_" + slot_id
			var select: OptionButton = OptionButton.new()
			select.custom_minimum_size = Vector2(0, 28)
			select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			select.add_theme_font_size_override("font_size", 10)
			_grid_activities[key] = avail
			_populate_grouped_select(select, slot_id)
			select.item_selected.connect(_on_grid_select_changed.bind(key, slot_id))
			# Default late_night to sleep
			if slot_id == "late_night":
				_select_activity_by_id(select, key, "sleep")
			_update_select_tooltip(select, key, slot_id)
			_grid_selects[key] = select
			grid_container.add_child(select)

		var btn_play: Button = Button.new()
		btn_play.text = ">"
		btn_play.custom_minimum_size = Vector2(28, 28)
		btn_play.tooltip_text = I18n.text(T_TIP_SLOT)
		btn_play.pressed.connect(_on_play_slot.bind(day_id))
		_day_play_buttons[day_id] = btn_play
		grid_container.add_child(btn_play)

		var btn_fast: Button = Button.new()
		btn_fast.text = ">>"
		btn_fast.custom_minimum_size = Vector2(28, 28)
		btn_fast.tooltip_text = I18n.text(T_TIP_DAY)
		btn_fast.pressed.connect(_on_play_day.bind(day_id))
		_day_fast_buttons[day_id] = btn_fast
		grid_container.add_child(btn_fast)

func _populate_grouped_select(select: OptionButton, slot_id: String) -> void:
	var grouped: Array[Dictionary] = _activity_def.list_for_slot_grouped(slot_id)
	for entry: Dictionary in grouped:
		if entry["type"] == "header":
			var cat: Dictionary = entry["category"]
			var icon: String = String(cat.get("icon", ""))
			var label_text: String = icon + " " + I18n.text(cat.get("label", ""))
			select.add_separator(label_text)
		else:
			var act: Dictionary = entry["activity"]
			var cat: Dictionary = _activity_def.get_category(String(act.get("category", "")))
			var icon: String = String(cat.get("icon", " "))
			var lock_reason: String = ActivityDef.check_requires(act, The.session)
			var item_text: String = icon + " " + I18n.text(act.get("name", "?"))
			if lock_reason != "":
				item_text += " [X]"
			select.add_item(item_text)
			if lock_reason != "":
				var idx: int = select.item_count - 1
				select.set_item_disabled(idx, true)
				select.set_item_tooltip(idx, lock_reason)

func _select_index_to_activity(key: String, display_index: int) -> Dictionary:
	# Map OptionButton index (which includes separators) to activity
	var acts: Array[Dictionary] = _grid_activities.get(key, [])
	var select: OptionButton = _grid_selects.get(key, null)
	if select == null or display_index < 0:
		return {}
	# Count non-separator items up to display_index
	var act_idx: int = -1
	for i: int in range(display_index + 1):
		if not select.is_item_separator(i):
			act_idx += 1
	if act_idx >= 0 and act_idx < acts.size():
		return acts[act_idx]
	return {}

func _get_selected_activity_id(key: String) -> String:
	var act: Dictionary = _select_index_to_activity(key, _grid_selects.get(key, null).selected if _grid_selects.has(key) else -1)
	return String(act.get("id", ""))

func _select_activity_by_id(select: OptionButton, key: String, act_id: String) -> void:
	if select == null:
		return
	var acts: Array[Dictionary] = _grid_activities.get(key, [])
	var act_idx: int = -1
	for i: int in acts.size():
		if acts[i].get("id", "") == act_id:
			act_idx = i
			break
	if act_idx < 0:
		return
	# Find the display index that maps to this activity index
	var count: int = -1
	for i: int in select.item_count:
		if not select.is_item_separator(i):
			count += 1
			if count == act_idx:
				select.selected = i
				return

func _on_column_changed(index: int, slot_id: String) -> void:
	if index == 0 or _updating_column:
		return
	_updating_column = true
	# The column select has "---" at 0, then grouped items with separators
	# Map to the activity the same way as day cells
	var col_select: OptionButton = _column_selects[slot_id]
	var col_acts: Array[Dictionary] = _column_activities.get(slot_id, [])
	# Count non-separator items (excluding the "---" at 0)
	var act_idx: int = -1
	for i: int in range(1, index + 1):
		if not col_select.is_item_separator(i):
			act_idx += 1
	if act_idx < 0 or act_idx >= col_acts.size():
		_updating_column = false
		return
	var target_id: String = String(col_acts[act_idx].get("id", ""))
	for day_id: String in DAYS:
		var key: String = day_id + "_" + slot_id
		if not _day_resolved.get(day_id, false):
			var select: OptionButton = _grid_selects.get(key, null)
			if select:
				_select_activity_by_id(select, key, target_id)
				_update_select_tooltip(select, key, slot_id)
	_updating_column = false

func _on_grid_select_changed(_index: int, key: String, slot_id: String) -> void:
	var select: OptionButton = _grid_selects.get(key, null)
	if select:
		_update_select_tooltip(select, key, slot_id)
	# Reset column header to label when individual cell changes
	if not _updating_column and _column_selects.has(slot_id):
		_column_selects[slot_id].selected = 0

func _update_select_tooltip(select: OptionButton, key: String, slot_id: String) -> void:
	var act: Dictionary = _select_index_to_activity(key, select.selected)
	if act.is_empty():
		select.tooltip_text = ""
		return
	var desc: String = I18n.text(act.get("desc", ""))
	var modifiers: Dictionary = act.get("slot_modifiers", {})
	var mod: float = float(modifiers.get(slot_id, 1.0))
	var mod_text: String = ""
	if mod > 1.01:
		mod_text = "\n^ " + str(int(mod * 100)) + "% synergy"
	elif mod < 0.99:
		mod_text = "\nv " + str(int(mod * 100)) + "% penalty"
	select.tooltip_text = desc + mod_text

func _select_first_item(select: OptionButton) -> void:
	for i: int in select.item_count:
		if not select.is_item_separator(i):
			select.selected = i
			return

func _apply_default_week() -> void:
	# Realistic 15yo student schedule
	# Weekdays: study morning, varied afternoon, rest/social night, sleep late_night
	# Weekend: free morning, active afternoon, social night, sleep late_night
	var weekday_plan: Dictionary = {
		"morning":    ["study", "train_speed", "study", "train_strength", "study"],
		"afternoon":  ["train_agility", "train_perception", "train_balance", "cook", "pickup_football"],
		"night":      ["browse_phone", "train_intelligence", "watch_tv", "train_charisma", "play_games"],
		"late_night": ["sleep", "sleep", "sleep", "sleep", "sleep"],
	}
	var weekend_plan: Dictionary = {
		"morning":    ["rest", "train_stamina"],
		"afternoon":  ["pickup_football", "train_dexterity"],
		"night":      ["play_games", "browse_phone"],
		"late_night": ["sleep", "sleep"],
	}
	for slot_id: String in SLOTS:
		var day_idx: int = 0
		for day_id: String in DAYS:
			var key: String = day_id + "_" + slot_id
			var act_id: String = ""
			if day_idx < 5:  # weekday
				var options: Array = weekday_plan.get(slot_id, [])
				if not options.is_empty():
					act_id = options[day_idx % options.size()]
			else:  # weekend
				var options: Array = weekend_plan.get(slot_id, [])
				if not options.is_empty():
					act_id = options[(day_idx - 5) % options.size()]
			if act_id != "":
				var select: OptionButton = _grid_selects.get(key, null)
				if select:
					_select_activity_by_id(select, key, act_id)
			day_idx += 1

func _on_clear() -> void:
	if _resolving:
		return
	for key: String in _grid_selects:
		var select: OptionButton = _grid_selects[key]
		_select_first_item(select)
		_reset_select_color(select)
	for day_id: String in DAYS:
		var key: String = day_id + "_late_night"
		_select_activity_by_id(_grid_selects.get(key, null), key, "sleep")
	for day_id: String in DAYS:
		_day_resolved[day_id] = false
		_day_slot_index[day_id] = 0
		_day_play_buttons[day_id].text = ">"
		_day_play_buttons[day_id].disabled = false
		_day_fast_buttons[day_id].text = ">>"
		_day_fast_buttons[day_id].disabled = false

func _set_select_color(select: OptionButton, color: Color) -> void:
	select.add_theme_color_override("font_color", color)
	select.add_theme_color_override("font_focus_color", color)

func _reset_select_color(select: OptionButton) -> void:
	select.remove_theme_color_override("font_color")
	select.remove_theme_color_override("font_focus_color")

# --- Room ---

func _build_room() -> void:
	_rebuild_room()

func _rebuild_room() -> void:
	for child: Node in room_panel.get_children():
		child.queue_free()
	var items: Array[Dictionary] = [
		{"label": T_MIRROR, "id": "mirror", "key": "M"},
		{"label": T_PHONE, "id": "phone", "key": ""},
		{"label": T_COMPUTER, "id": "computer", "key": ""},
		{"label": T_FRIDGE, "id": "fridge", "key": "F"},
		{"label": T_WARDROBE, "id": "wardrobe", "key": ""},
	]
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 4)
	for item: Dictionary in items:
		var btn: Button = Button.new()
		var key_hint: String = " [" + item["key"] + "]" if item["key"] != "" else ""
		btn.text = I18n.text(item["label"]) + key_hint
		btn.custom_minimum_size = Vector2(0, 32)
		btn.add_theme_font_size_override("font_size", 11)
		btn.pressed.connect(_on_room_item.bind(item["id"]))
		hbox.add_child(btn)
	room_panel.add_child(hbox)

func _on_room_item(item_id: String) -> void:
	match item_id:
		"fridge":
			_toggle_fridge_window()
		"mirror":
			_toggle_mirror_window()
		_:
			_log("[" + item_id.capitalize() + I18n.text(T_NOT_IMPL) + "]", COLOR_DEFAULT)

# --- Fridge window ---

func _toggle_fridge_window() -> void:
	if _fridge_window != null and is_instance_valid(_fridge_window):
		_fridge_window.queue_free()
		_fridge_window = null
		return
	_fridge_window = Window.new()
	_fridge_window.title = I18n.text(T_FRIDGE_TITLE)
	_fridge_window.size = Vector2i(250, 120)
	_fridge_window.position = Vector2i(600, 300)
	_fridge_window.unresizable = true
	_fridge_window.close_requested.connect(_close_fridge_window)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)

	_fridge_label = Label.new()
	_fridge_label.add_theme_font_size_override("font_size", 18)
	_update_fridge_display()
	margin.add_child(_fridge_label)

	_fridge_window.add_child(margin)
	add_child(_fridge_window)

func _close_fridge_window() -> void:
	if _fridge_window != null and is_instance_valid(_fridge_window):
		_fridge_window.queue_free()
		_fridge_window = null

# --- Mirror window (character sheet) ---

func _toggle_mirror_window() -> void:
	if _mirror_window != null and is_instance_valid(_mirror_window):
		_mirror_window.queue_free()
		_mirror_window = null
		return
	_mirror_window = Window.new()
	_mirror_window.title = I18n.text(T_MIRROR_TITLE)
	_mirror_window.size = Vector2i(380, 500)
	_mirror_window.position = Vector2i(500, 100)
	_mirror_window.close_requested.connect(_close_mirror_window)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 12)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	var player_name: String = String(The.session.get("player_name", ""))
	var player_age: int = int(The.session.get("player_age", 15))
	var gender: String = String(The.session.get("player_gender", "male"))
	var gender_str: String = "M" if gender == "male" else "F"

	var header: Label = Label.new()
	header.text = player_name + "  |  " + str(player_age) + "  |  " + gender_str
	header.add_theme_font_size_override("font_size", 18)
	vbox.add_child(header)
	vbox.add_child(HSeparator.new())

	# Stats with active effect modifiers
	var stat_def: Def = Drive.def("stat")
	if stat_def:
		for group: Dictionary in stat_def.list_groups():
			var group_label: Label = Label.new()
			group_label.text = I18n.text(group["label"])
			group_label.add_theme_font_size_override("font_size", 13)
			group_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			vbox.add_child(group_label)
			for s: Dictionary in group["stats"]:
				var sid: String = s["id"]
				var base_val: int = int(The.session.get("player_stats", {}).get(sid, stat_def.base_for(sid)))
				var row: HBoxContainer = HBoxContainer.new()
				row.add_theme_constant_override("separation", 8)
				var name_label: Label = Label.new()
				name_label.text = I18n.text(s.get("name", sid))
				name_label.custom_minimum_size = Vector2(120, 0)
				name_label.add_theme_font_size_override("font_size", 13)
				row.add_child(name_label)
				var val_label: Label = Label.new()
				val_label.text = str(base_val)
				val_label.add_theme_font_size_override("font_size", 13)
				val_label.custom_minimum_size = Vector2(30, 0)
				val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				row.add_child(val_label)
				# Show effect modifier if any active effect touches this stat's category
				var cat_id: String = String(group.get("id", ""))
				var total_mod: float = 1.0
				for eff: Dictionary in _active_effects:
					var cb: Dictionary = eff.get("category_bonus", {})
					if cb.has(cat_id):
						total_mod *= float(cb[cat_id])
				if total_mod > 1.01 or total_mod < 0.99:
					var mod_label: Label = Label.new()
					var pct: int = int(total_mod * 100)
					mod_label.text = " (" + str(pct) + "%)"
					mod_label.add_theme_font_size_override("font_size", 12)
					mod_label.add_theme_color_override("font_color", COLOR_SYNERGY if total_mod > 1.0 else COLOR_COLLAPSE)
					row.add_child(mod_label)
				vbox.add_child(row)

	vbox.add_child(HSeparator.new())

	# Skills
	var skill_def: Def = Drive.def("skill")
	if skill_def:
		for group: Dictionary in skill_def.list_groups():
			var group_label: Label = Label.new()
			group_label.text = I18n.text(group["label"])
			group_label.add_theme_font_size_override("font_size", 13)
			group_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			vbox.add_child(group_label)
			for s: Dictionary in group["stats"]:
				var sid: String = s["id"]
				var val: int = int(The.session.get("player_stats", {}).get(sid, 0))
				var row: HBoxContainer = HBoxContainer.new()
				row.add_theme_constant_override("separation", 8)
				var name_label: Label = Label.new()
				name_label.text = I18n.text(s.get("name", sid))
				name_label.custom_minimum_size = Vector2(120, 0)
				name_label.add_theme_font_size_override("font_size", 13)
				name_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
				row.add_child(name_label)
				var val_label: Label = Label.new()
				val_label.text = str(val)
				val_label.add_theme_font_size_override("font_size", 13)
				val_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
				val_label.custom_minimum_size = Vector2(30, 0)
				val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				row.add_child(val_label)
				vbox.add_child(row)

	# Active effects section
	if not _active_effects.is_empty():
		vbox.add_child(HSeparator.new())
		var eff_header: Label = Label.new()
		eff_header.text = I18n.text(T_EFFECTS)
		eff_header.add_theme_font_size_override("font_size", 13)
		eff_header.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		vbox.add_child(eff_header)
		for eff: Dictionary in _active_effects:
			var eff_row: HBoxContainer = HBoxContainer.new()
			eff_row.add_theme_constant_override("separation", 8)
			var icon: String = String(eff.get("icon", "?"))
			var is_buff: bool = icon == "^"
			var eff_label: Label = Label.new()
			eff_label.text = icon + " " + I18n.text(eff.get("name", "?")) + " (" + str(int(eff.get("duration", 0))) + ")"
			eff_label.add_theme_font_size_override("font_size", 13)
			eff_label.add_theme_color_override("font_color", COLOR_SYNERGY if is_buff else COLOR_COLLAPSE)
			eff_row.add_child(eff_label)
			# Show what categories it affects
			var cats: PackedStringArray = PackedStringArray()
			for cat_key: String in eff.get("category_bonus", {}):
				var mod_val: float = float(eff["category_bonus"][cat_key])
				cats.append(cat_key + " " + str(int(mod_val * 100)) + "%")
			if not cats.is_empty():
				var cat_label: Label = Label.new()
				cat_label.text = "  [" + ", ".join(cats) + "]"
				cat_label.add_theme_font_size_override("font_size", 11)
				cat_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
				eff_row.add_child(cat_label)
			vbox.add_child(eff_row)

	margin.add_child(vbox)
	scroll.add_child(margin)
	_mirror_window.add_child(scroll)
	add_child(_mirror_window)

func _close_mirror_window() -> void:
	if _mirror_window != null and is_instance_valid(_mirror_window):
		_mirror_window.queue_free()
		_mirror_window = null

func _update_fridge_display() -> void:
	if _fridge_label == null or not is_instance_valid(_fridge_label):
		return
	var meals: int = int(The.session.get("fridge_meals", 0))
	_fridge_label.text = I18n.text(T_FRIDGE_MEALS) + str(meals)

# --- Vitals ---

func _build_vitals() -> void:
	var vital_ids: Array[String] = ["hp", "energy", "hunger", "social", "leisure", "room"]
	for vid: String in vital_ids:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)

		var label: Label = Label.new()
		label.text = I18n.text(VITAL_NAMES.get(vid, vid))
		label.add_theme_font_size_override("font_size", 12)
		label.custom_minimum_size = Vector2(50, 0)
		row.add_child(label)
		_vital_labels[vid] = label

		var bar: ProgressBar = ProgressBar.new()
		bar.min_value = 0
		bar.max_value = 100
		bar.custom_minimum_size = Vector2(60, 12)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.show_percentage = false
		row.add_child(bar)
		_vital_bars[vid] = bar

		var val_label: Label = Label.new()
		val_label.text = "0/100"
		val_label.add_theme_font_size_override("font_size", 11)
		val_label.custom_minimum_size = Vector2(45, 0)
		val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(val_label)
		_vital_value_labels[vid] = val_label

		vitals_panel.add_child(row)

func _update_vitals() -> void:
	var vitals: Dictionary = The.session.get("vitals", {})
	for vid: String in _vital_bars:
		var val: int = int(vitals.get(vid, 0))
		(_vital_bars[vid] as ProgressBar).value = val
		_vital_value_labels[vid].text = str(val) + "/100"

# --- Resolve single slot ---

func _next_unresolved_day() -> String:
	for d: String in DAYS:
		if not _day_resolved.get(d, false):
			return d
	return ""

func _can_play_day(day_id: String) -> bool:
	if _day_resolved.get(day_id, false):
		return false
	var next: String = _next_unresolved_day()
	return next == "" or next == day_id

func _on_play_slot(day_id: String) -> void:
	if _resolving or not _can_play_day(day_id):
		return
	var slot_idx: int = _day_slot_index.get(day_id, 0)
	if slot_idx >= SLOTS.size():
		return
	_resolving = true
	_set_buttons_enabled(false)
	await _resolve_slot(day_id, SLOTS[slot_idx])
	_day_slot_index[day_id] = slot_idx + 1
	if _day_slot_index[day_id] >= SLOTS.size():
		_mark_day_done(day_id)
	_resolving = false
	_set_buttons_enabled(true)

func _on_play_day(day_id: String) -> void:
	if _resolving or not _can_play_day(day_id):
		return
	_resolving = true
	_set_buttons_enabled(false)
	var start_idx: int = _day_slot_index.get(day_id, 0)
	for i: int in range(start_idx, SLOTS.size()):
		await _resolve_slot(day_id, SLOTS[i])
		_day_slot_index[day_id] = i + 1
	_mark_day_done(day_id)
	_resolving = false
	_set_buttons_enabled(true)

func _mark_day_done(day_id: String) -> void:
	_day_resolved[day_id] = true
	_day_play_buttons[day_id].text = "ok"
	_day_play_buttons[day_id].disabled = true
	_day_fast_buttons[day_id].text = "ok"
	_day_fast_buttons[day_id].disabled = true
	_finalize_if_week_done()

# --- Resolve full week ---

func _on_next_week() -> void:
	if _resolving:
		return
	_resolving = true
	_set_buttons_enabled(false)
	for day_id: String in DAYS:
		if _day_resolved.get(day_id, false):
			continue
		var start_idx: int = _day_slot_index.get(day_id, 0)
		for i: int in range(start_idx, SLOTS.size()):
			await _resolve_slot(day_id, SLOTS[i])
			_day_slot_index[day_id] = i + 1
		_day_resolved[day_id] = true
		_day_play_buttons[day_id].text = "ok"
		_day_play_buttons[day_id].disabled = true
		_day_fast_buttons[day_id].text = "ok"
		_day_fast_buttons[day_id].disabled = true
	_finalize_week()
	_resolving = false
	_set_buttons_enabled(true)

func _set_buttons_enabled(enabled: bool) -> void:
	btn_next_week.disabled = not enabled
	btn_clear.disabled = not enabled
	for day_id: String in _day_play_buttons:
		if not _day_resolved.get(day_id, false):
			(_day_play_buttons[day_id] as Button).disabled = not enabled
			(_day_fast_buttons[day_id] as Button).disabled = not enabled

# --- Core slot resolution ---

func _resolve_slot(day_id: String, slot_id: String) -> void:
	var vitals: Dictionary = The.session.get("vitals", {}).duplicate()
	var money: int = int(The.session.get("money", 0))
	var day_text: String = I18n.text(DAY_LABELS[day_id])

	var key: String = day_id + "_" + slot_id
	var select: OptionButton = _grid_selects.get(key, null)
	if select == null:
		return
	var act: Dictionary = {}
	var collapsed: bool = false
	var fridge_meals: int = int(The.session.get("fridge_meals", 0))

	# Check vital collapse — hunger uses fridge first
	for vid: String in vitals:
		if int(vitals[vid]) <= 0:
			if vid == "hunger" and fridge_meals > 0:
				# Eat from fridge silently — no collapse
				fridge_meals -= 1
				The.session["fridge_meals"] = fridge_meals
				vitals["hunger"] = clampi(int(vitals["hunger"]) + 25, 0, 100)
				_log(day_text + " " + SLOT_ICONS[slot_id] + " [=] " + I18n.text({"pt": "Comeu uma refeicao da geladeira", "en": "Ate a meal from the fridge"}) + " (" + str(fridge_meals) + ")", COLOR_NORMAL)
				_update_fridge_display()
				continue
			var recovery: Dictionary = _activity_def.get_recovery_for(vid)
			if not recovery.is_empty():
				act = recovery
				collapsed = true
				break

	# If no collapse, use the planned activity
	if not collapsed:
		act = _select_index_to_activity(key, select.selected)
		if act.is_empty():
			return

	var act_name: String = I18n.text(act.get("name", "?"))

	# Mark as running
	_set_select_color(select, COLOR_RUNNING)
	await get_tree().create_timer(SLOT_DELAY * 0.3).timeout

	# Slot modifier
	var modifiers: Dictionary = act.get("slot_modifiers", {})
	var modifier: float = float(modifiers.get(slot_id, 1.0))

	# Active effects modifier: multiply by category bonuses
	var act_category: String = String(act.get("category", ""))
	if act_category != "" and not collapsed:
		for eff: Dictionary in _active_effects:
			var cat_bonus: Dictionary = eff.get("category_bonus", {})
			if cat_bonus.has(act_category):
				modifier *= float(cat_bonus[act_category])

	# Apply effects scaled by modifier, track deltas
	var effects: Dictionary = act.get("effects", {})
	var deltas: Dictionary = {}
	for vid: String in effects.keys():
		var base_effect: float = float(effects[vid])
		var scaled: int = int(base_effect * modifier)
		var current: int = int(vitals.get(vid, 0))
		var new_val: int = clampi(current + scaled, 0, 100)
		deltas[vid] = new_val - current
		vitals[vid] = new_val

	var money_delta: int = int(int(act.get("money", 0)) * modifier)
	money += money_delta

	# Late night penalty: not sleeping in late_night costs extra energy
	var act_id: String = String(act.get("id", ""))
	if slot_id == "late_night" and not collapsed and act_id != "sleep":
		var penalty: int = -15
		var current_ene: int = int(vitals.get("energy", 0))
		vitals["energy"] = clampi(current_ene + penalty, 0, 100)
		deltas["energy"] = int(deltas.get("energy", 0)) + penalty

	# Fridge: cooking adds meals
	var fridge_add: int = int(act.get("fridge_add", 0))
	if fridge_add > 0:
		fridge_meals += fridge_add
		The.session["fridge_meals"] = fridge_meals
		_update_fridge_display()

	# Roll event if activity has events
	var event_text: String = ""
	var event_rolled: Dictionary = {}
	var events_raw: Variant = act.get("events", null)
	if not collapsed and events_raw is Array and not (events_raw as Array).is_empty():
		event_rolled = _roll_event(events_raw as Array)
		if not event_rolled.is_empty():
			event_text = I18n.text(event_rolled.get("text", ""))
			# Apply stat bonuses
			var stat_bonus: Dictionary = event_rolled.get("stat_bonus", {})
			for sid: String in stat_bonus.keys():
				var player_stats: Dictionary = The.session.get("player_stats", {})
				player_stats[sid] = int(player_stats.get(sid, 0)) + int(stat_bonus[sid])
				The.session["player_stats"] = player_stats
			# Apply vital bonuses
			var vital_bonus: Dictionary = event_rolled.get("vital_bonus", {})
			for vid: String in vital_bonus.keys():
				var current: int = int(vitals.get(vid, 0))
				var bonus: int = int(vital_bonus[vid])
				vitals[vid] = clampi(current + bonus, 0, 100)
				deltas[vid] = int(deltas.get(vid, 0)) + bonus
			# Create timed effect if event defines one
			var effect_def: Variant = event_rolled.get("effect", null)
			if effect_def is Dictionary:
				_add_effect(effect_def as Dictionary)

	# Tick down active effects
	_tick_effects()

	# Determine color: green=synergy, yellow=normal, red=collapse
	var is_synergy: bool = not collapsed and modifier > 1.01
	var outcome_color: Color
	if collapsed:
		outcome_color = COLOR_COLLAPSE
	elif is_synergy:
		outcome_color = COLOR_SYNERGY
	else:
		outcome_color = COLOR_NORMAL
	_track_slot(act, collapsed, is_synergy)

	# Update state
	The.session["vitals"] = vitals
	The.session["money"] = money
	_update_vitals()
	_update_header()

	# Build log line
	var money_str: String = ""
	if money_delta > 0:
		money_str = " (+R$" + str(money_delta) + ")"
	elif money_delta < 0:
		money_str = " (-R$" + str(absi(money_delta)) + ")"

	var delta_parts: Array[String] = []
	for vid: String in deltas:
		var d: int = deltas[vid]
		if d != 0:
			var prefix: String = "+" if d > 0 else ""
			delta_parts.append(vid.substr(0, 3) + prefix + str(d))
	var delta_str: String = ""
	if not delta_parts.is_empty():
		delta_str = " (" + ", ".join(delta_parts) + ")"

	_log(day_text + " " + SLOT_ICONS[slot_id] + " " + act_name + money_str + delta_str, outcome_color)
	if event_text != "":
		var event_type: String = String(event_rolled.get("type", "neutral"))
		var event_color: Color = COLOR_SYNERGY if event_type == "positive" else (COLOR_COLLAPSE if event_type == "negative" else COLOR_NORMAL)
		_log("    " + event_text, event_color)

	# Color the dropdown + update text if collapsed
	_set_select_color(select, outcome_color)
	if collapsed:
		var sel_idx: int = select.selected
		if sel_idx >= 0:
			select.set_item_text(sel_idx, act_name)

	await get_tree().create_timer(SLOT_DELAY * 0.7).timeout
	# Pause check
	while _paused:
		await get_tree().create_timer(0.1).timeout

func _finalize_if_week_done() -> void:
	for day_id: String in DAYS:
		if not _day_resolved.get(day_id, false):
			_update_effects_check()
			return
	_finalize_week()

func _finalize_week() -> void:
	var vitals: Dictionary = The.session.get("vitals", {})
	_effects.clear()
	for vid: String in vitals:
		if int(vitals[vid]) <= 20:
			_effects.append({"name": I18n.text(VITAL_NAMES.get(vid, vid)) + " LOW", "type": "debuff"})

	var day: int = int(The.session.get("day", 1)) + 7
	The.session["day"] = day
	@warning_ignore("integer_division")
	The.session["week"] = ((day - 1) / 7) + 1

	_update_header()
	_update_effects()
	_log("--- " + I18n.text(T_WEEK) + " " + str(The.session["week"]) + " ---", COLOR_DEFAULT)

	_show_week_summary()
	_reset_week_tracking()
	_load_quests()

	# Save current selections for carryover
	_last_week_selections.clear()
	for key: String in _grid_selects:
		_last_week_selections[key] = _get_selected_activity_id(key)

	# Reset grid for next week
	for day_id: String in DAYS:
		_day_resolved[day_id] = false
		_day_slot_index[day_id] = 0
		_day_play_buttons[day_id].text = ">"
		_day_play_buttons[day_id].disabled = false
		_day_fast_buttons[day_id].text = ">>"
		_day_fast_buttons[day_id].disabled = false
	for key: String in _grid_selects:
		var select: OptionButton = _grid_selects[key]
		_reset_select_color(select)
		var slot_id: String = key.substr(key.find("_") + 1) if "_" in key else ""
		select.clear()
		if slot_id != "":
			_populate_grouped_select(select, slot_id)
		_select_first_item(select)

	# Restore previous week's selections
	for key: String in _last_week_selections:
		var prev_id: String = _last_week_selections[key]
		if prev_id != "":
			var select: OptionButton = _grid_selects.get(key, null)
			if select:
				_select_activity_by_id(select, key, prev_id)
	for slot_id: String in _column_selects:
		_column_selects[slot_id].selected = 0

func _update_effects_check() -> void:
	_update_effects()

func _make_effect_card(text: String, color: Color, bg_color: Color) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = color
	panel.add_theme_stylebox_override("panel", style)
	var label: Label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 11)
	panel.add_child(label)
	return panel

func _update_effects() -> void:
	for child: Node in effects_bar.get_children():
		child.queue_free()
	# Vital warnings as cards
	var vitals: Dictionary = The.session.get("vitals", {})
	for vid: String in vitals:
		if int(vitals[vid]) <= 20:
			var card: PanelContainer = _make_effect_card(
				I18n.text(VITAL_NAMES.get(vid, vid)) + " LOW",
				COLOR_COLLAPSE, Color(0.15, 0.05, 0.05))
			effects_bar.add_child(card)
	# Timed effects as cards
	for eff: Dictionary in _active_effects:
		var eff_name: String = I18n.text(eff.get("name", "?"))
		var dur: int = int(eff.get("duration", 0))
		var icon: String = String(eff.get("icon", "?"))
		var is_buff: bool = icon == "^"
		var color: Color = COLOR_SYNERGY if is_buff else COLOR_COLLAPSE
		var bg: Color = Color(0.05, 0.12, 0.05) if is_buff else Color(0.15, 0.05, 0.05)
		var card: PanelContainer = _make_effect_card(
			icon + " " + eff_name + " (" + str(dur) + ")",
			color, bg)
		effects_bar.add_child(card)

# --- Quests ---

func _load_quests() -> void:
	_current_quests.clear()
	_quest_labels.clear()
	_quest_activity_counts.clear()
	for child: Node in quest_list.get_children():
		child.queue_free()
	var week: int = int(The.session.get("week", 1))
	var all_quest_jsons: Array[Dictionary] = Drive.list_json_by_group("quest")
	for raw: Dictionary in all_quest_jsons:
		if int(raw.get("week", 0)) == week:
			var quests: Variant = raw.get("quests", [])
			if quests is Array:
				for q: Variant in (quests as Array):
					if q is Dictionary:
						_current_quests.append(q as Dictionary)
			break
	for quest: Dictionary in _current_quests:
		var label: Label = Label.new()
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", COLOR_QUEST_PENDING)
		label.tooltip_text = I18n.text(quest.get("desc", ""))
		label.text = "[ ] " + I18n.text(quest.get("name", "?"))
		quest_list.add_child(label)
		_quest_labels.append(label)

func _update_quests() -> void:
	for i: int in _current_quests.size():
		if i >= _quest_labels.size():
			break
		var quest: Dictionary = _current_quests[i]
		var done: bool = _is_quest_done(quest)
		var label: Label = _quest_labels[i]
		var mark: String = "[x] " if done else "[ ] "
		label.text = mark + I18n.text(quest.get("name", "?"))
		label.add_theme_color_override("font_color", COLOR_QUEST_DONE if done else COLOR_QUEST_PENDING)

func _is_quest_done(quest: Dictionary) -> bool:
	var qtype: String = String(quest.get("type", ""))
	var target: int = int(quest.get("target", 0))
	match qtype:
		"activity_count":
			var q_act_id: String = String(quest.get("activity_id", ""))
			var count: int = int(_quest_activity_counts.get(q_act_id, 0))
			return count >= target
		"activity_category_count":
			var cat_id: String = String(quest.get("category", ""))
			var total: int = 0
			for q_act_id: String in _quest_activity_counts:
				var act_data: Dictionary = _activity_def.get_activity(q_act_id)
				if String(act_data.get("category", "")) == cat_id:
					total += int(_quest_activity_counts[q_act_id])
			return total >= target
		"max_collapses":
			return _week_collapses <= target
	return false

func _track_quest_activity(act_id: String) -> void:
	_quest_activity_counts[act_id] = int(_quest_activity_counts.get(act_id, 0)) + 1
	_update_quests()

func _quests_completed() -> int:
	var count: int = 0
	for quest: Dictionary in _current_quests:
		if _is_quest_done(quest):
			count += 1
	return count

# --- Timed effects ---

func _add_effect(effect_def: Dictionary) -> void:
	var eff: Dictionary = {
		"name": effect_def.get("name", ""),
		"duration": int(effect_def.get("duration", 1)),
		"category_bonus": effect_def.get("category_bonus", {}),
		"icon": String(effect_def.get("icon", "?")),
	}
	_active_effects.append(eff)
	_update_effects()

func _tick_effects() -> void:
	var remaining: Array[Dictionary] = []
	for eff: Dictionary in _active_effects:
		eff["duration"] = int(eff["duration"]) - 1
		if int(eff["duration"]) > 0:
			remaining.append(eff)
	_active_effects = remaining
	_update_effects()

# --- Event rolling ---

func _roll_event(events: Array) -> Dictionary:
	var total_chance: float = 0.0
	for e: Variant in events:
		if e is Dictionary:
			total_chance += float((e as Dictionary).get("chance", 0.0))
	if total_chance <= 0.0:
		return {}
	var roll: float = randf() * total_chance
	var acc: float = 0.0
	for e: Variant in events:
		if not e is Dictionary:
			continue
		var entry: Dictionary = e as Dictionary
		acc += float(entry.get("chance", 0.0))
		if roll <= acc:
			return entry
	return {}

# --- Week tracking ---

func _reset_week_tracking() -> void:
	_week_collapses = 0
	_week_synergies = 0
	_week_money_start = int(The.session.get("money", 0))
	_week_vitals_start = The.session.get("vitals", {}).duplicate()
	_week_activities.clear()
	_quest_activity_counts.clear()

func _track_slot(act: Dictionary, collapsed: bool, synergy: bool) -> void:
	if collapsed:
		_week_collapses += 1
	if synergy:
		_week_synergies += 1
	var act_id: String = String(act.get("id", "?"))
	var color_rank: int = 2 if collapsed else (0 if synergy else 1)
	var key: String = act_id + "_" + str(color_rank)
	if not _week_activities.has(key):
		_week_activities[key] = {"id": act_id, "count": 0, "color_rank": color_rank}
	_week_activities[key]["count"] = int(_week_activities[key]["count"]) + 1
	_track_quest_activity(act_id)

func _show_week_summary() -> void:
	var vitals_now: Dictionary = The.session.get("vitals", {})
	var money_now: int = int(The.session.get("money", 0))
	var money_delta: int = money_now - _week_money_start

	# Build summary text
	var lines: Array[String] = []

	# Vitals comparison
	for vid: String in vitals_now:
		var before: int = int(_week_vitals_start.get(vid, 0))
		var after: int = int(vitals_now[vid])
		var diff: int = after - before
		var prefix: String = "+" if diff > 0 else ""
		var vname: String = I18n.text(VITAL_NAMES.get(vid, vid))
		lines.append(vname + ": " + str(before) + " -> " + str(after) + " (" + prefix + str(diff) + ")")

	lines.append("")

	# Money
	var m_prefix: String = "+" if money_delta >= 0 else ""
	lines.append(I18n.text(T_MONEY_CHANGE) + ": R$" + str(_week_money_start) + " -> R$" + str(money_now) + " (" + m_prefix + "R$" + str(money_delta) + ")")

	# Quest results
	if not _current_quests.is_empty():
		lines.append("")
		lines.append("[b]" + I18n.text(T_QUESTS) + "[/b]")
		for quest: Dictionary in _current_quests:
			var done: bool = _is_quest_done(quest)
			var qname: String = I18n.text(quest.get("name", "?"))
			var mark: String = "[x]" if done else "[ ]"
			var hex: String = COLOR_QUEST_DONE.to_html(false) if done else COLOR_COLLAPSE.to_html(false)
			lines.append("  [color=#" + hex + "]" + mark + " " + qname + "[/color]")
		lines.append("  " + str(_quests_completed()) + "/" + str(_current_quests.size()))

	# Activities sorted by color (green, yellow, red) then by count desc
	if not _week_activities.is_empty():
		lines.append("")
		lines.append("[b]" + I18n.text(T_ACTIVITIES) + "[/b]")
		var sorted_acts: Array[Dictionary] = []
		for key: String in _week_activities:
			var entry: Dictionary = _week_activities[key]
			sorted_acts.append({"id": entry["id"], "count": int(entry["count"]), "color_rank": int(entry["color_rank"])})
		sorted_acts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			if int(a["color_rank"]) != int(b["color_rank"]):
				return int(a["color_rank"]) < int(b["color_rank"])
			return int(a["count"]) > int(b["count"]))
		var rank_colors: Array[Color] = [COLOR_SYNERGY, COLOR_NORMAL, COLOR_COLLAPSE]
		for entry: Dictionary in sorted_acts:
			var act_data: Dictionary = _activity_def.get_activity(entry["id"])
			var act_name: String = I18n.text(act_data.get("name", entry["id"]))
			var hex: String = rank_colors[int(entry["color_rank"])].to_html(false)
			lines.append("  [color=#" + hex + "]" + act_name + " x" + str(entry["count"]) + "[/color]")

	# Create popup
	var week_num: int = int(The.session.get("week", 1)) - 1
	var popup: AcceptDialog = AcceptDialog.new()
	popup.title = I18n.text(T_SUMMARY) + " " + str(week_num)
	popup.ok_button_text = I18n.text(T_CLOSE)
	popup.min_size = Vector2(420, 460)

	var rtl: RichTextLabel = RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.custom_minimum_size = Vector2(400, 400)
	rtl.text = "\n".join(lines)
	popup.add_child(rtl)

	add_child(popup)
	popup.popup_centered()
	popup.confirmed.connect(popup.queue_free)
	popup.canceled.connect(popup.queue_free)

# --- Log ---

func _log(text: String, color: Color = COLOR_DEFAULT) -> void:
	if color != COLOR_DEFAULT:
		var hex: String = color.to_html(false)
		log_text.append_text("[color=#" + hex + "]" + text + "[/color]\n")
	else:
		log_text.append_text(text + "\n")
