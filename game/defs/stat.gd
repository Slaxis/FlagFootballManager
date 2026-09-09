# StatDef — the whole sheet: what an actor is, what they can do, and how big
# their body is.
#
# THE SCALE. Everything is stored 0..100 but read in STEPS of ten, and the
# steps are what the game actually uses:
#
#     1 step   a toddler
#     5 steps  an average adult          ← the anchor, and the zero of every modifier
#    10 steps  an Olympic medal contender
#
# Storing at ten times the resolution is what lets weekly training move someone
# by three points: you feel the progress before the bar lights up. Rolls, team
# bonuses and every comparison use the step.
#
# THREE SECTIONS.
#
#   base      8 attributes. What you are.
#   measures  height and weight. NOT attributes: real units, never bars, and no
#             training makes anyone taller. They trade attributes instead —
#             taller pushes better and turns worse.
#   skills    15 of them, each governed by ONE attribute. What you learned.
#
# A skill roll is `attribute_step + skill_step + 2d5*`, so aptitude and practice
# add up. That is why there is no third "derived" layer: a derived number
# computed from attributes alone would have nowhere to put the training.
extends Def
class_name StatDef

const DEFAULT_STORED_PER_STEP := 10
const DEFAULT_AVERAGE_STEP := 5
const MAX_STEP := 10
const STORED_MIN := 0
const STORED_MAX := 100

var stored_per_step: int = DEFAULT_STORED_PER_STEP
var average_step: int = DEFAULT_AVERAGE_STEP

var _base: Dictionary = {}
var _measures: Dictionary = {}
var _skills: Dictionary = {}
var _anchors: Array = []

func load_data(raw: Dictionary) -> void:
	_base.clear()
	_measures.clear()
	_skills.clear()
	var scale: Dictionary = raw.get("scale", {})
	stored_per_step = int(scale.get("stored_per_step", DEFAULT_STORED_PER_STEP))
	average_step = int(scale.get("average_adult", DEFAULT_AVERAGE_STEP))
	_anchors = scale.get("anchors", [])
	_ingest(raw.get("base", []), _base)
	_ingest(raw.get("measures", []), _measures)
	_ingest(raw.get("skills", []), _skills, "attribute")

func _ingest(entries: Variant, into: Dictionary, required_field: String = "") -> void:
	if not entries is Array:
		return
	for entry: Variant in (entries as Array):
		if not entry is Dictionary:
			continue
		var spec: Dictionary = entry as Dictionary
		var id: String = _key(String(spec.get("id", "")))
		if id == "":
			continue
		if required_field != "" and String(spec.get(required_field, "")) == "":
			Log.log(self, "error", "StatDef: '%s' is missing '%s'" % [id, required_field])
			continue
		into[id] = spec

# --- Scale ---

# Stored value to the step the game reads. Everything above 100 clamps: 10 is
# the medal contender and there is nothing past it.
func step(stored: int) -> int:
	return clampi(int(floor(float(stored) / float(stored_per_step))), 0, MAX_STEP)

func stored_for(step_value: int) -> int:
	return clampi(step_value * stored_per_step, STORED_MIN, STORED_MAX)

# The D&D-style modifier a leader passes to the squad, and the reason the
# anchor matters: an average adult is the zero. Six steps gives +1, three
# steps gives -2 — a bad manager actively drags the club down.
func modifier(stored: int) -> int:
	return step(stored) - average_step

func anchors() -> Array:
	return _anchors

# --- Attributes ---

func base_ids() -> Array:
	return _base.keys()

func base_stat(id: String) -> Dictionary:
	return _base.get(_key(id), {})

func has_base(id: String) -> bool:
	return _base.has(_key(id))

# --- Measures ---

func measure_ids() -> Array:
	return _measures.keys()

func measure(id: String) -> Dictionary:
	return _measures.get(_key(id), {})

func has_measure(id: String) -> bool:
	return _measures.has(_key(id))

