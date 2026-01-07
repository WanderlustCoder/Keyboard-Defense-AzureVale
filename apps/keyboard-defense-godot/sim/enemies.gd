class_name SimEnemies
extends RefCounted

const GameState = preload("res://sim/types.gd")
const SimRng = preload("res://sim/rng.gd")
const SimWords = preload("res://sim/words.gd")

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
    if state.day >= 8:
        affixes.append("splitting")
    if state.day >= 9:
        affixes.append("regenerating")
    if state.day >= 10:
        affixes.append("enraged")
        affixes.append("vampiric")
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
        "elite": 6
    }
    return int(rewards.get(kind, 2))

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
