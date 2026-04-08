extends Control

const PAGES: Array[String] = [
	"You're 15. School, friends, weekend pickup games at the park.\nLife is simple enough.",
	"Then one Saturday you see them — a flag football team practicing on the field next door.\nFast cuts, tight spirals, trash talk between plays. You can't look away.",
	"You walk over. Someone tosses you a ball.\n\"Wanna run a route?\"\nYou don't even know what a route is. You say yes anyway.",
	"That afternoon changes everything.\nYou're not great — not yet — but something clicks.\nThe speed, the strategy, the rush of pulling a flag at the last second.",
	"You go home that night and make a decision:\nyou're going to be a flag football player.\nA real one.",
	"It won't be easy. You'll need to balance school, maybe a job,\ntrain hard, earn a spot on a team, and survive season after season.",
	"But right now, none of that matters.\nRight now, you just want to get back on that field.",
]

var _page_index: int = 0

@onready var text_label: RichTextLabel = $Margin/VBox/TextPanel/Text
@onready var btn_next: Button = $Margin/VBox/Buttons/BtnNext
@onready var btn_skip: Button = $Margin/VBox/Buttons/BtnSkip
@onready var page_label: Label = $Margin/VBox/Buttons/PageLabel

func _ready() -> void:
	btn_next.pressed.connect(_on_next)
	btn_skip.pressed.connect(_on_skip)
	_show_page()

func _show_page() -> void:
	text_label.text = ""
	text_label.append_text(PAGES[_page_index])
	page_label.text = str(_page_index + 1) + "/" + str(PAGES.size())
	btn_next.text = "NEXT" if _page_index < PAGES.size() - 1 else "BEGIN"

func _on_next() -> void:
	_page_index += 1
	if _page_index >= PAGES.size():
		_go_home()
		return
	_show_page()

func _on_skip() -> void:
	_go_home()

func _go_home() -> void:
	var scene: PackedScene = The.ui("player_home")
	if scene:
		The.next_scene(scene)
