# Generalized card minigame: prompt + clickable cards under time pressure.
# Supports label cards, path-drawing cards, and play-reference cards.
extends Control

signal minigame_finished(score: int, total: int)

const T_CORRECT: Dictionary = {"pt": "CORRETO!", "en": "CORRECT!"}
const T_WRONG: Dictionary = {"pt": "ERRADO!", "en": "WRONG!"}
const T_SCORE: Dictionary = {"pt": "Pontos: ", "en": "Score: "}
const T_ROUND: Dictionary = {"pt": "Rodada: ", "en": "Round: "}

const FIELD_COLOR := Color(0.15, 0.35, 0.15)
const PLAYER_COLOR := Color(0.2, 0.6, 1.0)
const ROUTE_CORRECT := Color(0.2, 0.85, 0.2)
const ROUTE_WRONG := Color(0.85, 0.2, 0.2)
const CARD_BG := Color(0.12, 0.12, 0.12)
const CARD_BORDER := Color(0.4, 0.4, 0.4)
const CARD_HOVER := Color(0.2, 0.2, 0.3)
const CARD_CORRECT_BG := Color(0.1, 0.25, 0.1)
const CARD_WRONG_BG := Color(0.25, 0.1, 0.1)

var _rounds: Array[Dictionary] = []
var _round_index: int = 0
var _score: int = 0
var _timer_seconds: float = 8.0
var _timer_remaining: float = 0.0
var _timer_active: bool = false
var _waiting: bool = false
var _drill_name: Dictionary = {}
var _current_round: Dictionary = {}
var _card_options: Array[Dictionary] = []
var _card_buttons: Array[Button] = []
var _play_def: Def

var _call_label: Label
var _result_label: Label
var _score_label: Label
var _round_label: Label
var _timer_bar: ProgressBar
var _cards_container: HBoxContainer
var _field_panel: Panel
var _route_line: Line2D
var _player_dot: ColorRect
var _drill_label: Label

func setup(config: Dictionary) -> void:
	var raw_rounds: Variant = config.get("rounds", [])
	if raw_rounds is Array:
		for r: Variant in (raw_rounds as Array):
			if r is Dictionary:
				_rounds.append(r as Dictionary)
	_timer_seconds = float(config.get("timer_sec", 8.0))
	_drill_name = config.get("drill_name", {})

func _ready() -> void:
	_play_def = Drive.def("play")
	_build_ui()
	if not _rounds.is_empty():
		_start_round()

func _process(delta: float) -> void:
	if _timer_active:
		_timer_remaining -= delta
		_timer_bar.value = _timer_remaining
		if _timer_remaining <= 0:
			_timer_active = false
			_on_timeout()

# --- UI ---

func _build_ui() -> void:
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 6)
	add_child(vbox)

	# Top bar: drill name + score + round
	var top_bar: HBoxContainer = HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 12)
	vbox.add_child(top_bar)

	_drill_label = Label.new()
	_drill_label.add_theme_font_size_override("font_size", 14)
	_drill_label.text = I18n.text(_drill_name) if not _drill_name.is_empty() else ""
	_drill_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(_drill_label)

	_score_label = Label.new()
	_score_label.add_theme_font_size_override("font_size", 14)
	top_bar.add_child(_score_label)

	_round_label = Label.new()
	_round_label.add_theme_font_size_override("font_size", 14)
	top_bar.add_child(_round_label)

	# Timer
	_timer_bar = ProgressBar.new()
	_timer_bar.custom_minimum_size = Vector2(0, 14)
	_timer_bar.show_percentage = false
	vbox.add_child(_timer_bar)

	# Call label
	_call_label = Label.new()
	_call_label.add_theme_font_size_override("font_size", 20)
	_call_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_call_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_call_label)

	# Field panel (for path display)
	_field_panel = Panel.new()
	_field_panel.custom_minimum_size = Vector2(0, 140)
	_field_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var field_style: StyleBoxFlat = StyleBoxFlat.new()
	field_style.bg_color = FIELD_COLOR
	field_style.corner_radius_top_left = 4
	field_style.corner_radius_top_right = 4
	field_style.corner_radius_bottom_left = 4
	field_style.corner_radius_bottom_right = 4
	_field_panel.add_theme_stylebox_override("panel", field_style)
	vbox.add_child(_field_panel)

	_route_line = Line2D.new()
	_route_line.width = 3.0
	_route_line.default_color = ROUTE_CORRECT
	_field_panel.add_child(_route_line)

	_player_dot = ColorRect.new()
	_player_dot.custom_minimum_size = Vector2(12, 12)
	_player_dot.size = Vector2(12, 12)
	_player_dot.color = PLAYER_COLOR
	_player_dot.visible = false
	_field_panel.add_child(_player_dot)

	# Result
	_result_label = Label.new()
	_result_label.add_theme_font_size_override("font_size", 18)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.text = ""
	vbox.add_child(_result_label)

	# Cards
	_cards_container = HBoxContainer.new()
	_cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_container.add_theme_constant_override("separation", 16)
	vbox.add_child(_cards_container)

