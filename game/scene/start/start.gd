# Start Screen — the first thing the game shows, before any module is picked.
#
# Lives in `game/scene/` and not inside a module on purpose: D5Star resolves a
# Flow's `scene_file` against the active module first and then falls back to
# the game-level shell (PathManager.scene_path, rule R5). Chrome belongs in
# the shell, so a user-made universe never has to ship its own start screen.
extends Menu

# Continue needs a save, and saving is E.1. The button exists and is greyed
# with a reason rather than being hidden — hiding it would make the feature
# invisible instead of pending.
const _SAVE_EXISTS := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# The window may have changed since the last screen, and the canvas has to
	# follow it on a whole-pixel boundary or nothing drawn here lands on one.
	Look.fit_window()
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Look.CANVAS
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	# Bottom-right, quiet. A pixel game lives or dies on whether the window is an
	# exact multiple of its canvas, and that is invisible until it is written
	# down: a 1x here means the screen is being upscaled by the compositor and
	# nothing else about the picture will look right.
	var scale_note := Label.new()
	scale_note.text = Look.scale_line()
	scale_note.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	scale_note.offset_left = -560
	scale_note.offset_top = -34
	scale_note.offset_right = -16
	scale_note.offset_bottom = -12
	scale_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	scale_note.add_theme_color_override("font_color", Look.MUTED.darkened(0.3))
	Look.wear_body(scale_note, Look.TEXT)
	add_child(scale_note)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)

	var title := Label.new()
	title.text = UiText.t("start.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	box.add_child(title)

	var tagline := Label.new()
	tagline.text = UiText.t("start.tagline")
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_size_override("font_size", 20)
	tagline.add_theme_color_override("font_color", Look.MUTED)
	box.add_child(tagline)

	box.add_child(_spacer(32))

	var continue_button := _menu_button(UiText.t("start.continue"))
	continue_button.disabled = not _SAVE_EXISTS
	continue_button.pressed.connect(func() -> void: go("continue"))
	box.add_child(continue_button)

	if not _SAVE_EXISTS:
		var hint := Label.new()
		hint.text = UiText.t("start.continue_hint")
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.add_theme_font_size_override("font_size", 13)
		hint.add_theme_color_override("font_color", Look.MUTED.darkened(0.2))
		box.add_child(hint)

	var new_game := _menu_button(UiText.t("start.new_game"))
	new_game.pressed.connect(func() -> void: go("new_game"))
	box.add_child(new_game)

	var settings := _menu_button(UiText.t("start.settings"))
	settings.pressed.connect(func() -> void: go("settings"))
	box.add_child(settings)

	var quit := _menu_button(UiText.t("start.quit"))
	quit.pressed.connect(func() -> void: go("quit"))
	box.add_child(quit)

	new_game.grab_focus()

func _menu_button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(280, 46)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return button

func _spacer(height: int) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	return spacer
