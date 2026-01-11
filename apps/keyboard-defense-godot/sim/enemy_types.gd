class_name SimEnemyTypes
extends RefCounted
## Enemy Type Definitions - Centralized definitions for all enemy types across 4 tiers

# =============================================================================
# ENUMS
# =============================================================================

enum Tier { MINION = 1, SOLDIER = 2, ELITE = 3, CHAMPION = 4, BOSS = 5 }

enum Category {
	BASIC,      # Standard enemies, direct advance
	SWARM,      # Spawns in groups, pack tactics
	RANGED,     # Attacks from distance
	STEALTH,    # Visibility gimmicks
	SUPPORT,    # Buffs/heals allies
	TANK,       # High HP/armor
	BERSERKER,  # Gets stronger when damaged
	CASTER,     # Debuffs player/towers
	COMMANDER,  # Summons/commands minions
	SIEGE       # Attacks structures
}

enum BehaviorType {
	DIRECT_ADVANCE,    # Move straight to castle
	ERRATIC_PATH,      # Zigzag movement
	PACK_MOVEMENT,     # Stay near pack
	STOP_AND_ATTACK,   # Stop at range to attack
	CHARGE_ATTACK,     # Speed burst toward target
	SUPPORT_CASTER,    # Stay behind allies
	STEALTH_ADVANCE,   # Periodic invisibility
	GUARDIAN,          # Protect nearby allies
	COMMANDER_LEAD,    # Lead from back
	TELEPORTER,        # Blink movement
	SIEGE_MODE         # Attack structures
}

enum Region {
	ALL,           # Spawns everywhere
	EVERGROVE,     # Evergrove Forest
	STONEPASS,     # Stonepass Mountains
	MISTFEN,       # Mistfen Marshes
	SUNFIELDS      # Sunfields Plains
}

# =============================================================================
# ENEMY TYPE IDS
# =============================================================================

# Tier 1: Minions
const TYPHOS_SPAWN := "typhos_spawn"
const VOID_WISP := "void_wisp"
const SHADOW_RAT := "shadow_rat"
const INK_BLOB := "ink_blob"
const GLITCH_SPRITE := "glitch_sprite"
const DUST_MOTE := "dust_mote"
const VOID_TICK := "void_tick"
const SPARK_FLY := "spark_fly"

# Tier 2: Soldiers
const TYPHOS_SCOUT := "typhos_scout"
const CORRUPTED_ARCHER := "corrupted_archer"
const VOID_HOUND := "void_hound"
const SILENCE_ACOLYTE := "silence_acolyte"
const RUSTED_KNIGHT := "rusted_knight"
const SHADE_STALKER := "shade_stalker"
const MARSH_LURKER := "marsh_lurker"
const STONE_CRAWLER := "stone_crawler"
const FLAME_DANCER := "flame_dancer"
const WIND_RUNNER := "wind_runner"

# Tier 3: Elites
const TYPHOS_RAIDER := "typhos_raider"
const SHADOW_MAGE := "shadow_mage"
const VOID_KNIGHT := "void_knight"
const CHAOS_BERSERKER := "chaos_berserker"
const FROST_WEAVER := "frost_weaver"
const PLAGUE_BEARER := "plague_bearer"
const CRYSTAL_SENTINEL := "crystal_sentinel"
const STORM_CALLER := "storm_caller"

# Tier 4: Champions
const TYPHOS_LORD := "typhos_lord"
const CORRUPTED_GIANT := "corrupted_giant"
const VOID_ASSASSIN := "void_assassin"
const WARLORD := "warlord"
const ARCANE_HORROR := "arcane_horror"
const TREANT_ANCIENT := "treant_ancient"

# =============================================================================
# ENEMY DEFINITIONS
# =============================================================================

