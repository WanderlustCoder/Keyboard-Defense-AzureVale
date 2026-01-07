class_name IntentApplier
extends RefCounted

const GameState = preload("res://sim/types.gd")
const DefaultState = preload("res://sim/default_state.gd")
const SimIntents = preload("res://sim/intents.gd")
const SimTick = preload("res://sim/tick.gd")
const SimBuildings = preload("res://sim/buildings.gd")
const SimMap = preload("res://sim/map.gd")
const SimRng = preload("res://sim/rng.gd")
const SimEnemies = preload("res://sim/enemies.gd")
const SimTypingFeedback = preload("res://sim/typing_feedback.gd")
const SimLessons = preload("res://sim/lessons.gd")
const SimWords = preload("res://sim/words.gd")
const SimBalance = preload("res://sim/balance.gd")
const SimPoi = preload("res://sim/poi.gd")
const SimEvents = preload("res://sim/events.gd")
const SimEventEffects = preload("res://sim/event_effects.gd")
const SimUpgrades = preload("res://sim/upgrades.gd")

static func apply(state: GameState, intent: Dictionary) -> Dictionary:
    var events: Array[String] = []
    var new_state: GameState = _copy_state(state)
    var request: Dictionary = {}
    var kind: String = str(intent.get("kind", ""))

    match kind:
        "help":
            events.append_array(SimIntents.help_lines())
        "status":
            events.append(_format_status(new_state))
        "seed":
            var seed_value: String = str(intent.get("seed", ""))
            SimRng.seed_state(new_state, seed_value)
            events.append("Seed set to '%s'." % seed_value)
        "gather":
            _apply_gather(new_state, intent, events)
        "build":
            _apply_build(new_state, intent, events)
        "explore":
            _apply_explore(new_state, events)
        "cursor":
            _apply_cursor(new_state, intent, events)
        "cursor_move":
            _apply_cursor_move(new_state, intent, events)
        "inspect":
            _apply_inspect(new_state, intent, events)
        "map":
            _apply_map(new_state, events)
        "lesson_show":
            _apply_lesson_show(new_state, events)
        "lesson_set":
            _apply_lesson_set(new_state, intent, events)
        "lesson_next":
            _apply_lesson_cycle(new_state, 1, events)
        "lesson_prev":
            _apply_lesson_cycle(new_state, -1, events)
        "lesson_sample":
            _apply_lesson_sample(new_state, intent, events)
        "demolish":
            _apply_demolish(new_state, intent, events)
        "upgrade":
            _apply_upgrade(new_state, intent, events)
        "end":
            if _apply_end(new_state, events):
                request = {"kind": "autosave", "reason": "night"}
        "defend_input":
            if _apply_defend_input(new_state, intent, events):
                request = {"kind": "autosave", "reason": "dawn"}
        "wait":
            if _apply_wait(new_state, events):
                request = {"kind": "autosave", "reason": "dawn"}
        "restart":
            return _apply_restart(state, events)
        "new":
            return _apply_new(state, events)
        "save":
            request = {"kind": "save"}
        "load":
            request = {"kind": "load"}
        "ui_preview":
            var building: String = str(intent.get("building", ""))
            if building.is_empty():
                events.append("Build preview cleared.")
            else:
                events.append("Build preview set to: %s (UI-only)." % building)
        "ui_overlay":
            var overlay_name: String = str(intent.get("name", ""))
            var enabled: bool = bool(intent.get("enabled", false))
            var state_text: String = "ON" if enabled else "OFF"
            events.append("%s overlay: %s (UI-only)." % [overlay_name.capitalize(), state_text])
        "enemies":
            _apply_enemies(new_state, events)
        "interact_poi":
            _apply_interact_poi(new_state, events)
        "event_choice":
            _apply_event_choice(new_state, intent, events)
        "event_skip":
            _apply_event_skip(new_state, events)
        "buy_upgrade":
            _apply_buy_upgrade(new_state, intent, events)
        "ui_upgrades":
            _apply_ui_upgrades(new_state, intent, events)
        _:
            events.append("Unknown intent: %s" % kind)

    var result := {"state": new_state, "events": events}
    if not request.is_empty():
        result["request"] = request
    return result

static func _apply_gather(state: GameState, intent: Dictionary, events: Array[String]) -> void:
    if not _require_day(state, events):
        return
    if not _consume_ap(state, events):
        return
    var resource: String = str(intent.get("resource", ""))
    var amount: int = int(intent.get("amount", 0))
    if not state.resources.has(resource) or amount <= 0:
        events.append("Invalid gather request.")
        return
    state.resources[resource] = int(state.resources.get(resource, 0)) + amount
    events.append("Gathered %d %s." % [amount, resource])
    events.append(_format_status(state))

static func _apply_build(state: GameState, intent: Dictionary, events: Array[String]) -> void:
    if not _require_day(state, events):
        return
    var building_type: String = str(intent.get("building", ""))
    if not SimBuildings.is_valid(building_type):
        events.append("Unknown build type: %s" % building_type)
        return
    var pos: Vector2i = _intent_position(state, intent)
    if not SimMap.in_bounds(pos.x, pos.y, state.map_w, state.map_h):
        events.append("Build location out of bounds.")
        return
    var index: int = SimMap.idx(pos.x, pos.y, state.map_w)
    if not state.discovered.has(index):
        events.append("That tile is not discovered yet.")
        return
    if pos == state.base_pos:
        events.append("Cannot build on the base tile.")
        return
    if state.structures.has(index):
        events.append("That tile is already occupied.")
        return
    if SimMap.get_terrain(state, pos) == SimMap.TERRAIN_WATER:
        events.append("Cannot build on water.")
        return
    var cost: Dictionary = SimBuildings.cost_for(building_type)
    if not _has_resources(state, cost):
        events.append("Not enough resources to build %s." % building_type)
        return
    if not _consume_ap(state, events):
        return
    _apply_cost(state, cost)
    state.structures[index] = building_type
    state.structure_levels[index] = 1
    state.buildings[building_type] = int(state.buildings.get(building_type, 0)) + 1
    events.append("Built %s at (%d,%d)." % [building_type, pos.x, pos.y])
    events.append(_format_status(state))

