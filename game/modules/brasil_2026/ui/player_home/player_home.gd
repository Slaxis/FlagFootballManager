extends Control

const SLOTS: Array[String] = ["morning", "afternoon", "night"]
const SLOT_LABELS: Dictionary = {
	"morning":   {"pt": "MANHÃ",  "en": "MORNING"},
	"afternoon": {"pt": "TARDE",  "en": "AFTERNOON"},
	"night":     {"pt": "NOITE",  "en": "NIGHT"},
}
const DAY_NAMES_I18N: Dictionary = {
	"pt": ["Seg", "Ter", "Qua", "Qui", "Sex", "Sáb", "Dom"],
	"en": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
}
const T_PLAN: Dictionary = {"pt": "PLANEJE SEU DIA", "en": "PLAN YOUR DAY"}
const T_NEXT: Dictionary = {"pt": "PRÓXIMO DIA", "en": "NEXT DAY"}
const T_ROOM: Dictionary = {"pt": "SEU QUARTO", "en": "YOUR ROOM"}
const T_LOG: Dictionary = {"pt": "LOG", "en": "LOG"}
const T_VITALS: Dictionary = {"pt": "SINAIS VITAIS", "en": "VITALS"}
const T_WEEK: Dictionary = {"pt": "Semana", "en": "Week"}
const T_DAY: Dictionary = {"pt": "Dia", "en": "Day"}
const T_WELCOME: Dictionary = {"pt": "Bem-vindo! Planeje seu dia.", "en": "Welcome home. Plan your day."}
const T_PHONE: Dictionary = {"pt": "Celular", "en": "Phone"}
const T_TV: Dictionary = {"pt": "TV", "en": "TV"}
const T_FRIDGE: Dictionary = {"pt": "Geladeira", "en": "Fridge"}
const T_WARDROBE: Dictionary = {"pt": "Armário", "en": "Wardrobe"}
const T_NOT_IMPL: Dictionary = {"pt": " — ainda não implementado", "en": " — not yet implemented"}
const T_EXHAUSTED: Dictionary = {"pt": "Exausto demais para treinar. Dormiu.", "en": "Too exhausted to train. Slept instead."}

const VITAL_NAMES: Dictionary = {
	"energy":  {"pt": "Energia", "en": "Energy"},
	"hunger":  {"pt": "Fome",    "en": "Hunger"},
	"social":  {"pt": "Social",  "en": "Social"},
	"leisure": {"pt": "Lazer",   "en": "Leisure"},
}

const COLOR_VITAL_OK := Color(0.3, 0.8, 0.3)
const COLOR_VITAL_WARN := Color(0.9, 0.7, 0.2)
const COLOR_VITAL_LOW := Color(0.8, 0.2, 0.2)
const COLOR_BUFF := Color(0.3, 0.7, 0.9)
const COLOR_DEBUFF := Color(0.8, 0.3, 0.3)

var _activity_def: Def  # ActivityDef
var _slot_selects: Dictionary = {}
var _slot_activities: Dictionary = {}
var _vital_bars: Dictionary = {}
var _vital_labels: Dictionary = {}
var _slot_labels: Dictionary = {}  # slot -> Label
var _effects: Array[Dictionary] = []

@onready var money_label: Label = $Margin/VBox/TopBar/MoneyLabel
@onready var day_label: Label = $Margin/VBox/TopBar/DayLabel
@onready var week_label: Label = $Margin/VBox/TopBar/WeekLabel
@onready var player_label: Label = $Margin/VBox/TopBar/PlayerLabel
@onready var btn_lang: Button = $Margin/VBox/TopBar/BtnLang

@onready var plan_header: Label = $Margin/VBox/Content/LeftPanel/PlanHeader
@onready var slots_panel: VBoxContainer = $Margin/VBox/Content/LeftPanel/Slots
@onready var btn_next: Button = $Margin/VBox/Content/LeftPanel/BtnNextDay

