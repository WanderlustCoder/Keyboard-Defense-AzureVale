# Story & Progression Guide

This document explains the narrative system, act progression, boss encounters, dialogue triggers, and performance feedback in Keyboard Defense.

## Overview

The story system provides narrative context and feedback:

```
Day → Act Lookup → Boss Check → Dialogue → Performance Feedback → Encouragement
 ↓        ↓            ↓           ↓              ↓                    ↓
 5    "Act II"    day == 7?    get lines    accuracy/speed/combo    milestones
```

## Story Data Structure

### Data File

Story content is loaded from `res://data/story.json`:

```gdscript
# game/story_manager.gd
const STORY_PATH := "res://data/story.json"

static func load_data() -> Dictionary:
    if not _cache.is_empty():
        return _cache
    var file: FileAccess = FileAccess.open(STORY_PATH, FileAccess.READ)
    var text: String = file.get_as_text()
    var parsed: Variant = JSON.parse_string(text)
    _cache = {"ok": true, "error": "", "data": parsed}
    return _cache
```

### Story JSON Schema

```json
{
  "acts": [
    {
      "id": "act_1",
      "name": "The Siege Begins",
      "days": [1, 7],
      "intro_text": "The Typhos Horde approaches...",
      "completion_text": "You've survived the first week!",
      "mentor": {"name": "Elder Lyra"},
      "boss": {"day": 7, "kind": "warlord", "lore": "..."},
      "reward": "unlock_tower_slow"
    }
  ],
  "dialogue": {
    "welcome": {
      "speaker": "Elder Lyra",
      "lines": ["Welcome, scribe.", "The kingdom needs you."]
    }
  },
  "typing_tips": {
    "accuracy": ["Focus on clean keystrokes..."],
    "speed": ["Build rhythm with common words..."]
  },
  "performance_feedback": {
    "accuracy": {
      "excellent": {"threshold": 95, "messages": ["Perfect precision!"]},
      "good": {"threshold": 85, "messages": ["Solid accuracy."]}
    }
  },
  "encouragement": {
    "streak_broken": ["Don't worry, try again!"],
    "milestone_wpm": {"40": "You hit 40 WPM!"}
  }
}
```

## Act System

### Getting Current Act

```gdscript
# game/story_manager.gd:35
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
```

### Act by ID

```gdscript
# game/story_manager.gd:49
static func get_act_by_id(act_id: String) -> Dictionary:
    var acts: Array = get_acts()
    for act in acts:
        if str(act.get("id", "")) == act_id:
            return act
    return {}
```

### Act Progress

```gdscript
# game/story_manager.gd:84
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
```

### Act Intro Detection

```gdscript
# game/story_manager.gd:145
static func should_show_act_intro(day: int, last_intro_day: int) -> bool:
    var act: Dictionary = get_act_for_day(day)
    if act.is_empty():
        return false
    var days: Array = act.get("days", [0, 0])
    var start: int = int(days[0]) if days.size() >= 1 else 0
    # Show intro on first day of act if we haven't shown it yet
    return day == start and last_intro_day < start
```

## Boss System

### Boss Day Check

```gdscript
# game/story_manager.gd:56
static func is_boss_day(day: int) -> bool:
    var act: Dictionary = get_act_for_day(day)
    if act.is_empty():
        return false
    var boss: Dictionary = act.get("boss", {})
    return int(boss.get("day", -1)) == day
```

### Get Boss Info

```gdscript
# game/story_manager.gd:63
static func get_boss_for_day(day: int) -> Dictionary:
    var act: Dictionary = get_act_for_day(day)
    if act.is_empty():
        return {}
    var boss: Dictionary = act.get("boss", {})
    if int(boss.get("day", -1)) == day:
        return boss
    return {}
```

### Boss Lore

```gdscript
# game/story_manager.gd:463
static func get_boss_lore(day: int) -> String:
    var boss: Dictionary = get_boss_for_day(day)
    if boss.is_empty():
        return ""
    return str(boss.get("lore", ""))
```

## Dialogue System

### Getting Dialogue

```gdscript
# game/story_manager.gd:101
static func get_dialogue(dialogue_key: String) -> Dictionary:
    var data: Dictionary = load_data()
    if not data.get("ok", false):
        return {}
    var dialogue_map: Dictionary = data.get("data", {}).get("dialogue", {})
    if dialogue_map.has(dialogue_key):
        return dialogue_map[dialogue_key]
    return {}
```

### Dialogue Lines with Substitutions

```gdscript
# game/story_manager.gd:110
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
```

Usage:
```gdscript
var lines := StoryManager.get_dialogue_lines("welcome", {"player_name": "Hero"})
# Replaces {player_name} with "Hero" in all lines
```

### Dialogue Speaker

```gdscript
# game/story_manager.gd:121
static func get_dialogue_speaker(dialogue_key: String) -> String:
    var dialogue: Dictionary = get_dialogue(dialogue_key)
    return str(dialogue.get("speaker", ""))
```

### Enemy Taunts

