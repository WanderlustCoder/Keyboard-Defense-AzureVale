class_name SimWords
extends RefCounted
const CommandKeywords = preload("res://sim/command_keywords.gd")
const SimLessons = preload("res://sim/lessons.gd")
static var _reserved_cache: Dictionary = {}
const RESERVED_EXTRA := {}

const SHORT_WORDS: Array[String] = [
	"mist",
	"fern",
	"glow",
	"bolt",
	"rift",
	"lark",
	"reed",
	"moth",
	"brim",
	"palm",
	"rust",
	"quill"
]

const MEDIUM_WORDS: Array[String] = [
	"harvest",
	"harbor",
	"citron",
	"amber",
	"copper",
	"stone",
	"forest",
	"meadow",
	"candle",
	"shield",
	"vector",
	"echoes",
	"market",
	"bridge"
]

const LONG_WORDS: Array[String] = [
	"sentinel",
	"fortress",
	"vanguard",
	"monolith",
	"stronghold",
	"cathedral",
	"archivist",
	"lighthouse",
	"riverstone",
	"everglade",
	"moonlight",
	"wildgrowth"
]

static func word_for_enemy(seed: String, day: int, kind: String, enemy_id: int, already_used: Dictionary, lesson_id: String = "") -> String:
	var resolved_lesson: String = SimLessons.normalize_lesson_id(lesson_id)
	var lesson: Dictionary = SimLessons.get_lesson(resolved_lesson)
	if lesson.is_empty():
		return _fallback_word(seed, day, kind, enemy_id, already_used)

	var mode: String = str(lesson.get("mode", "charset"))
	match mode:
		"wordlist":
			var word: String = _word_from_wordlist(seed, day, kind, enemy_id, lesson, already_used)
			if word != "":
				return word
		"sentence":
			var sentence: String = _sentence_from_lesson(seed, day, enemy_id, lesson, already_used)
			if sentence != "":
				return sentence
		"charset", _:
			var lesson_word: String = _word_from_lesson(seed, day, kind, enemy_id, resolved_lesson, lesson, already_used)
			if lesson_word != "":
				return lesson_word
	return _fallback_word(seed, day, kind, enemy_id, already_used)

static func _word_from_lesson(seed: String, day: int, kind: String, enemy_id: int, lesson_id: String, lesson: Dictionary, already_used: Dictionary) -> String:
	var charset: String = str(lesson.get("charset", "")).to_lower()
	if charset == "":
		return ""
	var lengths: Dictionary = lesson.get("lengths", {})
	var range_value: Variant = lengths.get(kind, [])
	var min_len: int = 3
	var max_len: int = 5
	if range_value is Array and range_value.size() >= 2:
		min_len = int(range_value[0])
		max_len = int(range_value[1])
	if min_len < 1:
		min_len = 1
	if max_len < min_len:
		max_len = min_len
	var base_key: String = "%s|%d|%s|%d|%s" % [seed, day, kind, enemy_id, lesson_id]
	var attempts: int = max(16, charset.length() * 2)
	for attempt in range(attempts):
		var word: String = _make_word(base_key, charset, min_len, max_len, attempt)
		if word == "":
			continue
		if _reserved_words().has(word):
			continue
		if already_used.has(word):
			continue
		return word
	return ""

static func _make_word(base_key: String, charset: String, min_len: int, max_len: int, attempt: int) -> String:
	if charset == "":
		return ""
	var span: int = max(1, max_len - min_len + 1)
	var length: int = min_len + _hash_index("%s|len|%d" % [base_key, attempt], span)
	var parts: Array[String] = []
	for i in range(length):
		var idx: int = _hash_index("%s|%d|%d" % [base_key, attempt, i], charset.length())
		parts.append(charset.substr(idx, 1))
	return "".join(parts)

static func _hash_index(key: String, modulo: int) -> int:
	if modulo <= 0:
		return 0
	var hash_value: int = key.hash()
	if hash_value == -9223372036854775808:
		hash_value = 0
	return abs(hash_value) % modulo

