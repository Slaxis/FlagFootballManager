# StatDef — the two-layer attribute model.
#
#   base      the 7 attributes an actor actually owns and that training moves
#   derived   the 9 in-game stats, each the floor of the average of exactly
#             3 base attributes. Never stored on an actor — always computed.
#   overall   "Geral": floor of the average of the 7 base attributes. One
#             number for the roster list, deliberately not position-aware.
#
# Every formula lives in stat.json, so retuning the game is editing data.
# Actors carry only the 7 base values; everything else is a function of them.
extends Def
class_name StatDef

const DERIVED_INPUTS := 3

var _base: Dictionary = {}      # id -> raw base Dictionary, insertion ordered
var _derived: Dictionary = {}   # id -> raw derived Dictionary

func load_data(raw: Dictionary) -> void:
	_base.clear()
	_derived.clear()
	for entry: Variant in raw.get("base", []):
		if not entry is Dictionary:
			continue
		var id: String = _key(String((entry as Dictionary).get("id", "")))
		if id != "":
			_base[id] = entry
	for entry: Variant in raw.get("derived", []):
		if not entry is Dictionary:
			continue
		var derived: Dictionary = entry as Dictionary
		var id: String = _key(String(derived.get("id", "")))
		if id == "":
			continue
		var inputs: Array = derived.get("from", [])
		if inputs.size() != DERIVED_INPUTS:
			push_error("StatDef: derived '%s' has %d inputs, expected %d" % [id, inputs.size(), DERIVED_INPUTS])
			continue
		for input: Variant in inputs:
			if not _base.has(_key(String(input))):
				push_error("StatDef: derived '%s' reads unknown base stat '%s'" % [id, input])
				return
		_derived[id] = derived

# --- Catalogue ---

func base_ids() -> Array:
	return _base.keys()

func derived_ids() -> Array:
	return _derived.keys()

func base_stat(id: String) -> Dictionary:
	return _base.get(_key(id), {})

func derived_stat(id: String) -> Dictionary:
	return _derived.get(_key(id), {})

func has_base(id: String) -> bool:
	return _base.has(_key(id))

func has_derived(id: String) -> bool:
	return _derived.has(_key(id))

func inputs_of(derived_id: String) -> Array:
	return (_derived.get(_key(derived_id), {}) as Dictionary).get("from", [])

# --- Computation ---

# Floor of the average of the derived stat's 3 base inputs. Missing values
# count as 0 so a partially built actor degrades instead of crashing.
func derive(stats: Dictionary, derived_id: String) -> int:
	var inputs: Array = inputs_of(derived_id)
	if inputs.is_empty():
		return 0
	var total: int = 0
	for input: Variant in inputs:
		total += int(stats.get(_key(String(input)), 0))
	return int(floor(float(total) / float(inputs.size())))

func derive_all(stats: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for id: String in _derived.keys():
		out[id] = derive(stats, id)
	return out

# "Geral" — floor of the average of the 7 base attributes.
func overall(stats: Dictionary) -> int:
	if _base.is_empty():
		return 0
	var total: int = 0
	for id: String in _base.keys():
		total += int(stats.get(id, 0))
	return int(floor(float(total) / float(_base.size())))

# A blank actor sheet: every base attribute at `value`.
func blank_sheet(value: int = 0) -> Dictionary:
	var out: Dictionary = {}
	for id: String in _base.keys():
		out[id] = value
	return out
