# TeamColors — the Elifoot look: a club's screen is printed in its own two
# colours, so you know whose turn it is before you read a word. Flamengo was red
# and black, and you knew it was Flamengo from across the room.
#
# ⚠️ CONVENTION: `colors[0]` is the BACKGROUND and `colors[1]` is the LETTERING.
#
# It used to be the other way round — primary as the ink, secondary as the plate
# — and worse, it would SWAP the two when the pairing failed a contrast check.
# Both of those quietly overrule the person who chose the colours. Somebody
# picking yellow for the background and green for the letters got a mustard
# screen with no green in it, because yellow had been made the lettering, then
# swapped, then the green was replaced outright.
#
# The player's choice is not a suggestion. The background is the background; if
# the lettering does not read on it, only the lettering moves, and only its
# BRIGHTNESS moves — dark green on yellow is still green, and that is the whole
# point of letting somebody choose green.
class_name TeamColors

# WCAG contrast ratio below which we intervene. 4.5 is the AA threshold for
# body text; 3.0 is the large-text one, and club names render large and bold.
const MIN_CONTRAST := 3.0

const _FALLBACK_PLATE := Color(0.16, 0.16, 0.16)
const _INK_LIGHT := Color(0.96, 0.96, 0.96)
const _INK_DARK := Color(0.08, 0.08, 0.08)

# Returns { "plate": Color, "ink": Color } ready to paint — the background and
# the lettering, in that order, as chosen.
static func of(team: Dictionary) -> Dictionary:
	var raw: Array = team.get("colors", [])
	var background: Color = _parse(raw, 0, _FALLBACK_PLATE)
	var lettering: Color = _parse(raw, 1, _INK_LIGHT)
	if contrast(lettering, background) >= MIN_CONTRAST:
		return {"plate": background, "ink": lettering}
	# NO SWAPPING. The background stays the background — the only thing that may
	# move is how bright the lettering is, and it keeps its hue while it moves.
	return {"plate": background, "ink": legible_against(lettering, background)}

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