# "1,78 m" / "74 kg". Unit and precision come from the JSON, so a module could
# ship feet and pounds without a line of code. The decimal separator follows
# the language, because "1.78 m" reads wrong in Portuguese.
func format_measure(id: String, value: float) -> String:
	var spec: Dictionary = measure(id)
	if spec.is_empty():
		return str(value)
	var text: String = "%.*f" % [int(spec.get("decimals", 0)), value]
	if I18n.get_lang().begins_with("pt"):
		text = text.replace(".", ",")
	var unit: String = String(spec.get("unit", ""))
	return "%s %s" % [text, unit] if unit != "" else text

# What a body does to the attributes. Each measure declares a median, a step,
# a cap and what one step away is worth.
#
# Two rules keep this honest, and both exist because the first version broke
# them:
#
#   NO OVERLAP. Height and weight touch DIFFERENT attributes. When both fed
#   strength, a minimum-height minimum-weight build dumped -31 into the one
#   stat it did not care about and collected the credit in two it did — free
#   points for anyone willing to be small.
#
#   CAPPED AND ZERO-SUM. Each measure gives at most `cap` and takes exactly as
#   much, so an extreme body is a SHAPE, not an upgrade, and never moves an
#   attribute by more than half a step.
#
# Height trades agility for perception — the tall player sees over the line and
# turns worse. Weight trades stamina for strength.
# Which threshold band a measured value falls into, from -cap to +cap. Height
# and weight move in real units — a centimetre, a kilo — so anyone can enter
# their own body, but only crossing a band changes an attribute. Several
# centimetres therefore read the same, which is the point: 1,79 m and 1,81 m
# are the same person.
func bucket(measure_id: String, value: float) -> int:
	var spec: Dictionary = measure(measure_id)
	if spec.is_empty():
		return 0
	var size: float = float(spec.get("step", 1.0))
	if size == 0.0:
		return 0
	var cap: int = int(spec.get("cap", 5))
	return clampi(int(round((value - float(spec.get("median", 0.0))) / size)), -cap, cap)

# How much one press of a stepper moves this measure, in its own unit.
func increment(measure_id: String) -> float:
	return float(measure(measure_id).get("increment", measure(measure_id).get("step", 1.0)))

func body_effect(values: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for id: String in _measures.keys():
		var spec: Dictionary = _measures[id]
		var affects: Dictionary = spec.get("affects", {})
		if affects.is_empty():
			continue
		var magnitude: int = bucket(id, float(values.get(id, float(spec.get("median", 0.0)))))
		for stat_id: String in affects.keys():
			var key: String = _key(stat_id)
			out[key] = int(out.get(key, 0)) + magnitude * int(affects[stat_id])
	return out

# --- Skills ---

func skill_ids() -> Array:
	return _skills.keys()

func skill(id: String) -> Dictionary:
	return _skills.get(_key(id), {})

func has_skill(id: String) -> bool:
	return _skills.has(_key(id))

# The attribute that governs a skill — the aptitude half of every roll.
func skill_attribute(id: String) -> String:
	return _key(String(skill(id).get("attribute", "")))

func skill_group(id: String) -> String:
	return _key(String(skill(id).get("group", "")))

func skills_in_group(group: String) -> Array:
	var target: String = _key(group)
	var out: Array = []
	for id: String in _skills.keys():
		if skill_group(id) == target:
			out.append(id)
	return out

func skill_groups() -> Array:
	var out: Array = []
	for id: String in _skills.keys():
		var group: String = skill_group(id)
		if group != "" and not out.has(group):
			out.append(group)
	return out

# --- Sheet helpers ---

# "Geral": the mean of the 8 attributes, in stored units, floored.
func overall(stats: Dictionary) -> int:
	if _base.is_empty():
		return 0
	var total: int = 0
	for id: String in _base.keys():
		total += int(stats.get(id, 0))
	return int(floor(float(total) / float(_base.size())))

func blank_sheet(value: int = 0) -> Dictionary:
	var out: Dictionary = {}
	for id: String in _base.keys():
		out[id] = value
	return out

func blank_skills(value: int = 0) -> Dictionary:
	var out: Dictionary = {}
	for id: String in _skills.keys():
		out[id] = value
	return out
