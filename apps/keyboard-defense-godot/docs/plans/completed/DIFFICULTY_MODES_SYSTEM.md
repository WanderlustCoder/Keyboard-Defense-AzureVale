# Difficulty Modes System

**Version:** 1.0.0
**Last Updated:** 2026-01-09
**Status:** Implementation Ready

## Overview

The difficulty system provides multiple ways to experience Keyboard Defense, from relaxed practice sessions to punishing challenges. Difficulty affects enemy stats, typing requirements, resource availability, and unlock requirements.

---

## Core Difficulty Modes

### Story Mode (Easy)

```json
{
  "mode_id": "story",
  "name": "Story Mode",
  "icon": "book_open",
  "description": "Experience the tale of Keystonia at your own pace. Reduced pressure, forgiving mistakes.",
  "unlock_requirement": "default",
  "modifiers": {
    "enemy_health": 0.6,
    "enemy_damage": 0.5,
    "enemy_speed": 0.8,
    "wave_size": 0.7,
    "wave_delay": 1.5,
    "typing_time_bonus": 2.0,
    "error_penalty": 0.5,
    "gold_earned": 1.0,
    "xp_earned": 0.8
  },
  "features": {
    "auto_pause_between_waves": true,
    "hint_system": "aggressive",
    "retry_on_fail": "unlimited",
    "checkpoint_saves": true,
    "skip_difficult_words": true,
    "word_preview_time": 3.0,
    "typo_forgiveness": 2
  },
  "restrictions": {
    "leaderboard_eligible": false,
    "achievement_multiplier": 0.5,
    "some_achievements_locked": true
  },
  "recommended_for": "New typists, story enthusiasts, accessibility needs"
}
```

### Adventure Mode (Normal)

```json
{
  "mode_id": "adventure",
  "name": "Adventure Mode",
  "icon": "sword_shield",
  "description": "The intended experience. Balanced challenge that rewards skill improvement.",
  "unlock_requirement": "default",
  "modifiers": {
    "enemy_health": 1.0,
    "enemy_damage": 1.0,
    "enemy_speed": 1.0,
    "wave_size": 1.0,
    "wave_delay": 1.0,
    "typing_time_bonus": 1.0,
    "error_penalty": 1.0,
    "gold_earned": 1.0,
    "xp_earned": 1.0
  },
  "features": {
    "auto_pause_between_waves": false,
    "hint_system": "on_request",
    "retry_on_fail": "unlimited",
    "checkpoint_saves": true,
    "skip_difficult_words": false,
    "word_preview_time": 1.5,
    "typo_forgiveness": 1
  },
  "restrictions": {
    "leaderboard_eligible": true,
    "achievement_multiplier": 1.0,
    "some_achievements_locked": false
  },
  "recommended_for": "Most players, 40-60 WPM typists"
}
```

### Champion Mode (Hard)

```json
{
  "mode_id": "champion",
  "name": "Champion Mode",
  "icon": "crown",
  "description": "For experienced defenders. Enemies hit harder, words are trickier, margins are thin.",
  "unlock_requirement": {
    "complete_story": true,
    "typing_level": 15
  },
  "modifiers": {
    "enemy_health": 1.4,
    "enemy_damage": 1.5,
    "enemy_speed": 1.2,
    "wave_size": 1.3,
    "wave_delay": 0.8,
    "typing_time_bonus": 0.8,
    "error_penalty": 1.5,
    "gold_earned": 1.3,
    "xp_earned": 1.25
  },
  "features": {
    "auto_pause_between_waves": false,
    "hint_system": "disabled",
    "retry_on_fail": 3,
    "checkpoint_saves": false,
    "skip_difficult_words": false,
    "word_preview_time": 1.0,
    "typo_forgiveness": 0,
    "elite_spawn_rate": 1.5,
    "boss_enrage_timer": true
  },
  "restrictions": {
    "leaderboard_eligible": true,
    "leaderboard_separate": true,
    "achievement_multiplier": 1.5,
    "unlocks_champion_achievements": true
  },
  "recommended_for": "Skilled typists, 70+ WPM, challenge seekers"
}
```