static func _fallback_word(seed: String, day: int, kind: String, enemy_id: int, already_used: Dictionary) -> String:
	var list: Array[String] = _list_for_kind(kind)
	if list.is_empty():
		return "foe%d" % enemy_id
	var key: String = "%s|%d|%s|%d" % [seed, day, kind, enemy_id]
	var index: int = _hash_index(key, list.size())
	for _i in range(list.size()):
		var word: String = str(list[index]).to_lower()
		if not _reserved_words().has(word) and not already_used.has(word):
			return word
		index = (index + 1) % list.size()
	return "foe%d" % enemy_id

static func _list_for_kind(kind: String) -> Array[String]:
	match kind:
		"scout":
			return SHORT_WORDS
		"armored":
			return LONG_WORDS
		_:
			return MEDIUM_WORDS

static func _reserved_words() -> Dictionary:
	if _reserved_cache.is_empty():
		for keyword in CommandKeywords.KEYWORDS:
			_reserved_cache[str(keyword).to_lower()] = true
		for word in RESERVED_EXTRA.keys():
			_reserved_cache[str(word).to_lower()] = true
	return _reserved_cache

static func _word_from_wordlist(seed: String, day: int, kind: String, enemy_id: int, lesson: Dictionary, already_used: Dictionary) -> String:
	var wordlist: Array = lesson.get("wordlist", [])
	if wordlist.is_empty():
		return ""

	# Filter by length based on enemy kind
	var lengths: Dictionary = lesson.get("lengths", {})
	var range_value: Variant = lengths.get(kind, [3, 6])
	var min_len: int = 3
	var max_len: int = 6
	if range_value is Array and range_value.size() >= 2:
		min_len = int(range_value[0])
		max_len = int(range_value[1])

	# Build filtered list
	var filtered: Array = []
	for word in wordlist:
		var w: String = str(word)
		if w.length() >= min_len and w.length() <= max_len:
			filtered.append(w)

	# Fall back to full list if filter is too restrictive
	if filtered.is_empty():
		filtered = wordlist

	# Select from filtered list
	var key: String = "%s|%d|%s|%d" % [seed, day, kind, enemy_id]
	var index: int = _hash_index(key, filtered.size())
	for _i in range(filtered.size()):
		var word: String = str(filtered[index]).to_lower()
		if not _reserved_words().has(word) and not already_used.has(word):
			return word
		index = (index + 1) % filtered.size()
	return ""

static func _sentence_from_lesson(seed: String, day: int, enemy_id: int, lesson: Dictionary, already_used: Dictionary) -> String:
	var sentences: Array = lesson.get("sentences", [])
	if sentences.is_empty():
		return ""

	var key: String = "%s|%d|%d" % [seed, day, enemy_id]
	var index: int = _hash_index(key, sentences.size())
	for _i in range(sentences.size()):
		var sentence: String = str(sentences[index])
		# Use lowercase version for uniqueness check but return original case
		var check_key: String = sentence.to_lower()
		if not already_used.has(check_key):
			return sentence
		index = (index + 1) % sentences.size()
	# If all sentences used, just return one anyway
	return str(sentences[_hash_index(key, sentences.size())])

