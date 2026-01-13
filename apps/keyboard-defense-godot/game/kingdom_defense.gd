extends Control

## Kingdom Defense - Top-Down RTS Typing Game
## Inspired by Super Fantasy Kingdom with typing-based combat and commands

const GameState = preload("res://sim/types.gd")
const SimMap = preload("res://sim/map.gd")
const SimEnemies = preload("res://sim/enemies.gd")
const SimLessons = preload("res://sim/lessons.gd")
const SimWords = preload("res://sim/words.gd")
const DefaultState = preload("res://sim/default_state.gd")
const StoryManager = preload("res://game/story_manager.gd")
const SimBuildings = preload("res://sim/buildings.gd")
const SimWorkers = preload("res://sim/workers.gd")
const SimResearch = preload("res://sim/research.gd")
const SimTrade = preload("res://sim/trade.gd")
const SimExpeditions = preload("res://sim/expeditions.gd")
const KingdomDashboard = preload("res://ui/components/kingdom_dashboard.gd")
const SettingsPanel = preload("res://ui/components/settings_panel.gd")
const GamePersistence = preload("res://game/persistence.gd")
const TypingProfile = preload("res://game/typing_profile.gd")
const AchievementChecker = preload("res://game/achievement_checker.gd")
const AchievementPanel = preload("res://ui/components/achievement_panel.gd")
const ACHIEVEMENT_POPUP_SCENE := preload("res://ui/components/achievement_popup.tscn")
const ACHIEVEMENT_PANEL_SCENE := preload("res://ui/components/achievement_panel.tscn")
const LorePanel = preload("res://ui/components/lore_panel.gd")
const SimDifficulty = preload("res://sim/difficulty.gd")
const SimCombo = preload("res://sim/combo.gd")

const SimSkills = preload("res://sim/skills.gd")
const SimItems = preload("res://sim/items.gd")
const SimSpecialCommands = preload("res://sim/special_commands.gd")
const SimQuests = preload("res://sim/quests.gd")
const SimBestiary = preload("res://sim/bestiary.gd")
const BestiaryPanel = preload("res://ui/components/bestiary_panel.gd")
const WaveSummaryPanel = preload("res://ui/components/wave_summary_panel.gd")
const RunSummaryPanel = preload("res://ui/components/run_summary_panel.gd")
const TipNotification = preload("res://ui/components/tip_notification.gd")
const SimMilestones = preload("res://sim/milestones.gd")
const SimPlayerStats = preload("res://sim/player_stats.gd")
const SimLoginRewards = preload("res://sim/login_rewards.gd")
const SimDailyChallenges = preload("res://sim/daily_challenges.gd")
const SimEndlessMode = preload("res://sim/endless_mode.gd")
const SimCrafting = preload("res://sim/crafting.gd")
const SimWaveComposer = preload("res://sim/wave_composer.gd")
const SimAutoTowerCombat = preload("res://sim/auto_tower_combat.gd")
const MilestonePopup = preload("res://ui/components/milestone_popup.gd")
const StatsDashboard = preload("res://ui/components/stats_dashboard.gd")
const EquipmentPanel = preload("res://ui/components/equipment_panel.gd")
const SkillsPanel = preload("res://ui/components/skills_panel.gd")
const ShopPanel = preload("res://ui/components/shop_panel.gd")
const QuestsPanel = preload("res://ui/components/quests_panel.gd")
const HelpPanel = preload("res://ui/components/help_panel.gd")
const EffectsPanel = preload("res://ui/components/effects_panel.gd")
const AutoTowersPanel = preload("res://ui/components/auto_towers_panel.gd")
const SpellsPanel = preload("res://ui/components/spells_panel.gd")
const WaveInfoPanel = preload("res://ui/components/wave_info_panel.gd")
const DifficultyPanel = preload("res://ui/components/difficulty_panel.gd")
const EndlessModePanel = preload("res://ui/components/endless_mode_panel.gd")
const MaterialsPanel = preload("res://ui/components/materials_panel.gd")
const RecipesPanel = preload("res://ui/components/recipes_panel.gd")
const DailyChallengePanel = preload("res://ui/components/daily_challenge_panel.gd")
const TokenShopPanel = preload("res://ui/components/token_shop_panel.gd")
const StatsPanel = preload("res://ui/components/stats_panel.gd")
const ExpeditionsPanel = preload("res://ui/components/expeditions_panel.gd")
const SynergiesPanel = preload("res://ui/components/synergies_panel.gd")
const BuffsPanel = preload("res://ui/components/buffs_panel.gd")
const SummonedUnitsPanel = preload("res://ui/components/summoned_units_panel.gd")
const LootPanel = preload("res://ui/components/loot_panel.gd")
const ResourceNodesPanel = preload("res://ui/components/resource_nodes_panel.gd")

const SimResourceNodes = preload("res://sim/resource_nodes.gd")
const AffixesPanel = preload("res://ui/components/affixes_panel.gd")
const DamageTypesPanel = preload("res://ui/components/damage_types_panel.gd")
const PoiPanel = preload("res://ui/components/poi_panel.gd")
const TowerEncyclopediaPanel = preload("res://ui/components/tower_encyclopedia_panel.gd")

const SimPoi = preload("res://sim/poi.gd")
const StatusEffectsPanel = preload("res://ui/components/status_effects_panel.gd")
const ComboSystemPanel = preload("res://ui/components/combo_system_panel.gd")
const MilestonesPanel = preload("res://ui/components/milestones_panel.gd")
const PracticeGoalsPanel = preload("res://ui/components/practice_goals_panel.gd")
const WaveThemesPanel = preload("res://ui/components/wave_themes_panel.gd")
const SpecialCommandsPanel = preload("res://ui/components/special_commands_panel.gd")
const LifetimeStatsPanel = preload("res://ui/components/lifetime_stats_panel.gd")
const KeyboardReferencePanel = preload("res://ui/components/keyboard_reference_panel.gd")
const LoginRewardsPanel = preload("res://ui/components/login_rewards_panel.gd")
const TypingTowerBonusesPanel = preload("res://ui/components/typing_tower_bonuses_panel.gd")
const ResearchTreePanel = preload("res://ui/components/research_tree_panel.gd")
const TradePanel = preload("res://ui/components/trade_panel.gd")
const TargetingModesPanel = preload("res://ui/components/targeting_modes_panel.gd")
const WorkersPanel = preload("res://ui/components/workers_panel.gd")
const EventEffectsPanel = preload("res://ui/components/event_effects_panel.gd")
const UpgradesPanel = preload("res://ui/components/upgrades_panel.gd")
const BalanceReferencePanel = preload("res://ui/components/balance_reference_panel.gd")
const WaveCompositionPanel = preload("res://ui/components/wave_composition_panel.gd")
const SynergyReferencePanel = preload("res://ui/components/synergy_reference_panel.gd")
const TypingMetricsPanel = preload("res://ui/components/typing_metrics_panel.gd")
const TowerTypesReferencePanel = preload("res://ui/components/tower_types_reference_panel.gd")
const EnemyTypesReferencePanel = preload("res://ui/components/enemy_types_reference_panel.gd")
const BuildingTypesReferencePanel = preload("res://ui/components/building_types_reference_panel.gd")
const ResearchTreeReferencePanel = preload("res://ui/components/research_tree_reference_panel.gd")
const WorkersReferencePanel = preload("res://ui/components/workers_reference_panel.gd")
const TradeReferencePanel = preload("res://ui/components/trade_reference_panel.gd")
const LessonsReferencePanel = preload("res://ui/components/lessons_reference_panel.gd")
const KingdomUpgradesReferencePanel = preload("res://ui/components/kingdom_upgrades_reference_panel.gd")
const SpecialCommandsReferencePanel = preload("res://ui/components/special_commands_reference_panel.gd")
const StatusEffectsReferencePanel = preload("res://ui/components/status_effects_reference_panel.gd")
const ComboSystemReferencePanel = preload("res://ui/components/combo_system_reference_panel.gd")
const DifficultyModesReferencePanel = preload("res://ui/components/difficulty_modes_reference_panel.gd")
const DamageTypesReferencePanel = preload("res://ui/components/damage_types_reference_panel.gd")
const EnemyAffixesReferencePanel = preload("res://ui/components/enemy_affixes_reference_panel.gd")
const EquipmentItemsReferencePanel = preload("res://ui/components/equipment_items_reference_panel.gd")
const SkillTreesReferencePanel = preload("res://ui/components/skill_trees_reference_panel.gd")
const ExpeditionsReferencePanel = preload("res://ui/components/expeditions_reference_panel.gd")
const DailyChallengesReferencePanel = preload("res://ui/components/daily_challenges_reference_panel.gd")
const MilestonesReferencePanel = preload("res://ui/components/milestones_reference_panel.gd")
const LoginRewardsReferencePanel = preload("res://ui/components/login_rewards_reference_panel.gd")
const LootSystemReferencePanel = preload("res://ui/components/loot_system_reference_panel.gd")
const QuestsReferencePanel = preload("res://ui/components/quests_reference_panel.gd")
const ResourceNodesReferencePanel = preload("res://ui/components/resource_nodes_reference_panel.gd")
const PlayerStatsReferencePanel = preload("res://ui/components/player_stats_reference_panel.gd")
const WaveComposerReferencePanel = preload("res://ui/components/wave_composer_reference_panel.gd")

# UI Node references
@onready var grid_renderer: Node2D = $GridRenderer
@onready var day_label: Label = $HUD/TopBar/HBox/DayLabel
@onready var wave_label: Label = $HUD/TopBar/HBox/WaveLabel
@onready var hp_value: Label = $HUD/TopBar/HBox/HPBar/HPValue
@onready var gold_value: Label = $HUD/TopBar/HBox/GoldBar/GoldValue
@onready var resources_label: Label = $HUD/TopBar/HBox/ResourceBar/ResourcesLabel
@onready var lesson_label: Label = $HUD/TopBar/HBox/LessonLabel
@onready var phase_label: Label = $HUD/TopBar/HBox/PhaseLabel
@onready var menu_button: Button = $HUD/TopBar/HBox/MenuButton
@onready var enemy_panel: Panel = $HUD/EnemyPanel
@onready var current_enemy_label: RichTextLabel = $HUD/EnemyPanel/VBox/CurrentEnemy/CurrentLabel
@onready var queue_list: RichTextLabel = $HUD/EnemyPanel/VBox/QueueList
@onready var typing_panel: Panel = $HUD/TypingPanel
@onready var word_display: RichTextLabel = $HUD/TypingPanel/VBox/WordDisplay
@onready var input_display: Label = $HUD/TypingPanel/VBox/InputDisplay
@onready var input_field: LineEdit = $HUD/TypingPanel/VBox/InputField
@onready var wpm_label: Label = $HUD/TypingPanel/VBox/StatsBar/WPMLabel
@onready var accuracy_label: Label = $HUD/TypingPanel/VBox/StatsBar/AccuracyLabel
@onready var combo_label: Label = $HUD/TypingPanel/VBox/StatsBar/ComboLabel
@onready var power_label: Label = $HUD/TypingPanel/VBox/StatsBar/PowerLabel
@onready var hint_label: Label = $HUD/TypingPanel/VBox/HintLabel
@onready var tip_label: Label = $HUD/TypingPanel/VBox/TipLabel
@onready var finger_hint_label: Label = $HUD/TypingPanel/VBox/FingerHintLabel
@onready var objective_label: RichTextLabel = $HUD/ObjectivePanel/ObjectiveLabel
@onready var keyboard_display: Control = $HUD/TypingPanel/VBox/KeyboardPanel
@onready var act_label: Label = $HUD/TopBar/HBox/ActLabel
@onready var dialogue_box: Control = $DialogueBox
@onready var game_controller = get_node_or_null("/root/GameController")
@onready var audio_manager = get_node_or_null("/root/AudioManager")

# Game state
var state: GameState
var current_phase: String = "planning"  # "planning" or "defense"
var day: int = 1
var wave: int = 1
var waves_per_day: int = 3
var castle_hp: int = 10
var castle_max_hp: int = 10
var gold: int = 50

# Enemy management
var active_enemies: Array = []  # Enemies on the field with real-time positions
var enemy_queue: Array = []  # Enemies waiting to spawn
var spawn_timer: float = 0.0
var spawn_interval: float = 2.0
var target_enemy_id: int = -1  # Currently targeted enemy

# Typing state
var current_word: String = ""
var typed_text: String = ""
var combo: int = 0
var max_combo: int = 0
var correct_chars: int = 0
var total_chars: int = 0
var words_typed: int = 0
var wave_start_time: float = 0.0
var word_start_time: float = 0.0
var current_wave_composition: Dictionary = {}  # Wave composer output

# Skill system tracking
var words_typed_this_wave: int = 0
var kills_this_wave: int = 0
var gold_earned_this_wave: int = 0
var last_kill_time: float = 0.0
var chain_kill_count: int = 0
var active_skill_buffs: Dictionary = {}  # {skill_id: {remaining: float, effect: value}}

# Active item buffs
var active_item_buffs: Dictionary = {}  # {buff_type: {remaining: float, value: float}}

# Auto-tower cooldowns and states
var auto_tower_cooldowns: Dictionary = {}  # {tower_index: remaining_cooldown}
var auto_tower_states: Dictionary = {}  # {tower_index: {heat, fuel, ramp_multiplier, etc.}}

# Distance field cache (performance optimization)
var _cached_dist_field: PackedInt32Array = PackedInt32Array()
var _dist_field_valid: bool = false
var _last_structure_hash: int = 0

# Special command tracking
var command_cooldowns: Dictionary = {}  # {command_id: remaining_cooldown}
var command_effects: Dictionary = {}  # Active effects like {damage_charges: 5, crit_charges: 3, etc.}
var auto_tower_speed_buff: float = 1.0  # Multiplier for auto-tower attack speed

# Quest tracking
var quest_state: Dictionary = {}  # Stores daily/weekly/challenge quest progress
var session_stats: Dictionary = {}  # Tracks stats for quest progress this session

# Endless mode tracking
var is_endless_mode: bool = false
var endless_run_kills: int = 0
var endless_day_start_time: float = 0.0

# Daily challenge tracking
var is_challenge_mode: bool = false
var challenge_state: Dictionary = {}
var challenge_kills: int = 0
var challenge_words: int = 0
var challenge_gold_earned: int = 0
var challenge_boss_kills: int = 0

# Lesson progression
var lesson_order: Array[String] = [
	"home_row_1", "home_row_2",
	"reach_row_1", "reach_row_2",
	"bottom_row_1", "bottom_row_2",
	"upper_row_1", "upper_row_2",
	"mixed_rows", "speed_alpha",
	"nexus_blend", "apex_mastery"
]
var current_lesson_index: int = 0
var lesson_accuracy_threshold: float = 0.8  # 80% accuracy to unlock next

# Planning phase
var planning_timer: float = 30.0
var cursor_grid_pos: Vector2i = Vector2i(8, 5)

# Story state
var last_act_intro_day: int = 0
var game_started: bool = false
var waiting_for_dialogue: bool = false

# Educational tracking
var tip_timer: float = 0.0
var tip_interval: float = 8.0
var last_wpm_milestone: int = 0
var previous_lesson_id: String = ""
var show_finger_hints: bool = true

# Key practice mode
var practice_mode: bool = false
var practice_keys: Array[String] = []
var practice_index: int = 0
var practice_lesson_id: String = ""
var practice_correct_count: int = 0
var practice_attempts: int = 0
var pending_practice_lesson: String = ""  # Lesson to practice after dialogue

# Build commands
const BUILD_COMMANDS := {
	"build tower": "tower",
	"build wall": "wall",
	"build farm": "farm",
	"build lumber": "lumber",
	"build quarry": "quarry",
	"build market": "market",
	"build barracks": "barracks",
	"build temple": "temple",
	"build workshop": "workshop",
	"build sentry": "sentry",
	"build spark": "spark",
	"build flame": "flame",
	"tower": "tower",
	"wall": "wall",
	"farm": "farm",
	"lumber": "lumber",
	"quarry": "quarry",
	"market": "market",
	"barracks": "barracks",
	"temple": "temple",
	"workshop": "workshop",
	"sentry": "sentry",
	"spark": "spark",
	"flame": "flame"
}

# Kingdom management
var kingdom_dashboard: KingdomDashboard = null
var settings_panel: SettingsPanel = null
var research_instance: SimResearch = null

# Achievement and profile system
var profile: Dictionary = {}
var achievement_checker: AchievementChecker = null
var achievement_popup: Node = null
var achievement_panel: AchievementPanel = null
var notification_manager: NotificationManager = null
var damage_taken_this_wave: int = 0
var damage_taken_this_day: int = 0
var lore_panel: LorePanel = null
var bestiary_panel: BestiaryPanel = null
var wave_summary_panel: WaveSummaryPanel = null
var run_summary_panel: RunSummaryPanel = null
var tip_notification: TipNotification = null
var milestone_popup: MilestonePopup = null
var stats_dashboard: StatsDashboard = null
var equipment_panel: EquipmentPanel = null
var skills_panel: SkillsPanel = null
var shop_panel: ShopPanel = null
var quests_panel: QuestsPanel = null
var help_panel: HelpPanel = null
var effects_panel: EffectsPanel = null
var auto_towers_panel: AutoTowersPanel = null
var spells_panel: SpellsPanel = null
var wave_info_panel: WaveInfoPanel = null
var difficulty_panel: DifficultyPanel = null
var endless_mode_panel: EndlessModePanel = null
var materials_panel: MaterialsPanel = null
var recipes_panel: RecipesPanel = null
var daily_challenge_panel: DailyChallengePanel = null
var token_shop_panel: TokenShopPanel = null
var stats_panel: StatsPanel = null
var expeditions_panel: ExpeditionsPanel = null
var synergies_panel: SynergiesPanel = null
var buffs_panel: BuffsPanel = null
var summoned_units_panel: SummonedUnitsPanel = null
var loot_panel: LootPanel = null
var resource_nodes_panel: ResourceNodesPanel = null
var affixes_panel: AffixesPanel = null
var damage_types_panel: DamageTypesPanel = null
var poi_panel: PoiPanel = null
var tower_encyclopedia_panel: TowerEncyclopediaPanel = null
var status_effects_panel: StatusEffectsPanel = null
var combo_system_panel: ComboSystemPanel = null
var milestones_panel: MilestonesPanel = null
var practice_goals_panel: PracticeGoalsPanel = null
var wave_themes_panel: WaveThemesPanel = null
var special_commands_panel: SpecialCommandsPanel = null
var lifetime_stats_panel: LifetimeStatsPanel = null
var keyboard_reference_panel: KeyboardReferencePanel = null
var login_rewards_panel: LoginRewardsPanel = null
var typing_tower_bonuses_panel: TypingTowerBonusesPanel = null
var research_tree_panel: ResearchTreePanel = null
var trade_panel: TradePanel = null
var targeting_modes_panel: TargetingModesPanel = null
var workers_panel: WorkersPanel = null
var event_effects_panel: EventEffectsPanel = null
var upgrades_panel: UpgradesPanel = null
var balance_reference_panel: BalanceReferencePanel = null
var wave_composition_panel: WaveCompositionPanel = null
var synergy_reference_panel: SynergyReferencePanel = null
var typing_metrics_panel: TypingMetricsPanel = null
var tower_types_reference_panel: TowerTypesReferencePanel = null
var enemy_types_reference_panel: EnemyTypesReferencePanel = null
var building_types_reference_panel: BuildingTypesReferencePanel = null
var research_tree_reference_panel: ResearchTreeReferencePanel = null
var workers_reference_panel: WorkersReferencePanel = null
var trade_reference_panel: TradeReferencePanel = null
var lessons_reference_panel: LessonsReferencePanel = null
var kingdom_upgrades_reference_panel: KingdomUpgradesReferencePanel = null
var special_commands_reference_panel: SpecialCommandsReferencePanel = null
var status_effects_reference_panel: StatusEffectsReferencePanel = null
var combo_system_reference_panel: ComboSystemReferencePanel = null
var difficulty_modes_reference_panel: DifficultyModesReferencePanel = null
var damage_types_reference_panel: DamageTypesReferencePanel = null
var enemy_affixes_reference_panel: EnemyAffixesReferencePanel = null
var equipment_items_reference_panel: EquipmentItemsReferencePanel = null
var skill_trees_reference_panel: SkillTreesReferencePanel = null
var expeditions_reference_panel: ExpeditionsReferencePanel = null
var daily_challenges_reference_panel: DailyChallengesReferencePanel = null
var milestones_reference_panel: MilestonesReferencePanel = null
var login_rewards_reference_panel: LoginRewardsReferencePanel = null
var loot_system_reference_panel: LootSystemReferencePanel = null
var quests_reference_panel: QuestsReferencePanel = null
var resource_nodes_reference_panel: ResourceNodesReferencePanel = null
var player_stats_reference_panel: PlayerStatsReferencePanel = null
var wave_composer_reference_panel: WaveComposerReferencePanel = null
var difficulty_mode: String = "adventure"

# Run-level tracking
var run_start_time: float = 0.0
var run_total_kills: int = 0
var run_boss_kills: int = 0
var run_damage_dealt: int = 0
var run_damage_taken: int = 0
var run_gold_earned: int = 0
var run_words_typed: int = 0
var run_best_accuracy: float = 0.0
var run_accuracy_sum: float = 0.0
var run_accuracy_count: int = 0
var run_best_wpm: int = 0
var run_best_combo: int = 0
var run_xp_start: int = 0
var run_level_start: int = 0
var run_achievements_unlocked: Array[String] = []
var consecutive_errors: int = 0
const CONSECUTIVE_ERROR_TIP_THRESHOLD: int = 3

func _ready() -> void:
	_init_game_state()
	_init_kingdom_systems()
	_init_achievement_system()
	_connect_signals()
	_show_game_start_dialogue()

	# Start with kingdom music (planning phase)
	if audio_manager:
		audio_manager.play_music(audio_manager.Music.KINGDOM)

func _init_kingdom_systems() -> void:
	# Initialize research system
	research_instance = SimResearch.instance()

	# Create kingdom dashboard
	kingdom_dashboard = KingdomDashboard.new()
	add_child(kingdom_dashboard)
	kingdom_dashboard.update_state(state)
	kingdom_dashboard.closed.connect(_on_dashboard_closed)
	kingdom_dashboard.upgrade_requested.connect(_on_upgrade_requested)
	kingdom_dashboard.research_started.connect(_on_research_started)
	kingdom_dashboard.trade_executed.connect(_on_trade_executed)
	kingdom_dashboard.build_requested.connect(_on_build_requested)

	# Create settings panel
	settings_panel = SettingsPanel.new()
	add_child(settings_panel)
	settings_panel.close_requested.connect(_on_settings_closed)

