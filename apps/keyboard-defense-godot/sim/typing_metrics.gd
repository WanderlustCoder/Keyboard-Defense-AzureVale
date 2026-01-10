class_name SimTypingMetrics
extends RefCounted
## Typing metrics system for tracking WPM, accuracy, and tower damage scaling

const GameState = preload("res://sim/types.gd")

# =============================================================================
# CONSTANTS
# =============================================================================

const WPM_WINDOW_MS := 10000  # 10-second rolling window for WPM
const UNIQUE_LETTER_WINDOW_MS := 10000  # 10-second window for unique letters
const CHARS_PER_WORD := 5.0  # Standard WPM calculation

# Combo thresholds
const COMBO_THRESHOLDS := [3, 5, 10, 20, 50]
const COMBO_MULTIPLIERS := [1.1, 1.25, 1.5, 2.0, 2.5]

# =============================================================================
# METRICS INITIALIZATION
# =============================================================================

## Initialize typing metrics for a new battle
static func init_battle_metrics(state: GameState) -> void:
	state.typing_metrics = {
		"battle_chars_typed": 0,
		"battle_words_typed": 0,
		"battle_start_msec": Time.get_ticks_msec(),
		"battle_errors": 0,
		"rolling_window_chars": [],  # Array of {msec, char}
		"unique_letters_window": {},  # {letter: last_typed_msec}
		"perfect_word_streak": 0,
		"current_word_errors": 0,
		"combo_count": 0,
		"max_combo": 0,
		"last_char_msec": 0
	}


## Reset metrics (call at battle start)
static func reset_metrics(state: GameState) -> void:
	init_battle_metrics(state)


# =============================================================================
# RECORDING METRICS
# =============================================================================

## Record a correctly typed character
static func record_char_typed(state: GameState, char: String) -> void:
	var now: int = Time.get_ticks_msec()
	var metrics: Dictionary = state.typing_metrics

	metrics["battle_chars_typed"] = int(metrics.get("battle_chars_typed", 0)) + 1

	# Add to rolling window
	var window: Array = metrics.get("rolling_window_chars", [])
	window.append({"msec": now, "char": char})
	metrics["rolling_window_chars"] = window

	# Track unique letters
	var unique: Dictionary = metrics.get("unique_letters_window", {})
	unique[char.to_lower()] = now
	metrics["unique_letters_window"] = unique

	# Update last char time
	metrics["last_char_msec"] = now

	# Increment combo
	metrics["combo_count"] = int(metrics.get("combo_count", 0)) + 1
	metrics["max_combo"] = max(
		int(metrics.get("max_combo", 0)),
		int(metrics.get("combo_count", 0))
	)

	_clean_old_entries(metrics, now)
	state.typing_metrics = metrics


## Record a typing error
static func record_error(state: GameState) -> void:
	var metrics: Dictionary = state.typing_metrics
	metrics["battle_errors"] = int(metrics.get("battle_errors", 0)) + 1
	metrics["current_word_errors"] = int(metrics.get("current_word_errors", 0)) + 1

	# Break combo on error
	metrics["combo_count"] = 0

	state.typing_metrics = metrics


## Record a completed word
static func record_word_completed(state: GameState) -> void:
	var metrics: Dictionary = state.typing_metrics
	metrics["battle_words_typed"] = int(metrics.get("battle_words_typed", 0)) + 1

	# Check if word was perfect (no errors)
	if int(metrics.get("current_word_errors", 0)) == 0:
		metrics["perfect_word_streak"] = int(metrics.get("perfect_word_streak", 0)) + 1
	else:
		metrics["perfect_word_streak"] = 0

	# Reset word error counter
	metrics["current_word_errors"] = 0

	state.typing_metrics = metrics


# =============================================================================
# CALCULATING METRICS
# =============================================================================

## Calculate current WPM from rolling window
static func get_wpm(state: GameState) -> float:
	var metrics: Dictionary = state.typing_metrics
	var window: Array = metrics.get("rolling_window_chars", [])

	if window.is_empty():
		return 0.0

	var now: int = Time.get_ticks_msec()
	_clean_old_entries(metrics, now)
	window = metrics.get("rolling_window_chars", [])

	if window.is_empty():
		return 0.0

	var chars_in_window: int = window.size()

	# Calculate time span
	var oldest: int = int(window[0].get("msec", now))
	var time_span_ms: int = now - oldest

	if time_span_ms < 100:  # Need at least 100ms of data
		return 0.0

	# WPM = (chars / chars_per_word) / (time_in_minutes)
	var time_minutes: float = float(time_span_ms) / 60000.0
	var wpm: float = (float(chars_in_window) / CHARS_PER_WORD) / time_minutes

	return wpm


