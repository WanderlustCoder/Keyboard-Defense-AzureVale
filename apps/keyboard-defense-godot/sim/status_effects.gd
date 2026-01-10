class_name SimStatusEffects
extends RefCounted
## Status effects system - applies debuffs, buffs, and DoT to enemies

# Effect category constants
const CATEGORY_DEBUFF := "debuff"
const CATEGORY_BUFF := "buff"
const CATEGORY_NEUTRAL := "neutral"

# Effect IDs - Movement
const EFFECT_SLOW := "slow"
const EFFECT_FROZEN := "frozen"
const EFFECT_ROOTED := "rooted"

# Effect IDs - Damage over Time
const EFFECT_BURNING := "burning"
const EFFECT_POISONED := "poisoned"
const EFFECT_BLEEDING := "bleeding"
const EFFECT_CORRUPTING := "corrupting"

# Effect IDs - Defensive Reduction
const EFFECT_ARMOR_BROKEN := "armor_broken"
const EFFECT_EXPOSED := "exposed"
const EFFECT_WEAKENED := "weakened"

# Effect IDs - Special
const EFFECT_MARKED := "marked"
const EFFECT_PURIFYING := "purifying"
const EFFECT_CONFUSED := "confused"

const EFFECTS: Dictionary = {
	# Movement Effects
	"slow": {
		"name": "Slowed",
		"description": "Movement speed reduced",
		"category": "debuff",
		"target": "enemy",
		"tiers": [
			{"tier": 1, "slow_percent": 15, "duration": 2.0},
			{"tier": 2, "slow_percent": 25, "duration": 3.0},
			{"tier": 3, "slow_percent": 40, "duration": 4.0},
			{"tier": 4, "slow_percent": 60, "duration": 5.0}
		],
		"max_slow": 80,
		"can_stack": true,
		"color": "#87CEEB"
	},
	"frozen": {
		"name": "Frozen",
		"description": "Completely immobilized",
		"category": "debuff",
		"target": "enemy",
		"duration": 1.5,
		"damage_vulnerability": 1.5,
		"immobilize": true,
		"immunity_duration": 5.0,
		"color": "#00BFFF"
	},
	"rooted": {
		"name": "Rooted",
		"description": "Held in place by roots",
		"category": "debuff",
		"target": "enemy",
		"duration": 2.0,
		"immobilize": true,
		"can_still_attack": true,
		"color": "#228B22"
	},
	# Damage Over Time
	"burning": {
		"name": "Burning",
		"description": "Taking fire damage over time",
		"category": "debuff",
		"target": "enemy",
		"duration": 5.0,
		"max_stacks": 5,
		"tick_damage": 3,
		"tick_interval": 1.0,
		"damage_type": "fire",
		"removed_by": ["frozen", "wet"],
		"color": "#FF4500"
	},
	"poisoned": {
		"name": "Poisoned",
		"description": "Taking poison damage over time",
		"category": "debuff",
		"target": "enemy",
		"duration": 8.0,
		"max_stacks": 10,
		"tick_damage": 2,
		"tick_interval": 1.0,
		"damage_type": "poison",
		"healing_reduction": 0.5,
		"stack_behavior": "damage_increase",
		"color": "#9932CC"
	},
	"bleeding": {
		"name": "Bleeding",
		"description": "Losing health from wounds",
		"category": "debuff",
		"target": "enemy",
		"duration": 6.0,
		"max_stacks": 3,
		"tick_damage": 4,
		"tick_interval": 2.0,
		"damage_type": "physical",
		"movement_refreshes": true,
		"color": "#8B0000"
	},
	"corrupting": {
		"name": "Corrupting",
		"description": "Being unmade by corruption",
		"category": "debuff",
		"target": "enemy",
		"duration": 10.0,
		"max_stacks": 1,
		"tick_damage": 5,
		"tick_interval": 1.0,
		"damage_type": "corruption",
		"reduces_max_hp": true,
		"hp_reduction_per_tick": 0.02,
		"color": "#4B0082"
	},
	# Defensive Reduction
	"armor_broken": {
		"name": "Armor Broken",
		"description": "Armor reduced significantly",
		"category": "debuff",
		"target": "enemy",
		"duration": 8.0,
		"armor_reduction_percent": 50,
		"color": "#808080"
	},
	"exposed": {
		"name": "Exposed",
		"description": "Taking increased damage from all sources",
		"category": "debuff",
		"target": "enemy",
		"duration": 5.0,
		"damage_taken_increase": 0.25,
		"color": "#FF69B4"
	},
	"weakened": {
		"name": "Weakened",
		"description": "Dealing reduced damage",
		"category": "debuff",
		"target": "enemy",
		"duration": 6.0,
		"damage_dealt_reduction": 0.30,
		"color": "#D3D3D3"
	},
	# Special Effects
	"marked": {
		"name": "Marked",
		"description": "Targeted for priority attack",
		"category": "debuff",
		"target": "enemy",
		"duration": 10.0,
		"all_towers_prioritize": true,
		"critical_chance_against": 0.25,
		"color": "#FF0000"
	},
	"purifying": {
		"name": "Purifying",
		"description": "Corruption being cleansed",
		"category": "debuff",
		"target": "enemy",
		"duration": 3.0,
		"channeled": true,
		"bonus_damage_to_corrupted": 1.5,
		"color": "#FFD700"
	},
	"confused": {
		"name": "Confused",
		"description": "Moving erratically",
		"category": "debuff",
		"target": "enemy",
		"duration": 3.0,
		"random_direction_change_interval": 0.5,
		"attack_allies_chance": 0.15,
		"color": "#FFFF00"
	}
}


