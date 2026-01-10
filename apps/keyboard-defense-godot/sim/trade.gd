class_name SimTrade
extends RefCounted

const GameState = preload("res://sim/types.gd")
const SimBuildings = preload("res://sim/buildings.gd")
const SimMap = preload("res://sim/map.gd")

# Base exchange rates (how much you get per 1 unit traded)
const BASE_RATES := {
	"wood_to_stone": 0.67,     # 3 wood -> 2 stone
	"stone_to_wood": 1.5,      # 2 stone -> 3 wood
	"wood_to_food": 1.0,       # 1 wood -> 1 food
	"food_to_wood": 1.0,       # 1 food -> 1 wood
	"stone_to_food": 1.5,      # 2 stone -> 3 food
	"food_to_stone": 0.67,     # 3 food -> 2 stone
	"wood_to_gold": 0.33,      # 3 wood -> 1 gold
	"gold_to_wood": 3.0,       # 1 gold -> 3 wood
	"stone_to_gold": 0.5,      # 2 stone -> 1 gold
	"gold_to_stone": 2.0,      # 1 gold -> 2 stone
	"food_to_gold": 0.5,       # 2 food -> 1 gold
	"gold_to_food": 2.0        # 1 gold -> 2 food
}

# Rate variance based on day (simulates market fluctuation)
const RATE_VARIANCE := 0.15  # +/- 15% variance

# Check if trading is enabled (requires Level 3 Market)
static func is_trading_enabled(state: GameState) -> bool:
	for key in state.structures.keys():
		var building_type: String = str(state.structures[key])
		if building_type == "market":
			var level: int = SimBuildings.structure_level(state, int(key))
			if level >= 3:
				return true
	return false

# Get current trade rates (may vary by day)
static func get_rates(state: GameState) -> Dictionary:
	var rates: Dictionary = state.trade_rates.duplicate(true)

	# If rates are empty or day changed, recalculate
	if rates.is_empty() or state.last_trade_day != state.day:
		rates = _calculate_rates(state)
		state.trade_rates = rates.duplicate(true)
		state.last_trade_day = state.day

	return rates

# Calculate rates with daily variance
static func _calculate_rates(state: GameState) -> Dictionary:
	var rates: Dictionary = {}

	# Use day as seed for consistent rates within a day
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(state.rng_seed) + str(state.day))

	for rate_key in BASE_RATES.keys():
		var base_rate: float = BASE_RATES[rate_key]
		var variance: float = rng.randf_range(-RATE_VARIANCE, RATE_VARIANCE)
		rates[rate_key] = base_rate * (1.0 + variance)

	# Apply market bonuses
	var market_bonus: float = _get_market_bonus(state)
	if market_bonus > 0:
		for rate_key in rates.keys():
			# Better rates with market bonus
			if rate_key.ends_with("_to_gold"):
				# Get more gold when selling
				rates[rate_key] = rates[rate_key] * (1.0 + market_bonus)
			else:
				# Pay less when buying
				rates[rate_key] = rates[rate_key] * (1.0 + market_bonus * 0.5)

	return rates

# Get market bonus from market buildings
static func _get_market_bonus(state: GameState) -> float:
	var bonus: float = 0.0

	for key in state.structures.keys():
		var building_type: String = str(state.structures[key])
		if building_type == "market":
			var level: int = SimBuildings.structure_level(state, int(key))
			bonus += 0.05 * level  # 5% per market level

	return min(bonus, 0.3)  # Cap at 30%

# Get rate key for a trade
static func _get_rate_key(from_resource: String, to_resource: String) -> String:
	return from_resource + "_to_" + to_resource

# Calculate how much you get for a trade
static func calculate_trade(state: GameState, from_resource: String, to_resource: String, amount: int) -> Dictionary:
	var result := {
		"ok": false,
		"reason": "",
		"from_resource": from_resource,
		"to_resource": to_resource,
		"from_amount": amount,
		"to_amount": 0,
		"rate": 0.0
	}

	# Check trading is enabled
	if not is_trading_enabled(state):
		result.reason = "trading not enabled (need Level 3 Market)"
		return result

	# Validate resources
	var valid_resources := ["wood", "stone", "food", "gold"]
	if from_resource not in valid_resources or to_resource not in valid_resources:
		result.reason = "invalid resource"
		return result

	if from_resource == to_resource:
		result.reason = "cannot trade same resource"
		return result

	if amount <= 0:
		result.reason = "invalid amount"
		return result

	# Check we have enough
	var have: int
	if from_resource == "gold":
		have = state.gold
	else:
		have = int(state.resources.get(from_resource, 0))

	if have < amount:
		result.reason = "not enough " + from_resource
		return result

	# Get rate
	var rate_key: String = _get_rate_key(from_resource, to_resource)
	var rates: Dictionary = get_rates(state)

	if not rates.has(rate_key):
		result.reason = "trade not available"
		return result

	var rate: float = rates[rate_key]
	var to_amount: int = int(floor(float(amount) * rate))

	if to_amount <= 0:
		result.reason = "trade amount too small"
		return result

	result.ok = true
	result.to_amount = to_amount
	result.rate = rate

	return result