### Nightmare Mode (Very Hard)

```json
{
  "mode_id": "nightmare",
  "name": "Nightmare Mode",
  "icon": "skull_flames",
  "description": "The ultimate test. One mistake can cascade into defeat. Only the fastest survive.",
  "unlock_requirement": {
    "complete_champion": true,
    "typing_level": 25,
    "defeat_boss": "nightmare_herald"
  },
  "modifiers": {
    "enemy_health": 2.0,
    "enemy_damage": 2.0,
    "enemy_speed": 1.4,
    "wave_size": 1.5,
    "wave_delay": 0.6,
    "typing_time_bonus": 0.6,
    "error_penalty": 2.0,
    "gold_earned": 1.75,
    "xp_earned": 1.5
  },
  "features": {
    "auto_pause_between_waves": false,
    "hint_system": "disabled",
    "retry_on_fail": 1,
    "checkpoint_saves": false,
    "skip_difficult_words": false,
    "word_preview_time": 0.5,
    "typo_forgiveness": 0,
    "elite_spawn_rate": 2.5,
    "boss_enrage_timer": true,
    "permadeath_option": true,
    "random_affixes": true,
    "curse_system": true
  },
  "restrictions": {
    "leaderboard_eligible": true,
    "leaderboard_separate": true,
    "achievement_multiplier": 2.0,
    "unlocks_nightmare_achievements": true,
    "exclusive_cosmetics": true
  },
  "recommended_for": "Elite typists, 100+ WPM, masochists"
}
```

### Zen Mode (Practice)

```json
{
  "mode_id": "zen",
  "name": "Zen Mode",
  "icon": "lotus",
  "description": "No pressure, no enemies, just you and the keyboard. Pure typing practice.",
  "unlock_requirement": "default",
  "modifiers": {
    "enemy_health": 0,
    "enemy_damage": 0,
    "enemy_speed": 0,
    "wave_size": 0,
    "typing_time_bonus": "infinite",
    "error_penalty": 0,
    "gold_earned": 0.25,
    "xp_earned": 0.5
  },
  "features": {
    "enemies_enabled": false,
    "endless_words": true,
    "word_selection": "custom",
    "speed_tracking": true,
    "accuracy_tracking": true,
    "finger_guide": "always_on",
    "progress_visualization": true,
    "background_music": "calm",
    "ambient_sounds": true
  },
  "practice_options": {
    "focus_keys": ["home_row", "top_row", "bottom_row", "numbers", "symbols", "custom"],
    "word_length": ["short", "medium", "long", "mixed"],
    "word_source": ["common", "lessons", "custom_list", "random"],
    "target_wpm": "user_defined",
    "session_goals": ["time", "words", "accuracy", "none"]
  },
  "restrictions": {
    "leaderboard_eligible": false,
    "achievement_multiplier": 0,
    "progression_disabled": false
  },
  "recommended_for": "Warm-up, focused practice, learning new keys"
}
```

---

## Special Difficulty Modifiers

### Hardcore Modifiers (Optional Toggles)

