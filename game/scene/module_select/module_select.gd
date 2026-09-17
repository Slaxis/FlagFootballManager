# Module Select — pick the universe before creating a manager.
#
# A module is a whole campaign: its clubs, its calendar, its rules. The native
# one is "Brasileirão de Flag 2026"; anything the player drops into
# `user://modules/<id>/` with a `module.json` shows up here alongside it, which
# is how a home-made league — the Elifoot tradition — gets to exist without a
# single line of game code.
#
# Lives in `game/scene/` (shell, rule R5) because it necessarily runs before
# any module is active.
extends Menu

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func _build_ui() -> void:
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

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var title := Label.new()
	title.text = UiText.t("module.title")
	title.add_theme_font_size_override("font_size", 34)
	box.add_child(title)

	var modules: Array[ModuleInfo] = Drive.list_modules()

	var subtitle := Label.new()
	subtitle.text = UiText.t("module.subtitle") % modules.size()
	subtitle.add_theme_color_override("font_color", Look.MUTED)
	box.add_child(subtitle)

	box.add_child(_spacer(12))

	if modules.is_empty():
		var empty := Label.new()
		empty.text = UiText.t("module.none")
		empty.add_theme_color_override("font_color", Look.BAD)
		box.add_child(empty)
	else:
		var first: Button = null
		for info: ModuleInfo in modules:
			var card: Button = _module_card(info)
			box.add_child(card)
			if first == null:
				first = card
		if first != null:
			first.grab_focus()

	box.add_child(_spacer(12))

	var back := Button.new()
	back.text = UiText.t("common.back")
	back.custom_minimum_size = Vector2(160, 40)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(func() -> void: go("back"))
	box.add_child(back)

# One clickable card per module: name, origin badge, and the description the
# manifest carries (which is why ModuleInfo learned to read `description`).
func _module_card(info: ModuleInfo) -> Button:
	var card := Button.new()
	card.custom_minimum_size = Vector2(0, 78)
	card.pressed.connect(_on_pick.bind(info.id))

	var rows := VBoxContainer.new()
	rows.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rows.add_theme_constant_override("separation", 2)
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "right"]:
		rows.add_theme_constant_override("margin_" + side, 14)
	card.add_child(rows)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_child(head)

	var name_label := Label.new()
	name_label.text = info.name
	name_label.add_theme_font_size_override("font_size", 20)
	head.add_child(name_label)

	var is_user: bool = info.user_path != ""
	var badge := Label.new()
	badge.text = "[%s]" % UiText.t("module.user" if is_user else "module.native")
	badge.add_theme_color_override("font_color",
		Look.MUTED if is_user else Look.MUTED.darkened(0.2))
	head.add_child(badge)

	var description := Label.new()
	description.text = info.description
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 13)
	description.add_theme_color_override("font_color", Look.MUTED)
	rows.add_child(description)

	return card

func _on_pick(module_id: String) -> void:
	if not Drive.set_module(module_id):
		Log.log(self, "error", "ModuleSelect: failed to activate module " + module_id)
		return
	go("selected")

func _spacer(height: int) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	return spacer
