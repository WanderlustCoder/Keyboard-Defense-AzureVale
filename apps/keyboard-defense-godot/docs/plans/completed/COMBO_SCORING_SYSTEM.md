# Combo and Scoring System

**Version:** 1.0.0
**Last Updated:** 2026-01-09
**Status:** Implementation Ready

## Overview

The combo and scoring system rewards consistent, accurate, and fast typing with escalating bonuses. It creates a satisfying gameplay loop where players are motivated to maintain streaks while managing risk.

---

## Core Combo Mechanics

### Combo Counter

```json
{
  "combo_system": {
    "description": "Sequential correct words without errors increase combo",
    "increment_on": "word_completed_correctly",
    "break_on": [
      "typing_error",
      "word_timeout",
      "enemy_reaches_base",
      "manual_cancel"
    ],
    "max_combo": 999,
    "display_location": "center_top_hud",
    "visual_scaling": {
      "size_increase_per_10": 5,
      "max_size_multiplier": 2.0,
      "color_thresholds": {
        "0": "#FFFFFF",
        "5": "#90EE90",
        "10": "#FFD700",
        "25": "#FF8C00",
        "50": "#FF4500",
        "100": "#FF00FF",
        "200": "#00FFFF"
      }
    }
  }
}
```

### Combo Tiers

```json
{
  "combo_tiers": [
    {
      "tier": 0,
      "name": "None",
      "min_combo": 0,
      "damage_bonus": 0,
      "gold_bonus": 0,
      "xp_bonus": 0,
      "visual": "none"
    },
    {
      "tier": 1,
      "name": "Warming Up",
      "min_combo": 3,
      "damage_bonus": 5,
      "gold_bonus": 5,
      "xp_bonus": 5,
      "visual": "subtle_glow"
    },
    {
      "tier": 2,
      "name": "On Fire",
      "min_combo": 5,
      "damage_bonus": 10,
      "gold_bonus": 10,
      "xp_bonus": 10,
      "visual": "flame_trail",
      "announcement": true
    },
    {
      "tier": 3,
      "name": "Blazing",
      "min_combo": 10,
      "damage_bonus": 20,
      "gold_bonus": 15,
      "xp_bonus": 15,
      "visual": "fire_aura",
      "screen_shake": "subtle"
    },
    {
      "tier": 4,
      "name": "Inferno",
      "min_combo": 25,
      "damage_bonus": 35,
      "gold_bonus": 25,
      "xp_bonus": 25,
      "visual": "inferno_particles",
      "screen_shake": "moderate",
      "tower_boost": true
    },
    {
      "tier": 5,
      "name": "Legendary",
      "min_combo": 50,
      "damage_bonus": 50,
      "gold_bonus": 40,
      "xp_bonus": 40,
      "visual": "legendary_aura",
      "screen_shake": "intense",
      "tower_boost": true,
      "projectile_effects": true
    },
    {
      "tier": 6,
      "name": "Mythic",
      "min_combo": 100,
      "damage_bonus": 75,
      "gold_bonus": 60,
      "xp_bonus": 60,
      "visual": "mythic_transformation",
      "screen_effects": "epic",
      "tower_boost": true,
      "projectile_effects": true,
      "enemy_fear": true
    },
    {
      "tier": 7,
      "name": "Transcendent",
      "min_combo": 200,
      "damage_bonus": 100,
      "gold_bonus": 100,
      "xp_bonus": 100,
      "visual": "transcendent_reality",
      "screen_effects": "reality_warp",
      "all_bonuses_doubled": true
    }
  ]
}
```

### Combo Decay (Optional Mode)

```json
{
  "combo_decay": {
    "enabled_modes": ["champion", "nightmare"],
    "description": "Combo slowly decreases if not typing",
    "idle_threshold": 3.0,
    "decay_rate": 1,
    "decay_interval": 1.0,
    "minimum_decay_to": 0,
    "visual_warning": {
      "starts_at": 2.0,
      "indicator": "pulsing_combo_number"
    }
  }
}
```

---

## Scoring System

### Base Score Calculation