static func _apply_explore(state: GameState, events: Array[String]) -> void:
    if not _require_day(state, events):
        return
    if not _consume_ap(state, events):
        return
    var tile_index: int = _pick_explore_tile(state)
    if tile_index < 0:
        events.append("No new tiles to discover.")
        return
    state.discovered[tile_index] = true
    var pos: Vector2i = SimMap.pos_from_index(tile_index, state.map_w)
    SimMap.ensure_tile_generated(state, pos)
    var terrain: String = SimMap.get_terrain(state, pos)
    var reward: Dictionary = _explore_reward(state, terrain)
    var reward_text: String = str(reward.get("resource", "food"))
    var reward_amount: int = int(reward.get("amount", 0))
    if reward_amount > 0:
        state.resources[reward_text] = int(state.resources.get(reward_text, 0)) + reward_amount
    state.threat += 1
    events.append("Discovered tile (%d,%d): %s." % [pos.x, pos.y, terrain])
    if reward_amount > 0:
        events.append("Found +%d %s." % [reward_amount, reward_text])
    else:
        events.append("Found nothing of value.")
    events.append("Threat increased to %d." % state.threat)

    # Try to spawn and discover a POI at this location
    var biome: String = _terrain_to_biome(terrain)
    var poi_id: String = SimPoi.try_spawn_random_poi(state, biome, pos)
    if poi_id != "":
        SimPoi.discover_poi(state, poi_id)
        var poi_data: Dictionary = SimPoi.get_poi(poi_id)
        var poi_name: String = str(poi_data.get("name", "something"))
        events.append("Found: %s! Use 'interact' to investigate." % poi_name)

    events.append(_format_status(state))

static func _terrain_to_biome(terrain: String) -> String:
    match terrain:
        SimMap.TERRAIN_FOREST:
            return "Evergrove"
        SimMap.TERRAIN_MOUNTAIN:
            return "Stonepass"
        SimMap.TERRAIN_WATER:
            return "Mistfen"
        SimMap.TERRAIN_PLAINS:
            return "Sunfields"
        _:
            return "Evergrove"

static func _apply_end(state: GameState, events: Array[String]) -> bool:
    if not _require_day(state, events):
        return false
    var result: Dictionary = SimTick.advance_day(state)
    var defense: int = SimBuildings.total_defense(state)
    state.phase = "night"
    state.ap = 0
    state.last_path_open = SimMap.path_open_to_base(state)
    state.night_wave_total = SimTick.compute_night_wave_total(state, defense)
    if not state.last_path_open:
        state.night_wave_total = max(1, state.night_wave_total - 2)
    state.night_spawn_remaining = state.night_wave_total
    state.enemies = []
    state.night_prompt = ""
    events.append_array(result.events)
    events.append("Night falls. Enemy wave: %d." % state.night_wave_total)
    if not state.last_path_open:
        events.append("Walls slow the enemy. Night shortened.")
    return true

static func _apply_defend_input(state: GameState, intent: Dictionary, events: Array[String]) -> bool:
    if state.phase != "night":
        events.append("No threats to defend right now.")
        return false
    var text: String = str(intent.get("text", ""))
    var normalized: String = SimTypingFeedback.normalize_input(text)
    if normalized.is_empty():
        events.append("Type an enemy word to defend.")
        return false
    var target_index: int = _find_enemy_index_by_word(state, normalized)
    if target_index >= 0:
        return _advance_night_step(state, target_index, true, events, normalized)
    if state.enemies.is_empty():
        events.append("No enemies yet; wait or defend after spawn.")
        return _advance_night_step(state, -1, false, events, "")
    return _advance_night_step(state, -1, true, events, "")

static func _apply_wait(state: GameState, events: Array[String]) -> bool:
    if state.phase != "night":
        events.append("Wait is only available at night.")
        return false
    return _advance_night_step(state, -1, false, events, "")

static func _apply_restart(state: GameState, events: Array[String]) -> Dictionary:
    if state.phase != "game_over":
        events.append("Restart is only available after game over.")
        return {"state": state, "events": events}
    var seed_value: String = state.rng_seed
    var new_state: GameState = DefaultState.create(seed_value)
    new_state.lesson_id = state.lesson_id
    events.append("Restarted run with seed '%s'." % seed_value)
    return {"state": new_state, "events": events}

static func _apply_new(state: GameState, events: Array[String]) -> Dictionary:
    var seed_value: String = state.rng_seed
    var new_state: GameState = DefaultState.create(seed_value)
    new_state.lesson_id = state.lesson_id
    events.append("New run started with seed '%s'." % seed_value)
    return {"state": new_state, "events": events}

static func _advance_night_step(state: GameState, hit_enemy_index: int, apply_miss_penalty: bool, events: Array[String], hit_word: String) -> bool:
    var dist_field: PackedInt32Array = SimMap.compute_dist_to_base(state)

    if hit_enemy_index >= 0:
        _apply_player_attack_target(state, hit_enemy_index, hit_word, events)
    else:
        if apply_miss_penalty:
            state.hp -= 1
            events.append("Miss. No matching enemy word.")
        else:
            events.append("Waited.")

    _spawn_enemy_step(state, events)
    _tower_attack_step(state, dist_field, events)
    _enemy_move_step(state, dist_field, events)

    if state.hp <= 0:
        state.phase = "game_over"
        events.append("Game Over.")
        return false

    if state.night_spawn_remaining <= 0 and state.enemies.is_empty():
        state.phase = "day"
        state.ap = state.ap_max
        state.night_prompt = ""
        state.night_wave_total = 0
        state.threat = max(0, state.threat - 1)
        # Wave heal from upgrades
        var wave_heal: int = SimUpgrades.get_wave_heal(state)
        if wave_heal > 0:
            var old_hp: int = state.hp
            var max_hp: int = 10 + SimUpgrades.get_castle_health_bonus(state)
            state.hp = min(max_hp, state.hp + wave_heal)
            if state.hp > old_hp:
                events.append("Healers restore %d HP." % (state.hp - old_hp))
        events.append("Dawn breaks.")
        return true

    return false

