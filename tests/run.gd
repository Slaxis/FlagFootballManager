# Headless test runner. Loads every suite, runs each test function through
# TestHelper, prints a per-test line, and exits 0 (all passed) or 1.
#
#   godot --headless --path . res://tests/run.tscn
#
# It runs as a SCENE, not via `--script`. That is deliberate: a `--script`
# run replaces the main loop with a custom SceneTree and the autoloads do
# not exist while `_init()` executes, so Drive/God/The are unreachable and
# any suite touching them aborts the runner mid-flight. Booting a scene
# gives us the real engine, fully wired.
extends Node

const _SUITES: Array[String] = [
	"res://tests/test_stat.gd",
	"res://tests/test_actor.gd",
]

func _ready() -> void:
	var started: int = Time.get_ticks_msec()
	var passed: int = 0
	var failed: int = 0
	var failed_names: Array[String] = []

	for suite_path: String in _SUITES:
		var label: String = suite_path.get_file().get_basename()
		var suite_script: Script = load(suite_path) as Script
		if suite_script == null:
			print("\n[%s]\n  X não carregou" % label)
			failed += 1
			continue
		var suite: Object = suite_script.new()
		if not suite.has_method("tests"):
			print("\n[%s]\n  X não expõe tests()" % label)
			failed += 1
			continue
		print("\n[%s]" % label)
		for test_name: String in (suite.tests() as Array):
			var helper := TestHelper.new()
			suite.call(test_name, helper)
			if helper.has_failures():
				failed += 1
				failed_names.append("%s::%s" % [label, test_name])
				print("  X %s" % test_name)
				for message: String in helper.failures():
					print("      . %s" % message)
			else:
				passed += 1
				print("  ok %s" % test_name)

	print("\n———————————————————————")
	print("%d passaram · %d falharam · %d ms" % [passed, failed, Time.get_ticks_msec() - started])
	if failed > 0:
		print("\nFalhas:")
		for name: String in failed_names:
			print("  - %s" % name)
	get_tree().quit(0 if failed == 0 else 1)
