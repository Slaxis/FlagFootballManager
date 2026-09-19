extends Def
class_name NameGenDef

# Apelidos are not decoration. In Brazilian amateur sport the nickname IS the
# name — nobody at the field knows the guy's surname — so a generated one that
# has nothing to do with the person reads as filler immediately.
#
# ⚠️ TEN CATEGORIES, DRAWN UNIFORMLY — and the thing it replaced is worth
# writing down, because the numbers lied for months.
#
# It was four weighted sources: `stat` 45, `first` 25, `last` 20, `random` 10.
# Measured on six hundred sandlot athletes, what actually came out was
# morphology 62%, open pool 20%, stat 16%. The declared 45% of "what he is
# notable FOR" delivered sixteen.
#
# The cause is the fallthrough. A source that produces nothing hands the turn to
# the next one, and `stat` produces nothing when the person has no notable
# trait — which, with the threshold at seven steps on a squad that lives between
# one and three, is 63% of a sandlot league. Those forty-five points of weight
# went to the two morphology sources, which is the whole of the -inho/-ão flood:
# 45 of the remaining 55 is 82% of every roll that had nowhere else to go.
#
# So the flavourful half of the system was calibrated for a world where people
# reach step seven, and that world is the national team.
#
# Uniform across the categories that CAN produce something fixes the shape at
# the source: with ten of them the morphology is one in ten instead of six.
#
#   1 size      Grandão, Tampinha, Torre
#   2 name      morphology — Pedro -> Pedrinho, Vasconcelos -> Vasco
#   3 look      Careca, Ruivo, Canhoto
#   4 body      Perna, Cabeção, Orelha
#   5 animal    Tigre, Formiga, Gavião
#   6 trait     what he is notable FOR — Foguete, Tanque
#   7 origin    Baiano, Serrano, Japa
#   8 trade     Padeiro, Sargento, Doutor
#   9 food      Feijão, Coxinha, Farofa
#  10 compound  two of the nine above — Thiago Perna, Feijão Ruivo
#
# The morphology is the real Portuguese rule (drop an unstressed final vowel
# and add -inho, otherwise add -zinho) with the orthographic repair that keeps
# the consonant hard: Luc + inho would sound "Lussinho", so it becomes
# Luquinho. It is deliberately NOT a complete grammar — a minority of names
# come out slightly off-register, which at the sandlot is indistinguishable
# from how apelidos actually work.

const VOWELS := "aeiouáàâãéêíóôõúü"
# Falling diphthongs: a vowel plus an i/u glide is ONE syllable nucleus, so
# "Caio" must not be cut into "Cai" and "Paulo" not into "Pau".
const GLIDES := "iuíú"
const NASALS := "ãõ"
# A final vowel that carries the stress refuses to be dropped — João is not
# "Joinho".
const SOFT_ENDINGS := "aeoi"
const LIQUIDS := "lrmnz"
const TRAILING_CONSONANTS := "slrzmn"

const DIR_HIGH := "high"
const DIR_LOW := "low"

const MIN_SHORT := 3
const MAX_SHORT := 6

# The three categories that are COMPUTED rather than drawn from a list. Every
# other one is a pool in the catalogue, which is what lets a module add a tenth
# bucket of its own without touching this file.
const KIND_MORPHOLOGY := "morphology"
const KIND_TRAIT := "trait"
const KIND_COMPOUND := "compound"

# Kept so an older module that still declares the four weighted sources loads
# without exploding; nothing reads them any more.
const SOURCE_STAT := "stat"
const SOURCE_FIRST := "first"
const SOURCE_LAST := "last"
const SOURCE_RANDOM := "random"
const SOURCES: Array[String] = [SOURCE_STAT, SOURCE_FIRST, SOURCE_LAST, SOURCE_RANDOM]

var first_male: Array[String] = []
var first_female: Array[String] = []
var last_names: Array[String] = []
var nicknames_male: Array[String] = []
var nicknames_female: Array[String] = []
var team_prefixes: Array[String] = []
var team_suffixes: Array[String] = []
var neighborhoods: Array[String] = []
var street_patterns: Array[String] = []
var place_patterns: Array[String] = []
var team_patterns: Array[String] = []

