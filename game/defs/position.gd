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

var _by_id: Dictionary = {}
var _order: Array[String] = []

func load_data(raw: Dictionary) -> void:
	_by_id.clear()
	_order.clear()
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

func side(id: String) -> String:
	return String(position(id).get("side", ""))

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
func match_position(stats: Dictionary, skills: Dictionary,
		rng: RandomNumberGenerator) -> String:
	var best: String = ""
	var best_score: float = -INF
	for id: String in _order:
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
