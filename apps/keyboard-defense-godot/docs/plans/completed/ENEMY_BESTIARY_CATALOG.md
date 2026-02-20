# Enemy Bestiary - Complete Catalog

**Created:** 2026-01-08

Full catalog of all enemies, stats, behaviors, and regional variants.

---

## Tier 1: Minions

### Core Minions

#### Typhos Spawn
```json
{
  "id": "typhos_spawn",
  "name": "Typhos Spawn",
  "tier": 1,
  "category": "minion",
  "description": "The most basic manifestation of void corruption. Born from abandoned keyboards and forgotten words.",
  "lore": "When a typist gives up mid-word, the unfinished intention coalesces into a Typhos Spawn - mindless, hungry, and drawn to the sound of typing.",
  "stats": {
    "hp": 3,
    "speed": 1.2,
    "damage_to_castle": 1,
    "word_length_min": 3,
    "word_length_max": 4,
    "xp_reward": 5,
    "gold_reward": 2
  },
  "appearance": {
    "base_color": "#4A0E4E",
    "glow_color": "#8B5CF6",
    "size": "small",
    "sprite": "enemies/typhos_spawn.svg",
    "animations": ["idle_float", "move_wobble", "attack_lunge", "death_dissolve"]
  },
  "behavior": {
    "type": "direct_advance",
    "ai_notes": "Moves directly toward castle, no special behaviors",
    "targeting_priority": 0
  },
  "sound": {
    "spawn": "sfx/enemies/spawn_small.wav",
    "move": "sfx/enemies/float_whisper.wav",
    "attack": "sfx/enemies/attack_weak.wav",
    "death": "sfx/enemies/death_poof_small.wav"
  },
  "spawn_conditions": {
    "min_day": 1,
    "regions": ["all"],
    "wave_position": "front"
  }
}
```

#### Void Wisp
```json
{
  "id": "void_wisp",
  "name": "Void Wisp",
  "tier": 1,
  "category": "minion",
  "description": "A flickering fragment of void energy that phases in and out of visibility.",
  "lore": "Wisps are the tears of the Void itself, drawn to realms of meaning like moths to flame. They seek to extinguish the light of typed words.",
  "stats": {
    "hp": 2,
    "speed": 1.5,
    "damage_to_castle": 1,
    "word_length_min": 3,
    "word_length_max": 3,
    "xp_reward": 6,
    "gold_reward": 2
  },
  "appearance": {
    "base_color": "#1E1B4B",
    "glow_color": "#A78BFA",
    "size": "tiny",
    "sprite": "enemies/void_wisp.svg",
    "animations": ["idle_flicker", "move_drift", "attack_flash", "death_fade"],
    "special_effect": "transparency_pulse"
  },
  "behavior": {
    "type": "erratic_path",
    "ai_notes": "Moves in zigzag pattern, harder to track",
    "path_deviation": 1.5,
    "targeting_priority": -1
  },
  "special_ability": {
    "name": "Flicker",
    "description": "Periodically becomes semi-transparent (50% opacity)",
    "interval": 3.0,
    "duration": 1.0,
    "effect": "Word text also flickers"
  },
  "spawn_conditions": {
    "min_day": 2,
    "regions": ["all"],
    "wave_position": "scattered"
  }
}
```

#### Shadow Rat
```json
{
  "id": "shadow_rat",
  "name": "Shadow Rat",
  "tier": 1,
  "category": "minion",
  "description": "Small, fast creatures that swarm in packs, overwhelming defenses through numbers.",
  "lore": "Shadow Rats nest in the spaces between letters, gnawing at the foundations of words. Where one appears, more always follow.",
  "stats": {
    "hp": 2,
    "speed": 1.3,
    "damage_to_castle": 1,
    "word_length_min": 3,
    "word_length_max": 4,
    "xp_reward": 4,
    "gold_reward": 1
  },
  "appearance": {
    "base_color": "#1F2937",
    "glow_color": "#6B7280",
    "size": "tiny",
    "sprite": "enemies/shadow_rat.svg",
    "animations": ["idle_twitch", "move_scurry", "attack_bite", "death_squeak"]
  },
  "behavior": {
    "type": "swarm",
    "ai_notes": "Always spawns in groups of 3, stays close to pack",
    "pack_size": 3,
    "pack_spread": 0.5,
    "targeting_priority": 1
  },
  "special_ability": {
    "name": "Pack Tactics",
    "description": "Gains +0.1 speed for each nearby Shadow Rat",
    "radius": 2,
    "max_bonus": 0.3
  },
  "spawn_conditions": {
    "min_day": 1,
    "regions": ["all"],
    "wave_position": "pack",
    "spawn_count": 3
  }
}
```

#### Ink Blob
```json
{
  "id": "ink_blob",
  "name": "Ink Blob",
  "tier": 1,
  "category": "minion",
  "description": "A slow-moving mass of corrupted ink that leaves a trail of smudged letters.",
  "lore": "Born from spilled ink and failed writing, Ink Blobs absorb words they touch, growing slightly larger with each feeding.",
  "stats": {
    "hp": 4,
    "speed": 0.8,
    "damage_to_castle": 2,
    "word_length_min": 3,
    "word_length_max": 4,
    "xp_reward": 7,
    "gold_reward": 3
  },
  "appearance": {
    "base_color": "#0F172A",
    "glow_color": "#334155",
    "size": "small",
    "sprite": "enemies/ink_blob.svg",
    "animations": ["idle_wobble", "move_ooze", "attack_splash", "death_splatter"],
    "leaves_trail": true,
    "trail_effect": "ink_smudge"
  },
  "behavior": {
    "type": "direct_advance",
    "ai_notes": "Slow but tanky for tier 1",
    "targeting_priority": 2
  },
  "special_ability": {
    "name": "Ink Trail",
    "description": "Leaves temporary terrain that reduces tower accuracy by 10%",
    "trail_duration": 5.0,
    "trail_width": 0.5
  },
  "spawn_conditions": {
    "min_day": 3,
    "regions": ["evergrove", "mistfen"],
    "wave_position": "back"
  }
}
```

