class_name StoryManager
extends RefCounted

## Story Manager - Tracks narrative progression through "The Siege of Keystonia"
## Provides act/boss information, dialogue triggers, and mentor messages

const STORY_PATH := "res://data/story.json"

static var _cache: Dictionary = {}

static func load_data() -> Dictionary:
	if not _cache.is_empty():
		return _cache
	if not FileAccess.file_exists(STORY_PATH):
		_cache = {"ok": false, "error": "Story file not found.", "data": {}}
		return _cache
	var file: FileAccess = FileAccess.open(STORY_PATH, FileAccess.READ)
	if file == null:
		_cache = {"ok": false, "error": "Story load failed.", "data": {}}
		return _cache
	var text: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		_cache = {"ok": false, "error": "Story file is invalid JSON.", "data": {}}
		return _cache
	_cache = {"ok": true, "error": "", "data": parsed}
	return _cache

static func get_acts() -> Array:
	var data: Dictionary = load_data()
	if not data.get("ok", false):
		return []
	return data.get("data", {}).get("acts", [])

static func get_act_for_day(day: int) -> Dictionary:
	var acts: Array = get_acts()
	for act in acts:
		var days: Array = act.get("days", [0, 0])
		if days.size() >= 2:
			var start: int = int(days[0])
			var end: int = int(days[1])
			if day >= start and day <= end:
				return act
	# Default to last act if day exceeds all
	if not acts.is_empty():
		return acts[acts.size() - 1]
	return {}

static func get_act_by_id(act_id: String) -> Dictionary:
	var acts: Array = get_acts()
	for act in acts:
		if str(act.get("id", "")) == act_id:
			return act
	return {}

static func is_boss_day(day: int) -> bool:
	var act: Dictionary = get_act_for_day(day)
	if act.is_empty():
		return false
	var boss: Dictionary = act.get("boss", {})
	return int(boss.get("day", -1)) == day

static func get_boss_for_day(day: int) -> Dictionary:
	var act: Dictionary = get_act_for_day(day)
	if act.is_empty():
		return {}
	var boss: Dictionary = act.get("boss", {})
	if int(boss.get("day", -1)) == day:
		return boss
	return {}

## Check if an enemy kind is a boss kind
static func is_boss_kind(kind: String) -> bool:
	var acts: Array = get_acts()
	for act in acts:
		var boss: Dictionary = act.get("boss", {})
		if str(boss.get("kind", "")) == kind:
			return true
	return false

## Get the list of all boss kinds
static func get_all_boss_kinds() -> Array[String]:
	var kinds: Array[String] = []
	var acts: Array = get_acts()
	for act in acts:
		var boss: Dictionary = act.get("boss", {})
		var boss_kind: String = str(boss.get("kind", ""))
		if not boss_kind.is_empty() and not kinds.has(boss_kind):
			kinds.append(boss_kind)
	return kinds

static func get_current_act_number(day: int) -> int:
	var acts: Array = get_acts()
	for i in range(acts.size()):
		var act: Dictionary = acts[i]
		var days: Array = act.get("days", [0, 0])
		if days.size() >= 2:
			var start: int = int(days[0])
			var end: int = int(days[1])
			if day >= start and day <= end:
				return i + 1
	return acts.size()

static func get_act_progress(day: int) -> Dictionary:
	var act: Dictionary = get_act_for_day(day)
	if act.is_empty():
		return {"act_name": "Unknown", "day_in_act": 1, "total_days": 1, "act_number": 1}
	var days: Array = act.get("days", [1, 1])
	var start: int = int(days[0]) if days.size() >= 1 else 1
	var end: int = int(days[1]) if days.size() >= 2 else start
	var day_in_act: int = day - start + 1
	var total_days: int = end - start + 1
	return {
		"act_name": str(act.get("name", "Unknown")),
		"act_id": str(act.get("id", "")),
		"day_in_act": day_in_act,
		"total_days": total_days,
		"act_number": get_current_act_number(day)
	}

static func get_dialogue(dialogue_key: String) -> Dictionary:
	var data: Dictionary = load_data()
	if not data.get("ok", false):
		return {}
	var dialogue_map: Dictionary = data.get("data", {}).get("dialogue", {})
	if dialogue_map.has(dialogue_key):
		return dialogue_map[dialogue_key]
	return {}

static func get_dialogue_lines(dialogue_key: String, substitutions: Dictionary = {}) -> Array[String]:
	var dialogue: Dictionary = get_dialogue(dialogue_key)
	var raw_lines: Array = dialogue.get("lines", [])
	var result: Array[String] = []
	for line in raw_lines:
		var processed: String = str(line)
		for key in substitutions.keys():
			processed = processed.replace("{%s}" % key, str(substitutions[key]))
		result.append(processed)
	return result

