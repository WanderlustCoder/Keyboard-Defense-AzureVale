# Story Manager Guide

Narrative progression and dialogue content system.

## Overview

`StoryManager` (game/story_manager.gd) provides access to all narrative content from `data/story.json`. It handles act progression, dialogue retrieval, performance feedback, typing tips, and lore.

## Data Loading

```gdscript
const STORY_PATH := "res://data/story.json"
static var _cache: Dictionary = {}

static func load_data() -> Dictionary:
    # Returns: {"ok": bool, "error": String, "data": Dictionary}
```

Data is cached after first load for performance.

## Act System

### Getting Current Act

```gdscript
# Get act containing specified day
static func get_act_for_day(day: int) -> Dictionary

# Get act by ID
static func get_act_by_id(act_id: String) -> Dictionary

# Get all acts
static func get_acts() -> Array
```

### Act Progress

```gdscript
static func get_act_progress(day: int) -> Dictionary:
    # Returns:
    # {
    #     "act_name": String,
    #     "act_id": String,
    #     "day_in_act": int,
    #     "total_days": int,
    #     "act_number": int
    # }
```

### Act Intro/Completion

```gdscript
# Check if intro should show
static func should_show_act_intro(day: int, last_intro_day: int) -> bool

# Get intro text for current act
static func get_act_intro_text(day: int) -> String

# Get completion text
static func get_act_completion_text(day: int) -> String

# Get act reward description
static func get_act_reward(day: int) -> String
```

## Boss System

```gdscript
# Check if day has boss encounter
static func is_boss_day(day: int) -> bool

# Get boss data for day
static func get_boss_for_day(day: int) -> Dictionary
# Returns: {"name": "", "kind": "", "day": int, "lore": ""}

# Get boss lore text
static func get_boss_lore(day: int) -> String
```

## Dialogue System

### Retrieving Dialogue

```gdscript
# Get raw dialogue entry
static func get_dialogue(dialogue_key: String) -> Dictionary

# Get dialogue lines with substitutions
static func get_dialogue_lines(dialogue_key: String, substitutions: Dictionary = {}) -> Array[String]
# Example: get_dialogue_lines("welcome", {"player": "Hero"})
# Line: "Welcome, {player}!" -> "Welcome, Hero!"

# Get speaker name
static func get_dialogue_speaker(dialogue_key: String) -> String
```

### Enemy Taunts

```gdscript
static func get_enemy_taunt(enemy_kind: String) -> String
# Returns random taunt for enemy type
```

## Mentor System

```gdscript
# Get current mentor name for act
static func get_mentor_name(day: int) -> String

# Get random mentor quote
static func get_mentor_quote() -> String
```

## Lesson Introductions

```gdscript
# Get full lesson intro data
static func get_lesson_intro(lesson_id: String) -> Dictionary

# Get intro dialogue lines
static func get_lesson_intro_lines(lesson_id: String) -> Array[String]

# Get finger guide for lesson
static func get_lesson_finger_guide(lesson_id: String) -> Dictionary

# Get lesson title
static func get_lesson_title(lesson_id: String) -> String

# Get practice tips for lesson
static func get_lesson_practice_tips(lesson_id: String) -> Array[String]

# Get random tip (lesson-specific or general)
static func get_random_lesson_tip(lesson_id: String) -> String
```

## Typing Tips

```gdscript
# Get tips by category
static func get_typing_tips(category: String) -> Array[String]
# Categories: "posture", "rhythm", "accuracy", "speed"

# Get random tip (from specific category or all)
static func get_random_typing_tip(category: String = "") -> String
```

## Performance Feedback

### Accuracy Feedback

```gdscript
static func get_accuracy_feedback(accuracy_percent: float) -> String
# Thresholds: excellent (95+), good (85+), needs_work (70+), struggling (<70)
```

### Speed Feedback

```gdscript
static func get_speed_feedback(wpm: float) -> String
# Thresholds: blazing (80+), fast (60+), good (40+), moderate (25+), learning (<25)
```

### Combo Feedback

```gdscript
static func get_combo_feedback(combo: int) -> String
# Thresholds: legendary (50+), amazing (30+), great (20+), building (10+)
```

## Encouragement Messages

### Milestone Messages

```gdscript
# WPM milestones
static func get_wpm_milestone_message(wpm: int) -> String
# Milestones: 100, 80, 70, 60, 50, 40, 30, 20

# Combo milestones
static func get_combo_milestone_message(combo: int) -> String
# Milestones: 50, 30, 20, 10

# Accuracy milestones
static func get_accuracy_milestone_message(accuracy: int) -> String
# Milestones: 100, 98, 95
```

### Streak Messages

