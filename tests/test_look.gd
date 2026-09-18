# Tests for the window scaling, which had two bugs in a row that a screenshot
# described better than any assertion did: "a small square in the middle", and
# then "everything giant and distorted, like it is zoomed".
#
# Both came from the scale being expressed in the wrong unit, so the rule lives
# in a pure function now and this is the suite that pins it down without needing
# a monitor.
#
# THE RULE IS ONE TO ONE. The canvas is whatever the monitor is — one logical
# pixel per screen pixel — which is the sharpest a picture can be, because there
# is no resampling step to be sharp through. It briefly scaled by whole numbers
# off a 1280x720 canvas instead; that is also genuinely pixel-perfect and it is a
# completely different, much chunkier game.
extends RefCounted
class_name TestLook

func tests() -> Array:
	return [
		"test_the_canvas_is_the_monitor",
		"test_the_window_is_never_scaled",
		"test_the_body_ladder_lands_on_the_font_grid",
		"test_the_chrome_has_no_hue",
		"test_the_club_never_paints_the_canvas",
		"test_the_window_survives_a_black_club_and_a_white_one",
	]

const MONITORS: Array[Vector2i] = [
	Vector2i(1366, 768), Vector2i(1920, 1080), Vector2i(2560, 1440),
	Vector2i(3440, 1440), Vector2i(3840, 2160),
]

func test_the_canvas_is_the_monitor(t: TestHelper) -> void:
	for size: Vector2i in MONITORS:
		t.equal(str(Look.canvas_for(size)), str(size),
			"%dx%d deveria virar canvas idêntico" % [size.x, size.y])

# ⚠️ `content_scale_size` AND `content_scale_factor` MULTIPLY: the size is the
# logical canvas the engine already stretches to the window, and the factor is a
# multiplier on TOP of that. Setting both put the game at 4x on a monitor that
# should have been at 2x — the logical viewport collapsing to 640x360 and forms
# built for 1250 spilling off the edges.
#
# There is no legitimate reason for either to come out of fit_window as anything
# but "the window, once", and now that is written down.
func test_the_window_is_never_scaled(t: TestHelper) -> void:
	var window: Window = (Engine.get_main_loop() as SceneTree).get_root()
	if window == null:
		t.fail("sem janela"); return
	# Must survive having no display at all, which is how the suite runs.
	Look.fit_window()
	t.check(is_equal_approx(window.content_scale_factor, 1.0),
		"content_scale_factor saiu em %.2f — ele MULTIPLICA o stretch" %
			window.content_scale_factor)

	# ⚠️ Headless has no window: `window_get_size()` reports 0x0 and fit_window
	# returns early rather than setting a canvas of nothing. The factor claim
	# above is the half that still holds there, and it is the half that broke.
	var have: Vector2i = DisplayServer.window_get_size()
	if have.x <= 0 or have.y <= 0:
		return
	t.equal(str(window.content_scale_size), str(have),
		"o canvas deveria ser a própria janela")
	t.equal(window.content_scale_mode, Window.CONTENT_SCALE_MODE_CANVAS_ITEMS,
		"modo de escala")

# The sizes are read off the fonts, not chosen. Pixel Code has 112 units per
# design pixel on a 1008 em, so only multiples of 9 put a design pixel on a whole
# screen pixel; anything else renders with stems that alternate width. VT323 is
# not grid-aligned at all, but its ascent and descent (800 / -200 on a 1000 em)
# only land on a whole pixel at multiples of five.
func test_the_body_ladder_lands_on_the_font_grid(t: TestHelper) -> void:
	for size: int in [Look.MICRO, Look.TEXT, Look.SMALL, Look.TINY, Look.LEAD]:
		t.equal(size % 9, 0, "corpo %d não cai na grade de 9 da Pixel Code" % size)
	for size: int in [Look.TITLE, Look.PLATE, Look.HEADING, Look.BIG]:
		t.equal(size % 5, 0, "display %d não cai no múltiplo de 5 da VT323" % size)


