# OriginDef — how you ended up in charge.
#
# The screen used to hand you a blank eighteen-year-old and drop him into a
# club full of people with ten-year careers, and there was no answer to the
# obvious question: why is the youngest man in the room the manager?
#
# So you pick. Three scenarios, the way Zomboid makes you pick a life before it
# makes you pick a stat — and each one is a different difficulty, not a
# different flavour:
#
#   founder   there was no club. You built it. Almost everyone is a rookie.
#   player    you played first. You can still play, and early on you will have
#             to — which costs you as a coach.
#   student   you never had the body, so you learned the game instead. An
#             established club took you on for exactly that.
#
# An origin does three things at once: it pre-spends part of your career points
# in its own direction, it says what KIND of club you get, and it conditions
# the squad that club fielded before you arrived.
extends Def
class_name OriginDef

var _by_id: Dictionary = {}
var _order: Array[String] = []

func load_data(raw: Dictionary) -> void:
	_by_id.clear()
	_order.clear()
	_ingest(raw.get("origins", []))

func add_thing(thing: Dictionary) -> void:
	_ingest([thing])

func _ingest(entries: Variant) -> void:
	if not entries is Array:
		return
	for entry: Variant in (entries as Array):
		if not entry is Dictionary:
			continue
		var spec: Dictionary = entry as Dictionary
		var id: String = _key(String(spec.get("id", "")))
		if id == "":
			Log.log(self, "error", "OriginDef: origin without an id")
			continue
		if not _by_id.has(id):
			_order.append(id)
		_by_id[id] = spec

# --- Reading ---

func origin_ids() -> Array[String]:
	return _order.duplicate()

func has_origin(id: String) -> bool:
	return _by_id.has(_key(id))

func origin(id: String) -> Dictionary:
	return _by_id.get(_key(id), {})

func label(id: String) -> String:
	return I18n.text(origin(id).get("label", id), id)

# The one-line pitch that goes on the chip.
func line(id: String) -> String:
	return I18n.text(origin(id).get("line", ""), "")

func desc(id: String) -> String:
	return I18n.text(origin(id).get("desc", ""), "")

# Steps, not stored points: "leadership 3" means three steps of it, which is
# what the creation screen deals in.
func sheet(id: String) -> Dictionary:
	return origin(id).get("sheet", {})

func stat_bias(id: String) -> Dictionary:
	return sheet(id).get("stats", {})

func skill_bias(id: String) -> Dictionary:
	return sheet(id).get("skills", {})

# Where on the world ladder this scenario drops you. A founder is starting a
# club in his own neighbourhood; a student was picked up by somebody who
# already had one. It is the same dial NationDef gives a club, so the manager
# is drawn against the same ruler as everybody he will manage.
func club_level(id: String) -> float:
	return float(origin(id).get("club", {}).get("level", 1.0))

# A TRACK, NOT A POSITION. This used to name the exact chair you sat in — the
# founder was a head coach, the ex-player a receiver, the student an offensive
# coordinator — and all three symptoms came straight out of that one line: the
# founder came out with nothing but management skills, the ex-player was always
# a quarterback, and the student had the same two skills no matter how many
# times you rolled.
#
# What actually varies between these three lives is which SIDE of the whitewash
# it happened on. Where on the field is a question for the body, and the
# matcher answers it — so the ex-player is a receiver or a rusher or a safety
# depending on who he turned out to be.
func career_track(id: String) -> String:
	return String(origin(id).get("career", {}).get("track", ActorGenerator.TRACK_PLAYER))

# And for how long. The student has one or two years now rather than none: a
# career of zero years cannot be rolled, so he was the same person every time —
# which is not a scenario, it is a constant.
func career_years(id: String, rng: RandomNumberGenerator) -> int:
	var career: Dictionary = origin(id).get("career", {})
	return rng.randi_range(int(career.get("years_min", 0)), int(career.get("years_max", 0)))

# PRESIDENT, WHATEVER THE SCENARIO. It is the one chair that is not a job on the
# sideline: the president is the person the club answers to, which is what being
# the player means. Head coach, coordinator, scout — those are jobs you HAND OUT,
# including back to yourself, and the roster screen is where that happens.
#
# It used to be head_coach for two of the three, and that quietly made you a
# member of your own technical staff — one of four or five people competing for
# a chair, in a club you are supposed to own.
func chair(id: String) -> String:
	return String(origin(id).get("start", {}).get("chair", CHAIR_OF_THE_CLUB))

# The chair nobody else can take and you cannot give up.
const CHAIR_OF_THE_CLUB := "president"

# The Fundador alone. He is not drafted — there is nothing to be drafted into —
# so the club has to come from somewhere, and the only honest answer is that he
# names it, picks the neighbourhood and chooses the colours himself. The other
# two walk into a club that already existed and do not get a vote.
func authors_club(id: String) -> bool:
	return bool(origin(id).get("start", {}).get("authors_club", false))

# What a career already did to you before the screen opened. The ex-player has
# two because he has been through more — a season that went right, a shoulder
# that did not.
func perk_points(id: String) -> int:
	return int(origin(id).get("perk_points", 1))

# Whether the club exists already or you are the reason it exists.
func founds_a_club(id: String) -> bool:
	return bool(origin(id).get("start", {}).get("founds_club", false))

# What the squad looked like before you got there. A founded club is full of
# people who had never played; an established one is not.
func squad_rule(id: String) -> Dictionary:
	return origin(id).get("squad", {})
