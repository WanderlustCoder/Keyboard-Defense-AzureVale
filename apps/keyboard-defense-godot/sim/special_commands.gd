class_name SimSpecialCommands
extends RefCounted
## Special Typing Commands - Powerful abilities triggered by typing specific words

# Command definitions
const COMMANDS: Dictionary = {
	"overcharge": {
		"name": "Overcharge",
		"word": "OVERCHARGE",
		"cooldown": 60.0,
		"difficulty": "hard",
		"description": "All auto-towers fire at 200% speed for 5 seconds.",
		"effect": {"type": "auto_tower_speed", "value": 2.0, "duration": 5.0}
	},
	"barrage": {
		"name": "Barrage",
		"word": "BARRAGE",
		"cooldown": 45.0,
		"difficulty": "medium",
		"description": "Next 5 typing attacks deal double damage.",
		"effect": {"type": "damage_charges", "value": 2.0, "charges": 5}
	},
	"fortify": {
		"name": "Fortify",
		"word": "FORTIFY",
		"cooldown": 90.0,
		"difficulty": "hard",
		"description": "Castle takes 50% less damage for 15 seconds.",
		"effect": {"type": "damage_reduction", "value": 0.5, "duration": 15.0}
	},
	"heal": {
		"name": "Healing Word",
		"word": "HEAL",
		"cooldown": 120.0,
		"difficulty": "easy",
		"description": "Restore 3 castle HP.",
		"effect": {"type": "heal", "value": 3}
	},
	"freeze": {
		"name": "Frost Nova",
		"word": "FREEZE",
		"cooldown": 75.0,
		"difficulty": "medium",
		"description": "Freeze all enemies for 3 seconds.",
		"effect": {"type": "freeze_all", "duration": 3.0}
	},
	"fury": {
		"name": "Typing Fury",
		"word": "FURY",
		"cooldown": 40.0,
		"difficulty": "easy",
		"description": "+50% damage for 10 seconds.",
		"effect": {"type": "damage_buff", "value": 0.5, "duration": 10.0}
	},
	"gold": {
		"name": "Gold Rush",
		"word": "GOLD",
		"cooldown": 60.0,
		"difficulty": "easy",
		"description": "+100% gold for 20 seconds.",
		"effect": {"type": "gold_buff", "value": 1.0, "duration": 20.0}
	},
	"critical": {
		"name": "Critical Focus",
		"word": "CRITICAL",
		"cooldown": 30.0,
		"difficulty": "hard",
		"description": "Next 3 attacks are guaranteed crits.",
		"effect": {"type": "crit_charges", "value": 1.0, "charges": 3}
	},
	"cleave": {
		"name": "Cleaving Strike",
		"word": "CLEAVE",
		"cooldown": 50.0,
		"difficulty": "medium",
		"description": "Next attack hits all enemies for 50% damage.",
		"effect": {"type": "cleave_next", "value": 0.5}
	},
	"execute": {
		"name": "Execute",
		"word": "EXECUTE",
		"cooldown": 35.0,
		"difficulty": "hard",
		"description": "Instantly kill the targeted enemy if below 30% HP.",
		"effect": {"type": "execute", "threshold": 0.3}
	},
	"combo": {
		"name": "Combo Boost",
		"word": "COMBO",
		"cooldown": 45.0,
		"difficulty": "medium",
		"description": "Instantly gain +10 combo.",
		"effect": {"type": "combo_boost", "value": 10}
	},
	"shield": {
		"name": "Shield Wall",
		"word": "SHIELD",
		"cooldown": 80.0,
		"difficulty": "medium",
		"description": "Block the next 2 enemies from damaging castle.",
		"effect": {"type": "block_charges", "charges": 2}
	}
}

# Unlock requirements by player level
const UNLOCK_LEVELS: Dictionary = {
	"heal": 1,
	"fury": 3,
	"gold": 5,
	"combo": 7,
	"barrage": 10,
	"freeze": 12,
	"critical": 15,
	"cleave": 18,
	"shield": 20,
	"execute": 22,
	"fortify": 25,
	"overcharge": 30
}


## Get all command IDs
static func get_all_command_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in COMMANDS.keys():
		ids.append(id)
	return ids


## Get command data
static func get_command(command_id: String) -> Dictionary:
	return COMMANDS.get(command_id, {})


## Get the word to type for a command
static func get_command_word(command_id: String) -> String:
	return str(COMMANDS.get(command_id, {}).get("word", ""))


## Check if a typed word matches any command
static func match_command(typed_word: String) -> String:
	var upper_word: String = typed_word.to_upper()
	for command_id in COMMANDS.keys():
		if upper_word == str(COMMANDS[command_id].get("word", "")):
			return command_id
	return ""


## Get unlock level for a command
static func get_unlock_level(command_id: String) -> int:
	return int(UNLOCK_LEVELS.get(command_id, 1))


## Check if command is unlocked
static func is_unlocked(command_id: String, player_level: int) -> bool:
	return player_level >= get_unlock_level(command_id)


## Get all unlocked commands for a player level
static func get_unlocked_commands(player_level: int) -> Array[String]:
	var unlocked: Array[String] = []
	for command_id in COMMANDS.keys():
		if is_unlocked(command_id, player_level):
			unlocked.append(command_id)
	return unlocked


## Get cooldown for a command
static func get_cooldown(command_id: String) -> float:
	return float(COMMANDS.get(command_id, {}).get("cooldown", 60.0))


## Get effect data for a command
static func get_effect(command_id: String) -> Dictionary:
	return COMMANDS.get(command_id, {}).get("effect", {})


## Format command for display
static func format_command(command_id: String, cooldown_remaining: float = 0.0) -> String:
	var cmd: Dictionary = get_command(command_id)
	if cmd.is_empty():
		return ""

	var word: String = str(cmd.get("word", ""))
	var name: String = str(cmd.get("name", command_id))
	var desc: String = str(cmd.get("description", ""))
	var cooldown: float = float(cmd.get("cooldown", 60.0))

	var status: String = "[color=lime]READY[/color]"
	if cooldown_remaining > 0:
		status = "[color=red]%.0fs[/color]" % cooldown_remaining

	return "[color=yellow]%s[/color] (%s) - %s [%s]" % [word, name, desc, status]


## Get difficulty color
static func get_difficulty_color(command_id: String) -> String:
	var difficulty: String = str(COMMANDS.get(command_id, {}).get("difficulty", "medium"))
	match difficulty:
		"easy": return "lime"
		"medium": return "yellow"
		"hard": return "orange"
		_: return "white"
