class_name SimWaveComposer
extends RefCounted
## Wave Composition System - Creates varied and themed enemy waves

const SimEnemyTypes = preload("res://sim/enemy_types.gd")
const SimBossEncounters = preload("res://sim/boss_encounters.gd")

# =============================================================================
# TIER-BASED SPAWN WEIGHTS
# =============================================================================

# Spawn weight multipliers by tier, scaled by day progression
# Format: {tier: {day_range_start: weight}}
const TIER_WEIGHTS_BY_DAY: Dictionary = {
	SimEnemyTypes.Tier.MINION: {1: 100, 3: 70, 7: 50, 15: 30},
	SimEnemyTypes.Tier.SOLDIER: {3: 30, 7: 50, 15: 40},
	SimEnemyTypes.Tier.ELITE: {7: 20, 15: 35},
	SimEnemyTypes.Tier.CHAMPION: {15: 15}
}

## Get spawn weight for a tier based on current day
static func get_tier_weight(tier: int, day: int) -> int:
	var tier_data: Dictionary = TIER_WEIGHTS_BY_DAY.get(tier, {})
	var weight: int = 0
	for day_threshold in tier_data.keys():
		if day >= int(day_threshold):
			weight = int(tier_data[day_threshold])
	return weight

# Wave themes define the flavor and enemy composition
const WAVE_THEMES: Dictionary = {
	"standard": {
		"name": "Standard Assault",
		"description": "Balanced mix of enemies",
		"enemy_weights": {"raider": 60, "scout": 25, "brute": 15},
		"modifiers": []
	},
	"swarm": {
		"name": "Swarming Tide",
		"description": "Many weak enemies",
		"enemy_weights": {"scout": 70, "raider": 25, "specter": 5},
		"modifiers": ["increased_count", "reduced_hp"],
		"count_mult": 1.5,
		"hp_mult": 0.6
	},
	"elite": {
		"name": "Elite Vanguard",
		"description": "Fewer but stronger enemies",
		"enemy_weights": {"brute": 40, "champion": 35, "warlord": 25},
		"modifiers": ["reduced_count", "increased_hp", "increased_gold"],
		"count_mult": 0.6,
		"hp_mult": 1.5,
		"gold_mult": 1.5
	},
	"speedy": {
		"name": "Swift Raiders",
		"description": "Fast-moving enemies",
		"enemy_weights": {"scout": 55, "specter": 30, "raider": 15},
		"modifiers": ["increased_speed"],
		"speed_mult": 1.4
	},
	"tanky": {
		"name": "Iron Wall",
		"description": "Slow but durable enemies",
		"enemy_weights": {"brute": 50, "titan": 30, "champion": 20},
		"modifiers": ["reduced_speed", "increased_hp"],
		"speed_mult": 0.7,
		"hp_mult": 1.8
	},
	"magic": {
		"name": "Arcane Invasion",
		"description": "Magical creatures",
		"enemy_weights": {"specter": 40, "elemental_fire": 30, "elemental_ice": 30},
		"modifiers": ["magic_damage"]
	},
	"undead": {
		"name": "Undead Uprising",
		"description": "Risen horrors",
		"enemy_weights": {"specter": 45, "wraith": 35, "champion": 20},
		"modifiers": ["reduced_gold"],
		"gold_mult": 0.7
	},
	"balanced": {
		"name": "Mixed Forces",
		"description": "Diverse enemy types",
		"enemy_weights": {"raider": 30, "scout": 25, "brute": 20, "specter": 15, "champion": 10},
		"modifiers": []
	},
	"boss_assault": {
		"name": "Champion's Challenge",
		"description": "Mini-bosses leading the charge",
		"enemy_weights": {"champion": 40, "warlord": 30, "brute": 30},
		"modifiers": ["reduced_count", "increased_hp"],
		"count_mult": 0.7,
		"hp_mult": 1.3
	},
	"burning": {
		"name": "Infernal Tide",
		"description": "Fire-aligned enemies",
		"enemy_weights": {"elemental_fire": 60, "raider": 25, "brute": 15},
		"modifiers": ["burn_damage"],
		"affix_chance": {"burning": 0.3}
	},
	"frozen": {
		"name": "Frozen Legion",
		"description": "Ice-aligned enemies",
		"enemy_weights": {"elemental_ice": 60, "scout": 25, "specter": 15},
		"modifiers": ["slow_player"],
		"affix_chance": {"frozen": 0.3}
	}
}

