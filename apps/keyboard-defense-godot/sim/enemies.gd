class_name SimEnemies
extends RefCounted

const GameState = preload("res://sim/types.gd")
const SimRng = preload("res://sim/rng.gd")
const SimWords = preload("res://sim/words.gd")
const SimStatusEffects = preload("res://sim/status_effects.gd")
const SimEnemyTypes = preload("res://sim/enemy_types.gd")
const SimEnemyAbilities = preload("res://sim/enemy_abilities.gd")
const SimBossEncounters = preload("res://sim/boss_encounters.gd")

const ENEMY_KINDS := {
    "raider": {"speed": 1, "armor": 0, "hp_bonus": 0, "glyph": "r"},
    "scout": {"speed": 2, "armor": 0, "hp_bonus": -1, "glyph": "s"},
    "armored": {"speed": 1, "armor": 1, "hp_bonus": 1, "glyph": "a"},
    "swarm": {"speed": 3, "armor": 0, "hp_bonus": -2, "glyph": "w"},
    "tank": {"speed": 1, "armor": 2, "hp_bonus": 3, "glyph": "T"},
    "berserker": {"speed": 2, "armor": 0, "hp_bonus": 1, "glyph": "B"},
    "phantom": {"speed": 1, "armor": 0, "hp_bonus": 0, "glyph": "P", "evasion": 0.5},
    "champion": {"speed": 1, "armor": 1, "hp_bonus": 2, "glyph": "C"},
    "healer": {"speed": 1, "armor": 0, "hp_bonus": 0, "glyph": "H", "heal_rate": 1},
    "elite": {"speed": 1, "armor": 1, "hp_bonus": 1, "glyph": "E", "has_affix": true}
}

# Boss enemies - spawn at specific milestones
const BOSS_KINDS := {
    # Day 5 boss - Evergrove
    "forest_guardian": {"speed": 1, "armor": 1, "hp_bonus": 8, "glyph": "G", "regen_rate": 2, "is_boss": true},
    # Day 10 boss - Stonepass
    "stone_golem": {"speed": 1, "armor": 4, "hp_bonus": 12, "glyph": "S", "is_boss": true},
    # Day 15 boss - Mistfen
    "fen_seer": {"speed": 1, "armor": 1, "hp_bonus": 10, "glyph": "F", "evasion": 0.3, "summons": true, "is_boss": true},
    # Day 20 boss - Sunfields
    "sunlord": {"speed": 2, "armor": 2, "hp_bonus": 15, "glyph": "L", "enraged": true, "is_boss": true}
}

const BOSS_DAYS := {
    5: "forest_guardian",
    10: "stone_golem",
    15: "fen_seer",
    20: "sunlord"
}
const ENEMY_HP_BONUS_BY_DAY := {
    "armored": [1, 1, 1, 2, 2, 3, 4],
    "raider": [0, 0, 0, 0, 1, 1, 2],
    "scout": [-1, -1, -1, 0, 0, 0, 1],
    "swarm": [-2, -2, -2, -1, -1, 0, 0],
    "tank": [3, 3, 4, 4, 5, 5, 6],
    "berserker": [1, 1, 1, 2, 2, 2, 3],
    "phantom": [0, 0, 0, 0, 1, 1, 2],
    "champion": [2, 2, 2, 3, 3, 4, 5],
    "healer": [0, 0, 0, 1, 1, 1, 2],
    "elite": [1, 1, 2, 2, 3, 3, 4]
}
const ENEMY_ARMOR_BY_DAY := {
    "armored": [1, 1, 1, 1, 1, 2, 2],
    "raider": [0, 0, 0, 0, 0, 0, 1],
    "scout": [0, 0, 0, 0, 0, 0, 1],
    "swarm": [0, 0, 0, 0, 0, 0, 0],
    "tank": [2, 2, 2, 2, 3, 3, 3],
    "berserker": [0, 0, 0, 0, 0, 1, 1],
    "phantom": [0, 0, 0, 0, 0, 0, 0],
    "champion": [1, 1, 1, 1, 2, 2, 2],
    "healer": [0, 0, 0, 0, 0, 0, 1],
    "elite": [1, 1, 1, 1, 1, 2, 2]
}
const ENEMY_SPEED_BY_DAY := {
    "raider": [1, 1, 1, 1, 1, 1, 2],
    "scout": [2, 2, 2, 2, 2, 2, 3],
    "armored": [1, 1, 1, 1, 1, 1, 2],
    "swarm": [3, 3, 3, 3, 3, 3, 4],
    "tank": [1, 1, 1, 1, 1, 1, 1],
    "berserker": [2, 2, 2, 2, 2, 2, 3],
    "phantom": [1, 1, 1, 1, 1, 2, 2],
    "champion": [1, 1, 1, 1, 1, 1, 2],
    "healer": [1, 1, 1, 1, 1, 1, 1],
    "elite": [1, 1, 1, 1, 1, 2, 2]
}

