# Quest & Side Content System

**Created:** 2026-01-08

Complete specification for quests, side activities, and repeatable content in Keystonia.

---

## Content Categories

```
┌─────────────────────────────────────────────────────────────┐
│                    CONTENT HIERARCHY                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  MAIN STORY (Required)                                      │
│  └── Story Chapters → Boss Encounters → Finale             │
│                                                             │
│  SIDE QUESTS (Optional)                                     │
│  └── Regional Chains → Standalone → Hidden                 │
│                                                             │
│  DAILY CONTENT (Repeatable)                                 │
│  └── Challenges → Bounties → Training                      │
│                                                             │
│  COLLECTIONS (Completionist)                                │
│  └── Lore Pages → Achievements → Titles                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Main Story Quests

### Story Structure

**Act 1: Awakening (Days 1-10)**
- Introduction to Castle Keystonia
- Meet Elder Lyra
- Learn home row fundamentals
- First Typhos attack
- Discover the threat

**Act 2: Journey (Days 11-30)**
- Explore the Verdant Heartland
- Meet regional allies
- Unlock reach row and bottom row
- Defeat regional bosses
- Learn the prophecy

**Act 3: Mastery (Days 31-50)**
- Enter the Central Kingdom
- Face elemental challenges
- Master all keyboard rows
- Uncover Void Tyrant's origin
- Prepare for final battle

**Act 4: Confrontation (Days 51+)**
- Enter the Outer Frontier
- Complete Legendary Trials
- Storm the Void Rift
- Defeat the Void Tyrant
- True ending conditions

---

### Main Quest Schema

```json
{
  "quest_id": "mq_01_awakening",
  "chapter": 1,
  "name": "The First Keystroke",
  "description": "Elder Lyra senses a new champion. Begin your journey.",
  "prerequisites": [],
  "objectives": [
    {
      "id": "obj_01",
      "type": "dialogue",
      "target": "npc_lyra",
      "description": "Speak with Elder Lyra"
    },
    {
      "id": "obj_02",
      "type": "lesson_complete",
      "target": "home_row_1",
      "description": "Complete Home Row Lesson 1"
    },
    {
      "id": "obj_03",
      "type": "battle_win",
      "count": 3,
      "description": "Defend the castle (3 waves)"
    }
  ],
  "rewards": {
    "gold": 50,
    "items": ["starter_scroll"],
    "unlock": ["zone_evergrove_entrance"]
  },
  "story_dialogue": {
    "intro": "lyra_mq01_intro",
    "complete": "lyra_mq01_complete"
  },
  "next_quest": "mq_02_forest_gate"
}
```

---

### Main Quest List

#### Act 1: Awakening

| Quest ID | Name | Objectives | Unlock |
|----------|------|------------|--------|
| mq_01 | The First Keystroke | Meet Lyra, complete home row 1, defend castle | Evergrove access |
| mq_02 | Forest Gate | Travel to Evergrove, meet Ranger Thorne | Forest exploration |
| mq_03 | Grove Initiation | Complete 3 forest lessons, find the shrine | Shrine blessing |
| mq_04 | The Gathering Storm | First major Typhos wave, defend Evergrove | Story revelation |
| mq_05 | Elder's Warning | Return to Lyra, learn the prophecy | Act 2 |

#### Act 2: Journey

| Quest ID | Name | Objectives | Unlock |
|----------|------|------------|--------|
| mq_06 | Sunlit Path | Enter Sunfields, meet Champion Vera | Arena access |
| mq_07 | Champion's Trial | Win 5 arena matches | Speed training |
| mq_08 | Mountain Calling | Enter Stonepass, meet Elder Grimstone | Mine access |
| mq_09 | Crystal Heart | Find the Heart Crystal, escape cave-in | Crystal abilities |
| mq_10 | Into the Mist | Enter Mistfen, survive the fog | Hermit contact |
| mq_11 | Hermit's Wisdom | Complete the Hermit's test | Hidden lore |
| mq_12 | Return to Light | Reach the Citadel | Citadel access |
| mq_13 | Royal Audience | Meet King Aldric, receive mission | Kingdom quests |
| mq_14 | The Four Seals | Defeat all regional bosses | Realm keys |
| mq_15 | Realm Attunement | Enter first elemental realm | Act 3 |

#### Act 3: Mastery

| Quest ID | Name | Objectives | Unlock |
|----------|------|------------|--------|
| mq_16 | Trial by Fire | Complete Fire Realm, defeat Flame Tyrant | Fire mastery |
| mq_17 | Frozen Precision | Complete Ice Realm, defeat Frost Empress | Ice mastery |
| mq_18 | Nature's Balance | Complete Nature Realm, defeat Ancient Treant | Balance mastery |
| mq_19 | The Truth Revealed | Learn Void Tyrant's origin | Story climax |
| mq_20 | Final Preparations | Complete all Legendary Trials | Act 4 |

#### Act 4: Confrontation

| Quest ID | Name | Objectives | Unlock |
|----------|------|------------|--------|
| mq_21 | Edge of the Void | Enter Void Rift, survive approach | Void Tyrant access |
| mq_22 | Silence Falls | Void Tyrant Phase 1-2 | Phase 3 |
| mq_23 | Words of Power | Void Tyrant Phase 3-4 | Ending |
| mq_24 | The Last Keystroke | Defeat Void Tyrant, restore Keystonia | True ending |

---

## Side Quest System

### Quest Categories

| Category | Count | Requirements | Rewards |
|----------|-------|--------------|---------|
| **Regional Chains** | 5 chains, 4 quests each | Region access | Unique items, lore |
| **Standalone** | 30+ quests | Various | Gold, items |
| **Hidden** | 10 quests | Discovery | Secret rewards |
| **Repeatable** | 15 types | Daily reset | Resources |

---

### Regional Quest Chains

#### Evergrove: The Spirit's Blessing

```json
{
  "chain_id": "rc_evergrove",
  "name": "The Spirit's Blessing",
  "quests": [
    {
      "id": "rc_ev_01",
      "name": "Whispers in the Woods",
      "description": "Strange lights appear in the forest at night.",
      "objectives": [
        {"type": "poi_visit", "target": "ancient_oak", "time": "night"},
        {"type": "typing_challenge", "accuracy": 0.85, "words": 15}
      ],
      "rewards": {"gold": 30, "item": "spirit_shard"}
    },
    {
      "id": "rc_ev_02",
      "name": "The Old Language",
      "description": "The Forest Spirit speaks in ancient words.",
      "objectives": [
        {"type": "collect", "target": "lore_fragment", "count": 5},
        {"type": "lesson_complete", "target": "ancient_words"}
      ],
      "rewards": {"gold": 50, "skill": "nature_tongue"}
    },
    {
      "id": "rc_ev_03",
      "name": "Corruption Creeps",
      "description": "Void corruption threatens the grove.",
      "objectives": [
        {"type": "battle_win", "enemy_type": "corrupted", "count": 10},
        {"type": "poi_cleanse", "target": "corrupted_grove"}
      ],
      "rewards": {"gold": 75, "item": "purified_essence"}
    },
    {
      "id": "rc_ev_04",
      "name": "The Spirit's Gift",
      "description": "Prove yourself worthy of the Spirit's blessing.",
      "objectives": [
        {"type": "typing_challenge", "type": "consistency", "target": 0.90, "words": 25},
        {"type": "dialogue", "target": "forest_spirit"}
      ],
      "rewards": {"gold": 100, "title": "Spirit Friend", "buff": "forest_blessing_permanent"}
    }
  ]
}
```

#### Sunfields: Champion's Path

| Quest | Name | Objective | Reward |
|-------|------|-----------|--------|
| rc_sf_01 | Arena Novice | Win first arena match | Arena access |
| rc_sf_02 | Rising Star | Reach 5-win streak | Champion recognition |
| rc_sf_03 | The Rival | Defeat Swift Sarah | Speed technique |
| rc_sf_04 | True Champion | Win the tournament | Champion's Crown |

#### Stonepass: Dwarf's Legacy

| Quest | Name | Objective | Reward |
|-------|------|-----------|--------|
| rc_sp_01 | Old Records | Find mining records | Map to secret vein |
| rc_sp_02 | Crystal Calling | Extract rare crystals | Crystal tools |
| rc_sp_03 | Cave Secrets | Explore ancient tunnels | Dwarf lore |
| rc_sp_04 | Forge Master | Complete forging trial | Legendary weapon |

#### Mistfen: Hermit's Secrets

| Quest | Name | Objective | Reward |
|-------|------|-----------|--------|
| rc_mf_01 | Fog Walker | Navigate the marsh | Fog immunity potion |
| rc_mf_02 | Old Potions | Gather rare ingredients | Hermit's trust |
| rc_mf_03 | Dark Past | Learn the Hermit's history | Secret technique |
| rc_mf_04 | True Wisdom | Pass the final test | Hermit's Blessing |

#### Citadel: Order of Scribes

| Quest | Name | Objective | Reward |
|-------|------|-----------|--------|
| rc_ct_01 | Initiate's Trial | Join the Order | Scribe rank |
| rc_ct_02 | Archive Duty | Catalog ancient texts | Rare scrolls |
| rc_ct_03 | Lost Manuscripts | Recover stolen texts | Historical lore |
| rc_ct_04 | Illuminator | Achieve master rank | Eternal Scribe title |

---

### Standalone Side Quests

#### Discovery Quests

```json
{
  "quests": [
    {
      "id": "sq_treasure_hunt",
      "name": "The Merchant's Map",
      "trigger": "purchase_map_from_marco",
      "description": "Marco sold you an old treasure map...",
      "objectives": [
        {"type": "poi_visit", "targets": ["x_marks_spot_1", "x_marks_spot_2", "x_marks_spot_3"]},
        {"type": "typing_challenge", "type": "speed", "target_wpm": 35}
      ],
      "rewards": {"gold": 200, "item": "ancient_treasure"}
    },
    {
      "id": "sq_lost_explorer",
      "name": "Lost in the Woods",
      "trigger": "find_wounded_explorer",
      "description": "An explorer needs help finding their way back.",
      "objectives": [
        {"type": "escort", "target": "npc_lost_explorer", "destination": "evergrove_village"},
        {"type": "battle_win", "count": 2}
      ],
      "rewards": {"gold": 50, "item": "explorer_compass"}
    }
  ]
}
```

#### Combat Quests

| Quest | Trigger | Objective | Reward |
|-------|---------|-----------|--------|
| Monster Slayer | Kill 50 enemies | Kill 100 more | Monster Hunter title |
| Typhos Bane | Defeat first boss | Defeat all bosses | Bane of Typhos |
| Perfectionist | 95% accuracy battle | 10 perfect battles | Precision Ring |
| Speed Demon | 50 WPM battle | 60 WPM battle | Speed Boots |

#### Collection Quests

| Quest | Requirement | Reward |
|-------|-------------|--------|
| Herbalist | Collect all herb types | Herbalist's Pouch |
| Geologist | Collect all gem types | Gem Detector |
| Archivist | Collect 50 lore pages | Archive Access |
| Completionist | 100% POI discovery | World Map |

---

### Hidden Quests

Hidden quests have no journal entry until discovered.

```json
{
  "hidden_quests": [
    {
      "id": "hq_secret_shrine",
      "name": "???",
      "reveal_name": "The Forgotten Shrine",
      "trigger": "type_ancient_phrase_at_shrine",
      "phrase": "qwerty forever",
      "reward": "ancient_keyboard_fragment"
    },
    {
      "id": "hq_ghost_typist",
      "name": "???",
      "reveal_name": "The Ghost in the Machine",
      "trigger": "visit_graveyard_at_midnight_with_full_accuracy",
      "reward": "ghost_typist_companion"
    },
    {
      "id": "hq_perfect_run",
      "name": "???",
      "reveal_name": "Flawless Victory",
      "trigger": "complete_any_region_100_accuracy_no_damage",
      "reward": "perfect_title_and_crown"
    }
  ]
}
```

---

## Daily Content System

### Daily Challenges

```json
{
  "daily_challenges": {
    "reset_time": "00:00 UTC",
    "slots": 3,
    "challenge_pool": [
      {
        "id": "daily_speed",
        "name": "Speed Run",
        "description": "Achieve 40 WPM in 5 battles",
        "objective": {"type": "wpm_threshold", "target": 40, "battles": 5},
        "rewards": {"gold": 30, "word_tokens": 5}
      },
      {
        "id": "daily_accuracy",
        "name": "Precision Focus",
        "description": "Maintain 95% accuracy across 10 battles",
        "objective": {"type": "accuracy_threshold", "target": 0.95, "battles": 10},
        "rewards": {"gold": 30, "word_tokens": 5}
      },
      {
        "id": "daily_streak",
        "name": "Winning Streak",
        "description": "Win 7 battles in a row",
        "objective": {"type": "win_streak", "count": 7},
        "rewards": {"gold": 50, "word_tokens": 10}
      },
      {
        "id": "daily_explorer",
        "name": "Explorer's Path",
        "description": "Visit 10 different POIs",
        "objective": {"type": "poi_visit", "count": 10},
        "rewards": {"gold": 25, "item": "random_common"}
      },
      {
        "id": "daily_lesson",
        "name": "Eternal Student",
        "description": "Complete 3 lessons with 3 stars",
        "objective": {"type": "lesson_stars", "count": 3, "stars": 3},
        "rewards": {"gold": 40, "word_tokens": 8}
      }
    ]
  }
}
```

### Weekly Challenges

```json
{
  "weekly_challenges": {
    "reset_day": "Monday",
    "slots": 2,
    "challenge_pool": [
      {
        "id": "weekly_master",
        "name": "Weekly Master",
        "description": "Achieve mastery in 5 lessons",
        "objective": {"type": "lesson_mastery", "count": 5},
        "rewards": {"gold": 200, "word_tokens": 50, "item": "rare_random"}
      },
      {
        "id": "weekly_boss",
        "name": "Boss Slayer",
        "description": "Defeat any boss 3 times",
        "objective": {"type": "boss_defeat", "count": 3},
        "rewards": {"gold": 150, "word_tokens": 40}
      },
      {
        "id": "weekly_perfectionist",
        "name": "Weekly Perfectionist",
        "description": "Achieve 100% accuracy in 5 battles",
        "objective": {"type": "perfect_battles", "count": 5},
        "rewards": {"gold": 250, "title": "Weekly Champion"}
      }
    ]
  }
}
```

### Bounty Board

```json
{
  "bounty_system": {
    "refresh": "every_3_hours",
    "max_active": 5,
    "bounty_types": [
      {
        "type": "enemy_hunt",
        "name_pattern": "Hunt: [enemy_type]",
        "description": "Defeat X [enemy_type] enemies",
        "reward_scale": "enemy_difficulty * count * 2"
      },
      {
        "type": "region_clear",
        "name_pattern": "Patrol: [region]",
        "description": "Complete X battles in [region]",
        "reward_scale": "region_level * count"
      },
      {
        "type": "special_condition",
        "name_pattern": "Challenge: [condition]",
        "description": "Win X battles with [condition]",
        "conditions": ["no_backspace", "speed_only", "accuracy_only"],
        "reward_scale": "difficulty * 3"
      }
    ]
  }
}
```

---

## Collection Systems

### Lore Collection

```
┌─────────────────────────────────────────────────────────────┐
│                    LORE COLLECTION                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Creation Myths ████████░░ 8/10                            │
│  Letter Spirits ██████░░░░ 6/10                            │
│  Kingdom History █████████░ 9/15                           │
│  Great Typists ████░░░░░░ 4/10                             │
│  The Silence ███░░░░░░░ 3/10                               │
│  Prophecies █████░░░░░ 5/5 ✓                               │
│  Secrets ██░░░░░░░░ 2/10                                   │
│  Elder Lyra ███████░░░ 7/10                                │
│                                                             │
│  Total: 44/80 (55%)                                        │
│                                                             │
│  [Rewards unlock at 25%, 50%, 75%, 100%]                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Lore Rewards:**
- 25%: Lorekeeper title, +10% lore drop rate
- 50%: Ancient Tome item, bonus dialogue options
- 75%: Secret areas revealed, Elder Lyra's history
- 100%: True Archivist title, hidden ending content

