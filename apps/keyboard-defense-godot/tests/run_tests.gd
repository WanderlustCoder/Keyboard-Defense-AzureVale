extends SceneTree

const DefaultState = preload("res://sim/default_state.gd")
const CommandParser = preload("res://sim/parse_command.gd")
const IntentApplier = preload("res://sim/apply_intent.gd")
const GameState = preload("res://sim/types.gd")
const SimMap = preload("res://sim/map.gd")
const SimBuildings = preload("res://sim/buildings.gd")
const SimSave = preload("res://sim/save.gd")
const SimRng = preload("res://sim/rng.gd")
const SimEnemies = preload("res://sim/enemies.gd")
const SimWords = preload("res://sim/words.gd")
const SimTypingFeedback = preload("res://sim/typing_feedback.gd")
const CommandKeywords = preload("res://sim/command_keywords.gd")
const SimTypingStats = preload("res://sim/typing_stats.gd")
const SimTypingTrends = preload("res://sim/typing_trends.gd")
const PracticeGoals = preload("res://sim/practice_goals.gd")
const GoalTheme = preload("res://game/goal_theme.gd")

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
    _run_command_keywords_tests()
    _run_practice_goal_tests()
    _run_goal_theme_tests()
    _run_inputmap_tests()
    _run_typing_feedback_tests()
    _run_typing_stats_tests()
    _run_typing_trends_tests()

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
    _assert_parse_ok("restart", "restart")
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
    _assert_parse_ok("settings", "ui_settings_toggle")
    _assert_parse_ok("bind cycle_goal", "ui_bind_cycle_goal")
    _assert_parse_ok("bind cycle_goal reset", "ui_bind_cycle_goal_reset")

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
    _assert_equal(int(gather_result.state.resources.get("wood", 0)), 3, "gather adds resource")

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
    _assert_equal(explore_result.state.threat, explore_state.threat + 1, "explore increases threat")
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
    _assert_equal(blocked_result.state.night_wave_total, 4, "blocked path reduces night")

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

    var demolish_upgrade_state: GameState = _make_flat_state("test-demolish-upgrade")
    demolish_upgrade_state.phase = "day"
    demolish_upgrade_state.ap = 2
    var demolish_upgrade_pos: Vector2i = demolish_upgrade_state.base_pos + Vector2i(1, 0)
    var demolish_upgrade_index: int = SimMap.idx(demolish_upgrade_pos.x, demolish_upgrade_pos.y, demolish_upgrade_state.map_w)
    demolish_upgrade_state.structures[demolish_upgrade_index] = "tower"
    demolish_upgrade_state.structure_levels[demolish_upgrade_index] = 3
    demolish_upgrade_state.buildings["tower"] = 1
    var demolish_upgrade_result: Dictionary = IntentApplier.apply(demolish_upgrade_state, {"kind": "demolish", "x": demolish_upgrade_pos.x, "y": demolish_upgrade_pos.y})
    _assert_equal(int(demolish_upgrade_result.state.resources.get("wood", 0)), 10, "demolish refund includes tower upgrades (wood)")
    _assert_equal(int(demolish_upgrade_result.state.resources.get("stone", 0)), 17, "demolish refund includes tower upgrades (stone)")
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
    _assert_equal(int(production.get("food", 0)), 4, "farm adjacency bonus applied")

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
    _assert_equal(int(preview.get("production", {}).get("food", 0)), 3, "preview farm adjacency bonus")

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
    _assert_equal(int(upgrade_result.state.resources.get("wood", 0)), 15, "upgrade costs wood")
    _assert_equal(int(upgrade_result.state.resources.get("stone", 0)), 10, "upgrade costs stone")

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

    var word_a: String = SimWords.word_for_enemy(seed_text, 2, "raider", 1, {})
    var word_b: String = SimWords.word_for_enemy(seed_text, 2, "raider", 1, {})
    _assert_equal(word_a, word_b, "deterministic enemy word assignment")
    var used: Dictionary = {word_a: true}
    var word_c: String = SimWords.word_for_enemy(seed_text, 2, "raider", 2, used)
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

func _run_command_keywords_tests() -> void:
    var keywords: Array[String] = CommandKeywords.keywords()
    _assert_true(keywords.has("help"), "command keywords include help")
    _assert_true(keywords.has("status"), "command keywords include status")
    _assert_true(keywords.has("build"), "command keywords include build")
    _assert_true(keywords.has("defend"), "command keywords include defend")
    _assert_true(keywords.has("wait"), "command keywords include wait")
    _assert_true(keywords.has("report"), "command keywords include report")
    _assert_true(keywords.has("history"), "command keywords include history")
    _assert_true(keywords.has("trend"), "command keywords include trend")
    _assert_true(keywords.has("goal"), "command keywords include goal")
    _assert_true(keywords.has("settings"), "command keywords include settings")
    _assert_true(keywords.has("bind"), "command keywords include bind")

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
    var has_f2: bool = false
    var details: Array[String] = []
    for event in events:
        if event is InputEventKey and event.keycode == KEY_F2:
            has_f2 = true
            break
        if event is InputEventKey:
            details.append("key=%d phys=%d" % [event.keycode, event.physical_keycode])
    if has_f2:
        _assert_true(true, "cycle_goal includes F2 binding")
    else:
        var detail_text: String = ", ".join(details)
        _assert_true(false, "cycle_goal includes F2 binding (events: %s, KEY_F2=%d)" % [detail_text, KEY_F2])

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

func _assert_parse_ok(command: String, expected_kind: String) -> void:
    var result: Dictionary = CommandParser.parse(command)
    _assert_true(result.get("ok", false), "parse ok: %s" % command)
    if result.get("ok", false):
        _assert_equal(str(result.intent.get("kind", "")), expected_kind, "intent kind: %s" % command)

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
