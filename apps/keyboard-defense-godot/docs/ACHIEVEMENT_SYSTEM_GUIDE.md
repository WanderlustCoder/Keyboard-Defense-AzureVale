# Achievement System Guide

This document explains the achievement checking and unlocking system in Keyboard Defense.

## Overview

The achievement system monitors gameplay events and unlocks achievements:

```
Gameplay Event → Check Conditions → Unlock Achievement → Emit Signal
       ↓               ↓                   ↓                  ↓
  enemy_killed    combo >= 20        update profile      show popup
```

## Achievement Checker

### Initialization

```gdscript
# game/achievement_checker.gd:12
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
    _story_data = json.data
    _achievements_cache = _story_data.get("achievements", {})
```

### Signal

```gdscript
signal achievement_unlocked(achievement_id: String, achievement_data: Dictionary)
```

Emitted when an achievement is newly unlocked.

## Achievement Checks

### First Blood

```gdscript
# game/achievement_checker.gd:38
func check_first_blood(profile: Dictionary, enemies_defeated: int) -> Dictionary:
    if enemies_defeated >= 1:
        return TypingProfile.unlock_achievement(profile, "first_blood")
    return {"ok": true, "profile": profile}
```

Triggered: First enemy killed.

### Combo Achievements

```gdscript
# game/achievement_checker.gd:44
func check_combo(profile: Dictionary, combo: int) -> Dictionary:
    var result: Dictionary = {"ok": true, "profile": profile}

    # Update best combo stat
    TypingProfile.update_best_stat(profile, "best_combo", combo)

    # combo_starter: 5+ combo
    if combo >= 5 and not TypingProfile.is_achievement_unlocked(profile, "combo_starter"):
        result = TypingProfile.unlock_achievement(profile, "combo_starter")
        if result.get("newly_unlocked", false):
            achievement_unlocked.emit("combo_starter", get_achievement_info("combo_starter"))
        profile = result.get("profile", profile)

    # combo_master: 20+ combo
    if combo >= 20 and not TypingProfile.is_achievement_unlocked(profile, "combo_master"):
        result = TypingProfile.unlock_achievement(profile, "combo_master")
        if result.get("newly_unlocked", false):
            achievement_unlocked.emit("combo_master", get_achievement_info("combo_master"))
        profile = result.get("profile", profile)

    return {"ok": true, "profile": profile}
```

| Achievement | Threshold |
|-------------|-----------|
| `combo_starter` | 5+ combo |
| `combo_master` | 20+ combo |

### Speed Demon

```gdscript
# game/achievement_checker.gd:67
func check_wpm(profile: Dictionary, wpm: float) -> Dictionary:
    TypingProfile.update_best_stat(profile, "best_wpm", wpm)

    if wpm >= 60.0 and not TypingProfile.is_achievement_unlocked(profile, "speed_demon"):
        var result := TypingProfile.unlock_achievement(profile, "speed_demon")
        if result.get("newly_unlocked", false):
            achievement_unlocked.emit("speed_demon", get_achievement_info("speed_demon"))
        return result
    return {"ok": true, "profile": profile}
```

Triggered: WPM >= 60 during a wave.

### Perfectionist

```gdscript
# game/achievement_checker.gd:80
func check_perfect_wave(profile: Dictionary, accuracy: float) -> Dictionary:
    if accuracy >= 1.0 and not TypingProfile.is_achievement_unlocked(profile, "perfectionist"):
        var result := TypingProfile.unlock_achievement(profile, "perfectionist")
        if result.get("newly_unlocked", false):
            achievement_unlocked.emit("perfectionist", get_achievement_info("perfectionist"))
        return result
    return {"ok": true, "profile": profile}
```

Triggered: 100% accuracy on a wave.

### Defender

```gdscript
# game/achievement_checker.gd:90
func check_defender(profile: Dictionary, damage_taken: int) -> Dictionary:
    if damage_taken == 0 and not TypingProfile.is_achievement_unlocked(profile, "defender"):
        var result := TypingProfile.unlock_achievement(profile, "defender")
        if result.get("newly_unlocked", false):
            achievement_unlocked.emit("defender", get_achievement_info("defender"))
        return result
    return {"ok": true, "profile": profile}
```

Triggered: Complete a wave without taking damage.

### Survivor

```gdscript
# game/achievement_checker.gd:100
func check_survivor(profile: Dictionary, hp_remaining: int, won: bool) -> Dictionary:
    if won and hp_remaining == 1 and not TypingProfile.is_achievement_unlocked(profile, "survivor"):
        var result := TypingProfile.unlock_achievement(profile, "survivor")
        if result.get("newly_unlocked", false):
            achievement_unlocked.emit("survivor", get_achievement_info("survivor"))
        return result
    return {"ok": true, "profile": profile}
```

Triggered: Win a wave with exactly 1 HP remaining.

### Boss Achievements

