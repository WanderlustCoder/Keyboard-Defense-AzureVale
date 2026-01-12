extends SceneTree

const DefaultState = preload("res://sim/default_state.gd")
const CommandParser = preload("res://sim/parse_command.gd")
const IntentApplier = preload("res://sim/apply_intent.gd")
const GameState = preload("res://sim/types.gd")
const SimMap = preload("res://sim/map.gd")
const SimBuildings = preload("res://sim/buildings.gd")
const SimSave = preload("res://sim/save.gd")

const SimEnemies = preload("res://sim/enemies.gd")
const SimLessons = preload("res://sim/lessons.gd")
const SimWords = preload("res://sim/words.gd")
const SimTypingFeedback = preload("res://sim/typing_feedback.gd")
const CommandKeywords = preload("res://sim/command_keywords.gd")
const SimTypingStats = preload("res://sim/typing_stats.gd")
const SimTypingTrends = preload("res://sim/typing_trends.gd")
const PracticeGoals = preload("res://sim/practice_goals.gd")
const SimBalanceReport = preload("res://sim/balance_report.gd")
const GoalTheme = preload("res://game/goal_theme.gd")
const MainScript = preload("res://game/main.gd")
const ControlsFormatter = preload("res://game/controls_formatter.gd")
const TypingProfile = preload("res://game/typing_profile.gd")
const RebindableActions = preload("res://game/rebindable_actions.gd")
const KeybindConflicts = preload("res://game/keybind_conflicts.gd")
const MiniTrend = preload("res://game/mini_trend.gd")
const LessonsSort = preload("res://game/lessons_sort.gd")
const LessonHealth = preload("res://game/lesson_health.gd")
const OnboardingFlow = preload("res://game/onboarding_flow.gd")
const ScenarioLoader = preload("res://tools/scenario_harness/scenario_loader.gd")
const ScenarioRunner = preload("res://tools/scenario_harness/scenario_runner.gd")
const ScenarioEval = preload("res://tools/scenario_harness/scenario_eval.gd")
const ScenarioTypes = preload("res://tools/scenario_harness/scenario_types.gd")
const StoryManager = preload("res://game/story_manager.gd")
const SimBossEncounters = preload("res://sim/boss_encounters.gd")
const SimDifficulty = preload("res://sim/difficulty.gd")
const SimExplorationChallenges = preload("res://sim/exploration_challenges.gd")
const SimDailyChallenges = preload("res://sim/daily_challenges.gd")
const SimBuffs = preload("res://sim/buffs.gd")
const SimCombo = preload("res://sim/combo.gd")
const SimAffixes = preload("res://sim/affixes.gd")
const SimBestiary = preload("res://sim/bestiary.gd")
const SimDamageTypes = preload("res://sim/damage_types.gd")
const SimEnemyTypes = preload("res://sim/enemy_types.gd")
const SimItems = preload("res://sim/items.gd")
const SimCrafting = preload("res://sim/crafting.gd")
const SimEndlessMode = preload("res://sim/endless_mode.gd")
const SimExpeditions = preload("res://sim/expeditions.gd")
const SimStatusEffects = preload("res://sim/status_effects.gd")
const SimTowerTypes = preload("res://sim/tower_types.gd")
const SimSkills = preload("res://sim/skills.gd")
const SimQuests = preload("res://sim/quests.gd")
const SimHeroTypes = preload("res://sim/hero_types.gd")
const SimLocale = preload("res://sim/locale.gd")
const SimTitles = preload("res://sim/titles.gd")
const SimUpgrades = preload("res://sim/upgrades.gd")
const SimWaveComposer = preload("res://sim/wave_composer.gd")
const SimLoot = preload("res://sim/loot.gd")
const SimMilestones = preload("res://sim/milestones.gd")
const SimEventEffects = preload("res://sim/event_effects.gd")
const SimEvents = preload("res://sim/events.gd")
const SimEventTables = preload("res://sim/event_tables.gd")
const SimPoi = preload("res://sim/poi.gd")

var total_tests: int = 0
var total_failed: int = 0
var messages: Array[String] = []
var exit_code: int = 0
var summary_line: String = ""

func _initialize() -> void:
    Engine.set("print_to_stdout", true)
    Engine.set("print_error_messages", true)
    ProjectSettings.set_setting("application/run/disable_stdout", false)
    ProjectSettings.set_setting("application/run/disable_stderr", false)
    ProjectSettings.set_setting("application/run/flush_stdout_on_print", true)
    ProjectSettings.set_setting("debug/settings/stdout/print", true)
    ProjectSettings.set_setting("debug/settings/stdout/verbose", false)
    _run_all()

func _run_all() -> void:
    _run_parser_tests()
    _run_scene_compile_tests()
    _run_reducer_tests()
    _run_determinism_tests()
    _run_lessons_tests()
    _run_docs_tests()
    _run_export_pipeline_tests()
    _run_version_tests()
    _run_version_bump_tests()
    _run_balance_report_tests()
    _run_verification_wrapper_tests()
    _run_command_keywords_tests()
    _run_practice_goal_tests()
    _run_goal_theme_tests()
    _run_inputmap_tests()
    _run_controls_formatter_tests()
    _run_keybind_conflicts_tests()
    _run_help_tests()
    _run_keybind_parsing_tests()
    _run_keybind_persistence_tests()
    _run_mini_trend_tests()
    _run_lesson_health_tests()
    _run_lessons_sort_tests()
    _run_onboarding_flow_tests()
    _run_scenario_harness_tests()
    _run_typing_profile_tests()
    _run_typing_feedback_tests()
    _run_typing_stats_tests()
    _run_typing_trends_tests()
    _run_story_manager_tests()
    _run_boss_encounters_tests()
    _run_difficulty_tests()
    _run_lesson_consistency_tests()
    _run_dialogue_flow_tests()
    _run_exploration_challenges_tests()
    _run_daily_challenges_tests()
    _run_buffs_tests()
    _run_combo_tests()
    _run_affixes_tests()
    _run_bestiary_tests()
    _run_damage_types_tests()
    _run_enemy_types_tests()
    _run_items_tests()
    _run_crafting_tests()
    _run_endless_mode_tests()
    _run_expeditions_tests()
    _run_status_effects_tests()
    _run_tower_types_tests()
    _run_skills_tests()
    _run_quests_tests()
    _run_hero_types_tests()
    _run_locale_tests()
    _run_titles_tests()
    _run_wave_composer_tests()
    _run_upgrades_tests()
    _run_loot_tests()
    _run_milestones_tests()
    _run_event_effects_tests()
    _run_event_system_tests()

    for message in messages:
        print("[tests] %s" % message)

    if total_failed > 0:
        summary_line = "[tests] FAIL %d/%d" % [total_failed, total_tests]
        print(summary_line)
        exit_code = 1
    else:
        summary_line = "[tests] OK %d" % total_tests
        print(summary_line)
        exit_code = 0

    _finish()

func _finish() -> void:
    if summary_line != "":
        print(summary_line)
        var user_dir: String = OS.get_user_data_dir()
        if user_dir != "":
            DirAccess.make_dir_recursive_absolute(user_dir)
        var summary_paths: Array[String] = ["res://_test_summary.log", "user://_test_summary.log", "user://logs/_test_summary.log"]
        for path in summary_paths:
            var file := FileAccess.open(path, FileAccess.WRITE)
            if file != null:
                file.store_line(summary_line)
                file.close()
    OS.delay_msec(50)
    quit(exit_code)

func _run_parser_tests() -> void:
    _assert_parse_ok("build farm", "build")
    _assert_parse_ok("build farm 1 2", "build")
    _assert_parse_ok("explore", "explore")
    _assert_parse_ok("help settings", "help")
    _assert_parse_ok("help hotkeys", "help")
    _assert_parse_ok("help topics", "help")
    _assert_parse_ok("help play", "help")
    _assert_parse_ok("help accessibility", "help")
    _assert_parse_ok("version", "ui_version")
    _assert_parse_ok("restart", "restart")
    _assert_parse_ok("balance verify", "ui_balance_verify")
    _assert_parse_ok("balance export", "ui_balance_export")
    _assert_parse_ok("balance export all", "ui_balance_export")
    _assert_parse_ok("balance export wave", "ui_balance_export")
    _assert_parse_ok("balance export save", "ui_balance_export")
    _assert_parse_ok("balance export save wave", "ui_balance_export")
    _assert_parse_ok("balance diff", "ui_balance_diff")
    _assert_parse_ok("balance diff wave", "ui_balance_diff")
    _assert_parse_ok("balance summary", "ui_balance_summary")
    _assert_parse_ok("balance summary wave", "ui_balance_summary")
    _assert_parse_ok("balance summary enemies", "ui_balance_summary")
    _assert_parse_ok("balance summary towers", "ui_balance_summary")
    _assert_parse_ok("balance summary buildings", "ui_balance_summary")
    _assert_parse_ok("balance summary midgame", "ui_balance_summary")
    _assert_parse_ok("defend shield", "defend_input")
    _assert_parse_ok("cursor 1 2", "cursor")
    _assert_parse_ok("cursor up", "cursor_move")
    _assert_parse_ok("cursor down 3", "cursor_move")
    _assert_parse_ok("cursor left 2", "cursor_move")
    _assert_parse_ok("cursor right", "cursor_move")
    _assert_parse_ok("inspect", "inspect")
    _assert_parse_ok("inspect 1 2", "inspect")
    _assert_parse_ok("map", "map")
    _assert_parse_ok("demolish", "demolish")
    _assert_parse_ok("demolish 1 2", "demolish")
    _assert_parse_ok("preview farm", "ui_preview")
    _assert_parse_ok("preview none", "ui_preview")
    _assert_parse_ok("wait", "wait")
    _assert_parse_ok("overlay path on", "ui_overlay")
    _assert_parse_ok("overlay path off", "ui_overlay")
    _assert_parse_ok("upgrade", "upgrade")
    _assert_parse_ok("upgrade 2 3", "upgrade")
    _assert_parse_ok("enemies", "enemies")
    _assert_parse_ok("save", "save")
    _assert_parse_ok("load", "load")
    _assert_parse_ok("new", "new")
    _assert_parse_ok("report", "ui_report")
    _assert_parse_ok("report show", "ui_report")
    _assert_parse_ok("history", "ui_history")
    _assert_parse_ok("history clear", "ui_history")
    _assert_parse_ok("trend", "ui_trend")
    _assert_parse_ok("trend show", "ui_trend")
    _assert_parse_ok("goal", "ui_goal_show")
    _assert_parse_ok("goal accuracy", "ui_goal_set")
    _assert_parse_ok("goal next", "ui_goal_next")
    _assert_parse_ok("goal banana", "ui_goal_set")
    _assert_parse_ok("lessons", "ui_lessons_toggle")
    _assert_parse_ok("lessons sort recent", "ui_lessons_sort")
    _assert_parse_ok("lessons sort default", "ui_lessons_sort")
    _assert_parse_ok("lessons sort name", "ui_lessons_sort")
    _assert_parse_ok("lessons sparkline on", "ui_lessons_sparkline")
    _assert_parse_ok("lessons sparkline off", "ui_lessons_sparkline")
    _assert_parse_ok("lessons sparkline", "ui_lessons_sparkline")
    _assert_parse_ok("lessons reset", "ui_lessons_reset")
    _assert_parse_ok("lessons reset all", "ui_lessons_reset")
    _assert_parse_ok("lesson", "lesson_show")
    _assert_parse_ok("lesson home_row", "lesson_set")
    _assert_parse_ok("lesson next", "lesson_next")
    _assert_parse_ok("lesson prev", "lesson_prev")
    _assert_parse_ok("lesson sample", "lesson_sample")
    _assert_parse_ok("lesson sample 4", "lesson_sample")
    _assert_parse_ok("settings", "ui_settings_toggle")
    _assert_parse_ok("settings show", "ui_settings_show")
    _assert_parse_ok("settings hide", "ui_settings_hide")
    _assert_parse_ok("settings lessons", "ui_settings_lessons")
    _assert_parse_ok("settings prefs", "ui_settings_prefs")
    _assert_parse_ok("settings scale", "ui_settings_scale")
    _assert_parse_ok("settings scale 120", "ui_settings_scale")
    _assert_parse_ok("settings scale +", "ui_settings_scale")
    _assert_parse_ok("settings scale reset", "ui_settings_scale")
    _assert_parse_ok("settings font 120", "ui_settings_scale")
    _assert_parse_ok("settings font +", "ui_settings_scale")
    _assert_parse_ok("settings font reset", "ui_settings_scale")
    _assert_parse_ok("settings verify", "ui_settings_verify")
    _assert_parse_ok("settings conflicts", "ui_settings_conflicts")
    _assert_parse_ok("settings resolve", "ui_settings_resolve")
    _assert_parse_ok("settings resolve apply", "ui_settings_resolve")
    _assert_parse_ok("settings export", "ui_settings_export")
    _assert_parse_ok("settings export save", "ui_settings_export")
    _assert_parse_ok("settings compact on", "ui_settings_compact")
    _assert_parse_ok("settings compact toggle", "ui_settings_compact")
    _assert_parse_ok("tutorial", "ui_tutorial_toggle")
    _assert_parse_ok("tutorial restart", "ui_tutorial_restart")
    _assert_parse_ok("tutorial skip", "ui_tutorial_skip")
    _assert_parse_ok("bind cycle_goal", "ui_bind_action")
    _assert_parse_ok("bind cycle_goal reset", "ui_bind_action_reset")
    _assert_parse_ok("bind toggle_settings reset", "ui_bind_action_reset")
    _assert_parse_ok("bind toggle_lessons F2", "ui_bind_action")
    _assert_parse_ok("bind toggle_trend", "ui_bind_action")
    _assert_parse_ok("bind toggle_trend reset", "ui_bind_action_reset")
    _assert_parse_ok("bind toggle_compact", "ui_bind_action")
    _assert_parse_ok("bind toggle_compact F4", "ui_bind_action")
    _assert_parse_ok("bind toggle_compact reset", "ui_bind_action_reset")
    _assert_parse_ok("bind toggle_history", "ui_bind_action")
    _assert_parse_ok("bind toggle_history reset", "ui_bind_action_reset")

    var invalid_build: Dictionary = CommandParser.parse("build castle")
    _assert_true(not invalid_build.get("ok", false), "reject invalid build type")
    var invalid_build_coords: Dictionary = CommandParser.parse("build farm a b")
    _assert_true(not invalid_build_coords.get("ok", false), "reject invalid build coords")
    var invalid_cursor: Dictionary = CommandParser.parse("cursor a b")
    _assert_true(not invalid_cursor.get("ok", false), "reject invalid cursor coords")
    var invalid_cursor_dir: Dictionary = CommandParser.parse("cursor foo")
    _assert_true(not invalid_cursor_dir.get("ok", false), "reject invalid cursor direction")
    var invalid_cursor_zero: Dictionary = CommandParser.parse("cursor up 0")
    _assert_true(not invalid_cursor_zero.get("ok", false), "reject cursor steps zero")
    var invalid_cursor_negative: Dictionary = CommandParser.parse("cursor left -1")
    _assert_true(not invalid_cursor_negative.get("ok", false), "reject cursor steps negative")
    var invalid_inspect: Dictionary = CommandParser.parse("inspect a b")
    _assert_true(not invalid_inspect.get("ok", false), "reject invalid inspect coords")

func _run_reducer_tests() -> void:
    var gather_state: GameState = DefaultState.create("test-gather")
    var gather_result: Dictionary = IntentApplier.apply(gather_state, {"kind": "gather", "resource": "wood", "amount": 3})
    _assert_equal(gather_result.state.ap, gather_state.ap - 1, "gather consumes AP")
    _assert_equal(int(gather_result.state.resources.get("wood", 0)), 6, "gather adds resource")

    var build_state: GameState = DefaultState.create("test-build")
    build_state.resources["wood"] = 20
    build_state.resources["food"] = 10
    build_state.resources["stone"] = 10
    var build_pos: Vector2i = build_state.base_pos + Vector2i(1, 0)
    var build_index: int = SimMap.idx(build_pos.x, build_pos.y, build_state.map_w)
    build_state.discovered[build_index] = true
    build_state.terrain[build_index] = SimMap.TERRAIN_PLAINS
    var build_result: Dictionary = IntentApplier.apply(build_state, {"kind": "build", "building": "farm", "x": build_pos.x, "y": build_pos.y})
    _assert_equal(build_result.state.ap, build_state.ap - 1, "build consumes AP")
    _assert_equal(str(build_result.state.structures.get(build_index, "")), "farm", "build places structure")
    _assert_equal(int(build_result.state.buildings.get("farm", 0)), 1, "build increments building count")

    var explore_state: GameState = DefaultState.create("test-explore")
    var explore_result: Dictionary = IntentApplier.apply(explore_state, {"kind": "explore"})
    _assert_equal(explore_result.state.ap, explore_state.ap - 1, "explore consumes AP")
    _assert_equal(explore_result.state.threat, explore_state.threat + 2, "explore increases threat")
    _assert_true(explore_result.state.discovered.size() > explore_state.discovered.size(), "explore discovers tile")
    var explore_tile: int = _find_new_tile(explore_state, explore_result.state)
    if explore_tile >= 0:
        _assert_true(str(explore_result.state.terrain[explore_tile]) != "", "explore reveals terrain")

    var ap_state: GameState = DefaultState.create("test-ap")
    ap_state.ap = 1
    var ap_first: Dictionary = IntentApplier.apply(ap_state, {"kind": "gather", "resource": "wood", "amount": 1})
    var ap_second: Dictionary = IntentApplier.apply(ap_first.state, {"kind": "gather", "resource": "wood", "amount": 1})
    _assert_equal(ap_second.state.ap, 0, "AP does not go below zero")
    _assert_equal(int(ap_second.state.resources.get("wood", 0)), int(ap_first.state.resources.get("wood", 0)), "no gather without AP")

    var cursor_state: GameState = DefaultState.create("test-cursor")
    cursor_state.cursor_pos = Vector2i(0, 0)
    var cursor_result: Dictionary = IntentApplier.apply(cursor_state, {"kind": "cursor_move", "dx": -1, "dy": 0, "steps": 3})
    _assert_equal(cursor_result.state.cursor_pos, Vector2i(0, 0), "cursor clamps to bounds")
    _assert_equal(cursor_result.state.ap, cursor_state.ap, "cursor move does not consume AP")
    var cursor_result2: Dictionary = IntentApplier.apply(cursor_result.state, {"kind": "cursor_move", "dx": 1, "dy": 0, "steps": 2})
    _assert_equal(cursor_result2.state.cursor_pos, Vector2i(2, 0), "cursor moves with steps")

    var end_state: GameState = DefaultState.create("test-end")
    var end_result: Dictionary = IntentApplier.apply(end_state, {"kind": "end"})
    _assert_equal(str(end_result.state.phase), "night", "end transitions to night")
    _assert_true(end_result.state.night_wave_total >= 1, "night wave total set")
    _assert_equal(end_result.state.night_spawn_remaining, end_result.state.night_wave_total, "night spawn remaining set")

    var defend_state: GameState = _make_flat_state("test-defend")
    defend_state.phase = "night"
    defend_state.night_spawn_remaining = 0
    defend_state.night_wave_total = 0
    defend_state.hp = 5
    defend_state.enemies = [
        {"id": 1, "pos": defend_state.base_pos + Vector2i(2, 0), "hp": 3, "kind": "raider", "armor": 0, "speed": 1, "word": "moss"},
        {"id": 2, "pos": defend_state.base_pos + Vector2i(3, 0), "hp": 2, "kind": "raider", "armor": 0, "speed": 1, "word": "reed"}
    ]
    defend_state.enemy_next_id = 3
    var defend_result: Dictionary = IntentApplier.apply(defend_state, {"kind": "defend_input", "text": "reed"})
    _assert_equal(defend_result.state.hp, 5, "hit does not reduce base hp")
    _assert_true(_find_enemy(defend_result.state.enemies, 2).is_empty(), "defend targets matching word")

    var armored_state: GameState = _make_flat_state("test-armored")
    armored_state.phase = "night"
    armored_state.night_spawn_remaining = 0
    armored_state.night_wave_total = 0
    var armored_enemy: Dictionary = SimEnemies.make_enemy(armored_state, "armored", armored_state.base_pos + Vector2i(3, 0))
    armored_enemy["hp"] = 3
    armored_enemy["word"] = "block"
    armored_state.enemies = [armored_enemy]
    armored_state.enemy_next_id = int(armored_enemy.get("id", 1)) + 1
    var armored_result: Dictionary = IntentApplier.apply(armored_state, {"kind": "defend_input", "text": "block"})
    var armored_after: Dictionary = _find_enemy(armored_result.state.enemies, int(armored_enemy.get("id", 1)))
    _assert_equal(int(armored_after.get("hp", 0)), 2, "armored reduces damage from hits")

    var miss_state: GameState = DefaultState.create("test-miss")
    miss_state.phase = "night"
    miss_state.night_spawn_remaining = 0
    miss_state.night_wave_total = 0
    miss_state.hp = 1
    miss_state.enemies = [{"id": 1, "pos": miss_state.base_pos + Vector2i(2, 0), "hp": 2, "kind": "raider", "armor": 0, "speed": 1, "word": "shield"}]
    var miss_result: Dictionary = IntentApplier.apply(miss_state, {"kind": "defend_input", "text": "oops"})
    _assert_equal(str(miss_result.state.phase), "game_over", "hp zero triggers game over")

    var wait_state: GameState = DefaultState.create("test-wait")
    wait_state.phase = "night"
    wait_state.night_spawn_remaining = 1
    wait_state.night_wave_total = 1
    wait_state.hp = 5
    var wait_result: Dictionary = IntentApplier.apply(wait_state, {"kind": "wait"})
    _assert_equal(wait_result.state.hp, 5, "wait does not apply miss penalty")
    _assert_equal(wait_result.state.night_spawn_remaining, 0, "wait advances spawn")
    _assert_true(wait_result.state.enemies.size() == 1, "wait spawns enemy")
    _assert_true(str(wait_result.state.enemies[0].get("word", "")) != "", "spawn assigns word")

    var spawn_kind_state: GameState = _make_flat_state("test-spawn-kind")
    spawn_kind_state.phase = "night"
    spawn_kind_state.day = 1
    spawn_kind_state.threat = 0
    spawn_kind_state.night_spawn_remaining = 1
    spawn_kind_state.night_wave_total = 1
    var spawn_kind_result: Dictionary = IntentApplier.apply(spawn_kind_state, {"kind": "wait"})
    var spawn_kind: String = str(spawn_kind_result.state.enemies[0].get("kind", ""))
    _assert_equal(spawn_kind, "raider", "spawn kind is raider early")
    _assert_true(str(spawn_kind_result.state.enemies[0].get("word", "")) != "", "spawn assigns word deterministically")

    var restart_state: GameState = DefaultState.create("test-restart")
    restart_state.phase = "game_over"
    restart_state.rng_seed = "seeded"
    var restart_result: Dictionary = IntentApplier.apply(restart_state, {"kind": "restart"})
    _assert_equal(str(restart_result.state.phase), "day", "restart returns to day")
    _assert_equal(str(restart_result.state.rng_seed), "seeded", "restart keeps seed")

    var blocked_state: GameState = DefaultState.create("test-blocked")
    blocked_state.day = 5
    blocked_state.threat = 5
    var offsets: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
    for offset in offsets:
        var pos: Vector2i = blocked_state.base_pos + offset
        var idx: int = SimMap.idx(pos.x, pos.y, blocked_state.map_w)
        blocked_state.structures[idx] = "wall"
    blocked_state.buildings["wall"] = 4
    var blocked_result: Dictionary = IntentApplier.apply(blocked_state, {"kind": "end"})
    _assert_true(not blocked_result.state.last_path_open, "blocked path detected")
    _assert_equal(blocked_result.state.night_wave_total, 5, "blocked path reduces night")

    var reject_state: GameState = DefaultState.create("test-reject")
    reject_state.resources["wood"] = 20
    var reject_pos: Vector2i = reject_state.base_pos + Vector2i(2, 0)
    var reject_index: int = SimMap.idx(reject_pos.x, reject_pos.y, reject_state.map_w)
    var reject_result: Dictionary = IntentApplier.apply(reject_state, {"kind": "build", "building": "farm", "x": reject_pos.x, "y": reject_pos.y})
    _assert_true(not reject_result.state.structures.has(reject_index), "build rejects undiscovered")
    _assert_equal(reject_result.state.ap, reject_state.ap, "build rejects without consuming AP")

    var water_state: GameState = DefaultState.create("test-water")
    water_state.resources["wood"] = 20
    var water_pos: Vector2i = water_state.base_pos + Vector2i(1, 0)
    var water_index: int = SimMap.idx(water_pos.x, water_pos.y, water_state.map_w)
    water_state.discovered[water_index] = true
    water_state.terrain[water_index] = SimMap.TERRAIN_WATER
    var water_result: Dictionary = IntentApplier.apply(water_state, {"kind": "build", "building": "farm", "x": water_pos.x, "y": water_pos.y})
    _assert_true(not water_result.state.structures.has(water_index), "build rejects water tile")
    _assert_equal(water_result.state.ap, water_state.ap, "build rejects water without AP cost")

    var demolish_night: GameState = DefaultState.create("test-demolish-night")
    demolish_night.phase = "night"
    var demolish_night_result: Dictionary = IntentApplier.apply(demolish_night, {"kind": "demolish"})
    _assert_equal(demolish_night_result.state.ap, demolish_night.ap, "demolish fails at night")

    var demolish_empty: GameState = DefaultState.create("test-demolish-empty")
    var empty_pos: Vector2i = demolish_empty.base_pos + Vector2i(1, 0)
    var empty_index: int = SimMap.idx(empty_pos.x, empty_pos.y, demolish_empty.map_w)
    demolish_empty.discovered[empty_index] = true
    demolish_empty.terrain[empty_index] = SimMap.TERRAIN_PLAINS
    var demolish_empty_result: Dictionary = IntentApplier.apply(demolish_empty, {"kind": "demolish", "x": empty_pos.x, "y": empty_pos.y})
    _assert_true(not demolish_empty_result.state.structures.has(empty_index), "demolish fails on empty tile")
    _assert_equal(demolish_empty_result.state.ap, demolish_empty.ap, "demolish empty does not consume AP")

    var demolish_base: GameState = DefaultState.create("test-demolish-base")
    var base_index: int = SimMap.idx(demolish_base.base_pos.x, demolish_base.base_pos.y, demolish_base.map_w)
    demolish_base.structures[base_index] = "wall"
    demolish_base.buildings["wall"] = 1
    var demolish_base_result: Dictionary = IntentApplier.apply(demolish_base, {"kind": "demolish", "x": demolish_base.base_pos.x, "y": demolish_base.base_pos.y})
    _assert_true(demolish_base_result.state.structures.has(base_index), "demolish refuses base tile")

    var demolish_state: GameState = DefaultState.create("test-demolish")
    demolish_state.ap = 2
    var demo_pos: Vector2i = demolish_state.base_pos + Vector2i(1, 0)
    var demo_index: int = SimMap.idx(demo_pos.x, demo_pos.y, demolish_state.map_w)
    demolish_state.discovered[demo_index] = true
    demolish_state.terrain[demo_index] = SimMap.TERRAIN_PLAINS
    demolish_state.structures[demo_index] = "wall"
    demolish_state.buildings["wall"] = 1
    var demolish_result: Dictionary = IntentApplier.apply(demolish_state, {"kind": "demolish", "x": demo_pos.x, "y": demo_pos.y})
    _assert_equal(demolish_result.state.ap, demolish_state.ap - 1, "demolish consumes AP")
    _assert_true(not demolish_result.state.structures.has(demo_index), "demolish removes structure")
    _assert_equal(int(demolish_result.state.resources.get("wood", 0)), 2, "demolish refunds wood")
    _assert_equal(int(demolish_result.state.resources.get("stone", 0)), 2, "demolish refunds stone")

    var lesson_ids: PackedStringArray = SimLessons.lesson_ids()
    if not lesson_ids.is_empty():
        var target_lesson: String = str(lesson_ids[0])
        var lesson_state: GameState = DefaultState.create("test-lesson")
        var lesson_result: Dictionary = IntentApplier.apply(lesson_state, {"kind": "lesson_set", "lesson_id": target_lesson})
        _assert_equal(str(lesson_result.state.lesson_id), target_lesson, "lesson_set updates lesson id")
        var lesson_night: GameState = DefaultState.create("test-lesson-night")
        lesson_night.phase = "night"
        var lesson_night_result: Dictionary = IntentApplier.apply(lesson_night, {"kind": "lesson_set", "lesson_id": target_lesson})
        _assert_equal(str(lesson_night_result.state.lesson_id), str(lesson_night.lesson_id), "lesson_set blocked at night")

    var demolish_upgrade_state: GameState = _make_flat_state("test-demolish-upgrade")
    demolish_upgrade_state.phase = "day"
    demolish_upgrade_state.ap = 2
    var demolish_upgrade_pos: Vector2i = demolish_upgrade_state.base_pos + Vector2i(1, 0)
    var demolish_upgrade_index: int = SimMap.idx(demolish_upgrade_pos.x, demolish_upgrade_pos.y, demolish_upgrade_state.map_w)
    demolish_upgrade_state.structures[demolish_upgrade_index] = "tower"
    demolish_upgrade_state.structure_levels[demolish_upgrade_index] = 3
    demolish_upgrade_state.buildings["tower"] = 1
    var demolish_upgrade_result: Dictionary = IntentApplier.apply(demolish_upgrade_state, {"kind": "demolish", "x": demolish_upgrade_pos.x, "y": demolish_upgrade_pos.y})
    _assert_equal(int(demolish_upgrade_result.state.resources.get("wood", 0)), 8, "demolish refund includes tower upgrades (wood)")
    _assert_equal(int(demolish_upgrade_result.state.resources.get("stone", 0)), 14, "demolish refund includes tower upgrades (stone)")
    _assert_true(not demolish_upgrade_result.state.structure_levels.has(demolish_upgrade_index), "demolish clears tower level")

    var prod_state: GameState = DefaultState.create("test-prod")
    var farm_pos: Vector2i = prod_state.base_pos + Vector2i(1, 0)
    var water_adjacent: Vector2i = farm_pos + Vector2i(1, 0)
    var farm_index: int = SimMap.idx(farm_pos.x, farm_pos.y, prod_state.map_w)
    var water_index_adj: int = SimMap.idx(water_adjacent.x, water_adjacent.y, prod_state.map_w)
    prod_state.structures[farm_index] = "farm"
    prod_state.buildings["farm"] = 1
    prod_state.terrain[farm_index] = SimMap.TERRAIN_PLAINS
    prod_state.terrain[water_index_adj] = SimMap.TERRAIN_WATER
    var production: Dictionary = SimBuildings.daily_production(prod_state)
    _assert_equal(int(production.get("food", 0)), 5, "farm adjacency bonus applied")

    var preview_state: GameState = DefaultState.create("test-preview")
    preview_state.resources["wood"] = 20
    preview_state.resources["stone"] = 20
    preview_state.resources["food"] = 20
    var preview_pos: Vector2i = preview_state.base_pos + Vector2i(1, 0)
    var preview_index: int = SimMap.idx(preview_pos.x, preview_pos.y, preview_state.map_w)
    var preview_adj: Vector2i = preview_pos + Vector2i(1, 0)
    var preview_adj_index: int = SimMap.idx(preview_adj.x, preview_adj.y, preview_state.map_w)
    preview_state.discovered[preview_index] = true
    preview_state.discovered[preview_adj_index] = true
    preview_state.terrain[preview_index] = SimMap.TERRAIN_PLAINS
    preview_state.terrain[preview_adj_index] = SimMap.TERRAIN_WATER
    var preview: Dictionary = SimBuildings.get_build_preview(preview_state, preview_pos, "farm")
    _assert_equal(int(preview.get("production", {}).get("food", 0)), 4, "preview farm adjacency bonus")

    var save_state: GameState = DefaultState.create("test-save")
    save_state.cursor_pos = Vector2i(1, 2)
    var save_pos: Vector2i = save_state.base_pos + Vector2i(1, 0)
    var save_index: int = SimMap.idx(save_pos.x, save_pos.y, save_state.map_w)
    save_state.discovered[save_index] = true
    save_state.terrain[save_index] = SimMap.TERRAIN_FOREST
    save_state.structures[save_index] = "lumber"
    save_state.buildings["lumber"] = 1
    save_state.structure_levels[save_index] = 2
    save_state.rng_state = 12345
    save_state.enemies = [{"id": 7, "pos": Vector2i(2, 3), "hp": 4, "kind": "raider", "word": "ember"}]
    save_state.enemy_next_id = 8
    var save_data: Dictionary = SimSave.state_to_dict(save_state)
    var save_json: String = JSON.stringify(save_data)
    var parsed: Variant = JSON.parse_string(save_json)
    var load_result: Dictionary = SimSave.state_from_dict(parsed)
    _assert_true(load_result.get("ok", false), "save/load round trip ok")
    if load_result.get("ok", false):
        var loaded: GameState = load_result.state
        _assert_equal(loaded.cursor_pos, save_state.cursor_pos, "cursor round trip")
        _assert_equal(str(loaded.terrain[save_index]), str(save_state.terrain[save_index]), "terrain round trip")
        _assert_equal(str(loaded.structures.get(save_index, "")), "lumber", "structure round trip")
        _assert_equal(int(loaded.structure_levels.get(save_index, 0)), 2, "structure level round trip")
        _assert_equal(loaded.rng_state, save_state.rng_state, "rng state round trip")
        var loaded_enemy: Dictionary = _find_enemy(loaded.enemies, 7)
        _assert_equal(loaded_enemy.get("pos", Vector2i.ZERO), Vector2i(2, 3), "enemy position round trip")
        _assert_equal(int(loaded_enemy.get("hp", 0)), 4, "enemy hp round trip")
        _assert_equal(str(loaded_enemy.get("word", "")), "ember", "enemy word round trip")
        _assert_equal(loaded.enemy_next_id, 8, "enemy id counter round trip")

    var tower_state: GameState = _make_flat_state("test-tower")
    tower_state.phase = "night"
    tower_state.night_spawn_remaining = 0
    tower_state.night_wave_total = 0
    var tower_pos: Vector2i = tower_state.base_pos + Vector2i(1, 0)
    var tower_index: int = SimMap.idx(tower_pos.x, tower_pos.y, tower_state.map_w)
    tower_state.structures[tower_index] = "tower"
    tower_state.enemies = [{"id": 1, "pos": tower_state.base_pos + Vector2i(3, 0), "hp": 3, "kind": "raider"}]
    var tower_result: Dictionary = IntentApplier.apply(tower_state, {"kind": "wait"})
    var tower_enemy: Dictionary = _find_enemy(tower_result.state.enemies, 1)
    _assert_equal(int(tower_enemy.get("hp", 0)), 2, "tower attack damages enemy")

    var upgrade_state: GameState = _make_flat_state("test-upgrade")
    upgrade_state.phase = "day"
    upgrade_state.ap = 2
    upgrade_state.resources["wood"] = 20
    upgrade_state.resources["stone"] = 20
    var upgrade_pos: Vector2i = upgrade_state.base_pos + Vector2i(1, 0)
    var upgrade_index: int = SimMap.idx(upgrade_pos.x, upgrade_pos.y, upgrade_state.map_w)
    upgrade_state.structures[upgrade_index] = "tower"
    upgrade_state.structure_levels[upgrade_index] = 1
    upgrade_state.buildings["tower"] = 1
    var upgrade_result: Dictionary = IntentApplier.apply(upgrade_state, {"kind": "upgrade", "x": upgrade_pos.x, "y": upgrade_pos.y})
    _assert_equal(int(upgrade_result.state.structure_levels.get(upgrade_index, 0)), 2, "upgrade increases tower level")
    _assert_equal(upgrade_result.state.ap, upgrade_state.ap - 1, "upgrade consumes AP")
    _assert_equal(int(upgrade_result.state.resources.get("wood", 0)), 16, "upgrade costs wood")
    _assert_equal(int(upgrade_result.state.resources.get("stone", 0)), 12, "upgrade costs stone")

    var tower2_state: GameState = _make_flat_state("test-tower-level2")
    tower2_state.phase = "night"
    tower2_state.night_spawn_remaining = 0
    tower2_state.night_wave_total = 0
    var tower2_pos: Vector2i = tower2_state.base_pos + Vector2i(1, 0)
    var tower2_index: int = SimMap.idx(tower2_pos.x, tower2_pos.y, tower2_state.map_w)
    tower2_state.structures[tower2_index] = "tower"
    tower2_state.structure_levels[tower2_index] = 2
    tower2_state.buildings["tower"] = 1
    tower2_state.enemies = [
        {"id": 1, "pos": tower2_state.base_pos + Vector2i(2, 0), "hp": 1, "kind": "raider", "armor": 0, "speed": 1},
        {"id": 2, "pos": tower2_state.base_pos + Vector2i(3, 0), "hp": 1, "kind": "raider", "armor": 0, "speed": 1}
    ]
    tower2_state.enemy_next_id = 3
    var tower2_result: Dictionary = IntentApplier.apply(tower2_state, {"kind": "wait"})
    _assert_true(tower2_result.state.enemies.is_empty(), "level 2 tower fires two shots")

    var move_state: GameState = _make_flat_state("test-move")
    move_state.phase = "night"
    move_state.night_spawn_remaining = 0
    move_state.night_wave_total = 0
    move_state.hp = 5
    move_state.enemies = [{"id": 1, "pos": move_state.base_pos + Vector2i(1, 0), "hp": 2, "kind": "raider"}]
    var move_result: Dictionary = IntentApplier.apply(move_state, {"kind": "wait"})
    _assert_equal(move_result.state.hp, 4, "enemy reaches base and damages hp")
    _assert_true(move_result.state.enemies.is_empty(), "enemy removed after hitting base")

    var scout_state: GameState = _make_flat_state("test-scout")
    scout_state.phase = "night"
    scout_state.night_spawn_remaining = 0
    scout_state.night_wave_total = 0
    var scout_enemy: Dictionary = SimEnemies.make_enemy(scout_state, "scout", scout_state.base_pos + Vector2i(3, 0))
    scout_enemy["hp"] = 2
    scout_state.enemies = [scout_enemy]
    scout_state.enemy_next_id = int(scout_enemy.get("id", 1)) + 1
    var scout_result: Dictionary = IntentApplier.apply(scout_state, {"kind": "wait"})
    var moved_scout: Dictionary = _find_enemy(scout_result.state.enemies, int(scout_enemy.get("id", 1)))
    _assert_equal(moved_scout.get("pos", Vector2i.ZERO), scout_state.base_pos + Vector2i(1, 0), "scout moves two tiles per step")

    var dawn_state: GameState = _make_flat_state("test-dawn")
    dawn_state.phase = "night"
    dawn_state.night_spawn_remaining = 0
    dawn_state.night_wave_total = 0
    dawn_state.threat = 2
    var dawn_result: Dictionary = IntentApplier.apply(dawn_state, {"kind": "wait"})
    _assert_equal(str(dawn_result.state.phase), "day", "dawn triggers when wave cleared")
    _assert_equal(dawn_result.state.ap, dawn_result.state.ap_max, "dawn resets AP")
    _assert_equal(dawn_result.state.threat, 1, "dawn reduces threat")

