# Typing Profile Model Guide

This document explains the TypingProfile class that manages player settings, keybinds, achievements, lesson progress, and persistence.

## Overview

TypingProfile provides static methods for profile management:

```
Load Profile → Merge Defaults → Get/Set Values → Save Profile
      ↓              ↓              ↓               ↓
  profile.json   normalization   typed access   JSON persist
```

## Class Reference

```gdscript
# game/typing_profile.gd
class_name TypingProfile
extends RefCounted

const PROFILE_PATH := "user://profile.json"
const VERSION := 1
```

## Default Keybinds

```gdscript
const DEFAULT_CYCLE_GOAL_BIND := {"keycode": KEY_F7, "shift": false, "alt": false, "ctrl": false, "meta": false}
const DEFAULT_TOGGLE_SETTINGS_BIND := {"keycode": KEY_F1, "shift": false, "alt": false, "ctrl": false, "meta": false}
const DEFAULT_TOGGLE_LESSONS_BIND := {"keycode": KEY_F2, "shift": false, "alt": false, "ctrl": false, "meta": false}
const DEFAULT_TOGGLE_TREND_BIND := {"keycode": KEY_F3, "shift": false, "alt": false, "ctrl": false, "meta": false}
const DEFAULT_TOGGLE_COMPACT_BIND := {"keycode": KEY_F4, "shift": false, "alt": false, "ctrl": false, "meta": false}
const DEFAULT_TOGGLE_HISTORY_BIND := {"keycode": KEY_F5, "shift": false, "alt": false, "ctrl": false, "meta": false}
const DEFAULT_TOGGLE_REPORT_BIND := {"keycode": KEY_F6, "shift": false, "alt": false, "ctrl": false, "meta": false}
```

| Action | Default Key |
|--------|-------------|
| cycle_goal | F7 |
| toggle_settings | F1 |
| toggle_lessons | F2 |
| toggle_trend | F3 |
| toggle_compact | F4 |
| toggle_history | F5 |
| toggle_report | F6 |

## UI Preferences

```gdscript
const DEFAULT_UI_PREFS := {
    "lessons_sort": "default",       # "default", "name", "recent"
    "lessons_sparkline": true,       # Show sparkline charts
    "onboarding": DEFAULT_ONBOARDING,
    "economy_note_shown": false,
    "ui_scale_percent": 100,         # 80-140
    "compact_panels": false,
    "reduced_motion": false,
    "speed_multiplier": 1.0,         # 0.5-2.0
    "high_contrast": false,
    "nav_hints": true,
    "practice_mode": false
}

const UI_SCALE_VALUES := [80, 90, 100, 110, 120, 130, 140]
const SPEED_MULTIPLIER_VALUES := [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
```

## Onboarding State

```gdscript
const DEFAULT_ONBOARDING := {
    "enabled": true,
    "completed": false,
    "step": 0,
    "ever_shown": false
}
```

## Lesson Progress Entry

```gdscript
const DEFAULT_LESSON_PROGRESS := {
    "nights": 0,              # Times played
    "goal_passes": 0,         # Times goal met
    "sum_accuracy": 0.0,      # Cumulative accuracy
    "sum_hit_rate": 0.0,      # Cumulative hit rate
    "sum_backspace_rate": 0.0,
    "best_accuracy": 0.0,
    "best_hit_rate": 0.0,
    "last_day": 0,
    "recent": []              # Last 3 sessions
}
```

## Achievement IDs

```gdscript
const ACHIEVEMENT_IDS := [
    "first_blood",       # Defeat your first enemy
    "combo_starter",     # Achieve a 5-combo
    "combo_master",      # Achieve a 20-combo
    "speed_demon",       # Reach 60 WPM
    "perfectionist",     # Complete a wave with 100% accuracy
    "home_row_master",   # Master all home row lessons
    "alphabet_scholar",  # Learn all 26 letters
    "number_cruncher",   # Master the number row
    "keyboard_master",   # Complete all lessons
    "defender",          # Complete a day without losing health
    "survivor",          # Win a battle with only 1 HP remaining
    "boss_slayer",       # Defeat your first boss
    "void_vanquisher"    # Defeat the Void Tyrant
]
```

