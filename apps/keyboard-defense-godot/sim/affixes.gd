class_name SimAffixes
extends RefCounted

const GameState = preload("res://sim/types.gd")
const SimRng = preload("res://sim/rng.gd")

const AFFIXES := {
	"swift": {
		"id": "swift",
		"name": "Swift",
		"description": "Moves faster than normal",
		"speed_bonus": 1,
		"armor_bonus": 0,
		"hp_bonus": 0,
		"tier": 1,
		"glyph": "+"
	},
	"armored": {
		"id": "armored",
		"name": "Armored",
		"description": "Additional armor plating",
		"speed_bonus": 0,
		"armor_bonus": 1,
		"hp_bonus": 0,
		"tier": 1,
		"glyph": "#"
	},
	"resilient": {
		"id": "resilient",
		"name": "Resilient",
		"description": "Extra health pool",
		"speed_bonus": 0,
		"armor_bonus": 0,
		"hp_bonus": 2,
		"tier": 1,
		"glyph": "*"
	},
	"shielded": {
		"id": "shielded",
		"name": "Shielded",
		"description": "First hit is absorbed",
		"speed_bonus": 0,
		"armor_bonus": 0,
		"hp_bonus": 0,
		"tier": 2,
		"glyph": "O",
		"special": "first_hit_immunity"
	},
	"splitting": {
		"id": "splitting",
		"name": "Splitting",
		"description": "Spawns smaller enemies on death",
		"speed_bonus": 0,
		"armor_bonus": 0,
		"hp_bonus": 1,
		"tier": 2,
		"glyph": "~",
		"special": "spawn_on_death"
	},
	"regenerating": {
		"id": "regenerating",
		"name": "Regenerating",
		"description": "Slowly heals over time",
		"speed_bonus": 0,
		"armor_bonus": 0,
		"hp_bonus": 0,
		"tier": 2,
		"glyph": "^",
		"special": "regenerate"
	},
	"enraged": {
		"id": "enraged",
		"name": "Enraged",
		"description": "Speed increases when damaged",
		"speed_bonus": 0,
		"armor_bonus": 0,
		"hp_bonus": 1,
		"tier": 2,
		"glyph": "!",
		"special": "enrage_on_damage"
	},
	"vampiric": {
		"id": "vampiric",
		"name": "Vampiric",
		"description": "Heals when dealing damage",
		"speed_bonus": 0,
		"armor_bonus": 0,
		"hp_bonus": 0,
		"tier": 3,
		"glyph": "V",
		"special": "lifesteal"
	}
}

const AFFIX_TIERS := {
	1: ["swift", "armored", "resilient"],
	2: ["shielded", "splitting", "regenerating", "enraged"],
	3: ["vampiric"]
}

static func get_affix(affix_id: String) -> Dictionary:
	return AFFIXES.get(affix_id, {})

static func get_all_affixes() -> Array:
	var result: Array = []
	for affix_id in AFFIXES:
		result.append(AFFIXES[affix_id])
	return result

static func get_affixes_for_tier(tier: int) -> Array:
	var result: Array = []
	var tier_affixes: Array = AFFIX_TIERS.get(tier, [])
	for affix_id in tier_affixes:
		if AFFIXES.has(affix_id):
			result.append(AFFIXES[affix_id])
	return result

static func get_available_affixes(day: int) -> Array:
	var result: Array = []
	# Tier 1 always available
	for affix in get_affixes_for_tier(1):
		result.append(affix)
	# Tier 2 available after day 4
	if day >= 4:
		for affix in get_affixes_for_tier(2):
			result.append(affix)
	# Tier 3 available after day 7
	if day >= 7:
		for affix in get_affixes_for_tier(3):
			result.append(affix)
	return result

static func roll_affix(state: GameState) -> String:
	var available: Array = get_available_affixes(state.day)
	if available.is_empty():
		return ""
	var affix: Variant = SimRng.choose(state, available)
	if affix == null or typeof(affix) != TYPE_DICTIONARY:
		return ""
	return str(affix.get("id", ""))