# Wave modifiers that can be applied
const WAVE_MODIFIERS: Dictionary = {
	"armored": {
		"name": "Armored Assault",
		"description": "Enemies have armor",
		"affix": "armored",
		"affix_chance": 0.4
	},
	"swift": {
		"name": "Swift Advance",
		"description": "Enemies move faster",
		"speed_mult": 1.3
	},
	"enraged": {
		"name": "Enraged Horde",
		"description": "Enemies deal more damage",
		"damage_mult": 1.5
	},
	"toxic": {
		"name": "Toxic Menace",
		"description": "Poison lingers",
		"affix": "toxic",
		"affix_chance": 0.25
	},
	"shielded": {
		"name": "Shield Wall",
		"description": "Some enemies are shielded",
		"affix": "shielded",
		"affix_chance": 0.2
	},
	"vampiric": {
		"name": "Blood Drinkers",
		"description": "Enemies heal on hit",
		"affix": "vampiric",
		"affix_chance": 0.15
	},
	"treasure": {
		"name": "Treasure Carriers",
		"description": "Enemies drop extra gold",
		"gold_mult": 2.0
	},
	"double_trouble": {
		"name": "Double Trouble",
		"description": "Twice as many enemies, half HP",
		"count_mult": 2.0,
		"hp_mult": 0.5
	}
}

# Special wave events (rare occurrences)
const SPECIAL_WAVES: Dictionary = {
	"ambush": {
		"name": "Ambush!",
		"description": "Enemies spawn from multiple directions",
		"multi_spawn": true
	},
	"boss_rush": {
		"name": "Boss Rush",
		"description": "Multiple mini-bosses attack",
		"force_bosses": 3
	},
	"countdown": {
		"name": "Countdown",
		"description": "Complete the wave in 60 seconds!",
		"time_limit": 60
	},
	"survival": {
		"name": "Survival Wave",
		"description": "Endless enemies until timer runs out",
		"endless": true,
		"duration": 45
	}
}


## Generate wave composition for a specific day and wave
static func compose_wave(day: int, wave_num: int, waves_per_day: int, rng_seed: int) -> Dictionary:
	var composition: Dictionary = {
		"theme": "",
		"theme_name": "",
		"description": "",
		"enemies": [],
		"enemy_count": 0,
		"modifiers": [],
		"modifier_names": [],
		"special": "",
		"hp_mult": 1.0,
		"speed_mult": 1.0,
		"damage_mult": 1.0,
		"gold_mult": 1.0,
		"affix_chances": {}
	}

	# Base enemy count scales with day and wave
	var base_count: int = 3 + wave_num + int(day * 0.5)
	composition["enemy_count"] = base_count

	# Select theme based on day/wave with some randomness
	var theme_id: String = _select_theme(day, wave_num, waves_per_day, rng_seed)
	var theme: Dictionary = WAVE_THEMES.get(theme_id, WAVE_THEMES["standard"])
	composition["theme"] = theme_id
	composition["theme_name"] = str(theme.get("name", "Standard"))
	composition["description"] = str(theme.get("description", ""))

	# Apply theme modifiers
	composition["hp_mult"] = float(theme.get("hp_mult", 1.0))
	composition["speed_mult"] = float(theme.get("speed_mult", 1.0))
	composition["gold_mult"] = float(theme.get("gold_mult", 1.0))
	composition["enemy_count"] = int(float(base_count) * float(theme.get("count_mult", 1.0)))

	# Apply affix chances from theme
	if theme.has("affix_chance"):
		for affix in theme["affix_chance"].keys():
			composition["affix_chances"][affix] = float(theme["affix_chance"][affix])

	# Generate enemy list from weights
	var enemy_weights: Dictionary = theme.get("enemy_weights", {"raider": 100})
	composition["enemies"] = _generate_enemy_list(enemy_weights, composition["enemy_count"], rng_seed + day * 100 + wave_num)

	# Maybe add a wave modifier (20% chance after day 3)
	if day >= 3:
		var mod_roll: float = _seeded_random(rng_seed + day * 50 + wave_num * 7)
		if mod_roll < 0.2:
			var modifier_id: String = _select_modifier(day, rng_seed + wave_num * 13)
			var modifier: Dictionary = WAVE_MODIFIERS.get(modifier_id, {})
			if not modifier.is_empty():
				composition["modifiers"].append(modifier_id)
				composition["modifier_names"].append(str(modifier.get("name", modifier_id)))

				# Apply modifier effects
				if modifier.has("hp_mult"):
					composition["hp_mult"] *= float(modifier["hp_mult"])
				if modifier.has("speed_mult"):
					composition["speed_mult"] *= float(modifier["speed_mult"])
				if modifier.has("damage_mult"):
					composition["damage_mult"] *= float(modifier["damage_mult"])
				if modifier.has("gold_mult"):
					composition["gold_mult"] *= float(modifier["gold_mult"])
				if modifier.has("count_mult"):
					composition["enemy_count"] = int(float(composition["enemy_count"]) * float(modifier["count_mult"]))
					# Regenerate enemy list with new count
					composition["enemies"] = _generate_enemy_list(enemy_weights, composition["enemy_count"], rng_seed + day * 100 + wave_num + 1)
				if modifier.has("affix") and modifier.has("affix_chance"):
					composition["affix_chances"][str(modifier["affix"])] = float(modifier["affix_chance"])

	# Check for special wave (rare, 5% chance after day 5)
	if day >= 5:
		var special_roll: float = _seeded_random(rng_seed + day * 77 + wave_num * 11)
		if special_roll < 0.05 and wave_num == waves_per_day:  # Only on final wave
			var special_ids: Array = SPECIAL_WAVES.keys()
			var special_index: int = int(_seeded_random(rng_seed + day * 99) * special_ids.size()) % special_ids.size()
			composition["special"] = special_ids[special_index]

	return composition