## Profile Structure

```gdscript
# game/typing_profile.gd:104
static func default_profile() -> Dictionary:
    return {
        "version": VERSION,
        "practice_goal": "balanced",
        "preferred_lesson": SimLessons.default_lesson_id(),
        "keybinds": default_keybinds(),
        "ui_prefs": DEFAULT_UI_PREFS.duplicate(true),
        "lesson_progress": default_lesson_progress_map(),
        "achievements": default_achievements(),
        "typing_history": [],
        "lifetime": {
            "nights": 0,
            "defend_attempts": 0,
            "hits": 0,
            "misses": 0,
            "enemies_defeated": 0,
            "bosses_defeated": 0,
            "best_combo": 0,
            "best_wpm": 0.0
        },
        "streak": {
            "daily_streak": 0,
            "best_streak": 0,
            "last_play_date": ""  # ISO date string YYYY-MM-DD
        }
    }
```

## Loading Profiles

```gdscript
# game/typing_profile.gd:131
static func load_profile(path: String = PROFILE_PATH) -> Dictionary:
    var load_path: String = path if path != "" else PROFILE_PATH

    if not FileAccess.file_exists(load_path):
        return {"ok": true, "profile": default_profile()}

    var file: FileAccess = FileAccess.open(load_path, FileAccess.READ)
    if file == null:
        return {"ok": false, "error": "Profile load failed: %s" % error_string(FileAccess.get_open_error())}

    var text: String = file.get_as_text()
    var parsed: Variant = JSON.parse_string(text)
    if typeof(parsed) != TYPE_DICTIONARY:
        return {"ok": false, "error": "Profile file is invalid JSON."}

    var data: Dictionary = parsed
    var version: int = int(data.get("version", 1))
    if version > VERSION:
        return {"ok": false, "error": "Profile version is too new."}

    # Merge with defaults
    var profile: Dictionary = default_profile()
    profile["typing_history"] = data.get("typing_history", [])
    profile["lifetime"] = data.get("lifetime", {})
    profile["practice_goal"] = PracticeGoals.normalize_goal(str(data.get("practice_goal", "balanced")))
    profile["preferred_lesson"] = SimLessons.normalize_lesson_id(str(data.get("preferred_lesson", "")))
    profile["lesson_progress"] = _merge_lesson_progress(data.get("lesson_progress", {}))
    profile["keybinds"] = _merge_keybinds(data.get("keybinds", {}))
    profile["ui_prefs"] = _merge_ui_prefs(data.get("ui_prefs", {}))
    profile["achievements"] = _merge_achievements(data.get("achievements", {}))
    profile["streak"] = _merge_streak(data.get("streak", {}))

    return {"ok": true, "profile": profile}
```

## Saving Profiles

```gdscript
# game/typing_profile.gd:462
static func save_profile(profile: Dictionary, path: String = PROFILE_PATH) -> Dictionary:
    var data: Dictionary = profile.duplicate(true)
    data["version"] = VERSION
    data["keybinds"] = _serialize_keybinds(profile.get("keybinds", {}))

    var json_text: String = JSON.stringify(data, "  ")
    var save_path: String = path if path != "" else PROFILE_PATH

    var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
    if file == null:
        return {"ok": false, "error": "Profile save failed: %s" % error_string(FileAccess.get_open_error())}

    file.store_string(json_text)
    return {"ok": true, "path": save_path}
```

## Keybind Management

### Get Keybind

```gdscript
# game/typing_profile.gd:165
static func get_keybind(profile: Dictionary, action_name: String) -> Dictionary:
    if profile.has("keybinds") and typeof(profile.get("keybinds")) == TYPE_DICTIONARY:
        var keybinds: Dictionary = profile.get("keybinds")
        if keybinds.has(action_name):
            return _normalize_keybind(keybinds.get(action_name), action_name)
    return _normalize_keybind({}, action_name)
```