static func hp_bonus_for_day(kind: String, day: int) -> int:
    var bonuses: Array = ENEMY_HP_BONUS_BY_DAY.get(kind, [])
    if bonuses.is_empty():
        var fallback: Dictionary = ENEMY_KINDS.get(kind, ENEMY_KINDS["raider"])
        return int(fallback.get("hp_bonus", 0))
    var index: int = int(clamp(day - 1, 0, bonuses.size() - 1))
    return int(bonuses[index])

static func armor_for_day(kind: String, day: int) -> int:
    var values: Array = ENEMY_ARMOR_BY_DAY.get(kind, [])
    if values.is_empty():
        var fallback: Dictionary = ENEMY_KINDS.get(kind, ENEMY_KINDS["raider"])
        return int(fallback.get("armor", 0))
    var index: int = int(clamp(day - 1, 0, values.size() - 1))
    return int(values[index])

static func speed_for_day(kind: String, day: int) -> int:
    var values: Array = ENEMY_SPEED_BY_DAY.get(kind, [])
    if values.is_empty():
        var fallback: Dictionary = ENEMY_KINDS.get(kind, ENEMY_KINDS["raider"])
        return int(fallback.get("speed", 1))
    var index: int = int(clamp(day - 1, 0, values.size() - 1))
    return int(values[index])

static func make_enemy(state: GameState, kind: String, pos: Vector2i) -> Dictionary:
    var base_hp: int = 2 + int(state.day / 3) + int(state.threat / 4)
    var hp_bonus: int = hp_bonus_for_day(kind, state.day)
    var hp: int = max(1, base_hp + hp_bonus)
    var armor_value: int = armor_for_day(kind, state.day)
    var speed_value: int = speed_for_day(kind, state.day)
    var config: Dictionary = ENEMY_KINDS.get(kind, ENEMY_KINDS["raider"])
    var enemy := {
        "id": state.enemy_next_id,
        "kind": kind,
        "pos": pos,
        "hp": hp,
        "armor": armor_value,
        "speed": speed_value,
        "word": ""
    }
    # Special properties
    if config.has("evasion"):
        enemy["evasion"] = float(config["evasion"])
        enemy["evade_ready"] = true
    if config.has("heal_rate"):
        enemy["heal_rate"] = int(config["heal_rate"])
    if config.has("has_affix") and config["has_affix"]:
        enemy["affix"] = _roll_affix(state)
    return assign_word(state, enemy)

static func _roll_affix(state: GameState) -> String:
    var affixes: Array[String] = ["swift", "armored", "resilient", "shielded"]
    if state.day >= 6:
        affixes.append("thorny")
    if state.day >= 7:
        affixes.append("ghostly")
    if state.day >= 8:
        affixes.append("splitting")
    if state.day >= 9:
        affixes.append("regenerating")
        affixes.append("commanding")
    if state.day >= 10:
        affixes.append("enraged")
        affixes.append("vampiric")
    if state.day >= 12:
        affixes.append("explosive")
    var index: int = SimRng.roll_range(state, 0, affixes.size() - 1)
    return affixes[index]

static func apply_damage(enemy: Dictionary, dmg: int, state: GameState = null) -> Dictionary:
    # Phantom evasion: 50% chance to evade first hit
    if enemy.get("evade_ready", false) and enemy.get("evasion", 0.0) > 0.0:
        if state != null:
            var roll: float = float(SimRng.roll_range(state, 1, 100)) / 100.0
            if roll <= enemy["evasion"]:
                enemy["evade_ready"] = false
                return enemy  # Evaded, no damage
        enemy["evade_ready"] = false

    var armor: int = int(enemy.get("armor", 0))
    # Shielded affix: first hit immunity
    if enemy.get("shield_active", false):
        enemy["shield_active"] = false
        return enemy
    var effective: int = max(0, dmg - armor)
    # Ghostly affix: 50% damage reduction
    if enemy.get("ghostly", false):
        effective = max(1, effective / 2)
    enemy["hp"] = int(enemy.get("hp", 0)) - effective
    return enemy