func _init_achievement_system() -> void:
	# Load player profile
	var load_result: Dictionary = TypingProfile.load_profile()
	if load_result.get("ok", false):
		profile = load_result.get("profile", TypingProfile.default_profile())
	else:
		profile = TypingProfile.default_profile()

	# Load difficulty mode from profile
	difficulty_mode = TypingProfile.get_difficulty_mode(profile)

	# Track session start for lifetime stats
	SimPlayerStats.start_session(profile)
	TypingProfile.save_profile(profile)

	# Update daily streak
	var streak_result: Dictionary = TypingProfile.update_daily_streak(profile)
	if streak_result.get("changed", false):
		TypingProfile.save_profile(profile)
		if streak_result.get("extended", false):
			var streak: int = int(streak_result.get("streak", 1))
			if streak >= 3:
				_show_streak_message(streak)

	# Initialize quest system
	_init_quest_system()

	# Create achievement checker
	achievement_checker = AchievementChecker.new()
	achievement_checker.achievement_unlocked.connect(_on_achievement_unlocked)

	# Create achievement popup
	achievement_popup = ACHIEVEMENT_POPUP_SCENE.instantiate()
	add_child(achievement_popup)

	# Create achievement panel
	achievement_panel = ACHIEVEMENT_PANEL_SCENE.instantiate()
	add_child(achievement_panel)
	achievement_panel.close_requested.connect(_on_achievement_panel_closed)

	# Create lore panel
	lore_panel = LorePanel.new()
	add_child(lore_panel)
	lore_panel.close_requested.connect(_on_lore_panel_closed)

	# Create bestiary panel
	bestiary_panel = BestiaryPanel.new()
	add_child(bestiary_panel)
	bestiary_panel.close_requested.connect(_on_bestiary_panel_closed)

	# Create wave summary panel
	wave_summary_panel = WaveSummaryPanel.new()
	add_child(wave_summary_panel)
	wave_summary_panel.continue_pressed.connect(_on_wave_summary_continue)

	# Create run summary panel
	run_summary_panel = RunSummaryPanel.new()
	add_child(run_summary_panel)
	run_summary_panel.continue_pressed.connect(_on_run_summary_continue)
	run_summary_panel.new_run_pressed.connect(_on_run_summary_new_run)
	run_summary_panel.main_menu_pressed.connect(_on_run_summary_menu)

	# Create tip notification
	tip_notification = TipNotification.new()
	add_child(tip_notification)
	# Position in bottom-right corner
	tip_notification.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	tip_notification.position = Vector2(-370, -100)

	# Create milestone popup
	milestone_popup = MilestonePopup.new()
	add_child(milestone_popup)

	# Create stats dashboard
	stats_dashboard = StatsDashboard.new()
	add_child(stats_dashboard)
	stats_dashboard.close_requested.connect(_on_stats_dashboard_closed)

	# Create equipment panel
	equipment_panel = EquipmentPanel.new()
	add_child(equipment_panel)
	equipment_panel.closed.connect(_on_equipment_panel_closed)
	equipment_panel.item_equipped.connect(_on_item_equipped)
	equipment_panel.item_unequipped.connect(_on_item_unequipped)

	# Create skills panel
	skills_panel = SkillsPanel.new()
	add_child(skills_panel)
	skills_panel.closed.connect(_on_skills_panel_closed)
	skills_panel.skill_learned.connect(_on_skill_learned)

	# Create shop panel
	shop_panel = ShopPanel.new()
	add_child(shop_panel)
	shop_panel.closed.connect(_on_shop_panel_closed)
	shop_panel.item_purchased.connect(_on_shop_item_purchased)

	# Create quests panel
	quests_panel = QuestsPanel.new()
	add_child(quests_panel)
	quests_panel.closed.connect(_on_quests_panel_closed)
	quests_panel.quest_claimed.connect(_on_quest_claimed_from_panel)

	# Create help panel
	help_panel = HelpPanel.new()
	add_child(help_panel)
	help_panel.closed.connect(_on_help_panel_closed)

	# Create effects panel
	effects_panel = EffectsPanel.new()
	add_child(effects_panel)
	effects_panel.closed.connect(_on_effects_panel_closed)

	# Create auto towers panel
	auto_towers_panel = AutoTowersPanel.new()
	add_child(auto_towers_panel)
	auto_towers_panel.closed.connect(_on_auto_towers_panel_closed)

	# Create spells panel
	spells_panel = SpellsPanel.new()
	add_child(spells_panel)
	spells_panel.closed.connect(_on_spells_panel_closed)

	# Create wave info panel
	wave_info_panel = WaveInfoPanel.new()
	add_child(wave_info_panel)
	wave_info_panel.closed.connect(_on_wave_info_panel_closed)

	# Create difficulty panel
	difficulty_panel = DifficultyPanel.new()
	add_child(difficulty_panel)
	difficulty_panel.closed.connect(_on_difficulty_panel_closed)
	difficulty_panel.difficulty_changed.connect(_on_difficulty_changed_from_panel)

	# Create endless mode panel
	endless_mode_panel = EndlessModePanel.new()
	add_child(endless_mode_panel)
	endless_mode_panel.closed.connect(_on_endless_mode_panel_closed)
	endless_mode_panel.start_endless_mode.connect(_on_start_endless_from_panel)

	# Create materials panel
	materials_panel = MaterialsPanel.new()
	add_child(materials_panel)
	materials_panel.closed.connect(_on_materials_panel_closed)

	# Create recipes panel
	recipes_panel = RecipesPanel.new()
	add_child(recipes_panel)
	recipes_panel.closed.connect(_on_recipes_panel_closed)
	recipes_panel.craft_requested.connect(_on_craft_from_panel)

	# Create daily challenge panel
	daily_challenge_panel = DailyChallengePanel.new()
	add_child(daily_challenge_panel)
	daily_challenge_panel.closed.connect(_on_daily_challenge_panel_closed)
	daily_challenge_panel.start_challenge.connect(_on_start_daily_from_panel)

	# Create token shop panel
	token_shop_panel = TokenShopPanel.new()
	add_child(token_shop_panel)
	token_shop_panel.closed.connect(_on_token_shop_panel_closed)
	token_shop_panel.item_purchased.connect(_on_token_item_purchased)

	# Create stats panel
	stats_panel = StatsPanel.new()
	add_child(stats_panel)
	stats_panel.closed.connect(_on_stats_panel_closed)

	# Create expeditions panel
	expeditions_panel = ExpeditionsPanel.new()
	add_child(expeditions_panel)
	expeditions_panel.closed.connect(_on_expeditions_panel_closed)
	expeditions_panel.expedition_started.connect(_on_expedition_started)
	expeditions_panel.expedition_cancelled.connect(_on_expedition_cancelled)

	# Create synergies panel
	synergies_panel = SynergiesPanel.new()
	add_child(synergies_panel)
	synergies_panel.closed.connect(_on_synergies_panel_closed)

	# Create buffs panel
	buffs_panel = BuffsPanel.new()
	add_child(buffs_panel)
	buffs_panel.closed.connect(_on_buffs_panel_closed)

	# Create summoned units panel
	summoned_units_panel = SummonedUnitsPanel.new()
	add_child(summoned_units_panel)
	summoned_units_panel.closed.connect(_on_summoned_units_panel_closed)

	# Create loot panel
	loot_panel = LootPanel.new()
	add_child(loot_panel)
	loot_panel.closed.connect(_on_loot_panel_closed)
	loot_panel.loot_collected.connect(_on_loot_collected)

	# Create resource nodes panel
	resource_nodes_panel = ResourceNodesPanel.new()
	add_child(resource_nodes_panel)
	resource_nodes_panel.closed.connect(_on_resource_nodes_panel_closed)
	resource_nodes_panel.harvest_requested.connect(_on_harvest_requested)

	# Create affixes panel
	affixes_panel = AffixesPanel.new()
	add_child(affixes_panel)
	affixes_panel.closed.connect(_on_affixes_panel_closed)

	# Create damage types panel
	damage_types_panel = DamageTypesPanel.new()
	add_child(damage_types_panel)
	damage_types_panel.closed.connect(_on_damage_types_panel_closed)

	# Create POI panel
	poi_panel = PoiPanel.new()
	add_child(poi_panel)
	poi_panel.closed.connect(_on_poi_panel_closed)
	poi_panel.poi_selected.connect(_on_poi_selected)

	# Create tower encyclopedia panel
	tower_encyclopedia_panel = TowerEncyclopediaPanel.new()
	add_child(tower_encyclopedia_panel)
	tower_encyclopedia_panel.closed.connect(_on_tower_encyclopedia_panel_closed)

	# Create status effects panel
	status_effects_panel = StatusEffectsPanel.new()
	add_child(status_effects_panel)
	status_effects_panel.closed.connect(_on_status_effects_panel_closed)

	# Create combo system panel
	combo_system_panel = ComboSystemPanel.new()
	add_child(combo_system_panel)
	combo_system_panel.closed.connect(_on_combo_system_panel_closed)

	# Create milestones panel
	milestones_panel = MilestonesPanel.new()
	add_child(milestones_panel)
	milestones_panel.closed.connect(_on_milestones_panel_closed)

	# Create practice goals panel
	practice_goals_panel = PracticeGoalsPanel.new()
	add_child(practice_goals_panel)
	practice_goals_panel.closed.connect(_on_practice_goals_panel_closed)
	practice_goals_panel.goal_selected.connect(_on_practice_goal_selected)

	# Create wave themes panel
	wave_themes_panel = WaveThemesPanel.new()
	add_child(wave_themes_panel)
	wave_themes_panel.closed.connect(_on_wave_themes_panel_closed)

	# Create special commands panel
	special_commands_panel = SpecialCommandsPanel.new()
	add_child(special_commands_panel)
	special_commands_panel.closed.connect(_on_special_commands_panel_closed)

	# Create lifetime stats panel
	lifetime_stats_panel = LifetimeStatsPanel.new()
	add_child(lifetime_stats_panel)
	lifetime_stats_panel.closed.connect(_on_lifetime_stats_panel_closed)

	# Create keyboard reference panel
	keyboard_reference_panel = KeyboardReferencePanel.new()
	add_child(keyboard_reference_panel)
	keyboard_reference_panel.closed.connect(_on_keyboard_reference_panel_closed)

	# Create login rewards panel
	login_rewards_panel = LoginRewardsPanel.new()
	add_child(login_rewards_panel)
	login_rewards_panel.closed.connect(_on_login_rewards_panel_closed)
	login_rewards_panel.reward_claimed.connect(_on_login_reward_claimed)

	# Create typing tower bonuses panel
	typing_tower_bonuses_panel = TypingTowerBonusesPanel.new()
	add_child(typing_tower_bonuses_panel)
	typing_tower_bonuses_panel.closed.connect(_on_typing_tower_bonuses_panel_closed)

	# Create research tree panel
	research_tree_panel = ResearchTreePanel.new()
	add_child(research_tree_panel)
	research_tree_panel.closed.connect(_on_research_tree_panel_closed)

	# Create trade panel
	trade_panel = TradePanel.new()
	add_child(trade_panel)
	trade_panel.closed.connect(_on_trade_panel_closed)

	# Create targeting modes panel
	targeting_modes_panel = TargetingModesPanel.new()
	add_child(targeting_modes_panel)
	targeting_modes_panel.closed.connect(_on_targeting_modes_panel_closed)

	# Create workers panel
	workers_panel = WorkersPanel.new()
	add_child(workers_panel)
	workers_panel.closed.connect(_on_workers_panel_closed)

	# Create event effects panel
	event_effects_panel = EventEffectsPanel.new()
	add_child(event_effects_panel)
	event_effects_panel.closed.connect(_on_event_effects_panel_closed)

	# Create upgrades panel
	upgrades_panel = UpgradesPanel.new()
	add_child(upgrades_panel)
	upgrades_panel.closed.connect(_on_upgrades_panel_closed)

	# Create balance reference panel
	balance_reference_panel = BalanceReferencePanel.new()
	add_child(balance_reference_panel)
	balance_reference_panel.closed.connect(_on_balance_reference_panel_closed)

	# Create wave composition panel
	wave_composition_panel = WaveCompositionPanel.new()
	add_child(wave_composition_panel)
	wave_composition_panel.closed.connect(_on_wave_composition_panel_closed)

	# Create synergy reference panel
	synergy_reference_panel = SynergyReferencePanel.new()
	add_child(synergy_reference_panel)
	synergy_reference_panel.closed.connect(_on_synergy_reference_panel_closed)

	# Create typing metrics panel
	typing_metrics_panel = TypingMetricsPanel.new()
	add_child(typing_metrics_panel)
	typing_metrics_panel.closed.connect(_on_typing_metrics_panel_closed)

	# Create tower types reference panel
	tower_types_reference_panel = TowerTypesReferencePanel.new()
	add_child(tower_types_reference_panel)
	tower_types_reference_panel.closed.connect(_on_tower_types_reference_panel_closed)

	# Create enemy types reference panel
	enemy_types_reference_panel = EnemyTypesReferencePanel.new()
	add_child(enemy_types_reference_panel)
	enemy_types_reference_panel.closed.connect(_on_enemy_types_reference_panel_closed)

	# Create building types reference panel
	building_types_reference_panel = BuildingTypesReferencePanel.new()
	add_child(building_types_reference_panel)
	building_types_reference_panel.closed.connect(_on_building_types_reference_panel_closed)

	# Create research tree reference panel
	research_tree_reference_panel = ResearchTreeReferencePanel.new()
	add_child(research_tree_reference_panel)
	research_tree_reference_panel.closed.connect(_on_research_tree_reference_panel_closed)

	# Create workers reference panel
	workers_reference_panel = WorkersReferencePanel.new()
	add_child(workers_reference_panel)
	workers_reference_panel.closed.connect(_on_workers_reference_panel_closed)

	# Create trade reference panel
	trade_reference_panel = TradeReferencePanel.new()
	add_child(trade_reference_panel)
	trade_reference_panel.closed.connect(_on_trade_reference_panel_closed)

	# Create lessons reference panel
	lessons_reference_panel = LessonsReferencePanel.new()
	add_child(lessons_reference_panel)
	lessons_reference_panel.closed.connect(_on_lessons_reference_panel_closed)

	# Create kingdom upgrades reference panel
	kingdom_upgrades_reference_panel = KingdomUpgradesReferencePanel.new()
	add_child(kingdom_upgrades_reference_panel)
	kingdom_upgrades_reference_panel.closed.connect(_on_kingdom_upgrades_reference_panel_closed)

	# Create special commands reference panel
	special_commands_reference_panel = SpecialCommandsReferencePanel.new()
	add_child(special_commands_reference_panel)
	special_commands_reference_panel.closed.connect(_on_special_commands_reference_panel_closed)

	# Create status effects reference panel
	status_effects_reference_panel = StatusEffectsReferencePanel.new()
	add_child(status_effects_reference_panel)
	status_effects_reference_panel.closed.connect(_on_status_effects_reference_panel_closed)

	# Create combo system reference panel
	combo_system_reference_panel = ComboSystemReferencePanel.new()
	add_child(combo_system_reference_panel)
	combo_system_reference_panel.closed.connect(_on_combo_system_reference_panel_closed)

	# Create difficulty modes reference panel
	difficulty_modes_reference_panel = DifficultyModesReferencePanel.new()
	add_child(difficulty_modes_reference_panel)
	difficulty_modes_reference_panel.closed.connect(_on_difficulty_modes_reference_panel_closed)

	# Create damage types reference panel
	damage_types_reference_panel = DamageTypesReferencePanel.new()
	add_child(damage_types_reference_panel)
	damage_types_reference_panel.closed.connect(_on_damage_types_reference_panel_closed)

	# Create enemy affixes reference panel
	enemy_affixes_reference_panel = EnemyAffixesReferencePanel.new()
	add_child(enemy_affixes_reference_panel)
	enemy_affixes_reference_panel.closed.connect(_on_enemy_affixes_reference_panel_closed)

	# Create equipment items reference panel
	equipment_items_reference_panel = EquipmentItemsReferencePanel.new()
	add_child(equipment_items_reference_panel)
	equipment_items_reference_panel.closed.connect(_on_equipment_items_reference_panel_closed)

	# Create skill trees reference panel
	skill_trees_reference_panel = SkillTreesReferencePanel.new()
	add_child(skill_trees_reference_panel)
	skill_trees_reference_panel.closed.connect(_on_skill_trees_reference_panel_closed)

	# Create expeditions reference panel
	expeditions_reference_panel = ExpeditionsReferencePanel.new()
	add_child(expeditions_reference_panel)
	expeditions_reference_panel.closed.connect(_on_expeditions_reference_panel_closed)

	# Create daily challenges reference panel
	daily_challenges_reference_panel = DailyChallengesReferencePanel.new()
	add_child(daily_challenges_reference_panel)
	daily_challenges_reference_panel.closed.connect(_on_daily_challenges_reference_panel_closed)

	# Create milestones reference panel
	milestones_reference_panel = MilestonesReferencePanel.new()
	add_child(milestones_reference_panel)
	milestones_reference_panel.closed.connect(_on_milestones_reference_panel_closed)

	# Create login rewards reference panel
	login_rewards_reference_panel = LoginRewardsReferencePanel.new()
	add_child(login_rewards_reference_panel)
	login_rewards_reference_panel.closed.connect(_on_login_rewards_reference_panel_closed)

	# Create loot system reference panel
	loot_system_reference_panel = LootSystemReferencePanel.new()
	add_child(loot_system_reference_panel)
	loot_system_reference_panel.closed.connect(_on_loot_system_reference_panel_closed)

	# Create quests reference panel
	quests_reference_panel = QuestsReferencePanel.new()
	add_child(quests_reference_panel)
	quests_reference_panel.closed.connect(_on_quests_reference_panel_closed)

	# Create resource nodes reference panel
	resource_nodes_reference_panel = ResourceNodesReferencePanel.new()
	add_child(resource_nodes_reference_panel)
	resource_nodes_reference_panel.closed.connect(_on_resource_nodes_reference_panel_closed)

	# Create player stats reference panel
	player_stats_reference_panel = PlayerStatsReferencePanel.new()
	add_child(player_stats_reference_panel)
	player_stats_reference_panel.closed.connect(_on_player_stats_reference_panel_closed)

	# Create wave composer reference panel
	wave_composer_reference_panel = WaveComposerReferencePanel.new()
	add_child(wave_composer_reference_panel)
	wave_composer_reference_panel.closed.connect(_on_wave_composer_reference_panel_closed)

	# Initialize run tracking
	_init_run_tracking()

	# Create notification manager
	notification_manager = NotificationManager.new()
	add_child(notification_manager)

func _show_streak_message(streak: int) -> void:
	var message: String = StoryManager.get_daily_streak_message(streak)
	if not message.is_empty() and dialogue_box:
		var lines: Array[String] = [message]
		dialogue_box.show_dialogue("Elder Lyra", lines)

func _add_event(message: String) -> void:
	# Display an event message using the notification manager
	if notification_manager != null:
		# Strip BBCode for toast notification
		var plain_text: String = message
		# Simple BBCode removal for color tags
		var regex := RegEx.new()
		regex.compile("\\[/?color[^\\]]*\\]")
		plain_text = regex.sub(plain_text, "", true)
		notification_manager.notify_info(plain_text)

func _update_hud() -> void:
	# Wrapper to refresh the HUD after gold/resource changes
	_update_ui()

func _on_achievement_unlocked(achievement_id: String, achievement_data: Dictionary) -> void:
	if achievement_popup != null and achievement_popup.has_method("show_achievement"):
		achievement_popup.show_achievement(achievement_id, achievement_data)

	# Track for run summary
	var ach_name: String = str(achievement_data.get("name", achievement_id))
	if not run_achievements_unlocked.has(ach_name):
		run_achievements_unlocked.append(ach_name)

	# Also show toast notification
	if notification_manager != null:
		var desc: String = str(achievement_data.get("description", ""))
		notification_manager.notify_achievement(ach_name, desc)

func _on_achievement_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_lore_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _toggle_lore() -> void:
	if lore_panel:
		if lore_panel.visible:
			lore_panel.hide_lore()
		else:
			lore_panel.show_lore()

func _on_bestiary_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _toggle_bestiary() -> void:
	if bestiary_panel:
		if bestiary_panel.visible:
			bestiary_panel.hide_bestiary()
		else:
			bestiary_panel.show_bestiary(profile)

func _on_stats_dashboard_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _toggle_stats() -> void:
	if stats_dashboard:
		if stats_dashboard.visible:
			stats_dashboard.hide_stats()
		else:
			stats_dashboard.show_stats(profile)

func _on_equipment_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_item_equipped(item_id: String, slot: String) -> void:
	var item: Dictionary = SimItems.get_item(item_id)
	var name: String = str(item.get("name", item_id))
	_add_event("Equipped [color=lime]%s[/color] to %s slot." % [name, slot])
	_update_equipment_stats()

func _on_item_unequipped(slot: String) -> void:
	_add_event("Unequipped item from %s slot." % slot)
	_update_equipment_stats()

func _update_equipment_stats() -> void:
	# Reload profile to ensure we have latest equipment
	var load_result: Dictionary = TypingProfile.load_profile()
	if load_result.get("ok", false):
		profile = load_result.get("profile", profile)

func _toggle_equipment() -> void:
	if equipment_panel:
		if equipment_panel.visible:
			equipment_panel.hide()
		else:
			equipment_panel.show_equipment(profile)

func _on_skills_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_skill_learned(tree_id: String, skill_id: String) -> void:
	var skill_name: String = SimSkills.get_skill_name(tree_id, skill_id)
	_add_event("Learned [color=lime]%s[/color]!" % skill_name)

func _toggle_skills() -> void:
	if skills_panel:
		if skills_panel.visible:
			skills_panel.hide()
		else:
			skills_panel.show_skills(profile)

func _on_shop_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_shop_item_purchased(item_id: String) -> void:
	var item: Dictionary = SimItems.CONSUMABLES.get(item_id, {})
	var price: int = int(item.get("price", 0))
	var name: String = str(item.get("name", item_id))

	if gold < price:
		_add_event("[color=red]Not enough gold![/color]")
		return

	# Deduct gold
	gold -= price

	# Add to inventory
	TypingProfile.add_to_inventory(profile, item_id)
	TypingProfile.save_profile(profile)

	# Update shop panel gold display
	if shop_panel:
		shop_panel.update_gold(gold)

	_add_event("Purchased [color=lime]%s[/color] for %d gold!" % [name, price])
	_update_hud()

func _toggle_shop() -> void:
	if shop_panel:
		if shop_panel.visible:
			shop_panel.hide()
		else:
			shop_panel.show_shop(gold)

func _on_quests_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_help_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_effects_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_auto_towers_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_spells_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_wave_info_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_difficulty_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_difficulty_changed_from_panel(mode_id: String) -> void:
	difficulty_mode = mode_id
	TypingProfile.set_difficulty_mode(profile, mode_id)
	TypingProfile.save_profile(profile)
	var name: String = SimDifficulty.get_mode_name(mode_id)
	_update_objective("[color=lime]Difficulty set to: %s[/color]" % name)

func _on_endless_mode_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_start_endless_from_panel() -> void:
	_start_endless_mode()

func _on_materials_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_recipes_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_craft_from_panel(recipe_id: String) -> void:
	_try_craft(recipe_id)
	# Update the panel with new gold value
	if recipes_panel and recipes_panel.visible:
		recipes_panel.update_gold(gold)

func _on_daily_challenge_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_start_daily_from_panel() -> void:
	_start_daily_challenge()

func _on_token_shop_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_token_item_purchased(item_id: String) -> void:
	_try_buy_token_item(item_id)
	# Update the panel with new balance
	if token_shop_panel and token_shop_panel.visible:
		var balance: int = SimDailyChallenges.get_token_balance(profile)
		token_shop_panel.update_balance(balance)

func _on_stats_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_expeditions_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_expedition_started(expedition_id: String, worker_count: int) -> void:
	var result: Dictionary = SimExpeditions.start_expedition(state, expedition_id, worker_count)
	if bool(result.get("ok", false)):
		var label: String = str(result.get("label", expedition_id))
		var duration: String = str(result.get("duration_text", ""))
		_add_event("[color=cyan]Expedition '%s' started (%s)[/color]" % [label, duration])
		if expeditions_panel and expeditions_panel.visible:
			expeditions_panel.refresh()
	else:
		_update_objective("[color=red]%s[/color]" % str(result.get("error", "Failed to start expedition")))

func _on_expedition_cancelled(expedition_id: int) -> void:
	var result: Dictionary = SimExpeditions.cancel_expedition(state, expedition_id)
	if bool(result.get("ok", false)):
		_add_event("[color=orange]%s[/color]" % str(result.get("message", "Expedition cancelled")))
		if expeditions_panel and expeditions_panel.visible:
			expeditions_panel.refresh()
	else:
		_update_objective("[color=red]%s[/color]" % str(result.get("error", "Failed to cancel expedition")))

func _on_synergies_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_buffs_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_summoned_units_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_loot_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_loot_collected() -> void:
	_update_hud()
	_add_event("[color=lime]Loot collected![/color]")
	if loot_panel and loot_panel.visible:
		loot_panel.refresh()

func _on_resource_nodes_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_harvest_requested(pos: Vector2i) -> void:
	# Start the harvest challenge at this position
	var result: Dictionary = SimResourceNodes.start_harvest_challenge(state, pos)
	if not bool(result.get("ok", false)):
		_update_objective("[color=red]%s[/color]" % str(result.get("error", "Cannot harvest")))
		return

	var node_name: String = str(result.get("node_name", "Resource"))
	var challenge_desc: String = str(result.get("challenge_description", "Complete the challenge!"))
	_add_event("[color=cyan]Starting harvest: %s[/color]" % node_name)
	_add_event("[color=gray]%s[/color]" % challenge_desc)

	# Close the panel and start the challenge
	if resource_nodes_panel:
		resource_nodes_panel.hide()

	# For now, auto-complete with simulated performance
	# In a full implementation, this would trigger a typing mini-game
	var performance: Dictionary = {
		"passed": true,
		"accuracy": 0.95,
		"wpm": 45,
		"time_remaining": 5.0
	}

	var harvest_result: Dictionary = SimResourceNodes.complete_harvest(state, pos, performance)
	if bool(harvest_result.get("ok", false)):
		_add_event("[color=lime]%s[/color]" % str(harvest_result.get("message", "Harvest complete!")))
		_update_hud()
	else:
		_add_event("[color=red]%s[/color]" % str(harvest_result.get("error", "Harvest failed")))

func _on_affixes_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_damage_types_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_poi_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_poi_selected(poi_id: String) -> void:
	# Handle POI interaction
	var poi_state: Dictionary = state.active_pois.get(poi_id, {})
	if poi_state.is_empty():
		_update_objective("[color=red]POI not found[/color]")
		return

	var poi_def: Dictionary = SimPoi.get_poi(poi_id)
	var poi_name: String = str(poi_def.get("name", poi_id))

	# Mark as interacted
	poi_state["interacted"] = true
	state.active_pois[poi_id] = poi_state

	_add_event("[color=cyan]Interacted with %s[/color]" % poi_name)

	# Close the panel
	if poi_panel:
		poi_panel.hide()

	# For now, just give a small reward
	var reward_gold: int = 10 + state.day * 2
	gold += reward_gold
	state.gold = gold
	_add_event("[color=yellow]+%d gold[/color] from %s" % [reward_gold, poi_name])
	_update_hud()

func _on_tower_encyclopedia_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_status_effects_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_combo_system_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_milestones_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_practice_goals_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_practice_goal_selected(goal_id: String) -> void:
	# Update the profile with the new goal
	if profile != null:
		profile["practice_goal"] = goal_id
		TypingProfile.save_profile(profile)
		_add_event("Practice goal set to: %s" % PracticeGoals.goal_label(goal_id))

func _on_wave_themes_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_special_commands_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_lifetime_stats_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_keyboard_reference_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_login_rewards_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_login_reward_claimed(reward: Dictionary) -> void:
	# Apply the login reward
	var reward_gold: int = int(reward.get("gold", 0))
	if reward_gold > 0:
		gold += reward_gold
		run_gold_earned += reward_gold
		_add_event("[color=yellow]+%d gold[/color] from daily login!" % reward_gold)

	# Apply bonus if present
	var bonus: String = str(reward.get("bonus", ""))
	if not bonus.is_empty():
		SimLoginRewards.apply_bonus_to_profile(profile, bonus)
		var bonus_info: Dictionary = SimLoginRewards.get_bonus_info(bonus)
		var bonus_name: String = str(bonus_info.get("name", bonus))
		_add_event("[color=cyan]%s[/color] activated!" % bonus_name)

	# Update streak in profile
	TypingProfile.save_profile(profile)
	_update_hud()

