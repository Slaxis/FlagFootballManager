# PerkDef — the one thing about an actor that is not a number.
#
# Everything else on the sheet is a step on a ladder. A perk is a sentence:
# "the ball sticks to his hands", "he disappears for three weeks and comes
# back like nothing happened". It is what makes two actors with the same
# overall play differently.
#
# PERKS HAVE THEIR OWN CURRENCY, and it is not career points. Career points are
# training — weeks in the gym, seasons on the field. A perk is not something
# you train into; it is what a career DID to you, so it is paid for out of perk
# points, earned at the big moments rather than accumulated by the week.
#
# Which also frees the Zomboid trade: take as many as you like, and a flaw pays
# for a talent. Somebody can be Mãos de pedra AND Capitão AND Vidraça, and that
# person is a real person. The old rule of one existed only because flaws
# refunded career points and the optimal build was the whole flaw list; on a
# separate ruler the budget does that job by itself.
#
# The `effect` block is DECLARED here and consumed by the systems that own the
# rule: `C.1-match-engine` reads `roll_bonus`, training reads
# `training_penalty`, the season reads `injury_risk`. This Def is a catalogue,
# not a rules engine — it says what a perk IS, never what happens.
extends Def
class_name PerkDef

const NONE := ""

var _perks: Dictionary = {}
var _order: Array[String] = []

func load_data(raw: Dictionary) -> void:
	_perks.clear()
	_order.clear()
	_ingest(raw.get("perks", []))

# A module may bring its own perks — a regional league with its own folklore —
# the same way it brings its own club names.
func add_thing(thing: Dictionary) -> void:
	_ingest([thing])

func _ingest(entries: Variant) -> void:
	if not entries is Array:
		return
	for entry: Variant in (entries as Array):
		if not entry is Dictionary:
			continue
		var spec: Dictionary = entry as Dictionary
		var id: String = String(spec.get("id", "")).strip_edges().to_lower()
		if id == "":
			Log.log(self, "error", "PerkDef: perk without an id")
			continue
		if not _perks.has(id):
			_order.append(id)
		_perks[id] = spec

# --- Reading ---

func perk_ids() -> Array[String]:
	return _order.duplicate()

func has_perk(id: String) -> bool:
	return _perks.has(_key(id))

func perk(id: String) -> Dictionary:
	return _perks.get(_key(id), {})

# In PERK POINTS. Positive is a price, negative is what a flaw pays you.
func cost(id: String) -> int:
	return int(perk(id).get("cost", 0))

func label(id: String) -> String:
	return I18n.text(perk(id).get("label", id), id)

func icon(id: String) -> String:
	return String(perk(id).get("icon", ""))

# Code, name and description as one block — the shape a tooltip wants, and the
# same contract as `StatDef.explain()`: the screen shows three letters, the
# tooltip carries everything those three letters stand for.
func explain(id: String) -> String:
	return "%s · %s

%s" % [icon(id), label(id), desc(id)]

func desc(id: String) -> String:
	return I18n.text(perk(id).get("desc", ""), "")

func effect(id: String) -> Dictionary:
	return perk(id).get("effect", {})

# A flaw is simply a perk that pays you.
func is_flaw(id: String) -> bool:
	return cost(id) < 0

func boons() -> Array[String]:
	return _filter(false)

func flaws() -> Array[String]:
	return _filter(true)

func _filter(want_flaw: bool) -> Array[String]:
	var out: Array[String] = []
	for id: String in _order:
		if is_flaw(id) == want_flaw:
			out.append(id)
	return out
