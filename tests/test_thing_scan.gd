# Tests for how the engine finds Things on disk.
#
# The point of the scan is that FOLDER LAYOUT IS CONVENTION. A curator keeping
# one file per athlete, another keeping a whole squad in one array, and a
# player's own mod organising by neighbourhood all have to merge into the same
# pool — because that is what modding a roster actually looks like, and none of
# them should have to care what the other chose.
#
# The fixture under `tests/fixtures/things/actor/` holds all four shapes at
# once, which is also the regression: before this, a loose `.json` that did not
# share its folder's name was skipped in silence.
extends RefCounted
class_name TestThingScan

const FIXTURE := "res://tests/fixtures/things/actor"

func tests() -> Array:
	return [
		"test_every_layout_is_found",
		"test_the_folder_name_is_still_a_fallback_id",
		"test_an_array_file_holds_many_things",
		"test_later_sources_override_by_id",
		"test_a_thing_without_an_id_is_refused_not_guessed",
	]

# A Def that records what it was handed, in order.
class Recorder extends Def:
	var seen: Array[Dictionary] = []

	func add_thing(thing: Dictionary) -> void:
		seen.append(thing)

	func ids() -> Array[String]:
		var out: Array[String] = []
		for entry: Dictionary in seen:
			out.append(String(entry.get("id", "")))
		return out

func _scan() -> Recorder:
	var recorder := Recorder.new()
	var manager := DefManager.new()
	manager._scan_thing_dir(recorder, FIXTURE)
	return recorder

func test_every_layout_is_found(t: TestHelper) -> void:
	var ids: Array[String] = _scan().ids()
	# solto na raiz, pasta casada, um por atleta, um array de três, e o mod
	# organizado por bairro que traz mais dois.
	for wanted: String in ["sem_pasta_nenhuma", "pasta_casada", "kings_qb",
			"kings_wr1", "kings_wr2", "kings_db1", "tijuca_livre"]:
		t.check(ids.has(wanted), "'%s' não foi encontrado pelo scan" % wanted)
	t.equal(ids.size(), 8, "quantidade de Things lidas (kings_qb aparece duas vezes)")

func test_the_folder_name_is_still_a_fallback_id(t: TestHelper) -> void:
	# The convention that predates this — `<folder>/<folder>.json` with no id
	# inside — has to keep working, or every module in every project breaks.
	var recorder: Recorder = _scan()
	var found: Dictionary = {}
	for entry: Dictionary in recorder.seen:
		if String(entry.get("id", "")) == "pasta_casada":
			found = entry
	t.check(not found.is_empty(), "a convenção antiga parou de funcionar")
	t.equal(String(found.get("team", "")), "convencao_antiga", "conteúdo do Thing")

func test_an_array_file_holds_many_things(t: TestHelper) -> void:
	var ids: Array[String] = _scan().ids()
	var from_squad: int = 0
	for id: String in ids:
		if id.begins_with("kings_wr") or id == "kings_db1":
			from_squad += 1
	t.equal(from_squad, 3, "o arquivo com o elenco inteiro não rendeu três atletas")

# Files before subdirectories, both sorted: `por_bairro/` comes after the loose
# root file and before `por_time/`, on every machine. Without a stable order,
# which version of an overridden Thing wins would depend on the filesystem.
func test_later_sources_override_by_id(t: TestHelper) -> void:
	var recorder: Recorder = _scan()
	var positions: Array[int] = []
	for i: int in range(recorder.seen.size()):
		if String(recorder.seen[i].get("id", "")) == "kings_qb":
			positions.append(i)
	t.equal(positions.size(), 2, "esperava o mesmo id vindo de duas fontes")
	t.check(positions[0] < positions[1], "ordem instável")
	# The neighbourhood mod sorts before `por_time/`, so the squad file is the
	# one that lands last and wins.
	t.equal(String(recorder.seen[positions[1]].get("note", "")), "um arquivo por atleta",
		"a última fonte não foi a que prevaleceu")

func test_a_thing_without_an_id_is_refused_not_guessed(t: TestHelper) -> void:
	# One filename cannot name three athletes, so an array entry has to carry
	# its own id. Guessing one would silently merge two people into one.
	var recorder := Recorder.new()
	var manager := DefManager.new()
	manager._ingest_thing_file(recorder, "res://tests/fixtures/things/actor/por_time/flag_kings/resto_do_elenco.json")
	for entry: Dictionary in recorder.seen:
		t.check(String(entry.get("id", "")).strip_edges() != "", "Thing sem id passou")
	t.equal(recorder.seen.size(), 3, "entradas lidas do array")
