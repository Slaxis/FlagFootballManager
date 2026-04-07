extends Control

const SLOTS: Array[String] = ["morning", "afternoon", "night"]
const SLOT_LABELS: Dictionary = {"morning": "MORNING", "afternoon": "AFTERNOON", "night": "NIGHT"}
const DAY_NAMES: Array[String] = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

const COLOR_VITAL_OK := Color(0.3, 0.8, 0.3)
const COLOR_VITAL_WARN := Color(0.9, 0.7, 0.2)
const COLOR_VITAL_LOW := Color(0.8, 0.2, 0.2)
const COLOR_BUFF := Color(0.3, 0.7, 0.9)
const COLOR_DEBUFF := Color(0.8, 0.3, 0.3)

var _activity_def: Def  # ActivityDef
var _slot_selects: Dictionary = {}  # slot_name -> OptionButton
var _slot_activities: Dictionary = {}  # slot_name -> Array[Dictionary]
var _vital_bars: Dictionary = {}  # vital_id -> ProgressBar
var _effects: Array[Dictionary] = []  # active buffs/debuffs

@onready var money_label: Label = $Margin/VBox/TopBar/MoneyLabel
@onready var day_label: Label = $Margin/VBox/TopBar/DayLabel
@onready var week_label: Label = $Margin/VBox/TopBar/WeekLabel
@onready var player_label: Label = $Margin/VBox/TopBar/PlayerLabel

@onready var slots_panel: VBoxContainer = $Margin/VBox/Content/LeftPanel/Slots
@onready var room_panel: VBoxContainer = $Margin/VBox/Content/CenterPanel/Room
@onready var log_text: RichTextLabel = $Margin/VBox/Content/CenterPanel/LogText
@onready var vitals_panel: VBoxContainer = $Margin/VBox/Content/RightPanel/Vitals
@onready var effects_bar: HBoxContainer = $Margin/VBox/EffectsBar

@onready var btn_next: Button = $Margin/VBox/Content/LeftPanel/BtnNextDay

func _ready() -> void:
	_activity_def = Drive.def("activity")
	if _activity_def == null:
		Log.log(self, "error", "PlayerHome: missing activity Def.")
		return
	_build_slots()
	_build_room()
	_build_vitals()
	_update_header()
	_update_vitals()
	btn_next.pressed.connect(_on_next_day)
	_log("Welcome home. Plan your day.")

# --- Header ---

func _update_header() -> void:
	var money: int = int(The.session.get("money", 0))
	var week: int = int(The.session.get("week", 1))
	var day: int = int(The.session.get("day", 1))
	var day_name: String = DAY_NAMES[(day - 1) % 7]
	var player_name: String = String(The.session.get("player_name", ""))

	money_label.text = "R$ " + str(money)
	day_label.text = day_name + ", Day " + str(day)
	week_label.text = "Week " + str(week)
	player_label.text = player_name

# --- Slots (left panel) ---

func _build_slots() -> void:
	for slot: String in SLOTS:
		var row: VBoxContainer = VBoxContainer.new()
		row.add_theme_constant_override("separation", 2)

		var label: Label = Label.new()
		label.text = SLOT_LABELS[slot]
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		row.add_child(label)

		var select: OptionButton = OptionButton.new()
		select.custom_minimum_size = Vector2(200, 32)
		var available: Array[Dictionary] = _activity_def.list_for_slot(slot)
		_slot_activities[slot] = available
		for act: Dictionary in available:
			select.add_item(String(act.get("name", act.get("id", "?"))))
		select.tooltip_text = _get_activity_desc(slot, 0)
		select.item_selected.connect(_on_slot_changed.bind(slot))
		row.add_child(select)
		_slot_selects[slot] = select

		slots_panel.add_child(row)

func _get_activity_desc(slot: String, index: int) -> String:
	var acts: Array[Dictionary] = _slot_activities.get(slot, [])
	if index >= 0 and index < acts.size():
		return String(acts[index].get("desc", ""))
	return ""

func _on_slot_changed(index: int, slot: String) -> void:
	var select: OptionButton = _slot_selects[slot]
	select.tooltip_text = _get_activity_desc(slot, index)

