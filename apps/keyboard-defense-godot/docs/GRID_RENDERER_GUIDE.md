# Grid Renderer Guide

This document explains the procedural 2D grid rendering system that visualizes the game map, terrain, structures, enemies, POIs, and visual effects.

## Overview

The grid renderer draws the game world using Godot's `_draw()` system:

```
State Update → Cache Textures → Draw Terrain → Draw Structures → Draw Enemies → Draw Effects
      ↓             ↓               ↓                ↓               ↓              ↓
  update_state   AssetLoader    Tile colors      Sprite/glyph    Animations     Particles
```

## Configuration

### Export Variables

```gdscript
# game/grid_renderer.gd
@export var cell_size: Vector2 = Vector2(40, 40)
@export var origin: Vector2 = Vector2(560, 40)
@export var line_color: Color = Color(0.25, 0.25, 0.32, 1.0)
@export var undiscovered_color: Color = Color(0.08, 0.09, 0.12, 1.0)
@export var plains_color: Color = Color(0.2, 0.22, 0.18, 1.0)
@export var forest_color: Color = Color(0.13, 0.2, 0.13, 1.0)
@export var mountain_color: Color = Color(0.2, 0.2, 0.22, 1.0)
@export var water_color: Color = Color(0.1, 0.16, 0.25, 1.0)
@export var base_color: Color = Color(0.25, 0.4, 0.25, 1.0)
@export var cursor_color: Color = Color(0.9, 0.8, 0.35, 1.0)
@export var structure_color: Color = Color(0.95, 0.95, 0.95, 1.0)
@export var preview_color: Color = Color(0.9, 0.9, 0.9, 0.6)
@export var preview_blocked_color: Color = Color(0.9, 0.4, 0.4, 0.6)
@export var enemy_color: Color = Color(0.9, 0.3, 0.3, 1.0)
@export var enemy_highlight_color: Color = Color(0.95, 0.85, 0.4, 0.8)
@export var enemy_focus_color: Color = Color(1.0, 0.85, 0.2, 0.95)
@export var poi_color: Color = Color(0.4, 0.7, 0.9, 1.0)
@export var font_size: int = 16
@export var use_sprites: bool = true
```

### Animation Constants

```gdscript
const PARTICLE_LIFETIME := 0.35
const PARTICLE_SPEED := 100.0
const TRAIL_SPAWN_INTERVAL := 0.03
const MAX_PARTICLES := 200
const HIT_FLASH_DURATION := 0.12
const DAMAGE_NUMBER_LIFETIME := 0.9
const DAMAGE_NUMBER_RISE_SPEED := 50.0
const ENEMY_WALK_FPS := 8.0
const ENEMY_DEATH_FPS := 10.0
```

## State Synchronization

```gdscript
# game/grid_renderer.gd:123
func update_state(state: GameState) -> void:
    state_ref = state
    map_w = state.map_w
    map_h = state.map_h
    base_pos = state.base_pos
    cursor_pos = state.cursor_pos
    discovered = state.discovered.duplicate(true)
    terrain = state.terrain.duplicate(true)
    structures = state.structures.duplicate(true)
    structure_levels = state.structure_levels.duplicate(true)

    # Track enemy animations
    _sync_enemy_animations(state.enemies)

    enemies = state.enemies.duplicate(true)
    active_pois = state.active_pois.duplicate(true)
    roaming_enemies = state.roaming_enemies.duplicate(true)
    time_of_day = state.time_of_day
    threat_level = state.threat_level
    activity_mode = state.activity_mode
    queue_redraw()
```

## Drawing Layers

### Layer Order (bottom to top)

1. Terrain tiles
2. Path overlay (if enabled)
3. Grid lines
4. Structures
5. POIs
6. Building preview
7. Enemies (wave)
8. Roaming enemies
9. Base/Castle
10. Combo indicator
11. Night overlay
12. Threat bar
13. Activity mode indicator
14. Cursor
15. Particles
16. Damage numbers

### Main Draw Function

