class_name SimQuests
extends RefCounted
## Quest and Mission System

# Quest types
const TYPE_DAILY := "daily"
const TYPE_WEEKLY := "weekly"
const TYPE_STORY := "story"
const TYPE_CHALLENGE := "challenge"

# Quest status
const STATUS_AVAILABLE := "available"
const STATUS_ACTIVE := "active"
const STATUS_COMPLETED := "completed"
const STATUS_CLAIMED := "claimed"

# Daily quest templates (randomly selected each day)
const DAILY_QUESTS: Array[Dictionary] = [
	{
		"id": "daily_kills_10",
		"name": "Monster Slayer",
		"description": "Defeat 10 enemies",
		"type": "daily",
		"objective": {"type": "kills", "target": 10},
		"rewards": {"gold": 25, "xp": 20}
	},
	{
		"id": "daily_kills_25",
		"name": "Monster Hunter",
		"description": "Defeat 25 enemies",
		"type": "daily",
		"objective": {"type": "kills", "target": 25},
		"rewards": {"gold": 50, "xp": 40}
	},
	{
		"id": "daily_combo_10",
		"name": "Combo Starter",
		"description": "Reach a 10 combo",
		"type": "daily",
		"objective": {"type": "max_combo", "target": 10},
		"rewards": {"gold": 30, "xp": 25}
	},
	{
		"id": "daily_combo_20",
		"name": "Combo Master",
		"description": "Reach a 20 combo",
		"type": "daily",
		"objective": {"type": "max_combo", "target": 20},
		"rewards": {"gold": 60, "xp": 50}
	},
	{
		"id": "daily_waves_3",
		"name": "Wave Survivor",
		"description": "Complete 3 waves",
		"type": "daily",
		"objective": {"type": "waves", "target": 3},
		"rewards": {"gold": 20, "xp": 15}
	},
	{
		"id": "daily_waves_5",
		"name": "Wave Champion",
		"description": "Complete 5 waves",
		"type": "daily",
		"objective": {"type": "waves", "target": 5},
		"rewards": {"gold": 40, "xp": 30}
	},
	{
		"id": "daily_accuracy_90",
		"name": "Precision Typer",
		"description": "Finish a wave with 90%+ accuracy",
		"type": "daily",
		"objective": {"type": "accuracy", "target": 90},
		"rewards": {"gold": 35, "xp": 30}
	},
	{
		"id": "daily_no_damage",
		"name": "Untouchable",
		"description": "Complete a wave without taking damage",
		"type": "daily",
		"objective": {"type": "no_damage_wave", "target": 1},
		"rewards": {"gold": 50, "xp": 40}
	},
	{
		"id": "daily_gold_100",
		"name": "Gold Collector",
		"description": "Earn 100 gold",
		"type": "daily",
		"objective": {"type": "gold_earned", "target": 100},
		"rewards": {"gold": 25, "xp": 20}
	},
	{
		"id": "daily_words_50",
		"name": "Wordsmith",
		"description": "Type 50 words correctly",
		"type": "daily",
		"objective": {"type": "words_typed", "target": 50},
		"rewards": {"gold": 30, "xp": 25}
	},
	{
		"id": "daily_boss_1",
		"name": "Boss Slayer",
		"description": "Defeat a boss enemy",
		"type": "daily",
		"objective": {"type": "boss_kills", "target": 1},
		"rewards": {"gold": 75, "xp": 60}
	},
	{
		"id": "daily_spells_3",
		"name": "Spellcaster",
		"description": "Use 3 special commands",
		"type": "daily",
		"objective": {"type": "spells_used", "target": 3},
		"rewards": {"gold": 40, "xp": 35}
	}
]