# --- Room (center panel) ---

func _build_room() -> void:
	var items: Array[Dictionary] = [
		{"label": "Phone", "icon": "[phone]"},
		{"label": "TV", "icon": "[tv]"},
		{"label": "Fridge", "icon": "[fridge]"},
		{"label": "Wardrobe", "icon": "[wardrobe]"},
	]
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 16)
	for item: Dictionary in items:
		var btn: Button = Button.new()
		btn.text = item["icon"] + " " + item["label"]
		btn.custom_minimum_size = Vector2(110, 50)
		btn.pressed.connect(_on_room_item.bind(item["label"].to_lower()))
		hbox.add_child(btn)
	room_panel.add_child(hbox)

func _on_room_item(item_id: String) -> void:
	_log("[" + item_id.capitalize() + " — not yet implemented]")

# --- Vitals (right panel) ---

func _build_vitals() -> void:
	var vital_defs: Array[Dictionary] = [
		{"id": "energy",  "name": "Energy",  "max": 100},
		{"id": "hunger",  "name": "Hunger",  "max": 100},
		{"id": "social",  "name": "Social",  "max": 100},
		{"id": "leisure", "name": "Leisure", "max": 100},
	]
	for v: Dictionary in vital_defs:
		var row: VBoxContainer = VBoxContainer.new()
		row.add_theme_constant_override("separation", 1)

		var label: Label = Label.new()
		label.text = v["name"]
		label.add_theme_font_size_override("font_size", 12)
		row.add_child(label)

		var bar: ProgressBar = ProgressBar.new()
		bar.min_value = 0
		bar.max_value = v["max"]
		bar.custom_minimum_size = Vector2(0, 14)
		bar.show_percentage = false
		row.add_child(bar)
		_vital_bars[v["id"]] = bar

		vitals_panel.add_child(row)

func _update_vitals() -> void:
	var vitals: Dictionary = The.session.get("vitals", {})
	for vid: String in _vital_bars:
		var bar: ProgressBar = _vital_bars[vid]
		var val: int = int(vitals.get(vid, 0))
		bar.value = val

func _get_vital_color(value: int) -> Color:
	if value <= 20:
		return COLOR_VITAL_LOW
	if value <= 40:
		return COLOR_VITAL_WARN
	return COLOR_VITAL_OK

# --- Day progression ---

func _on_next_day() -> void:
	var vitals: Dictionary = The.session.get("vitals", {}).duplicate()
	var money: int = int(The.session.get("money", 0))

	# Resolve each slot
	for slot: String in SLOTS:
		var select: OptionButton = _slot_selects[slot]
		var index: int = select.selected
		var acts: Array[Dictionary] = _slot_activities.get(slot, [])
		if index < 0 or index >= acts.size():
			continue
		var act: Dictionary = acts[index]
		var act_name: String = String(act.get("name", "?"))

		# Apply effects
		var effects: Dictionary = act.get("effects", {})
		for key: String in effects.keys():
			var current: int = int(vitals.get(key, 0))
			vitals[key] = clampi(current + int(effects[key]), 0, 100)

		# Apply money
		var money_delta: int = int(act.get("money", 0))
		money += money_delta

		var money_str: String = ""
		if money_delta > 0:
			money_str = " (+R$" + str(money_delta) + ")"
		elif money_delta < 0:
			money_str = " (-R$" + str(absi(money_delta)) + ")"

		_log(SLOT_LABELS[slot] + ": " + act_name + money_str)

	# Check for low vitals → debuffs
	_effects.clear()
	for vid: String in vitals:
		var val: int = int(vitals[vid])
		if val <= 20:
			_effects.append({"name": vid.capitalize() + " LOW", "type": "debuff"})

	# Save state
	The.session["vitals"] = vitals
	The.session["money"] = money
	var day: int = int(The.session.get("day", 1)) + 1
	The.session["day"] = day
	@warning_ignore("integer_division")
	The.session["week"] = ((day - 1) / 7) + 1

	_update_header()
	_update_vitals()
	_update_effects()
	_log("--- Day " + str(day) + " ---")

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