## Select a wave theme based on progression
static func _select_theme(day: int, wave_num: int, waves_per_day: int, rng_seed: int) -> String:
	# Available themes unlock based on day progression
	var available: Array[String] = ["standard"]

	if day >= 2:
		available.append("swarm")
		available.append("balanced")
	if day >= 3:
		available.append("speedy")
		available.append("tanky")
	if day >= 5:
		available.append("elite")
		available.append("magic")
	if day >= 7:
		available.append("undead")
		available.append("burning")
	if day >= 10:
		available.append("frozen")
		available.append("boss_assault")

	# Final wave of the day has higher chance of elite/boss themes
	if wave_num == waves_per_day and day >= 5:
		var final_roll: float = _seeded_random(rng_seed + day * 33)
		if final_roll < 0.4 and "elite" in available:
			return "elite"
		elif final_roll < 0.6 and "boss_assault" in available:
			return "boss_assault"

	# Random selection from available themes
	var roll: float = _seeded_random(rng_seed + day * 17 + wave_num * 3)
	var index: int = int(roll * float(available.size())) % available.size()
	return available[index]


## Select a random modifier
static func _select_modifier(day: int, rng_seed: int) -> String:
	var available: Array[String] = ["swift", "treasure"]

	if day >= 4:
		available.append("armored")
		available.append("enraged")
	if day >= 6:
		available.append("toxic")
		available.append("double_trouble")
	if day >= 8:
		available.append("shielded")
	if day >= 10:
		available.append("vampiric")

	var roll: float = _seeded_random(rng_seed)
	var index: int = int(roll * float(available.size())) % available.size()
	return available[index]


## Generate list of enemy types based on weights
static func _generate_enemy_list(weights: Dictionary, count: int, rng_seed: int) -> Array[String]:
	var enemies: Array[String] = []
	var total_weight: float = 0.0

	for weight in weights.values():
		total_weight += float(weight)

	for i in range(count):
		var roll: float = _seeded_random(rng_seed + i * 7) * total_weight
		var cumulative: float = 0.0

		for enemy_type in weights.keys():
			cumulative += float(weights[enemy_type])
			if roll <= cumulative:
				enemies.append(enemy_type)
				break

	return enemies