func _on_typing_tower_bonuses_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_research_tree_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_trade_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_targeting_modes_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_workers_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_event_effects_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_upgrades_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_balance_reference_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_wave_composition_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_synergy_reference_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_typing_metrics_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_tower_types_reference_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_enemy_types_reference_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_building_types_reference_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_research_tree_reference_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_workers_reference_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_trade_reference_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_lessons_reference_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_kingdom_upgrades_reference_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_special_commands_reference_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_status_effects_reference_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_combo_system_reference_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_difficulty_modes_reference_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_damage_types_reference_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_enemy_affixes_reference_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_equipment_items_reference_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_skill_trees_reference_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_expeditions_reference_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_daily_challenges_reference_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_milestones_reference_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_login_rewards_reference_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_loot_system_reference_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_quests_reference_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_resource_nodes_reference_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_player_stats_reference_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_wave_composer_reference_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_quest_claimed_from_panel(quest_id: String, rewards: Dictionary) -> void:
	# Apply rewards
	var gold_reward: int = int(rewards.get("gold", 0))
	var xp_reward: int = int(rewards.get("xp", 0))

	if gold_reward > 0:
		gold += gold_reward
		run_gold_earned += gold_reward
		_add_event("Quest reward: [color=yellow]+%d gold[/color]" % gold_reward)

	if xp_reward > 0:
		var xp_result: Dictionary = TypingProfile.add_xp(profile, xp_reward)
		TypingProfile.save_profile(profile)
		_add_event("Quest reward: [color=cyan]+%d XP[/color]" % xp_reward)
		if int(xp_result.get("levels_gained", 0)) > 0:
			var new_level: int = int(xp_result.get("new_level", 1))
			_add_event("[color=lime]Level Up! Now level %d[/color]" % new_level)

	# Mark quest as claimed
	var quest: Dictionary = SimQuests.get_quest(quest_id)
	var quest_type: String = str(quest.get("type", "daily"))

	if quest_type == "daily":
		var claimed: Array = quest_state.get("daily_claimed", [])
		if not quest_id in claimed:
			claimed.append(quest_id)
			quest_state["daily_claimed"] = claimed
	elif quest_type == "weekly":
		var claimed: Array = quest_state.get("weekly_claimed", [])
		if not quest_id in claimed:
			claimed.append(quest_id)
			quest_state["weekly_claimed"] = claimed

	# Update quests panel
	if quests_panel:
		quests_panel.update_quest_state(quest_state)

	_update_hud()

func _toggle_quests() -> void:
	if quests_panel:
		if quests_panel.visible:
			quests_panel.hide()
		else:
			quests_panel.show_quests(quest_state)

func _on_wave_summary_continue() -> void:
	if input_field:
		input_field.grab_focus()

func _init_run_tracking() -> void:
	run_start_time = Time.get_unix_time_from_system()
	run_total_kills = 0
	run_boss_kills = 0
	run_damage_dealt = 0
	run_damage_taken = 0
	run_gold_earned = 0
	run_words_typed = 0
	run_best_accuracy = 0.0
	run_accuracy_sum = 0.0
	run_accuracy_count = 0
	run_best_wpm = 0
	run_best_combo = 0
	run_xp_start = int(profile.get("player_xp", 0))
	run_level_start = int(profile.get("player_level", 1))
	run_achievements_unlocked.clear()

func _on_run_summary_continue() -> void:
	# For victory, continue playing (maybe unlock endless mode or rewards)
	if input_field:
		input_field.grab_focus()

func _on_run_summary_new_run() -> void:
	# Reset and start a new run
	_reset_game()
	_init_run_tracking()

func _on_run_summary_menu() -> void:
	# Return to main menu
	if game_controller and game_controller.has_method("go_to_main_menu"):
		game_controller.go_to_main_menu()
	else:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _show_run_summary(victory: bool) -> void:
	if run_summary_panel == null:
		return

	var play_time: float = Time.get_unix_time_from_system() - run_start_time
	var avg_accuracy: float = run_accuracy_sum / float(max(1, run_accuracy_count))

	var xp_gained: int = int(profile.get("player_xp", 0)) - run_xp_start
	var levels_gained: int = int(profile.get("player_level", 1)) - run_level_start

	var summary_stats: Dictionary = {
		"day_reached": day,
		"waves_cleared": (day - 1) * waves_per_day + wave - 1,
		"total_kills": run_total_kills,
		"boss_kills": run_boss_kills,
		"damage_dealt": run_damage_dealt,
		"damage_taken": run_damage_taken,
		"gold_earned": run_gold_earned,
		"words_typed": run_words_typed,
		"best_accuracy": run_best_accuracy,
		"avg_accuracy": avg_accuracy,
		"best_wpm": run_best_wpm,
		"best_combo": run_best_combo,
		"play_time": play_time,
		"xp_gained": xp_gained,
		"levels_gained": levels_gained,
		"achievements_unlocked": run_achievements_unlocked.duplicate()
	}

	run_summary_panel.show_summary(summary_stats, victory)

func _on_dashboard_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_settings_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _toggle_settings() -> void:
	if settings_panel:
		if settings_panel.visible:
			settings_panel.hide_settings()
		else:
			settings_panel.show_settings()

func _on_upgrade_requested(building_index: int) -> void:
	# Play upgrade sound
	if audio_manager:
		audio_manager.play_upgrade_purchase()
	_update_objective("[color=green]Building upgraded![/color]")
	_update_grid_renderer()

func _on_research_started(research_id: String) -> void:
	var research: Dictionary = research_instance.get_research(research_id)
	var label: String = str(research.get("label", research_id))
	# Play UI confirm sound
	if audio_manager:
		audio_manager.play_ui_confirm()
	_update_objective("[color=cyan]Started research: %s[/color]" % label)

func _on_trade_executed(from: String, to: String, amount: int) -> void:
	# Play trade sound
	if audio_manager:
		audio_manager.play_ui_confirm()
	_update_objective("[color=green]Trade complete![/color]")

func _on_build_requested(building_type: String) -> void:
	# Build at cursor position via the same function used by typed commands
	_try_build(building_type)

func _reset_game() -> void:
	# Reset gameplay variables
	day = 1
	wave = 1
	castle_hp = castle_max_hp
	gold = 50
	combo = 0
	max_combo = 0
	correct_chars = 0
	total_chars = 0
	words_typed = 0
	active_enemies.clear()
	enemy_queue.clear()
	target_enemy_id = -1
	current_word = ""
	typed_text = ""
	current_phase = "planning"

	# Reset wave tracking
	words_typed_this_wave = 0
	kills_this_wave = 0
	gold_earned_this_wave = 0

	# Reinitialize game state
	_init_game_state()

	# Clear input
	if input_field:
		input_field.text = ""
		input_field.grab_focus()

func _init_game_state() -> void:
	state = DefaultState.create("default", true)
	state.base_pos = Vector2i(1, state.map_h / 2)
	state.cursor_pos = cursor_grid_pos
	state.lesson_id = lesson_order[current_lesson_index]
	previous_lesson_id = state.lesson_id

	# Discover entire map for RTS view
	for y in range(state.map_h):
		for x in range(state.map_w):
			var index: int = y * state.map_w + x
			state.discovered[index] = true

	# Generate terrain
	SimMap.generate_terrain(state)

	# Starting resources - enough to build one tower (costs 4 wood, 8 stone)
	state.resources["wood"] = 5
	state.resources["stone"] = 10
	state.resources["food"] = 5

	_update_grid_renderer()


func _place_starting_towers() -> void:
	var base: Vector2i = state.base_pos
	# Place towers adjacent to castle (above and below)
	var tower_positions: Array[Vector2i] = [
		Vector2i(base.x, base.y - 1),  # Above castle
		Vector2i(base.x, base.y + 1),  # Below castle
		Vector2i(base.x + 1, base.y),  # Right of castle
	]

	for pos in tower_positions:
		if not SimMap.in_bounds(pos.x, pos.y, state.map_w, state.map_h):
			continue
		var index: int = SimMap.idx(pos.x, pos.y, state.map_w)
		# Ensure terrain is buildable
		if state.terrain[index] == SimMap.TERRAIN_WATER:
			state.terrain[index] = SimMap.TERRAIN_PLAINS
		# Place the tower
		state.structures[index] = "tower"


func _connect_signals() -> void:
	if input_field:
		input_field.text_changed.connect(_on_input_changed)
		input_field.text_submitted.connect(_on_input_submitted)
		input_field.grab_focus()

	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)

	if dialogue_box:
		dialogue_box.dialogue_finished.connect(_on_dialogue_finished)

func _process(delta: float) -> void:
	# Pause game during dialogue
	if waiting_for_dialogue:
		_update_ui()
		return

	match current_phase:
		"planning":
			_process_planning(delta)
		"defense":
			_process_defense(delta)
		"practice":
			_process_practice(delta)

	_update_ui()

func _process_planning(delta: float) -> void:
	planning_timer -= delta
	if planning_timer <= 0:
		_start_defense_phase()

	# Rotate typing tips
	tip_timer += delta
	if tip_timer >= tip_interval:
		tip_timer = 0.0
		_show_random_tip()

func _process_practice(delta: float) -> void:
	# Practice mode is event-driven via input, not delta-based
	pass

func _process_defense(delta: float) -> void:
	# Tick item buffs
	_tick_item_buffs(delta)

	# Tick command cooldowns and effects
	_tick_command_cooldowns(delta)

	# Process auto-tower attacks
	_process_auto_towers(delta)

	# Spawn enemies from queue
	spawn_timer -= delta
	if spawn_timer <= 0 and not enemy_queue.is_empty():
		_spawn_next_enemy()
		spawn_timer = spawn_interval

	# Move all active enemies toward castle (uses cached distance field)
	var dist_field: PackedInt32Array = _get_cached_dist_field()
	for i in range(active_enemies.size() - 1, -1, -1):
		var enemy: Dictionary = active_enemies[i]
		_move_enemy(enemy, dist_field, delta)
		active_enemies[i] = enemy

		# Check if reached castle
		var pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
		if pos == state.base_pos:
			_enemy_reached_castle(i)

	# Update state enemies for grid renderer
	state.enemies = active_enemies.duplicate(true)
	_update_grid_renderer()

	# Check wave completion
	if active_enemies.is_empty() and enemy_queue.is_empty():
		_wave_complete()


## Get distance field with caching (major performance optimization)
func _get_cached_dist_field() -> PackedInt32Array:
	# Check if cache needs invalidation via structure hash
	var current_hash := _compute_structure_hash()
	if current_hash != _last_structure_hash:
		_dist_field_valid = false
		_last_structure_hash = current_hash

	if not _dist_field_valid:
		_cached_dist_field = SimMap.compute_dist_to_base(state)
		_dist_field_valid = true

	return _cached_dist_field


## Compute a simple hash of structures for change detection
func _compute_structure_hash() -> int:
	var hash_val := 0
	for key in state.structures.keys():
		# Mix in both key and value
		hash_val = hash_val * 31 + int(key)
		hash_val = hash_val * 31 + str(state.structures[key]).hash()
	return hash_val


## Invalidate distance field cache (call when structures change)
func _invalidate_dist_field_cache() -> void:
	_dist_field_valid = false

func _move_enemy(enemy: Dictionary, dist_field: PackedInt32Array, delta: float) -> void:
	var pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
	var speed: float = float(enemy.get("speed", 1)) * 0.5  # Tiles per second

	# Accumulate movement progress
	var progress: float = enemy.get("move_progress", 0.0) + speed * delta
	enemy["move_progress"] = progress

	if progress >= 1.0:
		enemy["move_progress"] = 0.0
		# Find next tile toward castle
		var next_pos: Vector2i = _get_next_tile(pos, dist_field)
		if next_pos != pos:
			enemy["pos"] = next_pos

func _get_next_tile(from: Vector2i, dist_field: PackedInt32Array) -> Vector2i:
	var neighbors: Array[Vector2i] = SimMap.neighbors4(from, state.map_w, state.map_h)
	var best_pos: Vector2i = from
	var best_dist: int = _dist_at(from, dist_field)

	for neighbor in neighbors:
		var d: int = _dist_at(neighbor, dist_field)
		if d >= 0 and d < best_dist:
			best_dist = d
			best_pos = neighbor

	return best_pos

func _dist_at(pos: Vector2i, dist_field: PackedInt32Array) -> int:
	var index: int = pos.y * state.map_w + pos.x
	if index < 0 or index >= dist_field.size():
		return 999999
	var d: int = dist_field[index]
	return d if d >= 0 else 999999

func _spawn_next_enemy() -> void:
	if enemy_queue.is_empty():
		return

	var enemy: Dictionary = enemy_queue.pop_front()
	var spawn_edge: int = randi() % 3  # 0=top, 1=right, 2=bottom
	var spawn_pos: Vector2i

	match spawn_edge:
		0:  # Top edge
			spawn_pos = Vector2i(randi() % state.map_w, 0)
		1:  # Right edge
			spawn_pos = Vector2i(state.map_w - 1, randi() % state.map_h)
		2:  # Bottom edge
			spawn_pos = Vector2i(randi() % state.map_w, state.map_h - 1)

	enemy["pos"] = spawn_pos
	enemy["move_progress"] = 0.0
	active_enemies.append(enemy)

	# Auto-target first enemy
	if target_enemy_id < 0 and not active_enemies.is_empty():
		_target_closest_enemy()

func _target_closest_enemy() -> void:
	if active_enemies.is_empty():
		target_enemy_id = -1
		current_word = ""
		return

	var dist_field: PackedInt32Array = SimMap.compute_dist_to_base(state)
	var best_index: int = SimEnemies.pick_target_index(active_enemies, dist_field, state.map_w, state.base_pos, -1)

	if best_index >= 0:
		target_enemy_id = int(active_enemies[best_index].get("id", -1))
		current_word = str(active_enemies[best_index].get("word", ""))
		word_start_time = Time.get_unix_time_from_system()
		input_field.clear()
		typed_text = ""
	else:
		target_enemy_id = -1
		current_word = ""

func _enemy_reached_castle(enemy_index: int) -> void:
	var enemy: Dictionary = active_enemies[enemy_index]
	var damage: int = max(1, int(enemy.get("hp", 1)))

	# Apply equipment defense and damage reduction
	var equipment: Dictionary = TypingProfile.get_equipment(profile)
	var equip_stats: Dictionary = SimItems.calculate_equipment_stats(equipment)
	var defense: int = int(equip_stats.get("defense", 0))
	var damage_reduction: float = float(equip_stats.get("damage_reduction", 0))
	var dodge_chance: float = float(equip_stats.get("dodge_chance", 0))

	# Check for shield block charges
	if int(command_effects.get("block_charges", 0)) > 0:
		command_effects["block_charges"] = int(command_effects["block_charges"]) - 1
		if int(command_effects.get("block_charges", 0)) <= 0:
			command_effects.erase("block_charges")
		_update_objective("[color=cyan]BLOCKED![/color] Shield absorbed the hit!")
		active_enemies.remove_at(enemy_index)
		if target_enemy_id == int(enemy.get("id", -1)):
			_target_closest_enemy()
		return

	# Check for dodge
	if dodge_chance > 0 and randf() < dodge_chance:
		_update_objective("[color=cyan]DODGED![/color] Avoided all damage!")
		active_enemies.remove_at(enemy_index)
		if target_enemy_id == int(enemy.get("id", -1)):
			_target_closest_enemy()
		return

	# Reduce damage by defense (1 defense = 1 less damage)
	damage = max(1, damage - defense)

	# Apply % damage reduction from equipment
	if damage_reduction > 0:
		damage = max(1, int(float(damage) * (1.0 - damage_reduction)))

	# Apply fortify damage reduction from command
	var fortify_reduction: float = float(command_effects.get("fortify", 0))
	if fortify_reduction > 0:
		damage = max(1, int(float(damage) * (1.0 - fortify_reduction)))

	castle_hp = max(0, castle_hp - damage)
	damage_taken_this_wave += damage
	damage_taken_this_day += damage
	run_damage_taken += damage
	combo = 0  # Break combo

	# Play castle hit and combo break sounds
	if audio_manager:
		audio_manager.play_hit_player()
		audio_manager.play_combo_break()

	# Lifetime stats: damage taken
	SimPlayerStats.increment_stat(profile, "total_damage_taken", damage)

	active_enemies.remove_at(enemy_index)

	if target_enemy_id == int(enemy.get("id", -1)):
		_target_closest_enemy()

	if castle_hp <= 0:
		_game_over()

func _start_planning_phase() -> void:
	current_phase = "planning"
	planning_timer = 30.0
	tip_timer = 0.0
	cursor_grid_pos = state.base_pos + Vector2i(2, 0)
	state.cursor_pos = cursor_grid_pos

	_update_objective("Build defenses! [color=cyan]Ctrl+Arrows[/color] to move cursor.\n[color=cyan]Tab[/color] for Kingdom Dashboard | Type [color=cyan]ready[/color] to start.")
	_update_hint("PLANNING: build <type> | upgrade | research | trade | status | ach | ready | Tab=dashboard")
	_update_grid_renderer()

	# Update dashboard state
	if kingdom_dashboard:
		kingdom_dashboard.update_state(state)

	# Show initial typing tip
	_show_random_tip()

	# Show act intro on first day of each act
	_show_act_intro()

func _start_defense_phase() -> void:
	current_phase = "defense"
	wave_start_time = Time.get_unix_time_from_system()
	damage_taken_this_wave = 0
	gold_earned_this_wave = 0
	words_typed_this_wave = 0
	kills_this_wave = 0

	# Play wave start sound and switch to battle music
	if audio_manager:
		audio_manager.play_wave_start()
		audio_manager.play_music(audio_manager.Music.BATTLE_TENSE)

	# Show contextual tips at strategic moments
	_show_contextual_defense_tip()

	# Show boss intro on boss days (final wave only)
	if wave == waves_per_day and StoryManager.is_boss_day(day):
		_show_boss_intro()

	# Generate enemies for this wave
	_generate_wave_enemies()

	# Spawn first enemy immediately
	spawn_timer = 0.0

	# Display wave theme if non-standard
	var theme_name: String = str(current_wave_composition.get("theme_name", ""))
	var modifiers: Array = current_wave_composition.get("modifier_names", [])
	if not theme_name.is_empty() and theme_name != "Standard Assault":
		var wave_info: String = "[color=yellow]%s[/color]" % theme_name
		if not modifiers.is_empty():
			wave_info += " [color=orange](%s)[/color]" % ", ".join(modifiers)
		_update_objective(wave_info)
	else:
		_update_objective("Defeat the enemies! Type their words to attack.")

	_update_hint("Type the highlighted word to damage enemies. Combos increase power!")
	_update_grid_renderer()

func _generate_wave_enemies() -> void:
	enemy_queue.clear()
	active_enemies.clear()
	target_enemy_id = -1

	# Check if enemies are disabled (Zen mode)
	if SimDifficulty.are_enemies_disabled(difficulty_mode):
		return

	var is_boss_wave: bool = wave == waves_per_day and StoryManager.is_boss_day(day)

	# Use wave composer for varied enemy composition
	current_wave_composition = SimWaveComposer.compose_wave(day, wave, waves_per_day, state.rng_state)
	var wave_size: int = SimDifficulty.apply_wave_size_modifier(int(current_wave_composition.get("enemy_count", 5)), difficulty_mode)
	var enemy_list: Array = current_wave_composition.get("enemies", [])
	var used_words: Dictionary = {}

	# Composition modifiers
	var hp_mult: float = float(current_wave_composition.get("hp_mult", 1.0))
	var speed_mult: float = float(current_wave_composition.get("speed_mult", 1.0))
	var affix_chances: Dictionary = current_wave_composition.get("affix_chances", {})

	# Apply endless mode scaling
	if is_endless_mode:
		var endless_scaling: Dictionary = SimEndlessMode.get_scaling(day)
		hp_mult *= float(endless_scaling.get("hp_mult", 1.0))
		speed_mult *= float(endless_scaling.get("speed_mult", 1.0))
		wave_size = int(float(wave_size) * float(endless_scaling.get("count_mult", 1.0)))

		# Check for swarm wave
		if SimEndlessMode.is_swarm_wave(day, wave, state.rng_state):
			wave_size = int(wave_size * 2)
			hp_mult *= 0.5

		# Add endless mode affix chances
		var mods: Array[String] = SimEndlessMode.get_active_modifiers(day)
		if "affix_surge" in mods:
			affix_chances["armored"] = 0.2
			affix_chances["swift"] = 0.2

	# Apply challenge mode modifiers
	if is_challenge_mode:
		var challenge_mods: Dictionary = challenge_state.get("challenge", {}).get("modifiers", {})
		if challenge_mods.has("enemy_speed"):
			speed_mult *= float(challenge_mods.get("enemy_speed", 1.0))
		if challenge_mods.has("enemy_hp"):
			hp_mult *= float(challenge_mods.get("enemy_hp", 1.0))
		if challenge_mods.has("enemy_count"):
			wave_size = int(float(wave_size) * float(challenge_mods.get("enemy_count", 1.0)))

	# Generate enemies from composition
	for i in range(min(wave_size, enemy_list.size())):
		var kind: String = str(enemy_list[i]) if i < enemy_list.size() else "raider"

		# Validate enemy type exists, fallback to raider
		if not SimEnemies.ENEMY_KINDS.has(kind):
			kind = "raider"

		var base_hp: int = _get_enemy_hp(kind)
		var base_speed: float = SimEnemies.speed_for_day(kind, day)
		var modified_hp: int = max(1, int(float(base_hp) * hp_mult))
		var modified_speed: float = SimDifficulty.apply_speed_modifier(base_speed * speed_mult, difficulty_mode)

		var enemy: Dictionary = {
			"id": state.enemy_next_id,
			"kind": kind,
			"hp": modified_hp,
			"speed": modified_speed,
			"armor": SimEnemies.armor_for_day(kind, day),
			"pos": Vector2i.ZERO,
			"word": "",
			"move_progress": 0.0,
			"is_boss": false,
			"affixes": []
		}

		# Apply random affixes from composition
		for affix in affix_chances.keys():
			var roll: float = randf()
			if roll < float(affix_chances[affix]):
				enemy["affixes"].append(affix)

		# Assign word from current lesson
		var word: String = SimWords.word_for_enemy(state.rng_seed, day, kind, state.enemy_next_id, used_words, state.lesson_id)
		enemy["word"] = word.to_lower()
		used_words[enemy["word"]] = true

		state.enemy_next_id += 1
		enemy_queue.append(enemy)

	# Fill remaining slots if enemy_list was shorter than wave_size
	while enemy_queue.size() < wave_size:
		var kind: String = SimEnemies.choose_spawn_kind(state)
		var base_hp: int = _get_enemy_hp(kind)
		var base_speed: float = SimEnemies.speed_for_day(kind, day)
		var modified_hp: int = max(1, int(float(base_hp) * hp_mult))
		var modified_speed: float = SimDifficulty.apply_speed_modifier(base_speed * speed_mult, difficulty_mode)

		var enemy: Dictionary = {
			"id": state.enemy_next_id,
			"kind": kind,
			"hp": modified_hp,
			"speed": modified_speed,
			"armor": SimEnemies.armor_for_day(kind, day),
			"pos": Vector2i.ZERO,
			"word": "",
			"move_progress": 0.0,
			"is_boss": false,
			"affixes": []
		}

		var word: String = SimWords.word_for_enemy(state.rng_seed, day, kind, state.enemy_next_id, used_words, state.lesson_id)
		enemy["word"] = word.to_lower()
		used_words[enemy["word"]] = true

		state.enemy_next_id += 1
		enemy_queue.append(enemy)

	# Add boss enemy on boss waves
	if is_boss_wave:
		var boss: Dictionary = _create_boss_enemy(used_words)
		enemy_queue.append(boss)

func _create_boss_enemy(used_words: Dictionary) -> Dictionary:
	var boss_data: Dictionary = StoryManager.get_boss_for_day(day)
	var boss_kind: String = str(boss_data.get("kind", "boss"))
	var boss_name: String = str(boss_data.get("name", "Boss"))

	# Boss has significantly more HP
	var boss_hp: int = _get_enemy_hp(boss_kind) * 5 + day * 2

	# Boss uses harder words - get a longer word from the lesson
	var boss_word: String = SimWords.get_boss_word(state.lesson_id, used_words)
	if boss_word.is_empty():
		boss_word = SimWords.word_for_enemy(state.rng_seed, day, boss_kind, state.enemy_next_id, used_words, state.lesson_id)
	boss_word = boss_word.to_lower()
	used_words[boss_word] = true

	var base_boss_speed: float = max(1, SimEnemies.speed_for_day(boss_kind, day) - 1)  # Slower but tankier
	var modified_boss_speed: float = SimDifficulty.apply_speed_modifier(base_boss_speed, difficulty_mode)

	var boss: Dictionary = {
		"id": state.enemy_next_id,
		"kind": boss_kind,
		"name": boss_name,
		"hp": boss_hp,
		"max_hp": boss_hp,
		"speed": modified_boss_speed,
		"armor": SimEnemies.armor_for_day(boss_kind, day) + 2,
		"pos": Vector2i.ZERO,
		"word": boss_word,
		"move_progress": 0.0,
		"is_boss": true,
		"phase": 1,
		"max_phases": 3
	}

	state.enemy_next_id += 1
	return boss

func _get_enemy_hp(kind: String) -> int:
	var base: int = 2 + int(day / 3)
	var bonus: int = SimEnemies.hp_bonus_for_day(kind, day)
	var raw_hp: int = max(1, base + bonus)
	# Apply difficulty modifier
	return SimDifficulty.apply_health_modifier(raw_hp, difficulty_mode)

