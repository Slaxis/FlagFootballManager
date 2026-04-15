# Drill minigame: technique card-based drill with d5*, yomi, hand management.
# Each drill is a sequence of situations. Player draws cards and plays them to pass checks.
extends Control

signal minigame_finished(score: int, total: int)

# Personality colors
const PERS_COLORS: Dictionary = {
	"intenso": Color(0.8, 0.2, 0.2),
	"tecnico": Color(0.2, 0.5, 1.0),
	"estrategico": Color(0.2, 0.75, 0.3),
}
const PERS_LABELS: Dictionary = {
	"intenso": "INT",
	"tecnico": "TEC",
	"estrategico": "EST",
}
# Yomi: key beats value
const YOMI_BEATS: Dictionary = {
	"intenso": "estrategico",
	"estrategico": "tecnico",
	"tecnico": "intenso",
}

const COLOR_PASS := Color(0.2, 0.85, 0.2)
const COLOR_FAIL := Color(0.85, 0.2, 0.2)
const COLOR_BG := Color(0.1, 0.1, 0.14)
const COLOR_CARD_BG := Color(0.12, 0.12, 0.16)
const COLOR_CARD_BORDER := Color(0.3, 0.3, 0.35)
const COLOR_SYNERGY := Color(1.0, 0.85, 0.2)
const COLOR_DIM := Color(0.5, 0.5, 0.5)

var _drill_def: Def
var _tech_def: Def
var _drill: Dictionary = {}
var _situations: Array[Dictionary] = []
var _current_idx: int = 0
var _score: int = 0
var _timer_seconds: float = 5.0
var _timer_remaining: float = 0.0
var _timer_active: bool = false
var _waiting: bool = false

# Deck / Hand
var _deck_pool: Array[String] = []  # shuffled card IDs available to draw
var _graveyard: Array[String] = []  # played card IDs
var _hand: Array[Dictionary] = []   # current hand (resolved card dicts)
var _hand_size: int = 3
var _draw_interval: int = 3
var _tick: int = 0

# Cards selected this situation
var _selected_cards: Array[Dictionary] = []

# UI refs
var _title_label: Label
var _score_label: Label
var _round_label: Label
var _timer_bar: ProgressBar
var _prompt_label: Label
var _check_label: Label
var _other_box: VBoxContainer
var _result_label: Label
var _table_container: HBoxContainer
var _hand_container: HBoxContainer
var _hand_buttons: Array[Button] = []

func setup(config: Dictionary) -> void:
	var drill_id: String = String(config.get("drill_id", ""))
	_drill_def = Drive.def("drill")
	_tech_def = Drive.def("technique")
	if _drill_def == null or _tech_def == null:
		return
	_drill = _drill_def.get_drill(drill_id)
	_situations = _drill_def.get_situations(drill_id)
	_timer_seconds = float(_drill.get("timer_per_situation", 5.0))
	# Build deck from player's technique_deck, filtered by context "drill"
	var player_deck: Array = The.session.get("technique_deck", []) as Array
	_deck_pool.clear()
	# Deck pool = memory cards (non-common). Commons come from tag match each situation.
	for cid: Variant in player_deck:
		var tech: Dictionary = _tech_def.get_technique(String(cid))
		if tech.is_empty():
			continue
		if String(tech.get("rarity", "common")) == "common":
			continue
		var contexts: Variant = tech.get("valid_contexts", [])
		if contexts is Array and (contexts as Array).has("drill"):
			_deck_pool.append(String(cid))
	_deck_pool.shuffle()
	# Hand size from intelligence
	var intelligence: int = int(The.session.get("player_stats", {}).get("intelligence", 5))
	_hand_size = clampi(intelligence / 20, 1, 5)
	# Draw interval
	if intelligence >= 81:
		_draw_interval = 0  # 2 per tick handled specially
	elif intelligence >= 56:
		_draw_interval = 2
	elif intelligence >= 36:
		_draw_interval = 3
	elif intelligence >= 16:
		_draw_interval = 4
	else:
		_draw_interval = 5

func _ready() -> void:
	if _situations.is_empty():
		return
	_build_ui()
	_draw_cards(1)  # start with 1 card
	_start_situation()

func _process(delta: float) -> void:
	if _timer_active:
		_timer_remaining -= delta
		_timer_bar.value = _timer_remaining
		if _timer_remaining <= 0:
			_timer_active = false
			_on_timeout()

# --- d5* Dice ---

func _roll_d5star() -> int:
	var face: int = randi_range(0, 5)
	if face == 5:
		return 5 + _roll_d5star()
	elif face == 0:
		return 0 - _roll_d5star()
	return face

