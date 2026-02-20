# Tutorial and Hints System

**Version:** 1.0.0
**Last Updated:** 2026-01-09
**Status:** Implementation Ready

## Overview

The tutorial system teaches players both typing skills and game mechanics through integrated, story-driven lessons. The system adapts to player skill level and provides contextual hints without being intrusive.

---

## Tutorial Philosophy

### Core Principles

```json
{
  "tutorial_philosophy": {
    "principles": [
      {
        "name": "Show, Don't Tell",
        "description": "Demonstrate mechanics through guided play rather than text walls",
        "implementation": "Interactive tutorials with immediate feedback"
      },
      {
        "name": "Story Integration",
        "description": "Tutorials feel like part of the narrative, not interruptions",
        "implementation": "NPCs teach skills as story events"
      },
      {
        "name": "Respect Player Time",
        "description": "Experienced players can skip or accelerate tutorials",
        "implementation": "Skill detection and skip options"
      },
      {
        "name": "Learn by Doing",
        "description": "Practice in safe environments before real challenges",
        "implementation": "Training grounds with no fail states"
      },
      {
        "name": "Progressive Complexity",
        "description": "Introduce one concept at a time, build on previous knowledge",
        "implementation": "Layered tutorial sequence"
      }
    ]
  }
}
```

---

## Tutorial Sequence

### Chapter 1: The Awakening (Core Tutorials)

```json
{
  "chapter_1_tutorials": [
    {
      "tutorial_id": "intro_typing",
      "name": "First Words",
      "trigger": "Game start",
      "duration": "3-5 minutes",
      "skip_condition": "WPM test > 30",
      "teaches": [
        "Basic typing interface",
        "Word completion",
        "Home row positioning"
      ],
      "story_context": "The Letter Spirit awakens your typing powers",
      "npc_guide": "Alphabos",
      "steps": [
        {
          "step": 1,
          "instruction": "Type the glowing word to cast your first spell",
          "target_word": "home",
          "highlight": "word_display",
          "success_message": "Excellent! The letters respond to your touch."
        },
        {
          "step": 2,
          "instruction": "Notice how your fingers rest on the home row: ASDF and JKL;",
          "highlight": "keyboard_display",
          "show_finger_guide": true
        },
        {
          "step": 3,
          "instruction": "Complete these words using the home row",
          "target_words": ["ask", "sad", "fall", "glad"],
          "allow_errors": true,
          "error_coaching": true
        }
      ],
      "completion_reward": {
        "achievement": "First Words",
        "item": "Apprentice's Keyboard (cosmetic)"
      }
    },
    {
      "tutorial_id": "intro_combat",
      "name": "Defense of the Realm",
      "trigger": "After intro_typing",
      "duration": "5-7 minutes",
      "skip_condition": null,
      "teaches": [
        "Enemy movement",
        "Typing to attack",
        "Base defense concept"
      ],
      "story_context": "Word Wraiths approach the village",
      "npc_guide": "Captain Serif",
      "steps": [
        {
          "step": 1,
          "instruction": "Enemies approach! Type their word to defeat them.",
          "spawn_enemy": {"type": "grunt_tutorial", "word": "foe", "speed": 0.3},
          "highlight": "enemy_word"
        },
        {
          "step": 2,
          "instruction": "Good! Each enemy carries a word. Defeat them before they reach the castle.",
          "spawn_enemies": [
            {"word": "run", "delay": 0},
            {"word": "bad", "delay": 2}
          ],
          "speed": 0.4
        },
        {
          "step": 3,
          "instruction": "If an enemy reaches the castle, you lose health. Don't let that happen!",
          "show_health_bar": true,
          "spawn_wave": "tutorial_wave_1"
        }
      ]
    },
    {
      "tutorial_id": "intro_towers",
      "name": "Building Your Defense",
      "trigger": "After intro_combat",
      "duration": "5 minutes",
      "teaches": [
        "Tower placement",
        "Tower activation (typing)",
        "Gold and resources"
      ],
      "story_context": "The village elder shows you the watchtower",
      "npc_guide": "Elder Keystroke",
      "steps": [
        {
          "step": 1,
          "instruction": "Towers help defend the realm. Click here to place an Arrow Tower.",
          "highlight": "build_spot_1",
          "force_action": "place_tower",
          "free_tower": true
        },
        {
          "step": 2,
          "instruction": "Towers attack when you complete words. Type to fire!",
          "spawn_enemy": {"word": "fire"},
          "highlight": "tower_range"
        },
        {
          "step": 3,
          "instruction": "Building towers costs gold. Defeat enemies to earn more.",
          "show_gold_display": true,
          "practice_wave": true
        }
      ]
    }
  ]
}
```

