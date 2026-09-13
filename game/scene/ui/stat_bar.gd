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
const SLOT_SIZE := Vector2(13, 15)
const SLOT_GAP := 2

# A labelled row: name on the left, bar on the right, full description and the
# raw value on hover.
static func row(label_text: String, value: int, tooltip: String = "",
		label_width: int = 130) -> Control:
	var row_box := HBoxContainer.new()
	row_box.add_theme_constant_override("separation", 10)
	row_box.tooltip_text = _tooltip(tooltip, value)
	row_box.mouse_filter = Control.MOUSE_FILTER_STOP

	var name_label := Label.new()
	name_label.text = label_text
	name_label.custom_minimum_size = Vector2(label_width, 0)
	name_label.add_theme_font_size_override("font_size", 14)
	row_box.add_child(name_label)
	row_box.add_child(bar(value))
	return row_box

static func bar(value: int) -> Control:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", SLOT_GAP)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lit: int = clampi(int(floor(float(value) / 10.0)), 0, SLOTS)
	for i: int in range(SLOTS):
		var slot := ColorRect.new()
		slot.color = LIT if i < lit else DARK
		slot.custom_minimum_size = SLOT_SIZE
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(slot)
	return box

static func _tooltip(description: String, value: int) -> String:
	if description == "":
		return str(value)
	return "%s\n\n%d/99" % [description, value]
