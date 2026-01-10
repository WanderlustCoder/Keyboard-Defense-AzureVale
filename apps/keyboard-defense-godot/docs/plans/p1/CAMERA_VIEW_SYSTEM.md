# Camera and View System

**Version:** 1.0.0
**Last Updated:** 2026-01-09
**Status:** Implementation Ready

## Overview

The camera system controls how players view the game world across different modes: tower defense battles, open world exploration, and UI screens. It provides smooth transitions, responsive controls, and accessibility options.

---

## Camera Modes

### Battle Camera (Tower Defense)

```json
{
  "mode_id": "battle",
  "name": "Battle Camera",
  "description": "Fixed overhead view for tower defense gameplay",
  "camera_type": "orthographic",
  "default_settings": {
    "angle": "top_down_isometric",
    "pitch": 60,
    "rotation": 45,
    "zoom_level": 1.0,
    "follow_target": null
  },
  "bounds": {
    "constrained_to": "map_bounds",
    "edge_padding": 64
  },
  "controls": {
    "pan": {
      "enabled": true,
      "methods": ["wasd", "arrow_keys", "edge_scroll", "middle_mouse_drag"],
      "speed": 400,
      "smoothing": 0.15
    },
    "zoom": {
      "enabled": true,
      "methods": ["scroll_wheel", "plus_minus_keys", "pinch_gesture"],
      "min_zoom": 0.5,
      "max_zoom": 2.0,
      "default_zoom": 1.0,
      "zoom_speed": 0.1,
      "smooth_zoom": true
    },
    "rotate": {
      "enabled": false,
      "reason": "Fixed perspective for consistent gameplay"
    }
  },
  "auto_features": {
    "snap_to_action": {
      "enabled": true,
      "trigger": "Boss spawn, base breach, wave start",
      "speed": "fast",
      "override_player": false
    },
    "show_full_map": {
      "hotkey": "Tab",
      "zoom_to": "fit_entire_map",
      "duration": "hold"
    }
  }
}
```

### Exploration Camera (Open World)

```json
{
  "mode_id": "exploration",
  "name": "Exploration Camera",
  "description": "Follows player character through the overworld",
  "camera_type": "orthographic",
  "default_settings": {
    "angle": "top_down",
    "pitch": 90,
    "rotation": 0,
    "zoom_level": 1.0,
    "follow_target": "player"
  },
  "follow_settings": {
    "smoothing": 0.1,
    "dead_zone": {
      "enabled": true,
      "size": {"x": 100, "y": 75}
    },
    "look_ahead": {
      "enabled": true,
      "distance": 50,
      "based_on": "movement_direction"
    },
    "bounds": {
      "respect_room_bounds": true,
      "smooth_transition_at_edges": true
    }
  },
  "controls": {
    "pan": {
      "enabled": false,
      "reason": "Camera follows player"
    },
    "zoom": {
      "enabled": true,
      "min_zoom": 0.75,
      "max_zoom": 1.5,
      "default_zoom": 1.0
    },
    "rotate": {
      "enabled": false
    }
  },
  "special_behaviors": {
    "dialogue_zoom": {
      "trigger": "NPC conversation",
      "zoom_to": 1.3,
      "center_on": "midpoint_player_npc"
    },
    "poi_reveal": {
      "trigger": "Enter new POI",
      "action": "Quick pan to show area",
      "duration": 1.5
    },
    "cutscene_override": {
      "enabled": true,
      "scripted_paths": true
    }
  }
}
```

### Menu Camera

```json
{
  "mode_id": "menu",
  "name": "Menu Camera",
  "description": "Static or animated background for menu screens",
  "camera_type": "orthographic",
  "settings": {
    "static_backgrounds": ["Main menu", "Settings", "Credits"],
    "animated_backgrounds": ["Level select (slow pan)", "World map (cloud drift)"]
  },
  "transitions": {
    "menu_to_game": "fade_out",
    "game_to_menu": "fade_in"
  }
}
```

---

## Zoom System

### Zoom Levels

```json
{
  "zoom_levels": {
    "battle_mode": [
      {
        "level": 0.5,
        "name": "Strategic",
        "description": "See entire map",
        "use_case": "Planning, large maps"
      },
      {
        "level": 0.75,
        "name": "Tactical",
        "description": "Good overview with detail",
        "use_case": "Standard play"
      },
      {
        "level": 1.0,
        "name": "Normal",
        "description": "Default zoom",
        "use_case": "Most gameplay"
      },
      {
        "level": 1.5,
        "name": "Close",
        "description": "See fine details",
        "use_case": "Precise placement, enjoying visuals"
      },
      {
        "level": 2.0,
        "name": "Detail",
        "description": "Maximum zoom",
        "use_case": "Accessibility, screenshots"
      }
    ],
    "zoom_presets": {
      "hotkeys": {
        "1": 0.5,
        "2": 0.75,
        "3": 1.0,
        "4": 1.5,
        "5": 2.0
      },
      "double_click_zoom": {
        "enabled": true,
        "target": "clicked_position",
        "zoom_to": 1.5
      }
    }
  }
}
```

