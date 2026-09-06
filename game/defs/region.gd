# RegionDef — the five macro-regions of Brazil and which UFs belong to each.
#
# Every club's region is derived from its UF through this Def and is never
# stored on the club itself. The CBFA team listing we sourced misfiles RR and
# TO as South, PB as South and SC as Southeast; deriving makes that whole
# class of bug impossible to reintroduce.
extends Def
class_name RegionDef

var _by_id: Dictionary = {}         # region id -> raw region Dictionary
var _uf_to_region: Dictionary = {}  # "RJ" -> "sudeste"

func load_data(raw: Dictionary) -> void:
	_by_id.clear()
	_uf_to_region.clear()
	var raw_regions: Variant = raw.get("regions", [])
	if not raw_regions is Array:
		return
	for entry: Variant in (raw_regions as Array):
		if not entry is Dictionary:
			continue
		var region: Dictionary = entry as Dictionary
		var id: String = _key(String(region.get("id", "")))
		if id == "":
			continue
		_by_id[id] = region
		for uf: Variant in region.get("ufs", []):
			_uf_to_region[String(uf).to_upper()] = id

# Region id for a UF, or "" when the UF is unknown.
func region_of(uf: String) -> String:
	return String(_uf_to_region.get(String(uf).strip_edges().to_upper(), ""))

func label(region_id: String) -> Variant:
	return (_by_id.get(_key(region_id), {}) as Dictionary).get("label", "")

func ufs(region_id: String) -> Array:
	return (_by_id.get(_key(region_id), {}) as Dictionary).get("ufs", [])

func ids() -> Array:
	return _by_id.keys()

func has_uf(uf: String) -> bool:
	return _uf_to_region.has(String(uf).strip_edges().to_upper())