```gdscript
# Streak broken encouragement
static func get_streak_broken_message() -> String

# Daily streak celebration
static func get_daily_streak_message(days: int) -> String
# Thresholds: 100, 30, 14, 7, 3

# Comeback message after break
static func get_comeback_message() -> String
```

## Finger Assignments

```gdscript
# Get finger name for key
static func get_finger_for_key(key: String) -> String
# Returns: "left pinky", "right index", etc.

# Get color for finger zone
static func get_finger_color_for_key(key: String) -> String
# Returns: "#RRGGBB" hex color
```

## Lore System

```gdscript
# Get lore section
static func get_lore(lore_type: String) -> Dictionary

# Convenience functions
static func get_kingdom_lore() -> Dictionary
static func get_horde_lore() -> Dictionary

# Character info
static func get_character_info(character_id: String) -> Dictionary
static func get_character_quote(character_id: String) -> String
```

## Achievement Data

```gdscript
static func get_achievement(achievement_id: String) -> Dictionary
static func get_achievement_name(achievement_id: String) -> String
static func get_achievement_description(achievement_id: String) -> String
```

## Hint System

```gdscript
# Get hint by theme
static func get_hint_for_theme(theme: String) -> String
```

## Story.json Structure

```json
{
  "acts": [
    {
      "id": "act_1",
      "name": "The Gathering Storm",
      "days": [1, 5],
      "intro_text": "...",
      "completion_text": "...",
      "reward": "New tower type unlocked",
      "mentor": {"name": "Elder Lyra"},
      "boss": {
        "name": "Warlord Grimtusk",
        "kind": "boss_warlord",
        "day": 5,
        "lore": "..."
      }
    }
  ],
  "dialogue": {
    "welcome": {
      "speaker": "Elder Lyra",
      "lines": ["Welcome to Keystonia, {player}!", "..."]
    }
  },
  "enemy_taunts": {
    "raider": ["Prepare to fall!", "..."],
    "armored": ["Your keys cannot pierce my armor!", "..."]
  },
  "lesson_introductions": {
    "home_row": {
      "title": "Home Row Basics",
      "lines": ["Let's start with the foundation...", "..."],
      "finger_guide": {"a": "left_pinky", "s": "left_ring", ...},
      "practice_tips": ["Keep your fingers curved", "..."]
    }
  },
  "typing_tips": {
    "posture": ["Sit with feet flat on floor", "..."],
    "rhythm": ["Type with a steady beat", "..."]
  },
  "performance_feedback": {
    "accuracy": {
      "excellent": {"threshold": 95, "messages": ["Perfect precision!", "..."]},
      "good": {"threshold": 85, "messages": ["Solid accuracy!", "..."]}
    },
    "speed": {...},
    "combo": {...}
  },
  "encouragement": {
    "streak_broken": ["Don't worry, everyone makes mistakes!", "..."],
    "comeback": ["Welcome back! Ready to continue?", "..."],
    "daily_streak": {"7": "A full week of practice!", ...},
    "milestone_wpm": {"50": "50 WPM! You're typing faster than most!", ...}
  },
  "finger_assignments": {
    "left_pinky": {
      "name": "left pinky",
      "color": "#FF6B6B",
      "keys": ["q", "a", "z", "1"]
    }
  },
  "lore": {
    "kingdom": {"name": "Keystonia", "history": "..."},
    "characters": {
      "elder_lyra": {
        "name": "Elder Lyra",
        "role": "Mentor",
        "quotes": ["The keyboard is mightier than the sword!", "..."]
      }
    }
  },
  "achievements": {
    "first_victory": {
      "name": "First Victory",
      "description": "Complete your first battle"
    }
  }
}
```

## Usage Examples

### Displaying Act Progress

```gdscript
var progress = StoryManager.get_act_progress(current_day)
label.text = "Act %d: %s (%d/%d)" % [
    progress.act_number,
    progress.act_name,
    progress.day_in_act,
    progress.total_days
]
```

### Performance Summary

```gdscript
var accuracy_msg = StoryManager.get_accuracy_feedback(accuracy_percent)
var speed_msg = StoryManager.get_speed_feedback(wpm)
var combo_msg = StoryManager.get_combo_feedback(best_combo)

summary_label.text = "%s\n%s\n%s" % [accuracy_msg, speed_msg, combo_msg]
```

### Lesson Introduction

```gdscript
func _show_lesson_intro(lesson_id: String) -> void:
    var lines = StoryManager.get_lesson_intro_lines(lesson_id)
    var title = StoryManager.get_lesson_title(lesson_id)
    dialogue_box.show_dialogue(title, lines)
```

## File Dependencies

- `data/story.json` - All narrative content
