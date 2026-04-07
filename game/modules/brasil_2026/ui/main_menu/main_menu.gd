extends Control

@onready var btn_start: Button = $Center/VBox/BtnStart
@onready var btn_quit: Button = $Center/VBox/BtnQuit

func _ready() -> void:
	btn_start.pressed.connect(_on_start_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	var scene: PackedScene = The.ui("player_creation")
	if scene:
		The.next_scene(scene)

func _on_quit_pressed() -> void:
	get_tree().quit()
