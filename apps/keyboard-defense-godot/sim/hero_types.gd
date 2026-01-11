class_name SimHeroTypes
extends RefCounted

# =============================================================================
# HERO IDs
# =============================================================================

const HERO_NONE := ""
const HERO_SCRIBE := "scribe"
const HERO_WARDEN := "warden"
const HERO_TEMPEST := "tempest"
const HERO_SAGE := "sage"
const HERO_FORGEMASTER := "forgemaster"

# =============================================================================
# HERO DEFINITIONS
# =============================================================================

const HEROES: Dictionary = {
	HERO_SCRIBE: {
		"name": "Aldric the Scribe",
		"class": "Support",
		"description": "Master of precise lettering. Rewards accuracy with gold and critical strikes.",
		"color": Color(0.9, 0.8, 0.3),
		"passive": {
			"name": "Precision Ink",
			"description": "+5% crit chance, +5% gold for perfect words",
			"effects": {
				"critical_chance": 0.05,
				"perfect_word_gold_bonus": 0.05
			}
		},
		"ability": {
			"id": "inscribe",
			"name": "Inscribe",
			"word": "INSCRIBE",
			"description": "Next 3 words deal +50% damage if typed perfectly",
			"cooldown": 45.0,
			"duration": 10.0,
			"effect_type": "perfect_damage_charges",
			"effect_value": 0.5,
			"effect_charges": 3
		},
		"flavor": "His quill writes the fate of kingdoms."
	},
	HERO_WARDEN: {
		"name": "Sera the Warden",
		"class": "Tank",
		"description": "Stalwart defender of the realm. Reduces damage and blocks attacks.",
		"color": Color(0.4, 0.7, 0.4),
		"passive": {
			"name": "Guardian Presence",
			"description": "Castle takes 10% less damage, +1 max HP",
			"effects": {
				"damage_reduction": 0.10,
				"castle_health_bonus": 1
			}
		},
		"ability": {
			"id": "shield",
			"name": "Shield Wall",
			"word": "SHIELD",
			"description": "Block all castle damage for 4 seconds",
			"cooldown": 90.0,
			"duration": 4.0,
			"effect_type": "invulnerability",
			"effect_value": 1.0,
			"effect_charges": 0
		},
		"flavor": "She stands where others would flee."
	},
	HERO_TEMPEST: {
		"name": "Kaelen the Tempest",
		"class": "Assault",
		"description": "Lightning-fast warrior. Speed is his greatest weapon.",
		"color": Color(0.3, 0.6, 0.9),
		"passive": {
			"name": "Swift Strikes",
			"description": "+10% damage for words typed under 2 seconds",
			"effects": {
				"fast_typing_bonus": 0.10,
				"fast_typing_threshold": 2.0
			}
		},
		"ability": {
			"id": "surge",
			"name": "Surge",
			"word": "SURGE",
			"description": "+30% damage for 8s, one mistake forgiveness",
			"cooldown": 60.0,
			"duration": 8.0,
			"effect_type": "damage_boost",
			"effect_value": 0.30,
			"effect_charges": 1
		},
		"flavor": "The storm arrives before the thunder."
	},
	HERO_SAGE: {
		"name": "Mira the Sage",
		"class": "Control",
		"description": "Wise manipulator of time. Slows enemies and extends power.",
		"color": Color(0.7, 0.4, 0.8),
		"passive": {
			"name": "Temporal Ward",
			"description": "All buff durations extended by 20%",
			"effects": {
				"buff_duration_multiplier": 0.20
			}
		},
		"ability": {
			"id": "slow",
			"name": "Time Warp",
			"word": "SLOW",
			"description": "All enemies move at 50% speed for 6 seconds",
			"cooldown": 75.0,
			"duration": 6.0,
			"effect_type": "enemy_slow",
			"effect_value": 0.50,
			"effect_charges": 0
		},
		"flavor": "Time bends to her whispered commands."
	},
	HERO_FORGEMASTER: {
		"name": "Thorne the Forgemaster",
		"class": "Builder",
		"description": "Master craftsman. Towers and gold flow freely in his presence.",
		"color": Color(0.8, 0.5, 0.3),
		"passive": {
			"name": "Master Craftsman",
			"description": "+15% gold from kills, towers cost 10% less",
			"effects": {
				"gold_multiplier": 0.15,
				"tower_cost_reduction": 0.10
			}
		},
		"ability": {
			"id": "reinforce",
			"name": "Reinforce",
			"word": "REINFORCE",
			"description": "All auto-towers fire at 150% speed for 8 seconds",
			"cooldown": 60.0,
			"duration": 8.0,
			"effect_type": "tower_speed_boost",
			"effect_value": 0.50,
			"effect_charges": 0
		},
		"flavor": "Every hammer strike echoes with purpose."
	}
}

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

