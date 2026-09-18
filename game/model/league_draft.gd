# LeagueDraft — a pre-season, one move at a time, with a paper trail.
#
# The shape, and every phase runs BEST CLUB FIRST:
#
#   repeat until everybody is built:
#     · each unfinished club holds a TRYOUT for what it lacks and picks from it
#     · whoever it did not pick walks to the Praça
#     · one INDIE turnout — the people nobody called — into the Praça
#     · each club, best first, picks what it still needs out of the Praça
#
# This replaced a single stream of spawns that clubs were offered one by one,
# and the reason it had to is the failure you can watch happen: a league short
# of centers sat there rolling receivers and refusing them, a hundred lines of
# "ninguém quis" while the loop waited for the dice to produce the one position
# it needed. Supply is now made BY a club FOR its own gap, which is both how it
# actually works and why the tail went away.
#
# `LeagueGenerator.fill()` runs this to the end in one call, which is what the
# tests want and what a frozen window looks like to a player; the draft screen
# drives the same object a step at a time and draws the bar. One loop, two
# doors — they cannot drift.
#
# AND IT KEEPS A LOG, which is the more interesting half. Everything this
# system has got wrong so far got wrong quietly: the club that ended up with
# six rushers, the fit term that compared two different rulers, the Praça that
# came out empty. One line per signing, saying who went where and why, turns
# all of that into something you can scroll.
class_name LeagueDraft
extends RefCounted

enum Phase { SETUP, TRYOUTS, INDIE, MARKET, TOPUP, SETTLE, DONE }

# Ceiling on the log: a big league is a few hundred moves and a text box with
# no limit is a scroll nobody reaches the bottom of.
const MAX_LINES := 900

var rosters: Rosters = null
var praca: Praca = null
var category: String = Actor.CATEGORY_MASC

var lines: Array[String] = []
var phase: Phase = Phase.SETUP

var _clubs: Array = []
var _positions: PositionDef = null
var _level: float = 1.0
var _round: int = 0
var _cursor: int = 0
var _spawned: int = 0
var _signed_this_round: int = 0
var _market_floor: int = 0
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
	return clampf(float(_seated()) / float(_work_total), 0.0, 0.99)

func headline() -> String:
	match phase:
		Phase.SETUP:
			return UiText.t("draft.phase_setup")
		Phase.INDIE:
			return UiText.t("draft.phase_indie")
		Phase.MARKET:
			return UiText.t("draft.phase_market")
		Phase.TOPUP:
			return UiText.t("draft.phase_topup")
		Phase.SETTLE:
			return UiText.t("draft.phase_settle")
		Phase.DONE:
			return UiText.t("draft.phase_done")
		_:
			return _last_club if _last_club != "" else UiText.t("draft.phase_tryouts")

# One unit of work: one club's tryout, one club's turn at the market, one club
# closed. Small on purpose — a step that took a whole round would put the
# stutter back.
func step() -> void:
	match phase:
		Phase.SETUP:
			_step_setup()
		Phase.TRYOUTS:
			_step_tryouts()
		Phase.INDIE:
			_step_indie()
		Phase.MARKET:
			_step_market()
		Phase.TOPUP:
			_step_topup()
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
	var fielding: Array = []
	for club: Dictionary in LeagueGenerator.clubs_fielding(teams, category):
		if not rosters.is_filled(String(club.get("id", "")), category):
			fielding.append(club)
	if fielding.is_empty():
		phase = Phase.DONE
		return
	# Strongest first, and it stays that way for every phase. This ordering IS
	# the stratification: the best side picks from a full tryout and a full
	# Praça, and what is left over is what the bottom of the table gets.
	_clubs = LeagueGenerator.by_standing(fielding)
	_level = LeagueGenerator.ambient_level(_clubs)
	_market_floor = maxi(int(round(_clubs.size() * LeagueGenerator.RESIDUE_PER_CLUB)),
		LeagueGenerator.RESIDUE_MIN)
	_work_total = _market_floor
	for club: Dictionary in _clubs:
		_work_total += rosters.target_size(
			String(club.get("id", "")), int(club.get("tier", 4)))
		_work_total += rosters.staff_target(int(club.get("tier", 4)))
	_say("draft.header", [_clubs.size(), snappedf(_level, 0.01)])

# The authored athletes sit down first, one club per step. They are a fact
# about the world, not a draft outcome — a real person at a real club is where
# he is because somebody wrote him there.
func _step_setup() -> void:
	if _cursor >= _clubs.size():
		_cursor = 0
		_open_round()
		return
	var club: Dictionary = _clubs[_cursor]
	var id: String = String(club.get("id", ""))
	var seated: int = rosters.seat_curated(id, category)
	rosters.mark_filled(id, category)
	if seated > 0:
		_say("draft.curated", [seated, club.get("name", id)])
	_cursor += 1

func _open_round() -> void:
	_round += 1
	_signed_this_round = 0
	_cursor = 0
	phase = Phase.TRYOUTS
	_say("draft.round", [_round])

