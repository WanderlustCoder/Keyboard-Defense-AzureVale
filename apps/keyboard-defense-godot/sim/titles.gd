class_name SimTitles
extends RefCounted

# =============================================================================
# TITLE SYSTEM - Cosmetic rewards for player achievements
# =============================================================================

# Title categories
const CATEGORY_SPEED := "speed"
const CATEGORY_ACCURACY := "accuracy"
const CATEGORY_COMBAT := "combat"
const CATEGORY_DEDICATION := "dedication"
const CATEGORY_MASTERY := "mastery"
const CATEGORY_SPECIAL := "special"

# =============================================================================
# TITLE DEFINITIONS
# =============================================================================

const TITLES: Dictionary = {
	# Speed titles (WPM milestones)
	"novice_typist": {
		"name": "Novice Typist",
		"description": "Reach 20 WPM",
		"category": CATEGORY_SPEED,
		"color": Color(0.7, 0.7, 0.7),
		"unlock": {"type": "wpm", "value": 20}
	},
	"adept_typist": {
		"name": "Adept Typist",
		"description": "Reach 40 WPM",
		"category": CATEGORY_SPEED,
		"color": Color(0.5, 0.8, 0.5),
		"unlock": {"type": "wpm", "value": 40}
	},
	"swift_fingers": {
		"name": "Swift Fingers",
		"description": "Reach 60 WPM",
		"category": CATEGORY_SPEED,
		"color": Color(0.4, 0.7, 1.0),
		"unlock": {"type": "wpm", "value": 60}
	},
	"speed_demon": {
		"name": "Speed Demon",
		"description": "Reach 80 WPM",
		"category": CATEGORY_SPEED,
		"color": Color(1.0, 0.5, 0.2),
		"unlock": {"type": "wpm", "value": 80}
	},
	"lightning_hands": {
		"name": "Lightning Hands",
		"description": "Reach 100 WPM",
		"category": CATEGORY_SPEED,
		"color": Color(1.0, 0.84, 0.0),
		"unlock": {"type": "wpm", "value": 100}
	},
	"keyboard_blur": {
		"name": "Keyboard Blur",
		"description": "Reach 120 WPM",
		"category": CATEGORY_SPEED,
		"color": Color(0.9, 0.3, 1.0),
		"unlock": {"type": "wpm", "value": 120}
	},

	# Accuracy titles
	"careful_scribe": {
		"name": "Careful Scribe",
		"description": "Achieve 90% accuracy in a session",
		"category": CATEGORY_ACCURACY,
		"color": Color(0.5, 0.8, 0.5),
		"unlock": {"type": "accuracy", "value": 0.90}
	},
	"precision_master": {
		"name": "Precision Master",
		"description": "Achieve 95% accuracy in a session",
		"category": CATEGORY_ACCURACY,
		"color": Color(0.4, 0.7, 1.0),
		"unlock": {"type": "accuracy", "value": 0.95}
	},
	"flawless": {
		"name": "Flawless",
		"description": "Achieve 99% accuracy in a session",
		"category": CATEGORY_ACCURACY,
		"color": Color(1.0, 0.84, 0.0),
		"unlock": {"type": "accuracy", "value": 0.99}
	},
	"perfectionist": {
		"name": "Perfectionist",
		"description": "Complete a wave with 100% accuracy",
		"category": CATEGORY_ACCURACY,
		"color": Color(0.9, 0.3, 1.0),
		"unlock": {"type": "achievement", "id": "perfectionist"}
	},

	# Combat titles
	"first_blood": {
		"name": "Blooded",
		"description": "Defeat your first enemy",
		"category": CATEGORY_COMBAT,
		"color": Color(0.8, 0.3, 0.3),
		"unlock": {"type": "achievement", "id": "first_blood"}
	},
	"centurion": {
		"name": "Centurion",
		"description": "Defeat 100 enemies",
		"category": CATEGORY_COMBAT,
		"color": Color(0.7, 0.5, 0.3),
		"unlock": {"type": "kills", "value": 100}
	},
	"slayer": {
		"name": "Slayer",
		"description": "Defeat 1,000 enemies",
		"category": CATEGORY_COMBAT,
		"color": Color(0.8, 0.3, 0.3),
		"unlock": {"type": "kills", "value": 1000}
	},
	"annihilator": {
		"name": "Annihilator",
		"description": "Defeat 5,000 enemies",
		"category": CATEGORY_COMBAT,
		"color": Color(0.6, 0.1, 0.1),
		"unlock": {"type": "kills", "value": 5000}
	},
	"boss_slayer": {
		"name": "Boss Slayer",
		"description": "Defeat your first boss",
		"category": CATEGORY_COMBAT,
		"color": Color(1.0, 0.5, 0.2),
		"unlock": {"type": "achievement", "id": "boss_slayer"}
	},
	"combo_master": {
		"name": "Combo Master",
		"description": "Achieve a 20-combo",
		"category": CATEGORY_COMBAT,
		"color": Color(1.0, 0.6, 0.2),
		"unlock": {"type": "combo", "value": 20}
	},
	"unstoppable": {
		"name": "Unstoppable",
		"description": "Achieve a 50-combo",
		"category": CATEGORY_COMBAT,
		"color": Color(1.0, 0.84, 0.0),
		"unlock": {"type": "combo", "value": 50}
	},

	# Dedication titles (streaks and time)
	"dedicated": {
		"name": "Dedicated",
		"description": "Play for 7 consecutive days",
		"category": CATEGORY_DEDICATION,
		"color": Color(0.5, 0.8, 0.5),
		"unlock": {"type": "streak", "value": 7}
	},
	"committed": {
		"name": "Committed",
		"description": "Play for 30 consecutive days",
		"category": CATEGORY_DEDICATION,
		"color": Color(0.4, 0.7, 1.0),
		"unlock": {"type": "streak", "value": 30}
	},
	"devoted": {
		"name": "Devoted",
		"description": "Play for 100 consecutive days",
		"category": CATEGORY_DEDICATION,
		"color": Color(1.0, 0.84, 0.0),
		"unlock": {"type": "streak", "value": 100}
	},
	"wordsmith": {
		"name": "Wordsmith",
		"description": "Type 10,000 words total",
		"category": CATEGORY_DEDICATION,
		"color": Color(0.8, 0.6, 1.0),
		"unlock": {"type": "words", "value": 10000}
	},
	"literary_legend": {
		"name": "Literary Legend",
		"description": "Type 50,000 words total",
		"category": CATEGORY_DEDICATION,
		"color": Color(0.9, 0.3, 1.0),
		"unlock": {"type": "words", "value": 50000}
	},

	# Mastery titles (lessons and skills)
	"home_row_master": {
		"name": "Home Row Master",
		"description": "Master all home row lessons",
		"category": CATEGORY_MASTERY,
		"color": Color(0.5, 0.8, 0.5),
		"unlock": {"type": "achievement", "id": "home_row_master"}
	},
	"alphabet_scholar": {
		"name": "Alphabet Scholar",
		"description": "Learn all 26 letters",
		"category": CATEGORY_MASTERY,
		"color": Color(0.4, 0.7, 1.0),
		"unlock": {"type": "achievement", "id": "alphabet_scholar"}
	},
	"keyboard_master": {
		"name": "Keyboard Master",
		"description": "Complete all lessons",
		"category": CATEGORY_MASTERY,
		"color": Color(1.0, 0.84, 0.0),
		"unlock": {"type": "achievement", "id": "keyboard_master"}
	},
	"number_cruncher": {
		"name": "Number Cruncher",
		"description": "Master the number row",
		"category": CATEGORY_MASTERY,
		"color": Color(0.4, 0.8, 0.8),
		"unlock": {"type": "achievement", "id": "number_cruncher"}
	},

	# Special titles
	"defender": {
		"name": "Defender",
		"description": "Complete a day without losing health",
		"category": CATEGORY_SPECIAL,
		"color": Color(0.4, 0.7, 0.4),
		"unlock": {"type": "achievement", "id": "defender"}
	},
	"survivor": {
		"name": "Survivor",
		"description": "Win with only 1 HP remaining",
		"category": CATEGORY_SPECIAL,
		"color": Color(0.8, 0.3, 0.3),
		"unlock": {"type": "achievement", "id": "survivor"}
	},
	"void_vanquisher": {
		"name": "Void Vanquisher",
		"description": "Defeat the Void Tyrant",
		"category": CATEGORY_SPECIAL,
		"color": Color(0.5, 0.0, 0.8),
		"unlock": {"type": "achievement", "id": "void_vanquisher"}
	},
	"champion": {
		"name": "Champion of Keystonia",
		"description": "Complete the campaign",
		"category": CATEGORY_SPECIAL,
		"color": Color(1.0, 0.84, 0.0),
		"unlock": {"type": "day", "value": 20}
	}
}

