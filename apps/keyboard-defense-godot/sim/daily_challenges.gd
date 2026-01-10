class_name SimDailyChallenges
extends RefCounted
## Daily Challenge System - Special themed challenges that change each day

# Challenge templates - one is selected each day
const CHALLENGES: Dictionary = {
	"speed_demon": {
		"name": "Speed Demon",
		"description": "Enemies move 50% faster, but you deal 25% more damage",
		"icon": "fast",
		"modifiers": {"enemy_speed": 1.5, "player_damage": 1.25},
		"goal": {"type": "survive_waves", "target": 5},
		"rewards": {"gold": 200, "xp": 150, "tokens": 2}
	},
	"glass_cannon": {
		"name": "Glass Cannon",
		"description": "Castle has only 5 HP, but you deal triple damage",
		"icon": "power",
		"modifiers": {"max_hp": 5, "player_damage": 3.0},
		"goal": {"type": "survive_waves", "target": 3},
		"rewards": {"gold": 250, "xp": 200, "tokens": 3}
	},
	"swarm_survival": {
		"name": "Swarm Survival",
		"description": "Double enemies, half HP each. Survive the horde!",
		"icon": "swarm",
		"modifiers": {"enemy_count": 2.0, "enemy_hp": 0.5},
		"goal": {"type": "kill_count", "target": 50},
		"rewards": {"gold": 180, "xp": 120, "tokens": 2}
	},
	"precision_strike": {
		"name": "Precision Strike",
		"description": "Any typo ends the run. Perfect typing only!",
		"icon": "target",
		"modifiers": {"typo_ends_run": true},
		"goal": {"type": "words_typed", "target": 30},
		"rewards": {"gold": 300, "xp": 250, "tokens": 4}
	},
	"combo_master": {
		"name": "Combo Master",
		"description": "Combo damage bonus is doubled. Chain those kills!",
		"icon": "combo",
		"modifiers": {"combo_bonus": 2.0},
		"goal": {"type": "max_combo", "target": 25},
		"rewards": {"gold": 220, "xp": 180, "tokens": 3}
	},
	"iron_fortress": {
		"name": "Iron Fortress",
		"description": "Can't heal between waves. Preserve your HP!",
		"icon": "shield",
		"modifiers": {"no_wave_heal": true, "max_hp": 15},
		"goal": {"type": "survive_waves", "target": 7},
		"rewards": {"gold": 280, "xp": 220, "tokens": 3}
	},
	"time_attack": {
		"name": "Time Attack",
		"description": "Complete each wave in 45 seconds or lose HP",
		"icon": "clock",
		"modifiers": {"wave_time_limit": 45, "time_damage": 3},
		"goal": {"type": "survive_waves", "target": 5},
		"rewards": {"gold": 240, "xp": 190, "tokens": 3}
	},
	"word_marathon": {
		"name": "Word Marathon",
		"description": "Type 100 words without breaking your combo",
		"icon": "keyboard",
		"modifiers": {"marathon_mode": true},
		"goal": {"type": "words_without_break", "target": 100},
		"rewards": {"gold": 350, "xp": 300, "tokens": 5}
	},
	"boss_rush": {
		"name": "Boss Rush",
		"description": "Face a boss every wave! Extra rewards.",
		"icon": "skull",
		"modifiers": {"boss_every_wave": true, "gold_mult": 2.0},
		"goal": {"type": "boss_kills", "target": 3},
		"rewards": {"gold": 400, "xp": 350, "tokens": 5}
	},
	"minimalist": {
		"name": "Minimalist",
		"description": "No buildings, no items. Pure typing skill!",
		"icon": "simple",
		"modifiers": {"no_buildings": true, "no_items": true},
		"goal": {"type": "survive_waves", "target": 4},
		"rewards": {"gold": 200, "xp": 160, "tokens": 2}
	},
	"long_words": {
		"name": "Lexicon Master",
		"description": "All words are 8+ characters. Vocabulary test!",
		"icon": "book",
		"modifiers": {"min_word_length": 8},
		"goal": {"type": "words_typed", "target": 25},
		"rewards": {"gold": 260, "xp": 200, "tokens": 3}
	},
	"gold_rush": {
		"name": "Gold Rush",
		"description": "Triple gold, but enemies have +50% HP",
		"icon": "gold",
		"modifiers": {"gold_mult": 3.0, "enemy_hp": 1.5},
		"goal": {"type": "gold_earned", "target": 500},
		"rewards": {"gold": 150, "xp": 100, "tokens": 2}
	}
}

