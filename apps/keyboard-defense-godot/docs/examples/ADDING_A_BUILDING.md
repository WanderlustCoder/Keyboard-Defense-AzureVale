# Implementation Example: Adding a New Building

This walkthrough shows every file you need to touch when adding a new building type to Keyboard Defense.

## Example: Adding a "Barracks" Building

The barracks increases damage against enemies and provides a small gold income.

---

## Step 1: Register Building Type in `sim/types.gd`

Add to the building keys constant:

```gdscript
# sim/types.gd

const BUILDING_KEYS := [
    "farm", "lumber", "quarry", "wall", "tower",
    "barracks"  # Add new building
]
```

## Step 2: Add Building Data to `data/buildings.json`

Define the building's properties:

```json
{
  "version": 1,
  "buildings": {
    "barracks": {
      "name": "Barracks",
      "description": "Trains soldiers. Boosts damage and generates gold.",
      "category": "military",
      "cost": {
        "wood": 30,
        "stone": 20
      },
      "production": {
        "gold": 2
      },
      "effects": {
        "damage_bonus": 0.1
      },
      "build_time": 1,
      "max_count": 2,
      "requires_adjacent": null,
      "blocked_terrain": ["water", "mountain"]
    }
  }
}
```

**Fields:**
- `cost`: Resources required to build
- `production`: Resources generated per day
- `effects`: Passive bonuses (damage, defense, etc.)
- `max_count`: Limit on how many can be built (null = unlimited)
- `requires_adjacent`: Must be next to this building type
- `blocked_terrain`: Can't build on these terrain types

## Step 3: Add Build Cost to `sim/balance.gd`

```gdscript
# sim/balance.gd

const BUILD_COSTS := {
    "farm": {"wood": 10},
    "lumber": {"wood": 15},
    "quarry": {"wood": 10, "stone": 5},
    "wall": {"stone": 8},
    "tower": {"wood": 20, "stone": 15},
    "barracks": {"wood": 30, "stone": 20}  # Add new building
}

const BUILDING_EFFECTS := {
    "farm": {"food_production": 3},
    "lumber": {"wood_production": 2},
    "quarry": {"stone_production": 2},
    "tower": {"damage": 5, "range": 3},
    "barracks": {"damage_bonus": 0.1, "gold_production": 2}  # Add effects
}
```

## Step 4: Implement Production in `sim/buildings.gd`

Add production logic:

```gdscript
# sim/buildings.gd

static func calculate_production(state: GameState) -> Dictionary:
    var production := {
        "wood": 0, "stone": 0, "food": 0, "gold": 0
    }

    for idx in state.structures.keys():
        var building_type: String = state.structures[idx]
        match building_type:
            "farm":
                production["food"] += 3
            "lumber":
                production["wood"] += 2
            "quarry":
                production["stone"] += 2
            "barracks":
                production["gold"] += 2  # Add barracks production

    return production
```

## Step 5: Implement Effects in Combat

If the building affects combat, update the relevant systems:

```gdscript
# sim/tick.gd or sim/balance.gd

static func calculate_damage_multiplier(state: GameState) -> float:
    var multiplier: float = 1.0

    # Count barracks for damage bonus
    var barracks_count: int = 0
    for idx in state.structures.keys():
        if state.structures[idx] == "barracks":
            barracks_count += 1

    # 10% bonus per barracks
    multiplier += barracks_count * 0.1

    return multiplier
```

Apply in combat:

```gdscript
# Where damage is calculated
var base_damage: int = calculate_base_damage(word_length)
var multiplier: float = SimBuildings.calculate_damage_multiplier(state)
var final_damage: int = int(base_damage * multiplier)
```

## Step 6: Add Build Validation

Update placement validation in `sim/buildings.gd`:

```gdscript
# sim/buildings.gd

static func can_build(state: GameState, building: String, pos: Vector2i) -> Dictionary:
    # Check if building type is valid
    if building not in GameState.BUILDING_KEYS:
        return {"ok": false, "error": "Unknown building: %s" % building}

    # Check max count for barracks
    if building == "barracks":
        var count: int = _count_buildings(state, "barracks")
        if count >= 2:
            return {"ok": false, "error": "Maximum 2 barracks allowed."}

    # Check resources
    var cost: Dictionary = SimBalance.BUILD_COSTS.get(building, {})
    for resource in cost.keys():
        if state.resources.get(resource, 0) < cost[resource]:
            return {"ok": false, "error": "Not enough %s." % resource}

    # Check terrain
    var terrain: String = _get_terrain(state, pos)
    if terrain in ["water", "mountain"] and building == "barracks":
        return {"ok": false, "error": "Cannot build barracks on %s." % terrain}

    return {"ok": true}

static func _count_buildings(state: GameState, building_type: String) -> int:
    var count: int = 0
    for idx in state.structures.keys():
        if state.structures[idx] == building_type:
            count += 1
    return count
```

## Step 7: Update Parse Command

Add to build command parsing:

```gdscript
# sim/parse_command.gd - in build command handling

const VALID_BUILDINGS := ["farm", "lumber", "quarry", "wall", "tower", "barracks"]

# In parse() match:
"build":
    if tokens.size() < 2:
        return {"ok": false, "error": "Usage: build <type> [x y]"}
    var building_type: String = tokens[1].to_lower()
    if building_type not in VALID_BUILDINGS:
        return {"ok": false, "error": "Unknown building. Types: %s" % ", ".join(VALID_BUILDINGS)}
    # ... rest of parsing
```

