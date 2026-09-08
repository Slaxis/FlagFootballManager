# UiDef — the UI string catalogue. Every piece of chrome text the player can
# read lives here as an `{"pt": ..., "en": ...}` entry, keyed by a dotted id.
#
# Screens do not call this directly; they go through `UiText.t()`, which is
# shorter and null-safe. Modules can ship their own `ui.json`, which merges
# over this one through the normal Def merge, so a user universe can rename
# anything without touching the game.
extends Def
class_name UiDef

var _strings: Dictionary = {}   # key -> raw value (String or {pt, en})

func load_data(raw: Dictionary) -> void:
	_strings.clear()
	merge_data(raw)

func merge_data(raw: Dictionary) -> void:
	var incoming: Variant = raw.get("strings", {})
	if not incoming is Dictionary:
		return
	for key: String in (incoming as Dictionary).keys():
		_strings[key] = (incoming as Dictionary)[key]

# Resolved text for a key. Falls back to the key itself so a missing string
# shows up on screen as `start.new_game` instead of silently rendering blank.
func t(key: String, fallback: String = "") -> String:
	if not _strings.has(key):
		return fallback if fallback != "" else key
	return I18n.text(_strings[key], fallback if fallback != "" else key)

func has(key: String) -> bool:
	return _strings.has(key)

func keys() -> Array:
	return _strings.keys()