static func _apply_player_attack_target(state: GameState, target_index: int, hit_word: String, events: Array[String]) -> void:
    if target_index < 0 or target_index >= state.enemies.size():
        events.append("No matching targets.")
        return
    var enemy: Dictionary = state.enemies[target_index]
    var enemy_id: int = int(enemy.get("id", 0))
    var enemy_kind: String = str(enemy.get("kind", "raider"))

    # Calculate damage with upgrade effects
    var base_damage: int = 2
    var typing_power: float = SimUpgrades.get_typing_power(state)
    var damage: int = int(float(base_damage) * typing_power)

    # Critical hit check
    var is_crit: bool = false
    var crit_chance: float = SimUpgrades.get_critical_chance(state)
    if crit_chance > 0.0:
        var roll: float = float(SimRng.roll_range(state, 1, 100)) / 100.0
        if roll <= crit_chance:
            is_crit = true
            damage = damage * 2

    # Apply armor reduction and pierce from upgrades
    var enemy_armor: int = int(enemy.get("armor", 0))
    var armor_reduction: int = SimUpgrades.get_enemy_armor_reduction(state)
    var armor_pierce: int = SimUpgrades.get_armor_pierce(state)
    var effective_armor: int = max(0, enemy_armor - armor_reduction - armor_pierce)
    var effective_damage: int = max(1, damage - effective_armor)

    enemy = SimEnemies.apply_damage(enemy, damage, state)
    state.enemies[target_index] = enemy
    var enemy_word: String = str(enemy.get("word", ""))
    var word_text: String = hit_word if hit_word != "" else enemy_word
    var crit_text: String = " CRITICAL!" if is_crit else ""
    events.append("Hit %s#%d word=%s dmg=%d.%s" % [enemy_kind, enemy_id, word_text, effective_damage, crit_text])
    # Berserker rage: speed boost when damaged but not killed
    if int(enemy.get("hp", 0)) > 0 and enemy_kind == "berserker":
        if not enemy.get("enraged", false):
            enemy["enraged"] = true
            enemy["speed"] = int(enemy.get("speed", 1)) + 1
            state.enemies[target_index] = enemy
            events.append("Berserker#%d enters a rage! Speed +1." % enemy_id)
    if int(enemy.get("hp", 0)) <= 0:
        var enemy_pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
        # Splitting affix: spawn swarm minions on death
        if enemy.get("affix", "") == "splitting":
            _spawn_split_enemies(state, enemy_pos, events)
        state.enemies.remove_at(target_index)
        # Award gold for kill
        var base_gold: int = SimEnemies.gold_reward(enemy_kind)
        var gold_mult: float = SimUpgrades.get_gold_multiplier(state)
        var gold_reward: int = int(float(base_gold) * gold_mult)
        state.gold += gold_reward
        events.append("Enemy %s#%d defeated. +%d gold" % [enemy_kind, enemy_id, gold_reward])

static func _spawn_enemy_step(state: GameState, events: Array[String]) -> void:
    if state.night_spawn_remaining <= 0:
        return
    var spawn_index: int = _pick_spawn_tile(state)
    state.night_spawn_remaining -= 1
    if spawn_index < 0:
        events.append("No valid spawn points.")
        return
    var pos: Vector2i = SimMap.pos_from_index(spawn_index, state.map_w)
    var kind: String = SimEnemies.choose_spawn_kind(state)
    var enemy: Dictionary = SimEnemies.make_enemy(state, kind, pos)
    enemy = SimEnemies.apply_affix_on_spawn(enemy)
    state.enemy_next_id += 1
    state.enemies.append(enemy)
    var affix_text: String = ""
    if enemy.has("affix"):
        affix_text = " [%s]" % str(enemy.get("affix", ""))
    events.append("Enemy spawned: %s#%d at (%d,%d) [hp %d]%s word=%s." % [
        kind,
        int(enemy.get("id", 0)),
        pos.x,
        pos.y,
        int(enemy.get("hp", 0)),
        affix_text,
        str(enemy.get("word", ""))
    ])
    # Swarm multi-spawn: spawn 1-2 extra swarms nearby
    if kind == "swarm" and state.night_spawn_remaining > 0:
        var extra_count: int = SimRng.roll_range(state, 1, 2)
        for _i in range(extra_count):
            if state.night_spawn_remaining <= 0:
                break
            var extra_spawn_index: int = _pick_spawn_tile(state)
            if extra_spawn_index < 0:
                break
            state.night_spawn_remaining -= 1
            var extra_pos: Vector2i = SimMap.pos_from_index(extra_spawn_index, state.map_w)
            var extra_enemy: Dictionary = SimEnemies.make_enemy(state, "swarm", extra_pos)
            state.enemy_next_id += 1
            state.enemies.append(extra_enemy)
            events.append("Swarm pack: %s#%d at (%d,%d) word=%s." % [
                "swarm",
                int(extra_enemy.get("id", 0)),
                extra_pos.x,
                extra_pos.y,
                str(extra_enemy.get("word", ""))
            ])

static func _tower_attack_step(state: GameState, dist_field: PackedInt32Array, events: Array[String]) -> void:
    if state.enemies.is_empty():
        return
    var tower_indices: Array[int] = []
    for key in state.structures.keys():
        if str(state.structures[key]) == "tower":
            tower_indices.append(int(key))
    tower_indices.sort()
    for index in tower_indices:
        if state.enemies.is_empty():
            return
        var tower_pos: Vector2i = SimMap.pos_from_index(index, state.map_w)
        var level: int = int(state.structure_levels.get(index, 1))
        var stats: Dictionary = SimBuildings.tower_stats(level)
        var range: int = int(stats.get("range", 3))
        var damage: int = int(stats.get("damage", 1))
        var shots: int = int(stats.get("shots", 1))
        for _shot in range(shots):
            if state.enemies.is_empty():
                return
            var target_index: int = SimEnemies.pick_target_index(state.enemies, dist_field, state.map_w, tower_pos, range)
            if target_index < 0:
                break
            var enemy: Dictionary = state.enemies[target_index]
            enemy = SimEnemies.apply_damage(enemy, damage, state)
            state.enemies[target_index] = enemy
            var enemy_id: int = int(enemy.get("id", 0))
            var enemy_kind: String = str(enemy.get("kind", "raider"))
            events.append("Tower hits %s#%d." % [enemy_kind, enemy_id])
            # Berserker rage: speed boost when damaged but not killed
            if int(enemy.get("hp", 0)) > 0 and enemy_kind == "berserker":
                if not enemy.get("enraged", false):
                    enemy["enraged"] = true
                    enemy["speed"] = int(enemy.get("speed", 1)) + 1
                    state.enemies[target_index] = enemy
                    events.append("Berserker#%d enters a rage! Speed +1." % enemy_id)
            if int(enemy.get("hp", 0)) <= 0:
                var enemy_pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
                # Splitting affix: spawn swarm minions on death
                if enemy.get("affix", "") == "splitting":
                    _spawn_split_enemies(state, enemy_pos, events)
                state.enemies.remove_at(target_index)
                events.append("Enemy %s#%d destroyed." % [enemy_kind, enemy_id])

