class_name SimBalance
extends RefCounted
## Balance constants and formulas for Keyboard Defense.
## Centralizes all game balance tuning values.

const GameState = preload("res://sim/types.gd")

# =============================================================================
# ECONOMY CONSTANTS
# =============================================================================

## Resource catch-up mechanics
const MIDGAME_STONE_CATCHUP_DAY := 4
const MIDGAME_STONE_CATCHUP_MIN := 10
const MIDGAME_FOOD_BONUS_DAY := 4
const MIDGAME_FOOD_BONUS_THRESHOLD := 12
const MIDGAME_FOOD_BONUS_AMOUNT := 2

## Resource caps by day (prevents hoarding)
const MIDGAME_CAPS_DAY5 := {"wood": 40, "stone": 20, "food": 25}
const MIDGAME_CAPS_DAY7 := {"wood": 50, "stone": 35, "food": 35}
const ENDGAME_CAPS := {"wood": 100, "stone": 75, "food": 50, "gold": 1000}

## Starting resources
const STARTING_RESOURCES := {"wood": 10, "stone": 5, "food": 5, "gold": 0}

## Worker costs and limits
const WORKER_HIRE_COST := 10  # Gold per worker
const MAX_WORKERS_BASE := 5
const MAX_WORKERS_PER_HOUSE := 2

# =============================================================================
# COMBAT CONSTANTS
# =============================================================================

## Base enemy HP formula: base + (day/divisor) + (threat/divisor)
const ENEMY_HP_BASE := 2
const ENEMY_HP_DAY_DIVISOR := 3
const ENEMY_HP_THREAT_DIVISOR := 4

## Boss HP formula: base + (day/divisor) + hp_bonus
const BOSS_HP_BASE := 10
const BOSS_HP_DAY_DIVISOR := 2
const BOSS_HP_THREAT_DIVISOR := 3

## Wave spawn rates
const WAVE_ENEMY_BASE_COUNT := 3
const WAVE_ENEMY_PER_DAY := 1
const WAVE_ENEMY_PER_THREAT := 0.5

## Threat mechanics
const THREAT_MAX := 10
const THREAT_WAVE_THRESHOLD := 5  # Threat level that triggers wave assault

## Typing damage calculation
const TYPING_BASE_DAMAGE := 1
const TYPING_WPM_BONUS_THRESHOLD := 60  # WPM to get bonus damage
const TYPING_WPM_BONUS_DAMAGE := 1
const TYPING_ACCURACY_BONUS_THRESHOLD := 0.95
const TYPING_ACCURACY_BONUS_DAMAGE := 1
const TYPING_COMBO_BONUS_MULTIPLIER := 0.1  # +10% damage per 10 combo

# =============================================================================
# TOWER CONSTANTS
# =============================================================================

## Tower upgrade scaling
const TOWER_UPGRADE_DAMAGE_MULT := 1.25  # 25% more damage per upgrade
const TOWER_UPGRADE_COST_MULT := 1.5     # 50% more cost per upgrade
const TOWER_MAX_LEVEL := 5

## Tower placement limits
const TOWER_MIN_DISTANCE_FROM_BASE := 2
const TOWER_MAX_LEGENDARY_COUNT := 1

# =============================================================================
# PROGRESSION MILESTONES
# =============================================================================

## Expected player progression by day
const PROGRESSION_MILESTONES := {
	1: {"buildings": 1, "towers": 0, "gold": 0},
	3: {"buildings": 3, "towers": 1, "gold": 20},
	5: {"buildings": 5, "towers": 2, "gold": 50},  # First boss
	7: {"buildings": 7, "towers": 3, "gold": 100},
	10: {"buildings": 10, "towers": 5, "gold": 200},  # Second boss
	15: {"buildings": 15, "towers": 7, "gold": 400},  # Third boss
	20: {"buildings": 20, "towers": 10, "gold": 750}  # Final boss
}

## Victory condition thresholds
const VICTORY_GOLD_TARGET := 10000
const VICTORY_SURVIVAL_WAVES := 50

static func maybe_override_explore_reward(state: GameState, reward_resource: String) -> String:
	if state.day < MIDGAME_STONE_CATCHUP_DAY:
		return reward_resource
	if int(state.resources.get("stone", 0)) >= MIDGAME_STONE_CATCHUP_MIN:
		return reward_resource
	return "stone"

static func midgame_food_bonus(state: GameState) -> int:
	if state.day < MIDGAME_FOOD_BONUS_DAY:
		return 0
	if int(state.resources.get("food", 0)) >= MIDGAME_FOOD_BONUS_THRESHOLD:
		return 0
	return MIDGAME_FOOD_BONUS_AMOUNT

