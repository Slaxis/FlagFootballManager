# Tests for how a world comes to exist: spawn → Praça → draft → squad.
#
# This is the suite that has to be convincing, because the loop it covers
# replaced the thing that was obviously wrong but individually plausible —
# every club inventing exactly the people it was short of. That produced
# squads that each looked fine and together were impossible, and no test
# noticed, because every test was about one club.
#
# So these assertions are all about the WHOLE field at once.
extends RefCounted
class_name TestLeagueGenerator

const SEED := 20260420
const CATEGORY := Actor.CATEGORY_MASC

var _cached: Rosters = null
var _cached_praca: Praca = null

func tests() -> Array:
	return [
		"test_every_club_can_field_a_side",
		"test_the_praca_is_left_with_a_market",
		"test_a_club_is_a_club_and_the_praca_is_not",
		"test_nobody_is_born_holding_a_clipboard",
		"test_the_same_seed_builds_the_same_world",
		"test_filling_twice_does_not_double_anybody",
		"test_the_better_clubs_end_up_with_the_better_people",
		"test_a_squad_covers_its_formation_in_depth",
		"test_somebody_already_seated_is_counted_not_replaced",
		"test_a_praca_survives_the_round_trip",
		"test_the_draft_writes_down_what_it_did",
		"test_a_club_hires_a_bench_but_the_chairs_are_yours",
		"test_a_founded_club_is_a_squad_of_rookies",
	]

func _world() -> Rosters:
	if _cached != null:
		return _cached
	League.ensure_filled(SEED)
	_cached = Rosters.make(SEED)
	_cached_praca = Praca.make(SEED)
	LeagueGenerator.fill(_cached, _cached_praca, CATEGORY)
	return _cached

func _praca() -> Praca:
	_world()
	return _cached_praca

func _clubs() -> Array:
	var teams := Drive.def("team") as TeamDef
	return teams.all() if teams != null else []

# The whole point of the fill loop. It is not "everybody got a squad" — it is
# "nobody is left unable to play", which is a different and much harder thing:
# seven registered AND somebody at every position on the field.
func test_every_club_can_field_a_side(t: TestHelper) -> void:
	var rosters: Rosters = _world()
	var positions := Drive.def("position") as PositionDef
	if positions == null:
		t.fail("PositionDef ausente"); return
	var checked: int = 0
	for club: Dictionary in _clubs():
		var id: String = String(club.get("id", ""))
		if not bool(club.get("squads", {}).get(CATEGORY, true)):
			continue
		checked += 1
		t.check(LeagueGenerator.playable(rosters, id, CATEGORY, positions),
			"'%s' não consegue entrar em quadra: %d inscritos" %
				[club.get("name", id), rosters.squad(id, CATEGORY).size()])
	t.check(checked >= 10, "só %d clubes no campeonato — o teste não testou nada" % checked)

# A league that stops spawning the instant every club is legal has an empty
# market on day one. The residue is not slack, it is the transfer system.
func test_the_praca_is_left_with_a_market(t: TestHelper) -> void:
	var praca: Praca = _praca()
	t.check(praca.size() >= LeagueGenerator.RESIDUE_MIN,
		"a praça ficou com %d pessoas" % praca.size())
	t.check(praca.median_age() > 0, "a praça não sabe a idade de ninguém")
	t.check(praca.median_overall() > 0, "a praça não sabe o geral de ninguém")
	t.check(praca.median_level() > 0.0, "a praça não sabe o nível de ninguém")

func test_a_club_is_a_club_and_the_praca_is_not(t: TestHelper) -> void:
	var rosters: Rosters = _world()
	for person: Actor in _praca().people:
		t.check(person.in_praca(), "%s está na praça com clube '%s'" %
			[person.display_name(), person.team()])
	var checked: int = 0
	for club: Dictionary in _clubs():
		var id: String = String(club.get("id", ""))
		for person: Actor in rosters.squad(id, CATEGORY):
			checked += 1
			t.equal(person.team(), id, "%s está em '%s'" % [person.display_name(), id])
	t.check(checked > 50, "só %d atletas na liga inteira" % checked)

