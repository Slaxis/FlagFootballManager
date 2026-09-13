# Tests for the exploding die the library is named after.
#
# D5 lives in the library, which has no suite of its own — the ScrapWarriors
# boot is its canary. Covering it from here is pragmatic: this is the game that
# actually rolls dice, and an unverified die would poison every match.
extends RefCounted
class_name TestD5

const SEED := 20260909
const SAMPLES := 60000

func tests() -> Array:
	return [
		"test_is_deterministic",
		"test_mean_is_two_and_a_half",
		"test_faces_zero_and_five_never_survive",
		"test_explodes_in_both_directions",
		"test_two_dice_average_five",
		"test_check_adds_the_base",
		"test_contest_is_symmetric_when_equal",
		"test_underdog_still_wins_sometimes",
		"test_favourite_is_clearly_favoured",
	]

func _rng() -> RandomNumberGenerator:
	return SeedRng.make_rng(SEED)

func test_is_deterministic(t: TestHelper) -> void:
	var a: Array = []
	var b: Array = []
	var rng_a: RandomNumberGenerator = _rng()
	var rng_b: RandomNumberGenerator = _rng()
	for i: int in range(200):
		a.append(D5.roll(rng_a))
		b.append(D5.roll(rng_b))
	t.equal(str(b), str(a), "mesma seed deveria dar a mesma sequência")

# The explosions cancel exactly, which is what keeps the die honest: it runs
# away up as readily as down.
func test_mean_is_two_and_a_half(t: TestHelper) -> void:
	var rng: RandomNumberGenerator = _rng()
	var total: int = 0
	for i: int in range(SAMPLES):
		total += D5.roll(rng)
	var mean: float = float(total) / float(SAMPLES)
	t.check(absf(mean - 2.5) < 0.08, "média do d5* veio %.3f, esperado ~2.5" % mean)

func test_faces_zero_and_five_never_survive(t: TestHelper) -> void:
	var rng: RandomNumberGenerator = _rng()
	var zeros: int = 0
	var fives: int = 0
	for i: int in range(SAMPLES):
		var value: int = D5.roll(rng)
		if value == 0:
			zeros += 1
		if value == 5:
			fives += 1
	t.equal(zeros, 0, "um 0 deveria sempre explodir para baixo")
	t.equal(fives, 0, "um 5 deveria sempre explodir para cima")

func test_explodes_in_both_directions(t: TestHelper) -> void:
	var rng: RandomNumberGenerator = _rng()
	var lowest: int = 999
	var highest: int = -999
	for i: int in range(SAMPLES):
		var value: int = D5.roll(rng)
		lowest = mini(lowest, value)
		highest = maxi(highest, value)
	t.check(highest > 5, "nunca explodiu para cima (máximo %d)" % highest)
	t.check(lowest < 0, "nunca explodiu para baixo (mínimo %d)" % lowest)

func test_two_dice_average_five(t: TestHelper) -> void:
	var rng: RandomNumberGenerator = _rng()
	var total: int = 0
	for i: int in range(SAMPLES):
		total += D5.roll_many(rng, 2)
	var mean: float = float(total) / float(SAMPLES)
	t.check(absf(mean - 5.0) < 0.12, "média de 2d5* veio %.3f, esperado ~5.0" % mean)

func test_check_adds_the_base(t: TestHelper) -> void:
	var rng: RandomNumberGenerator = _rng()
	var total: int = 0
	for i: int in range(SAMPLES):
		total += D5.check(10, rng, 2)
	var mean: float = float(total) / float(SAMPLES)
	t.check(absf(mean - 15.0) < 0.12, "base 10 + 2d5* deveria dar ~15, veio %.3f" % mean)

func test_contest_is_symmetric_when_equal(t: TestHelper) -> void:
	var rng: RandomNumberGenerator = _rng()
	var attacker: int = 0
	var defender: int = 0
	for i: int in range(SAMPLES):
		var margin: int = D5.contest(11, 11, rng)
		if margin > 0:
			attacker += 1
		elif margin < 0:
			defender += 1
	var skew: float = absf(float(attacker - defender)) / float(SAMPLES)
	t.check(skew < 0.02, "disputa entre iguais pendeu %.1f%% para um lado" % (skew * 100.0))

# A sandlot side must be able to beat the champion, or the league is a
# spreadsheet. It must not do it often, or the league is a coin toss.
func test_underdog_still_wins_sometimes(t: TestHelper) -> void:
	var rng: RandomNumberGenerator = _rng()
	var wins: int = 0
	for i: int in range(SAMPLES):
		if D5.contest(5, 16, rng) > 0:
			wins += 1
	var rate: float = 100.0 * float(wins) / float(SAMPLES)
	t.check(rate > 2.0 and rate < 12.0,
		"zebra (5 vs 16) venceu %.2f%% — fora da faixa jogável de 2%% a 12%%" % rate)

func test_favourite_is_clearly_favoured(t: TestHelper) -> void:
	var rng: RandomNumberGenerator = _rng()
	var wins: int = 0
	for i: int in range(SAMPLES):
		if D5.contest(16, 5, rng) > 0:
			wins += 1
	var rate: float = 100.0 * float(wins) / float(SAMPLES)
	t.check(rate > 85.0, "favorito (16 vs 5) só venceu %.2f%%" % rate)
