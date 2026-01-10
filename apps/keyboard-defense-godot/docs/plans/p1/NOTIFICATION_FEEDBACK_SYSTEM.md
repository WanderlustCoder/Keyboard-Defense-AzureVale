# Notification and Feedback System

**Version:** 1.0.0
**Last Updated:** 2026-01-09
**Status:** Implementation Ready

## Overview

The notification and feedback system provides players with clear, timely information about game events, typing performance, and state changes. It balances informative feedback with avoiding visual clutter.

---

## Feedback Categories

### Typing Feedback

```json
{
  "typing_feedback": {
    "keystroke_feedback": {
      "correct_key": {
        "visual": "Key lights up green briefly",
        "audio": "Soft key click",
        "haptic": "Light vibration (if supported)"
      },
      "incorrect_key": {
        "visual": "Key flashes red, shake",
        "audio": "Error buzz",
        "haptic": "Sharp vibration",
        "word_display": "Red flash on current character"
      },
      "response_time": "< 16ms (1 frame at 60fps)"
    },
    "word_completion": {
      "normal": {
        "visual": "Word dissolves with sparkle",
        "audio": "Completion chime",
        "floating_text": "+[score]"
      },
      "perfect": {
        "visual": "Word explodes with golden particles",
        "audio": "Perfect completion fanfare",
        "floating_text": "Perfect! +[score]",
        "screen_effect": "Brief golden flash"
      },
      "speed_bonus": {
        "visual": "Lightning effect on word",
        "audio": "Quick whoosh",
        "floating_text": "Fast! +[bonus]"
      }
    },
    "word_timeout": {
      "visual": "Word fades to red, crumbles",
      "audio": "Failure tone",
      "floating_text": "Timeout!",
      "consequence_shown": "-[penalty] HP"
    }
  }
}
```

### Combat Feedback

```json
{
  "combat_feedback": {
    "damage_dealt": {
      "normal": {
        "floating_number": true,
        "color": "#FFFFFF",
        "size": "small",
        "animation": "rise_and_fade"
      },
      "critical": {
        "floating_number": true,
        "color": "#FFD700",
        "size": "large",
        "animation": "bounce_and_fade",
        "prefix": "CRIT!"
      },
      "super_critical": {
        "floating_number": true,
        "color": "#FF00FF",
        "size": "extra_large",
        "animation": "explode_and_fade",
        "prefix": "SUPER!",
        "screen_shake": true
      }
    },
    "damage_taken": {
      "visual": "Red vignette flash",
      "floating_number": true,
      "number_color": "#FF0000",
      "health_bar_shake": true,
      "audio": "Damage impact"
    },
    "enemy_killed": {
      "visual": "Death animation + particles",
      "floating_text": "+[gold] gold",
      "gold_color": "#FFD700",
      "audio": "Enemy death sound"
    },
    "tower_attack": {
      "visual": "Projectile + impact effect",
      "audio": "Tower-specific attack sound",
      "range_indicator": "Brief flash on hit"
    }
  }
}
```

### Combo Feedback

```json
{
  "combo_feedback": {
    "combo_increment": {
      "counter_animation": "Pop and settle",
      "audio": "Ascending pitch on buildup",
      "tier_change": {
        "visual": "Burst effect, color change",
        "audio": "Tier-up fanfare",
        "announcement": "Tier name appears"
      }
    },
    "combo_milestones": {
      "5_combo": {
        "announcement": "On Fire!",
        "effect": "Fire particles on typing"
      },
      "10_combo": {
        "announcement": "Blazing!",
        "effect": "Fire aura intensifies"
      },
      "25_combo": {
        "announcement": "INFERNO!",
        "effect": "Screen-wide fire effect",
        "audio": "Epic fanfare"
      },
      "50_combo": {
        "announcement": "LEGENDARY!",
        "effect": "Reality distortion",
        "audio": "Triumphant orchestral hit"
      },
      "100_combo": {
        "announcement": "MYTHIC!!!",
        "effect": "Full screen transformation",
        "audio": "Choir + orchestra"
      }
    },
    "combo_break": {
      "visual": "Counter shatters, fragments fly",
      "audio": "Glass break + sad trombone",
      "announcement": "Combo Lost!",
      "shows_final_combo": true,
      "lingers": 2.0
    }
  }
}
```

