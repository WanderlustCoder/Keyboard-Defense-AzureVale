class_name SimTowerTypes
extends RefCounted
## Tower type definitions, enums, and constants for the defense tower system

# =============================================================================
# ENUMS
# =============================================================================

## Tower category - determines unlock requirements
enum TowerCategory {
	BASIC,      # Available from tutorial
	ADVANCED,   # Unlock at level 10+
	SPECIALIST, # Unlock at level 18+
	LEGENDARY   # Quest/achievement unlock, limited to 1 per game
}

## Damage type - affects how damage interacts with armor and resistances
enum DamageType {
	PHYSICAL,   # Reduced by armor
	MAGICAL,    # Ignores armor
	COLD,       # Slows, reduced damage
	POISON,     # DoT, stacks, ignores half armor
	LIGHTNING,  # Chains, bonus vs wet
	HOLY,       # Bonus vs affixed/corrupted
	FIRE,       # DoT, bonus vs frozen
	PURE        # Ignores all resistances
}

## Target type - how the tower selects targets
enum TargetType {
	SINGLE,     # One target, closest to base
	MULTI,      # N targets simultaneously
	AOE,        # Radius-based splash around primary target
	CHAIN,      # Jumps between targets with falloff
	ADAPTIVE,   # Changes based on situation (legendary)
	NONE        # Non-attacking tower (support, trap)
}

## Attack type - the tower's core mechanic
enum AttackType {
	STANDARD,   # Basic ranged attack
	PIERCE,     # Ignores armor
	SLOW,       # Applies slow effect
	DOT,        # Damage over time (stacking)
	CHARGE,     # Builds damage over turns
	PURIFY,     # Removes enemy affixes
	SUMMON,     # Spawns allied units
	TRAP,       # Places triggered damage zones
	AURA        # Buffs nearby towers
}

# =============================================================================
# TOWER TYPE IDS
# =============================================================================

# Basic towers (Tutorial unlock)
const TOWER_ARROW := "tower_arrow"
const TOWER_MAGIC := "tower_magic"
const TOWER_FROST := "tower_frost"
const TOWER_CANNON := "tower_cannon"

# Advanced towers (Level 10+ unlock)
const TOWER_MULTI := "tower_multi"
const TOWER_ARCANE := "tower_arcane"
const TOWER_HOLY := "tower_holy"
const TOWER_SIEGE := "tower_siege"

# Specialist towers (Level 18+ unlock)
const TOWER_POISON := "tower_poison"
const TOWER_TESLA := "tower_tesla"
const TOWER_SUMMONER := "tower_summoner"
const TOWER_SUPPORT := "tower_support"
const TOWER_TRAP := "tower_trap"

# Legendary towers (Quest/Achievement unlock)
const TOWER_WORDSMITH := "tower_legendary_wordsmith"
const TOWER_SHRINE := "tower_legendary_shrine"
const TOWER_PURIFIER := "tower_legendary_purifier"

# All tower type IDs
const ALL_TOWER_IDS: Array[String] = [
	TOWER_ARROW, TOWER_MAGIC, TOWER_FROST, TOWER_CANNON,
	TOWER_MULTI, TOWER_ARCANE, TOWER_HOLY, TOWER_SIEGE,
	TOWER_POISON, TOWER_TESLA, TOWER_SUMMONER, TOWER_SUPPORT, TOWER_TRAP,
	TOWER_WORDSMITH, TOWER_SHRINE, TOWER_PURIFIER
]

# Category groupings
const CATEGORY_BASIC: Array[String] = [TOWER_ARROW, TOWER_MAGIC, TOWER_FROST, TOWER_CANNON]
const CATEGORY_ADVANCED: Array[String] = [TOWER_MULTI, TOWER_ARCANE, TOWER_HOLY, TOWER_SIEGE]
const CATEGORY_SPECIALIST: Array[String] = [TOWER_POISON, TOWER_TESLA, TOWER_SUMMONER, TOWER_SUPPORT, TOWER_TRAP]
const CATEGORY_LEGENDARY: Array[String] = [TOWER_WORDSMITH, TOWER_SHRINE, TOWER_PURIFIER]

# =============================================================================
# FOOTPRINT SIZES
# =============================================================================