static func apply_affix_on_spawn(enemy: Dictionary) -> Dictionary:
    var affix: String = str(enemy.get("affix", ""))
    match affix:
        "swift":
            enemy["speed"] = int(enemy.get("speed", 1)) + 1
        "armored":
            enemy["armor"] = int(enemy.get("armor", 0)) + 1
        "resilient":
            enemy["hp"] = int(enemy.get("hp", 1)) + 2
        "shielded":
            enemy["shield_active"] = true
        "regenerating":
            enemy["regen_rate"] = 1
        "enraged":
            enemy["enraged"] = true
        "vampiric":
            enemy["vampiric"] = true
        "thorny":
            enemy["thorny"] = true  # Reflects 1 damage when hit
        "ghostly":
            enemy["ghostly"] = true  # 50% damage reduction
        "commanding":
            enemy["commanding"] = true  # Buffs nearby allies
        "explosive":
            enemy["explosive"] = true  # Deals damage on death
    return enemy

static func apply_healer_tick(enemies: Array, healer_index: int) -> void:
    if healer_index < 0 or healer_index >= enemies.size():
        return
    var healer: Dictionary = enemies[healer_index]
    var heal_rate: int = int(healer.get("heal_rate", 0))
    if heal_rate <= 0:
        return
    var healer_pos: Vector2i = healer.get("pos", Vector2i.ZERO)
    for i in range(enemies.size()):
        if i == healer_index:
            continue
        var enemy: Dictionary = enemies[i]
        var enemy_pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
        if manhattan(healer_pos, enemy_pos) <= 2:
            enemy["hp"] = int(enemy.get("hp", 0)) + heal_rate
            enemies[i] = enemy

static func apply_regen_tick(enemy: Dictionary) -> Dictionary:
    var regen: int = int(enemy.get("regen_rate", 0))
    if regen > 0:
        enemy["hp"] = int(enemy.get("hp", 0)) + regen
    return enemy

static func enemy_glyph(kind: String) -> String:
    if BOSS_KINDS.has(kind):
        return str(BOSS_KINDS[kind].get("glyph", "!"))
    return str(ENEMY_KINDS.get(kind, ENEMY_KINDS["raider"]).get("glyph", "r"))

## Gold reward for defeating an enemy
static func gold_reward(kind: String) -> int:
    var rewards := {
        "scout": 1,
        "raider": 2,
        "armored": 3,
        "swarm": 1,
        "tank": 4,
        "berserker": 3,
        "phantom": 3,
        "champion": 5,
        "healer": 4,
        "elite": 6,
        # Boss rewards
        "forest_guardian": 25,
        "stone_golem": 40,
        "fen_seer": 55,
        "sunlord": 75
    }
    return int(rewards.get(kind, 2))

## Check if a day triggers a boss encounter
static func is_boss_day(day: int) -> bool:
    return BOSS_DAYS.has(day)

## Get the boss kind for a given day (empty string if not boss day)
static func get_boss_for_day(day: int) -> String:
    return str(BOSS_DAYS.get(day, ""))

## Create a boss enemy with enhanced stats
static func make_boss(state: GameState, kind: String, pos: Vector2i) -> Dictionary:
    var config: Dictionary = BOSS_KINDS.get(kind, {})
    if config.is_empty():
        push_warning("Unknown boss kind: %s" % kind)
        return make_enemy(state, "champion", pos)

    # Boss HP: higher base + bonus
    var base_hp: int = 10 + int(state.day / 2) + int(state.threat / 3)
    var hp_bonus: int = int(config.get("hp_bonus", 0))
    var hp: int = base_hp + hp_bonus

    var boss := {
        "id": state.enemy_next_id,
        "kind": kind,
        "pos": pos,
        "hp": hp,
        "hp_max": hp,  # Track max HP for phase transitions
        "armor": int(config.get("armor", 0)),
        "speed": int(config.get("speed", 1)),
        "word": "",
        "is_boss": true
    }

    # Apply special boss properties
    if config.has("regen_rate"):
        boss["regen_rate"] = int(config["regen_rate"])
    if config.has("evasion"):
        boss["evasion"] = float(config["evasion"])
        boss["evade_ready"] = true
    if config.has("summons"):
        boss["summons"] = true
        boss["summon_cooldown"] = 0
    if config.has("enraged"):
        boss["enraged"] = true

    return assign_word(state, boss)

