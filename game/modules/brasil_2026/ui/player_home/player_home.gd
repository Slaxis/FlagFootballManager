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
	"energy":  {"pt": "Energia", "en": "Energy"},
	"hunger":  {"pt": "Fome",    "en": "Hunger"},
	"social":  {"pt": "Social",  "en": "Social"},
	"leisure": {"pt": "Lazer",   "en": "Leisure"},
}

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
@onready var grid_container: GridContainer = $Margin/VBox/Content/LeftPanel/WeekGrid
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
	_log(I18n.text(T_WELCOME), COLOR_DEFAULT)

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

		var col_select: OptionButton = OptionButton.new()
		col_select.add_theme_font_size_override("font_size", 9)
		col_select.custom_minimum_size = Vector2(0, 22)
		var available: Array[Dictionary] = _activity_def.list_for_slot(slot_id)
		_column_activities[slot_id] = available
		col_select.add_item("---")
		for act: Dictionary in available:
			col_select.add_item(I18n.text(act.get("name", "?")))
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
			for act: Dictionary in avail:
				select.add_item(I18n.text(act.get("name", "?")))
			select.item_selected.connect(_on_grid_select_changed.bind(key, slot_id))
			if slot_id == "late_night":
				for i: int in avail.size():
					if avail[i].get("id", "") == "sleep":
						select.selected = i
						break
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

func _on_column_changed(index: int, slot_id: String) -> void:
	if index == 0 or _updating_column:
		return  # header label selected, ignore
	_updating_column = true
	var act_index: int = index - 1  # offset by the header item
	for day_id: String in DAYS:
		var key: String = day_id + "_" + slot_id
		var select: OptionButton = _grid_selects.get(key, null)
		if select and not _day_resolved.get(day_id, false):
			var acts: Array[Dictionary] = _grid_activities.get(key, [])
			if act_index >= 0 and act_index < acts.size():
				select.selected = act_index
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
	var acts: Array[Dictionary] = _grid_activities.get(key, [])
	var index: int = select.selected
	if index < 0 or index >= acts.size():
		select.tooltip_text = ""
		return
	var act: Dictionary = acts[index]
	var desc: String = I18n.text(act.get("desc", ""))
	var modifiers: Dictionary = act.get("slot_modifiers", {})
	var mod: float = float(modifiers.get(slot_id, 1.0))
	var mod_text: String = ""
	if mod > 1.01:
		mod_text = "\n^ " + str(int(mod * 100)) + "% synergy"
	elif mod < 0.99:
		mod_text = "\nv " + str(int(mod * 100)) + "% penalty"
	select.tooltip_text = desc + mod_text

func _on_clear() -> void:
	if _resolving:
		return
	for key: String in _grid_selects:
		var select: OptionButton = _grid_selects[key]
		select.selected = 0
		_reset_select_color(select)
	for day_id: String in DAYS:
		var key: String = day_id + "_late_night"
		var select: OptionButton = _grid_selects.get(key, null)
		if select == null:
			continue
		var acts: Array[Dictionary] = _grid_activities.get(key, [])
		for i: int in acts.size():
			if acts[i].get("id", "") == "sleep":
				select.selected = i
				break
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
		{"label": T_PHONE, "id": "phone"},
		{"label": T_COMPUTER, "id": "computer"},
		{"label": T_FRIDGE, "id": "fridge"},
		{"label": T_WARDROBE, "id": "wardrobe"},
	]
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 8)
	for item: Dictionary in items:
		var btn: Button = Button.new()
		btn.text = I18n.text(item["label"])
		btn.custom_minimum_size = Vector2(90, 40)
		btn.pressed.connect(_on_room_item.bind(item["id"]))
		hbox.add_child(btn)
	room_panel.add_child(hbox)

func _on_room_item(item_id: String) -> void:
	_log("[" + item_id.capitalize() + I18n.text(T_NOT_IMPL) + "]", COLOR_DEFAULT)

# --- Vitals ---

func _build_vitals() -> void:
	var vital_ids: Array[String] = ["energy", "hunger", "social", "leisure"]
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

	# Check vital collapse first
	for vid: String in vitals:
		if int(vitals[vid]) <= 0:
			var recovery: Dictionary = _activity_def.get_recovery_for(vid)
			if not recovery.is_empty():
				act = recovery
				collapsed = true
				break

	# If no collapse, use the planned activity
	if not collapsed:
		var index: int = select.selected
		var acts: Array[Dictionary] = _grid_activities.get(key, [])
		if index < 0 or index >= acts.size():
			return
		act = acts[index]

	var act_name: String = I18n.text(act.get("name", "?"))

	# Mark as running
	_set_select_color(select, COLOR_RUNNING)
	await get_tree().create_timer(SLOT_DELAY * 0.3).timeout

	# Slot modifier
	var modifiers: Dictionary = act.get("slot_modifiers", {})
	var modifier: float = float(modifiers.get(slot_id, 1.0))

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

	# Reset grid for next week
	for day_id: String in DAYS:
		_day_resolved[day_id] = false
		_day_slot_index[day_id] = 0
		_day_play_buttons[day_id].text = ">"
		_day_play_buttons[day_id].disabled = false
		_day_fast_buttons[day_id].text = ">>"
		_day_fast_buttons[day_id].disabled = false
	for key: String in _grid_selects:
		_reset_select_color(_grid_selects[key])
		# Restore original item text if it was overwritten by collapse
		var select: OptionButton = _grid_selects[key]
		var acts: Array[Dictionary] = _grid_activities.get(key, [])
		if not acts.is_empty():
			for i: int in acts.size():
				select.set_item_text(i, I18n.text(acts[i].get("name", "?")))
	for slot_id: String in _column_selects:
		_column_selects[slot_id].selected = 0

func _update_effects_check() -> void:
	var vitals: Dictionary = The.session.get("vitals", {})
	_effects.clear()
	for vid: String in vitals:
		if int(vitals[vid]) <= 20:
			_effects.append({"name": I18n.text(VITAL_NAMES.get(vid, vid)) + " LOW", "type": "debuff"})
	_update_effects()

func _update_effects() -> void:
	for child: Node in effects_bar.get_children():
		child.queue_free()
	for effect: Dictionary in _effects:
		var label: Label = Label.new()
		label.text = " " + String(effect.get("name", "?")) + " "
		var is_debuff: bool = String(effect.get("type", "")) == "debuff"
		label.add_theme_color_override("font_color", COLOR_DEBUFF if is_debuff else COLOR_BUFF)
		label.add_theme_font_size_override("font_size", 12)
		effects_bar.add_child(label)

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
			var act_id: String = String(quest.get("activity_id", ""))
			var count: int = int(_quest_activity_counts.get(act_id, 0))
			return count >= target
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