const FOOTPRINT_1X1 := Vector2i(1, 1)
const FOOTPRINT_2X2 := Vector2i(2, 2)
const FOOTPRINT_3X3 := Vector2i(3, 3)

const FOOTPRINT_SIZES: Dictionary = {
	TOWER_ARROW: FOOTPRINT_1X1,
	TOWER_MAGIC: FOOTPRINT_1X1,
	TOWER_FROST: FOOTPRINT_1X1,
	TOWER_CANNON: FOOTPRINT_2X2,
	TOWER_MULTI: FOOTPRINT_1X1,
	TOWER_ARCANE: FOOTPRINT_1X1,
	TOWER_HOLY: FOOTPRINT_1X1,
	TOWER_SIEGE: FOOTPRINT_2X2,
	TOWER_POISON: FOOTPRINT_1X1,
	TOWER_TESLA: FOOTPRINT_1X1,
	TOWER_SUMMONER: FOOTPRINT_2X2,
	TOWER_SUPPORT: FOOTPRINT_1X1,
	TOWER_TRAP: FOOTPRINT_1X1,
	TOWER_WORDSMITH: FOOTPRINT_2X2,
	TOWER_SHRINE: FOOTPRINT_3X3,
	TOWER_PURIFIER: FOOTPRINT_2X2
}

# =============================================================================
# BASE TOWER STATS
# =============================================================================

