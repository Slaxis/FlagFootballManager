# OriginDef — how you ended up in charge.
#
# The screen used to hand you a blank eighteen-year-old and drop him into a
# club full of people with ten-year careers, and there was no answer to the
# obvious question: why is the youngest man in the room the manager?
#
# So you pick. Three scenarios, the way Zomboid makes you pick a life before it
# makes you pick a stat — and each one is a different difficulty, not a
# different flavour:
#
#   founder   there was no club. You built it. Almost everyone is a rookie.
#   player    you played first. You can still play, and early on you will have
#             to — which costs you as a coach.
#   student   you never had the body, so you learned the game instead. An
#             established club took you on for exactly that.
#
# An origin does three things at once: it pre-spends part of your career points
# in its own direction, it says what KIND of club you get, and it conditions
# the squad that club fielded before you arrived.
extends Def
class_name OriginDef

var _by_id: Dictionary = {}
var _order: Array[String] = []

func load_data(raw: Dictionary) -> void:
	_by_id.clear()
	_order.clear()
	_ingest(raw.get("origins", []))

func add_thing(thing: Dictionary) -> void:
	_ingest([thing])

func _ingest(entries: Variant) -> void:
	if not entries is Array:
		return
	for entry: Variant in (entries as Array):
		if not entry is Dictionary:
			continue
		var spec: Dictionary = entry as Dictionary
		var id: String = _key(String(spec.get("id", "")))
		if id == "":
			Log.log(self, "error", "OriginDef: origin without an id")
			continue
		if not _by_id.has(id):
			_order.append(id)
		_by_id[id] = spec

# --- Reading ---

func origin_ids() -> Array[String]:
	return _order.duplicate()

func has_origin(id: String) -> bool:
	return _by_id.has(_key(id))

func origin(id: String) -> Dictionary:
	return _by_id.get(_key(id), {})

func label(id: String) -> String:
	return I18n.text(origin(id).get("label", id), id)

# The one-line pitch that goes on the chip.
func line(id: String) -> String:
	return I18n.text(origin(id).get("line", ""), "")

func desc(id: String) -> String:
	return I18n.text(origin(id).get("desc", ""), "")

# Steps, not stored points: "leadership 3" means three steps of it, which is
# what the creation screen deals in.
func sheet(id: String) -> Dictionary:
	return origin(id).get("sheet", {})

func stat_bias(id: String) -> Dictionary:
	return sheet(id).get("stats", {})

func skill_bias(id: String) -> Dictionary:
	return sheet(id).get("skills", {})

# Where on the world ladder this scenario drops you. A founder is starting a
# club in his own neighbourhood; a student was picked up by somebody who
# already had one. It is the same dial NationDef gives a club, so the manager
# is drawn against the same ruler as everybody he will manage.
func club_level(id: String) -> float:
	return float(origin(id).get("club", {}).get("level", 1.0))

# What you were doing before the clipboard, and for how long. An ex-player
# needs three years to be called one at all — a season as a rookie, a season as
# a rookie who has stopped being one, and a season actually playing — and the
# student has none, which is the entire point of him.
func career_position(id: String) -> String:
	return String(origin(id).get("career", {}).get("position", "head_coach"))

func career_years(id: String, rng: RandomNumberGenerator) -> int:
	var career: Dictionary = origin(id).get("career", {})
	return rng.randi_range(int(career.get("years_min", 0)), int(career.get("years_max", 0)))

# What a career already did to you before the screen opened. The ex-player has
# two because he has been through more — a season that went right, a shoulder
# that did not.
func perk_points(id: String) -> int:
	return int(origin(id).get("perk_points", 1))

# Whether the club exists already or you are the reason it exists.
func founds_a_club(id: String) -> bool:
	return bool(origin(id).get("club", {}).get("founded", false))

# What the squad looked like before you got there. A founded club is full of
# people who had never played; an established one is not.
func squad_rule(id: String) -> Dictionary:
	return origin(id).get("squad", {})
