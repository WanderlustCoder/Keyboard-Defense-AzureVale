# Word Pack Specification

**Created:** 2026-01-08

This document specifies word pack content, themed vocabularies, and word generation rules for the typing curriculum.

## Word Pack Architecture

### Pack Types

1. **Charset Packs** - Generate random words from character set
2. **Wordlist Packs** - Use curated word lists
3. **Hybrid Packs** - Combine charset generation with wordlist sampling

### Word Length Categories

| Category | Scout | Raider | Armored | Use Case |
|----------|-------|--------|---------|----------|
| Short | 2-3 | 3-4 | 4-5 | Speed drills, beginners |
| Standard | 3-4 | 4-6 | 6-8 | Core curriculum |
| Medium | 4-5 | 5-7 | 7-9 | Intermediate |
| Long | 5-7 | 7-9 | 9-12 | Advanced, endurance |
| Extended | 6-8 | 8-11 | 11-15 | Expert, legendary |

## Themed Word Packs

### Fantasy Kingdom Vocabulary

#### Castle & Fortifications
```json
{
  "id": "wordpack_castle",
  "name": "Castle Words",
  "theme": "fortifications",
  "words": [
    "castle", "tower", "wall", "gate", "moat", "drawbridge", "keep",
    "rampart", "battlement", "parapet", "turret", "dungeon", "throne",
    "hall", "chamber", "vault", "armory", "barracks", "stable", "forge",
    "portcullis", "arrow slit", "murder hole", "bailey", "curtain wall",
    "gatehouse", "barbican", "citadel", "fortress", "stronghold"
  ]
}
```

#### Military & Combat
```json
{
  "id": "wordpack_combat",
  "name": "Combat Words",
  "theme": "military",
  "words": [
    "sword", "shield", "armor", "helm", "lance", "bow", "arrow",
    "spear", "axe", "mace", "dagger", "crossbow", "catapult", "siege",
    "battle", "war", "army", "soldier", "knight", "guard", "scout",
    "archer", "cavalry", "infantry", "flank", "charge", "retreat",
    "victory", "defeat", "conquest", "defend", "attack", "ambush"
  ]
}
```

#### Magic & Spells
```json
{
  "id": "wordpack_magic",
  "name": "Magic Words",
  "theme": "arcane",
  "words": [
    "magic", "spell", "wizard", "mage", "sorcerer", "enchant", "curse",
    "hex", "charm", "potion", "elixir", "wand", "staff", "orb", "tome",
    "scroll", "rune", "glyph", "sigil", "aura", "mana", "arcane",
    "mystic", "occult", "ritual", "summon", "conjure", "invoke", "dispel",
    "ward", "barrier", "shield", "blast", "bolt", "beam", "wave"
  ]
}
```

#### Creatures & Enemies
```json
{
  "id": "wordpack_creatures",
  "name": "Creature Words",
  "theme": "monsters",
  "words": [
    "dragon", "ogre", "troll", "goblin", "orc", "demon", "ghost",
    "specter", "wraith", "skeleton", "zombie", "vampire", "werewolf",
    "giant", "titan", "hydra", "basilisk", "griffin", "phoenix",
    "elemental", "golem", "imp", "sprite", "fairy", "elf", "dwarf",
    "serpent", "wyrm", "drake", "wyvern", "chimera", "manticore"
  ]
}
```

#### Resources & Economy
```json
{
  "id": "wordpack_resources",
  "name": "Resource Words",
  "theme": "economy",
  "words": [
    "gold", "silver", "copper", "iron", "steel", "wood", "stone",
    "food", "grain", "wheat", "corn", "meat", "fish", "fruit",
    "lumber", "timber", "ore", "gem", "crystal", "diamond", "ruby",
    "emerald", "sapphire", "pearl", "coal", "oil", "cloth", "silk",
    "leather", "fur", "wool", "cotton", "linen", "rope", "chain"
  ]
}
```

#### Nature & Environment
```json
{
  "id": "wordpack_nature",
  "name": "Nature Words",
  "theme": "environment",
  "words": [
    "forest", "mountain", "river", "lake", "ocean", "desert", "swamp",
    "meadow", "valley", "hill", "cliff", "cave", "canyon", "volcano",
    "glacier", "tundra", "jungle", "savanna", "marsh", "bog", "fen",
    "grove", "glade", "thicket", "clearing", "waterfall", "spring",
    "stream", "creek", "pond", "beach", "shore", "island", "peninsula"
  ]
}
```

### Biome-Specific Vocabularies

