class_name SimFactions
extends RefCounted
## Faction system for diplomatic relations and interactions.
## Manages faction state, relations, and AI decision-making.

# =============================================================================
# FACTION DATA
# =============================================================================

## Faction definitions loaded from data/factions.json
static var _factions_data: Dictionary = {}
static var _loaded: bool = false

## Relation thresholds
const RELATION_HOSTILE := -50
const RELATION_UNFRIENDLY := -20
const RELATION_NEUTRAL := 20
const RELATION_FRIENDLY := 50
const RELATION_ALLIED := 80

## Relation change amounts
const RELATION_CHANGE_TRADE := 10
const RELATION_CHANGE_TRIBUTE := 15
const RELATION_CHANGE_GIFT := 5
const RELATION_CHANGE_ALLIANCE := 25
const RELATION_CHANGE_BROKEN_PACT := -30
const RELATION_CHANGE_WAR_DECLARED := -50
const RELATION_CHANGE_DAILY_DECAY := -1  # Relations decay slowly over time

## Load factions data from JSON
static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true

	var path := "res://data/factions.json"
	if not FileAccess.file_exists(path):
		push_warning("SimFactions: factions.json not found, using defaults")
		_factions_data = _get_default_factions()
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("SimFactions: Could not open factions.json")
		_factions_data = _get_default_factions()
		return

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_warning("SimFactions: Failed to parse factions.json: %s" % json.get_error_message())
		_factions_data = _get_default_factions()
		return

	_factions_data = json.data.get("factions", {})


## Default factions if JSON not available
static func _get_default_factions() -> Dictionary:
	return {
		"northern_tribes": {
			"name": "Northern Tribes",
			"description": "Hardy warriors from the frozen north",
			"personality": "aggressive",
			"base_relation": -10,
			"trade_modifier": 1.2,
			"tribute_base": 50,
			"military_strength": 80,
			"color": "#4a7cb5"
		},
		"merchant_guild": {
			"name": "Merchant Guild",
			"description": "Wealthy traders seeking profit",
			"personality": "mercantile",
			"base_relation": 20,
			"trade_modifier": 0.8,
			"tribute_base": 30,
			"military_strength": 40,
			"color": "#c9a227"
		},
		"forest_clans": {
			"name": "Forest Clans",
			"description": "Reclusive hunters who guard their lands",
			"personality": "isolationist",
			"base_relation": 0,
			"trade_modifier": 1.0,
			"tribute_base": 40,
			"military_strength": 60,
			"color": "#3d8b40"
		}
	}


# =============================================================================
# FACTION QUERIES
# =============================================================================

## Get all faction IDs
static func get_faction_ids() -> Array:
	_ensure_loaded()
	return _factions_data.keys()


## Get faction data by ID
static func get_faction(faction_id: String) -> Dictionary:
	_ensure_loaded()
	return _factions_data.get(faction_id, {})


## Get faction name
static func get_faction_name(faction_id: String) -> String:
	var data := get_faction(faction_id)
	return str(data.get("name", faction_id))


## Get faction color
static func get_faction_color(faction_id: String) -> Color:
	var data := get_faction(faction_id)
	var color_str: String = str(data.get("color", "#888888"))
	return Color.from_string(color_str, Color.GRAY)


## Get faction personality
static func get_faction_personality(faction_id: String) -> String:
	var data := get_faction(faction_id)
	return str(data.get("personality", "neutral"))


# =============================================================================
# RELATION MANAGEMENT
# =============================================================================

## Get current relation with a faction
static func get_relation(state, faction_id: String) -> int:
	if not state.faction_relations.has(faction_id):
		var data := get_faction(faction_id)
		return int(data.get("base_relation", 0))
	return int(state.faction_relations[faction_id])


## Set relation with a faction (clamped to -100 to 100)
static func set_relation(state, faction_id: String, value: int) -> void:
	state.faction_relations[faction_id] = clampi(value, -100, 100)


## Change relation by amount
static func change_relation(state, faction_id: String, amount: int) -> int:
	var current := get_relation(state, faction_id)
	var new_value := clampi(current + amount, -100, 100)
	state.faction_relations[faction_id] = new_value
	return new_value


## Get relation status string
static func get_relation_status(state, faction_id: String) -> String:
	var relation := get_relation(state, faction_id)
	if relation >= RELATION_ALLIED:
		return "allied"
	elif relation >= RELATION_FRIENDLY:
		return "friendly"
	elif relation >= RELATION_NEUTRAL:
		return "neutral"
	elif relation >= RELATION_UNFRIENDLY:
		return "unfriendly"
	else:
		return "hostile"


## Check if faction is hostile
static func is_hostile(state, faction_id: String) -> bool:
	return get_relation(state, faction_id) < RELATION_HOSTILE


