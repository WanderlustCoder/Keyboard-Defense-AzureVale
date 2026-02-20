# Sprite Usage and Animation Guide

**Version:** 1.0.0
**Last Updated:** 2026-01-09
**Status:** Implementation Ready

## Overview

This document defines standards for creating, organizing, and implementing sprites in Keyboard Defense. Consistent sprite usage ensures visual coherence, optimal performance, and maintainable art assets.

**Important:** All art assets for this project are created by Claude Code using:
1. **SVG generation** - Writing SVG markup directly to files
2. **Godot draw primitives** - Using `_draw()` for procedural graphics
3. **Procedural generation** - GDScript-based texture/pattern creation
4. **Placeholders** - Colored rectangles with labels for rapid prototyping

This guide serves as the implementation specification for Claude Code when generating visual assets.

---

## Technical Specifications

### Base Units and Grid

```json
{
  "grid_system": {
    "base_tile_size": 32,
    "sub_tile": 16,
    "large_tile": 64,
    "description": "All sprites align to 32px grid, with 16px for fine detail"
  },
  "pixel_density": {
    "standard": "1x (32px = 1 tile)",
    "retina": "2x (64px = 1 tile) for high-DPI displays"
  },
  "coordinate_origin": "top_left",
  "y_axis": "down_positive"
}
```

### Standard Sprite Dimensions

| Entity Type | Base Size | Animation Frame Size | Notes |
|-------------|-----------|---------------------|-------|
| Player Character | 32x32 | 32x32 | Single tile footprint |
| Standard Enemy | 32x32 | 32x32 | Fits one tile |
| Large Enemy | 64x64 | 64x64 | 2x2 tile footprint |
| Boss Enemy | 128x128 | 128x128 | 4x4 tile footprint |
| Tower (Tier 1-2) | 32x48 | 32x48 | Taller than wide |
| Tower (Tier 3-4) | 48x64 | 48x64 | Larger presence |
| Projectile | 16x16 | 16x16 | Small, fast-moving |
| Effect/Particle | 32x32 | 32x32 | Standard effect size |
| Large Effect | 64x64 | 64x64 | Explosions, big impacts |
| UI Icon | 32x32 | N/A | Static icons |
| UI Icon (Small) | 16x16 | N/A | Inventory, status |
| Tile/Terrain | 32x32 | 32x32 | Map tiles |

### Color Depth and Format

```json
{
  "file_format": {
    "sprites": "PNG",
    "sprite_sheets": "PNG",
    "reason": "Lossless compression, alpha transparency support"
  },
  "color_depth": {
    "standard": "32-bit RGBA",
    "indexed": "Optional for retro aesthetic (256 colors)"
  },
  "transparency": {
    "type": "Alpha channel",
    "avoid": "Color key transparency",
    "premultiplied_alpha": false
  },
  "compression": {
    "png_compression": "Maximum (lossless)",
    "no_jpeg": "Never use JPEG for sprites"
  }
}
```

---

## Art Style Guidelines

### Visual Style

```json
{
  "art_style": {
    "name": "Modern Pixel Art",
    "description": "Clean pixel art with limited anti-aliasing, readable at small sizes",
    "influences": ["Kingdom Rush", "Wargroove", "Into the Breach"],
    "key_principles": [
      "Readability over detail",
      "Consistent lighting direction",
      "Limited color palette per sprite",
      "Clear silhouettes"
    ]
  }
}
```

### Lighting and Shading

```json
{
  "lighting": {
    "global_light_direction": "top_left (315 degrees)",
    "shadow_direction": "bottom_right",
    "shading_style": "cel_shaded",
    "shading_levels": {
      "base": "100% brightness",
      "shadow_1": "75% brightness",
      "shadow_2": "50% brightness (deep shadow)",
      "highlight": "115% brightness"
    },
    "avoid": [
      "Pillow shading (light from all sides)",
      "Banding (visible color steps)",
      "Dithering (unless stylistic choice)"
    ]
  }
}
```

### Outline Standards

```json
{
  "outlines": {
    "characters_and_enemies": {
      "enabled": true,
      "thickness": 1,
      "color": "darker_than_adjacent (not pure black)",
      "method": "selective_outline",
      "description": "Outline only where needed for readability"
    },
    "towers": {
      "enabled": true,
      "thickness": 1,
      "color": "#1a1a2e",
      "method": "full_outline"
    },
    "projectiles": {
      "enabled": false,
      "reason": "Too small, would look cluttered"
    },
    "effects": {
      "enabled": false,
      "reason": "Effects should feel ethereal"
    },
    "ui_icons": {
      "enabled": true,
      "thickness": 1,
      "color": "#000000"
    }
  }
}
```