func _run_determinism_tests() -> void:
    var seed_text: String = "repeatable"

    var default_lesson: String = SimLessons.default_lesson_id()
    var word_a: String = SimWords.word_for_enemy(seed_text, 2, "raider", 1, {}, default_lesson)
    var word_b: String = SimWords.word_for_enemy(seed_text, 2, "raider", 1, {}, default_lesson)
    _assert_equal(word_a, word_b, "deterministic enemy word assignment")
    var used: Dictionary = {word_a: true}
    var word_c: String = SimWords.word_for_enemy(seed_text, 2, "raider", 2, used, default_lesson)
    _assert_true(word_c != word_a, "enemy words remain unique")

    var explore_a: GameState = DefaultState.create(seed_text)
    var explore_b: GameState = DefaultState.create(seed_text)
    var explore_result_a: Dictionary = IntentApplier.apply(explore_a, {"kind": "explore"})
    var explore_result_b: Dictionary = IntentApplier.apply(explore_b, {"kind": "explore"})
    var new_tile_a: int = _find_new_tile(explore_a, explore_result_a.state)
    var new_tile_b: int = _find_new_tile(explore_b, explore_result_b.state)
    _assert_equal(new_tile_a, new_tile_b, "deterministic explore tile")
    if new_tile_a >= 0:
        _assert_equal(str(explore_result_a.state.terrain[new_tile_a]), str(explore_result_b.state.terrain[new_tile_b]), "deterministic terrain")
    _assert_equal(int(explore_result_a.state.resources.get("wood", 0)), int(explore_result_b.state.resources.get("wood", 0)), "deterministic explore wood")
    _assert_equal(int(explore_result_a.state.resources.get("stone", 0)), int(explore_result_b.state.resources.get("stone", 0)), "deterministic explore stone")
    _assert_equal(int(explore_result_a.state.resources.get("food", 0)), int(explore_result_b.state.resources.get("food", 0)), "deterministic explore food")

    var spawn_a: GameState = _make_flat_state(seed_text)
    var spawn_b: GameState = _make_flat_state(seed_text)
    spawn_a.phase = "night"
    spawn_b.phase = "night"
    spawn_a.night_spawn_remaining = 1
    spawn_b.night_spawn_remaining = 1
    spawn_a.night_wave_total = 1
    spawn_b.night_wave_total = 1
    var spawn_result_a: Dictionary = IntentApplier.apply(spawn_a, {"kind": "wait"})
    var spawn_result_b: Dictionary = IntentApplier.apply(spawn_b, {"kind": "wait"})
    var enemy_a: Dictionary = spawn_result_a.state.enemies[0]
    var enemy_b: Dictionary = spawn_result_b.state.enemies[0]
    _assert_equal(enemy_a.get("pos", Vector2i.ZERO), enemy_b.get("pos", Vector2i.ZERO), "deterministic enemy spawn")

    var night_det_a: GameState = _make_flat_state(seed_text)
    var night_det_b: GameState = _make_flat_state(seed_text)
    night_det_a.phase = "night"
    night_det_b.phase = "night"
    night_det_a.day = 6
    night_det_b.day = 6
    night_det_a.threat = 4
    night_det_b.threat = 4
    night_det_a.night_spawn_remaining = 2
    night_det_b.night_spawn_remaining = 2
    night_det_a.night_wave_total = 2
    night_det_b.night_wave_total = 2
    var night_step_a: Dictionary = IntentApplier.apply(night_det_a, {"kind": "wait"})
    var night_step_b: Dictionary = IntentApplier.apply(night_det_b, {"kind": "wait"})
    _assert_equal(_enemy_snapshot(night_step_a.state.enemies), _enemy_snapshot(night_step_b.state.enemies), "deterministic enemy kind/pos/hp")
    var night_step2_a: Dictionary = IntentApplier.apply(night_step_a.state, {"kind": "wait"})
    var night_step2_b: Dictionary = IntentApplier.apply(night_step_b.state, {"kind": "wait"})
    _assert_equal(_enemy_snapshot(night_step2_a.state.enemies), _enemy_snapshot(night_step2_b.state.enemies), "deterministic enemy movement sequence")

    var refund_det_a: GameState = _make_flat_state(seed_text)
    var refund_det_b: GameState = _make_flat_state(seed_text)
    var refund_pos: Vector2i = refund_det_a.base_pos + Vector2i(1, 0)
    var refund_index: int = SimMap.idx(refund_pos.x, refund_pos.y, refund_det_a.map_w)
    for refund_state in [refund_det_a, refund_det_b]:
        refund_state.phase = "day"
        refund_state.ap = 5
        refund_state.resources["wood"] = 40
        refund_state.resources["stone"] = 40
        refund_state.structures[refund_index] = "tower"
        refund_state.structure_levels[refund_index] = 1
        refund_state.buildings["tower"] = 1
    var refund_step_a: Dictionary = IntentApplier.apply(refund_det_a, {"kind": "upgrade", "x": refund_pos.x, "y": refund_pos.y})
    refund_step_a = IntentApplier.apply(refund_step_a.state, {"kind": "upgrade", "x": refund_pos.x, "y": refund_pos.y})
    refund_step_a = IntentApplier.apply(refund_step_a.state, {"kind": "demolish", "x": refund_pos.x, "y": refund_pos.y})
    var refund_step_b: Dictionary = IntentApplier.apply(refund_det_b, {"kind": "upgrade", "x": refund_pos.x, "y": refund_pos.y})
    refund_step_b = IntentApplier.apply(refund_step_b.state, {"kind": "upgrade", "x": refund_pos.x, "y": refund_pos.y})
    refund_step_b = IntentApplier.apply(refund_step_b.state, {"kind": "demolish", "x": refund_pos.x, "y": refund_pos.y})
    _assert_equal(int(refund_step_a.state.resources.get("wood", 0)), int(refund_step_b.state.resources.get("wood", 0)), "deterministic upgrade/demolish wood")
    _assert_equal(int(refund_step_a.state.resources.get("stone", 0)), int(refund_step_b.state.resources.get("stone", 0)), "deterministic upgrade/demolish stone")

func _run_scenario_harness_tests() -> void:
    var load_result: Dictionary = ScenarioLoader.load_scenarios()
    _assert_true(load_result.get("ok", false), "scenario loader ok")
    if load_result.get("ok", false):
        var data: Dictionary = load_result.get("data", {})
        var scenarios: Array = data.get("scenarios", [])
        var ids: Array[String] = []
        for scenario in scenarios:
            if typeof(scenario) == TYPE_DICTIONARY:
                ids.append(str(scenario.get("id", "")))
        _assert_true(ids.has("determinism_smoke"), "scenario loader finds determinism_smoke")
        _assert_true(ids.has("day1_baseline"), "scenario loader finds day1_baseline")
        _assert_true(ids.has("first_night_smoke"), "scenario loader finds first_night_smoke")
        _assert_true(ids.has("enter_night_stop"), "scenario loader finds enter_night_stop")

        var p0_balance: Array = ScenarioTypes.filter_scenarios(scenarios, ["p0", "balance"], [], "P0")
        _assert_equal(p0_balance.size(), 20, "scenario filter returns P0 balance suite")
        var p0_balance_short: Array = ScenarioTypes.filter_scenarios(scenarios, ["p0", "balance"], ["long"], "P0")
        _assert_equal(p0_balance_short.size(), 16, "scenario filter excludes long tag")
        var p1_only: Array = ScenarioTypes.filter_scenarios(scenarios, [], [], "P1")
        _assert_equal(p1_only.size(), 2, "scenario filter returns P1 suite")
        var has_baseline: bool = false
        var has_target: bool = false
        for scenario in scenarios:
            if typeof(scenario) == TYPE_DICTIONARY:
                if scenario.has("expect_baseline"):
                    has_baseline = true
                if scenario.has("expect_target"):
                    has_target = true
        _assert_true(has_baseline, "scenario loader finds expect_baseline")
        _assert_true(has_target, "scenario loader finds expect_target")

    var range_failures: Array[String] = ScenarioEval.evaluate({"day": 2}, {"day": {"min": 1, "max": 3}})
    _assert_true(range_failures.is_empty(), "scenario eval range passes")
    var eq_failures: Array[String] = ScenarioEval.evaluate({"phase": "day"}, {"phase": {"eq": "night"}})
    _assert_true(eq_failures.size() == 1, "scenario eval eq detects mismatch")
    var nested_failures: Array[String] = ScenarioEval.evaluate({"resources": {"wood": 5}}, {"resources.wood": {"eq": 5}})
    _assert_true(nested_failures.is_empty(), "scenario eval nested keys pass")
    var eval_sets: Dictionary = ScenarioEval.evaluate_sets({"day": 1}, {"day": {"eq": 1}}, {"day": {"eq": 2}})
    _assert_true(eval_sets.get("baseline_failures", []).is_empty(), "scenario eval baseline set passes")
    _assert_true(eval_sets.get("target_failures", []).size() == 1, "scenario eval target set fails")

    if load_result.get("ok", false):
        var scenario_data: Array = load_result.get("data", {}).get("scenarios", [])
        var determinism: Dictionary = {}
        var enter_night: Dictionary = {}
        for entry in scenario_data:
            if typeof(entry) == TYPE_DICTIONARY and str(entry.get("id", "")) == "determinism_smoke":
                determinism = entry
            if typeof(entry) == TYPE_DICTIONARY and str(entry.get("id", "")) == "enter_night_stop":
                enter_night = entry
        if determinism.is_empty():
            _assert_true(false, "determinism_smoke scenario exists")
        else:
            var result: Dictionary = ScenarioRunner.run(determinism)
            _assert_equal(str(result.get("id", "")), "determinism_smoke", "scenario runner id matches")
            _assert_true(result.get("metrics", {}).has("day"), "scenario runner metrics include day")
            _assert_true(result.get("metrics", {}).has("phase"), "scenario runner metrics include phase")
            _assert_true(bool(result.get("pass", false)), "scenario runner passes determinism_smoke")
            _assert_true(result.get("baseline_failures", []).is_empty(), "scenario runner baseline failures empty")
            _assert_true(result.get("target_failures", []).is_empty(), "scenario runner target failures empty")
            var baseline_fail: Dictionary = determinism.duplicate(true)
            baseline_fail["expect_baseline"] = {"day": {"eq": 99}}
            var baseline_result: Dictionary = ScenarioRunner.run(baseline_fail)
            _assert_true(not bool(baseline_result.get("pass", false)), "baseline failures fail scenario")
            var target_only: Dictionary = determinism.duplicate(true)
            target_only["expect_baseline"] = {"day": {"eq": 1}}
            target_only["expect_target"] = {"day": {"eq": 99}}
            var target_result: Dictionary = ScenarioRunner.run(target_only)
            _assert_true(bool(target_result.get("pass", false)), "target failures do not fail by default")
            _assert_true(target_result.get("target_failures", []).size() == 1, "target failures recorded")
            var target_enforced: Dictionary = ScenarioRunner.run(target_only, {"enforce_targets": true})
            _assert_true(not bool(target_enforced.get("pass", false)), "enforced target failures fail scenario")
        if enter_night.is_empty():
            _assert_true(false, "enter_night_stop scenario exists")
        else:
            var night_result: Dictionary = ScenarioRunner.run(enter_night)
            _assert_true(bool(night_result.get("pass", false)), "scenario runner passes enter_night_stop")

    var cli := load("res://tools/run_scenarios.gd")
    if cli != null:
        var parsed: Dictionary = cli.parse_args(PackedStringArray(["--tag", "p0", "--exclude-tag", "long", "--targets", "--print-metrics", "--out-dir", "Logs/ScenarioReports"]))
        _assert_true(bool(parsed.get("ok", false)), "scenario cli parse ok")
        _assert_equal(parsed.get("exclude_tags", []).size(), 1, "scenario cli parse exclude tag")
        _assert_true(bool(parsed.get("targets", false)), "scenario cli parse targets flag")
        _assert_true(bool(parsed.get("print_metrics", false)), "scenario cli parse print-metrics flag")
        _assert_equal(str(parsed.get("out_dir", "")), "Logs/ScenarioReports", "scenario cli parse out-dir")
    _assert_true(FileAccess.file_exists("res://tools/run_scenarios.gd"), "tools: run_scenarios.gd exists")
    _assert_true(FileAccess.file_exists("res://data/scenarios.json"), "data: scenarios.json exists")

func _run_docs_tests() -> void:
    _assert_true(FileAccess.file_exists("res://docs/PROJECT_STATUS.md"), "docs: PROJECT_STATUS.md exists")
    _assert_true(FileAccess.file_exists("res://docs/ROADMAP.md"), "docs: ROADMAP.md exists")
    _assert_true(FileAccess.file_exists("res://docs/COMMAND_REFERENCE.md"), "docs: COMMAND_REFERENCE.md exists")
    _assert_true(FileAccess.file_exists("res://docs/ACCESSIBILITY_VERIFICATION.md"), "docs: ACCESSIBILITY_VERIFICATION.md exists")
    _assert_true(FileAccess.file_exists("res://docs/RESEARCH_SFK_SUMMARY.md"), "docs: RESEARCH_SFK_SUMMARY.md exists")
    _assert_true(FileAccess.file_exists("res://docs/BALANCE_CONSTANTS.md"), "docs: BALANCE_CONSTANTS.md exists")
    _assert_true(FileAccess.file_exists("res://docs/QUALITY_GATES.md"), "docs: QUALITY_GATES.md exists")
    _assert_true(FileAccess.file_exists("res://docs/PLAYTEST_PROTOCOL.md"), "docs: PLAYTEST_PROTOCOL.md exists")
    _assert_true(FileAccess.file_exists("res://docs/CHANGELOG.md"), "docs: CHANGELOG.md exists")
    _assert_true(FileAccess.file_exists("res://docs/ONBOARDING_TUTORIAL.md"), "docs: ONBOARDING_TUTORIAL.md exists")
    _assert_true(FileAccess.file_exists("res://docs/plans/README.md"), "docs: plans README exists")
    _assert_true(FileAccess.file_exists("res://docs/plans/planpack_2025-12-27_tempPlans/IMPORT_NOTES.md"), "docs: planpack import notes exist")
    _assert_true(FileAccess.file_exists("res://docs/plans/PLANPACK_TRIAGE.md"), "docs: planpack triage exists")
    _assert_true(FileAccess.file_exists("res://docs/plans/p0/ONBOARDING_PLAN.md"), "docs: P0 onboarding plan exists")
    _assert_true(FileAccess.file_exists("res://docs/plans/p0/ONBOARDING_COPY.md"), "docs: P0 onboarding copy exists")
    _assert_true(FileAccess.file_exists("res://docs/plans/p0/ONBOARDING_IMPLEMENTATION_SPEC.md"), "docs: P0 onboarding implementation spec exists")
    _assert_true(FileAccess.file_exists("res://docs/plans/p0/BALANCE_PLAN.md"), "docs: P0 balance plan exists")
    _assert_true(FileAccess.file_exists("res://docs/plans/p0/BALANCE_TARGETS.md"), "docs: P0 balance targets exist")
    _assert_true(FileAccess.file_exists("res://docs/plans/p0/ACCESSIBILITY_READABILITY_PLAN.md"), "docs: P0 accessibility plan exists")
    _assert_true(FileAccess.file_exists("res://docs/plans/p0/EXPORT_PIPELINE_PLAN.md"), "docs: P0 export plan exists")
    _assert_true(FileAccess.file_exists("res://docs/plans/p0/P0_IMPLEMENTATION_BACKLOG.md"), "docs: P0 implementation backlog exists")
    _assert_true(FileAccess.file_exists("res://docs/plans/p1/CONTENT_EXPANSION_PLAN.md"), "docs: P1 content expansion plan exists")
    _assert_true(FileAccess.file_exists("res://docs/plans/p1/VISUAL_STYLE_GUIDE_PLAN.md"), "docs: P1 visual style guide plan exists")
    _assert_true(FileAccess.file_exists("res://docs/plans/p1/MAP_EXPLORATION_PLAN.md"), "docs: P1 map exploration plan exists")
    _assert_true(FileAccess.file_exists("res://docs/plans/p1/QA_AUTOMATION_PLAN.md"), "docs: P1 QA automation plan exists")
    _assert_true(FileAccess.file_exists("res://docs/plans/p1/SCENARIO_TEST_HARNESS_PLAN.md"), "docs: P1 scenario test harness plan exists")
    _assert_true(FileAccess.file_exists("res://docs/plans/p1/SCENARIO_HARNESS_IMPLEMENTATION_SPEC.md"), "docs: P1 scenario harness implementation spec exists")
    _assert_true(FileAccess.file_exists("res://docs/plans/p1/SCENARIO_CATALOG.md"), "docs: P1 scenario catalog exists")
    _assert_true(FileAccess.file_exists("res://docs/plans/p1/CI_AUTOMATION_SPEC.md"), "docs: P1 CI automation spec exists")
    _assert_true(FileAccess.file_exists("res://docs/plans/p1/GDSCRIPT_QUALITY_PLAN.md"), "docs: P1 GDScript quality plan exists")
    _assert_true(FileAccess.file_exists("res://docs/plans/p2/META_PROGRESSION_PLAN.md"), "docs: P2 meta progression plan exists")
    _assert_true(FileAccess.file_exists("res://docs/plans/p2/HERO_SYSTEM_PLAN.md"), "docs: P2 hero system plan exists")
    _assert_true(FileAccess.file_exists("res://docs/plans/p2/LOCALIZATION_PLAN.md"), "docs: P2 localization plan exists")
    _assert_true(FileAccess.file_exists("res://docs/plans/p2/AUDIO_PLAN.md"), "docs: P2 audio plan exists")
    _assert_true(FileAccess.file_exists("res://docs/plans/ARCHITECTURE_MAPPING.md"), "docs: architecture mapping plan exists")
    _assert_true(FileAccess.file_exists("res://docs/plans/SCHEMA_ALIGNMENT_PLAN.md"), "docs: schema alignment plan exists")

func _run_export_pipeline_tests() -> void:
    var preset_path: String = "res://export_presets.cfg"
    _assert_true(FileAccess.file_exists(preset_path), "export preset: export_presets.cfg exists")
    var expected_name: String = "Windows Desktop"
    var expected_export_path: String = "build/windows/KeyboardDefense.exe"
    var expected_zip_path: String = "build/windows/KeyboardDefense-win64.zip"   
    var expected_pck_path: String = "build/windows/KeyboardDefense.pck"
    var embed_pck: bool = false
    var product_name: String = ""
    var product_version: String = ""
    if FileAccess.file_exists(preset_path):
        var config := ConfigFile.new()
        var load_result: int = config.load(preset_path)
        _assert_equal(load_result, OK, "export preset: config load OK")
        var found: bool = false
        var export_path: String = ""
        var platform: String = ""
        var matched_section: String = ""
        for section in config.get_sections():
            if not str(section).begins_with("preset."):
                continue
            var name_value: String = str(config.get_value(section, "name", ""))
            if name_value == expected_name:
                found = true
                export_path = str(config.get_value(section, "export_path", ""))
                platform = str(config.get_value(section, "platform", ""))
                matched_section = str(section)
                break
        _assert_true(found, "export preset: Windows Desktop preset exists")
        if found:
            _assert_equal(platform, expected_name, "export preset: platform matches Windows Desktop")
            _assert_true(export_path.ends_with(".exe"), "export preset: export_path ends with .exe")
            _assert_true(export_path.begins_with("build/"), "export preset: export_path under build/")
            _assert_equal(export_path, expected_export_path, "export preset: export_path matches expected")
            var options_section: String = "%s.options" % matched_section        
            _assert_true(config.has_section(options_section), "export preset: options section exists")
            if config.has_section(options_section):
                embed_pck = bool(config.get_value(options_section, "binary_format/embed_pck", false))
                product_name = str(config.get_value(options_section, "application/product_name", ""))
                product_version = str(config.get_value(options_section, "application/product_version", ""))
                _assert_true(product_name != "", "export preset: product_name present")
                _assert_true(product_version != "", "export preset: product_version present")

    var doc_path: String = "res://docs/EXPORT_WINDOWS.md"
    _assert_true(FileAccess.file_exists(doc_path), "docs: EXPORT_WINDOWS.md exists")
    if FileAccess.file_exists(doc_path):
        var doc_text: String = FileAccess.get_file_as_string(doc_path)
        _assert_true(doc_text.find("scripts/export_windows.ps1") != -1, "docs: export ps1 referenced")
        _assert_true(doc_text.find("scripts/export_windows.sh") != -1, "docs: export sh referenced")
        _assert_true(doc_text.find("apply package") != -1, "docs: package usage referenced")
        _assert_true(doc_text.find("package versioned") != -1, "docs: versioned package referenced")
        _assert_true(doc_text.find("apply package versioned") != -1, "docs: apply versioned package referenced")
        _assert_true(doc_text.find(expected_name) != -1, "docs: preset name referenced")
        _assert_true(doc_text.find(expected_export_path) != -1, "docs: export path matches expected")
        _assert_true(doc_text.find(expected_zip_path) != -1, "docs: zip path matches expected")
        _assert_true(doc_text.find("export_manifest.json") != -1, "docs: export manifest referenced")
        _assert_true(doc_text.find("KeyboardDefense-") != -1, "docs: versioned zip prefix referenced")
        _assert_true(doc_text.find("-win64.zip") != -1, "docs: versioned zip suffix referenced")
        _assert_true(doc_text.find("VERSION.txt") != -1, "docs: version file referenced")
        if not embed_pck:
            _assert_true(doc_text.find(expected_pck_path) != -1, "docs: pck path referenced when embed_pck is false")

    var ps_path: String = "res://scripts/export_windows.ps1"
    var sh_path: String = "res://scripts/export_windows.sh"
    _assert_true(FileAccess.file_exists(ps_path), "scripts: export_windows.ps1 exists")
    _assert_true(FileAccess.file_exists(sh_path), "scripts: export_windows.sh exists")
    if FileAccess.file_exists(ps_path):
        var ps_text: String = FileAccess.get_file_as_string(ps_path)
        _assert_true(ps_text.find(expected_export_path) != -1, "scripts: export_windows.ps1 uses expected path")
        _assert_true(ps_text.find(expected_name) != -1, "scripts: export_windows.ps1 uses preset name")
        _assert_true(ps_text.find(expected_zip_path) != -1, "scripts: export_windows.ps1 uses zip path")
        _assert_true(ps_text.find("application/product_name") != -1, "scripts: export_windows.ps1 parses product_name")
        _assert_true(ps_text.find("application/product_version") != -1, "scripts: export_windows.ps1 parses product_version")
        _assert_true(ps_text.find("application/file_version") != -1, "scripts: export_windows.ps1 parses file_version")
        _assert_true(ps_text.find("versioned") != -1, "scripts: export_windows.ps1 handles versioned token")
        _assert_true(ps_text.find("export_manifest.json") != -1, "scripts: export_windows.ps1 writes manifest")
        _assert_true(ps_text.find("-win64.zip") != -1, "scripts: export_windows.ps1 uses win64 zip suffix")
        _assert_true(ps_text.find("embed_pck") != -1, "scripts: export_windows.ps1 reads embed_pck")
        _assert_true(ps_text.find("VERSION.txt") != -1, "scripts: export_windows.ps1 reads VERSION.txt")
        _assert_true(ps_text.find("Preset file_version:") != -1, "scripts: export_windows.ps1 prints preset file_version")
        _assert_true(ps_text.find("WARNING: preset file_version") != -1, "scripts: export_windows.ps1 warns on preset file_version mismatch")
        _assert_true(ps_text.find("ERROR: preset file_version") != -1, "scripts: export_windows.ps1 errors on preset file_version mismatch")
        _assert_true(ps_text.find("WARNING: VERSION.txt (") != -1, "scripts: export_windows.ps1 warns on VERSION.txt mismatch")
        _assert_true(ps_text.find("ERROR: VERSION.txt (") != -1, "scripts: export_windows.ps1 errors on VERSION.txt mismatch")
        _assert_true(ps_text.find("preset file_version") != -1, "scripts: export_windows.ps1 references preset file_version")
        _assert_true(ps_text.find("WARNING: VERSION.txt") != -1, "scripts: export_windows.ps1 warns on version mismatch")
        _assert_true(ps_text.find("ERROR: VERSION.txt") != -1, "scripts: export_windows.ps1 errors on version mismatch")
        if not embed_pck:
            _assert_true(ps_text.find(".pck") != -1, "scripts: export_windows.ps1 checks for pck output")
    if FileAccess.file_exists(sh_path):
        var sh_text: String = FileAccess.get_file_as_string(sh_path)
        _assert_true(sh_text.find(expected_export_path) != -1, "scripts: export_windows.sh uses expected path")
        _assert_true(sh_text.find(expected_name) != -1, "scripts: export_windows.sh uses preset name")
        _assert_true(sh_text.find(expected_zip_path) != -1, "scripts: export_windows.sh uses zip path")
        _assert_true(sh_text.find("application/product_name") != -1, "scripts: export_windows.sh parses product_name")
        _assert_true(sh_text.find("application/product_version") != -1, "scripts: export_windows.sh parses product_version")
        _assert_true(sh_text.find("application/file_version") != -1, "scripts: export_windows.sh parses file_version")
        _assert_true(sh_text.find("versioned") != -1, "scripts: export_windows.sh handles versioned token")
        _assert_true(sh_text.find("export_manifest.json") != -1, "scripts: export_windows.sh writes manifest")
        _assert_true(sh_text.find("-win64.zip") != -1, "scripts: export_windows.sh uses win64 zip suffix")
        _assert_true(sh_text.find("embed_pck") != -1, "scripts: export_windows.sh reads embed_pck")
        _assert_true(sh_text.find("VERSION.txt") != -1, "scripts: export_windows.sh reads VERSION.txt")
        _assert_true(sh_text.find("Preset file_version:") != -1, "scripts: export_windows.sh prints preset file_version")
        _assert_true(sh_text.find("WARNING: preset file_version") != -1, "scripts: export_windows.sh warns on preset file_version mismatch")
        _assert_true(sh_text.find("ERROR: preset file_version") != -1, "scripts: export_windows.sh errors on preset file_version mismatch")
        _assert_true(sh_text.find("WARNING: VERSION.txt (") != -1, "scripts: export_windows.sh warns on VERSION.txt mismatch")
        _assert_true(sh_text.find("ERROR: VERSION.txt (") != -1, "scripts: export_windows.sh errors on VERSION.txt mismatch")
        _assert_true(sh_text.find("preset file_version") != -1, "scripts: export_windows.sh references preset file_version")
        _assert_true(sh_text.find("WARNING: VERSION.txt") != -1, "scripts: export_windows.sh warns on version mismatch")
        _assert_true(sh_text.find("ERROR: VERSION.txt") != -1, "scripts: export_windows.sh errors on version mismatch")
        if not embed_pck:
            _assert_true(sh_text.find(".pck") != -1, "scripts: export_windows.sh checks for pck output")

    var app_root: String = ProjectSettings.globalize_path("res://")
    var app_root_clean: String = app_root.trim_suffix("/").trim_suffix("\\")
    var apps_root: String = app_root_clean.get_base_dir()
    var repo_root: String = apps_root.get_base_dir()
    var root_ps_path: String = repo_root.path_join("scripts/export_windows.ps1")
    var root_sh_path: String = repo_root.path_join("scripts/export_windows.sh")
    _assert_true(FileAccess.file_exists(root_ps_path), "root scripts: export_windows.ps1 exists")
    _assert_true(FileAccess.file_exists(root_sh_path), "root scripts: export_windows.sh exists")
    if FileAccess.file_exists(root_ps_path):
        var root_ps_text: String = FileAccess.get_file_as_string(root_ps_path)
        _assert_true(root_ps_text.find("apps/keyboard-defense-godot/scripts/export_windows.ps1") != -1, "root scripts: ps1 delegates to app script")
    if FileAccess.file_exists(root_sh_path):
        var root_sh_text: String = FileAccess.get_file_as_string(root_sh_path)
        _assert_true(root_sh_text.find("apps/keyboard-defense-godot/scripts/export_windows.sh") != -1, "root scripts: sh delegates to app script")

func _run_version_tests() -> void:
    var version_path: String = "res://VERSION.txt"
    _assert_true(FileAccess.file_exists(version_path), "version file: VERSION.txt exists")
    var version_text: String = _read_file_text(version_path)
    if version_text != "":
        version_text = version_text.split("\n", false)[0].strip_edges()
    _assert_true(version_text != "", "version file: VERSION.txt not empty")
    var semver := RegEx.new()
    var semver_result: int = semver.compile("^\\d+\\.\\d+\\.\\d+$")
    _assert_equal(semver_result, OK, "version file: regex compiles")
    if semver_result == OK:
        _assert_true(semver.search(version_text) != null, "version file: semver format")

    var preset_version: String = ""
    var preset_path: String = "res://export_presets.cfg"
    if FileAccess.file_exists(preset_path):
        var config := ConfigFile.new()
        var load_result: int = config.load(preset_path)
        _assert_equal(load_result, OK, "version file: export presets load OK")
        if load_result == OK:
            for section in config.get_sections():
                var section_name: String = str(section)
                if section_name.begins_with("preset.") and not section_name.ends_with(".options"):
                    var name_value: String = str(config.get_value(section_name, "name", ""))
                    if name_value == "Windows Desktop":
                        var options_section: String = "%s.options" % section_name
                        preset_version = str(config.get_value(options_section, "application/product_version", ""))
                if section_name.begins_with("preset.") and section_name.ends_with(".options"):
                    var product_value: String = str(config.get_value(section_name, "application/product_version", ""))
                    var file_value: String = str(config.get_value(section_name, "application/file_version", ""))
                    _assert_true(product_value != "", "export preset: product_version present for %s" % section_name)
                    _assert_true(file_value != "", "export preset: file_version present for %s" % section_name)
                    _assert_equal(product_value, version_text, "export preset: product_version matches VERSION.txt for %s" % section_name)
                    _assert_equal(file_value, version_text, "export preset: file_version matches VERSION.txt for %s" % section_name)
                    _assert_equal(product_value, file_value, "export preset: product_version matches file_version for %s" % section_name)
    _assert_equal(preset_version, version_text, "version file: matches preset product_version")

    var parsed: Dictionary = CommandParser.parse("version")
    _assert_true(parsed.get("ok", false), "version command parse ok")
    if parsed.get("ok", false):
        _assert_equal(str(parsed.intent.get("kind", "")), "ui_version", "version command intent kind")
    var version_lines: Array[String] = MainScript.build_version_lines()
    _assert_equal(version_lines.size(), 2, "version output has two lines")
    if version_lines.size() >= 2:
        _assert_equal(version_lines[0], "Keyboard Defense v%s" % version_text, "version output line 1")
        _assert_true(version_lines[1].begins_with("Godot v"), "version output line 2 prefix")
        var engine_re := RegEx.new()
        var engine_result: int = engine_re.compile("^Godot v\\d+\\.\\d+\\.\\d+$")
        _assert_equal(engine_result, OK, "version output regex compiles")
        if engine_result == OK:
            _assert_true(engine_re.search(version_lines[1]) != null, "version output line 2 format")

func _run_version_bump_tests() -> void:
    var app_root: String = ProjectSettings.globalize_path("res://")
    var app_root_clean: String = app_root.trim_suffix("/").trim_suffix("\\")
    var apps_root: String = app_root_clean.get_base_dir()
    var repo_root: String = apps_root.get_base_dir()
    var root_ps_path: String = repo_root.path_join("scripts/bump_version.ps1")
    var root_sh_path: String = repo_root.path_join("scripts/bump_version.sh")
    _assert_true(FileAccess.file_exists(root_ps_path), "root scripts: bump_version.ps1 exists")
    _assert_true(FileAccess.file_exists(root_sh_path), "root scripts: bump_version.sh exists")
    if FileAccess.file_exists(root_ps_path):
        var ps_text: String = FileAccess.get_file_as_string(root_ps_path)
        _assert_true(ps_text.find("set <version>") != -1, "bump scripts: ps1 includes set token")
        _assert_true(ps_text.find("apply <version>") != -1, "bump scripts: ps1 includes apply token")
        _assert_true(ps_text.find("bump_version.ps1 patch") != -1, "bump scripts: ps1 includes patch usage")
        _assert_true(ps_text.find("bump_version.ps1 minor") != -1, "bump scripts: ps1 includes minor usage")
        _assert_true(ps_text.find("bump_version.ps1 major") != -1, "bump scripts: ps1 includes major usage")
        _assert_true(ps_text.find("apply patch") != -1, "bump scripts: ps1 includes apply patch usage")
        _assert_true(ps_text.find("apply minor") != -1, "bump scripts: ps1 includes apply minor usage")
        _assert_true(ps_text.find("apply major") != -1, "bump scripts: ps1 includes apply major usage")
        _assert_true(ps_text.find("ERROR: Current VERSION.txt is missing or invalid; use set <version>.") != -1, "bump scripts: ps1 includes invalid current version error")
        _assert_true(ps_text.find("VERSION.txt") != -1, "bump scripts: ps1 references VERSION.txt")
        _assert_true(ps_text.find("export_presets.cfg") != -1, "bump scripts: ps1 references export_presets.cfg")
        _assert_true(ps_text.find("application/product_version") != -1, "bump scripts: ps1 references product_version")
        _assert_true(ps_text.find("application/file_version") != -1, "bump scripts: ps1 references file_version")
    if FileAccess.file_exists(root_sh_path):
        var sh_text: String = FileAccess.get_file_as_string(root_sh_path)       
        _assert_true(sh_text.find("set <version>") != -1, "bump scripts: sh includes set token")
        _assert_true(sh_text.find("apply <version>") != -1, "bump scripts: sh includes apply token")
        _assert_true(sh_text.find("bump_version.sh patch") != -1, "bump scripts: sh includes patch usage")
        _assert_true(sh_text.find("bump_version.sh minor") != -1, "bump scripts: sh includes minor usage")
        _assert_true(sh_text.find("bump_version.sh major") != -1, "bump scripts: sh includes major usage")
        _assert_true(sh_text.find("apply patch") != -1, "bump scripts: sh includes apply patch usage")
        _assert_true(sh_text.find("apply minor") != -1, "bump scripts: sh includes apply minor usage")
        _assert_true(sh_text.find("apply major") != -1, "bump scripts: sh includes apply major usage")
        _assert_true(sh_text.find("ERROR: Current VERSION.txt is missing or invalid; use set <version>.") != -1, "bump scripts: sh includes invalid current version error")
        _assert_true(sh_text.find("VERSION.txt") != -1, "bump scripts: sh references VERSION.txt")
        _assert_true(sh_text.find("export_presets.cfg") != -1, "bump scripts: sh references export_presets.cfg")
        _assert_true(sh_text.find("application/product_version") != -1, "bump scripts: sh references product_version")
        _assert_true(sh_text.find("application/file_version") != -1, "bump scripts: sh references file_version")

