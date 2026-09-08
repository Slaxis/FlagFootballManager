# Create Manager — you, at 18, about to be called by a sandlot club.
#
# Produces the `career` Record onto the Blackboard. The Flow gates every later
# step on its presence, so this screen is the only place a career begins.
#
# Two things it deliberately does NOT ask:
#   • your gender — it asks which CATEGORY you play, which is the thing the
#     game actually needs and the thing that is true of people (decision 17)
#   • which club you want — Pick Team is locked until a national round is won
extends Menu

# 18 and unproven. The manager's own strength grows with results (decision 12),
# so starting low is what gives that growth somewhere to go.
const START_AGE := 18
const START_QUALITY := 40

var _career_seed: int = 0
var _manager: Actor = null
var _plays: String = Actor.CATEGORY_MASC
var _drafted: Dictionary = {}
var _name_field: LineEdit = null
var _root: VBoxContainer = null

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_career_seed = _new_seed()
	League.ensure_filled(_career_seed)
	_manager = _roll_manager()

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

	_root = VBoxContainer.new()
	_root.add_theme_constant_override("separation", 12)
	margin.add_child(_root)
	_build_ui()

func _build_ui() -> void:
	for child: Node in _root.get_children():
		child.queue_free()

	var title := Label.new()
	title.text = UiText.t("manager.title")
	title.add_theme_font_size_override("font_size", 34)
	_root.add_child(title)

	var seed_label := Label.new()
	seed_label.text = UiText.t("manager.seed") % _career_seed
	seed_label.add_theme_font_size_override("font_size", 12)
	seed_label.add_theme_color_override("font_color", Color(0.45, 0.47, 0.45))
	_root.add_child(seed_label)

	if _drafted.is_empty():
		_build_form()
	else:
		_build_result()

# --- Form ---

func _build_form() -> void:
	_root.add_child(_spacer(8))

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 10)
	_root.add_child(name_row)

	var name_label := Label.new()
	name_label.text = UiText.t("manager.name")
	name_label.custom_minimum_size = Vector2(120, 0)
	name_row.add_child(name_label)

	_name_field = LineEdit.new()
	_name_field.text = _manager.full_name()
	_name_field.custom_minimum_size = Vector2(300, 36)
	name_row.add_child(_name_field)

	var reroll := Button.new()
	reroll.text = "🎲 " + UiText.t("manager.reroll")
	reroll.pressed.connect(_on_reroll)
	name_row.add_child(reroll)

	var age := Label.new()
	age.text = UiText.t("manager.age") % START_AGE
	age.add_theme_color_override("font_color", Color(0.62, 0.62, 0.62))
	_root.add_child(age)

	_root.add_child(_spacer(6))
	_root.add_child(_sheet())
	_root.add_child(_spacer(6))
	_root.add_child(_plays_row())
	_root.add_child(_manages_row())
	_root.add_child(_spacer(10))

	var type_label := Label.new()
	type_label.text = UiText.t("manager.career_type")
	type_label.add_theme_font_size_override("font_size", 18)
	_root.add_child(type_label)

	var pick := Button.new()
	pick.text = "🔒 " + UiText.t("manager.pick_team")
	pick.disabled = true
	pick.custom_minimum_size = Vector2(280, 42)
	pick.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_root.add_child(pick)

	var locked_hint := Label.new()
	locked_hint.text = UiText.t("manager.pick_locked")
	locked_hint.add_theme_font_size_override("font_size", 12)
	locked_hint.add_theme_color_override("font_color", Color(0.45, 0.47, 0.45))
	_root.add_child(locked_hint)

	var random := Button.new()
	random.text = UiText.t("manager.random")
	random.custom_minimum_size = Vector2(280, 42)
	random.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	random.pressed.connect(_on_draw)
	_root.add_child(random)

	var random_hint := Label.new()
	random_hint.text = UiText.t("manager.random_hint")
	random_hint.add_theme_font_size_override("font_size", 12)
	random_hint.add_theme_color_override("font_color", Color(0.45, 0.47, 0.45))
	_root.add_child(random_hint)

	_root.add_child(_spacer(8))
	var back := Button.new()
	back.text = UiText.t("common.back")
	back.custom_minimum_size = Vector2(160, 38)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(func() -> void: go("back"))
	_root.add_child(back)

# The 7 attributes and the Geral, on screen. A.2 and A.3 shipped without a
# single pixel; this is the first place their numbers are visible.
func _sheet() -> Control:
	var stats := Drive.def("stat") as StatDef
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)

	var header := Label.new()
	header.text = "%s — %s %d" % [UiText.t("manager.sheet"), UiText.t("manager.overall"), _manager.overall()]
	header.add_theme_color_override("font_color", Color(0.58, 0.70, 0.60))
	box.add_child(header)

	if stats == null:
		return box
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 18)
	box.add_child(grid)
	for id: String in stats.base_ids():
		var cell := Label.new()
		var value: int = _manager.stat(id)
		cell.text = "%s %d" % [I18n.text(stats.base_stat(id).get("label", id), id), value]
		cell.add_theme_font_size_override("font_size", 13)
		grid.add_child(cell)
	return box