---

## Color Palette

### Master Palette

```json
{
  "master_palette": {
    "description": "All sprites should use colors from or derived from this palette",
    "colors": {
      "blacks_grays": [
        {"name": "void", "hex": "#0a0a0f"},
        {"name": "charcoal", "hex": "#1a1a2e"},
        {"name": "slate", "hex": "#3d3d5c"},
        {"name": "stone", "hex": "#5c5c7a"},
        {"name": "silver", "hex": "#8b8ba8"},
        {"name": "cloud", "hex": "#c4c4d4"},
        {"name": "white", "hex": "#f0f0f5"}
      ],
      "warm_colors": [
        {"name": "blood", "hex": "#8b0000"},
        {"name": "crimson", "hex": "#dc143c"},
        {"name": "flame", "hex": "#ff4500"},
        {"name": "orange", "hex": "#ff8c00"},
        {"name": "gold", "hex": "#ffd700"},
        {"name": "yellow", "hex": "#ffeb3b"}
      ],
      "cool_colors": [
        {"name": "navy", "hex": "#000080"},
        {"name": "royal", "hex": "#4169e1"},
        {"name": "sky", "hex": "#87ceeb"},
        {"name": "cyan", "hex": "#00ffff"},
        {"name": "teal", "hex": "#008080"}
      ],
      "nature_colors": [
        {"name": "forest", "hex": "#228b22"},
        {"name": "grass", "hex": "#32cd32"},
        {"name": "lime", "hex": "#90ee90"},
        {"name": "earth", "hex": "#8b4513"},
        {"name": "sand", "hex": "#deb887"}
      ],
      "magic_colors": [
        {"name": "purple", "hex": "#800080"},
        {"name": "violet", "hex": "#9370db"},
        {"name": "magenta", "hex": "#ff00ff"},
        {"name": "pink", "hex": "#ff69b4"}
      ]
    }
  }
}
```

### Entity Color Coding

```json
{
  "entity_colors": {
    "player": {
      "primary": "#4169e1",
      "secondary": "#ffd700",
      "accent": "#f0f0f5"
    },
    "enemies": {
      "standard": "#dc143c",
      "elite": "#800080",
      "boss": "#8b0000"
    },
    "towers": {
      "arrow": "#8b4513",
      "magic": "#9370db",
      "fire": "#ff4500",
      "ice": "#87ceeb",
      "nature": "#32cd32",
      "auto": "#5c5c7a"
    },
    "effects": {
      "damage": "#ff4500",
      "healing": "#32cd32",
      "buff": "#ffd700",
      "debuff": "#800080"
    },
    "rarity": {
      "common": "#c4c4d4",
      "uncommon": "#32cd32",
      "rare": "#4169e1",
      "epic": "#9370db",
      "legendary": "#ffd700"
    }
  }
}
```

---

## Sprite Sheet Organization

### Sheet Layout

```json
{
  "sprite_sheet_layout": {
    "orientation": "horizontal_rows",
    "row_organization": "one_animation_per_row",
    "frame_order": "left_to_right",
    "padding": {
      "between_frames": 0,
      "sheet_border": 0,
      "reason": "Texture atlas packing handles padding"
    },
    "power_of_two": {
      "required": false,
      "recommended": true,
      "reason": "Better GPU memory alignment"
    }
  }
}
```

### Standard Sheet Structure

```
sprite_sheet.png
├── Row 0: Idle animation (4-8 frames)
├── Row 1: Walk/Move animation (6-8 frames)
├── Row 2: Attack animation (4-6 frames)
├── Row 3: Hurt animation (2-4 frames)
├── Row 4: Death animation (6-10 frames)
├── Row 5: Special animation (varies)
└── Row N: Additional animations
```

### Example Sheet Dimensions

| Entity | Frame Size | Frames/Row | Rows | Total Sheet Size |
|--------|-----------|-----------|------|------------------|
| Player | 32x32 | 8 | 6 | 256x192 |
| Enemy (Standard) | 32x32 | 8 | 5 | 256x160 |
| Enemy (Large) | 64x64 | 6 | 5 | 384x320 |
| Boss | 128x128 | 6 | 8 | 768x1024 |
| Tower | 32x48 | 4 | 4 | 128x192 |
| Effect | 32x32 | 8 | 1 | 256x32 |

