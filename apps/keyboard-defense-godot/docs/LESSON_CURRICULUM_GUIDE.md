# Lesson & Curriculum Guide

This document explains the typing lesson system, word generation, and graduation paths in Keyboard Defense. The curriculum is designed to progressively teach touch typing while providing engaging combat.

## Overview

Lessons determine what words enemies carry. Each lesson defines:
- **Character set** or **word list** for word generation
- **Length ranges** per enemy type (scout, raider, armored)
- **Mode** (charset, wordlist, or sentence)
- **Graduation path** progression

```
Player selects lesson → Enemies spawn with lesson-appropriate words
                           ↓
                     Word length matches enemy type
                           ↓
                     Player types words to deal damage
                           ↓
                     Completion unlocks next stage
```

## Lesson Modes

### Charset Mode (`mode: "charset"`)

Generates random words from a character set:

```gdscript
# sim/words.gd:105
static func _make_word(base_key: String, charset: String, min_len: int, max_len: int, attempt: int) -> String:
    if charset == "":
        return ""
    var span: int = max(1, max_len - min_len + 1)
    var length: int = min_len + _hash_index("%s|len|%d" % [base_key, attempt], span)
    var parts: Array[String] = []
    for i in range(length):
        var idx: int = _hash_index("%s|%d|%d" % [base_key, attempt, i], charset.length())
        parts.append(charset.substr(idx, 1))
    return "".join(parts)
```

Example lesson:
```json
{
  "id": "home_row_1",
  "name": "Home Row Basics",
  "description": "ASDF GH JKL; focused practice.",
  "mode": "charset",
  "charset": "asdfghjkl;",
  "lengths": { "scout": [3, 4], "raider": [4, 6], "armored": [6, 8] }
}
```

### Wordlist Mode (`mode: "wordlist"`)

Uses predefined real words filtered by length:

```gdscript
# sim/words.gd:154
static func _word_from_wordlist(seed: String, day: int, kind: String, enemy_id: int, lesson: Dictionary, already_used: Dictionary) -> String:
    var wordlist: Array = lesson.get("wordlist", [])
    if wordlist.is_empty():
        return ""

    # Filter by length based on enemy kind
    var lengths: Dictionary = lesson.get("lengths", {})
    var range_value: Variant = lengths.get(kind, [3, 6])
    var min_len: int = 3
    var max_len: int = 6
    if range_value is Array and range_value.size() >= 2:
        min_len = int(range_value[0])
        max_len = int(range_value[1])

    # Build filtered list
    var filtered: Array = []
    for word in wordlist:
        var w: String = str(word)
        if w.length() >= min_len and w.length() <= max_len:
            filtered.append(w)
```

Example lesson:
```json
{
  "id": "home_row_words",
  "name": "Home Row Words",
  "mode": "wordlist",
  "wordlist": ["ad", "ah", "as", "dad", "fad", "gag", "gal", "gas", "had", "hag", "salad", "flask"],
  "lengths": { "scout": [3, 4], "raider": [4, 6], "armored": [6, 8] }
}
```

### Sentence Mode (`mode: "sentence"`)

Uses full sentences for advanced practice:

```gdscript
# sim/words.gd:189
static func _sentence_from_lesson(seed: String, day: int, enemy_id: int, lesson: Dictionary, already_used: Dictionary) -> String:
    var sentences: Array = lesson.get("sentences", [])
    if sentences.is_empty():
        return ""

    var key: String = "%s|%d|%d" % [seed, day, enemy_id]
    var index: int = _hash_index(key, sentences.size())
    for _i in range(sentences.size()):
        var sentence: String = str(sentences[index])
        var check_key: String = sentence.to_lower()
        if not already_used.has(check_key):
            return sentence
        index = (index + 1) % sentences.size()
    return str(sentences[_hash_index(key, sentences.size())])
```

Example lesson:
```json
{
  "id": "sentence_basics",
  "name": "Simple Sentences",
  "mode": "sentence",
  "sentences": [
    "The cat sat.",
    "I can run.",
    "She is here.",
    "We go home."
  ]
}
```

