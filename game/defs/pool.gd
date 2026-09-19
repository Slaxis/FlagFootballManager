# PoolDef — the five bars, as a catalogue instead of as a table in the code.
#
# It was a `const Dictionary` inside `Pools` for exactly one day, which was long
# enough to notice the problem: which attributes hold a bar up, what colour it
# is and what it is called are all CONTENT, and content in a `.gd` is content a
# module cannot replace. A different sport has different bars.
#
# ⚠️ THE ORDER IS DERIVED, NOT DECLARED. The pools come out sorted by the chakra
# of the attribute that holds them up — the same head-to-foot reading the
# attribute list has, so the two blocks on a sheet scan as one. Sorting by the
# order they happen to sit in this JSON would be a second source for something
# `StatDef` already decides, and the two would drift the first time somebody
# added a pool to the end of the file.
#
# Loyalty is the exception and lands last, because it has no attribute: nothing
# about a player says how much he can care about a club he has not joined yet.
extends Def
class_name PoolDef

const LOYALTY := "loyalty"

var _pools: Dictionary = {}   # id -> raw
var _floor: int = 4
var _scale: int = 24

func load_data(raw: Dictionary) -> void:
	_pools.clear()
	_floor = int(raw.get("floor", 4))
	_scale = int(raw.get("scale", 24))
	for entry: Variant in raw.get("pools", []):
		if entry is Dictionary:
			var id: String = _key(String((entry as Dictionary).get("id", "")))
			if id != "":
				_pools[id] = entry

func add_thing(thing: Dictionary) -> void:
	var id: String = _key(String(thing.get("id", "")))
	if id != "":
		_pools[id] = thing

# --- Reading ---

func has_pool(id: String) -> bool:
	return _pools.has(_key(id))

func pool(id: String) -> Dictionary:
	return _pools.get(_key(id), {})

func floor_value() -> int:
	return _floor

# The highest any pool can reach, which is what a gauge measures against. The
# floor plus two attributes at the top of the ruler — without it the bar would
# have to normalise against the biggest pool ON SCREEN, and then the same
# player's bar would change length depending on who he was standing next to.
func scale_value() -> int:
	return _scale

# The two attributes that hold a bar up, or empty for the one that has none.
func sources(id: String) -> Array:
	var raw: Array = pool(id).get("from", [])
	var out: Array = []
	for entry: Variant in raw:
		out.append(_key(String(entry)))
	return out

func color(id: String) -> Color:
	return Color.from_string(String(pool(id).get("color", "#FFFFFF")), Color.WHITE)

func code(id: String) -> String:
	return I18n.text(pool(id).get("code", ""), label(id))

func label(id: String) -> String:
	return I18n.text(pool(id).get("label", id), id)

func desc(id: String) -> String:
	return I18n.text(pool(id).get("desc", ""), "")

# Name and description as one block, the shape a tooltip wants — the same
# contract StatDef and PerkDef keep.
func explain(id: String) -> String:
	return "%s\n\n%s" % [label(id), desc(id)]

# --- Loyalty's own numbers ---

func ceiling_value(id: String) -> int:
	return int(pool(id).get("ceiling", 0))

func founder_bonus(id: String) -> int:
	return int(pool(id).get("founder_bonus", 0))

func per_level(id: String) -> int:
	return int(pool(id).get("per_level", 0))

# --- Order ---

# Head to foot, by the chakra of the attribute each bar hangs from. The pair is
# the key rather than just the first one, so two bars sharing a source (health
# and stamina both come off VIT) still have a stable order instead of depending
# on how the Dictionary happened to hash.
func ids() -> Array:
	var stats := Drive.def("stat") as StatDef
	var order: Array = stats.base_ids() if stats != null else []
	var out: Array = _pools.keys()
	out.sort_custom(func(a: String, b: String) -> bool:
		var ka: Vector2i = _rank(a, order)
		var kb: Vector2i = _rank(b, order)
		if ka.x != kb.x:
			return ka.x < kb.x
		return ka.y < kb.y)
	return out

# A pool with no attribute sorts to the end: `find` returns -1, which is why the
# fallback is a number bigger than any real index rather than the -1 itself.
func _rank(id: String, order: Array) -> Vector2i:
	var last: int = order.size() + 1
	var pair: Array = sources(id)
	if pair.is_empty():
		return Vector2i(last, last)
	var first: int = order.find(pair[0])
	var second: int = order.find(pair[1]) if pair.size() > 1 else last
	return Vector2i(last if first < 0 else first, last if second < 0 else second)