## Deterministic random number generator
static func _seeded_random(seed_val: int) -> float:
	# LCG parameters
	var a: int = 1103515245
	var c: int = 12345
	var m: int = 2147483648

	var value: int = (a * abs(seed_val) + c) % m
	return float(value) / float(m)


## Get theme display name
static func get_theme_name(theme_id: String) -> String:
	return str(WAVE_THEMES.get(theme_id, {}).get("name", theme_id))


## Get theme description
static func get_theme_description(theme_id: String) -> String:
	return str(WAVE_THEMES.get(theme_id, {}).get("description", ""))


## Get modifier display name
static func get_modifier_name(modifier_id: String) -> String:
	return str(WAVE_MODIFIERS.get(modifier_id, {}).get("name", modifier_id))


## Get all available themes
static func get_all_themes() -> Array[String]:
	var themes: Array[String] = []
	for id in WAVE_THEMES.keys():
		themes.append(id)
	return themes


## Get all available modifiers
static func get_all_modifiers() -> Array[String]:
	var modifiers: Array[String] = []
	for id in WAVE_MODIFIERS.keys():
		modifiers.append(id)
	return modifiers


## Format wave composition for display
static func format_composition(composition: Dictionary) -> String:
	var lines: Array[String] = []

	lines.append("[color=yellow]%s[/color]" % str(composition.get("theme_name", "Wave")))
	lines.append(str(composition.get("description", "")))
	lines.append("Enemies: %d" % int(composition.get("enemy_count", 0)))

	if not composition.get("modifiers", []).is_empty():
		lines.append("[color=orange]Modifier: %s[/color]" % ", ".join(composition.get("modifier_names", [])))

	if not str(composition.get("special", "")).is_empty():
		var special: Dictionary = SPECIAL_WAVES.get(str(composition.get("special", "")), {})
		lines.append("[color=red]SPECIAL: %s[/color]" % str(special.get("name", "Special")))

	# Show stat modifiers if not default
	var stats: Array[String] = []
	if float(composition.get("hp_mult", 1.0)) != 1.0:
		stats.append("HP x%.1f" % float(composition.get("hp_mult", 1.0)))
	if float(composition.get("speed_mult", 1.0)) != 1.0:
		stats.append("Speed x%.1f" % float(composition.get("speed_mult", 1.0)))
	if float(composition.get("gold_mult", 1.0)) != 1.0:
		stats.append("Gold x%.1f" % float(composition.get("gold_mult", 1.0)))

	if not stats.is_empty():
		lines.append("[color=gray]%s[/color]" % ", ".join(stats))

	return "\n".join(lines)


# =============================================================================
# TIER-BASED WAVE COMPOSITION (NEW ENEMY SYSTEM)
# =============================================================================

## Compose a wave using the new tier-based enemy type system
static func compose_tiered_wave(day: int, wave_num: int, waves_per_day: int, rng_seed: int, region: int = SimEnemyTypes.Region.ALL) -> Dictionary:
	var composition: Dictionary = {
		"theme": "tiered",
		"theme_name": "",
		"description": "",
		"enemies": [],
		"enemy_count": 0,
		"modifiers": [],
		"modifier_names": [],
		"special": "",
		"hp_mult": 1.0,
		"speed_mult": 1.0,
		"damage_mult": 1.0,
		"gold_mult": 1.0,
		"affix_chances": {},
		"region": region,
		"boss": ""
	}

	# Base enemy count scales with day and wave
	var base_count: int = 3 + wave_num + int(day * 0.5)
	composition["enemy_count"] = base_count

	# Set theme name based on wave position
	if wave_num == waves_per_day:
		composition["theme_name"] = "Final Wave"
		composition["description"] = "The strongest enemies attack!"
	elif wave_num == 1:
		composition["theme_name"] = "Opening Assault"
		composition["description"] = "The enemy begins their attack."
	else:
		composition["theme_name"] = "Wave %d" % wave_num
		composition["description"] = "The onslaught continues."

	# Check for boss wave (every 7 days, final wave only)
	if day % 7 == 0 and wave_num == waves_per_day and day >= 7:
		var boss_id: String = _select_boss_for_day(day, region, rng_seed)
		if not boss_id.is_empty():
			composition["boss"] = boss_id
			composition["theme_name"] = "Boss Battle"
			composition["description"] = SimBossEncounters.get_boss_title(boss_id)
			# Reduce regular enemies for boss wave
			composition["enemy_count"] = maxi(3, base_count / 2)

	# Generate enemy list using tier weights
	composition["enemies"] = _generate_tiered_enemy_list(
		day, composition["enemy_count"], region, rng_seed + day * 100 + wave_num
	)

	# Maybe add a wave modifier (20% chance after day 3)
	if day >= 3 and composition["boss"].is_empty():
		var mod_roll: float = _seeded_random(rng_seed + day * 50 + wave_num * 7)
		if mod_roll < 0.2:
			var modifier_id: String = _select_modifier(day, rng_seed + wave_num * 13)
			var modifier: Dictionary = WAVE_MODIFIERS.get(modifier_id, {})
			if not modifier.is_empty():
				composition["modifiers"].append(modifier_id)
				composition["modifier_names"].append(str(modifier.get("name", modifier_id)))
				_apply_modifier_effects(composition, modifier, rng_seed)

	# Final wave scaling
	if wave_num == waves_per_day:
		composition["hp_mult"] *= 1.2
		composition["gold_mult"] *= 1.3

	return composition


