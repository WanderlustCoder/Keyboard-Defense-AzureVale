class_name GameState
extends RefCounted

const RESOURCE_KEYS := ["wood", "stone", "food"]
const BUILDING_KEYS := ["farm", "lumber", "quarry", "wall", "tower", "market", "barracks", "temple", "workshop"]

var day: int
var phase: String
var ap_max: int
var ap: int
var hp: int
var threat: int
var resources: Dictionary
var buildings: Dictionary
var map_w: int
var map_h: int
var base_pos: Vector2i
var cursor_pos: Vector2i
var terrain: Array
var structures: Dictionary
var structure_levels: Dictionary
var discovered: Dictionary
var night_prompt: String
var night_spawn_remaining: int
var night_wave_total: int
var enemies: Array
var enemy_next_id: int
var last_path_open: bool
var rng_seed: String
var rng_state: int
var lesson_id: String
var version: int

# Event system state
var active_pois: Dictionary
var event_cooldowns: Dictionary
var event_flags: Dictionary
var pending_event: Dictionary
var active_buffs: Array

# Upgrade system state
var purchased_kingdom_upgrades: Array
var purchased_unit_upgrades: Array
var gold: int

# Worker system state
var workers: Dictionary  # {building_index: worker_count}
var total_workers: int
var max_workers: int
var worker_upkeep: int  # Food consumed per worker per day

# Citizen identity system state
var citizens: Array  # Array of citizen dictionaries

# Research system state
var active_research: String  # Currently researching ID
var research_progress: int  # Waves completed toward research
var completed_research: Array  # List of completed research IDs

# Trade system state
var trade_rates: Dictionary  # Current exchange rates
var last_trade_day: int  # Day of last trade (for rate changes)

# Faction/Diplomacy system state
var faction_relations: Dictionary  # {faction_id: relation_value}
var faction_agreements: Dictionary  # {agreement_type: [faction_ids]}
var pending_diplomacy: Dictionary  # {faction_id: pending_offer_data}

# Accessibility settings (applied from profile)
var speed_multiplier: float
var practice_mode: bool

# Open-world exploration state
var roaming_enemies: Array
var roaming_resources: Array
var threat_level: float
var time_of_day: float
var world_tick_accum: float

# Unified threat system (replaces rigid day/night)
var activity_mode: String  # "exploration", "encounter", "event", "wave_assault"
var encounter_enemies: Array  # Enemies in current local encounter
var wave_cooldown: float  # Time until threat can trigger another wave
var threat_decay_accum: float  # Accumulator for passive threat decay

# Expedition system state
var active_expeditions: Array  # Array of expedition dictionaries
var expedition_next_id: int  # ID counter for expeditions
var expedition_history: Array  # Recent expedition results (for UI)

# Resource node system state
var resource_nodes: Dictionary  # {tile_index: node_data}
var harvested_nodes: Dictionary  # {node_id: last_harvested_day}

# Loot tracking state
var loot_pending: Array  # Pending loot to collect from defeats
var last_loot_quality: float  # Quality modifier from last combat (0.0-2.0)
var perfect_kills: int  # Count of perfect (no mistakes) kills this wave

# Tower system state
var tower_states: Dictionary  # {index: tower_instance_state}
var active_synergies: Array  # Currently active tower synergies
var summoned_units: Array  # Summoned units from summoner towers
var summoned_next_id: int  # Counter for summoned unit IDs
var active_traps: Array  # Placed traps from trap towers
var tower_charge: Dictionary  # {index: charge_turns} for siege towers
var tower_cooldowns: Dictionary  # {index: cooldown_remaining}
var tower_summon_ids: Dictionary  # {index: [summoned_unit_ids]}

# Typing metrics for tower damage scaling
var typing_metrics: Dictionary  # Real-time WPM, accuracy, letter tracking
var arrow_rain_timer: float  # Timer for Arrow Rain synergy

# Hero system state
var hero_id: String  # Selected hero ID (empty for no hero)
var hero_ability_cooldown: float  # Remaining cooldown for hero ability
var hero_active_effects: Array  # Active hero ability effects

# Title system state (synced from profile)
var equipped_title: String  # Currently equipped title ID
var unlocked_titles: Array  # Array of unlocked title IDs
var unlocked_badges: Array  # Array of unlocked badge IDs

