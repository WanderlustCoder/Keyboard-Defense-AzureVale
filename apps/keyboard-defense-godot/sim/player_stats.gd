class_name SimPlayerStats
extends RefCounted
## Player Statistics System - Tracks lifetime and session performance metrics

# Stat keys
const STATS: Dictionary = {
	# Combat stats
	"total_kills": {"name": "Total Kills", "category": "combat"},
	"total_boss_kills": {"name": "Boss Kills", "category": "combat"},
	"total_damage_dealt": {"name": "Damage Dealt", "category": "combat"},
	"total_damage_taken": {"name": "Damage Taken", "category": "combat"},
	"total_deaths": {"name": "Deaths", "category": "combat"},

	# Typing stats
	"total_words_typed": {"name": "Words Typed", "category": "typing"},
	"total_chars_typed": {"name": "Characters Typed", "category": "typing"},
	"total_typos": {"name": "Typos Made", "category": "typing"},
	"perfect_words": {"name": "Perfect Words", "category": "typing"},

	# Economy stats
	"total_gold_earned": {"name": "Gold Earned", "category": "economy"},
	"total_gold_spent": {"name": "Gold Spent", "category": "economy"},
	"items_purchased": {"name": "Items Purchased", "category": "economy"},
	"items_dropped": {"name": "Items Dropped", "category": "economy"},

	# Progression stats
	"days_survived": {"name": "Days Survived", "category": "progression"},
	"waves_completed": {"name": "Waves Completed", "category": "progression"},
	"quests_completed": {"name": "Quests Completed", "category": "progression"},
	"challenges_completed": {"name": "Challenges Completed", "category": "progression"},
	"achievements_unlocked": {"name": "Achievements Unlocked", "category": "progression"},

	# Time stats
	"total_play_time": {"name": "Play Time (minutes)", "category": "time"},
	"sessions_played": {"name": "Sessions Played", "category": "time"},

	# Combo stats
	"total_combos_started": {"name": "Combos Started", "category": "combo"},
	"total_combos_broken": {"name": "Combos Broken", "category": "combo"},
	"combo_words_typed": {"name": "Words in Combos", "category": "combo"}
}

# Record keys (highest values)
const RECORDS: Dictionary = {
	"highest_combo": {"name": "Highest Combo", "category": "records"},
	"highest_day": {"name": "Highest Day Reached", "category": "records"},
	"most_kills_wave": {"name": "Most Kills in a Wave", "category": "records"},
	"most_gold_wave": {"name": "Most Gold in a Wave", "category": "records"},
	"fastest_wave_time": {"name": "Fastest Wave (seconds)", "category": "records", "lower_is_better": true},
	"highest_accuracy": {"name": "Highest Accuracy (%)", "category": "records"},
	"longest_streak": {"name": "Longest Daily Streak", "category": "records"},
	"highest_wpm": {"name": "Highest WPM", "category": "records"},
	"endless_highest_day": {"name": "Endless Mode High Day", "category": "records"}
}


## Initialize stats for a new profile
static func init_stats() -> Dictionary:
	var stats: Dictionary = {}
	for key in STATS.keys():
		stats[key] = 0
	for key in RECORDS.keys():
		if bool(RECORDS[key].get("lower_is_better", false)):
			stats[key] = 999999
		else:
			stats[key] = 0
	stats["first_played"] = Time.get_unix_time_from_system()
	stats["last_played"] = Time.get_unix_time_from_system()
	return stats


## Get stats from profile
static func get_stats(profile: Dictionary) -> Dictionary:
	var stats: Dictionary = TypingProfile.get_profile_value(profile, "player_stats", {})
	if stats.is_empty():
		stats = init_stats()
	return stats


## Save stats to profile
static func save_stats(profile: Dictionary, stats: Dictionary) -> void:
	stats["last_played"] = Time.get_unix_time_from_system()
	TypingProfile.set_profile_value(profile, "player_stats", stats)


## Increment a stat
static func increment_stat(profile: Dictionary, stat_key: String, amount: int = 1) -> void:
	var stats: Dictionary = get_stats(profile)
	stats[stat_key] = int(stats.get(stat_key, 0)) + amount
	save_stats(profile, stats)


