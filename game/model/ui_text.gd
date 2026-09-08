# UiText — the one call every screen makes to get a translated string.
#
#   UiText.t("start.new_game")            -> "Novo Jogo" / "New Game"
#   UiText.t("clubs.count") % [where, 9]  -> "Sudeste · 9 clubes"
#
# Wraps UiDef so screens never repeat the `Drive.def("ui") as UiDef` dance,
# and so a missing catalogue degrades into showing the key rather than
# rendering an empty screen.
class_name UiText

static func t(key: String, fallback: String = "") -> String:
	var def := Drive.def("ui") as UiDef
	if def == null:
		return fallback if fallback != "" else key
	return def.t(key, fallback)
