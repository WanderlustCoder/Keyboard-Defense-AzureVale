class_name SimDifficulty
extends RefCounted
## Difficulty mode definitions and modifier calculations

const MODES: Dictionary = {
	"story": {
		"name": "Story Mode",
		"description": "Experience the tale of Keystonia at your own pace.",
		"icon": "book",
		"enemy_health": 0.6,
		"enemy_damage": 0.5,
		"enemy_speed": 0.8,
		"wave_size": 0.7,
		"wave_delay": 1.5,
		"error_penalty": 0.5,
		"gold_earned": 1.0,
		"typo_forgiveness": 2,
		"word_preview_time": 3.0,
		"recommended": "New typists, story enthusiasts"
	},
	"adventure": {
		"name": "Adventure Mode",
		"description": "The intended experience. Balanced challenge that rewards skill.",
		"icon": "sword",
		"enemy_health": 1.0,
		"enemy_damage": 1.0,
		"enemy_speed": 1.0,
		"wave_size": 1.0,
		"wave_delay": 1.0,
		"error_penalty": 1.0,
		"gold_earned": 1.0,
		"typo_forgiveness": 1,
		"word_preview_time": 1.5,
		"recommended": "Most players, 40-60 WPM"
	},
	"champion": {
		"name": "Champion Mode",
		"description": "For experienced defenders. Enemies hit harder, margins are thin.",
		"icon": "crown",
		"enemy_health": 1.4,
		"enemy_damage": 1.5,
		"enemy_speed": 1.2,
		"wave_size": 1.3,
		"wave_delay": 0.8,
		"error_penalty": 1.5,
		"gold_earned": 1.3,
		"typo_forgiveness": 0,
		"word_preview_time": 1.0,
		"unlock_requirement": "complete_act_3",
		"recommended": "Skilled typists, 70+ WPM"
	},
	"nightmare": {
		"name": "Nightmare Mode",
		"description": "The ultimate test. Only the fastest survive.",
		"icon": "skull",
		"enemy_health": 2.0,
		"enemy_damage": 2.0,
		"enemy_speed": 1.4,
		"wave_size": 1.5,
		"wave_delay": 0.6,
		"error_penalty": 2.0,
		"gold_earned": 1.75,
		"typo_forgiveness": 0,
		"word_preview_time": 0.5,
		"unlock_requirement": "complete_champion",
		"recommended": "Elite typists, 100+ WPM"
	},
	"zen": {
		"name": "Zen Mode",
		"description": "No pressure. Pure typing practice with no enemies.",
		"icon": "lotus",
		"enemy_health": 0.0,
		"enemy_damage": 0.0,
		"enemy_speed": 0.0,
		"wave_size": 0.0,
		"wave_delay": 0.0,
		"error_penalty": 0.0,
		"gold_earned": 0.25,
		"typo_forgiveness": 99,
		"word_preview_time": 10.0,
		"enemies_disabled": true,
		"recommended": "Warm-up, focused practice"
	}
}

const DEFAULT_MODE := "adventure"

static func get_mode(mode_id: String) -> Dictionary:
	return MODES.get(mode_id, MODES[DEFAULT_MODE])

static func get_mode_name(mode_id: String) -> String:
	var mode: Dictionary = get_mode(mode_id)
	return str(mode.get("name", "Adventure Mode"))

static func get_mode_description(mode_id: String) -> String:
	var mode: Dictionary = get_mode(mode_id)
	return str(mode.get("description", ""))

static func get_all_mode_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in MODES.keys():
		ids.append(str(key))
	return ids

static func get_unlocked_modes(profile: Dictionary) -> Array[String]:
	var unlocked: Array[String] = ["story", "adventure", "zen"]
	var badges: Array = profile.get("badges", [])

	# Champion unlocks after completing Act 3 (day 12)
	if "full_alphabet_badge" in badges:
		unlocked.append("champion")

	# Nightmare unlocks after completing champion mode (special badge)
	if "champion_complete" in badges:
		unlocked.append("nightmare")

	return unlocked

static func is_mode_unlocked(mode_id: String, profile: Dictionary) -> bool:
	var unlocked: Array[String] = get_unlocked_modes(profile)
	return mode_id in unlocked

# Modifier getters with default fallback
static func get_enemy_health_mult(mode_id: String) -> float:
	var mode: Dictionary = get_mode(mode_id)
	return float(mode.get("enemy_health", 1.0))

static func get_enemy_damage_mult(mode_id: String) -> float:
	var mode: Dictionary = get_mode(mode_id)
	return float(mode.get("enemy_damage", 1.0))

static func get_enemy_speed_mult(mode_id: String) -> float:
	var mode: Dictionary = get_mode(mode_id)
	return float(mode.get("enemy_speed", 1.0))

static func get_wave_size_mult(mode_id: String) -> float:
	var mode: Dictionary = get_mode(mode_id)
	return float(mode.get("wave_size", 1.0))

static func get_wave_delay_mult(mode_id: String) -> float:
	var mode: Dictionary = get_mode(mode_id)
	return float(mode.get("wave_delay", 1.0))

static func get_error_penalty_mult(mode_id: String) -> float:
	var mode: Dictionary = get_mode(mode_id)
	return float(mode.get("error_penalty", 1.0))

static func get_gold_earned_mult(mode_id: String) -> float:
	var mode: Dictionary = get_mode(mode_id)
	return float(mode.get("gold_earned", 1.0))

static func get_typo_forgiveness(mode_id: String) -> int:
	var mode: Dictionary = get_mode(mode_id)
	return int(mode.get("typo_forgiveness", 1))

static func get_word_preview_time(mode_id: String) -> float:
	var mode: Dictionary = get_mode(mode_id)
	return float(mode.get("word_preview_time", 1.5))

static func are_enemies_disabled(mode_id: String) -> bool:
	var mode: Dictionary = get_mode(mode_id)
	return bool(mode.get("enemies_disabled", false))

# Apply modifiers to a base value
static func apply_health_modifier(base_hp: int, mode_id: String) -> int:
	return max(1, int(base_hp * get_enemy_health_mult(mode_id)))

static func apply_damage_modifier(base_damage: int, mode_id: String) -> int:
	return max(1, int(base_damage * get_enemy_damage_mult(mode_id)))

static func apply_speed_modifier(base_speed: float, mode_id: String) -> float:
	return max(0.1, base_speed * get_enemy_speed_mult(mode_id))

static func apply_wave_size_modifier(base_size: int, mode_id: String) -> int:
	return max(1, int(base_size * get_wave_size_mult(mode_id)))

static func apply_gold_modifier(base_gold: int, mode_id: String) -> int:
	return max(1, int(base_gold * get_gold_earned_mult(mode_id)))