### Set Keybind

```gdscript
# game/typing_profile.gd:172
static func set_keybind(profile: Dictionary, action_name: String, keybind: Dictionary) -> Dictionary:
    var normalized: Dictionary = _normalize_keybind(keybind, action_name)
    if not profile.has("keybinds"):
        profile["keybinds"] = {}
    profile["keybinds"][action_name] = normalized
    var result: Dictionary = save_profile(profile)
    if result.get("ok", false):
        return {"ok": true, "profile": profile}
    return {"ok": false, "profile": profile, "error": result.get("error", "")}
```

### Keybind Normalization

```gdscript
# game/typing_profile.gd:631
static func _normalize_keybind(raw: Variant, action_name: String) -> Dictionary:
    var defaults: Dictionary = default_binding_for_action(action_name)

    # Handle string format (e.g., "F7", "Ctrl+F1")
    if typeof(raw) == TYPE_STRING:
        var parsed: Dictionary = ControlsFormatter.keybind_from_text(str(raw))
        if parsed.is_empty():
            return defaults.duplicate()
        raw = parsed

    if typeof(raw) != TYPE_DICTIONARY:
        return defaults.duplicate()

    var keycode: int = int(raw.get("keycode", defaults.get("keycode", 0)))
    if keycode <= 0:
        keycode = int(defaults.get("keycode", KEY_F7))

    return {
        "keycode": keycode,
        "shift": bool(raw.get("shift", defaults.get("shift", false))),
        "alt": bool(raw.get("alt", defaults.get("alt", false))),
        "ctrl": bool(raw.get("ctrl", defaults.get("ctrl", false))),
        "meta": bool(raw.get("meta", defaults.get("meta", false)))
    }
```

## Goal Management

```gdscript
# game/typing_profile.gd:182
static func get_goal(profile: Dictionary) -> String:
    return PracticeGoals.normalize_goal(str(profile.get("practice_goal", "balanced")))

static func set_goal(profile: Dictionary, goal_id: String) -> Dictionary:
    var normalized: String = PracticeGoals.normalize_goal(goal_id)
    profile["practice_goal"] = normalized
    var result: Dictionary = save_profile(profile)
    if result.get("ok", false):
        return {"ok": true, "profile": profile}
    return {"ok": false, "profile": profile, "error": result.get("error", "")}
```

## Lesson Management

```gdscript
# game/typing_profile.gd:193
static func get_lesson(profile: Dictionary) -> String:
    return SimLessons.normalize_lesson_id(str(profile.get("preferred_lesson", SimLessons.default_lesson_id())))

static func set_lesson(profile: Dictionary, lesson_id: String) -> Dictionary:
    var normalized: String = SimLessons.normalize_lesson_id(lesson_id)
    profile["preferred_lesson"] = normalized
    var result: Dictionary = save_profile(profile)
    if result.get("ok", false):
        return {"ok": true, "profile": profile}
    return {"ok": false, "profile": profile, "error": result.get("error", "")}
```

## UI Preference Getters/Setters

### Lessons Sort

```gdscript
# game/typing_profile.gd:204
static func get_lessons_sort(profile: Dictionary) -> String:
    if profile.has("ui_prefs"):
        var prefs: Dictionary = profile.get("ui_prefs")
        return _normalize_lessons_sort(str(prefs.get("lessons_sort", "default")))
    return "default"

static func set_lessons_sort(profile: Dictionary, mode: String) -> Dictionary:
    var normalized: String = _normalize_lessons_sort(mode)
    profile["ui_prefs"]["lessons_sort"] = normalized
    return save_profile(profile)

static func _normalize_lessons_sort(mode: String) -> String:
    var normalized: String = mode.strip_edges().to_lower()
    if normalized == "name":
        return "name"
    if normalized == "recent":
        return "recent"
    return "default"
```

### UI Scale