#### Evergrove (Forest)
```json
{
  "id": "wordpack_evergrove",
  "name": "Evergrove Vocabulary",
  "theme": "forest_biome",
  "difficulty": "intermediate",
  "words": [
    "oak", "pine", "maple", "birch", "willow", "cedar", "spruce",
    "acorn", "pinecone", "bark", "branch", "leaf", "root", "moss",
    "fern", "mushroom", "berry", "nut", "sap", "resin", "timber",
    "canopy", "undergrowth", "thicket", "clearing", "path", "trail",
    "deer", "wolf", "bear", "fox", "owl", "hawk", "squirrel", "rabbit",
    "woodsman", "ranger", "druid", "treant", "dryad", "sprite"
  ]
}
```

#### Stonepass (Mountains)
```json
{
  "id": "wordpack_stonepass",
  "name": "Stonepass Vocabulary",
  "theme": "mountain_biome",
  "difficulty": "intermediate",
  "words": [
    "peak", "summit", "ridge", "cliff", "crag", "ledge", "slope",
    "boulder", "rock", "stone", "gravel", "scree", "granite", "slate",
    "cave", "cavern", "tunnel", "mine", "shaft", "vein", "ore",
    "crystal", "gem", "iron", "copper", "silver", "gold", "coal",
    "eagle", "goat", "ram", "yeti", "troll", "giant", "dwarf",
    "avalanche", "rockslide", "echo", "wind", "snow", "ice", "frost"
  ]
}
```

#### Mistfen (Swamps)
```json
{
  "id": "wordpack_mistfen",
  "name": "Mistfen Vocabulary",
  "theme": "swamp_biome",
  "difficulty": "intermediate",
  "words": [
    "swamp", "marsh", "bog", "fen", "mire", "quagmire", "morass",
    "muck", "mud", "silt", "peat", "moss", "algae", "lichen",
    "reed", "cattail", "lily", "lotus", "mangrove", "cypress", "willow",
    "frog", "toad", "newt", "snake", "turtle", "alligator", "heron",
    "mist", "fog", "haze", "vapor", "damp", "humid", "murky",
    "witch", "hag", "specter", "wisp", "wraith", "shade", "phantom"
  ]
}
```

#### Sunfields (Plains)
```json
{
  "id": "wordpack_sunfields",
  "name": "Sunfields Vocabulary",
  "theme": "plains_biome",
  "difficulty": "beginner",
  "words": [
    "field", "plain", "prairie", "meadow", "pasture", "grassland",
    "wheat", "corn", "barley", "oat", "rye", "hay", "straw", "grain",
    "farm", "barn", "mill", "silo", "plow", "harvest", "crop", "seed",
    "horse", "cow", "sheep", "pig", "chicken", "goose", "dog", "cat",
    "sun", "sky", "cloud", "wind", "rain", "dew", "dawn", "dusk",
    "farmer", "shepherd", "miller", "baker", "merchant", "traveler"
  ]
}
```

### Programming Vocabularies

#### Variables & Identifiers
```json
{
  "id": "wordpack_code_vars",
  "name": "Variable Names",
  "theme": "programming",
  "difficulty": "intermediate",
  "words": [
    "user", "name", "data", "value", "count", "index", "item",
    "list", "array", "map", "set", "node", "tree", "graph",
    "input", "output", "result", "error", "status", "state",
    "config", "option", "setting", "param", "arg", "flag",
    "max", "min", "sum", "avg", "len", "size", "key", "val",
    "temp", "curr", "prev", "next", "first", "last", "head", "tail"
  ],
  "patterns": [
    "user_name", "first_name", "last_name", "user_id", "item_count",
    "max_value", "min_size", "total_sum", "is_valid", "has_data",
    "get_user", "set_name", "add_item", "del_node", "run_test"
  ]
}
```

#### Keywords
```json
{
  "id": "wordpack_code_keywords",
  "name": "Code Keywords",
  "theme": "programming",
  "difficulty": "intermediate",
  "words": [
    "if", "else", "elif", "for", "while", "do", "switch", "case",
    "break", "continue", "return", "yield", "pass", "raise", "try",
    "catch", "except", "finally", "throw", "async", "await", "with",
    "import", "from", "export", "class", "struct", "enum", "interface",
    "func", "def", "var", "let", "const", "static", "public", "private",
    "true", "false", "null", "none", "nil", "void", "int", "float",
    "string", "bool", "list", "dict", "array", "map", "set", "tuple"
  ]
}
```

### Common English Word Packs

#### High Frequency (Top 100)
```json
{
  "id": "wordpack_common_100",
  "name": "Most Common Words",
  "theme": "english",
  "difficulty": "beginner",
  "words": [
    "the", "be", "to", "of", "and", "a", "in", "that", "have", "I",
    "it", "for", "not", "on", "with", "he", "as", "you", "do", "at",
    "this", "but", "his", "by", "from", "they", "we", "say", "her", "she",
    "or", "an", "will", "my", "one", "all", "would", "there", "their", "what",
    "so", "up", "out", "if", "about", "who", "get", "which", "go", "me",
    "when", "make", "can", "like", "time", "no", "just", "him", "know", "take",
    "people", "into", "year", "your", "good", "some", "could", "them", "see", "other",
    "than", "then", "now", "look", "only", "come", "its", "over", "think", "also",
    "back", "after", "use", "two", "how", "our", "work", "first", "well", "way",
    "even", "new", "want", "because", "any", "these", "give", "day", "most", "us"
  ]
}
```