#### Glitch Sprite
```json
{
  "id": "glitch_sprite",
  "name": "Glitch Sprite",
  "tier": 1,
  "category": "minion",
  "description": "A corrupted data fragment that occasionally scrambles nearby text.",
  "lore": "Glitch Sprites are errors made manifest - the ghosts of typos and corrupted files that somehow gained sentience.",
  "stats": {
    "hp": 2,
    "speed": 1.1,
    "damage_to_castle": 1,
    "word_length_min": 3,
    "word_length_max": 4,
    "xp_reward": 8,
    "gold_reward": 3
  },
  "appearance": {
    "base_color": "#22C55E",
    "glow_color": "#4ADE80",
    "size": "tiny",
    "sprite": "enemies/glitch_sprite.svg",
    "animations": ["idle_static", "move_teleport_micro", "attack_zap", "death_crash"],
    "visual_effect": "scanline_distortion"
  },
  "behavior": {
    "type": "direct_advance",
    "ai_notes": "Normal movement with occasional micro-teleports",
    "micro_teleport_chance": 0.1,
    "micro_teleport_distance": 0.3,
    "targeting_priority": 3
  },
  "special_ability": {
    "name": "Static Interference",
    "description": "On death, scrambles one letter of a random nearby enemy's word",
    "radius": 2,
    "probability": 0.5
  },
  "spawn_conditions": {
    "min_day": 4,
    "regions": ["citadel", "void_rift"],
    "wave_position": "scattered"
  }
}
```

---

## Tier 2: Soldiers

### Core Soldiers

#### Typhos Scout
```json
{
  "id": "typhos_scout",
  "name": "Typhos Scout",
  "tier": 2,
  "category": "soldier",
  "description": "A more developed Typhos creature, capable of tactical movement and basic combat.",
  "lore": "Scouts form the backbone of the Typhos Horde, their simple minds sharpened by countless battles against typists.",
  "stats": {
    "hp": 5,
    "armor": 0,
    "speed": 1.0,
    "damage_to_castle": 2,
    "word_length_min": 4,
    "word_length_max": 5,
    "xp_reward": 12,
    "gold_reward": 5
  },
  "appearance": {
    "base_color": "#581C87",
    "glow_color": "#A855F7",
    "size": "medium",
    "sprite": "enemies/typhos_scout.svg",
    "animations": ["idle_alert", "move_march", "attack_slash", "death_collapse"]
  },
  "behavior": {
    "type": "direct_advance",
    "ai_notes": "Standard soldier behavior",
    "targeting_priority": 5
  },
  "spawn_conditions": {
    "min_day": 3,
    "regions": ["all"],
    "wave_position": "middle"
  }
}
```

#### Corrupted Archer
```json
{
  "id": "corrupted_archer",
  "name": "Corrupted Archer",
  "tier": 2,
  "category": "soldier",
  "description": "A ranged attacker that stops to fire volleys of void-tipped arrows.",
  "lore": "Once proud rangers of Keystonia's forests, these corrupted souls now serve the Void, their arrows carrying whispers of silence.",
  "stats": {
    "hp": 4,
    "armor": 0,
    "speed": 0.8,
    "damage_to_castle": 1,
    "word_length_min": 5,
    "word_length_max": 6,
    "xp_reward": 15,
    "gold_reward": 6
  },
  "appearance": {
    "base_color": "#365314",
    "glow_color": "#84CC16",
    "corruption_overlay": "#581C87",
    "size": "medium",
    "sprite": "enemies/corrupted_archer.svg",
    "animations": ["idle_aim", "move_stalk", "attack_shoot", "death_fall"]
  },
  "behavior": {
    "type": "stop_and_attack",
    "ai_notes": "Advances to range 3, then stops to attack towers",
    "attack_range": 3,
    "attack_target": "towers",
    "targeting_priority": 8
  },
  "special_ability": {
    "name": "Void Arrow",
    "description": "Ranged attack that deals 2 damage to towers",
    "damage": 2,
    "range": 3,
    "cooldown": 5.0,
    "projectile_speed": 5
  },
  "spawn_conditions": {
    "min_day": 5,
    "regions": ["evergrove", "sunfields"],
    "wave_position": "back"
  }
}
```

#### Void Hound
```json
{
  "id": "void_hound",
  "name": "Void Hound",
  "tier": 2,
  "category": "soldier",
  "description": "A fast, aggressive hunter that accelerates when wounded.",
  "lore": "Void Hounds are hunting beasts bred in the Rift, their hunger for typed words driving them to frenzy when they sense weakness.",
  "stats": {
    "hp": 6,
    "armor": 0,
    "speed": 1.4,
    "damage_to_castle": 3,
    "word_length_min": 4,
    "word_length_max": 5,
    "xp_reward": 14,
    "gold_reward": 6
  },
  "appearance": {
    "base_color": "#1E1B4B",
    "glow_color": "#7C3AED",
    "size": "medium",
    "sprite": "enemies/void_hound.svg",
    "animations": ["idle_prowl", "move_lope", "attack_pounce", "death_howl"]
  },
  "behavior": {
    "type": "charge_attack",
    "ai_notes": "Fast attacker, gets faster when damaged",
    "targeting_priority": 9
  },
  "special_ability": {
    "name": "Blood Frenzy",
    "description": "Gains +0.2 speed for each HP lost",
    "trigger": "on_damage",
    "speed_per_hp_lost": 0.2,
    "max_bonus": 1.0,
    "visual": "red_glow_intensify"
  },
  "spawn_conditions": {
    "min_day": 5,
    "regions": ["all"],
    "wave_position": "front"
  }
}
```

