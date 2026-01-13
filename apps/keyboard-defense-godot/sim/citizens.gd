class_name SimCitizens
extends RefCounted
## Citizen identity system for the kingdom.
## Citizens are named individuals with professions, skills, morale, and traits.
## Wraps the existing worker system with identity and progression.

# =============================================================================
# CONSTANTS
# =============================================================================

## Base morale value for new citizens
const BASE_MORALE := 50.0

## Morale thresholds
const MORALE_HIGH := 75.0
const MORALE_LOW := 25.0

## Skill level range
const MIN_SKILL := 1
const MAX_SKILL := 5

## Morale modifiers
const MORALE_MODIFIERS := {
	"food_surplus": 10.0,
	"starvation": -30.0,
	"wave_survived": 5.0,
	"casualty": -10.0,
	"good_housing": 15.0,
	"poor_housing": -15.0,
	"victory": 20.0,
	"defeat": -25.0
}

## Productivity modifiers based on morale
const PRODUCTIVITY_BY_MORALE := {
	"very_high": 1.25,   # Morale >= 90
	"high": 1.10,        # Morale >= 75
	"normal": 1.0,       # Morale 50-74
	"low": 0.85,         # Morale 25-49
	"very_low": 0.60     # Morale < 25
}

# Cached name data
static var _name_data: Dictionary = {}
static var _next_citizen_id: int = 1


# =============================================================================
# DATA LOADING
# =============================================================================

## Load name pools from JSON
static func _ensure_name_data() -> void:
	if _name_data.is_empty():
		var file := FileAccess.open("res://data/names.json", FileAccess.READ)
		if file:
			var json := JSON.new()
			if json.parse(file.get_as_text()) == OK:
				_name_data = json.data
			file.close()


## Get name pools
static func get_name_data() -> Dictionary:
	_ensure_name_data()
	return _name_data


# =============================================================================
# CITIZEN CREATION
# =============================================================================

## Create a new citizen with procedurally generated attributes
static func create_citizen(profession: String = "", rng: RandomNumberGenerator = null) -> Dictionary:
	_ensure_name_data()

	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()

	var citizen := {
		"id": _next_citizen_id,
		"first_name": _generate_first_name(rng),
		"last_name": _generate_last_name(rng),
		"profession": profession if profession != "" else _random_profession(rng),
		"skill_level": 1,
		"skill_xp": 0.0,
		"morale": BASE_MORALE,
		"assigned_building": -1,
		"traits": _generate_traits(rng),
		"days_employed": 0,
		"lifetime_production": 0.0
	}

	_next_citizen_id += 1
	return citizen


## Generate a first name from pools
static func _generate_first_name(rng: RandomNumberGenerator) -> String:
	var pools: Dictionary = _name_data.get("first_names", {})
	var pool_names := pools.keys()

	if pool_names.is_empty():
		return "Citizen"

	# Weight common names higher
	var pool_weights := {
		"common": 70,
		"noble": 15,
		"rustic": 15
	}

	var total_weight := 0
	for pool_name in pool_names:
		total_weight += pool_weights.get(pool_name, 10)

	var roll := rng.randi_range(0, total_weight - 1)
	var cumulative := 0
	var selected_pool := "common"

	for pool_name in pool_names:
		cumulative += pool_weights.get(pool_name, 10)
		if roll < cumulative:
			selected_pool = pool_name
			break

	var names: Array = pools.get(selected_pool, ["Citizen"])
	if names.is_empty():
		return "Citizen"

	return names[rng.randi_range(0, names.size() - 1)]


## Generate a last name from pools
static func _generate_last_name(rng: RandomNumberGenerator) -> String:
	var pools: Dictionary = _name_data.get("last_names", {})
	var pool_names := pools.keys()

	if pool_names.is_empty():
		return "Worker"

	# Weight common and trade names higher
	var pool_weights := {
		"common": 50,
		"trade": 35,
		"place": 15
	}

	var total_weight := 0
	for pool_name in pool_names:
		total_weight += pool_weights.get(pool_name, 10)

	var roll := rng.randi_range(0, total_weight - 1)
	var cumulative := 0
	var selected_pool := "common"

	for pool_name in pool_names:
		cumulative += pool_weights.get(pool_name, 10)
		if roll < cumulative:
			selected_pool = pool_name
			break

	var names: Array = pools.get(selected_pool, ["Worker"])
	if names.is_empty():
		return "Worker"

	return names[rng.randi_range(0, names.size() - 1)]