#### Academic Vocabulary
```json
{
  "id": "wordpack_academic",
  "name": "Academic Words",
  "theme": "english",
  "difficulty": "advanced",
  "words": [
    "analyze", "approach", "area", "assess", "assume", "authority",
    "available", "benefit", "concept", "consistent", "constitute",
    "context", "contract", "create", "data", "define", "derive",
    "distribute", "economy", "environment", "establish", "estimate",
    "evident", "export", "factor", "finance", "formula", "function",
    "identify", "income", "indicate", "individual", "interpret",
    "involve", "issue", "labor", "legal", "legislate", "major",
    "method", "occur", "percent", "period", "policy", "principle",
    "proceed", "process", "require", "research", "respond", "role",
    "section", "sector", "significant", "similar", "source", "specific",
    "structure", "theory", "vary"
  ]
}
```

## Word Generation Rules

### Charset Word Generation

```gdscript
# Generate random word from charset
func generate_word(charset: String, min_len: int, max_len: int) -> String:
    var length = randi_range(min_len, max_len)
    var word = ""
    for i in range(length):
        word += charset[randi() % charset.length()]
    return word
```

### Pronounceable Word Generation

For charset-based lessons, generate pronounceable combinations:

```gdscript
const VOWELS = "aeiou"
const CONSONANTS = "bcdfghjklmnpqrstvwxyz"

func generate_pronounceable(charset: String, length: int) -> String:
    var word = ""
    var last_was_vowel = randf() > 0.5

    for i in range(length):
        var pool = ""
        if last_was_vowel:
            for c in charset:
                if c in CONSONANTS:
                    pool += c
        else:
            for c in charset:
                if c in VOWELS:
                    pool += c

        if pool.is_empty():
            pool = charset

        word += pool[randi() % pool.length()]
        last_was_vowel = word[-1] in VOWELS

    return word
```

### Wordlist Sampling Rules

1. **No Immediate Repeats** - Don't show same word twice in a row
2. **Frequency Weighting** - Common words appear more often in beginner lessons
3. **Length Filtering** - Only use words within length range for enemy type
4. **Difficulty Scaling** - Longer/harder words for armored enemies

## Word Pack Integration

### Lesson-to-Wordpack Mapping

| Lesson Category | Primary Pack | Secondary Pack |
|-----------------|--------------|----------------|
| home_row_* | charset | common_100 |
| reach_row_* | charset | castle, combat |
| bottom_row_* | charset | nature |
| biome_evergrove | wordpack_evergrove | nature |
| biome_stonepass | wordpack_stonepass | resources |
| biome_mistfen | wordpack_mistfen | creatures |
| biome_sunfields | wordpack_sunfields | common_100 |
| code_* | wordpack_code_vars | wordpack_code_keywords |
| boss_* | mixed themed | all packs |

### Word Difficulty Scoring

```gdscript
func score_word_difficulty(word: String) -> float:
    var score = 0.0

    # Length factor
    score += word.length() * 0.1

    # Uncommon letter penalty
    var uncommon = "qzxjkv"
    for c in word:
        if c in uncommon:
            score += 0.2

    # Double letter bonus (easier)
    for i in range(word.length() - 1):
        if word[i] == word[i + 1]:
            score -= 0.1

    # Alternating hands bonus (easier)
    # ... calculation based on finger map

    return clamp(score, 0.0, 1.0)
```

## Implementation Checklist

### Data Files
- [ ] Create `data/wordpacks/fantasy.json` with themed vocabularies
- [ ] Create `data/wordpacks/biomes.json` with biome words
- [ ] Create `data/wordpacks/coding.json` with programming words
- [ ] Create `data/wordpacks/common.json` with English frequency lists
- [ ] Add wordpack references to lessons.json

### Code Changes
- [ ] Add wordpack loader to sim/words.gd
- [ ] Implement pronounceable word generator
- [ ] Add difficulty scoring function
- [ ] Support hybrid charset + wordlist lessons

### Validation
- [ ] Verify all words are typeable with lesson charset
- [ ] Check word lengths match enemy type ranges
- [ ] Validate no profanity or inappropriate words
- [ ] Test word distribution fairness

## References

- `data/lessons.json` - Lesson definitions with charsets
- `sim/words.gd` - Word generation logic
- `docs/plans/p1/LESSON_GUIDE_PLAN.md` - Lesson structure