```gdscript
# game/typing_profile.gd:281
static func get_ui_scale_percent(profile: Dictionary) -> int:
    if profile.has("ui_prefs"):
        var prefs: Dictionary = profile.get("ui_prefs")
        return _normalize_ui_scale(int(prefs.get("ui_scale_percent", 100)))
    return 100

static func set_ui_scale_percent(profile: Dictionary, value: int) -> Dictionary:
    var normalized: int = _normalize_ui_scale(value)
    profile["ui_prefs"]["ui_scale_percent"] = normalized
    return save_profile(profile)

static func _normalize_ui_scale(value: int) -> int:
    if UI_SCALE_VALUES.has(value):
        return value
    var clamped: int = clamp(value, 80, 140)
    var rounded: int = int(round(float(clamped) / 10.0) * 10.0)
    if UI_SCALE_VALUES.has(rounded):
        return rounded
    return 100
```

### Speed Multiplier

```gdscript
# game/typing_profile.gd:327
static func get_speed_multiplier(profile: Dictionary) -> float:
    if profile.has("ui_prefs"):
        var prefs: Dictionary = profile.get("ui_prefs")
        var val: float = float(prefs.get("speed_multiplier", 1.0))
        if val > 0.0 and val <= 2.0:
            return val
    return 1.0

static func set_speed_multiplier(profile: Dictionary, multiplier: float) -> Dictionary:
    var clamped: float = clamp(multiplier, 0.5, 2.0)
    profile["ui_prefs"]["speed_multiplier"] = clamped
    return save_profile(profile)

static func cycle_speed_multiplier(profile: Dictionary, direction: int) -> Dictionary:
    var current: float = get_speed_multiplier(profile)
    var current_index: int = 0
    for i in range(SPEED_MULTIPLIER_VALUES.size()):
        if abs(SPEED_MULTIPLIER_VALUES[i] - current) < 0.01:
            current_index = i
            break
    var next_index: int = (current_index + direction) % SPEED_MULTIPLIER_VALUES.size()
    if next_index < 0:
        next_index = SPEED_MULTIPLIER_VALUES.size() - 1
    return set_speed_multiplier(profile, SPEED_MULTIPLIER_VALUES[next_index])
```

### Boolean Preferences

```gdscript
static func get_compact_panels(profile: Dictionary) -> bool
static func set_compact_panels(profile: Dictionary, enabled: bool) -> Dictionary

static func get_reduced_motion(profile: Dictionary) -> bool
static func set_reduced_motion(profile: Dictionary, enabled: bool) -> Dictionary

static func get_high_contrast(profile: Dictionary) -> bool
static func set_high_contrast(profile: Dictionary, enabled: bool) -> Dictionary

static func get_nav_hints(profile: Dictionary) -> bool
static func set_nav_hints(profile: Dictionary, enabled: bool) -> Dictionary

static func get_practice_mode(profile: Dictionary) -> bool
static func set_practice_mode(profile: Dictionary, enabled: bool) -> Dictionary

static func get_lessons_sparkline(profile: Dictionary) -> bool
static func set_lessons_sparkline(profile: Dictionary, enabled: bool) -> Dictionary
```

## Onboarding Management

```gdscript
# game/typing_profile.gd:210
static func get_onboarding(profile: Dictionary) -> Dictionary:
    if profile.has("ui_prefs"):
        var prefs: Dictionary = profile.get("ui_prefs")
        return _normalize_onboarding(prefs.get("onboarding", {}))
    return default_onboarding_state()

static func set_onboarding(profile: Dictionary, onboarding: Dictionary) -> Dictionary:
    var normalized: Dictionary = _normalize_onboarding(onboarding)
    profile["ui_prefs"]["onboarding"] = normalized
    return save_profile(profile)

static func reset_onboarding(profile: Dictionary) -> Dictionary:
    var onboarding: Dictionary = default_onboarding_state()
    onboarding["enabled"] = true
    onboarding["completed"] = false
    onboarding["step"] = 0
    onboarding["ever_shown"] = true
    return set_onboarding(profile, onboarding)

static func complete_onboarding(profile: Dictionary) -> Dictionary:
    var onboarding: Dictionary = get_onboarding(profile)
    onboarding["enabled"] = false
    onboarding["completed"] = true
    onboarding["ever_shown"] = true
    return set_onboarding(profile, onboarding)
```