# Weekly quest templates
const WEEKLY_QUESTS: Array[Dictionary] = [
	{
		"id": "weekly_kills_100",
		"name": "Weekly Warrior",
		"description": "Defeat 100 enemies this week",
		"type": "weekly",
		"objective": {"type": "kills", "target": 100},
		"rewards": {"gold": 200, "xp": 150, "item": "potion_health"}
	},
	{
		"id": "weekly_combo_50",
		"name": "Combo Legend",
		"description": "Reach a 50 combo",
		"type": "weekly",
		"objective": {"type": "max_combo", "target": 50},
		"rewards": {"gold": 300, "xp": 200, "item": "scroll_damage"}
	},
	{
		"id": "weekly_days_5",
		"name": "Dedicated Defender",
		"description": "Survive 5 days",
		"type": "weekly",
		"objective": {"type": "days_survived", "target": 5},
		"rewards": {"gold": 250, "xp": 175}
	},
	{
		"id": "weekly_perfect_waves",
		"name": "Perfect Week",
		"description": "Complete 10 waves with 95%+ accuracy",
		"type": "weekly",
		"objective": {"type": "perfect_waves", "target": 10},
		"rewards": {"gold": 400, "xp": 300, "item": "scroll_gold"}
	},
	{
		"id": "weekly_bosses_3",
		"name": "Boss Hunter",
		"description": "Defeat 3 bosses",
		"type": "weekly",
		"objective": {"type": "boss_kills", "target": 3},
		"rewards": {"gold": 350, "xp": 250, "item": "potion_health_large"}
	},
	{
		"id": "weekly_gold_500",
		"name": "Treasure Hoarder",
		"description": "Earn 500 gold total",
		"type": "weekly",
		"objective": {"type": "gold_earned", "target": 500},
		"rewards": {"gold": 150, "xp": 100}
	}
]

# Challenge quests (one-time, harder)
const CHALLENGE_QUESTS: Dictionary = {
	"challenge_combo_100": {
		"name": "Legendary Combo",
		"description": "Reach a 100 combo",
		"type": "challenge",
		"objective": {"type": "max_combo", "target": 100},
		"rewards": {"gold": 500, "xp": 400, "item": "ring_combo"}
	},
	"challenge_no_damage_day": {
		"name": "Invincible",
		"description": "Complete an entire day without taking damage",
		"type": "challenge",
		"objective": {"type": "no_damage_day", "target": 1},
		"rewards": {"gold": 750, "xp": 500, "item": "cape_shadow"}
	},
	"challenge_speed_demon": {
		"name": "Speed Demon",
		"description": "Complete a wave in under 30 seconds",
		"type": "challenge",
		"objective": {"type": "fast_wave", "target": 30},
		"rewards": {"gold": 400, "xp": 300, "item": "boots_swift"}
	},
	"challenge_kills_1000": {
		"name": "Veteran Defender",
		"description": "Defeat 1000 enemies total",
		"type": "challenge",
		"objective": {"type": "total_kills", "target": 1000},
		"rewards": {"gold": 1000, "xp": 750, "item": "amulet_power"}
	},
	"challenge_survive_20": {
		"name": "Endurance Test",
		"description": "Survive to day 20",
		"type": "challenge",
		"objective": {"type": "days_survived", "target": 20},
		"rewards": {"gold": 800, "xp": 600, "item": "armor_chain"}
	}
}


## Get quest by ID
static func get_quest(quest_id: String) -> Dictionary:
	# Check daily quests
	for quest in DAILY_QUESTS:
		if quest.get("id", "") == quest_id:
			return quest.duplicate(true)

	# Check weekly quests
	for quest in WEEKLY_QUESTS:
		if quest.get("id", "") == quest_id:
			return quest.duplicate(true)

	# Check challenge quests
	if CHALLENGE_QUESTS.has(quest_id):
		var quest: Dictionary = CHALLENGE_QUESTS[quest_id].duplicate(true)
		quest["id"] = quest_id
		return quest

	return {}


## Generate daily quests for a given day (deterministic based on day number)
static func generate_daily_quests(day_seed: int) -> Array[String]:
	var quests: Array[String] = []
	var available: Array[Dictionary] = DAILY_QUESTS.duplicate()

	# Pick 3 random daily quests
	var rng_val: int = day_seed * 7919
	for i in range(3):
		if available.is_empty():
			break
		var index: int = int(fmod(float(rng_val + i * 1009), float(available.size())))
		quests.append(str(available[index].get("id", "")))
		available.remove_at(index)

	return quests


## Generate weekly quests for a given week (deterministic)
static func generate_weekly_quests(week_seed: int) -> Array[String]:
	var quests: Array[String] = []
	var available: Array[Dictionary] = WEEKLY_QUESTS.duplicate()

	# Pick 2 random weekly quests
	var rng_val: int = week_seed * 3571
	for i in range(2):
		if available.is_empty():
			break
		var index: int = int(fmod(float(rng_val + i * 503), float(available.size())))
		quests.append(str(available[index].get("id", "")))
		available.remove_at(index)

	return quests


## Get all challenge quest IDs
static func get_all_challenge_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in CHALLENGE_QUESTS.keys():
		ids.append(id)
	return ids


