class_name SimEnemyAbilities
extends RefCounted
## Enemy Ability System - Handles all special enemy abilities

const SimEnemyTypes = preload("res://sim/enemy_types.gd")

# =============================================================================
# ABILITY TYPES
# =============================================================================

enum AbilityType {
	PASSIVE,    # Always active while enemy alive
	TRIGGER,    # Activates on specific events (damage, low HP, etc.)
	COOLDOWN,   # Active ability with cooldown timer
	DEATH       # Triggers when enemy dies
}

enum TriggerEvent {
	ON_SPAWN,       # When enemy first appears
	ON_DAMAGE,      # When enemy takes damage
	ON_LOW_HP,      # When HP drops below threshold
	ON_ALLY_DEATH,  # When nearby ally dies
	ON_ATTACK,      # When enemy attacks
	ON_DEATH        # When enemy dies
}

# =============================================================================
# ABILITY DEFINITIONS
# =============================================================================

const ABILITIES: Dictionary = {
	# =========================================================================
	# PASSIVE ABILITIES (always active)
	# =========================================================================
	"void_armor": {
		"name": "Void Armor",
		"type": AbilityType.PASSIVE,
		"description": "Reduces first hit damage to 1.",
		"effect": "first_hit_reduction",
		"stacks": 1
	},
	"frost_aura": {
		"name": "Frost Aura",
		"type": AbilityType.PASSIVE,
		"description": "Slows nearby towers by {slow_percent}%.",
		"effect": "tower_slow",
		"radius": 3,
		"slow_percent": 30
	},
	"toxic_presence": {
		"name": "Toxic Presence",
		"type": AbilityType.PASSIVE,
		"description": "Deals {damage} damage per tick to nearby enemies.",
		"effect": "aura_damage",
		"radius": 2,
		"damage": 1
	},
	"shield_aura": {
		"name": "Shield Aura",
		"type": AbilityType.PASSIVE,
		"description": "Grants +{armor} armor to nearby allies.",
		"effect": "aura_armor",
		"radius": 2,
		"armor_bonus": 1
	},
	"mute_aura": {
		"name": "Mute Aura",
		"type": AbilityType.PASSIVE,
		"description": "Hides word labels of nearby enemies.",
		"effect": "hide_words",
		"radius": 2
	},
	"command_aura": {
		"name": "Command Aura",
		"type": AbilityType.PASSIVE,
		"description": "Nearby allies deal +{damage_bonus}% damage and move +{speed_bonus}% faster.",
		"effect": "buff_allies",
		"radius": 3,
		"damage_bonus": 25,
		"speed_bonus": 15
	},
	"war_banner": {
		"name": "War Banner",
		"type": AbilityType.PASSIVE,
		"description": "Allies within range deal +{damage_bonus}% damage.",
		"effect": "damage_aura",
		"radius": 4,
		"damage_bonus": 50
	},
	"regeneration": {
		"name": "Regeneration",
		"type": AbilityType.PASSIVE,
		"description": "Regenerates {rate} HP per tick.",
		"effect": "hp_regen",
		"rate": 1
	},
	"mass_regeneration": {
		"name": "Mass Regeneration",
		"type": AbilityType.PASSIVE,
		"description": "Regenerates {rate} HP per tick for self and nearby allies.",
		"effect": "aura_regen",
		"radius": 3,
		"rate": 2
	},
	"flicker": {
		"name": "Flicker",
		"type": AbilityType.PASSIVE,
		"description": "Periodically becomes untargetable.",
		"effect": "periodic_invuln",
		"duration": 1.0,
		"cooldown": 3.0
	},
	"rusty_armor": {
		"name": "Rusty Armor",
		"type": AbilityType.PASSIVE,
		"description": "{chance}% chance to lose 1 armor when hit.",
		"effect": "armor_decay",
		"chance": 20
	},
	"dodge": {
		"name": "Dodge",
		"type": AbilityType.PASSIVE,
		"description": "{chance}% chance to avoid damage.",
		"effect": "evasion",
		"chance": 30
	},
	"damage_reflect": {
		"name": "Damage Reflect",
		"type": AbilityType.PASSIVE,
		"description": "Reflects {percent}% of damage taken back to attacker.",
		"effect": "reflect",
		"percent": 25
	},

	# =========================================================================
	# TRIGGER ABILITIES (activate on events)
	# =========================================================================
	"blood_frenzy": {
		"name": "Blood Frenzy",
		"type": AbilityType.TRIGGER,
		"trigger": TriggerEvent.ON_DAMAGE,
		"description": "Gains +{speed_per_hp} speed per HP lost (max +{max_bonus}).",
		"effect": "speed_on_damage",
		"speed_per_hp": 0.2,
		"max_bonus": 1.0
	},
	"enrage": {
		"name": "Enrage",
		"type": AbilityType.TRIGGER,
		"trigger": TriggerEvent.ON_LOW_HP,
		"description": "At {threshold}% HP: +{damage_bonus} damage, +{speed_bonus} speed.",
		"effect": "low_hp_buff",
		"threshold": 50,
		"damage_bonus": 2,
		"speed_bonus": 0.5
	},
	"shadow_cloak": {
		"name": "Shadow Cloak",
		"type": AbilityType.TRIGGER,
		"trigger": TriggerEvent.ON_DAMAGE,
		"description": "Becomes invisible for {duration}s when damaged. Cooldown: {cooldown}s.",
		"effect": "cloak_on_damage",
		"duration": 2.0,
		"cooldown": 4.0
	},
	"pack_spawn": {
		"name": "Pack Spawn",
		"type": AbilityType.TRIGGER,
		"trigger": TriggerEvent.ON_SPAWN,
		"description": "Spawns with {count} additional copies.",
		"effect": "spawn_copies",
		"count": 2
	},
	"attach": {
		"name": "Attach",
		"type": AbilityType.TRIGGER,
		"trigger": TriggerEvent.ON_SPAWN,
		"description": "Attaches to strongest nearby enemy for protection.",
		"effect": "attach_to_ally",
		"search_radius": 3
	},

	# =========================================================================
	# COOLDOWN ABILITIES (active with cooldown)
	# =========================================================================
	"summon_spawn": {
		"name": "Summon Spawn",
		"type": AbilityType.COOLDOWN,
		"description": "Summons {count} minions every {cooldown}s.",
		"effect": "summon",
		"cooldown": 10.0,
		"count": 2,
		"summon_type": "typhos_spawn"
	},
	"ground_pound": {
		"name": "Ground Pound",
		"type": AbilityType.COOLDOWN,
		"description": "Stuns towers in radius {radius} for {duration}s.",
		"effect": "aoe_stun",
		"cooldown": 12.0,
		"radius": 2,
		"duration": 2.0
	},
	"shadow_step": {
		"name": "Shadow Step",
		"type": AbilityType.COOLDOWN,
		"description": "Teleports {distance} tiles toward the castle.",
		"effect": "teleport",
		"cooldown": 6.0,
		"distance": 3
	},
	"mana_drain": {
		"name": "Mana Drain",
		"type": AbilityType.COOLDOWN,
		"description": "Disables a tower for {duration}s.",
		"effect": "disable_tower",
		"cooldown": 8.0,
		"duration": 4.0
	},
	"lightning_strike": {
		"name": "Lightning Strike",
		"type": AbilityType.COOLDOWN,
		"description": "Deals {damage} damage to a random structure.",
		"effect": "structure_damage",
		"cooldown": 5.0,
		"damage": 2
	},
	"arcane_blast": {
		"name": "Arcane Blast",
		"type": AbilityType.COOLDOWN,
		"description": "Deals {damage} damage to all towers in radius {radius}.",
		"effect": "aoe_structure_damage",
		"cooldown": 10.0,
		"radius": 2,
		"damage": 1
	},
	"root_snare": {
		"name": "Root Snare",
		"type": AbilityType.COOLDOWN,
		"description": "Prevents a tower from attacking for {duration}s.",
		"effect": "snare_tower",
		"cooldown": 10.0,
		"duration": 3.0
	},
	"ranged_attack": {
		"name": "Ranged Attack",
		"type": AbilityType.COOLDOWN,
		"description": "Attacks from {range} tiles away.",
		"effect": "ranged",
		"cooldown": 3.0,
		"range": 4
	},
	"tunnel": {
		"name": "Tunnel",
		"type": AbilityType.COOLDOWN,
		"description": "Burrows underground, becoming untargetable for {duration}s.",
		"effect": "burrow",
		"cooldown": 8.0,
		"duration": 2.0
	},
	"word_scramble": {
		"name": "Word Scramble",
		"type": AbilityType.COOLDOWN,
		"description": "Scrambles words of nearby enemies.",
		"effect": "scramble_words",
		"cooldown": 8.0,
		"radius": 3
	},
	"tower_debuff": {
		"name": "Tower Debuff",
		"type": AbilityType.COOLDOWN,
		"description": "Reduces tower damage by {percent}% for {duration}s.",
		"effect": "weaken_towers",
		"cooldown": 6.0,
		"radius": 3,
		"percent": 50,
		"duration": 4.0
	},

	# =========================================================================
	# DEATH ABILITIES (trigger on death)
	# =========================================================================
	"splitting": {
		"name": "Splitting",
		"type": AbilityType.DEATH,
		"description": "Splits into {count} smaller enemies on death.",
		"effect": "spawn_on_death",
		"count": 2,
		"spawn_type": "void_wisp"
	},
	"explosive": {
		"name": "Explosive",
		"type": AbilityType.DEATH,
		"description": "Explodes on death, dealing {damage} damage in radius {radius}.",
		"effect": "death_explosion",
		"damage": 1,
		"radius": 1
	},
	"death_scramble": {
		"name": "Death Scramble",
		"type": AbilityType.DEATH,
		"description": "Scrambles words of all visible enemies on death.",
		"effect": "scramble_all_on_death"
	},
	"healing_burst": {
		"name": "Healing Burst",
		"type": AbilityType.DEATH,
		"description": "Heals nearby allies for {amount} on death.",
		"effect": "heal_allies_on_death",
		"amount": 3,
		"radius": 2
	},
	"ink_trail": {
		"name": "Ink Trail",
		"type": AbilityType.DEATH,
		"description": "Leaves a slowing ink pool on death.",
		"effect": "create_hazard",
		"hazard_type": "ink",
		"duration": 5.0
	},
	"fire_trail": {
		"name": "Fire Trail",
		"type": AbilityType.DEATH,
		"description": "Leaves a burning trail while moving.",
		"effect": "continuous_trail",
		"hazard_type": "fire",
		"damage": 1,
		"duration": 2.0
	},
	"poison_attack": {
		"name": "Poison Attack",
		"type": AbilityType.PASSIVE,
		"description": "Attacks apply poison for {duration}s.",
		"effect": "poison_on_hit",
		"damage": 1,
		"duration": 3.0
	}
}

