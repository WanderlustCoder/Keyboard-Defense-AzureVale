# Data Extraction Guide

This guide shows how to convert planning documents (in `docs/plans/`) into actual game data files (in `data/`).

## Workflow

```
1. Find relevant plan document
2. Locate JSON specifications in the doc
3. Extract and adapt to game schema
4. Save to appropriate data/ file
5. Update any loaders if schema changed
6. Test in-game
```

## Plan Doc → Data File Mapping

| Plan Document | Data File | Loader |
|--------------|-----------|--------|
| `ENEMY_BESTIARY_CATALOG.md` | `data/enemies.json` | `sim/enemies.gd` |
| `TOWER_SPECIFICATIONS_COMPLETE.md` | `data/towers.json` | `sim/buildings.gd` |
| `ITEM_CATALOG_COMPLETE.md` | `data/items.json` | (create loader) |
| `SKILL_TREE_COMPLETE.md` | `data/skills.json` | (create loader) |
| `ACHIEVEMENT_SYSTEM_COMPLETE.md` | `data/achievements.json` | `game/achievement_checker.gd` |
| `STATUS_EFFECTS_CATALOG.md` | `data/status_effects.json` | `sim/affixes.gd` |
| `CRAFTING_RECIPES_COMPLETE.md` | `data/crafting.json` | (create loader) |
| `LESSON_INTRODUCTIONS_*.md` | `data/lessons.json` | `sim/lessons.gd` |
| `NPC_DIALOGUE_SCRIPTS.md` | `data/story.json` | `game/story_manager.gd` |
| `WAVE_COMPOSITION_SYSTEM.md` | `data/waves.json` | `sim/enemies.gd` |

## Extraction Examples

### Example 1: Enemy from Plan to Data

**Source:** `docs/plans/p1/ENEMY_BESTIARY_CATALOG.md`
```json
{
  "enemy_id": "goblin_scout",
  "name": "Goblin Scout",
  "tier": 1,
  "base_stats": {
    "health": 25,
    "speed": 70,
    "damage": 5
  },
  "word_config": {
    "pool": "common_short",
    "length_range": [3, 5]
  }
}
```

**Target:** `data/enemies.json`
```json
{
  "goblin_scout": {
    "name": "Goblin Scout",
    "hp": 25,
    "speed": 70,
    "damage": 5,
    "word_pool": "common_short",
    "word_min": 3,
    "word_max": 5
  }
}
```

**Adaptation Notes:**
- Flatten nested structures for simpler access
- Use existing field names from current schema
- Keep IDs as dictionary keys (not internal field)

### Example 2: Achievement from Plan to Data

**Source:** `docs/plans/p1/ACHIEVEMENT_SYSTEM_COMPLETE.md`
```json
{
  "achievement_id": "first_blood",
  "name": "First Blood",
  "description": "Defeat your first enemy",
  "category": "combat",
  "unlock_condition": {
    "type": "enemy_kills",
    "count": 1
  },
  "reward": {
    "gold": 50,
    "title": "Defender"
  }
}
```

**Target:** `data/achievements.json`
```json
{
  "first_blood": {
    "name": "First Blood",
    "description": "Defeat your first enemy",
    "category": "combat",
    "condition": "enemy_kills >= 1",
    "reward_gold": 50,
    "reward_title": "Defender"
  }
}
```

### Example 3: Lesson from Plan to Data

**Source:** `docs/plans/p1/LESSON_INTRODUCTIONS_DRAFT.md`
```json
{
  "lesson_id": "home_row_1",
  "name": "Home Row Basics",
  "introduction": "Welcome to your first lesson...",
  "focus_keys": ["a", "s", "d", "f", "j", "k", "l", ";"],
  "finger_guide": {
    "a": "left_pinky",
    "s": "left_ring",
    ...
  }
}
```

**Target:** `data/lessons.json`
```json
{
  "home_row_1": {
    "name": "Home Row Basics",
    "description": "Welcome to your first lesson...",
    "focus_keys": ["a", "s", "d", "f", "j", "k", "l", ";"],
    "word_pool": ["as", "sad", "dad", "fall", "salad"],
    "difficulty": 1,
    "category": "beginner"
  }
}
```

## Schema Conventions

### Current Data Schemas

**lessons.json:**
```json
{
  "version": 2,
  "default_lesson": "full_alpha",
  "graduation_paths": {...},
  "lessons": {
    "lesson_id": {
      "name": "string",
      "description": "string",
      "focus_keys": ["char"],
      "word_pool": ["word"],
      "difficulty": 1-5,
      "category": "string"
    }
  }
}
```