## Check if quest objective is met
static func check_objective(quest_id: String, progress: Dictionary) -> bool:
	var quest: Dictionary = get_quest(quest_id)
	if quest.is_empty():
		return false

	var objective: Dictionary = quest.get("objective", {})
	var obj_type: String = str(objective.get("type", ""))
	var target: int = int(objective.get("target", 0))
	var current: int = int(progress.get(obj_type, 0))

	return current >= target


## Get quest progress percentage
static func get_progress_percent(quest_id: String, progress: Dictionary) -> float:
	var quest: Dictionary = get_quest(quest_id)
	if quest.is_empty():
		return 0.0

	var objective: Dictionary = quest.get("objective", {})
	var obj_type: String = str(objective.get("type", ""))
	var target: int = int(objective.get("target", 1))
	var current: int = int(progress.get(obj_type, 0))

	return min(1.0, float(current) / float(target))


## Format quest for display
static func format_quest(quest_id: String, progress: Dictionary, status: String = STATUS_ACTIVE) -> String:
	var quest: Dictionary = get_quest(quest_id)
	if quest.is_empty():
		return "[color=gray]Unknown quest[/color]"

	var name: String = str(quest.get("name", quest_id))
	var desc: String = str(quest.get("description", ""))
	var objective: Dictionary = quest.get("objective", {})
	var target: int = int(objective.get("target", 0))
	var obj_type: String = str(objective.get("type", ""))
	var current: int = int(progress.get(obj_type, 0))
	var rewards: Dictionary = quest.get("rewards", {})

	var status_color: String = "white"
	var status_text: String = ""
	match status:
		STATUS_COMPLETED:
			status_color = "lime"
			status_text = " [COMPLETE]"
		STATUS_CLAIMED:
			status_color = "gray"
			status_text = " [CLAIMED]"
		STATUS_ACTIVE:
			status_color = "yellow"

	var progress_text: String = "%d/%d" % [min(current, target), target]
	if status == STATUS_COMPLETED or status == STATUS_CLAIMED:
		progress_text = "%d/%d" % [target, target]

	var reward_parts: Array[String] = []
	if int(rewards.get("gold", 0)) > 0:
		reward_parts.append("%dg" % int(rewards.get("gold", 0)))
	if int(rewards.get("xp", 0)) > 0:
		reward_parts.append("%d XP" % int(rewards.get("xp", 0)))
	if rewards.has("item"):
		reward_parts.append("+ item")

	return "[color=%s]%s[/color]%s\n  %s (%s)\n  Rewards: %s" % [
		status_color, name, status_text, desc, progress_text, ", ".join(reward_parts)
	]


## Get reward summary text
static func get_reward_text(quest_id: String) -> String:
	var quest: Dictionary = get_quest(quest_id)
	if quest.is_empty():
		return ""

	var rewards: Dictionary = quest.get("rewards", {})
	var parts: Array[String] = []

	if int(rewards.get("gold", 0)) > 0:
		parts.append("[color=gold]+%d gold[/color]" % int(rewards.get("gold", 0)))
	if int(rewards.get("xp", 0)) > 0:
		parts.append("[color=cyan]+%d XP[/color]" % int(rewards.get("xp", 0)))
	if rewards.has("item"):
		parts.append("[color=lime]+%s[/color]" % str(rewards.get("item", "")))

	return ", ".join(parts)


## Create empty quest state
static func create_quest_state() -> Dictionary:
	return {
		"daily_quests": [],
		"weekly_quests": [],
		"daily_progress": {},
		"weekly_progress": {},
		"challenge_progress": {},
		"completed_challenges": [],
		"last_daily_refresh": 0,
		"last_weekly_refresh": 0
	}


## Serialize quest state for save
static func serialize(quest_state: Dictionary) -> Dictionary:
	return quest_state.duplicate(true)


## Deserialize quest state from save
static func deserialize(data: Dictionary) -> Dictionary:
	var state: Dictionary = create_quest_state()

	if data.has("daily_quests"):
		state["daily_quests"] = data["daily_quests"]
	if data.has("weekly_quests"):
		state["weekly_quests"] = data["weekly_quests"]
	if data.has("daily_progress"):
		state["daily_progress"] = data["daily_progress"]
	if data.has("weekly_progress"):
		state["weekly_progress"] = data["weekly_progress"]
	if data.has("challenge_progress"):
		state["challenge_progress"] = data["challenge_progress"]
	if data.has("completed_challenges"):
		state["completed_challenges"] = data["completed_challenges"]
	if data.has("last_daily_refresh"):
		state["last_daily_refresh"] = int(data["last_daily_refresh"])
	if data.has("last_weekly_refresh"):
		state["last_weekly_refresh"] = int(data["last_weekly_refresh"])

	return state