#### Silence Acolyte
```json
{
  "id": "silence_acolyte",
  "name": "Silence Acolyte",
  "tier": 2,
  "category": "soldier",
  "description": "A devoted follower of the Void Tyrant who channels anti-typing magic.",
  "lore": "Acolytes were once typists who embraced the silence. They now spread their dark gospel, seeking to convert others to wordlessness.",
  "stats": {
    "hp": 4,
    "armor": 0,
    "speed": 0.9,
    "damage_to_castle": 2,
    "word_length_min": 5,
    "word_length_max": 6,
    "xp_reward": 16,
    "gold_reward": 7
  },
  "appearance": {
    "base_color": "#1F2937",
    "glow_color": "#9CA3AF",
    "size": "medium",
    "sprite": "enemies/silence_acolyte.svg",
    "animations": ["idle_meditate", "move_glide", "attack_curse", "death_whisper"],
    "held_item": "void_tome"
  },
  "behavior": {
    "type": "support_caster",
    "ai_notes": "Stays behind other enemies, casts debuffs",
    "preferred_position": "back",
    "targeting_priority": 10
  },
  "special_ability": {
    "name": "Muting Touch",
    "description": "Every 8s, mutes typing sounds for 3s (disorienting)",
    "cooldown": 8.0,
    "duration": 3.0,
    "effect": "disable_typing_audio",
    "visual": "silence_wave"
  },
  "spawn_conditions": {
    "min_day": 7,
    "regions": ["mistfen", "void_rift"],
    "wave_position": "back"
  }
}
```

#### Rusted Knight
```json
{
  "id": "rusted_knight",
  "name": "Rusted Knight",
  "tier": 2,
  "category": "soldier",
  "description": "An ancient warrior whose armor provides modest protection.",
  "lore": "The Rusted Knights were once champions of Dvorakia, fallen to the Silence centuries ago. Their corroded armor still bears their kingdom's crest.",
  "stats": {
    "hp": 7,
    "armor": 1,
    "speed": 0.7,
    "damage_to_castle": 3,
    "word_length_min": 5,
    "word_length_max": 6,
    "xp_reward": 15,
    "gold_reward": 7
  },
  "appearance": {
    "base_color": "#78350F",
    "glow_color": "#D97706",
    "size": "medium",
    "sprite": "enemies/rusted_knight.svg",
    "animations": ["idle_stand", "move_clank", "attack_swing", "death_crumble"]
  },
  "behavior": {
    "type": "direct_advance",
    "ai_notes": "Slow and tanky",
    "targeting_priority": 6
  },
  "special_ability": {
    "name": "Rusty Armor",
    "description": "Takes 1 less damage from all sources (minimum 1)",
    "damage_reduction": 1,
    "passive": true
  },
  "spawn_conditions": {
    "min_day": 6,
    "regions": ["stonepass", "citadel"],
    "wave_position": "front"
  }
}
```

#### Shade Stalker
```json
{
  "id": "shade_stalker",
  "name": "Shade Stalker",
  "tier": 2,
  "category": "soldier",
  "description": "An assassin that can briefly turn invisible.",
  "lore": "Shade Stalkers slip between shadows, their words visible only at the last moment. Many a typist has been caught off-guard by their sudden appearance.",
  "stats": {
    "hp": 4,
    "armor": 0,
    "speed": 1.1,
    "damage_to_castle": 4,
    "word_length_min": 4,
    "word_length_max": 5,
    "xp_reward": 18,
    "gold_reward": 8
  },
  "appearance": {
    "base_color": "#0F172A",
    "glow_color": "#475569",
    "size": "medium",
    "sprite": "enemies/shade_stalker.svg",
    "animations": ["idle_crouch", "move_slink", "attack_backstab", "death_fade"]
  },
  "behavior": {
    "type": "stealth_advance",
    "ai_notes": "Periodically goes invisible",
    "targeting_priority": 11
  },
  "special_ability": {
    "name": "Shadow Cloak",
    "description": "Becomes invisible for 2s every 6s (word hidden too)",
    "cooldown": 6.0,
    "duration": 2.0,
    "reveals_on": ["typing_started", "tower_hit"],
    "visual": "fade_to_shadow"
  },
  "spawn_conditions": {
    "min_day": 8,
    "regions": ["mistfen", "evergrove"],
    "wave_position": "scattered"
  }
}
```

---

## Tier 3: Elites

### Core Elites

#### Typhos Raider
```json
{
  "id": "typhos_raider",
  "name": "Typhos Raider",
  "tier": 3,
  "category": "elite",
  "description": "A battle-hardened Typhos warrior with thick void-forged armor.",
  "lore": "Raiders have survived countless battles, their bodies now more void than flesh. They lead assault groups with brutal efficiency.",
  "stats": {
    "hp": 10,
    "armor": 1,
    "speed": 0.9,
    "damage_to_castle": 4,
    "word_length_min": 6,
    "word_length_max": 8,
    "xp_reward": 25,
    "gold_reward": 12
  },
  "appearance": {
    "base_color": "#4C1D95",
    "glow_color": "#8B5CF6",
    "size": "large",
    "sprite": "enemies/typhos_raider.svg",
    "animations": ["idle_ready", "move_stride", "attack_cleave", "death_kneel"]
  },
  "behavior": {
    "type": "direct_advance",
    "ai_notes": "Tank, leads groups",
    "targeting_priority": 15
  },
  "special_ability": {
    "name": "Void Armor",
    "description": "Takes 1 less damage, regenerates 1 HP every 10s",
    "damage_reduction": 1,
    "regen_amount": 1,
    "regen_interval": 10.0
  },
  "spawn_conditions": {
    "min_day": 7,
    "regions": ["all"],
    "wave_position": "front"
  }
}
```

#### Shadow Mage
```json
{
  "id": "shadow_mage",
  "name": "Shadow Mage",
  "tier": 3,
  "category": "elite",
  "description": "A powerful spellcaster who debuffs the player's typing ability.",
  "lore": "Shadow Mages have mastered the anti-typing arts, weaving spells that scramble thoughts and fumble fingers.",
  "stats": {
    "hp": 7,
    "armor": 0,
    "speed": 0.7,
    "damage_to_castle": 2,
    "word_length_min": 7,
    "word_length_max": 8,
    "xp_reward": 30,
    "gold_reward": 15
  },
  "appearance": {
    "base_color": "#312E81",
    "glow_color": "#6366F1",
    "size": "medium",
    "sprite": "enemies/shadow_mage.svg",
    "animations": ["idle_channel", "move_float", "attack_bolt", "death_implode"],
    "particles": "shadow_swirl"
  },
  "behavior": {
    "type": "support_caster",
    "ai_notes": "Stays back, casts debuffs on player",
    "preferred_position": "back",
    "targeting_priority": 20
  },
  "special_ability": {
    "name": "Word Scramble",
    "description": "Every 8s, scrambles the letters of the next word you target",
    "cooldown": 8.0,
    "effect": "scramble_target_word",
    "visual": "purple_runes",
    "audio": "spell_cast"
  },
  "spawn_conditions": {
    "min_day": 10,
    "regions": ["mistfen", "void_rift", "citadel"],
    "wave_position": "back"
  }
}
```

