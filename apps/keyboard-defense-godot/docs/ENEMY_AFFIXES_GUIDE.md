# Enemy Affixes Guide

This document explains the affix system that adds variety and challenge to enemies in Keyboard Defense. Affixes are modifiers that grant special abilities or stat bonuses.

## Overview

Affixes create enemy variety without requiring new enemy types. A "Swift Goblin" behaves differently from an "Armored Goblin" despite being the same base creature.

```
Base Enemy + Affix = Enhanced Enemy
   goblin  + swift = fast goblin with +1 speed
   goblin  + shielded = goblin that absorbs first hit
```

## Affix Categories

### Tier 1 - Basic (Available from Day 1)

| Affix | Glyph | Effect |
|-------|-------|--------|
| **Swift** | `+` | +1 speed |
| **Armored** | `#` | +1 armor |
| **Resilient** | `*` | +2 HP |

### Tier 2 - Advanced (Available from Day 4)

| Affix | Glyph | Effect |
|-------|-------|--------|
| **Shielded** | `O` | First hit absorbed |
| **Splitting** | `~` | Spawns smaller enemies on death |
| **Regenerating** | `^` | Heals 1 HP every 3 ticks |
| **Enraged** | `!` | +1 speed when first damaged |

### Tier 3 - Elite (Available from Day 7)

| Affix | Glyph | Effect |
|-------|-------|--------|
| **Vampiric** | `V` | Heals when dealing damage |

## Affix Data Structure

```gdscript
# sim/affixes.gd
const AFFIXES := {
    "swift": {
        "id": "swift",
        "name": "Swift",
        "description": "Moves faster than normal",
        "speed_bonus": 1,
        "armor_bonus": 0,
        "hp_bonus": 0,
        "tier": 1,
        "glyph": "+"
    },
    "shielded": {
        "id": "shielded",
        "name": "Shielded",
        "description": "First hit is absorbed",
        "speed_bonus": 0,
        "armor_bonus": 0,
        "hp_bonus": 0,
        "tier": 2,
        "glyph": "O",
        "special": "first_hit_immunity"  # Special behavior
    }
}
```

## Affix Application

### When Affixes Are Applied

```gdscript
# sim/affixes.gd
static func should_have_affix(state: GameState, enemy_kind: String) -> bool:
    # Elite enemies always have affixes
    if enemy_kind == "elite":
        return true

    # Champion enemies have high affix chance
    if enemy_kind == "champion":
        return SimRng.roll_range(state, 1, 100) <= 75

    # Regular enemies gain affix chance based on day
    var base_chance: int = 0
    if state.day >= 5:
        base_chance = (state.day - 4) * 5  # 5% at day 5, 10% at day 6, etc.

    return SimRng.roll_range(state, 1, 100) <= base_chance
```

### Affix Chance by Day

| Day | Regular Enemy | Champion | Elite |
|-----|---------------|----------|-------|
| 1-4 | 0% | 75% | 100% |
| 5 | 5% | 75% | 100% |
| 6 | 10% | 75% | 100% |
| 10 | 30% | 75% | 100% |
| 15 | 55% | 75% | 100% |
| 20 | 80% | 75% | 100% |

### Applying Affix to Enemy

```gdscript
static func apply_affix_to_enemy(enemy: Dictionary, affix_id: String) -> Dictionary:
    var affix = get_affix(affix_id)
    if affix.is_empty():
        return enemy

    # Apply stat bonuses
    enemy["speed"] += affix.get("speed_bonus", 0)
    enemy["armor"] += affix.get("armor_bonus", 0)
    enemy["hp"] += affix.get("hp_bonus", 0)

    # Store affix reference
    enemy["affix"] = affix_id

    # Initialize special state
    var special = affix.get("special", "")
    match special:
        "first_hit_immunity":
            enemy["shield_active"] = true
        "regenerate":
            enemy["regen_counter"] = 0
        "enrage_on_damage":
            enemy["enraged"] = false

    return enemy
```

## Special Affix Behaviors

