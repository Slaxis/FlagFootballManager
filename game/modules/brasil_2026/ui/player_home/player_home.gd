extends Control

const DAYS: Array[String] = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]
const SLOTS: Array[String] = ["morning", "afternoon", "night", "late_night"]

const DAY_LABELS: Dictionary = {
	"mon": {"pt": "SEG", "en": "MON"},
	"tue": {"pt": "TER", "en": "TUE"},
	"wed": {"pt": "QUA", "en": "WED"},
	"thu": {"pt": "QUI", "en": "THU"},
	"fri": {"pt": "SEX", "en": "FRI"},
	"sat": {"pt": "SÁB", "en": "SAT"},
	"sun": {"pt": "DOM", "en": "SUN"},
}
const SLOT_LABELS: Dictionary = {
	"morning":    {"pt": "MANHÃ",      "en": "MORN"},
	"afternoon":  {"pt": "TARDE",      "en": "AFT"},
	"night":      {"pt": "NOITE",      "en": "NITE"},
	"late_night": {"pt": "MADRUGADA",  "en": "LATE"},
}
const T_WEEK: Dictionary = {"pt": "Semana", "en": "Week"}
const T_DAY: Dictionary = {"pt": "Dia", "en": "Day"}
const T_PLAN: Dictionary = {"pt": "PLANEJE SUA SEMANA", "en": "PLAN YOUR WEEK"}
const T_NEXT_WEEK: Dictionary = {"pt": "PRÓXIMA SEMANA", "en": "NEXT WEEK"}
const T_CLEAR: Dictionary = {"pt": "LIMPAR", "en": "CLEAR"}
const T_ROOM: Dictionary = {"pt": "SEU QUARTO", "en": "YOUR ROOM"}
const T_VITALS: Dictionary = {"pt": "SINAIS VITAIS", "en": "VITALS"}
const T_WELCOME: Dictionary = {"pt": "Bem-vindo! Planeje sua semana.", "en": "Welcome home. Plan your week."}
const T_PHONE: Dictionary = {"pt": "Celular", "en": "Phone"}
const T_TV: Dictionary = {"pt": "TV", "en": "TV"}
const T_FRIDGE: Dictionary = {"pt": "Geladeira", "en": "Fridge"}
const T_WARDROBE: Dictionary = {"pt": "Armário", "en": "Wardrobe"}
const T_NOT_IMPL: Dictionary = {"pt": " — ainda não implementado", "en": " — not yet implemented"}

const VITAL_NAMES: Dictionary = {
	"energy":  {"pt": "Energia", "en": "Energy"},
	"hunger":  {"pt": "Fome",    "en": "Hunger"},
	"social":  {"pt": "Social",  "en": "Social"},
	"leisure": {"pt": "Lazer",   "en": "Leisure"},
}

const COLOR_DEBUFF := Color(0.8, 0.3, 0.3)
const COLOR_BUFF := Color(0.3, 0.7, 0.9)

var _activity_def: Def
var _grid_selects: Dictionary = {}  # "day_slot" -> OptionButton
var _grid_activities: Dictionary = {}  # "day_slot" -> Array[Dictionary]
var _vital_bars: Dictionary = {}
var _vital_labels: Dictionary = {}
var _effects: Array[Dictionary] = []

@onready var money_label: Label = $Margin/VBox/TopBar/MoneyLabel
@onready var day_label: Label = $Margin/VBox/TopBar/DayLabel
@onready var week_label: Label = $Margin/VBox/TopBar/WeekLabel
@onready var player_label: Label = $Margin/VBox/TopBar/PlayerLabel

@onready var plan_header: Label = $Margin/VBox/Content/LeftPanel/PlanHeader
@onready var grid_container: GridContainer = $Margin/VBox/Content/LeftPanel/GridScroll/WeekGrid
@onready var btn_next_week: Button = $Margin/VBox/Content/LeftPanel/ButtonRow/BtnNextWeek
@onready var btn_clear: Button = $Margin/VBox/Content/LeftPanel/ButtonRow/BtnClear

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
	_log(I18n.text(T_WELCOME))

# --- Text ---

func _update_text() -> void:
	plan_header.text = I18n.text(T_PLAN)
	btn_next_week.text = I18n.text(T_NEXT_WEEK)
	btn_clear.text = I18n.text(T_CLEAR)
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
	# Transposed: columns = slots, rows = days
	grid_container.columns = SLOTS.size() + 1

	# Corner cell
	var corner: Label = Label.new()
	corner.text = ""
	corner.custom_minimum_size = Vector2(36, 0)
	grid_container.add_child(corner)

	# Slot headers (columns)
	for slot_id: String in SLOTS:
		var header: Label = Label.new()
		header.text = I18n.text(SLOT_LABELS[slot_id])
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header.add_theme_font_size_override("font_size", 11)
		grid_container.add_child(header)

	# Day rows
	for day_id: String in DAYS:
		var row_label: Label = Label.new()
		row_label.text = I18n.text(DAY_LABELS[day_id])
		row_label.add_theme_font_size_override("font_size", 12)
		row_label.custom_minimum_size = Vector2(36, 0)
		grid_container.add_child(row_label)

		for slot_id: String in SLOTS:
			var available: Array[Dictionary] = _activity_def.list_for_slot(slot_id)
			var key: String = day_id + "_" + slot_id
			var select: OptionButton = OptionButton.new()
			select.custom_minimum_size = Vector2(0, 28)
			select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			select.add_theme_font_size_override("font_size", 10)
			_grid_activities[key] = available
			for act: Dictionary in available:
				select.add_item(I18n.text(act.get("name", "?")))
			# Default late_night to sleep
			if slot_id == "late_night":
				for i: int in available.size():
					if available[i].get("id", "") == "sleep":
						select.selected = i
						break
			_grid_selects[key] = select
			grid_container.add_child(select)