# Victory system state
var victory_achieved: Array  # Array of achieved victory condition IDs
var victory_checked: bool  # Whether victory has been checked this turn
var peak_gold: int  # Highest gold amount achieved (for economic victory tracking)
var story_completed: bool  # Whether the full story campaign is complete
var current_act: int  # Current story act (1-5)

func _init() -> void:
	day = 1
	phase = "day"
	ap_max = 3
	ap = ap_max
	hp = 10
	threat = 0
	map_w = 16
	map_h = 10
	base_pos = Vector2i(int(map_w / 2), int(map_h / 2))
	cursor_pos = base_pos
	night_prompt = ""
	night_spawn_remaining = 0
	night_wave_total = 0
	enemies = []
	enemy_next_id = 1
	last_path_open = true
	rng_seed = "default"
	rng_state = 0
	lesson_id = "full_alpha"
	version = 1

	resources = {}
	for key in RESOURCE_KEYS:
		resources[key] = 0

	buildings = {}
	for key in BUILDING_KEYS:
		buildings[key] = 0

	terrain = []
	for _i in range(map_w * map_h):
		terrain.append("")

	structures = {}
	structure_levels = {}

	discovered = {}

	# Event system initialization
	active_pois = {}
	event_cooldowns = {}
	event_flags = {}
	pending_event = {}
	active_buffs = []

	# Upgrade system initialization
	purchased_kingdom_upgrades = []
	purchased_unit_upgrades = []
	gold = 0

	# Worker system initialization
	workers = {}
	total_workers = 3
	max_workers = 10
	worker_upkeep = 1

	# Citizen identity system initialization
	citizens = []

	# Research system initialization
	active_research = ""
	research_progress = 0
	completed_research = []

	# Trade system initialization
	trade_rates = {
		"wood_to_stone": 1.5,  # 3 wood = 2 stone
		"stone_to_wood": 0.67,
		"food_to_gold": 0.5,   # 2 food = 1 gold
		"gold_to_food": 2.0,
		"wood_to_gold": 0.33,  # 3 wood = 1 gold
		"gold_to_wood": 3.0,
		"stone_to_gold": 0.5,  # 2 stone = 1 gold
		"gold_to_stone": 2.0
	}
	last_trade_day = 0

	# Faction/Diplomacy system initialization
	faction_relations = {}
	faction_agreements = {
		"trade": [],
		"non_aggression": [],
		"alliance": [],
		"war": []
	}
	pending_diplomacy = {}

	# Accessibility defaults
	speed_multiplier = 1.0
	practice_mode = false

	# Open-world exploration initialization
	roaming_enemies = []
	roaming_resources = []
	threat_level = 0.0
	time_of_day = 0.25  # Start at morning (0.0=midnight, 0.5=noon, 1.0=midnight)
	world_tick_accum = 0.0

	# Unified threat system initialization
	activity_mode = "exploration"
	encounter_enemies = []
	wave_cooldown = 0.0
	threat_decay_accum = 0.0

	# Expedition system initialization
	active_expeditions = []
	expedition_next_id = 1
	expedition_history = []

	# Resource node system initialization
	resource_nodes = {}
	harvested_nodes = {}

	# Loot tracking initialization
	loot_pending = []
	last_loot_quality = 1.0
	perfect_kills = 0

	# Tower system initialization
	tower_states = {}
	active_synergies = []
	summoned_units = []
	summoned_next_id = 1
	active_traps = []
	tower_charge = {}
	tower_cooldowns = {}
	tower_summon_ids = {}

	# Typing metrics initialization
	typing_metrics = {
		"battle_chars_typed": 0,
		"battle_words_typed": 0,
		"battle_start_msec": 0,
		"battle_errors": 0,
		"rolling_window_chars": [],
		"unique_letters_window": {},
		"perfect_word_streak": 0,
		"current_word_errors": 0
	}
	arrow_rain_timer = 0.0

	# Hero system initialization
	hero_id = ""
	hero_ability_cooldown = 0.0
	hero_active_effects = []

	# Title system initialization
	equipped_title = ""
	unlocked_titles = []
	unlocked_badges = []

	# Victory system initialization
	victory_achieved = []
	victory_checked = false
	peak_gold = 0
	story_completed = false
	current_act = 1

	discovered[_index(base_pos.x, base_pos.y)] = true

func _index(x: int, y: int) -> int:
	return y * map_w + x