func _roll_2d5star(vital_level: int) -> int:
	if vital_level > 50:
		# Normal: 2d5*, sum
		return _roll_d5star() + _roll_d5star()
	elif vital_level > 25:
		# Tired: 1d5* only
		return _roll_d5star()
	else:
		# Exhausted: 2d5*, take worst
		var a: int = _roll_d5star()
		var b: int = _roll_d5star()
		return mini(a, b)

func _get_vital_level_for_costs(cards: Array[Dictionary]) -> int:
	# Find the worst vital level among all costs
	var worst: int = 100
	var vitals: Dictionary = The.session.get("vitals", {})
	for card: Dictionary in cards:
		var costs: Dictionary = card.get("vital_cost", {})
		for vid: String in costs:
			var current: int = int(vitals.get(vid, 100))
			worst = mini(worst, current)
	if cards.is_empty():
		# SKIP: use average of all vitals
		var total: int = 0
		var count: int = 0
		for vid: String in vitals:
			total += int(vitals[vid])
			count += 1
		worst = total / maxi(count, 1)
	return worst

# --- Yomi ---

func _yomi_bonus(card_pers: String, situation_pers: String) -> int:
	if card_pers == situation_pers:
		return 0
	if YOMI_BEATS.get(card_pers, "") == situation_pers:
		return 2
	return -1

# --- UI ---

func _build_ui() -> void:
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)
	add_child(vbox)

	# Top bar
	var top: HBoxContainer = HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	vbox.add_child(top)
	_title_label = Label.new()
	_title_label.text = I18n.text(_drill.get("name", "Drill"))
	_title_label.add_theme_font_size_override("font_size", 16)
	top.add_child(_title_label)
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	_score_label = Label.new()
	_score_label.add_theme_font_size_override("font_size", 14)
	top.add_child(_score_label)
	_round_label = Label.new()
	_round_label.add_theme_font_size_override("font_size", 14)
	top.add_child(_round_label)

	# Timer
	_timer_bar = ProgressBar.new()
	_timer_bar.custom_minimum_size = Vector2(0, 10)
	_timer_bar.max_value = _timer_seconds
	_timer_bar.show_percentage = false
	vbox.add_child(_timer_bar)

	# Sprites row (player | other) — NEO Scavenger style
	var sprites_row: HBoxContainer = HBoxContainer.new()
	sprites_row.alignment = BoxContainer.ALIGNMENT_CENTER
	sprites_row.add_theme_constant_override("separation", 40)
	sprites_row.custom_minimum_size = Vector2(0, 90)
	vbox.add_child(sprites_row)

	var player_box: VBoxContainer = VBoxContainer.new()
	player_box.alignment = BoxContainer.ALIGNMENT_CENTER
	var player_sprite: Panel = Panel.new()
	player_sprite.custom_minimum_size = Vector2(56, 72)
	var ps_style: StyleBoxFlat = StyleBoxFlat.new()
	ps_style.bg_color = Color(0.2, 0.4, 0.7)
	ps_style.corner_radius_top_left = 4
	ps_style.corner_radius_top_right = 4
	ps_style.corner_radius_bottom_left = 4
	ps_style.corner_radius_bottom_right = 4
	player_sprite.add_theme_stylebox_override("panel", ps_style)
	player_box.add_child(player_sprite)
	var player_name: Label = Label.new()
	player_name.text = String(The.session.get("player_name", "Player"))
	player_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_name.add_theme_font_size_override("font_size", 11)
	player_box.add_child(player_name)
	sprites_row.add_child(player_box)

	_other_box = VBoxContainer.new()
	_other_box.alignment = BoxContainer.ALIGNMENT_CENTER
	sprites_row.add_child(_other_box)

	# Narrative prompt
	_prompt_label = Label.new()
	_prompt_label.add_theme_font_size_override("font_size", 16)
	_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_prompt_label)

	_check_label = Label.new()
	_check_label.add_theme_font_size_override("font_size", 11)
	_check_label.add_theme_color_override("font_color", COLOR_DIM)
	_check_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_check_label)

	# Result
	_result_label = Label.new()
	_result_label.add_theme_font_size_override("font_size", 14)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_result_label)

	# Table (played cards)
	var table_header: Label = Label.new()
	table_header.text = I18n.text({"pt": "MESA", "en": "TABLE"})
	table_header.add_theme_font_size_override("font_size", 10)
	table_header.add_theme_color_override("font_color", COLOR_DIM)
	vbox.add_child(table_header)

	_table_container = HBoxContainer.new()
	_table_container.add_theme_constant_override("separation", 4)
	_table_container.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(_table_container)

	# Hand
	_hand_container = HBoxContainer.new()
	_hand_container.add_theme_constant_override("separation", 6)
	vbox.add_child(_hand_container)

