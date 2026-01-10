# Analytics & Telemetry System

**Created:** 2026-01-08

Complete specification for game analytics, player metrics, and performance tracking.

---

## Overview

### Analytics Philosophy

```
┌─────────────────────────────────────────────────────────────┐
│                ANALYTICS PHILOSOPHY                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. PRIVACY FIRST                                           │
│     → All telemetry is opt-in                              │
│     → No personally identifiable information               │
│     → Data anonymized before transmission                   │
│     → Clear disclosure of what is collected                │
│                                                             │
│  2. PLAYER BENEFIT                                          │
│     → Analytics improve gameplay experience                 │
│     → Identify frustration points                          │
│     → Balance difficulty appropriately                      │
│     → Fix bugs faster                                       │
│                                                             │
│  3. ACTIONABLE INSIGHTS                                     │
│     → Only collect what we'll use                          │
│     → Focus on improving the game                          │
│     → Regular review and cleanup                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Data Categories

### Event Categories

| Category | Purpose | Examples |
|----------|---------|----------|
| **Session** | Play patterns | Start/end, duration, frequency |
| **Progress** | Player advancement | Levels, unlocks, completion |
| **Typing** | Core gameplay | WPM, accuracy, patterns |
| **Combat** | Battle metrics | Wins, losses, strategies |
| **Economy** | Resource flow | Earnings, spending, balance |
| **Technical** | Performance | FPS, errors, load times |

---

## Session Analytics

### Session Events

```json
{
  "session_events": {
    "session_start": {
      "timestamp": "ISO8601",
      "session_id": "uuid",
      "game_version": "1.0.0",
      "platform": "windows|linux|mac",
      "locale": "en_US",
      "first_session": false,
      "days_since_last": 2
    },
    "session_end": {
      "timestamp": "ISO8601",
      "session_id": "uuid",
      "duration_seconds": 3600,
      "battles_played": 15,
      "lessons_completed": 3,
      "end_reason": "quit|crash|timeout"
    },
    "session_pause": {
      "timestamp": "ISO8601",
      "pause_reason": "focus_lost|menu_open|user"
    },
    "session_resume": {
      "timestamp": "ISO8601",
      "pause_duration_seconds": 120
    }
  }
}
```

### Engagement Metrics

```json
{
  "engagement_metrics": {
    "retention": {
      "d1": "Returned within 1 day",
      "d7": "Returned within 7 days",
      "d30": "Returned within 30 days"
    },
    "session_frequency": {
      "daily_sessions": 0,
      "weekly_sessions": 0,
      "avg_session_gap_hours": 0
    },
    "session_depth": {
      "avg_duration_minutes": 0,
      "avg_battles_per_session": 0,
      "avg_lessons_per_session": 0
    }
  }
}
```

---

## Typing Analytics

### Typing Performance Events

```json
{
  "typing_events": {
    "word_completed": {
      "word_length": 5,
      "time_ms": 1200,
      "accuracy": 1.0,
      "wpm_for_word": 50,
      "mistakes": 0,
      "backspaces": 0,
      "lesson_id": "home_row_1",
      "battle_context": true
    },
    "word_failed": {
      "word_length": 8,
      "partial_typed": 5,
      "reason": "enemy_reached_castle|timeout|abandoned"
    },
    "mistake_made": {
      "expected_char": "a",
      "typed_char": "s",
      "position_in_word": 3,
      "word_id": "forest",
      "finger_expected": "left_pinky",
      "common_error": true
    }
  }
}
```

### Typing Pattern Analysis

```json
{
  "typing_patterns": {
    "character_stats": {
      "a": {
        "total_typed": 15234,
        "errors": 234,
        "accuracy": 0.985,
        "avg_time_ms": 150
      }
    },
    "bigram_stats": {
      "th": {
        "total_typed": 2345,
        "avg_time_ms": 200,
        "errors": 45
      }
    },
    "problem_areas": {
      "slow_keys": ["q", "z", "x"],
      "error_prone_keys": ["b", "n"],
      "hesitation_patterns": ["qu", "ck"]
    },
    "improvement_tracking": {
      "wpm_by_week": [25, 28, 32, 35, 38],
      "accuracy_by_week": [0.85, 0.88, 0.90, 0.92, 0.94]
    }
  }
}
```

### Lesson Analytics

```json
{
  "lesson_analytics": {
    "lesson_started": {
      "lesson_id": "home_row_1",
      "attempt_number": 3,
      "current_stars": 2
    },
    "lesson_completed": {
      "lesson_id": "home_row_1",
      "duration_seconds": 180,
      "accuracy": 0.92,
      "wpm": 35,
      "stars_earned": 3,
      "improvement_from_last": 0.05
    },
    "lesson_abandoned": {
      "lesson_id": "reach_row_2",
      "time_in_lesson_seconds": 45,
      "reason": "quit|error|frustration_detected"
    },
    "mastery_achieved": {
      "lesson_id": "home_row_1",
      "total_attempts": 12,
      "days_to_master": 5
    }
  }
}
```

---

## Combat Analytics

### Battle Events

```json
{
  "combat_events": {
    "battle_started": {
      "battle_id": "uuid",
      "day": 15,
      "region": "evergrove",
      "wave_count": 5,
      "difficulty": "normal",
      "player_level": 12
    },
    "wave_completed": {
      "wave_number": 3,
      "duration_seconds": 45,
      "enemies_defeated": 12,
      "damage_taken": 5,
      "accuracy": 0.94,
      "wpm": 42,
      "combo_max": 15,
      "towers_used": ["arrow", "arcane"]
    },
    "battle_won": {
      "total_duration_seconds": 240,
      "total_enemies": 45,
      "final_hp": 75,
      "gold_earned": 150,
      "perfect_waves": 2
    },
    "battle_lost": {
      "wave_reached": 4,
      "cause": "hp_depleted",
      "final_enemy_hp": 5,
      "retry_count": 0
    }
  }
}
```

### Enemy Analytics

```json
{
  "enemy_analytics": {
    "enemy_defeated": {
      "enemy_type": "typhos_scout",
      "tier": 2,
      "word_length": 5,
      "time_to_kill_ms": 2500,
      "overkill": false
    },
    "enemy_reached_castle": {
      "enemy_type": "void_hound",
      "damage_dealt": 3,
      "partial_word_progress": 0.6,
      "reason": "too_slow|targeting_error|overwhelmed"
    },
    "boss_encounter": {
      "boss_id": "grove_guardian",
      "attempt_number": 2,
      "phases_completed": 1,
      "victory": false,
      "time_in_fight_seconds": 180
    }
  }
}
```

### Tower Analytics

```json
{
  "tower_analytics": {
    "tower_built": {
      "tower_type": "arrow",
      "position": {"x": 3, "y": 2},
      "day": 8,
      "gold_spent": 50
    },
    "tower_upgraded": {
      "tower_type": "arrow",
      "new_tier": 2,
      "gold_spent": 100
    },
    "tower_sold": {
      "tower_type": "arcane",
      "tier": 1,
      "gold_received": 30,
      "time_owned_seconds": 600
    },
    "tower_performance": {
      "tower_id": "uuid",
      "damage_dealt": 500,
      "enemies_killed": 25,
      "uptime_seconds": 1800
    }
  }
}
```

---

## Economy Analytics

### Resource Flow

```json
{
  "economy_events": {
    "gold_earned": {
      "amount": 50,
      "source": "battle|quest|sell|daily",
      "details": {
        "battle_id": "uuid",
        "enemy_count": 12
      }
    },
    "gold_spent": {
      "amount": 100,
      "target": "tower|item|upgrade|shop",
      "item_id": "tower_arrow_t2"
    },
    "item_acquired": {
      "item_id": "helm_speed",
      "source": "drop|purchase|craft|reward",
      "rarity": "rare"
    },
    "item_used": {
      "item_id": "potion_health_small",
      "context": "battle",
      "remaining_count": 4
    }
  }
}
```

### Economy Balance

```json
{
  "economy_balance": {
    "gold_velocity": {
      "earned_per_hour": 500,
      "spent_per_hour": 450,
      "net_per_hour": 50
    },
    "item_distribution": {
      "common_drops": 150,
      "rare_drops": 25,
      "epic_drops": 5,
      "legendary_drops": 1
    },
    "shop_usage": {
      "visits": 45,
      "purchases": 12,
      "browse_only": 33,
      "avg_spend": 75
    }
  }
}
```

---

## Progress Analytics

### Player Progression

```json
{
  "progression_events": {
    "level_up": {
      "new_level": 15,
      "xp_earned_this_level": 2500,
      "time_at_previous_level_hours": 4.5,
      "stat_points_allocated": {
        "precision": 2,
        "velocity": 1
      }
    },
    "skill_unlocked": {
      "skill_id": "burst_typing",
      "tree": "speed",
      "skill_points_used": 2
    },
    "achievement_earned": {
      "achievement_id": "century",
      "time_to_earn_hours": 8.5
    },
    "region_unlocked": {
      "region_id": "sunfields",
      "day_unlocked": 12,
      "prerequisite_complete": "mq_05"
    }
  }
}
```

### Funnel Analysis

```json
{
  "funnel_events": {
    "onboarding": {
      "stages": [
        {"id": "start_game", "completed": true},
        {"id": "first_lesson", "completed": true},
        {"id": "first_battle", "completed": true},
        {"id": "first_tower", "completed": true},
        {"id": "reach_day_5", "completed": false}
      ],
      "drop_off_stage": "reach_day_5",
      "time_in_funnel_minutes": 45
    },
    "conversion": {
      "tutorial_to_game": 0.85,
      "day1_to_day7": 0.45,
      "free_to_engaged": 0.30
    }
  }
}
```

---

## Technical Analytics

### Performance Metrics

```json
{
  "performance_events": {
    "frame_rate_sample": {
      "avg_fps": 58,
      "min_fps": 42,
      "max_fps": 60,
      "context": "battle",
      "enemy_count": 15
    },
    "load_time": {
      "scene": "main_game",
      "duration_ms": 1500,
      "cold_start": false
    },
    "memory_usage": {
      "current_mb": 512,
      "peak_mb": 650,
      "context": "world_map"
    }
  }
}
```

### Error Tracking

```json
{
  "error_events": {
    "error_occurred": {
      "error_type": "script_error|crash|assertion",
      "message": "Null reference in enemy_spawn",
      "stack_trace": "...",
      "context": {
        "scene": "battle",
        "day": 15,
        "action": "spawning_wave"
      },
      "frequency": 1,
      "first_seen": "2026-01-08",
      "game_version": "1.0.0"
    },
    "crash_report": {
      "crash_type": "out_of_memory|segfault|unknown",
      "last_action": "loading_world_map",
      "session_duration_before_crash": 3600,
      "auto_recovery": true
    }
  }
}
```

---

## Data Collection

### Collection Implementation

```gdscript
# analytics_manager.gd

