extends Control

const T_TITLE: Dictionary = {"pt": "VOCE ENTROU NO TIME!", "en": "YOU MADE THE TEAM!"}
const T_ACT: Dictionary = {"pt": "ATO 0 — CONCLUIDO", "en": "ACT 0 — COMPLETE"}
const T_WELCOME: Dictionary = {"pt": "Bem-vindo ao [b]{team}[/b]. Seu primeiro passo numa longa jornada.\n\nA 4a divisao e so o comeco. Varias temporadas, ligas e selecoes te esperam.", "en": "Welcome to [b]{team}[/b]. Your first step on a long journey.\n\n4th division is just the beginning. Many seasons, leagues, and national teams await."}
const T_STATS: Dictionary = {"pt": "Resultado do Tryout", "en": "Tryout Result"}
const T_SOON: Dictionary = {"pt": "O Ato 1 chegara em breve. Por enquanto, seu progresso foi salvo.", "en": "Act 1 coming soon. Your progress has been saved."}
const T_CONTINUE: Dictionary = {"pt": "CONTINUAR", "en": "CONTINUE"}

@onready var title_label: Label = $Margin/VBox/Title
@onready var act_label: Label = $Margin/VBox/Act
@onready var welcome_label: RichTextLabel = $Margin/VBox/InfoPanel/Welcome
@onready var stats_label: RichTextLabel = $Margin/VBox/StatsPanel/Stats
@onready var soon_label: Label = $Margin/VBox/SoonLabel
@onready var btn_continue: Button = $Margin/VBox/BtnContinue

func _ready() -> void:
	_save_to_hall_of_fame()
	_populate()
	btn_continue.pressed.connect(_on_continue)
	btn_continue.pressed.connect(func() -> void: Audio.play_sfx("menu_click"))
	Audio.play_music("victory")

func _save_to_hall_of_fame() -> void:
	var entry: Dictionary = {
		"name": String(The.session.get("player_name", "?")),
		"age": int(The.session.get("player_age", 15)),
		"gender": String(The.session.get("player_gender", "?")),
		"personality": String(The.session.get("personality", "?")),
		"weeks": int(The.session.get("week", 1)),
		"tryouts_failed": int(The.session.get("tryout_failed_count", 0)),
		"team_joined": String(The.session.get("team_id", "?")),
		"result": "act0_complete",
		"timestamp": Time.get_datetime_string_from_system(),
	}
	SaveManager.add_hall_entry(entry)
	# Keep save intact so player can return (for future act 1)
	SaveManager.save_game()

func _populate() -> void:
	title_label.text = I18n.text(T_TITLE)
	act_label.text = I18n.text(T_ACT)
	soon_label.text = I18n.text(T_SOON)
	btn_continue.text = I18n.text(T_CONTINUE)

	var team_id: String = String(The.session.get("team_id", ""))
	var team_data: Dictionary = God.thing_data(team_id)
	var team_name: String = I18n.text(team_data.get("name", team_id))
	welcome_label.text = I18n.format(I18n.text(T_WELCOME), {"team": team_name})

	var last: Dictionary = The.session.get("last_tryout_result", {})
	var lines: Array[String] = []
	lines.append("[b]" + I18n.text(T_STATS) + "[/b]")
	lines.append(str(last.get("total_score", 0)) + " / " + str(last.get("total_possible", 0)))
	stats_label.text = "\n".join(lines)

func _on_continue() -> void:
	var scene: PackedScene = The.ui("main_menu")
	if scene:
		The.next_scene(scene)