# NOBODY IS BORN A FITNESS COACH. The matcher used to choose among all fourteen
# positions, five of them staff, and a squad came out with more clipboards than
# players. A staff chair is a late-career transition, so spawning never offers
# one — this is the assertion that says so out loud.
func test_nobody_is_born_holding_a_clipboard(t: TestHelper) -> void:
	var positions := Drive.def("position") as PositionDef
	if positions == null:
		t.fail("PositionDef ausente"); return
	var playing: Array[String] = positions.playing_ids()
	var seen: Dictionary = {}
	for i: int in range(60):
		var person: Actor = ActorGenerator.spawn(SEED, i, 1.0)
		t.check(playing.has(person.position()),
			"nasceu em '%s', que não é posição de quadra" % person.position())
		seen[person.position()] = true
	# And not all in the same box either, or the squads would be unplayable for
	# the opposite reason.
	t.check(seen.size() >= 4, "só %d posições distintas em 60 nascimentos" % seen.size())

func test_the_same_seed_builds_the_same_world(t: TestHelper) -> void:
	League.ensure_filled(SEED)
	var first: Rosters = Rosters.make(SEED)
	LeagueGenerator.fill(first, Praca.make(SEED), CATEGORY)
	var second: Rosters = Rosters.make(SEED)
	LeagueGenerator.fill(second, Praca.make(SEED), CATEGORY)
	var checked: int = 0
	for club: Dictionary in _clubs():
		var id: String = String(club.get("id", ""))
		var a: Array[Actor] = first.squad(id, CATEGORY)
		var b: Array[Actor] = second.squad(id, CATEGORY)
		t.equal(b.size(), a.size(), "'%s' mudou de tamanho" % id)
		for i: int in range(mini(a.size(), b.size())):
			checked += 1
			t.equal(b[i].display_name(), a[i].display_name(),
				"'%s' trocou de gente na posição %d" % [id, i])
	t.check(checked > 50, "comparei só %d pessoas" % checked)

# A screen may rebuild itself for any reason, and it calls this on the way. The
# day that stops being idempotent is the day a career loses its squad.
func test_filling_twice_does_not_double_anybody(t: TestHelper) -> void:
	League.ensure_filled(SEED)
	var rosters: Rosters = Rosters.make(SEED)
	var praca: Praca = Praca.make(SEED)
	LeagueGenerator.fill(rosters, praca, CATEGORY)
	var sizes: Dictionary = {}
	for id: String in rosters.team_ids():
		sizes[id] = rosters.squad(id, CATEGORY).size()
	var before: int = praca.size()
	LeagueGenerator.fill(rosters, praca, CATEGORY)
	for id: String in sizes.keys():
		t.equal(rosters.squad(id, CATEGORY).size(), int(sizes[id]),
			"'%s' cresceu na segunda passada" % id)
	t.equal(praca.size(), before, "a praça cresceu na segunda passada")

# NOBODY ASSIGNS QUALITY TO A CLUB. The draft matches level to level, and the
# tier table is supposed to fall out of that on its own. If this ever goes red,
# the stratification is being faked somewhere else.
func test_the_better_clubs_end_up_with_the_better_people(t: TestHelper) -> void:
	var rosters: Rosters = _world()
	var strong: Array[int] = []
	var weak: Array[int] = []
	for club: Dictionary in _clubs():
		var id: String = String(club.get("id", ""))
		var bucket: Array[int] = strong if int(club.get("reputation", 0)) >= 45 else weak
		for person: Actor in rosters.squad(id, CATEGORY):
			bucket.append(person.overall())
	if strong.is_empty() or weak.is_empty():
		t.fail("o campeonato não tem os dois extremos"); return
	t.check(_mean(strong) > _mean(weak),
		"federados (%.1f) não ficaram melhores que a várzea (%.1f)" %
			[_mean(strong), _mean(weak)])

# Playable only asks for ONE man per position, which is the competition's floor
# and not a squad. A club that fills up must fill up in the shape of a team:
# three receivers before a sixth rusher, because that is where the slots are.
func test_a_squad_covers_its_formation_in_depth(t: TestHelper) -> void:
	var rosters: Rosters = _world()
	var positions := Drive.def("position") as PositionDef
	if positions == null:
		t.fail("PositionDef ausente"); return
	var checked: int = 0
	for club: Dictionary in _clubs():
		var id: String = String(club.get("id", ""))
		var people: Array[Actor] = rosters.squad(id, CATEGORY)
		# Only clubs with room for a full formation are held to this.
		if people.size() < positions.slots_on_side("offense") + positions.slots_on_side("defense"):
			continue
		checked += 1
		var deepest: String = ""
		var deepest_extra: int = -99
		var thinnest_extra: int = 99
		for pid: String in positions.playing_ids():
			var extra: int = rosters.depth_at(id, CATEGORY, pid) - positions.slots(pid)
			thinnest_extra = mini(thinnest_extra, extra)
			if extra > deepest_extra:
				deepest_extra = extra
				deepest = pid
		t.check(deepest_extra - thinnest_extra <= 4,
			"'%s' empilhou %d em %s enquanto outra posição está %d abaixo" %
				[club.get("name", id), deepest_extra, positions.code(deepest), -thinnest_extra])
	t.check(checked >= 6, "só %d clubes grandes o bastante para o teste" % checked)