static func _enemy_move_step(state: GameState, dist_field: PackedInt32Array, events: Array[String]) -> void:
    if state.enemies.is_empty():
        return
    var ids: Array[int] = _sorted_enemy_ids(state.enemies)
    var offsets: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
    var speed_reduction: float = SimUpgrades.get_enemy_speed_reduction(state)
    var damage_reduction: float = SimUpgrades.get_damage_reduction(state)
    for enemy_id in ids:
        var enemy_index: int = _find_enemy_index(state.enemies, enemy_id)
        if enemy_index < 0:
            continue
        var enemy: Dictionary = SimEnemies.normalize_enemy(state.enemies[enemy_index])
        state.enemies[enemy_index] = enemy
        # Apply speed reduction from upgrades
        var base_speed: int = int(enemy.get("speed", 1))
        var reduced_speed: float = float(base_speed) * (1.0 - speed_reduction)
        var speed: int = max(1, int(reduced_speed))
        var kind: String = str(enemy.get("kind", "raider"))
        for _step in range(speed):
            var pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
            if pos == state.base_pos:
                # Apply damage reduction from upgrades
                var blocked: bool = damage_reduction > 0.0 and float(SimRng.roll_range(state, 1, 100)) / 100.0 <= damage_reduction
                if not blocked:
                    state.hp -= 1
                    events.append("Enemy %s#%d hits the base." % [kind, enemy_id])
                else:
                    events.append("Enemy %s#%d blocked!" % [kind, enemy_id])
                state.enemies.remove_at(enemy_index)
                break
            var current_dist: int = SimEnemies.dist_at(dist_field, pos, state.map_w)
            if current_dist < 0:
                break
            var next_pos: Vector2i = pos
            for offset in offsets:
                var candidate: Vector2i = pos + offset
                if not SimMap.in_bounds(candidate.x, candidate.y, state.map_w, state.map_h):
                    continue
                var candidate_dist: int = SimEnemies.dist_at(dist_field, candidate, state.map_w)
                if candidate_dist >= 0 and candidate_dist < current_dist:
                    next_pos = candidate
                    break
            if next_pos != pos:
                enemy["pos"] = next_pos
                state.enemies[enemy_index] = enemy
                if next_pos == state.base_pos:
                    # Apply damage reduction from upgrades
                    var blocked: bool = damage_reduction > 0.0 and float(SimRng.roll_range(state, 1, 100)) / 100.0 <= damage_reduction
                    if not blocked:
                        state.hp -= 1
                        events.append("Enemy %s#%d hits the base." % [kind, enemy_id])
                    else:
                        events.append("Enemy %s#%d blocked!" % [kind, enemy_id])
                    state.enemies.remove_at(enemy_index)
                    break

static func _sorted_enemy_ids(enemies: Array) -> Array[int]:
    var ids: Array[int] = []
    for enemy in enemies:
        if typeof(enemy) != TYPE_DICTIONARY:
            continue
        ids.append(int(enemy.get("id", 0)))
    ids.sort()
    return ids

static func _find_enemy_index(enemies: Array, enemy_id: int) -> int:
    for i in range(enemies.size()):
        var enemy: Dictionary = enemies[i]
        if int(enemy.get("id", 0)) == enemy_id:
            return i
    return -1

static func _find_enemy_index_by_word(state: GameState, text: String) -> int:
    var normalized: String = text.to_lower()
    if normalized == "":
        return -1
    var best_index: int = -1
    var best_id: int = 999999
    for i in range(state.enemies.size()):
        var enemy: Dictionary = state.enemies[i]
        if typeof(enemy) != TYPE_DICTIONARY:
            continue
        var word: String = str(enemy.get("word", "")).to_lower()
        if word != normalized:
            continue
        var enemy_id: int = int(enemy.get("id", 0))
        if enemy_id < best_id:
            best_id = enemy_id
            best_index = i
    return best_index

static func _spawn_split_enemies(state: GameState, origin_pos: Vector2i, events: Array[String]) -> void:
    # Spawn 2 swarm enemies near the origin position
    var offsets: Array[Vector2i] = [
        Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
        Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)
    ]
    var spawned: int = 0
    for offset in offsets:
        if spawned >= 2:
            break
        var pos: Vector2i = origin_pos + offset
        if not SimMap.in_bounds(pos.x, pos.y, state.map_w, state.map_h):
            continue
        if pos == state.base_pos:
            continue
        SimMap.ensure_tile_generated(state, pos)
        if not SimMap.is_passable(state, pos):
            continue
        var enemy: Dictionary = SimEnemies.make_enemy(state, "swarm", pos)
        state.enemy_next_id += 1
        state.enemies.append(enemy)
        events.append("Split! Swarm#%d spawns at (%d,%d) word=%s." % [
            int(enemy.get("id", 0)),
            pos.x,
            pos.y,
            str(enemy.get("word", ""))
        ])
        spawned += 1

static func _pick_spawn_tile(state: GameState) -> int:
    var candidates: Array[int] = []
    var seen: Dictionary = {}
    var w: int = state.map_w
    var h: int = state.map_h
    for x in range(w):
        _try_spawn_candidate(state, candidates, seen, Vector2i(x, 0))
        _try_spawn_candidate(state, candidates, seen, Vector2i(x, h - 1))
    for y in range(h):
        _try_spawn_candidate(state, candidates, seen, Vector2i(0, y))
        _try_spawn_candidate(state, candidates, seen, Vector2i(w - 1, y))
    if candidates.is_empty():
        return -1
    candidates.sort()
    return int(SimRng.choose(state, candidates))