## Get a random profession
static func _random_profession(rng: RandomNumberGenerator) -> String:
	var professions: Array = _name_data.get("professions", [])
	if professions.is_empty():
		return "worker"

	var idx := rng.randi_range(0, professions.size() - 1)
	return professions[idx].get("id", "worker")


## Generate traits for a citizen (0-2 traits)
static func _generate_traits(rng: RandomNumberGenerator) -> Array:
	var traits_data: Dictionary = _name_data.get("traits", {})
	var result := []

	# Chance to have traits
	var trait_roll := rng.randf()
	if trait_roll > 0.7:  # 30% chance for no traits
		return result

	# Determine how many traits (1 or 2)
	var num_traits := 1 if rng.randf() < 0.7 else 2

	# Build pool of all traits
	var all_traits := []
	for category in ["positive", "negative", "neutral"]:
		var category_traits: Array = traits_data.get(category, [])
		for trait_item in category_traits:
			all_traits.append(trait_item.get("id", ""))

	# Pick random traits
	all_traits.shuffle()
	for i in range(mini(num_traits, all_traits.size())):
		if all_traits[i] != "":
			result.append(all_traits[i])

	return result


# =============================================================================
# CITIZEN QUERIES
# =============================================================================

## Get citizen's full name
static func get_full_name(citizen: Dictionary) -> String:
	return "%s %s" % [citizen.get("first_name", "Unknown"), citizen.get("last_name", "Citizen")]


## Get citizen's title based on skill level
static func get_title(citizen: Dictionary) -> String:
	var title_prefixes: Dictionary = _name_data.get("title_prefixes", {})
	var skill_level: int = citizen.get("skill_level", 1)
	var skill_key: String = "skill_%d" % skill_level
	var prefix: String = title_prefixes.get(skill_key, "")

	var profession_id: String = citizen.get("profession", "worker")
	var profession_name: String = _get_profession_name(profession_id)

	if prefix.is_empty():
		return profession_name
	return "%s %s" % [prefix, profession_name]


## Get profession display name
static func _get_profession_name(profession_id: String) -> String:
	_ensure_name_data()
	var professions: Array = _name_data.get("professions", [])

	for prof in professions:
		if prof.get("id") == profession_id:
			return prof.get("name", profession_id.capitalize())

	return profession_id.capitalize()


## Get trait display info
static func get_trait_info(trait_id: String) -> Dictionary:
	_ensure_name_data()
	var traits_data: Dictionary = _name_data.get("traits", {})

	for category in ["positive", "negative", "neutral"]:
		var category_traits: Array = traits_data.get(category, [])
		for trait_item in category_traits:
			if trait_item.get("id") == trait_id:
				return {
					"id": trait_id,
					"name": trait_item.get("name", trait_id.capitalize()),
					"description": trait_item.get("description", ""),
					"effect": trait_item.get("effect", {}),
					"category": category
				}

	return {"id": trait_id, "name": trait_id.capitalize(), "description": "", "effect": {}, "category": "neutral"}


## Get all traits for a citizen with full info
static func get_citizen_traits(citizen: Dictionary) -> Array:
	var result := []
	var trait_ids: Array = citizen.get("traits", [])

	for trait_id in trait_ids:
		result.append(get_trait_info(trait_id))

	return result


# =============================================================================
# MORALE SYSTEM
# =============================================================================

## Calculate current morale for a citizen based on state
static func calculate_morale(citizen: Dictionary, state) -> float:
	var base_morale: float = citizen.get("morale", BASE_MORALE)
	var modifier := 0.0

	# Food situation
	var food: int = state.resources.get("food", 0)
	var total_workers: int = _count_total_workers(state)

	if food > total_workers * 2:
		modifier += MORALE_MODIFIERS.food_surplus
	elif food <= 0 and total_workers > 0:
		modifier += MORALE_MODIFIERS.starvation

	# Apply trait effects
	var traits: Array = citizen.get("traits", [])
	for trait_id in traits:
		var trait_info := get_trait_info(trait_id)
		var effect: Dictionary = trait_info.get("effect", {})

		if effect.has("morale_floor"):
			base_morale = maxf(base_morale, effect.morale_floor)
		if effect.has("morale_aura"):
			modifier += effect.morale_aura
		if effect.has("morale_recovery"):
			# Applied when morale is recovering
			pass

	return clampf(base_morale + modifier, 0.0, 100.0)