## Get effect data by ID
static func get_effect(effect_id: String) -> Dictionary:
	return EFFECTS.get(effect_id, {})


## Get effect name for display
static func get_effect_name(effect_id: String) -> String:
	var effect: Dictionary = get_effect(effect_id)
	return str(effect.get("name", effect_id.capitalize()))


## Get effect color for visual display
static func get_effect_color(effect_id: String) -> Color:
	var effect: Dictionary = get_effect(effect_id)
	var hex: String = str(effect.get("color", "#FFFFFF"))
	return Color.from_string(hex, Color.WHITE)


## Get effect description
static func get_effect_description(effect_id: String) -> String:
	var effect: Dictionary = get_effect(effect_id)
	return str(effect.get("description", ""))


## Get effect duration (base duration for tier 1 or non-tiered)
static func get_effect_duration(effect_id: String, tier: int = 1) -> float:
	var effect: Dictionary = get_effect(effect_id)
	if effect.has("tiers"):
		var tiers: Array = effect.get("tiers", [])
		for tier_data in tiers:
			if typeof(tier_data) == TYPE_DICTIONARY and int(tier_data.get("tier", 0)) == tier:
				return float(tier_data.get("duration", 5.0))
		return 5.0
	return float(effect.get("duration", 5.0))


## Create a status effect instance for an enemy
static func create_effect(effect_id: String, tier: int = 1, source: String = "") -> Dictionary:
	var effect: Dictionary = get_effect(effect_id)
	if effect.is_empty():
		return {}

	var instance := {
		"effect_id": effect_id,
		"tier": tier,
		"stacks": 1,
		"remaining_duration": get_effect_duration(effect_id, tier),
		"tick_timer": 0.0,
		"source": source
	}
	return instance