```gdscript
# game/story_manager.gd:132
static func get_enemy_taunt(enemy_kind: String) -> String:
    var data: Dictionary = load_data()
    var taunts: Dictionary = data.get("data", {}).get("enemy_taunts", {})
    var kind_taunts: Array = taunts.get(enemy_kind, [])
    if kind_taunts.is_empty():
        kind_taunts = taunts.get("raider", ["..."])  # Fallback
    if kind_taunts.is_empty():
        return ""
    return str(kind_taunts[randi() % kind_taunts.size()])
```

## Performance Feedback

### Accuracy Feedback

```gdscript
# game/story_manager.gd:232
static func get_accuracy_feedback(accuracy_percent: float) -> String:
    var feedback: Dictionary = data.get("performance_feedback", {}).get("accuracy", {})

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
```

Thresholds:
| Level | Threshold | Example Message |
|-------|-----------|-----------------|
| excellent | 95% | "Perfect precision!" |
| good | 85% | "Solid accuracy." |
| needs_work | 70% | "Keep practicing." |
| struggling | 0% | "Focus on accuracy." |

### Speed Feedback

```gdscript
# game/story_manager.gd:249
static func get_speed_feedback(wpm: float) -> String:
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
```

### Combo Feedback

```gdscript
# game/story_manager.gd:266
static func get_combo_feedback(combo: int) -> String:
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
```

## Encouragement Messages

### Streak Broken

```gdscript
# game/story_manager.gd:284
static func get_streak_broken_message() -> String:
    var messages: Array = data.get("encouragement", {}).get("streak_broken", [])
    if messages.is_empty():
        return ""
    return str(messages[randi() % messages.size()])
```

### WPM Milestones

```gdscript
# game/story_manager.gd:293
static func get_wpm_milestone_message(wpm: int) -> String:
    var milestones: Dictionary = data.get("encouragement", {}).get("milestone_wpm", {})

    var milestone_values: Array[int] = [100, 80, 70, 60, 50, 40, 30, 20]
    for m in milestone_values:
        if wpm >= m:
            var key: String = str(m)
            if milestones.has(key):
                return str(milestones[key])
            break
    return ""
```

### Combo Milestones

```gdscript
# game/story_manager.gd:425
static func get_combo_milestone_message(combo: int) -> String:
    var milestones: Dictionary = data.get("encouragement", {}).get("milestone_combo", {})

    var combo_thresholds: Array[int] = [50, 30, 20, 10]
    for threshold in combo_thresholds:
        if combo >= threshold:
            var key: String = str(threshold)
            if milestones.has(key):
                return str(milestones[key])
            break
    return ""
```

### Daily Streak

```gdscript
# game/story_manager.gd:410
static func get_daily_streak_message(days: int) -> String:
    var streaks: Dictionary = data.get("encouragement", {}).get("daily_streak", {})

    var streak_thresholds: Array[int] = [100, 30, 14, 7, 3]
    for threshold in streak_thresholds:
        if days >= threshold:
            var key: String = str(threshold)
            if streaks.has(key):
                return str(streaks[key])
            break
    return ""
```

## Typing Tips

### Category Tips

```gdscript
# game/story_manager.gd:198
static func get_typing_tips(category: String) -> Array[String]:
    var tips: Dictionary = data.get("typing_tips", {})
    var raw_tips: Array = tips.get(category, [])
    var result: Array[String] = []
    for tip in raw_tips:
        result.append(str(tip))
    return result
```

### Random Tip

```gdscript
# game/story_manager.gd:209
static func get_random_typing_tip(category: String = "") -> String:
    var tips: Dictionary = data.get("typing_tips", {})

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
```

## Lesson Introductions

### Get Lesson Intro

```gdscript
# game/story_manager.gd:174
static func get_lesson_intro(lesson_id: String) -> Dictionary:
    var intros: Dictionary = data.get("lesson_introductions", {})
    return intros.get(lesson_id, {})

static func get_lesson_intro_lines(lesson_id: String) -> Array[String]:
    var intro: Dictionary = get_lesson_intro(lesson_id)
    var raw_lines: Array = intro.get("lines", [])
    var result: Array[String] = []
    for line in raw_lines:
        result.append(str(line))
    return result
```

### Finger Guide

```gdscript
# game/story_manager.gd:189
static func get_lesson_finger_guide(lesson_id: String) -> Dictionary:
    var intro: Dictionary = get_lesson_intro(lesson_id)
    return intro.get("finger_guide", {})
```

## Finger Assignments

### Get Finger for Key

```gdscript
# game/story_manager.gd:310
static func get_finger_for_key(key: String) -> String:
    var assignments: Dictionary = data.get("finger_assignments", {})

    var lower_key: String = key.to_lower()
    for finger_id in assignments.keys():
        var finger_data: Dictionary = assignments[finger_id]
        var keys: Array = finger_data.get("keys", [])
        if keys.has(lower_key):
            return str(finger_data.get("name", ""))
    return ""
```

### Finger Color

```gdscript
# game/story_manager.gd:324
static func get_finger_color_for_key(key: String) -> String:
    var assignments: Dictionary = data.get("finger_assignments", {})

    var lower_key: String = key.to_lower()
    for finger_id in assignments.keys():
        var finger_data: Dictionary = assignments[finger_id]
        var keys: Array = finger_data.get("keys", [])
        if keys.has(lower_key):
            return str(finger_data.get("color", "#FFFFFF"))
    return "#FFFFFF"
```

