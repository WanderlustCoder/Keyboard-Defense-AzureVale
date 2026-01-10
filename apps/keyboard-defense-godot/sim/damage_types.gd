class_name SimDamageTypes
extends RefCounted
## Damage type system - handles armor, resistances, and damage modifiers

const GameState = preload("res://sim/types.gd")
const SimTowerTypes = preload("res://sim/tower_types.gd")
const SimStatusEffects = preload("res://sim/status_effects.gd")

# =============================================================================
# DAMAGE CALCULATION
# =============================================================================

## Calculate final damage after armor and modifiers
## Returns the actual damage to apply to the enemy
static func calculate_damage(
	base_damage: int,
	damage_type: int,
	enemy: Dictionary,
	state: GameState
) -> int:
	var damage: float = float(base_damage)
	var armor: int = int(enemy.get("armor", 0))

	# Apply effective armor from status effects
	armor = SimStatusEffects.get_effective_armor(enemy)

	# Apply damage type modifiers
	match damage_type:
		SimTowerTypes.DamageType.MAGICAL:
			# Magic ignores armor completely
			armor = 0

		SimTowerTypes.DamageType.HOLY:
			# Bonus damage to enemies with affixes
			if enemy.has("affix") and str(enemy.get("affix", "")) != "":
				damage = damage * 1.5
			# Also bonus to corrupted enemies
			if _has_effect(enemy, "corrupting"):
				damage = damage * 1.5

		SimTowerTypes.DamageType.LIGHTNING:
			# Bonus to wet enemies (future: rain weather)
			if enemy.get("wet", false):
				damage = damage * 1.3
			# Bonus to enemies in water
			if _is_in_water(state, enemy):
				damage = damage * 1.2

		SimTowerTypes.DamageType.POISON:
			# Poison ignores half armor
			armor = int(armor * 0.5)

		SimTowerTypes.DamageType.COLD:
			# Cold damage is reduced but applies slow (handled separately)
			damage = damage * 0.8

		SimTowerTypes.DamageType.FIRE:
			# Fire has massive bonus to frozen enemies
			if _has_effect(enemy, "frozen"):
				damage = damage * 3.0

		SimTowerTypes.DamageType.PURE:
			# Pure damage ignores all resistances and armor
			armor = 0

	# Apply armor reduction (minimum 1 damage)
	var effective_damage: float = max(1.0, damage - float(armor))

	# Apply damage taken multiplier from status effects (exposed, frozen vulnerability)
	var damage_mult: float = SimStatusEffects.get_damage_taken_multiplier(enemy)
	effective_damage = effective_damage * damage_mult

	return max(1, int(effective_damage))


## Calculate damage with synergy bonuses applied
static func calculate_damage_with_synergies(
	base_damage: int,
	damage_type: int,
	enemy: Dictionary,
	state: GameState,
	synergy_bonus: float = 0.0
) -> int:
	var damage := calculate_damage(base_damage, damage_type, enemy, state)

	# Apply synergy bonus
	if synergy_bonus > 0.0:
		damage = int(float(damage) * (1.0 + synergy_bonus))

	return max(1, damage)


## Calculate boss damage with special modifiers
static func calculate_boss_damage(
	base_damage: int,
	damage_type: int,
	enemy: Dictionary,
	state: GameState,
	boss_bonus_percent: int = 0
) -> int:
	var damage := calculate_damage(base_damage, damage_type, enemy, state)

	# Apply boss bonus if target is a boss
	if enemy.get("is_boss", false) and boss_bonus_percent > 0:
		damage = int(float(damage) * (1.0 + float(boss_bonus_percent) / 100.0))

	return max(1, damage)


# =============================================================================
# CHAIN DAMAGE
# =============================================================================

## Calculate chain damage with falloff
static func calculate_chain_damage(
	base_damage: int,
	damage_type: int,
	enemy: Dictionary,
	state: GameState,
	jump_index: int,
	falloff: float
) -> int:
	# First target gets full damage, subsequent targets get falloff
	var falloff_mult: float = pow(falloff, float(jump_index))
	var reduced_damage: int = max(1, int(float(base_damage) * falloff_mult))

	return calculate_damage(reduced_damage, damage_type, enemy, state)


# =============================================================================
# AOE DAMAGE
# =============================================================================

## Calculate AoE damage with optional distance falloff
static func calculate_aoe_damage(
	base_damage: int,
	damage_type: int,
	enemy: Dictionary,
	state: GameState,
	center: Vector2i,
	use_falloff: bool = false
) -> int:
	var damage: int = base_damage

	# Optional distance-based falloff for more realistic explosions
	if use_falloff:
		var enemy_pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
		var dist: int = abs(enemy_pos.x - center.x) + abs(enemy_pos.y - center.y)
		if dist > 0:
			damage = max(1, int(float(damage) * (1.0 - float(dist) * 0.2)))

	return calculate_damage(damage, damage_type, enemy, state)


# =============================================================================
# DOT DAMAGE
# =============================================================================

