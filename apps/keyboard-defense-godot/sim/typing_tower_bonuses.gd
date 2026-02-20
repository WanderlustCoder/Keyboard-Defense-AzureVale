class_name SimTypingTowerBonuses
extends RefCounted
## Tower damage bonuses based on typing performance

const GameState = preload("res://sim/types.gd")
const SimTowerTypes = preload("res://sim/tower_types.gd")
const SimTypingMetrics = preload("res://sim/typing_metrics.gd")
const SimUpgrades = preload("res://sim/upgrades.gd")

# =============================================================================
# CONSTANTS
# =============================================================================

# Wordsmith's Forge scaling
const WORDSMITH_WPM_SCALE := 100.0  # base * (1 + WPM/100)
const WORDSMITH_ACCURACY_POWER := 2.0  # accuracy squared

# Arcane Tower scaling
const ARCANE_MAX_ACCURACY_BONUS := 1.5  # 150% at 100% accuracy

# Letter Spirit Shrine scaling
const LETTER_SPIRIT_PER_LETTER := 0.05  # 5% per unique letter
const LETTER_SPIRIT_MAX_BONUS := 1.30  # Max 130% bonus (26 letters)

# Accuracy threshold for bonus activation
const MIN_ACCURACY_FOR_BONUS := 0.5  # 50% accuracy minimum

# =============================================================================
# TOWER-SPECIFIC BONUSES
# =============================================================================

## Get damage multiplier for a specific tower based on typing performance
static func get_tower_damage_multiplier(
	state: GameState,
	tower_id: String
) -> float:
	var multiplier: float = 1.0

	# Get combo multiplier (applies to all towers)
	# Base combo from typing streak + research bonus
	var combo_mult: float = SimTypingMetrics.get_combo_multiplier(state)
	combo_mult += SimUpgrades.get_combo_multiplier(state)  # Research bonus (additive)
	multiplier *= combo_mult

	# Apply tower-specific bonuses
	match tower_id:
		SimTowerTypes.TOWER_WORDSMITH:
			multiplier *= _get_wordsmith_bonus(state)

		SimTowerTypes.TOWER_ARCANE:
			multiplier *= _get_arcane_bonus(state)

		SimTowerTypes.TOWER_SHRINE:
			multiplier *= _get_letter_shrine_bonus(state)

		SimTowerTypes.TOWER_ARROW, SimTowerTypes.TOWER_MULTI:
			# Arrow towers get small accuracy bonus
			multiplier *= _get_accuracy_bonus(state, 0.2)

		SimTowerTypes.TOWER_MAGIC:
			# Magic towers get moderate accuracy bonus
			multiplier *= _get_accuracy_bonus(state, 0.3)

		SimTowerTypes.TOWER_FROST:
			# Frost effectiveness scales with accuracy
			multiplier *= _get_accuracy_bonus(state, 0.25)

		SimTowerTypes.TOWER_HOLY, SimTowerTypes.TOWER_PURIFIER:
			# Holy towers benefit from perfect streaks
			multiplier *= _get_perfect_streak_bonus(state)

		SimTowerTypes.TOWER_TESLA:
			# Chain lightning improves with combo
			multiplier *= _get_chain_bonus(state)

		SimTowerTypes.TOWER_SIEGE:
			# Siege benefits from sustained typing
			multiplier *= _get_sustained_bonus(state)

	return multiplier


## Get chain count bonus for Tesla/chain towers
static func get_chain_bonus(state: GameState, tower_id: String) -> int:
	if tower_id != SimTowerTypes.TOWER_TESLA:
		return 0

	var combo: int = SimTypingMetrics.get_combo_count(state)

	# Extra chains at high combos
	if combo >= 50:
		return 3
	elif combo >= 20:
		return 2
	elif combo >= 10:
		return 1

	return 0


## Get attack speed multiplier based on WPM
static func get_attack_speed_multiplier(state: GameState, tower_id: String) -> float:
	var wpm: float = SimTypingMetrics.get_wpm(state)

	# Base speed multiplier scales with WPM
	var speed_mult: float = 1.0 + (wpm / 200.0)  # +50% at 100 WPM

	# Cap at reasonable values
	return clamp(speed_mult, 1.0, 2.0)


# =============================================================================
# INTERNAL BONUS CALCULATIONS
# =============================================================================

## Wordsmith's Forge bonus: base * (1 + WPM/100) * accuracy^2
static func _get_wordsmith_bonus(state: GameState) -> float:
	var wpm: float = SimTypingMetrics.get_wpm(state)
	var accuracy: float = SimTypingMetrics.get_accuracy(state)

	if accuracy < MIN_ACCURACY_FOR_BONUS:
		return 1.0

	var wpm_bonus: float = 1.0 + (wpm / WORDSMITH_WPM_SCALE)
	var accuracy_mult: float = pow(accuracy, WORDSMITH_ACCURACY_POWER)

	return wpm_bonus * accuracy_mult


## Arcane Tower bonus: scales to 1.5x at 100% accuracy
static func _get_arcane_bonus(state: GameState) -> float:
	var accuracy: float = SimTypingMetrics.get_accuracy(state)

	if accuracy < MIN_ACCURACY_FOR_BONUS:
		return 1.0

	# Linear scaling from 1.0 at 50% accuracy to 1.5 at 100%
	var bonus: float = 1.0 + (accuracy - MIN_ACCURACY_FOR_BONUS) * (ARCANE_MAX_ACCURACY_BONUS - 1.0) / (1.0 - MIN_ACCURACY_FOR_BONUS)

	return bonus