static func get_dialogue_speaker(dialogue_key: String) -> String:
	var dialogue: Dictionary = get_dialogue(dialogue_key)
	return str(dialogue.get("speaker", ""))

static func get_hint_for_theme(theme: String) -> String:
	var data: Dictionary = load_data()
	if not data.get("ok", false):
		return ""
	var hints: Dictionary = data.get("data", {}).get("dialogue", {}).get("hints", {})
	return str(hints.get(theme, ""))

static func get_enemy_taunt(enemy_kind: String) -> String:
	var data: Dictionary = load_data()
	if not data.get("ok", false):
		return ""
	var taunts: Dictionary = data.get("data", {}).get("enemy_taunts", {})
	var kind_taunts: Array = taunts.get(enemy_kind, [])
	if kind_taunts.is_empty():
		# Fall back to generic taunts
		kind_taunts = taunts.get("raider", ["..."])
	if kind_taunts.is_empty():
		return ""
	return str(kind_taunts[randi() % kind_taunts.size()])

static func should_show_act_intro(day: int, last_intro_day: int) -> bool:
	var act: Dictionary = get_act_for_day(day)
	if act.is_empty():
		return false
	var days: Array = act.get("days", [0, 0])
	var start: int = int(days[0]) if days.size() >= 1 else 0
	# Show intro on first day of act if we haven't shown it yet
	return day == start and last_intro_day < start

static func get_act_intro_text(day: int) -> String:
	var act: Dictionary = get_act_for_day(day)
	if act.is_empty():
		return ""
	return str(act.get("intro_text", ""))

static func get_act_completion_text(day: int) -> String:
	var act: Dictionary = get_act_for_day(day)
	if act.is_empty():
		return ""
	return str(act.get("completion_text", ""))

static func get_mentor_name(day: int) -> String:
	var act: Dictionary = get_act_for_day(day)
	if act.is_empty():
		return "Elder Lyra"
	var mentor: Dictionary = act.get("mentor", {})
	return str(mentor.get("name", "Elder Lyra"))

# Lesson introduction functions
static func get_lesson_intro(lesson_id: String) -> Dictionary:
	var data: Dictionary = load_data()
	if not data.get("ok", false):
		return {}
	var intros: Dictionary = data.get("data", {}).get("lesson_introductions", {})
	return intros.get(lesson_id, {})

static func get_lesson_intro_lines(lesson_id: String) -> Array[String]:
	var intro: Dictionary = get_lesson_intro(lesson_id)
	var raw_lines: Array = intro.get("lines", [])
	var result: Array[String] = []
	for line in raw_lines:
		result.append(str(line))
	return result

static func get_lesson_finger_guide(lesson_id: String) -> Dictionary:
	var intro: Dictionary = get_lesson_intro(lesson_id)
	return intro.get("finger_guide", {})

static func get_lesson_title(lesson_id: String) -> String:
	var intro: Dictionary = get_lesson_intro(lesson_id)
	return str(intro.get("title", ""))

# Typing tips functions
static func get_typing_tips(category: String) -> Array[String]:
	var data: Dictionary = load_data()
	if not data.get("ok", false):
		return []
	var tips: Dictionary = data.get("data", {}).get("typing_tips", {})
	var raw_tips: Array = tips.get(category, [])
	var result: Array[String] = []
	for tip in raw_tips:
		result.append(str(tip))
	return result

static func get_random_typing_tip(category: String = "") -> String:
	var data: Dictionary = load_data()
	if not data.get("ok", false):
		return ""
	var tips: Dictionary = data.get("data", {}).get("typing_tips", {})

	var all_tips: Array[String] = []
	if category.is_empty():
		# Get tips from all categories
		for cat in tips.keys():
			var cat_tips: Array = tips.get(cat, [])
			for tip in cat_tips:
				all_tips.append(str(tip))
	else:
		var cat_tips: Array = tips.get(category, [])
		for tip in cat_tips:
			all_tips.append(str(tip))

	if all_tips.is_empty():
		return ""
	return all_tips[randi() % all_tips.size()]

# Performance feedback functions
static func get_accuracy_feedback(accuracy_percent: float) -> String:
	var data: Dictionary = load_data()
	if not data.get("ok", false):
		return ""
	var feedback: Dictionary = data.get("data", {}).get("performance_feedback", {}).get("accuracy", {})

	var levels: Array[String] = ["excellent", "good", "needs_work", "struggling"]
	for level in levels:
		var level_data: Dictionary = feedback.get(level, {})
		var threshold: float = float(level_data.get("threshold", 0))
		if accuracy_percent >= threshold:
			var messages: Array = level_data.get("messages", [])
			if not messages.is_empty():
				return str(messages[randi() % messages.size()])
			break
	return ""