static func _try_spawn_candidate(state: GameState, candidates: Array[int], seen: Dictionary, pos: Vector2i) -> void:
    if not SimMap.in_bounds(pos.x, pos.y, state.map_w, state.map_h):
        return
    if pos == state.base_pos:
        return
    var index: int = SimMap.idx(pos.x, pos.y, state.map_w)
    if seen.has(index):
        return
    seen[index] = true
    SimMap.ensure_tile_generated(state, pos)
    if SimMap.is_passable(state, pos):
        candidates.append(index)

static func _apply_cursor(state: GameState, intent: Dictionary, events: Array[String]) -> void:
    var pos: Vector2i = _intent_position(state, intent)
    if not SimMap.in_bounds(pos.x, pos.y, state.map_w, state.map_h):
        events.append("Cursor out of bounds.")
        return
    state.cursor_pos = pos
    events.append("Cursor moved to (%d,%d)." % [pos.x, pos.y])

static func _apply_cursor_move(state: GameState, intent: Dictionary, events: Array[String]) -> void:
    var dx: int = int(intent.get("dx", 0))
    var dy: int = int(intent.get("dy", 0))
    var steps: int = int(intent.get("steps", 1))
    if steps <= 0:
        events.append("Invalid cursor movement.")
        return
    var pos: Vector2i = state.cursor_pos + Vector2i(dx, dy) * steps
    pos.x = clamp(pos.x, 0, state.map_w - 1)
    pos.y = clamp(pos.y, 0, state.map_h - 1)
    state.cursor_pos = pos
    events.append("Cursor moved to (%d,%d)." % [pos.x, pos.y])

static func _apply_inspect(state: GameState, intent: Dictionary, events: Array[String]) -> void:
    var pos: Vector2i = _intent_position(state, intent)
    if not SimMap.in_bounds(pos.x, pos.y, state.map_w, state.map_h):
        events.append("Inspect out of bounds.")
        return
    var report: Dictionary = SimBuildings.get_tile_report(state, pos)
    events.append(_format_tile_report(report))

static func _apply_map(state: GameState, events: Array[String]) -> void:
    events.append(SimMap.render_ascii(state))

static func _apply_lesson_show(state: GameState, events: Array[String]) -> void:
    var lesson_ids: PackedStringArray = SimLessons.lesson_ids()
    var entries: Array[String] = []
    for lesson_id in lesson_ids:
        entries.append("%s (%s)" % [SimLessons.lesson_label(str(lesson_id)), str(lesson_id)])
    events.append("Current lesson: %s (%s)" % [SimLessons.lesson_label(state.lesson_id), state.lesson_id])
    if entries.is_empty():
        events.append("Lessons: none available.")
    else:
        events.append("Lessons: %s" % ", ".join(entries))
    events.append("Use: lesson <id> | lesson next | lesson prev | lesson sample [n]")

static func _apply_lesson_set(state: GameState, intent: Dictionary, events: Array[String]) -> void:
    if not _require_day_or_game_over(state, events):
        return
    var lesson_id: String = str(intent.get("lesson_id", "")).strip_edges().to_lower()
    if lesson_id == "":
        events.append("Lesson id required.")
        return
    if not SimLessons.is_valid(lesson_id):
        events.append("Unknown lesson: %s." % lesson_id)
        return
    state.lesson_id = lesson_id
    events.append("Lesson set to %s (%s)." % [SimLessons.lesson_label(lesson_id), lesson_id])
    events.append(_format_status(state))

static func _apply_lesson_cycle(state: GameState, delta: int, events: Array[String]) -> void:
    if not _require_day_or_game_over(state, events):
        return
    var lesson_ids: PackedStringArray = SimLessons.lesson_ids()
    if lesson_ids.is_empty():
        events.append("No lessons available.")
        return
    var size: int = lesson_ids.size()
    var current_index: int = lesson_ids.find(state.lesson_id)
    if current_index < 0:
        current_index = 0
    var next_index: int = current_index + delta
    if next_index < 0:
        next_index = size - 1
    elif next_index >= size:
        next_index = 0
    var lesson_id: String = str(lesson_ids[next_index])
    state.lesson_id = lesson_id
    events.append("Lesson set to %s (%s)." % [SimLessons.lesson_label(lesson_id), lesson_id])
    events.append(_format_status(state))

static func _apply_lesson_sample(state: GameState, intent: Dictionary, events: Array[String]) -> void:
    var count: int = int(intent.get("count", 3))
    if count <= 0:
        events.append("Sample count must be a positive integer.")
        return
    events.append("Lesson samples for %s (%s):" % [SimLessons.lesson_label(state.lesson_id), state.lesson_id])
    var used: Dictionary = {}
    for kind in ["scout", "raider", "armored"]:
        var words: Array[String] = []
        for i in range(count):
            var word: String = SimWords.word_for_enemy("lesson-sample", 1, kind, i + 1, used, state.lesson_id)
            if word == "":
                word = "n/a"
            else:
                used[word] = true
            words.append(word)
        events.append("%s: %s" % [kind, ", ".join(words)])

static func _apply_demolish(state: GameState, intent: Dictionary, events: Array[String]) -> void:
    if not _require_day(state, events):
        return
    var pos: Vector2i = _intent_position(state, intent)
    if not SimMap.in_bounds(pos.x, pos.y, state.map_w, state.map_h):
        events.append("Demolish out of bounds.")
        return
    if pos == state.base_pos:
        events.append("Cannot demolish the base tile.")
        return
    var index: int = SimMap.idx(pos.x, pos.y, state.map_w)
    if not state.structures.has(index):
        events.append("No structure to demolish.")
        return
    if not _consume_ap(state, events):
        return
    var building_type: String = str(state.structures[index])
    var level: int = int(state.structure_levels.get(index, 1))
    state.structures.erase(index)
    state.structure_levels.erase(index)
    if state.buildings.has(building_type):
        state.buildings[building_type] = max(0, int(state.buildings.get(building_type, 0)) - 1)
    var refund: Dictionary = _refund_for(building_type, level)
    _apply_refund(state, refund)
    events.append("Demolished %s at (%d,%d)." % [building_type, pos.x, pos.y])
    events.append("Refunded: %s." % _format_resource_list(refund, false))
    events.append(_format_status(state))