**buildings.json:**
```json
{
  "building_id": {
    "name": "string",
    "description": "string",
    "cost": {"wood": 0, "stone": 0},
    "production": {"resource": amount},
    "unlocks": "requirement"
  }
}
```

**story.json:**
```json
{
  "acts": [
    {
      "id": "act_1",
      "name": "string",
      "days": [1, 4],
      "focus": "string"
    }
  ],
  "dialogue": {
    "dialogue_id": {
      "speaker": "string",
      "lines": ["string"]
    }
  },
  "tips": {
    "category": ["tip string"]
  }
}
```

## Bulk Extraction Process

When implementing a new system from a plan doc:

### Step 1: Create Data File Structure
```bash
# Create new data file with version header
```
```json
{
  "version": 1,
  "entries": {}
}
```

### Step 2: Extract All Entries
Read through the plan doc and extract each JSON block. Transform to match game schema.

### Step 3: Create/Update Loader
```gdscript
# sim/new_system.gd or appropriate existing file
class_name NewSystem
extends RefCounted

static var _data: Dictionary = {}

static func _load_data() -> void:
    if _data.is_empty():
        var json = JSON.parse_string(
            FileAccess.get_file_as_string("res://data/new_system.json")
        )
        _data = json.get("entries", {})

static func get_entry(id: String) -> Dictionary:
    _load_data()
    return _data.get(id, {})

static func get_all_ids() -> Array:
    _load_data()
    return _data.keys()
```

### Step 4: Wire Into Game
Connect the loader to relevant game systems (sim logic, UI, etc.)

### Step 5: Test
```gdscript
# Add to tests/run_tests.gd
func test_new_system_data() -> void:
    var entry = NewSystem.get_entry("test_id")
    assert(entry.has("name"), "Entry should have name")
    _pass("test_new_system_data")
```

## Validation Checklist

Before committing extracted data:

- [ ] All IDs are unique within the file
- [ ] Required fields present for each entry
- [ ] Values within reasonable ranges
- [ ] References to other data (IDs) are valid
- [ ] JSON is valid (no trailing commas, proper quotes)
- [ ] Version number set appropriately
- [ ] Loader handles missing/invalid data gracefully

## Common Transformations

### Nested → Flat
```json
// Plan doc (nested):
"stats": { "hp": 100, "damage": 10 }

// Game data (flat):
"hp": 100, "damage": 10
```

### Array of Objects → Dictionary
```json
// Plan doc:
[{"id": "a", "name": "A"}, {"id": "b", "name": "B"}]

// Game data:
{"a": {"name": "A"}, "b": {"name": "B"}}
```

### Enum Strings → Simple Strings
```json
// Plan doc:
"rarity": {"type": "enum", "value": "RARE"}

// Game data:
"rarity": "rare"
```

### Complex Conditions → Simple Expressions
```json
// Plan doc:
"condition": {
  "type": "and",
  "conditions": [
    {"type": "stat_gte", "stat": "level", "value": 5},
    {"type": "has_item", "item": "key"}
  ]
}

// Game data:
"condition": "level >= 5 && has_item('key')"
```

## Quick Reference: What Goes Where

| Content Type | Data File | Notes |
|-------------|-----------|-------|
| Enemy stats | `enemies.json` | HP, speed, damage, word config |
| Building stats | `buildings.json` | Cost, production, bonuses |
| Tower stats | `towers.json` or `buildings.json` | Damage, range, upgrade paths |
| Lessons | `lessons.json` | Word pools, focus keys, difficulty |
| Story/dialogue | `story.json` | Acts, dialogue, tips |
| Upgrades | `kingdom_upgrades.json`, `unit_upgrades.json` | Costs, effects |
| Achievements | `achievements.json` | Conditions, rewards |
| Balance values | `sim/balance.gd` | Constants, formulas |
| Scenarios | `scenarios.json` | Test configurations |

## When to Create New Files vs Extend Existing

**Create new file when:**
- System is self-contained and large
- Data is loaded/used independently
- Clear separation improves maintainability

**Extend existing file when:**
- Data is closely related to existing system
- Would require cross-file references otherwise
- File is not already too large

## Tips for Efficient Extraction

1. **Use search in plan docs** - Look for ```json blocks
2. **Copy-paste, then transform** - Don't retype everything
3. **Batch similar entries** - Do all enemies at once, all items at once
4. **Validate incrementally** - Test after each batch, not at the end
5. **Document schema changes** - If you modify structure, note why