## Step 8: Update Help Text

```gdscript
# sim/intents.gd - in help_lines()

"  build <type> [x y] - place a building (day only)",
"  build types: farm, lumber, quarry, wall, tower, barracks",
```

## Step 9: Add Visual Assets

### SVG Sprite

Create `assets/art/src-svg/buildings/barracks.svg`:

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <!-- Brown barracks with flag -->
  <rect x="4" y="12" width="24" height="16" fill="#8B4513"/>
  <polygon points="16,4 4,12 28,12" fill="#654321"/>
  <rect x="12" y="18" width="8" height="10" fill="#4a3728"/>
  <line x1="24" y1="4" x2="24" y2="12" stroke="#8B4513" stroke-width="2"/>
  <polygon points="24,4 24,8 28,6" fill="#dc143c"/>
</svg>
```

### Procedural Drawing

```gdscript
# game/grid_renderer.gd

func _draw_building(pos: Vector2, building_type: String) -> void:
    match building_type:
        "barracks":
            # Main building
            draw_rect(Rect2(pos.x - 12, pos.y - 4, 24, 16), Color("#8B4513"))
            # Roof
            draw_polygon([
                pos + Vector2(-12, -4),
                pos + Vector2(0, -12),
                pos + Vector2(12, -4)
            ], [Color("#654321")])
            # Door
            draw_rect(Rect2(pos.x - 4, pos.y + 2, 8, 10), Color("#4a3728"))
            # Flag
            draw_line(pos + Vector2(10, -12), pos + Vector2(10, -4), Color("#8B4513"), 2)
            draw_polygon([
                pos + Vector2(10, -12),
                pos + Vector2(10, -8),
                pos + Vector2(14, -10)
            ], [Color("#dc143c")])
```

## Step 10: Update Assets Manifest

```json
{
  "id": "building_barracks",
  "path": "res://assets/sprites/building_barracks.png",
  "source_svg": "res://assets/art/src-svg/buildings/barracks.svg",
  "expected_width": 32,
  "expected_height": 32,
  "max_kb": 4,
  "pixel_art": true,
  "category": "buildings"
}
```

## Step 11: Add Upgrade Path (Optional)

If the building can be upgraded:

```json
// data/building_upgrades.json
{
  "barracks": {
    "tier_2": {
      "name": "Veteran Barracks",
      "cost": {"wood": 40, "stone": 30, "gold": 20},
      "effects": {"damage_bonus": 0.2, "gold_production": 3}
    },
    "tier_3": {
      "name": "Elite Barracks",
      "cost": {"wood": 60, "stone": 50, "gold": 40},
      "effects": {"damage_bonus": 0.35, "gold_production": 5}
    }
  }
}
```

## Step 12: Add Tests

```gdscript
# tests/run_tests.gd

func test_barracks_build_cost() -> void:
    var cost: Dictionary = SimBalance.BUILD_COSTS.get("barracks", {})
    assert(cost.get("wood", 0) == 30, "Should cost 30 wood")
    assert(cost.get("stone", 0) == 20, "Should cost 20 stone")
    _pass("test_barracks_build_cost")

func test_barracks_max_count() -> void:
    var state := GameState.new()
    state.phase = "day"
    state.resources = {"wood": 100, "stone": 100}

    # Build first barracks
    var result1 := SimBuildings.try_build(state, "barracks", Vector2i(2, 2))
    assert(result1["ok"], "First barracks should build")

    # Build second barracks
    var result2 := SimBuildings.try_build(state, "barracks", Vector2i(4, 2))
    assert(result2["ok"], "Second barracks should build")

    # Third should fail
    var result3 := SimBuildings.try_build(state, "barracks", Vector2i(6, 2))
    assert(not result3["ok"], "Third barracks should fail")
    _pass("test_barracks_max_count")

func test_barracks_damage_bonus() -> void:
    var state := GameState.new()
    # Add a barracks
    state.structures[10] = "barracks"

    var multiplier := SimBuildings.calculate_damage_multiplier(state)
    assert(multiplier == 1.1, "One barracks should give 10% bonus")
    _pass("test_barracks_damage_bonus")
```

## Step 13: Run Validation

```bash
./scripts/validate.sh
./scripts/precommit.sh --quick
```

---

## Files Changed Summary

| File | Change |
|------|--------|
| `sim/types.gd` | Add to BUILDING_KEYS |
| `data/buildings.json` | Add building definition |
| `sim/balance.gd` | Add costs and effects |
| `sim/buildings.gd` | Add production and validation |
| `sim/parse_command.gd` | Add to valid buildings list |
| `sim/intents.gd` | Update help text |
| `assets/art/src-svg/buildings/barracks.svg` | Create sprite |
| `data/assets_manifest.json` | Register asset |
| `tests/run_tests.gd` | Add test cases |

## Building Properties Reference

| Property | Type | Description |
|----------|------|-------------|
| `cost` | Dict | Resources to build |
| `production` | Dict | Resources per day |
| `effects` | Dict | Passive bonuses |
| `max_count` | int/null | Build limit |
| `build_time` | int | Days to complete |
| `requires_adjacent` | string/null | Must be next to |
| `blocked_terrain` | array | Can't build on |

## Common Pitfalls

1. **Forgetting BUILDING_KEYS** - Building won't be recognized
2. **Missing balance entry** - Build cost will be zero or error
3. **No production logic** - Building won't generate resources
4. **Unlimited buildings** - May break game balance if no max_count
5. **Missing help text** - Players won't know the building exists