## Apply boss ability tick (called each turn)
static func apply_boss_tick(state: GameState, boss_index: int, events: Array[String]) -> void:
    if boss_index < 0 or boss_index >= state.enemies.size():
        return

    var boss: Dictionary = state.enemies[boss_index]
    var kind: String = str(boss.get("kind", ""))

    match kind:
        "forest_guardian":
            # Regenerates HP each tick
            var regen: int = int(boss.get("regen_rate", 2))
            var old_hp: int = int(boss.get("hp", 0))
            var max_hp: int = int(boss.get("hp_max", old_hp))
            boss["hp"] = min(max_hp, old_hp + regen)
            if boss["hp"] > old_hp:
                events.append("Forest Guardian regenerates %d HP." % (int(boss["hp"]) - old_hp))
        "fen_seer":
            # Summons swarms periodically
            if int(boss.get("summon_cooldown", 0)) <= 0:
                boss["summon_cooldown"] = 3  # Every 3 ticks
                var boss_pos: Vector2i = boss.get("pos", Vector2i.ZERO)
                var summon_pos: Vector2i = Vector2i(boss_pos.x + 1, boss_pos.y)
                if summon_pos.x < state.map_w:
                    var swarm: Dictionary = make_enemy(state, "phantom", summon_pos)
                    state.enemy_next_id += 1
                    state.enemies.append(swarm)
                    events.append("Fen Seer conjures a phantom!")
            else:
                boss["summon_cooldown"] = int(boss.get("summon_cooldown", 0)) - 1
        "sunlord":
            # Enraged: deals extra damage when attacks land
            pass  # Handled in apply_intent.gd

    state.enemies[boss_index] = boss

static func normalize_enemy(enemy: Dictionary) -> Dictionary:
    var kind: String = str(enemy.get("kind", "raider"))
    var config: Dictionary = ENEMY_KINDS.get(kind, ENEMY_KINDS["raider"])
    if not enemy.has("armor"):
        enemy["armor"] = int(config.get("armor", 0))
    if not enemy.has("speed"):
        enemy["speed"] = int(config.get("speed", 1))
    if not enemy.has("hp"):
        enemy["hp"] = 1
    if not enemy.has("pos"):
        enemy["pos"] = Vector2i.ZERO
    if not enemy.has("word"):
        enemy["word"] = ""
    enemy["kind"] = kind
    return enemy

static func assign_word(state: GameState, enemy: Dictionary) -> Dictionary:
    var current: String = str(enemy.get("word", ""))
    if current != "":
        return enemy
    var used: Dictionary = _used_words(state.enemies)
    var kind: String = str(enemy.get("kind", "raider"))
    var enemy_id: int = int(enemy.get("id", 0))
    var word: String = SimWords.word_for_enemy(state.rng_seed, state.day, kind, enemy_id, used, state.lesson_id)
    enemy["word"] = word.to_lower()
    return enemy

static func ensure_enemy_words(state: GameState) -> void:
    var used: Dictionary = _used_words(state.enemies)
    var ids: Array[int] = []
    for enemy in state.enemies:
        if typeof(enemy) != TYPE_DICTIONARY:
            continue
        ids.append(int(enemy.get("id", 0)))
    ids.sort()
    for enemy_id in ids:
        var index: int = _find_enemy_index(state.enemies, enemy_id)
        if index < 0:
            continue
        var enemy: Dictionary = normalize_enemy(state.enemies[index])
        var word: String = str(enemy.get("word", ""))
        if word == "":
            var kind: String = str(enemy.get("kind", "raider"))
            var assigned: String = SimWords.word_for_enemy(state.rng_seed, state.day, kind, enemy_id, used, state.lesson_id)
            enemy["word"] = assigned.to_lower()
            used[enemy["word"]] = true
        else:
            enemy["word"] = word.to_lower()
            used[enemy["word"]] = true
        state.enemies[index] = enemy

static func choose_spawn_kind(state: GameState) -> String:
    var kinds: Array[String] = ["raider"]
    if state.day >= 3 or state.threat >= 2:
        kinds.append("scout")
    if state.day >= 4 or state.threat >= 3:
        kinds.append("swarm")
    if state.day >= 5 or state.threat >= 4:
        kinds.append("armored")
    if state.day >= 5 or state.threat >= 5:
        kinds.append("berserker")
    if state.day >= 6 or state.threat >= 6:
        kinds.append("tank")
    if state.day >= 6 or state.threat >= 5:
        kinds.append("phantom")
    if state.day >= 7 or state.threat >= 7:
        kinds.append("champion")
    if state.day >= 7 or state.threat >= 6:
        kinds.append("healer")
    if state.day >= 8 or state.threat >= 8:
        kinds.append("elite")

    var weights: Dictionary = {}
    weights["raider"] = 6
    weights["scout"] = 2 + int(state.day / 3)
    weights["swarm"] = max(0, int(state.day / 2))
    weights["armored"] = max(0, int(state.day / 2) - 1)
    weights["berserker"] = max(0, int(state.day / 3))
    weights["tank"] = max(0, int(state.day / 3) - 1)
    weights["phantom"] = max(0, int(state.day / 3))
    weights["champion"] = max(0, int(state.day / 4))
    weights["healer"] = max(0, int(state.day / 4))
    weights["elite"] = max(0, int(state.day / 5))

    var total: int = 0
    for kind in kinds:
        total += int(weights.get(kind, 1))
    if total <= 0:
        return "raider"
    var roll: int = SimRng.roll_range(state, 1, total)
    var running: int = 0
    for kind in kinds:
        running += int(weights.get(kind, 1))
        if roll <= running:
            return kind
    return "raider"

