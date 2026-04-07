extends Control

const COLOR_CARD_BG := Color(0.15, 0.15, 0.15)
const COLOR_CARD_SELECTED := Color(0.12, 0.25, 0.12)
const COLOR_DESC := Color(0.6, 0.6, 0.6)
const COLOR_VERSION := Color(0.45, 0.45, 0.45)

var _selected_module_id: String = ""
var _card_panels: Dictionary = {}  # module_id -> PanelContainer

@onready var cards_container: HBoxContainer = $Margin/VBox/Cards
@onready var info_label: Label = $Margin/VBox/InfoLabel
@onready var btn_ok: Button = $Margin/VBox/Buttons/BtnOk
@onready var btn_back: Button = $Margin/VBox/Buttons/BtnBack

func _ready() -> void:
	btn_ok.disabled = true
	btn_ok.pressed.connect(_on_ok)
	btn_back.pressed.connect(_on_back)
	_build_cards()

func _build_cards() -> void:
	var modules: Array[ModuleInfo] = Drive.list_modules()
	if modules.is_empty():
		info_label.text = "No modules found."
		return
	for mod: ModuleInfo in modules:
		_build_card(mod)

func _build_card(mod: ModuleInfo) -> void:
	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = COLOR_CARD_BG
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(260, 0)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	# Read manifest for i18n fields
	var manifest: Dictionary = _read_manifest(mod)

	var title: Label = Label.new()
	title.text = I18n.text(manifest.get("name", mod.name))
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)

	var desc: Label = Label.new()
	desc.text = I18n.text(manifest.get("description", ""))
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", COLOR_DESC)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(220, 0)
	vbox.add_child(desc)

	var version: Label = Label.new()
	version.text = "v" + String(manifest.get("version", "?"))
	version.add_theme_font_size_override("font_size", 11)
	version.add_theme_color_override("font_color", COLOR_VERSION)
	vbox.add_child(version)

	panel.add_child(vbox)

	# Clickable overlay
	var btn: Button = Button.new()
	btn.flat = true
	btn.anchors_preset = Control.PRESET_FULL_RECT
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(_on_card_pressed.bind(mod.id))
	panel.add_child(btn)

	cards_container.add_child(panel)
	_card_panels[mod.id] = panel

func _read_manifest(mod: ModuleInfo) -> Dictionary:
	var path: String = mod.native_path + "/module.json"
	return Drive.read_content(path)

func _on_card_pressed(module_id: String) -> void:
	# Deselect previous
	if _selected_module_id != "" and _card_panels.has(_selected_module_id):
		var old_style: StyleBoxFlat = _card_panels[_selected_module_id].get_theme_stylebox("panel")
		old_style.bg_color = COLOR_CARD_BG
	_selected_module_id = module_id
	# Highlight new
	var style: StyleBoxFlat = _card_panels[module_id].get_theme_stylebox("panel")
	style.bg_color = COLOR_CARD_SELECTED
	btn_ok.disabled = false
	info_label.text = ""

func _on_ok() -> void:
	if _selected_module_id == "":
		return
	if not Drive.set_module(_selected_module_id):
		Log.log(self, "error", "ModuleSelect: failed to activate module: " + _selected_module_id)
		return
	The.session["module_id"] = _selected_module_id
	The.load_rules()
	Log.log(self, "info", "Module selected: " + _selected_module_id)
	var scene: PackedScene = The.ui("player_creation")
	if scene:
		The.next_scene(scene)

func _on_back() -> void:
	var scene: PackedScene = The.ui("main_menu")
	if scene:
		The.next_scene(scene)
