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
