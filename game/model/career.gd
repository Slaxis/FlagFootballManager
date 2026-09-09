# Career — your run. The Record that every screen after Create Manager reads.
#
# It is the first real entry on the Blackboard (`The.board`): the create screen
# produces it, the Flow gates the next step on its presence, and E.1 will
# persist it. It holds the three things a whole career unfolds from:
#
#   manager   the Actor that is you
#   team_id   the club that drafted you
#   career_seed  the root of everything generated in this run
#
# The seed matters more than it looks: the sandlot clubs that exist, which one
# picked you and (from B.5) every roster all derive from it. Two careers with
# the same seed are the same universe, which is what makes a bug reproducible.
class_name Career
extends Record

var manager: Actor = null
var team_id: String = ""
# Not `seed`: that shadows Godot's built-in seed() function.
var career_seed: int = 0

static func make(manager_actor: Actor, drafted_team_id: String, value: int) -> Career:
	var career := Career.new()
	career.manager = manager_actor
	career.team_id = String(drafted_team_id).strip_edges().to_lower()
	career.career_seed = value
	return career

# The club that drafted you, straight from TeamDef.
func team() -> Dictionary:
	# Not `def`: that shadows Record.def().
	var teams := Drive.def("team") as TeamDef
	return teams.get_team(team_id) if teams != null else {}

# --- Memento ---
#
# An Actor is a Thing, so its whole state already lives in a plain `data`
# Dictionary — nothing here needs custom field-by-field serialisation.

func to_snapshot() -> Dictionary:
	return {
		"team_id": team_id,
		"seed": career_seed,
		"manager": {
			"thing_id": manager.thing_id if manager != null else "",
			"ancestor": manager.ancestor if manager != null else "",
			"data": manager.data.duplicate(true) if manager != null else {},
		},
	}

func from_snapshot(state: Dictionary) -> void:
	team_id = String(state.get("team_id", ""))
	career_seed = int(state.get("seed", 0))
	var raw: Dictionary = state.get("manager", {})
	manager = Actor.new()
	manager._apply_data(
		String(raw.get("thing_id", "")),
		String(raw.get("ancestor", "actor")),
		raw.get("data", {}),
	)