```gdscript
# game/achievement_checker.gd:109
func check_boss_defeated(profile: Dictionary, boss_kind: String) -> Dictionary:
    TypingProfile.increment_lifetime_stat(profile, "bosses_defeated")

    # First boss kill
    if not TypingProfile.is_achievement_unlocked(profile, "boss_slayer"):
        var result := TypingProfile.unlock_achievement(profile, "boss_slayer")
        if result.get("newly_unlocked", false):
            achievement_unlocked.emit("boss_slayer", get_achievement_info("boss_slayer"))
        profile = result.get("profile", profile)

    # Void Tyrant specifically
    if boss_kind == "void_tyrant" and not TypingProfile.is_achievement_unlocked(profile, "void_vanquisher"):
        var result := TypingProfile.unlock_achievement(profile, "void_vanquisher")
        if result.get("newly_unlocked", false):
            achievement_unlocked.emit("void_vanquisher", get_achievement_info("void_vanquisher"))
        profile = result.get("profile", profile)

    return {"ok": true, "profile": profile}
```

| Achievement | Condition |
|-------------|-----------|
| `boss_slayer` | Defeat any boss |
| `void_vanquisher` | Defeat the Void Tyrant |

### Lesson Mastery

```gdscript
# game/achievement_checker.gd:132
func check_lesson_mastery(profile: Dictionary, lessons_mastered: Array) -> Dictionary:
    # Home row mastery
    var home_row_lessons := ["home_row_1", "home_row_2", "home_row_words"]
    var home_row_complete := true
    for lesson_id in home_row_lessons:
        if not lessons_mastered.has(lesson_id):
            home_row_complete = false
            break

    if home_row_complete and not TypingProfile.is_achievement_unlocked(profile, "home_row_master"):
        result = TypingProfile.unlock_achievement(profile, "home_row_master")
        # ...

    # Alphabet scholar
    if lessons_mastered.has("full_alpha"):
        # Unlock alphabet_scholar

    # Number cruncher
    var number_lessons := ["numbers_1", "numbers_2"]
    # Check completion...

    # Keyboard master (12+ lessons)
    if lessons_mastered.size() >= 12:
        # Unlock keyboard_master

    return {"ok": true, "profile": profile}
```

| Achievement | Condition |
|-------------|-----------|
| `home_row_master` | Complete home_row_1, home_row_2, home_row_words |
| `alphabet_scholar` | Complete full_alpha lesson |
| `number_cruncher` | Complete numbers_1, numbers_2 |
| `keyboard_master` | Master 12+ lessons |

## Event Handlers

### Enemy Defeated

```gdscript
# game/achievement_checker.gd:184
func on_enemy_defeated(profile: Dictionary, is_boss: bool = false, boss_kind: String = "") -> Dictionary:
    # Increment lifetime stat
    TypingProfile.increment_lifetime_stat(profile, "enemies_defeated")
    var enemies_defeated: int = int(TypingProfile.get_lifetime_stat(profile, "enemies_defeated"))

    # Check first blood
    var result := check_first_blood(profile, enemies_defeated)
    if result.get("newly_unlocked", false):
        achievement_unlocked.emit("first_blood", get_achievement_info("first_blood"))
    profile = result.get("profile", profile)

    # Check boss achievements
    if is_boss and boss_kind != "":
        result = check_boss_defeated(profile, boss_kind)
        profile = result.get("profile", profile)

    return {"ok": true, "profile": profile}
```

### Wave Complete

```gdscript
# game/achievement_checker.gd:205
func on_wave_complete(profile: Dictionary, stats: Dictionary) -> Dictionary:
    var accuracy: float = float(stats.get("accuracy", 0.0))
    var wpm: float = float(stats.get("wpm", 0.0))
    var damage_taken: int = int(stats.get("damage_taken", 0))
    var hp_remaining: int = int(stats.get("hp_remaining", 0))
    var won: bool = bool(stats.get("won", false))
    var combo: int = int(stats.get("best_combo", 0))

    check_perfect_wave(profile, accuracy)
    check_wpm(profile, wpm)
    check_defender(profile, damage_taken)
    check_survivor(profile, hp_remaining, won)
    check_combo(profile, combo)

    return {"ok": true, "profile": profile}
```

**Stats Dictionary:**
```gdscript
{
    "accuracy": 0.95,        # 0.0 - 1.0
    "wpm": 55.0,
    "damage_taken": 2,
    "hp_remaining": 8,
    "won": true,
    "best_combo": 12
}
```

## Achievement Data

### Accessing Achievement Info

```gdscript
# game/achievement_checker.gd:30
func get_achievement_info(achievement_id: String) -> Dictionary:
    return _achievements_cache.get(achievement_id, {})

func get_all_achievement_info() -> Dictionary:
    return _achievements_cache.duplicate(true)
```

### story.json Format

