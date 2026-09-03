# Deterministic city graph generator.
#
# Given (city, state, rng, teen_team_specs) emits a Dictionary with nodes +
# edges + current position. Layout is a handcrafted 9-node template
# (home at center, 4 cardinal anchors, 4 team_fields at corners) with rng
# jitter on coordinates so same-seed careers feel stable but not identical
# to a neighbor's.
#
# Output shape (JSON-serializable so it round-trips through SaveManager):
# {
#   "nodes": [
#     {
#       "id": "home",
#       "type": "home",
#       "name": "Casa",
#       "pos": [0.5, 0.5],              # normalized viewport coords
#       "neighbors": ["school", ...],
#       "team_id": "..."                # only on team_field nodes
#     }, ...
#   ],
#   "current": "home"
# }
class_name CityGraphGen

const JITTER: float = 0.04  # ±4% of viewport per axis

# Base template (normalized coords). x right, y down (Godot convention).
const ANCHORS: Dictionary = {
	"home":           {"type": "home",           "pos": [0.50, 0.50]},
	"school":         {"type": "school",         "pos": [0.50, 0.18]},
	"training_field": {"type": "training_field", "pos": [0.82, 0.50]},
	"shop":           {"type": "shop",           "pos": [0.18, 0.50]},
	"hangout":        {"type": "hangout",        "pos": [0.50, 0.82]},
}

# Team-field base positions (corners). Order matches teen_team archetype order.
const TEAM_CORNERS: Array[Array] = [
	[0.18, 0.18],  # NW
	[0.82, 0.18],  # NE
	[0.18, 0.82],  # SW
	[0.82, 0.82],  # SE
]

# Which anchors each team field connects to (nearest 2).
const TEAM_CONNECTIONS: Array[Array] = [
	["school", "shop"],           # NW
	["school", "training_field"], # NE
	["shop",   "hangout"],        # SW
	["training_field", "hangout"],# SE
]

static func generate(city: String, state: String, rng: RandomNumberGenerator, teen_team_specs: Array) -> Dictionary:
	var name_def: Def = Drive.def("name_gen")
	var nodes: Array[Dictionary] = []

	# Home is fixed + named simply.
	nodes.append({
		"id": "home",
		"type": "home",
		"name": "Casa",
		"pos": _jitter(ANCHORS["home"]["pos"], rng),
		"neighbors": ["school", "training_field", "shop", "hangout"],
	})

	# Four cardinal anchors.
	nodes.append(_anchor_node("school",         rng, name_def, "Escola Estadual {neighborhood}"))
	nodes.append(_anchor_node("training_field", rng, name_def, "Campo do {neighborhood}"))
	nodes.append(_anchor_node("shop",           rng, name_def, ""))  # use place pattern
	nodes.append(_anchor_node("hangout",        rng, name_def, "Praça do {neighborhood}"))

	# Team fields — one per generated team, anchored to a corner.
	for i: int in range(min(teen_team_specs.size(), TEAM_CORNERS.size())):
		var team: Dictionary = teen_team_specs[i]
		var corner: Array = TEAM_CORNERS[i]
		var conns: Array = TEAM_CONNECTIONS[i]
		var team_name: String = String(team.get("name", "Time"))
		nodes.append({
			"id": "team_field_" + String(team.get("id", "team_" + str(i))),
			"type": "team_field",
			"name": "Campo dos " + team_name,
			"pos": _jitter(corner, rng),
			"neighbors": conns.duplicate(),
			"team_id": String(team.get("id", "")),
		})
		# Append team_field back into each anchor's neighbors list so edges are bidirectional.
		for conn_id: String in conns:
			_add_neighbor(nodes, conn_id, "team_field_" + String(team.get("id", "team_" + str(i))))

	return {
		"nodes": nodes,
		"current": "home",
		"city": city,
		"state": state,
	}

static func _anchor_node(anchor_id: String, rng: RandomNumberGenerator, name_def: Def, name_template: String) -> Dictionary:
	var spec: Dictionary = ANCHORS[anchor_id]
	var display_name: String
	if name_def == null:
		display_name = String(anchor_id).capitalize()
	elif anchor_id == "shop":
		# Shop uses one of the place patterns that references a first-name.
		var pattern: String = "Mercadinho do {first_male}" if rng.randi() % 2 == 0 else "Lanchonete da {first_female}"
		display_name = name_def.call("fill_pattern",pattern, rng)
	elif name_template == "":
		display_name = String(anchor_id).capitalize()
	else:
		display_name = name_def.call("fill_pattern",name_template, rng)
	return {
		"id": anchor_id,
		"type": String(spec["type"]),
		"name": display_name,
		"pos": _jitter(spec["pos"], rng),
		"neighbors": [],  # filled in below (home reaches out, team fields reach in)
	}

static func _jitter(base_pos: Array, rng: RandomNumberGenerator) -> Array:
	var x: float = clampf(float(base_pos[0]) + rng.randf_range(-JITTER, JITTER), 0.05, 0.95)
	var y: float = clampf(float(base_pos[1]) + rng.randf_range(-JITTER, JITTER), 0.05, 0.95)
	return [x, y]

static func _add_neighbor(nodes: Array[Dictionary], node_id: String, neighbor_id: String) -> void:
	for n: Dictionary in nodes:
		if String(n.get("id", "")) == node_id:
			var neighbors: Array = n.get("neighbors", [])
			if not neighbors.has(neighbor_id):
				neighbors.append(neighbor_id)
				n["neighbors"] = neighbors
			return