## Lore & Characters

### Kingdom Lore

```gdscript
# game/story_manager.gd:361
static func get_kingdom_lore() -> Dictionary:
    return get_lore("kingdom")

static func get_horde_lore() -> Dictionary:
    return get_lore("typhos_horde")
```

### Character Info

```gdscript
# game/story_manager.gd:367
static func get_character_info(character_id: String) -> Dictionary:
    var characters: Dictionary = data.get("lore", {}).get("characters", {})
    return characters.get(character_id, {})

static func get_character_quote(character_id: String) -> String:
    var info: Dictionary = get_character_info(character_id)
    var quotes: Array = info.get("quotes", [])
    if quotes.is_empty():
        return ""
    return str(quotes[randi() % quotes.size()])

static func get_mentor_quote() -> String:
    return get_character_quote("elder_lyra")
```

## Achievements

```gdscript
# game/story_manager.gd:385
static func get_achievement(achievement_id: String) -> Dictionary:
    var achievements: Dictionary = data.get("achievements", {})
    return achievements.get(achievement_id, {})

static func get_achievement_name(achievement_id: String) -> String:
    var achievement: Dictionary = get_achievement(achievement_id)
    return str(achievement.get("name", ""))

static func get_achievement_description(achievement_id: String) -> String:
    var achievement: Dictionary = get_achievement(achievement_id)
    return str(achievement.get("description", ""))
```

## Integration Examples

### Day Start Display

```gdscript
func _on_day_start(day: int) -> void:
    var progress := StoryManager.get_act_progress(day)

    act_label.text = progress.act_name
    day_label.text = "Day %d/%d" % [progress.day_in_act, progress.total_days]

    # Check for act intro
    if StoryManager.should_show_act_intro(day, last_intro_day):
        var intro := StoryManager.get_act_intro_text(day)
        _show_intro_dialogue(intro)
        last_intro_day = day

    # Check for boss warning
    if StoryManager.is_boss_day(day):
        var boss := StoryManager.get_boss_for_day(day)
        _show_boss_warning(boss)
```

### Wave End Feedback

```gdscript
func _on_wave_complete(stats: Dictionary) -> void:
    var accuracy: float = stats.accuracy * 100
    var wpm: float = stats.wpm
    var combo: int = stats.max_combo

    # Get contextual feedback
    var accuracy_msg := StoryManager.get_accuracy_feedback(accuracy)
    var speed_msg := StoryManager.get_speed_feedback(wpm)
    var combo_msg := StoryManager.get_combo_feedback(combo)

    # Check milestones
    var wpm_milestone := StoryManager.get_wpm_milestone_message(int(wpm))
    var combo_milestone := StoryManager.get_combo_milestone_message(combo)

    # Display feedback
    _show_feedback([accuracy_msg, speed_msg, combo_msg, wpm_milestone, combo_milestone])

    # Random typing tip
    var tip := StoryManager.get_random_typing_tip()
    tip_label.text = tip
```

### Lesson Selection

```gdscript
func _show_lesson_intro(lesson_id: String) -> void:
    var lines := StoryManager.get_lesson_intro_lines(lesson_id)
    var finger_guide := StoryManager.get_lesson_finger_guide(lesson_id)

    for line in lines:
        intro_text.text += line + "\n"

    # Show finger assignments
    for key in finger_guide.keys():
        var finger := StoryManager.get_finger_for_key(key)
        var color := StoryManager.get_finger_color_for_key(key)
        _highlight_key(key, color, finger)
```

## Testing

```gdscript
func test_act_lookup():
    var act := StoryManager.get_act_for_day(5)
    assert(not act.is_empty())
    assert(act.has("name"))

    _pass("test_act_lookup")

func test_boss_day():
    # Assuming boss on day 7
    assert(StoryManager.is_boss_day(7))
    assert(not StoryManager.is_boss_day(5))

    var boss := StoryManager.get_boss_for_day(7)
    assert(not boss.is_empty())

    _pass("test_boss_day")

func test_dialogue():
    var lines := StoryManager.get_dialogue_lines("welcome")
    assert(lines.size() > 0)

    var speaker := StoryManager.get_dialogue_speaker("welcome")
    assert(speaker != "")

    _pass("test_dialogue")

func test_substitutions():
    var lines := StoryManager.get_dialogue_lines("greeting", {"name": "Hero"})
    # Check that {name} was replaced
    for line in lines:
        assert("{name}" not in line)

    _pass("test_substitutions")

func test_performance_feedback():
    var excellent := StoryManager.get_accuracy_feedback(98.0)
    assert(excellent != "")

    var struggling := StoryManager.get_accuracy_feedback(50.0)
    assert(struggling != "")

    _pass("test_performance_feedback")

func test_typing_tips():
    var tips := StoryManager.get_typing_tips("accuracy")
    assert(tips.size() > 0)

    var random := StoryManager.get_random_typing_tip()
    assert(random != "")

    _pass("test_typing_tips")
```
