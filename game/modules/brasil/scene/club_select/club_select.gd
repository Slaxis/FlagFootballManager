# Club selection — lists the clubs the module declares, read straight from
# TeamDef. No gameplay yet: this screen exists so the boot chain proves that
# per-Thing hosting found every team JSON and that Flow transitions work.
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

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 48)
	add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var title := Label.new()
	title.text = "ESCOLHA SEU CLUBE"
	title.add_theme_font_size_override("font_size", 34)
	box.add_child(title)

	var teams: Array = _teams()
	var hint := Label.new()
	hint.text = "%d clubes carregados do módulo" % teams.size()
	hint.add_theme_color_override("font_color", Color(0.58, 0.70, 0.60))
	box.add_child(hint)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	box.add_child(list)
	for team: Dictionary in teams:
		list.add_child(_team_row(team))

	var back := Button.new()
	back.text = "Voltar"
	back.custom_minimum_size = Vector2(160, 40)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(func() -> void: go("back"))
	box.add_child(back)
	back.grab_focus()

func _teams() -> Array:
	var def := Drive.def("team") as TeamDef
	if def == null:
		return []
	return def.all()

func _team_row(team: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var swatch := ColorRect.new()
	var colors: Array = team.get("colors", [])
	swatch.color = Color(String(colors[0])) if colors.size() > 0 else Color.WHITE
	swatch.custom_minimum_size = Vector2(18, 18)
	row.add_child(swatch)

	var name_label := Label.new()
	name_label.text = String(team.get("name", team.get("id", "?")))
	name_label.custom_minimum_size = Vector2(240, 0)
	row.add_child(name_label)

	var where := Label.new()
	where.text = "%s/%s" % [team.get("city", "?"), team.get("state", "?")]
	where.custom_minimum_size = Vector2(180, 0)
	where.add_theme_color_override("font_color", Color(0.62, 0.62, 0.62))
	row.add_child(where)

	var roster := Label.new()
	var players: Array = team.get("roster", [])
	roster.text = "%d atletas" % players.size()
	roster.add_theme_color_override("font_color", Color(0.62, 0.62, 0.62))
	row.add_child(roster)

	return row