## Lesson Progress

### Get Progress Map

```gdscript
# game/typing_profile.gd:418
static func get_lesson_progress_map(profile: Dictionary) -> Dictionary:
    if profile.has("lesson_progress"):
        return _merge_lesson_progress(profile.get("lesson_progress"))
    return default_lesson_progress_map()
```

### Update Progress

```gdscript
# game/typing_profile.gd:423
static func update_lesson_progress(progress_map: Dictionary, lesson_id: String, report: Dictionary, goal_met: bool) -> Dictionary:
    var result: Dictionary = progress_map.duplicate(true)
    var normalized: String = SimLessons.normalize_lesson_id(lesson_id)
    var entry: Dictionary = _normalize_lesson_progress_entry(result.get(normalized, {}))

    entry["nights"] = int(entry.get("nights", 0)) + 1
    entry["goal_passes"] = int(entry.get("goal_passes", 0)) + (1 if goal_met else 0)

    var accuracy: float = float(report.get("avg_accuracy", 0.0))
    var hit_rate: float = float(report.get("hit_rate", 0.0))
    var backspace_rate: float = float(report.get("backspace_rate", 0.0))
    var incomplete_rate: float = float(report.get("incomplete_rate", 0.0))

    entry["sum_accuracy"] = float(entry.get("sum_accuracy", 0.0)) + accuracy
    entry["sum_hit_rate"] = float(entry.get("sum_hit_rate", 0.0)) + hit_rate
    entry["sum_backspace_rate"] = float(entry.get("sum_backspace_rate", 0.0)) + backspace_rate
    entry["best_accuracy"] = max(float(entry.get("best_accuracy", 0.0)), accuracy)
    entry["best_hit_rate"] = max(float(entry.get("best_hit_rate", 0.0)), hit_rate)
    entry["last_day"] = int(report.get("night_day", entry.get("last_day", 0)))

    # Update recent list (max 3 entries)
    var recent_entry: Dictionary = {
        "day": int(report.get("night_day", 0)),
        "avg_accuracy": accuracy,
        "hit_rate": hit_rate,
        "backspace_rate": backspace_rate,
        "incomplete_rate": incomplete_rate,
        "goal_met": goal_met
    }
    var recent_list: Array = entry.get("recent", []).duplicate()
    recent_list.insert(0, recent_entry)
    while recent_list.size() > 3:
        recent_list.pop_back()
    entry["recent"] = recent_list

    result[normalized] = entry
    return result
```

### Format Recent Entry

```gdscript
# game/typing_profile.gd:602
static func format_recent_entry(entry: Dictionary) -> String:
    var day: int = int(entry.get("day", 0))
    var acc: float = float(entry.get("avg_accuracy", 0.0)) * 100.0
    var hit: float = float(entry.get("hit_rate", 0.0)) * 100.0
    var back: float = float(entry.get("backspace_rate", 0.0)) * 100.0
    var inc: float = float(entry.get("incomplete_rate", 0.0)) * 100.0
    var met: bool = bool(entry.get("goal_met", false))
    var status: String = "PASS" if met else "NOT YET"
    return "Day %d | acc %.0f%% | hit %.0f%% | back %.0f%% | inc %.0f%% | %s" % [
        day, acc, hit, back, inc, status
    ]
```

## Achievement System

### Get Achievements

```gdscript
# game/typing_profile.gd:666
static func get_achievements(profile: Dictionary) -> Dictionary:
    if profile.has("achievements"):
        return _merge_achievements(profile.get("achievements"))
    return default_achievements()

static func is_achievement_unlocked(profile: Dictionary, achievement_id: String) -> bool:
    var achievements: Dictionary = get_achievements(profile)
    if achievements.has(achievement_id):
        var entry: Dictionary = achievements.get(achievement_id)
        return bool(entry.get("unlocked", false))
    return false
```