```json
{
  "hardcore_modifiers": [
    {
      "modifier_id": "ironman",
      "name": "Ironman",
      "description": "One life. Game over on death.",
      "effect": {
        "lives": 1,
        "no_revives": true,
        "save_deleted_on_death": true
      },
      "reward_multiplier": 1.5,
      "icon": "iron_helmet"
    },
    {
      "modifier_id": "speedrun",
      "name": "Speedrun",
      "description": "Global timer. Every second counts.",
      "effect": {
        "global_timer": true,
        "time_bonus_for_kills": true,
        "time_penalty_for_errors": true
      },
      "reward_multiplier": 1.25,
      "icon": "stopwatch"
    },
    {
      "modifier_id": "purist",
      "name": "Purist",
      "description": "No power-ups, no items, no mercy.",
      "effect": {
        "items_disabled": true,
        "power_ups_disabled": true,
        "consumables_disabled": true
      },
      "reward_multiplier": 1.4,
      "icon": "bare_hands"
    },
    {
      "modifier_id": "blind",
      "name": "Blind Typing",
      "description": "Keyboard display hidden. Trust your fingers.",
      "effect": {
        "keyboard_display": "hidden",
        "finger_guide": "disabled"
      },
      "reward_multiplier": 1.3,
      "icon": "blindfold"
    },
    {
      "modifier_id": "chaos",
      "name": "Chaos",
      "description": "Random modifiers every wave.",
      "effect": {
        "random_wave_modifiers": true,
        "modifier_pool": "all",
        "can_be_beneficial_or_harmful": true
      },
      "reward_multiplier": 1.2,
      "icon": "dice"
    },
    {
      "modifier_id": "marathon",
      "name": "Marathon",
      "description": "Double wave count. Endurance test.",
      "effect": {
        "wave_count_multiplier": 2.0,
        "no_breaks": true,
        "fatigue_system": true
      },
      "reward_multiplier": 1.6,
      "icon": "runner"
    }
  ]
}
```

### Accessibility Modifiers

```json
{
  "accessibility_modifiers": [
    {
      "modifier_id": "one_handed",
      "name": "One-Handed Mode",
      "description": "Words use only left or right hand keys.",
      "effect": {
        "word_filter": "single_hand",
        "hand_selection": "player_choice",
        "alternative_layouts": true
      },
      "no_reward_penalty": true
    },
    {
      "modifier_id": "dyslexia_friendly",
      "name": "Dyslexia Support",
      "description": "Special font, colors, and word filtering.",
      "effect": {
        "font": "opendyslexic",
        "color_coding": true,
        "avoid_similar_words": true,
        "extended_time": 1.5
      },
      "no_reward_penalty": true
    },
    {
      "modifier_id": "motor_assist",
      "name": "Motor Assist",
      "description": "Slower pace, larger targets, more forgiving input.",
      "effect": {
        "enemy_speed": 0.5,
        "input_buffer": 500,
        "double_tap_ignore": true,
        "extended_word_timeout": 3.0
      },
      "no_reward_penalty": true
    },
    {
      "modifier_id": "vision_assist",
      "name": "Vision Assist",
      "description": "High contrast, larger text, screen reader support.",
      "effect": {
        "high_contrast": true,
        "font_scale": 1.5,
        "screen_reader_enabled": true,
        "audio_cues_enhanced": true
      },
      "no_reward_penalty": true
    }
  ]
}
```

---

## Enemy Scaling Tables

### Health Scaling by Difficulty

| Enemy Type | Story | Adventure | Champion | Nightmare |
|------------|-------|-----------|----------|-----------|
| Grunt | 30 | 50 | 70 | 100 |
| Runner | 20 | 35 | 50 | 70 |
| Tank | 60 | 100 | 140 | 200 |
| Elite | 90 | 150 | 210 | 300 |
| Mini-Boss | 300 | 500 | 700 | 1000 |
| Boss | 600 | 1000 | 1400 | 2000 |

### Speed Scaling by Difficulty

| Enemy Type | Story | Adventure | Champion | Nightmare |
|------------|-------|-----------|----------|-----------|
| Grunt | 40 | 50 | 60 | 70 |
| Runner | 64 | 80 | 96 | 112 |
| Tank | 24 | 30 | 36 | 42 |
| Elite | 48 | 60 | 72 | 84 |
| Mini-Boss | 32 | 40 | 48 | 56 |
| Boss | 28 | 35 | 42 | 49 |

---

## Word Difficulty Scaling

### Word Pool by Difficulty