#### Void Knight
```json
{
  "id": "void_knight",
  "name": "Void Knight",
  "tier": 3,
  "category": "elite",
  "description": "A commanding presence that shields nearby allies.",
  "lore": "Void Knights are chosen champions of the Tyrant, their loyalty rewarded with power to protect the Horde.",
  "stats": {
    "hp": 12,
    "armor": 2,
    "speed": 0.8,
    "damage_to_castle": 5,
    "word_length_min": 6,
    "word_length_max": 7,
    "xp_reward": 35,
    "gold_reward": 18
  },
  "appearance": {
    "base_color": "#18181B",
    "glow_color": "#A855F7",
    "size": "large",
    "sprite": "enemies/void_knight.svg",
    "animations": ["idle_guard", "move_march", "attack_smash", "death_shatter"],
    "aura_effect": "shield_pulse"
  },
  "behavior": {
    "type": "guardian",
    "ai_notes": "Moves with group, provides shields",
    "stay_with_allies": true,
    "targeting_priority": 18
  },
  "special_ability": {
    "name": "Void Shield",
    "description": "Grants 2 shield HP to all allies within radius 2",
    "radius": 2,
    "shield_amount": 2,
    "refresh_interval": 15.0,
    "visual": "purple_shield_bubble"
  },
  "spawn_conditions": {
    "min_day": 12,
    "regions": ["all"],
    "wave_position": "middle"
  }
}
```

#### Chaos Berserker
```json
{
  "id": "chaos_berserker",
  "name": "Chaos Berserker",
  "tier": 3,
  "category": "elite",
  "description": "A frenzied warrior whose attacks grow more devastating over time.",
  "lore": "Berserkers have abandoned all reason, their minds consumed by battle-lust. They know only the joy of destruction.",
  "stats": {
    "hp": 9,
    "armor": 0,
    "speed": 1.0,
    "damage_to_castle": 6,
    "word_length_min": 6,
    "word_length_max": 8,
    "xp_reward": 32,
    "gold_reward": 16
  },
  "appearance": {
    "base_color": "#7F1D1D",
    "glow_color": "#DC2626",
    "size": "large",
    "sprite": "enemies/chaos_berserker.svg",
    "animations": ["idle_rage", "move_charge", "attack_frenzy", "death_explosion"]
  },
  "behavior": {
    "type": "berserker",
    "ai_notes": "Gets stronger over time",
    "targeting_priority": 17
  },
  "special_ability": {
    "name": "Rage Build",
    "description": "Gains +0.1 speed and +1 damage every 10s alive",
    "interval": 10.0,
    "speed_bonus": 0.1,
    "damage_bonus": 1,
    "max_stacks": 5,
    "visual": "rage_aura_grow"
  },
  "spawn_conditions": {
    "min_day": 14,
    "regions": ["sunfields", "fire_realm"],
    "wave_position": "front"
  }
}
```

#### Frost Weaver
```json
{
  "id": "frost_weaver",
  "name": "Frost Weaver",
  "tier": 3,
  "category": "elite",
  "description": "An ice mage that slows towers and complicates typing.",
  "lore": "Frost Weavers draw power from the Ice Realm, their chilling presence freezing both fingers and thoughts.",
  "stats": {
    "hp": 8,
    "armor": 0,
    "speed": 0.75,
    "damage_to_castle": 3,
    "word_length_min": 7,
    "word_length_max": 8,
    "xp_reward": 33,
    "gold_reward": 17
  },
  "appearance": {
    "base_color": "#164E63",
    "glow_color": "#22D3EE",
    "size": "medium",
    "sprite": "enemies/frost_weaver.svg",
    "animations": ["idle_frost", "move_glide", "attack_freeze", "death_shatter"],
    "particles": "frost_crystals"
  },
  "behavior": {
    "type": "support_caster",
    "ai_notes": "Debuffs towers and player",
    "targeting_priority": 21
  },
  "special_ability": {
    "name": "Frost Aura",
    "description": "All towers within radius 2 have -30% attack speed",
    "radius": 2,
    "tower_slow": 0.3,
    "passive": true,
    "visual": "frost_field"
  },
  "secondary_ability": {
    "name": "Frozen Fingers",
    "description": "Every 12s, your next mistake has double penalty",
    "cooldown": 12.0,
    "effect": "double_mistake_penalty",
    "duration": "next_mistake"
  },
  "spawn_conditions": {
    "min_day": 15,
    "regions": ["stonepass", "ice_realm"],
    "wave_position": "back"
  }
}
```

#### Plague Bearer
```json
{
  "id": "plague_bearer",
  "name": "Plague Bearer",
  "tier": 3,
  "category": "elite",
  "description": "A diseased horror that spreads corruption on death.",
  "lore": "Plague Bearers carry the sickness of unfinished stories, their very presence toxic to properly formed words.",
  "stats": {
    "hp": 11,
    "armor": 0,
    "speed": 0.6,
    "damage_to_castle": 4,
    "word_length_min": 6,
    "word_length_max": 8,
    "xp_reward": 30,
    "gold_reward": 14
  },
  "appearance": {
    "base_color": "#14532D",
    "glow_color": "#22C55E",
    "size": "large",
    "sprite": "enemies/plague_bearer.svg",
    "animations": ["idle_sway", "move_shamble", "attack_vomit", "death_burst"],
    "particles": "toxic_cloud"
  },
  "behavior": {
    "type": "direct_advance",
    "ai_notes": "Slow, dangerous on death",
    "targeting_priority": 16
  },
  "special_ability": {
    "name": "Toxic Presence",
    "description": "Towers targeting this enemy have -20% accuracy",
    "tower_accuracy_penalty": 0.2,
    "passive": true
  },
  "death_ability": {
    "name": "Death Burst",
    "description": "On death, poisons all enemies in radius 2 (actually heals them)",
    "radius": 2,
    "heal_amount": 3,
    "visual": "green_explosion"
  },
  "spawn_conditions": {
    "min_day": 13,
    "regions": ["mistfen", "nature_realm"],
    "wave_position": "middle"
  }
}
```