func _wave_complete() -> void:
	var was_boss_day: bool = wave == waves_per_day and StoryManager.is_boss_day(day)
	var old_lesson_id: String = state.lesson_id

	# Play wave end and victory sounds, switch back to kingdom music
	if audio_manager:
		audio_manager.play_wave_end()
		audio_manager.play_victory()
		audio_manager.play_music(audio_manager.Music.KINGDOM)

	wave += 1

	# Gold reward
	var wave_bonus: int = 10 + wave * 5
	if castle_hp == castle_max_hp:
		wave_bonus = int(wave_bonus * 1.5)  # Perfect defense bonus
	gold += wave_bonus
	gold_earned_this_wave += wave_bonus
	state.gold = gold
	SimPlayerStats.increment_stat(profile, "total_gold_earned", wave_bonus)
	SimPlayerStats.update_record(profile, "most_gold_wave", gold_earned_this_wave)

	# Check wave achievements
	_check_wave_achievements()

	# Show wave summary panel
	_show_wave_summary()

	# Show contextual tip based on performance
	_show_contextual_tip_after_wave()

	# Advance research
	if research_instance and not state.active_research.is_empty():
		var research_result: Dictionary = research_instance.advance_research(state)
		if research_result.completed:
			_update_objective("[color=lime]Research complete: %s![/color]" % research_result.research_id)

	# Apply building effects (wave healing from temples)
	var building_effects: Dictionary = SimBuildings.get_total_effects(state)
	var total_wave_heal: int = 2 + int(building_effects.get("wave_heal", 0))

	# Also add research wave heal bonus
	if research_instance:
		var research_effects: Dictionary = research_instance.get_total_effects(state)
		total_wave_heal += int(research_effects.get("wave_heal", 0))

	# Add skill wave heal bonus
	var learned_skills: Dictionary = TypingProfile.get_learned_skills(profile)
	total_wave_heal += SimSkills.get_wave_heal(learned_skills)

	# Add regen buff heal bonus
	var regen_value: float = _get_item_buff_value("regen")
	if regen_value > 0:
		total_wave_heal += int(regen_value)

	# Update kills record before reset
	SimPlayerStats.update_record(profile, "most_kills_wave", kills_this_wave)

	# Reset wave counters
	words_typed_this_wave = 0
	kills_this_wave = 0
	chain_kill_count = 0

	# Check lesson progression
	var accuracy: float = _get_accuracy()
	if accuracy >= lesson_accuracy_threshold and current_lesson_index < lesson_order.size() - 1:
		current_lesson_index += 1
		state.lesson_id = lesson_order[current_lesson_index]

	# Quest progress: wave completion
	_update_quest_progress("waves", 1)
	_update_quest_progress("accuracy", int(accuracy * 100))
	if damage_taken_this_wave == 0:
		_update_quest_progress("no_damage_wave", 1)
	if accuracy >= 0.95:
		_update_quest_progress("perfect_waves", 1)
	var wave_time: int = int(Time.get_unix_time_from_system() - wave_start_time)
	_update_quest_progress("fast_wave", wave_time)

	# Lifetime stats: wave completion
	SimPlayerStats.increment_stat(profile, "waves_completed", 1)
	SimPlayerStats.update_record(profile, "highest_combo", max_combo)
	SimPlayerStats.update_record(profile, "highest_accuracy", int(accuracy * 100))
	if wave_time > 0:
		SimPlayerStats.update_record(profile, "fastest_wave_time", wave_time)

	# Challenge progress: wave survival
	if is_challenge_mode:
		_update_challenge_progress("survive_waves", 1)

	# Heal between waves
	castle_hp = min(castle_hp + total_wave_heal, castle_max_hp)

	# Day advancement
	if wave > waves_per_day:
		var completed_day: int = day  # Store before incrementing
		wave = 1
		day += 1
		state.day = day

		# Quest progress: day survived and no-damage day
		_update_quest_progress("days_survived", day)
		if damage_taken_this_day == 0:
			_update_quest_progress("no_damage_day", 1)
		damage_taken_this_day = 0  # Reset for next day

		# Lifetime stats: day progression
		SimPlayerStats.increment_stat(profile, "days_survived", 1)
		SimPlayerStats.update_record(profile, "highest_day", day)

		# Check for victory (completed day 20 - campaign end)
		if completed_day >= 20 and not is_endless_mode and not is_challenge_mode:
			_on_campaign_victory()
			return

		# Check for act completion
		_check_act_completion(completed_day)

		# Apply daily production at the start of each new day
		_apply_daily_production()

		# Gain a worker each day (up to max)
		SimWorkers.gain_worker(state)

		# Autosave on day completion
		var save_result: Dictionary = GamePersistence.save_state(state)
		if save_result.ok and OS.is_debug_build():
			print("[Kingdom Defense] Autosaved on day %d" % day)

	# Show boss defeat dialogue if we just beat a boss
	if was_boss_day:
		_show_boss_defeat()
	elif state.lesson_id != old_lesson_id:
		# Lesson unlocked - show intro
		_show_lesson_intro(state.lesson_id)
	else:
		# Show wave feedback
		_show_wave_feedback()

	# Update dashboard
	if kingdom_dashboard:
		kingdom_dashboard.update_state(state)

	# Short delay then planning phase
	await get_tree().create_timer(1.5).timeout
	_start_planning_phase()

func _apply_daily_production() -> void:
	# Calculate and apply daily production
	var production: Dictionary = SimWorkers.daily_production_with_workers(state)

	# Apply worker upkeep first
	var upkeep_result: Dictionary = SimWorkers.apply_upkeep(state)
	if not upkeep_result.ok and upkeep_result.workers_lost > 0:
		_update_objective("[color=red]Lost %d workers due to food shortage![/color]" % upkeep_result.workers_lost)

	# Add production (food already reduced by upkeep)
	for res_key in production.keys():
		if res_key == "gold":
			state.gold += int(production[res_key])
		else:
			state.resources[res_key] = int(state.resources.get(res_key, 0)) + int(production[res_key])

	# Sync gold
	gold = state.gold

func _game_over() -> void:
	word_display.text = "[center][color=red]GAME OVER[/color]\nCastle Destroyed![/center]"
	input_field.editable = false
	current_phase = "gameover"

	# Play defeat sound and switch to defeat music
	if audio_manager:
		audio_manager.play_defeat()
		audio_manager.play_music(audio_manager.Music.DEFEAT)

	# Lifetime stats: death and final records
	SimPlayerStats.increment_stat(profile, "total_deaths", 1)
	SimPlayerStats.update_record(profile, "highest_day", day)
	SimPlayerStats.update_record(profile, "highest_combo", max_combo)
	TypingProfile.save_profile(profile)

	# Handle endless mode game over
	if is_endless_mode:
		_end_endless_run()
		_update_objective("[color=yellow]ENDLESS RUN ENDED![/color] Final: Day %d, Wave %d, Kills %d, Max Combo %d" % [day, wave, endless_run_kills, max_combo])
	elif is_challenge_mode:
		_fail_daily_challenge("Castle destroyed!")
	else:
		_update_objective("Game Over! Final score: Day %d, Gold %d, Max Combo %d" % [day, gold, max_combo])

	# Show run summary (not for challenges - they have their own summary)
	if not is_challenge_mode:
		_show_run_summary(false)

func _on_campaign_victory() -> void:
	word_display.text = "[center][color=gold]VICTORY![/color]\nThe Siege of Keystonia is Over![/center]"
	input_field.editable = false
	current_phase = "victory"

	# Play victory sound and switch to victory music
	if audio_manager:
		audio_manager.play_victory()
		audio_manager.play_music(audio_manager.Music.VICTORY)

	# Award completion bonus
	var victory_gold: int = 500
	var victory_xp: int = 1000
	gold += victory_gold
	run_gold_earned += victory_gold
	TypingProfile.add_xp(profile, victory_xp)

	# Lifetime stats: victory
	SimPlayerStats.increment_stat(profile, "campaigns_won", 1)
	TypingProfile.save_profile(profile)

	# Show victory dialogue if we have dialogue box
	if dialogue_box:
		var lines: Array[String] = [
			"[color=gold]Congratulations, Champion![/color]",
			"You have defended Keystonia from the Typhos Horde!",
			"The Void Tyrant has been vanquished, and peace returns to the land.",
			"Your typing skills have saved the kingdom!",
			"[color=cyan]Victory Rewards: +%d Gold, +%d XP[/color]" % [victory_gold, victory_xp]
		]
		dialogue_box.show_dialogue("Elder Lyra", lines)

	_update_objective("[color=gold]CAMPAIGN COMPLETE![/color] You have saved Keystonia!")

	# Show run summary
	_show_run_summary(true)

func _on_input_changed(new_text: String) -> void:
	var old_len: int = typed_text.length()
	typed_text = new_text.to_lower()

	# Handle practice mode input specially
	if current_phase == "practice" and typed_text.length() > old_len:
		var last_char: String = typed_text[typed_text.length() - 1]
		_handle_practice_input(last_char)
		# Clear input after each key in practice mode
		if input_field:
			input_field.call_deferred("clear")
		return

	# Flash keyboard key on new character typed
	if keyboard_display and typed_text.length() > old_len:
		var last_char: String = typed_text[typed_text.length() - 1]
		var expected: String = ""
		if current_phase == "defense" and current_word.length() >= typed_text.length():
			expected = current_word[typed_text.length() - 1]
		elif current_phase == "planning":
			# In planning, any letter is valid
			expected = last_char
		var is_correct: bool = (last_char == expected)
		keyboard_display.flash_key(last_char, is_correct)

	if current_phase == "defense":
		_process_combat_typing()
	elif current_phase == "planning":
		_process_command_typing()

func _on_input_submitted(text: String) -> void:
	var lower_text: String = text.to_lower().strip_edges()

	if current_phase == "planning":
		if lower_text == "ready":
			_start_defense_phase()
		elif BUILD_COMMANDS.has(lower_text):
			_try_build(BUILD_COMMANDS[lower_text])
		elif lower_text == "upgrade":
			_try_upgrade_at_cursor()
		elif lower_text.begins_with("upgrade "):
			var building_type: String = lower_text.substr(8).strip_edges()
			_try_upgrade_building_type(building_type)
		elif lower_text == "status" or lower_text == "kingdom":
			_toggle_dashboard()
		elif lower_text == "settings" or lower_text == "options":
			_toggle_settings()
		elif lower_text == "workers":
			_show_dashboard_tab(1)  # Workers tab
		elif lower_text == "research":
			_show_dashboard_tab(3)  # Research tab
		elif lower_text.begins_with("research "):
			var research_name: String = lower_text.substr(9).strip_edges()
			_try_start_research(research_name)
		elif lower_text == "trade":
			_show_dashboard_tab(4)  # Trade tab
		elif lower_text.begins_with("trade "):
			_try_execute_trade(lower_text)
		elif lower_text == "info":
			_show_tile_info()
		elif lower_text == "achievements" or lower_text == "ach":
			_toggle_achievements()
		elif lower_text == "lore" or lower_text == "story":
			_toggle_lore()
		elif lower_text == "bestiary" or lower_text == "enemies":
			_toggle_bestiary()
		elif lower_text == "stats" or lower_text == "statistics":
			_toggle_stats()
		elif lower_text == "difficulty" or lower_text == "diff":
			_show_difficulty_options()
		elif lower_text.begins_with("diff "):
			_try_set_difficulty(lower_text.substr(5).strip_edges())
		elif lower_text == "effects" or lower_text == "debuffs":
			_show_status_effects_info()
		elif lower_text == "skills" or lower_text == "skill":
			_show_skills_info()
		elif lower_text.begins_with("learn "):
			_try_learn_skill(lower_text.substr(6).strip_edges())
		elif lower_text == "inventory" or lower_text == "inv" or lower_text == "items":
			_show_inventory()
		elif lower_text.begins_with("equip "):
			_try_equip_item(lower_text.substr(6).strip_edges())
		elif lower_text.begins_with("unequip "):
			_try_unequip_slot(lower_text.substr(8).strip_edges())
		elif lower_text == "equipment" or lower_text == "gear":
			_show_equipment()
		elif lower_text.begins_with("use "):
			_try_use_consumable(lower_text.substr(4).strip_edges())
		elif lower_text == "shop" or lower_text == "store":
			_show_shop()
		elif lower_text.begins_with("buy "):
			_try_buy_item(lower_text.substr(4).strip_edges())
		elif lower_text == "auto" or lower_text == "sentries" or lower_text == "autotowers":
			_show_auto_towers()
		elif lower_text == "help" or lower_text == "commands" or lower_text == "?":
			_show_help()
		elif lower_text == "spells" or lower_text == "abilities" or lower_text == "powers":
			_show_special_commands()
		elif lower_text == "quests" or lower_text == "missions" or lower_text == "q":
			_show_quests()
		elif lower_text.begins_with("claim "):
			_try_claim_quest(lower_text.substr(6).strip_edges())
		elif lower_text == "wave" or lower_text == "waveinfo":
			_show_wave_info()
		elif lower_text == "endless" or lower_text == "infinite":
			_show_endless_mode()
		elif lower_text == "startendless" or lower_text == "endless start":
			_start_endless_mode()
		elif lower_text == "daily" or lower_text == "challenge":
			_show_daily_challenge()
		elif lower_text == "startdaily" or lower_text == "startchallenge":
			_start_daily_challenge()
		elif lower_text == "tokens" or lower_text == "tokenshop":
			_show_token_shop()
		elif lower_text.begins_with("tokenbuy "):
			_try_buy_token_item(lower_text.substr(9).strip_edges())
		elif lower_text == "stats" or lower_text == "statistics":
			_show_stats_summary()
		elif lower_text == "stats full" or lower_text == "stats all":
			_show_stats_full()
		elif lower_text == "records" or lower_text == "highscores":
			_show_records()
		elif lower_text == "materials" or lower_text == "mats":
			_show_materials()
		elif lower_text == "recipes" or lower_text == "crafting":
			_show_recipes()
		elif lower_text.begins_with("recipes "):
			_show_recipes(lower_text.substr(8).strip_edges())
		elif lower_text.begins_with("craft "):
			_try_craft(lower_text.substr(6).strip_edges())
		elif lower_text.begins_with("recipe "):
			_show_recipe_detail(lower_text.substr(7).strip_edges())
		elif lower_text == "expeditions" or lower_text == "expedition" or lower_text == "exp":
			_show_expeditions()
		elif lower_text == "synergies" or lower_text == "synergy":
			_show_synergies()
		elif lower_text == "buffs" or lower_text == "buff" or lower_text == "boosts":
			_show_buffs()
		elif lower_text == "summons" or lower_text == "summon" or lower_text == "minions":
			_show_summons()
		elif lower_text == "loot" or lower_text == "drops" or lower_text == "collectloot":
			_show_loot()
		elif lower_text == "nodes" or lower_text == "resources" or lower_text == "harvest":
			_show_nodes()
		elif lower_text == "affixes" or lower_text == "affix" or lower_text == "modifiers":
			_show_affixes()
		elif lower_text == "damagetypes" or lower_text == "damage" or lower_text == "elements":
			_show_damage_types()
		elif lower_text == "pois" or lower_text == "poi" or lower_text == "locations":
			_show_pois()
		elif lower_text == "towers" or lower_text == "tower" or lower_text == "encyclopedia":
			_show_towers()
		elif lower_text == "statuseffects" or lower_text == "status" or lower_text == "effects" or lower_text == "debuffs":
			_show_status_effects()
		elif lower_text == "combosystem" or lower_text == "combo" or lower_text == "combos":
			_show_combo_system()
		elif lower_text == "milestones" or lower_text == "milestone" or lower_text == "records":
			_show_milestones()
		elif lower_text == "goals" or lower_text == "goal" or lower_text == "practice":
			_show_practice_goals()
		elif lower_text == "wavethemes" or lower_text == "waves" or lower_text == "themes":
			_show_wave_themes()
		elif lower_text == "commands" or lower_text == "command" or lower_text == "abilities":
			_show_special_commands()
		elif lower_text == "lifetimestats" or lower_text == "lifetime" or lower_text == "allstats":
			_show_lifetime_stats()
		elif lower_text == "keyboard" or lower_text == "keys" or lower_text == "fingers":
			_show_keyboard_reference()
		elif lower_text == "loginrewards" or lower_text == "login" or lower_text == "daily":
			_show_login_rewards()
		elif lower_text == "towerbonuses" or lower_text == "typingbonuses" or lower_text == "towerscaling":
			_show_typing_tower_bonuses()
		elif lower_text == "researchtree" or lower_text == "research" or lower_text == "techtree":
			_show_research_tree()
		elif lower_text == "trademarket" or lower_text == "trade" or lower_text == "market":
			_show_trade_market()
		elif lower_text == "targeting" or lower_text == "targetmodes" or lower_text == "priority":
			_show_targeting_modes()
		elif lower_text == "workers" or lower_text == "workforce" or lower_text == "labor":
			_show_workers()
		elif lower_text == "eventeffects" or lower_text == "effects" or lower_text == "buffs":
			_show_event_effects()
		elif lower_text == "upgrades" or lower_text == "upgradetree" or lower_text == "perks":
			_show_upgrades()
		elif lower_text == "balance" or lower_text == "economy" or lower_text == "scaling":
			_show_balance_reference()
		elif lower_text == "waves" or lower_text == "wavecomposition" or lower_text == "wavethemes":
			_show_wave_composition()
		elif lower_text == "synergies" or lower_text == "combos" or lower_text == "towersynergy":
			_show_synergy_reference()
		elif lower_text == "metrics" or lower_text == "typingmetrics" or lower_text == "wpm":
			_show_typing_metrics()
		elif lower_text == "towerref" or lower_text == "towers" or lower_text == "towertypes":
			_show_tower_types_reference()
		elif lower_text == "enemyref" or lower_text == "enemies" or lower_text == "bestiary":
			_show_enemy_types_reference()
		elif lower_text == "buildingref" or lower_text == "buildings" or lower_text == "structures":
			_show_building_types_reference()
		elif lower_text == "researchref" or lower_text == "research" or lower_text == "tech":
			_show_research_tree_reference()
		elif lower_text == "workersref" or lower_text == "workers" or lower_text == "labor":
			_show_workers_reference()
		elif lower_text == "traderef" or lower_text == "trade" or lower_text == "exchange":
			_show_trade_reference()
		elif lower_text == "lessonsref" or lower_text == "lessons" or lower_text == "curriculum":
			_show_lessons_reference()
		elif lower_text == "upgradesref" or lower_text == "upgrades" or lower_text == "kingdom":
			_show_kingdom_upgrades_reference()
		elif lower_text == "commandsref" or lower_text == "commands" or lower_text == "abilities":
			_show_special_commands_reference()
		elif lower_text == "effectsref" or lower_text == "effects" or lower_text == "debuffs":
			_show_status_effects_reference()
		elif lower_text == "comboref" or lower_text == "combo" or lower_text == "multiplier":
			_show_combo_system_reference()
		elif lower_text == "difficultyref" or lower_text == "difficulty" or lower_text == "modes":
			_show_difficulty_modes_reference()
		elif lower_text == "damageref" or lower_text == "damage" or lower_text == "elements":
			_show_damage_types_reference()
		elif lower_text == "affixref" or lower_text == "affixes" or lower_text == "modifiers":
			_show_enemy_affixes_reference()
		elif lower_text == "equipref" or lower_text == "equipment" or lower_text == "gear":
			_show_equipment_items_reference()
		elif lower_text == "skillref" or lower_text == "skills" or lower_text == "talents":
			_show_skill_trees_reference()
		elif lower_text == "expeditionref" or lower_text == "expeditions" or lower_text == "journeys":
			_show_expeditions_reference()
		elif lower_text == "challengeref" or lower_text == "challenges" or lower_text == "daily":
			_show_daily_challenges_reference()
		elif lower_text == "milestoneref" or lower_text == "milestones" or lower_text == "achievements":
			_show_milestones_reference()
		elif lower_text == "loginref" or lower_text == "login" or lower_text == "streaks":
			_show_login_rewards_reference()
		elif lower_text == "lootref" or lower_text == "loot" or lower_text == "drops":
			_show_loot_system_reference()
		elif lower_text == "questref" or lower_text == "quests" or lower_text == "missions":
			_show_quests_reference()
		elif lower_text == "noderef" or lower_text == "nodes" or lower_text == "harvest":
			_show_resource_nodes_reference()
		elif lower_text == "statsref" or lower_text == "playerstats" or lower_text == "records":
			_show_player_stats_reference()
		elif lower_text == "waveref" or lower_text == "waves" or lower_text == "themes":
			_show_wave_composer_reference()
		input_field.clear()
	elif current_phase == "defense":
		# Check for special commands first
		var command_id: String = SimSpecialCommands.match_command(typed_text)
		if not command_id.is_empty():
			_try_execute_command(command_id)
		elif typed_text == current_word:
			_attack_target_enemy()
		input_field.clear()

func _process_combat_typing() -> void:
	if current_word.is_empty():
		return

	# Check if typed text matches start of word
	if not current_word.begins_with(typed_text) and typed_text.length() > 0:
		# Mistake - break combo
		combo = 0
		total_chars += 1
		consecutive_errors += 1

		# Play mistake and combo break sounds
		if audio_manager:
			audio_manager.play_type_mistake()
			audio_manager.play_combo_break()

		# Show error tip after consecutive mistakes
		if consecutive_errors >= CONSECUTIVE_ERROR_TIP_THRESHOLD:
			if tip_notification and not tip_notification.visible:
				tip_notification.show_tip_for_context("error")
			consecutive_errors = 0  # Reset after showing tip

		# Handle challenge mode combo break
		if is_challenge_mode:
			_update_challenge_progress("combo_break", 1)
			var modifiers: Dictionary = challenge_state.get("challenge", {}).get("modifiers", {})
			if bool(modifiers.get("typo_ends_run", false)):
				_fail_daily_challenge("Typo detected! This challenge requires perfect typing.")

		# Lifetime stats: typos and combo breaks
		SimPlayerStats.increment_stat(profile, "total_typos", 1)
		SimPlayerStats.increment_stat(profile, "total_combos_broken", 1)

	# Auto-complete on exact match
	if typed_text == current_word:
		_attack_target_enemy()

func _process_command_typing() -> void:
	# Highlight matching commands as user types
	pass  # Could add autocomplete hints here