```json
{
  "word_pools": {
    "story": {
      "max_length": 6,
      "complexity": "simple",
      "sources": ["common_words", "lesson_vocabulary"],
      "exclude": ["technical", "obscure", "compound"],
      "repetition_allowed": true,
      "phonetic_difficulty": "low"
    },
    "adventure": {
      "max_length": 10,
      "complexity": "moderate",
      "sources": ["common_words", "lesson_vocabulary", "thematic"],
      "exclude": ["obscure"],
      "repetition_allowed": false,
      "phonetic_difficulty": "medium"
    },
    "champion": {
      "max_length": 14,
      "complexity": "challenging",
      "sources": ["all_words", "technical", "compound"],
      "exclude": [],
      "repetition_allowed": false,
      "phonetic_difficulty": "high",
      "includes_symbols": true
    },
    "nightmare": {
      "max_length": 20,
      "complexity": "extreme",
      "sources": ["all_words", "technical", "compound", "phrases"],
      "exclude": [],
      "repetition_allowed": false,
      "phonetic_difficulty": "extreme",
      "includes_symbols": true,
      "includes_numbers": true,
      "mixed_case": true
    }
  }
}
```

### Typing Time Windows

```json
{
  "typing_windows": {
    "story": {
      "base_time_per_char": 500,
      "min_time": 3000,
      "max_time": 15000,
      "bonus_time_per_correct": 200
    },
    "adventure": {
      "base_time_per_char": 300,
      "min_time": 2000,
      "max_time": 10000,
      "bonus_time_per_correct": 100
    },
    "champion": {
      "base_time_per_char": 200,
      "min_time": 1500,
      "max_time": 7000,
      "bonus_time_per_correct": 50
    },
    "nightmare": {
      "base_time_per_char": 120,
      "min_time": 1000,
      "max_time": 5000,
      "bonus_time_per_correct": 25
    }
  }
}
```

---

## Error Penalty System

### Penalty Types by Difficulty

```json
{
  "error_penalties": {
    "story": {
      "typo_damage": 0,
      "typo_time_loss": 0,
      "combo_break": false,
      "word_reset_on_error": false,
      "max_errors_per_word": 5,
      "visual_shake": "subtle"
    },
    "adventure": {
      "typo_damage": 5,
      "typo_time_loss": 200,
      "combo_break": true,
      "word_reset_on_error": false,
      "max_errors_per_word": 3,
      "visual_shake": "moderate"
    },
    "champion": {
      "typo_damage": 10,
      "typo_time_loss": 500,
      "combo_break": true,
      "word_reset_on_error": true,
      "max_errors_per_word": 2,
      "visual_shake": "intense",
      "error_attracts_enemies": true
    },
    "nightmare": {
      "typo_damage": 20,
      "typo_time_loss": 1000,
      "combo_break": true,
      "word_reset_on_error": true,
      "max_errors_per_word": 1,
      "visual_shake": "violent",
      "error_attracts_enemies": true,
      "error_buffs_enemies": true,
      "error_spawns_curse": true
    }
  }
}
```

---

## Resource Scaling

### Gold and Drop Rates

```json
{
  "resource_scaling": {
    "story": {
      "gold_per_kill": 1.0,
      "gold_per_wave": 1.2,
      "item_drop_rate": 1.3,
      "rare_drop_rate": 1.0,
      "resource_costs": 0.8
    },
    "adventure": {
      "gold_per_kill": 1.0,
      "gold_per_wave": 1.0,
      "item_drop_rate": 1.0,
      "rare_drop_rate": 1.0,
      "resource_costs": 1.0
    },
    "champion": {
      "gold_per_kill": 1.2,
      "gold_per_wave": 1.3,
      "item_drop_rate": 1.1,
      "rare_drop_rate": 1.25,
      "resource_costs": 1.0,
      "bonus_chest_chance": 1.2
    },
    "nightmare": {
      "gold_per_kill": 1.5,
      "gold_per_wave": 1.75,
      "item_drop_rate": 1.2,
      "rare_drop_rate": 1.5,
      "resource_costs": 1.0,
      "bonus_chest_chance": 1.5,
      "exclusive_drops": true
    }
  }
}
```

---

## Curse System (Nightmare Only)

### Curse Mechanics