# =============================================================================
# ABILITY STATE MANAGEMENT
# =============================================================================

## Initialize ability state for an enemy
static func init_ability_state(enemy: Dictionary) -> void:
	var enemy_type: String = str(enemy.get("type", ""))
	var abilities: Array = SimEnemyTypes.get_abilities(enemy_type)

	if abilities.is_empty():
		return

	# Initialize ability tracking
	enemy["ability_state"] = {}

	for ability_id in abilities:
		var ability: Dictionary = ABILITIES.get(ability_id, {})
		if ability.is_empty():
			continue

		var state: Dictionary = {
			"active": false,
			"cooldown_remaining": 0.0,
			"stacks": ability.get("stacks", 0),
			"triggered": false
		}

		# Initialize based on type
		var ability_type: int = int(ability.get("type", AbilityType.PASSIVE))
		match ability_type:
			AbilityType.PASSIVE:
				state["active"] = true
			AbilityType.COOLDOWN:
				state["cooldown_remaining"] = 0.0

		enemy["ability_state"][ability_id] = state


## Update ability cooldowns for an enemy
static func tick_abilities(enemy: Dictionary, delta: float) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var ability_state: Dictionary = enemy.get("ability_state", {})

	for ability_id in ability_state.keys():
		var state: Dictionary = ability_state[ability_id]
		var ability: Dictionary = ABILITIES.get(ability_id, {})

		if ability.is_empty():
			continue

		# Tick cooldowns
		if state.get("cooldown_remaining", 0.0) > 0:
			state["cooldown_remaining"] = maxf(0.0, state["cooldown_remaining"] - delta)

		# Check for cooldown abilities ready to fire
		var ability_type: int = int(ability.get("type", 0))
		if ability_type == AbilityType.COOLDOWN:
			if state.get("cooldown_remaining", 0.0) <= 0:
				var event: Dictionary = _try_activate_cooldown(enemy, ability_id, ability)
				if not event.is_empty():
					events.append(event)
					state["cooldown_remaining"] = float(ability.get("cooldown", 5.0))

	return events