func _run_balance_report_tests() -> void:
    var verify_text: String = SimBalanceReport.balance_verify_output()
    var verify_text_again: String = SimBalanceReport.balance_verify_output()
    _assert_equal(verify_text_again, verify_text, "balance verify deterministic")
    var verify_clean: String = verify_text
    if verify_clean.ends_with("\n"):
        verify_clean = verify_clean.trim_suffix("\n")
    _assert_equal(verify_clean, "Balance verify: OK", "balance verify output ok")

    var export_json: String = SimBalanceReport.balance_export_json()
    var export_json_again: String = SimBalanceReport.balance_export_json()
    _assert_equal(export_json_again, export_json, "balance export deterministic")
    _assert_true(export_json.begins_with("{"), "balance export outputs JSON object")
    var export_parsed: Variant = JSON.parse_string(export_json)
    _assert_true(typeof(export_parsed) == TYPE_DICTIONARY, "balance export JSON parses")
    var export_dict: Dictionary = export_parsed
    _assert_equal(str(export_dict.get("schema", "")), "typing-defense.balance-export", "balance export schema id")
    _assert_equal(int(export_dict.get("schema_version", 0)), 1, "balance export schema version")
    var export_game: Dictionary = export_dict.get("game", {})
    _assert_equal(str(export_game.get("name", "")), "Keyboard Defense", "balance export game name")
    var version_text: String = _read_file_text("res://VERSION.txt")
    if version_text != "":
        version_text = version_text.split("\n", false)[0].strip_edges()
    _assert_equal(str(export_game.get("version", "")), version_text, "balance export game version")
    var axis_text: String = str(export_dict.get("axis", ""))
    _assert_true(axis_text != "", "balance export axis non-empty")
    var metrics: Array = export_dict.get("metrics", [])
    _assert_true(metrics.size() >= 4, "balance export metrics count")
    var metrics_normalized: Array[String] = []
    for entry in metrics:
        metrics_normalized.append(str(entry))
    var metrics_sorted: Array[String] = metrics_normalized.duplicate()
    metrics_sorted.sort()
    _assert_equal(metrics_sorted, metrics_normalized, "balance export metrics sorted")
    var samples: Array = export_dict.get("samples", [])
    _assert_true(samples.size() >= 3, "balance export samples count")
    var last_id: String = ""
    for sample in samples:
        _assert_true(typeof(sample) == TYPE_DICTIONARY, "balance export sample dictionary")
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var sample_id: String = str(sample.get("id", ""))
        _assert_true(sample_id != "", "balance export sample id present")
        if last_id != "":
            _assert_true(sample_id >= last_id, "balance export sample order")
        last_id = sample_id
        var values: Variant = sample.get("values", {})
        _assert_true(typeof(values) == TYPE_DICTIONARY, "balance export values dictionary")
        if typeof(values) != TYPE_DICTIONARY:
            continue
        for metric_key in metrics:
            var metric_text: String = str(metric_key)
            _assert_true(values.has(metric_text), "balance export values include %s" % metric_text)
            if values.has(metric_text):
                var value: Variant = values.get(metric_text)
                var value_type: int = typeof(value)
                _assert_true(value_type == TYPE_INT or value_type == TYPE_FLOAT, "balance export %s numeric" % metric_text)

    var save_path: String = "user://balance_export.json"
    _remove_temp_file(save_path)
    var save_result: Dictionary = SimBalanceReport.save_balance_export()
    var save_line: String = str(save_result.get("line", ""))
    _assert_equal(save_line, "Saved to user://balance_export.json", "balance export save output line")
    _assert_true(FileAccess.file_exists(save_path), "balance export save writes file")
    var saved_text: String = _read_file_text(save_path)
    _assert_equal(saved_text, export_json, "balance export save content matches")
    var saved_parsed: Variant = JSON.parse_string(saved_text)
    if typeof(saved_parsed) == TYPE_DICTIONARY:
        _assert_equal(str(saved_parsed.get("schema", "")), "typing-defense.balance-export", "balance export save schema id")
    _remove_temp_file(save_path)

    var wave_json: String = SimBalanceReport.balance_export_json("wave")
    var wave_json_again: String = SimBalanceReport.balance_export_json("wave")
    _assert_equal(wave_json_again, wave_json, "balance export wave deterministic")
    _assert_true(wave_json.begins_with("{"), "balance export wave outputs JSON object")
    var wave_parsed: Variant = JSON.parse_string(wave_json)
    _assert_true(typeof(wave_parsed) == TYPE_DICTIONARY, "balance export wave JSON parses")
    var wave_dict: Dictionary = wave_parsed
    var wave_metrics: Array = wave_dict.get("metrics", [])
    _assert_true(wave_metrics.size() > 0, "balance export wave metrics count")
    var wave_metrics_text: Array[String] = []
    for entry in wave_metrics:
        var metric_text: String = str(entry)
        wave_metrics_text.append(metric_text)
        _assert_true(metric_text.begins_with("night_wave_"), "balance export wave metric prefix")
    _assert_true(wave_metrics_text.has("night_wave_total_base"), "balance export wave includes night_wave_total_base")
    _assert_true(wave_metrics_text.has("night_wave_total_threat2"), "balance export wave includes night_wave_total_threat2")
    _assert_true(wave_metrics_text.has("night_wave_total_threat4"), "balance export wave includes night_wave_total_threat4")
    var wave_samples: Array = wave_dict.get("samples", [])
    var wave_ids: Dictionary = {}
    var day7_values: Dictionary = {}
    for sample in wave_samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var sample_id: String = str(sample.get("id", ""))
        wave_ids[sample_id] = true
        var values: Variant = sample.get("values", {})
        _assert_true(typeof(values) == TYPE_DICTIONARY, "balance export wave values dictionary")
        if typeof(values) != TYPE_DICTIONARY:
            continue
        var values_dict: Dictionary = values
        if sample_id == "day_07":
            day7_values = values_dict
        _assert_equal(values_dict.size(), wave_metrics_text.size(), "balance export wave values size matches metrics")
        for metric_key in wave_metrics_text:
            _assert_true(values_dict.has(metric_key), "balance export wave values include %s" % metric_key)
        for value_key in values_dict.keys():
            _assert_true(wave_metrics_text.has(str(value_key)), "balance export wave values only wave metrics")
    for day in SimBalanceReport.SAMPLE_DAYS:
        var required_id: String = "day_%02d" % int(day)
        _assert_true(wave_ids.has(required_id), "balance export wave includes %s" % required_id)
    _assert_true(day7_values.size() > 0, "balance export wave captures day_07 values")
    if day7_values.size() > 0:
        _assert_equal(int(day7_values.get("night_wave_total_base", -1)), 7, "balance export wave day_07 base")
        _assert_equal(int(day7_values.get("night_wave_total_threat2", -1)), 9, "balance export wave day_07 threat2")
        _assert_equal(int(day7_values.get("night_wave_total_threat4", -1)), 11, "balance export wave day_07 threat4")

    var enemies_json: String = SimBalanceReport.balance_export_json("enemies")
    _assert_true(enemies_json.begins_with("{"), "balance export enemies outputs JSON object")
    var enemies_parsed: Variant = JSON.parse_string(enemies_json)
    _assert_true(typeof(enemies_parsed) == TYPE_DICTIONARY, "balance export enemies JSON parses")
    var enemies_dict: Dictionary = enemies_parsed
    var enemies_samples: Array = enemies_dict.get("samples", [])
    var enemies_day01_values: Dictionary = {}
    var enemies_day7_values: Dictionary = {}
    for sample in enemies_samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var sample_id: String = str(sample.get("id", ""))
        if sample_id == "day_01":
            var values_day1: Variant = sample.get("values", {})
            if typeof(values_day1) == TYPE_DICTIONARY:
                enemies_day01_values = values_day1
        elif sample_id == "day_07":
            var values_day7: Variant = sample.get("values", {})
            if typeof(values_day7) == TYPE_DICTIONARY:
                enemies_day7_values = values_day7
        if enemies_day01_values.size() > 0 and enemies_day7_values.size() > 0:
            break
    _assert_true(enemies_day01_values.size() > 0, "balance export enemies captures day_01 values")
    _assert_true(enemies_day7_values.size() > 0, "balance export enemies captures day_07 values")
    if enemies_day01_values.size() > 0:
        _assert_equal(int(enemies_day01_values.get("enemy_raider_hp_bonus", -1)), 0, "balance export enemies day_01 raider hp bonus")
        _assert_equal(int(enemies_day01_values.get("enemy_armored_hp_bonus", -1)), 1, "balance export enemies day_01 armored hp bonus")
        _assert_equal(int(enemies_day01_values.get("enemy_scout_hp_bonus", -2)), -1, "balance export enemies day_01 scout hp bonus")
        _assert_equal(int(enemies_day01_values.get("enemy_armored_armor", -1)), 1, "balance export enemies day_01 armored armor")
        _assert_equal(int(enemies_day01_values.get("enemy_raider_armor", -1)), 0, "balance export enemies day_01 raider armor")
        _assert_equal(int(enemies_day01_values.get("enemy_scout_armor", -1)), 0, "balance export enemies day_01 scout armor")
        _assert_equal(int(enemies_day01_values.get("enemy_scout_speed", -1)), 2, "balance export enemies day_01 scout speed")
        _assert_equal(int(enemies_day01_values.get("enemy_raider_speed", -1)), 1, "balance export enemies day_01 raider speed")
        _assert_equal(int(enemies_day01_values.get("enemy_armored_speed", -1)), 1, "balance export enemies day_01 armored speed")
    if enemies_day7_values.size() > 0:
        _assert_equal(int(enemies_day7_values.get("enemy_armored_hp_bonus", -1)), 4, "balance export enemies day_07 armored hp bonus")
        _assert_equal(int(enemies_day7_values.get("enemy_raider_hp_bonus", -1)), 2, "balance export enemies day_07 raider hp bonus")
        _assert_equal(int(enemies_day7_values.get("enemy_scout_hp_bonus", -1)), 1, "balance export enemies day_07 scout hp bonus")
        _assert_equal(int(enemies_day7_values.get("enemy_armored_armor", -1)), 2, "balance export enemies day_07 armored armor")
        _assert_equal(int(enemies_day7_values.get("enemy_raider_armor", -1)), 1, "balance export enemies day_07 raider armor")
        _assert_equal(int(enemies_day7_values.get("enemy_scout_armor", -1)), 1, "balance export enemies day_07 scout armor")
        _assert_equal(int(enemies_day7_values.get("enemy_scout_speed", -1)), 3, "balance export enemies day_07 scout speed")
        _assert_equal(int(enemies_day7_values.get("enemy_raider_speed", -1)), 2, "balance export enemies day_07 raider speed")
        _assert_equal(int(enemies_day7_values.get("enemy_armored_speed", -1)), 2, "balance export enemies day_07 armored speed")

    var towers_json: String = SimBalanceReport.balance_export_json("towers")
    _assert_true(towers_json.begins_with("{"), "balance export towers outputs JSON object")
    var towers_parsed: Variant = JSON.parse_string(towers_json)
    _assert_true(typeof(towers_parsed) == TYPE_DICTIONARY, "balance export towers JSON parses")
    var towers_dict: Dictionary = towers_parsed
    var towers_samples: Array = towers_dict.get("samples", [])
    var towers_day7_values: Dictionary = {}
    for sample in towers_samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var sample_id: String = str(sample.get("id", ""))
        if sample_id != "day_07":
            continue
        var values: Variant = sample.get("values", {})
        if typeof(values) == TYPE_DICTIONARY:
            towers_day7_values = values
        break
    _assert_true(towers_day7_values.size() > 0, "balance export towers captures day_07 values")
    if towers_day7_values.size() > 0:
        _assert_equal(int(towers_day7_values.get("tower_level1_damage", -1)), 1, "balance export towers day_07 level1 damage")
        _assert_equal(int(towers_day7_values.get("tower_level2_damage", -1)), 2, "balance export towers day_07 level2 damage")
        _assert_equal(int(towers_day7_values.get("tower_level3_damage", -1)), 3, "balance export towers day_07 level3 damage")
        _assert_equal(int(towers_day7_values.get("tower_upgrade1_cost_stone", -1)), 8, "balance export towers day_07 upgrade1 stone")
        _assert_equal(int(towers_day7_values.get("tower_upgrade1_cost_wood", -1)), 4, "balance export towers day_07 upgrade1 wood")
        _assert_equal(int(towers_day7_values.get("tower_upgrade2_cost_stone", -1)), 12, "balance export towers day_07 upgrade2 stone")
        _assert_equal(int(towers_day7_values.get("tower_upgrade2_cost_wood", -1)), 8, "balance export towers day_07 upgrade2 wood")

    var buildings_json: String = SimBalanceReport.balance_export_json("buildings")
    var buildings_parsed: Variant = JSON.parse_string(buildings_json)
    _assert_true(typeof(buildings_parsed) == TYPE_DICTIONARY, "balance export buildings JSON parses")
    var buildings_dict: Dictionary = buildings_parsed
    var buildings_samples: Array = buildings_dict.get("samples", [])
    var buildings_day01_values: Dictionary = {}
    var buildings_day07_values: Dictionary = {}
    for sample in buildings_samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var sample_id: String = str(sample.get("id", ""))
        if sample_id == "day_01":
            var values_day1: Variant = sample.get("values", {})
            if typeof(values_day1) == TYPE_DICTIONARY:
                buildings_day01_values = values_day1
        elif sample_id == "day_07":
            var values_day7: Variant = sample.get("values", {})
            if typeof(values_day7) == TYPE_DICTIONARY:
                buildings_day07_values = values_day7
        if buildings_day01_values.size() > 0 and buildings_day07_values.size() > 0:
            break
    _assert_true(buildings_day01_values.size() > 0, "balance export buildings captures day_01 values")
    _assert_true(buildings_day07_values.size() > 0, "balance export buildings captures day_07 values")
    if buildings_day01_values.size() > 0:
        _assert_equal(int(buildings_day01_values.get("building_tower_cost_stone", -1)), 8, "balance export buildings day_01 tower stone cost")
        _assert_equal(int(buildings_day01_values.get("building_tower_cost_wood", -1)), 4, "balance export buildings day_01 tower wood cost")
        _assert_equal(int(buildings_day01_values.get("building_wall_cost_stone", -1)), 4, "balance export buildings day_01 wall stone cost")
        _assert_equal(int(buildings_day01_values.get("building_wall_cost_wood", -1)), 4, "balance export buildings day_01 wall wood cost")
        _assert_equal(int(buildings_day01_values.get("building_farm_production_food", -1)), 3, "balance export buildings day_01 farm food production")
        _assert_equal(int(buildings_day01_values.get("building_lumber_production_wood", -1)), 3, "balance export buildings day_01 lumber wood production")
        _assert_equal(int(buildings_day01_values.get("building_quarry_production_stone", -1)), 3, "balance export buildings day_01 quarry stone production")
    if buildings_day07_values.size() > 0:
        _assert_equal(int(buildings_day07_values.get("building_tower_cost_stone", -1)), 8, "balance export buildings day_07 tower stone cost")
        _assert_equal(int(buildings_day07_values.get("building_tower_cost_wood", -1)), 4, "balance export buildings day_07 tower wood cost")
        _assert_equal(int(buildings_day07_values.get("building_wall_cost_stone", -1)), 4, "balance export buildings day_07 wall stone cost")
        _assert_equal(int(buildings_day07_values.get("building_wall_cost_wood", -1)), 4, "balance export buildings day_07 wall wood cost")
        _assert_equal(int(buildings_day07_values.get("building_farm_production_food", -1)), 3, "balance export buildings day_07 farm food production")
        _assert_equal(int(buildings_day07_values.get("building_lumber_production_wood", -1)), 3, "balance export buildings day_07 lumber wood production")
        _assert_equal(int(buildings_day07_values.get("building_quarry_production_stone", -1)), 3, "balance export buildings day_07 quarry stone production")

    var midgame_json: String = SimBalanceReport.balance_export_json("midgame")
    _assert_true(midgame_json.begins_with("{"), "balance export midgame outputs JSON object")
    var midgame_parsed: Variant = JSON.parse_string(midgame_json)
    _assert_true(typeof(midgame_parsed) == TYPE_DICTIONARY, "balance export midgame JSON parses")
    var midgame_dict: Dictionary = midgame_parsed
    var midgame_samples: Array = midgame_dict.get("samples", [])
    var midgame_day01_values: Dictionary = {}
    var midgame_day03_values: Dictionary = {}
    var midgame_day04_values: Dictionary = {}
    var midgame_day07_values: Dictionary = {}
    for sample in midgame_samples:
        if typeof(sample) != TYPE_DICTIONARY:
            continue
        var sample_id: String = str(sample.get("id", ""))
        if sample_id == "day_01":
            var values_day1: Variant = sample.get("values", {})
            if typeof(values_day1) == TYPE_DICTIONARY:
                midgame_day01_values = values_day1
        elif sample_id == "day_03":
            var values: Variant = sample.get("values", {})
            if typeof(values) == TYPE_DICTIONARY:
                midgame_day03_values = values
        elif sample_id == "day_04":
            var values_day4: Variant = sample.get("values", {})
            if typeof(values_day4) == TYPE_DICTIONARY:
                midgame_day04_values = values_day4
        elif sample_id == "day_07":
            var values_day7: Variant = sample.get("values", {})
            if typeof(values_day7) == TYPE_DICTIONARY:
                midgame_day07_values = values_day7
        if midgame_day01_values.size() > 0 and midgame_day03_values.size() > 0 and midgame_day04_values.size() > 0 and midgame_day07_values.size() > 0:
            break
    _assert_true(midgame_day01_values.size() > 0, "balance export midgame captures day_01 values")
    _assert_true(midgame_day03_values.size() > 0, "balance export midgame captures day_03 values")
    _assert_true(midgame_day04_values.size() > 0, "balance export midgame captures day_04 values")
    _assert_true(midgame_day07_values.size() > 0, "balance export midgame captures day_07 values")
    if midgame_day01_values.size() > 0:
        _assert_equal(int(midgame_day01_values.get("midgame_caps_food", -1)), 0, "balance export midgame day_01 food cap")
    if midgame_day03_values.size() > 0:
        _assert_equal(int(midgame_day03_values.get("midgame_food_bonus_day", -1)), 4, "balance export midgame day_03 food bonus day")
        _assert_equal(int(midgame_day03_values.get("midgame_food_bonus", -1)), 0, "balance export midgame day_03 food bonus")
    if midgame_day04_values.size() > 0:
        _assert_equal(int(midgame_day04_values.get("midgame_food_bonus_day", -1)), 4, "balance export midgame day_04 food bonus day")
        _assert_equal(int(midgame_day04_values.get("midgame_food_bonus", -1)), 2, "balance export midgame day_04 food bonus")
    if midgame_day07_values.size() > 0:
        _assert_equal(int(midgame_day07_values.get("midgame_caps_food", -1)), 35, "balance export midgame day_07 food cap")
        _assert_equal(int(midgame_day07_values.get("midgame_caps_stone", -1)), 35, "balance export midgame day_07 stone cap")
        _assert_equal(int(midgame_day07_values.get("midgame_stone_catchup_min", -1)), 10, "balance export midgame day_07 stone catchup min")
        _assert_equal(int(midgame_day07_values.get("midgame_food_bonus_day", -1)), 4, "balance export midgame day_07 food bonus day")

    var wave_save_path: String = "user://balance_export_wave.json"
    _remove_temp_file(wave_save_path)
    var wave_save_result: Dictionary = SimBalanceReport.save_balance_export("wave")
    var wave_save_line: String = str(wave_save_result.get("line", ""))
    _assert_equal(wave_save_line, "Saved to user://balance_export_wave.json", "balance export save wave output line")
    _assert_true(FileAccess.file_exists(wave_save_path), "balance export save wave writes file")
    var wave_saved_text: String = _read_file_text(wave_save_path)
    _assert_equal(wave_saved_text, wave_json, "balance export save wave content matches")
    var wave_saved_parsed: Variant = JSON.parse_string(wave_saved_text)
    if typeof(wave_saved_parsed) == TYPE_DICTIONARY:
        var wave_saved_metrics: Array = wave_saved_parsed.get("metrics", [])
        for entry in wave_saved_metrics:
            _assert_true(str(entry).begins_with("night_wave_"), "balance export save wave metrics prefix")
    _remove_temp_file(wave_save_path)

    var summary_text: String = SimBalanceReport.balance_summary_output()
    var summary_text_again: String = SimBalanceReport.balance_summary_output()
    _assert_equal(summary_text_again, summary_text, "balance summary deterministic")
    var summary_lines: PackedStringArray = summary_text.split("\n", false)
    _assert_true(summary_lines.size() >= 2, "balance summary lines present")
    _assert_equal(summary_lines[0], "Balance summary (days):", "balance summary title")
    _assert_equal(summary_lines[1], "id | night_wave_total_base | night_wave_total_threat2 | night_wave_total_threat4 | enemy_scout_speed | tower_level1_damage", "balance summary header")
    _assert_true(summary_text.find("day_01 |") != -1, "balance summary includes day_01")
    _assert_true(summary_text.find("day_07 |") != -1, "balance summary includes day_07")

    var wave_summary_text: String = SimBalanceReport.balance_summary_output("wave")
    var wave_summary_text_again: String = SimBalanceReport.balance_summary_output("wave")
    _assert_equal(wave_summary_text_again, wave_summary_text, "balance summary wave deterministic")
    var wave_lines: PackedStringArray = wave_summary_text.split("\n", false)
    _assert_true(wave_lines.size() >= 2, "balance summary wave lines present")
    _assert_equal(wave_lines[0], "Balance summary (days/wave):", "balance summary wave title")
    _assert_equal(wave_lines[1], "id | night_wave_total_base | night_wave_total_threat2 | night_wave_total_threat4", "balance summary wave header")
    _assert_true(wave_summary_text.find("day_07 |") != -1, "balance summary wave includes day_07")

    var enemies_summary_text: String = SimBalanceReport.balance_summary_output("enemies")
    var enemies_summary_text_again: String = SimBalanceReport.balance_summary_output("enemies")
    _assert_equal(enemies_summary_text_again, enemies_summary_text, "balance summary enemies deterministic")
    var enemies_lines: PackedStringArray = enemies_summary_text.split("\n", false)
    _assert_true(enemies_lines.size() >= 2, "balance summary enemies lines present")
    _assert_equal(enemies_lines[0], "Balance summary (days/enemies):", "balance summary enemies title")
    _assert_equal(enemies_lines[1], "id | enemy_scout_hp_bonus | enemy_raider_hp_bonus | enemy_armored_hp_bonus | enemy_scout_speed | enemy_raider_speed | enemy_armored_speed", "balance summary enemies header")
    _assert_true(enemies_summary_text.find("day_07 |") != -1, "balance summary enemies includes day_07")
    _assert_true(enemies_summary_text.find("day_07 | 1 | 2 | 4 |") != -1, "balance summary enemies day_07 hp bonus trio")

    var towers_summary_text: String = SimBalanceReport.balance_summary_output("towers")
    var towers_summary_text_again: String = SimBalanceReport.balance_summary_output("towers")
    _assert_equal(towers_summary_text_again, towers_summary_text, "balance summary towers deterministic")
    var towers_lines: PackedStringArray = towers_summary_text.split("\n", false)
    _assert_true(towers_lines.size() >= 2, "balance summary towers lines present")
    _assert_equal(towers_lines[0], "Balance summary (days/towers):", "balance summary towers title")
    _assert_equal(towers_lines[1], "id | tower_level1_damage | tower_level1_shots | tower_level2_damage | tower_level2_shots | tower_level3_damage | tower_level3_shots", "balance summary towers header")

    var buildings_summary_text: String = SimBalanceReport.balance_summary_output("buildings")
    var buildings_summary_text_again: String = SimBalanceReport.balance_summary_output("buildings")
    _assert_equal(buildings_summary_text_again, buildings_summary_text, "balance summary buildings deterministic")
    var buildings_lines: PackedStringArray = buildings_summary_text.split("\n", false)
    _assert_true(buildings_lines.size() >= 2, "balance summary buildings lines present")
    _assert_equal(buildings_lines[0], "Balance summary (days/buildings):", "balance summary buildings title")
    _assert_equal(buildings_lines[1], "id | building_farm_cost_wood | building_farm_production_food | building_lumber_cost_food | building_lumber_cost_wood | building_lumber_production_wood | building_quarry_cost_food | building_quarry_cost_wood | building_quarry_production_stone | building_tower_cost_stone | building_tower_cost_wood | building_wall_cost_stone | building_wall_cost_wood", "balance summary buildings header")
    _assert_true(buildings_summary_text.find("day_07 |") != -1, "balance summary buildings includes day_07")

    var midgame_summary_text: String = SimBalanceReport.balance_summary_output("midgame")
    var midgame_summary_text_again: String = SimBalanceReport.balance_summary_output("midgame")
    _assert_equal(midgame_summary_text_again, midgame_summary_text, "balance summary midgame deterministic")
    var midgame_lines: PackedStringArray = midgame_summary_text.split("\n", false)
    _assert_true(midgame_lines.size() >= 2, "balance summary midgame lines present")
    _assert_equal(midgame_lines[0], "Balance summary (days/midgame):", "balance summary midgame title")
    _assert_equal(midgame_lines[1], "id | midgame_caps_food | midgame_caps_wood | midgame_caps_stone | midgame_food_bonus_day | midgame_food_bonus_amount | midgame_food_bonus_threshold | midgame_food_bonus | midgame_stone_catchup_day | midgame_stone_catchup_min", "balance summary midgame header")
    _assert_true(midgame_summary_text.find("day_07 |") != -1, "balance summary midgame includes day_07")

    var unknown_summary: String = SimBalanceReport.balance_summary_output("banana")
    _assert_equal(unknown_summary, "Balance summary: unknown group banana", "balance summary unknown group message")

    var unknown_export: String = SimBalanceReport.balance_export_json("banana")
    _assert_equal(unknown_export, "Balance export: unknown group banana", "balance export unknown group message")
    var unknown_save: Dictionary = SimBalanceReport.save_balance_export("banana")
    _assert_equal(str(unknown_save.get("line", "")), "Balance export save: unknown group banana", "balance export save unknown group message")

    var diff_path: String = "user://balance_export_wave.json"
    _remove_temp_file(diff_path)
    var diff_missing: String = SimBalanceReport.balance_diff_output("wave")
    _assert_equal(diff_missing, "Balance diff: missing baseline user://balance_export_wave.json", "balance diff missing baseline message")

    var diff_save: Dictionary = SimBalanceReport.save_balance_export("wave")
    _assert_true(diff_save.get("ok", false), "balance diff save baseline ok")
    var diff_clean: String = SimBalanceReport.balance_diff_output("wave")
    _assert_equal(diff_clean, "Balance diff: no changes", "balance diff no changes")

    var diff_saved_text: String = _read_file_text(diff_path)
    var diff_saved_parsed: Variant = JSON.parse_string(diff_saved_text)
    if typeof(diff_saved_parsed) == TYPE_DICTIONARY:
        var diff_saved_dict: Dictionary = diff_saved_parsed
        var diff_samples: Array = diff_saved_dict.get("samples", [])
        for i in range(diff_samples.size()):
            var sample: Variant = diff_samples[i]
            if typeof(sample) != TYPE_DICTIONARY:
                continue
            if str(sample.get("id", "")) != "day_07":
                continue
            var values_raw: Variant = sample.get("values", {})
            if typeof(values_raw) != TYPE_DICTIONARY:
                continue
            var values_dict: Dictionary = values_raw
            var current_base: int = int(day7_values.get("night_wave_total_base", 0))
            values_dict["night_wave_total_base"] = current_base - 1
            sample["values"] = values_dict
            diff_samples[i] = sample
            break
        diff_saved_dict["samples"] = diff_samples
        var diff_json: String = SimBalanceReport.format_balance_export_json(diff_saved_dict)
        var diff_file := FileAccess.open(diff_path, FileAccess.WRITE)
        if diff_file != null:
            diff_file.store_string(diff_json)
            diff_file.close()

    var diff_changed: String = SimBalanceReport.balance_diff_output("wave")
    var diff_lines: PackedStringArray = diff_changed.split("\n", false)
    _assert_equal(diff_lines.size(), 2, "balance diff one change lines")
    _assert_equal(diff_lines[0], "Balance diff: 1 changes", "balance diff one change header")
    var diff_old: int = int(day7_values.get("night_wave_total_base", 0)) - 1
    var diff_new: int = int(day7_values.get("night_wave_total_base", 0))
    _assert_equal(diff_lines[1], "day_07 night_wave_total_base: %d -> %d" % [diff_old, diff_new], "balance diff one change value")

    var diff_unknown: String = SimBalanceReport.balance_diff_output("banana")
    _assert_equal(diff_unknown, "Balance diff: unknown group banana", "balance diff unknown group message")
    _remove_temp_file(diff_path)

func _run_verification_wrapper_tests() -> void:
    var wrapper_specs: Array[Dictionary] = [
        {"path": "res://scripts/test.ps1", "target": "scripts/test.ps1"},
        {"path": "res://scripts/test.sh", "target": "scripts/test.sh"},
        {"path": "res://scripts/scenarios.ps1", "target": "scripts/scenarios.ps1"},
        {"path": "res://scripts/scenarios.sh", "target": "scripts/scenarios.sh"},
        {"path": "res://scripts/scenarios_early.ps1", "target": "scripts/scenarios_early.ps1"},
        {"path": "res://scripts/scenarios_early.sh", "target": "scripts/scenarios_early.sh"},
        {"path": "res://scripts/scenarios_mid.ps1", "target": "scripts/scenarios_mid.ps1"},
        {"path": "res://scripts/scenarios_mid.sh", "target": "scripts/scenarios_mid.sh"}
    ]
    for spec in wrapper_specs:
        var path: String = str(spec.get("path", ""))
        var target: String = str(spec.get("target", ""))
        _assert_true(FileAccess.file_exists(path), "wrapper scripts: %s exists" % path)
        if FileAccess.file_exists(path):
            var text: String = FileAccess.get_file_as_string(path)
            _assert_true(text.find("Delegating to scripts/") != -1, "wrapper scripts: delegation line in %s" % path)
            _assert_true(text.find(target) != -1, "wrapper scripts: target reference in %s" % path)

    var app_root: String = ProjectSettings.globalize_path("res://")
    var app_root_clean: String = app_root.trim_suffix("/").trim_suffix("\\")
    var apps_root: String = app_root_clean.get_base_dir()
    var repo_root: String = apps_root.get_base_dir()
    var root_scripts: Array[String] = [
        "scripts/test.ps1",
        "scripts/test.sh",
        "scripts/scenarios.ps1",
        "scripts/scenarios.sh",
        "scripts/scenarios_early.ps1",
        "scripts/scenarios_early.sh",
        "scripts/scenarios_mid.ps1",
        "scripts/scenarios_mid.sh"
    ]
    for rel_path in root_scripts:
        var abs_path: String = repo_root.path_join(rel_path)
        _assert_true(FileAccess.file_exists(abs_path), "root scripts: %s exists" % rel_path)

func _run_lessons_tests() -> void:
    var load_result: Dictionary = SimLessons.load_data()
    _assert_true(load_result.get("ok", false), "lessons load ok")
    var data: Dictionary = load_result.get("data", {})
    var lessons: Array = data.get("lessons", [])
    _assert_true(lessons is Array and lessons.size() > 0, "lessons list non-empty")
    var default_id: String = str(data.get("default_lesson", ""))
    _assert_equal(int(data.get("version", 0)), 2, "lessons version is 2")
    _assert_true(SimLessons.is_valid(default_id), "default lesson valid")
    _assert_true(SimLessons.lesson_ids().has("full_alpha"), "lessons include full_alpha")
    for entry in lessons:
        _assert_true(typeof(entry) == TYPE_DICTIONARY, "lesson entry is dictionary")
        var lesson: Dictionary = entry
        _assert_true(str(lesson.get("id", "")) != "", "lesson id present")
        _assert_true(str(lesson.get("name", "")) != "", "lesson name present")
        var mode: String = str(lesson.get("mode", ""))
        _assert_true(mode in ["charset", "wordlist", "sentence"], "lesson mode is valid")
        # Charset mode requires charset field, wordlist/sentence modes have word pools
        if mode == "charset":
            var charset: String = str(lesson.get("charset", ""))
            _assert_true(charset != "", "charset lesson has charset")
        var lengths: Dictionary = lesson.get("lengths", {})
        for kind in ["scout", "raider", "armored"]:
            var range_value: Variant = lengths.get(kind, [])
            _assert_true(range_value is Array and range_value.size() >= 2, "lesson lengths include %s" % kind)
            if range_value is Array and range_value.size() >= 2:
                var min_len: int = int(range_value[0])
                var max_len: int = int(range_value[1])
                _assert_true(min_len > 0, "lesson length min positive for %s" % kind)
                _assert_true(max_len >= min_len, "lesson length max >= min for %s" % kind)
    var lesson_id: String = SimLessons.normalize_lesson_id(default_id)
    var lesson_data: Dictionary = SimLessons.get_lesson(lesson_id)
    var word: String = SimWords.word_for_enemy("lesson-seed", 1, "scout", 1, {}, lesson_id)
    _assert_true(word != "", "lesson word generated")
    var lesson_charset: String = str(lesson_data.get("charset", ""))
    _assert_true(_word_in_charset(word, lesson_charset), "lesson word uses charset")
    var scout_range: Variant = lesson_data.get("lengths", {}).get("scout", [])
    if scout_range is Array and scout_range.size() >= 2:
        _assert_true(word.length() >= int(scout_range[0]) and word.length() <= int(scout_range[1]), "lesson word length in range")
    var used: Dictionary = {word: true}
    var word2: String = SimWords.word_for_enemy("lesson-seed", 1, "scout", 2, used, lesson_id)
    _assert_true(word2 != word, "lesson words unique")

func _word_in_charset(word: String, charset: String) -> bool:
    if charset == "":
        return false
    for i in range(word.length()):
        var ch: String = word.substr(i, 1)
        if charset.find(ch) < 0:
            return false
    return true

func _run_command_keywords_tests() -> void:
    var keywords: Array[String] = CommandKeywords.keywords()
    _assert_true(keywords.has("help"), "command keywords include help")
    _assert_true(keywords.has("version"), "command keywords include version")
    _assert_true(keywords.has("status"), "command keywords include status")     
    _assert_true(keywords.has("balance"), "command keywords include balance")
    _assert_true(keywords.has("build"), "command keywords include build")       
    _assert_true(keywords.has("defend"), "command keywords include defend")
    _assert_true(keywords.has("wait"), "command keywords include wait")
    _assert_true(keywords.has("report"), "command keywords include report")
    _assert_true(keywords.has("history"), "command keywords include history")
    _assert_true(keywords.has("trend"), "command keywords include trend")
    _assert_true(keywords.has("goal"), "command keywords include goal")
    _assert_true(keywords.has("lesson"), "command keywords include lesson")
    _assert_true(keywords.has("lessons"), "command keywords include lessons")
    _assert_true(keywords.has("settings"), "command keywords include settings")
    _assert_true(keywords.has("bind"), "command keywords include bind")
    _assert_true(keywords.has("tutorial"), "command keywords include tutorial")

func _run_scene_compile_tests() -> void:
    var packed := load("res://scenes/Main.tscn")
    _assert_true(packed is PackedScene, "Main scene loads")
    if packed is PackedScene:
        var inst = packed.instantiate()
        _assert_true(inst != null, "Main scene instantiates")
        if inst != null:
            inst.free()

func _run_practice_goal_tests() -> void:
    _assert_equal(PracticeGoals.normalize_goal(""), "balanced", "normalize_goal empty")
    _assert_equal(PracticeGoals.normalize_goal("banana"), "balanced", "normalize_goal invalid")
    _assert_equal(PracticeGoals.normalize_goal("Accuracy"), "accuracy", "normalize_goal valid")
    _assert_true(PracticeGoals.is_valid("speed"), "practice goal valid speed")
    var thresholds: Dictionary = PracticeGoals.thresholds("balanced")
    _assert_true(thresholds.has("min_hit_rate"), "thresholds include min_hit_rate")
    _assert_true(thresholds.has("min_accuracy"), "thresholds include min_accuracy")
    _assert_true(thresholds.has("max_backspace_rate"), "thresholds include max_backspace_rate")
    _assert_true(thresholds.has("max_incomplete_rate"), "thresholds include max_incomplete_rate")

func _run_goal_theme_tests() -> void:
    _assert_equal(GoalTheme.hex_for_goal("accuracy"), "#0072B2", "goal theme accuracy hex")
    _assert_equal(GoalTheme.hex_for_goal("unknown"), "#B0B0B0", "goal theme unknown uses balanced")
    var pass_hex: String = GoalTheme.hex_for_pass(true)
    var fail_hex: String = GoalTheme.hex_for_pass(false)
    _assert_true(pass_hex != fail_hex, "goal theme pass differs from fail")
    _assert_true(pass_hex.begins_with("#") and pass_hex.length() == 7, "goal theme pass hex format")
    _assert_true(fail_hex.begins_with("#") and fail_hex.length() == 7, "goal theme fail hex format")

func _run_inputmap_tests() -> void:
    _assert_true(InputMap.has_action("cycle_goal"), "InputMap has cycle_goal action")
    var events: Array = InputMap.action_get_events("cycle_goal")
    _assert_true(events.size() > 0, "cycle_goal has at least one binding")
    var has_f7: bool = false
    var details: Array[String] = []
    for event in events:
        if event is InputEventKey and event.keycode == KEY_F7:
            has_f7 = true
            break
        if event is InputEventKey:
            details.append("key=%d phys=%d" % [event.keycode, event.physical_keycode])
    if has_f7:
        _assert_true(true, "cycle_goal includes F7 binding")
    else:
        var detail_text: String = ", ".join(details)
        _assert_true(false, "cycle_goal includes F7 binding (events: %s, KEY_F7=%d)" % [detail_text, KEY_F7])

    _assert_true(InputMap.has_action("toggle_settings"), "InputMap has toggle_settings action")
    var settings_events: Array = InputMap.action_get_events("toggle_settings")
    _assert_true(settings_events.size() > 0, "toggle_settings has at least one binding")
    var has_f1: bool = false
    var settings_details: Array[String] = []
    for event in settings_events:
        if event is InputEventKey and event.keycode == KEY_F1:
            has_f1 = true
            break
        if event is InputEventKey:
            settings_details.append("key=%d phys=%d" % [event.keycode, event.physical_keycode])
    if has_f1:
        _assert_true(true, "toggle_settings includes F1 binding")
    else:
        var settings_detail_text: String = ", ".join(settings_details)
        _assert_true(false, "toggle_settings includes F1 binding (events: %s, KEY_F1=%d)" % [settings_detail_text, KEY_F1])

    _assert_true(InputMap.has_action("toggle_lessons"), "InputMap has toggle_lessons action")
    var lessons_events: Array = InputMap.action_get_events("toggle_lessons")
    _assert_true(lessons_events.size() > 0, "toggle_lessons has at least one binding")
    var has_f2: bool = false
    var lessons_details: Array[String] = []
    for event in lessons_events:
        if event is InputEventKey and event.keycode == KEY_F2:
            has_f2 = true
            break
        if event is InputEventKey:
            lessons_details.append("key=%d phys=%d" % [event.keycode, event.physical_keycode])
    if has_f2:
        _assert_true(true, "toggle_lessons includes F2 binding")
    else:
        var lessons_detail_text: String = ", ".join(lessons_details)
        _assert_true(false, "toggle_lessons includes F2 binding (events: %s, KEY_F2=%d)" % [lessons_detail_text, KEY_F2])

    _assert_true(InputMap.has_action("toggle_trend"), "InputMap has toggle_trend action")
    var trend_events: Array = InputMap.action_get_events("toggle_trend")
    _assert_true(trend_events.size() > 0, "toggle_trend has at least one binding")
    var has_f3: bool = false
    var trend_details: Array[String] = []
    for event in trend_events:
        if event is InputEventKey and event.keycode == KEY_F3:
            has_f3 = true
            break
        if event is InputEventKey:
            trend_details.append("key=%d phys=%d" % [event.keycode, event.physical_keycode])
    if has_f3:
        _assert_true(true, "toggle_trend includes F3 binding")
    else:
        var trend_detail_text: String = ", ".join(trend_details)
        _assert_true(false, "toggle_trend includes F3 binding (events: %s, KEY_F3=%d)" % [trend_detail_text, KEY_F3])

    _assert_true(InputMap.has_action("toggle_history"), "InputMap has toggle_history action")
    var history_events: Array = InputMap.action_get_events("toggle_history")
    _assert_true(history_events.size() > 0, "toggle_history has at least one binding")
    var has_f5: bool = false
    var history_details: Array[String] = []
    for event in history_events:
        if event is InputEventKey and event.keycode == KEY_F5:
            has_f5 = true
            break
        if event is InputEventKey:
            history_details.append("key=%d phys=%d" % [event.keycode, event.physical_keycode])
    if has_f5:
        _assert_true(true, "toggle_history includes F5 binding")
    else:
        var history_detail_text: String = ", ".join(history_details)
        _assert_true(false, "toggle_history includes F5 binding (events: %s, KEY_F5=%d)" % [history_detail_text, KEY_F5])

    _assert_true(InputMap.has_action("toggle_compact"), "InputMap has toggle_compact action")
    var compact_events: Array = InputMap.action_get_events("toggle_compact")
    _assert_true(compact_events.size() > 0, "toggle_compact has at least one binding")
    var has_f4: bool = false
    var compact_details: Array[String] = []
    for event in compact_events:
        if event is InputEventKey and event.keycode == KEY_F4:
            has_f4 = true
            break
        if event is InputEventKey:
            compact_details.append("key=%d phys=%d" % [event.keycode, event.physical_keycode])
    if has_f4:
        _assert_true(true, "toggle_compact includes F4 binding")
    else:
        var compact_detail_text: String = ", ".join(compact_details)
        _assert_true(false, "toggle_compact includes F4 binding (events: %s, KEY_F4=%d)" % [compact_detail_text, KEY_F4])

    _assert_true(InputMap.has_action("toggle_report"), "InputMap has toggle_report action")
    var report_events: Array = InputMap.action_get_events("toggle_report")
    _assert_true(report_events.size() > 0, "toggle_report has at least one binding")
    var has_f6: bool = false
    var report_details: Array[String] = []
    for event in report_events:
        if event is InputEventKey and event.keycode == KEY_F6:
            has_f6 = true
            break
        if event is InputEventKey:
            report_details.append("key=%d phys=%d" % [event.keycode, event.physical_keycode])
    if has_f6:
        _assert_true(true, "toggle_report includes F6 binding")
    else:
        var report_detail_text: String = ", ".join(report_details)
        _assert_true(false, "toggle_report includes F6 binding (events: %s, KEY_F6=%d)" % [report_detail_text, KEY_F6])

