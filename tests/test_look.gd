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