## Handle a trigger event for an enemy
static func handle_trigger(enemy: Dictionary, event_type: int, context: Dictionary = {}) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var ability_state: Dictionary = enemy.get("ability_state", {})
	var enemy_type: String = str(enemy.get("type", ""))
	var abilities: Array = SimEnemyTypes.get_abilities(enemy_type)

	for ability_id in abilities:
		var ability: Dictionary = ABILITIES.get(ability_id, {})
		if ability.is_empty():
			continue

		var ability_type: int = int(ability.get("type", 0))
		var trigger: int = int(ability.get("trigger", -1))

		# Check if this is a trigger ability with matching event
		if ability_type == AbilityType.TRIGGER and trigger == event_type:
			var state: Dictionary = ability_state.get(ability_id, {})

			# Check cooldown for triggered abilities
			if state.get("cooldown_remaining", 0.0) > 0:
				continue

			var event: Dictionary = _apply_trigger_effect(enemy, ability_id, ability, context)
			if not event.is_empty():
				events.append(event)
				# Set cooldown if applicable
				var cooldown: float = float(ability.get("cooldown", 0.0))
				if cooldown > 0 and ability_state.has(ability_id):
					ability_state[ability_id]["cooldown_remaining"] = cooldown

		# Handle death abilities
		if ability_type == AbilityType.DEATH and event_type == TriggerEvent.ON_DEATH:
			var event: Dictionary = _apply_death_effect(enemy, ability_id, ability, context)
			if not event.is_empty():
				events.append(event)

	return events


