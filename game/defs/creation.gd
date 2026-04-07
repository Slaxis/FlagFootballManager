# Creation rules definition: character creation balancing.
# Loaded from creation.json, overridable by modules.
extends Def
class_name CreationDef

var point_pool: int = 5
var max_dump: int = 5
var min_stat: int = 0
var max_stat: int = 99
var base_star_points: int = 1
var star_cost: int = 1
var double_cost: int = 3
var max_dummies: int = 2

func load_data(raw: Dictionary) -> void:
	point_pool = int(raw.get("point_pool", point_pool))
	max_dump = int(raw.get("max_dump", max_dump))
	min_stat = int(raw.get("min_stat", min_stat))
	max_stat = int(raw.get("max_stat", max_stat))
	base_star_points = int(raw.get("base_star_points", base_star_points))
	star_cost = int(raw.get("star_cost", star_cost))
	double_cost = int(raw.get("double_cost", double_cost))
	max_dummies = int(raw.get("max_dummies", max_dummies))

func merge_data(raw: Dictionary) -> void:
	load_data(raw)