---

## Tier 4: Champions

### Core Champions

#### Typhos Lord
```json
{
  "id": "typhos_lord",
  "name": "Typhos Lord",
  "tier": 4,
  "category": "champion",
  "description": "A commander of the Horde who summons reinforcements.",
  "lore": "Lords are the generals of the Typhos Horde, their strategic minds twisted by void corruption into ruthless tactical savants.",
  "stats": {
    "hp": 18,
    "armor": 1,
    "speed": 0.6,
    "damage_to_castle": 8,
    "word_length_min": 8,
    "word_length_max": 10,
    "xp_reward": 75,
    "gold_reward": 40
  },
  "appearance": {
    "base_color": "#3B0764",
    "glow_color": "#C084FC",
    "size": "large",
    "sprite": "enemies/typhos_lord.svg",
    "animations": ["idle_command", "move_stride", "attack_command", "death_dramatic"],
    "crown": true
  },
  "behavior": {
    "type": "commander",
    "ai_notes": "Summons minions, stays back",
    "preferred_position": "back",
    "targeting_priority": 25
  },
  "special_ability": {
    "name": "Summon Spawn",
    "description": "Every 10s, summons 2 Typhos Spawn",
    "cooldown": 10.0,
    "summon_type": "typhos_spawn",
    "summon_count": 2,
    "max_summons_alive": 6
  },
  "secondary_ability": {
    "name": "Rally Cry",
    "description": "When HP drops below 50%, all allies gain +20% speed for 10s",
    "trigger": "hp_below_50",
    "speed_bonus": 0.2,
    "duration": 10.0,
    "one_time": true
  },
  "spawn_conditions": {
    "min_day": 15,
    "regions": ["all"],
    "wave_position": "back",
    "max_per_wave": 1
  }
}
```

#### Corrupted Giant
```json
{
  "id": "corrupted_giant",
  "name": "Corrupted Giant",
  "tier": 4,
  "category": "champion",
  "description": "A massive creature that can stun towers with ground pounds.",
  "lore": "Giants were once the gentle guardians of the mountains. Now corrupted, they bring earthquakes with every step.",
  "stats": {
    "hp": 25,
    "armor": 2,
    "speed": 0.4,
    "damage_to_castle": 15,
    "word_length_min": 10,
    "word_length_max": 12,
    "xp_reward": 100,
    "gold_reward": 50
  },
  "appearance": {
    "base_color": "#44403C",
    "glow_color": "#A8A29E",
    "corruption_veins": "#7C3AED",
    "size": "huge",
    "sprite": "enemies/corrupted_giant.svg",
    "animations": ["idle_breathe", "move_stomp", "attack_slam", "death_fall"],
    "screen_shake_on_step": true
  },
  "behavior": {
    "type": "siege",
    "ai_notes": "Very slow, very dangerous",
    "causes_screen_shake": true,
    "targeting_priority": 23
  },
  "special_ability": {
    "name": "Ground Pound",
    "description": "Every 15s, stuns all towers for 2s",
    "cooldown": 15.0,
    "stun_duration": 2.0,
    "radius": "all_towers",
    "visual": "earthquake_wave"
  },
  "secondary_ability": {
    "name": "Thick Hide",
    "description": "Takes 2 less damage from all sources",
    "damage_reduction": 2,
    "passive": true
  },
  "spawn_conditions": {
    "min_day": 20,
    "regions": ["stonepass", "void_rift"],
    "wave_position": "front",
    "max_per_wave": 1
  }
}
```

#### Void Assassin
```json
{
  "id": "void_assassin",
  "name": "Void Assassin",
  "tier": 4,
  "category": "champion",
  "description": "A master of stealth who teleports and resets targeting.",
  "lore": "Assassins are the Tyrant's silent hand, eliminating threats before they can be voiced. To type their word is to catch a shadow.",
  "stats": {
    "hp": 15,
    "armor": 0,
    "speed": 1.0,
    "damage_to_castle": 10,
    "word_length_min": 8,
    "word_length_max": 10,
    "xp_reward": 90,
    "gold_reward": 45
  },
  "appearance": {
    "base_color": "#0C0A09",
    "glow_color": "#A855F7",
    "size": "medium",
    "sprite": "enemies/void_assassin.svg",
    "animations": ["idle_crouch", "move_dash", "attack_execute", "death_shadow"],
    "shadow_trail": true
  },
  "behavior": {
    "type": "teleporter",
    "ai_notes": "Teleports frequently, resets word progress",
    "targeting_priority": 28
  },
  "special_ability": {
    "name": "Shadow Step",
    "description": "Every 6s, teleports 3 tiles forward and resets word progress",
    "cooldown": 6.0,
    "teleport_distance": 3,
    "resets_word_progress": true,
    "visual": "shadow_blink"
  },
  "secondary_ability": {
    "name": "Assassin's Mark",
    "description": "If not defeated within 30s, deals double castle damage",
    "timer": 30.0,
    "damage_multiplier": 2.0,
    "visual": "timer_indicator"
  },
  "spawn_conditions": {
    "min_day": 25,
    "regions": ["mistfen", "void_rift"],
    "wave_position": "scattered",
    "max_per_wave": 1
  }
}
```

