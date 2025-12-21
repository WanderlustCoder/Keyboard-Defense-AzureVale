extends RefCounted

const TestHelper = preload("res://scripts/tests/test_helper.gd")
const TypingSystem = preload("res://scripts/TypingSystem.gd")

func run() -> Dictionary:
	var helper = TestHelper.new()
	var typing = TypingSystem.new()

	typing.start(["castle"])
	var result: Dictionary = typing.input_char("c")
	helper.assert_eq(result.get("status"), "progress", "first letter progresses")
	typing.input_char("a")
	typing.input_char("s")
	typing.input_char("t")
	typing.input_char("l")
	result = typing.input_char("e")
	helper.assert_eq(result.get("status"), "lesson_complete", "last letter completes lesson")
	helper.assert_eq(typing.get_words_completed(), 1, "word completion count")
	helper.assert_eq(typing.errors, 0, "no errors on clean word")
	helper.assert_true(typing.get_accuracy() > 0.99, "accuracy stays high")
	helper.assert_true(typing.get_wpm() > 0, "wpm computes")

	typing.start(["gate"])
	result = typing.input_char("x")
	helper.assert_eq(result.get("status"), "error", "wrong letter produces error")
	helper.assert_eq(typing.errors, 1, "error count increments")
	helper.assert_true(typing.get_accuracy() < 0.5, "accuracy drops on error")

	typing.start(["go!"])
	typing.input_char("g")
	typing.input_char("o")
	result = typing.input_char("!")
	helper.assert_eq(result.get("status"), "lesson_complete", "punctuation completes target")

	typing.start(["hold the line"])
	var sentence = "hold the line"
	for i in range(sentence.length()):
		result = typing.input_char(sentence.substr(i, 1))
	helper.assert_eq(result.get("status"), "lesson_complete", "spaces are accepted when in target")

	return helper.summary()
