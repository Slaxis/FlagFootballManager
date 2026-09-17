# Settings — language for now, and nothing else.
#
# Volume is deliberately absent: no audio plays yet, so a slider would move
# without proving anything. It arrives when there is something to hear.
#
# Language is not filler either — flipping it rebuilds this screen in place,
# which is the only way to see that the whole UI catalogue is actually wired
# through I18n rather than hardcoded Portuguese.
extends Menu

const _LANGUAGES: Array = [
	["pt", "Português"],
	["en", "English"],
]

var _root: VBoxContainer = null

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Look.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 48)
	add_child(margin)

	_root = VBoxContainer.new()
	_root.add_theme_constant_override("separation", 14)
	margin.add_child(_root)
	_build_ui()

func _build_ui() -> void:
	for child: Node in _root.get_children():
		child.queue_free()

	var title := Label.new()
	title.text = UiText.t("settings.title")
	title.add_theme_font_size_override("font_size", 34)
	_root.add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_root.add_child(row)

	var label := Label.new()
	label.text = UiText.t("settings.language")
	label.custom_minimum_size = Vector2(140, 0)
	row.add_child(label)

	var active: String = I18n.get_lang()
	for entry: Array in _LANGUAGES:
		var code: String = String(entry[0])
		var button := Button.new()
		button.text = String(entry[1])
		button.custom_minimum_size = Vector2(150, 40)
		button.disabled = code == active
		button.pressed.connect(_on_language.bind(code))
		row.add_child(button)

	var back := Button.new()
	back.text = UiText.t("common.back")
	back.custom_minimum_size = Vector2(160, 40)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(func() -> void: go("back"))
	_root.add_child(back)

func _on_language(code: String) -> void:
	I18n.set_lang(code)
	# Rebuild in place so the change is visible immediately, on this screen,
	# instead of only showing up after navigating away and back.
	_build_ui()