---

## Animation Standards

### Frame Rates

```json
{
  "frame_rates": {
    "default": 12,
    "slow": 8,
    "fast": 16,
    "very_fast": 24,
    "by_animation_type": {
      "idle": 8,
      "walk": 12,
      "run": 16,
      "attack": 12,
      "hurt": 16,
      "death": 10,
      "cast_spell": 12,
      "projectile_travel": 24,
      "explosion": 16,
      "ambient_loop": 6,
      "ui_pulse": 8
    }
  }
}
```

### Animation Loops

```json
{
  "loop_settings": {
    "looping_animations": [
      "idle",
      "walk",
      "run",
      "ambient",
      "scanning",
      "charging"
    ],
    "one_shot_animations": [
      "attack",
      "hurt",
      "death",
      "spawn",
      "ability_cast",
      "explosion"
    ],
    "ping_pong_animations": [
      "breathe",
      "hover",
      "sway"
    ],
    "transition_handling": {
      "interrupt_on_action": true,
      "blend_frames": false,
      "return_to": "idle"
    }
  }
}
```

### Frame Count Guidelines

| Animation Type | Minimum Frames | Recommended | Maximum |
|---------------|---------------|-------------|---------|
| Idle | 2 | 4-6 | 8 |
| Walk | 4 | 6-8 | 12 |
| Run | 4 | 6-8 | 10 |
| Attack | 3 | 4-6 | 8 |
| Hurt | 2 | 2-3 | 4 |
| Death | 4 | 6-8 | 12 |
| Spawn | 4 | 6-8 | 10 |
| Ability | 4 | 6-8 | 12 |
| Effect Burst | 4 | 6-8 | 12 |

### Animation Timing Principles

```json
{
  "timing_principles": {
    "anticipation": {
      "description": "Wind-up before action",
      "frames": "1-2 before main action",
      "use_for": ["attacks", "jumps", "throws"]
    },
    "action": {
      "description": "The main motion",
      "frames": "2-4 frames",
      "hold_key_frame": true
    },
    "follow_through": {
      "description": "Recovery after action",
      "frames": "1-2 after main action",
      "use_for": ["attacks", "heavy movements"]
    },
    "ease_in_out": {
      "description": "Slow start/end, fast middle",
      "apply_to": ["walk", "idle", "ambient"]
    },
    "smear_frames": {
      "description": "Motion blur single frames",
      "use_for": ["fast attacks", "quick movements"],
      "optional": true
    }
  }
}
```

---

## Entity-Specific Guidelines

### Player Character

```json
{
  "player_sprites": {
    "dimensions": "32x32",
    "anchor_point": "bottom_center",
    "required_animations": [
      {"name": "idle", "frames": 6, "fps": 8, "loop": true},
      {"name": "walk_down", "frames": 6, "fps": 10, "loop": true},
      {"name": "walk_up", "frames": 6, "fps": 10, "loop": true},
      {"name": "walk_side", "frames": 6, "fps": 10, "loop": true},
      {"name": "interact", "frames": 4, "fps": 12, "loop": false}
    ],
    "directional_sprites": {
      "enabled": true,
      "directions": ["down", "up", "left", "right"],
      "mirroring": "left_mirrors_right"
    },
    "design_notes": [
      "Clear silhouette from all angles",
      "Distinct from enemies",
      "Bright, heroic colors",
      "Readable at zoomed-out view"
    ]
  }
}
```

### Enemies

