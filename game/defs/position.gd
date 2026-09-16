# PositionDef — the five spots on a 5x5 flag field, and what each one makes you
# practise.
#
# Two jobs, and they are the spine of how an actor turns out:
#
#   affinity   what the position WANTS. The matcher scores a birth sheet
#              against it to answer "this kid, with this body — where does he
#              end up playing?"
#   trains     where a career year's career points go. This is why an old
#              receiver has route and catching and not much else: he spent
#              fifteen years running routes, not simulating a flat roll across
#              fifteen skills.
#
# Both are weights, not targets. A curator adding a sixth position writes one
# more entry and the matcher and the simulation pick it up untouched.
extends Def
class_name PositionDef

const DEFAULT_MINIMUM := 7
const DEFAULT_USUAL := 12

# What the competition demands of a squad sheet. There is no maximum: two
# quarterbacks is not a mistake, it is how a coach finds out which one is
# better — and most weeks the event IS the coletivo, where both of them take
# snaps.
var squad_minimum: int = DEFAULT_MINIMUM
var squad_usual: int = DEFAULT_USUAL

var _by_id: Dictionary = {}
var _order: Array[String] = []

func load_data(raw: Dictionary) -> void:
	_by_id.clear()
	_order.clear()
	var squad: Dictionary = raw.get("squad", {})
	squad_minimum = int(squad.get("minimum", DEFAULT_MINIMUM))
	squad_usual = int(squad.get("usual", DEFAULT_USUAL))
	_ingest(raw.get("positions", []))

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
			Log.log(self, "error", "PositionDef: position without an id")
			continue
		if not _by_id.has(id):
			_order.append(id)
		_by_id[id] = spec

# --- Reading ---

func position_ids() -> Array[String]:
	return _order.duplicate()

func has_position(id: String) -> bool:
	return _by_id.has(_key(id))

func position(id: String) -> Dictionary:
	return _by_id.get(_key(id), {})

func label(id: String) -> String:
	return I18n.text(position(id).get("label", id), id)

func desc(id: String) -> String:
	return I18n.text(position(id).get("desc", ""), "")

# The two or three letters that fit on a button in a roster row.
func code(id: String) -> String:
	return String(position(id).get("code", id.to_upper()))

# How many the formation starts at this position. Anybody marked past that is a
# RESERVE there, not an error.
func slots(id: String) -> int:
	return int(position(id).get("slots", 1))

func slots_on_side(wanted: String) -> int:
	var total: int = 0
	for id: String in ids_on_side(wanted):
		total += slots(id)
	return total

func side(id: String) -> String:
	return String(position(id).get("side", ""))

# The two sides somebody can actually be BORN into. Staff and admin are chairs
# a club hands out, not things a body is suited for at fifteen.
const PLAYING_SIDES: Array[String] = ["offense", "defense"]
const SIDE_STAFF := "staff"
const SIDE_ADMIN := "admin"

# Every position that puts you on the field, in formation order.
func playing_ids() -> Array[String]:
	var out: Array[String] = []
	for side_id: String in PLAYING_SIDES:
		out.append_array(ids_on_side(side_id))
	return out

func ids_on_side(wanted: String) -> Array[String]:
	var out: Array[String] = []
	for id: String in _order:
		if side(id) == wanted:
			out.append(id)
	return out

func affinity(id: String) -> Dictionary:
	return position(id).get("affinity", {})

func trains(id: String) -> Dictionary:
	return position(id).get("trains", {})

# --- Fit ---
#
# AFFINITY IS A POLARITY, NOT A WEIGHT. Each position carries a vector of
# +1 / 0 / -1 over attributes AND skills, and fit is the inner product of that
# vector with the actor's own numbers. A QB wants dexterity, intelligence and a
# rulebook; he does NOT want trash talk, so that entry is -1 and a loudmouth
# scores worse at the position no matter how well he throws.
#
# Weights would have said "throwing matters three times as much as rules",
# which is a statement about TRAINING and belongs in `trains`. Polarity answers
# a different question — does this person suit this job — and answering it with
# a sign instead of a magnitude is what makes the vector easy to author and
# easy to read: a curator adding a position decides yes / no / actively wrong,
# fifteen times, and is done.
#
# One vector does both eras of a career: at birth the skills are all zero so
# only the attributes speak, and by year ten the skills dominate. The matcher
# and B.6's role assignment can therefore ask the same function.
const MATCH_NOISE := 0.14

# Roughly -1..+1. Normalised by how many terms the position actually declares,
# so a position with ten opinions is not automatically favoured over one with
# six.
func fit(id: String, stats: Dictionary, skills: Dictionary = {}) -> float:
	var polarity: Dictionary = affinity(id)
	var total: float = 0.0
	var terms: float = 0.0
	for key: String in polarity.keys():
		var sign_value: float = float(polarity[key])
		if is_zero_approx(sign_value):
			continue
		var value: float = float(int(stats.get(key, skills.get(key, 0))))
		total += sign_value * value
		terms += absf(sign_value)
	if terms <= 0.0:
		return 0.0
	return total / (terms * float(StatDef.STORED_MAX))

# "This actor, with these numbers, would play where?"
#
# Best fit wins, with a nudge of noise: without it every quick kid becomes a
# receiver and a squad comes out with five of them and nobody to snap the ball.
#
# PLAYING SIDES ONLY, by default. NOBODY IS BORN A FITNESS COACH. Letting the
# matcher choose among all fourteen entries meant five of them were staff and a
# squad came out with more clipboards than players — and worse, it said a
# sixteen-year-old had been a scout since birth. A staff chair is a LATE-CAREER
# TRANSITION: you played, you got old, and the club still wanted you around.
# So the sides are an argument, and spawning simply never passes "staff".
func match_position(stats: Dictionary, skills: Dictionary,
		rng: RandomNumberGenerator) -> String:
	return match_on_sides(stats, skills, rng, PLAYING_SIDES)

func match_on_sides(stats: Dictionary, skills: Dictionary,
		rng: RandomNumberGenerator, sides: Array[String]) -> String:
	var best: String = ""
	var best_score: float = -INF
	for id: String in _order:
		if not sides.has(side(id)):
			continue
		var score: float = fit(id, stats, skills) + rng.randfn(0.0, MATCH_NOISE)
		if score > best_score:
			best_score = score
			best = id
	return best

# Every position ranked for this actor, best first — what B.6 needs to show
# "he could also play here, slightly worse".
func ranked_fits(stats: Dictionary, skills: Dictionary = {}) -> Array:
	var out: Array = []
	for id: String in _order:
		out.append({"position": id, "fit": fit(id, stats, skills)})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["fit"]) > float(b["fit"]))
	return out
