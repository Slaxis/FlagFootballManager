# Draft — the world being built, while you watch it happen.
#
# Two hundred careers get simulated between pressing COMEÇAR and seeing your
# squad, and that is about nine seconds of arithmetic. Done inside the team
# screen's `_ready` it was nine seconds of a window that looks hung — no
# repaint, no cursor, nothing to tell you the game had not died.
#
# So it became a screen. `LeagueDraft` is resumable, this drives it a few
# milliseconds at a time, and the bar moves because there is genuinely that
# much to do.
#
# AND IT PRINTS WHAT IT DID. That is the more interesting half: every bug this
# system has had so far was quiet — the club that ended up with six rushers,
# the fit term comparing two different rulers, the Praça that came out empty.
# None of them raised anything. A scrollable list of who went where and why is
# how you catch the next one, which is why the OK button waits for you instead
# of the screen moving on by itself.
extends Menu

# How long to spend working per frame. Big enough that the draft is not made
# slower by being watched, small enough that the bar still redraws — at this
# budget a frame lands around 30ms and the whole thing costs about a second
# more than doing it blind.
const BUDGET_MS := 25
# The log is appended incrementally, but the bar and the caption are cheap
# enough to refresh every frame.
const LINES_PER_PAINT := 40

var BG := Color(0.055, 0.078, 0.063)
var PANEL := Color(0.086, 0.118, 0.094)
var ACCENT := Color(0.49, 0.78, 0.45)
var MUTED := Color(0.47, 0.52, 0.48)
var TEXT := Color(0.87, 0.90, 0.87)
var LINE := Color(0.16, 0.22, 0.17)

var _run: LeagueDraft = null
var _bar: ProgressBar = null
var _caption: Label = null
var _log: RichTextLabel = null
var _ok: Button = null
var _printed: int = 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_wear_club_colours()
	_build_ui()
	_start()

func _process(_delta: float) -> void:
	if _run == null or _run.is_done():
		return
	# A time budget, not a step count. One step is a whole lived career and
	# they are not the same size — a fifteen-year veteran costs three times
	# what a rookie does, so counting steps would stutter exactly where the
	# work is heaviest.
	var until: int = Time.get_ticks_msec() + BUDGET_MS
	while not _run.is_done() and Time.get_ticks_msec() < until:
		_run.step()
	_paint()
	if _run.is_done():
		_finish()

# --- Building ---

func _start() -> void:
	var career := read("career") as Career
	var seed_value: int = career.career_seed if career != null else 0
	var rosters := read("rosters") as Rosters
	var praca := read("praca") as Praca
	if rosters == null:
		rosters = Rosters.make(seed_value)
	if praca == null:
		praca = Praca.make(seed_value)
	# You are seated at your own club BEFORE the draft runs, so the club counts
	# you against its needs and does not go and sign a second head coach.
	if career != null and career.manager != null:
		var mine: Array = career.manager.plays()
		if mine.is_empty():
			mine = [Actor.CATEGORY_MASC]
		for entry: Variant in mine:
			rosters.add(career.team_id, String(entry), career.manager)
	write("rosters", rosters)
	write("praca", praca)
	_run = LeagueDraft.make(rosters, praca, Actor.CATEGORY_MASC)
	_paint()
	if _run.is_done():
		_finish()

func _finish() -> void:
	_paint()
	_ok.disabled = false
	_ok.text = UiText.t("draft.ok")
	_ok.grab_focus()

func _paint() -> void:
	_bar.value = _run.progress() * 100.0
	_caption.text = "%s   ·   %d%%" % [_run.headline(), int(round(_run.progress() * 100.0))]
	while _printed < _run.lines.size():
		_log.add_text(_run.lines[_printed] + "\n")
		_printed += 1

# --- Chrome ---