#### Warlord
```json
{
  "id": "warlord",
  "name": "Warlord",
  "tier": 4,
  "category": "champion",
  "description": "A devastating melee combatant who empowers nearby allies.",
  "lore": "Warlords were legendary warriors who fell to the Void. Their battle prowess now serves darkness, inspiring terror in all who face them.",
  "stats": {
    "hp": 22,
    "armor": 1,
    "speed": 0.7,
    "damage_to_castle": 12,
    "word_length_min": 9,
    "word_length_max": 11,
    "xp_reward": 85,
    "gold_reward": 42
  },
  "appearance": {
    "base_color": "#7F1D1D",
    "glow_color": "#EF4444",
    "size": "large",
    "sprite": "enemies/warlord.svg",
    "animations": ["idle_roar", "move_march", "attack_cleave", "death_dramatic"],
    "banner": "void_banner"
  },
  "behavior": {
    "type": "commander",
    "ai_notes": "Leads from the front, buffs allies",
    "preferred_position": "front",
    "targeting_priority": 26
  },
  "special_ability": {
    "name": "War Banner",
    "description": "All allies within radius 3 deal +25% damage",
    "radius": 3,
    "damage_bonus": 0.25,
    "passive": true,
    "visual": "red_aura"
  },
  "secondary_ability": {
    "name": "Execute",
    "description": "If castle HP is below 30%, gains +50% speed",
    "trigger": "castle_hp_below_30",
    "speed_bonus": 0.5,
    "passive": true
  },
  "spawn_conditions": {
    "min_day": 22,
    "regions": ["sunfields", "citadel"],
    "wave_position": "front",
    "max_per_wave": 1
  }
}
```

#### Arcane Horror
```json
{
  "id": "arcane_horror",
  "name": "Arcane Horror",
  "tier": 4,
  "category": "champion",
  "description": "A twisted spellcaster that drains tower effectiveness.",
  "lore": "Arcane Horrors were once the greatest mages of the realm. Their pursuit of forbidden knowledge transformed them into living nightmares.",
  "stats": {
    "hp": 16,
    "armor": 0,
    "speed": 0.5,
    "damage_to_castle": 6,
    "word_length_min": 10,
    "word_length_max": 12,
    "xp_reward": 95,
    "gold_reward": 48
  },
  "appearance": {
    "base_color": "#1E1B4B",
    "glow_color": "#818CF8",
    "size": "large",
    "sprite": "enemies/arcane_horror.svg",
    "animations": ["idle_channel", "move_hover", "attack_beam", "death_implosion"],
    "floating": true,
    "eye_count": 5
  },
  "behavior": {
    "type": "siege_caster",
    "ai_notes": "Disables towers, very high priority target",
    "targeting_priority": 30
  },
  "special_ability": {
    "name": "Mana Drain",
    "description": "Every 8s, disables the nearest tower for 5s",
    "cooldown": 8.0,
    "disable_duration": 5.0,
    "target": "nearest_tower",
    "visual": "purple_drain_beam"
  },
  "secondary_ability": {
    "name": "Arcane Shield",
    "description": "Takes 50% less damage from towers",
    "tower_damage_reduction": 0.5,
    "passive": true,
    "note": "Typing damage is full"
  },
  "spawn_conditions": {
    "min_day": 28,
    "regions": ["citadel", "void_rift"],
    "wave_position": "back",
    "max_per_wave": 1
  }
}
```

---

## Regional Variants

### Evergrove Forest Variants

```json
{
  "region": "evergrove",
  "variants": [
    {
      "base": "typhos_spawn",
      "variant_id": "forest_imp",
      "name": "Forest Imp",
      "modifications": {
        "appearance": {
          "base_color": "#166534",
          "glow_color": "#4ADE80"
        },
        "word_source": "nature_vocabulary",
        "stats": {
          "speed": 1.3
        }
      },
      "lore": "Forest Imps were once tree sprites, corrupted by void essence seeping through the forest floor."
    },
    {
      "base": "void_hound",
      "variant_id": "corrupted_deer",
      "name": "Corrupted Deer",
      "modifications": {
        "appearance": {
          "base_color": "#713F12",
          "sprite": "enemies/corrupted_deer.svg"
        },
        "stats": {
          "hp": 5,
          "speed": 1.6
        }
      },
      "lore": "Once graceful forest dwellers, these deer now flee toward destruction rather than from it."
    },
    {
      "base": "typhos_raider",
      "variant_id": "treant_shambler",
      "name": "Treant Shambler",
      "modifications": {
        "appearance": {
          "base_color": "#365314",
          "sprite": "enemies/treant_shambler.svg"
        },
        "stats": {
          "hp": 13,
          "speed": 0.6
        },
        "special_ability": {
          "name": "Regeneration",
          "description": "Heals 1 HP every 5s",
          "regen_amount": 1,
          "regen_interval": 5.0
        }
      },
      "lore": "Ancient forest guardians whose bark has been corrupted by void fungus."
    }
  ]
}
```

### Stonepass Mountains Variants

```json
{
  "region": "stonepass",
  "variants": [
    {
      "base": "shadow_rat",
      "variant_id": "cave_crawler",
      "name": "Cave Crawler",
      "modifications": {
        "appearance": {
          "base_color": "#292524"
        },
        "behavior": {
          "pack_size": 4,
          "pack_spread": 0.3
        }
      }
    },
    {
      "base": "typhos_raider",
      "variant_id": "stone_sentinel",
      "name": "Stone Sentinel",
      "modifications": {
        "appearance": {
          "base_color": "#57534E",
          "sprite": "enemies/stone_sentinel.svg"
        },
        "stats": {
          "hp": 14,
          "armor": 2,
          "speed": 0.7
        }
      },
      "lore": "Ancient dwarven constructs corrupted by void energy seeping through crystal veins."
    },
    {
      "base": "shadow_mage",
      "variant_id": "crystal_horror",
      "name": "Crystal Horror",
      "modifications": {
        "appearance": {
          "base_color": "#7DD3FC",
          "glow_color": "#38BDF8"
        },
        "special_ability": {
          "name": "Crystal Reflection",
          "description": "Reflects 25% of tower damage back at towers",
          "reflect_percent": 0.25
        }
      }
    }
  ]
}
```

### Mistfen Marshes Variants