# --- Draw cards ---

func _render_other_sprite(sit: Dictionary) -> void:
	for child: Node in _other_box.get_children():
		child.queue_free()
	var other: Variant = sit.get("other", null)
	if not (other is Dictionary):
		return
	var other_dict: Dictionary = other as Dictionary
	var color: Color = Color(0.5, 0.2, 0.2)
	if other_dict.has("color"):
		color = Color.from_string(String(other_dict["color"]), color)
	var sprite: Panel = Panel.new()
	sprite.custom_minimum_size = Vector2(56, 72)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	sprite.add_theme_stylebox_override("panel", style)
	_other_box.add_child(sprite)
	var name_label: Label = Label.new()
	name_label.text = I18n.text(other_dict.get("name", "?"))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 11)
	_other_box.add_child(name_label)

func _draw_cards(count: int) -> void:
	for i: int in count:
		if _hand.size() >= _hand_size:
			break
		if _deck_pool.is_empty():
			break
		var cid: String = _deck_pool.pop_back()
		var tech: Dictionary = _tech_def.get_technique(cid)
		if not tech.is_empty():
			_hand.append(tech)

func _tick_draw() -> void:
	_tick += 1
	var intelligence: int = int(The.session.get("player_stats", {}).get("intelligence", 5))
	if intelligence >= 81:
		_draw_cards(2)
	elif _draw_interval > 0 and _tick % _draw_interval == 0:
		_draw_cards(1)

# --- Situation flow ---

func _start_situation() -> void:
	_selected_cards.clear()
	_waiting = false
	_result_label.text = ""
	_update_labels()
	_clear_table()

	var sit: Dictionary = _situations[_current_idx]
	_prompt_label.text = I18n.text(sit.get("prompt", ""))
	_render_other_sprite(sit)
	var stats: Array = sit.get("check_stats", []) as Array
	var diff: int = int(sit.get("difficulty", 10))
	var pers: String = String(sit.get("personality", ""))
	var pers_label: String = PERS_LABELS.get(pers, "?")
	_check_label.text = "/".join(PackedStringArray(stats)).to_upper() + " >= " + str(diff) + "  [" + pers_label + "]"
	if PERS_COLORS.has(pers):
		_check_label.add_theme_color_override("font_color", PERS_COLORS[pers])

	# Remove any leftover commons from previous situation
	var clean_hand: Array[Dictionary] = []
	for c: Dictionary in _hand:
		if String(c.get("rarity", "common")) != "common":
			clean_hand.append(c)
	_hand = clean_hand

	# Add matching commons for this situation (always available)
	var sit_tags: Array = sit.get("situation_tags", []) as Array
	for tech: Dictionary in _tech_def.list_all():
		if String(tech.get("rarity", "common")) != "common":
			continue
		if String(tech.get("card_type", "")) != "":
			continue
		var contexts: Variant = tech.get("valid_contexts", [])
		if not (contexts is Array and (contexts as Array).has("drill")):
			continue
		var tech_tags: Array = tech.get("situation_tags", []) as Array
		var found: bool = false
		for t: Variant in tech_tags:
			if sit_tags.has(t):
				found = true
				break
		if found and not _hand.has(tech):
			_hand.append(tech)

	_render_hand()
	_timer_remaining = _timer_seconds
	_timer_bar.value = _timer_remaining
	_timer_active = true

func _render_hand() -> void:
	for child: Node in _hand_container.get_children():
		child.queue_free()
	_hand_buttons.clear()

	for i: int in _hand.size():
		var card: Dictionary = _hand[i]
		var btn: Button = _make_card_button(card, i + 1)
		btn.pressed.connect(_on_card_toggled.bind(i))
		_hand_container.add_child(btn)
		_hand_buttons.append(btn)

	# Confirm / Skip buttons
	var confirm_btn: Button = Button.new()
	confirm_btn.text = I18n.text({"pt": "JOGAR", "en": "PLAY"})
	confirm_btn.custom_minimum_size = Vector2(60, 0)
	confirm_btn.pressed.connect(_on_confirm)
	_hand_container.add_child(confirm_btn)

	var skip_btn: Button = Button.new()
	skip_btn.text = "[S] SKIP"
	skip_btn.custom_minimum_size = Vector2(60, 0)
	skip_btn.pressed.connect(_on_skip)
	_hand_container.add_child(skip_btn)

