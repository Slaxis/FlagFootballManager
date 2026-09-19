# StatBar — a ten-slot segmented bar, Project Zomboid style.
#
# Attributes are 0..99 internally because the derived formulas need the
# resolution, but a manager reading a roster does not want to compare 61 to 58.
# Ten lit-or-dark slots answer "is he good at this" at a glance, and the exact
# number stays one hover away.
class_name StatBar

const SLOTS := 10
const LIT := Color(0.49, 0.78, 0.45)
const DARK := Color(0.12, 0.21, 0.14)
# Where the gradient starts: a grey that reads as off, not as dark green.
const UNLIT_TEXT := Color(0.38, 0.40, 0.38)
# ⚠️ TEN WIDE, NOT THIRTEEN. Ten slots and nine gaps is the widest single item in
# every attribute and skill row — 148px at thirteen, against a row that has to
# fit twice over inside half a screen. At ten it is 118, and a solid rectangle
# loses nothing at that size the way a glyph would: there is no shape to read,
# only how many are lit.
const SLOT_SIZE := Vector2(10, 15)
const SLOT_GAP := 2

# A labelled row: name on the left, bar on the right, full description and the
# raw value on hover.
static func row(label_text: String, value: int, tooltip: String = "",
		label_width: int = 130, hue: Color = LIT) -> Control:
	var row_box := HBoxContainer.new()
	row_box.add_theme_constant_override("separation", 10)
	row_box.tooltip_text = _tooltip(tooltip, value)
	row_box.mouse_filter = Control.MOUSE_FILTER_STOP

	var name_label := Label.new()
	name_label.text = label_text
	name_label.add_theme_color_override("font_color", hue.lightened(0.25))
	name_label.custom_minimum_size = Vector2(label_width, 0)
	name_label.add_theme_font_size_override("font_size", 14)
	# Without this a long label ("Chamada de jogada") sets the row's minimum
	# width and shoves the whole panel open. The full name is on the tooltip
	# that this row already carries.
	name_label.clip_text = true
	row_box.add_child(name_label)
	row_box.add_child(bar(value, hue))
	return row_box

# ⚠️ A BAR AND A GAUGE ARE NOT THE SAME CONTROL, and shipping the first where
# the second belonged made five pools look identical on every roll.
#
# `bar()` draws a FRACTION: ten slots, lit in proportion. That is right for an
# attribute, where the only number is the value. It is wrong for a pool, because
# a pool has TWO numbers and nothing drains it yet — so `now == max`, every bar
# came out at a hundred per cent, and the ceiling (which varies from 4 to 11 on
# the same attribute) was the thing being hidden.
#
# A gauge has three states, which is how every HP bar ever drawn works:
#
#   lit       up to `now`             — what you have
#   empty     up to `top`             — what you could have and do not
#   absent    beyond `top`            — bar you were never given
#
# The length is the ceiling and the fill is the present. Roll a stronger body
# and the bar gets LONGER, which is the thing the player is choosing.
static func gauge(now: int, top: int, scale: int, hue: Color = LIT) -> Control:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", SLOT_GAP)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var reach: int = SLOTS if scale <= 0 else clampi(
		int(round(float(top) * float(SLOTS) / float(scale))), 1, SLOTS)
	var full: int = 0 if top <= 0 else clampi(
		int(round(float(now) * float(reach) / float(top))), 0, reach)
	for i: int in range(SLOTS):
		var slot := ColorRect.new()
		if i < full:
			slot.color = hue
		elif i < reach:
			slot.color = hue.darkened(0.72)
		else:
			# Not "empty" — ABSENT. Almost the background, so a short bar reads
			# as a short bar rather than as a long one that is switched off.
			slot.color = hue.darkened(0.93)
		slot.custom_minimum_size = SLOT_SIZE
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(slot)
	return box

# A row whose bar is a gauge. Same shape as `row()`, which is what lets the card
# and the creation sheet put pools and attributes in one column each.
static func gauge_row(label_text: String, now: int, top: int, scale: int,
		tooltip: String = "", label_width: int = 130, hue: Color = LIT) -> Control:
	var row_box := HBoxContainer.new()
	row_box.add_theme_constant_override("separation", 10)
	row_box.tooltip_text = tooltip
	row_box.mouse_filter = Control.MOUSE_FILTER_STOP
	var name_label := Label.new()
	name_label.text = label_text
	name_label.add_theme_color_override("font_color", hue.lightened(0.25))
	name_label.custom_minimum_size = Vector2(label_width, 0)
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.clip_text = true
	row_box.add_child(name_label)
	row_box.add_child(gauge(now, top, scale, hue))
	return row_box

# The same 0..100 reading as the bar, as a single colour: dead grey at the
# bottom, LIT AT THE TOP IN WHATEVER HUE YOU ASK FOR. A column of numbers
# tinted this way sorts itself — the bad ones read as switched off and the good
# ones as switched on, without anybody parsing a digit.
#
# The hue is an argument because the team screen wears the CLUB's colours, and
# a welded-in green fought every club that is not green: the roster of a yellow
# side came out with green affinity bars sitting on a yellow ground. Grey stays
# at the bottom either way — "off" is club-neutral, and it is what makes the
# gradient read as a gradient instead of as two team colours.
static func tint(value: int, hue: Color = LIT) -> Color:
	return UNLIT_TEXT.lerp(hue, clampf(float(value) / 100.0, 0.0, 1.0))

static func bar(value: int, hue: Color = LIT) -> Control:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", SLOT_GAP)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lit: int = clampi(int(floor(float(value) / 10.0)), 0, SLOTS)
	for i: int in range(SLOTS):
		var slot := ColorRect.new()
		# The unlit half keeps the same hue, dimmed, so a row reads as one
		# colour at two intensities rather than as two unrelated colours.
		slot.color = hue if i < lit else hue.darkened(0.72)
		slot.custom_minimum_size = SLOT_SIZE
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(slot)
	return box

static func _tooltip(description: String, value: int) -> String:
	if description == "":
		return str(value)
	return "%s\n\n%d/99" % [description, value]