## Apply a status effect to an enemy
static func apply_effect(enemy: Dictionary, effect_id: String, tier: int = 1, source: String = "") -> Dictionary:
	var effect_def: Dictionary = get_effect(effect_id)
	if effect_def.is_empty():
		return enemy

	# Initialize effects array if needed
	if not enemy.has("status_effects"):
		enemy["status_effects"] = []

	var effects: Array = enemy["status_effects"]
	var existing_index: int = -1

	# Check for existing effect
	for i in range(effects.size()):
		if typeof(effects[i]) == TYPE_DICTIONARY and str(effects[i].get("effect_id", "")) == effect_id:
			existing_index = i
			break

	if existing_index >= 0:
		# Effect already exists - handle stacking
		var existing: Dictionary = effects[existing_index]
		var max_stacks: int = int(effect_def.get("max_stacks", 1))
		var can_stack: bool = effect_def.get("can_stack", false) or max_stacks > 1

		if can_stack and int(existing.get("stacks", 1)) < max_stacks:
			existing["stacks"] = int(existing.get("stacks", 1)) + 1

		# Refresh duration
		existing["remaining_duration"] = get_effect_duration(effect_id, tier)

		# Upgrade tier if higher
		if tier > int(existing.get("tier", 1)):
			existing["tier"] = tier

		effects[existing_index] = existing
	else:
		# Apply new effect
		var new_effect: Dictionary = create_effect(effect_id, tier, source)
		if not new_effect.is_empty():
			effects.append(new_effect)

	enemy["status_effects"] = effects
	return enemy


## Remove a status effect from an enemy
static func remove_effect(enemy: Dictionary, effect_id: String) -> Dictionary:
	if not enemy.has("status_effects"):
		return enemy

	var effects: Array = enemy["status_effects"]
	var new_effects: Array = []

	for effect in effects:
		if typeof(effect) == TYPE_DICTIONARY and str(effect.get("effect_id", "")) != effect_id:
			new_effects.append(effect)

	enemy["status_effects"] = new_effects
	return enemy


## Check if enemy has a specific effect
static func has_effect(enemy: Dictionary, effect_id: String) -> bool:
	if not enemy.has("status_effects"):
		return false

	var effects: Array = enemy["status_effects"]
	for effect in effects:
		if typeof(effect) == TYPE_DICTIONARY and str(effect.get("effect_id", "")) == effect_id:
			return true
	return false


## Get effect instance from enemy (or empty dict if not present)
static func get_enemy_effect(enemy: Dictionary, effect_id: String) -> Dictionary:
	if not enemy.has("status_effects"):
		return {}

	var effects: Array = enemy["status_effects"]
	for effect in effects:
		if typeof(effect) == TYPE_DICTIONARY and str(effect.get("effect_id", "")) == effect_id:
			return effect
	return {}


## Get total slow percent on enemy (capped at max_slow)
static func get_slow_percent(enemy: Dictionary) -> float:
	var slow_effect: Dictionary = get_enemy_effect(enemy, EFFECT_SLOW)
	if slow_effect.is_empty():
		return 0.0

	var effect_def: Dictionary = get_effect(EFFECT_SLOW)
	var tier: int = int(slow_effect.get("tier", 1))
	var stacks: int = int(slow_effect.get("stacks", 1))
	var max_slow: float = float(effect_def.get("max_slow", 80))

	# Get slow percent from tier
	var base_slow: float = 15.0
	var tiers: Array = effect_def.get("tiers", [])
	for tier_data in tiers:
		if typeof(tier_data) == TYPE_DICTIONARY and int(tier_data.get("tier", 0)) == tier:
			base_slow = float(tier_data.get("slow_percent", 15))
			break

	# Apply stacks (diminishing returns)
	var total_slow: float = base_slow + (stacks - 1) * (base_slow * 0.5)
	return min(total_slow, max_slow)


## Check if enemy is immobilized (frozen or rooted)
static func is_immobilized(enemy: Dictionary) -> bool:
	return has_effect(enemy, EFFECT_FROZEN) or has_effect(enemy, EFFECT_ROOTED)


## Get damage multiplier from effects (exposed increases damage taken)
static func get_damage_taken_multiplier(enemy: Dictionary) -> float:
	var multiplier: float = 1.0

	# Exposed effect
	if has_effect(enemy, EFFECT_EXPOSED):
		var effect_def: Dictionary = get_effect(EFFECT_EXPOSED)
		multiplier += float(effect_def.get("damage_taken_increase", 0.25))

	# Frozen effect increases damage
	if has_effect(enemy, EFFECT_FROZEN):
		var effect_def: Dictionary = get_effect(EFFECT_FROZEN)
		multiplier *= float(effect_def.get("damage_vulnerability", 1.5))

	return multiplier