# Token shop items (tokens earned from challenges)
const TOKEN_SHOP: Dictionary = {
	"exclusive_cape": {
		"name": "Champion's Cape",
		"description": "+15% gold, +10% XP from all sources",
		"cost": 25,
		"type": "equipment",
		"stats": {"gold_bonus": 0.15, "xp_bonus": 0.10}
	},
	"exclusive_ring": {
		"name": "Challenger's Ring",
		"description": "+20% crit chance, +50% crit damage",
		"cost": 30,
		"type": "equipment",
		"stats": {"crit_chance": 0.20, "crit_damage": 0.50}
	},
	"exclusive_amulet": {
		"name": "Daily Victor Amulet",
		"description": "+25% damage, +5% dodge",
		"cost": 35,
		"type": "equipment",
		"stats": {"damage_bonus": 0.25, "dodge_chance": 0.05}
	},
	"token_potion_bundle": {
		"name": "Potion Bundle",
		"description": "5 health potions",
		"cost": 10,
		"type": "consumable_bundle",
		"item": "potion_health",
		"quantity": 5
	},
	"token_scroll_bundle": {
		"name": "Scroll Bundle",
		"description": "3 damage scrolls",
		"cost": 15,
		"type": "consumable_bundle",
		"item": "scroll_damage",
		"quantity": 3
	}
}

# Streak bonuses for completing challenges on consecutive days
const STREAK_BONUSES: Dictionary = {
	3: {"tokens": 2, "name": "3-Day Streak"},
	7: {"tokens": 5, "name": "Weekly Warrior"},
	14: {"tokens": 10, "name": "Fortnight Fighter"},
	30: {"tokens": 25, "name": "Monthly Master"},
	100: {"tokens": 100, "name": "Century Champion"}
}


## Get today's challenge
static func get_daily_challenge(profile: Dictionary) -> Dictionary:
	var today: int = _get_today_seed()
	var challenge_id: String = _select_challenge(today)
	var challenge: Dictionary = CHALLENGES.get(challenge_id, {}).duplicate(true)
	challenge["id"] = challenge_id

	# Check if already completed today
	var last_completed: int = int(TypingProfile.get_profile_value(profile, "daily_challenge_last_completed", 0))
	challenge["completed_today"] = (last_completed == today)

	# Get current streak
	challenge["current_streak"] = int(TypingProfile.get_profile_value(profile, "daily_challenge_streak", 0))

	return challenge


## Select challenge for a given day (deterministic)
static func _select_challenge(day_seed: int) -> String:
	var challenge_ids: Array = CHALLENGES.keys()
	var index: int = day_seed % challenge_ids.size()
	return challenge_ids[index]


## Get today's seed (days since epoch)
static func _get_today_seed() -> int:
	return int(Time.get_unix_time_from_system() / 86400)


## Start a daily challenge run
static func start_challenge(profile: Dictionary) -> Dictionary:
	var today: int = _get_today_seed()
	var challenge_id: String = _select_challenge(today)
	var challenge: Dictionary = CHALLENGES.get(challenge_id, {}).duplicate(true)

	return {
		"id": challenge_id,
		"challenge": challenge,
		"progress": 0,
		"started_at": Time.get_unix_time_from_system()
	}