func _make_card_button(card: Dictionary, hotkey: int) -> Button:
	var btn: Button = Button.new()
	btn.toggle_mode = true
	btn.custom_minimum_size = Vector2(110, 70)
	var pers: String = String(card.get("personality", ""))
	var pers_color: Color = PERS_COLORS.get(pers, Color.WHITE)
	var pers_lbl: String = PERS_LABELS.get(pers, "?")
	var coins: int = int(card.get("coins", 1))
	var name_text: String = I18n.text(card.get("name", "?"))
	# Build bonus text
	var bonus_parts: Array[String] = []
	var stat_bonus: Dictionary = card.get("stat_bonus", {})
	for sid: String in stat_bonus:
		bonus_parts.append("+" + str(int(stat_bonus[sid])) + " " + sid.to_upper().substr(0, 3))
	var bonus_text: String = " ".join(bonus_parts) if not bonus_parts.is_empty() else ""
	# Check synergy with current situation
	var sit: Dictionary = _situations[_current_idx] if _current_idx < _situations.size() else {}
	var sit_tags: Array = sit.get("situation_tags", []) as Array
	var card_tags: Array = card.get("situation_tags", []) as Array
	var has_synergy: bool = false
	for t: Variant in card_tags:
		if sit_tags.has(t):
			has_synergy = true
			break
	# Check yomi
	var sit_pers: String = String(sit.get("personality", ""))
	var yomi: int = _yomi_bonus(pers, sit_pers)
	# Build label
	var lines: String = "[" + str(hotkey) + "] " + name_text + "\n"
	lines += pers_lbl + " " + str(coins) + " coin\n"
	lines += bonus_text
	if has_synergy:
		lines += "\nSYNERGY!"
	if yomi > 0:
		lines += "\nYOMI +" + str(yomi)
	elif yomi < 0:
		lines += "\nyomi " + str(yomi)
	btn.text = lines
	# Style
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = COLOR_CARD_BG
	style.border_width_left = 4
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = pers_color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", style)
	var hover: StyleBoxFlat = style.duplicate()
	hover.bg_color = Color(0.18, 0.18, 0.25)
	btn.add_theme_stylebox_override("hover", hover)
	var pressed: StyleBoxFlat = style.duplicate()
	pressed.bg_color = Color(0.15, 0.25, 0.15)
	pressed.border_color = COLOR_SYNERGY
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_font_size_override("font_size", 10)
	return btn

# --- Input ---

func _unhandled_key_input(event: InputEvent) -> void:
	if _waiting or not event is InputEventKey or not (event as InputEventKey).pressed:
		return
	var key: InputEventKey = event as InputEventKey
	match key.keycode:
		KEY_1:
			_toggle_card(0)
		KEY_2:
			_toggle_card(1)
		KEY_3:
			_toggle_card(2)
		KEY_4:
			_toggle_card(3)
		KEY_5:
			_toggle_card(4)
		KEY_S:
			_on_skip()
		KEY_ENTER, KEY_SPACE:
			_on_confirm()

func _toggle_card(idx: int) -> void:
	if idx >= _hand_buttons.size():
		return
	_hand_buttons[idx].button_pressed = not _hand_buttons[idx].button_pressed
	_on_card_toggled(idx)

func _on_card_toggled(idx: int) -> void:
	if idx >= _hand.size():
		return
	var card: Dictionary = _hand[idx]
	if _hand_buttons[idx].button_pressed:
		if not _selected_cards.has(card):
			_selected_cards.append(card)
			Audio.play_sfx("card_pick")
	else:
		_selected_cards.erase(card)

func _on_confirm() -> void:
	if _waiting:
		return
	_timer_active = false
	_waiting = true
	_resolve(_selected_cards)

func _on_skip() -> void:
	if _waiting:
		return
	_timer_active = false
	_waiting = true
	_selected_cards.clear()
	_resolve([])

func _on_timeout() -> void:
	if _waiting:
		return
	_waiting = true
	_selected_cards.clear()
	_resolve([])

# --- Resolution ---