## Calculate DoT tick damage
static func calculate_dot_tick_damage(
	base_tick_damage: int,
	stacks: int,
	damage_type: int,
	enemy: Dictionary,
	state: GameState
) -> int:
	# DoT damage scales with stacks
	var total_damage: int = base_tick_damage * stacks

	# DoT typically bypasses armor
	var armor: int = 0
	if damage_type == SimTowerTypes.DamageType.POISON:
		# Poison completely ignores armor
		armor = 0
	elif damage_type == SimTowerTypes.DamageType.FIRE:
		# Fire DoT ignores half armor
		armor = int(int(enemy.get("armor", 0)) * 0.5)

	var effective_damage: int = max(1, total_damage - armor)

	# Apply damage taken multiplier
	var damage_mult: float = SimStatusEffects.get_damage_taken_multiplier(enemy)
	effective_damage = int(float(effective_damage) * damage_mult)

	return max(1, effective_damage)


# =============================================================================
# CRITICAL HITS
# =============================================================================

## Check if attack is a critical hit
static func is_critical_hit(
	state: GameState,
	crit_chance: float,
	enemy: Dictionary
) -> bool:
	# Bonus crit chance against marked enemies
	if _has_effect(enemy, "marked"):
		crit_chance += 0.25  # +25% crit from marked status

	# Roll for crit (using game RNG for determinism)
	var roll: float = float(_roll_percent(state)) / 100.0
	return roll < crit_chance


## Calculate critical damage
static func apply_critical_multiplier(
	damage: int,
	crit_multiplier: float = 2.0
) -> int:
	return int(float(damage) * crit_multiplier)


# =============================================================================
# DAMAGE RESISTANCE
# =============================================================================

## Get damage resistance for specific damage type
static func get_damage_resistance(
	enemy: Dictionary,
	damage_type: int
) -> float:
	var resistance: float = 0.0

	# Check enemy affix for resistances
	var affix: String = str(enemy.get("affix", ""))

	# Armored affix resists physical
	if affix == "armored" and damage_type == SimTowerTypes.DamageType.PHYSICAL:
		resistance += 0.2

	# Ghostly affix resists physical
	if enemy.get("ghostly", false) and damage_type == SimTowerTypes.DamageType.PHYSICAL:
		resistance += 0.5

	# Frozen enemies are vulnerable to fire (negative resistance)
	if _has_effect(enemy, "frozen") and damage_type == SimTowerTypes.DamageType.FIRE:
		resistance -= 0.5  # 50% MORE damage

	# Burning enemies are vulnerable to cold
	if _has_effect(enemy, "burning") and damage_type == SimTowerTypes.DamageType.COLD:
		resistance -= 0.5

	return clamp(resistance, -1.0, 0.9)  # Cap at 90% resistance


## Apply damage resistance
static func apply_resistance(
	damage: int,
	resistance: float
) -> int:
	if resistance == 0.0:
		return damage

	return max(1, int(float(damage) * (1.0 - resistance)))


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

## Check if enemy has a specific status effect
static func _has_effect(enemy: Dictionary, effect_id: String) -> bool:
	if not enemy.has("status_effects"):
		return false
	return SimStatusEffects.has_effect(enemy, effect_id)


## Check if enemy is standing in water terrain
static func _is_in_water(state: GameState, enemy: Dictionary) -> bool:
	var pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
	var index: int = pos.y * state.map_w + pos.x
	if index < 0 or index >= state.terrain.size():
		return false
	return str(state.terrain[index]) == "water"


## Roll a percentage (0-100) using game RNG
static func _roll_percent(state: GameState) -> int:
	# Simple deterministic RNG based on state
	state.rng_state = (state.rng_state * 1103515245 + 12345) % 2147483648
	return (state.rng_state >> 16) % 101


# =============================================================================
# DAMAGE TYPE INFO
# =============================================================================

## Get damage type color for UI
static func get_damage_type_color(damage_type: int) -> Color:
	match damage_type:
		SimTowerTypes.DamageType.PHYSICAL:
			return Color("#C0C0C0")  # Silver
		SimTowerTypes.DamageType.MAGICAL:
			return Color("#9932CC")  # Purple
		SimTowerTypes.DamageType.COLD:
			return Color("#87CEEB")  # Sky blue
		SimTowerTypes.DamageType.POISON:
			return Color("#32CD32")  # Lime green
		SimTowerTypes.DamageType.LIGHTNING:
			return Color("#FFD700")  # Gold
		SimTowerTypes.DamageType.HOLY:
			return Color("#FFFFFF")  # White
		SimTowerTypes.DamageType.FIRE:
			return Color("#FF4500")  # Orange red
		SimTowerTypes.DamageType.PURE:
			return Color("#FF00FF")  # Magenta
	return Color.WHITE


## Get damage type name for UI
static func get_damage_type_name(damage_type: int) -> String:
	return SimTowerTypes.damage_type_to_string(damage_type).capitalize()


## Get damage type description
static func get_damage_type_description(damage_type: int) -> String:
	match damage_type:
		SimTowerTypes.DamageType.PHYSICAL:
			return "Reduced by armor"
		SimTowerTypes.DamageType.MAGICAL:
			return "Ignores armor"
		SimTowerTypes.DamageType.COLD:
			return "Slows enemies, 3x vs burning"
		SimTowerTypes.DamageType.POISON:
			return "DoT, stacks, ignores half armor"
		SimTowerTypes.DamageType.LIGHTNING:
			return "Chains between enemies"
		SimTowerTypes.DamageType.HOLY:
			return "Bonus vs affixed/corrupted"
		SimTowerTypes.DamageType.FIRE:
			return "DoT, 3x vs frozen"
		SimTowerTypes.DamageType.PURE:
			return "Ignores all resistances"
	return ""
