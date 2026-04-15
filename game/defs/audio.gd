extends Def
class_name AudioDef

var music: Dictionary = {}
var sfx: Dictionary = {}

func load_data(raw: Dictionary) -> void:
	music = (raw.get("music", {}) as Dictionary).duplicate(true) if raw.get("music", {}) is Dictionary else {}
	sfx = (raw.get("sfx", {}) as Dictionary).duplicate(true) if raw.get("sfx", {}) is Dictionary else {}

func merge_data(raw: Dictionary) -> void:
	var incoming_music: Variant = raw.get("music", {})
	if incoming_music is Dictionary:
		for k: String in (incoming_music as Dictionary):
			music[k] = (incoming_music as Dictionary)[k]
	var incoming_sfx: Variant = raw.get("sfx", {})
	if incoming_sfx is Dictionary:
		for k: String in (incoming_sfx as Dictionary):
			sfx[k] = (incoming_sfx as Dictionary)[k]

func get_music(id: String) -> Dictionary:
	var key: String = _key(id)
	return music.get(key, {})

func get_sfx(id: String) -> Dictionary:
	var key: String = _key(id)
	return sfx.get(key, {})

func has_music(id: String) -> bool:
	return music.has(_key(id))

func has_sfx(id: String) -> bool:
	return sfx.has(_key(id))