```json
{
  "region": "mistfen",
  "variants": [
    {
      "base": "typhos_spawn",
      "variant_id": "bog_creeper",
      "name": "Bog Creeper",
      "modifications": {
        "appearance": {
          "base_color": "#14532D",
          "glow_color": "#22C55E"
        },
        "special_ability": {
          "name": "Poisonous",
          "description": "On dealing castle damage, applies poison (2 damage over 4s)",
          "poison_damage": 2,
          "poison_duration": 4.0
        }
      }
    },
    {
      "base": "shade_stalker",
      "variant_id": "marsh_stalker",
      "name": "Marsh Stalker",
      "modifications": {
        "appearance": {
          "base_color": "#064E3B"
        },
        "special_ability": {
          "name": "Fog Form",
          "description": "Invisible while in fog weather",
          "fog_invisible": true
        }
      }
    },
    {
      "base": "shadow_mage",
      "variant_id": "fen_witch",
      "name": "Fen Witch",
      "modifications": {
        "special_ability": {
          "name": "Curse of Confusion",
          "description": "Every 6s, swaps two letters in your current word",
          "cooldown": 6.0
        }
      }
    }
  ]
}
```

---

## Affix Details

### Full Affix Catalog

```json
{
  "affixes": [
    {
      "id": "armored",
      "name": "Armored",
      "description": "Covered in void-forged plates",
      "effect": {
        "armor_bonus": 2,
        "speed_penalty": 0.1
      },
      "visual": {
        "overlay": "affix_armored.svg",
        "particle": "metal_gleam",
        "color_shift": "#71717A"
      },
      "counter": "High combo for bonus damage pierces armor",
      "weight": 100,
      "tier_min": 2
    },
    {
      "id": "swift",
      "name": "Swift",
      "description": "Moves with unnatural speed",
      "effect": {
        "speed_bonus": 0.4,
        "hp_penalty": 0.15
      },
      "visual": {
        "overlay": "affix_swift.svg",
        "particle": "speed_lines",
        "color_shift": "#22D3EE"
      },
      "counter": "Prioritize targeting immediately",
      "weight": 100,
      "tier_min": 1
    },
    {
      "id": "shielded",
      "name": "Shielded",
      "description": "Protected by a void barrier",
      "effect": {
        "shield_hp": 3,
        "shield_word": true
      },
      "visual": {
        "overlay": "affix_shielded.svg",
        "particle": "shield_shimmer",
        "color_shift": "#A78BFA"
      },
      "mechanic": "Must type shield word first to remove shield",
      "counter": "Shield word is always 3 letters",
      "weight": 80,
      "tier_min": 2
    },
    {
      "id": "burning",
      "name": "Burning",
      "description": "Wreathed in void flames",
      "effect": {
        "tower_dot": 1,
        "tower_dot_radius": 1,
        "tower_dot_interval": 2.0
      },
      "visual": {
        "overlay": "affix_burning.svg",
        "particle": "fire_embers",
        "color_shift": "#EF4444"
      },
      "counter": "Holy towers extinguish burning on hit",
      "weight": 90,
      "tier_min": 2,
      "incompatible": ["frozen"]
    },
    {
      "id": "frozen",
      "name": "Frozen",
      "description": "Emanates supernatural cold",
      "effect": {
        "tower_slow_aura": 0.25,
        "tower_slow_radius": 1.5
      },
      "visual": {
        "overlay": "affix_frozen.svg",
        "particle": "frost_crystals",
        "color_shift": "#38BDF8"
      },
      "counter": "Fire towers ignore slow effect",
      "weight": 90,
      "tier_min": 2,
      "incompatible": ["burning"]
    },
    {
      "id": "toxic",
      "name": "Toxic",
      "description": "Oozes corrosive void slime",
      "effect": {
        "on_mistake_damage": 2,
        "mistake_damage_target": "castle"
      },
      "visual": {
        "overlay": "affix_toxic.svg",
        "particle": "poison_bubbles",
        "color_shift": "#84CC16"
      },
      "counter": "Focus on accuracy, avoid mistakes",
      "weight": 70,
      "tier_min": 3
    },
    {
      "id": "vampiric",
      "name": "Vampiric",
      "description": "Drains life force from damage dealt",
      "effect": {
        "lifesteal_percent": 0.5,
        "lifesteal_source": "castle_damage"
      },
      "visual": {
        "overlay": "affix_vampiric.svg",
        "particle": "blood_drain",
        "color_shift": "#DC2626"
      },
      "counter": "Kill quickly before it heals",
      "weight": 60,
      "tier_min": 3
    },
    {
      "id": "enraged",
      "name": "Enraged",
      "description": "Consumed by void fury",
      "effect": {
        "damage_bonus": 0.5,
        "hp_penalty": 0.2,
        "speed_bonus": 0.15
      },
      "visual": {
        "overlay": "affix_enraged.svg",
        "particle": "rage_pulse",
        "color_shift": "#F97316"
      },
      "counter": "High priority target due to bonus damage",
      "weight": 80,
      "tier_min": 2
    },
    {
      "id": "splitting",
      "name": "Splitting",
      "description": "Divides upon death",
      "effect": {
        "on_death_spawn": "same_tier_minus_1",
        "spawn_count": 2
      },
      "visual": {
        "overlay": "affix_splitting.svg",
        "particle": "mitosis_glow",
        "color_shift": "#A3E635"
      },
      "counter": "Be prepared to handle spawns",
      "weight": 50,
      "tier_min": 2,
      "tier_max": 3
    },
    {
      "id": "phasing",
      "name": "Phasing",
      "description": "Exists partially in the void",
      "effect": {
        "tower_damage_reduction": 0.5,
        "typing_damage_bonus": 0.25
      },
      "visual": {
        "overlay": "affix_phasing.svg",
        "particle": "phase_shimmer",
        "color_shift": "#C084FC"
      },
      "counter": "Typing is more effective than towers",
      "weight": 60,
      "tier_min": 3
    },
    {
      "id": "reflecting",
      "name": "Reflecting",
      "description": "Surrounded by mirror void",
      "effect": {
        "reflect_tower_damage": 0.3,
        "reflect_to": "random_tower"
      },
      "visual": {
        "overlay": "affix_reflecting.svg",
        "particle": "mirror_shards",
        "color_shift": "#E2E8F0"
      },
      "counter": "Use towers carefully, prioritize typing",
      "weight": 40,
      "tier_min": 4
    },
    {
      "id": "hexed",
      "name": "Hexed",
      "description": "Curses the keyboard on damage",
      "effect": {
        "on_damage_curse_key": true,
        "curse_duration": 3.0,
        "curse_effect": "key_does_nothing"
      },
      "visual": {
        "overlay": "affix_hexed.svg",
        "particle": "curse_runes",
        "color_shift": "#7C3AED"
      },
      "counter": "Use tower damage when possible",
      "weight": 30,
      "tier_min": 4
    }
  ]
}
```

