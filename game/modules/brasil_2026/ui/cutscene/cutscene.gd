extends Control

const T_NEXT: Dictionary = {"pt": "PRÓXIMO", "en": "NEXT"}
const T_BEGIN: Dictionary = {"pt": "COMEÇAR", "en": "BEGIN"}
const T_SKIP: Dictionary = {"pt": "PULAR", "en": "SKIP"}
const T_NO_CUTSCENE: Dictionary = {"pt": "Nenhuma cutscene encontrada.", "en": "No cutscene found."}

var _pages: Array[Dictionary] = []
var _page_index: int = 0

@onready var text_label: RichTextLabel = $Margin/VBox/TextPanel/Text
@onready var btn_next: Button = $Margin/VBox/Buttons/BtnNext
@onready var btn_skip: Button = $Margin/VBox/Buttons/BtnSkip
@onready var page_label: Label = $Margin/VBox/Buttons/PageLabel

func _ready() -> void:
	btn_next.pressed.connect(_on_next)
	btn_skip.pressed.connect(_on_skip)
	btn_skip.text = I18n.text(T_SKIP)
	_load_pages()
	if _pages.is_empty():
		Log.log(self, "info", "Cutscene: no pages, skipping to home.")
		_go_home()
		return
	_show_page()

func _load_pages() -> void:
	var cutscene_jsons: Array[Dictionary] = Drive.list_json_by_group("cutscene")
	if cutscene_jsons.is_empty():
		return
	# Use first cutscene found (modules can override)
	var raw: Dictionary = cutscene_jsons[0]
	var raw_pages: Variant = raw.get("pages", [])
	if not raw_pages is Array:
		return
	var all: Array[Dictionary] = []
	for entry: Variant in (raw_pages as Array):
		if entry is Dictionary:
			all.append(entry as Dictionary)
	all.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("order", 0)) < int(b.get("order", 0))
	)
	_pages = all

func _show_page() -> void:
	var page: Dictionary = _pages[_page_index]
	text_label.text = ""
	text_label.append_text(I18n.text(page.get("text", "")))
	page_label.text = str(_page_index + 1) + "/" + str(_pages.size())
	var is_last: bool = _page_index >= _pages.size() - 1
	btn_next.text = I18n.text(T_BEGIN) if is_last else I18n.text(T_NEXT)

func _on_next() -> void:
	_page_index += 1
	if _page_index >= _pages.size():
		_go_home()
		return
	_show_page()

func _on_skip() -> void:
	_go_home()

func _go_home() -> void:
	var scene: PackedScene = The.ui("player_home")
	if scene:
		The.next_scene(scene)