```json
{
  "curse_system": {
    "enabled_modes": ["nightmare"],
    "acquisition": [
      "Typing errors accumulate curse",
      "Certain enemy attacks inflict curse",
      "Environmental hazards",
      "Boss mechanics"
    ],
    "curse_levels": [
      {
        "level": 1,
        "name": "Unease",
        "threshold": 10,
        "effects": {
          "typing_time_reduction": 5,
          "visual": "slight_screen_darkening"
        }
      },
      {
        "level": 2,
        "name": "Dread",
        "threshold": 25,
        "effects": {
          "typing_time_reduction": 10,
          "enemy_damage_bonus": 10,
          "visual": "screen_vignette"
        }
      },
      {
        "level": 3,
        "name": "Terror",
        "threshold": 50,
        "effects": {
          "typing_time_reduction": 20,
          "enemy_damage_bonus": 25,
          "word_scramble_chance": 10,
          "visual": "heavy_vignette_whispers"
        }
      },
      {
        "level": 4,
        "name": "Doom",
        "threshold": 75,
        "effects": {
          "typing_time_reduction": 30,
          "enemy_damage_bonus": 50,
          "word_scramble_chance": 25,
          "phantom_letters": true,
          "visual": "screen_cracks_screams"
        }
      },
      {
        "level": 5,
        "name": "Oblivion",
        "threshold": 100,
        "effects": {
          "instant_death": true,
          "description": "The curse consumes you"
        }
      }
    ],
    "curse_reduction": {
      "perfect_words": -2,
      "wave_completion": -5,
      "special_items": -10,
      "shrine_cleanse": -25
    }
  }
}
```

---

## Adaptive Difficulty (Optional)

### Dynamic Adjustment System

```json
{
  "adaptive_difficulty": {
    "enabled": true,
    "opt_in_required": true,
    "description": "Subtly adjusts challenge based on player performance",
    "tracking_metrics": {
      "recent_wpm": {"window": 30, "unit": "seconds"},
      "error_rate": {"window": 50, "unit": "words"},
      "damage_taken": {"window": 3, "unit": "waves"},
      "gold_efficiency": {"window": 5, "unit": "waves"},
      "combo_average": {"window": 100, "unit": "words"}
    },
    "adjustment_ranges": {
      "enemy_health": {"min": 0.85, "max": 1.15},
      "enemy_speed": {"min": 0.9, "max": 1.1},
      "word_difficulty": {"min": -1, "max": 1},
      "timing_window": {"min": 0.9, "max": 1.2}
    },
    "adjustment_speed": "gradual",
    "player_notification": false,
    "never_affects": ["leaderboard_runs", "achievement_tracking"]
  }
}
```

---

## Difficulty Transitions

### Mid-Game Difficulty Changes

```json
{
  "difficulty_changes": {
    "allowed": true,
    "restrictions": {
      "can_decrease": true,
      "can_increase": false,
      "mid_wave": false,
      "cost": "progress_penalty"
    },
    "decrease_penalty": {
      "achievement_lockout": true,
      "score_modifier": 0.5,
      "leaderboard_flag": "difficulty_lowered"
    },
    "story_mode_exception": {
      "can_increase_to_adventure": true,
      "no_penalty": true,
      "description": "Players who improve can graduate up"
    }
  }
}
```

---

## Per-Level Difficulty Overrides

### Level-Specific Modifiers

```json
{
  "level_overrides": {
    "tutorial_levels": {
      "force_difficulty": "story_lite",
      "ignore_player_difficulty": true,
      "purpose": "Ensure learning experience"
    },
    "boss_levels": {
      "additional_modifiers": {
        "champion": {"boss_health": 1.2},
        "nightmare": {"boss_phases": "+1", "enrage_timer": 0.8}
      }
    },
    "bonus_levels": {
      "allow_difficulty_selection": true,
      "difficulty_affects_rewards": true
    },
    "endless_mode": {
      "base_difficulty": "player_selected",
      "scaling": {
        "per_wave_enemy_health": 1.02,
        "per_wave_enemy_damage": 1.01,
        "caps_at_wave": 100
      }
    }
  }
}
```