static func serialize(enemy: Dictionary) -> Dictionary:
    var pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
    var result := {
        "id": int(enemy.get("id", 0)),
        "pos": {"x": pos.x, "y": pos.y},
        "hp": int(enemy.get("hp", 0)),
        "kind": str(enemy.get("kind", "raider")),
        "armor": int(enemy.get("armor", 0)),
        "speed": int(enemy.get("speed", 1)),
        "word": str(enemy.get("word", ""))
    }
    # Special properties
    if enemy.has("evasion"):
        result["evasion"] = float(enemy["evasion"])
        result["evade_ready"] = bool(enemy.get("evade_ready", false))
    if enemy.has("heal_rate"):
        result["heal_rate"] = int(enemy["heal_rate"])
    if enemy.has("affix"):
        result["affix"] = str(enemy["affix"])
    if enemy.has("shield_active"):
        result["shield_active"] = bool(enemy["shield_active"])
    if enemy.has("regen_rate"):
        result["regen_rate"] = int(enemy["regen_rate"])
    if enemy.has("enraged"):
        result["enraged"] = bool(enemy["enraged"])
    if enemy.has("vampiric"):
        result["vampiric"] = bool(enemy["vampiric"])
    # New affix properties
    if enemy.has("thorny"):
        result["thorny"] = bool(enemy["thorny"])
    if enemy.has("ghostly"):
        result["ghostly"] = bool(enemy["ghostly"])
    if enemy.has("commanding"):
        result["commanding"] = bool(enemy["commanding"])
    if enemy.has("explosive"):
        result["explosive"] = bool(enemy["explosive"])
    if enemy.has("commanded"):
        result["commanded"] = bool(enemy["commanded"])
    # Boss properties
    if enemy.has("is_boss"):
        result["is_boss"] = bool(enemy["is_boss"])
    if enemy.has("hp_max"):
        result["hp_max"] = int(enemy["hp_max"])
    if enemy.has("summons"):
        result["summons"] = bool(enemy["summons"])
    if enemy.has("summon_cooldown"):
        result["summon_cooldown"] = int(enemy["summon_cooldown"])
    # Status effects
    if enemy.has("status_effects"):
        result["status_effects"] = SimStatusEffects.serialize_effects(enemy["status_effects"])
    if enemy.has("freeze_immunity"):
        result["freeze_immunity"] = float(enemy["freeze_immunity"])
    return result

static func deserialize(raw: Dictionary) -> Dictionary:
    var pos_data: Dictionary = raw.get("pos", {})
    var pos: Vector2i = Vector2i(int(pos_data.get("x", 0)), int(pos_data.get("y", 0)))
    var result := {
        "id": int(raw.get("id", 0)),
        "pos": pos,
        "hp": int(raw.get("hp", 0)),
        "kind": str(raw.get("kind", "raider")),
        "armor": int(raw.get("armor", 0)),
        "speed": int(raw.get("speed", 1)),
        "word": str(raw.get("word", ""))
    }
    # Special properties
    if raw.has("evasion"):
        result["evasion"] = float(raw["evasion"])
        result["evade_ready"] = bool(raw.get("evade_ready", false))
    if raw.has("heal_rate"):
        result["heal_rate"] = int(raw["heal_rate"])
    if raw.has("affix"):
        result["affix"] = str(raw["affix"])
    if raw.has("shield_active"):
        result["shield_active"] = bool(raw["shield_active"])
    if raw.has("regen_rate"):
        result["regen_rate"] = int(raw["regen_rate"])
    if raw.has("enraged"):
        result["enraged"] = bool(raw["enraged"])
    if raw.has("vampiric"):
        result["vampiric"] = bool(raw["vampiric"])
    # New affix properties
    if raw.has("thorny"):
        result["thorny"] = bool(raw["thorny"])
    if raw.has("ghostly"):
        result["ghostly"] = bool(raw["ghostly"])
    if raw.has("commanding"):
        result["commanding"] = bool(raw["commanding"])
    if raw.has("explosive"):
        result["explosive"] = bool(raw["explosive"])
    if raw.has("commanded"):
        result["commanded"] = bool(raw["commanded"])
    # Boss properties
    if raw.has("is_boss"):
        result["is_boss"] = bool(raw["is_boss"])
    if raw.has("hp_max"):
        result["hp_max"] = int(raw["hp_max"])
    if raw.has("summons"):
        result["summons"] = bool(raw["summons"])
    if raw.has("summon_cooldown"):
        result["summon_cooldown"] = int(raw["summon_cooldown"])
    # Status effects
    if raw.has("status_effects"):
        result["status_effects"] = SimStatusEffects.deserialize_effects(raw["status_effects"])
    if raw.has("freeze_immunity"):
        result["freeze_immunity"] = float(raw["freeze_immunity"])
    return result