const ENEMIES: Dictionary = {
	# =========================================================================
	# TIER 1 - MINIONS (Base HP: 2-4, low threat, cannon fodder)
	# =========================================================================
	TYPHOS_SPAWN: {
		"name": "Typhos Spawn",
		"description": "Basic void-touched creature. Weak but persistent.",
		"tier": Tier.MINION,
		"category": Category.BASIC,
		"behavior": BehaviorType.DIRECT_ADVANCE,
		"hp": 3,
		"armor": 0,
		"speed": 1.2,
		"damage": 1,
		"gold": 1,
		"glyph": "t",
		"color": Color(0.6, 0.4, 0.8),
		"sprite": "enemy_typhos_spawn",
		"abilities": [],
		"flavor": "The first whispers of corruption."
	},
	VOID_WISP: {
		"name": "Void Wisp",
		"description": "Ethereal light that flickers in and out of visibility.",
		"tier": Tier.MINION,
		"category": Category.STEALTH,
		"behavior": BehaviorType.ERRATIC_PATH,
		"hp": 2,
		"armor": 0,
		"speed": 1.5,
		"damage": 1,
		"gold": 1,
		"glyph": "w",
		"color": Color(0.8, 0.6, 1.0),
		"abilities": ["flicker"],
		"flavor": "Now you see it, now you don't."
	},
	SHADOW_RAT: {
		"name": "Shadow Rat",
		"description": "Small vermin that travels in packs.",
		"tier": Tier.MINION,
		"category": Category.SWARM,
		"behavior": BehaviorType.PACK_MOVEMENT,
		"hp": 2,
		"armor": 0,
		"speed": 1.3,
		"damage": 1,
		"gold": 1,
		"glyph": "r",
		"color": Color(0.4, 0.4, 0.5),
		"abilities": ["pack_spawn"],
		"pack_size": 3,
		"flavor": "Where there's one, there's many."
	},
	INK_BLOB: {
		"name": "Ink Blob",
		"description": "Leaves a slowing trail of void residue.",
		"tier": Tier.MINION,
		"category": Category.BASIC,
		"behavior": BehaviorType.DIRECT_ADVANCE,
		"hp": 4,
		"armor": 0,
		"speed": 0.8,
		"damage": 1,
		"gold": 2,
		"glyph": "b",
		"color": Color(0.2, 0.2, 0.3),
		"abilities": ["ink_trail"],
		"flavor": "Slow but inevitable."
	},
	GLITCH_SPRITE: {
		"name": "Glitch Sprite",
		"description": "Digital corruption that scrambles nearby text on death.",
		"tier": Tier.MINION,
		"category": Category.CASTER,
		"behavior": BehaviorType.DIRECT_ADVANCE,
		"hp": 2,
		"armor": 0,
		"speed": 1.1,
		"damage": 1,
		"gold": 2,
		"glyph": "g",
		"color": Color(0.0, 1.0, 0.8),
		"abilities": ["death_scramble"],
		"flavor": "Err0r: R3al1ty n0t f0und."
	},
	DUST_MOTE: {
		"name": "Dust Mote",
		"description": "Fragile creature that splits into smaller motes on death.",
		"tier": Tier.MINION,
		"category": Category.SWARM,
		"behavior": BehaviorType.DIRECT_ADVANCE,
		"hp": 2,
		"armor": 0,
		"speed": 1.4,
		"damage": 1,
		"gold": 1,
		"glyph": "d",
		"color": Color(0.8, 0.7, 0.5),
		"abilities": ["splitting"],
		"split_count": 2,
		"flavor": "One becomes many."
	},
	VOID_TICK: {
		"name": "Void Tick",
		"description": "Parasite that attaches to stronger enemies for protection.",
		"tier": Tier.MINION,
		"category": Category.SUPPORT,
		"behavior": BehaviorType.GUARDIAN,
		"hp": 3,
		"armor": 0,
		"speed": 1.1,
		"damage": 1,
		"gold": 1,
		"glyph": "v",
		"color": Color(0.5, 0.3, 0.4),
		"abilities": ["attach"],
		"flavor": "Safety in numbers."
	},
	SPARK_FLY: {
		"name": "Spark Fly",
		"description": "Explosive insect that detonates on contact.",
		"tier": Tier.MINION,
		"category": Category.BERSERKER,
		"behavior": BehaviorType.CHARGE_ATTACK,
		"hp": 1,
		"armor": 0,
		"speed": 2.0,
		"damage": 2,
		"gold": 2,
		"glyph": "s",
		"color": Color(1.0, 0.8, 0.2),
		"abilities": ["explosive"],
		"explosion_damage": 1,
		"flavor": "Fast, bright, gone."
	},

	# =========================================================================
	# TIER 2 - SOLDIERS (Base HP: 4-7, moderate threat)
	# =========================================================================
	TYPHOS_SCOUT: {
		"name": "Typhos Scout",
		"description": "Swift reconnaissance unit of the void forces.",
		"tier": Tier.SOLDIER,
		"category": Category.BASIC,
		"behavior": BehaviorType.DIRECT_ADVANCE,
		"hp": 5,
		"armor": 0,
		"speed": 1.0,
		"damage": 2,
		"gold": 3,
		"glyph": "S",
		"color": Color(0.5, 0.3, 0.7),
		"abilities": [],
		"flavor": "Eyes of the corruption."
	},
	CORRUPTED_ARCHER: {
		"name": "Corrupted Archer",
		"description": "Ranged attacker that stops to fire void arrows.",
		"tier": Tier.SOLDIER,
		"category": Category.RANGED,
		"behavior": BehaviorType.STOP_AND_ATTACK,
		"hp": 4,
		"armor": 0,
		"speed": 0.8,
		"damage": 2,
		"gold": 4,
		"glyph": "A",
		"color": Color(0.6, 0.5, 0.3),
		"abilities": ["ranged_attack"],
		"attack_range": 4,
		"attack_cooldown": 3.0,
		"flavor": "Death from afar."
	},
	VOID_HOUND: {
		"name": "Void Hound",
		"description": "Ferocious beast that grows faster when wounded.",
		"tier": Tier.SOLDIER,
		"category": Category.BERSERKER,
		"behavior": BehaviorType.CHARGE_ATTACK,
		"hp": 6,
		"armor": 0,
		"speed": 1.4,
		"damage": 2,
		"gold": 4,
		"glyph": "H",
		"color": Color(0.4, 0.2, 0.5),
		"abilities": ["blood_frenzy"],
		"speed_per_hp_lost": 0.2,
		"max_speed_bonus": 1.0,
		"flavor": "Pain only makes it hungrier."
	},
	SILENCE_ACOLYTE: {
		"name": "Silence Acolyte",
		"description": "Cultist whose presence muffles the world.",
		"tier": Tier.SOLDIER,
		"category": Category.CASTER,
		"behavior": BehaviorType.SUPPORT_CASTER,
		"hp": 4,
		"armor": 0,
		"speed": 0.9,
		"damage": 1,
		"gold": 4,
		"glyph": "X",
		"color": Color(0.3, 0.3, 0.4),
		"abilities": ["mute_aura"],
		"mute_radius": 2,
		"flavor": "Shhhh..."
	},
	RUSTED_KNIGHT: {
		"name": "Rusted Knight",
		"description": "Ancient warrior with degraded but still formidable armor.",
		"tier": Tier.SOLDIER,
		"category": Category.TANK,
		"behavior": BehaviorType.DIRECT_ADVANCE,
		"hp": 7,
		"armor": 1,
		"speed": 0.7,
		"damage": 2,
		"gold": 4,
		"glyph": "K",
		"color": Color(0.6, 0.4, 0.3),
		"abilities": ["rusty_armor"],
		"armor_decay_chance": 20,
		"flavor": "Once noble, now hollow."
	},
	SHADE_STALKER: {
		"name": "Shade Stalker",
		"description": "Shadow creature that phases in and out of visibility.",
		"tier": Tier.SOLDIER,
		"category": Category.STEALTH,
		"behavior": BehaviorType.STEALTH_ADVANCE,
		"hp": 4,
		"armor": 0,
		"speed": 1.1,
		"damage": 2,
		"gold": 4,
		"glyph": "Z",
		"color": Color(0.2, 0.2, 0.3),
		"abilities": ["shadow_cloak"],
		"cloak_duration": 2.0,
		"cloak_cooldown": 4.0,
		"flavor": "A shadow among shadows."
	},
	MARSH_LURKER: {
		"name": "Marsh Lurker",
		"description": "Swamp creature with poisonous attacks.",
		"tier": Tier.SOLDIER,
		"category": Category.BASIC,
		"behavior": BehaviorType.DIRECT_ADVANCE,
		"hp": 5,
		"armor": 0,
		"speed": 0.9,
		"damage": 2,
		"gold": 3,
		"glyph": "M",
		"color": Color(0.3, 0.5, 0.3),
		"abilities": ["poison_attack"],
		"poison_damage": 1,
		"poison_duration": 3.0,
		"flavor": "From the depths of the fen."
	},
	STONE_CRAWLER: {
		"name": "Stone Crawler",
		"description": "Armored insectoid that burrows through obstacles.",
		"tier": Tier.SOLDIER,
		"category": Category.TANK,
		"behavior": BehaviorType.DIRECT_ADVANCE,
		"hp": 6,
		"armor": 1,
		"speed": 0.6,
		"damage": 2,
		"gold": 4,
		"glyph": "C",
		"color": Color(0.5, 0.5, 0.4),
		"abilities": ["tunnel"],
		"tunnel_cooldown": 8.0,
		"flavor": "The mountain comes to you."
	},
	FLAME_DANCER: {
		"name": "Flame Dancer",
		"description": "Fire elemental leaving burning trails.",
		"tier": Tier.SOLDIER,
		"category": Category.BASIC,
		"behavior": BehaviorType.ERRATIC_PATH,
		"hp": 4,
		"armor": 0,
		"speed": 1.3,
		"damage": 2,
		"gold": 3,
		"glyph": "F",
		"color": Color(1.0, 0.5, 0.2),
		"abilities": ["fire_trail"],
		"trail_damage": 1,
		"trail_duration": 2.0,
		"flavor": "Dance of destruction."
	},
	WIND_RUNNER: {
		"name": "Wind Runner",
		"description": "Swift air elemental with high evasion.",
		"tier": Tier.SOLDIER,
		"category": Category.STEALTH,
		"behavior": BehaviorType.DIRECT_ADVANCE,
		"hp": 3,
		"armor": 0,
		"speed": 1.8,
		"damage": 1,
		"gold": 3,
		"glyph": "W",
		"color": Color(0.7, 0.8, 0.9),
		"abilities": ["dodge"],
		"dodge_chance": 30,
		"flavor": "Gone with the wind."
	},

	# =========================================================================
	# TIER 3 - ELITES (Base HP: 7-12, high threat)
	# =========================================================================
	TYPHOS_RAIDER: {
		"name": "Typhos Raider",
		"description": "Veteran void warrior with regenerating shields.",
		"tier": Tier.ELITE,
		"category": Category.TANK,
		"behavior": BehaviorType.DIRECT_ADVANCE,
		"hp": 10,
		"armor": 1,
		"speed": 0.9,
		"damage": 3,
		"gold": 8,
		"glyph": "R",
		"color": Color(0.5, 0.2, 0.6),
		"abilities": ["void_armor", "regeneration"],
		"regen_rate": 1,
		"flavor": "Forged in the void."
	},
	SHADOW_MAGE: {
		"name": "Shadow Mage",
		"description": "Dark caster that scrambles words and debuffs towers.",
		"tier": Tier.ELITE,
		"category": Category.CASTER,
		"behavior": BehaviorType.SUPPORT_CASTER,
		"hp": 7,
		"armor": 0,
		"speed": 0.7,
		"damage": 2,
		"gold": 10,
		"glyph": "M",
		"color": Color(0.3, 0.1, 0.4),
		"abilities": ["word_scramble", "tower_debuff"],
		"scramble_cooldown": 8.0,
		"debuff_range": 3,
		"flavor": "Reality bends to its will."
	},
	VOID_KNIGHT: {
		"name": "Void Knight",
		"description": "Heavy armored champion with a protective aura.",
		"tier": Tier.ELITE,
		"category": Category.TANK,
		"behavior": BehaviorType.GUARDIAN,
		"hp": 12,
		"armor": 2,
		"speed": 0.8,
		"damage": 3,
		"gold": 10,
		"glyph": "V",
		"color": Color(0.4, 0.3, 0.5),
		"sprite": "enemy_void_knight",
		"abilities": ["shield_aura"],
		"aura_radius": 2,
		"aura_armor_bonus": 1,
		"flavor": "Shield of the abyss."
	},
	CHAOS_BERSERKER: {
		"name": "Chaos Berserker",
		"description": "Frenzied warrior that enrages when damaged.",
		"tier": Tier.ELITE,
		"category": Category.BERSERKER,
		"behavior": BehaviorType.CHARGE_ATTACK,
		"hp": 9,
		"armor": 0,
		"speed": 1.0,
		"damage": 3,
		"gold": 8,
		"glyph": "B",
		"color": Color(0.8, 0.2, 0.2),
		"abilities": ["enrage"],
		"enrage_threshold": 0.5,
		"enrage_damage_bonus": 2,
		"enrage_speed_bonus": 0.5,
		"flavor": "Fury incarnate."
	},
	FROST_WEAVER: {
		"name": "Frost Weaver",
		"description": "Ice elemental that slows nearby towers.",
		"tier": Tier.ELITE,
		"category": Category.CASTER,
		"behavior": BehaviorType.DIRECT_ADVANCE,
		"hp": 8,
		"armor": 0,
		"speed": 0.75,
		"damage": 2,
		"gold": 9,
		"glyph": "I",
		"color": Color(0.6, 0.8, 1.0),
		"abilities": ["frost_aura"],
		"frost_radius": 3,
		"frost_slow_percent": 30,
		"flavor": "Winter's embrace."
	},
	PLAGUE_BEARER: {
		"name": "Plague Bearer",
		"description": "Toxic creature that poisons everything nearby.",
		"tier": Tier.ELITE,
		"category": Category.CASTER,
		"behavior": BehaviorType.DIRECT_ADVANCE,
		"hp": 11,
		"armor": 0,
		"speed": 0.6,
		"damage": 2,
		"gold": 9,
		"glyph": "P",
		"color": Color(0.4, 0.6, 0.2),
		"abilities": ["toxic_presence"],
		"toxic_radius": 2,
		"toxic_damage": 1,
		"flavor": "Breathe deep."
	},
	CRYSTAL_SENTINEL: {
		"name": "Crystal Sentinel",
		"description": "Crystalline guardian that reflects damage.",
		"tier": Tier.ELITE,
		"category": Category.TANK,
		"behavior": BehaviorType.DIRECT_ADVANCE,
		"hp": 10,
		"armor": 2,
		"speed": 0.7,
		"damage": 2,
		"gold": 10,
		"glyph": "Y",
		"color": Color(0.8, 0.9, 1.0),
		"abilities": ["damage_reflect"],
		"reflect_percent": 25,
		"flavor": "A mirror of pain."
	},
	STORM_CALLER: {
		"name": "Storm Caller",
		"description": "Lightning caster that calls down strikes.",
		"tier": Tier.ELITE,
		"category": Category.CASTER,
		"behavior": BehaviorType.STOP_AND_ATTACK,
		"hp": 8,
		"armor": 0,
		"speed": 0.8,
		"damage": 3,
		"gold": 10,
		"glyph": "L",
		"color": Color(0.7, 0.7, 1.0),
		"abilities": ["lightning_strike"],
		"strike_cooldown": 5.0,
		"strike_damage": 2,
		"flavor": "Thunder follows."
	},

	# =========================================================================
	# TIER 4 - CHAMPIONS (Base HP: 15-25, extreme threat)
	# =========================================================================
	TYPHOS_LORD: {
		"name": "Typhos Lord",
		"description": "Commander of the void forces that summons minions.",
		"tier": Tier.CHAMPION,
		"category": Category.COMMANDER,
		"behavior": BehaviorType.COMMANDER_LEAD,
		"hp": 18,
		"armor": 1,
		"speed": 0.6,
		"damage": 4,
		"gold": 25,
		"glyph": "T",
		"color": Color(0.6, 0.3, 0.8),
		"sprite": "enemy_typhos_lord",
		"abilities": ["summon_spawn", "command_aura"],
		"summon_cooldown": 10.0,
		"summon_count": 2,
		"aura_radius": 3,
		"flavor": "The void speaks through it."
	},
	CORRUPTED_GIANT: {
		"name": "Corrupted Giant",
		"description": "Massive creature with devastating ground pounds.",
		"tier": Tier.CHAMPION,
		"category": Category.SIEGE,
		"behavior": BehaviorType.SIEGE_MODE,
		"hp": 25,
		"armor": 2,
		"speed": 0.4,
		"damage": 5,
		"gold": 30,
		"glyph": "G",
		"color": Color(0.5, 0.4, 0.3),
		"abilities": ["ground_pound"],
		"pound_cooldown": 12.0,
		"pound_stun_duration": 2.0,
		"pound_radius": 2,
		"flavor": "The earth trembles."
	},
	VOID_ASSASSIN: {
		"name": "Void Assassin",
		"description": "Shadow striker that teleports past defenses.",
		"tier": Tier.CHAMPION,
		"category": Category.STEALTH,
		"behavior": BehaviorType.TELEPORTER,
		"hp": 15,
		"armor": 0,
		"speed": 1.0,
		"damage": 4,
		"gold": 25,
		"glyph": "N",
		"color": Color(0.2, 0.1, 0.3),
		"abilities": ["shadow_step"],
		"teleport_cooldown": 6.0,
		"teleport_distance": 3,
		"flavor": "Death comes unseen."
	},
	WARLORD: {
		"name": "Warlord",
		"description": "Battle commander that inspires nearby allies.",
		"tier": Tier.CHAMPION,
		"category": Category.COMMANDER,
		"behavior": BehaviorType.COMMANDER_LEAD,
		"hp": 22,
		"armor": 1,
		"speed": 0.7,
		"damage": 4,
		"gold": 28,
		"glyph": "O",
		"color": Color(0.7, 0.3, 0.3),
		"abilities": ["war_banner"],
		"banner_radius": 4,
		"banner_damage_bonus": 50,
		"banner_speed_bonus": 25,
		"flavor": "Victory or death!"
	},
	ARCANE_HORROR: {
		"name": "Arcane Horror",
		"description": "Eldritch being that drains tower power.",
		"tier": Tier.CHAMPION,
		"category": Category.CASTER,
		"behavior": BehaviorType.SUPPORT_CASTER,
		"hp": 16,
		"armor": 0,
		"speed": 0.5,
		"damage": 3,
		"gold": 26,
		"glyph": "E",
		"color": Color(0.5, 0.2, 0.7),
		"abilities": ["mana_drain", "arcane_blast"],
		"drain_cooldown": 8.0,
		"drain_duration": 4.0,
		"blast_cooldown": 10.0,
		"flavor": "Knowledge is power."
	},
	TREANT_ANCIENT: {
		"name": "Treant Ancient",
		"description": "Ancient tree spirit with massive regeneration.",
		"tier": Tier.CHAMPION,
		"category": Category.TANK,
		"behavior": BehaviorType.GUARDIAN,
		"hp": 20,
		"armor": 1,
		"speed": 0.5,
		"damage": 3,
		"gold": 24,
		"glyph": "Q",
		"color": Color(0.3, 0.5, 0.2),
		"abilities": ["mass_regeneration", "root_snare"],
		"regen_rate": 2,
		"regen_radius": 3,
		"snare_cooldown": 10.0,
		"flavor": "The forest remembers."
	}
}

