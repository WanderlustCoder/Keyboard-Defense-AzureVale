class_name SimEnemies
extends RefCounted

const GameState = preload("res://sim/types.gd")
const SimRng = preload("res://sim/rng.gd")
const SimWords = preload("res://sim/words.gd")

const ENEMY_KINDS := {
    "raider": {"speed": 1, "armor": 0, "hp_bonus": 0, "glyph": "r"},
    "scout": {"speed": 2, "armor": 0, "hp_bonus": -1, "glyph": "s"},
    "armored": {"speed": 1, "armor": 1, "hp_bonus": 1, "glyph": "a"}
}

static func make_enemy(state: GameState, kind: String, pos: Vector2i) -> Dictionary:
    var config: Dictionary = ENEMY_KINDS.get(kind, ENEMY_KINDS["raider"])
    var base_hp: int = 2 + int(state.day / 3) + int(state.threat / 4)
    var hp: int = max(1, base_hp + int(config.get("hp_bonus", 0)))
    var enemy := {
        "id": state.enemy_next_id,
        "kind": kind,
        "pos": pos,
        "hp": hp,
        "armor": int(config.get("armor", 0)),
        "speed": int(config.get("speed", 1)),
        "word": ""
    }
    return assign_word(state, enemy)

static func apply_damage(enemy: Dictionary, dmg: int) -> Dictionary:
    var armor: int = int(enemy.get("armor", 0))
    var effective: int = max(0, dmg - armor)
    enemy["hp"] = int(enemy.get("hp", 0)) - effective
    return enemy

static func enemy_glyph(kind: String) -> String:
    return str(ENEMY_KINDS.get(kind, ENEMY_KINDS["raider"]).get("glyph", "r"))

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
    var word: String = SimWords.word_for_enemy(state.rng_seed, state.day, kind, enemy_id, used)
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
            var assigned: String = SimWords.word_for_enemy(state.rng_seed, state.day, kind, enemy_id, used)
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
    if state.day >= 5 or state.threat >= 4:
        kinds.append("armored")

    var weights: Dictionary = {}
    weights["raider"] = 6
    weights["scout"] = 2 + int(state.day / 3)
    weights["armored"] = max(0, int(state.day / 2) - 1)

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
    return {
        "id": int(enemy.get("id", 0)),
        "pos": {"x": pos.x, "y": pos.y},
        "hp": int(enemy.get("hp", 0)),
        "kind": str(enemy.get("kind", "raider")),
        "armor": int(enemy.get("armor", 0)),
        "speed": int(enemy.get("speed", 1)),
        "word": str(enemy.get("word", ""))
    }

static func deserialize(raw: Dictionary) -> Dictionary:
    var pos_data: Dictionary = raw.get("pos", {})
    var pos: Vector2i = Vector2i(int(pos_data.get("x", 0)), int(pos_data.get("y", 0)))
    return {
        "id": int(raw.get("id", 0)),
        "pos": pos,
        "hp": int(raw.get("hp", 0)),
        "kind": str(raw.get("kind", "raider")),
        "armor": int(raw.get("armor", 0)),
        "speed": int(raw.get("speed", 1)),
        "word": str(raw.get("word", ""))
    }

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
