class_name SimAutoTowerTypes
extends RefCounted
## Auto-Defense Tower Types - Definitions, stats, and upgrade paths for all auto-towers

# =============================================================================
# ENUMS
# =============================================================================

enum Tier { TIER_1 = 1, TIER_2 = 2, TIER_3 = 3, TIER_4 = 4 }

enum TargetMode {
	NEAREST,       # Attack closest enemy
	HIGHEST_HP,    # Attack enemy with most HP
	LOWEST_HP,     # Attack enemy with least HP (finish off)
	FASTEST,       # Attack fastest moving enemy
	CLUSTER,       # Attack center of largest enemy group
	CHAIN,         # Attack primary, chain to nearby enemies
	ZONE,          # Damage all enemies in range
	CONTACT,       # Damage enemies that touch the tower
	SMART          # AI-driven optimal selection (legendary only)
}

enum DamageType {
	PHYSICAL,      # Standard damage, affected by armor
	LIGHTNING,     # Chain damage, stun chance
	FIRE,          # Burn DoT
	NATURE,        # Slow, root effects
	SIEGE          # High damage, armor piercing
}

# =============================================================================
# TOWER TYPE IDS
# =============================================================================

const AUTO_SENTRY := "auto_sentry"
const AUTO_SPARK := "auto_spark"
const AUTO_THORNS := "auto_thorns"
const AUTO_BALLISTA := "auto_ballista"
const AUTO_TESLA := "auto_tesla"
const AUTO_BRAMBLE := "auto_bramble"
const AUTO_FLAME := "auto_flame"
const AUTO_CANNON := "auto_cannon"
const AUTO_STORM := "auto_storm"
const AUTO_FORTRESS := "auto_fortress"
const AUTO_INFERNO := "auto_inferno"
const AUTO_ARCANE := "auto_arcane"
const AUTO_DOOM := "auto_doom"

# =============================================================================
# TOWER DEFINITIONS
# =============================================================================

