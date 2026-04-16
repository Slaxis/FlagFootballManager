# Procedural generator for the 4a-div teen teams of a career.
# Given (city, state, rng) emits 4 team specs — same structure as the hand-
# authored JSON under content/things/teams/. Specs are Dictionaries so they
# round-trip safely through The.session save/load.
class_name TeenTeamGen

const STATS: Array[String] = [
	"speed", "strength", "stamina", "agility", "dexterity", "balance",
	"perception", "intelligence", "charisma",
	"throwing", "catching", "route_running", "snap", "release",
	"pass_rush", "coverage", "deflecting", "flag_pulling",
	"play_reading", "game_rules", "trash_talk"
]

# The 4 archetypes keep tryout schedule + focus + threshold fixed so the
# phone UI / calendar / tryout flow don't branch on generated vs hardcoded.
const ARCHETYPES: Array[Dictionary] = [
	{
		"key": "amateur",
		"vibe": "amateur",
		"difficulty": "easy",
		"drill_focus": ["speed", "agility", "catching"],
		"tryout_threshold": 0.45,
		"tryout_week": 1, "tryout_day": "sat", "tryout_slot": "afternoon",
		"fee_range": [0, 10],
		"budget_range": [100, 400],
		"roster_size": 3,
		"color_palettes": [
			["#cccccc", "#333333"],
			["#b0c4de", "#2f4f4f"],
			["#f5deb3", "#4b3f2f"],
			["#dcdcdc", "#1c1c1c"],
		],
		"description_pt": "Galera do bairro que joga todo fim de semana na quadra da escola. Ninguém leva muito a sério, mas aceita qualquer um que apareça. Bom pra começar — só não espera muita estrutura.",
		"description_en": "Neighborhood crew that plays every weekend on the school court. Nobody takes it too seriously, but they'll take anyone who shows up. Good to start — just don't expect structure.",
	},
	{
		"key": "disciplined",
		"vibe": "disciplined",
		"difficulty": "medium",
		"drill_focus": ["intelligence", "play_reading", "game_rules", "route_running"],
		"tryout_threshold": 0.55,
		"tryout_week": 2, "tryout_day": "tue", "tryout_slot": "afternoon",
		"fee_range": [5, 25],
		"budget_range": [500, 1200],
		"roster_size": 3,
		"color_palettes": [
			["#7a0019", "#ffcc00"],
			["#002147", "#e0e0e0"],
			["#1e3f66", "#f2c14e"],
			["#3b0a57", "#f4e285"],
		],
		"description_pt": "Time do colégio, coach é o professor de educação física. Treinos disciplinados, muita tática e leitura de jogo. Se você gosta de pensar antes de correr, é aqui.",
		"description_en": "The public school team — the coach is the PE teacher. Disciplined drills, heavy on tactics and play-reading. If you like thinking before running, this is it.",
	},
	{
		"key": "traditional",
		"vibe": "traditional",
		"difficulty": "medium",
		"drill_focus": ["balance", "dexterity", "stamina", "flag_pulling"],
		"tryout_threshold": 0.55,
		"tryout_week": 3, "tryout_day": "sat", "tryout_slot": "afternoon",
		"fee_range": [40, 100],
		"budget_range": [1500, 3000],
		"roster_size": 4,
		"color_palettes": [
			["#1b4d3e", "#e6d4a7"],
			["#1a237e", "#ffd54f"],
			["#2e2c2f", "#c0392b"],
			["#0b3d91", "#f4f4f4"],
		],
		"description_pt": "Clube tradicional de bairro, categoria de base com 15 anos de história. Treinos equilibrados, fundamentos sólidos. Respeita quem passa de 20h no sábado.",
		"description_en": "Traditional neighborhood club, 15 years of youth teams. Balanced drills, solid fundamentals. Shows respect to anyone still training after 8pm on a Saturday.",
	},
	{
		"key": "rebel",
		"vibe": "rebel",
		"difficulty": "hard",
		"drill_focus": ["speed", "strength", "agility", "trash_talk"],
		"tryout_threshold": 0.65,
		"tryout_week": 4, "tryout_day": "fri", "tryout_slot": "night",
		"fee_range": [0, 5],
		"budget_range": [100, 600],
		"roster_size": 3,
		"color_palettes": [
			["#0a0a0a", "#ff1f4f"],
			["#101010", "#39ff14"],
			["#1e1e1e", "#ff8500"],
			["#0d0d0d", "#ffd300"],
		],
		"description_pt": "Turma da quebrada que transforma flag em pista de corrida. Sem coach, sem horário fixo. Tryout é na porrada — se não tiver velocidade e atitude, nem aparece.",
		"description_en": "Outsider crew that turns flag football into a track meet. No coach, no fixed schedule. The tryout is brutal — if you don't have speed and attitude, don't bother showing up.",
	},
]