# The player is seated at his own club BEFORE the draft runs, so the club
# counts him against its needs. Reading emptiness instead of a flag made his
# club the only one in the league with a squad of one.
func test_somebody_already_seated_is_counted_not_replaced(t: TestHelper) -> void:
	var teams := Drive.def("team") as TeamDef
	if teams == null:
		t.fail("TeamDef ausente"); return
	League.ensure_filled(SEED)
	var sandlot: Array = teams.by_tier(TeamGenerator.TIER_UNAFFILIATED)
	if sandlot.is_empty():
		t.fail("sem clube de várzea"); return
	var club_id: String = String(sandlot[0]["id"])
	var rosters: Rosters = Rosters.make(SEED)
	var manager := Actor.new()
	manager._apply_data("o_player", "actor", {
		"first_name": "Eduardo", "last_name": "Neves", "nickname": "Dudu",
		"age": 31, "position": "head_coach", "stats": {}, "skills": {}})
	rosters.add(club_id, CATEGORY, manager)
	LeagueGenerator.fill(rosters, Praca.make(SEED), CATEGORY)

	var found: bool = false
	for person: Actor in rosters.squad(club_id, CATEGORY):
		if person.thing_id == "o_player":
			found = true
	t.check(found, "o manager sumiu do próprio elenco")
	t.check(LeagueGenerator.playable(rosters, club_id, CATEGORY),
		"o clube do player ficou sem elenco: %d inscritos" %
			rosters.squad(club_id, CATEGORY).size())

func test_a_praca_survives_the_round_trip(t: TestHelper) -> void:
	var before: Praca = _praca()
	var after := Praca.new()
	after.from_snapshot(before.to_snapshot())
	t.equal(after.size(), before.size(), "tamanho da praça")
	t.equal(after.world_seed, before.world_seed, "semente")
	for i: int in range(before.size()):
		t.equal(after.people[i].display_name(), before.people[i].display_name(),
			"nome na posição %d" % i)
		t.equal(after.people[i].position(), before.people[i].position(),
			"posição na posição %d" % i)

# A draft that cannot be read is a draft you have to trust, and every bug this
# system has had so far was quiet: the club that ended up with six rushers, the
# fit term comparing two different rulers, the Praça that came out empty. None
# of them raised anything. The log is the instrument.
func test_the_draft_writes_down_what_it_did(t: TestHelper) -> void:
	League.ensure_filled(SEED)
	var rosters: Rosters = Rosters.make(SEED)
	var praca: Praca = Praca.make(SEED)
	var run: LeagueDraft = LeagueDraft.make(rosters, praca, CATEGORY)
	var last: float = -1.0
	var steps: int = 0
	while not run.is_done() and steps < 4000:
		# The bar never goes backwards. A progress number that retreats is worse
		# than none: it reads as the thing having gone wrong.
		t.check(run.progress() >= last, "a barra andou pra trás no passo %d" % steps)
		last = run.progress()
		run.step()
		steps += 1
	t.check(run.is_done(), "o draft não terminou em %d passos" % steps)
	t.equal(run.progress(), 1.0, "a barra não fechou")
	t.check(run.lines.size() > 20, "o log tem só %d linhas" % run.lines.size())
	t.check(run.headline().strip_edges() != "", "a legenda saiu vazia")

	# Every line is a real sentence, not a format string that never got its
	# arguments — which is what a missing i18n key looks like from here.
	for line: String in run.lines:
		t.check(not line.contains("%"), "linha com formatação crua: %s" % line)
		t.check(not line.begins_with("draft."), "chave de tradução faltando: %s" % line)

	# And stepping it is the same world the one-shot door builds.
	var other: Rosters = Rosters.make(SEED)
	LeagueGenerator.fill(other, Praca.make(SEED), CATEGORY)
	for id: String in rosters.team_ids():
		t.equal(other.squad(id, CATEGORY).size(), rosters.squad(id, CATEGORY).size(),
			"'%s' saiu diferente pelos dois caminhos" % id)