## Update challenge progress
static func update_progress(challenge_state: Dictionary, stat_type: String, value: int) -> Dictionary:
	var challenge: Dictionary = challenge_state.get("challenge", {})
	var goal: Dictionary = challenge.get("goal", {})
	var goal_type: String = str(goal.get("type", ""))

	# Check if this stat contributes to the goal
	if goal_type == stat_type:
		if goal_type in ["max_combo"]:
			challenge_state["progress"] = max(int(challenge_state.get("progress", 0)), value)
		else:
			challenge_state["progress"] = int(challenge_state.get("progress", 0)) + value

	# Special case: words_without_break resets on combo break
	if goal_type == "words_without_break" and stat_type == "combo_break":
		challenge_state["progress"] = 0

	return challenge_state


## Check if challenge is complete
static func is_complete(challenge_state: Dictionary) -> bool:
	var challenge: Dictionary = challenge_state.get("challenge", {})
	var goal: Dictionary = challenge.get("goal", {})
	var target: int = int(goal.get("target", 0))
	var progress: int = int(challenge_state.get("progress", 0))

	return progress >= target


## Complete the challenge and grant rewards
static func complete_challenge(profile: Dictionary, challenge_state: Dictionary) -> Dictionary:
	var today: int = _get_today_seed()
	var challenge: Dictionary = challenge_state.get("challenge", {})
	var rewards: Dictionary = challenge.get("rewards", {})
	var result: Dictionary = {
		"gold": 0,
		"xp": 0,
		"tokens": 0,
		"streak_bonus": 0,
		"streak_milestone": ""
	}

	# Grant base rewards
	result["gold"] = int(rewards.get("gold", 0))
	result["xp"] = int(rewards.get("xp", 0))
	result["tokens"] = int(rewards.get("tokens", 0))

	# Update streak
	var last_completed: int = int(TypingProfile.get_profile_value(profile, "daily_challenge_last_completed", 0))
	var current_streak: int = int(TypingProfile.get_profile_value(profile, "daily_challenge_streak", 0))

	if last_completed == today - 1:
		# Consecutive day - increase streak
		current_streak += 1
	elif last_completed != today:
		# Streak broken - reset
		current_streak = 1

	# Check for streak bonuses
	if STREAK_BONUSES.has(current_streak):
		var bonus: Dictionary = STREAK_BONUSES[current_streak]
		result["streak_bonus"] = int(bonus.get("tokens", 0))
		result["streak_milestone"] = str(bonus.get("name", ""))
		result["tokens"] += result["streak_bonus"]

	# Update profile
	TypingProfile.set_profile_value(profile, "daily_challenge_last_completed", today)
	TypingProfile.set_profile_value(profile, "daily_challenge_streak", current_streak)

	var total_tokens: int = int(TypingProfile.get_profile_value(profile, "challenge_tokens", 0))
	TypingProfile.set_profile_value(profile, "challenge_tokens", total_tokens + result["tokens"])

	var total_completed: int = int(TypingProfile.get_profile_value(profile, "daily_challenges_completed", 0))
	TypingProfile.set_profile_value(profile, "daily_challenges_completed", total_completed + 1)

	return result


## Get player's token balance
static func get_token_balance(profile: Dictionary) -> int:
	return int(TypingProfile.get_profile_value(profile, "challenge_tokens", 0))


## Get current streak
static func get_streak(profile: Dictionary) -> int:
	var today: int = _get_today_seed()
	var last_completed: int = int(TypingProfile.get_profile_value(profile, "daily_challenge_last_completed", 0))
	var streak: int = int(TypingProfile.get_profile_value(profile, "daily_challenge_streak", 0))

	# Check if streak is still valid
	if last_completed < today - 1:
		return 0  # Streak broken
	return streak