static func get_hero(hero_id: String) -> Dictionary:
	return HEROES.get(hero_id, {})


static func get_hero_name(hero_id: String) -> String:
	var hero: Dictionary = HEROES.get(hero_id, {})
	return str(hero.get("name", "Unknown Hero"))


static func get_hero_class(hero_id: String) -> String:
	var hero: Dictionary = HEROES.get(hero_id, {})
	return str(hero.get("class", ""))


static func get_hero_description(hero_id: String) -> String:
	var hero: Dictionary = HEROES.get(hero_id, {})
	return str(hero.get("description", ""))


static func get_hero_color(hero_id: String) -> Color:
	var hero: Dictionary = HEROES.get(hero_id, {})
	return hero.get("color", Color.WHITE) as Color


static func get_passive(hero_id: String) -> Dictionary:
	var hero: Dictionary = HEROES.get(hero_id, {})
	return hero.get("passive", {}) as Dictionary


static func get_passive_name(hero_id: String) -> String:
	var passive: Dictionary = get_passive(hero_id)
	return str(passive.get("name", ""))


static func get_passive_description(hero_id: String) -> String:
	var passive: Dictionary = get_passive(hero_id)
	return str(passive.get("description", ""))


static func get_passive_effects(hero_id: String) -> Dictionary:
	var passive: Dictionary = get_passive(hero_id)
	return passive.get("effects", {}) as Dictionary


static func get_ability(hero_id: String) -> Dictionary:
	var hero: Dictionary = HEROES.get(hero_id, {})
	return hero.get("ability", {}) as Dictionary


static func get_ability_name(hero_id: String) -> String:
	var ability: Dictionary = get_ability(hero_id)
	return str(ability.get("name", ""))


static func get_ability_word(hero_id: String) -> String:
	var ability: Dictionary = get_ability(hero_id)
	return str(ability.get("word", ""))


static func get_ability_description(hero_id: String) -> String:
	var ability: Dictionary = get_ability(hero_id)
	return str(ability.get("description", ""))


static func get_ability_cooldown(hero_id: String) -> float:
	var ability: Dictionary = get_ability(hero_id)
	return float(ability.get("cooldown", 60.0))


static func get_ability_duration(hero_id: String) -> float:
	var ability: Dictionary = get_ability(hero_id)
	return float(ability.get("duration", 0.0))


static func is_valid_hero(hero_id: String) -> bool:
	if hero_id == HERO_NONE:
		return true
	return HEROES.has(hero_id)


static func get_all_hero_ids() -> Array[String]:
	var ids: Array[String] = []
	for hero_id in HEROES.keys():
		ids.append(str(hero_id))
	return ids


static func match_ability_word(hero_id: String, typed_word: String) -> bool:
	if hero_id == HERO_NONE or hero_id == "":
		return false
	var ability_word: String = get_ability_word(hero_id)
	if ability_word == "":
		return false
	return typed_word.to_upper() == ability_word


static func get_hero_summary(hero_id: String) -> String:
	if hero_id == HERO_NONE or hero_id == "":
		return "No hero selected"
	var hero: Dictionary = get_hero(hero_id)
	if hero.is_empty():
		return "Unknown hero: %s" % hero_id
	var name: String = str(hero.get("name", ""))
	var hero_class: String = str(hero.get("class", ""))
	var passive: Dictionary = hero.get("passive", {}) as Dictionary
	var passive_name: String = str(passive.get("name", ""))
	var ability: Dictionary = hero.get("ability", {}) as Dictionary
	var ability_name: String = str(ability.get("name", ""))
	var ability_word: String = str(ability.get("word", ""))
	return "%s (%s)\nPassive: %s\nAbility: %s (type %s)" % [name, hero_class, passive_name, ability_name, ability_word]


static func get_heroes_list() -> String:
	var lines: Array[String] = ["Available Heroes:"]
	for hero_id in HEROES.keys():
		var hero: Dictionary = HEROES.get(hero_id, {})
		var name: String = str(hero.get("name", ""))
		var hero_class: String = str(hero.get("class", ""))
		lines.append("  %s - %s (%s)" % [hero_id, name, hero_class])
	lines.append("  none - Play without a hero")
	return "\n".join(lines)