# =============================================================================
# BADGE DEFINITIONS (smaller cosmetic rewards)
# =============================================================================

const BADGES: Dictionary = {
	"early_bird": {
		"name": "Early Bird",
		"description": "Complete 5 sessions before noon",
		"icon": "sun",
		"unlock": {"type": "time_sessions", "hour_before": 12, "count": 5}
	},
	"night_owl": {
		"name": "Night Owl",
		"description": "Complete 5 sessions after midnight",
		"icon": "moon",
		"unlock": {"type": "time_sessions", "hour_after": 0, "hour_before": 6, "count": 5}
	},
	"weekend_warrior": {
		"name": "Weekend Warrior",
		"description": "Play every day for a weekend",
		"icon": "calendar",
		"unlock": {"type": "weekend_streak", "value": 1}
	},
	"consistent": {
		"name": "Consistent",
		"description": "Maintain 80%+ accuracy for 10 sessions",
		"icon": "target",
		"unlock": {"type": "accuracy_streak", "accuracy": 0.8, "sessions": 10}
	},
	"improving": {
		"name": "Improving",
		"description": "Increase WPM by 10 in a week",
		"icon": "arrow_up",
		"unlock": {"type": "wpm_improvement", "value": 10, "days": 7}
	},
	"explorer": {
		"name": "Explorer",
		"description": "Discover 50 map tiles",
		"icon": "compass",
		"unlock": {"type": "tiles_discovered", "value": 50}
	},
	"builder": {
		"name": "Builder",
		"description": "Build 20 structures",
		"icon": "hammer",
		"unlock": {"type": "structures_built", "value": 20}
	},
	"collector": {
		"name": "Collector",
		"description": "Earn 10,000 gold total",
		"icon": "coin",
		"unlock": {"type": "gold_earned", "value": 10000}
	}
}


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================