### Chapter 2-3: Expanding Skills

```json
{
  "progressive_tutorials": [
    {
      "tutorial_id": "combo_system",
      "name": "The Flow State",
      "trigger": "Chapter 2, Level 1",
      "teaches": ["Combo building", "Combo bonuses", "Maintaining streaks"],
      "story_context": "Master Typist teaches the art of flow",
      "practice_mode": "combo_challenge"
    },
    {
      "tutorial_id": "tower_upgrades",
      "name": "Strengthening Defenses",
      "trigger": "Chapter 2, Level 3",
      "teaches": ["Tower upgrade paths", "Resource management", "Strategic choices"],
      "story_context": "The Blacksmith offers to improve your towers"
    },
    {
      "tutorial_id": "special_enemies",
      "name": "Know Your Enemy",
      "trigger": "First elite encounter",
      "teaches": ["Elite enemy mechanics", "Prioritization", "Special abilities"],
      "story_context": "A Champion approaches with unknown power"
    },
    {
      "tutorial_id": "top_row",
      "name": "Reaching Higher",
      "trigger": "Chapter 2, Level 5",
      "teaches": ["Top row keys (QWERTY)", "Finger movement", "Return to home row"],
      "story_context": "The Tower of Letters has more floors to climb",
      "practice_words": ["quite", "write", "tower", "power"]
    },
    {
      "tutorial_id": "bottom_row",
      "name": "Deeper Keys",
      "trigger": "Chapter 3, Level 1",
      "teaches": ["Bottom row keys (ZXCVB)", "Maintaining posture", "Challenging reaches"],
      "story_context": "The dungeons hold secrets in their depths",
      "practice_words": ["zone", "cave", "brave", "blaze"]
    },
    {
      "tutorial_id": "numbers_intro",
      "name": "The Number Realm",
      "trigger": "Chapter 3, Level 5",
      "teaches": ["Number row basics", "Shifting for symbols", "Mixed alphanumeric"],
      "story_context": "The Calculator Cult guards numerical secrets"
    }
  ]
}
```

---

## Contextual Hints

### Hint Trigger System

```json
{
  "hint_system": {
    "hint_types": [
      {
        "type": "proactive",
        "description": "Shown before player might need it",
        "timing": "On new mechanic encounter",
        "display": "Tooltip near relevant element"
      },
      {
        "type": "reactive",
        "description": "Shown after player struggles",
        "timing": "After X failures or long pause",
        "display": "Gentle suggestion in corner"
      },
      {
        "type": "requested",
        "description": "Player manually asks for help",
        "timing": "On button press or menu",
        "display": "Full hint panel"
      }
    ],
    "hint_frequency": {
      "aggressive": "Show all hints immediately",
      "moderate": "Show hints after 2 failures",
      "minimal": "Only show requested hints",
      "off": "No hints"
    },
    "settings_location": "Options > Gameplay > Hint Frequency"
  }
}
```

### Hint Categories