## Get productivity multiplier based on morale
static func get_productivity_multiplier(citizen: Dictionary) -> float:
	var morale: float = citizen.get("morale", BASE_MORALE)
	var base_multiplier := 1.0

	if morale >= 90:
		base_multiplier = PRODUCTIVITY_BY_MORALE.very_high
	elif morale >= MORALE_HIGH:
		base_multiplier = PRODUCTIVITY_BY_MORALE.high
	elif morale >= 50:
		base_multiplier = PRODUCTIVITY_BY_MORALE.normal
	elif morale >= MORALE_LOW:
		base_multiplier = PRODUCTIVITY_BY_MORALE.low
	else:
		base_multiplier = PRODUCTIVITY_BY_MORALE.very_low

	# Apply trait effects
	var traits: Array = citizen.get("traits", [])
	for trait_id in traits:
		var trait_info := get_trait_info(trait_id)
		var effect: Dictionary = trait_info.get("effect", {})

		if effect.has("production_bonus"):
			base_multiplier *= (1.0 + effect.production_bonus)

	return base_multiplier


## Apply morale change to citizen
static func apply_morale_change(citizen: Dictionary, change_type: String) -> void:
	var change: float = MORALE_MODIFIERS.get(change_type, 0.0)

	# Check for recovery trait
	if change > 0:
		var traits: Array = citizen.get("traits", [])
		for trait_id in traits:
			var trait_info := get_trait_info(trait_id)
			var effect: Dictionary = trait_info.get("effect", {})
			if effect.has("morale_recovery"):
				change *= (1.0 + effect.morale_recovery)

	citizen.morale = clampf(citizen.get("morale", BASE_MORALE) + change, 0.0, 100.0)


## Get morale status string
static func get_morale_status(citizen: Dictionary) -> String:
	var morale: float = citizen.get("morale", BASE_MORALE)

	if morale >= 90:
		return "Ecstatic"
	elif morale >= MORALE_HIGH:
		return "Happy"
	elif morale >= 50:
		return "Content"
	elif morale >= MORALE_LOW:
		return "Unhappy"
	else:
		return "Miserable"


# =============================================================================
# SKILL SYSTEM
# =============================================================================

## XP required per skill level
const SKILL_XP_REQUIREMENTS := [0, 100, 300, 600, 1000]

## Add experience and check for level up
static func add_experience(citizen: Dictionary, xp_amount: float) -> bool:
	var current_skill: int = citizen.get("skill_level", 1)
	if current_skill >= MAX_SKILL:
		return false

	# Apply trait modifiers
	var modifier := 1.0
	var traits: Array = citizen.get("traits", [])
	for trait_id in traits:
		var trait_info := get_trait_info(trait_id)
		var effect: Dictionary = trait_info.get("effect", {})
		if effect.has("skill_growth"):
			modifier *= (1.0 + effect.skill_growth)

	citizen.skill_xp = citizen.get("skill_xp", 0.0) + (xp_amount * modifier)

	# Check for level up
	var required: int = SKILL_XP_REQUIREMENTS[mini(current_skill, SKILL_XP_REQUIREMENTS.size() - 1)]
	if citizen.skill_xp >= required and current_skill < MAX_SKILL:
		citizen.skill_level = current_skill + 1
		citizen.skill_xp = 0.0
		return true

	return false


## Get skill bonus for production
static func get_skill_bonus(citizen: Dictionary) -> float:
	var skill_level: int = citizen.get("skill_level", 1)
	# Each skill level adds 10% bonus
	return 1.0 + (skill_level - 1) * 0.10


## Get XP progress to next level (0.0 - 1.0)
static func get_skill_progress(citizen: Dictionary) -> float:
	var current_skill: int = citizen.get("skill_level", 1)
	if current_skill >= MAX_SKILL:
		return 1.0

	var current_xp: float = citizen.get("skill_xp", 0.0)
	var required: int = SKILL_XP_REQUIREMENTS[mini(current_skill, SKILL_XP_REQUIREMENTS.size() - 1)]

	if required <= 0:
		return 0.0

	return clampf(current_xp / float(required), 0.0, 1.0)


