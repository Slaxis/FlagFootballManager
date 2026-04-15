extends Control

const T_TITLE: Dictionary = {"pt": "GAME OVER", "en": "GAME OVER"}
const T_SUB: Dictionary = {"pt": "Sua carreira no flag terminou antes de comecar.", "en": "Your flag football career ended before it started."}
const T_NAME: Dictionary = {"pt": "Nome:", "en": "Name:"}
const T_AGE: Dictionary = {"pt": "Idade:", "en": "Age:"}
const T_WEEKS: Dictionary = {"pt": "Semanas vividas:", "en": "Weeks played:"}
const T_TRYOUTS: Dictionary = {"pt": "Tryouts falhados:", "en": "Failed tryouts:"}
const T_NEW: Dictionary = {"pt": "NOVO JOGO", "en": "NEW GAME"}
const T_MENU: Dictionary = {"pt": "MENU PRINCIPAL", "en": "MAIN MENU"}
const T_SAVED: Dictionary = {"pt": "Carreira salva no Hall da Fama.", "en": "Career saved to Hall of Fame."}

@onready var title_label: Label = $Margin/VBox/Title
@onready var sub_label: Label = $Margin/VBox/Subtitle
@onready var info_label: RichTextLabel = $Margin/VBox/InfoPanel/Info
@onready var saved_label: Label = $Margin/VBox/SavedLabel
@onready var btn_new: Button = $Margin/VBox/Buttons/BtnNew
@onready var btn_menu: Button = $Margin/VBox/Buttons/BtnMenu

func _ready() -> void:
	_save_to_hall_of_fame()
	_populate()
	btn_new.pressed.connect(_on_new)
	btn_menu.pressed.connect(_on_menu)

func _save_to_hall_of_fame() -> void:
	var entry: Dictionary = {
		"name": String(The.session.get("player_name", "?")),
		"age": int(The.session.get("player_age", 15)),
		"gender": String(The.session.get("player_gender", "?")),
		"personality": String(The.session.get("personality", "?")),
		"weeks": int(The.session.get("week", 1)),
		"tryouts_failed": int(The.session.get("tryout_failed_count", 0)),
		"result": "game_over",
		"timestamp": Time.get_datetime_string_from_system(),
	}
	SaveManager.add_hall_entry(entry)
	SaveManager.delete_save()

func _populate() -> void:
	title_label.text = I18n.text(T_TITLE)
	sub_label.text = I18n.text(T_SUB)
	saved_label.text = I18n.text(T_SAVED)
	btn_new.text = I18n.text(T_NEW)
	btn_menu.text = I18n.text(T_MENU)

	var lines: Array[String] = []
	lines.append("[b]" + String(The.session.get("player_name", "?")) + "[/b]")
	lines.append(I18n.text(T_AGE) + " " + str(The.session.get("player_age", 15)))
	lines.append(I18n.text(T_WEEKS) + " " + str(The.session.get("week", 1)))
	lines.append(I18n.text(T_TRYOUTS) + " " + str(The.session.get("tryout_failed_count", 0)))
	info_label.text = "\n".join(lines)

func _on_new() -> void:
	The.session.clear()
	var scene: PackedScene = The.ui("module_select")
	if scene:
		The.next_scene(scene)

func _on_menu() -> void:
	var scene: PackedScene = The.ui("main_menu")
	if scene:
		The.next_scene(scene)