---

## Boss Phase Details

### Grove Guardian - Full Script

```json
{
  "boss_id": "boss_grove_guardian",
  "name": "Grove Guardian",
  "title": "Protector of the Ancient Woods",
  "region": "evergrove",
  "unlock_condition": "complete_all_evergrove_zones",

  "intro_dialogue": [
    "The ancient trees part, revealing a massive figure of bark and vine.",
    "Its eyes glow with emerald light as it regards you.",
    "\"You seek passage through my forest, young typist?\"",
    "\"Then prove your worth. Show me the rhythm of your keys.\""
  ],

  "stats": {
    "total_hp": 50,
    "armor": 1,
    "speed": 0.5
  },

  "phases": [
    {
      "phase": 1,
      "name": "Nature's Test",
      "hp_range": [50, 30],
      "music": "boss/grove_guardian_p1.ogg",
      "dialogue_start": "\"Let us begin. Type as the forest speaks.\"",
      "mechanics": [
        {
          "name": "Vine Wall",
          "description": "Summons vine barriers that must be cleared",
          "interval": 12.0,
          "effect": "Spawns 3 vine obstacles with 3-letter words",
          "visual": "vine_wall_grow"
        },
        {
          "name": "Nature Words",
          "description": "Boss words are nature-themed",
          "word_source": "nature_vocabulary",
          "words": ["leaf", "branch", "root", "bark", "grove", "forest", "ancient", "growth"]
        },
        {
          "name": "Healing Roots",
          "description": "Periodically attempts to heal",
          "interval": 15.0,
          "heal_amount": 5,
          "interrupt_wpm": 35,
          "interrupt_text": "Type fast to interrupt healing!"
        }
      ],
      "minions": {
        "spawn_interval": 20.0,
        "types": ["forest_imp"],
        "count": 2
      }
    },
    {
      "phase": 2,
      "name": "Guardian's Fury",
      "hp_range": [30, 0],
      "music": "boss/grove_guardian_p2.ogg",
      "dialogue_start": "\"You have skill. But can you weather the storm?\"",
      "transition_effect": "boss_roar_screen_shake",
      "mechanics": [
        {
          "name": "Accelerated Vines",
          "description": "Vine walls spawn faster and have longer words",
          "interval": 8.0,
          "word_length": [4, 5]
        },
        {
          "name": "Root Snare",
          "description": "Accuracy challenge to escape root trap",
          "interval": 20.0,
          "effect": "If accuracy < 90% in next 10s, take 5 damage",
          "visual": "roots_grabbing"
        },
        {
          "name": "Forest Creatures",
          "description": "Summons more and stronger minions",
          "spawn_interval": 15.0,
          "types": ["forest_imp", "corrupted_deer"],
          "count": 3
        }
      ],
      "enrage": {
        "trigger": "hp_below_10",
        "effect": "Speed +50%, attack rate +50%",
        "dialogue": "\"The forest will NOT fall!\""
      }
    }
  ],

  "defeat_dialogue": [
    "The Guardian staggers, bark cracking, light fading from its eyes.",
    "\"You... have proven yourself, young one.\"",
    "\"The forest accepts you. Take this seal as proof of your worth.\"",
    "The Guardian dissolves into a shower of leaves, leaving behind a glowing seal."
  ],

  "rewards": {
    "gold": 200,
    "xp": 500,
    "items": [
      {"id": "grove_seal", "guaranteed": true},
      {"id": "treant_bark_armor", "chance": 0.25}
    ],
    "title": "Grove Protector",
    "achievement": "defeat_grove_guardian"
  }
}
```

---

## Implementation Data

### Enemy Spawn Tables by Day

```json
{
  "spawn_tables": {
    "day_1_5": {
      "tier_weights": {"T1": 1.0},
      "enemies": {
        "typhos_spawn": 50,
        "void_wisp": 25,
        "shadow_rat": 25
      },
      "affix_chance": 0,
      "champion_chance": 0
    },
    "day_6_10": {
      "tier_weights": {"T1": 0.6, "T2": 0.4},
      "enemies": {
        "typhos_spawn": 30,
        "void_wisp": 15,
        "shadow_rat": 15,
        "ink_blob": 10,
        "typhos_scout": 15,
        "corrupted_archer": 10,
        "void_hound": 5
      },
      "affix_chance": 0.05,
      "champion_chance": 0
    },
    "day_11_20": {
      "tier_weights": {"T1": 0.3, "T2": 0.5, "T3": 0.2},
      "affix_chance": 0.15,
      "champion_chance": 0.05
    },
    "day_21_35": {
      "tier_weights": {"T1": 0.15, "T2": 0.4, "T3": 0.35, "T4": 0.1},
      "affix_chance": 0.25,
      "champion_chance": 0.1
    },
    "day_36_plus": {
      "tier_weights": {"T1": 0.1, "T2": 0.3, "T3": 0.4, "T4": 0.2},
      "affix_chance": 0.35,
      "champion_chance": 0.15,
      "multi_affix_chance": 0.1
    }
  }
}
```

---

## References

- `docs/plans/p1/ENEMY_COMBAT_DESIGN.md` - Overview document
- `docs/plans/p1/REGION_SPECIFICATIONS.md` - Regional details
- `sim/types.gd` - Enemy type definitions
- `data/enemies.json` - Enemy data file (to be created)