class_name AnalyticsManager
extends Node

signal event_logged(event_name: String, data: Dictionary)

var enabled: bool = false
var session_id: String = ""
var event_queue: Array[Dictionary] = []
var batch_size: int = 50
var flush_interval: float = 60.0

func _ready() -> void:
    enabled = Settings.get("analytics_enabled", false)
    if enabled:
        _start_session()
        _start_flush_timer()

func log_event(event_name: String, data: Dictionary = {}) -> void:
    if not enabled:
        return

    var event := {
        "event": event_name,
        "timestamp": Time.get_datetime_string_from_system(true),
        "session_id": session_id,
        "data": data
    }

    event_queue.append(event)
    emit_signal("event_logged", event_name, data)

    if event_queue.size() >= batch_size:
        _flush_events()

func _flush_events() -> void:
    if event_queue.is_empty():
        return

    var batch := event_queue.duplicate()
    event_queue.clear()

    # Send to analytics backend
    _send_batch(batch)

func _send_batch(batch: Array) -> void:
    # Implement actual sending to analytics service
    # Could be local file, remote server, etc.
    pass
```

### Event Helpers

```gdscript
# Typing events
func log_word_completed(word: String, accuracy: float, wpm: float, time_ms: int) -> void:
    log_event("word_completed", {
        "word_length": word.length(),
        "accuracy": accuracy,
        "wpm": wpm,
        "time_ms": time_ms
    })