static func _used_words(enemies: Array) -> Dictionary:
    var used: Dictionary = {}
    for enemy in enemies:
        if typeof(enemy) != TYPE_DICTIONARY:
            continue
        var word: String = str(enemy.get("word", ""))
        if word != "":
            used[word.to_lower()] = true
    return used

static func _find_enemy_index(enemies: Array, enemy_id: int) -> int:
    for i in range(enemies.size()):
        var enemy: Dictionary = enemies[i]
        if int(enemy.get("id", 0)) == enemy_id:
            return i
    return -1

static func manhattan(a: Vector2i, b: Vector2i) -> int:
    return abs(a.x - b.x) + abs(a.y - b.y)

static func dist_at(dist: PackedInt32Array, pos: Vector2i, map_w: int) -> int:
    var index: int = pos.y * map_w + pos.x
    if index < 0 or index >= dist.size():
        return -1
    return int(dist[index])

static func pick_target_index(enemies: Array, dist: PackedInt32Array, map_w: int, origin: Vector2i, max_range: int) -> int:
    var best_index: int = -1
    var best_dist: int = 999999
    var best_id: int = 999999
    for i in range(enemies.size()):
        var enemy: Dictionary = enemies[i]
        var pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
        if max_range >= 0 and manhattan(origin, pos) > max_range:
            continue
        var d: int = dist_at(dist, pos, map_w)
        if d < 0:
            continue
        var enemy_id: int = int(enemy.get("id", 0))
        if d < best_dist or (d == best_dist and enemy_id < best_id):
            best_dist = d
            best_id = enemy_id
            best_index = i
    return best_index


## Status effect helpers

## Apply a status effect to an enemy
static func apply_status_effect(enemy: Dictionary, effect_id: String, tier: int = 1, source: String = "") -> Dictionary:
    enemy = SimStatusEffects.apply_effect(enemy, effect_id, tier, source)
    enemy = SimStatusEffects.apply_effect_interactions(enemy, effect_id)
    return enemy

## Remove a status effect from an enemy
static func remove_status_effect(enemy: Dictionary, effect_id: String) -> Dictionary:
    return SimStatusEffects.remove_effect(enemy, effect_id)

## Check if enemy has a specific effect
static func has_status_effect(enemy: Dictionary, effect_id: String) -> bool:
    return SimStatusEffects.has_effect(enemy, effect_id)

## Get effective speed considering status effects
static func get_effective_speed(enemy: Dictionary) -> int:
    return SimStatusEffects.get_effective_speed(enemy)

## Get effective armor considering status effects
static func get_effective_armor(enemy: Dictionary) -> int:
    return SimStatusEffects.get_effective_armor(enemy)

## Get damage multiplier from status effects (for damage taken)
static func get_damage_taken_multiplier(enemy: Dictionary) -> float:
    return SimStatusEffects.get_damage_taken_multiplier(enemy)

## Get damage reduction for enemy attacks (weakened debuff)
static func get_damage_dealt_reduction(enemy: Dictionary) -> float:
    return SimStatusEffects.get_damage_dealt_reduction(enemy)

## Check if enemy is immobilized (frozen/rooted)
static func is_immobilized(enemy: Dictionary) -> bool:
    return SimStatusEffects.is_immobilized(enemy)

## Process status effect ticks for all enemies (call during combat tick)
static func tick_status_effects(enemies: Array, delta: float, events: Array[String]) -> void:
    for i in range(enemies.size()):
        var enemy: Dictionary = enemies[i]
        if typeof(enemy) != TYPE_DICTIONARY:
            continue
        var result: Dictionary = SimStatusEffects.tick_effects(enemy, delta)
        var dot_damage: int = int(result.get("damage", 0))
        if dot_damage > 0:
            enemy["hp"] = int(enemy.get("hp", 0)) - dot_damage
            var enemy_id: int = int(enemy.get("id", 0))
            var kind: String = str(enemy.get("kind", "raider"))
            events.append("%s#%d takes %d DoT damage." % [kind, enemy_id, dot_damage])
        enemies[i] = enemy

