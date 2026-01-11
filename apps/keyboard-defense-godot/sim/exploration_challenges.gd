class_name SimExplorationChallenges
extends RefCounted
## Typing challenges for exploration events - accuracy, speed, consistency tests

const SimWords = preload("res://sim/words.gd")
const SimRng = preload("res://sim/rng.gd")

# Challenge types
enum ChallengeType {
	ACCURACY,      # Type words with minimum accuracy %
	SPEED,         # Achieve minimum WPM
	CONSISTENCY,   # Type with even pacing (low variance)
	TIMED,         # Complete within time limit
	WORD_COUNT,    # Type N words correctly
	MIXED          # Combined requirements
}

# Challenge difficulty presets
const DIFFICULTY_PRESETS: Dictionary = {
	"easy": {
		"word_count": 3,
		"min_accuracy": 0.7,
		"min_wpm": 20,
		"time_limit": 30.0,
		"word_length_min": 3,
		"word_length_max": 5
	},
	"medium": {
		"word_count": 5,
		"min_accuracy": 0.8,
		"min_wpm": 35,
		"time_limit": 25.0,
		"word_length_min": 4,
		"word_length_max": 7
	},
	"hard": {
		"word_count": 7,
		"min_accuracy": 0.9,
		"min_wpm": 50,
		"time_limit": 20.0,
		"word_length_min": 5,
		"word_length_max": 9
	},
	"legendary": {
		"word_count": 10,
		"min_accuracy": 0.95,
		"min_wpm": 70,
		"time_limit": 15.0,
		"word_length_min": 6,
		"word_length_max": 12
	}
}

# Day-based difficulty scaling
static func get_difficulty_for_day(day: int) -> String:
	if day <= 3:
		return "easy"
	elif day <= 7:
		return "medium"
	elif day <= 14:
		return "hard"
	else:
		return "legendary"


# =============================================================================
# CHALLENGE GENERATION
# =============================================================================

## Generate a typing challenge based on config
static func generate_challenge(state, config: Dictionary) -> Dictionary:
	var challenge_type: int = int(config.get("type", ChallengeType.WORD_COUNT))
	var difficulty: String = str(config.get("difficulty", "medium"))
	var day_scaled: bool = config.get("day_scaled", true)

	# Apply day scaling if enabled
	if day_scaled and state != null:
		difficulty = get_difficulty_for_day(state.day)

	var preset: Dictionary = DIFFICULTY_PRESETS.get(difficulty, DIFFICULTY_PRESETS["medium"])

	# Override preset with explicit config values
	var word_count: int = int(config.get("word_count", preset["word_count"]))
	var min_accuracy: float = float(config.get("min_accuracy", preset["min_accuracy"]))
	var min_wpm: float = float(config.get("min_wpm", preset["min_wpm"]))
	var time_limit: float = float(config.get("time_limit", preset["time_limit"]))
	var word_pool: String = str(config.get("word_pool", "common"))
	var word_length_min: int = int(config.get("word_length_min", preset["word_length_min"]))
	var word_length_max: int = int(config.get("word_length_max", preset["word_length_max"]))

	# Generate words for the challenge
	var words: Array[String] = _generate_challenge_words(
		state, word_count, word_pool, word_length_min, word_length_max
	)

	return {
		"type": challenge_type,
		"difficulty": difficulty,
		"words": words,
		"word_count": words.size(),
		"min_accuracy": min_accuracy,
		"min_wpm": min_wpm,
		"time_limit": time_limit,
		"started": false,
		"start_time": 0.0,
		"typed_words": [],
		"correct_words": 0,
		"total_chars": 0,
		"correct_chars": 0,
		"current_word_index": 0
	}


## Generate words for a challenge
static func _generate_challenge_words(state, count: int, pool: String, min_len: int, max_len: int) -> Array[String]:
	var words: Array[String] = []
	var attempts: int = 0
	var max_attempts: int = count * 10

	while words.size() < count and attempts < max_attempts:
		attempts += 1
		var word: String = ""

		# Generate from word pool
		if pool == "common":
			word = SimWords.random_common_word(state)
		elif pool == "uncommon":
			word = SimWords.random_uncommon_word(state)
		elif pool == "lesson":
			var lesson_id: String = str(state.lesson_id) if state != null else "home_row_1"
			word = SimWords.random_word_for_lesson(state, lesson_id)
		else:
			word = SimWords.random_common_word(state)

		# Check length constraints
		if word.length() >= min_len and word.length() <= max_len:
			if word not in words:  # Avoid duplicates
				words.append(word)

	# Fill remaining with any words if we couldn't meet constraints
	while words.size() < count:
		var fallback: String = SimWords.random_common_word(state)
		if fallback not in words:
			words.append(fallback)

	return words


# =============================================================================
# CHALLENGE VALIDATION
# =============================================================================