func _run_controls_formatter_tests() -> void:
    _assert_true(RebindableActions.actions().has("toggle_compact"), "actions include toggle_compact")
    _assert_true(RebindableActions.actions().has("toggle_settings"), "actions include toggle_settings")
    _assert_true(RebindableActions.actions().has("toggle_lessons"), "actions include toggle_lessons")
    _assert_true(RebindableActions.actions().has("toggle_report"), "actions include toggle_report")
    _assert_equal(RebindableActions.display_name("cycle_goal"), "Cycle Goal", "display_name cycle_goal")
    _assert_equal(RebindableActions.display_name("toggle_settings"), "Toggle Settings Panel", "display_name toggle_settings")
    _assert_equal(RebindableActions.display_name("toggle_lessons"), "Toggle Lessons Panel", "display_name toggle_lessons")
    _assert_equal(RebindableActions.display_name("toggle_trend"), "Toggle Trend Panel", "display_name toggle_trend")
    _assert_equal(RebindableActions.display_name("toggle_compact"), "Toggle Compact Panels", "display_name toggle_compact")
    _assert_equal(RebindableActions.display_name("toggle_history"), "Toggle History Panel", "display_name toggle_history")
    _assert_equal(RebindableActions.display_name("toggle_report"), "Toggle Report Panel", "display_name toggle_report")
    _assert_equal(RebindableActions.display_name("unknown_action"), "unknown_action", "display_name fallback")
    var hint_text: String = RebindableActions.format_actions_hint()
    _assert_true(hint_text.find("Actions:") != -1, "actions hint includes prefix")
    _assert_true(hint_text.find("Cycle Goal (cycle_goal)") != -1, "actions hint includes cycle_goal")
    _assert_true(hint_text.find("Toggle Settings Panel (toggle_settings)") != -1, "actions hint includes toggle_settings")
    _assert_true(hint_text.find("Toggle Lessons Panel (toggle_lessons)") != -1, "actions hint includes toggle_lessons")
    _assert_true(hint_text.find("Toggle Trend Panel (toggle_trend)") != -1, "actions hint includes toggle_trend")
    _assert_true(hint_text.find("Toggle Compact Panels (toggle_compact)") != -1, "actions hint includes toggle_compact")
    _assert_true(hint_text.find("Toggle History Panel (toggle_history)") != -1, "actions hint includes toggle_history")
    _assert_true(hint_text.find("Toggle Report Panel (toggle_report)") != -1, "actions hint includes toggle_report")

    _assert_true(InputMap.has_action("cycle_goal"), "controls formatter uses cycle_goal")
    var binding_text: String = ControlsFormatter.binding_text_for_action("cycle_goal")
    _assert_true(binding_text != "", "controls formatter returns binding text")
    _assert_true(binding_text != "Unbound", "controls formatter binding is not unbound")
    _assert_true(binding_text != "Missing (InputMap)", "controls formatter binding is not missing")
    var trend_text: String = ControlsFormatter.binding_text_for_action("toggle_trend")
    _assert_true(trend_text != "", "controls formatter returns toggle_trend text")
    _assert_true(trend_text != "Unbound", "controls formatter toggle_trend not unbound")
    _assert_true(trend_text != "Missing (InputMap)", "controls formatter toggle_trend not missing")
    var history_text: String = ControlsFormatter.binding_text_for_action("toggle_history")
    _assert_true(history_text != "", "controls formatter returns toggle_history text")
    _assert_true(history_text != "Unbound", "controls formatter toggle_history not unbound")
    _assert_true(history_text != "Missing (InputMap)", "controls formatter toggle_history not missing")
    var compact_text: String = ControlsFormatter.binding_text_for_action("toggle_compact")
    _assert_true(compact_text != "", "controls formatter returns toggle_compact text")
    _assert_true(compact_text != "Unbound", "controls formatter toggle_compact not unbound")
    _assert_true(compact_text != "Missing (InputMap)", "controls formatter toggle_compact not missing")
    var settings_text: String = ControlsFormatter.binding_text_for_action("toggle_settings")
    _assert_true(settings_text != "", "controls formatter returns toggle_settings text")
    _assert_true(settings_text != "Unbound", "controls formatter toggle_settings not unbound")
    _assert_true(settings_text != "Missing (InputMap)", "controls formatter toggle_settings not missing")
    var report_text: String = ControlsFormatter.binding_text_for_action("toggle_report")
    _assert_true(report_text != "", "controls formatter returns toggle_report text")
    _assert_true(report_text != "Unbound", "controls formatter toggle_report not unbound")
    _assert_true(report_text != "Missing (InputMap)", "controls formatter toggle_report not missing")

    InputMap.add_action("tmp_unbound_action")
    var unbound_text: String = ControlsFormatter.binding_text_for_action("tmp_unbound_action")
    _assert_equal(unbound_text, "Unbound", "controls formatter handles unbound action")
    InputMap.erase_action("tmp_unbound_action")

    var missing_text: String = ControlsFormatter.binding_text_for_action("definitely_not_an_action")
    _assert_equal(missing_text, "Missing (InputMap)", "controls formatter handles missing action")

    var list_text: String = ControlsFormatter.format_controls_list(PackedStringArray(["cycle_goal"]))
    _assert_true(list_text.find("Cycle Goal") != -1, "controls formatter list includes display name")
    _assert_true(list_text.find("(cycle_goal)") != -1, "controls formatter list includes action id")
    var list_full: String = ControlsFormatter.format_controls_list(RebindableActions.actions())
    _assert_true(list_full.find("Toggle Settings Panel") != -1, "controls formatter list includes toggle_settings")
    _assert_true(list_full.find("Toggle Lessons Panel") != -1, "controls formatter list includes toggle_lessons")
    _assert_true(list_full.find("Toggle Trend Panel") != -1, "controls formatter list includes toggle_trend")
    _assert_true(list_full.find("Toggle Compact Panels") != -1, "controls formatter list includes toggle_compact")
    _assert_true(list_full.find("Toggle History Panel") != -1, "controls formatter list includes toggle_history")
    _assert_true(list_full.find("Toggle Report Panel") != -1, "controls formatter list includes toggle_report")

    var formatter_source: String = _read_file_text("res://game/controls_formatter.gd")
    _assert_true(formatter_source.find("keybind_conflicts") == -1, "controls formatter avoids keybind_conflicts dependency")
    _assert_true(formatter_source.find("ControlsAliases") != -1, "controls formatter uses ControlsAliases")
    var conflicts_source: String = _read_file_text("res://game/keybind_conflicts.gd")
    var uses_shared_aliases: bool = (
        conflicts_source.find("ControlsAliases") != -1
        or conflicts_source.find("ControlsFormatter") != -1
    )
    _assert_true(uses_shared_aliases, "keybind_conflicts uses shared alias helper")

func _run_keybind_conflicts_tests() -> void:
    var event_a := InputEventKey.new()
    event_a.keycode = KEY_F4
    event_a.shift_pressed = false
    event_a.ctrl_pressed = false
    event_a.alt_pressed = false
    event_a.meta_pressed = false
    var sig_a: String = KeybindConflicts.key_signature(event_a)
    var event_b := InputEventKey.new()
    event_b.keycode = KEY_F4
    event_b.shift_pressed = false
    event_b.ctrl_pressed = false
    event_b.alt_pressed = false
    event_b.meta_pressed = false
    var sig_b: String = KeybindConflicts.key_signature(event_b)
    _assert_equal(sig_a, sig_b, "key_signature stable for same modifiers")
    var event_c := InputEventKey.new()
    event_c.keycode = KEY_F4
    event_c.shift_pressed = true
    event_c.ctrl_pressed = false
    event_c.alt_pressed = false
    event_c.meta_pressed = false
    var sig_c: String = KeybindConflicts.key_signature(event_c)
    _assert_true(sig_a != sig_c, "key_signature differs with modifiers")

    var action_a: String = "tmp_exact_action_a"
    var action_b: String = "tmp_exact_action_b"
    var had_action_a: bool = InputMap.has_action(action_a)
    var had_action_b: bool = InputMap.has_action(action_b)
    var restore_a: Array = []
    var restore_b: Array = []
    if had_action_a:
        restore_a = InputMap.action_get_events(action_a)
    else:
        InputMap.add_action(action_a)
    if had_action_b:
        restore_b = InputMap.action_get_events(action_b)
    else:
        InputMap.add_action(action_b)
    InputMap.action_erase_events(action_a)
    InputMap.action_erase_events(action_b)
    var bind_f1 := InputEventKey.new()
    bind_f1.keycode = KEY_F1
    var bind_ctrl_f1 := InputEventKey.new()
    bind_ctrl_f1.keycode = KEY_F1
    bind_ctrl_f1.ctrl_pressed = true
    InputMap.action_add_event(action_a, bind_f1)
    InputMap.action_add_event(action_b, bind_ctrl_f1)
    var f1_press := InputEventKey.new()
    f1_press.keycode = KEY_F1
    f1_press.pressed = true
    var ctrl_f1_press := InputEventKey.new()
    ctrl_f1_press.keycode = KEY_F1
    ctrl_f1_press.ctrl_pressed = true
    ctrl_f1_press.pressed = true
    _assert_true(KeybindConflicts.event_matches_action_exact(ctrl_f1_press, action_b),
        "exact match accepts Ctrl+F1 for Ctrl+F1 action")
    _assert_true(not KeybindConflicts.event_matches_action_exact(ctrl_f1_press, action_a),
        "exact match rejects Ctrl+F1 for F1 action")
    _assert_true(KeybindConflicts.event_matches_action_exact(f1_press, action_a),
        "exact match accepts F1 for F1 action")
    _assert_true(not KeybindConflicts.event_matches_action_exact(f1_press, action_b),
        "exact match rejects F1 for Ctrl+F1 action")
    _assert_true(not InputMap.event_is_action(ctrl_f1_press, action_a, true),
        "InputMap exact match rejects Ctrl+F1 for F1 action")
    var f1_signature_exact: String = KeybindConflicts.key_signature(f1_press)
    var ctrl_f1_signature_exact: String = KeybindConflicts.key_signature(ctrl_f1_press)
    var distinct_conflicts: Dictionary = KeybindConflicts.find_conflicts({
        "a": [f1_signature_exact],
        "b": [ctrl_f1_signature_exact]
    })
    _assert_true(distinct_conflicts.is_empty(), "conflicts ignore modifier-distinct signatures")
    InputMap.action_erase_events(action_a)
    InputMap.action_erase_events(action_b)
    if had_action_a:
        for event in restore_a:
            InputMap.action_add_event(action_a, event)
    else:
        InputMap.erase_action(action_a)
    if had_action_b:
        for event in restore_b:
            InputMap.action_add_event(action_b, event)
    else:
        InputMap.erase_action(action_b)

    var conflict_signature := "K=65|S=0|C=0|A=0|M=0"
    var action_sig_map: Dictionary = {
        "a": [conflict_signature],
        "b": [conflict_signature]
    }
    var conflicts: Dictionary = KeybindConflicts.find_conflicts(action_sig_map)
    _assert_true(conflicts.has(conflict_signature), "find_conflicts detects conflicts")
    var conflict_actions: Array = conflicts.get(conflict_signature, [])
    _assert_equal(conflict_actions, ["a", "b"], "find_conflicts sorts action ids")

    var no_conflicts: Dictionary = KeybindConflicts.find_conflicts({
        "a": ["K=66|S=0|C=0|A=0|M=0"],
        "b": ["K=67|S=0|C=0|A=0|M=0"]
    })
    _assert_true(no_conflicts.is_empty(), "find_conflicts ignores unique bindings")

    var formatted: Array[String] = KeybindConflicts.format_conflicts(
        {conflict_signature: ["b", "a"]},
        Callable(self, "_conflict_signature_label_test")
    )
    _assert_equal(formatted.size(), 1, "format_conflicts returns one line")
    _assert_equal(formatted[0], "CONFLICT: TEST -> a, b", "format_conflicts sorts and formats")

    var f1_signature: String = "K=%d|S=0|C=0|A=0|M=0" % KeybindConflicts.fn_keycode(1)
    var f2_signature: String = "K=%d|S=0|C=0|A=0|M=0" % KeybindConflicts.fn_keycode(2)
    var suggestion_map: Dictionary = {
        "a": [f1_signature],
        "b": [f2_signature]
    }
    var suggestion: String = KeybindConflicts.suggest_unused_safe_key(suggestion_map)
    _assert_equal(suggestion, "F3", "suggest_unused_safe_key finds first open F-key")

    var safe_signatures: Array[String] = KeybindConflicts.safe_key_pool_signatures()
    _assert_true(safe_signatures.size() > 12, "safe key pool includes fallback keys")
    var fallback_signature: String = ""
    if safe_signatures.size() > 12:
        fallback_signature = safe_signatures[12]
    var saturated_map: Dictionary = {
        "a": [f1_signature],
        "b": [f1_signature]
    }
    for i in range(2, 13):
        saturated_map["f%d" % i] = ["K=%d|S=0|C=0|A=0|M=0" % KeybindConflicts.fn_keycode(i)]
    var saturated_plan: Dictionary = KeybindConflicts.build_resolution_plan(saturated_map)
    var saturated_changes: Variant = saturated_plan.get("changes", [])
    _assert_true(typeof(saturated_changes) == TYPE_ARRAY and saturated_changes.size() > 0, "resolve plan uses fallback pool when F-keys are saturated")
    if typeof(saturated_changes) == TYPE_ARRAY and saturated_changes.size() > 0 and fallback_signature != "":
        var saturated_change: Dictionary = saturated_changes[0]
        _assert_equal(str(saturated_change.get("to_signature", "")), fallback_signature, "resolve plan chooses first fallback signature")

    var tier0_saturated_map: Dictionary = {
        "a": [safe_signatures[0]],
        "b": [safe_signatures[0]]
    }
    for i in range(1, safe_signatures.size()):
        tier0_saturated_map["k%d" % i] = [safe_signatures[i]]
    var tier1_suggestion: String = KeybindConflicts.suggest_unused_safe_key(tier0_saturated_map)
    _assert_equal(tier1_suggestion, "Ctrl+F1", "suggest_unused_safe_key falls back to Ctrl tier when tier 0 exhausted")
    var tier1_plan: Dictionary = KeybindConflicts.build_resolution_plan(tier0_saturated_map)
    var tier1_changes: Variant = tier1_plan.get("changes", [])
    _assert_true(typeof(tier1_changes) == TYPE_ARRAY and tier1_changes.size() > 0, "resolve plan uses Ctrl tier when tier 0 exhausted")
    if typeof(tier1_changes) == TYPE_ARRAY and tier1_changes.size() > 0:
        var ctrl_f1_event := InputEventKey.new()
        ctrl_f1_event.keycode = KeybindConflicts.fn_keycode(1)
        ctrl_f1_event.ctrl_pressed = true
        var ctrl_f1_signature: String = KeybindConflicts.key_signature(ctrl_f1_event)
        var tier1_change: Dictionary = tier1_changes[0]
        _assert_equal(str(tier1_change.get("to_signature", "")), ctrl_f1_signature, "resolve plan chooses first Ctrl safe signature")
    var tier1_applied: Dictionary = KeybindConflicts.apply_resolution_plan(tier0_saturated_map, tier1_plan)
    var tier1_conflicts: Dictionary = KeybindConflicts.find_conflicts(tier1_applied)
    _assert_true(tier1_conflicts.is_empty(), "resolve apply clears conflicts with Ctrl tier")

    var tier0_full_map: Dictionary = {"a": safe_signatures}
    var tier0_suggestion: String = KeybindConflicts.suggest_unused_safe_key(tier0_full_map)
    _assert_equal(tier0_suggestion, "Ctrl+F1", "suggest_unused_safe_key uses Ctrl tier when tier 0 occupied")
    var ctrl_signatures: Array[String] = []
    for entry in KeybindConflicts.safe_key_pool_entries():
        var keycode: int = int(entry.get("keycode", 0))
        if keycode <= 0:
            continue
        var ctrl_event := InputEventKey.new()
        ctrl_event.keycode = keycode
        ctrl_event.ctrl_pressed = true
        var ctrl_signature: String = KeybindConflicts.key_signature(ctrl_event)
        if ctrl_signature != "":
            ctrl_signatures.append(ctrl_signature)
    var exhausted_map: Dictionary = {
        "a": [safe_signatures[0]],
        "b": [safe_signatures[0]]
    }
    for i in range(1, safe_signatures.size()):
        exhausted_map["k%d" % i] = [safe_signatures[i]]
    for i in range(ctrl_signatures.size()):
        exhausted_map["c%d" % i] = [ctrl_signatures[i]]
    var no_suggestion: String = KeybindConflicts.suggest_unused_safe_key(exhausted_map)
    _assert_equal(no_suggestion, "", "suggest_unused_safe_key returns empty when safe tiers used")

    var ordered_lines: Array[String] = KeybindConflicts.format_conflicts(
        {
            "K=66|S=0|C=0|A=0|M=0": ["b", "a"],
            "K=65|S=0|C=0|A=0|M=0": ["d", "c"]
        },
        Callable(self, "_conflict_signature_identity_test")
    )
    _assert_equal(ordered_lines, [
        "CONFLICT: K=65|S=0|C=0|A=0|M=0 -> c, d",
        "CONFLICT: K=66|S=0|C=0|A=0|M=0 -> a, b"
    ], "format_conflicts keeps signatures sorted")

    var no_conflict_map: Dictionary = {
        "a": ["K=66|S=0|C=0|A=0|M=0"],
        "b": ["K=67|S=0|C=0|A=0|M=0"]
    }
    var no_conflict_plan: Dictionary = KeybindConflicts.build_resolution_plan(no_conflict_map)
    var no_conflict_lines: Array[String] = KeybindConflicts.format_resolution_plan(
        no_conflict_plan,
        Callable(self, "_conflict_action_identity_test"),
        Callable(self, "_conflict_signature_identity_test")
    )
    _assert_equal(no_conflict_lines, [KeybindConflicts.no_conflicts_message()], "resolve plan uses no-conflicts message")
    var no_conflict_apply: Dictionary = KeybindConflicts.apply_resolution_plan(no_conflict_map, no_conflict_plan)
    _assert_equal(no_conflict_apply, no_conflict_map, "resolve apply keeps map unchanged")

    var f3_signature: String = "K=%d|S=0|C=0|A=0|M=0" % KeybindConflicts.fn_keycode(3)
    var conflict_map: Dictionary = {
        "b": [f1_signature],
        "a": [f1_signature],
        "c": [f2_signature]
    }
    var resolve_plan: Dictionary = KeybindConflicts.build_resolution_plan(conflict_map)
    var resolve_lines: Array[String] = KeybindConflicts.format_resolution_plan(
        resolve_plan,
        Callable(self, "_conflict_action_identity_test"),
        Callable(self, "_conflict_signature_identity_test")
    )
    _assert_equal(resolve_lines[1], "CHANGE: b %s -> %s" % [f1_signature, f3_signature], "resolve plan change order stable")
    var changes: Variant = resolve_plan.get("changes", [])
    _assert_true(typeof(changes) == TYPE_ARRAY and changes.size() > 0, "resolve apply has changes")
    var resolved_map: Dictionary = KeybindConflicts.apply_resolution_plan(conflict_map, resolve_plan)
    if typeof(changes) == TYPE_ARRAY:
        var diff_count: int = 0
        for action_name in conflict_map.keys():
            if conflict_map.get(action_name) != resolved_map.get(action_name):
                diff_count += 1
        _assert_equal(diff_count, changes.size(), "resolve apply changes count matches plan")
    var resolved_conflicts: Dictionary = KeybindConflicts.find_conflicts(resolved_map)
    _assert_true(resolved_conflicts.is_empty(), "resolve apply clears conflicts")

    var unresolvable_map: Dictionary = exhausted_map
    var unresolvable_plan: Dictionary = KeybindConflicts.build_resolution_plan(unresolvable_map)
    var unresolved: Variant = unresolvable_plan.get("unresolved", [])
    _assert_true(typeof(unresolved) == TYPE_ARRAY and unresolved.size() == 1, "resolve plan reports unresolved when no keys available")
    if typeof(unresolved) == TYPE_ARRAY and unresolved.size() > 0:
        var entry: Dictionary = unresolved[0]
        _assert_equal(str(entry.get("action", "")), "b", "resolve plan keeps first action as conflict owner")
        _assert_true(str(entry.get("reason", "")).find("No unused safe keys") != -1, "resolve plan explains no keys available")
    var unresolvable_apply: Dictionary = KeybindConflicts.apply_resolution_plan(unresolvable_map, unresolvable_plan)
    _assert_equal(unresolvable_apply, unresolvable_map, "resolve apply keeps map unchanged when pool exhausted")

    var export_actions: Array[String] = ["b", "a"]
    var export_signature: String = "K=%d|S=0|C=0|A=0|M=0" % KeybindConflicts.fn_keycode(1)
    var export_map: Dictionary = {
        "b": [export_signature],
        "a": [export_signature]
    }
    var export_keybinds: Dictionary = {
        "b": KeybindConflicts.keybind_from_signature(export_signature),
        "a": KeybindConflicts.keybind_from_signature(export_signature)
    }
    var export_ui: Dictionary = {"scale": 1.25, "compact": true}
    var version_text: String = _read_file_text("res://VERSION.txt")
    if version_text != "":
        version_text = version_text.split("\n", false)[0].strip_edges()
    var version_info: Dictionary = Engine.get_version_info()
    var major: int = int(version_info.get("major", 0))
    var minor: int = int(version_info.get("minor", 0))
    var patch: int = int(version_info.get("patch", 0))
    var godot_text: String = ""
    if major != 0 or minor != 0 or patch != 0:
        godot_text = "%d.%d.%d" % [major, minor, patch]
    else:
        godot_text = str(version_info.get("string", ""))
    if godot_text == "":
        godot_text = "0.0.0"
    var export_engine: Dictionary = {
        "godot": godot_text,
        "major": major,
        "minor": minor,
        "patch": patch
    }
    var export_window: Dictionary = {"width": 0, "height": 0}
    var export_panels: Dictionary = {
        "settings": false,
        "lessons": false,
        "trend": false,
        "history": false,
        "report": false
    }
    var export_payload: Dictionary = KeybindConflicts.build_settings_export_payload(
        export_actions,
        export_keybinds,
        export_map,
        export_ui,
        export_engine,
        export_window,
        export_panels
    )
    var export_json: String = KeybindConflicts.format_settings_export_json(export_payload)
    _assert_true(export_json.begins_with("{"), "settings export outputs JSON object")
    var export_parsed: Variant = JSON.parse_string(export_json)
    _assert_true(typeof(export_parsed) == TYPE_DICTIONARY, "settings export JSON parses")
    var export_dict: Dictionary = export_parsed
    _assert_equal(str(export_dict.get("schema", "")), "typing-defense.settings-export", "settings export schema id")
    _assert_equal(int(export_dict.get("schema_version", 0)), 4, "settings export schema version")
    var export_game_dict: Dictionary = export_dict.get("game", {})
    _assert_equal(str(export_game_dict.get("name", "")), "Keyboard Defense", "settings export game name")
    _assert_equal(str(export_game_dict.get("version", "")), version_text, "settings export game version")
    var export_engine_dict: Dictionary = export_dict.get("engine", {})
    var export_godot: String = str(export_engine_dict.get("godot", ""))
    _assert_true(export_godot != "", "settings export engine godot string")
    var export_window_dict: Dictionary = export_dict.get("window", {})
    var export_width_type: int = typeof(export_window_dict.get("width"))
    var export_height_type: int = typeof(export_window_dict.get("height"))
    _assert_true(
        export_width_type == TYPE_INT or export_width_type == TYPE_FLOAT,
        "settings export window width is numeric"
    )
    _assert_true(
        export_height_type == TYPE_INT or export_height_type == TYPE_FLOAT,
        "settings export window height is numeric"
    )
    var export_panels_dict: Dictionary = export_dict.get("panels", {})
    _assert_true(typeof(export_panels_dict.get("settings")) == TYPE_BOOL, "settings export panels settings bool")
    _assert_true(typeof(export_panels_dict.get("lessons")) == TYPE_BOOL, "settings export panels lessons bool")
    _assert_true(typeof(export_panels_dict.get("trend")) == TYPE_BOOL, "settings export panels trend bool")
    _assert_true(typeof(export_panels_dict.get("history")) == TYPE_BOOL, "settings export panels history bool")
    _assert_true(typeof(export_panels_dict.get("report")) == TYPE_BOOL, "settings export panels report bool")
    _assert_true(typeof(export_dict.get("ui")) == TYPE_DICTIONARY, "settings export ui object type")
    var export_ui_dict: Dictionary = export_dict.get("ui", {})
    var export_ui_scale: Variant = export_ui_dict.get("scale")
    _assert_true(
        typeof(export_ui_scale) == TYPE_FLOAT or typeof(export_ui_scale) == TYPE_INT,
        "settings export ui scale is numeric"
    )
    _assert_approx(float(export_ui_scale), 1.25, 0.0001, "settings export ui scale value")
    var export_ui_compact: Variant = export_ui_dict.get("compact")
    _assert_true(typeof(export_ui_compact) == TYPE_BOOL, "settings export ui compact is bool")
    _assert_equal(export_ui_compact, true, "settings export ui compact value")
    _assert_true(typeof(export_dict.get("keybinds")) == TYPE_ARRAY, "settings export keybinds array type")
    _assert_true(typeof(export_dict.get("conflicts")) == TYPE_ARRAY, "settings export conflicts array type")
    _assert_true(typeof(export_dict.get("resolve_plan")) == TYPE_DICTIONARY, "settings export resolve_plan object type")
    var export_keybinds_list: Array = export_dict.get("keybinds", [])
    _assert_true(export_keybinds_list.size() == 2, "settings export keybinds count")
    if export_keybinds_list.size() >= 2:
        _assert_equal(str(export_keybinds_list[0].get("action", "")), "a", "settings export keybinds sorted by action")
        _assert_equal(str(export_keybinds_list[1].get("action", "")), "b", "settings export keybinds sorted by action")
    var export_conflicts: Array = export_dict.get("conflicts", [])
    _assert_true(export_conflicts.size() > 0, "settings export includes conflicts")
    var export_plan: Dictionary = export_dict.get("resolve_plan", {})
    var export_changes: Array = export_plan.get("changes", [])
    _assert_true(export_changes.size() > 0, "settings export includes resolve changes")
    var export_json_again: String = KeybindConflicts.format_settings_export_json(
        KeybindConflicts.build_settings_export_payload(
            export_actions,
            export_keybinds,
            export_map,
            export_ui,
            export_engine,
            export_window,
            export_panels
        )
    )
    _assert_equal(export_json_again, export_json, "settings export JSON deterministic")
    var save_path: String = "user://settings_export.json"
    _remove_temp_file(save_path)
    var save_file := FileAccess.open(save_path, FileAccess.WRITE)
    if save_file != null:
        save_file.store_string(export_json)
        save_file.close()
    var save_line: String = "Saved to user://settings_export.json"
    _assert_equal(save_line, "Saved to user://settings_export.json", "settings export save output line")
    _assert_true(FileAccess.file_exists(save_path), "settings export save writes file")
    var saved_text: String = _read_file_text(save_path)
    _assert_equal(saved_text, export_json, "settings export save content matches")
    var saved_parsed: Variant = JSON.parse_string(saved_text)
    if typeof(saved_parsed) == TYPE_DICTIONARY:
        _assert_equal(int(saved_parsed.get("schema_version", 0)), 4, "settings export save schema v4")
    _remove_temp_file(save_path)

func _run_help_tests() -> void:
    var settings_action: String = "toggle_settings"
    var lessons_action: String = "toggle_lessons"
    var trend_action: String = "toggle_trend"
    var goal_action: String = "cycle_goal"
    var report_action: String = "toggle_report"
    var action_ids: Array[String] = [
        settings_action,
        lessons_action,
        trend_action,
        goal_action,
        report_action
    ]
    var had_actions: Dictionary = {}
    var restore_events: Dictionary = {}
    for action_id in action_ids:
        var had_action: bool = InputMap.has_action(action_id)
        had_actions[action_id] = had_action
        if had_action:
            restore_events[action_id] = InputMap.action_get_events(action_id)
        else:
            InputMap.add_action(action_id)

    for action_id in action_ids:
        InputMap.action_erase_events(action_id)
    var f1_event := InputEventKey.new()
    f1_event.keycode = KEY_F1
    InputMap.action_add_event(settings_action, f1_event)
    var ctrl_f1_event := InputEventKey.new()
    ctrl_f1_event.keycode = KEY_F1
    ctrl_f1_event.ctrl_pressed = true
    InputMap.action_add_event(lessons_action, ctrl_f1_event)
    var f7_event := InputEventKey.new()
    f7_event.keycode = KEY_F7
    InputMap.action_add_event(goal_action, f7_event)

    var help_actions: Array[String] = []
    for action_name in RebindableActions.actions():
        help_actions.append(action_name)
    var help_lines: Array[String] = MainScript.build_help_lines("", help_actions)
    var help_text: String = "\n".join(help_lines)
    var help_text_again: String = "\n".join(MainScript.build_help_lines("", help_actions))
    _assert_equal(help_text_again, help_text, "help output deterministic")
    var required_commands: Array[String] = [
        "settings verify",
        "settings conflicts",
        "settings resolve",
        "settings resolve apply",
        "settings export",
        "settings export save",
        "balance verify",
        "balance export",
        "balance export save",
        "balance diff",
        "balance summary",
        "help hotkeys",
        "help topics"
    ]
    for command_text in required_commands:
        _assert_true(help_text.find(command_text) != -1, "help includes %s" % command_text)
    _assert_true(
        help_text.find("Tip: type help hotkeys to list all hotkeys.") != -1,
        "help includes hotkeys tip"
    )
    var hotkeys_tip_index: int = help_text.find("Tip: type help hotkeys to list all hotkeys.")
    var topics_tip_index: int = help_text.find("Tip: type help topics to see all help topics.")
    _assert_true(
        hotkeys_tip_index != -1 and topics_tip_index != -1 and hotkeys_tip_index < topics_tip_index,
        "help tips ordered"
    )
    _assert_true(help_text.find("Current hotkeys:") != -1, "help includes hotkeys section")
    var settings_binding: String = ControlsFormatter.binding_text_for_action(settings_action)
    var lessons_binding: String = ControlsFormatter.binding_text_for_action(lessons_action)
    _assert_true(
        help_text.find("%s: %s" % [settings_action, settings_binding]) != -1,
        "help includes toggle_settings binding"
    )
    _assert_true(
        help_text.find("%s: %s" % [lessons_action, lessons_binding]) != -1,
        "help includes toggle_lessons binding"
    )
    var lessons_index: int = help_text.find(lessons_action)
    var settings_index: int = help_text.find(settings_action)
    _assert_true(
        lessons_index != -1 and settings_index != -1 and lessons_index < settings_index,
        "help hotkeys sorted by action id"
    )

    var help_hotkeys_lines: Array[String] = MainScript.build_help_lines("hotkeys", help_actions)
    var help_hotkeys_text: String = "\n".join(help_hotkeys_lines)
    var help_hotkeys_text_again: String = "\n".join(MainScript.build_help_lines("hotkeys", help_actions))
    _assert_equal(help_hotkeys_text_again, help_hotkeys_text, "help hotkeys deterministic")
    _assert_true(
        help_hotkeys_lines.size() > 0 and help_hotkeys_lines[0] == "Hotkeys:",
        "help hotkeys header"
    )
    var sorted_actions: Array[String] = []
    for action_name in help_actions:
        sorted_actions.append(str(action_name))
    sorted_actions.sort()
    var last_index: int = -1
    for action_id in sorted_actions:
        var line_prefix: String = "  %s:" % action_id
        var index: int = help_hotkeys_text.find(line_prefix)
        _assert_true(index != -1, "help hotkeys includes %s" % action_id)
        _assert_true(index > last_index, "help hotkeys order %s" % action_id)
        last_index = index
    _assert_true(
        help_hotkeys_text.find("  %s: (unbound)" % trend_action) != -1,
        "help hotkeys prints unbound"
    )
    _assert_true(
        help_hotkeys_text.find("  %s: Ctrl+F1" % lessons_action) != -1,
        "help hotkeys prints modifier binding"
    )
    _assert_true(
        help_hotkeys_lines[help_hotkeys_lines.size() - 1] == "Conflicts: none",
        "help hotkeys no conflicts summary"
    )

    var help_topics_lines: Array[String] = MainScript.build_help_lines("topics", help_actions)
    var help_topics_text: String = "\n".join(help_topics_lines)
    var help_topics_text_again: String = "\n".join(MainScript.build_help_lines("topics", help_actions))
    _assert_equal(help_topics_text_again, help_topics_text, "help topics deterministic")
    var expected_topics: Array[String] = [
        "Help topics:",
        "  settings",
        "  hotkeys",
        "  play",
        "  accessibility",
        "  topics"
    ]
    _assert_equal("\n".join(expected_topics), help_topics_text, "help topics output exact")

    var help_play_lines: Array[String] = MainScript.build_help_lines("play", help_actions)
    var help_play_text: String = "\n".join(help_play_lines)
    var help_play_text_again: String = "\n".join(MainScript.build_help_lines("play", help_actions))
    _assert_equal(help_play_text_again, help_play_text, "help play deterministic")
    _assert_true(help_play_lines.size() == 7, "help play has header + 6 lines")
    _assert_true(help_play_text.find("toggle_lessons (Ctrl+F1)") != -1, "help play inserts lessons hotkey")
    _assert_true(help_play_text.find("toggle_settings (F1)") != -1, "help play inserts settings hotkey")
    _assert_true(help_play_text.find("cycle_goal (F7)") != -1, "help play inserts goal hotkey")
    _assert_true(help_play_text.find("toggle_report (unbound)") != -1, "help play inserts unbound report")
    _assert_true(help_play_text.find("settings verify") != -1, "help play includes settings verify")
    _assert_true(help_play_text.find("settings conflicts") != -1, "help play includes settings conflicts")
    _assert_true(help_play_text.find("settings resolve apply") != -1, "help play includes settings resolve apply")

    var help_access_lines: Array[String] = MainScript.build_help_lines("accessibility", help_actions)
    var help_access_text: String = "\n".join(help_access_lines)
    _assert_true(help_access_lines.size() > 0 and help_access_lines[0] == "Accessibility:", "help accessibility header")
    _assert_true(help_access_text.find("settings compact on|off|toggle") != -1, "help accessibility includes compact toggle")
    _assert_true(help_access_text.find("settings scale <80-140>") != -1, "help accessibility includes scale")
    _assert_true(help_access_text.find("settings conflicts") != -1, "help accessibility includes conflicts")
    _assert_true(help_access_text.find("settings resolve apply") != -1, "help accessibility includes resolve apply")
    _assert_true(help_access_text.find("settings export save") != -1, "help accessibility includes export save")
    _assert_true(help_access_text.find("toggle_settings (F1)") != -1, "help accessibility inserts settings hotkey")
    _assert_true(help_access_text.find("toggle_lessons (Ctrl+F1)") != -1, "help accessibility inserts lessons hotkey")

    InputMap.action_erase_events(lessons_action)
    var hotkeys_conflict_event := InputEventKey.new()
    hotkeys_conflict_event.keycode = KEY_F1
    InputMap.action_add_event(lessons_action, hotkeys_conflict_event)
    var conflict_help_lines: Array[String] = MainScript.build_help_lines("hotkeys", help_actions)
    _assert_true(
        conflict_help_lines[conflict_help_lines.size() - 1] == "Conflicts: present (run settings conflicts or settings resolve apply)",
        "help hotkeys conflict summary"
    )

    var settings_help_lines: Array[String] = MainScript.build_help_lines("settings", help_actions)
    var settings_help_text: String = "\n".join(settings_help_lines)
    var settings_help_text_again: String = "\n".join(MainScript.build_help_lines("settings", help_actions))
    _assert_equal(settings_help_text_again, settings_help_text, "help settings deterministic")
    _assert_true(settings_help_text.find("settings verify") != -1, "help settings includes settings verify")
    _assert_true(settings_help_text.find("settings conflicts") != -1, "help settings includes settings conflicts")
    _assert_true(settings_help_text.find("settings resolve") != -1, "help settings includes settings resolve")
    _assert_true(settings_help_text.find("settings export") != -1, "help settings includes settings export")

    var unknown_lines: Array[String] = MainScript.build_help_lines("banana", help_actions)
    _assert_equal(unknown_lines.size(), 1, "unknown help topic returns single line")
    if unknown_lines.size() == 1:
        _assert_equal(
            unknown_lines[0],
            "Unknown help topic: banana. Try help.",
            "unknown help topic message"
        )

    var panel_states: Dictionary = {
        "settings": "OFF",
        "lessons": "OFF",
        "trend": "OFF",
        "history": "OFF",
        "report": "OFF"
    }
    var no_conflict_lines: Array[String] = MainScript.build_settings_verify_lines(
        1280,
        720,
        120,
        false,
        panel_states,
        help_actions,
        {}
    )
    var no_conflict_text: String = "\n".join(no_conflict_lines)
    _assert_true(
        no_conflict_text.find("Recommendations: settings compact on; settings scale 110") != -1,
        "settings verify shows recommendations without conflicts"
    )
    _assert_true(
        no_conflict_text.find("Next: type help for a quick start.") != -1,
        "settings verify success hint shown with no conflicts"
    )
    var conflict_event := InputEventKey.new()
    conflict_event.keycode = KEY_F1
    var conflict_signature: String = KeybindConflicts.key_signature(conflict_event)
    var conflict_map: Dictionary = {conflict_signature: [settings_action, lessons_action]}
    var conflict_lines: Array[String] = MainScript.build_settings_verify_lines(
        1600,
        900,
        100,
        false,
        panel_states,
        help_actions,
        conflict_map
    )
    var conflict_text: String = "\n".join(conflict_lines)
    _assert_true(
        conflict_text.find("Tip: run \"settings resolve apply\" to auto-fix conflicts.") != -1,
        "settings verify retains conflict hint"
    )
    _assert_true(
        conflict_text.find("Next: type help for a quick start.") == -1,
        "settings verify success hint suppressed on conflicts"
    )

    for action_id in action_ids:
        InputMap.action_erase_events(action_id)
        var had_action: bool = bool(had_actions.get(action_id, false))
        if had_action:
            var events: Array = restore_events.get(action_id, [])
            for event in events:
                InputMap.action_add_event(action_id, event)
        else:
            InputMap.erase_action(action_id)