## Purchase from token shop
static func purchase_token_item(profile: Dictionary, item_id: String) -> Dictionary:
	var item: Dictionary = TOKEN_SHOP.get(item_id, {})
	if item.is_empty():
		return {"success": false, "error": "Item not found"}

	var cost: int = int(item.get("cost", 0))
	var balance: int = get_token_balance(profile)

	if balance < cost:
		return {"success": false, "error": "Not enough tokens"}

	# Deduct tokens
	TypingProfile.set_profile_value(profile, "challenge_tokens", balance - cost)

	# Grant item
	var item_type: String = str(item.get("type", ""))
	if item_type == "equipment":
		TypingProfile.add_to_inventory(profile, item_id)
	elif item_type == "consumable_bundle":
		var consumable_id: String = str(item.get("item", ""))
		var quantity: int = int(item.get("quantity", 1))
		for i in range(quantity):
			TypingProfile.add_to_inventory(profile, consumable_id)

	return {"success": true, "item": item}


## Get all token shop items
static func get_shop_items() -> Dictionary:
	return TOKEN_SHOP.duplicate(true)


## Format challenge for display
static func format_challenge(challenge: Dictionary) -> String:
	var lines: Array[String] = []

	var name: String = str(challenge.get("name", "Unknown"))
	var desc: String = str(challenge.get("description", ""))
	var goal: Dictionary = challenge.get("goal", {})
	var rewards: Dictionary = challenge.get("rewards", {})

	lines.append("[color=yellow]%s[/color]" % name)
	lines.append(desc)
	lines.append("")

	# Goal
	var goal_type: String = str(goal.get("type", ""))
	var target: int = int(goal.get("target", 0))
	var goal_text: String = _format_goal(goal_type, target)
	lines.append("[color=cyan]Goal:[/color] %s" % goal_text)

	# Rewards
	var reward_parts: Array[String] = []
	if int(rewards.get("gold", 0)) > 0:
		reward_parts.append("%d gold" % int(rewards.get("gold", 0)))
	if int(rewards.get("xp", 0)) > 0:
		reward_parts.append("%d XP" % int(rewards.get("xp", 0)))
	if int(rewards.get("tokens", 0)) > 0:
		reward_parts.append("%d tokens" % int(rewards.get("tokens", 0)))

	lines.append("[color=lime]Rewards:[/color] %s" % ", ".join(reward_parts))

	if bool(challenge.get("completed_today", false)):
		lines.append("")
		lines.append("[color=gray]Already completed today![/color]")

	return "\n".join(lines)


## Format goal type for display
static func _format_goal(goal_type: String, target: int) -> String:
	match goal_type:
		"survive_waves": return "Survive %d waves" % target
		"kill_count": return "Kill %d enemies" % target
		"words_typed": return "Type %d words" % target
		"max_combo": return "Reach %d combo" % target
		"boss_kills": return "Defeat %d bosses" % target
		"gold_earned": return "Earn %d gold" % target
		"words_without_break": return "Type %d words without breaking combo" % target
		_: return "%s: %d" % [goal_type, target]


## Format token shop for display
static func format_shop(profile: Dictionary) -> String:
	var lines: Array[String] = []
	var balance: int = get_token_balance(profile)

	lines.append("[color=yellow]TOKEN SHOP[/color]")
	lines.append("Your Tokens: [color=cyan]%d[/color]" % balance)
	lines.append("")

	for item_id in TOKEN_SHOP.keys():
		var item: Dictionary = TOKEN_SHOP[item_id]
		var name: String = str(item.get("name", item_id))
		var desc: String = str(item.get("description", ""))
		var cost: int = int(item.get("cost", 0))

		var color: String = "lime" if balance >= cost else "red"
		lines.append("[color=%s]%s[/color] - %d tokens" % [color, name, cost])
		lines.append("  %s" % desc)

	lines.append("")
	lines.append("[color=gray]Use 'tokenbuy <item_id>' to purchase[/color]")

	return "\n".join(lines)