## Update a record (highest value)
static func update_record(profile: Dictionary, record_key: String, value: int) -> bool:
	var stats: Dictionary = get_stats(profile)
	var lower_is_better: bool = bool(RECORDS.get(record_key, {}).get("lower_is_better", false))

	var current: int = int(stats.get(record_key, 999999 if lower_is_better else 0))
	var is_new_record: bool = false

	if lower_is_better:
		if value < current and value > 0:
			stats[record_key] = value
			is_new_record = true
	else:
		if value > current:
			stats[record_key] = value
			is_new_record = true

	if is_new_record:
		save_stats(profile, stats)

	return is_new_record


## Get a specific stat value
static func get_stat(profile: Dictionary, stat_key: String) -> int:
	var stats: Dictionary = get_stats(profile)
	return int(stats.get(stat_key, 0))


## Get a specific record value
static func get_record(profile: Dictionary, record_key: String) -> int:
	var stats: Dictionary = get_stats(profile)
	var lower_is_better: bool = bool(RECORDS.get(record_key, {}).get("lower_is_better", false))
	return int(stats.get(record_key, 999999 if lower_is_better else 0))


## Get a specific record value as float (for accuracy, etc.)
static func get_record_float(profile: Dictionary, record_key: String) -> float:
	var stats: Dictionary = get_stats(profile)
	var lower_is_better: bool = bool(RECORDS.get(record_key, {}).get("lower_is_better", false))
	return float(stats.get(record_key, 999999.0 if lower_is_better else 0.0))


## Calculate derived stats
static func calculate_derived_stats(profile: Dictionary) -> Dictionary:
	var stats: Dictionary = get_stats(profile)
	var derived: Dictionary = {}

	# Accuracy
	var total_chars: int = int(stats.get("total_chars_typed", 0))
	var typos: int = int(stats.get("total_typos", 0))
	if total_chars > 0:
		derived["overall_accuracy"] = float(total_chars - typos) / float(total_chars) * 100.0
	else:
		derived["overall_accuracy"] = 100.0

	# K/D ratio
	var kills: int = int(stats.get("total_kills", 0))
	var deaths: int = int(stats.get("total_deaths", 0))
	if deaths > 0:
		derived["kd_ratio"] = float(kills) / float(deaths)
	else:
		derived["kd_ratio"] = float(kills)

	# Combo efficiency
	var combos_started: int = int(stats.get("total_combos_started", 0))
	var combos_broken: int = int(stats.get("total_combos_broken", 0))
	if combos_started > 0:
		derived["combo_efficiency"] = float(combos_started - combos_broken) / float(combos_started) * 100.0
	else:
		derived["combo_efficiency"] = 100.0

	# Average words per session
	var sessions: int = int(stats.get("sessions_played", 1))
	var words: int = int(stats.get("total_words_typed", 0))
	derived["avg_words_per_session"] = float(words) / float(max(1, sessions))

	# Average gold per wave
	var waves: int = int(stats.get("waves_completed", 1))
	var gold: int = int(stats.get("total_gold_earned", 0))
	derived["avg_gold_per_wave"] = float(gold) / float(max(1, waves))

	# Average kills per wave
	derived["avg_kills_per_wave"] = float(kills) / float(max(1, waves))

	# Play time in hours
	var minutes: int = int(stats.get("total_play_time", 0))
	derived["play_time_hours"] = float(minutes) / 60.0

	return derived


## Format stats by category for display
static func format_stats_by_category(profile: Dictionary, category: String) -> String:
	var stats: Dictionary = get_stats(profile)
	var lines: Array[String] = []

	for stat_key in STATS.keys():
		var stat_info: Dictionary = STATS[stat_key]
		if str(stat_info.get("category", "")) == category:
			var name: String = str(stat_info.get("name", stat_key))
			var value: int = int(stats.get(stat_key, 0))
			lines.append("  %s: [color=cyan]%s[/color]" % [name, _format_number(value)])

	return "\n".join(lines)


## Format records for display
static func format_records(profile: Dictionary) -> String:
	var stats: Dictionary = get_stats(profile)
	var lines: Array[String] = []

	for record_key in RECORDS.keys():
		var record_info: Dictionary = RECORDS[record_key]
		var name: String = str(record_info.get("name", record_key))
		var value: int = int(stats.get(record_key, 0))
		var lower_is_better: bool = bool(record_info.get("lower_is_better", false))

		if lower_is_better and value >= 999999:
			lines.append("  %s: [color=gray]--[/color]" % name)
		else:
			lines.append("  %s: [color=lime]%s[/color]" % [name, _format_number(value)])

	return "\n".join(lines)


