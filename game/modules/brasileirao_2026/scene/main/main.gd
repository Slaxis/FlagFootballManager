# Main menu — entry screen of the Brasil module. The Flow routes the
# "play" transition into `club_select` and "quit" into $exit.
extends Menu

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.10, 0.08)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)

	var title := Label.new()
	title.text = "FLAG FOOTBALL MANAGER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "— Brasil —"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", Color(0.58, 0.70, 0.60))
	box.add_child(subtitle)

	box.add_child(_spacer(28))

	var new_game := _menu_button("Novo Jogo")
	new_game.pressed.connect(func() -> void: go("play"))
	box.add_child(new_game)

	var quit := _menu_button("Sair")
	quit.pressed.connect(func() -> void: go("quit"))
	box.add_child(quit)

	new_game.grab_focus()

func _menu_button(label: String) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(260, 46)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return b

func _spacer(height: int) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, height)
	return s