## Check if faction is allied
static func is_allied(state, faction_id: String) -> bool:
	return get_relation(state, faction_id) >= RELATION_ALLIED


# =============================================================================
# DIPLOMATIC STATUS
# =============================================================================

## Check if we have a trade agreement with faction
static func has_trade_agreement(state, faction_id: String) -> bool:
	return faction_id in state.faction_agreements.get("trade", [])


## Check if we have a non-aggression pact with faction
static func has_non_aggression_pact(state, faction_id: String) -> bool:
	return faction_id in state.faction_agreements.get("non_aggression", [])


## Check if we have an alliance with faction
static func has_alliance(state, faction_id: String) -> bool:
	return faction_id in state.faction_agreements.get("alliance", [])


## Check if we are at war with faction
static func is_at_war(state, faction_id: String) -> bool:
	return faction_id in state.faction_agreements.get("war", [])


## Get trade modifier with faction (lower = better prices)
static func get_trade_modifier(state, faction_id: String) -> float:
	var data := get_faction(faction_id)
	var base_modifier: float = float(data.get("trade_modifier", 1.0))

	# Trade agreement improves prices
	if has_trade_agreement(state, faction_id):
		base_modifier *= 0.85

	# Good relations improve prices slightly
	var relation := get_relation(state, faction_id)
	if relation >= RELATION_FRIENDLY:
		base_modifier *= 0.95
	elif relation < RELATION_UNFRIENDLY:
		base_modifier *= 1.1

	return base_modifier


## Get tribute demand from faction
static func get_tribute_demand(state, faction_id: String) -> int:
	var data := get_faction(faction_id)
	var base_tribute: int = int(data.get("tribute_base", 50))

	# Scale by day (factions demand more over time)
	var day_mult := 1.0 + (state.day - 1) * 0.05

	# Relations affect tribute
	var relation := get_relation(state, faction_id)
	var relation_mult := 1.0
	if relation >= RELATION_FRIENDLY:
		relation_mult = 0.7
	elif relation < RELATION_UNFRIENDLY:
		relation_mult = 1.3

	return int(base_tribute * day_mult * relation_mult)


## Get military strength of faction (for threat calculations)
static func get_military_strength(faction_id: String) -> int:
	var data := get_faction(faction_id)
	return int(data.get("military_strength", 50))


# =============================================================================
# AI DECISION MAKING
# =============================================================================

## Determine what action a faction wants to take this day
static func get_faction_intent(state, faction_id: String) -> Dictionary:
	var personality := get_faction_personality(faction_id)
	var relation := get_relation(state, faction_id)
	var at_war := is_at_war(state, faction_id)

	# If at war, check if they want peace
	if at_war:
		if relation > RELATION_HOSTILE:
			return {"action": "offer_peace", "faction": faction_id}
		return {"action": "continue_war", "faction": faction_id}

	# Check personality-based actions
	match personality:
		"aggressive":
			if relation < RELATION_UNFRIENDLY and not has_non_aggression_pact(state, faction_id):
				if randf() < 0.1:  # 10% chance to declare war
					return {"action": "declare_war", "faction": faction_id}
			if relation < RELATION_NEUTRAL:
				return {"action": "demand_tribute", "faction": faction_id}

		"mercantile":
			if relation >= RELATION_NEUTRAL and not has_trade_agreement(state, faction_id):
				return {"action": "offer_trade", "faction": faction_id}

		"isolationist":
			if relation < RELATION_NEUTRAL:
				return {"action": "demand_tribute", "faction": faction_id}
			if relation >= RELATION_FRIENDLY and not has_non_aggression_pact(state, faction_id):
				return {"action": "offer_pact", "faction": faction_id}

	return {"action": "none", "faction": faction_id}


# =============================================================================
# STATE INITIALIZATION
# =============================================================================

## Initialize faction state for a new game
static func init_faction_state(state) -> void:
	_ensure_loaded()

	# Initialize relations to base values
	state.faction_relations = {}
	for faction_id in _factions_data:
		var data: Dictionary = _factions_data[faction_id]
		state.faction_relations[faction_id] = int(data.get("base_relation", 0))

	# Initialize agreement tracking
	state.faction_agreements = {
		"trade": [],
		"non_aggression": [],
		"alliance": [],
		"war": []
	}

	# Track pending diplomatic actions
	state.pending_diplomacy = {}


## Apply daily relation decay
static func apply_daily_decay(state) -> void:
	for faction_id in state.faction_relations:
		var current := int(state.faction_relations[faction_id])
		# Relations drift toward base value
		var data := get_faction(faction_id)
		var base: int = int(data.get("base_relation", 0))

		if current > base:
			state.faction_relations[faction_id] = maxi(base, current - 1)
		elif current < base:
			state.faction_relations[faction_id] = mini(base, current + 1)
