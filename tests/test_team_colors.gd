# Tests for the Elifoot name-plate colour pairing.
extends RefCounted
class_name TestTeamColors

func tests() -> Array:
	return [
		"test_primary_is_ink_secondary_is_plate",
		"test_swaps_when_declared_order_is_unreadable",
		"test_forces_readable_ink_when_both_pairings_are_mud",
		"test_repair_keeps_the_hue",
		"test_missing_colors_do_not_crash",
		"test_every_club_in_the_module_is_readable",
	]

func _team(colors: Array) -> Dictionary:
	return {"id": "t", "name": "T", "colors": colors}

# Flamengo: red ink on a black plate, exactly the Elifoot memory.
func test_primary_is_ink_secondary_is_plate(t: TestHelper) -> void:
	var scheme: Dictionary = TeamColors.of(_team(["#e2231a", "#000000"]))
	t.equal(scheme["ink"], Color("#e2231a"), "tinta")
	t.equal(scheme["plate"], Color("#000000"), "chapa")

# Two dark colours in the declared order would be mud, but flipped they read.
func test_swaps_when_declared_order_is_unreadable(t: TestHelper) -> void:
	var scheme: Dictionary = TeamColors.of(_team(["#111111", "#f0f0f0"]))
	t.check(TeamColors.contrast(scheme["ink"], scheme["plate"]) >= TeamColors.MIN_CONTRAST,
		"deveria ter invertido para ficar legível")

func test_forces_readable_ink_when_both_pairings_are_mud(t: TestHelper) -> void:
	# Two near-identical pale colours: no ordering saves this pairing.
	var scheme: Dictionary = TeamColors.of(_team(["#ffffff", "#fafafa"]))
	t.check(TeamColors.contrast(scheme["ink"], scheme["plate"]) >= TeamColors.MIN_CONTRAST,
		"deveria ter forçado tinta legível, veio contraste %.2f" %
			TeamColors.contrast(scheme["ink"], scheme["plate"]))

# The repair must keep the club's identity, not replace it with white. Flag
# Kings' crimson on near-black is the real case that motivated this.
func test_repair_keeps_the_hue(t: TestHelper) -> void:
	var crimson := Color("#c41e3a")
	var scheme: Dictionary = TeamColors.of(_team(["#c41e3a", "#1a1a1a"]))
	var ink: Color = scheme["ink"]
	t.check(TeamColors.contrast(ink, scheme["plate"]) >= TeamColors.MIN_CONTRAST,
		"não ficou legível")
	t.check(absf(ink.h - crimson.h) < 0.05,
		"perdeu o matiz do clube: %.3f virou %.3f" % [crimson.h, ink.h])
	t.check(ink.s > 0.4, "desbotou a cor do clube: saturação %.2f" % ink.s)

func test_missing_colors_do_not_crash(t: TestHelper) -> void:
	for colors: Array in [[], ["#ff0000"], ["nao-e-cor", ""]]:
		var scheme: Dictionary = TeamColors.of(_team(colors))
		t.check(scheme.has("ink") and scheme.has("plate"), "esquema incompleto para %s" % str(colors))
		t.check(TeamColors.contrast(scheme["ink"], scheme["plate"]) >= TeamColors.MIN_CONTRAST,
			"cores faltando deveriam cair num par legível: %s" % str(colors))

# The guard exists for the real roster, not for synthetic cases — so assert it
# on every club the module actually ships.
func test_every_club_in_the_module_is_readable(t: TestHelper) -> void:
	var def := Drive.def("team") as TeamDef
	if def == null:
		t.fail("TeamDef ausente"); return
	t.check(def.all().size() > 0, "nenhum clube carregado")
	for team: Dictionary in def.all():
		var scheme: Dictionary = TeamColors.of(team)
		var ratio: float = TeamColors.contrast(scheme["ink"], scheme["plate"])
		t.check(ratio >= TeamColors.MIN_CONTRAST,
			"'%s' ficaria ilegível: contraste %.2f" % [team.get("name", team.get("id", "?")), ratio])
