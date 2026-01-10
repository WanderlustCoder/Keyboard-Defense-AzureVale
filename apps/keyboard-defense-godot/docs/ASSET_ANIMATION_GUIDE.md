# Asset Loading & Animation Guide

This document explains the manifest-based asset loading system and sprite animation controller in Keyboard Defense.

## Overview

Assets are loaded through a centralized manifest system with texture caching:

```
assets_manifest.json → AssetLoader → Texture Cache → SpriteAnimator
                          ↓                              ↓
                   Entity Mapping              Frame Timing & Playback
```

## Asset Loader

### Manifest Structure

Assets are defined in `res://data/assets_manifest.json`:

```json
{
  "textures": [
    {
      "id": "enemy_runner",
      "path": "res://assets/sprites/enemy_runner.png",
      "category": "enemies",
      "size": [32, 32]
    },
    {
      "id": "enemy_runner_walk",
      "path": "res://assets/sprites/enemy_runner_walk_01.png",
      "category": "enemies",
      "animation": {
        "frame_count": 4,
        "fps": 8,
        "loop": true
      },
      "source_svg_frames": [
        "res://assets/art/src-svg/anim/enemy_runner_walk_01.svg",
        "res://assets/art/src-svg/anim/enemy_runner_walk_02.svg",
        "res://assets/art/src-svg/anim/enemy_runner_walk_03.svg",
        "res://assets/art/src-svg/anim/enemy_runner_walk_04.svg"
      ]
    }
  ]
}
```

### Category Indices

```gdscript
# game/asset_loader.gd
var sprites: Dictionary = {}     # buildings, units, enemies, decorations, effects, npcs, portraits
var icons: Dictionary = {}       # icons, poi, status, medals
var tiles: Dictionary = {}       # terrain tiles
var ui: Dictionary = {}          # ui, tutorial
var animations: Dictionary = {}  # entries with animation data
```

### Loading Textures

```gdscript
# Basic texture loading (with caching)
var texture := AssetLoader.get_texture("enemy_runner")

# Category-specific loading
var sprite := AssetLoader.get_sprite_texture("enemy_runner")
var icon := AssetLoader.get_icon_texture("resource_wood")
var tile := AssetLoader.get_tile_texture("tile_grass")
var ui_tex := AssetLoader.get_ui_texture("button_normal")
```

### Entity Sprite Mapping

Map game entities to sprite IDs:

```gdscript
# game/asset_loader.gd:118
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

### Building Sprite Mapping

```gdscript
# game/asset_loader.gd:146
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

### Unit and Effect Mapping

```gdscript
# Unit sprites
func get_unit_sprite_id(unit_type: String) -> String:
    match unit_type:
        "scribe": return "unit_scribe"
        "archer": return "unit_archer"
        "scout": return "unit_scout"
        _: return "unit_scribe"

# Effect sprites
func get_effect_sprite_id(effect_type: String) -> String:
    match effect_type:
        "projectile": return "fx_projectile"
        "magic_bolt": return "fx_magic_bolt"
        "hit_flash": return "fx_hit_flash"
        "build_dust": return "fx_build_dust"
        "typing_streak": return "fx_typing_streak"
        "reward_sparkle": return "fx_reward_sparkle"
        _: return "fx_projectile"
```

### Portrait Mapping

```gdscript
# game/asset_loader.gd:194
func get_portrait_sprite_id(character: String) -> String:
    match character.to_lower():
        "lyra", "elder lyra":
            return "portrait_lyra"
        "commander":
            return "portrait_commander"
        "scholar":
            return "portrait_scholar"
        "merchant":
            return "portrait_merchant"
        "scout":
            return "portrait_scout"
        "blacksmith":
            return "portrait_blacksmith"
        "wizard":
            return "portrait_wizard"
        "king":
            return "portrait_king"
        _:
            return "portrait_lyra"  # Default
```

## Animation Frame Loading

### Animation Info

```gdscript
# Check if sprite has animation
func has_animation(sprite_id: String) -> bool:
    return animations.has(sprite_id)

# Get frame count
func get_animation_frame_count(sprite_id: String) -> int:
    if not animations.has(sprite_id):
        return 1
    var entry: Dictionary = animations[sprite_id]
    var anim_info: Dictionary = entry.get("animation", {})
    return anim_info.get("frame_count", 1)
```

### Loading Animation Frames

