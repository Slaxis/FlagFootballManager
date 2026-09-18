# CategoryDef — who may play, and how many are on the field.
#
# Two independent axes live in this one Def, on purpose:
#
#   categoria   masc · fem · misto     — WHO can be fielded. This is what an
#                                         Actor's `plays` and `manages` refer to.
#   formato     5x5 · 4x4              — HOW MANY are on the field.
#
# They share a file because the composition rule is a function of BOTH: a mixed
# side needs 2 women whether it plays 5x5 on grass or 4x4 on sand, while a
# women's side needs everyone on the field to be a woman — so the number
# depends on the format. `min_women()` is where the two axes meet.
#
# The numbers are the Brazilian amateur convention as of 2026 and nothing more.
# We are the International Superstar Soccer of flag: if a rule changes, it
# changes in this JSON.
extends Def
class_name CategoryDef

# `min_women: "all"` means every player on the field — used by the women's
# category, where the count therefore depends on the format.
const ALL := "all"

var _categories: Dictionary = {}   # id -> raw
var _formats: Dictionary = {}      # id -> raw

func load_data(raw: Dictionary) -> void:
	_categories.clear()
	_formats.clear()
	for entry: Variant in raw.get("categories", []):
		if entry is Dictionary:
			var id: String = _key(String((entry as Dictionary).get("id", "")))
			if id != "":
				_categories[id] = entry
	for entry: Variant in raw.get("formats", []):
		if entry is Dictionary:
			var id: String = _key(String((entry as Dictionary).get("id", "")))
			if id != "":
				_formats[id] = entry

# --- Categories ---

func category_ids() -> Array:
	return _categories.keys()

func has_category(id: String) -> bool:
	return _categories.has(_key(id))

# The short form for a chip, with the whole word one hover away — the same
# contract the attributes, the positions and the talents all keep.
func category_code(id: String) -> String:
	return I18n.text(
		(_categories.get(_key(id), {}) as Dictionary).get("code", ""), category_label(id))

func category_label(id: String) -> String:
	return I18n.text((_categories.get(_key(id), {}) as Dictionary).get("label", id), id)

# --- Formats ---

func format_ids() -> Array:
	return _formats.keys()

func has_format(id: String) -> bool:
	return _formats.has(_key(id))

func format_label(id: String) -> String:
	return I18n.text((_formats.get(_key(id), {}) as Dictionary).get("label", id), id)

func on_field(format_id: String) -> int:
	return int((_formats.get(_key(format_id), {}) as Dictionary).get("on_field", 0))

# --- Where the two axes meet ---

# How many of the players on the field must be women, for this category in this
# format. Nobody enforces this yet: the match engine will, and declaring it now
# means it does not have to invent the rule.
func min_women(category_id: String, format_id: String) -> int:
	var category: Dictionary = _categories.get(_key(category_id), {})
	if category.is_empty():
		return 0
	var rule: Variant = category.get("min_women", 0)
	if rule is String and String(rule) == ALL:
		return on_field(format_id)
	return int(rule)