### Unlock Achievement

```gdscript
# game/typing_profile.gd:678
static func unlock_achievement(profile: Dictionary, achievement_id: String) -> Dictionary:
    if not ACHIEVEMENT_IDS.has(achievement_id):
        return {"ok": false, "profile": profile, "error": "Invalid achievement ID: %s" % achievement_id}

    if is_achievement_unlocked(profile, achievement_id):
        return {"ok": true, "profile": profile, "already_unlocked": true}

    if not profile.has("achievements"):
        profile["achievements"] = default_achievements()

    profile["achievements"][achievement_id] = {
        "unlocked": true,
        "unlocked_at": int(Time.get_unix_time_from_system())
    }

    var result: Dictionary = save_profile(profile)
    if result.get("ok", false):
        return {"ok": true, "profile": profile, "newly_unlocked": true}
    return {"ok": false, "profile": profile, "error": result.get("error", "")}
```

### Achievement Counts

```gdscript
# game/typing_profile.gd:701
static func get_unlocked_achievements(profile: Dictionary) -> Array[String]:
    var result: Array[String] = []
    var achievements: Dictionary = get_achievements(profile)
    for achievement_id in ACHIEVEMENT_IDS:
        if achievements.has(achievement_id):
            var entry: Dictionary = achievements.get(achievement_id)
            if bool(entry.get("unlocked", false)):
                result.append(achievement_id)
    return result

static func get_achievement_count(profile: Dictionary) -> Dictionary:
    var unlocked: int = get_unlocked_achievements(profile).size()
    var total: int = ACHIEVEMENT_IDS.size()
    return {"unlocked": unlocked, "total": total}
```

## Lifetime Statistics

```gdscript
# game/typing_profile.gd:716
static func get_lifetime_stat(profile: Dictionary, stat_name: String) -> Variant:
    if profile.has("lifetime"):
        var lifetime: Dictionary = profile.get("lifetime")
        return lifetime.get(stat_name, 0)
    return 0

static func update_lifetime_stat(profile: Dictionary, stat_name: String, value: Variant) -> Dictionary:
    if not profile.has("lifetime"):
        profile["lifetime"] = {
            "nights": 0,
            "defend_attempts": 0,
            "hits": 0,
            "misses": 0,
            "enemies_defeated": 0,
            "bosses_defeated": 0,
            "best_combo": 0,
            "best_wpm": 0.0
        }
    profile["lifetime"][stat_name] = value
    return save_profile(profile)

static func increment_lifetime_stat(profile: Dictionary, stat_name: String, amount: int = 1) -> Dictionary:
    var current: int = int(get_lifetime_stat(profile, stat_name))
    return update_lifetime_stat(profile, stat_name, current + amount)

static func update_best_stat(profile: Dictionary, stat_name: String, value: Variant) -> Dictionary:
    var current: Variant = get_lifetime_stat(profile, stat_name)
    if typeof(value) == TYPE_FLOAT:
        if float(value) > float(current):
            return update_lifetime_stat(profile, stat_name, value)
    elif typeof(value) == TYPE_INT:
        if int(value) > int(current):
            return update_lifetime_stat(profile, stat_name, value)
    return {"ok": true, "profile": profile}
```

## Daily Streak System

```gdscript
# game/typing_profile.gd:769
static func get_streak(profile: Dictionary) -> Dictionary:
    if profile.has("streak"):
        return _merge_streak(profile.get("streak"))
    return {"daily_streak": 0, "best_streak": 0, "last_play_date": ""}

static func get_daily_streak(profile: Dictionary) -> int:
    return int(get_streak(profile).get("daily_streak", 0))

static func get_best_streak(profile: Dictionary) -> int:
    return int(get_streak(profile).get("best_streak", 0))
```

### Update Streak

