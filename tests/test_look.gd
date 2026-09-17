# Tests for the window scaling, which had two bugs in a row that a screenshot
# describes better than any assertion did: "a small square in the middle", and
# then "everything giant and distorted, like it is zoomed".
#
# Both came from the same place — the scale being expressed in the wrong unit —
# so the arithmetic lives in pure functions now and this is the suite that pins
# it down without needing a monitor.
extends RefCounted
class_name TestLook

func tests() -> Array:
	return [
		"test_every_common_monitor_gets_a_whole_step",
		"test_the_canvas_never_drops_below_the_design_minimum",
		"test_the_window_is_scaled_by_the_stretch_and_nothing_else",
		"test_the_body_ladder_lands_on_the_font_grid",
	]

# The reason the design canvas is 1280x720 at all: so the common monitors each
# pick up a whole step instead of being stuck at 1x.
func test_every_common_monitor_gets_a_whole_step(t: TestHelper) -> void:
	var wanted: Dictionary = {
		Vector2i(1366, 768): 1,
		Vector2i(1920, 1080): 1,
		Vector2i(2560, 1440): 2,
		Vector2i(3440, 1440): 2,
		Vector2i(3840, 2160): 3,
	}
	for size: Vector2i in wanted.keys():
		t.equal(Look.scale_for(size), int(wanted[size]),
			"%dx%d deveria dar %dx" % [size.x, size.y, int(wanted[size])])

# ⚠️ THE INVARIANT THAT MATTERS. The canvas times the scale has to be the window,
# or the content is being stretched by something other than a whole number — and
# that is exactly what "gigante e distorcido" looked like.
func test_the_canvas_never_drops_below_the_design_minimum(t: TestHelper) -> void:
	for size: Vector2i in [Vector2i(1366, 768), Vector2i(1920, 1080),
			Vector2i(2560, 1440), Vector2i(3440, 1440), Vector2i(3840, 2160),
			Vector2i(1280, 720), Vector2i(800, 600)]:
		var scale: int = Look.scale_for(size)
		var canvas: Vector2i = Look.canvas_for(size)
		t.check(scale >= 1, "%dx%d deu escala %d" % [size.x, size.y, scale])
		t.check(canvas.x >= Look.DESIGN_MIN.x or size.x < Look.DESIGN_MIN.x,
			"canvas %d menor que o mínimo de projeto em %dx%d" % [canvas.x, size.x, size.y])
		# Whole-number stretch on both axes, give or take the truncation of an
		# odd pixel — that is the whole promise.
		t.check(absi(canvas.x * scale - size.x) < scale,
			"%dx%d: canvas %d x escala %d não fecha a janela" %
				[size.x, size.y, canvas.x, scale])
		t.check(absi(canvas.y * scale - size.y) < scale,
			"%dx%d: canvas %d x escala %d não fecha a janela" %
				[size.y, size.y, canvas.y, scale])

# `content_scale_size` and `content_scale_factor` MULTIPLY, and setting both is
# what turned a 2x picture into a 4x one. The factor must come out of fit_window
# at exactly one, forever.
func test_the_window_is_scaled_by_the_stretch_and_nothing_else(t: TestHelper) -> void:
	var window: Window = (Engine.get_main_loop() as SceneTree).get_root()
	if window == null:
		t.fail("sem janela"); return
	Look.fit_window()
	t.check(is_equal_approx(window.content_scale_factor, 1.0),
		"content_scale_factor saiu em %.2f — ele MULTIPLICA o stretch" %
			window.content_scale_factor)
	t.equal(window.content_scale_mode, Window.CONTENT_SCALE_MODE_CANVAS_ITEMS,
		"modo de escala")
	t.check(window.content_scale_size.x > 0, "canvas vazio")

# The sizes are read off the fonts, not chosen: Pixel Code has 112 units per
# design pixel on a 1008 em, so only multiples of 9 put a design pixel on a whole
# screen pixel. Anything else renders with stems that alternate width.
func test_the_body_ladder_lands_on_the_font_grid(t: TestHelper) -> void:
	for size: int in [Look.MICRO, Look.TEXT, Look.SMALL, Look.TINY, Look.LEAD]:
		t.equal(size % 9, 0, "corpo %d não cai na grade de 9 da Pixel Code" % size)
	# And VT323 only puts its baseline on a whole pixel at multiples of five.
	for size: int in [Look.TITLE, Look.PLATE, Look.HEADING, Look.BIG]:
		t.equal(size % 5, 0, "display %d não cai no múltiplo de 5 da VT323" % size)