# One club puts out the word. It advertises the positions it is short of, and
# what turns up leans that way — which is the entire answer to the old tail:
# you do not wait for a center to wander past, you announce a tryout.
func _step_tryouts() -> void:
	if _cursor >= _clubs.size():
		phase = Phase.INDIE
		return
	var club: Dictionary = _clubs[_cursor]
	_cursor += 1
	if LeagueGenerator.is_built(club, rosters, category, _positions):
		return
	var id: String = String(club.get("id", ""))
	var wanted: Array[String] = LeagueGenerator.gaps(club, rosters, category, _positions)
	var candidates: Array[Actor] = Tryout.hold(club, wanted, praca.world_seed,
		_spawned, category, LeagueGenerator.years_cap(club, rosters, category))
	_spawned += candidates.size()
	_last_club = String(club.get("name", id))
	_say("draft.tryout", [_last_club, candidates.size(), _codes(wanted)])

	# The club picks first, and keeps picking while it still wants somebody.
	while true:
		var who: Actor = LeagueGenerator.pick(club, candidates, rosters, category, _positions)
		if who == null:
			break
		candidates.erase(who)
		var why: String = LeagueGenerator.reason_for(
			club, who, rosters, category, _positions)
		_seat(rosters, id, who)
		_signed_this_round += 1
		_say("draft.signed", [_who(who), _last_club, why])
	# And whoever it did not pick walks to the Praça, which is how somebody good
	# ends up available to a worse club.
	for left: Actor in candidates:
		praca.add(left)
		_say("draft.passed_over", [_who(left)])

# The turnout nobody organised: the gridiron player who also plays flag, the
# cousin, the guy who saw a game on Sunday. They arrive at the scene rather
# than at a club, so they land in the Praça and get picked from there.
func _step_indie() -> void:
	var arrivals: Array[Actor] = Tryout.indie(_level, praca.world_seed, _spawned, category)
	_spawned += arrivals.size()
	for person: Actor in arrivals:
		praca.add(person)
	_say("draft.indie", [arrivals.size()])
	_cursor = 0
	phase = Phase.MARKET

# The draft proper. Each club, best first, takes what it still needs out of the
# Praça — and it takes everything it wants, because that is the point of being
# the best club: Flag Kings shops a full square and Estácio shops what is left.
func _step_market() -> void:
	if _cursor >= _clubs.size():
		_close_round()
		return
	var club: Dictionary = _clubs[_cursor]
	_cursor += 1
	if LeagueGenerator.is_built(club, rosters, category, _positions):
		return
	var id: String = String(club.get("id", ""))
	while true:
		var who: Actor = LeagueGenerator.pick(
			club, praca.people, rosters, category, _positions)
		if who == null:
			break
		var why: String = LeagueGenerator.reason_for(
			club, who, rosters, category, _positions)
		praca.take(who)
		_seat(rosters, id, who)
		_signed_this_round += 1
		_say("draft.from_market", [_who(who), club.get("name", id), why])

func _close_round() -> void:
	if _everybody_built():
		_cursor = 0
		phase = Phase.TOPUP
		return
	# A round that signed NOBODY will not sign anybody next time either: the
	# tryouts advertised the gaps and the gaps went unfilled. Better a short
	# squad and a line in the log than a loop that never ends.
	if _signed_this_round == 0:
		_say("draft.stalled", [_round])
		_cursor = 0
		phase = Phase.TOPUP
		return
	if _round >= LeagueGenerator.MAX_ROUNDS:
		_say("draft.gave_up", [LeagueGenerator.MAX_ROUNDS])
		_cursor = 0
		phase = Phase.TOPUP
		return
	_open_round()

# A league whose every club filled up on its own tryouts leaves an empty
# square, and an empty square is a transfer market that starts dead. If the
# pre-season did not leave a market behind, one more turnout does.
func _step_topup() -> void:
	if praca.size() >= _market_floor:
		_cursor = 0
		phase = Phase.SETTLE
		return
	var arrivals: Array[Actor] = Tryout.indie(_level, praca.world_seed, _spawned, category)
	_spawned += arrivals.size()
	for person: Actor in arrivals:
		praca.add(person)

func _step_settle() -> void:
	if _cursor >= _clubs.size():
		_say("draft.market_left", [praca.size(), praca.median_age(),
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
	_say("draft.settled", [club.get("name", id), rosters.athlete_count(id, category),
		rosters.staff_count(id, category),
		int(float(total) / maxf(float(people.size()), 1.0)), _shape(id)])
	_cursor += 1

# ⚠️ HIRING SOMEBODY IS NOT GIVING HIM THE CHAIR. Staff used to be seated the
# moment they were signed, and since `head_coach` is the first chair a tryout
# advertises, EVERY club in the league opened with a head coach already in post —
# a decision made for you, silently, before you had seen the roster.
#
# Athletes arrive un-ticked because picking the starting five is the manager's
# job. A coaching staff is the same job. The people are there, on the roster,
# with the staff affinities to prove it; which of them sits where is yours.
#
# The presidency is the one exception, and it is not an exception to this rule —
# it is a different rule. You do not appoint yourself, you already are it.
func _seat(target: Rosters, team_id: String, who: Actor) -> void:
	target.add(team_id, category, who)

# --- Reading ---

func _everybody_built() -> bool:
	for club: Dictionary in _clubs:
		if not LeagueGenerator.is_built(club, rosters, category, _positions):
			return false
	return true

func _seated() -> int:
	var total: int = praca.size()
	for club: Dictionary in _clubs:
		total += rosters.squad(String(club.get("id", "")), category).size()
	return total

func _who(actor: Actor) -> String:
	return "%s %s %d  nv %.1f" % [
		actor.display_name(), _positions.code(actor.position()), actor.age(),
		float(actor.data.get("level", 1.0))]

func _codes(ids: Array[String]) -> String:
	var out: Array[String] = []
	for id: String in ids:
		out.append(_positions.code(id))
	return " ".join(out)

func _shape(team_id: String) -> String:
	var out: String = ""
	for id: String in _positions.playing_ids():
		out += "%s%d " % [_positions.code(id), rosters.depth_at(team_id, category, id)]
	return out.strip_edges()

func _say(key: String, args: Array) -> void:
	if lines.size() >= MAX_LINES:
		return
	lines.append(UiText.t(key) % args)
