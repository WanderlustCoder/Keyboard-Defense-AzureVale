class_name AchievementChecker
extends RefCounted
## Achievement checker - monitors gameplay events and unlocks achievements

const TypingProfile = preload("res://game/typing_profile.gd")

signal achievement_unlocked(achievement_id: String, achievement_data: Dictionary)

var _story_data: Dictionary = {}
var _achievements_cache: Dictionary = {}

func _init() -> void:
	_load_story_data()

func _load_story_data() -> void:
	var file := FileAccess.open("res://data/story.json", FileAccess.READ)
	if file == null:
		push_warning("AchievementChecker: Could not load story.json")
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_warning("AchievementChecker: Failed to parse story.json")
		return
	_story_data = json.data
	_achievements_cache = _story_data.get("achievements", {})

## Get achievement info from story.json
func get_achievement_info(achievement_id: String) -> Dictionary:
	return _achievements_cache.get(achievement_id, {})

## Get all achievement definitions
func get_all_achievement_info() -> Dictionary:
	return _achievements_cache.duplicate(true)

## Check and unlock first_blood achievement
func check_first_blood(profile: Dictionary, enemies_defeated: int) -> Dictionary:
	if enemies_defeated >= 1:
		return TypingProfile.unlock_achievement(profile, "first_blood")
	return {"ok": true, "profile": profile}

## Check and unlock combo achievements
func check_combo(profile: Dictionary, combo: int) -> Dictionary:
	var result: Dictionary = {"ok": true, "profile": profile}

	# Update best combo stat
	TypingProfile.update_best_stat(profile, "best_combo", combo)

	if combo >= 5 and not TypingProfile.is_achievement_unlocked(profile, "combo_starter"):
		result = TypingProfile.unlock_achievement(profile, "combo_starter")
		if result.get("newly_unlocked", false):
			var info := get_achievement_info("combo_starter")
			achievement_unlocked.emit("combo_starter", info)
		profile = result.get("profile", profile)

	if combo >= 20 and not TypingProfile.is_achievement_unlocked(profile, "combo_master"):
		result = TypingProfile.unlock_achievement(profile, "combo_master")
		if result.get("newly_unlocked", false):
			var info := get_achievement_info("combo_master")
			achievement_unlocked.emit("combo_master", info)
		profile = result.get("profile", profile)

	return {"ok": true, "profile": profile}

## Check and unlock speed_demon achievement
func check_wpm(profile: Dictionary, wpm: float) -> Dictionary:
	# Update best WPM stat
	TypingProfile.update_best_stat(profile, "best_wpm", wpm)

	if wpm >= 60.0 and not TypingProfile.is_achievement_unlocked(profile, "speed_demon"):
		var result := TypingProfile.unlock_achievement(profile, "speed_demon")
		if result.get("newly_unlocked", false):
			var info := get_achievement_info("speed_demon")
			achievement_unlocked.emit("speed_demon", info)
		return result
	return {"ok": true, "profile": profile}

## Check and unlock perfectionist achievement
func check_perfect_wave(profile: Dictionary, accuracy: float) -> Dictionary:
	if accuracy >= 1.0 and not TypingProfile.is_achievement_unlocked(profile, "perfectionist"):
		var result := TypingProfile.unlock_achievement(profile, "perfectionist")
		if result.get("newly_unlocked", false):
			var info := get_achievement_info("perfectionist")
			achievement_unlocked.emit("perfectionist", info)
		return result
	return {"ok": true, "profile": profile}

## Check and unlock defender achievement (no damage taken)
func check_defender(profile: Dictionary, damage_taken: int) -> Dictionary:
	if damage_taken == 0 and not TypingProfile.is_achievement_unlocked(profile, "defender"):
		var result := TypingProfile.unlock_achievement(profile, "defender")
		if result.get("newly_unlocked", false):
			var info := get_achievement_info("defender")
			achievement_unlocked.emit("defender", info)
		return result
	return {"ok": true, "profile": profile}

## Check and unlock survivor achievement (won with 1 HP)
func check_survivor(profile: Dictionary, hp_remaining: int, won: bool) -> Dictionary:
	if won and hp_remaining == 1 and not TypingProfile.is_achievement_unlocked(profile, "survivor"):
		var result := TypingProfile.unlock_achievement(profile, "survivor")
		if result.get("newly_unlocked", false):
			var info := get_achievement_info("survivor")
			achievement_unlocked.emit("survivor", info)
		return result
	return {"ok": true, "profile": profile}

