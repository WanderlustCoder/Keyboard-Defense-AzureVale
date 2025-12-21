class_name TypingSystem
extends RefCounted

var words: Array = []
var word_index: int = 0
var typed: String = ""
var total_inputs: int = 0
var correct_inputs: int = 0
var errors: int = 0
var start_time_ms: int = 0
var allowed_chars: String = ""
var case_sensitive: bool = false

func start(words_list: Array, config: Dictionary = {}) -> void:
	words = words_list.duplicate()
	word_index = 0
	typed = ""
	total_inputs = 0
	correct_inputs = 0
	errors = 0
	start_time_ms = Time.get_ticks_msec()
	case_sensitive = bool(config.get("case_sensitive", false))
	var allow_spaces = bool(config.get("allow_spaces", false))
	var provided_allowed = str(config.get("allowed_chars", ""))
	if provided_allowed != "":
		allowed_chars = provided_allowed
	else:
		allowed_chars = _build_allowed_chars(words, case_sensitive)
	if not case_sensitive:
		allowed_chars = allowed_chars.to_lower()
	if allow_spaces and allowed_chars.find(" ") == -1:
		allowed_chars += " "

func get_current_word() -> String:
	if word_index < words.size():
		return str(words[word_index])
	return ""

func get_words_completed() -> int:
	return word_index

func get_elapsed_seconds() -> float:
	var elapsed_ms := Time.get_ticks_msec() - start_time_ms
	return max(0.001, float(elapsed_ms) / 1000.0)

func get_accuracy() -> float:
	if total_inputs <= 0:
		return 1.0
	return float(correct_inputs) / float(total_inputs)

func get_wpm() -> float:
	return float(get_words_completed()) / (get_elapsed_seconds() / 60.0)

func input_char(char: String) -> Dictionary:
	if char.length() != 1:
		return {"status": "ignored"}
	var input_char := char
	var current_word := get_current_word()
	if current_word == "":
		return {"status": "complete"}
	var expected_raw := current_word.substr(typed.length(), 1)
	var expected_cmp := expected_raw
	if not case_sensitive:
		input_char = input_char.to_lower()
		expected_cmp = expected_cmp.to_lower()
	if allowed_chars != "" and allowed_chars.find(input_char) == -1:
		total_inputs += 1
		errors += 1
		typed = ""
		return {"status": "error", "expected": expected_raw, "received": input_char}
	total_inputs += 1
	if input_char != expected_cmp:
		errors += 1
		typed = ""
		return {"status": "error", "expected": expected_raw, "received": input_char}
	correct_inputs += 1
	typed += expected_raw
	if typed.length() >= current_word.length():
		var finished_word := current_word
		word_index += 1
		typed = ""
		if word_index >= words.size():
			return {"status": "lesson_complete", "word": finished_word}
		return {"status": "word_complete", "word": finished_word}
	return {"status": "progress", "expected": expected_raw}

func backspace() -> void:
	if typed.length() > 0:
		typed = typed.substr(0, typed.length() - 1)

func _build_allowed_chars(words_list: Array, is_case_sensitive: bool) -> String:
	var seen: Dictionary = {}
	var result := ""
	for word in words_list:
		var text := str(word)
		if not is_case_sensitive:
			text = text.to_lower()
		for i in range(text.length()):
			var letter = text.substr(i, 1)
			if not seen.has(letter):
				seen[letter] = true
				result += letter
	return result
