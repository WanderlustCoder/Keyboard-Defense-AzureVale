class_name SimMilestones
extends RefCounted
## Milestone tracking - Celebrates player achievements and personal records

## WPM milestone thresholds
const WPM_MILESTONES: Array[int] = [20, 30, 40, 50, 60, 70, 80, 90, 100, 120, 150]

## Accuracy milestone thresholds (percentage)
const ACCURACY_MILESTONES: Array[float] = [80.0, 85.0, 90.0, 95.0, 98.0, 99.0, 100.0]

## Combo milestone thresholds
const COMBO_MILESTONES: Array[int] = [5, 10, 15, 20, 25, 30, 40, 50, 75, 100]

## Kill count milestones (cumulative)
const KILL_MILESTONES: Array[int] = [50, 100, 250, 500, 1000, 2500, 5000, 10000]

## Word count milestones (cumulative)
const WORD_MILESTONES: Array[int] = [100, 500, 1000, 2500, 5000, 10000, 25000, 50000]

## Streak milestones
const STREAK_MILESTONES: Array[int] = [3, 7, 14, 21, 30, 60, 90, 180, 365]

## Milestone categories
enum Category {
	WPM,
	ACCURACY,
	COMBO,
	KILLS,
	WORDS,
	STREAK
}

## Milestone messages by category
const MILESTONE_MESSAGES: Dictionary = {
	Category.WPM: {
		20: "First Steps! 20 WPM reached!",
		30: "Getting Faster! 30 WPM!",
		40: "Solid Speed! 40 WPM achieved!",
		50: "Professional Speed! 50 WPM!",
		60: "Expert Typist! 60 WPM!",
		70: "Speed Demon! 70 WPM!",
		80: "Blazing Fast! 80 WPM!",
		90: "Incredible! 90 WPM!",
		100: "Century Club! 100 WPM!",
		120: "Superhuman! 120 WPM!",
		150: "Legendary! 150 WPM!"
	},
	Category.ACCURACY: {
		80.0: "Solid Accuracy! 80%+",
		85.0: "Sharp Shooter! 85%+",
		90.0: "Precision Master! 90%+",
		95.0: "Near Perfect! 95%+",
		98.0: "Surgical Precision! 98%+",
		99.0: "Almost Flawless! 99%+",
		100.0: "PERFECT! 100% Accuracy!"
	},
	Category.COMBO: {
		5: "Combo Started! 5 streak!",
		10: "Double Digits! 10 combo!",
		15: "On Fire! 15 combo!",
		20: "Unstoppable! 20 combo!",
		25: "Dominating! 25 combo!",
		30: "Legendary Streak! 30 combo!",
		40: "Godlike! 40 combo!",
		50: "Impossible! 50 combo!",
		75: "Mythical! 75 combo!",
		100: "IMMORTAL! 100 combo!"
	},
	Category.KILLS: {
		50: "First Blood! 50 enemies slain!",
		100: "Centurion! 100 enemies!",
		250: "Warrior! 250 enemies!",
		500: "Champion! 500 enemies!",
		1000: "Slayer! 1,000 enemies!",
		2500: "Destroyer! 2,500 enemies!",
		5000: "Annihilator! 5,000 enemies!",
		10000: "LEGEND! 10,000 enemies!"
	},
	Category.WORDS: {
		100: "Scribe! 100 words typed!",
		500: "Writer! 500 words!",
		1000: "Author! 1,000 words!",
		2500: "Novelist! 2,500 words!",
		5000: "Master Scribe! 5,000 words!",
		10000: "Wordsmith! 10,000 words!",
		25000: "Literary Master! 25,000 words!",
		50000: "LEGEND OF WORDS! 50,000!"
	},
	Category.STREAK: {
		3: "Three-Day Streak!",
		7: "Weekly Warrior! 7 days!",
		14: "Two Week Champion!",
		21: "Three Week Hero!",
		30: "Monthly Master! 30 days!",
		60: "Two Month Titan!",
		90: "Quarterly Champion!",
		180: "Half Year Hero!",
		365: "YEAR OF MASTERY!"
	}
}


## Check if a new WPM milestone was reached
static func check_wpm_milestone(current_wpm: int, previous_best: int) -> Dictionary:
	if current_wpm <= previous_best:
		return {}

	for milestone in WPM_MILESTONES:
		if current_wpm >= milestone and previous_best < milestone:
			return {
				"category": Category.WPM,
				"value": milestone,
				"message": MILESTONE_MESSAGES[Category.WPM].get(milestone, "WPM Milestone!"),
				"is_personal_best": current_wpm > previous_best
			}

	# Personal best but no milestone
	if current_wpm > previous_best:
		return {
			"category": Category.WPM,
			"value": current_wpm,
			"message": "New Personal Best! %d WPM!" % current_wpm,
			"is_personal_best": true
		}

	return {}


