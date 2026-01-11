class_name SimCombo
extends RefCounted
## Combo system with tiers, bonuses, and visual feedback

const TIERS: Array[Dictionary] = [
	{
		"tier": 0,
		"name": "",
		"min_combo": 0,
		"damage_bonus": 0,
		"gold_bonus": 0,
		"color": "#FFFFFF"
	},
	{
		"tier": 1,
		"name": "Warming Up",
		"min_combo": 3,
		"damage_bonus": 5,
		"gold_bonus": 5,
		"color": "#90EE90"
	},
	{
		"tier": 2,
		"name": "On Fire",
		"min_combo": 5,
		"damage_bonus": 10,
		"gold_bonus": 10,
		"color": "#FFD700"
	},
	{
		"tier": 3,
		"name": "Blazing",
		"min_combo": 10,
		"damage_bonus": 20,
		"gold_bonus": 15,
		"color": "#FF8C00"
	},
	{
		"tier": 4,
		"name": "Inferno",
		"min_combo": 25,
		"damage_bonus": 35,
		"gold_bonus": 25,
		"color": "#FF4500"
	},
	{
		"tier": 5,
		"name": "Legendary",
		"min_combo": 50,
		"damage_bonus": 50,
		"gold_bonus": 40,
		"color": "#FF00FF"
	},
	{
		"tier": 6,
		"name": "Mythic",
		"min_combo": 100,
		"damage_bonus": 75,
		"gold_bonus": 60,
		"color": "#00FFFF"
	},
	{
		"tier": 7,
		"name": "GODLIKE",
		"min_combo": 200,
		"damage_bonus": 100,
		"gold_bonus": 100,
		"color": "#FFFFFF"  # Rainbow effect would be applied separately
	}
]

static func get_tier_for_combo(combo: int) -> Dictionary:
	var result: Dictionary = TIERS[0]
	for tier_data in TIERS:
		if combo >= int(tier_data.get("min_combo", 0)):
			result = tier_data
	return result

static func get_tier_number(combo: int) -> int:
	var tier: Dictionary = get_tier_for_combo(combo)
	return int(tier.get("tier", 0))

static func get_tier_name(combo: int) -> String:
	var tier: Dictionary = get_tier_for_combo(combo)
	return str(tier.get("name", ""))

static func get_damage_bonus_percent(combo: int) -> int:
	var tier: Dictionary = get_tier_for_combo(combo)
	return int(tier.get("damage_bonus", 0))

static func get_gold_bonus_percent(combo: int) -> int:
	var tier: Dictionary = get_tier_for_combo(combo)
	return int(tier.get("gold_bonus", 0))

static func get_tier_color(combo: int) -> Color:
	var tier: Dictionary = get_tier_for_combo(combo)
	var hex: String = str(tier.get("color", "#FFFFFF"))
	return Color.from_string(hex, Color.WHITE)

static func apply_damage_bonus(base_damage: int, combo: int) -> int:
	var bonus_percent: int = get_damage_bonus_percent(combo)
	if bonus_percent <= 0:
		return base_damage
	# Use roundi to avoid floating point truncation issues
	return roundi(base_damage * (1.0 + bonus_percent / 100.0))

static func apply_gold_bonus(base_gold: int, combo: int) -> int:
	var bonus_percent: int = get_gold_bonus_percent(combo)
	if bonus_percent <= 0:
		return base_gold
	# Use roundi to avoid floating point truncation issues
	return roundi(base_gold * (1.0 + bonus_percent / 100.0))

static func is_tier_milestone(prev_combo: int, new_combo: int) -> bool:
	## Check if transitioning from prev_combo to new_combo crossed a tier threshold
	var prev_tier: int = get_tier_number(prev_combo)
	var new_tier: int = get_tier_number(new_combo)
	return new_tier > prev_tier

static func get_tier_announcement(combo: int) -> String:
	## Get announcement text for reaching a new tier
	var tier_name: String = get_tier_name(combo)
	if tier_name.is_empty():
		return ""

	match tier_name:
		"Warming Up":
			return "Getting started!"
		"On Fire":
			return "ON FIRE! x%d Combo!" % combo
		"Blazing":
			return "BLAZING! x%d Combo!" % combo
		"Inferno":
			return "INFERNO! x%d Combo - Damage increased!" % combo
		"Legendary":
			return "LEGENDARY! x%d Combo - Unstoppable!" % combo
		"Mythic":
			return "MYTHIC! x%d Combo - True mastery!" % combo
		"GODLIKE":
			return "GODLIKE!!! x%d Combo - KEYBOARD MASTER!" % combo
		_:
			return "x%d Combo!" % combo

static func format_combo_display(combo: int) -> String:
	## Get formatted combo text for UI display
	if combo < 3:
		return ""
	var tier_name: String = get_tier_name(combo)
	if tier_name.is_empty():
		return "x%d" % combo
	return "x%d %s" % [combo, tier_name.to_upper()]
