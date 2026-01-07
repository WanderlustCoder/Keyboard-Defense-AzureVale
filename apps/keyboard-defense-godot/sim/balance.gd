class_name SimBalance
extends RefCounted

const GameState = preload("res://sim/types.gd")

const MIDGAME_STONE_CATCHUP_DAY := 4
const MIDGAME_STONE_CATCHUP_MIN := 10

const MIDGAME_FOOD_BONUS_DAY := 4
const MIDGAME_FOOD_BONUS_THRESHOLD := 12
const MIDGAME_FOOD_BONUS_AMOUNT := 2

const MIDGAME_CAPS_DAY5 := {"wood": 40, "stone": 20, "food": 25}
const MIDGAME_CAPS_DAY7 := {"wood": 50, "stone": 35, "food": 35}

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