### Zoom Transitions

```json
{
  "zoom_transitions": {
    "scroll_wheel": {
      "increment": 0.1,
      "smooth": true,
      "easing": "ease_out",
      "duration": 0.2
    },
    "preset_jump": {
      "smooth": true,
      "easing": "ease_in_out",
      "duration": 0.3
    },
    "auto_zoom": {
      "smooth": true,
      "easing": "ease_in_out",
      "duration": 0.5
    },
    "zoom_to_fit": {
      "adds_padding": 50,
      "max_zoom": 1.5,
      "min_zoom": 0.5
    }
  }
}
```

---

## Camera Shake

### Shake Events

```json
{
  "camera_shake": {
    "enabled": true,
    "global_intensity": 1.0,
    "can_disable": true,
    "events": [
      {
        "event": "enemy_reaches_base",
        "intensity": 0.5,
        "duration": 0.3,
        "decay": "linear"
      },
      {
        "event": "tower_destroyed",
        "intensity": 0.6,
        "duration": 0.4,
        "decay": "exponential"
      },
      {
        "event": "boss_attack",
        "intensity": 0.8,
        "duration": 0.5,
        "decay": "exponential"
      },
      {
        "event": "critical_hit",
        "intensity": 0.2,
        "duration": 0.1,
        "decay": "instant"
      },
      {
        "event": "super_critical",
        "intensity": 0.7,
        "duration": 0.4,
        "decay": "bounce"
      },
      {
        "event": "explosion",
        "intensity": 0.4,
        "duration": 0.25,
        "decay": "exponential",
        "falloff_by_distance": true
      },
      {
        "event": "typing_error",
        "intensity": 0.15,
        "duration": 0.1,
        "decay": "instant"
      },
      {
        "event": "combo_break",
        "intensity": 0.3,
        "duration": 0.2,
        "decay": "linear"
      }
    ]
  }
}
```

### Shake Settings

```json
{
  "shake_settings": {
    "trauma_system": {
      "enabled": true,
      "max_trauma": 1.0,
      "decay_rate": 0.8,
      "multiple_events_stack": true,
      "cap_at_max": true
    },
    "shake_parameters": {
      "max_offset_x": 10,
      "max_offset_y": 10,
      "max_rotation": 2,
      "noise_based": true,
      "perlin_frequency": 15
    },
    "accessibility": {
      "intensity_slider": {"min": 0, "max": 1, "default": 1},
      "disable_option": true,
      "reduce_for_motion_sensitivity": true
    }
  }
}
```

---

## Camera Transitions

### Scene Transitions

```json
{
  "scene_transitions": {
    "level_start": {
      "type": "zoom_in_fade",
      "from_zoom": 0.3,
      "to_zoom": 1.0,
      "duration": 1.0,
      "fade_color": "#000000",
      "shows": "Map overview then normal view"
    },
    "level_complete": {
      "type": "slow_zoom_out",
      "to_zoom": 0.5,
      "duration": 2.0,
      "shows": "Full map celebration"
    },
    "level_failed": {
      "type": "shake_then_fade",
      "shake_duration": 0.5,
      "fade_duration": 1.0,
      "fade_color": "#330000"
    },
    "battle_to_exploration": {
      "type": "fade_through_black",
      "duration": 0.8
    },
    "exploration_to_battle": {
      "type": "zoom_focus_fade",
      "focus_on": "battle_start_position",
      "duration": 1.0
    },
    "cutscene_enter": {
      "type": "letterbox_fade",
      "letterbox_ratio": 2.35,
      "duration": 0.5
    },
    "cutscene_exit": {
      "type": "letterbox_remove",
      "duration": 0.3
    }
  }
}
```

### In-Level Transitions

```json
{
  "in_level_transitions": {
    "wave_start": {
      "action": "Brief pan to spawn point",
      "duration": 0.8,
      "return_to": "previous_position"
    },
    "boss_spawn": {
      "action": "Dramatic zoom and pan to boss",
      "duration": 1.5,
      "shake": "rumble",
      "return_to": "fit_boss_and_base"
    },
    "tower_placed": {
      "action": "Subtle focus on new tower",
      "duration": 0.3,
      "only_if": "not_in_build_mode"
    },
    "enemy_killed_offscreen": {
      "action": "None",
      "reason": "Don't interrupt player view"
    },
    "base_danger": {
      "action": "Subtle pull toward base",
      "trigger": "enemy_within_3_tiles",
      "intensity": "gentle"
    }
  }
}
```

