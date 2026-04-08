extends Control

const T_NEXT: Dictionary = {"pt": "PRÓXIMO", "en": "NEXT"}
const T_BEGIN: Dictionary = {"pt": "COMEÇAR", "en": "BEGIN"}
const T_SKIP: Dictionary = {"pt": "PULAR", "en": "SKIP"}

const PAGES: Array[Dictionary] = [
	{"pt": "Você tem 15 anos. Escola, amigos, peladas no parque no fim de semana.\nA vida é simples.", "en": "You're 15. School, friends, weekend pickup games at the park.\nLife is simple enough."},
	{"pt": "Então num sábado você vê — um time de flag football treinando no campo ao lado.\nCortes rápidos, espirais perfeitas, trash talk entre as jogadas. Você não consegue parar de olhar.", "en": "Then one Saturday you see them — a flag football team practicing on the field next door.\nFast cuts, tight spirals, trash talk between plays. You can't look away."},
	{"pt": "Você se aproxima. Alguém te joga uma bola.\n\"Quer correr uma rota?\"\nVocê nem sabe o que é uma rota. Mas aceita mesmo assim.", "en": "You walk over. Someone tosses you a ball.\n\"Wanna run a route?\"\nYou don't even know what a route is. You say yes anyway."},
	{"pt": "Aquela tarde muda tudo.\nVocê não é bom — ainda não — mas algo clica.\nA velocidade, a estratégia, a adrenalina de puxar uma flag no último segundo.", "en": "That afternoon changes everything.\nYou're not great — not yet — but something clicks.\nThe speed, the strategy, the rush of pulling a flag at the last second."},
	{"pt": "Você chega em casa naquela noite e toma uma decisão:\nvocê vai ser um jogador de flag football.\nDe verdade.", "en": "You go home that night and make a decision:\nyou're going to be a flag football player.\nA real one."},
	{"pt": "Não vai ser fácil. Vai ter que conciliar escola, talvez um trampo,\ntreinar pesado, conquistar uma vaga num time e sobreviver temporada após temporada.", "en": "It won't be easy. You'll need to balance school, maybe a job,\ntrain hard, earn a spot on a team, and survive season after season."},
	{"pt": "Mas agora, nada disso importa.\nAgora, você só quer voltar pra aquele campo.", "en": "But right now, none of that matters.\nRight now, you just want to get back on that field."},
]

var _page_index: int = 0

@onready var text_label: RichTextLabel = $Margin/VBox/TextPanel/Text
@onready var btn_next: Button = $Margin/VBox/Buttons/BtnNext
@onready var btn_skip: Button = $Margin/VBox/Buttons/BtnSkip
@onready var page_label: Label = $Margin/VBox/Buttons/PageLabel

func _ready() -> void:
	btn_next.pressed.connect(_on_next)
	btn_skip.pressed.connect(_on_skip)
	btn_skip.text = I18n.text(T_SKIP)
	_show_page()

func _show_page() -> void:
	text_label.text = ""
	text_label.append_text(I18n.text(PAGES[_page_index]))
	page_label.text = str(_page_index + 1) + "/" + str(PAGES.size())
	var is_last: bool = _page_index >= PAGES.size() - 1
	btn_next.text = I18n.text(T_BEGIN) if is_last else I18n.text(T_NEXT)

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