# =============================================================================
# PASSIVE ABILITY QUERIES
# =============================================================================

## Check if enemy has active passive ability
static func has_passive(enemy: Dictionary, ability_id: String) -> bool:
	var ability_state: Dictionary = enemy.get("ability_state", {})
	var state: Dictionary = ability_state.get(ability_id, {})
	return state.get("active", false)


## Get passive ability value
static func get_passive_value(enemy: Dictionary, ability_id: String, key: String, default_value: Variant = 0) -> Variant:
	if not has_passive(enemy, ability_id):
		return default_value
	var ability: Dictionary = ABILITIES.get(ability_id, {})
	return ability.get(key, default_value)


## Calculate total armor including aura bonuses
static func get_effective_armor(enemy: Dictionary, nearby_enemies: Array) -> int:
	var base_armor: int = int(enemy.get("armor", 0))
	var bonus_armor: int = 0

	# Check nearby enemies for shield_aura
	for ally in nearby_enemies:
		if has_passive(ally, "shield_aura"):
			var radius: int = int(get_passive_value(ally, "shield_aura", "radius", 2))
			var ally_pos: Vector2 = ally.get("pos", Vector2.ZERO)
			var enemy_pos: Vector2 = enemy.get("pos", Vector2.ZERO)
			if ally_pos.distance_to(enemy_pos) <= radius:
				bonus_armor += int(get_passive_value(ally, "shield_aura", "armor_bonus", 1))

	return base_armor + bonus_armor