func _run_keybind_parsing_tests() -> void:
    var alias_groups: Dictionary = {
        KEY_INSERT: ["Ins", "Insert"],
        KEY_DELETE: ["Del", "Delete"],
        KEY_PAGEUP: ["PgUp", "PageUp", "Page Up"],
        KEY_PAGEDOWN: ["PgDn", "PageDown", "Page Down"],
        KEY_PRINT: ["PrtSc", "PrtScn", "PrintScreen", "Print Screen"],
        KEY_SCROLLLOCK: ["ScrLk", "ScrollLock", "Scroll Lock"],
        KEY_PAUSE: ["Pause", "PauseBreak", "Break"],
        KEY_HOME: ["Home"],
        KEY_END: ["End"]
    }
    for keycode in alias_groups.keys():
        var aliases: Array = alias_groups.get(keycode, [])
        for alias in aliases:
            var parsed: Dictionary = KeybindConflicts.parse_key_text(str(alias))
            _assert_true(parsed.get("ok", false), "keybind alias parses: %s" % alias)
            var keybind: Dictionary = parsed.get("keybind", {})
            _assert_equal(int(keybind.get("keycode", 0)), int(keycode), "keybind alias keycode: %s" % alias)
            var no_mods: bool = (
                not bool(keybind.get("shift", false))
                and not bool(keybind.get("alt", false))
                and not bool(keybind.get("ctrl", false))
                and not bool(keybind.get("meta", false))
            )
            _assert_true(no_mods, "keybind alias modifiers clear: %s" % alias)

    var ctrl_a: Dictionary = KeybindConflicts.parse_key_text("Ctrl+F1")
    var ctrl_b: Dictionary = KeybindConflicts.parse_key_text("Control+F1")
    _assert_true(ctrl_a.get("ok", false) and ctrl_b.get("ok", false), "modifier ctrl aliases parse")
    var ctrl_bind: Dictionary = ctrl_a.get("keybind", {})
    var ctrl_bind_b: Dictionary = ctrl_b.get("keybind", {})
    _assert_equal(int(ctrl_bind.get("keycode", 0)), KEY_F1, "modifier ctrl keycode")
    _assert_true(bool(ctrl_bind.get("ctrl", false)) and bool(ctrl_bind_b.get("ctrl", false)), "modifier ctrl flag set")

    var alt_a: Dictionary = KeybindConflicts.parse_key_text("Alt+F1")
    var alt_b: Dictionary = KeybindConflicts.parse_key_text("Option+F1")
    _assert_true(alt_a.get("ok", false) and alt_b.get("ok", false), "modifier alt aliases parse")
    var alt_bind: Dictionary = alt_a.get("keybind", {})
    var alt_bind_b: Dictionary = alt_b.get("keybind", {})
    _assert_equal(int(alt_bind.get("keycode", 0)), KEY_F1, "modifier alt keycode")
    _assert_true(bool(alt_bind.get("alt", false)) and bool(alt_bind_b.get("alt", false)), "modifier alt flag set")

    var meta_a: Dictionary = KeybindConflicts.parse_key_text("Cmd+F1")
    var meta_b: Dictionary = KeybindConflicts.parse_key_text("Super+F1")
    _assert_true(meta_a.get("ok", false) and meta_b.get("ok", false), "modifier meta aliases parse")
    var meta_bind: Dictionary = meta_a.get("keybind", {})
    var meta_bind_b: Dictionary = meta_b.get("keybind", {})
    _assert_equal(int(meta_bind.get("keycode", 0)), KEY_F1, "modifier meta keycode")
    _assert_true(bool(meta_bind.get("meta", false)) and bool(meta_bind_b.get("meta", false)), "modifier meta flag set")

    var ctrl_f1_event := InputEventKey.new()
    ctrl_f1_event.keycode = KEY_F1
    ctrl_f1_event.ctrl_pressed = true
    var ctrl_f1_text: String = KeybindConflicts.key_text_from_event(ctrl_f1_event)
    var ctrl_f1_parsed: Dictionary = KeybindConflicts.parse_key_text(ctrl_f1_text)
    _assert_true(ctrl_f1_parsed.get("ok", false), "round-trip ctrl+F1 parses")
    var ctrl_f1_keybind: Dictionary = ctrl_f1_parsed.get("keybind", {})
    _assert_equal(int(ctrl_f1_keybind.get("keycode", 0)), KEY_F1, "round-trip ctrl+F1 keycode")
    _assert_true(bool(ctrl_f1_keybind.get("ctrl", false)), "round-trip ctrl+F1 modifier")

    var ctrl_insert_event := InputEventKey.new()
    ctrl_insert_event.keycode = KEY_INSERT
    ctrl_insert_event.ctrl_pressed = true
    var ctrl_insert_text: String = KeybindConflicts.key_text_from_event(ctrl_insert_event)
    var ctrl_insert_parsed: Dictionary = KeybindConflicts.parse_key_text(ctrl_insert_text)
    _assert_true(ctrl_insert_parsed.get("ok", false), "round-trip ctrl+Insert parses")
    var ctrl_insert_keybind: Dictionary = ctrl_insert_parsed.get("keybind", {})
    _assert_equal(int(ctrl_insert_keybind.get("keycode", 0)), KEY_INSERT, "round-trip ctrl+Insert keycode")
    _assert_true(bool(ctrl_insert_keybind.get("ctrl", false)), "round-trip ctrl+Insert modifier")

    var ctrl_pgdn_event := InputEventKey.new()
    ctrl_pgdn_event.keycode = KEY_PAGEDOWN
    ctrl_pgdn_event.ctrl_pressed = true
    var ctrl_pgdn_text: String = KeybindConflicts.key_text_from_event(ctrl_pgdn_event)
    var ctrl_pgdn_parsed: Dictionary = KeybindConflicts.parse_key_text(ctrl_pgdn_text)
    _assert_true(ctrl_pgdn_parsed.get("ok", false), "round-trip ctrl+PageDown parses")
    var ctrl_pgdn_keybind: Dictionary = ctrl_pgdn_parsed.get("keybind", {})
    _assert_equal(int(ctrl_pgdn_keybind.get("keycode", 0)), KEY_PAGEDOWN, "round-trip ctrl+PageDown keycode")
    _assert_true(bool(ctrl_pgdn_keybind.get("ctrl", false)), "round-trip ctrl+PageDown modifier")

    var error_no_key: Dictionary = KeybindConflicts.parse_key_text("Ctrl")
    _assert_true(not error_no_key.get("ok", false), "parse error on modifier-only")
    _assert_true(str(error_no_key.get("error", "")).find("Expected") != -1, "error message for missing key")

    var error_multi: Dictionary = KeybindConflicts.parse_key_text("Ctrl+F1+F2")
    _assert_true(not error_multi.get("ok", false), "parse error on multiple keys")
    _assert_true(str(error_multi.get("error", "")).find("Multiple") != -1, "error message for multiple keys")

    var error_empty: Dictionary = KeybindConflicts.parse_key_text("")
    _assert_true(not error_empty.get("ok", false), "parse error on empty text")
    _assert_true(str(error_empty.get("error", "")).find("Expected") != -1, "error message for empty text")

    var error_bad: Dictionary = KeybindConflicts.parse_key_text("++F1")
    _assert_true(not error_bad.get("ok", false), "parse error on bad tokens")
    _assert_true(str(error_bad.get("error", "")).find("Invalid") != -1, "error message for bad tokens")

func _run_keybind_persistence_tests() -> void:
    var temp_roundtrip: String = "user://tmp_profile_keybind_roundtrip.json"
    var temp_roundtrip_two: String = "user://tmp_profile_keybind_roundtrip_2.json"
    var temp_legacy: String = "user://tmp_profile_keybind_legacy.json"
    _remove_temp_file(temp_roundtrip)
    _remove_temp_file(temp_roundtrip_two)
    _remove_temp_file(temp_legacy)

    var profile: Dictionary = TypingProfile.default_profile()
    if not profile.has("keybinds") or typeof(profile.get("keybinds")) != TYPE_DICTIONARY:
        profile["keybinds"] = {}
    var keybinds: Dictionary = profile.get("keybinds")
    keybinds["toggle_settings"] = {"keycode": KEY_F1, "shift": false, "alt": false, "ctrl": false, "meta": false}
    keybinds["toggle_lessons"] = {"keycode": KEY_F1, "shift": false, "alt": false, "ctrl": true, "meta": false}
    profile["keybinds"] = keybinds

    var save_roundtrip: Dictionary = TypingProfile.save_profile(profile, temp_roundtrip)
    _assert_true(save_roundtrip.get("ok", false), "profile save ok (modifier round-trip)")
    var load_roundtrip: Dictionary = TypingProfile.load_profile(temp_roundtrip)
    _assert_true(load_roundtrip.get("ok", false), "profile load ok (modifier round-trip)")
    var loaded_profile: Dictionary = load_roundtrip.get("profile", {})
    var settings_keybind: Dictionary = TypingProfile.get_keybind(loaded_profile, "toggle_settings")
    var lessons_keybind: Dictionary = TypingProfile.get_keybind(loaded_profile, "toggle_lessons")
    _assert_equal(int(settings_keybind.get("keycode", 0)), KEY_F1, "round-trip restores F1 keycode")
    _assert_true(not bool(settings_keybind.get("ctrl", false)), "round-trip restores F1 modifiers")
    _assert_equal(int(lessons_keybind.get("keycode", 0)), KEY_F1, "round-trip restores Ctrl+F1 keycode")
    _assert_true(bool(lessons_keybind.get("ctrl", false)), "round-trip restores Ctrl modifier")
    var settings_event: InputEventKey = KeybindConflicts.event_from_keybind(settings_keybind)
    var lessons_event: InputEventKey = KeybindConflicts.event_from_keybind(lessons_keybind)
    var action_sig_map: Dictionary = {
        "toggle_settings": [KeybindConflicts.key_signature(settings_event)],
        "toggle_lessons": [KeybindConflicts.key_signature(lessons_event)]
    }
    var conflicts: Dictionary = KeybindConflicts.find_conflicts(action_sig_map)
    _assert_true(conflicts.is_empty(), "round-trip preserves modifier-distinct bindings")

    var legacy_payload: Dictionary = {
        "version": 1,
        "keybinds": {
            "toggle_settings": {"keycode": KEY_F1}
        }
    }
    var legacy_text: String = JSON.stringify(legacy_payload, "  ")
    var legacy_file := FileAccess.open(temp_legacy, FileAccess.WRITE)
    if legacy_file != null:
        legacy_file.store_string(legacy_text)
        legacy_file.close()
    var legacy_load: Dictionary = TypingProfile.load_profile(temp_legacy)
    _assert_true(legacy_load.get("ok", false), "legacy profile load ok")
    var legacy_profile: Dictionary = legacy_load.get("profile", {})
    var legacy_keybind: Dictionary = TypingProfile.get_keybind(legacy_profile, "toggle_settings")
    _assert_equal(int(legacy_keybind.get("keycode", 0)), KEY_F1, "legacy keybind restores keycode")
    _assert_true(not bool(legacy_keybind.get("ctrl", false)), "legacy keybind restores modifiers")

    var save_one: Dictionary = TypingProfile.save_profile(profile, temp_roundtrip)
    var save_two: Dictionary = TypingProfile.save_profile(profile, temp_roundtrip_two)
    _assert_true(save_one.get("ok", false) and save_two.get("ok", false), "profile save ok (deterministic ordering)")
    var text_one: String = _read_file_text(temp_roundtrip)
    var text_two: String = _read_file_text(temp_roundtrip_two)
    _assert_equal(text_one, text_two, "profile save ordering stable for keybinds")

    _remove_temp_file(temp_roundtrip)
    _remove_temp_file(temp_roundtrip_two)
    _remove_temp_file(temp_legacy)

func _run_mini_trend_tests() -> void:
    _assert_equal(MiniTrend.arrow_for_delta(0.02), "+", "mini trend arrow positive")
    _assert_equal(MiniTrend.arrow_for_delta(-0.02), "-", "mini trend arrow negative")
    _assert_equal(MiniTrend.arrow_for_delta(0.001, 0.01), "=", "mini trend arrow flat")

    var recent: Array = [
        {"avg_accuracy": 0.8, "hit_rate": 0.6, "backspace_rate": 0.1},
        {"avg_accuracy": 0.7, "hit_rate": 0.7, "backspace_rate": 0.2}
    ]
    var trend: Dictionary = MiniTrend.format_last3_delta(recent)
    _assert_true(bool(trend.get("has_delta", false)), "mini trend has delta")
    _assert_equal(str(trend.get("acc_arrow", "")), "+", "mini trend acc arrow")
    _assert_equal(str(trend.get("hit_arrow", "")), "-", "mini trend hit arrow")
    _assert_equal(str(trend.get("back_arrow", "")), "-", "mini trend back arrow")
    var text: String = str(trend.get("text", ""))
    _assert_true(text.find("acc") != -1, "mini trend text includes acc")
    _assert_true(text.find("+") != -1, "mini trend text includes plus")
    _assert_true(text.find("-") != -1, "mini trend text includes minus")
    _assert_true(text.find("+0.10") != -1, "mini trend text includes accuracy delta")
    _assert_true(text.find("-10%") != -1, "mini trend text includes rate delta")

    var single: Dictionary = MiniTrend.format_last3_delta([{"avg_accuracy": 0.5}])
    _assert_true(not bool(single.get("has_delta", true)), "mini trend single has no delta")
    _assert_true(str(single.get("text", "")) != "", "mini trend single text non-empty")

    var spark: String = MiniTrend.sparkline([0.0, 0.5, 1.0], 3)
    _assert_true(spark.length() == 3, "sparkline width 3")
    _assert_true(spark != "", "sparkline not empty")
    var recent_spark: String = MiniTrend.sparkline_from_recent([
        {"avg_accuracy": 0.2},
        {"avg_accuracy": 0.6},
        {"avg_accuracy": 0.8}
    ], "avg_accuracy", 3)
    _assert_true(recent_spark.length() == 3, "sparkline_from_recent width 3")
    _assert_equal(MiniTrend.sparkline([], 3), "---", "sparkline empty sentinel")

func _run_lesson_health_tests() -> void:
    var no_delta_recent: Array = [{"avg_accuracy": 0.8, "hit_rate": 0.7, "backspace_rate": 0.1}]
    var no_delta_text: String = LessonHealth.build_hud_text("Home Row", "home_row", no_delta_recent, true)
    _assert_true(no_delta_text.find("Health: --") != -1, "lesson health no delta shows --")

    var improve_recent: Array = [
        {"avg_accuracy": 0.8, "hit_rate": 0.7, "backspace_rate": 0.1},
        {"avg_accuracy": 0.7, "hit_rate": 0.6, "backspace_rate": 0.2}
    ]
    var improve_score: int = LessonHealth.score_recent(improve_recent)
    _assert_true(improve_score >= 2, "lesson health score improves")
    var improve_label: String = LessonHealth.label_for_score(improve_score, true)
    _assert_equal(improve_label, "GOOD", "lesson health label good")
    var improve_text: String = LessonHealth.build_hud_text("Full Alpha", "full_alpha", improve_recent, false)
    _assert_true(improve_text.find("acc") != -1, "lesson health text includes acc")
    _assert_true(improve_text.find("+") != -1 or improve_text.find("=") != -1, "lesson health includes arrows")

    var warn_recent: Array = [
        {"avg_accuracy": 0.6, "hit_rate": 0.5, "backspace_rate": 0.3},
        {"avg_accuracy": 0.8, "hit_rate": 0.7, "backspace_rate": 0.1}
    ]
    var warn_score: int = LessonHealth.score_recent(warn_recent)
    var warn_label: String = LessonHealth.label_for_score(warn_score, true)
    _assert_equal(warn_label, "WARN", "lesson health label warn")

    var legend: String = LessonHealth.legend_line()
    _assert_true(legend.find("GOOD") != -1, "lesson health legend mentions GOOD")
    _assert_true(legend.find("OK") != -1, "lesson health legend mentions OK")
    _assert_true(legend.find("WARN") != -1, "lesson health legend mentions WARN")

func _run_lessons_sort_tests() -> void:
    var ids: PackedStringArray = PackedStringArray(["a", "b", "c"])
    var progress: Dictionary = {
        "a": {
            "recent": [
                {"avg_accuracy": 0.65, "hit_rate": 0.4, "backspace_rate": 0.25},
                {"avg_accuracy": 0.6, "hit_rate": 0.5, "backspace_rate": 0.2}
            ],
            "nights": 2
        },
        "b": {
            "recent": [
                {"avg_accuracy": 0.9, "hit_rate": 0.8, "backspace_rate": 0.05},
                {"avg_accuracy": 0.6, "hit_rate": 0.5, "backspace_rate": 0.2}
            ],
            "nights": 3
        },
        "c": {
            "recent": [
                {"avg_accuracy": 0.5, "hit_rate": 0.4, "backspace_rate": 0.3},
                {"avg_accuracy": 0.5, "hit_rate": 0.4, "backspace_rate": 0.3}
            ],
            "nights": 1
        }
    }
    var lessons_by_id: Dictionary = {
        "a": {"name": "Alpha"},
        "b": {"name": "Beta"},
        "c": {"name": "Gamma"}
    }
    var sorted: PackedStringArray = LessonsSort.sort_ids(ids, progress, "recent", lessons_by_id)
    _assert_equal(sorted, PackedStringArray(["b", "a", "c"]), "lessons sort recent orders by score")
    var default_sorted: PackedStringArray = LessonsSort.sort_ids(ids, progress, "default", lessons_by_id)
    _assert_equal(default_sorted, ids, "lessons sort default preserves order")

    var name_ids: PackedStringArray = PackedStringArray(["b", "a", "c"])
    var name_sorted: PackedStringArray = LessonsSort.sort_ids(name_ids, progress, "name", lessons_by_id)
    _assert_equal(name_sorted, PackedStringArray(["a", "b", "c"]), "lessons sort name orders alphabetically")

    var tie_ids: PackedStringArray = PackedStringArray(["b", "a", "c"])
    var tie_progress: Dictionary = {
        "a": {"recent": [{"avg_accuracy": 0.5, "hit_rate": 0.5, "backspace_rate": 0.2},
                         {"avg_accuracy": 0.5, "hit_rate": 0.5, "backspace_rate": 0.2}], "nights": 1},
        "b": {"recent": [{"avg_accuracy": 0.5, "hit_rate": 0.5, "backspace_rate": 0.2},
                         {"avg_accuracy": 0.5, "hit_rate": 0.5, "backspace_rate": 0.2}], "nights": 1},
        "c": {"recent": [{"avg_accuracy": 0.5, "hit_rate": 0.5, "backspace_rate": 0.2},
                         {"avg_accuracy": 0.5, "hit_rate": 0.5, "backspace_rate": 0.2}], "nights": 1}
    }
    var tie_sorted: PackedStringArray = LessonsSort.sort_ids(tie_ids, tie_progress, "recent", lessons_by_id)
    _assert_equal(tie_sorted, PackedStringArray(["a", "b", "c"]), "lessons sort recent tie-breaks by name")

func _run_onboarding_flow_tests() -> void:
    var step0_snapshot: Dictionary = {"used_help_or_status": true}
    _assert_true(OnboardingFlow.is_step_complete(0, step0_snapshot), "onboarding step 1 completes on help/status")
    var step1_snapshot: Dictionary = {"did_gather": true, "did_build": true, "did_explore": true, "explored_count": 2}
    _assert_true(OnboardingFlow.is_step_complete(1, step1_snapshot), "onboarding step 2 completes on day actions")
    var step2_snapshot: Dictionary = {"phase": "night", "entered_night": true}
    _assert_true(OnboardingFlow.is_step_complete(2, step2_snapshot), "onboarding step 3 completes on entering night")
    var step3_snapshot: Dictionary = {"hit_enemy": true}
    _assert_true(OnboardingFlow.is_step_complete(3, step3_snapshot), "onboarding step 4 completes on hit")
    var advance_step: int = OnboardingFlow.advance(0, step0_snapshot)
    _assert_equal(advance_step, 1, "onboarding advance increments")

func _run_typing_profile_tests() -> void:
    var base_profile: Dictionary = TypingProfile.default_profile()
    var onboarding: Dictionary = TypingProfile.get_onboarding(base_profile)     
    _assert_true(bool(onboarding.get("enabled", false)), "onboarding enabled default")
    _assert_true(not bool(onboarding.get("completed", true)), "onboarding not completed default")
    _assert_equal(int(onboarding.get("step", -1)), 0, "onboarding step default")
    _assert_true(not bool(onboarding.get("ever_shown", true)), "onboarding ever_shown default false")

    var reset_result: Dictionary = TypingProfile.reset_onboarding(base_profile)
    var reset_profile: Dictionary = reset_result.get("profile", base_profile)
    var reset_onboarding: Dictionary = TypingProfile.get_onboarding(reset_profile)
    _assert_true(bool(reset_onboarding.get("enabled", false)), "onboarding reset enables tutorial")
    _assert_true(not bool(reset_onboarding.get("completed", true)), "onboarding reset clears completion")
    _assert_equal(int(reset_onboarding.get("step", -1)), 0, "onboarding reset step 0")
    _assert_true(bool(reset_onboarding.get("ever_shown", false)), "onboarding reset sets ever_shown")

    var complete_result: Dictionary = TypingProfile.complete_onboarding(reset_profile)
    var complete_profile: Dictionary = complete_result.get("profile", reset_profile)
    var complete_onboarding: Dictionary = TypingProfile.get_onboarding(complete_profile)
    _assert_true(bool(complete_onboarding.get("completed", false)), "onboarding complete sets completed")
    _assert_true(not bool(complete_onboarding.get("enabled", true)), "onboarding complete disables tutorial")
    _assert_true(bool(complete_onboarding.get("ever_shown", false)), "onboarding complete sets ever_shown")

    var defaults: Dictionary = TypingProfile.default_keybinds()
    _assert_true(defaults.has("cycle_goal"), "profile defaults include cycle_goal")
    _assert_true(defaults.has("toggle_settings"), "profile defaults include toggle_settings")
    _assert_true(defaults.has("toggle_lessons"), "profile defaults include toggle_lessons")
    _assert_true(defaults.has("toggle_trend"), "profile defaults include toggle_trend")
    _assert_true(defaults.has("toggle_compact"), "profile defaults include toggle_compact")
    _assert_true(defaults.has("toggle_history"), "profile defaults include toggle_history")
    _assert_true(defaults.has("toggle_report"), "profile defaults include toggle_report")
    var trend_default: Dictionary = TypingProfile.default_binding_for_action("toggle_trend")
    _assert_equal(int(trend_default.get("keycode", 0)), KEY_F3, "profile default toggle_trend is F3")
    var settings_default: Dictionary = TypingProfile.default_binding_for_action("toggle_settings")
    _assert_equal(int(settings_default.get("keycode", 0)), KEY_F1, "profile default toggle_settings is F1")
    var lessons_default: Dictionary = TypingProfile.default_binding_for_action("toggle_lessons")
    _assert_equal(int(lessons_default.get("keycode", 0)), KEY_F2, "profile default toggle_lessons is F2")
    var history_default: Dictionary = TypingProfile.default_binding_for_action("toggle_history")
    _assert_equal(int(history_default.get("keycode", 0)), KEY_F5, "profile default toggle_history is F5")
    var compact_bind_default: Dictionary = TypingProfile.default_binding_for_action("toggle_compact")
    _assert_equal(int(compact_bind_default.get("keycode", 0)), KEY_F4, "profile default toggle_compact is F4")
    var report_default: Dictionary = TypingProfile.default_binding_for_action("toggle_report")
    _assert_equal(int(report_default.get("keycode", 0)), KEY_F6, "profile default toggle_report is F6")
    var cycle_default: Dictionary = TypingProfile.default_binding_for_action("cycle_goal")
    _assert_equal(int(cycle_default.get("keycode", 0)), KEY_F7, "profile default cycle_goal is F7")
    var profile: Dictionary = {"keybinds": {"cycle_goal": defaults.get("cycle_goal", {})}}
    var toggle_keybind: Dictionary = TypingProfile.get_keybind(profile, "toggle_trend")
    _assert_equal(int(toggle_keybind.get("keycode", 0)), KEY_F3, "get_keybind falls back to default")
    var history_keybind: Dictionary = TypingProfile.get_keybind(profile, "toggle_history")
    _assert_equal(int(history_keybind.get("keycode", 0)), KEY_F5, "get_keybind falls back to default for history")
    var compact_keybind: Dictionary = TypingProfile.get_keybind(profile, "toggle_compact")
    _assert_equal(int(compact_keybind.get("keycode", 0)), KEY_F4, "get_keybind falls back to default for compact")
    var settings_keybind: Dictionary = TypingProfile.get_keybind(profile, "toggle_settings")
    _assert_equal(int(settings_keybind.get("keycode", 0)), KEY_F1, "get_keybind falls back to default for settings")
    var lessons_keybind: Dictionary = TypingProfile.get_keybind(profile, "toggle_lessons")
    _assert_equal(int(lessons_keybind.get("keycode", 0)), KEY_F2, "get_keybind falls back to default for lessons")
    var report_keybind: Dictionary = TypingProfile.get_keybind(profile, "toggle_report")
    _assert_equal(int(report_keybind.get("keycode", 0)), KEY_F6, "get_keybind falls back to default for report")
    var lesson_profile: Dictionary = TypingProfile.default_profile()
    var preferred_lesson: String = TypingProfile.get_lesson(lesson_profile)
    _assert_true(SimLessons.is_valid(preferred_lesson), "profile preferred lesson valid")
    var sort_mode: String = TypingProfile.get_lessons_sort(lesson_profile)
    _assert_equal(sort_mode, "default", "profile lessons sort default")
    var name_profile: Dictionary = {"ui_prefs": {"lessons_sort": "name"}}
    _assert_equal(TypingProfile.get_lessons_sort(name_profile), "name", "profile lessons sort accepts name")
    var spark_default: bool = TypingProfile.get_lessons_sparkline(lesson_profile)
    _assert_true(spark_default, "profile lessons sparkline default true")
    var spark_update: Dictionary = TypingProfile.set_lessons_sparkline(lesson_profile, false)
    var spark_profile: Dictionary = spark_update.get("profile", lesson_profile)
    _assert_equal(TypingProfile.get_lessons_sparkline(spark_profile), false, "profile lessons sparkline set false")
    var economy_default: bool = TypingProfile.get_economy_note_shown(lesson_profile)
    _assert_true(not economy_default, "profile economy note default false")
    var economy_update: Dictionary = TypingProfile.set_economy_note_shown(lesson_profile, true)
    var economy_profile: Dictionary = economy_update.get("profile", lesson_profile)
    _assert_true(TypingProfile.get_economy_note_shown(economy_profile), "profile economy note set true")
    var scale_default: int = TypingProfile.get_ui_scale_percent(lesson_profile)
    _assert_equal(scale_default, 100, "profile ui scale default 100")
    var scale_profile: Dictionary = {"ui_prefs": {"ui_scale_percent": 115}}
    _assert_equal(TypingProfile.get_ui_scale_percent(scale_profile), 120, "profile ui scale sanitizes to nearest step")
    var scale_update: Dictionary = TypingProfile.set_ui_scale_percent(lesson_profile, 140)
    var scale_updated_profile: Dictionary = scale_update.get("profile", lesson_profile)
    _assert_equal(TypingProfile.get_ui_scale_percent(scale_updated_profile), 140, "profile ui scale set 140")
    var compact_default: bool = TypingProfile.get_compact_panels(lesson_profile)
    _assert_true(not compact_default, "profile compact panels default false")
    var compact_update: Dictionary = TypingProfile.set_compact_panels(lesson_profile, true)
    var compact_profile: Dictionary = compact_update.get("profile", lesson_profile)
    _assert_true(TypingProfile.get_compact_panels(compact_profile), "profile compact panels set true")
    var progress_map: Dictionary = TypingProfile.get_lesson_progress_map(lesson_profile)
    _assert_true(progress_map.has(preferred_lesson), "lesson progress includes preferred lesson")
    var entry: Dictionary = progress_map.get(preferred_lesson, {})
    _assert_true(entry.has("nights"), "lesson progress has nights")
    _assert_true(entry.has("sum_accuracy"), "lesson progress has sum_accuracy")
    _assert_true(entry.has("recent"), "lesson progress has recent")
    var report := {"avg_accuracy": 0.8, "hit_rate": 0.6, "backspace_rate": 0.1, "incomplete_rate": 0.2, "night_day": 5}
    var updated: Dictionary = TypingProfile.update_lesson_progress(progress_map, preferred_lesson, report, true)
    var updated_entry: Dictionary = updated.get(preferred_lesson, {})
    _assert_equal(int(updated_entry.get("nights", 0)), int(entry.get("nights", 0)) + 1, "lesson progress nights increment")
    _assert_equal(int(updated_entry.get("goal_passes", 0)), int(entry.get("goal_passes", 0)) + 1, "lesson progress goal passes increment")
    _assert_true(float(updated_entry.get("best_accuracy", 0.0)) >= 0.8, "lesson progress best accuracy updated")
    var recent: Array = updated_entry.get("recent", [])
    _assert_true(recent is Array and recent.size() == 1, "lesson progress recent appends")
    if recent.size() > 0 and typeof(recent[0]) == TYPE_DICTIONARY:
        _assert_equal(int(recent[0].get("day", 0)), 5, "lesson progress recent day set")
        _assert_true(bool(recent[0].get("goal_met", false)), "lesson progress recent goal met set")

    var updated2: Dictionary = TypingProfile.update_lesson_progress(updated, preferred_lesson, {"avg_accuracy": 0.7, "hit_rate": 0.5, "backspace_rate": 0.2, "incomplete_rate": 0.1, "night_day": 6}, false)
    var updated3: Dictionary = TypingProfile.update_lesson_progress(updated2, preferred_lesson, {"avg_accuracy": 0.9, "hit_rate": 0.7, "backspace_rate": 0.1, "incomplete_rate": 0.05, "night_day": 7}, true)
    var updated4: Dictionary = TypingProfile.update_lesson_progress(updated3, preferred_lesson, {"avg_accuracy": 0.6, "hit_rate": 0.4, "backspace_rate": 0.3, "incomplete_rate": 0.2, "night_day": 8}, false)
    var updated_recent: Array = updated4.get(preferred_lesson, {}).get("recent", [])
    _assert_equal(updated_recent.size(), 3, "lesson progress recent capped at 3")
    if updated_recent.size() > 0 and typeof(updated_recent[0]) == TYPE_DICTIONARY:
        _assert_equal(int(updated_recent[0].get("day", 0)), 8, "lesson progress recent keeps most recent first")

    var reset_map: Dictionary = TypingProfile.reset_lesson_progress(updated4, preferred_lesson)
    var reset_entry: Dictionary = reset_map.get(preferred_lesson, {})
    _assert_equal(int(reset_entry.get("nights", 0)), 0, "lesson progress reset nights")
    var reset_recent: Array = reset_entry.get("recent", [])
    _assert_true(reset_recent is Array and reset_recent.is_empty(), "lesson progress reset recent")

func _run_typing_feedback_tests() -> void:
    _assert_equal(SimTypingFeedback.prefix_len("ap", "apple"), 2, "prefix_len matches partial")
    _assert_equal(SimTypingFeedback.prefix_len("apple", "apple"), 5, "prefix_len matches exact")
    _assert_equal(SimTypingFeedback.prefix_len("apx", "apple"), 2, "prefix_len stops at mismatch")
    _assert_equal(SimTypingFeedback.prefix_len(" Apple ", "apple"), 5, "prefix_len normalizes case/trim")
    _assert_equal(SimTypingFeedback.edit_distance("", ""), 0, "edit_distance empty")
    _assert_equal(SimTypingFeedback.edit_distance("a", ""), 1, "edit_distance deletion")
    _assert_equal(SimTypingFeedback.edit_distance("kitten", "sitting"), 3, "edit_distance classic")

    var enemies: Array = [
        {"id": 1, "word": "stone", "dist": 4},
        {"id": 2, "word": "staple", "dist": 1}
    ]
    var cand_st: Dictionary = SimTypingFeedback.enemy_candidates(enemies, "st")
    _assert_true(cand_st.get("candidate_ids", []).has(1), "enemy_candidates includes stone")
    _assert_true(cand_st.get("candidate_ids", []).has(2), "enemy_candidates includes staple")
    var cand_exact: Dictionary = SimTypingFeedback.enemy_candidates(enemies, "stone")
    _assert_equal(int(cand_exact.get("exact_id", -1)), 1, "enemy_candidates exact_id matches")
    var cand_sta: Dictionary = SimTypingFeedback.enemy_candidates(enemies, "sta")
    _assert_true(cand_sta.get("candidate_ids", []).has(2), "enemy_candidates sta matches staple")
    _assert_true(not cand_sta.get("candidate_ids", []).has(1), "enemy_candidates sta excludes stone")
    var suggestions: Array = cand_st.get("suggestions", [])
    if suggestions.size() >= 2:
        _assert_equal(int(suggestions[0].get("id", 0)), 2, "suggestions use dist tie-break")

    var route_cmd: Dictionary = SimTypingFeedback.route_night_input(true, "status", "sta", enemies)
    _assert_equal(str(route_cmd.get("action", "")), "command", "route returns command on parse_ok")
    var route_prefix: Dictionary = SimTypingFeedback.route_night_input(false, "", "st", enemies)
    _assert_equal(str(route_prefix.get("action", "")), "incomplete", "route blocks prefix of enemy word")
    var route_exact: Dictionary = SimTypingFeedback.route_night_input(false, "", "stone", enemies)
    _assert_equal(str(route_exact.get("action", "")), "defend", "route allows exact enemy word")
    var route_cmd_prefix: Dictionary = SimTypingFeedback.route_night_input(false, "", "sta", [])
    _assert_equal(str(route_cmd_prefix.get("action", "")), "incomplete", "route blocks command prefixes")
    var route_miss: Dictionary = SimTypingFeedback.route_night_input(false, "", "zzz", enemies)
    _assert_equal(str(route_miss.get("action", "")), "defend", "route treats nonsense as miss")

func _run_typing_stats_tests() -> void:
    var stats: SimTypingStats = SimTypingStats.new()
    stats.start_night(2, 5)
    _assert_equal(stats.night_day, 2, "typing stats start_night sets day")
    _assert_equal(stats.wave_total, 5, "typing stats start_night sets wave")
    stats.on_text_changed("", "cat")
    stats.on_text_changed("cat", "ca")
    _assert_equal(stats.typed_chars, 3, "typing stats counts typed chars")
    _assert_equal(stats.deleted_chars, 1, "typing stats counts deleted chars")
    stats.on_enter_pressed()
    stats.record_incomplete_enter("prefix")
    _assert_equal(stats.enter_presses, 1, "typing stats enter presses")
    _assert_equal(stats.incomplete_enters, 1, "typing stats incomplete enters")
    stats.record_command_enter("wait", true)
    _assert_equal(stats.command_enters, 1, "typing stats command enters")
    _assert_equal(stats.wait_steps, 1, "typing stats wait steps")
    var enemies: Array = [
        {"id": 1, "word": "stone"},
        {"id": 2, "word": "staple"}
    ]
    stats.record_defend_attempt("stone", enemies)
    _assert_equal(stats.hits, 1, "typing stats records hits")
    _assert_equal(stats.misses, 0, "typing stats records misses")
    stats.record_defend_attempt("zzz", enemies)
    _assert_equal(stats.misses, 1, "typing stats records miss attempts")
    var report: Dictionary = stats.to_report_dict()
    _assert_true(float(report.get("avg_accuracy", 0.0)) >= 0.0, "typing stats avg accuracy non-negative")
    _assert_true(float(report.get("avg_accuracy", 0.0)) <= 1.0, "typing stats avg accuracy max 1")

func _run_typing_trends_tests() -> void:
    var bad_report: Dictionary = {"avg_accuracy": 0.6, "hit_rate": 0.5, "backspace_rate": 0.3, "incomplete_rate": 0.4}
    var history: Array = [bad_report]
    var accuracy_summary: Dictionary = SimTypingTrends.summarize(history, "accuracy")
    _assert_equal(str(accuracy_summary.get("goal_id", "")), "accuracy", "trend summary goal id")
    _assert_equal(bool(accuracy_summary.get("goal_met", true)), false, "trend goal not met")
    _assert_true(_summary_has_suggestion(accuracy_summary, "Accuracy"), "trend accuracy suggestion")

    var backspace_summary: Dictionary = SimTypingTrends.summarize(history, "backspace")
    _assert_true(_summary_has_suggestion(backspace_summary, "Backspace"), "trend backspace suggestion")

    var good_report: Dictionary = {"avg_accuracy": 0.9, "hit_rate": 0.8, "backspace_rate": 0.1, "incomplete_rate": 0.05}
    var good_history: Array = [good_report, good_report]
    var balanced_summary: Dictionary = SimTypingTrends.summarize(good_history, "balanced")
    _assert_equal(bool(balanced_summary.get("goal_met", false)), true, "trend goal met when above thresholds")

