# Praça — everybody without a club, and the only place people come from.
#
# Decision 14 said the Praça is where unclubbed actors wait to be invited, and
# until now that was a sentence in the roadmap: squads were conjured inside the
# club that needed them. So there was no market, no pressure, and no answer to
# "where did this person come from" other than "the club invented him".
#
# Now it is the source. Actors spawn here, clubs draft out of here, and people
# who stop being wanted come back here. The player is one of them — which is
# what makes a career start the same event as any other signing.
#
# IT HAS TO STAY WARM. The Elifoot failure mode is a pool that only fills: once
# every club is full nobody bids, the price floor vanishes and the economy is
# over. A hot Praça means clubs are hunting; a cold one means they are full and
# people are about to start leaving. The KPIs exist so that is visible weeks
# before it matters, instead of being discovered five seasons in.
class_name Praca
extends Record

var world_seed: int = 0
var people: Array[Actor] = []

static func make(seed_value: int) -> Praca:
	var praca := Praca.new()
	praca.world_seed = seed_value
	return praca

func size() -> int:
	return people.size()

func add(actor: Actor) -> void:
	if actor == null or people.has(actor):
		return
	actor.set_team(Actor.NO_TEAM)
	people.append(actor)

# Taken by a club. Returns false when somebody else got there first, which is
# what keeps two clubs from signing the same person.
func take(actor: Actor) -> bool:
	var index: int = people.find(actor)
	if index < 0:
		return false
	people.remove_at(index)
	return true

func take_at(index: int) -> Actor:
	if index < 0 or index >= people.size():
		return null
	var actor: Actor = people[index]
	people.remove_at(index)
	return actor

# --- The KPIs ---
#
# Three numbers, on purpose. The signature of a cold Praça is the median age
# climbing while nobody is taken: the pool ages in place and the good ones are
# long gone. The fourth number — how fast people leave — needs weeks to happen
# in, so it belongs with the living Praça and not here.

func median_age() -> int:
	if people.is_empty():
		return 0
	var ages: Array[int] = []
	for actor: Actor in people:
		ages.append(actor.age())
	ages.sort()
	return ages[ages.size() / 2]

func median_overall() -> int:
	if people.is_empty():
		return 0
	var marks: Array[int] = []
	for actor: Actor in people:
		marks.append(actor.overall())
	marks.sort()
	return marks[marks.size() / 2]

# Where this pool sits on the world ladder. The one that answers "is there
# anybody worth signing out there", which median Geral cannot: Geral at this
# tier never leaves the twenties, and the level is the ruler the draft itself
# compares clubs against.
func median_level() -> float:
	if people.is_empty():
		return 0.0
	var levels: Array[float] = []
	for actor: Actor in people:
		levels.append(float(actor.data.get("level", 1.0)))
	levels.sort()
	return levels[levels.size() / 2]

# --- Memento ---

func to_snapshot() -> Dictionary:
	var rows: Array = []
	for actor: Actor in people:
		rows.append({
			"thing_id": actor.thing_id,
			"ancestor": actor.ancestor,
			"data": actor.data.duplicate(true),
		})
	return {"seed": world_seed, "people": rows}

func from_snapshot(state: Dictionary) -> void:
	world_seed = int(state.get("seed", 0))
	people.clear()
	for raw: Variant in (state.get("people", []) as Array):
		var entry: Dictionary = raw as Dictionary
		var actor := Actor.new()
		actor._apply_data(
			String(entry.get("thing_id", "")),
			String(entry.get("ancestor", "actor")),
			entry.get("data", {}))
		people.append(actor)