```gdscript
# game/asset_loader.gd:255
func get_animation_frame(sprite_id: String, frame_index: int) -> Texture2D:
    var entry: Dictionary = animations.get(sprite_id, {})
    if entry.is_empty():
        return get_texture(sprite_id)  # Fallback

    var frames: Array = entry.get("source_svg_frames", [])
    var anim_info: Dictionary = entry.get("animation", {})
    var frame_count: int = anim_info.get("frame_count", 1)

    # Clamp frame index
    frame_index = clampi(frame_index, 0, frame_count - 1)

    # Try to load from frames array paths
    if frames.size() > frame_index:
        var frame_path: String = frames[frame_index]

        # Try PNG first (if converted from SVG)
        var png_path := _svg_to_png_path(frame_path)
        var tex := load(png_path) as Texture2D
        if tex != null:
            _texture_cache[png_path] = tex
            return tex

        # Try SVG directly
        tex = load(frame_path) as Texture2D
        if tex != null:
            _texture_cache[frame_path] = tex
            return tex

    # Ultimate fallback: return base texture
    return get_texture(sprite_id)
```

### SVG to PNG Path Conversion

```gdscript
# game/asset_loader.gd:327
func _svg_to_png_path(svg_path: String) -> String:
    # res://assets/art/src-svg/sprites/anim/enemy_runner_walk_01.svg
    # -> res://assets/sprites/enemy_runner_walk_01.png
    var path := svg_path.replace("/art/src-svg/", "/")
    path = path.replace("/anim/", "/")
    path = path.replace(".svg", ".png")
    return path
```

### Preloading Animations

```gdscript
# Preload all frames for an animation
func preload_animation_frames(sprite_id: String) -> Array[Texture2D]:
    if _animation_frame_cache.has(sprite_id):
        return _animation_frame_cache[sprite_id]

    var frame_count := get_animation_frame_count(sprite_id)
    var frames: Array[Texture2D] = []

    for i in range(frame_count):
        var tex := get_animation_frame(sprite_id, i)
        if tex != null:
            frames.append(tex)

    _animation_frame_cache[sprite_id] = frames
    return frames
```

### Animation ID Helpers

```gdscript
# Get animation ID for an enemy with specific animation type
func get_enemy_animation_id(kind: String, anim_type: String) -> String:
    var base_id := get_enemy_sprite_id(kind)
    var anim_id := "%s_%s" % [base_id, anim_type]
    if animations.has(anim_id):
        return anim_id
    return ""

# Get animation ID for a building with specific animation type
func get_building_animation_id(building_type: String, anim_type: String) -> String:
    var base_id := get_building_sprite_id(building_type)
    var anim_id := "%s_%s" % [base_id, anim_type]
    if animations.has(anim_id):
        return anim_id
    return ""
```

## Sprite Animator

### Animation State

```gdscript
# game/sprite_animator.gd:17
class AnimState:
    var sprite_id: String = ""
    var current_frame: int = 0
    var frame_timer: float = 0.0
    var fps: float = 8.0
    var frame_count: int = 1
    var loop: bool = true
    var playing: bool = true
    var on_complete: Callable
    var base_sprite_id: String = ""  # For reverting after oneshot

    func reset() -> void:
        current_frame = 0
        frame_timer = 0.0
        playing = true
```

### Registering Animations

```gdscript
# game/sprite_animator.gd:38
func register_animation(entity_id: int, sprite_id: String, anim_info: Dictionary = {}) -> void:
    if reduced_motion:
        return

    var state := AnimState.new()
    state.sprite_id = sprite_id
    state.frame_count = anim_info.get("frame_count", 1)
    state.fps = anim_info.get("fps", 8.0)
    state.loop = anim_info.get("loop", true)
    state.base_sprite_id = sprite_id

    # If no anim_info provided, try to get from asset loader
    if anim_info.is_empty() and _asset_loader:
        var loaded_info := _asset_loader.get_animation_info(sprite_id)
        if not loaded_info.is_empty():
            state.frame_count = loaded_info.get("frame_count", 1)
            state.fps = loaded_info.get("fps", 8.0)
            state.loop = loaded_info.get("loop", true)

    _animations[entity_id] = state
```

### Updating Animations

Call from `_process()`:

```gdscript
# game/sprite_animator.gd:64
func update(delta: float) -> void:
    if reduced_motion:
        return

    _global_time += delta

    var completed_oneshots: Array = []

    for entity_id in _animations:
        var state: AnimState = _animations[entity_id]
        if not state.playing:
            continue

        state.frame_timer += delta
        var frame_duration: float = 1.0 / state.fps if state.fps > 0 else 0.125

        while state.frame_timer >= frame_duration:
            state.frame_timer -= frame_duration
            state.current_frame += 1

            if state.current_frame >= state.frame_count:
                if state.loop:
                    state.current_frame = 0
                else:
                    state.current_frame = state.frame_count - 1
                    state.playing = false
                    if state.on_complete.is_valid():
                        completed_oneshots.append(entity_id)

    # Handle completed oneshots outside iteration
    for entity_id in completed_oneshots:
        var state: AnimState = _animations[entity_id]
        var callback: Callable = state.on_complete

        # Revert to base animation if set
        if not state.base_sprite_id.is_empty() and state.base_sprite_id != state.sprite_id:
            register_animation(entity_id, state.base_sprite_id)

        callback.call()
```

### Oneshot Animations

Play a non-looping animation with optional callback:

```gdscript
# game/sprite_animator.gd:119
func play_oneshot(entity_id: int, sprite_id: String, on_complete: Callable = Callable()) -> void:
    if reduced_motion:
        if on_complete.is_valid():
            on_complete.call()  # Immediately call callback
        return

    # Store current animation as base to revert to
    var base_sprite: String = ""
    if _animations.has(entity_id):
        base_sprite = _animations[entity_id].base_sprite_id

    # Get animation info
    var anim_info: Dictionary = {}
    if _asset_loader:
        anim_info = _asset_loader.get_animation_info(sprite_id)

    var state := AnimState.new()
    state.sprite_id = sprite_id
    state.frame_count = anim_info.get("frame_count", 3)
    state.fps = anim_info.get("fps", 10.0)
    state.loop = false
    state.on_complete = on_complete
    state.base_sprite_id = base_sprite
    state.playing = true

    _animations[entity_id] = state
```

### Playback Control

```gdscript
# Get current frame for an entity
func get_current_frame(entity_id: int) -> int:
    if not _animations.has(entity_id):
        return 0
    return _animations[entity_id].current_frame

# Set animation to specific frame
func set_frame(entity_id: int, frame: int) -> void:
    if not _animations.has(entity_id):
        return
    var state: AnimState = _animations[entity_id]
    state.current_frame = clampi(frame, 0, state.frame_count - 1)

# Pause/resume individual animation
func pause(entity_id: int) -> void:
    if _animations.has(entity_id):
        _animations[entity_id].playing = false

func resume(entity_id: int) -> void:
    if _animations.has(entity_id):
        _animations[entity_id].playing = true

# Pause/resume all animations
func pause_all() -> void:
    for entity_id in _animations:
        _animations[entity_id].playing = false

func resume_all() -> void:
    for entity_id in _animations:
        _animations[entity_id].playing = true
```

### Animation Synchronization

Sync multiple entities to the same animation phase:

```gdscript
# game/sprite_animator.gd:190
func sync_animations(entity_ids: Array) -> void:
    if entity_ids.is_empty():
        return

    # Use first entity as reference
    var ref_state: AnimState = _animations.get(entity_ids[0], null)
    if ref_state == null:
        return

    for i in range(1, entity_ids.size()):
        var entity_id: int = entity_ids[i]
        if _animations.has(entity_id):
            var state: AnimState = _animations[entity_id]
            state.current_frame = ref_state.current_frame
            state.frame_timer = ref_state.frame_timer
```

### Getting Frame Sprite ID

```gdscript
# Get sprite ID with frame suffix for loading correct texture
func get_frame_sprite_id(entity_id: int) -> String:
    if not _animations.has(entity_id):
        return ""
    var state: AnimState = _animations[entity_id]
    # Format: sprite_id_01, sprite_id_02, etc.
    return "%s_%02d" % [state.sprite_id, state.current_frame + 1]
```

### Reduced Motion Accessibility

```gdscript
# game/sprite_animator.gd:14
var reduced_motion: bool = false

# When reduced_motion is true:
# - register_animation() returns immediately
# - update() returns immediately (no frame updates)
# - play_oneshot() immediately calls the callback and returns
```

## Preloading

### Battle Textures

```gdscript
func preload_battle_textures() -> void:
    var battle_ids := [
        "bld_castle", "enemy_runner", "enemy_brute", "enemy_flyer",
        "fx_projectile", "fx_hit_flash", "fx_magic_bolt"
    ]
    for id in battle_ids:
        var _tex := get_texture(id)
```

### Grid Textures

```gdscript
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

### Animation Textures

```gdscript
func preload_animation_textures() -> void:
    var anim_ids := [
        "enemy_runner_walk", "enemy_runner_death",
        "enemy_brute_walk", "enemy_brute_death",
        "enemy_flyer_hover", "enemy_flyer_death",
        "bld_tower_arrow_fire", "bld_tower_slow_pulse"
    ]
    for id in anim_ids:
        if animations.has(id):
            var _frames := preload_animation_frames(id)