## Calculate total speed including buffs
static func get_effective_speed(enemy: Dictionary, nearby_enemies: Array) -> float:
	var enemy_type: String = str(enemy.get("type", ""))
	var base_speed: float = SimEnemyTypes.get_speed(enemy_type)
	var multiplier: float = 1.0

	# Blood frenzy bonus
	if has_passive(enemy, "blood_frenzy"):
		var max_hp: int = SimEnemyTypes.get_hp(enemy_type)
		var current_hp: int = int(enemy.get("hp", max_hp))
		var hp_lost: int = max_hp - current_hp
		var speed_per_hp: float = float(get_passive_value(enemy, "blood_frenzy", "speed_per_hp", 0.2))
		var max_bonus: float = float(get_passive_value(enemy, "blood_frenzy", "max_bonus", 1.0))
		var bonus: float = minf(hp_lost * speed_per_hp, max_bonus)
		multiplier += bonus / base_speed

	# Enrage bonus (if triggered)
	var ability_state: Dictionary = enemy.get("ability_state", {})
	if ability_state.get("enrage", {}).get("triggered", false):
		var speed_bonus: float = float(ABILITIES.get("enrage", {}).get("speed_bonus", 0.5))
		multiplier += speed_bonus / base_speed

	# Command aura bonus from nearby allies
	for ally in nearby_enemies:
		if ally == enemy:
			continue
		if has_passive(ally, "command_aura") or has_passive(ally, "war_banner"):
			var ability_id: String = "command_aura" if has_passive(ally, "command_aura") else "war_banner"
			var radius: int = int(get_passive_value(ally, ability_id, "radius", 3))
			var ally_pos: Vector2 = ally.get("pos", Vector2.ZERO)
			var enemy_pos: Vector2 = enemy.get("pos", Vector2.ZERO)
			if ally_pos.distance_to(enemy_pos) <= radius:
				var speed_bonus: int = int(get_passive_value(ally, ability_id, "speed_bonus", 0))
				multiplier += speed_bonus / 100.0

	return base_speed * multiplier


## Calculate total damage including buffs
static func get_effective_damage(enemy: Dictionary, nearby_enemies: Array) -> int:
	var enemy_type: String = str(enemy.get("type", ""))
	var base_damage: int = SimEnemyTypes.get_damage(enemy_type)
	var bonus_damage: int = 0
	var multiplier: float = 1.0

	# Enrage bonus (if triggered)
	var ability_state: Dictionary = enemy.get("ability_state", {})
	if ability_state.get("enrage", {}).get("triggered", false):
		bonus_damage += int(ABILITIES.get("enrage", {}).get("damage_bonus", 2))

	# Command aura / war banner bonus from nearby allies
	for ally in nearby_enemies:
		if ally == enemy:
			continue
		for aura_id in ["command_aura", "war_banner"]:
			if has_passive(ally, aura_id):
				var radius: int = int(get_passive_value(ally, aura_id, "radius", 3))
				var ally_pos: Vector2 = ally.get("pos", Vector2.ZERO)
				var enemy_pos: Vector2 = enemy.get("pos", Vector2.ZERO)
				if ally_pos.distance_to(enemy_pos) <= radius:
					var damage_bonus: int = int(get_passive_value(ally, aura_id, "damage_bonus", 25))
					multiplier += damage_bonus / 100.0

	return int((base_damage + bonus_damage) * multiplier)


## Check if enemy should dodge damage
static func should_dodge(enemy: Dictionary) -> bool:
	if not has_passive(enemy, "dodge"):
		return false
	var chance: int = int(get_passive_value(enemy, "dodge", "chance", 30))
	return randi() % 100 < chance


## Check if void armor should reduce damage
static func check_void_armor(enemy: Dictionary) -> bool:
	var ability_state: Dictionary = enemy.get("ability_state", {})
	var state: Dictionary = ability_state.get("void_armor", {})
	if state.get("stacks", 0) > 0:
		state["stacks"] = state["stacks"] - 1
		return true
	return false


