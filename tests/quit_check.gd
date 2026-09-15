# Quit check — the one thing the unit suite cannot look at.
#
#   godot --headless --path . res://tests/quit_check.tscn
#
# Exit 0 means the game really went down when Sair was pressed. Exit 1 means it
# is still standing, which is what shipped twice: "$exit" reached a listener on
# Game, and Game is freed by the first scene swap. A test that ends the process
# cannot live in run.tscn, so it lives here and runs beside the boot smoke test.
extends Node2D

func _ready() -> void:
	var modules: Array[ModuleInfo] = Drive.list_modules()
	Drive.set_module(modules[0].id)
	The.load_rules()
	var flow_data: Dictionary = (Drive.def("flow") as FlowDef).get_flow(The.rules.get_flow())
	var flow := Flow.new()
	flow.name = "FlowRuntime"
	flow.quit_on_finish = true
	get_tree().root.add_child.call_deferred(flow)
	var driver := Node.new()
	driver.name = "QuitDriver"
	driver.set_script(load("res://tests/quit_driver.gd"))
	get_tree().root.add_child.call_deferred(driver)
	flow.start.call_deferred(flow_data)
	driver.run.call_deferred()
