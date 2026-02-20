# Tower & Building System

**Created:** 2026-01-08

Complete specification for defensive structures, upgrades, and strategic placement.

---

## System Overview

### Tower Role in Combat

```
┌─────────────────────────────────────────────────────────────┐
│                    TOWER FUNCTION                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Primary: SUPPORT typing damage with automatic effects      │
│  Secondary: CONTROL enemy movement and positioning          │
│  Tertiary: BUFF player typing performance                   │
│                                                             │
│  Towers DO NOT replace typing - they enhance it!            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Building Grid

```
┌─────────────────────────────────────────────────────────────┐
│                    BATTLEFIELD GRID                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [S]──[P]──[P]──[P]──[P]──[P]──[P]──[P]──[P]──[C]         │
│   │    │    │    │    │    │    │    │    │    │          │
│  [S]──[P]──[T]──[P]──[T]──[P]──[T]──[P]──[T]──[C]         │
│   │    │    │    │    │    │    │    │    │    │          │
│  [S]──[P]──[P]──[P]──[P]──[P]──[P]──[P]──[P]──[C]         │
│   │    │    │    │    │    │    │    │    │    │          │
│  [S]──[P]──[T]──[P]──[T]──[P]──[T]──[P]──[T]──[C]         │
│   │    │    │    │    │    │    │    │    │    │          │
│  [S]──[P]──[P]──[P]──[P]──[P]──[P]──[P]──[P]──[C]         │
│                                                             │
│  [S] = Spawn point    [P] = Path    [T] = Tower slot       │
│  [C] = Castle                                               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Tower Categories

### Overview Table

| Category | Focus | Primary Effect | Synergy |
|----------|-------|----------------|---------|
| **Arrow** | DPS | Direct damage | Speed |
| **Arcane** | Debuff | Weaken enemies | Accuracy |
| **Holy** | Control | Stun/slow | Combo |
| **Siege** | AoE | Area damage | Burst |
| **Multi** | Utility | Multiple targets | Flexibility |

---

## Tower Types

### Arrow Tower Line

```json
{
  "tower_line": "arrow",
  "theme": "Physical damage, speed focus",
  "tiers": [
    {
      "tier": 1,
      "id": "tower_arrow",
      "name": "Arrow Tower",
      "cost": 50,
      "stats": {
        "damage": 2,
        "range": 3,
        "attack_speed": 1.0,
        "targets": 1
      },
      "ability": null,
      "description": "Basic defensive tower. Fires arrows at passing enemies."
    },
    {
      "tier": 2,
      "id": "tower_arrow_t2",
      "name": "Longbow Tower",
      "cost": 100,
      "upgrade_from": "tower_arrow",
      "stats": {
        "damage": 4,
        "range": 4,
        "attack_speed": 1.2,
        "targets": 1
      },
      "ability": {
        "name": "Piercing Shot",
        "description": "Every 5th shot pierces through enemies",
        "effect": "pierce_2_enemies"
      },
      "description": "Extended range tower with piercing capability."
    },
    {
      "tier": 3,
      "id": "tower_arrow_t3",
      "name": "Siege Ballista",
      "cost": 200,
      "upgrade_from": "tower_arrow_t2",
      "stats": {
        "damage": 10,
        "range": 5,
        "attack_speed": 0.5,
        "targets": 1
      },
      "ability": {
        "name": "Armor Break",
        "description": "Attacks ignore armor and apply -2 armor for 3s",
        "effect": "armor_break"
      },
      "description": "Devastating siege weapon for high-priority targets."
    }
  ]
}
```

### Arcane Tower Line

```json
{
  "tower_line": "arcane",
  "theme": "Magic damage, debuffs",
  "tiers": [
    {
      "tier": 1,
      "id": "tower_arcane",
      "name": "Arcane Tower",
      "cost": 60,
      "stats": {
        "damage": 1,
        "range": 3,
        "attack_speed": 0.8,
        "targets": 1
      },
      "ability": {
        "name": "Magic Bolt",
        "description": "Attacks mark enemies for +10% damage",
        "duration": 3
      },
      "description": "Mystical tower that weakens enemies."
    },
    {
      "tier": 2,
      "id": "tower_arcane_t2",
      "name": "Wizard Spire",
      "cost": 120,
      "upgrade_from": "tower_arcane",
      "stats": {
        "damage": 3,
        "range": 3,
        "attack_speed": 1.0,
        "targets": 2
      },
      "ability": {
        "name": "Chain Lightning",
        "description": "Attacks bounce to 2 additional enemies",
        "bounce_damage": 0.5
      },
      "description": "Advanced magic tower with chain attacks."
    },
    {
      "tier": 3,
      "id": "tower_arcane_t3",
      "name": "Archmage Tower",
      "cost": 250,
      "upgrade_from": "tower_arcane_t2",
      "stats": {
        "damage": 6,
        "range": 4,
        "attack_speed": 1.2,
        "targets": 3
      },
      "ability": {
        "name": "Arcane Explosion",
        "description": "Every 10s, explosion deals 20 damage in radius 2",
        "cooldown": 10
      },
      "description": "Supreme magical artillery with devastating AoE."
    }
  ]
}
```