```json
{
  "base_scoring": {
    "word_completion": {
      "base_points": 100,
      "per_character_bonus": 10,
      "formula": "base_points + (word_length * per_character_bonus)"
    },
    "enemy_kill": {
      "grunt": 50,
      "runner": 40,
      "tank": 100,
      "elite": 200,
      "mini_boss": 500,
      "boss": 2000
    },
    "wave_completion": {
      "base": 500,
      "per_enemy_killed": 10,
      "perfect_wave_bonus": 1000,
      "no_damage_bonus": 500
    },
    "level_completion": {
      "base": 5000,
      "time_bonus": true,
      "health_bonus": true,
      "gold_bonus": false
    }
  }
}
```

### Score Multipliers

```json
{
  "score_multipliers": {
    "combo_multiplier": {
      "formula": "1.0 + (combo_count * 0.02)",
      "max_multiplier": 5.0,
      "example": "50 combo = 2.0x multiplier"
    },
    "accuracy_multiplier": {
      "thresholds": {
        "100": 2.0,
        "99": 1.8,
        "98": 1.6,
        "95": 1.4,
        "90": 1.2,
        "80": 1.0,
        "below_80": 0.8
      }
    },
    "speed_multiplier": {
      "thresholds": {
        "120_wpm": 2.0,
        "100_wpm": 1.7,
        "80_wpm": 1.4,
        "60_wpm": 1.2,
        "40_wpm": 1.0,
        "below_40": 0.9
      }
    },
    "difficulty_multiplier": {
      "story": 0.5,
      "adventure": 1.0,
      "champion": 1.5,
      "nightmare": 2.5
    },
    "modifier_multipliers": {
      "ironman": 1.5,
      "speedrun": 1.25,
      "purist": 1.4,
      "blind": 1.3,
      "chaos": 1.2,
      "marathon": 1.6
    }
  }
}
```

### Final Score Formula

```
Final Score = Base Score × Combo Multiplier × Accuracy Multiplier × Speed Multiplier × Difficulty Multiplier × Modifier Multipliers
```

---

## Perfect Word Bonuses

### Perfect Word Definition

```json
{
  "perfect_word": {
    "requirements": [
      "No typing errors",
      "Completed within time limit",
      "No backspace used"
    ],
    "bonuses": {
      "score_bonus": 50,
      "damage_bonus_percent": 25,
      "gold_bonus": 5,
      "combo_bonus": 1,
      "special_effect": "sparkle_burst"
    }
  }
}
```

### Speed Perfect Bonus

```json
{
  "speed_perfect": {
    "description": "Complete word significantly faster than required",
    "thresholds": {
      "fast": {
        "time_remaining_percent": 50,
        "score_bonus": 100,
        "label": "Fast!"
      },
      "blazing": {
        "time_remaining_percent": 70,
        "score_bonus": 200,
        "label": "Blazing!"
      },
      "instant": {
        "time_remaining_percent": 90,
        "score_bonus": 500,
        "label": "INSTANT!",
        "special_effect": "lightning_strike"
      }
    }
  }
}
```

### Chain Bonuses

```json
{
  "chain_bonuses": {
    "description": "Bonus for completing multiple words in rapid succession",
    "time_window": 1.5,
    "chain_types": {
      "double": {
        "words": 2,
        "bonus": 50,
        "label": "Double!"
      },
      "triple": {
        "words": 3,
        "bonus": 150,
        "label": "Triple!"
      },
      "quad": {
        "words": 4,
        "bonus": 300,
        "label": "Quad!"
      },
      "penta": {
        "words": 5,
        "bonus": 500,
        "label": "PENTA!",
        "special_effect": "explosion"
      },
      "mega_chain": {
        "words": 10,
        "bonus": 2000,
        "label": "MEGA CHAIN!!!",
        "special_effect": "screen_nuke",
        "kills_weak_enemies": true
      }
    }
  }
}
```

---

## Critical Hits

### Critical Hit System

```json
{
  "critical_hits": {
    "base_crit_chance": 5,
    "base_crit_damage": 2.0,
    "triggers": [
      "Random chance on word completion",
      "Perfect word bonus",
      "Speed perfect bonus",
      "Special key combinations"
    ],
    "crit_modifiers": {
      "combo_crit_chance": {
        "per_10_combo": 1,
        "max_bonus": 15
      },
      "accuracy_crit_chance": {
        "per_percent_above_95": 0.5,
        "max_bonus": 10
      },
      "item_crit_chance": "varies",
      "skill_crit_chance": "varies"
    },
    "visual": {
      "text": "CRITICAL!",
      "color": "#FFD700",
      "size_multiplier": 1.5,
      "screen_flash": true,
      "sound": "crit_impact"
    }
  }
}
```

