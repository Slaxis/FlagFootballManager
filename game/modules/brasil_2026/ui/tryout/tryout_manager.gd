# TryoutManager: orchestrates the full tryout flow.
# Position select → 3 physical drills → 1 position drill → results.
extends Control

signal tryout_finished(passed: bool, results: Dictionary)

const CARD_MINIGAME_SCENE := "res://game/modules/brasil_2026/ui/minigame/card_minigame.tscn"

const T_SELECT: Dictionary = {"pt": "Escolha sua posicao:", "en": "Choose your position:"}
const T_NEXT: Dictionary = {"pt": "Proximo >>", "en": "Next >>"}
const T_RESULT_PASS: Dictionary = {"pt": "APROVADO!", "en": "PASSED!"}
const T_RESULT_FAIL: Dictionary = {"pt": "REPROVADO", "en": "FAILED"}
const T_FINAL: Dictionary = {"pt": "Resultado Final", "en": "Final Result"}
const T_CLOSE: Dictionary = {"pt": "Fechar", "en": "Close"}

const COLOR_PASS := Color(0.2, 0.85, 0.2)
const COLOR_FAIL := Color(0.85, 0.2, 0.2)
const COLOR_BG := Color(0.1, 0.1, 0.1)
const COLOR_CARD_BG := Color(0.15, 0.15, 0.2)
const COLOR_CARD_HOVER := Color(0.2, 0.2, 0.3)
const COLOR_CARD_BORDER := Color(0.4, 0.4, 0.5)

const POSITIONS: Array[Dictionary] = [
	{"id": "qb",     "name": {"pt": "Quarterback (QB)", "en": "Quarterback (QB)"}, "desc": {"pt": "Leia a defesa, lance pro receiver aberto", "en": "Read the defense, throw to the open receiver"}, "drill_type": "qb_read",   "drill_name": {"pt": "Leitura de Defesa", "en": "Defensive Read"}},
	{"id": "wr",     "name": {"pt": "Wide Receiver (WR)", "en": "Wide Receiver (WR)"}, "desc": {"pt": "Corra rotas precisas, pegue a bola", "en": "Run precise routes, catch the ball"}, "drill_type": "route",     "drill_name": {"pt": "Reconhecimento de Rota", "en": "Route Recognition"}},
	{"id": "center", "name": {"pt": "Center (C)", "en": "Center (C)"}, "desc": {"pt": "Snap a bola e corra rotas curtas", "en": "Snap the ball and run short routes"}, "drill_type": "route",     "drill_name": {"pt": "Snap & Rota", "en": "Snap & Route"}},
	{"id": "db",     "name": {"pt": "Defensive Back (DB)", "en": "Defensive Back (DB)"}, "desc": {"pt": "Cubra os receivers, leia as rotas", "en": "Cover receivers, read the routes"}, "drill_type": "db_read",   "drill_name": {"pt": "Leitura de Cobertura", "en": "Coverage Read"}},
	{"id": "rusher", "name": {"pt": "Rusher (R)", "en": "Rusher (R)"}, "desc": {"pt": "Pressione o QB, leia a formacao", "en": "Pressure the QB, read the formation"}, "drill_type": "rush_read", "drill_name": {"pt": "Leitura de Rush", "en": "Rush Read"}}
]

const PHYSICAL_DRILLS: Array[Dictionary] = [
	{"drill_type": "forty",      "name": {"pt": "40-Yard Dash", "en": "40-Yard Dash"},     "timer": 4.0},
	{"drill_type": "three_cone", "name": {"pt": "Three-Cone Drill", "en": "Three-Cone Drill"}, "timer": 8.0},
	{"drill_type": "shuttle",    "name": {"pt": "Pro Agility (5-10-5)", "en": "Pro Agility (5-10-5)"}, "timer": 3.0}
]

var _config: Dictionary = {}
var _selected_position: Dictionary = {}
var _play_def: PlayDef
var _drill_results: Dictionary = {}
var _content: Control

func setup(config: Dictionary) -> void:
	_config = config

func _ready() -> void:
	_play_def = Drive.def("play") as PlayDef
	if _play_def == null:
		Log.log(self, "error", "TryoutManager: missing play Def.")
		return
	_show_position_select()

