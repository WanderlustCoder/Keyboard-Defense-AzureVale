# Asset Loader Guide

Runtime asset loading and caching system.

## Overview

`AssetLoader` (game/asset_loader.gd) loads textures from `data/assets_manifest.json`, caches them for performance, and provides sprite ID mapping for game entities.

## Constants

```gdscript
const MANIFEST_PATH := "res://data/assets_manifest.json"
```

## State Variables

```gdscript
var _manifest: Dictionary = {}
var _texture_cache: Dictionary = {}
var _animation_frame_cache: Dictionary = {}  # sprite_id -> Array[Texture2D]
var _loaded: bool = false

# Category lookup tables
var sprites: Dictionary = {}      # buildings, units, enemies, effects
var icons: Dictionary = {}        # icons, poi, status, medals
var tiles: Dictionary = {}        # terrain tiles
var ui: Dictionary = {}           # UI elements, tutorial
var animations: Dictionary = {}   # Entries with animation data
```

## Initialization

```gdscript
func _ready() -> void:
    _load_manifest()

func _load_manifest() -> void:
    # Load and parse manifest JSON
    # Index textures by category
```

## Core Functions

### Texture Loading

```gdscript
# Load any texture by ID
func get_texture(id: String) -> Texture2D

# Category-specific loading
func get_sprite_texture(id: String) -> Texture2D
func get_icon_texture(id: String) -> Texture2D
func get_tile_texture(id: String) -> Texture2D
func get_ui_texture(id: String) -> Texture2D
```

Textures are cached after first load.

### Entry Lookup

```gdscript
# Get full manifest entry
func get_entry(id: String) -> Dictionary

# Get animation info from entry
func get_animation_info(id: String) -> Dictionary
# Returns: {"frame_count": int, "fps": float, "loop": bool}

# Get nine-slice info for UI
func get_nineslice_info(id: String) -> Dictionary
```

## Sprite ID Mapping

### Enemy Sprites

```gdscript
func get_enemy_sprite_id(kind: String) -> String:
    match kind:
        "raider", "runner":
            return "enemy_runner"
        "scout":
            return "enemy_runner"
        "armored", "brute":
            return "enemy_brute"
        "flyer":
            return "enemy_flyer"
        "shielder":
            return "enemy_shielder"
        "healer":
            return "enemy_healer"
        "boss_warlord":
            return "enemy_boss_warlord"
        "boss_mage":
            return "enemy_boss_mage"
        _:
            # Handle elite variants
            if kind.ends_with("_elite"):
                var base_kind := kind.trim_suffix("_elite")
                var base_id := get_enemy_sprite_id(base_kind)
                if sprites.has(base_id + "_elite"):
                    return base_id + "_elite"
                return base_id
            return "enemy_runner"
```

### Building Sprites

```gdscript
func get_building_sprite_id(building_type: String) -> String:
    match building_type:
        "farm":
            return "bld_barracks"  # Placeholder
        "lumber":
            return "bld_library"
        "quarry":
            return "bld_gate"
        "wall":
            return "bld_wall"
        "tower":
            return "bld_tower_arrow"
        "castle":
            return "bld_castle"
        _:
            return "bld_wall"
```

### Unit Sprites

```gdscript
func get_unit_sprite_id(unit_type: String) -> String:
    match unit_type:
        "scribe":
            return "unit_scribe"
        "archer":
            return "unit_archer"
        "scout":
            return "unit_scout"
        _:
            return "unit_scribe"
```

### Effect Sprites

```gdscript
func get_effect_sprite_id(effect_type: String) -> String:
    match effect_type:
        "projectile":
            return "fx_projectile"
        "magic_bolt":
            return "fx_magic_bolt"
        "hit_flash":
            return "fx_hit_flash"
        "build_dust":
            return "fx_build_dust"
        "typing_streak":
            return "fx_typing_streak"
        "reward_sparkle":
            return "fx_reward_sparkle"
        _:
            return "fx_projectile"
```

### Portrait Sprites

```gdscript
func get_portrait_sprite_id(character: String) -> String:
    match character.to_lower():
        "lyra", "elder lyra":
            return "portrait_lyra"
        "commander":
            return "portrait_commander"
        "merchant":
            return "portrait_merchant"
        # ... more characters
        _:
            return "portrait_lyra"  # Default

func get_portrait_texture(character: String) -> Texture2D:
    var sprite_id := get_portrait_sprite_id(character)
    return get_texture(sprite_id)
```

## Animation Support