# Execute a trade
static func execute_trade(state: GameState, from_resource: String, to_resource: String, amount: int) -> Dictionary:
	var calc: Dictionary = calculate_trade(state, from_resource, to_resource, amount)
	if not calc.ok:
		return calc

	# Deduct from resource
	if from_resource == "gold":
		state.gold -= amount
	else:
		state.resources[from_resource] = int(state.resources.get(from_resource, 0)) - amount

	# Add to resource
	if to_resource == "gold":
		state.gold += calc.to_amount
	else:
		state.resources[to_resource] = int(state.resources.get(to_resource, 0)) + calc.to_amount

	return calc

# Parse a trade command like "10 wood for stone" or "trade 5 food to gold"
static func parse_trade_command(command: String) -> Dictionary:
	var result := {
		"ok": false,
		"from_resource": "",
		"to_resource": "",
		"amount": 0,
		"reason": ""
	}

	# Normalize the command
	command = command.to_lower().strip_edges()

	# Remove "trade" prefix if present
	if command.begins_with("trade "):
		command = command.substr(6).strip_edges()

	# Try to parse: "<amount> <resource> for/to <resource>"
	var parts: Array = command.split(" ")
	if parts.size() < 4:
		result.reason = "invalid format"
		return result

	# First part should be amount
	if not parts[0].is_valid_int():
		result.reason = "invalid amount"
		return result

	var amount: int = int(parts[0])
	if amount <= 0:
		result.reason = "amount must be positive"
		return result

	# Second part should be from_resource
	var from_resource: String = parts[1]

	# Third part should be "for" or "to"
	if parts[2] != "for" and parts[2] != "to":
		result.reason = "expected 'for' or 'to'"
		return result

	# Fourth part should be to_resource
	var to_resource: String = parts[3]

	result.ok = true
	result.amount = amount
	result.from_resource = from_resource
	result.to_resource = to_resource

	return result

# Get available trades summary
static func get_trade_summary(state: GameState) -> Dictionary:
	var summary := {
		"enabled": is_trading_enabled(state),
		"market_bonus": _get_market_bonus(state),
		"rates": {},
		"resources": {
			"wood": int(state.resources.get("wood", 0)),
			"stone": int(state.resources.get("stone", 0)),
			"food": int(state.resources.get("food", 0)),
			"gold": state.gold
		}
	}

	if summary.enabled:
		summary.rates = get_rates(state)

	return summary

# Get suggested trades based on current resources
static func get_suggested_trades(state: GameState) -> Array:
	var suggestions: Array = []

	if not is_trading_enabled(state):
		return suggestions

	var resources := {
		"wood": int(state.resources.get("wood", 0)),
		"stone": int(state.resources.get("stone", 0)),
		"food": int(state.resources.get("food", 0)),
		"gold": state.gold
	}

	var rates: Dictionary = get_rates(state)

	# Find resources we have a lot of
	var avg: float = float(resources["wood"] + resources["stone"] + resources["food"]) / 3.0
	var high_threshold: float = avg * 1.5
	var low_threshold: float = avg * 0.5

	for from_res in ["wood", "stone", "food"]:
		if resources[from_res] > high_threshold:
			# We have excess, suggest trading
			for to_res in ["wood", "stone", "food", "gold"]:
				if from_res == to_res:
					continue
				if to_res != "gold" and resources[to_res] > low_threshold:
					continue  # Don't suggest if target is not low

				var rate_key: String = _get_rate_key(from_res, to_res)
				if rates.has(rate_key):
					var trade_amount: int = int(resources[from_res] * 0.3)  # Suggest trading 30%
					if trade_amount > 0:
						suggestions.append({
							"from": from_res,
							"to": to_res,
							"amount": trade_amount,
							"receive": int(floor(float(trade_amount) * rates[rate_key])),
							"rate": rates[rate_key]
						})

	return suggestions
