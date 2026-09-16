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
	"res://tests/test_ui.gd",
	"res://tests/test_team_colors.gd",
	"res://tests/test_team_generator.gd",
	"res://tests/test_category.gd",
	"res://tests/test_sheet_builder.gd",
	"res://tests/test_career.gd",
	"res://tests/test_d5.gd",
	"res://tests/test_names.gd",
	"res://tests/test_perk.gd",
	"res://tests/test_screen_start.gd",
	"res://tests/test_screen_create_manager.gd",
	"res://tests/test_rosters.gd",
	"res://tests/test_league_generator.gd",
	"res://tests/test_screen_draft.gd",
	"res://tests/test_screen_team.gd",
	"res://tests/test_thing_scan.gd",
	"res://tests/test_lint.gd",
]

func _ready() -> void:
	if not _activate_module():
		get_tree().quit(1)
		return
	# One frame before anything runs. Inside _ready the tree is still building
	# its children and add_child() is refused, which locks out any suite that
	# needs to mount a screen — and a screen nobody mounts is a screen nobody
	# tests.
	await get_tree().process_frame
	_run()

func _run() -> void:
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
		# A script with a parse error still loads as a non-null Script but
		# cannot be instantiated. Without this the whole run dies on one bad
		# file, and every suite after it silently never runs.
		var suite: Object = null
		if suite_script.can_instantiate():
			suite = suite_script.new()
		if suite == null:
			print("
[%s]
  X não instanciou (erro de parse?)" % label)
			failed += 1
			continue
		if not suite.has_method("tests"):
			print("\n[%s]\n  X não expõe tests()" % label)
			failed += 1
			continue
		print("\n[%s]" % label)
		for test_name: String in (suite.tests() as Array):
			var helper := TestHelper.new()
			suite.call(test_name, helper)
			# A test that asserted nothing did not run: GDScript aborted it on a
			# runtime error and handed control back here, where "no failures"
			# used to read as success. That false green hid five broken tests.
			if helper.checks() == 0:
				failed += 1
				failed_names.append("%s::%s" % [label, test_name])
				print("  X %s" % test_name)
				print("      . não fez asserção nenhuma — erro em tempo de execução?")
			elif helper.has_failures():
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

# Mirror what Game._ready() does. Without this no module is active, the
# content roots are empty, and every Thing-backed Def (teams, flows, ...)
# reads as empty — so a suite asserting over module content would pass while
# testing nothing at all.
func _activate_module() -> bool:
	var modules: Array[ModuleInfo] = Drive.list_modules()
	if modules.is_empty():
		print("X nenhum módulo em game/modules/ — as suítes não teriam conteúdo")
		return false
	if not Drive.set_module(modules[0].id):
		print("X falhou ao ativar o módulo " + modules[0].id)
		return false
	return true
