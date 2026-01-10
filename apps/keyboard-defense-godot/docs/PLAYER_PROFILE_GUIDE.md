# Player Profile & Persistence Guide

This document explains the player profile system, settings management, achievements, daily streaks, and game state persistence in Keyboard Defense.

## Overview

The persistence layer manages two distinct data stores:

| Store | File | Purpose |
|-------|------|---------|
| **Profile** | `user://profile.json` | Player preferences, achievements, lesson progress |
| **Save** | `user://savegame.json` | Current game state (resumable session) |

```
Profile (permanent)              Save (session)
├── practice_goal               ├── day
├── preferred_lesson            ├── phase
├── keybinds                    ├── resources
├── ui_prefs                    ├── structures
├── lesson_progress             ├── enemies
├── achievements                ├── threat
├── typing_history              └── ...
├── lifetime stats
└── streak
```

## Profile Structure

### Default Profile

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
            "last_play_date": ""
        }
    }
```

### UI Preferences

```gdscript
const DEFAULT_UI_PREFS := {
    "lessons_sort": "default",      # "default", "name", "recent"
    "lessons_sparkline": true,      # Show mini-charts in lesson list
    "onboarding": DEFAULT_ONBOARDING,
    "economy_note_shown": false,    # First-time economy tip shown
    "ui_scale_percent": 100,        # 80-140%
    "compact_panels": false,        # Smaller UI panels
    "reduced_motion": false,        # Accessibility: less animation
    "speed_multiplier": 1.0,        # 0.5x - 2.0x game speed
    "high_contrast": false,         # Accessibility: higher contrast
    "nav_hints": true,              # Show keyboard navigation hints
    "practice_mode": false          # No damage, unlimited practice
}
```

### Speed Multiplier Values

```gdscript
const SPEED_MULTIPLIER_VALUES := [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
const UI_SCALE_VALUES := [80, 90, 100, 110, 120, 130, 140]
```

## Keybind System

### Default Keybinds

```gdscript
const DEFAULT_CYCLE_GOAL_BIND := {"keycode": KEY_F7, "shift": false, "alt": false, "ctrl": false, "meta": false}
const DEFAULT_TOGGLE_SETTINGS_BIND := {"keycode": KEY_F1, ...}
const DEFAULT_TOGGLE_LESSONS_BIND := {"keycode": KEY_F2, ...}
const DEFAULT_TOGGLE_TREND_BIND := {"keycode": KEY_F3, ...}
const DEFAULT_TOGGLE_COMPACT_BIND := {"keycode": KEY_F4, ...}
const DEFAULT_TOGGLE_HISTORY_BIND := {"keycode": KEY_F5, ...}
const DEFAULT_TOGGLE_REPORT_BIND := {"keycode": KEY_F6, ...}
```

### Keybind Structure

```gdscript
{
    "keycode": KEY_F1,   # Godot key constant
    "shift": false,
    "alt": false,
    "ctrl": false,
    "meta": false        # Windows/Command key
}
```

### Setting Keybinds

```gdscript
# game/typing_profile.gd:172
static func set_keybind(profile: Dictionary, action_name: String, keybind: Dictionary) -> Dictionary:
    var normalized: Dictionary = _normalize_keybind(keybind, action_name)
    profile["keybinds"][action_name] = normalized
    var result: Dictionary = save_profile(profile)
    return {"ok": result.ok, "profile": profile}
```

### Keybind Serialization

Keybinds serialize to human-readable text format:

```gdscript
# Serializes to: "F1", "Shift+F2", "Ctrl+Alt+Delete"
static func _serialize_keybinds(raw: Variant) -> Dictionary:
    for key in keys:
        var canonical: String = ControlsFormatter.keybind_to_text(value)
        result[str(key)] = canonical
```

## Lesson Progress Tracking

### Progress Entry Structure

```gdscript
const DEFAULT_LESSON_PROGRESS := {
    "nights": 0,           # Total nights played with this lesson
    "goal_passes": 0,      # Times practice goal was met
    "sum_accuracy": 0.0,   # Sum for averaging
    "sum_hit_rate": 0.0,
    "sum_backspace_rate": 0.0,
    "best_accuracy": 0.0,  # Personal best
    "best_hit_rate": 0.0,
    "last_day": 0,         # Last in-game day played
    "recent": []           # Last 3 session entries
}
```

### Recent Entry Structure

```gdscript
{
    "day": 5,
    "avg_accuracy": 0.95,
    "hit_rate": 0.88,
    "backspace_rate": 0.12,
    "incomplete_rate": 0.05,
    "goal_met": true
}
```

### Updating Lesson Progress

```gdscript
# game/typing_profile.gd:423
static func update_lesson_progress(progress_map: Dictionary, lesson_id: String, report: Dictionary, goal_met: bool) -> Dictionary:
    var entry: Dictionary = progress_map.get(normalized, {})

    # Increment counters
    entry["nights"] = entry["nights"] + 1
    entry["goal_passes"] = entry["goal_passes"] + (1 if goal_met else 0)

    # Accumulate stats for averaging
    entry["sum_accuracy"] += report.get("avg_accuracy", 0.0)
    entry["sum_hit_rate"] += report.get("hit_rate", 0.0)

    # Update personal bests
    entry["best_accuracy"] = max(entry["best_accuracy"], accuracy)
    entry["best_hit_rate"] = max(entry["best_hit_rate"], hit_rate)

    # Add to recent history (max 3 entries)
    entry["recent"].insert(0, recent_entry)
    while entry["recent"].size() > 3:
        entry["recent"].pop_back()

    return result
```

## Achievement System

### Achievement IDs

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

### Achievement Entry Structure

```gdscript
{
    "unlocked": false,
    "unlocked_at": 0  # Unix timestamp, 0 if not unlocked
}
```

### Unlocking Achievements

```gdscript
# game/typing_profile.gd:678
static func unlock_achievement(profile: Dictionary, achievement_id: String) -> Dictionary:
    if not ACHIEVEMENT_IDS.has(achievement_id):
        return {"ok": false, "error": "Invalid achievement ID"}

    if is_achievement_unlocked(profile, achievement_id):
        return {"ok": true, "already_unlocked": true}

    profile["achievements"][achievement_id] = {
        "unlocked": true,
        "unlocked_at": int(Time.get_unix_time_from_system())
    }

    save_profile(profile)
    return {"ok": true, "newly_unlocked": true}
```

### Checking Achievement Status

```gdscript
# Check single achievement
var unlocked = TypingProfile.is_achievement_unlocked(profile, "first_blood")

# Get all unlocked
var unlocked_list = TypingProfile.get_unlocked_achievements(profile)

# Get progress count
var counts = TypingProfile.get_achievement_count(profile)
# {"unlocked": 5, "total": 13}
```

## Lifetime Statistics

### Stat Tracking

```gdscript
"lifetime": {
    "nights": 0,            # Total nights survived
    "defend_attempts": 0,   # Total defense attempts
    "hits": 0,              # Total successful hits
    "misses": 0,            # Total misses
    "enemies_defeated": 0,  # Total enemies killed
    "bosses_defeated": 0,   # Total bosses killed
    "best_combo": 0,        # Highest combo achieved
    "best_wpm": 0.0         # Best words per minute
}
```

### Updating Stats

```gdscript
# Increment a stat
TypingProfile.increment_lifetime_stat(profile, "enemies_defeated", 5)

# Update if better
TypingProfile.update_best_stat(profile, "best_combo", current_combo)
TypingProfile.update_best_stat(profile, "best_wpm", current_wpm)

# Get a stat
var best_combo = TypingProfile.get_lifetime_stat(profile, "best_combo")
```

## Daily Streak System

### Streak Structure

```gdscript
"streak": {
    "daily_streak": 0,      # Current consecutive days
    "best_streak": 0,       # All-time best streak
    "last_play_date": ""    # ISO date: "YYYY-MM-DD"
}
```

### Streak Update Logic

```gdscript
# game/typing_profile.gd:798
static func update_daily_streak(profile: Dictionary) -> Dictionary:
    var today: String = _get_today_date()
    var last_play: String = streak.get("last_play_date", "")

    if last_play == today:
        # Already played today
        return {"changed": false}

    if _is_yesterday(last_play):
        # Consecutive day - extend streak
        current_streak += 1
    elif last_play.is_empty():
        # First time playing
        current_streak = 1
    else:
        # Streak broken
        current_streak = 1

    # Update best if needed
    if current_streak > best_streak:
        best_streak = current_streak

    return {
        "streak": current_streak,
        "extended": true/false,
        "broken": true/false
    }
```

### Date Helpers

```gdscript
# Get today as YYYY-MM-DD
static func _get_today_date() -> String:
    var dt: Dictionary = Time.get_date_dict_from_system()
    return "%04d-%02d-%02d" % [dt.year, dt.month, dt.day]

# Check if date is yesterday
static func _is_yesterday(date_str: String) -> bool:
    var today_unix: int = Time.get_unix_time_from_datetime_string(today + "T00:00:00")
    var date_unix: int = Time.get_unix_time_from_datetime_string(date_str + "T00:00:00")
    var diff_days: int = (today_unix - date_unix) / 86400
    return diff_days == 1
```

## Onboarding System

### Onboarding State

```gdscript
const DEFAULT_ONBOARDING := {
    "enabled": true,      # Currently showing tutorial
    "completed": false,   # Ever finished tutorial
    "step": 0,            # Current step index
    "ever_shown": false   # Has tutorial ever appeared
}
```

### Managing Onboarding

```gdscript
# Get current onboarding state
var onboarding = TypingProfile.get_onboarding(profile)

# Complete onboarding
TypingProfile.complete_onboarding(profile)

# Reset to show again
TypingProfile.reset_onboarding(profile)
```

## Profile Load/Save

### Loading Profile

```gdscript
# game/typing_profile.gd:131
static func load_profile(path: String = PROFILE_PATH) -> Dictionary:
    if not FileAccess.file_exists(load_path):
        return {"ok": true, "profile": default_profile()}

    var file: FileAccess = FileAccess.open(load_path, FileAccess.READ)
    var text: String = file.get_as_text()
    var parsed: Variant = JSON.parse_string(text)

    # Merge with defaults for forward compatibility
    var profile: Dictionary = default_profile()
    profile["practice_goal"] = PracticeGoals.normalize_goal(data.get("practice_goal"))
    profile["lesson_progress"] = _merge_lesson_progress(data.get("lesson_progress", {}))
    profile["keybinds"] = _merge_keybinds(data.get("keybinds", {}))
    // ...

    return {"ok": true, "profile": profile}
```

### Saving Profile

```gdscript
# game/typing_profile.gd:462
static func save_profile(profile: Dictionary, path: String = PROFILE_PATH) -> Dictionary:
    var data: Dictionary = profile.duplicate(true)
    data["version"] = VERSION
    data["keybinds"] = _serialize_keybinds(profile.get("keybinds", {}))

    var json_text: String = JSON.stringify(data, "  ")
    var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
    file.store_string(json_text)

    return {"ok": true, "path": save_path}
```

## Game State Persistence

### Save State

```gdscript
# game/persistence.gd
static func save_state(state: GameState) -> Dictionary:
    var data: Dictionary = SimSave.state_to_dict(state)
    var json_text: String = JSON.stringify(data, "  ")
    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    file.store_string(json_text)
    return {"ok": true, "path": SAVE_PATH}
```

### Load State

```gdscript
static func load_state() -> Dictionary:
    if not FileAccess.file_exists(SAVE_PATH):
        return {"ok": false, "error": "Save file not found."}

    var text: String = file.get_as_text()
    var parsed: Variant = JSON.parse_string(text)
    var result: Dictionary = SimSave.state_from_dict(parsed)

    return {"ok": true, "state": result.state}
```

## Common Patterns

### Get/Set Setting Pattern

All settings follow this pattern:

```gdscript
# Getter
static func get_reduced_motion(profile: Dictionary) -> bool:
    if profile.has("ui_prefs"):
        return bool(profile["ui_prefs"].get("reduced_motion", false))
    return false

# Setter (auto-saves)
static func set_reduced_motion(profile: Dictionary, enabled: bool) -> Dictionary:
    profile["ui_prefs"]["reduced_motion"] = bool(enabled)
    var result: Dictionary = save_profile(profile)
    return {"ok": result.ok, "profile": profile}
```

### Merge Pattern for Forward Compatibility

When loading, merge with defaults:

```gdscript
static func _merge_ui_prefs(raw: Variant) -> Dictionary:
    var result: Dictionary = DEFAULT_UI_PREFS.duplicate(true)
    if typeof(raw) != TYPE_DICTIONARY:
        return result

    # Override with loaded values
    result["lessons_sort"] = _normalize_lessons_sort(raw.get("lessons_sort", "default"))
    result["ui_scale_percent"] = _normalize_ui_scale(raw.get("ui_scale_percent", 100))
    // ...

    return result
```

### Version Checking

```gdscript
const VERSION := 1

static func load_profile(...):
    var version: int = int(data.get("version", 1))
    if version > VERSION:
        return {"ok": false, "error": "Profile version is too new."}
    // ... handle migration for older versions
```

## Adding New Settings

### Step 1: Add to DEFAULT_UI_PREFS

```gdscript
const DEFAULT_UI_PREFS := {
    // ... existing ...
    "new_setting": false
}
```

### Step 2: Add Getter

```gdscript
static func get_new_setting(profile: Dictionary) -> bool:
    if profile.has("ui_prefs") and typeof(profile.get("ui_prefs")) == TYPE_DICTIONARY:
        return bool(profile["ui_prefs"].get("new_setting", false))
    return false
```

### Step 3: Add Setter

```gdscript
static func set_new_setting(profile: Dictionary, enabled: bool) -> Dictionary:
    if not profile.has("ui_prefs"):
        profile["ui_prefs"] = {}
    profile["ui_prefs"]["new_setting"] = bool(enabled)
    var result: Dictionary = save_profile(profile)
    return {"ok": result.ok, "profile": profile}
```

### Step 4: Add to Merge

```gdscript
static func _merge_ui_prefs(raw: Variant) -> Dictionary:
    // ...
    result["new_setting"] = bool(raw.get("new_setting", false))
    return result
```

## Adding New Achievements

### Step 1: Add to ACHIEVEMENT_IDS

```gdscript
const ACHIEVEMENT_IDS := [
    // ... existing ...
    "new_achievement"
]
```

### Step 2: Define in story.json

```json
{
  "achievements": [
    {
      "id": "new_achievement",
      "name": "New Achievement",
      "description": "How to unlock this",
      "icon": "trophy"
    }
  ]
}
```

### Step 3: Trigger in Game Code

```gdscript
# In game logic when condition met
if some_condition:
    var result = TypingProfile.unlock_achievement(profile, "new_achievement")
    if result.get("newly_unlocked", false):
        # Show achievement popup
        AudioManager.play_sfx(AudioManager.SFX.ACHIEVEMENT_UNLOCK)
```

## Testing Profiles

### Test Profile Load

```gdscript
func test_profile_load():
    var result = TypingProfile.load_profile()
    assert(result.ok, "Profile should load")
    assert(result.profile.has("version"), "Should have version")
    _pass("test_profile_load")
```

### Test Achievement Unlock

```gdscript
func test_achievement_unlock():
    var profile = TypingProfile.default_profile()
    assert(not TypingProfile.is_achievement_unlocked(profile, "first_blood"))

    var result = TypingProfile.unlock_achievement(profile, "first_blood")
    assert(result.ok)
    assert(result.newly_unlocked)
    assert(TypingProfile.is_achievement_unlocked(profile, "first_blood"))
    _pass("test_achievement_unlock")
```

### Test Streak Update

```gdscript
func test_streak_update():
    var profile = TypingProfile.default_profile()
    var result = TypingProfile.update_daily_streak(profile)
    assert(result.streak == 1, "First play should start streak at 1")
    _pass("test_streak_update")
```