---

## Focus Systems

### Auto-Focus

```json
{
  "auto_focus": {
    "battle_mode": {
      "focus_priority": [
        {"target": "boss", "priority": 1, "conditions": "boss_active"},
        {"target": "base_threat", "priority": 2, "conditions": "enemy_near_base"},
        {"target": "player_interest", "priority": 3, "conditions": "cursor_activity"},
        {"target": "center_of_action", "priority": 4, "conditions": "default"}
      ],
      "blend_mode": "weighted_average",
      "responsiveness": 0.1
    },
    "exploration_mode": {
      "focus_priority": [
        {"target": "player", "priority": 1, "conditions": "always"}
      ],
      "look_ahead": true,
      "npc_focus_on_dialogue": true
    },
    "manual_override": {
      "enabled": true,
      "trigger": "player_pans_camera",
      "auto_resume_after": 5.0
    }
  }
}
```

### Point of Interest Focus

```json
{
  "poi_focus": {
    "enabled_in": ["exploration", "battle_planning"],
    "trigger": "click_on_poi",
    "behavior": {
      "pan_to": "poi_center",
      "zoom_to": "poi_appropriate_zoom",
      "hold_duration": 2.0,
      "return_on": "any_input"
    },
    "poi_types": {
      "enemy_spawner": {"zoom": 1.2, "highlight": true},
      "treasure_chest": {"zoom": 1.3, "highlight": true},
      "npc": {"zoom": 1.4, "prepare_dialogue": true},
      "tower_slot": {"zoom": 1.0, "show_range": true}
    }
  }
}
```

---

## Minimap System

### Minimap Configuration

```json
{
  "minimap": {
    "enabled": true,
    "position": "top_right",
    "size": {
      "default": {"width": 200, "height": 150},
      "expanded": {"width": 400, "height": 300},
      "toggle_hotkey": "M"
    },
    "display_elements": {
      "terrain": true,
      "paths": true,
      "towers": {
        "show": true,
        "icon": "dot",
        "color": "by_type"
      },
      "enemies": {
        "show": true,
        "icon": "dot",
        "color": "red",
        "boss_icon": "skull"
      },
      "player": {
        "show": true,
        "icon": "arrow",
        "shows_direction": true
      },
      "objective_markers": true,
      "fog_of_war": "exploration_only"
    },
    "camera_viewport": {
      "show": true,
      "style": "rectangle",
      "color": "#FFFFFF40",
      "click_to_pan": true
    },
    "opacity": {
      "default": 0.8,
      "on_hover": 1.0,
      "adjustable": true
    }
  }
}
```

### Minimap Interactions

```json
{
  "minimap_interactions": {
    "left_click": {
      "action": "Pan main camera to location",
      "smooth": true
    },
    "right_click": {
      "action": "Set waypoint marker",
      "max_markers": 3
    },
    "scroll": {
      "action": "Zoom minimap",
      "affects_main": false
    },
    "drag": {
      "action": "Pan minimap view",
      "when": "minimap_expanded"
    },
    "double_click": {
      "action": "Center and zoom main camera"
    }
  }
}
```

---

## View Layers

### Layer System

```json
{
  "view_layers": {
    "layer_order": [
      {"layer": "background", "z": 0},
      {"layer": "terrain", "z": 1},
      {"layer": "paths", "z": 2},
      {"layer": "ground_effects", "z": 3},
      {"layer": "buildings", "z": 4},
      {"layer": "enemies", "z": 5},
      {"layer": "projectiles", "z": 6},
      {"layer": "effects", "z": 7},
      {"layer": "ui_world", "z": 8},
      {"layer": "fog", "z": 9}
    ],
    "dynamic_sorting": {
      "within_layer": "by_y_position",
      "ensures": "Proper occlusion for isometric view"
    }
  }
}
```

### Layer Toggles (Debug/Accessibility)

```json
{
  "layer_toggles": {
    "tower_ranges": {
      "default": "on_hover",
      "toggle_key": "R",
      "shows": "Circle around each tower"
    },
    "enemy_paths": {
      "default": "hidden",
      "toggle_key": "P",
      "shows": "Lines showing enemy routes"
    },
    "damage_numbers": {
      "default": "on",
      "toggle_in": "settings",
      "shows": "Floating damage text"
    },
    "grid_overlay": {
      "default": "hidden",
      "toggle_key": "G",
      "shows": "Tile grid"
    }
  }
}
```

---

## Screen Effects

### Post-Processing