## Generate enemy list using tier-based weights
static func _generate_tiered_enemy_list(day: int, count: int, region: int, rng_seed: int) -> Array[String]:
	var enemies: Array[String] = []

	# Calculate tier weights for this day
	var tier_weights: Dictionary = {}
	var total_weight: int = 0
	for tier in [SimEnemyTypes.Tier.MINION, SimEnemyTypes.Tier.SOLDIER, SimEnemyTypes.Tier.ELITE, SimEnemyTypes.Tier.CHAMPION]:
		var weight: int = get_tier_weight(tier, day)
		if weight > 0:
			tier_weights[tier] = weight
			total_weight += weight

	if total_weight == 0:
		tier_weights[SimEnemyTypes.Tier.MINION] = 100
		total_weight = 100

	# Generate each enemy
	for i in range(count):
		# Roll for tier
		var roll: float = _seeded_random(rng_seed + i * 7) * float(total_weight)
		var cumulative: float = 0.0
		var selected_tier: int = SimEnemyTypes.Tier.MINION

		for tier in tier_weights.keys():
			cumulative += float(tier_weights[tier])
			if roll <= cumulative:
				selected_tier = int(tier)
				break

		# Get enemies of this tier
		var tier_enemies: Array[String] = SimEnemyTypes.get_enemies_by_tier(selected_tier)

		# Add regional variants if in a specific region
		if region != SimEnemyTypes.Region.ALL:
			var regional: Array[String] = []
			for enemy_id in SimEnemyTypes.get_regional_enemies_by_region(region):
				var enemy_data: Dictionary = SimEnemyTypes.get_regional_enemy(enemy_id)
				if int(enemy_data.get("tier", 0)) == selected_tier:
					regional.append(enemy_id)
			# 40% chance to use regional variant if available
			if not regional.is_empty() and _seeded_random(rng_seed + i * 11) < 0.4:
				tier_enemies = regional

		# Select random enemy from tier
		if not tier_enemies.is_empty():
			var enemy_roll: float = _seeded_random(rng_seed + i * 13)
			var enemy_index: int = int(enemy_roll * float(tier_enemies.size())) % tier_enemies.size()
			enemies.append(tier_enemies[enemy_index])
		else:
			enemies.append(SimEnemyTypes.TYPHOS_SPAWN)  # Fallback

	return enemies


## Select boss for a given day based on region and progression
static func _select_boss_for_day(day: int, region: int, rng_seed: int) -> String:
	var available: Array[String] = SimBossEncounters.get_available_bosses_for_day(day)

	if available.is_empty():
		return ""

	# Prefer region-specific boss if in a region
	if region != SimEnemyTypes.Region.ALL:
		var regional_boss: String = SimBossEncounters.get_boss_for_region(region)
		if not regional_boss.is_empty() and regional_boss in available:
			return regional_boss

	# Otherwise random from available
	var roll: float = _seeded_random(rng_seed + day * 77)
	var index: int = int(roll * float(available.size())) % available.size()
	return available[index]