### Super Critical

```json
{
  "super_critical": {
    "description": "Extremely rare devastating hit",
    "base_chance": 0.5,
    "damage_multiplier": 5.0,
    "requirements": [
      "Perfect word",
      "High combo (25+)",
      "Random roll success"
    ],
    "visual": {
      "text": "SUPER CRITICAL!!!",
      "color": "#FF00FF",
      "screen_shake": "heavy",
      "slow_motion": 0.3,
      "sound": "super_crit_explosion"
    },
    "effects": [
      "Massive damage to target",
      "Splash damage to nearby enemies",
      "Restores 10% health",
      "Bonus gold drop"
    ]
  }
}
```

---

## Streak Systems

### Word Type Streaks

```json
{
  "type_streaks": {
    "description": "Bonus for consecutive words of same category",
    "streak_types": [
      {
        "type": "same_starting_letter",
        "streak_3_bonus": 25,
        "streak_5_bonus": 75,
        "streak_10_bonus": 200,
        "label": "Letter Streak!"
      },
      {
        "type": "same_length",
        "streak_3_bonus": 20,
        "streak_5_bonus": 60,
        "streak_10_bonus": 150,
        "label": "Length Streak!"
      },
      {
        "type": "same_hand",
        "streak_3_bonus": 30,
        "streak_5_bonus": 90,
        "streak_10_bonus": 250,
        "label": "Hand Streak!"
      },
      {
        "type": "alternating_hands",
        "streak_3_bonus": 40,
        "streak_5_bonus": 120,
        "streak_10_bonus": 350,
        "label": "Alternating Master!"
      },
      {
        "type": "home_row_only",
        "streak_3_bonus": 50,
        "streak_5_bonus": 150,
        "streak_10_bonus": 500,
        "label": "Home Row Hero!"
      }
    ]
  }
}
```

### Accuracy Streaks

```json
{
  "accuracy_streaks": {
    "description": "Bonus for maintaining high accuracy",
    "tracking_window": 20,
    "thresholds": [
      {
        "accuracy": 100,
        "streak_required": 10,
        "bonus": 500,
        "label": "Perfect Streak!",
        "ongoing_bonus_per_word": 50
      },
      {
        "accuracy": 100,
        "streak_required": 25,
        "bonus": 1500,
        "label": "Flawless!",
        "ongoing_bonus_per_word": 100
      },
      {
        "accuracy": 100,
        "streak_required": 50,
        "bonus": 5000,
        "label": "UNTOUCHABLE!",
        "ongoing_bonus_per_word": 200,
        "special_effect": "golden_aura"
      }
    ]
  }
}
```

---

## Wave and Level Scoring

### Wave Completion Scoring

```json
{
  "wave_scoring": {
    "base_completion": 500,
    "bonuses": {
      "all_enemies_killed": 200,
      "no_enemies_reached_base": 300,
      "no_damage_taken": 250,
      "under_par_time": {
        "enabled": true,
        "bonus_per_second_saved": 20,
        "max_bonus": 500
      },
      "no_typos": 400,
      "max_combo_maintained": {
        "enabled": true,
        "bonus_per_combo": 10,
        "max_bonus": 1000
      }
    },
    "penalties": {
      "enemy_reached_base": -50,
      "tower_destroyed": -100,
      "over_par_time": {
        "penalty_per_second": 5,
        "max_penalty": 200
      }
    }
  }
}
```

### Level Completion Scoring

```json
{
  "level_scoring": {
    "base_completion": 5000,
    "star_rating": {
      "enabled": true,
      "criteria": {
        "1_star": "Complete level",
        "2_stars": "Complete with 90%+ accuracy AND no more than 3 enemies reach base",
        "3_stars": "Complete with 95%+ accuracy AND no enemies reach base AND under par time"
      },
      "star_bonuses": {
        "1_star": 0,
        "2_stars": 2500,
        "3_stars": 5000
      }
    },
    "grading": {
      "enabled": true,
      "grades": {
        "S": {"threshold": 50000, "label": "S Rank - Perfect!"},
        "A": {"threshold": 35000, "label": "A Rank - Excellent!"},
        "B": {"threshold": 25000, "label": "B Rank - Great!"},
        "C": {"threshold": 15000, "label": "C Rank - Good"},
        "D": {"threshold": 10000, "label": "D Rank - Passed"},
        "F": {"threshold": 0, "label": "F Rank - Try Again"}
      }
    },
    "first_time_bonus": 1000,
    "improvement_bonus": {
      "enabled": true,
      "bonus": "10% of score increase from previous best"
    }
  }
}
```