static func get_speed_feedback(wpm: float) -> String:
	var data: Dictionary = load_data()
	if not data.get("ok", false):
		return ""
	var feedback: Dictionary = data.get("data", {}).get("performance_feedback", {}).get("speed", {})

	var levels: Array[String] = ["blazing", "fast", "good", "moderate", "learning"]
	for level in levels:
		var level_data: Dictionary = feedback.get(level, {})
		var threshold: float = float(level_data.get("threshold", 0))
		if wpm >= threshold:
			var messages: Array = level_data.get("messages", [])
			if not messages.is_empty():
				return str(messages[randi() % messages.size()])
			break
	return ""

static func get_combo_feedback(combo: int) -> String:
	var data: Dictionary = load_data()
	if not data.get("ok", false):
		return ""
	var feedback: Dictionary = data.get("data", {}).get("performance_feedback", {}).get("combo", {})

	var levels: Array[String] = ["legendary", "amazing", "great", "building"]
	for level in levels:
		var level_data: Dictionary = feedback.get(level, {})
		var threshold: int = int(level_data.get("threshold", 0))
		if combo >= threshold:
			var messages: Array = level_data.get("messages", [])
			if not messages.is_empty():
				return str(messages[randi() % messages.size()])
			break
	return ""

# Encouragement functions
static func get_streak_broken_message() -> String:
	var data: Dictionary = load_data()
	if not data.get("ok", false):
		return ""
	var messages: Array = data.get("data", {}).get("encouragement", {}).get("streak_broken", [])
	if messages.is_empty():
		return ""
	return str(messages[randi() % messages.size()])

static func get_wpm_milestone_message(wpm: int) -> String:
	var data: Dictionary = load_data()
	if not data.get("ok", false):
		return ""
	var milestones: Dictionary = data.get("data", {}).get("encouragement", {}).get("milestone_wpm", {})

	# Find highest milestone reached
	var milestone_values: Array[int] = [100, 80, 70, 60, 50, 40, 30, 20]
	for m in milestone_values:
		if wpm >= m:
			var key: String = str(m)
			if milestones.has(key):
				return str(milestones[key])
			break
	return ""

# Finger assignment lookup
static func get_finger_for_key(key: String) -> String:
	var data: Dictionary = load_data()
	if not data.get("ok", false):
		return ""
	var assignments: Dictionary = data.get("data", {}).get("finger_assignments", {})

	var lower_key: String = key.to_lower()
	for finger_id in assignments.keys():
		var finger_data: Dictionary = assignments[finger_id]
		var keys: Array = finger_data.get("keys", [])
		if keys.has(lower_key):
			return str(finger_data.get("name", ""))
	return ""

static func get_finger_color_for_key(key: String) -> String:
	var data: Dictionary = load_data()
	if not data.get("ok", false):
		return ""
	var assignments: Dictionary = data.get("data", {}).get("finger_assignments", {})

	var lower_key: String = key.to_lower()
	for finger_id in assignments.keys():
		var finger_data: Dictionary = assignments[finger_id]
		var keys: Array = finger_data.get("keys", [])
		if keys.has(lower_key):
			return str(finger_data.get("color", "#FFFFFF"))
	return "#FFFFFF"

# Lesson practice tips
static func get_lesson_practice_tips(lesson_id: String) -> Array[String]:
	var intro: Dictionary = get_lesson_intro(lesson_id)
	var raw_tips: Array = intro.get("practice_tips", [])
	var result: Array[String] = []
	for tip in raw_tips:
		result.append(str(tip))
	return result

static func get_random_lesson_tip(lesson_id: String) -> String:
	var tips: Array[String] = get_lesson_practice_tips(lesson_id)
	if tips.is_empty():
		return get_random_typing_tip()
	return tips[randi() % tips.size()]

# Lore functions
static func get_lore(lore_type: String) -> Dictionary:
	var data: Dictionary = load_data()
	if not data.get("ok", false):
		return {}
	var lore: Dictionary = data.get("data", {}).get("lore", {})
	return lore.get(lore_type, {})

static func get_kingdom_lore() -> Dictionary:
	return get_lore("kingdom")

static func get_horde_lore() -> Dictionary:
	return get_lore("typhos_horde")

static func get_character_info(character_id: String) -> Dictionary:
	var data: Dictionary = load_data()
	if not data.get("ok", false):
		return {}
	var characters: Dictionary = data.get("data", {}).get("lore", {}).get("characters", {})
	return characters.get(character_id, {})