# =============================================================================
# STATE INTEGRATION
# =============================================================================

## Initialize citizens array in state if not present
static func ensure_citizens(state) -> void:
	if not state.get("citizens"):
		state.citizens = []


## Get all citizens from state
static func get_citizens(state) -> Array:
	ensure_citizens(state)
	return state.citizens


## Find citizen by ID
static func find_citizen(state, citizen_id: int) -> Dictionary:
	var citizens: Array = get_citizens(state)
	for citizen in citizens:
		if citizen.get("id") == citizen_id:
			return citizen
	return {}


## Find citizens assigned to a building
static func find_citizens_at_building(state, building_index: int) -> Array:
	var result := []
	var citizens: Array = get_citizens(state)

	for citizen in citizens:
		if citizen.get("assigned_building") == building_index:
			result.append(citizen)

	return result


## Add citizen to state
static func add_citizen(state, citizen: Dictionary) -> void:
	ensure_citizens(state)
	state.citizens.append(citizen)


## Remove citizen from state
static func remove_citizen(state, citizen_id: int) -> bool:
	ensure_citizens(state)
	for i in range(state.citizens.size()):
		if state.citizens[i].get("id") == citizen_id:
			state.citizens.remove_at(i)
			return true
	return false


## Assign citizen to building
static func assign_to_building(state, citizen_id: int, building_index: int) -> bool:
	var citizen := find_citizen(state, citizen_id)
	if citizen.is_empty():
		return false

	# Remove from previous assignment
	var previous_building: int = citizen.get("assigned_building", -1)
	if previous_building >= 0 and previous_building != building_index:
		# Update worker count at previous building if using worker system
		pass

	citizen.assigned_building = building_index
	return true


## Unassign citizen from building
static func unassign_from_building(state, citizen_id: int) -> bool:
	var citizen := find_citizen(state, citizen_id)
	if citizen.is_empty():
		return false

	citizen.assigned_building = -1
	return true


## Get total production bonus from all citizens at a building
static func get_building_citizen_bonus(state, building_index: int) -> float:
	var citizens := find_citizens_at_building(state, building_index)
	if citizens.is_empty():
		return 0.0

	var total_bonus := 0.0
	for citizen in citizens:
		var skill_bonus := get_skill_bonus(citizen)
		var morale_mult := get_productivity_multiplier(citizen)
		total_bonus += skill_bonus * morale_mult

	return total_bonus


## Daily tick for all citizens
static func daily_tick(state) -> Array[String]:
	var events: Array[String] = []
	var citizens: Array = get_citizens(state)

	for citizen in citizens:
		# Increment days employed
		citizen.days_employed = citizen.get("days_employed", 0) + 1

		# Recalculate morale
		citizen.morale = calculate_morale(citizen, state)

		# Add experience if assigned
		if citizen.get("assigned_building", -1) >= 0:
			var leveled := add_experience(citizen, 10.0)  # Base XP per day
			if leveled:
				var name := get_full_name(citizen)
				var title := get_title(citizen)
				events.append("%s is now a %s!" % [name, title])

	return events


# =============================================================================
# HELPERS
# =============================================================================

## Count total workers in state (from worker system)
static func _count_total_workers(state) -> int:
	var workers: Dictionary = state.get("workers", {})
	var total := 0
	for building_idx in workers:
		total += workers[building_idx]
	return total


## Get citizen count
static func count_citizens(state) -> int:
	return get_citizens(state).size()


## Get unassigned citizens
static func get_unassigned_citizens(state) -> Array:
	var result := []
	var citizens: Array = get_citizens(state)

	for citizen in citizens:
		if citizen.get("assigned_building", -1) < 0:
			result.append(citizen)

	return result


## Get citizens by profession
static func get_citizens_by_profession(state, profession: String) -> Array:
	var result := []
	var citizens: Array = get_citizens(state)

	for citizen in citizens:
		if citizen.get("profession") == profession:
			result.append(citizen)

	return result


## Calculate average morale across all citizens
static func get_average_morale(state) -> float:
	var citizens: Array = get_citizens(state)
	if citizens.is_empty():
		return BASE_MORALE

	var total := 0.0
	for citizen in citizens:
		total += citizen.get("morale", BASE_MORALE)

	return total / float(citizens.size())