### Shielded (`first_hit_immunity`)

The shield absorbs the first hit completely:

```gdscript
# In apply_intent.gd, before damage calculation
if SimAffixes.has_active_shield(enemy):
    enemy = SimAffixes.process_shield_hit(enemy)
    events.append("Shield absorbed the hit!")
    return  # No damage

# Shield processing
static func process_shield_hit(enemy: Dictionary) -> Dictionary:
    enemy["shield_active"] = false
    return enemy
```

### Regenerating (`regenerate`)

Heals every 3 combat ticks:

```gdscript
# Called during _enemy_ability_tick()
static func process_regeneration(enemy: Dictionary) -> Dictionary:
    if enemy.get("affix", "") != "regenerating":
        return enemy

    var counter = enemy.get("regen_counter", 0) + 1
    enemy["regen_counter"] = counter

    if counter >= 3:
        enemy["hp"] += 1
        enemy["regen_counter"] = 0

    return enemy
```

### Enraged (`enrage_on_damage`)

Gains speed when first damaged:

```gdscript
# Called when enemy takes damage
static func process_enrage(enemy: Dictionary) -> Dictionary:
    if enemy.get("affix", "") != "enraged":
        return enemy
    if enemy.get("enraged", false):
        return enemy  # Already enraged

    enemy["enraged"] = true
    enemy["speed"] += 1
    return enemy
```

### Splitting (`spawn_on_death`)

Spawns smaller enemies when killed:

```gdscript
# In _kill_enemy(), after removing the enemy
if enemy.get("affix", "") == "splitting":
    _spawn_split_enemies(state, enemy, events)

static func _spawn_split_enemies(state: GameState, parent: Dictionary, events: Array[String]) -> void:
    var pos = parent.get("pos", state.base_pos)
    for i in range(2):  # Spawn 2 smaller enemies
        var spawn = SimEnemies.make_enemy(state, "swarm", pos)
        spawn["hp"] = max(1, spawn["hp"] / 2)  # Half HP
        state.enemies.append(spawn)
    events.append("Enemy split into smaller foes!")
```

### Vampiric (`lifesteal`)

Heals when dealing damage to castle:

```gdscript
# In _enemy_attack_castle()
if enemy.get("affix", "") == "vampiric":
    var heal = min(damage, enemy.get("max_hp", 5) - enemy.get("hp", 0))
    if heal > 0:
        enemy["hp"] += heal
        events.append("Vampiric enemy healed!")
```

## Display Considerations

### Enemy Name with Affix

```gdscript
func get_enemy_display_name(enemy: Dictionary) -> String:
    var name = enemy.get("kind", "enemy")
    var affix = enemy.get("affix", "")
    if affix != "":
        var affix_name = SimAffixes.get_affix_name(affix)
        return "%s %s" % [affix_name, name]
    return name.capitalize()

# Examples:
# "Swift Goblin"
# "Shielded Orc"
# "Regenerating Troll"
```

### Glyph Overlay

Use glyphs for visual indicators:

```gdscript
func get_enemy_glyph(enemy: Dictionary) -> String:
    var affix = enemy.get("affix", "")
    if affix == "":
        return ""
    return SimAffixes.get_affix_glyph(affix)

# In UI/rendering
var glyph = get_enemy_glyph(enemy)
if glyph != "":
    draw_string(font, pos + Vector2(-4, -16), glyph, HORIZONTAL_ALIGNMENT_CENTER)
```

## Adding New Affixes

### Step 1: Define Affix Data

```gdscript
# In AFFIXES constant
"thorny": {
    "id": "thorny",
    "name": "Thorny",
    "description": "Reflects damage when hit",
    "speed_bonus": 0,
    "armor_bonus": 0,
    "hp_bonus": 1,
    "tier": 2,
    "glyph": "%",
    "special": "reflect_damage"
}
```

### Step 2: Add to Tier List

```gdscript
# In AFFIX_TIERS
const AFFIX_TIERS := {
    1: ["swift", "armored", "resilient"],
    2: ["shielded", "splitting", "regenerating", "enraged", "thorny"],  # Added
    3: ["vampiric"]
}
```