static func get_character_quote(character_id: String) -> String:
	var info: Dictionary = get_character_info(character_id)
	var quotes: Array = info.get("quotes", [])
	if quotes.is_empty():
		return ""
	return str(quotes[randi() % quotes.size()])

static func get_mentor_quote() -> String:
	return get_character_quote("elder_lyra")

# Achievement functions
static func get_achievement(achievement_id: String) -> Dictionary:
	var data: Dictionary = load_data()
	if not data.get("ok", false):
		return {}
	var achievements: Dictionary = data.get("data", {}).get("achievements", {})
	return achievements.get(achievement_id, {})

static func get_achievement_name(achievement_id: String) -> String:
	var achievement: Dictionary = get_achievement(achievement_id)
	return str(achievement.get("name", ""))

static func get_achievement_description(achievement_id: String) -> String:
	var achievement: Dictionary = get_achievement(achievement_id)
	return str(achievement.get("description", ""))

# Comeback and encouragement
static func get_comeback_message() -> String:
	var data: Dictionary = load_data()
	if not data.get("ok", false):
		return ""
	var messages: Array = data.get("data", {}).get("encouragement", {}).get("comeback", [])
	if messages.is_empty():
		return ""
	return str(messages[randi() % messages.size()])

static func get_daily_streak_message(days: int) -> String:
	var data: Dictionary = load_data()
	if not data.get("ok", false):
		return ""
	var streaks: Dictionary = data.get("data", {}).get("encouragement", {}).get("daily_streak", {})

	var streak_thresholds: Array[int] = [100, 30, 14, 7, 3]
	for threshold in streak_thresholds:
		if days >= threshold:
			var key: String = str(threshold)
			if streaks.has(key):
				return str(streaks[key])
			break
	return ""

static func get_combo_milestone_message(combo: int) -> String:
	var data: Dictionary = load_data()
	if not data.get("ok", false):
		return ""
	var milestones: Dictionary = data.get("data", {}).get("encouragement", {}).get("milestone_combo", {})

	var combo_thresholds: Array[int] = [50, 30, 20, 10]
	for threshold in combo_thresholds:
		if combo >= threshold:
			var key: String = str(threshold)
			if milestones.has(key):
				return str(milestones[key])
			break
	return ""

static func get_accuracy_milestone_message(accuracy: int) -> String:
	var data: Dictionary = load_data()
	if not data.get("ok", false):
		return ""
	var milestones: Dictionary = data.get("data", {}).get("encouragement", {}).get("milestone_accuracy", {})

	var thresholds: Array[int] = [100, 98, 95]
	for threshold in thresholds:
		if accuracy >= threshold:
			var key: String = str(threshold)
			if milestones.has(key):
				return str(milestones[key])
			break
	return ""

# Act reward
static func get_act_reward(day: int) -> String:
	var act: Dictionary = get_act_for_day(day)
	if act.is_empty():
		return ""
	return str(act.get("reward", ""))

# Boss lore
static func get_boss_lore(day: int) -> String:
	var boss: Dictionary = get_boss_for_day(day)
	if boss.is_empty():
		return ""
	return str(boss.get("lore", ""))

static func get_contextual_tip(context: String) -> String:
	# Map contexts to tip categories
	var category_map: Dictionary = {
		"error": "errors",
		"slow": "rhythm",
		"tired": "posture",
		"start": "warm_up",
		"home_row": "home_row",
		"speed": "advanced",
		"accuracy": "technique",
		"mental": "mental",
		"practice": "practice",
		"stuck": "troubleshooting"
	}

	var category: String = category_map.get(context, "")
	return get_random_typing_tip(category)

# Lore access
static func get_all_lore() -> Dictionary:
	var data: Dictionary = load_data()
	if not data.get("ok", false):
		return {}
	return data.get("data", {}).get("lore", {})

# Act completion functions
static func is_act_complete_day(day: int) -> bool:
	## Check if the given day is the last day of an act
	var acts: Array = get_acts()
	for act in acts:
		var days: Array = act.get("days", [])
		if days.size() >= 2 and int(days[1]) == day:
			return true
	return false

static func get_act_completion_info(day: int) -> Dictionary:
	## Get act completion info if this day completes an act
	var acts: Array = get_acts()
	for act in acts:
		var days: Array = act.get("days", [])
		if days.size() >= 2 and int(days[1]) == day:
			return {
				"act_id": str(act.get("id", "")),
				"act_name": str(act.get("name", "")),
				"completion_text": str(act.get("completion_text", "")),
				"reward": str(act.get("reward", ""))
			}
	return {}

static func get_act_reward_id(reward_name: String) -> String:
	## Convert reward name to an ID for storage
	return reward_name.to_lower().replace(" ", "_")