### Holy Tower Line

```json
{
  "tower_line": "holy",
  "theme": "Control, healing, anti-undead",
  "tiers": [
    {
      "tier": 1,
      "id": "tower_holy",
      "name": "Holy Shrine",
      "cost": 70,
      "stats": {
        "damage": 1,
        "range": 2,
        "attack_speed": 0.6,
        "targets": 1
      },
      "ability": {
        "name": "Blessing",
        "description": "Nearby player accuracy +5%",
        "radius": 3
      },
      "description": "Sacred shrine that blesses the defender."
    },
    {
      "tier": 2,
      "id": "tower_holy_t2",
      "name": "Temple Guard",
      "cost": 140,
      "upgrade_from": "tower_holy",
      "stats": {
        "damage": 3,
        "range": 2,
        "attack_speed": 0.8,
        "targets": 2
      },
      "ability": {
        "name": "Smite",
        "description": "Attacks stun enemies for 0.5s",
        "stun_duration": 0.5
      },
      "description": "Holy warrior that stuns the unholy."
    },
    {
      "tier": 3,
      "id": "tower_holy_t3",
      "name": "Cathedral",
      "cost": 280,
      "upgrade_from": "tower_holy_t2",
      "stats": {
        "damage": 5,
        "range": 3,
        "attack_speed": 1.0,
        "targets": 3
      },
      "ability": {
        "name": "Divine Judgment",
        "description": "Every 15s, all enemies in range stunned for 2s",
        "cooldown": 15,
        "stun_duration": 2
      },
      "description": "Grand cathedral with overwhelming holy power."
    }
  ]
}
```

### Siege Tower Line

```json
{
  "tower_line": "siege",
  "theme": "AoE damage, slow attack",
  "tiers": [
    {
      "tier": 1,
      "id": "tower_siege",
      "name": "Catapult",
      "cost": 80,
      "stats": {
        "damage": 5,
        "range": 4,
        "attack_speed": 0.3,
        "targets": "aoe",
        "aoe_radius": 1
      },
      "ability": null,
      "description": "Slow but powerful area damage."
    },
    {
      "tier": 2,
      "id": "tower_siege_t2",
      "name": "Trebuchet",
      "cost": 160,
      "upgrade_from": "tower_siege",
      "stats": {
        "damage": 10,
        "range": 5,
        "attack_speed": 0.25,
        "targets": "aoe",
        "aoe_radius": 1.5
      },
      "ability": {
        "name": "Burning Pitch",
        "description": "Attacks leave fire that deals 2 DPS for 3s",
        "dot_damage": 2,
        "dot_duration": 3
      },
      "description": "Massive siege weapon with burning projectiles."
    },
    {
      "tier": 3,
      "id": "tower_siege_t3",
      "name": "War Engine",
      "cost": 320,
      "upgrade_from": "tower_siege_t2",
      "stats": {
        "damage": 20,
        "range": 6,
        "attack_speed": 0.2,
        "targets": "aoe",
        "aoe_radius": 2
      },
      "ability": {
        "name": "Apocalypse",
        "description": "Attacks apply all status effects for 2s",
        "effects": ["slow", "burn", "weaken"]
      },
      "description": "Ultimate siege weapon of mass destruction."
    }
  ]
}
```

### Multi Tower Line