## Check and unlock boss_slayer achievement
func check_boss_defeated(profile: Dictionary, boss_kind: String) -> Dictionary:
	# Increment bosses defeated
	TypingProfile.increment_lifetime_stat(profile, "bosses_defeated")

	# First boss kill
	if not TypingProfile.is_achievement_unlocked(profile, "boss_slayer"):
		var result := TypingProfile.unlock_achievement(profile, "boss_slayer")
		if result.get("newly_unlocked", false):
			var info := get_achievement_info("boss_slayer")
			achievement_unlocked.emit("boss_slayer", info)
		profile = result.get("profile", profile)

	# Void Tyrant specifically
	if boss_kind == "void_tyrant" and not TypingProfile.is_achievement_unlocked(profile, "void_vanquisher"):
		var result := TypingProfile.unlock_achievement(profile, "void_vanquisher")
		if result.get("newly_unlocked", false):
			var info := get_achievement_info("void_vanquisher")
			achievement_unlocked.emit("void_vanquisher", info)
		profile = result.get("profile", profile)

	return {"ok": true, "profile": profile}

## Check lesson mastery achievements
func check_lesson_mastery(profile: Dictionary, lessons_mastered: Array) -> Dictionary:
	var result: Dictionary = {"ok": true, "profile": profile}

	# Home row mastery (home_row_1, home_row_2, home_row_words)
	var home_row_lessons := ["home_row_1", "home_row_2", "home_row_words"]
	var home_row_complete := true
	for lesson_id in home_row_lessons:
		if not lessons_mastered.has(lesson_id):
			home_row_complete = false
			break

	if home_row_complete and not TypingProfile.is_achievement_unlocked(profile, "home_row_master"):
		result = TypingProfile.unlock_achievement(profile, "home_row_master")
		if result.get("newly_unlocked", false):
			var info := get_achievement_info("home_row_master")
			achievement_unlocked.emit("home_row_master", info)
		profile = result.get("profile", profile)

	# Alphabet scholar (full_alpha lesson)
	if lessons_mastered.has("full_alpha") and not TypingProfile.is_achievement_unlocked(profile, "alphabet_scholar"):
		result = TypingProfile.unlock_achievement(profile, "alphabet_scholar")
		if result.get("newly_unlocked", false):
			var info := get_achievement_info("alphabet_scholar")
			achievement_unlocked.emit("alphabet_scholar", info)
		profile = result.get("profile", profile)

	# Number cruncher (numbers_1, numbers_2)
	var number_lessons := ["numbers_1", "numbers_2"]
	var numbers_complete := true
	for lesson_id in number_lessons:
		if not lessons_mastered.has(lesson_id):
			numbers_complete = false
			break

	if numbers_complete and not TypingProfile.is_achievement_unlocked(profile, "number_cruncher"):
		result = TypingProfile.unlock_achievement(profile, "number_cruncher")
		if result.get("newly_unlocked", false):
			var info := get_achievement_info("number_cruncher")
			achievement_unlocked.emit("number_cruncher", info)
		profile = result.get("profile", profile)

	# Keyboard master (all lessons - check if lesson count is high enough)
	if lessons_mastered.size() >= 12 and not TypingProfile.is_achievement_unlocked(profile, "keyboard_master"):
		result = TypingProfile.unlock_achievement(profile, "keyboard_master")
		if result.get("newly_unlocked", false):
			var info := get_achievement_info("keyboard_master")
			achievement_unlocked.emit("keyboard_master", info)
		profile = result.get("profile", profile)

	return {"ok": true, "profile": profile}

## Called when an enemy is defeated - checks relevant achievements
func on_enemy_defeated(profile: Dictionary, is_boss: bool = false, boss_kind: String = "") -> Dictionary:
	# Increment enemies defeated
	TypingProfile.increment_lifetime_stat(profile, "enemies_defeated")
	var enemies_defeated: int = int(TypingProfile.get_lifetime_stat(profile, "enemies_defeated"))

	# Check first blood
	var result := check_first_blood(profile, enemies_defeated)
	if result.get("newly_unlocked", false):
		var info := get_achievement_info("first_blood")
		achievement_unlocked.emit("first_blood", info)
	profile = result.get("profile", profile)

	# Check boss achievements
	if is_boss and boss_kind != "":
		result = check_boss_defeated(profile, boss_kind)
		profile = result.get("profile", profile)

	return {"ok": true, "profile": profile}

## Called at end of wave/battle with stats
func on_wave_complete(profile: Dictionary, stats: Dictionary) -> Dictionary:
	var accuracy: float = float(stats.get("accuracy", 0.0))
	var wpm: float = float(stats.get("wpm", 0.0))
	var damage_taken: int = int(stats.get("damage_taken", 0))
	var hp_remaining: int = int(stats.get("hp_remaining", 0))
	var won: bool = bool(stats.get("won", false))
	var combo: int = int(stats.get("best_combo", 0))

	# Check all relevant achievements
	check_perfect_wave(profile, accuracy)
	check_wpm(profile, wpm)
	check_defender(profile, damage_taken)
	check_survivor(profile, hp_remaining, won)
	check_combo(profile, combo)

	return {"ok": true, "profile": profile}