# Free choice, independent of any club: you might play the men's side, the
# women's, the mixed, or not play at all.
func _plays_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = UiText.t("manager.plays")
	label.custom_minimum_size = Vector2(120, 0)
	row.add_child(label)

	var categories := Drive.def("category") as CategoryDef
	var options: Array = categories.category_ids() if categories != null else []
	for id: String in options:
		var button := Button.new()
		button.text = categories.category_label(id)
		button.custom_minimum_size = Vector2(110, 34)
		button.disabled = _plays == id
		button.pressed.connect(_on_plays.bind(id))
		row.add_child(button)

	var none := Button.new()
	none.text = UiText.t("manager.plays_none")
	none.custom_minimum_size = Vector2(110, 34)
	none.disabled = _plays == ""
	none.pressed.connect(_on_plays.bind(""))
	row.add_child(none)
	return row

# Not a choice yet: the draft lands you in a tier-4 club, and every one of them
# fields only a men's side. It becomes a real choice the day a club has two.
func _manages_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = UiText.t("manager.manages")
	label.custom_minimum_size = Vector2(120, 0)
	row.add_child(label)

	var categories := Drive.def("category") as CategoryDef
	var value := Label.new()
	value.text = categories.category_label(Actor.CATEGORY_MASC) if categories != null else Actor.CATEGORY_MASC
	value.add_theme_color_override("font_color", Color(0.62, 0.62, 0.62))
	row.add_child(value)
	return row

# --- Result ---

func _build_result() -> void:
	_root.add_child(_spacer(24))

	var lead := Label.new()
	lead.text = UiText.t("manager.drafted")
	lead.add_theme_font_size_override("font_size", 18)
	_root.add_child(lead)

	var scheme: Dictionary = TeamColors.of(_drafted)
	var style := StyleBoxFlat.new()
	style.bg_color = scheme["plate"]
	style.set_content_margin_all(14)
	for corner: String in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		style.set("corner_radius_" + corner, 4)

	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", style)
	plate.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_root.add_child(plate)

	var club := Label.new()
	club.text = String(_drafted.get("name", "?"))
	club.add_theme_color_override("font_color", scheme["ink"])
	club.add_theme_font_size_override("font_size", 32)
	plate.add_child(club)

	var where := Label.new()
	where.text = "%s/%s · %s" % [
		_drafted.get("city", "?"), _drafted.get("state", "?"),
		UiText.t("tier.%d" % int(_drafted.get("tier", 4))),
	]
	where.add_theme_color_override("font_color", Color(0.62, 0.62, 0.62))
	_root.add_child(where)

	if not _club_fields_my_category():
		var warning := Label.new()
		warning.text = "⚠ " + UiText.t("manager.not_fielded")
		warning.add_theme_font_size_override("font_size", 12)
		warning.add_theme_color_override("font_color", Color(0.85, 0.72, 0.45))
		_root.add_child(warning)

	_root.add_child(_spacer(20))

	var start := Button.new()
	start.text = UiText.t("manager.start")
	start.custom_minimum_size = Vector2(280, 44)
	start.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	start.pressed.connect(_on_start)
	_root.add_child(start)
	start.grab_focus()

# You may play a category your club does not field — Diego played men's and
# coached women's. The game says so instead of pretending it cannot happen.
func _club_fields_my_category() -> bool:
	if _plays == "":
		return true
	var squads: Dictionary = _drafted.get("squads", {})
	return bool(squads.get(_plays, false))

# --- Actions ---

func _on_reroll() -> void:
	_career_seed = _new_seed()
	League.ensure_filled(_career_seed)
	_manager = _roll_manager()
	_build_ui()

func _on_plays(category: String) -> void:
	_plays = category
	_build_ui()

func _on_draw() -> void:
	_commit_name()
	var def := Drive.def("team") as TeamDef
	if def == null:
		return
	var pool: Array = def.by_tier(TeamGenerator.TIER_UNAFFILIATED)
	if pool.is_empty():
		Log.log(self, "error", "CreateManager: no tier-4 club to draft into.")
		return
	var rng: RandomNumberGenerator = SeedRng.make_rng(SeedRng.derive(_career_seed, "draft"))
	_drafted = pool[rng.randi() % pool.size()]
	_build_ui()

func _on_start() -> void:
	_commit_name()
	_manager.set_plays([_plays] if _plays != "" else [])
	_manager.set_manages([Actor.CATEGORY_MASC])
	_manager.set_team(String(_drafted.get("id", "")))
	write("career", Career.make(_manager, String(_drafted.get("id", "")), _career_seed))
	go("created")

# --- Internals ---

func _commit_name() -> void:
	if _name_field == null:
		return
	var typed: String = _name_field.text.strip_edges()
	if typed == "":
		return
	var parts: PackedStringArray = typed.split(" ", false)
	_manager.data["first_name"] = parts[0]
	_manager.data["last_name"] = " ".join(parts.slice(1)) if parts.size() > 1 else ""

# The manager's name is drawn from BOTH pools and is editable, which is what
# asking about categories instead of identity buys us: no gender question, and
# the player still gets a name they like.
func _roll_manager() -> Actor:
	var pool: String = Actor.CATEGORY_MISTO
	var actor: Actor = ActorGenerator.generate(
		SeedRng.derive(_career_seed, "manager"), START_QUALITY, pool,
		ActorGenerator.SPREAD, START_AGE, START_AGE)
	actor.set_plays([])
	actor.set_manages([Actor.CATEGORY_MASC])
	return actor

func _new_seed() -> int:
	return abs(int(Time.get_unix_time_from_system() * 1000.0)) % 100000000

func _spacer(height: int) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	return spacer