## Apply modifier effects to composition
static func _apply_modifier_effects(composition: Dictionary, modifier: Dictionary, rng_seed: int) -> void:
	if modifier.has("hp_mult"):
		composition["hp_mult"] *= float(modifier["hp_mult"])
	if modifier.has("speed_mult"):
		composition["speed_mult"] *= float(modifier["speed_mult"])
	if modifier.has("damage_mult"):
		composition["damage_mult"] *= float(modifier["damage_mult"])
	if modifier.has("gold_mult"):
		composition["gold_mult"] *= float(modifier["gold_mult"])
	if modifier.has("count_mult"):
		var old_count: int = int(composition["enemy_count"])
		composition["enemy_count"] = int(float(old_count) * float(modifier["count_mult"]))
		# Regenerate enemy list with new count
		var day: int = 1  # Will be passed in properly when called
		var region: int = int(composition.get("region", 0))
		composition["enemies"] = _generate_tiered_enemy_list(
			day, composition["enemy_count"], region, rng_seed + 1
		)
	if modifier.has("affix") and modifier.has("affix_chance"):
		composition["affix_chances"][str(modifier["affix"])] = float(modifier["affix_chance"])


# =============================================================================
# REGIONAL WAVE THEMES
# =============================================================================

const REGIONAL_THEMES: Dictionary = {
	SimEnemyTypes.Region.EVERGROVE: {
		"name": "Forest Assault",
		"description": "Creatures of the corrupted woods attack!",
		"tier_bonus": {SimEnemyTypes.Tier.SOLDIER: 10},  # More soldiers
		"preferred_categories": [SimEnemyTypes.Category.BASIC, SimEnemyTypes.Category.TANK]
	},
	SimEnemyTypes.Region.STONEPASS: {
		"name": "Mountain Siege",
		"description": "Stone-hard enemies descend from the peaks!",
		"tier_bonus": {SimEnemyTypes.Tier.ELITE: 10},  # More elites
		"preferred_categories": [SimEnemyTypes.Category.TANK, SimEnemyTypes.Category.SIEGE]
	},
	SimEnemyTypes.Region.MISTFEN: {
		"name": "Marsh Horror",
		"description": "Poisonous swamp creatures emerge!",
		"tier_bonus": {SimEnemyTypes.Tier.MINION: 20},  # More swarm
		"preferred_categories": [SimEnemyTypes.Category.CASTER, SimEnemyTypes.Category.STEALTH]
	},
	SimEnemyTypes.Region.SUNFIELDS: {
		"name": "Plains Raiders",
		"description": "Swift warriors charge across the plains!",
		"tier_bonus": {SimEnemyTypes.Tier.SOLDIER: 15},
		"preferred_categories": [SimEnemyTypes.Category.BERSERKER, SimEnemyTypes.Category.RANGED]
	}
}


## Get regional theme data
static func get_regional_theme(region: int) -> Dictionary:
	return REGIONAL_THEMES.get(region, {})


## Get wave summary for display
static func get_wave_summary(composition: Dictionary) -> String:
	var lines: Array[String] = []

	# Theme name
	lines.append(str(composition.get("theme_name", "Wave")))

	# Boss indicator
	var boss: String = str(composition.get("boss", ""))
	if not boss.is_empty():
		lines.append("[Boss: %s]" % SimBossEncounters.get_boss_name(boss))

	# Enemy breakdown by tier
	var tier_counts: Dictionary = {}
	for enemy_id in composition.get("enemies", []):
		var tier: int = SimEnemyTypes.get_tier(enemy_id)
		tier_counts[tier] = tier_counts.get(tier, 0) + 1

	var tier_parts: Array[String] = []
	for tier in tier_counts.keys():
		var tier_name: String = ""
		match tier:
			SimEnemyTypes.Tier.MINION:
				tier_name = "Minions"
			SimEnemyTypes.Tier.SOLDIER:
				tier_name = "Soldiers"
			SimEnemyTypes.Tier.ELITE:
				tier_name = "Elites"
			SimEnemyTypes.Tier.CHAMPION:
				tier_name = "Champions"
		tier_parts.append("%d %s" % [tier_counts[tier], tier_name])

	if not tier_parts.is_empty():
		lines.append(", ".join(tier_parts))

	return "\n".join(lines)