```gdscript
# Check if sprite has animation data
func has_animation(sprite_id: String) -> bool:
    return animations.has(sprite_id)

# Get frame count
func get_animation_frame_count(sprite_id: String) -> int
```

## Preloading

```gdscript
# Preload common battle textures
func preload_battle_textures() -> void:
    var battle_ids := [
        "bld_castle", "enemy_runner", "enemy_brute", "enemy_flyer",
        "fx_projectile", "fx_hit_flash", "fx_magic_bolt"
    ]
    for id in battle_ids:
        var _tex := get_texture(id)

# Preload grid/map textures
func preload_grid_textures() -> void:
    var grid_ids := [
        "bld_wall", "bld_tower_arrow", "bld_tower_slow",
        "bld_barracks", "bld_library", "bld_gate",
        "enemy_runner", "enemy_brute", "enemy_flyer",
        "tile_grass", "tile_forest", "tile_mountain", "tile_water"
    ]
    for id in grid_ids:
        var _tex := get_texture(id)
```

## Manifest Format

```json
{
  "version": 1,
  "textures": [
    {
      "id": "enemy_runner",
      "path": "res://assets/art/enemies/runner.png",
      "category": "enemies",
      "animation": {
        "frame_count": 4,
        "fps": 8.0,
        "loop": true
      }
    },
    {
      "id": "bld_castle",
      "path": "res://assets/art/buildings/castle.png",
      "category": "buildings"
    },
    {
      "id": "icon_gold",
      "path": "res://assets/art/icons/gold.png",
      "category": "icons"
    },
    {
      "id": "panel_dialogue",
      "path": "res://assets/art/ui/dialogue_panel.png",
      "category": "ui",
      "nineslice": {
        "left": 8,
        "right": 8,
        "top": 8,
        "bottom": 8
      }
    }
  ]
}
```

## Category Indexing

Textures are indexed by category during load:

```gdscript
func _index_textures() -> void:
    var textures: Array = _manifest.get("textures", [])
    for entry in textures:
        var id: String = entry.get("id", "")
        var category: String = entry.get("category", "")

        # Index animations separately
        if entry.has("animation"):
            animations[id] = entry

        match category:
            "buildings", "units", "enemies", "decorations", "effects", "npcs", "portraits":
                sprites[id] = entry
            "icons", "poi", "status", "medals":
                icons[id] = entry
            "tiles":
                tiles[id] = entry
            "ui", "tutorial":
                ui[id] = entry
```

## Usage Examples

### Loading Enemy Sprite

```gdscript
var asset_loader = AssetLoader.new()
asset_loader._load_manifest()

# Get sprite for enemy type
var enemy_kind = "armored"
var sprite_id = asset_loader.get_enemy_sprite_id(enemy_kind)
var texture = asset_loader.get_sprite_texture(sprite_id)

if texture:
    enemy_node.texture = texture
```

### Loading Building Sprite

```gdscript
var building_type = "tower"
var sprite_id = asset_loader.get_building_sprite_id(building_type)
var texture = asset_loader.get_sprite_texture(sprite_id)
building_sprite.texture = texture
```

### Character Portrait

```gdscript
var portrait = asset_loader.get_portrait_texture("Elder Lyra")
dialogue_box.set_portrait(portrait)
```

### Animation Setup

```gdscript
var sprite_id = "enemy_runner"
if asset_loader.has_animation(sprite_id):
    var anim_info = asset_loader.get_animation_info(sprite_id)
    sprite_animator.register_animation(entity_id, sprite_id, anim_info)
```

### Scene Preloading

```gdscript
func _ready() -> void:
    asset_loader.preload_battle_textures()
    # All battle sprites now cached
```

## Fallback Handling

When texture not found:

```gdscript
func get_texture(id: String) -> Texture2D:
    if _texture_cache.has(id):
        return _texture_cache[id]
    var entry := _find_entry(id)
    if entry.is_empty():
        return null  # Not found
    var path: String = entry.get("path", "")
    if path.is_empty():
        return null
    var texture := load(path) as Texture2D
    if texture != null:
        _texture_cache[id] = texture
    return texture
```

Callers should handle null returns with placeholder graphics.

## Adding New Assets

1. Add texture entry to `data/assets_manifest.json`
2. Place file at specified path
3. Use appropriate category
4. Add animation data if animated

For sprite ID mappings, update the relevant `get_*_sprite_id()` function.

## File Dependencies

- `data/assets_manifest.json` - Asset manifest
- `assets/art/**` - Actual texture files
