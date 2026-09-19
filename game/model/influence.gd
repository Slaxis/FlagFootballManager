# Influence — the manager's three currencies, from Aristotle by way of Old World.
#
#   LOGOS   you convince because you are right      the intellect
#   ETHOS   you convince because you are you        standing, earned
#   PATHOS  you convince because they like you      the charisma
#
# This is decision 29, and the reason it matters more than it sounds: it is what
# makes the creation screen mean something after you leave it. A manager sheet
# that only ever decided a starting roster is a character sheet for a character
# who does not act.
#
# ⚠️ THE THREE GROW DIFFERENTLY, AND THAT IS THE DESIGN. Pathos is almost fixed
# at creation — charisma is charisma. Logos moves with study. Ethos is the only
# one that cannot be bought at all: it comes off the seasons behind you and the
# silverware on the shelf, so the ex-player starts with the one currency the
# other two scenarios have to earn.
#
# Which falls out of the origins rather than being arranged: the Fundador's
# sheet is will and leadership, the Estudado's is rules and play calling, and
# the Ex-jogador's is years. Three scenarios, three corners.
class_name Influence

const ETHOS := "ethos"
const PATHOS := "pathos"
const LOGOS := "logos"

const ALL: Array[String] = [ETHOS, PATHOS, LOGOS]

# ⚠️ CAPPED, because without it the seasons alone blow through the ruler: a
# twenty-six-year career divided by three is nine steps of ethos before the
# will is counted. Decision 26 says the first years are the ones that teach, and
# twelve of them is a long career in this scene.
const CAREER_CAP := 12
const CAREER_PER_STEP := 3

# ⚠️ HALF A STEP, NOT A THIRD, AND A MEASUREMENT CHOSE IT. At `1 + step/3` the
# three scenarios all came out at 1·1·1 a week, because they all open around
# step 2 and step 2 is the whole early game. A dial that does not move across
# the only range the player will ever see is not a dial. At half a step the
# Fundador opens on 5 points a week, the other two on 4, and the shape of the
# week differs by scenario from the first one.
const INCOME_BASE := 1
const INCOME_PER_STEP := 2

# How many weeks of income may be held. Two, so saving up and spending it at
# once is a plan — at one it is a wage, and at four the currency stops being
# scarce in the only part of the game where scarcity is the point.
const STOCK_WEEKS := 2

# --- The three ---

static func step(actor: Actor, currency: String) -> int:
	var def := Drive.def("stat") as StatDef
	if def == null:
		return 0
	match currency:
		LOGOS:
			# ⚠️ WEIGHTED TO THE SKILL, and a test forced it round this way. It
			# leaned on the attribute first — "the argument is won by whoever
			# understood the game" — and the Estudado tied with the Ex-jogador at
			# two apiece, because a few seasons pick up enough rules to round to
			# the same step and raw intelligence is not a scenario.
			#
			# The attribute is the capacity everybody has some of; the skill is
			# what this person actually DID. Three scenarios that differ by their
			# skills must be told apart by their skills.
			return _tenth(def.step(actor.stat("intelligence"))
				+ actor.skill_step("rules") * 2 + actor.skill_step("play_calling"), 4)
		PATHOS:
			return _tenth(def.step(actor.stat("charisma"))
				+ actor.skill_step("leadership") * 2, 3)
		ETHOS:
			return _tenth(def.step(actor.stat("will")) * CAREER_PER_STEP
				+ mini(actor.career_years(), CAREER_CAP)
				+ int(actor.data.get("titles", 0)) * CAREER_PER_STEP, CAREER_PER_STEP)
	return 0

# How much of a currency a week brings in.
static func income(actor: Actor, currency: String) -> int:
	@warning_ignore("integer_division")
	var earned: int = step(actor, currency) / INCOME_PER_STEP
	return INCOME_BASE + earned

static func stock_cap(actor: Actor, currency: String) -> int:
	return income(actor, currency) * STOCK_WEEKS

# All three, as {id: {"step": int, "income": int, "held": int, "cap": int}}.
# `held` reads what the career has saved and falls back to a full week, so a
# fresh manager opens with something to spend rather than with an empty purse
# and a week to wait.
static func of(actor: Actor) -> Dictionary:
	var out: Dictionary = {}
	for id: String in ALL:
		var week: int = income(actor, id)
		var cap: int = stock_cap(actor, id)
		out[id] = {
			"step": step(actor, id),
			"income": week,
			"held": clampi(int(actor.data.get("held_" + id, week)), 0, cap),
			"cap": cap,
		}
	return out

# A weighted average back onto the 0..10 ruler, rounded rather than truncated —
# three of the four inputs are already steps and the fourth is a count of years.
static func _tenth(total: int, divisor: int) -> int:
	if divisor <= 0:
		return 0
	return clampi(int(round(float(total) / float(divisor))), 0, StatDef.MAX_STEP)