# =============================================================================
# TIER COLORS (for UI)
# =============================================================================

const TIER_COLORS: Dictionary = {
	Tier.MINION: Color(0.6, 0.6, 0.6),      # Gray
	Tier.SOLDIER: Color(0.3, 0.7, 0.3),     # Green
	Tier.ELITE: Color(0.3, 0.5, 0.9),       # Blue
	Tier.CHAMPION: Color(0.8, 0.5, 0.9),    # Purple
	Tier.BOSS: Color(1.0, 0.5, 0.2)         # Orange
}

const CATEGORY_COLORS: Dictionary = {
	Category.BASIC: Color(0.7, 0.7, 0.7),
	Category.SWARM: Color(0.6, 0.5, 0.3),
	Category.RANGED: Color(0.5, 0.7, 0.4),
	Category.STEALTH: Color(0.4, 0.4, 0.5),
	Category.SUPPORT: Color(0.5, 0.8, 0.5),
	Category.TANK: Color(0.6, 0.5, 0.4),
	Category.BERSERKER: Color(0.8, 0.3, 0.3),
	Category.CASTER: Color(0.6, 0.4, 0.8),
	Category.COMMANDER: Color(0.8, 0.6, 0.3),
	Category.SIEGE: Color(0.5, 0.4, 0.3)
}