func _attack_target_enemy() -> void:
	if target_enemy_id < 0:
		return

	# Reset consecutive errors on successful word completion
	consecutive_errors = 0

	var enemy_index: int = _find_enemy_index(target_enemy_id)
	if enemy_index < 0:
		_target_closest_enemy()
		return

	var enemy: Dictionary = active_enemies[enemy_index]
	var learned_skills: Dictionary = TypingProfile.get_learned_skills(profile)
	var equipment: Dictionary = TypingProfile.get_equipment(profile)
	var item_stats: Dictionary = SimItems.calculate_equipment_stats(equipment)

	# Calculate damage with power multiplier
	var power: float = _calculate_power()
	var damage: int = max(1, int(ceil(power)))

	# Apply equipment damage bonus
	var equip_damage_bonus: float = float(item_stats.get("damage_bonus", 0))
	if equip_damage_bonus > 0:
		damage = int(float(damage) * (1.0 + equip_damage_bonus))

	# Apply consumable damage buff
	var consumable_damage_buff: float = _get_item_buff_value("damage_buff")
	if consumable_damage_buff > 0:
		damage = int(float(damage) * (1.0 + consumable_damage_buff))

	# Apply all_buff (affects damage too)
	var all_buff_value: float = _get_item_buff_value("all_buff")
	if all_buff_value > 0:
		damage = int(float(damage) * (1.0 + all_buff_value))

	# Apply special command damage buff
	var cmd_damage_buff: float = float(command_effects.get("damage_buff", 0))
	if cmd_damage_buff > 0:
		damage = int(float(damage) * (1.0 + cmd_damage_buff))

	# Apply challenge mode damage bonus
	if is_challenge_mode:
		var challenge_mods: Dictionary = challenge_state.get("challenge", {}).get("modifiers", {})
		var challenge_damage: float = float(challenge_mods.get("player_damage", 1.0))
		if challenge_damage != 1.0:
			damage = max(1, int(float(damage) * challenge_damage))

	# Apply damage charges (BARRAGE)
	if int(command_effects.get("damage_charges", 0)) > 0:
		var mult: float = float(command_effects.get("damage_charge_mult", 2.0))
		damage = int(float(damage) * mult)
		command_effects["damage_charges"] = int(command_effects["damage_charges"]) - 1
		if int(command_effects.get("damage_charges", 0)) <= 0:
			command_effects.erase("damage_charges")
			command_effects.erase("damage_charge_mult")

	# Apply skill bonuses to damage
	# Burst typing (first 3 words per wave)
	var burst_bonus: float = SimSkills.get_burst_damage_bonus(learned_skills, words_typed_this_wave)
	if burst_bonus > 0:
		damage = int(float(damage) * (1.0 + burst_bonus))

	# Combo damage bonus
	var combo_bonus: float = SimSkills.get_combo_damage_bonus(learned_skills, combo)
	if combo_bonus > 0:
		damage = int(float(damage) * (1.0 + combo_bonus))

	# Perfect combo bonus (10+ combo)
	if SimSkills.has_perfect_combo_bonus(learned_skills, combo):
		damage = int(float(damage) * (1.0 + SimSkills.get_perfect_combo_damage(learned_skills)))

	# Chain kill bonus (kills within 2s)
	var current_time: float = Time.get_unix_time_from_system()
	if current_time - last_kill_time < 2.0:
		chain_kill_count += 1
		var chain_bonus: float = SimSkills.get_chain_damage_bonus(learned_skills) * float(chain_kill_count)
		if chain_bonus > 0:
			damage = int(float(damage) * (1.0 + chain_bonus))
	else:
		chain_kill_count = 0

	# Check for critical strike (skills + equipment + commands)
	var equip_crit_chance: float = float(item_stats.get("crit_chance", 0))
	var equip_crit_damage: float = float(item_stats.get("crit_damage", 0))
	var crit_chance: float = 0.05 + SimSkills.get_crit_chance_bonus(learned_skills) + equip_crit_chance
	var crit_damage_mult: float = 2.0 + SimSkills.get_crit_damage_bonus(learned_skills) + equip_crit_damage

	# Guaranteed crit from CRITICAL command
	var guaranteed_crit: bool = false
	if int(command_effects.get("crit_charges", 0)) > 0:
		guaranteed_crit = true
		command_effects["crit_charges"] = int(command_effects["crit_charges"]) - 1
		if int(command_effects.get("crit_charges", 0)) <= 0:
			command_effects.erase("crit_charges")

	var is_crit: bool = guaranteed_crit or randf() < crit_chance
	if is_crit:
		damage = int(float(damage) * crit_damage_mult)

	# Check for cleave effect (hit ALL enemies)
	var cleave_mult: float = float(command_effects.get("cleave_next", 0))
	if cleave_mult > 0:
		command_effects.erase("cleave_next")
		var cleave_damage: int = max(1, int(float(damage) * cleave_mult))
		var kills: int = 0
		for i in range(active_enemies.size() - 1, -1, -1):
			var e: Dictionary = active_enemies[i]
			if int(e.get("id", -1)) != int(enemy.get("id", -1)):
				e["hp"] = int(e.get("hp", 1)) - cleave_damage
				if int(e.get("hp", 0)) <= 0:
					kills += 1
					gold += 2  # Small gold for cleave kills
					active_enemies.remove_at(i)
				else:
					active_enemies[i] = e
		if kills > 0:
			_update_objective("[color=red]CLEAVE![/color] Hit all enemies, killed %d!" % kills)

	# Apply damage to main target
	enemy["hp"] = int(enemy.get("hp", 1)) - damage

	# Play hit sound
	if audio_manager:
		audio_manager.play_hit_enemy()

	# Track stats
	correct_chars += current_word.length()
	total_chars += current_word.length()
	words_typed += 1
	words_typed_this_wave += 1
	run_words_typed += 1
	var prev_combo: int = combo
	combo += 1
	max_combo = max(max_combo, combo)
	run_best_combo = max(run_best_combo, combo)

	# Quest progress: words typed and combo
	_update_quest_progress("words_typed", 1)
	_update_quest_progress("max_combo", combo)

	# Challenge progress: words and combo
	if is_challenge_mode:
		_update_challenge_progress("words_typed", 1)
		_update_challenge_progress("words_without_break", 1)
		_update_challenge_progress("max_combo", combo)

	# Lifetime stats: words and characters
	SimPlayerStats.increment_stat(profile, "total_words_typed", 1)
	SimPlayerStats.increment_stat(profile, "total_chars_typed", current_word.length())
	SimPlayerStats.increment_stat(profile, "perfect_words", 1)
	SimPlayerStats.increment_stat(profile, "combo_words_typed", 1)

	# Check for tier milestone and announce
	if SimCombo.is_tier_milestone(prev_combo, combo):
		var announcement: String = SimCombo.get_tier_announcement(combo)
		if not announcement.is_empty():
			_update_objective("[color=yellow]%s[/color]" % announcement)
		# Play combo milestone sound
		if audio_manager:
			audio_manager.play_combo_milestone(combo)

	# Check combo achievements
	if achievement_checker != null and combo >= 5:
		achievement_checker.check_combo(profile, combo)
		TypingProfile.save_profile(profile)

	# Check for combo milestone
	if milestone_popup != null and combo >= 10:
		var prev_best_combo: int = SimPlayerStats.get_record(profile, "highest_combo")
		var milestone: Dictionary = SimMilestones.check_combo_milestone(combo, prev_best_combo)
		if not milestone.is_empty():
			milestone_popup.show_milestone(milestone)

	# Fire projectile visual
	if grid_renderer != null and grid_renderer.has_method("spawn_projectile"):
		var enemy_pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
		grid_renderer.spawn_projectile(enemy_pos, is_crit)

	if int(enemy.get("hp", 0)) <= 0:
		# Enemy defeated
		var enemy_kind: String = str(enemy.get("kind", "raider"))
		var is_boss: bool = bool(enemy.get("is_boss", false)) or StoryManager.is_boss_kind(enemy_kind)
		var gold_reward: int = SimEnemies.gold_reward(enemy_kind)

		# Play word complete sound
		if audio_manager:
			audio_manager.play_word_complete()

		# Apply wave composition gold multiplier
		var wave_gold_mult: float = float(current_wave_composition.get("gold_mult", 1.0))
		if wave_gold_mult != 1.0:
			gold_reward = max(1, int(float(gold_reward) * wave_gold_mult))

		# Boss bonus rewards
		if is_boss:
			gold_reward = gold_reward * 5 + 50  # Significant boss bonus
			_update_objective("[color=lime]BOSS DEFEATED![/color] +%d Gold!" % gold_reward)
			# Lifetime stats: boss kill
			SimPlayerStats.increment_stat(profile, "total_boss_kills", 1)
			# Toast notification
			if notification_manager != null:
				var boss_name: String = str(enemy.get("name", enemy_kind))
				notification_manager.notify_boss_defeated(boss_name, gold_reward)

		# Apply combo tier bonus (replaces simple combo bonus)
		gold_reward = SimCombo.apply_gold_bonus(gold_reward, combo)

		# Apply skill gold bonus
		var skill_gold_bonus: float = SimSkills.get_gold_bonus(learned_skills)
		if skill_gold_bonus > 0:
			gold_reward = int(float(gold_reward) * (1.0 + skill_gold_bonus))

		# Apply equipment gold bonus
		var equip_gold_bonus: float = float(item_stats.get("gold_bonus", 0))
		if equip_gold_bonus > 0:
			gold_reward = int(float(gold_reward) * (1.0 + equip_gold_bonus))

		# Apply consumable gold buff
		var consumable_gold_buff: float = _get_item_buff_value("gold_buff")
		if consumable_gold_buff > 0:
			gold_reward = int(float(gold_reward) * (1.0 + consumable_gold_buff))

		# Apply all_buff (affects gold too)
		var all_buff_for_gold: float = _get_item_buff_value("all_buff")
		if all_buff_for_gold > 0:
			gold_reward = int(float(gold_reward) * (1.0 + all_buff_for_gold))

		# Apply special command gold buff
		var cmd_gold_buff: float = float(command_effects.get("gold_buff", 0))
		if cmd_gold_buff > 0:
			gold_reward = int(float(gold_reward) * (1.0 + cmd_gold_buff))

		# Apply difficulty modifier to gold
		gold_reward = SimDifficulty.apply_gold_modifier(gold_reward, difficulty_mode)
		gold += gold_reward
		gold_earned_this_wave += gold_reward
		SimPlayerStats.increment_stat(profile, "total_gold_earned", gold_reward)

		# Award XP for kills (with equipment bonus)
		var base_xp: int = 10 if not is_boss else 100
		var equip_xp_bonus: float = float(item_stats.get("xp_bonus", 0))
		if equip_xp_bonus > 0:
			base_xp = int(float(base_xp) * (1.0 + equip_xp_bonus))
		var xp_result: Dictionary = TypingProfile.add_xp(profile, base_xp)
		if int(xp_result.get("levels_gained", 0)) > 0:
			var new_level: int = int(xp_result.get("new_level", 1))
			var sp_gained: int = int(xp_result.get("skill_points_gained", 0))
			_update_objective("[color=yellow]LEVEL UP![/color] Now level %d! +%d skill point(s)" % [new_level, sp_gained])

			# Toast notification for level up
			if notification_manager != null:
				notification_manager.notify_level_up(new_level, sp_gained)

		# Track chain kills
		last_kill_time = Time.get_unix_time_from_system()

		# Check achievements for enemy defeat
		if achievement_checker != null:
			achievement_checker.on_enemy_defeated(profile, is_boss, enemy_kind)
			TypingProfile.save_profile(profile)

		# Track bestiary encounter
		SimBestiary.record_encounter(profile, enemy_kind, true)
		var affix: String = str(enemy.get("affix", ""))
		if not affix.is_empty():
			SimBestiary.record_affix_encounter(profile, affix)
		TypingProfile.save_profile(profile)

		# Roll for item drop
		var drop_seed: int = state.rng_state + int(enemy.get("id", 0)) * 7
		var dropped_item: String = SimItems.roll_drop(day, is_boss, drop_seed)
		if not dropped_item.is_empty():
			TypingProfile.add_to_inventory(profile, dropped_item)
			TypingProfile.save_profile(profile)
			var item_display: String = SimItems.format_item_display(dropped_item)
			_update_objective("[color=lime]LOOT![/color] Found %s!" % item_display)

		# Roll for crafting material drop
		var is_elite: bool = enemy.get("affixes", []).size() > 0
		var mat_drop: String = SimCrafting.roll_material_drop(day, is_boss, is_elite, drop_seed + 100)
		if not mat_drop.is_empty():
			SimCrafting.add_material(profile, mat_drop, 1)
			TypingProfile.save_profile(profile)
			var mat_info: Dictionary = SimCrafting.MATERIALS.get(mat_drop, {})
			var mat_name: String = str(mat_info.get("name", mat_drop))
			var mat_tier: int = int(mat_info.get("tier", 1))
			_update_objective("[color=cyan]MATERIAL:[/color] Found %s!" % mat_name)
			# Toast for rare+ materials
			if mat_tier >= 3 and notification_manager != null:
				notification_manager.notify_material(mat_name, 1)

		# Quest progress: kills and gold
		_update_quest_progress("kills", 1)
		_update_quest_progress("total_kills", 1)
		_update_quest_progress("gold_earned", gold_reward)
		if is_boss:
			_update_quest_progress("boss_kills", 1)

		# Challenge mode progress: kills
		if is_challenge_mode:
			_update_challenge_progress("kill_count", 1)
			_update_challenge_progress("gold_earned", gold_reward)
			if is_boss:
				_update_challenge_progress("boss_kills", 1)

		# Endless mode kill tracking
		if is_endless_mode:
			endless_run_kills += 1

		# Wave kill tracking (for records)
		kills_this_wave += 1

		# Run tracking
		run_total_kills += 1
		run_damage_dealt += damage
		run_gold_earned += gold_reward
		if is_boss:
			run_boss_kills += 1

		# Lifetime stats tracking (gold and boss kills tracked earlier)
		SimPlayerStats.increment_stat(profile, "total_kills", 1)
		SimPlayerStats.increment_stat(profile, "total_damage_dealt", damage)

		# Critical hit visual
		if is_crit and grid_renderer.has_method("spawn_hit_particles"):
			var pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
			grid_renderer.spawn_hit_particles(pos, 20, Color(1, 1, 0))

		# Spawn hit particles - more for bosses
		if grid_renderer.has_method("spawn_hit_particles"):
			var pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
			var particle_count: int = 12 if not is_boss else 30
			var particle_color: Color = Color(1, 0.5, 0.2) if not is_boss else Color(1, 0.8, 0.1)
			grid_renderer.spawn_hit_particles(pos, particle_count, particle_color)

		active_enemies.remove_at(enemy_index)
		_target_closest_enemy()
	else:
		# Enemy damaged but alive - assign new word
		var used: Dictionary = {}
		for e in active_enemies:
			var w: String = str(e.get("word", ""))
			if w != "":
				used[w] = true
		var new_word: String = SimWords.word_for_enemy(state.rng_seed, day, str(enemy.get("kind", "raider")), int(enemy.get("id", 0)), used, state.lesson_id)
		enemy["word"] = new_word.to_lower()
		current_word = enemy["word"]
		active_enemies[enemy_index] = enemy

	input_field.clear()
	typed_text = ""
	word_start_time = Time.get_unix_time_from_system()

func _find_enemy_index(enemy_id: int) -> int:
	for i in range(active_enemies.size()):
		if int(active_enemies[i].get("id", -1)) == enemy_id:
			return i
	return -1

func _try_build(building_type: String) -> void:
	# Validate building type
	if not SimBuildings.is_valid(building_type):
		_update_objective("[color=red]Unknown building type![/color]")
		return

	# Get cost from SimBuildings
	var cost: Dictionary = SimBuildings.cost_for(building_type)

	# Check resources
	var can_afford: bool = true
	for res in cost.keys():
		var have: int = int(state.resources.get(res, 0))
		if res == "gold":
			have = state.gold
		if have < int(cost.get(res, 0)):
			can_afford = false
			break

	if not can_afford:
		_update_objective("[color=red]Not enough resources![/color]")
		return

	# Check if buildable at cursor
	if not SimMap.is_buildable(state, cursor_grid_pos):
		_update_objective("[color=red]Cannot build there![/color]")
		return

	# Check path still open after build (only for blocking buildings)
	var test_index: int = cursor_grid_pos.y * state.map_w + cursor_grid_pos.x
	if SimBuildings.is_blocking(building_type):
		state.structures[test_index] = building_type
		if not SimMap.path_open_to_base(state):
			state.structures.erase(test_index)
			_update_objective("[color=red]Would block enemy path![/color]")
			return
	else:
		state.structures[test_index] = building_type

	# Deduct resources
	var gold_spent: int = 0
	for res in cost.keys():
		if res == "gold":
			gold_spent = int(cost[res])
			state.gold -= gold_spent
		else:
			state.resources[res] = int(state.resources.get(res, 0)) - int(cost.get(res, 0))
	if gold_spent > 0:
		SimPlayerStats.increment_stat(profile, "total_gold_spent", gold_spent)

	# Update building counts
	state.buildings[building_type] = int(state.buildings.get(building_type, 0)) + 1

	# Play build sound
	if audio_manager:
		audio_manager.play_ui_confirm()

	_update_objective("[color=green]Built %s![/color]" % building_type)
	_update_grid_renderer()
	if kingdom_dashboard:
		kingdom_dashboard.update_state(state)

# Kingdom management command handlers

func _toggle_dashboard() -> void:
	if kingdom_dashboard:
		if kingdom_dashboard.visible:
			kingdom_dashboard.hide_dashboard()
		else:
			kingdom_dashboard.update_state(state)
			kingdom_dashboard.show_dashboard()

func _show_dashboard_tab(tab_index: int) -> void:
	if kingdom_dashboard:
		kingdom_dashboard.update_state(state)
		kingdom_dashboard.show_dashboard()
		if kingdom_dashboard._tabs:
			kingdom_dashboard._tabs.current_tab = tab_index

func _try_upgrade_at_cursor() -> void:
	var index: int = cursor_grid_pos.y * state.map_w + cursor_grid_pos.x
	if not state.structures.has(index):
		_update_objective("[color=red]No building at cursor![/color]")
		return

	var check: Dictionary = SimBuildings.can_upgrade(state, index)
	if not check.ok:
		_update_objective("[color=red]Cannot upgrade: %s[/color]" % check.reason)
		return

	if SimBuildings.apply_upgrade(state, index):
		var building_type: String = str(state.structures[index])
		_update_objective("[color=green]Upgraded %s to level %d![/color]" % [building_type, check.next_level])
		_update_grid_renderer()
		if kingdom_dashboard:
			kingdom_dashboard.update_state(state)

func _try_upgrade_building_type(building_type: String) -> void:
	# Find first building of this type that can be upgraded
	for key in state.structures.keys():
		if str(state.structures[key]) == building_type:
			var check: Dictionary = SimBuildings.can_upgrade(state, int(key))
			if check.ok:
				if SimBuildings.apply_upgrade(state, int(key)):
					_update_objective("[color=green]Upgraded %s to level %d![/color]" % [building_type, check.next_level])
					_update_grid_renderer()
					if kingdom_dashboard:
						kingdom_dashboard.update_state(state)
					return

	_update_objective("[color=red]No %s available to upgrade![/color]" % building_type)

func _try_start_research(research_name: String) -> void:
	if research_instance == null:
		return

	# Find research by label or id
	var all_research: Array = research_instance.get_all_research()
	var research_id: String = ""

	for item in all_research:
		var item_id: String = str(item.get("id", ""))
		var item_label: String = str(item.get("label", "")).to_lower()
		if item_id == research_name or item_label == research_name:
			research_id = item_id
			break

	if research_id.is_empty():
		_update_objective("[color=red]Unknown research: %s[/color]" % research_name)
		return

	var check: Dictionary = research_instance.can_start_research(state, research_id)
	if not check.ok:
		_update_objective("[color=red]Cannot research: %s[/color]" % check.reason)
		return

	if research_instance.start_research(state, research_id):
		var research: Dictionary = research_instance.get_research(research_id)
		_update_objective("[color=cyan]Started research: %s[/color]" % str(research.get("label", research_id)))
		if kingdom_dashboard:
			kingdom_dashboard.update_state(state)

func _try_execute_trade(command: String) -> void:
	var parsed: Dictionary = SimTrade.parse_trade_command(command)
	if not parsed.ok:
		_update_objective("[color=red]Invalid trade: %s[/color]" % parsed.reason)
		return

	var result: Dictionary = SimTrade.execute_trade(state, parsed.from_resource, parsed.to_resource, parsed.amount)
	if result.ok:
		_update_objective("[color=green]Traded %d %s for %d %s![/color]" % [result.from_amount, result.from_resource, result.to_amount, result.to_resource])
		if kingdom_dashboard:
			kingdom_dashboard.update_state(state)
	else:
		_update_objective("[color=red]Trade failed: %s[/color]" % result.reason)

func _show_tile_info() -> void:
	var report: Dictionary = SimBuildings.get_tile_report(state, cursor_grid_pos)
	var info_parts: Array = []

	info_parts.append("Pos: (%d,%d)" % [cursor_grid_pos.x, cursor_grid_pos.y])
	info_parts.append("Terrain: %s" % report.terrain)

	if not report.structure.is_empty():
		info_parts.append("Building: %s Lv%d" % [report.structure, report.structure_level])
		var preview: Dictionary = SimBuildings.get_building_upgrade_preview(state, cursor_grid_pos.y * state.map_w + cursor_grid_pos.x)
		if preview.can_upgrade:
			info_parts.append("Upgrade available!")

	_update_objective("[color=cyan]%s[/color]" % " | ".join(info_parts))

func _calculate_power() -> float:
	var accuracy: float = _get_accuracy()
	var combo_bonus: float = min(combo * 0.1, 1.0)  # Max +100% from combo
	var accuracy_bonus: float = accuracy * 0.5  # Max +50% from accuracy

	# Add typing power bonuses from buildings and research
	var typing_power_bonus: float = 0.0

	# Building effects (barracks, etc.)
	var building_effects: Dictionary = SimBuildings.get_total_effects(state)
	typing_power_bonus += float(building_effects.get("typing_power", 0.0))

	# Research effects
	if research_instance:
		var research_effects: Dictionary = research_instance.get_total_effects(state)
		typing_power_bonus += float(research_effects.get("typing_power", 0.0))

		# Apply combo multiplier from research
		var combo_mult: float = float(research_effects.get("combo_multiplier", 0.0))
		if combo_mult > 0:
			combo_bonus = combo_bonus * (1.0 + combo_mult)

	return 1.0 + combo_bonus + accuracy_bonus + typing_power_bonus

func _get_accuracy() -> float:
	if total_chars == 0:
		return 1.0
	return float(correct_chars) / float(total_chars)

func _get_wpm() -> float:
	if words_typed == 0:
		return 0.0
	var elapsed: float = Time.get_unix_time_from_system() - wave_start_time
	if elapsed < 1.0:
		return 0.0
	return (float(words_typed) / elapsed) * 60.0

func _update_ui() -> void:
	# Top bar - show day and difficulty
	var diff_short: String = difficulty_mode.capitalize().substr(0, 3)
	day_label.text = "Day %d [%s]" % [day, diff_short]
	wave_label.text = "Wave %d/%d" % [wave, waves_per_day]
	hp_value.text = "%d/%d" % [castle_hp, castle_max_hp]
	gold_value.text = "%d" % gold
	resources_label.text = "Wood: %d | Stone: %d | Food: %d" % [
		int(state.resources.get("wood", 0)),
		int(state.resources.get("stone", 0)),
		int(state.resources.get("food", 0))
	]

	var lesson_name: String = SimLessons.lesson_label(state.lesson_id)
	lesson_label.text = "Lesson: %s" % lesson_name

	# Update act label
	if act_label:
		var act_progress: Dictionary = StoryManager.get_act_progress(day)
		act_label.text = "Act %d: %s (Day %d/%d)" % [
			int(act_progress.get("act_number", 1)),
			str(act_progress.get("act_name", "Unknown")),
			int(act_progress.get("day_in_act", 1)),
			int(act_progress.get("total_days", 1))
		]

	phase_label.text = current_phase.to_upper()
	if current_phase == "planning":
		phase_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	elif current_phase == "practice":
		phase_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	else:
		phase_label.add_theme_color_override("font_color", Color(0.9, 0.5, 0.4))

	# Stats bar
	wpm_label.text = "WPM: %d" % int(_get_wpm())
	accuracy_label.text = "Accuracy: %d%%" % int(_get_accuracy() * 100)

	# Combo with tier display
	var combo_display: String = SimCombo.format_combo_display(combo)
	if combo_display.is_empty():
		combo_label.text = "Combo: %d" % combo
		combo_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		combo_label.text = combo_display
		combo_label.add_theme_color_override("font_color", SimCombo.get_tier_color(combo))

	power_label.text = "Power: %.1fx" % _calculate_power()

	# Word display
	if current_phase == "defense" and not current_word.is_empty():
		_update_word_display()
	elif current_phase == "planning":
		word_display.text = "[center][color=white]Planning Phase[/color]\nTime: %d seconds[/center]" % int(planning_timer)

	# Enemy panel
	_update_enemy_panel()

	# Update keyboard display
	_update_keyboard_display()

func _update_word_display() -> void:
	var display: String = "[center]"
	for i in range(current_word.length()):
		var ch: String = current_word[i]
		if i < typed_text.length():
			if typed_text[i] == ch:
				display += "[color=lime]%s[/color]" % ch
			else:
				display += "[color=red]%s[/color]" % ch
		else:
			display += "[color=yellow]%s[/color]" % ch
	display += "[/center]"
	word_display.text = display
	input_display.text = typed_text

func _update_enemy_panel() -> void:
	# Current target
	if target_enemy_id >= 0:
		var enemy_index: int = _find_enemy_index(target_enemy_id)
		if enemy_index >= 0:
			var enemy: Dictionary = active_enemies[enemy_index]
			# Get effective speed with status effects
			var effective_speed: int = SimEnemies.get_effective_speed(enemy)
			var base_speed: int = int(enemy.get("speed", 1))
			var speed_text: String = str(effective_speed)
			if effective_speed < base_speed:
				speed_text = "[color=cyan]%d[/color]" % effective_speed  # Slowed
			elif SimEnemies.is_immobilized(enemy):
				speed_text = "[color=aqua]FROZEN[/color]"
			# Get status effects summary
			var effects_text: String = ""
			var effects: Array[Dictionary] = SimEnemies.get_status_summary(enemy)
			if effects.size() > 0:
				var effect_parts: Array[String] = []
				for eff in effects:
					var color_hex: String = str(eff.get("color", Color.WHITE)).substr(0, 7)
					var stacks: int = int(eff.get("stacks", 1))
					var name: String = str(eff.get("name", ""))
					if stacks > 1:
						effect_parts.append("[color=%s]%s x%d[/color]" % [color_hex, name, stacks])
					else:
						effect_parts.append("[color=%s]%s[/color]" % [color_hex, name])
				effects_text = "\n" + ", ".join(effect_parts)
			current_enemy_label.text = "[center][color=yellow]TARGET[/color]\n[color=orange]%s[/color]\nHP: %d  Speed: %s%s[/center]" % [
				str(enemy.get("kind", "enemy")).to_upper(),
				int(enemy.get("hp", 0)),
				speed_text,
				effects_text
			]
		else:
			current_enemy_label.text = "[center][color=gray]No target[/color][/center]"
	else:
		current_enemy_label.text = "[center][color=gray]No target[/color][/center]"

	# Queue list
	var queue_text: String = ""
	var combined: Array = active_enemies.duplicate()
	var count: int = 1
	for enemy in combined.slice(0, 5):
		if int(enemy.get("id", -1)) == target_enemy_id:
			queue_text += "[color=yellow]> %d. %s (HP: %d)[/color]\n" % [count, str(enemy.get("word", "")), int(enemy.get("hp", 0))]
		else:
			queue_text += "%d. %s (HP: %d)\n" % [count, str(enemy.get("kind", "enemy")), int(enemy.get("hp", 0))]
		count += 1

	var remaining: int = combined.size() + enemy_queue.size() - 5
	if remaining > 0:
		queue_text += "... and %d more" % remaining

	queue_list.text = queue_text

func _update_keyboard_display() -> void:
	if not keyboard_display:
		return

	# Get charset from current lesson
	var lesson: Dictionary = SimLessons.get_lesson(state.lesson_id)
	var charset: String = str(lesson.get("charset", "abcdefghijklmnopqrstuvwxyz"))

	# Determine next key to press
	var next_key: String = ""
	if current_phase == "defense" and current_word.length() > typed_text.length():
		next_key = current_word[typed_text.length()]
	elif current_phase == "planning":
		# In planning phase, show command keys as active
		charset = "abcdefghijklmnopqrstuvwxyz "

	keyboard_display.update_state(charset, next_key)

	# Update finger hint
	_update_finger_hint(next_key)

func _update_finger_hint(next_key: String) -> void:
	if not finger_hint_label:
		return

	if not show_finger_hints or next_key.is_empty():
		finger_hint_label.text = ""
		return

	var finger: String = StoryManager.get_finger_for_key(next_key)
	if finger.is_empty():
		finger_hint_label.text = ""
	else:
		finger_hint_label.text = "Next key '%s' - Use: %s" % [next_key.to_upper(), finger]

func _update_objective(text: String) -> void:
	objective_label.text = "[b]OBJECTIVE[/b]\n%s" % text

func _update_hint(text: String) -> void:
	hint_label.text = text

func _update_grid_renderer() -> void:
	if grid_renderer and grid_renderer.has_method("update_state"):
		state.cursor_pos = cursor_grid_pos
		grid_renderer.update_state(state)

		# Highlight target enemy
		var highlights: Array = []
		if target_enemy_id >= 0:
			highlights.append(target_enemy_id)
		if grid_renderer.has_method("set_enemy_highlights"):
			grid_renderer.set_enemy_highlights(highlights, target_enemy_id)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		# F1 key toggles settings panel
		if event.keycode == KEY_F1:
			_toggle_settings()
			get_viewport().set_input_as_handled()
			return

		# Tab key toggles kingdom dashboard during planning phase
		if event.keycode == KEY_TAB and current_phase == "planning":
			_toggle_dashboard()
			get_viewport().set_input_as_handled()
			return

		# Handle planning phase input
		if current_phase == "planning":
			# Use Ctrl+Arrow keys for grid cursor movement (doesn't conflict with typing)
			var moved: bool = false

			if event.ctrl_pressed:
				match event.keycode:
					KEY_UP:
						cursor_grid_pos.y = max(0, cursor_grid_pos.y - 1)
						moved = true
					KEY_DOWN:
						cursor_grid_pos.y = min(state.map_h - 1, cursor_grid_pos.y + 1)
						moved = true
					KEY_LEFT:
						cursor_grid_pos.x = max(0, cursor_grid_pos.x - 1)
						moved = true
					KEY_RIGHT:
						cursor_grid_pos.x = min(state.map_w - 1, cursor_grid_pos.x + 1)
						moved = true

			if moved:
				state.cursor_pos = cursor_grid_pos
				_update_grid_renderer()
				get_viewport().set_input_as_handled()

func _on_menu_pressed() -> void:
	if game_controller:
		game_controller.go_to_menu()

# Story dialogue functions
func _show_game_start_dialogue() -> void:
	if not dialogue_box:
		game_started = true
		_start_key_practice(state.lesson_id)
		return

	var speaker: String = StoryManager.get_dialogue_speaker("game_start")
	var lines: Array[String] = StoryManager.get_dialogue_lines("game_start")

	if lines.is_empty():
		game_started = true
		_show_lesson_intro(state.lesson_id)
		return

	waiting_for_dialogue = true
	dialogue_box.show_dialogue(speaker, lines)