var nickname_weights: Dictionary = {}
# One entry per category: {"id", "kind"} or {"id", "pool", "fem"}.
var nickname_categories: Array = []
var suffixes_male: Array[String] = []
var suffixes_female: Array[String] = []
# One entry per (stat, direction): {"stat", "dir", "pool", "fem"}.
var stat_nicknames: Array = []

func load_data(raw: Dictionary) -> void:
	first_male       = _load_strings(raw.get("first_male", []))
	first_female     = _load_strings(raw.get("first_female", []))
	last_names       = _load_strings(raw.get("last", []))
	nicknames_male   = _load_strings(raw.get("nicknames_male", []))
	nicknames_female = _load_strings(raw.get("nicknames_female", []))
	team_prefixes    = _load_strings(raw.get("team_prefixes", []))
	team_suffixes    = _load_strings(raw.get("team_suffixes", []))
	neighborhoods    = _load_strings(raw.get("neighborhoods", []))
	street_patterns  = _load_strings(raw.get("street_patterns", []))
	place_patterns   = _load_strings(raw.get("place_patterns", []))
	team_patterns    = _load_strings(raw.get("team_patterns", []))
	nickname_weights = raw.get("nickname_weights", {})
	nickname_categories = raw.get("nickname_categories", []).duplicate()
	var suffixes: Dictionary = raw.get("nickname_suffixes", {})
	suffixes_male    = _load_strings(suffixes.get("masc", []))
	suffixes_female  = _load_strings(suffixes.get("fem", []))
	stat_nicknames   = (raw.get("stat_nicknames", []) as Array).duplicate(true)

# A module hosts its own vocabulary as a Thing under
# `content/things/name_gen/<id>/<id>.json`. DefManager reads a Def's base JSON
# only from `game/defs/`, so this is the ONLY way a universe can bring its own
# neighbourhoods and club names — which is what keeps a South Park league from
# drafting teams out of Jacarepaguá.
func add_thing(thing: Dictionary) -> void:
	merge_data(thing)

func merge_data(raw: Dictionary) -> void:
	# Append rather than replace so user modules can extend the pools.
	first_male.append_array(_load_strings(raw.get("first_male", [])))
	first_female.append_array(_load_strings(raw.get("first_female", [])))
	last_names.append_array(_load_strings(raw.get("last", [])))
	nicknames_male.append_array(_load_strings(raw.get("nicknames_male", [])))
	nicknames_female.append_array(_load_strings(raw.get("nicknames_female", [])))
	team_prefixes.append_array(_load_strings(raw.get("team_prefixes", [])))
	team_suffixes.append_array(_load_strings(raw.get("team_suffixes", [])))
	neighborhoods.append_array(_load_strings(raw.get("neighborhoods", [])))
	street_patterns.append_array(_load_strings(raw.get("street_patterns", [])))
	place_patterns.append_array(_load_strings(raw.get("place_patterns", [])))
	team_patterns.append_array(_load_strings(raw.get("team_patterns", [])))
	var suffixes: Dictionary = raw.get("nickname_suffixes", {})
	suffixes_male.append_array(_load_strings(suffixes.get("masc", [])))
	suffixes_female.append_array(_load_strings(suffixes.get("fem", [])))
	stat_nicknames.append_array((raw.get("stat_nicknames", []) as Array).duplicate(true))
	# Weights are a single dial, not a pool: a module that states one replaces
	# it rather than adding a second opinion.
	nickname_weights.merge(raw.get("nickname_weights", {}), true)
	nickname_categories.append_array(raw.get("nickname_categories", []))

func _load_strings(raw: Variant) -> Array[String]:
	var out: Array[String] = []
	if not raw is Array:
		return out
	for v: Variant in (raw as Array):
		var s: String = String(v).strip_edges()
		if s != "":
			out.append(s)
	return out

# --- Public API. All methods accept a RandomNumberGenerator for determinism.

