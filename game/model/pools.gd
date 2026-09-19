# Pools — the arithmetic of the five bars. The CATALOGUE is `PoolDef`.
#
# ⚠️ A POOL IS A PAIR, NOT A NUMBER: `now` and `max`. That is what makes a bar a
# bar, and it is why the shape exists before anything spends from it — a screen
# that shows a single figure has to be rewritten the day something drains it,
# and a screen that shows a fraction never does.
#
# What each bar means, what colour it is, which two attributes hold it up and
# what it is called all live in `pool.json`, because all four of those are
# content: a module that ships a different sport ships different bars. What
# lives HERE is the only part that is not content — how a ceiling is built out
# of two attributes, and where loyalty starts.
#
# THE FIRST FOUR ARE ABOUT THE PERSON AND THE FIFTH IS ABOUT A RELATIONSHIP.
# Four ceilings come off the attributes, because what your body and your head
# can hold is who you are. Loyalty's does not.
#
# Nobody drains any of them yet. `D.1` spends the first four in a match, `C.1`
# and `C.3` write Loyalty — the manager's actions and the monthly dues — and
# `C.5` refills what a week restores.
class_name Pools

const LOYALTY := PoolDef.LOYALTY

static func _def() -> PoolDef:
	return Drive.def("pool") as PoolDef

# Head to foot, by the chakra of the attribute each bar hangs from.
static func ids() -> Array:
	var def: PoolDef = _def()
	return def.ids() if def != null else []

# --- Ceilings ---

# ⚠️ THE MEAN OF THE TWO, WHICH IS WHAT PUTS IT ON THE RULER. Nought to ten like
# every other number in the game, and **ten only when both attributes are ten** —
# a body that never tires is a body that is maximal at both of the things that
# make it, and nothing less buys it.
#
# It was `4 + a + b`, running to twenty-four, which is a second ruler: every
# screen showing a pool beside an attribute had to teach which scale was which.
# The floor went with it, and that is right even though I argued for it — step 0
# already means the twentieth percentile of PEOPLE rather than the bottom of
# them, so a pool of zero says exactly what an attribute of zero says, and
# giving one of them an exception was the mistake.
static func ceiling(actor: Actor, pool_id: String) -> int:
	var def: PoolDef = _def()
	var stats := Drive.def("stat") as StatDef
	if def == null:
		return 0
	var pair: Array = def.sources(pool_id)
	if pair.is_empty():
		return def.ceiling_value(pool_id) \
			+ (def.founder_bonus(pool_id) if _is_founder(actor) else 0)
	if stats == null or pair.size() < 2:
		return 0
	return int(round((float(stats.step(actor.stat(String(pair[0]))))
		+ float(stats.step(actor.stat(String(pair[1]))))) / 2.0))

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
	var def: PoolDef = _def()
	var top: int = ceiling(actor, pool_id)
	if def == null or not def.sources(pool_id).is_empty():
		return top
	var nations := Drive.def("nation") as NationDef
	var club_level: float = nations.club_level(club) if nations != null and not club.is_empty() else 1.0
	var own_level: float = float(actor.data.get("level", 1.0))
	# Nobody is born able to love a club at ten. Loyalty's ceiling is six — nine
	# if you built the place — and where it STARTS is the gap between the club
	# and the player, because on day one that gap is the whole relationship.
	# `C.1` and `C.3` are what move it afterwards.
	@warning_ignore("integer_division")
	var middle: int = top / 2
	return clampi(middle
		+ int(round((club_level - own_level) * float(def.per_level(pool_id)))), 0, top)

# Every pool of one person, as {id: {"now": int, "max": int}}. A Dictionary and
# not five getters because every reader wants all five — the card draws them in
# a loop and so does the test.
static func of(actor: Actor, club: Dictionary = {}) -> Dictionary:
	var out: Dictionary = {}
	for id: String in ids():
		var top: int = ceiling(actor, id)
		out[id] = {
			"now": mini(int(actor.data.get("pool_" + id, opening(actor, id, club))), top),
			"max": top,
		}
	return out

# 0..100, which is what a ten-slot bar wants. A ceiling of zero should not
# happen, but a module may ship its own catalogue and a division by zero inside
# a draw call is a black screen.
static func fraction(pool: Dictionary) -> int:
	var top: int = int(pool.get("max", 0))
	if top <= 0:
		return 0
	return clampi(int(round(float(int(pool.get("now", 0))) * 100.0 / float(top))), 0, 100)

static func _is_founder(actor: Actor) -> bool:
	return bool(actor.data.get("founder", false))