```gdscript
# game/typing_profile.gd:798
static func update_daily_streak(profile: Dictionary) -> Dictionary:
    var streak: Dictionary = get_streak(profile)
    var today: String = _get_today_date()
    var last_play: String = streak.get("last_play_date", "")
    var current_streak: int = int(streak.get("daily_streak", 0))
    var best_streak: int = int(streak.get("best_streak", 0))
    var streak_broken: bool = false
    var streak_extended: bool = false

    if last_play == today:
        # Already played today
        return {"ok": true, "profile": profile, "streak": current_streak, "changed": false}

    if _is_yesterday(last_play):
        # Consecutive day - extend streak
        current_streak += 1
        streak_extended = true
    elif last_play.is_empty():
        # First time playing
        current_streak = 1
        streak_extended = true
    else:
        # Streak broken (missed a day)
        streak_broken = current_streak > 1
        current_streak = 1

    # Update best streak
    if current_streak > best_streak:
        best_streak = current_streak

    # Update profile
    profile["streak"] = {
        "daily_streak": current_streak,
        "best_streak": best_streak,
        "last_play_date": today
    }

    return {
        "ok": true,
        "profile": profile,
        "streak": current_streak,
        "best_streak": best_streak,
        "extended": streak_extended,
        "broken": streak_broken,
        "changed": true
    }
```

### Date Helpers

```gdscript
# game/typing_profile.gd:783
static func _get_today_date() -> String:
    var dt: Dictionary = Time.get_date_dict_from_system()
    return "%04d-%02d-%02d" % [dt.year, dt.month, dt.day]

static func _is_yesterday(date_str: String) -> bool:
    if date_str.is_empty():
        return false
    var today: String = _get_today_date()
    var today_unix: int = Time.get_unix_time_from_datetime_string(today + "T00:00:00")
    var date_unix: int = Time.get_unix_time_from_datetime_string(date_str + "T00:00:00")
    var diff_days: int = (today_unix - date_unix) / 86400
    return diff_days == 1
```

## Integration Example

```gdscript
# In game controller or main
func _ready() -> void:
    var result: Dictionary = TypingProfile.load_profile()
    if not result.get("ok", false):
        push_error(result.get("error", "Unknown error"))
        profile = TypingProfile.default_profile()
    else:
        profile = result.get("profile", {})

    # Update streak
    var streak_result: Dictionary = TypingProfile.update_daily_streak(profile)
    if streak_result.get("extended", false):
        _show_streak_notification(streak_result.streak)
    elif streak_result.get("broken", false):
        _show_streak_broken_notification()

    # Apply UI preferences
    var scale: int = TypingProfile.get_ui_scale_percent(profile)
    _apply_ui_scale(scale)

    var reduced_motion: bool = TypingProfile.get_reduced_motion(profile)
    _apply_reduced_motion(reduced_motion)

func _on_wave_complete(report: Dictionary) -> void:
    var lesson_id: String = TypingProfile.get_lesson(profile)
    var goal_met: bool = PracticeGoals.check_goal_met(report, TypingProfile.get_goal(profile))

    var progress_map: Dictionary = TypingProfile.get_lesson_progress_map(profile)
    progress_map = TypingProfile.update_lesson_progress(progress_map, lesson_id, report, goal_met)
    profile["lesson_progress"] = progress_map

    # Update lifetime stats
    TypingProfile.increment_lifetime_stat(profile, "nights")
    TypingProfile.increment_lifetime_stat(profile, "enemies_defeated", report.get("enemies_killed", 0))
    TypingProfile.update_best_stat(profile, "best_combo", report.get("max_combo", 0))
    TypingProfile.update_best_stat(profile, "best_wpm", report.get("wpm", 0.0))

    # Check achievements
    if report.get("max_combo", 0) >= 5:
        TypingProfile.unlock_achievement(profile, "combo_starter")
    if report.get("max_combo", 0) >= 20:
        TypingProfile.unlock_achievement(profile, "combo_master")

    TypingProfile.save_profile(profile)
```