```gdscript
# game/grid_renderer.gd:160
func _draw() -> void:
    if font == null:
        font = ThemeDB.fallback_font

    # Compute distance field for path overlay
    var dist_field: PackedInt32Array = PackedInt32Array()
    if overlay_path_enabled and state_ref != null:
        dist_field = SimMap.compute_dist_to_base(state_ref)

    # Draw terrain tiles
    for y in range(map_h):
        for x in range(map_w):
            var top_left: Vector2 = origin + Vector2(x * cell_size.x, y * cell_size.y)
            var rect: Rect2 = Rect2(top_left, cell_size)
            var index: int = y * map_w + x
            var is_discovered: bool = discovered.has(index)
            var terrain_type := _terrain_at(index)

            # Draw terrain background
            if is_discovered:
                if use_sprites:
                    var tile_tex := _get_terrain_texture(terrain_type)
                    if tile_tex != null:
                        _draw_tiled_texture(rect, tile_tex)
                    else:
                        draw_rect(rect, _terrain_color(terrain_type), true)
                else:
                    draw_rect(rect, _terrain_color(terrain_type), true)
            else:
                draw_rect(rect, undiscovered_color, true)

            # Draw path overlay
            if overlay_path_enabled and dist_field.size() == map_w * map_h:
                var overlay_color: Color = overlay_reachable_color if dist_field[index] >= 0 else overlay_blocked_color
                draw_rect(rect, overlay_color, true)

            # Draw grid lines
            draw_rect(rect, line_color, false, 1.0)

            # Draw structures
            if is_discovered and structures.has(index):
                _draw_structure(rect, index)
```

## Terrain Rendering

### Terrain Colors

```gdscript
func _terrain_color(terrain_type: String) -> Color:
    match terrain_type:
        "plains", "grass": return plains_color
        "forest", "evergrove_dense": return forest_color
        "mountain", "stone": return mountain_color
        "water", "lake": return water_color
        _: return undiscovered_color
```

### Terrain Textures

```gdscript
func _get_terrain_texture(terrain_type: String) -> Texture2D:
    var sprite_id: String
    match terrain_type:
        "plains", "grass": sprite_id = "tile_grass"
        "forest", "evergrove_dense": sprite_id = "tile_evergrove_dense"
        "mountain", "stone": sprite_id = "tile_dirt"
        "water", "lake": sprite_id = "tile_water"
        _: return null
    return _get_texture(sprite_id)
```

## Structure Rendering

```gdscript
# game/grid_renderer.gd:202
func _draw_structure_sprite(rect: Rect2, building_type: String, level: int) -> void:
    var sprite_id := asset_loader.get_building_sprite_id(building_type)
    var tex := _get_texture(sprite_id)
    if tex != null:
        _draw_centered_texture(rect, tex)
    else:
        # Fallback to glyph
        var symbol: String = _structure_char(building_type, level)
        var text_pos: Vector2 = rect.position + Vector2(6, cell_size.y - 10)
        draw_string(font, text_pos, symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, structure_color)

func _structure_char(building_type: String, level: int) -> String:
    var base_char: String
    match building_type:
        "tower", "tower_arrow": base_char = "T"
        "tower_slow": base_char = "S"
        "wall": base_char = "W"
        "farm": base_char = "F"
        "lumberyard": base_char = "L"
        "quarry": base_char = "Q"
        "barracks": base_char = "B"
        "library": base_char = "Y"
        "gate": base_char = "G"
        "market": base_char = "M"
        _: base_char = "?"
    if level > 1:
        return "%s%d" % [base_char, level]
    return base_char
```

## Enemy Rendering

### Enhanced Enemy Sprite