func random_first_name(gender: String, rng: RandomNumberGenerator) -> String:
	var pool: Array[String] = first_female if _is_female(gender) else first_male
	return _pick(pool, rng)

func random_last_name(rng: RandomNumberGenerator) -> String:
	return _pick(last_names, rng)

func random_nickname(gender: String, rng: RandomNumberGenerator) -> String:
	var pool: Array[String] = nicknames_female if _is_female(gender) else nicknames_male
	return _pick(pool, rng)

func random_full_name(gender: String, rng: RandomNumberGenerator) -> String:
	var first: String = random_first_name(gender, rng)
	var last: String = random_last_name(rng)
	if first == "" and last == "":
		return ""
	return (first + " " + last).strip_edges()

# --- Nicknames that mean something ---

# The entry point. `traits` is what StatDef.notable_traits() found — an ordered
# list of {stat, dir}, most extreme first, possibly empty.
#
# Tries the weighted sources in order and takes the first that produces
# anything, so a name the morphology cannot bend (João -> "Joã", rejected)
# falls through to the surname or the pool instead of returning nothing.
func nickname_for(first: String, last: String, gender: String,
		traits: Array, rng: RandomNumberGenerator) -> String:
	for id: String in _category_order(rng):
		var candidate: String = _from_category(id, first, last, gender, traits, rng)
		if candidate != "":
			return candidate
	return ""

# ⚠️ SHUFFLED, NOT PICKED ONCE. A single uniform draw that lands on a category
# with nothing to give would return an empty apelido — and with `trait` silent
# for two thirds of a sandlot squad that is a lot of nobody. Walking a shuffled
# order keeps the draw uniform AMONG THE ONES THAT CAN ANSWER, which is what was
# actually wanted, without having to ask each one twice.
func _category_order(rng: RandomNumberGenerator) -> Array[String]:
	var out: Array[String] = []
	for entry: Variant in nickname_categories:
		if entry is Dictionary:
			var id: String = _key(String((entry as Dictionary).get("id", "")))
			if id != "":
				out.append(id)
	for i: int in range(out.size() - 1, 0, -1):
		var j: int = rng.randi() % (i + 1)
		var swap: String = out[i]
		out[i] = out[j]
		out[j] = swap
	return out

func _category(id: String) -> Dictionary:
	for entry: Variant in nickname_categories:
		if entry is Dictionary and _key(String((entry as Dictionary).get("id", ""))) == _key(id):
			return entry as Dictionary
	return {}

func _from_category(id: String, first: String, last: String, gender: String,
		traits: Array, rng: RandomNumberGenerator) -> String:
	var spec: Dictionary = _category(id)
	match String(spec.get("kind", "")):
		KIND_MORPHOLOGY:
			# Either name, so the morphology category is one bucket and not two.
			var from_first: String = name_nickname(first, gender, rng)
			var from_last: String = name_nickname(last, gender, rng)
			if from_first != "" and from_last != "":
				return from_first if rng.randf() < 0.5 else from_last
			return from_first if from_first != "" else from_last
		KIND_TRAIT:
			return stat_nickname(traits, gender, rng)
		KIND_COMPOUND:
			return _compound(first, last, gender, traits, rng)
	return _pick(_category_pool(spec, gender), rng)

# Two apelidos from two DIFFERENT categories, joined: Thiago Perna, Feijão
# Ruivo. It draws from the same nine — never from itself, or a compound could
# nest into a sentence.
const COMPOUND_PARTS := 2

func _compound(first: String, last: String, gender: String,
		traits: Array, rng: RandomNumberGenerator) -> String:
	var parts: Array[String] = []
	for id: String in _category_order(rng):
		if String(_category(id).get("kind", "")) == KIND_COMPOUND:
			continue
		var piece: String = _from_category(id, first, last, gender, traits, rng)
		if piece != "" and not parts.has(piece):
			parts.append(piece)
		if parts.size() == COMPOUND_PARTS:
			return " ".join(parts)
	return ""