func _show_act_intro() -> void:
	if not dialogue_box:
		return

	if not StoryManager.should_show_act_intro(day, last_act_intro_day):
		return

	last_act_intro_day = day
	var act: Dictionary = StoryManager.get_act_for_day(day)
	if act.is_empty():
		return

	var speaker: String = StoryManager.get_mentor_name(day)
	var intro_text: String = StoryManager.get_act_intro_text(day)

	if intro_text.is_empty():
		return

	var lines: Array[String] = [intro_text]
	waiting_for_dialogue = true
	dialogue_box.show_dialogue(speaker, lines)

func _show_boss_intro() -> void:
	if not dialogue_box:
		return

	var boss: Dictionary = StoryManager.get_boss_for_day(day)
	if boss.is_empty():
		return

	var boss_name: String = str(boss.get("name", "Boss"))
	var intro_text: String = str(boss.get("intro", ""))
	var taunt: String = str(boss.get("taunt", ""))

	var lines: Array[String] = []
	if not intro_text.is_empty():
		lines.append(intro_text)
	if not taunt.is_empty():
		lines.append("[color=red]%s[/color]: \"%s\"" % [boss_name, taunt])

	if lines.is_empty():
		return

	waiting_for_dialogue = true
	dialogue_box.show_dialogue("", lines)

func _show_boss_defeat() -> void:
	if not dialogue_box:
		return

	var boss: Dictionary = StoryManager.get_boss_for_day(day)
	if boss.is_empty():
		return

	var boss_name: String = str(boss.get("name", "Boss"))
	var defeat_text: String = str(boss.get("defeat", ""))

	if defeat_text.is_empty():
		return

	var lines: Array[String] = ["[color=red]%s[/color]: \"%s\"" % [boss_name, defeat_text]]

	var speaker: String = StoryManager.get_mentor_name(day)
	var victory_lines: Array[String] = StoryManager.get_dialogue_lines("boss_victory", {"boss_name": boss_name})
	lines.append_array(victory_lines)

	waiting_for_dialogue = true
	dialogue_box.show_dialogue(speaker, lines)

func _on_dialogue_finished() -> void:
	waiting_for_dialogue = false

	if not game_started:
		game_started = true
		# Show lesson intro for first lesson with practice
		_show_lesson_intro(state.lesson_id)
		return

	# Check if we have a pending practice session
	if not pending_practice_lesson.is_empty():
		var lesson_to_practice: String = pending_practice_lesson
		pending_practice_lesson = ""
		_start_key_practice(lesson_to_practice)
		return

	# Check if practice just completed
	if current_phase == "practice" and not practice_mode:
		_start_planning_phase()
		return

	# Default: return focus to input
	if input_field:
		input_field.grab_focus()

# Educational feature functions
func _show_random_tip(context: String = "") -> void:
	if not tip_label:
		return

	var tip: String = ""

	# Use contextual tips when context is provided
	if not context.is_empty():
		tip = StoryManager.get_contextual_tip(context)
	else:
		# Try to get a lesson-specific tip first, fall back to general tips
		tip = StoryManager.get_random_lesson_tip(state.lesson_id)

	if not tip.is_empty():
		tip_label.text = "Tip: " + tip

func _show_wave_summary() -> void:
	if wave_summary_panel == null:
		return

	# Build stats dictionary for summary
	var wave_time: float = Time.get_unix_time_from_system() - wave_start_time
	var accuracy: float = _get_accuracy()
	var wpm: float = _get_wpm()

	# Update run-level accuracy/WPM tracking
	if accuracy > 0:
		run_accuracy_sum += accuracy
		run_accuracy_count += 1
		run_best_accuracy = maxf(run_best_accuracy, accuracy)
	if wpm > 0:
		run_best_wpm = max(run_best_wpm, int(wpm))

	# Check for new records
	var prev_best_combo: int = SimPlayerStats.get_record(profile, "highest_combo")
	var prev_best_wpm: int = SimPlayerStats.get_record(profile, "highest_wpm")
	var prev_best_accuracy: float = SimPlayerStats.get_record_float(profile, "highest_accuracy")

	# Check for WPM milestone
	if milestone_popup != null and int(wpm) > 0:
		var wpm_milestone: Dictionary = SimMilestones.check_wpm_milestone(int(wpm), prev_best_wpm)
		if not wpm_milestone.is_empty():
			milestone_popup.show_milestone(wpm_milestone)

	# Check for accuracy milestone (convert to 0-1 scale since that's what milestone checker expects)
	if milestone_popup != null and accuracy >= 0.85:
		var prev_best_accuracy_decimal: float = prev_best_accuracy / 100.0  # Convert from 0-100 to 0-1
		var acc_milestone: Dictionary = SimMilestones.check_accuracy_milestone(accuracy, prev_best_accuracy_decimal)
		if not acc_milestone.is_empty():
			milestone_popup.show_milestone(acc_milestone)

	var summary_stats: Dictionary = {
		"day": day,
		"wave": wave - 1,  # Wave was just incremented
		"won": true,
		"words_typed": words_typed_this_wave,
		"accuracy": accuracy,
		"wpm": int(wpm),
		"best_combo": max_combo,
		"kills": kills_this_wave,
		"gold_earned": gold_earned_this_wave,
		"time": wave_time,
		"damage_taken": damage_taken_this_wave,
		"new_record_combo": max_combo > prev_best_combo and max_combo > 0,
		"new_record_wpm": int(wpm) > prev_best_wpm and wpm > 0
	}

	wave_summary_panel.show_summary(summary_stats)

func _show_contextual_tip_after_wave() -> void:
	# Determine context based on performance
	var accuracy: float = _get_accuracy()
	var context: String = ""

	if accuracy < 0.7:
		context = "error"  # Many errors - show error recovery tips
	elif accuracy < 0.85:
		context = "accuracy"  # Needs accuracy work
	elif _get_wpm() < 20:
		context = "slow"  # Needs rhythm tips
	else:
		context = "practice"  # General practice tips

	_show_random_tip(context)

	# Also show as notification if available and not on cooldown
	if tip_notification and not tip_notification.is_on_cooldown():
		tip_notification.show_tip_for_context(context)

func _show_contextual_defense_tip() -> void:
	if tip_notification == null:
		return

	# First wave of first day - show warm-up tip
	if day == 1 and wave == 1:
		tip_notification.show_tip_for_context("start", true)  # Force show
		return

	# Start of new day - home row reminder
	if wave == 1 and day > 1:
		# Show different tips based on day progress
		var contexts: Array[String] = ["home_row", "practice", "rhythm", "technique"]
		var context: String = contexts[(day - 1) % contexts.size()]
		tip_notification.show_tip_for_context(context)

func _show_lesson_intro(lesson_id: String) -> void:
	if not dialogue_box:
		# No dialogue box - go straight to practice
		_start_key_practice(lesson_id)
		return

	var lines: Array[String] = StoryManager.get_lesson_intro_lines(lesson_id)
	if lines.is_empty():
		# No intro lines - go straight to practice
		_start_key_practice(lesson_id)
		return

	var title: String = StoryManager.get_lesson_title(lesson_id)
	var speaker: String = "Elder Lyra"
	var intro: Dictionary = StoryManager.get_lesson_intro(lesson_id)
	if intro.has("speaker"):
		speaker = str(intro.get("speaker", speaker))

	# Prepend title if available
	if not title.is_empty():
		lines.insert(0, "[color=yellow]" + title + "[/color]")

	# Add practice prompt at the end
	lines.append("[color=cyan]Now let's practice these keys![/color]")

	# Mark that we should start practice after this dialogue
	pending_practice_lesson = lesson_id

	waiting_for_dialogue = true
	dialogue_box.show_dialogue(speaker, lines)

func _show_wave_feedback() -> void:
	if not dialogue_box:
		return

	var accuracy_pct: float = _get_accuracy() * 100.0
	var wpm: float = _get_wpm()

	var feedback_lines: Array[String] = []

	# Accuracy feedback
	var acc_feedback: String = StoryManager.get_accuracy_feedback(accuracy_pct)
	if not acc_feedback.is_empty():
		feedback_lines.append(acc_feedback)

	# Speed feedback
	var speed_feedback: String = StoryManager.get_speed_feedback(wpm)
	if not speed_feedback.is_empty():
		feedback_lines.append(speed_feedback)

	# Combo feedback
	if max_combo >= 5:
		var combo_feedback: String = StoryManager.get_combo_feedback(max_combo)
		if not combo_feedback.is_empty():
			feedback_lines.append(combo_feedback)

	# WPM milestone check
	var wpm_int: int = int(wpm)

	# Update highest WPM record
	if wpm_int > 0:
		var is_new_record: bool = SimPlayerStats.update_record(profile, "highest_wpm", wpm_int)
		if is_new_record and notification_manager != null:
			notification_manager.notify_new_record("Highest WPM", wpm_int)

	var milestone_thresholds: Array[int] = [100, 80, 70, 60, 50, 40, 30, 20]
	for threshold in milestone_thresholds:
		if wpm_int >= threshold and last_wpm_milestone < threshold:
			last_wpm_milestone = threshold
			var milestone_msg: String = StoryManager.get_wpm_milestone_message(wpm_int)
			if not milestone_msg.is_empty():
				feedback_lines.insert(0, "[color=gold]" + milestone_msg + "[/color]")
			break

	if feedback_lines.is_empty():
		return

	# Add a random tip
	var tip: String = StoryManager.get_random_typing_tip()
	if not tip.is_empty():
		feedback_lines.append("[color=cyan]Tip: " + tip + "[/color]")

	waiting_for_dialogue = true
	dialogue_box.show_dialogue("Elder Lyra", feedback_lines)

func _check_lesson_progression() -> void:
	var old_lesson: String = previous_lesson_id
	var new_lesson: String = state.lesson_id

	if old_lesson != new_lesson and not old_lesson.is_empty():
		# Lesson changed - show introduction
		_show_lesson_intro(new_lesson)

	previous_lesson_id = new_lesson

# Key Practice Mode Functions
func _start_key_practice(lesson_id: String) -> void:
	# Get the keys to practice from the lesson intro
	var intro: Dictionary = StoryManager.get_lesson_intro(lesson_id)
	var keys: Array = intro.get("keys", [])

	if keys.is_empty():
		# No specific keys to practice, skip to planning
		_start_planning_phase()
		return

	# Convert to typed array
	practice_keys.clear()
	for k in keys:
		practice_keys.append(str(k).to_lower())

	practice_lesson_id = lesson_id
	practice_index = 0
	practice_correct_count = 0
	practice_attempts = 0
	practice_mode = true
	current_phase = "practice"

	# Clear input field and set focus
	if input_field:
		input_field.clear()
		input_field.grab_focus()

	_update_practice_ui()

func _update_practice_ui() -> void:
	if practice_index >= practice_keys.size():
		return

	var current_key: String = practice_keys[practice_index]
	var finger: String = StoryManager.get_finger_for_key(current_key)
	var progress: String = "%d / %d" % [practice_index + 1, practice_keys.size()]

	# Update word display to show practice prompt
	if word_display:
		var display_key: String = current_key.to_upper() if current_key != " " else "SPACE"
		word_display.text = "[center][color=yellow]Practice Key:[/color]\n[color=white][font_size=48]%s[/font_size][/color][/center]" % display_key

	# Update finger hint
	if finger_hint_label:
		if not finger.is_empty():
			finger_hint_label.text = "Press '%s' with your %s" % [current_key.to_upper() if current_key != " " else "SPACE", finger]
		else:
			finger_hint_label.text = "Press the highlighted key"

	# Update hint label with progress
	if hint_label:
		hint_label.text = "KEY PRACTICE: %s - Press each key as it's highlighted" % progress

	# Update objective
	if objective_label:
		var title: String = StoryManager.get_lesson_title(practice_lesson_id)
		if title.is_empty():
			title = "New Lesson"
		objective_label.text = "[b]%s[/b]\nPractice pressing each new key.\nWatch the keyboard highlight!" % title

	# Update keyboard display to highlight the practice key
	# Use practice keys as the active charset so all practice keys are visible
	if keyboard_display:
		var practice_charset: String = ""
		for k in practice_keys:
			practice_charset += k
		keyboard_display.update_state(practice_charset, current_key)

func _handle_practice_input(key_pressed: String) -> void:
	if not practice_mode or practice_index >= practice_keys.size():
		return

	var expected_key: String = practice_keys[practice_index]
	practice_attempts += 1

	if key_pressed.to_lower() == expected_key:
		# Correct key pressed!
		practice_correct_count += 1
		practice_index += 1

		# Flash the key green
		if keyboard_display:
			keyboard_display.flash_key(key_pressed, true)

		# Check if practice is complete
		if practice_index >= practice_keys.size():
			_complete_key_practice()
		else:
			# Move to next key after short delay
			await get_tree().create_timer(0.3).timeout
			if practice_mode:  # Check still in practice mode
				_update_practice_ui()
	else:
		# Wrong key - flash red and show encouragement
		if keyboard_display:
			keyboard_display.flash_key(key_pressed, false)

		# Show hint about correct key
		if tip_label:
			var finger: String = StoryManager.get_finger_for_key(expected_key)
			tip_label.text = "Try again! Look for the highlighted key on the keyboard."

func _complete_key_practice() -> void:
	practice_mode = false

	var accuracy: float = 100.0
	if practice_attempts > 0:
		accuracy = (float(practice_correct_count) / float(practice_attempts)) * 100.0

	# Show completion message
	var lines: Array[String] = []
	if accuracy >= 100.0:
		lines.append("[color=lime]Perfect![/color] You pressed every key correctly!")
	elif accuracy >= 80.0:
		lines.append("[color=yellow]Well done![/color] You're getting the hang of these keys.")
	else:
		lines.append("Good effort! These keys will become easier with practice.")

	lines.append("Now let's put your new skills to the test in battle!")

	if dialogue_box:
		waiting_for_dialogue = true
		dialogue_box.show_dialogue("Elder Lyra", lines)
	else:
		_start_planning_phase()

func _skip_practice() -> void:
	practice_mode = false
	practice_keys.clear()
	practice_index = 0
	_start_planning_phase()

# Achievement System Functions

func _toggle_achievements() -> void:
	if achievement_panel:
		if achievement_panel.visible:
			achievement_panel.hide_achievements()
		else:
			achievement_panel.show_achievements(profile)

func _check_wave_achievements() -> void:
	if achievement_checker == null:
		return

	# Build stats dictionary for achievement checker
	var accuracy: float = _get_accuracy()
	var wpm: float = _get_wpm()
	var won: bool = castle_hp > 0

	var stats: Dictionary = {
		"accuracy": accuracy,
		"wpm": wpm,
		"damage_taken": damage_taken_this_wave,
		"hp_remaining": castle_hp,
		"won": won,
		"best_combo": max_combo
	}

	# Check wave-related achievements
	achievement_checker.on_wave_complete(profile, stats)

	# Also check lesson mastery achievements
	var mastered: Array = []
	var progress_map: Dictionary = TypingProfile.get_lesson_progress_map(profile)
	for lesson_id in progress_map.keys():
		var progress: Dictionary = progress_map[lesson_id]
		if int(progress.get("goal_passes", 0)) >= 3:
			mastered.append(lesson_id)

	if not mastered.is_empty():
		achievement_checker.check_lesson_mastery(profile, mastered)

	# Save profile with any new achievements
	TypingProfile.save_profile(profile)

func _show_difficulty_options() -> void:
	_toggle_difficulty()

func _toggle_difficulty() -> void:
	if difficulty_panel:
		if difficulty_panel.visible:
			difficulty_panel.hide()
		else:
			var unlocked: Array[String] = SimDifficulty.get_unlocked_modes(profile)
			difficulty_panel.show_difficulty(difficulty_mode, unlocked)

func _try_set_difficulty(mode_id: String) -> void:
	if not SimDifficulty.is_mode_unlocked(mode_id, profile):
		_update_objective("[color=red]Difficulty '%s' is locked. Complete more acts to unlock.[/color]" % mode_id)
		return

	var mode: Dictionary = SimDifficulty.get_mode(mode_id)
	if mode.is_empty():
		_update_objective("[color=red]Unknown difficulty '%s'. Type 'diff' to see options.[/color]" % mode_id)
		return

	difficulty_mode = mode_id
	TypingProfile.set_difficulty_mode(profile, mode_id)
	TypingProfile.save_profile(profile)

	var name: String = SimDifficulty.get_mode_name(mode_id)
	_update_objective("[color=lime]Difficulty set to: %s[/color]" % name)

func _show_status_effects_info() -> void:
	_toggle_effects()

func _toggle_effects() -> void:
	if effects_panel:
		if effects_panel.visible:
			effects_panel.hide()
		else:
			effects_panel.show_effects()

func _show_skills_info() -> void:
	# Open skills panel
	_toggle_skills()

func _try_learn_skill(input: String) -> void:
	var parts: PackedStringArray = input.split(":")
	if parts.size() != 2:
		_update_objective("[color=red]Invalid format. Use 'learn tree:skill' (e.g., 'learn speed:swift_start')[/color]")
		return

	var tree_id: String = parts[0].strip_edges()
	var skill_id: String = parts[1].strip_edges()

	# Validate tree
	var tree: Dictionary = SimSkills.get_tree(tree_id)
	if tree.is_empty():
		_update_objective("[color=red]Unknown skill tree '%s'. Valid: speed, accuracy, defense[/color]" % tree_id)
		return

	# Validate skill
	var skill: Dictionary = SimSkills.get_skill(tree_id, skill_id)
	if skill.is_empty():
		_update_objective("[color=red]Unknown skill '%s' in tree '%s'[/color]" % [skill_id, tree_id])
		return

	var learned_skills: Dictionary = TypingProfile.get_learned_skills(profile)
	var skill_points: int = TypingProfile.get_skill_points(profile)
	var cost: int = SimSkills.get_skill_cost(tree_id, skill_id)
	var max_ranks: int = SimSkills.get_skill_max_ranks(tree_id, skill_id)
	var current_rank: int = SimSkills.get_skill_rank(tree_id, skill_id, learned_skills)

	# Check max rank
	if current_rank >= max_ranks:
		_update_objective("[color=yellow]%s is already at max rank![/color]" % str(skill.get("name", skill_id)))
		return

	# Check prerequisites
	if not SimSkills.can_learn_skill(tree_id, skill_id, learned_skills):
		var prereqs: Array[String] = SimSkills.get_skill_prerequisites(tree_id, skill_id)
		_update_objective("[color=red]Must learn prerequisites first: %s[/color]" % ", ".join(prereqs))
		return

	# Check skill points
	if skill_points < cost:
		_update_objective("[color=red]Not enough skill points! Need %d, have %d[/color]" % [cost, skill_points])
		return

	# Learn the skill
	learned_skills = SimSkills.learn_skill(tree_id, skill_id, learned_skills)
	TypingProfile.set_learned_skills(profile, learned_skills)
	TypingProfile.set_skill_points(profile, skill_points - cost)
	TypingProfile.save_profile(profile)

	var skill_name: String = str(skill.get("name", skill_id))
	var new_rank: int = current_rank + 1
	_update_objective("[color=lime]Learned %s (rank %d/%d)![/color]" % [skill_name, new_rank, max_ranks])

func _show_inventory() -> void:
	# Open equipment panel to inventory tab
	_toggle_equipment()

func _show_equipment() -> void:
	# Open equipment panel to equipped tab
	_toggle_equipment()

func _try_equip_item(item_id: String) -> void:
	var inventory: Array = TypingProfile.get_inventory(profile)

	# Check if item is in inventory
	if not TypingProfile.has_item(profile, item_id):
		_update_objective("[color=red]You don't have '%s' in your inventory![/color]" % item_id)
		return

	# Check if it's equipment
	if not SimItems.is_equipment(item_id):
		_update_objective("[color=red]'%s' is not equippable![/color]" % item_id)
		return

	var slot: String = SimItems.get_slot(item_id)
	var equipment: Dictionary = TypingProfile.get_equipment(profile)
	var old_item: String = str(equipment.get(slot, ""))

	# Remove from inventory
	TypingProfile.remove_from_inventory(profile, item_id)

	# If something was equipped, add it back to inventory
	if not old_item.is_empty():
		TypingProfile.add_to_inventory(profile, old_item)

	# Equip the new item
	TypingProfile.equip_item(profile, item_id, slot)
	TypingProfile.save_profile(profile)

	var item_display: String = SimItems.format_item_display(item_id)
	_update_objective("[color=lime]Equipped %s![/color]" % item_display)
	if not old_item.is_empty():
		var old_display: String = SimItems.format_item_display(old_item)
		_update_objective("[color=lime]Equipped %s![/color] (Unequipped %s)" % [item_display, old_display])

func _try_unequip_slot(slot: String) -> void:
	slot = slot.to_lower()
	var equipment: Dictionary = TypingProfile.get_equipment(profile)

	# Check if valid slot
	if not slot in SimItems.EQUIPMENT_SLOTS:
		_update_objective("[color=red]Invalid slot '%s'! Valid: %s[/color]" % [slot, ", ".join(SimItems.EQUIPMENT_SLOTS)])
		return

	var item_id: String = str(equipment.get(slot, ""))
	if item_id.is_empty():
		_update_objective("[color=yellow]Nothing equipped in %s slot.[/color]" % slot.capitalize())
		return

	# Unequip and add to inventory
	TypingProfile.unequip_item(profile, slot)
	TypingProfile.add_to_inventory(profile, item_id)
	TypingProfile.save_profile(profile)

	var item_display: String = SimItems.format_item_display(item_id)
	_update_objective("[color=lime]Unequipped %s from %s slot.[/color]" % [item_display, slot.capitalize()])

func _try_use_consumable(item_id: String) -> void:
	# Check if item is in inventory
	if not TypingProfile.has_item(profile, item_id):
		_update_objective("[color=red]You don't have '%s' in your inventory![/color]" % item_id)
		return

	# Check if it's a consumable
	if not SimItems.is_consumable(item_id):
		_update_objective("[color=red]'%s' cannot be used![/color]" % item_id)
		return

	var item: Dictionary = SimItems.get_item(item_id)
	var effect: Dictionary = item.get("effect", {})
	var effect_type: String = str(effect.get("type", ""))
	var effect_value: float = float(effect.get("value", 0))
	var duration: float = float(effect.get("duration", 0))
	var item_name: String = str(item.get("name", item_id))

	# Apply effect based on type
	match effect_type:
		"heal":
			var heal_amount: int = int(effect_value)
			var old_hp: int = castle_hp
			castle_hp = min(castle_hp + heal_amount, castle_max_hp)
			var healed: int = castle_hp - old_hp
			TypingProfile.remove_from_inventory(profile, item_id)
			TypingProfile.save_profile(profile)
			_update_objective("[color=lime]Used %s![/color] Restored %d HP." % [item_name, healed])

		"damage_buff":
			active_item_buffs["damage_buff"] = {"remaining": duration, "value": effect_value}
			TypingProfile.remove_from_inventory(profile, item_id)
			TypingProfile.save_profile(profile)
			_update_objective("[color=lime]Used %s![/color] +%.0f%% damage for %.0f seconds." % [item_name, effect_value * 100, duration])

		"gold_buff":
			active_item_buffs["gold_buff"] = {"remaining": duration, "value": effect_value}
			TypingProfile.remove_from_inventory(profile, item_id)
			TypingProfile.save_profile(profile)
			_update_objective("[color=lime]Used %s![/color] +%.0f%% gold for %.0f seconds." % [item_name, effect_value * 100, duration])

		"freeze_all":
			# Apply frozen status to all active enemies
			for i in range(active_enemies.size()):
				var enemy: Dictionary = active_enemies[i]
				enemy = SimEnemies.apply_status_effect(enemy, "frozen", 1, "scroll")
				active_enemies[i] = enemy
			TypingProfile.remove_from_inventory(profile, item_id)
			TypingProfile.save_profile(profile)
			_update_objective("[color=cyan]Used %s![/color] All enemies frozen!" % item_name)

		"regen":
			active_item_buffs["regen"] = {"remaining": duration, "value": effect_value}
			TypingProfile.remove_from_inventory(profile, item_id)
			TypingProfile.save_profile(profile)
			_update_objective("[color=lime]Used %s![/color] Regenerating HP over time." % item_name)

		"all_buff":
			active_item_buffs["all_buff"] = {"remaining": duration, "value": effect_value}
			TypingProfile.remove_from_inventory(profile, item_id)
			TypingProfile.save_profile(profile)
			_update_objective("[color=lime]Used %s![/color] All stats boosted for %.0f seconds." % [item_name, duration])

		_:
			_update_objective("[color=yellow]Unknown effect type '%s'.[/color]" % effect_type)

func _tick_item_buffs(delta: float) -> void:
	var expired: Array[String] = []
	for buff_type in active_item_buffs.keys():
		active_item_buffs[buff_type]["remaining"] = float(active_item_buffs[buff_type].get("remaining", 0)) - delta
		if float(active_item_buffs[buff_type].get("remaining", 0)) <= 0:
			expired.append(buff_type)

	for buff_type in expired:
		active_item_buffs.erase(buff_type)
		_update_objective("[color=gray]%s buff expired.[/color]" % buff_type.replace("_", " ").capitalize())

