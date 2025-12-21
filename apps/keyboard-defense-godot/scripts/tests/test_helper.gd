extends RefCounted

var tests: int = 0
var failures: Array = []

func assert_true(condition: bool, message: String) -> void:
	tests += 1
	if not condition:
		failures.append(message)

func assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	var matches = actual == expected
	assert_true(matches, "%s (got: %s, expected: %s)" % [message, str(actual), str(expected)])

func summary() -> Dictionary:
	return {
		"tests": tests,
		"failed": failures.size(),
		"messages": failures
	}