## Get damage dealt reduction for enemy attacks
static func get_damage_dealt_reduction(enemy: Dictionary) -> float:
	if has_effect(enemy, EFFECT_WEAKENED):
		var effect_def: Dictionary = get_effect(EFFECT_WEAKENED)
		return float(effect_def.get("damage_dealt_reduction", 0.30))
	return 0.0


## Get armor reduction from effects
static func get_armor_reduction_percent(enemy: Dictionary) -> float:
	if has_effect(enemy, EFFECT_ARMOR_BROKEN):
		var effect_def: Dictionary = get_effect(EFFECT_ARMOR_BROKEN)
		return float(effect_def.get("armor_reduction_percent", 50)) / 100.0
	return 0.0


## Get effective armor after status effects
static func get_effective_armor(enemy: Dictionary) -> int:
	var base_armor: int = int(enemy.get("armor", 0))
	var reduction: float = get_armor_reduction_percent(enemy)
	return max(0, int(base_armor * (1.0 - reduction)))


## Get effective speed after status effects
static func get_effective_speed(enemy: Dictionary) -> int:
	var base_speed: int = int(enemy.get("speed", 1))

	# Immobilized = 0 speed
	if is_immobilized(enemy):
		return 0

	# Apply slow
	var slow_percent: float = get_slow_percent(enemy)
	if slow_percent > 0:
		var speed_mult: float = 1.0 - (slow_percent / 100.0)
		return max(1, int(base_speed * speed_mult))

	return base_speed


## Tick all effects on an enemy, returns damage dealt and expired effect IDs
static func tick_effects(enemy: Dictionary, delta: float) -> Dictionary:
	var result := {
		"damage": 0,
		"expired": [],
		"events": []
	}

	if not enemy.has("status_effects"):
		return result

	var effects: Array = enemy["status_effects"]
	var remaining_effects: Array = []

	for effect in effects:
		if typeof(effect) != TYPE_DICTIONARY:
			continue

		var effect_id: String = str(effect.get("effect_id", ""))
		var effect_def: Dictionary = get_effect(effect_id)
		if effect_def.is_empty():
			continue

		# Tick duration
		effect["remaining_duration"] = float(effect.get("remaining_duration", 0)) - delta

		# Handle tick damage (DoT effects)
		if effect_def.has("tick_damage") and effect_def.has("tick_interval"):
			effect["tick_timer"] = float(effect.get("tick_timer", 0)) + delta
			var tick_interval: float = float(effect_def.get("tick_interval", 1.0))

			while float(effect.get("tick_timer", 0)) >= tick_interval:
				effect["tick_timer"] = float(effect.get("tick_timer", 0)) - tick_interval
				var tick_damage: int = int(effect_def.get("tick_damage", 0))
				var stacks: int = int(effect.get("stacks", 1))

				# Stack behavior
				if str(effect_def.get("stack_behavior", "")) == "damage_increase":
					tick_damage = tick_damage * stacks

				result["damage"] += tick_damage
				result["events"].append("%s dealt %d %s damage" % [
					get_effect_name(effect_id),
					tick_damage,
					str(effect_def.get("damage_type", ""))
				])

				# Corruption reduces max HP
				if effect_def.get("reduces_max_hp", false):
					var reduction: float = float(effect_def.get("hp_reduction_per_tick", 0.02))
					var max_hp: int = int(enemy.get("hp_max", enemy.get("hp", 10)))
					var new_max: int = max(1, int(max_hp * (1.0 - reduction)))
					enemy["hp_max"] = new_max
					if int(enemy.get("hp", 0)) > new_max:
						enemy["hp"] = new_max

		# Check expiration
		if float(effect.get("remaining_duration", 0)) <= 0:
			result["expired"].append(effect_id)
			result["events"].append("%s wore off" % get_effect_name(effect_id))

			# Handle immunity after frozen
			if effect_id == EFFECT_FROZEN:
				enemy["freeze_immunity"] = float(effect_def.get("immunity_duration", 5.0))
		else:
			remaining_effects.append(effect)

	enemy["status_effects"] = remaining_effects

	# Tick freeze immunity
	if enemy.has("freeze_immunity"):
		enemy["freeze_immunity"] = float(enemy.get("freeze_immunity", 0)) - delta
		if float(enemy.get("freeze_immunity", 0)) <= 0:
			enemy.erase("freeze_immunity")

	return result


