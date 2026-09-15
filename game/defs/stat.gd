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
#             training makes anyone taller. They shift attributes by whole
#             STEPS — one per band away from the centre — and you pay career
#             points for it, because the swap is worth points.
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
# Where "notable" begins, in steps, on either side of the average adult.
const NOTABLE_HIGH := 7
const NOTABLE_LOW := 3

var stored_per_step: int = DEFAULT_STORED_PER_STEP
var average_step: int = DEFAULT_AVERAGE_STEP

var _base: Dictionary = {}
var _measures: Dictionary = {}
var _skills: Dictionary = {}
var _anchors: Array = []
var _quantiles: Array = []
var _odds_ratio: int = 4

func load_data(raw: Dictionary) -> void:
	_base.clear()
	_measures.clear()
	_skills.clear()
	var scale: Dictionary = raw.get("scale", {})
	stored_per_step = int(scale.get("stored_per_step", DEFAULT_STORED_PER_STEP))
	average_step = int(scale.get("average_adult", DEFAULT_AVERAGE_STEP))
	_anchors = scale.get("anchors", [])
	var quantiles: Dictionary = raw.get("quantiles", {})
	_quantiles = quantiles.get("bands", [])
	_odds_ratio = int(quantiles.get("odds_ratio", 4))
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
#   CAPPED AND ZERO-SUM IN STEPS. Each measure gives at most `cap` bands and
#   takes exactly as many, so an extreme body is a SHAPE. At the limit that is
#   three steps each way — enough to feel on the field.
#
# ⚠️ ZERO-SUM IN STEPS IS NOT ZERO-SUM IN CAREER POINTS. Because step costs are
# triangular, trading three cheap low steps for three dear high ones nets 27
# career points per pair, and there are two pairs — so an extreme body is worth
# 54 free points, which happens to be the entire spare budget. That is only
# actually free if the penalised attributes are ones you did not need, so
# whether it is a dominant strategy is decided by the match engine (C.1), not
# here. Registered in the roadmap as a balance watch.
#
# Height trades agility for perception — the tall player sees over the line and
# turns worse. Weight trades stamina for strength.
# How much one press of a stepper moves this measure, in its own unit.
func increment(measure_id: String) -> float:
	return float(measure(measure_id).get("increment", 1.0))

# How many bands away from the centre a measured value sits, signed and capped.
# Height and weight move in real units — a centimetre, a kilo — so anyone can
# enter their own body, but only crossing a band shifts an attribute. Several
# centimetres therefore read the same, which is the point: 1,79 m and 1,81 m
# are the same person.
func band(measure_id: String, value: float) -> int:
	var spec: Dictionary = measure(measure_id)
	if spec.is_empty():
		return 0
	var width: float = float(spec.get("band", 1.0))
	if width == 0.0:
		return 0
	var cap: int = int(spec.get("cap", 3))
	return clampi(int(round((value - float(spec.get("center", 0.0))) / width)), -cap, cap)