# =============================================================================
# TIER UNLOCK BY DAY
# =============================================================================

const TIER_UNLOCK_DAYS: Dictionary = {
	Tier.MINION: 1,
	Tier.SOLDIER: 3,
	Tier.ELITE: 7,
	Tier.CHAMPION: 15
}

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

static func get_enemy(enemy_id: String) -> Dictionary:
	return ENEMIES.get(enemy_id, {})


static func get_name(enemy_id: String) -> String:
	return str(ENEMIES.get(enemy_id, {}).get("name", enemy_id))


static func get_tier(enemy_id: String) -> int:
	return int(ENEMIES.get(enemy_id, {}).get("tier", Tier.MINION))


static func get_category(enemy_id: String) -> int:
	return int(ENEMIES.get(enemy_id, {}).get("category", Category.BASIC))


static func get_hp(enemy_id: String) -> int:
	return int(ENEMIES.get(enemy_id, {}).get("hp", 3))


static func get_armor(enemy_id: String) -> int:
	return int(ENEMIES.get(enemy_id, {}).get("armor", 0))


static func get_speed(enemy_id: String) -> float:
	return float(ENEMIES.get(enemy_id, {}).get("speed", 1.0))


static func get_damage(enemy_id: String) -> int:
	return int(ENEMIES.get(enemy_id, {}).get("damage", 1))