## Calculate overall accuracy for this battle
static func get_accuracy(state: GameState) -> float:
	var metrics: Dictionary = state.typing_metrics
	var chars: int = int(metrics.get("battle_chars_typed", 0))
	var errors: int = int(metrics.get("battle_errors", 0))

	if chars == 0:
		return 1.0

	return float(chars) / float(chars + errors)


## Get count of unique letters typed in the window
static func get_unique_letter_count(state: GameState) -> int:
	var metrics: Dictionary = state.typing_metrics
	var now: int = Time.get_ticks_msec()

	_clean_old_entries(metrics, now)

	var unique: Dictionary = metrics.get("unique_letters_window", {})
	return unique.size()


## Get all unique letters typed in the window
static func get_unique_letters(state: GameState) -> Array[String]:
	var metrics: Dictionary = state.typing_metrics
	var now: int = Time.get_ticks_msec()

	_clean_old_entries(metrics, now)

	var unique: Dictionary = metrics.get("unique_letters_window", {})
	var letters: Array[String] = []
	for letter in unique.keys():
		letters.append(str(letter))
	return letters


## Get current combo count
static func get_combo_count(state: GameState) -> int:
	return int(state.typing_metrics.get("combo_count", 0))


## Get max combo achieved this battle
static func get_max_combo(state: GameState) -> int:
	return int(state.typing_metrics.get("max_combo", 0))


## Get perfect word streak
static func get_perfect_streak(state: GameState) -> int:
	return int(state.typing_metrics.get("perfect_word_streak", 0))


## Get combo damage multiplier based on current combo
static func get_combo_multiplier(state: GameState) -> float:
	var combo: int = get_combo_count(state)

	var multiplier: float = 1.0
	for i in range(COMBO_THRESHOLDS.size()):
		if combo >= COMBO_THRESHOLDS[i]:
			multiplier = COMBO_MULTIPLIERS[i]

	return multiplier


## Get battle duration in seconds
static func get_battle_duration(state: GameState) -> float:
	var metrics: Dictionary = state.typing_metrics
	var start: int = int(metrics.get("battle_start_msec", 0))
	if start == 0:
		return 0.0

	var now: int = Time.get_ticks_msec()
	return float(now - start) / 1000.0


## Get total chars typed this battle
static func get_chars_typed(state: GameState) -> int:
	return int(state.typing_metrics.get("battle_chars_typed", 0))


## Get total words typed this battle
static func get_words_typed(state: GameState) -> int:
	return int(state.typing_metrics.get("battle_words_typed", 0))


## Get total errors this battle
static func get_errors(state: GameState) -> int:
	return int(state.typing_metrics.get("battle_errors", 0))


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

## Remove entries older than the window
static func _clean_old_entries(metrics: Dictionary, now: int) -> void:
	# Clean rolling window chars
	var window: Array = metrics.get("rolling_window_chars", [])
	var cutoff: int = now - WPM_WINDOW_MS

	while not window.is_empty() and int(window[0].get("msec", 0)) < cutoff:
		window.pop_front()

	metrics["rolling_window_chars"] = window

	# Clean unique letters window
	var unique: Dictionary = metrics.get("unique_letters_window", {})
	var letter_cutoff: int = now - UNIQUE_LETTER_WINDOW_MS
	var to_remove: Array[String] = []

	for letter in unique.keys():
		if int(unique[letter]) < letter_cutoff:
			to_remove.append(str(letter))

	for letter in to_remove:
		unique.erase(letter)

	metrics["unique_letters_window"] = unique


# =============================================================================
# BATTLE SUMMARY
# =============================================================================

## Get a summary of battle performance
static func get_battle_summary(state: GameState) -> Dictionary:
	return {
		"wpm": get_wpm(state),
		"accuracy": get_accuracy(state),
		"chars_typed": get_chars_typed(state),
		"words_typed": get_words_typed(state),
		"errors": get_errors(state),
		"max_combo": get_max_combo(state),
		"perfect_streak": get_perfect_streak(state),
		"duration_sec": get_battle_duration(state),
		"unique_letters": get_unique_letter_count(state)
	}


## Format battle summary for display
static func format_battle_summary(state: GameState) -> String:
	var summary: Dictionary = get_battle_summary(state)
	return """Battle Performance:
WPM: %.1f
Accuracy: %.1f%%
Words: %d
Chars: %d
Errors: %d
Max Combo: %d
Perfect Streak: %d
Duration: %.1fs""" % [
		summary.wpm,
		summary.accuracy * 100.0,
		summary.words_typed,
		summary.chars_typed,
		summary.errors,
		summary.max_combo,
		summary.perfect_streak,
		summary.duration_sec
	]