## Get a title by ID
static func get_title(title_id: String) -> Dictionary:
	return TITLES.get(title_id, {})


## Get a badge by ID
static func get_badge(badge_id: String) -> Dictionary:
	return BADGES.get(badge_id, {})


## Check if a title ID is valid
static func is_valid_title(title_id: String) -> bool:
	return TITLES.has(title_id)


## Check if a badge ID is valid
static func is_valid_badge(badge_id: String) -> bool:
	return BADGES.has(badge_id)


## Get title name
static func get_title_name(title_id: String) -> String:
	var title: Dictionary = get_title(title_id)
	return str(title.get("name", title_id))


## Get title color
static func get_title_color(title_id: String) -> Color:
	var title: Dictionary = get_title(title_id)
	return title.get("color", Color.WHITE)


## Get all title IDs
static func get_all_title_ids() -> Array[String]:
	var ids: Array[String] = []
	for title_id in TITLES.keys():
		ids.append(str(title_id))
	return ids


## Get all badge IDs
static func get_all_badge_ids() -> Array[String]:
	var ids: Array[String] = []
	for badge_id in BADGES.keys():
		ids.append(str(badge_id))
	return ids


## Get titles by category
static func get_titles_by_category(category: String) -> Array[String]:
	var ids: Array[String] = []
	for title_id in TITLES.keys():
		var title: Dictionary = TITLES[title_id]
		if str(title.get("category", "")) == category:
			ids.append(str(title_id))
	return ids


## Get all categories
static func get_categories() -> Array[String]:
	return [
		CATEGORY_SPEED,
		CATEGORY_ACCURACY,
		CATEGORY_COMBAT,
		CATEGORY_DEDICATION,
		CATEGORY_MASTERY,
		CATEGORY_SPECIAL
	]