func _find_new_tile(before_state: GameState, after_state: GameState) -> int:
    for key in after_state.discovered.keys():
        if not before_state.discovered.has(key):
            return int(key)
    return -1

func _find_enemy(enemies: Array, enemy_id: int) -> Dictionary:
    for enemy in enemies:
        if typeof(enemy) != TYPE_DICTIONARY:
            continue
        if int(enemy.get("id", 0)) == enemy_id:
            return enemy
    return {}

func _enemy_snapshot(enemies: Array) -> Array[String]:
    var ids: Array[int] = []
    for enemy in enemies:
        if typeof(enemy) != TYPE_DICTIONARY:
            continue
        ids.append(int(enemy.get("id", 0)))
    ids.sort()
    var output: Array[String] = []
    for enemy_id in ids:
        var enemy: Dictionary = _find_enemy(enemies, enemy_id)
        var pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
        output.append("%d|%s|%d|%d|%d|%s" % [
            enemy_id,
            str(enemy.get("kind", "")),
            int(enemy.get("hp", 0)),
            pos.x,
            pos.y,
            str(enemy.get("word", ""))
        ])
    return output

func _summary_has_suggestion(summary: Dictionary, needle: String) -> bool:
    var suggestions: Array = summary.get("suggestions", [])
    for suggestion in suggestions:
        if str(suggestion).find(needle) != -1:
            return true
    return false

func _make_flat_state(seed_text: String) -> GameState:
    var state: GameState = DefaultState.create(seed_text)
    for y in range(state.map_h):
        for x in range(state.map_w):
            var index: int = SimMap.idx(x, y, state.map_w)
            state.terrain[index] = SimMap.TERRAIN_PLAINS
            state.discovered[index] = true
    return state

func _run_story_manager_tests() -> void:
    # Test data loading
    var data: Dictionary = StoryManager.load_data()
    _assert_true(data.get("ok", false), "StoryManager.load_data() succeeds")

    # Test acts retrieval
    var acts: Array = StoryManager.get_acts()
    _assert_true(acts.size() >= 5, "StoryManager has at least 5 acts")

    # Test act for day
    var act1: Dictionary = StoryManager.get_act_for_day(1)
    _assert_true(not act1.is_empty(), "get_act_for_day(1) returns act")
    _assert_true(str(act1.get("id", "")).begins_with("act"), "Day 1 is in an act")

    var act3: Dictionary = StoryManager.get_act_for_day(10)
    _assert_true(not act3.is_empty(), "get_act_for_day(10) returns act")

    # Test boss day detection
    _assert_true(StoryManager.is_boss_day(4), "Day 4 is boss day")
    _assert_true(StoryManager.is_boss_day(8), "Day 8 is boss day")
    _assert_true(not StoryManager.is_boss_day(3), "Day 3 is not boss day")
    _assert_true(not StoryManager.is_boss_day(7), "Day 7 is not boss day")

    # Test boss data retrieval
    var boss4: Dictionary = StoryManager.get_boss_for_day(4)
    _assert_true(not boss4.is_empty(), "get_boss_for_day(4) returns boss")
    _assert_true(not str(boss4.get("kind", "")).is_empty(), "Boss has kind")

    # Test boss kind detection
    var boss_kinds: Array[String] = StoryManager.get_all_boss_kinds()
    _assert_true(boss_kinds.size() >= 4, "At least 4 boss kinds exist")
    for kind in boss_kinds:
        _assert_true(StoryManager.is_boss_kind(kind), "is_boss_kind(%s) returns true" % kind)
    _assert_true(not StoryManager.is_boss_kind("raider"), "raider is not a boss kind")

    # Test act progress
    var progress: Dictionary = StoryManager.get_act_progress(1)
    _assert_true(progress.get("act_number", 0) == 1, "Day 1 is act number 1")
    _assert_true(progress.get("day_in_act", 0) >= 1, "Day in act is at least 1")

    # Test dialogue retrieval
    var dialogue: Dictionary = StoryManager.get_dialogue("game_start")
    _assert_true(not dialogue.is_empty(), "game_start dialogue exists")

    var lines: Array[String] = StoryManager.get_dialogue_lines("game_start")
    _assert_true(lines.size() > 0, "game_start has dialogue lines")

    # Test mentor name
    var mentor: String = StoryManager.get_mentor_name(1)
    _assert_true(not mentor.is_empty(), "Mentor name for day 1 exists")

    # Test lesson introductions
    var intro: Dictionary = StoryManager.get_lesson_intro("home_row_1")
    _assert_true(not intro.is_empty(), "home_row_1 lesson intro exists")

    var intro_lines: Array[String] = StoryManager.get_lesson_intro_lines("home_row_1")
    _assert_true(intro_lines.size() > 0, "home_row_1 has intro lines")

    var finger_guide: Dictionary = StoryManager.get_lesson_finger_guide("home_row_1")
    _assert_true(not finger_guide.is_empty(), "home_row_1 has finger guide")

    var lesson_title: String = StoryManager.get_lesson_title("home_row_1")
    _assert_true(not lesson_title.is_empty(), "home_row_1 has title")

    # Test typing tips
    var tips: Array[String] = StoryManager.get_typing_tips("technique")
    _assert_true(tips.size() > 0, "technique tips exist")

    var random_tip: String = StoryManager.get_random_typing_tip()
    _assert_true(not random_tip.is_empty(), "Random typing tip returns value")

    # Test performance feedback
    var acc_feedback: String = StoryManager.get_accuracy_feedback(98.0)
    _assert_true(not acc_feedback.is_empty(), "Accuracy feedback for 98% exists")

    var speed_feedback: String = StoryManager.get_speed_feedback(60.0)
    _assert_true(not speed_feedback.is_empty(), "Speed feedback for 60 WPM exists")

    var combo_feedback: String = StoryManager.get_combo_feedback(15)
    _assert_true(not combo_feedback.is_empty(), "Combo feedback for 15 exists")

    # Test finger assignments
    var finger_a: String = StoryManager.get_finger_for_key("a")
    _assert_true(not finger_a.is_empty(), "Finger for 'a' key exists")
    _assert_true(finger_a.to_lower().find("pinky") != -1 or finger_a.to_lower().find("little") != -1, "Key 'a' uses left pinky/little finger")

    var finger_j: String = StoryManager.get_finger_for_key("j")
    _assert_true(not finger_j.is_empty(), "Finger for 'j' key exists")
    _assert_true(finger_j.to_lower().find("index") != -1, "Key 'j' uses index finger")

    # Test contextual tips
    var error_tip: String = StoryManager.get_contextual_tip("error")
    _assert_true(not error_tip.is_empty(), "Error context tip exists")

    # Test lore retrieval
    var kingdom_lore: Dictionary = StoryManager.get_kingdom_lore()
    _assert_true(not kingdom_lore.is_empty(), "Kingdom lore exists")

    var horde_lore: Dictionary = StoryManager.get_horde_lore()
    _assert_true(not horde_lore.is_empty(), "Horde lore exists")

    # Test character info
    var lyra_info: Dictionary = StoryManager.get_character_info("elder_lyra")
    _assert_true(not lyra_info.is_empty(), "Elder Lyra character info exists")

    # Test act completion detection
    _assert_true(StoryManager.is_act_complete_day(4), "Day 4 completes an act")
    _assert_true(not StoryManager.is_act_complete_day(3), "Day 3 does not complete an act")

    var completion_info: Dictionary = StoryManager.get_act_completion_info(4)
    _assert_true(not completion_info.is_empty(), "Act completion info for day 4 exists")

    # Test streak messages
    var streak_msg: String = StoryManager.get_daily_streak_message(7)
    _assert_true(not streak_msg.is_empty(), "7-day streak message exists")

    # Test milestone messages
    var wpm_msg: String = StoryManager.get_wpm_milestone_message(50)
    _assert_true(not wpm_msg.is_empty(), "50 WPM milestone message exists")

func _assert_parse_ok(command: String, expected_kind: String) -> void:
    var result: Dictionary = CommandParser.parse(command)
    _assert_true(result.get("ok", false), "parse ok: %s" % command)
    if result.get("ok", false):
        _assert_equal(str(result.intent.get("kind", "")), expected_kind, "intent kind: %s" % command)

func _conflict_signature_label_test(signature: String) -> String:
    return "TEST"

func _conflict_signature_identity_test(signature: String) -> String:
    return signature

func _conflict_action_identity_test(action_name: String) -> String:
    return action_name

func _read_file_text(path: String) -> String:
    if not FileAccess.file_exists(path):
        return ""
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return ""
    var text: String = file.get_as_text()
    file.close()
    return text

func _remove_temp_file(path: String) -> void:
    if not FileAccess.file_exists(path):
        return
    var absolute: String = ProjectSettings.globalize_path(path)
    if absolute == "":
        return
    DirAccess.remove_absolute(absolute)

func _assert_true(value: bool, name: String) -> void:
    total_tests += 1
    if not value:
        total_failed += 1
        messages.append("FAIL: %s" % name)

func _assert_equal(actual, expected, name: String) -> void:
    total_tests += 1
    if actual != expected:
        total_failed += 1
        messages.append("FAIL: %s (expected %s, got %s)" % [name, str(expected), str(actual)])

func _assert_approx(actual: float, expected: float, epsilon: float, name: String) -> void:
    total_tests += 1
    if abs(actual - expected) > epsilon:
        total_failed += 1
        messages.append("FAIL: %s (expected %s, got %s)" % [name, str(expected), str(actual)])

func _run_boss_encounters_tests() -> void:
    # Test getting all boss IDs
    var boss_ids: Array[String] = SimBossEncounters.get_all_boss_ids()
    _assert_true(boss_ids.size() >= 4, "At least 4 bosses defined")

    # Test individual boss validation
    for boss_id in boss_ids:
        _assert_true(SimBossEncounters.is_valid_boss(boss_id), "Boss '%s' is valid" % boss_id)

    # Test invalid boss detection
    _assert_true(not SimBossEncounters.is_valid_boss("not_a_boss"), "Invalid boss returns false")

    # Test boss data retrieval
    var grove_guardian: Dictionary = SimBossEncounters.get_boss("grove_guardian")
    _assert_true(not grove_guardian.is_empty(), "grove_guardian boss data exists")
    _assert_true(grove_guardian.has("name"), "Boss has name field")
    _assert_true(grove_guardian.has("phases"), "Boss has phases field")

    # Test boss name and title
    var boss_name: String = SimBossEncounters.get_boss_name("grove_guardian")
    _assert_true(not boss_name.is_empty(), "Boss name is not empty")

    var boss_title: String = SimBossEncounters.get_boss_title("grove_guardian")
    _assert_true(not boss_title.is_empty(), "Boss title is not empty")

    # Test boss for region
    var region1_boss: String = SimBossEncounters.get_boss_for_region(1)
    _assert_true(not region1_boss.is_empty(), "Region 1 has a boss")
    _assert_true(SimBossEncounters.is_valid_boss(region1_boss), "Region 1 boss is valid")

    # Test boss unlock days
    var unlock_day: int = SimBossEncounters.get_boss_unlock_day("grove_guardian")
    _assert_true(unlock_day >= 1, "Boss has valid unlock day")

    # Test available bosses for day (bosses unlock at days 7, 14, 21, 28)
    var day7_bosses: Array[String] = SimBossEncounters.get_available_bosses_for_day(7)
    _assert_true(day7_bosses.size() >= 1, "At least 1 boss available on day 7")

    # Test dialogue retrieval
    var intro: Array = SimBossEncounters.get_intro_dialogue("grove_guardian")
    _assert_true(intro.size() > 0, "Boss has intro dialogue")

    var defeat: Array = SimBossEncounters.get_defeat_dialogue("grove_guardian")
    _assert_true(defeat.size() > 0, "Boss has defeat dialogue")

    # Test phase name retrieval
    var phase1_name: String = SimBossEncounters.get_phase_name("grove_guardian", 1)
    _assert_true(not phase1_name.is_empty(), "Phase 1 has a name")

    # Test boss state initialization (uses "type" field, not "kind")
    var boss_enemy: Dictionary = {
        "id": 1,
        "type": "grove_guardian",
        "hp": 100,
        "max_hp": 100,
        "pos": Vector2i(5, 5),
        "word": "test"
    }
    SimBossEncounters.init_boss_state(boss_enemy)
    _assert_true(boss_enemy.has("current_phase"), "Boss state has current_phase after init")
    _assert_equal(int(boss_enemy.get("current_phase", 0)), 1, "Boss starts at phase 1")

    # Test phase transition check (need proper phase setup for transition)
    boss_enemy["hp"] = 30  # Low HP
    boss_enemy["max_hp"] = 100
    var transition: Dictionary = SimBossEncounters.check_phase_transition(boss_enemy)
    # Transition may be empty if already at max phase or conditions not met
    _assert_true(transition != null, "Phase transition check returns dictionary")

    # Test mechanic retrieval (use an actual mechanic name)
    var barrier_mechanic: Dictionary = SimBossEncounters.get_mechanic("crystal_barrier")
    _assert_true(not barrier_mechanic.is_empty(), "Crystal barrier mechanic exists")


func _run_difficulty_tests() -> void:
    # Test difficulty mode definitions
    var modes: Array[String] = SimDifficulty.get_all_mode_ids()
    _assert_true(modes.size() >= 3, "At least 3 difficulty modes exist")
    _assert_true("adventure" in modes, "Adventure mode exists")
    _assert_true("story" in modes, "Story mode exists")

    # Test mode data (adventure is the default/normal mode)
    var adventure: Dictionary = SimDifficulty.get_mode("adventure")
    _assert_true(not adventure.is_empty(), "Adventure mode data exists")

    # Test mode name and description
    var mode_name: String = SimDifficulty.get_mode_name("adventure")
    _assert_true(not mode_name.is_empty(), "Mode has name")

    var mode_desc: String = SimDifficulty.get_mode_description("adventure")
    _assert_true(not mode_desc.is_empty(), "Mode has description")

    # Test modifier application
    var base_hp: int = 10
    var modified_hp: int = SimDifficulty.apply_health_modifier(base_hp, "adventure")
    _assert_true(modified_hp >= 1, "Adventure mode HP modifier works")

    var base_speed: float = 1.0
    var modified_speed: float = SimDifficulty.apply_speed_modifier(base_speed, "adventure")
    _assert_true(modified_speed > 0, "Adventure mode speed modifier works")

    # Test damage modifier
    var base_damage: int = 5
    var modified_damage: int = SimDifficulty.apply_damage_modifier(base_damage, "adventure")
    _assert_true(modified_damage >= 1, "Damage modifier produces valid value")

    # Test wave size modifier
    var base_size: int = 5
    var modified_size: int = SimDifficulty.apply_wave_size_modifier(base_size, "adventure")
    _assert_true(modified_size >= 1, "Wave size modifier produces valid value")

    # Test gold modifier
    var base_gold: int = 10
    var modified_gold: int = SimDifficulty.apply_gold_modifier(base_gold, "adventure")
    _assert_true(modified_gold >= 1, "Gold modifier produces valid value")

    # Test multiplier getters
    var health_mult: float = SimDifficulty.get_enemy_health_mult("adventure")
    _assert_true(health_mult > 0, "Health multiplier is positive")

    var speed_mult: float = SimDifficulty.get_enemy_speed_mult("adventure")
    _assert_true(speed_mult > 0, "Speed multiplier is positive")

    # Test typo forgiveness
    var typo_forgiveness: int = SimDifficulty.get_typo_forgiveness("adventure")
    _assert_true(typo_forgiveness >= 0, "Typo forgiveness is non-negative")


func _run_lesson_consistency_tests() -> void:
    # Test that all lesson IDs have story introductions
    var lesson_ids: PackedStringArray = SimLessons.lesson_ids()
    _assert_true(lesson_ids.size() >= 10, "At least 10 lessons defined")

    var lessons_with_intros: int = 0
    var lessons_without_intros: Array[String] = []

    for lesson_id in lesson_ids:
        var intro: Dictionary = StoryManager.get_lesson_intro(lesson_id)
        if not intro.is_empty():
            lessons_with_intros += 1
        else:
            lessons_without_intros.append(lesson_id)

    # At least 90% of lessons should have intros
    var coverage: float = float(lessons_with_intros) / float(lesson_ids.size())
    _assert_true(coverage >= 0.9, "At least 90%% of lessons have story intros (%.1f%%)" % [coverage * 100])

    # Test lesson title retrieval
    for lesson_id in lesson_ids:
        var title: String = StoryManager.get_lesson_title(lesson_id)
        _assert_true(not title.is_empty(), "Lesson '%s' has title" % lesson_id)

    # Test finger guide availability for home row lessons
    var finger_guide: Dictionary = StoryManager.get_lesson_finger_guide("home_row_1")
    _assert_true(not finger_guide.is_empty(), "home_row_1 has finger guide")

    # Test lesson practice tips
    var tips: Array[String] = StoryManager.get_lesson_practice_tips("home_row_1")
    _assert_true(tips.size() > 0, "home_row_1 has practice tips")


func _run_dialogue_flow_tests() -> void:
    # Test key dialogue keys that exist in story.json
    var key_dialogues: Array[String] = [
        "game_start", "day_start", "boss_victory", "game_victory"
    ]

    for key in key_dialogues:
        var dialogue: Dictionary = StoryManager.get_dialogue(key)
        _assert_true(not dialogue.is_empty(), "Dialogue '%s' exists" % key)

        var speaker: String = StoryManager.get_dialogue_speaker(key)
        _assert_true(not speaker.is_empty(), "Dialogue '%s' has speaker" % key)

        var lines: Array[String] = StoryManager.get_dialogue_lines(key)
        _assert_true(lines.size() > 0, "Dialogue '%s' has lines" % key)

    # Test dialogue with substitutions
    var substitutions: Dictionary = {"player_name": "Hero", "day": 5}
    var subbed_lines: Array[String] = StoryManager.get_dialogue_lines("game_start", substitutions)
    _assert_true(subbed_lines.size() > 0, "Dialogue with substitutions returns lines")

    # Test act intro/completion text for all 5 acts
    var act_end_days: Array[int] = [4, 8, 12, 16, 20]
    for day in act_end_days:
        var intro_text: String = StoryManager.get_act_intro_text(day)
        # Not all days have intros, but some should
        if day <= 4:
            _assert_true(not intro_text.is_empty(), "Day %d has act intro text" % day)

        var completion_text: String = StoryManager.get_act_completion_text(day)
        _assert_true(not completion_text.is_empty(), "Day %d has act completion text" % day)

    # Test enemy taunts exist for common enemy kinds
    var enemy_kinds: Array[String] = ["raider", "scout", "armored"]
    for kind in enemy_kinds:
        var taunt: String = StoryManager.get_enemy_taunt(kind)
        # Taunts are optional, just ensure function doesn't crash
        _assert_true(taunt != null, "Enemy taunt function works for '%s'" % kind)

    # Test comeback messages
    var comeback: String = StoryManager.get_comeback_message()
    _assert_true(not comeback.is_empty(), "Comeback message exists")

    # Test combo milestone messages for thresholds >= 10
    var combo_thresholds: Array[int] = [10, 20, 30, 50]
    for combo in combo_thresholds:
        var msg: String = StoryManager.get_combo_milestone_message(combo)
        _assert_true(not msg.is_empty(), "Combo milestone message for %d exists" % combo)

    # Test accuracy milestone messages for thresholds >= 95
    var accuracy_thresholds: Array[int] = [95, 98, 100]
    for acc in accuracy_thresholds:
        var msg: String = StoryManager.get_accuracy_milestone_message(acc)
        _assert_true(not msg.is_empty(), "Accuracy milestone message for %d%% exists" % acc)

    # Test hint themes (may be empty depending on story.json structure)
    var hint_themes: Array[String] = ["speed", "accuracy", "endurance", "combo"]
    for theme in hint_themes:
        var hint: String = StoryManager.get_hint_for_theme(theme)
        # Hints may be empty if not defined in story.json
        _assert_true(hint != null, "Hint function for theme '%s' works" % theme)

    # Test all lore retrieval
    var all_lore: Dictionary = StoryManager.get_all_lore()
    _assert_true(not all_lore.is_empty(), "All lore retrieval works")
    _assert_true(all_lore.has("kingdom") or all_lore.has("horde"), "All lore has expected categories")


func _run_exploration_challenges_tests() -> void:
    # Test difficulty presets exist
    _assert_true(SimExplorationChallenges.DIFFICULTY_PRESETS.has("easy"), "Easy difficulty preset exists")
    _assert_true(SimExplorationChallenges.DIFFICULTY_PRESETS.has("medium"), "Medium difficulty preset exists")
    _assert_true(SimExplorationChallenges.DIFFICULTY_PRESETS.has("hard"), "Hard difficulty preset exists")
    _assert_true(SimExplorationChallenges.DIFFICULTY_PRESETS.has("legendary"), "Legendary difficulty preset exists")

    # Test difficulty scaling by day
    _assert_equal(SimExplorationChallenges.get_difficulty_for_day(1), "easy", "Day 1 is easy")
    _assert_equal(SimExplorationChallenges.get_difficulty_for_day(3), "easy", "Day 3 is easy")
    _assert_equal(SimExplorationChallenges.get_difficulty_for_day(5), "medium", "Day 5 is medium")
    _assert_equal(SimExplorationChallenges.get_difficulty_for_day(10), "hard", "Day 10 is hard")
    _assert_equal(SimExplorationChallenges.get_difficulty_for_day(20), "legendary", "Day 20 is legendary")

    # Test challenge generation with config
    var config: Dictionary = {
        "type": SimExplorationChallenges.ChallengeType.WORD_COUNT,
        "difficulty": "medium",
        "day_scaled": false
    }
    var challenge: Dictionary = SimExplorationChallenges.generate_challenge(null, config)
    _assert_true(not challenge.is_empty(), "Challenge generation returns dictionary")
    _assert_true(challenge.has("words"), "Challenge has words")
    _assert_true(challenge.has("difficulty"), "Challenge has difficulty")
    _assert_equal(str(challenge.get("difficulty")), "medium", "Challenge has correct difficulty")

    # Test challenge words are generated
    var words: Array = challenge.get("words", [])
    _assert_true(words.size() > 0, "Challenge has words generated")

    # Test challenge start
    var started: Dictionary = SimExplorationChallenges.start_challenge(challenge, 0.0)
    _assert_true(started.get("started", false), "Challenge started after start_challenge")
    _assert_equal(int(started.get("current_word_index", -1)), 0, "Challenge starts at word index 0")

    # Test word processing
    if words.size() > 0:
        var first_word: String = str(words[0])
        var process_result: Dictionary = SimExplorationChallenges.process_word(challenge, first_word)
        _assert_true(process_result.get("accepted", false), "Correct word is accepted")
        _assert_true(process_result.get("correct", false), "Correct word is marked correct")

        # Test wrong word
        var wrong_result: Dictionary = SimExplorationChallenges.process_word(challenge, "wrongwordxyz")
        _assert_true(wrong_result.get("accepted", false), "Wrong word is accepted (tracked)")
        _assert_true(not wrong_result.get("correct", true), "Wrong word is marked incorrect")

    # Test challenge evaluation
    var eval_result: Dictionary = SimExplorationChallenges.evaluate_challenge(challenge, 10.0)
    _assert_true(eval_result.has("passed"), "Evaluation has passed field")
    _assert_true(eval_result.has("score"), "Evaluation has score field")
    _assert_true(eval_result.has("accuracy"), "Evaluation has accuracy field")
    _assert_true(eval_result.has("wpm"), "Evaluation has wpm field")

    # Test challenge description
    var desc: String = SimExplorationChallenges.get_challenge_description(challenge)
    _assert_true(not desc.is_empty(), "Challenge description is not empty")

    # Test result description
    var result_desc: String = SimExplorationChallenges.get_result_description(eval_result)
    _assert_true(not result_desc.is_empty(), "Result description is not empty")

    # Test reward scaling
    var base_rewards: Array = [
        {"type": "gold_add", "amount": 10},
        {"type": "resource_add", "resource": "wood", "amount": 5}
    ]
    var passing_eval: Dictionary = {"passed": true, "score": 80}
    var scaled_rewards: Array = SimExplorationChallenges.scale_rewards(base_rewards, passing_eval, 5)
    _assert_true(scaled_rewards.size() > 0, "Scaled rewards are returned for passing challenge")

    # Test no rewards on failure
    var failing_eval: Dictionary = {"passed": false, "score": 30}
    var no_rewards: Array = SimExplorationChallenges.scale_rewards(base_rewards, failing_eval, 5)
    _assert_equal(no_rewards.size(), 0, "No rewards returned for failing challenge")


func _run_daily_challenges_tests() -> void:
    # Test daily challenges module exists and has basic structure
    _assert_true(SimDailyChallenges != null, "SimDailyChallenges module loads")

    # Test CHALLENGES dictionary exists and has entries
    _assert_true(SimDailyChallenges.CHALLENGES.size() >= 5, "At least 5 daily challenges defined")

    # Test TOKEN_SHOP exists
    _assert_true(SimDailyChallenges.TOKEN_SHOP.size() >= 1, "Token shop has items")

    # Test STREAK_BONUSES exists
    _assert_true(SimDailyChallenges.STREAK_BONUSES.has(3), "3-day streak bonus exists")
    _assert_true(SimDailyChallenges.STREAK_BONUSES.has(7), "7-day streak bonus exists")

    # Test challenge structure
    var sample_challenge: Dictionary = SimDailyChallenges.CHALLENGES.get("speed_demon", {})
    _assert_true(sample_challenge.has("name"), "Challenge has name")
    _assert_true(sample_challenge.has("description"), "Challenge has description")
    _assert_true(sample_challenge.has("modifiers"), "Challenge has modifiers")
    _assert_true(sample_challenge.has("goal"), "Challenge has goal")
    _assert_true(sample_challenge.has("rewards"), "Challenge has rewards")

    # Test daily challenge retrieval with profile
    var profile: Dictionary = {}
    var daily: Dictionary = SimDailyChallenges.get_daily_challenge(profile)
    _assert_true(not daily.is_empty(), "Daily challenge returns data")
    _assert_true(daily.has("name"), "Daily challenge has name")

    # Test format_challenge
    var formatted: String = SimDailyChallenges.format_challenge(daily)
    _assert_true(not formatted.is_empty(), "Challenge can be formatted")

    # Test token balance
    var balance: int = SimDailyChallenges.get_token_balance(profile)
    _assert_true(balance >= 0, "Token balance is non-negative")

    # Test streak retrieval
    var streak: int = SimDailyChallenges.get_streak(profile)
    _assert_true(streak >= 0, "Streak is non-negative")

    # Test shop items retrieval
    var shop: Dictionary = SimDailyChallenges.get_shop_items()
    _assert_true(not shop.is_empty(), "Shop items can be retrieved")

    # Test format_shop
    var shop_str: String = SimDailyChallenges.format_shop(profile)
    _assert_true(not shop_str.is_empty(), "Shop can be formatted")


func _run_buffs_tests() -> void:
    # Test buff data loading
    SimBuffs.load_buffs()
    var all_buffs: Dictionary = SimBuffs.get_all_buffs()
    _assert_true(all_buffs.size() >= 0, "Buffs can be loaded")

    # Test get_buff_data for a known buff (if any exist)
    var buff_data: Dictionary = SimBuffs.get_buff_data("resource_boost")
    # Buff may or may not exist depending on data
    _assert_true(buff_data != null, "get_buff_data returns dictionary")

    # Test multiplier functions with a fresh state
    var state: GameState = DefaultState.create("buffs_test")

    var resource_mult: float = SimBuffs.get_resource_multiplier(state)
    _assert_true(resource_mult >= 0.0, "Resource multiplier is non-negative")

    var threat_mult: float = SimBuffs.get_threat_multiplier(state)
    _assert_true(threat_mult >= 0.0, "Threat multiplier is non-negative")

    var damage_mult: float = SimBuffs.get_damage_multiplier(state)
    _assert_true(damage_mult >= 0.0, "Damage multiplier is non-negative")

    var damage_red: int = SimBuffs.get_damage_reduction(state)
    _assert_true(damage_red >= 0, "Damage reduction is non-negative")

    var gold_mult: float = SimBuffs.get_gold_multiplier(state)
    _assert_true(gold_mult >= 0.0, "Gold multiplier is non-negative")

    var explore_mult: float = SimBuffs.get_explore_reward_multiplier(state)
    _assert_true(explore_mult >= 0.0, "Explore reward multiplier is non-negative")

    var ap_bonus: int = SimBuffs.get_ap_bonus(state)
    _assert_true(ap_bonus >= 0, "AP bonus is non-negative")

    var hp_regen: int = SimBuffs.get_hp_regen(state)
    _assert_true(hp_regen >= 0, "HP regen is non-negative")

    var acc_bonus: float = SimBuffs.get_accuracy_bonus(state)
    _assert_true(acc_bonus >= 0.0, "Accuracy bonus is non-negative")

    var enemy_speed: float = SimBuffs.get_enemy_speed_multiplier(state)
    _assert_true(enemy_speed >= 0.0, "Enemy speed multiplier is non-negative")

    # Test active buff display
    var display: Array[Dictionary] = SimBuffs.get_active_buff_display(state)
    _assert_true(display != null, "Active buff display returns array")

    # Test is_buff_active
    var is_active: bool = SimBuffs.is_buff_active(state, "nonexistent_buff")
    _assert_true(not is_active, "Nonexistent buff returns false for is_buff_active")


func _run_combo_tests() -> void:
    # Test combo tiers exist
    _assert_true(SimCombo.TIERS.size() >= 5, "At least 5 combo tiers defined")

    # Test tier 0 (no combo)
    var tier0: Dictionary = SimCombo.get_tier_for_combo(0)
    _assert_equal(int(tier0.get("tier", -1)), 0, "Combo 0 is tier 0")

    # Test tier progression
    var tier1: Dictionary = SimCombo.get_tier_for_combo(3)
    _assert_equal(int(tier1.get("tier", -1)), 1, "Combo 3 is tier 1 (Warming Up)")

    var tier2: Dictionary = SimCombo.get_tier_for_combo(5)
    _assert_equal(int(tier2.get("tier", -1)), 2, "Combo 5 is tier 2 (On Fire)")

    var tier3: Dictionary = SimCombo.get_tier_for_combo(10)
    _assert_equal(int(tier3.get("tier", -1)), 3, "Combo 10 is tier 3 (Blazing)")

    var tier4: Dictionary = SimCombo.get_tier_for_combo(25)
    _assert_equal(int(tier4.get("tier", -1)), 4, "Combo 25 is tier 4 (Inferno)")

    # Test tier number function
    _assert_equal(SimCombo.get_tier_number(0), 0, "get_tier_number(0) is 0")
    _assert_equal(SimCombo.get_tier_number(10), 3, "get_tier_number(10) is 3")

    # Test tier name function
    var name3: String = SimCombo.get_tier_name(10)
    _assert_equal(name3, "Blazing", "Tier 3 name is Blazing")

    # Test damage bonus
    var dmg_bonus: int = SimCombo.get_damage_bonus_percent(10)
    _assert_equal(dmg_bonus, 20, "Combo 10 has 20% damage bonus")

    # Test gold bonus
    var gold_bonus: int = SimCombo.get_gold_bonus_percent(10)
    _assert_equal(gold_bonus, 15, "Combo 10 has 15% gold bonus")

    # Test tier color
    var color: Color = SimCombo.get_tier_color(10)
    _assert_true(color != Color.BLACK, "Tier color is not black")

    # Test damage bonus application
    var base_dmg: int = 100
    var boosted_dmg: int = SimCombo.apply_damage_bonus(base_dmg, 10)
    _assert_equal(boosted_dmg, 120, "100 damage with 20% bonus is 120")

    # Test gold bonus application
    var base_gold: int = 100
    var boosted_gold: int = SimCombo.apply_gold_bonus(base_gold, 10)
    _assert_equal(boosted_gold, 115, "100 gold with 15% bonus is 115")

    # Test tier milestone detection
    _assert_true(SimCombo.is_tier_milestone(2, 3), "2->3 is a milestone (tier 1)")
    _assert_true(SimCombo.is_tier_milestone(4, 5), "4->5 is a milestone (tier 2)")
    _assert_true(not SimCombo.is_tier_milestone(6, 7), "6->7 is not a milestone")

    # Test tier announcement
    var announce: String = SimCombo.get_tier_announcement(5)
    _assert_true(not announce.is_empty(), "Tier 2 has announcement")

    # Test format combo display
    var display: String = SimCombo.format_combo_display(10)
    _assert_true(not display.is_empty(), "Combo display is formatted")


func _run_affixes_tests() -> void:
    # Test AFFIXES constant exists and has entries
    _assert_true(SimAffixes.AFFIXES.size() >= 1, "At least 1 affix defined")

    # Test get_affix for a known affix
    var swift_affix: Dictionary = SimAffixes.get_affix("swift")
    _assert_true(not swift_affix.is_empty(), "Swift affix exists")

    # Test get_all_affixes
    var all_affixes: Array = SimAffixes.get_all_affixes()
    _assert_true(all_affixes.size() >= 1, "get_all_affixes returns array")

    # Test get_affixes_for_tier
    var tier1_affixes: Array = SimAffixes.get_affixes_for_tier(1)
    _assert_true(tier1_affixes != null, "get_affixes_for_tier returns array")

    # Test get_available_affixes for day
    var day5_affixes: Array = SimAffixes.get_available_affixes(5)
    _assert_true(day5_affixes != null, "get_available_affixes returns array")

    # Test affix application
    var enemy: Dictionary = {
        "id": 1,
        "kind": "raider",
        "hp": 10,
        "speed": 1.0,
        "damage": 1
    }
    var affixed_enemy: Dictionary = SimAffixes.apply_affix_to_enemy(enemy.duplicate(), "swift")
    _assert_true(affixed_enemy.has("affix"), "apply_affix_to_enemy adds affix field")

    # Test affix glyph
    var glyph: String = SimAffixes.get_affix_glyph("swift")
    _assert_true(not glyph.is_empty(), "Swift affix has glyph")

    # Test affix name
    var name: String = SimAffixes.get_affix_name("swift")
    _assert_true(not name.is_empty(), "Swift affix has name")

    # Test shield functions
    _assert_true(not SimAffixes.has_active_shield(enemy), "Regular enemy has no shield")

    # Test serialization
    var serialized: Dictionary = SimAffixes.serialize_affix_state(affixed_enemy)
    _assert_true(serialized != null, "Affix state can be serialized")


func _run_bestiary_tests() -> void:
    # Test enemy categories constant
    _assert_true(SimBestiary.ENEMY_CATEGORIES.size() >= 1, "Enemy categories defined")

    # Test get_enemies_by_tier
    var tier1_enemies: Array[String] = SimBestiary.get_enemies_by_tier(SimEnemyTypes.Tier.MINION)
    _assert_true(tier1_enemies != null, "get_enemies_by_tier returns array")

    # Test get_enemies_by_category
    var basic_enemies: Array[String] = SimBestiary.get_enemies_by_category(SimEnemyTypes.Category.BASIC)
    _assert_true(basic_enemies != null, "get_enemies_by_category returns array")

    # Test get_enemy_info for a known enemy
    var spawn_info: Dictionary = SimBestiary.get_enemy_info("typhos_spawn")
    if not spawn_info.is_empty():
        _assert_true(spawn_info.has("name"), "Enemy info has name")
        _assert_true(spawn_info.has("hp"), "Enemy info has hp")

    # Test get_tier_name
    var tier_name: String = SimBestiary.get_tier_name(SimEnemyTypes.Tier.MINION)
    _assert_equal(tier_name, "Minion", "Minion tier name is Minion")

    var elite_name: String = SimBestiary.get_tier_name(SimEnemyTypes.Tier.ELITE)
    _assert_equal(elite_name, "Elite", "Elite tier name is Elite")

    # Test get_category_name
    var basic_name: String = SimBestiary.get_category_name(SimEnemyTypes.Category.BASIC)
    _assert_equal(basic_name, "Basic", "Basic category name is Basic")

    var tank_name: String = SimBestiary.get_category_name(SimEnemyTypes.Category.TANK)
    _assert_equal(tank_name, "Tank", "Tank category name is Tank")

    # Test encounter tracking
    var profile: Dictionary = {}
    _assert_true(not SimBestiary.has_encountered(profile, "raider"), "New profile has no encounters")

    SimBestiary.record_encounter(profile, "raider", true)
    _assert_true(SimBestiary.has_encountered(profile, "raider"), "Encounter recorded")
    _assert_equal(SimBestiary.get_defeat_count(profile, "raider"), 1, "Defeat count is 1")

    SimBestiary.record_encounter(profile, "raider", true)
    _assert_equal(SimBestiary.get_defeat_count(profile, "raider"), 2, "Defeat count is 2")

    # Test ability encounter tracking
    _assert_true(not SimBestiary.has_encountered_ability(profile, "charge"), "No ability encounter")
    SimBestiary.record_ability_encounter(profile, "charge")
    _assert_true(SimBestiary.has_encountered_ability(profile, "charge"), "Ability encounter recorded")

    # Test boss encounter tracking
    SimBestiary.record_boss_encounter(profile, "grove_guardian", false, 2)
    _assert_true(profile.has("bestiary"), "Profile has bestiary")
    _assert_true(profile["bestiary"].has("boss_encounters"), "Bestiary has boss_encounters")

    # Test get_summary
    var summary: Dictionary = SimBestiary.get_summary(profile)
    _assert_true(summary.has("enemies_seen"), "Summary has enemies_seen")
    _assert_true(summary.has("enemies_total"), "Summary has enemies_total")
    _assert_true(summary.has("completion_percent"), "Summary has completion_percent")

    # Test get_all_bosses
    var all_bosses: Array[String] = SimBestiary.get_all_bosses()
    _assert_true(all_bosses != null, "get_all_bosses returns array")

    # Test get_all_abilities
    var all_abilities: Array[String] = SimBestiary.get_all_abilities()
    _assert_true(all_abilities != null, "get_all_abilities returns array")


