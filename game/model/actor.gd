# Actor — the single entity every person in the game is made of: players,
# coaches, scouts, and the manager you play as. There is no "player type" and
# no "coach type". A role is an ASSIGNMENT, not a class, which is why a tier-4
# manager can be head coach and quarterback at once while a tier-1 club has a
# different person in each chair.
#
# D5Star prefers pure-data Things with behaviour in systems, and this is a
# deliberate exception: Actor is the entity every system in the game touches,
# and stringly-typed `attr("age")` reads across that surface would rot fast.
# Behaviour stays out — derived stats come from StatDef, roles from the role
# system. What lives here is typed access and nothing else.
#
# ⚠️ Names are read with `text()`, never `attr()`: `ThingData.attr()` runs
# strings through `format_attr()`, which lowercases them. "Lucas Silva" would
# come back as "lucas silva".
#
# There is no `gender` field, deliberately. See `plays()` / `manages()`.
class_name Actor
extends Thing

const CATEGORY_MASC := "masc"
const CATEGORY_FEM := "fem"
const CATEGORY_MISTO := "misto"
const NO_TEAM := ""
const NO_JERSEY := 0

# --- Identity ---

func first_name() -> String:
	return text("first_name")

func last_name() -> String:
	return text("last_name")

# May be empty — plenty of people go by their given name.
func nickname() -> String:
	return text("nickname")

func full_name() -> String:
	return "%s %s" % [first_name(), last_name()]

# What the roster list shows: the nickname when there is one, because that is
# what everyone at the field actually calls him.
func display_name() -> String:
	var nick: String = nickname()
	return nick if nick != "" else full_name()

func age() -> int:
	return int(attr("age", 0))

func set_age(value: int) -> void:
	data["age"] = value

# --- Modalidade ---
#
# The game never asks whether someone is a man or a woman. It asks which
# category they COMPETE in and which they COACH — because "played men's,
# coached women's" is the norm in Brazilian flag, not an exception.

# Categories this actor plays in as an athlete. Empty means they do not play.
func plays() -> Array:
	return data.get("plays", [])

# Categories this actor coaches. A head coach running all three squads is a
# real case, so there is no restriction here.
func manages() -> Array:
	return data.get("manages", [])

func set_plays(categories: Array) -> void:
	data["plays"] = _sanitize_plays(categories)

func set_manages(categories: Array) -> void:
	data["manages"] = _normalize(categories)

func is_athlete() -> bool:
	return not plays().is_empty()

func is_coach() -> bool:
	return not manages().is_empty()

# You can play the men's side and the mixed side, or the women's and the mixed.
# You cannot play both the men's and the women's — that is the one hard rule.
static func plays_is_valid(categories: Array) -> bool:
	return not (categories.has(CATEGORY_MASC) and categories.has(CATEGORY_FEM))

# Drops the offending entry rather than silently accepting an impossible actor.
# `fem` wins only because something has to: the caller should validate first.
func _sanitize_plays(categories: Array) -> Array:
	var clean: Array = _normalize(categories)
	if not plays_is_valid(clean):
		Log.log(self, "error",
			"Actor '%s': plays cannot hold both masc and fem — dropping masc" % thing_id)
		clean.erase(CATEGORY_MASC)
	return clean

func _normalize(categories: Array) -> Array:
	var out: Array = []
	for entry: Variant in categories:
		var id: String = String(entry).strip_edges().to_lower()
		if id != "" and not out.has(id):
			out.append(id)
	return out

# --- Attributes ---

func stats() -> Dictionary:
	return data.get("stats", {})

func stat(id: String) -> int:
	return int(stats().get(String(id).strip_edges().to_lower(), 0))

# --- Measures ---
#
# Height and weight are not attributes: they have units and training does not
# change them. They shift attributes by whole steps instead, and the creation
# screen charges career points for the shift.

func height() -> float:
	return float(data.get("height", 0.0))

func weight() -> float:
	return float(data.get("weight", 0.0))

func measure(id: String) -> float:
	return float(data.get(String(id).strip_edges().to_lower(), 0.0))

func set_stat(id: String, value: int) -> void:
	if not data.has("stats"):
		data["stats"] = {}
	data["stats"][String(id).strip_edges().to_lower()] = value

# --- Skills ---

func skills() -> Dictionary:
	return data.get("skills", {})

func skill(id: String) -> int:
	return int(skills().get(String(id).strip_edges().to_lower(), 0))

func set_skill(id: String, value: int) -> void:
	if not data.has("skills"):
		data["skills"] = {}
	data["skills"][String(id).strip_edges().to_lower()] = value

# --- Steps: what the game actually reads ---

# An attribute in steps — what the game actually reads, body included. Height
# and weight shift whole steps, so the number on the sheet is not always the
# number that rolls.
func step(stat_id: String) -> int:
	var def := Drive.def("stat") as StatDef
	if def == null:
		return 0
	var shift: int = int(body_effect().get(String(stat_id).strip_edges().to_lower(), 0))
	return clampi(def.step(stat(stat_id)) + shift, 0, StatDef.MAX_STEP)

func skill_step(skill_id: String) -> int:
	var def := Drive.def("stat") as StatDef
	return def.step(skill(skill_id)) if def != null else 0

# What an attempt is worth before the dice: aptitude plus practice. A roll is
# this plus 2d5*, which is why a trained sandlot player can beat an untalented
# natural — and why the natural still wins more often.
func roll_base(skill_id: String) -> int:
	var def := Drive.def("stat") as StatDef
	if def == null:
		return 0
	return step(def.skill_attribute(skill_id)) + skill_step(skill_id)

# The bonus this actor passes to everyone they lead, in that attribute. Zero at
# five steps (an average adult leads nobody anywhere); negative below it.
func team_bonus(stat_id: String) -> int:
	var def := Drive.def("stat") as StatDef
	return step(stat_id) - def.average_step if def != null else 0

# Step deltas coming from height and weight.
func body_effect() -> Dictionary:
	var def := Drive.def("stat") as StatDef
	if def == null:
		return {}
	var values: Dictionary = {}
	for id: String in def.measure_ids():
		values[id] = measure(id)
	return def.body_effect(values)

# "Geral" — the one number the roster list shows.
func overall() -> int:
	var def := Drive.def("stat") as StatDef
	return def.overall(stats()) if def != null else 0


# --- Career ---

func team() -> String:
	return String(attr("team", NO_TEAM))

func set_team(team_id: String) -> void:
	data["team"] = String(team_id).strip_edges().to_lower()

# No club means standing in the Praça, waiting to be invited.
func in_praca() -> bool:
	return team() == NO_TEAM

func jersey() -> int:
	return int(attr("jersey", NO_JERSEY))

func set_jersey(number: int) -> void:
	data["jersey"] = number

# --- Perks ---

func perks() -> Array:
	return data.get("perks", [])

func has_perk(perk_id: String) -> bool:
	return perks().has(String(perk_id).strip_edges().to_lower())