# The club's own colours, same derivation as the team screen: you are already
# inside your club by the time this runs, and arriving at a green screen and
# then a yellow one reads as two different games.
func _wear_club_colours() -> void:
	var career := read("career") as Career
	var teams := Drive.def("team") as TeamDef
	var club: Dictionary = teams.get_team(career.team_id) if career != null and teams != null else {}
	var scheme: Dictionary = TeamColors.of(club)
	var plate: Color = scheme["plate"]
	var ink: Color = scheme["ink"]
	BG = plate.darkened(0.82) if plate.get_luminance() > 0.35 else plate.darkened(0.45)
	PANEL = BG.lightened(0.06)
	LINE = BG.lightened(0.16)
	ACCENT = ink if ink.get_luminance() > 0.3 else plate.lightened(0.45)
	TEXT = ACCENT.lightened(0.55)
	MUTED = TEXT.darkened(0.45)

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = LINE
	style.set_border_width_all(1)
	style.set_content_margin_all(24)
	for corner: String in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		style.set("corner_radius_" + corner, 4)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(1240, 0)
	# Tagged for tests/fit_check.tscn: THIS is the node that has to fit on the
	# screen. The check cannot guess it — a ScrollContainer reports a tiny
	# minimum by design, so measuring the outermost thing would hide exactly the
	# problem the check exists to catch.
	panel.set_meta("fit_root", true)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var title := Label.new()
	title.text = UiText.t("draft.title")
	title.add_theme_color_override("font_color", ACCENT)
	Look.wear_display(title, Look.TITLE)
	box.add_child(title)

	var lead := Label.new()
	lead.text = UiText.t("draft.subtitle")
	lead.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lead.custom_minimum_size = Vector2(1180, 0)
	lead.add_theme_color_override("font_color", MUTED)
	Look.wear_body(lead, Look.TINY)
	box.add_child(lead)

	_bar = ProgressBar.new()
	_bar.max_value = 100.0
	_bar.value = 0.0
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0, 14)
	var track := StyleBoxFlat.new()
	track.bg_color = BG
	track.border_color = LINE
	track.set_border_width_all(1)
	var fill := StyleBoxFlat.new()
	fill.bg_color = ACCENT
	_bar.add_theme_stylebox_override("background", track)
	_bar.add_theme_stylebox_override("fill", fill)
	box.add_child(_bar)

	_caption = Label.new()
	_caption.text = ""
	_caption.add_theme_color_override("font_color", TEXT)
	Look.wear_body(_caption, Look.SMALL)
	box.add_child(_caption)

	# RichTextLabel and not a Label in a ScrollContainer: it appends without
	# re-laying-out six hundred lines, and it follows its own tail, which is the
	# only way a log that is still being written reads as one.
	_log = RichTextLabel.new()
	_log.bbcode_enabled = false
	_log.scroll_following = true
	_log.selection_enabled = true
	_log.custom_minimum_size = Vector2(1180, 470)
	_log.add_theme_color_override("default_color", MUTED)
	Look.wear_body(_log, Look.TINY)
	var log_style := StyleBoxFlat.new()
	log_style.bg_color = BG
	log_style.border_color = LINE
	log_style.set_border_width_all(1)
	log_style.set_content_margin_all(8)
	_log.add_theme_stylebox_override("normal", log_style)
	box.add_child(_log)

	_ok = Button.new()
	_ok.text = UiText.t("draft.working")
	_ok.disabled = true
	_ok.custom_minimum_size = Vector2(0, 38)
	_ok.pressed.connect(func() -> void: go("drafted"))
	var ok_style := StyleBoxFlat.new()
	ok_style.bg_color = ACCENT
	ok_style.set_content_margin_all(6)
	_ok.add_theme_stylebox_override("normal", ok_style)
	_ok.add_theme_stylebox_override("hover", ok_style)
	_ok.add_theme_stylebox_override("pressed", ok_style)
	var off_style := StyleBoxFlat.new()
	off_style.bg_color = LINE
	off_style.set_content_margin_all(6)
	_ok.add_theme_stylebox_override("disabled", off_style)
	_ok.add_theme_color_override("font_color", BG)
	_ok.add_theme_color_override("font_hover_color", BG)
	_ok.add_theme_color_override("font_pressed_color", BG)
	_ok.add_theme_color_override("font_disabled_color", MUTED)
	_ok.set_meta("draft_ok", true)
	box.add_child(_ok)