---

## UI/UX for Difficulty

### Difficulty Selection Screen

```json
{
  "difficulty_ui": {
    "location": "new_game_screen",
    "layout": "horizontal_cards",
    "information_displayed": [
      "Mode name and icon",
      "Description",
      "Key modifiers summary",
      "Recommended WPM range",
      "Reward multipliers",
      "Unlock status"
    ],
    "hover_details": {
      "full_modifier_list": true,
      "comparison_to_normal": true
    },
    "hardcore_modifiers": {
      "location": "expandable_section",
      "toggle_switches": true,
      "combined_reward_preview": true
    },
    "confirmation": {
      "required_for": ["nightmare", "ironman"],
      "message": "Are you sure? This difficulty is punishing."
    }
  }
}
```

### In-Game Difficulty Indicator

```json
{
  "ingame_indicator": {
    "location": "top_right_hud",
    "display": "icon_small",
    "hover_tooltip": true,
    "color_coding": {
      "story": "#4CAF50",
      "adventure": "#2196F3",
      "champion": "#FF9800",
      "nightmare": "#F44336",
      "zen": "#9C27B0"
    },
    "hardcore_modifier_icons": true
  }
}
```

---

## Achievements by Difficulty

### Difficulty-Gated Achievements

```json
{
  "difficulty_achievements": [
    {
      "id": "story_complete",
      "name": "Tale Told",
      "description": "Complete the story on any difficulty",
      "difficulty_required": "story+"
    },
    {
      "id": "adventure_complete",
      "name": "Hero's Journey",
      "description": "Complete the story on Adventure or higher",
      "difficulty_required": "adventure+"
    },
    {
      "id": "champion_complete",
      "name": "Champion of Keystonia",
      "description": "Complete the story on Champion difficulty",
      "difficulty_required": "champion+"
    },
    {
      "id": "nightmare_complete",
      "name": "Nightmare Slayer",
      "description": "Complete the story on Nightmare difficulty",
      "difficulty_required": "nightmare"
    },
    {
      "id": "ironman_champion",
      "name": "Iron Will",
      "description": "Complete Champion with Ironman modifier",
      "difficulty_required": "champion",
      "modifier_required": "ironman"
    },
    {
      "id": "nightmare_ironman",
      "name": "Deathless Legend",
      "description": "Complete Nightmare with Ironman modifier",
      "difficulty_required": "nightmare",
      "modifier_required": "ironman",
      "reward": "exclusive_title"
    },
    {
      "id": "all_modifiers",
      "name": "Absolute Mastery",
      "description": "Complete Nightmare with all hardcore modifiers active",
      "difficulty_required": "nightmare",
      "modifier_required": "all",
      "reward": "legendary_cosmetic_set"
    }
  ]
}
```

---

## Testing Scenarios

```json
{
  "test_scenarios": [
    {
      "name": "New Player Story Mode",
      "setup": "30 WPM player, first playthrough",
      "expected": "Complete level without frustration",
      "success_criteria": "Clear first 5 levels within 3 attempts each"
    },
    {
      "name": "Skilled Player Adventure",
      "setup": "60 WPM player, experienced gamer",
      "expected": "Moderate challenge, occasional deaths",
      "success_criteria": "Clear most levels first try, some retries on bosses"
    },
    {
      "name": "Expert Champion Mode",
      "setup": "80+ WPM player, completed Adventure",
      "expected": "Consistent challenge, requires strategy",
      "success_criteria": "Multiple attempts on many levels, feels rewarding"
    },
    {
      "name": "Elite Nightmare Mode",
      "setup": "100+ WPM player, completed Champion",
      "expected": "Punishing but fair, requires near-perfection",
      "success_criteria": "Many deaths, eventual completion feels epic"
    },
    {
      "name": "Accessibility Mode",
      "setup": "Player with motor difficulties",
      "expected": "Can complete game at own pace",
      "success_criteria": "Accommodations enable completion"
    }
  ]
}
```

---

*End of Difficulty Modes System Document*