const TOWERS: Dictionary = {
	# =========================================================================
	# TIER 1 - Basic Auto-Towers
	# =========================================================================
	AUTO_SENTRY: {
		"name": "Sentry Turret",
		"description": "Clockwork turret that fires at nearby enemies.",
		"tier": Tier.TIER_1,
		"damage": 5,
		"attack_speed": 0.8,  # attacks per second
		"range": 3,
		"targeting": TargetMode.NEAREST,
		"damage_type": DamageType.PHYSICAL,
		"cost": {"gold": 80, "wood": 6, "stone": 10},
		"special": {},
		"flavor": "Wind it up and watch it work."
	},
	AUTO_SPARK: {
		"name": "Spark Coil",
		"description": "Releases electrical pulses damaging all enemies in range.",
		"tier": Tier.TIER_1,
		"damage": 3,
		"attack_speed": 0.67,  # ~1.5s cooldown
		"range": 2,
		"targeting": TargetMode.ZONE,
		"damage_type": DamageType.LIGHTNING,
		"cost": {"gold": 100, "wood": 4, "stone": 8},
		"special": {"aoe_radius": 2},
		"flavor": "The air crackles with anticipation."
	},
	AUTO_THORNS: {
		"name": "Thorn Barrier",
		"description": "Living barrier that damages enemies passing through.",
		"tier": Tier.TIER_1,
		"damage": 8,
		"attack_speed": 0.0,  # Passive/contact damage
		"range": 1,
		"targeting": TargetMode.CONTACT,
		"damage_type": DamageType.NATURE,
		"cost": {"gold": 60, "wood": 8},
		"special": {"slow_percent": 15, "contact_damage": true},
		"flavor": "Nature's first line of defense."
	},

	# =========================================================================
	# TIER 2 - Advanced Auto-Towers
	# =========================================================================
	AUTO_BALLISTA: {
		"name": "Ballista Emplacement",
		"description": "Heavy siege weapon dealing massive single-target damage.",
		"tier": Tier.TIER_2,
		"damage": 25,
		"attack_speed": 0.3,  # ~3.3s cooldown
		"range": 6,
		"targeting": TargetMode.HIGHEST_HP,
		"damage_type": DamageType.SIEGE,
		"cost": {"gold": 230, "wood": 10, "stone": 15},
		"special": {"armor_pierce": 50},
		"upgrade_from": AUTO_SENTRY,
		"flavor": "One shot, one problem solved."
	},
	AUTO_TESLA: {
		"name": "Tesla Array",
		"description": "Chain lightning bounces between multiple enemies.",
		"tier": Tier.TIER_2,
		"damage": 8,
		"attack_speed": 1.0,
		"range": 4,
		"targeting": TargetMode.CHAIN,
		"damage_type": DamageType.LIGHTNING,
		"cost": {"gold": 280, "wood": 6, "stone": 12},
		"special": {"chain_count": 4, "chain_falloff": 0.8},
		"upgrade_from": AUTO_SPARK,
		"flavor": "Lightning never strikes twice? Think again."
	},
	AUTO_BRAMBLE: {
		"name": "Bramble Maze",
		"description": "Expanding thorns create a damage zone.",
		"tier": Tier.TIER_2,
		"damage": 4,
		"attack_speed": 2.0,  # Ticks per second
		"range": 3,
		"targeting": TargetMode.ZONE,
		"damage_type": DamageType.NATURE,
		"cost": {"gold": 180, "wood": 15, "stone": 5},
		"special": {"slow_percent": 30, "root_chance": 10},
		"upgrade_from": AUTO_THORNS,
		"flavor": "The forest remembers all who trespass."
	},
	AUTO_FLAME: {
		"name": "Flame Jet",
		"description": "Sprays fire in a cone, burning all enemies.",
		"tier": Tier.TIER_2,
		"damage": 6,
		"attack_speed": 2.0,
		"range": 3,
		"targeting": TargetMode.NEAREST,
		"damage_type": DamageType.FIRE,
		"cost": {"gold": 250, "wood": 8, "stone": 10},
		"special": {"burn_damage": 3, "burn_duration": 3.0, "cone_angle": 60},
		"flavor": "Everything burns eventually."
	},

	# =========================================================================
	# TIER 3 - Elite Auto-Towers
	# =========================================================================
	AUTO_CANNON: {
		"name": "Siege Cannon",
		"description": "Devastating artillery firing explosive shells.",
		"tier": Tier.TIER_3,
		"damage": 50,
		"attack_speed": 0.2,  # 5s cooldown
		"range": 8,
		"targeting": TargetMode.CLUSTER,
		"damage_type": DamageType.SIEGE,
		"cost": {"gold": 530, "wood": 15, "stone": 30},
		"special": {"splash_radius": 2, "splash_damage_percent": 60},
		"upgrade_from": AUTO_BALLISTA,
		"flavor": "When subtlety fails, bring bigger guns."
	},
	AUTO_STORM: {
		"name": "Storm Spire",
		"description": "Calls lightning storms on enemy clusters.",
		"tier": Tier.TIER_3,
		"damage": 15,
		"attack_speed": 0.5,  # 2s cooldown
		"range": 6,
		"targeting": TargetMode.CLUSTER,
		"damage_type": DamageType.LIGHTNING,
		"cost": {"gold": 630, "wood": 8, "stone": 20},
		"special": {"strikes_per_storm": 5, "stun_chance": 20, "stun_duration": 1.0},
		"upgrade_from": AUTO_TESLA,
		"flavor": "The sky itself bends to your will."
	},
	AUTO_FORTRESS: {
		"name": "Living Fortress",
		"description": "Massive treant that blocks paths and strikes nearby foes.",
		"tier": Tier.TIER_3,
		"damage": 20,
		"attack_speed": 0.8,
		"range": 2,
		"targeting": TargetMode.ZONE,
		"damage_type": DamageType.NATURE,
		"cost": {"gold": 520, "wood": 30, "stone": 10},
		"special": {"hp": 500, "armor": 30, "regen": 5, "blocks_path": true},
		"upgrade_from": AUTO_BRAMBLE,
		"flavor": "Ancient protector of the realm."
	},
	AUTO_INFERNO: {
		"name": "Inferno Engine",
		"description": "Industrial flamethrower with ramping damage.",
		"tier": Tier.TIER_3,
		"damage": 10,
		"attack_speed": 3.0,
		"range": 4,
		"targeting": TargetMode.NEAREST,
		"damage_type": DamageType.FIRE,
		"cost": {"gold": 580, "wood": 12, "stone": 15},
		"special": {
			"ramp_max_multiplier": 3.0,
			"ramp_time": 5.0,
			"uses_fuel": true,
			"max_fuel": 100,
			"fuel_per_second": 5,
			"refuel_rate": 2
		},
		"upgrade_from": AUTO_FLAME,
		"flavor": "Feed the flames, reap the ashes."
	},

	# =========================================================================
	# TIER 4 - Legendary Auto-Towers
	# =========================================================================
	AUTO_ARCANE: {
		"name": "Arcane Sentinel",
		"description": "Ancient construct infused with letter magic. Adapts to weaknesses.",
		"tier": Tier.TIER_4,
		"damage": 35,
		"attack_speed": 1.2,
		"range": 5,
		"targeting": TargetMode.SMART,
		"damage_type": DamageType.PHYSICAL,  # Adaptive
		"cost": {"gold": 1200, "wood": 20, "stone": 30},
		"special": {
			"adaptive_damage": true,
			"weakness_bonus": 75,
			"typing_synergy": true,
			"crit_on_word_complete": true
		},
		"legendary": true,
		"limit_per_map": 1,
		"flavor": "The letters themselves serve as its ammunition."
	},
	AUTO_DOOM: {
		"name": "Doom Fortress",
		"description": "Massive defense platform with multiple weapon systems.",
		"tier": Tier.TIER_4,
		"damage": 80,  # Main cannon
		"attack_speed": 0.15,
		"range": 7,
		"targeting": TargetMode.CLUSTER,
		"damage_type": DamageType.SIEGE,
		"cost": {"gold": 2000, "wood": 50, "stone": 80},
		"special": {
			"multi_system": true,
			"main_cannon": {"damage": 80, "cooldown": 6.67, "targeting": "highest_hp"},
			"turrets": {"count": 4, "damage": 12, "cooldown": 0.5},
			"flame_moat": {"damage": 5, "tick_rate": 0.5},
			"shield": {"hp": 200, "recharge_rate": 10},
			"size": "3x3"
		},
		"legendary": true,
		"limit_per_map": 1,
		"flavor": "An army unto itself."
	}
}