```json
{
  "hint_categories": {
    "typing_hints": [
      {
        "hint_id": "finger_position",
        "trigger": "Wrong finger used (detected by key)",
        "message": "Try using your {correct_finger} finger for the '{key}' key",
        "visual": "Highlight correct finger on keyboard display"
      },
      {
        "hint_id": "home_row_drift",
        "trigger": "Multiple errors suggesting hand drift",
        "message": "Your hands might have drifted. Feel for the bumps on F and J!",
        "visual": "Pulse home row keys"
      },
      {
        "hint_id": "speed_vs_accuracy",
        "trigger": "High error rate with fast typing",
        "message": "Slow down a bit - accuracy is more important than speed right now",
        "visual": null
      },
      {
        "hint_id": "difficult_word",
        "trigger": "Same word failed 3 times",
        "message": "This word is tricky! Break it down: '{word_split}'",
        "visual": "Show word syllables"
      }
    ],
    "combat_hints": [
      {
        "hint_id": "enemy_priority",
        "trigger": "Enemy close to base while typing far enemy",
        "message": "Watch out! That enemy is close to your castle. Prioritize threats!",
        "visual": "Highlight dangerous enemy"
      },
      {
        "hint_id": "tower_placement",
        "trigger": "Tower placed with poor coverage",
        "message": "Towers work best where they can hit enemies on the path longer",
        "visual": "Show optimal placement zones"
      },
      {
        "hint_id": "resource_management",
        "trigger": "Player hoarding gold late in level",
        "message": "Don't forget to spend your gold! More towers mean more defense.",
        "visual": "Highlight build spots"
      },
      {
        "hint_id": "combo_opportunity",
        "trigger": "Player not building combos",
        "message": "Complete words quickly to build combos for bonus damage!",
        "visual": "Highlight combo counter"
      }
    ],
    "strategic_hints": [
      {
        "hint_id": "tower_synergy",
        "trigger": "Player has unsynergized towers",
        "message": "These towers work well together! Place them close for bonus effects.",
        "visual": "Draw synergy connection line"
      },
      {
        "hint_id": "upgrade_suggestion",
        "trigger": "Player has enough for upgrade but doesn't use it",
        "message": "You can upgrade this tower! Upgraded towers are more powerful.",
        "visual": "Highlight upgrade button"
      },
      {
        "hint_id": "enemy_weakness",
        "trigger": "First encounter with enemy type",
        "message": "This {enemy_type} is weak to {damage_type} damage!",
        "visual": "Show weakness icon"
      }
    ]
  }
}
```

### Smart Hint Timing

```json
{
  "hint_timing": {
    "cooldown_between_hints": 30,
    "max_hints_per_level": 5,
    "suppress_during": [
      "Boss fights (unless critical)",
      "High combo streaks",
      "Final wave",
      "Cutscenes"
    ],
    "priority_queue": true,
    "dismiss_on": [
      "Player action resolving hint",
      "Click/keypress",
      "Timeout (10 seconds)"
    ]
  }
}
```

---

## Training Grounds

### Practice Areas

```json
{
  "training_grounds": {
    "location": "Village Hub",
    "unlocked": "After Chapter 1",
    "features": [
      {
        "area_id": "typing_range",
        "name": "Typing Range",
        "description": "Practice typing without combat pressure",
        "modes": [
          {
            "mode": "free_practice",
            "description": "Endless words, no enemies",
            "settings": ["Word length", "Word source", "Target WPM"]
          },
          {
            "mode": "key_focus",
            "description": "Practice specific keys or rows",
            "settings": ["Select keys", "Repetition count"]
          },
          {
            "mode": "accuracy_drill",
            "description": "Focus on error-free typing",
            "goal": "Complete 50 words with 98%+ accuracy"
          },
          {
            "mode": "speed_drill",
            "description": "Build typing speed",
            "goal": "Maintain target WPM for 2 minutes"
          }
        ]
      },
      {
        "area_id": "combat_simulator",
        "name": "Combat Simulator",
        "description": "Practice against enemies without losing progress",
        "modes": [
          {
            "mode": "wave_practice",
            "description": "Replay any completed wave",
            "settings": ["Wave selection", "Difficulty modifier"]
          },
          {
            "mode": "enemy_training",
            "description": "Practice against specific enemy types",
            "settings": ["Enemy type", "Quantity", "Speed"]
          },
          {
            "mode": "boss_rush",
            "description": "Practice boss fights",
            "unlock": "After defeating boss",
            "settings": ["Boss selection", "Phase selection"]
          }
        ]
      },
      {
        "area_id": "tower_sandbox",
        "name": "Tower Sandbox",
        "description": "Experiment with tower combinations",
        "features": [
          "Unlimited gold for building",
          "Test any unlocked tower",
          "Simulate enemy waves",
          "No rewards earned"
        ]
      }
    ]
  }
}
```

