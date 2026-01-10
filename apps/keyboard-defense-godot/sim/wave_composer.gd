class_name SimWaveComposer
extends RefCounted
## Wave Composition System - Creates varied and themed enemy waves

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