# =============================================================================
# UPGRADE PATHS
# =============================================================================

const UPGRADE_PATHS: Dictionary = {
	AUTO_SENTRY: [AUTO_BALLISTA],
	AUTO_SPARK: [AUTO_TESLA],
	AUTO_THORNS: [AUTO_BRAMBLE],
	AUTO_FLAME: [AUTO_INFERNO],
	AUTO_BALLISTA: [AUTO_CANNON],
	AUTO_TESLA: [AUTO_STORM],
	AUTO_BRAMBLE: [AUTO_FORTRESS],
	# Tier 4 towers require special unlock conditions (quests, achievements)
}

const UPGRADE_COSTS: Dictionary = {
	AUTO_BALLISTA: {"gold": 150, "stone": 15},
	AUTO_TESLA: {"gold": 180, "stone": 12},
	AUTO_BRAMBLE: {"gold": 120, "wood": 10},
	AUTO_FLAME: {"gold": 140, "wood": 8, "stone": 6},
	AUTO_CANNON: {"gold": 300, "stone": 25},
	AUTO_STORM: {"gold": 350, "stone": 20},
	AUTO_FORTRESS: {"gold": 340, "wood": 25},
	AUTO_INFERNO: {"gold": 330, "wood": 10, "stone": 12},
	AUTO_ARCANE: {"gold": 800, "stone": 30},
	AUTO_DOOM: {"gold": 1500, "wood": 50, "stone": 80}
}

# =============================================================================
# OVERHEAT CONFIG (mechanical towers)
# =============================================================================

