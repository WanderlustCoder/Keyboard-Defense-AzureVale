# Animation Specifications

**Last updated:** 2026-01-09

This document defines all animation specifications for Keyboard Defense, including character animations, enemy animations, tower animations, effects, and UI animations.

---

## Table of Contents

1. [Animation System Overview](#animation-system-overview)
2. [Character Animations](#character-animations)
3. [Enemy Animations](#enemy-animations)
4. [Tower Animations](#tower-animations)
5. [Projectile Animations](#projectile-animations)
6. [Effect Animations](#effect-animations)
7. [UI Animations](#ui-animations)
8. [Environmental Animations](#environmental-animations)
9. [Cutscene Animations](#cutscene-animations)

---

## Animation System Overview

### Technical Specifications

```json
{
  "animation_system": {
    "engine": "Godot 4 AnimationPlayer + AnimationTree",
    "sprite_format": "PNG with transparency",
    "frame_rate": 12,
    "default_loop": true,
    "blend_time": 0.1,

    "resolution_tiers": {
      "sd": {"scale": 1.0, "max_sprite_size": 64},
      "hd": {"scale": 2.0, "max_sprite_size": 128},
      "uhd": {"scale": 4.0, "max_sprite_size": 256}
    },

    "color_depth": 32,
    "compression": "lossless"
  }
}
```

### Animation Data Structure

```json
{
  "animation_id": "string",
  "name": "Display Name",
  "category": "character | enemy | tower | projectile | effect | ui | environment",

  "frames": {
    "count": 0,
    "fps": 12,
    "loop": true,
    "ping_pong": false
  },

  "sprite_sheet": {
    "path": "res://assets/animations/",
    "columns": 0,
    "rows": 0,
    "frame_width": 0,
    "frame_height": 0
  },

  "timing": {
    "duration": 0.0,
    "hold_frames": [],
    "events": []
  },

  "transitions": {
    "can_interrupt": true,
    "blend_in": 0.1,
    "blend_out": 0.1,
    "next_animation": null
  }
}
```

### Animation States

```gdscript
enum AnimationState {
    IDLE,
    MOVING,
    ATTACKING,
    HURT,
    DYING,
    DEAD,
    SPECIAL,
    STUNNED,
    CHANNELING
}
```

---

## Character Animations

### Player Avatar (Optional Visual)

```json
{
  "character_animations": {
    "player_idle": {
      "animation_id": "player_idle",
      "frames": {"count": 4, "fps": 6, "loop": true},
      "description": "Subtle breathing, occasional blink",
      "sprite_size": {"width": 64, "height": 64}
    },
    "player_typing": {
      "animation_id": "player_typing",
      "frames": {"count": 6, "fps": 12, "loop": true},
      "description": "Fingers moving on keyboard, focused expression",
      "sprite_size": {"width": 64, "height": 64},
      "sync_to_input": true
    },
    "player_typing_fast": {
      "animation_id": "player_typing_fast",
      "frames": {"count": 4, "fps": 18, "loop": true},
      "description": "Rapid typing animation for high WPM",
      "trigger": "wpm > 60"
    },
    "player_combo": {
      "animation_id": "player_combo",
      "frames": {"count": 8, "fps": 12, "loop": false},
      "description": "Excited expression, glowing hands",
      "trigger": "combo >= 10"
    },
    "player_error": {
      "animation_id": "player_error",
      "frames": {"count": 4, "fps": 8, "loop": false},
      "description": "Brief wince or frustration",
      "trigger": "typo_made"
    },
    "player_victory": {
      "animation_id": "player_victory",
      "frames": {"count": 12, "fps": 10, "loop": false},
      "description": "Celebratory pose, arms raised",
      "trigger": "wave_complete"
    },
    "player_defeat": {
      "animation_id": "player_defeat",
      "frames": {"count": 8, "fps": 8, "loop": false},
      "description": "Slumped shoulders, disappointed expression",
      "trigger": "castle_destroyed"
    }
  }
}
```

### NPC Animations

```json
{
  "npc_animations": {
    "npc_idle": {
      "animation_id": "npc_idle",
      "frames": {"count": 4, "fps": 4, "loop": true},
      "description": "Standard idle, subtle movement",
      "variants": ["npc_idle_look_around", "npc_idle_stretch"]
    },
    "npc_talking": {
      "animation_id": "npc_talking",
      "frames": {"count": 6, "fps": 8, "loop": true},
      "description": "Mouth movement, gestures",
      "sync_to_dialogue": true
    },
    "npc_react_positive": {
      "animation_id": "npc_react_positive",
      "frames": {"count": 6, "fps": 10, "loop": false},
      "description": "Smile, nod, pleased expression"
    },
    "npc_react_negative": {
      "animation_id": "npc_react_negative",
      "frames": {"count": 6, "fps": 10, "loop": false},
      "description": "Frown, shake head, concerned expression"
    },
    "npc_react_surprised": {
      "animation_id": "npc_react_surprised",
      "frames": {"count": 4, "fps": 12, "loop": false},
      "description": "Eyes widen, step back"
    }
  }
}
```

### NPC-Specific Animations

```json
{
  "elder_typhos": {
    "typhos_idle": {
      "frames": {"count": 6, "fps": 4},
      "description": "Slow, wise movements, stroking beard"
    },
    "typhos_teaching": {
      "frames": {"count": 8, "fps": 8},
      "description": "Gesturing while explaining, pointing to keyboard"
    },
    "typhos_concerned": {
      "frames": {"count": 4, "fps": 6},
      "description": "Furrowed brow, looking toward corruption"
    }
  },
  "blacksmith_garrett": {
    "garrett_idle": {
      "frames": {"count": 4, "fps": 4},
      "description": "Wiping hands, looking at forge"
    },
    "garrett_hammering": {
      "frames": {"count": 8, "fps": 12},
      "description": "Rhythmic hammering animation",
      "audio_sync": "sfx_hammer_strike"
    },
    "garrett_presenting": {
      "frames": {"count": 6, "fps": 8},
      "description": "Holding up crafted item proudly"
    }
  },
  "merchant_elise": {
    "elise_idle": {
      "frames": {"count": 4, "fps": 6},
      "description": "Organizing wares, cheerful posture"
    },
    "elise_selling": {
      "frames": {"count": 6, "fps": 8},
      "description": "Presenting items enthusiastically"
    },
    "elise_counting": {
      "frames": {"count": 4, "fps": 6},
      "description": "Counting coins"
    }
  }
}
```

---

## Enemy Animations

### Tier 1 Enemies

```json
{
  "typhos_spawn": {
    "animations": {
      "spawn": {
        "frames": {"count": 8, "fps": 12, "loop": false},
        "description": "Emerges from corruption puddle",
        "duration": 0.67
      },
      "idle": {
        "frames": {"count": 4, "fps": 6, "loop": true},
        "description": "Slight bobbing, corruption particles"
      },
      "walk": {
        "frames": {"count": 6, "fps": 10, "loop": true},
        "description": "Shambling movement toward castle"
      },
      "attack": {
        "frames": {"count": 6, "fps": 12, "loop": false},
        "description": "Lunging strike",
        "damage_frame": 4
      },
      "hurt": {
        "frames": {"count": 3, "fps": 12, "loop": false},
        "description": "Recoil, flash white"
      },
      "death": {
        "frames": {"count": 8, "fps": 10, "loop": false},
        "description": "Dissolves into letters, corruption disperses",
        "spawn_particles": "letter_burst"
      }
    },
    "sprite_size": {"width": 32, "height": 32},
    "origin": {"x": 16, "y": 28}
  },
  "word_imp": {
    "animations": {
      "spawn": {
        "frames": {"count": 6, "fps": 14, "loop": false},
        "description": "Pops into existence with spark"
      },
      "idle": {
        "frames": {"count": 4, "fps": 8, "loop": true},
        "description": "Jittery hovering"
      },
      "walk": {
        "frames": {"count": 4, "fps": 14, "loop": true},
        "description": "Fast hopping movement"
      },
      "death": {
        "frames": {"count": 6, "fps": 12, "loop": false},
        "description": "Pops like a bubble, letters scatter"
      }
    },
    "sprite_size": {"width": 24, "height": 24}
  }
}
```

### Tier 2 Enemies

```json
{
  "glitch_runner": {
    "animations": {
      "idle": {
        "frames": {"count": 4, "fps": 8, "loop": true},
        "description": "Flickering, unstable form"
      },
      "walk": {
        "frames": {"count": 6, "fps": 16, "loop": true},
        "description": "Fast glitchy movement with afterimages"
      },
      "teleport": {
        "frames": {"count": 4, "fps": 20, "loop": false},
        "description": "Short-range blink effect"
      },
      "death": {
        "frames": {"count": 6, "fps": 14, "loop": false},
        "description": "Glitch effect intensifies, breaks apart"
      }
    },
    "special_effects": {
      "afterimage": {
        "count": 3,
        "fade_time": 0.2,
        "spacing": 0.05
      }
    }
  },
  "shell_walker": {
    "animations": {
      "idle": {
        "frames": {"count": 4, "fps": 4, "loop": true},
        "description": "Slow, heavy breathing"
      },
      "walk": {
        "frames": {"count": 8, "fps": 6, "loop": true},
        "description": "Slow, deliberate steps with ground shake"
      },
      "armor_break": {
        "frames": {"count": 6, "fps": 10, "loop": false},
        "description": "Armor cracks and falls off",
        "trigger": "armor_depleted"
      },
      "death": {
        "frames": {"count": 10, "fps": 8, "loop": false},
        "description": "Collapses heavily, armor scatters"
      }
    },
    "sprite_size": {"width": 48, "height": 48}
  }
}
```

### Tier 3-4 Enemies

```json
{
  "syntax_horror": {
    "animations": {
      "idle": {
        "frames": {"count": 6, "fps": 6, "loop": true},
        "description": "Writhing tentacles of corrupted text"
      },
      "walk": {
        "frames": {"count": 8, "fps": 8, "loop": true},
        "description": "Slithering movement, leaving corruption trail"
      },
      "attack_melee": {
        "frames": {"count": 8, "fps": 12, "loop": false},
        "description": "Tentacle lash",
        "damage_frame": 5
      },
      "attack_ranged": {
        "frames": {"count": 10, "fps": 10, "loop": false},
        "description": "Spits corrupted letters",
        "projectile_spawn_frame": 6
      },
      "death": {
        "frames": {"count": 12, "fps": 10, "loop": false},
        "description": "Tentacles retract, core dissolves"
      }
    },
    "sprite_size": {"width": 64, "height": 64}
  },
  "paragraph_horror": {
    "animations": {
      "idle": {
        "frames": {"count": 8, "fps": 4, "loop": true},
        "description": "Massive form pulsing with corrupted text"
      },
      "walk": {
        "frames": {"count": 12, "fps": 6, "loop": true},
        "description": "Ponderous movement, screen shake"
      },
      "roar": {
        "frames": {"count": 10, "fps": 8, "loop": false},
        "description": "Opens maw, releases word-scramble wave"
      },
      "death": {
        "frames": {"count": 16, "fps": 8, "loop": false},
        "description": "Dramatic collapse, explosion of letters"
      }
    },
    "sprite_size": {"width": 96, "height": 96}
  }
}
```

### Boss Animations

```json
{
  "grove_guardian": {
    "sprite_size": {"width": 128, "height": 160},
    "animations": {
      "dormant": {
        "frames": {"count": 4, "fps": 2, "loop": true},
        "description": "Tree-like stillness, subtle bark movement"
      },
      "awakening": {
        "frames": {"count": 24, "fps": 12, "loop": false},
        "description": "Bark cracks, eyes open, limbs extend",
        "duration": 2.0,
        "camera_shake": true
      },
      "idle": {
        "frames": {"count": 6, "fps": 4, "loop": true},
        "description": "Slow swaying, corruption pulsing"
      },
      "branch_swipe": {
        "frames": {"count": 10, "fps": 14, "loop": false},
        "description": "Massive branch arm sweeps across arena",
        "damage_frame": 7,
        "telegraph_frames": [0, 1, 2, 3]
      },
      "root_eruption": {
        "frames": {"count": 12, "fps": 12, "loop": false},
        "description": "Ground cracks, roots burst upward",
        "damage_frame": 8
      },
      "summon_saplings": {
        "frames": {"count": 8, "fps": 10, "loop": false},
        "description": "Drops seeds that grow into corrupted saplings"
      },
      "phase_transition_1": {
        "frames": {"count": 16, "fps": 10, "loop": false},
        "description": "Roars, corruption spreads across body",
        "duration": 1.6
      },
      "phase_transition_2": {
        "frames": {"count": 20, "fps": 10, "loop": false},
        "description": "Bark cracks revealing glowing corruption core",
        "duration": 2.0
      },
      "death_normal": {
        "frames": {"count": 24, "fps": 8, "loop": false},
        "description": "Collapses, crumbles to wood and leaves",
        "duration": 3.0
      },
      "death_purified": {
        "frames": {"count": 30, "fps": 10, "loop": false},
        "description": "Corruption fades, returns to healthy tree briefly, then peaceful dissolution",
        "duration": 3.0
      }
    }
  },
  "stone_colossus": {
    "sprite_size": {"width": 160, "height": 192},
    "animations": {
      "sealed": {
        "frames": {"count": 1, "fps": 1, "loop": false},
        "description": "Statue-like stillness, chains visible"
      },
      "awakening": {
        "frames": {"count": 30, "fps": 10, "loop": false},
        "description": "Chains break one by one, runes ignite",
        "duration": 3.0
      },
      "idle": {
        "frames": {"count": 4, "fps": 3, "loop": true},
        "description": "Heavy breathing, runes pulsing"
      },
      "walk": {
        "frames": {"count": 12, "fps": 6, "loop": true},
        "description": "Earth-shaking steps",
        "screen_shake_per_step": true
      },
      "stone_fist": {
        "frames": {"count": 12, "fps": 12, "loop": false},
        "description": "Raises fist, slams down",
        "damage_frame": 9
      },
      "charge": {
        "frames": {"count": 8, "fps": 14, "loop": false},
        "description": "Lowers head, rushes forward"
      },
      "rune_beam": {
        "frames": {"count": 14, "fps": 10, "loop": false},
        "description": "Runes glow, beam fires from chest"
      },
      "crumbling": {
        "frames": {"count": 8, "fps": 6, "loop": true},
        "description": "Pieces falling off, sparking",
        "phase": 4
      },
      "death": {
        "frames": {"count": 36, "fps": 10, "loop": false},
        "description": "Falls apart piece by piece, runes fade",
        "duration": 3.6
      }
    }
  },
  "mist_wraith": {
    "sprite_size": {"width": 96, "height": 128},
    "animations": {
      "materialize": {
        "frames": {"count": 16, "fps": 12, "loop": false},
        "description": "Coalesces from mist into humanoid form"
      },
      "idle": {
        "frames": {"count": 8, "fps": 6, "loop": true},
        "description": "Floating, form constantly shifting"
      },
      "float": {
        "frames": {"count": 6, "fps": 8, "loop": true},
        "description": "Drifting movement"
      },
      "mist_touch": {
        "frames": {"count": 8, "fps": 12, "loop": false},
        "description": "Extends misty tendril to touch target"
      },
      "dissolve": {
        "frames": {"count": 10, "fps": 12, "loop": false},
        "description": "Becomes invisible mist briefly"
      },
      "reform": {
        "frames": {"count": 10, "fps": 12, "loop": false},
        "description": "Rematerializes from mist"
      },
      "cast_spell": {
        "frames": {"count": 12, "fps": 10, "loop": false},
        "description": "Hands glow, arcane symbols appear"
      },
      "death_destroyed": {
        "frames": {"count": 20, "fps": 10, "loop": false},
        "description": "Screams, dissipates into nothing"
      },
      "death_redeemed": {
        "frames": {"count": 30, "fps": 10, "loop": false},
        "description": "Form solidifies briefly into Vorthan, peaceful smile, fades to light"
      }
    }
  }
}
```

### Enemy Affix Visual Modifiers

```json
{
  "affix_animations": {
    "swift": {
      "overlay": "speed_lines",
      "animation_speed_multiplier": 1.3,
      "particle": "wind_trail"
    },
    "armored": {
      "overlay": "armor_plates",
      "tint": "#A0A0A0",
      "hit_effect": "spark_deflect"
    },
    "burning": {
      "overlay": "flame_aura",
      "particle": "fire_embers",
      "tint_pulse": "#FF4500"
    },
    "frozen": {
      "overlay": "ice_crystals",
      "animation_speed_multiplier": 0.5,
      "tint": "#87CEEB"
    },
    "shielded": {
      "overlay": "shield_bubble",
      "particle": "shield_sparkle"
    },
    "enraged": {
      "overlay": "rage_aura",
      "tint_pulse": "#FF0000",
      "scale_multiplier": 1.1
    },
    "vampiric": {
      "overlay": "blood_drip",
      "on_hit_effect": "life_drain_beam"
    },
    "toxic": {
      "overlay": "poison_cloud",
      "particle": "toxic_bubbles",
      "tint": "#9932CC"
    }
  }
}
```

---

## Tower Animations

### Basic Tower Animations

```json
{
  "tower_arrow": {
    "sprite_size": {"width": 48, "height": 64},
    "animations": {
      "build": {
        "frames": {"count": 12, "fps": 12, "loop": false},
        "description": "Construction animation, pieces assembling"
      },
      "idle": {
        "frames": {"count": 4, "fps": 4, "loop": true},
        "description": "Subtle sway, flag waving"
      },
      "aim": {
        "frames": {"count": 1, "fps": 1, "loop": false},
        "description": "Rotates toward target",
        "rotation_enabled": true
      },
      "fire": {
        "frames": {"count": 4, "fps": 16, "loop": false},
        "description": "Draw, release, recoil",
        "projectile_spawn_frame": 2
      },
      "upgrade": {
        "frames": {"count": 16, "fps": 12, "loop": false},
        "description": "Glowing, parts transform"
      },
      "sell": {
        "frames": {"count": 8, "fps": 10, "loop": false},
        "description": "Collapses into gold coins"
      }
    }
  },
  "tower_magic": {
    "sprite_size": {"width": 48, "height": 72},
    "animations": {
      "build": {
        "frames": {"count": 14, "fps": 12, "loop": false},
        "description": "Crystal grows from ground"
      },
      "idle": {
        "frames": {"count": 6, "fps": 6, "loop": true},
        "description": "Magical energy swirling"
      },
      "charge": {
        "frames": {"count": 6, "fps": 10, "loop": false},
        "description": "Energy gathering at top"
      },
      "fire": {
        "frames": {"count": 4, "fps": 14, "loop": false},
        "description": "Energy releases as bolt"
      }
    }
  },
  "tower_frost": {
    "sprite_size": {"width": 48, "height": 64},
    "animations": {
      "idle": {
        "frames": {"count": 4, "fps": 4, "loop": true},
        "description": "Frost particles, icy glow"
      },
      "fire": {
        "frames": {"count": 6, "fps": 12, "loop": false},
        "description": "Frost beam or shard launch"
      },
      "freeze_pulse": {
        "frames": {"count": 8, "fps": 10, "loop": false},
        "description": "AoE freeze effect expanding"
      }
    }
  },
  "tower_cannon": {
    "sprite_size": {"width": 64, "height": 56},
    "animations": {
      "idle": {
        "frames": {"count": 2, "fps": 2, "loop": true},
        "description": "Smoke wisps from barrel"
      },
      "aim": {
        "frames": {"count": 1, "fps": 1, "loop": false},
        "description": "Barrel rotates to target"
      },
      "fire": {
        "frames": {"count": 6, "fps": 14, "loop": false},
        "description": "Massive recoil, smoke burst",
        "screen_shake": true
      },
      "reload": {
        "frames": {"count": 8, "fps": 8, "loop": false},
        "description": "Loading next shell"
      }
    }
  }
}
```

### Advanced Tower Animations

```json
{
  "tower_tesla": {
    "sprite_size": {"width": 48, "height": 80},
    "animations": {
      "idle": {
        "frames": {"count": 6, "fps": 8, "loop": true},
        "description": "Electric arcs between coils"
      },
      "charge": {
        "frames": {"count": 8, "fps": 12, "loop": false},
        "description": "Energy builds up visibly"
      },
      "discharge": {
        "frames": {"count": 4, "fps": 16, "loop": false},
        "description": "Lightning bolt releases",
        "chain_effect": "lightning_arc"
      }
    }
  },
  "tower_summoner": {
    "sprite_size": {"width": 64, "height": 48},
    "animations": {
      "idle": {
        "frames": {"count": 8, "fps": 6, "loop": true},
        "description": "Runes glow and pulse"
      },
      "summoning": {
        "frames": {"count": 16, "fps": 10, "loop": false},
        "description": "Portal opens, creature emerges"
      },
      "portal_active": {
        "frames": {"count": 6, "fps": 8, "loop": true},
        "description": "Portal swirling while summons exist"
      }
    }
  },
  "tower_legendary_wordsmith": {
    "sprite_size": {"width": 80, "height": 96},
    "animations": {
      "idle": {
        "frames": {"count": 8, "fps": 6, "loop": true},
        "description": "Floating letters orbit the tower"
      },
      "typing_sync": {
        "frames": {"count": 4, "fps": 12, "loop": true},
        "description": "Pulses in sync with player typing",
        "sync_to_input": true
      },
      "word_forge": {
        "frames": {"count": 12, "fps": 10, "loop": false},
        "description": "Letters combine into glowing projectile"
      },
      "perfect_strike": {
        "frames": {"count": 16, "fps": 12, "loop": false},
        "description": "Massive beam of pure word energy"
      }
    }
  }
}
```

### Auto-Defense Tower Animations

```json
{
  "tower_auto_arrow": {
    "sprite_size": {"width": 48, "height": 64},
    "animations": {
      "idle": {
        "frames": {"count": 4, "fps": 4, "loop": true},
        "description": "Mechanical parts slowly moving"
      },
      "scanning": {
        "frames": {"count": 8, "fps": 8, "loop": true},
        "description": "Sensor sweeps for targets"
      },
      "target_lock": {
        "frames": {"count": 4, "fps": 12, "loop": false},
        "description": "Locks onto enemy, reticle appears"
      },
      "auto_fire": {
        "frames": {"count": 3, "fps": 18, "loop": false},
        "description": "Rapid automated shot"
      },
      "reload": {
        "frames": {"count": 6, "fps": 10, "loop": false},
        "description": "Mechanical reload"
      },
      "overheat": {
        "frames": {"count": 6, "fps": 6, "loop": true},
        "description": "Steam venting, red glow"
      },
      "cooldown": {
        "frames": {"count": 8, "fps": 8, "loop": false},
        "description": "Cooling down after overheat"
      }
    }
  },
  "tower_auto_sentry": {
    "sprite_size": {"width": 40, "height": 48},
    "animations": {
      "deploy": {
        "frames": {"count": 10, "fps": 12, "loop": false},
        "description": "Unfolds from compact form"
      },
      "idle": {
        "frames": {"count": 4, "fps": 6, "loop": true},
        "description": "Small movements, ready state"
      },
      "track": {
        "rotation_speed": 180,
        "description": "Rotates to follow target"
      },
      "burst_fire": {
        "frames": {"count": 6, "fps": 20, "loop": false},
        "description": "Three-round burst"
      },
      "pack_up": {
        "frames": {"count": 10, "fps": 12, "loop": false},
        "description": "Folds back into compact form"
      }
    }
  }
}
```

---

## Projectile Animations

### Physical Projectiles

```json
{
  "projectile_arrow": {
    "sprite_size": {"width": 16, "height": 4},
    "animations": {
      "flight": {
        "frames": {"count": 1, "fps": 1, "loop": false},
        "rotation": "follow_velocity",
        "trail": "arrow_trail"
      },
      "impact": {
        "frames": {"count": 4, "fps": 16, "loop": false},
        "description": "Arrow sticks, small dust puff"
      }
    }
  },
  "projectile_cannonball": {
    "sprite_size": {"width": 12, "height": 12},
    "animations": {
      "flight": {
        "frames": {"count": 2, "fps": 8, "loop": true},
        "rotation": "spin",
        "trail": "smoke_trail"
      },
      "impact": {
        "frames": {"count": 8, "fps": 14, "loop": false},
        "description": "Explosion, debris scatter",
        "spawn_effect": "explosion_medium"
      }
    }
  },
  "projectile_boulder": {
    "sprite_size": {"width": 24, "height": 24},
    "animations": {
      "flight": {
        "frames": {"count": 4, "fps": 10, "loop": true},
        "rotation": "tumble"
      },
      "impact": {
        "frames": {"count": 6, "fps": 12, "loop": false},
        "description": "Shatters into fragments",
        "screen_shake": true
      }
    }
  }
}
```

### Magical Projectiles

```json
{
  "projectile_magic_bolt": {
    "sprite_size": {"width": 16, "height": 16},
    "animations": {
      "flight": {
        "frames": {"count": 4, "fps": 12, "loop": true},
        "description": "Pulsing energy sphere",
        "trail": "magic_sparkle"
      },
      "impact": {
        "frames": {"count": 6, "fps": 14, "loop": false},
        "description": "Arcane burst"
      }
    }
  },
  "projectile_frost_shard": {
    "sprite_size": {"width": 12, "height": 20},
    "animations": {
      "flight": {
        "frames": {"count": 2, "fps": 8, "loop": true},
        "description": "Spinning ice crystal",
        "trail": "frost_particles"
      },
      "impact": {
        "frames": {"count": 6, "fps": 12, "loop": false},
        "description": "Shatters, frost spreads"
      }
    }
  },
  "projectile_lightning": {
    "sprite_size": {"width": 8, "height": "dynamic"},
    "animations": {
      "strike": {
        "frames": {"count": 3, "fps": 20, "loop": false},
        "description": "Jagged lightning bolt",
        "procedural": true
      },
      "chain": {
        "frames": {"count": 2, "fps": 20, "loop": false},
        "description": "Smaller arc to next target"
      }
    }
  },
  "projectile_word_beam": {
    "sprite_size": {"width": 32, "height": 8},
    "animations": {
      "charge": {
        "frames": {"count": 6, "fps": 10, "loop": false},
        "description": "Letters gathering"
      },
      "fire": {
        "frames": {"count": 4, "fps": 16, "loop": false},
        "description": "Beam of letters streaking forward"
      },
      "impact": {
        "frames": {"count": 8, "fps": 12, "loop": false},
        "description": "Letters scatter and fade"
      }
    }
  }
}
```

---

## Effect Animations

### Combat Effects

```json
{
  "combat_effects": {
    "hit_physical": {
      "frames": {"count": 4, "fps": 16},
      "description": "White flash, small sparks"
    },
    "hit_magic": {
      "frames": {"count": 5, "fps": 14},
      "description": "Arcane burst, colored by element"
    },
    "hit_critical": {
      "frames": {"count": 6, "fps": 14},
      "description": "Larger impact, screen shake, 'CRITICAL' text"
    },
    "heal": {
      "frames": {"count": 8, "fps": 10},
      "description": "Green particles rising"
    },
    "shield_hit": {
      "frames": {"count": 4, "fps": 12},
      "description": "Ripple effect on shield surface"
    },
    "shield_break": {
      "frames": {"count": 8, "fps": 14},
      "description": "Shield shatters into fragments"
    },
    "level_up": {
      "frames": {"count": 16, "fps": 12},
      "description": "Pillar of light, expanding rings"
    }
  }
}
```

### Status Effect Visuals

```json
{
  "status_effects": {
    "burning": {
      "overlay_animation": {
        "frames": {"count": 6, "fps": 10, "loop": true},
        "description": "Flames licking up the target"
      },
      "particle": "fire_embers"
    },
    "frozen": {
      "overlay_animation": {
        "frames": {"count": 4, "fps": 4, "loop": true},
        "description": "Ice crystals covering target"
      },
      "tint": "#87CEEB",
      "animation_speed": 0.3
    },
    "poisoned": {
      "overlay_animation": {
        "frames": {"count": 4, "fps": 6, "loop": true},
        "description": "Green bubbles rising"
      },
      "tint_pulse": "#9932CC"
    },
    "slowed": {
      "overlay_animation": {
        "frames": {"count": 4, "fps": 4, "loop": true},
        "description": "Blue particles trailing"
      },
      "animation_speed": 0.6
    },
    "stunned": {
      "overlay_animation": {
        "frames": {"count": 6, "fps": 8, "loop": true},
        "description": "Stars circling head"
      }
    },
    "corrupting": {
      "overlay_animation": {
        "frames": {"count": 8, "fps": 8, "loop": true},
        "description": "Dark tendrils spreading"
      },
      "shader": "corruption_spread"
    }
  }
}
```

### Word/Typing Effects

```json
{
  "typing_effects": {
    "word_complete": {
      "frames": {"count": 6, "fps": 14},
      "description": "Word glows, letters burst outward",
      "color": "#00FF00"
    },
    "word_error": {
      "frames": {"count": 4, "fps": 12},
      "description": "Red flash, shake effect",
      "color": "#FF0000"
    },
    "combo_increment": {
      "frames": {"count": 4, "fps": 12},
      "description": "Number pulses, particles rise"
    },
    "combo_break": {
      "frames": {"count": 6, "fps": 10},
      "description": "Counter shatters"
    },
    "perfect_word": {
      "frames": {"count": 8, "fps": 12},
      "description": "Golden glow, sparkle burst",
      "color": "#FFD700"
    },
    "letter_typed": {
      "frames": {"count": 2, "fps": 20},
      "description": "Subtle pulse on letter"
    }
  }
}
```

### Environmental Effects

```json
{
  "environment_effects": {
    "corruption_spread": {
      "frames": {"count": 12, "fps": 8, "loop": true},
      "description": "Dark tendrils creeping across ground"
    },
    "corruption_cleanse": {
      "frames": {"count": 16, "fps": 10, "loop": false},
      "description": "Light pushing back darkness"
    },
    "portal_open": {
      "frames": {"count": 12, "fps": 10, "loop": false},
      "description": "Swirling vortex forming"
    },
    "portal_active": {
      "frames": {"count": 8, "fps": 8, "loop": true},
      "description": "Stable portal swirling"
    },
    "portal_close": {
      "frames": {"count": 8, "fps": 12, "loop": false},
      "description": "Vortex collapses"
    }
  }
}
```

---

## UI Animations

### Menu Animations

```json
{
  "ui_animations": {
    "menu_slide_in": {
      "type": "tween",
      "property": "position",
      "duration": 0.3,
      "easing": "ease_out_back"
    },
    "menu_fade_in": {
      "type": "tween",
      "property": "modulate:a",
      "from": 0,
      "to": 1,
      "duration": 0.2
    },
    "button_hover": {
      "type": "tween",
      "property": "scale",
      "to": {"x": 1.05, "y": 1.05},
      "duration": 0.1
    },
    "button_press": {
      "type": "tween",
      "property": "scale",
      "to": {"x": 0.95, "y": 0.95},
      "duration": 0.05
    },
    "panel_bounce": {
      "type": "tween",
      "property": "scale",
      "keyframes": [
        {"time": 0, "value": {"x": 0.8, "y": 0.8}},
        {"time": 0.15, "value": {"x": 1.1, "y": 1.1}},
        {"time": 0.25, "value": {"x": 1, "y": 1}}
      ]
    }
  }
}
```

### HUD Animations

```json
{
  "hud_animations": {
    "health_change": {
      "type": "tween",
      "duration": 0.5,
      "properties": ["value", "tint_progress"]
    },
    "gold_add": {
      "type": "sprite",
      "frames": {"count": 6, "fps": 12},
      "description": "Coins flying to counter",
      "sound": "sfx_coin_collect"
    },
    "xp_add": {
      "type": "sprite",
      "frames": {"count": 8, "fps": 10},
      "description": "XP orbs flowing to bar"
    },
    "wave_counter_increment": {
      "type": "tween",
      "property": "scale",
      "keyframes": [
        {"time": 0, "value": {"x": 1.3, "y": 1.3}},
        {"time": 0.2, "value": {"x": 1, "y": 1}}
      ]
    },
    "combo_counter_update": {
      "type": "tween",
      "duration": 0.15,
      "property": "scale",
      "pulse": true
    },
    "damage_number_float": {
      "type": "tween",
      "property": "position:y",
      "offset": -30,
      "duration": 0.8,
      "fade_out": true
    }
  }
}
```

### Notification Animations

```json
{
  "notification_animations": {
    "achievement_popup": {
      "enter": {
        "type": "tween",
        "from": {"position:x": -300},
        "to": {"position:x": 20},
        "duration": 0.4,
        "easing": "ease_out_elastic"
      },
      "hold": {"duration": 3.0},
      "exit": {
        "type": "tween",
        "to": {"position:x": -300, "modulate:a": 0},
        "duration": 0.3
      }
    },
    "toast_message": {
      "enter": {
        "type": "tween",
        "from": {"modulate:a": 0, "position:y": 20},
        "to": {"modulate:a": 1, "position:y": 0},
        "duration": 0.2
      },
      "exit": {
        "type": "tween",
        "to": {"modulate:a": 0},
        "duration": 0.3
      }
    },
    "item_acquired": {
      "type": "composite",
      "animations": [
        {"type": "scale_bounce", "duration": 0.3},
        {"type": "glow_pulse", "duration": 0.5},
        {"type": "particle_burst", "particle": "sparkle"}
      ]
    }
  }
}
```

---

## Environmental Animations

### Background Animations

```json
{
  "background_animations": {
    "evergrove_trees": {
      "frames": {"count": 8, "fps": 4, "loop": true},
      "description": "Gentle swaying in wind"
    },
    "evergrove_leaves": {
      "type": "particle",
      "spawn_rate": 2,
      "description": "Floating leaves"
    },
    "stonepass_lava": {
      "frames": {"count": 6, "fps": 6, "loop": true},
      "description": "Bubbling lava pools"
    },
    "stonepass_crystals": {
      "frames": {"count": 4, "fps": 3, "loop": true},
      "description": "Pulsing glow"
    },
    "mistfen_fog": {
      "type": "shader",
      "description": "Drifting fog layers"
    },
    "mistfen_wisps": {
      "type": "particle",
      "spawn_rate": 1,
      "description": "Floating light orbs"
    }
  }
}
```

### Weather Animations

```json
{
  "weather_animations": {
    "rain": {
      "type": "particle",
      "density": 100,
      "speed": 400,
      "angle": -10,
      "splash_on_ground": true
    },
    "snow": {
      "type": "particle",
      "density": 50,
      "speed": 80,
      "drift": true,
      "accumulation": true
    },
    "storm": {
      "components": [
        {"type": "rain", "density": 150},
        {"type": "lightning", "interval": 5.0},
        {"type": "wind", "strength": 0.3}
      ]
    },
    "fog": {
      "type": "shader",
      "density": 0.5,
      "movement_speed": 0.1
    }
  }
}
```

---

## Cutscene Animations

### Intro Sequence

```json
{
  "cutscene_intro": {
    "scenes": [
      {
        "scene_id": "intro_1",
        "duration": 4.0,
        "background": "keystonia_overview",
        "animations": [
          {"type": "pan", "from": {"x": 0, "y": 0}, "to": {"x": 100, "y": 50}},
          {"type": "fade_in", "duration": 1.0}
        ],
        "text": "In the beginning, there was the Word..."
      },
      {
        "scene_id": "intro_2",
        "duration": 5.0,
        "background": "corruption_spreading",
        "animations": [
          {"type": "corruption_overlay", "spread_speed": 0.2}
        ],
        "text": "But then came the Corruption..."
      },
      {
        "scene_id": "intro_3",
        "duration": 4.0,
        "background": "defender_silhouette",
        "animations": [
          {"type": "character_reveal", "delay": 1.0}
        ],
        "text": "Now, a new Defender must rise..."
      }
    ]
  }
}
```

### Boss Introduction Cutscenes

```json
{
  "cutscene_grove_guardian": {
    "duration": 8.0,
    "scenes": [
      {
        "scene_id": "approach",
        "duration": 3.0,
        "camera": {"type": "dolly", "toward": "guardian_tree"},
        "ambient": "forest_wind_rising"
      },
      {
        "scene_id": "awakening",
        "duration": 5.0,
        "animations": [
          {"target": "guardian", "animation": "awakening"},
          {"type": "camera_shake", "intensity": 0.3},
          {"type": "lighting_shift", "to": "ominous"}
        ],
        "dialogue": {
          "speaker": "grove_guardian",
          "text": "INTRUDERS... IN MY... GROVE..."
        }
      }
    ]
  }
}
```

---

## Implementation Notes

### Animation Controller

```gdscript
class_name AnimationController
extends Node

@export var animation_player: AnimationPlayer
@export var sprite: Sprite2D

var current_state: String = "idle"
var queued_animation: String = ""
var animation_speed_multiplier: float = 1.0

func play_animation(anim_name: String, force: bool = false) -> void:
    if not force and not can_interrupt(current_state):
        queued_animation = anim_name
        return

    current_state = anim_name
    animation_player.play(anim_name)
    animation_player.speed_scale = animation_speed_multiplier

func can_interrupt(state: String) -> bool:
    match state:
        "death", "special":
            return false
        "attack":
            return animation_player.current_animation_position > 0.5
        _:
            return true

func _on_animation_finished(anim_name: String) -> void:
    if queued_animation != "":
        play_animation(queued_animation, true)
        queued_animation = ""
    elif anim_name != "idle":
        play_animation("idle")

func apply_status_effect(effect_id: String) -> void:
    var effect_data = StatusEffectDB.get_visual(effect_id)
    if effect_data.has("animation_speed"):
        animation_speed_multiplier = effect_data.animation_speed
    if effect_data.has("tint"):
        sprite.modulate = Color(effect_data.tint)
```

### Sprite Sheet Organization

```
res://assets/animations/
├── characters/
│   ├── player/
│   │   └── player_spritesheet.png
│   └── npcs/
│       ├── elder_typhos.png
│       ├── blacksmith_garrett.png
│       └── ...
├── enemies/
│   ├── tier1/
│   │   ├── typhos_spawn.png
│   │   └── word_imp.png
│   ├── tier2/
│   ├── tier3/
│   ├── tier4/
│   ├── tier5/
│   └── bosses/
│       ├── grove_guardian.png
│       ├── stone_colossus.png
│       └── mist_wraith.png
├── towers/
│   ├── basic/
│   ├── advanced/
│   ├── auto/
│   └── legendary/
├── projectiles/
├── effects/
│   ├── combat/
│   ├── status/
│   └── typing/
└── ui/
```

---

**Document version:** 1.0
**Animation categories:** 9
**Total animation definitions:** 200+