---

## Skill Assessment

### Initial Typing Test

```json
{
  "initial_assessment": {
    "trigger": "First game launch",
    "skippable": true,
    "duration": "60 seconds",
    "purpose": "Calibrate starting difficulty and tutorials",
    "test_content": {
      "word_source": "common_words",
      "word_lengths": "mixed",
      "presentation": "continuous_flow"
    },
    "metrics_captured": [
      "Words per minute",
      "Accuracy percentage",
      "Error patterns",
      "Key-specific speed",
      "Consistency"
    ],
    "result_mapping": {
      "beginner": {
        "wpm_range": [0, 25],
        "accuracy_range": [0, 85],
        "recommendations": [
          "Enable all tutorials",
          "Start on Story difficulty",
          "Focus on home row lessons"
        ]
      },
      "novice": {
        "wpm_range": [25, 40],
        "accuracy_range": [85, 92],
        "recommendations": [
          "Standard tutorials",
          "Adventure difficulty available",
          "Full keyboard lessons"
        ]
      },
      "intermediate": {
        "wpm_range": [40, 60],
        "accuracy_range": [92, 96],
        "recommendations": [
          "Abbreviated tutorials",
          "Adventure difficulty recommended",
          "Focus on speed improvement"
        ]
      },
      "advanced": {
        "wpm_range": [60, 80],
        "accuracy_range": [96, 99],
        "recommendations": [
          "Skip basic tutorials",
          "Champion difficulty available",
          "Advanced technique lessons"
        ]
      },
      "expert": {
        "wpm_range": [80, 999],
        "accuracy_range": [99, 100],
        "recommendations": [
          "All tutorials optional",
          "All difficulties available",
          "Focus on game strategy"
        ]
      }
    }
  }
}
```

### Ongoing Assessment

```json
{
  "ongoing_assessment": {
    "tracking_window": "Last 100 words",
    "metrics": {
      "rolling_wpm": true,
      "rolling_accuracy": true,
      "problematic_keys": true,
      "improvement_rate": true
    },
    "adaptive_responses": [
      {
        "condition": "WPM dropping significantly",
        "response": "Offer easier word pool or break suggestion"
      },
      {
        "condition": "Specific key consistently wrong",
        "response": "Suggest targeted practice for that key"
      },
      {
        "condition": "Accuracy below 80%",
        "response": "Encourage slower, more deliberate typing"
      },
      {
        "condition": "Significant improvement detected",
        "response": "Celebrate progress, suggest harder content"
      }
    ]
  }
}
```

---

## Tutorial UI Elements

### Overlay System

```json
{
  "tutorial_overlay": {
    "highlight_style": {
      "type": "spotlight",
      "background_dim": 0.7,
      "border_glow": true,
      "pulse_animation": true
    },
    "tooltip_style": {
      "position": "near_element",
      "arrow_pointing": true,
      "max_width": 300,
      "font_size": "readable",
      "background": "semi_transparent"
    },
    "instruction_panel": {
      "position": "top_center",
      "shows": ["Current objective", "Progress indicator"],
      "dismissible": false
    },
    "npc_dialogue": {
      "position": "bottom_left",
      "portrait": true,
      "typewriter_effect": true,
      "voice_blips": true
    }
  }
}
```

### Progress Indicators