```json
{
  "tower_line": "multi",
  "theme": "Versatility, multiple targets",
  "tiers": [
    {
      "tier": 1,
      "id": "tower_multi",
      "name": "Scout Post",
      "cost": 55,
      "stats": {
        "damage": 1,
        "range": 3,
        "attack_speed": 1.5,
        "targets": 2
      },
      "ability": {
        "name": "Spotter",
        "description": "Reveals enemy HP and word",
        "radius": 4
      },
      "description": "Fast-attacking scout tower."
    },
    {
      "tier": 2,
      "id": "tower_multi_t2",
      "name": "Ranger Outpost",
      "cost": 110,
      "upgrade_from": "tower_multi",
      "stats": {
        "damage": 2,
        "range": 4,
        "attack_speed": 1.8,
        "targets": 3
      },
      "ability": {
        "name": "Mark Target",
        "description": "Marks priority target for +25% damage",
        "duration": 5
      },
      "description": "Rapid-fire tower that marks targets."
    },
    {
      "tier": 3,
      "id": "tower_multi_t3",
      "name": "Fortress",
      "cost": 220,
      "upgrade_from": "tower_multi_t2",
      "stats": {
        "damage": 3,
        "range": 4,
        "attack_speed": 2.0,
        "targets": 5
      },
      "ability": {
        "name": "Overwatch",
        "description": "Attacks all enemies simultaneously in range",
        "note": "Reduced damage per target if >3"
      },
      "description": "Defensive fortress covering all approaches."
    }
  ]
}
```

---

## Special Towers

### Unlockable Towers

| Tower | Unlock Condition | Special Effect |
|-------|------------------|----------------|
| **Void Cannon** | Complete Void Rift | Deals void damage (ignores shields) |
| **Crystal Spire** | Find all crystals | Amplifies nearby towers |
| **Ancient Obelisk** | Complete all lore | Grants random buffs |
| **Champion's Monument** | Win 100 arena matches | Speed buff aura |

### Event Towers

| Tower | Available | Duration | Effect |
|-------|-----------|----------|--------|
| **Harvest Scarecrow** | Autumn event | 7 days | Fear effect on enemies |
| **Frost Beacon** | Winter event | 7 days | Global slow aura |
| **Bloom Tree** | Spring event | 7 days | Regeneration aura |
| **Sun Pillar** | Summer event | 7 days | Speed buff aura |

---

## Tower Placement Strategy

### Placement Bonuses

```json
{
  "placement_bonuses": {
    "adjacent_same_type": {
      "name": "Resonance",
      "effect": "+10% damage per adjacent same-type tower",
      "max_stacks": 3
    },
    "near_path_junction": {
      "name": "Crossfire",
      "effect": "+15% attack speed at path intersections"
    },
    "elevated_position": {
      "name": "High Ground",
      "effect": "+1 range",
      "locations": "marked_on_map"
    },
    "near_water": {
      "name": "Water Source",
      "effect": "Holy towers gain +20% healing",
      "tower_types": ["holy"]
    },
    "near_crystal": {
      "name": "Crystal Power",
      "effect": "Arcane towers gain +25% damage",
      "tower_types": ["arcane"]
    }
  }
}
```

### Tower Synergies

```
┌─────────────────────────────────────────────────────────────┐
│                    TOWER SYNERGIES                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  SLOW + DPS: Holy (slow) + Arrow (damage)                  │
│  → Enemies spend longer in kill zone                        │
│                                                             │
│  DEBUFF + BURST: Arcane (weaken) + Siege (AoE)             │
│  → Massive damage to groups                                 │
│                                                             │
│  MARK + MULTI: Multi (mark) + Any tower                     │
│  → Focus fire on priority targets                           │
│                                                             │
│  STUN CHAIN: Holy T2 + Holy T2 (staggered)                 │
│  → Perma-stun on single target                              │
│                                                             │
│  BURN + SLOW: Siege T2 + Holy                               │
│  → Maximum DoT time                                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Upgrade System

### Upgrade Paths

```
                    Tower Evolution Tree

        [Tier 1]         [Tier 2]           [Tier 3]
           │                │                  │
    Arrow Tower ─────► Longbow Tower ────► Siege Ballista
           │
           └───────────────────────────────► Rapid Fire
                                             (Alt Tier 3)