@onready var room_header: Label = $Margin/VBox/Content/CenterPanel/RoomHeader
@onready var room_panel: VBoxContainer = $Margin/VBox/Content/CenterPanel/Room
@onready var log_header: Label = $Margin/VBox/Content/CenterPanel/LogHeader
@onready var log_text: RichTextLabel = $Margin/VBox/Content/CenterPanel/LogText

@onready var vitals_header: Label = $Margin/VBox/Content/RightPanel/VitalsHeader
@onready var vitals_panel: VBoxContainer = $Margin/VBox/Content/RightPanel/Vitals
@onready var effects_bar: HBoxContainer = $Margin/VBox/EffectsBar

func _ready() -> void:
	_activity_def = Drive.def("activity")
	if _activity_def == null:
		Log.log(self, "error", "PlayerHome: missing activity Def.")
		return
	_build_slots()
	_build_room()
	_build_vitals()
	_update_all_text()
	_update_header()
	_update_vitals()
	btn_next.pressed.connect(_on_next_day)
	btn_lang.pressed.connect(_on_lang_toggle)
	_log(I18n.text(T_WELCOME))

# --- Language toggle ---

func _on_lang_toggle() -> void:
	var next_lang: String = "pt" if I18n.lang == "en" else "en"
	I18n.set_lang(next_lang)
	_update_all_text()

func _update_all_text() -> void:
	btn_lang.text = I18n.lang.to_upper()
	plan_header.text = I18n.text(T_PLAN)
	btn_next.text = I18n.text(T_NEXT)
	room_header.text = I18n.text(T_ROOM)
	log_header.text = I18n.text(T_LOG)
	vitals_header.text = I18n.text(T_VITALS)
	# Update slot labels
	for slot: String in _slot_labels:
		_slot_labels[slot].text = I18n.text(SLOT_LABELS[slot])
	# Update slot dropdowns
	for slot: String in _slot_selects:
		var select: OptionButton = _slot_selects[slot]
		var acts: Array[Dictionary] = _slot_activities.get(slot, [])
		for i: int in acts.size():
			select.set_item_text(i, I18n.text(acts[i].get("name", acts[i].get("id", "?"))))
	# Update vital labels
	for vid: String in _vital_labels:
		_vital_labels[vid].text = I18n.text(VITAL_NAMES.get(vid, vid))
	# Update room buttons
	_rebuild_room()
	_update_header()

# --- Header ---

func _update_header() -> void:
	var money: int = int(The.session.get("money", 0))
	var week: int = int(The.session.get("week", 1))
	var day: int = int(The.session.get("day", 1))
	var day_names: Array = DAY_NAMES_I18N.get(I18n.lang, DAY_NAMES_I18N["en"])
	var day_name: String = day_names[(day - 1) % 7]
	var player_name: String = String(The.session.get("player_name", ""))

	money_label.text = "R$ " + str(money)
	day_label.text = day_name + ", " + I18n.text(T_DAY) + " " + str(day)
	week_label.text = I18n.text(T_WEEK) + " " + str(week)
	player_label.text = player_name

# --- Slots ---

func _build_slots() -> void:
	for slot: String in SLOTS:
		var row: VBoxContainer = VBoxContainer.new()
		row.add_theme_constant_override("separation", 2)

		var label: Label = Label.new()
		label.text = I18n.text(SLOT_LABELS[slot])
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		row.add_child(label)
		_slot_labels[slot] = label

		var select: OptionButton = OptionButton.new()
		select.custom_minimum_size = Vector2(200, 32)
		var available: Array[Dictionary] = _activity_def.list_for_slot(slot)
		_slot_activities[slot] = available
		for act: Dictionary in available:
			select.add_item(I18n.text(act.get("name", act.get("id", "?"))))
		select.tooltip_text = _get_activity_desc(slot, 0)
		select.item_selected.connect(_on_slot_changed.bind(slot))
		row.add_child(select)
		_slot_selects[slot] = select

		slots_panel.add_child(row)

func _get_activity_desc(slot: String, index: int) -> String:
	var acts: Array[Dictionary] = _slot_activities.get(slot, [])
	if index >= 0 and index < acts.size():
		return I18n.text(acts[index].get("desc", ""))
	return ""

