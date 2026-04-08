extends Control

const T_CONTINUE: Dictionary = {"pt": "CONTINUAR", "en": "CONTINUE"}
const T_START: Dictionary = {"pt": "INICIAR", "en": "START"}
const T_OPTIONS: Dictionary = {"pt": "OPÇÕES", "en": "OPTIONS"}
const T_QUIT: Dictionary = {"pt": "SAIR", "en": "QUIT"}

@onready var btn_continue: Button = $Center/VBox/BtnContinue
@onready var btn_start: Button = $Center/VBox/BtnStart
@onready var btn_options: Button = $Center/VBox/BtnOptions
@onready var btn_quit: Button = $Center/VBox/BtnQuit
@onready var btn_lang: Button = $BtnLang

func _ready() -> void:
	btn_start.pressed.connect(_on_start_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)
	btn_lang.pressed.connect(_on_lang_toggle)
	_update_text()

func _on_start_pressed() -> void:
	var scene: PackedScene = The.ui("module_select")
	if scene:
		The.next_scene(scene)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_lang_toggle() -> void:
	var next_lang: String = "pt" if I18n.lang == "en" else "en"
	I18n.set_lang(next_lang)
	_update_text()

func _update_text() -> void:
	btn_lang.text = I18n.lang.to_upper()
	btn_continue.text = I18n.text(T_CONTINUE)
	btn_start.text = I18n.text(T_START)
	btn_options.text = I18n.text(T_OPTIONS)
	btn_quit.text = I18n.text(T_QUIT)
