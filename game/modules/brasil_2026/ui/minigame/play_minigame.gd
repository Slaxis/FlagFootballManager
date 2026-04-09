# Play recognition minigame: identify the correct play card under time pressure.
# Used for tryouts, training, and matches.
extends Control

signal minigame_finished(score: int, total: int)

const T_CALL: Dictionary = {"pt": "Corra uma rota:", "en": "Run a route:"}
const T_CORRECT: Dictionary = {"pt": "CORRETO!", "en": "CORRECT!"}
const T_WRONG: Dictionary = {"pt": "ERRADO!", "en": "WRONG!"}
const T_SCORE: Dictionary = {"pt": "Pontos: ", "en": "Score: "}
const T_ROUND: Dictionary = {"pt": "Rodada: ", "en": "Round: "}
const T_TIME: Dictionary = {"pt": "Tempo", "en": "Time"}

const FIELD_COLOR := Color(0.15, 0.35, 0.15)
const LINE_COLOR := Color(1, 1, 1, 0.3)
const PLAYER_COLOR := Color(0.2, 0.6, 1.0)
const ROUTE_CORRECT := Color(0.2, 0.85, 0.2)
const ROUTE_WRONG := Color(0.85, 0.2, 0.2)
const CARD_BG := Color(0.12, 0.12, 0.12)
const CARD_BORDER := Color(0.4, 0.4, 0.4)
const CARD_HOVER := Color(0.2, 0.2, 0.3)
const CARD_CORRECT_BG := Color(0.1, 0.25, 0.1)
const CARD_WRONG_BG := Color(0.25, 0.1, 0.1)

var _play_def: Def
var _rounds_total: int = 5
var _rounds_done: int = 0
var _score: int = 0
var _timer_seconds: float = 10.0
var _timer_remaining: float = 0.0
var _timer_active: bool = false
var _max_difficulty: int = 1
var _current_correct: Dictionary = {}
var _cards: Array[Dictionary] = []
var _card_buttons: Array[Button] = []
var _waiting: bool = false

# Field drawing
var _field_panel: Panel
var _player_dot: ColorRect
var _route_line: Line2D
var _call_label: Label
var _result_label: Label
var _score_label: Label
var _round_label: Label
var _timer_bar: ProgressBar
var _cards_container: HBoxContainer

func setup(rounds: int = 5, timer_sec: float = 10.0, max_diff: int = 1) -> void:
	_rounds_total = rounds
	_timer_seconds = timer_sec
	_max_difficulty = max_diff

func _ready() -> void:
	_play_def = Drive.def("play")
	if _play_def == null:
		Log.log(self, "error", "PlayMinigame: missing play Def.")
		return
	_build_ui()
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
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)

	# Top row: score + round
	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 24)
	_score_label = Label.new()
	_score_label.add_theme_font_size_override("font_size", 16)
	top_row.add_child(_score_label)
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)
	_round_label = Label.new()
	_round_label.add_theme_font_size_override("font_size", 16)
	top_row.add_child(_round_label)
	vbox.add_child(top_row)

	# Timer bar
	_timer_bar = ProgressBar.new()
	_timer_bar.min_value = 0
	_timer_bar.max_value = _timer_seconds
	_timer_bar.custom_minimum_size = Vector2(0, 12)
	_timer_bar.show_percentage = false
	vbox.add_child(_timer_bar)

	# Call label
	_call_label = Label.new()
	_call_label.add_theme_font_size_override("font_size", 20)
	_call_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_call_label)

	# Field
	_field_panel = Panel.new()
	_field_panel.custom_minimum_size = Vector2(0, 200)
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

	# Result label
	_result_label = Label.new()
	_result_label.add_theme_font_size_override("font_size", 18)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.text = ""
	vbox.add_child(_result_label)

	# Cards row
	_cards_container = HBoxContainer.new()
	_cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_container.add_theme_constant_override("separation", 16)
	vbox.add_child(_cards_container)

# --- Round logic ---

func _start_round() -> void:
	_rounds_done += 1
	_update_labels()
	_result_label.text = ""
	_route_line.clear_points()
	_player_dot.visible = false
	_waiting = false

	# Pick a correct play and distractors
	var routes: Array[Dictionary] = _play_def.list_routes(_max_difficulty)
	if routes.is_empty():
		return
	routes.shuffle()
	_current_correct = routes[0]
	var distractors: Array[Dictionary] = _play_def.get_random_distractors(_current_correct, 2, routes)

	_cards.clear()
	_cards.append(_current_correct)
	for d: Dictionary in distractors:
		_cards.append(d)
	_cards.shuffle()

	# Build card buttons
	for child: Node in _cards_container.get_children():
		child.queue_free()
	_card_buttons.clear()

	for card: Dictionary in _cards:
		var btn: Button = _make_card_button(card)
		btn.pressed.connect(_on_card_picked.bind(card))
		_cards_container.add_child(btn)
		_card_buttons.append(btn)

	_call_label.text = I18n.text(T_CALL) + " " + I18n.text(_current_correct.get("name", "?"))

	# Start timer
	_timer_remaining = _timer_seconds
	_timer_bar.value = _timer_remaining
	_timer_active = true

