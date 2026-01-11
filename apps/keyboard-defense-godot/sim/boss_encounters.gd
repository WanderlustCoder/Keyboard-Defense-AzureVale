class_name SimBossEncounters
extends RefCounted
## Boss Encounter System - Multi-phase boss fights with mechanics and dialogue

const SimEnemyTypes = preload("res://sim/enemy_types.gd")
const SimEnemyAbilities = preload("res://sim/enemy_abilities.gd")

# =============================================================================
# BOSS IDS
# =============================================================================

const GROVE_GUARDIAN := "grove_guardian"
const MOUNTAIN_KING := "mountain_king"
const FEN_SEER := "fen_seer"
const SUNLORD := "sunlord"

# =============================================================================
# BOSS DEFINITIONS
# =============================================================================

const BOSSES: Dictionary = {
	# =========================================================================
	# GROVE GUARDIAN - Evergrove Forest Boss (Day 7)
	# Nature-themed, regeneration, summons treants
	# =========================================================================
	GROVE_GUARDIAN: {
		"name": "Grove Guardian",
		"title": "Ancient Protector of Evergrove",
		"description": "A massive treant corrupted by void energy. Once protected the forest, now seeks to consume it.",
		"region": SimEnemyTypes.Region.EVERGROVE,
		"unlock_day": 7,
		"hp": 50,
		"armor": 2,
		"speed": 0.3,
		"damage": 4,
		"gold": 100,
		"glyph": "G",
		"color": Color(0.2, 0.5, 0.2),
		"phases": 2,
		"phase_thresholds": [0.5],  # Phase 2 at 50% HP
		"abilities": ["mass_regeneration", "root_snare", "summon_treants"],
		"flavor": "The forest's heart beats with corruption.",

		# Phase-specific data
		"phase_data": {
			1: {
				"name": "Guardian's Vigil",
				"abilities": ["mass_regeneration", "root_snare"],
				"regen_rate": 2,
				"snare_cooldown": 8.0
			},
			2: {
				"name": "Nature's Wrath",
				"abilities": ["mass_regeneration", "root_snare", "summon_treants"],
				"regen_rate": 3,
				"snare_cooldown": 5.0,
				"summon_cooldown": 12.0,
				"summon_count": 2,
				"summon_type": "treant_shambler"
			}
		},

		# Dialogue
		"dialogue": {
			"intro": [
				"The Grove Guardian awakens...",
				"\"You dare tread upon my forest?\"",
				"\"The corruption has shown me the truth.\"",
				"\"All must return to the void!\""
			],
			"phase_2": [
				"The Guardian's eyes glow with void energy!",
				"\"Enough! The forest itself shall consume you!\"",
				"Roots burst from the ground as treants rise to defend their master!"
			],
			"defeat": [
				"The Guardian staggers, the corruption fading from its eyes.",
				"\"Free... at last... protect... the forest...\"",
				"The ancient treant crumbles, leaving behind crystallized sap."
			]
		}
	},

	# =========================================================================
	# MOUNTAIN KING - Stonepass Mountains Boss (Day 14)
	# Earth-themed, armored, ground pounds, crystal shields
	# =========================================================================
	MOUNTAIN_KING: {
		"name": "Mountain King",
		"title": "Lord of the Stone Depths",
		"description": "An ancient stone golem infused with corrupted crystal energy. Commands the earth itself.",
		"region": SimEnemyTypes.Region.STONEPASS,
		"unlock_day": 14,
		"hp": 75,
		"armor": 4,
		"speed": 0.25,
		"damage": 5,
		"gold": 150,
		"glyph": "K",
		"color": Color(0.5, 0.5, 0.6),
		"phases": 3,
		"phase_thresholds": [0.66, 0.33],  # Phase 2 at 66%, Phase 3 at 33%
		"abilities": ["ground_pound", "crystal_barrier", "summon_sentinels"],
		"flavor": "The mountain itself marches against you.",

		"phase_data": {
			1: {
				"name": "Stone Advance",
				"abilities": ["ground_pound"],
				"pound_cooldown": 10.0,
				"pound_radius": 2
			},
			2: {
				"name": "Crystal Defense",
				"abilities": ["ground_pound", "crystal_barrier"],
				"pound_cooldown": 8.0,
				"barrier_cooldown": 15.0,
				"barrier_duration": 5.0
			},
			3: {
				"name": "Mountain's Fury",
				"abilities": ["ground_pound", "crystal_barrier", "summon_sentinels"],
				"pound_cooldown": 6.0,
				"barrier_cooldown": 12.0,
				"summon_cooldown": 10.0,
				"summon_count": 3,
				"summon_type": "stone_sentinel"
			}
		},

		"dialogue": {
			"intro": [
				"The ground trembles as something massive approaches...",
				"The Mountain King rises from the stone!",
				"\"INTRUDER. THE MOUNTAIN DOES NOT FORGET.\"",
				"\"YOU SHALL BECOME ONE WITH THE STONE.\""
			],
			"phase_2": [
				"Crystals erupt from the King's body!",
				"\"MY ARMOR IS THE MOUNTAIN ITSELF!\"",
				"A shimmering barrier surrounds the colossus!"
			],
			"phase_3": [
				"The Mountain King slams the ground in fury!",
				"\"RISE, MY CHILDREN! DEFEND YOUR KING!\"",
				"Stone Sentinels claw their way from the earth!"
			],
			"defeat": [
				"Cracks spread across the Mountain King's form.",
				"\"THE... MOUNTAIN... ENDURES...\"",
				"The colossus crumbles, revealing a heart of pure crystal."
			]
		}
	},

	# =========================================================================
	# FEN SEER - Mistfen Marshes Boss (Day 21)
	# Poison/magic-themed, word scrambling, illusions
	# =========================================================================
	FEN_SEER: {
		"name": "Fen Seer",
		"title": "Witch of the Endless Mist",
		"description": "A powerful witch who commands the swamp's dark magic. Her gaze pierces reality itself.",
		"region": SimEnemyTypes.Region.MISTFEN,
		"unlock_day": 21,
		"hp": 60,
		"armor": 1,
		"speed": 0.35,
		"damage": 3,
		"gold": 175,
		"glyph": "S",
		"color": Color(0.4, 0.5, 0.4),
		"phases": 3,
		"phase_thresholds": [0.66, 0.33],
		"abilities": ["word_scramble", "toxic_cloud", "summon_illusions", "mist_veil"],
		"flavor": "She sees all futures, and in all of them, you fall.",

		"phase_data": {
			1: {
				"name": "Whispers of Madness",
				"abilities": ["word_scramble", "toxic_cloud"],
				"scramble_cooldown": 8.0,
				"cloud_cooldown": 12.0,
				"cloud_radius": 3
			},
			2: {
				"name": "Veiled in Mist",
				"abilities": ["word_scramble", "toxic_cloud", "mist_veil"],
				"scramble_cooldown": 6.0,
				"cloud_cooldown": 10.0,
				"veil_duration": 3.0,
				"veil_cooldown": 10.0
			},
			3: {
				"name": "Reality Unravels",
				"abilities": ["word_scramble", "toxic_cloud", "mist_veil", "summon_illusions"],
				"scramble_cooldown": 4.0,
				"cloud_cooldown": 8.0,
				"illusion_count": 3,
				"illusion_cooldown": 15.0
			}
		},

		"dialogue": {
			"intro": [
				"A cackling laugh echoes through the mist...",
				"\"Foolish child, to wander into my domain.\"",
				"The Fen Seer materializes from the swamp vapors!",
				"\"I have foreseen your arrival... and your demise.\""
			],
			"phase_2": [
				"The mist grows thick, obscuring everything!",
				"\"Can you trust your eyes? Can you trust your words?\"",
				"Reality itself seems to waver and shift!"
			],
			"phase_3": [
				"Multiple Fen Seers appear throughout the marsh!",
				"\"Which of us is real? ALL of us! NONE of us!\"",
				"Her laughter splits into a maddening chorus!"
			],
			"defeat": [
				"The illusions shatter like broken mirrors.",
				"\"Impossible... I saw... I SAW...\"",
				"The Fen Seer dissolves into mist, leaving behind a crystallized eye."
			]
		}
	},

	# =========================================================================
	# SUNLORD - Sunfields Plains Boss (Day 28)
	# Fire/light-themed, solar flares, burning ground
	# =========================================================================
	SUNLORD: {
		"name": "Sunlord",
		"title": "Blazing Tyrant of the Plains",
		"description": "An ancient warrior-king risen from the sands, empowered by corrupted solar energy.",
		"region": SimEnemyTypes.Region.SUNFIELDS,
		"unlock_day": 28,
		"hp": 80,
		"armor": 2,
		"speed": 0.4,
		"damage": 6,
		"gold": 200,
		"glyph": "L",
		"color": Color(1.0, 0.6, 0.1),
		"phases": 3,
		"phase_thresholds": [0.66, 0.33],
		"abilities": ["solar_flare", "burning_ground", "war_banner", "summon_marauders"],
		"flavor": "The sun itself kneels before him.",

		"phase_data": {
			1: {
				"name": "Solar Radiance",
				"abilities": ["solar_flare", "war_banner"],
				"flare_cooldown": 10.0,
				"flare_damage": 3,
				"banner_radius": 5
			},
			2: {
				"name": "Burning Conquest",
				"abilities": ["solar_flare", "war_banner", "burning_ground"],
				"flare_cooldown": 8.0,
				"ground_cooldown": 12.0,
				"ground_duration": 5.0
			},
			3: {
				"name": "Endless Summer",
				"abilities": ["solar_flare", "war_banner", "burning_ground", "summon_marauders"],
				"flare_cooldown": 6.0,
				"flare_damage": 4,
				"summon_cooldown": 10.0,
				"summon_count": 2,
				"summon_type": "plains_marauder"
			}
		},

		"dialogue": {
			"intro": [
				"The air shimmers with unbearable heat...",
				"A figure rises from the blazing sands!",
				"\"BOW BEFORE THE ETERNAL SUN!\"",
				"\"I am the light that burns all shadows!\""
			],
			"phase_2": [
				"The ground beneath your feet begins to glow!",
				"\"Feel the wrath of a thousand suns!\"",
				"Flames erupt across the battlefield!"
			],
			"phase_3": [
				"War horns sound across the plains!",
				"\"MY WARRIORS! TO ME!\"",
				"Sunscorched Marauders charge from the horizon!"
			],
			"defeat": [
				"The Sunlord's flames begin to dim.",
				"\"The sun... sets... but will... rise... again...\"",
				"His crown clatters to the ground, still glowing with power."
			]
		}
	}
}

