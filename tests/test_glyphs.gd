# Every character the game can show must exist in the game's own font.
#
# This is the check that would have caught the emoji. A glyph the face does not
# have is not an error and does not warn — Godot quietly draws it from a system
# fallback, so it arrives in a different shape, a different weight and a
# different colour model, in the middle of a pixel screen. It looks like a
# sticker somebody put there, and nothing in a log or a test says why.
#
# It also catches the subtler one: four symbols in the draft log (⌂ ⚐ ⚑ ⚠) were
# in NEITHER face, and in a monospace log a fallback glyph of another width
# breaks the column that makes the log readable at all.
#
# So it walks the content files rather than the screens: a curator pasting an
# emoji into a talent description is exactly the case, and no screen test would
# ever mount the screen that shows it.
extends RefCounted
class_name TestGlyphs

# Everything a keyboard types. Below this the font is not in question.
const ASCII_TOP := 0x7F

# SCANNED, not listed. A hand-kept list is a list that a new def file is not on,
# and the whole point is catching content nobody thought to check.
const ROOTS: Array[String] = [
	"res://game/defs",
	"res://game/modules",
]

func tests() -> Array:
	return [
		"test_the_body_font_can_draw_every_string",
		"test_the_font_really_does_refuse_something",
	]

func test_the_body_font_can_draw_every_string(t: TestHelper) -> void:
	var font: FontFile = Look.body()
	if font == null:
		t.fail("fonte de corpo ausente"); return
	var checked: int = 0
	var seen: Dictionary = {}
	var files: Array[String] = []
	for root: String in ROOTS:
		_find_json(root, files)
	t.check(files.size() >= 10, "só %d arquivos de conteúdo varridos" % files.size())
	for path: String in files:
		for entry: Array in _strings(path):
			for i: int in range(String(entry[1]).length()):
				var code: int = String(entry[1]).unicode_at(i)
				if code <= ASCII_TOP or seen.has(code):
					continue
				seen[code] = true
				checked += 1
				t.check(font.has_char(code),
					"U+%04X ('%s') não existe na fonte — %s, em %s" %
						[code, String.chr(code), entry[0], path.get_file()])
	t.check(checked > 10,
		"só %d caracteres não-ASCII no conteúdo inteiro — o teste não testou nada"
			% checked)

# ⚠️ The assertion above is worthless if `has_char` answers yes to everything,
# which is exactly what it would do if the face fell back to the system. So the
# suite proves the instrument first, with a glyph no pixel font has ever had.
func test_the_font_really_does_refuse_something(t: TestHelper) -> void:
	var font: FontFile = Look.body()
	if font == null:
		t.fail("fonte de corpo ausente"); return
	t.check(not font.has_char(0x1F3B2), "has_char disse que a fonte tem 🎲")
	t.check(font.has_char(0x00E7), "a fonte deveria ter cedilha")

func _find_json(dir_path: String, into: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	for name: String in dir.get_files():
		if name.get_extension() == "json":
			into.append(dir_path.path_join(name))
	for name: String in dir.get_directories():
		_find_json(dir_path.path_join(name), into)

# [key, text] for every string in a content file, however deep.
func _strings(path: String) -> Array:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	var out: Array = []
	_walk(parsed, path.get_file(), out)
	return out

func _walk(node: Variant, trail: String, out: Array) -> void:
	if node is String:
		out.append([trail, node])
	elif node is Dictionary:
		for key: Variant in (node as Dictionary).keys():
			_walk((node as Dictionary)[key], "%s/%s" % [trail, key], out)
	elif node is Array:
		for i: int in range((node as Array).size()):
			_walk((node as Array)[i], "%s[%d]" % [trail, i], out)
