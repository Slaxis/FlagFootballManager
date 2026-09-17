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

# ⚠️ THESE NUMBERS COME OUT OF THE FONT FILES, NOT OUT OF TASTE. Both ladders
# were measured by reading the glyph outlines: the greatest common divisor of
# every glyph's bounding box is the size of one DESIGN PIXEL, and a font size
# where that does not land on a whole screen pixel renders with stems that
# alternate between one and two pixels wide. That is the mush.
#
# Pixel Code: 112 font units per design pixel on a 1008 em, so nine design
# pixels per em, so the crisp sizes are 9, 18, 27, 36. The first ladder here
# used 12, 14 and 16 — every one of them off the grid, and 16 in particular put
# a design pixel at 1.78 screen pixels, which is the worst case.
#
# So THE BODY HAS ONE SIZE. There is no crisp rung between 9 (too small to read
# at 1x) and 18, and inventing one is inventing the blur back. Hierarchy comes
# from colour instead, which is how these screens were already doing most of it.
const TEXT := 18
const SMALL := 18
const TINY := 18
# Available, and currently unused: the native cell. Legible at 2x on a 4K
# monitor and a squint at 1x, so reach for it only for something genuinely dense.
const MICRO := 9
const LEAD := 27

# VT323 is NOT grid-aligned — its outlines have a divisor of 4 on a 1000 em, so
# it is a smooth face imitating a CRT rather than a pixel font. No size makes its
# stems perfectly even; with antialiasing off it still renders hard-edged, and at
# display sizes the unevenness is what a CRT looked like anyway.
#
# What it does have is a metric constraint: ascent 800 and descent -200 on a 1000
# em, so only MULTIPLES OF 5 put the baseline on a whole pixel. Off a multiple of
# five the whole line shifts half a pixel and every glyph in it softens.
const TITLE := 40
const PLATE := 30
const HEADING := 25
const BIG := 20

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