# =============================================================================
# BOSS MECHANICS
# =============================================================================

const BOSS_MECHANICS: Dictionary = {
	# Crystal barrier - temporary invulnerability
	"crystal_barrier": {
		"name": "Crystal Barrier",
		"type": SimEnemyAbilities.AbilityType.COOLDOWN,
		"description": "Becomes invulnerable for {duration}s.",
		"effect": "invulnerability",
		"cooldown": 15.0,
		"duration": 5.0
	},

	# Summon treants - Evergrove
	"summon_treants": {
		"name": "Summon Treants",
		"type": SimEnemyAbilities.AbilityType.COOLDOWN,
		"description": "Summons {count} Treant Shamblers.",
		"effect": "summon",
		"cooldown": 12.0,
		"count": 2,
		"summon_type": "treant_shambler"
	},

	# Summon sentinels - Stonepass
	"summon_sentinels": {
		"name": "Summon Sentinels",
		"type": SimEnemyAbilities.AbilityType.COOLDOWN,
		"description": "Summons {count} Stone Sentinels.",
		"effect": "summon",
		"cooldown": 10.0,
		"count": 3,
		"summon_type": "stone_sentinel"
	},

	# Toxic cloud - Mistfen
	"toxic_cloud": {
		"name": "Toxic Cloud",
		"type": SimEnemyAbilities.AbilityType.COOLDOWN,
		"description": "Creates a poisonous cloud that damages towers.",
		"effect": "hazard_zone",
		"cooldown": 10.0,
		"radius": 3,
		"damage": 1,
		"duration": 5.0
	},

	# Mist veil - Mistfen
	"mist_veil": {
		"name": "Mist Veil",
		"type": SimEnemyAbilities.AbilityType.COOLDOWN,
		"description": "Becomes untargetable for {duration}s.",
		"effect": "phase_out",
		"cooldown": 10.0,
		"duration": 3.0
	},

	# Summon illusions - Mistfen
	"summon_illusions": {
		"name": "Summon Illusions",
		"type": SimEnemyAbilities.AbilityType.COOLDOWN,
		"description": "Creates {count} illusion copies.",
		"effect": "create_illusions",
		"cooldown": 15.0,
		"count": 3,
		"illusion_hp": 1
	},

	# Solar flare - Sunfields
	"solar_flare": {
		"name": "Solar Flare",
		"type": SimEnemyAbilities.AbilityType.COOLDOWN,
		"description": "Deals {damage} damage to all towers.",
		"effect": "global_damage",
		"cooldown": 8.0,
		"damage": 3
	},

	# Burning ground - Sunfields
	"burning_ground": {
		"name": "Burning Ground",
		"type": SimEnemyAbilities.AbilityType.COOLDOWN,
		"description": "Sets the ground on fire, damaging towers over time.",
		"effect": "ground_hazard",
		"cooldown": 12.0,
		"radius": 4,
		"damage": 1,
		"duration": 5.0
	},

	# Summon marauders - Sunfields
	"summon_marauders": {
		"name": "Summon Marauders",
		"type": SimEnemyAbilities.AbilityType.COOLDOWN,
		"description": "Summons {count} Plains Marauders.",
		"effect": "summon",
		"cooldown": 10.0,
		"count": 2,
		"summon_type": "plains_marauder"
	}
}

