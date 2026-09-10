# Lint for the two shadowing traps that actually bit us.
#
# Godot only emits GDScript warnings inside the editor — neither a headless
# run, nor `--editor --quit`, nor `--check-only` surfaces them. That left the
# whole automated loop blind to a real class of defect, and the author was
# finding them by hand.
#
# This is NOT a reimplementation of the compiler. It covers exactly what has
# gone wrong here:
#
#   1. a variable named after a Godot built-in — `var seed` silently shadows
#      seed(), and the editor screams about it days later
#   2. a variable named after a method of the base class the file extends —
#      `var def` inside a Record shadows Record.def()
extends RefCounted
class_name TestLint

const ROOTS: Array[String] = ["res://game", "res://tests"]

# Built-ins that read like ordinary variable names, which is exactly why they
# get shadowed. Not the whole global list — the plausible half.
const BUILTINS: Array[String] = [
	"seed", "hash", "log", "min", "max", "abs", "sign", "round", "floor",
	"ceil", "pow", "str", "print", "sin", "cos", "tan", "ease", "remap",
	"wrap", "clamp", "lerp", "smoothstep", "typeof", "weakref", "randi",
	"randf", "exp", "sqrt", "range", "snapped", "instance_from_id",
]

# Methods our own base classes expose. A local with one of these names inside
# a subclass shadows the real thing.
const BASE_METHODS: Dictionary = {
	"Record": ["def", "text", "to_snapshot", "from_snapshot"],
	"Def": ["load_data", "merge_data", "add_thing"],
	"Thing": ["attr", "text", "data", "clone", "think", "say"],
	"ThingData": ["attr", "text", "data"],
	"Actor": ["attr", "text", "data", "stats", "skills", "step", "measure"],
	"Menu": ["read", "write", "go"],
	"World": ["read", "write", "go"],
	"Overlay": ["read", "write", "go"],
}

func tests() -> Array:
	return [
		"test_no_variable_shadows_a_builtin",
		"test_no_variable_shadows_a_base_class_method",
	]

func test_no_variable_shadows_a_builtin(t: TestHelper) -> void:
	# Assert the scan happened. A test whose only statement is a conditional
	# fail() asserts nothing on a clean codebase, and "asserted nothing" is
	# indistinguishable from "crashed on line one".
	t.check(_scripts().size() > 0, "não encontrou script nenhum para varrer")
	for path: String in _scripts():
		var source: String = _read(path)
		for name: String in BUILTINS:
			var line: int = _find_declaration(source, name)
			if line > 0:
				t.fail("%s:%d — 'var %s' sombreia a função embutida %s()" % [path, line, name, name])

func test_no_variable_shadows_a_base_class_method(t: TestHelper) -> void:
	t.check(_scripts().size() > 0, "não encontrou script nenhum para varrer")
	for path: String in _scripts():
		var source: String = _read(path)
		var base: String = _base_class(source)
		if not BASE_METHODS.has(base):
			continue
		for name: String in BASE_METHODS[base]:
			var line: int = _find_declaration(source, name)
			if line > 0:
				t.fail("%s:%d — 'var %s' sombreia %s.%s()" % [path, line, name, base, name])

# --- Internals ---

# Matches `var name`, `var name:` and `var name :=` at any indentation, but not
# `var name_thing` — the word has to end there.
func _find_declaration(source: String, name: String) -> int:
	var regex := RegEx.new()
	regex.compile("(?m)^[\\t ]*var[\\t ]+%s[\\t ]*(:|=|$)" % name)
	var found: RegExMatch = regex.search(source)
	if found == null:
		return 0
	return source.substr(0, found.get_start()).count("\n") + 1

func _base_class(source: String) -> String:
	var regex := RegEx.new()
	regex.compile("(?m)^extends[\\t ]+([A-Za-z_][A-Za-z0-9_]*)")
	var found: RegExMatch = regex.search(source)
	return found.get_string(1) if found != null else ""

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""

func _scripts() -> Array[String]:
	var out: Array[String] = []
	for root: String in ROOTS:
		_collect(root, out)
	return out

func _collect(path: String, into: Array[String]) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var entry: String = dir.get_next()
		if entry == "":
			break
		if entry.begins_with("."):
			continue
		var full: String = path + "/" + entry
		if dir.current_is_dir():
			_collect(full, into)
		elif entry.get_extension() == "gd":
			into.append(full)
	dir.list_dir_end()