# Every club has somebody on the sideline, sized by tier — and NOBODY IS SEATED.
#
# Staff used to be put in their chair the moment they were signed, and since
# `head_coach` is the first chair a tryout advertises, every club in the league
# opened with a head coach already in post. That is a decision made for the
# manager, silently, before he has seen the roster.
#
# Athletes arrive un-ticked because picking the starting five is his job. A
# coaching staff is the same job.
func test_a_club_hires_a_bench_but_the_chairs_are_yours(t: TestHelper) -> void:
	var rosters: Rosters = _world()
	var positions := Drive.def("position") as PositionDef
	if positions == null:
		t.fail("PositionDef ausente"); return
	var checked: int = 0
	var staff_seen: int = 0
	for club: Dictionary in _clubs():
		var id: String = String(club.get("id", ""))
		if not rosters.has_squad(id, CATEGORY):
			continue
		checked += 1
		var tier: int = int(club.get("tier", 4))
		t.equal(rosters.staff_count(id, CATEGORY), rosters.staff_target(tier),
			"'%s' (tier %d) não contratou a comissão" % [club.get("name", id), tier])
		for pid: String in positions.ids_on_side(PositionDef.SIDE_STAFF):
			t.check(rosters.depth_at(id, CATEGORY, pid) <= 1,
				"'%s' contratou %d para %s" % [club.get("name", id),
					rosters.depth_at(id, CATEGORY, pid), positions.code(pid)])
		for person: Actor in rosters.squad(id, CATEGORY):
			if positions.side(person.position()) == PositionDef.SIDE_STAFF:
				staff_seen += 1
				t.check(person.lineup().is_empty(),
					"%s já chegou sentado em %s — a cadeira é do manager" %
						[person.display_name(), positions.code(person.position())])
				t.equal(person.jersey(), Actor.NO_JERSEY,
					"%s é comissão e saiu de camisa %d" %
						[person.display_name(), person.jersey()])
			else:
				t.check(person.jersey() != Actor.NO_JERSEY or person.thing_id == "o_player",
					"%s é atleta e saiu sem camisa" % person.display_name())
	t.check(checked >= 10, "só %d clubes montados" % checked)
	t.check(staff_seen >= 10, "só %d contratados de comissão na liga inteira" % staff_seen)

func _mean(values: Array[int]) -> float:
	if values.is_empty():
		return 0.0
	var total: float = 0.0
	for value: int in values:
		total += float(value)
	return total / float(values.size())


# THE ONE CLUB WHOSE PREMISE IS THAT NOBODY THERE HAS DONE THIS BEFORE.
#
# The founder scenario promises a squad of rookies, and the origin writes the
# numbers — `squad.max_career_years`, plus a couple who left another side to bet
# on this one. Its own tryouts turn up novices because the cap is passed down to
# them, but the PRAÇA does not: the market is full of other people's careers,
# and without a rule the founded club would quietly stock up on them in the
# draft phase. So the cap lives in `wants`, where both doors read it.
func test_a_founded_club_is_a_squad_of_rookies(t: TestHelper) -> void:
	var positions := Drive.def("position") as PositionDef
	if positions == null:
		t.fail("PositionDef ausente"); return
	var rosters: Rosters = Rosters.make(SEED + 77)
	var club: Dictionary = {
		"id": "test_founded", "name": "Fundado Ontem", "tier": 4, "reputation": 12,
		"max_career_years": 2, "veterans": 0,
	}
	# Same club, same hole, two candidates — one who has been playing eight
	# years and one who started last season.
	var veteran: Actor = ActorGenerator.spawn(SEED, 1, 4.0)
	var rookie: Actor = ActorGenerator.spawn(SEED, 1, 4.0, Actor.CATEGORY_MASC,
		ActorGenerator.TRACK_PLAYER, 1)
	t.check(veteran.career_years() > 2,
		"o veterano do teste tem %d anos de carreira" % veteran.career_years())
	t.equal(rookie.career_years(), 1, "o novato do teste não é novato")
	t.equal(LeagueGenerator.wants(club, veteran, rosters, CATEGORY, positions), 0.0,
		"o clube fundado ontem contratou alguém com %d anos de estrada"
			% veteran.career_years())
	t.check(LeagueGenerator.wants(club, rookie, rosters, CATEGORY, positions) > 0.0,
		"o clube fundado ontem recusou um novato")
	# And the rule is opt-in: an ordinary club has no cap and takes either.
	var ordinary: Dictionary = {"id": "test_plain", "name": "Comum", "tier": 4, "reputation": 12}
	t.equal(LeagueGenerator.years_cap(ordinary, rosters, CATEGORY), -1,
		"um clube comum herdou o teto de novatos")
	t.check(LeagueGenerator.wants(ordinary, veteran, rosters, CATEGORY, positions) > 0.0,
		"um clube comum recusou um veterano")