## Start tracking a challenge (call when player begins typing)
static func start_challenge(challenge: Dictionary, current_time: float) -> Dictionary:
	challenge["started"] = true
	challenge["start_time"] = current_time
	challenge["typed_words"] = []
	challenge["correct_words"] = 0
	challenge["total_chars"] = 0
	challenge["correct_chars"] = 0
	challenge["current_word_index"] = 0
	return challenge


## Process a typed word during the challenge
static func process_word(challenge: Dictionary, typed_word: String) -> Dictionary:
	var idx: int = int(challenge.get("current_word_index", 0))
	var words: Array = challenge.get("words", [])

	if idx >= words.size():
		return {"accepted": false, "reason": "challenge_complete"}

	var expected: String = str(words[idx])
	var typed_clean: String = typed_word.strip_edges().to_lower()
	var expected_clean: String = expected.to_lower()
	var correct: bool = typed_clean == expected_clean

	# Track stats
	var typed_words: Array = challenge.get("typed_words", [])
	typed_words.append({
		"expected": expected,
		"typed": typed_word,
		"correct": correct
	})
	challenge["typed_words"] = typed_words

	challenge["total_chars"] = int(challenge.get("total_chars", 0)) + typed_word.length()
	if correct:
		challenge["correct_words"] = int(challenge.get("correct_words", 0)) + 1
		challenge["correct_chars"] = int(challenge.get("correct_chars", 0)) + expected.length()
	else:
		# Count matching characters for partial credit
		var matching: int = _count_matching_chars(typed_clean, expected_clean)
		challenge["correct_chars"] = int(challenge.get("correct_chars", 0)) + matching

	challenge["current_word_index"] = idx + 1

	return {
		"accepted": true,
		"correct": correct,
		"expected": expected,
		"words_remaining": words.size() - (idx + 1)
	}


## Count matching characters between two strings
static func _count_matching_chars(typed: String, expected: String) -> int:
	var matching: int = 0
	var min_len: int = mini(typed.length(), expected.length())
	for i in range(min_len):
		if typed[i] == expected[i]:
			matching += 1
	return matching


## Evaluate the completed challenge
static func evaluate_challenge(challenge: Dictionary, end_time: float) -> Dictionary:
	var words: Array = challenge.get("words", [])
	var correct_words: int = int(challenge.get("correct_words", 0))
	var total_chars: int = int(challenge.get("total_chars", 0))
	var correct_chars: int = int(challenge.get("correct_chars", 0))
	var start_time: float = float(challenge.get("start_time", end_time))
	var time_limit: float = float(challenge.get("time_limit", 60.0))
	var min_accuracy: float = float(challenge.get("min_accuracy", 0.8))
	var min_wpm: float = float(challenge.get("min_wpm", 30.0))
	var challenge_type: int = int(challenge.get("type", ChallengeType.WORD_COUNT))

	# Calculate metrics
	var elapsed: float = end_time - start_time
	var accuracy: float = float(correct_chars) / maxf(float(total_chars), 1.0)
	var wpm: float = (float(correct_chars) / 5.0) / maxf(elapsed / 60.0, 0.01)
	var words_completed: int = int(challenge.get("current_word_index", 0))
	var all_words_typed: bool = words_completed >= words.size()

	# Evaluate based on challenge type
	var passed: bool = false
	var fail_reason: String = ""

	match challenge_type:
		ChallengeType.ACCURACY:
			passed = accuracy >= min_accuracy and all_words_typed
			if not passed:
				if not all_words_typed:
					fail_reason = "incomplete"
				else:
					fail_reason = "accuracy_too_low"

		ChallengeType.SPEED:
			passed = wpm >= min_wpm and all_words_typed
			if not passed:
				if not all_words_typed:
					fail_reason = "incomplete"
				else:
					fail_reason = "too_slow"

		ChallengeType.TIMED:
			passed = elapsed <= time_limit and all_words_typed
			if not passed:
				if elapsed > time_limit:
					fail_reason = "time_expired"
				else:
					fail_reason = "incomplete"

		ChallengeType.WORD_COUNT:
			passed = correct_words >= words.size()
			if not passed:
				fail_reason = "not_enough_correct"

		ChallengeType.MIXED:
			var acc_ok: bool = accuracy >= min_accuracy
			var wpm_ok: bool = wpm >= min_wpm
			var time_ok: bool = elapsed <= time_limit
			passed = acc_ok and wpm_ok and time_ok and all_words_typed
			if not passed:
				if not all_words_typed:
					fail_reason = "incomplete"
				elif not acc_ok:
					fail_reason = "accuracy_too_low"
				elif not wpm_ok:
					fail_reason = "too_slow"
				else:
					fail_reason = "time_expired"

		_:
			passed = all_words_typed
			if not passed:
				fail_reason = "incomplete"

	# Calculate score (0-100)
	var base_score: float = (float(correct_words) / maxf(float(words.size()), 1.0)) * 50.0
	var accuracy_bonus: float = accuracy * 25.0
	var speed_bonus: float = minf(wpm / 100.0, 1.0) * 25.0
	var final_score: int = int(base_score + accuracy_bonus + speed_bonus)

	return {
		"passed": passed,
		"fail_reason": fail_reason,
		"score": final_score,
		"accuracy": accuracy,
		"wpm": wpm,
		"elapsed_time": elapsed,
		"words_completed": words_completed,
		"words_total": words.size(),
		"correct_words": correct_words,
		"total_chars": total_chars,
		"correct_chars": correct_chars,
		"thresholds": {
			"min_accuracy": min_accuracy,
			"min_wpm": min_wpm,
			"time_limit": time_limit
		}
	}


