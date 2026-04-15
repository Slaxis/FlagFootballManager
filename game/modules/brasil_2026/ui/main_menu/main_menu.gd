extends Control

const T_CONTINUE: Dictionary = {"pt": "CONTINUAR", "en": "CONTINUE"}
const T_START: Dictionary = {"pt": "INICIAR", "en": "START"}
const T_OPTIONS: Dictionary = {"pt": "OPÇÕES", "en": "OPTIONS"}
const T_HALL: Dictionary = {"pt": "HALL DA FAMA", "en": "HALL OF FAME"}
const T_QUIT: Dictionary = {"pt": "SAIR", "en": "QUIT"}
const T_NEW_OVERWRITE: Dictionary = {"pt": "Isso vai apagar seu save atual. Continuar?", "en": "This will delete your current save. Continue?"}
const T_YES: Dictionary = {"pt": "Sim", "en": "Yes"}
const T_NO: Dictionary = {"pt": "Nao", "en": "No"}

@onready var btn_continue: Button = $Center/VBox/BtnContinue
@onready var btn_start: Button = $Center/VBox/BtnStart
@onready var btn_options: Button = $Center/VBox/BtnOptions
@onready var btn_hall: Button = $Center/VBox/BtnHall
@onready var btn_quit: Button = $Center/VBox/BtnQuit
@onready var btn_lang: Button = $BtnLang

func _ready() -> void:
	btn_start.pressed.connect(_on_start_pressed)
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_options.pressed.connect(_on_options_pressed)
	btn_hall.pressed.connect(_on_hall_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)
	btn_lang.pressed.connect(_on_lang_toggle)
	_update_text()
	_refresh_continue_state()

func _refresh_continue_state() -> void:
	btn_continue.disabled = not SaveManager.has_save()

func _on_start_pressed() -> void:
	if SaveManager.has_save():
		_confirm_new_game()
	else:
		_go_to_module_select()

func _confirm_new_game() -> void:
	var dialog: ConfirmationDialog = ConfirmationDialog.new()
	dialog.title = I18n.text(T_START)
	dialog.dialog_text = I18n.text(T_NEW_OVERWRITE)
	dialog.ok_button_text = I18n.text(T_YES)
	dialog.cancel_button_text = I18n.text(T_NO)
	dialog.confirmed.connect(func() -> void:
		SaveManager.delete_save()
		_go_to_module_select()
		dialog.queue_free()
	)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()

func _go_to_module_select() -> void:
	# Fresh run: wipe lingering session from prior career so stale grid selections,
	# ato0_complete, tryout counters, etc. don't bleed into the new playthrough.
	The.session.clear()
	var scene: PackedScene = The.ui("module_select")
	if scene:
		The.next_scene(scene)

func _on_continue_pressed() -> void:
	var payload: Dictionary = SaveManager.load_game()
	if payload.is_empty():
		Log.log(self, "error", "MainMenu: continue pressed but no save")
		return
	SaveManager.apply_save(payload)
	# Ato 0 complete = Act 1 not implemented yet, so return to win screen.
	var target: String = "win_ato0" if bool(The.session.get("ato0_complete", false)) else "player_home"
	var scene: PackedScene = The.ui(target)
	if scene:
		The.next_scene(scene)

func _on_options_pressed() -> void:
	var scene: PackedScene = The.ui("options")
	if scene:
		The.next_scene(scene)

func _on_hall_pressed() -> void:
	var scene: PackedScene = The.ui("hall_of_fame")
	if scene:
		The.next_scene(scene)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_lang_toggle() -> void:
	var next_lang: String = "pt" if I18n.lang == "en" else "en"
	I18n.set_lang(next_lang)
	var settings: Dictionary = SaveManager.load_settings()
	settings["lang"] = next_lang
	SaveManager.save_settings(settings)
	_update_text()

func _update_text() -> void:
	btn_lang.text = I18n.lang.to_upper()
	btn_continue.text = I18n.text(T_CONTINUE)
	btn_start.text = I18n.text(T_START)
	btn_options.text = I18n.text(T_OPTIONS)
	btn_hall.text = I18n.text(T_HALL)
	btn_quit.text = I18n.text(T_QUIT)