func _category_pool(spec: Dictionary, gender: String) -> Array[String]:
	var key: String = "fem" if _is_female(gender) else "pool"
	var raw: Array = spec.get(key, spec.get("pool", []))
	return _load_strings(raw)

# Every apelido this person could plausibly answer to. The screen uses it to
# offer alternatives; the tests use it to prove each source produces something.
func nickname_options(first: String, last: String, gender: String,
		traits: Array) -> Array[String]:
	var out: Array[String] = []
	var everything: Array[String] = _name_forms(first, gender) \
		+ _name_forms(last, gender) + _stat_options(traits, gender)
	for entry: Variant in nickname_categories:
		if entry is Dictionary and not (entry as Dictionary).has("kind"):
			everything.append_array(_category_pool(entry as Dictionary, gender))
	for candidate: String in everything:
		if candidate != "" and not out.has(candidate):
			out.append(candidate)
	return out

# A nickname drawn from what the actor is notable FOR. Weighted toward the
# first trait, which is the most extreme one — the 10-agility winger gets
# called Foguete before he gets called anything about his rulebook.
func stat_nickname(traits: Array, gender: String, rng: RandomNumberGenerator) -> String:
	if traits.is_empty():
		return ""
	for _attempt: int in range(traits.size()):
		var trait_index: int = _front_loaded(traits.size(), rng)
		var entry: Dictionary = traits[trait_index]
		var pool: Array[String] = _stat_pool(
			String(entry.get("stat", "")), String(entry.get("dir", DIR_HIGH)), gender)
		if not pool.is_empty():
			return _pick(pool, rng)
	return ""

# Diminutive, augmentative and short form of a name, in that order — the three
# shapes a Brazilian given name actually takes at a field.
func name_nickname(name: String, gender: String, rng: RandomNumberGenerator) -> String:
	var forms: Array[String] = _name_forms(name, gender)
	return _pick(forms, rng)

func diminutive(name: String, gender: String) -> String:
	var clean: String = name.strip_edges()
	if clean.length() < 3:
		return ""
	var suffix: String = "inha" if _is_female(gender) else "inho"
	# The suffix takes the stress, so whatever the accent was marking is gone:
	# Vinicius, not Vinicius with the mark it no longer earns.
	clean = _unaccent(clean)
	var last_char: String = _at(clean, -1)
	# Beatriz -> Beatrizinho. The linking consonant is already there.
	if last_char == "z":
		return clean + suffix
	# Pedro -> Pedrinho: an unstressed final vowel simply goes. Not when the
	# vowel before it shares the nucleus - Joao has no "o" to drop on its own.
	var preceding: String = _at(clean, -2)
	# Except the u in que/gue, which is a digraph spelling the hard consonant
	# and not a vowel at all: Henrique does give up its -e, for Henriquinho.
	if preceding == "u" and "qg".contains(_at(clean, -3)):
		preceding = ""
	if SOFT_ENDINGS.contains(last_char) and not VOWELS.contains(preceding):
		return _soften(clean.substr(0, clean.length() - 1), suffix) + suffix
	if last_char == "s":
		var body: String = clean.substr(0, clean.length() - 1)
		# Matheus -> Matheusinho: a diphthong under the -s leaves no single
		# vowel to drop, so the whole name takes the suffix.
		if VOWELS.contains(_at(body, -1)) and VOWELS.contains(_at(body, -2)):
			return clean + suffix
		# Lucas -> Luquinho: the -s is not part of the stem either.
		var stem: String = _strip_trailing_vowels(body)
		if stem.length() >= 2:
			return _soften(stem, suffix) + suffix
	# Gabriel -> Gabrielzinho, Joao -> Joaozinho. A stressed, nasal or
	# consonant ending keeps the whole name and takes the linking -z-.
	return clean + "z" + suffix