---

## Notification Types

### Toast Notifications

```json
{
  "toast_notifications": {
    "description": "Brief messages that appear and auto-dismiss",
    "position": "top_center",
    "max_visible": 3,
    "default_duration": 3.0,
    "animation": {
      "enter": "slide_down_fade_in",
      "exit": "slide_up_fade_out"
    },
    "types": [
      {
        "type": "achievement_unlocked",
        "icon": "trophy",
        "color": "#FFD700",
        "duration": 5.0,
        "sound": "achievement_unlock",
        "example": "Achievement Unlocked: First Blood!"
      },
      {
        "type": "level_up",
        "icon": "arrow_up",
        "color": "#00FF00",
        "duration": 4.0,
        "sound": "level_up",
        "example": "Level Up! You are now Level 5"
      },
      {
        "type": "item_acquired",
        "icon": "item_icon",
        "color": "rarity_color",
        "duration": 3.0,
        "sound": "item_pickup",
        "example": "Obtained: Fire Crystal x3"
      },
      {
        "type": "quest_progress",
        "icon": "quest_marker",
        "color": "#87CEEB",
        "duration": 3.0,
        "sound": "quest_progress",
        "example": "Quest Progress: Defeat Enemies 5/10"
      },
      {
        "type": "quest_complete",
        "icon": "quest_complete",
        "color": "#00FF00",
        "duration": 4.0,
        "sound": "quest_complete",
        "example": "Quest Complete: The Lost Village"
      },
      {
        "type": "skill_unlocked",
        "icon": "skill_icon",
        "color": "#9370DB",
        "duration": 4.0,
        "sound": "skill_unlock",
        "example": "New Skill: Combo Shield"
      },
      {
        "type": "new_record",
        "icon": "star",
        "color": "#FFD700",
        "duration": 4.0,
        "sound": "record_broken",
        "example": "New Personal Best: 85 WPM!"
      }
    ],
    "queue_behavior": {
      "overflow": "queue",
      "max_queue": 10,
      "priority_system": true,
      "high_priority": ["achievement", "level_up", "quest_complete"]
    }
  }
}
```

### Alert Notifications

```json
{
  "alert_notifications": {
    "description": "Important alerts requiring attention",
    "position": "center_screen",
    "blocks_input": false,
    "types": [
      {
        "type": "wave_starting",
        "message": "Wave {n} Incoming!",
        "visual": "Large text, pulse animation",
        "duration": 2.0,
        "sound": "wave_horn",
        "countdown": true
      },
      {
        "type": "boss_incoming",
        "message": "BOSS APPROACHING",
        "visual": "Full screen dramatic reveal",
        "duration": 3.0,
        "sound": "boss_theme_intro",
        "camera_action": "pan_to_boss"
      },
      {
        "type": "base_under_attack",
        "message": "Base Under Attack!",
        "visual": "Red flashing border",
        "duration": "until_resolved",
        "sound": "alarm",
        "repeat_interval": 5.0
      },
      {
        "type": "low_health",
        "message": "Health Critical!",
        "visual": "Red vignette, heartbeat pulse",
        "duration": "until_resolved",
        "sound": "heartbeat",
        "threshold": 25
      },
      {
        "type": "wave_complete",
        "message": "Wave Complete!",
        "visual": "Success banner",
        "duration": 2.0,
        "sound": "wave_victory"
      },
      {
        "type": "level_complete",
        "message": "Victory!",
        "visual": "Full celebration screen",
        "duration": 5.0,
        "sound": "victory_fanfare",
        "blocks_input": true
      }
    ]
  }
}
```

### Subtle Notifications

```json
{
  "subtle_notifications": {
    "description": "Non-intrusive status indicators",
    "types": [
      {
        "type": "autosave",
        "visual": "Small icon in corner",
        "duration": 2.0,
        "position": "bottom_right",
        "no_sound": true
      },
      {
        "type": "buff_applied",
        "visual": "Icon appears in buff bar",
        "tooltip_on_hover": true,
        "no_sound": true
      },
      {
        "type": "gold_earned",
        "visual": "Gold counter increments with flash",
        "sound": "coin_clink",
        "batch_updates": true
      },
      {
        "type": "typing_stats_update",
        "visual": "Stats panel updates",
        "no_sound": true,
        "only_on_significant_change": true
      }
    ]
  }
}
```

