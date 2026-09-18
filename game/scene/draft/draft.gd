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

# ⚠️ THE DEFAULTS CAME FROM `Look`, and they did not use to. These six were
# hand-written GREEN — Elifoot's green, kept alive in two screens long after
# decision 62 took it off the palette. It never showed, because
# `_wear_club_colours()` overwrites all of them a frame later, so the file sat
# there asserting something false about the game for months.
var CANVAS := Look.CANVAS
var SIGNAL := Look.ACCENT
var MUTED := Look.MUTED
var INK := Look.INK
var LINE := Look.LINE
var WELL := Look.WELL

var _run: LeagueDraft = null
var _bar: ProgressBar = null
var _caption: Label = null
var _log: RichTextLabel = null
var _ok: Button = null
var _printed: int = 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# The window may have changed since the last screen, and the canvas has to
	# follow it on a whole-pixel boundary or nothing drawn here lands on one.
	Look.fit_window()
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
# ⚠️ THE CLUB DRESSES THE WINDOW, NOT THE MONITOR. This used to set the
# background to the club's own background, so the draft of a yellow club was two
# megapixels of yellow with a log written on it. The page is black now and the
# club arrives as the frame, the heading and the bar — which is more of the club
# than a wall of it was, because you can actually see where it is.
func _wear_club_colours() -> void:
	var career := read("career") as Career
	var teams := Drive.def("team") as TeamDef
	var club: Dictionary = teams.get_team(career.team_id) if career != null and teams != null else {}
	var scheme: Dictionary = Look.club_scheme(club)
	CANVAS = scheme["canvas"]
	SIGNAL = scheme["signal"]
	INK = scheme["canvas_ink"]
	MUTED = scheme["canvas_muted"]
	LINE = SIGNAL.lerp(CANVAS, 0.55)
	WELL = Look.WELL

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = CANVAS
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	# The window: black inside, outlined in the club. It fills most of the
	# screen, so filling it with the club's own background would put the wall
	# straight back — the frame is what says whose draft this is.
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = CANVAS
	style.border_color = SIGNAL
	style.set_border_width_all(Look.EDGE_WIDTH)
	style.set_content_margin_all(22)
	for corner: String in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		style.set("corner_radius_" + corner, 4)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(1900, 0)
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
	title.add_theme_color_override("font_color", SIGNAL)
	Look.wear_display(title, Look.TITLE)
	box.add_child(title)

	var lead := Label.new()
	lead.text = UiText.t("draft.subtitle")
	lead.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lead.custom_minimum_size = Vector2(1850, 0)
	lead.add_theme_color_override("font_color", MUTED)
	Look.wear_body(lead, Look.TINY)
	box.add_child(lead)

	_bar = ProgressBar.new()
	_bar.max_value = 100.0
	_bar.value = 0.0
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0, 14)
	var track := StyleBoxFlat.new()
	track.bg_color = WELL
	track.border_color = LINE
	track.set_border_width_all(1)
	var fill := StyleBoxFlat.new()
	fill.bg_color = SIGNAL
	_bar.add_theme_stylebox_override("background", track)
	_bar.add_theme_stylebox_override("fill", fill)
	box.add_child(_bar)

	_caption = Label.new()
	_caption.text = ""
	_caption.add_theme_color_override("font_color", INK)
	Look.wear_body(_caption, Look.SMALL)
	box.add_child(_caption)

	# RichTextLabel and not a Label in a ScrollContainer: it appends without
	# re-laying-out six hundred lines, and it follows its own tail, which is the
	# only way a log that is still being written reads as one.
	_log = RichTextLabel.new()
	_log.bbcode_enabled = false
	_log.scroll_following = true
	_log.selection_enabled = true
	_log.custom_minimum_size = Vector2(1850, 760)
	_log.add_theme_color_override("default_color", MUTED)
	Look.wear_body(_log, Look.TINY)
	var log_style := StyleBoxFlat.new()
	log_style.bg_color = WELL
	log_style.border_color = LINE
	log_style.set_border_width_all(1)
	log_style.set_content_margin_all(8)
	_log.add_theme_stylebox_override("normal", log_style)
	box.add_child(_log)

	_ok = Button.new()
	_ok.text = UiText.t("draft.working")
	_ok.disabled = true
	_ok.custom_minimum_size = Vector2(0, 40)
	_ok.pressed.connect(func() -> void: go("drafted"))
	var ok_style := StyleBoxFlat.new()
	ok_style.bg_color = SIGNAL
	ok_style.set_content_margin_all(6)
	_ok.add_theme_stylebox_override("normal", ok_style)
	_ok.add_theme_stylebox_override("hover", ok_style)
	_ok.add_theme_stylebox_override("pressed", ok_style)
	var off_style := StyleBoxFlat.new()
	off_style.bg_color = LINE
	off_style.set_content_margin_all(6)
	_ok.add_theme_stylebox_override("disabled", off_style)
	_ok.add_theme_color_override("font_color", CANVAS)
	_ok.add_theme_color_override("font_hover_color", CANVAS)
	_ok.add_theme_color_override("font_pressed_color", CANVAS)
	_ok.add_theme_color_override("font_disabled_color", MUTED)
	_ok.set_meta("draft_ok", true)
	box.add_child(_ok)