# =============================================================================
# BOSS STATE MANAGEMENT
# =============================================================================

## Initialize boss state
static func init_boss_state(boss: Dictionary) -> void:
	var boss_id: String = str(boss.get("type", ""))
	var boss_def: Dictionary = BOSSES.get(boss_id, {})

	if boss_def.is_empty():
		return

	boss["is_boss"] = true
	boss["current_phase"] = 1
	boss["max_phases"] = int(boss_def.get("phases", 1))
	boss["phase_thresholds"] = boss_def.get("phase_thresholds", [])
	boss["dialogue_shown"] = {"intro": false, "defeat": false}
	boss["phase_transitions_shown"] = []

	# Initialize ability cooldowns for current phase
	_init_phase_abilities(boss, 1)


## Initialize abilities for a specific phase
static func _init_phase_abilities(boss: Dictionary, phase: int) -> void:
	var boss_id: String = str(boss.get("type", ""))
	var boss_def: Dictionary = BOSSES.get(boss_id, {})
	var phase_data: Dictionary = boss_def.get("phase_data", {}).get(phase, {})

	boss["ability_cooldowns"] = {}
	var abilities: Array = phase_data.get("abilities", [])

	for ability_id in abilities:
		boss["ability_cooldowns"][ability_id] = 0.0


