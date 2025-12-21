class_name TypingSystem
extends RefCounted

var words: Array = []
var word_index: int = 0
var typed: String = ""
var total_inputs: int = 0
var correct_inputs: int = 0
var errors: int = 0
var start_time_ms: int = 0

func start(words_list: Array) -> void:
	words = words_list.duplicate()
	word_index = 0
	typed = ""
	total_inputs = 0
	correct_inputs = 0
	errors = 0
	start_time_ms = Time.get_ticks_msec()

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
	var c := char.to_lower()
	if c < "a" or c > "z":
		return {"status": "ignored"}
	var current_word := get_current_word()
	if current_word == "":
		return {"status": "complete"}
	var expected := current_word.substr(typed.length(), 1)
	total_inputs += 1
	if c != expected:
		errors += 1
		typed = ""
		return {"status": "error", "expected": expected, "received": c}
	correct_inputs += 1
	typed += c
	if typed.length() >= current_word.length():
		var finished_word := current_word
		word_index += 1
		typed = ""
		if word_index >= words.size():
			return {"status": "lesson_complete", "word": finished_word}
		return {"status": "word_complete", "word": finished_word}
	return {"status": "progress", "expected": expected}

func backspace() -> void:
	if typed.length() > 0:
		typed = typed.substr(0, typed.length() - 1)
