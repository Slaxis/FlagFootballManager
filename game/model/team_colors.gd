# TeamColors — the Elifoot look: a club's name is printed in its own colours,
# so you recognise the row before you finish reading the name. Flamengo was
# red on black, and you knew it was Flamengo from across the room.
#
# Convention: `colors[0]` is the club's primary (the ink), `colors[1]` the
# secondary (the plate). But a club whose two colours are white and pale blue
# would render an unreadable row, so the pairing is checked for contrast and
# repaired before it reaches the screen — the look is never worth an
# illegible name.
class_name TeamColors

# WCAG contrast ratio below which we intervene. 4.5 is the AA threshold for
# body text; 3.0 is the large-text one, and club names render large and bold.
const MIN_CONTRAST := 3.0

const _FALLBACK_PLATE := Color(0.16, 0.16, 0.16)
const _INK_LIGHT := Color(0.96, 0.96, 0.96)
const _INK_DARK := Color(0.08, 0.08, 0.08)

# Returns { "plate": Color, "ink": Color } ready to paint.
static func of(team: Dictionary) -> Dictionary:
	var raw: Array = team.get("colors", [])
	var primary: Color = _parse(raw, 0, _INK_LIGHT)
	var secondary: Color = _parse(raw, 1, _FALLBACK_PLATE)

	# Preferred reading: primary is the ink, secondary the plate.
	if contrast(primary, secondary) >= MIN_CONTRAST:
		return {"plate": secondary, "ink": primary}
	# Some clubs are declared the other way round; try the swap before giving up.
	if contrast(secondary, primary) >= MIN_CONTRAST:
		return {"plate": primary, "ink": secondary}
	# Both pairings are mud. Do NOT throw the club's colour away — keep the hue
	# and push its brightness until it reads. Flag Kings' crimson on near-black
	# fails the raw check, and replacing it with white would erase exactly the
	# identity this whole feature exists to show.
	return {"plate": secondary, "ink": legible_against(primary, secondary)}

# Same hue and saturation, brightness moved until the pair clears MIN_CONTRAST.
# Falls back to flat black or white only if even the extreme fails.
static func legible_against(ink: Color, plate: Color) -> Color:
	var lighten: bool = luminance(plate) <= 0.4
	var adjusted: Color = ink
	for step: int in range(1, 21):
		var amount: float = float(step) * 0.05
		adjusted = ink.lightened(amount) if lighten else ink.darkened(amount)
		if contrast(adjusted, plate) >= MIN_CONTRAST:
			return adjusted
	return readable_ink(plate)

static func contrast(a: Color, b: Color) -> float:
	var la: float = luminance(a)
	var lb: float = luminance(b)
	var lighter: float = maxf(la, lb)
	var darker: float = minf(la, lb)
	return (lighter + 0.05) / (darker + 0.05)

# WCAG relative luminance.
static func luminance(color: Color) -> float:
	return 0.2126 * _channel(color.r) + 0.7152 * _channel(color.g) + 0.0722 * _channel(color.b)

static func readable_ink(plate: Color) -> Color:
	return _INK_DARK if luminance(plate) > 0.4 else _INK_LIGHT

# --- Internals ---

static func _channel(value: float) -> float:
	return value / 12.92 if value <= 0.03928 else pow((value + 0.055) / 1.055, 2.4)

static func _parse(raw: Array, index: int, fallback: Color) -> Color:
	if raw.size() <= index:
		return fallback
	var text: String = String(raw[index]).strip_edges()
	return Color(text) if text != "" and Color.html_is_valid(text) else fallback
