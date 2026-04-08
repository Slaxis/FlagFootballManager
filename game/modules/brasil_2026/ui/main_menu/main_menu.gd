extends Control

@onready var btn_start: Button = $Center/VBox/BtnStart
@onready var btn_quit: Button = $Center/VBox/BtnQuit
@onready var btn_lang: Button = $BtnLang

func _ready() -> void:
	btn_start.pressed.connect(_on_start_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)
	btn_lang.pressed.connect(_on_lang_toggle)
	btn_lang.text = I18n.lang.to_upper()

func _on_start_pressed() -> void:
	var scene: PackedScene = The.ui("module_select")
	if scene:
		The.next_scene(scene)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_lang_toggle() -> void:
	var next_lang: String = "pt" if I18n.lang == "en" else "en"
	I18n.set_lang(next_lang)
	btn_lang.text = I18n.lang.to_upper()