## Check if enemy can be frozen (respects immunity)
static func can_be_frozen(enemy: Dictionary) -> bool:
	return not enemy.has("freeze_immunity")


## Handle effect interactions (e.g., frozen removes burning)
static func apply_effect_interactions(enemy: Dictionary, new_effect_id: String) -> Dictionary:
	var effect_def: Dictionary = get_effect(new_effect_id)

	# Check what effects this removes
	var removes: Array = effect_def.get("removed_by", [])

	# Frozen/wet removes burning
	if new_effect_id == EFFECT_FROZEN:
		enemy = remove_effect(enemy, EFFECT_BURNING)

	# Burning removes frozen (mutual destruction)
	if new_effect_id == EFFECT_BURNING and has_effect(enemy, EFFECT_FROZEN):
		enemy = remove_effect(enemy, EFFECT_FROZEN)
		enemy = remove_effect(enemy, EFFECT_BURNING)

	return enemy


## Get all active effect IDs on enemy
static func get_active_effect_ids(enemy: Dictionary) -> Array[String]:
	var result: Array[String] = []
	if not enemy.has("status_effects"):
		return result

	var effects: Array = enemy["status_effects"]
	for effect in effects:
		if typeof(effect) == TYPE_DICTIONARY:
			result.append(str(effect.get("effect_id", "")))
	return result


## Get status effect summary for UI display
static func get_effect_summary(enemy: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not enemy.has("status_effects"):
		return result

	var effects: Array = enemy["status_effects"]
	for effect in effects:
		if typeof(effect) != TYPE_DICTIONARY:
			continue

		var effect_id: String = str(effect.get("effect_id", ""))
		var effect_def: Dictionary = get_effect(effect_id)

		result.append({
			"id": effect_id,
			"name": get_effect_name(effect_id),
			"stacks": int(effect.get("stacks", 1)),
			"duration": float(effect.get("remaining_duration", 0)),
			"color": get_effect_color(effect_id)
		})

	return result


## Format effect for display (e.g., "Burning x3 (2.5s)")
static func format_effect_display(effect: Dictionary) -> String:
	var effect_id: String = str(effect.get("effect_id", ""))
	var name: String = get_effect_name(effect_id)
	var stacks: int = int(effect.get("stacks", 1))
	var duration: float = float(effect.get("remaining_duration", 0))

	if stacks > 1:
		return "%s x%d (%.1fs)" % [name, stacks, duration]
	return "%s (%.1fs)" % [name, duration]


## Serialize status effects for save/load
static func serialize_effects(effects: Array) -> Array:
	var result: Array = []
	for effect in effects:
		if typeof(effect) == TYPE_DICTIONARY:
			result.append({
				"effect_id": str(effect.get("effect_id", "")),
				"tier": int(effect.get("tier", 1)),
				"stacks": int(effect.get("stacks", 1)),
				"remaining_duration": float(effect.get("remaining_duration", 0)),
				"tick_timer": float(effect.get("tick_timer", 0)),
				"source": str(effect.get("source", ""))
			})
	return result


## Deserialize status effects from save data
static func deserialize_effects(data: Array) -> Array:
	var result: Array = []
	for item in data:
		if typeof(item) == TYPE_DICTIONARY:
			result.append({
				"effect_id": str(item.get("effect_id", "")),
				"tier": int(item.get("tier", 1)),
				"stacks": int(item.get("stacks", 1)),
				"remaining_duration": float(item.get("remaining_duration", 0)),
				"tick_timer": float(item.get("tick_timer", 0)),
				"source": str(item.get("source", ""))
			})
	return result