## Get category display name
static func get_category_name(category: String) -> String:
	match category:
		CATEGORY_SPEED:
			return "Speed"
		CATEGORY_ACCURACY:
			return "Accuracy"
		CATEGORY_COMBAT:
			return "Combat"
		CATEGORY_DEDICATION:
			return "Dedication"
		CATEGORY_MASTERY:
			return "Mastery"
		CATEGORY_SPECIAL:
			return "Special"
		_:
			return category.capitalize()


# =============================================================================
# UNLOCK CHECKING
# =============================================================================


## Check if a title should be unlocked based on player stats
static func check_title_unlock(title_id: String, stats: Dictionary) -> bool:
	var title: Dictionary = get_title(title_id)
	if title.is_empty():
		return false

	var unlock: Dictionary = title.get("unlock", {})
	var unlock_type: String = str(unlock.get("type", ""))

	match unlock_type:
		"wpm":
			var required: int = int(unlock.get("value", 0))
			var current: int = int(stats.get("highest_wpm", 0))
			return current >= required

		"accuracy":
			var required: float = float(unlock.get("value", 0))
			var current: float = float(stats.get("highest_accuracy", 0))
			return current >= required

		"kills":
			var required: int = int(unlock.get("value", 0))
			var current: int = int(stats.get("total_kills", 0))
			return current >= required

		"combo":
			var required: int = int(unlock.get("value", 0))
			var current: int = int(stats.get("highest_combo", 0))
			return current >= required

		"streak":
			var required: int = int(unlock.get("value", 0))
			var current: int = int(stats.get("longest_streak", 0))
			return current >= required

		"words":
			var required: int = int(unlock.get("value", 0))
			var current: int = int(stats.get("total_words_typed", 0))
			return current >= required

		"day":
			var required: int = int(unlock.get("value", 0))
			var current: int = int(stats.get("highest_day", 0))
			return current >= required

		"achievement":
			# Achievement-based unlocks checked separately
			return false

		_:
			return false


## Check all titles against stats and return newly unlockable ones
static func check_all_title_unlocks(stats: Dictionary, already_unlocked: Array) -> Array[String]:
	var newly_unlockable: Array[String] = []

	for title_id in TITLES.keys():
		if str(title_id) in already_unlocked:
			continue
		if check_title_unlock(str(title_id), stats):
			newly_unlockable.append(str(title_id))

	return newly_unlockable


# =============================================================================
# FORMATTING
# =============================================================================


## Format a title for display with color
static func format_title(title_id: String) -> String:
	var title: Dictionary = get_title(title_id)
	if title.is_empty():
		return title_id

	var name: String = str(title.get("name", title_id))
	var color: Color = title.get("color", Color.WHITE)
	return "[color=#%s]%s[/color]" % [color.to_html(false), name]


## Format title list for display
static func format_titles_list(unlocked: Array, equipped: String = "") -> String:
	var lines: Array[String] = []
	lines.append("[color=yellow]TITLES[/color]")
	lines.append("")

	if equipped != "":
		lines.append("Equipped: %s" % format_title(equipped))
		lines.append("")

	for category in get_categories():
		var category_titles: Array[String] = get_titles_by_category(category)
		if category_titles.is_empty():
			continue

		lines.append("[color=orange]%s[/color]" % get_category_name(category))
		for title_id in category_titles:
			var title: Dictionary = get_title(title_id)
			var is_unlocked: bool = title_id in unlocked
			var marker: String = " *" if title_id == equipped else ""

			if is_unlocked:
				lines.append("  %s%s" % [format_title(title_id), marker])
			else:
				var desc: String = str(title.get("description", ""))
				lines.append("  [color=gray]??? - %s[/color]" % desc)
		lines.append("")

	lines.append("[color=gray]Type 'title <name>' to equip a title.[/color]")
	return "\n".join(lines)


## Format badges list for display
static func format_badges_list(unlocked: Array) -> String:
	var lines: Array[String] = []
	lines.append("[color=yellow]BADGES[/color]")
	lines.append("")

	for badge_id in BADGES.keys():
		var badge: Dictionary = BADGES[badge_id]
		var name: String = str(badge.get("name", badge_id))
		var desc: String = str(badge.get("description", ""))
		var is_unlocked: bool = badge_id in unlocked

		if is_unlocked:
			lines.append("  [color=lime]%s[/color] - %s" % [name, desc])
		else:
			lines.append("  [color=gray]??? - %s[/color]" % desc)

	return "\n".join(lines)