```gdscript
# game/grid_renderer.gd:461
func _draw_enemy_sprite(rect: Rect2, tex: Texture2D, kind: String, mod_color: Color = Color.WHITE) -> void:
    var tex_size := tex.get_size()
    var scale_factor: float = minf(rect.size.x / tex_size.x, rect.size.y / tex_size.y) * 0.95
    var scaled_size: Vector2 = tex_size * scale_factor
    var offset: Vector2 = (rect.size - scaled_size) * 0.5
    var dest_rect := Rect2(rect.position + offset, scaled_size)

    # Draw dark backdrop circle for contrast
    var center := rect.position + rect.size * 0.5
    var backdrop_radius := scaled_size.x * 0.55
    draw_circle(center, backdrop_radius, Color(0.08, 0.08, 0.12, 0.85))

    # Draw colored outline based on enemy type
    var outline_color: Color
    match kind:
        "runner", "raider", "scout":
            outline_color = Color(0.9, 0.3, 0.2, 0.6)  # Red
        "brute", "armored":
            outline_color = Color(0.5, 0.4, 0.6, 0.6)  # Purple-grey
        "flyer":
            outline_color = Color(0.6, 0.3, 0.7, 0.6)  # Purple
        "shielder":
            outline_color = Color(0.3, 0.5, 0.7, 0.6)  # Blue
        "healer":
            outline_color = Color(0.3, 0.7, 0.4, 0.6)  # Green
        "boss_warlord", "boss_mage":
            outline_color = Color(1.0, 0.7, 0.2, 0.8)  # Gold
        _:
            outline_color = Color(0.8, 0.3, 0.3, 0.5)

    draw_arc(center, backdrop_radius + 1.5, 0.0, TAU, 16, outline_color, 2.0)
    draw_texture_rect(tex, dest_rect, false, mod_color)
```

### Enemy Highlights

```gdscript
# game/grid_renderer.gd:153
func set_enemy_highlights(candidate_ids: Array, focus_id: int) -> void:
    highlight_enemy_ids.clear()
    for enemy_id in candidate_ids:
        highlight_enemy_ids[int(enemy_id)] = true
    focus_enemy_id = focus_id
    queue_redraw()
```

Highlight boxes are drawn in the main enemy loop:
- **Highlight**: Yellow box for typing candidates
- **Focus**: Brighter gold box for current target

### Hit Flash

```gdscript
func trigger_hit_flash(enemy_id: int) -> void:
    _hit_flash_timers[enemy_id] = HIT_FLASH_DURATION

func _update_hit_flashes(delta: float) -> void:
    var to_remove: Array = []
    for enemy_id in _hit_flash_timers:
        _hit_flash_timers[enemy_id] -= delta
        if _hit_flash_timers[enemy_id] <= 0.0:
            to_remove.append(enemy_id)
    for enemy_id in to_remove:
        _hit_flash_timers.erase(enemy_id)
    if not to_remove.is_empty():
        queue_redraw()
```

## Animation System

### Enemy Animation State

```gdscript
var _enemy_anim_state: Dictionary = {}  # enemy_id -> {anim_type, frame, timer, kind}

func _sync_enemy_animations(new_enemies: Array) -> void:
    # Register new enemies
    for enemy in new_enemies:
        var enemy_id: int = int(enemy.get("id", 0))
        if not _enemy_anim_state.has(enemy_id):
            _enemy_anim_state[enemy_id] = {
                "anim_type": "walk",
                "frame": 0,
                "timer": 0.0,
                "kind": str(enemy.get("kind", "runner"))
            }

    # Unregister removed enemies
    var current_ids: Dictionary = {}
    for enemy in new_enemies:
        current_ids[int(enemy.get("id", 0))] = true
    var to_remove: Array = []
    for enemy_id in _enemy_anim_state:
        if not current_ids.has(enemy_id):
            to_remove.append(enemy_id)
    for enemy_id in to_remove:
        _enemy_anim_state.erase(enemy_id)

func _update_animations(delta: float) -> void:
    var needs_redraw: bool = false
    for enemy_id in _enemy_anim_state:
        var state: Dictionary = _enemy_anim_state[enemy_id]
        state["timer"] += delta
        var fps: float = ENEMY_WALK_FPS if state["anim_type"] == "walk" else ENEMY_DEATH_FPS
        var frame_time: float = 1.0 / fps
        if state["timer"] >= frame_time:
            state["timer"] -= frame_time
            state["frame"] += 1
            needs_redraw = true
    if needs_redraw:
        queue_redraw()
```