## Check and handle phase transitions
static func check_phase_transition(boss: Dictionary) -> Dictionary:
	var current_phase: int = int(boss.get("current_phase", 1))
	var max_phases: int = int(boss.get("max_phases", 1))

	if current_phase >= max_phases:
		return {}

	var thresholds: Array = boss.get("phase_thresholds", [])
	var boss_id: String = str(boss.get("type", ""))
	var boss_def: Dictionary = BOSSES.get(boss_id, {})
	var max_hp: int = int(boss_def.get("hp", 50))
	var current_hp: int = int(boss.get("hp", max_hp))
	var hp_percent: float = float(current_hp) / float(max_hp)

	# Check if we crossed a threshold
	var next_phase: int = current_phase + 1
	if next_phase - 2 < thresholds.size():
		var threshold: float = float(thresholds[next_phase - 2])
		if hp_percent <= threshold:
			# Transition to next phase
			boss["current_phase"] = next_phase
			_init_phase_abilities(boss, next_phase)

			# Return transition event with dialogue
			var dialogue: Array = []
			var dialogue_key: String = "phase_%d" % next_phase
			if boss_def.has("dialogue") and boss_def["dialogue"].has(dialogue_key):
				dialogue = boss_def["dialogue"][dialogue_key]

			return {
				"type": "phase_transition",
				"boss_id": boss_id,
				"new_phase": next_phase,
				"dialogue": dialogue
			}

	return {}