static func _apply_upgrade(state: GameState, intent: Dictionary, events: Array[String]) -> void:
    if not _require_day(state, events):
        return
    var pos: Vector2i = _intent_position(state, intent)
    if not SimMap.in_bounds(pos.x, pos.y, state.map_w, state.map_h):
        events.append("Upgrade out of bounds.")
        return
    var index: int = SimMap.idx(pos.x, pos.y, state.map_w)
    if not state.structures.has(index):
        events.append("No structure to upgrade.")
        return
    if str(state.structures[index]) != "tower":
        events.append("Only towers can be upgraded.")
        return
    var level: int = int(state.structure_levels.get(index, 1))
    var max_level: int = SimBuildings.tower_max_level()
    if level >= max_level:
        events.append("Tower is already max level.")
        return
    var cost: Dictionary = SimBuildings.upgrade_cost_for(level)
    if not _has_resources(state, cost):
        events.append("Not enough resources to upgrade tower.")
        return
    if not _consume_ap(state, events):
        return
    _apply_cost(state, cost)
    state.structure_levels[index] = level + 1
    events.append("Upgraded tower at (%d,%d) to level %d." % [pos.x, pos.y, level + 1])
    events.append(_format_status(state))

static func _apply_enemies(state: GameState, events: Array[String]) -> void:
    if state.enemies.is_empty():
        events.append("No enemies on the field.")
        return
    var dist_field: PackedInt32Array = SimMap.compute_dist_to_base(state)
    var ids: Array[int] = _sorted_enemy_ids(state.enemies)
    for enemy_id in ids:
        var enemy_index: int = _find_enemy_index(state.enemies, enemy_id)
        if enemy_index < 0:
            continue
        var enemy: Dictionary = state.enemies[enemy_index]
        var pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
        var dist: int = SimEnemies.dist_at(dist_field, pos, state.map_w)
        events.append("Enemy #%d %s hp %d (%d,%d) word %s dist %d" % [
            enemy_id,
            str(enemy.get("kind", "raider")),
            int(enemy.get("hp", 0)),
            pos.x,
            pos.y,
            str(enemy.get("word", "")),
            dist
        ])

static func _intent_position(state: GameState, intent: Dictionary) -> Vector2i:
    if intent.has("x") and intent.has("y"):
        return Vector2i(int(intent.get("x", 0)), int(intent.get("y", 0)))
    return state.cursor_pos

static func _explore_reward(state: GameState, terrain: String) -> Dictionary:
    var choices: Array[String] = []
    var amount: int = 8
    match terrain:
        SimMap.TERRAIN_FOREST:
            choices = ["wood", "wood", "wood", "food", "stone"]
        SimMap.TERRAIN_MOUNTAIN:
            choices = ["stone", "stone", "stone", "wood", "food"]
        SimMap.TERRAIN_PLAINS:
            choices = ["food", "food", "food", "wood", "stone"]
        SimMap.TERRAIN_WATER:
            choices = ["food", "food", "wood"]
            amount = 5
        _:
            choices = ["food", "wood", "stone"]
    var reward_resource: String = str(SimRng.choose(state, choices))
    if reward_resource == "":
        reward_resource = "food"
    var override_resource: String = SimBalance.maybe_override_explore_reward(state, reward_resource)
    if override_resource != reward_resource and amount < 8:
        amount = 8
    reward_resource = override_resource
    return {"resource": reward_resource, "amount": amount}

static func _format_status(state: GameState) -> String:
    var building_parts: Array[String] = []
    for building_type in GameState.BUILDING_KEYS:
        var count: int = int(state.buildings.get(building_type, 0))
        if count > 0:
            building_parts.append("%s:%d" % [building_type, count])
    var building_text: String = "none" if building_parts.is_empty() else ", ".join(building_parts)
    var defense: int = SimBuildings.total_defense(state)
    var path_text: String = "yes" if state.last_path_open else "no"

    var lines: Array[String] = []
    lines.append("Phase: %s" % state.phase)
    lines.append("Lesson: %s (%s)" % [SimLessons.lesson_label(state.lesson_id), state.lesson_id])
    lines.append("Day: %d" % state.day)
    lines.append("AP: %d/%d" % [state.ap, state.ap_max])
    lines.append("HP: %d" % state.hp)
    lines.append("Threat: %d" % state.threat)
    lines.append("Gold: %d" % state.gold)
    lines.append("Defense: %d" % defense)
    lines.append("Path open: %s" % path_text)
    lines.append("Cursor: (%d,%d)" % [state.cursor_pos.x, state.cursor_pos.y])
    lines.append("Enemies: %d" % state.enemies.size())
    if state.phase == "night":
        lines.append("Night spawns: %d/%d" % [state.night_spawn_remaining, state.night_wave_total])
    lines.append("Resources: Wood %d | Stone %d | Food %d" % [
        int(state.resources.get("wood", 0)),
        int(state.resources.get("stone", 0)),
        int(state.resources.get("food", 0))
    ])
    lines.append("Buildings: %s" % building_text)
    return "\n".join(lines)