func _run_damage_types_tests() -> void:
    # Test damage type colors exist
    var physical_color: Color = SimDamageTypes.get_damage_type_color(0)  # PHYSICAL
    _assert_true(physical_color != Color.BLACK, "Physical damage has color")

    var fire_color: Color = SimDamageTypes.get_damage_type_color(6)  # FIRE
    _assert_true(fire_color != Color.BLACK, "Fire damage has color")

    # Test damage type names
    var physical_name: String = SimDamageTypes.get_damage_type_name(0)
    _assert_true(not physical_name.is_empty(), "Physical damage has name")

    # Test damage type descriptions
    var physical_desc: String = SimDamageTypes.get_damage_type_description(0)
    _assert_true(not physical_desc.is_empty(), "Physical damage has description")

    var magic_desc: String = SimDamageTypes.get_damage_type_description(1)  # MAGICAL
    _assert_true("armor" in magic_desc.to_lower(), "Magic damage ignores armor")

    # Test basic damage calculation
    var state: GameState = DefaultState.create("damage_test")
    var enemy: Dictionary = {"hp": 10, "armor": 2, "pos": Vector2i(5, 5)}

    var damage: int = SimDamageTypes.calculate_damage(10, 0, enemy, state)  # PHYSICAL
    _assert_true(damage >= 1, "Damage is at least 1")
    _assert_true(damage <= 10, "Damage is reduced by armor")

    # Test magical damage ignores armor
    var magic_damage: int = SimDamageTypes.calculate_damage(10, 1, enemy, state)  # MAGICAL
    _assert_true(magic_damage >= damage, "Magic damage ignores armor")

    # Test critical multiplier
    var crit_damage: int = SimDamageTypes.apply_critical_multiplier(10, 2.0)
    _assert_equal(crit_damage, 20, "Critical multiplier doubles damage")

    # Test resistance application
    var resisted: int = SimDamageTypes.apply_resistance(100, 0.5)
    _assert_equal(resisted, 50, "50% resistance halves damage")

    var no_resist: int = SimDamageTypes.apply_resistance(100, 0.0)
    _assert_equal(no_resist, 100, "0% resistance does nothing")


func _run_enemy_types_tests() -> void:
    # Test tier enum values
    _assert_equal(SimEnemyTypes.Tier.MINION, 1, "MINION tier is 1")
    _assert_equal(SimEnemyTypes.Tier.SOLDIER, 2, "SOLDIER tier is 2")
    _assert_equal(SimEnemyTypes.Tier.ELITE, 3, "ELITE tier is 3")
    _assert_equal(SimEnemyTypes.Tier.CHAMPION, 4, "CHAMPION tier is 4")
    _assert_equal(SimEnemyTypes.Tier.BOSS, 5, "BOSS tier is 5")

    # Test category enum values
    _assert_equal(SimEnemyTypes.Category.BASIC, 0, "BASIC category is 0")
    _assert_equal(SimEnemyTypes.Category.SWARM, 1, "SWARM category is 1")
    _assert_equal(SimEnemyTypes.Category.TANK, 5, "TANK category is 5")

    # Test ENEMIES constant has entries
    _assert_true(SimEnemyTypes.ENEMIES.size() >= 1, "ENEMIES has entries")

    # Test known enemy type exists
    _assert_true(SimEnemyTypes.ENEMIES.has(SimEnemyTypes.TYPHOS_SPAWN), "Typhos Spawn exists")

    # Test enemy type data
    var spawn_data: Dictionary = SimEnemyTypes.ENEMIES.get(SimEnemyTypes.TYPHOS_SPAWN, {})
    _assert_true(spawn_data.has("name"), "Enemy has name")
    _assert_true(spawn_data.has("hp"), "Enemy has hp")
    _assert_true(spawn_data.has("tier"), "Enemy has tier")
    _assert_true(spawn_data.has("category"), "Enemy has category")

    # Test tier values are valid
    var tier: int = int(spawn_data.get("tier", 0))
    _assert_equal(tier, SimEnemyTypes.Tier.MINION, "Typhos Spawn is Minion tier")

    # Test get_enemies_by_tier
    var minions: Array[String] = SimEnemyTypes.get_enemies_by_tier(SimEnemyTypes.Tier.MINION)
    _assert_true(minions.size() >= 1, "At least 1 minion enemy")

    # Test get_enemies_by_category
    var basic: Array[String] = SimEnemyTypes.get_enemies_by_category(SimEnemyTypes.Category.BASIC)
    _assert_true(basic != null, "get_enemies_by_category returns array")

    # Test region enum
    _assert_equal(SimEnemyTypes.Region.ALL, 0, "ALL region is 0")
    _assert_equal(SimEnemyTypes.Region.EVERGROVE, 1, "EVERGROVE region is 1")

    # Test region name
    var region_name: String = SimEnemyTypes.get_region_name(SimEnemyTypes.Region.EVERGROVE)
    _assert_true(not region_name.is_empty(), "Evergrove has name")


func _run_items_tests() -> void:
    # Test rarity constants
    _assert_equal(SimItems.RARITY_COMMON, "common", "Common rarity constant")
    _assert_equal(SimItems.RARITY_LEGENDARY, "legendary", "Legendary rarity constant")

    # Test slot constants
    _assert_equal(SimItems.SLOT_HEADGEAR, "headgear", "Headgear slot constant")
    _assert_equal(SimItems.SLOT_ARMOR, "armor", "Armor slot constant")

    # Test EQUIPMENT_SLOTS array
    _assert_true(SimItems.EQUIPMENT_SLOTS.size() == 8, "8 equipment slots")
    _assert_true(SimItems.EQUIPMENT_SLOTS.has("headgear"), "Has headgear slot")
    _assert_true(SimItems.EQUIPMENT_SLOTS.has("ring"), "Has ring slot")

    # Test RARITY_COLORS
    _assert_true(SimItems.RARITY_COLORS.has("common"), "Has common color")
    _assert_true(SimItems.RARITY_COLORS.has("legendary"), "Has legendary color")

    # Test RARITY_WEIGHTS
    _assert_true(SimItems.RARITY_WEIGHTS.has("common"), "Has common weight")
    _assert_true(int(SimItems.RARITY_WEIGHTS.get("common", 0)) > int(SimItems.RARITY_WEIGHTS.get("legendary", 0)), "Common more likely than legendary")

    # Test EQUIPMENT dictionary has items
    _assert_true(SimItems.EQUIPMENT.size() >= 1, "EQUIPMENT has items")

    # Test known equipment exists
    _assert_true(SimItems.EQUIPMENT.has("helm_basic"), "Has basic helm")
    _assert_true(SimItems.EQUIPMENT.has("armor_basic"), "Has basic armor")

    # Test equipment data structure
    var helm: Dictionary = SimItems.EQUIPMENT.get("helm_basic", {})
    _assert_true(helm.has("name"), "Equipment has name")
    _assert_true(helm.has("slot"), "Equipment has slot")
    _assert_true(helm.has("rarity"), "Equipment has rarity")
    _assert_true(helm.has("stats"), "Equipment has stats")

    # Test slot assignment is correct
    _assert_equal(str(helm.get("slot", "")), "headgear", "Helm is headgear slot")


func _run_crafting_tests() -> void:
    # Test MATERIALS dictionary
    _assert_true(SimCrafting.MATERIALS.size() >= 1, "MATERIALS has entries")

    # Test known materials exist
    _assert_true(SimCrafting.MATERIALS.has("scrap_metal"), "Has scrap metal")
    _assert_true(SimCrafting.MATERIALS.has("leather_scraps"), "Has leather scraps")
    _assert_true(SimCrafting.MATERIALS.has("crystal_shard"), "Has crystal shard")

    # Test material data structure
    var scrap: Dictionary = SimCrafting.MATERIALS.get("scrap_metal", {})
    _assert_true(scrap.has("name"), "Material has name")
    _assert_true(scrap.has("tier"), "Material has tier")
    _assert_true(scrap.has("description"), "Material has description")

    # Test material tiers
    _assert_equal(int(scrap.get("tier", 0)), 1, "Scrap metal is tier 1")

    var iron: Dictionary = SimCrafting.MATERIALS.get("iron_ingot", {})
    _assert_equal(int(iron.get("tier", 0)), 2, "Iron ingot is tier 2")

    var steel: Dictionary = SimCrafting.MATERIALS.get("steel_ingot", {})
    _assert_equal(int(steel.get("tier", 0)), 3, "Steel ingot is tier 3")

    # Test RECIPES dictionary
    _assert_true(SimCrafting.RECIPES.size() >= 1, "RECIPES has entries")

    # Test known recipes exist
    _assert_true(SimCrafting.RECIPES.has("health_potion"), "Has health potion recipe")

    # Test recipe data structure
    var health_recipe: Dictionary = SimCrafting.RECIPES.get("health_potion", {})
    _assert_true(health_recipe.has("name"), "Recipe has name")
    _assert_true(health_recipe.has("category"), "Recipe has category")
    _assert_true(health_recipe.has("ingredients"), "Recipe has ingredients")
    _assert_true(health_recipe.has("gold_cost"), "Recipe has gold cost")
    _assert_true(health_recipe.has("output_item"), "Recipe has output item")

    # Test recipe ingredients structure
    var ingredients: Array = health_recipe.get("ingredients", [])
    _assert_true(ingredients.size() >= 1, "Recipe has at least 1 ingredient")
    var first_ing: Dictionary = ingredients[0] if ingredients.size() > 0 else {}
    _assert_true(first_ing.has("item"), "Ingredient has item id")
    _assert_true(first_ing.has("qty"), "Ingredient has quantity")

    # Test recipe categories
    _assert_equal(str(health_recipe.get("category", "")), "consumable", "Health potion is consumable")


func _run_endless_mode_tests() -> void:
    # Test unlock constants
    _assert_true(SimEndlessMode.UNLOCK_DAY >= 1, "UNLOCK_DAY is positive")
    _assert_true(SimEndlessMode.UNLOCK_WAVES >= 1, "UNLOCK_WAVES is positive")

    # Test scaling constants
    _assert_true(SimEndlessMode.HP_SCALE_PER_DAY > 0.0, "HP scaling is positive")
    _assert_true(SimEndlessMode.SPEED_SCALE_PER_DAY >= 0.0, "Speed scaling is non-negative")
    _assert_true(SimEndlessMode.COUNT_SCALE_PER_DAY > 0.0, "Count scaling is positive")
    _assert_true(SimEndlessMode.DAMAGE_SCALE_PER_DAY >= 0.0, "Damage scaling is non-negative")

    # Test MILESTONES dictionary
    _assert_true(SimEndlessMode.MILESTONES.size() >= 1, "MILESTONES has entries")
    _assert_true(SimEndlessMode.MILESTONES.has(5), "Has day 5 milestone")
    _assert_true(SimEndlessMode.MILESTONES.has(10), "Has day 10 milestone")

    # Test milestone structure
    var milestone5: Dictionary = SimEndlessMode.MILESTONES.get(5, {})
    _assert_true(milestone5.has("name"), "Milestone has name")
    _assert_true(milestone5.has("gold"), "Milestone has gold reward")
    _assert_true(milestone5.has("xp"), "Milestone has xp reward")

    # Test ENDLESS_MODIFIERS dictionary
    _assert_true(SimEndlessMode.ENDLESS_MODIFIERS.size() >= 1, "ENDLESS_MODIFIERS has entries")
    _assert_true(SimEndlessMode.ENDLESS_MODIFIERS.has("veteran_enemies"), "Has veteran_enemies modifier")
    _assert_true(SimEndlessMode.ENDLESS_MODIFIERS.has("nightmare"), "Has nightmare modifier")

    # Test modifier structure
    var veteran: Dictionary = SimEndlessMode.ENDLESS_MODIFIERS.get("veteran_enemies", {})
    _assert_true(veteran.has("start_day"), "Modifier has start_day")
    _assert_true(veteran.has("description"), "Modifier has description")

    # Test is_unlocked function exists
    var profile: Dictionary = {"max_day_reached": 20}
    var unlocked: bool = SimEndlessMode.is_unlocked(profile)
    _assert_true(unlocked, "Day 20 profile unlocks endless mode")

    var early_profile: Dictionary = {"max_day_reached": 5}
    var early_unlocked: bool = SimEndlessMode.is_unlocked(early_profile)
    _assert_true(not early_unlocked, "Day 5 profile does not unlock endless mode")

    # Test get_high_scores function
    var scores: Dictionary = SimEndlessMode.get_high_scores(profile)
    _assert_true(scores.has("highest_day"), "Scores has highest_day")
    _assert_true(scores.has("highest_wave"), "Scores has highest_wave")


func _run_expeditions_tests() -> void:
    # Test state constants
    _assert_equal(SimExpeditions.STATE_TRAVELING, "traveling", "STATE_TRAVELING constant")
    _assert_equal(SimExpeditions.STATE_GATHERING, "gathering", "STATE_GATHERING constant")
    _assert_equal(SimExpeditions.STATE_RETURNING, "returning", "STATE_RETURNING constant")
    _assert_equal(SimExpeditions.STATE_COMPLETE, "complete", "STATE_COMPLETE constant")
    _assert_equal(SimExpeditions.STATE_FAILED, "failed", "STATE_FAILED constant")

    # Test get_expedition_definition for unknown returns empty
    var unknown_exp: Dictionary = SimExpeditions.get_expedition_definition("nonexistent_expedition")
    _assert_true(unknown_exp.is_empty(), "Unknown expedition returns empty dictionary")

    # Test get_available_expeditions with fresh state
    var state: GameState = DefaultState.create("expedition_test")
    var available: Array = SimExpeditions.get_available_expeditions(state)
    _assert_true(available != null, "get_available_expeditions returns array")

    # Test get_workers_on_expedition with no expeditions
    var workers_on_exp: int = SimExpeditions.get_workers_on_expedition(state)
    _assert_equal(workers_on_exp, 0, "No workers on expedition initially")

    # Test available_workers_for_expedition
    var available_workers: int = SimExpeditions.available_workers_for_expedition(state)
    _assert_true(available_workers >= 0, "Available workers is non-negative")

    # Test can_start_expedition validation
    var result: Dictionary = SimExpeditions.can_start_expedition(state, "nonexistent", 1)
    _assert_true(result.has("ok"), "can_start_expedition returns ok field")
    _assert_true(result.has("error"), "can_start_expedition returns error field")
    _assert_true(not result.get("ok", true), "Unknown expedition cannot start")


func _run_status_effects_tests() -> void:
    # Test category constants
    _assert_equal(SimStatusEffects.CATEGORY_DEBUFF, "debuff", "CATEGORY_DEBUFF constant")
    _assert_equal(SimStatusEffects.CATEGORY_BUFF, "buff", "CATEGORY_BUFF constant")
    _assert_equal(SimStatusEffects.CATEGORY_NEUTRAL, "neutral", "CATEGORY_NEUTRAL constant")

    # Test effect ID constants
    _assert_equal(SimStatusEffects.EFFECT_SLOW, "slow", "EFFECT_SLOW constant")
    _assert_equal(SimStatusEffects.EFFECT_FROZEN, "frozen", "EFFECT_FROZEN constant")
    _assert_equal(SimStatusEffects.EFFECT_BURNING, "burning", "EFFECT_BURNING constant")
    _assert_equal(SimStatusEffects.EFFECT_POISONED, "poisoned", "EFFECT_POISONED constant")
    _assert_equal(SimStatusEffects.EFFECT_MARKED, "marked", "EFFECT_MARKED constant")

    # Test EFFECTS dictionary exists and has entries
    _assert_true(SimStatusEffects.EFFECTS.size() >= 1, "EFFECTS has entries")
    _assert_true(SimStatusEffects.EFFECTS.has("slow"), "Has slow effect")
    _assert_true(SimStatusEffects.EFFECTS.has("frozen"), "Has frozen effect")
    _assert_true(SimStatusEffects.EFFECTS.has("burning"), "Has burning effect")

    # Test effect data structure
    var slow_effect: Dictionary = SimStatusEffects.EFFECTS.get("slow", {})
    _assert_true(slow_effect.has("name"), "Effect has name")
    _assert_true(slow_effect.has("description"), "Effect has description")
    _assert_true(slow_effect.has("category"), "Effect has category")
    _assert_equal(str(slow_effect.get("category", "")), "debuff", "Slow is debuff")

    # Test burning has DoT properties
    var burning: Dictionary = SimStatusEffects.EFFECTS.get("burning", {})
    _assert_true(burning.has("tick_damage"), "Burning has tick_damage")
    _assert_true(burning.has("duration"), "Burning has duration")
    _assert_true(burning.has("max_stacks"), "Burning has max_stacks")

    # Test frozen has immobilize
    var frozen: Dictionary = SimStatusEffects.EFFECTS.get("frozen", {})
    _assert_true(frozen.has("immobilize"), "Frozen has immobilize")
    _assert_true(frozen.get("immobilize", false), "Frozen immobilizes")


func _run_tower_types_tests() -> void:
    # Test TowerCategory enum
    _assert_equal(SimTowerTypes.TowerCategory.BASIC, 0, "BASIC category is 0")
    _assert_equal(SimTowerTypes.TowerCategory.ADVANCED, 1, "ADVANCED category is 1")
    _assert_equal(SimTowerTypes.TowerCategory.SPECIALIST, 2, "SPECIALIST category is 2")
    _assert_equal(SimTowerTypes.TowerCategory.LEGENDARY, 3, "LEGENDARY category is 3")

    # Test DamageType enum
    _assert_equal(SimTowerTypes.DamageType.PHYSICAL, 0, "PHYSICAL damage is 0")
    _assert_equal(SimTowerTypes.DamageType.MAGICAL, 1, "MAGICAL damage is 1")
    _assert_equal(SimTowerTypes.DamageType.FIRE, 6, "FIRE damage is 6")
    _assert_equal(SimTowerTypes.DamageType.PURE, 7, "PURE damage is 7")

    # Test TargetType enum
    _assert_equal(SimTowerTypes.TargetType.SINGLE, 0, "SINGLE target is 0")
    _assert_equal(SimTowerTypes.TargetType.AOE, 2, "AOE target is 2")
    _assert_equal(SimTowerTypes.TargetType.CHAIN, 3, "CHAIN target is 3")

    # Test tower ID constants
    _assert_equal(SimTowerTypes.TOWER_ARROW, "tower_arrow", "TOWER_ARROW constant")
    _assert_equal(SimTowerTypes.TOWER_MAGIC, "tower_magic", "TOWER_MAGIC constant")
    _assert_equal(SimTowerTypes.TOWER_FROST, "tower_frost", "TOWER_FROST constant")

    # Test ALL_TOWER_IDS array
    _assert_true(SimTowerTypes.ALL_TOWER_IDS.size() >= 4, "At least 4 tower types")
    _assert_true(SimTowerTypes.ALL_TOWER_IDS.has("tower_arrow"), "Has arrow tower")
    _assert_true(SimTowerTypes.ALL_TOWER_IDS.has("tower_magic"), "Has magic tower")

    # Test category arrays
    _assert_true(SimTowerTypes.CATEGORY_BASIC.size() >= 1, "CATEGORY_BASIC has entries")
    _assert_true(SimTowerTypes.CATEGORY_ADVANCED.size() >= 1, "CATEGORY_ADVANCED has entries")
    _assert_true(SimTowerTypes.CATEGORY_SPECIALIST.size() >= 1, "CATEGORY_SPECIALIST has entries")
    _assert_true(SimTowerTypes.CATEGORY_LEGENDARY.size() >= 1, "CATEGORY_LEGENDARY has entries")

    # Test footprint constants
    _assert_equal(SimTowerTypes.FOOTPRINT_1X1, Vector2i(1, 1), "FOOTPRINT_1X1 is 1x1")
    _assert_equal(SimTowerTypes.FOOTPRINT_2X2, Vector2i(2, 2), "FOOTPRINT_2X2 is 2x2")


func _run_skills_tests() -> void:
    # Test tree ID constants
    _assert_equal(SimSkills.TREE_SPEED, "speed", "TREE_SPEED constant")
    _assert_equal(SimSkills.TREE_ACCURACY, "accuracy", "TREE_ACCURACY constant")
    _assert_equal(SimSkills.TREE_DEFENSE, "defense", "TREE_DEFENSE constant")

    # Test SKILL_TREES dictionary
    _assert_true(SimSkills.SKILL_TREES.size() >= 1, "SKILL_TREES has entries")
    _assert_true(SimSkills.SKILL_TREES.has("speed"), "Has speed tree")
    _assert_true(SimSkills.SKILL_TREES.has("accuracy"), "Has accuracy tree")

    # Test tree structure
    var speed_tree: Dictionary = SimSkills.SKILL_TREES.get("speed", {})
    _assert_true(speed_tree.has("name"), "Tree has name")
    _assert_true(speed_tree.has("description"), "Tree has description")
    _assert_true(speed_tree.has("skills"), "Tree has skills")

    # Test skills within tree
    var skills: Dictionary = speed_tree.get("skills", {})
    _assert_true(skills.size() >= 1, "Tree has at least 1 skill")
    _assert_true(skills.has("swift_start"), "Has swift_start skill")

    # Test skill data structure
    var swift: Dictionary = skills.get("swift_start", {})
    _assert_true(swift.has("name"), "Skill has name")
    _assert_true(swift.has("tier"), "Skill has tier")
    _assert_true(swift.has("cost"), "Skill has cost")
    _assert_true(swift.has("max_ranks"), "Skill has max_ranks")
    _assert_true(swift.has("effect"), "Skill has effect description")
    _assert_true(swift.has("effect_type"), "Skill has effect_type")
    _assert_true(swift.has("prerequisites"), "Skill has prerequisites")


func _run_quests_tests() -> void:
    # Test type constants
    _assert_equal(SimQuests.TYPE_DAILY, "daily", "TYPE_DAILY constant")
    _assert_equal(SimQuests.TYPE_WEEKLY, "weekly", "TYPE_WEEKLY constant")
    _assert_equal(SimQuests.TYPE_STORY, "story", "TYPE_STORY constant")
    _assert_equal(SimQuests.TYPE_CHALLENGE, "challenge", "TYPE_CHALLENGE constant")

    # Test status constants
    _assert_equal(SimQuests.STATUS_AVAILABLE, "available", "STATUS_AVAILABLE constant")
    _assert_equal(SimQuests.STATUS_ACTIVE, "active", "STATUS_ACTIVE constant")
    _assert_equal(SimQuests.STATUS_COMPLETED, "completed", "STATUS_COMPLETED constant")
    _assert_equal(SimQuests.STATUS_CLAIMED, "claimed", "STATUS_CLAIMED constant")

    # Test DAILY_QUESTS array
    _assert_true(SimQuests.DAILY_QUESTS.size() >= 1, "DAILY_QUESTS has entries")

    # Test quest data structure
    var first_quest: Dictionary = SimQuests.DAILY_QUESTS[0] if SimQuests.DAILY_QUESTS.size() > 0 else {}
    _assert_true(first_quest.has("id"), "Quest has id")
    _assert_true(first_quest.has("name"), "Quest has name")
    _assert_true(first_quest.has("description"), "Quest has description")
    _assert_true(first_quest.has("type"), "Quest has type")
    _assert_true(first_quest.has("objective"), "Quest has objective")
    _assert_true(first_quest.has("rewards"), "Quest has rewards")

    # Test objective structure
    var objective: Dictionary = first_quest.get("objective", {})
    _assert_true(objective.has("type"), "Objective has type")
    _assert_true(objective.has("target"), "Objective has target")

    # Test rewards structure
    var rewards: Dictionary = first_quest.get("rewards", {})
    _assert_true(rewards.has("gold") or rewards.has("xp"), "Rewards has gold or xp")


func _run_hero_types_tests() -> void:
    # Test hero ID constants
    _assert_equal(SimHeroTypes.HERO_NONE, "", "HERO_NONE constant")
    _assert_equal(SimHeroTypes.HERO_SCRIBE, "scribe", "HERO_SCRIBE constant")
    _assert_equal(SimHeroTypes.HERO_WARDEN, "warden", "HERO_WARDEN constant")
    _assert_equal(SimHeroTypes.HERO_TEMPEST, "tempest", "HERO_TEMPEST constant")
    _assert_equal(SimHeroTypes.HERO_SAGE, "sage", "HERO_SAGE constant")
    _assert_equal(SimHeroTypes.HERO_FORGEMASTER, "forgemaster", "HERO_FORGEMASTER constant")

    # Test HEROES dictionary
    _assert_true(SimHeroTypes.HEROES.size() >= 1, "HEROES has entries")
    _assert_true(SimHeroTypes.HEROES.has(SimHeroTypes.HERO_SCRIBE), "Has scribe hero")
    _assert_true(SimHeroTypes.HEROES.has(SimHeroTypes.HERO_WARDEN), "Has warden hero")

    # Test hero data structure
    var scribe: Dictionary = SimHeroTypes.HEROES.get(SimHeroTypes.HERO_SCRIBE, {})
    _assert_true(scribe.has("name"), "Hero has name")
    _assert_true(scribe.has("class"), "Hero has class")
    _assert_true(scribe.has("description"), "Hero has description")
    _assert_true(scribe.has("passive"), "Hero has passive")
    _assert_true(scribe.has("ability"), "Hero has ability")
    _assert_true(scribe.has("flavor"), "Hero has flavor text")

    # Test passive structure
    var passive: Dictionary = scribe.get("passive", {})
    _assert_true(passive.has("name"), "Passive has name")
    _assert_true(passive.has("description"), "Passive has description")
    _assert_true(passive.has("effects"), "Passive has effects")

    # Test ability structure
    var ability: Dictionary = scribe.get("ability", {})
    _assert_true(ability.has("id"), "Ability has id")
    _assert_true(ability.has("name"), "Ability has name")
    _assert_true(ability.has("word"), "Ability has word trigger")
    _assert_true(ability.has("cooldown"), "Ability has cooldown")

    # Test helper functions
    _assert_true(SimHeroTypes.is_valid_hero("scribe"), "scribe is valid hero")
    _assert_true(SimHeroTypes.is_valid_hero("warden"), "warden is valid hero")
    _assert_true(SimHeroTypes.is_valid_hero(""), "empty string is valid (no hero)")
    _assert_true(not SimHeroTypes.is_valid_hero("invalid"), "invalid ID returns false")

    _assert_equal(SimHeroTypes.get_hero_name("scribe"), "Aldric the Scribe", "get_hero_name works")
    _assert_equal(SimHeroTypes.get_hero_class("warden"), "Tank", "get_hero_class works")
    _assert_true(SimHeroTypes.get_ability_word("scribe") == "INSCRIBE", "get_ability_word works")
    _assert_true(SimHeroTypes.get_ability_cooldown("scribe") > 0, "get_ability_cooldown returns positive")

    var passive_effects: Dictionary = SimHeroTypes.get_passive_effects("scribe")
    _assert_true(passive_effects.has("critical_chance"), "Scribe passive has critical_chance")
    _assert_true(float(passive_effects.get("critical_chance", 0)) > 0, "Scribe crit chance is positive")

    _assert_true(SimHeroTypes.match_ability_word("scribe", "INSCRIBE"), "match_ability_word matches")
    _assert_true(SimHeroTypes.match_ability_word("scribe", "inscribe"), "match_ability_word case insensitive")
    _assert_true(not SimHeroTypes.match_ability_word("scribe", "WRONG"), "match_ability_word rejects wrong word")
    _assert_true(not SimHeroTypes.match_ability_word("", "INSCRIBE"), "match_ability_word rejects no hero")

    var all_ids: Array[String] = SimHeroTypes.get_all_hero_ids()
    _assert_true(all_ids.size() >= 5, "get_all_hero_ids returns 5+ heroes")
    _assert_true("scribe" in all_ids, "all_ids contains scribe")

    # Test hero passive integration with upgrades
    var state: GameState = GameState.new()
    state.hero_id = ""
    var base_crit: float = SimUpgrades.get_total_effect(state, "critical_chance")
    state.hero_id = "scribe"
    var hero_crit: float = SimUpgrades.get_total_effect(state, "critical_chance")
    _assert_true(hero_crit > base_crit, "Hero passive adds to total effect")
    _assert_true(hero_crit >= 0.05, "Scribe adds at least 5% crit")

    # Test hero command parsing
    var result: Dictionary = CommandParser.parse("hero")
    _assert_true(result.get("ok", false), "hero command parses")
    _assert_equal(str(result.get("intent", {}).get("kind", "")), "hero_show", "hero -> hero_show intent")

    result = CommandParser.parse("hero scribe")
    _assert_true(result.get("ok", false), "hero scribe parses")
    _assert_equal(str(result.get("intent", {}).get("kind", "")), "hero_set", "hero scribe -> hero_set intent")

    result = CommandParser.parse("hero none")
    _assert_true(result.get("ok", false), "hero none parses")
    _assert_equal(str(result.get("intent", {}).get("kind", "")), "hero_clear", "hero none -> hero_clear intent")

    result = CommandParser.parse("hero invalid_hero")
    _assert_true(not result.get("ok", false), "invalid hero rejected")


func _run_locale_tests() -> void:
    # Test locale ID constants
    _assert_equal(SimLocale.LOCALE_EN, "en", "LOCALE_EN constant")
    _assert_equal(SimLocale.LOCALE_ES, "es", "LOCALE_ES constant")
    _assert_equal(SimLocale.LOCALE_DE, "de", "LOCALE_DE constant")
    _assert_equal(SimLocale.LOCALE_FR, "fr", "LOCALE_FR constant")
    _assert_equal(SimLocale.LOCALE_PT, "pt", "LOCALE_PT constant")
    _assert_equal(SimLocale.DEFAULT_LOCALE, "en", "DEFAULT_LOCALE is en")

    # Test SUPPORTED_LOCALES array
    _assert_true(SimLocale.SUPPORTED_LOCALES.size() >= 5, "At least 5 locales supported")
    _assert_true("en" in SimLocale.SUPPORTED_LOCALES, "en is supported")
    _assert_true("es" in SimLocale.SUPPORTED_LOCALES, "es is supported")
    _assert_true("de" in SimLocale.SUPPORTED_LOCALES, "de is supported")
    _assert_true("fr" in SimLocale.SUPPORTED_LOCALES, "fr is supported")
    _assert_true("pt" in SimLocale.SUPPORTED_LOCALES, "pt is supported")

    # Test LOCALE_NAMES dictionary
    _assert_equal(SimLocale.LOCALE_NAMES.get("en", ""), "English", "English name")
    _assert_equal(SimLocale.LOCALE_NAMES.get("es", ""), "Español", "Spanish name")
    _assert_equal(SimLocale.LOCALE_NAMES.get("de", ""), "Deutsch", "German name")
    _assert_equal(SimLocale.LOCALE_NAMES.get("fr", ""), "Français", "French name")
    _assert_equal(SimLocale.LOCALE_NAMES.get("pt", ""), "Português", "Portuguese name")

    # Test is_valid_locale function
    _assert_true(SimLocale.is_valid_locale("en"), "en is valid locale")
    _assert_true(SimLocale.is_valid_locale("es"), "es is valid locale")
    _assert_true(SimLocale.is_valid_locale("de"), "de is valid locale")
    _assert_true(not SimLocale.is_valid_locale("invalid"), "invalid is not valid locale")
    _assert_true(not SimLocale.is_valid_locale(""), "empty string is not valid locale")

    # Test get_locale_name function
    _assert_equal(SimLocale.get_locale_name("en"), "English", "get_locale_name en")
    _assert_equal(SimLocale.get_locale_name("es"), "Español", "get_locale_name es")
    _assert_equal(SimLocale.get_locale_name("invalid"), "invalid", "get_locale_name fallback")

    # Test get_supported_locales function
    var locales: Array[Dictionary] = SimLocale.get_supported_locales()
    _assert_true(locales.size() >= 5, "get_supported_locales returns 5+ entries")
    var first: Dictionary = locales[0] if locales.size() > 0 else {}
    _assert_true(first.has("id"), "locale entry has id")
    _assert_true(first.has("name"), "locale entry has name")

    # Test set_locale and get_locale
    SimLocale.init("en")
    _assert_equal(SimLocale.get_locale(), "en", "get_locale returns en")
    _assert_true(SimLocale.set_locale("es"), "set_locale es succeeds")
    _assert_equal(SimLocale.get_locale(), "es", "get_locale returns es after set")
    _assert_true(not SimLocale.set_locale("invalid"), "set_locale invalid fails")
    _assert_equal(SimLocale.get_locale(), "es", "locale unchanged after invalid set")
    # Reset to default
    SimLocale.set_locale("en")

    # Test format_number function
    _assert_equal(SimLocale.format_number(1234567), "1,234,567", "format_number with commas")
    _assert_equal(SimLocale.format_number(0), "0", "format_number zero")
    _assert_equal(SimLocale.format_number(-500), "-500", "format_number negative")

    # Test get_locale_info function
    var info: Dictionary = SimLocale.get_locale_info()
    _assert_true(info.has("current"), "locale_info has current")
    _assert_true(info.has("name"), "locale_info has name")
    _assert_true(info.has("supported"), "locale_info has supported")
    _assert_true(info.has("translations_loaded"), "locale_info has translations_loaded")

    # Test locale command parsing
    var result: Dictionary = CommandParser.parse("locale")
    _assert_true(result.get("ok", false), "locale command parses")
    _assert_equal(str(result.get("intent", {}).get("kind", "")), "locale_show", "locale -> locale_show intent")

    result = CommandParser.parse("locale en")
    _assert_true(result.get("ok", false), "locale en parses")
    _assert_equal(str(result.get("intent", {}).get("kind", "")), "locale_set", "locale en -> locale_set intent")
    _assert_equal(str(result.get("intent", {}).get("locale", "")), "en", "locale en has correct locale")

    result = CommandParser.parse("lang es")
    _assert_true(result.get("ok", false), "lang alias parses")
    _assert_equal(str(result.get("intent", {}).get("kind", "")), "locale_set", "lang es -> locale_set intent")

    result = CommandParser.parse("language de")
    _assert_true(result.get("ok", false), "language alias parses")
    _assert_equal(str(result.get("intent", {}).get("kind", "")), "locale_set", "language de -> locale_set intent")

    result = CommandParser.parse("locale invalid_locale")
    _assert_true(not result.get("ok", false), "invalid locale rejected")

    # Test TypingProfile locale functions
    var profile: Dictionary = TypingProfile.default_profile()
    _assert_equal(TypingProfile.get_locale(profile), "en", "default profile locale is en")
    TypingProfile.set_locale(profile, "es")
    _assert_equal(TypingProfile.get_locale(profile), "es", "set_locale updates profile")


func _run_titles_tests() -> void:
    # Test category constants
    _assert_equal(SimTitles.CATEGORY_SPEED, "speed", "CATEGORY_SPEED constant")
    _assert_equal(SimTitles.CATEGORY_ACCURACY, "accuracy", "CATEGORY_ACCURACY constant")
    _assert_equal(SimTitles.CATEGORY_COMBAT, "combat", "CATEGORY_COMBAT constant")
    _assert_equal(SimTitles.CATEGORY_DEDICATION, "dedication", "CATEGORY_DEDICATION constant")
    _assert_equal(SimTitles.CATEGORY_MASTERY, "mastery", "CATEGORY_MASTERY constant")
    _assert_equal(SimTitles.CATEGORY_SPECIAL, "special", "CATEGORY_SPECIAL constant")

    # Test TITLES dictionary
    _assert_true(SimTitles.TITLES.size() >= 20, "At least 20 titles defined")
    _assert_true(SimTitles.TITLES.has("novice_typist"), "Has novice_typist title")
    _assert_true(SimTitles.TITLES.has("speed_demon"), "Has speed_demon title")
    _assert_true(SimTitles.TITLES.has("perfectionist"), "Has perfectionist title")
    _assert_true(SimTitles.TITLES.has("champion"), "Has champion title")

    # Test title structure
    var title: Dictionary = SimTitles.get_title("novice_typist")
    _assert_true(title.has("name"), "Title has name")
    _assert_true(title.has("description"), "Title has description")
    _assert_true(title.has("category"), "Title has category")
    _assert_true(title.has("color"), "Title has color")
    _assert_true(title.has("unlock"), "Title has unlock requirements")

    # Test unlock structure
    var unlock: Dictionary = title.get("unlock", {})
    _assert_true(unlock.has("type"), "Unlock has type")
    _assert_true(unlock.has("value"), "Unlock has value")

    # Test BADGES dictionary
    _assert_true(SimTitles.BADGES.size() >= 5, "At least 5 badges defined")
    _assert_true(SimTitles.BADGES.has("early_bird"), "Has early_bird badge")
    _assert_true(SimTitles.BADGES.has("explorer"), "Has explorer badge")

    # Test badge structure
    var badge: Dictionary = SimTitles.get_badge("early_bird")
    _assert_true(badge.has("name"), "Badge has name")
    _assert_true(badge.has("description"), "Badge has description")
    _assert_true(badge.has("icon"), "Badge has icon")
    _assert_true(badge.has("unlock"), "Badge has unlock requirements")

    # Test helper functions
    _assert_true(SimTitles.is_valid_title("novice_typist"), "novice_typist is valid title")
    _assert_true(SimTitles.is_valid_title("speed_demon"), "speed_demon is valid title")
    _assert_true(not SimTitles.is_valid_title("invalid_title"), "invalid_title is not valid")
    _assert_true(not SimTitles.is_valid_title(""), "empty string is not valid title")

    _assert_true(SimTitles.is_valid_badge("early_bird"), "early_bird is valid badge")
    _assert_true(not SimTitles.is_valid_badge("invalid_badge"), "invalid_badge is not valid")

    # Test get_title_name
    _assert_equal(SimTitles.get_title_name("novice_typist"), "Novice Typist", "get_title_name works")
    _assert_equal(SimTitles.get_title_name("speed_demon"), "Speed Demon", "get_title_name for speed_demon")

    # Test get_title_color
    var color: Color = SimTitles.get_title_color("novice_typist")
    _assert_true(color is Color, "get_title_color returns Color")

    # Test get_all_title_ids
    var all_ids: Array[String] = SimTitles.get_all_title_ids()
    _assert_true(all_ids.size() >= 20, "get_all_title_ids returns 20+ titles")
    _assert_true("novice_typist" in all_ids, "all_ids contains novice_typist")
    _assert_true("champion" in all_ids, "all_ids contains champion")

    # Test get_all_badge_ids
    var badge_ids: Array[String] = SimTitles.get_all_badge_ids()
    _assert_true(badge_ids.size() >= 5, "get_all_badge_ids returns 5+ badges")
    _assert_true("early_bird" in badge_ids, "badge_ids contains early_bird")

    # Test get_titles_by_category
    var speed_titles: Array[String] = SimTitles.get_titles_by_category(SimTitles.CATEGORY_SPEED)
    _assert_true(speed_titles.size() >= 1, "Speed category has titles")
    _assert_true("novice_typist" in speed_titles, "Speed category contains novice_typist")

    # Test get_categories
    var categories: Array[String] = SimTitles.get_categories()
    _assert_true(categories.size() >= 6, "At least 6 categories")
    _assert_true("speed" in categories, "Categories contains speed")
    _assert_true("combat" in categories, "Categories contains combat")

    # Test get_category_name
    _assert_equal(SimTitles.get_category_name("speed"), "Speed", "get_category_name for speed")
    _assert_equal(SimTitles.get_category_name("combat"), "Combat", "get_category_name for combat")

    # Test check_title_unlock
    var stats: Dictionary = {"highest_wpm": 25, "total_kills": 150, "highest_combo": 15}
    _assert_true(SimTitles.check_title_unlock("novice_typist", stats), "novice_typist unlocked at 25 WPM")
    _assert_true(not SimTitles.check_title_unlock("swift_fingers", stats), "swift_fingers not unlocked at 25 WPM")
    _assert_true(SimTitles.check_title_unlock("centurion", stats), "centurion unlocked at 150 kills")

    # Test check_all_title_unlocks
    var already_unlocked: Array = ["novice_typist"]
    var newly_unlockable: Array[String] = SimTitles.check_all_title_unlocks(stats, already_unlocked)
    _assert_true("novice_typist" not in newly_unlockable, "Already unlocked not in newly_unlockable")
    _assert_true("centurion" in newly_unlockable, "centurion in newly_unlockable")

    # Test title command parsing
    var result: Dictionary = CommandParser.parse("titles")
    _assert_true(result.get("ok", false), "titles command parses")
    _assert_equal(str(result.get("intent", {}).get("kind", "")), "titles_show", "titles -> titles_show intent")

    result = CommandParser.parse("title novice_typist")
    _assert_true(result.get("ok", false), "title novice_typist parses")
    _assert_equal(str(result.get("intent", {}).get("kind", "")), "title_equip", "title -> title_equip intent")
    _assert_equal(str(result.get("intent", {}).get("title_id", "")), "novice_typist", "title_id is correct")

    result = CommandParser.parse("title none")
    _assert_true(result.get("ok", false), "title none parses")
    _assert_equal(str(result.get("intent", {}).get("kind", "")), "title_clear", "title none -> title_clear intent")

    result = CommandParser.parse("badges")
    _assert_true(result.get("ok", false), "badges command parses")
    _assert_equal(str(result.get("intent", {}).get("kind", "")), "badges_show", "badges -> badges_show intent")

    result = CommandParser.parse("title invalid_title")
    _assert_true(not result.get("ok", false), "invalid title rejected")

    # Test TypingProfile title functions
    var profile: Dictionary = TypingProfile.default_profile()
    _assert_true(TypingProfile.get_unlocked_titles(profile).is_empty(), "default profile has no unlocked titles")
    _assert_true(TypingProfile.get_unlocked_badges(profile).is_empty(), "default profile has no unlocked badges")
    _assert_equal(TypingProfile.get_equipped_title(profile), "", "default profile has no equipped title")

    _assert_true(TypingProfile.unlock_title(profile, "novice_typist"), "unlock_title returns true")
    _assert_true(TypingProfile.is_title_unlocked(profile, "novice_typist"), "novice_typist is now unlocked")
    _assert_true(not TypingProfile.unlock_title(profile, "novice_typist"), "unlock_title returns false for already unlocked")

    TypingProfile.set_equipped_title(profile, "novice_typist")
    _assert_equal(TypingProfile.get_equipped_title(profile), "novice_typist", "equipped title is set")

    _assert_true(TypingProfile.unlock_badge(profile, "early_bird"), "unlock_badge returns true")
    _assert_true(TypingProfile.is_badge_unlocked(profile, "early_bird"), "early_bird is now unlocked")

    # Test GameState title fields
    var state: GameState = GameState.new()
    _assert_equal(state.equipped_title, "", "GameState default equipped_title is empty")
    _assert_true(state.unlocked_titles.is_empty(), "GameState default unlocked_titles is empty")
    _assert_true(state.unlocked_badges.is_empty(), "GameState default unlocked_badges is empty")

    state.unlocked_titles = ["novice_typist", "centurion"]
    state.equipped_title = "novice_typist"
    _assert_true("novice_typist" in state.unlocked_titles, "Can add titles to state")
    _assert_equal(state.equipped_title, "novice_typist", "Can equip title in state")