### Achievement System

```json
{
  "achievement_categories": {
    "combat": {
      "name": "Combat",
      "achievements": [
        {"id": "first_blood", "name": "First Blood", "description": "Defeat your first enemy", "reward": 10},
        {"id": "century", "name": "Century", "description": "Defeat 100 enemies", "reward": 50},
        {"id": "thousand", "name": "Thousand Foes", "description": "Defeat 1000 enemies", "reward": 200},
        {"id": "boss_slayer", "name": "Boss Slayer", "description": "Defeat all regional bosses", "reward": 100},
        {"id": "void_victor", "name": "Void Victor", "description": "Defeat the Void Tyrant", "reward": 500}
      ]
    },
    "typing": {
      "name": "Typing Mastery",
      "achievements": [
        {"id": "home_row_master", "name": "Home Row Master", "description": "Master all home row lessons", "reward": 30},
        {"id": "full_keyboard", "name": "Full Keyboard", "description": "Master all basic lessons", "reward": 100},
        {"id": "speed_50", "name": "50 WPM Club", "description": "Achieve 50 WPM", "reward": 50},
        {"id": "speed_80", "name": "80 WPM Elite", "description": "Achieve 80 WPM", "reward": 150},
        {"id": "speed_100", "name": "Triple Digits", "description": "Achieve 100 WPM", "reward": 300},
        {"id": "perfect_100", "name": "Centurion", "description": "100 battles with 100% accuracy", "reward": 200}
      ]
    },
    "exploration": {
      "name": "Exploration",
      "achievements": [
        {"id": "first_steps", "name": "First Steps", "description": "Leave Castle Keystonia", "reward": 5},
        {"id": "wanderer", "name": "Wanderer", "description": "Visit 50 POIs", "reward": 50},
        {"id": "cartographer", "name": "Cartographer", "description": "Visit all POIs", "reward": 200},
        {"id": "secret_finder", "name": "Secret Finder", "description": "Find 5 hidden locations", "reward": 75}
      ]
    },
    "collection": {
      "name": "Collection",
      "achievements": [
        {"id": "lore_novice", "name": "Lore Novice", "description": "Collect 20 lore pages", "reward": 30},
        {"id": "lore_expert", "name": "Lore Expert", "description": "Collect all lore pages", "reward": 200},
        {"id": "fashionista", "name": "Fashionista", "description": "Unlock 10 titles", "reward": 50},
        {"id": "completionist", "name": "Completionist", "description": "100% completion", "reward": 1000}
      ]
    }
  }
}
```