# ⚠️ NEUTRAL MEANS R = G = B, and "dark navy" and "dark grey" are
# indistinguishable in a sentence. The decision said grey and the constants
# stayed blue for months — blue at 2.4x the red — because the only way to tell
# is to subtract the channels, which no code review does by eye.
#
# It matters beyond taste: the chrome is what every coloured thing in the game
# is drawn ON, and a background with a temperature makes every chakra, every
# talent and every club argue with it before saying what it came to say.
const HUE_TOLERANCE := 0.012

func test_the_chrome_has_no_hue(t: TestHelper) -> void:
	var chrome: Dictionary = {
		"CANVAS": Look.CANVAS, "PANEL": Look.PANEL, "WELL": Look.WELL,
		"LINE": Look.LINE, "INK": Look.INK, "MUTED": Look.MUTED,
		"ACCENT": Look.ACCENT, "ON_ACCENT": Look.ON_ACCENT,
	}
	for name: String in chrome.keys():
		var c: Color = chrome[name]
		var spread: float = maxf(maxf(c.r, c.g), c.b) - minf(minf(c.r, c.g), c.b)
		t.check(spread <= HUE_TOLERANCE,
			"%s tem matiz: r %.3f g %.3f b %.3f (espalhamento %.3f)" % [
				name, c.r, c.g, c.b, spread])
	# And the page is genuinely dark, not merely darkish.
	t.check(TeamColors.luminance(Look.CANVAS) < 0.05,
		"o canvas não é quase preto (luminância %.3f)" % TeamColors.luminance(Look.CANVAS))

# Pairs on purpose: the two extremes are real clubs. Vasco is black on white and
# América is white on red, and each of them breaks a different naive rule.
const CLUBS: Array[Array] = [
	["#000000", "#ffffff"], ["#ffffff", "#000000"], ["#ffd700", "#00703c"],
	["#7a1f2b", "#ffffff"], ["#0a0a0a", "#c8102e"], ["#f2f2f2", "#1b1b1b"],
]

func _club(pair: Array) -> Dictionary:
	return {"id": "t", "name": "T", "colors": [String(pair[0]), String(pair[1])]}

# THE CLUB DRESSES THE WINDOWS, NOT THE MONITOR. It used to be the page itself,
# which is how a yellow club made its own athlete card unreadable — eight
# chakra hues drawn on yellow, and not one of them anybody's mistake.
func test_the_club_never_paints_the_canvas(t: TestHelper) -> void:
	for pair: Array in CLUBS:
		var scheme: Dictionary = Look.club_scheme(_club(pair))
		t.equal(scheme["canvas"], Look.CANVAS,
			"o clube %s pintou a página" % str(pair))
		t.equal(scheme["plate"], TeamColors.of(_club(pair))["plate"],
			"a janela perdeu a cor de fundo escolhida pelo clube")

# ⚠️ THE CASE THAT BREAKS EVERY NAIVE RULE. `TeamColors` promises the plate and
# the ink contrast with EACH OTHER and says nothing about either against black,
# so "use the plate for the border" gives a black border on a black page for one
# club and "use the ink" gives it for the other. `signal` picks whichever of the
# two survives, and this is the test that proves both directions.
const SIGNAL_MIN_CONTRAST := 3.0

func test_the_window_survives_a_black_club_and_a_white_one(t: TestHelper) -> void:
	for pair: Array in CLUBS:
		var scheme: Dictionary = Look.club_scheme(_club(pair))
		var ratio: float = TeamColors.contrast(scheme["signal"], Look.CANVAS)
		t.check(ratio >= SIGNAL_MIN_CONTRAST,
			"o clube %s ficou com contraste %.1f contra a página — a janela some"
				% [str(pair), ratio])
		# And the signal is one of the two the player actually chose, not a
		# third hue invented to solve the problem (decisão 70).
		var chosen: Dictionary = TeamColors.of(_club(pair))
		t.check(scheme["signal"] == chosen["plate"] or scheme["signal"] == chosen["ink"],
			"o clube %s recebeu um matiz que ninguém escolheu" % str(pair))