func _process_auto_towers(delta: float) -> void:
	if active_enemies.is_empty():
		return

	# Use the new combat system
	var combat_result := SimAutoTowerCombat.process_auto_towers(
		state,
		active_enemies,
		auto_tower_cooldowns,
		auto_tower_states,
		delta,
		auto_tower_speed_buff
	)

	# Update tracking dictionaries
	auto_tower_cooldowns = combat_result.updated_cooldowns
	auto_tower_states = combat_result.updated_states

	# Apply damage events and handle kills
	if not combat_result.damage_events.is_empty():
		var damage_result := SimAutoTowerCombat.apply_damage_events(active_enemies, combat_result.damage_events)
		active_enemies = damage_result.updated_enemies

		# Process kills (in reverse order to preserve indices)
		var kill_indices: Array[int] = []
		for kill in damage_result.kills:
			kill_indices.append(int(kill.index))
		kill_indices.sort()
		kill_indices.reverse()

		for idx in kill_indices:
			if idx >= 0 and idx < active_enemies.size():
				var tower_type: String = ""
				for kill in damage_result.kills:
					if int(kill.index) == idx:
						tower_type = str(kill.tower_type)
						break
				_auto_tower_kill(idx, tower_type)

	# Spawn visual effects for attacks
	for attack in combat_result.attacks:
		var tower_pos: Vector2i = attack.tower_pos
		var effect_type: String = str(attack.effect_type)
		var damage_count: int = attack.damage_events.size()

		if damage_count > 0:
			if effect_type == "aoe" or effect_type == "zone":
				_spawn_auto_tower_effect(tower_pos, "aoe", damage_count)
			elif effect_type == "chain":
				# Spawn chain effect - projectile to first target, then chain lines
				if not attack.damage_events.is_empty():
					var first_idx: int = int(attack.damage_events[0].get("enemy_index", -1))
					if first_idx >= 0 and first_idx < active_enemies.size():
						var target_pos: Vector2i = active_enemies[first_idx].get("pos", Vector2i.ZERO)
						_spawn_auto_tower_effect(tower_pos, "chain", damage_count, target_pos)
			elif effect_type == "splash":
				if not attack.damage_events.is_empty():
					var first_idx: int = int(attack.damage_events[0].get("enemy_index", -1))
					if first_idx >= 0 and first_idx < active_enemies.size():
						var target_pos: Vector2i = active_enemies[first_idx].get("pos", Vector2i.ZERO)
						_spawn_auto_tower_effect(tower_pos, "splash", damage_count, target_pos)
			elif effect_type == "contact":
				_spawn_auto_tower_effect(tower_pos, "contact", damage_count)
			else:
				# Single target projectile
				if not attack.damage_events.is_empty():
					var first_idx: int = int(attack.damage_events[0].get("enemy_index", -1))
					if first_idx >= 0 and first_idx < active_enemies.size():
						var target_pos: Vector2i = active_enemies[first_idx].get("pos", Vector2i.ZERO)
						_spawn_auto_tower_effect(tower_pos, "projectile", 1, target_pos)

func _auto_tower_kill(enemy_index: int, tower_type: String) -> void:
	var enemy: Dictionary = active_enemies[enemy_index]
	var is_boss: bool = bool(enemy.get("is_boss", false))
	var enemy_kind: String = str(enemy.get("kind", "unknown"))

	# Award gold (reduced compared to typing kills)
	var gold_reward: int = 2 if not is_boss else 10
	gold += gold_reward

	# Remove enemy
	active_enemies.remove_at(enemy_index)

	# Update targeting if needed
	if target_enemy_id == int(enemy.get("id", -1)):
		_target_closest_enemy()

	# Visual feedback
	var pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
	if grid_renderer and grid_renderer.has_method("spawn_hit_particles"):
		grid_renderer.spawn_hit_particles(pos, 8, Color(0.5, 0.5, 1.0))

func _spawn_auto_tower_effect(tower_pos: Vector2i, effect_type: String, count: int, target_pos: Vector2i = Vector2i.ZERO) -> void:
	if not grid_renderer:
		return

	match effect_type:
		"aoe", "zone":
			if grid_renderer.has_method("spawn_hit_particles"):
				grid_renderer.spawn_hit_particles(tower_pos, count * 5, Color(1.0, 1.0, 0.0))
		"projectile":
			if grid_renderer.has_method("spawn_projectile"):
				grid_renderer.spawn_projectile(tower_pos, target_pos, Color(0.5, 0.8, 1.0))
		"chain":
			# Lightning chain effect
			if grid_renderer.has_method("spawn_projectile"):
				grid_renderer.spawn_projectile(tower_pos, target_pos, Color(0.5, 0.7, 1.0))
			if grid_renderer.has_method("spawn_hit_particles"):
				grid_renderer.spawn_hit_particles(target_pos, count * 3, Color(0.6, 0.8, 1.0))
		"splash":
			# Explosive splash effect
			if grid_renderer.has_method("spawn_projectile"):
				grid_renderer.spawn_projectile(tower_pos, target_pos, Color(1.0, 0.6, 0.2))
			if grid_renderer.has_method("spawn_hit_particles"):
				grid_renderer.spawn_hit_particles(target_pos, count * 4, Color(1.0, 0.5, 0.1))
		"contact":
			# Thorn/contact damage effect
			if grid_renderer.has_method("spawn_hit_particles"):
				grid_renderer.spawn_hit_particles(tower_pos, count * 3, Color(0.3, 0.8, 0.3))

func _get_item_buff_value(buff_type: String) -> float:
	if active_item_buffs.has(buff_type):
		return float(active_item_buffs[buff_type].get("value", 0))
	return 0.0

func _show_shop() -> void:
	# Open shop panel
	_toggle_shop()

func _try_buy_item(item_id: String) -> void:
	# Check if item exists
	if not SimItems.is_consumable(item_id):
		_update_objective("[color=red]'%s' is not available in the shop![/color]" % item_id)
		return

	var item: Dictionary = SimItems.get_item(item_id)
	var price: int = int(item.get("price", 0))
	var item_name: String = str(item.get("name", item_id))

	# Check if player can afford
	if gold < price:
		_update_objective("[color=red]Not enough gold! Need %d, have %d.[/color]" % [price, gold])
		return

	# Purchase the item
	gold -= price
	state.gold = gold
	TypingProfile.add_to_inventory(profile, item_id)
	TypingProfile.save_profile(profile)

	# Lifetime stats: shop purchase
	SimPlayerStats.increment_stat(profile, "total_gold_spent", price)
	SimPlayerStats.increment_stat(profile, "items_purchased", 1)

	_update_objective("[color=lime]Purchased %s for %d gold![/color]" % [item_name, price])

func _show_auto_towers() -> void:
	_toggle_auto_towers()

func _toggle_auto_towers() -> void:
	if auto_towers_panel:
		if auto_towers_panel.visible:
			auto_towers_panel.hide()
		else:
			var towers: Array[Dictionary] = SimBuildings.get_all_auto_towers(state)
			auto_towers_panel.show_auto_towers(towers)

func _show_help() -> void:
	_toggle_help()

func _toggle_help() -> void:
	if help_panel:
		if help_panel.visible:
			help_panel.hide()
		else:
			help_panel.show_help()

func _show_wave_info() -> void:
	_toggle_wave_info()

func _toggle_wave_info() -> void:
	if wave_info_panel:
		if wave_info_panel.visible:
			wave_info_panel.hide()
		else:
			wave_info_panel.show_wave_info(day, wave, waves_per_day, current_wave_composition)

func _show_endless_mode() -> void:
	_toggle_endless_mode_panel()

func _toggle_endless_mode_panel() -> void:
	if endless_mode_panel == null:
		return

	if endless_mode_panel.visible:
		endless_mode_panel.hide()
	else:
		var is_unlocked: bool = SimEndlessMode.is_unlocked(profile)
		var high_scores: Dictionary = SimEndlessMode.get_high_scores(profile)
		var current_day_reached: int = int(TypingProfile.get_profile_value(profile, "max_day_reached", 0))

		if is_endless_mode:
			# Show current run status
			endless_mode_panel.show_current_run(day, wave, max_combo, endless_run_kills)
		else:
			endless_mode_panel.show_endless_mode(is_unlocked, high_scores, current_day_reached)

func _start_endless_mode() -> void:
	if not SimEndlessMode.is_unlocked(profile):
		var max_day_reached: int = int(TypingProfile.get_profile_value(profile, "max_day_reached", 0))
		_update_objective("[color=red]Endless mode locked![/color] Reach Day %d to unlock (currently: %d)" % [SimEndlessMode.UNLOCK_DAY, max_day_reached])
		return

	# Reset game state for endless mode
	is_endless_mode = true
	endless_run_kills = 0
	endless_day_start_time = Time.get_unix_time_from_system()

	# Reset to day 1
	day = 1
	wave = 1
	state.day = day
	castle_hp = castle_max_hp
	gold = 50  # Starting gold for endless
	combo = 0
	max_combo = 0

	# Start the run counter
	SimEndlessMode.start_run(profile)
	TypingProfile.save_profile(profile)

	_update_objective("[color=yellow]ENDLESS MODE STARTED![/color]")
	_update_hint("Survive as long as you can! Difficulty scales infinitely.")

	# Start first wave
	_start_planning_phase()

func _end_endless_run() -> void:
	if not is_endless_mode:
		return

	# Calculate day time
	var day_time: float = Time.get_unix_time_from_system() - endless_day_start_time

	# Update high scores
	var result: Dictionary = SimEndlessMode.update_high_scores(profile, day, wave + (day - 1) * waves_per_day, max_combo, endless_run_kills, day_time)
	TypingProfile.save_profile(profile)

	# Show results
	var lines: Array[String] = []
	lines.append("[color=yellow]ENDLESS RUN COMPLETE![/color]")
	lines.append("")
	lines.append("Final Day: %d, Wave: %d" % [day, wave])
	lines.append("Total Kills: %d" % endless_run_kills)
	lines.append("Max Combo: %d" % max_combo)

	# Show new records
	var new_records: Array = result.get("new_records", [])
	if not new_records.is_empty():
		lines.append("")
		lines.append("[color=lime]NEW RECORDS![/color]")
		for record in new_records:
			lines.append("  • %s" % str(record))

	# Show milestones reached
	var milestones: Array = result.get("milestones_reached", [])
	for milestone_day in milestones:
		var reward: Dictionary = SimEndlessMode.get_milestone_reward(milestone_day)
		if not reward.is_empty():
			lines.append("")
			lines.append("[color=orange]MILESTONE: %s (Day %d)[/color]" % [str(reward.get("name", "")), milestone_day])
			var gold_reward: int = int(reward.get("gold", 0))
			var xp_reward: int = int(reward.get("xp", 0))
			gold += gold_reward
			TypingProfile.add_xp(profile, xp_reward)
			lines.append("  +%d gold, +%d XP" % [gold_reward, xp_reward])

	_update_log(lines)
	is_endless_mode = false

func _show_daily_challenge() -> void:
	_toggle_daily_challenge_panel()

func _toggle_daily_challenge_panel() -> void:
	if daily_challenge_panel == null:
		return

	if daily_challenge_panel.visible:
		daily_challenge_panel.hide()
	else:
		var challenge: Dictionary = SimDailyChallenges.get_daily_challenge(profile)
		var run_progress: int = 0
		if is_challenge_mode:
			run_progress = int(challenge_state.get("progress", 0))
		var token_balance: int = SimDailyChallenges.get_token_balance(profile)
		daily_challenge_panel.show_challenge(challenge, is_challenge_mode, run_progress, token_balance)

func _start_daily_challenge() -> void:
	var challenge: Dictionary = SimDailyChallenges.get_daily_challenge(profile)

	if bool(challenge.get("completed_today", false)):
		_update_objective("[color=yellow]Already completed today's challenge![/color] Come back tomorrow.")
		return

	if is_challenge_mode:
		_update_objective("[color=yellow]Challenge already in progress![/color]")
		return

	if is_endless_mode:
		_update_objective("[color=red]Cannot start challenge while in endless mode![/color]")
		return

	# Start the challenge
	is_challenge_mode = true
	challenge_state = SimDailyChallenges.start_challenge(profile)
	challenge_kills = 0
	challenge_words = 0
	challenge_gold_earned = 0
	challenge_boss_kills = 0

	# Reset game state for challenge
	day = 1
	wave = 1
	state.day = day
	combo = 0
	max_combo = 0

	# Apply challenge modifiers
	var modifiers: Dictionary = challenge_state.get("challenge", {}).get("modifiers", {})
	if modifiers.has("max_hp"):
		castle_max_hp = int(modifiers.get("max_hp", 10))
	else:
		castle_max_hp = 10
	castle_hp = castle_max_hp
	gold = 50

	var challenge_name: String = str(challenge_state.get("challenge", {}).get("name", "Daily Challenge"))
	_update_objective("[color=yellow]%s STARTED![/color]" % challenge_name)
	_update_hint("Complete the goal to earn tokens!")

	_start_planning_phase()

func _update_challenge_progress(stat_type: String, value: int) -> void:
	if not is_challenge_mode:
		return

	challenge_state = SimDailyChallenges.update_progress(challenge_state, stat_type, value)

	# Check for completion
	if SimDailyChallenges.is_complete(challenge_state):
		_complete_daily_challenge()

func _complete_daily_challenge() -> void:
	if not is_challenge_mode:
		return

	var result: Dictionary = SimDailyChallenges.complete_challenge(profile, challenge_state)
	TypingProfile.save_profile(profile)

	# Grant rewards
	gold += int(result.get("gold", 0))
	TypingProfile.add_xp(profile, int(result.get("xp", 0)))

	var lines: Array[String] = []
	lines.append("[color=lime]DAILY CHALLENGE COMPLETE![/color]")
	lines.append("")
	lines.append("Rewards:")
	lines.append("  +%d gold" % int(result.get("gold", 0)))
	lines.append("  +%d XP" % int(result.get("xp", 0)))
	lines.append("  +%d tokens" % int(result.get("tokens", 0)))

	if not str(result.get("streak_milestone", "")).is_empty():
		lines.append("")
		lines.append("[color=orange]STREAK BONUS: %s![/color]" % str(result.get("streak_milestone", "")))
		lines.append("  +%d bonus tokens" % int(result.get("streak_bonus", 0)))

	lines.append("")
	lines.append("Total Tokens: %d" % SimDailyChallenges.get_token_balance(profile))

	_update_log(lines)
	is_challenge_mode = false

func _fail_daily_challenge(reason: String) -> void:
	if not is_challenge_mode:
		return

	var lines: Array[String] = []
	lines.append("[color=red]DAILY CHALLENGE FAILED![/color]")
	lines.append(reason)
	lines.append("")

	var goal: Dictionary = challenge_state.get("challenge", {}).get("goal", {})
	var target: int = int(goal.get("target", 0))
	var progress: int = int(challenge_state.get("progress", 0))
	lines.append("Progress: %d / %d" % [progress, target])
	lines.append("")
	lines.append("[color=gray]Try again tomorrow or restart now![/color]")

	_update_log(lines)
	is_challenge_mode = false

func _show_token_shop() -> void:
	_toggle_token_shop_panel()

func _toggle_token_shop_panel() -> void:
	if token_shop_panel == null:
		return

	if token_shop_panel.visible:
		token_shop_panel.hide()
	else:
		var balance: int = SimDailyChallenges.get_token_balance(profile)
		token_shop_panel.show_shop(profile, balance)

func _try_buy_token_item(item_id: String) -> void:
	var result: Dictionary = SimDailyChallenges.purchase_token_item(profile, item_id)

	if bool(result.get("success", false)):
		var item: Dictionary = result.get("item", {})
		var name: String = str(item.get("name", item_id))
		TypingProfile.save_profile(profile)
		_update_objective("[color=lime]Purchased %s![/color]" % name)
	else:
		_update_objective("[color=red]%s[/color]" % str(result.get("error", "Purchase failed")))

func _show_stats_summary() -> void:
	_toggle_stats_panel("overview")

func _show_stats_full() -> void:
	_toggle_stats_panel("overview")

func _show_records() -> void:
	_toggle_stats_panel("records")

func _toggle_stats_panel(tab: String = "overview") -> void:
	if stats_panel == null:
		return

	if stats_panel.visible:
		stats_panel.hide()
	else:
		stats_panel.show_stats(profile, tab)

func _show_expeditions() -> void:
	_toggle_expeditions_panel()

func _toggle_expeditions_panel() -> void:
	if expeditions_panel == null:
		return

	if expeditions_panel.visible:
		expeditions_panel.hide()
	else:
		expeditions_panel.show_expeditions(state)

func _show_synergies() -> void:
	_toggle_synergies_panel()

func _toggle_synergies_panel() -> void:
	if synergies_panel == null:
		return

	if synergies_panel.visible:
		synergies_panel.hide()
	else:
		synergies_panel.show_synergies(state)

func _show_buffs() -> void:
	_toggle_buffs_panel()

func _toggle_buffs_panel() -> void:
	if buffs_panel == null:
		return

	if buffs_panel.visible:
		buffs_panel.hide()
	else:
		buffs_panel.show_buffs(profile)

func _show_summons() -> void:
	_toggle_summoned_units_panel()

func _toggle_summoned_units_panel() -> void:
	if summoned_units_panel == null:
		return

	if summoned_units_panel.visible:
		summoned_units_panel.hide()
	else:
		summoned_units_panel.show_summons(state)

func _show_loot() -> void:
	_toggle_loot_panel()

func _toggle_loot_panel() -> void:
	if loot_panel == null:
		return

	if loot_panel.visible:
		loot_panel.hide()
	else:
		loot_panel.show_loot(state)

func _show_nodes() -> void:
	_toggle_resource_nodes_panel()

func _toggle_resource_nodes_panel() -> void:
	if resource_nodes_panel == null:
		return

	if resource_nodes_panel.visible:
		resource_nodes_panel.hide()
	else:
		resource_nodes_panel.show_nodes(state)

func _show_affixes() -> void:
	_toggle_affixes_panel()

func _toggle_affixes_panel() -> void:
	if affixes_panel == null:
		return

	if affixes_panel.visible:
		affixes_panel.hide()
	else:
		affixes_panel.show_affixes(state)

func _show_damage_types() -> void:
	_toggle_damage_types_panel()

func _toggle_damage_types_panel() -> void:
	if damage_types_panel == null:
		return

	if damage_types_panel.visible:
		damage_types_panel.hide()
	else:
		damage_types_panel.show_damage_types()

func _show_pois() -> void:
	_toggle_poi_panel()

func _toggle_poi_panel() -> void:
	if poi_panel == null:
		return

	if poi_panel.visible:
		poi_panel.hide()
	else:
		poi_panel.show_pois(state)

func _show_towers() -> void:
	_toggle_tower_encyclopedia_panel()

func _toggle_tower_encyclopedia_panel() -> void:
	if tower_encyclopedia_panel == null:
		return

	if tower_encyclopedia_panel.visible:
		tower_encyclopedia_panel.hide()
	else:
		tower_encyclopedia_panel.show_encyclopedia()

func _show_status_effects() -> void:
	_toggle_status_effects_panel()

func _toggle_status_effects_panel() -> void:
	if status_effects_panel == null:
		return

	if status_effects_panel.visible:
		status_effects_panel.hide()
	else:
		status_effects_panel.show_status_effects(state)

func _show_combo_system() -> void:
	_toggle_combo_system_panel()

func _toggle_combo_system_panel() -> void:
	if combo_system_panel == null:
		return

	if combo_system_panel.visible:
		combo_system_panel.hide()
	else:
		combo_system_panel.show_combo_system(state)

func _show_milestones() -> void:
	_toggle_milestones_panel()

func _toggle_milestones_panel() -> void:
	if milestones_panel == null:
		return

	if milestones_panel.visible:
		milestones_panel.hide()
	else:
		milestones_panel.show_milestones(profile)

func _show_practice_goals() -> void:
	_toggle_practice_goals_panel()

func _toggle_practice_goals_panel() -> void:
	if practice_goals_panel == null:
		return

	if practice_goals_panel.visible:
		practice_goals_panel.hide()
	else:
		var current_goal: String = str(profile.get("practice_goal", "balanced"))
		practice_goals_panel.show_practice_goals(profile, current_goal)

func _show_wave_themes() -> void:
	_toggle_wave_themes_panel()

func _toggle_wave_themes_panel() -> void:
	if wave_themes_panel == null:
		return

	if wave_themes_panel.visible:
		wave_themes_panel.hide()
	else:
		wave_themes_panel.show_wave_themes(state)

func _show_special_commands() -> void:
	_toggle_special_commands_panel()

func _toggle_special_commands_panel() -> void:
	if special_commands_panel == null:
		return

	if special_commands_panel.visible:
		special_commands_panel.hide()
	else:
		var player_level: int = int(profile.get("level", 1))
		special_commands_panel.show_special_commands(player_level, command_cooldowns)

func _show_lifetime_stats() -> void:
	_toggle_lifetime_stats_panel()

func _toggle_lifetime_stats_panel() -> void:
	if lifetime_stats_panel == null:
		return

	if lifetime_stats_panel.visible:
		lifetime_stats_panel.hide()
	else:
		lifetime_stats_panel.show_lifetime_stats(profile)

func _show_keyboard_reference() -> void:
	_toggle_keyboard_reference_panel()

func _toggle_keyboard_reference_panel() -> void:
	if keyboard_reference_panel == null:
		return

	if keyboard_reference_panel.visible:
		keyboard_reference_panel.hide()
	else:
		keyboard_reference_panel.show_keyboard_reference()

func _show_login_rewards() -> void:
	_toggle_login_rewards_panel()

func _toggle_login_rewards_panel() -> void:
	if login_rewards_panel == null:
		return

	if login_rewards_panel.visible:
		login_rewards_panel.hide()
	else:
		var streak: Dictionary = profile.get("streak", {})
		var current_streak: int = int(streak.get("current", 0))
		var can_claim: bool = SimLoginRewards.should_show_reward(profile)
		login_rewards_panel.show_login_rewards(current_streak, can_claim)

func _show_typing_tower_bonuses() -> void:
	_toggle_typing_tower_bonuses_panel()

func _toggle_typing_tower_bonuses_panel() -> void:
	if typing_tower_bonuses_panel == null:
		return

	if typing_tower_bonuses_panel.visible:
		typing_tower_bonuses_panel.hide()
	else:
		typing_tower_bonuses_panel.show_typing_tower_bonuses()

func _show_research_tree() -> void:
	_toggle_research_tree_panel()

func _toggle_research_tree_panel() -> void:
	if research_tree_panel == null:
		return

	if research_tree_panel.visible:
		research_tree_panel.hide()
	else:
		var research_instance: SimResearch = SimResearch.instance()
		var tree: Dictionary = research_instance.get_research_tree(state)
		research_tree_panel.show_research_tree(tree, state.gold)

func _show_trade_market() -> void:
	_toggle_trade_panel()

func _toggle_trade_panel() -> void:
	if trade_panel == null:
		return

	if trade_panel.visible:
		trade_panel.hide()
	else:
		var summary: Dictionary = SimTrade.get_trade_summary(state)
		trade_panel.show_trade_market(summary)

func _show_targeting_modes() -> void:
	_toggle_targeting_modes_panel()

func _toggle_targeting_modes_panel() -> void:
	if targeting_modes_panel == null:
		return

	if targeting_modes_panel.visible:
		targeting_modes_panel.hide()
	else:
		targeting_modes_panel.show_targeting_modes()

func _show_workers() -> void:
	_toggle_workers_panel()

func _toggle_workers_panel() -> void:
	if workers_panel == null:
		return

	if workers_panel.visible:
		workers_panel.hide()
	else:
		var summary: Dictionary = SimWorkers.get_worker_summary(state)
		workers_panel.show_workers(summary)

func _show_event_effects() -> void:
	_toggle_event_effects_panel()

func _toggle_event_effects_panel() -> void:
	if event_effects_panel == null:
		return

	if event_effects_panel.visible:
		event_effects_panel.hide()
	else:
		event_effects_panel.show_event_effects()

func _show_upgrades() -> void:
	_toggle_upgrades_panel()

func _toggle_upgrades_panel() -> void:
	if upgrades_panel == null:
		return

	if upgrades_panel.visible:
		upgrades_panel.hide()
	else:
		upgrades_panel.show_upgrades(
			state.gold,
			state.purchased_kingdom_upgrades,
			state.purchased_unit_upgrades
		)

func _show_balance_reference() -> void:
	_toggle_balance_reference_panel()

func _toggle_balance_reference_panel() -> void:
	if balance_reference_panel == null:
		return

	if balance_reference_panel.visible:
		balance_reference_panel.hide()
	else:
		balance_reference_panel.show_balance_reference()

func _show_wave_composition() -> void:
	_toggle_wave_composition_panel()

func _toggle_wave_composition_panel() -> void:
	if wave_composition_panel == null:
		return

	if wave_composition_panel.visible:
		wave_composition_panel.hide()
	else:
		wave_composition_panel.show_wave_composition()

func _show_synergy_reference() -> void:
	_toggle_synergy_reference_panel()

func _toggle_synergy_reference_panel() -> void:
	if synergy_reference_panel == null:
		return

	if synergy_reference_panel.visible:
		synergy_reference_panel.hide()
	else:
		synergy_reference_panel.show_synergies()

func _show_typing_metrics() -> void:
	_toggle_typing_metrics_panel()

func _toggle_typing_metrics_panel() -> void:
	if typing_metrics_panel == null:
		return

	if typing_metrics_panel.visible:
		typing_metrics_panel.hide()
	else:
		typing_metrics_panel.show_typing_metrics()

func _show_tower_types_reference() -> void:
	_toggle_tower_types_reference_panel()

func _toggle_tower_types_reference_panel() -> void:
	if tower_types_reference_panel == null:
		return

	if tower_types_reference_panel.visible:
		tower_types_reference_panel.hide()
	else:
		tower_types_reference_panel.show_tower_types_reference()

func _show_enemy_types_reference() -> void:
	_toggle_enemy_types_reference_panel()

func _toggle_enemy_types_reference_panel() -> void:
	if enemy_types_reference_panel == null:
		return

	if enemy_types_reference_panel.visible:
		enemy_types_reference_panel.hide()
	else:
		enemy_types_reference_panel.show_enemy_types_reference()

func _show_building_types_reference() -> void:
	_toggle_building_types_reference_panel()

func _toggle_building_types_reference_panel() -> void:
	if building_types_reference_panel == null:
		return

	if building_types_reference_panel.visible:
		building_types_reference_panel.hide()
	else:
		building_types_reference_panel.show_building_types_reference()

func _show_research_tree_reference() -> void:
	_toggle_research_tree_reference_panel()

func _toggle_research_tree_reference_panel() -> void:
	if research_tree_reference_panel == null:
		return

	if research_tree_reference_panel.visible:
		research_tree_reference_panel.hide()
	else:
		research_tree_reference_panel.show_research_tree_reference()

func _show_workers_reference() -> void:
	_toggle_workers_reference_panel()

func _toggle_workers_reference_panel() -> void:
	if workers_reference_panel == null:
		return

	if workers_reference_panel.visible:
		workers_reference_panel.hide()
	else:
		workers_reference_panel.show_workers_reference()

func _show_trade_reference() -> void:
	_toggle_trade_reference_panel()

