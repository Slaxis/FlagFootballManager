extends Control

const T_TITLE: Dictionary = {"pt": "HALL DA FAMA", "en": "HALL OF FAME"}
const T_EMPTY: Dictionary = {"pt": "Nenhuma carreira registrada ainda.", "en": "No careers recorded yet."}
const T_BACK: Dictionary = {"pt": "VOLTAR", "en": "BACK"}
const T_WEEKS: Dictionary = {"pt": "semanas", "en": "weeks"}
const T_FAILED: Dictionary = {"pt": "tryouts falhados", "en": "failed tryouts"}
const T_PASSED: Dictionary = {"pt": "Entrou no time!", "en": "Made the team!"}
const T_RETIRED: Dictionary = {"pt": "Aposentado", "en": "Retired"}

const COLOR_PASSED := Color(0.2, 0.75, 0.2)
const COLOR_RETIRED := Color(0.8, 0.4, 0.4)

@onready var title_label: Label = $Margin/VBox/Title
@onready var entries_container: VBoxContainer = $Margin/VBox/Scroll/Entries
@onready var btn_back: Button = $Margin/VBox/BtnBack

func _ready() -> void:
	title_label.text = I18n.text(T_TITLE)
	btn_back.text = I18n.text(T_BACK)
	btn_back.pressed.connect(_on_back)
	btn_back.pressed.connect(func() -> void: Audio.play_sfx("menu_click"))
	_populate()

func _populate() -> void:
	for child: Node in entries_container.get_children():
		child.queue_free()
	var entries: Array = SaveManager.load_hall_of_fame()
	if entries.is_empty():
		var label: Label = Label.new()
		label.text = I18n.text(T_EMPTY)
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		entries_container.add_child(label)
		return
	# Most recent first
	entries.reverse()
	for raw: Variant in entries:
		if raw is Dictionary:
			entries_container.add_child(_build_entry(raw as Dictionary))

func _build_entry(entry: Dictionary) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.15)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)

	var name_label: Label = Label.new()
	name_label.text = String(entry.get("name", "?"))
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.custom_minimum_size = Vector2(180, 0)
	hbox.add_child(name_label)

	var meta_label: Label = Label.new()
	meta_label.text = str(entry.get("weeks", 0)) + " " + I18n.text(T_WEEKS) + "  |  " + str(entry.get("tryouts_failed", 0)) + " " + I18n.text(T_FAILED)
	meta_label.add_theme_font_size_override("font_size", 12)
	meta_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	meta_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(meta_label)

	var result_label: Label = Label.new()
	var result: String = String(entry.get("result", ""))
	if result == "act0_complete":
		result_label.text = I18n.text(T_PASSED)
		result_label.add_theme_color_override("font_color", COLOR_PASSED)
	else:
		result_label.text = I18n.text(T_RETIRED)
		result_label.add_theme_color_override("font_color", COLOR_RETIRED)
	result_label.add_theme_font_size_override("font_size", 12)
	hbox.add_child(result_label)

	panel.add_child(hbox)
	return panel

func _on_back() -> void:
	var scene: PackedScene = The.ui("main_menu")
	if scene:
		The.next_scene(scene)