static func get_gold(enemy_id: String) -> int:
	return int(ENEMIES.get(enemy_id, {}).get("gold", 1))


static func get_abilities(enemy_id: String) -> Array:
	return ENEMIES.get(enemy_id, {}).get("abilities", [])


static func get_glyph(enemy_id: String) -> String:
	return str(ENEMIES.get(enemy_id, {}).get("glyph", "?"))


static func get_color(enemy_id: String) -> Color:
	return ENEMIES.get(enemy_id, {}).get("color", Color.WHITE)


static func get_all_enemy_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in ENEMIES.keys():
		ids.append(str(key))
	return ids


static func get_enemies_by_tier(tier: int) -> Array[String]:
	var result: Array[String] = []
	for key in ENEMIES.keys():
		if int(ENEMIES[key].get("tier", 0)) == tier:
			result.append(str(key))
	return result


static func get_enemies_by_category(category: int) -> Array[String]:
	var result: Array[String] = []
	for key in ENEMIES.keys():
		if int(ENEMIES[key].get("category", 0)) == category:
			result.append(str(key))
	return result


static func get_available_tiers_for_day(day: int) -> Array[int]:
	var available: Array[int] = []
	for tier in TIER_UNLOCK_DAYS.keys():
		if day >= int(TIER_UNLOCK_DAYS[tier]):
			available.append(int(tier))
	return available