## Format full stats report
static func format_full_report(profile: Dictionary) -> String:
	var lines: Array[String] = []
	var derived: Dictionary = calculate_derived_stats(profile)

	lines.append("[color=yellow]PLAYER STATISTICS[/color]")
	lines.append("")

	lines.append("[color=orange]Combat[/color]")
	lines.append(format_stats_by_category(profile, "combat"))
	lines.append("")

	lines.append("[color=orange]Typing[/color]")
	lines.append(format_stats_by_category(profile, "typing"))
	lines.append("  Overall Accuracy: [color=cyan]%.1f%%[/color]" % float(derived.get("overall_accuracy", 0)))
	lines.append("")

	lines.append("[color=orange]Economy[/color]")
	lines.append(format_stats_by_category(profile, "economy"))
	lines.append("  Avg Gold/Wave: [color=cyan]%.1f[/color]" % float(derived.get("avg_gold_per_wave", 0)))
	lines.append("")

	lines.append("[color=orange]Progression[/color]")
	lines.append(format_stats_by_category(profile, "progression"))
	lines.append("")

	lines.append("[color=orange]Performance[/color]")
	lines.append("  K/D Ratio: [color=cyan]%.2f[/color]" % float(derived.get("kd_ratio", 0)))
	lines.append("  Combo Efficiency: [color=cyan]%.1f%%[/color]" % float(derived.get("combo_efficiency", 0)))
	lines.append("  Avg Kills/Wave: [color=cyan]%.1f[/color]" % float(derived.get("avg_kills_per_wave", 0)))
	lines.append("")

	lines.append("[color=orange]Time[/color]")
	lines.append(format_stats_by_category(profile, "time"))
	lines.append("  Total Hours: [color=cyan]%.1f[/color]" % float(derived.get("play_time_hours", 0)))

	return "\n".join(lines)


## Format compact summary
static func format_summary(profile: Dictionary) -> String:
	var stats: Dictionary = get_stats(profile)
	var derived: Dictionary = calculate_derived_stats(profile)
	var lines: Array[String] = []

	lines.append("[color=yellow]STATS SUMMARY[/color]")
	lines.append("")
	lines.append("Kills: %s | Words: %s | Gold: %s" % [
		_format_number(int(stats.get("total_kills", 0))),
		_format_number(int(stats.get("total_words_typed", 0))),
		_format_number(int(stats.get("total_gold_earned", 0)))
	])
	lines.append("Accuracy: %.1f%% | K/D: %.2f" % [
		float(derived.get("overall_accuracy", 0)),
		float(derived.get("kd_ratio", 0))
	])
	lines.append("Highest Combo: %d | Highest Day: %d" % [
		int(stats.get("highest_combo", 0)),
		int(stats.get("highest_day", 0))
	])
	lines.append("")
	lines.append("[color=gray]Type 'stats full' for detailed report[/color]")

	return "\n".join(lines)


## Format number with commas for readability
static func _format_number(value: int) -> String:
	var s: String = str(abs(value))
	var result: String = ""
	var count: int = 0

	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1

	if value < 0:
		result = "-" + result

	return result


## Get categories list
static func get_categories() -> Array[String]:
	return ["combat", "typing", "economy", "progression", "time", "combo", "records"]


## Session tracking helpers
static func start_session(profile: Dictionary) -> void:
	increment_stat(profile, "sessions_played", 1)


static func add_play_time(profile: Dictionary, minutes: int) -> void:
	increment_stat(profile, "total_play_time", minutes)


## Batch update multiple stats (more efficient)
static func batch_update(profile: Dictionary, updates: Dictionary) -> void:
	var stats: Dictionary = get_stats(profile)

	for key in updates.keys():
		if STATS.has(key):
			stats[key] = int(stats.get(key, 0)) + int(updates[key])
		elif RECORDS.has(key):
			var lower_is_better: bool = bool(RECORDS.get(key, {}).get("lower_is_better", false))
			var current: int = int(stats.get(key, 999999 if lower_is_better else 0))
			var new_value: int = int(updates[key])
			if lower_is_better:
				if new_value < current and new_value > 0:
					stats[key] = new_value
			else:
				if new_value > current:
					stats[key] = new_value

	save_stats(profile, stats)