```json
{
  "enemy_sprites": {
    "standard_enemy": {
      "dimensions": "32x32",
      "anchor_point": "bottom_center",
      "required_animations": [
        {"name": "walk", "frames": 6, "fps": 10, "loop": true},
        {"name": "attack", "frames": 4, "fps": 12, "loop": false},
        {"name": "hurt", "frames": 2, "fps": 16, "loop": false},
        {"name": "death", "frames": 6, "fps": 10, "loop": false}
      ],
      "optional_animations": [
        {"name": "idle", "frames": 4, "fps": 6},
        {"name": "spawn", "frames": 4, "fps": 12},
        {"name": "special", "frames": 6, "fps": 12}
      ]
    },
    "elite_enemy": {
      "dimensions": "32x32 or 48x48",
      "additional_effects": {
        "glow": "subtle_aura",
        "particles": "floating_particles"
      },
      "visual_distinction": [
        "More saturated colors",
        "Additional details/ornamentation",
        "Visible aura or effect"
      ]
    },
    "boss_enemy": {
      "dimensions": "128x128",
      "anchor_point": "bottom_center",
      "required_animations": [
        {"name": "idle", "frames": 8, "fps": 8, "loop": true},
        {"name": "walk", "frames": 8, "fps": 10, "loop": true},
        {"name": "attack_1", "frames": 8, "fps": 12, "loop": false},
        {"name": "attack_2", "frames": 8, "fps": 12, "loop": false},
        {"name": "special", "frames": 10, "fps": 12, "loop": false},
        {"name": "hurt", "frames": 3, "fps": 16, "loop": false},
        {"name": "death", "frames": 12, "fps": 10, "loop": false},
        {"name": "intro", "frames": 10, "fps": 12, "loop": false}
      ],
      "design_notes": [
        "Imposing, fills significant screen space",
        "Unique color scheme per boss",
        "Elaborate death animation",
        "Phase changes visible in sprite"
      ]
    },
    "enemy_word_display": {
      "position": "above_sprite",
      "offset_y": -4,
      "never_overlap_sprite": true
    }
  }
}
```

### Towers

```json
{
  "tower_sprites": {
    "base_structure": {
      "dimensions": {
        "tier_1": "32x48",
        "tier_2": "32x48",
        "tier_3": "48x64",
        "tier_4": "48x64"
      },
      "anchor_point": "bottom_center",
      "footprint": "centered_on_tile"
    },
    "required_animations": [
      {"name": "idle", "frames": 4, "fps": 6, "loop": true},
      {"name": "attack", "frames": 4, "fps": 12, "loop": false},
      {"name": "build", "frames": 6, "fps": 12, "loop": false},
      {"name": "upgrade", "frames": 6, "fps": 12, "loop": false},
      {"name": "destroy", "frames": 6, "fps": 10, "loop": false}
    ],
    "optional_animations": [
      {"name": "charge", "frames": 4, "fps": 8, "description": "Charging up attack"},
      {"name": "overheat", "frames": 4, "fps": 8, "description": "Auto-towers cooling"},
      {"name": "disabled", "frames": 2, "fps": 4, "description": "Out of ammo/power"}
    ],
    "rotating_components": {
      "description": "Some towers have rotating turrets",
      "separate_sprite": true,
      "rotation_smooth": true,
      "layers": ["base (static)", "turret (rotating)", "effects (animated)"]
    },
    "tier_visual_progression": {
      "tier_1": "Basic, simple design",
      "tier_2": "Added details, slight size increase",
      "tier_3": "Significant upgrade visible, new elements",
      "tier_4": "Elaborate, impressive, unique effects"
    }
  }
}
```

### Projectiles

```json
{
  "projectile_sprites": {
    "dimensions": "16x16",
    "anchor_point": "center",
    "required_animations": [
      {"name": "travel", "frames": 4, "fps": 24, "loop": true},
      {"name": "impact", "frames": 4, "fps": 16, "loop": false}
    ],
    "rotation": {
      "enabled": true,
      "method": "sprite_rotation",
      "aligns_to": "velocity_direction"
    },
    "types": {
      "arrow": {
        "shape": "pointed",
        "trail": false,
        "rotation": true
      },
      "magic_bolt": {
        "shape": "orb",
        "trail": true,
        "rotation": false,
        "glow": true
      },
      "fireball": {
        "shape": "sphere_with_tail",
        "trail": true,
        "rotation": false,
        "particles": "fire_trail"
      },
      "lightning": {
        "shape": "jagged_line",
        "trail": false,
        "rotation": true,
        "render": "procedural_or_sprite"
      }
    },
    "scaling": {
      "distance_scaling": false,
      "damage_scaling": "optional_visual_size_increase"
    }
  }
}
```

### Effects and Particles