static func get_available_enemies_for_day(day: int) -> Array[String]:
	var available_tiers: Array[int] = get_available_tiers_for_day(day)
	var result: Array[String] = []
	for tier in available_tiers:
		result.append_array(get_enemies_by_tier(tier))
	return result


static func has_ability(enemy_id: String, ability_id: String) -> bool:
	var abilities: Array = get_abilities(enemy_id)
	return ability_id in abilities


static func is_valid(enemy_id: String) -> bool:
	return ENEMIES.has(enemy_id) or REGIONAL_VARIANTS.has(enemy_id)


# =============================================================================
# REGIONAL VARIANT IDS
# =============================================================================

# Evergrove Forest variants
const FOREST_IMP := "forest_imp"
const CORRUPTED_DEER := "corrupted_deer"
const TREANT_SHAMBLER := "treant_shambler"
const VINE_HORROR := "vine_horror"

# Stonepass Mountains variants
const CAVE_CRAWLER := "cave_crawler"
const STONE_SENTINEL := "stone_sentinel"
const CRYSTAL_HORROR := "crystal_horror"
const MAGMA_ELEMENTAL := "magma_elemental"

# Mistfen Marshes variants
const BOG_CREEPER := "bog_creeper"
const MARSH_STALKER := "marsh_stalker"
const FEN_WITCH := "fen_witch"
const SWAMP_HYDRA := "swamp_hydra"

# Sunfields Plains variants
const DUST_DEVIL := "dust_devil"
const PLAINS_MARAUDER := "plains_marauder"
const SUNSCORCHED_WARRIOR := "sunscorched_warrior"
const SAND_WYRM := "sand_wyrm"

# =============================================================================
# REGIONAL VARIANT DEFINITIONS
# =============================================================================