## Apply damage with status effect modifiers
static func apply_damage_with_effects(enemy: Dictionary, base_dmg: int, state: GameState = null) -> Dictionary:
    # Get damage multiplier from status effects (exposed, frozen vulnerability)
    var damage_mult: float = get_damage_taken_multiplier(enemy)
    var effective_damage: int = int(float(base_dmg) * damage_mult)

    # Apply damage through existing system
    return apply_damage(enemy, effective_damage, state)

## Get status effect summary for an enemy (for UI display)
static func get_status_summary(enemy: Dictionary) -> Array[Dictionary]:
    return SimStatusEffects.get_effect_summary(enemy)


# =============================================================================
# NEW ENEMY TYPE SYSTEM INTEGRATION
# =============================================================================

## Create enemy from new type system (SimEnemyTypes)
static func make_enemy_from_type(state: GameState, type_id: String, pos: Vector2i) -> Dictionary:
    # Get enemy data from new type system
    var type_data: Dictionary = SimEnemyTypes.get_any_enemy(type_id)
    if type_data.is_empty():
        # Fallback to legacy system
        return make_enemy(state, "raider", pos)

    # Scale HP with day progression
    var base_hp: int = int(type_data.get("hp", 3))
    var day_bonus: int = int(state.day / 3)
    var hp: int = base_hp + day_bonus

    var enemy := {
        "id": state.enemy_next_id,
        "kind": type_id,
        "type": type_id,  # New field for type system
        "pos": pos,
        "hp": hp,
        "hp_max": hp,
        "armor": int(type_data.get("armor", 0)),
        "speed": int(type_data.get("speed", 1.0)),
        "damage": int(type_data.get("damage", 1)),
        "gold": int(type_data.get("gold", 1)),
        "tier": int(type_data.get("tier", SimEnemyTypes.Tier.MINION)),
        "category": int(type_data.get("category", SimEnemyTypes.Category.BASIC)),
        "word": "",
        "glyph": str(type_data.get("glyph", "?")),
        "color": type_data.get("color", Color.WHITE)
    }

    # Initialize abilities
    SimEnemyAbilities.init_ability_state(enemy)

    # Assign word and return
    return assign_word(state, enemy)


## Create boss from new boss encounter system
static func make_boss_from_type(state: GameState, boss_id: String, pos: Vector2i) -> Dictionary:
    var boss_data: Dictionary = SimBossEncounters.get_boss(boss_id)
    if boss_data.is_empty():
        # Fallback to legacy boss
        return make_boss(state, "forest_guardian", pos)

    var base_hp: int = int(boss_data.get("hp", 50))
    var hp: int = base_hp + int(state.day / 2)

    var boss := {
        "id": state.enemy_next_id,
        "kind": boss_id,
        "type": boss_id,
        "pos": pos,
        "hp": hp,
        "hp_max": hp,
        "armor": int(boss_data.get("armor", 2)),
        "speed": int(boss_data.get("speed", 0.3) * 2),  # Convert float speed to int
        "damage": int(boss_data.get("damage", 4)),
        "gold": int(boss_data.get("gold", 100)),
        "tier": SimEnemyTypes.Tier.BOSS,
        "is_boss": true,
        "word": "",
        "glyph": str(boss_data.get("glyph", "B")),
        "color": boss_data.get("color", Color.RED)
    }

    # Initialize boss state
    SimBossEncounters.init_boss_state(boss)

    return assign_word(state, boss)


## Choose spawn type using tiered system
static func choose_spawn_type(state: GameState) -> String:
    var available: Array[String] = SimEnemyTypes.get_available_enemies_for_day(state.day)

    if available.is_empty():
        return SimEnemyTypes.TYPHOS_SPAWN

    # Weight selection based on tier
    var tier_weights: Dictionary = {}
    var total_weight: int = 0

    for tier in [SimEnemyTypes.Tier.MINION, SimEnemyTypes.Tier.SOLDIER, SimEnemyTypes.Tier.ELITE, SimEnemyTypes.Tier.CHAMPION]:
        var weight: int = _get_tier_weight_for_day(tier, state.day)
        if weight > 0:
            tier_weights[tier] = weight
            total_weight += weight

    if total_weight == 0:
        tier_weights[SimEnemyTypes.Tier.MINION] = 100
        total_weight = 100

    # Roll for tier
    var roll: int = SimRng.roll_range(state, 1, total_weight)
    var cumulative: int = 0
    var selected_tier: int = SimEnemyTypes.Tier.MINION

    for tier in tier_weights.keys():
        cumulative += int(tier_weights[tier])
        if roll <= cumulative:
            selected_tier = int(tier)
            break

    # Get enemies of selected tier
    var tier_enemies: Array[String] = SimEnemyTypes.get_enemies_by_tier(selected_tier)
    if tier_enemies.is_empty():
        return SimEnemyTypes.TYPHOS_SPAWN

    # Random selection from tier
    var enemy_index: int = SimRng.roll_range(state, 0, tier_enemies.size() - 1)
    return tier_enemies[enemy_index]


