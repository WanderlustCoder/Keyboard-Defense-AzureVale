# Sprite Animator Guide

Central animation controller for sprite-based frame animations.

## Overview

`SpriteAnimator` (game/sprite_animator.gd) manages frame timing, state transitions, and oneshot animations for all sprite-based entities. It maintains animation state per entity ID and handles accessibility (reduced motion).

## State Structure

```gdscript
class AnimState:
    var sprite_id: String = ""      # Base sprite identifier
    var current_frame: int = 0      # Current animation frame
    var frame_timer: float = 0.0    # Time accumulator for frame advancement
    var fps: float = 8.0            # Frames per second
    var frame_count: int = 1        # Total frames in animation
    var loop: bool = true           # Whether to loop or play once
    var playing: bool = true        # Animation active state
    var on_complete: Callable       # Callback when oneshot finishes
    var base_sprite_id: String = "" # For reverting after oneshot
```

## Initialization

```gdscript
var _animations: Dictionary = {}  # entity_id -> AnimState
var _global_time: float = 0.0
var _asset_loader: AssetLoader
var reduced_motion: bool = false  # Accessibility setting

func _ready() -> void:
    _asset_loader = AssetLoader.new()
    _asset_loader._load_manifest()
```

## Core Functions

### Registering Animations

```gdscript
func register_animation(entity_id: int, sprite_id: String, anim_info: Dictionary = {}) -> void
```

Parameters:
- `entity_id` - Unique entity identifier
- `sprite_id` - Base sprite ID from asset manifest
- `anim_info` - Optional override: `{frame_count, fps, loop}`

If `anim_info` is empty, loads from AssetLoader.

### Unregistering

```gdscript
func unregister_animation(entity_id: int) -> void
```

Call when entity is removed to clean up state.

### Updating Animations

```gdscript
func update(delta: float) -> void
```

Call from `_process()` to advance all animations. Handles:
- Frame timing based on FPS
- Loop/oneshot completion
- Completion callbacks

### Oneshot Animations

```gdscript
func play_oneshot(entity_id: int, sprite_id: String, on_complete: Callable = Callable()) -> void
```

Play a non-looping animation (e.g., attack, death). After completion:
1. Calls `on_complete` callback if provided
2. Reverts to base animation if set

### Frame Control

```gdscript
func get_current_frame(entity_id: int) -> int
func set_frame(entity_id: int, frame: int) -> void
func get_frame_sprite_id(entity_id: int) -> String  # Returns "sprite_id_01", etc.
```

### Playback Control

```gdscript
func pause(entity_id: int) -> void
func resume(entity_id: int) -> void
func pause_all() -> void
func resume_all() -> void
```

### State Queries

```gdscript
func has_animation(entity_id: int) -> bool
func get_animation_state(entity_id: int) -> AnimState
func get_global_time() -> float  # For procedural effects
```

### Synchronization

```gdscript
func sync_animations(entity_ids: Array) -> void
```

Syncs multiple entities to same animation phase (useful for formation units).

### Cleanup

```gdscript
func clear_all() -> void
```

Clear all animations (e.g., on scene change).

## Frame Timing

```gdscript
func update(delta: float) -> void:
    _global_time += delta

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
                    # Handle completion callback...
```

## Reduced Motion Support

When `reduced_motion` is true:
- `register_animation()` returns immediately
- `update()` skips processing
- `play_oneshot()` immediately calls completion callback

```gdscript
func play_oneshot(entity_id: int, sprite_id: String, on_complete: Callable = Callable()) -> void:
    if reduced_motion:
        if on_complete.is_valid():
            on_complete.call()  # Immediate completion
        return
    # ... normal processing
```

## Frame Sprite ID Format

Animations use frame suffixes:
```
sprite_id_01  # Frame 1
sprite_id_02  # Frame 2
sprite_id_03  # Frame 3
```

```gdscript
func get_frame_sprite_id(entity_id: int) -> String:
    var state: AnimState = _animations[entity_id]
    return "%s_%02d" % [state.sprite_id, state.current_frame + 1]
```

## Usage Examples

### Basic Entity Animation

```gdscript
# In entity spawn
var anim_info = asset_loader.get_animation_info("enemy_runner")
sprite_animator.register_animation(enemy_id, "enemy_runner", anim_info)

# In _process
sprite_animator.update(delta)
var frame_id = sprite_animator.get_frame_sprite_id(enemy_id)
var texture = asset_loader.get_texture(frame_id)
enemy_sprite.texture = texture

# On entity death
sprite_animator.unregister_animation(enemy_id)
```

### Attack Animation

```gdscript
func play_attack_animation(entity_id: int) -> void:
    sprite_animator.play_oneshot(entity_id, "enemy_attack", _on_attack_complete)

func _on_attack_complete() -> void:
    # Attack animation finished, deal damage
    _apply_damage()
```

### Pausing During Menu

```gdscript
func _on_pause_menu_opened() -> void:
    sprite_animator.pause_all()

func _on_pause_menu_closed() -> void:
    sprite_animator.resume_all()
```

### Syncing Formation

```gdscript
# Make all soldiers march in sync
var soldier_ids = [1, 2, 3, 4]
sprite_animator.sync_animations(soldier_ids)
```

## Integration with GridRenderer

```gdscript
# In grid_renderer.gd
func _draw_entity(entity_id: int, pos: Vector2) -> void:
    var frame_id = sprite_animator.get_frame_sprite_id(entity_id)
    var texture = asset_loader.get_texture(frame_id)
    if texture:
        draw_texture(texture, pos)
    else:
        # Fallback to static sprite
        var base_id = sprite_animator.get_animation_state(entity_id).sprite_id
        texture = asset_loader.get_texture(base_id)
        draw_texture(texture, pos)
```

## Animation Info from Manifest

Asset manifest entries with animation:

```json
{
  "id": "enemy_runner",
  "path": "res://assets/art/enemies/runner.png",
  "category": "enemies",
  "animation": {
    "frame_count": 4,
    "fps": 8.0,
    "loop": true
  }
}
```

## File Dependencies

- `game/asset_loader.gd` - AssetLoader for animation info
- `data/assets_manifest.json` - Animation data source
