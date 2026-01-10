# VFX and Persistence Guide

Visual effects system and game save/load utilities.

## Overview

This guide covers:
- `hit_effects.gd` - Particle effects for combat and typing feedback
- `persistence.gd` - Save/load system for game state

## HitEffects (game/hit_effects.gd)

Particle-based visual effects for combat feedback.

### Constants

```gdscript
const PARTICLE_COUNT := 6
const PARTICLE_LIFETIME := 0.4
const PARTICLE_SPEED := 120.0
const PARTICLE_SIZE := Vector2(4, 4)
const SPARK_SIZE := Vector2(6, 2)
```

### Effect Types

#### Hit Sparks
```gdscript
func spawn_hit_sparks(parent: Node, position: Vector2, color: Color = Color(1.0, 0.9, 0.5, 1.0)) -> void:
    # Radiating yellow/gold sparks on normal hit
    # 6 particles in circular pattern
    # Default: golden color
```

#### Power Burst
```gdscript
func spawn_power_burst(parent: Node, position: Vector2) -> void:
    # Larger, brighter burst for critical/power hits
    # 1.5x particle size and speed
    # Brighter white-gold color
```

#### Damage Flash
```gdscript
func spawn_damage_flash(parent: Node, position: Vector2) -> void:
    # Red particles when castle takes damage
    # 8 particles at reduced speed (0.7x)
    # Red color with slight alpha
```

#### Word Complete Burst
```gdscript
func spawn_word_complete_burst(parent: Node, position: Vector2) -> void:
    # Celebratory upward burst for word completion
    # 12 particles
    # Golden-to-cyan gradient
    # Upward velocity bias
```

### Particle System

```gdscript
func update(delta: float) -> void:
    # Called from _process()
    # Updates all active particles:
    # - Apply velocity
    # - Apply gravity (downward acceleration)
    # - Fade out over lifetime
    # - Queue_free when lifetime expires

func clear() -> void:
    # Removes all active particles immediately
```

### Particle Structure

Each particle is a ColorRect with metadata:

```gdscript
particle.set_meta("velocity", velocity)
particle.set_meta("lifetime", PARTICLE_LIFETIME)
particle.set_meta("age", 0.0)
```

### Usage Example

```gdscript
var hit_effects: HitEffects

func _ready() -> void:
    hit_effects = HitEffects.new()
    add_child(hit_effects)

func _process(delta: float) -> void:
    hit_effects.update(delta)

func _on_enemy_hit(position: Vector2, is_critical: bool) -> void:
    if is_critical:
        hit_effects.spawn_power_burst(self, position)
    else:
        hit_effects.spawn_hit_sparks(self, position)

func _on_word_completed(position: Vector2) -> void:
    hit_effects.spawn_word_complete_burst(self, position)

func _on_castle_damaged(position: Vector2) -> void:
    hit_effects.spawn_damage_flash(self, position)

func _on_scene_change() -> void:
    hit_effects.clear()
```

### Gravity and Motion

```gdscript
# In update():
var velocity: Vector2 = particle.get_meta("velocity")
velocity.y += 200.0 * delta  # Gravity
particle.set_meta("velocity", velocity)
particle.position += velocity * delta

# Fade out
var age: float = particle.get_meta("age") + delta
var alpha: float = 1.0 - (age / lifetime)
particle.modulate.a = max(0.0, alpha)
```

## GamePersistence (game/persistence.gd)

Save/load system for game state.

### Constants

```gdscript
const SAVE_PATH := "user://savegame.json"
```

### Save State

```gdscript
static func save_state(state: GameState) -> Dictionary:
    # Serializes GameState to JSON
    # Writes to user://savegame.json
    # Returns: {"ok": true, "path": SAVE_PATH}
    # Or: {"ok": false, "error": "error message"}
```

### Load State

```gdscript
static func load_state() -> Dictionary:
    # Reads and parses savegame.json
    # Reconstructs GameState from JSON
    # Returns: {"ok": true, "state": GameState}
    # Or: {"ok": false, "error": "error message"}
```

### Error Handling

```gdscript
# File not found
{"ok": false, "error": "No save file found."}

# File read error
{"ok": false, "error": "Failed to open save file."}

# JSON parse error
{"ok": false, "error": "Save file is corrupted."}
```

### Serialization Format

```json
{
  "version": 1,
  "day": 5,
  "phase": "day",
  "ap": 3,
  "ap_max": 3,
  "hp": 8,
  "gold": 150,
  "resources": {"wood": 25, "stone": 15, "food": 20},
  "buildings": {"farm": 2, "tower": 1},
  "lesson_id": "home_row",
  "rng_seed": "my_seed",
  "rng_state": 12345,
  "map_w": 16,
  "map_h": 16,
  "terrain": [0, 1, 2, ...],
  "structures": {"45": "tower", "67": "wall"},
  "discovered": {"0": true, "1": true, ...},
  "purchased_kingdom_upgrades": ["typing_power_1"],
  "purchased_unit_upgrades": []
}
```

### Usage Example

```gdscript
# Saving
func _on_save_requested() -> void:
    var result = GamePersistence.save_state(current_state)
    if result.ok:
        events.append("Game saved to %s" % result.path)
    else:
        events.append("Save failed: %s" % result.error)

# Loading
func _on_load_requested() -> void:
    var result = GamePersistence.load_state()
    if result.ok:
        current_state = result.state
        _refresh_display()
        events.append("Game loaded.")
    else:
        events.append("Load failed: %s" % result.error)

# Auto-save on night end
func _on_dawn() -> void:
    var _result = GamePersistence.save_state(current_state)
```

### Save Location

Platform-specific user data directory:
- Windows: `%APPDATA%\Godot\app_userdata\Keyboard Defense\savegame.json`
- macOS: `~/Library/Application Support/Godot/app_userdata/Keyboard Defense/savegame.json`
- Linux: `~/.local/share/godot/app_userdata/Keyboard Defense/savegame.json`

## Integration Example

Combining VFX with game events:

```gdscript
extends Node2D

var hit_effects: HitEffects
var state: GameState

func _ready() -> void:
    hit_effects = HitEffects.new()
    add_child(hit_effects)

    # Try to load saved game
    var load_result = GamePersistence.load_state()
    if load_result.ok:
        state = load_result.state
    else:
        state = DefaultState.create()

func _process(delta: float) -> void:
    hit_effects.update(delta)

func _on_enemy_defeated(enemy_pos: Vector2) -> void:
    hit_effects.spawn_power_burst(self, enemy_pos)

func _on_word_typed(word_pos: Vector2) -> void:
    hit_effects.spawn_word_complete_burst(self, word_pos)

func _on_game_over() -> void:
    hit_effects.clear()
    # Don't auto-save on game over

func _on_victory() -> void:
    hit_effects.clear()
    GamePersistence.save_state(state)
```

## File Dependencies

- `game/hit_effects.gd` - No dependencies (standalone Node)
- `game/persistence.gd` - Depends on sim/types.gd (GameState)