static func generate(city: String, state: String, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var name_def: Def = Drive.def("name_gen")
	var teams: Array[Dictionary] = []
	for arch: Dictionary in ARCHETYPES:
		teams.append(_gen_team(city, state, rng, name_def, arch))
	return teams

static func _gen_team(city: String, state: String, rng: RandomNumberGenerator, name_def: Def, arch: Dictionary) -> Dictionary:
	var team_name: String = name_def.call("random_team_name", rng) if name_def != null else "Time " + String(arch.get("key", "?"))
	var palettes: Array = arch.get("color_palettes", [])
	var colors: Array = palettes[rng.randi() % palettes.size()] if not palettes.is_empty() else ["#808080", "#202020"]
	var roster_size: int = int(arch.get("roster_size", 3))
	var roster: Array[Dictionary] = []
	for i in roster_size:
		roster.append(_gen_npc(rng, name_def, String(arch.get("key", ""))))
	var fee_range: Array = arch.get("fee_range", [0, 0])
	var budget_range: Array = arch.get("budget_range", [100, 500])
	return {
		"id": "teen_" + String(arch.get("key", "")) + "_" + _slugify(city) + "_" + state.to_lower(),
		"group": "team",
		"division": "4a_div",
		"age_range": "teen",
		"name": team_name,
		"city": city,
		"state": state,
		"colors": colors,
		"budget": rng.randi_range(int(budget_range[0]), int(budget_range[1])),
		"monthly_fee": rng.randi_range(int(fee_range[0]), int(fee_range[1])),
		"description": {
			"pt": String(arch.get("description_pt", "")),
			"en": String(arch.get("description_en", "")),
		},
		"vibe": String(arch.get("vibe", "")),
		"difficulty": String(arch.get("difficulty", "medium")),
		"drill_focus": arch.get("drill_focus", []),
		"tryout_threshold": float(arch.get("tryout_threshold", 0.5)),
		"tryout_week": int(arch.get("tryout_week", 0)),
		"tryout_day": String(arch.get("tryout_day", "")),
		"tryout_slot": String(arch.get("tryout_slot", "")),
		"roster": roster,
	}

static func _gen_npc(rng: RandomNumberGenerator, name_def: Def, archetype_key: String) -> Dictionary:
	var gender: String = "f" if rng.randf() < 0.2 else "m"
	var npc_name: String = name_def.call("random_full_name", gender, rng) if name_def != null else "NPC"
	var stats: Dictionary = {"name": npc_name}
	for stat: String in STATS:
		stats[stat] = _gen_stat(rng, archetype_key, stat)
	return stats

static func _gen_stat(rng: RandomNumberGenerator, archetype: String, stat_id: String) -> int:
	# Per-archetype bias. Returns 1..9 clamped.
	var lo: int = 4
	var hi: int = 6
	match archetype:
		"amateur":
			lo = 3; hi = 6
		"disciplined":
			if stat_id in ["intelligence", "play_reading", "game_rules", "route_running", "perception"]:
				lo = 6; hi = 8
			else:
				lo = 4; hi = 6
		"traditional":
			lo = 5; hi = 7
		"rebel":
			if stat_id in ["speed", "strength", "agility", "trash_talk"]:
				lo = 7; hi = 9
			elif stat_id in ["intelligence", "game_rules", "play_reading", "coverage"]:
				lo = 2; hi = 4
			else:
				lo = 4; hi = 6
	return clampi(rng.randi_range(lo, hi), 1, 9)

static func _slugify(s: String) -> String:
	var out: String = s.strip_edges().to_lower()
	# Replace common Portuguese diacritics before dropping non-ascii.
	var map: Dictionary = {
		"á":"a","à":"a","ã":"a","â":"a","ä":"a",
		"é":"e","ê":"e","è":"e","ë":"e",
		"í":"i","ì":"i","î":"i","ï":"i",
		"ó":"o","ô":"o","õ":"o","ò":"o","ö":"o",
		"ú":"u","ù":"u","û":"u","ü":"u",
		"ç":"c", "ñ":"n",
	}
	for k: String in map:
		out = out.replace(k, String(map[k]))
	var result: String = ""
	for ch in out:
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9"):
			result += ch
		elif ch == " " or ch == "-" or ch == "_":
			result += "_"
	# Collapse consecutive underscores.
	while result.contains("__"):
		result = result.replace("__", "_")
	return result.trim_prefix("_").trim_suffix("_")