## Base stats for all tower types at level 1
const TOWER_STATS: Dictionary = {
	TOWER_ARROW: {
		"name": "Arrow Tower",
		"category": TowerCategory.BASIC,
		"damage_type": DamageType.PHYSICAL,
		"target_type": TargetType.SINGLE,
		"attack_type": AttackType.STANDARD,
		"damage": 10,
		"range": 4,
		"attack_speed": 1.0,
		"shots_per_attack": 1,
		"cost": {"wood": 4, "stone": 8}
	},
	TOWER_MAGIC: {
		"name": "Magic Tower",
		"category": TowerCategory.BASIC,
		"damage_type": DamageType.MAGICAL,
		"target_type": TargetType.SINGLE,
		"attack_type": AttackType.PIERCE,
		"damage": 15,
		"range": 5,
		"attack_speed": 0.7,
		"shots_per_attack": 1,
		"armor_pierce": true,
		"cost": {"wood": 6, "stone": 10, "gold": 10}
	},
	TOWER_FROST: {
		"name": "Frost Tower",
		"category": TowerCategory.BASIC,
		"damage_type": DamageType.COLD,
		"target_type": TargetType.SINGLE,
		"attack_type": AttackType.SLOW,
		"damage": 5,
		"range": 3,
		"attack_speed": 0.8,
		"shots_per_attack": 1,
		"slow_percent": 25,
		"slow_duration": 2.0,
		"cost": {"wood": 5, "stone": 8}
	},
	TOWER_CANNON: {
		"name": "Cannon Tower",
		"category": TowerCategory.BASIC,
		"damage_type": DamageType.PHYSICAL,
		"target_type": TargetType.AOE,
		"attack_type": AttackType.STANDARD,
		"damage": 25,
		"range": 4,
		"attack_speed": 0.4,
		"shots_per_attack": 1,
		"aoe_radius": 1,
		"cost": {"wood": 8, "stone": 15, "gold": 15}
	},
	TOWER_MULTI: {
		"name": "Multi-Shot Tower",
		"category": TowerCategory.ADVANCED,
		"damage_type": DamageType.PHYSICAL,
		"target_type": TargetType.MULTI,
		"attack_type": AttackType.STANDARD,
		"damage": 8,
		"range": 4,
		"attack_speed": 0.8,
		"shots_per_attack": 1,
		"target_count": 3,
		"cost": {"wood": 10, "stone": 15, "gold": 50}
	},
	TOWER_ARCANE: {
		"name": "Arcane Tower",
		"category": TowerCategory.ADVANCED,
		"damage_type": DamageType.MAGICAL,
		"target_type": TargetType.SINGLE,
		"attack_type": AttackType.PIERCE,
		"damage": 20,
		"range": 5,
		"attack_speed": 0.6,
		"shots_per_attack": 1,
		"accuracy_scaling": true,
		"cost": {"wood": 8, "stone": 12, "gold": 75}
	},
	TOWER_HOLY: {
		"name": "Holy Tower",
		"category": TowerCategory.ADVANCED,
		"damage_type": DamageType.HOLY,
		"target_type": TargetType.SINGLE,
		"attack_type": AttackType.PURIFY,
		"damage": 18,
		"range": 4,
		"attack_speed": 0.7,
		"shots_per_attack": 1,
		"purify_chance": 5,
		"corruption_bonus_percent": 50,
		"cost": {"stone": 20, "gold": 100}
	},
	TOWER_SIEGE: {
		"name": "Siege Tower",
		"category": TowerCategory.ADVANCED,
		"damage_type": DamageType.PHYSICAL,
		"target_type": TargetType.SINGLE,
		"attack_type": AttackType.CHARGE,
		"damage": 100,
		"range": 6,
		"attack_speed": 0.15,
		"shots_per_attack": 1,
		"charge_time": 5,
		"charge_damage_bonus_per_word": 0.1,
		"max_charge_multiplier": 2.0,
		"cost": {"wood": 15, "stone": 25, "gold": 125}
	},
	TOWER_POISON: {
		"name": "Venomspire",
		"category": TowerCategory.SPECIALIST,
		"damage_type": DamageType.POISON,
		"target_type": TargetType.SINGLE,
		"attack_type": AttackType.DOT,
		"damage": 3,
		"range": 4,
		"attack_speed": 1.2,
		"shots_per_attack": 1,
		"poison_damage_per_tick": 5,
		"poison_duration": 5.0,
		"poison_max_stacks": 10,
		"cost": {"wood": 10, "stone": 15, "gold": 100}
	},
	TOWER_TESLA: {
		"name": "Tesla Coil",
		"category": TowerCategory.SPECIALIST,
		"damage_type": DamageType.LIGHTNING,
		"target_type": TargetType.CHAIN,
		"attack_type": AttackType.STANDARD,
		"damage": 12,
		"range": 3,
		"attack_speed": 0.5,
		"shots_per_attack": 1,
		"chain_count": 5,
		"chain_range": 2,
		"chain_damage_falloff": 0.8,
		"cost": {"wood": 8, "stone": 20, "gold": 110}
	},
	TOWER_SUMMONER: {
		"name": "Summoning Circle",
		"category": TowerCategory.SPECIALIST,
		"damage_type": DamageType.PHYSICAL,
		"target_type": TargetType.NONE,
		"attack_type": AttackType.SUMMON,
		"damage": 0,
		"range": 0,
		"attack_speed": 0,
		"shots_per_attack": 0,
		"max_summons": 3,
		"summon_cooldown": 15.0,
		"default_summon": "word_warrior",
		"cost": {"stone": 25, "gold": 150}
	},
	TOWER_SUPPORT: {
		"name": "Command Post",
		"category": TowerCategory.SPECIALIST,
		"damage_type": DamageType.PHYSICAL,
		"target_type": TargetType.NONE,
		"attack_type": AttackType.AURA,
		"damage": 0,
		"range": 0,
		"attack_speed": 0,
		"shots_per_attack": 0,
		"aura_range": 3,
		"damage_buff_percent": 15,
		"speed_buff_percent": 10,
		"cost": {"wood": 12, "stone": 18, "gold": 120}
	},
	TOWER_TRAP: {
		"name": "Trap Nexus",
		"category": TowerCategory.SPECIALIST,
		"damage_type": DamageType.PHYSICAL,
		"target_type": TargetType.NONE,
		"attack_type": AttackType.TRAP,
		"damage": 30,
		"range": 0,
		"attack_speed": 0,
		"shots_per_attack": 0,
		"trap_count": 3,
		"trap_recharge_time": 10.0,
		"trap_radius": 1,
		"placement_range": 5,
		"cost": {"wood": 10, "stone": 12, "gold": 90}
	},
	TOWER_WORDSMITH: {
		"name": "Wordsmith's Forge",
		"category": TowerCategory.LEGENDARY,
		"damage_type": DamageType.PURE,
		"target_type": TargetType.ADAPTIVE,
		"attack_type": AttackType.STANDARD,
		"damage": 25,
		"range": 5,
		"attack_speed": 1.0,
		"shots_per_attack": 1,
		"wpm_scaling": true,
		"accuracy_scaling": true,
		"word_forge_threshold": 50,
		"word_forge_damage": 200,
		"perfect_strike_threshold": 10,
		"perfect_strike_damage": 500,
		"placement_limit": 1,
		"cost": {"wood": 30, "stone": 50, "gold": 500}
	},
	TOWER_SHRINE: {
		"name": "Letter Spirit Shrine",
		"category": TowerCategory.LEGENDARY,
		"damage_type": DamageType.HOLY,
		"target_type": TargetType.ADAPTIVE,
		"attack_type": AttackType.STANDARD,
		"damage": 50,
		"range": 6,
		"attack_speed": 0.5,
		"shots_per_attack": 1,
		"letter_bonus_percent": 5,
		"letter_max_bonus": 130,
		"letter_window_seconds": 10,
		"spirit_modes": ["alpha", "epsilon", "omega"],
		"placement_limit": 1,
		"cost": {"stone": 60, "gold": 600}
	},
	TOWER_PURIFIER: {
		"name": "Corruption Purifier",
		"category": TowerCategory.LEGENDARY,
		"damage_type": DamageType.HOLY,
		"target_type": TargetType.SINGLE,
		"attack_type": AttackType.PURIFY,
		"damage": 40,
		"range": 5,
		"attack_speed": 0.6,
		"shots_per_attack": 1,
		"purify_chance": 25,
		"corruption_bonus_percent": 100,
		"mass_purification_cooldown": 30.0,
		"mass_purification_range": 5,
		"final_word_phrase": "CORRUPTION END",
		"final_word_damage": 500,
		"placement_limit": 1,
		"cost": {"stone": 45, "gold": 750}
	}
}