const REGIONAL_VARIANTS: Dictionary = {
	# =========================================================================
	# EVERGROVE FOREST (Region.EVERGROVE)
	# Nature-themed enemies, forest creatures, plant monsters
	# =========================================================================
	FOREST_IMP: {
		"name": "Forest Imp",
		"description": "Mischievous forest sprite that throws acorns.",
		"tier": Tier.MINION,
		"category": Category.RANGED,
		"behavior": BehaviorType.ERRATIC_PATH,
		"region": Region.EVERGROVE,
		"base_type": TYPHOS_SPAWN,  # Regional variant of
		"hp": 3,
		"armor": 0,
		"speed": 1.3,
		"damage": 1,
		"gold": 2,
		"glyph": "i",
		"color": Color(0.3, 0.6, 0.2),
		"abilities": ["ranged_attack"],
		"attack_range": 2,
		"flavor": "The forest's little terrors."
	},
	CORRUPTED_DEER: {
		"name": "Corrupted Deer",
		"description": "Once peaceful herbivore, now twisted by corruption.",
		"tier": Tier.SOLDIER,
		"category": Category.BERSERKER,
		"behavior": BehaviorType.CHARGE_ATTACK,
		"region": Region.EVERGROVE,
		"base_type": VOID_HOUND,
		"hp": 5,
		"armor": 0,
		"speed": 1.5,
		"damage": 2,
		"gold": 4,
		"glyph": "D",
		"color": Color(0.4, 0.5, 0.3),
		"abilities": ["blood_frenzy"],
		"flavor": "Its antlers drip with corruption."
	},
	TREANT_SHAMBLER: {
		"name": "Treant Shambler",
		"description": "Corrupted tree spirit with thick bark armor.",
		"tier": Tier.ELITE,
		"category": Category.TANK,
		"behavior": BehaviorType.DIRECT_ADVANCE,
		"region": Region.EVERGROVE,
		"base_type": VOID_KNIGHT,
		"hp": 14,
		"armor": 2,
		"speed": 0.5,
		"damage": 3,
		"gold": 12,
		"glyph": "T",
		"color": Color(0.3, 0.4, 0.2),
		"abilities": ["regeneration", "root_snare"],
		"flavor": "The forest walks."
	},
	VINE_HORROR: {
		"name": "Vine Horror",
		"description": "Writhing mass of corrupted vines that entangles defenses.",
		"tier": Tier.CHAMPION,
		"category": Category.CASTER,
		"behavior": BehaviorType.SUPPORT_CASTER,
		"region": Region.EVERGROVE,
		"base_type": ARCANE_HORROR,
		"hp": 18,
		"armor": 1,
		"speed": 0.4,
		"damage": 2,
		"gold": 25,
		"glyph": "V",
		"color": Color(0.2, 0.5, 0.1),
		"abilities": ["root_snare", "mass_regeneration"],
		"flavor": "Where it walks, the forest follows."
	},

	# =========================================================================
	# STONEPASS MOUNTAINS (Region.STONEPASS)
	# Rock/crystal enemies, earth elementals, miners
	# =========================================================================
	CAVE_CRAWLER: {
		"name": "Cave Crawler",
		"description": "Subterranean insect with crystal-hard shell.",
		"tier": Tier.MINION,
		"category": Category.TANK,
		"behavior": BehaviorType.DIRECT_ADVANCE,
		"region": Region.STONEPASS,
		"base_type": INK_BLOB,
		"hp": 5,
		"armor": 1,
		"speed": 0.7,
		"damage": 1,
		"gold": 2,
		"glyph": "c",
		"color": Color(0.5, 0.4, 0.4),
		"abilities": ["tunnel"],
		"flavor": "Skitters through the dark."
	},
	STONE_SENTINEL: {
		"name": "Stone Sentinel",
		"description": "Ancient guardian of the mountain passes.",
		"tier": Tier.SOLDIER,
		"category": Category.TANK,
		"behavior": BehaviorType.GUARDIAN,
		"region": Region.STONEPASS,
		"base_type": RUSTED_KNIGHT,
		"hp": 8,
		"armor": 2,
		"speed": 0.5,
		"damage": 2,
		"gold": 5,
		"glyph": "S",
		"color": Color(0.6, 0.6, 0.5),
		"abilities": ["shield_aura"],
		"flavor": "Immovable as the mountain itself."
	},
	CRYSTAL_HORROR: {
		"name": "Crystal Horror",
		"description": "Living crystal formation that reflects damage.",
		"tier": Tier.ELITE,
		"category": Category.TANK,
		"behavior": BehaviorType.DIRECT_ADVANCE,
		"region": Region.STONEPASS,
		"base_type": CRYSTAL_SENTINEL,
		"hp": 12,
		"armor": 3,
		"speed": 0.6,
		"damage": 2,
		"gold": 12,
		"glyph": "Y",
		"color": Color(0.7, 0.8, 0.9),
		"abilities": ["damage_reflect", "splitting"],
		"split_type": "cave_crawler",
		"flavor": "Beautiful and deadly."
	},
	MAGMA_ELEMENTAL: {
		"name": "Magma Elemental",
		"description": "Creature of molten rock from deep within the mountain.",
		"tier": Tier.CHAMPION,
		"category": Category.SIEGE,
		"behavior": BehaviorType.SIEGE_MODE,
		"region": Region.STONEPASS,
		"base_type": CORRUPTED_GIANT,
		"hp": 22,
		"armor": 2,
		"speed": 0.4,
		"damage": 4,
		"gold": 28,
		"glyph": "M",
		"color": Color(1.0, 0.4, 0.1),
		"abilities": ["fire_trail", "ground_pound"],
		"flavor": "The mountain's fury unleashed."
	},

	# =========================================================================
	# MISTFEN MARSHES (Region.MISTFEN)
	# Poison/disease enemies, swamp creatures, undead
	# =========================================================================
	BOG_CREEPER: {
		"name": "Bog Creeper",
		"description": "Slow but poisonous swamp creature.",
		"tier": Tier.MINION,
		"category": Category.BASIC,
		"behavior": BehaviorType.DIRECT_ADVANCE,
		"region": Region.MISTFEN,
		"base_type": INK_BLOB,
		"hp": 4,
		"armor": 0,
		"speed": 0.7,
		"damage": 1,
		"gold": 2,
		"glyph": "b",
		"color": Color(0.3, 0.4, 0.2),
		"abilities": ["poison_attack", "ink_trail"],
		"flavor": "The swamp seeps into everything."
	},
	MARSH_STALKER: {
		"name": "Marsh Stalker",
		"description": "Predator that hunts in the mist.",
		"tier": Tier.SOLDIER,
		"category": Category.STEALTH,
		"behavior": BehaviorType.STEALTH_ADVANCE,
		"region": Region.MISTFEN,
		"base_type": SHADE_STALKER,
		"hp": 5,
		"armor": 0,
		"speed": 1.0,
		"damage": 3,
		"gold": 5,
		"glyph": "m",
		"color": Color(0.3, 0.4, 0.3),
		"abilities": ["shadow_cloak", "poison_attack"],
		"flavor": "You'll never see it coming."
	},
	FEN_WITCH: {
		"name": "Fen Witch",
		"description": "Dark caster dwelling in the swamp depths.",
		"tier": Tier.ELITE,
		"category": Category.CASTER,
		"behavior": BehaviorType.SUPPORT_CASTER,
		"region": Region.MISTFEN,
		"base_type": SHADOW_MAGE,
		"hp": 8,
		"armor": 0,
		"speed": 0.6,
		"damage": 2,
		"gold": 11,
		"glyph": "W",
		"color": Color(0.4, 0.5, 0.3),
		"abilities": ["toxic_presence", "word_scramble", "healing_burst"],
		"flavor": "Her curses foul the very air."
	},
	SWAMP_HYDRA: {
		"name": "Swamp Hydra",
		"description": "Multi-headed terror of the marshes that regenerates.",
		"tier": Tier.CHAMPION,
		"category": Category.TANK,
		"behavior": BehaviorType.DIRECT_ADVANCE,
		"region": Region.MISTFEN,
		"base_type": TREANT_ANCIENT,
		"hp": 24,
		"armor": 1,
		"speed": 0.5,
		"damage": 4,
		"gold": 30,
		"glyph": "H",
		"color": Color(0.2, 0.4, 0.3),
		"abilities": ["mass_regeneration", "splitting", "toxic_presence"],
		"split_type": "bog_creeper",
		"flavor": "Cut off one head..."
	},

	# =========================================================================
	# SUNFIELDS PLAINS (Region.SUNFIELDS)
	# Fire/light enemies, nomadic warriors, desert creatures
	# =========================================================================
	DUST_DEVIL: {
		"name": "Dust Devil",
		"description": "Whirling sand elemental that blinds defenses.",
		"tier": Tier.MINION,
		"category": Category.CASTER,
		"behavior": BehaviorType.ERRATIC_PATH,
		"region": Region.SUNFIELDS,
		"base_type": VOID_WISP,
		"hp": 2,
		"armor": 0,
		"speed": 1.6,
		"damage": 1,
		"gold": 2,
		"glyph": "d",
		"color": Color(0.8, 0.7, 0.5),
		"abilities": ["mute_aura", "dodge"],
		"flavor": "The wind made manifest."
	},
	PLAINS_MARAUDER: {
		"name": "Plains Marauder",
		"description": "Mounted raider from the sunbaked steppes.",
		"tier": Tier.SOLDIER,
		"category": Category.BERSERKER,
		"behavior": BehaviorType.CHARGE_ATTACK,
		"region": Region.SUNFIELDS,
		"base_type": VOID_HOUND,
		"hp": 6,
		"armor": 0,
		"speed": 1.6,
		"damage": 2,
		"gold": 5,
		"glyph": "P",
		"color": Color(0.7, 0.5, 0.3),
		"abilities": ["blood_frenzy"],
		"flavor": "Strike fast, strike hard."
	},
	SUNSCORCHED_WARRIOR: {
		"name": "Sunscorched Warrior",
		"description": "Undead warrior animated by the blazing sun.",
		"tier": Tier.ELITE,
		"category": Category.BERSERKER,
		"behavior": BehaviorType.CHARGE_ATTACK,
		"region": Region.SUNFIELDS,
		"base_type": CHAOS_BERSERKER,
		"hp": 10,
		"armor": 1,
		"speed": 1.1,
		"damage": 4,
		"gold": 10,
		"glyph": "U",
		"color": Color(0.9, 0.6, 0.2),
		"abilities": ["enrage", "fire_trail"],
		"flavor": "The sun's relentless fury."
	},
	SAND_WYRM: {
		"name": "Sand Wyrm",
		"description": "Enormous desert serpent that burrows beneath the sands.",
		"tier": Tier.CHAMPION,
		"category": Category.SIEGE,
		"behavior": BehaviorType.SIEGE_MODE,
		"region": Region.SUNFIELDS,
		"base_type": CORRUPTED_GIANT,
		"hp": 20,
		"armor": 2,
		"speed": 0.6,
		"damage": 5,
		"gold": 28,
		"glyph": "W",
		"color": Color(0.8, 0.7, 0.4),
		"abilities": ["tunnel", "ground_pound"],
		"tunnel_distance": 4,
		"flavor": "The sand itself hungers."
	}
}