func _on_slot_changed(index: int, slot: String) -> void:
	var select: OptionButton = _slot_selects[slot]
	select.tooltip_text = _get_activity_desc(slot, index)

# --- Room ---

func _build_room() -> void:
	_rebuild_room()

func _rebuild_room() -> void:
	for child: Node in room_panel.get_children():
		child.queue_free()
	var items: Array[Dictionary] = [
		{"label": T_PHONE,    "id": "phone"},
		{"label": T_TV,       "id": "tv"},
		{"label": T_FRIDGE,   "id": "fridge"},
		{"label": T_WARDROBE, "id": "wardrobe"},
	]
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 16)
	for item: Dictionary in items:
		var btn: Button = Button.new()
		btn.text = I18n.text(item["label"])
		btn.custom_minimum_size = Vector2(110, 50)
		btn.pressed.connect(_on_room_item.bind(item["id"]))
		hbox.add_child(btn)
	room_panel.add_child(hbox)

func _on_room_item(item_id: String) -> void:
	_log("[" + item_id.capitalize() + I18n.text(T_NOT_IMPL) + "]")

# --- Vitals ---

func _build_vitals() -> void:
	var vital_ids: Array[String] = ["energy", "hunger", "social", "leisure"]
	for vid: String in vital_ids:
		var row: VBoxContainer = VBoxContainer.new()
		row.add_theme_constant_override("separation", 1)

		var label: Label = Label.new()
		label.text = I18n.text(VITAL_NAMES.get(vid, vid))
		label.add_theme_font_size_override("font_size", 12)
		row.add_child(label)
		_vital_labels[vid] = label

		var bar: ProgressBar = ProgressBar.new()
		bar.min_value = 0
		bar.max_value = 100
		bar.custom_minimum_size = Vector2(0, 14)
		bar.show_percentage = false
		row.add_child(bar)
		_vital_bars[vid] = bar

		vitals_panel.add_child(row)

func _update_vitals() -> void:
	var vitals: Dictionary = The.session.get("vitals", {})
	for vid: String in _vital_bars:
		var bar: ProgressBar = _vital_bars[vid]
		var val: int = int(vitals.get(vid, 0))
		bar.value = val

# --- Day progression ---

func _on_next_day() -> void:
	var vitals: Dictionary = The.session.get("vitals", {}).duplicate()
	var money: int = int(The.session.get("money", 0))

	for slot: String in SLOTS:
		var select: OptionButton = _slot_selects[slot]
		var index: int = select.selected
		var acts: Array[Dictionary] = _slot_activities.get(slot, [])
		if index < 0 or index >= acts.size():
			continue
		var act: Dictionary = acts[index]
		var act_name: String = I18n.text(act.get("name", "?"))

		var effects: Dictionary = act.get("effects", {})
		for key: String in effects.keys():
			var current: int = int(vitals.get(key, 0))
			vitals[key] = clampi(current + int(effects[key]), 0, 100)

		var money_delta: int = int(act.get("money", 0))
		money += money_delta

		var money_str: String = ""
		if money_delta > 0:
			money_str = " (+R$" + str(money_delta) + ")"
		elif money_delta < 0:
			money_str = " (-R$" + str(absi(money_delta)) + ")"

		_log(I18n.text(SLOT_LABELS[slot]) + ": " + act_name + money_str)

	_effects.clear()
	for vid: String in vitals:
		var val: int = int(vitals[vid])
		if val <= 20:
			_effects.append({"name": I18n.text(VITAL_NAMES.get(vid, vid)) + " LOW", "type": "debuff"})

	The.session["vitals"] = vitals
	The.session["money"] = money
	var day: int = int(The.session.get("day", 1)) + 1
	The.session["day"] = day
	@warning_ignore("integer_division")
	The.session["week"] = ((day - 1) / 7) + 1

	_update_header()
	_update_vitals()
	_update_effects()
	_log("--- " + I18n.text(T_DAY) + " " + str(day) + " ---")

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

func _log(text: String) -> void:
	log_text.append_text(text + "\n")