### Step 3: Initialize Special State

```gdscript
# In apply_affix_to_enemy()
match special:
    # ... existing ...
    "reflect_damage":
        enemy["thorns_active"] = true
```

### Step 4: Implement Behavior

```gdscript
# New function for thorns
static func process_thorns(enemy: Dictionary, damage: int) -> int:
    if not enemy.get("thorns_active", false):
        return 0
    return int(damage * 0.5)  # Reflect 50%

# In damage application
var reflected = SimAffixes.process_thorns(enemy, damage)
if reflected > 0:
    # Apply to castle or attacker
```

### Step 5: Update Serialization

```gdscript
# In serialize_affix_state()
if enemy.has("thorns_active"):
    result["thorns_active"] = enemy.get("thorns_active", false)

# In deserialize_affix_state()
if raw.has("thorns_active"):
    enemy["thorns_active"] = raw.get("thorns_active", false)
```

## Integration with Combat

### Damage Flow with Affixes

```
Player types word → Target enemy found
                          │
                          ▼
                   Has active shield?
                    /           \
                  Yes            No
                   │              │
            Absorb hit       Calculate damage
            (no damage)            │
                   │              ▼
                   │     Has armor? → Reduce damage
                   │              │
                   │              ▼
                   │     Apply damage to HP
                   │              │
                   │              ▼
                   │     Process enrage (if applicable)
                   │              │
                   │              ▼
                   │     HP <= 0? → Kill (process splitting)
                   │              │
                   ▼              ▼
              Next tick     Next tick
                   │              │
                   ▼              ▼
           Process regeneration (all enemies)
```

### Combat Tick Integration

```gdscript
# In _enemy_ability_tick()
static func _enemy_ability_tick(state: GameState, events: Array[String]) -> void:
    for enemy in state.enemies:
        # Process regeneration
        enemy = SimAffixes.process_regeneration(enemy)

        # Process vampiric (on attack)
        if enemy.get("attacking", false):
            if enemy.get("affix", "") == "vampiric":
                # Heal calculation
```

## Testing Affixes

```gdscript
func test_affix_application():
    var enemy = {"hp": 5, "speed": 1, "armor": 0}
    enemy = SimAffixes.apply_affix_to_enemy(enemy, "swift")
    assert(enemy["speed"] == 2, "Swift should add 1 speed")
    assert(enemy["affix"] == "swift", "Affix should be stored")
    _pass("test_affix_application")

func test_shield_absorption():
    var enemy = {"hp": 5}
    enemy = SimAffixes.apply_affix_to_enemy(enemy, "shielded")
    assert(SimAffixes.has_active_shield(enemy), "Shield should be active")

    enemy = SimAffixes.process_shield_hit(enemy)
    assert(not SimAffixes.has_active_shield(enemy), "Shield should be consumed")
    _pass("test_shield_absorption")
```

## Balancing Considerations

| Affix | Threat Increase | Counter Strategy |
|-------|-----------------|------------------|
| Swift | High | Prioritize early |
| Armored | Medium | Use critical hits |
| Resilient | Low | Just more HP to type |
| Shielded | Medium | Waste one word |
| Splitting | High | Prepare for spawns |
| Regenerating | High | Kill quickly |
| Enraged | Medium | One-shot if possible |
| Vampiric | High | Prevent castle damage |

## Common Patterns

### Check if Enemy Has Specific Affix

```gdscript
if enemy.get("affix", "") == "regenerating":
    # Handle regeneration
```

### Get All Enemies with Affixes

```gdscript
var affixed_enemies = state.enemies.filter(func(e): return e.has("affix"))
```

### Display Affix Info in UI

```gdscript
var affix_id = enemy.get("affix", "")
if affix_id != "":
    var affix_data = SimAffixes.get_affix(affix_id)
    tooltip.text = "%s\n%s" % [
        affix_data.get("name", ""),
        affix_data.get("description", "")
    ]
```