func augmentative(name: String, gender: String) -> String:
	var clean: String = name.strip_edges()
	if clean.length() < 3:
		return ""
	# Gabriel -> Gabrielzao. A name ending in a liquid keeps its whole shape.
	# There is no feminine of this form worth printing, so it declines to make
	# one and the caller falls through to another source.
	if _is_female(gender) and LIQUIDS.contains(_at(clean, -1)):
		return ""
	# Beatriz -> Beatrizão: the z is already the link, a second one is a typo.
	if _at(clean, -1) == "z":
		return _unaccent(clean) + "ão"
	if LIQUIDS.contains(_at(clean, -1)):
		return _unaccent(clean) + "zão"
	# Matheus -> Matheusão: a diphthong under the -s leaves nothing to cut, the
	# same case the diminutive handles.
	if _at(clean, -1) == "s" and VOWELS.contains(_at(clean, -2)) and VOWELS.contains(_at(clean, -3)):
		return _unaccent(clean) + "ão"
	var stem: String = _unaccent(_augmentative_stem(clean))
	if stem.length() < 2:
		return ""
	# The suffix carries the stress now, so Vinicius comes out Vinicao and not
	# Vinicao with the accent it no longer has.
	var suffix: String = "ona" if _is_female(gender) else "ão"
	var result: String = _soften(stem, suffix) + suffix
	return "" if result.to_lower() == clean.to_lower() else result

# The bare truncation: Leonardo -> Leo, Guilherme -> Gui, Vasconcelos -> Vasco.
# Empty when the cut lands somewhere unsayable, which the caller reads as "this
# name does not shorten" rather than as an error.
func short_form(name: String) -> String:
	var clean: String = name.strip_edges()
	var cut: String = _stem(clean)
	if cut.length() < MIN_SHORT or cut.length() > MAX_SHORT:
		return ""
	if cut.to_lower() == clean.to_lower():
		return ""
	# Two rejections, both of cuts that land mid-word rather than on a name.
	# An unstressed final -e is always mid-word (Guilhe, Mathe), and past three
	# letters a trailing vowel pair is a severed diphthong (Thia, Ferrei) -
	# under three letters it is the whole point (Leo, Bea).
	if _at(cut, -1) == "e":
		return ""
	if cut.length() > MIN_SHORT and VOWELS.contains(_at(cut, -1)) and VOWELS.contains(_at(cut, -2)):
		return ""
	return _unaccent_tail(cut)

func random_team_name(rng: RandomNumberGenerator) -> String:
	# Patterns let the module decide the SHAPE of a club name, not just the
	# words: "Tijuca Capivaras" and "Águias do Morro" are different grammars.
	if not team_patterns.is_empty():
		var filled: String = fill_pattern(_pick(team_patterns, rng), rng)
		if filled != "":
			return filled
	var prefix: String = _pick(team_prefixes, rng)
	var suffix: String = _pick(team_suffixes, rng)
	if prefix == "" and suffix == "":
		return "Time"
	return (prefix + " " + suffix).strip_edges()

func random_team_pattern(rng: RandomNumberGenerator) -> String:
	return _pick(team_patterns, rng)

func random_neighborhood(rng: RandomNumberGenerator) -> String:
	return _pick(neighborhoods, rng)

func random_street_name(rng: RandomNumberGenerator) -> String:
	var pattern: String = _pick(street_patterns, rng)
	return fill_pattern(pattern, rng)

func random_place_name(rng: RandomNumberGenerator) -> String:
	var pattern: String = _pick(place_patterns, rng)
	return fill_pattern(pattern, rng)

# Public: fill an arbitrary template string with random picks from the pools.
# Supported placeholders: {last} {first_male} {first_female} {neighborhood}
#                         {team_prefix} {team_suffix}
func fill_pattern(pattern: String, rng: RandomNumberGenerator) -> String:
	if pattern == "":
		return ""
	var result: String = pattern
	# Supported placeholders:
	#   {last} {first_male} {first_female} {neighborhood}
	#   {team_prefix} {team_suffix}
	if result.contains("{last}"):
		result = result.replace("{last}", random_last_name(rng))
	if result.contains("{first_male}"):
		result = result.replace("{first_male}", random_first_name("m", rng))
	if result.contains("{first_female}"):
		result = result.replace("{first_female}", random_first_name("f", rng))
	if result.contains("{neighborhood}"):
		result = result.replace("{neighborhood}", random_neighborhood(rng))
	if result.contains("{team_prefix}"):
		result = result.replace("{team_prefix}", _pick(team_prefixes, rng))
	if result.contains("{team_suffix}"):
		result = result.replace("{team_suffix}", _pick(team_suffixes, rng))
	return result

