extends Window

signal tryout_enrolled(team_id: String)

const T_PHONE: Dictionary = {"pt": "Celular", "en": "Phone"}
const T_BACK: Dictionary = {"pt": "< voltar", "en": "< back"}
const T_NETWORK: Dictionary = {"pt": "Network", "en": "Network"}
const T_COMMUNITIES: Dictionary = {"pt": "Comunidades", "en": "Communities"}
const T_PERSONS: Dictionary = {"pt": "Pessoas", "en": "People"}
const T_ENROLL: Dictionary = {"pt": "Inscrever no tryout", "en": "Enroll in tryout"}
const T_ENROLLED: Dictionary = {"pt": "Inscrito", "en": "Enrolled"}
const T_TRYOUT_DATE: Dictionary = {"pt": "Tryout: Semana {w} — {day} {slot}", "en": "Tryout: Week {w} — {day} {slot}"}
const T_MONTHLY: Dictionary = {"pt": "Mensalidade", "en": "Monthly fee"}
const T_DIFFICULTY: Dictionary = {"pt": "Dificuldade", "en": "Difficulty"}
const T_FOCUS: Dictionary = {"pt": "Foco do tryout", "en": "Tryout focus"}
const T_DIV: Dictionary = {"pt": "Divisão", "en": "Division"}
const T_FREE: Dictionary = {"pt": "Grátis", "en": "Free"}

const DAY_LABELS: Dictionary = {
	"mon": {"pt": "Seg", "en": "Mon"}, "tue": {"pt": "Ter", "en": "Tue"},
	"wed": {"pt": "Qua", "en": "Wed"}, "thu": {"pt": "Qui", "en": "Thu"},
	"fri": {"pt": "Sex", "en": "Fri"}, "sat": {"pt": "Sáb", "en": "Sat"},
	"sun": {"pt": "Dom", "en": "Sun"},
}
const SLOT_LABELS: Dictionary = {
	"morning": {"pt": "manhã", "en": "morning"}, "afternoon": {"pt": "tarde", "en": "afternoon"},
	"night": {"pt": "noite", "en": "night"}, "late_night": {"pt": "madrugada", "en": "late night"},
}
const DIFFICULTY_LABELS: Dictionary = {
	"easy":   {"pt": "fácil",  "en": "easy"},
	"medium": {"pt": "médio",  "en": "medium"},
	"hard":   {"pt": "difícil","en": "hard"},
}

enum Page { APPS, NETWORK, PROFILE }

@onready var btn_back: Button = $Margin/VBox/TopBar/BtnBack
@onready var page_title: Label = $Margin/VBox/TopBar/PageTitle
@onready var content: PanelContainer = $Margin/VBox/Content

var _page: Page = Page.APPS
var _profile_account_id: String = ""

func _ready() -> void:
	close_requested.connect(queue_free)
	btn_back.pressed.connect(_on_back)
	title = I18n.text(T_PHONE)
	_render()

func _on_back() -> void:
	Audio.play_sfx("menu_click")
	match _page:
		Page.NETWORK: _go(Page.APPS)
		Page.PROFILE: _go(Page.NETWORK)
		_: queue_free()

func _go(p: Page) -> void:
	_page = p
	_render()

func _render() -> void:
	for child: Node in content.get_children():
		child.queue_free()
	btn_back.visible = _page != Page.APPS
	btn_back.text = I18n.text(T_BACK)
	match _page:
		Page.APPS:    _render_apps()
		Page.NETWORK: _render_network()
		Page.PROFILE: _render_profile()

# --- Page: Apps grid ---

func _render_apps() -> void:
	page_title.text = I18n.text(T_PHONE)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)

	grid.add_child(_build_app_icon("network", "Network", "N", Color(0.2, 0.5, 0.9)))
	# Future: calendar, stats, store, messages, settings...

	margin.add_child(grid)
	content.add_child(margin)

func _build_app_icon(id: String, label: String, glyph: String, color: Color) -> Control:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(72, 72)
	btn.text = glyph
	btn.add_theme_font_size_override("font_size", 28)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.pressed.connect(_on_app_pressed.bind(id))
	box.add_child(btn)
	var lbl: Label = Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(lbl)
	return box

func _on_app_pressed(id: String) -> void:
	Audio.play_sfx("menu_click")
	if id == "network":
		_go(Page.NETWORK)

# --- Page: Network feed ---

func _render_network() -> void:
	page_title.text = I18n.text(T_NETWORK)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)

	var header_c: Label = Label.new()
	header_c.text = I18n.text(T_COMMUNITIES).to_upper()
	header_c.add_theme_font_size_override("font_size", 10)
	header_c.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6))
	vbox.add_child(header_c)

	for team_id: String in _list_4a_div_teams():
		var team: Dictionary = _read_team(team_id)
		vbox.add_child(_build_feed_card(team_id, team, true))

	# Future: list personal accounts below

	scroll.add_child(vbox)
	content.add_child(scroll)

func _list_4a_div_teams() -> Array[String]:
	# Drive.list_by_group("team") returns everyone; filter by division
	var result: Array[String] = []
	var all_ids: Array[String] = God.list_by_group("team")
	for id: String in all_ids:
		var t: Dictionary = _read_team(id)
		if String(t.get("division", "")) == "4a_div":
			result.append(id)
	return result

func _read_team(team_id: String) -> Dictionary:
	return Drive.read_content(Drive.content_path(team_id))