```json
{
  "post_processing": {
    "vignette": {
      "enabled": true,
      "default_intensity": 0.2,
      "dynamic": {
        "low_health": {"intensity": 0.5, "color": "#330000"},
        "high_combo": {"intensity": 0.1, "color": "#FFD700"},
        "boss_fight": {"intensity": 0.3, "color": "#000000"}
      }
    },
    "color_grading": {
      "enabled": true,
      "per_region": true,
      "examples": {
        "verdant_grove": "lush_green_boost",
        "ember_wastes": "warm_orange_tint",
        "frost_peaks": "cool_blue_shift"
      }
    },
    "bloom": {
      "enabled": true,
      "intensity": 0.3,
      "threshold": 0.8,
      "on_magic_effects": 0.5
    },
    "accessibility_options": {
      "disable_all": true,
      "individual_toggles": true
    }
  }
}
```

### Damage Flash

```json
{
  "damage_flash": {
    "trigger": "Player takes damage",
    "effect": "Red screen flash",
    "intensity_scales_with": "damage_percent",
    "duration": 0.2,
    "max_intensity": 0.3,
    "disable_option": true
  }
}
```

---

## Accessibility Options

### Camera Accessibility

```json
{
  "camera_accessibility": {
    "reduced_motion": {
      "setting": true,
      "effects": [
        "Disable camera shake",
        "Instant zoom (no smooth)",
        "Reduced transition effects",
        "Static backgrounds"
      ]
    },
    "high_contrast_mode": {
      "setting": true,
      "effects": [
        "Simplified color palette",
        "Bold outlines on units",
        "Reduced visual noise"
      ]
    },
    "zoom_override": {
      "min_zoom_override": 0.25,
      "max_zoom_override": 4.0,
      "for": "Vision impaired users"
    },
    "edge_scroll_sensitivity": {
      "adjustable": true,
      "disable_option": true
    },
    "screen_reader_camera": {
      "announce_transitions": true,
      "describe_view": "on_request"
    }
  }
}
```

---

## Resolution and Aspect Ratio

### Display Settings

```json
{
  "display_settings": {
    "supported_resolutions": [
      "1280x720",
      "1366x768",
      "1920x1080",
      "2560x1440",
      "3840x2160"
    ],
    "aspect_ratios": {
      "16:9": "native",
      "16:10": "letterbox_or_expand",
      "21:9": "expand_horizontal",
      "4:3": "pillarbox"
    },
    "scaling_mode": "pixel_perfect_or_smooth",
    "ui_scaling": {
      "auto": true,
      "manual_override": {"min": 0.75, "max": 1.5}
    }
  }
}
```

### Fullscreen Handling

```json
{
  "fullscreen": {
    "modes": ["windowed", "borderless_fullscreen", "exclusive_fullscreen"],
    "default": "borderless_fullscreen",
    "toggle_hotkey": "Alt+Enter",
    "remember_window_position": true,
    "multi_monitor_support": true
  }
}
```

---

## Implementation Notes

### Godot-Specific

```gdscript
# Camera2D setup for battle mode
extends Camera2D

var target_zoom: Vector2 = Vector2(1.0, 1.0)
var shake_intensity: float = 0.0
var shake_decay: float = 0.8

func _process(delta):
    # Smooth zoom
    zoom = zoom.lerp(target_zoom, 10 * delta)

    # Camera shake
    if shake_intensity > 0:
        offset = Vector2(
            randf_range(-1, 1) * shake_intensity * 10,
            randf_range(-1, 1) * shake_intensity * 10
        )
        shake_intensity = max(0, shake_intensity - shake_decay * delta)
    else:
        offset = Vector2.ZERO

func add_shake(amount: float):
    shake_intensity = min(shake_intensity + amount, 1.0)

func set_zoom_level(level: float):
    target_zoom = Vector2(level, level)
```

---

## Testing Scenarios

```json
{
  "test_scenarios": [
    {
      "name": "Zoom Range",
      "test": "Zoom in and out through full range",
      "expected": "Smooth transitions, no visual artifacts"
    },
    {
      "name": "Edge Panning",
      "test": "Move cursor to screen edges",
      "expected": "Camera pans smoothly, stops at bounds"
    },
    {
      "name": "Camera Shake Stack",
      "test": "Multiple shake events in quick succession",
      "expected": "Shakes combine without exceeding max"
    },
    {
      "name": "Resolution Change",
      "test": "Switch resolutions mid-game",
      "expected": "Camera adjusts, UI remains usable"
    },
    {
      "name": "Minimap Click",
      "test": "Click various minimap locations",
      "expected": "Main camera pans to clicked location"
    },
    {
      "name": "Reduced Motion",
      "test": "Enable reduced motion, trigger all effects",
      "expected": "No shake, instant transitions"
    }
  ]
}
```

---

*End of Camera and View System Document*