## Tick boss abilities
static func tick_boss_abilities(boss: Dictionary, delta: float) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var boss_id: String = str(boss.get("type", ""))
	var boss_def: Dictionary = BOSSES.get(boss_id, {})
	var current_phase: int = int(boss.get("current_phase", 1))
	var phase_data: Dictionary = boss_def.get("phase_data", {}).get(current_phase, {})
	var cooldowns: Dictionary = boss.get("ability_cooldowns", {})

	# Tick all cooldowns
	for ability_id in cooldowns.keys():
		if cooldowns[ability_id] > 0:
			cooldowns[ability_id] = maxf(0.0, cooldowns[ability_id] - delta)

	# Check for abilities ready to fire
	var abilities: Array = phase_data.get("abilities", [])
	for ability_id in abilities:
		if cooldowns.get(ability_id, 0.0) <= 0:
			var event: Dictionary = _try_activate_boss_ability(boss, ability_id, phase_data)
			if not event.is_empty():
				events.append(event)
				# Set cooldown from phase data or mechanic definition
				var cooldown_key: String = "%s_cooldown" % ability_id
				var cooldown: float = float(phase_data.get(cooldown_key, BOSS_MECHANICS.get(ability_id, {}).get("cooldown", 10.0)))
				cooldowns[ability_id] = cooldown

	return events


static func _try_activate_boss_ability(boss: Dictionary, ability_id: String, phase_data: Dictionary) -> Dictionary:
	var mechanic: Dictionary = BOSS_MECHANICS.get(ability_id, {})
	# Fall back to standard abilities if not a boss-specific mechanic
	if mechanic.is_empty():
		mechanic = SimEnemyAbilities.ABILITIES.get(ability_id, {})

	if mechanic.is_empty():
		return {}

	var effect: String = str(mechanic.get("effect", ""))
	var boss_pos: Vector2 = boss.get("pos", Vector2.ZERO)

	match effect:
		"summon":
			var summon_type: String = str(phase_data.get("summon_type", mechanic.get("summon_type", "typhos_spawn")))
			var count: int = int(phase_data.get("summon_count", mechanic.get("count", 2)))
			return {
				"type": "boss_summon",
				"ability": ability_id,
				"pos": boss_pos,
				"count": count,
				"summon_type": summon_type
			}
		"invulnerability":
			var duration: float = float(phase_data.get("barrier_duration", mechanic.get("duration", 5.0)))
			boss["invulnerable"] = true
			boss["invuln_duration"] = duration
			return {
				"type": "boss_barrier",
				"ability": ability_id,
				"boss_id": boss.get("id", 0),
				"duration": duration
			}
		"phase_out":
			var duration: float = float(phase_data.get("veil_duration", mechanic.get("duration", 3.0)))
			boss["phased_out"] = true
			boss["phase_duration"] = duration
			return {
				"type": "boss_phase_out",
				"ability": ability_id,
				"boss_id": boss.get("id", 0),
				"duration": duration
			}
		"create_illusions":
			var count: int = int(phase_data.get("illusion_count", mechanic.get("count", 3)))
			return {
				"type": "boss_illusions",
				"ability": ability_id,
				"boss_id": boss.get("id", 0),
				"count": count,
				"pos": boss_pos
			}
		"global_damage":
			var damage: int = int(phase_data.get("flare_damage", mechanic.get("damage", 3)))
			return {
				"type": "boss_global_damage",
				"ability": ability_id,
				"damage": damage
			}
		"hazard_zone", "ground_hazard":
			var radius: int = int(phase_data.get("cloud_radius", mechanic.get("radius", 3)))
			var damage: int = int(mechanic.get("damage", 1))
			var duration: float = float(phase_data.get("cloud_duration", mechanic.get("duration", 5.0)))
			return {
				"type": "boss_hazard",
				"ability": ability_id,
				"pos": boss_pos,
				"radius": radius,
				"damage": damage,
				"duration": duration
			}
		# Handle standard abilities
		"aoe_stun":
			var radius: int = int(phase_data.get("pound_radius", mechanic.get("radius", 2)))
			var duration: float = float(mechanic.get("duration", 2.0))
			return {
				"type": "aoe_stun",
				"ability": ability_id,
				"pos": boss_pos,
				"radius": radius,
				"duration": duration
			}
		"scramble_words":
			var radius: int = int(phase_data.get("scramble_radius", mechanic.get("radius", 3)))
			return {
				"type": "scramble_words",
				"ability": ability_id,
				"pos": boss_pos,
				"radius": radius
			}
		"damage_aura", "buff_allies":
			# War banner effect is passive
			return {}

	return {}