## Check if a new accuracy milestone was reached
static func check_accuracy_milestone(current_accuracy: float, previous_best: float) -> Dictionary:
	if current_accuracy <= previous_best:
		return {}

	var current_percent: float = current_accuracy * 100.0
	var prev_percent: float = previous_best * 100.0

	for milestone in ACCURACY_MILESTONES:
		if current_percent >= milestone and prev_percent < milestone:
			return {
				"category": Category.ACCURACY,
				"value": milestone,
				"message": MILESTONE_MESSAGES[Category.ACCURACY].get(milestone, "Accuracy Milestone!"),
				"is_personal_best": current_accuracy > previous_best
			}

	return {}


## Check if a new combo milestone was reached
static func check_combo_milestone(current_combo: int, previous_best: int) -> Dictionary:
	if current_combo <= previous_best:
		return {}

	for milestone in COMBO_MILESTONES:
		if current_combo >= milestone and previous_best < milestone:
			return {
				"category": Category.COMBO,
				"value": milestone,
				"message": MILESTONE_MESSAGES[Category.COMBO].get(milestone, "Combo Milestone!"),
				"is_personal_best": current_combo > previous_best
			}

	# Personal best but no milestone
	if current_combo > previous_best:
		return {
			"category": Category.COMBO,
			"value": current_combo,
			"message": "New Combo Record! %d streak!" % current_combo,
			"is_personal_best": true
		}

	return {}


## Check if a cumulative kill milestone was reached
static func check_kill_milestone(total_kills: int, previous_total: int) -> Dictionary:
	for milestone in KILL_MILESTONES:
		if total_kills >= milestone and previous_total < milestone:
			return {
				"category": Category.KILLS,
				"value": milestone,
				"message": MILESTONE_MESSAGES[Category.KILLS].get(milestone, "Kill Milestone!"),
				"is_personal_best": false  # Cumulative milestones are not "personal bests"
			}
	return {}


## Check if a cumulative word milestone was reached
static func check_word_milestone(total_words: int, previous_total: int) -> Dictionary:
	for milestone in WORD_MILESTONES:
		if total_words >= milestone and previous_total < milestone:
			return {
				"category": Category.WORDS,
				"value": milestone,
				"message": MILESTONE_MESSAGES[Category.WORDS].get(milestone, "Word Milestone!"),
				"is_personal_best": false
			}
	return {}


## Check if a streak milestone was reached
static func check_streak_milestone(current_streak: int, previous_streak: int) -> Dictionary:
	for milestone in STREAK_MILESTONES:
		if current_streak >= milestone and previous_streak < milestone:
			return {
				"category": Category.STREAK,
				"value": milestone,
				"message": MILESTONE_MESSAGES[Category.STREAK].get(milestone, "Streak Milestone!"),
				"is_personal_best": current_streak > previous_streak
			}
	return {}


## Get the next milestone for a given category and current value
static func get_next_milestone(category: Category, current_value) -> Dictionary:
	var milestones: Array = []

	match category:
		Category.WPM:
			milestones = WPM_MILESTONES
		Category.ACCURACY:
			milestones = ACCURACY_MILESTONES
		Category.COMBO:
			milestones = COMBO_MILESTONES
		Category.KILLS:
			milestones = KILL_MILESTONES
		Category.WORDS:
			milestones = WORD_MILESTONES
		Category.STREAK:
			milestones = STREAK_MILESTONES

	for milestone in milestones:
		if milestone > current_value:
			return {
				"next": milestone,
				"progress": float(current_value) / float(milestone),
				"remaining": milestone - current_value
			}

	return {"next": -1, "progress": 1.0, "remaining": 0}  # All milestones achieved


## Get color for milestone category
static func get_category_color(category: Category) -> Color:
	match category:
		Category.WPM:
			return Color(0.4, 0.8, 1.0)  # Cyan
		Category.ACCURACY:
			return Color(0.4, 1.0, 0.4)  # Green
		Category.COMBO:
			return Color(1.0, 0.6, 0.2)  # Orange
		Category.KILLS:
			return Color(1.0, 0.4, 0.4)  # Red
		Category.WORDS:
			return Color(0.8, 0.6, 1.0)  # Purple
		Category.STREAK:
			return Color(1.0, 0.84, 0.0)  # Gold
		_:
			return Color.WHITE


## Format milestone for display
static func format_milestone(milestone: Dictionary) -> String:
	if milestone.is_empty():
		return ""

	var message: String = str(milestone.get("message", "Milestone!"))
	var is_pb: bool = bool(milestone.get("is_personal_best", false))

	if is_pb:
		return "[color=#ffd700]%s[/color]" % message
	else:
		return message