### Death Animation

```gdscript
func play_enemy_death_anim(enemy_id: int, kind: String) -> void:
    if _enemy_anim_state.has(enemy_id):
        _enemy_anim_state[enemy_id]["anim_type"] = "death"
        _enemy_anim_state[enemy_id]["frame"] = 0
        _enemy_anim_state[enemy_id]["timer"] = 0.0
```

## Particle System

### Particle Data Structure

```gdscript
var _active_particles: Array = []

# Particle dictionary structure:
# {
#     "pos": Vector2,
#     "velocity": Vector2,
#     "color": Color,
#     "lifetime": float,
#     "max_lifetime": float,
#     "size": float
# }
```

### Particle Update

```gdscript
func update_particles(delta: float) -> void:
    var to_remove: Array = []
    for i in range(_active_particles.size()):
        var p: Dictionary = _active_particles[i]
        p["lifetime"] -= delta
        if p["lifetime"] <= 0.0:
            to_remove.append(i)
            continue
        p["pos"] += p["velocity"] * delta

    # Remove expired particles (reverse order)
    for i in range(to_remove.size() - 1, -1, -1):
        _active_particles.remove_at(to_remove[i])

    if not _active_particles.is_empty():
        queue_redraw()

func _draw_particles() -> void:
    for p in _active_particles:
        var alpha: float = p["lifetime"] / p["max_lifetime"]
        var color: Color = p["color"]
        color.a *= alpha
        var size: float = p["size"] * alpha
        draw_circle(p["pos"], size, color)
```

### Spawning Effects

```gdscript
func spawn_projectile(target_pos: Vector2i, is_boss: bool = false) -> void:
    var start: Vector2 = origin + Vector2(base_pos.x * cell_size.x, base_pos.y * cell_size.y) + cell_size * 0.5
    var end: Vector2 = origin + Vector2(target_pos.x * cell_size.x, target_pos.y * cell_size.y) + cell_size * 0.5
    var direction: Vector2 = (end - start).normalized()

    var color: Color = Color(1.0, 0.85, 0.3) if is_boss else Color(0.9, 0.7, 0.2)
    _add_particle({
        "pos": start,
        "velocity": direction * PARTICLE_SPEED * 3.0,
        "color": color,
        "lifetime": PARTICLE_LIFETIME,
        "max_lifetime": PARTICLE_LIFETIME,
        "size": 6.0 if is_boss else 4.0
    })

func spawn_defeat_burst(pos: Vector2i, is_boss: bool = false) -> void:
    var center: Vector2 = origin + Vector2(pos.x * cell_size.x, pos.y * cell_size.y) + cell_size * 0.5
    var count: int = 12 if is_boss else 8
    var color: Color = Color(1.0, 0.7, 0.2) if is_boss else Color(0.9, 0.5, 0.2)

    for i in range(count):
        var angle: float = (float(i) / float(count)) * TAU
        var velocity: Vector2 = Vector2(cos(angle), sin(angle)) * PARTICLE_SPEED
        _add_particle({
            "pos": center,
            "velocity": velocity,
            "color": color,
            "lifetime": PARTICLE_LIFETIME * 1.5,
            "max_lifetime": PARTICLE_LIFETIME * 1.5,
            "size": 3.0
        })
```

## Combo Visualization

```gdscript
var _combo_count: int = 0
var _combo_pulse_time: float = 0.0
var _combo_ring_radius: float = 0.0

func set_combo(count: int) -> void:
    _combo_count = count
    queue_redraw()

# In _draw():
if _combo_count >= 3 and not reduced_motion:
    var combo_tier: int = mini(_combo_count / 5, 3)
    var ring_color: Color
    match combo_tier:
        0: ring_color = Color(0.9, 0.8, 0.3, 0.6)  # Yellow
        1: ring_color = Color(1.0, 0.6, 0.2, 0.7)  # Orange
        2: ring_color = Color(0.9, 0.3, 0.9, 0.8)  # Purple
        _: ring_color = Color(0.3, 0.9, 1.0, 0.9)  # Cyan (legendary)

    var pulse: float = sin(Time.get_ticks_msec() * 0.006) * 0.15 + 0.85
    var base_radius: float = 28.0 + float(combo_tier) * 4.0
    draw_arc(castle_center, base_radius * pulse, 0.0, TAU, 24, ring_color, 2.0)
```