## Get intro dialogue for a boss
static func get_intro_dialogue(boss_id: String) -> Array:
	var boss_def: Dictionary = BOSSES.get(boss_id, {})
	if boss_def.has("dialogue") and boss_def["dialogue"].has("intro"):
		return boss_def["dialogue"]["intro"]
	return []


## Get defeat dialogue for a boss
static func get_defeat_dialogue(boss_id: String) -> Array:
	var boss_def: Dictionary = BOSSES.get(boss_id, {})
	if boss_def.has("dialogue") and boss_def["dialogue"].has("defeat"):
		return boss_def["dialogue"]["defeat"]
	return []


## Get phase transition dialogue
static func get_phase_dialogue(boss_id: String, phase: int) -> Array:
	var boss_def: Dictionary = BOSSES.get(boss_id, {})
	var dialogue_key: String = "phase_%d" % phase
	if boss_def.has("dialogue") and boss_def["dialogue"].has(dialogue_key):
		return boss_def["dialogue"][dialogue_key]
	return []


# =============================================================================
# BOSS INFO QUERIES
# =============================================================================

static func get_boss(boss_id: String) -> Dictionary:
	return BOSSES.get(boss_id, {})


static func get_boss_name(boss_id: String) -> String:
	return str(BOSSES.get(boss_id, {}).get("name", boss_id))


static func get_boss_title(boss_id: String) -> String:
	return str(BOSSES.get(boss_id, {}).get("title", ""))


static func get_boss_for_region(region: int) -> String:
	for boss_id in BOSSES.keys():
		if int(BOSSES[boss_id].get("region", 0)) == region:
			return str(boss_id)
	return ""


static func get_boss_unlock_day(boss_id: String) -> int:
	return int(BOSSES.get(boss_id, {}).get("unlock_day", 7))


static func get_available_bosses_for_day(day: int) -> Array[String]:
	var result: Array[String] = []
	for boss_id in BOSSES.keys():
		if day >= int(BOSSES[boss_id].get("unlock_day", 999)):
			result.append(str(boss_id))
	return result


static func is_valid_boss(boss_id: String) -> bool:
	return BOSSES.has(boss_id)


static func get_all_boss_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in BOSSES.keys():
		ids.append(str(key))
	return ids


static func get_phase_name(boss_id: String, phase: int) -> String:
	var boss_def: Dictionary = BOSSES.get(boss_id, {})
	var phase_data: Dictionary = boss_def.get("phase_data", {}).get(phase, {})
	return str(phase_data.get("name", "Phase %d" % phase))


static func get_mechanic(mechanic_id: String) -> Dictionary:
	return BOSS_MECHANICS.get(mechanic_id, {})