static func _format_tile_report(report: Dictionary) -> String:
    var pos: Vector2i = report.get("pos", Vector2i.ZERO)
    var discovered: bool = bool(report.get("discovered", false))
    var terrain: String = str(report.get("terrain", ""))
    var structure: String = str(report.get("structure", ""))
    var adjacency: Dictionary = report.get("adjacency", {})
    var lines: Array[String] = []
    lines.append("Inspect (%d,%d)" % [pos.x, pos.y])
    lines.append("Discovered: %s" % ("yes" if discovered else "no"))
    lines.append("Terrain: %s" % (terrain if terrain != "" else "unknown"))
    lines.append("Structure: %s" % (structure if structure != "" else "none"))
    var structure_level: int = int(report.get("structure_level", 0))
    if structure == "tower":
        lines.append("Tower level: %d" % structure_level)
        var tower_stats: Dictionary = report.get("tower_stats", {})
        lines.append("Tower stats: range %d dmg %d shots %d" % [
            int(tower_stats.get("range", 0)),
            int(tower_stats.get("damage", 0)),
            int(tower_stats.get("shots", 0))
        ])
        var upgrade_preview: Dictionary = report.get("upgrade_preview", {})
        if bool(upgrade_preview.get("ok", false)):
            var next_level: int = int(upgrade_preview.get("next_level", structure_level + 1))
            var next_stats: Dictionary = upgrade_preview.get("stats", {})
            lines.append("Upgrade -> L%d: cost %s | range %d dmg %d shots %d" % [
                next_level,
                _format_resource_list(upgrade_preview.get("cost", {}), false),
                int(next_stats.get("range", 0)),
                int(next_stats.get("damage", 0)),
                int(next_stats.get("shots", 0))
            ])
        elif structure == "tower":
            lines.append("Upgrade: MAX LEVEL")
    if bool(report.get("is_base", false)):
        lines.append("Tile: base")
    lines.append("Adjacency: water %d | forest %d | mountain %d | wall %d" % [
        int(adjacency.get("water", 0)),
        int(adjacency.get("forest", 0)),
        int(adjacency.get("mountain", 0)),
        int(adjacency.get("wall", 0))
    ])
    lines.append("Build preview:")
    var previews: Dictionary = report.get("previews", {})
    for building_type in SimBuildings.list_types():
        var preview: Dictionary = previews.get(building_type, {})
        var ok_text: String = "yes"
        if not bool(preview.get("ok", false)):
            ok_text = "no (%s)" % str(preview.get("reason", "blocked"))
        var cost_text: String = _format_resource_list(preview.get("cost", {}), false)
        var prod_text: String = _format_resource_list(preview.get("production", {}), true)
        var defense: int = int(preview.get("defense", 0))
        var extra: String = ""
        if building_type == "tower":
            var tower_stats_preview: Dictionary = preview.get("tower_stats", {})
            extra = " | range %d dmg %d shots %d" % [
                int(tower_stats_preview.get("range", 0)),
                int(tower_stats_preview.get("damage", 0)),
                int(tower_stats_preview.get("shots", 0))
            ]
        lines.append("%s: buildable %s | cost %s | prod %s | def %d%s" % [
            building_type, ok_text, cost_text, prod_text, defense, extra
        ])
    return "\n".join(lines)

static func _format_resource_list(values: Dictionary, show_plus: bool) -> String:
    var parts: Array[String] = []
    for key in GameState.RESOURCE_KEYS:
        if not values.has(key):
            continue
        var amount: int = int(values.get(key, 0))
        if amount == 0:
            continue
        if show_plus:
            parts.append("%s +%d" % [key, amount])
        else:
            parts.append("%s %d" % [key, amount])
    if parts.is_empty():
        return "none"
    return ", ".join(parts)

static func _copy_state(state: GameState) -> GameState:
    var copy: GameState = GameState.new()
    copy.day = state.day
    copy.phase = state.phase
    copy.ap_max = state.ap_max
    copy.ap = state.ap
    copy.hp = state.hp
    copy.threat = state.threat
    copy.resources = state.resources.duplicate(true)
    copy.buildings = state.buildings.duplicate(true)
    copy.map_w = state.map_w
    copy.map_h = state.map_h
    copy.base_pos = state.base_pos
    copy.cursor_pos = state.cursor_pos
    copy.terrain = state.terrain.duplicate(true)
    copy.structures = state.structures.duplicate(true)
    copy.structure_levels = state.structure_levels.duplicate(true)
    copy.discovered = state.discovered.duplicate(true)
    copy.night_prompt = state.night_prompt
    copy.night_spawn_remaining = state.night_spawn_remaining
    copy.night_wave_total = state.night_wave_total
    copy.enemies = state.enemies.duplicate(true)
    copy.enemy_next_id = state.enemy_next_id
    copy.last_path_open = state.last_path_open
    copy.rng_seed = state.rng_seed
    copy.rng_state = state.rng_state
    copy.lesson_id = state.lesson_id
    copy.version = state.version
    # Event system state
    copy.active_pois = state.active_pois.duplicate(true)
    copy.event_cooldowns = state.event_cooldowns.duplicate(true)
    copy.event_flags = state.event_flags.duplicate(true)
    copy.pending_event = state.pending_event.duplicate(true)
    copy.active_buffs = state.active_buffs.duplicate(true)
    # Upgrade system state
    copy.purchased_kingdom_upgrades = state.purchased_kingdom_upgrades.duplicate()
    copy.purchased_unit_upgrades = state.purchased_unit_upgrades.duplicate()
    copy.gold = state.gold
    return copy

static func _require_day(state: GameState, events: Array[String]) -> bool:
    if state.phase != "day":
        events.append("That action is only available during the day.")
        return false
    return true

static func _require_day_or_game_over(state: GameState, events: Array[String]) -> bool:
    if state.phase != "day" and state.phase != "game_over":
        events.append("Lesson changes are only available during the day or after game over.")
        return false
    return true

static func _consume_ap(state: GameState, events: Array[String]) -> bool:
    if state.ap <= 0:
        events.append("No AP left.")
        return false
    state.ap -= 1
    return true

static func _has_resources(state: GameState, cost: Dictionary) -> bool:
    for key in cost.keys():
        if int(state.resources.get(key, 0)) < int(cost[key]):
            return false
    return true

static func _apply_cost(state: GameState, cost: Dictionary) -> void:
    for key in cost.keys():
        state.resources[key] = int(state.resources.get(key, 0)) - int(cost[key])

static func _apply_refund(state: GameState, refund: Dictionary) -> void:
    for key in refund.keys():
        var amount: int = int(refund[key])
        if amount <= 0:
            continue
        state.resources[key] = int(state.resources.get(key, 0)) + amount

static func _refund_for(building_type: String, level: int) -> Dictionary:
    var refund: Dictionary = {}
    if not SimBuildings.is_valid(building_type):
        return refund
    var cost: Dictionary = SimBuildings.invested_cost(building_type, level)
    for key in cost.keys():
        refund[key] = int(int(cost[key]) * 0.5)
    return refund

