class_name SimLoot
extends RefCounted

## Combat loot drop system - handles enemy drops based on typing performance.
## Drop rates and quality scale with player accuracy and combo performance.

const GameState = preload("res://sim/types.gd")
const SimRng = preload("res://sim/rng.gd")

const LOOT_PATH := "res://data/loot_tables.json"

# Quality tiers based on typing performance
const QUALITY_TIERS := {
	"poor": {"multiplier": 0.5, "min_accuracy": 0.0, "max_accuracy": 0.6},
	"normal": {"multiplier": 1.0, "min_accuracy": 0.6, "max_accuracy": 0.85},
	"good": {"multiplier": 1.25, "min_accuracy": 0.85, "max_accuracy": 0.95},
	"excellent": {"multiplier": 1.5, "min_accuracy": 0.95, "max_accuracy": 0.99},
	"perfect": {"multiplier": 2.0, "min_accuracy": 0.99, "max_accuracy": 1.01}
}

static var _loot_tables: Dictionary = {}
static var _loaded: bool = false


static func _load_if_needed() -> void:
	if _loaded:
		return
	if not FileAccess.file_exists(LOOT_PATH):
		push_warning("SimLoot: Loot tables not found at %s" % LOOT_PATH)
		_loaded = true
		return
	var file := FileAccess.open(LOOT_PATH, FileAccess.READ)
	if file == null:
		push_warning("SimLoot: Failed to open loot tables")
		_loaded = true
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	if err != OK:
		push_warning("SimLoot: JSON parse error: %s" % json.get_error_message())
		_loaded = true
		return
	_loot_tables = json.data
	_loaded = true


static func get_loot_table(enemy_kind: String) -> Dictionary:
	_load_if_needed()
	var enemy_drops: Dictionary = _loot_tables.get("enemy_drops", {})
	return enemy_drops.get(enemy_kind, {})


static func get_boss_loot_table(boss_id: String) -> Dictionary:
	_load_if_needed()
	var boss_drops: Dictionary = _loot_tables.get("boss_drops", {})
	return boss_drops.get(boss_id, {})


static func calculate_quality_tier(accuracy: float, is_perfect: bool) -> String:
	if is_perfect:
		return "perfect"
	for tier_name in ["excellent", "good", "normal", "poor"]:
		var tier: Dictionary = QUALITY_TIERS[tier_name]
		if accuracy >= tier["min_accuracy"] and accuracy < tier["max_accuracy"]:
			return tier_name
	return "poor"


static func get_quality_multiplier(tier: String) -> float:
	if QUALITY_TIERS.has(tier):
		return QUALITY_TIERS[tier]["multiplier"]
	return 1.0


static func roll_loot(state: GameState, enemy_kind: String, is_boss: bool) -> Dictionary:
	## Roll loot drops for a defeated enemy. Returns dictionary of resources.
	_load_if_needed()

	var table: Dictionary
	if is_boss:
		table = get_boss_loot_table(enemy_kind)
	else:
		table = get_loot_table(enemy_kind)

	if table.is_empty():
		return {}

	var loot: Dictionary = {}
	var quality_mult: float = state.last_loot_quality

	# Add guaranteed drops
	var guaranteed: Dictionary = table.get("guaranteed", {})
	for resource in guaranteed.keys():
		var amount: int = int(float(guaranteed[resource]) * quality_mult)
		if amount > 0:
			loot[resource] = loot.get(resource, 0) + amount

	# Roll for chance-based drops
	var drops: Array = table.get("drops", [])
	for drop in drops:
		var chance: float = float(drop.get("chance", 0.0))
		var roll: float = float(SimRng.roll_range(state, 0, 1000)) / 1000.0
		if roll <= chance:
			var resource: String = str(drop.get("resource", ""))
			var amount: int = int(float(drop.get("amount", 0)) * quality_mult)
			if amount > 0 and resource != "":
				loot[resource] = loot.get(resource, 0) + amount

	# Add perfect kill bonus if applicable
	if state.last_loot_quality >= 2.0:  # Perfect tier
		var perfect_bonus: Dictionary = table.get("perfect_bonus", {})
		for resource in perfect_bonus.keys():
			var amount: int = int(perfect_bonus[resource])
			if amount > 0:
				loot[resource] = loot.get(resource, 0) + amount

	return loot


static func queue_loot(state: GameState, loot: Dictionary) -> void:
	## Add loot to pending collection queue.
	if loot.is_empty():
		return
	state.loot_pending.append(loot)


static func collect_pending_loot(state: GameState) -> Dictionary:
	## Collect all pending loot and add to resources. Returns total collected.
	var total: Dictionary = {}

	for loot in state.loot_pending:
		for resource in loot.keys():
			var amount: int = int(loot[resource])
			total[resource] = total.get(resource, 0) + amount

			# Apply to state
			if resource == "gold":
				state.gold += amount
			elif state.resources.has(resource):
				state.resources[resource] += amount

	state.loot_pending.clear()
	return {"collected": total}


static func get_pending_loot_summary(state: GameState) -> Dictionary:
	## Get summary of pending loot without collecting it.
	var total: Dictionary = {}
	for loot in state.loot_pending:
		for resource in loot.keys():
			total[resource] = total.get(resource, 0) + int(loot[resource])
	return total


static func format_loot_brief(loot: Dictionary) -> String:
	## Format loot dictionary as brief string for events.
	var parts: Array[String] = []
	for resource in loot.keys():
		var amount: int = int(loot[resource])
		if amount > 0:
			parts.append("+%d %s" % [amount, resource])
	return ", ".join(parts)


static func update_quality_from_performance(state: GameState, accuracy: float, had_mistakes: bool) -> void:
	## Update loot quality multiplier based on typing performance.
	var is_perfect: bool = accuracy >= 1.0 and not had_mistakes
	var tier: String = calculate_quality_tier(accuracy, is_perfect)
	state.last_loot_quality = get_quality_multiplier(tier)

	if is_perfect:
		state.perfect_kills += 1


static func reset_wave_stats(state: GameState) -> void:
	## Reset per-wave loot tracking stats.
	state.perfect_kills = 0
	state.last_loot_quality = 1.0
