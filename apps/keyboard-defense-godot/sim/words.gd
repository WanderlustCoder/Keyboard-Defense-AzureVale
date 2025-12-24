class_name SimWords
extends RefCounted
const CommandKeywords = preload("res://sim/command_keywords.gd")
static var _reserved_cache: Dictionary = {}

const RESERVED_EXTRA := {}

const SHORT_WORDS: Array[String] = [
    "mist",
    "fern",
    "glow",
    "bolt",
    "rift",
    "lark",
    "reed",
    "moth",
    "brim",
    "palm",
    "rust",
    "quill"
]

const MEDIUM_WORDS: Array[String] = [
    "harvest",
    "harbor",
    "citron",
    "amber",
    "copper",
    "stone",
    "forest",
    "meadow",
    "candle",
    "shield",
    "vector",
    "echoes",
    "market",
    "bridge"
]

const LONG_WORDS: Array[String] = [
    "sentinel",
    "fortress",
    "vanguard",
    "monolith",
    "stronghold",
    "cathedral",
    "archivist",
    "lighthouse",
    "riverstone",
    "everglade",
    "moonlight",
    "wildgrowth"
]

static func word_for_enemy(seed: String, day: int, kind: String, enemy_id: int, already_used: Dictionary) -> String:
    var list: Array[String] = _list_for_kind(kind)
    if list.is_empty():
        return "foe%d" % enemy_id
    var key: String = "%s|%d|%s|%d" % [seed, day, kind, enemy_id]
    var hash_value: int = key.hash()
    if hash_value == -9223372036854775808:
        hash_value = 0
    var index: int = abs(hash_value) % list.size()
    for _i in range(list.size()):
        var word: String = str(list[index]).to_lower()
        if not _reserved_words().has(word) and not already_used.has(word):
            return word
        index = (index + 1) % list.size()
    return "foe%d" % enemy_id

static func _list_for_kind(kind: String) -> Array[String]:
    match kind:
        "scout":
            return SHORT_WORDS
        "armored":
            return LONG_WORDS
        _:
            return MEDIUM_WORDS

static func _reserved_words() -> Dictionary:
    if _reserved_cache.is_empty():
        for keyword in CommandKeywords.KEYWORDS:
            _reserved_cache[str(keyword).to_lower()] = true
        for word in RESERVED_EXTRA.keys():
            _reserved_cache[str(word).to_lower()] = true
    return _reserved_cache
