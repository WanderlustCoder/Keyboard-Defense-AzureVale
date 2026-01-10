class_name SimEndlessMode
extends RefCounted
## Endless Mode System - Infinite scaling challenge mode

# Unlock requirements
const UNLOCK_DAY: int = 15  # Days needed to unlock endless mode
const UNLOCK_WAVES: int = 45  # Waves completed needed (alternative unlock)

# Scaling factors per day
const HP_SCALE_PER_DAY: float = 0.08  # +8% HP per day
const SPEED_SCALE_PER_DAY: float = 0.02  # +2% speed per day
const COUNT_SCALE_PER_DAY: float = 0.05  # +5% enemy count per day
const DAMAGE_SCALE_PER_DAY: float = 0.04  # +4% enemy damage per day

# Milestone rewards
const MILESTONES: Dictionary = {
	5: {"name": "Survivor", "gold": 50, "xp": 100},
	10: {"name": "Enduring", "gold": 150, "xp": 300},
	15: {"name": "Persistent", "gold": 300, "xp": 600},
	20: {"name": "Indomitable", "gold": 500, "xp": 1000},
	25: {"name": "Unstoppable", "gold": 750, "xp": 1500},
	30: {"name": "Legendary", "gold": 1000, "xp": 2000},
	40: {"name": "Mythic", "gold": 1500, "xp": 3000},
	50: {"name": "Godlike", "gold": 2500, "xp": 5000},
	75: {"name": "Transcendent", "gold": 5000, "xp": 10000},
	100: {"name": "Eternal", "gold": 10000, "xp": 25000}
}

# Special endless wave modifiers that stack over time
const ENDLESS_MODIFIERS: Dictionary = {
	"veteran_enemies": {
		"start_day": 8,
		"description": "Enemies gain +10% armor",
		"armor_bonus": 0.1
	},
	"elite_spawn": {
		"start_day": 12,
		"description": "Elite enemies spawn more often",
		"elite_chance": 0.15
	},
	"swarm_mode": {
		"start_day": 16,
		"description": "Occasional swarm waves with 2x enemies",
		"swarm_chance": 0.2
	},
	"boss_rush": {
		"start_day": 20,
		"description": "Mini-bosses appear every 3 waves",
		"boss_interval": 3
	},
	"affix_surge": {
		"start_day": 25,
		"description": "All enemies gain random affixes",
		"affix_chance": 0.4
	},
	"nightmare": {
		"start_day": 30,
		"description": "Nightmare difficulty - massive stat boosts",
		"hp_mult": 2.0,
		"damage_mult": 1.5
	}
}


## Check if endless mode is unlocked
static func is_unlocked(profile: Dictionary) -> bool:
	var max_day: int = int(TypingProfile.get_profile_value(profile, "max_day_reached", 0))
	var total_waves: int = int(TypingProfile.get_profile_value(profile, "total_waves_completed", 0))

	return max_day >= UNLOCK_DAY or total_waves >= UNLOCK_WAVES


## Get endless mode high scores
static func get_high_scores(profile: Dictionary) -> Dictionary:
	return {
		"highest_day": int(TypingProfile.get_profile_value(profile, "endless_highest_day", 0)),
		"highest_wave": int(TypingProfile.get_profile_value(profile, "endless_highest_wave", 0)),
		"best_combo": int(TypingProfile.get_profile_value(profile, "endless_best_combo", 0)),
		"total_kills": int(TypingProfile.get_profile_value(profile, "endless_total_kills", 0)),
		"total_runs": int(TypingProfile.get_profile_value(profile, "endless_total_runs", 0)),
		"fastest_day": float(TypingProfile.get_profile_value(profile, "endless_fastest_day", 999.0))
	}


## Update endless mode high scores
static func update_high_scores(profile: Dictionary, day: int, wave: int, combo: int, kills: int, day_time: float) -> Dictionary:
	var updated: Dictionary = {
		"new_records": [],
		"milestones_reached": []
	}

	var current_highest_day: int = int(TypingProfile.get_profile_value(profile, "endless_highest_day", 0))
	var current_highest_wave: int = int(TypingProfile.get_profile_value(profile, "endless_highest_wave", 0))
	var current_best_combo: int = int(TypingProfile.get_profile_value(profile, "endless_best_combo", 0))
	var current_fastest: float = float(TypingProfile.get_profile_value(profile, "endless_fastest_day", 999.0))

	# Check for new records
	if day > current_highest_day:
		TypingProfile.set_profile_value(profile, "endless_highest_day", day)
		updated["new_records"].append("New high day: %d" % day)

		# Check for milestones
		for milestone_day in MILESTONES.keys():
			if day >= milestone_day and current_highest_day < milestone_day:
				updated["milestones_reached"].append(milestone_day)

	if wave > current_highest_wave:
		TypingProfile.set_profile_value(profile, "endless_highest_wave", wave)
		updated["new_records"].append("New high wave: %d" % wave)

	if combo > current_best_combo:
		TypingProfile.set_profile_value(profile, "endless_best_combo", combo)
		updated["new_records"].append("New best combo: %d" % combo)

	if day_time < current_fastest and day_time > 0:
		TypingProfile.set_profile_value(profile, "endless_fastest_day", day_time)
		updated["new_records"].append("New fastest day: %.1fs" % day_time)

	# Update totals
	var total_kills: int = int(TypingProfile.get_profile_value(profile, "endless_total_kills", 0))
	TypingProfile.set_profile_value(profile, "endless_total_kills", total_kills + kills)

	return updated


## Increment run count
static func start_run(profile: Dictionary) -> void:
	var runs: int = int(TypingProfile.get_profile_value(profile, "endless_total_runs", 0))
	TypingProfile.set_profile_value(profile, "endless_total_runs", runs + 1)