---

## Combo Breaker Recovery

### Recovery Mechanics

```json
{
  "combo_recovery": {
    "description": "Ways to mitigate or recover from combo breaks",
    "systems": [
      {
        "system": "combo_shield",
        "description": "First error doesn't break combo",
        "charges": 1,
        "recharge": "every 25 combo",
        "max_charges": 3,
        "visual": "shield_icon_on_combo"
      },
      {
        "system": "quick_recovery",
        "description": "Next 3 perfect words restore half of lost combo",
        "window": 10,
        "recovery_percent": 50,
        "visual": "fading_combo_number"
      },
      {
        "system": "combo_insurance",
        "description": "Item that saves combo on break",
        "item_type": "consumable",
        "uses": 1,
        "rarity": "rare"
      }
    ]
  }
}
```

### Combo Shield Upgrades

```json
{
  "combo_shield_upgrades": {
    "base_charges": 1,
    "upgrade_path": [
      {
        "level": 1,
        "effect": "1 shield charge",
        "unlock": "default"
      },
      {
        "level": 2,
        "effect": "2 shield charges",
        "unlock": "skill_tree"
      },
      {
        "level": 3,
        "effect": "3 shield charges",
        "unlock": "skill_tree"
      },
      {
        "level": 4,
        "effect": "Shields recharge faster (every 20 combo)",
        "unlock": "skill_tree"
      },
      {
        "level": 5,
        "effect": "Blocked error grants temporary damage boost",
        "unlock": "mastery"
      }
    ]
  }
}
```

---

## Score Display and Feedback

### In-Game Score Display

```json
{
  "score_display": {
    "main_score": {
      "location": "top_right",
      "format": "abbreviated",
      "example": "45.2K",
      "update": "animated_count_up"
    },
    "combo_counter": {
      "location": "center_top",
      "format": "large_number",
      "tier_indicator": true,
      "shake_on_increase": true
    },
    "floating_scores": {
      "enabled": true,
      "duration": 1.5,
      "rise_speed": 50,
      "fade_out": true,
      "colors": {
        "base": "#FFFFFF",
        "bonus": "#FFD700",
        "critical": "#FF4500",
        "combo": "#00FF00"
      }
    },
    "multiplier_display": {
      "location": "below_score",
      "format": "x2.5",
      "pulse_on_change": true
    }
  }
}
```

### End of Level Score Breakdown

```json
{
  "score_breakdown": {
    "display_order": [
      "Words Completed",
      "Perfect Words",
      "Enemies Defeated",
      "Wave Bonuses",
      "Combo Bonuses",
      "Speed Bonuses",
      "Accuracy Bonus",
      "Streak Bonuses",
      "Difficulty Multiplier",
      "Total Score"
    ],
    "animation": {
      "line_by_line_reveal": true,
      "delay_between_lines": 0.3,
      "count_up_numbers": true,
      "sound_per_line": true,
      "grand_total_fanfare": true
    },
    "comparison": {
      "show_previous_best": true,
      "show_improvement": true,
      "new_record_effect": true
    }
  }
}
```

---

## Leaderboards

### Leaderboard Categories

```json
{
  "leaderboards": {
    "global": [
      {
        "id": "total_score",
        "name": "Total Score",
        "description": "Cumulative score across all levels",
        "reset": "never"
      },
      {
        "id": "highest_combo",
        "name": "Highest Combo",
        "description": "Highest combo achieved in a single session",
        "reset": "never"
      },
      {
        "id": "best_accuracy",
        "name": "Best Accuracy",
        "description": "Highest accuracy in a completed level (min 100 words)",
        "reset": "never"
      },
      {
        "id": "fastest_wpm",
        "name": "Fastest WPM",
        "description": "Highest sustained WPM over 1 minute",
        "reset": "never"
      }
    ],
    "per_level": [
      {
        "id": "level_high_score",
        "name": "Level High Score",
        "filter_by": "difficulty"
      },
      {
        "id": "level_speed_run",
        "name": "Fastest Clear",
        "filter_by": "difficulty"
      },
      {
        "id": "level_combo",
        "name": "Highest Combo",
        "filter_by": "none"
      }
    ],
    "weekly": [
      {
        "id": "weekly_challenge",
        "name": "Weekly Challenge",
        "reset": "sunday_midnight_utc"
      },
      {
        "id": "weekly_score",
        "name": "Weekly Top Scores",
        "reset": "sunday_midnight_utc"
      }
    ],
    "friends": {
      "enabled": true,
      "types": ["all_global_categories", "all_per_level_categories"]
    }
  }
}
```