# =============================================================================
# REWARD SCALING
# =============================================================================

## Scale rewards based on challenge performance
static func scale_rewards(base_rewards: Array, evaluation: Dictionary, day: int) -> Array:
	var score: int = int(evaluation.get("score", 50))
	var passed: bool = evaluation.get("passed", false)

	if not passed:
		return []  # No rewards on failure

	var scaled: Array = []
	var multiplier: float = 1.0

	# Score-based multiplier
	if score >= 90:
		multiplier = 1.5
	elif score >= 75:
		multiplier = 1.25
	elif score >= 50:
		multiplier = 1.0
	else:
		multiplier = 0.75

	# Day-based scaling (5% bonus per day after day 1)
	var day_bonus: float = 1.0 + (float(day - 1) * 0.05)
	multiplier *= day_bonus

	for reward in base_rewards:
		if typeof(reward) != TYPE_DICTIONARY:
			continue

		var scaled_reward: Dictionary = reward.duplicate()
		var effect_type: String = str(reward.get("type", ""))

		# Scale numeric rewards
		if effect_type == "resource_add":
			var amount: int = int(reward.get("amount", 0))
			scaled_reward["amount"] = int(float(amount) * multiplier)
		elif effect_type == "gold_add":
			var amount: int = int(reward.get("amount", 0))
			scaled_reward["amount"] = int(float(amount) * multiplier)
		elif effect_type == "heal_castle":
			var amount: int = int(reward.get("amount", 0))
			scaled_reward["amount"] = int(float(amount) * multiplier)

		scaled.append(scaled_reward)

	return scaled


# =============================================================================
# CHALLENGE DESCRIPTIONS
# =============================================================================

## Get human-readable challenge description
static func get_challenge_description(challenge: Dictionary) -> String:
	var challenge_type: int = int(challenge.get("type", ChallengeType.WORD_COUNT))
	var words: Array = challenge.get("words", [])
	var min_accuracy: float = float(challenge.get("min_accuracy", 0.8))
	var min_wpm: float = float(challenge.get("min_wpm", 30.0))
	var time_limit: float = float(challenge.get("time_limit", 60.0))
	var difficulty: String = str(challenge.get("difficulty", "medium"))

	var desc: String = "[%s Challenge]\n" % difficulty.capitalize()

	match challenge_type:
		ChallengeType.ACCURACY:
			desc += "Type %d words with at least %d%% accuracy." % [words.size(), int(min_accuracy * 100)]
		ChallengeType.SPEED:
			desc += "Type %d words at %d+ WPM." % [words.size(), int(min_wpm)]
		ChallengeType.TIMED:
			desc += "Type %d words within %.0f seconds." % [words.size(), time_limit]
		ChallengeType.WORD_COUNT:
			desc += "Type all %d words correctly." % words.size()
		ChallengeType.MIXED:
			desc += "Type %d words: %d%% accuracy, %d+ WPM, %.0fs limit." % [
				words.size(), int(min_accuracy * 100), int(min_wpm), time_limit
			]
		_:
			desc += "Complete the typing challenge."

	return desc


## Get result description
static func get_result_description(evaluation: Dictionary) -> String:
	var passed: bool = evaluation.get("passed", false)
	var score: int = int(evaluation.get("score", 0))
	var accuracy: float = float(evaluation.get("accuracy", 0.0))
	var wpm: float = float(evaluation.get("wpm", 0.0))
	var elapsed: float = float(evaluation.get("elapsed_time", 0.0))

	var result: String = ""

	if passed:
		if score >= 90:
			result = "Excellent! "
		elif score >= 75:
			result = "Well done! "
		else:
			result = "Challenge completed. "
	else:
		var reason: String = str(evaluation.get("fail_reason", ""))
		match reason:
			"accuracy_too_low":
				result = "Accuracy too low. "
			"too_slow":
				result = "Not fast enough. "
			"time_expired":
				result = "Time ran out. "
			"incomplete":
				result = "Challenge incomplete. "
			_:
				result = "Challenge failed. "

	result += "Score: %d | Accuracy: %d%% | Speed: %d WPM | Time: %.1fs" % [
		score, int(accuracy * 100), int(wpm), elapsed
	]

	return result