## Length Ranges by Enemy Type

Word length scales with enemy difficulty:

| Enemy Kind | Default Range | Purpose |
|------------|---------------|---------|
| Scout | 3-4 chars | Quick, easy kills |
| Raider | 4-6 chars | Standard challenge |
| Armored | 6-8 chars | Tougher targets |

```gdscript
# sim/lessons.gd:145
static func _normalize_lengths(raw: Variant) -> Dictionary:
    var defaults := {
        "scout": [3, 4],
        "raider": [4, 6],
        "armored": [6, 8]
    }
    # ... applies lesson-specific overrides
```

### Length Scaling Examples

| Lesson | Scout | Raider | Armored |
|--------|-------|--------|---------|
| home_row_1 | 3-4 | 4-6 | 6-8 |
| gauntlet_speed | 2-3 | 3-4 | 4-5 |
| gauntlet_endurance | 6-8 | 8-10 | 10-14 |
| code_master | 5-7 | 7-10 | 10-14 |

## Graduation Paths

Players progress through structured learning paths:

```json
"graduation_paths": {
  "beginner": {
    "name": "Beginner Path",
    "description": "Learn touch typing from scratch",
    "stages": [
      {
        "stage": 1,
        "name": "Home Row Fundamentals",
        "lessons": ["home_row_1", "home_row_2", "home_row_words"],
        "goal": "Master the home row position"
      }
    ]
  }
}
```

### Available Paths

| Path | Target Audience | Stages |
|------|-----------------|--------|
| **Beginner** | New typists | Home row → Reach row → Bottom row → Full alpha → Sentences |
| **Intermediate** | Improving typists | Word mastery → Patterns → Sentence fluency → Themed content |
| **Advanced** | Skilled typists | Numbers/symbols → Precision → Speed → Advanced sentences → Legendary |
| **Coding** | Programmers | Variables → Syntax → Code mastery |

### Beginner Path Progression

```
Stage 1: Home Row Fundamentals
├── home_row_1 (ASDF GH JKL;)
├── home_row_2 (Extended home row)
└── home_row_words (Real words: dad, gal, salad)

Stage 2: Reach Row Addition
├── reach_row_1 (Add E, R, T, Y, U)
├── reach_row_2 (Full reach + home)
└── reach_row_words (Real words: the, there, year)

Stage 3: Bottom Row
├── bottom_row_1 (Z, X, C, V)
├── bottom_row_2 (Full B, N, M)
└── bottom_row_words (Real words: box, zone, banana)

Stage 4: Full Alphabet
├── full_alpha (A-Z general practice)
├── full_alpha_words (Common English)
└── common_words (Frequently used)

Stage 5: Simple Sentences
├── sentence_basics (Short sentences)
├── sentence_home_row (Home row focused)
└── sentence_common (Everyday phrases)
```

## Word Generation Flow

### Main Entry Point

```gdscript
# sim/words.gd:55
static func word_for_enemy(seed: String, day: int, kind: String, enemy_id: int, already_used: Dictionary, lesson_id: String = "") -> String:
    var resolved_lesson: String = SimLessons.normalize_lesson_id(lesson_id)
    var lesson: Dictionary = SimLessons.get_lesson(resolved_lesson)
    if lesson.is_empty():
        return _fallback_word(seed, day, kind, enemy_id, already_used)

    var mode: String = str(lesson.get("mode", "charset"))
    match mode:
        "wordlist":
            var word: String = _word_from_wordlist(seed, day, kind, enemy_id, lesson, already_used)
            if word != "":
                return word
        "sentence":
            var sentence: String = _sentence_from_lesson(seed, day, enemy_id, lesson, already_used)
            if sentence != "":
                return sentence
        "charset", _:
            var lesson_word: String = _word_from_lesson(seed, day, kind, enemy_id, resolved_lesson, lesson, already_used)
            if lesson_word != "":
                return lesson_word
    return _fallback_word(seed, day, kind, enemy_id, already_used)
```

### Uniqueness Guarantee

Words are never duplicated within a wave:

```gdscript
# In enemy spawning
var already_used: Dictionary = {}
for enemy in enemies_to_spawn:
    var word = SimWords.word_for_enemy(seed, day, kind, enemy_id, already_used, lesson_id)
    already_used[word] = true
    enemy["word"] = word
```

### Reserved Words

Command keywords are excluded from word generation:

```gdscript
# sim/words.gd:146
static func _reserved_words() -> Dictionary:
    if _reserved_cache.is_empty():
        for keyword in CommandKeywords.KEYWORDS:
            _reserved_cache[str(keyword).to_lower()] = true
    return _reserved_cache
```

This prevents conflicts like typing "build" to attack an enemy vs. issuing the build command.

## Fallback Word Lists

When lessons can't generate unique words, fallbacks are used:

```gdscript
# sim/words.gd
const SHORT_WORDS: Array[String] = [
    "mist", "fern", "glow", "bolt", "rift", "lark", "reed", "moth"
]

const MEDIUM_WORDS: Array[String] = [
    "harvest", "harbor", "citron", "amber", "copper", "stone", "forest"
]

const LONG_WORDS: Array[String] = [
    "sentinel", "fortress", "vanguard", "monolith", "stronghold", "cathedral"
]
```

## Lesson Categories

### Keyboard Region Lessons

| Category | Lessons | Keys Covered |
|----------|---------|--------------|
| Home Row | home_row_1, home_row_2, home_row_words | ASDFGHJKL; |
| Reach Row | reach_row_1, reach_row_2, reach_row_words | ERTYU + home |
| Bottom Row | bottom_row_1, bottom_row_2, bottom_row_words | ZXCVBNM |
| Full Alpha | full_alpha, full_alpha_words | A-Z |

### Skill-Based Lessons

| Category | Focus | Examples |
|----------|-------|----------|
| Precision | Accuracy training | precision_bronze, precision_silver, precision_gold |
| Speed | Fast typing | gauntlet_speed, time_trial_sprint |
| Endurance | Long words | gauntlet_endurance, time_trial_marathon |
| Pattern | Typing flow | double_letters, rhythm_words, alternating_hands |

### Specialized Lessons

| Category | Purpose | Examples |
|----------|---------|----------|
| Weak Fingers | Pinky/ring training | weak_fingers, pinky_power, ring_finger_focus |
| Programming | Code syntax | code_variables, code_keywords, code_syntax |
| Numbers | Number row | numbers_1, numbers_2 |
| Symbols | Special characters | symbols_1, symbols_2, punctuation_1 |

### Themed Lessons (Biomes)

| Biome | Theme | Example Words |
|-------|-------|---------------|
| Evergrove | Forest | forest, grove, tree, oak, canopy |
| Stonepass | Mountain | peak, summit, granite, avalanche |
| Mistfen | Swamp | marsh, bog, mist, frog, heron |
| Sunfields | Plains | field, wheat, harvest, horizon |

## Adding New Lessons

### Step 1: Add to lessons.json

```json
{
  "id": "new_lesson",
  "name": "New Lesson Name",
  "description": "What this lesson teaches.",
  "mode": "charset",
  "charset": "abcdefghijklmnopqrstuvwxyz",
  "lengths": { "scout": [3, 4], "raider": [4, 6], "armored": [6, 8] }
}
```

### Step 2: Add to Graduation Path (Optional)

```json
{
  "stage": 3,
  "name": "New Stage",
  "lessons": ["existing_lesson", "new_lesson"],
  "goal": "Master this new skill"
}
```

### Lesson Structure Reference

```gdscript
# sim/lessons.gd:100
var lesson := {
    "id": id,                    # Unique identifier
    "name": name,                # Display name
    "description": description,  # Help text
    "mode": mode,                # "charset", "wordlist", or "sentence"
    "charset": charset,          # For charset mode
    "lengths": lengths,          # {scout: [min, max], raider: [...], armored: [...]}
    "wordlist": wordlist,        # For wordlist mode
    "sentences": sentences       # For sentence mode
}
```

## Lesson Difficulty Scaling

### By Character Set Complexity