### Title System

```json
{
  "titles": {
    "combat": [
      {"id": "novice_typist", "name": "Novice Typist", "unlock": "Start game"},
      {"id": "defender", "name": "Defender", "unlock": "Win 10 battles"},
      {"id": "champion", "name": "Champion", "unlock": "Win 100 battles"},
      {"id": "legend", "name": "Legend", "unlock": "Win 1000 battles"},
      {"id": "void_slayer", "name": "Void Slayer", "unlock": "Defeat Void Tyrant"}
    ],
    "typing": [
      {"id": "speed_demon", "name": "Speed Demon", "unlock": "80+ WPM"},
      {"id": "precision_master", "name": "Precision Master", "unlock": "100 perfect battles"},
      {"id": "balanced_sage", "name": "Balanced Sage", "unlock": "60 WPM + 95% accuracy consistently"}
    ],
    "exploration": [
      {"id": "explorer", "name": "Explorer", "unlock": "Visit all regions"},
      {"id": "realm_walker", "name": "Realm Walker", "unlock": "Complete all elemental realms"}
    ],
    "special": [
      {"id": "spirit_friend", "name": "Spirit Friend", "unlock": "Evergrove quest chain"},
      {"id": "arena_champion", "name": "Arena Champion", "unlock": "Win tournament"},
      {"id": "true_typist", "name": "True Typist", "unlock": "True ending"}
    ],
    "hidden": [
      {"id": "ghost_whisperer", "name": "Ghost Whisperer", "unlock": "Hidden quest"},
      {"id": "perfect_one", "name": "The Perfect One", "unlock": "Flawless region clear"}
    ]
  }
}
```

