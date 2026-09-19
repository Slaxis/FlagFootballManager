# Pools — the five bars every person carries, and what empties each one.
#
# ⚠️ A POOL IS A PAIR, NOT A NUMBER: `now` and `max`. That is what makes a bar a
# bar, and it is the whole reason this file exists before anything spends from
# it — a screen that shows a single figure has to be rewritten the day something
# drains it, and a screen that shows a fraction never does.
#
#   HEALTH     the body. Takes the hit, and at the bottom you are injured and on
#              the bench — so it is the shield certain events are spent against
#              rather than a number that goes down for its own sake.
#   STAMINA    how many plays in a row before you come off.
#   SANITY     mental strength. Breaks under pressure.
#   EMOTIONAL  emotional strength: what calls a team-mate over, what gets in an
#              opponent's head, what brings the touchline into it.
#   LOYALTY    how committed you are to THIS club. At the bottom you can leave.
#
# THE FIRST FOUR ARE ABOUT THE PERSON AND THE FIFTH IS ABOUT A RELATIONSHIP, and
# that is the only real difference between them. Four ceilings come off the
# attributes, because what your body and your head can hold is who you are.
# Loyalty's does not: nothing about a player says how much he can care about a
# club he has not joined yet.
#
# Nobody drains any of them yet. `D.1` spends the first four in a match, `C.1`
# and `C.3` write Loyalty — the manager's actions and the monthly dues — and
# `C.5` refills what a week restores. This file is the shape they all agree on.
class_name Pools

const HEALTH := "health"
const STAMINA := "stamina"
const SANITY := "sanity"
const EMOTIONAL := "emotional"
const LOYALTY := "loyalty"

const ALL: Array[String] = [HEALTH, STAMINA, SANITY, EMOTIONAL, LOYALTY]

# Which two attributes hold each ceiling up. Declared rather than branched, so
# adding a pool is a line here and not a case in three functions.
const FROM: Dictionary = {
	HEALTH: ["stamina", "strength"],
	STAMINA: ["stamina", "agility"],
	SANITY: ["will", "intelligence"],
	EMOTIONAL: ["charisma", "will"],
}

# ⚠️ EVERYBODY HAS A BODY. Decision 43 puts step 0 at the twentieth percentile of
# people, not at the bottom of them — the adult who never trained still walks
# onto the pitch and still absorbs a shoulder. Without a floor a Q1 player would
# have four points of health and a Q5 sixteen, which reads as "the weak ones are
# made of paper" rather than "the strong ones last longer".
const FLOOR := 4

# Loyalty's ceiling, since no attribute is asking. The founder bonus is the one
# thing in this file that is about history rather than about a person: you do
# not leave the club you built as easily as the club that signed you.
const LOYALTY_CEILING := 12
const LOYALTY_FOUNDER := 6

# How far the club being above or below you moves where loyalty STARTS. Three
# points a level, so a star at a sandlot club (three levels down) opens nine
# below the middle and the neighbours can already call.
const LOYALTY_PER_LEVEL := 3

# --- Ceilings ---

static func ceiling(actor: Actor, pool_id: String) -> int:
	if pool_id == LOYALTY:
		return LOYALTY_CEILING + (LOYALTY_FOUNDER if _is_founder(actor) else 0)
	var def := Drive.def("stat") as StatDef
	var pair: Array = FROM.get(pool_id, [])
	if def == null or pair.size() < 2:
		return FLOOR
	return FLOOR + def.step(actor.stat(String(pair[0]))) \
		+ def.step(actor.stat(String(pair[1])))

# --- Where a pool starts ---
#
# The four body pools open full: nothing has happened to this person yet, and a
# squad that arrives already tired would be a story nobody told.
#
# Loyalty does not, and that is the point of it. It opens from the gap between
# the club and the player, because that gap IS the relationship on day one —
# somebody who got into a side above his level is grateful, and somebody
# carrying a side below his is already being called by the neighbours.
static func opening(actor: Actor, pool_id: String, club: Dictionary = {}) -> int:
	var top: int = ceiling(actor, pool_id)
	if pool_id != LOYALTY:
		return top
	var nations := Drive.def("nation") as NationDef
	var club_level: float = nations.club_level(club) if nations != null and not club.is_empty() else 1.0
	var own_level: float = float(actor.data.get("level", 1.0))
	@warning_ignore("integer_division")
	var middle: int = top / 2
	return clampi(middle + int(round((club_level - own_level) * LOYALTY_PER_LEVEL)), 0, top)

# Every pool of one person, as {id: {"now": int, "max": int}}. A Dictionary and
# not five getters because every reader wants all five — the card draws them in
# a loop and so does the test.
static func of(actor: Actor, club: Dictionary = {}) -> Dictionary:
	var out: Dictionary = {}
	for id: String in ALL:
		var top: int = ceiling(actor, id)
		out[id] = {
			"now": mini(int(actor.data.get("pool_" + id, opening(actor, id, club))), top),
			"max": top,
		}
	return out

# 0..100, which is what a ten-slot bar wants. A ceiling of zero cannot happen —
# FLOOR and LOYALTY_CEILING both see to that — but a module may write its own
# catalogue, and a division by zero in a draw call is a black screen.
static func fraction(pool: Dictionary) -> int:
	var top: int = int(pool.get("max", 0))
	if top <= 0:
		return 0
	return clampi(int(round(float(int(pool.get("now", 0))) * 100.0 / float(top))), 0, 100)

static func _is_founder(actor: Actor) -> bool:
	return bool(actor.data.get("founder", false))