```

## Integration Example

### Enemy Renderer

```gdscript
class EnemyRenderer:
    var animator: SpriteAnimator
    var asset_loader: AssetLoader

    func spawn_enemy(enemy_id: int, kind: String) -> void:
        # Get walk animation ID
        var walk_anim := asset_loader.get_enemy_animation_id(kind, "walk")
        if walk_anim.is_empty():
            walk_anim = asset_loader.get_enemy_sprite_id(kind)

        # Register animation
        animator.register_animation(enemy_id, walk_anim)

    func on_enemy_death(enemy_id: int, kind: String) -> void:
        # Play death animation, then remove
        var death_anim := asset_loader.get_enemy_animation_id(kind, "death")
        if not death_anim.is_empty():
            animator.play_oneshot(enemy_id, death_anim, func():
                animator.unregister_animation(enemy_id)
                _remove_enemy_visual(enemy_id)
            )
        else:
            animator.unregister_animation(enemy_id)
            _remove_enemy_visual(enemy_id)

    func _process(delta: float) -> void:
        animator.update(delta)

    func _draw_enemy(enemy_id: int, position: Vector2) -> void:
        var frame := animator.get_current_frame(enemy_id)
        var state := animator.get_animation_state(enemy_id)
        if state:
            var texture := asset_loader.get_animation_frame(state.sprite_id, frame)
            if texture:
                draw_texture(texture, position)
```

### Tower Attack Animation

```gdscript
func on_tower_fire(tower_id: int, building_type: String) -> void:
    var fire_anim := asset_loader.get_building_animation_id(building_type, "fire")
    if not fire_anim.is_empty():
        animator.play_oneshot(tower_id, fire_anim)
```

## Adding New Animations

### Step 1: Create SVG Frames

Create frames in `assets/art/src-svg/anim/`:
```
enemy_new_walk_01.svg
enemy_new_walk_02.svg
enemy_new_walk_03.svg
enemy_new_walk_04.svg
```

### Step 2: Add to Manifest

```json
{
  "id": "enemy_new_walk",
  "path": "res://assets/sprites/enemy_new_walk_01.png",
  "category": "enemies",
  "animation": {
    "frame_count": 4,
    "fps": 8,
    "loop": true
  },
  "source_svg_frames": [
    "res://assets/art/src-svg/anim/enemy_new_walk_01.svg",
    "res://assets/art/src-svg/anim/enemy_new_walk_02.svg",
    "res://assets/art/src-svg/anim/enemy_new_walk_03.svg",
    "res://assets/art/src-svg/anim/enemy_new_walk_04.svg"
  ]
}
```

### Step 3: Add Entity Mapping

```gdscript
# In get_enemy_sprite_id():
"new_enemy":
    return "enemy_new"
```

### Step 4: Add Animation Preload (Optional)

```gdscript
func preload_animation_textures() -> void:
    var anim_ids := [
        // ... existing ...
        "enemy_new_walk", "enemy_new_death"
    ]
```

## Animation Constants

| Animation Type | Typical FPS | Typical Frames | Loop |
|---------------|-------------|----------------|------|
| Walk cycle | 8 | 4 | Yes |
| Idle | 4 | 2-4 | Yes |
| Attack | 10 | 3-6 | No |
| Death | 10 | 4-6 | No |
| Tower fire | 12 | 3 | No |
| Effect flash | 15 | 2-3 | No |

## Testing

```gdscript
func test_asset_loading():
    var loader := AssetLoader.new()
    loader._load_manifest()

    # Test texture loading
    var tex := loader.get_texture("enemy_runner")
    assert(tex != null, "Should load texture")

    # Test entity mapping
    var sprite_id := loader.get_enemy_sprite_id("brute")
    assert(sprite_id == "enemy_brute")

    _pass("test_asset_loading")

func test_animation():
    var animator := SpriteAnimator.new()
    animator.register_animation(1, "enemy_runner_walk", {"frame_count": 4, "fps": 8, "loop": true})

    # Simulate time
    animator.update(0.5)
    var frame := animator.get_current_frame(1)
    assert(frame > 0, "Frame should advance")

    _pass("test_animation")

func test_oneshot_callback():
    var animator := SpriteAnimator.new()
    var called := false

    animator.play_oneshot(1, "enemy_death", func():
        called = true
    )

    # Simulate until complete
    for i in range(10):
        animator.update(0.1)

    assert(called, "Callback should be called")
    _pass("test_oneshot_callback")
```