const OVERHEAT_CONFIG: Dictionary = {
	AUTO_SENTRY: {"heat_per_shot": 5, "max_heat": 100, "cooldown_rate": 20},
	AUTO_BALLISTA: {"heat_per_shot": 15, "max_heat": 100, "cooldown_rate": 15},
	AUTO_CANNON: {"heat_per_shot": 25, "max_heat": 100, "cooldown_rate": 10}
}

# =============================================================================
# TIER COLORS (for UI)
# =============================================================================

const TIER_COLORS: Dictionary = {
	Tier.TIER_1: Color(0.6, 0.6, 0.6),      # Gray
	Tier.TIER_2: Color(0.3, 0.7, 0.3),      # Green
	Tier.TIER_3: Color(0.3, 0.5, 0.9),      # Blue
	Tier.TIER_4: Color(0.8, 0.5, 0.9)       # Purple (legendary)
}

const DAMAGE_TYPE_COLORS: Dictionary = {
	DamageType.PHYSICAL: Color(0.8, 0.8, 0.8),    # Silver
	DamageType.LIGHTNING: Color(0.5, 0.7, 1.0),   # Electric blue
	DamageType.FIRE: Color(1.0, 0.5, 0.2),        # Orange
	DamageType.NATURE: Color(0.3, 0.8, 0.3),      # Green
	DamageType.SIEGE: Color(0.6, 0.4, 0.2)        # Brown
}

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

static func get_tower(tower_id: String) -> Dictionary:
	return TOWERS.get(tower_id, {})


static func get_name(tower_id: String) -> String:
	return str(TOWERS.get(tower_id, {}).get("name", tower_id))


static func get_tier(tower_id: String) -> int:
	return int(TOWERS.get(tower_id, {}).get("tier", 1))


static func get_cost(tower_id: String) -> Dictionary:
	return TOWERS.get(tower_id, {}).get("cost", {}).duplicate()


static func get_upgrade_cost(tower_id: String) -> Dictionary:
	return UPGRADE_COSTS.get(tower_id, {}).duplicate()


static func get_upgrade_options(tower_id: String) -> Array[String]:
	var options: Array[String] = []
	var paths: Array = UPGRADE_PATHS.get(tower_id, [])
	for path in paths:
		options.append(str(path))
	return options


static func can_upgrade_to(from_id: String, to_id: String) -> bool:
	var options: Array = UPGRADE_PATHS.get(from_id, [])
	return to_id in options


static func get_targeting_mode(tower_id: String) -> int:
	return int(TOWERS.get(tower_id, {}).get("targeting", TargetMode.NEAREST))


static func get_damage_type(tower_id: String) -> int:
	return int(TOWERS.get(tower_id, {}).get("damage_type", DamageType.PHYSICAL))


static func get_special(tower_id: String) -> Dictionary:
	return TOWERS.get(tower_id, {}).get("special", {}).duplicate()


static func is_legendary(tower_id: String) -> bool:
	return bool(TOWERS.get(tower_id, {}).get("legendary", false))


static func has_overheat(tower_id: String) -> bool:
	return OVERHEAT_CONFIG.has(tower_id)


static func get_overheat_config(tower_id: String) -> Dictionary:
	return OVERHEAT_CONFIG.get(tower_id, {}).duplicate()


static func uses_fuel(tower_id: String) -> bool:
	return bool(TOWERS.get(tower_id, {}).get("special", {}).get("uses_fuel", false))


static func get_all_tower_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in TOWERS.keys():
		ids.append(str(key))
	return ids


static func get_towers_by_tier(tier: int) -> Array[String]:
	var result: Array[String] = []
	for key in TOWERS.keys():
		if int(TOWERS[key].get("tier", 0)) == tier:
			result.append(str(key))
	return result


static func get_dps(tower_id: String) -> float:
	var tower: Dictionary = TOWERS.get(tower_id, {})
	var damage: float = float(tower.get("damage", 0))
	var attack_speed: float = float(tower.get("attack_speed", 1))
	if attack_speed <= 0:
		return 0.0
	return damage * attack_speed


static func get_cooldown(tower_id: String) -> float:
	var tower: Dictionary = TOWERS.get(tower_id, {})
	var attack_speed: float = float(tower.get("attack_speed", 1))
	if attack_speed <= 0:
		return 0.0
	return 1.0 / attack_speed
