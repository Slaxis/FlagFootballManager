# Game entrypoint: activate default module, load rules, open initial UI.
extends Node2D
class_name Game

func _ready() -> void:
	var modules: Array[ModuleInfo] = Drive.list_modules()
	if modules.is_empty():
		Log.log(self, "error", "No modules found.")
		return
	if not Drive.set_module(modules[0].id):
		Log.log(self, "error", "Failed to activate module: " + modules[0].id)
		return
	The.load_rules()
	var the_rules: Rules = The.rules
	if the_rules == null or not the_rules.is_valid():
		Log.log(self, "error", "Invalid rules object, check game.json in content/system/.")
		return
	var asset_id: String = the_rules.get_asset()
	var ui: PackedScene = The.ui(asset_id)
	if ui == null:
		Log.log(self, "error", "UI scene not found for id: " + asset_id)
		return
	The.next_scene(ui)
