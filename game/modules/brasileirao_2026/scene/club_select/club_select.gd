# Club listing — every club the module declares, read straight from TeamDef,
# strongest first. No gameplay yet: this screen is how we eyeball the team
# database, and it proves per-Thing hosting, the tier/reputation fields and
# the UF-derived region are all wired.
extends Menu

const _TIER_COLOR: Dictionary = {
	1: Color(0.95, 0.82, 0.35),
	2: Color(0.75, 0.78, 0.82),
	3: Color(0.72, 0.52, 0.36),
	4: Color(0.45, 0.47, 0.45),
}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	League.ensure_filled()
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
	title.text = UiText.t("clubs.title")
	title.add_theme_font_size_override("font_size", 34)
	box.add_child(title)

	var teams: Array = _teams()
	var subtitle := Label.new()
	subtitle.text = UiText.t("clubs.count") % [_region_label(teams), teams.size()]
	subtitle.add_theme_color_override("font_color", Color(0.58, 0.70, 0.60))
	box.add_child(subtitle)

	box.add_child(_spacer(10))

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 5)
	box.add_child(list)
	for team: Dictionary in teams:
		list.add_child(_team_row(team))

	box.add_child(_spacer(10))

	var back := Button.new()
	back.text = UiText.t("common.back")
	back.custom_minimum_size = Vector2(160, 40)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(func() -> void: go("back"))
	box.add_child(back)
	back.grab_focus()

func _def() -> TeamDef:
	return Drive.def("team") as TeamDef

func _teams() -> Array:
	var def := _def()
	return def.by_reputation() if def != null else []

# Proves the region comes from the UF via RegionDef, not from the club JSON.
func _region_label(teams: Array) -> String:
	if teams.is_empty():
		return "—"
	var def := _def()
	if def == null:
		return "—"
	var region_id: String = def.region_of(teams[0])
	var region_def := Drive.def("region") as RegionDef
	if region_def == null or region_id == "":
		return region_id
	return I18n.text(region_def.label(region_id), region_id)

func _team_row(team: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var tier: int = int(team.get("tier", 4))
	var badge := Label.new()
	badge.text = UiText.t("tier.%d" % tier, "?")
	badge.custom_minimum_size = Vector2(96, 0)
	badge.add_theme_color_override("font_color", _TIER_COLOR.get(tier, Color.WHITE))
	row.add_child(badge)

	var colors: Array = team.get("colors", [])
	row.add_child(_swatch(colors, 0))
	row.add_child(_swatch(colors, 1))

	row.add_child(_name_plate(team))

	var where := Label.new()
	where.text = "%s/%s" % [team.get("city", "?"), team.get("state", "?")]
	where.custom_minimum_size = Vector2(180, 0)
	where.add_theme_color_override("font_color", Color(0.62, 0.62, 0.62))
	row.add_child(where)

	var squads := Label.new()
	squads.text = _squad_marks(team)
	squads.custom_minimum_size = Vector2(70, 0)
	squads.add_theme_color_override("font_color", Color(0.62, 0.62, 0.62))
	row.add_child(squads)

	var rep := Label.new()
	var reputation: int = int(team.get("reputation", 0))
	rep.text = "%s %d" % ["█".repeat(int(reputation / 10.0)), reputation]
	rep.add_theme_color_override("font_color", Color(0.58, 0.70, 0.60))
	row.add_child(rep)

	return row

# Elifoot-style: the club name printed in the club's own colours, so the row
# is recognisable before it is read.
func _name_plate(team: Dictionary) -> Control:
	var scheme: Dictionary = TeamColors.of(team)
	var style := StyleBoxFlat.new()
	style.bg_color = scheme["plate"]
	style.set_content_margin_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(280, 0)

	var label := Label.new()
	label.text = String(team.get("name", team.get("id", "?")))
	label.add_theme_color_override("font_color", scheme["ink"])
	label.add_theme_font_size_override("font_size", 17)
	panel.add_child(label)
	return panel

func _swatch(colors: Array, idx: int) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = Color(String(colors[idx])) if colors.size() > idx else Color(0.2, 0.2, 0.2)
	rect.custom_minimum_size = Vector2(14, 18)
	return rect

func _squad_marks(team: Dictionary) -> String:
	var squads: Dictionary = team.get("squads", {})
	var marks: Array[String] = []
	if bool(squads.get("masc", false)):
		marks.append("M")
	if bool(squads.get("fem", false)):
		marks.append("F")
	return " ".join(marks)

func _spacer(height: int) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, height)
	return s