# What the body does to the attributes, in whole STEPS. Height trades agility
# for perception — the tall player sees over the line and turns worse. Weight
# trades stamina for strength.
#
# The two measures touch DIFFERENT attributes on purpose: when both fed
# strength, a small light build dumped the stat it did not need and collected
# the credit in two it did.
func body_effect(values: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for id: String in _measures.keys():
		var affects: Dictionary = _measures[id].get("affects", {})
		if affects.is_empty():
			continue
		var bands: int = band(id, float(values.get(id, float(_measures[id].get("center", 0.0)))))
		for stat_id: String in affects.keys():
			var key: String = _key(stat_id)
			out[key] = int(out.get(key, 0)) + bands * int(affects[stat_id])
	return out

# What a body is WORTH, in points of the attribute kind — which is what makes
# charging for it fair.
#
# Moving one band gives one stat a step and takes a step from another. Starting
# from the average adult that is `+1 costs 6, -1 refunds 5`, so the swap is
# worth 1 point. The next band swaps 7 against 4 and is worth 3; the third
# swaps 8 against 3 and is worth 5. The running total for n bands is n².
#
# So being taller than average is an advantage AND being shorter than average
# is an advantage: in both directions the step you gain is dearer than the one
# you give up. Both get billed.
func body_value(values: Dictionary) -> int:
	var total: int = 0
	for id: String in _measures.keys():
		if (_measures[id].get("affects", {}) as Dictionary).is_empty():
			continue
		var bands: int = absi(band(id, float(values.get(id, float(_measures[id].get("center", 0.0))))))
		total += bands * bands
	return total

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

# --- What somebody is known for ---
#
# Which of the twenty-three numbers on a sheet are worth mentioning. The
# nickname generator reads this: "Foguete" only means something if the guy is
# actually fast, and calling an average adult anything at all is what makes a
# generated squad read as filler.
#
# Both arguments are in STEPS, not stored units — the scale the game reads.
# Returns [{stat, dir}, ...] ordered by distance from the average adult, most
# extreme first, so the caller can weight toward the thing people notice.
func notable_traits(stat_steps: Dictionary, skill_steps: Dictionary = {}) -> Array:
	var found: Array = []
	for id: String in stat_steps.keys():
		var value: int = int(stat_steps[id])
		if value >= NOTABLE_HIGH:
			found.append({"stat": id, "dir": "high", "distance": value - average_step})
		elif value <= NOTABLE_LOW:
			found.append({"stat": id, "dir": "low", "distance": average_step - value})
	# Skills count only upward. Everybody is born with all eight attributes, so
	# a low one is a real deficit - but nobody is born knowing how to cover a
	# receiver, and an amateur has a dozen skills at zero simply because he
	# never trained them. Reading those as flaws would get every generated
	# player mocked for something that was never a failing.
	for id: String in skill_steps.keys():
		var trained: int = int(skill_steps[id])
		if trained >= NOTABLE_HIGH:
			found.append({"stat": id, "dir": "high", "distance": trained - average_step})
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["distance"]) > int(b["distance"]))
	return found


# --- The quantile ladder ---
#
# The ruler is ABSOLUTE: 10 is the best there is, on Earth. So a number needs a
# second reading that says which league that number belongs to, and the five
# bands are it:
#
#   Q1  city level      plays well on the neighbourhood sandlot
#   Q2  state level     shows up at the state championship
#   Q3  national        the Brazil squad IS this
#   Q4  world, minor    faces Mexico and the USA and holds up
#   Q5  world, major    an IFAF star; all of Brazil might have three
#
# Adjacent bands sit at the declared odds ratio — 4:1, so 80/20 — which is what
# makes Q5 vanishingly rare instead of merely uncommon. Reading a roster
# against this is how "a 26-year-old at a Piedade club with international-level
# coaching" becomes a visible mistake rather than just a big number.
func quantile_count() -> int:
	return _quantiles.size()

func odds_ratio() -> int:
	return _odds_ratio

# 1-based, so quantile_of(72) is 3.
func quantile_of(stored: int) -> int:
	for i: int in range(_quantiles.size()):
		if stored < int((_quantiles[i] as Dictionary).get("max", StatDef.STORED_MAX)):
			return i + 1
	return maxi(_quantiles.size(), 1)

func quantile_band(quantile: int) -> Dictionary:
	var index: int = clampi(quantile, 1, maxi(_quantiles.size(), 1)) - 1
	return _quantiles[index] if index < _quantiles.size() else {}

func quantile_label(quantile: int) -> String:
	var band: Dictionary = quantile_band(quantile)
	return I18n.text(band.get("label", ""), "Q%d" % quantile)

# A value drawn inside a band, so "Q2" becomes an actual number.
func quantile_value(quantile: int, rng: RandomNumberGenerator) -> int:
	var band: Dictionary = quantile_band(quantile)
	if band.is_empty():
		return 50
	return rng.randi_range(int(band.get("min", 30)), int(band.get("max", 55)))
