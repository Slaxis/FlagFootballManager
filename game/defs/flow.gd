# FlowDef — registry of available Flow declarations. Each Thing under
# `<module>/things/flow/<id>/<id>.json` becomes one entry, accessible
# by id via `get_flow(id)`.
#
# A Flow declaration is a Dictionary with `id`, `entry` and `steps`
# (each step carries `scene_class`, `scene_file`, optional `consumes`
# / `produces`, and a `transitions` map). The Flow runtime in
# `engine/d5star/scene/flow.gd` consumes it via `Flow.start(data)`.
#
# Discovery: DefManager scans every active module for Things matching
# `things/flow/<id>/<id>.json` and calls `add_thing()` once per entry.
# CLAUDE: I think this def should go to D5star, because Flow is a core engine feature and not game-specific.
extends Def
class_name FlowDef

var _by_id: Dictionary = {}    # id -> raw flow Dictionary

func load_data(_raw: Dictionary) -> void:
	pass

func add_thing(thing: Dictionary) -> void:
	var id: String = String(thing.get("id", ""))
	if id == "":
		return
	_by_id[id] = thing

func get_flow(id: String) -> Dictionary:
	return _by_id.get(id, {})

func all() -> Array:
	return _by_id.values()

func ids() -> Array:
	return _by_id.keys()