## Letter Spirit Shrine bonus: +5% per unique letter
static func _get_letter_shrine_bonus(state: GameState) -> float:
	var unique_count: int = SimTypingMetrics.get_unique_letter_count(state)

	var bonus: float = 1.0 + (float(unique_count) * LETTER_SPIRIT_PER_LETTER)

	return min(bonus, 1.0 + LETTER_SPIRIT_MAX_BONUS)


## Generic accuracy bonus
static func _get_accuracy_bonus(state: GameState, max_bonus: float) -> float:
	var accuracy: float = SimTypingMetrics.get_accuracy(state)

	if accuracy < MIN_ACCURACY_FOR_BONUS:
		return 1.0

	# Scale from 1.0 to (1.0 + max_bonus)
	var bonus: float = 1.0 + (accuracy - MIN_ACCURACY_FOR_BONUS) * max_bonus / (1.0 - MIN_ACCURACY_FOR_BONUS)

	return bonus


## Perfect streak bonus for Holy towers
static func _get_perfect_streak_bonus(state: GameState) -> float:
	var streak: int = SimTypingMetrics.get_perfect_streak(state)

	# +10% per perfect word, capped at +50%
	var bonus: float = 1.0 + min(float(streak) * 0.1, 0.5)

	return bonus


## Chain bonus for Tesla tower (combo based)
static func _get_chain_bonus(state: GameState) -> float:
	var combo: int = SimTypingMetrics.get_combo_count(state)

	# +2% per combo hit, capped at +50%
	var bonus: float = 1.0 + min(float(combo) * 0.02, 0.5)

	return bonus


## Sustained typing bonus for Siege tower
static func _get_sustained_bonus(state: GameState) -> float:
	var chars: int = SimTypingMetrics.get_chars_typed(state)
	var duration: float = SimTypingMetrics.get_battle_duration(state)

	if duration < 5.0:  # Need at least 5 seconds
		return 1.0

	# Bonus based on sustained typing rate
	var chars_per_sec: float = float(chars) / duration

	# 10 chars/sec = +50% bonus
	var bonus: float = 1.0 + min(chars_per_sec * 0.05, 0.5)

	return bonus


# =============================================================================
# LETTER SPIRIT SHRINE SPECIAL MODES
# =============================================================================

## Determine Letter Spirit Shrine attack mode based on typing
static func get_letter_shrine_mode(state: GameState) -> String:
	var unique_count: int = SimTypingMetrics.get_unique_letter_count(state)
	var combo: int = SimTypingMetrics.get_combo_count(state)
	var wpm: float = SimTypingMetrics.get_wpm(state)

	# Epsilon mode: Many unique letters, chain attack
	if unique_count >= 20:
		return "epsilon"

	# Omega mode: High combo, healing on kill
	if combo >= 30:
		return "omega"

	# Alpha mode: Default focused single target
	return "alpha"


## Get Letter Spirit Shrine mode description
static func get_letter_shrine_mode_description(mode: String) -> String:
	match mode:
		"alpha":
			return "Alpha: Focused single-target damage"
		"epsilon":
			return "Epsilon: Chain lightning to multiple targets"
		"omega":
			return "Omega: Heals castle on enemy kill"
		_:
			return "Unknown mode"


# =============================================================================
# WORD-SPECIFIC BONUSES
# =============================================================================

## Check if a word triggers a tower's word bonus
static func get_word_bonus(
	state: GameState,
	tower_id: String,
	word: String
) -> float:
	var tower_data: Dictionary = SimTowerTypes.get_tower_data(tower_id)
	var word_bonus: Dictionary = tower_data.get("word_bonus", {})

	if word_bonus.is_empty():
		return 1.0

	var pattern: String = str(word_bonus.get("pattern", ""))
	var bonus_mult: float = float(word_bonus.get("multiplier", 1.5))

	if pattern.is_empty():
		return 1.0

	# Check word length bonus
	if pattern.begins_with("length>="):
		var min_len: int = int(pattern.substr(8))
		if word.length() >= min_len:
			return bonus_mult
	# Check prefix bonus
	elif pattern.begins_with("prefix:"):
		var prefix: String = pattern.substr(7)
		if word.to_lower().begins_with(prefix):
			return bonus_mult
	# Check suffix bonus
	elif pattern.begins_with("suffix:"):
		var suffix: String = pattern.substr(7)
		if word.to_lower().ends_with(suffix):
			return bonus_mult
	# Check contains bonus
	elif pattern.begins_with("contains:"):
		var substr: String = pattern.substr(9)
		if word.to_lower().contains(substr):
			return bonus_mult
	# Check double letter bonus
	elif pattern == "double_letter":
		for i in range(word.length() - 1):
			if word[i] == word[i + 1]:
				return bonus_mult
	# Check all same letter bonus
	elif pattern == "all_same":
		if word.length() > 0:
			var first: String = word[0]
			var all_same: bool = true
			for c in word:
				if c != first:
					all_same = false
					break
			if all_same:
				return bonus_mult

	return 1.0


# =============================================================================
# SUMMARY
# =============================================================================

## Get all active bonuses for a tower
static func get_active_bonuses(state: GameState, tower_id: String) -> Dictionary:
	return {
		"combo_multiplier": SimTypingMetrics.get_combo_multiplier(state),
		"tower_multiplier": get_tower_damage_multiplier(state, tower_id),
		"attack_speed": get_attack_speed_multiplier(state, tower_id),
		"chain_bonus": get_chain_bonus(state, tower_id),
		"wpm": SimTypingMetrics.get_wpm(state),
		"accuracy": SimTypingMetrics.get_accuracy(state),
		"combo": SimTypingMetrics.get_combo_count(state),
		"unique_letters": SimTypingMetrics.get_unique_letter_count(state)
	}