```json
{
  "effect_sprites": {
    "standard_effects": {
      "dimensions": "32x32",
      "anchor_point": "center",
      "additive_blending": "for_glow_effects",
      "alpha_fade": true
    },
    "large_effects": {
      "dimensions": "64x64 or 128x128",
      "use_for": ["explosions", "boss_attacks", "screen_effects"]
    },
    "effect_types": {
      "impact": {
        "frames": 6,
        "fps": 16,
        "scale_with_damage": true
      },
      "explosion": {
        "frames": 8,
        "fps": 16,
        "sizes": ["small_32", "medium_64", "large_128"]
      },
      "status_effect": {
        "frames": 4,
        "fps": 8,
        "loop": true,
        "attach_to": "entity"
      },
      "environmental": {
        "frames": 8,
        "fps": 6,
        "loop": true,
        "examples": ["fire_on_ground", "poison_cloud", "ice_patch"]
      },
      "word_complete": {
        "frames": 6,
        "fps": 16,
        "style": "sparkle_burst",
        "color": "gold_or_white"
      },
      "combo_effect": {
        "frames": 8,
        "fps": 12,
        "scales_with_tier": true
      }
    },
    "particle_sprites": {
      "dimensions": "8x8 or 16x16",
      "variety": "3-5 variations per type",
      "types": ["spark", "smoke", "fire", "magic", "blood", "debris"]
    }
  }
}
```

### UI Elements

```json
{
  "ui_sprites": {
    "icons": {
      "standard": {
        "dimensions": "32x32",
        "style": "flat_with_outline",
        "background": "transparent_or_rounded_square"
      },
      "small": {
        "dimensions": "16x16",
        "use_for": ["status_icons", "inventory_small", "minimap"]
      },
      "large": {
        "dimensions": "64x64",
        "use_for": ["shop_display", "achievement_art", "loading_tips"]
      }
    },
    "buttons": {
      "states": ["normal", "hover", "pressed", "disabled"],
      "9_slice": true,
      "minimum_size": "48x32",
      "corner_radius": "4px visual"
    },
    "panels": {
      "style": "9_slice",
      "variations": ["default", "tooltip", "modal", "notification"],
      "transparency": "semi_transparent_background"
    },
    "health_bars": {
      "height": 4,
      "width": "entity_width",
      "segments": "optional",
      "colors": {
        "full": "#32cd32",
        "medium": "#ffd700",
        "low": "#dc143c",
        "background": "#1a1a2e"
      }
    },
    "progress_bars": {
      "style": "rounded_rectangle",
      "height": 8,
      "fill_animation": "smooth_or_stepped"
    }
  }
}
```

### Terrain and Tiles

```json
{
  "terrain_sprites": {
    "tile_size": "32x32",
    "autotiling": {
      "enabled": true,
      "method": "47_tile_blob",
      "alternative": "16_tile_minimal"
    },
    "tile_types": {
      "ground": {
        "variations": 4,
        "decoration_overlays": true
      },
      "path": {
        "variations": 2,
        "connection_aware": true
      },
      "water": {
        "animated": true,
        "frames": 4,
        "fps": 6
      },
      "walls": {
        "height_illusion": true,
        "shadow_casting": true
      }
    },
    "seamless_tiling": {
      "required": true,
      "edge_matching": "all_edges_must_connect"
    },
    "decorations": {
      "size": "16x16 to 32x32",
      "placement": "random_scatter_or_manual",
      "types": ["grass_tufts", "rocks", "flowers", "debris"]
    }
  }
}
```

---

## Sprite Presentation

### Z-Ordering / Draw Order

```json
{
  "draw_order": {
    "layers": [
      {"name": "terrain_base", "z": 0},
      {"name": "terrain_decoration", "z": 1},
      {"name": "ground_effects", "z": 2},
      {"name": "shadows", "z": 3},
      {"name": "entity_base", "z": 4},
      {"name": "entities_by_y", "z": "dynamic_by_y"},
      {"name": "entity_effects", "z": 5},
      {"name": "projectiles", "z": 6},
      {"name": "flying_entities", "z": 7},
      {"name": "overhead_effects", "z": 8},
      {"name": "ui_world", "z": 9},
      {"name": "word_displays", "z": 10}
    ],
    "y_sorting": {
      "enabled": true,
      "reference_point": "sprite_bottom",
      "within_same_layer": true
    }
  }
}
```

### Shadows

```json
{
  "shadow_system": {
    "style": "blob_shadow",
    "shape": "ellipse",
    "color": "#00000040",
    "size": "80%_of_sprite_width",
    "offset": {"x": 2, "y": 2},
    "by_entity": {
      "characters": {"scale": 0.8, "alpha": 0.4},
      "enemies": {"scale": 0.8, "alpha": 0.4},
      "towers": {"scale": 0.9, "alpha": 0.5},
      "projectiles": {"scale": 0.5, "alpha": 0.2},
      "flying": {"scale": 0.6, "alpha": 0.3, "offset_larger": true}
    }
  }
}
```

### Sprite Transforms