func _make_card_button(card: Dictionary) -> Button:
	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(160, 80)
	btn.add_theme_font_size_override("font_size", 14)
	btn.text = I18n.text(card.get("name", "?"))
	btn.tooltip_text = I18n.text(card.get("desc", ""))
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
	style_normal.content_margin_left = 12
	style_normal.content_margin_right = 12
	style_normal.content_margin_top = 8
	style_normal.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", style_normal)
	var style_hover: StyleBoxFlat = style_normal.duplicate()
	style_hover.bg_color = CARD_HOVER
	btn.add_theme_stylebox_override("hover", style_hover)
	return btn

func _on_card_picked(card: Dictionary) -> void:
	if _waiting:
		return
	_timer_active = false
	_waiting = true
	var correct: bool = card.get("id", "") == _current_correct.get("id", "")

	# Color the cards
	for i: int in _cards.size():
		var is_this_correct: bool = _cards[i].get("id", "") == _current_correct.get("id", "")
		var style: StyleBoxFlat = _card_buttons[i].get_theme_stylebox("normal").duplicate()
		if is_this_correct:
			style.bg_color = CARD_CORRECT_BG
			style.border_color = ROUTE_CORRECT
		elif _cards[i].get("id", "") == card.get("id", ""):
			style.bg_color = CARD_WRONG_BG
			style.border_color = ROUTE_WRONG
		_card_buttons[i].add_theme_stylebox_override("normal", style)
		_card_buttons[i].add_theme_stylebox_override("hover", style)

	if correct:
		_score += 1
		_result_label.text = I18n.text(T_CORRECT)
		_result_label.add_theme_color_override("font_color", ROUTE_CORRECT)
	else:
		_result_label.text = I18n.text(T_WRONG) + " -> " + I18n.text(_current_correct.get("name", ""))
		_result_label.add_theme_color_override("font_color", ROUTE_WRONG)

	_update_labels()
	_animate_route(_current_correct, correct)

	await get_tree().create_timer(1.5).timeout
	_next_or_finish()

func _on_timeout() -> void:
	if _waiting:
		return
	_waiting = true
	_result_label.text = I18n.text(T_WRONG) + " (timeout) -> " + I18n.text(_current_correct.get("name", ""))
	_result_label.add_theme_color_override("font_color", ROUTE_WRONG)

	# Highlight correct card
	for i: int in _cards.size():
		if _cards[i].get("id", "") == _current_correct.get("id", ""):
			var style: StyleBoxFlat = _card_buttons[i].get_theme_stylebox("normal").duplicate()
			style.bg_color = CARD_CORRECT_BG
			style.border_color = ROUTE_CORRECT
			_card_buttons[i].add_theme_stylebox_override("normal", style)

	_animate_route(_current_correct, false)

	await get_tree().create_timer(1.5).timeout
	_next_or_finish()

func _next_or_finish() -> void:
	if _rounds_done >= _rounds_total:
		minigame_finished.emit(_score, _rounds_total)
	else:
		_start_round()

# --- Route animation ---

func _animate_route(play: Dictionary, correct: bool) -> void:
	_route_line.clear_points()
	_route_line.default_color = ROUTE_CORRECT if correct else ROUTE_WRONG
	var path_raw: Variant = play.get("path", [])
	if not path_raw is Array or (path_raw as Array).is_empty():
		return
	var field_size: Vector2 = _field_panel.size
	var center_x: float = field_size.x * 0.5
	var start_y: float = field_size.y * 0.75
	var scale_factor: float = field_size.y / 100.0

	var points: Array[Vector2] = []
	for p: Variant in (path_raw as Array):
		if p is Array and (p as Array).size() >= 2:
			var px: float = center_x + float((p as Array)[0]) * scale_factor
			var py: float = start_y + float((p as Array)[1]) * scale_factor
			points.append(Vector2(px, py))

	if points.is_empty():
		return

	_player_dot.visible = true
	_player_dot.position = points[0] - Vector2(6, 6)

	for i: int in range(1, points.size()):
		_route_line.add_point(points[i - 1])
		_route_line.add_point(points[i])
		var tween: Tween = create_tween()
		tween.tween_property(_player_dot, "position", points[i] - Vector2(6, 6), 0.3)
		await tween.finished

func _update_labels() -> void:
	_score_label.text = I18n.text(T_SCORE) + str(_score)
	_round_label.text = I18n.text(T_ROUND) + str(_rounds_done) + "/" + str(_rounds_total)