## Check if enemy is currently invisible/untargetable
static func is_untargetable(enemy: Dictionary) -> bool:
	var ability_state: Dictionary = enemy.get("ability_state", {})

	# Check flicker
	if ability_state.get("flicker", {}).get("active", false):
		return true

	# Check shadow cloak
	if ability_state.get("shadow_cloak", {}).get("active", false):
		return true

	# Check tunnel/burrow
	if ability_state.get("tunnel", {}).get("active", false):
		return true

	return false


## Check if enemy word should be hidden (mute aura effect)
static func is_word_hidden(enemy: Dictionary, nearby_enemies: Array) -> bool:
	for ally in nearby_enemies:
		if ally == enemy:
			continue
		if has_passive(ally, "mute_aura"):
			var radius: int = int(get_passive_value(ally, "mute_aura", "radius", 2))
			var ally_pos: Vector2 = ally.get("pos", Vector2.ZERO)
			var enemy_pos: Vector2 = enemy.get("pos", Vector2.ZERO)
			if ally_pos.distance_to(enemy_pos) <= radius:
				return true
	return false


# =============================================================================
# PRIVATE HELPERS
# =============================================================================

static func _try_activate_cooldown(enemy: Dictionary, ability_id: String, ability: Dictionary) -> Dictionary:
	var effect: String = str(ability.get("effect", ""))
	var enemy_pos: Vector2 = enemy.get("pos", Vector2.ZERO)

	match effect:
		"summon":
			return {
				"type": "summon",
				"ability": ability_id,
				"pos": enemy_pos,
				"count": ability.get("count", 1),
				"summon_type": ability.get("summon_type", "typhos_spawn")
			}
		"teleport":
			return {
				"type": "teleport",
				"ability": ability_id,
				"enemy_id": enemy.get("id", 0),
				"distance": ability.get("distance", 3)
			}
		"aoe_stun":
			return {
				"type": "aoe_stun",
				"ability": ability_id,
				"pos": enemy_pos,
				"radius": ability.get("radius", 2),
				"duration": ability.get("duration", 2.0)
			}
		"disable_tower":
			return {
				"type": "disable_tower",
				"ability": ability_id,
				"pos": enemy_pos,
				"duration": ability.get("duration", 4.0)
			}
		"structure_damage":
			return {
				"type": "structure_damage",
				"ability": ability_id,
				"damage": ability.get("damage", 2)
			}
		"aoe_structure_damage":
			return {
				"type": "aoe_structure_damage",
				"ability": ability_id,
				"pos": enemy_pos,
				"radius": ability.get("radius", 2),
				"damage": ability.get("damage", 1)
			}
		"scramble_words":
			return {
				"type": "scramble_words",
				"ability": ability_id,
				"pos": enemy_pos,
				"radius": ability.get("radius", 3)
			}
		"weaken_towers":
			return {
				"type": "weaken_towers",
				"ability": ability_id,
				"pos": enemy_pos,
				"radius": ability.get("radius", 3),
				"percent": ability.get("percent", 50),
				"duration": ability.get("duration", 4.0)
			}
		"snare_tower":
			return {
				"type": "snare_tower",
				"ability": ability_id,
				"pos": enemy_pos,
				"duration": ability.get("duration", 3.0)
			}
		"burrow":
			# Set burrow state active
			var ability_state: Dictionary = enemy.get("ability_state", {})
			if ability_state.has(ability_id):
				ability_state[ability_id]["active"] = true
			return {
				"type": "burrow",
				"ability": ability_id,
				"enemy_id": enemy.get("id", 0),
				"duration": ability.get("duration", 2.0)
			}

	return {}