```json
{
  "transforms": {
    "flip_horizontal": {
      "use_for": "directional_movement",
      "method": "scale.x = -1",
      "preserve_shadow": true
    },
    "rotation": {
      "use_for": ["projectiles", "effects"],
      "method": "sprite_rotation_property",
      "smooth": true
    },
    "scaling": {
      "base_scale": 1.0,
      "spawn_scale_in": {"from": 0.5, "to": 1.0, "duration": 0.2},
      "death_scale_out": {"from": 1.0, "to": 0.0, "duration": 0.3},
      "impact_squash": {"scale": {"x": 1.2, "y": 0.8}, "duration": 0.1}
    },
    "color_modulation": {
      "damage_flash": {"color": "#ff0000", "duration": 0.1},
      "heal_flash": {"color": "#00ff00", "duration": 0.15},
      "freeze": {"color": "#87ceeb", "duration": "while_frozen"},
      "poison": {"color": "#9932cc", "duration": "while_poisoned"},
      "invincible": {"modulate_alpha": 0.5, "flash": true}
    }
  }
}
```

---

## Godot Implementation

### Sprite Node Setup

```gdscript
# Standard entity sprite setup
extends Sprite2D

@export var sprite_sheet: Texture2D
@export var frame_size: Vector2 = Vector2(32, 32)
@export var animations: Dictionary = {}

func _ready():
    texture = sprite_sheet
    region_enabled = true
    region_rect = Rect2(Vector2.ZERO, frame_size)
    centered = true
    offset = Vector2(0, -frame_size.y / 2)  # Bottom-center anchor
```

### AnimatedSprite2D Configuration

```gdscript
# Animation setup for entities
extends AnimatedSprite2D

func setup_animations():
    var frames = SpriteFrames.new()

    # Add idle animation
    frames.add_animation("idle")
    frames.set_animation_speed("idle", 8)
    frames.set_animation_loop("idle", true)
    for i in range(6):
        var texture = load_frame("idle", i)
        frames.add_frame("idle", texture)

    # Add walk animation
    frames.add_animation("walk")
    frames.set_animation_speed("walk", 12)
    frames.set_animation_loop("walk", true)
    for i in range(8):
        var texture = load_frame("walk", i)
        frames.add_frame("walk", texture)

    sprite_frames = frames

func play_animation(anim_name: String):
    if sprite_frames.has_animation(anim_name):
        play(anim_name)
```

### Animation State Machine

```gdscript
# Animation state management
extends Node

enum State { IDLE, WALK, ATTACK, HURT, DEATH }
var current_state: State = State.IDLE
var animated_sprite: AnimatedSprite2D

func change_state(new_state: State):
    if current_state == State.DEATH:
        return  # Can't change from death

    current_state = new_state
    match new_state:
        State.IDLE:
            animated_sprite.play("idle")
        State.WALK:
            animated_sprite.play("walk")
        State.ATTACK:
            animated_sprite.play("attack")
            await animated_sprite.animation_finished
            change_state(State.IDLE)
        State.HURT:
            animated_sprite.play("hurt")
            _flash_damage()
            await animated_sprite.animation_finished
            change_state(State.IDLE)
        State.DEATH:
            animated_sprite.play("death")

func _flash_damage():
    animated_sprite.modulate = Color.RED
    await get_tree().create_timer(0.1).timeout
    animated_sprite.modulate = Color.WHITE
```

### Sprite Sheet Region Calculation

```gdscript
# Calculate frame region from sprite sheet
func get_frame_region(frame_index: int, row: int, frame_size: Vector2) -> Rect2:
    return Rect2(
        Vector2(frame_index * frame_size.x, row * frame_size.y),
        frame_size
    )

# Example: Get attack frame 3
var attack_row = 2
var attack_frame = 3
var frame_size = Vector2(32, 32)
sprite.region_rect = get_frame_region(attack_frame, attack_row, frame_size)
```

---

## File Naming Conventions

### Sprite Files

```
Format: [entity_type]_[entity_name]_[variant].png

Examples:
- enemy_goblin_green.png
- enemy_goblin_elite.png
- tower_arrow_t1.png
- tower_arrow_t2.png
- tower_arrow_t3.png
- effect_explosion_small.png
- effect_explosion_large.png
- projectile_arrow.png
- projectile_fireball.png
- ui_icon_gold.png
- ui_icon_health.png
- tile_grass_set.png
- player_hero_main.png
```

### Animation Files (if separate)