# Combat events
func log_battle_won(duration: int, enemies: int, gold: int) -> void:
    log_event("battle_won", {
        "duration_seconds": duration,
        "enemies_defeated": enemies,
        "gold_earned": gold
    })

# Progress events
func log_level_up(new_level: int, stats: Dictionary) -> void:
    log_event("level_up", {
        "new_level": new_level,
        "stats_allocated": stats
    })
```

---

## Privacy & Consent

### Consent Flow

```
┌─────────────────────────────────────────────────────────────┐
│ ANALYTICS CONSENT                                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ Help us improve Keyboard Defense!                          │
│                                                             │
│ We collect anonymous gameplay data to:                     │
│ • Balance difficulty                                        │
│ • Fix bugs                                                  │
│ • Improve lessons                                           │
│                                                             │
│ We NEVER collect:                                           │
│ • Personal information                                      │
│ • Text you type (only statistics)                          │
│ • Information from other apps                              │
│                                                             │
│ [View Privacy Policy]                                       │
│                                                             │
│ [Enable Analytics]  [Disable Analytics]                    │
│                                                             │
│ You can change this anytime in Settings.                   │
└─────────────────────────────────────────────────────────────┘
```

### Data Anonymization

```json
{
  "anonymization": {
    "no_pii": [
      "No player names",
      "No email addresses",
      "No IP addresses stored",
      "No location data"
    ],
    "data_hashing": {
      "session_id": "Generated UUID, no link to user",
      "device_id": "One-way hash, cannot be reversed"
    },
    "aggregation": {
      "individual_events": "Kept for 30 days",
      "aggregated_data": "Kept indefinitely",
      "raw_data": "Deleted after aggregation"
    }
  }
}
```

---

## Analytics Dashboard

### Key Metrics View

```
┌─────────────────────────────────────────────────────────────┐
│ KEYBOARD DEFENSE ANALYTICS                    Last 7 days  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ ENGAGEMENT                                                  │
│ ├── DAU: 1,234 (+5%)                                       │
│ ├── D1 Retention: 45%                                      │
│ ├── D7 Retention: 25%                                      │
│ └── Avg Session: 32 min                                    │
│                                                             │
│ TYPING                                                      │
│ ├── Avg WPM: 38 (+2)                                       │
│ ├── Avg Accuracy: 92%                                      │
│ └── Lessons Completed: 5,234                               │
│                                                             │
│ COMBAT                                                      │
│ ├── Battles Played: 15,234                                 │
│ ├── Win Rate: 78%                                          │
│ └── Avg Combo: 12                                          │
│                                                             │
│ ISSUES                                                      │
│ ├── Crash Rate: 0.1%                                       │
│ ├── Top Error: enemy_spawn null                            │
│ └── Affected Users: 23                                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Implementation Checklist

- [ ] Create AnalyticsManager singleton
- [ ] Implement event logging system
- [ ] Add session tracking
- [ ] Create typing event helpers
- [ ] Add combat event helpers
- [ ] Implement progress tracking
- [ ] Add error tracking
- [ ] Create consent flow UI
- [ ] Implement data anonymization
- [ ] Set up analytics backend
- [ ] Create dashboard views
- [ ] Add opt-out functionality
- [ ] Document privacy policy

---

## References

- `game/main.gd` - Game events
- `game/typing_profile.gd` - Typing stats
- `docs/plans/p1/SAVE_SYSTEM_ARCHITECTURE.md` - Data storage
- GDPR compliance guidelines
- App Store privacy requirements