# --- Internals: sources ---

# The declared weights, shuffled into a try-order. `stat` drops out entirely
# when the actor is notable for nothing, and its weight goes to the others.
func _source_order(traits: Array, rng: RandomNumberGenerator) -> Array[String]:
	var pool: Array[String] = []
	var weights: Array[float] = []
	for source: String in SOURCES:
		if source == SOURCE_STAT and traits.is_empty():
			continue
		pool.append(source)
		weights.append(maxf(float(nickname_weights.get(source, 1)), 0.0))
	var order: Array[String] = []
	while not pool.is_empty():
		var index: int = _weighted_index(weights, rng)
		order.append(pool[index])
		pool.remove_at(index)
		weights.remove_at(index)
	return order

func _from_source(source: String, first: String, last: String, gender: String,
		traits: Array, rng: RandomNumberGenerator) -> String:
	match source:
		SOURCE_STAT:
			return stat_nickname(traits, gender, rng)
		SOURCE_FIRST:
			return name_nickname(first, gender, rng)
		SOURCE_LAST:
			return name_nickname(last, gender, rng)
		SOURCE_RANDOM:
			return random_nickname(gender, rng)
	return ""

func _name_forms(name: String, gender: String) -> Array[String]:
	var out: Array[String] = []
	if name.strip_edges() == "":
		return out
	for form: String in [short_form(name), diminutive(name, gender), augmentative(name, gender)]:
		if form != "" and not out.has(form):
			out.append(form)
	return out

func _stat_options(traits: Array, gender: String) -> Array[String]:
	var out: Array[String] = []
	for entry: Variant in traits:
		if not entry is Dictionary:
			continue
		var spec: Dictionary = entry as Dictionary
		out.append_array(_stat_pool(
			String(spec.get("stat", "")), String(spec.get("dir", DIR_HIGH)), gender))
	return out

func _stat_pool(stat_id: String, direction: String, gender: String) -> Array[String]:
	var wanted: String = _key(stat_id)
	var out: Array[String] = []
	for entry: Variant in stat_nicknames:
		if not entry is Dictionary:
			continue
		var spec: Dictionary = entry as Dictionary
		if _key(String(spec.get("stat", ""))) != wanted:
			continue
		if _key(String(spec.get("dir", DIR_HIGH))) != _key(direction):
			continue
		# `fem` is an override, not a second pool: most of these nouns already
		# work for anyone, so only the ones that inflect carry one.
		if _is_female(gender) and spec.has("fem"):
			out.append_array(_load_strings(spec["fem"]))
		else:
			out.append_array(_load_strings(spec.get("pool", [])))
	return out

# --- Internals: morphology ---

# Cut after the second vowel nucleus. Falling diphthongs and nasals count as
# one nucleus, which is what keeps "Caio" from becoming "Cai".
func _stem(name: String) -> String:
	var lowered: String = name.to_lower()
	var nuclei: int = 0
	var index: int = 0
	while index < lowered.length():
		if not VOWELS.contains(lowered[index]):
			index += 1
			continue
		nuclei += 1
		var end: int = index + 1
		while end < lowered.length() and _continues_nucleus(lowered[end - 1], lowered[end]):
			end += 1
		if nuclei >= 2:
			return name.substr(0, end)
		index = end
	return name

# Two adjacent vowels belong to the same nucleus when the second is a glide
# (Caio, Paulo, Guilherme) or when either is nasal (João).
func _continues_nucleus(previous: String, current: String) -> bool:
	if not VOWELS.contains(current):
		return false
	return GLIDES.contains(current) or NASALS.contains(previous) or NASALS.contains(current)