# --- Phase: Position Select ---

func _show_position_select() -> void:
	_clear_content()
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 12)
	_content = vbox
	add_child(vbox)

	var title: Label = Label.new()
	title.text = I18n.text(T_SELECT)
	title.add_theme_font_size_override("font_size", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	for pos: Dictionary in POSITIONS:
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(0, 60)
		btn.add_theme_font_size_override("font_size", 16)
		btn.text = I18n.text(pos["name"]) + "\n" + I18n.text(pos["desc"])
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = COLOR_CARD_BG
		style.border_width_bottom = 2
		style.border_color = COLOR_CARD_BORDER
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		style.content_margin_left = 12
		style.content_margin_right = 12
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		btn.add_theme_stylebox_override("normal", style)
		var hover: StyleBoxFlat = style.duplicate()
		hover.bg_color = COLOR_CARD_HOVER
		btn.add_theme_stylebox_override("hover", hover)
		btn.pressed.connect(_on_position_selected.bind(pos))
		vbox.add_child(btn)

func _on_position_selected(pos: Dictionary) -> void:
	_selected_position = pos
	_drill_results.clear()
	_run_drill_sequence()

# --- Phase: Drill Sequence ---

func _run_drill_sequence() -> void:
	var drill_rounds: int = int(_config.get("drill_rounds", 3))

	# Physical drills
	for drill: Dictionary in PHYSICAL_DRILLS:
		var drill_type: String = String(drill["drill_type"])
		var rounds: Array[Dictionary] = _play_def.get_drill_rounds(drill_type, drill_rounds)
		if rounds.is_empty():
			_drill_results[drill_type] = {"score": 0, "total": drill_rounds}
			continue
		var timer_sec: float = float(drill.get("timer", 8.0))
		var result: Dictionary = await _run_single_drill(rounds, timer_sec, drill["name"])
		_drill_results[drill_type] = result

	# Position-specific drill
	var pos_drill_type: String = String(_selected_position.get("drill_type", ""))
	var pos_rounds_count: int = int(_config.get("position_rounds", 5))
	var pos_timer: float = float(_config.get("position_timer", 10.0))
	var pos_rounds: Array[Dictionary] = []

	if pos_drill_type == "route":
		# WR / Center: use route recognition (build rounds from route plays)
		var max_diff: int = 1 if _selected_position["id"] == "center" else 2
		var routes: Array[Dictionary] = _play_def.list_routes(max_diff)
		pos_rounds = _build_route_rounds(routes, pos_rounds_count)
	else:
		pos_rounds = _play_def.get_drill_rounds(pos_drill_type, pos_rounds_count)

	if not pos_rounds.is_empty():
		var result: Dictionary = await _run_single_drill(pos_rounds, pos_timer, _selected_position["drill_name"])
		_drill_results["position"] = result
	else:
		_drill_results["position"] = {"score": 0, "total": pos_rounds_count}

	# Show results
	_show_results()

func _build_route_rounds(routes: Array[Dictionary], count: int) -> Array[Dictionary]:
	# Build card_minigame-compatible rounds from route plays (like play_minigame)
	if routes.size() < 3:
		return []
	routes.shuffle()
	var result: Array[Dictionary] = []
	for i: int in mini(count, routes.size()):
		var correct: Dictionary = routes[i]
		var distractors: Array[Dictionary] = _play_def.get_random_distractors(correct, 2, routes)
		var options: Array = []
		options.append({"id": String(correct["id"]), "path": correct.get("path", [])})
		for d: Dictionary in distractors:
			options.append({"id": String(d["id"]), "path": d.get("path", [])})
		result.append({
			"prompt": {"pt": "Corra a rota: " + I18n.text(correct.get("name", "?")), "en": "Run the route: " + I18n.text(correct.get("name", "?"))},
			"correct": String(correct["id"]),
			"card_type": "path",
			"options": options
		})
	return result

func _run_single_drill(rounds: Array[Dictionary], timer_sec: float, drill_name: Dictionary) -> Dictionary:
	_clear_content()
	var scene: PackedScene = load(CARD_MINIGAME_SCENE)
	if scene == null:
		return {"score": 0, "total": rounds.size()}
	var minigame: Control = scene.instantiate()
	minigame.setup({
		"rounds": rounds,
		"timer_sec": timer_sec,
		"drill_name": drill_name
	})
	var result: Dictionary = {"done": false, "score": 0, "total": 0}
	minigame.minigame_finished.connect(func(score: int, total: int) -> void:
		result["done"] = true
		result["score"] = score
		result["total"] = total
	)
	_content = minigame
	add_child(minigame)

	while not result["done"]:
		await get_tree().process_frame

	return {"score": int(result["score"]), "total": int(result["total"])}

# --- Phase: Results ---

func _show_results() -> void:
	_clear_content()
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	_content = vbox
	add_child(vbox)

	var title: Label = Label.new()
	title.text = I18n.text(T_FINAL)
	title.add_theme_font_size_override("font_size", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Position
	var pos_label: Label = Label.new()
	pos_label.add_theme_font_size_override("font_size", 16)
	pos_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pos_label.text = I18n.text(_selected_position.get("name", {"pt": "?", "en": "?"}))
	vbox.add_child(pos_label)

	vbox.add_child(HSeparator.new())

	# Drill scores
	var total_score: int = 0
	var total_possible: int = 0

	var drill_names: Dictionary = {
		"forty": {"pt": "40-Yard Dash", "en": "40-Yard Dash"},
		"three_cone": {"pt": "Three-Cone", "en": "Three-Cone"},
		"shuttle": {"pt": "Pro Agility", "en": "Pro Agility"},
		"position": _selected_position.get("drill_name", {"pt": "Posicao", "en": "Position"})
	}

	for drill_id: String in ["forty", "three_cone", "shuttle", "position"]:
		var dr: Dictionary = _drill_results.get(drill_id, {"score": 0, "total": 0})
		var s: int = int(dr.get("score", 0))
		var t: int = int(dr.get("total", 0))
		total_score += s
		total_possible += t
		var row: Label = Label.new()
		row.add_theme_font_size_override("font_size", 16)
		var name_text: String = I18n.text(drill_names.get(drill_id, {"pt": drill_id, "en": drill_id}))
		row.text = "  " + name_text + ": " + str(s) + "/" + str(t)
		var ratio: float = float(s) / maxf(float(t), 1.0)
		row.add_theme_color_override("font_color", COLOR_PASS if ratio >= 0.5 else COLOR_FAIL)
		vbox.add_child(row)

	vbox.add_child(HSeparator.new())

	# Total
	var threshold: float = float(_config.get("pass_threshold", 0.6))
	var passed: bool = total_possible > 0 and (float(total_score) / float(total_possible)) >= threshold

	var total_label: Label = Label.new()
	total_label.add_theme_font_size_override("font_size", 20)
	total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	total_label.text = "Total: " + str(total_score) + "/" + str(total_possible)
	vbox.add_child(total_label)

	var result_label: Label = Label.new()
	result_label.add_theme_font_size_override("font_size", 28)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if passed:
		result_label.text = I18n.text(T_RESULT_PASS)
		result_label.add_theme_color_override("font_color", COLOR_PASS)
	else:
		result_label.text = I18n.text(T_RESULT_FAIL)
		result_label.add_theme_color_override("font_color", COLOR_FAIL)
	vbox.add_child(result_label)

	# Close button
	var btn_close: Button = Button.new()
	btn_close.text = I18n.text(T_CLOSE)
	btn_close.custom_minimum_size = Vector2(0, 40)
	btn_close.pressed.connect(func() -> void:
		tryout_finished.emit(passed, {
			"position": String(_selected_position.get("id", "")),
			"drills": _drill_results,
			"total_score": total_score,
			"total_possible": total_possible,
			"passed": passed
		})
	)
	vbox.add_child(btn_close)

# --- Util ---

func _clear_content() -> void:
	if _content != null and is_instance_valid(_content):
		_content.queue_free()
		_content = null
	# Wait one frame for queue_free to process
	await get_tree().process_frame