func _build_feed_card(team_id: String, team: Dictionary, is_community: bool) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.14, 0.18)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	var avatar: ColorRect = ColorRect.new()
	avatar.custom_minimum_size = Vector2(36, 36)
	avatar.color = _team_primary_color(team)
	hbox.add_child(avatar)

	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	var name_lbl: Label = Label.new()
	name_lbl.text = String(team.get("name", team_id))
	name_lbl.add_theme_font_size_override("font_size", 14)
	info.add_child(name_lbl)
	var meta_lbl: Label = Label.new()
	var tag: String = I18n.text(T_COMMUNITIES) if is_community else I18n.text(T_PERSONS)
	meta_lbl.text = tag + " · " + String(team.get("city", "")) + "/" + String(team.get("state", ""))
	meta_lbl.add_theme_font_size_override("font_size", 10)
	meta_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
	info.add_child(meta_lbl)
	hbox.add_child(info)

	panel.add_child(hbox)

	var btn: Button = Button.new()
	btn.flat = true
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.pressed.connect(_on_account_pressed.bind(team_id))
	panel.add_child(btn)
	return panel

func _team_primary_color(team: Dictionary) -> Color:
	var colors: Variant = team.get("colors", [])
	if colors is Array and not (colors as Array).is_empty():
		var hex: String = String((colors as Array)[0])
		if hex.begins_with("#"):
			return Color(hex)
	return Color(0.3, 0.3, 0.35)

func _on_account_pressed(team_id: String) -> void:
	Audio.play_sfx("menu_click")
	_profile_account_id = team_id
	_go(Page.PROFILE)

# --- Page: Profile (Ficha) ---

func _render_profile() -> void:
	var team: Dictionary = _read_team(_profile_account_id)
	page_title.text = String(team.get("name", _profile_account_id))

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)

	# Header strip with color
	var header: PanelContainer = PanelContainer.new()
	header.custom_minimum_size = Vector2(0, 60)
	var hstyle: StyleBoxFlat = StyleBoxFlat.new()
	hstyle.bg_color = _team_primary_color(team)
	header.add_theme_stylebox_override("panel", hstyle)
	var htitle: Label = Label.new()
	htitle.text = String(team.get("name", "?"))
	htitle.add_theme_font_size_override("font_size", 18)
	htitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	htitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(htitle)
	vbox.add_child(header)

	# Description
	var desc_rtl: RichTextLabel = RichTextLabel.new()
	desc_rtl.bbcode_enabled = true
	desc_rtl.fit_content = true
	desc_rtl.text = "[i]" + I18n.text(team.get("description", "")) + "[/i]"
	vbox.add_child(desc_rtl)

	# Stats panel
	vbox.add_child(_profile_row(I18n.text(T_DIV),        String(team.get("division", "?"))))
	vbox.add_child(_profile_row(I18n.text(T_DIFFICULTY), I18n.text(DIFFICULTY_LABELS.get(String(team.get("difficulty", "")), team.get("difficulty", "?")))))
	vbox.add_child(_profile_row(I18n.text(T_FOCUS),      ", ".join(team.get("drill_focus", []))))
	var fee: int = int(team.get("monthly_fee", 0))
	vbox.add_child(_profile_row(I18n.text(T_MONTHLY),    "R$ " + str(fee) if fee > 0 else I18n.text(T_FREE)))

	# Tryout scheduling row
	var tryout_week: int = int(team.get("tryout_week", 0))
	var tryout_day: String = String(team.get("tryout_day", ""))
	var tryout_slot: String = String(team.get("tryout_slot", ""))
	if tryout_week > 0:
		var date_label: Label = Label.new()
		date_label.add_theme_font_size_override("font_size", 12)
		date_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.4))
		var date_text: String = I18n.format(I18n.text(T_TRYOUT_DATE), {
			"w": str(tryout_week),
			"day": I18n.text(DAY_LABELS.get(tryout_day, tryout_day)),
			"slot": I18n.text(SLOT_LABELS.get(tryout_slot, tryout_slot)),
		})
		date_label.text = date_text
		vbox.add_child(date_label)

	# Enroll button
	var enrolled: Dictionary = The.session.get("enrolled_tryouts", {})
	var btn_enroll: Button = Button.new()
	btn_enroll.custom_minimum_size = Vector2(0, 40)
	btn_enroll.add_theme_font_size_override("font_size", 14)
	if enrolled.has(_profile_account_id):
		btn_enroll.text = "✓ " + I18n.text(T_ENROLLED)
		btn_enroll.disabled = true
	else:
		btn_enroll.text = I18n.text(T_ENROLL)
		btn_enroll.pressed.connect(_on_enroll)
	vbox.add_child(btn_enroll)

	scroll.add_child(vbox)
	content.add_child(scroll)

func _profile_row(label: String, value: String) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var k: Label = Label.new()
	k.text = label
	k.custom_minimum_size = Vector2(140, 0)
	k.add_theme_font_size_override("font_size", 12)
	k.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	row.add_child(k)
	var v: Label = Label.new()
	v.text = value
	v.add_theme_font_size_override("font_size", 12)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(v)
	return row

func _on_enroll() -> void:
	Audio.play_sfx("pass")
	var team: Dictionary = _read_team(_profile_account_id)
	var enrolled: Dictionary = The.session.get("enrolled_tryouts", {})
	enrolled[_profile_account_id] = {
		"week": int(team.get("tryout_week", 0)),
		"day": String(team.get("tryout_day", "")),
		"slot": String(team.get("tryout_slot", "")),
	}
	The.session["enrolled_tryouts"] = enrolled
	tryout_enrolled.emit(_profile_account_id)
	_render()