static func caps_for_day(day: int) -> Dictionary:
	if day >= 7:
		return MIDGAME_CAPS_DAY7
	if day >= 5:
		return MIDGAME_CAPS_DAY5
	return {}

static func apply_resource_caps(state: GameState) -> Dictionary:
	var caps: Dictionary = caps_for_day(state.day)
	var trimmed: Dictionary = {}
	for key in caps.keys():
		var cap: int = int(caps.get(key, 0))
		var value: int = int(state.resources.get(key, 0))
		if value > cap:
			var delta: int = value - cap
			state.resources[key] = cap
			trimmed[key] = delta
	return trimmed


# =============================================================================
# BALANCE CALCULATION HELPERS
# =============================================================================

## Calculate base enemy HP for a given day and threat level
static func calculate_enemy_hp(day: int, threat: int) -> int:
	return ENEMY_HP_BASE + int(day / ENEMY_HP_DAY_DIVISOR) + int(threat / ENEMY_HP_THREAT_DIVISOR)


## Calculate boss HP for a given day and threat level
static func calculate_boss_hp(day: int, threat: int, hp_bonus: int = 0) -> int:
	return BOSS_HP_BASE + int(day / BOSS_HP_DAY_DIVISOR) + int(threat / BOSS_HP_THREAT_DIVISOR) + hp_bonus


## Calculate wave enemy count for a given day and threat level
static func calculate_wave_size(day: int, threat: int) -> int:
	var count := WAVE_ENEMY_BASE_COUNT + int(day * WAVE_ENEMY_PER_DAY) + int(float(threat) * WAVE_ENEMY_PER_THREAT)
	return max(1, count)


## Calculate typing damage with bonuses
static func calculate_typing_damage(base_damage: int, wpm: float, accuracy: float, combo: int) -> int:
	var damage := base_damage

	# WPM bonus
	if wpm >= TYPING_WPM_BONUS_THRESHOLD:
		damage += TYPING_WPM_BONUS_DAMAGE

	# Accuracy bonus
	if accuracy >= TYPING_ACCURACY_BONUS_THRESHOLD:
		damage += TYPING_ACCURACY_BONUS_DAMAGE

	# Combo multiplier
	var combo_bonus := 1.0 + (float(combo / 10) * TYPING_COMBO_BONUS_MULTIPLIER)
	damage = int(float(damage) * combo_bonus)

	return max(1, damage)


## Calculate tower upgrade cost
static func calculate_upgrade_cost(base_cost: Dictionary, current_level: int) -> Dictionary:
	var multiplier := pow(TOWER_UPGRADE_COST_MULT, current_level)
	var result: Dictionary = {}
	for resource in base_cost.keys():
		result[resource] = int(float(base_cost[resource]) * multiplier)
	return result


## Calculate tower damage at level
static func calculate_tower_damage(base_damage: int, level: int) -> int:
	var multiplier := pow(TOWER_UPGRADE_DAMAGE_MULT, level - 1)
	return int(float(base_damage) * multiplier)


## Check if player is meeting progression milestones
static func check_milestone(day: int, buildings: int, towers: int, gold: int) -> Dictionary:
	var milestone: Dictionary = PROGRESSION_MILESTONES.get(day, {})
	if milestone.is_empty():
		return {"on_track": true, "issues": []}

	var issues: Array[String] = []
	var expected_buildings: int = milestone.get("buildings", 0)
	var expected_towers: int = milestone.get("towers", 0)
	var expected_gold: int = milestone.get("gold", 0)

	if buildings < expected_buildings:
		issues.append("Buildings behind (%d/%d)" % [buildings, expected_buildings])
	if towers < expected_towers:
		issues.append("Towers behind (%d/%d)" % [towers, expected_towers])
	if gold < expected_gold:
		issues.append("Gold behind (%d/%d)" % [gold, expected_gold])

	return {
		"on_track": issues.is_empty(),
		"issues": issues
	}


## Get difficulty scaling factor for current day
static func get_difficulty_factor(day: int) -> float:
	# Smooth scaling: starts at 1.0, reaches 2.0 by day 10, 3.0 by day 20
	return 1.0 + (float(day - 1) / 10.0)


## Calculate gold reward for enemy with day scaling
static func calculate_gold_reward(base_gold: int, day: int) -> int:
	# Gold rewards scale slightly with day to keep pace with economy
	var scaling := 1.0 + (float(day) * 0.05)  # +5% per day
	return int(float(base_gold) * scaling)
