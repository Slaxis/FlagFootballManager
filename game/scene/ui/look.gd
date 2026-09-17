# Look — the two fonts and the size ladder, in one place.
#
# A game that is 100% panel has no sprite to carry the mood, so the FONT is the
# mood. Two terminals, on purpose: Elifoot was a DOS game, and a CRT face says
# "sport sim you keep a notebook next to" before a single word is read.
#
#   display   VT323 — the DEC VT320 character matrix. Titles, the big age
#             number, club plates. Tall and narrow, unmistakably a monitor.
#   body      Pixel Code — pixel MONOSPACE. Tables, labels, the draft log.
#             Monospace is not a taste here: half this game is a column of
#             numbers, and monospace aligns them for free.
#
# ⚠️ PIXEL FONTS GO TO MUSH UNDER ANTIALIASING. Three settings blur them and all
# three are on by default — antialiasing, hinting, and subpixel positioning. The
# loader turns them off the moment the face is loaded, which works because
# `load()` caches: one mutation, every screen.
#
# ⚠️ THE SIZES ARE A LADDER, NOT A RANGE. A pixel face is only crisp at whole
# steps of the grid it was drawn on, so a size between two rungs is a size that
# looks soft for no reason. Pick a rung. If you need something in between, the
# answer is a different rung.
# ⚠️ NOT `Skin`: Godot owns that one (it is the skeleton-binding resource), and a
# `class_name Skin` is a parse error the moment anything loads. Same trap the
# library's reserved-name list exists for.
class_name Look

const DISPLAY_PATH := "res://game/asset/font/vt323.ttf"
const BODY_PATH := "res://game/asset/font/pixel_code.ttf"

# VT323 is drawn tall and reads a size or two smaller than it measures, which is
# why the display rungs sit above the body ones.
const TITLE := 40
const HEADING := 28
const PLATE := 32
const BIG := 22

# Pixel Code at 16 is one glyph cell; 12 is the smallest that still has a
# readable cedilla, which is the real floor in Portuguese.
const TEXT := 16
const SMALL := 14
const TINY := 12

static var _display: FontFile = null
static var _body: FontFile = null

static func display() -> FontFile:
	if _display == null:
		_display = _crisp(DISPLAY_PATH)
	return _display

static func body() -> FontFile:
	if _body == null:
		_body = _crisp(BODY_PATH)
	return _body

static func _crisp(path: String) -> FontFile:
	var font := load(path) as FontFile
	if font == null:
		Log.log(null, "error", "Look: font '%s' not found" % path)
		return null
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.hinting = TextServer.HINTING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	font.generate_mipmaps = false
	return font

# --- Applying ---
#
# Screens build their controls in code, so these are the two calls that replace
# a hand-written `add_theme_font_override` everywhere.

static func wear_display(control: Control, size: int) -> void:
	var font: FontFile = display()
	if font == null:
		return
	control.add_theme_font_override(_font_slot(control), font)
	control.add_theme_font_size_override(_size_slot(control), size)

static func wear_body(control: Control, size: int) -> void:
	var font: FontFile = body()
	if font == null:
		return
	control.add_theme_font_override(_font_slot(control), font)
	control.add_theme_font_size_override(_size_slot(control), size)

# RichTextLabel names its theme items differently from everything else, which is
# the sort of thing that silently does nothing until you look closely at a log
# that is still in the default face.
static func _font_slot(control: Control) -> String:
	return "normal_font" if control is RichTextLabel else "font"

static func _size_slot(control: Control) -> String:
	return "normal_font_size" if control is RichTextLabel else "font_size"

# The project-wide default, so a control nobody dressed still comes out in the
# right face instead of in Godot's sans.
static func theme() -> Theme:
	var built := Theme.new()
	built.default_font = body()
	built.default_font_size = TEXT
	return built