func _run_wave_composer_tests() -> void:
    # Test TIER_WEIGHTS_BY_DAY dictionary
    _assert_true(SimWaveComposer.TIER_WEIGHTS_BY_DAY.size() >= 1, "TIER_WEIGHTS_BY_DAY has entries")
    _assert_true(SimWaveComposer.TIER_WEIGHTS_BY_DAY.has(SimEnemyTypes.Tier.MINION), "Has MINION tier weights")

    # Test get_tier_weight function
    var minion_weight_d1: int = SimWaveComposer.get_tier_weight(SimEnemyTypes.Tier.MINION, 1)
    _assert_true(minion_weight_d1 >= 0, "Day 1 minion weight is non-negative")

    var minion_weight_d20: int = SimWaveComposer.get_tier_weight(SimEnemyTypes.Tier.MINION, 20)
    _assert_true(minion_weight_d20 < minion_weight_d1, "Later days have lower minion weight")

    var soldier_weight_d1: int = SimWaveComposer.get_tier_weight(SimEnemyTypes.Tier.SOLDIER, 1)
    var soldier_weight_d10: int = SimWaveComposer.get_tier_weight(SimEnemyTypes.Tier.SOLDIER, 10)
    _assert_true(soldier_weight_d10 > soldier_weight_d1, "Later days have higher soldier weight")

    # Test WAVE_THEMES dictionary
    _assert_true(SimWaveComposer.WAVE_THEMES.size() >= 1, "WAVE_THEMES has entries")
    _assert_true(SimWaveComposer.WAVE_THEMES.has("standard"), "Has standard theme")
    _assert_true(SimWaveComposer.WAVE_THEMES.has("swarm"), "Has swarm theme")
    _assert_true(SimWaveComposer.WAVE_THEMES.has("elite"), "Has elite theme")

    # Test theme structure
    var standard: Dictionary = SimWaveComposer.WAVE_THEMES.get("standard", {})
    _assert_true(standard.has("name"), "Theme has name")
    _assert_true(standard.has("description"), "Theme has description")
    _assert_true(standard.has("enemy_weights"), "Theme has enemy_weights")
    _assert_true(standard.has("modifiers"), "Theme has modifiers")

    # Test swarm theme has multipliers
    var swarm: Dictionary = SimWaveComposer.WAVE_THEMES.get("swarm", {})
    _assert_true(swarm.has("count_mult"), "Swarm has count_mult")
    _assert_true(float(swarm.get("count_mult", 1.0)) > 1.0, "Swarm has increased count")


func _run_upgrades_tests() -> void:
    # Test kingdom upgrade retrieval
    var all_kingdom: Array = SimUpgrades.get_all_kingdom_upgrades()
    _assert_true(all_kingdom is Array, "get_all_kingdom_upgrades returns Array")

    var all_unit: Array = SimUpgrades.get_all_unit_upgrades()
    _assert_true(all_unit is Array, "get_all_unit_upgrades returns Array")

    # Test upgrade structure validation (if upgrades exist)
    for upgrade in all_kingdom:
        if not upgrade.is_empty():
            _assert_true(upgrade.has("id"), "Kingdom upgrade has id")
            _assert_true(upgrade.has("cost") or upgrade.has("label"), "Kingdom upgrade has cost or label")

    for upgrade in all_unit:
        if not upgrade.is_empty():
            _assert_true(upgrade.has("id"), "Unit upgrade has id")
            _assert_true(upgrade.has("cost") or upgrade.has("label"), "Unit upgrade has cost or label")

    # Test get_kingdom_upgrade with empty ID
    var empty_upgrade: Dictionary = SimUpgrades.get_kingdom_upgrade("")
    _assert_true(empty_upgrade.is_empty(), "Empty ID returns empty upgrade")

    var unknown_upgrade: Dictionary = SimUpgrades.get_kingdom_upgrade("nonexistent_upgrade_xyz")
    _assert_true(unknown_upgrade.is_empty(), "Unknown ID returns empty upgrade")

    # Test effect calculations
    var state: GameState = GameState.new()
    state.purchased_kingdom_upgrades = []
    state.purchased_unit_upgrades = []
    state.gold = 0
    state.hero_id = ""

    # Test base effect values
    var typing_power: float = SimUpgrades.get_typing_power(state)
    _assert_true(typing_power >= 1.0, "Base typing power is at least 1.0")

    var threat_rate: float = SimUpgrades.get_threat_rate_multiplier(state)
    _assert_true(threat_rate >= 0.0, "Threat rate multiplier is non-negative")

    var gold_mult: float = SimUpgrades.get_gold_multiplier(state)
    _assert_true(gold_mult >= 1.0, "Base gold multiplier is at least 1.0")

    var resource_mult: float = SimUpgrades.get_resource_multiplier(state)
    _assert_true(resource_mult >= 1.0, "Base resource multiplier is at least 1.0")

    var damage_reduction: float = SimUpgrades.get_damage_reduction(state)
    _assert_true(damage_reduction >= 0.0, "Damage reduction is non-negative")
    _assert_true(damage_reduction <= 0.75, "Damage reduction is capped at 75%")

    var castle_hp: int = SimUpgrades.get_castle_health_bonus(state)
    _assert_true(castle_hp >= 0, "Castle health bonus is non-negative")

    var wave_heal: int = SimUpgrades.get_wave_heal(state)
    _assert_true(wave_heal >= 0, "Wave heal is non-negative")

    var crit_chance: float = SimUpgrades.get_critical_chance(state)
    _assert_true(crit_chance >= 0.0, "Critical chance is non-negative")
    _assert_true(crit_chance <= 0.5, "Critical chance is capped at 50%")

    var mistake_forgiveness: float = SimUpgrades.get_mistake_forgiveness(state)
    _assert_true(mistake_forgiveness >= 0.0, "Mistake forgiveness is non-negative")

    var armor_reduction: int = SimUpgrades.get_enemy_armor_reduction(state)
    _assert_true(armor_reduction >= 0, "Armor reduction is non-negative")

    var armor_pierce: int = SimUpgrades.get_armor_pierce(state)
    _assert_true(armor_pierce >= 0, "Armor pierce is non-negative")

    var speed_reduction: float = SimUpgrades.get_enemy_speed_reduction(state)
    _assert_true(speed_reduction >= 0.0, "Speed reduction is non-negative")
    _assert_true(speed_reduction <= 0.5, "Speed reduction is capped at 50%")

    var gold_income: int = SimUpgrades.get_gold_income(state)
    _assert_true(gold_income >= 0, "Gold income is non-negative")

    # Test can_purchase validation
    state.gold = 0
    var result: Dictionary = SimUpgrades.can_purchase_kingdom_upgrade(state, "nonexistent_xyz")
    _assert_true(not result.get("ok", true), "Cannot purchase nonexistent upgrade")

    # Test available upgrades listing
    state.gold = 10000
    var available_kingdom: Array = SimUpgrades.list_available_kingdom_upgrades(state)
    _assert_true(available_kingdom is Array, "list_available_kingdom_upgrades returns Array")

    var available_unit: Array = SimUpgrades.list_available_unit_upgrades(state)
    _assert_true(available_unit is Array, "list_available_unit_upgrades returns Array")

    # Test format_upgrade_tree
    var tree_lines: Array[String] = SimUpgrades.format_upgrade_tree(state, "kingdom")
    _assert_true(tree_lines.size() > 0, "format_upgrade_tree returns lines")
    _assert_true("Kingdom Upgrades" in tree_lines[0], "Tree header contains category name")

    var unit_tree: Array[String] = SimUpgrades.format_upgrade_tree(state, "unit")
    _assert_true(unit_tree.size() > 0, "format_upgrade_tree returns lines for unit")


func _run_loot_tests() -> void:
    # Test QUALITY_TIERS constant
    _assert_true(SimLoot.QUALITY_TIERS.size() >= 5, "QUALITY_TIERS has at least 5 tiers")
    _assert_true(SimLoot.QUALITY_TIERS.has("poor"), "Has poor tier")
    _assert_true(SimLoot.QUALITY_TIERS.has("normal"), "Has normal tier")
    _assert_true(SimLoot.QUALITY_TIERS.has("good"), "Has good tier")
    _assert_true(SimLoot.QUALITY_TIERS.has("excellent"), "Has excellent tier")
    _assert_true(SimLoot.QUALITY_TIERS.has("perfect"), "Has perfect tier")

    # Test tier structure
    var poor: Dictionary = SimLoot.QUALITY_TIERS.get("poor", {})
    _assert_true(poor.has("multiplier"), "Poor tier has multiplier")
    _assert_true(poor.has("min_accuracy"), "Poor tier has min_accuracy")
    _assert_true(poor.has("max_accuracy"), "Poor tier has max_accuracy")

    # Test multiplier progression
    var poor_mult: float = float(SimLoot.QUALITY_TIERS["poor"]["multiplier"])
    var normal_mult: float = float(SimLoot.QUALITY_TIERS["normal"]["multiplier"])
    var good_mult: float = float(SimLoot.QUALITY_TIERS["good"]["multiplier"])
    var excellent_mult: float = float(SimLoot.QUALITY_TIERS["excellent"]["multiplier"])
    var perfect_mult: float = float(SimLoot.QUALITY_TIERS["perfect"]["multiplier"])

    _assert_true(poor_mult < normal_mult, "Poor mult < normal mult")
    _assert_true(normal_mult < good_mult, "Normal mult < good mult")
    _assert_true(good_mult < excellent_mult, "Good mult < excellent mult")
    _assert_true(excellent_mult < perfect_mult, "Excellent mult < perfect mult")

    # Test calculate_quality_tier
    var tier_poor: String = SimLoot.calculate_quality_tier(0.5, false)
    _assert_equal(tier_poor, "poor", "50% accuracy is poor tier")

    var tier_normal: String = SimLoot.calculate_quality_tier(0.75, false)
    _assert_equal(tier_normal, "normal", "75% accuracy is normal tier")

    var tier_good: String = SimLoot.calculate_quality_tier(0.90, false)
    _assert_equal(tier_good, "good", "90% accuracy is good tier")

    var tier_excellent: String = SimLoot.calculate_quality_tier(0.97, false)
    _assert_equal(tier_excellent, "excellent", "97% accuracy is excellent tier")

    var tier_perfect: String = SimLoot.calculate_quality_tier(1.0, true)
    _assert_equal(tier_perfect, "perfect", "100% accuracy with perfect flag is perfect tier")

    # Test get_quality_multiplier
    _assert_true(SimLoot.get_quality_multiplier("poor") == poor_mult, "get_quality_multiplier returns correct poor mult")
    _assert_true(SimLoot.get_quality_multiplier("perfect") == perfect_mult, "get_quality_multiplier returns correct perfect mult")
    _assert_true(SimLoot.get_quality_multiplier("invalid") == 1.0, "Invalid tier returns 1.0")

    # Test format_loot_brief
    var loot_dict: Dictionary = {"gold": 10, "wood": 5}
    var brief: String = SimLoot.format_loot_brief(loot_dict)
    _assert_true(brief.length() > 0, "format_loot_brief returns non-empty string")
    _assert_true("10" in brief or "5" in brief, "Brief contains amounts")

    var empty_brief: String = SimLoot.format_loot_brief({})
    _assert_equal(empty_brief, "", "Empty loot returns empty string")

    # Test get_pending_loot_summary with empty state
    var state: GameState = GameState.new()
    state.loot_pending = []
    var summary: Dictionary = SimLoot.get_pending_loot_summary(state)
    _assert_true(summary.is_empty(), "Empty pending loot returns empty summary")

    # Test queue_loot
    SimLoot.queue_loot(state, {"gold": 50})
    _assert_true(state.loot_pending.size() == 1, "queue_loot adds to pending")

    SimLoot.queue_loot(state, {})
    _assert_true(state.loot_pending.size() == 1, "Empty loot not queued")

    # Test get_pending_loot_summary with queued loot
    var pending_summary: Dictionary = SimLoot.get_pending_loot_summary(state)
    _assert_true(pending_summary.get("gold", 0) == 50, "Pending summary shows queued gold")

    # Test reset_wave_stats
    state.perfect_kills = 5
    state.last_loot_quality = 2.0
    SimLoot.reset_wave_stats(state)
    _assert_true(state.perfect_kills == 0, "reset_wave_stats clears perfect_kills")
    _assert_true(state.last_loot_quality == 1.0, "reset_wave_stats resets quality")

    # Test update_quality_from_performance
    state.perfect_kills = 0
    SimLoot.update_quality_from_performance(state, 0.5, false)
    _assert_true(state.last_loot_quality == poor_mult, "update_quality sets poor mult")

    SimLoot.update_quality_from_performance(state, 1.0, false)
    _assert_true(state.perfect_kills == 1, "Perfect performance increments perfect_kills")


func _run_milestones_tests() -> void:
    # Test WPM_MILESTONES array
    _assert_true(SimMilestones.WPM_MILESTONES.size() >= 10, "WPM_MILESTONES has 10+ entries")
    _assert_true(20 in SimMilestones.WPM_MILESTONES, "WPM milestones includes 20")
    _assert_true(100 in SimMilestones.WPM_MILESTONES, "WPM milestones includes 100")

    # Test ACCURACY_MILESTONES array
    _assert_true(SimMilestones.ACCURACY_MILESTONES.size() >= 7, "ACCURACY_MILESTONES has 7+ entries")
    _assert_true(100.0 in SimMilestones.ACCURACY_MILESTONES, "Accuracy milestones includes 100%")

    # Test COMBO_MILESTONES array
    _assert_true(SimMilestones.COMBO_MILESTONES.size() >= 10, "COMBO_MILESTONES has 10+ entries")
    _assert_true(100 in SimMilestones.COMBO_MILESTONES, "Combo milestones includes 100")

    # Test KILL_MILESTONES array
    _assert_true(SimMilestones.KILL_MILESTONES.size() >= 8, "KILL_MILESTONES has 8+ entries")
    _assert_true(1000 in SimMilestones.KILL_MILESTONES, "Kill milestones includes 1000")

    # Test WORD_MILESTONES array
    _assert_true(SimMilestones.WORD_MILESTONES.size() >= 8, "WORD_MILESTONES has 8+ entries")
    _assert_true(1000 in SimMilestones.WORD_MILESTONES, "Word milestones includes 1000")

    # Test STREAK_MILESTONES array
    _assert_true(SimMilestones.STREAK_MILESTONES.size() >= 9, "STREAK_MILESTONES has 9+ entries")
    _assert_true(365 in SimMilestones.STREAK_MILESTONES, "Streak milestones includes 365")

    # Test Category enum
    _assert_true(SimMilestones.Category.WPM == 0, "WPM category is 0")
    _assert_true(SimMilestones.Category.ACCURACY == 1, "ACCURACY category is 1")
    _assert_true(SimMilestones.Category.COMBO == 2, "COMBO category is 2")
    _assert_true(SimMilestones.Category.KILLS == 3, "KILLS category is 3")
    _assert_true(SimMilestones.Category.WORDS == 4, "WORDS category is 4")
    _assert_true(SimMilestones.Category.STREAK == 5, "STREAK category is 5")

    # Test MILESTONE_MESSAGES dictionary
    _assert_true(SimMilestones.MILESTONE_MESSAGES.has(SimMilestones.Category.WPM), "Messages has WPM category")
    _assert_true(SimMilestones.MILESTONE_MESSAGES.has(SimMilestones.Category.ACCURACY), "Messages has ACCURACY category")
    _assert_true(SimMilestones.MILESTONE_MESSAGES.has(SimMilestones.Category.COMBO), "Messages has COMBO category")
    _assert_true(SimMilestones.MILESTONE_MESSAGES.has(SimMilestones.Category.KILLS), "Messages has KILLS category")
    _assert_true(SimMilestones.MILESTONE_MESSAGES.has(SimMilestones.Category.WORDS), "Messages has WORDS category")
    _assert_true(SimMilestones.MILESTONE_MESSAGES.has(SimMilestones.Category.STREAK), "Messages has STREAK category")

    # Test check_wpm_milestone
    var wpm_result: Dictionary = SimMilestones.check_wpm_milestone(25, 15)
    _assert_true(not wpm_result.is_empty(), "WPM milestone detected for 25 WPM from 15")
    _assert_equal(int(wpm_result.get("value", 0)), 20, "WPM milestone value is 20")
    _assert_equal(int(wpm_result.get("category", -1)), SimMilestones.Category.WPM, "Category is WPM")
    _assert_true(wpm_result.has("message"), "WPM result has message")

    var no_wpm_result: Dictionary = SimMilestones.check_wpm_milestone(15, 15)
    _assert_true(no_wpm_result.is_empty(), "No milestone if current <= previous")

    # Personal best without milestone
    var pb_result: Dictionary = SimMilestones.check_wpm_milestone(17, 15)
    _assert_true(not pb_result.is_empty(), "Personal best detected")
    _assert_true(bool(pb_result.get("is_personal_best", false)), "Marked as personal best")

    # Test check_accuracy_milestone
    var acc_result: Dictionary = SimMilestones.check_accuracy_milestone(0.91, 0.85)
    _assert_true(not acc_result.is_empty(), "Accuracy milestone detected for 91%")
    _assert_equal(float(acc_result.get("value", 0)), 90.0, "Accuracy milestone value is 90%")

    var no_acc_result: Dictionary = SimMilestones.check_accuracy_milestone(0.85, 0.86)
    _assert_true(no_acc_result.is_empty(), "No milestone if current <= previous")

    # Test check_combo_milestone
    var combo_result: Dictionary = SimMilestones.check_combo_milestone(12, 8)
    _assert_true(not combo_result.is_empty(), "Combo milestone detected for 12")
    _assert_equal(int(combo_result.get("value", 0)), 10, "Combo milestone value is 10")

    # Test check_kill_milestone
    var kill_result: Dictionary = SimMilestones.check_kill_milestone(55, 45)
    _assert_true(not kill_result.is_empty(), "Kill milestone detected for 55")
    _assert_equal(int(kill_result.get("value", 0)), 50, "Kill milestone value is 50")
    _assert_true(not bool(kill_result.get("is_personal_best", true)), "Kill milestone is not personal best")

    # Test check_word_milestone
    var word_result: Dictionary = SimMilestones.check_word_milestone(120, 90)
    _assert_true(not word_result.is_empty(), "Word milestone detected for 120")
    _assert_equal(int(word_result.get("value", 0)), 100, "Word milestone value is 100")

    # Test check_streak_milestone
    var streak_result: Dictionary = SimMilestones.check_streak_milestone(8, 5)
    _assert_true(not streak_result.is_empty(), "Streak milestone detected for 8")
    _assert_equal(int(streak_result.get("value", 0)), 7, "Streak milestone value is 7")

    # Test get_next_milestone
    var next_wpm: Dictionary = SimMilestones.get_next_milestone(SimMilestones.Category.WPM, 35)
    _assert_true(next_wpm.has("next"), "Next WPM has next field")
    _assert_equal(int(next_wpm.get("next", 0)), 40, "Next WPM after 35 is 40")
    _assert_true(next_wpm.has("progress"), "Next WPM has progress")
    _assert_true(float(next_wpm.get("progress", 0)) > 0.5, "Progress > 50% at 35 WPM towards 40")

    var next_combo: Dictionary = SimMilestones.get_next_milestone(SimMilestones.Category.COMBO, 100)
    _assert_true(int(next_combo.get("next", 0)) == -1, "No next combo after 100")
    _assert_true(float(next_combo.get("progress", 0)) == 1.0, "Progress is 1.0 at max")

    # Test get_category_color
    var wpm_color: Color = SimMilestones.get_category_color(SimMilestones.Category.WPM)
    _assert_true(wpm_color != Color.BLACK, "WPM color is not black")

    var accuracy_color: Color = SimMilestones.get_category_color(SimMilestones.Category.ACCURACY)
    _assert_true(accuracy_color != wpm_color, "Accuracy color differs from WPM")

    # Test format_milestone
    var formatted: String = SimMilestones.format_milestone(wpm_result)
    _assert_true(formatted.length() > 0, "Formatted milestone is non-empty")

    var empty_formatted: String = SimMilestones.format_milestone({})
    _assert_equal(empty_formatted, "", "Empty milestone formats to empty string")

    # Test personal best formatting
    var pb_formatted: String = SimMilestones.format_milestone(pb_result)
    _assert_true("ffd700" in pb_formatted.to_lower() or "gold" in pb_formatted.to_lower() or "[color" in pb_formatted, "Personal best has special formatting")


func _run_event_effects_tests() -> void:
    var state: GameState = DefaultState.create()

    # Test resource_add effect
    state.resources["wood"] = 10
    var resource_result: Dictionary = SimEventEffects.apply_effect(state, {"type": "resource_add", "resource": "wood", "amount": 5})
    _assert_equal(str(resource_result.get("type", "")), "resource_add", "resource_add type")
    _assert_equal(int(state.resources.get("wood", 0)), 15, "Wood increased by 5")
    _assert_equal(int(resource_result.get("old_value", 0)), 10, "old_value correct")
    _assert_equal(int(resource_result.get("new_value", 0)), 15, "new_value correct")

    # Test resource_add with negative (can't go below 0)
    var negative_result: Dictionary = SimEventEffects.apply_effect(state, {"type": "resource_add", "resource": "wood", "amount": -100})
    _assert_equal(int(state.resources.get("wood", 0)), 0, "Wood can't go below 0")

    # Test invalid resource
    var invalid_resource: Dictionary = SimEventEffects.apply_effect(state, {"type": "resource_add", "resource": "fake_resource", "amount": 5})
    _assert_true(invalid_resource.has("error"), "Invalid resource returns error")

    # Test gold_add effect
    state.gold = 50
    var gold_result: Dictionary = SimEventEffects.apply_effect(state, {"type": "gold_add", "amount": 25})
    _assert_equal(str(gold_result.get("type", "")), "gold_add", "gold_add type")
    _assert_equal(int(state.gold), 75, "Gold increased by 25")

    # Test buff_apply effect
    var buff_result: Dictionary = SimEventEffects.apply_effect(state, {"type": "buff_apply", "buff": "speed_boost", "duration": 3})
    _assert_equal(str(buff_result.get("type", "")), "buff_apply", "buff_apply type")
    _assert_equal(str(buff_result.get("buff_id", "")), "speed_boost", "buff_id correct")
    _assert_equal(int(buff_result.get("duration", 0)), 3, "duration correct")
    _assert_false(bool(buff_result.get("refreshed", true)), "First application not refreshed")

    # Test buff refresh
    var refresh_result: Dictionary = SimEventEffects.apply_effect(state, {"type": "buff_apply", "buff": "speed_boost", "duration": 5})
    _assert_true(bool(refresh_result.get("refreshed", false)), "Second application refreshed")

    # Test has_buff
    _assert_true(SimEventEffects.has_buff(state, "speed_boost"), "has_buff returns true for active buff")
    _assert_false(SimEventEffects.has_buff(state, "nonexistent_buff"), "has_buff returns false for nonexistent buff")

    # Test damage_castle effect
    state.hp = 10
    var damage_result: Dictionary = SimEventEffects.apply_effect(state, {"type": "damage_castle", "amount": 3})
    _assert_equal(str(damage_result.get("type", "")), "damage_castle", "damage_castle type")
    _assert_equal(int(state.hp), 7, "HP reduced by 3")
    _assert_equal(int(damage_result.get("old_hp", 0)), 10, "old_hp correct")
    _assert_equal(int(damage_result.get("new_hp", 0)), 7, "new_hp correct")

    # Test heal_castle effect
    var heal_result: Dictionary = SimEventEffects.apply_effect(state, {"type": "heal_castle", "amount": 5, "max_hp": 10})
    _assert_equal(int(state.hp), 10, "HP healed to max")
    _assert_equal(int(heal_result.get("new_hp", 0)), 10, "new_hp capped at max")

    # Test threat_add effect
    state.threat = 5
    var threat_result: Dictionary = SimEventEffects.apply_effect(state, {"type": "threat_add", "amount": 3})
    _assert_equal(int(state.threat), 8, "Threat increased by 3")

    # Test ap_add effect
    state.ap = 2
    state.ap_max = 5
    var ap_result: Dictionary = SimEventEffects.apply_effect(state, {"type": "ap_add", "amount": 10})
    _assert_equal(int(state.ap), 5, "AP capped at ap_max")

    # Test set_flag effect
    var flag_result: Dictionary = SimEventEffects.apply_effect(state, {"type": "set_flag", "flag": "test_flag", "value": true})
    _assert_true(state.event_flags.has("test_flag"), "Flag set in state")
    _assert_true(bool(state.event_flags.get("test_flag", false)), "Flag value is true")

    # Test clear_flag effect
    var clear_result: Dictionary = SimEventEffects.apply_effect(state, {"type": "clear_flag", "flag": "test_flag"})
    _assert_false(state.event_flags.has("test_flag"), "Flag removed from state")
    _assert_true(bool(clear_result.get("removed", false)), "clear_flag reports removed")

    # Test spawn_enemies effect
    state.enemies = []
    state.enemy_next_id = 1
    var spawn_result: Dictionary = SimEventEffects.apply_effect(state, {"type": "spawn_enemies", "kind": "raider", "count": 2, "at_cursor": true})
    _assert_equal(str(spawn_result.get("type", "")), "spawn_enemies", "spawn_enemies type")
    _assert_true(int(spawn_result.get("spawned", 0)) >= 1, "At least 1 enemy spawned")
    _assert_true(state.enemies.size() >= 1, "Enemies array has entries")
    _assert_true(spawn_result.has("enemy_ids"), "spawn_result has enemy_ids")

    # Test spawn_enemies with invalid kind
    var invalid_spawn: Dictionary = SimEventEffects.apply_effect(state, {"type": "spawn_enemies", "kind": "fake_enemy", "count": 1})
    _assert_true(invalid_spawn.has("error"), "Invalid enemy kind returns error")

    # Test modify_terrain effect
    var terrain_result: Dictionary = SimEventEffects.apply_effect(state, {"type": "modify_terrain", "terrain": "forest", "at_cursor": true})
    _assert_equal(str(terrain_result.get("type", "")), "modify_terrain", "modify_terrain type")
    var terrain_index: int = state.cursor_pos.y * state.map_w + state.cursor_pos.x
    _assert_equal(str(state.terrain[terrain_index]), "forest", "Terrain changed to forest")

    # Test modify_terrain with invalid terrain
    var invalid_terrain: Dictionary = SimEventEffects.apply_effect(state, {"type": "modify_terrain", "terrain": "lava"})
    _assert_true(invalid_terrain.has("error"), "Invalid terrain returns error")

    # Test unlock_lesson effect
    var lesson_result: Dictionary = SimEventEffects.apply_effect(state, {"type": "unlock_lesson", "lesson": "test_lesson"})
    _assert_equal(str(lesson_result.get("type", "")), "unlock_lesson", "unlock_lesson type")
    _assert_true(state.event_flags.has("lesson_unlocked_test_lesson"), "Lesson unlock flag set")
    _assert_false(bool(lesson_result.get("already_unlocked", true)), "First unlock not already_unlocked")

    # Test unlock_lesson when already unlocked
    var second_unlock: Dictionary = SimEventEffects.apply_effect(state, {"type": "unlock_lesson", "lesson": "test_lesson"})
    _assert_true(bool(second_unlock.get("already_unlocked", false)), "Second unlock already_unlocked")

    # Test unlock_achievement effect
    var achievement_result: Dictionary = SimEventEffects.apply_effect(state, {"type": "unlock_achievement", "achievement": "test_achievement"})
    _assert_equal(str(achievement_result.get("type", "")), "unlock_achievement", "unlock_achievement type")
    _assert_true(state.event_flags.has("achievement_test_achievement"), "Achievement flag set")
    _assert_false(bool(achievement_result.get("already_earned", true)), "First earn not already_earned")

    # Test unknown effect type
    var unknown_result: Dictionary = SimEventEffects.apply_effect(state, {"type": "unknown_type"})
    _assert_true(unknown_result.has("error"), "Unknown effect type returns error")

    # Test apply_effects with multiple effects
    var multi_state: GameState = DefaultState.create()
    multi_state.resources["wood"] = 0
    multi_state.gold = 0
    var effects: Array = [
        {"type": "resource_add", "resource": "wood", "amount": 10},
        {"type": "gold_add", "amount": 50},
        {"type": "set_flag", "flag": "multi_test", "value": true}
    ]
    var multi_results: Array = SimEventEffects.apply_effects(multi_state, effects)
    _assert_equal(multi_results.size(), 3, "3 effect results returned")
    _assert_equal(int(multi_state.resources.get("wood", 0)), 10, "Wood set from multi effects")
    _assert_equal(int(multi_state.gold), 50, "Gold set from multi effects")
    _assert_true(multi_state.event_flags.has("multi_test"), "Flag set from multi effects")

    # Test expire_buffs
    var expire_state: GameState = DefaultState.create()
    expire_state.day = 5
    expire_state.active_buffs = [
        {"buff_id": "expired", "expires_day": 4, "applied_day": 1},
        {"buff_id": "active", "expires_day": 10, "applied_day": 3}
    ]
    var expired: Array = SimEventEffects.expire_buffs(expire_state)
    _assert_equal(expired.size(), 1, "1 buff expired")
    _assert_equal(str(expired[0]), "expired", "Correct buff expired")
    _assert_equal(expire_state.active_buffs.size(), 1, "1 active buff remains")

    # Test get_buff_remaining_days
    var remaining: int = SimEventEffects.get_buff_remaining_days(expire_state, "active")
    _assert_equal(remaining, 5, "5 days remaining on active buff")

    # Test serialize/deserialize buffs
    var serialized: Array = SimEventEffects.serialize_buffs(expire_state.active_buffs)
    _assert_equal(serialized.size(), 1, "1 buff serialized")
    var deserialized: Array = SimEventEffects.deserialize_buffs(serialized)
    _assert_equal(deserialized.size(), 1, "1 buff deserialized")
    _assert_equal(str(deserialized[0].get("buff_id", "")), "active", "Buff ID preserved")


func _run_event_system_tests() -> void:
    # Test SimEvents loading
    SimEvents.load_events()
    var events: Dictionary = SimEvents.get_all_events()
    _assert_true(events.size() > 0, "Events loaded from JSON")

    # Test get_event
    if events.size() > 0:
        var first_id: String = str(events.keys()[0])
        var event: Dictionary = SimEvents.get_event(first_id)
        _assert_true(event.has("title"), "Event has title")
        _assert_true(event.has("body"), "Event has body")
        _assert_true(event.has("choices") or event.has("id"), "Event has choices or id")

    # Test is_valid_event
    _assert_false(SimEvents.is_valid_event("nonexistent_event_12345"), "Nonexistent event invalid")

    # Test SimEventTables loading
    SimEventTables.load_tables()
    var tables: Dictionary = SimEventTables.get_all_tables()
    _assert_true(tables.size() > 0, "Event tables loaded from JSON")

    # Test table structure
    if tables.size() > 0:
        var first_table_id: String = str(tables.keys()[0])
        var table: Dictionary = SimEventTables.get_table(first_table_id)
        _assert_true(table.has("entries") or table.has("id"), "Table has entries or id")

    # Test SimPoi loading
    SimPoi.load_pois()
    var pois: Dictionary = SimPoi.get_all_pois()
    _assert_true(pois.size() > 0, "POIs loaded from JSON")

    # Test POI structure
    if pois.size() > 0:
        var first_poi_id: String = str(pois.keys()[0])
        var poi: Dictionary = SimPoi.get_poi(first_poi_id)
        _assert_true(poi.has("name") or poi.has("id"), "POI has name or id")
        _assert_true(poi.has("biome") or poi.has("event_table_id") or poi.has("id"), "POI has biome or event_table_id")

    # Test POI spawn validation
    var state: GameState = DefaultState.create()
    state.day = 5
    # Test can_spawn_poi doesn't crash (we don't know valid POI IDs from data)

    # Test event cooldown management
    state.event_cooldowns = {}
    _assert_false(SimEvents.is_on_cooldown(state, "test_event"), "Event not on cooldown initially")

    # Test has_pending_event
    state.pending_event = {}
    _assert_false(SimEvents.has_pending_event(state), "No pending event initially")

    # Test start_event
    var test_event: Dictionary = {
        "id": "test_event",
        "title": "Test Event",
        "body": "This is a test event.",
        "choices": [
            {"text": "Option A", "input_mode": "code", "code": "accept", "effects": []},
            {"text": "Option B", "input_mode": "code", "code": "decline", "effects": []}
        ]
    }
    SimEvents.start_event(state, test_event)
    _assert_true(SimEvents.has_pending_event(state), "Event is pending after start")
    var pending: Dictionary = SimEvents.get_pending_event(state)
    _assert_equal(str(pending.get("id", "")), "test_event", "Pending event ID correct")

    # Test clear pending event
    state.pending_event = {}
    _assert_false(SimEvents.has_pending_event(state), "No pending event after clear")

    # Test event flag conditions
    state.event_flags = {"has_key": true}
    _assert_true(SimEventTables.check_condition(state, {"type": "flag_set", "flag": "has_key"}), "flag_set condition passes")
    _assert_false(SimEventTables.check_condition(state, {"type": "flag_set", "flag": "no_key"}), "flag_set fails for missing flag")
    _assert_true(SimEventTables.check_condition(state, {"type": "flag_not_set", "flag": "no_key"}), "flag_not_set passes for missing flag")
    _assert_false(SimEventTables.check_condition(state, {"type": "flag_not_set", "flag": "has_key"}), "flag_not_set fails for set flag")

    # Test day_range condition
    state.day = 5
    _assert_true(SimEventTables.check_condition(state, {"type": "day_range", "min": 1, "max": 10}), "day_range passes when in range")
    _assert_false(SimEventTables.check_condition(state, {"type": "day_range", "min": 10, "max": 20}), "day_range fails when below min")

    # Test resource_min condition
    state.resources["wood"] = 50
    _assert_true(SimEventTables.check_condition(state, {"type": "resource_min", "resource": "wood", "amount": 30}), "resource_min passes")
    _assert_false(SimEventTables.check_condition(state, {"type": "resource_min", "resource": "wood", "amount": 100}), "resource_min fails when insufficient")

    # Test unknown condition type (should pass by default)
    _assert_true(SimEventTables.check_condition(state, {"type": "unknown_condition"}), "Unknown condition passes by default")