static func should_have_affix(state: GameState, enemy_kind: String) -> bool:
	# Elite enemies always have affixes
	if enemy_kind == "elite":
		return true
	# Champion enemies have high affix chance
	if enemy_kind == "champion":
		return SimRng.roll_range(state, 1, 100) <= 75
	# Regular enemies gain affix chance based on day
	var base_chance: int = 0
	if state.day >= 5:
		base_chance = (state.day - 4) * 5  # 5% at day 5, 10% at day 6, etc.
	if base_chance <= 0:
		return false
	return SimRng.roll_range(state, 1, 100) <= base_chance

static func apply_affix_to_enemy(enemy: Dictionary, affix_id: String) -> Dictionary:
	var affix: Dictionary = get_affix(affix_id)
	if affix.is_empty():
		return enemy
	# Apply stat bonuses
	enemy["speed"] = int(enemy.get("speed", 1)) + int(affix.get("speed_bonus", 0))
	enemy["armor"] = int(enemy.get("armor", 0)) + int(affix.get("armor_bonus", 0))
	enemy["hp"] = int(enemy.get("hp", 1)) + int(affix.get("hp_bonus", 0))
	# Store affix data
	enemy["affix"] = affix_id
	# Initialize special state if needed
	var special: String = str(affix.get("special", ""))
	match special:
		"first_hit_immunity":
			enemy["shield_active"] = true
		"regenerate":
			enemy["regen_counter"] = 0
		"enrage_on_damage":
			enemy["enraged"] = false
	return enemy

static func make_elite_enemy(state: GameState, enemy: Dictionary) -> Dictionary:
	var affix_id: String = roll_affix(state)
	if affix_id == "":
		return enemy
	return apply_affix_to_enemy(enemy, affix_id)

static func process_regeneration(enemy: Dictionary) -> Dictionary:
	if not enemy.has("affix") or str(enemy.get("affix", "")) != "regenerating":
		return enemy
	var counter: int = int(enemy.get("regen_counter", 0)) + 1
	enemy["regen_counter"] = counter
	# Heal 1 HP every 3 ticks
	if counter >= 3:
		enemy["hp"] = int(enemy.get("hp", 0)) + 1
		enemy["regen_counter"] = 0
	return enemy

static func process_shield_hit(enemy: Dictionary) -> Dictionary:
	if not enemy.has("shield_active") or not bool(enemy.get("shield_active", false)):
		return enemy
	# Shield absorbs the hit
	enemy["shield_active"] = false
	return enemy

static func has_active_shield(enemy: Dictionary) -> bool:
	return bool(enemy.get("shield_active", false))

static func process_enrage(enemy: Dictionary) -> Dictionary:
	if not enemy.has("affix") or str(enemy.get("affix", "")) != "enraged":
		return enemy
	if bool(enemy.get("enraged", false)):
		return enemy
	# Trigger enrage on first damage
	enemy["enraged"] = true
	enemy["speed"] = int(enemy.get("speed", 1)) + 1
	return enemy

static func get_affix_glyph(affix_id: String) -> String:
	var affix: Dictionary = get_affix(affix_id)
	return str(affix.get("glyph", ""))

static func get_affix_name(affix_id: String) -> String:
	var affix: Dictionary = get_affix(affix_id)
	return str(affix.get("name", ""))

static func serialize_affix_state(enemy: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	if enemy.has("affix"):
		result["affix"] = str(enemy.get("affix", ""))
	if enemy.has("shield_active"):
		result["shield_active"] = bool(enemy.get("shield_active", false))
	if enemy.has("regen_counter"):
		result["regen_counter"] = int(enemy.get("regen_counter", 0))
	if enemy.has("enraged"):
		result["enraged"] = bool(enemy.get("enraged", false))
	return result

static func deserialize_affix_state(enemy: Dictionary, raw: Dictionary) -> Dictionary:
	if raw.has("affix"):
		enemy["affix"] = str(raw.get("affix", ""))
	if raw.has("shield_active"):
		enemy["shield_active"] = bool(raw.get("shield_active", false))
	if raw.has("regen_counter"):
		enemy["regen_counter"] = int(raw.get("regen_counter", 0))
	if raw.has("enraged"):
		enemy["enraged"] = bool(raw.get("enraged", false))
	return enemy