### Anti-Cheat Measures

```json
{
  "score_validation": {
    "client_side": [
      "Reasonable WPM caps (200 max)",
      "Minimum time per word",
      "Maximum score per action",
      "Combo rate limiting"
    ],
    "server_side": [
      "Replay verification",
      "Statistical anomaly detection",
      "Device fingerprinting",
      "Manual review queue for top scores"
    ],
    "penalties": {
      "suspicious_score": "flagged_for_review",
      "confirmed_cheat": "score_removed",
      "repeat_offender": "leaderboard_ban"
    }
  }
}
```

---

## Special Scoring Events

### Bonus Score Events

```json
{
  "bonus_events": {
    "first_blood": {
      "description": "First enemy killed in a wave",
      "bonus": 100,
      "label": "First Blood!"
    },
    "wave_ender": {
      "description": "Kill that ends the wave",
      "bonus": 150,
      "label": "Wave Clear!"
    },
    "boss_slayer": {
      "description": "Defeat a boss",
      "bonus": 1000,
      "label": "Boss Slain!"
    },
    "clutch_save": {
      "description": "Kill enemy 1 tile from base",
      "bonus": 200,
      "label": "Clutch Save!"
    },
    "multi_kill": {
      "description": "Kill 3+ enemies within 1 second",
      "bonus_per_kill": 75,
      "label": "Multi-Kill!"
    },
    "shutdown": {
      "description": "Kill elite enemy before it uses special",
      "bonus": 300,
      "label": "Shutdown!"
    },
    "denied": {
      "description": "Kill flying enemy",
      "bonus": 50,
      "label": "Denied!"
    }
  }
}
```

### Negative Events

```json
{
  "penalty_events": {
    "base_breach": {
      "description": "Enemy reaches the base",
      "penalty": -100,
      "label": "Breach!",
      "visual": "red_flash"
    },
    "tower_lost": {
      "description": "Tower is destroyed",
      "penalty": -200,
      "label": "Tower Down!",
      "visual": "tower_explosion"
    },
    "combo_lost": {
      "description": "High combo broken",
      "penalty": 0,
      "label": "Combo Lost!",
      "visual": "combo_shatter",
      "threshold": 10
    },
    "timeout": {
      "description": "Word times out",
      "penalty": -50,
      "label": "Too Slow!",
      "visual": "word_fade"
    }
  }
}
```

---

## Score-Based Rewards

### Score Thresholds

```json
{
  "score_rewards": {
    "per_level": [
      {
        "threshold": 10000,
        "reward": {"gold": 50}
      },
      {
        "threshold": 25000,
        "reward": {"gold": 100, "item_chance": 0.5}
      },
      {
        "threshold": 50000,
        "reward": {"gold": 200, "item_chance": 1.0, "rare_chance": 0.25}
      },
      {
        "threshold": 100000,
        "reward": {"gold": 500, "guaranteed_rare": true}
      }
    ],
    "milestones": [
      {
        "lifetime_score": 100000,
        "reward": {"title": "Scorer"},
        "one_time": true
      },
      {
        "lifetime_score": 1000000,
        "reward": {"title": "Point Master", "cosmetic": "golden_keyboard"},
        "one_time": true
      },
      {
        "lifetime_score": 10000000,
        "reward": {"title": "Score Legend", "cosmetic": "diamond_effects"},
        "one_time": true
      }
    ]
  }
}
```

---

## Implementation Priority

### Phase 1 - Core
1. Basic combo counter
2. Base scoring system
3. Combo tier bonuses
4. Simple multipliers

### Phase 2 - Depth
1. Perfect word bonuses
2. Speed bonuses
3. Chain bonuses
4. Wave/level scoring

### Phase 3 - Advanced
1. Critical hit system
2. Streak systems
3. Combo recovery mechanics
4. Full multiplier system

### Phase 4 - Polish
1. Visual feedback
2. Sound effects
3. Leaderboards
4. Score breakdown screens

---

*End of Combo and Scoring System Document*