---

## Repeatable Content

### Training Modes

```json
{
  "training_modes": {
    "free_practice": {
      "name": "Free Practice",
      "description": "Practice any lesson without time pressure",
      "rewards": "None (practice only)",
      "unlocked": "Always"
    },
    "time_attack": {
      "name": "Time Attack",
      "description": "Type as many words as possible in 60 seconds",
      "rewards": {"gold": "words_typed", "leaderboard": true},
      "unlocked": "Complete Act 1"
    },
    "survival": {
      "name": "Survival",
      "description": "Endless waves of increasing difficulty",
      "rewards": {"gold": "wave_reached * 10", "leaderboard": true},
      "unlocked": "Complete Act 2"
    },
    "accuracy_drill": {
      "name": "Accuracy Drill",
      "description": "100 words, aim for perfect accuracy",
      "rewards": {"gold": "accuracy_percentage", "word_tokens": "if_95_plus"},
      "unlocked": "Complete 10 lessons"
    }
  }
}
```

### Arena Modes

```json
{
  "arena_modes": {
    "quick_match": {
      "name": "Quick Match",
      "description": "Single opponent, random difficulty",
      "rewards": {"gold": 20, "chance": "arena_token"},
      "cooldown": "None"
    },
    "championship": {
      "name": "Championship",
      "description": "5-match tournament bracket",
      "rewards": {"gold": 100, "item": "champion_prize"},
      "cooldown": "24 hours"
    },
    "gauntlet": {
      "name": "Gauntlet",
      "description": "10 opponents, no healing between",
      "rewards": {"gold": 200, "title": "Gauntlet Survivor"},
      "cooldown": "Weekly"
    }
  }
}
```