# --- Round logic ---

func _start_round() -> void:
	if _round_index >= _rounds.size():
		minigame_finished.emit(_score, _rounds.size())
		return
	_current_round = _rounds[_round_index]
	_round_index += 1
	_update_labels()
	_result_label.text = ""
	_route_line.clear_points()
	_player_dot.visible = false
	_waiting = false

	# Show prompt
	_call_label.text = I18n.text(_current_round.get("prompt", {"pt": "?", "en": "?"}))

	# Show display_path on field if present
	var display_path: Variant = _current_round.get("display_path", null)
	var card_type: String = String(_current_round.get("card_type", "label"))
	if display_path is Array and (display_path as Array).size() >= 2:
		_field_panel.visible = true
		_draw_path_on_field(display_path as Array, PLAYER_COLOR)
	elif card_type == "play_ref":
		_field_panel.visible = false
	else:
		_field_panel.visible = false

	# Build option cards
	_build_cards()

	# Timer
	_timer_remaining = _timer_seconds
	_timer_bar.max_value = _timer_seconds
	_timer_bar.value = _timer_remaining
	_timer_active = true

func _build_cards() -> void:
	for child: Node in _cards_container.get_children():
		child.queue_free()
	_card_buttons.clear()
	_card_options.clear()

	var card_type: String = String(_current_round.get("card_type", "label"))
	var options_raw: Variant = _current_round.get("options", [])
	if not options_raw is Array:
		return

	for opt: Variant in (options_raw as Array):
		var option: Dictionary = {}
		if opt is Dictionary:
			option = opt as Dictionary
		elif opt is String and _play_def != null:
			# play_ref: resolve play id to play dict
			var play: Dictionary = (_play_def as PlayDef).get_play(opt as String)
			if not play.is_empty():
				option = {"id": String(opt), "play": play}
			else:
				option = {"id": String(opt), "label": {"pt": String(opt), "en": String(opt)}}
		else:
			continue
		_card_options.append(option)

	# Shuffle card order
	_card_options.shuffle()

	for opt: Dictionary in _card_options:
		var btn: Button = _make_card(opt, card_type)
		btn.pressed.connect(_on_card_picked.bind(opt))
		_cards_container.add_child(btn)
		_card_buttons.append(btn)

func _make_card(opt: Dictionary, card_type: String) -> Button:
	var btn: Button = Button.new()
	var style_normal: StyleBoxFlat = StyleBoxFlat.new()
	style_normal.bg_color = CARD_BG
	style_normal.border_width_left = 2
	style_normal.border_width_top = 2
	style_normal.border_width_right = 2
	style_normal.border_width_bottom = 2
	style_normal.border_color = CARD_BORDER
	style_normal.corner_radius_top_left = 6
	style_normal.corner_radius_top_right = 6
	style_normal.corner_radius_bottom_left = 6
	style_normal.corner_radius_bottom_right = 6
	style_normal.content_margin_left = 8
	style_normal.content_margin_right = 8
	style_normal.content_margin_top = 8
	style_normal.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", style_normal)
	var style_hover: StyleBoxFlat = style_normal.duplicate()
	style_hover.bg_color = CARD_HOVER
	btn.add_theme_stylebox_override("hover", style_hover)

	match card_type:
		"path":
			btn.custom_minimum_size = Vector2(140, 120)
			btn.text = ""
			var path_data: Variant = opt.get("path", [])
			if path_data is Array and (path_data as Array).size() >= 2:
				_draw_route_on_card(btn, path_data as Array, Vector2(140, 120))
			else:
				btn.text = "?"
		"play_ref":
			btn.custom_minimum_size = Vector2(140, 120)
			btn.text = ""
			var play: Dictionary = opt.get("play", {})
			var path_data: Variant = play.get("path", [])
			if path_data is Array and (path_data as Array).size() >= 2:
				_draw_route_on_card(btn, path_data as Array, Vector2(140, 120))
			else:
				btn.text = I18n.text(play.get("name", {"pt": "?", "en": "?"}))
		_: # "label"
			btn.custom_minimum_size = Vector2(180, 100)
			btn.add_theme_font_size_override("font_size", 18)
			btn.text = I18n.text(opt.get("label", {"pt": "?", "en": "?"}))
	return btn