---

## Floating Text System

### Configuration

```json
{
  "floating_text": {
    "types": {
      "damage": {
        "font_size": 16,
        "color": "#FFFFFF",
        "outline": "#000000",
        "animation": "rise_and_fade",
        "duration": 1.0,
        "rise_height": 30
      },
      "critical_damage": {
        "font_size": 24,
        "color": "#FFD700",
        "outline": "#000000",
        "animation": "bounce_and_fade",
        "duration": 1.2,
        "bounce_height": 40
      },
      "healing": {
        "font_size": 16,
        "color": "#00FF00",
        "outline": "#000000",
        "animation": "rise_and_fade",
        "duration": 1.0
      },
      "gold": {
        "font_size": 14,
        "color": "#FFD700",
        "outline": "#000000",
        "animation": "arc_to_ui",
        "target": "gold_counter",
        "duration": 0.8
      },
      "score": {
        "font_size": 18,
        "color": "#FFFFFF",
        "outline": "#000000",
        "animation": "rise_and_fade",
        "duration": 0.8
      },
      "status_text": {
        "font_size": 14,
        "color": "status_color",
        "animation": "rise_and_fade",
        "duration": 1.5,
        "examples": ["Poisoned!", "Slowed!", "Stunned!"]
      }
    },
    "pooling": {
      "enabled": true,
      "pool_size": 50,
      "reuse_oldest": true
    },
    "collision_avoidance": {
      "enabled": true,
      "spread_overlapping": true
    }
  }
}
```

### Floating Text Animations

```json
{
  "floating_text_animations": {
    "rise_and_fade": {
      "y_offset": -30,
      "alpha": {"start": 1.0, "end": 0.0},
      "scale": {"start": 1.0, "end": 0.8},
      "easing": "ease_out"
    },
    "bounce_and_fade": {
      "keyframes": [
        {"time": 0.0, "y_offset": 0, "scale": 1.5},
        {"time": 0.2, "y_offset": -40, "scale": 1.2},
        {"time": 0.4, "y_offset": -30, "scale": 1.0},
        {"time": 1.0, "y_offset": -50, "alpha": 0.0}
      ]
    },
    "arc_to_ui": {
      "type": "bezier_curve",
      "control_points": "dynamic",
      "end_at": "ui_element",
      "scale_down_at_end": true
    },
    "explode_and_fade": {
      "scale": {"start": 0.5, "peak": 2.0, "end": 1.5},
      "rotation": {"range": [-15, 15]},
      "particles": true
    }
  }
}
```

---

## Audio Feedback

### Sound Categories

```json
{
  "audio_feedback": {
    "typing_sounds": {
      "key_press": {
        "variations": 5,
        "pitch_variation": 0.1,
        "volume": 0.6
      },
      "key_error": {
        "sound": "error_buzz",
        "volume": 0.7,
        "cooldown": 0.1
      },
      "word_complete": {
        "variations": 3,
        "pitch_scales_with_combo": true,
        "volume": 0.7
      },
      "perfect_word": {
        "sound": "perfect_chime",
        "volume": 0.8
      }
    },
    "combat_sounds": {
      "enemy_hit": {
        "per_enemy_type": true,
        "volume": 0.6
      },
      "enemy_death": {
        "per_enemy_type": true,
        "volume": 0.7
      },
      "tower_fire": {
        "per_tower_type": true,
        "volume": 0.5
      },
      "player_damage": {
        "sound": "damage_taken",
        "volume": 0.8
      }
    },
    "ui_sounds": {
      "button_hover": {"volume": 0.3},
      "button_click": {"volume": 0.5},
      "menu_open": {"volume": 0.4},
      "menu_close": {"volume": 0.3},
      "notification": {"volume": 0.6}
    },
    "achievement_sounds": {
      "unlock": {"sound": "achievement_fanfare", "volume": 0.8},
      "level_up": {"sound": "level_up_fanfare", "volume": 0.9}
    }
  }
}
```

### Sound Priorities