| Complexity | Keys | Example |
|------------|------|---------|
| Basic | 4 keys | training_basics (asdf) |
| Home Row | 10 keys | home_row_1 (asdfghjkl;) |
| Half Alpha | 15-20 keys | reach_row_2 |
| Full Alpha | 26 keys | full_alpha |
| Alphanumeric | 36 keys | numbers_2 |
| Full Keyboard | 50+ keys | gauntlet_chaos |

### By Word Length

| Difficulty | Scout | Raider | Armored |
|------------|-------|--------|---------|
| Easy | 2-3 | 3-4 | 4-5 |
| Normal | 3-4 | 4-6 | 6-8 |
| Hard | 4-5 | 5-7 | 7-9 |
| Expert | 5-7 | 7-9 | 9-12 |
| Legendary | 7-9 | 9-12 | 12-16 |

## Common Patterns

### Get Current Lesson Info

```gdscript
var lesson_id = state.lesson_id
var lesson = SimLessons.get_lesson(lesson_id)
var name = SimLessons.lesson_label(lesson_id)
var description = SimLessons.lesson_description(lesson_id)
```

### Validate Lesson ID

```gdscript
if SimLessons.is_valid(user_input):
    state.lesson_id = user_input
else:
    events.append("Invalid lesson: %s" % user_input)
```

### Generate Word for Enemy

```gdscript
var word = SimWords.word_for_enemy(
    state.seed,
    state.day,
    enemy_kind,      # "scout", "raider", or "armored"
    enemy_id,
    already_used,    # Dictionary of used words
    state.lesson_id
)
enemy["word"] = word
already_used[word] = true
```

### List All Available Lessons

```gdscript
var all_lessons = SimLessons.lesson_ids()
for lesson_id in all_lessons:
    var label = SimLessons.lesson_label(lesson_id)
    print("%s: %s" % [lesson_id, label])
```

## Integration with Combat

### Word-Enemy Binding

When enemies spawn, words are assigned based on the active lesson:

```
Enemy spawns → word_for_enemy() called
                    ↓
            Lesson determines character set
                    ↓
            Enemy kind determines length
                    ↓
            Uniqueness check against wave
                    ↓
            Word assigned to enemy["word"]
```

### Typing Feedback

The lesson affects typing feedback quality:

| Lesson Type | Feedback Style |
|-------------|----------------|
| Charset | Random strings may lack rhythm |
| Wordlist | Real words feel natural |
| Sentence | Punctuation and spacing |

## Testing Lessons

### Verify Lesson Loads

```gdscript
func test_lesson_loads():
    var data = SimLessons.load_data()
    assert(data.ok, "Lessons should load successfully")
    assert(data.data.lessons.size() > 0, "Should have lessons")
    _pass("test_lesson_loads")
```

### Verify Word Generation

```gdscript
func test_word_generation():
    var used = {}
    for i in range(10):
        var word = SimWords.word_for_enemy("test", 1, "raider", i, used, "home_row_1")
        assert(word != "", "Should generate word")
        # Verify only home row characters
        for ch in word:
            assert("asdfghjkl;".contains(ch), "Should use only home row: " + ch)
        used[word] = true
    _pass("test_word_generation")
```

### Verify No Reserved Conflicts

```gdscript
func test_no_reserved_words():
    var used = {}
    for i in range(100):
        var word = SimWords.word_for_enemy("test", 1, "scout", i, used, "full_alpha")
        assert(not CommandKeywords.KEYWORDS.has(word.to_upper()), "Should not be command")
        used[word] = true
    _pass("test_no_reserved_words")
```

## Sentence Mode Considerations

### Preserving Case

Sentences maintain original case for display but use lowercase for uniqueness:

```gdscript
# Check lowercase for uniqueness
var check_key: String = sentence.to_lower()
if not already_used.has(check_key):
    return sentence  # Return original case
```

### Sentence Length

Unlike charset/wordlist, sentences don't filter by enemy kind length. All enemies use sentences of original length.

### Punctuation Handling

Sentences may include:
- Periods, commas, question marks
- Quotation marks and apostrophes
- Spaces between words

The typing system handles these appropriately for match detection.