func _draw_route_on_card(btn: Button, path_raw: Array, card_size: Vector2) -> void:
	var raw_pts: Array[Vector2] = []
	for p: Variant in path_raw:
		if p is Array and (p as Array).size() >= 2:
			raw_pts.append(Vector2(float((p as Array)[0]), float((p as Array)[1])))
	if raw_pts.size() < 2:
		btn.text = "?"
		return
	var min_x: float = raw_pts[0].x
	var max_x: float = raw_pts[0].x
	var min_y: float = raw_pts[0].y
	var max_y: float = raw_pts[0].y
	for pt: Vector2 in raw_pts:
		min_x = minf(min_x, pt.x)
		max_x = maxf(max_x, pt.x)
		min_y = minf(min_y, pt.y)
		max_y = maxf(max_y, pt.y)
	var range_x: float = maxf(max_x - min_x, 1.0)
	var range_y: float = maxf(max_y - min_y, 1.0)
	var padding: float = 16.0
	var draw_w: float = card_size.x - padding * 2
	var draw_h: float = card_size.y - padding * 2
	var scale_f: float = minf(draw_w / range_x, draw_h / range_y)
	var offset_x: float = padding + (draw_w - range_x * scale_f) * 0.5
	var offset_y: float = padding + (draw_h - range_y * scale_f) * 0.5
	var line: Line2D = Line2D.new()
	line.width = 3.0
	line.default_color = Color(1, 1, 1, 0.8)
	var first_screen: Vector2 = Vector2.ZERO
	for i: int in raw_pts.size():
		var sx: float = offset_x + (raw_pts[i].x - min_x) * scale_f
		var sy: float = offset_y + (raw_pts[i].y - min_y) * scale_f
		var screen_pt: Vector2 = Vector2(sx, sy)
		line.add_point(screen_pt)
		if i == 0:
			first_screen = screen_pt
	btn.add_child(line)
	var dot: ColorRect = ColorRect.new()
	dot.custom_minimum_size = Vector2(8, 8)
	dot.size = Vector2(8, 8)
	dot.color = PLAYER_COLOR
	dot.position = first_screen - Vector2(4, 4)
	btn.add_child(dot)

func _draw_path_on_field(path_raw: Array, color: Color) -> void:
	_route_line.clear_points()
	_route_line.default_color = color
	var field_size: Vector2 = _field_panel.size
	if field_size.x < 10:
		field_size = _field_panel.custom_minimum_size
	var center_x: float = field_size.x * 0.5
	var start_y: float = field_size.y * 0.75
	var scale_factor: float = field_size.y / 100.0
	var points: Array[Vector2] = []
	for p: Variant in path_raw:
		if p is Array and (p as Array).size() >= 2:
			var px: float = center_x + float((p as Array)[0]) * scale_factor
			var py: float = start_y + float((p as Array)[1]) * scale_factor
			points.append(Vector2(px, py))
	if points.is_empty():
		return
	_player_dot.visible = true
	_player_dot.position = points[0] - Vector2(6, 6)
	for pt: Vector2 in points:
		_route_line.add_point(pt)

# --- Pick / Timeout ---

func _on_card_picked(option: Dictionary) -> void:
	if _waiting:
		return
	_timer_active = false
	_waiting = true
	var picked_id: String = String(option.get("id", ""))
	var correct_id: String = String(_current_round.get("correct", ""))
	var correct: bool = picked_id == correct_id

	# Color cards
	for i: int in _card_options.size():
		var opt_id: String = String(_card_options[i].get("id", ""))
		var style: StyleBoxFlat = _card_buttons[i].get_theme_stylebox("normal").duplicate()
		if opt_id == correct_id:
			style.bg_color = CARD_CORRECT_BG
			style.border_color = ROUTE_CORRECT
		elif opt_id == picked_id:
			style.bg_color = CARD_WRONG_BG
			style.border_color = ROUTE_WRONG
		_card_buttons[i].add_theme_stylebox_override("normal", style)
		_card_buttons[i].add_theme_stylebox_override("hover", style)

	if correct:
		_score += 1
		_result_label.text = I18n.text(T_CORRECT)
		_result_label.add_theme_color_override("font_color", ROUTE_CORRECT)
	else:
		_result_label.text = I18n.text(T_WRONG)
		_result_label.add_theme_color_override("font_color", ROUTE_WRONG)

	_update_labels()
	await get_tree().create_timer(1.2).timeout
	_next_or_finish()

func _on_timeout() -> void:
	if _waiting:
		return
	_waiting = true
	_result_label.text = I18n.text(T_WRONG) + " (timeout)"
	_result_label.add_theme_color_override("font_color", ROUTE_WRONG)

	var correct_id: String = String(_current_round.get("correct", ""))
	for i: int in _card_options.size():
		if String(_card_options[i].get("id", "")) == correct_id:
			var style: StyleBoxFlat = _card_buttons[i].get_theme_stylebox("normal").duplicate()
			style.bg_color = CARD_CORRECT_BG
			style.border_color = ROUTE_CORRECT
			_card_buttons[i].add_theme_stylebox_override("normal", style)

	await get_tree().create_timer(1.2).timeout
	_next_or_finish()

func _next_or_finish() -> void:
	if _round_index >= _rounds.size():
		minigame_finished.emit(_score, _rounds.size())
	else:
		_start_round()

func _update_labels() -> void:
	_score_label.text = I18n.text(T_SCORE) + str(_score)
	_round_label.text = I18n.text(T_ROUND) + str(_round_index) + "/" + str(_rounds.size())
