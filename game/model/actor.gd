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
class_name Actor
extends Thing

const GENDER_MASC := "masc"
const GENDER_FEM := "fem"
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

func gender() -> String:
	return String(attr("gender", GENDER_MASC))

# --- Attributes ---

func stats() -> Dictionary:
	return data.get("stats", {})

func stat(id: String) -> int:
	return int(stats().get(String(id).strip_edges().to_lower(), 0))

func set_stat(id: String, value: int) -> void:
	if not data.has("stats"):
		data["stats"] = {}
	data["stats"][String(id).strip_edges().to_lower()] = value

# Derived stats are never stored — always a function of the 7 base ones.
func derived(derived_id: String) -> int:
	var def := Drive.def("stat") as StatDef
	return def.derive(stats(), derived_id) if def != null else 0

func derived_all() -> Dictionary:
	var def := Drive.def("stat") as StatDef
	return def.derive_all(stats()) if def != null else {}

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