## Testing

```gdscript
func test_profile_load_save():
    var profile: Dictionary = TypingProfile.default_profile()
    profile["practice_goal"] = "accuracy"

    var save_result: Dictionary = TypingProfile.save_profile(profile, "user://test_profile.json")
    assert(save_result.get("ok", false))

    var load_result: Dictionary = TypingProfile.load_profile("user://test_profile.json")
    assert(load_result.get("ok", false))
    assert(load_result.get("profile", {}).get("practice_goal", "") == "accuracy")

    _pass("test_profile_load_save")

func test_achievement_unlock():
    var profile: Dictionary = TypingProfile.default_profile()
    assert(not TypingProfile.is_achievement_unlocked(profile, "first_blood"))

    var result: Dictionary = TypingProfile.unlock_achievement(profile, "first_blood")
    assert(result.get("ok", false))
    assert(result.get("newly_unlocked", false))

    assert(TypingProfile.is_achievement_unlocked(profile, "first_blood"))

    # Unlock again should return already_unlocked
    result = TypingProfile.unlock_achievement(profile, "first_blood")
    assert(result.get("already_unlocked", false))

    _pass("test_achievement_unlock")

func test_streak_tracking():
    var profile: Dictionary = TypingProfile.default_profile()

    # First play
    var result: Dictionary = TypingProfile.update_daily_streak(profile)
    assert(result.get("streak", 0) == 1)
    assert(result.get("extended", false))

    _pass("test_streak_tracking")

func test_ui_scale_normalization():
    assert(TypingProfile._normalize_ui_scale(100) == 100)
    assert(TypingProfile._normalize_ui_scale(85) == 80)
    assert(TypingProfile._normalize_ui_scale(115) == 120)
    assert(TypingProfile._normalize_ui_scale(50) == 80)
    assert(TypingProfile._normalize_ui_scale(200) == 140)

    _pass("test_ui_scale_normalization")
```

## API Quick Reference

| Category | Function | Purpose |
|----------|----------|---------|
| **Core** | `load_profile(path)` | Load profile from disk |
| | `save_profile(profile, path)` | Save profile to disk |
| | `default_profile()` | Get default profile structure |
| **Goals** | `get_goal(profile)` | Get practice goal ID |
| | `set_goal(profile, goal_id)` | Set practice goal |
| **Lessons** | `get_lesson(profile)` | Get preferred lesson ID |
| | `set_lesson(profile, lesson_id)` | Set preferred lesson |
| **Keybinds** | `get_keybind(profile, action)` | Get keybind for action |
| | `set_keybind(profile, action, bind)` | Set keybind for action |
| **UI Prefs** | `get_ui_scale_percent(profile)` | Get UI scale (80-140) |
| | `set_ui_scale_percent(profile, val)` | Set UI scale |
| | `get_speed_multiplier(profile)` | Get game speed (0.5-2.0) |
| | `cycle_speed_multiplier(profile, dir)` | Cycle through speed values |
| **Progress** | `get_lesson_progress_map(profile)` | Get all lesson progress |
| | `update_lesson_progress(map, ...)` | Update lesson progress |
| **Achievements** | `is_achievement_unlocked(profile, id)` | Check if achievement unlocked |
| | `unlock_achievement(profile, id)` | Unlock an achievement |
| | `get_achievement_count(profile)` | Get unlocked/total counts |
| **Lifetime** | `get_lifetime_stat(profile, stat)` | Get lifetime stat value |
| | `increment_lifetime_stat(profile, stat)` | Increment stat by 1 |
| | `update_best_stat(profile, stat, val)` | Update if new value is higher |
| **Streak** | `get_daily_streak(profile)` | Get current streak |
| | `update_daily_streak(profile)` | Update streak for today |
| **Onboarding** | `get_onboarding(profile)` | Get onboarding state |
| | `complete_onboarding(profile)` | Mark onboarding complete |
| | `reset_onboarding(profile)` | Reset onboarding |