# =============================================================================
# SUMMON TYPES
# =============================================================================

const SUMMON_TYPES: Dictionary = {
	"word_warrior": {
		"name": "Word Warrior",
		"hp": 50,
		"damage": 8,
		"attack_speed": 1.0,
		"movement_speed": 1,
		"range": 1
	},
	"letter_sprite": {
		"name": "Letter Sprite",
		"hp": 25,
		"damage": 15,
		"attack_speed": 1.5,
		"movement_speed": 2,
		"range": 2,
		"flying": true
	},
	"grammar_golem": {
		"name": "Grammar Golem",
		"hp": 150,
		"damage": 20,
		"attack_speed": 0.5,
		"movement_speed": 1,
		"range": 1,
		"taunt": true
	}
}

# =============================================================================
# TRAP TYPES
# =============================================================================

const TRAP_TYPES: Dictionary = {
	"explosive": {
		"name": "Explosive Trap",
		"damage": 30,
		"radius": 1.0,
		"effect": null
	},
	"frost": {
		"name": "Frost Trap",
		"damage": 10,
		"radius": 1.5,
		"effect": "slow",
		"slow_percent": 50,
		"slow_duration": 3.0
	},
	"poison": {
		"name": "Poison Trap",
		"damage": 5,
		"radius": 1.0,
		"effect": "poisoned",
		"poison_damage": 10,
		"poison_duration": 5.0
	},
	"stun": {
		"name": "Stun Trap",
		"damage": 15,
		"radius": 0.5,
		"effect": "frozen",
		"stun_duration": 2.0
	}
}

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

## Check if tower type ID is valid
static func is_valid_tower_type(tower_id: String) -> bool:
	return tower_id in ALL_TOWER_IDS


## Get tower category enum from tower ID
static func get_category(tower_id: String) -> TowerCategory:
	if tower_id in CATEGORY_BASIC:
		return TowerCategory.BASIC
	if tower_id in CATEGORY_ADVANCED:
		return TowerCategory.ADVANCED
	if tower_id in CATEGORY_SPECIALIST:
		return TowerCategory.SPECIALIST
	if tower_id in CATEGORY_LEGENDARY:
		return TowerCategory.LEGENDARY
	return TowerCategory.BASIC


## Get tower category name string
static func get_category_name(tower_id: String) -> String:
	match get_category(tower_id):
		TowerCategory.BASIC:
			return "Basic"
		TowerCategory.ADVANCED:
			return "Advanced"
		TowerCategory.SPECIALIST:
			return "Specialist"
		TowerCategory.LEGENDARY:
			return "Legendary"
	return "Unknown"