### Procedural Dungeons

```json
{
  "dungeon_system": {
    "name": "The Depths",
    "description": "Procedurally generated typing challenges",
    "floors": "Infinite (scaling difficulty)",
    "generation": {
      "room_types": ["battle", "treasure", "trap", "rest", "shop", "boss"],
      "floor_length": "5-7 rooms",
      "boss_every": 5,
      "difficulty_scale": "floor * 0.1"
    },
    "rewards": {
      "per_floor": {"gold": "floor * 20"},
      "milestone_10": {"item": "dungeon_chest"},
      "milestone_25": {"title": "Depth Delver"},
      "milestone_50": {"item": "legendary_random"}
    },
    "unlock": "Complete all regional bosses"
  }
}
```

---

## Quest UI Requirements

### Quest Journal

```
┌─────────────────────────────────────────────────────────────┐
│ QUEST JOURNAL                              [X Close]        │
├─────────────────────────────────────────────────────────────┤
│ [Main] [Side] [Daily] [Completed] [Hidden: ???]            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ ★ ACTIVE: The Four Seals (Main Quest)                      │
│   "Defeat the guardians of each region to obtain           │
│    the keys to the elemental realms."                      │
│                                                             │
│   Objectives:                                               │
│   ✓ Defeat Grove Guardian (Evergrove)                      │
│   ✓ Defeat Sunlord Champion (Sunfields)                    │
│   □ Defeat Citadel Warden (Stonepass)                      │
│   □ Defeat Fen Seer (Mistfen)                              │
│                                                             │
│   Rewards: 4 Realm Keys, 500 Gold, Title: Seal Breaker     │
│                                                             │
│   [Track] [Abandon]                                         │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│ Other Active Quests:                                        │
│ • The Spirit's Blessing (3/4) - Evergrove                  │
│ • Daily: Speed Run (2/5) - 4h remaining                    │
│ • Bounty: Hunt Typhos (7/10) - 2h remaining                │
└─────────────────────────────────────────────────────────────┘
```