static func _pick_explore_tile(state: GameState) -> int:
    var candidates: Array[int] = _adjacent_undiscovered(state)
    if candidates.is_empty():
        candidates = _all_undiscovered(state)
    if candidates.is_empty():
        return -1
    candidates.sort()
    var choice = SimRng.choose(state, candidates)
    return int(choice)

static func _adjacent_undiscovered(state: GameState) -> Array[int]:
    var results: Array[int] = []
    var seen: Dictionary = {}
    var offsets: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
    for key in state.discovered.keys():
        var index: int = int(key)
        var x: int = index % state.map_w
        var y: int = int(index / state.map_w)
        for offset in offsets:
            var nx: int = x + offset.x
            var ny: int = y + offset.y
            if nx < 0 or ny < 0 or nx >= state.map_w or ny >= state.map_h:
                continue
            var neighbor: int = ny * state.map_w + nx
            if state.discovered.has(neighbor):
                continue
            if seen.has(neighbor):
                continue
            seen[neighbor] = true
            results.append(neighbor)
    return results

static func _all_undiscovered(state: GameState) -> Array[int]:
    var results: Array[int] = []
    for y in range(state.map_h):
        for x in range(state.map_w):
            var index: int = y * state.map_w + x
            if not state.discovered.has(index):
                results.append(index)
    return results

static func _apply_interact_poi(state: GameState, events: Array[String]) -> void:
    if not _require_day(state, events):
        return
    if SimEvents.has_pending_event(state):
        events.append("Already interacting with an event. Use 'choice' or 'skip'.")
        return
    var poi_id: String = SimPoi.get_poi_at(state, state.cursor_pos)
    if poi_id == "":
        events.append("No POI at current position.")
        return
    var poi_state: Dictionary = state.active_pois.get(poi_id, {})
    if not poi_state.get("discovered", false):
        events.append("POI not yet discovered.")
        return
    if poi_state.get("interacted", false):
        events.append("Already interacted with this POI.")
        return
    var result: Dictionary = SimEvents.trigger_event_from_poi(state, poi_id)
    if not result.get("success", false):
        events.append("No event triggered: %s" % str(result.get("error", "unknown")))
        return
    var event_data: Dictionary = result.get("event", {})
    events.append("Event: %s" % str(event_data.get("title", "Unknown")))
    events.append(str(event_data.get("body", "")))
    events.append("Choices:")
    var choices: Array = event_data.get("choices", [])
    for i in range(choices.size()):
        var choice: Dictionary = choices[i]
        events.append("  [%s] %s" % [str(choice.get("id", "")), str(choice.get("label", ""))])
    events.append("Use: choice <id> <input text>")

static func _apply_event_choice(state: GameState, intent: Dictionary, events: Array[String]) -> void:
    if not SimEvents.has_pending_event(state):
        events.append("No active event.")
        return
    var choice_id: String = str(intent.get("choice_id", ""))
    var input_text: String = str(intent.get("input", ""))
    if choice_id == "":
        events.append("Choice id required.")
        return
    var result: Dictionary = SimEvents.resolve_choice(state, choice_id, input_text)
    if not result.get("success", false):
        var error: String = str(result.get("error", "unknown"))
        if error == "input_incomplete":
            var validation: Dictionary = result.get("validation", {})
            if validation.get("partial_match", false):
                events.append("Keep typing to complete the input.")
            else:
                events.append("Input does not match. Try again.")
        else:
            events.append("Choice failed: %s" % error)
        return
    events.append("Choice resolved: %s" % choice_id)
    var effects: Array = result.get("effects_applied", [])
    for effect in effects:
        if typeof(effect) != TYPE_DICTIONARY:
            continue
        var effect_type: String = str(effect.get("type", ""))
        match effect_type:
            "resource_add":
                var resource: String = str(effect.get("resource", ""))
                var amount: int = int(effect.get("amount", 0))
                if amount > 0:
                    events.append("+%d %s" % [amount, resource])
                elif amount < 0:
                    events.append("%d %s" % [amount, resource])
            "buff_apply":
                var buff_id: String = str(effect.get("buff_id", ""))
                var duration: int = int(effect.get("duration", 0))
                events.append("Buff: %s (%d days)" % [buff_id, duration])
            "damage_castle":
                var amount: int = int(effect.get("amount", 0))
                events.append("Castle damaged: -%d HP" % amount)
            "set_flag":
                var flag: String = str(effect.get("flag", ""))
                events.append("Flag set: %s" % flag)
    if result.has("chain_event"):
        var chain: Dictionary = result.get("chain_event", {})
        if chain.get("success", false):
            var event_data: Dictionary = chain.get("event", {})
            events.append("Chain event: %s" % str(event_data.get("title", "Unknown")))
    events.append(_format_status(state))

static func _apply_event_skip(state: GameState, events: Array[String]) -> void:
    if not SimEvents.has_pending_event(state):
        events.append("No active event to skip.")
        return
    var result: Dictionary = SimEvents.skip_event(state)
    if result.get("success", false):
        events.append("Event skipped.")
    else:
        events.append("Failed to skip event: %s" % str(result.get("error", "unknown")))

static func _apply_buy_upgrade(state: GameState, intent: Dictionary, events: Array[String]) -> void:
    var category: String = str(intent.get("category", ""))
    var upgrade_id: String = str(intent.get("upgrade_id", ""))

    if category == "kingdom":
        var result: Dictionary = SimUpgrades.purchase_kingdom_upgrade(state, upgrade_id)
        if result.get("ok", false):
            events.append(str(result.get("message", "Upgrade purchased")))
            events.append(_format_status(state))
        else:
            events.append("Cannot purchase: %s" % str(result.get("error", "unknown")))
    elif category == "unit":
        var result: Dictionary = SimUpgrades.purchase_unit_upgrade(state, upgrade_id)
        if result.get("ok", false):
            events.append(str(result.get("message", "Upgrade purchased")))
            events.append(_format_status(state))
        else:
            events.append("Cannot purchase: %s" % str(result.get("error", "unknown")))
    else:
        events.append("Unknown upgrade category: %s" % category)

static func _apply_ui_upgrades(state: GameState, intent: Dictionary, events: Array[String]) -> void:
    var category: String = str(intent.get("category", "kingdom"))
    var lines: Array[String] = SimUpgrades.format_upgrade_tree(state, category)
    for line in lines:
        events.append(line)