## Get scaling multipliers for a given day
static func get_scaling(day: int) -> Dictionary:
	return {
		"hp_mult": 1.0 + (float(day - 1) * HP_SCALE_PER_DAY),
		"speed_mult": 1.0 + (float(day - 1) * SPEED_SCALE_PER_DAY),
		"count_mult": 1.0 + (float(day - 1) * COUNT_SCALE_PER_DAY),
		"damage_mult": 1.0 + (float(day - 1) * DAMAGE_SCALE_PER_DAY)
	}


## Get active modifiers for a given day
static func get_active_modifiers(day: int) -> Array[String]:
	var active: Array[String] = []
	for mod_id in ENDLESS_MODIFIERS.keys():
		var mod: Dictionary = ENDLESS_MODIFIERS[mod_id]
		if day >= int(mod.get("start_day", 999)):
			active.append(mod_id)
	return active


## Get modifier details
static func get_modifier(mod_id: String) -> Dictionary:
	return ENDLESS_MODIFIERS.get(mod_id, {})


## Check if this wave should be a swarm wave
static func is_swarm_wave(day: int, wave: int, rng_seed: int) -> bool:
	if day < int(ENDLESS_MODIFIERS.get("swarm_mode", {}).get("start_day", 999)):
		return false

	var swarm_chance: float = float(ENDLESS_MODIFIERS.get("swarm_mode", {}).get("swarm_chance", 0.2))
	var roll: float = _seeded_random(rng_seed + day * 50 + wave * 7)
	return roll < swarm_chance


## Check if this wave should have a mini-boss
static func should_spawn_miniboss(day: int, wave: int) -> bool:
	if day < int(ENDLESS_MODIFIERS.get("boss_rush", {}).get("start_day", 999)):
		return false

	var interval: int = int(ENDLESS_MODIFIERS.get("boss_rush", {}).get("boss_interval", 3))
	return wave % interval == 0


## Get milestone reward for a day
static func get_milestone_reward(day: int) -> Dictionary:
	return MILESTONES.get(day, {})


## Get all milestones
static func get_all_milestones() -> Array[int]:
	var milestones: Array[int] = []
	for d in MILESTONES.keys():
		milestones.append(d)
	milestones.sort()
	return milestones


## Format endless mode status for display
static func format_status(profile: Dictionary) -> String:
	var lines: Array[String] = []

	if not is_unlocked(profile):
		var max_day: int = int(TypingProfile.get_profile_value(profile, "max_day_reached", 0))
		var progress: float = float(max_day) / float(UNLOCK_DAY) * 100.0
		lines.append("[color=gray]ENDLESS MODE LOCKED[/color]")
		lines.append("Reach Day %d to unlock (%.0f%% progress)" % [UNLOCK_DAY, progress])
		return "\n".join(lines)

	lines.append("[color=yellow]ENDLESS MODE[/color]")
	lines.append("")

	var scores: Dictionary = get_high_scores(profile)
	lines.append("[color=cyan]High Scores:[/color]")
	lines.append("  Highest Day: %d" % int(scores.get("highest_day", 0)))
	lines.append("  Highest Wave: %d" % int(scores.get("highest_wave", 0)))
	lines.append("  Best Combo: %d" % int(scores.get("best_combo", 0)))
	lines.append("  Total Kills: %d" % int(scores.get("total_kills", 0)))
	lines.append("  Total Runs: %d" % int(scores.get("total_runs", 0)))

	if float(scores.get("fastest_day", 999.0)) < 999.0:
		lines.append("  Fastest Day: %.1fs" % float(scores.get("fastest_day", 0)))

	# Show next milestone
	var highest: int = int(scores.get("highest_day", 0))
	var next_milestone: int = 0
	for m in get_all_milestones():
		if m > highest:
			next_milestone = m
			break

	if next_milestone > 0:
		var reward: Dictionary = MILESTONES[next_milestone]
		lines.append("")
		lines.append("[color=orange]Next Milestone: Day %d (%s)[/color]" % [next_milestone, str(reward.get("name", ""))])
		lines.append("  Rewards: %d gold, %d XP" % [int(reward.get("gold", 0)), int(reward.get("xp", 0))])

	return "\n".join(lines)


## Format current endless run status
static func format_run_status(day: int, wave: int, combo: int, kills: int) -> String:
	var lines: Array[String] = []

	lines.append("[color=yellow]ENDLESS RUN[/color]")
	lines.append("Day %d - Wave %d" % [day, wave])
	lines.append("Combo: %d | Kills: %d" % [combo, kills])

	# Show scaling
	var scaling: Dictionary = get_scaling(day)
	lines.append("")
	lines.append("[color=gray]Scaling:[/color]")
	lines.append("  HP: x%.2f" % float(scaling.get("hp_mult", 1.0)))
	lines.append("  Speed: x%.2f" % float(scaling.get("speed_mult", 1.0)))
	lines.append("  Count: x%.2f" % float(scaling.get("count_mult", 1.0)))

	# Show active modifiers
	var mods: Array[String] = get_active_modifiers(day)
	if not mods.is_empty():
		lines.append("")
		lines.append("[color=orange]Active Modifiers:[/color]")
		for mod_id in mods:
			var mod: Dictionary = get_modifier(mod_id)
			lines.append("  • %s" % str(mod.get("description", mod_id)))

	return "\n".join(lines)


## Deterministic random
static func _seeded_random(seed_val: int) -> float:
	var a: int = 1103515245
	var c: int = 12345
	var m: int = 2147483648
	var value: int = (a * abs(seed_val) + c) % m
	return float(value) / float(m)