func _toggle_trade_reference_panel() -> void:
	if trade_reference_panel == null:
		return

	if trade_reference_panel.visible:
		trade_reference_panel.hide()
	else:
		trade_reference_panel.show_trade_reference()

func _show_lessons_reference() -> void:
	_toggle_lessons_reference_panel()

func _toggle_lessons_reference_panel() -> void:
	if lessons_reference_panel == null:
		return

	if lessons_reference_panel.visible:
		lessons_reference_panel.hide()
	else:
		lessons_reference_panel.show_lessons_reference()

func _show_kingdom_upgrades_reference() -> void:
	_toggle_kingdom_upgrades_reference_panel()

func _toggle_kingdom_upgrades_reference_panel() -> void:
	if kingdom_upgrades_reference_panel == null:
		return

	if kingdom_upgrades_reference_panel.visible:
		kingdom_upgrades_reference_panel.hide()
	else:
		kingdom_upgrades_reference_panel.show_kingdom_upgrades_reference()

func _show_special_commands_reference() -> void:
	_toggle_special_commands_reference_panel()

func _toggle_special_commands_reference_panel() -> void:
	if special_commands_reference_panel == null:
		return

	if special_commands_reference_panel.visible:
		special_commands_reference_panel.hide()
	else:
		special_commands_reference_panel.show_special_commands_reference()

func _show_status_effects_reference() -> void:
	_toggle_status_effects_reference_panel()

func _toggle_status_effects_reference_panel() -> void:
	if status_effects_reference_panel == null:
		return

	if status_effects_reference_panel.visible:
		status_effects_reference_panel.hide()
	else:
		status_effects_reference_panel.show_status_effects_reference()

func _show_combo_system_reference() -> void:
	_toggle_combo_system_reference_panel()

func _toggle_combo_system_reference_panel() -> void:
	if combo_system_reference_panel == null:
		return

	if combo_system_reference_panel.visible:
		combo_system_reference_panel.hide()
	else:
		combo_system_reference_panel.show_combo_system_reference()

func _show_difficulty_modes_reference() -> void:
	_toggle_difficulty_modes_reference_panel()

func _toggle_difficulty_modes_reference_panel() -> void:
	if difficulty_modes_reference_panel == null:
		return

	if difficulty_modes_reference_panel.visible:
		difficulty_modes_reference_panel.hide()
	else:
		difficulty_modes_reference_panel.show_difficulty_modes_reference()

func _show_damage_types_reference() -> void:
	_toggle_damage_types_reference_panel()

func _toggle_damage_types_reference_panel() -> void:
	if damage_types_reference_panel == null:
		return

	if damage_types_reference_panel.visible:
		damage_types_reference_panel.hide()
	else:
		damage_types_reference_panel.show_damage_types_reference()

func _show_enemy_affixes_reference() -> void:
	_toggle_enemy_affixes_reference_panel()

func _toggle_enemy_affixes_reference_panel() -> void:
	if enemy_affixes_reference_panel == null:
		return

	if enemy_affixes_reference_panel.visible:
		enemy_affixes_reference_panel.hide()
	else:
		enemy_affixes_reference_panel.show_enemy_affixes_reference()

func _show_equipment_items_reference() -> void:
	_toggle_equipment_items_reference_panel()

func _toggle_equipment_items_reference_panel() -> void:
	if equipment_items_reference_panel == null:
		return

	if equipment_items_reference_panel.visible:
		equipment_items_reference_panel.hide()
	else:
		equipment_items_reference_panel.show_equipment_items_reference()

func _show_skill_trees_reference() -> void:
	_toggle_skill_trees_reference_panel()

func _toggle_skill_trees_reference_panel() -> void:
	if skill_trees_reference_panel == null:
		return

	if skill_trees_reference_panel.visible:
		skill_trees_reference_panel.hide()
	else:
		skill_trees_reference_panel.show_skill_trees_reference()

func _show_expeditions_reference() -> void:
	_toggle_expeditions_reference_panel()

func _toggle_expeditions_reference_panel() -> void:
	if expeditions_reference_panel == null:
		return

	if expeditions_reference_panel.visible:
		expeditions_reference_panel.hide()
	else:
		expeditions_reference_panel.show_expeditions_reference()

func _show_daily_challenges_reference() -> void:
	_toggle_daily_challenges_reference_panel()

func _toggle_daily_challenges_reference_panel() -> void:
	if daily_challenges_reference_panel == null:
		return

	if daily_challenges_reference_panel.visible:
		daily_challenges_reference_panel.hide()
	else:
		daily_challenges_reference_panel.show_daily_challenges_reference()

func _show_milestones_reference() -> void:
	_toggle_milestones_reference_panel()

func _toggle_milestones_reference_panel() -> void:
	if milestones_reference_panel == null:
		return

	if milestones_reference_panel.visible:
		milestones_reference_panel.hide()
	else:
		milestones_reference_panel.show_milestones_reference()

func _show_login_rewards_reference() -> void:
	_toggle_login_rewards_reference_panel()

func _toggle_login_rewards_reference_panel() -> void:
	if login_rewards_reference_panel == null:
		return

	if login_rewards_reference_panel.visible:
		login_rewards_reference_panel.hide()
	else:
		login_rewards_reference_panel.show_login_rewards_reference()

func _show_loot_system_reference() -> void:
	_toggle_loot_system_reference_panel()

func _toggle_loot_system_reference_panel() -> void:
	if loot_system_reference_panel == null:
		return

	if loot_system_reference_panel.visible:
		loot_system_reference_panel.hide()
	else:
		loot_system_reference_panel.show_loot_system_reference()

func _show_quests_reference() -> void:
	_toggle_quests_reference_panel()

func _toggle_quests_reference_panel() -> void:
	if quests_reference_panel == null:
		return

	if quests_reference_panel.visible:
		quests_reference_panel.hide()
	else:
		quests_reference_panel.show_quests_reference()

func _show_resource_nodes_reference() -> void:
	_toggle_resource_nodes_reference_panel()

func _toggle_resource_nodes_reference_panel() -> void:
	if resource_nodes_reference_panel == null:
		return

	if resource_nodes_reference_panel.visible:
		resource_nodes_reference_panel.hide()
	else:
		resource_nodes_reference_panel.show_resource_nodes_reference()

func _show_player_stats_reference() -> void:
	_toggle_player_stats_reference_panel()

func _toggle_player_stats_reference_panel() -> void:
	if player_stats_reference_panel == null:
		return

	if player_stats_reference_panel.visible:
		player_stats_reference_panel.hide()
	else:
		player_stats_reference_panel.show_player_stats_reference()

func _show_wave_composer_reference() -> void:
	_toggle_wave_composer_reference_panel()

func _toggle_wave_composer_reference_panel() -> void:
	if wave_composer_reference_panel == null:
		return

	if wave_composer_reference_panel.visible:
		wave_composer_reference_panel.hide()
	else:
		wave_composer_reference_panel.show_wave_composer_reference()

func _show_materials() -> void:
	_toggle_materials_panel()

func _toggle_materials_panel() -> void:
	if materials_panel == null:
		return

	if materials_panel.visible:
		materials_panel.hide()
	else:
		var mats: Dictionary = SimCrafting.get_materials(profile)
		var player_level: int = int(TypingProfile.get_profile_value(profile, "player_level", 1))
		materials_panel.show_materials(mats, player_level)

func _show_recipes(category: String = "") -> void:
	_toggle_recipes_panel(category)

func _toggle_recipes_panel(category: String = "") -> void:
	if recipes_panel == null:
		return

	if recipes_panel.visible:
		recipes_panel.hide()
	else:
		recipes_panel.show_recipes(profile, gold, category)

func _show_recipe_detail(recipe_id: String) -> void:
	# Show the recipes panel - the user can find the recipe there
	_toggle_recipes_panel("")

func _try_craft(recipe_id: String) -> void:
	var check: Dictionary = SimCrafting.can_craft(profile, recipe_id, gold)
	if not bool(check.get("can_craft", false)):
		_update_objective("[color=red]Cannot craft: %s[/color]" % str(check.get("reason", "Unknown error")))
		return

	var result: Dictionary = SimCrafting.craft(profile, recipe_id, gold)
	if not bool(result.get("success", false)):
		_update_objective("[color=red]Crafting failed: %s[/color]" % str(result.get("error", "Unknown error")))
		return

	# Deduct gold
	var gold_cost: int = int(result.get("gold_cost", 0))
	gold -= gold_cost
	state.gold = gold

	# Track stats
	SimPlayerStats.increment_stat(profile, "total_gold_spent", gold_cost)
	TypingProfile.save_profile(profile)

	var recipe_name: String = str(result.get("recipe_name", recipe_id))
	var output_item: String = str(result.get("output_item", ""))
	var output_qty: int = int(result.get("output_qty", 1))

	_update_objective("[color=lime]Crafted %s![/color] Received %s x%d" % [recipe_name, output_item, output_qty])

func _toggle_spells() -> void:
	if spells_panel:
		if spells_panel.visible:
			spells_panel.hide()
		else:
			var player_level: int = int(TypingProfile.get_profile_value(profile, "player_level", 1))
			spells_panel.show_spells(player_level, command_cooldowns)

func _tick_command_cooldowns(delta: float) -> void:
	# Tick cooldowns
	var expired: Array[String] = []
	for cmd_id in command_cooldowns.keys():
		command_cooldowns[cmd_id] = max(0.0, float(command_cooldowns[cmd_id]) - delta)
		if float(command_cooldowns[cmd_id]) <= 0:
			expired.append(cmd_id)

	for cmd_id in expired:
		command_cooldowns.erase(cmd_id)

	# Tick duration-based effects
	if command_effects.has("damage_buff_duration"):
		command_effects["damage_buff_duration"] = float(command_effects["damage_buff_duration"]) - delta
		if float(command_effects["damage_buff_duration"]) <= 0:
			command_effects.erase("damage_buff")
			command_effects.erase("damage_buff_duration")
			_update_objective("[color=gray]Damage buff expired.[/color]")

	if command_effects.has("gold_buff_duration"):
		command_effects["gold_buff_duration"] = float(command_effects["gold_buff_duration"]) - delta
		if float(command_effects["gold_buff_duration"]) <= 0:
			command_effects.erase("gold_buff")
			command_effects.erase("gold_buff_duration")
			_update_objective("[color=gray]Gold buff expired.[/color]")

	if command_effects.has("fortify_duration"):
		command_effects["fortify_duration"] = float(command_effects["fortify_duration"]) - delta
		if float(command_effects["fortify_duration"]) <= 0:
			command_effects.erase("fortify")
			command_effects.erase("fortify_duration")
			_update_objective("[color=gray]Fortify expired.[/color]")

	if command_effects.has("auto_speed_duration"):
		command_effects["auto_speed_duration"] = float(command_effects["auto_speed_duration"]) - delta
		if float(command_effects["auto_speed_duration"]) <= 0:
			auto_tower_speed_buff = 1.0
			command_effects.erase("auto_speed_duration")
			_update_objective("[color=gray]Overcharge expired.[/color]")

func _try_execute_command(command_id: String) -> void:
	var player_level: int = int(TypingProfile.get_profile_value(profile, "player_level", 1))

	# Check if unlocked
	if not SimSpecialCommands.is_unlocked(command_id, player_level):
		var unlock_level: int = SimSpecialCommands.get_unlock_level(command_id)
		_update_objective("[color=red]Command locked! Requires level %d.[/color]" % unlock_level)
		return

	# Check cooldown
	var cooldown_remaining: float = float(command_cooldowns.get(command_id, 0))
	if cooldown_remaining > 0:
		_update_objective("[color=red]Command on cooldown! %.0f seconds remaining.[/color]" % cooldown_remaining)
		return

	# Execute the command
	var cmd: Dictionary = SimSpecialCommands.get_command(command_id)
	var effect: Dictionary = cmd.get("effect", {})
	var effect_type: String = str(effect.get("type", ""))
	var cooldown: float = SimSpecialCommands.get_cooldown(command_id)
	var cmd_name: String = str(cmd.get("name", command_id))

	match effect_type:
		"heal":
			var heal_amount: int = int(effect.get("value", 3))
			var old_hp: int = castle_hp
			castle_hp = min(castle_hp + heal_amount, castle_max_hp)
			var healed: int = castle_hp - old_hp
			_update_objective("[color=lime]%s![/color] Restored %d HP." % [cmd_name, healed])

		"damage_buff":
			var value: float = float(effect.get("value", 0.5))
			var duration: float = float(effect.get("duration", 10.0))
			command_effects["damage_buff"] = value
			command_effects["damage_buff_duration"] = duration
			_update_objective("[color=lime]%s![/color] +%.0f%% damage for %.0fs!" % [cmd_name, value * 100, duration])

		"gold_buff":
			var value: float = float(effect.get("value", 1.0))
			var duration: float = float(effect.get("duration", 20.0))
			command_effects["gold_buff"] = value
			command_effects["gold_buff_duration"] = duration
			_update_objective("[color=gold]%s![/color] +%.0f%% gold for %.0fs!" % [cmd_name, value * 100, duration])

		"damage_charges":
			var value: float = float(effect.get("value", 2.0))
			var charges: int = int(effect.get("charges", 5))
			command_effects["damage_charges"] = charges
			command_effects["damage_charge_mult"] = value
			_update_objective("[color=lime]%s![/color] Next %d attacks deal %.0fx damage!" % [cmd_name, charges, value])

		"crit_charges":
			var charges: int = int(effect.get("charges", 3))
			command_effects["crit_charges"] = charges
			_update_objective("[color=orange]%s![/color] Next %d attacks are guaranteed crits!" % [cmd_name, charges])

		"freeze_all":
			var duration: float = float(effect.get("duration", 3.0))
			for i in range(active_enemies.size()):
				var enemy: Dictionary = active_enemies[i]
				enemy = SimEnemies.apply_status_effect(enemy, "frozen", 1, "spell")
				active_enemies[i] = enemy
			_update_objective("[color=cyan]%s![/color] All enemies frozen!" % cmd_name)

		"damage_reduction":
			var value: float = float(effect.get("value", 0.5))
			var duration: float = float(effect.get("duration", 15.0))
			command_effects["fortify"] = value
			command_effects["fortify_duration"] = duration
			_update_objective("[color=cyan]%s![/color] Castle takes %.0f%% less damage for %.0fs!" % [cmd_name, value * 100, duration])

		"auto_tower_speed":
			var value: float = float(effect.get("value", 2.0))
			var duration: float = float(effect.get("duration", 5.0))
			auto_tower_speed_buff = value
			command_effects["auto_speed_duration"] = duration
			_update_objective("[color=yellow]%s![/color] Auto-towers firing at %.0f%% speed!" % [cmd_name, value * 100])

		"combo_boost":
			var value: int = int(effect.get("value", 10))
			combo += value
			_update_objective("[color=purple]%s![/color] +%d combo!" % [cmd_name, value])

		"cleave_next":
			var value: float = float(effect.get("value", 0.5))
			command_effects["cleave_next"] = value
			_update_objective("[color=red]%s![/color] Next attack hits ALL enemies!" % cmd_name)

		"execute":
			var threshold: float = float(effect.get("threshold", 0.3))
			if target_enemy_id >= 0:
				for i in range(active_enemies.size()):
					var enemy: Dictionary = active_enemies[i]
					if int(enemy.get("id", -1)) == target_enemy_id:
						var current_hp: int = int(enemy.get("hp", 0))
						var max_hp: int = int(enemy.get("max_hp", current_hp))
						if float(current_hp) / float(max_hp) <= threshold:
							enemy["hp"] = 0
							_update_objective("[color=red]%s![/color] Target executed!" % cmd_name)
							# Kill will be processed in next tick
						else:
							_update_objective("[color=yellow]%s![/color] Target HP too high (need below %.0f%%)." % [cmd_name, threshold * 100])
						break
			else:
				_update_objective("[color=yellow]No target for Execute.[/color]")

		"block_charges":
			var charges: int = int(effect.get("charges", 2))
			command_effects["block_charges"] = charges
			_update_objective("[color=cyan]%s![/color] Next %d enemies blocked!" % [cmd_name, charges])

		_:
			_update_objective("[color=yellow]Unknown command effect.[/color]")
			return

	# Set cooldown
	command_cooldowns[command_id] = cooldown

	# Track for quest progress
	_update_quest_progress("spells_used", 1)

func _init_quest_system() -> void:
	# Load quest state from profile or create new
	var saved_quests: Dictionary = TypingProfile.get_profile_value(profile, "quest_state", {})
	if saved_quests.is_empty():
		quest_state = SimQuests.create_quest_state()
	else:
		quest_state = SimQuests.deserialize(saved_quests)

	# Initialize session stats
	session_stats = {
		"kills": 0,
		"boss_kills": 0,
		"max_combo": 0,
		"waves": 0,
		"gold_earned": 0,
		"words_typed": 0,
		"perfect_waves": 0,
		"no_damage_wave": 0,
		"no_damage_day": 0,
		"fast_wave": 999,
		"spells_used": 0,
		"accuracy": 0,
		"days_survived": day,
		"total_kills": int(TypingProfile.get_profile_value(profile, "total_kills", 0))
	}

	# Check if daily quests need refresh (new day)
	var current_day: int = int(Time.get_unix_time_from_system() / 86400)
	if int(quest_state.get("last_daily_refresh", 0)) != current_day:
		quest_state["daily_quests"] = SimQuests.generate_daily_quests(current_day)
		quest_state["daily_progress"] = {}
		quest_state["last_daily_refresh"] = current_day
		_save_quest_state()

	# Check if weekly quests need refresh (new week)
	var current_week: int = int(Time.get_unix_time_from_system() / 604800)
	if int(quest_state.get("last_weekly_refresh", 0)) != current_week:
		quest_state["weekly_quests"] = SimQuests.generate_weekly_quests(current_week)
		quest_state["weekly_progress"] = {}
		quest_state["last_weekly_refresh"] = current_week
		_save_quest_state()

func _save_quest_state() -> void:
	TypingProfile.set_profile_value(profile, "quest_state", SimQuests.serialize(quest_state))
	TypingProfile.save_profile(profile)

func _update_quest_progress(stat_type: String, amount: int) -> void:
	# Update session stats
	if stat_type == "max_combo":
		session_stats["max_combo"] = max(int(session_stats.get("max_combo", 0)), amount)
	elif stat_type == "fast_wave":
		session_stats["fast_wave"] = min(int(session_stats.get("fast_wave", 999)), amount)
	elif stat_type == "accuracy":
		session_stats["accuracy"] = amount
	else:
		session_stats[stat_type] = int(session_stats.get(stat_type, 0)) + amount

	# Update daily quest progress
	var daily_progress: Dictionary = quest_state.get("daily_progress", {})
	if stat_type == "max_combo":
		daily_progress["max_combo"] = max(int(daily_progress.get("max_combo", 0)), amount)
	elif stat_type == "accuracy":
		daily_progress["accuracy"] = max(int(daily_progress.get("accuracy", 0)), amount)
	else:
		daily_progress[stat_type] = int(daily_progress.get(stat_type, 0)) + amount
	quest_state["daily_progress"] = daily_progress

	# Update weekly quest progress
	var weekly_progress: Dictionary = quest_state.get("weekly_progress", {})
	if stat_type == "max_combo":
		weekly_progress["max_combo"] = max(int(weekly_progress.get("max_combo", 0)), amount)
	else:
		weekly_progress[stat_type] = int(weekly_progress.get(stat_type, 0)) + amount
	quest_state["weekly_progress"] = weekly_progress

	# Update challenge progress
	var challenge_progress: Dictionary = quest_state.get("challenge_progress", {})
	if stat_type == "max_combo":
		challenge_progress["max_combo"] = max(int(challenge_progress.get("max_combo", 0)), amount)
	elif stat_type == "total_kills":
		challenge_progress["total_kills"] = int(challenge_progress.get("total_kills", 0)) + amount
	elif stat_type == "days_survived":
		challenge_progress["days_survived"] = max(int(challenge_progress.get("days_survived", 0)), amount)
	elif stat_type == "no_damage_day":
		challenge_progress["no_damage_day"] = int(challenge_progress.get("no_damage_day", 0)) + amount
	elif stat_type == "fast_wave":
		challenge_progress["fast_wave"] = min(int(challenge_progress.get("fast_wave", 999)), amount)
	quest_state["challenge_progress"] = challenge_progress

	_save_quest_state()

	# Check for newly completed quests
	_check_quest_completions()

func _check_quest_completions() -> void:
	# Check daily quests
	var daily_quests: Array = quest_state.get("daily_quests", [])
	var daily_progress: Dictionary = quest_state.get("daily_progress", {})
	for quest_id in daily_quests:
		if SimQuests.check_objective(quest_id, daily_progress):
			var quest: Dictionary = SimQuests.get_quest(quest_id)
			if not quest.is_empty():
				# Only notify once per quest
				var claimed: Array = quest_state.get("daily_claimed", [])
				if not quest_id in claimed:
					var notified: Array = quest_state.get("daily_notified", [])
					if not quest_id in notified:
						notified.append(quest_id)
						quest_state["daily_notified"] = notified
						_update_objective("[color=lime]Quest Complete![/color] %s - Type 'claim %s'" % [str(quest.get("name", "")), quest_id])

	# Check weekly quests
	var weekly_quests: Array = quest_state.get("weekly_quests", [])
	var weekly_progress: Dictionary = quest_state.get("weekly_progress", {})
	for quest_id in weekly_quests:
		if SimQuests.check_objective(quest_id, weekly_progress):
			var quest: Dictionary = SimQuests.get_quest(quest_id)
			if not quest.is_empty():
				var claimed: Array = quest_state.get("weekly_claimed", [])
				if not quest_id in claimed:
					var notified: Array = quest_state.get("weekly_notified", [])
					if not quest_id in notified:
						notified.append(quest_id)
						quest_state["weekly_notified"] = notified
						_update_objective("[color=lime]Weekly Quest Complete![/color] %s" % str(quest.get("name", "")))

func _show_quests() -> void:
	# Open quests panel
	_toggle_quests()

func _try_claim_quest(quest_id: String) -> void:
	var quest: Dictionary = SimQuests.get_quest(quest_id)
	if quest.is_empty():
		_update_objective("[color=red]Unknown quest '%s'[/color]" % quest_id)
		return

	var quest_type: String = str(quest.get("type", ""))
	var progress: Dictionary = {}
	var claimed_list: Array = []

	# Determine which progress/claimed list to use
	if quest_type == "daily":
		progress = quest_state.get("daily_progress", {})
		claimed_list = quest_state.get("daily_claimed", [])
		if not quest_id in quest_state.get("daily_quests", []):
			_update_objective("[color=red]Quest '%s' is not active today[/color]" % quest_id)
			return
	elif quest_type == "weekly":
		progress = quest_state.get("weekly_progress", {})
		claimed_list = quest_state.get("weekly_claimed", [])
		if not quest_id in quest_state.get("weekly_quests", []):
			_update_objective("[color=red]Quest '%s' is not active this week[/color]" % quest_id)
			return
	elif quest_type == "challenge":
		progress = quest_state.get("challenge_progress", {})
		claimed_list = quest_state.get("completed_challenges", [])
	else:
		_update_objective("[color=red]Invalid quest type[/color]")
		return

	# Check if already claimed
	if quest_id in claimed_list:
		_update_objective("[color=yellow]Quest already claimed![/color]")
		return

	# Check if complete
	if not SimQuests.check_objective(quest_id, progress):
		var pct: float = SimQuests.get_progress_percent(quest_id, progress)
		_update_objective("[color=yellow]Quest not complete! (%.0f%%)[/color]" % (pct * 100))
		return

	# Grant rewards
	var rewards: Dictionary = quest.get("rewards", {})
	var reward_text: Array[String] = []

	if int(rewards.get("gold", 0)) > 0:
		var gold_reward: int = int(rewards.get("gold", 0))
		gold += gold_reward
		state.gold = gold
		reward_text.append("+%d gold" % gold_reward)

	if int(rewards.get("xp", 0)) > 0:
		var xp_reward: int = int(rewards.get("xp", 0))
		var xp_result: Dictionary = TypingProfile.add_xp(profile, xp_reward)
		reward_text.append("+%d XP" % xp_reward)
		if int(xp_result.get("levels_gained", 0)) > 0:
			reward_text.append("LEVEL UP!")

	if rewards.has("item"):
		var item_id: String = str(rewards.get("item", ""))
		TypingProfile.add_to_inventory(profile, item_id)
		var item_name: String = SimItems.get_item_name(item_id)
		reward_text.append("+%s" % item_name)

	# Mark as claimed
	claimed_list.append(quest_id)
	if quest_type == "daily":
		quest_state["daily_claimed"] = claimed_list
	elif quest_type == "weekly":
		quest_state["weekly_claimed"] = claimed_list
	elif quest_type == "challenge":
		quest_state["completed_challenges"] = claimed_list

	_save_quest_state()
	TypingProfile.save_profile(profile)

	var quest_name: String = str(quest.get("name", quest_id))
	_update_objective("[color=lime]Claimed %s![/color] %s" % [quest_name, ", ".join(reward_text)])

func _update_log(lines: Array[String]) -> void:
	# Use word_display for multi-line info during planning
	if word_display:
		word_display.text = "\n".join(lines)

func _check_act_completion(completed_day: int) -> void:
	if not StoryManager.is_act_complete_day(completed_day):
		return

	var completion_info: Dictionary = StoryManager.get_act_completion_info(completed_day)
	if completion_info.is_empty():
		return

	var act_name: String = completion_info.get("act_name", "")
	var completion_text: String = completion_info.get("completion_text", "")
	var reward: String = completion_info.get("reward", "")

	# Award badge if there's a reward
	if not reward.is_empty():
		var badge_id: String = StoryManager.get_act_reward_id(reward)
		var newly_awarded: bool = TypingProfile.award_badge(profile, badge_id)
		if newly_awarded:
			TypingProfile.save_profile(profile)

	# Show completion dialogue
	if dialogue_box and not completion_text.is_empty():
		var lines: Array[String] = []
		lines.append("[color=lime]Act Complete: %s[/color]" % act_name)
		lines.append(completion_text)
		if not reward.is_empty():
			lines.append("[color=yellow]Reward: %s[/color]" % reward)
		dialogue_box.show_dialogue("Elder Lyra", lines)