```json
{
  "sound_priority": {
    "description": "Prevent audio clutter by prioritizing important sounds",
    "categories": [
      {"category": "critical_alerts", "priority": 1, "always_play": true},
      {"category": "player_actions", "priority": 2, "max_concurrent": 3},
      {"category": "combat", "priority": 3, "max_concurrent": 10},
      {"category": "ambient", "priority": 4, "max_concurrent": 5},
      {"category": "ui", "priority": 5, "max_concurrent": 2}
    ],
    "ducking": {
      "enabled": true,
      "trigger": "critical_alerts",
      "duck_amount": 0.3
    }
  }
}
```

---

## Visual Feedback Elements

### Screen Effects

```json
{
  "screen_effects": {
    "damage_flash": {
      "color": "#FF000040",
      "duration": 0.15,
      "blend_mode": "additive"
    },
    "heal_flash": {
      "color": "#00FF0030",
      "duration": 0.2,
      "blend_mode": "additive"
    },
    "combo_glow": {
      "color": "tier_color",
      "intensity": "combo_level",
      "position": "screen_border"
    },
    "critical_flash": {
      "color": "#FFD70060",
      "duration": 0.1,
      "blend_mode": "additive"
    },
    "level_complete": {
      "effect": "golden_rays",
      "duration": 2.0
    },
    "slow_motion": {
      "trigger": ["super_critical", "boss_defeat", "clutch_save"],
      "time_scale": 0.3,
      "duration": 0.5,
      "ramp_in": 0.1,
      "ramp_out": 0.2
    }
  }
}
```

### Progress Indicators

```json
{
  "progress_indicators": {
    "health_bar": {
      "position": "top_left",
      "style": "segmented",
      "color_gradient": {
        "full": "#00FF00",
        "half": "#FFFF00",
        "low": "#FF0000"
      },
      "shake_on_damage": true,
      "pulse_when_low": true
    },
    "wave_progress": {
      "position": "top_center",
      "shows": "Wave X/Y",
      "enemy_count": true,
      "fills_as_cleared": true
    },
    "combo_meter": {
      "position": "below_combo_counter",
      "shows": "Progress to next tier",
      "glows_when_close": true
    },
    "word_timer": {
      "position": "below_word",
      "style": "shrinking_bar",
      "color_change": {
        "safe": "#00FF00",
        "warning": "#FFFF00",
        "danger": "#FF0000"
      }
    },
    "xp_bar": {
      "position": "bottom_of_screen",
      "minimalist": true,
      "shows_on_gain": true,
      "hides_after": 3.0
    }
  }
}
```

---

## Announcement System

### Major Announcements

```json
{
  "announcements": {
    "style": "dramatic_text",
    "position": "center_screen",
    "types": [
      {
        "type": "wave_start",
        "text": "WAVE {n}",
        "font_size": 48,
        "animation": "zoom_in_shake",
        "duration": 1.5,
        "sound": "wave_horn"
      },
      {
        "type": "boss_name",
        "text": "{boss_name}",
        "subtitle": "{boss_title}",
        "font_size": 56,
        "animation": "dramatic_reveal",
        "duration": 3.0,
        "sound": "boss_intro"
      },
      {
        "type": "chapter_title",
        "text": "Chapter {n}: {title}",
        "font_size": 64,
        "animation": "fade_in_fade_out",
        "duration": 4.0,
        "position": "center_with_background"
      },
      {
        "type": "game_over",
        "text": "DEFEAT",
        "font_size": 72,
        "color": "#FF0000",
        "animation": "shatter_in",
        "duration": 3.0,
        "sound": "defeat_sting"
      },
      {
        "type": "victory",
        "text": "VICTORY",
        "font_size": 72,
        "color": "#FFD700",
        "animation": "burst_in",
        "duration": 3.0,
        "sound": "victory_fanfare"
      }
    ]
  }
}
```

### Combo Announcements

```json
{
  "combo_announcements": {
    "style": "energetic",
    "position": "near_combo_counter",
    "announcements": [
      {"combo": 5, "text": "ON FIRE!", "color": "#FFA500"},
      {"combo": 10, "text": "BLAZING!", "color": "#FF4500"},
      {"combo": 15, "text": "UNSTOPPABLE!", "color": "#FF0000"},
      {"combo": 25, "text": "INFERNO!", "color": "#FF00FF"},
      {"combo": 50, "text": "LEGENDARY!", "color": "#FFD700"},
      {"combo": 75, "text": "GODLIKE!", "color": "#00FFFF"},
      {"combo": 100, "text": "MYTHIC!", "color": "#FF00FF", "special_effect": true}
    ],
    "break_announcement": {
      "text": "COMBO LOST!",
      "color": "#808080",
      "shows_lost_amount": true
    }
  }
}
```

