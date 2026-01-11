class_name SimLoginRewards
extends RefCounted
## Login rewards system - daily streaks and bonuses

# Reward tiers based on consecutive login days
const REWARD_TIERS: Array[Dictionary] = [
	{"day": 1, "gold": 10, "bonus": ""},
	{"day": 2, "gold": 15, "bonus": ""},
	{"day": 3, "gold": 20, "bonus": "power_boost"},
	{"day": 4, "gold": 25, "bonus": ""},
	{"day": 5, "gold": 30, "bonus": ""},
	{"day": 6, "gold": 40, "bonus": "accuracy_boost"},
	{"day": 7, "gold": 50, "bonus": "xp_boost"},
	{"day": 14, "gold": 75, "bonus": "combo_boost"},
	{"day": 21, "gold": 100, "bonus": "gold_boost"},
	{"day": 30, "gold": 150, "bonus": "mega_boost"}
]

# Bonus item definitions
const BONUS_ITEMS: Dictionary = {
	"power_boost": {
		"name": "Power Boost",
		"description": "10% increased typing power for 3 battles",
		"icon": "lightning",
		"duration_battles": 3,
		"effect": {"typing_power": 0.1}
	},
	"accuracy_boost": {
		"name": "Accuracy Boost",
		"description": "5% mistake forgiveness for 3 battles",
		"icon": "shield",
		"duration_battles": 3,
		"effect": {"mistake_forgiveness": 0.05}
	},
	"xp_boost": {
		"name": "XP Boost",
		"description": "20% bonus gold for 5 battles",
		"icon": "star",
		"duration_battles": 5,
		"effect": {"gold_mult": 0.2}
	},
	"combo_boost": {
		"name": "Combo Boost",
		"description": "Combos charge 20% faster for 3 battles",
		"icon": "flame",
		"duration_battles": 3,
		"effect": {"combo_charge_rate": 0.2}
	},
	"gold_boost": {
		"name": "Gold Rush",
		"description": "50% bonus gold for 3 battles",
		"icon": "crown",
		"duration_battles": 3,
		"effect": {"gold_mult": 0.5}
	},
	"mega_boost": {
		"name": "Mega Boost",
		"description": "All stats +10% for 5 battles",
		"icon": "crown",
		"duration_battles": 5,
		"effect": {"typing_power": 0.1, "mistake_forgiveness": 0.05, "gold_mult": 0.1}
	}
}


static func should_show_reward(profile: Dictionary) -> bool:
	var last_login: int = int(profile.get("last_login_day", 0))
	var today: int = _get_today_number()
	return today > last_login


static func calculate_reward(streak: int) -> Dictionary:
	var gold := 10 + (streak * 5)
	var bonus := ""

	# Find matching tier
	for tier in REWARD_TIERS:
		if streak >= int(tier.get("day", 0)):
			gold = int(tier.get("gold", gold))
			var tier_bonus: String = str(tier.get("bonus", ""))
			if tier_bonus != "":
				bonus = tier_bonus

	return {
		"gold": gold,
		"bonus": bonus,
		"streak": streak
	}


static func apply_bonus_to_profile(profile: Dictionary, bonus_id: String) -> void:
	if bonus_id == "" or not BONUS_ITEMS.has(bonus_id):
		return

	var bonus_info: Dictionary = BONUS_ITEMS[bonus_id]
	var duration: int = int(bonus_info.get("duration_battles", 3))
	var effect: Dictionary = bonus_info.get("effect", {})

	if not profile.has("active_login_buffs"):
		profile["active_login_buffs"] = []

	profile["active_login_buffs"].append({
		"id": bonus_id,
		"battles_remaining": duration,
		"effect": effect.duplicate()
	})


static func get_bonus_info(bonus_id: String) -> Dictionary:
	return BONUS_ITEMS.get(bonus_id, {})


static func get_active_buffs(profile: Dictionary) -> Array:
	return profile.get("active_login_buffs", [])


static func get_streak_progress(current_streak: int) -> Dictionary:
	var next_tier: Dictionary = {}
	var days_to_next := 0

	for tier in REWARD_TIERS:
		var tier_day: int = int(tier.get("day", 0))
		if tier_day > current_streak:
			next_tier = tier
			days_to_next = tier_day - current_streak
			break

	return {
		"current_streak": current_streak,
		"next_tier": next_tier,
		"days_to_next": days_to_next
	}


static func format_reward_text(reward: Dictionary) -> String:
	var parts: Array[String] = []

	var gold: int = int(reward.get("gold", 0))
	if gold > 0:
		parts.append("+%d Gold" % gold)

	var bonus: String = str(reward.get("bonus", ""))
	if bonus != "" and BONUS_ITEMS.has(bonus):
		var bonus_info: Dictionary = BONUS_ITEMS[bonus]
		parts.append(str(bonus_info.get("name", bonus)))

	return ", ".join(parts) if not parts.is_empty() else "Login Reward"


static func tick_buffs(profile: Dictionary) -> void:
	## Call after each battle to decrement buff durations
	if not profile.has("active_login_buffs"):
		return

	var buffs: Array = profile["active_login_buffs"]
	var i := buffs.size() - 1
	while i >= 0:
		buffs[i]["battles_remaining"] = int(buffs[i].get("battles_remaining", 0)) - 1
		if buffs[i]["battles_remaining"] <= 0:
			buffs.remove_at(i)
		i -= 1


static func get_combined_buff_effects(profile: Dictionary) -> Dictionary:
	## Get combined effects from all active login buffs
	var combined: Dictionary = {}
	var buffs: Array = profile.get("active_login_buffs", [])

	for buff in buffs:
		var effect: Dictionary = buff.get("effect", {})
		for key in effect.keys():
			combined[key] = float(combined.get(key, 0.0)) + float(effect[key])

	return combined


static func _get_today_number() -> int:
	## Get a unique number for today (days since epoch)
	var unix_time: float = Time.get_unix_time_from_system()
	return int(unix_time / 86400.0)
