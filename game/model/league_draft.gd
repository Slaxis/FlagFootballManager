# LeagueDraft — the same draft, one signing at a time, with a paper trail.
#
# `LeagueGenerator.fill()` runs the whole world in one call, which is what the
# tests want and what a nine-second frozen window looks like to a player. So
# the loop moved here and became resumable: the screen calls `step()` until
# `is_done()`, yielding whenever it has spent its frame budget, and the same
# code drives both — `fill()` is now a `while not is_done(): step()`.
#
# It also KEEPS A LOG, which is the more interesting half. A draft that cannot
# be read is a draft you have to trust, and everything this system gets wrong
# gets wrong quietly: the club that ended up with six rushers, the fit term
# that compared two different rulers. One line per signing, saying who went
# where and WHY, turns all of that into something you can scroll.
class_name LeagueDraft
extends RefCounted

enum Phase { SETUP, FILL, RESIDUE, SETTLE, DONE }

# Ceiling on the log, because a big league is a few hundred signings and a
# Label with no limit is a scroll nobody reaches the bottom of.
const MAX_LINES := 600

var rosters: Rosters = null
var praca: Praca = null
var category: String = Actor.CATEGORY_MASC

var lines: Array[String] = []
var phase: Phase = Phase.SETUP

var _clubs: Array = []
var _positions: PositionDef = null
var _level: float = 1.0
var _spawned: int = 0
var _residue: int = 0
var _residue_done: int = 0
var _cursor: int = 0
var _work_total: int = 1
var _last_club: String = ""

static func make(target: Rosters, pool: Praca, wanted: String) -> LeagueDraft:
	var run := LeagueDraft.new()
	run.rosters = target
	run.praca = pool
	run.category = wanted
	run._prepare()
	return run

func is_done() -> bool:
	return phase == Phase.DONE

# 0..1, and it has to be honest rather than smooth: the bar is the only thing
# standing between the player and a window that looks hung.
func progress() -> float:
	if phase == Phase.DONE:
		return 1.0
	return clampf(float(_signed() + _residue_done) / float(_work_total), 0.0, 1.0)

# What the screen puts under the bar. The club currently being built, or the
# phase when there is no one club to name.
func headline() -> String:
	match phase:
		Phase.SETUP:
			return UiText.t("draft.phase_setup")
		Phase.RESIDUE:
			return UiText.t("draft.phase_residue")
		Phase.SETTLE:
			return UiText.t("draft.phase_settle")
		Phase.DONE:
			return UiText.t("draft.phase_done")
		_:
			return _last_club if _last_club != "" else UiText.t("draft.phase_fill")

# One unit of work. Small on purpose — a step that took a whole club would put
# the stutter back.
func step() -> void:
	match phase:
		Phase.SETUP:
			_step_setup()
		Phase.FILL:
			_step_fill()
		Phase.RESIDUE:
			_step_residue()
		Phase.SETTLE:
			_step_settle()
		_:
			pass

# --- Phases ---

func _prepare() -> void:
	var teams := Drive.def("team") as TeamDef
	_positions = Drive.def("position") as PositionDef
	if teams == null or _positions == null:
		phase = Phase.DONE
		return
	for club: Dictionary in LeagueGenerator.clubs_fielding(teams, category):
		if not rosters.is_filled(String(club.get("id", "")), category):
			_clubs.append(club)
	if _clubs.is_empty():
		phase = Phase.DONE
		return
	_level = LeagueGenerator.ambient_level(_clubs)
	_residue = maxi(int(round(_clubs.size() * LeagueGenerator.RESIDUE_PER_CLUB)),
		LeagueGenerator.RESIDUE_MIN)
	_work_total = maxi(_residue, 1)
	for club: Dictionary in _clubs:
		_work_total += rosters.target_size(
			String(club.get("id", "")), int(club.get("tier", 4)))
	_say("draft.header", [_clubs.size(), snappedf(_level, 0.01)])