```
Format: [entity_name]_[animation_name].png

Examples:
- goblin_walk.png
- goblin_attack.png
- goblin_death.png
- hero_idle.png
- hero_walk.png
```

### Sprite Sheet Files

```
Format: [entity_name]_spritesheet.png

Examples:
- goblin_spritesheet.png
- tower_arrow_spritesheet.png
- effects_spritesheet.png
```

---

## Directory Structure

```
res://assets/
├── sprites/
│   ├── characters/
│   │   ├── player/
│   │   │   └── hero_spritesheet.png
│   │   └── npcs/
│   │       ├── shopkeeper_spritesheet.png
│   │       └── quest_giver_spritesheet.png
│   ├── enemies/
│   │   ├── standard/
│   │   │   ├── goblin_spritesheet.png
│   │   │   ├── skeleton_spritesheet.png
│   │   │   └── slime_spritesheet.png
│   │   ├── elite/
│   │   │   └── goblin_champion_spritesheet.png
│   │   └── bosses/
│   │       ├── boss_dragon_spritesheet.png
│   │       └── boss_lich_spritesheet.png
│   ├── towers/
│   │   ├── arrow/
│   │   │   ├── tower_arrow_t1.png
│   │   │   ├── tower_arrow_t2.png
│   │   │   └── tower_arrow_t3.png
│   │   ├── magic/
│   │   └── auto/
│   ├── projectiles/
│   │   ├── projectile_arrow.png
│   │   ├── projectile_fireball.png
│   │   └── projectile_magic.png
│   ├── effects/
│   │   ├── impacts/
│   │   ├── explosions/
│   │   ├── status/
│   │   └── particles/
│   ├── tiles/
│   │   ├── terrain/
│   │   ├── decorations/
│   │   └── autotile_sets/
│   └── ui/
│       ├── icons/
│       ├── buttons/
│       ├── panels/
│       └── hud/
```

---

## Quality Checklist

### Before Committing Sprites

- [ ] Dimensions match specification for entity type
- [ ] Anchor point is correctly set (bottom-center for entities)
- [ ] No anti-aliasing artifacts on edges
- [ ] Colors match palette or derived colors
- [ ] Consistent lighting direction (top-left)
- [ ] Outlines follow guidelines
- [ ] Animation frame count matches requirements
- [ ] Looping animations loop seamlessly
- [ ] File named according to convention
- [ ] PNG format with alpha transparency
- [ ] No unused transparent space (cropped properly)
- [ ] Readable at intended zoom levels
- [ ] Shadow sprite included if required

### Animation Quality Check

- [ ] Smooth motion, no jarring jumps
- [ ] Proper anticipation and follow-through
- [ ] Key poses are clear and readable
- [ ] Timing feels appropriate for action
- [ ] Loops are seamless (for looping anims)
- [ ] One-shot animations have clear end state
- [ ] Consistent style across all frames

---

## Claude Code Asset Creation

### SVG Generation Examples

When creating SVG assets, write the markup directly:

```svg
<!-- Simple enemy (32x32) -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <!-- Body -->
  <ellipse cx="16" cy="20" rx="10" ry="8" fill="#dc143c"/>
  <!-- Outline -->
  <ellipse cx="16" cy="20" rx="10" ry="8" fill="none" stroke="#8b0000" stroke-width="1"/>
  <!-- Eyes -->
  <circle cx="12" cy="18" r="2" fill="#ffffff"/>
  <circle cx="20" cy="18" r="2" fill="#ffffff"/>
  <circle cx="12" cy="18" r="1" fill="#000000"/>
  <circle cx="20" cy="18" r="1" fill="#000000"/>
  <!-- Shadow -->
  <ellipse cx="16" cy="28" rx="8" ry="3" fill="#00000040"/>
</svg>
```

```svg
<!-- Tower base (32x48) -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 48">
  <!-- Foundation -->
  <rect x="4" y="40" width="24" height="8" fill="#5c5c7a"/>
  <!-- Tower body -->
  <rect x="6" y="16" width="20" height="24" fill="#8b8ba8"/>
  <!-- Battlement -->
  <rect x="4" y="12" width="6" height="8" fill="#8b8ba8"/>
  <rect x="13" y="12" width="6" height="8" fill="#8b8ba8"/>
  <rect x="22" y="12" width="6" height="8" fill="#8b8ba8"/>
  <!-- Window -->
  <rect x="12" y="24" width="8" height="10" fill="#1a1a2e"/>
  <!-- Outline -->
  <path d="M4,12 h6 v4 h3 v-4 h6 v4 h3 v-4 h6 v8 h-2 v24 h2 v8 h-24 v-8 h2 v-24 h-2 z"
        fill="none" stroke="#1a1a2e" stroke-width="1"/>
</svg>
```