---

## HUD Elements

### Dynamic HUD

```json
{
  "hud_layout": {
    "always_visible": [
      {"element": "health_bar", "position": "top_left"},
      {"element": "gold_counter", "position": "top_left_below_health"},
      {"element": "wave_indicator", "position": "top_center"},
      {"element": "score", "position": "top_right"},
      {"element": "combo_counter", "position": "center_top"}
    ],
    "contextual": [
      {
        "element": "word_display",
        "visible_when": "word_active",
        "position": "center"
      },
      {
        "element": "tower_info",
        "visible_when": "tower_selected",
        "position": "right_panel"
      },
      {
        "element": "enemy_info",
        "visible_when": "enemy_hovered",
        "position": "tooltip"
      },
      {
        "element": "build_menu",
        "visible_when": "build_mode",
        "position": "bottom"
      }
    ],
    "toggleable": [
      {"element": "minimap", "default": true, "hotkey": "M"},
      {"element": "typing_stats", "default": false, "hotkey": "T"},
      {"element": "keyboard_display", "default": true, "hotkey": "K"}
    ]
  }
}
```

### HUD Animations

```json
{
  "hud_animations": {
    "gold_change": {
      "increase": "flash_gold_increment",
      "decrease": "flash_red_decrement"
    },
    "health_change": {
      "damage": "shake_and_flash_red",
      "heal": "pulse_green"
    },
    "combo_change": {
      "increase": "pop_and_glow",
      "tier_up": "burst_effect",
      "break": "shatter_animation"
    },
    "score_change": {
      "animation": "count_up",
      "speed": "proportional_to_amount"
    }
  }
}
```

---

## Settings and Accessibility

### Notification Settings

```json
{
  "notification_settings": {
    "master_toggle": true,
    "category_toggles": {
      "achievements": true,
      "quest_updates": true,
      "item_pickups": true,
      "combat_alerts": true,
      "typing_feedback": true
    },
    "visual_intensity": {
      "slider": true,
      "range": [0.0, 1.0],
      "default": 1.0,
      "affects": ["screen_flash", "shake", "particles"]
    },
    "audio_toggles": {
      "notification_sounds": true,
      "typing_sounds": true,
      "combat_sounds": true,
      "announcement_sounds": true
    },
    "floating_text": {
      "enabled": true,
      "damage_numbers": true,
      "gold_numbers": true,
      "score_numbers": true,
      "status_text": true
    },
    "screen_shake": {
      "enabled": true,
      "intensity": {"range": [0.0, 1.0], "default": 1.0}
    }
  }
}
```

### Accessibility Options

```json
{
  "accessibility_feedback": {
    "screen_reader_support": {
      "announce_notifications": true,
      "announce_combat_events": true,
      "announce_typing_feedback": true,
      "verbosity": ["minimal", "normal", "detailed"]
    },
    "visual_alternatives": {
      "audio_cues_for_visual": true,
      "high_contrast_notifications": true,
      "larger_text_option": true
    },
    "reduced_motion": {
      "disables": [
        "Screen shake",
        "Complex animations",
        "Particle effects"
      ],
      "uses_instead": [
        "Simple fades",
        "Color changes",
        "Static indicators"
      ]
    },
    "colorblind_modes": {
      "deuteranopia": true,
      "protanopia": true,
      "tritanopia": true,
      "affects": "All color-coded feedback"
    }
  }
}
```

---

## Implementation Priority

### Phase 1 - Core
1. Basic typing feedback (correct/error)
2. Floating damage numbers
3. Health bar updates
4. Wave announcements

### Phase 2 - Enhancement
1. Toast notification system
2. Combo feedback and announcements
3. Achievement notifications
4. Audio feedback system

### Phase 3 - Polish
1. Screen effects
2. Advanced animations
3. Priority/queuing system
4. All settings options

### Phase 4 - Accessibility
1. Screen reader support
2. Reduced motion mode
3. Colorblind modes
4. Audio alternatives

---

*End of Notification and Feedback System Document*