func _on_clear() -> void:
	for key: String in _grid_selects:
		(_grid_selects[key] as OptionButton).selected = 0

# --- Room ---

func _build_room() -> void:
	_rebuild_room()

func _rebuild_room() -> void:
	for child: Node in room_panel.get_children():
		child.queue_free()
	var items: Array[Dictionary] = [
		{"label": T_PHONE, "id": "phone"},
		{"label": T_TV, "id": "tv"},
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
	_log("[" + item_id.capitalize() + I18n.text(T_NOT_IMPL) + "]")

# --- Vitals ---

func _build_vitals() -> void:
	var vital_ids: Array[String] = ["energy", "hunger", "social", "leisure"]
	for vid: String in vital_ids:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		var label: Label = Label.new()
		label.text = I18n.text(VITAL_NAMES.get(vid, vid))
		label.add_theme_font_size_override("font_size", 12)
		label.custom_minimum_size = Vector2(55, 0)
		row.add_child(label)
		_vital_labels[vid] = label

		var bar: ProgressBar = ProgressBar.new()
		bar.min_value = 0
		bar.max_value = 100
		bar.custom_minimum_size = Vector2(80, 12)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.show_percentage = false
		row.add_child(bar)
		_vital_bars[vid] = bar

		vitals_panel.add_child(row)

func _update_vitals() -> void:
	var vitals: Dictionary = The.session.get("vitals", {})
	for vid: String in _vital_bars:
		(_vital_bars[vid] as ProgressBar).value = int(vitals.get(vid, 0))

# --- Week resolution ---

const SLOT_DELAY: float = 0.5

var _resolving: bool = false

func _on_next_week() -> void:
	if _resolving:
		return
	_resolving = true
	btn_next_week.disabled = true
	btn_clear.disabled = true
	_resolve_week()

func _resolve_week() -> void:
	var vitals: Dictionary = The.session.get("vitals", {}).duplicate()
	var money: int = int(The.session.get("money", 0))

	for day_id: String in DAYS:
		var day_text: String = I18n.text(DAY_LABELS[day_id])
		for slot_id: String in SLOTS:
			var key: String = day_id + "_" + slot_id
			var select: OptionButton = _grid_selects.get(key, null)
			if select == null:
				continue
			var index: int = select.selected
			var acts: Array[Dictionary] = _grid_activities.get(key, [])
			if index < 0 or index >= acts.size():
				continue
			var act: Dictionary = acts[index]
			var act_name: String = I18n.text(act.get("name", "?"))

			var effects: Dictionary = act.get("effects", {})
			for vid: String in effects.keys():
				var current: int = int(vitals.get(vid, 0))
				vitals[vid] = clampi(current + int(effects[vid]), 0, 100)

			var money_delta: int = int(act.get("money", 0))
			money += money_delta

			var money_str: String = ""
			if money_delta > 0:
				money_str = " (+R$" + str(money_delta) + ")"
			elif money_delta < 0:
				money_str = " (-R$" + str(absi(money_delta)) + ")"

			_log(day_text + " " + I18n.text(SLOT_LABELS[slot_id]) + ": " + act_name + money_str)

			# Update vitals progressively
			The.session["vitals"] = vitals
			The.session["money"] = money
			_update_vitals()

			await get_tree().create_timer(SLOT_DELAY).timeout

	# Debuffs
	_effects.clear()
	for vid: String in vitals:
		if int(vitals[vid]) <= 20:
			_effects.append({"name": I18n.text(VITAL_NAMES.get(vid, vid)) + " LOW", "type": "debuff"})

	The.session["vitals"] = vitals
	The.session["money"] = money
	var day: int = int(The.session.get("day", 1)) + 7
	The.session["day"] = day
	@warning_ignore("integer_division")
	The.session["week"] = ((day - 1) / 7) + 1

	_update_header()
	_update_vitals()
	_update_effects()
	_log("--- " + I18n.text(T_WEEK) + " " + str(The.session["week"]) + " ---")

	_resolving = false
	btn_next_week.disabled = false
	btn_clear.disabled = false

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

# --- Log ---

func _log(text: String) -> void:
	log_text.append_text(text + "\n")
