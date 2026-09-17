# TeamGenerator — invents clubs.
#
# Clubs are not authored JSON (roadmap decision 13): in amateur flag they are
# born, they merge and they die, and a fixed list cannot model that. What the
# module ships is the ten real Rio clubs; everything below them — the
# unaffiliated sandlot sides you actually start in — is invented here.
#
# The vocabulary comes from the MODULE, not from this file, so a home-made
# universe drafts its own kind of club instead of inheriting Jacarepaguá.
# See `NameGenDef.add_thing()`.
#
# Merging and extinction are NOT here: they only happen at a season rollover,
# so they live in E.7 alongside the calendar that triggers them.
class_name TeamGenerator

const TIER_UNAFFILIATED := 4
# The município every neighbourhood in the shipped module belongs to.
const DEFAULT_CITY := "Rio de Janeiro"
# Deliberately below the weakest affiliated club (Nova Friburgo Yetis, 36).
# That gap is the step the player feels in their first match.
const REPUTATION_MIN := 12
const REPUTATION_MAX := 34

# Sandlot palettes. Each pair is authored to clear TeamColors.MIN_CONTRAST on
# its own, so generated clubs never lean on the readability repair — that
# repair exists for real clubs whose colours we do not get to choose.
const PALETTES: Array = [
	["#e8e337", "#1b1b1b"], ["#3fb960", "#101a12"], ["#e07a2a", "#1c1410"],
	["#4aa3df", "#0e1a24"], ["#e05a7a", "#1d1116"], ["#c9d1d9", "#232a31"],
	["#f0f0f0", "#7a1f2b"], ["#ffd166", "#22333b"], ["#8ecae6", "#023047"],
	["#b5e48c", "#1b3a2f"], ["#ff9f1c", "#2b2118"], ["#cdb4db", "#241a2e"],
]

# One club. Deterministic: same seed, same club.
static func invent(seed_value: int, state: String = "RJ") -> Dictionary:
	var rng: RandomNumberGenerator = SeedRng.make_rng(seed_value)
	var names := Drive.def("name_gen") as NameGenDef
	# The neighbourhood is drawn FIRST and then substituted into the name, so a
	# club called "Méier Sabiás" is actually from Méier. Letting the pattern
	# roll its own would happily place it in Deodoro.
	var city: String = names.random_neighborhood(rng) if names != null else ""
	var team_name: String = _compose_name(names, rng, city, seed_value)
	var palette: Array = PALETTES[rng.randi() % PALETTES.size()]
	return {
		"id": slug(team_name, seed_value),
		"group": "team",
		"name": team_name,
		# The bairro and the município are two different answers, and squashing
		# them into one field meant a founder could not be asked for both.
		# Everything on screen shows the neighbourhood, because at this level
		# "Méier" says far more than "Rio de Janeiro" does.
		"city": DEFAULT_CITY,
		"neighborhood": city,
		"state": state,
		"tier": TIER_UNAFFILIATED,
		"reputation": rng.randi_range(REPUTATION_MIN, REPUTATION_MAX),
		"colors": [palette[0], palette[1]],
		"squads": {"masc": true, "fem": false},
		# The league tears these down and rebuilds them when the career seed
		# changes; an authored club must never be caught in that sweep.
		"generated": true,
	}

# The Fundador's club. Rolled like any other so the fields open with something
# plausible in them, then handed to the player to overwrite — he is the only
# start that gets a vote, because he is the only one where the club did not
# exist until he said it did.
#
# Reputation sits at the FLOOR and nowhere near it by accident: a club founded
# last week has not beaten anybody. The other sandlot sides rolled theirs.
static func found(seed_value: int, name: String, neighborhood: String,
		city: String, colors: Array, state: String = "RJ") -> Dictionary:
	var club: Dictionary = invent(seed_value, state)
	var clean: String = name.strip_edges()
	if clean != "":
		club["name"] = clean
		club["id"] = slug(clean, seed_value)
	if neighborhood.strip_edges() != "":
		club["neighborhood"] = neighborhood.strip_edges()
	if city.strip_edges() != "":
		club["city"] = city.strip_edges()
	if colors.size() >= 2:
		club["colors"] = [String(colors[0]), String(colors[1])]
	club["reputation"] = REPUTATION_MIN
	club["founded_by_player"] = true
	return club

# A batch sharing one base seed. Salted sub-seeds per index, same discipline as
# ActorGenerator.squad: adding a club must not reshuffle the ones already there.
static func batch(base_seed: int, count: int, state: String = "RJ") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var used: Dictionary = {}
	for i: int in range(count):
		var team: Dictionary = invent(SeedRng.derive(base_seed, "team_%d" % i), state)
		# Two draws can land on the same name; nudge the seed until the id is
		# free so a batch never silently contains fewer clubs than requested.
		var attempt: int = 0
		while used.has(team["id"]) and attempt < 16:
			attempt += 1
			team = invent(SeedRng.derive(base_seed, "team_%d_%d" % [i, attempt]), state)
		used[team["id"]] = true
		out.append(team)
	return out

static func _compose_name(names: NameGenDef, rng: RandomNumberGenerator, city: String, seed_value: int) -> String:
	if names == null:
		return "Time %d" % seed_value
	var pattern: String = names.random_team_pattern(rng)
	if pattern == "":
		return names.random_team_name(rng)
	return names.fill_pattern(pattern.replace("{neighborhood}", city), rng)

# Public, because the creation screen has to re-derive it every time the player
# edits the name: the id is what every later screen looks the club up by, and a
# club registered under the slug of a name nobody chose is a club that exists
# under the wrong address.
static func slug(text: String, seed_value: int) -> String:
	# Not `slug`: that is this function's own name now that it is public.
	var folded: String = text.to_lower()
	for pair: Array in [["á", "a"], ["à", "a"], ["ã", "a"], ["â", "a"], ["é", "e"],
			["ê", "e"], ["í", "i"], ["ó", "o"], ["ô", "o"], ["õ", "o"], ["ú", "u"],
			["ç", "c"], ["-", " "]]:
		folded = folded.replace(String(pair[0]), String(pair[1]))
	var clean: String = ""
	for i: int in range(folded.length()):
		var ch: String = folded[i]
		clean += ch if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9") else "_"
	while clean.contains("__"):
		clean = clean.replace("__", "_")
	clean = clean.trim_prefix("_").trim_suffix("_")
	return clean if clean != "" else "time_%d" % seed_value