### Quest Tracking

```json
{
  "tracking_features": {
    "map_markers": "Show objectives on world map",
    "compass_indicator": "Point to nearest objective",
    "progress_popup": "Show progress on objective completion",
    "reminder": "Notify when daily resets",
    "max_tracked": 3
  }
}
```

---

## Implementation Checklist

- [ ] Create main quest data files
- [ ] Implement quest objective handlers
- [ ] Build side quest chains per region
- [ ] Add daily/weekly challenge rotation
- [ ] Create bounty board system
- [ ] Implement lore collection tracking
- [ ] Build achievement system
- [ ] Create title unlock system
- [ ] Add procedural dungeon generator
- [ ] Build quest journal UI
- [ ] Add map quest markers
- [ ] Implement quest rewards distribution
- [ ] Save/load quest progress

---

## References

- `docs/plans/p1/WORLD_EXPANSION_PLAN.md` - World structure
- `docs/plans/p1/REGION_SPECIFICATIONS.md` - Region details
- `docs/plans/p1/NPC_CHARACTER_ROSTER.md` - Quest-giving NPCs
- `docs/plans/p1/POI_EVENT_SYSTEM.md` - POI integration
- `docs/plans/p1/WORLD_LORE_HISTORY.md` - Story content
- `data/story.json` - Dialogue data
- `game/story_manager.gd` - Story system