```json
{
  "tutorial_progress": {
    "step_indicator": {
      "style": "dots",
      "position": "top_right",
      "shows_total": true
    },
    "completion_celebration": {
      "animation": "confetti_burst",
      "sound": "achievement_unlock",
      "message": "Tutorial Complete!",
      "rewards_shown": true
    },
    "skip_button": {
      "position": "bottom_right",
      "label": "Skip Tutorial",
      "confirmation_required": true,
      "hidden_for": ["Critical tutorials", "First-time players"]
    }
  }
}
```

---

## Keyboard Display Guide

### Visual Keyboard

```json
{
  "keyboard_display": {
    "enabled_by_default": true,
    "position": "bottom_center",
    "size": "adjustable",
    "features": {
      "finger_color_coding": {
        "enabled": true,
        "colors": {
          "left_pinky": "#FF6B6B",
          "left_ring": "#4ECDC4",
          "left_middle": "#45B7D1",
          "left_index": "#96CEB4",
          "right_index": "#FFEAA7",
          "right_middle": "#DDA0DD",
          "right_ring": "#98D8C8",
          "right_pinky": "#F7DC6F"
        }
      },
      "next_key_highlight": {
        "enabled": true,
        "style": "glow",
        "color": "#FFFFFF"
      },
      "pressed_key_feedback": {
        "enabled": true,
        "correct": "green_flash",
        "incorrect": "red_shake"
      },
      "finger_guide_overlay": {
        "enabled": "on_hover_or_toggle",
        "shows": "Which finger for each key"
      }
    },
    "layouts_supported": ["QWERTY", "DVORAK", "AZERTY", "COLEMAK"],
    "opacity": "adjustable",
    "hide_option": true
  }
}
```

### Hand Position Guide

```json
{
  "hand_guide": {
    "enabled": "Settings toggle",
    "display_mode": [
      {
        "mode": "static",
        "description": "Shows correct hand position diagram"
      },
      {
        "mode": "animated",
        "description": "Shows finger movement to next key"
      },
      {
        "mode": "ghost_hands",
        "description": "Semi-transparent hands on keyboard"
      }
    ],
    "trigger_conditions": [
      "Tutorial mode",
      "Practice mode",
      "Player request",
      "Detected position problems"
    ]
  }
}
```

---

## Accessibility in Tutorials

### Adaptive Tutorial Features

```json
{
  "accessibility_tutorials": {
    "extended_time": {
      "enabled_for": "Motor assist mode",
      "multiplier": 2.0,
      "removes_time_pressure": true
    },
    "audio_descriptions": {
      "enabled_for": "Vision assist mode",
      "describes": ["UI elements", "Enemy positions", "Tutorial steps"]
    },
    "simplified_instructions": {
      "enabled_for": "Cognitive assist mode",
      "features": [
        "Shorter sentences",
        "Fewer steps per tutorial",
        "More repetition"
      ]
    },
    "one_handed_tutorials": {
      "enabled_for": "One-handed mode",
      "modified_content": "Left or right hand only exercises"
    }
  }
}
```

---

## Tutorial Analytics

### Learning Metrics

```json
{
  "tutorial_analytics": {
    "tracked_metrics": [
      "Tutorial completion rates",
      "Steps where players struggle",
      "Skip rates by tutorial",
      "Time spent per tutorial",
      "Post-tutorial performance"
    ],
    "purpose": "Improve tutorial design",
    "privacy": "Aggregated only, no personal data",
    "opt_out": true
  }
}
```

---

## Implementation Priority

### Phase 1 - Core
1. Initial typing assessment
2. Chapter 1 tutorials
3. Basic hint system
4. Keyboard display

### Phase 2 - Expansion
1. Progressive tutorials (Ch 2-3)
2. Training grounds
3. Contextual hints
4. NPC dialogue system

### Phase 3 - Polish
1. Adaptive difficulty hints
2. Advanced practice modes
3. Accessibility features
4. Analytics integration

---

*End of Tutorial and Hints System Document*
