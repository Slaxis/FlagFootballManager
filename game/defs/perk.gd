# PerkDef — the one thing about an actor that is not a number.
#
# Everything else on the sheet is a step on a ladder. A perk is a sentence:
# "the ball sticks to his hands", "he disappears for three weeks and comes
# back like nothing happened". It is what makes two actors with the same
# overall play differently.
#
# Perks are PRICED IN CAREER POINTS, and the price can be negative. A flaw
# hands points back, which is the whole reason the cap exists: without a
# ceiling the optimal build is every flaw in the catalogue. With `max_per_actor`
# at one, taking a flaw is a real decision — you get one sentence, and you
# choose whether it flatters you.
#
# The `effect` block is DECLARED here and consumed by the systems that own the
# rule: `C.1-match-engine` reads `roll_bonus`, training reads
# `training_penalty`, the season reads `injury_risk`. This Def is a catalogue,
# not a rules engine — it says what a perk IS, never what happens.
extends Def
class_name PerkDef

const DEFAULT_MAX := 1
const NONE := ""

var max_per_actor: int = DEFAULT_MAX

var _perks: Dictionary = {}
var _order: Array[String] = []

func load_data(raw: Dictionary) -> void:
	_perks.clear()
	_order.clear()
	max_per_actor = int(raw.get("max_per_actor", DEFAULT_MAX))
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

# In career points. Positive is a price, negative is a refund.
func cost(id: String) -> int:
	return int(perk(id).get("cost", 0))

func label(id: String) -> String:
	return I18n.text(perk(id).get("label", id), id)

func icon(id: String) -> String:
	return String(perk(id).get("icon", ""))

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
