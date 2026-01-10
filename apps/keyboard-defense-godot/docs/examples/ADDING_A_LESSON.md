# Implementation Example: Adding a New Lesson

This walkthrough shows every file you need to touch when adding a new typing lesson to Keyboard Defense.

## Example: Adding a "Programming Keywords" Lesson

A lesson focused on common programming terms like `function`, `return`, `class`, etc.

---

## Step 1: Add to `data/lessons.json`

Add the lesson definition. There are three modes: `charset`, `wordlist`, and `sentence`.

### Wordlist Mode (for this example)

```json
{
  "version": 2,
  "default_lesson": "full_alpha",
  "lessons": [
    // ... existing lessons ...
    {
      "id": "programming_keywords",
      "name": "Programming Keywords",
      "description": "Common programming terms and syntax.",
      "mode": "wordlist",
      "wordlist": [
        "function", "return", "class", "const", "var",
        "import", "export", "async", "await", "yield",
        "static", "public", "private", "void", "null",
        "true", "false", "break", "continue", "throw",
        "catch", "finally", "extends", "implements", "interface",
        "array", "string", "boolean", "integer", "float",
        "object", "method", "property", "constructor", "prototype"
      ],
      "lengths": {
        "scout": [3, 5],
        "raider": [5, 8],
        "armored": [8, 12]
      }
    }
  ]
}
```

### Charset Mode (for character practice)

```json
{
  "id": "special_chars",
  "name": "Special Characters",
  "description": "Practice brackets, symbols, and punctuation.",
  "mode": "charset",
  "charset": "[]{}()<>,.;:'\"!@#$%^&*-+=",
  "lengths": {
    "scout": [2, 3],
    "raider": [3, 5],
    "armored": [5, 8]
  }
}
```

### Sentence Mode (for full sentences)

```json
{
  "id": "sentence_programming",
  "name": "Code Comments",
  "description": "Practice typing code-style comments.",
  "mode": "sentence",
  "sentences": [
    "This function returns the sum of two numbers.",
    "Initialize the array with default values.",
    "Check if the user input is valid before processing.",
    "Loop through each element in the collection.",
    "Handle the error gracefully and log the message."
  ]
}
```

**Length ranges** determine word length for each enemy type:
- `scout`: Fast enemies get short words
- `raider`: Normal enemies get medium words
- `armored`: Tough enemies get long words

## Step 2: Add to Graduation Path (Optional)

If the lesson is part of a learning progression:

```json
{
  "graduation_paths": {
    "programming": {
      "name": "Programming Path",
      "description": "Learn to type code fluently",
      "stages": [
        {
          "stage": 1,
          "name": "Basic Keywords",
          "lessons": ["programming_keywords"],
          "goal": "Type common keywords quickly"
        },
        {
          "stage": 2,
          "name": "Special Characters",
          "lessons": ["special_chars", "brackets"],
          "goal": "Master symbols and punctuation"
        },
        {
          "stage": 3,
          "name": "Code Sentences",
          "lessons": ["sentence_programming"],
          "goal": "Type full code comments"
        }
      ]
    }
  }
}
```

## Step 3: Add to Campaign Map (Optional)

If the lesson unlocks at a specific campaign node, update `data/map.json`:

```json
{
  "nodes": [
    // ... existing nodes ...
    {
      "id": "code_temple",
      "name": "Temple of Code",
      "type": "lesson",
      "lesson_id": "programming_keywords",
      "requires": ["tech_village"],
      "position": {"x": 5, "y": 3},
      "description": "Ancient programmers trained here."
    }
  ]
}
```

## Step 4: Verify Word Generation

Test that words generate correctly by checking `sim/words.gd`:

```gdscript
# sim/words.gd handles word generation

# For wordlist mode:
static func pick_word_from_lesson(lesson: Dictionary, length_range: Array, rng: SimRng) -> String:
    var words: Array = lesson.get("wordlist", [])
    var min_len: int = length_range[0]
    var max_len: int = length_range[1]

    # Filter words by length
    var candidates: Array = []
    for word in words:
        if word.length() >= min_len and word.length() <= max_len:
            candidates.append(word)

    if candidates.is_empty():
        # Fallback to any word if none match length
        return words[rng.randi() % words.size()]

    return candidates[rng.randi() % candidates.size()]
```

## Step 5: Add Category Tags (Optional)

For filtering in the UI, you can add categories:

```json
{
  "id": "programming_keywords",
  "name": "Programming Keywords",
  "description": "Common programming terms and syntax.",
  "mode": "wordlist",
  "category": "technical",
  "difficulty": 3,
  "tags": ["programming", "code", "technical"],
  // ... rest of lesson
}
```

Note: Check if the schema supports these fields. If not, they'll be ignored but won't break anything.

## Step 6: Update Schema (If Adding New Fields)

If you add new fields to the lesson structure, update `data/schemas/lessons.schema.json`:

```json
{
  "$defs": {
    "lesson": {
      "properties": {
        // ... existing properties ...
        "category": {"type": "string"},
        "difficulty": {"type": "integer", "minimum": 1, "maximum": 5},
        "tags": {
          "type": "array",
          "items": {"type": "string"}
        }
      }
    }
  }
}
```

## Step 7: Test the Lesson

### Manual Test

```
# In-game commands
lesson set programming_keywords
lesson sample
lesson sample 10
```

### Automated Test

```gdscript
# tests/run_tests.gd

func test_programming_keywords_lesson_loads() -> void:
    var lessons := SimLessons.load_lessons()
    var found := false
    for lesson in lessons:
        if lesson["id"] == "programming_keywords":
            found = true
            assert(lesson["mode"] == "wordlist", "Should be wordlist mode")
            assert(lesson["wordlist"].size() >= 10, "Should have words")
            break
    assert(found, "Lesson should exist")
    _pass("test_programming_keywords_lesson_loads")

func test_programming_keywords_word_generation() -> void:
    var state := GameState.new()
    state.lesson_id = "programming_keywords"
    var word := SimWords.generate_word(state, "raider")
    assert(word.length() >= 5 and word.length() <= 8, "Word length should match raider range")
    _pass("test_programming_keywords_word_generation")
```

## Step 8: Validate Schema

```bash
./scripts/validate.sh lessons
```

Expected output:
```
[SCHEMA] lessons.json
  Schema validation passed
```

---

## Files Changed Summary

| File | Change |
|------|--------|
| `data/lessons.json` | Add lesson definition |
| `data/map.json` | Add campaign node (optional) |
| `data/schemas/lessons.schema.json` | Add new fields (if any) |
| `tests/run_tests.gd` | Add test cases |

## Lesson Modes Reference

| Mode | Required Fields | Word Source |
|------|-----------------|-------------|
| `charset` | `charset`, `lengths` | Random strings from charset |
| `wordlist` | `wordlist`, `lengths` | Words from provided list |
| `sentence` | `sentences` | Full sentences from list |

## Length Ranges by Enemy Type

| Enemy Type | Typical Range | Description |
|------------|---------------|-------------|
| `scout` | `[2, 4]` to `[3, 5]` | Short words for fast enemies |
| `raider` | `[4, 7]` to `[5, 8]` | Medium words for normal enemies |
| `armored` | `[7, 12]` to `[8, 15]` | Long words for tough enemies |

## Common Pitfalls

1. **Empty wordlist** - Must have at least one word
2. **Length range mismatch** - If no words match the length range, generation may fail or use fallback
3. **Invalid characters** - Words should only contain typeable characters
4. **Missing lengths** - All three enemy types must have length ranges (except sentence mode)
5. **Duplicate IDs** - Lesson IDs must be unique
6. **Invalid mode** - Must be `charset`, `wordlist`, or `sentence`