| Combo | Tier | Color | Ring Size |
|-------|------|-------|-----------|
| 3-4 | 0 | Yellow | 28px |
| 5-9 | 1 | Orange | 32px |
| 10-14 | 2 | Purple | 36px |
| 15+ | 3 | Cyan | 40px |

## Damage Numbers

```gdscript
var _damage_numbers: Array = []

func spawn_damage_number(pos: Vector2i, amount: int, is_crit: bool = false) -> void:
    var screen_pos: Vector2 = origin + Vector2(pos.x * cell_size.x, pos.y * cell_size.y) + cell_size * 0.5
    _damage_numbers.append({
        "pos": screen_pos,
        "text": str(amount),
        "color": Color(1.0, 0.3, 0.3) if is_crit else Color(1.0, 0.8, 0.2),
        "lifetime": DAMAGE_NUMBER_LIFETIME,
        "size": 20 if is_crit else 16
    })

func _update_damage_numbers(delta: float) -> void:
    var to_remove: Array = []
    for i in range(_damage_numbers.size()):
        var dn: Dictionary = _damage_numbers[i]
        dn["lifetime"] -= delta
        dn["pos"].y -= DAMAGE_NUMBER_RISE_SPEED * delta
        if dn["lifetime"] <= 0.0:
            to_remove.append(i)
    for i in range(to_remove.size() - 1, -1, -1):
        _damage_numbers.remove_at(to_remove[i])
    if not to_remove.is_empty():
        queue_redraw()

func _draw_damage_numbers() -> void:
    for dn in _damage_numbers:
        var alpha: float = dn["lifetime"] / DAMAGE_NUMBER_LIFETIME
        var color: Color = dn["color"]
        color.a = alpha
        draw_string(font, dn["pos"], dn["text"], HORIZONTAL_ALIGNMENT_CENTER, -1, dn["size"], color)
```

## Night Overlay

```gdscript
# Time-of-day overlay (0.0-1.0 cycle)
if time_of_day > 0.7 or time_of_day < 0.2:
    var night_alpha: float = 0.0
    if time_of_day > 0.7:
        night_alpha = (time_of_day - 0.7) / 0.3 * 0.3  # Fade in to 30%
    else:
        night_alpha = (0.2 - time_of_day) / 0.2 * 0.3  # Fade out from 30%

    var night_overlay: Color = Color(0.05, 0.05, 0.15, night_alpha)
    var map_rect: Rect2 = Rect2(origin, Vector2(map_w * cell_size.x, map_h * cell_size.y))
    draw_rect(map_rect, night_overlay, true)
```

## Testing

```gdscript
func test_particle_limit():
    var renderer := preload("res://game/grid_renderer.gd").new()

    # Spawn MAX_PARTICLES + 10
    for i in range(MAX_PARTICLES + 10):
        renderer._add_particle({"lifetime": 1.0})

    assert(renderer._active_particles.size() == MAX_PARTICLES)
    _pass("test_particle_limit")

func test_enemy_animation_sync():
    var renderer := preload("res://game/grid_renderer.gd").new()
    var enemies := [
        {"id": 1, "kind": "runner"},
        {"id": 2, "kind": "brute"}
    ]

    renderer._sync_enemy_animations(enemies)
    assert(renderer._enemy_anim_state.has(1))
    assert(renderer._enemy_anim_state.has(2))

    # Remove enemy 1
    renderer._sync_enemy_animations([{"id": 2, "kind": "brute"}])
    assert(not renderer._enemy_anim_state.has(1))
    assert(renderer._enemy_anim_state.has(2))

    _pass("test_enemy_animation_sync")
```