# =============================================================================
# REGIONAL VARIANT HELPERS
# =============================================================================

static func get_regional_enemy(enemy_id: String) -> Dictionary:
	return REGIONAL_VARIANTS.get(enemy_id, {})


static func get_all_regional_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in REGIONAL_VARIANTS.keys():
		ids.append(str(key))
	return ids


static func get_regional_enemies_by_region(region: int) -> Array[String]:
	var result: Array[String] = []
	for key in REGIONAL_VARIANTS.keys():
		if int(REGIONAL_VARIANTS[key].get("region", 0)) == region:
			result.append(str(key))
	return result


static func get_base_enemy_for_variant(variant_id: String) -> String:
	return str(REGIONAL_VARIANTS.get(variant_id, {}).get("base_type", ""))


static func get_variant_for_base(base_id: String, region: int) -> String:
	for key in REGIONAL_VARIANTS.keys():
		var variant: Dictionary = REGIONAL_VARIANTS[key]
		if str(variant.get("base_type", "")) == base_id and int(variant.get("region", 0)) == region:
			return str(key)
	return ""


static func get_region_name(region: int) -> String:
	match region:
		Region.ALL:
			return "All Regions"
		Region.EVERGROVE:
			return "Evergrove Forest"
		Region.STONEPASS:
			return "Stonepass Mountains"
		Region.MISTFEN:
			return "Mistfen Marshes"
		Region.SUNFIELDS:
			return "Sunfields Plains"
	return "Unknown"


static func get_region_color(region: int) -> Color:
	match region:
		Region.EVERGROVE:
			return Color(0.3, 0.6, 0.2)  # Forest green
		Region.STONEPASS:
			return Color(0.5, 0.5, 0.5)  # Stone gray
		Region.MISTFEN:
			return Color(0.3, 0.4, 0.4)  # Murky teal
		Region.SUNFIELDS:
			return Color(0.9, 0.7, 0.3)  # Sun gold
	return Color.WHITE


## Get enemy data from either base types or regional variants
static func get_any_enemy(enemy_id: String) -> Dictionary:
	if ENEMIES.has(enemy_id):
		return ENEMIES[enemy_id]
	if REGIONAL_VARIANTS.has(enemy_id):
		return REGIONAL_VARIANTS[enemy_id]
	return {}


## Get all enemy IDs (base + regional)
static func get_all_ids() -> Array[String]:
	var ids: Array[String] = get_all_enemy_ids()
	ids.append_array(get_all_regional_ids())
	return ids