static func _get_tier_weight_for_day(tier: int, day: int) -> int:
    match tier:
        SimEnemyTypes.Tier.MINION:
            if day >= 15:
                return 30
            elif day >= 7:
                return 50
            elif day >= 3:
                return 70
            else:
                return 100
        SimEnemyTypes.Tier.SOLDIER:
            if day < 3:
                return 0
            elif day >= 15:
                return 40
            elif day >= 7:
                return 50
            else:
                return 30
        SimEnemyTypes.Tier.ELITE:
            if day < 7:
                return 0
            elif day >= 15:
                return 35
            else:
                return 20
        SimEnemyTypes.Tier.CHAMPION:
            if day < 15:
                return 0
            else:
                return 15
    return 0


## Get enemy glyph from new type system
static func get_type_glyph(type_id: String) -> String:
    # Check new type system first
    if SimEnemyTypes.is_valid(type_id):
        return SimEnemyTypes.get_glyph(type_id)
    # Check boss system
    if SimBossEncounters.is_valid_boss(type_id):
        return str(SimBossEncounters.get_boss(type_id).get("glyph", "B"))
    # Fall back to legacy
    return enemy_glyph(type_id)


## Get enemy color from new type system
static func get_type_color(type_id: String) -> Color:
    if SimEnemyTypes.is_valid(type_id):
        return SimEnemyTypes.get_color(type_id)
    if SimBossEncounters.is_valid_boss(type_id):
        return SimBossEncounters.get_boss(type_id).get("color", Color.RED)
    return Color.WHITE


## Get gold reward from new type system
static func get_type_gold(type_id: String) -> int:
    if SimEnemyTypes.is_valid(type_id):
        return SimEnemyTypes.get_gold(type_id)
    if SimBossEncounters.is_valid_boss(type_id):
        return int(SimBossEncounters.get_boss(type_id).get("gold", 100))
    return gold_reward(type_id)


## Tick abilities for an enemy using new ability system
static func tick_enemy_abilities(enemy: Dictionary, delta: float) -> Array[Dictionary]:
    return SimEnemyAbilities.tick_abilities(enemy, delta)


## Handle ability trigger for an enemy
static func trigger_enemy_ability(enemy: Dictionary, event_type: int, context: Dictionary = {}) -> Array[Dictionary]:
    return SimEnemyAbilities.handle_trigger(enemy, event_type, context)


## Check if enemy is using new type system
static func uses_new_type_system(enemy: Dictionary) -> bool:
    return enemy.has("type") and SimEnemyTypes.is_valid(str(enemy.get("type", "")))


## Get effective stats using new ability system (considers auras, buffs)
static func get_effective_stats_with_abilities(enemy: Dictionary, nearby_enemies: Array) -> Dictionary:
    if not uses_new_type_system(enemy):
        return {
            "armor": int(enemy.get("armor", 0)),
            "speed": int(enemy.get("speed", 1)),
            "damage": int(enemy.get("damage", 1))
        }

    return {
        "armor": SimEnemyAbilities.get_effective_armor(enemy, nearby_enemies),
        "speed": SimEnemyAbilities.get_effective_speed(enemy, nearby_enemies),
        "damage": SimEnemyAbilities.get_effective_damage(enemy, nearby_enemies)
    }


## Apply damage with new ability system checks
static func apply_damage_with_abilities(enemy: Dictionary, dmg: int, state: GameState = null) -> Dictionary:
    if not uses_new_type_system(enemy):
        return apply_damage(enemy, dmg, state)

    # Check dodge
    if SimEnemyAbilities.should_dodge(enemy):
        return enemy  # Dodged

    # Check void armor
    if SimEnemyAbilities.check_void_armor(enemy):
        dmg = 1  # Reduce to 1 damage

    # Check untargetable
    if SimEnemyAbilities.is_untargetable(enemy):
        return enemy  # Can't be damaged

    # Apply normal damage
    return apply_damage(enemy, dmg, state)