```json
{
  "achievements": {
    "first_blood": {
      "name": "First Blood",
      "description": "Defeat your first enemy",
      "icon": "sword",
      "points": 10
    },
    "combo_starter": {
      "name": "Combo Starter",
      "description": "Achieve a 5-hit combo",
      "icon": "flame",
      "points": 25
    }
  }
}
```

## Achievement List

| ID | Name | Condition | Points |
|----|------|-----------|--------|
| `first_blood` | First Blood | Defeat 1 enemy | 10 |
| `combo_starter` | Combo Starter | 5+ combo | 25 |
| `combo_master` | Combo Master | 20+ combo | 50 |
| `speed_demon` | Speed Demon | 60+ WPM | 50 |
| `perfectionist` | Perfectionist | 100% accuracy wave | 50 |
| `defender` | Defender | No damage wave | 50 |
| `survivor` | Survivor | Win at 1 HP | 75 |
| `boss_slayer` | Boss Slayer | Beat any boss | 100 |
| `void_vanquisher` | Void Vanquisher | Beat Void Tyrant | 200 |
| `home_row_master` | Home Row Master | Complete home row lessons | 50 |
| `alphabet_scholar` | Alphabet Scholar | Complete full_alpha | 75 |
| `number_cruncher` | Number Cruncher | Complete number lessons | 50 |
| `keyboard_master` | Keyboard Master | Master 12+ lessons | 150 |

## Integration Examples

### Combat Controller Integration

```gdscript
var achievement_checker := AchievementChecker.new()

func _ready() -> void:
    achievement_checker.achievement_unlocked.connect(_on_achievement_unlocked)

func _on_enemy_killed(enemy: Dictionary) -> void:
    var is_boss: bool = enemy.get("is_boss", false)
    var boss_kind: String = str(enemy.get("kind", ""))
    achievement_checker.on_enemy_defeated(profile, is_boss, boss_kind)

func _on_wave_ended(stats: Dictionary) -> void:
    achievement_checker.on_wave_complete(profile, stats)
    _save_profile()

func _on_achievement_unlocked(achievement_id: String, data: Dictionary) -> void:
    var popup := AchievementPopup.new()
    popup.show_achievement(data.get("name", ""), data.get("description", ""))
    add_child(popup)
```

### Lesson Completion

```gdscript
func _on_lesson_completed(lesson_id: String) -> void:
    if not profile.lessons_mastered.has(lesson_id):
        profile.lessons_mastered.append(lesson_id)
    achievement_checker.check_lesson_mastery(profile, profile.lessons_mastered)
```

### Achievement Display

```gdscript
func _show_achievements_panel() -> void:
    var all_achievements := achievement_checker.get_all_achievement_info()

    for achievement_id in all_achievements:
        var data: Dictionary = all_achievements[achievement_id]
        var unlocked: bool = TypingProfile.is_achievement_unlocked(profile, achievement_id)

        var item := AchievementListItem.new()
        item.setup(
            data.get("name", ""),
            data.get("description", ""),
            unlocked,
            int(data.get("points", 0))
        )
        achievement_list.add_child(item)
```

## Testing

```gdscript
func test_first_blood():
    var checker := AchievementChecker.new()
    var profile := TypingProfile.create_default()

    var result := checker.check_first_blood(profile, 0)
    assert(not TypingProfile.is_achievement_unlocked(profile, "first_blood"))

    result = checker.check_first_blood(profile, 1)
    assert(TypingProfile.is_achievement_unlocked(result.profile, "first_blood"))

    _pass("test_first_blood")

func test_combo_tiers():
    var checker := AchievementChecker.new()
    var profile := TypingProfile.create_default()

    checker.check_combo(profile, 4)
    assert(not TypingProfile.is_achievement_unlocked(profile, "combo_starter"))

    checker.check_combo(profile, 5)
    assert(TypingProfile.is_achievement_unlocked(profile, "combo_starter"))
    assert(not TypingProfile.is_achievement_unlocked(profile, "combo_master"))

    checker.check_combo(profile, 20)
    assert(TypingProfile.is_achievement_unlocked(profile, "combo_master"))

    _pass("test_combo_tiers")

func test_wave_complete():
    var checker := AchievementChecker.new()
    var profile := TypingProfile.create_default()

    var perfect_stats := {
        "accuracy": 1.0,
        "wpm": 65.0,
        "damage_taken": 0,
        "hp_remaining": 1,
        "won": true,
        "best_combo": 25
    }

    checker.on_wave_complete(profile, perfect_stats)

    assert(TypingProfile.is_achievement_unlocked(profile, "perfectionist"))
    assert(TypingProfile.is_achievement_unlocked(profile, "speed_demon"))
    assert(TypingProfile.is_achievement_unlocked(profile, "defender"))
    assert(TypingProfile.is_achievement_unlocked(profile, "survivor"))
    assert(TypingProfile.is_achievement_unlocked(profile, "combo_master"))

    _pass("test_wave_complete")
```