## Get a longer, harder word for boss enemies
static func get_boss_word(lesson_id: String, already_used: Dictionary) -> String:
	var resolved_lesson: String = SimLessons.normalize_lesson_id(lesson_id)
	var lesson: Dictionary = SimLessons.get_lesson(resolved_lesson)
	if lesson.is_empty():
		return _get_boss_fallback_word(already_used)

	var mode: String = str(lesson.get("mode", "charset"))

	# For wordlist lessons, get the longest available word
	if mode == "wordlist":
		var wordlist: Array = lesson.get("wordlist", [])
		if not wordlist.is_empty():
			# Sort by length and pick a long unused word
			var sorted_words: Array = wordlist.duplicate()
			sorted_words.sort_custom(func(a, b): return str(a).length() > str(b).length())
			for word in sorted_words:
				var w: String = str(word).to_lower()
				if not _reserved_words().has(w) and not already_used.has(w):
					return w

	# For charset lessons, generate a longer word
	var charset: String = str(lesson.get("charset", "")).to_lower()
	if charset != "":
		# Boss words are 7-10 characters
		var min_len: int = 7
		var max_len: int = 10
		var base_key: String = "boss|%s|%d" % [lesson_id, Time.get_ticks_msec()]
		for attempt in range(32):
			var word: String = _make_word(base_key, charset, min_len, max_len, attempt)
			if word == "":
				continue
			if _reserved_words().has(word):
				continue
			if already_used.has(word):
				continue
			return word

	return _get_boss_fallback_word(already_used)

static func _get_boss_fallback_word(already_used: Dictionary) -> String:
	# Use long words for bosses
	for word in LONG_WORDS:
		var w: String = word.to_lower()
		if not _reserved_words().has(w) and not already_used.has(w):
			return w
	# If all long words used, generate a unique one
	return "overlord%d" % (Time.get_ticks_msec() % 1000)


## Scramble the letters of a word (used by word-scrambling abilities)
static func scramble_word(word: String, seed: String) -> String:
	if word.length() <= 1:
		return word

	# Convert to array of characters
	var chars: Array[String] = []
	for c in word:
		chars.append(c)

	# Fisher-Yates shuffle using hash-based randomization
	var hash_base: int = hash(seed + word)
	for i in range(chars.size() - 1, 0, -1):
		var j: int = abs(hash(hash_base + i)) % (i + 1)
		var temp: String = chars[i]
		chars[i] = chars[j]
		chars[j] = temp

	# Ensure the result is different from the original
	var result: String = "".join(chars)
	if result == word and word.length() > 1:
		# If still the same, swap first two characters
		chars[0] = word[1]
		chars[1] = word[0]
		result = "".join(chars)

	return result


# =============================================================================
# Random Word Generation (for exploration challenges)
# =============================================================================

static func random_common_word(state) -> String:
	## Get a random common word from SHORT_WORDS or MEDIUM_WORDS
	var combined: Array[String] = []
	combined.append_array(SHORT_WORDS)
	combined.append_array(MEDIUM_WORDS)
	if combined.is_empty():
		return "word"
	var idx: int = 0
	if state != null and state.has_method("get"):
		# Use state RNG if available
		var seed_val: String = str(state.get("rng_seed", "random"))
		idx = _hash_index(seed_val + str(Time.get_ticks_msec()), combined.size())
	else:
		idx = randi() % combined.size()
	return combined[idx]


static func random_uncommon_word(state) -> String:
	## Get a random uncommon/longer word from LONG_WORDS
	if LONG_WORDS.is_empty():
		return "challenge"
	var idx: int = 0
	if state != null and state.has_method("get"):
		var seed_val: String = str(state.get("rng_seed", "random"))
		idx = _hash_index(seed_val + str(Time.get_ticks_msec()) + "uncommon", LONG_WORDS.size())
	else:
		idx = randi() % LONG_WORDS.size()
	return LONG_WORDS[idx]


static func random_word_for_lesson(state, lesson_id: String) -> String:
	## Get a random word appropriate for a specific lesson
	var lesson: Dictionary = SimLessons.get_lesson(lesson_id)
	if lesson.is_empty():
		return random_common_word(state)

	# Try to get from lesson word pool
	var word_pool: Array = lesson.get("word_pool", [])
	if not word_pool.is_empty():
		var idx: int = 0
		if state != null and state.has_method("get"):
			var seed_val: String = str(state.get("rng_seed", "random"))
			idx = _hash_index(seed_val + str(Time.get_ticks_msec()) + lesson_id, word_pool.size())
		else:
			idx = randi() % word_pool.size()
		return str(word_pool[idx])

	# Fallback to common words
	return random_common_word(state)