## Get footprint size for a tower type
static func get_footprint(tower_id: String) -> Vector2i:
	return FOOTPRINT_SIZES.get(tower_id, FOOTPRINT_1X1)


## Check if tower has multi-tile footprint
static func is_multi_tile(tower_id: String) -> bool:
	var size: Vector2i = get_footprint(tower_id)
	return size.x > 1 or size.y > 1


## Get base stats for a tower type
static func get_base_stats(tower_id: String) -> Dictionary:
	return TOWER_STATS.get(tower_id, {}).duplicate(true)


## Get tower name
static func get_tower_name(tower_id: String) -> String:
	var stats: Dictionary = TOWER_STATS.get(tower_id, {})
	return str(stats.get("name", tower_id.capitalize()))


## Get full tower data (stats, cost, abilities, etc.)
static func get_tower_data(tower_id: String) -> Dictionary:
	return TOWER_STATS.get(tower_id, {}).duplicate(true)


## Get tower build cost
static func get_build_cost(tower_id: String) -> Dictionary:
	var stats: Dictionary = TOWER_STATS.get(tower_id, {})
	return stats.get("cost", {}).duplicate(true)


## Check if tower is legendary (placement limited)
static func is_legendary(tower_id: String) -> bool:
	return tower_id in CATEGORY_LEGENDARY


## Get placement limit for tower (0 = unlimited)
static func get_placement_limit(tower_id: String) -> int:
	var stats: Dictionary = TOWER_STATS.get(tower_id, {})
	return int(stats.get("placement_limit", 0))


## Get unlock requirement for tower category
static func get_unlock_level(tower_id: String) -> int:
	match get_category(tower_id):
		TowerCategory.BASIC:
			return 0
		TowerCategory.ADVANCED:
			return 10
		TowerCategory.SPECIALIST:
			return 18
		TowerCategory.LEGENDARY:
			return 30  # Plus quest/achievement
	return 0


## Convert damage type enum to string
static func damage_type_to_string(damage_type: DamageType) -> String:
	match damage_type:
		DamageType.PHYSICAL:
			return "physical"
		DamageType.MAGICAL:
			return "magical"
		DamageType.COLD:
			return "cold"
		DamageType.POISON:
			return "poison"
		DamageType.LIGHTNING:
			return "lightning"
		DamageType.HOLY:
			return "holy"
		DamageType.FIRE:
			return "fire"
		DamageType.PURE:
			return "pure"
	return "physical"


## Convert string to damage type enum
static func string_to_damage_type(s: String) -> DamageType:
	match s.to_lower():
		"physical":
			return DamageType.PHYSICAL
		"magical", "magic":
			return DamageType.MAGICAL
		"cold", "ice":
			return DamageType.COLD
		"poison":
			return DamageType.POISON
		"lightning", "electric":
			return DamageType.LIGHTNING
		"holy", "divine":
			return DamageType.HOLY
		"fire":
			return DamageType.FIRE
		"pure":
			return DamageType.PURE
	return DamageType.PHYSICAL


## Get all towers in a category
static func get_towers_in_category(category: TowerCategory) -> Array[String]:
	match category:
		TowerCategory.BASIC:
			return CATEGORY_BASIC.duplicate()
		TowerCategory.ADVANCED:
			return CATEGORY_ADVANCED.duplicate()
		TowerCategory.SPECIALIST:
			return CATEGORY_SPECIALIST.duplicate()
		TowerCategory.LEGENDARY:
			return CATEGORY_LEGENDARY.duplicate()
	return []


## Check if tower blocks movement
static func is_blocking(tower_id: String) -> bool:
	# All towers block movement except support towers
	return tower_id != TOWER_SUPPORT


## Get summon type data
static func get_summon_type(summon_id: String) -> Dictionary:
	return SUMMON_TYPES.get(summon_id, SUMMON_TYPES["word_warrior"]).duplicate(true)


## Get trap type data
static func get_trap_type(trap_id: String) -> Dictionary:
	return TRAP_TYPES.get(trap_id, TRAP_TYPES["explosive"]).duplicate(true)