func _resolve(cards_played: Array) -> void:
	var sit: Dictionary = _situations[_current_idx]
	var check_stats: Array = sit.get("check_stats", []) as Array
	var difficulty: int = int(sit.get("difficulty", 10))
	var sit_pers: String = String(sit.get("personality", ""))
	var sit_tags: Array = sit.get("situation_tags", []) as Array
	var player_stats: Dictionary = The.session.get("player_stats", {})
	var vitals: Dictionary = The.session.get("vitals", {})

	# Best relevant stat
	var best_stat: int = 0
	for sid: Variant in check_stats:
		var val: int = int(player_stats.get(String(sid), 5))
		best_stat = maxi(best_stat, val)

	# Pay costs and calculate bonuses
	var total_bonus: int = 0
	var total_synergy: int = 0
	var total_yomi: int = 0
	var typed_cards: Array[Dictionary] = []
	for card: Variant in cards_played:
		if card is Dictionary:
			typed_cards.append(card as Dictionary)

	for card: Dictionary in typed_cards:
		# Pay vital costs
		var costs: Dictionary = card.get("vital_cost", {})
		for vid: String in costs:
			var current: int = int(vitals.get(vid, 0))
			vitals[vid] = maxi(current + int(costs[vid]), 0)
		# Stat bonus (only for matching check stats)
		var stat_bonus: Dictionary = card.get("stat_bonus", {})
		for sid: String in stat_bonus:
			if check_stats.has(sid):
				total_bonus += int(stat_bonus[sid])
		# Synergy
		var card_tags: Array = card.get("situation_tags", []) as Array
		for t: Variant in card_tags:
			if sit_tags.has(t):
				total_synergy += 1
				break
		# Yomi
		var card_pers: String = String(card.get("personality", ""))
		total_yomi += _yomi_bonus(card_pers, sit_pers)

	The.session["vitals"] = vitals

	# Dice roll
	var vital_level: int = _get_vital_level_for_costs(typed_cards)
	var dice: int = _roll_2d5star(vital_level)

	var effective: int = best_stat + total_bonus + total_synergy + total_yomi + dice
	var passed: bool = effective >= difficulty

	Audio.play_sfx("pass" if passed else "fail")
	if passed:
		_score += 1

	# Remove played cards from hand. Commons are re-added on next situation via tags;
	# memory cards go to graveyard (consumed from deck).
	for card: Dictionary in typed_cards:
		var cid: String = String(card.get("id", ""))
		var is_common: bool = String(card.get("rarity", "common")) == "common"
		if not is_common:
			_graveyard.append(cid)
		_hand.erase(card)

	# Show on table
	_show_table(typed_cards)

	# Result display
	var result_parts: Array[String] = []
	result_parts.append(str(best_stat) + " stat")
	if total_bonus > 0:
		result_parts.append("+" + str(total_bonus) + " card")
	if total_synergy > 0:
		result_parts.append("+" + str(total_synergy) + " syn")
	if total_yomi != 0:
		var yomi_pfx: String = "+" if total_yomi > 0 else ""
		result_parts.append(yomi_pfx + str(total_yomi) + " yomi")
	result_parts.append("+" + str(dice) + " d5*")
	result_parts.append("= " + str(effective) + " vs " + str(difficulty))

	if passed:
		_result_label.text = "PASS! (" + ", ".join(result_parts) + ")"
		_result_label.add_theme_color_override("font_color", COLOR_PASS)
	else:
		_result_label.text = "FAIL (" + ", ".join(result_parts) + ")"
		_result_label.add_theme_color_override("font_color", COLOR_FAIL)

	_update_labels()

	# Animate (no-op for now, placeholder for future sprite reactions)
	_animate_viewport(sit.get("viewport_action", {}), passed)
	await get_tree().create_timer(1.5).timeout

	_next_or_finish()

func _next_or_finish() -> void:
	_current_idx += 1
	if _current_idx >= _situations.size():
		minigame_finished.emit(_score, _situations.size())
	else:
		_tick_draw()
		_start_situation()

# --- Table ---

func _clear_table() -> void:
	for child: Node in _table_container.get_children():
		child.queue_free()

func _show_table(cards: Array[Dictionary]) -> void:
	_clear_table()
	if cards.is_empty():
		var skip_lbl: Label = Label.new()
		skip_lbl.text = "SKIP"
		skip_lbl.add_theme_font_size_override("font_size", 11)
		skip_lbl.add_theme_color_override("font_color", COLOR_DIM)
		_table_container.add_child(skip_lbl)
		return
	for card: Dictionary in cards:
		var lbl: Label = Label.new()
		var pers: String = String(card.get("personality", ""))
		lbl.text = I18n.text(card.get("name", "?"))
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", PERS_COLORS.get(pers, Color.WHITE))
		_table_container.add_child(lbl)

# --- Viewport animation (disabled — NEO Scavenger format uses sprites + narrative) ---

func _animate_viewport(_action: Dictionary, _passed: bool) -> void:
	# No-op: old field/dot viewport was replaced with sprite panels.
	# Could be used later to animate the other sprite (shake, nod, etc.)
	pass

func _update_labels() -> void:
	_score_label.text = I18n.text({"pt": "Pontos: ", "en": "Score: "}) + str(_score)
	_round_label.text = str(_current_idx + 1) + "/" + str(_situations.size())