### Godot Draw Primitives

For procedural graphics in GDScript:

```gdscript
# Simple enemy drawn procedurally
extends Node2D

var enemy_color: Color = Color("#dc143c")
var outline_color: Color = Color("#8b0000")

func _draw():
    # Shadow
    draw_ellipse(Vector2(0, 12), Vector2(8, 3), Color(0, 0, 0, 0.25))

    # Body
    draw_ellipse(Vector2(0, 4), Vector2(10, 8), enemy_color)
    draw_arc(Vector2(0, 4), 10, 0, TAU, 32, outline_color, 1.0)

    # Eyes
    draw_circle(Vector2(-4, 2), 2, Color.WHITE)
    draw_circle(Vector2(4, 2), 2, Color.WHITE)
    draw_circle(Vector2(-4, 2), 1, Color.BLACK)
    draw_circle(Vector2(4, 2), 1, Color.BLACK)

func draw_ellipse(center: Vector2, size: Vector2, color: Color):
    var points = PackedVector2Array()
    for i in range(32):
        var angle = i * TAU / 32
        points.append(center + Vector2(cos(angle) * size.x, sin(angle) * size.y))
    draw_colored_polygon(points, color)
```

```gdscript
# Health bar drawn procedurally
extends Node2D

var max_health: float = 100
var current_health: float = 100
var bar_width: float = 24
var bar_height: float = 4

func _draw():
    var health_percent = current_health / max_health
    var health_color = Color.GREEN
    if health_percent < 0.5:
        health_color = Color.YELLOW
    if health_percent < 0.25:
        health_color = Color.RED

    # Background
    draw_rect(Rect2(-bar_width/2, -bar_height/2, bar_width, bar_height), Color("#1a1a2e"))
    # Health fill
    draw_rect(Rect2(-bar_width/2, -bar_height/2, bar_width * health_percent, bar_height), health_color)
    # Border
    draw_rect(Rect2(-bar_width/2, -bar_height/2, bar_width, bar_height), Color.BLACK, false, 1.0)
```

### Placeholder System

For rapid prototyping before creating final assets:

```gdscript
# Placeholder sprite generator
class_name PlaceholderSprite
extends Node2D

@export var size: Vector2 = Vector2(32, 32)
@export var color: Color = Color.MAGENTA
@export var label: String = "?"

func _draw():
    # Colored rectangle
    draw_rect(Rect2(-size/2, size), color)
    # Border
    draw_rect(Rect2(-size/2, size), Color.BLACK, false, 2.0)
    # Label
    draw_string(ThemeDB.fallback_font, Vector2(-size.x/4, 4), label, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE)
```

### Animation via Tweens

Prefer tweens over sprite sheet animations when possible:

```gdscript
# Attack animation via tween
func play_attack_animation():
    var tween = create_tween()
    # Anticipation - pull back
    tween.tween_property(sprite, "position", Vector2(-4, 0), 0.1)
    # Strike forward
    tween.tween_property(sprite, "position", Vector2(8, 0), 0.05)
    # Return
    tween.tween_property(sprite, "position", Vector2.ZERO, 0.15)

# Idle bob animation
func start_idle_animation():
    var tween = create_tween().set_loops()
    tween.tween_property(sprite, "position:y", -2, 0.5).set_ease(Tween.EASE_IN_OUT)
    tween.tween_property(sprite, "position:y", 0, 0.5).set_ease(Tween.EASE_IN_OUT)

# Damage flash
func flash_damage():
    sprite.modulate = Color.RED
    await get_tree().create_timer(0.1).timeout
    sprite.modulate = Color.WHITE
```

---

## Performance Considerations

```json
{
  "performance_guidelines": {
    "texture_atlas": {
      "use": true,
      "max_size": "4096x4096",
      "auto_generate": "on_export"
    },
    "sprite_batching": {
      "enabled": true,
      "same_texture_batched": true
    },
    "animation_optimization": {
      "skip_frames_when_offscreen": true,
      "reduce_fps_when_distant": true,
      "pool_animated_sprites": true
    },
    "memory_limits": {
      "max_unique_sprites_loaded": 500,
      "unload_unused_after": "scene_change"
    }
  }
}
```

---

*End of Sprite Usage and Animation Guide*
