# Implementation Example: Adding a New Enemy Type

This walkthrough shows every file you need to touch when adding a new enemy type to Keyboard Defense.

## Example: Adding a "Healer" Enemy

The healer enemy regenerates HP over time and heals nearby allies.

---

## Step 1: Define Enemy Stats in `sim/enemies.gd`

Add the new enemy kind to the `ENEMY_KINDS` constant:

```gdscript
# sim/enemies.gd - Line ~8
const ENEMY_KINDS := {
    # ... existing enemies ...
    "healer": {"speed": 1, "armor": 0, "hp_bonus": 0, "glyph": "H", "heal_rate": 1}
}
```

**Fields:**
- `speed`: Movement speed (1 = normal, 2 = fast, 3 = very fast)
- `armor`: Damage reduction
- `hp_bonus`: Added to base HP calculation
- `glyph`: ASCII character for map display
- Custom fields (e.g., `heal_rate`) for special abilities

## Step 2: Add Scaling Tables

Add entries to the day-scaling tables:

```gdscript
# sim/enemies.gd - ENEMY_HP_BONUS_BY_DAY
const ENEMY_HP_BONUS_BY_DAY := {
    # ... existing ...
    "healer": [0, 0, 0, 1, 1, 1, 2]  # 7 entries for days 1-7+
}

# sim/enemies.gd - ENEMY_ARMOR_BY_DAY
const ENEMY_ARMOR_BY_DAY := {
    # ... existing ...
    "healer": [0, 0, 0, 0, 0, 0, 1]
}

# sim/enemies.gd - ENEMY_SPEED_BY_DAY
const ENEMY_SPEED_BY_DAY := {
    # ... existing ...
    "healer": [1, 1, 1, 1, 1, 1, 1]
}
```

## Step 3: Implement Special Behavior in `sim/tick.gd`

If the enemy has special abilities, add logic to the tick function:

```gdscript
# sim/tick.gd - in _tick_enemies() or similar

# Healer regeneration
for enemy in state.enemies:
    if enemy.get("heal_rate", 0) > 0:
        var heal_amount: int = enemy["heal_rate"]
        var max_hp: int = _calculate_max_hp(enemy)
        enemy["hp"] = mini(enemy["hp"] + heal_amount, max_hp)

# Healer healing nearby allies
for enemy in state.enemies:
    if enemy.get("heal_rate", 0) > 0:
        for ally in state.enemies:
            if ally != enemy and _distance(enemy, ally) <= 2:
                ally["hp"] = mini(ally["hp"] + 1, _calculate_max_hp(ally))
```

## Step 4: Add to Wave Composition in `sim/balance.gd`

Configure when this enemy appears in waves:

```gdscript
# sim/balance.gd - WAVE_COMPOSITION or similar

const WAVE_COMPOSITION := {
    # ... existing ...
    # Healers appear starting day 4
    4: {"raider": 3, "healer": 1},
    5: {"raider": 2, "armored": 1, "healer": 1},
    # ...
}
```

Or add to the wave generation logic:

```gdscript
# In wave generation function
if day >= 4 and rng.randf() < 0.2:
    composition["healer"] = 1
```

## Step 5: Add Visual Assets

### Option A: SVG Sprite (Preferred)

Create `assets/art/src-svg/enemies/enemy_healer.svg`:

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <!-- Green healer with cross symbol -->
  <circle cx="16" cy="16" r="12" fill="#32cd32"/>
  <rect x="14" y="8" width="4" height="16" fill="white"/>
  <rect x="8" y="14" width="16" height="4" fill="white"/>
</svg>
```

### Option B: Procedural Drawing

Add to grid renderer or enemy drawing:

```gdscript
# game/grid_renderer.gd - in draw_enemy() or similar
"healer":
    # Draw green circle with cross
    draw_circle(pos, 12, Color("#32cd32"))
    draw_rect(Rect2(pos.x - 2, pos.y - 8, 4, 16), Color.WHITE)
    draw_rect(Rect2(pos.x - 8, pos.y - 2, 16, 4), Color.WHITE)
```

## Step 6: Update Assets Manifest

Add to `data/assets_manifest.json` if using sprites:

```json
{
  "id": "enemy_healer",
  "path": "res://assets/sprites/enemy_healer.png",
  "source_svg": "res://assets/art/src-svg/enemies/enemy_healer.svg",
  "expected_width": 32,
  "expected_height": 32,
  "max_kb": 4,
  "pixel_art": true,
  "category": "enemies"
}
```

## Step 7: Add to Enemy Bestiary (Optional)

Update `docs/plans/p1/ENEMY_BESTIARY_CATALOG.md`:

```markdown
### Healer
- **Role:** Support
- **Speed:** 1 (Normal)
- **Armor:** 0
- **Special:** Regenerates 1 HP per tick, heals nearby allies
- **First Appearance:** Day 4
- **Strategy:** Prioritize healers to prevent enemy recovery
```

## Step 8: Add Tests

Add test cases to `tests/run_tests.gd`:

```gdscript
func test_healer_enemy_creation() -> void:
    var state := GameState.new()
    var enemy := SimEnemies.spawn_enemy(state, "healer", 1)
    assert(enemy != null, "Should create healer enemy")
    assert(enemy.get("heal_rate", 0) == 1, "Healer should have heal_rate")
    _pass("test_healer_enemy_creation")

func test_healer_regeneration() -> void:
    var state := GameState.new()
    var enemy := SimEnemies.spawn_enemy(state, "healer", 1)
    var initial_hp: int = enemy["hp"]
    enemy["hp"] -= 2  # Damage it
    SimTick.tick(state)  # Run a tick
    assert(enemy["hp"] > initial_hp - 2, "Healer should regenerate HP")
    _pass("test_healer_regeneration")
```

## Step 9: Run Validation

```bash
# Validate schemas
./scripts/validate.sh

# Run tests
godot --headless --path . --script res://tests/run_tests.gd

# Run balance scenarios
godot --headless --path . --script res://tools/run_scenarios.gd
```

---

## Files Changed Summary

| File | Change |
|------|--------|
| `sim/enemies.gd` | Add to ENEMY_KINDS, scaling tables |
| `sim/tick.gd` | Add special ability logic |
| `sim/balance.gd` | Add to wave composition |
| `assets/art/src-svg/enemies/enemy_healer.svg` | Create sprite |
| `data/assets_manifest.json` | Register asset |
| `tests/run_tests.gd` | Add test cases |

## Common Pitfalls

1. **Forgetting scaling tables** - Enemy will have flat stats if not in `*_BY_DAY` tables
2. **Missing glyph** - ASCII map will show wrong character
3. **Not testing wave composition** - Enemy may never spawn
4. **Forgetting manifest entry** - Asset loader won't find the sprite