static func _apply_trigger_effect(enemy: Dictionary, ability_id: String, ability: Dictionary, context: Dictionary) -> Dictionary:
	var effect: String = str(ability.get("effect", ""))
	var enemy_pos: Vector2 = enemy.get("pos", Vector2.ZERO)
	var ability_state: Dictionary = enemy.get("ability_state", {})

	match effect:
		"speed_on_damage":
			# Blood frenzy is handled passively in get_effective_speed
			return {"type": "buff_applied", "ability": ability_id, "enemy_id": enemy.get("id", 0)}
		"low_hp_buff":
			# Check if we crossed the threshold
			var enemy_type: String = str(enemy.get("type", ""))
			var max_hp: int = SimEnemyTypes.get_hp(enemy_type)
			var current_hp: int = int(enemy.get("hp", max_hp))
			var threshold: int = int(ability.get("threshold", 50))
			var hp_percent: int = int((float(current_hp) / float(max_hp)) * 100)

			if hp_percent <= threshold:
				if ability_state.has(ability_id):
					ability_state[ability_id]["triggered"] = true
				return {"type": "enrage", "ability": ability_id, "enemy_id": enemy.get("id", 0)}
		"cloak_on_damage":
			if ability_state.has(ability_id):
				ability_state[ability_id]["active"] = true
			return {
				"type": "cloak",
				"ability": ability_id,
				"enemy_id": enemy.get("id", 0),
				"duration": ability.get("duration", 2.0)
			}
		"spawn_copies":
			return {
				"type": "pack_spawn",
				"ability": ability_id,
				"pos": enemy_pos,
				"count": ability.get("count", 2),
				"spawn_type": enemy.get("type", "shadow_rat")
			}
		"attach_to_ally":
			return {
				"type": "attach",
				"ability": ability_id,
				"enemy_id": enemy.get("id", 0),
				"search_radius": ability.get("search_radius", 3)
			}

	return {}


static func _apply_death_effect(enemy: Dictionary, ability_id: String, ability: Dictionary, context: Dictionary) -> Dictionary:
	var effect: String = str(ability.get("effect", ""))
	var enemy_pos: Vector2 = enemy.get("pos", Vector2.ZERO)

	match effect:
		"spawn_on_death":
			return {
				"type": "death_spawn",
				"ability": ability_id,
				"pos": enemy_pos,
				"count": ability.get("count", 2),
				"spawn_type": ability.get("spawn_type", "void_wisp")
			}
		"death_explosion":
			return {
				"type": "explosion",
				"ability": ability_id,
				"pos": enemy_pos,
				"damage": ability.get("damage", 1),
				"radius": ability.get("radius", 1)
			}
		"scramble_all_on_death":
			return {
				"type": "scramble_all",
				"ability": ability_id,
				"pos": enemy_pos
			}
		"heal_allies_on_death":
			return {
				"type": "death_heal",
				"ability": ability_id,
				"pos": enemy_pos,
				"amount": ability.get("amount", 3),
				"radius": ability.get("radius", 2)
			}
		"create_hazard":
			return {
				"type": "create_hazard",
				"ability": ability_id,
				"pos": enemy_pos,
				"hazard_type": ability.get("hazard_type", "ink"),
				"duration": ability.get("duration", 5.0)
			}

	return {}


# =============================================================================
# ABILITY INFO
# =============================================================================

static func get_ability(ability_id: String) -> Dictionary:
	return ABILITIES.get(ability_id, {})


static func get_ability_name(ability_id: String) -> String:
	return str(ABILITIES.get(ability_id, {}).get("name", ability_id))


static func get_ability_description(ability_id: String) -> String:
	var ability: Dictionary = ABILITIES.get(ability_id, {})
	var desc: String = str(ability.get("description", ""))

	# Replace placeholders with actual values
	for key in ability.keys():
		if key != "description" and key != "name" and key != "type" and key != "effect":
			desc = desc.replace("{%s}" % key, str(ability[key]))

	return desc


static func get_ability_type(ability_id: String) -> int:
	return int(ABILITIES.get(ability_id, {}).get("type", AbilityType.PASSIVE))


static func is_valid_ability(ability_id: String) -> bool:
	return ABILITIES.has(ability_id)


static func get_all_ability_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in ABILITIES.keys():
		ids.append(str(key))
	return ids


static func get_abilities_by_type(ability_type: int) -> Array[String]:
	var result: Array[String] = []
	for key in ABILITIES.keys():
		if int(ABILITIES[key].get("type", 0)) == ability_type:
			result.append(str(key))
	return result