func _augmentative_stem(name: String) -> String:
	var clean: String = name.strip_edges()
	if clean.length() < 3:
		return ""
	var last_char: String = clean.substr(clean.length() - 1, 1).to_lower()
	if TRAILING_CONSONANTS.contains(last_char):
		clean = clean.substr(0, clean.length() - 1)
	return _strip_trailing_vowels(clean)

func _strip_trailing_vowels(value: String) -> String:
	var out: String = value
	while out.length() > 0 and VOWELS.contains(out.substr(out.length() - 1, 1).to_lower()):
		out = out.substr(0, out.length() - 1)
	return out

# Portuguese spells the sound, not the letter: c and g go hard before a and o
# but soft before e and i, so a stem that must stay hard grows a u. Without
# this, Luc + inho reads "Lussinho" and Thiag + inho reads "Thiajinho".
func _soften(stem: String, suffix: String) -> String:
	if stem == "" or suffix == "":
		return stem
	var head: String = suffix.substr(0, 1).to_lower()
	var tail: String = stem.substr(stem.length() - 1, 1).to_lower()
	if head == "i" or head == "e":
		# Luc + inho reads "Lussinho", so the c becomes qu: Luquinho. The g
		# only grows a u: Thiag -> Thiaguinho.
		if tail == "c":
			return stem.substr(0, stem.length() - 1) + "qu"
		if tail == "g":
			return stem + "u"
	elif head == "a" or head == "o" or head == "ã":
		# And the other way for a hard suffix. The u in qu/gu spelled the hard
		# sound before an i or an e and spells nothing before an a or an o, so
		# it goes — and a bare q cannot stand at all: Henrique gives up its
		# whole digraph and comes back as Henricao.
		if stem.to_lower().ends_with("qu"):
			return stem.substr(0, stem.length() - 2) + "c"
		if stem.to_lower().ends_with("gu"):
			return stem.substr(0, stem.length() - 1)
		if tail == "q":
			return stem.substr(0, stem.length() - 1) + "c"
	return stem

const ACCENTED := "áàâéêíóôúü"
const PLAIN := "aaaeeioouu"

# A cut is not a name: the tail accent marked a stress the short form no
# longer has.
func _unaccent_tail(value: String) -> String:
	if value == "":
		return value
	var index: int = ACCENTED.find(_at(value, -1))
	if index < 0:
		return value
	return value.substr(0, value.length() - 1) + PLAIN[index]

# Whole-word, for when a suffix takes the stress over. The nasals are left
# alone: they are not stress marks.
func _unaccent(value: String) -> String:
	var out: String = ""
	for i: int in range(value.length()):
		var index: int = ACCENTED.find(value[i].to_lower())
		if index < 0:
			out += value[i]
		elif value[i] == value[i].to_lower():
			out += PLAIN[index]
		else:
			out += PLAIN[index].to_upper()
	return out

# Character at a position, counting from the end when negative, lowercased.
# Empty outside the string, which reads as "there is no letter there".
func _at(value: String, index: int) -> String:
	var at: int = value.length() + index if index < 0 else index
	if at < 0 or at >= value.length():
		return ""
	return value[at].to_lower()

# --- Internals: picking ---

# Index into a list ordered by how notable the trait is, biased to the front:
# roughly half the time the first one, then halving.
func _front_loaded(size: int, rng: RandomNumberGenerator) -> int:
	var index: int = 0
	while index < size - 1 and rng.randf() >= 0.5:
		index += 1
	return index

func _weighted_index(weights: Array[float], rng: RandomNumberGenerator) -> int:
	var total: float = 0.0
	for w: float in weights:
		total += w
	if total <= 0.0:
		return rng.randi() % weights.size()
	var roll: float = rng.randf() * total
	for i: int in range(weights.size()):
		roll -= weights[i]
		if roll <= 0.0:
			return i
	return weights.size() - 1

func _is_female(gender: String) -> bool:
	return gender.to_lower().begins_with("f")

func _pick(pool: Array[String], rng: RandomNumberGenerator) -> String:
	if pool.is_empty():
		return ""
	var idx: int = rng.randi() % pool.size()
	return pool[idx]
