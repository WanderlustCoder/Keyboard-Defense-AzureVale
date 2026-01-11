class_name NotificationManager
extends Node
## Notification Manager - Handles game notifications and popups

var toast: NotificationToast
var last_combo_tier: int = 0
var last_wpm: int = 0
var last_accuracy: int = 100
var shown_milestones: Dictionary = {}


func _init() -> void:
	toast = NotificationToast.new()


func _ready() -> void:
	# Position toast at top center
	toast.anchor_left = 0.5
	toast.anchor_right = 0.5
	toast.anchor_top = 0.0
	toast.anchor_bottom = 0.0
	toast.offset_left = -150
	toast.offset_right = 150
	toast.offset_top = 20
	add_child(toast)


## Notify achievement unlocked
func notify_achievement(achievement_name: String, description: String = "") -> void:
	toast.queue_notification("achievement", achievement_name, description)


## Notify level up
func notify_level_up(new_level: int, skill_points: int = 0) -> void:
	var message: String = ""
	if skill_points > 0:
		message = "+%d skill point%s!" % [skill_points, "s" if skill_points > 1 else ""]
	toast.queue_notification("level_up", "Level %d!" % new_level, message)


## Notify milestone reached
func notify_milestone(milestone_name: String, details: String = "") -> void:
	# Avoid duplicate milestone notifications
	if shown_milestones.has(milestone_name):
		return
	shown_milestones[milestone_name] = true
	toast.queue_notification("milestone", milestone_name, details)


## Notify streak
func notify_streak(streak_days: int) -> void:
	var message: String = ""
	if streak_days >= 7:
		message = "Keep it up!"
	elif streak_days >= 3:
		message = "Nice consistency!"
	toast.queue_notification("streak", "%d Day Streak!" % streak_days, message)


## Notify reward received
func notify_reward(reward_type: String, amount: int) -> void:
	toast.queue_notification("reward", "+%d %s" % [amount, reward_type])


## Notify warning
func notify_warning(title: String, message: String = "") -> void:
	toast.queue_notification("warning", title, message)


## Notify info
func notify_info(title: String, message: String = "") -> void:
	toast.queue_notification("info", title, message)


## Notify combo tier change
func notify_combo_tier(tier: int, tier_name: String) -> void:
	if tier > last_combo_tier and tier >= 2:  # Only notify tier 2+
		toast.queue_notification("combo", tier_name + "!", "Combo damage increased")
	last_combo_tier = tier


## Notify combo broken (only for high combos)
func notify_combo_broken(was_combo: int) -> void:
	if was_combo >= 10:
		toast.queue_notification("warning", "Combo Lost!", "%d combo broken" % was_combo)
	last_combo_tier = 0


## Notify new record
func notify_new_record(record_type: String, value: int) -> void:
	var display_name: String = record_type.replace("_", " ").capitalize()
	toast.queue_notification("record", "New Record!", "%s: %d" % [display_name, value])


## Notify loot drop
func notify_loot(item_name: String, is_rare: bool = false) -> void:
	var ntype: String = "loot" if not is_rare else "milestone"
	toast.queue_notification(ntype, "Found: " + item_name)


## Notify material drop
func notify_material(material_name: String, quantity: int = 1) -> void:
	if quantity > 1:
		toast.queue_notification("loot", "+%d %s" % [quantity, material_name])
	else:
		toast.queue_notification("loot", "+" + material_name)


## Check and notify WPM milestone
func check_wpm_milestone(wpm: int) -> void:
	var milestones: Array[int] = [30, 40, 50, 60, 70, 80, 100]
	for m in milestones:
		if wpm >= m and last_wpm < m:
			notify_milestone("%d WPM!" % m, "Typing speed milestone")
			break
	last_wpm = max(last_wpm, wpm)


## Check and notify accuracy milestone
func check_accuracy_milestone(accuracy: int) -> void:
	if accuracy >= 100 and last_accuracy < 100:
		notify_milestone("Perfect Accuracy!", "100% correct")
	elif accuracy >= 95 and last_accuracy < 95:
		notify_milestone("Master Typist!", "95%+ accuracy")
	last_accuracy = accuracy


## Notify quest completed
func notify_quest_complete(quest_name: String, rewards: String = "") -> void:
	toast.queue_notification("reward", "Quest Complete!", quest_name + (("\n" + rewards) if rewards else ""))


## Notify daily challenge complete
func notify_challenge_complete(challenge_name: String, tokens: int = 0) -> void:
	var message: String = ""
	if tokens > 0:
		message = "+%d tokens" % tokens
	toast.queue_notification("achievement", "Challenge Complete!", challenge_name + (("\n" + message) if message else ""))


## Notify endless mode milestone
func notify_endless_milestone(day: int, milestone_name: String) -> void:
	notify_milestone(milestone_name, "Endless Day %d" % day)


## Notify wave complete (only for special waves)
func notify_wave_complete(wave: int, theme_name: String, was_special: bool = false) -> void:
	if was_special:
		toast.queue_notification("info", "Wave %d Complete!" % wave, theme_name)


## Notify boss defeated
func notify_boss_defeated(boss_name: String, gold_reward: int = 0) -> void:
	var message: String = ""
	if gold_reward > 0:
		message = "+%d gold" % gold_reward
	toast.queue_notification("milestone", "Boss Defeated!", boss_name + (("\n" + message) if message else ""))


## Notify day survived
func notify_day_survived(day: int) -> void:
	if day >= 5 and day % 5 == 0:  # Every 5 days
		toast.queue_notification("milestone", "Day %d Survived!" % day)


## Notify skill learned
func notify_skill_learned(skill_name: String) -> void:
	toast.queue_notification("level_up", "Skill Learned!", skill_name)


## Notify item crafted
func notify_item_crafted(item_name: String) -> void:
	toast.queue_notification("info", "Crafted!", item_name)


## Reset session tracking
func reset_session() -> void:
	last_combo_tier = 0
	last_wpm = 0
	last_accuracy = 100
	shown_milestones.clear()


## Clear all notifications
func clear_all() -> void:
	toast.clear_queue()
