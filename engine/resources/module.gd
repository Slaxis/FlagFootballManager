# ModuleInfo: manifest for a module read from module.json.
extends Resource
class_name ModuleInfo

var id: String = ""
var name: String = ""
var order: int = 0
var requires: Array[String] = []
var native_path: String = ""
var user_path: String = ""

static func from_dict(data: Dictionary, base_path: String) -> ModuleInfo:
	var info := ModuleInfo.new()
	info.id          = String(data.get("id",    "")).strip_edges().to_lower()
	info.name        = String(data.get("name",  info.id))
	info.order       = int(data.get("order", 0))
	info.native_path = base_path
	var req: Variant = data.get("requires", [])
	if req is Array:
		for entry: Variant in (req as Array):
			var s: String = String(entry).strip_edges().to_lower()
			if s != "":
				info.requires.append(s)
	return info