```

### Alternative Tier 3 Upgrades

```json
{
  "alternative_upgrades": {
    "tower_arrow_t2": {
      "standard": "tower_arrow_t3",
      "alternative": {
        "id": "tower_arrow_t3_rapid",
        "name": "Rapid Fire Tower",
        "cost": 180,
        "stats": {
          "damage": 2,
          "range": 3,
          "attack_speed": 3.0,
          "targets": 2
        },
        "ability": {
          "name": "Suppressing Fire",
          "description": "Attacks slow enemies by 20%",
          "slow_amount": 0.2
        }
      }
    },
    "tower_arcane_t2": {
      "standard": "tower_arcane_t3",
      "alternative": {
        "id": "tower_arcane_t3_support",
        "name": "Enchantment Spire",
        "cost": 200,
        "stats": {
          "damage": 0,
          "range": 4,
          "buff_radius": 3
        },
        "ability": {
          "name": "Empower",
          "description": "All towers in radius deal +30% damage",
          "buff_amount": 0.3
        }
      }
    }
  }
}
```

### Upgrade Costs

| From | To | Gold Cost | Requirements |
|------|-----|-----------|--------------|
| New | T1 | 50-80 | None |
| T1 | T2 | 100-160 | Day 5+ |
| T2 | T3 | 180-320 | Day 15+ |
| T2 | Alt T3 | 150-250 | Special unlock |

---

## Tower UI

### Build Menu

```
┌─────────────────────────────────────────────────────────────┐
│ BUILD TOWER                               Gold: 250        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [Arrow: 50]  [Arcane: 60]  [Holy: 70]                     │
│                                                             │
│  [Siege: 80]  [Multi: 55]   [Locked]                       │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│ Selected: Arrow Tower                                       │
│ Damage: 2  Range: 3  Speed: 1.0/s                          │
│                                                             │
│ "Basic defensive tower. Fires arrows at passing enemies."  │
│                                                             │
│ [Build - 50g]                              [Cancel]         │
└─────────────────────────────────────────────────────────────┘
```

### Upgrade Menu

```
┌─────────────────────────────────────────────────────────────┐
│ UPGRADE: Arrow Tower (Lv1)                Gold: 250        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Current Stats:                                             │
│  Damage: 2  Range: 3  Speed: 1.0/s                         │
│                                                             │
│  ─────────────────────────────────────────────              │
│                                                             │
│  Upgrade to: Longbow Tower                                  │
│  Damage: 4  Range: 4  Speed: 1.2/s                         │
│  + Piercing Shot ability                                    │
│                                                             │
│  Cost: 100 gold                                             │
│                                                             │
│  [Upgrade - 100g]  [Sell - 25g]            [Cancel]         │
└─────────────────────────────────────────────────────────────┘
```

---

## Balance Parameters

### Tower DPS Comparison

| Tower | Tier | Raw DPS | Effective DPS* |
|-------|------|---------|----------------|
| Arrow | T1 | 2.0 | 2.0 |
| Arrow | T2 | 4.8 | 6.0 (pierce) |
| Arrow | T3 | 5.0 | 7.5 (armor break) |
| Arcane | T1 | 0.8 | 1.2 (+mark) |
| Arcane | T2 | 3.0 | 6.0 (chain) |
| Arcane | T3 | 7.2 | 12.0 (explosion) |
| Holy | T1 | 0.6 | 1.0 (+player buff) |
| Holy | T2 | 2.4 | 4.0 (stun value) |
| Holy | T3 | 5.0 | 10.0 (mass stun) |
| Siege | T1 | 1.5 | 4.5 (AoE 3 targets) |
| Siege | T2 | 2.5 | 10.0 (AoE + DoT) |
| Siege | T3 | 4.0 | 20.0 (full potential) |
| Multi | T1 | 3.0 | 3.0 |
| Multi | T2 | 10.8 | 12.0 (+mark) |
| Multi | T3 | 30.0 | 20.0 (diminishing) |

*Effective DPS includes abilities and typical combat conditions

---

## Implementation Checklist

- [ ] Create tower data files
- [ ] Implement tower placement system
- [ ] Build upgrade UI
- [ ] Add tower attack logic
- [ ] Implement abilities per tower
- [ ] Create placement bonus detection
- [ ] Add synergy calculations
- [ ] Build sell/refund system
- [ ] Create tower animations
- [ ] Add tower sound effects
- [ ] Balance damage/cost ratios
- [ ] Implement special tower unlocks

---

## References

- `sim/types.gd` - Building definitions
- `sim/world_tick.gd` - Tower attack simulation
- `game/grid_renderer.gd` - Tower rendering
- `assets/art/src-svg/buildings/` - Tower sprites
- `docs/plans/p1/ENEMY_COMBAT_DESIGN.md` - Enemy reference