# The authored athletes sit down first, one club per step. They are a fact
# about the world, not a draft outcome — a real person at a real club is where
# he is because somebody wrote him there.
func _step_setup() -> void:
	if _cursor >= _clubs.size():
		_cursor = 0
		phase = Phase.FILL
		return
	var club: Dictionary = _clubs[_cursor]
	var id: String = String(club.get("id", ""))
	var seated: int = rosters.seat_curated(id, category)
	rosters.mark_filled(id, category)
	if seated > 0:
		_say("draft.curated", [seated, club.get("name", id)])
	_cursor += 1

func _step_fill() -> void:
	if _spawned >= LeagueGenerator.MAX_SPAWNS:
		_say("draft.gave_up", [LeagueGenerator.MAX_SPAWNS])
		phase = Phase.RESIDUE
		return
	if _all_full():
		phase = Phase.RESIDUE
		return
	_release(LeagueGenerator.spawn_one(praca.world_seed, _spawned, _level, category))
	_spawned += 1

# And then it keeps going. A league that stops spawning the instant every club
# is legal has an empty market on day one, which is a transfer system that
# starts dead. The overflow IS the market.
func _step_residue() -> void:
	if _residue_done >= _residue:
		_cursor = 0
		phase = Phase.SETTLE
		return
	_release(LeagueGenerator.spawn_one(
		praca.world_seed, _spawned + _residue_done, _level, category))
	_residue_done += 1

func _step_settle() -> void:
	if _cursor >= _clubs.size():
		_say("draft.market", [praca.size(), praca.median_age(),
			snappedf(praca.median_level(), 0.01)])
		phase = Phase.DONE
		return
	var club: Dictionary = _clubs[_cursor]
	var id: String = String(club.get("id", ""))
	rosters.mark_founders(id, category)
	rosters.hand_out_jerseys(id, category)
	var people: Array[Actor] = rosters.squad(id, category)
	var total: int = 0
	for person: Actor in people:
		total += person.overall()
	_say("draft.settled", [club.get("name", id), people.size(),
		int(float(total) / maxf(float(people.size()), 1.0)),
		_shape(id)])
	_cursor += 1

# --- The signing itself ---

func _release(actor: Actor) -> void:
	var team_id: String = LeagueGenerator.draft(
		actor, _clubs, rosters, category, _positions)
	var who: String = "%s %s %d  nv %.1f" % [
		actor.display_name(), _positions.code(actor.position()), actor.age(),
		float(actor.data.get("level", 1.0))]
	if team_id == "":
		praca.add(actor)
		_say("draft.to_praca", [who])
		return
	var club: Dictionary = _club(team_id)
	_last_club = String(club.get("name", team_id))
	var reason: String = LeagueGenerator.reason_for(
		club, actor, rosters, category, _positions)
	rosters.add(team_id, category, actor)
	_say("draft.signed", [who, _last_club, reason])

# --- Reading ---

func _all_full() -> bool:
	for club: Dictionary in _clubs:
		var id: String = String(club.get("id", ""))
		if rosters.squad(id, category).size() < rosters.target_size(
				id, int(club.get("tier", 4))):
			return false
		if not LeagueGenerator.playable(rosters, id, category, _positions):
			return false
	return true

func _signed() -> int:
	var total: int = 0
	for club: Dictionary in _clubs:
		total += rosters.squad(String(club.get("id", "")), category).size()
	return total

func _club(team_id: String) -> Dictionary:
	for club: Dictionary in _clubs:
		if String(club.get("id", "")) == team_id:
			return club
	return {}

func _shape(team_id: String) -> String:
	var out: String = ""
	for id: String in _positions.playing_ids():
		out += "%s%d " % [_positions.code(id), rosters.depth_at(team_id, category, id)]
	return out.strip_edges()

func _say(key: String, args: Array) -> void:
	if lines.size() >= MAX_LINES:
		return
	lines.append(UiText.t(key) % args)
